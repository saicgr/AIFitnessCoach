#!/usr/bin/env python3
"""
Run migrations 217-226 - Complete XP System.

217: First-Time Bonuses System
218: Weekly/Monthly Checkpoint Progress
219: Consumables & Rewards System
220: Daily Crate System
221: Dynamic Checkpoint Targets
222: Extended Weekly Checkpoints (10 types)
223: Monthly Achievements (12 types)
224: Daily Social XP
225: Level Progression to 250
226: Update Social XP Limits
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
    """Execute migrations 217-226."""
    migrations_dir = Path(__file__).parent.parent / "migrations"

    migrations = [
        ("217_first_time_bonuses.sql", "First-Time Bonuses System"),
        ("218_checkpoint_progress.sql", "Weekly/Monthly Checkpoint Progress"),
        ("219_consumables_system.sql", "Consumables & Rewards System"),
        ("220_daily_crate_system.sql", "Daily Crate System"),
        ("221_dynamic_checkpoint_targets.sql", "Dynamic Checkpoint Targets"),
        ("222_extended_weekly_checkpoints.sql", "Extended Weekly Checkpoints (10 types)"),
        ("223_monthly_achievements.sql", "Monthly Achievements (12 types)"),
        ("224_daily_social_xp.sql", "Daily Social XP (4 actions)"),
        ("225_level_progression_250.sql", "Level Progression to 250"),
        ("226_update_social_xp_limits.sql", "Update Social XP Limits"),
    ]

    print("=" * 60)
    print("XP SYSTEM MIGRATIONS 217-226")
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
                elif "does not exist" in error_str.lower() and "drop" in error_str.lower():
                    print(f"SKIPPED: {migration_file} - object to drop doesn't exist (OK)")
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
            "user_extended_weekly_progress",
            "user_monthly_achievements",
            "user_daily_social_xp",
            "level_rewards",
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

        # Verify key functions were created
        print("\n" + "=" * 60)
        print("Verifying key functions...")
        print("=" * 60)

        functions_to_check = [
            "init_user_checkpoint_progress",
            "increment_checkpoint_workout",
            "get_user_consumables",
            "claim_daily_crate",
            "get_user_days_per_week",
            "init_extended_weekly_progress",
            "get_full_weekly_progress",
            "init_user_monthly_achievements",
            "get_monthly_achievements_progress",
            "init_user_daily_social",
            "award_social_share_xp",
            "get_daily_social_xp_status",
            "calculate_level_from_xp",
            "get_xp_title",
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
