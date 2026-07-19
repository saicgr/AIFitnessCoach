"""
Tests for the leaked-tool-call sanitizer and how-to chip gating.

Covers two regressions:
- BUG 2: a failed `generate_quick_workout` turn made the lite model re-emit the
  call as literal prose (`[generate_quick_workout(user_id="...", ...)]`). Both
  the JSON envelope AND bracket/paren function-call syntax must be scrubbed by
  `strip_leaked_tool_json`.
- BUG 9: a failed turn (no how-to text) wrongly emitted a `reference_exercise`
  chip off a bare exercise-name mention. `infer_inline_action` must gate that
  chip on a technique cue AND a non-failed tool turn.

Run with: pytest backend/tests/test_leaked_tool_call_sanitizer.py -v
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from services.langgraph_service import strip_leaked_tool_json
from services.chat_inline_actions import infer_inline_action


# ============================================================
# strip_leaked_tool_json — bracket/paren call syntax (BUG 2)
# ============================================================

def test_strips_bracketed_tool_call():
    text = (
        'Sorry about that! [generate_quick_workout(user_id="abc", '
        'duration_minutes=45, workout_type="full_body", intensity="moderate")]'
    )
    clean, recovered = strip_leaked_tool_json(text)
    assert "generate_quick_workout" not in clean
    assert "duration_minutes" not in clean
    assert clean == "Sorry about that!"
    assert recovered is None


def test_strips_bare_tool_call():
    text = 'generate_quick_workout(user_id="x", intensity="moderate")'
    clean, _ = strip_leaked_tool_json(text)
    # Whole message was the call — falls back to a graceful non-empty line.
    assert "generate_quick_workout" not in clean
    assert clean == "Here's what I put together for you."


def test_strips_generic_kwarg_call():
    text = 'Let me run add_set(workout_id=12, exercise="squat") for you'
    clean, _ = strip_leaked_tool_json(text)
    assert "add_set(" not in clean
    assert clean == "Let me run for you"


def test_json_envelope_still_recovered():
    text = 'Here you go {"action_ids": ["generate_quick_workout"], "prompt": "go"}'
    clean, recovered = strip_leaked_tool_json(text)
    assert "action_ids" not in clean
    assert recovered == {"action_ids": ["generate_quick_workout"], "prompt": "go"}


def test_prose_with_parens_is_preserved():
    # No `=` inside the parens, and a space before `(` — genuine prose.
    for text in (
        "aim for a deficit (about 500 kcal) daily",
        "your max heart rate (roughly 220 minus age) matters",
        "Great job on your chest press today!",
    ):
        clean, recovered = strip_leaked_tool_json(text)
        assert clean == text
        assert recovered is None


# ============================================================
# infer_inline_action — reference_exercise gating (BUG 9)
# ============================================================

def test_reference_exercise_emitted_with_howto_cue():
    action = infer_inline_action(
        "Here's how to do a proper barbell squat with good form.",
        "workout",
        {"tool_results": []},
    )
    assert action is not None
    assert action["action"] == "reference_exercise"


def test_reference_exercise_suppressed_without_howto_cue():
    # Bare exercise-name mention, no technique cue -> no chip.
    action = infer_inline_action(
        "Nice chest press today, keep crushing it!",
        "workout",
        {"tool_results": []},
    )
    assert action is None


def test_reference_exercise_suppressed_on_failed_tool_turn():
    # Even with a how-to cue, a failed tool turn must not emit the chip.
    action = infer_inline_action(
        "Here's how to do a proper squat with good form.",
        "workout",
        {"tool_results": [{"success": False, "error": "boom"}]},
    )
    assert action is None
