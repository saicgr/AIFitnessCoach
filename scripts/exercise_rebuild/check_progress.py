#!/usr/bin/env python3
"""
Check progress of exercise research agents.
Merges any completed research into the master CSV.
Run anytime to see current state.
"""

import json
import csv
import os
from pathlib import Path

REBUILD_DIR = Path("/Users/saichetangrandhe/AIFitnessCoach/scripts/exercise_rebuild")
MASTER_CSV = REBUILD_DIR / "exercise_library_master.csv"
MERGED_JSON = Path("/tmp/merged_exercises.json")

RESEARCH_FILES = {
    "Legs": "/tmp/research_Legs.json",
    "Calisthenics": "/tmp/research_Calisthenics.json",
    "Shoulders": "/tmp/research_Shoulders.json",
    "Abdominals": "/tmp/research_Abdominals.json",
    "Back": "/tmp/research_Back.json",
    "Chest": "/tmp/research_Chest.json",
    "Biceps": "/tmp/research_Biceps.json",
    "Stretching": "/tmp/research_Stretching.json",
    "Yoga": "/tmp/research_Yoga.json",
    "Forearms": "/tmp/research_Forearms.json",
    "Powerlifting": "/tmp/research_Powerlifting.json",
    "Triceps": "/tmp/research_Triceps.json",
}

# All columns in exercise_library
CSV_COLUMNS = [
    "exercise_name", "folder", "video_s3_path", "image_s3_path",
    "body_part", "equipment", "target_muscle", "secondary_muscles",
    "instructions", "tips", "difficulty_level", "category",
    "goals", "suitable_for", "avoid_if",
    "is_timed", "is_unilateral", "single_dumbbell_friendly", "single_kettlebell_friendly",
    "movement_pattern", "mechanic_type", "force_type", "plane_of_motion",
    "energy_system", "default_rep_range_min", "default_rep_range_max",
    "default_rest_seconds", "default_hold_seconds", "default_tempo",
    "default_duration_seconds", "default_incline_percent", "default_speed_mph",
    "default_resistance_level", "default_rpm", "stroke_rate_spm",
    "impact_level", "form_complexity", "stability_requirement",
    "contraindicated_conditions", "is_dynamic_stretch",
    "hold_seconds_min", "hold_seconds_max",
    "raw_data", "research_status",
]


def load_merged_base():
    """Load the merged base data (Excel + backup + folders)."""
    if not MERGED_JSON.exists():
        print("ERROR: /tmp/merged_exercises.json not found. Run rebuild_exercise_library.py first.")
        return {}

    with open(MERGED_JSON) as f:
        data = json.load(f)

    # Index by exercise_name (lowercase)
    return {ex["exercise_name"].lower().strip(): ex for ex in data}


def load_research(folder_name, filepath):
    """Load a research output file if it exists."""
    if not os.path.exists(filepath):
        return None

    try:
        with open(filepath) as f:
            data = json.load(f)
        if isinstance(data, list) and len(data) > 0:
            return data
    except (json.JSONDecodeError, Exception) as e:
        print(f"  WARNING: {filepath} is invalid JSON: {e}")
    return None


def merge_research_into_base(base_map, research_data):
    """Merge research fields into base exercise data."""
    merged_count = 0
    for res in research_data:
        name = res.get("exercise_name", "").lower().strip()
        if name in base_map:
            ex = base_map[name]
            # Merge research fields (don't overwrite existing good data)
            for field in ["category", "body_part", "difficulty_level", "movement_pattern",
                          "mechanic_type", "force_type", "plane_of_motion", "energy_system",
                          "default_rep_range_min", "default_rep_range_max", "default_rest_seconds",
                          "impact_level", "form_complexity", "stability_requirement",
                          "contraindicated_conditions", "is_dynamic_stretch",
                          "hold_seconds_min", "hold_seconds_max", "default_hold_seconds"]:
                if res.get(field) is not None:
                    ex[field] = res[field]
            ex["research_status"] = "done"
            merged_count += 1
    return merged_count


def save_master_csv(base_map):
    """Save all exercises to master CSV."""
    with open(MASTER_CSV, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=CSV_COLUMNS, extrasaction="ignore")
        writer.writeheader()
        for ex in sorted(base_map.values(), key=lambda x: (x.get("folder", ""), x.get("exercise_name", ""))):
            # Convert lists/dicts to JSON strings for CSV
            row = {}
            for col in CSV_COLUMNS:
                val = ex.get(col)
                if isinstance(val, (list, dict)):
                    row[col] = json.dumps(val)
                elif val is None:
                    row[col] = ""
                else:
                    row[col] = str(val)
            writer.writerow(row)

    print(f"\nMaster CSV saved: {MASTER_CSV}")
    print(f"  Total rows: {len(base_map)}")


def main():
    print("=" * 60)
    print("EXERCISE REBUILD PROGRESS CHECK")
    print("=" * 60)

    # Load base data
    base_map = load_merged_base()
    if not base_map:
        return

    print(f"\nBase exercises loaded: {len(base_map)}")

    # Check each research file
    print(f"\nResearch agent status:")
    total_researched = 0
    completed_folders = []
    pending_folders = []

    for folder, filepath in RESEARCH_FILES.items():
        research = load_research(folder, filepath)
        if research:
            count = merge_research_into_base(base_map, research)
            total_researched += count
            completed_folders.append(folder)
            print(f"  {folder}: DONE ({count} exercises merged from {len(research)} researched)")
        else:
            pending_folders.append(folder)
            print(f"  {folder}: PENDING")

    # Count fill rates
    print(f"\n{'='*60}")
    print(f"COLUMN FILL RATES")
    print(f"{'='*60}")
    total = len(base_map)
    for col in ["category", "body_part", "target_muscle", "secondary_muscles",
                 "equipment", "instructions", "difficulty_level", "movement_pattern",
                 "mechanic_type", "force_type", "goals", "contraindicated_conditions"]:
        filled = sum(1 for ex in base_map.values() if ex.get(col))
        pct = filled / total * 100
        status = "OK" if pct > 90 else "PARTIAL" if pct > 50 else "LOW"
        print(f"  {col:30s}: {filled:4d}/{total} ({pct:5.1f}%) [{status}]")

    # Summary
    print(f"\n{'='*60}")
    print(f"SUMMARY")
    print(f"{'='*60}")
    print(f"  Completed: {len(completed_folders)}/12 folders")
    print(f"  Researched: {total_researched}/{total} exercises")
    print(f"  Pending: {', '.join(pending_folders) if pending_folders else 'NONE'}")

    # Save CSV
    save_master_csv(base_map)


if __name__ == "__main__":
    main()
