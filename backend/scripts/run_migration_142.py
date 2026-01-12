#!/usr/bin/env python3
"""
Run migration 142 - Metabolic Adaptation Tracking.

Adds table for detecting and tracking metabolic adaptation events
(plateaus, TDEE drops, recovery).
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
    """Execute migration 142."""
    migrations_dir = Path(__file__).parent.parent / "migrations"
    migration_file = migrations_dir / "142_metabolic_adaptation_tracking.sql"

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

        print(f"\nRunning migration: 142_metabolic_adaptation_tracking.sql")
        print("=" * 60)

        with open(migration_file, 'r') as f:
            sql_content = f.read()

        with conn.cursor() as cur:
            cur.execute(sql_content)

        conn.commit()
        print("SUCCESS: Migration 142 completed!")

        # Verify the table was created
        with conn.cursor() as cur:
            cur.execute("""
                SELECT table_name
                FROM information_schema.tables
                WHERE table_schema = 'public'
                AND table_name = 'metabolic_adaptation_events'
            """)
            table = cur.fetchone()
            if table:
                print(f"\nVERIFIED: Table 'metabolic_adaptation_events' created")
            else:
                print("WARNING: Table 'metabolic_adaptation_events' not found")

            # Check if index was created
            cur.execute("""
                SELECT indexname
                FROM pg_indexes
                WHERE tablename = 'metabolic_adaptation_events'
            """)
            indexes = cur.fetchall()
            if indexes:
                print(f"VERIFIED: {len(indexes)} index(es) created:")
                for idx in indexes:
                    print(f"  - {idx[0]}")

        conn.close()
        return True

    except psycopg2.Error as e:
        error_msg = str(e)
        if "already exists" in error_msg.lower():
            print(f"WARNING: Table or index already exists (this is OK)")
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
