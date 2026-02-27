#!/usr/bin/env python3
"""Run migration 265 - Fix get_feed_for_user to join users table for name + avatar."""
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
    file_path = migrations_dir / "265_feed_rpc_join_users.sql"

    print("Running migration 265: Fix feed RPC to join users table...")
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
        print("SUCCESS: get_feed_for_user now returns user_name and user_avatar")

        # Verify
        with conn.cursor() as cur:
            cur.execute("""
                SELECT prorettype::regtype FROM pg_proc WHERE proname = 'get_feed_for_user'
            """)
            row = cur.fetchone()
            print(f"  Return type: {row[0] if row else 'NOT FOUND'}")
        conn.close()
        return True
    except Exception as e:
        print(f"ERROR: {e}")
        return False

if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
