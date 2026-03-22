#!/usr/bin/env python3
"""
Deduplicates food_name_normalized keys within each country override SQL file.
Some files were generated with duplicate keys in a single INSERT block, which
PostgreSQL rejects even with ON CONFLICT DO UPDATE.
"""
import os
import re
import sys
import glob
import argparse

MIGRATIONS_DIR = os.path.join(os.path.dirname(__file__), '..', 'migrations')


def fix_sql_file(filepath: str, dry_run: bool = False) -> tuple[int, int]:
    """
    Deduplicate rows by food_name_normalized in a SQL file.
    Returns (original_count, deduped_count).
    """
    with open(filepath, encoding='utf-8') as f:
        content = f.read()

    # Fix Python None written as bare SQL identifier instead of NULL
    content = re.sub(r'(?<![a-zA-Z_\'"])None(?![a-zA-Z_\'"])', 'NULL', content)

    # Find the VALUES block — everything from first '(' after VALUES to final ';'
    values_match = re.search(r'\)\s*VALUES\s*\n(.*?)(?:\n\s*ON CONFLICT|\Z)', content, re.DOTALL)
    if not values_match:
        return 0, 0

    values_block = values_match.group(1)

    # Split into individual row strings using line-based approach
    # Each row starts with optional whitespace then '('
    row_pattern = re.compile(r'^\s*\(', re.MULTILINE)
    positions = [m.start() for m in row_pattern.finditer(values_block)]
    positions.append(len(values_block))

    rows = []
    for i in range(len(positions) - 1):
        row = values_block[positions[i]:positions[i+1]].strip().rstrip(',').strip()
        if row.startswith('(') and row.endswith(')'):
            rows.append(row)

    if not rows:
        return 0, 0

    # Extract food_name_normalized (first quoted value in each row)
    seen_keys = set()
    deduped_rows = []
    for row in rows:
        key_match = re.match(r"\('([^']+)'", row)
        if not key_match:
            deduped_rows.append(row)
            continue
        key = key_match.group(1)
        if key in seen_keys:
            continue
        seen_keys.add(key)
        deduped_rows.append(row)

    original_count = len(rows)
    deduped_count = len(deduped_rows)

    if original_count == deduped_count:
        return original_count, deduped_count  # nothing to do

    if not dry_run:
        # Rebuild the VALUES block
        new_values = ',\n'.join(deduped_rows)
        new_content = content.replace(values_match.group(1), new_values + '\n')
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)

    return original_count, deduped_count


def main():
    parser = argparse.ArgumentParser(description='Fix duplicate food_name_normalized in override SQL files')
    parser.add_argument('--dry-run', action='store_true', help='Show what would change without writing files')
    parser.add_argument('--files', nargs='*', help='Specific files to fix (default: all country override files)')
    args = parser.parse_args()

    pattern = os.path.join(MIGRATIONS_DIR, '*_overrides_[A-Z][A-Z]_*.sql')
    files = args.files or sorted(glob.glob(pattern))

    fixed = 0
    skipped = 0
    errors = 0

    for filepath in files:
        fname = os.path.basename(filepath)
        try:
            orig, deduped = fix_sql_file(filepath, dry_run=args.dry_run)
            if orig == 0:
                skipped += 1
                continue
            if orig != deduped:
                removed = orig - deduped
                action = 'would remove' if args.dry_run else 'removed'
                print(f'  FIXED {fname}: {action} {removed} duplicate(s) ({orig} -> {deduped} rows)')
                fixed += 1
            else:
                skipped += 1
        except Exception as e:
            print(f'  ERROR {fname}: {e}', file=sys.stderr)
            errors += 1

    print(f'\nDone: {fixed} files fixed, {skipped} clean, {errors} errors')
    if args.dry_run:
        print('(dry run — no files written)')


if __name__ == '__main__':
    main()
