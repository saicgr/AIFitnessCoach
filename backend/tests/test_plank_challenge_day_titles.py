"""
Regression gate for row 111 (2026-08 backend prompt sweep): the 30-Day Plank
Challenge's Schedule tab showed cryptic numeric-shorthand day titles ("DAY 5
— 40S + SIDE", "DAY 30 — FINAL 180S TEST"). Root cause was two-fold:

1. Content: `programs.workouts[].workout_name` used raw seconds-with-"s"
   shorthand plus undefined abbreviations ("Side", "Taps").
2. Gate coverage: this program has `variant_base_id IS NULL` (a base-blob
   program served straight from `programs.workouts`, not
   `program_variant_weeks`) — audit_program_copy_clarity.py used to only
   ever query program_variant_weeks, so base-blob programs were completely
   unscanned. Fixed by fetch_base_blob_programs() + a "Day N — ...NNs..."
   shorthand pattern (the existing `^\\d+s\\b` rule is anchored to the START
   of the string, which never matches "Day 5 — 40s...").

scripts/fix_plank_challenge_day_titles.py is the content fix (dry-run by
default — this environment's write permissions block a direct apply; the
migration/script is ready for the maintainer to run).

No paid Gemini calls: purely regex + a static string mapping.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from scripts.audit_program_copy_clarity import lint  # noqa: E402
from scripts.fix_plank_challenge_day_titles import TITLE_MAP  # noqa: E402


def test_original_day_titles_are_flagged_by_the_gate():
    # Proves the gate (and this test) isn't vacuous: every OLD title in the
    # map is genuinely caught as cryptic shorthand today.
    flagged = [old for old in TITLE_MAP if lint(old) is not None]
    assert flagged == list(TITLE_MAP.keys()), (
        f"expected every original day title to be flagged; these weren't: "
        f"{set(TITLE_MAP) - set(flagged)}"
    )


def test_rewritten_day_titles_pass_the_gate():
    still_flagged = {new: lint(new) for new in TITLE_MAP.values() if lint(new) is not None}
    assert not still_flagged, f"rewritten titles still trip the gate: {still_flagged}"


def test_rewritten_titles_preserve_the_day_number_and_are_readable():
    for old, new in TITLE_MAP.items():
        old_day = old.split(" — ")[0]
        assert new.startswith(old_day), f"{new!r} lost its day number from {old!r}"
        assert "s " not in new.split("—")[-1].split(" ")[0], (
            f"{new!r} still looks like it opens with bare seconds shorthand"
        )
