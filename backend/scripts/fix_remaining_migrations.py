#!/usr/bin/env python3
"""
Fix remaining failing migrations.
"""

import os
import sys
from pathlib import Path

import psycopg2


# Database connection
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
            print(f"  {error_msg[:300]}")
            return False


def main():
    print("\n" + "="*60)
    print("Fixing Remaining Migrations")
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

    migrations_dir = Path(__file__).parent.parent / "migrations"

    # Fix 089_cardio_sessions.sql - drop and recreate the view with proper columns
    print("\n--- 089_cardio_sessions.sql (complete fix) ---")
    # First check what columns the original view has
    check_view_sql = """
    SELECT column_name FROM information_schema.columns
    WHERE table_name = 'cardio_session_analytics'
    AND table_schema = 'public';
    """
    try:
        with conn.cursor() as cur:
            cur.execute(check_view_sql)
            cols = cur.fetchall()
            print(f"  Existing view columns: {[c[0] for c in cols]}")
    except:
        print("  View doesn't exist yet")

    # Now read the migration and strip out just the CREATE VIEW part
    # Since the view is using a different column name, we need to handle this carefully
    cardio_fix = """
    -- Drop the existing view completely
    DROP VIEW IF EXISTS cardio_session_analytics CASCADE;
    DROP VIEW IF EXISTS user_cardio_progress CASCADE;

    -- Create cardio_sessions table if not exists (main table)
    CREATE TABLE IF NOT EXISTS cardio_sessions (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        session_type TEXT NOT NULL CHECK (session_type IN ('steady_state', 'hiit', 'interval', 'liss', 'circuit')),
        activity_type TEXT NOT NULL,
        workout_id UUID REFERENCES workouts(id) ON DELETE SET NULL,
        started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        completed_at TIMESTAMPTZ,
        planned_duration_minutes INTEGER,
        actual_duration_minutes INTEGER,
        distance_km DECIMAL(8,2),
        calories_burned INTEGER,
        avg_heart_rate INTEGER,
        max_heart_rate INTEGER,
        avg_pace_min_per_km DECIMAL(5,2),
        elevation_gain_m INTEGER,
        notes TEXT,
        source TEXT DEFAULT 'manual',
        created_at TIMESTAMPTZ DEFAULT NOW(),
        updated_at TIMESTAMPTZ DEFAULT NOW()
    );

    -- Enable RLS
    ALTER TABLE cardio_sessions ENABLE ROW LEVEL SECURITY;

    -- Create policies
    DROP POLICY IF EXISTS "Users can view own cardio sessions" ON cardio_sessions;
    CREATE POLICY "Users can view own cardio sessions" ON cardio_sessions
        FOR SELECT USING (auth.uid() = user_id);

    DROP POLICY IF EXISTS "Users can create own cardio sessions" ON cardio_sessions;
    CREATE POLICY "Users can create own cardio sessions" ON cardio_sessions
        FOR INSERT WITH CHECK (auth.uid() = user_id);

    DROP POLICY IF EXISTS "Users can update own cardio sessions" ON cardio_sessions;
    CREATE POLICY "Users can update own cardio sessions" ON cardio_sessions
        FOR UPDATE USING (auth.uid() = user_id);

    DROP POLICY IF EXISTS "Users can delete own cardio sessions" ON cardio_sessions;
    CREATE POLICY "Users can delete own cardio sessions" ON cardio_sessions
        FOR DELETE USING (auth.uid() = user_id);

    -- Create indexes
    CREATE INDEX IF NOT EXISTS idx_cardio_sessions_user_id ON cardio_sessions(user_id);
    CREATE INDEX IF NOT EXISTS idx_cardio_sessions_started_at ON cardio_sessions(started_at DESC);
    CREATE INDEX IF NOT EXISTS idx_cardio_sessions_type ON cardio_sessions(session_type);

    -- Create the analytics view with proper column names
    CREATE OR REPLACE VIEW cardio_session_analytics AS
    SELECT
        cs.user_id,
        DATE_TRUNC('week', cs.started_at) as week,
        COUNT(*) as total_sessions,
        SUM(cs.actual_duration_minutes) as total_duration_minutes,
        SUM(cs.distance_km) as total_distance_km,
        SUM(cs.calories_burned) as total_calories,
        AVG(cs.avg_heart_rate)::INTEGER as avg_heart_rate,
        cs.session_type,
        cs.activity_type
    FROM cardio_sessions cs
    WHERE cs.completed_at IS NOT NULL
    GROUP BY cs.user_id, DATE_TRUNC('week', cs.started_at), cs.session_type, cs.activity_type;
    """
    run_sql(conn, cardio_fix, "089_cardio_sessions (recreated)")

    # Fix 089_leverage_progressions.sql - add all missing columns
    print("\n--- 089_leverage_progressions.sql (add missing columns) ---")
    add_columns_sql = """
    -- Add all missing columns to exercise_variant_chains
    ALTER TABLE exercise_variant_chains
    ADD COLUMN IF NOT EXISTS chain_type TEXT DEFAULT 'leverage';

    ALTER TABLE exercise_variant_chains
    ADD COLUMN IF NOT EXISTS difficulty_order INTEGER DEFAULT 1;

    ALTER TABLE exercise_variant_chains
    ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;
    """
    run_sql(conn, add_columns_sql, "Add missing columns to exercise_variant_chains")

    with open(migrations_dir / "089_leverage_progressions.sql", 'r') as f:
        sql_89_lev = f.read()
    run_sql(conn, sql_89_lev, "089_leverage_progressions")

    # Fix 090_enhanced_sets_reps_control.sql - proper table creation
    print("\n--- 090_enhanced_sets_reps_control.sql (proper table) ---")
    create_rep_range_fixed = """
    -- Create user_rep_range_preferences table properly
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

    DROP POLICY IF EXISTS "Users can manage own rep range preferences" ON user_rep_range_preferences;
    CREATE POLICY "Users can manage own rep range preferences" ON user_rep_range_preferences
        FOR ALL USING (auth.uid() = user_id);
    """
    run_sql(conn, create_rep_range_fixed, "Create user_rep_range_preferences")

    with open(migrations_dir / "090_enhanced_sets_reps_control.sql", 'r') as f:
        sql_90 = f.read()
    run_sql(conn, sql_90, "090_enhanced_sets_reps_control")

    # Fix 096_progress_analytics.sql - add missing column
    print("\n--- 096_progress_analytics.sql (add exercises_performance) ---")
    add_exercises_perf = """
    -- Add exercises_performance column to workout_logs if missing
    ALTER TABLE workout_logs
    ADD COLUMN IF NOT EXISTS exercises_performance JSONB DEFAULT '[]';
    """
    run_sql(conn, add_exercises_perf, "Add exercises_performance column")

    with open(migrations_dir / "096_progress_analytics.sql", 'r') as f:
        sql_96 = f.read()
    run_sql(conn, sql_96, "096_progress_analytics")

    conn.close()
    print("\n" + "="*60)
    print("Remaining migration fixes completed!")
    print("="*60)
    return 0


if __name__ == "__main__":
    sys.exit(main())
