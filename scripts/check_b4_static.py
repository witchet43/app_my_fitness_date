#!/usr/bin/env python3
"""B4 zero-runner security preflight. Not a replacement for PostgreSQL E2E."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def source(path: str) -> str:
    p = ROOT / path
    assert p.is_file(), f'B4 file missing: {path}'
    return p.read_text(encoding='utf-8')


def must(name: str, source_text: str, phrases: list[str]) -> None:
    missing = [p for p in phrases if p not in source_text]
    assert not missing, f'{name}: missing {missing}'


sql = source('supabase/migrations/202611120019_community_safety_b4.sql')
must('B4 SQL', sql, [
    'enable row level security',
    'revoke all on public.community_posts_b4',
    'revoke all on public.community_reports_b4',
    'community_actor_b4()',
    'community_feed_b4(',
    'community_publish_b4(',
    'community_block_b4(',
    'community_report_b4(',
    'community_my_blocks_b4()',
    'community_remove_post_b4(',
    'community_request_deletion_b4()',
    'admin_community_queue_b4()',
    'admin_community_resolve_b4(',
    'community_moderation_audit_b4',
    'community_suspensions_b4',
    'app_private.is_brand_owner()',
    'app_private.community_deletion_requests_b4',
    "app_private.community_actor_b4()='available'",
    'b.blocker_id=(select auth.uid()) and b.blocked_id=p.author_id',
    'b.blocked_id=(select auth.uid()) and b.blocker_id=p.author_id',
    'on conflict do nothing',
    'pg_advisory_xact_lock',
    'admin_community_publish_b4(',
    'admin_community_announcements_b4()',
    'admin_community_remove_announcement_b4(',
])
assert sql.rstrip().endswith('commit;')
assert sql.count('security definer') >= 12
assert 'grant select on public.community_reports_b4 to' not in sql
assert 'grant insert on public.community_posts_b4 to' not in sql

optout = source('supabase/migrations/202611120020_community_optout_b4.sql')
must('B4 separate community opt-out', optout, [
    'app_private.community_participation_b4',
    'community_set_participation_b4',
    "if not p_enabled then",
    "status='removed'",
])
pilot = source('supabase/migrations/202611120021_community_closed_pilot_b4.sql')
must('B4 closed pilot', pilot, [
    'app_private.community_pilot_b4',
    'app_private.community_pilot_audit_b4',
    "then return 'pilot_closed'",
    "allowed.user_id=p.author_id and allowed.active=true",
    'admin_community_admit_pilot_b4',
    'admin_community_revoke_pilot_b4',
    'app_private.is_brand_owner()',
])
assert pilot.rstrip().endswith('commit;')


api = source('supabase/functions/member-api-v26/index.ts')
must('B4 Edge API', api, [
    'validateCommunityPost',
    'validateCommunityReport',
    'validateModeration',
    'communityFeedCursor',
    'communityRemovePostId(route)',
    '"/v1/community/status"',
    '"/v1/community/feed"',
    '"/v1/community/block"',
    '"/v1/community/report"',
    '"/v1/me/community/deletion"',
    '"/v1/admin/community/reports"',
    '"/v1/admin/community/deletions"',
    '"/v1/admin/community/announcements"',
    '"/v1/admin/community/resolve"',
    '"/v1/admin/community/pilot"',
    '"/v1/admin/community/pilot/revoke"',
    '"/v1/me/community/participation"',
    'https://b4-preview.my-fitness-date.pages.dev',
])
assert 'service_role' not in api.lower()

flutter = source('apps/flutter_client/lib/src/features/community_b4.dart')
must('B4 member UI', flutter, [
    'acceptCommunityConsent()',
    'publishCommunityPost(',
    'setCommunityBlock(',
    'reportCommunity(',
    'removeCommunityPost(',
    'requestCommunityDeletion()',
    'b4-consent-submit',
    'b4-community-leave',
    'b4-community-rejoin',
    'pilot_closed',
    'b4-block-confirm',
    'b4-report-submit',
    'b4-delete-request-confirm',
    'is_official',
])
moderation = source(
    'apps/flutter_client/lib/src/features/community_moderation_b4.dart'
)
must('B4 owner UI', moderation, [
    'resolveModerationReport(',
    'adminPublishCommunityAnnouncement(',
    'moderationDeletionRequests()',
    'b4-moderation-submit',
    'b4-announcement-submit',
])
root = source('apps/flutter_client/lib/src/member_v26_app.dart')
assert 'communityAdmin:widget.api' in root
assert 'brand_admin_session' in root
profile = source('apps/flutter_client/lib/src/features/member_profile_v26.dart')
assert 'CommunityB4(api:widget.api)' in profile
assert 'Comunidad deportiva' in profile
pilotui = source('apps/flutter_client/lib/src/features/community_pilot_b4.dart')
must('B4 pilot management UI', pilotui, [
    'pilotMembers()', 'admitPilotMember(', 'revokePilotMember(',
    'b4-pilot-invite', 'b4-pilot-revoke-confirm',
])
assert 'CommunityPilotB4(api:widget.api)' in moderation
# A production-impacting Flutter lifecycle regression was caught by B4
# widget tests: controllers in temporary modal closures were disposed before
# Navigator's reverse animation detached their TextFields. Keep the stricter
# value-callback pattern until those fields become owned StatefulWidgets.
for widget_path in (
    'apps/flutter_client/lib/src/features/community_b4.dart',
    'apps/flutter_client/lib/src/features/community_moderation_b4.dart',
    'apps/flutter_client/lib/src/features/community_pilot_b4.dart',
):
    widget = source(widget_path)
    assert 'TextEditingController()' not in widget, (
        f'{widget_path}: ephemeral TextEditingController may outlive dialog')
    assert '.dispose()' not in widget, (
        f'{widget_path}: transient dialog controller lifecycle needs review')

print('B4 source invariants PASS (runtime and human moderation checks pending)')
