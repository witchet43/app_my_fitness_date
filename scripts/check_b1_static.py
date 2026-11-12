#!/usr/bin/env python3
"""Fast, offline contract preflight. It does NOT replace SQL or browser E2E."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    file = ROOT / path
    assert file.is_file(), f"Missing B1 artifact: {path}"
    return file.read_text(encoding="utf-8")


def require(name: str, text: str, expected: list[str]) -> None:
    missing = [item for item in expected if item not in text]
    assert not missing, f"{name}: missing contractual safeguards: {missing}"


sql = read("supabase/migrations/202611120016_activity_rsvp_b1.sql")
require("B1 SQL", sql, [
    "for update", "capacity between 1 and 200",
    "drop policy if exists event_rsvps_join_future_event",
    "revoke insert (event_id, user_id)", "on conflict (event_id, user_id)",
    "auth.uid()", "interval '18 years'", "v27-terms-1", "v27-privacy-1",
    "grant execute on function public.confirm_activity_rsvp(uuid)",
    "to authenticated", "set search_path = ''",
])
api = read("supabase/functions/member-api-v26/index.ts")
require("Edge API", api, [
    '"/v1/activities"', '"/v1/me/organizer-status"',
    '"/v1/organizer/activities"', 'confirm_activity_rsvp',
    'verify(token)', "activityRsvpRoute(route)", "organizer_id: identity.id",
])
assert "service_role" not in api.lower(), "Edge API must never carry service key"
validator = read("supabase/functions/member-api-v26/activity_validation.ts")
require("Validated input", validator, [
    "validateActivityDraft", "activityRsvpRoute", "Number.isInteger",
    "180 * 24 * 60 * 60_000",
])
flutter = read("apps/flutter_client/lib/src/member_v26_app.dart")
require("Flutter journey", flutter, [
    "MemberOnboardingB1", "ActivitiesB1(api:widget.api)",
    "brand_admin_status", "brand_admin_session",
])
view = read("apps/flutter_client/lib/src/features/activities_b1.dart")
require("Activities UX", view, [
    "loadActivities()", "confirmActivity(id)", "publishActivity(payload)",
    "Participación confirmada", "b1-activities-empty",
])
print("B1 offline source contract: PASS (static only, not QA signoff)")
