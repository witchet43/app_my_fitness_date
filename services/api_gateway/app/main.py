"""Public API gateway. A bearer token is always validated by Supabase Auth.

Cloud Run: only this service is public; Gym Shield requires roles/run.invoker.
No database key or privileged credentials ever reach Flutter.
"""
import asyncio
from datetime import datetime, timezone
import os
from urllib.parse import urlparse
from uuid import UUID, uuid4

import httpx
from fastapi import FastAPI, Header, HTTPException, Query, Response, Request as HttpRequest
from fastapi.middleware.cors import CORSMiddleware
from google.auth.transport.requests import Request
from google.oauth2.id_token import fetch_id_token
from pydantic import BaseModel, ConfigDict

app = FastAPI(title="my_fitness_date API Gateway", version="0.1.0",
              docs_url=None, redoc_url=None)

# Browser clients need CORS, but only configured web origins may call APIs.
# No wildcard and no credentials; native Android/iOS are unaffected by CORS.
allowed_origins = [origin.strip() for origin in
                   os.getenv("MFD_WEB_ALLOWED_ORIGINS", "").split(",")
                   if origin.strip() and origin.strip() != "*"]
app.add_middleware(CORSMiddleware, allow_origins=allowed_origins,
                   allow_methods=["GET"], allow_headers=["Authorization"],
                   allow_credentials=False, expose_headers=["X-Request-ID"])

@app.middleware("http")
async def response_security_headers(request: HttpRequest, call_next):
    """Correlate requests without trusting client supplied identifiers."""
    response = await call_next(request)
    response.headers["X-Request-ID"] = str(uuid4())
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["Referrer-Policy"] = "no-referrer"
    if request.url.path.startswith("/v1/"):
        response.headers["Cache-Control"] = "no-store"
    return response


class Candidate(BaseModel):
    model_config = ConfigDict(extra="ignore")
    id: UUID
    display_name: str
    city: str
    sports: list[str]


class CandidateResponse(BaseModel):
    items: list[Candidate]
    count: int


def config_url(key: str, *, internal: bool = False) -> str:
    raw = os.getenv(key, "").rstrip("/")
    parsed = urlparse(raw)
    local = os.getenv("MFD_APP_ENV") == "local"
    if not raw or parsed.username or parsed.password or parsed.query or parsed.fragment:
        raise HTTPException(503, "Service unavailable")
    if parsed.scheme != "https" and not (
        local and parsed.scheme == "http" and
        parsed.hostname in {"127.0.0.1", "localhost", "gym-shield"}
    ):
        raise HTTPException(503, "Service unavailable")
    if internal and not local and not os.getenv("MFD_GYM_SHIELD_AUDIENCE"):
        raise HTTPException(503, "Service unavailable")
    return raw


async def verify_user(access_token: str) -> UUID:
    base = config_url("MFD_SUPABASE_URL")
    key = os.getenv("MFD_SUPABASE_PUBLISHABLE_KEY", "")
    if not key:
        raise HTTPException(503, "Service unavailable")
    try:
        async with httpx.AsyncClient(timeout=5) as client:
            response = await client.get(
                base + "/auth/v1/user",
                headers={"apikey": key, "Authorization": "Bearer " + access_token},
            )
    except httpx.HTTPError:
        raise HTTPException(503, "Service unavailable") from None
    if response.status_code != 200:
        raise HTTPException(401, "Authentication required")
    try:
        return UUID(str(response.json()["id"]))
    except (ValueError, KeyError, TypeError):
        raise HTTPException(401, "Authentication required") from None


def cloud_run_identity_token(audience: str) -> str:
    return fetch_id_token(Request(), audience)


async def proxy_candidates(access_token: str, limit: int) -> CandidateResponse:
    base = config_url("MFD_GYM_SHIELD_URL", internal=True)
    headers = {"X-End-User-Token": access_token}
    if os.getenv("MFD_APP_ENV") != "local":
        audience = os.environ["MFD_GYM_SHIELD_AUDIENCE"]
        try:
            signed = await asyncio.to_thread(cloud_run_identity_token, audience)
        except Exception:
            raise HTTPException(503, "Service unavailable") from None
        headers["X-Serverless-Authorization"] = "Bearer " + signed
    try:
        async with httpx.AsyncClient(timeout=8) as client:
            response = await client.get(base + "/internal/v1/dating/candidates",
                                        params={"limit": limit}, headers=headers)
    except httpx.HTTPError:
        raise HTTPException(503, "Service unavailable") from None
    if response.status_code in (401, 403):
        raise HTTPException(response.status_code, "Dating unavailable")
    if response.status_code != 200:
        raise HTTPException(503, "Service unavailable")
    try:
        return CandidateResponse.model_validate(response.json())
    except (ValueError, TypeError):
        raise HTTPException(503, "Service unavailable") from None


@app.get("/healthz")
async def healthz() -> dict[str, str]:
    return {"status": "ok", "service": "api-gateway"}


async def probe_database() -> None:
    """Exercise PostgreSQL through an unprivileged Supabase RPC."""
    base = config_url("MFD_SUPABASE_URL")
    key = os.getenv("MFD_SUPABASE_PUBLISHABLE_KEY", "")
    if not key:
        raise HTTPException(503, "Dependency unavailable")
    try:
        async with httpx.AsyncClient(timeout=4) as client:
            result = await client.post(
                base + "/rest/v1/rpc/saas_heartbeat_v1",
                headers={"apikey": key, "Content-Type": "application/json"},
                json={},
            )
    except httpx.HTTPError:
        raise HTTPException(503, "Dependency unavailable") from None
    if result.status_code != 200:
        raise HTTPException(503, "Dependency unavailable")
    try:
        if result.json() != {"status": "ok"}:
            raise HTTPException(503, "Dependency unavailable")
    except (ValueError, TypeError):
        raise HTTPException(503, "Dependency unavailable") from None


@app.get("/readyz")
@app.get("/heartbeat")
async def database_heartbeat(response: Response) -> dict[str, object]:
    """Readiness, unlike /healthz, fails if PostgreSQL is unavailable."""
    response.headers["Cache-Control"] = "no-store, max-age=0"
    try:
        await probe_database()
    except HTTPException:
        raise HTTPException(
            503, "Dependency unavailable",
            headers={"Cache-Control": "no-store, max-age=0"},
        ) from None
    return {"status": "ok", "service": "api-gateway",
            "dependencies": {"database": "ok"},
            "checked_at": datetime.now(timezone.utc).isoformat(
                timespec="seconds").replace("+00:00", "Z")}


@app.get("/v1/dating/candidates", response_model=CandidateResponse)
async def candidates(
    limit: int = Query(default=10, ge=1, le=10),
    authorization: str | None = Header(default=None),
) -> CandidateResponse:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(401, "Authentication required")
    token = authorization.removeprefix("Bearer ").strip()
    if not token or len(token) > 8192:
        raise HTTPException(401, "Authentication required")
    await verify_user(token)  # Trust is never derived from user-supplied IDs.
    return await proxy_candidates(token, limit)
