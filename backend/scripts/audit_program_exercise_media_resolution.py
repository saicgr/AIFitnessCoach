#!/usr/bin/env python3
"""
Regression gate: does every exercise SLOT in the SHIPPED program schedule
resolve to an image, AT THE LAYER THE APP ACTUALLY SERVES FROM?

Why this exists — E2E register #122 / #126 / #127
---------------------------------------------------
`audit_exercise_media_urls.py` HEAD-checks S3 paths that ARE referenced — it
structurally cannot ask "does this authored exercise name find a row at all?"
`audit_exercise_name_reachability.py` audits the catalogue (exercise_canonical)
and recent workout logs — not the published program *schedule* (what a user
actually sees when they open a program before ever starting a workout).

This script replicates the app's REAL resolver — `GET /programs/templates/
{id}/schedule` (backend/api/v1/program_templates.py:1802-1990) — exactly,
tier for tier, over every exercise occurrence in every published program's
`program_variant_weeks.workouts[].exercises[]`:

  1. POSITION match — `program_exercises_with_media` row at
     (week_number, workout_idx+1, exercise_idx+1) for this variant.
  2. NAME+WEEK fallback — a media row in the same variant/week whose
     `canonical_name` (lowercased) equals this exercise's own name.
  3. NAME-ONLY fallback — same, ignoring week.
  4. BY-ID fallback — the JSON exercise's own `exercise_id`, looked up
     directly against `exercise_library` / `exercise_library_cleaned`.

Per #126, "this exercise's own name" is `exercise_name or name` — the JSON
element's `exercise_name` key FIRST, `name` second — exactly
`ex.get("exercise_name") or ex.get("name")` in program_templates.py. Checking
only `name` (what a naive read of the flat view suggests) undercounts what
the app can actually resolve.

A slot is a FINDING when none of the four tiers produces a non-null
`image_s3_path` / `image_url`.

Usage:
    cd backend && set -a && source ./.env && set +a && \\
        .venv/bin/python scripts/audit_program_exercise_media_resolution.py --check
    ... --refresh-baseline
    ... (no flags) full report, no exit-code gating

`--check` exits 1 only on NEW findings (baseline-diff, house convention — see
audit_exercise_naming.py). Findings are keyed by stable strings (week-row id +
position + normalized name) — no line numbers, so the baseline survives
unrelated content edits.

Read-only. Never writes to program_variant_weeks, exercise_aliases, or any
S3 path.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import psycopg2
import psycopg2.extras

BASELINE_PATH = Path(__file__).with_name("audit_program_exercise_media_resolution_baseline.json")


def connect():
    dsn = os.environ["DATABASE_URL"].replace("postgresql+asyncpg://", "postgresql://")
    return psycopg2.connect(dsn)


def _norm(s: Optional[str]) -> str:
    return re.sub(r"[^a-z0-9]+", " ", (s or "").lower()).strip()


def _exercise_name(ex: Dict[str, Any]) -> str:
    """Same precedence as program_templates.py:1949-1953."""
    return ((ex.get("exercise_name") or ex.get("name") or "")).strip()


def collect(cur, program_ids: Optional[List[str]] = None) -> Tuple[List[dict], dict]:
    """Returns (findings, stats)."""
    # ── 1. Published variants ────────────────────────────────────────────
    q = """
        SELECT pv.id AS variant_id, p.id AS program_id, p.program_name
        FROM programs p
        JOIN program_variants pv ON pv.base_program_id = p.variant_base_id
        WHERE p.is_published = true
    """
    params: list = []
    if program_ids:
        q += " AND p.id = ANY(%s::uuid[])"
        params.append(program_ids)
    cur.execute(q, params)
    variant_rows = cur.fetchall()
    if not variant_rows:
        return [], {"programs": 0, "variants": 0, "occurrences": 0}

    variant_ids = [r[0] for r in variant_rows]
    variant_meta = {r[0]: {"program_id": r[1], "program_name": r[2]} for r in variant_rows}
    program_ids_seen = {r[1] for r in variant_rows}

    # ── 2. Media rows (position + name fallback source), scoped to these variants ──
    pos_map: Dict[Tuple[str, int, int, int], str] = {}
    name_week_map: Dict[Tuple[str, int, str], str] = {}
    name_map: Dict[Tuple[str, str], str] = {}

    CHUNK = 200
    for i in range(0, len(variant_ids), CHUNK):
        chunk = variant_ids[i:i + CHUNK]
        cur.execute(
            """
            SELECT variant_id, week_number, workout_idx, exercise_idx,
                   canonical_name, image_s3_path
            FROM program_exercises_with_media
            WHERE variant_id = ANY(%s::uuid[])
            """,
            (chunk,),
        )
        for variant_id, week_number, workout_idx, exercise_idx, canonical_name, image_s3_path in cur.fetchall():
            if not image_s3_path:
                continue
            pos_key = (variant_id, week_number, workout_idx, exercise_idx)
            if pos_key not in pos_map:
                pos_map[pos_key] = image_s3_path
            if canonical_name:
                cn = canonical_name.strip().lower()
                nw_key = (variant_id, week_number, cn)
                if nw_key not in name_week_map:
                    name_week_map[nw_key] = image_s3_path
                n_key = (variant_id, cn)
                if n_key not in name_map:
                    name_map[n_key] = image_s3_path

    # ── 3. Week rows (the actual authored content) ───────────────────────
    week_rows: List[Tuple[Any, Any, int, Any]] = []
    for i in range(0, len(variant_ids), CHUNK):
        chunk = variant_ids[i:i + CHUNK]
        start = 0
        while True:
            cur.execute(
                """
                SELECT id, variant_id, week_number, workouts
                FROM program_variant_weeks
                WHERE variant_id = ANY(%s::uuid[])
                ORDER BY id
                LIMIT 1000 OFFSET %s
                """,
                (chunk, start),
            )
            batch = cur.fetchall()
            week_rows.extend(batch)
            if len(batch) < 1000:
                break
            start += 1000

    # ── 4. By-id fallback source: every exercise_id referenced in the blobs ──
    all_ex_ids: set = set()
    for _id, _vid, _wk, workouts in week_rows:
        for w in (workouts or []):
            if not isinstance(w, dict):
                continue
            for ex in (w.get("exercises") or []):
                if isinstance(ex, dict) and ex.get("exercise_id"):
                    all_ex_ids.add(str(ex["exercise_id"]))

    by_id_image: Dict[str, str] = {}
    if all_ex_ids:
        ids_list = list(all_ex_ids)
        for i in range(0, len(ids_list), 1000):
            chunk = ids_list[i:i + 1000]
            cur.execute(
                "SELECT id::text, image_s3_path FROM exercise_library WHERE id::text = ANY(%s)",
                (chunk,),
            )
            for _id, path in cur.fetchall():
                if path:
                    by_id_image[_id] = path
        missing = [i for i in ids_list if i not in by_id_image]
        for i in range(0, len(missing), 1000):
            chunk = missing[i:i + 1000]
            cur.execute(
                "SELECT id::text, image_url FROM exercise_library_cleaned WHERE id::text = ANY(%s)",
                (chunk,),
            )
            for _id, path in cur.fetchall():
                if path:
                    by_id_image[_id] = path

    # ── 5. Walk every occurrence, apply the 4-tier resolver ──────────────
    findings: List[dict] = []
    total_occurrences = 0
    tier_hits = {"position": 0, "name_week": 0, "name_only": 0, "by_id": 0, "none": 0}

    for week_row_id, variant_id, week_number, workouts in week_rows:
        meta = variant_meta.get(variant_id, {})
        for wi, w in enumerate(workouts or []):
            if not isinstance(w, dict):
                continue
            for ei, ex in enumerate(w.get("exercises") or []):
                if not isinstance(ex, dict):
                    continue
                total_occurrences += 1
                ex_name = _exercise_name(ex)
                ex_name_lower = ex_name.lower()

                resolved_tier = None
                if pos_map.get((variant_id, week_number, wi + 1, ei + 1)):
                    resolved_tier = "position"
                elif ex_name_lower and name_week_map.get((variant_id, week_number, ex_name_lower)):
                    resolved_tier = "name_week"
                elif ex_name_lower and name_map.get((variant_id, ex_name_lower)):
                    resolved_tier = "name_only"
                else:
                    ex_id = str(ex.get("exercise_id") or "")
                    if ex_id and ex_id in by_id_image:
                        resolved_tier = "by_id"

                if resolved_tier:
                    tier_hits[resolved_tier] += 1
                else:
                    tier_hits["none"] += 1
                    findings.append({
                        "program_id": meta.get("program_id"),
                        "program_name": meta.get("program_name"),
                        "variant_id": variant_id,
                        "week_row_id": week_row_id,
                        "week_number": week_number,
                        "workout_idx": wi,
                        "exercise_idx": ei,
                        "name": ex_name,
                        "name_normalized": _norm(ex_name),
                    })

    stats = {
        "programs": len(program_ids_seen),
        "variants": len(variant_ids),
        "occurrences": total_occurrences,
        "missing": len(findings),
        "distinct_names_missing": len({f["name_normalized"] for f in findings}),
        "programs_with_missing": len({f["program_id"] for f in findings}),
        "tier_hits": tier_hits,
    }
    return findings, stats


def key(f: dict) -> str:
    # Stable across content re-ingests of the SAME week row; not tied to line
    # numbers. week_row_id is a real DB id (program_variant_weeks.id).
    return f"{f['week_row_id']}|{f['workout_idx']}|{f['exercise_idx']}|{f['name_normalized']}"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--check", action="store_true", help="exit 1 on NEW findings")
    ap.add_argument("--refresh-baseline", action="store_true")
    ap.add_argument("--all", action="store_true", help="print baselined findings too")
    ap.add_argument("--program-id", action="append", help="comma-separated/repeatable programs.id values")
    ap.add_argument("--top", type=int, default=15, help="how many top-offender names to print")
    args = ap.parse_args()

    program_ids = None
    if args.program_id:
        program_ids = []
        for chunk in args.program_id:
            program_ids.extend(p.strip() for p in chunk.split(",") if p.strip())

    with connect() as conn:
        with conn.cursor() as cur:
            findings, stats = collect(cur, program_ids)

    baseline = set()
    if BASELINE_PATH.exists():
        baseline = set(json.loads(BASELINE_PATH.read_text()).get("accepted", []))

    if args.refresh_baseline:
        BASELINE_PATH.write_text(
            json.dumps({
                "_comment": "Accepted findings for audit_program_exercise_media_resolution.py. "
                            "Refresh only after genuinely clearing or reviewing the current set.",
                "stats_at_refresh": stats,
                "accepted": sorted(key(f) for f in findings),
            }, indent=2) + "\n"
        )
        print(f"baseline refreshed: {len(findings)} accepted findings")
        return 0

    new = [f for f in findings if key(f) not in baseline]
    shown = findings if args.all else new

    print(f"programs: {stats['programs']}  variants: {stats['variants']}  "
          f"occurrences: {stats['occurrences']}")
    print(f"tier hits: {stats['tier_hits']}")
    print(f"missing: {stats['missing']} occurrences  /  "
          f"{stats['distinct_names_missing']} distinct names  /  "
          f"{stats['programs_with_missing']} programs with at least one miss")
    print(f"baselined: {len(findings) - len(new)}   NEW: {len(new)}")

    # top offenders by raw name (not normalized, for readability)
    if shown:
        from collections import Counter
        counts = Counter(f["name"] for f in shown)
        print(f"\ntop {args.top} offenders:")
        for name, n in counts.most_common(args.top):
            print(f"  {n:6d}  {name}")

    if args.all or args.check:
        pass  # per-row dump omitted by default (177K-scale); use --all with care

    if args.check and new:
        print(
            "\nFAIL: new program-exercise media resolution findings. "
            "Alias the authored name onto its real canonical exercise "
            "(see migrations/2394_inuse_exercise_name_aliases.sql for the pattern) "
            "or verify demo media actually exists for it. Never rename "
            "exercise_demos.original_exercise_name."
        )
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
