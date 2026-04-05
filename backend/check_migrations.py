#!/usr/bin/env python3
"""
Check which migrations >= 1885 have been applied to the Supabase database.
For each migration, verifies the expected database objects exist.
"""
import os
import sys

try:
    import psycopg2
except ImportError:
    print("Installing psycopg2-binary...")
    os.system(f"{sys.executable} -m pip install psycopg2-binary -q")
    import psycopg2


def get_conn():
    return psycopg2.connect(
        host="db.hpbzfahijszqmgsybuor.supabase.co",
        port=5432,
        database="postgres",
        user="postgres",
        password=os.environ["SUPABASE_DB_PASSWORD"],
        sslmode="require",
    )


def check_column_exists(cur, table, column):
    cur.execute(
        """
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = %s AND column_name = %s
        """,
        (table, column),
    )
    return cur.fetchone() is not None


def check_table_exists(cur, table):
    cur.execute(
        """
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = %s
        """,
        (table,),
    )
    return cur.fetchone() is not None


def check_index_exists(cur, index_name):
    cur.execute(
        """
        SELECT 1 FROM pg_indexes
        WHERE schemaname = 'public' AND indexname = %s
        """,
        (index_name,),
    )
    return cur.fetchone() is not None


def check_function_exists(cur, func_name):
    cur.execute(
        """
        SELECT 1 FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public' AND p.proname = %s
        """,
        (func_name,),
    )
    return cur.fetchone() is not None


def check_function_returns_type(cur, func_name, return_type_fragment):
    """Check if a function's return type contains a certain string."""
    cur.execute(
        """
        SELECT pg_get_function_result(p.oid)
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public' AND p.proname = %s
        """,
        (func_name,),
    )
    row = cur.fetchone()
    if row is None:
        return False
    return return_type_fragment.lower() in row[0].lower()


def check_rls_enabled(cur, table):
    cur.execute(
        """
        SELECT rowsecurity FROM pg_tables
        WHERE schemaname = 'public' AND tablename = %s
        """,
        (table,),
    )
    row = cur.fetchone()
    return row is not None and row[0]


def check_policy_exists(cur, policy_name):
    cur.execute(
        """
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public' AND policyname = %s
        """,
        (policy_name,),
    )
    return cur.fetchone() is not None


def check_food_override_exists(cur, food_name_normalized):
    cur.execute(
        """
        SELECT 1 FROM food_nutrition_overrides
        WHERE food_name_normalized = %s
        """,
        (food_name_normalized,),
    )
    return cur.fetchone() is not None


def main():
    conn = get_conn()
    cur = conn.cursor()

    results = {}

    # =========================================================
    # 1885: Add targets and progression to performance_logs
    # =========================================================
    name = "1885_add_targets_and_progression_to_performance_logs"
    checks = []
    for col in ["target_weight_kg", "target_reps", "progression_model"]:
        exists = check_column_exists(cur, "performance_logs", col)
        checks.append((f"performance_logs.{col}", exists))

    metadata_exists = check_column_exists(cur, "workout_logs", "metadata")
    checks.append(("workout_logs.metadata", metadata_exists))

    results[name] = checks

    # =========================================================
    # 1886: Create warmup_exercise_logs table
    # =========================================================
    name = "1886_create_warmup_exercise_logs"
    checks = []
    checks.append(("table warmup_exercise_logs", check_table_exists(cur, "warmup_exercise_logs")))
    for col in ["id", "workout_id", "user_id", "exercise_name", "intervals_json", "created_at"]:
        checks.append((f"warmup_exercise_logs.{col}", check_column_exists(cur, "warmup_exercise_logs", col)))
    checks.append(("idx_warmup_exercise_logs_workout_id", check_index_exists(cur, "idx_warmup_exercise_logs_workout_id")))
    checks.append(("idx_warmup_exercise_logs_user_id", check_index_exists(cur, "idx_warmup_exercise_logs_user_id")))
    checks.append(("RLS enabled", check_rls_enabled(cur, "warmup_exercise_logs")))
    checks.append(("policy warmup_exercise_logs_select", check_policy_exists(cur, "warmup_exercise_logs_select")))
    checks.append(("policy warmup_exercise_logs_insert", check_policy_exists(cur, "warmup_exercise_logs_insert")))

    results[name] = checks

    # =========================================================
    # 1887: Fix daily login field names (function replacement)
    # =========================================================
    name = "1887_fix_daily_login_field_names"
    checks = []
    checks.append(("function process_daily_login exists", check_function_exists(cur, "process_daily_login")))
    checks.append(("process_daily_login returns jsonb", check_function_returns_type(cur, "process_daily_login", "jsonb")))

    results[name] = checks

    # =========================================================
    # 1888: Fix custom exercise stats (function replacement)
    # =========================================================
    name = "1888_fix_custom_exercise_stats"
    checks = []
    checks.append(("function get_custom_exercise_stats exists", check_function_exists(cur, "get_custom_exercise_stats")))
    # The correct version returns TABLE(exercise_id, exercise_name, usage_count, last_used, avg_rating)
    checks.append(("returns TABLE with exercise_id", check_function_returns_type(cur, "get_custom_exercise_stats", "exercise_id")))
    checks.append(("returns TABLE with usage_count", check_function_returns_type(cur, "get_custom_exercise_stats", "usage_count")))
    checks.append(("returns TABLE with avg_rating", check_function_returns_type(cur, "get_custom_exercise_stats", "avg_rating")))

    results[name] = checks

    # =========================================================
    # 1889: Add food log mood columns
    # =========================================================
    name = "1889_add_food_log_mood_columns"
    checks = []
    for col in ["mood_before", "mood_after", "energy_level"]:
        checks.append((f"food_logs.{col}", check_column_exists(cur, "food_logs", col)))
    checks.append(("idx_food_logs_mood", check_index_exists(cur, "idx_food_logs_mood")))

    results[name] = checks

    # =========================================================
    # 1890: Add generic food overrides
    # =========================================================
    name = "1890_add_generic_food_overrides"
    checks = []
    sample_foods = [
        "rotisserie_chicken", "filet_mignon", "tuna_canned", "cod",
        "pork_sausage", "ham_deli", "deli_turkey", "beef_burger_patty",
        "ramen_noodles", "flour_tortilla", "sub_roll", "hamburger_bun",
        "hot_dog_bun", "bell_pepper", "fajita_vegetables", "yogurt_plain",
        "corn_salsa", "yellow_mustard", "ranch_dressing", "bbq_sauce",
        "soy_sauce", "teriyaki_sauce", "mixed_berries", "trail_mix",
        "granola_bar", "protein_bar", "tortilla_chips", "popcorn",
        "crackers", "chocolate_chip_cookie", "fruit_smoothie", "coffee_black",
    ]
    for food in sample_foods:
        checks.append((f"food override: {food}", check_food_override_exists(cur, food)))

    results[name] = checks

    # =========================================================
    # Print results
    # =========================================================
    print("=" * 80)
    print("MIGRATION VERIFICATION REPORT (>= 1885)")
    print("=" * 80)

    unapplied = []

    for migration, checks in results.items():
        all_pass = all(ok for _, ok in checks)
        any_pass = any(ok for _, ok in checks)

        if all_pass:
            status = "FULLY APPLIED"
        elif any_pass:
            status = "PARTIALLY APPLIED"
        else:
            status = "NOT APPLIED"

        print(f"\n{'PASS' if all_pass else 'FAIL'} | {migration}")
        print(f"     Status: {status}")

        for check_name, ok in checks:
            icon = "  OK" if ok else "MISS"
            print(f"     [{icon}] {check_name}")

        if not all_pass:
            unapplied.append((migration, status, [(c, ok) for c, ok in checks if not ok]))

    print("\n" + "=" * 80)
    if unapplied:
        print(f"SUMMARY: {len(unapplied)} migration(s) need attention:")
        for mig, status, missing in unapplied:
            print(f"  - {mig} ({status})")
            for check_name, _ in missing:
                print(f"      Missing: {check_name}")
    else:
        print("SUMMARY: All 6 migrations (1885-1890) are fully applied.")
    print("=" * 80)

    cur.close()
    conn.close()


if __name__ == "__main__":
    main()
