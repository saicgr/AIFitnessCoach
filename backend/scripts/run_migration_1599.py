#!/usr/bin/env python3
"""Run migration 1599 - Add 'large' variant names to Sam's Club pizza entries."""
import os, sys
from pathlib import Path
import psycopg2

DATABASE_HOST = os.environ.get("DATABASE_HOST", "db.hpbzfahijszqmgsybuor.supabase.co")
DATABASE_PORT = int(os.environ.get("DATABASE_PORT", 5432))
DATABASE_NAME = os.environ.get("DATABASE_NAME", "postgres")
DATABASE_USER = os.environ.get("DATABASE_USER", "postgres")
DATABASE_PASSWORD = os.environ.get("DATABASE_PASSWORD") or os.environ.get("SUPABASE_DB_PASSWORD")
if not DATABASE_PASSWORD:
    raise SystemExit("DATABASE_PASSWORD or SUPABASE_DB_PASSWORD environment variable is required")

def run_migration():
    migrations_dir = Path(__file__).parent.parent / "migrations"
    file_path = migrations_dir / "1599_add_sams_club_pizza_variants.sql"

    print("Running migration 1599: Add 'large' variant names to Sam's Club pizza entries...")
    try:
        conn = psycopg2.connect(
            host=DATABASE_HOST, port=DATABASE_PORT, dbname=DATABASE_NAME,
            user=DATABASE_USER, password=DATABASE_PASSWORD, sslmode="require"
        )
        with open(file_path, 'r') as f:
            sql = f.read()

        # Execute all statements
        with conn.cursor() as cur:
            cur.execute(sql)
        conn.commit()

        # Verify: check variant_names for the three pizza entries
        with conn.cursor() as cur:
            cur.execute("""
                SELECT food_name_normalized, variant_names
                FROM food_nutrition_overrides
                WHERE food_name_normalized IN (
                    'sams_club_combo_pizza_slice',
                    'sams_club_pepperoni_pizza_slice',
                    'sams_club_cheese_pizza_slice'
                )
                ORDER BY food_name_normalized
            """)
            rows = cur.fetchall()
            print(f"\nVerification - {len(rows)} rows found:")
            for name, variants in rows:
                large_variants = [v for v in (variants or []) if 'large' in v.lower()]
                print(f"  {name}: {len(variants or [])} total variants, {len(large_variants)} with 'large'")
                for lv in large_variants:
                    print(f"    - {lv}")

        conn.close()
        print("\nSUCCESS: Migration 1599 complete.")
        return True
    except Exception as e:
        print(f"ERROR: {e}")
        return False

if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
