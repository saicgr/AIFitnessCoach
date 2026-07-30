#!/usr/bin/env python3
"""
PL/pgSQL trigger-function phantom-reference audit (regression gate).

WHY THIS EXISTS
---------------
CLAUDE.md documents the phantom-column class for PostgREST `.select("...")`
strings. The SAME class exists inside Postgres, in PL/pgSQL, and is strictly
worse: PL/pgSQL resolves `NEW.<field>` / `OLD.<field>` and table names at
RUNTIME, so `CREATE OR REPLACE FUNCTION` happily accepts a body that can only
ever raise. Nothing type-checks it, and the failure surfaces as a 500 on an
unrelated user action.

2026-07-29 (E2E register rows 98 + 105): every INSERT into `saved_workouts`
raised `42703 record "new" has no field "workout_id"`, so the coach workout
card's Save button 500'd on every tap and the table stayed at 0 rows forever.
Root cause: migrations 026_fix_function_search_path.sql and
074_fix_function_search_paths.sql were "add SET search_path" sweeps that
REWROTE eight function bodies against an imagined schema instead of preserving
them. All eight were guaranteed runtime errors:

    update_workout_share_count            NEW.workout_id            (saved_workouts)
    update_feature_vote_count             NEW/OLD.feature_request_id(feature_votes)
    update_saved_workout_completion       NEW.is_completed          (scheduled_workouts)
    update_daily_stats_on_screen_view     NEW.viewed_at             (screen_views)
    create_challenge_notification         NEW.challenged_user_id    (workout_challenges)
    notify_challenge_accepted             NEW.challenger_id         (workout_challenges)
    notify_challenge_abandoned            NEW.abandoned_by, ...     (workout_challenges)
    update_challenge_participant_count    table `fitness_challenges` does not exist

Repaired by migrations/2361_fix_phantom_new_field_trigger_functions.sql.

WHAT IT CHECKS
--------------
For every non-internal trigger in schema `public`:
  1. every `NEW.<field>` / `OLD.<field>` in the trigger function's body exists
     as a column on the table the trigger is attached to;
  2. every table named in an `INSERT INTO <t>` / `UPDATE <t>` / `DELETE FROM <t>`
     statement inside the body exists in `public` (tables + views).

Conservative by design (under-reports rather than false-positives):
  - `NEW.<field>.<...>` composite/JSON drilling uses only the first segment;
  - quoted identifiers, CTE names and PL/pgSQL local record variables are
    skipped for the table check (see _LOCAL_TABLE_ALLOW);
  - functions attached to more than one table are checked against EACH table
    they are attached to, and a field only fails when it is missing from that
    specific table.

USAGE
    cd backend && set -a && source ./.env && set +a && \
      .venv/bin/python scripts/audit_trigger_function_columns.py            # report
    ... scripts/audit_trigger_function_columns.py --check                   # gate (exit 1)

Requires DATABASE_URL (the asyncpg-scheme URL in backend/.env is normalized).
"""
from __future__ import annotations

import argparse
import os
import re
import sys
from collections import defaultdict

try:
    import psycopg2
except ImportError:  # pragma: no cover
    print("psycopg2 is required: pip install psycopg2-binary", file=sys.stderr)
    raise

# `NEW.foo` / `OLD.foo` — first identifier segment only.
_RECORD_FIELD_RE = re.compile(r"\b(NEW|OLD)\.([A-Za-z_][A-Za-z0-9_]*)", re.IGNORECASE)

# DML target tables. `INSERT INTO x`, `UPDATE x SET`, `DELETE FROM x`.
_DML_TABLE_RE = re.compile(
    r"\b(?:INSERT\s+INTO|UPDATE|DELETE\s+FROM)\s+(?:ONLY\s+)?(?:public\.)?"
    r"([A-Za-z_][A-Za-z0-9_]*)",
    re.IGNORECASE,
)

# Words that follow UPDATE/DELETE-FROM in prose or PL/pgSQL keywords, not tables.
_LOCAL_TABLE_ALLOW = {
    "set", "the", "a", "an", "if", "from", "only", "count", "logic", "command",
    "longest", "senior", "fitness_challenges_placeholder",
}


def _dsn() -> str:
    raw = os.environ.get("DATABASE_URL")
    if not raw:
        print("DATABASE_URL not set (source backend/.env first)", file=sys.stderr)
        sys.exit(2)
    return raw.replace("postgresql+asyncpg://", "postgresql://")


def audit():
    conn = psycopg2.connect(_dsn())
    cur = conn.cursor()

    cur.execute(
        """
        SELECT t.tgname, c.relname AS tbl, p.proname, pg_get_functiondef(p.oid)
        FROM pg_trigger t
        JOIN pg_class c      ON c.oid = t.tgrelid
        JOIN pg_namespace n  ON n.oid = c.relnamespace
        JOIN pg_proc p       ON p.oid = t.tgfoid
        WHERE NOT t.tgisinternal AND n.nspname = 'public'
        """
    )
    triggers = cur.fetchall()

    cur.execute(
        "SELECT table_name, column_name FROM information_schema.columns "
        "WHERE table_schema = 'public'"
    )
    columns = defaultdict(set)
    for tbl, col in cur.fetchall():
        columns[tbl].add(col.lower())

    cur.execute(
        "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'"
    )
    tables = {r[0].lower() for r in cur.fetchall()}
    conn.close()

    findings = []
    for tgname, tbl, proname, src in triggers:
        # Strip -- line comments so prose never contributes a match.
        body = re.sub(r"--[^\n]*", "", src)

        refs = {m.group(2).lower() for m in _RECORD_FIELD_RE.finditer(body)}
        missing_fields = sorted(r for r in refs if r not in columns.get(tbl, set()))
        for f in missing_fields:
            findings.append(
                f"{proname}() on {tbl} (trigger {tgname}): "
                f"references NEW/OLD.{f} — no such column on {tbl}"
            )

        for m in _DML_TABLE_RE.finditer(body):
            target = m.group(1).lower()
            if target in _LOCAL_TABLE_ALLOW or target in tables:
                continue
            findings.append(
                f"{proname}() on {tbl} (trigger {tgname}): "
                f"writes to table '{target}' — no such table in public"
            )

    return len(triggers), findings


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--check", action="store_true", help="exit 1 on any finding")
    args = ap.parse_args()

    n, findings = audit()
    print(f"Scanned {n} public triggers.")
    if not findings:
        print("✅ No phantom NEW/OLD field or phantom target-table references.")
        return 0

    print(f"❌ {len(findings)} phantom reference(s):")
    for f in sorted(set(findings)):
        print(f"  - {f}")
    return 1 if args.check else 0


if __name__ == "__main__":
    sys.exit(main())
