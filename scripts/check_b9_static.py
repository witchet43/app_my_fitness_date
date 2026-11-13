#!/usr/bin/env python3
"""Offline B9 invariants. Source contracts are NOT browser/security signoff."""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
def src(path):
    return (root / path).read_text(encoding='utf8')

lib = src('apps/flutter_client/lib/src/core/activity_discovery_b9.dart')
widget = src('apps/flutter_client/lib/src/features/activities_b1.dart')
test = src('apps/flutter_client/test/activity_discovery_b9_test.dart')
readiness = json.loads(src('release/readiness.json'))
for must in (
    "activity['event_cancelled'] == true",
    "upcomingOnly && (date == null || !date.isAfter(now))",
    "title.contains(text)", "discipline.contains(text)",
    "location.contains(text)", "return a.key.compareTo(b.key)",
    "List<Map<String, dynamic>>.unmodifiable",
    "Only public fields are allowed",
):
    assert must in lib, must
for must in (
    "discoverActivitiesB9(", "activityFilterOptionsB9(",
    "b9-search", "b9-sport-filter", "b9-city-filter",
    "b9-only-upcoming", "b9-no-results", "b9-results-count",
    "b9-reset", "if (!loading && error == null)",
):
    assert must in widget, must
assert "accent-insensitive search" in test
assert "sport, city and date filters work on mobile" in test
assert "service_role" not in lib.lower()
assert readiness['release_channel'] == 'not_published'
assert all(g['status'] == 'pending' for g in readiness['gates'].values())
print("B9 static preflight PASS — live security/E2E remains pending")
