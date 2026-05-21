"""Unit tests for services/program_library_importer.py.

Covers the deterministic transform layer that converts a `programs`-table row
into the normalized `days[]` shape used by `user_program_templates`:
  - normalize_reps_spec()  -- free-text rep parsing into a structured spec
  - reps_spec_display()    -- human rendering of a reps_spec
  - map_difficulty()       -- programs difficulty_level -> workouts difficulty
  - is_compound()          -- movement classification
  - default_rest_seconds() -- rest default by movement classification
  - derive_progression_strategy() / derive_deload_every_n() -- category routing
  - program_workouts_to_days() / normalize_program_blob_for_preview()

These are pure functions; the ExerciseResolver (which hits Supabase) is mocked
so the day-transform tests stay offline. No live DB, no Gemini.
"""
import os
import sys
from unittest.mock import patch

import pytest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from services.program_library_importer import (  # noqa: E402
    normalize_reps_spec,
    reps_spec_display,
    map_difficulty,
    is_compound,
    default_rest_seconds,
    derive_progression_strategy,
    derive_deload_every_n,
    program_workouts_to_days,
    normalize_program_blob_for_preview,
    DEFAULT_DIFFICULTY,
)


# =============================================================================
# normalize_reps_spec — the core free-text rep parser
# =============================================================================
class TestNormalizeRepsSpecFixed:
    """Single-number rep strings parse to kind='fixed'."""

    def test_plain_integer_string(self):
        spec = normalize_reps_spec("10")
        assert spec["kind"] == "fixed"
        assert spec["min"] == 10
        assert spec["max"] == 10
        assert spec["per_side"] is False
        assert "unit" not in spec

    def test_large_integer_string(self):
        spec = normalize_reps_spec("200")
        assert spec["kind"] == "fixed"
        assert spec["min"] == 200
        assert spec["max"] == 200
        assert spec["per_side"] is False

    def test_numeric_int_input(self):
        """A JSON numeric (not a string) is treated as a fixed rep count."""
        spec = normalize_reps_spec(12)
        assert spec["kind"] == "fixed"
        assert spec["min"] == 12
        assert spec["max"] == 12
        assert spec["per_side"] is False

    def test_numeric_float_input(self):
        spec = normalize_reps_spec(8.0)
        assert spec["kind"] == "fixed"
        assert spec["min"] == 8
        assert spec["max"] == 8


class TestNormalizeRepsSpecRange:
    """Range rep strings parse to kind='range'."""

    def test_simple_range(self):
        spec = normalize_reps_spec("10-12")
        assert spec["kind"] == "range"
        assert spec["min"] == 10
        assert spec["max"] == 12
        assert spec["per_side"] is False

    def test_wider_range(self):
        spec = normalize_reps_spec("8-12")
        assert spec["kind"] == "range"
        assert spec["min"] == 8
        assert spec["max"] == 12
        assert spec["per_side"] is False


class TestNormalizeRepsSpecTime:
    """Time-qualified rep strings parse to kind='time' with a unit."""

    def test_single_seconds(self):
        spec = normalize_reps_spec("30 seconds")
        assert spec["kind"] == "time"
        assert spec["min"] == 30
        assert spec["max"] == 30
        assert spec["unit"] == "seconds"
        assert spec["per_side"] is False

    def test_single_seconds_60(self):
        spec = normalize_reps_spec("60 seconds")
        assert spec["kind"] == "time"
        assert spec["min"] == 60
        assert spec["max"] == 60
        assert spec["unit"] == "seconds"

    def test_seconds_range(self):
        spec = normalize_reps_spec("30-60 seconds")
        assert spec["kind"] == "time"
        assert spec["min"] == 30
        assert spec["max"] == 60
        assert spec["unit"] == "seconds"
        assert spec["per_side"] is False

    def test_minutes_range(self):
        spec = normalize_reps_spec("1-2 minutes")
        assert spec["kind"] == "time"
        assert spec["min"] == 1
        assert spec["max"] == 2
        assert spec["unit"] == "minutes"

    def test_single_minutes(self):
        spec = normalize_reps_spec("30 minutes")
        assert spec["kind"] == "time"
        assert spec["min"] == 30
        assert spec["max"] == 30
        assert spec["unit"] == "minutes"
        assert spec["per_side"] is False


class TestNormalizeRepsSpecPerSide:
    """Per-side qualifiers ('each leg', 'per side') set per_side=True."""

    def test_range_each_leg(self):
        spec = normalize_reps_spec("10-15 each leg")
        assert spec["kind"] == "range"
        assert spec["min"] == 10
        assert spec["max"] == 15
        assert spec["per_side"] is True

    def test_fixed_per_side(self):
        spec = normalize_reps_spec("20 per side")
        assert spec["kind"] == "fixed"
        assert spec["min"] == 20
        assert spec["max"] == 20
        assert spec["per_side"] is True


class TestNormalizeRepsSpecAmrap:
    """AMRAP / to-failure strings parse to kind='amrap'."""

    def test_amrap_literal(self):
        spec = normalize_reps_spec("AMRAP")
        assert spec["kind"] == "amrap"
        assert spec["per_side"] is False
        assert "min" not in spec

    def test_amrap_lowercase(self):
        spec = normalize_reps_spec("amrap")
        assert spec["kind"] == "amrap"

    def test_to_failure(self):
        spec = normalize_reps_spec("to failure")
        assert spec["kind"] == "amrap"


class TestNormalizeRepsSpecFreeform:
    """Anything unparseable falls through to kind='freeform' (never drops)."""

    def test_climbing_freeform_fallback(self):
        """'10-15 minutes climbing' has trailing words -> freeform, raw kept."""
        spec = normalize_reps_spec("10-15 minutes climbing")
        assert spec["kind"] == "freeform"
        assert spec["raw"] == "10-15 minutes climbing"

    def test_none_input_is_empty_freeform(self):
        spec = normalize_reps_spec(None)
        assert spec["kind"] == "freeform"
        assert spec["raw"] == ""

    def test_empty_string_is_empty_freeform(self):
        spec = normalize_reps_spec("")
        assert spec["kind"] == "freeform"
        assert spec["raw"] == ""

    def test_pure_text_is_freeform(self):
        spec = normalize_reps_spec("as many as you can")
        # No leading number, not an AMRAP keyword -> freeform raw verbatim.
        assert spec["kind"] == "freeform"
        assert spec["raw"] == "as many as you can"


@pytest.mark.parametrize(
    "raw,expected_kind",
    [
        ("10", "fixed"),
        ("10-12", "range"),
        ("8-12", "range"),
        ("30 seconds", "time"),
        ("60 seconds", "time"),
        ("30-60 seconds", "time"),
        ("1-2 minutes", "time"),
        ("30 minutes", "time"),
        ("10-15 each leg", "range"),
        ("20 per side", "fixed"),
        ("200", "fixed"),
        ("AMRAP", "amrap"),
        ("10-15 minutes climbing", "freeform"),
    ],
)
def test_normalize_reps_spec_kind_matrix(raw, expected_kind):
    """Single source-of-truth matrix over every input the task enumerates."""
    assert normalize_reps_spec(raw)["kind"] == expected_kind


# =============================================================================
# reps_spec_display — human rendering
# =============================================================================
class TestRepsSpecDisplay:
    def test_fixed(self):
        assert reps_spec_display(normalize_reps_spec("10")) == "10"

    def test_range(self):
        assert reps_spec_display(normalize_reps_spec("8-12")) == "8-12"

    def test_per_side_suffix(self):
        assert reps_spec_display(normalize_reps_spec("20 per side")) == (
            "20 each side"
        )

    def test_time_single(self):
        assert reps_spec_display(normalize_reps_spec("30 seconds")) == (
            "30 seconds"
        )

    def test_time_range(self):
        assert reps_spec_display(normalize_reps_spec("1-2 minutes")) == (
            "1-2 minutes"
        )

    def test_amrap(self):
        assert reps_spec_display(normalize_reps_spec("AMRAP")) == "AMRAP"

    def test_freeform_returns_raw(self):
        spec = normalize_reps_spec("10-15 minutes climbing")
        assert reps_spec_display(spec) == "10-15 minutes climbing"


# =============================================================================
# map_difficulty — programs.difficulty_level -> workouts.difficulty
# =============================================================================
class TestMapDifficulty:
    @pytest.mark.parametrize(
        "level,expected",
        [
            ("Beginner", "easy"),
            ("Intermediate", "medium"),
            ("Advanced", "hard"),
            ("Elite", "hell"),
        ],
    )
    def test_all_four_program_levels(self, level, expected):
        assert map_difficulty(level) == expected

    @pytest.mark.parametrize(
        "level,expected",
        [
            ("beginner", "easy"),
            ("INTERMEDIATE", "medium"),
            ("  advanced  ", "hard"),
        ],
    )
    def test_case_and_whitespace_insensitive(self, level, expected):
        assert map_difficulty(level) == expected

    def test_already_valid_value_passes_through(self):
        assert map_difficulty("easy") == "easy"
        assert map_difficulty("hell") == "hell"

    def test_unknown_defaults_to_medium(self):
        assert map_difficulty("Superhuman") == DEFAULT_DIFFICULTY
        assert map_difficulty("xyz") == "medium"

    def test_none_defaults_to_medium(self):
        assert map_difficulty(None) == DEFAULT_DIFFICULTY

    def test_empty_string_defaults_to_medium(self):
        assert map_difficulty("") == DEFAULT_DIFFICULTY


# =============================================================================
# is_compound + default_rest_seconds — movement classification
# =============================================================================
class TestIsCompound:
    @pytest.mark.parametrize(
        "name",
        [
            "Barbell Back Squat",
            "Conventional Deadlift",
            "Bench Press",
            "Overhead Press",
            "Bent-Over Row",
            "Pull-up",
            "Walking Lunge",
            "Dip",
            "Hip Thrust",
        ],
    )
    def test_compound_movements(self, name):
        assert is_compound(name) is True

    @pytest.mark.parametrize(
        "name",
        ["Bicep Curl", "Lateral Raise", "Calf Raise", "Leg Extension",
         "Tricep Pushdown", "Cable Fly"],
    )
    def test_isolation_movements(self, name):
        assert is_compound(name) is False

    def test_empty_name_is_not_compound(self):
        assert is_compound("") is False
        assert is_compound(None) is False


class TestDefaultRestSeconds:
    def test_compound_rests_90s(self):
        assert default_rest_seconds("Barbell Squat") == 90
        assert default_rest_seconds("Deadlift") == 90

    def test_isolation_rests_60s(self):
        assert default_rest_seconds("Bicep Curl") == 60
        assert default_rest_seconds("Lateral Raise") == 60

    def test_empty_name_rests_60s(self):
        assert default_rest_seconds("") == 60


# =============================================================================
# derive_progression_strategy + derive_deload_every_n — category routing
# =============================================================================
class TestDeriveProgressionStrategy:
    @pytest.mark.parametrize(
        "category",
        ["strength", "Strength Training", "powerlifting", "hypertrophy",
         "bodybuilding", None, "", "cardio"],
    )
    def test_progressing_categories_get_linear(self, category):
        """Anything that is NOT a non-progressing category -> 'linear'."""
        assert derive_progression_strategy(category) == "linear"

    @pytest.mark.parametrize(
        "category",
        ["yoga", "Yoga Flow", "stretching", "stretch", "mobility",
         "flexibility", "recovery", "rehab", "Pain Relief"],
    )
    def test_non_progressing_categories_get_none(self, category):
        assert derive_progression_strategy(category) == "none"


class TestDeriveDeloadEveryN:
    def test_strength_deloads_every_5_weeks(self):
        assert derive_deload_every_n("strength") == 5
        assert derive_deload_every_n(None) == 5

    def test_yoga_has_no_deload(self):
        assert derive_deload_every_n("yoga") is None

    def test_stretching_has_no_deload(self):
        assert derive_deload_every_n("stretching") is None


# =============================================================================
# program_workouts_to_days — JSONB -> days[] transform (resolver mocked)
# =============================================================================
class _StubResolver:
    """A no-DB stand-in for ExerciseResolver: echoes the name unresolved."""

    def __init__(self, *_, **__):
        pass

    def resolve(self, exercise_name):
        name = (exercise_name or "").strip()
        return {
            "exercise_id": None,
            "resolved_name": name,
            "source": None,
            "unresolved": bool(name),
        }


class TestProgramWorkoutsToDays:
    def _program(self, **overrides):
        base = {
            "id": "prog-1",
            "program_name": "Test Program",
            "difficulty_level": "Intermediate",
            "workouts": [
                {
                    "day": 1,
                    "type": "strength",
                    "workout_name": "Upper A",
                    "exercises": [
                        {"exercise_name": "Bench Press", "sets": 4,
                         "reps": "8-12"},
                    ],
                },
                {
                    "day": 2,
                    "type": "rest",
                    "workout_name": "Rest Day",
                    "exercises": [],
                },
            ],
        }
        base.update(overrides)
        return base

    def test_each_workout_becomes_one_day(self):
        days = program_workouts_to_days(self._program(), _StubResolver())
        assert len(days) == 2
        assert days[0]["day_index"] == 0
        assert days[1]["day_index"] == 1

    def test_empty_exercise_day_is_rest(self):
        days = program_workouts_to_days(self._program(), _StubResolver())
        assert days[0]["is_rest"] is False
        assert days[1]["is_rest"] is True

    def test_day_inherits_program_difficulty_mapped(self):
        days = program_workouts_to_days(self._program(), _StubResolver())
        # Intermediate -> medium for the workouts.difficulty value set.
        assert days[0]["difficulty"] == "medium"
        assert days[1]["difficulty"] == "medium"

    def test_exercise_reps_are_normalized(self):
        days = program_workouts_to_days(self._program(), _StubResolver())
        ex = days[0]["exercises"][0]
        assert ex["reps_spec"]["kind"] == "range"
        assert ex["reps_spec"]["min"] == 8
        assert ex["reps_spec"]["max"] == 12
        assert ex["sets"] == 4

    def test_rest_default_applied_when_missing(self):
        days = program_workouts_to_days(self._program(), _StubResolver())
        # Bench Press is compound -> 90s default rest (no rest_seconds given).
        assert days[0]["exercises"][0]["rest_seconds"] == 90

    def test_workout_type_classified(self):
        days = program_workouts_to_days(self._program(), _StubResolver())
        assert days[0]["workout_type"] == "strength"

    def test_dict_shaped_blob_is_supported(self):
        """`workouts` may arrive as {'workouts': [...]} instead of a bare list."""
        prog = self._program()
        prog["workouts"] = {"workouts": prog["workouts"]}
        days = program_workouts_to_days(prog, _StubResolver())
        assert len(days) == 2

    def test_empty_program_raises(self):
        with pytest.raises(ValueError, match="no structured workouts"):
            program_workouts_to_days(
                self._program(workouts=[]), _StubResolver()
            )

    def test_amrap_exercise_marked_amrap_set_type(self):
        prog = self._program()
        prog["workouts"][0]["exercises"][0]["reps"] = "AMRAP"
        days = program_workouts_to_days(prog, _StubResolver())
        assert days[0]["exercises"][0]["set_type"] == "amrap"


# =============================================================================
# normalize_program_blob_for_preview — full preview payload
# =============================================================================
class TestNormalizeProgramBlobForPreview:
    def _program(self, **overrides):
        base = {
            "id": "prog-9",
            "program_name": "Strength Builder",
            "description": "A 4-day strength program",
            "program_category": "strength",
            "difficulty_level": "Advanced",
            "workouts": [
                {
                    "day": 1,
                    "type": "strength",
                    "workout_name": "Day 1",
                    "exercises": [
                        {"exercise_name": "Squat", "sets": 5, "reps": "5"},
                    ],
                },
            ],
        }
        base.update(overrides)
        return base

    def test_preview_payload_shape(self):
        # ExerciseResolver is constructed inside the function; patch it out so
        # this stays a pure offline test.
        with patch(
            "services.program_library_importer.ExerciseResolver",
            _StubResolver,
        ):
            preview = normalize_program_blob_for_preview(self._program())

        assert preview["name"] == "Strength Builder"
        assert preview["description"] == "A 4-day strength program"
        assert preview["category"] == "strength"
        assert preview["progression_strategy"] == "linear"
        assert preview["deload_every_n_weeks"] == 5
        assert preview["source_program_id"] == "prog-9"
        assert len(preview["days"]) == 1

    def test_week_length_floored_at_7(self):
        """A 1-day program still reports a >= 7 week_length (#L10)."""
        with patch(
            "services.program_library_importer.ExerciseResolver",
            _StubResolver,
        ):
            preview = normalize_program_blob_for_preview(self._program())
        assert preview["week_length"] >= 7

    def test_yoga_category_disables_progression(self):
        prog = self._program(program_category="yoga")
        with patch(
            "services.program_library_importer.ExerciseResolver",
            _StubResolver,
        ):
            preview = normalize_program_blob_for_preview(prog)
        assert preview["progression_strategy"] == "none"
        assert preview["deload_every_n_weeks"] is None
