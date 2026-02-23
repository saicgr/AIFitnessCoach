#!/usr/bin/env python3
"""
Final verification of all migrations 077-108.
"""

import os
import psycopg2

DATABASE_HOST = "db.hpbzfahijszqmgsybuor.supabase.co"
DATABASE_PORT = 5432
DATABASE_NAME = "postgres"
DATABASE_USER = "postgres"
DATABASE_PASSWORD = os.environ.get("DATABASE_PASSWORD")
if not DATABASE_PASSWORD:
    raise SystemExit("DATABASE_PASSWORD environment variable is required")


def main():
    conn = psycopg2.connect(
        host=DATABASE_HOST,
        port=DATABASE_PORT,
        dbname=DATABASE_NAME,
        user=DATABASE_USER,
        password=DATABASE_PASSWORD,
        connect_timeout=30
    )

    print("\n" + "="*70)
    print("FINAL MIGRATION VERIFICATION (077-108)")
    print("="*70)

    # Tables that SHOULD exist from our migrations
    migration_tables = {
        "077": ["exercise_performance_summary", "workout_performance_summary"],
        "078": [],  # Adds columns
        "079": ["billing_notifications", "subscription_transparency_settings", "support_tickets"],
        "080": [],  # Adds columns
        "081": ["exercise_progression_chains", "exercise_progression_steps", "user_skill_progress"],
        "082": ["flexibility_assessments", "cancellation_requests"],
        "083": ["break_detection_history", "comeback_history"],
        "084": [],  # Adds columns
        "085": ["feedback_difficulty_adjustments"],
        "086": [],  # Adds columns
        "087": ["set_adjustments"],
        "088": ["email_preferences"],
        "089": ["cardio_sessions", "exercise_progression_mastery"],
        "090": ["user_rep_range_preferences", "trial_demo_sessions"],
        "091": ["audio_preferences", "rep_accuracy_logs"],
        "092": [],  # Adds columns
        "093": ["sound_preferences"],
        "094": ["exercise_swap_history"],
        "095": ["hiit_workouts", "hiit_intervals"],
        "096": [],  # Views/functions
        "097": ["subjective_feedback", "generated_workouts"],
        "098": ["consistency_metrics"],
        "099": ["scheduling_settings"],
        "100": ["user_milestones", "milestone_definitions", "enhanced_trial_tracking"],
        "101": ["branded_programs", "quick_workout_logs"],
        "102": ["app_tour_sessions", "lifetime_membership_tracking"],
        "103": [],  # Seeds program data
        "104": ["window_mode_logs"],
        "105": [],  # Adds event types
        "106": ["subscription_management_logs"],
        "107": ["calibration_workouts", "strength_baselines", "neat_goals", "neat_daily_scores", "neat_streaks", "neat_achievements"],
        "108": ["superset_preferences", "user_superset_history", "favorite_superset_pairs"],
    }

    all_expected = []
    for tables in migration_tables.values():
        all_expected.extend(tables)

    print(f"\nChecking {len(all_expected)} tables from migrations...")

    with conn.cursor() as cur:
        existing = []
        missing = []
        for table in all_expected:
            cur.execute(f"""
                SELECT EXISTS (
                    SELECT 1 FROM information_schema.tables
                    WHERE table_schema = 'public' AND table_name = '{table}'
                );
            """)
            if cur.fetchone()[0]:
                existing.append(table)
            else:
                missing.append(table)

    print(f"\n  EXISTING ({len(existing)}):")
    for t in sorted(existing):
        print(f"    + {t}")

    if missing:
        print(f"\n  MISSING ({len(missing)}):")
        for t in sorted(missing):
            print(f"    - {t}")

    # Check key functions
    print("\n--- Key Functions ---")
    functions = [
        "get_previous_exercise_performance",
        "get_workout_comparison",
        "get_exercise_comparisons",
        "calculate_neat_score",
        "update_daily_neat_score",
        "update_neat_streaks",
        "check_neat_achievements",
        "upsert_superset_preferences",
        "record_superset_completion",
        "calculate_estimated_1rm",
    ]

    with conn.cursor() as cur:
        for func in functions:
            cur.execute(f"""
                SELECT EXISTS (
                    SELECT 1 FROM information_schema.routines
                    WHERE routine_schema = 'public' AND routine_name = '{func}'
                );
            """)
            exists = cur.fetchone()[0]
            status = "+" if exists else "-"
            print(f"  {status} {func}")

    # Check key views
    print("\n--- Key Views ---")
    views = [
        "cardio_session_analytics",
        "neat_user_dashboard",
        "superset_analytics",
        "latest_calibration_workout",
        "calibration_summary",
    ]

    with conn.cursor() as cur:
        for view in views:
            cur.execute(f"""
                SELECT EXISTS (
                    SELECT 1 FROM information_schema.views
                    WHERE table_schema = 'public' AND table_name = '{view}'
                );
            """)
            exists = cur.fetchone()[0]
            status = "+" if exists else "-"
            print(f"  {status} {view}")

    # Final counts
    print("\n" + "="*70)
    print("OVERALL STATISTICS")
    print("="*70)

    with conn.cursor() as cur:
        cur.execute("""
            SELECT count(*) FROM information_schema.tables
            WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
        """)
        print(f"  Total tables: {cur.fetchone()[0]}")

        cur.execute("""
            SELECT count(*) FROM information_schema.views
            WHERE table_schema = 'public';
        """)
        print(f"  Total views: {cur.fetchone()[0]}")

        cur.execute("""
            SELECT count(*) FROM information_schema.routines
            WHERE routine_schema = 'public' AND routine_type = 'FUNCTION';
        """)
        print(f"  Total functions: {cur.fetchone()[0]}")

    success_rate = len(existing) / len(all_expected) * 100 if all_expected else 100
    print(f"\n  Migration success rate: {success_rate:.1f}% ({len(existing)}/{len(all_expected)} tables)")

    conn.close()

    print("\n" + "="*70)
    print("MIGRATION STATUS: " + ("COMPLETE" if not missing else "MOSTLY COMPLETE"))
    print("="*70 + "\n")


if __name__ == "__main__":
    main()
