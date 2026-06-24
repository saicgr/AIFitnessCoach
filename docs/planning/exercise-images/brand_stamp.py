#!/usr/bin/env python3
"""Composite the real Zealova logo + wordmark onto a generated render (crisp, deterministic)."""
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
LOGO_SRC = os.path.join(ROOT, "frontend", "public", "zealova-logo.png")
BRAND = (242, 106, 27, 255)   # Zealova orange
WORD  = "Zealova"

FONTS = [
    "/System/Library/Fonts/Avenir Next.ttc",
    "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
    "/System/Library/Fonts/HelveticaNeue.ttc",
    "/Library/Fonts/Arial Bold.ttf",
]

def _load_font(sz):
    for f in FONTS:
        if os.path.exists(f):
            try: return ImageFont.truetype(f, sz)
            except Exception: pass
    return ImageFont.load_default()

def _logo_transparent(h):
    """Key out the light-gray logo background by colorfulness; keep the orange mark."""
    logo = Image.open(LOGO_SRC).convert("RGBA")
    px = logo.load()
    w, ht = logo.size
    for y in range(ht):
        for x in range(w):
            r, g, b, a = px[x, y]
            colorful = max(r, g, b) - min(r, g, b)
            alpha = max(0, min(255, (colorful - 18) * 10))
            px[x, y] = (r, g, b, alpha)
    ratio = h / logo.height
    return logo.resize((int(logo.width * ratio), h), Image.LANCZOS)

_LOGO_CACHE = {}
def logo(h):
    if h not in _LOGO_CACHE:
        _LOGO_CACHE[h] = _logo_transparent(h)
    return _LOGO_CACHE[h]

def stamp(path, out=None, opacity=0.92):
    out = out or path
    img = Image.open(path).convert("RGBA")
    W, H = img.size
    icon_h = max(26, int(H * 0.036))
    ic = logo(icon_h)
    font = _load_font(int(icon_h * 0.82))
    gap = int(icon_h * 0.22)

    # measure wordmark
    tmp = ImageDraw.Draw(Image.new("RGBA", (10, 10)))
    bb = tmp.textbbox((0, 0), WORD, font=font)
    tw, th = bb[2] - bb[0], bb[3] - bb[1]

    strip_w = ic.width + gap + tw
    strip_h = max(ic.height, th)
    strip = Image.new("RGBA", (strip_w, strip_h), (0, 0, 0, 0))
    strip.alpha_composite(ic, (0, (strip_h - ic.height) // 2))
    d = ImageDraw.Draw(strip)
    d.text((ic.width + gap, (strip_h - th) // 2 - bb[1]), WORD, font=font, fill=BRAND)

    # White rounded backing chip so the logo stays readable over any background (dark equipment, shadows).
    pad_x = int(icon_h * 0.50); pad_y = int(icon_h * 0.34)
    chip_w, chip_h = strip_w + 2 * pad_x, strip_h + 2 * pad_y
    chip = Image.new("RGBA", (chip_w, chip_h), (0, 0, 0, 0))
    cd = ImageDraw.Draw(chip)
    cd.rounded_rectangle([0, 0, chip_w - 1, chip_h - 1], radius=int(chip_h * 0.34),
                         fill=(255, 255, 255, int(235 * opacity)))
    chip.alpha_composite(strip, (pad_x, pad_y))

    margin = int(H * 0.022)
    pos = (W - chip_w - margin, H - chip_h - margin)   # bottom-right
    img.alpha_composite(chip, pos)
    img.convert("RGB").save(out, "PNG")
    return out

if __name__ == "__main__":
    import sys
    for p in sys.argv[1:]:
        print("stamped", stamp(p))
