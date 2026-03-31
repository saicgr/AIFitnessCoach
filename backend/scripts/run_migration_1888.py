#!/usr/bin/env python3
"""Run migration 1888: Fix get_custom_exercise_stats function.

Migration 074 overwrote the correct function with a broken one that references
workout_logs.exercise_id (column doesn't exist). This restores the correct
definition from migration 070 that uses exercises + custom_exercise_usage tables.
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
    file_path = migrations_dir / "1888_fix_custom_exercise_stats.sql"

    conn = psycopg2.connect(
        host=DATABASE_HOST, port=DATABASE_PORT, dbname=DATABASE_NAME,
        user=DATABASE_USER, password=DATABASE_PASSWORD, sslmode="require"
    )

    print(f"\n{'='*60}")
    print(f"Running: 1888_fix_custom_exercise_stats.sql")
    print(f"  Fixes: DROP broken get_custom_exercise_stats (references workout_logs.exercise_id)")
    print(f"  Recreates with correct definition using exercises + custom_exercise_usage tables")

    try:
        with open(file_path, 'r') as f:
            sql = f.read()
        with conn.cursor() as cur:
            cur.execute(sql)
        conn.commit()
        print(f"  SUCCESS - get_custom_exercise_stats function fixed")
    except Exception as e:
        conn.rollback()
        print(f"  FAILED: {e}")
        conn.close()
        return False

    # Verify the fix
    print(f"\n  Verifying...")
    try:
        with conn.cursor() as cur:
            # Check the function signature
            cur.execute("""
                SELECT pg_get_functiondef(oid)
                FROM pg_proc
                WHERE proname = 'get_custom_exercise_stats'
            """)
            result = cur.fetchone()
            if result and 'custom_exercise_usage' in result[0]:
                print(f"  VERIFIED - Function correctly references custom_exercise_usage table")
            elif result:
                print(f"  WARNING - Function exists but may not reference correct tables")
                print(f"  Definition: {result[0][:200]}...")
            else:
                print(f"  ERROR - Function not found after migration!")

            # Test with a sample call
            cur.execute("SELECT * FROM get_custom_exercise_stats('387701a2-f6c7-43d7-a4e7-61129b59fec6'::uuid)")
            rows = cur.fetchall()
            print(f"  TEST CALL - Returned {len(rows)} rows (no error = success)")
        conn.rollback()  # Don't commit the test query
    except Exception as e:
        print(f"  VERIFY FAILED: {e}")
        conn.rollback()

    conn.close()
    print(f"{'='*60}\n")
    return True

if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
