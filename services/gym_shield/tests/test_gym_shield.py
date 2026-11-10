from fastapi import HTTPException
from fastapi.testclient import TestClient
from app import domain, main

client = TestClient(main.app)
morning = (domain.WeeklySlot(1, 420, 510),)
evening = (domain.WeeklySlot(1, 1080, 1170),)


def profile(**kwargs):
    data = dict(id="a", gym_id="gym-1", mode="same_gym_other_time",
                dating_enabled=True, weekly_slots=morning)
    data.update(kwargs)
    return domain.Profile(**data)


def test_exact_30_minute_buffer():
    assert not domain.schedules_separated(
        morning, (domain.WeeklySlot(1, 539, 600),))
    assert domain.schedules_separated(
        morning, (domain.WeeklySlot(1, 540, 600),))


def test_symmetry_and_double_optin():
    a = profile()
    b = profile(id="b", weekly_slots=evening)
    assert domain.eligible(a, b) and domain.eligible(b, a)
    assert not domain.eligible(a, profile(id="b", mode="other_gyms",
                                          weekly_slots=evening))


def test_other_gyms_override_schedule_but_not_blocks():
    a = profile(mode="other_gyms")
    b = profile(id="b", gym_id="gym-2", mode="other_gyms")
    assert domain.eligible(a, b)
    assert not domain.eligible(profile(blocked_ids=frozenset({"b"})), b)
    assert not domain.eligible(a, profile(id="b", gym_id="gym-2",
                                          blocked_ids=frozenset({"a"})))


def test_fail_closed_invalid_and_same_day():
    assert not domain.schedules_separated(morning, ())
    assert not domain.schedules_separated(
        morning, (domain.WeeklySlot(1, 1400, 60),))
    assert not domain.eligible(profile(), profile(id="b", weekly_slots=()))
    assert not domain.eligible(profile(), profile(id="b", gym_id=None))
    assert not domain.eligible(profile(), profile())
    assert not domain.eligible(profile(), profile(id="b", dating_enabled=False))
    assert not domain.eligible(
        profile(weekly_slots=(domain.WeeklySlot(1,420,510),
                              domain.WeeklySlot(3,420,510))),
        profile(id="b", weekly_slots=(domain.WeeklySlot(1,1080,1170),
                                      domain.WeeklySlot(3,420,470))))
    assert domain.eligible(profile(), profile(
        id="b", weekly_slots=(domain.WeeklySlot(2,420,510),)))


def test_no_user_supplied_personal_data():
    assert client.get("/internal/v1/dating/candidates").status_code == 401
    assert client.get("/internal/v1/dating/candidates?limit=50").status_code == 422


def test_rpc_response_strips_private_data(monkeypatch):
    async def fake_discover(token, limit):
        assert token == "fake" and limit == 1
        return main.CandidateResponse.model_validate({
            "items": [{"id": "10000000-0000-4000-8000-000000000002",
                       "display_name": "Demo", "city": "Qro",
                       "sports": ["Running"], "gym_id": "not-safe"}],
            "count": 1,
        })
    monkeypatch.setattr(main, "discover", fake_discover)
    response = client.get("/internal/v1/dating/candidates?limit=1",
                          headers={"X-End-User-Token": "fake"})
    assert response.status_code == 200
    assert "gym_id" not in response.text
    assert "weekly_slots" not in response.text


def test_missing_supabase_fails_closed(monkeypatch):
    import pytest
    monkeypatch.delenv("MFD_SUPABASE_URL", raising=False)
    with pytest.raises(HTTPException) as error:
        main.supabase_config()
    assert error.value.status_code == 503


def test_internal_candidate_response_has_no_store_headers():
    from uuid import UUID
    response = client.get("/internal/v1/dating/candidates")
    assert response.status_code == 401
    assert response.headers["Cache-Control"] == "no-store"
    assert response.headers["X-Content-Type-Options"] == "nosniff"
    assert response.headers["Referrer-Policy"] == "no-referrer"
    UUID(response.headers["X-Request-ID"])
