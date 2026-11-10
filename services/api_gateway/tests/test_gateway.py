import pytest
from fastapi import HTTPException
from fastapi.testclient import TestClient
from app import main


client = TestClient(main.app)


def test_public_health():
    assert client.get("/healthz").json() == {"status": "ok", "service": "api-gateway"}


def test_cors_never_allows_unlisted_origins():
    response = client.get("/healthz", headers={"Origin": "https://hostile.example"})
    assert "access-control-allow-origin" not in response.headers


def test_fails_closed_without_auth():
    response = client.get("/v1/dating/candidates")
    assert response.status_code == 401
    assert "gym" not in response.text.lower()


def test_rejects_invalid_limits():
    assert client.get("/v1/dating/candidates?limit=11").status_code == 422


def test_missing_configuration_is_not_insecure(monkeypatch):
    monkeypatch.delenv("MFD_GYM_SHIELD_URL", raising=False)
    with pytest.raises(HTTPException) as exc:
        main.config_url("MFD_GYM_SHIELD_URL", internal=True)
    assert exc.value.status_code == 503


def test_http_refused_outside_local(monkeypatch):
    monkeypatch.setenv("MFD_APP_ENV", "dev")
    monkeypatch.setenv("MFD_GYM_SHIELD_URL", "http://localhost:8001")
    with pytest.raises(HTTPException):
        main.config_url("MFD_GYM_SHIELD_URL", internal=True)


def test_proxy_drops_private_data(monkeypatch):
    from uuid import UUID

    async def verify(_):
        return UUID("10000000-0000-4000-8000-000000000001")

    async def proxy(_, limit):
        assert limit == 3
        return main.CandidateResponse.model_validate({
            "items": [{
                "id": "10000000-0000-4000-8000-000000000002",
                "display_name": "Demo", "city": "Qro", "sports": ["Running"],
                "gym_id": "secret", "weekly_slots": [{"day": 1}]
            }], "count": 1
        })

    monkeypatch.setattr(main, "verify_user", verify)
    monkeypatch.setattr(main, "proxy_candidates", proxy)
    response = client.get("/v1/dating/candidates?limit=3",
                          headers={"Authorization": "Bearer test"})
    assert response.status_code == 200
    assert response.json()["count"] == 1
    assert "gym_id" not in response.text
    assert "weekly_slots" not in response.text


def test_readiness_makes_database_probe(monkeypatch):
    calls = []

    async def probe():
        calls.append("postgres")

    monkeypatch.setattr(main, "probe_database", probe)
    for path in ("/readyz", "/heartbeat"):
        response = client.get(path)
        assert response.status_code == 200
        payload = response.json()
        assert payload["status"] == "ok"
        assert payload["service"] == "api-gateway"
        assert payload["dependencies"] == {"database": "ok"}
        assert payload["checked_at"].endswith("Z")
        assert response.headers["cache-control"] == "no-store, max-age=0"
    assert calls == ["postgres", "postgres"]


def test_readiness_fails_closed(monkeypatch):
    async def probe():
        raise HTTPException(503, "Dependency unavailable")

    monkeypatch.setattr(main, "probe_database", probe)
    response = client.get("/heartbeat")
    assert response.status_code == 503
    assert response.json() == {"detail": "Dependency unavailable"}
    assert response.headers["cache-control"] == "no-store, max-age=0"


def test_readiness_requires_backend_configuration(monkeypatch):
    monkeypatch.delenv("MFD_SUPABASE_URL", raising=False)
    assert client.get("/readyz").status_code == 503


def test_private_api_denies_cache_and_does_not_echo_untrusted_request_id():
    from uuid import UUID
    response = client.get("/v1/dating/candidates", headers={"X-Request-ID": "untrusted"})
    assert response.status_code == 401
    assert response.headers["Cache-Control"] == "no-store"
    assert response.headers["X-Content-Type-Options"] == "nosniff"
    assert response.headers["Referrer-Policy"] == "no-referrer"
    assert str(UUID(response.headers["X-Request-ID"])) != "untrusted"


def test_health_does_not_change_readiness_cache_contract():
    assert client.get("/healthz").headers["X-Content-Type-Options"] == "nosniff"
