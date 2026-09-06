"""Regenerate every VisiMed logo/icon asset from one monogram definition.

The mark: a wide rounded "V" with a point dropped into its cradle, pine green.
Run from the `frontend/` directory:  python tool/gen_logo.py

Requires Pillow only. Mirrors assets/images/logo.svg.
"""
from __future__ import annotations

import json
import os
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
PINE = (47, 93, 80, 255)      # #2F5D50
WHITE = (255, 255, 255, 255)
SS = 4                          # supersampling factor

# Geometry in a 256-unit box (matches logo.svg).
STROKE_W = 29
V = [((76, 74), (128, 162)), ((180, 74), (128, 162))]
DOT = ((128, 200), 16)


def _draw_mark(draw: ImageDraw.ImageDraw, fg, scale: float, ox: float, oy: float):
    def pt(p):
        return (ox + p[0] * scale, oy + p[1] * scale)

    w = STROKE_W * scale
    for a, b in V:
        ax, ay = pt(a)
        bx, by = pt(b)
        draw.line([(ax, ay), (bx, by)], fill=fg, width=round(w))
        for (cx, cy) in ((ax, ay), (bx, by)):  # round caps
            draw.ellipse([cx - w / 2, cy - w / 2, cx + w / 2, cy + w / 2], fill=fg)
    (dcx, dcy), dr = DOT
    dcx, dcy = pt((dcx, dcy))
    dr *= scale
    draw.ellipse([dcx - dr, dcy - dr, dcx + dr, dcy + dr], fill=fg)


def render(size: int, *, fg=PINE, bg=None, mark_frac=0.66, radius_frac=0.0) -> Image.Image:
    """mark_frac: mark height as a fraction of `size`. bg None => transparent."""
    s = size * SS
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if bg is not None:
        if radius_frac > 0:
            d.rounded_rectangle([0, 0, s - 1, s - 1], radius=radius_frac * s, fill=bg)
        else:
            d.rectangle([0, 0, s, s], fill=bg)
    # The mark art spans y≈60..216 (156 units) in the 256 box; scale that to mark_frac.
    art_h = 156.0
    scale = (mark_frac * s) / art_h
    art_cx, art_cy = 128.0, 138.0  # visual centre of the mark
    ox = s / 2 - art_cx * scale
    oy = s / 2 - art_cy * scale
    _draw_mark(d, fg, scale, ox, oy)
    return img.resize((size, size), Image.LANCZOS)


def save(img: Image.Image, rel: str, *, rgb: bool = False):
    path = ROOT / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    if rgb:
        flat = Image.new("RGB", img.size, (255, 255, 255))
        flat.paste(img, mask=img.split()[3])
        flat.save(path)
    else:
        img.save(path)
    print("wrote", rel)


def main():
    # In-app logo — green mark on transparent (UI wraps it in a white tile).
    save(render(1024, fg=PINE, bg=None, mark_frac=0.72), "assets/images/logo.png")

    # Web favicon — green on transparent.
    save(render(64, fg=PINE, bg=None, mark_frac=0.80), "web/favicon.png")

    # Web PWA icons — white mark on a full-bleed pine tile.
    for sz in (192, 512):
        save(render(sz, fg=WHITE, bg=PINE, mark_frac=0.60), f"web/icons/Icon-{sz}.png", rgb=True)
        # maskable: keep the mark inside the ~80% safe zone.
        save(render(sz, fg=WHITE, bg=PINE, mark_frac=0.44),
             f"web/icons/Icon-maskable-{sz}.png", rgb=True)

    # Android legacy launcher icons.
    for name, sz in [("mdpi", 48), ("hdpi", 72), ("xhdpi", 96),
                     ("xxhdpi", 144), ("xxxhdpi", 192)]:
        save(render(sz, fg=WHITE, bg=PINE, mark_frac=0.58, radius_frac=0.18),
             f"android/app/src/main/res/mipmap-{name}/ic_launcher.png", rgb=True)

    # iOS AppIcon set — sizes from Contents.json.
    ios_dir = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    contents = json.loads((ios_dir / "Contents.json").read_text())
    for entry in contents["images"]:
        pt_size = float(entry["size"].split("x")[0])
        scale = int(entry["scale"].rstrip("x"))
        px = round(pt_size * scale)
        fname = entry["filename"]
        save(render(px, fg=WHITE, bg=PINE, mark_frac=0.60),
             f"ios/Runner/Assets.xcassets/AppIcon.appiconset/{fname}", rgb=True)


if __name__ == "__main__":
    os.chdir(ROOT)
    main()
