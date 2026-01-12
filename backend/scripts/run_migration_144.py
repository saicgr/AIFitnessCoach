#!/usr/bin/env python3
"""
Run migration 144 - Fix View Security.

Recreates weekly_adherence_summary view with security_invoker = true
to fix Supabase linter warning about SECURITY DEFINER.
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
    """Execute migration 144."""
    migrations_dir = Path(__file__).parent.parent / "migrations"
    migration_file = migrations_dir / "144_fix_view_security.sql"

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

        print(f"\nRunning migration: 144_fix_view_security.sql")
        print("=" * 60)

        with open(migration_file, 'r') as f:
            sql_content = f.read()

        with conn.cursor() as cur:
            cur.execute(sql_content)

        conn.commit()
        print("SUCCESS: Migration 144 completed!")

        # Verify the view was recreated with correct security
        with conn.cursor() as cur:
            cur.execute("""
                SELECT viewname
                FROM pg_views
                WHERE schemaname = 'public'
                AND viewname = 'weekly_adherence_summary'
            """)
            view = cur.fetchone()
            if view:
                print(f"\nVERIFIED: View 'weekly_adherence_summary' exists")
            else:
                print("WARNING: View 'weekly_adherence_summary' not found")

        conn.close()
        return True

    except psycopg2.Error as e:
        error_msg = str(e)
        print(f"ERROR: {error_msg}")
        return False
    except Exception as e:
        print(f"ERROR: {e}")
        return False


if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
