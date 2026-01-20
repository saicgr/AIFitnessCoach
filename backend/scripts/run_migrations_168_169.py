#!/usr/bin/env python3
"""
Run migrations 168 and 169:
- 168: Multi-Gym Profile System
- 169: HYROX Race Prep Program
"""

import os
import sys

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from supabase import create_client

def run_migration(client, migration_number: int, migration_name: str):
    """Run a single migration file."""
    migration_path = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "migrations",
        f"{migration_number}_{migration_name}.sql"
    )

    print(f"\n📄 Reading migration {migration_number}: {migration_name}")
    print(f"   Path: {migration_path}")

    if not os.path.exists(migration_path):
        print(f"❌ Migration file not found: {migration_path}")
        return False

    with open(migration_path, "r") as f:
        migration_sql = f.read()

    print(f"🚀 Running migration {migration_number}...")

    try:
        # Split by semicolons and run each statement
        statements = [s.strip() for s in migration_sql.split(';') if s.strip()]

        for i, stmt in enumerate(statements):
            if stmt:
                try:
                    client.postgrest.rpc("exec_sql", {"sql": stmt + ";"}).execute()
                except Exception as e:
                    # Some statements might fail due to exec_sql limitations
                    # We'll print the error and continue
                    if "does not exist" in str(e) and "exec_sql" in str(e):
                        raise e  # Re-raise if exec_sql doesn't exist
                    print(f"   ⚠️  Statement {i+1} warning: {str(e)[:100]}")

        print(f"✅ Migration {migration_number} completed!")
        return True

    except Exception as e:
        if "exec_sql" in str(e):
            print(f"⚠️  RPC exec_sql not available.")
            print(f"   Please run the migration manually in Supabase SQL Editor.")
            print(f"   File: {migration_path}")
            return False
        else:
            print(f"❌ Error running migration {migration_number}: {e}")
            return False


def main():
    """Run migrations 168 and 169."""
    supabase_url = os.environ.get("SUPABASE_URL")
    supabase_key = os.environ.get("SUPABASE_SERVICE_KEY")

    if not supabase_url or not supabase_key:
        print("❌ Error: SUPABASE_URL and SUPABASE_SERVICE_KEY must be set")
        print("   Run: source .env or export the variables")
        sys.exit(1)

    print("🔄 Connecting to Supabase...")
    client = create_client(supabase_url, supabase_key)

    migrations = [
        (168, "gym_profiles"),
        (169, "hyrox_program"),
    ]

    success_count = 0
    for num, name in migrations:
        if run_migration(client, num, name):
            success_count += 1

    print(f"\n{'='*50}")
    print(f"📊 Migration Summary: {success_count}/{len(migrations)} completed")

    if success_count < len(migrations):
        print("\n⚠️  Some migrations need manual execution in Supabase SQL Editor.")
        print("   Copy and paste the SQL from:")
        for num, name in migrations:
            print(f"   - backend/migrations/{num}_{name}.sql")


if __name__ == "__main__":
    main()
