#!/usr/bin/env python3
"""
Run migrations 158 and 159 - Clean exercise names and fuzzy search.

158: Creates exercise_library_cleaned view with clean names
159: Adds pg_trgm extension and fuzzy search function
"""

import sys
from pathlib import Path

import psycopg2


# Database connection
DATABASE_HOST = "db.hpbzfahijszqmgsybuor.supabase.co"
DATABASE_PORT = 5432
DATABASE_NAME = "postgres"
DATABASE_USER = "postgres"
DATABASE_PASSWORD = "d2nHU5oLZ1GCz63B"


def run_migrations():
    """Execute migrations 158 and 159."""
    migrations_dir = Path(__file__).parent.parent / "migrations"

    migrations = [
        ("158_clean_exercise_names.sql", "Clean exercise names view"),
        ("159_fuzzy_exercise_search.sql", "Fuzzy search with pg_trgm"),
    ]

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

        for migration_file, description in migrations:
            file_path = migrations_dir / migration_file

            if not file_path.exists():
                print(f"ERROR: Migration file not found: {file_path}")
                continue

            print(f"\n{'=' * 60}")
            print(f"Running migration: {migration_file}")
            print(f"Description: {description}")
            print("=" * 60)

            with open(file_path, 'r') as f:
                sql_content = f.read()

            try:
                with conn.cursor() as cur:
                    cur.execute(sql_content)
                conn.commit()
                print(f"SUCCESS: {migration_file} completed!")
            except Exception as e:
                print(f"ERROR in {migration_file}: {e}")
                conn.rollback()

        # Verify view was created
        print("\n" + "=" * 60)
        print("Verifying exercise_library_cleaned view...")
        print("=" * 60)

        with conn.cursor() as cur:
            cur.execute("""
                SELECT COUNT(*) FROM exercise_library_cleaned
            """)
            count = cur.fetchone()[0]
            print(f"exercise_library_cleaned has {count} exercises")

            # Show sample of cleaned names
            cur.execute("""
                SELECT name, original_name
                FROM exercise_library_cleaned
                WHERE original_name LIKE '%Male%' OR original_name LIKE '%360%'
                LIMIT 5
            """)
            samples = cur.fetchall()
            if samples:
                print("\nSample cleaned names:")
                for clean, original in samples:
                    print(f"  '{original}' -> '{clean}'")

        # Verify fuzzy search function
        print("\n" + "=" * 60)
        print("Testing fuzzy search function...")
        print("=" * 60)

        try:
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT name, similarity_score
                    FROM fuzzy_search_exercises('benchpress', 5)
                """)
                results = cur.fetchall()
                if results:
                    print("Fuzzy search for 'benchpress':")
                    for name, score in results:
                        print(f"  {name} (similarity: {score:.2f})")
                else:
                    print("No results for 'benchpress'")
        except Exception as e:
            print(f"Fuzzy search test failed: {e}")

        conn.close()
        return True

    except Exception as e:
        print(f"ERROR: {e}")
        return False


if __name__ == "__main__":
    success = run_migrations()
    sys.exit(0 if success else 1)
