"""
Regression-guard audit: sample N random exercise_library rows, fetch their
image, ask Gemini Vision whether the depicted exercise matches the row name,
and write a CSV of flagged mismatches.

Designed as a weekly cron. Exits non-zero if mismatch ratio exceeds threshold
so a wrapping CI/cron alert can fire.

Run:
  backend/.venv/bin/python backend/scripts/audit_image_url_correctness.py [N]
"""
from __future__ import annotations

import asyncio
import csv
import os
import sys
import time
from pathlib import Path
from typing import List, Tuple

import asyncpg
import boto3
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[2]
BACKEND = ROOT / "backend"
load_dotenv(BACKEND / ".env")
sys.path.insert(0, str(BACKEND))

from google import genai  # noqa: E402
from google.genai import types  # noqa: E402

BUCKET = os.getenv("S3_BUCKET_NAME", "ai-fitness-coach")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
GEMINI_MODEL = os.getenv("GEMINI_VISION_MODEL", "gemini-2.5-flash")
SAMPLE_SIZE = int(sys.argv[1]) if len(sys.argv) > 1 else 50
MISMATCH_THRESHOLD = 0.85  # confidence below this counts as mismatch

OUT_DIR = BACKEND / "scripts" / "output"
OUT_DIR.mkdir(parents=True, exist_ok=True)
OUT_CSV = OUT_DIR / f"image_audit_{time.strftime('%Y%m%d_%H%M%S')}.csv"

if not GEMINI_API_KEY:
    print("ERROR: GEMINI_API_KEY not set; aborting (no fake matches).")
    sys.exit(2)

s3 = boto3.client(
    "s3",
    aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
    aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY"),
    region_name=os.getenv("AWS_DEFAULT_REGION", "us-east-1"),
)
genai_client = genai.Client(api_key=GEMINI_API_KEY)


def fetch_image(s3_path: str) -> bytes | None:
    if not s3_path or not s3_path.startswith("s3://"):
        return None
    rest = s3_path[5:]
    bucket, _, key = rest.partition("/")
    try:
        return s3.get_object(Bucket=bucket, Key=key)["Body"].read()
    except Exception as e:
        print(f"   s3 fetch err: {e}")
        return None


def vision_check(name: str, img: bytes) -> Tuple[float, str]:
    prompt = (
        f"Does this illustration depict the exercise: \"{name}\"?\n"
        "Reply strict JSON: {\"confidence\": <0.0-1.0>, \"reason\": \"<short>\"}.\n"
        "Be strict: confidence < 0.5 if the depicted exercise differs in equipment, plane of motion, or muscle group."
    )
    try:
        resp = genai_client.models.generate_content(
            model=GEMINI_MODEL,
            contents=[types.Part.from_bytes(data=img, mime_type="image/jpeg"), prompt],
            config=types.GenerateContentConfig(
                temperature=0.1, max_output_tokens=512,
                response_mime_type="application/json",
                thinking_config=types.ThinkingConfig(thinking_budget=0),
            ),
        )
        import json
        data = json.loads(resp.text or "{}")
        return float(data.get("confidence", 0.0)), str(data.get("reason", ""))
    except Exception as e:
        return 0.0, f"vision_error: {e}"


async def main() -> int:
    raw = os.environ.get("DATABASE_URL_DIRECT") or os.environ["DATABASE_URL"]
    pg_url = raw.replace("postgresql+asyncpg://", "postgresql://")
    conn = await asyncpg.connect(pg_url)
    rows = await conn.fetch(
        "SELECT id, exercise_name, image_s3_path FROM exercise_library "
        "WHERE image_s3_path IS NOT NULL AND image_s3_path <> '' "
        "ORDER BY random() LIMIT $1",
        SAMPLE_SIZE,
    )
    await conn.close()
    print(f"Auditing {len(rows)} random rows (threshold={MISMATCH_THRESHOLD})")

    flagged: List[dict] = []
    for r in rows:
        name = r["exercise_name"]
        img = fetch_image(r["image_s3_path"])
        if img is None:
            flagged.append({
                "id": r["id"], "exercise_name": name,
                "image_s3_path": r["image_s3_path"],
                "confidence": 0.0, "reason": "image_fetch_failed",
            })
            continue
        conf, reason = vision_check(name, img)
        status = "OK" if conf >= MISMATCH_THRESHOLD else "FLAG"
        print(f"   [{status}] {name} | conf={conf:.2f} ({reason[:80]})")
        if conf < MISMATCH_THRESHOLD:
            flagged.append({
                "id": r["id"], "exercise_name": name,
                "image_s3_path": r["image_s3_path"],
                "confidence": conf, "reason": reason,
            })

    with open(OUT_CSV, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["id", "exercise_name", "image_s3_path", "confidence", "reason"])
        w.writeheader()
        for row in flagged:
            w.writerow(row)

    ratio = len(flagged) / max(len(rows), 1)
    print(f"\nFlagged {len(flagged)}/{len(rows)} ({ratio:.1%}) -> {OUT_CSV}")
    # Non-zero exit if more than 10% flagged
    return 0 if ratio <= 0.10 else 1


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
