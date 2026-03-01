#!/usr/bin/env python3
"""
Exercise Library Matcher
========================
Fetches all exercises from exercise_library_cleaned view via Supabase,
exports exercise_library_lookup.json for use by program generation agents.

Usage:
    cd backend
    python3 scripts/match_exercises.py
"""

import os
import re
import json
from pathlib import Path
from dotenv import load_dotenv

# Load environment
env_path = Path(__file__).parent.parent / ".env"
load_dotenv(env_path)

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

OUTPUT_PATH = Path(__file__).parent / "exercise_library_lookup.json"


def normalize_name(name: str) -> str:
    """Normalize exercise name for matching."""
    name = name.lower().strip()
    # Remove common prefixes/suffixes
    name = re.sub(r'\b(barbell|dumbbell|cable|machine|smith machine|ez bar|kettlebell)\b', '', name).strip()
    # Remove extra whitespace
    name = re.sub(r'\s+', ' ', name)
    return name


def fetch_exercises():
    """Fetch all exercises from exercise_library_cleaned view."""
    from supabase import create_client

    if not SUPABASE_URL or not SUPABASE_KEY:
        raise SystemExit("SUPABASE_URL and SUPABASE_KEY environment variables are required")

    client = create_client(SUPABASE_URL, SUPABASE_KEY)

    all_exercises = []
    page_size = 1000
    offset = 0

    while True:
        result = client.table("exercise_library_cleaned").select(
            "id, name, original_name, equipment, body_part, target_muscle, "
            "secondary_muscles, difficulty_level, category, video_url, image_url"
        ).range(offset, offset + page_size - 1).execute()

        if not result.data:
            break

        all_exercises.extend(result.data)
        print(f"  Fetched {len(all_exercises)} exercises...")

        if len(result.data) < page_size:
            break
        offset += page_size

    return all_exercises


def build_lookup(exercises: list) -> dict:
    """Build lookup dictionary keyed by normalized name variants."""
    lookup = {}
    stats = {"total": 0, "with_video": 0, "with_image": 0}

    for ex in exercises:
        ex_id = ex["id"]
        name = ex.get("name", "")
        original_name = ex.get("original_name", "")
        equipment = ex.get("equipment", "")
        body_part = ex.get("body_part", "")
        target_muscle = ex.get("target_muscle", "")
        secondary_muscles = ex.get("secondary_muscles", [])
        difficulty = ex.get("difficulty_level", "")
        category = ex.get("category", "")
        has_video = bool(ex.get("video_url"))
        has_image = bool(ex.get("image_url"))

        stats["total"] += 1
        if has_video:
            stats["with_video"] += 1
        if has_image:
            stats["with_image"] += 1

        entry = {
            "id": ex_id,
            "name": name,
            "original_name": original_name,
            "equipment": equipment,
            "body_part": body_part,
            "target_muscle": target_muscle,
            "secondary_muscles": secondary_muscles if secondary_muscles else [],
            "difficulty": difficulty,
            "category": category,
            "has_video": has_video,
            "has_image": has_image,
        }

        # Index by multiple name variants for flexible matching
        keys = set()
        keys.add(name.lower().strip())
        keys.add(original_name.lower().strip())
        keys.add(normalize_name(name))

        # Also add without equipment prefix
        for equip in ["barbell", "dumbbell", "cable", "machine", "kettlebell",
                       "smith machine", "ez bar", "resistance band", "bodyweight"]:
            if name.lower().startswith(equip):
                stripped = name[len(equip):].strip().lower()
                if stripped:
                    keys.add(stripped)

        for key in keys:
            if key and key not in lookup:
                lookup[key] = entry

    return lookup, stats


def main():
    print("Exercise Library Matcher")
    print("=" * 50)

    print("\n1. Fetching exercises from exercise_library_cleaned...")
    exercises = fetch_exercises()
    print(f"   Total exercises fetched: {len(exercises)}")

    print("\n2. Building lookup dictionary...")
    lookup, stats = build_lookup(exercises)
    print(f"   Lookup entries: {len(lookup)}")
    print(f"   Exercises with video: {stats['with_video']}")
    print(f"   Exercises with image: {stats['with_image']}")

    print(f"\n3. Writing to {OUTPUT_PATH}...")
    with open(OUTPUT_PATH, 'w') as f:
        json.dump(lookup, f, indent=2, default=str)
    print(f"   File size: {OUTPUT_PATH.stat().st_size / 1024:.1f} KB")

    # Also write a simplified version for quick reference
    simple_path = Path(__file__).parent / "exercise_names.txt"
    with open(simple_path, 'w') as f:
        names = sorted(set(ex.get("name", "") for ex in exercises))
        for name in names:
            f.write(f"{name}\n")
    print(f"   Also wrote {len(names)} names to {simple_path}")

    print("\nDone!")


if __name__ == "__main__":
    main()
