"""
Tests for core/exercise_data.py module.

Tests exercise categorization, progression increments, and priority scoring.
"""
import pytest

from core.exercise_data import (
    COMPOUND_LOWER,
    COMPOUND_UPPER,
    PROGRESSION_INCREMENTS,
    EXERCISE_SUBSTITUTES,
    EXERCISE_TIME_ESTIMATES,
    get_exercise_type,
    get_exercise_priority,
)


class TestExerciseConstants:
    """Test exercise data constants are properly defined."""

    def test_compound_lower_exercises_exist(self):
        """Compound lower exercises should be defined."""
        assert len(COMPOUND_LOWER) > 0
        assert "squat" in COMPOUND_LOWER
        assert "deadlift" in COMPOUND_LOWER
        assert "leg press" in COMPOUND_LOWER

    def test_compound_upper_exercises_exist(self):
        """Compound upper exercises should be defined."""
        assert len(COMPOUND_UPPER) > 0
        assert "bench press" in COMPOUND_UPPER
        assert "overhead press" in COMPOUND_UPPER
        assert "row" in COMPOUND_UPPER
        assert "pull-up" in COMPOUND_UPPER

    def test_progression_increments_defined(self):
        """Progression increments should be defined for all types."""
        assert "compound_upper" in PROGRESSION_INCREMENTS
        assert "compound_lower" in PROGRESSION_INCREMENTS
        assert "isolation" in PROGRESSION_INCREMENTS
        assert "bodyweight" in PROGRESSION_INCREMENTS

    def test_progression_increment_values(self):
        """Progression increments should have appropriate values."""
        assert PROGRESSION_INCREMENTS["compound_lower"] == 5.0
        assert PROGRESSION_INCREMENTS["compound_upper"] == 2.5
        assert PROGRESSION_INCREMENTS["isolation"] == 1.25
        assert PROGRESSION_INCREMENTS["bodyweight"] == 0

    def test_exercise_substitutes_defined(self):
        """Exercise substitutes should be defined for common exercises."""
        assert "bench press" in EXERCISE_SUBSTITUTES
        assert "squat" in EXERCISE_SUBSTITUTES
        assert "barbell row" in EXERCISE_SUBSTITUTES
        assert "pull-ups" in EXERCISE_SUBSTITUTES

    def test_exercise_substitutes_have_alternatives(self):
        """Each exercise should have at least one substitute."""
        for exercise, substitutes in EXERCISE_SUBSTITUTES.items():
            assert len(substitutes) > 0, f"{exercise} has no substitutes"

    def test_exercise_time_estimates_defined(self):
        """Exercise time estimates should be defined."""
        assert "compound" in EXERCISE_TIME_ESTIMATES
        assert "isolation" in EXERCISE_TIME_ESTIMATES
        assert "bodyweight" in EXERCISE_TIME_ESTIMATES

    def test_exercise_time_estimates_values(self):
        """Compound exercises should take longer than isolation."""
        assert EXERCISE_TIME_ESTIMATES["compound"] > EXERCISE_TIME_ESTIMATES["isolation"]
        assert EXERCISE_TIME_ESTIMATES["isolation"] > EXERCISE_TIME_ESTIMATES["bodyweight"]


class TestGetExerciseType:
    """Test get_exercise_type function."""

    def test_compound_lower_squat(self):
        """Squat should be classified as compound_lower."""
        assert get_exercise_type("Barbell Squat") == "compound_lower"
        assert get_exercise_type("goblet squat") == "compound_lower"
        assert get_exercise_type("Front Squat") == "compound_lower"

    def test_compound_lower_deadlift(self):
        """Deadlift variations should be compound_lower."""
        assert get_exercise_type("Deadlift") == "compound_lower"
        assert get_exercise_type("romanian deadlift") == "compound_lower"
        assert get_exercise_type("Sumo Deadlift") == "compound_lower"

    def test_compound_lower_leg_press(self):
        """Leg press should be compound_lower."""
        assert get_exercise_type("Leg Press") == "compound_lower"
        assert get_exercise_type("45 degree leg press") == "compound_lower"

    def test_compound_upper_bench(self):
        """Bench press should be compound_upper."""
        assert get_exercise_type("Bench Press") == "compound_upper"
        assert get_exercise_type("incline bench press") == "compound_upper"
        assert get_exercise_type("Dumbbell Bench Press") == "compound_upper"

    def test_compound_upper_overhead_press(self):
        """Overhead press should be compound_upper."""
        assert get_exercise_type("Overhead Press") == "compound_upper"
        assert get_exercise_type("standing overhead press") == "compound_upper"

    def test_compound_upper_row(self):
        """Row exercises should be compound_upper."""
        assert get_exercise_type("Barbell Row") == "compound_upper"
        assert get_exercise_type("Dumbbell Row") == "compound_upper"
        assert get_exercise_type("Cable Row") == "compound_upper"

    def test_compound_upper_pullup(self):
        """Pull-up should be compound_upper."""
        assert get_exercise_type("Pull-up") == "compound_upper"
        assert get_exercise_type("Weighted Pull-ups") == "compound_upper"

    def test_bodyweight_exercises(self):
        """Bodyweight exercises should be classified correctly."""
        assert get_exercise_type("Push-up") == "bodyweight"
        assert get_exercise_type("Diamond Push-ups") == "bodyweight"
        assert get_exercise_type("Dip") == "bodyweight"
        assert get_exercise_type("Tricep Dips") == "bodyweight"
        assert get_exercise_type("Plank") == "bodyweight"
        assert get_exercise_type("Side Plank") == "bodyweight"

    def test_isolation_exercises(self):
        """Isolation exercises should default to isolation type."""
        assert get_exercise_type("Bicep Curl") == "isolation"
        assert get_exercise_type("Lateral Raise") == "isolation"
        assert get_exercise_type("Leg Extension") == "isolation"
        assert get_exercise_type("Tricep Kickback") == "isolation"

    def test_case_insensitivity(self):
        """Exercise type detection should be case insensitive."""
        assert get_exercise_type("SQUAT") == "compound_lower"
        assert get_exercise_type("bench press") == "compound_upper"
        assert get_exercise_type("PUSH-UP") == "bodyweight"


class TestGetExercisePriority:
    """Test get_exercise_priority function."""

    def test_compound_exercises_highest_priority(self):
        """Compound exercises should have priority 100."""
        assert get_exercise_priority("Squat") == 100
        assert get_exercise_priority("Deadlift") == 100
        assert get_exercise_priority("Bench Press") == 100
        assert get_exercise_priority("Barbell Row") == 100
        assert get_exercise_priority("Overhead Press") == 100
        assert get_exercise_priority("Pull-up") == 100

    def test_secondary_exercises_medium_priority(self):
        """Secondary compound exercises should have priority 75."""
        assert get_exercise_priority("Lunges") == 75
        assert get_exercise_priority("Walking Lunge") == 75
        assert get_exercise_priority("Dip") == 75
        assert get_exercise_priority("Tricep Dips") == 75
        assert get_exercise_priority("Chin-up") == 75
        assert get_exercise_priority("Hip Thrust") == 75

    def test_isolation_exercises_lowest_priority(self):
        """Isolation exercises should have priority 50."""
        assert get_exercise_priority("Bicep Curl") == 50
        assert get_exercise_priority("Tricep Pushdown") == 50
        assert get_exercise_priority("Leg Extension") == 50
        assert get_exercise_priority("Calf Raise") == 50

    def test_unknown_exercises_default_priority(self):
        """Unknown exercises should default to priority 50."""
        assert get_exercise_priority("Some Random Exercise") == 50
        assert get_exercise_priority("") == 50

    def test_case_insensitivity(self):
        """Priority detection should be case insensitive."""
        assert get_exercise_priority("SQUAT") == 100
        assert get_exercise_priority("Bench Press") == 100
        assert get_exercise_priority("lunge") == 75


class TestExerciseSubstitutes:
    """Test exercise substitution mappings."""

    def test_chest_substitutes(self):
        """Chest exercises should have valid substitutes."""
        bench_subs = EXERCISE_SUBSTITUTES["bench press"]
        assert "dumbbell press" in bench_subs
        assert "push-ups" in bench_subs

    def test_back_substitutes(self):
        """Back exercises should have valid substitutes."""
        pullup_subs = EXERCISE_SUBSTITUTES["pull-ups"]
        assert "lat pulldown" in pullup_subs

        row_subs = EXERCISE_SUBSTITUTES["barbell row"]
        assert "dumbbell row" in row_subs

    def test_leg_substitutes(self):
        """Leg exercises should have valid substitutes."""
        squat_subs = EXERCISE_SUBSTITUTES["squat"]
        assert "leg press" in squat_subs
        assert "goblet squat" in squat_subs

    def test_substitutes_dont_contain_self(self):
        """No exercise should list itself as a substitute."""
        for exercise, substitutes in EXERCISE_SUBSTITUTES.items():
            assert exercise not in substitutes, f"{exercise} lists itself as substitute"
