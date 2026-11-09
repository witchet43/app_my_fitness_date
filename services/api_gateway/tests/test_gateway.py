import pytest
from fastapi import HTTPException
from fastapi.testclient import TestClient
from app import main


client = TestClient(main.app)


def test_public_health():
    assert client.get("/healthz").json() == {"status": "ok", "service": "api-gateway"}


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
