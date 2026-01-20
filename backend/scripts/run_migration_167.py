#!/usr/bin/env python3
"""
Run migration 167 to rebalance early XP levels.

This migration changes the XP requirements for levels 1-10 from flat 1000 XP
to a gradual curve starting at 100 XP for level 2.

New Level Progression:
- Level 2: 100 XP (cumulative: 100)
- Level 3: 150 XP (cumulative: 250)
- Level 4: 200 XP (cumulative: 450)
- Level 5: 300 XP (cumulative: 750)
- Level 6: 400 XP (cumulative: 1,150)
- Level 7: 500 XP (cumulative: 1,650)
- Level 8: 650 XP (cumulative: 2,300)
- Level 9: 800 XP (cumulative: 3,100)
- Level 10: 1,000 XP (cumulative: 4,100)

This makes early levels much more achievable for new users.
"""

import os
import sys

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from supabase import create_client

def run_migration():
    """Run migration 167 to rebalance early XP levels."""
    supabase_url = os.environ.get("SUPABASE_URL")
    supabase_key = os.environ.get("SUPABASE_SERVICE_KEY")

    if not supabase_url or not supabase_key:
        print("❌ Error: SUPABASE_URL and SUPABASE_SERVICE_KEY must be set")
        print("   Run: source .env or export the variables")
        sys.exit(1)

    print("🔄 Connecting to Supabase...")
    client = create_client(supabase_url, supabase_key)

    # Read the migration SQL
    migration_path = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "migrations",
        "167_xp_early_levels_rebalance.sql"
    )

    print(f"📄 Reading migration from: {migration_path}")
    with open(migration_path, "r") as f:
        migration_sql = f.read()

    print("🚀 Running migration 167: XP Early Levels Rebalance...")

    try:
        # Execute the migration
        result = client.postgrest.rpc("exec_sql", {"sql": migration_sql}).execute()
        print("✅ Migration completed successfully!")
        print("\n📊 New XP Level Curve (Levels 1-10):")
        print("   Level 2:  100 XP")
        print("   Level 3:  150 XP")
        print("   Level 4:  200 XP")
        print("   Level 5:  300 XP")
        print("   Level 6:  400 XP")
        print("   Level 7:  500 XP")
        print("   Level 8:  650 XP")
        print("   Level 9:  800 XP")
        print("   Level 10: 1,000 XP")
        print("\n   Total XP for Level 10: 4,100 XP (down from 10,000)")

    except Exception as e:
        # If exec_sql doesn't exist, try running directly via postgres
        print(f"⚠️  RPC exec_sql not available, this is expected.")
        print("   Please run the migration manually in Supabase SQL Editor:")
        print(f"   File: {migration_path}")
        print("\n   Or run via psql:")
        print(f"   psql $DATABASE_URL -f {migration_path}")

if __name__ == "__main__":
    run_migration()
