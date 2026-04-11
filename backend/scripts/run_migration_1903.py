#!/usr/bin/env python3
"""Run migration 1903 - Add 'Walk After Eating' habit template."""
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
    file_path = migrations_dir / "1903_add_walk_after_eating_habit_template.sql"

    print("Running migration 1903: Add 'Walk After Eating' habit template...")
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

        # Verify it was inserted
        with conn.cursor() as cur:
            cur.execute("""
                SELECT id, name, category, suggested_target, unit
                FROM habit_templates
                WHERE name ILIKE '%walk after%'
            """)
            rows = cur.fetchall()
            if rows:
                for row in rows:
                    print(f"  SUCCESS: id={row[0]}, name='{row[1]}', category={row[2]}, target={row[3]} {row[4]}")
            else:
                print("  WARNING: Template not found after insert")

        conn.close()
        print("Done!")
    except Exception as e:
        print(f"FAILED: {e}")
        raise

if __name__ == "__main__":
    run_migration()
