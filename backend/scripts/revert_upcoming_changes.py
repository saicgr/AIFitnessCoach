#!/usr/bin/env python3
"""Revert the upcoming programs database changes."""

import os
import psycopg2
from pathlib import Path
from dotenv import load_dotenv

# Load environment
env_path = Path(__file__).parent.parent / ".env"
load_dotenv(env_path)

DB_PASSWORD = os.getenv("SUPABASE_DB_PASSWORD")
SUPABASE_URL = os.getenv("SUPABASE_URL")

# Extract host from URL
db_host = SUPABASE_URL.replace("https://", "").replace(".supabase.co", "") + ".supabase.co"
db_host = f"db.{db_host.split('.')[0]}.supabase.co"

def revert_changes():
    """Remove status column and app_programs view."""
    conn = psycopg2.connect(
        host=db_host,
        database="postgres",
        user="postgres",
        password=DB_PASSWORD,
        port=5432
    )
    conn.autocommit = True
    cur = conn.cursor()

    print("=== Reverting Upcoming Programs Changes ===\n")

    # Step 1: Drop app_programs view
    print("1. Dropping app_programs view...")
    cur.execute("DROP VIEW IF EXISTS app_programs CASCADE;")
    print("   ✅ View dropped\n")

    # Step 2: Drop status column from program_variants
    print("2. Removing status column from program_variants...")
    cur.execute("""
        ALTER TABLE program_variants
        DROP COLUMN IF EXISTS status;
    """)
    print("   ✅ Status column removed\n")

    # Verify
    print("=== Verification ===\n")

    # Check that status column is gone
    cur.execute("""
        SELECT column_name
        FROM information_schema.columns
        WHERE table_name = 'program_variants'
        AND column_name = 'status';
    """)

    if cur.fetchone() is None:
        print("✅ Status column successfully removed from program_variants")
    else:
        print("❌ Status column still exists")

    # Check that app_programs view is gone
    cur.execute("""
        SELECT table_name
        FROM information_schema.views
        WHERE table_name = 'app_programs';
    """)

    if cur.fetchone() is None:
        print("✅ app_programs view successfully removed")
    else:
        print("❌ app_programs view still exists")

    print("\n" + "="*60)
    print("✅ Database reverted to original state")
    print("="*60)
    print("\nYou can now handle 'coming soon' purely in the Flutter UI")
    print("Use program_exercises_with_media view for queries")

    cur.close()
    conn.close()

if __name__ == "__main__":
    revert_changes()
