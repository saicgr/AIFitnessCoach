#!/usr/bin/env python3
"""Run migration 1644: Create verified_foods table with indexes and search RPC."""
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
    file_path = migrations_dir / "1644_create_verified_foods_table.sql"

    conn = psycopg2.connect(
        host=DATABASE_HOST, port=DATABASE_PORT, dbname=DATABASE_NAME,
        user=DATABASE_USER, password=DATABASE_PASSWORD, sslmode="require"
    )

    print(f"\n{'='*60}")
    print(f"Running: 1644_create_verified_foods_table.sql")
    print(f"  Creates verified_foods table, 6 indexes, search_verified_foods() RPC")

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
        # Check table exists
        cur.execute("""
            SELECT EXISTS (
                SELECT 1 FROM information_schema.tables
                WHERE table_name = 'verified_foods'
            )
        """)
        table_exists = cur.fetchone()[0]
        print(f"\n  Table 'verified_foods' exists: {table_exists}")

        # Check indexes
        cur.execute("""
            SELECT indexname FROM pg_indexes
            WHERE tablename = 'verified_foods'
            ORDER BY indexname
        """)
        indexes = [r[0] for r in cur.fetchall()]
        print(f"  Indexes ({len(indexes)}):")
        for idx in indexes:
            print(f"    - {idx}")

        # Check RPC function exists
        cur.execute("""
            SELECT EXISTS (
                SELECT 1 FROM pg_proc
                WHERE proname = 'search_verified_foods'
            )
        """)
        rpc_exists = cur.fetchone()[0]
        print(f"  Function 'search_verified_foods' exists: {rpc_exists}")

        # Check column count
        cur.execute("""
            SELECT count(*) FROM information_schema.columns
            WHERE table_name = 'verified_foods'
        """)
        col_count = cur.fetchone()[0]
        print(f"  Column count: {col_count}")

    conn.close()
    print(f"\n{'='*60}")
    print("DONE")
    return table_exists and rpc_exists

if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
