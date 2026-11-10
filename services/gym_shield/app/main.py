"""Gym Shield service boundary (Supabase RPC is authoritative during migration).

Never accept user IDs, gym IDs, schedules or exclusion decisions from the client.
For Cloud Run this service must be IAM-private and invokable only by the gateway.
The user's validated JWT is forwarded to existing RLS/role-protected SQL RPC.
"""
import os
from urllib.parse import urlparse
from uuid import UUID, uuid4

import httpx
from fastapi import FastAPI, Header, HTTPException, Query, Request
from pydantic import BaseModel, ConfigDict

app = FastAPI(title="my_fitness_date Gym Shield", version="0.1.0",
              docs_url=None, redoc_url=None)

@app.middleware("http")
async def response_security_headers(request: Request, call_next):
    """Avoid proxy caches of protected candidates and expose safe diagnostics."""
    response = await call_next(request)
    response.headers["X-Request-ID"] = str(uuid4())
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["Referrer-Policy"] = "no-referrer"
    if request.url.path.startswith("/internal/"):
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


def supabase_config() -> tuple[str, str]:
    url = os.getenv("MFD_SUPABASE_URL", "").rstrip("/")
    key = os.getenv("MFD_SUPABASE_PUBLISHABLE_KEY", "")
    parsed = urlparse(url)
    if not url or not key or parsed.scheme != "https" or (
        parsed.username or parsed.password or parsed.query or parsed.fragment
    ):
        raise HTTPException(503, "Service unavailable")
    return url, key


async def discover(access_token: str, limit: int) -> CandidateResponse:
    url, key = supabase_config()
    headers = {"apikey": key, "Authorization": "Bearer " + access_token}
    try:
        async with httpx.AsyncClient(timeout=8) as client:
            # Defense in depth: recheck the user and preserve Supabase Auth as
            # the authority. The user JWT (never service_role) scopes the RPC.
            identity = await client.get(url + "/auth/v1/user", headers=headers)
            if identity.status_code != 200:
                raise HTTPException(401, "Authentication required")
            try:
                UUID(str(identity.json()["id"]))
            except (KeyError, ValueError, TypeError):
                raise HTTPException(401, "Authentication required") from None
            result = await client.post(
                url + "/rest/v1/rpc/discover_dating_candidates",
                json={"p_limit": limit}, headers=headers,
            )
    except httpx.HTTPError:
        raise HTTPException(503, "Service unavailable") from None

    if result.status_code in (400, 401, 403, 429):
        # Do not reveal eligibility, block, age, gym or quota information.
        raise HTTPException(403, "Dating unavailable")
    if result.status_code != 200:
        raise HTTPException(503, "Service unavailable")
    try:
        payload = result.json()
        if not isinstance(payload, list):
            raise ValueError("Invalid result")
        items = [Candidate.model_validate({
            "id": row["user_id"],
            "display_name": row["display_name"],
            "city": row["city"],
            "sports": row["sports"],
        }) for row in payload]
        return CandidateResponse(items=items, count=len(items))
    except (KeyError, ValueError, TypeError):
        raise HTTPException(503, "Service unavailable") from None


@app.get("/healthz")
async def healthz() -> dict[str, str]:
    return {"status": "ok", "service": "gym-shield"}


@app.get("/internal/v1/dating/candidates", response_model=CandidateResponse)
async def candidates(
    limit: int = Query(default=10, ge=1, le=10),
    x_end_user_token: str | None = Header(default=None),
) -> CandidateResponse:
    if not x_end_user_token or len(x_end_user_token) > 8192:
        raise HTTPException(401, "Authentication required")
    return await discover(x_end_user_token, limit)
