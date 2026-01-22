#!/usr/bin/env python3
"""
Batch Program Ingestion Script for Supabase

Features:
- Ingests validated JSON files to Supabase program_variants table
- Skips already existing records in database
- Updates status.json to track ingestion
- Creates branded_programs entries if needed

Usage:
    cd backend
    python3 scripts/batch_ingest.py

    # Dry run (no database writes)
    python3 scripts/batch_ingest.py --dry-run

    # Ingest specific file
    python3 scripts/batch_ingest.py --file 5x5_Linear_4w_3d.json

    # Force re-ingest (even if exists)
    python3 scripts/batch_ingest.py --force
"""

import os
import json
import argparse
import re
from pathlib import Path
from datetime import datetime
from typing import Optional
from dotenv import load_dotenv

# Load environment
env_path = Path(__file__).parent.parent / ".env"
load_dotenv(env_path)

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")  # Service role key for admin operations

# Paths
OUTPUT_DIR = Path(__file__).parent.parent / "generated_programs" / "json"
STATUS_FILE = OUTPUT_DIR / "status.json"


def load_status() -> dict:
    """Load generation status from file."""
    if STATUS_FILE.exists():
        with open(STATUS_FILE) as f:
            return json.load(f)
    return {"programs": {}}


def save_status(status: dict):
    """Save generation status to file."""
    status["last_updated"] = datetime.now().isoformat()
    with open(STATUS_FILE, 'w') as f:
        json.dump(status, f, indent=2)


def get_supabase_client():
    """Initialize Supabase client."""
    from supabase import create_client
    return create_client(SUPABASE_URL, SUPABASE_KEY)


def get_existing_variants(supabase) -> set:
    """Fetch all existing variant keys from database."""
    result = supabase.table('program_variants').select(
        'variant_name, duration_weeks, sessions_per_week'
    ).execute()

    existing = set()
    for row in result.data:
        # Create key from variant info
        name = row.get('variant_name', '')
        duration = row.get('duration_weeks', 0)
        sessions = row.get('sessions_per_week', 0)

        # Normalize to match our file naming
        safe_name = re.sub(r'[^\w\s-]', '', name).replace(' ', '_')
        key = f"{safe_name}_{duration}w_{sessions}d"
        existing.add(key.lower())

    return existing


def get_or_create_base_program(supabase, program_data: dict, dry_run: bool = False) -> Optional[str]:
    """Get existing branded_program or create new one. Returns UUID."""

    program_name = program_data.get("program_name", "")

    # Extract base program name (remove variant suffix like "(12 weeks)")
    base_name = re.sub(r'\s*\([^)]*\)\s*$', '', program_name).strip()

    # Check if exists in branded_programs table
    result = supabase.table('branded_programs').select('id, name').ilike(
        'name', f'%{base_name}%'
    ).limit(1).execute()

    if result.data:
        return result.data[0]['id']

    if dry_run:
        print(f"      [DRY RUN] Would create branded_program: {base_name}")
        return "dry-run-uuid"

    # Create new branded_program entry
    category = determine_category(program_data)
    difficulty = determine_difficulty(program_data)

    new_program = {
        "name": base_name,
        "tagline": program_data.get("description", "")[:100] if program_data.get("description") else None,
        "description": program_data.get("description"),
        "category": category,
        "difficulty_level": difficulty,
        "duration_weeks": program_data.get("duration_weeks", 8),
        "sessions_per_week": program_data.get("sessions_per_week", 4),
        "split_type": determine_split_type(program_data),
        "goals": program_data.get("goals", [])[:5] if program_data.get("goals") else [],
        "requires_gym": determine_requires_gym(program_data),
        "minimum_equipment": program_data.get("equipment_required", [])[:5] if program_data.get("equipment_required") else [],
        "is_active": True,
        "is_featured": False,
        "is_premium": False,
    }

    try:
        result = supabase.table('branded_programs').insert(new_program).execute()
        if result.data:
            print(f"      ✨ Created branded_program: {base_name}")
            return result.data[0]['id']
    except Exception as e:
        print(f"      ⚠️ Failed to create branded_program: {e}")

    return None


def determine_category(data: dict) -> str:
    """Determine branded_programs category from program data."""
    name = (data.get("program_name", "") + " " + data.get("description", "")).lower()

    if any(x in name for x in ["strength", "powerlifting", "5x5", "531"]):
        return "strength"
    if any(x in name for x in ["hypertrophy", "muscle", "bodybuilding", "mass"]):
        return "hypertrophy"
    if any(x in name for x in ["fat loss", "shred", "cut", "weight loss", "hiit"]):
        return "fat_loss"
    if any(x in name for x in ["athletic", "sport", "hyrox", "functional"]):
        return "athletic"
    if any(x in name for x in ["endurance", "cardio", "running", "marathon"]):
        return "endurance"
    if any(x in name for x in ["home", "bodyweight", "calisthenics", "no equipment"]):
        return "bodyweight"
    if any(x in name for x in ["power", "explosive"]):
        return "powerbuilding"

    return "general_fitness"


def determine_difficulty(data: dict) -> str:
    """Determine difficulty level from program data."""
    difficulty = data.get("difficulty", "").lower()

    if difficulty in ["beginner", "easy"]:
        return "beginner"
    if difficulty in ["intermediate", "moderate"]:
        return "intermediate"
    if difficulty in ["advanced", "hard", "expert"]:
        return "advanced"

    # Infer from program structure
    sessions = data.get("sessions_per_week", 3)
    if sessions >= 6:
        return "advanced"
    if sessions >= 4:
        return "intermediate"
    return "beginner"


def determine_split_type(data: dict) -> str:
    """Determine split type from program data."""
    name = data.get("program_name", "").lower()

    if "ppl" in name or "push pull leg" in name:
        return "push_pull_legs"
    if "upper lower" in name:
        return "upper_lower"
    if "full body" in name:
        return "full_body"
    if "bro split" in name:
        return "bro_split"
    if "arnold" in name:
        return "arnold_split"

    # Default based on sessions
    sessions = data.get("sessions_per_week", 3)
    if sessions <= 3:
        return "full_body"
    if sessions == 4:
        return "upper_lower"
    return "push_pull_legs"


def determine_requires_gym(data: dict) -> bool:
    """Determine if program requires gym equipment."""
    equipment = data.get("equipment_required", [])
    name = data.get("program_name", "").lower()

    # Check for home/bodyweight programs
    if any(x in name for x in ["home", "bodyweight", "no equipment", "apartment"]):
        return False

    # Check equipment list
    gym_equipment = ["barbell", "squat rack", "cable", "machine", "lat pulldown", "leg press"]
    for eq in equipment:
        if any(gym_eq in eq.lower() for gym_eq in gym_equipment):
            return True

    return True  # Default to requiring gym


def ingest_program(supabase, filepath: Path, existing_keys: set, dry_run: bool = False, force: bool = False) -> dict:
    """Ingest a single program JSON to Supabase."""

    variant_key = filepath.stem.lower()

    # Check if already exists
    if not force and variant_key in existing_keys:
        return {"success": True, "skipped": True, "reason": "Already in database"}

    # Load JSON
    try:
        with open(filepath) as f:
            data = json.load(f)
    except Exception as e:
        return {"success": False, "error": f"Failed to load JSON: {e}"}

    # Get or create base program
    base_program_id = get_or_create_base_program(supabase, data, dry_run)
    if not base_program_id:
        return {"success": False, "error": "Failed to get/create branded_program"}

    # Prepare variant record
    variant_name = data.get("program_name", filepath.stem)
    duration_weeks = data.get("duration_weeks", 8)
    sessions_per_week = data.get("sessions_per_week", 4)

    # Determine intensity level
    intensity = "Medium"  # Default
    if "hard" in variant_name.lower() or "advanced" in data.get("difficulty", "").lower():
        intensity = "Hard"
    elif "easy" in variant_name.lower() or "beginner" in data.get("difficulty", "").lower():
        intensity = "Easy"

    variant_record = {
        "base_program_id": base_program_id,
        "variant_name": variant_name,
        "intensity_level": intensity,
        "duration_weeks": duration_weeks,
        "program_category": determine_category(data).title(),
        "program_subcategory": None,
        "sessions_per_week": sessions_per_week,
        "session_duration_minutes": 60,  # Default
        "tags": data.get("tags", [])[:10] if data.get("tags") else [],
        "goals": data.get("goals", [])[:10] if data.get("goals") else [],
        "workouts": data.get("workouts", {}),
        "generation_model": "gemini-2.5-flash",
        "generation_cost_usd": 0.003,  # Approximate
    }

    if dry_run:
        print(f"      [DRY RUN] Would insert variant: {variant_name}")
        return {"success": True, "dry_run": True}

    try:
        result = supabase.table('program_variants').insert(variant_record).execute()
        if result.data:
            return {"success": True, "id": result.data[0].get("id")}
        else:
            return {"success": False, "error": "No data returned from insert"}
    except Exception as e:
        error_msg = str(e)
        if "duplicate" in error_msg.lower() or "unique" in error_msg.lower():
            return {"success": True, "skipped": True, "reason": "Duplicate key"}
        return {"success": False, "error": error_msg}


def main():
    parser = argparse.ArgumentParser(description='Ingest programs to Supabase')
    parser.add_argument('--file', type=str, help='Ingest specific file only')
    parser.add_argument('--dry-run', action='store_true', help='No database writes')
    parser.add_argument('--force', action='store_true', help='Re-ingest even if exists')
    parser.add_argument('--limit', type=int, help='Limit number of files to ingest')
    parser.add_argument('--validated-only', action='store_true', help='Only ingest validated files')
    args = parser.parse_args()

    print("=" * 60)
    print("📤 BATCH PROGRAM INGESTION TO SUPABASE")
    print("=" * 60)
    print(f"Source: {OUTPUT_DIR}")
    print(f"Database: {SUPABASE_URL}")

    if args.dry_run:
        print("\n🔍 DRY RUN MODE - No database writes")

    # Initialize Supabase
    try:
        supabase = get_supabase_client()
        print("✅ Connected to Supabase")
    except Exception as e:
        print(f"❌ Failed to connect to Supabase: {e}")
        return

    # Load status
    status = load_status()

    # Get existing variants from database
    print("\n📊 Fetching existing variants from database...")
    existing_keys = get_existing_variants(supabase)
    print(f"   Found {len(existing_keys)} existing variants")

    # Get files to ingest
    if args.file:
        files = [OUTPUT_DIR / args.file]
    else:
        files = sorted(OUTPUT_DIR.glob("*.json"))
        files = [f for f in files if f.name not in ["status.json", "validation_report.json"]]

    # Filter to validated only if specified
    if args.validated_only:
        validated_files = []
        for f in files:
            key = f.stem
            prog_status = status.get('programs', {}).get(key, {})
            if prog_status.get('validated', False):
                validated_files.append(f)
        files = validated_files
        print(f"   Filtered to {len(files)} validated files")

    if args.limit:
        files = files[:args.limit]

    print(f"\nFiles to ingest: {len(files)}")

    # Ingest each file
    ingested = 0
    skipped = 0
    failed = 0

    for filepath in files:
        variant_key = filepath.stem

        print(f"\n📦 {filepath.name}")

        result = ingest_program(supabase, filepath, existing_keys, dry_run=args.dry_run, force=args.force)

        if result.get('skipped'):
            print(f"   ⏭️  Skipped: {result.get('reason', 'Already exists')}")
            skipped += 1
        elif result['success']:
            print(f"   ✅ Ingested")
            ingested += 1

            # Update status
            if variant_key in status.get('programs', {}):
                status['programs'][variant_key]['ingested'] = True
                status['programs'][variant_key]['ingested_at'] = datetime.now().isoformat()
        else:
            print(f"   ❌ Failed: {result.get('error', 'Unknown error')}")
            failed += 1

            # Update status
            if variant_key in status.get('programs', {}):
                status['programs'][variant_key]['ingestion_error'] = result.get('error')

        # Save status periodically
        if (ingested + skipped + failed) % 20 == 0:
            save_status(status)

    # Final save
    save_status(status)

    # Summary
    print("\n" + "=" * 60)
    print("📊 INGESTION SUMMARY")
    print("=" * 60)
    print(f"Ingested: {ingested}")
    print(f"Skipped (already exist): {skipped}")
    print(f"Failed: {failed}")
    print(f"\nStatus updated in: {STATUS_FILE}")


if __name__ == "__main__":
    main()
