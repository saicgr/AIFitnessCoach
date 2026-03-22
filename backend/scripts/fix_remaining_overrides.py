#!/usr/bin/env python3
"""
Fix remaining 24 country override files that have deep duplicate issues.
Strategy: Execute each row as an individual INSERT with ON CONFLICT.
"""
import os
import sys
import re
import glob
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

# The 24 files that failed dedup
FAILED_FILES = [
    "1693_overrides_CR_costa_rica.sql",
    "1700_overrides_DJ_djibouti.sql",
    "1702_overrides_DO_dominican_republic.sql",
    "1705_overrides_SV_el_salvador.sql",
    "1715_overrides_GM_gambia.sql",
    "1723_overrides_GU_guam.sql",
    "1726_overrides_GN_guinea.sql",
    "1727_overrides_GW_guinea_bissau.sql",
    "1731_overrides_HN_honduras.sql",
    "1734_overrides_IN_india.sql",
    "1743_overrides_JM_jamaica.sql",
    "1750_overrides_KI_kiribati.sql",
    "1757_overrides_LS_lesotho.sql",
    "1758_overrides_LR_liberia.sql",
    "1763_overrides_MO_macau.sql",
    "1768_overrides_MV_maldives.sql",
    "1773_overrides_MR_mauritania.sql",
    "1774_overrides_MU_mauritius.sql",
    "1775_overrides_MX_mexico.sql",
    "1784_overrides_MM_myanmar.sql",
    "1790_overrides_NC_new_caledonia.sql",
    "1792_overrides_NI_nicaragua.sql",
    "1795_overrides_MP_northern_mariana_islands.sql",
]


def get_conn():
    return psycopg2.connect(
        host=DATABASE_HOST, port=DATABASE_PORT, dbname=DATABASE_NAME,
        user=DATABASE_USER, password=DATABASE_PASSWORD, sslmode="require"
    )


def extract_rows(sql_text):
    """Extract individual row tuples from INSERT ... VALUES ... ON CONFLICT SQL."""
    # Find header (INSERT INTO ... VALUES\n)
    m = re.search(r'(INSERT\s+INTO\s+\S+\s*\([^)]+\)\s*VALUES\s*\n)', sql_text, re.IGNORECASE)
    if not m:
        return None, None, None

    header = m.group(1)
    rest = sql_text[m.end():]

    # Find ON CONFLICT
    oc = re.search(r'\nON CONFLICT ', rest)
    if not oc:
        return None, None, None

    values_part = rest[:oc.start()]
    footer = rest[oc.start():]

    # Parse rows - handle strings properly
    rows = []
    current = ''
    depth = 0
    i = 0

    while i < len(values_part):
        c = values_part[i]

        # Handle strings
        if c == "'" and depth > 0:
            current += c
            i += 1
            while i < len(values_part):
                c2 = values_part[i]
                current += c2
                i += 1
                if c2 == "'":
                    if i < len(values_part) and values_part[i] == "'":
                        current += "'"
                        i += 1
                    else:
                        break
            continue

        if c == '(':
            depth += 1
            current += c
        elif c == ')':
            depth -= 1
            current += c
            if depth == 0:
                rows.append(current.strip())
                current = ''
        elif depth > 0:
            current += c
        # else: skip chars between rows (commas, whitespace)

        i += 1

    return header, rows, footer


def get_food_name(row):
    """Extract food_name_normalized from row."""
    # Match first quoted string
    m = re.match(r"\(\s*'((?:[^']|'')*?)'", row)
    if m:
        return m.group(1).replace("''", "'")
    return None


def process_file(conn, filepath):
    """Process by executing each unique row individually."""
    sql_text = filepath.read_text()
    header, rows, footer = extract_rows(sql_text)

    if not rows:
        return False, "Could not parse file"

    # Deduplicate: keep last occurrence
    seen = {}
    for i, row in enumerate(rows):
        name = get_food_name(row)
        if name:
            seen[name] = row
        else:
            seen[f"_unk_{i}"] = row

    unique_rows = list(seen.values())
    removed = len(rows) - len(unique_rows)

    # Try bulk insert first with deduped rows
    bulk_sql = f"{header}{','.join(unique_rows)}{footer}"
    try:
        with conn.cursor() as cur:
            cur.execute(bulk_sql)
        conn.commit()
        return True, f"bulk ok, removed {removed} dupes from {len(rows)} rows"
    except Exception as e:
        conn.rollback()
        # If bulk still fails, do row-by-row
        pass

    # Row-by-row fallback
    inserted = 0
    errors = 0
    for row in unique_rows:
        single_sql = f"{header}{row}{footer}"
        try:
            with conn.cursor() as cur:
                cur.execute(single_sql)
            conn.commit()
            inserted += 1
        except Exception as e:
            conn.rollback()
            errors += 1

    return True, f"row-by-row: {inserted} inserted, {errors} errors, {removed} dupes removed"


def main():
    conn = get_conn()
    print("=" * 70)
    print("FIX REMAINING COUNTRY OVERRIDE FILES")
    print("=" * 70)

    # Also detect any we missed
    all_override_files = sorted(glob.glob(str(MIGRATIONS_DIR / "*_overrides_[A-Z][A-Z]_*.sql")))
    all_override_files = [
        Path(f) for f in all_override_files
        if re.match(r'1[6-8]\d\d_overrides_', os.path.basename(f))
    ]

    # Check which regions are already loaded
    with conn.cursor() as cur:
        cur.execute("SELECT DISTINCT region FROM food_nutrition_overrides WHERE region IS NOT NULL")
        existing_regions = {r[0] for r in cur.fetchall()}

    # Find files whose region code is NOT in the DB yet
    missing_files = []
    for f in all_override_files:
        # Extract region code from filename
        m = re.search(r'_overrides_([A-Z]{2})_', f.name)
        if m:
            region = m.group(1)
            if region not in existing_regions:
                missing_files.append(f)

    # Also include known failed files that may have partial data
    known_failed = [MIGRATIONS_DIR / name for name in FAILED_FILES if (MIGRATIONS_DIR / name).exists()]

    # Combine and deduplicate
    files_to_process = list({str(f): f for f in (missing_files + known_failed)}.values())
    files_to_process.sort(key=lambda f: f.name)

    print(f"  Files to process: {len(files_to_process)}")
    print(f"  Existing regions in DB: {len(existing_regions)}")

    start_time = time.time()
    for filepath in files_to_process:
        ok, info = process_file(conn, filepath)
        status = "OK" if ok else "FAILED"
        print(f"  {status}: {filepath.name} -> {info}")

    # Now populate country_name for new rows
    print("\n  Populating country_name for new rows...")
    populate_sql = Path(MIGRATIONS_DIR / "1869_populate_country_names.sql").read_text()
    try:
        with conn.cursor() as cur:
            cur.execute(populate_sql)
        conn.commit()
        print("  country_name populated")
    except Exception as e:
        conn.rollback()
        print(f"  country_name populate failed: {e}")

    # Verification
    print(f"\n{'='*70}")
    print("VERIFICATION")
    print(f"{'='*70}")
    with conn.cursor() as cur:
        cur.execute("SELECT COUNT(*) FROM food_nutrition_overrides WHERE is_active = TRUE;")
        print(f"  Active overrides: {cur.fetchone()[0]}")

        cur.execute("SELECT COUNT(DISTINCT region) FROM food_nutrition_overrides WHERE region IS NOT NULL;")
        print(f"  Distinct regions: {cur.fetchone()[0]}")

        cur.execute("SELECT COUNT(*) FROM food_nutrition_overrides WHERE region IS NOT NULL AND country_name IS NULL;")
        print(f"  Rows missing country_name: {cur.fetchone()[0]}")

        cur.execute("""
            SELECT region, COUNT(*) as cnt FROM food_nutrition_overrides
            WHERE region IS NOT NULL GROUP BY region ORDER BY cnt DESC LIMIT 15;
        """)
        print(f"\n  Top 15 regions:")
        for region, cnt in cur.fetchall():
            print(f"    {region}: {cnt}")

        cur.execute("""
            SELECT DISTINCT country_name FROM food_nutrition_overrides
            WHERE country_name IS NOT NULL ORDER BY country_name;
        """)
        all_countries = [r[0] for r in cur.fetchall()]
        print(f"\n  All {len(all_countries)} countries with names:")
        for c in all_countries:
            print(f"    {c}")

    conn.close()
    print(f"\n{'='*70}")
    print(f"DONE in {time.time() - start_time:.1f}s")


if __name__ == "__main__":
    main()
