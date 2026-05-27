"""Tests for the per-day workout-overrides prompt builder.

Covers the edge cases from `docs/planning/.../per_day_workout_overrides_design`
§3.7 — no overrides, single override, multiple overrides, orphan day
filtering, empty equipment override (bodyweight-only), notes propagation,
unknown focus fallback. Pure-function helper — no Gemini call needed.

Run:
    cd backend
    .venv/bin/python -m pytest tests/test_workout_day_overrides.py -v
"""
import pytest

from services.gemini.workout_generation_helpers import (
    _build_per_day_overrides_prompt,
)


class TestBuildPerDayOverridesPrompt:
    def test_o1_no_overrides_returns_empty(self):
        """O1: empty dict → empty string (caller skips the prompt block)."""
        result = _build_per_day_overrides_prompt({}, [1, 3, 5])
        assert result == ""

    def test_o1b_none_overrides_returns_empty(self):
        """O1b: empty dict same as None — caller filters before invocation."""
        result = _build_per_day_overrides_prompt({}, [])
        assert result == ""

    def test_o2_single_override_renders(self):
        """O2: 1 override → block contains exactly that day's line."""
        result = _build_per_day_overrides_prompt(
            {1: {"focus": "upper_body", "duration_min": 45, "intensity": "moderate"}},
            [1, 3, 5],
        )
        assert "Tuesday" in result
        assert "UPPER BODY" in result
        assert "45 min" in result
        assert "moderate" in result.lower()
        # Other days should not appear.
        assert "Thursday" not in result
        assert "Saturday" not in result

    def test_o3_multiple_overrides_all_render(self):
        """O3: 4 overrides → 4 lines, sorted Mon→Sun."""
        result = _build_per_day_overrides_prompt(
            {
                6: {"focus": "cardio", "duration_min": 30, "intensity": "easy"},
                1: {"focus": "upper_body", "duration_min": 45},
                3: {"focus": "lower_body", "duration_min": 60, "intensity": "hard"},
                5: {"focus": "full_body", "duration_min": 60},
            },
            [1, 3, 5, 6],
        )
        # All 4 days present.
        assert "Tuesday" in result
        assert "Thursday" in result
        assert "Saturday" in result
        assert "Sunday" in result
        # Sorted order: Tuesday < Thursday < Saturday < Sunday.
        tue_pos = result.find("Tuesday")
        thu_pos = result.find("Thursday")
        sat_pos = result.find("Saturday")
        sun_pos = result.find("Sunday")
        assert tue_pos < thu_pos < sat_pos < sun_pos

    def test_o4_orphan_override_filtered_out(self):
        """O4: override on a day NOT in workout_days → filtered, not rendered.
        (Plan §3.2 scenario F — preserve in storage, hide from prompt.)
        """
        result = _build_per_day_overrides_prompt(
            {
                1: {"focus": "upper_body"},  # Tue — in training days
                4: {"focus": "lower_body"},  # Fri — orphan, NOT in training days
            },
            [1, 3, 5],  # Mon-ish set, no Friday
        )
        assert "Tuesday" in result
        assert "Friday" not in result

    def test_o4b_empty_training_days_renders_all(self):
        """O4b: empty workout_days = no filtering applied. Defensive — the
        caller usually has training days, but if not we render everything
        rather than silently drop the user's customization."""
        result = _build_per_day_overrides_prompt(
            {1: {"focus": "upper_body"}, 4: {"focus": "lower_body"}},
            [],
        )
        assert "Tuesday" in result
        assert "Friday" in result

    def test_o5_empty_equipment_override_bodyweight_label(self):
        """O5: equipment_override=[] → 'bodyweight only' in the prompt."""
        result = _build_per_day_overrides_prompt(
            {6: {"focus": "cardio", "duration_min": 30,
                 "equipment_override": []}},
            [6],
        )
        assert "bodyweight only" in result
        assert "no equipment available" in result

    def test_o5b_equipment_override_with_items(self):
        """O5b: equipment_override list → comma-separated list in prompt."""
        result = _build_per_day_overrides_prompt(
            {1: {"focus": "upper_body",
                 "equipment_override": ["dumbbells", "bench"]}},
            [1],
        )
        assert "Equipment override:" in result
        assert "dumbbells" in result
        assert "bench" in result

    def test_o5c_no_equipment_override_silent(self):
        """O5c: equipment_override=None → no equipment line in the prompt."""
        result = _build_per_day_overrides_prompt(
            {1: {"focus": "upper_body"}},  # no equipment_override key
            [1],
        )
        assert "Equipment" not in result

    def test_o6_notes_rendered_verbatim(self):
        """O6: notes string → rendered verbatim in quotes (after whitespace
        sanitization). User said it, AI sees it."""
        result = _build_per_day_overrides_prompt(
            {3: {"focus": "lower_body", "duration_min": 60,
                 "notes": "Soccer match tomorrow — go lighter on quads"}},
            [3],
        )
        assert "Soccer match tomorrow" in result
        assert "go lighter on quads" in result
        assert "User note:" in result

    def test_o6b_notes_newlines_sanitized(self):
        """O6b: newlines + extra whitespace in notes get collapsed to a
        single space so the prompt block stays tidy."""
        result = _build_per_day_overrides_prompt(
            {3: {"focus": "upper_body",
                 "notes": "Line 1.\n\nLine 2.\n   Line 3."}},
            [3],
        )
        assert "Line 1. Line 2. Line 3." in result
        assert "\n\n" not in result.split("User note:")[1].split('"')[1]

    def test_o7_intensity_hell_label(self):
        """Hell intensity should mention the HELL MODE prompt block."""
        result = _build_per_day_overrides_prompt(
            {3: {"focus": "lower_body", "intensity": "hell"}},
            [3],
        )
        assert "HELL" in result

    def test_unknown_focus_falls_back_to_uppercase(self):
        """Defensive: an unknown focus value renders as uppercase rather
        than crashing or silently dropping the override."""
        result = _build_per_day_overrides_prompt(
            {1: {"focus": "custom_thing"}},
            [1],
        )
        assert "CUSTOM_THING" in result

    def test_missing_focus_defaults_to_full_body(self):
        """If `focus` key is missing, default to full_body."""
        result = _build_per_day_overrides_prompt(
            {1: {"duration_min": 45}},
            [1],
        )
        assert "FULL BODY" in result

    def test_invalid_day_payload_skipped(self):
        """Defensive: a non-dict value should be silently skipped, not crash."""
        result = _build_per_day_overrides_prompt(
            {1: {"focus": "upper_body"}, 3: "not a dict"},  # type: ignore[dict-item]
            [1, 3],
        )
        assert "Tuesday" in result
        assert "Thursday" not in result

    def test_block_has_explanatory_header_and_footer(self):
        """The prompt block opens with a clear "OVERRIDE" header so Gemini
        knows to prioritize these, and closes with a fallback hint."""
        result = _build_per_day_overrides_prompt(
            {1: {"focus": "upper_body"}},
            [1, 3, 5],
        )
        assert "OVERRIDE" in result
        assert "fall back to your training-split defaults" in result
