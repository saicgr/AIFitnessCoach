#!/usr/bin/env python3
"""
Fix SECURITY DEFINER views by recreating them as SECURITY INVOKER.

SECURITY DEFINER views run with the permissions of the view creator (usually postgres),
which bypasses RLS. SECURITY INVOKER (the default) runs with the permissions of the
querying user, which is safer.
"""

import sys
import psycopg2

# Database connection (same as other migration scripts)
DATABASE_HOST = "db.hpbzfahijszqmgsybuor.supabase.co"
DATABASE_PORT = 5432
DATABASE_NAME = "postgres"
DATABASE_USER = "postgres"
DATABASE_PASSWORD = "d2nHU5oLZ1GCz63B"

# Views to fix
VIEWS_TO_FIX = [
    "world_records_leaderboard",
    "admin_pending_merch_claims",
    "exercise_library_cleaned",
    "xp_leaderboard",
    "admin_fraud_dashboard",
]


def run_fix():
    """Recreate SECURITY DEFINER views as SECURITY INVOKER."""

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

        print("\nFixing SECURITY DEFINER views...")
        print("=" * 60)

        with conn.cursor() as cur:
            for view_name in VIEWS_TO_FIX:
                try:
                    # First, get the current view definition
                    cur.execute(f"""
                        SELECT pg_get_viewdef('public.{view_name}'::regclass, true);
                    """)
                    result = cur.fetchone()

                    if not result:
                        print(f"  ⏭️ {view_name} - view not found")
                        continue

                    view_def = result[0]

                    # Drop and recreate with SECURITY INVOKER (default)
                    # We use CREATE OR REPLACE to preserve grants
                    cur.execute(f"""
                        CREATE OR REPLACE VIEW public.{view_name}
                        WITH (security_invoker = true)
                        AS {view_def}
                    """)

                    print(f"  ✅ {view_name} - converted to SECURITY INVOKER")

                except psycopg2.Error as e:
                    error_msg = str(e)
                    print(f"  ❌ {view_name}: {error_msg[:100]}")
                    conn.rollback()
                    continue

        conn.commit()
        print("\n" + "=" * 60)
        print("SUCCESS: Views updated!")

        # Verify the changes
        print("\nVerifying changes...")
        with conn.cursor() as cur:
            for view_name in VIEWS_TO_FIX:
                try:
                    cur.execute(f"""
                        SELECT
                            c.relname,
                            CASE WHEN c.reloptions @> ARRAY['security_invoker=true']
                                 THEN 'INVOKER'
                                 WHEN c.reloptions @> ARRAY['security_invoker=false']
                                 THEN 'DEFINER'
                                 ELSE 'INVOKER (default)'
                            END as security_type
                        FROM pg_class c
                        JOIN pg_namespace n ON n.oid = c.relnamespace
                        WHERE c.relname = '{view_name}'
                        AND n.nspname = 'public'
                        AND c.relkind = 'v';
                    """)
                    result = cur.fetchone()
                    if result:
                        print(f"  {result[0]}: {result[1]}")
                except Exception as e:
                    print(f"  Could not verify {view_name}: {e}")

        conn.close()
        return True

    except psycopg2.Error as e:
        print(f"ERROR: {e}")
        return False
    except Exception as e:
        print(f"ERROR: {e}")
        return False


if __name__ == "__main__":
    success = run_fix()
    sys.exit(0 if success else 1)
