#!/usr/bin/env python3
"""
Run migration 264 - Media analysis background job queue.

Creates the media_analysis_jobs table for tracking async media analysis tasks.

Changes:
  - Creates media_analysis_jobs table with UUID PK, status tracking, S3 keys, results
  - Adds indexes for user_id, status, and pending/in_progress jobs
  - Enables RLS with user-read and service-role-all policies
"""

import os
import sys
from pathlib import Path

import psycopg2


# Database connection (Supabase PostgreSQL)
DATABASE_HOST = os.environ.get("DATABASE_HOST", "db.hpbzfahijszqmgsybuor.supabase.co")
DATABASE_PORT = int(os.environ.get("DATABASE_PORT", 5432))
DATABASE_NAME = os.environ.get("DATABASE_NAME", "postgres")
DATABASE_USER = os.environ.get("DATABASE_USER", "postgres")
DATABASE_PASSWORD = os.environ.get("DATABASE_PASSWORD")
if not DATABASE_PASSWORD:
    raise SystemExit("DATABASE_PASSWORD environment variable is required")


def run_migration():
    """Execute migration 264 - media_analysis_jobs table."""
    migrations_dir = Path(__file__).parent.parent / "migrations"

    migration_files = [
        "264_media_analysis_jobs.sql",
    ]

    print("=" * 60)
    print("MIGRATION 264: Media Analysis Jobs Table")
    print("=" * 60)
    print()
    print("This migration:")
    print("  - Creates media_analysis_jobs table")
    print("  - Adds indexes for user_id, status, pending jobs")
    print("  - Enables RLS with user-read and service-role policies")
    print()
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

        for migration_file in migration_files:
            file_path = migrations_dir / migration_file

            if not file_path.exists():
                print(f"\nERROR: Migration file not found: {file_path}")
                return False

            print(f"\n{'=' * 60}")
            print(f"Running: {migration_file}")
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
                return False

        # Verify the table was created
        print("\n" + "=" * 60)
        print("Verifying migration...")
        print("=" * 60)

        with conn.cursor() as cur:
            # Check table exists
            cur.execute("""
                SELECT EXISTS (
                    SELECT FROM information_schema.tables
                    WHERE table_schema = 'public'
                    AND table_name = 'media_analysis_jobs'
                )
            """)
            exists = cur.fetchone()[0]
            print(f"\n  Table exists: {'YES' if exists else 'NO (ERROR)'}")

            if exists:
                # Check columns
                cur.execute("""
                    SELECT column_name, data_type
                    FROM information_schema.columns
                    WHERE table_schema = 'public'
                    AND table_name = 'media_analysis_jobs'
                    ORDER BY ordinal_position
                """)
                columns = cur.fetchall()
                print(f"  Columns ({len(columns)}):")
                for col_name, col_type in columns:
                    print(f"    - {col_name}: {col_type}")

                # Check indexes
                cur.execute("""
                    SELECT indexname
                    FROM pg_indexes
                    WHERE tablename = 'media_analysis_jobs'
                """)
                indexes = cur.fetchall()
                print(f"\n  Indexes ({len(indexes)}):")
                for (idx_name,) in indexes:
                    print(f"    - {idx_name}")

                # Check RLS is enabled
                cur.execute("""
                    SELECT relrowsecurity
                    FROM pg_class
                    WHERE relname = 'media_analysis_jobs'
                """)
                rls = cur.fetchone()
                print(f"\n  RLS enabled: {'YES' if rls and rls[0] else 'NO (WARNING)'}")

                # Check policies
                cur.execute("""
                    SELECT policyname, cmd
                    FROM pg_policies
                    WHERE tablename = 'media_analysis_jobs'
                """)
                policies = cur.fetchall()
                print(f"  Policies ({len(policies)}):")
                for pol_name, pol_cmd in policies:
                    print(f"    - {pol_name} ({pol_cmd})")

        conn.close()
        print("\n" + "=" * 60)
        print("Migration 264 completed successfully!")
        print("=" * 60)
        return True

    except Exception as e:
        print(f"ERROR: {e}")
        return False


if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
