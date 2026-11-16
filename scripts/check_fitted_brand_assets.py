#!/usr/bin/env python3
"""Fail the release if Flutter recreates its default icon, or if brand drifts."""
import argparse
import json
from pathlib import Path
from PIL import Image
from io import BytesIO

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--project", default="apps/flutter_client")
    args=p.parse_args()
    root=Path(args.project)
    icon=root/"assets/branding/fitted_motion_f.webp"
    alias=root/"assets/branding/mfd_icon.webp"
    assert icon.read_bytes()==alias.read_bytes(), "In-app F differs from launcher source"
    with Image.open(icon) as im:
        assert im.format=="WEBP" and im.size==(256,256), im.size
    web=root/"web"
    for name,size in [
        ("favicon.png",(48,48)),
        ("apple-touch-icon.png",(180,180)),
        ("icons/Icon-192.png",(192,192)),
        ("icons/Icon-512.png",(512,512)),
        ("icons/Icon-maskable-192.png",(192,192)),
        ("icons/Icon-maskable-512.png",(512,512)),
    ]:
        with Image.open(web/name) as im:
            assert im.format=="PNG" and im.size==size,(name,im.size)
            assert im.getpixel((0,0))!=(255,255,255), "Default Flutter icon present"
    m=json.loads((web/"manifest.json").read_text())
    assert m["name"]=="Fitted" and m["theme_color"]=="#0D1030"
    assert any("maskable" in entry.get("purpose","") for entry in m["icons"])
    html=(web/"index.html").read_text()
    assert '<title>Fitted</title>' in html
    assert 'apple-touch-icon.png' in html
    assert 'favicon.png' in html
    theme=(root/"lib/src/theme/fitness_date_theme.dart").read_text()
    for color in ("0xFF0D1030","0xFF65D3FA","0xFFC4ACFF","0xFFF15FAB"):
        assert color in theme,"Motion F color token not present: "+color
    brand=(root/"lib/src/core/live_brand.dart").read_text()
    for token in ("'catalog:0'","'#D9C3FF'","'#65D3FA'","'#0D1030'"):
        assert token in brand,"Dynamic fallback brand is not synchronized: "+token
    print("PASS Motion F canonical asset, favicon, maskable PWA, iOS touch, Flutter palette")

if __name__=="__main__":
    main()
