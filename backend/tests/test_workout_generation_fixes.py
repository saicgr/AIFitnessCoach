"""Unit tests for duration resolver, equipment inference, and dedup helpers.

Covers the three fixes landed together:
  1. resolve_target_duration — user preferences fall back correctly when the
     request body omits duration (fixes workout showing 45 min instead of 30).
  2. infer_equipment_from_name — hanging / muscle-up / lever movements are
     treated as needing a Pull-Up Bar even when the DB tag says bodyweight.
  3. dedup_key / strip_dedup_suffix — ``Burpee`` and ``Burpee(1)`` collapse.
"""

import os
import sys

import pytest

# Allow the tests to run from repo root or backend/ without pytest.ini tweaks.
BACKEND_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if BACKEND_DIR not in sys.path:
    sys.path.insert(0, BACKEND_DIR)

from api.v1.workouts.utils import resolve_target_duration  # noqa: E402
from services.exercise_rag.utils import (  # noqa: E402
    dedup_key,
    infer_equipment_from_name,
    strip_dedup_suffix,
)


# ---------------------------------------------------------------------------
# resolve_target_duration
# ---------------------------------------------------------------------------

class TestResolveTargetDuration:
    def test_body_duration_wins_over_everything(self):
        out = resolve_target_duration(
            body_duration=25,
            body_duration_min=None,
            body_duration_max=None,
            gym_profile={"duration_minutes": 60},
            user={"preferences": {"workout_duration": 45}},
        )
        assert out["target"] == 25

    def test_gym_profile_beats_user_prefs(self):
        out = resolve_target_duration(
            body_duration=None,
            body_duration_min=None,
            body_duration_max=None,
            gym_profile={"duration_minutes": 30},
            user={"preferences": {"workout_duration": 60}},
        )
        assert out["target"] == 30

    def test_user_prefs_when_body_and_gym_empty(self):
        # Reproduces the original bug: user set 30 min, no body or gym value.
        out = resolve_target_duration(
            body_duration=None,
            body_duration_min=None,
            body_duration_max=None,
            gym_profile=None,
            user={"preferences": {"workout_duration_max": 30, "workout_duration_min": 15}},
        )
        assert out["target"] == 30
        assert out["min"] == 15
        assert out["max"] == 30

    def test_asymmetric_range_min_only(self):
        out = resolve_target_duration(
            body_duration=None,
            body_duration_min=None,
            body_duration_max=None,
            gym_profile=None,
            user={"preferences": {"workout_duration_min": 40}},
        )
        assert out["min"] == 40
        assert out["max"] is None
        # Target falls back to min via default (no target set)
        assert out["target"] == 45  # min isn't treated as target; default kicks in

    def test_default_when_nothing_set(self):
        out = resolve_target_duration(
            body_duration=None,
            body_duration_min=None,
            body_duration_max=None,
            gym_profile=None,
            user=None,
        )
        assert out["target"] == 45

    def test_string_preferences_are_coerced(self):
        # preferences stored in JSONB sometimes deserialize as strings
        out = resolve_target_duration(
            body_duration=None,
            body_duration_min=None,
            body_duration_max=None,
            gym_profile={"duration_minutes": "30"},
            user=None,
        )
        assert out["target"] == 30

    def test_invalid_zero_or_negative_ignored(self):
        out = resolve_target_duration(
            body_duration=0,
            body_duration_min=-5,
            body_duration_max=None,
            gym_profile=None,
            user={"preferences": {"workout_duration": 40}},
        )
        assert out["target"] == 40


# ---------------------------------------------------------------------------
# infer_equipment_from_name
# ---------------------------------------------------------------------------

class TestInferEquipmentFromName:
    @pytest.mark.parametrize("name", [
        "Hanging Toes-to-Bar",
        "Hanging Leg Raise",
        "Tuck Front Lever Holds",
        "Front Lever Raise",
        "Back Lever",
        "Skin the Cat",
        "Bodyweight Muscle-Up",
        "Kipping Pull Up",
        "Dead Hang",
        "Bar Hang",
        "Knees to Elbows",
    ])
    def test_requires_pullup_bar(self, name):
        assert infer_equipment_from_name(name) == "Pull-Up Bar"

    @pytest.mark.parametrize("name", [
        "Assisted Pull-Up",
        "Assisted Chin-Up Machine",
    ])
    def test_assisted_variants_not_flagged_as_pullup_bar(self, name):
        assert infer_equipment_from_name(name) != "Pull-Up Bar"

    def test_bench_dip_is_not_dip_station(self):
        assert infer_equipment_from_name("Bench Dip") != "Dip Station"

    def test_parallel_bar_dip_is_dip_station(self):
        assert infer_equipment_from_name("Parallel Bar Dip") == "Dip Station"

    def test_trx_row_is_suspension_trainer(self):
        assert infer_equipment_from_name("TRX Row") == "Suspension Trainer"

    def test_ring_pull_up_is_gymnastic_rings(self):
        # Ring tokens take priority over "pull-up" pullup-bar rule.
        assert infer_equipment_from_name("Ring Pull-Up") == "Gymnastic Rings"

    def test_plain_burpee_stays_bodyweight(self):
        assert infer_equipment_from_name("Burpee") == "Bodyweight"

    def test_empty_name_is_bodyweight(self):
        assert infer_equipment_from_name("") == "Bodyweight"


# ---------------------------------------------------------------------------
# dedup_key / strip_dedup_suffix
# ---------------------------------------------------------------------------

class TestDedupKey:
    def test_strip_parenthesized_suffix(self):
        assert strip_dedup_suffix("Burpee(1)") == "Burpee"

    def test_strip_with_spaces(self):
        assert strip_dedup_suffix("Bird Dog (3)") == "Bird Dog"

    def test_strip_trailing_whitespace(self):
        assert strip_dedup_suffix("Burpee(1) ") == "Burpee"

    def test_no_suffix_unchanged(self):
        assert strip_dedup_suffix("Burpee") == "Burpee"

    def test_dedup_key_collapses_case_and_suffix(self):
        assert dedup_key("Burpee") == dedup_key("Burpee(1)") == dedup_key("BURPEE (2)")

    def test_empty_name(self):
        assert dedup_key("") == ""
        assert dedup_key(None) == ""  # type: ignore[arg-type]

    def test_suffix_that_looks_like_a_version_number_in_middle_is_preserved(self):
        # Only trailing "(N)" is stripped — in-name parens should survive.
        assert strip_dedup_suffix("Foo(1) Bar") == "Foo(1) Bar"
