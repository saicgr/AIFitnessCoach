"""
Tests for core modules: config, logger, exercise_data, muscle_groups.

Tests:
- Configuration loading
- Logger setup and formatting
- Exercise data categorization
- Muscle group mappings

Run with: pytest backend/tests/test_core_modules.py -v
"""

import pytest
import logging
import os
from unittest.mock import patch, MagicMock
from io import StringIO


# ============================================================
# CONFIG TESTS
# ============================================================

class TestConfig:
    """Test configuration module."""

    def test_settings_loads_from_env(self, monkeypatch):
        """Test that settings loads from environment variables."""
        # Set required env vars
        monkeypatch.setenv("GEMINI_API_KEY", "test-api-key")
        monkeypatch.setenv("SUPABASE_URL", "https://test.supabase.co")
        monkeypatch.setenv("SUPABASE_KEY", "test-supabase-key")

        # Clear the LRU cache to force reload
        from core.config import get_settings
        get_settings.cache_clear()

        settings = get_settings()

        assert settings.gemini_api_key == "test-api-key"
        assert settings.supabase_url == "https://test.supabase.co"
        assert settings.supabase_key == "test-supabase-key"

    def test_settings_default_values(self, monkeypatch):
        """Test that settings has correct default values.

        Retired assertion: this used to assert
        `gemini_embedding_model == "text-embedding-004"`. That default was
        replaced in `core/config.py` when the project moved off the retired
        Google `text-embedding-004` model onto `gemini-embedding-001` (the
        current Gemini embedding model). The guarantee this test protects is
        unchanged: the settings object exposes a concrete, pinned embedding
        model plus the server/RAG defaults, so a missing env var can never
        leave the app with an unset model or a random port.

        Retired assertion 2: `gemini_max_tokens == 2000`. Commit 6defeb2f
        (Gemini 3 switch + structured output) raised the default cap to 2500
        because structured-output responses were being truncated at 2000.

        Note on `gemini_model`: the autouse `mock_env` fixture in conftest.py
        sets GEMINI_MODEL=gemini-2.5-flash, so this assertion pins the value
        the test environment injects (the pydantic default is
        `gemini-3.1-flash-lite`, overridden here by env).
        """
        monkeypatch.setenv("GEMINI_API_KEY", "test-api-key")
        monkeypatch.setenv("SUPABASE_URL", "https://test.supabase.co")
        monkeypatch.setenv("SUPABASE_KEY", "test-supabase-key")

        from core.config import get_settings
        get_settings.cache_clear()

        settings = get_settings()

        # Check defaults
        assert settings.gemini_model == "gemini-2.5-flash"
        assert settings.gemini_embedding_model == "gemini-embedding-001"
        assert settings.gemini_max_tokens == 2500
        assert settings.gemini_temperature == 0.7
        assert settings.host == "0.0.0.0"
        assert settings.port == 8000
        assert settings.rag_top_k == 5
        assert settings.rag_min_similarity == 0.7

    def test_settings_overrides(self, monkeypatch):
        """Test that environment variables override defaults."""
        monkeypatch.setenv("GEMINI_API_KEY", "test-api-key")
        monkeypatch.setenv("SUPABASE_URL", "https://test.supabase.co")
        monkeypatch.setenv("SUPABASE_KEY", "test-supabase-key")
        monkeypatch.setenv("GEMINI_MODEL", "gemini-pro")
        monkeypatch.setenv("PORT", "9000")

        from core.config import get_settings
        get_settings.cache_clear()

        settings = get_settings()

        assert settings.gemini_model == "gemini-pro"
        assert settings.port == 9000

    def test_settings_cors_origins(self, monkeypatch):
        """Test CORS origins configuration."""
        monkeypatch.setenv("GEMINI_API_KEY", "test-api-key")
        monkeypatch.setenv("SUPABASE_URL", "https://test.supabase.co")
        monkeypatch.setenv("SUPABASE_KEY", "test-supabase-key")

        from core.config import get_settings
        get_settings.cache_clear()

        settings = get_settings()

        assert isinstance(settings.cors_origins, list)
        assert len(settings.cors_origins) > 0

    def test_get_settings_cached(self, monkeypatch):
        """Test that get_settings returns cached instance."""
        monkeypatch.setenv("GEMINI_API_KEY", "test-api-key")
        monkeypatch.setenv("SUPABASE_URL", "https://test.supabase.co")
        monkeypatch.setenv("SUPABASE_KEY", "test-supabase-key")

        from core.config import get_settings
        get_settings.cache_clear()

        settings1 = get_settings()
        settings2 = get_settings()

        assert settings1 is settings2


# ============================================================
# LOGGER TESTS
# ============================================================

class TestLogger:
    """Test logger module."""

    def test_get_logger(self):
        """Test getting a logger instance."""
        from core.logger import get_logger

        logger = get_logger("test_module")

        assert logger is not None
        assert isinstance(logger, logging.Logger)
        assert logger.name == "test_module"

    def test_setup_logging(self):
        """Test logging setup."""
        from core.logger import setup_logging

        setup_logging("DEBUG")

        root_logger = logging.getLogger()
        assert root_logger.level == logging.DEBUG

    def test_setup_logging_levels(self):
        """Test different logging levels."""
        from core.logger import setup_logging

        setup_logging("WARNING")
        root_logger = logging.getLogger()
        assert root_logger.level == logging.WARNING

        setup_logging("ERROR")
        root_logger = logging.getLogger()
        assert root_logger.level == logging.ERROR

    def test_structured_formatter(self):
        """Test structured log formatting."""
        from core.logger import StructuredFormatter

        formatter = StructuredFormatter()

        # Create a mock log record
        record = logging.LogRecord(
            name="test.module",
            level=logging.INFO,
            pathname="test.py",
            lineno=10,
            msg="Test message",
            args=(),
            exc_info=None
        )

        formatted = formatter.format(record)

        assert "[INFO]" in formatted
        assert "[module]" in formatted
        assert "Test message" in formatted

    def test_structured_formatter_with_extras(self):
        """Test structured formatter with extra fields."""
        from core.logger import StructuredFormatter

        formatter = StructuredFormatter()

        record = logging.LogRecord(
            name="test",
            level=logging.INFO,
            pathname="test.py",
            lineno=10,
            msg="User action",
            args=(),
            exc_info=None
        )
        record.user_id = 123
        record.action = "login"

        formatted = formatter.format(record)

        assert "user_id=123" in formatted
        assert "action=login" in formatted

    def test_get_context_logger(self):
        """Test getting context logger with persistent context."""
        from core.logger import get_context_logger

        logger = get_context_logger("test", request_id="abc123", user_id=42)

        assert logger is not None
        assert logger.extra["request_id"] == "abc123"
        assert logger.extra["user_id"] == 42


# ============================================================
# EXERCISE DATA TESTS
# ============================================================

class TestExerciseData:
    """Test exercise data module."""

    def test_compound_exercises_defined(self):
        """Test that compound exercise lists are defined."""
        from core.exercise_data import COMPOUND_LOWER, COMPOUND_UPPER

        assert len(COMPOUND_LOWER) > 0
        assert len(COMPOUND_UPPER) > 0

        # Check expected exercises
        assert "squat" in COMPOUND_LOWER
        assert "deadlift" in COMPOUND_LOWER
        assert "bench press" in COMPOUND_UPPER
        assert "pull-up" in COMPOUND_UPPER

    def test_progression_increments(self):
        """Test progression increment values.

        Retired assertion: this used to assert
        `PROGRESSION_INCREMENTS["isolation"] == 1.25`. Commit 72b20835 changed
        the isolation increment from 1.25 kg to 2.5 kg deliberately (see the
        inline comment in core/exercise_data.py: "Changed from 1.25 to 2.5
        (realistic for dumbbells)") — a 1.25 kg jump is unloadable on a
        standard dumbbell rack, so the recommender was emitting weights the
        user could not actually pick up.

        The guarantee this test protects is unchanged: every exercise type has
        a defined kg increment, compound-lower jumps the most, bodyweight never
        gets an external-load bump, and no increment is finer than what a real
        gym can load.
        """
        from core.exercise_data import PROGRESSION_INCREMENTS

        assert PROGRESSION_INCREMENTS["compound_upper"] == 2.5
        assert PROGRESSION_INCREMENTS["compound_lower"] == 5.0
        assert PROGRESSION_INCREMENTS["isolation"] == 2.5
        assert PROGRESSION_INCREMENTS["bodyweight"] == 0
        # Ordering invariant that survived the value change.
        assert (
            PROGRESSION_INCREMENTS["compound_lower"]
            > PROGRESSION_INCREMENTS["compound_upper"]
            >= PROGRESSION_INCREMENTS["isolation"]
            > PROGRESSION_INCREMENTS["bodyweight"]
        )

    def test_exercise_substitutes(self):
        """Test exercise substitutes mapping."""
        from core.exercise_data import EXERCISE_SUBSTITUTES

        assert "bench press" in EXERCISE_SUBSTITUTES
        assert "pull-ups" in EXERCISE_SUBSTITUTES
        assert "squat" in EXERCISE_SUBSTITUTES

        # Check substitutes exist
        bench_subs = EXERCISE_SUBSTITUTES["bench press"]
        assert len(bench_subs) > 0
        assert "dumbbell press" in bench_subs

    def test_get_exercise_type_compound_lower(self):
        """Test exercise type categorization for compound lower."""
        from core.exercise_data import get_exercise_type

        assert get_exercise_type("Barbell Squat") == "compound_lower"
        assert get_exercise_type("Romanian Deadlift") == "compound_lower"
        assert get_exercise_type("leg press machine") == "compound_lower"

    def test_get_exercise_type_compound_upper(self):
        """Test exercise type categorization for compound upper."""
        from core.exercise_data import get_exercise_type

        assert get_exercise_type("Bench Press") == "compound_upper"
        assert get_exercise_type("Overhead Press") == "compound_upper"
        assert get_exercise_type("Barbell Row") == "compound_upper"
        assert get_exercise_type("Pull-up") == "compound_upper"

    def test_get_exercise_type_bodyweight(self):
        """Test exercise type categorization for bodyweight.

        Retired assertion: this used to assert
        `get_exercise_type("Push-ups") == "bodyweight"`. Commit d730c1a9
        rebuilt COMPOUND_LOWER/COMPOUND_UPPER against the 2,078-exercise
        library and deliberately moved the push family ("push-up", "push up",
        "pushup") into COMPOUND_UPPER alongside the pull family — both are
        multi-joint upper-body pressing/pulling patterns that CAN be externally
        loaded (weighted vest / plate / dip belt), so they take a compound
        weight increment and the 6-12 compound rep band. The test already
        encoded that reasoning for "Pull-ups"; push-ups now follow the same
        rule.

        The guarantee this test protects is unchanged: the "bodyweight" bucket
        is reserved for movements with no loadable progression (planks,
        crunches, conditioning drills) so they never get a kg increment
        recommended against them.
        """
        from core.exercise_data import get_exercise_type, PROGRESSION_INCREMENTS

        # Loadable multi-joint calisthenics -> compound, not bodyweight.
        assert get_exercise_type("Push-ups") == "compound_upper"
        assert get_exercise_type("Pull-ups") == "compound_upper"

        # Unloadable core / conditioning movements -> bodyweight.
        assert get_exercise_type("Plank") == "bodyweight"
        assert get_exercise_type("Crunches") == "bodyweight"
        assert get_exercise_type("Burpees") == "bodyweight"
        assert get_exercise_type("Mountain Climbers") == "bodyweight"

        # The whole point of the bodyweight bucket: no external-load increment.
        assert PROGRESSION_INCREMENTS[get_exercise_type("Plank")] == 0

    def test_get_exercise_type_isolation(self):
        """Test exercise type categorization for isolation."""
        from core.exercise_data import get_exercise_type

        assert get_exercise_type("Bicep Curl") == "isolation"
        assert get_exercise_type("Lateral Raise") == "isolation"
        assert get_exercise_type("Tricep Extension") == "isolation"
        assert get_exercise_type("Calf Raise") == "isolation"

    def test_get_exercise_priority_compound(self):
        """Test exercise priority for compound movements."""
        from core.exercise_data import get_exercise_priority

        assert get_exercise_priority("Squat") == 100
        assert get_exercise_priority("Deadlift") == 100
        assert get_exercise_priority("Bench Press") == 100
        assert get_exercise_priority("Barbell Row") == 100

    def test_get_exercise_priority_secondary(self):
        """Test exercise priority for secondary movements."""
        from core.exercise_data import get_exercise_priority

        assert get_exercise_priority("Lunge") == 75
        assert get_exercise_priority("Dips") == 75
        assert get_exercise_priority("Hip Thrust") == 75

    def test_get_exercise_priority_isolation(self):
        """Test exercise priority for isolation movements."""
        from core.exercise_data import get_exercise_priority

        assert get_exercise_priority("Bicep Curl") == 50
        assert get_exercise_priority("Lateral Raise") == 50
        assert get_exercise_priority("Tricep Extension") == 50

    def test_exercise_time_estimates(self):
        """Test exercise time estimates."""
        from core.exercise_data import EXERCISE_TIME_ESTIMATES

        assert EXERCISE_TIME_ESTIMATES["compound"] == 8
        assert EXERCISE_TIME_ESTIMATES["isolation"] == 5
        assert EXERCISE_TIME_ESTIMATES["bodyweight"] == 4


# ============================================================
# MUSCLE GROUPS TESTS
# ============================================================

class TestMuscleGroups:
    """Test muscle groups module."""

    def test_muscle_group_mappings_exist(self):
        """Test that muscle group mappings are defined.

        Wrong import fixed: this imported `MUSCLE_GROUPS` from
        core.muscle_groups, a name that module has never exported (see
        `core/__init__.py`, which re-exports WEEKLY_SET_TARGETS and
        MUSCLE_TO_EXERCISES). The canonical muscle-group taxonomy IS the key
        set of WEEKLY_SET_TARGETS (every group the volume engine can budget
        sets for). Same intent, real names.
        """
        from core.muscle_groups import (
            WEEKLY_SET_TARGETS,
            MUSCLE_TO_EXERCISES,
            EXERCISE_TO_MUSCLES,
        )

        assert len(WEEKLY_SET_TARGETS) > 0
        assert len(MUSCLE_TO_EXERCISES) > 0
        assert len(EXERCISE_TO_MUSCLES) > 0

        # The three mappings must agree on the taxonomy: every muscle that has
        # a weekly set target must also have exercises that train it.
        assert set(MUSCLE_TO_EXERCISES) == set(WEEKLY_SET_TARGETS)

    def test_muscle_groups_structure(self):
        """Test muscle groups structure.

        Retired assertion: this used to look for the coarse groups
        ["chest", "back", "shoulders", "legs", "arms", "core"] inside a
        `MUSCLE_GROUPS` collection that does not exist. The real taxonomy
        (WEEKLY_SET_TARGETS / MUSCLE_TO_EXERCISES) is *finer*: legs is split
        into quadriceps/hamstrings/glutes/calves and arms into biceps/triceps,
        because weekly set targets differ per head. The guarantee this test
        protects is the same: every major trained region is represented, none
        was dropped.
        """
        from core.muscle_groups import WEEKLY_SET_TARGETS, get_target_sets

        groups = set(WEEKLY_SET_TARGETS)

        # Torso + core are named directly.
        for group in ["chest", "back", "shoulders", "core"]:
            assert group in groups, f"Muscle group {group} not found"

        # "Legs" and "arms" are represented by their constituent muscles.
        for leg_muscle in ["quadriceps", "hamstrings", "glutes", "calves"]:
            assert leg_muscle in groups, f"Leg muscle {leg_muscle} not found"
        for arm_muscle in ["biceps", "triceps"]:
            assert arm_muscle in groups, f"Arm muscle {arm_muscle} not found"

        # Each target is a sane (min, max) weekly set range.
        for group, (low, high) in WEEKLY_SET_TARGETS.items():
            assert 0 < low < high, f"Bad weekly set range for {group}: {(low, high)}"
            assert low <= get_target_sets(group) <= high

    def test_exercise_to_muscles_mapping(self):
        """Test exercise to muscles mapping."""
        from core.muscle_groups import EXERCISE_TO_MUSCLES

        # Check common exercises have mappings
        if "bench press" in EXERCISE_TO_MUSCLES:
            muscles = EXERCISE_TO_MUSCLES["bench press"]
            assert len(muscles) > 0
            assert "chest" in str(muscles).lower() or len(muscles) > 0


# ============================================================
# INJURY MAPPINGS TESTS
# ============================================================

class TestInjuryMappings:
    """Test injury mappings module."""

    def test_injury_mappings_exist(self):
        """Test that injury mappings are defined.

        Wrong import fixed: this imported `INJURY_TO_AVOID_EXERCISES` and
        `INJURY_ALTERNATIVES` from core.injury_mappings — names that module has
        never exported. The real names (see core/__init__.py) are
        INJURY_CONTRAINDICATIONS (exercises to avoid per injury) and
        SUBSTITUTE_CONTRAINDICATIONS (patterns a substitute must not contain).
        Same intent, real names.
        """
        from core.injury_mappings import (
            INJURY_CONTRAINDICATIONS,
            SUBSTITUTE_CONTRAINDICATIONS,
        )

        assert len(INJURY_CONTRAINDICATIONS) > 0
        assert len(SUBSTITUTE_CONTRAINDICATIONS) > 0

    def test_common_injuries_mapped(self):
        """Test that common injuries have mappings.

        Strengthened: the original loop computed `found` and then never used
        it — it asserted only `isinstance(..., dict)`, which cannot fail. Every
        one of the common injuries it listed IS in fact mapped, so the check is
        now the real one the test's name promises, plus the contraindication
        engine actually flagging a known-bad exercise for each.
        """
        from core.injury_mappings import (
            INJURY_CONTRAINDICATIONS,
            is_exercise_contraindicated,
        )

        common_injuries = ["shoulder", "knee", "lower back", "wrist"]

        for injury in common_injuries:
            assert injury in INJURY_CONTRAINDICATIONS, f"{injury} has no avoid list"
            avoid = INJURY_CONTRAINDICATIONS[injury]
            assert len(avoid) > 0, f"{injury} avoid list is empty"
            # The mapping must be live: a listed exercise is actually flagged.
            assert is_exercise_contraindicated(avoid[0], injury) is True

    def test_injury_alternatives_structure(self):
        """Test injury alternatives structure.

        Wrong import fixed (see test_injury_mappings_exist): the alternatives
        side of the module is SUBSTITUTE_CONTRAINDICATIONS + find_safe_substitute().
        Intent preserved — the alternatives data is well-formed AND actually
        yields a substitute that is not itself contraindicated for the injury.
        """
        from core.exercise_data import EXERCISE_SUBSTITUTES
        from core.injury_mappings import (
            INJURY_CONTRAINDICATIONS,
            SUBSTITUTE_CONTRAINDICATIONS,
            is_exercise_contraindicated,
            find_safe_substitute,
        )

        for injury, bad_patterns in SUBSTITUTE_CONTRAINDICATIONS.items():
            assert isinstance(bad_patterns, (list, dict))
            assert len(bad_patterns) > 0

        # REGRESSION GATE (real bug, fixed in core/injury_mappings.py):
        # find_safe_substitute only filtered against SUBSTITUTE_CONTRAINDICATIONS
        # and never re-checked the authoritative avoid list, so it returned
        # substitutes that were themselves contraindicated for the same injury
        # (wrist: push-ups -> bench press; wrist: barbell curl -> dumbbell curl;
        # elbow: tricep pushdown -> skull crushers).
        # workout_adaptation_service._substitute_injury_exercises swaps whatever
        # comes back straight into the user's workout.
        # Invariant: a substitute offered for an injury is NEVER contraindicated
        # for that injury. (None is allowed — the caller then drops the exercise.)
        for exercise in EXERCISE_SUBSTITUTES:
            for injury in INJURY_CONTRAINDICATIONS:
                substitute = find_safe_substitute(exercise, injury)
                if substitute is not None:
                    assert is_exercise_contraindicated(substitute, injury) is False, (
                        f"{injury} injury: {exercise} -> {substitute} is itself "
                        f"on the avoid list {INJURY_CONTRAINDICATIONS[injury]}"
                    )

        # And the substitution engine still actually substitutes when it safely can.
        bench_sub = find_safe_substitute("bench press", "shoulder")
        assert bench_sub is not None
        assert is_exercise_contraindicated(bench_sub, "shoulder") is False


# ============================================================
# EDGE CASES
# ============================================================

class TestEdgeCases:
    """Test edge cases and error handling."""

    def test_get_exercise_type_empty_string(self):
        """Test exercise type with empty string."""
        from core.exercise_data import get_exercise_type

        result = get_exercise_type("")
        assert result == "isolation"  # Default for unknown

    def test_get_exercise_type_case_insensitive(self):
        """Test exercise type is case insensitive."""
        from core.exercise_data import get_exercise_type

        assert get_exercise_type("SQUAT") == get_exercise_type("squat")
        assert get_exercise_type("Bench Press") == get_exercise_type("bench press")

    def test_get_exercise_priority_unknown(self):
        """Test exercise priority for unknown exercise."""
        from core.exercise_data import get_exercise_priority

        result = get_exercise_priority("Unknown Exercise XYZ")
        assert result == 50  # Default for unknown

    def test_logger_handles_unicode(self):
        """Test logger handles unicode characters."""
        from core.logger import get_logger, StructuredFormatter

        logger = get_logger("unicode_test")
        formatter = StructuredFormatter()

        record = logging.LogRecord(
            name="test",
            level=logging.INFO,
            pathname="test.py",
            lineno=10,
            msg="Message with emoji: fitness test",
            args=(),
            exc_info=None
        )

        formatted = formatter.format(record)
        assert "fitness" in formatted


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
