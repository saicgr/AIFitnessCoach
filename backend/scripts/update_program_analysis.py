#!/usr/bin/env python3
"""Update program_analysis view with simpler, faster logic."""

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

def update_view():
    """Update the program_analysis view."""
    conn = psycopg2.connect(
        host=db_host,
        database="postgres",
        user="postgres",
        password=DB_PASSWORD,
        port=5432
    )
    conn.autocommit = True
    cur = conn.cursor()

    # Drop and recreate view
    sql = """
    DROP VIEW IF EXISTS program_analysis CASCADE;

    CREATE OR REPLACE VIEW program_analysis
    WITH (security_invoker = true)
    AS
    WITH variant_week_counts AS (
        SELECT
            pvw.variant_id,
            pvw.priority,
            pvw.program_name,
            COUNT(DISTINCT pvw.week_number) as weeks_ingested
        FROM program_variant_weeks pvw
        GROUP BY pvw.variant_id, pvw.priority, pvw.program_name
    ),
    variant_status AS (
        SELECT
            vwc.priority,
            vwc.program_name,
            pv.id as variant_id,
            pv.duration_weeks,
            vwc.weeks_ingested,
            CASE
                WHEN vwc.weeks_ingested >= pv.duration_weeks THEN 'complete'
                WHEN vwc.weeks_ingested > 0 THEN 'partial'
                ELSE 'empty'
            END as status
        FROM variant_week_counts vwc
        JOIN program_variants pv ON pv.id = vwc.variant_id
    ),
    priority_stats AS (
        SELECT
            priority,
            COUNT(*) as total_variants,
            COUNT(*) FILTER (WHERE status = 'complete') as complete,
            COUNT(*) FILTER (WHERE status = 'partial') as partial,
            COUNT(*) FILTER (WHERE status = 'empty') as empty,
            COUNT(DISTINCT program_name) as unique_programs,
            SUM(weeks_ingested) as weeks_ingested,
            SUM(duration_weeks) as weeks_expected
        FROM variant_status
        GROUP BY priority
    )
    SELECT
        priority,
        total_variants,
        complete,
        partial,
        empty,
        unique_programs,
        weeks_ingested,
        weeks_expected,
        ROUND(100.0 * weeks_ingested / NULLIF(weeks_expected, 0), 1) as pct
    FROM priority_stats
    ORDER BY
        CASE priority
            WHEN 'High' THEN 1
            WHEN 'Med' THEN 2
            WHEN 'Low' THEN 3
            ELSE 4
        END;
    """

    print("Updating program_analysis view...")
    cur.execute(sql)
    print("View updated successfully!")

    # Query the new view
    cur.execute("SELECT * FROM program_analysis;")
    rows = cur.fetchall()

    print("\n=== PROGRAM ANALYSIS ===")
    print(f"{'Priority':<10} {'Variants':<10} {'Complete':<10} {'Partial':<10} {'Empty':<8} {'Programs':<10} {'Weeks Done':<12} {'Weeks Expected':<15} {'%':<8}")
    print("-" * 95)

    for row in rows:
        priority, total_variants, complete, partial, empty, unique_programs, weeks_ingested, weeks_expected, pct = row
        print(f"{priority:<10} {total_variants:<10} {complete:<10} {partial:<10} {empty:<8} {unique_programs:<10} {weeks_ingested:<12} {weeks_expected:<15} {pct}%")

    cur.close()
    conn.close()

if __name__ == "__main__":
    update_view()
