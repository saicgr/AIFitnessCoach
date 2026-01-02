#!/usr/bin/env python3
"""
Fix Supabase Security Linter Errors

This script fixes:
1. Tables with RLS policies but RLS not enabled
2. Tables missing RLS entirely
3. Views with SECURITY DEFINER (should be SECURITY INVOKER)
"""

import psycopg2
from psycopg2 import sql
import sys

# Database connection details
DB_CONFIG = {
    "host": "db.hpbzfahijszqmgsybuor.supabase.co",
    "port": 5432,
    "database": "postgres",
    "user": "postgres",
    "password": "d2nHU5oLZ1GCz63B"
}

# Tables with RLS policies but RLS not enabled
TABLES_RLS_NOT_ENABLED = [
    "cardio_progression_templates",
    "hormone_supportive_foods",
    "kegel_exercises"
]

# Tables missing RLS entirely (reference/read-only tables)
TABLES_MISSING_RLS = [
    "migration_log",
    "hiit_templates",
    "cuisine_types",
    "body_types",
    "senior_mobility_exercises",
    "low_impact_alternatives",
    "progression_pace_definitions",
    "exercise_muscle_mappings"
]

# Views with SECURITY DEFINER that need to be SECURITY INVOKER
VIEWS_TO_FIX = [
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


def connect():
    """Connect to the database."""
    print("Connecting to Supabase PostgreSQL...")
    conn = psycopg2.connect(**DB_CONFIG)
    conn.autocommit = False
    print("Connected successfully!")
    return conn


def enable_rls_on_tables(cursor, tables, description):
    """Enable RLS on a list of tables."""
    print(f"\n{'='*60}")
    print(f"Enabling RLS: {description}")
    print(f"{'='*60}")

    success_count = 0
    error_count = 0

    for table in tables:
        try:
            cursor.execute(
                sql.SQL("ALTER TABLE public.{} ENABLE ROW LEVEL SECURITY").format(
                    sql.Identifier(table)
                )
            )
            print(f"  [OK] Enabled RLS on: {table}")
            success_count += 1
        except Exception as e:
            print(f"  [ERROR] {table}: {e}")
            error_count += 1

    return success_count, error_count


def add_public_read_policy(cursor, tables):
    """Add public read access policy to tables."""
    print(f"\n{'='*60}")
    print("Adding public read access policies")
    print(f"{'='*60}")

    success_count = 0
    error_count = 0

    for table in tables:
        policy_name = f"Allow public read access on {table}"
        try:
            # Check if policy already exists
            cursor.execute("""
                SELECT 1 FROM pg_policies
                WHERE schemaname = 'public'
                AND tablename = %s
                AND policyname = %s
            """, (table, policy_name))

            if cursor.fetchone():
                print(f"  [SKIP] Policy already exists on: {table}")
                success_count += 1
                continue

            # Create the policy
            cursor.execute(
                sql.SQL("""
                    CREATE POLICY {} ON public.{}
                    FOR SELECT USING (true)
                """).format(
                    sql.Identifier(policy_name),
                    sql.Identifier(table)
                )
            )
            print(f"  [OK] Added read policy on: {table}")
            success_count += 1
        except Exception as e:
            print(f"  [ERROR] {table}: {e}")
            error_count += 1

    return success_count, error_count


def fix_view_security(cursor, views):
    """Recreate views with SECURITY INVOKER."""
    print(f"\n{'='*60}")
    print("Fixing views with SECURITY DEFINER -> SECURITY INVOKER")
    print(f"{'='*60}")

    success_count = 0
    error_count = 0
    skipped_count = 0

    for view in views:
        try:
            # Get current view definition
            cursor.execute("""
                SELECT pg_get_viewdef(%s::regclass, true)
            """, (f"public.{view}",))

            result = cursor.fetchone()
            if not result or not result[0]:
                print(f"  [SKIP] View not found: {view}")
                skipped_count += 1
                continue

            view_def = result[0]

            # Recreate view with security_invoker = true
            create_sql = sql.SQL("""
                CREATE OR REPLACE VIEW public.{view_name}
                WITH (security_invoker = true)
                AS {view_def}
            """).format(
                view_name=sql.Identifier(view),
                view_def=sql.SQL(view_def)
            )

            cursor.execute(create_sql)
            print(f"  [OK] Fixed: {view}")
            success_count += 1

        except Exception as e:
            print(f"  [ERROR] {view}: {e}")
            error_count += 1

    return success_count, error_count, skipped_count


def main():
    """Main function to fix all security issues."""
    print("=" * 60)
    print("Supabase Security Linter Fix Script")
    print("=" * 60)

    conn = None
    try:
        conn = connect()
        cursor = conn.cursor()

        total_success = 0
        total_errors = 0

        # 1. Enable RLS on tables with policies but RLS not enabled
        s, e = enable_rls_on_tables(
            cursor,
            TABLES_RLS_NOT_ENABLED,
            "Tables with policies but RLS not enabled"
        )
        total_success += s
        total_errors += e

        # 2. Enable RLS on tables missing RLS entirely
        s, e = enable_rls_on_tables(
            cursor,
            TABLES_MISSING_RLS,
            "Tables missing RLS entirely"
        )
        total_success += s
        total_errors += e

        # 3. Add public read policies for reference tables
        s, e = add_public_read_policy(cursor, TABLES_MISSING_RLS)
        total_success += s
        total_errors += e

        # 4. Fix views with SECURITY DEFINER
        s, e, skipped = fix_view_security(cursor, VIEWS_TO_FIX)
        total_success += s
        total_errors += e

        # Commit all changes
        if total_errors == 0:
            print(f"\n{'='*60}")
            print("Committing all changes...")
            conn.commit()
            print("All changes committed successfully!")
        else:
            print(f"\n{'='*60}")
            print(f"Rolling back due to {total_errors} errors...")
            conn.rollback()
            print("Changes rolled back.")

        # Summary
        print(f"\n{'='*60}")
        print("SUMMARY")
        print(f"{'='*60}")
        print(f"  Successful operations: {total_success}")
        print(f"  Failed operations: {total_errors}")
        print(f"  Views skipped (not found): {skipped}")

        return 0 if total_errors == 0 else 1

    except Exception as e:
        print(f"\nFATAL ERROR: {e}")
        if conn:
            conn.rollback()
        return 1
    finally:
        if conn:
            conn.close()
            print("\nDatabase connection closed.")


if __name__ == "__main__":
    sys.exit(main())
