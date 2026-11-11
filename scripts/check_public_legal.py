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
    assert "<script" not in body.lower(), slug
print("Legal pages static integrity: OK (no assertion of legal certification).")
