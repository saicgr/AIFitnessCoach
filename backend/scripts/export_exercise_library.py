#!/usr/bin/env python3
"""
Export the full exercise library from Supabase to a JSON asset for Flutter.

Standalone script — avoids importing the full backend (no redis/gemini deps).

Usage:
    cd backend
    python3 scripts/export_exercise_library.py

Reads SUPABASE_URL and SUPABASE_KEY from .env (or environment).
Outputs: mobile/flutter/assets/data/exercise_library.json
"""

import json
import os
from collections import Counter
from pathlib import Path

# Load .env if python-dotenv is available
try:
    from dotenv import load_dotenv
    load_dotenv(Path(__file__).parent.parent / ".env")
except ImportError:
    pass

from supabase import create_client

# Fields to export (only what the offline engine needs)
EXPORT_FIELDS = [
    "id",
    "name",
    "body_part",
    "equipment",
    "target_muscle",
    "secondary_muscles",
    "difficulty_level",
    "category",
    "video_url",
    "image_url",
    "goals",
    "avoid_if",
    "single_dumbbell_friendly",
    "single_kettlebell_friendly",
]


def compact_exercise(row: dict) -> dict:
    """Extract only the fields the Flutter engine needs, stripping nulls."""
    result = {}
    for field in EXPORT_FIELDS:
        value = row.get(field)
        if value is not None and value != "" and value != []:
            result[field] = value
    return result


def fetch_all_paginated(client, table_name: str, select_columns: str, order_by: str = "name"):
    """Fetch all rows from a Supabase table, handling the 1000-row limit."""
    all_rows = []
    page_size = 1000
    offset = 0

    while True:
        query = client.table(table_name).select(select_columns)
        query = query.order(order_by)
        result = query.range(offset, offset + page_size - 1).execute()

        if not result.data:
            break

        all_rows.extend(result.data)

        if len(result.data) < page_size:
            break

        offset += page_size

    return all_rows


def main():
    url = os.environ.get("SUPABASE_URL") or os.environ.get("supabase_url")
    key = os.environ.get("SUPABASE_KEY") or os.environ.get("supabase_key")

    if not url or not key:
        print("ERROR: Set SUPABASE_URL and SUPABASE_KEY environment variables (or in .env)")
        return

    client = create_client(url, key)

    print("Fetching exercises from exercise_library_cleaned...")
    rows = fetch_all_paginated(
        client,
        table_name="exercise_library_cleaned",
        select_columns=", ".join(EXPORT_FIELDS),
        order_by="name",
    )
    print(f"Fetched {len(rows)} exercises from Supabase")

    # Compact: strip null/empty values
    exercises = [compact_exercise(row) for row in rows]

    # Remove duplicates by id
    seen_ids = set()
    unique_exercises = []
    for ex in exercises:
        eid = ex.get("id")
        if eid and eid not in seen_ids:
            seen_ids.add(eid)
            unique_exercises.append(ex)
    exercises = unique_exercises

    # Output path
    output_path = Path(__file__).parent.parent.parent / "mobile" / "flutter" / "assets" / "data" / "exercise_library.json"
    output_path.parent.mkdir(parents=True, exist_ok=True)

    with open(output_path, "w") as f:
        json.dump(exercises, f, separators=(",", ":"))

    file_size = output_path.stat().st_size
    file_size_kb = file_size / 1024
    file_size_mb = file_size / (1024 * 1024)

    # Summary
    print(f"\n{'='*50}")
    print(f"Export Summary")
    print(f"{'='*50}")
    print(f"Total exercises: {len(exercises)}")
    print(f"File size: {file_size_kb:.1f} KB ({file_size_mb:.2f} MB)")
    print(f"Output: {output_path}")

    # Body part distribution
    body_parts = Counter(ex.get("body_part", "Unknown") for ex in exercises)
    print(f"\nBody Part Distribution:")
    for bp, count in body_parts.most_common():
        print(f"  {bp}: {count}")

    # Equipment distribution
    equipment_dist = Counter(ex.get("equipment", "Unknown") for ex in exercises)
    print(f"\nEquipment Distribution (top 10):")
    for eq, count in equipment_dist.most_common(10):
        print(f"  {eq}: {count}")

    # Difficulty distribution
    difficulties = Counter(ex.get("difficulty_level") for ex in exercises if ex.get("difficulty_level"))
    print(f"\nDifficulty Distribution:")
    for diff, count in sorted(difficulties.items()):
        print(f"  Level {diff}: {count}")

    print(f"\nDone!")


if __name__ == "__main__":
    main()
