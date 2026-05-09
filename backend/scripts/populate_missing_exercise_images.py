"""
Populate exercise_library.image_s3_path for rows where it's NULL/empty.

Strategy:
  1. Query NULL-image rows.
  2. For each row, map body_part -> S3 muscle folder(s) under "ILLUSTRATIONS ALL/".
  3. Score candidate filenames by token overlap with the exercise name.
  4. Top candidates are validated by Gemini Vision (confidence >= 0.85 required).
  5. If a confident match exists, UPDATE the row's image_s3_path.
     Append "?v=<epoch>" cache-bust suffix on the URL so CDN edges miss.
  6. If no confident match: append to no-match CSV for manual generation.
  7. Refresh the exercise_library_cleaned materialized view at the end.

Idempotent: rows that already have a non-empty image_s3_path are ignored.

Run:
  cd /Users/saichetangrandhe/AIFitnessCoach
  backend/.venv/bin/python -m backend.scripts.populate_missing_exercise_images
"""
from __future__ import annotations

import asyncio
import csv
import os
import re
import sys
import time
from pathlib import Path
from typing import List, Optional, Tuple

import asyncpg
import boto3
from dotenv import load_dotenv

# Load env
ROOT = Path(__file__).resolve().parents[2]
BACKEND = ROOT / "backend"
load_dotenv(BACKEND / ".env")

# Make backend importable
sys.path.insert(0, str(BACKEND))

from google import genai  # noqa: E402
from google.genai import types  # noqa: E402

BUCKET = os.getenv("S3_BUCKET_NAME", "ai-fitness-coach")
IMAGE_PREFIX = "ILLUSTRATIONS ALL/"
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
GEMINI_MODEL = os.getenv("GEMINI_VISION_MODEL", "gemini-2.5-flash")
CONFIDENCE_THRESHOLD = 0.85
MAX_VISION_CANDIDATES = 3  # only verify the top-N filename matches per exercise

OUTPUT_DIR = BACKEND / "scripts" / "output"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
NO_MATCH_CSV = OUTPUT_DIR / "missing_exercise_images_no_match.csv"

# Map body_part values from exercise_library to S3 folders
BODY_PART_FOLDERS = {
    "back": ["Back"],
    "chest": ["Chest"],
    "shoulders": ["Shoulders"],
    "upper arms": ["Biceps", "Triceps"],
    "lower arms": ["Forearms"],
    "waist": ["Abdominals"],
    "upper legs": ["Legs"],
    "lower legs": ["Legs"],
    "legs": ["Legs"],
    "cardio": ["Calisthenics-Cardio-Plyo-Functional"],
    "neck": ["Stretching - Mobility"],
}

s3_client = boto3.client(
    "s3",
    aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
    aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY"),
    region_name=os.getenv("AWS_DEFAULT_REGION", "us-east-1"),
)

if not GEMINI_API_KEY:
    print("ERROR: GEMINI_API_KEY not set in backend/.env. Aborting (no fake matches).")
    sys.exit(2)

genai_client = genai.Client(api_key=GEMINI_API_KEY)


_NORMALIZE_RX = re.compile(r"[^a-z0-9 ]+")


def normalize(s: str) -> str:
    return _NORMALIZE_RX.sub(" ", (s or "").lower()).strip()


def tokens(s: str) -> List[str]:
    return [t for t in normalize(s).split() if len(t) >= 2]


def list_folder_keys(folder: str) -> List[str]:
    keys: List[str] = []
    paginator = s3_client.get_paginator("list_objects_v2")
    for page in paginator.paginate(Bucket=BUCKET, Prefix=f"{IMAGE_PREFIX}{folder}/"):
        for obj in page.get("Contents", []) or []:
            k = obj["Key"]
            if k.lower().endswith((".jpg", ".jpeg", ".png", ".gif", ".webp")):
                keys.append(k)
    return keys


def score_filename(exercise_name: str, key: str) -> int:
    fname = key.split("/")[-1].rsplit(".", 1)[0]
    ex_tokens = set(tokens(exercise_name))
    fn_tokens = set(tokens(fname))
    if not ex_tokens:
        return 0
    overlap = len(ex_tokens & fn_tokens)
    extra = len(fn_tokens - ex_tokens)
    missing = len(ex_tokens - fn_tokens)
    score = overlap * 10 - missing * 4 - extra * 1
    # gender suffix preference: if exercise has _female, prefer female filenames
    ex_lower = exercise_name.lower()
    fn_lower = fname.lower()
    if "_female" in ex_lower and "female" in fn_lower:
        score += 5
    if "_female" not in ex_lower and "female" in fn_lower:
        score -= 5
    return score


def fetch_image_bytes(key: str) -> Optional[bytes]:
    try:
        obj = s3_client.get_object(Bucket=BUCKET, Key=key)
        return obj["Body"].read()
    except Exception as e:
        print(f"   s3 fetch err {key}: {e}")
        return None


def vision_verify(exercise_name: str, image_bytes: bytes) -> Tuple[float, str]:
    """Ask Gemini whether the image depicts the exercise. Returns (confidence, reasoning)."""
    prompt = (
        f"Does this illustration depict the exercise: \"{exercise_name}\"?\n"
        "Reply with strict JSON only: {\"confidence\": <0.0-1.0>, \"reason\": \"<one short sentence>\"}.\n"
        "Confidence reflects whether body position, equipment, and movement match the exercise name.\n"
        "Be strict: a 'lat pulldown' image of someone deadlifting must score < 0.3."
    )
    try:
        resp = genai_client.models.generate_content(
            model=GEMINI_MODEL,
            contents=[
                types.Part.from_bytes(data=image_bytes, mime_type="image/jpeg"),
                prompt,
            ],
            config=types.GenerateContentConfig(
                temperature=0.1,
                max_output_tokens=512,
                response_mime_type="application/json",
                thinking_config=types.ThinkingConfig(thinking_budget=0),
            ),
        )
        text = (resp.text or "").strip()
        import json
        data = json.loads(text)
        return float(data.get("confidence", 0.0)), str(data.get("reason", ""))
    except Exception as e:
        print(f"   vision err: {e}")
        return 0.0, f"vision_error: {e}"


async def main() -> int:
    raw = os.environ.get("DATABASE_URL_DIRECT") or os.environ["DATABASE_URL"]
    pg_url = raw.replace("postgresql+asyncpg://", "postgresql://")
    conn = await asyncpg.connect(pg_url)

    rows = await conn.fetch(
        "SELECT id, exercise_name, body_part FROM exercise_library "
        "WHERE image_s3_path IS NULL OR image_s3_path = '' "
        "ORDER BY exercise_name"
    )
    print(f"Found {len(rows)} rows with NULL/empty image_s3_path")

    # Cache S3 listings per folder
    folder_cache: dict = {}
    populated = 0
    no_match: List[dict] = []

    for r in rows:
        ex_name = r["exercise_name"]
        body_part = (r["body_part"] or "").lower().strip()
        ex_id = r["id"]
        print(f"\n>>> {ex_name} | bp={body_part} | id={ex_id}")

        folders = BODY_PART_FOLDERS.get(body_part, [])
        if not folders:
            # search every folder as fallback
            folders = list({v for vs in BODY_PART_FOLDERS.values() for v in vs})
            print(f"   unmapped body_part — scanning all folders")

        # collect candidate keys
        candidates: List[str] = []
        for f in folders:
            if f not in folder_cache:
                folder_cache[f] = list_folder_keys(f)
            candidates.extend(folder_cache[f])

        if not candidates:
            no_match.append({"id": ex_id, "exercise_name": ex_name, "body_part": body_part, "reason": "no_candidates"})
            continue

        scored = sorted(
            ((score_filename(ex_name, k), k) for k in candidates),
            key=lambda t: t[0], reverse=True,
        )
        top = [t for t in scored if t[0] > 0][:MAX_VISION_CANDIDATES]
        if not top:
            no_match.append({"id": ex_id, "exercise_name": ex_name, "body_part": body_part, "reason": "no_filename_match"})
            print(f"   no filename overlap")
            continue

        chosen_key = None
        chosen_conf = 0.0
        chosen_reason = ""
        for sc, key in top:
            print(f"   candidate score={sc} key={key}")
            img = fetch_image_bytes(key)
            if not img:
                continue
            conf, reason = vision_verify(ex_name, img)
            print(f"     vision conf={conf:.2f} ({reason})")
            if conf >= CONFIDENCE_THRESHOLD and conf > chosen_conf:
                chosen_key = key
                chosen_conf = conf
                chosen_reason = reason

        if chosen_key:
            # Store the clean s3:// path in DB. Cache-bust is added to the
            # OUTPUT URL by resolve_image_url() (which keys on the path itself)
            # so that updating the row naturally changes the URL and CDN edges
            # miss on next fetch — without breaking S3 presigning.
            new_path = f"s3://{BUCKET}/{chosen_key}"
            await conn.execute(
                "UPDATE exercise_library SET image_s3_path = $1 WHERE id = $2",
                new_path, ex_id,
            )
            populated += 1
            print(f"   ✅ updated -> {new_path} (conf={chosen_conf:.2f})")
        else:
            no_match.append({
                "id": ex_id, "exercise_name": ex_name, "body_part": body_part,
                "reason": f"no_confident_match (best top score {top[0][0]})",
            })
            print(f"   ❌ no confident match")

    # Write CSV (always — empty file is OK)
    with open(NO_MATCH_CSV, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["id", "exercise_name", "body_part", "reason"])
        w.writeheader()
        for nm in no_match:
            w.writerow(nm)

    # Refresh materialized view (project_exercise_library_mv).
    # Prefer the helper SQL function; fall back to direct REFRESH MV if the
    # mv_refresh_queue trigger is broken.
    if populated > 0:
        try:
            await conn.execute("SELECT refresh_exercise_library_cleaned();")
            print("\n🔁 refreshed exercise_library_cleaned MV via helper")
        except Exception as e:
            print(f"\n⚠️  helper refresh failed ({e}); falling back to direct REFRESH MV")
            try:
                await conn.execute(
                    "REFRESH MATERIALIZED VIEW CONCURRENTLY exercise_library_cleaned"
                )
                print("🔁 refreshed exercise_library_cleaned MV (CONCURRENTLY)")
            except Exception as e2:
                print(f"❌ MV refresh failed entirely: {e2}")

    await conn.close()

    print(f"\n=== SUMMARY ===")
    print(f"Total NULL rows: {len(rows)}")
    print(f"Populated:       {populated}")
    print(f"No-match:        {len(no_match)} (see {NO_MATCH_CSV})")
    return 0


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
