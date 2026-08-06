"""
Regression gate for row 110 (2026-08 backend prompt sweep): Program detail ->
SCHEDULE tab showed interval descriptions in fractional minutes — "3 rounds:
1 min hard, 0.5 min easy", "2 rounds: 3 min hard, 1.5 min easy" — nobody
reads a rest interval as a decimal minute.

Root cause: `scripts/program_build.py` `_rewrite_minutes_text` (used by the
Easy/Medium/Hard intensity-variant deriver, `scale_intensity`, to keep a
timed exercise's human-readable `reps` text in sync after scaling its
`duration_seconds` by a 0.85x/1.15x factor) computed
`round(new_seconds / 60, 1)` and substituted that straight into the "N min"
text — whenever the scaled duration wasn't a clean multiple of 60 (e.g. 30s
Easy-scaled from a ~35s original), the result was a decimal minute like
"0.5 min".

Fix: when the scaled duration is a whole number of minutes, use whole
minutes; otherwise swap the UNIT to seconds ("1 min" -> "30 sec") instead of
writing a fraction. No paid calls — pure string-rewrite unit test.
"""
import os
import sys

_SCRIPTS_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "scripts")
_BACKEND_DIR = os.path.dirname(_SCRIPTS_DIR)
for p in (_SCRIPTS_DIR, _BACKEND_DIR):
    if p not in sys.path:
        sys.path.insert(0, p)

import program_build as pb  # noqa: E402


def test_the_exact_shipped_defect_case():
    # "1 min hard" scaled down to 30s (Easy factor) used to become
    # "0.5 min hard" — must now read "30 sec hard".
    result = pb._rewrite_minutes_text("3 rounds: 1 min hard, 1 min easy", 30)
    assert "0.5 min" not in result
    assert "30 sec hard" in result


def test_ninety_second_scale_does_not_produce_a_fraction():
    # The function only rewrites the FIRST minute mention (the exercise's
    # own scaled duration) — "3 min hard" here. 90s isn't a clean multiple
    # of 60, so it must become "90 sec hard", never "1.5 min hard".
    result = pb._rewrite_minutes_text("2 rounds: 3 min hard, rest between", 90)
    assert "1.5 min" not in result
    assert "90 sec hard" in result


def test_whole_minute_scaling_still_uses_minutes():
    # 900s is a clean 15 minutes — should NOT be forced into seconds.
    result = pb._rewrite_minutes_text("30 minutes easy", 900)
    assert result == "15 minutes easy"


def test_seconds_text_path_is_unaffected():
    result = pb._rewrite_minutes_text("30 seconds", 25)
    assert result == "25 seconds"


def test_no_recognizable_pattern_is_a_noop():
    assert pb._rewrite_minutes_text("AMRAP", 45) == "AMRAP"


def test_non_string_input_is_a_noop():
    assert pb._rewrite_minutes_text(None, 30) is None
