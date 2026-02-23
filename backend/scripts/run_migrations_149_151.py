#!/usr/bin/env python3
"""
Run migrations 149-151 - Admin Role System, Pinned Posts, and Admin RLS Policies.

This script executes:
- Migration 149: Admin Role System (role column, is_support_user flag, helper functions)
- Migration 150: Pinned Posts (is_pinned, pinned_at, pinned_by columns on activity_feed)
- Migration 151: Admin RLS Policies (updated RLS policies for admin access)
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


MIGRATIONS = [
    ("149_admin_role_system.sql", "Admin Role System"),
    ("150_pinned_posts.sql", "Pinned Posts"),
    ("151_admin_rls_policies.sql", "Admin RLS Policies"),
]


def run_migrations():
    """Execute migrations 149-151 in order."""
    migrations_dir = Path(__file__).parent.parent / "migrations"

    print("=" * 60)
    print("Running Migrations 149-151: Admin System")
    print("=" * 60)

    # Verify all migration files exist first
    for filename, _ in MIGRATIONS:
        migration_file = migrations_dir / filename
        if not migration_file.exists():
            print(f"ERROR: Migration file not found: {migration_file}")
            return False

    print("\nAll migration files found. Connecting to database...")

    try:
        conn = psycopg2.connect(
            host=DATABASE_HOST,
            port=DATABASE_PORT,
            dbname=DATABASE_NAME,
            user=DATABASE_USER,
            password=DATABASE_PASSWORD,
            sslmode="require"
        )
        print("Connected successfully!\n")

        # Run each migration
        for filename, description in MIGRATIONS:
            migration_file = migrations_dir / filename
            print(f"Running: {filename}")
            print(f"  Description: {description}")
            print("-" * 40)

            with open(migration_file, 'r') as f:
                sql_content = f.read()

            with conn.cursor() as cur:
                cur.execute(sql_content)

            conn.commit()
            print(f"  SUCCESS: {filename} completed!\n")

        # Verify the changes
        print("=" * 60)
        print("Verifying migration results...")
        print("=" * 60)

        with conn.cursor() as cur:
            # Check role column on users
            cur.execute("""
                SELECT column_name, data_type, column_default
                FROM information_schema.columns
                WHERE table_name = 'users'
                AND column_name IN ('role', 'is_support_user')
                ORDER BY column_name
            """)
            user_columns = cur.fetchall()
            if user_columns:
                print(f"\n[OK] Users table columns added:")
                for col in user_columns:
                    print(f"  - {col[0]} ({col[1]}, default: {col[2]})")
            else:
                print("\n[WARNING] Expected columns not found on users table")

            # Check activity_feed columns
            cur.execute("""
                SELECT column_name, data_type
                FROM information_schema.columns
                WHERE table_name = 'activity_feed'
                AND column_name IN ('is_pinned', 'pinned_at', 'pinned_by')
                ORDER BY column_name
            """)
            activity_columns = cur.fetchall()
            if activity_columns:
                print(f"\n[OK] Activity_feed table columns added:")
                for col in activity_columns:
                    print(f"  - {col[0]} ({col[1]})")
            else:
                print("\n[WARNING] Expected columns not found on activity_feed table")

            # Check indexes
            cur.execute("""
                SELECT indexname, tablename
                FROM pg_indexes
                WHERE indexname IN ('idx_users_role', 'idx_users_is_support_user', 'idx_activity_feed_pinned')
            """)
            indexes = cur.fetchall()
            if indexes:
                print(f"\n[OK] Indexes created:")
                for idx in indexes:
                    print(f"  - {idx[0]} on {idx[1]}")

            # Check functions
            cur.execute("""
                SELECT routine_name
                FROM information_schema.routines
                WHERE routine_schema = 'public'
                AND routine_name IN ('is_admin', 'get_support_user_id')
            """)
            functions = cur.fetchall()
            if functions:
                print(f"\n[OK] Functions created:")
                for func in functions:
                    print(f"  - {func[0]}()")

            # Check RLS policies
            cur.execute("""
                SELECT policyname, tablename
                FROM pg_policies
                WHERE schemaname = 'public'
                AND (policyname LIKE '%admin%' OR policyname LIKE '%support user%')
            """)
            policies = cur.fetchall()
            if policies:
                print(f"\n[OK] RLS policies created/updated:")
                for pol in policies:
                    print(f"  - {pol[0]} on {pol[1]}")

        conn.close()
        print("\n" + "=" * 60)
        print("ALL MIGRATIONS COMPLETED SUCCESSFULLY!")
        print("=" * 60)
        return True

    except psycopg2.Error as e:
        error_msg = str(e)
        if "already exists" in error_msg.lower():
            print(f"WARNING: Some objects already exist (this may be OK)")
            print(f"Details: {error_msg}")
            return True
        else:
            print(f"ERROR: Database error - {error_msg}")
            return False
    except Exception as e:
        print(f"ERROR: {e}")
        return False


if __name__ == "__main__":
    success = run_migrations()
    sys.exit(0 if success else 1)
