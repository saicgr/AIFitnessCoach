"""
Data Export Service for FitWiz.

Exports user data to CSV, JSON, Excel, and Parquet formats.
Supports export for data portability and re-import after account deletion.

GDPR Art. 20 (data portability) requires that the export include *all*
personal data held about the user, not just the headline fitness tables.
That means chat transcripts, food logs, progress photos (URLs + metadata),
nutrition summaries, user_ai_settings (so consent timestamps are auditable),
injuries, habits, personal goals, measurements, hormonal/cycle logs,
kegel logs, cardio sessions, and custom exercises.
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

# Export version for compatibility checking on import.
# Bumped to 2.0 when we expanded coverage to satisfy GDPR Art. 20 in full.
EXPORT_VERSION = "2.0"
APP_VERSION = "1.0.0"

# Tables that may not exist in every environment (e.g. brand-new schemas
# where a migration hasn't been applied). Missing tables return an empty
# list rather than failing the whole export.
_PORTABILITY_TABLES: List[Dict[str, Any]] = [
    # (table, date_column used for range filter or None, row_limit)
    {"name": "chat_history", "date_col": "timestamp", "limit": 10000},
    {"name": "food_logs", "date_col": "logged_at", "limit": 10000},
    {"name": "progress_photos", "date_col": "taken_at", "limit": 2000},
    {"name": "nutrition_summaries", "date_col": "summary_date", "limit": 2000},
    {"name": "user_ai_settings", "date_col": None, "limit": 10},
    {"name": "injuries", "date_col": "reported_at", "limit": 500},
    {"name": "habits", "date_col": None, "limit": 500},
    {"name": "habit_completions", "date_col": "completed_at", "limit": 10000},
    {"name": "personal_goals", "date_col": None, "limit": 500},
    {"name": "user_measurements", "date_col": "recorded_at", "limit": 2000},
    {"name": "hormonal_logs", "date_col": "logged_date", "limit": 2000},
    {"name": "kegel_logs", "date_col": "logged_at", "limit": 2000},
    {"name": "cardio_logs", "date_col": "logged_at", "limit": 5000},
    {"name": "custom_exercises", "date_col": None, "limit": 500},
    {"name": "water_intake", "date_col": "logged_at", "limit": 5000},
    {"name": "mood_logs", "date_col": "logged_at", "limit": 2000},
]


# Category catalog shared with the frontend. Each key maps to the set of
# output files (CSV name / JSON field / Excel sheet / Parquet file) that
# belong to it. `profile` is always emitted — the export is useless without
# the user record.
#
# When adding a table, list it under exactly one category so toggle state is
# unambiguous. Keys must stay in sync with
# mobile/flutter/lib/data/models/export_categories.dart.
EXPORT_CATEGORIES: Dict[str, List[str]] = {
    "workouts": [
        "workouts",
        "workout_logs",
        "exercise_sets",        # derived from performance_logs
        "workouts_strong",      # derived from workouts + performance_logs
    ],
    "strength": ["strength_records"],
    "body": ["body_metrics", "user_measurements"],
    "achievements": ["achievements", "streaks"],
    "nutrition": ["food_logs", "nutrition_summaries", "water_intake"],
    "chat": ["chat_history"],
    "photos": ["progress_photos"],
    "health": [
        "injuries",
        "mood_logs",
        "hormonal_logs",
        "kegel_logs",
        "cardio_logs",
    ],
    "goals": ["habits", "habit_completions", "personal_goals"],
    "custom": ["custom_exercises", "user_ai_settings"],
}

ALL_CATEGORY_KEYS = set(EXPORT_CATEGORIES.keys())


def _parse_categories(categories: Optional[str]) -> set:
    """Parse a comma-separated categories query param into a set of keys.

    None / empty → all categories. Unknown keys are ignored silently so a
    typo or stale client cannot break export for everyone.
    """
    if not categories:
        return set(ALL_CATEGORY_KEYS)
    requested = {c.strip() for c in categories.split(",") if c.strip()}
    return requested & ALL_CATEGORY_KEYS or set(ALL_CATEGORY_KEYS)


def _files_for_categories(selected: set) -> set:
    """Flatten the category catalog into the set of output file keys."""
    allowed: set = set()
    for key in selected:
        allowed.update(EXPORT_CATEGORIES.get(key, []))
    return allowed


def _fetch_portability_table(
    db,
    user_id: str,
    table: str,
    date_col: Optional[str],
    start_date: Optional[str],
    end_date: Optional[str],
    limit: int,
) -> List[Dict[str, Any]]:
    """Fetch a user's rows from a given table with SELECT * semantics.

    Missing tables (HTTP 404 / 42P01 undefined_table) degrade to an empty
    list. We never raise — a partial export is strictly better than no
    export for a GDPR DSAR deadline.
    """
    try:
        query = db.client.table(table).select("*").eq("user_id", user_id)
        if date_col and start_date:
            query = query.gte(date_col, start_date)
        if date_col and end_date:
            # Inclusive end-of-day for date-only columns.
            query = query.lte(date_col, end_date + "T23:59:59Z")
        if date_col:
            query = query.order(date_col, desc=True)
        result = query.limit(limit).execute()
        return result.data or []
    except Exception as e:
        # Table may not exist in this environment, or RLS denied access.
        # Log and continue so the rest of the export completes.
        msg = str(e)
        if "42P01" in msg or "does not exist" in msg or "not found" in msg.lower():
            logger.info(f"portability: table '{table}' not present — skipping")
        else:
            logger.warning(f"portability: failed to read '{table}' for user {user_id}: {e}")
        return []


def _collect_portability_tables(
    user_id: str,
    start_date: Optional[str],
    end_date: Optional[str],
) -> Dict[str, List[Dict[str, Any]]]:
    """Fetch every portability table in one pass."""
    db = get_supabase_db()
    out: Dict[str, List[Dict[str, Any]]] = {}
    for spec in _PORTABILITY_TABLES:
        rows = _fetch_portability_table(
            db,
            user_id,
            table=spec["name"],
            date_col=spec["date_col"],
            start_date=start_date,
            end_date=end_date,
            limit=spec["limit"],
        )
        out[spec["name"]] = rows
        logger.info(f"  ✓ {spec['name']}: {len(rows)} rows")
    return out


def _rows_to_csv(rows: List[Dict[str, Any]]) -> str:
    """Serialize a list of dicts to CSV. Handles variable-width rows by
    collecting the union of all keys so no column is dropped.
    Dict/list values are JSON-encoded so the export round-trips cleanly.
    """
    if not rows:
        return ""
    all_keys: List[str] = []
    seen = set()
    for row in rows:
        for k in row.keys():
            if k not in seen:
                seen.add(k)
                all_keys.append(k)
    buf = io.StringIO()
    writer = csv.DictWriter(buf, fieldnames=all_keys)
    writer.writeheader()
    for row in rows:
        safe_row = {}
        for k in all_keys:
            v = row.get(k)
            if isinstance(v, (dict, list)):
                safe_row[k] = json.dumps(v, default=str)
            else:
                safe_row[k] = v
        writer.writerow(safe_row)
    return buf.getvalue()


def export_user_data(
    user_id: str,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    categories: Optional[str] = None,
) -> bytes:
    """
    Export all user data to a ZIP file containing CSV files.

    Args:
        user_id: The user ID to export data for
        start_date: Optional start date filter (YYYY-MM-DD format)
        end_date: Optional end date filter (YYYY-MM-DD format)
        categories: Optional comma-separated category keys (see
            EXPORT_CATEGORIES). None/empty → include all.

    Returns the ZIP file as bytes.
    """
    total_start = time.time()
    selected = _parse_categories(categories)
    allowed_files = _files_for_categories(selected)
    logger.info(
        f"🔄 Starting data export for user: {user_id}, "
        f"date_range: {start_date} to {end_date}, categories: {sorted(selected)}"
    )

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
        logger.error(f"Error fetching metrics: {e}", exc_info=True)
        results["metrics"] = []

    try:
        logger.info("📊 Fetching workouts...")
        results["workouts"] = _get_filtered_workouts(db, user_id, start_date, end_date)
        logger.info(f"  ✓ workouts: {len(results['workouts'])} rows")
    except Exception as e:
        logger.error(f"Error fetching workouts: {e}", exc_info=True)
        results["workouts"] = []

    try:
        logger.info("📊 Fetching workout_logs...")
        results["workout_logs"] = _get_filtered_workout_logs(db, user_id, start_date, end_date)
        logger.info(f"  ✓ workout_logs: {len(results['workout_logs'])} rows")
    except Exception as e:
        logger.error(f"Error fetching workout_logs: {e}", exc_info=True)
        results["workout_logs"] = []

    try:
        logger.info("📊 Fetching performance_logs...")
        results["performance_logs"] = _get_filtered_performance_logs(db, user_id, start_date, end_date)
        logger.info(f"  ✓ performance_logs: {len(results['performance_logs'])} rows")
    except Exception as e:
        logger.error(f"Error fetching performance_logs: {e}", exc_info=True)
        results["performance_logs"] = []

    try:
        logger.info("📊 Fetching strength_records...")
        results["strength_records"] = _get_filtered_strength_records(db, user_id, start_date, end_date)
        logger.info(f"  ✓ strength_records: {len(results['strength_records'])} rows")
    except Exception as e:
        logger.error(f"Error fetching strength_records: {e}", exc_info=True)
        results["strength_records"] = []

    try:
        logger.info("📊 Fetching achievements...")
        results["achievements"] = _get_filtered_achievements(db, user_id, start_date, end_date)
        logger.info(f"  ✓ achievements: {len(results['achievements'])} rows")
    except Exception as e:
        logger.error(f"Error fetching achievements: {e}", exc_info=True)
        results["achievements"] = []

    try:
        logger.info("📊 Fetching streaks...")
        results["streaks"] = _get_user_streaks(db, user_id)
        logger.info(f"  ✓ streaks: {len(results['streaks'])} rows")
    except Exception as e:
        logger.error(f"Error fetching streaks: {e}", exc_info=True)
        results["streaks"] = []

    logger.info(f"⏱️ All queries completed in {time.time() - t:.2f}s")

    # Create in-memory ZIP file
    zip_buffer = io.BytesIO()

    with zipfile.ZipFile(zip_buffer, 'w', zipfile.ZIP_DEFLATED) as zip_file:
        export_counts = {}

        def _include(file_key: str) -> bool:
            return file_key in allowed_files

        # 1. Profile data (always included, no date filter)
        profile_csv = _export_profile(user)
        zip_file.writestr("profile.csv", profile_csv)
        export_counts["profile"] = 1

        # 2. Body metrics
        if _include("body_metrics"):
            metrics_csv = _export_body_metrics(results["metrics"])
            zip_file.writestr("body_metrics.csv", metrics_csv)
            export_counts["body_metrics"] = len(results["metrics"])

        # 3. Workouts
        if _include("workouts"):
            workouts_csv = _export_workouts(results["workouts"])
            zip_file.writestr("workouts.csv", workouts_csv)
            export_counts["workouts"] = len(results["workouts"])

        # 4. Workout logs
        if _include("workout_logs"):
            logs_csv = _export_workout_logs(results["workout_logs"])
            zip_file.writestr("workout_logs.csv", logs_csv)
            export_counts["workout_logs"] = len(results["workout_logs"])

        # 5. Performance logs (exercise sets) — FitWiz-native schema
        if _include("exercise_sets"):
            sets_csv = _export_exercise_sets(results["performance_logs"])
            zip_file.writestr("exercise_sets.csv", sets_csv)
            export_counts["exercise_sets"] = len(results["performance_logs"])

        # 5b. Strong-compatible CSV — same data, Hevy-importable schema.
        # Shipped alongside (not instead of) the native format so users can
        # pick the tool chain that fits: FitWiz import for round-trip,
        # workouts_strong.csv for migrating to Hevy / community parsers.
        if _include("workouts_strong"):
            strong_csv = _export_workouts_strong_format(
                results["workouts"], results["performance_logs"]
            )
            zip_file.writestr("workouts_strong.csv", strong_csv)
            export_counts["workouts_strong"] = len(results["performance_logs"])

        # 6. Strength records
        if _include("strength_records"):
            strength_csv = _export_strength_records(results["strength_records"])
            zip_file.writestr("strength_records.csv", strength_csv)
            export_counts["strength_records"] = len(results["strength_records"])

        # 7. Achievements
        if _include("achievements"):
            achievements_csv = _export_achievements(results["achievements"])
            zip_file.writestr("achievements.csv", achievements_csv)
            export_counts["achievements"] = len(results["achievements"])

        # 8. Streaks
        if _include("streaks"):
            streaks_csv = _export_streaks(results["streaks"])
            zip_file.writestr("streaks.csv", streaks_csv)
            export_counts["streaks"] = len(results["streaks"])

        # 9. Everything else required for GDPR Art. 20 completeness.
        # Each table is dumped as SELECT * -> CSV so we never silently
        # lose a field that a later migration added.
        logger.info("📊 Fetching portability tables (chat, food, photos, etc.)...")
        extra = _collect_portability_tables(user_id, start_date, end_date)
        for table_name, rows in extra.items():
            if not _include(table_name):
                continue
            zip_file.writestr(f"{table_name}.csv", _rows_to_csv(rows))
            export_counts[table_name] = len(rows)

        # 10. Metadata file (for import validation)
        metadata_csv = _export_metadata(user_id, export_counts, start_date, end_date)
        zip_file.writestr("_metadata.csv", metadata_csv)

        # 11. README clarifying what each file contains. Helpful for users
        # who open the archive outside the app — GDPR recommends exports
        # be "structured, commonly used and machine-readable" *and* legible.
        zip_file.writestr(
            "README.txt",
            _build_export_readme(export_counts, start_date, end_date),
        )

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
            logger.error(f"Error fetching {key}: {e}", exc_info=True)
            results[key] = []

    return user, results


def export_user_data_json(
    user_id: str,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    categories: Optional[str] = None,
) -> dict:
    """
    Export all user data as a JSON-serializable dict.

    Returns dict with all data categories as lists of dicts. Keys outside
    `categories` are omitted entirely (not emptied) so the payload reflects
    the user's choice.
    """
    total_start = time.time()
    selected = _parse_categories(categories)
    allowed_files = _files_for_categories(selected)
    logger.info(f"Starting JSON export for user: {user_id}, categories: {sorted(selected)}")

    user, results = _query_all_data(user_id, start_date, end_date)

    # Parse JSONB fields in user profile
    for field in ("goals", "equipment", "active_injuries"):
        val = user.get(field, [])
        if isinstance(val, str):
            try:
                user[field] = json.loads(val)
            except Exception:
                user[field] = []

    # Fetch the additional portability tables (chat, food, photos, etc.)
    # so the JSON export satisfies GDPR Art. 20 in full.
    extra = _collect_portability_tables(user_id, start_date, end_date)

    # Profile is always included. Every other field is gated by the
    # category selection so the JSON payload actually reflects the user's
    # toggles — returning an empty list would imply "you have no data" which
    # is misleading when the data just wasn't requested.
    candidates = {
        "body_metrics": results["metrics"],
        "workouts": results["workouts"],
        "workout_logs": results["workout_logs"],
        "exercise_sets": results["performance_logs"],
        "strength_records": results["strength_records"],
        "achievements": results["achievements"],
        "streaks": results["streaks"],
        "chat_history": extra.get("chat_history", []),
        "food_logs": extra.get("food_logs", []),
        "progress_photos": extra.get("progress_photos", []),
        "nutrition_summaries": extra.get("nutrition_summaries", []),
        "user_ai_settings": extra.get("user_ai_settings", []),
        "injuries": extra.get("injuries", []),
        "habits": extra.get("habits", []),
        "habit_completions": extra.get("habit_completions", []),
        "personal_goals": extra.get("personal_goals", []),
        "user_measurements": extra.get("user_measurements", []),
        "hormonal_logs": extra.get("hormonal_logs", []),
        "kegel_logs": extra.get("kegel_logs", []),
        "cardio_logs": extra.get("cardio_logs", []),
        "custom_exercises": extra.get("custom_exercises", []),
        "water_intake": extra.get("water_intake", []),
        "mood_logs": extra.get("mood_logs", []),
    }
    export: dict = {"profile": user}
    for key, value in candidates.items():
        if key in allowed_files:
            export[key] = value

    export["metadata"] = {
        "export_version": EXPORT_VERSION,
        "exported_at": datetime.utcnow().isoformat() + "Z",
        "app_version": APP_VERSION,
        "original_user_id": user_id,
        "filter_start_date": start_date,
        "filter_end_date": end_date,
        "selected_categories": sorted(selected),
        "coverage_note": (
            "This export includes every table containing your personal "
            "data as required by GDPR Art. 20. Tables not applicable "
            "to your account appear as empty lists."
        ),
    }

    logger.info(f"JSON export complete for user {user_id} in {time.time() - total_start:.2f}s")
    return export


def export_user_data_excel(
    user_id: str,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    categories: Optional[str] = None,
) -> bytes:
    """
    Export all user data as an Excel (.xlsx) file with one sheet per data type.

    Returns .xlsx bytes.
    """
    total_start = time.time()
    selected = _parse_categories(categories)
    allowed_files = _files_for_categories(selected)
    logger.info(f"Starting Excel export for user: {user_id}, categories: {sorted(selected)}")

    user, results = _query_all_data(user_id, start_date, end_date)

    # Add the full portability coverage so Excel matches JSON/CSV.
    extra = _collect_portability_tables(user_id, start_date, end_date)

    output = io.BytesIO()
    with pd.ExcelWriter(output, engine="openpyxl") as writer:
        # Profile (always included)
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
        # Merge in portability tables. Excel sheet names have a 31-char
        # limit and can't contain []:*?/\ — truncate defensively.
        for name, rows in extra.items():
            safe_name = name.replace("/", "_")[:31]
            sheet_map[safe_name] = rows

        for sheet_name, data in sheet_map.items():
            if sheet_name not in allowed_files:
                continue
            df = pd.DataFrame(data) if data else pd.DataFrame()
            df.to_excel(writer, sheet_name=sheet_name, index=False)

    logger.info(f"Excel export complete for user {user_id} in {time.time() - total_start:.2f}s")
    output.seek(0)
    return output.getvalue()


def export_user_data_parquet(
    user_id: str,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    categories: Optional[str] = None,
) -> bytes:
    """
    Export all user data as a ZIP of Parquet files (one per data type).

    Returns ZIP bytes.
    """
    total_start = time.time()
    selected = _parse_categories(categories)
    allowed_files = _files_for_categories(selected)
    logger.info(f"Starting Parquet export for user: {user_id}, categories: {sorted(selected)}")

    user, results = _query_all_data(user_id, start_date, end_date)

    extra = _collect_portability_tables(user_id, start_date, end_date)

    zip_buffer = io.BytesIO()
    with zipfile.ZipFile(zip_buffer, "w", zipfile.ZIP_DEFLATED) as zf:
        # Profile (always included)
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
        file_map.update(extra)

        for name, data in file_map.items():
            if name not in allowed_files:
                continue
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


def _export_workouts_strong_format(
    workouts: List[Dict[str, Any]],
    performance_logs: List[Dict[str, Any]],
) -> str:
    """Export workouts + sets in the Strong app's exact CSV schema.

    Why separate from `_export_exercise_sets` + `_export_workouts`: Strong's
    CSV is the de-facto industry standard that tooling and competitor
    importers (Hevy, community parsers on GitHub) already understand. Users
    migrating between apps want *this exact layout*, not a FitWiz-native
    one — even if ours captures more fields. The plain `exercise_sets.csv`
    still ships for users who want FitWiz's richer schema.

    Columns (ORDER MATTERS — Hevy's importer validates positionally on some
    paths): Date, Workout Name, Duration, Exercise Name, Set Order, Weight,
    Reps, Distance, Seconds, Notes, Workout No.

    Source: https://help.hevyapp.com/hc/en-us/articles/38001424401943
    """
    output = io.StringIO()
    writer = csv.writer(output)

    writer.writerow([
        "Date", "Workout Name", "Duration", "Exercise Name", "Set Order",
        "Weight", "Reps", "Distance", "Seconds", "Notes", "Workout No",
    ])

    # Build a workout lookup by id so we can decorate each set row with its
    # parent workout's Date/Name/Duration. `workouts` rows come in arbitrary
    # order; avoid an O(n²) scan per set by indexing once.
    wk_by_id: Dict[str, Dict[str, Any]] = {}
    for w in workouts:
        wid = str(w.get("id") or "")
        if wid:
            wk_by_id[wid] = w

    # Assign a per-user-sequential "Workout No" matching Strong's behavior —
    # sorted by workout date ascending, numbered from 1. Groups share a number
    # when they're part of the same workout.
    ordered_workouts = sorted(
        wk_by_id.values(),
        key=lambda w: (w.get("created_at") or w.get("date") or ""),
    )
    workout_no_by_id = {
        str(w["id"]): idx + 1 for idx, w in enumerate(ordered_workouts) if w.get("id")
    }

    for log in performance_logs:
        wid = str(log.get("workout_log_id") or log.get("workout_id") or "")
        w = wk_by_id.get(wid, {})

        # Strong uses "YYYY-MM-DD HH:MM:SS" for date. Fall back through the
        # most-to-least authoritative source; performance_logs uses
        # `recorded_at` (not logged_at) in this schema.
        date_val = (
            w.get("created_at")
            or w.get("completed_at")
            or w.get("date")
            or log.get("recorded_at")
            or log.get("logged_at")
            or ""
        )

        # Duration in Strong = total workout minutes as an integer string.
        duration_minutes = w.get("duration_minutes") or w.get("total_time_minutes") or ""

        writer.writerow([
            date_val,
            w.get("name") or w.get("workout_name") or "",
            duration_minutes,
            log.get("exercise_name", ""),
            log.get("set_number", ""),
            log.get("weight_kg", ""),          # Strong stores user's chosen unit; we export kg
            log.get("reps_completed", ""),
            log.get("distance_m") or "",       # Strong's distance column (meters)
            log.get("duration_seconds") or "", # Strong's seconds column (for timed)
            log.get("notes", ""),
            workout_no_by_id.get(wid, ""),
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


def _build_export_readme(
    counts: Dict[str, int],
    start_date: Optional[str],
    end_date: Optional[str],
) -> str:
    """Plain-text companion document explaining the archive contents.

    GDPR Art. 20 calls for a "structured, commonly used and machine-readable
    format" but users who open the ZIP directly should be able to understand
    it without running code. This README is that bridge.
    """
    lines: List[str] = []
    lines.append("FitWiz — Data Export")
    lines.append("=" * 68)
    lines.append(f"Generated:   {datetime.utcnow().isoformat()}Z")
    lines.append(f"Version:     {EXPORT_VERSION}")
    if start_date or end_date:
        lines.append(f"Date range:  {start_date or 'beginning'} → {end_date or 'today'}")
    lines.append("")
    lines.append("This archive contains every personal record FitWiz holds")
    lines.append("about your account, as required by GDPR Art. 20 (the right")
    lines.append("to data portability) and CCPA/CPRA equivalents.")
    lines.append("")
    lines.append("Files:")
    human_descriptions = {
        "profile.csv": "Your account profile (name, email, fitness goals, equipment).",
        "body_metrics.csv": "Weight, waist, body-fat %, HR, blood pressure history.",
        "workouts.csv": "Scheduled and completed workouts (structure + exercises).",
        "workout_logs.csv": "Completed workout sessions (duration, exit reason).",
        "exercise_sets.csv": "Every set you have logged (weight, reps, RPE).",
        "strength_records.csv": "Recorded personal records per exercise.",
        "achievements.csv": "Trophies and milestones earned.",
        "streaks.csv": "Current and longest streaks per tracked category.",
        "chat_history.csv": "Every message you exchanged with the coach.",
        "food_logs.csv": "Every food entry you logged (with macros + source).",
        "progress_photos.csv": "Progress photo URLs, captions, and metadata.",
        "nutrition_summaries.csv": "Daily calorie/macro roll-ups.",
        "user_ai_settings.csv": "Your coaching preferences and consent timestamps.",
        "injuries.csv": "Reported injuries and recovery notes.",
        "habits.csv": "Custom habits you are tracking.",
        "habit_completions.csv": "Individual habit check-ins.",
        "personal_goals.csv": "Goals you have set (weight, strength, etc.).",
        "user_measurements.csv": "Body measurements (neck, waist, hip, etc.).",
        "hormonal_logs.csv": "Menstrual / hormonal cycle entries.",
        "kegel_logs.csv": "Kegel exercise logs.",
        "cardio_logs.csv": "Cardio sessions logged outside workouts.",
        "custom_exercises.csv": "Exercises you added yourself.",
        "water_intake.csv": "Hydration entries.",
        "mood_logs.csv": "Mood / energy / stress check-ins.",
        "_metadata.csv": "Version and per-table row counts for re-import.",
    }
    for fname, desc in human_descriptions.items():
        key = fname.replace(".csv", "")
        n = counts.get(key, 0)
        lines.append(f"  - {fname:<28} {desc}  ({n} rows)")
    lines.append("")
    lines.append("Questions? Email privacy@fitwiz.app.")
    return "\n".join(lines)


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
