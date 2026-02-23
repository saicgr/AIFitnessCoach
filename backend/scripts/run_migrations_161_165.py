#!/usr/bin/env python3
"""
Run migrations 161-165 - Trophy System & Anti-Fraud.

161: XP system (levels, prestige, titles)
162: Expanded achievements (badges, categories)
163: World records (competitive trophies)
164: Gifts & rewards (gift cards, merch, referrals)
165: Anti-fraud (validation, suspicious activity detection)
"""

import os
import sys
from pathlib import Path

import psycopg2


# Database connection
DATABASE_HOST = "db.hpbzfahijszqmgsybuor.supabase.co"
DATABASE_PORT = 5432
DATABASE_NAME = "postgres"
DATABASE_USER = "postgres"
DATABASE_PASSWORD = os.environ.get("DATABASE_PASSWORD")
if not DATABASE_PASSWORD:
    raise SystemExit("DATABASE_PASSWORD environment variable is required")


def run_migrations():
    """Execute migrations 161-165."""
    migrations_dir = Path(__file__).parent.parent / "migrations"

    migrations = [
        ("161_xp_system.sql", "XP & Level System"),
        ("162_expanded_achievements.sql", "Expanded Achievements & Badges"),
        ("163_world_records.sql", "World Records & Competitive Trophies"),
        ("164_gifts_rewards.sql", "Gifts, Rewards & Referrals"),
        ("165_anti_fraud.sql", "Anti-Fraud & Validation System"),
    ]

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
                print(f"ERROR: Migration file not found: {file_path}")
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
                print(f"ERROR in {migration_file}: {e}")
                conn.rollback()

        # Verify tables were created
        print("\n" + "=" * 60)
        print("Verifying created tables...")
        print("=" * 60)

        tables_to_check = [
            "user_xp",
            "xp_transactions",
            "achievements",
            "user_achievements",
            "world_records",
            "gift_cards",
            "referrals",
            "fraud_flags",
            "workout_validations",
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
                status = "✅" if exists else "❌"
                print(f"  {status} {table}")

        # Verify functions were created
        print("\n" + "=" * 60)
        print("Verifying created functions...")
        print("=" * 60)

        functions_to_check = [
            "award_xp",
            "calculate_level_from_xp",
            "get_user_xp_summary",
            "check_and_award_achievements",
            "validate_workout",
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
                status = "✅" if exists else "❌"
                print(f"  {status} {func}()")

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
