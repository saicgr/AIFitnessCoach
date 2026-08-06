#!/usr/bin/env python3
"""Rewrite jargon in `programs.phases[].title/subtitle` (row 102, 2026-08).

The Program-detail OVERVIEW tab renders `programs.phases` (a small per-
program list of {title, subtitle, week_start, week_end}) — a SEPARATE
authored source from the Schedule tab's `program_variant_weeks.phase/focus`,
which is why the two tabs can disagree in wording even after
scripts/rewrite_program_copy_plain_language.py cleans up the Schedule side.
This gate/script covers the Overview side specifically; `audit_program_copy_
clarity.py` never scanned `programs.phases` at all before this sweep (same
class of coverage gap as the base-blob `programs.workouts` scan added for
row 111).

Deterministic, no LLM, translate-not-delete (same word list as
rewrite_program_copy_plain_language.py, applied to a small catalog-wide set
— 6 hits across 4 programs, checked directly against the DB).

    .venv/bin/python scripts/fix_program_phases_overview_jargon.py            # dry run
    .venv/bin/python scripts/fix_program_phases_overview_jargon.py --apply

NOTE: does not attempt to reconcile the deeper NARRATIVE disagreement row 102
also flagged (Overview's "02 Volume · Week 4-8" block summarizing a week that
Schedule's per-week data calls a deload/technique week) — Overview and
Schedule are two independently-authored sources for the same weeks with no
shared derivation, so a text-level rewrite can't make them agree; that needs
a generation-pipeline change (derive one from the other) tracked separately.
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.supabase_client import get_supabase  # noqa: E402
from scripts.rewrite_program_copy_plain_language import rewrite  # noqa: E402


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()

    db = get_supabase()
    rows = db.client.table("programs").select("id, editorial_name, phases").execute().data or []

    updates = []
    for p in rows:
        phases = p.get("phases")
        if not isinstance(phases, list):
            continue
        changed = False
        for ph in phases:
            for f in ("title", "subtitle"):
                v = ph.get(f)
                if isinstance(v, str) and v.strip():
                    nv = rewrite(v, title=(f == "title"))
                    if nv != v:
                        print(f"  [{p['editorial_name']}.{f}] {v!r} -> {nv!r}")
                        ph[f] = nv
                        changed = True
        if changed:
            updates.append((p["id"], phases))

    print(f"{len(updates)} programs to rewrite")
    if not args.apply:
        print("dry run — pass --apply to write")
        return 0
    if not updates:
        print("nothing to write")
        return 0

    for pid, phases in updates:
        db.client.table("programs").update({"phases": phases}).eq("id", pid).execute()
    print(f"wrote {len(updates)} programs")
    return 0


if __name__ == "__main__":
    sys.exit(main())
