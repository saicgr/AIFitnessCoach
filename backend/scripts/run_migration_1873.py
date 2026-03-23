#!/usr/bin/env python3
"""
Run migration 1873: Push Nudge Accountability System.

Creates push_nudge_log table for daily push notification deduplication
and extends notification_preferences JSONB with accountability coach fields.
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
    file_path = migrations_dir / "1873_push_nudge_accountability.sql"

    conn = psycopg2.connect(
        host=DATABASE_HOST, port=DATABASE_PORT, dbname=DATABASE_NAME,
        user=DATABASE_USER, password=DATABASE_PASSWORD, sslmode="require"
    )

    print(f"\n{'='*60}")
    print(f"Running: 1873_push_nudge_accountability.sql")
    print(f"  Creates push_nudge_log table + extends notification_preferences")

    try:
        with open(file_path, 'r') as f:
            sql = f.read()
        with conn.cursor() as cur:
            cur.execute(sql)
        conn.commit()
        print(f"  SUCCESS - Migration applied")
    except Exception as e:
        conn.rollback()
        print(f"  FAILED: {e}")
        conn.close()
        return False

    # Verify table creation
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'push_nudge_log'")
            exists = cur.fetchone()[0]
            print(f"  Verification: push_nudge_log table exists = {bool(exists)}")

            cur.execute("""
                SELECT COUNT(*) FROM users
                WHERE notification_preferences->>'missed_workout_nudge' IS NOT NULL
            """)
            updated = cur.fetchone()[0]
            print(f"  Verification: {updated} users have accountability preferences")
    except Exception as e:
        print(f"  Verification query failed: {e}")

    conn.close()
    print(f"{'='*60}\n")
    return True


if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
