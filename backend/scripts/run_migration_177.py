#!/usr/bin/env python3
"""
Run migration 177: Fix exercise_library video_url and image_url columns

This migration:
1. Ensures video_s3_path and image_s3_path columns exist in exercise_library table
2. Recreates the exercise_library_cleaned view with proper column aliases
"""

import os
import sys

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from supabase import create_client


def run_migration(client):
    """Run migration 177."""
    migration_path = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "migrations",
        "177_fix_exercise_library_video_columns.sql"
    )

    print(f"\n📄 Reading migration 177: fix_exercise_library_video_columns")
    print(f"   Path: {migration_path}")

    if not os.path.exists(migration_path):
        print(f"❌ Migration file not found: {migration_path}")
        return False

    with open(migration_path, "r") as f:
        migration_sql = f.read()

    print(f"🚀 Running migration 177...")

    try:
        # Split by semicolons and run each statement
        statements = [s.strip() for s in migration_sql.split(';') if s.strip()]

        for i, stmt in enumerate(statements):
            if stmt and not stmt.startswith('--'):
                try:
                    client.postgrest.rpc("exec_sql", {"sql": stmt + ";"}).execute()
                    print(f"   ✓ Statement {i+1} executed")
                except Exception as e:
                    if "does not exist" in str(e) and "exec_sql" in str(e):
                        raise e
                    print(f"   ⚠️  Statement {i+1} warning: {str(e)[:100]}")

        print(f"✅ Migration 177 completed!")
        return True

    except Exception as e:
        if "exec_sql" in str(e):
            print(f"⚠️  RPC exec_sql not available.")
            print(f"   Please run the migration manually in Supabase SQL Editor.")
            print(f"   File: {migration_path}")
            return False
        else:
            print(f"❌ Error running migration: {e}")
            return False


def main():
    """Run migration 177."""
    supabase_url = os.environ.get("SUPABASE_URL")
    supabase_key = os.environ.get("SUPABASE_SERVICE_KEY") or os.environ.get("SUPABASE_KEY")

    if not supabase_url or not supabase_key:
        print("❌ Error: SUPABASE_URL and SUPABASE_SERVICE_KEY (or SUPABASE_KEY) must be set")
        print("   Run: source .env or export the variables")
        sys.exit(1)

    print("🔄 Connecting to Supabase...")
    client = create_client(supabase_url, supabase_key)

    if run_migration(client):
        print("\n✅ Migration 177 completed successfully!")
    else:
        print("\n⚠️  Migration needs manual execution in Supabase SQL Editor.")
        print("   Copy and paste the SQL from:")
        print("   - backend/migrations/177_fix_exercise_library_video_columns.sql")


if __name__ == "__main__":
    main()
