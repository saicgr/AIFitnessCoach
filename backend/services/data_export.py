"""
Data Export Service for FitWiz.

Exports user data to CSV, JSON, Excel, and Parquet formats.
Supports export for data portability and re-import after account deletion.
"""
import csv
import io
import json
import time
import zipfile
from datetime import datetime
from typing import Dict, List, Any, Optional

import pandas as pd

from core.supabase_db import get_supabase_db
from core.logger import get_logger

logger = get_logger(__name__)

# Export version for compatibility checking on import
EXPORT_VERSION = "1.0"
APP_VERSION = "1.0.0"


def export_user_data(
    user_id: str,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
) -> bytes:
    """
    Export all user data to a ZIP file containing CSV files.

    Args:
        user_id: The user ID to export data for
        start_date: Optional start date filter (YYYY-MM-DD format)
        end_date: Optional end date filter (YYYY-MM-DD format)

    Returns the ZIP file as bytes.
    """
    total_start = time.time()
    logger.info(f"🔄 Starting data export for user: {user_id}, date_range: {start_date} to {end_date}")

    db = get_supabase_db()

    # Verify user exists
    t = time.time()
    user = db.get_user(user_id)
    logger.info(f"⏱️ get_user: {time.time() - t:.2f}s")
    if not user:
        raise ValueError(f"User {user_id} not found")

    # Run queries sequentially (ThreadPoolExecutor has issues with Supabase on cold starts)
    # Sequential is actually fast enough (~1-2s total) and more reliable
    t = time.time()
    results = {}

    try:
        logger.info("📊 Fetching metrics...")
        results["metrics"] = _get_filtered_metrics(db, user_id, start_date, end_date)
        logger.info(f"  ✓ metrics: {len(results['metrics'])} rows")
    except Exception as e:
        logger.error(f"Error fetching metrics: {e}")
        results["metrics"] = []

    try:
        logger.info("📊 Fetching workouts...")
        results["workouts"] = _get_filtered_workouts(db, user_id, start_date, end_date)
        logger.info(f"  ✓ workouts: {len(results['workouts'])} rows")
    except Exception as e:
        logger.error(f"Error fetching workouts: {e}")
        results["workouts"] = []

    try:
        logger.info("📊 Fetching workout_logs...")
        results["workout_logs"] = _get_filtered_workout_logs(db, user_id, start_date, end_date)
        logger.info(f"  ✓ workout_logs: {len(results['workout_logs'])} rows")
    except Exception as e:
        logger.error(f"Error fetching workout_logs: {e}")
        results["workout_logs"] = []

    try:
        logger.info("📊 Fetching performance_logs...")
        results["performance_logs"] = _get_filtered_performance_logs(db, user_id, start_date, end_date)
        logger.info(f"  ✓ performance_logs: {len(results['performance_logs'])} rows")
    except Exception as e:
        logger.error(f"Error fetching performance_logs: {e}")
        results["performance_logs"] = []

    try:
        logger.info("📊 Fetching strength_records...")
        results["strength_records"] = _get_filtered_strength_records(db, user_id, start_date, end_date)
        logger.info(f"  ✓ strength_records: {len(results['strength_records'])} rows")
    except Exception as e:
        logger.error(f"Error fetching strength_records: {e}")
        results["strength_records"] = []

    try:
        logger.info("📊 Fetching achievements...")
        results["achievements"] = _get_filtered_achievements(db, user_id, start_date, end_date)
        logger.info(f"  ✓ achievements: {len(results['achievements'])} rows")
    except Exception as e:
        logger.error(f"Error fetching achievements: {e}")
        results["achievements"] = []

    try:
        logger.info("📊 Fetching streaks...")
        results["streaks"] = _get_user_streaks(db, user_id)
        logger.info(f"  ✓ streaks: {len(results['streaks'])} rows")
    except Exception as e:
        logger.error(f"Error fetching streaks: {e}")
        results["streaks"] = []

    logger.info(f"⏱️ All queries completed in {time.time() - t:.2f}s")

    # Create in-memory ZIP file
    zip_buffer = io.BytesIO()

    with zipfile.ZipFile(zip_buffer, 'w', zipfile.ZIP_DEFLATED) as zip_file:
        export_counts = {}

        # 1. Profile data (always included, no date filter)
        profile_csv = _export_profile(user)
        zip_file.writestr("profile.csv", profile_csv)
        export_counts["profile"] = 1

        # 2. Body metrics
        metrics_csv = _export_body_metrics(results["metrics"])
        zip_file.writestr("body_metrics.csv", metrics_csv)
        export_counts["body_metrics"] = len(results["metrics"])

        # 3. Workouts
        workouts_csv = _export_workouts(results["workouts"])
        zip_file.writestr("workouts.csv", workouts_csv)
        export_counts["workouts"] = len(results["workouts"])

        # 4. Workout logs
        logs_csv = _export_workout_logs(results["workout_logs"])
        zip_file.writestr("workout_logs.csv", logs_csv)
        export_counts["workout_logs"] = len(results["workout_logs"])

        # 5. Performance logs (exercise sets)
        sets_csv = _export_exercise_sets(results["performance_logs"])
        zip_file.writestr("exercise_sets.csv", sets_csv)
        export_counts["exercise_sets"] = len(results["performance_logs"])

        # 6. Strength records
        strength_csv = _export_strength_records(results["strength_records"])
        zip_file.writestr("strength_records.csv", strength_csv)
        export_counts["strength_records"] = len(results["strength_records"])

        # 7. Achievements
        achievements_csv = _export_achievements(results["achievements"])
        zip_file.writestr("achievements.csv", achievements_csv)
        export_counts["achievements"] = len(results["achievements"])

        # 8. Streaks
        streaks_csv = _export_streaks(results["streaks"])
        zip_file.writestr("streaks.csv", streaks_csv)
        export_counts["streaks"] = len(results["streaks"])

        # 9. Metadata file (for import validation)
        metadata_csv = _export_metadata(user_id, export_counts, start_date, end_date)
        zip_file.writestr("_metadata.csv", metadata_csv)

    logger.info(f"✅ Data export complete for user {user_id} in {time.time() - total_start:.2f}s: {export_counts}")

    # Get the ZIP file bytes
    zip_buffer.seek(0)
    return zip_buffer.getvalue()


def _query_all_data(user_id: str, start_date: Optional[str], end_date: Optional[str]) -> tuple:
    """
    Shared query logic for all export formats.
    Returns (user, results) tuple.
    """
    db = get_supabase_db()

    user = db.get_user(user_id)
    if not user:
        raise ValueError(f"User {user_id} not found")

    results = {}
    queries = [
        ("metrics", lambda: _get_filtered_metrics(db, user_id, start_date, end_date)),
        ("workouts", lambda: _get_filtered_workouts(db, user_id, start_date, end_date)),
        ("workout_logs", lambda: _get_filtered_workout_logs(db, user_id, start_date, end_date)),
        ("performance_logs", lambda: _get_filtered_performance_logs(db, user_id, start_date, end_date)),
        ("strength_records", lambda: _get_filtered_strength_records(db, user_id, start_date, end_date)),
        ("achievements", lambda: _get_filtered_achievements(db, user_id, start_date, end_date)),
        ("streaks", lambda: _get_user_streaks(db, user_id)),
    ]

    for key, query_fn in queries:
        try:
            results[key] = query_fn()
        except Exception as e:
            logger.error(f"Error fetching {key}: {e}")
            results[key] = []

    return user, results


def export_user_data_json(
    user_id: str,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
) -> dict:
    """
    Export all user data as a JSON-serializable dict.

    Returns dict with all data categories as lists of dicts.
    """
    total_start = time.time()
    logger.info(f"Starting JSON export for user: {user_id}")

    user, results = _query_all_data(user_id, start_date, end_date)

    # Parse JSONB fields in user profile
    for field in ("goals", "equipment", "active_injuries"):
        val = user.get(field, [])
        if isinstance(val, str):
            try:
                user[field] = json.loads(val)
            except Exception:
                user[field] = []

    export = {
        "profile": user,
        "body_metrics": results["metrics"],
        "workouts": results["workouts"],
        "workout_logs": results["workout_logs"],
        "exercise_sets": results["performance_logs"],
        "strength_records": results["strength_records"],
        "achievements": results["achievements"],
        "streaks": results["streaks"],
        "metadata": {
            "export_version": EXPORT_VERSION,
            "exported_at": datetime.utcnow().isoformat() + "Z",
            "app_version": APP_VERSION,
            "original_user_id": user_id,
            "filter_start_date": start_date,
            "filter_end_date": end_date,
        },
    }

    logger.info(f"JSON export complete for user {user_id} in {time.time() - total_start:.2f}s")
    return export


def export_user_data_excel(
    user_id: str,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
) -> bytes:
    """
    Export all user data as an Excel (.xlsx) file with one sheet per data type.

    Returns .xlsx bytes.
    """
    total_start = time.time()
    logger.info(f"Starting Excel export for user: {user_id}")

    user, results = _query_all_data(user_id, start_date, end_date)

    output = io.BytesIO()
    with pd.ExcelWriter(output, engine="openpyxl") as writer:
        # Profile
        pd.DataFrame([user]).to_excel(writer, sheet_name="profile", index=False)

        # Data categories
        sheet_map = {
            "body_metrics": results["metrics"],
            "workouts": results["workouts"],
            "workout_logs": results["workout_logs"],
            "exercise_sets": results["performance_logs"],
            "strength_records": results["strength_records"],
            "achievements": results["achievements"],
            "streaks": results["streaks"],
        }

        for sheet_name, data in sheet_map.items():
            df = pd.DataFrame(data) if data else pd.DataFrame()
            df.to_excel(writer, sheet_name=sheet_name, index=False)

    logger.info(f"Excel export complete for user {user_id} in {time.time() - total_start:.2f}s")
    output.seek(0)
    return output.getvalue()


def export_user_data_parquet(
    user_id: str,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
) -> bytes:
    """
    Export all user data as a ZIP of Parquet files (one per data type).

    Returns ZIP bytes.
    """
    total_start = time.time()
    logger.info(f"Starting Parquet export for user: {user_id}")

    user, results = _query_all_data(user_id, start_date, end_date)

    zip_buffer = io.BytesIO()
    with zipfile.ZipFile(zip_buffer, "w", zipfile.ZIP_DEFLATED) as zf:
        # Profile
        df = pd.DataFrame([user])
        buf = io.BytesIO()
        df.to_parquet(buf, engine="pyarrow", index=False)
        zf.writestr("profile.parquet", buf.getvalue())

        # Data categories
        file_map = {
            "body_metrics": results["metrics"],
            "workouts": results["workouts"],
            "workout_logs": results["workout_logs"],
            "exercise_sets": results["performance_logs"],
            "strength_records": results["strength_records"],
            "achievements": results["achievements"],
            "streaks": results["streaks"],
        }

        for name, data in file_map.items():
            df = pd.DataFrame(data) if data else pd.DataFrame()
            buf = io.BytesIO()
            df.to_parquet(buf, engine="pyarrow", index=False)
            zf.writestr(f"{name}.parquet", buf.getvalue())

    logger.info(f"Parquet export complete for user {user_id} in {time.time() - total_start:.2f}s")
    zip_buffer.seek(0)
    return zip_buffer.getvalue()


# ==================== DATE-FILTERED QUERY FUNCTIONS ====================


def _get_filtered_metrics(db, user_id: str, start_date: Optional[str], end_date: Optional[str]) -> List[Dict[str, Any]]:
    """Get body metrics filtered by date range."""
    query = db.client.table("user_metrics").select("*").eq("user_id", user_id)

    if start_date:
        query = query.gte("recorded_at", start_date)
    if end_date:
        query = query.lte("recorded_at", end_date + "T23:59:59Z")

    result = query.order("recorded_at", desc=True).limit(500).execute()
    return result.data or []


def _get_filtered_workouts(db, user_id: str, start_date: Optional[str], end_date: Optional[str]) -> List[Dict[str, Any]]:
    """Get workouts filtered by scheduled_date."""
    query = db.client.table("workouts").select("*").eq("user_id", user_id)

    if start_date:
        query = query.gte("scheduled_date", start_date)
    if end_date:
        query = query.lte("scheduled_date", end_date)

    result = query.order("scheduled_date", desc=True).limit(500).execute()
    return result.data or []


def _get_filtered_workout_logs(db, user_id: str, start_date: Optional[str], end_date: Optional[str]) -> List[Dict[str, Any]]:
    """Get workout logs filtered by completed_at."""
    query = db.client.table("workout_logs").select("*").eq("user_id", user_id)

    if start_date:
        query = query.gte("completed_at", start_date)
    if end_date:
        query = query.lte("completed_at", end_date + "T23:59:59Z")

    result = query.order("completed_at", desc=True).limit(500).execute()
    return result.data or []


def _get_filtered_performance_logs(db, user_id: str, start_date: Optional[str], end_date: Optional[str]) -> List[Dict[str, Any]]:
    """Get performance logs filtered by recorded_at."""
    query = db.client.table("performance_logs").select("*").eq("user_id", user_id)

    if start_date:
        query = query.gte("recorded_at", start_date)
    if end_date:
        query = query.lte("recorded_at", end_date + "T23:59:59Z")

    result = query.order("recorded_at", desc=True).limit(5000).execute()
    return result.data or []


def _get_filtered_strength_records(db, user_id: str, start_date: Optional[str], end_date: Optional[str]) -> List[Dict[str, Any]]:
    """Get strength records filtered by achieved_at."""
    query = db.client.table("strength_records").select("*").eq("user_id", user_id)

    if start_date:
        query = query.gte("achieved_at", start_date)
    if end_date:
        query = query.lte("achieved_at", end_date + "T23:59:59Z")

    result = query.order("achieved_at", desc=True).limit(500).execute()
    return result.data or []


def _get_filtered_achievements(db, user_id: str, start_date: Optional[str], end_date: Optional[str]) -> List[Dict[str, Any]]:
    """Get user achievements filtered by earned_at."""
    query = db.client.table("user_achievements").select(
        "*, achievement_types(name, category, tier)"
    ).eq("user_id", user_id)

    if start_date:
        query = query.gte("earned_at", start_date)
    if end_date:
        query = query.lte("earned_at", end_date + "T23:59:59Z")

    result = query.execute()
    return result.data or []


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
        except Exception as e:
            logger.debug(f"Failed to parse goals JSON during export: {e}")
            goals = []

    equipment = user.get("equipment", [])
    if isinstance(equipment, str):
        try:
            equipment = json.loads(equipment)
        except Exception as e:
            logger.debug(f"Failed to parse equipment JSON during export: {e}")
            equipment = []

    active_injuries = user.get("active_injuries", [])
    if isinstance(active_injuries, str):
        try:
            active_injuries = json.loads(active_injuries)
        except Exception as e:
            logger.debug(f"Failed to parse active_injuries JSON during export: {e}")
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
            except Exception as e:
                logger.debug(f"Failed to parse sets_json during workout log export: {e}")
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


def _export_metadata(
    user_id: str,
    counts: Dict[str, int],
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
) -> str:
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

    # Date filter info
    if start_date:
        writer.writerow(["filter_start_date", start_date])
    if end_date:
        writer.writerow(["filter_end_date", end_date])

    # Include counts for each data type
    for key, count in counts.items():
        writer.writerow([f"total_{key}", str(count)])

    return output.getvalue()


def export_workout_logs_text(
    user_id: str,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
) -> str:
    """
    Export workout logs as formatted plain text.

    Args:
        user_id: The user ID to export data for
        start_date: Optional start date filter (YYYY-MM-DD format)
        end_date: Optional end date filter (YYYY-MM-DD format)

    Returns the formatted text string.
    """
    logger.info(f"Starting text export for user: {user_id}, date_range: {start_date} to {end_date}")

    db = get_supabase_db()

    # Verify user exists
    user = db.get_user(user_id)
    if not user:
        raise ValueError(f"User {user_id} not found")

    # Get workout logs
    workout_logs = _get_filtered_workout_logs(db, user_id, start_date, end_date)

    # Get performance logs (exercise sets)
    performance_logs = _get_filtered_performance_logs(db, user_id, start_date, end_date)

    # Build a lookup of performance logs by workout_log_id
    perf_by_log: Dict[str, List[Dict[str, Any]]] = {}
    for perf in performance_logs:
        log_id = perf.get("workout_log_id")
        if log_id:
            if log_id not in perf_by_log:
                perf_by_log[log_id] = []
            perf_by_log[log_id].append(perf)

    # Sort performance logs by set number within each workout
    for log_id in perf_by_log:
        perf_by_log[log_id].sort(key=lambda x: (x.get("exercise_name", ""), x.get("set_number", 0)))

    # Build the text output
    lines = []

    # Header
    generated_date = datetime.utcnow().strftime("%Y-%m-%d")
    period_start = start_date if start_date else "All time"
    period_end = end_date if end_date else generated_date

    lines.append("=" * 68)
    lines.append("AI FITNESS COACH - WORKOUT LOG EXPORT")
    lines.append(f"Generated: {generated_date}")
    lines.append(f"Period: {period_start} to {period_end}")
    lines.append("=" * 68)
    lines.append("")

    if not workout_logs:
        lines.append("No workout logs found for this period.")
        lines.append("")
        return "\n".join(lines)

    # Sort workout logs by date (most recent first is already done by query,
    # but let's reverse for chronological order in export)
    workout_logs_sorted = sorted(
        workout_logs,
        key=lambda x: x.get("completed_at", ""),
        reverse=False  # Oldest first for chronological reading
    )

    for log in workout_logs_sorted:
        log_id = log.get("id", "")
        workout_name = log.get("workout_name", "Workout")
        completed_at = log.get("completed_at", "")
        total_time_seconds = log.get("total_time_seconds", 0)
        notes = log.get("notes", "")

        # Parse the completion date
        workout_date_str = "Unknown date"
        if completed_at:
            try:
                if "T" in completed_at:
                    dt = datetime.fromisoformat(completed_at.replace("Z", "+00:00"))
                else:
                    dt = datetime.strptime(completed_at[:10], "%Y-%m-%d")
                workout_date_str = dt.strftime("%A, %B %d, %Y")
            except (ValueError, AttributeError):
                workout_date_str = completed_at[:10] if len(completed_at) >= 10 else completed_at

        # Calculate duration in minutes
        duration_minutes = (total_time_seconds // 60) if total_time_seconds else 0

        # Get performance logs for this workout
        perf_logs = perf_by_log.get(log_id, [])

        # Calculate totals
        total_sets = len(perf_logs)
        total_reps = sum(p.get("reps_completed", 0) or 0 for p in perf_logs)
        total_volume = sum(
            (p.get("weight_kg", 0) or 0) * (p.get("reps_completed", 0) or 0)
            for p in perf_logs
        )

        # Workout header
        lines.append("-" * 68)
        lines.append(f"WORKOUT: {workout_name}")
        lines.append(f"Date: {workout_date_str}")

        # Summary line
        summary_parts = []
        if duration_minutes > 0:
            summary_parts.append(f"Duration: {duration_minutes} minutes")
        summary_parts.append(f"Total Sets: {total_sets}")
        summary_parts.append(f"Total Reps: {total_reps}")
        if total_volume > 0:
            summary_parts.append(f"Total Volume: {total_volume:.1f} kg")
        lines.append(" | ".join(summary_parts))
        lines.append("-" * 68)
        lines.append("")

        if not perf_logs:
            lines.append("   No exercise data recorded.")
            lines.append("")
        else:
            # Group by exercise name
            exercises: Dict[str, List[Dict[str, Any]]] = {}
            for p in perf_logs:
                ex_name = p.get("exercise_name", "Unknown Exercise")
                if ex_name not in exercises:
                    exercises[ex_name] = []
                exercises[ex_name].append(p)

            exercise_num = 0
            for ex_name, sets in exercises.items():
                exercise_num += 1
                lines.append(f"{exercise_num}. {ex_name}")

                for s in sets:
                    set_num = s.get("set_number", 0)
                    reps = s.get("reps_completed", 0)
                    weight = s.get("weight_kg")
                    rpe = s.get("rpe")
                    set_notes = s.get("notes", "")

                    # Build set line
                    set_parts = []
                    if weight is not None and weight > 0:
                        set_parts.append(f"{weight} kg")
                    set_parts.append(f"{reps} reps")
                    if rpe is not None:
                        set_parts.append(f"(RPE {rpe})")

                    set_line = f"   Set {set_num}: " + " x ".join(set_parts[:2])
                    if len(set_parts) > 2:
                        set_line += f" {set_parts[2]}"

                    if set_notes:
                        set_line += f" - {set_notes}"

                    lines.append(set_line)

                lines.append("")

        # Workout notes
        if notes:
            lines.append(f"Notes: {notes}")
            lines.append("")

    # Footer
    lines.append("=" * 68)
    lines.append(f"Total Workouts: {len(workout_logs)}")
    lines.append("=" * 68)

    logger.info(f"Text export complete for user {user_id}: {len(workout_logs)} workouts")

    return "\n".join(lines)
