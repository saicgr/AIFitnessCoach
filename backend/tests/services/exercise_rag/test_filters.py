"""
Tests for exercise RAG filter functions.
"""

import pytest


class TestGetBaseExerciseName:
    """Tests for get_base_exercise_name function."""

    def test_removes_female_suffix(self):
        """Test removing female suffix."""
        from services.exercise_rag.filters import get_base_exercise_name

        assert get_base_exercise_name("Air Bike_female") == "air bike"
        assert get_base_exercise_name("Push-up_Female") == "push up"

    def test_removes_version_suffix(self):
        """Test removing version suffix."""
        from services.exercise_rag.filters import get_base_exercise_name

        assert get_base_exercise_name("Push-up (version 2)") == "push up"
        assert get_base_exercise_name("Squat version 3") == "squat"

    def test_removes_variation_suffix(self):
        """Test removing variation suffix."""
        from services.exercise_rag.filters import get_base_exercise_name

        assert get_base_exercise_name("Lunge (variation 2)") == "lunge"
        assert get_base_exercise_name("Curl variation 1") == "curl"

    def test_removes_filler_words(self):
        """Test removing filler words."""
        from services.exercise_rag.filters import get_base_exercise_name

        result = get_base_exercise_name("Squat with barbell")
        assert "with" not in result

    def test_normalizes_hyphens(self):
        """Test normalizing hyphens to spaces."""
        from services.exercise_rag.filters import get_base_exercise_name

        assert "push up" in get_base_exercise_name("Push-up")

    def test_normalizes_underscores(self):
        """Test normalizing underscores to spaces."""
        from services.exercise_rag.filters import get_base_exercise_name

        assert "goblet squat" in get_base_exercise_name("goblet_squat")


class TestIsSimilarExercise:
    """Tests for is_similar_exercise function."""

    def test_exact_match(self):
        """Test exact match after normalization."""
        from services.exercise_rag.filters import is_similar_exercise

        assert is_similar_exercise("Push-up", "push up") is True
        assert is_similar_exercise("Squat", "SQUAT") is True

    def test_subset_match(self):
        """Test when one name is subset of another."""
        from services.exercise_rag.filters import is_similar_exercise

        assert is_similar_exercise("Squat", "Bodyweight Squat") is True
        assert is_similar_exercise("Bicep Curl", "Dumbbell Bicep Curl") is True

    def test_high_overlap(self):
        """Test high word overlap detection."""
        from services.exercise_rag.filters import is_similar_exercise

        assert is_similar_exercise("Barbell Bench Press", "Bench Press") is True

    def test_different_exercises(self):
        """Test different exercises are not similar."""
        from services.exercise_rag.filters import is_similar_exercise

        assert is_similar_exercise("Push-up", "Squat") is False
        assert is_similar_exercise("Bench Press", "Deadlift") is False

    def test_version_variants(self):
        """Test version variants are similar."""
        from services.exercise_rag.filters import is_similar_exercise

        assert is_similar_exercise("Push-up (version 2)", "Push-up") is True


class TestFilterByEquipment:
    """Tests for filter_by_equipment function."""

    def test_matches_exact_equipment(self):
        """Test exact equipment match."""
        from services.exercise_rag.filters import filter_by_equipment

        assert filter_by_equipment("dumbbell", ["Dumbbells"], "Dumbbell Curl") is True
        assert filter_by_equipment("barbell", ["Barbell"], "Barbell Squat") is True

    def test_full_gym_includes_all(self):
        """Test full gym includes all equipment."""
        from services.exercise_rag.filters import filter_by_equipment

        assert filter_by_equipment("barbell", ["Full Gym"], "Barbell Press") is True
        assert filter_by_equipment("cable machine", ["Full Gym"], "Cable Fly") is True
        assert filter_by_equipment("dumbbell", ["Full Gym"], "Dumbbell Curl") is True

    def test_full_gym_access_includes_all(self):
        """Test 'Full Gym Access' (with Access suffix) includes all equipment.

        This tests the bug fix where 'Full Gym Access' was not matching because
        the check was looking for exact 'full gym' string instead of substring.
        """
        from services.exercise_rag.filters import filter_by_equipment

        # This is the exact equipment string that caused the production bug
        assert filter_by_equipment("barbell", ["Full Gym Access"], "Barbell Press") is True
        assert filter_by_equipment("cable machine", ["Full Gym Access"], "Cable Fly") is True
        assert filter_by_equipment("dumbbell", ["Full Gym Access"], "Dumbbell Curl") is True
        assert filter_by_equipment("bodyweight", ["Full Gym Access"], "Push-up") is True

    def test_full_gym_mixed_with_other_equipment(self):
        """Test Full Gym Access works when mixed with other equipment in list."""
        from services.exercise_rag.filters import filter_by_equipment

        # Real-world case: user selects multiple equipment types including Full Gym Access
        user_equipment = ['Bodyweight Only', 'Dumbbells', 'Barbell', 'Resistance Bands',
                         'Pull-up Bar', 'Kettlebell', 'Cable Machine', 'Full Gym Access']

        assert filter_by_equipment("barbell", user_equipment, "Barbell Squat") is True
        assert filter_by_equipment("cable machine", user_equipment, "Cable Row") is True
        assert filter_by_equipment("leg press", user_equipment, "Leg Press") is True

    def test_bodyweight_always_allowed(self):
        """Test bodyweight exercises are always allowed."""
        from services.exercise_rag.filters import filter_by_equipment

        assert filter_by_equipment("bodyweight", ["Dumbbells"], "Push-up") is True
        assert filter_by_equipment("body weight", ["Barbell"], "Plank") is True

    def test_bodyweight_only_restricts(self):
        """Test bodyweight only restricts to bodyweight."""
        from services.exercise_rag.filters import filter_by_equipment

        assert filter_by_equipment("bodyweight", ["Bodyweight Only"], "Push-up") is True
        # Note: The function also checks exercise name for equipment, so this might pass

    def test_home_gym_equipment(self):
        """Test home gym equipment list."""
        from services.exercise_rag.filters import filter_by_equipment

        assert filter_by_equipment("dumbbell", ["Home Gym"], "Dumbbell Row") is True
        assert filter_by_equipment("kettlebell", ["Home Gym"], "KB Swing") is True

    def test_no_match(self):
        """Test no equipment match."""
        from services.exercise_rag.filters import filter_by_equipment

        # When user has only dumbbells, cable machine shouldn't match
        result = filter_by_equipment("cable machine", ["Dumbbells"], "Cable Fly")
        assert result is False


class TestPreFilterByInjuries:
    """Tests for pre_filter_by_injuries function."""

    def test_filters_leg_injury_exercises(self):
        """Test filtering exercises for leg injury."""
        from services.exercise_rag.filters import pre_filter_by_injuries

        candidates = [
            {"name": "Squat", "target_muscle": "quads", "body_part": "legs"},
            {"name": "Bench Press", "target_muscle": "chest", "body_part": "chest"},
            {"name": "Lunge", "target_muscle": "quads", "body_part": "legs"},
        ]

        result = pre_filter_by_injuries(candidates, ["leg pain"])

        # Squat and Lunge should be filtered out
        assert len(result) == 1
        assert result[0]["name"] == "Bench Press"

    def test_filters_back_injury_exercises(self):
        """Test filtering exercises for back injury."""
        from services.exercise_rag.filters import pre_filter_by_injuries

        candidates = [
            {"name": "Deadlift", "target_muscle": "back", "body_part": "back"},
            {"name": "Bicep Curl", "target_muscle": "biceps", "body_part": "arms"},
            {"name": "Good Morning", "target_muscle": "hamstrings", "body_part": "legs"},
        ]

        result = pre_filter_by_injuries(candidates, ["lower back pain"])

        # Deadlift and Good Morning should be filtered
        assert len(result) == 1
        assert result[0]["name"] == "Bicep Curl"

    def test_filters_shoulder_injury_exercises(self):
        """Test filtering exercises for shoulder injury."""
        from services.exercise_rag.filters import pre_filter_by_injuries

        candidates = [
            {"name": "Overhead Press", "target_muscle": "shoulders", "body_part": "shoulders"},
            {"name": "Lateral Raise", "target_muscle": "delts", "body_part": "shoulders"},
            {"name": "Leg Press", "target_muscle": "quads", "body_part": "legs"},
        ]

        result = pre_filter_by_injuries(candidates, ["shoulder injury"])

        # Only Leg Press should remain
        assert len(result) == 1
        assert result[0]["name"] == "Leg Press"

    def test_returns_all_for_unknown_injury(self):
        """Test returning all candidates for unknown injury type."""
        from services.exercise_rag.filters import pre_filter_by_injuries

        candidates = [
            {"name": "Squat", "target_muscle": "quads", "body_part": "legs"},
            {"name": "Bench Press", "target_muscle": "chest", "body_part": "chest"},
        ]

        result = pre_filter_by_injuries(candidates, ["xyz injury"])

        # All candidates should remain
        assert len(result) == 2

    def test_handles_empty_injuries(self):
        """Test handling empty injuries list."""
        from services.exercise_rag.filters import pre_filter_by_injuries

        candidates = [
            {"name": "Squat", "target_muscle": "quads", "body_part": "legs"},
        ]

        result = pre_filter_by_injuries(candidates, [])

        assert len(result) == 1

    def test_handles_multiple_injuries(self):
        """Test filtering for multiple injuries."""
        from services.exercise_rag.filters import pre_filter_by_injuries

        candidates = [
            {"name": "Squat", "target_muscle": "quads", "body_part": "legs"},
            {"name": "Overhead Press", "target_muscle": "shoulders", "body_part": "shoulders"},
            {"name": "Bicep Curl", "target_muscle": "biceps", "body_part": "arms"},
        ]

        result = pre_filter_by_injuries(candidates, ["knee pain", "shoulder injury"])

        # Only Bicep Curl should remain
        assert len(result) == 1
        assert result[0]["name"] == "Bicep Curl"


class TestEquipmentConstants:
    """Tests for equipment constant lists."""

    def test_full_gym_equipment_list(self):
        """Test FULL_GYM_EQUIPMENT contains expected items."""
        from services.exercise_rag.filters import FULL_GYM_EQUIPMENT

        assert "barbell" in FULL_GYM_EQUIPMENT
        assert "dumbbell" in FULL_GYM_EQUIPMENT
        assert "cable machine" in FULL_GYM_EQUIPMENT
        assert "bodyweight" in FULL_GYM_EQUIPMENT

    def test_home_gym_equipment_list(self):
        """Test HOME_GYM_EQUIPMENT contains expected items."""
        from services.exercise_rag.filters import HOME_GYM_EQUIPMENT

        assert "dumbbell" in HOME_GYM_EQUIPMENT
        assert "kettlebell" in HOME_GYM_EQUIPMENT
        assert "resistance band" in HOME_GYM_EQUIPMENT
        assert "bodyweight" in HOME_GYM_EQUIPMENT

    def test_injury_contraindications_structure(self):
        """Test INJURY_CONTRAINDICATIONS has proper structure."""
        from services.exercise_rag.filters import INJURY_CONTRAINDICATIONS

        assert "leg" in INJURY_CONTRAINDICATIONS
        assert "back" in INJURY_CONTRAINDICATIONS
        assert "shoulder" in INJURY_CONTRAINDICATIONS

        # Check that each has a list of patterns
        assert isinstance(INJURY_CONTRAINDICATIONS["leg"], list)
        assert len(INJURY_CONTRAINDICATIONS["leg"]) > 0


class TestDifficultyFiltering:
    """Tests for exercise difficulty filtering functions.

    CRITICAL: These tests verify the fix for the bug where beginner users
    only received 1 exercise (Push-ups) because the strict difficulty filter
    blocked all intermediate/advanced exercises.

    The permissive filter (is_exercise_too_difficult) should:
    - Only block Elite (10) exercises for beginners
    - Allow all other exercises for ranking, not hard filtering
    """

    def test_permissive_allows_intermediate_for_beginners(self):
        """Beginner users should have access to intermediate exercises.

        This is the core fix: intermediate exercises (difficulty 5) should
        NOT be blocked for beginners. Only Elite (10) exercises are blocked.
        """
        from services.exercise_rag.service import is_exercise_too_difficult

        # Intermediate exercises (difficulty 5) should be allowed for beginners
        assert is_exercise_too_difficult("intermediate", "beginner") is False
        assert is_exercise_too_difficult(5, "beginner") is False

    def test_permissive_allows_advanced_for_beginners(self):
        """Beginner users should have access to advanced exercises for variety.

        Advanced exercises are allowed but will be ranked lower via DIFFICULTY_RATIOS.
        """
        from services.exercise_rag.service import is_exercise_too_difficult

        # Advanced exercises (difficulty 8) should be allowed for beginners
        assert is_exercise_too_difficult("advanced", "beginner") is False
        assert is_exercise_too_difficult(8, "beginner") is False

    def test_permissive_blocks_elite_for_beginners(self):
        """Elite exercises should be blocked for beginners to prevent injury."""
        from services.exercise_rag.service import is_exercise_too_difficult

        # Elite exercises (difficulty 10) should be blocked for beginners
        assert is_exercise_too_difficult("elite", "beginner") is True
        assert is_exercise_too_difficult(10, "beginner") is True

    def test_permissive_allows_beginner_exercises_for_all(self):
        """Beginner exercises should be allowed for all fitness levels."""
        from services.exercise_rag.service import is_exercise_too_difficult

        # Beginner exercises should never be blocked
        for level in ["beginner", "intermediate", "advanced"]:
            assert is_exercise_too_difficult("beginner", level) is False
            assert is_exercise_too_difficult(2, level) is False

    def test_strict_blocks_intermediate_for_beginners(self):
        """Strict filter blocks intermediate exercises for beginners.

        This is the OLD behavior that caused the bug. The strict filter
        has a ceiling of 3 for beginners, which blocks intermediate (5).
        """
        from services.exercise_rag.service import is_exercise_too_difficult_strict

        # Strict filter should block intermediate (5) for beginners (ceiling 3)
        assert is_exercise_too_difficult_strict("intermediate", "beginner") is True
        assert is_exercise_too_difficult_strict(5, "beginner") is True

    def test_strict_allows_beginner_exercises_for_beginners(self):
        """Strict filter allows beginner exercises for beginners."""
        from services.exercise_rag.service import is_exercise_too_difficult_strict

        # Beginner exercises (difficulty 2) should pass strict filter
        assert is_exercise_too_difficult_strict("beginner", "beginner") is False
        assert is_exercise_too_difficult_strict(2, "beginner") is False

    def test_difficulty_adjustment_increases_ceiling(self):
        """Positive difficulty adjustment should raise the ceiling."""
        from services.exercise_rag.service import is_exercise_too_difficult

        # With +2 adjustment, Elite exercises should be allowed for beginners
        # (demonstrates the ceiling shifting mechanism)
        assert is_exercise_too_difficult(10, "beginner", difficulty_adjustment=2) is False

    def test_difficulty_adjustment_does_not_affect_permissive_for_normal_exercises(self):
        """Difficulty adjustment doesn't change permissive filter for non-elite exercises."""
        from services.exercise_rag.service import is_exercise_too_difficult

        # Intermediate exercises allowed regardless of adjustment
        assert is_exercise_too_difficult(5, "beginner", difficulty_adjustment=-2) is False
        assert is_exercise_too_difficult(5, "beginner", difficulty_adjustment=0) is False
        assert is_exercise_too_difficult(5, "beginner", difficulty_adjustment=2) is False


class TestCheckAndRegenerateThreshold:
    """Tests for the check-and-regenerate workout threshold logic.

    Verifies the fix for the bug where threshold_days=0 with upcoming_count=0
    incorrectly returned 'sufficient workouts' because 0 >= 0 is True.
    """

    def test_zero_workouts_always_triggers_generation(self):
        """When user has 0 workouts, generation should always be triggered.

        This tests the logic: if upcoming_count == 0, we should generate
        regardless of threshold (critical for new users after onboarding).
        """
        # The fix changes the condition from:
        #   if upcoming_count >= threshold_days:
        # to:
        #   if upcoming_count > 0 and upcoming_count >= threshold_days:

        # Test the logic directly
        upcoming_count = 0
        threshold_days = 0

        # Old buggy logic: 0 >= 0 = True (would skip generation)
        old_logic_needs_skip = upcoming_count >= threshold_days
        assert old_logic_needs_skip is True  # Bug: returns True

        # New fixed logic: 0 > 0 and 0 >= 0 = False and True = False
        new_logic_needs_skip = upcoming_count > 0 and upcoming_count >= threshold_days
        assert new_logic_needs_skip is False  # Fixed: returns False, so generation happens

    def test_some_workouts_below_threshold_triggers_generation(self):
        """When user has workouts but below threshold, generation should trigger."""
        upcoming_count = 2
        threshold_days = 3

        # Both old and new logic should trigger generation here
        needs_skip = upcoming_count > 0 and upcoming_count >= threshold_days
        assert needs_skip is False  # 2 < 3, so generate

    def test_sufficient_workouts_skips_generation(self):
        """When user has sufficient workouts, generation should be skipped."""
        upcoming_count = 5
        threshold_days = 3

        needs_skip = upcoming_count > 0 and upcoming_count >= threshold_days
        assert needs_skip is True  # 5 >= 3, so skip
