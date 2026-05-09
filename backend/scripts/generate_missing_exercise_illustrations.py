"""
Generate illustrations for the 25 exercise_library rows that have NULL
image_s3_path and were not matched by Vision against the existing S3
ILLUSTRATIONS ALL/ catalog.

Pipeline:
  1. Read backend/scripts/output/missing_exercise_images_no_match.csv
  2. For each row with NULL image_s3_path:
       - Build a 3D-mannequin anatomical-illustration prompt
       - Generate JPEG via Imagen 4 fast (Gemini API)
       - Save locally under output/generated_illustrations_<ts>/
       - Re-validate the rendered image with Gemini Vision (>= 0.7 confidence)
       - On pass: upload to s3://<bucket>/ILLUSTRATIONS ALL/<folder>/<slug>.jpg
                  and UPDATE exercise_library.image_s3_path
       - On fail: append to needs_review CSV and DO NOT touch the row
  3. Refresh the exercise_library_cleaned materialized view at the end.

Idempotent: rows whose image_s3_path is already non-NULL are skipped.

Run:
  backend/.venv/bin/python backend/scripts/generate_missing_exercise_illustrations.py
"""
from __future__ import annotations

import asyncio
import csv
import json
import os
import re
import sys
import time
from pathlib import Path
from typing import Optional

import asyncpg
import boto3
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[2]
BACKEND = ROOT / "backend"
load_dotenv(BACKEND / ".env")
sys.path.insert(0, str(BACKEND))

from google import genai  # noqa: E402
from google.genai import types  # noqa: E402

# ---------- Config ----------
BUCKET = os.getenv("S3_BUCKET_NAME", "ai-fitness-coach")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
IMAGEN_MODEL = os.getenv("IMAGEN_MODEL", "imagen-4.0-fast-generate-001")
VISION_MODEL = os.getenv("GEMINI_VISION_MODEL", "gemini-2.5-flash")
COST_PER_IMAGE_USD = 0.02  # Imagen 4 fast pricing (approx). Bound: $5 cap.
MAX_SPEND_USD = 5.0
MIN_VISION_CONFIDENCE = 0.7
RPM_LIMIT = 5  # throttle generations per minute
SECONDS_PER_GEN = 60.0 / RPM_LIMIT

# body_part (DB) -> S3 folder (under ILLUSTRATIONS ALL/)
# Picked the most common folder for each body_part using the mix already in the table.
BODY_PART_TO_FOLDER = {
    "back": "Back",
    "cardio": "Calisthenics-Cardio-Plyo-Functional",
    "chest": "Chest",
    "full body": "Calisthenics-Cardio-Plyo-Functional",
    "lower arms": "Forearms",
    "lower legs": "Legs",
    "neck": "Stretching - Mobility",
    "shoulders": "Shoulders",
    "upper arms": "Triceps",  # most no-match rows are tricep band/ring exercises
    "upper legs": "Legs",
    "waist": "Abdominals",
}

INPUT_CSV = BACKEND / "scripts" / "output" / "missing_exercise_images_no_match.csv"
TS = time.strftime("%Y%m%d_%H%M%S")
OUT_DIR = BACKEND / "scripts" / "output"
RUN_DIR = OUT_DIR / f"generated_illustrations_{TS}"
RUN_DIR.mkdir(parents=True, exist_ok=True)
RESULT_CSV = OUT_DIR / f"generated_exercise_illustrations_{TS}.csv"
REVIEW_CSV = OUT_DIR / f"generated_exercise_illustrations_needs_review_{TS}.csv"

if not GEMINI_API_KEY:
    print("ERROR: GEMINI_API_KEY not set; aborting (no fake matches).")
    sys.exit(2)

s3 = boto3.client(
    "s3",
    aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
    aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY"),
    region_name=os.getenv("AWS_DEFAULT_REGION", "us-east-1"),
)
client = genai.Client(api_key=GEMINI_API_KEY)


def slugify(name: str) -> str:
    s = re.sub(r"[^\w\s-]", "", name).strip().replace(" ", "_")
    s = re.sub(r"_+", "_", s)
    return s


def normalize_name_for_prompt(name: str) -> str:
    # Strip trailing _Female / _female so the prompt reads naturally.
    return re.sub(r"_+female$", "", name, flags=re.IGNORECASE).replace("_", " ").strip()


def is_female(name: str) -> bool:
    return bool(re.search(r"_female$", name, flags=re.IGNORECASE))


def detect_equipment(name: str) -> str:
    n = name.lower()
    if "landmine" in n: return "an Olympic barbell anchored at one end into a landmine attachment, the free end held in the hands"
    if "barbell" in n: return "an Olympic barbell with weight plates"
    if "dumbbell" in n: return "a pair of dumbbells"
    if "band " in n or n.startswith("band"): return "a long elastic resistance band"
    if "ring" in n: return "gymnastic rings hanging from above on long straps"
    if "jump rope" in n: return "a jump rope"
    if "airbike" in n or "air bike" in n: return "an Assault AirBike fan exercise bike"
    if "back extension machine" in n: return "a 45-degree back extension / hyperextension machine with hip pads"
    if "decline" in n: return "a decline bench tilted head-down"
    return ""


def motion_hint(name: str) -> str:
    """Per-exercise posture / plane-of-motion override clause to push Imagen onto the
    correct movement when the exercise name alone is ambiguous."""
    n = name.lower()
    if "skullcrusher" in n:
        return ("Figure is LYING SUPINE on a flat bench, arms extended straight up, "
                "elbows fixed, lowering the resistance behind the head toward the forehead "
                "(triceps extension overhead).")
    if "lying press down" in n:
        return ("Figure is LYING SUPINE on the floor, arms extended overhead, pressing "
                "a resistance band downward toward the hips with straight arms.")
    if "wrist curl" in n:
        return ("Figure is SEATED with forearm resting on the thigh, palm facing up, "
                "curling the wrist only (forearm flexor focus). Hand and wrist visible.")
    if "triceps pushdown" in n:
        return ("Figure stands upright, upper arm pinned to the side, elbow bent 90 degrees "
                "at top, then EXTENDING the elbow downward to push the band toward the hip "
                "(triceps isolation, NOT a curl, NOT a row).")
    if "incline palms back press" in n:
        return ("Figure stands at a slight forward incline, both arms extended behind the "
                "body with palms facing backward, pressing a band backward (rear delt / "
                "tricep extension behind the body).")
    if "hooklying bench press" in n:
        return ("Figure lies SUPINE on a flat bench in hooklying position (knees bent, feet "
                "flat on the bench), pressing a barbell up from the chest with elbows tucked "
                "close to the ribs.")
    if "larsen bench press" in n:
        return ("Figure lies SUPINE on a flat bench pressing a barbell, with both legs "
                "extended STRAIGHT OUT in the air (feet OFF the floor — Larsen press style).")
    if "landmine chest press" in n:
        return ("Figure stands upright facing forward, both hands gripping the FREE END of a "
                "landmine barbell at the chest, pressing the barbell forward and slightly "
                "up away from the body.")
    if "barbell pullover to triceps extension" in n:
        return ("Figure lies SUPINE on a flat bench, holding a barbell overhead with straight "
                "arms in the pullover position, then bending the elbows to lower the bar "
                "behind the head (combined pullover + triceps extension).")
    if "back slaps" in n or "wrap arround stretch" in n:
        return ("Figure stands upright and swings both arms across the chest in a "
                "self-hugging motion (dynamic chest / upper back stretch).")
    if "abs snails" in n:
        return ("Figure lies SUPINE on the floor with knees pulled toward the chest in a "
                "tight tuck (abdominal crunch with hip flexion).")
    if "lateral raise" in n and "seated" in n:
        return ("Figure is SEATED on a bench, dumbbells in each hand at the sides, raising "
                "both arms outward to shoulder height (lateral deltoid raise).")
    if "jump rope row" in n:
        return ("Figure stands upright with a jump rope, mid-jump with feet just off the "
                "ground and rope rotating overhead (cardio jump-rope motion).")
    if "decline levitating sit up" in n:
        return ("Figure performs a sit-up on a decline bench, torso curling up off the "
                "decline pad toward the knees.")
    if "airbike" in n or "air bike" in n:
        return ("Figure is SEATED on an Assault AirBike, gripping the moving handlebars and "
                "pedaling, dynamic motion.")
    if "back extension machine" in n:
        return ("Figure secured on a 45-degree back extension machine, torso hinging upward "
                "from the hips back toward neutral spine.")
    if "ring dip" in n:
        return ("Figure suspended above the ground gripping two gymnastic rings, arms bent "
                "at the bottom of a dip with elbows close to the body, knees tucked.")
    if "romanian deadlift" in n:
        return ("Figure stands with a barbell at hip height, hinging at the hips with a flat "
                "back, knees only slightly bent, lowering the bar along the thighs to about "
                "knee height (hip-hinge pattern).")
    if "plank to alternating row" in n:
        return ("Figure in a high plank position holding two dumbbells, rowing one dumbbell "
                "up to the ribs while the other hand stays on the floor.")
    return ""


def build_prompt(name: str, body_part: str) -> str:
    pretty = normalize_name_for_prompt(name)
    figure = "muscular adult female" if is_female(name) else "muscular adult male"
    target = body_part if body_part else "primary working muscles"
    equipment = detect_equipment(name)
    eq_clause = f" The figure is using {equipment}." if equipment else ""
    motion = motion_hint(name)
    motion_clause = f" SPECIFIC POSTURE: {motion}" if motion else ""
    return (
        f"Photorealistic 3D anatomy-render style illustration of a {figure} figure shown "
        f"mid-repetition performing the exercise '{pretty}'. "
        f"The figure has a grey-white anatomical surface (visible muscle definition like an "
        f"ecorche mannequin) wearing only plain black athletic shorts and grey training shoes, "
        f"no shirt. The {target} muscles being worked are colored bright red while all other "
        f"muscles remain grey. The figure is captured in the working position of the exercise "
        f"(NOT just standing still — show the actual movement, joint angle, and posture).{eq_clause} "
        f"Centered on a completely plain solid white background, soft realistic shadow under feet. "
        f"Front or rear view, even diffuse lighting, ExRx.net / Muscle & Motion fitness "
        f"reference illustration style. No text, no watermark, no logos, no branding, no faces "
        f"shown in detail.{motion_clause}"
    )


def generate_image(prompt: str) -> Optional[bytes]:
    try:
        resp = client.models.generate_images(
            model=IMAGEN_MODEL,
            prompt=prompt,
            config={"number_of_images": 1, "aspect_ratio": "1:1"},
        )
        if not resp.generated_images:
            return None
        return resp.generated_images[0].image.image_bytes
    except Exception as e:
        print(f"   imagen err: {type(e).__name__}: {str(e)[:200]}")
        return None


def vision_check(name: str, img: bytes) -> tuple[float, str]:
    pretty = normalize_name_for_prompt(name)
    prompt = (
        f"You are validating an AI-generated anatomical exercise reference illustration. "
        f"The illustration is meant to depict: \"{pretty}\".\n\n"
        "Score how plausibly the image could pass as a reference illustration for that "
        "exercise. Be LENIENT: this is a muscle-anatomy reference render, not a photo. "
        "An ecorche / muscle-map figure on a plain background COUNTS as a valid reference "
        "as long as: (a) the highlighted muscles are roughly the right region for the named "
        "exercise, AND (b) nothing in the image actively contradicts the named exercise "
        "(e.g. wrong equipment clearly shown, opposite plane of motion clearly shown).\n\n"
        "Reply strict JSON: {\"confidence\": <0.0-1.0>, \"reason\": \"<short>\"}.\n"
        ">= 0.7  => acceptable reference (highlighted muscles match, no major contradiction).\n"
        "0.4-0.7 => weak/ambiguous (could be reused but flag).\n"
        "< 0.4   => clear contradiction (wrong muscle group highlighted, or wrong equipment "
        "explicitly depicted)."
    )
    try:
        resp = client.models.generate_content(
            model=VISION_MODEL,
            contents=[types.Part.from_bytes(data=img, mime_type="image/jpeg"), prompt],
            config=types.GenerateContentConfig(
                temperature=0.1,
                max_output_tokens=512,
                response_mime_type="application/json",
                thinking_config=types.ThinkingConfig(thinking_budget=0),
            ),
        )
        data = json.loads(resp.text or "{}")
        return float(data.get("confidence", 0.0)), str(data.get("reason", ""))
    except Exception as e:
        return 0.0, f"vision_error: {e}"


def s3_key_for(body_part: str, name: str) -> str:
    folder = BODY_PART_TO_FOLDER.get(body_part, "Calisthenics-Cardio-Plyo-Functional")
    return f"ILLUSTRATIONS ALL/{folder}/{slugify(name)}.jpg"


def upload_to_s3(key: str, body: bytes) -> str:
    s3.put_object(Bucket=BUCKET, Key=key, Body=body, ContentType="image/jpeg")
    return f"s3://{BUCKET}/{key}"


async def main() -> int:
    if not INPUT_CSV.exists():
        print(f"ERROR: input CSV not found: {INPUT_CSV}")
        return 2

    with open(INPUT_CSV, newline="") as f:
        rows = list(csv.DictReader(f))
    print(f"Loaded {len(rows)} candidates from {INPUT_CSV.name}")

    raw = os.environ.get("DATABASE_URL_DIRECT") or os.environ["DATABASE_URL"]
    pg_url = raw.replace("postgresql+asyncpg://", "postgresql://")
    conn = await asyncpg.connect(pg_url)

    results: list[dict] = []
    review: list[dict] = []
    spent = 0.0
    populated = 0
    skipped = 0
    flagged = 0

    for i, row in enumerate(rows, 1):
        ex_id = row["id"]
        name = row["exercise_name"]
        body_part = (row.get("body_part") or "").strip()

        # Idempotency: skip if image_s3_path already populated.
        existing = await conn.fetchval(
            "SELECT image_s3_path FROM exercise_library WHERE id = $1", ex_id
        )
        if existing:
            print(f"[{i}/{len(rows)}] SKIP {name} -- already has {existing}")
            skipped += 1
            continue

        if spent + COST_PER_IMAGE_USD > MAX_SPEND_USD:
            print(f"ABORT: spend cap ${MAX_SPEND_USD} would be exceeded; stopping at "
                  f"{i - 1}/{len(rows)} (spent ~${spent:.2f}).")
            break

        prompt = build_prompt(name, body_part)
        print(f"[{i}/{len(rows)}] {name} ({body_part}) -- generating...")
        t0 = time.time()
        img = generate_image(prompt)
        spent += COST_PER_IMAGE_USD
        if img is None:
            print("   FAIL: empty image response")
            review.append({
                "id": ex_id, "name": name, "body_part": body_part,
                "generation_status": "failed", "confidence": 0.0,
                "reason": "imagen_returned_no_image", "prompt": prompt,
                "generated_path": "",
            })
            results.append({
                "exercise_id": ex_id, "name": name, "generated_path": "",
                "generation_status": "failed", "prompt": prompt,
            })
            # throttle even on failure to respect RPM
            elapsed = time.time() - t0
            if elapsed < SECONDS_PER_GEN:
                time.sleep(SECONDS_PER_GEN - elapsed)
            continue

        local_path = RUN_DIR / f"{slugify(name)}.jpg"
        local_path.write_bytes(img)

        conf, reason = vision_check(name, img)
        print(f"   vision conf={conf:.2f} ({reason[:80]})")

        if conf < MIN_VISION_CONFIDENCE:
            review.append({
                "id": ex_id, "name": name, "body_part": body_part,
                "generation_status": "flagged_low_confidence", "confidence": conf,
                "reason": reason, "prompt": prompt,
                "generated_path": str(local_path),
            })
            results.append({
                "exercise_id": ex_id, "name": name, "generated_path": str(local_path),
                "generation_status": "needs_review", "prompt": prompt,
            })
            flagged += 1
        else:
            key = s3_key_for(body_part, name)
            s3_path = upload_to_s3(key, img)
            await conn.execute(
                "UPDATE exercise_library SET image_s3_path = $1 WHERE id = $2",
                s3_path, ex_id,
            )
            print(f"   UPLOADED -> {s3_path}")
            populated += 1
            results.append({
                "exercise_id": ex_id, "name": name, "generated_path": s3_path,
                "generation_status": "succeeded", "prompt": prompt,
            })

        elapsed = time.time() - t0
        if elapsed < SECONDS_PER_GEN:
            time.sleep(SECONDS_PER_GEN - elapsed)

    # Refresh MV
    refreshed = False
    try:
        await conn.execute("SELECT refresh_exercise_library_cleaned()")
        refreshed = True
        print("MV refreshed via refresh_exercise_library_cleaned()")
    except Exception as e:
        print(f"refresh fn err: {e}; trying CONCURRENTLY refresh")
        try:
            await conn.execute(
                "REFRESH MATERIALIZED VIEW CONCURRENTLY exercise_library_cleaned"
            )
            refreshed = True
            print("MV refreshed via CONCURRENTLY")
        except Exception as e2:
            print(f"MV refresh failed: {e2}")

    null_count = await conn.fetchval(
        "SELECT count(*) FROM exercise_library "
        "WHERE image_s3_path IS NULL OR image_s3_path = ''"
    )
    await conn.close()

    # Write CSVs
    with open(RESULT_CSV, "w", newline="") as f:
        w = csv.DictWriter(
            f, fieldnames=["exercise_id", "name", "generated_path",
                           "generation_status", "prompt"]
        )
        w.writeheader()
        for r in results:
            w.writerow(r)

    with open(REVIEW_CSV, "w", newline="") as f:
        w = csv.DictWriter(
            f, fieldnames=["id", "name", "body_part", "generation_status",
                           "confidence", "reason", "prompt", "generated_path"]
        )
        w.writeheader()
        for r in review:
            w.writerow(r)

    print("\n==================== SUMMARY ====================")
    print(f"candidates:     {len(rows)}")
    print(f"populated:      {populated}")
    print(f"needs_review:   {flagged}")
    print(f"skipped:        {skipped}")
    print(f"approx spend:   ${spent:.2f}")
    print(f"MV refreshed:   {refreshed}")
    print(f"NULL/empty image_s3_path count after run: {null_count}")
    print(f"results CSV:    {RESULT_CSV}")
    print(f"review  CSV:    {REVIEW_CSV}")
    return 0


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
