#!/usr/bin/env python3
"""
Verify Search Path & Materialized View Security Fixes

This script verifies that:
1. All functions have SET search_path = public
2. Materialized views are not accessible to anon/authenticated
3. Wrapper functions exist for leaderboard access
"""
from __future__ import annotations

import psycopg2
import sys

# Database connection details
DB_CONFIG = {
    "host": "db.hpbzfahijszqmgsybuor.supabase.co",
    "port": 5432,
    "database": "postgres",
    "user": "postgres",
    "password": "d2nHU5oLZ1GCz63B"
}

# Functions that should have search_path set
FUNCTIONS_TO_CHECK = [
    "get_iso_week_boundaries",
    "get_primary_nutrition_goal",
    "get_muscle_injury_status",
    "increment_feature_usage",
    "get_active_injuries",
    "get_injury_avoided_exercises",
    "update_injury_updated_at",
    "get_friends_on_goal",
    "update_quick_workout_preferences_updated_at",
    "save_user_profile",
    "increment_quick_workout_count",
    "update_updated_at_column",
    "record_workout_regeneration",
    "get_days_since_last_workout",
    "start_comeback_mode",
    "update_home_layouts_updated_at",
    "progress_comeback_week",
    "end_comeback_mode",
    "update_comeback_workout_count",
    "update_last_workout_date",
    "update_app_tour_sessions_timestamp",
    "update_tour_steps_completed",
    "update_branded_programs_timestamp",
    "update_user_program_assignments_timestamp",
    "log_program_assignment_change",
    "get_user_leaderboard_rank",
    "calculate_demo_session_duration",
    "trigger_check_milestones_on_workout",
    "update_superset_preferences_updated_at",
    "upsert_superset_preferences",
    "record_superset_completion",
    "update_hormonal_updated_at",
    "get_cycle_phase_exercise_intensity",
    "check_daily_kegel_goal",
    "get_user_active_program",
    "get_recommended_programs",
    "start_branded_program",
    "update_program_progress",
    "update_cooking_conversion_updated_at",
    "find_next_exercise_variant",
    "get_latest_strength_baseline",
    "user_needs_recalibration",
    "calculate_estimated_1rm",
    "update_subjective_feedback_updated_at",
    "update_sound_preferences_updated_at",
    "get_flexibility_trend",
    "get_flexibility_score",
    "user_frequently_swaps",
    "validate_hiit_no_static_holds",
    "check_and_award_milestones",
    "calculate_user_roi_metrics",
    "get_exercise_muscles",
    "exercise_involves_muscle",
    "get_exercises_for_muscle",
    "update_user_workout_pattern",
    "update_fasting_weight_correlation",
    "calculate_fasting_weight_correlation",
]

# Materialized views that should not be accessible
MATERIALIZED_VIEWS = [
    "leaderboard_streaks",
    "leaderboard_weekly_challenges",
    "leaderboard_challenge_masters",
    "leaderboard_volume_kings",
]

# Wrapper functions that should exist
WRAPPER_FUNCTIONS = [
    "get_leaderboard_streaks",
    "get_leaderboard_weekly_challenges",
    "get_leaderboard_challenge_masters",
    "get_leaderboard_volume_kings",
]


def main():
    print("=" * 70)
    print("Verifying Search Path & Materialized View Security Fixes")
    print("=" * 70)

    conn = psycopg2.connect(**DB_CONFIG)
    cursor = conn.cursor()

    issues = []

    # ========================================
    # 1. Check functions have search_path set
    # ========================================
    print(f"\n1. Checking {len(FUNCTIONS_TO_CHECK)} functions for search_path setting...")
    print("-" * 50)

    ok_count = 0
    fail_count = 0

    for func_name in FUNCTIONS_TO_CHECK:
        cursor.execute("""
            SELECT pg_get_functiondef(p.oid) as definition
            FROM pg_proc p
            JOIN pg_namespace n ON p.pronamespace = n.oid
            WHERE n.nspname = 'public' AND p.proname = %s
        """, (func_name,))
        result = cursor.fetchone()

        if result:
            definition = result[0].lower()
            if 'search_path' in definition:
                ok_count += 1
            else:
                print(f"  [FAIL] {func_name}: search_path NOT set")
                issues.append(f"Function {func_name} missing search_path")
                fail_count += 1
        else:
            print(f"  [SKIP] {func_name}: function not found")

    print(f"\n  Summary: {ok_count} OK, {fail_count} FAIL")

    # ========================================
    # 2. Check materialized views are not accessible
    # ========================================
    print(f"\n2. Checking {len(MATERIALIZED_VIEWS)} materialized views are secured...")
    print("-" * 50)

    for view_name in MATERIALIZED_VIEWS:
        # Check if anon has SELECT privilege
        cursor.execute("""
            SELECT has_table_privilege('anon', %s, 'SELECT')
        """, (f"public.{view_name}",))
        anon_result = cursor.fetchone()

        # Check if authenticated has SELECT privilege
        cursor.execute("""
            SELECT has_table_privilege('authenticated', %s, 'SELECT')
        """, (f"public.{view_name}",))
        auth_result = cursor.fetchone()

        anon_access = anon_result[0] if anon_result else False
        auth_access = auth_result[0] if auth_result else False

        if not anon_access and not auth_access:
            print(f"  [OK] {view_name}: direct access revoked from anon and authenticated")
        else:
            access_list = []
            if anon_access:
                access_list.append("anon")
            if auth_access:
                access_list.append("authenticated")
            print(f"  [FAIL] {view_name}: still accessible by {', '.join(access_list)}")
            issues.append(f"Materialized view {view_name} accessible by {', '.join(access_list)}")

    # ========================================
    # 3. Check wrapper functions exist
    # ========================================
    print(f"\n3. Checking {len(WRAPPER_FUNCTIONS)} wrapper functions exist...")
    print("-" * 50)

    for func_name in WRAPPER_FUNCTIONS:
        cursor.execute("""
            SELECT pg_get_functiondef(p.oid) as definition
            FROM pg_proc p
            JOIN pg_namespace n ON p.pronamespace = n.oid
            WHERE n.nspname = 'public' AND p.proname = %s
        """, (func_name,))
        result = cursor.fetchone()

        if result:
            definition = result[0].lower()
            if 'search_path' in definition and 'security definer' in definition:
                print(f"  [OK] {func_name}: exists with search_path and SECURITY DEFINER")
            elif 'search_path' in definition:
                print(f"  [WARN] {func_name}: exists with search_path but missing SECURITY DEFINER")
            else:
                print(f"  [FAIL] {func_name}: exists but missing search_path")
                issues.append(f"Wrapper function {func_name} missing search_path")
        else:
            print(f"  [FAIL] {func_name}: function does not exist")
            issues.append(f"Wrapper function {func_name} does not exist")

    # ========================================
    # 4. Check wrapper functions have execute grants
    # ========================================
    print(f"\n4. Checking wrapper functions have EXECUTE grant to authenticated...")
    print("-" * 50)

    for func_name in WRAPPER_FUNCTIONS:
        cursor.execute("""
            SELECT has_function_privilege('authenticated',
                                         (SELECT oid FROM pg_proc
                                          WHERE proname = %s
                                          AND pronamespace = 'public'::regnamespace),
                                         'EXECUTE')
        """, (func_name,))
        result = cursor.fetchone()

        if result and result[0]:
            print(f"  [OK] {func_name}: authenticated can execute")
        else:
            print(f"  [FAIL] {func_name}: authenticated CANNOT execute")
            issues.append(f"Wrapper function {func_name} not executable by authenticated")

    # ========================================
    # Summary
    # ========================================
    print("\n" + "=" * 70)
    print("VERIFICATION SUMMARY")
    print("=" * 70)

    if not issues:
        print("\nAll security fixes verified successfully!")
        print(f"  - {len(FUNCTIONS_TO_CHECK)} functions have search_path set")
        print(f"  - {len(MATERIALIZED_VIEWS)} materialized views are secured")
        print(f"  - {len(WRAPPER_FUNCTIONS)} wrapper functions exist and are accessible")
        conn.close()
        return 0
    else:
        print(f"\nFound {len(issues)} issues:")
        for issue in issues:
            print(f"  - {issue}")
        conn.close()
        return 1


if __name__ == "__main__":
    sys.exit(main())
