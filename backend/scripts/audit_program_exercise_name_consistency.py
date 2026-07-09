#!/usr/bin/env python3
"""
Audit + repair exercise-name / canonical-resolution drift in curated program
sessions, and the alias-table disagreements that cause it.

CONTEXT (2026-07-07) — reported bug
------------------------------------------------------------------------
A HYROX session displayed "Ski Ergometer Cross Country Ski Basic Pull" in the
program schedule, but tapping into it showed the detail screen for "Ski Erg
Easy" (different muscle group, different instructions). Root cause: the
schedule list prints a session's stored exercise `name` verbatim, but the
`exercise_id` / media the app actually attaches is computed by resolving that
same name through `exercise_aliases -> exercise_canonical` (the
`resolve_exercise_demo_media` RPC, the same stack `program_exercises_with_media`
/ `GET /library/{id}/schedule` use). When a stored name's alias-canonical
resolution meaningfully diverges from its own text (as here — "Ski Ergometer
Cross Country Ski Basic Pull" normalizes/aliases straight to "Ski Erg Easy"),
the schedule and the detail screen show two different exercises for the same
row. Confirmed for this case: "Ski Erg Easy" IS the correct exercise — the
`exercise_image_aliases` override added in migration 2298 (routing
"skierg"/"ski erg" to "Ski Ergometer Cross Country Ski Basic Pull") was itself
the mistake and disagreed with `exercise_aliases`.

This script has two independent modes:

  --check / --apply (default)
      Walk every exercise across variant-backed programs' `program_variant_weeks
      .workouts` (and blob-only programs' `programs.workouts`), resolve each
      exercise's stored `name` via `resolve_exercise_demo_media` (the RPC — same
      canonical stack the schedule endpoint uses), and flag any exercise whose
      name normalizes differently from its resolved `canonical_name`. --apply
      overwrites the stored name to match the canonical name (the alias/canonical
      mapping is the source of truth here — it is what actually determines the
      exercise_id/media/detail-screen content the user sees; the free-text name
      is what drifts).

  --check-alias-tables
      Flag every alias string present in BOTH `exercise_aliases` and
      `exercise_image_aliases` whose resolved underlying exercise disagrees
      (comparing `exercise_canonical.canonical_name` vs `exercise_library
      .exercise_name`). Report-only — never auto-fixed, since resolving a
      genuine disagreement is a curation judgment call (as this case shows).

KEY PROPERTIES
  • Dry-run by DEFAULT — --apply required to write.
  • --program-id scopes to specific programs.id values (comma-separated /
    repeatable). Default: every published program.
  • Self-contained: supabase-py (REST) + the `resolve_exercise_demo_media` RPC —
    no heavy backend imports.
  • Writes are id-scoped UPDATEs (program_variant_weeks.workouts by row id, or
    programs.workouts by program id) — safe for two workers on disjoint programs.
  • NO materialized-view refresh needed.

USAGE
  python3 scripts/audit_program_exercise_name_consistency.py --check
  python3 scripts/audit_program_exercise_name_consistency.py --check --program-id <id>
  python3 scripts/audit_program_exercise_name_consistency.py --apply --program-id <id>
  python3 scripts/audit_program_exercise_name_consistency.py --check-alias-tables
"""
from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional

BACKEND_DIR = Path(__file__).parent.parent
sys.path.insert(0, str(BACKEND_DIR))

from dotenv import load_dotenv  # noqa: E402
load_dotenv(BACKEND_DIR / ".env")

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

_sb = None


def get_sb():
    global _sb
    if _sb is None:
        from supabase import create_client
        if not (SUPABASE_URL and SUPABASE_KEY):
            raise SystemExit("SUPABASE_URL / SUPABASE_KEY not set in backend/.env")
        _sb = create_client(SUPABASE_URL, SUPABASE_KEY)
    return _sb


def _norm(s: Optional[str]) -> str:
    return re.sub(r"[^a-z0-9]+", " ", (s or "").lower()).strip()


# ── Program / variant resolution (same shape as backfill_thin_program_sessions.py) ──
def resolve_programs(program_ids: List[str]):
    sb = get_sb()
    rows = (sb.table("programs")
            .select("id, program_name, variant_base_id, workouts")
            .eq("is_published", True).execute().data or [])
    if program_ids:
        wanted = set(program_ids)
        rows = [r for r in rows if r["id"] in wanted]
    return rows


def fetch_variant_ids(variant_base_id: str) -> List[str]:
    sb = get_sb()
    rows = (sb.table("program_variants").select("id")
            .eq("base_program_id", variant_base_id).execute().data or [])
    return [r["id"] for r in rows]


def fetch_week_rows(variant_ids: List[str]):
    sb = get_sb()
    out, step = [], 500
    for i in range(0, len(variant_ids), 50):
        chunk = variant_ids[i:i + 50]
        start = 0
        while True:
            r = (sb.table("program_variant_weeks")
                 .select("id, variant_id, week_number, workouts")
                 .in_("variant_id", chunk).range(start, start + step - 1).execute())
            batch = r.data or []
            out.extend(batch)
            if len(batch) < step:
                break
            start += step
    return out


def fetch_all(table: str, columns: str) -> List[Dict[str, Any]]:
    """Paginate a full-table select past PostgREST's default 1000-row page cap."""
    sb = get_sb()
    out, start, step = [], 0, 1000
    while True:
        r = sb.table(table).select(columns).range(start, start + step - 1).execute()
        batch = r.data or []
        out.extend(batch)
        if len(batch) < step:
            break
        start += step
    return out


def canonical_for(name: str, cache: Dict[str, Optional[str]]) -> Optional[str]:
    if name in cache:
        return cache[name]
    sb = get_sb()
    try:
        r = sb.rpc("resolve_exercise_demo_media", {"p_name": name}).execute().data
    except Exception:  # noqa: BLE001
        r = None
    canonical = None
    if r:
        rows = r if isinstance(r, list) else [r]
        if rows:
            canonical = rows[0].get("canonical_name")
    cache[name] = canonical
    return canonical


# ── name-consistency check/apply ────────────────────────────────────────────────
def find_mismatches(programs: List[Dict[str, Any]], cache: Dict[str, Optional[str]]):
    mismatches = []
    for prog in programs:
        variant_base_id = prog.get("variant_base_id")
        if variant_base_id:
            variant_ids = fetch_variant_ids(variant_base_id)
            if not variant_ids:
                continue
            for wr in fetch_week_rows(variant_ids):
                workouts = wr.get("workouts") or []
                for wi, w in enumerate(workouts):
                    if not isinstance(w, dict):
                        continue
                    for ei, e in enumerate(w.get("exercises") or []):
                        name = (e.get("name") or "").strip()
                        if not name:
                            continue
                        canonical = canonical_for(name, cache)
                        if canonical and _norm(canonical) != _norm(name):
                            mismatches.append({
                                "program": prog["program_name"], "program_id": prog["id"],
                                "week_row_id": wr["id"], "variant_id": wr["variant_id"],
                                "week_number": wr.get("week_number"),
                                "workout_idx": wi, "exercise_idx": ei, "name_key": "name",
                                "session": w.get("workout_name") or w.get("name"),
                                "name": name, "canonical_name": canonical,
                            })
        else:
            blob = prog.get("workouts")
            workouts = (blob or {}).get("workouts") if isinstance(blob, dict) else (blob or [])
            if not isinstance(workouts, list):
                continue
            for wi, w in enumerate(workouts):
                if not isinstance(w, dict):
                    continue
                for ei, e in enumerate(w.get("exercises") or []):
                    name = (e.get("exercise_name") or e.get("name") or "").strip()
                    if not name:
                        continue
                    canonical = canonical_for(name, cache)
                    if canonical and _norm(canonical) != _norm(name):
                        mismatches.append({
                            "program": prog["program_name"], "program_id": prog["id"],
                            "week_row_id": None, "variant_id": None,
                            "week_number": None,
                            "workout_idx": wi, "exercise_idx": ei,
                            "name_key": "exercise_name" if e.get("exercise_name") else "name",
                            "session": w.get("workout_name") or w.get("type") or w.get("day"),
                            "name": name, "canonical_name": canonical,
                        })
    return mismatches


def _with_retry(fn, retries: int = 4, label: str = ""):
    """Retry a Supabase call through transient network drops (observed:
    httpx.RemoteProtocolError / ConnectionTerminated on long-running scripts
    making thousands of sequential requests over one persistent HTTP/2
    connection). Recreates the client on failure since the dead connection
    is cached on the module-level singleton."""
    global _sb
    import time
    last_err = None
    for attempt in range(retries):
        try:
            return fn()
        except Exception as e:  # noqa: BLE001
            last_err = e
            _sb = None  # force get_sb() to build a fresh client/connection
            wait = min(2 ** attempt, 10)
            print(f"⚠️  {label} transient error (attempt {attempt + 1}/{retries}): {e} — retrying in {wait}s")
            time.sleep(wait)
    raise last_err


def apply_fixes(mismatches: List[Dict[str, Any]]):
    by_week: Dict[str, List[Dict[str, Any]]] = {}
    by_program_blob: Dict[str, List[Dict[str, Any]]] = {}
    for m in mismatches:
        if m["week_row_id"]:
            by_week.setdefault(m["week_row_id"], []).append(m)
        else:
            by_program_blob.setdefault(m["program_id"], []).append(m)

    total = len(by_week) + len(by_program_blob)
    print(f"⏳ writing {total} row(s) ({len(by_week)} week rows, {len(by_program_blob)} program blobs)…", flush=True)

    updated_rows = 0
    failed_rows: List[str] = []
    for i, (week_row_id, patches) in enumerate(by_week.items(), 1):
        try:
            row = _with_retry(
                lambda: get_sb().table("program_variant_weeks").select("workouts")
                .eq("id", week_row_id).limit(1).execute().data,
                label=f"select week {week_row_id}",
            )
            if not row:
                continue
            workouts = row[0].get("workouts") or []
            for p in patches:
                try:
                    workouts[p["workout_idx"]]["exercises"][p["exercise_idx"]][p["name_key"]] = p["canonical_name"]
                except (IndexError, KeyError, TypeError):
                    print(f"⚠️  skip (shape changed since check): {p['program']} week_row {week_row_id}")
                    continue
            _with_retry(
                lambda: get_sb().table("program_variant_weeks").update({"workouts": workouts})
                .eq("id", week_row_id).execute(),
                label=f"update week {week_row_id}",
            )
            updated_rows += 1
        except Exception as e:  # noqa: BLE001
            print(f"❌ giving up on week_row {week_row_id} after retries: {e}")
            failed_rows.append(week_row_id)
        if i % 200 == 0:
            print(f"   …{i}/{len(by_week)} week rows written", flush=True)

    for program_id, patches in by_program_blob.items():
        try:
            row = _with_retry(
                lambda: get_sb().table("programs").select("workouts")
                .eq("id", program_id).limit(1).execute().data,
                label=f"select program {program_id}",
            )
            if not row:
                continue
            blob = row[0].get("workouts")
            workouts = (blob or {}).get("workouts") if isinstance(blob, dict) else (blob or [])
            for p in patches:
                try:
                    workouts[p["workout_idx"]]["exercises"][p["exercise_idx"]][p["name_key"]] = p["canonical_name"]
                except (IndexError, KeyError, TypeError):
                    print(f"⚠️  skip (shape changed since check): {p['program']} blob")
                    continue
            if isinstance(blob, dict):
                blob["workouts"] = workouts
                new_blob = blob
            else:
                new_blob = workouts
            _with_retry(
                lambda: get_sb().table("programs").update({"workouts": new_blob})
                .eq("id", program_id).execute(),
                label=f"update program {program_id}",
            )
            updated_rows += 1
        except Exception as e:  # noqa: BLE001
            print(f"❌ giving up on program {program_id} after retries: {e}")
            failed_rows.append(program_id)

    if failed_rows:
        print(f"⚠️  {len(failed_rows)} row(s) failed after retries — re-run to pick these up "
              f"(idempotent, only unresolved mismatches remain): {failed_rows[:10]}")
    return updated_rows


# ── alias-table agreement check (report-only) ───────────────────────────────────
def check_alias_tables():
    sb = get_sb()
    image_aliases = fetch_all("exercise_image_aliases", "display_name, library_exercise_id")
    name_aliases = fetch_all("exercise_aliases", "alias_name_normalized, canonical_exercise_id")

    canon_ids = {a["canonical_exercise_id"] for a in name_aliases if a.get("canonical_exercise_id")}
    canon_names: Dict[str, str] = {}
    for i in range(0, len(list(canon_ids)), 200):
        chunk = list(canon_ids)[i:i + 200]
        rows = sb.table("exercise_canonical").select("id, canonical_name").in_("id", chunk).execute().data or []
        for r in rows:
            canon_names[r["id"]] = r["canonical_name"]

    lib_ids = {a["library_exercise_id"] for a in image_aliases if a.get("library_exercise_id")}
    lib_names: Dict[str, str] = {}
    for i in range(0, len(list(lib_ids)), 200):
        chunk = list(lib_ids)[i:i + 200]
        rows = sb.table("exercise_library").select("id, exercise_name").in_("id", chunk).execute().data or []
        for r in rows:
            lib_names[r["id"]] = r["exercise_name"]

    by_norm_name_alias: Dict[str, str] = {}
    for a in name_aliases:
        n = _norm(a["alias_name_normalized"])
        cn = canon_names.get(a.get("canonical_exercise_id"))
        if n and cn:
            by_norm_name_alias.setdefault(n, cn)

    disagreements = []
    for ia in image_aliases:
        n = _norm(ia["display_name"])
        image_target = lib_names.get(ia.get("library_exercise_id"))
        alias_target = by_norm_name_alias.get(n)
        if image_target and alias_target and _norm(image_target) != _norm(alias_target):
            disagreements.append({
                "alias": ia["display_name"],
                "exercise_image_aliases_says": image_target,
                "exercise_aliases_says": alias_target,
            })
    return disagreements


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter,
                                  allow_abbrev=False)
    ap.add_argument("--check", action="store_true", help="Dry-run report (default behavior; explicit flag optional)")
    ap.add_argument("--apply", action="store_true", help="Write fixes (default: dry-run report only)")
    ap.add_argument("--program-id", action="append", help="Comma-separated / repeatable programs.id values")
    ap.add_argument("--check-alias-tables", action="store_true",
                     help="Check exercise_aliases vs exercise_image_aliases agreement instead (report-only)")
    ap.add_argument("--only-name", action="append",
                     help="Restrict --apply to exercises whose stored name exactly matches one of these "
                          "(case-insensitive, comma-separated/repeatable). Confirmed-safe fixes only — the "
                          "resolver is a fuzzy media-matcher, not a ground truth, so bulk --apply across "
                          "every mismatch WILL introduce wrong renames; always review the dry-run report "
                          "and scope --apply to reviewed names.")
    ap.add_argument("--verbose", action="store_true")
    args = ap.parse_args()

    if args.check_alias_tables:
        disagreements = check_alias_tables()
        if not disagreements:
            print("✅ exercise_aliases and exercise_image_aliases agree on every shared alias")
            return
        print(f"⚠️  {len(disagreements)} alias disagreement(s):")
        for d in disagreements:
            print(f"  '{d['alias']}': exercise_image_aliases → {d['exercise_image_aliases_says']!r}"
                  f"  vs  exercise_aliases → {d['exercise_aliases_says']!r}")
        return

    program_ids = []
    for chunk in (args.program_id or []):
        program_ids.extend(p.strip() for p in chunk.split(",") if p.strip())

    programs = resolve_programs(program_ids)
    if not programs:
        raise SystemExit("No matching published programs found.")
    print(f"⏳ Scanning {len(programs)} program(s)…")

    cache: Dict[str, Optional[str]] = {}
    mismatches = find_mismatches(programs, cache)

    if not mismatches:
        print("✅ no name/canonical-resolution mismatches found")
        return

    print(f"⚠️  {len(mismatches)} mismatch(es) found:")
    for m in mismatches:
        loc = f"variant {m['variant_id']} week {m['week_number']}" if m["week_row_id"] else "base blob"
        print(f"  [{m['program']}] {loc} / {m['session']!r}: "
              f"{m['name']!r} → resolves to {m['canonical_name']!r}")

    if args.apply:
        only_names = set()
        for chunk in (args.only_name or []):
            only_names.update(n.strip().lower() for n in chunk.split(",") if n.strip())
        to_apply = mismatches
        if only_names:
            to_apply = [m for m in mismatches if m["name"].strip().lower() in only_names]
            skipped = len(mismatches) - len(to_apply)
            print(f"\n--only-name scoped: applying {len(to_apply)} of {len(mismatches)} "
                  f"({skipped} left untouched for manual review)")
        elif len(mismatches) > 20:
            raise SystemExit(
                f"\n❌ refusing to --apply {len(mismatches)} unreviewed mismatches — the resolver is a "
                f"fuzzy media-matcher (e.g. 'Kettlebell Swings' → 'Dumbbell Swing' is WRONG, not a fix). "
                f"Review the report above and re-run with --only-name '<confirmed name>,...' "
                f"to apply only the names you've verified."
            )
        if to_apply:
            updated = apply_fixes(to_apply)
            print(f"✅ applied: rewrote {updated} row(s) to their canonical name")
        else:
            print("(nothing matched --only-name — no changes made)")
    else:
        print("\n(dry-run — pass --apply --only-name '<confirmed name>' to write reviewed fixes)")


if __name__ == "__main__":
    main()
