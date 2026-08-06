"""
Regression gate for row 146 (2026-08 backend prompt sweep): the coach's
EVENING RECAP said "This week: You have finished 2 workouts and 1 day of
nutrition tracking" while Home's calendar-week ring read "1 OF 4" for the
same day. Both numbers were arithmetically correct for what they measured —
`snapshot["weekly"]` is a TRAILING 7-day window ending today (see
api/v1/coach/daily_insight.py "This week (last 7 days)" builder), not the
Mon-start calendar week Home's ring uses. Only the LABEL was wrong.

Two chokepoints render this label and both are fixed here:
1. services/gemini/daily_insight_prompt.py `_EVENING_RECAP_BRANCH_INSTRUCTION`
   — the Gemini prompt that told the model to literally write "This week: ".
2. api/v1/coach/daily_insight.py `_grounded_greeting_lines` — the
   deterministic (no-LLM) "greeting" fallback that built the same sentence
   itself with a hardcoded "This week: " prefix.

No paid Gemini calls in this test: (1) is asserted by reading the prompt
source text directly (the model is never invoked), and (2) calls the pure
deterministic function directly.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from services.gemini import daily_insight_prompt  # noqa: E402
from api.v1.coach.daily_insight import _grounded_greeting_lines  # noqa: E402


def test_evening_recap_prompt_does_not_instruct_this_week_label():
    src = daily_insight_prompt._EVENING_RECAP_BRANCH_INSTRUCTION
    assert '"This week: "' not in src, (
        "The evening_recap prompt still instructs Gemini to label a "
        "trailing-7-day rollup as 'This week', which reads as the "
        "calendar week and disagrees with Home's Mon-start ring."
    )
    assert "In the last 7 days" in src


def test_grounded_greeting_lines_labels_trailing_window_honestly():
    snapshot = {
        "weekly": {"workouts_completed": 2, "avg_sleep_minutes": 420},
    }
    lines = _grounded_greeting_lines(snapshot, next_workout=None)
    weekly_line = next((l for l in lines if "workout" in l.lower()), None)
    assert weekly_line is not None, f"No weekly rollup line produced: {lines}"
    assert "This week:" not in weekly_line
    assert weekly_line.startswith("In the last 7 days:")
