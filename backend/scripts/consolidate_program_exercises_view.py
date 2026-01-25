#!/usr/bin/env python3
"""Consolidate program_exercises_with_media view to include week completion info."""

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

def consolidate_view():
    """Drop program_completion_status and update program_exercises_with_media with all needed columns."""
    conn = psycopg2.connect(
        host=db_host,
        database="postgres",
        user="postgres",
        password=DB_PASSWORD,
        port=5432
    )
    conn.autocommit = True
    cur = conn.cursor()

    sql = """
    -- Drop the separate program_completion_status view
    DROP VIEW IF EXISTS program_completion_status CASCADE;
    DROP VIEW IF EXISTS complete_programs CASCADE;

    -- Recreate program_exercises_with_media with week completion columns
    DROP VIEW IF EXISTS program_exercises_with_media CASCADE;

    CREATE VIEW program_exercises_with_media AS
    WITH variant_week_counts AS (
        SELECT
            variant_id,
            COUNT(DISTINCT week_number) as weeks_ingested
        FROM program_variant_weeks
        GROUP BY variant_id
    )
    SELECT
        pef.*,

        -- Program/variant metadata
        pv.duration_weeks,
        pv.sessions_per_week,
        vwc.weeks_ingested,

        -- Week completion status
        CASE
            WHEN vwc.weeks_ingested >= pv.duration_weeks THEN 'complete'
            WHEN vwc.weeks_ingested > 0 THEN 'partial'
            ELSE 'empty'
        END as week_status,

        CASE
            WHEN vwc.weeks_ingested >= pv.duration_weeks THEN '✅'
            WHEN vwc.weeks_ingested > 0 THEN '⚠️'
            ELSE '❌'
        END as status_icon,

        -- Sub-program name
        REPLACE(pef.program_name, ' ', '_') || '_' ||
            pv.duration_weeks || 'w_' || pv.sessions_per_week || 'd' as sub_program_name,

        -- Canonical exercise info
        ec.canonical_name,
        ec.canonical_name_normalized,
        ec.equipment as canonical_equipment,
        ec.body_part as canonical_body_part,
        ec.target_muscle as canonical_target_muscle,

        -- Media paths
        pem.video_s3_path,
        pem.image_s3_path,
        pem.gif_url,
        pem.demo_gender,

        -- Media status
        CASE
            WHEN ea.id IS NULL THEN 'no_alias'
            WHEN ec.id IS NULL THEN 'no_canonical'
            WHEN pem.id IS NULL THEN 'no_demo'
            WHEN pem.video_s3_path IS NULL OR pem.image_s3_path IS NULL THEN 'missing_media'
            ELSE 'complete'
        END as media_status

    FROM program_exercises_flat pef
    LEFT JOIN program_variants pv ON pv.id = pef.variant_id
    LEFT JOIN variant_week_counts vwc ON vwc.variant_id = pef.variant_id
    LEFT JOIN exercise_aliases ea ON pef.exercise_name_normalized = ea.alias_name_normalized
    LEFT JOIN exercise_canonical ec ON ea.canonical_exercise_id = ec.id
    LEFT JOIN exercise_demos pem ON ec.id = pem.canonical_exercise_id
        AND (pem.demo_gender = 'neutral' OR pem.demo_gender = 'female');
    """

    print("Consolidating views...")
    print("  - Dropping program_completion_status")
    print("  - Dropping complete_programs")
    print("  - Recreating program_exercises_with_media with all columns")

    cur.execute(sql)
    print("✅ View consolidated successfully!")

    # Verify the new structure
    print("\n=== Verifying new columns ===")
    cur.execute("""
        SELECT column_name, data_type
        FROM information_schema.columns
        WHERE table_name = 'program_exercises_with_media'
        ORDER BY ordinal_position;
    """)

    columns = cur.fetchall()
    print(f"\nTotal columns: {len(columns)}")
    print("\nNew columns added:")
    new_cols = ['duration_weeks', 'sessions_per_week', 'weeks_ingested', 'week_status',
                'status_icon', 'sub_program_name']
    for col_name, col_type in columns:
        if col_name in new_cols:
            print(f"  ✅ {col_name} ({col_type})")

    # Sample query
    print("\n=== Sample: Leg Development program ===")
    cur.execute("""
        SELECT DISTINCT
            program_name,
            sub_program_name,
            duration_weeks,
            weeks_ingested,
            week_status,
            status_icon,
            COUNT(*) OVER (PARTITION BY variant_id) as total_exercises,
            COUNT(CASE WHEN media_status = 'complete' THEN 1 END) OVER (PARTITION BY variant_id) as complete_exercises
        FROM program_exercises_with_media
        WHERE program_name = 'Leg Development'
        LIMIT 1;
    """)

    row = cur.fetchone()
    if row:
        program, sub_program, duration, ingested, status, icon, total, complete = row
        print(f"Program: {program}")
        print(f"Sub-program: {sub_program}")
        print(f"Duration: {duration} weeks")
        print(f"Weeks ingested: {ingested}")
        print(f"Week status: {icon} {status}")
        print(f"Media: {complete}/{total} exercises complete ({100.0*complete/total:.2f}%)")

    # Summary stats
    print("\n=== Summary Statistics ===")
    cur.execute("""
        SELECT
            week_status,
            COUNT(DISTINCT variant_id) as variant_count,
            COUNT(DISTINCT program_name) as program_count
        FROM program_exercises_with_media
        WHERE program_name IS NOT NULL
        GROUP BY week_status
        ORDER BY
            CASE week_status
                WHEN 'complete' THEN 1
                WHEN 'partial' THEN 2
                WHEN 'empty' THEN 3
            END;
    """)

    print(f"\n{'Week Status':<15} {'Variants':<12} {'Programs':<12}")
    print("-" * 40)
    for status, variants, programs in cur.fetchall():
        icon = '✅' if status == 'complete' else '⚠️' if status == 'partial' else '❌'
        print(f"{icon} {status:<12} {variants:<12} {programs:<12}")

    cur.close()
    conn.close()

if __name__ == "__main__":
    consolidate_view()
