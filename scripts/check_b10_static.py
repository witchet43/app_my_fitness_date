#!/usr/bin/env python3
"""B10 offline guardrails. NOT proof of real E2E, compliance or app release."""
import json
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
read = lambda path: (root / path).read_text(encoding="utf8")
domain = read("apps/flutter_client/lib/src/core/rhythm_concept_b10.dart")
ui = read("apps/flutter_client/lib/src/features/rhythm_concept_lab_b10.dart")
entry = read("apps/flutter_client/lib/src/features/dating_v27.dart")
tests = read("apps/flutter_client/test/rhythm_concept_b10_test.dart")
audit = read("docs/product/B10_FITTED_84_REQUIREMENTS_AUDIT.md")
release = json.loads(read("release/readiness.json"))

for token in [
    "explainRhythmB10(", "hypotheticalRhythmB10(",
    "hypotheticalActiveDatesB10(", "importance:'high'",
    "importance:'medium'", "importance:'low'",
    "List<RhythmReasonB10>.unmodifiable",
]:
    assert token in domain, token
for token in [
    "How I Move", "How I Live", "How I Relate", "b10-language",
    "b10-fiction-disclaimer", "b10-prototype-only",
    "b10-gym-c-locked", "b10-locked-policy", "b10-after-mutual",
]:
    assert token in ui, token
assert "rhythm_concept_lab_b10.dart" in entry
assert "b10-enter-rhythm-lab" in entry
assert "same_gym_different_time" in domain
assert "exclude_gym" in domain
assert "allow_same_gym" not in domain
assert all(x not in ui for x in [
    "SupabaseClient", "http.Client", "import 'dart:io'",
    "service_role", "datingCandidates(",
])
assert "PRIVATE_GYM_DO_NOT_LEAK" in tests
assert "throwsUnsupportedError" in tests
assert len(re.findall(r"^\\| [FNE]-\\d{3} \\|", audit, re.MULTILINE)) == 84
assert release["release_channel"] == "not_published"
assert all(g["status"] == "pending" for g in release["gates"].values())
print("B10 STATIC PREFLIGHT PASS — not a Flutter build or product signoff")
