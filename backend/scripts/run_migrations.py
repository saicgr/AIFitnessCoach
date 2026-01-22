#!/usr/bin/env python3
"""
Run pending migrations for program variants.
Migrations: 169, 174, 176, 181
"""

import os
from pathlib import Path
from dotenv import load_dotenv

# Load environment
env_path = Path(__file__).parent.parent / ".env"
load_dotenv(env_path)

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

MIGRATIONS = [
    ("169_hyrox_race_prep.sql", "HYROX Race Prep Program"),
    ("174_extend_duration_weeks.sql", "Extend duration_weeks constraint"),
    ("176_add_sessions_to_unique_constraint.sql", "Add sessions to unique constraint"),
    ("181_update_program_variants_fk.sql", "Update FK to branded_programs"),
]


def main():
    from supabase import create_client

    print("=" * 60)
    print("🔄 RUNNING MIGRATIONS")
    print("=" * 60)
    print(f"Database: {SUPABASE_URL}")

    client = create_client(SUPABASE_URL, SUPABASE_KEY)
    migrations_dir = Path(__file__).parent.parent / "migrations"

    for filename, description in MIGRATIONS:
        filepath = migrations_dir / filename

        if not filepath.exists():
            print(f"\n⚠️  {filename} - NOT FOUND")
            continue

        print(f"\n📄 {filename}")
        print(f"   {description}")

        with open(filepath) as f:
            sql = f.read()

        # Split into statements (simple split by semicolon)
        statements = [s.strip() for s in sql.split(';') if s.strip() and not s.strip().startswith('--')]

        for i, stmt in enumerate(statements):
            if not stmt or stmt.startswith('--'):
                continue
            try:
                # Use raw SQL execution via postgrest
                result = client.rpc('exec_sql', {'query': stmt}).execute()
                print(f"   ✅ Statement {i+1} OK")
            except Exception as e:
                error_str = str(e)
                if "already exists" in error_str.lower():
                    print(f"   ⏭️  Statement {i+1} - already exists")
                elif "does not exist" in error_str.lower() and "constraint" in error_str.lower():
                    print(f"   ⏭️  Statement {i+1} - constraint doesn't exist (OK)")
                else:
                    print(f"   ❌ Statement {i+1} FAILED: {error_str[:100]}")

    print("\n" + "=" * 60)
    print("✅ MIGRATIONS COMPLETE")
    print("=" * 60)
    print("\nNote: If exec_sql RPC is not available, run the SQL manually in Supabase.")


if __name__ == "__main__":
    main()
