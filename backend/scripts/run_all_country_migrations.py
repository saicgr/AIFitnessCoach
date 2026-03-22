#!/usr/bin/env python3
"""
Run all pending country food override migrations and related fix migrations.
Steps:
  1. Check/apply schema prerequisites (277, 1646)
  2. Apply 1868_add_country_name_column.sql
  3. Apply all 212 country override migrations (1650-1865)
  4. Apply misc fix migrations
  5. Apply 1869_populate_country_names.sql
  6. Run verification queries
"""
import os
import sys
import glob
import re
import time
from pathlib import Path

# Load .env
env_path = Path(__file__).parent.parent / ".env"
if env_path.exists():
    for line in env_path.read_text().splitlines():
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            k, v = line.split("=", 1)
            os.environ.setdefault(k.strip(), v.strip())

import psycopg2

DATABASE_HOST = os.environ.get("DATABASE_HOST", "db.hpbzfahijszqmgsybuor.supabase.co")
DATABASE_PORT = int(os.environ.get("DATABASE_PORT", 5432))
DATABASE_NAME = os.environ.get("DATABASE_NAME", "postgres")
DATABASE_USER = os.environ.get("DATABASE_USER", "postgres")
DATABASE_PASSWORD = os.environ.get("DATABASE_PASSWORD") or os.environ.get("SUPABASE_DB_PASSWORD")

if not DATABASE_PASSWORD:
    print("ERROR: DATABASE_PASSWORD or SUPABASE_DB_PASSWORD required")
    sys.exit(1)

MIGRATIONS_DIR = Path(__file__).parent.parent / "migrations"


def get_conn():
    return psycopg2.connect(
        host=DATABASE_HOST, port=DATABASE_PORT, dbname=DATABASE_NAME,
        user=DATABASE_USER, password=DATABASE_PASSWORD, sslmode="require"
    )


def column_exists(cur, table, column):
    cur.execute(
        "SELECT 1 FROM information_schema.columns WHERE table_name=%s AND column_name=%s",
        (table, column)
    )
    return cur.fetchone() is not None


def table_exists(cur, table):
    cur.execute(
        "SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name=%s",
        (table,)
    )
    return cur.fetchone() is not None


def run_sql_file(conn, filepath, description=None):
    name = filepath.name if isinstance(filepath, Path) else os.path.basename(filepath)
    desc = description or name
    try:
        sql = Path(filepath).read_text()
        with conn.cursor() as cur:
            cur.execute(sql)
        conn.commit()
        return True
    except Exception as e:
        conn.rollback()
        print(f"  FAILED: {desc} -> {e}")
        return False


def main():
    conn = get_conn()
    print("="*70)
    print("COUNTRY FOOD OVERRIDE MIGRATION RUNNER")
    print("="*70)

    # ── Step 1: Prerequisites ──
    print("\n[Step 1] Checking schema prerequisites...")
    with conn.cursor() as cur:
        # Check if restaurant_category columns exist (from migration 277)
        has_restaurant = column_exists(cur, "food_nutrition_overrides", "restaurant_category")
        # Check if region column exists (from migration 1646)
        has_region = column_exists(cur, "food_nutrition_overrides", "region")

    if not has_restaurant:
        print("  Applying 277_add_restaurant_category_columns.sql ...")
        f = MIGRATIONS_DIR / "277_add_restaurant_category_columns.sql"
        if f.exists():
            ok = run_sql_file(conn, f)
            print(f"  {'SUCCESS' if ok else 'FAILED'}")
            if not ok:
                conn.close(); sys.exit(1)
        else:
            print(f"  WARNING: {f.name} not found, skipping")
    else:
        print("  restaurant_category column already exists - skipping 277")

    if not has_region:
        print("  Applying 1646_add_region_column.sql ...")
        f = MIGRATIONS_DIR / "1646_add_region_column.sql"
        if f.exists():
            ok = run_sql_file(conn, f)
            print(f"  {'SUCCESS' if ok else 'FAILED'}")
            if not ok:
                conn.close(); sys.exit(1)
        else:
            print(f"  WARNING: {f.name} not found, skipping")
    else:
        print("  region column already exists - skipping 1646")

    # ── Step 2: Add country_name column ──
    print("\n[Step 2] Adding country_name column...")
    with conn.cursor() as cur:
        has_country_name = column_exists(cur, "food_nutrition_overrides", "country_name")
    if not has_country_name:
        ok = run_sql_file(conn, MIGRATIONS_DIR / "1868_add_country_name_column.sql")
        print(f"  {'SUCCESS' if ok else 'FAILED'}")
        if not ok:
            conn.close(); sys.exit(1)
    else:
        print("  country_name column already exists - skipping")

    # ── Step 3: Run all country override migrations ──
    print("\n[Step 3] Running 212 country override migrations...")
    override_files = sorted(glob.glob(str(MIGRATIONS_DIR / "*_overrides_[A-Z][A-Z]_*.sql")))
    # Filter to 1650-1865 range
    override_files = [
        f for f in override_files
        if re.match(r'1[6-8]\d\d_overrides_', os.path.basename(f))
    ]
    print(f"  Found {len(override_files)} override migration files")

    success_count = 0
    fail_count = 0
    start_time = time.time()

    for i, filepath in enumerate(override_files):
        name = os.path.basename(filepath)
        ok = run_sql_file(conn, filepath)
        if ok:
            success_count += 1
        else:
            fail_count += 1
        # Print progress every 20 files
        if (i + 1) % 20 == 0 or (i + 1) == len(override_files):
            elapsed = time.time() - start_time
            print(f"  Progress: {i+1}/{len(override_files)} ({success_count} ok, {fail_count} failed) [{elapsed:.1f}s]")

    print(f"\n  Country overrides complete: {success_count} succeeded, {fail_count} failed")

    # ── Step 4: Misc fix migrations ──
    print("\n[Step 4] Running misc fix migrations...")
    fix_migrations = [
        "1670_email_send_log.sql",
        "1674_fix_gym_profile_coach_colors.sql",
        "1675_fix_nutrition_goals_in_rpc.sql",
        "1676_fix_progress_summary_ambiguous_column.sql",
        "280_fix_media_jobs_user_id_fk.sql",
        "1864_add_ai_chat_messages_gate.sql",
        "1865_sync_nutrition_targets_to_users.sql",
        "1866_fix_feature_usage_rls.sql",
        "1867_fix_story_views_rls.sql",
        "1868_add_reset_period_to_feature_gates.sql",
        "1869_add_media_url_to_chat_history.sql",
        "1870_fix_first_login_xp.sql",
    ]

    for mig_name in fix_migrations:
        f = MIGRATIONS_DIR / mig_name
        if not f.exists():
            print(f"  SKIP (not found): {mig_name}")
            continue
        ok = run_sql_file(conn, f)
        print(f"  {'OK' if ok else 'FAILED'}: {mig_name}")

    # ── Step 5: Populate country names ──
    print("\n[Step 5] Populating country_name from region...")
    ok = run_sql_file(conn, MIGRATIONS_DIR / "1869_populate_country_names.sql")
    print(f"  {'SUCCESS' if ok else 'FAILED'}")

    # ── Step 6: Verification ──
    print("\n" + "="*70)
    print("VERIFICATION")
    print("="*70)

    with conn.cursor() as cur:
        cur.execute("SELECT COUNT(*) FROM food_nutrition_overrides WHERE is_active = TRUE;")
        active_count = cur.fetchone()[0]
        print(f"\n  Active food overrides: {active_count}")

        cur.execute("SELECT COUNT(DISTINCT region) FROM food_nutrition_overrides WHERE region IS NOT NULL;")
        region_count = cur.fetchone()[0]
        print(f"  Distinct regions: {region_count}")

        cur.execute("""
            SELECT DISTINCT country_name FROM food_nutrition_overrides
            WHERE country_name IS NOT NULL ORDER BY country_name LIMIT 15;
        """)
        countries = [r[0] for r in cur.fetchall()]
        print(f"\n  Sample country names ({len(countries)} shown):")
        for c in countries:
            print(f"    - {c}")

        cur.execute("""
            SELECT region, COUNT(*) as cnt FROM food_nutrition_overrides
            WHERE region IS NOT NULL GROUP BY region ORDER BY cnt DESC LIMIT 10;
        """)
        top_regions = cur.fetchall()
        print(f"\n  Top 10 regions by food count:")
        for region, cnt in top_regions:
            print(f"    {region}: {cnt}")

        # Check country_name population
        cur.execute("""
            SELECT COUNT(*) FROM food_nutrition_overrides
            WHERE region IS NOT NULL AND country_name IS NULL;
        """)
        missing_names = cur.fetchone()[0]
        print(f"\n  Rows with region but no country_name: {missing_names}")

    conn.close()
    total_time = time.time() - start_time
    print(f"\n{'='*70}")
    print(f"ALL DONE in {total_time:.1f}s")
    print(f"{'='*70}")


if __name__ == "__main__":
    main()
