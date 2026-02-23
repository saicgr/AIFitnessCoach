#!/usr/bin/env python3
"""
Fix Supabase Security Linter Warnings - Search Path & Materialized Views

This script fixes:
1. Functions with mutable search_path by adding SET search_path = public
2. Materialized views accessible via API - revoke direct access and create wrapper functions

Run this script with: python -m scripts.fix_search_path_security
Or directly: python scripts/fix_search_path_security.py
"""
import os
from __future__ import annotations

import psycopg2
from psycopg2 import sql
import sys
import re
from typing import Optional, List, Tuple

# Database connection details
DB_CONFIG = {
    "host": "db.hpbzfahijszqmgsybuor.supabase.co",
    "port": 5432,
    "database": "postgres",
    "user": "postgres",
    "password": os.environ.get("DATABASE_PASSWORD")
}

if not DB_CONFIG["password"]:
    raise SystemExit("DATABASE_PASSWORD environment variable is required")

# List of functions that need search_path fix (59 functions)
FUNCTIONS_TO_FIX = [
    "get_iso_week_boundaries",
    "get_primary_nutrition_goal",
    "get_muscle_injury_status",
    "increment_feature_usage",
    "get_active_injuries",
    "get_injury_avoided_exercises",
    "update_injury_updated_at",
    "get_friends_on_goal",
    "update_quick_workout_preferences_updated_at",
    "save_user_profile",
    "increment_quick_workout_count",
    "update_updated_at_column",
    "record_workout_regeneration",
    "get_days_since_last_workout",
    "start_comeback_mode",
    "update_home_layouts_updated_at",
    "progress_comeback_week",
    "end_comeback_mode",
    "update_comeback_workout_count",
    "update_last_workout_date",
    "update_app_tour_sessions_timestamp",
    "update_tour_steps_completed",
    "update_branded_programs_timestamp",
    "update_user_program_assignments_timestamp",
    "log_program_assignment_change",
    "get_user_leaderboard_rank",
    "calculate_demo_session_duration",
    "trigger_check_milestones_on_workout",
    "update_superset_preferences_updated_at",
    "upsert_superset_preferences",
    "record_superset_completion",
    "update_hormonal_updated_at",
    "get_cycle_phase_exercise_intensity",
    "check_daily_kegel_goal",
    "get_user_active_program",
    "get_recommended_programs",
    "start_branded_program",
    "update_program_progress",
    "update_cooking_conversion_updated_at",
    "find_next_exercise_variant",
    "get_latest_strength_baseline",
    "user_needs_recalibration",
    "calculate_estimated_1rm",
    "update_subjective_feedback_updated_at",
    "update_sound_preferences_updated_at",
    "get_flexibility_trend",
    "get_flexibility_score",
    "user_frequently_swaps",
    "validate_hiit_no_static_holds",
    "check_and_award_milestones",
    "calculate_user_roi_metrics",
    "get_exercise_muscles",
    "exercise_involves_muscle",
    "get_exercises_for_muscle",
    "update_user_workout_pattern",
    "update_fasting_weight_correlation",
    "calculate_fasting_weight_correlation",
]

# Materialized views to secure (4 views)
MATERIALIZED_VIEWS = [
    "leaderboard_streaks",
    "leaderboard_weekly_challenges",
    "leaderboard_challenge_masters",
    "leaderboard_volume_kings",
]


def connect():
    """Connect to the database."""
    print("Connecting to Supabase PostgreSQL...")
    conn = psycopg2.connect(**DB_CONFIG)
    conn.autocommit = False
    print("Connected successfully!")
    return conn


def get_function_definition(cursor, func_name: str) -> str | None:
    """Get the current definition of a function."""
    cursor.execute("""
        SELECT pg_get_functiondef(p.oid) as definition
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public' AND p.proname = %s
    """, (func_name,))
    result = cursor.fetchone()
    return result[0] if result else None


def fix_function_search_path(cursor, func_name: str) -> tuple[bool, str]:
    """
    Fix a function by adding SET search_path = public.

    Returns (success, message)
    """
    definition = get_function_definition(cursor, func_name)

    if not definition:
        return False, f"Function '{func_name}' not found"

    # Check if already has search_path set
    if "search_path" in definition.lower():
        return True, f"Function '{func_name}' already has search_path set"

    # Modify the function to add SET search_path = public
    # We need to inject it before the AS $$ or AS $function$ part
    # Pattern: ... LANGUAGE xxx [other options] AS $xxx$
    # We want: ... LANGUAGE xxx [other options] SET search_path = public AS $xxx$

    # Look for the pattern before AS $$ or AS $something$
    # The SET clause should go after LANGUAGE and any existing options, but before AS
    pattern = r'(\s+AS\s+\$)'

    if re.search(pattern, definition, re.IGNORECASE):
        # Insert SET search_path = public before AS
        modified = re.sub(
            pattern,
            r'\n SET search_path = public\1',
            definition,
            count=1,
            flags=re.IGNORECASE
        )

        try:
            cursor.execute(modified)
            return True, f"Fixed function '{func_name}'"
        except Exception as e:
            return False, f"Error fixing '{func_name}': {e}"
    else:
        return False, f"Could not parse function '{func_name}' - unexpected format"


def revoke_materialized_view_access(cursor, view_name: str) -> tuple[bool, str]:
    """
    Revoke SELECT from anon and authenticated roles on a materialized view.

    Returns (success, message)
    """
    try:
        cursor.execute(f"REVOKE SELECT ON public.{view_name} FROM anon, authenticated;")
        return True, f"Revoked access on '{view_name}'"
    except Exception as e:
        return False, f"Error revoking access on '{view_name}': {e}"


def get_materialized_view_columns(cursor, view_name: str) -> List[Tuple[str, str]]:
    """Get column names and types for a materialized view."""
    # Materialized views are not in information_schema, need to use pg_catalog
    cursor.execute("""
        SELECT a.attname as column_name,
               pg_catalog.format_type(a.atttypid, a.atttypmod) as data_type
        FROM pg_catalog.pg_attribute a
        JOIN pg_catalog.pg_class c ON a.attrelid = c.oid
        JOIN pg_catalog.pg_namespace n ON c.relnamespace = n.oid
        WHERE c.relname = %s
          AND n.nspname = 'public'
          AND a.attnum > 0
          AND NOT a.attisdropped
        ORDER BY a.attnum
    """, (view_name,))
    return cursor.fetchall()


def create_leaderboard_wrapper_functions(cursor) -> List[Tuple[bool, str]]:
    """
    Create wrapper functions for controlled access to leaderboard data.

    Returns list of (success, message) tuples
    """
    results = []

    # First, get actual column structures for each materialized view
    view_info = {}
    for view_name in MATERIALIZED_VIEWS:
        columns = get_materialized_view_columns(cursor, view_name)
        if columns:
            view_info[view_name] = columns
            print(f"  Found {len(columns)} columns in {view_name}")
        else:
            print(f"  Warning: Could not find columns for {view_name}")

    # Create wrapper functions based on actual view structure
    for view_name in MATERIALIZED_VIEWS:
        if view_name not in view_info:
            results.append((False, f"Skipping {view_name} - columns not found"))
            continue

        columns = view_info[view_name]
        func_name = f"get_{view_name}"

        # Build column list for RETURNS TABLE
        returns_cols = []
        select_cols = []
        for col_name, col_type in columns:
            # Map PostgreSQL types to function return types
            pg_type = col_type.upper()
            if 'INT' in pg_type:
                pg_type = 'BIGINT'
            elif pg_type == 'CHARACTER VARYING':
                pg_type = 'TEXT'
            elif pg_type == 'TIMESTAMP WITHOUT TIME ZONE':
                pg_type = 'TIMESTAMP'
            elif pg_type == 'TIMESTAMP WITH TIME ZONE':
                pg_type = 'TIMESTAMPTZ'
            elif pg_type == 'DOUBLE PRECISION':
                pg_type = 'DOUBLE PRECISION'
            elif 'NUMERIC' in pg_type:
                pg_type = 'NUMERIC'
            elif pg_type == 'UUID':
                pg_type = 'UUID'
            elif pg_type == 'BOOLEAN':
                pg_type = 'BOOLEAN'
            else:
                pg_type = 'TEXT'  # Default fallback

            returns_cols.append(f"{col_name} {pg_type}")
            select_cols.append(f"mv.{col_name}")

        returns_clause = ",\n            ".join(returns_cols)
        select_clause = ",\n                ".join(select_cols)

        func_sql = f"""
        CREATE OR REPLACE FUNCTION public.{func_name}(p_limit INTEGER DEFAULT 100)
        RETURNS TABLE (
            {returns_clause}
        )
        LANGUAGE plpgsql
        SECURITY DEFINER
        SET search_path = public
        AS $$
        BEGIN
            RETURN QUERY
            SELECT
                {select_clause}
            FROM public.{view_name} mv
            LIMIT p_limit;
        END;
        $$;
        """

        try:
            cursor.execute(func_sql)
            results.append((True, f"Created wrapper function '{func_name}'"))
        except Exception as e:
            results.append((False, f"Error creating '{func_name}': {e}"))

    # Grant execute on wrapper functions to authenticated users
    for view_name in MATERIALIZED_VIEWS:
        func_name = f"get_{view_name}"
        grant_sql = f"GRANT EXECUTE ON FUNCTION public.{func_name}(INTEGER) TO authenticated;"
        try:
            cursor.execute(grant_sql)
            results.append((True, f"Granted execute on '{func_name}' to authenticated"))
        except Exception as e:
            results.append((False, f"Error granting execute on '{func_name}': {e}"))

    return results


def main():
    print("=" * 70)
    print("Supabase Security Fixes - Search Path & Materialized Views")
    print("=" * 70)

    conn = None
    try:
        conn = connect()
        cursor = conn.cursor()

        # Track results
        success_count = 0
        failure_count = 0
        skip_count = 0

        # ============================================================
        # 1. Fix functions with mutable search_path
        # ============================================================
        print(f"\n{'-' * 70}")
        print(f"1. Fixing {len(FUNCTIONS_TO_FIX)} functions with mutable search_path")
        print("-" * 70)

        for func_name in FUNCTIONS_TO_FIX:
            success, message = fix_function_search_path(cursor, func_name)
            if success:
                if "already has" in message:
                    skip_count += 1
                    print(f"  [SKIP] {message}")
                else:
                    success_count += 1
                    print(f"  [OK] {message}")
            else:
                failure_count += 1
                print(f"  [FAIL] {message}")

        # ============================================================
        # 2. Revoke access on materialized views
        # ============================================================
        print(f"\n{'-' * 70}")
        print(f"2. Revoking access on {len(MATERIALIZED_VIEWS)} materialized views")
        print("-" * 70)

        for view_name in MATERIALIZED_VIEWS:
            success, message = revoke_materialized_view_access(cursor, view_name)
            if success:
                success_count += 1
                print(f"  [OK] {message}")
            else:
                failure_count += 1
                print(f"  [FAIL] {message}")

        # ============================================================
        # 3. Create wrapper functions for leaderboard access
        # ============================================================
        print(f"\n{'-' * 70}")
        print("3. Creating wrapper functions for leaderboard access")
        print("-" * 70)

        wrapper_results = create_leaderboard_wrapper_functions(cursor)
        for success, message in wrapper_results:
            if success:
                success_count += 1
                print(f"  [OK] {message}")
            else:
                failure_count += 1
                print(f"  [FAIL] {message}")

        # ============================================================
        # Commit or rollback
        # ============================================================
        print(f"\n{'=' * 70}")
        print("Summary")
        print("=" * 70)
        print(f"  Successful: {success_count}")
        print(f"  Skipped:    {skip_count}")
        print(f"  Failed:     {failure_count}")

        if failure_count == 0:
            print("\nCommitting changes...")
            conn.commit()
            print("All changes committed successfully!")
            return 0
        else:
            print("\nSome operations failed. Rolling back all changes...")
            conn.rollback()
            print("Changes rolled back.")
            return 1

    except Exception as e:
        print(f"\nFATAL ERROR: {e}")
        import traceback
        traceback.print_exc()
        if conn:
            conn.rollback()
        return 1
    finally:
        if conn:
            conn.close()
            print("\nDatabase connection closed.")


if __name__ == "__main__":
    sys.exit(main())
