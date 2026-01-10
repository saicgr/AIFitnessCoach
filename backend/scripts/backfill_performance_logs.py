"""
Backfill script to migrate existing workout_logs data to performance_logs.

This script reads the sets_json from workout_logs and creates individual
records in performance_logs for efficient querying.

Usage:
    python -m scripts.backfill_performance_logs [--dry-run] [--batch-size 100]

The script:
1. Fetches workout_logs that don't have corresponding performance_logs
2. Parses the sets_json field
3. Creates individual performance_log records for each set
4. Handles both dict and list formats of sets_json
"""

import argparse
import json
import sys
from datetime import datetime
from typing import List, Dict, Any

# Add parent directory to path for imports
sys.path.insert(0, '.')

from core.supabase_db import get_supabase_db
from core.logger import get_logger

logger = get_logger(__name__)


def parse_sets_json(sets_json: Any) -> Dict[str, List[Dict]]:
    """
    Parse sets_json field which can be in various formats.

    Returns: Dict mapping exercise_name -> list of set dicts
    """
    if sets_json is None:
        return {}

    # Handle string JSON
    if isinstance(sets_json, str):
        try:
            sets_json = json.loads(sets_json)
        except json.JSONDecodeError:
            logger.warning(f"Failed to parse sets_json string: {sets_json[:100]}...")
            return {}

    # If it's already a dict with exercise names as keys
    if isinstance(sets_json, dict):
        return sets_json

    # If it's a list, it might be a flat list of sets
    if isinstance(sets_json, list):
        # Try to group by exercise_name if available
        result = {}
        for item in sets_json:
            if isinstance(item, dict):
                exercise_name = item.get("exercise_name") or item.get("name") or "unknown"
                if exercise_name not in result:
                    result[exercise_name] = []
                result[exercise_name].append(item)
        return result

    return {}


def create_performance_log_records(
    workout_log_id: str,
    user_id: str,
    sets_json: Any,
    completed_at: str,
) -> List[Dict]:
    """
    Create performance_log records from sets_json.

    Returns list of records ready for insertion.
    """
    records = []
    parsed = parse_sets_json(sets_json)

    for exercise_name, sets in parsed.items():
        if not sets or not exercise_name:
            continue

        for i, set_data in enumerate(sets):
            if not isinstance(set_data, dict):
                continue

            # Skip incomplete sets
            if not set_data.get("completed", True):
                continue

            # Extract set data with various field name possibilities
            set_number = set_data.get("set_number", i + 1)
            reps_completed = (
                set_data.get("reps_completed") or
                set_data.get("reps") or
                set_data.get("actual_reps") or
                0
            )
            weight_kg = (
                set_data.get("weight_kg") or
                set_data.get("weight") or
                0
            )
            rpe = set_data.get("rpe")
            rir = set_data.get("rir")
            set_type = set_data.get("set_type", "working")
            tempo = set_data.get("tempo")
            is_completed = set_data.get("completed", True)
            failed_at_rep = set_data.get("failed_at_rep")
            notes = set_data.get("notes")

            # Get exercise_id from various possible fields
            exercise_id = (
                set_data.get("exercise_id") or
                set_data.get("id") or
                exercise_name.lower().replace(" ", "_")
            )

            # Skip sets with no meaningful data
            if reps_completed <= 0 and weight_kg <= 0:
                continue

            record = {
                "workout_log_id": workout_log_id,
                "user_id": user_id,
                "exercise_id": str(exercise_id),
                "exercise_name": exercise_name,
                "set_number": set_number,
                "reps_completed": int(reps_completed),
                "weight_kg": float(weight_kg),
                "rpe": float(rpe) if rpe is not None else None,
                "rir": int(rir) if rir is not None else None,
                "set_type": set_type,
                "tempo": tempo,
                "is_completed": is_completed,
                "failed_at_rep": failed_at_rep,
                "notes": notes,
                "recorded_at": completed_at,
            }

            records.append(record)

    return records


def backfill_performance_logs(dry_run: bool = False, batch_size: int = 100):
    """
    Main backfill function.

    Args:
        dry_run: If True, don't actually insert, just log what would be done
        batch_size: Number of workout_logs to process at a time
    """
    db = get_supabase_db()

    # Get workout_logs that don't have performance_logs yet
    # We do this by checking if any performance_logs exist for each workout_log
    logger.info("Fetching workout_logs to backfill...")

    # First, get all workout_log_ids that already have performance_logs
    existing_response = db.client.table("performance_logs").select(
        "workout_log_id"
    ).execute()

    existing_workout_log_ids = set(
        row["workout_log_id"] for row in (existing_response.data or [])
    )

    logger.info(f"Found {len(existing_workout_log_ids)} workout_logs already migrated")

    # Get all workout_logs
    offset = 0
    total_processed = 0
    total_records_created = 0

    while True:
        response = db.client.table("workout_logs").select(
            "id, user_id, sets_json, completed_at"
        ).not_.is_(
            "completed_at", "null"
        ).order(
            "completed_at", desc=True
        ).range(offset, offset + batch_size - 1).execute()

        if not response.data:
            break

        batch_records = []

        for log in response.data:
            workout_log_id = log["id"]

            # Skip if already migrated
            if workout_log_id in existing_workout_log_ids:
                continue

            user_id = log["user_id"]
            sets_json = log.get("sets_json")
            completed_at = log.get("completed_at")

            if not sets_json:
                continue

            records = create_performance_log_records(
                workout_log_id=workout_log_id,
                user_id=user_id,
                sets_json=sets_json,
                completed_at=completed_at,
            )

            if records:
                batch_records.extend(records)
                total_processed += 1

        if batch_records:
            if dry_run:
                logger.info(f"[DRY RUN] Would insert {len(batch_records)} performance_log records")
            else:
                try:
                    db.client.table("performance_logs").insert(batch_records).execute()
                    total_records_created += len(batch_records)
                    logger.info(f"Inserted {len(batch_records)} performance_log records")
                except Exception as e:
                    logger.error(f"Failed to insert batch: {e}")
                    # Continue with next batch

        offset += batch_size

        # Progress logging
        if offset % 1000 == 0:
            logger.info(f"Progress: processed {offset} workout_logs, created {total_records_created} records")

    logger.info(f"Backfill complete!")
    logger.info(f"Total workout_logs processed: {total_processed}")
    logger.info(f"Total performance_log records created: {total_records_created}")


def main():
    parser = argparse.ArgumentParser(
        description="Backfill performance_logs from workout_logs.sets_json"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Don't actually insert, just log what would be done"
    )
    parser.add_argument(
        "--batch-size",
        type=int,
        default=100,
        help="Number of workout_logs to process at a time (default: 100)"
    )

    args = parser.parse_args()

    logger.info(f"Starting backfill (dry_run={args.dry_run}, batch_size={args.batch_size})")

    backfill_performance_logs(
        dry_run=args.dry_run,
        batch_size=args.batch_size,
    )


if __name__ == "__main__":
    main()
