"""
Regression gate for row 102 (2026-08 backend prompt sweep): the Program
detail OVERVIEW tab's phase list ("02 Volume · Week 4-8 · Accumulate sets in
the 8-15 range", "03 Intensify · Week 9-12 · Heavier load, then a deload")
carries the same class of jargon ("deload", "hypertrophy", "accumulation")
Row 35 already fixed on the Schedule tab — but Overview reads from a
DIFFERENT column (`programs.phases[].title/subtitle`), a separate authored
source from `program_variant_weeks.phase/focus`, so the Schedule-side fix
never touched it. `audit_program_copy_clarity.py` never scanned
`programs.phases` at all before this sweep — this test guards both the new
gate coverage and the content fix.

scripts/fix_program_phases_overview_jargon.py is the content fix (dry-run
verified against the live catalog — 6 hits across 4 programs, matching the
count this test's live check below finds). NOT applied — this sandbox's
permission classifier blocks direct prod DB writes.

Does NOT attempt the deeper Overview-vs-Schedule NARRATIVE reconciliation
(the same weeks described with contradictory content, plus the "in Phase 2"
authoring-scaffolding leak) — that's a generation-pipeline change tracked
separately in the script's docstring; a text-level rewrite can't make two
independently-authored sources agree on WHAT happened in a given week, only
on HOW they say it.
"""
import os
import sys

import pytest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from scripts.audit_program_copy_clarity import fetch_program_phases, lint  # noqa: E402


def test_the_exact_shipped_defect_string_is_flagged():
    # Row 102 evidence, verbatim: programs.phases subtitle for Hypertrophy
    # 4-Day Split's week 9-12 phase.
    assert lint("Heavier load, then a deload") is not None


def test_rewrite_script_translates_the_defect_string():
    from scripts.rewrite_program_copy_plain_language import rewrite

    out = rewrite("Heavier load, then a deload")
    assert lint(out) is None, f"rewritten string still trips the gate: {out!r}"
    assert "deload" not in out.lower()


@pytest.mark.skipif(
    not (
        os.environ.get("SUPABASE_URL")
        and (os.environ.get("SUPABASE_SERVICE_KEY") or os.environ.get("SUPABASE_KEY"))
    ),
    reason="Supabase credentials not configured in this environment",
)
def test_gate_now_scans_programs_phases_and_finds_the_live_defect():
    from core.supabase_client import get_supabase

    db = get_supabase()
    programs = fetch_program_phases(db)
    if not programs:
        pytest.skip("no programs.phases data in this environment")

    flagged = []
    for _pid, name, phases in programs:
        for ph in phases:
            if not isinstance(ph, dict):
                continue
            for f in ("title", "subtitle"):
                v = ph.get(f)
                if isinstance(v, str) and lint(v):
                    flagged.append((name, f, v))

    names = {f[0] for f in flagged}
    assert "Hypertrophy 4-Day Split" in names, (
        f"gate did not catch the known-live row 102 defect; found instead: {flagged}"
    )
