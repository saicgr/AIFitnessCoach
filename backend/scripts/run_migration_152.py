#!/usr/bin/env python3
"""
Run migration 152 - Direct Messages for Social Feature.

Creates tables for direct messaging between users:
1. conversations table
2. conversation_participants table
3. direct_messages table
4. RLS policies
5. get_or_create_conversation function
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


def run_migration():
    """Execute migration 152."""
    migrations_dir = Path(__file__).parent.parent / "migrations"
    migration_file = migrations_dir / "152_direct_messages.sql"

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

        print(f"\nRunning migration: 152_direct_messages.sql")
        print("=" * 60)

        with open(migration_file, 'r') as f:
            sql_content = f.read()

        with conn.cursor() as cur:
            cur.execute(sql_content)

        conn.commit()
        print("SUCCESS: Migration 152 completed!")

        # Verify tables were created
        with conn.cursor() as cur:
            cur.execute("""
                SELECT table_name
                FROM information_schema.tables
                WHERE table_schema = 'public'
                AND table_name IN ('conversations', 'conversation_participants', 'direct_messages')
                ORDER BY table_name
            """)
            tables = cur.fetchall()
            if tables:
                print(f"\nVERIFIED: {len(tables)} table(s) created:")
                for t in tables:
                    print(f"  - {t[0]}")
            else:
                print("WARNING: Expected tables not found")

            # Check indexes
            cur.execute("""
                SELECT indexname, tablename
                FROM pg_indexes
                WHERE tablename IN ('conversations', 'conversation_participants', 'direct_messages')
                ORDER BY tablename, indexname
            """)
            indexes = cur.fetchall()
            if indexes:
                print(f"\nVERIFIED: {len(indexes)} index(es) created:")
                for idx in indexes:
                    print(f"  - {idx[1]}: {idx[0]}")

            # Check RLS is enabled
            cur.execute("""
                SELECT tablename, rowsecurity
                FROM pg_tables
                WHERE schemaname = 'public'
                AND tablename IN ('conversations', 'conversation_participants', 'direct_messages')
                ORDER BY tablename
            """)
            rls_status = cur.fetchall()
            if rls_status:
                print(f"\nRLS Status:")
                for t in rls_status:
                    status = "ENABLED" if t[1] else "DISABLED"
                    print(f"  - {t[0]}: {status}")

            # Check policies
            cur.execute("""
                SELECT tablename, policyname
                FROM pg_policies
                WHERE schemaname = 'public'
                AND tablename IN ('conversations', 'conversation_participants', 'direct_messages')
                ORDER BY tablename, policyname
            """)
            policies = cur.fetchall()
            if policies:
                print(f"\nVERIFIED: {len(policies)} RLS policies created:")
                for p in policies:
                    print(f"  - {p[0]}: {p[1]}")

            # Check function exists
            cur.execute("""
                SELECT routine_name
                FROM information_schema.routines
                WHERE routine_schema = 'public'
                AND routine_name = 'get_or_create_conversation'
            """)
            func = cur.fetchone()
            if func:
                print(f"\nVERIFIED: Function '{func[0]}' created")

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
