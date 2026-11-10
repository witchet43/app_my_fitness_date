#!/usr/bin/env python3
"""Validate SaaS Factory v1.9 registry; no third-party deps.

Default mode checks structure, not compliance. --release is fail-closed until
all applicable P0 controls have evidence or a justified N/A exception.
"""
import argparse
import csv
import json
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REGISTER = ROOT / "docs/compliance/SAAS_V19_CONTROL_BASELINE.csv"
EXPECTED = {
    "ENG":25,"UX":16,"AI":15,"INT":15,"DEV":13,"DOC":5,
    "ID":5,"SAAS":13,"FAC":13,"SAFE":7,"COST":24,
    "OPS-HB":10,"MP":10,"XPLAT":24,"PX":24
}
REQUIRED_BETA_GATES = (
    'hosted_email_configuration', 'external_age_verification',
    'staffed_moderation', 'legal_privacy_retention', 'real_auth_erasure_e2e',
    'physical_android_qa', 'physical_ios_qa',
    'independent_security_review', 'support_and_incident_response',
)
STATES = {"NO_EVALUADO","EN_PROGRESO","CUMPLE","NO_CUMPLE","NO_APLICA","BLOQUEADO"}

def family(control_id):
    return "OPS-HB" if control_id.startswith("OPS-HB-") else control_id.split("-")[0]

def validate(rows, *, release=False):
    problems = []
    if len(rows) != 219:
        problems.append(f"Expected 219 controls; got {len(rows)}")
    ids = [r.get("control_id", "").strip() for r in rows]
    for cid, count in Counter(ids).items():
        if count > 1:
            problems.append(f"Duplicate control: {cid}")
    totals = Counter(family(cid) for cid in ids)
    if dict(totals) != EXPECTED:
        problems.append(f"Control families mismatch: {dict(totals)}")
    for row in rows:
        cid = row.get("control_id", "").strip()
        state = row.get("estado", "").strip()
        priority = row.get("prioridad", "").strip()
        evidence = row.get("evidencia_url", "").strip()
        exception = row.get("excepcion_justificada", "").strip()
        owner = row.get("responsable", "").strip()
        if state not in STATES:
            problems.append(f"{cid}: invalid status {state}")
        if row.get("proyecto") != "my_fitness_date":
            problems.append(f"{cid}: incorrect project")
        if state == "CUMPLE" and (not evidence or not owner):
            problems.append(f"{cid}: CUMPLE requires owner and evidence URL")
        if state == "NO_APLICA" and (not exception or not owner):
            problems.append(f"{cid}: NO_APLICA requires owner and justification")
        if release and priority.startswith("P0") and state not in {"CUMPLE","NO_APLICA"}:
            problems.append(f"{cid}: unresolved P0 before release ({state})")
    return problems


def validate_existing_release_gates():
    """Do not let the 219-control CSV bypass the pre-existing beta gates."""
    manifest = json.loads((ROOT / "release/readiness.json").read_text(encoding="utf-8"))
    issues = []
    gates = manifest.get("gates", {})
    for key in REQUIRED_BETA_GATES:
        item = gates.get(key, {})
        if item.get("status") != "verified":
            issues.append(f"Beta gate pending: {key}")
        elif not (str(item.get("evidence_url", "")).startswith("https://")
                  and item.get("verified_at")):
            issues.append(f"Beta gate lacks verified dated evidence: {key}")
    if manifest.get("release_channel") == "not_published":
        issues.append("Release channel still not_published")
    return issues

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--release", action="store_true",
                        help="Require every applicable P0 resolved with evidence")
    args = parser.parse_args()
    with REGISTER.open(encoding="utf-8-sig", newline="") as file:
        rows = list(csv.DictReader(file))
    problems = validate(rows, release=args.release)
    if args.release:
        problems.extend(validate_existing_release_gates())
    if problems:
        for problem in problems[:30]:
            print("FAIL:", problem)
        if len(problems) > 30:
            print(f"... and {len(problems)-30} additional failures")
        raise SystemExit(1)
    print(f"Registry integrity OK: {len(rows)} controls. "
          + ("Release gate OK" if args.release else "NOT a compliance certification."))

if __name__ == "__main__":
    main()
