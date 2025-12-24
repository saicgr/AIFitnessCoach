"""
Tests for Exercise Library Service.

Tests:
- Getting exercises by body part
- Getting exercises by muscle
- Getting exercises for workout
- Exercise search
- Equipment filtering

Run with: pytest backend/tests/test_exercise_library_service.py -v
"""

import pytest
from unittest.mock import MagicMock, patch

from services.exercise_library_service import (
    ExerciseLibraryService, get_exercise_library_service
)


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def mock_supabase():
    """Create mock Supabase client."""
    mock = MagicMock()
    mock.client = MagicMock()
    return mock


@pytest.fixture
def exercise_service(mock_supabase):
    """Create exercise library service with mocked Supabase."""
    with patch("services.exercise_library_service.get_supabase") as mock_get:
        mock_get.return_value = mock_supabase
        service = ExerciseLibraryService()
        yield service


@pytest.fixture
def sample_exercises():
    """Sample exercises from database."""
    return [
        {
            "id": 1,
            "exercise_name": "Barbell Bench Press",
            "body_part": "chest",
            "target_muscle": "pectoralis major",
            "equipment": "barbell",
            "instructions": "Lie on bench, press barbell up",
            "gif_url": "https://example.com/bench.gif",
        },
        {
            "id": 2,
            "exercise_name": "Dumbbell Fly",
            "body_part": "chest",
            "target_muscle": "pectoralis major",
            "equipment": "dumbbells",
            "instructions": "Lie on bench, open arms wide",
            "gif_url": "https://example.com/fly.gif",
        },
        {
            "id": 3,
            "exercise_name": "Push-up",
            "body_part": "chest",
            "target_muscle": "pectoralis major",
            "equipment": "body weight",
            "instructions": "Get in plank position, lower body",
            "gif_url": "https://example.com/pushup.gif",
        },
        {
            "id": 4,
            "exercise_name": "Barbell Squat",
            "body_part": "upper legs",
            "target_muscle": "quadriceps",
            "equipment": "barbell",
            "instructions": "Place barbell on back, squat down",
            "gif_url": "https://example.com/squat.gif",
        },
    ]


# ============================================================
# GET EXERCISES BY BODY PART TESTS
# ============================================================

class TestGetExercisesByBodyPart:
    """Test getting exercises by body part."""

    def test_get_exercises_by_body_part_success(self, exercise_service, mock_supabase, sample_exercises):
        """Test successfully getting exercises by body part."""
        mock_supabase.client.table.return_value.select.return_value.ilike.return_value.limit.return_value.execute.return_value = MagicMock(
            data=[e for e in sample_exercises if e["body_part"] == "chest"]
        )

        exercises = exercise_service.get_exercises_by_body_part("chest")

        assert len(exercises) == 3
        assert all(ex["body_part"] == "chest" for ex in exercises)

    def test_get_exercises_by_body_part_empty(self, exercise_service, mock_supabase):
        """Test getting exercises for body part with no results."""
        mock_supabase.client.table.return_value.select.return_value.ilike.return_value.limit.return_value.execute.return_value = MagicMock(
            data=[]
        )

        exercises = exercise_service.get_exercises_by_body_part("nonexistent")

        assert exercises == []

    def test_get_exercises_by_body_part_with_equipment_filter(self, exercise_service, mock_supabase, sample_exercises):
        """Test filtering exercises by equipment."""
        chest_exercises = [e for e in sample_exercises if e["body_part"] == "chest"]
        mock_supabase.client.table.return_value.select.return_value.ilike.return_value.limit.return_value.execute.return_value = MagicMock(
            data=chest_exercises
        )

        exercises = exercise_service.get_exercises_by_body_part(
            "chest",
            equipment=["barbell"]
        )

        # Should include barbell exercises and bodyweight
        for ex in exercises:
            eq = ex.get("equipment", "").lower()
            assert any(e in eq for e in ["barbell", "body weight", "bodyweight", "none"])

    def test_get_exercises_by_body_part_with_limit(self, exercise_service, mock_supabase, sample_exercises):
        """Test respecting limit parameter."""
        chest_exercises = [e for e in sample_exercises if e["body_part"] == "chest"]
        mock_supabase.client.table.return_value.select.return_value.ilike.return_value.limit.return_value.execute.return_value = MagicMock(
            data=chest_exercises
        )

        exercise_service.get_exercises_by_body_part("chest", limit=5)

        # Verify limit was called with correct value
        mock_supabase.client.table.return_value.select.return_value.ilike.return_value.limit.assert_called_with(5)

    def test_get_exercises_by_body_part_error_handling(self, exercise_service, mock_supabase):
        """Test error handling returns empty list."""
        mock_supabase.client.table.side_effect = Exception("Database error")

        exercises = exercise_service.get_exercises_by_body_part("chest")

        assert exercises == []


# ============================================================
# GET EXERCISES BY MUSCLE TESTS
# ============================================================

class TestGetExercisesByMuscle:
    """Test getting exercises by target muscle."""

    def test_get_exercises_by_muscle_success(self, exercise_service, mock_supabase, sample_exercises):
        """Test getting exercises by target muscle."""
        pec_exercises = [e for e in sample_exercises if "pectoralis" in e["target_muscle"]]
        mock_supabase.client.table.return_value.select.return_value.ilike.return_value.limit.return_value.execute.return_value = MagicMock(
            data=pec_exercises
        )

        exercises = exercise_service.get_exercises_by_muscle("pectoralis")

        assert len(exercises) == 3

    def test_get_exercises_by_muscle_with_equipment(self, exercise_service, mock_supabase, sample_exercises):
        """Test filtering by muscle and equipment."""
        pec_exercises = [e for e in sample_exercises if "pectoralis" in e["target_muscle"]]
        mock_supabase.client.table.return_value.select.return_value.ilike.return_value.limit.return_value.execute.return_value = MagicMock(
            data=pec_exercises
        )

        exercises = exercise_service.get_exercises_by_muscle(
            "pectoralis",
            equipment=["dumbbells"]
        )

        # Should filter to dumbbell and bodyweight
        for ex in exercises:
            eq = ex.get("equipment", "").lower()
            assert any(e in eq for e in ["dumbbell", "body weight", "bodyweight", "none"])

    def test_get_exercises_by_muscle_empty(self, exercise_service, mock_supabase):
        """Test getting exercises for muscle with no results."""
        mock_supabase.client.table.return_value.select.return_value.ilike.return_value.limit.return_value.execute.return_value = MagicMock(
            data=[]
        )

        exercises = exercise_service.get_exercises_by_muscle("nonexistent_muscle")

        assert exercises == []

    def test_get_exercises_by_muscle_error_handling(self, exercise_service, mock_supabase):
        """Test error handling."""
        mock_supabase.client.table.side_effect = Exception("Database error")

        exercises = exercise_service.get_exercises_by_muscle("quadriceps")

        assert exercises == []


# ============================================================
# GET EXERCISES FOR WORKOUT TESTS
# ============================================================

class TestGetExercisesForWorkout:
    """Test getting exercises for a workout."""

    @patch.object(ExerciseLibraryService, 'get_exercises_by_body_part')
    def test_get_exercises_for_workout_chest(self, mock_get_by_body_part, exercise_service):
        """Test getting exercises for chest workout."""
        mock_get_by_body_part.return_value = [
            {"exercise_name": "Bench Press", "body_part": "chest", "target_muscle": "pectoralis", "equipment": "barbell"},
            {"exercise_name": "Dumbbell Fly", "body_part": "chest", "target_muscle": "pectoralis", "equipment": "dumbbells"},
        ]

        exercises = exercise_service.get_exercises_for_workout(
            focus_area="chest",
            equipment=["barbell", "dumbbells"],
            count=2,
            fitness_level="intermediate"
        )

        assert len(exercises) <= 2
        for ex in exercises:
            assert "name" in ex
            assert "sets" in ex
            assert "reps" in ex
            assert "rest_seconds" in ex

    @patch.object(ExerciseLibraryService, 'get_exercises_by_body_part')
    def test_get_exercises_for_workout_beginner_params(self, mock_get_by_body_part, exercise_service):
        """Test beginner fitness level gets appropriate sets/reps."""
        mock_get_by_body_part.return_value = [
            {"exercise_name": "Squat", "body_part": "upper legs", "target_muscle": "quadriceps", "equipment": "barbell"},
        ]

        exercises = exercise_service.get_exercises_for_workout(
            focus_area="legs",
            equipment=["barbell"],
            count=1,
            fitness_level="beginner"
        )

        assert exercises[0]["sets"] == 2
        assert exercises[0]["reps"] == 10

    @patch.object(ExerciseLibraryService, 'get_exercises_by_body_part')
    def test_get_exercises_for_workout_advanced_params(self, mock_get_by_body_part, exercise_service):
        """Test advanced fitness level gets appropriate sets/reps."""
        mock_get_by_body_part.return_value = [
            {"exercise_name": "Squat", "body_part": "upper legs", "target_muscle": "quadriceps", "equipment": "barbell"},
        ]

        exercises = exercise_service.get_exercises_for_workout(
            focus_area="legs",
            equipment=["barbell"],
            count=1,
            fitness_level="advanced"
        )

        assert exercises[0]["sets"] == 4
        assert exercises[0]["reps"] == 12
        assert exercises[0]["rest_seconds"] == 45

    @patch.object(ExerciseLibraryService, 'get_exercises_by_body_part')
    def test_get_exercises_for_workout_full_body(self, mock_get_by_body_part, exercise_service):
        """Test full body workout gets exercises from multiple body parts."""
        mock_get_by_body_part.return_value = [
            {"exercise_name": "Exercise 1", "body_part": "chest", "target_muscle": "pecs", "equipment": "barbell"},
        ]

        exercise_service.get_exercises_for_workout(
            focus_area="full_body",
            equipment=["barbell"],
            count=6
        )

        # Should have called get_exercises_by_body_part multiple times
        assert mock_get_by_body_part.call_count >= 3

    @patch.object(ExerciseLibraryService, 'get_exercises_by_body_part')
    def test_get_exercises_for_workout_no_duplicates(self, mock_get_by_body_part, exercise_service):
        """Test no duplicate exercises in result."""
        # Return same exercises for different body parts
        mock_get_by_body_part.return_value = [
            {"exercise_name": "Dip", "body_part": "chest", "target_muscle": "pecs", "equipment": "body weight"},
            {"exercise_name": "Dip", "body_part": "chest", "target_muscle": "pecs", "equipment": "body weight"},
        ]

        exercises = exercise_service.get_exercises_for_workout(
            focus_area="chest",
            equipment=[],
            count=5
        )

        names = [ex["name"] for ex in exercises]
        assert len(names) == len(set(names))

    @patch.object(ExerciseLibraryService, 'get_exercises_by_body_part')
    def test_get_exercises_for_workout_formats_correctly(self, mock_get_by_body_part, exercise_service):
        """Test exercises are formatted correctly for workout."""
        mock_get_by_body_part.return_value = [
            {
                "id": 1,
                "exercise_name": "Bench Press",
                "body_part": "chest",
                "target_muscle": "pectoralis major",
                "equipment": "barbell",
                "instructions": "Press the bar",
                "gif_url": "https://example.com/bench.gif",
                "image_s3_path": "/images/bench.jpg",
                "video_s3_path": "/videos/bench.mp4",
            },
        ]

        exercises = exercise_service.get_exercises_for_workout(
            focus_area="chest",
            equipment=["barbell"],
            count=1
        )

        ex = exercises[0]
        assert ex["name"] == "Bench Press"
        assert ex["equipment"] == "barbell"
        assert ex["muscle_group"] == "pectoralis major"
        assert ex["body_part"] == "chest"
        assert "notes" in ex
        assert ex["library_id"] == 1


# ============================================================
# SEARCH EXERCISES TESTS
# ============================================================

class TestSearchExercises:
    """Test exercise search."""

    def test_search_exercises_success(self, exercise_service, mock_supabase, sample_exercises):
        """Test searching exercises by name."""
        mock_supabase.client.table.return_value.select.return_value.ilike.return_value.limit.return_value.execute.return_value = MagicMock(
            data=[sample_exercises[0]]  # Barbell Bench Press
        )

        exercises = exercise_service.search_exercises("bench")

        assert len(exercises) == 1
        assert "Bench Press" in exercises[0]["name"]

    def test_search_exercises_normalizes_fields(self, exercise_service, mock_supabase, sample_exercises):
        """Test search normalizes field names."""
        mock_supabase.client.table.return_value.select.return_value.ilike.return_value.limit.return_value.execute.return_value = MagicMock(
            data=[sample_exercises[0]]
        )

        exercises = exercise_service.search_exercises("bench")

        assert "name" in exercises[0]  # Should have 'name' field
        assert "muscle_group" in exercises[0]  # Should have 'muscle_group' field

    def test_search_exercises_empty_results(self, exercise_service, mock_supabase):
        """Test search with no results."""
        mock_supabase.client.table.return_value.select.return_value.ilike.return_value.limit.return_value.execute.return_value = MagicMock(
            data=[]
        )

        exercises = exercise_service.search_exercises("nonexistent")

        assert exercises == []

    def test_search_exercises_respects_limit(self, exercise_service, mock_supabase, sample_exercises):
        """Test search respects limit parameter."""
        mock_supabase.client.table.return_value.select.return_value.ilike.return_value.limit.return_value.execute.return_value = MagicMock(
            data=sample_exercises
        )

        exercise_service.search_exercises("press", limit=5)

        mock_supabase.client.table.return_value.select.return_value.ilike.return_value.limit.assert_called_with(5)

    def test_search_exercises_error_handling(self, exercise_service, mock_supabase):
        """Test error handling returns empty list."""
        mock_supabase.client.table.side_effect = Exception("Database error")

        exercises = exercise_service.search_exercises("bench")

        assert exercises == []


# ============================================================
# FOCUS AREA MAPPING TESTS
# ============================================================

class TestFocusAreaMapping:
    """Test focus area to body part mapping."""

    @patch.object(ExerciseLibraryService, 'get_exercises_by_body_part')
    def test_chest_maps_correctly(self, mock_get, exercise_service):
        """Test chest focus area maps to chest body part."""
        mock_get.return_value = []

        exercise_service.get_exercises_for_workout("chest", ["barbell"], 1)

        mock_get.assert_called_with(body_part="chest", equipment=["barbell"], limit=15)

    @patch.object(ExerciseLibraryService, 'get_exercises_by_body_part')
    def test_back_maps_correctly(self, mock_get, exercise_service):
        """Test back focus area maps to back body part."""
        mock_get.return_value = []

        exercise_service.get_exercises_for_workout("back", ["barbell"], 1)

        mock_get.assert_called_with(body_part="back", equipment=["barbell"], limit=15)

    @patch.object(ExerciseLibraryService, 'get_exercises_by_body_part')
    def test_legs_maps_to_upper_and_lower_legs(self, mock_get, exercise_service):
        """Test legs focus area maps to upper legs and lower legs."""
        mock_get.return_value = []

        exercise_service.get_exercises_for_workout("legs", ["barbell"], 1)

        # Should be called for both upper_legs and lower_legs
        calls = mock_get.call_args_list
        body_parts_called = [call.kwargs["body_part"] for call in calls]
        assert "upper legs" in body_parts_called
        assert "lower legs" in body_parts_called


# ============================================================
# SINGLETON TESTS
# ============================================================

class TestSingleton:
    """Test singleton pattern."""

    def test_get_exercise_library_service_returns_same_instance(self):
        """Test singleton returns same instance."""
        import services.exercise_library_service as module
        module._exercise_library_service = None

        with patch("services.exercise_library_service.get_supabase"):
            service1 = get_exercise_library_service()
            service2 = get_exercise_library_service()

            assert service1 is service2


# ============================================================
# EQUIPMENT INFERENCE TESTS
# ============================================================

class TestEquipmentInference:
    """Test equipment inference from exercise names."""

    @patch.object(ExerciseLibraryService, 'get_exercises_by_body_part')
    @patch("services.exercise_library_service._infer_equipment_from_name")
    def test_infers_equipment_when_missing(self, mock_infer, mock_get, exercise_service):
        """Test equipment is inferred when missing."""
        mock_get.return_value = [
            {"exercise_name": "Barbell Bench Press", "body_part": "chest", "target_muscle": "pecs", "equipment": ""},
        ]
        mock_infer.return_value = "barbell"

        exercises = exercise_service.get_exercises_for_workout("chest", ["barbell"], 1)

        mock_infer.assert_called()
        assert exercises[0]["equipment"] == "barbell"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
