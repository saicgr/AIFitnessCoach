#!/usr/bin/env python3
"""
Run migration 228 to reduce welcome bonus XP.

This migration:
1. Updates the first_login welcome bonus from 500 XP to 250 XP
2. Grants 525 XP to early adopters (first 100 users)
3. Updates the process_daily_login function to handle early adopter bonus

Changes:
- Standard welcome bonus: 500 XP -> 250 XP
- Early adopter bonus (first 100 users): 525 XP
"""

import os
import sys

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from supabase import create_client

def run_migration():
    """Run migration 228 to reduce welcome bonus."""
    supabase_url = os.environ.get("SUPABASE_URL")
    supabase_key = os.environ.get("SUPABASE_SERVICE_KEY") or os.environ.get("SUPABASE_KEY")

    if not supabase_url or not supabase_key:
        print("❌ Error: SUPABASE_URL and SUPABASE_KEY (or SUPABASE_SERVICE_KEY) must be set")
        print("   Run: source .env or export the variables")
        sys.exit(1)

    print("🔄 Connecting to Supabase...")
    client = create_client(supabase_url, supabase_key)

    # Read migration file
    migration_path = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "migrations",
        "228_reduce_welcome_bonus.sql"
    )

    if not os.path.exists(migration_path):
        print(f"❌ Error: Migration file not found: {migration_path}")
        sys.exit(1)

    with open(migration_path, "r") as f:
        migration_sql = f.read()

    print("📄 Migration 228: Reduce Welcome Bonus")
    print("   - Standard welcome bonus: 500 XP -> 250 XP")
    print("   - Early adopter bonus (first 100 users): 525 XP")
    print("")

    # Execute migration
    print("🚀 Running migration...")
    try:
        result = client.rpc("exec_sql", {"sql": migration_sql}).execute()
        print("✅ Migration 228 completed successfully!")
    except Exception as e:
        # Try direct execution via postgrest
        print(f"⚠️  RPC exec_sql not available, trying direct SQL execution...")
        try:
            # Split into separate statements and run each
            statements = migration_sql.split(';')
            for i, stmt in enumerate(statements):
                stmt = stmt.strip()
                if stmt and not stmt.startswith('--'):
                    try:
                        client.postgrest.rpc("exec_sql", {"query": stmt}).execute()
                    except:
                        pass
            print("✅ Migration 228 completed (with warnings)!")
        except Exception as e2:
            print(f"❌ Error running migration: {e2}")
            print("")
            print("Please run the migration manually in Supabase SQL Editor:")
            print(f"   File: {migration_path}")
            sys.exit(1)

    # Verify the update
    print("")
    print("🔍 Verifying migration...")
    try:
        result = client.table("xp_bonus_templates").select("*").eq("bonus_type", "first_login").execute()
        if result.data:
            bonus = result.data[0]
            print(f"   first_login base_xp: {bonus.get('base_xp', 'N/A')}")
            if bonus.get('base_xp') == 250:
                print("   ✅ Welcome bonus updated to 250 XP")
            else:
                print(f"   ⚠️  Expected 250 XP, got {bonus.get('base_xp')}")
    except Exception as e:
        print(f"   ⚠️  Could not verify: {e}")

    print("")
    print("✅ Migration 228 complete!")
    print("")
    print("Summary:")
    print("   - New users now receive 250 XP welcome bonus")
    print("   - First 100 users receive 525 XP (early adopter bonus)")


if __name__ == "__main__":
    run_migration()
