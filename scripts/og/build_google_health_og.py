"""Build /vs/google-health OG image (1200x630)."""
from PIL import Image, ImageDraw, ImageFont
from pathlib import Path

W, H = 1200, 630
OUT = Path(__file__).resolve().parents[2] / "frontend/public/screenshots/og-google-health-vs.png"

BG_TOP = (8, 14, 20)
BG_BOT = (15, 28, 26)
EMERALD = (16, 185, 129)
EMERALD_DIM = (5, 95, 70)
WHITE = (245, 247, 246)
MUTED = (148, 163, 165)
DIVIDER = (60, 70, 75)

SF = "/System/Library/Fonts/SFCompact.ttf"
SFB = "/System/Library/Fonts/SFCompactRounded.ttf"
ARIAL_B = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
ARIAL = "/System/Library/Fonts/Supplemental/Arial.ttf"


def font(path_options, size):
    for p in path_options:
        try:
            return ImageFont.truetype(p, size)
        except Exception:
            continue
    return ImageFont.load_default()


def gradient_bg(img):
    px = img.load()
    for y in range(H):
        t = y / H
        r = int(BG_TOP[0] * (1 - t) + BG_BOT[0] * t)
        g = int(BG_TOP[1] * (1 - t) + BG_BOT[1] * t)
        b = int(BG_TOP[2] * (1 - t) + BG_BOT[2] * t)
        for x in range(W):
            px[x, y] = (r, g, b)


def main():
    OUT.parent.mkdir(parents=True, exist_ok=True)
    img = Image.new("RGB", (W, H), BG_TOP)
    gradient_bg(img)
    d = ImageDraw.Draw(img)

    # Soft emerald glow blob top-right
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    for r, a in [(420, 18), (320, 28), (220, 40), (140, 60)]:
        gd.ellipse([W - 200 - r, -r // 2, W - 200 + r, r], fill=(16, 185, 129, a))
    img.paste(glow, (0, 0), glow)

    f_eyebrow = font([SFB, ARIAL_B], 26)
    f_title = font([SFB, ARIAL_B], 92)
    f_vs = font([SFB, ARIAL_B], 80)
    f_sub = font([SF, ARIAL], 32)
    f_bullet = font([SFB, ARIAL_B], 28)
    f_foot = font([SF, ARIAL], 24)
    f_brand = font([SFB, ARIAL_B], 32)

    pad_x = 70

    # Eyebrow
    d.text((pad_x, 70), "HONEST COMPARISON  ·  MAY 2026", fill=EMERALD, font=f_eyebrow)

    # Title block
    d.text((pad_x, 115), "Zealova", fill=WHITE, font=f_title)
    d.text((pad_x, 215), "vs", fill=MUTED, font=f_vs)
    d.text((pad_x + 130, 215), "Google Health", fill=WHITE, font=f_vs)

    # Divider
    d.line([(pad_x, 340), (W - pad_x, 340)], fill=DIVIDER, width=1)

    # Three wedges
    wedges = [
        "40% cheaper annual plan",
        "No wearable required",
        "Full monthly workout plans",
    ]
    y0 = 370
    for i, w in enumerate(wedges):
        cy = y0 + i * 56
        # check mark dot
        d.ellipse([pad_x, cy + 6, pad_x + 22, cy + 28], fill=EMERALD)
        d.line([(pad_x + 6, cy + 17), (pad_x + 10, cy + 22), (pad_x + 17, cy + 12)],
               fill=(8, 14, 20), width=3)
        d.text((pad_x + 42, cy), w, fill=WHITE, font=f_bullet)

    # Footer bar
    d.line([(pad_x, H - 100), (W - pad_x, H - 100)], fill=DIVIDER, width=1)
    d.text((pad_x, H - 80), "zealova.com/vs/google-health", fill=MUTED, font=f_foot)

    # Brand right-aligned footer
    brand = "ZEALOVA"
    bw = d.textlength(brand, font=f_brand)
    d.text((W - pad_x - bw, H - 82), brand, fill=EMERALD, font=f_brand)

    img.save(OUT, "PNG", optimize=True)
    print(f"wrote {OUT} ({OUT.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
