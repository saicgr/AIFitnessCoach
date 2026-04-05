#!/usr/bin/env python3
"""Run migration 1895: Fix rls_policy_always_true warnings.

Fixes 19 Supabase linter warnings where RLS policies use USING(true) or
WITH CHECK(true), effectively bypassing row-level security.

Strategy per policy:
- 7 policies DROPPED (redundant with existing *_service_role_all policies)
- 6 policies ALTERED to scope with user_id = (select auth.uid())
- 3 demo policies RECREATED with TO anon role restriction
- 3 policies ALTERED to scope with user_id/created_by = (select auth.uid())
"""
import os, sys
from pathlib import Path
import psycopg2

DATABASE_HOST = os.environ.get("DATABASE_HOST", "db.hpbzfahijszqmgsybuor.supabase.co")
DATABASE_PORT = int(os.environ.get("DATABASE_PORT", 5432))
DATABASE_NAME = os.environ.get("DATABASE_NAME", "postgres")
DATABASE_USER = os.environ.get("DATABASE_USER", "postgres")
DATABASE_PASSWORD = os.environ.get("DATABASE_PASSWORD") or os.environ.get("SUPABASE_DB_PASSWORD")
if not DATABASE_PASSWORD:
    raise SystemExit("DATABASE_PASSWORD or SUPABASE_DB_PASSWORD environment variable is required")


# The 19 policies we expect to fix
EXPECTED_POLICIES = [
    ("conversation_participants", "Users can add participants to conversations"),
    ("conversations", "Users can create conversations"),
    ("daily_activity", "daily_activity_delete_policy"),
    ("daily_activity", "daily_activity_insert_policy"),
    ("daily_activity", "daily_activity_update_policy"),
    ("daily_adherence_logs", "Service can manage adherence logs"),
    ("demo_interactions", "demo_interactions_insert_policy"),
    ("demo_sessions", "demo_sessions_insert_policy"),
    ("demo_sessions", "demo_sessions_update_policy"),
    ("difficulty_adjustments", "Service can insert adjustments"),
    ("metabolic_adaptation_events", "Service can manage adaptation events"),
    ("push_nudge_log", "push_nudge_log_service_all"),
    ("sustainability_scores", "Service can insert sustainability scores"),
    ("tdee_calculation_history", "Service can insert TDEE history"),
    ("user_checkpoint_progress", "Service can manage checkpoint progress"),
    ("user_consumables", "Service can manage consumables"),
    ("user_daily_crates", "Service can manage daily crates"),
    ("user_first_time_bonuses", "Service can insert first time bonuses"),
    ("workout_generation_jobs", "Service role has full access to workout_generation_jobs"),
]

# Policies that will be DROPPED (not altered)
DROPPED_POLICIES = {
    ("daily_adherence_logs", "Service can manage adherence logs"),
    ("metabolic_adaptation_events", "Service can manage adaptation events"),
    ("push_nudge_log", "push_nudge_log_service_all"),
    ("user_checkpoint_progress", "Service can manage checkpoint progress"),
    ("user_consumables", "Service can manage consumables"),
    ("user_daily_crates", "Service can manage daily crates"),
    ("workout_generation_jobs", "Service role has full access to workout_generation_jobs"),
}

# Policies that will be RECREATED (dropped + created with TO anon)
RECREATED_POLICIES = {
    ("demo_interactions", "demo_interactions_insert_policy"),
    ("demo_sessions", "demo_sessions_insert_policy"),
    ("demo_sessions", "demo_sessions_update_policy"),
}


def run_migration():
    migrations_dir = Path(__file__).parent.parent / "migrations"
    file_path = migrations_dir / "1895_fix_rls_always_true.sql"

    conn = psycopg2.connect(
        host=DATABASE_HOST, port=DATABASE_PORT, dbname=DATABASE_NAME,
        user=DATABASE_USER, password=DATABASE_PASSWORD, sslmode="require"
    )

    print(f"\n{'='*60}")
    print(f"Running: 1895_fix_rls_always_true.sql")
    print(f"  Fixes 19 rls_policy_always_true linter warnings")
    print(f"{'='*60}")

    try:
        # Pre-flight: verify all 19 policies exist
        with conn.cursor() as cur:
            missing = []
            for table, policy in EXPECTED_POLICIES:
                cur.execute(
                    "SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = %s AND policyname = %s",
                    (table, policy)
                )
                if not cur.fetchone():
                    missing.append(f"  {table}.{policy}")
            if missing:
                print(f"\n  WARNING: {len(missing)} expected policies not found:")
                for m in missing:
                    print(m)
                print("  Migration may have already been applied. Aborting.")
                sys.exit(1)

        # Count always-true policies before
        with conn.cursor() as cur:
            cur.execute("""
                SELECT COUNT(*) FROM pg_policies
                WHERE schemaname = 'public'
                AND (qual = 'true' OR with_check = 'true')
                AND cmd != 'SELECT'
            """)
            count_before = cur.fetchone()[0]
            print(f"\n  Always-true non-SELECT policies before: {count_before}")

        # Run the migration
        sql = file_path.read_text()
        with conn.cursor() as cur:
            cur.execute(sql)
        conn.commit()

        # Count always-true policies after
        with conn.cursor() as cur:
            cur.execute("""
                SELECT COUNT(*) FROM pg_policies
                WHERE schemaname = 'public'
                AND (qual = 'true' OR with_check = 'true')
                AND cmd != 'SELECT'
            """)
            count_after = cur.fetchone()[0]
            print(f"  Always-true non-SELECT policies after:  {count_after}")
            print(f"  Policies fixed: {count_before - count_after}")

        # Verify: check dropped policies are gone
        with conn.cursor() as cur:
            still_exists = []
            for table, policy in DROPPED_POLICIES:
                cur.execute(
                    "SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = %s AND policyname = %s",
                    (table, policy)
                )
                if cur.fetchone():
                    still_exists.append(f"  {table}.{policy}")
            if still_exists:
                print(f"\n  WARNING: {len(still_exists)} policies should have been dropped but still exist:")
                for s in still_exists:
                    print(s)

        # Verify: check altered policies no longer have true
        with conn.cursor() as cur:
            altered_tables = [
                ("conversation_participants", "Users can add participants to conversations"),
                ("conversations", "Users can create conversations"),
                ("daily_activity", "daily_activity_delete_policy"),
                ("daily_activity", "daily_activity_insert_policy"),
                ("daily_activity", "daily_activity_update_policy"),
                ("difficulty_adjustments", "Service can insert adjustments"),
                ("sustainability_scores", "Service can insert sustainability scores"),
                ("tdee_calculation_history", "Service can insert TDEE history"),
                ("user_first_time_bonuses", "Service can insert first time bonuses"),
            ]
            still_true = []
            for table, policy in altered_tables:
                cur.execute(
                    "SELECT qual, with_check FROM pg_policies WHERE schemaname = 'public' AND tablename = %s AND policyname = %s",
                    (table, policy)
                )
                row = cur.fetchone()
                if row and (row[0] == 'true' or row[1] == 'true'):
                    still_true.append(f"  {table}.{policy} (qual={row[0]}, with_check={row[1]})")
            if still_true:
                print(f"\n  WARNING: {len(still_true)} altered policies still have 'true':")
                for s in still_true:
                    print(s)

        # Verify: demo policies now have TO anon
        with conn.cursor() as cur:
            for table, policy in RECREATED_POLICIES:
                cur.execute(
                    "SELECT roles FROM pg_policies WHERE schemaname = 'public' AND tablename = %s AND policyname = %s",
                    (table, policy)
                )
                row = cur.fetchone()
                if row:
                    roles = row[0]
                    if 'anon' in roles:
                        print(f"  OK: {table}.{policy} now restricted to anon role")
                    else:
                        print(f"  WARNING: {table}.{policy} roles={roles} (expected anon)")
                else:
                    print(f"  WARNING: {table}.{policy} not found after recreation")

        print(f"\n  Migration completed successfully!")

    except Exception as e:
        conn.rollback()
        print(f"\n  ERROR: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
    finally:
        conn.close()


if __name__ == "__main__":
    run_migration()
