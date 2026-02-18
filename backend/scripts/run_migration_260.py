#!/usr/bin/env python3
"""
Run migration 260 - Populate inflammatory_score and inflammatory_category
in food_database for all rows.

This migration:
  - Populates inflammatory_score (1-10) based on NOVA group, nutriscore,
    sugar/fiber content, name heuristics, and category
  - Populates inflammatory_category based on the computed score
  - Creates an index on inflammatory_score for lookup performance
  - Only updates rows where inflammatory_score IS NULL (idempotent)
"""

import sys
import psycopg2


DATABASE_HOST = "db.hpbzfahijszqmgsybuor.supabase.co"
DATABASE_PORT = 5432
DATABASE_NAME = "postgres"
DATABASE_USER = "postgres"
DATABASE_PASSWORD = "d2nHU5oLZ1GCz63B"


def run_migration():
    """Execute migration 260."""
    print("=" * 60)
    print("MIGRATION 260: Populate Inflammation Scores in food_database")
    print("=" * 60)
    print()
    print("This migration:")
    print("  - Populates inflammatory_score (1-10) for all food_database rows")
    print("  - Populates inflammatory_category based on score")
    print("  - Creates index on inflammatory_score")
    print("  - Only updates rows where inflammatory_score IS NULL")
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

        # Preview: count rows to be updated
        print(f"\n{'=' * 60}")
        print("Preview: Rows to be updated")
        print("=" * 60)

        with conn.cursor() as cur:
            cur.execute("SELECT COUNT(*) FROM food_database WHERE inflammatory_score IS NULL")
            null_score_count = cur.fetchone()[0]
            cur.execute("SELECT COUNT(*) FROM food_database")
            total_count = cur.fetchone()[0]
            cur.execute("SELECT COUNT(*) FROM food_database WHERE inflammatory_score IS NOT NULL")
            existing_count = cur.fetchone()[0]
            print(f"  Total food_database rows: {total_count}")
            print(f"  Already have inflammatory_score: {existing_count}")
            print(f"  Need inflammatory_score: {null_score_count}")

        if null_score_count == 0:
            print("\n  No rows need updating. Migration is a no-op.")
            conn.close()
            return True

        # Execute migration
        print(f"\n{'=' * 60}")
        print("Executing migration SQL...")
        print("=" * 60)

        with open("backend/migrations/260_populate_inflammation_scores.sql", "r") as f:
            sql = f.read()

        with conn.cursor() as cur:
            cur.execute(sql)
            print(f"  SQL executed successfully")

        conn.commit()
        print("SUCCESS: Migration applied!")

        # Verify
        print(f"\n{'=' * 60}")
        print("Verifying...")
        print("=" * 60)

        with conn.cursor() as cur:
            # Check counts by category
            cur.execute("""
                SELECT inflammatory_category, COUNT(*) as cnt
                FROM food_database
                WHERE inflammatory_category IS NOT NULL
                GROUP BY inflammatory_category
                ORDER BY cnt DESC
            """)
            print("  Distribution by category:")
            for category, count in cur.fetchall():
                print(f"    {category}: {count}")

            # Check remaining nulls
            cur.execute("SELECT COUNT(*) FROM food_database WHERE inflammatory_score IS NULL")
            remaining = cur.fetchone()[0]
            print(f"\n  Remaining NULL inflammatory_score: {remaining}")

            # Sample some results
            cur.execute("""
                SELECT name, inflammatory_score, inflammatory_category
                FROM food_database
                WHERE inflammatory_score IS NOT NULL
                ORDER BY RANDOM()
                LIMIT 10
            """)
            print("\n  Sample results:")
            for name, score, category in cur.fetchall():
                print(f"    {name[:50]:50s} -> score={score}, cat={category}")

        conn.close()
        print(f"\n{'=' * 60}")
        print("Migration 260 completed successfully!")
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
