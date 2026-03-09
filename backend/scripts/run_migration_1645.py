#!/usr/bin/env python3
"""Run migration 1645: Add validation columns to food_database, drop verified_foods."""
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
    file_path = migrations_dir / "1645_food_database_validation_columns.sql"

    conn = psycopg2.connect(
        host=DATABASE_HOST, port=DATABASE_PORT, dbname=DATABASE_NAME,
        user=DATABASE_USER, password=DATABASE_PASSWORD, sslmode="require"
    )

    print(f"\n{'='*60}")
    print(f"Running: 1645_food_database_validation_columns.sql")
    print(f"  Adds 6 validation columns to food_database, drops verified_foods")

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
            SELECT column_name FROM information_schema.columns
            WHERE table_name = 'food_database'
              AND column_name IN ('atwater_valid', 'confidence_score', 'verification_level',
                                  'validation_flags', 'food_group_detected', 'validated_at')
            ORDER BY column_name
        """)
        new_cols = [r[0] for r in cur.fetchall()]
        print(f"\n  New columns on food_database ({len(new_cols)}/6):")
        for col in new_cols:
            print(f"    - {col}")

        # Check indexes
        cur.execute("""
            SELECT indexname FROM pg_indexes
            WHERE tablename = 'food_database'
              AND indexname LIKE 'idx_food_database_%'
            ORDER BY indexname
        """)
        indexes = [r[0] for r in cur.fetchall()]
        print(f"\n  Validation indexes ({len(indexes)}):")
        for idx in indexes:
            print(f"    - {idx}")

        # Check verified_foods is gone
        cur.execute("""
            SELECT EXISTS (
                SELECT 1 FROM information_schema.tables
                WHERE table_name = 'verified_foods'
            )
        """)
        vf_exists = cur.fetchone()[0]
        print(f"\n  verified_foods table exists: {vf_exists} (should be False)")

        # Check search_verified_foods RPC is gone
        cur.execute("""
            SELECT EXISTS (
                SELECT 1 FROM pg_proc
                WHERE proname = 'search_verified_foods'
            )
        """)
        rpc_exists = cur.fetchone()[0]
        print(f"  search_verified_foods() exists: {rpc_exists} (should be False)")

    conn.close()
    print(f"\n{'='*60}")
    print("DONE")
    return len(new_cols) == 6 and not vf_exists

if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
