#!/usr/bin/env python3
"""
Deduplicates country override migration files (removes duplicate food_name_normalized
within a single INSERT) and applies them to Supabase.

Strategy: Read each file, find the INSERT header and ON CONFLICT footer,
extract individual value rows, deduplicate by food_name_normalized (keep last),
rebuild and execute.
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


def get_conn():
    return psycopg2.connect(
        host=DATABASE_HOST, port=DATABASE_PORT, dbname=DATABASE_NAME,
        user=DATABASE_USER, password=DATABASE_PASSWORD, sslmode="require"
    )


def parse_migration(sql_text):
    """
    Parse a migration file into:
    - header: everything up to and including ') VALUES\n'
    - rows: list of individual row strings like "('name', ...)"
    - footer: the ON CONFLICT ... clause
    """
    # Find "VALUES" and split
    m = re.search(r'(\)\s*VALUES\s*\n)', sql_text, re.IGNORECASE)
    if not m:
        return None, None, None

    header = sql_text[:m.end()]
    rest = sql_text[m.end():]

    # Find "ON CONFLICT" - it starts on its own line
    on_conflict_match = re.search(r'\nON CONFLICT ', rest)
    if not on_conflict_match:
        return None, None, None

    values_part = rest[:on_conflict_match.start()]
    footer = rest[on_conflict_match.start():]  # includes leading \n

    # Now parse values_part into individual row tuples
    rows = []
    current_row = ""
    paren_depth = 0
    in_string = False

    for i, ch in enumerate(values_part):
        if in_string:
            current_row += ch
            if ch == "'" and i + 1 < len(values_part) and values_part[i + 1] == "'":
                pass  # will be handled next iteration
            elif ch == "'" and (i == 0 or values_part[i - 1] != "'"):
                in_string = False
            continue

        if ch == "'":
            in_string = True
            current_row += ch
            continue

        if ch == '(':
            paren_depth += 1
            current_row += ch
            continue

        if ch == ')':
            paren_depth -= 1
            current_row += ch
            if paren_depth == 0:
                rows.append(current_row.strip())
                current_row = ""
            continue

        if paren_depth > 0:
            current_row += ch
        # Skip commas, whitespace between rows when paren_depth is 0

    return header, rows, footer


def extract_food_name(row_str):
    """Extract the first single-quoted value from a row tuple."""
    match = re.match(r"\(\s*'((?:[^']|'')*)'", row_str)
    if match:
        return match.group(1).replace("''", "'")
    return None


def dedup_rows(rows):
    """Keep only the last occurrence of each food_name_normalized."""
    seen = {}
    for i, row in enumerate(rows):
        name = extract_food_name(row)
        key = name if name else f"__unknown_{i}"
        seen[key] = (i, row)

    deduped = sorted(seen.values(), key=lambda x: x[0])
    return [row for _, row in deduped]


def process_and_apply(conn, filepath):
    """Process a migration file: dedup and apply."""
    sql_text = filepath.read_text()

    header, rows, footer = parse_migration(sql_text)
    if header is None or not rows:
        # Try running as-is
        try:
            with conn.cursor() as cur:
                cur.execute(sql_text)
            conn.commit()
            return True, 0
        except Exception as e:
            conn.rollback()
            return False, str(e)

    original_count = len(rows)
    deduped = dedup_rows(rows)
    removed = original_count - len(deduped)

    # Rebuild SQL
    rows_sql = ",\n".join(deduped)
    full_sql = f"{header}{rows_sql}{footer}"

    try:
        with conn.cursor() as cur:
            cur.execute(full_sql)
        conn.commit()
        return True, removed
    except Exception as e:
        conn.rollback()
        return False, str(e)


def main():
    conn = get_conn()
    print("=" * 70)
    print("DEDUP & APPLY COUNTRY OVERRIDE MIGRATIONS")
    print("=" * 70)

    override_files = sorted(glob.glob(str(MIGRATIONS_DIR / "*_overrides_[A-Z][A-Z]_*.sql")))
    override_files = [
        Path(f) for f in override_files
        if re.match(r'1[6-8]\d\d_overrides_', os.path.basename(f))
    ]
    print(f"Found {len(override_files)} override migration files\n")

    success_count = 0
    fail_count = 0
    total_dupes_removed = 0
    failed_files = []
    start_time = time.time()

    for i, filepath in enumerate(override_files):
        ok, info = process_and_apply(conn, filepath)
        if ok:
            success_count += 1
            if isinstance(info, int) and info > 0:
                total_dupes_removed += info
        else:
            fail_count += 1
            failed_files.append((filepath.name, info))

        if (i + 1) % 50 == 0 or (i + 1) == len(override_files):
            elapsed = time.time() - start_time
            print(f"  Progress: {i+1}/{len(override_files)} ({success_count} ok, {fail_count} failed, {total_dupes_removed} dupes removed) [{elapsed:.1f}s]")

    print(f"\n{'='*70}")
    print(f"RESULTS")
    print(f"{'='*70}")
    print(f"  Succeeded: {success_count}/{len(override_files)}")
    print(f"  Failed: {fail_count}/{len(override_files)}")
    print(f"  Duplicate rows removed: {total_dupes_removed}")

    if failed_files:
        print(f"\n  Failed files ({len(failed_files)}):")
        for name, err in failed_files[:10]:
            err_short = str(err)[:150]
            print(f"    {name}: {err_short}")

    # Verification
    print(f"\n{'='*70}")
    print("VERIFICATION")
    print(f"{'='*70}")
    with conn.cursor() as cur:
        cur.execute("SELECT COUNT(*) FROM food_nutrition_overrides WHERE is_active = TRUE;")
        print(f"  Active overrides: {cur.fetchone()[0]}")

        cur.execute("SELECT COUNT(DISTINCT region) FROM food_nutrition_overrides WHERE region IS NOT NULL;")
        print(f"  Distinct regions: {cur.fetchone()[0]}")

        cur.execute("""
            SELECT DISTINCT country_name FROM food_nutrition_overrides
            WHERE country_name IS NOT NULL ORDER BY country_name LIMIT 15;
        """)
        countries = [r[0] for r in cur.fetchall()]
        print(f"  Sample countries: {', '.join(countries)}")

        cur.execute("""
            SELECT region, COUNT(*) as cnt FROM food_nutrition_overrides
            WHERE region IS NOT NULL GROUP BY region ORDER BY cnt DESC LIMIT 10;
        """)
        print(f"\n  Top 10 regions by count:")
        for region, cnt in cur.fetchall():
            print(f"    {region}: {cnt}")

        cur.execute("SELECT COUNT(DISTINCT region) FROM food_nutrition_overrides WHERE region IS NOT NULL;")
        total_regions = cur.fetchone()[0]
        print(f"\n  Total distinct regions: {total_regions}")

        cur.execute("SELECT COUNT(*) FROM food_nutrition_overrides WHERE region IS NOT NULL AND country_name IS NULL;")
        missing = cur.fetchone()[0]
        print(f"  Rows missing country_name: {missing}")

    conn.close()
    print(f"\n{'='*70}")
    print(f"DONE in {time.time() - start_time:.1f}s")
    print(f"{'='*70}")


if __name__ == "__main__":
    main()
