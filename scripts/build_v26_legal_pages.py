#!/usr/bin/env python3
"""Stage approved V26 legal pages in the same Flutter web release.

Fail closed when final, reviewed documents are absent. Never package
unapproved drafts for the Google OAuth branding URLs.
"""
from __future__ import annotations

import argparse
from html import escape
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
DOCUMENTS = {
    "privacy": ("docs/legal/PRIVACY_V26_APPROVED.md", "Aviso de privacidad"),
    "terms": ("docs/legal/TERMS_V26_APPROVED.md", "Términos y condiciones"),
}
BLOCKED = ("[PENDIENTE", "NO PUBLICAR", "BORRADOR", "POR DEFINIR", "TODO:", "TBD")


def validate_approved(document: str, slug: str) -> None:
    text = document.upper()
    if any(marker in text for marker in BLOCKED):
        raise ValueError(f"{slug}: documento no aprobado o incompleto")
    if len(document.strip()) < 1200:
        raise ValueError(f"{slug}: texto insuficiente para publicar")
    if not re.search(r"^# .+", document, flags=re.MULTILINE):
        raise ValueError(f"{slug}: falta el título")
    if slug == "privacy" and "ARCO" not in text:
        raise ValueError("privacy: falta procedimiento de derechos ARCO")
    if "my-fitness-date.pages.dev" not in document:
        raise ValueError(f"{slug}: dominio de la aplicación no validado")


def render_html(markdown: str, title: str, slug: str) -> str:
    """Safe, minimal renderer: no raw HTML or scripts from document."""
    output: list[str] = []
    list_open = False
    for raw in markdown.splitlines():
        line = raw.strip()
        if not line:
            if list_open:
                output.append("</ul>")
                list_open = False
            continue
        escaped = escape(line)
        if line.startswith("# "):
            if list_open:
                output.append("</ul>")
                list_open = False
            output.append(f"<h1>{escape(line[2:])}</h1>")
        elif line.startswith("## "):
            if list_open:
                output.append("</ul>")
                list_open = False
            output.append(f"<h2>{escape(line[3:])}</h2>")
        elif line.startswith("- "):
            if not list_open:
                output.append("<ul>")
                list_open = True
            output.append(f"<li>{escape(line[2:])}</li>")
        elif line == "---":
            if list_open:
                output.append("</ul>")
                list_open = False
            output.append("<hr>")
        else:
            if list_open:
                output.append("</ul>")
                list_open = False
            output.append(f"<p>{escaped}</p>")
    if list_open:
        output.append("</ul>")
    body = "\n".join(output)
    canonical = f"https://my-fitness-date.pages.dev/{slug}/"
    other_slug = "terms" if slug == "privacy" else "privacy"
    other_label = "Términos" if slug == "privacy" else "Privacidad"
    return f"""<!doctype html>
<html lang="es-MX">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="robots" content="index,follow">
  <meta name="description" content="{escape(title)} de My Fitness Date">
  <link rel="canonical" href="{canonical}">
  <title>{escape(title)} — My Fitness Date</title>
  <style>
    :root {{ color-scheme: dark; }}
    * {{box-sizing:border-box}}
    body {{margin:0;background:#10121e;color:#f6f5f7;font:16px/1.65 system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif}}
    header,footer {{padding:20px 26px;background:#191d2c}}
    header a,footer a {{color:#c8ff6b;text-decoration:none}}
    main {{max-width:900px;margin:0 auto;padding:26px 24px 60px}}
    h1 {{font-size:clamp(28px,5vw,42px);line-height:1.15;color:#ff617b}}
    h2 {{font-size:22px;line-height:1.3;margin-top:34px}}
    p,li {{color:#d3d6df}} li {{margin-bottom:8px}}
    a {{color:#c8ff6b}} a:focus-visible {{outline:3px solid #c8ff6b;outline-offset:3px}}
  </style>
</head>
<body>
<header><a href="/" aria-label="Volver a My Fitness Date">♥ My Fitness Date</a></header>
<main id="main">{body}</main>
<footer><a href="/">Inicio</a> · <a href="/{other_slug}/">{other_label}</a></footer>
</body>
</html>
"""


def stage(root: Path, destination: Path) -> None:
    result: dict[str, str] = {}
    for slug, (relative, title) in DOCUMENTS.items():
        document = (root / relative).read_text(encoding="utf-8")
        validate_approved(document, slug)
        result[slug] = render_html(document, title, slug)
    # No partial output if either doc is absent, incomplete or unapproved.
    for slug, content in result.items():
        target = destination / slug / "index.html"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--destination", type=Path, required=True)
    args = parser.parse_args()
    stage(args.root, args.destination)
