"""Promote the needs_review JPEGs to S3 and link them in exercise_library.

The previous generation pass produced 8 JPEGs that Imagen flagged below the
0.7 Vision-confidence gate (wrong equipment / wrong plane of motion). The
product call is to ship them anyway rather than leave the rows NULL — better a
mediocre illustration than a 404 placeholder. Each promoted row gets a
flag in raw_data so we can revisit and replace later.

Reads the latest needs_review CSV, uploads the local JPEGs to
s3://ai-fitness-coach/ILLUSTRATIONS ALL/<folder>/<slug>.jpg, updates
exercise_library.image_s3_path, and refreshes the materialized view.
"""
from __future__ import annotations

import csv
import glob
import json
import os
import re
import sys
from pathlib import Path
from urllib.parse import urlparse

import boto3
import psycopg2
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[2]
BACKEND = ROOT / "backend"
load_dotenv(BACKEND / ".env")

BUCKET = os.getenv("S3_BUCKET_NAME", "ai-fitness-coach")
S3_PREFIX = "ILLUSTRATIONS ALL"

BODY_PART_TO_FOLDER = {
    "back": "Back",
    "cardio": "Calisthenics-Cardio-Plyo-Functional",
    "chest": "Chest",
    "full body": "Calisthenics-Cardio-Plyo-Functional",
    "lower arms": "Forearms",
    "lower legs": "Legs",
    "neck": "Stretching - Mobility",
    "shoulders": "Shoulders",
    "upper arms": "Triceps",
    "upper legs": "Legs",
    "waist": "Abdominals",
}


def slugify(name: str) -> str:
    s = re.sub(r"[^\w\s-]", "", name).strip().replace(" ", "_")
    return re.sub(r"_+", "_", s)


def latest_review_csv() -> Path:
    out = BACKEND / "scripts" / "output"
    csvs = sorted(out.glob("generated_exercise_illustrations_needs_review_*.csv"))
    if not csvs:
        sys.exit("No needs_review CSV found in scripts/output/")
    return csvs[-1]


def main() -> None:
    csv_path = latest_review_csv()
    print(f"Reading {csv_path.name}")

    s3 = boto3.client(
        "s3",
        aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
        aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY"),
        region_name=os.getenv("AWS_DEFAULT_REGION", "us-east-1"),
    )
    db_url = urlparse(os.environ["DATABASE_URL"])
    conn = psycopg2.connect(
        host=db_url.hostname,
        port=db_url.port,
        user=db_url.username,
        password=db_url.password,
        database=db_url.path.lstrip("/"),
    )
    cur = conn.cursor()

    promoted = 0
    skipped = 0
    with csv_path.open() as f:
        rows = list(csv.DictReader(f))

    print(f"{len(rows)} candidate rows")
    for row in rows:
        ex_id = row["id"]
        name = row["name"]
        body_part = (row.get("body_part") or "").lower().strip()
        local_path = Path(row["generated_path"])

        if not local_path.exists():
            print(f"  SKIP (no local file): {name}")
            skipped += 1
            continue

        folder = BODY_PART_TO_FOLDER.get(body_part, "Misc")
        s3_key = f"{S3_PREFIX}/{folder}/{slugify(name)}.jpg"

        # Idempotency: only act if the row is still NULL/empty.
        cur.execute(
            "SELECT image_s3_path FROM exercise_library WHERE id = %s",
            (ex_id,),
        )
        existing = cur.fetchone()
        if not existing:
            print(f"  SKIP (row not found): {ex_id}")
            skipped += 1
            continue
        if existing[0]:
            print(f"  SKIP (already populated): {name} -> {existing[0]}")
            skipped += 1
            continue

        # Upload (always overwrite — the local JPEG is the source of truth).
        with local_path.open("rb") as fh:
            s3.put_object(
                Bucket=BUCKET,
                Key=s3_key,
                Body=fh.read(),
                ContentType="image/jpeg",
                CacheControl="public, max-age=86400",
            )

        # Stamp a flag in raw_data so we can find these rows later for replacement.
        flag = {
            "image_quality_flag": "needs_review_imagen",
            "vision_confidence": float(row.get("confidence") or 0),
            "reason": row.get("reason"),
            "promoted_at": Path(local_path).stat().st_mtime,
        }
        cur.execute(
            """
            UPDATE exercise_library
            SET image_s3_path = %s,
                raw_data = COALESCE(raw_data, '{}'::jsonb) || %s::jsonb
            WHERE id = %s
            """,
            (s3_key, json.dumps(flag), ex_id),
        )
        promoted += 1
        print(f"  OK   {name}\n       -> s3://{BUCKET}/{s3_key}")

    conn.commit()

    # Refresh MV (use direct REFRESH; the helper function has a known broken trigger).
    print("Refreshing exercise_library_cleaned...")
    cur.execute("REFRESH MATERIALIZED VIEW CONCURRENTLY exercise_library_cleaned")
    conn.commit()

    cur.execute(
        "SELECT count(*) FROM exercise_library WHERE image_s3_path IS NULL OR image_s3_path = ''"
    )
    final_null = cur.fetchone()[0]

    print()
    print("=" * 50)
    print(f"Promoted: {promoted}")
    print(f"Skipped:  {skipped}")
    print(f"Final NULL count in exercise_library: {final_null}")
    print("=" * 50)
    cur.close()
    conn.close()


if __name__ == "__main__":
    main()
