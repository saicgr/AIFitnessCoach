"""Generate synthetic resilience-test images (the G-series edge cases).

From a few base corpus images, PIL-generates:
  - corrupt   : truncated/garbage bytes      → expect clean 400, not 500
  - tiny      : 64px image                   → expect upscale + process
  - huge      : >10MB image                  → expect IMAGE_TOO_LARGE 400
  - grayscale : desaturated food photo        → expect normal `done`
  - blur      : heavy gaussian blur           → expect `done` low-confidence
                                                or clean NO_FOOD_DETECTED

Output: scripts/benchmarks/images_corpus/synthetic/<case>_NN.jpg
Deterministic, no network. Idempotent.
"""
import io
import sys
from pathlib import Path

from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parent
CORPUS = ROOT / "images_corpus"
OUT = CORPUS / "synthetic"


def _base_images(n: int = 3):
    """Pick n base food images from the single/ corpus."""
    singles = sorted((CORPUS / "single").glob("*.jpg"))
    return singles[:n]


def main() -> int:
    bases = _base_images(3)
    if not bases:
        print("no base images in images_corpus/single/ — run build_corpus.py first")
        return 1
    OUT.mkdir(parents=True, exist_ok=True)

    made = 0
    for i, base in enumerate(bases):
        img = Image.open(base).convert("RGB")

        # corrupt — valid JPEG header then garbage
        good = io.BytesIO()
        img.save(good, format="JPEG", quality=80)
        corrupt = good.getvalue()[: len(good.getvalue()) // 2] + b"\xff\xd8GARBAGE" * 50
        (OUT / f"corrupt_{i:02d}.jpg").write_bytes(corrupt)
        made += 1

        # tiny — 64px
        tiny = img.resize((64, 64), Image.LANCZOS)
        tiny.save(OUT / f"tiny_{i:02d}.jpg", format="JPEG", quality=80)
        made += 1

        # huge — pad to >10MB by upscaling + low compression
        huge = img.resize((6000, 6000), Image.LANCZOS)
        hb = io.BytesIO()
        huge.save(hb, format="JPEG", quality=100)
        # if still under 10MB, tile it bigger
        data = hb.getvalue()
        while len(data) < 11 * 1024 * 1024:
            huge = huge.resize((int(huge.width * 1.3), int(huge.height * 1.3)), Image.LANCZOS)
            hb = io.BytesIO()
            huge.save(hb, format="JPEG", quality=100)
            data = hb.getvalue()
            if huge.width > 20000:
                break
        (OUT / f"huge_{i:02d}.jpg").write_bytes(data)
        made += 1

        # grayscale
        gray = img.convert("L").convert("RGB")
        gray.save(OUT / f"grayscale_{i:02d}.jpg", format="JPEG", quality=80)
        made += 1

        # blur
        blurred = img.filter(ImageFilter.GaussianBlur(radius=12))
        blurred.save(OUT / f"blur_{i:02d}.jpg", format="JPEG", quality=80)
        made += 1

    print(f"synthetic edge cases: {made} images in {OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
