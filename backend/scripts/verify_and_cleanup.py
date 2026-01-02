#!/usr/bin/env python3
"""
Final verification and cleanup for migrations 077-108.
"""

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
        connect_timeout=30
    )

    print("\n" + "="*60)
    print("Migration Verification Report")
    print("="*60)

    # Add remaining missing columns
    print("\n--- Adding final missing columns ---")
    with conn.cursor() as cur:
        # user_exercise_mastery columns
        columns = [
            "ALTER TABLE user_exercise_mastery ADD COLUMN IF NOT EXISTS current_max_weight DECIMAL(8,2);",
            "ALTER TABLE user_exercise_mastery ADD COLUMN IF NOT EXISTS mastery_level TEXT DEFAULT 'beginner';",
            "ALTER TABLE user_exercise_mastery ADD COLUMN IF NOT EXISTS progression_status TEXT DEFAULT 'stable';",
        ]
        for sql in columns:
            try:
                cur.execute(sql)
                conn.commit()
            except Exception as e:
                conn.rollback()
                if "already exists" not in str(e).lower():
                    print(f"  Warning: {str(e)[:60]}")

    print("  Columns added (if missing)")

    # Check key tables from our migrations
    expected_tables = [
        'exercise_performance_summary',
        'workout_performance_summary',
        'skill_progressions',
        'skill_achievements',
        'flexibility_assessments',
        'user_milestones',
        'milestone_definitions',
        'quick_workouts',
        'quick_workout_templates',
        'branded_programs',
        'app_tour_sessions',
        'app_tour_steps',
        'window_mode_logs',
        'calibration_workouts',
        'strength_baselines',
        'superset_preferences',
        'user_superset_history',
        'neat_goals',
        'neat_daily_scores',
        'neat_streaks',
        'neat_achievements',
        'billing_notifications',
        'cancellation_requests',
        'support_tickets',
        'sound_preferences',
        'consistency_snapshots',
        'scheduling_preferences',
        'email_preferences',
    ]

    print("\n--- Checking key tables from migrations ---")
    with conn.cursor() as cur:
        existing = []
        missing = []
        for table in expected_tables:
            cur.execute(f"""
                SELECT EXISTS (
                    SELECT 1 FROM information_schema.tables
                    WHERE table_schema = 'public' AND table_name = '{table}'
                );
            """)
            exists = cur.fetchone()[0]
            if exists:
                existing.append(table)
            else:
                missing.append(table)

    print(f"\n  Existing tables ({len(existing)}):")
    for t in existing[:10]:
        print(f"    + {t}")
    if len(existing) > 10:
        print(f"    ... and {len(existing) - 10} more")

    if missing:
        print(f"\n  Missing tables ({len(missing)}):")
        for t in missing:
            print(f"    - {t}")

    # Check key functions
    expected_functions = [
        'get_previous_exercise_performance',
        'get_workout_comparison',
        'get_exercise_comparisons',
        'calculate_neat_score',
        'update_neat_streaks',
        'upsert_superset_preferences',
    ]

    print("\n--- Checking key functions ---")
    with conn.cursor() as cur:
        for func in expected_functions:
            cur.execute(f"""
                SELECT EXISTS (
                    SELECT 1 FROM information_schema.routines
                    WHERE routine_schema = 'public' AND routine_name = '{func}'
                );
            """)
            exists = cur.fetchone()[0]
            status = "+" if exists else "-"
            print(f"  {status} {func}")

    # Summary
    print("\n" + "="*60)
    print("SUMMARY")
    print("="*60)

    with conn.cursor() as cur:
        cur.execute("""
            SELECT count(*) FROM information_schema.tables
            WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
        """)
        total_tables = cur.fetchone()[0]

        cur.execute("""
            SELECT count(*) FROM information_schema.views
            WHERE table_schema = 'public';
        """)
        total_views = cur.fetchone()[0]

        cur.execute("""
            SELECT count(*) FROM information_schema.routines
            WHERE routine_schema = 'public' AND routine_type = 'FUNCTION';
        """)
        total_functions = cur.fetchone()[0]

    print(f"\n  Total PUBLIC tables: {total_tables}")
    print(f"  Total PUBLIC views: {total_views}")
    print(f"  Total PUBLIC functions: {total_functions}")

    print(f"\n  Expected tables present: {len(existing)}/{len(expected_tables)}")
    if missing:
        print(f"  Missing tables: {', '.join(missing)}")

    conn.close()

    print("\n" + "="*60)
    print("Verification complete!")
    print("="*60)


if __name__ == "__main__":
    main()
