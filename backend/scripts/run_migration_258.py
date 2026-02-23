#!/usr/bin/env python3
"""
Run migration 258 - Fix nutrition_goal for users whose weight_direction contradicts their stored goal.

- Updates nutrition_preferences.nutrition_goal to match users.preferences.weight_direction
- Affects users who have weight_direction='lose' or 'gain' but nutrition_goal='maintain'
"""

import os
import sys
import psycopg2


DATABASE_HOST = "db.hpbzfahijszqmgsybuor.supabase.co"
DATABASE_PORT = 5432
DATABASE_NAME = "postgres"
DATABASE_USER = "postgres"
DATABASE_PASSWORD = os.environ.get("DATABASE_PASSWORD")
if not DATABASE_PASSWORD:
    raise SystemExit("DATABASE_PASSWORD environment variable is required")


def run_migration():
    """Execute migration 258."""
    print("=" * 60)
    print("MIGRATION 258: Fix Nutrition Goals")
    print("=" * 60)
    print()
    print("This migration:")
    print("  - Fixes nutrition_goal for users where weight_direction contradicts stored goal")
    print("  - 'lose' weight_direction -> 'lose_fat' nutrition_goal")
    print("  - 'gain' weight_direction -> 'build_muscle' nutrition_goal")
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

        # Preview affected rows
        print(f"\n{'=' * 60}")
        print("Preview: Users to be updated")
        print("=" * 60)

        with conn.cursor() as cur:
            cur.execute("""
                SELECT np.user_id, np.nutrition_goal, np.nutrition_goals,
                       u.preferences->>'weight_direction' as weight_direction
                FROM nutrition_preferences np
                JOIN users u ON np.user_id = u.id
                WHERE np.nutrition_goal = 'maintain'
                  AND u.preferences->>'weight_direction' IN ('lose', 'gain')
            """)
            rows = cur.fetchall()
            print(f"  Found {len(rows)} user(s) to update:")
            for user_id, goal, goals, direction in rows:
                print(f"    - {user_id}: {goal} -> {'lose_fat' if direction == 'lose' else 'build_muscle'} (weight_direction={direction})")

        if not rows:
            print("\n  No users need updating. Migration is a no-op.")
            conn.close()
            return True

        # Execute migration
        print(f"\n{'=' * 60}")
        print("Executing migration SQL...")
        print("=" * 60)

        with open("backend/migrations/258_fix_nutrition_goals.sql", "r") as f:
            sql = f.read()

        with conn.cursor() as cur:
            cur.execute(sql)
            print(f"  Rows updated: {cur.rowcount}")

        conn.commit()
        print("SUCCESS: Migration applied!")

        # Verify
        print(f"\n{'=' * 60}")
        print("Verifying...")
        print("=" * 60)

        with conn.cursor() as cur:
            cur.execute("""
                SELECT np.user_id, np.nutrition_goal, np.nutrition_goals,
                       u.preferences->>'weight_direction' as weight_direction
                FROM nutrition_preferences np
                JOIN users u ON np.user_id = u.id
                WHERE u.preferences->>'weight_direction' IN ('lose', 'gain')
                LIMIT 10
            """)
            for user_id, goal, goals, direction in cur.fetchall():
                status = "OK" if (
                    (direction == 'lose' and goal == 'lose_fat') or
                    (direction == 'gain' and goal == 'build_muscle')
                ) else "MISMATCH"
                print(f"  {user_id}: goal={goal}, direction={direction} [{status}]")

        conn.close()
        print(f"\n{'=' * 60}")
        print("Migration 258 completed successfully!")
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
