#!/usr/bin/env python3
"""Read-only production checks. Never writes to Supabase or Cloudflare."""
import json
import urllib.error
import urllib.request

BASE="https://jtrdvnwbxpfdnbzasvcj.supabase.co"
SITE="https://my-fitness-date.pages.dev"

def request(url,method="GET",origin=None):
    headers={"User-Agent":"Fitted-Production-Preflight/1.0","Cache-Control":"no-cache"}
    if origin: headers["Origin"]=origin
    req=urllib.request.Request(url,headers=headers,method=method)
    try:
        with urllib.request.urlopen(req,timeout=20) as response:
            return response.status,response.read()
    except urllib.error.HTTPError as exc:
        return exc.code,exc.read()

def check():
    code,data=request(BASE+"/functions/v1/heartbeat")
    if code!=200: raise RuntimeError(f"Heartbeat HTTP {code}")
    h=json.loads(data)
    if h.get("status")!="ok" or h.get("dependencies",{}).get("database")!="ok":
        raise RuntimeError("Heartbeat database dependency unhealthy")
    code,data=request(SITE+"/mfd-release.json")
    if code!=200: raise RuntimeError(f"Release manifest HTTP {code}")
    release=json.loads(data)
    sha=release.get("commit","")
    if len(sha)!=40 or any(c not in "0123456789abcdef" for c in sha):
        raise RuntimeError("Release manifest has no valid SHA")
    for path in ("/v1/me/profile","/v1/dating/candidates"):
        status,_=request(BASE+"/functions/v1/member-api-v26"+path)
        if status!=401: raise RuntimeError(f"Anonymous-access safety check {path}: {status}")
    return {"status":"PASS","cloudflare_sha":sha,"database":"ok","anonymous_api":"denied"}

if __name__=="__main__":
    print(json.dumps(check(),sort_keys=True))
