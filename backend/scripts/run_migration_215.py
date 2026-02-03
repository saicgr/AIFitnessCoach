#!/usr/bin/env python3
"""
Run migration 215: Sync initial weight from onboarding to body_measurements.

This migration:
1. Creates a trigger that automatically inserts a body_measurements entry
   when a user's weight_kg is first set during onboarding
2. Backfills existing users who have weight but no body_measurements records
"""

import os
from pathlib import Path
from dotenv import load_dotenv

# Load environment
env_path = Path(__file__).parent.parent / ".env"
load_dotenv(env_path)

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_KEY") or os.getenv("SUPABASE_KEY")


def main():
    from supabase import create_client

    print("=" * 60)
    print("🔄 RUNNING MIGRATION 215")
    print("   Sync Initial Weight to body_measurements")
    print("=" * 60)

    client = create_client(SUPABASE_URL, SUPABASE_KEY)
    migrations_dir = Path(__file__).parent.parent / "migrations"
    filepath = migrations_dir / "215_sync_initial_weight_to_body_measurements.sql"

    if not filepath.exists():
        print(f"❌ Migration file not found: {filepath}")
        return

    with open(filepath) as f:
        sql = f.read()

    # Split into logical blocks (functions, triggers, inserts)
    # We need smarter splitting for $$ blocks
    blocks = []
    current_block = []
    in_function = False

    for line in sql.split('\n'):
        current_block.append(line)

        # Track function/trigger blocks (they use $$)
        if '$$' in line:
            in_function = not in_function

        # End of statement (semicolon outside function)
        if line.strip().endswith(';') and not in_function:
            block = '\n'.join(current_block).strip()
            if block and not block.startswith('--'):
                blocks.append(block)
            current_block = []

    print(f"\n📄 Found {len(blocks)} SQL blocks to execute\n")

    for i, block in enumerate(blocks):
        # Skip pure comment blocks
        if all(line.strip().startswith('--') or not line.strip() for line in block.split('\n')):
            continue

        # Get first non-comment line for description
        desc = next((line.strip() for line in block.split('\n')
                    if line.strip() and not line.strip().startswith('--')), 'Unknown')[:60]

        try:
            # Execute via RPC
            result = client.rpc('exec_sql', {'query': block}).execute()
            print(f"✅ Block {i+1}: {desc}...")
        except Exception as e:
            error_str = str(e)
            if "already exists" in error_str.lower():
                print(f"⏭️  Block {i+1}: Already exists - {desc}...")
            elif "does not exist" in error_str.lower():
                print(f"⏭️  Block {i+1}: Does not exist (OK) - {desc}...")
            else:
                print(f"❌ Block {i+1} FAILED: {desc}...")
                print(f"   Error: {error_str[:200]}")

    print("\n" + "=" * 60)
    print("✅ MIGRATION 215 COMPLETE")
    print("=" * 60)
    print("\nWhat this does:")
    print("• New users: Weight from onboarding auto-creates body_measurements entry")
    print("• Existing users: Backfilled body_measurements from their profile data")
    print("\nNote: If exec_sql RPC is not available, run the SQL manually in Supabase SQL Editor.")


if __name__ == "__main__":
    main()
