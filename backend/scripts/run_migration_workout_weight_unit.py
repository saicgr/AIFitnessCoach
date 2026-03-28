#!/usr/bin/env python3
"""Run migration: Add workout_weight_unit column to users table."""
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
    file_path = migrations_dir / "add_workout_weight_unit.sql"

    conn = psycopg2.connect(
        host=DATABASE_HOST, port=DATABASE_PORT, dbname=DATABASE_NAME,
        user=DATABASE_USER, password=DATABASE_PASSWORD, sslmode="require"
    )

    print(f"\n{'='*60}")
    print(f"Running: add_workout_weight_unit.sql")
    print(f"  Adds workout_weight_unit column to users table")

    try:
        with open(file_path, 'r') as f:
            sql = f.read()

        with conn.cursor() as cur:
            cur.execute(sql)
        conn.commit()
        print(f"  ✅ Migration completed successfully")
    except Exception as e:
        conn.rollback()
        print(f"  ❌ Error: {e}")
        raise
    finally:
        conn.close()

if __name__ == "__main__":
    run_migration()
