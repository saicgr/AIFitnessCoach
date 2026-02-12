#!/usr/bin/env python3
"""
Run migration 241 - Fix fuzzy_search_exercises_api return type.

Problem: Migration 240 changed the return type to SETOF exercise_library_cleaned,
which breaks PostgREST's schema cache. RPC calls fail silently, causing the
Python code to fall back to ILIKE (no typo tolerance).

Fix: Replace SETOF with explicit RETURNS TABLE(...) using the actual view columns,
queried dynamically from information_schema. This makes the function self-describing
so PostgREST doesn't need to resolve the view schema.
"""

import sys
import psycopg2


# Database connection (Supabase PostgreSQL)
DATABASE_HOST = "db.hpbzfahijszqmgsybuor.supabase.co"
DATABASE_PORT = 5432
DATABASE_NAME = "postgres"
DATABASE_USER = "postgres"
DATABASE_PASSWORD = "d2nHU5oLZ1GCz63B"


def get_view_columns(cur):
    """Get column names and exact types from exercise_library_cleaned view.

    Uses pg_catalog instead of information_schema to get the precise types
    (e.g., varchar(50) instead of just 'text'), which is required for
    RETURNS TABLE to match SELECT e.* exactly.
    """
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
    return cur.fetchall()


def run_migration():
    """Execute migration 241."""
    print("=" * 60)
    print("MIGRATION 241: Fix Fuzzy Search Return Type")
    print("=" * 60)
    print()
    print("This migration:")
    print("  - Reverts fuzzy_search_exercises_api from SETOF to RETURNS TABLE")
    print("  - Dynamically queries view columns for correct return type")
    print("  - Keeps equipment search logic from migration 240")
    print("  - Fixes PostgREST schema cache issue")
    print()
    print("Connecting to database...")

    try:
        conn = psycopg2.connect(
            host=DATABASE_HOST,
            port=DATABASE_PORT,
            dbname=DATABASE_NAME,
            user=DATABASE_USER,
            password=DATABASE_PASSWORD,
            sslmode="require"
        )
        print("Connected successfully!")

        with conn.cursor() as cur:
            # Step 1: Get view columns dynamically
            columns = get_view_columns(cur)
            if not columns:
                print("ERROR: Could not get columns from exercise_library_cleaned view")
                return False

            print(f"\nFound {len(columns)} columns in exercise_library_cleaned:")
            col_defs = []
            for col_name, col_type in columns:
                col_defs.append(f'    "{col_name}" {col_type}')
                print(f"  {col_name}: {col_type}")

            returns_clause = ",\n".join(col_defs)

            # Step 2: Build and execute DROP + CREATE
            sql = f"""
-- Drop the API function only (basic function return type is unchanged)
DROP FUNCTION IF EXISTS fuzzy_search_exercises_api(TEXT, TEXT, TEXT, INT);

-- Recreate with explicit RETURNS TABLE (fixes PostgREST schema cache issue)
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
            -- Name matching (trigram similarity or substring)
            similarity(LOWER(e.name), LOWER(search_term)) > 0.2
            OR LOWER(e.name) LIKE '%' || LOWER(search_term) || '%'
            -- Equipment matching (trigram similarity or substring)
            OR similarity(LOWER(COALESCE(e.equipment, '')), LOWER(search_term)) > 0.3
            OR LOWER(COALESCE(e.equipment, '')) LIKE '%' || LOWER(search_term) || '%'
        )
        -- Optional equipment filter
        AND (equipment_filter IS NULL OR LOWER(e.equipment) = LOWER(equipment_filter))
        -- Optional body part filter
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

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION fuzzy_search_exercises_api(TEXT, TEXT, TEXT, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION fuzzy_search_exercises_api(TEXT, TEXT, TEXT, INT) TO anon;
GRANT EXECUTE ON FUNCTION fuzzy_search_exercises_api(TEXT, TEXT, TEXT, INT) TO service_role;
"""

            print(f"\n{'=' * 60}")
            print("Executing migration SQL...")
            print("=" * 60)

            cur.execute(sql)

        conn.commit()
        print("SUCCESS: Function recreated with explicit RETURNS TABLE!")

        # Step 3: Verify
        print(f"\n{'=' * 60}")
        print("Verifying migration...")
        print("=" * 60)

        with conn.cursor() as cur:
            # Test "treadmill" (exact match)
            cur.execute("""
                SELECT name, equipment
                FROM fuzzy_search_exercises_api('treadmill', NULL, NULL, 10)
            """)
            rows = cur.fetchall()
            print(f"\n  fuzzy_search_exercises_api('treadmill'): {len(rows)} results")
            for name, equip in rows[:5]:
                print(f"    - {name} (equipment: {equip})")

            # Test "threadmill" (typo)
            cur.execute("""
                SELECT name, equipment
                FROM fuzzy_search_exercises_api('threadmill', NULL, NULL, 10)
            """)
            rows = cur.fetchall()
            print(f"\n  fuzzy_search_exercises_api('threadmill') [typo]: {len(rows)} results")
            for name, equip in rows[:5]:
                print(f"    - {name} (equipment: {equip})")

            # Test "benchpress" (typo, no space)
            cur.execute("""
                SELECT name, equipment
                FROM fuzzy_search_exercises_api('benchpress', NULL, NULL, 5)
            """)
            rows = cur.fetchall()
            print(f"\n  fuzzy_search_exercises_api('benchpress') [typo]: {len(rows)} results")
            for name, equip in rows[:5]:
                print(f"    - {name} (equipment: {equip})")

            # Verify return type is TABLE not SETOF
            cur.execute("""
                SELECT pg_get_function_result(p.oid)
                FROM pg_proc p
                JOIN pg_namespace n ON p.pronamespace = n.oid
                WHERE p.proname = 'fuzzy_search_exercises_api'
                  AND n.nspname = 'public'
            """)
            row = cur.fetchone()
            if row:
                result_type = row[0]
                print(f"\n  Function return type: TABLE(...) with {result_type.count(',') + 1} columns")
                if 'SETOF' in result_type.upper():
                    print("  WARNING: Still using SETOF - PostgREST issue NOT fixed!")
                else:
                    print("  OK: Using explicit TABLE return type (PostgREST compatible)")

        conn.close()
        print(f"\n{'=' * 60}")
        print("Migration 241 completed successfully!")
        print("=" * 60)
        return True

    except Exception as e:
        print(f"ERROR: {e}")
        import traceback
        traceback.print_exc()
        return False


if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
