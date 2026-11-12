#!/usr/bin/env python3
"""Brand Admin deploy/security contracts without third-party dependencies."""
from pathlib import Path
from html.parser import HTMLParser
import re
import unittest

ROOT=Path(__file__).resolve().parents[1]
ADMIN=ROOT/"apps/flutter_client/cloudflare/admin/branding"
SQL=(ROOT/"supabase/migrations/202611110015_brand_admin_foundation.sql").read_text()
HTML=(ADMIN/"index.html").read_text()
JS=(ADMIN/"admin-brand.js").read_text()
CSS=(ADMIN/"admin-brand.css").read_text()
HEADERS=(ROOT/"apps/flutter_client/cloudflare/_headers").read_text()
REDIRECTS=(ROOT/"apps/flutter_client/cloudflare/_redirects").read_text()
RELEASE=(ROOT/".github/workflows/cloudflare-pages-production.yml").read_text()

class Checker(HTMLParser):
    def __init__(self):
        super().__init__();self.ids=set();self.links=[];self.scripts=[]
    def handle_starttag(self,tag,attrs):
        a=dict(attrs)
        if "id" in a:
            assert a["id"] not in self.ids, "duplicate DOM id"
            self.ids.add(a["id"])
        if tag=="script":self.scripts.append(a.get("src"))
        if tag=="link" and a.get("rel")=="stylesheet":self.links.append(a.get("href"))

class BrandAdminSecurityTest(unittest.TestCase):
    def test_admin_page_is_separate_and_mfa_gate_exists(self):
        doc=Checker();doc.feed(HTML)
        self.assertEqual(doc.scripts,["./admin-brand.js"])
        self.assertEqual(doc.links,["./admin-brand.css"])
        for id_ in ("login-screen","mfa-screen","studio","admin-email",
                    "admin-password","totp-code","brand-name","palette-select",
                    "palette-name","font-upload","font-license","logo-upload",
                    "image-kind","image-upload","draft-select","stage","feedback"):
            self.assertIn(id_,doc.ids)
        self.assertIn("MFA obligatorio",HTML)
        self.assertIn("No existe registro público de administradores",HTML)
        self.assertNotIn("Crear cuenta de administrador",HTML)

    def test_auth_is_denied_by_default_and_never_uses_user_metadata(self):
        for required in ("brand_admin_status","brand_admin_session",
                         "auth/v1/token?grant_type=password","/auth/v1/factors",
                         "/challenge","/verify","identityReset()"):
            self.assertIn(required,JS)
        for forbidden in ("service_role","sb_secret_","localStorage",
                          "user_metadata","signUp(","grant admin", "window.ADMIN_SECRET"):
            self.assertNotIn(forbidden,JS)
        self.assertIn("brand_administrators",SQL)
        self.assertIn("email_confirmed_at is not null",SQL)
        self.assertIn("not exists (",SQL)
        self.assertIn("member_profiles_v26",SQL)
        self.assertIn("auth.jwt()->>'aal'",SQL)
        self.assertIn("'aal2'",SQL)
        self.assertIn("revoke all on app_private.brand_administrators",SQL)
        self.assertIn("No real admin is seeded",SQL)

    def test_configuration_is_server_versioned_and_not_published_directly(self):
        for name in ("brand_palettes","brand_design_drafts","brand_design_revisions",
                     "brand_assets","brand_release_requests"):
            self.assertIn("create table public."+name,SQL)
            self.assertIn("alter table public."+name+" enable row level security",SQL)
            self.assertIn("revoke all on public."+name,SQL)
        self.assertIn("brand_design_revision_log",SQL)
        self.assertIn("status = 'pending_review'",SQL)
        self.assertIn("No INSERT privileges or policies for anon",SQL)
        self.assertIn("Guard",HTML)
        self.assertIn("Guardar borrador en Supabase",HTML)
        self.assertIn("No se publicó ningún cambio",JS)
        self.assertNotIn("grant update on public.brand_release_requests",SQL)

    def test_private_storage_and_upload_types(self):
        self.assertIn("mfd-brand-drafts",SQL)
        self.assertIn("file_size_limit",SQL)
        self.assertIn("8388608",SQL)
        self.assertIn("mfd-brand-drafts",SQL)
        self.assertIn(",false,8388608",SQL.replace(" ","").replace("\n",""))
        self.assertIn("license_basis",SQL)
        self.assertIn("storage.foldername(name)",SQL)
        self.assertIn("brand_drafts_admin_select",SQL)
        self.assertIn("brand_drafts_admin_insert",SQL)
        self.assertNotIn("mfd_brand_drafts_admin_delete",SQL)
        for token in ("font/woff2","image/png","image/jpeg","image/webp",
                      "validateFile","file.slice(0,16).arrayBuffer()",
                      "URL.createObjectURL","owner_approval_required"):
            if token=="owner_approval_required":continue
            self.assertIn(token,JS+SQL)
        self.assertNotIn("image/svg+xml",SQL)
        self.assertIn("SVG externo no se admite",HTML)

    def test_cloudflare_route_and_content_policy(self):
        self.assertIn("/admin/branding/ /admin/branding/index.html 200",REDIRECTS)
        self.assertLess(REDIRECTS.index("/admin/branding/ /admin/branding/index.html"),
                        REDIRECTS.index("/* /index.html"))
        self.assertIn("/admin/branding/*",HEADERS)
        self.assertIn("script-src 'self'",HEADERS)
        self.assertIn("frame-ancestors 'none'",HEADERS)
        self.assertIn("noindex, nofollow",HEADERS)
        self.assertIn("cloudflare/admin build/web/",RELEASE)
        self.assertIn("admin/branding/index.html",RELEASE)
        self.assertIn("PUBLIC CLOUDFLARE RELEASE + BRAND LAB + ADMIN SHELL VERIFIED",RELEASE)
        self.assertIn("prefers-reduced-motion",CSS)

if __name__=="__main__":
    unittest.main()
