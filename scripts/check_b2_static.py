#!/usr/bin/env python3
"""Offline B2 source-invariant QA; complements, never replaces, real SQL E2E."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def source(relative: str) -> str:
    file = ROOT / relative
    assert file.is_file(), f"B2 file missing: {relative}"
    return file.read_text(encoding="utf-8")


def require(name: str, contents: str, fragments: tuple[str, ...]) -> None:
    missing = [part for part in fragments if part not in contents]
    assert not missing, f"{name}: required invariants missing: {missing}"


sql = source("supabase/migrations/202611120017_activity_lifecycle_b2.sql")
require("B2 SQL", sql, (
    "add column if not exists cancelled_at",
    "revoke update, delete on public.event_rsvps from authenticated",
    "for update",
    "on conflict (event_id, user_id)",
    "r.cancelled_at is null",
    "app_private.is_brand_owner()",
    "function public.my_activity_reservations()",
    "function public.cancel_activity_rsvp(uuid)",
    "function public.my_organized_activities()",
    "function public.admin_curated_activities()",
    "function public.admin_publish_curated_activity(",
    "function public.cancel_organized_activity(uuid)",
    "function public.admin_cancel_curated_activity(uuid)",
))
assert sql.strip().startswith("--") and sql.rstrip().endswith("commit;")
assert sql.count("security definer") >= 7
assert "auth.uid()" in sql
edge = source("supabase/functions/member-api-v26/index.ts")
require("B2 Edge API", edge, (
    '"/v1/me/activities"',
    '"/v1/admin/activities"',
    '"/v1/organizer/activities"',
    "cancel_activity_rsvp",
    "cancel_organized_activity",
    "admin_publish_curated_activity",
    "admin_cancel_curated_activity",
    "verify(token)",
    'cancelled_at: "is.null"',
    "allowedOrigins.has(requestedOrigin)",
    "new Headers(response.headers)",
))
assert "service_role" not in edge.lower()
client = source("apps/flutter_client/lib/src/core/member_v26_api.dart")
require("B2 Flutter API", client, (
    "implements ActivityRepository, CuratorRepository",
    "loadMyActivities()",
    "cancelActivity(String eventId)",
    "loadOrganizedActivities()",
    "cancelOrganizedActivity(String eventId)",
    "adminActivities()",
    "adminPublishActivity(",
    "adminCancelActivity(String eventId)",
))
role = source("apps/flutter_client/lib/src/member_v26_app.dart")
require("Role isolation", role, (
    "brand_admin_session",
    "curatorApi:widget.api",
    "activityPreviewApi:widget.api",
))
admin = source("apps/flutter_client/lib/src/features/brand_admin_home.dart")
require("Owner UI", admin, (
    "b2-admin-open-curation", "b2-admin-member-preview",
))
readonly = source("apps/flutter_client/lib/src/features/activities_b1.dart")
require("Admin member preview is read-only", readonly, (
    "this.readOnly = false",
    "if (!widget.readOnly)",
    "widget.readOnly || joined || busy",
))
print("B2 offline invariants PASS (not a runtime security test)")
