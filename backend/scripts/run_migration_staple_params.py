#!/usr/bin/env python3
"""Run migration: Add user_sets, user_reps, user_rest_seconds, target_days to staple_exercises."""
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
    file_path = migrations_dir / "add_staple_user_sets_reps.sql"

    conn = psycopg2.connect(
        host=DATABASE_HOST, port=DATABASE_PORT, dbname=DATABASE_NAME,
        user=DATABASE_USER, password=DATABASE_PASSWORD, sslmode="require"
    )

    print(f"\n{'='*60}")
    print(f"Running: add_staple_user_sets_reps.sql")
    print(f"  Adds user_sets, user_reps, user_rest_seconds, target_days columns")
    print(f"  Recreates user_staples_with_details view")

    try:
        with open(file_path, 'r') as f:
            sql = f.read()
        with conn.cursor() as cur:
            cur.execute(sql)
        conn.commit()
        print(f"  SUCCESS")
    except Exception as e:
        conn.rollback()
        print(f"  FAILED: {e}")
        conn.close()
        return False

    # Verification
    print(f"\n{'='*60}")
    print("VERIFICATION")
    print(f"{'='*60}")

    with conn.cursor() as cur:
        # Check new columns exist
        cur.execute("""
            SELECT column_name, data_type FROM information_schema.columns
            WHERE table_name = 'staple_exercises'
            AND column_name IN ('user_sets', 'user_reps', 'user_rest_seconds', 'target_days')
            ORDER BY column_name
        """)
        cols = cur.fetchall()
        print(f"\n  New columns in staple_exercises:")
        for col_name, col_type in cols:
            print(f"    {col_name}: {col_type}")

        expected = {'user_sets', 'user_reps', 'user_rest_seconds', 'target_days'}
        found = {c[0] for c in cols}
        missing = expected - found
        if missing:
            print(f"\n  WARNING: Missing columns: {missing}")
        else:
            print(f"\n  All 4 columns present")

        # Check view exists and has target_days
        cur.execute("""
            SELECT column_name FROM information_schema.columns
            WHERE table_name = 'user_staples_with_details'
            AND column_name = 'target_days'
        """)
        view_col = cur.fetchone()
        print(f"  View 'user_staples_with_details' has target_days: {view_col is not None}")

    conn.close()
    print(f"\n{'='*60}")
    print("DONE")
    return True

if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
