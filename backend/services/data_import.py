"""
Data Import Service for Zealova.

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

# Supported export versions.
# Must always contain services.data_export.EXPORT_VERSION — an export this app
# produces has to be an export this app can import back (round-trip invariant,
# and GDPR Art. 20 portability requires the archive we hand the user be usable).
# 2.0 is a superset of 1.0: it adds CSV files (chat_history, food_logs, ...) and
# removes none, and the importer reads files by name and treats every file as
# optional, so 1.0 archives keep importing unchanged.
SUPPORTED_VERSIONS = ["1.0", "2.0"]

# ZIP bomb protection limits
_MAX_UNCOMPRESSED_SIZE = 200 * 1024 * 1024  # 200 MB
_MAX_FILE_COUNT = 100


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
    truncated_uid = f"...{user_id[-4:]}" if user_id and len(user_id) > 4 else user_id
    logger.info(f"Starting data import for user: {truncated_uid}")

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

            # ZIP bomb protection: check file count
            if len(file_list) > _MAX_FILE_COUNT:
                raise ValueError(f"ZIP contains too many files ({len(file_list)}), max {_MAX_FILE_COUNT}")

            # ZIP bomb protection: check total uncompressed size
            total_size = sum(info.file_size for info in zip_file.infolist())
            if total_size > _MAX_UNCOMPRESSED_SIZE:
                raise ValueError(f"ZIP uncompressed size too large ({total_size} bytes), max {_MAX_UNCOMPRESSED_SIZE}")

            # Path traversal protection: reject filenames with ..
            for name in file_list:
                if ".." in name or name.startswith("/"):
                    raise ValueError(f"ZIP contains unsafe filename: {name}")

            logger.info(f"ZIP contains {len(file_list)} files: {file_list}")

            # Metadata is optional but recommended for version checking
            metadata = {}
            if "_metadata.csv" in file_list:
                metadata = _parse_metadata(zip_file.read("_metadata.csv").decode('utf-8'))
                _validate_metadata(metadata)
            else:
                logger.warning("No _metadata.csv found, skipping version check")

            # Import counts. Every `_import_*` helper below runs a per-row
            # try/except (one bad row must not abort the whole restore), so
            # `count` alone can silently under-report a ZIP without ever
            # telling the caller anything was dropped. `_record` also writes a
            # `<name>_failed` key whenever rows actually failed, so a GDPR
            # restore response can say so instead of reporting `workout_logs:
            # 47` with no sign that 3 of 50 rows never landed.
            counts: Dict[str, int] = {}

            def _record(name: str, count: int, failed: int) -> None:
                counts[name] = count
                if failed:
                    counts[f"{name}_failed"] = failed

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
                count, failed = _import_body_metrics(db, user_id, metrics)
                _record("body_metrics", count, failed)

            # 3. Import workouts (need to map IDs)
            if "workouts.csv" in file_list:
                workouts = _parse_csv(zip_file.read("workouts.csv").decode('utf-8'))
                count, workout_id_map, failed = _import_workouts(db, user_id, workouts)
                _record("workouts", count, failed)

            # 4. Import workout logs (need to map workout IDs)
            if "workout_logs.csv" in file_list:
                logs = _parse_csv(zip_file.read("workout_logs.csv").decode('utf-8'))
                # Pre-parse exercise_sets.csv (if present) just to learn, per
                # OLD log_id, the set of distinct exercises it contains. The
                # workout_logs export has no `exercises_completed` column of
                # its own (see `_export_workout_logs` in data_export.py) — the
                # per-set rows are the only place that ground truth lives.
                # This is a read of the same bytes `_import_exercise_sets`
                # reads again below to do the actual per-set insert; nothing
                # is skipped either way.
                exercises_by_old_log_id: Dict[str, set] = {}
                if "exercise_sets.csv" in file_list:
                    for s in _parse_csv(zip_file.read("exercise_sets.csv").decode('utf-8')):
                        old_log_id = s.get("log_id")
                        ex_name = (s.get("exercise_name") or "").strip()
                        if old_log_id and ex_name:
                            exercises_by_old_log_id.setdefault(old_log_id, set()).add(ex_name.lower())
                count, log_id_map, failed = _import_workout_logs(
                    db, user_id, logs, workout_id_map, exercises_by_old_log_id
                )
                _record("workout_logs", count, failed)

            # 5. Import exercise sets (need to map log IDs)
            if "exercise_sets.csv" in file_list:
                sets = _parse_csv(zip_file.read("exercise_sets.csv").decode('utf-8'))
                count, failed = _import_exercise_sets(db, user_id, sets, log_id_map)
                _record("exercise_sets", count, failed)

            # 6. Import strength records
            if "strength_records.csv" in file_list:
                records = _parse_csv(zip_file.read("strength_records.csv").decode('utf-8'))
                count, failed = _import_strength_records(db, user_id, records)
                _record("strength_records", count, failed)

            # 7. Import achievements
            if "achievements.csv" in file_list:
                achievements = _parse_csv(zip_file.read("achievements.csv").decode('utf-8'))
                count, failed = _import_achievements(db, user_id, achievements)
                _record("achievements", count, failed)

            # 8. Import streaks
            if "streaks.csv" in file_list:
                streaks = _parse_csv(zip_file.read("streaks.csv").decode('utf-8'))
                count, failed = _import_streaks(db, user_id, streaks)
                _record("streaks", count, failed)

    except zipfile.BadZipFile:
        raise ValueError("Invalid ZIP file format")
    except Exception as e:
        logger.error(f"Import error: {e}", exc_info=True)
        raise

    logger.info(f"Data import complete for user {truncated_uid}: {counts}")
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
        except (ValueError, TypeError) as e:
            logger.debug(f"Failed to parse height_cm: {e}")

    if profile.get("weight_kg"):
        try:
            update_data["weight_kg"] = float(profile["weight_kg"])
        except (ValueError, TypeError) as e:
            logger.debug(f"Failed to parse weight_kg: {e}")

    if profile.get("target_weight_kg"):
        try:
            update_data["target_weight_kg"] = float(profile["target_weight_kg"])
        except (ValueError, TypeError) as e:
            logger.debug(f"Failed to parse target_weight_kg: {e}")

    if profile.get("age"):
        try:
            update_data["age"] = int(profile["age"])
        except (ValueError, TypeError) as e:
            logger.debug(f"Failed to parse age: {e}")

    if profile.get("gender"):
        update_data["gender"] = profile["gender"]

    if profile.get("activity_level"):
        update_data["activity_level"] = profile["activity_level"]

    if update_data:
        db.update_user(user_id, update_data)
        logger.debug(f"Updated profile: {list(update_data.keys())}")


def _import_body_metrics(db, user_id: str, metrics: List[Dict[str, str]]) -> tuple:
    """Import body metrics. Returns (count, failed)."""
    count = 0
    failed = 0
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
                    except (ValueError, TypeError) as e:
                        logger.debug(f"Failed to parse metric {field}: {e}")

            db.create_user_metrics(data)
            count += 1
        except Exception as e:
            failed += 1
            logger.warning(f"Failed to import metric: {e}", exc_info=True)

    return count, failed


def _import_workouts(db, user_id: str, workouts: List[Dict[str, str]]) -> tuple:
    """Import workouts. Returns (count, id_map, failed)."""
    count = 0
    failed = 0
    id_map = {}

    for w in workouts:
        try:
            old_id = w.get("workout_id")

            # Parse exercises JSON
            exercises_json = w.get("exercises_json", "[]")
            try:
                exercises = json.loads(exercises_json)
            except (json.JSONDecodeError, TypeError) as e:
                logger.debug(f"Failed to parse exercises JSON: {e}")
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
                except (ValueError, TypeError) as e:
                    logger.debug(f"Failed to parse duration: {e}")
                    data["duration_minutes"] = 45

            result = db.create_workout(data)
            if result:
                new_id = result["id"]
                if old_id:
                    id_map[old_id] = new_id
                count += 1
        except Exception as e:
            failed += 1
            logger.warning(f"Failed to import workout: {e}", exc_info=True)

    return count, id_map, failed


# Real `workout_logs.status` values (migration 137's CHECK constraint).
_VALID_WORKOUT_LOG_STATUSES = {"completed", "in_progress", "abandoned", "paused"}


def _import_workout_logs(
    db,
    user_id: str,
    logs: List[Dict[str, str]],
    workout_id_map: Dict[str, str],
    exercises_by_old_log_id: Optional[Dict[str, set]] = None,
) -> tuple:
    """Import workout logs. Returns (count, id_map, failed).

    `exercises_by_old_log_id` (optional) maps an OLD `log_id` from the export
    to the set of distinct exercise names logged against it, pre-computed by
    the caller from `exercise_sets.csv` — see `import_user_data`. Used to fill
    `exercises_completed`, which (like `status` and `duration_minutes` below)
    has no column of its own in the workout_logs CSV export.
    """
    count = 0
    failed = 0
    id_map = {}
    exercises_by_old_log_id = exercises_by_old_log_id or {}

    for log in logs:
        try:
            old_id = log.get("log_id")
            old_workout_id = log.get("workout_id")

            # Map to new workout ID if available
            new_workout_id = workout_id_map.get(old_workout_id) if old_workout_id else None

            data = {
                "user_id": user_id,
                "workout_id": new_workout_id,
                "completed_at": log.get("completed_at") or datetime.utcnow().isoformat(),
                "sets_json": [],  # Will be populated from exercise_sets
                # `workout_logs` has no `workout_name` column — writing it made
                # PostgREST reject the ENTIRE insert (42703), so every imported
                # workout log silently failed (the except below only warned).
                # The name is still worth keeping for imported logs whose
                # workout_id didn't map, so it goes in the metadata JSONB.
                "metadata": {
                    **(log.get("metadata") or {}),
                    "workout_name": log.get("workout_name", "Imported Workout"),
                    "imported": True,
                },
            }

            if log.get("total_time_seconds"):
                try:
                    data["total_time_seconds"] = int(log["total_time_seconds"])
                except (ValueError, TypeError) as e:
                    logger.debug(f"Failed to parse total_time: {e}")

            # `duration_minutes` is a real workout_logs column that the CSV
            # export (`_export_workout_logs`) does not write directly — but
            # `total_time_seconds`, the SAME session's duration, IS exported.
            # Derive minutes from it rather than leaving the column unset. A
            # future export that adds a genuine `duration_minutes` field wins
            # if present.
            if log.get("duration_minutes"):
                try:
                    data["duration_minutes"] = int(float(log["duration_minutes"]))
                except (ValueError, TypeError) as e:
                    logger.debug(f"Failed to parse duration_minutes: {e}")
            elif "total_time_seconds" in data:
                data["duration_minutes"] = data["total_time_seconds"] // 60

            # `exercises_completed` — same story: no column in the export, but
            # the caller-supplied per-log exercise-name set (built from
            # exercise_sets.csv, the ground truth for what was actually
            # logged) tells us the real count.
            if old_id in exercises_by_old_log_id:
                data["exercises_completed"] = len(exercises_by_old_log_id[old_id])

            # `status` — restoring a GDPR export must not silently downgrade
            # every historical session to 'in_progress'. Migration 2390
            # flipped the column DEFAULT from 'completed' to 'in_progress', so
            # a writer that omits `status` (as this importer always has) now
            # gets the OPPOSITE of the pre-2390 default — every restored log
            # becomes invisible to every status='completed' reader (progress,
            # streaks, PRs), defeating the entire point of a restore path.
            # The export has no genuine `status` column either (honor one if
            # a future export adds it); the closest available signal is
            # `exit_reason`, which today always reads "completed" because
            # `workout_logs` itself has no exit_reason column and
            # `_export_workout_logs`'s `log.get("exit_reason", "completed")`
            # always falls through to that default. A row that made it into
            # the export at all completed the finish/finalize flow, so a
            # missing/"completed" exit_reason means completed; any other
            # value (an early-exit reason like "too_tired"/"out_of_time")
            # means the session was abandoned, not left "in progress" forever.
            raw_status = (log.get("status") or "").strip().lower()
            if raw_status in _VALID_WORKOUT_LOG_STATUSES:
                data["status"] = raw_status
            else:
                exit_reason = (log.get("exit_reason") or "").strip().lower()
                data["status"] = (
                    "completed"
                    if exit_reason in ("", "completed", "complete", "finished")
                    else "abandoned"
                )

            result = db.create_workout_log(data)
            if result:
                new_id = result["id"]
                if old_id:
                    id_map[old_id] = new_id
                count += 1
        except Exception as e:
            failed += 1
            logger.warning(f"Failed to import workout log: {e}", exc_info=True)

    return count, id_map, failed


def _import_exercise_sets(db, user_id: str, sets: List[Dict[str, str]], log_id_map: Dict[str, str]) -> tuple:
    """Import exercise sets (performance logs). Returns (count, failed)."""
    count = 0
    failed = 0

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
                except (ValueError, TypeError) as e:
                    logger.debug(f"Failed to parse set_number: {e}")
                    data["set_number"] = 1

            if s.get("reps_completed"):
                try:
                    data["reps_completed"] = int(s["reps_completed"])
                except (ValueError, TypeError) as e:
                    logger.debug(f"Failed to parse reps: {e}")

            if s.get("weight_kg"):
                try:
                    data["weight_kg"] = float(s["weight_kg"])
                except (ValueError, TypeError) as e:
                    logger.debug(f"Failed to parse set weight: {e}")

            if s.get("rpe"):
                try:
                    data["rpe"] = float(s["rpe"])
                except (ValueError, TypeError) as e:
                    logger.debug(f"Failed to parse RPE: {e}")

            data["is_completed"] = s.get("is_completed", "true").lower() == "true"

            if s.get("notes"):
                data["notes"] = s["notes"]

            db.create_performance_log(data)
            count += 1
        except Exception as e:
            failed += 1
            logger.warning(f"Failed to import exercise set: {e}", exc_info=True)

    return count, failed


def _import_strength_records(db, user_id: str, records: List[Dict[str, str]]) -> tuple:
    """Import strength records. Returns (count, failed)."""
    count = 0
    failed = 0

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
                except (ValueError, TypeError) as e:
                    logger.debug(f"Failed to parse record weight: {e}")

            if r.get("reps"):
                try:
                    data["reps"] = int(r["reps"])
                except (ValueError, TypeError) as e:
                    logger.debug(f"Failed to parse record reps: {e}")

            if r.get("estimated_1rm"):
                try:
                    data["estimated_1rm"] = float(r["estimated_1rm"])
                except (ValueError, TypeError) as e:
                    logger.debug(f"Failed to parse estimated 1RM: {e}")

            data["is_pr"] = r.get("is_pr", "false").lower() == "true"

            db.create_strength_record(data)
            count += 1
        except Exception as e:
            failed += 1
            logger.warning(f"Failed to import strength record: {e}", exc_info=True)

    return count, failed


def _import_achievements(db, user_id: str, achievements: List[Dict[str, str]]) -> tuple:
    """Import achievements by looking up achievement types. Returns (count, failed)."""
    count = 0
    failed = 0

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
                except (ValueError, TypeError) as e:
                    logger.debug(f"Failed to parse trigger_value: {e}")

            db.client.table("user_achievements").insert(data).execute()
            count += 1
        except Exception as e:
            failed += 1
            logger.warning(f"Failed to import achievement: {e}", exc_info=True)

    return count, failed


def _import_streaks(db, user_id: str, streaks: List[Dict[str, str]]) -> tuple:
    """Import streaks (upsert - update if exists). Returns (count, failed)."""
    count = 0
    failed = 0

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
            failed += 1
            logger.warning(f"Failed to import streak: {e}", exc_info=True)

    return count, failed
