#!/usr/bin/env python3
"""Run migration 1597 - Reclassify stretch exercises and purge affected workouts."""
import os, sys
from pathlib import Path
import psycopg2

DATABASE_HOST = os.environ.get("DATABASE_HOST", "db.hpbzfahijszqmgsybuor.supabase.co")
DATABASE_PORT = int(os.environ.get("DATABASE_PORT", 5432))
DATABASE_NAME = os.environ.get("DATABASE_NAME", "postgres")
DATABASE_USER = os.environ.get("DATABASE_USER", "postgres")
DATABASE_PASSWORD = os.environ.get("DATABASE_PASSWORD") or os.environ.get("SUPABASE_DB_PASSWORD")
if not DATABASE_PASSWORD:
    raise SystemExit("DATABASE_PASSWORD or SUPABASE_DB_PASSWORD environment variable is required")

def run_migration():
    migrations_dir = Path(__file__).parent.parent / "migrations"
    file_path = migrations_dir / "1597_reclassify_stretch_exercises.sql"

    print("Running migration 1597: Reclassify stretch exercises & purge affected workouts...")
    try:
        conn = psycopg2.connect(
            host=DATABASE_HOST, port=DATABASE_PORT, dbname=DATABASE_NAME,
            user=DATABASE_USER, password=DATABASE_PASSWORD, sslmode="require"
        )
        with open(file_path, 'r') as f:
            sql = f.read()
        with conn.cursor() as cur:
            cur.execute(sql)
            # Get row counts from the two statements
            deleted_workouts = cur.rowcount
        conn.commit()

        # Verify Part 1: exercise reclassification
        with conn.cursor() as cur:
            cur.execute("SELECT COUNT(*) FROM exercise_library WHERE body_part = 'stretching'")
            stretch_count = cur.fetchone()[0]
            print(f"  Part 1 - Stretching exercises in library: {stretch_count} (was ~66, expect ~180)")

        # Verify Part 2: affected workouts deleted
        print(f"  Part 2 - Deleted {deleted_workouts} future workouts containing stretches")

        # Show remaining future workouts (sanity check)
        with conn.cursor() as cur:
            cur.execute("""
                SELECT COUNT(*) FROM workouts
                WHERE is_completed = false AND scheduled_date >= NOW()
            """)
            remaining = cur.fetchone()[0]
            print(f"  Remaining future incomplete workouts: {remaining}")

        conn.close()
        print("SUCCESS: Migration 1597 complete. Affected users' workouts will auto-regenerate on next app open.")
        return True
    except Exception as e:
        print(f"ERROR: {e}")
        return False

if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
