#!/usr/bin/env python3
"""B8 safe-integration preflight; does not assert real browser E2E."""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
src = (root / 'apps/flutter_client/lib/src/features/member_dashboard_b8.dart').read_text()
home = (root / 'apps/flutter_client/lib/src/features/member_profile_v26.dart').read_text()
tests = (root / 'apps/flutter_client/test/member_dashboard_b8_test.dart').read_text()
readiness = json.loads((root / 'release/readiness.json').read_text())
assert "loadMyActivities()" in src
assert "booking['cancelled_at'] != null" in src
assert "booking['event_cancelled'] == true" in src
assert "date.isAfter(now)" in src
assert "b8-agenda-empty" in src and "b8-agenda-error" in src
assert "MemberAgendaB8(" in home and "import 'member_dashboard_b8.dart';" in home
assert "real next booking and recoverable offline error" in tests
assert readiness['release_channel'] == 'not_published'
assert all(g['status'] == 'pending' for g in readiness['gates'].values())
assert "service_role" not in src.lower()
print('B8 static preflight PASS; Flutter and human E2E remain required')
