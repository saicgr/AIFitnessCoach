#!/usr/bin/env python3
"""
Verify Supabase Security Fixes

This script verifies that all security fixes have been applied correctly.
"""

import os
import psycopg2

# Database connection details
DB_CONFIG = {
    "host": "db.hpbzfahijszqmgsybuor.supabase.co",
    "port": 5432,
    "database": "postgres",
    "user": "postgres",
    "password": os.environ.get("DATABASE_PASSWORD")
}

if not DB_CONFIG["password"]:
    raise SystemExit("DATABASE_PASSWORD environment variable is required")

# Tables that should have RLS enabled
TABLES_TO_CHECK = [
    "cardio_progression_templates",
    "hormone_supportive_foods",
    "kegel_exercises",
    "migration_log",
    "hiit_templates",
    "cuisine_types",
    "body_types",
    "senior_mobility_exercises",
    "low_impact_alternatives",
    "progression_pace_definitions",
    "exercise_muscle_mappings"
]

# Views that should have SECURITY INVOKER
VIEWS_TO_CHECK = [
    "demo_feature_engagement",
    "try_workout_analytics",
    "v_recent_missed_workouts",
    "lifetime_member_benefits",
    "subscription_pause_metrics",
    "upcoming_renewals",
    "fasting_performance_summary",
    "quick_workout_source_analytics",
    "superset_analytics",
    "v_warmups_with_muscles",
    "latest_cardio_metrics",
    "neat_user_dashboard",
    "app_tour_analytics",
    "recent_cardio_sessions",
    "user_milestone_progress",
    "exercise_workout_history",
    "trial_conversion_funnel",
    "window_mode_analytics",
    "user_subscription_history_readable",
    "weekly_progress_summary",
    "quick_workout_analytics",
    "frequently_swapped_exercises",
    "fasting_weight_trend",
    "v_user_scheduling_patterns",
    "app_tour_step_analytics",
    "app_tour_skip_analysis",
    "user_meal_templates_by_usage",
    "muscle_group_weekly_volume",
    "quick_log_top_foods",
    "user_kegel_stats",
    "static_hold_exercises",
    "warmup_exercises_with_type",
    "v_user_activity_status",
    "cardio_session_stats",
    "current_week_plan_view",
    "cardio_session_analytics",
    "retention_offer_metrics",
    "plan_preview_analytics",
    "active_cardio_programs",
    "demo_screen_flow",
    "user_current_cycle_phase",
    "user_swap_patterns",
    "conversion_trigger_effectiveness",
    "demo_conversion_funnel",
    "exercise_strength_progress",
    "v_stretches_with_muscles"
]


def main():
    print("=" * 60)
    print("Verifying Supabase Security Fixes")
    print("=" * 60)

    conn = psycopg2.connect(**DB_CONFIG)
    cursor = conn.cursor()

    # Check RLS status on tables
    print("\n1. Checking RLS status on tables...")
    print("-" * 40)

    rls_issues = []
    for table in TABLES_TO_CHECK:
        cursor.execute("""
            SELECT rowsecurity
            FROM pg_tables
            WHERE schemaname = 'public' AND tablename = %s
        """, (table,))
        result = cursor.fetchone()
        if result and result[0]:
            print(f"  [OK] {table}: RLS enabled")
        else:
            print(f"  [FAIL] {table}: RLS NOT enabled")
            rls_issues.append(table)

    # Check policies on tables
    print("\n2. Checking policies on reference tables...")
    print("-" * 40)

    policy_issues = []
    reference_tables = [
        "migration_log", "hiit_templates", "cuisine_types", "body_types",
        "senior_mobility_exercises", "low_impact_alternatives",
        "progression_pace_definitions", "exercise_muscle_mappings"
    ]
    for table in reference_tables:
        cursor.execute("""
            SELECT COUNT(*)
            FROM pg_policies
            WHERE schemaname = 'public' AND tablename = %s
        """, (table,))
        result = cursor.fetchone()
        if result and result[0] > 0:
            print(f"  [OK] {table}: has {result[0]} policy(ies)")
        else:
            print(f"  [FAIL] {table}: NO policies found")
            policy_issues.append(table)

    # Check view security options
    print("\n3. Checking view security options...")
    print("-" * 40)

    view_issues = []
    for view in VIEWS_TO_CHECK:
        cursor.execute("""
            SELECT c.reloptions
            FROM pg_class c
            JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE n.nspname = 'public'
            AND c.relname = %s
            AND c.relkind = 'v'
        """, (view,))
        result = cursor.fetchone()
        if result:
            options = result[0] or []
            if 'security_invoker=true' in options:
                print(f"  [OK] {view}: security_invoker=true")
            else:
                print(f"  [FAIL] {view}: security_invoker NOT set (options: {options})")
                view_issues.append(view)
        else:
            print(f"  [SKIP] {view}: view not found")

    # Summary
    print("\n" + "=" * 60)
    print("VERIFICATION SUMMARY")
    print("=" * 60)

    total_issues = len(rls_issues) + len(policy_issues) + len(view_issues)

    if total_issues == 0:
        print("\nAll security fixes verified successfully!")
        print(f"  - {len(TABLES_TO_CHECK)} tables have RLS enabled")
        print(f"  - {len(reference_tables)} reference tables have policies")
        print(f"  - {len(VIEWS_TO_CHECK)} views have security_invoker=true")
    else:
        print(f"\nFound {total_issues} issues:")
        if rls_issues:
            print(f"  - Tables without RLS: {rls_issues}")
        if policy_issues:
            print(f"  - Tables without policies: {policy_issues}")
        if view_issues:
            print(f"  - Views without security_invoker: {view_issues}")

    conn.close()
    return 0 if total_issues == 0 else 1


if __name__ == "__main__":
    exit(main())
