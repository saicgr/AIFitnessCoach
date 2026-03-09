#!/usr/bin/env python3
"""
Run migration 103 to fix exercise_library_cleaned data quality.

This migration:
1. Drops and recreates the exercise_library_cleaned view with NULL filters
2. Recreates dependent fuzzy search functions (dropped by CASCADE)
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

# Fuzzy search functions that depend on the view (from migrations 240+241)
FUZZY_SEARCH_BASIC_SQL = """
CREATE OR REPLACE FUNCTION fuzzy_search_exercises(
    search_term TEXT,
    limit_count INT DEFAULT 50
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    body_part TEXT,
    equipment TEXT,
    target_muscle TEXT,
    gif_url TEXT,
    video_url TEXT,
    similarity_score REAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        e.id,
        e.name,
        e.body_part,
        e.equipment,
        e.target_muscle,
        e.gif_url,
        e.video_url,
        GREATEST(
            similarity(LOWER(e.name), LOWER(search_term)),
            similarity(LOWER(COALESCE(e.equipment, '')), LOWER(search_term))
        ) as similarity_score
    FROM exercise_library_cleaned e
    WHERE
        similarity(LOWER(e.name), LOWER(search_term)) > 0.2
        OR LOWER(e.name) LIKE '%' || LOWER(search_term) || '%'
        OR similarity(LOWER(COALESCE(e.equipment, '')), LOWER(search_term)) > 0.3
        OR LOWER(COALESCE(e.equipment, '')) LIKE '%' || LOWER(search_term) || '%'
    ORDER BY
        CASE
            WHEN LOWER(e.name) = LOWER(search_term) THEN 0
            WHEN LOWER(e.name) LIKE LOWER(search_term) || '%' THEN 1
            WHEN LOWER(e.name) LIKE '%' || LOWER(search_term) || '%' THEN 2
            WHEN LOWER(COALESCE(e.equipment, '')) = LOWER(search_term) THEN 3
            WHEN LOWER(COALESCE(e.equipment, '')) LIKE '%' || LOWER(search_term) || '%' THEN 4
            ELSE 5
        END,
        GREATEST(
            similarity(LOWER(e.name), LOWER(search_term)),
            similarity(LOWER(COALESCE(e.equipment, '')), LOWER(search_term))
        ) DESC,
        e.name ASC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql STABLE SECURITY INVOKER;

GRANT EXECUTE ON FUNCTION fuzzy_search_exercises(TEXT, INT) TO authenticated;
"""


def build_api_function_sql(cur):
    """Build fuzzy_search_exercises_api with explicit RETURNS TABLE from view columns."""
    cur.execute("""
        SELECT a.attname AS column_name,
               format_type(a.atttypid, a.atttypmod) AS column_type
        FROM pg_attribute a
        JOIN pg_class c ON a.attrelid = c.oid
        JOIN pg_namespace n ON c.relnamespace = n.oid
        WHERE c.relname = 'exercise_library_cleaned'
          AND n.nspname = 'public'
          AND a.attnum > 0
          AND NOT a.attisdropped
        ORDER BY a.attnum
    """)
    columns = cur.fetchall()
    if not columns:
        return None

    col_defs = [f'    "{col_name}" {col_type}' for col_name, col_type in columns]
    returns_clause = ",\n".join(col_defs)

    return f"""
DROP FUNCTION IF EXISTS fuzzy_search_exercises_api(TEXT, TEXT, TEXT, INT);

CREATE FUNCTION fuzzy_search_exercises_api(
    search_term TEXT,
    equipment_filter TEXT DEFAULT NULL,
    body_part_filter TEXT DEFAULT NULL,
    limit_count INT DEFAULT 50
)
RETURNS TABLE (
{returns_clause}
) AS $$
BEGIN
    RETURN QUERY
    SELECT e.*
    FROM exercise_library_cleaned e
    WHERE
        (
            similarity(LOWER(e.name), LOWER(search_term)) > 0.2
            OR LOWER(e.name) LIKE '%' || LOWER(search_term) || '%'
            OR similarity(LOWER(COALESCE(e.equipment, '')), LOWER(search_term)) > 0.3
            OR LOWER(COALESCE(e.equipment, '')) LIKE '%' || LOWER(search_term) || '%'
        )
        AND (equipment_filter IS NULL OR LOWER(e.equipment) = LOWER(equipment_filter))
        AND (body_part_filter IS NULL OR LOWER(e.body_part) = LOWER(body_part_filter))
    ORDER BY
        CASE
            WHEN LOWER(e.name) = LOWER(search_term) THEN 0
            WHEN LOWER(e.name) LIKE LOWER(search_term) || '%' THEN 1
            WHEN LOWER(e.name) LIKE '%' || LOWER(search_term) || '%' THEN 2
            WHEN LOWER(COALESCE(e.equipment, '')) = LOWER(search_term) THEN 3
            WHEN LOWER(COALESCE(e.equipment, '')) LIKE '%' || LOWER(search_term) || '%' THEN 4
            ELSE 5
        END,
        GREATEST(
            similarity(LOWER(e.name), LOWER(search_term)),
            similarity(LOWER(COALESCE(e.equipment, '')), LOWER(search_term))
        ) DESC,
        e.name ASC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql STABLE SECURITY INVOKER;

GRANT EXECUTE ON FUNCTION fuzzy_search_exercises_api(TEXT, TEXT, TEXT, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION fuzzy_search_exercises_api(TEXT, TEXT, TEXT, INT) TO anon;
GRANT EXECUTE ON FUNCTION fuzzy_search_exercises_api(TEXT, TEXT, TEXT, INT) TO service_role;
"""


def main():
    print("=" * 60)
    print("MIGRATION 103: FIX EXERCISE LIBRARY CLEANED DATA QUALITY")
    print("=" * 60)
    print()

    if not DB_URL:
        print("[ERROR] DATABASE_URL not set")
        return 1

    migrations_dir = Path(__file__).parent.parent / "migrations"
    filepath = migrations_dir / "103_fix_exercise_library_cleaned_data_quality.sql"

    if not filepath.exists():
        print(f"[ERROR] Migration file not found: {filepath}")
        return 1

    with open(filepath) as f:
        sql_content = f.read()

    try:
        conn = psycopg2.connect(DB_URL)
        conn.autocommit = True
        cur = conn.cursor()

        # Step 1: Run the view migration (DROP CASCADE + CREATE)
        print("[1/3] Recreating exercise_library_cleaned view...")
        cur.execute(sql_content)
        print("  View recreated with NULL filters")

        # Step 2: Recreate basic fuzzy search function
        print("[2/3] Recreating fuzzy_search_exercises function...")
        cur.execute(FUZZY_SEARCH_BASIC_SQL)
        print("  Basic fuzzy search function restored")

        # Step 3: Recreate API fuzzy search function with dynamic columns
        print("[3/3] Recreating fuzzy_search_exercises_api function...")
        api_sql = build_api_function_sql(cur)
        if api_sql:
            cur.execute(api_sql)
            print("  API fuzzy search function restored")
        else:
            print("  [WARN] Could not detect view columns - API function not recreated")

        # Verify
        print()
        print("Verifying...")

        cur.execute("SELECT count(*) FROM exercise_library_cleaned WHERE body_part IS NULL")
        null_bp = cur.fetchone()[0]
        print(f"  NULL body_part: {null_bp}")

        cur.execute("SELECT count(*) FROM exercise_library_cleaned WHERE target_muscle IS NULL")
        null_tm = cur.fetchone()[0]
        print(f"  NULL target_muscle: {null_tm}")

        cur.execute("SELECT count(*) FROM exercise_library_cleaned")
        total = cur.fetchone()[0]
        print(f"  Total exercises: {total}")

        cur.execute("SELECT count(*) FROM exercise_library_cleaned WHERE LOWER(name) = 'major groups muscle body'")
        junk = cur.fetchone()[0]
        print(f"  Junk 'Major Groups Muscle Body': {'GONE' if junk == 0 else f'STILL PRESENT ({junk})'}")

        # Test fuzzy search still works
        cur.execute("SELECT name FROM fuzzy_search_exercises('bench press', 3)")
        rows = cur.fetchall()
        print(f"  Fuzzy search test ('bench press'): {[r[0] for r in rows]}")

        if null_bp == 0 and null_tm == 0:
            print()
            print("[OK] Migration 103 complete! Data quality filters working.")
        else:
            print()
            print("[WARN] Some NULL rows still present")

        cur.close()
        conn.close()
        return 0

    except Exception as e:
        print(f"[ERROR] {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())
