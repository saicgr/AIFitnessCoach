#!/usr/bin/env python3
"""Check current schema state."""

import psycopg2

DATABASE_HOST = "db.hpbzfahijszqmgsybuor.supabase.co"
DATABASE_PORT = 5432
DATABASE_NAME = "postgres"
DATABASE_USER = "postgres"
DATABASE_PASSWORD = "d2nHU5oLZ1GCz63B"

def main():
    conn = psycopg2.connect(
        host=DATABASE_HOST,
        port=DATABASE_PORT,
        dbname=DATABASE_NAME,
        user=DATABASE_USER,
        password=DATABASE_PASSWORD,
    )

    with conn.cursor() as cur:
        # Check cardio_sessions columns
        print("\n=== cardio_sessions columns ===")
        cur.execute("""
            SELECT column_name, data_type
            FROM information_schema.columns
            WHERE table_name = 'cardio_sessions' AND table_schema = 'public'
            ORDER BY ordinal_position;
        """)
        for row in cur.fetchall():
            print(f"  {row[0]}: {row[1]}")

        # Check exercise_variant_chains columns
        print("\n=== exercise_variant_chains columns ===")
        cur.execute("""
            SELECT column_name, data_type
            FROM information_schema.columns
            WHERE table_name = 'exercise_variant_chains' AND table_schema = 'public'
            ORDER BY ordinal_position;
        """)
        for row in cur.fetchall():
            print(f"  {row[0]}: {row[1]}")

        # Check user_exercise_mastery columns
        print("\n=== user_exercise_mastery columns ===")
        cur.execute("""
            SELECT column_name, data_type
            FROM information_schema.columns
            WHERE table_name = 'user_exercise_mastery' AND table_schema = 'public'
            ORDER BY ordinal_position;
        """)
        for row in cur.fetchall():
            print(f"  {row[0]}: {row[1]}")

        # Check workout_logs columns
        print("\n=== workout_logs columns ===")
        cur.execute("""
            SELECT column_name, data_type
            FROM information_schema.columns
            WHERE table_name = 'workout_logs' AND table_schema = 'public'
            ORDER BY ordinal_position;
        """)
        for row in cur.fetchall():
            print(f"  {row[0]}: {row[1]}")

        # Check if muscle_group_weekly_volume exists and what it is
        print("\n=== muscle_group_weekly_volume type ===")
        cur.execute("""
            SELECT table_type FROM information_schema.tables
            WHERE table_name = 'muscle_group_weekly_volume' AND table_schema = 'public';
        """)
        result = cur.fetchone()
        if result:
            print(f"  Type: {result[0]}")
        else:
            print("  Does not exist")

        # Check functions named get_exercises_for_muscle
        print("\n=== get_exercises_for_muscle functions ===")
        cur.execute("""
            SELECT routine_name, data_type, pg_get_function_arguments(p.oid)
            FROM information_schema.routines r
            JOIN pg_proc p ON p.proname = r.routine_name
            WHERE routine_name = 'get_exercises_for_muscle'
            AND routine_schema = 'public';
        """)
        for row in cur.fetchall():
            print(f"  {row[0]}({row[2]}) -> {row[1]}")

    conn.close()

if __name__ == "__main__":
    main()
