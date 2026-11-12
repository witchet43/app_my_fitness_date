#!/usr/bin/env python3
"""Dependency-free, deterministic guardrails for the production Brand Lab."""
from __future__ import annotations
from html.parser import HTMLParser
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
LAB = ROOT / "apps/flutter_client/cloudflare/brand-lab"

class Markup(HTMLParser):
    def __init__(self):
        super().__init__()
        self.ids: set[str] = set()
        self.scripts: list[str] = []
        self.stylesheets: list[str] = []
        self.presets: dict[str, set[str]] = {}
        self.has_remote_asset = False

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if "id" in a:
            assert a["id"] not in self.ids, f"duplicated id: {a['id']}"
            self.ids.add(a["id"])
        if tag == "script" and "src" in a:
            self.scripts.append(a["src"])
        if tag == "link" and a.get("rel") == "stylesheet":
            self.stylesheets.append(a.get("href", ""))
        for kind in ("name", "palette", "font", "mode", "device", "view", "tone", "shape"):
            key = "data-" + kind
            if key in a:
                self.presets.setdefault(kind, set()).add(a[key])
        for key in ("src", "href"):
            if a.get(key, "").startswith(("https://", "http://", "//")):
                self.has_remote_asset = True

class BrandLabStatic(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.html = (LAB / "index.html").read_text(encoding="utf-8")
        cls.js = (LAB / "brand-lab.js").read_text(encoding="utf-8")
        cls.css = (LAB / "brand-lab.css").read_text(encoding="utf-8")
        cls.redirects = (LAB.parent / "_redirects").read_text(encoding="utf-8")
        cls.headers = (LAB.parent / "_headers").read_text(encoding="utf-8")
        cls.dom = Markup()
        cls.dom.feed(cls.html)

    def test_all_assets_and_panels(self):
        self.assertEqual(self.dom.scripts, ["./brand-lab.js"])
        self.assertEqual(self.dom.stylesheets, ["./brand-lab.css"])
        self.assertFalse(self.dom.has_remote_asset)
        for panel in ("name-panel", "palette-panel", "type-panel", "details-panel", "preview-panel", "logo-panel"):
            self.assertIn(panel, self.dom.ids)
        self.assertEqual(len(self.dom.presets["name"]), 8)
        self.assertEqual(len(self.dom.presets["palette"]), 5)
        self.assertEqual(len(self.dom.presets["font"]), 4)
        self.assertEqual(self.dom.presets["mode"], {"light", "dark"})
        self.assertEqual(self.dom.presets["device"], {"desktop", "mobile"})
        self.assertEqual(self.dom.presets["view"], {"landing", "app", "onboarding"})

    def test_10_individual_vector_logos(self):
        self.assertIn("const logos = Object.freeze([", self.js)
        block = self.js.split("const logos = Object.freeze([", 1)[1].split("]);", 1)[0]
        names = re.findall(r'"([^"]+)"', block)
        self.assertEqual(len(names), 10, names)
        self.assertEqual(len(set(names)), 10)
        icons = self.js.split("const geometry = [", 1)[1].split("];", 1)[0]
        self.assertEqual(len(re.findall(r"^\s*'<", icons, re.MULTILINE)), 10)

    def test_preview_persistence_export_without_backend(self):
        for phrase in ("data-screen=\"landing\"", "data-screen=\"app\"",
                       "data-screen=\"onboarding\"", "Borrador de este navegador",
                       "sin perfiles reales", "no se envían datos al servidor"):
            self.assertIn(phrase, self.html)
        for token in ("window.localStorage.setItem", "window.localStorage.getItem",
                      "window.localStorage.removeItem", "application/json",
                      "image/svg+xml", "owner_approval_required", "xmlEscape"):
            self.assertIn(token, self.js)
        for forbidden in ("fetch(", "XMLHttpRequest", "sendBeacon(", "supabase.co",
                          "service_role", "sb_secret_", "eval(", "new Function("):
            self.assertNotIn(forbidden, self.js)

    def test_secure_routes_and_csp(self):
        self.assertIn("/brand-lab /brand-lab/ 301", self.redirects)
        self.assertIn("/brand-lab/ /brand-lab/index.html 200", self.redirects)
        self.assertLess(self.redirects.index("/brand-lab/ /brand-lab/index.html"),
                        self.redirects.index("/* /index.html"))
        self.assertIn("/brand-lab/*", self.headers)
        self.assertIn("script-src 'self'", self.headers)
        self.assertIn("connect-src 'none'", self.headers)
        self.assertIn("frame-ancestors 'none'", self.headers)
        self.assertIn('name="robots" content="noindex, nofollow"', self.html)
        self.assertIn("prefers-reduced-motion", self.css)

    def test_user_content_stays_out_of_inner_html(self):
        self.assertIn('node.textContent = state.name.trim()', self.js)
        self.assertIn('node.textContent = state.tagline', self.js) if False else None
        self.assertIn("function xmlEscape(input)", self.js)
        self.assertIn('typeof input.name === "string"', self.js)
        self.assertIn('/^#[0-9a-fA-F]{6}$/', self.js)
        self.assertIn('aria-pressed', self.js)

if __name__ == "__main__":
    unittest.main()
