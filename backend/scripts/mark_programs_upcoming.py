#!/usr/bin/env python3
"""Mark programs as upcoming based on media coverage."""

import os
import psycopg2
from pathlib import Path
from dotenv import load_dotenv

# Load environment
env_path = Path(__file__).parent.parent / ".env"
load_dotenv(env_path)

DB_PASSWORD = os.getenv("SUPABASE_DB_PASSWORD")
SUPABASE_URL = os.getenv("SUPABASE_URL")

# Extract host from URL
db_host = SUPABASE_URL.replace("https://", "").replace(".supabase.co", "") + ".supabase.co"
db_host = f"db.{db_host.split('.')[0]}.supabase.co"

def mark_upcoming():
    """Add status column and mark all programs as upcoming."""
    conn = psycopg2.connect(
        host=db_host,
        database="postgres",
        user="postgres",
        password=DB_PASSWORD,
        port=5432
    )
    conn.autocommit = True
    cur = conn.cursor()

    print("=== Marking Programs as Upcoming ===\n")

    # Step 1: Add status column to program_variants if it doesn't exist
    print("1. Adding 'status' column to program_variants table...")
    cur.execute("""
        DO $$
        BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM information_schema.columns
                WHERE table_name = 'program_variants'
                AND column_name = 'status'
            ) THEN
                ALTER TABLE program_variants
                ADD COLUMN status TEXT DEFAULT 'upcoming';

                COMMENT ON COLUMN program_variants.status IS
                'Program availability status: upcoming, active, archived';
            END IF;
        END $$;
    """)
    print("   ✅ Status column added/verified\n")

    # Step 2: Mark all programs as upcoming initially
    print("2. Setting all programs to 'upcoming' status...")
    cur.execute("""
        UPDATE program_variants
        SET status = 'upcoming'
        WHERE status IS NULL OR status != 'upcoming';
    """)

    cur.execute("SELECT COUNT(*) FROM program_variants WHERE status = 'upcoming';")
    upcoming_count = cur.fetchone()[0]
    print(f"   ✅ {upcoming_count} variants marked as 'upcoming'\n")

    # Step 3: Optionally mark the 14 complete variants as 'active'
    print("3. Do you want to mark the 14 variants with 100% media coverage as 'active'?")
    print("   (This will make them available in the app while others are 'upcoming')")

    # For now, let's keep them all as upcoming as requested
    # You can manually change specific ones to 'active' later

    print("\n=== Summary ===")
    cur.execute("""
        SELECT
            status,
            COUNT(*) as variant_count
        FROM program_variants
        GROUP BY status
        ORDER BY status;
    """)

    print(f"\n{'Status':<15} {'Variant Count':<15}")
    print("-" * 30)
    for row in cur.fetchall():
        status, count = row
        print(f"{status:<15} {count:<15}")

    # Step 4: Create a view for app consumption
    print("\n4. Creating app-ready view with status...")
    cur.execute("""
        DROP VIEW IF EXISTS app_programs CASCADE;

        CREATE VIEW app_programs AS
        SELECT
            pv.id as variant_id,
            pv.base_program_id,
            pv.duration_weeks,
            pv.sessions_per_week,
            pv.status,
            pvw.program_name,
            pvw.priority,

            -- Sub-program name
            REPLACE(pvw.program_name, ' ', '_') || '_' ||
                pv.duration_weeks || 'w_' || pv.sessions_per_week || 'd' as sub_program_name,

            -- Week completion
            COUNT(DISTINCT pvw.week_number) as weeks_ingested,
            CASE
                WHEN COUNT(DISTINCT pvw.week_number) >= pv.duration_weeks THEN 'complete'
                WHEN COUNT(DISTINCT pvw.week_number) > 0 THEN 'partial'
                ELSE 'empty'
            END as week_status,

            -- Media coverage stats (aggregated)
            (
                SELECT COUNT(*)
                FROM program_exercises_flat pef
                WHERE pef.variant_id = pv.id
            ) as total_exercises,

            (
                SELECT COUNT(*)
                FROM program_exercises_flat pef
                LEFT JOIN exercise_aliases ea ON pef.exercise_name_normalized = ea.alias_name_normalized
                LEFT JOIN exercise_canonical ec ON ea.canonical_exercise_id = ec.id
                LEFT JOIN exercise_demos ed ON ec.id = ed.canonical_exercise_id
                    AND (ed.demo_gender = 'neutral' OR ed.demo_gender = 'female')
                WHERE pef.variant_id = pv.id
                    AND ed.video_s3_path IS NOT NULL
                    AND ed.image_s3_path IS NOT NULL
            ) as exercises_with_media,

            -- Calculated coverage percentage
            ROUND(100.0 * (
                SELECT COUNT(*)
                FROM program_exercises_flat pef
                LEFT JOIN exercise_aliases ea ON pef.exercise_name_normalized = ea.alias_name_normalized
                LEFT JOIN exercise_canonical ec ON ea.canonical_exercise_id = ec.id
                LEFT JOIN exercise_demos ed ON ec.id = ed.canonical_exercise_id
                    AND (ed.demo_gender = 'neutral' OR ed.demo_gender = 'female')
                WHERE pef.variant_id = pv.id
                    AND ed.video_s3_path IS NOT NULL
                    AND ed.image_s3_path IS NOT NULL
            ) / NULLIF((
                SELECT COUNT(*)
                FROM program_exercises_flat pef
                WHERE pef.variant_id = pv.id
            ), 0), 1) as media_coverage_pct

        FROM program_variants pv
        LEFT JOIN program_variant_weeks pvw ON pvw.variant_id = pv.id
        WHERE pvw.program_name IS NOT NULL
        GROUP BY pv.id, pv.base_program_id, pv.duration_weeks, pv.sessions_per_week,
                 pv.status, pvw.program_name, pvw.priority;
    """)
    print("   ✅ Created 'app_programs' view\n")

    # Show sample of upcoming programs
    print("\n=== Sample Upcoming Programs ===")
    cur.execute("""
        SELECT
            sub_program_name,
            priority,
            status,
            weeks_ingested || '/' || duration_weeks as weeks,
            media_coverage_pct || '%' as coverage
        FROM app_programs
        WHERE status = 'upcoming'
        ORDER BY priority, media_coverage_pct DESC
        LIMIT 10;
    """)

    print(f"\n{'Sub-Program Name':<40} {'Priority':<10} {'Status':<12} {'Weeks':<10} {'Coverage':<10}")
    print("-" * 85)
    for row in cur.fetchall():
        sub_name, priority, status, weeks, coverage = row
        print(f"{sub_name:<40} {priority:<10} {status:<12} {weeks:<10} {coverage:<10}")

    print("\n" + "="*85)
    print("✅ All programs marked as 'upcoming'")
    print("="*85)
    print("\nNext steps:")
    print("1. Use 'app_programs' view in your Flutter app")
    print("2. Filter by status = 'upcoming' to show upcoming programs")
    print("3. When ready to launch specific programs, UPDATE program_variants SET status = 'active' WHERE id = '...'")
    print("4. The view includes media_coverage_pct so you can track progress")

    cur.close()
    conn.close()

if __name__ == "__main__":
    mark_upcoming()
