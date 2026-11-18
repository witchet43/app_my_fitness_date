#!/usr/bin/env python3
"""Classify changes without contacting GitHub; conservative defaults for unknown paths."""
import argparse
import json
import subprocess

def classify(paths):
    paths = sorted(set(p.strip() for p in paths if p.strip()))
    doc = lambda p: p.startswith("docs/") or p.endswith(".md")
    flutter = any(p.startswith(("apps/flutter_client/", "cloudflare/")) or p in (
        "scripts/build_fitted_brand_assets.py", "scripts/check_fitted_brand_assets.py",
        "scripts/check_public_legal.py", "scripts/verify_hosted_auth.py") for p in paths)
    db = any(p.startswith("supabase/migrations/") for p in paths)
    edge = any(p.startswith("supabase/functions/") for p in paths)
    mobile = any(p.startswith(("android/", "ios/")) or "/android/" in p or "/ios/" in p for p in paths)
    infra = any(p.startswith(".github/") or p in ("product.manifest.yaml", "AGENTS.md") for p in paths)
    unknown = [p for p in paths if not (doc(p) or p.startswith(("apps/", "cloudflare/", "supabase/", ".github/", "scripts/", "tests/")) or p in ("product.manifest.yaml", "AGENTS.md"))]
    if unknown:
        flutter = True  # safer than skipping a potentially relevant app edit
    return dict(paths=paths, flutter=flutter, database=db, edge=edge, mobile=mobile,
                infrastructure=infra, documentation_only=bool(paths) and all(map(doc,paths)),
                full_gate=(db or edge or infra or bool(unknown)))

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--base", default="HEAD~1")
    ap.add_argument("--head", default="HEAD")
    ap.add_argument("--files", nargs="*")
    args=ap.parse_args()
    files=args.files if args.files is not None else subprocess.check_output(
        ["git","diff","--name-only",args.base,args.head],text=True).splitlines()
    result=classify(files)
    print(json.dumps(result,sort_keys=True))
    with open(__import__("os").environ.get("GITHUB_OUTPUT","/dev/null"),"a") as out:
        for key,value in result.items():
            if isinstance(value,bool): out.write(f"{key}={str(value).lower()}\n")

if __name__=="__main__": main()
