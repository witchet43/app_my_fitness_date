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
    assert icon.is_file() and alias.is_file(), "Bundled fallback files missing"
    mark=(root/"assets/branding/fitted_mint_f.svg").read_text()
    assert "<svg" in mark and "#DDE7EC" in mark and "#8196A2" in mark, "Silver F source missing"
    with Image.open(icon) as im:
        assert im.format=="WEBP" and min(im.size)>=160 and im.width==im.height, im.size
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
    assert m["name"]=="Fitted" and m["theme_color"]=="#1A2D38"
    assert any("maskable" in entry.get("purpose","") for entry in m["icons"])
    html=(web/"index.html").read_text()
    assert '<title>Fitted</title>' in html
    assert 'apple-touch-icon.png' in html
    assert 'favicon.png?v=slate-silver-v2' in html
    theme=(root/"lib/src/theme/fitness_date_theme.dart").read_text()
    for color in ("0xFF1A2D38","0xFF8EF0D5","0xFF68D4C7"):
        assert color in theme,"Fallback brand token not present: "+color
    for token in ("static void useBrand", "static Color get pulsePink", "static Color get aqua"):
        assert token in theme,"Dynamic palette token not present: "+token
    brand=(root/"lib/src/core/live_brand.dart").read_text()
    for token in ("'catalog:0'","'#8EF0D5'","'#68D4C7'","'#1A2D38'"):
        assert token in brand,"Dynamic fallback brand is not synchronized: "+token
    print("PASS translucent silver Motion F icon, maskable PWA and Flutter color tokens")

if __name__=="__main__":
    main()
