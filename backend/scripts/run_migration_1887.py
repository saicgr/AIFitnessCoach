#!/usr/bin/env python3
"""Run migration 1887: Fix daily login response field names."""
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
    file_path = migrations_dir / "1887_fix_daily_login_field_names.sql"

    conn = psycopg2.connect(
        host=DATABASE_HOST, port=DATABASE_PORT, dbname=DATABASE_NAME,
        user=DATABASE_USER, password=DATABASE_PASSWORD, sslmode="require"
    )

    print(f"\n{'='*60}")
    print(f"Running: 1887_fix_daily_login_field_names.sql")
    print(f"  Fixes field names: daily_bonus->daily_xp, streak_bonus->streak_milestone_xp, max_streak->longest_streak, adds multiplier")

    try:
        with open(file_path, 'r') as f:
            sql = f.read()
        with conn.cursor() as cur:
            cur.execute(sql)
        conn.commit()
        print(f"  SUCCESS - Daily login field names fixed")
    except Exception as e:
        conn.rollback()
        print(f"  FAILED: {e}")
        conn.close()
        return False

    conn.close()
    print(f"{'='*60}\n")
    return True

if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
