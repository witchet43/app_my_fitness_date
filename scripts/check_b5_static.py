#!/usr/bin/env python3
"""B5 no-discovery-by-consent static contract. Not a substitute for SQL E2E."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
def read(path):return (root/path).read_text(encoding='utf8')
def check(label,text,parts):
    missing=[p for p in parts if p not in text]
    assert not missing,(label,missing)

sql=read('supabase/migrations/202611120022_fitdating_readiness_b5.sql')
check('SQL gate',sql,[
    "default false", "app_private.fitdating_gate_b5",
    "independently_verified_provider_live", "moderation_staffed",
    "privacy_review_approved", "release_approved",
    "if not app_private.b5_discovery_open() then",
    "app_private.community_deletion_requests_b4",
    "public.community_blocks_b4",
    "app_private.community_pilot_b4",
    "app_private.fitdating_preferences_b5",
    "public.fitdating_status_b5()",
    "public.fitdating_disable_b5()",
    "public.fitdating_save_preferences_b5(",
    "select 1 from auth.users",
    "app_private.brand_administrators",
    "member_profiles_v26",
    "p_requested and not exists",
    "dating_enabled=false",
])
assert sql.strip().endswith('commit;')
consent=read('supabase/migrations/202611120023_fitdating_consent_withdrawal_b5.sql')
check('Revocation',consent,[
    'delete from public.member_consents_v26',
    "consent_kind='dating'",
    'app_private.fitdating_consent_withdrawals_b5',
    'participation_requested=false',
    'dating_enabled=false',
    'grant execute on function public.fitdating_disable_b5()',
])
assert consent.strip().endswith('commit;')
assert "grant update on app_private.fitdating_gate_b5" not in sql.lower()
api=read('supabase/functions/member-api-v26/index.ts')
check('Gateway',api,[
    "fitdating_status_b5", "fitdating_save_preferences_b5",
    "fitdating_disable_b5", "validateDatingPreferencesB5",
    '"/v1/dating/candidates"', "if (!state.enabled) return error(403)",
])
assert 'service_role' not in api.lower().replace('service-role','')
widget=read('apps/flutter_client/lib/src/features/dating_v27.dart')
check('Flutter',widget,[
    'datingDraftB5(', 'datingStatus()',
    'datingCandidates()', 'disableDating()',
    'b5-save-preferences', 'b5-disable',
    'b5-separate-consent', 'b5-availability',
    'No se activó la búsqueda',
])
client=read('apps/flutter_client/lib/src/core/member_v26_api.dart')
check('client',client,[
    "implements ActivityRepository, CuratorRepository, CommunityRepository, DatingRepositoryB5",
    "Future<String> saveDatingPreferences", "Future<String> disableDating",
])
print('B5 fail-closed static contract PASS (runtime and E2E pending)')
