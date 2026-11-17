#!/usr/bin/env python3
"""Check public legal pages before a static-only Cloudflare release."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
EMAIL = "witchet43@gmail.com"
for slug, title in (("privacy", "Aviso de privacidad"), ("terms", "Términos y condiciones")):
    p = ROOT / "apps" / "flutter_client" / "cloudflare" / slug / "index.html"
    body = p.read_text(encoding="utf-8")
    assert "<!doctype html>" in body.lower(), slug
    assert "<html lang=\"es-MX\">" in body, slug
    assert title in body, slug
    assert EMAIL in body, slug
    assert "Julio Alejandro Villeda Maldonado" in body, slug
    assert "Matancillas 1641" in body, slug
    assert f'https://my-fitness-date.pages.dev/{slug}/' in body, slug
    assert len(body) > 3000, slug
    assert not re.search(r"\[(PENDIENTE|TODO|TBD)", body, flags=re.I), slug
    assert '<script defer src="/brand-legal.js"></script>' in body, slug
    assert "data-brand-name" in body and "data-brand-vector" in body, slug
    assert "My Fitness Date es un nombre comercial" not in body, slug
    assert "♥" not in body and "#c8ff6b" not in body, slug
brand_js=(ROOT/"apps/flutter_client/cloudflare/brand-legal.js").read_text()
assert "mfd_brand_live" in brand_js and "textContent=s.name" in brand_js
assert "'__FITTED_PUBLIC_BRAND_KEY__'" in brand_js
assert "innerHTML" not in brand_js
assert "safeLogo.test(s.logo)" in brand_js
print("Legal pages, safe dynamic brand client and unchanged legal identity: OK (not legal certification).")
