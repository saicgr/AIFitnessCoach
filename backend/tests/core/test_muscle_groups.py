"""
Tests for core/muscle_groups.py module.

Tests muscle group mappings, volume targets, and recovery status.
"""
import pytest

from core.muscle_groups import (
    WEEKLY_SET_TARGETS,
    MUSCLE_TO_EXERCISES,
    EXERCISE_TO_MUSCLES,
    get_muscle_groups,
    get_target_sets,
    get_recovery_status,
)


class TestMuscleGroupConstants:
    """Test muscle group constants are properly defined."""

    def test_weekly_set_targets_all_muscles(self):
        """All major muscle groups should have set targets."""
        expected_muscles = [
            "chest", "back", "shoulders", "biceps", "triceps",
            "quadriceps", "hamstrings", "glutes", "calves", "core"
        ]
        for muscle in expected_muscles:
            assert muscle in WEEKLY_SET_TARGETS, f"{muscle} missing from WEEKLY_SET_TARGETS"

    def test_weekly_set_targets_are_tuples(self):
        """Each target should be a (min, max) tuple."""
        for muscle, target in WEEKLY_SET_TARGETS.items():
            assert isinstance(target, tuple), f"{muscle} target is not a tuple"
            assert len(target) == 2, f"{muscle} target should have 2 values"
            assert target[0] < target[1], f"{muscle} min should be less than max"

    def test_weekly_set_targets_reasonable_ranges(self):
        """Set targets should be within reasonable ranges."""
        for muscle, (min_sets, max_sets) in WEEKLY_SET_TARGETS.items():
            assert min_sets >= 4, f"{muscle} min sets too low"
            assert max_sets <= 25, f"{muscle} max sets too high"
            assert min_sets >= 0, f"{muscle} min sets can't be negative"

    def test_muscle_to_exercises_all_muscles(self):
        """All muscle groups should have associated exercises."""
        for muscle in WEEKLY_SET_TARGETS.keys():
            assert muscle in MUSCLE_TO_EXERCISES, f"{muscle} missing from MUSCLE_TO_EXERCISES"
            assert len(MUSCLE_TO_EXERCISES[muscle]) > 0, f"{muscle} has no exercises"

    def test_exercise_to_muscles_defined(self):
        """Exercise to muscle mapping should be defined."""
        assert len(EXERCISE_TO_MUSCLES) > 0
        for exercise, muscles in EXERCISE_TO_MUSCLES.items():
            assert len(muscles) > 0, f"{exercise} has no muscles mapped"


class TestMuscleToExercises:
    """Test muscle-to-exercise mappings."""

    def test_chest_exercises(self):
        """Chest should have appropriate exercises."""
        chest_exercises = MUSCLE_TO_EXERCISES["chest"]
        assert "bench press" in chest_exercises
        assert "push-ups" in chest_exercises

    def test_back_exercises(self):
        """Back should have appropriate exercises."""
        back_exercises = MUSCLE_TO_EXERCISES["back"]
        assert "barbell row" in back_exercises or "pull-ups" in back_exercises

    def test_leg_exercises(self):
        """Leg muscles should have appropriate exercises."""
        quad_exercises = MUSCLE_TO_EXERCISES["quadriceps"]
        assert "squat" in quad_exercises or "leg press" in quad_exercises

        ham_exercises = MUSCLE_TO_EXERCISES["hamstrings"]
        assert "romanian deadlift" in ham_exercises or "leg curl" in ham_exercises


class TestExerciseToMuscles:
    """Test exercise-to-muscle mappings."""

    def test_bench_works_multiple_muscles(self):
        """Bench press should work chest, triceps, and shoulders."""
        bench_muscles = EXERCISE_TO_MUSCLES.get("bench", [])
        assert "chest" in bench_muscles
        assert "triceps" in bench_muscles

    def test_row_works_back_and_biceps(self):
        """Rows should work back and biceps."""
        row_muscles = EXERCISE_TO_MUSCLES.get("row", [])
        assert "back" in row_muscles
        assert "biceps" in row_muscles

    def test_squat_works_legs(self):
        """Squat should work quadriceps and glutes."""
        squat_muscles = EXERCISE_TO_MUSCLES.get("squat", [])
        assert "quadriceps" in squat_muscles
        assert "glutes" in squat_muscles


class TestGetMuscleGroups:
    """Test get_muscle_groups function."""

    def test_bench_press(self):
        """Bench press should return chest, triceps, shoulders."""
        muscles = get_muscle_groups("Bench Press")
        assert "chest" in muscles
        assert "triceps" in muscles

    def test_push_up(self):
        """Push-up should work similar muscles to bench."""
        muscles = get_muscle_groups("Push-up")
        assert "chest" in muscles

    def test_barbell_row(self):
        """Barbell row should work back and biceps."""
        muscles = get_muscle_groups("Barbell Row")
        assert "back" in muscles
        assert "biceps" in muscles

    def test_squat(self):
        """Squat should work quads and glutes."""
        muscles = get_muscle_groups("Barbell Squat")
        assert "quadriceps" in muscles
        assert "glutes" in muscles

    def test_deadlift(self):
        """Deadlift should work hamstrings, glutes, back."""
        muscles = get_muscle_groups("Deadlift")
        assert "hamstrings" in muscles
        assert "glutes" in muscles
        assert "back" in muscles

    def test_curl(self):
        """Curls should work biceps."""
        muscles = get_muscle_groups("Bicep Curl")
        assert "biceps" in muscles

    def test_tricep_exercise(self):
        """Tricep exercises should work triceps."""
        muscles = get_muscle_groups("Tricep Pushdown")
        assert "triceps" in muscles

    def test_calf_raise(self):
        """Calf raise should work calves."""
        muscles = get_muscle_groups("Calf Raise")
        assert "calves" in muscles

    def test_plank(self):
        """Plank should work core."""
        muscles = get_muscle_groups("Plank")
        assert "core" in muscles

    def test_unknown_exercise(self):
        """Unknown exercises should return unknown."""
        muscles = get_muscle_groups("Some Exotic Exercise")
        assert "unknown" in muscles

    def test_case_insensitivity(self):
        """Function should be case insensitive."""
        muscles1 = get_muscle_groups("bench press")
        muscles2 = get_muscle_groups("BENCH PRESS")
        muscles3 = get_muscle_groups("Bench Press")
        assert muscles1 == muscles2 == muscles3


class TestGetTargetSets:
    """Test get_target_sets function."""

    def test_chest_target(self):
        """Chest should have target sets in expected range."""
        target = get_target_sets("chest")
        assert 10 <= target <= 20

    def test_back_target(self):
        """Back should have target sets in expected range."""
        target = get_target_sets("back")
        assert 10 <= target <= 20

    def test_arms_target(self):
        """Arms should have lower target than chest/back."""
        bicep_target = get_target_sets("biceps")
        tricep_target = get_target_sets("triceps")
        assert bicep_target < get_target_sets("chest")
        assert tricep_target < get_target_sets("back")

    def test_unknown_muscle_default(self):
        """Unknown muscle should return default target."""
        target = get_target_sets("unknown_muscle")
        assert target > 0
        assert 8 <= target <= 16

    def test_target_is_integer(self):
        """Target should be an integer."""
        for muscle in WEEKLY_SET_TARGETS.keys():
            target = get_target_sets(muscle)
            assert isinstance(target, int)

    def test_target_is_average_of_range(self):
        """Target should be the average of min and max."""
        for muscle, (min_sets, max_sets) in WEEKLY_SET_TARGETS.items():
            expected = (min_sets + max_sets) // 2
            assert get_target_sets(muscle) == expected


class TestGetRecoveryStatus:
    """Test get_recovery_status function."""

    def test_recovered_within_range(self):
        """Sets within target range should be recovered."""
        # Chest target is (10, 20), so 15 should be recovered
        status = get_recovery_status("chest", 15)
        assert status == "recovered"

    def test_overtrained_above_max(self):
        """Sets significantly above max should be overtrained."""
        # Chest max is 20, so 25+ (20 * 1.2 = 24) should be overtrained
        status = get_recovery_status("chest", 25)
        assert status == "overtrained"

    def test_undertrained_below_min(self):
        """Sets significantly below min should be undertrained."""
        # Chest min is 10, so 7 or less (10 * 0.8 = 8) should be undertrained
        status = get_recovery_status("chest", 7)
        assert status == "undertrained"

    def test_edge_case_at_min(self):
        """Sets exactly at min should be recovered."""
        status = get_recovery_status("chest", 10)
        assert status == "recovered"

    def test_edge_case_at_max(self):
        """Sets exactly at max should be recovered."""
        status = get_recovery_status("chest", 20)
        assert status == "recovered"

    def test_all_muscles_have_valid_status(self):
        """All muscles should return valid status for various volumes."""
        for muscle in WEEKLY_SET_TARGETS.keys():
            for sets in [0, 5, 10, 15, 20, 25, 30]:
                status = get_recovery_status(muscle, sets)
                assert status in ["recovered", "overtrained", "undertrained"]

    def test_unknown_muscle_uses_default(self):
        """Unknown muscles should use default range."""
        status = get_recovery_status("unknown_muscle", 12)
        assert status in ["recovered", "overtrained", "undertrained"]
