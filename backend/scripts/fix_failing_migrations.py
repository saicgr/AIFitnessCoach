#!/usr/bin/env python3
"""
Fix and run the failing migrations with appropriate modifications.
"""

import os
import sys
from pathlib import Path

import psycopg2


# Database connection from environment
DATABASE_HOST = "db.hpbzfahijszqmgsybuor.supabase.co"
DATABASE_PORT = 5432
DATABASE_NAME = "postgres"
DATABASE_USER = "postgres"
DATABASE_PASSWORD = "d2nHU5oLZ1GCz63B"


def run_sql(conn, sql, name=""):
    """Execute SQL and handle errors."""
    try:
        with conn.cursor() as cur:
            cur.execute(sql)
        conn.commit()
        print(f"SUCCESS: {name}")
        return True
    except psycopg2.Error as e:
        conn.rollback()
        error_msg = str(e)
        if "already exists" in error_msg.lower():
            print(f"OK (already exists): {name}")
            return True
        else:
            print(f"ERROR: {name}")
            print(f"  {error_msg[:200]}")
            return False


def main():
    print("\n" + "="*60)
    print("Fixing Failing Migrations")
    print("="*60)

    # Connect to database
    print(f"\nConnecting to database...")
    try:
        conn = psycopg2.connect(
            host=DATABASE_HOST,
            port=DATABASE_PORT,
            dbname=DATABASE_NAME,
            user=DATABASE_USER,
            password=DATABASE_PASSWORD,
            connect_timeout=30
        )
        conn.autocommit = False
        print("Connected successfully!")
    except Exception as e:
        print(f"Failed to connect: {e}")
        return 1

    # Fix 077_performance_comparison.sql - just run without the user_context_log_types insert
    print("\n--- 077_performance_comparison.sql (without log types) ---")
    migrations_dir = Path(__file__).parent.parent / "migrations"

    with open(migrations_dir / "077_performance_comparison.sql", 'r') as f:
        sql = f.read()

    # Remove the problematic INSERT statement
    sql_fixed = sql.split("-- 6. User Context Logging")[0] + """
-- 7. Grant permissions
-- ============================================================================
GRANT SELECT, INSERT ON exercise_performance_summary TO authenticated;
GRANT SELECT, INSERT ON workout_performance_summary TO authenticated;
GRANT EXECUTE ON FUNCTION get_previous_exercise_performance TO authenticated;
GRANT EXECUTE ON FUNCTION get_workout_comparison TO authenticated;
GRANT EXECUTE ON FUNCTION get_exercise_comparisons TO authenticated;

-- 8. Comments
COMMENT ON TABLE exercise_performance_summary IS 'Aggregated exercise performance per workout for comparison';
COMMENT ON TABLE workout_performance_summary IS 'Aggregated workout-level performance for comparison';
COMMENT ON FUNCTION get_exercise_comparisons IS 'Returns exercise-by-exercise comparison with previous session';
COMMENT ON FUNCTION get_workout_comparison IS 'Returns workout-level comparison with previous similar workout';
"""
    run_sql(conn, sql_fixed, "077_performance_comparison (fixed)")

    # Fix 089_cardio_sessions.sql - check if view exists and handle column rename
    print("\n--- 089_cardio_sessions.sql ---")
    with open(migrations_dir / "089_cardio_sessions.sql", 'r') as f:
        sql_89_cardio = f.read()

    # First, try to drop the view if it exists, then recreate
    # The issue is that the view already exists with different column names
    drop_view_sql = """
    DROP VIEW IF EXISTS cardio_session_analytics CASCADE;
    DROP VIEW IF EXISTS user_cardio_progress CASCADE;
    """
    run_sql(conn, drop_view_sql, "Drop existing cardio views")
    run_sql(conn, sql_89_cardio, "089_cardio_sessions")

    # Fix 089_leverage_progressions.sql - add column if missing
    print("\n--- 089_leverage_progressions.sql ---")
    add_column_sql = """
    -- Add muscle_group column if it doesn't exist
    ALTER TABLE exercise_variant_chains
    ADD COLUMN IF NOT EXISTS muscle_group TEXT;
    """
    run_sql(conn, add_column_sql, "Add muscle_group column")

    with open(migrations_dir / "089_leverage_progressions.sql", 'r') as f:
        sql_89_lev = f.read()
    run_sql(conn, sql_89_lev, "089_leverage_progressions")

    # Fix 090_enhanced_sets_reps_control.sql - create missing table first
    print("\n--- 090_enhanced_sets_reps_control.sql ---")
    create_rep_range_table = """
    CREATE TABLE IF NOT EXISTS user_rep_range_preferences (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        preference_type TEXT NOT NULL DEFAULT 'default',
        min_reps INTEGER DEFAULT 8,
        max_reps INTEGER DEFAULT 12,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        updated_at TIMESTAMPTZ DEFAULT NOW(),
        UNIQUE(user_id, preference_type)
    );

    ALTER TABLE user_rep_range_preferences ENABLE ROW LEVEL SECURITY;

    CREATE POLICY IF NOT EXISTS "Users can manage own rep range preferences"
    ON user_rep_range_preferences FOR ALL
    USING (auth.uid() = user_id);
    """
    run_sql(conn, create_rep_range_table, "Create user_rep_range_preferences")

    with open(migrations_dir / "090_enhanced_sets_reps_control.sql", 'r') as f:
        sql_90 = f.read()
    run_sql(conn, sql_90, "090_enhanced_sets_reps_control")

    # Fix 092, 093, 094 - create migration_log table if needed
    print("\n--- Creating migration_log table ---")
    create_migration_log = """
    CREATE TABLE IF NOT EXISTS migration_log (
        id SERIAL PRIMARY KEY,
        migration_name TEXT NOT NULL UNIQUE,
        applied_at TIMESTAMPTZ DEFAULT NOW(),
        description TEXT
    );
    """
    run_sql(conn, create_migration_log, "Create migration_log")

    # Now run 092, 093, 094
    for num in ["092_warmup_movement_type.sql", "093_sound_preferences.sql", "094_exercise_swap_tracking.sql"]:
        print(f"\n--- {num} ---")
        with open(migrations_dir / num, 'r') as f:
            sql = f.read()
        run_sql(conn, sql, num)

    # Fix 095_hiit_interval_workouts.sql - add movement_type column if missing
    print("\n--- 095_hiit_interval_workouts.sql ---")
    add_movement_type = """
    ALTER TABLE exercises
    ADD COLUMN IF NOT EXISTS movement_type TEXT;
    """
    run_sql(conn, add_movement_type, "Add movement_type column")

    with open(migrations_dir / "095_hiit_interval_workouts.sql", 'r') as f:
        sql_95 = f.read()
    run_sql(conn, sql_95, "095_hiit_interval_workouts")

    # Fix 096_progress_analytics.sql - check for missing columns
    print("\n--- 096_progress_analytics.sql ---")
    add_duration_minutes = """
    ALTER TABLE workout_logs
    ADD COLUMN IF NOT EXISTS duration_minutes INTEGER;
    """
    run_sql(conn, add_duration_minutes, "Add duration_minutes column")

    with open(migrations_dir / "096_progress_analytics.sql", 'r') as f:
        sql_96 = f.read()
    run_sql(conn, sql_96, "096_progress_analytics")

    # Fix 097_subjective_tracking.sql - check for generated_workouts
    print("\n--- 097_subjective_tracking.sql ---")
    create_generated_workouts = """
    CREATE TABLE IF NOT EXISTS generated_workouts (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        workout_data JSONB,
        created_at TIMESTAMPTZ DEFAULT NOW()
    );

    ALTER TABLE generated_workouts ENABLE ROW LEVEL SECURITY;
    """
    run_sql(conn, create_generated_workouts, "Create generated_workouts if missing")

    with open(migrations_dir / "097_subjective_tracking.sql", 'r') as f:
        sql_97 = f.read()
    run_sql(conn, sql_97, "097_subjective_tracking")

    # Fix 107_calibration_workouts.sql - fix the bad index
    print("\n--- 107_calibration_workouts.sql ---")
    with open(migrations_dir / "107_calibration_workouts.sql", 'r') as f:
        sql_107 = f.read()

    # Remove the problematic index line
    sql_107_fixed = sql_107.replace(
        "CREATE INDEX IF NOT EXISTS idx_strength_baselines_calibration_id ON strength_baselines(calibration_id);",
        "-- (Removed: calibration_id index - column doesn't exist)"
    )
    run_sql(conn, sql_107_fixed, "107_calibration_workouts (fixed)")

    conn.close()
    print("\n" + "="*60)
    print("Migration fixes completed!")
    print("="*60)
    return 0


if __name__ == "__main__":
    sys.exit(main())
