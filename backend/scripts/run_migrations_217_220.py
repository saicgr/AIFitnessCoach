#!/usr/bin/env python3
"""
Run migrations 217-220 - XP System Phase 1-3.

217: First-Time Bonuses System
218: Weekly/Monthly Checkpoint Progress
219: Consumables & Rewards System
220: Daily Crate System
"""

import os
import sys
from pathlib import Path

import psycopg2


# Database connection (Supabase PostgreSQL)
DATABASE_HOST = "db.hpbzfahijszqmgsybuor.supabase.co"
DATABASE_PORT = 5432
DATABASE_NAME = "postgres"
DATABASE_USER = "postgres"
DATABASE_PASSWORD = os.environ.get("DATABASE_PASSWORD")
if not DATABASE_PASSWORD:
    raise SystemExit("DATABASE_PASSWORD environment variable is required")


def run_migrations():
    """Execute migrations 217-220."""
    migrations_dir = Path(__file__).parent.parent / "migrations"

    migrations = [
        ("217_first_time_bonuses.sql", "First-Time Bonuses System"),
        ("218_checkpoint_progress.sql", "Weekly/Monthly Checkpoint Progress"),
        ("219_consumables_system.sql", "Consumables & Rewards System"),
        ("220_daily_crate_system.sql", "Daily Crate System"),
    ]

    print("=" * 60)
    print("XP SYSTEM MIGRATIONS 217-220")
    print("=" * 60)
    print("Connecting to database...")

    try:
        conn = psycopg2.connect(
            host=DATABASE_HOST,
            port=DATABASE_PORT,
            dbname=DATABASE_NAME,
            user=DATABASE_USER,
            password=DATABASE_PASSWORD,
            sslmode="require"
        )
        print("Connected successfully!")

        for migration_file, description in migrations:
            file_path = migrations_dir / migration_file

            if not file_path.exists():
                print(f"\nERROR: Migration file not found: {file_path}")
                continue

            print(f"\n{'=' * 60}")
            print(f"Running migration: {migration_file}")
            print(f"Description: {description}")
            print("=" * 60)

            with open(file_path, 'r') as f:
                sql_content = f.read()

            try:
                with conn.cursor() as cur:
                    cur.execute(sql_content)
                conn.commit()
                print(f"SUCCESS: {migration_file} completed!")
            except Exception as e:
                error_str = str(e)
                if "already exists" in error_str.lower():
                    print(f"SKIPPED: {migration_file} - objects already exist")
                    conn.rollback()
                else:
                    print(f"ERROR in {migration_file}: {e}")
                    conn.rollback()

        # Verify tables were created
        print("\n" + "=" * 60)
        print("Verifying created tables...")
        print("=" * 60)

        tables_to_check = [
            "user_first_time_bonuses",
            "user_checkpoint_progress",
            "user_consumables",
            "user_daily_crates",
        ]

        with conn.cursor() as cur:
            for table in tables_to_check:
                cur.execute("""
                    SELECT EXISTS (
                        SELECT FROM information_schema.tables
                        WHERE table_schema = 'public'
                        AND table_name = %s
                    )
                """, (table,))
                exists = cur.fetchone()[0]
                status = "YES" if exists else "NO"
                print(f"  {status} - {table}")

        # Verify new column on user_xp
        print("\nVerifying new column...")
        with conn.cursor() as cur:
            cur.execute("""
                SELECT EXISTS (
                    SELECT FROM information_schema.columns
                    WHERE table_name = 'user_xp'
                    AND column_name = 'active_2x_token_until'
                )
            """)
            exists = cur.fetchone()[0]
            status = "YES" if exists else "NO"
            print(f"  {status} - user_xp.active_2x_token_until")

        # Verify functions were created
        print("\n" + "=" * 60)
        print("Verifying created functions...")
        print("=" * 60)

        functions_to_check = [
            "init_user_checkpoint_progress",
            "increment_checkpoint_workout",
            "init_user_consumables",
            "get_user_consumables",
            "add_consumable",
            "use_consumable",
            "activate_2x_token",
            "is_2x_xp_active",
            "award_level_up_consumables",
            "init_daily_crates",
            "update_activity_crate_availability",
            "claim_daily_crate",
        ]

        with conn.cursor() as cur:
            for func in functions_to_check:
                cur.execute("""
                    SELECT EXISTS (
                        SELECT FROM pg_proc
                        WHERE proname = %s
                    )
                """, (func,))
                exists = cur.fetchone()[0]
                status = "YES" if exists else "NO"
                print(f"  {status} - {func}()")

        conn.close()
        print("\n" + "=" * 60)
        print("All migrations completed!")
        print("=" * 60)
        return True

    except Exception as e:
        print(f"ERROR: {e}")
        return False


if __name__ == "__main__":
    success = run_migrations()
    sys.exit(0 if success else 1)
