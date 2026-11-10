"""No external calls or real QA accounts are used by these tests."""
import httpx
import pytest
from fastapi.testclient import TestClient
from app import main, identity

client = TestClient(main.app)
UUID1 = "10000000-0000-4000-8000-000000000001"
USER = {"id": UUID1, "email": "qa@example.test",
        "email_confirmed_at": "2026-11-10T00:00:00Z",
        "is_anonymous": False}
TOKENS = {"access_token": "jwt-synthetic", "refresh_token": "rotated-synthetic",
          "expires_in": 3600, "token_type": "bearer"}


@pytest.fixture(autouse=True)
def private_qa_environment(monkeypatch):
    monkeypatch.delenv("MFD_QA_AUTH_ENABLED", raising=False)
    monkeypatch.delenv("MFD_QA_AUTH_ALLOWLIST", raising=False)
    monkeypatch.setenv("MFD_APP_ENV", "local")


def enable(monkeypatch):
    monkeypatch.setenv("MFD_QA_AUTH_ENABLED", "EXISTING_QA_ACCOUNTS_ONLY")
    monkeypatch.setenv("MFD_QA_AUTH_ALLOWLIST", "qa@example.test")


def synthetic_provider(monkeypatch, *, user=None, token_status=200):
    calls = []
    async def fake_request(method, resource, *, bearer=None, payload=None, grant=None):
        calls.append((method, resource, bearer, payload, grant))
        if resource == "user":
            return httpx.Response(200, json=user or USER)
        if resource == "token":
            return httpx.Response(token_status, json=TOKENS)
        return httpx.Response(204)
    monkeypatch.setattr(identity, "_provider", fake_request)
    return calls


def test_qa_session_endpoints_disabled_by_default():
    for method, path, data in (
        ("post", "/v1/identity/session", {"email": "qa@example.test", "password": "secret"}),
        ("post", "/v1/identity/session/refresh", {"refresh_token": "synthetic"}),
        ("get", "/v1/identity/me", None),
        ("delete", "/v1/identity/session", None),
    ):
        result = getattr(client, method)(path, json=data) if data else getattr(client, method)(path)
        assert result.status_code == 404
        assert result.headers["cache-control"] == "no-store"


def test_production_never_enables_qa_auth_even_if_flag_set(monkeypatch):
    enable(monkeypatch)
    monkeypatch.setenv("MFD_APP_ENV", "prod")
    assert client.post("/v1/identity/session",
                       json={"email": "qa@example.test", "password": "secret"}).status_code == 404


def test_allowlist_is_required(monkeypatch):
    enable(monkeypatch)
    monkeypatch.delenv("MFD_QA_AUTH_ALLOWLIST")
    assert client.get("/v1/identity/me").status_code == 503


def test_login_only_allowlisted_existing_confirmed_user(monkeypatch):
    enable(monkeypatch)
    calls = synthetic_provider(monkeypatch)
    denied = client.post("/v1/identity/session",
                         json={"email": "other@example.test", "password": "test"})
    assert denied.status_code == 401 and not calls
    result = client.post("/v1/identity/session",
                         json={"email": " QA@EXAMPLE.TEST ", "password": "test"})
    assert result.status_code == 200
    assert result.json()["user"] == {"id": UUID1, "email": "qa@example.test",
                                    "email_verified": True}
    assert result.json()["refresh_token"] == "rotated-synthetic"
    assert calls[0][0:2] == ("POST", "token")
    assert calls[0][4] == "password"
    assert calls[1][0:2] == ("GET", "user")
    assert result.headers["cache-control"] == "no-store"


def test_unconfirmed_or_anonymous_user_denied(monkeypatch):
    enable(monkeypatch)
    synthetic_provider(monkeypatch, user={**USER, "email_confirmed_at": None})
    assert client.post("/v1/identity/session",
                       json={"email": "qa@example.test", "password": "test"}).status_code == 401
    synthetic_provider(monkeypatch, user={**USER, "is_anonymous": True})
    assert client.post("/v1/identity/session",
                       json={"email": "qa@example.test", "password": "test"}).status_code == 401


def test_refresh_rotation_me_and_remote_signout(monkeypatch):
    enable(monkeypatch)
    calls = synthetic_provider(monkeypatch)
    refreshed = client.post("/v1/identity/session/refresh",
                            json={"refresh_token": "previous-synthetic"})
    assert refreshed.status_code == 200
    assert refreshed.json()["refresh_token"] == "rotated-synthetic"
    assert ("POST", "token", None, {"refresh_token": "previous-synthetic"},
            "refresh_token") in calls
    who = client.get("/v1/identity/me", headers={"Authorization": "Bearer jwt-synthetic"})
    assert who.status_code == 200 and who.json()["id"] == UUID1
    deleted = client.delete("/v1/identity/session",
                            headers={"Authorization": "Bearer jwt-synthetic"})
    assert deleted.status_code == 204
    assert calls[-1][0:3] == ("POST", "logout", "jwt-synthetic")


def test_auth_failures_redact_upstream_messages_and_credentials(monkeypatch):
    enable(monkeypatch)
    synthetic_provider(monkeypatch, token_status=401)
    result = client.post("/v1/identity/session",
                         json={"email": "qa@example.test", "password": "TOP_SECRET_TEST"})
    assert result.status_code == 401
    assert "TOP_SECRET_TEST" not in result.text
    # Pydantic 422 error inputs are not reflected for sensitive identity endpoints.
    invalid = client.post("/v1/identity/session",
                          json={"email": "qa@example.test", "password": "SECRET",
                                "forbidden": "ANOTHER_SECRET"})
    assert invalid.status_code == 422
    assert "SECRET" not in invalid.text
    assert "ANOTHER_SECRET" not in invalid.text


def test_429_and_503_fail_closed(monkeypatch):
    enable(monkeypatch)
    synthetic_provider(monkeypatch, token_status=429)
    assert client.post("/v1/identity/session",
                       json={"email": "qa@example.test", "password": "x"}).status_code == 429
    synthetic_provider(monkeypatch, token_status=500)
    assert client.post("/v1/identity/session",
                       json={"email": "qa@example.test", "password": "x"}).status_code == 503


def test_no_bearer_or_whitespace_token(monkeypatch):
    enable(monkeypatch)
    for value in (None, "Basic test", "Bearer bad token", "Bearer "):
        headers = {"Authorization": value} if value is not None else {}
        assert client.get("/v1/identity/me", headers=headers).status_code == 401


def test_credentials_and_tokens_not_allowed_in_query_or_untrusted_fields(monkeypatch):
    enable(monkeypatch)
    synthetic_provider(monkeypatch)
    response = client.post("/v1/identity/session?password=LEAK",
                           json={"email": "qa@example.test", "password": "x",
                                 "viewer_id": "other-user"})
    assert response.status_code == 422
    assert "other-user" not in response.text


def test_qa_provider_rejects_unsafe_urls_and_privileged_key(monkeypatch):
    monkeypatch.setenv("MFD_SUPABASE_URL", "http://example.com")
    monkeypatch.setenv("MFD_SUPABASE_PUBLISHABLE_KEY", "sb_publishable_example")
    with pytest.raises(Exception):
        identity._provider_config()
    monkeypatch.setenv("MFD_SUPABASE_URL", "https://example.supabase.co")
    monkeypatch.setenv("MFD_SUPABASE_PUBLISHABLE_KEY", "sb_secret_server-key")
    with pytest.raises(Exception):
        identity._provider_config()
