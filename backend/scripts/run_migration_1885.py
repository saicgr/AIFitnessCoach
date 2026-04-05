#!/usr/bin/env python3
"""Run migration 1885: Add target_weight_kg, target_reps, progression_model to performance_logs.

These columns allow comparing planned vs actual performance and tracking
which progression model the user selected for each exercise.
"""
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
    file_path = migrations_dir / "1885_add_targets_and_progression_to_performance_logs.sql"

    conn = psycopg2.connect(
        host=DATABASE_HOST, port=DATABASE_PORT, dbname=DATABASE_NAME,
        user=DATABASE_USER, password=DATABASE_PASSWORD, sslmode="require"
    )

    print(f"\n{'='*60}")
    print(f"Running: 1885_add_targets_and_progression_to_performance_logs.sql")
    print(f"  Adds target_weight_kg, target_reps, progression_model")
    print(f"{'='*60}")

    try:
        with conn.cursor() as cur:
            # Check which columns exist before
            cur.execute("""
                SELECT column_name FROM information_schema.columns
                WHERE table_name = 'performance_logs'
                AND column_name IN ('target_weight_kg', 'target_reps', 'progression_model')
            """)
            existing = [r[0] for r in cur.fetchall()]
            print(f"\n  Columns already present: {existing or 'none'}")

            sql = file_path.read_text()
            cur.execute(sql)
            conn.commit()

            # Verify columns exist after
            cur.execute("""
                SELECT column_name, data_type FROM information_schema.columns
                WHERE table_name = 'performance_logs'
                AND column_name IN ('target_weight_kg', 'target_reps', 'progression_model')
                ORDER BY column_name
            """)
            after = cur.fetchall()
            print(f"  Columns after migration:")
            for col_name, col_type in after:
                print(f"    {col_name}: {col_type}")

            # Also check workout_logs.metadata
            cur.execute("""
                SELECT column_name, data_type FROM information_schema.columns
                WHERE table_name = 'workout_logs' AND column_name = 'metadata'
            """)
            meta = cur.fetchone()
            if meta:
                print(f"    workout_logs.metadata: {meta[1]}")

            print(f"\n  Migration 1885 completed successfully!")

    except Exception as e:
        conn.rollback()
        print(f"\n  ERROR: {e}")
        sys.exit(1)
    finally:
        conn.close()

if __name__ == "__main__":
    run_migration()
