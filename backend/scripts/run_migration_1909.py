#!/usr/bin/env python3
"""Run migration 1909 - Fix regional food names shadowing common English searches."""
import os
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
    file_path = migrations_dir / "1909_fix_regional_food_search_quality.sql"

    print("Running migration 1909: Fix regional food search quality...")
    try:
        conn = psycopg2.connect(
            host=DATABASE_HOST, port=DATABASE_PORT, dbname=DATABASE_NAME,
            user=DATABASE_USER, password=DATABASE_PASSWORD, sslmode="require"
        )
        with open(file_path, 'r') as f:
            sql = f.read()
        with conn.cursor() as cur:
            cur.execute(sql)
        conn.commit()

        # Verify fixes
        with conn.cursor() as cur:
            test_terms = [
                'coconut water', 'buttermilk', 'chickpea', 'roasted chickpeas',
                'naan bread', 'black beans', 'egg roll', 'lentil soup',
                'steamed rice', 'nariyal paani', 'chole', 'dal'
            ]
            for term in test_terms:
                cur.execute("""
                    SELECT food_name_normalized, display_name, region
                    FROM food_nutrition_overrides
                    WHERE is_active = TRUE
                    AND (food_name_normalized = %s OR %s = ANY(variant_names))
                    ORDER BY
                        CASE WHEN food_name_normalized = %s THEN 0 ELSE 1 END,
                        CASE WHEN region IS NULL THEN 0 ELSE 1 END,
                        CASE WHEN replace(food_name_normalized, '_', ' ') = %s THEN 0 ELSE 1 END,
                        CASE WHEN lower(display_name) LIKE '%%' || %s || '%%' THEN 0 ELSE 1 END,
                        length(display_name)
                    LIMIT 1
                """, (term, term, term, term, term))
                row = cur.fetchone()
                if row:
                    print(f"  '{term}' -> '{row[1]}' (region={row[2]})")

        conn.close()
        print("Migration 1909 applied successfully!")
    except Exception as e:
        print(f"Migration failed: {e}")
        raise

if __name__ == "__main__":
    run_migration()
