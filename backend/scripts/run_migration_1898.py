#!/usr/bin/env python3
"""Run migration 1898: XP Race Condition & Timezone Fixes.

Adds FOR UPDATE row locks and user timezone parameters to prevent:
- Race conditions from concurrent requests (double daily login XP, double crate claims)
- Timezone mismatch where CURRENT_DATE (server UTC) differs from user's local date
- Consumable use race conditions
- Daily goal XP double-awarding via unique index

Functions updated:
- process_daily_login: FOR UPDATE + p_user_date
- init_daily_crates: FOR UPDATE + p_user_date + ON CONFLICT
- claim_daily_crate: FOR UPDATE
- update_activity_crate_availability: p_user_date
- get_unclaimed_crates: p_user_date
- use_consumable: FOR UPDATE
- New index: idx_xp_transactions_daily_goal_dedup
"""
import os
from pathlib import Path
import psycopg2

DATABASE_HOST = os.environ.get("DATABASE_HOST", "db.hpbzfahijszqmgsybuor.supabase.co")
DATABASE_PORT = int(os.environ.get("DATABASE_PORT", 5432))
DATABASE_NAME = os.environ.get("DATABASE_NAME", "postgres")
DATABASE_USER = os.environ.get("DATABASE_USER", "postgres")
DATABASE_PASSWORD = os.environ.get("DATABASE_PASSWORD") or os.environ.get("SUPABASE_DB_PASSWORD")
if not DATABASE_PASSWORD:
    raise SystemExit("DATABASE_PASSWORD or SUPABASE_DB_PASSWORD environment variable is required")


FUNCTIONS_TO_CHECK = [
    "process_daily_login",
    "init_daily_crates",
    "claim_daily_crate",
    "update_activity_crate_availability",
    "get_unclaimed_crates",
    "use_consumable",
]


def run():
    migration_path = Path(__file__).parent.parent / "migrations" / "1898_xp_race_condition_timezone_fixes.sql"
    sql = migration_path.read_text()

    conn = psycopg2.connect(
        host=DATABASE_HOST,
        port=DATABASE_PORT,
        dbname=DATABASE_NAME,
        user=DATABASE_USER,
        password=DATABASE_PASSWORD,
    )
    conn.autocommit = True

    try:
        with conn.cursor() as cur:
            # Check function signatures before migration
            print("[1898] === BEFORE MIGRATION ===")
            for func in FUNCTIONS_TO_CHECK:
                cur.execute("""
                    SELECT p.proname, pg_get_function_arguments(p.oid)
                    FROM pg_proc p
                    JOIN pg_namespace n ON p.pronamespace = n.oid
                    WHERE p.proname = %s AND n.nspname = 'public';
                """, (func,))
                rows = cur.fetchall()
                for name, args in rows:
                    print(f"  {name}({args})")
                if not rows:
                    print(f"  {func}: NOT FOUND")

            # Check if dedup index already exists
            cur.execute("""
                SELECT indexname FROM pg_indexes
                WHERE indexname = 'idx_xp_transactions_daily_goal_dedup';
            """)
            idx = cur.fetchone()
            print(f"\n  Daily goal dedup index: {'EXISTS' if idx else 'NOT FOUND'}")

            # Run migration
            print("\n[1898] Running migration: XP race condition & timezone fixes...")
            cur.execute(sql)
            print("[1898] Migration complete!")

            # Verify function signatures after migration
            print("\n[1898] === AFTER MIGRATION ===")
            for func in FUNCTIONS_TO_CHECK:
                cur.execute("""
                    SELECT p.proname, pg_get_function_arguments(p.oid)
                    FROM pg_proc p
                    JOIN pg_namespace n ON p.pronamespace = n.oid
                    WHERE p.proname = %s AND n.nspname = 'public';
                """, (func,))
                rows = cur.fetchall()
                for name, args in rows:
                    print(f"  {name}({args})")
                if not rows:
                    print(f"  {func}: NOT FOUND (ERROR!)")

            # Verify dedup index exists
            cur.execute("""
                SELECT indexname FROM pg_indexes
                WHERE indexname = 'idx_xp_transactions_daily_goal_dedup';
            """)
            idx = cur.fetchone()
            print(f"\n  Daily goal dedup index: {'EXISTS' if idx else 'MISSING (ERROR!)'}")

            # Verify FOR UPDATE is present in function bodies
            print("\n[1898] === FOR UPDATE VERIFICATION ===")
            for func in ["process_daily_login", "init_daily_crates", "claim_daily_crate", "use_consumable"]:
                cur.execute("""
                    SELECT prosrc FROM pg_proc p
                    JOIN pg_namespace n ON p.pronamespace = n.oid
                    WHERE p.proname = %s AND n.nspname = 'public'
                    LIMIT 1;
                """, (func,))
                row = cur.fetchone()
                if row and "FOR UPDATE" in row[0].upper():
                    print(f"  {func}: FOR UPDATE present ✓")
                elif row:
                    print(f"  {func}: FOR UPDATE MISSING (ERROR!)")
                else:
                    print(f"  {func}: function not found")

    finally:
        conn.close()


if __name__ == "__main__":
    run()
