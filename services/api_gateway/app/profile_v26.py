"""My Fitness Date V26: private member profile API.

Every call verifies a real Supabase Auth bearer token; Supabase PostgREST
executes using that SAME user JWT and owner-only RLS. No service_role or
other privileged key. Profile and venue endpoints never return other users.
All routes are closed when backend PROD auth is not explicitly configured.
"""
from __future__ import annotations

from datetime import date
from io import BytesIO
import re
import os
from typing import Literal
from urllib.parse import urlparse
from uuid import UUID, uuid4

import httpx
from fastapi import APIRouter, Header, HTTPException, Path, Request
from fastapi.responses import Response
from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator

router = APIRouter(prefix="/v1/me", tags=["private member profile"])


def _provider_config() -> tuple[str, str]:
    if os.getenv("MFD_APP_ENV") != "prod" or os.getenv("MFD_PROFILE_V26_ENABLED") != "true":
        raise HTTPException(404, "Not found")
    url = os.getenv("MFD_SUPABASE_URL", "").rstrip("/")
    key = os.getenv("MFD_SUPABASE_PUBLISHABLE_KEY", "")
    parsed = urlparse(url)
    if (parsed.scheme != "https" or not parsed.hostname
            or parsed.username or parsed.password or parsed.query
            or parsed.fragment or parsed.path not in ("", "/")
            or not key.startswith("sb_publishable_")):
        raise HTTPException(503, "Service unavailable")
    # Promote the EXISTING MFD project, never MUV or a newly created project.
    # This exact ref is permitted only after the independent prod enable flag.
    if url != "https://jtrdvnwbxpfdnbzasvcj.supabase.co":
        raise HTTPException(503, "Production identity unavailable")
    return url, key


def _bearer(authorization: str | None) -> str:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(401, "Authentication required")
    token = authorization.removeprefix("Bearer ").strip()
    if not token or len(token) > 8192 or any(c.isspace() for c in token):
        raise HTTPException(401, "Authentication required")
    return token


async def _provider(method: str, path: str, token: str, *,
                    params: dict[str, str] | None = None,
                    data: dict | None = None,
                    binary: bytes | None = None,
                    content_type: str = "application/json",
                    upsert: bool = False) -> httpx.Response:
    url, key = _provider_config()
    headers = {"apikey": key, "Authorization": "Bearer " + token,
               "Content-Type": content_type,
               "Prefer": ("resolution=merge-duplicates,return=representation"
                          if upsert else "return=representation")}
    try:
        async with httpx.AsyncClient(timeout=9, follow_redirects=False) as client:
            return await client.request(
                method, url + path, params=params, headers=headers,
                json=data if binary is None else None, content=binary)
    except httpx.HTTPError:
        raise HTTPException(503, "Service unavailable") from None


def _provider_response(response: httpx.Response, *, creation: bool = False) -> list[dict]:
    if response.status_code in (401, 403):
        raise HTTPException(403, "Profile access denied")
    if response.status_code == 409:
        raise HTTPException(409, "Conflicting profile update")
    if response.status_code == 429:
        raise HTTPException(429, "Too many requests")
    if response.status_code not in (200, 201, 204):
        raise HTTPException(503, "Service unavailable")
    if response.status_code == 204 or not response.content:
        return []
    try:
        result = response.json()
    except ValueError:
        raise HTTPException(503, "Service unavailable") from None
    if not isinstance(result, list):
        raise HTTPException(503, "Service unavailable")
    return result


async def _member(token: str) -> UUID:
    response = await _provider("GET", "/auth/v1/user", token)
    if response.status_code != 200:
        raise HTTPException(401, "Authentication required")
    try:
        user = response.json()
        if user.get("is_anonymous") or not user.get("email_confirmed_at"):
            raise HTTPException(401, "Verified account required")
        member_id = UUID(str(user["id"]))
        # Existing account-erasure policy: a pending/deactivated member must
        # not continue to write profile, photos, places or consent records.
        state = await _provider("POST", "/rest/v1/rpc/my_account_status", token,
                                data={})
        if state.status_code != 200:
            raise HTTPException(503, "Service unavailable")
        account = state.json()
        if not isinstance(account, dict) or not isinstance(account.get("pending"), bool):
            raise HTTPException(503, "Service unavailable")
        if account["pending"]:
            raise HTTPException(403, "Account unavailable")
        return member_id
    except (ValueError, KeyError, TypeError, AttributeError):
        raise HTTPException(401, "Authentication required") from None


def _clean_list(values: list[str], *, count: int, max_item: int = 70) -> list[str]:
    if len(values) > count:
        raise ValueError("Too many items")
    cleaned = [v.strip() for v in values]
    if any(not v or len(v) > max_item for v in cleaned):
        raise ValueError("Invalid list entry")
    return list(dict.fromkeys(cleaned))


class MemberProfile(BaseModel):
    model_config = ConfigDict(extra="forbid")
    display_name: str = Field(min_length=2, max_length=60)
    date_of_birth: date
    city: str = Field(min_length=2, max_length=100)
    about_me: str = Field(default="", max_length=1200)
    headline: str = Field(default="", max_length=160)
    occupation: str = Field(default="", max_length=100)
    languages: list[str] = Field(default_factory=list)
    hobbies: list[str] = Field(default_factory=list)
    life_values: list[str] = Field(default_factory=list)
    prompts: list[dict[str, str]] = Field(default_factory=list, max_length=3)
    sports: list[str] = Field(default_factory=list)
    fitness_goals: list[str] = Field(default_factory=list)
    achievements: list[str] = Field(default_factory=list)
    training_frequency: Literal["starting", "one_to_two", "three_to_four",
                                "five_plus", "flexible"] | None = None
    dating_intent: Literal["unknown", "relationship", "companionship",
                           "open_to_explore"] | None = None
    social_visibility: Literal["private", "members"] = "private"
    onboarding_complete: bool = False

    @field_validator("display_name", "city")
    @classmethod
    def no_blank(cls, value: str) -> str:
        if not value.strip():
            raise ValueError("Empty field")
        return value.strip()

    @field_validator("languages", "hobbies", "life_values", "sports",
                     "fitness_goals", "achievements")
    @classmethod
    def bound_lists(cls, value: list[str], info) -> list[str]:
        limits = {"languages": 8, "hobbies": 18, "life_values": 12,
                  "sports": 16, "fitness_goals": 10, "achievements": 16}
        return _clean_list(value, count=limits[info.field_name])

    @field_validator("prompts")
    @classmethod
    def bound_prompts(cls, prompts: list[dict[str, str]]) -> list[dict[str, str]]:
        cleaned = []
        for prompt in prompts:
            if set(prompt) != {"question", "answer"}:
                raise ValueError("Invalid prompt")
            q, a = prompt["question"].strip(), prompt["answer"].strip()
            if not 4 <= len(q) <= 110 or not 2 <= len(a) <= 280:
                raise ValueError("Invalid prompt")
            cleaned.append({"question": q, "answer": a})
        return cleaned

    @model_validator(mode="after")
    def validate_adult_self_declaration(self):
        # Self-declared adult age is mandatory for onboarding; independent
        # operator verification is STILL REQUIRED to activate FitDating.
        today = date.today()
        year = today.year - self.date_of_birth.year
        adult = year - ((today.month, today.day) <
                        (self.date_of_birth.month, self.date_of_birth.day)) >= 18
        if self.onboarding_complete and not adult:
            raise ValueError("Adult eligibility is required")
        return self


class TrainingPlace(BaseModel):
    model_config = ConfigDict(extra="forbid")
    venue_kind: Literal["gym", "studio", "running_club", "park", "box", "other"]
    place_name: str = Field(min_length=2, max_length=110)
    city: str = Field(min_length=2, max_length=100)
    general_zone: str = Field(default="", max_length=70)
    is_favorite: bool = False


class MemberConsent(BaseModel):
    model_config = ConfigDict(extra="forbid")
    consent_kind: Literal["terms", "privacy", "community", "dating"]
    document_version: str = Field(min_length=1, max_length=50)


def _profile_query(user_id: UUID) -> dict[str, str]:
    return {"user_id": "eq." + str(user_id)}


@router.get("/profile")
async def get_profile(authorization: str | None = Header(default=None)) -> dict:
    token = _bearer(authorization)
    user_id = await _member(token)
    data = _provider_response(await _provider(
        "GET", "/rest/v1/member_profiles_v26", token,
        params={**_profile_query(user_id), "select": "*"}))
    return {"profile": data[0] if data else None}


@router.put("/profile")
async def save_profile(profile: MemberProfile,
                       authorization: str | None = Header(default=None)) -> dict:
    token = _bearer(authorization)
    user_id = await _member(token)
    record = profile.model_dump(mode="json")
    record["user_id"] = str(user_id)
    data = _provider_response(await _provider(
        "POST", "/rest/v1/member_profiles_v26", token,
        params={"on_conflict": "user_id"}, data=record, upsert=True))
    return {"profile": data[0] if data else record}


@router.get("/places")
async def list_places(authorization: str | None = Header(default=None)) -> dict:
    token = _bearer(authorization)
    user_id = await _member(token)
    data = _provider_response(await _provider(
        "GET", "/rest/v1/member_training_places_v26", token,
        params={**_profile_query(user_id), "select": "*"}))
    return {"places": data}


@router.post("/places", status_code=201)
async def create_place(place: TrainingPlace,
                       authorization: str | None = Header(default=None)) -> dict:
    token = _bearer(authorization)
    user_id = await _member(token)
    data = _provider_response(await _provider(
        "POST", "/rest/v1/member_training_places_v26", token,
        data={"user_id": str(user_id), **place.model_dump()}))
    return {"place": data[0] if data else None}


@router.delete("/places/{place_id}", status_code=204)
async def delete_place(place_id: UUID,
                       authorization: str | None = Header(default=None)):
    token = _bearer(authorization)
    user_id = await _member(token)
    _provider_response(await _provider(
        "DELETE", "/rest/v1/member_training_places_v26", token,
        params={"id": "eq." + str(place_id), **_profile_query(user_id)}))


@router.post("/consents", status_code=201)
async def append_consent(consent: MemberConsent,
                         authorization: str | None = Header(default=None)) -> dict:
    token = _bearer(authorization)
    user_id = await _member(token)
    # A dating consent alone does not grant adult eligibility or discovery.
    data = _provider_response(await _provider(
        "POST", "/rest/v1/member_consents_v26", token,
        data={"user_id": str(user_id), **consent.model_dump()}))
    return {"consent": {"recorded": bool(data)}}


@router.get("/consents")
async def list_consents(authorization: str | None = Header(default=None)) -> dict:
    token = _bearer(authorization)
    user_id = await _member(token)
    data = _provider_response(await _provider(
        "GET", "/rest/v1/member_consents_v26", token,
        params={**_profile_query(user_id), "select":
                "consent_kind,document_version,accepted_at"}))
    return {"consents": data}


@router.get("/photos")
async def list_photos(authorization: str | None = Header(default=None)) -> dict:
    token = _bearer(authorization)
    user_id = await _member(token)
    data = _provider_response(await _provider(
        "GET", "/rest/v1/member_media_v26", token,
        params={**_profile_query(user_id),
                "select": "id,alt_text,position,moderation_state,created_at"}))
    return {"photos": data}


def _safe_photo(binary: bytes, content_type: str) -> bytes:
    if content_type not in {"image/png", "image/jpeg"} or len(binary) > 5 * 1024 * 1024:
        raise HTTPException(413, "Unsupported image")
    try:
        from PIL import Image, ImageOps
        with Image.open(BytesIO(binary)) as original:
            original.verify()
        with Image.open(BytesIO(binary)) as original:
            if original.format not in ("PNG", "JPEG"):
                raise HTTPException(415, "Unsupported image")
            original = ImageOps.exif_transpose(original)
            if original.width < 200 or original.height < 200 or \
                    original.width * original.height > 20_000_000:
                raise HTTPException(413, "Unsupported image dimensions")
            out = BytesIO()
            # Re-encode from pixels: discard original EXIF, GPS and ICC metadata.
            original.convert("RGB").save(out, format="JPEG", quality=84)
            value = out.getvalue()
            if len(value) > 5 * 1024 * 1024:
                raise HTTPException(413, "Image is too large")
            return value
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(415, "Unreadable image") from None


@router.post("/photos", status_code=201)
async def upload_photo(request: Request,
                       authorization: str | None = Header(default=None)) -> dict:
    token = _bearer(authorization)
    user_id = await _member(token)
    existing = _provider_response(await _provider(
        "GET", "/rest/v1/member_media_v26", token,
        params={**_profile_query(user_id), "select": "id,position"}))
    if len(existing) >= 8:
        raise HTTPException(409, "Maximum eight photos")
    content_type = request.headers.get("content-type", "").split(";")[0].lower()
    # Stream a strict size cap before reading the whole body.
    try:
        declared = int(request.headers.get("content-length", "0") or "0")
    except ValueError:
        raise HTTPException(400, "Invalid content length") from None
    if declared > 5 * 1024 * 1024:
        raise HTTPException(413, "Image is too large")
    buffer = bytearray()
    async for chunk in request.stream():
        buffer.extend(chunk)
        if len(buffer) > 5 * 1024 * 1024:
            raise HTTPException(413, "Image is too large")
    clean = _safe_photo(bytes(buffer), content_type)
    key = f"{user_id}/{uuid4()}.jpg"
    result = await _provider(
        "POST", "/storage/v1/object/mfd-profile-private/" + key, token,
        binary=clean, content_type="image/jpeg")
    if result.status_code not in (200, 201):
        raise HTTPException(503, "Photo upload unavailable")
    used = {row["position"] for row in existing}
    position = next((i for i in range(8) if i not in used), None)
    if position is None:
        raise HTTPException(409, "Maximum eight photos")
    record = {"user_id": str(user_id), "object_key": key,
              "alt_text": "", "position": position}
    metadata = _provider_response(await _provider(
        "POST", "/rest/v1/member_media_v26", token, data=record))
    return {"photo": {"id": metadata[0]["id"], "moderation_state": "pending"}}


def _checked_photo_key(raw: object, user_id: UUID) -> str:
    """Prevent forged storage metadata from escaping own image namespace."""
    key = str(raw)
    if not key.startswith(str(user_id) + "/") or not re.fullmatch(
        r"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/"
        r"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.jpg",
        key,
    ):
        raise HTTPException(503, "Photo unavailable")
    return key


@router.get("/photos/{photo_id}/content")
async def read_photo_content(photo_id: UUID,
                             authorization: str | None = Header(default=None)):
    """Authenticated owner can preview their own (even pending) photo.
    No external member can fetch pending or approved media by guessing IDs.
    """
    token = _bearer(authorization)
    user_id = await _member(token)
    rows = _provider_response(await _provider(
        "GET", "/rest/v1/member_media_v26", token,
        params={"id": "eq." + str(photo_id), **_profile_query(user_id),
                "select": "object_key"}))
    if not rows:
        raise HTTPException(404, "Photo not found")
    response = await _provider(
        "GET", "/storage/v1/object/mfd-profile-private/" + _checked_photo_key(rows[0]["object_key"], user_id),
        token)
    if response.status_code != 200 or len(response.content) > 5 * 1024 * 1024:
        raise HTTPException(503, "Photo unavailable")
    return Response(response.content, media_type="image/jpeg",
                    headers={"Cache-Control": "private, no-store"})


@router.delete("/photos/{photo_id}", status_code=204)
async def delete_photo(photo_id: UUID,
                       authorization: str | None = Header(default=None)):
    token = _bearer(authorization)
    user_id = await _member(token)
    rows = _provider_response(await _provider(
        "GET", "/rest/v1/member_media_v26", token,
        params={"id": "eq." + str(photo_id), **_profile_query(user_id),
                "select": "object_key"}))
    if not rows:
        raise HTTPException(404, "Photo not found")
    storage = await _provider(
        "DELETE", "/storage/v1/object/mfd-profile-private/" + rows[0]["object_key"],
        token)
    if storage.status_code not in (200, 204):
        raise HTTPException(503, "Could not remove photo")
    _provider_response(await _provider(
        "DELETE", "/rest/v1/member_media_v26", token,
        params={"id": "eq." + str(photo_id), **_profile_query(user_id)}))
