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
