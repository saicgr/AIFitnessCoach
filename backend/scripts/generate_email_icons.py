"""Rasterize the email icon set to hosted PNGs — the Gmail-compatibility fix.

WHY: every Zealova email rendered its icons as inline `<svg>` (hero chip, feature
rows, footer socials). Gmail (web + app) STRIPS inline SVG, so those icons showed
as empty boxes for the majority of recipients. Apple Mail/iOS render inline SVG,
which masked the bug in dev. PNGs served over HTTPS render everywhere, including
Gmail. This script is the asset half of that fix; `email_signature_template._icon`
and `_footer` emit `<img>` tags pointing at what this uploads.

WHAT: renders every key in `ICON_PATHS` in BOTH palette colors (accent + grey) and
each `_SOCIAL` glyph (grey), then uploads to S3 under `static/email-icons/...` with
STABLE keys (no timestamp/uuid) so the URLs in the template never change.

S3 layout (bucket `ai-fitness-coach`, `static/` prefix is public-read):
  static/email-icons/accent/<key>.png   # stroke #F0531E
  static/email-icons/grey/<key>.png      # stroke #8a8a90
  static/email-icons/social/<name>.png   # fill  #8a8a90

Run (uses AWS creds + bucket from backend/.env):
  backend/.venv312/bin/python scripts/generate_email_icons.py
  backend/.venv312/bin/python scripts/generate_email_icons.py --dry-run   # render only, no upload

Idempotent — re-running overwrites the same keys. Run once after adding any new
icon key to `ICON_PATHS`.
"""
from __future__ import annotations

import argparse
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

# Load backend/.env so AWS_* + S3_BUCKET_NAME are present when run standalone.
try:
    from dotenv import load_dotenv
    load_dotenv(os.path.join(os.path.dirname(__file__), "..", ".env"))
except Exception:  # noqa: BLE001 — dotenv is best-effort; CI may inject env directly
    pass

import cairosvg  # noqa: E402

from services.email_signature_template import ICON_PATHS, _SOCIAL, ACCENT, GREY  # noqa: E402

# Render at a high fixed resolution; the <img> tag downsamples to the display
# size (20-28px), so a single 128px master stays crisp on retina + scaled DPRs.
MASTER_PX = 128

PALETTES = {"accent": ACCENT, "grey": GREY}


def _stroke_svg(inner: str, color: str) -> bytes:
    """Lucide monoline glyph — stroked, no fill (matches `_icon`)."""
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" '
        f'viewBox="0 0 24 24" fill="none" stroke="{color}" stroke-width="1.8" '
        f'stroke-linecap="round" stroke-linejoin="round">{inner}</svg>'
    ).encode()


def _fill_svg(inner: str, color: str) -> bytes:
    """Brand glyph — single fill path, no stroke (matches `_SOCIAL`)."""
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" '
        f'viewBox="0 0 24 24" fill="{color}" stroke="none">{inner}</svg>'
    ).encode()


def _png(svg_bytes: bytes) -> bytes:
    return cairosvg.svg2png(
        bytestring=svg_bytes, output_width=MASTER_PX, output_height=MASTER_PX
    )


def _build() -> dict[str, bytes]:
    """Return {s3_key: png_bytes} for the full email icon set."""
    out: dict[str, bytes] = {}
    for folder, color in PALETTES.items():
        for key, inner in ICON_PATHS.items():
            out[f"static/email-icons/{folder}/{key}.png"] = _png(_stroke_svg(inner, color))
    for name, inner in _SOCIAL.items():
        out[f"static/email-icons/social/{name}.png"] = _png(_fill_svg(inner, GREY))
    return out


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate + upload email icon PNGs.")
    parser.add_argument("--dry-run", action="store_true",
                        help="Render PNGs but skip S3 upload (writes to /tmp for inspection).")
    args = parser.parse_args()

    assets = _build()
    total = len(assets)
    print(f"🎨 Rendered {total} PNGs at {MASTER_PX}px "
          f"({len(ICON_PATHS)} icons × {len(PALETTES)} colors + {len(_SOCIAL)} socials)")

    if args.dry_run:
        outdir = "/tmp/email-icons"
        for key, data in assets.items():
            path = os.path.join(outdir, key.replace("static/email-icons/", ""))
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, "wb") as f:
                f.write(data)
        print(f"📝 --dry-run: wrote {total} PNGs under {outdir} (no upload)")
        return 0

    from services.s3_service import get_s3_service
    s3 = get_s3_service()
    if not s3.is_configured():
        print("❌ S3 not configured (missing AWS creds or bucket). Aborting.")
        return 1

    # Direct put_object with STABLE keys (s3_service.upload_bytes injects a
    # timestamp+uuid, which would break the fixed template URLs).
    uploaded = 0
    for key, data in assets.items():
        s3._client.put_object(
            Bucket=s3.bucket, Key=key, Body=data,
            ContentType="image/png", CacheControl="public, max-age=31536000",
        )
        uploaded += 1
    base = f"https://{s3.bucket}.s3.{s3.region}.amazonaws.com"
    print(f"📤 Uploaded {uploaded}/{total} PNGs to {base}/static/email-icons/")
    print(f"   sample: {base}/static/email-icons/accent/mail.png")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
