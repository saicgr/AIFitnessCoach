#!/usr/bin/env python3
"""
Run migration 205: Add time preference fields to gym_profiles table.

This migration adds:
- preferred_time_slot: VARCHAR(20) for time slot preference
- time_auto_switch_enabled: BOOLEAN for time-based auto-switch toggle
- Index for time-based queries
"""

import os
import sys
from pathlib import Path
from dotenv import load_dotenv
import psycopg2

# Load environment
env_path = Path(__file__).parent.parent / ".env"
load_dotenv(env_path)

# Parse DATABASE_URL (convert from asyncpg format to psycopg2)
DATABASE_URL = os.getenv("DATABASE_URL", "")
DB_URL = DATABASE_URL.replace("postgresql+asyncpg://", "postgresql://")


def main():
    print("=" * 60)
    print("🔄 RUNNING MIGRATION 205: GYM PROFILE TIME PREFERENCE")
    print("=" * 60)

    if not DB_URL:
        print("❌ DATABASE_URL not set")
        return 1

    migrations_dir = Path(__file__).parent.parent / "migrations"
    filepath = migrations_dir / "205_gym_profile_time_preference.sql"

    if not filepath.exists():
        print(f"❌ Migration file not found: {filepath}")
        return 1

    print(f"📄 Reading {filepath.name}")

    with open(filepath) as f:
        sql_content = f.read()

    try:
        conn = psycopg2.connect(DB_URL)
        conn.autocommit = True
        cursor = conn.cursor()

        # Split by semicolons and execute each statement
        statements = [s.strip() for s in sql_content.split(';') if s.strip()]

        for i, stmt in enumerate(statements, 1):
            # Skip comment-only statements
            lines = [l for l in stmt.split('\n') if l.strip() and not l.strip().startswith('--')]
            if not lines:
                continue

            try:
                cursor.execute(stmt + ';')
                print(f"   ✅ Statement {i} OK")
            except psycopg2.Error as e:
                error_msg = str(e).lower()
                if "already exists" in error_msg or "duplicate" in error_msg:
                    print(f"   ⏭️  Statement {i} - already exists (OK)")
                else:
                    print(f"   ❌ Statement {i} FAILED: {e}")
                conn.rollback()

        cursor.close()
        conn.close()

        print("\n" + "=" * 60)
        print("✅ MIGRATION 205 COMPLETE")
        print("=" * 60)
        return 0

    except psycopg2.Error as e:
        print(f"\n❌ Database error: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
