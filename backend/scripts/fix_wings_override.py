"""One-shot cleanup: remove the bare 'wings' variant from any
food_nutrition_overrides row whose display_name does not contain "wing".

Why this exists:
  Backend logs showed `[FoodDB] OVERRIDE HIT (variant): 'wings' →
  Chicken Barbecue Timor`. A row whose display_name is
  "Chicken Barbecue Timor" has been tagged with the variant 'wings',
  which is wrong. The Step-2 variant-name match in
  food_database_lookup_service_helpers.py picked it up as the
  canonical answer for the user's query.

  food_database_lookup_service_helpers.py now has a sanity gate that
  rejects this kind of stem-mismatch at runtime, but the underlying
  bad data should still be cleaned so other code paths and future
  audits stay honest.

Run:
    cd backend && .venv/bin/python scripts/fix_wings_override.py [--dry-run]
"""
from __future__ import annotations

import argparse
import os
import sys

import psycopg2
from dotenv import load_dotenv


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true", help="Report only, no writes")
    args = parser.parse_args()

    load_dotenv()
    raw_url = os.environ.get("DATABASE_URL")
    if not raw_url:
        print("DATABASE_URL not set", file=sys.stderr)
        return 1
    url = raw_url.replace("postgresql+asyncpg://", "postgresql://").replace(
        "postgresql+psycopg://", "postgresql://"
    )

    conn = psycopg2.connect(url)
    conn.autocommit = False
    cur = conn.cursor()

    cur.execute(
        """
        SELECT id, display_name, food_name_normalized, variant_names
        FROM food_nutrition_overrides
        WHERE 'wings' = ANY(variant_names);
        """
    )
    rows = cur.fetchall()
    if not rows:
        print("No rows have 'wings' as an exact variant.")
        return 0

    print(f"Found {len(rows)} row(s) with bare 'wings' variant:\n")
    bad_ids: list[int] = []
    for row_id, display_name, fn_norm, variants in rows:
        dn_lower = (display_name or "").lower()
        fn_lower = (fn_norm or "").replace("_", " ").lower()
        is_bad = ("wing" not in dn_lower) and ("wing" not in fn_lower)
        flag = "BAD " if is_bad else "OK  "
        print(f"  {flag} id={row_id}  '{display_name}'  variants={variants}")
        if is_bad:
            bad_ids.append(row_id)

    if not bad_ids:
        print("\nAll rows are legitimate — nothing to clean.")
        return 0

    print(f"\nWill remove 'wings' from variant_names on {len(bad_ids)} bad row(s).")
    if args.dry_run:
        print("--dry-run set; no changes written.")
        return 0

    cur.execute(
        """
        UPDATE food_nutrition_overrides
        SET variant_names = array_remove(variant_names, 'wings')
        WHERE id = ANY(%s);
        """,
        (bad_ids,),
    )
    affected = cur.rowcount
    conn.commit()
    print(f"Updated {affected} row(s).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
