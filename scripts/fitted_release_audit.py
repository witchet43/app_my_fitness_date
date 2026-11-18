#!/usr/bin/env python3
"""Verify public Fitted deployment SHA and essential public endpoints, read-only."""
import argparse
import json
import time
import urllib.error
import urllib.request

BASE="https://my-fitness-date.pages.dev"

def get(path):
    req=urllib.request.Request(BASE+path,headers={"User-Agent":"Fitted-Release-Audit/1.0","Cache-Control":"no-cache"})
    with urllib.request.urlopen(req,timeout=20) as response:
        assert response.status == 200
        return response.read()

def verify(expected,attempts=12):
    last=None
    for n in range(attempts):
        try:
            release=json.loads(get("/mfd-release.json?check="+expected))
            if release.get("commit") != expected:
                raise ValueError(f"expected {expected}, deployed {release.get('commit')}")
            if b"flutter" not in get("/").lower():
                raise ValueError("canonical Flutter marker unavailable")
            for slug in ("terms","privacy"):
                if b"<html" not in get("/"+slug+"/").lower():
                    raise ValueError("legal route missing: "+slug)
            return dict(status="VERIFIED",commit=expected,url=BASE+"/",channel=release.get("channel"))
        except (ValueError,AssertionError,urllib.error.URLError,TimeoutError) as exc:
            last=str(exc)
            if n+1 < attempts: time.sleep(5)
    raise RuntimeError(f"Production SHA not verified: {last}")

if __name__=="__main__":
    p=argparse.ArgumentParser()
    p.add_argument("--sha",required=True)
    p.add_argument("--attempts",type=int,default=12)
    args=p.parse_args()
    print(json.dumps(verify(args.sha,args.attempts),sort_keys=True))
