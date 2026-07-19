#!/usr/bin/env python3
"""
Clean up already-logged PHANTOM food items in `food_logs`.

CONTEXT (2026-07)
-----------------
The client logs a food as a comma-joined string `"{name}, {weight}g"`
(e.g. "Almond Joy King Size, 91g"). A degraded parse in
`services/gemini/nutrition.analyze_food` sometimes split that on the comma and
invented a SECOND item named "Generic Food"/"Food" (or the bare portion token
"91g") with made-up macros — so a single logged food shipped as "2 ITEMS" with a
phantom. The read-time fix (`collapse_phantom_food_items` + prompt hardening in
nutrition.py) stops NEW phantoms; this script repairs rows ALREADY written.

WHAT IT TOUCHES
  A `food_logs` row is repaired only when its `food_items` JSON array holds >1
  item AND at least one item is a phantom (generic placeholder name OR a pure
  quantity token) AND at least one sibling is a REAL item (duplicate-of-parent).
  It then drops the phantom(s) (their macros are hallucinated, so they are NOT
  folded into the real item — a 0-cal "Diet Coke" must not inherit a phantom's
  533 cal) and recomputes the row's total_calories / protein_g / carbs_g /
  fat_g / fiber_g from the remaining items. Logs with a single item, or where
  EVERY item looks generic, are left untouched.

  Detection mirrors `services.gemini.nutrition` (kept inline so the script stays
  self-contained — importing that module pulls in the Gemini client).

USAGE
  python3 scripts/cleanup_phantom_food_items.py                 # dry-run, all users
  python3 scripts/cleanup_phantom_food_items.py --user-id U     # dry-run, one user
  python3 scripts/cleanup_phantom_food_items.py --apply         # WRITE all users
  python3 scripts/cleanup_phantom_food_items.py --user-id U --apply --verbose

  --apply      perform writes (default is dry-run, writes nothing)
  --user-id    scope to a single user_id
  --limit      cap number of rows scanned (debugging)
  --verbose    print every row that would change, with before/after items
"""
from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path

BACKEND_DIR = Path(__file__).parent.parent
sys.path.insert(0, str(BACKEND_DIR))

from dotenv import load_dotenv  # noqa: E402

load_dotenv(BACKEND_DIR / ".env")

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

# ── Phantom detection (mirrors services/gemini/nutrition.py) ──────────────────
_GENERIC_ITEM_NAMES = {"food", "generic food", "", "item", "meal", "snack"}
_PORTION_TOKEN_RE = re.compile(
    r"^\s*[\d.]+\s*(?:g|kg|oz|ml|serving|cup|slice)s?\s*$", re.IGNORECASE
)
_MACRO_KEYS = ("calories", "protein_g", "carbs_g", "fat_g", "fiber_g")
# Item macro key -> food_logs row column.
_ROW_TOTAL_COLS = {
    "calories": "total_calories",
    "protein_g": "protein_g",
    "carbs_g": "carbs_g",
    "fat_g": "fat_g",
    "fiber_g": "fiber_g",
}


def _is_phantom_item_name(name) -> bool:
    n = (name or "").strip().lower()
    return n in _GENERIC_ITEM_NAMES or bool(_PORTION_TOKEN_RE.match(n))


def _num(v) -> float:
    try:
        return float(v or 0)
    except (TypeError, ValueError):
        return 0.0


def collapse_phantom_food_items(items):
    """Return (cleaned_items, phantom_names) — drop generic/portion-token phantoms
    when >1 item AND a real sibling remains. The phantom's macros are DROPPED,
    never folded: they are hallucinated (the model invents ~1-1.5 cal/g for the
    split-off portion token), so folding them corrupts genuinely-zero-calorie
    foods — e.g. "Diet Coke" (0 cal) + phantom "Generic Food" (533 cal) must
    stay 0 cal, not become 533. Returns (items, []) when nothing should change."""
    if not isinstance(items, list) or len(items) <= 1:
        return items, []
    real = [it for it in items if isinstance(it, dict) and not _is_phantom_item_name(it.get("name"))]
    phantoms = [it for it in items if isinstance(it, dict) and _is_phantom_item_name(it.get("name"))]
    if not phantoms or not real:
        return items, []

    return real, [p.get("name") for p in phantoms]


def _recompute_row_totals(items):
    """Row-level totals recomputed from the surviving items."""
    totals = {}
    for macro_key, col in _ROW_TOTAL_COLS.items():
        total = sum(_num(it.get(macro_key)) for it in items if isinstance(it, dict))
        totals[col] = round(total, 1) if macro_key != "calories" else round(total)
    return totals


def _get_client():
    from supabase import create_client
    if not (SUPABASE_URL and SUPABASE_KEY):
        raise SystemExit("SUPABASE_URL / SUPABASE_KEY not set in backend/.env")
    return create_client(SUPABASE_URL, SUPABASE_KEY)


def main():
    ap = argparse.ArgumentParser(description="Remove phantom food items from food_logs.")
    ap.add_argument("--apply", action="store_true", help="perform writes (default: dry-run)")
    ap.add_argument("--user-id", help="scope to a single user_id")
    ap.add_argument("--limit", type=int, help="cap rows scanned (debugging)")
    ap.add_argument("--verbose", action="store_true", help="print each planned change")
    args = ap.parse_args()

    sb = _get_client()

    scanned = 0
    changed = 0
    phantoms_removed = 0
    page = 0
    page_size = 500

    while True:
        q = (sb.table("food_logs")
             .select("id, user_id, food_name, food_items, total_calories, "
                     "protein_g, carbs_g, fat_g, fiber_g")
             .is_("deleted_at", "null")
             .order("id")
             .range(page * page_size, page * page_size + page_size - 1))
        if args.user_id:
            q = q.eq("user_id", args.user_id)
        rows = (q.execute().data) or []
        if not rows:
            break

        for row in rows:
            if args.limit and scanned >= args.limit:
                rows = []
                break
            scanned += 1
            items = row.get("food_items")
            cleaned, removed = collapse_phantom_food_items(items)
            if not removed:
                continue

            changed += 1
            phantoms_removed += len(removed)
            totals = _recompute_row_totals(cleaned)

            if args.verbose or not args.apply:
                before = [it.get("name") for it in items if isinstance(it, dict)]
                after = [it.get("name") for it in cleaned if isinstance(it, dict)]
                print(f"  log {row['id']} ({row.get('food_name')!r}) "
                      f"drop {removed} | {before} -> {after} | totals -> {totals}")

            if args.apply:
                update = {"food_items": cleaned, **totals}
                (sb.table("food_logs").update(update).eq("id", row["id"]).execute())

        if not rows or (args.limit and scanned >= args.limit):
            break
        page += 1

    mode = "APPLIED" if args.apply else "DRY-RUN (no writes)"
    print(f"\n[{mode}] scanned={scanned} rows_with_phantoms={changed} "
          f"phantom_items_removed={phantoms_removed}")


if __name__ == "__main__":
    main()
