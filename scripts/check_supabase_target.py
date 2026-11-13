#!/usr/bin/env python3
"""Refuse deployment against the wrong Supabase project.
Usage: python3 scripts/check_supabase_target.py development <project_ref>
No network, no credentials, no migration side effects.
"""
import json, re, sys
from pathlib import Path

def validate(name, project_ref, manifest=None):
    path = Path(__file__).resolve().parents[1] / 'infra/supabase-targets.json'
    manifest = manifest if manifest is not None else json.loads(path.read_text())
    environments = manifest['environments']
    if name not in environments:
        raise ValueError('Unknown environment')
    configured = environments[name]['project_id']
    production = environments['production']['project_id']
    if not re.fullmatch(r'[a-z]{20}', project_ref or ''):
        raise ValueError('Project ref invalid')
    if name == 'development':
        if not configured:
            raise ValueError('DEV not provisioned; refusing to write to production')
        if project_ref == production:
            raise ValueError('Production Supabase ref cannot be used as DEV')
    if configured != project_ref:
        raise ValueError('Requested Supabase ref mismatches environment manifest')
    return True

if __name__ == '__main__':
    if len(sys.argv) != 3:
        raise SystemExit('Usage: check_supabase_target.py <development|production> <project_ref>')
    try:
        validate(sys.argv[1],sys.argv[2])
        print('Supabase target guard PASS')
    except ValueError as exc:
        raise SystemExit(f'Supabase target guard BLOCKED: {exc}')
