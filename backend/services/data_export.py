"""
Data Export Service for AI Fitness Coach.

Exports user data to CSV files packaged in a ZIP archive.
Supports export for data portability and re-import after account deletion.
"""
import csv
import io
import json
import zipfile
from datetime import datetime
from typing import Dict, List, Any, Optional

from core.supabase_db import get_supabase_db
from core.logger import get_logger

logger = get_logger(__name__)

# Export version for compatibility checking on import
EXPORT_VERSION = "1.0"
APP_VERSION = "1.0.0"


def export_user_data(user_id: str) -> bytes:
    """
    Export all user data to a ZIP file containing CSV files.

    Returns the ZIP file as bytes.
    """
    logger.info(f"Starting data export for user: {user_id}")

    db = get_supabase_db()

    # Verify user exists
    user = db.get_user(user_id)
    if not user:
        raise ValueError(f"User {user_id} not found")

    # Create in-memory ZIP file
    zip_buffer = io.BytesIO()

    with zipfile.ZipFile(zip_buffer, 'w', zipfile.ZIP_DEFLATED) as zip_file:
        # Export each data type
        export_counts = {}

        # 1. Profile data
        profile_csv = _export_profile(user)
        zip_file.writestr("profile.csv", profile_csv)
        export_counts["profile"] = 1

        # 2. Body metrics
        metrics = db.list_user_metrics(user_id, limit=10000)
        metrics_csv = _export_body_metrics(metrics)
        zip_file.writestr("body_metrics.csv", metrics_csv)
        export_counts["body_metrics"] = len(metrics)

        # 3. Workouts (including non-current for history)
        workouts = _get_all_workouts(db, user_id)
        workouts_csv = _export_workouts(workouts)
        zip_file.writestr("workouts.csv", workouts_csv)
        export_counts["workouts"] = len(workouts)

        # 4. Workout logs
        workout_logs = db.list_workout_logs(user_id, limit=10000)
        logs_csv = _export_workout_logs(workout_logs)
        zip_file.writestr("workout_logs.csv", logs_csv)
        export_counts["workout_logs"] = len(workout_logs)

        # 5. Performance logs (exercise sets)
        performance_logs = db.list_performance_logs(user_id, limit=100000)
        sets_csv = _export_exercise_sets(performance_logs)
        zip_file.writestr("exercise_sets.csv", sets_csv)
        export_counts["exercise_sets"] = len(performance_logs)

        # 6. Strength records
        strength_records = db.list_strength_records(user_id, limit=10000)
        strength_csv = _export_strength_records(strength_records)
        zip_file.writestr("strength_records.csv", strength_csv)
        export_counts["strength_records"] = len(strength_records)

        # 7. User achievements
        achievements = _get_user_achievements(db, user_id)
        achievements_csv = _export_achievements(achievements)
        zip_file.writestr("achievements.csv", achievements_csv)
        export_counts["achievements"] = len(achievements)

        # 8. User streaks
        streaks = _get_user_streaks(db, user_id)
        streaks_csv = _export_streaks(streaks)
        zip_file.writestr("streaks.csv", streaks_csv)
        export_counts["streaks"] = len(streaks)

        # 9. Metadata file (for import validation)
        metadata_csv = _export_metadata(user_id, export_counts)
        zip_file.writestr("_metadata.csv", metadata_csv)

    logger.info(f"Data export complete for user {user_id}: {export_counts}")

    # Get the ZIP file bytes
    zip_buffer.seek(0)
    return zip_buffer.getvalue()


def _export_profile(user: Dict[str, Any]) -> str:
    """Export user profile to CSV string."""
    output = io.StringIO()
    writer = csv.writer(output)

    # Header
    writer.writerow([
        "name", "email", "fitness_level", "goals", "equipment",
        "height_cm", "weight_kg", "target_weight_kg", "age", "gender",
        "activity_level", "active_injuries"
    ])

    # Parse JSONB fields
    goals = user.get("goals", [])
    if isinstance(goals, str):
        try:
            goals = json.loads(goals)
        except:
            goals = []

    equipment = user.get("equipment", [])
    if isinstance(equipment, str):
        try:
            equipment = json.loads(equipment)
        except:
            equipment = []

    active_injuries = user.get("active_injuries", [])
    if isinstance(active_injuries, str):
        try:
            active_injuries = json.loads(active_injuries)
        except:
            active_injuries = []

    # Data row
    writer.writerow([
        user.get("name", ""),
        user.get("email", ""),
        user.get("fitness_level", ""),
        ",".join(goals) if isinstance(goals, list) else str(goals),
        ",".join(equipment) if isinstance(equipment, list) else str(equipment),
        user.get("height_cm", ""),
        user.get("weight_kg", ""),
        user.get("target_weight_kg", ""),
        user.get("age", ""),
        user.get("gender", ""),
        user.get("activity_level", ""),
        ",".join(active_injuries) if isinstance(active_injuries, list) else str(active_injuries),
    ])

    return output.getvalue()


def _export_body_metrics(metrics: List[Dict[str, Any]]) -> str:
    """Export body metrics history to CSV string."""
    output = io.StringIO()
    writer = csv.writer(output)

    # Header
    writer.writerow([
        "recorded_at", "weight_kg", "waist_cm", "hip_cm", "neck_cm",
        "body_fat_percent", "resting_heart_rate",
        "blood_pressure_systolic", "blood_pressure_diastolic"
    ])

    # Data rows
    for m in metrics:
        writer.writerow([
            m.get("recorded_at", ""),
            m.get("weight_kg", ""),
            m.get("waist_cm", ""),
            m.get("hip_cm", ""),
            m.get("neck_cm", ""),
            m.get("body_fat_measured", m.get("body_fat_calculated", "")),
            m.get("resting_heart_rate", ""),
            m.get("blood_pressure_systolic", ""),
            m.get("blood_pressure_diastolic", ""),
        ])

    return output.getvalue()


def _get_all_workouts(db, user_id: str) -> List[Dict[str, Any]]:
    """Get all workouts including superseded versions."""
    # Use direct query to get all workouts, not just current
    result = db.client.table("workouts").select("*").eq("user_id", user_id).order("scheduled_date", desc=True).execute()
    return result.data or []


def _export_workouts(workouts: List[Dict[str, Any]]) -> str:
    """Export workouts to CSV string."""
    output = io.StringIO()
    writer = csv.writer(output)

    # Header
    writer.writerow([
        "workout_id", "name", "type", "difficulty", "scheduled_date",
        "is_completed", "duration_minutes", "exercises_json"
    ])

    # Data rows
    for w in workouts:
        exercises_json = w.get("exercises_json", [])
        if isinstance(exercises_json, list):
            exercises_json = json.dumps(exercises_json)
        elif exercises_json is None:
            exercises_json = "[]"

        writer.writerow([
            w.get("id", ""),
            w.get("name", ""),
            w.get("type", ""),
            w.get("difficulty", ""),
            w.get("scheduled_date", ""),
            w.get("is_completed", False),
            w.get("duration_minutes", ""),
            exercises_json,
        ])

    return output.getvalue()


def _export_workout_logs(logs: List[Dict[str, Any]]) -> str:
    """Export workout logs to CSV string."""
    output = io.StringIO()
    writer = csv.writer(output)

    # Header
    writer.writerow([
        "log_id", "workout_id", "workout_name", "completed_at",
        "total_time_seconds", "total_sets", "total_reps", "exit_reason"
    ])

    # Data rows
    for log in logs:
        # Calculate totals from sets_json if available
        sets_json = log.get("sets_json", [])
        if isinstance(sets_json, str):
            try:
                sets_json = json.loads(sets_json)
            except:
                sets_json = []

        total_sets = len(sets_json) if sets_json else 0
        total_reps = sum(s.get("reps", 0) for s in sets_json) if sets_json else 0

        writer.writerow([
            log.get("id", ""),
            log.get("workout_id", ""),
            log.get("workout_name", ""),
            log.get("completed_at", ""),
            log.get("total_time_seconds", ""),
            total_sets,
            total_reps,
            log.get("exit_reason", "completed"),
        ])

    return output.getvalue()


def _export_exercise_sets(performance_logs: List[Dict[str, Any]]) -> str:
    """Export exercise sets (performance logs) to CSV string."""
    output = io.StringIO()
    writer = csv.writer(output)

    # Header
    writer.writerow([
        "log_id", "exercise_name", "set_number", "reps_completed",
        "weight_kg", "rpe", "is_completed", "notes"
    ])

    # Data rows
    for log in performance_logs:
        writer.writerow([
            log.get("workout_log_id", ""),
            log.get("exercise_name", ""),
            log.get("set_number", ""),
            log.get("reps_completed", ""),
            log.get("weight_kg", ""),
            log.get("rpe", ""),
            log.get("is_completed", True),
            log.get("notes", ""),
        ])

    return output.getvalue()


def _export_strength_records(records: List[Dict[str, Any]]) -> str:
    """Export strength records to CSV string."""
    output = io.StringIO()
    writer = csv.writer(output)

    # Header
    writer.writerow([
        "exercise_name", "weight_kg", "reps", "estimated_1rm", "achieved_at", "is_pr"
    ])

    # Data rows
    for r in records:
        writer.writerow([
            r.get("exercise_name", ""),
            r.get("weight_kg", ""),
            r.get("reps", ""),
            r.get("estimated_1rm", ""),
            r.get("achieved_at", ""),
            r.get("is_pr", False),
        ])

    return output.getvalue()


def _get_user_achievements(db, user_id: str) -> List[Dict[str, Any]]:
    """Get user achievements with achievement type details."""
    result = db.client.table("user_achievements").select(
        "*, achievement_types(name, category, tier)"
    ).eq("user_id", user_id).execute()
    return result.data or []


def _export_achievements(achievements: List[Dict[str, Any]]) -> str:
    """Export achievements to CSV string."""
    output = io.StringIO()
    writer = csv.writer(output)

    # Header
    writer.writerow([
        "achievement_name", "achievement_type", "tier", "earned_at", "trigger_value"
    ])

    # Data rows
    for a in achievements:
        achievement_type = a.get("achievement_types", {}) or {}
        writer.writerow([
            achievement_type.get("name", ""),
            achievement_type.get("category", ""),
            achievement_type.get("tier", ""),
            a.get("earned_at", ""),
            a.get("trigger_value", ""),
        ])

    return output.getvalue()


def _get_user_streaks(db, user_id: str) -> List[Dict[str, Any]]:
    """Get user streaks."""
    result = db.client.table("user_streaks").select("*").eq("user_id", user_id).execute()
    return result.data or []


def _export_streaks(streaks: List[Dict[str, Any]]) -> str:
    """Export streaks to CSV string."""
    output = io.StringIO()
    writer = csv.writer(output)

    # Header
    writer.writerow([
        "streak_type", "current_streak", "longest_streak",
        "last_activity_date", "streak_start_date"
    ])

    # Data rows
    for s in streaks:
        writer.writerow([
            s.get("streak_type", ""),
            s.get("current_streak", 0),
            s.get("longest_streak", 0),
            s.get("last_activity_date", ""),
            s.get("streak_start_date", ""),
        ])

    return output.getvalue()


def _export_metadata(user_id: str, counts: Dict[str, int]) -> str:
    """Export metadata for import validation."""
    output = io.StringIO()
    writer = csv.writer(output)

    # Header
    writer.writerow(["key", "value"])

    # Metadata rows
    writer.writerow(["export_version", EXPORT_VERSION])
    writer.writerow(["exported_at", datetime.utcnow().isoformat() + "Z"])
    writer.writerow(["app_version", APP_VERSION])
    writer.writerow(["original_user_id", user_id])

    # Include counts for each data type
    for key, count in counts.items():
        writer.writerow([f"total_{key}", str(count)])

    return output.getvalue()
