#!/usr/bin/env python3
"""
Prove the live `feature_gates` table still matches the policy declared in code.

WHY THIS EXISTS
---------------
`feature_gates` is the row that WINS at runtime. `core/premium_gate._get_fallback_gate()`
is only consulted when a row is MISSING. So the constants in code are a
statement of intent, and the table is the enforced reality — and nothing ever
proved the two agreed.

They did not. On 2026-08-30 the live table read:

    ai_workout_generation   free_limit 100 / monthly   (code says 2 / monthly)
    food_scanning           free_limit 100 / monthly   (code says 1 / daily)
    text_to_calories        free_limit 100 / monthly   (code says 3 / daily)

i.e. the advertised free caps were never the enforced ones — a free user got
~100 AI workout generations and ~100 food scans a month, which is an unmetered
tier with a large number written next to it. Migration 268 had seeded the
correct 2/1/3 values, and no migration ever changed them; grep confirms NO code
path writes this table (every `.table("feature_gates")` call site is a
`.select()`). The drift therefore came from an out-of-band edit — a Supabase
dashboard change or a psql session — and there was no gate to notice.

The same edit also resurrected `ai_meal_plan`, a row migration 268 explicitly
DELETEd as a phantom.

WHAT IT CHECKS
--------------
FAIL (exit 1) — a key the code declares in PREMIUM_FEATURE_KEYS whose live row
    is missing, or whose free_limit / reset_period / minimum_tier / is_enabled
    differs from _get_fallback_gate(). This is the class that bit us.

WARN (exit 0) — a live row for a key the code never declares ("orphan"). These
    look like gates but gate nothing, because no call site passes the key.
    Reported, never auto-deleted: a production config row is not something an
    audit script should remove on its own.

USAGE
-----
    cd backend && set -a && source ./.env && set +a && \\
      .venv/bin/python scripts/audit_feature_gate_drift.py --check

    # push the code-declared policy INTO the table (fixes FAIL rows):
    ... audit_feature_gate_drift.py --apply

Run after any migration touching feature_gates, and after any manual edit.
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import psycopg2  # noqa: E402

from core.premium_gate import PREMIUM_FEATURE_KEYS, _get_fallback_gate  # noqa: E402

# Columns that constitute the enforced policy for one gate.
POLICY_COLUMNS = ("free_limit", "reset_period", "minimum_tier", "is_enabled")


def _dsn() -> str:
    try:
        return os.environ["DATABASE_URL"].replace("postgresql+asyncpg://", "postgresql://")
    except KeyError:
        sys.exit(
            "DATABASE_URL is not set. Run with:\n"
            "  cd backend && set -a && source ./.env && set +a && "
            ".venv/bin/python scripts/audit_feature_gate_drift.py --check"
        )


def _live_rows(cur) -> dict:
    cur.execute(
        "SELECT feature_key, free_limit, reset_period, minimum_tier, is_enabled "
        "FROM feature_gates"
    )
    return {
        r[0]: {
            "free_limit": r[1],
            "reset_period": r[2],
            "minimum_tier": r[3],
            "is_enabled": r[4],
        }
        for r in cur.fetchall()
    }


def audit(apply_fixes: bool) -> int:
    conn = psycopg2.connect(_dsn())
    conn.autocommit = True
    cur = conn.cursor()
    live = _live_rows(cur)

    failures = []  # (key, column, declared, actual) — declared policy violated
    missing = []   # keys declared in code with no row at all
    orphans = sorted(set(live) - set(PREMIUM_FEATURE_KEYS))

    for key in PREMIUM_FEATURE_KEYS:
        declared = _get_fallback_gate(key)
        row = live.get(key)
        if row is None:
            missing.append(key)
            continue
        for col in POLICY_COLUMNS:
            if row[col] != declared[col]:
                failures.append((key, col, declared[col], row[col]))

    if apply_fixes and (failures or missing):
        for key in sorted({k for k, *_ in failures} | set(missing)):
            d = _get_fallback_gate(key)
            cur.execute(
                "INSERT INTO feature_gates "
                "(feature_key, display_name, minimum_tier, free_limit, reset_period, is_enabled) "
                "VALUES (%s, %s, %s, %s, %s, %s) "
                "ON CONFLICT (feature_key) DO UPDATE SET "
                "minimum_tier=EXCLUDED.minimum_tier, free_limit=EXCLUDED.free_limit, "
                "reset_period=EXCLUDED.reset_period, is_enabled=EXCLUDED.is_enabled",
                (
                    key,
                    key.replace("_", " ").title(),
                    d["minimum_tier"],
                    d["free_limit"],
                    d["reset_period"],
                    d["is_enabled"],
                ),
            )
            print(f"  applied {key} -> {d}")
        print(f"\n✅ pushed code-declared policy for {len({k for k, *_ in failures}) + len(missing)} gate(s)")
        failures, missing = [], []

    if orphans:
        print(f"⚠️  {len(orphans)} live row(s) not declared in PREMIUM_FEATURE_KEYS "
              f"(they gate nothing — no call site passes these keys):")
        for key in orphans:
            print(f"      {key:<24} {live[key]}")
        print("    Either wire a check_premium_gate() call for them, or DELETE the "
              "row deliberately. Not auto-removed.\n")

    if missing:
        print(f"❌ {len(missing)} declared gate(s) have NO row (they fall back to "
              f"the code default, which is correct but unverified):")
        for key in missing:
            print(f"      {key:<24} expected {_get_fallback_gate(key)}")

    if failures:
        print(f"❌ {len(failures)} policy divergence(s) — the LIVE table wins at "
              f"runtime, so these are the values actually enforced:")
        for key, col, declared, actual in failures:
            print(f"      {key:<24} {col:<14} code={declared!r:<12} live={actual!r}")

    cur.close()
    conn.close()

    if failures or missing:
        print("\nFix with: .venv/bin/python scripts/audit_feature_gate_drift.py --apply")
        return 1

    print(f"✅ feature_gates matches declared policy for all "
          f"{len(PREMIUM_FEATURE_KEYS)} code-declared gate(s)"
          + (f" ({len(orphans)} orphan row(s) reported above)" if orphans else ""))
    return 0


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--check", action="store_true", help="exit 1 on drift (CI gate)")
    ap.add_argument("--apply", action="store_true", help="push code policy into the table")
    args = ap.parse_args()
    if not (args.check or args.apply):
        ap.error("pass --check or --apply")
    sys.exit(audit(apply_fixes=args.apply))
