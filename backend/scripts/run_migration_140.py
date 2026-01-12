#!/usr/bin/env python3
"""
Run migration 140 - Create user_challenge_mastery table.

This table tracks beginner users' progress with challenge exercises.
When they complete challenges successfully 2+ times consecutively,
the exercise becomes ready to be included in their main workouts.
"""

import sys
from pathlib import Path

import psycopg2


# Database connection from environment
DATABASE_HOST = "db.hpbzfahijszqmgsybuor.supabase.co"
DATABASE_PORT = 5432
DATABASE_NAME = "postgres"
DATABASE_USER = "postgres"
DATABASE_PASSWORD = "d2nHU5oLZ1GCz63B"


def run_migration():
    """Execute migration 140."""
    migrations_dir = Path(__file__).parent.parent / "migrations"
    migration_file = migrations_dir / "140_user_challenge_mastery.sql"

    if not migration_file.exists():
        print(f"ERROR: Migration file not found: {migration_file}")
        return False

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

        print(f"\nRunning migration: 140_user_challenge_mastery.sql")
        print("=" * 60)

        with open(migration_file, 'r') as f:
            sql_content = f.read()

        with conn.cursor() as cur:
            cur.execute(sql_content)

        conn.commit()
        print("SUCCESS: Migration 140 completed!")

        # Verify the table was created
        with conn.cursor() as cur:
            cur.execute("""
                SELECT table_name
                FROM information_schema.tables
                WHERE table_name = 'user_challenge_mastery'
            """)
            result = cur.fetchone()
            if result:
                print(f"VERIFIED: user_challenge_mastery table exists")
            else:
                print("WARNING: user_challenge_mastery table not found")

            # Check columns
            cur.execute("""
                SELECT column_name, data_type
                FROM information_schema.columns
                WHERE table_name = 'user_challenge_mastery'
                ORDER BY ordinal_position
            """)
            columns = cur.fetchall()
            if columns:
                print(f"Columns ({len(columns)}):")
                for col in columns:
                    print(f"  - {col[0]}: {col[1]}")

        conn.close()
        return True

    except psycopg2.Error as e:
        error_msg = str(e)
        if "already exists" in error_msg.lower():
            print(f"WARNING: Table or object already exists (this is OK)")
            return True
        else:
            print(f"ERROR: {error_msg}")
            return False
    except Exception as e:
        print(f"ERROR: {e}")
        return False


if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
