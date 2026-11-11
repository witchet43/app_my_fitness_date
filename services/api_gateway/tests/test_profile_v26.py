"""Private V26 API contract: fail closed, JWT ownership and image hygiene."""
from io import BytesIO
from uuid import UUID

import httpx
from fastapi.testclient import TestClient
from PIL import Image
from app import main, profile_v26

client = TestClient(main.app)
OWN = UUID("10000000-0000-4000-8000-000000000007")


def test_v26_requires_bearer_and_is_disabled_in_prod_without_flag(monkeypatch):
    assert client.get("/v1/me/profile").status_code == 401
    assert client.get("/v1/me/places").status_code == 401
    assert client.get("/v1/me/photos").status_code == 401
    assert client.post("/v1/me/consents", json={
        "consent_kind": "dating", "document_version": "v1"}).status_code == 401
    monkeypatch.setenv("MFD_APP_ENV", "prod")
    monkeypatch.delenv("MFD_PROFILE_V26_ENABLED", raising=False)
    assert client.get("/v1/me/profile",
                      headers={"Authorization": "Bearer fake"}).status_code == 404


def test_v26_rejects_dev_and_muv_prod_backend(monkeypatch):
    monkeypatch.setenv("MFD_APP_ENV", "prod")
    monkeypatch.setenv("MFD_PROFILE_V26_ENABLED", "true")
    monkeypatch.setenv("MFD_SUPABASE_PUBLISHABLE_KEY", "sb_publishable_test")
    for url in ("https://jtrdvnwbxpfdnbzasvcj.supabase.co",
                "https://mmainsfubddfojkbwjoq.supabase.co"):
        monkeypatch.setenv("MFD_SUPABASE_URL", url)
        response = client.get("/v1/me/profile",
                              headers={"Authorization": "Bearer qa.fake"})
        assert response.status_code == 503


def test_v26_body_cannot_set_foreign_user_id():
    body = {
        "user_id": "10000000-0000-4000-8000-000000000008",
        "display_name": "Runner", "city": "Querétaro",
        "date_of_birth": "1998-03-20", "sports": ["Running"]}
    res = client.put("/v1/me/profile", json=body,
                     headers={"Authorization": "Bearer aaa"})
    assert res.status_code == 422


def test_v26_rejects_underage_onboarding():
    from datetime import date
    born = date.today().replace(year=date.today().year - 12)
    res = client.put("/v1/me/profile", json={
        "display_name": "Example", "city": "Querétaro",
        "date_of_birth": born.isoformat(), "onboarding_complete": True
    }, headers={"Authorization": "Bearer abc"})
    assert res.status_code == 422


def test_v26_owner_scope_and_data_projection(monkeypatch):
    requests = []

    async def member(_token):
        return OWN

    async def provider(method, path, token, **kwargs):
        assert token == "valid"
        requests.append((method, path, kwargs))
        if method == "POST":
            return httpx.Response(201, json=[kwargs["data"]])
        return httpx.Response(200, json=[])

    monkeypatch.setattr(profile_v26, "_member", member)
    monkeypatch.setattr(profile_v26, "_provider", provider)
    headers = {"Authorization": "Bearer valid"}
    body = {
        "display_name": "Alex", "city": "Querétaro",
        "date_of_birth": "1994-06-05",
        "sports": ["Running", "Yoga"],
        "hobbies": ["Café", "Senderismo"],
        "fitness_goals": ["10K"], "onboarding_complete": True,
    }
    updated = client.put("/v1/me/profile", headers=headers, json=body)
    assert updated.status_code == 200
    assert updated.json()["profile"]["user_id"] == str(OWN)
    assert updated.json()["profile"]["sports"] == ["Running", "Yoga"]
    fetched = client.get("/v1/me/profile", headers=headers)
    assert fetched.status_code == 200
    assert fetched.json()["profile"] is None
    places = client.get("/v1/me/places", headers=headers)
    assert places.status_code == 200
    assert all(v.get("params", {}).get("user_id") == "eq." + str(OWN)
               for m, p, v in requests if m == "GET" and
               p.endswith(("member_profiles_v26", "member_training_places_v26")))
    assert not any("service_role" in str(r) for r in requests)


def test_v26_training_place_is_never_in_public_profile(monkeypatch):
    async def member(_):
        return OWN
    async def provider(method, path, token, **kwargs):
        return httpx.Response(201, json=[kwargs.get("data", {})])
    monkeypatch.setattr(profile_v26, "_member", member)
    monkeypatch.setattr(profile_v26, "_provider", provider)
    r = client.post("/v1/me/places",
                    json={"venue_kind": "studio", "place_name": "Studio Private",
                          "city": "Querétaro", "general_zone": "Norte"},
                    headers={"Authorization": "Bearer valid"})
    assert r.status_code == 201
    assert r.json()["place"]["user_id"] == str(OWN)


def test_v26_photos_remove_exif_and_deny_invalid_payload():
    content = BytesIO()
    img = Image.new("RGB", (400, 300), "red")
    exif = img.getexif()
    exif[274] = 1
    exif[270] = "private information"
    img.save(content, format="JPEG", exif=exif)
    result = profile_v26._safe_photo(content.getvalue(), "image/jpeg")
    reopened = Image.open(BytesIO(result))
    assert not reopened.getexif()
    assert reopened.size == (400, 300)
    from fastapi import HTTPException
    try:
        profile_v26._safe_photo(b"<svg/>", "image/svg+xml")
        assert False, "SVG should be rejected"
    except HTTPException as e:
        assert e.status_code == 413


def test_v26_rejects_anonymous_provider_even_with_token(monkeypatch):
    monkeypatch.setenv("MFD_APP_ENV", "prod")
    monkeypatch.setenv("MFD_PROFILE_V26_ENABLED", "true")
    monkeypatch.setenv("MFD_SUPABASE_URL", "https://mfdproduction.supabase.co")
    monkeypatch.setenv("MFD_SUPABASE_PUBLISHABLE_KEY", "sb_publishable_test")
    async def provider(method, path, token, **kwargs):
        return httpx.Response(200, json={"id": str(OWN),
            "email_confirmed_at": "2026-11-10", "is_anonymous": True})
    monkeypatch.setattr(profile_v26, "_provider", provider)
    resp = client.get("/v1/me/profile",
                      headers={"Authorization": "Bearer test.token"})
    assert resp.status_code == 401
