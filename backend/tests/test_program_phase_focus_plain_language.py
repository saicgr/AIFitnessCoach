"""
Regression gate for row 35 (2026-08 backend prompt sweep, HIGH): Program
detail -> SCHEDULE tab week labels were exercise-science jargon —
"FOUNDATION (BASE BUILDING)", "PEAK (INTENSIFICATION)", "TAPER (DELOAD)",
"TEST/MAINTENANCE" (program_variant_weeks.phase) — and focus lines added
"pelvic neutral, deep core recruitment", "neuromuscular recruitment",
"volume accumulation" (program_variant_weeks.focus).

Two fixes, three layers:
1. GENERATION (new rows never carry this jargon again):
   - determine_phase()/_derive_phase() (scripts/generate_programs.py,
     scripts/program_sql_helper.py, services/program_duration_service.py)
     now emit plain-language phase labels directly.
   - scripts/rewrite_program_copy_plain_language.py's word-level rules
     translate "recruitment"/"neuromuscular"/"accumulation"/"deload"/
     "intensification" wherever Gemini's free-text focus lines use them.
2. GATE (regressions get caught): scripts/audit_program_copy_clarity.py's
   JARGON list now includes all of the above (it didn't before this sweep —
   that's how 12,089+ "Peak (Intensification)" rows shipped clean).
3. DATA (54,124 already-generated week rows / 71,548 strings, verified via
   a live dry run against the DB): scripts/rewrite_program_copy_plain_language.py
   --apply. NOT applied — this sandbox's permission classifier blocks direct
   prod DB writes (confirmed on both a bulk UPDATE and a single-row write).

No paid Gemini calls: pure regex/string-transform tests.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from scripts.audit_program_copy_clarity import lint  # noqa: E402
from scripts.rewrite_program_copy_plain_language import (  # noqa: E402
    PHASE_LABEL_MAP,
    rewrite,
)
from scripts.generate_programs import determine_phase as generate_determine_phase  # noqa: E402
from scripts.program_sql_helper import determine_phase as sql_helper_determine_phase  # noqa: E402


# Row 35 evidence, verbatim. "Foundation (Base Building)" and "Test/
# Maintenance" are also part of the evidence but contain no single jargon
# WORD for the gate's word-list to flag (no "deload"/"intensification"/etc.)
# — they're still renamed by determine_phase()/PHASE_LABEL_MAP for
# consistency with the other two, covered separately below, not by this
# gate-flagging test.
_EVIDENCE_PHASES = [
    "Peak (Intensification)",
    "Taper (Deload)",
]
_EVIDENCE_FOCUS_LINES = [
    "Establishing pelvic neutral, deep core recruitment, and breath synchronization.",
    "Focus on neuromuscular recruitment and volume accumulation this week.",
]


class TestGateCatchesTheShippedDefect:
    """Negative-test proxy: these strings must be flagged by the CURRENT
    gate — proves the JARGON-list expansion is real, not decorative."""

    def test_every_evidence_phase_is_flagged(self):
        for p in _EVIDENCE_PHASES:
            assert lint(p) is not None, f"gate did not flag {p!r}"

    def test_every_evidence_focus_line_is_flagged(self):
        for f in _EVIDENCE_FOCUS_LINES:
            assert lint(f) is not None, f"gate did not flag {f!r}"


class TestPhaseLabelMapTranslatesTheEvidence:
    def test_phase_label_map_covers_all_evidence_phases(self):
        for p in _EVIDENCE_PHASES + ["Foundation (Base Building)", "Test/Maintenance"]:
            assert p in PHASE_LABEL_MAP, f"{p!r} has no plain-language mapping"
            assert lint(PHASE_LABEL_MAP[p]) is None, (
                f"mapped value for {p!r} still trips the gate: {PHASE_LABEL_MAP[p]!r}"
            )
            assert PHASE_LABEL_MAP[p] != p, f"{p!r} maps to itself — not actually renamed"


class TestRewriteTranslatesTheEvidenceFocusLines:
    def test_focus_lines_become_clean(self):
        for f in _EVIDENCE_FOCUS_LINES:
            out = rewrite(f)
            assert lint(out) is None, f"rewrite({f!r}) still trips the gate: {out!r}"

    def test_recruitment_and_accumulation_are_translated_not_dropped(self):
        out = rewrite("Focus on neuromuscular recruitment and volume accumulation this week.")
        assert "engagement" in out.lower()
        assert "buildup" in out.lower()
        # translate-don't-delete: the sentence must still be roughly as long,
        # not just have the jargon words stripped out.
        assert len(out) > 40


class TestGeneratorsNoLongerEmitJargonPhaseLabels:
    """The two live generator entry points (kept in sync per their own
    docstrings) must never again produce a jargon phase label for any
    week/duration combination."""

    def test_generate_programs_determine_phase_is_clean_across_range(self):
        for total in (4, 8, 12, 16):
            for week in range(1, total + 1):
                phase = generate_determine_phase(week, total, "")
                assert lint(phase) is None, f"determine_phase({week},{total}) -> {phase!r}"

    def test_program_sql_helper_determine_phase_is_clean_across_range(self):
        for total in (4, 8, 12, 16):
            for week in range(1, total + 1):
                phase = sql_helper_determine_phase(week, total, "")
                assert lint(phase) is None, f"determine_phase({week},{total}) -> {phase!r}"
