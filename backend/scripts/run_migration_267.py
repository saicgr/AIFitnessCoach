#!/usr/bin/env python3
"""Run migration 267 - Challenge accept-from-feed: fix triggers, add completion trigger, RLS."""
import os, sys
from pathlib import Path
import psycopg2

DATABASE_HOST = os.environ.get("DATABASE_HOST", "db.hpbzfahijszqmgsybuor.supabase.co")
DATABASE_PORT = int(os.environ.get("DATABASE_PORT", 5432))
DATABASE_NAME = os.environ.get("DATABASE_NAME", "postgres")
DATABASE_USER = os.environ.get("DATABASE_USER", "postgres")
DATABASE_PASSWORD = os.environ.get("DATABASE_PASSWORD")
if not DATABASE_PASSWORD:
    raise SystemExit("DATABASE_PASSWORD environment variable is required")

def run_migration():
    migrations_dir = Path(__file__).parent.parent / "migrations"
    file_path = migrations_dir / "267_challenge_accept_from_feed.sql"

    print("Running migration 267: Challenge accept-from-feed support...")
    try:
        conn = psycopg2.connect(
            host=DATABASE_HOST, port=DATABASE_PORT, dbname=DATABASE_NAME,
            user=DATABASE_USER, password=DATABASE_PASSWORD, sslmode="require"
        )
        with open(file_path, 'r') as f:
            sql = f.read()
        with conn.cursor() as cur:
            cur.execute(sql)
        conn.commit()
        print("SUCCESS: Challenge accept-from-feed migration applied")

        # Verify triggers exist
        with conn.cursor() as cur:
            cur.execute("""
                SELECT tgname FROM pg_trigger
                WHERE tgrelid = 'workout_challenges'::regclass
                  AND tgname IN (
                      'trigger_create_challenge_notification',
                      'trigger_notify_challenge_completed'
                  )
                ORDER BY tgname
            """)
            triggers = [row[0] for row in cur.fetchall()]
            print(f"  Triggers found: {triggers}")

            # Verify RLS policies
            cur.execute("""
                SELECT policyname FROM pg_policies
                WHERE tablename = 'workout_challenges'
                  AND policyname LIKE 'Service role%'
                ORDER BY policyname
            """)
            policies = [row[0] for row in cur.fetchall()]
            print(f"  Service role policies: {policies}")

        conn.close()
        return True
    except Exception as e:
        print(f"ERROR: {e}")
        return False

if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
