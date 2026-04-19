"""
Phase 2G — Exercise Safety Coverage Audit
=========================================

Reports coverage of `public.exercise_safety_index` and identifies rows that
need manual audit (Phase 4N).

Metrics
-------
1. Total exercises in library vs tagged.
2. Breakdown by safety_difficulty.
3. Breakdown by movement_pattern.
4. Rows with UNCLASSIFIED citation (need manual audit).
5. Per-injury count of safe vs unsafe exercises.
6. Random sample of 20 tagged rows for spot-check.

Usage
-----
    # Via Supabase MCP (preferred for CI/dry-run):
    python -m backend.scripts.audit_exercise_safety_coverage --emit-sql

    # Via supabase-py (standalone):
    python -m backend.scripts.audit_exercise_safety_coverage
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any, Dict, List

BACKEND_ROOT = Path(__file__).resolve().parents[1]


AUDIT_QUERIES: Dict[str, str] = {
    "totals": """
        SELECT
          (SELECT COUNT(*) FROM public.exercise_library_cleaned) AS library_total,
          (SELECT COUNT(*) FROM public.exercise_safety_tags)    AS tagged_total,
          (SELECT COUNT(*) FROM public.exercise_safety_index
             WHERE safety_difficulty IS NOT NULL
               AND safety_difficulty <> 'unknown')              AS classified_total,
          (SELECT COUNT(*) FROM public.exercise_safety_tags
             WHERE source_citation LIKE 'UNCLASSIFIED%')        AS unclassified_total;
    """,
    "by_difficulty": """
        SELECT safety_difficulty, COUNT(*) AS n
        FROM public.exercise_safety_index
        GROUP BY safety_difficulty
        ORDER BY n DESC;
    """,
    "by_movement_pattern": """
        SELECT COALESCE(movement_pattern, '__null__') AS movement_pattern,
               COUNT(*) AS n
        FROM public.exercise_safety_index
        GROUP BY movement_pattern
        ORDER BY n DESC;
    """,
    "per_injury_safe": """
        SELECT
          SUM(CASE WHEN shoulder_safe   IS TRUE THEN 1 ELSE 0 END) AS shoulder_safe_count,
          SUM(CASE WHEN lower_back_safe IS TRUE THEN 1 ELSE 0 END) AS lower_back_safe_count,
          SUM(CASE WHEN knee_safe       IS TRUE THEN 1 ELSE 0 END) AS knee_safe_count,
          SUM(CASE WHEN elbow_safe      IS TRUE THEN 1 ELSE 0 END) AS elbow_safe_count,
          SUM(CASE WHEN wrist_safe      IS TRUE THEN 1 ELSE 0 END) AS wrist_safe_count,
          SUM(CASE WHEN ankle_safe      IS TRUE THEN 1 ELSE 0 END) AS ankle_safe_count,
          SUM(CASE WHEN hip_safe        IS TRUE THEN 1 ELSE 0 END) AS hip_safe_count,
          SUM(CASE WHEN neck_safe       IS TRUE THEN 1 ELSE 0 END) AS neck_safe_count,
          SUM(CASE WHEN is_beginner_safe IS TRUE THEN 1 ELSE 0 END) AS beginner_safe_count
        FROM public.exercise_safety_index;
    """,
    "unclassified_sample_20": """
        SELECT e.id, e.name, e.equipment, e.target_muscle, e.difficulty_level
        FROM public.exercise_safety_tags t
        JOIN public.exercise_library_cleaned e ON e.id = t.exercise_id
        WHERE t.source_citation LIKE 'UNCLASSIFIED%'
        ORDER BY random()
        LIMIT 20;
    """,
    "spot_check_20": """
        SELECT e.name, t.movement_pattern, t.safety_difficulty,
               t.shoulder_safe, t.lower_back_safe, t.knee_safe,
               t.elbow_safe, t.wrist_safe, t.ankle_safe, t.hip_safe, t.neck_safe,
               LEFT(t.source_citation, 160) AS source_citation
        FROM public.exercise_safety_tags t
        JOIN public.exercise_library_cleaned e ON e.id = t.exercise_id
        ORDER BY random()
        LIMIT 20;
    """,
    "missing_tags": """
        SELECT e.id, e.name
        FROM public.exercise_library_cleaned e
        LEFT JOIN public.exercise_safety_tags t ON t.exercise_id = e.id
        WHERE t.exercise_id IS NULL
        LIMIT 50;
    """,
    "verification_failing_cases": """
        SELECT e.name, t.movement_pattern, t.safety_difficulty,
               t.shoulder_safe, t.lower_back_safe, t.knee_safe,
               t.elbow_safe, t.wrist_safe, t.ankle_safe, t.hip_safe, t.neck_safe
        FROM public.exercise_safety_tags t
        JOIN public.exercise_library_cleaned e ON e.id = t.exercise_id
        WHERE e.name ILIKE 'Cable Bar Lateral Pulldown'
           OR e.name ILIKE 'Landmine Rotational Lift%'
           OR e.name ILIKE 'Front Lever Raise%';
    """,
}


def _try_import_supabase_client():
    try:
        sys.path.insert(0, str(BACKEND_ROOT))
        from core.supabase_client import get_supabase  # type: ignore
        return get_supabase
    except Exception as e:
        print(f"[WARN] supabase client unavailable: {e}", file=sys.stderr)
        return None


def run_via_supabase() -> Dict[str, Any]:
    get_sb = _try_import_supabase_client()
    if get_sb is None:
        raise SystemExit("Cannot run audit without supabase-py — use --emit-sql and execute via MCP.")
    sb = get_sb().client
    out: Dict[str, Any] = {}
    for name, sql in AUDIT_QUERIES.items():
        # Supabase-py does not expose raw SQL directly; use RPC fallback if a
        # function is registered, else print the SQL so the operator runs it.
        # For robustness in this project we use the postgrest REST layer
        # through table selects where possible; but audit queries need SQL.
        # Fall back to printing.
        raise SystemExit(
            "Direct SQL audit via supabase-py is not wired up in this script. "
            "Use --emit-sql and execute via Supabase MCP."
        )
    return out


def emit_sql(out_path: str = "-") -> None:
    if out_path == "-":
        for name, sql in AUDIT_QUERIES.items():
            print(f"-- === {name} ===\n{sql.strip()}\n")
    else:
        with open(out_path, "w", encoding="utf-8") as f:
            for name, sql in AUDIT_QUERIES.items():
                f.write(f"-- === {name} ===\n{sql.strip()}\n\n")


def main(argv: List[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--emit-sql", action="store_true",
                    help="Print audit SQL to stdout or --out for MCP execution.")
    ap.add_argument("--out", default="-", help="Output path for --emit-sql (default stdout)")
    ap.add_argument("--format", choices=["json", "text"], default="text",
                    help="Format for direct-run output (unused unless a DB adapter is wired)")
    args = ap.parse_args(argv)

    if args.emit_sql:
        emit_sql(args.out)
        return 0

    # Direct-run path — emit SQL even without --emit-sql so operators always get
    # something useful. A supabase-py path is left as a TODO per plan (MCP is
    # the canonical executor).
    print("This audit is executed via Supabase MCP. Dumping SQL:", file=sys.stderr)
    emit_sql("-")
    return 0


if __name__ == "__main__":
    sys.exit(main())
