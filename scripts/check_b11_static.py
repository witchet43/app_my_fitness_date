#!/usr/bin/env python3
"""Final build static P0 preflight: source guardrails, NOT a release sign-off."""
import json,re
from pathlib import Path

r=Path(__file__).resolve().parents[1]
read=lambda p:(r/p).read_text(encoding='utf8')
sql=read('supabase/migrations/202611120024_fitted_lifestyle_matching_b11.sql')
edge=read('supabase/functions/member-api-v26/index.ts')
api=read('apps/flutter_client/lib/src/core/member_v26_api.dart')
ui=read('apps/flutter_client/lib/src/features/dating_v27.dart')
lab=read('apps/flutter_client/lib/src/features/rhythm_concept_lab_b10.dart')
chat=read('apps/flutter_client/lib/src/features/dating_discovery_b11.dart')
validator=read('supabase/functions/member-api-v26/rhythm_validation_b11.ts')
tests=read('apps/flutter_client/test/fitted_end_to_end_b11_test.dart')
readiness=json.loads(read('release/readiness.json'))
ci=read('.github/workflows/ci.yml')

assert readiness['release_channel']=='not_published'
assert all(g['status']=='pending' for g in readiness['gates'].values())
assert len(re.findall(r'-f supabase/migrations/\d+_[\w]+\.sql',ci))==24
assert '202611120024_fitted_lifestyle_matching_b11.sql' in ci
assert 'fitted_lifestyle_b11_integration.sql' in ci
assert 'begin;' in sql.lower() and sql.lower().rstrip().endswith('commit;')
assert 'enable row level security' in sql.lower()
for required in [
 'public.member_rhythm_b11', 'public.member_consents_v26',
 'app_private.b5_discovery_open()', 'app_private.adult_eligible(',
 'app_private.community_pilot_b4', 'app_private.user_blocks',
 'app_private.fitdating_likes_b11','app_private.fitdating_matches_b11',
 'app_private.fitdating_messages_b11','app_private.fitdating_reports_b11',
 'fitdating_send_b11','fitdating_report_b11','fitdating_date_ideas_b11',
 'security definer set search_path=', 'no', 'app_private.consume_dating_quota',
 'public.community_reports_b4',
]:
 if required!='no':
  assert required in sql,required
assert "revoke all on app_private.fitdating_likes_b11" in sql
assert "to authenticated" in sql
assert "no shared" not in sql.lower()
assert 'b11_member_eligible' in sql and 'b11_pair_allowed' in sql
assert "b11_rhythm_select" in sql and "with check(" in sql
assert 'delete from public.member_rhythm_b11 where user_id=v_user' in sql
assert 'app_private.b11_reasons' in sql
assert 'gym_id' not in sql[sql.index('create function app_private.b11_reasons'):sql.index('create function app_private.b11_candidates')]
assert 'validateRhythmB11' in edge and 'fitdating_candidates_b11' in edge
assert 'b11-preview.my-fitness-date.pages.dev' in edge
assert 'MemberV26Api implements' in api and 'DatingRepositoryB11' in api
assert 'saveRhythmB11' in api and 'reportB11' in api
assert 'b11-open-real-discovery' in ui
assert 'b11-save-rhythm' in lab
assert 'b11-report' in chat and 'b11-send' in chat
assert 'user_id' in validator and 'validateRhythmB11' in validator
assert 'gym_id' in tests and 'canSave:false' in tests
print('B11 final static P0 checks PASS — human release gates remain closed')
