#!/usr/bin/env python3
"""Generate Fitted Motion F web/PWA and optional native icons from one asset.

Source stays in Flutter assets/branding. This script is deliberately deterministic
and contains no network requests; CI installs a pinned Pillow before calling it.
Execute after `flutter create`, which regenerates Flutter's default icon files.
"""
from __future__ import annotations
import argparse
import json
import re
from pathlib import Path
from PIL import Image, ImageOps, ImageDraw

NAVY = "#1A2D38"
APP_NAME = "Fitted"



def mint_f_icon() -> Image.Image:
    """Build the new Fitted Slate Mint launcher artwork deterministically."""
    icon = Image.new("RGB", (512, 512), NAVY)
    draw = ImageDraw.Draw(icon)
    scale = 2.56

    def curve(a, b, c, d):
        points = []
        for step in range(37):
            t = step / 36
            u = 1 - t
            x = u**3*a[0] + 3*u*u*t*b[0] + 3*u*t*t*c[0] + t**3*d[0]
            y = u**3*a[1] + 3*u*u*t*b[1] + 3*u*t*t*c[1] + t**3*d[1]
            points.append((round(x*scale), round(y*scale)))
        return points

    top = []
    top += curve((43,53),(60,23),(85,30),(120,30))
    top += curve((120,30),(148,30),(173,31),(179,29))
    top += curve((179,29),(175,52),(151,66),(124,66))
    top += curve((124,66),(100,66),(77,60),(63,86))
    top += curve((63,86),(47,95),(36,107),(26,121))
    top += curve((26,121),(28,91),(32,71),(43,53))
    draw.polygon(top, fill="#89EBD2")
    lower = []
    lower += curve((28,113),(51,88),(61,80),(94,80))
    lower += curve((94,80),(118,78),(128,76),(137,72))
    lower += curve((137,72),(128,93),(114,108),(94,110))
    lower += curve((94,110),(75,109),(69,113),(61,129))
    lower += curve((61,129),(45,165),(21,174),(14,158))
    lower += curve((14,158),(9,142),(13,130),(28,113))
    draw.polygon(lower, fill="#69DEC8")
    return icon


def resized(image: Image.Image, size: int) -> Image.Image:
    return image.resize((size, size), Image.Resampling.LANCZOS).convert("RGB")


def save_png(image: Image.Image, target: Path, size: int, maskable: bool = False):
    target.parent.mkdir(parents=True, exist_ok=True)
    if maskable:
        # Keep the whole F in the safe zone when a launcher applies its own mask.
        canvas = Image.new("RGB", (size, size), NAVY)
        mark = resized(image, round(size * .8))
        offset = (size - mark.width) // 2
        canvas.paste(mark, (offset, offset))
        canvas.save(target, format="PNG", optimize=True)
    else:
        resized(image, size).save(target, format="PNG", optimize=True)


def web_assets(image: Image.Image, web: Path, source: Path):
    web.mkdir(parents=True, exist_ok=True)
    save_png(image, web / "favicon.png", 48)
    save_png(image, web / "apple-touch-icon.png", 180)
    for size in (192, 512):
        save_png(image, web / "icons" / f"Icon-{size}.png", size)
        save_png(image, web / "icons" / f"Icon-maskable-{size}.png", size, True)
    image.save(web / "icon.webp", format="WEBP", quality=93)
    manifest_path = web / "manifest.json"
    manifest = json.loads(manifest_path.read_text()) if manifest_path.exists() else {}
    manifest.update({
        "name": APP_NAME,
        "short_name": APP_NAME,
        "description": "Personas en movimiento. Conexiones con intención.",
        "background_color": NAVY,
        "theme_color": NAVY,
        "display": "standalone",
        "icons": [
            {"src": f"icons/Icon-{size}.png?v=slate-mint-v1",
             "sizes": f"{size}x{size}", "type": "image/png"}
            for size in (192, 512)
        ] + [
            {"src": f"icons/Icon-maskable-{size}.png?v=slate-mint-v1",
             "sizes": f"{size}x{size}", "type": "image/png",
             "purpose": "maskable"}
            for size in (192, 512)
        ],
    })
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
    html_path = web / "index.html"
    html = html_path.read_text() if html_path.exists() else """<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>Fitted</title></head><body></body></html>
"""
    html = re.sub(r'<link[^>]*rel="icon"[^>]*>', "", html)
    html = re.sub(r'<link[^>]*rel="apple-touch-icon"[^>]*>', "", html)
    html = re.sub(r'<meta[^>]*name="theme-color"[^>]*>', "", html)
    html = html.replace('href="manifest.json"','href="manifest.json?v=slate-mint-v1"')
    html = re.sub(r"<title>.*?</title>", "<title>Fitted</title>", html,
                  count=1, flags=re.DOTALL)
    addition = ('<meta name="theme-color" content="' + NAVY + '">\n'
                '<link rel="icon" type="image/png" sizes="48x48" href="favicon.png?v=slate-mint-v1">\n'
                '<link rel="apple-touch-icon" sizes="180x180" href="apple-touch-icon.png?v=slate-mint-v1">\n')
    assert "</head>" in html, "Flutter index must contain a head"
    html_path.write_text(html.replace("</head>", addition + "</head>", 1))
    assert (web / "icons" / "Icon-512.png").stat().st_size > 5000


def android_assets(image: Image.Image, root: Path):
    targets = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    for bucket, size in targets.items():
        path = root / "app" / "src" / "main" / "res" / f"mipmap-{bucket}"
        if path.exists():
            save_png(image, path / "ic_launcher.png", size)
    # Adaptive icon foreground with a safe zone, if the app includes its res dir.
    values = root / "app" / "src" / "main" / "res" / "values"
    if values.exists():
        (values / "fitted_motion_colors.xml").write_text(
            '<?xml version="1.0" encoding="utf-8"?>\n'
            '<resources><color name="fitted_icon_background">#0D1030</color></resources>\n')


def ios_assets(image: Image.Image, root: Path):
    folder = root / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    if not folder.exists():
        return
    contents = folder / "Contents.json"
    if not contents.exists():
        return
    data = json.loads(contents.read_text())
    for item in data.get("images", []):
        filename = item.get("filename")
        if not filename:
            continue
        point = item.get("size", "0x0").split("x")[0]
        scale = float(item.get("scale", "1x").replace("x", ""))
        size = int(round(float(point) * scale))
        if size > 0:
            save_png(image, folder / filename, size)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--project", default="apps/flutter_client")
    p.add_argument("--skip-native", action="store_true")
    args = p.parse_args()
    root = Path(args.project)
    source = root / "assets/branding/fitted_motion_f.webp"
    assert source.is_file(), "A real Motion F icon must be committed"
    image = mint_f_icon()
    web_assets(image, root / "web", source)
    if not args.skip_native:
        android_assets(image, root / "android")
        ios_assets(image, root / "ios")
    print("FITTED Slate Mint: favicon, PWA, Apple touch and native icons generated")


if __name__ == "__main__":
    main()
