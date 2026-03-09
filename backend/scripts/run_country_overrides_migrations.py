#!/usr/bin/env python3
"""
Batch-run country-specific food override migrations (1647–1859).

Usage:
    python run_country_overrides_migrations.py                    # Run all 213 country migrations
    python run_country_overrides_migrations.py --country JP       # Run only Japan
    python run_country_overrides_migrations.py --start 1647 --end 1660  # Run a range
    python run_country_overrides_migrations.py --dry-run          # Validate SQL without executing
"""
import argparse
import glob
import os
import re
import sys
import time
from pathlib import Path

import psycopg2

DATABASE_HOST = os.environ.get("DATABASE_HOST", "db.hpbzfahijszqmgsybuor.supabase.co")
DATABASE_PORT = int(os.environ.get("DATABASE_PORT", 5432))
DATABASE_NAME = os.environ.get("DATABASE_NAME", "postgres")
DATABASE_USER = os.environ.get("DATABASE_USER", "postgres")
DATABASE_PASSWORD = os.environ.get("DATABASE_PASSWORD") or os.environ.get("SUPABASE_DB_PASSWORD")
if not DATABASE_PASSWORD:
    raise SystemExit("DATABASE_PASSWORD or SUPABASE_DB_PASSWORD environment variable is required")

MIGRATIONS_DIR = Path(__file__).parent.parent / "migrations"


def get_migration_files(country: str = None, start: int = None, end: int = None):
    """Get sorted list of country override migration files, optionally filtered."""
    pattern = str(MIGRATIONS_DIR / "1*_overrides_??_*.sql")
    files = sorted(glob.glob(pattern))

    # Filter to only 1647-1859 range
    result = []
    for f in files:
        basename = os.path.basename(f)
        match = re.match(r"(\d+)_overrides_([A-Z]{2})_", basename)
        if not match:
            continue
        num = int(match.group(1))
        cc = match.group(2)
        if num < 1647 or num > 1859:
            continue
        if country and cc != country.upper():
            continue
        if start and num < start:
            continue
        if end and num > end:
            continue
        result.append((num, cc, f))

    return result


def run_migrations(files, dry_run=False):
    """Execute migration files sequentially."""
    if not files:
        print("No migration files found matching criteria.")
        return

    print(f"\n{'='*60}")
    print(f"Country Override Migrations: {len(files)} file(s)")
    print(f"Mode: {'DRY RUN (validate only)' if dry_run else 'EXECUTE'}")
    print(f"{'='*60}\n")

    if not dry_run:
        conn = psycopg2.connect(
            host=DATABASE_HOST, port=DATABASE_PORT, dbname=DATABASE_NAME,
            user=DATABASE_USER, password=DATABASE_PASSWORD, sslmode="require"
        )

    succeeded = 0
    failed = 0
    total_rows = 0

    for i, (num, cc, filepath) in enumerate(files, 1):
        basename = os.path.basename(filepath)
        print(f"[{i}/{len(files)}] {basename} ...", end=" ", flush=True)

        try:
            with open(filepath, 'r') as f:
                sql = f.read()

            if dry_run:
                # Count INSERT rows (lines starting with '(' that have data)
                row_count = sql.count("', '")  # rough estimate from VALUES
                # Better: count lines that start with ('
                row_count = len(re.findall(r"^\('", sql, re.MULTILINE))
                print(f"OK ({row_count} rows)")
                total_rows += row_count
                succeeded += 1
            else:
                t0 = time.time()
                with conn.cursor() as cur:
                    cur.execute(sql)
                conn.commit()
                elapsed = time.time() - t0

                # Count affected rows
                with conn.cursor() as cur:
                    cur.execute(
                        "SELECT count(*) FROM food_nutrition_overrides WHERE region = %s",
                        (cc,)
                    )
                    count = cur.fetchone()[0]

                print(f"OK ({count} rows, {elapsed:.1f}s)")
                total_rows += count
                succeeded += 1

        except Exception as e:
            print(f"FAILED: {e}")
            if not dry_run:
                conn.rollback()
            failed += 1

    if not dry_run and 'conn' in dir():
        conn.close()

    print(f"\n{'='*60}")
    print(f"SUMMARY")
    print(f"  Succeeded: {succeeded}")
    print(f"  Failed:    {failed}")
    print(f"  Total rows: {total_rows}")
    print(f"{'='*60}")

    return failed == 0


def main():
    parser = argparse.ArgumentParser(description="Run country food override migrations")
    parser.add_argument("--country", type=str, help="ISO 3166-1 alpha-2 country code (e.g., JP)")
    parser.add_argument("--start", type=int, help="Start migration number (e.g., 1647)")
    parser.add_argument("--end", type=int, help="End migration number (e.g., 1660)")
    parser.add_argument("--dry-run", action="store_true", help="Validate SQL without executing")
    args = parser.parse_args()

    files = get_migration_files(country=args.country, start=args.start, end=args.end)
    success = run_migrations(files, dry_run=args.dry_run)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
