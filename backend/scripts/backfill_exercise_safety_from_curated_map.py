"""Phase A3 — exercise_safety_index coverage audit + curated-map drift check.

Originally scoped as a "backfill missing `*_safe` tags" script. After running
the audit on 2026-05-09 (`yfbluebqtddhxdqeofsj/...ai-fitness-coach`):

    SELECT COUNT(*) FROM exercise_safety_index WHERE is_tagged IS TRUE
    → 2190 / 2192  (99.9%)

The coverage gap is essentially zero (2 untagged rows). What actually matters
for the cascade tier-2 fallback is that every substring in
`injury_focus_alternatives.INJURY_FOCUS_ALTERNATIVES` resolves to ≥1 row in
`exercise_library_cleaned`. A substring with 0 matches silently drops a
clinically appropriate alternative — invisible to tests, visible only in
sweep fallout.

This script:
  1. Reports the count + IDs of un-tagged safety_index rows so PT review can
     close the long tail (currently just 2 rows).
  2. For every (injury, focus) entry in the curated map, runs a SQL
     EXISTS check per substring against `exercise_library_cleaned` and
     prints any substring with 0 matches — so the map can be repaired
     before the next sweep.
  3. Optionally writes a JSON report (`--out report.json`) for CI ingestion.

This is read-only — no DDL, no UPDATEs. Run via:

    cd backend && .venv/bin/python scripts/backfill_exercise_safety_from_curated_map.py

Add `--json` for machine-readable output, `--out path.json` to persist it.
"""
from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path
from typing import Dict, List, Tuple

# Resolve backend on path so we can import the curated map directly.
_BACKEND = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(_BACKEND))

try:
    from dotenv import load_dotenv  # type: ignore
    load_dotenv(_BACKEND / ".env")
except ImportError:
    pass

from services.exercise_rag.injury_focus_alternatives import (
    INJURY_FOCUS_ALTERNATIVES,
    UNIVERSAL_SAFE_BY_FOCUS,
)


def _connect():
    """Open an SQLAlchemy connection using DATABASE_URL from backend/.env.

    We bypass the supabase-client wrapper because this is a one-shot CLI
    that doesn't need pooling, and we want to surface DB connect errors
    loudly rather than silently degrade.
    """
    from sqlalchemy import create_engine
    url = os.getenv("DATABASE_URL")
    if not url:
        raise RuntimeError(
            "DATABASE_URL not set in backend/.env — cannot run audit. "
            "This script requires a live Postgres connection."
        )
    # SQLAlchemy needs the postgresql+psycopg2:// dialect spelled out.
    if url.startswith("postgresql://"):
        url = url.replace("postgresql://", "postgresql+psycopg2://", 1)
    elif url.startswith("postgres://"):
        url = url.replace("postgres://", "postgresql+psycopg2://", 1)
    return create_engine(url, future=True).connect()


def audit_safety_index_coverage(conn) -> Dict:
    from sqlalchemy import text
    sql = text("""
        SELECT
          COUNT(*)                                            AS total,
          COUNT(*) FILTER (WHERE is_tagged IS TRUE)           AS tagged,
          COUNT(*) FILTER (WHERE is_tagged IS NOT TRUE)       AS untagged,
          COUNT(*) FILTER (WHERE
            shoulder_safe IS NULL AND knee_safe IS NULL AND hip_safe IS NULL
            AND ankle_safe IS NULL AND wrist_safe IS NULL AND elbow_safe IS NULL
            AND lower_back_safe IS NULL AND neck_safe IS NULL
          ) AS all_null
        FROM public.exercise_safety_index
    """)
    row = conn.execute(sql).mappings().first()
    counts = dict(row) if row else {}
    untagged_ids: List[str] = []
    if counts.get("untagged", 0):
        ids_sql = text(
            "SELECT exercise_id, name FROM public.exercise_safety_index "
            "WHERE is_tagged IS NOT TRUE LIMIT 50"
        )
        untagged_ids = [
            f"{r['exercise_id']}: {r['name']}"
            for r in conn.execute(ids_sql).mappings()
        ]
    return {
        "counts": counts,
        "tagged_share": round(counts.get("tagged", 0) / max(counts.get("total", 1), 1), 4),
        "untagged_samples": untagged_ids,
    }


def audit_curated_map_drift(conn) -> Dict:
    """For every substring in the curated map + universals, check if it
    matches ≥1 row in `exercise_library_cleaned`. Returns substrings with
    zero matches — those are dead entries that need repair."""
    from sqlalchemy import text
    all_subs: Dict[str, List[Tuple[str, str]]] = {}  # substring → [(injury, focus)]
    for (inj, foc), subs in INJURY_FOCUS_ALTERNATIVES.items():
        for s in subs:
            all_subs.setdefault(s.lower(), []).append((inj, foc))
    for foc, subs in UNIVERSAL_SAFE_BY_FOCUS.items():
        for s in subs:
            all_subs.setdefault(s.lower(), []).append(("__universal__", foc))

    dead: List[Dict] = []
    live: List[Dict] = []
    sql = text(
        "SELECT COUNT(*) AS n FROM public.exercise_library_cleaned "
        "WHERE LOWER(name) LIKE :pat"
    )
    for s, where_used in sorted(all_subs.items()):
        n = conn.execute(sql, {"pat": f"%{s}%"}).scalar() or 0
        rec = {
            "substring": s,
            "match_count": int(n),
            "used_in": [{"injury": i, "focus": f} for i, f in where_used],
        }
        (dead if n == 0 else live).append(rec)
    return {
        "total_substrings": len(all_subs),
        "live_count": len(live),
        "dead_count": len(dead),
        "dead": dead,
    }


def _print_report(rep: Dict) -> int:
    """Pretty-print to stdout. Returns shell exit code (0 ok, 1 issues)."""
    si = rep["safety_index"]
    print("=" * 60)
    print("Phase A3 audit — exercise_safety_index coverage")
    print("=" * 60)
    counts = si.get("counts", {})
    print(f"  total exercises:    {counts.get('total', '?')}")
    print(f"  tagged:             {counts.get('tagged', '?')} "
          f"({si['tagged_share']*100:.1f}%)")
    print(f"  untagged:           {counts.get('untagged', '?')}")
    print(f"  all-NULL safety:    {counts.get('all_null', '?')}")
    if si.get("untagged_samples"):
        print("  untagged samples:")
        for s in si["untagged_samples"][:10]:
            print(f"    - {s}")

    print()
    print("=" * 60)
    print("Phase A3 audit — curated map drift")
    print("=" * 60)
    cm = rep["curated_map"]
    print(f"  total substrings:   {cm['total_substrings']}")
    print(f"  live (≥1 match):    {cm['live_count']}")
    print(f"  dead (0 matches):   {cm['dead_count']}")
    if cm["dead"]:
        print("  dead substrings:")
        for d in cm["dead"]:
            uses = ", ".join(f"{u['injury']}+{u['focus']}" for u in d["used_in"])
            print(f"    - {d['substring']!r}  (used in: {uses})")

    has_issues = bool(cm["dead"]) or counts.get("untagged", 0) > 5
    return 1 if has_issues else 0


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--json", action="store_true", help="emit JSON only")
    p.add_argument("--out", type=Path, help="write JSON report to path")
    args = p.parse_args()

    with _connect() as conn:
        report = {
            "safety_index": audit_safety_index_coverage(conn),
            "curated_map": audit_curated_map_drift(conn),
        }

    if args.out:
        args.out.write_text(json.dumps(report, indent=2))
        print(f"wrote {args.out}", file=sys.stderr)

    if args.json:
        print(json.dumps(report, indent=2))
        return 0
    return _print_report(report)


if __name__ == "__main__":
    sys.exit(main())
