#!/usr/bin/env python3
"""Run migration 1902 - Fix sync_latest_measurements_to_user temporal order."""
import os
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
    file_path = migrations_dir / "1902_fix_sync_measurements_temporal_order.sql"

    print("Running migration 1902: Fix sync_latest_measurements_to_user temporal order...")
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
        print("SUCCESS: sync_latest_measurements_to_user trigger updated")

        # Verify trigger exists
        with conn.cursor() as cur:
            cur.execute("""
                SELECT tgname, proname
                FROM pg_trigger t
                JOIN pg_proc p ON t.tgfoid = p.oid
                WHERE tgrelid = 'body_measurements'::regclass
                ORDER BY tgname
            """)
            print("\nCurrent triggers on body_measurements:")
            for row in cur.fetchall():
                print(f"  {row[0]} -> {row[1]}")

        # Also clean up duplicate weight entries for all users
        print("\nCleaning up duplicate body_measurements entries...")
        with conn.cursor() as cur:
            # Find and remove duplicate entries where same user has multiple entries
            # with same weight on the same day (keep the one with earliest measured_at)
            cur.execute("""
                WITH duplicates AS (
                    SELECT id, user_id, weight_kg, measured_at,
                           ROW_NUMBER() OVER (
                               PARTITION BY user_id, DATE(measured_at), weight_kg
                               ORDER BY measured_at ASC
                           ) as rn
                    FROM body_measurements
                    WHERE weight_kg IS NOT NULL
                )
                DELETE FROM body_measurements
                WHERE id IN (
                    SELECT id FROM duplicates WHERE rn > 1
                )
                RETURNING id, user_id, weight_kg, measured_at
            """)
            deleted = cur.fetchall()
            if deleted:
                print(f"  Removed {len(deleted)} duplicate entries:")
                for row in deleted:
                    print(f"    id={row[0]}, user={row[1][:8]}..., weight={row[2]}kg, at={row[3]}")
            else:
                print("  No duplicates found")

        conn.commit()

        # Now fix users.weight_kg to match the actual latest body_measurements entry
        print("\nSyncing users.weight_kg to latest body_measurements...")
        with conn.cursor() as cur:
            cur.execute("""
                WITH latest_weight AS (
                    SELECT DISTINCT ON (user_id)
                        user_id, weight_kg
                    FROM body_measurements
                    WHERE weight_kg IS NOT NULL
                    ORDER BY user_id, measured_at DESC
                )
                UPDATE users u
                SET weight_kg = lw.weight_kg
                FROM latest_weight lw
                WHERE u.id = lw.user_id
                  AND u.weight_kg IS DISTINCT FROM lw.weight_kg
                RETURNING u.id, u.weight_kg
            """)
            updated = cur.fetchall()
            if updated:
                print(f"  Fixed weight for {len(updated)} users:")
                for row in updated:
                    print(f"    user={row[0][:8]}..., corrected weight={row[1]}kg")
            else:
                print("  All users already have correct weight")

        conn.commit()
        conn.close()
        print("\nDone!")
    except Exception as e:
        print(f"FAILED: {e}")
        raise

if __name__ == "__main__":
    run_migration()
