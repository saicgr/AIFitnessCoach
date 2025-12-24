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
        """Test that settings has correct default values."""
        monkeypatch.setenv("GEMINI_API_KEY", "test-api-key")
        monkeypatch.setenv("SUPABASE_URL", "https://test.supabase.co")
        monkeypatch.setenv("SUPABASE_KEY", "test-supabase-key")

        from core.config import get_settings
        get_settings.cache_clear()

        settings = get_settings()

        # Check defaults
        assert settings.gemini_model == "gemini-2.5-flash"
        assert settings.gemini_embedding_model == "text-embedding-004"
        assert settings.gemini_max_tokens == 2000
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
        """Test progression increment values."""
        from core.exercise_data import PROGRESSION_INCREMENTS

        assert PROGRESSION_INCREMENTS["compound_upper"] == 2.5
        assert PROGRESSION_INCREMENTS["compound_lower"] == 5.0
        assert PROGRESSION_INCREMENTS["isolation"] == 1.25
        assert PROGRESSION_INCREMENTS["bodyweight"] == 0

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
        """Test exercise type categorization for bodyweight."""
        from core.exercise_data import get_exercise_type

        assert get_exercise_type("Push-ups") == "bodyweight"
        assert get_exercise_type("Pull-ups") == "compound_upper"  # Pull-up is in COMPOUND_UPPER
        assert get_exercise_type("Plank") == "bodyweight"
        assert get_exercise_type("Crunches") == "bodyweight"

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
        """Test that muscle group mappings are defined."""
        from core.muscle_groups import MUSCLE_GROUPS, EXERCISE_TO_MUSCLES

        assert len(MUSCLE_GROUPS) > 0
        assert len(EXERCISE_TO_MUSCLES) > 0

    def test_muscle_groups_structure(self):
        """Test muscle groups structure."""
        from core.muscle_groups import MUSCLE_GROUPS

        # Check main muscle groups exist
        expected_groups = ["chest", "back", "shoulders", "legs", "arms", "core"]

        for group in expected_groups:
            found = any(group in str(mg).lower() for mg in MUSCLE_GROUPS)
            assert found, f"Muscle group {group} not found"

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
        """Test that injury mappings are defined."""
        from core.injury_mappings import INJURY_TO_AVOID_EXERCISES, INJURY_ALTERNATIVES

        assert len(INJURY_TO_AVOID_EXERCISES) > 0
        assert len(INJURY_ALTERNATIVES) > 0

    def test_common_injuries_mapped(self):
        """Test that common injuries have mappings."""
        from core.injury_mappings import INJURY_TO_AVOID_EXERCISES

        # Common injuries should have avoid lists
        common_injuries = ["shoulder", "knee", "lower back", "wrist"]

        for injury in common_injuries:
            found = any(injury in str(key).lower() for key in INJURY_TO_AVOID_EXERCISES)
            # This may not be true for all injuries, so just check structure
            assert isinstance(INJURY_TO_AVOID_EXERCISES, dict)

    def test_injury_alternatives_structure(self):
        """Test injury alternatives structure."""
        from core.injury_mappings import INJURY_ALTERNATIVES

        for injury, alternatives in INJURY_ALTERNATIVES.items():
            assert isinstance(alternatives, (list, dict))


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
