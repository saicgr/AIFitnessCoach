#!/usr/bin/env python3
"""
Fix RLS on program_variant_weeks table.
"""

import os
import sys
import psycopg2

# Database connection (same as run_migration_136.py)
DATABASE_HOST = "db.hpbzfahijszqmgsybuor.supabase.co"
DATABASE_PORT = 5432
DATABASE_NAME = "postgres"
DATABASE_USER = "postgres"
DATABASE_PASSWORD = os.environ.get("DATABASE_PASSWORD")
if not DATABASE_PASSWORD:
    raise SystemExit("DATABASE_PASSWORD environment variable is required")


def run_fix():
    """Enable RLS and create policies on program_variant_weeks."""

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

        sql_statements = [
            # Enable RLS
            ("Enable RLS", "ALTER TABLE public.program_variant_weeks ENABLE ROW LEVEL SECURITY;"),

            # Drop existing policies if any
            ("Drop read policy (if exists)", "DROP POLICY IF EXISTS \"Allow public read access to program weeks\" ON public.program_variant_weeks;"),
            ("Drop write policy (if exists)", "DROP POLICY IF EXISTS \"Service role can manage program weeks\" ON public.program_variant_weeks;"),

            # Create read policy - programs are public content
            ("Create read policy", """
                CREATE POLICY "Allow public read access to program weeks"
                ON public.program_variant_weeks
                FOR SELECT
                TO public
                USING (true);
            """),

            # Create write policy for service role only
            ("Create write policy", """
                CREATE POLICY "Service role can manage program weeks"
                ON public.program_variant_weeks
                FOR ALL
                TO service_role
                USING (true)
                WITH CHECK (true);
            """),
        ]

        print("\nFixing RLS on program_variant_weeks...")
        print("=" * 60)

        with conn.cursor() as cur:
            for name, sql in sql_statements:
                try:
                    cur.execute(sql)
                    print(f"  ✅ {name}")
                except psycopg2.Error as e:
                    error_msg = str(e)
                    if "already exists" in error_msg.lower():
                        print(f"  ⏭️ {name} (already exists)")
                    else:
                        print(f"  ❌ {name}: {error_msg[:100]}")

        conn.commit()
        print("\n" + "=" * 60)
        print("SUCCESS: RLS fixed on program_variant_weeks!")

        # Verify RLS is enabled
        with conn.cursor() as cur:
            cur.execute("""
                SELECT relrowsecurity
                FROM pg_class
                WHERE relname = 'program_variant_weeks';
            """)
            result = cur.fetchone()
            if result and result[0]:
                print("VERIFIED: RLS is enabled")
            else:
                print("WARNING: RLS may not be enabled")

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
