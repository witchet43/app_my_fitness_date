"""Restricted, existing-account-only Supabase Auth adapter for QA.

No sign-up, admin API, service_role, OAuth client secret, or stored credentials.
QA endpoints remain disabled unless explicitly enabled in local/dev AND allowlisted.
"""
from __future__ import annotations

import os
from urllib.parse import urlparse
from uuid import UUID

import httpx
from fastapi import APIRouter, Header, HTTPException
from pydantic import BaseModel, ConfigDict, Field, field_validator

router = APIRouter(prefix="/v1/identity", tags=["QA identity"])


class Credentials(BaseModel):
    model_config = ConfigDict(extra="forbid")
    email: str = Field(min_length=3, max_length=254)
    password: str = Field(min_length=1, max_length=1024, repr=False)

    @field_validator("email")
    @classmethod
    def normalize_email(cls, email: str) -> str:
        email = email.strip().lower()
        if "@" not in email or email.startswith("@") or email.endswith("@"):
            raise ValueError("Invalid email")
        return email


class RefreshRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    refresh_token: str = Field(min_length=1, max_length=8192, repr=False)


class IdentityUser(BaseModel):
    id: UUID
    email: str
    email_verified: bool


class IdentitySession(BaseModel):
    access_token: str = Field(repr=False)
    refresh_token: str = Field(repr=False)
    expires_in: int = Field(ge=1, le=86400)
    user: IdentityUser


def _qa_allowlist() -> frozenset[str]:
    enabled = os.getenv("MFD_QA_AUTH_ENABLED") == "EXISTING_QA_ACCOUNTS_ONLY"
    environment = os.getenv("MFD_APP_ENV")
    if not enabled or environment not in {"local", "dev"}:
        raise HTTPException(404, "Not found")
    accounts = frozenset(
        email.strip().lower() for email in
        os.getenv("MFD_QA_AUTH_ALLOWLIST", "").split(",") if email.strip()
    )
    # Without an explicit allowlist there is no QA authentication.
    if not accounts or any("@" not in email or "*" in email for email in accounts):
        raise HTTPException(503, "Service unavailable")
    return accounts


def _provider_config() -> tuple[str, str]:
    url = os.getenv("MFD_SUPABASE_URL", "").rstrip("/")
    key = os.getenv("MFD_SUPABASE_PUBLISHABLE_KEY", "")
    parsed = urlparse(url)
    local = os.getenv("MFD_APP_ENV") == "local"
    if (
        not url or not parsed.hostname or
        parsed.username or parsed.password or parsed.query or parsed.fragment or
        parsed.path not in {"", "/"} or
        not (
            parsed.scheme == "https" or
            (local and parsed.scheme == "http" and
             parsed.hostname in {"localhost", "127.0.0.1"})
        ) or not key.startswith("sb_publishable_")
    ):
        raise HTTPException(503, "Service unavailable")
    return url, key


async def _provider(
    method: str,
    resource: str,
    *,
    bearer: str | None = None,
    payload: dict[str, str] | None = None,
    grant: str | None = None,
) -> httpx.Response:
    url, key = _provider_config()
    headers = {"apikey": key, "Content-Type": "application/json"}
    if bearer is not None:
        headers["Authorization"] = "Bearer " + bearer
    params = {"grant_type": grant} if grant else {"scope": "local"} if resource == "logout" else None
    try:
        async with httpx.AsyncClient(timeout=7, follow_redirects=False) as client:
            return await client.request(
                method, url + "/auth/v1/" + resource,
                params=params, headers=headers, json=payload,
            )
    except httpx.HTTPError:
        raise HTTPException(503, "Service unavailable") from None


def _check_provider_response(response: httpx.Response) -> None:
    if response.status_code in (400, 401, 403):
        raise HTTPException(401, "Authentication required")
    if response.status_code == 429:
        raise HTTPException(429, "Too many attempts")
    if response.status_code not in (200, 204):
        raise HTTPException(503, "Service unavailable")


def _bearer(header: str | None) -> str:
    if not header or not header.startswith("Bearer "):
        raise HTTPException(401, "Authentication required")
    token = header[len("Bearer "):].strip()
    if not token or len(token) > 8192 or any(c.isspace() for c in token):
        raise HTTPException(401, "Authentication required")
    return token


async def _user_from_token(token: str, allowlist: frozenset[str]) -> IdentityUser:
    response = await _provider("GET", "user", bearer=token)
    _check_provider_response(response)
    try:
        value = response.json()
        user = IdentityUser(
            id=UUID(str(value["id"])),
            email=str(value["email"]).strip().lower(),
            email_verified=bool(value.get("email_confirmed_at")),
        )
        if (user.email not in allowlist or not user.email_verified or
                value.get("is_anonymous") is True):
            raise HTTPException(401, "Authentication required")
        return user
    except (ValueError, TypeError, KeyError, AttributeError):
        raise HTTPException(401, "Authentication required") from None


async def _session_from_response(
    response: httpx.Response, allowlist: frozenset[str]
) -> IdentitySession:
    _check_provider_response(response)
    try:
        data = response.json()
        access = data["access_token"]
        refresh = data["refresh_token"]
        expires = data["expires_in"]
        if (data.get("token_type", "").lower() != "bearer"
                or not isinstance(access, str) or not isinstance(refresh, str)
                or not access or not refresh or len(access) > 8192
                or len(refresh) > 8192 or type(expires) is not int):
            raise ValueError("Invalid provider session")
        user = await _user_from_token(access, allowlist)
        return IdentitySession(
            access_token=access, refresh_token=refresh,
            expires_in=expires, user=user,
        )
    except (ValueError, KeyError, TypeError, AttributeError):
        raise HTTPException(503, "Service unavailable") from None


@router.post("/session", response_model=IdentitySession)
async def sign_in(credentials: Credentials) -> IdentitySession:
    allowlist = _qa_allowlist()
    if credentials.email not in allowlist:
        raise HTTPException(401, "Authentication required")
    response = await _provider(
        "POST", "token",
        payload={"email": credentials.email, "password": credentials.password},
        grant="password",
    )
    session = await _session_from_response(response, allowlist)
    if session.user.email != credentials.email:
        raise HTTPException(401, "Authentication required")
    return session


@router.post("/session/refresh", response_model=IdentitySession)
async def refresh(body: RefreshRequest) -> IdentitySession:
    allowlist = _qa_allowlist()
    response = await _provider(
        "POST", "token",
        payload={"refresh_token": body.refresh_token}, grant="refresh_token",
    )
    return await _session_from_response(response, allowlist)


@router.get("/me", response_model=IdentityUser)
async def me(authorization: str | None = Header(default=None)) -> IdentityUser:
    allowlist = _qa_allowlist()
    return await _user_from_token(_bearer(authorization), allowlist)


@router.delete("/session", status_code=204)
async def sign_out(authorization: str | None = Header(default=None)) -> None:
    _qa_allowlist()
    response = await _provider("POST", "logout", bearer=_bearer(authorization))
    _check_provider_response(response)
