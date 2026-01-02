"""
Data Import Service for FitWiz.

Imports user data from a previously exported ZIP file containing CSV files.
Handles ID regeneration and relationship mapping for data portability.
"""
import csv
import io
import json
import uuid
import zipfile
from datetime import datetime
from typing import Dict, List, Any, Optional

from core.supabase_db import get_supabase_db
from core.logger import get_logger

logger = get_logger(__name__)

# Supported export versions
SUPPORTED_VERSIONS = ["1.0"]


def import_user_data(user_id: str, zip_content: bytes) -> Dict[str, int]:
    """
    Import user data from a ZIP file.

    All CSV files are OPTIONAL - import whatever exists in the ZIP.
    The only required file is _metadata.csv for version validation.

    Core files for workout continuity:
    - workouts.csv - Workout plans
    - exercise_sets.csv - Performance history (weights, reps)
    - strength_records.csv - Personal records

    Optional files:
    - profile.csv - User settings (usually re-entered during onboarding)
    - body_metrics.csv - Historical measurements
    - workout_logs.csv - Session summaries
    - achievements.csv - Earned badges (can be re-earned)
    - streaks.csv - Streak history (resets anyway)

    Args:
        user_id: The target user ID to import data into
        zip_content: The ZIP file content as bytes

    Returns:
        Dictionary with counts of imported items

    Raises:
        ValueError: If the ZIP file is invalid or incompatible
    """
    logger.info(f"Starting data import for user: {user_id}")

    db = get_supabase_db()

    # Verify user exists
    user = db.get_user(user_id)
    if not user:
        raise ValueError(f"User {user_id} not found")

    # Parse ZIP file
    try:
        zip_buffer = io.BytesIO(zip_content)
        with zipfile.ZipFile(zip_buffer, 'r') as zip_file:
            # List files in ZIP
            file_list = zip_file.namelist()
            logger.info(f"ZIP contains {len(file_list)} files: {file_list}")

            # Metadata is optional but recommended for version checking
            metadata = {}
            if "_metadata.csv" in file_list:
                metadata = _parse_metadata(zip_file.read("_metadata.csv").decode('utf-8'))
                _validate_metadata(metadata)
            else:
                logger.warning("No _metadata.csv found, skipping version check")

            # Import counts
            counts = {}

            # ID mapping for relationships (old_id -> new_id)
            workout_id_map = {}
            log_id_map = {}

            # 1. Import profile (update user settings)
            if "profile.csv" in file_list:
                profile_data = _parse_profile(zip_file.read("profile.csv").decode('utf-8'))
                if profile_data:
                    _import_profile(db, user_id, profile_data)
                    counts["profile"] = 1

            # 2. Import body metrics
            if "body_metrics.csv" in file_list:
                metrics = _parse_csv(zip_file.read("body_metrics.csv").decode('utf-8'))
                count = _import_body_metrics(db, user_id, metrics)
                counts["body_metrics"] = count

            # 3. Import workouts (need to map IDs)
            if "workouts.csv" in file_list:
                workouts = _parse_csv(zip_file.read("workouts.csv").decode('utf-8'))
                count, workout_id_map = _import_workouts(db, user_id, workouts)
                counts["workouts"] = count

            # 4. Import workout logs (need to map workout IDs)
            if "workout_logs.csv" in file_list:
                logs = _parse_csv(zip_file.read("workout_logs.csv").decode('utf-8'))
                count, log_id_map = _import_workout_logs(db, user_id, logs, workout_id_map)
                counts["workout_logs"] = count

            # 5. Import exercise sets (need to map log IDs)
            if "exercise_sets.csv" in file_list:
                sets = _parse_csv(zip_file.read("exercise_sets.csv").decode('utf-8'))
                count = _import_exercise_sets(db, user_id, sets, log_id_map)
                counts["exercise_sets"] = count

            # 6. Import strength records
            if "strength_records.csv" in file_list:
                records = _parse_csv(zip_file.read("strength_records.csv").decode('utf-8'))
                count = _import_strength_records(db, user_id, records)
                counts["strength_records"] = count

            # 7. Import achievements
            if "achievements.csv" in file_list:
                achievements = _parse_csv(zip_file.read("achievements.csv").decode('utf-8'))
                count = _import_achievements(db, user_id, achievements)
                counts["achievements"] = count

            # 8. Import streaks
            if "streaks.csv" in file_list:
                streaks = _parse_csv(zip_file.read("streaks.csv").decode('utf-8'))
                count = _import_streaks(db, user_id, streaks)
                counts["streaks"] = count

    except zipfile.BadZipFile:
        raise ValueError("Invalid ZIP file format")
    except Exception as e:
        logger.error(f"Import error: {e}")
        raise

    logger.info(f"Data import complete for user {user_id}: {counts}")
    return counts


def _parse_metadata(csv_content: str) -> Dict[str, str]:
    """Parse metadata CSV to dictionary."""
    reader = csv.DictReader(io.StringIO(csv_content))
    metadata = {}
    for row in reader:
        metadata[row["key"]] = row["value"]
    return metadata


def _validate_metadata(metadata: Dict[str, str]) -> None:
    """Validate export metadata. Lenient - only warns on version mismatch."""
    version = metadata.get("export_version")
    if version and version not in SUPPORTED_VERSIONS:
        logger.warning(f"Export version {version} may not be fully compatible. Supported: {SUPPORTED_VERSIONS}")


def _parse_csv(csv_content: str) -> List[Dict[str, str]]:
    """Parse CSV content to list of dictionaries."""
    reader = csv.DictReader(io.StringIO(csv_content))
    return list(reader)


def _parse_profile(csv_content: str) -> Optional[Dict[str, str]]:
    """Parse profile CSV to dictionary."""
    rows = _parse_csv(csv_content)
    return rows[0] if rows else None


def _import_profile(db, user_id: str, profile: Dict[str, str]) -> None:
    """Import profile data (update user settings)."""
    update_data = {}

    # Map CSV fields to database fields
    if profile.get("fitness_level"):
        update_data["fitness_level"] = profile["fitness_level"]

    if profile.get("goals"):
        goals = profile["goals"].split(",") if profile["goals"] else []
        update_data["goals"] = goals

    if profile.get("equipment"):
        equipment = profile["equipment"].split(",") if profile["equipment"] else []
        update_data["equipment"] = equipment

    if profile.get("active_injuries"):
        injuries = profile["active_injuries"].split(",") if profile["active_injuries"] else []
        update_data["active_injuries"] = injuries

    # Only update numeric fields if they have values
    if profile.get("height_cm"):
        try:
            update_data["height_cm"] = float(profile["height_cm"])
        except:
            pass

    if profile.get("weight_kg"):
        try:
            update_data["weight_kg"] = float(profile["weight_kg"])
        except:
            pass

    if profile.get("target_weight_kg"):
        try:
            update_data["target_weight_kg"] = float(profile["target_weight_kg"])
        except:
            pass

    if profile.get("age"):
        try:
            update_data["age"] = int(profile["age"])
        except:
            pass

    if profile.get("gender"):
        update_data["gender"] = profile["gender"]

    if profile.get("activity_level"):
        update_data["activity_level"] = profile["activity_level"]

    if update_data:
        db.update_user(user_id, update_data)
        logger.debug(f"Updated profile: {list(update_data.keys())}")


def _import_body_metrics(db, user_id: str, metrics: List[Dict[str, str]]) -> int:
    """Import body metrics."""
    count = 0
    for m in metrics:
        try:
            data = {
                "user_id": user_id,
                "recorded_at": m.get("recorded_at") or datetime.utcnow().isoformat(),
            }

            # Add numeric fields if present
            for field in ["weight_kg", "waist_cm", "hip_cm", "neck_cm",
                          "body_fat_percent", "resting_heart_rate",
                          "blood_pressure_systolic", "blood_pressure_diastolic"]:
                if m.get(field):
                    try:
                        # Map body_fat_percent to body_fat_measured
                        db_field = "body_fat_measured" if field == "body_fat_percent" else field
                        data[db_field] = float(m[field])
                    except:
                        pass

            db.create_user_metrics(data)
            count += 1
        except Exception as e:
            logger.warning(f"Failed to import metric: {e}")

    return count


def _import_workouts(db, user_id: str, workouts: List[Dict[str, str]]) -> tuple:
    """Import workouts and return ID mapping."""
    count = 0
    id_map = {}

    for w in workouts:
        try:
            old_id = w.get("workout_id")

            # Parse exercises JSON
            exercises_json = w.get("exercises_json", "[]")
            try:
                exercises = json.loads(exercises_json)
            except:
                exercises = []

            data = {
                "user_id": user_id,
                "name": w.get("name", "Imported Workout"),
                "type": w.get("type", "general"),
                "difficulty": w.get("difficulty", "intermediate"),
                "scheduled_date": w.get("scheduled_date"),
                "is_completed": w.get("is_completed", "false").lower() == "true",
                "exercises_json": exercises,
                "generation_method": "import",
                "generation_source": "user_import",
                "is_current": True,
                "version_number": 1,
            }

            if w.get("duration_minutes"):
                try:
                    data["duration_minutes"] = int(w["duration_minutes"])
                except:
                    data["duration_minutes"] = 45

            result = db.create_workout(data)
            if result:
                new_id = result["id"]
                if old_id:
                    id_map[old_id] = new_id
                count += 1
        except Exception as e:
            logger.warning(f"Failed to import workout: {e}")

    return count, id_map


def _import_workout_logs(db, user_id: str, logs: List[Dict[str, str]], workout_id_map: Dict[str, str]) -> tuple:
    """Import workout logs and return ID mapping."""
    count = 0
    id_map = {}

    for log in logs:
        try:
            old_id = log.get("log_id")
            old_workout_id = log.get("workout_id")

            # Map to new workout ID if available
            new_workout_id = workout_id_map.get(old_workout_id) if old_workout_id else None

            data = {
                "user_id": user_id,
                "workout_id": new_workout_id,
                "workout_name": log.get("workout_name", "Imported Workout"),
                "completed_at": log.get("completed_at") or datetime.utcnow().isoformat(),
                "sets_json": [],  # Will be populated from exercise_sets
            }

            if log.get("total_time_seconds"):
                try:
                    data["total_time_seconds"] = int(log["total_time_seconds"])
                except:
                    pass

            result = db.create_workout_log(data)
            if result:
                new_id = result["id"]
                if old_id:
                    id_map[old_id] = new_id
                count += 1
        except Exception as e:
            logger.warning(f"Failed to import workout log: {e}")

    return count, id_map


def _import_exercise_sets(db, user_id: str, sets: List[Dict[str, str]], log_id_map: Dict[str, str]) -> int:
    """Import exercise sets (performance logs)."""
    count = 0

    for s in sets:
        try:
            old_log_id = s.get("log_id")

            # Map to new log ID
            new_log_id = log_id_map.get(old_log_id) if old_log_id else None
            if not new_log_id:
                continue  # Skip if we can't map to a log

            data = {
                "user_id": user_id,
                "workout_log_id": new_log_id,
                "exercise_name": s.get("exercise_name", "Unknown"),
                "recorded_at": datetime.utcnow().isoformat(),
            }

            # Add numeric fields
            if s.get("set_number"):
                try:
                    data["set_number"] = int(s["set_number"])
                except:
                    data["set_number"] = 1

            if s.get("reps_completed"):
                try:
                    data["reps_completed"] = int(s["reps_completed"])
                except:
                    pass

            if s.get("weight_kg"):
                try:
                    data["weight_kg"] = float(s["weight_kg"])
                except:
                    pass

            if s.get("rpe"):
                try:
                    data["rpe"] = float(s["rpe"])
                except:
                    pass

            data["is_completed"] = s.get("is_completed", "true").lower() == "true"

            if s.get("notes"):
                data["notes"] = s["notes"]

            db.create_performance_log(data)
            count += 1
        except Exception as e:
            logger.warning(f"Failed to import exercise set: {e}")

    return count


def _import_strength_records(db, user_id: str, records: List[Dict[str, str]]) -> int:
    """Import strength records."""
    count = 0

    for r in records:
        try:
            data = {
                "user_id": user_id,
                "exercise_name": r.get("exercise_name", "Unknown"),
                "achieved_at": r.get("achieved_at") or datetime.utcnow().isoformat(),
            }

            if r.get("weight_kg"):
                try:
                    data["weight_kg"] = float(r["weight_kg"])
                except:
                    pass

            if r.get("reps"):
                try:
                    data["reps"] = int(r["reps"])
                except:
                    pass

            if r.get("estimated_1rm"):
                try:
                    data["estimated_1rm"] = float(r["estimated_1rm"])
                except:
                    pass

            data["is_pr"] = r.get("is_pr", "false").lower() == "true"

            db.create_strength_record(data)
            count += 1
        except Exception as e:
            logger.warning(f"Failed to import strength record: {e}")

    return count


def _import_achievements(db, user_id: str, achievements: List[Dict[str, str]]) -> int:
    """Import achievements by looking up achievement types."""
    count = 0

    for a in achievements:
        try:
            achievement_name = a.get("achievement_name")
            if not achievement_name:
                continue

            # Look up achievement type by name
            result = db.client.table("achievement_types").select("id").eq("name", achievement_name).execute()
            if not result.data:
                logger.debug(f"Achievement type not found: {achievement_name}")
                continue

            achievement_type_id = result.data[0]["id"]

            # Check if already earned
            existing = db.client.table("user_achievements").select("id").eq(
                "user_id", user_id
            ).eq("achievement_id", achievement_type_id).execute()

            if existing.data:
                continue  # Already has this achievement

            data = {
                "user_id": user_id,
                "achievement_id": achievement_type_id,
                "earned_at": a.get("earned_at") or datetime.utcnow().isoformat(),
                "is_notified": True,  # Don't trigger notification for imports
            }

            if a.get("trigger_value"):
                try:
                    data["trigger_value"] = float(a["trigger_value"])
                except:
                    pass

            db.client.table("user_achievements").insert(data).execute()
            count += 1
        except Exception as e:
            logger.warning(f"Failed to import achievement: {e}")

    return count


def _import_streaks(db, user_id: str, streaks: List[Dict[str, str]]) -> int:
    """Import streaks (upsert - update if exists)."""
    count = 0

    for s in streaks:
        try:
            streak_type = s.get("streak_type")
            if not streak_type:
                continue

            data = {
                "user_id": user_id,
                "streak_type": streak_type,
                "current_streak": int(s.get("current_streak", 0)),
                "longest_streak": int(s.get("longest_streak", 0)),
            }

            if s.get("last_activity_date"):
                data["last_activity_date"] = s["last_activity_date"]

            if s.get("streak_start_date"):
                data["streak_start_date"] = s["streak_start_date"]

            # Check if streak exists
            existing = db.client.table("user_streaks").select("id").eq(
                "user_id", user_id
            ).eq("streak_type", streak_type).execute()

            if existing.data:
                # Update existing streak (keep higher values)
                existing_id = existing.data[0]["id"]
                db.client.table("user_streaks").update({
                    "longest_streak": data["longest_streak"],  # Always take imported longest
                }).eq("id", existing_id).execute()
            else:
                # Insert new streak
                db.client.table("user_streaks").insert(data).execute()

            count += 1
        except Exception as e:
            logger.warning(f"Failed to import streak: {e}")

    return count
