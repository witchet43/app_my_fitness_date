#!/usr/bin/env python3
"""Production Auth preflight: zero user creation and no OAuth secrets.

Read only the public GoTrue settings and confirm Google's authorization
endpoint redirects to a Google-owned HTTPS login URL. The user must still
complete an interactive OAuth round-trip in a browser.
"""
import json
from pathlib import Path
import re
from urllib.parse import urlencode, urlparse
from urllib.request import Request, build_opener, HTTPRedirectHandler
from urllib.error import HTTPError, URLError

PROJECT = "https://jtrdvnwbxpfdnbzasvcj.supabase.co"
HOME = "https://my-fitness-date.pages.dev/"

class DoNotRedirect(HTTPRedirectHandler):
    def redirect_request(self, request, fp, code, msg, headers, newurl):
        return None

def public_key():
    workflow = (Path(__file__).resolve().parents[1] /
                ".github/workflows/cloudflare-pages-production.yml").read_text()
    match = re.search(r"--dart-define=MFD_PROD_SUPABASE_PUBLISHABLE_KEY=(sb_publishable_[A-Za-z0-9_-]+)", workflow)
    if not match:
        raise RuntimeError("Production publishable key is not configured")
    return match.group(1)

def probe(path, *, redirects=False):
    request = Request(PROJECT + path, headers={
        "apikey": public_key(),
        "User-Agent": "MyFitnessDate-AuthPreflight/1.0",
        "Accept": "application/json",
    })
    opener = build_opener() if redirects else build_opener(DoNotRedirect())
    try:
        with opener.open(request, timeout=15) as resp:
            return resp.status, resp.headers, resp.read(16000)
    except HTTPError as exc:
        return exc.code, exc.headers, exc.read(16000)

def main():
    status, _, data = probe("/auth/v1/settings")
    if status != 200:
        raise RuntimeError(f"Auth settings unavailable (HTTP {status})")
    config = json.loads(data)
    providers = config.get("external", {})
    if not isinstance(providers, dict):
        raise RuntimeError("Invalid Auth settings response")
    if providers.get("google") is not True:
        raise RuntimeError("Google OAuth is not enabled on hosted Supabase")
    if providers.get("email") is not True:
        raise RuntimeError("Email authentication is not enabled")
    if config.get("disable_signup") is True:
        raise RuntimeError("Supabase Auth account registration is disabled")
    params = urlencode({
        "provider": "google",
        "redirect_to": HOME,
        "code_challenge": "a" * 43,
        "code_challenge_method": "s256",
    })
    status, headers, data = probe("/auth/v1/authorize?" + params)
    location = headers.get("Location", "")
    parsed = urlparse(location)
    if status not in (302, 303) or parsed.scheme != "https" or parsed.hostname not in {
        "accounts.google.com", "accounts.googleusercontent.com"
    }:
        raise RuntimeError(f"Google handshake failed (HTTP {status}); "
                           "check provider and redirect allowlist, without exposing tokens")
    print("OK: hosted email signup enabled; Google OAuth handshake redirects to Google.")
    print("NOTE: final Google callback and real email delivery require browser E2E.")

if __name__ == "__main__":
    main()
