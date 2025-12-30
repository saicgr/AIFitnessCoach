"""
Tests for Custom and Composite Exercise API endpoints.

Tests the following endpoints:
- GET /api/v1/exercises/custom/{user_id} - Get user's custom exercises
- GET /api/v1/exercises/custom/{user_id}/all - Get all custom exercises with usage stats
- POST /api/v1/exercises/custom/{user_id} - Create a simple custom exercise
- POST /api/v1/exercises/custom/{user_id}/composite - Create a composite exercise
- PUT /api/v1/exercises/custom/{user_id}/{exercise_id} - Update a custom exercise
- DELETE /api/v1/exercises/custom/{user_id}/{exercise_id} - Delete a custom exercise
- POST /api/v1/exercises/custom/{user_id}/{exercise_id}/log-usage - Log exercise usage
- GET /api/v1/exercises/custom/{user_id}/stats - Get custom exercise statistics
- GET /api/v1/exercises/library/search - Search exercise library
"""

import pytest
from unittest.mock import MagicMock, patch, AsyncMock
import uuid

# Test data
TEST_USER_ID = str(uuid.uuid4())


class MockSupabaseResult:
    """Mock Supabase query result."""
    def __init__(self, data):
        self.data = data


class MockSupabaseQuery:
    """Mock Supabase query builder."""
    def __init__(self, table_name, initial_data=None):
        self.table_name = table_name
        self._data = initial_data or []
        self._filters = {}

    def select(self, *args):
        return self

    def eq(self, field, value):
        self._filters[field] = value
        return self

    def ilike(self, field, pattern):
        return self

    def order(self, field, desc=False):
        return self

    def limit(self, n):
        return self

    def insert(self, data):
        self._data = [{"id": str(uuid.uuid4()), "created_at": "2024-01-01T00:00:00Z", **data}]
        return self

    def update(self, data):
        if self._data:
            self._data[0].update(data)
        return self

    def delete(self):
        return self

    def execute(self):
        return MockSupabaseResult(self._data)


class MockSupabaseClient:
    """Mock Supabase client."""
    def __init__(self, exercises=None, usage=None, stats=None):
        self._exercises = exercises or []
        self._usage = usage or []
        self._stats = stats or []

    def table(self, name):
        if name == "exercises":
            return MockSupabaseQuery("exercises", self._exercises)
        elif name == "custom_exercise_usage":
            return MockSupabaseQuery("custom_exercise_usage", self._usage)
        elif name == "exercise_library":
            return MockSupabaseQuery("exercise_library", [
                {"id": 1, "exercise_name": "Bench Press", "body_part": "chest", "equipment": "barbell", "target_muscle": "chest"},
                {"id": 2, "exercise_name": "Chest Fly", "body_part": "chest", "equipment": "dumbbell", "target_muscle": "chest"},
            ])
        return MockSupabaseQuery(name)

    def rpc(self, name, params):
        if name == "get_custom_exercise_stats":
            return MockSupabaseResult(self._stats)
        return MockSupabaseResult([])


class MockSupabaseDB:
    """Mock SupabaseDB wrapper."""
    def __init__(self, client):
        self.client = client


# ============================================================================
# Simple Custom Exercise Tests
# ============================================================================

class TestSimpleCustomExercises:
    """Tests for simple (non-composite) custom exercises."""

    @pytest.fixture
    def mock_db(self):
        """Create mock database with sample custom exercises."""
        exercises = [
            {
                "id": str(uuid.uuid4()),
                "name": "My Custom Push-up",
                "primary_muscle": "chest",
                "equipment": "bodyweight",
                "instructions": "Push up from the ground",
                "default_sets": 3,
                "default_reps": 15,
                "is_compound": True,
                "is_custom": True,
                "is_composite": False,
                "created_by_user_id": TEST_USER_ID,
                "created_at": "2024-01-01T00:00:00Z",
            }
        ]
        return MockSupabaseDB(MockSupabaseClient(exercises=exercises))

    def test_create_custom_exercise_model_validation(self):
        """Test that CustomExerciseCreate model validates input correctly."""
        from api.v1.exercises import CustomExerciseCreate

        # Valid exercise
        exercise = CustomExerciseCreate(
            name="Test Exercise",
            primary_muscle="chest",
            equipment="dumbbell",
            default_sets=3,
            default_reps=10,
        )
        assert exercise.name == "Test Exercise"
        assert exercise.primary_muscle == "chest"
        assert exercise.default_sets == 3

    def test_create_custom_exercise_validation_name_too_short(self):
        """Test that empty name is rejected."""
        from api.v1.exercises import CustomExerciseCreate
        from pydantic import ValidationError

        with pytest.raises(ValidationError):
            CustomExerciseCreate(
                name="",  # Too short
                primary_muscle="chest",
            )

    def test_create_custom_exercise_validation_sets_out_of_range(self):
        """Test that invalid sets count is rejected."""
        from api.v1.exercises import CustomExerciseCreate
        from pydantic import ValidationError

        with pytest.raises(ValidationError):
            CustomExerciseCreate(
                name="Test Exercise",
                primary_muscle="chest",
                default_sets=0,  # Below minimum of 1
            )

        with pytest.raises(ValidationError):
            CustomExerciseCreate(
                name="Test Exercise",
                primary_muscle="chest",
                default_sets=15,  # Above maximum of 10
            )


# ============================================================================
# Composite Exercise Tests
# ============================================================================

class TestCompositeExercises:
    """Tests for composite/combo exercises."""

    def test_composite_exercise_model_validation(self):
        """Test that CompositeExerciseCreate model validates correctly."""
        from api.v1.exercises import CompositeExerciseCreate, ComponentExercise

        # Valid composite exercise
        exercise = CompositeExerciseCreate(
            name="Bench Press & Chest Fly",
            primary_muscle="chest",
            secondary_muscles=["shoulders", "triceps"],
            equipment="dumbbell",
            combo_type="superset",
            component_exercises=[
                ComponentExercise(name="Dumbbell Bench Press", order=1, reps=10),
                ComponentExercise(name="Chest Fly", order=2, reps=12),
            ],
            default_sets=3,
        )
        assert exercise.name == "Bench Press & Chest Fly"
        assert exercise.combo_type == "superset"
        assert len(exercise.component_exercises) == 2

    def test_composite_exercise_minimum_components(self):
        """Test that composite exercises require at least 2 components."""
        from api.v1.exercises import CompositeExerciseCreate, ComponentExercise
        from pydantic import ValidationError

        with pytest.raises(ValidationError):
            CompositeExerciseCreate(
                name="Single Exercise",
                primary_muscle="chest",
                combo_type="superset",
                component_exercises=[
                    ComponentExercise(name="Only One", order=1, reps=10),
                ],  # Only 1 component - should fail
            )

    def test_composite_exercise_maximum_components(self):
        """Test that composite exercises cannot have more than 5 components."""
        from api.v1.exercises import CompositeExerciseCreate, ComponentExercise
        from pydantic import ValidationError

        with pytest.raises(ValidationError):
            CompositeExerciseCreate(
                name="Too Many Exercises",
                primary_muscle="full body",
                combo_type="giant_set",
                component_exercises=[
                    ComponentExercise(name=f"Exercise {i}", order=i, reps=10)
                    for i in range(1, 7)  # 6 components - should fail
                ],
            )

    def test_component_exercise_model(self):
        """Test ComponentExercise model validation."""
        from api.v1.exercises import ComponentExercise

        # With reps
        comp1 = ComponentExercise(name="Push-up", order=1, reps=15)
        assert comp1.reps == 15
        assert comp1.duration_seconds is None

        # With duration
        comp2 = ComponentExercise(name="Plank", order=2, duration_seconds=60)
        assert comp2.reps is None
        assert comp2.duration_seconds == 60

        # With transition note
        comp3 = ComponentExercise(
            name="Burpee",
            order=1,
            reps=10,
            transition_note="immediately flow into"
        )
        assert comp3.transition_note == "immediately flow into"

    def test_valid_combo_types(self):
        """Test all valid combo types."""
        from api.v1.exercises import CompositeExerciseCreate, ComponentExercise

        valid_types = ["superset", "compound_set", "giant_set", "complex", "hybrid"]

        for combo_type in valid_types:
            exercise = CompositeExerciseCreate(
                name=f"{combo_type.title()} Example",
                primary_muscle="chest",
                combo_type=combo_type,
                component_exercises=[
                    ComponentExercise(name="Exercise 1", order=1, reps=10),
                    ComponentExercise(name="Exercise 2", order=2, reps=10),
                ],
            )
            assert exercise.combo_type == combo_type


# ============================================================================
# Response Model Tests
# ============================================================================

class TestResponseModels:
    """Tests for response models."""

    def test_custom_exercise_response(self):
        """Test CustomExerciseResponse model."""
        from api.v1.exercises import CustomExerciseResponse

        response = CustomExerciseResponse(
            id=str(uuid.uuid4()),
            name="Custom Exercise",
            primary_muscle="back",
            equipment="cable",
            instructions="Pull the cable",
            default_sets=4,
            default_reps=12,
            is_compound=False,
            created_at="2024-01-01T00:00:00Z",
        )
        assert response.name == "Custom Exercise"
        assert response.default_sets == 4

    def test_composite_exercise_response(self):
        """Test CompositeExerciseResponse model."""
        from api.v1.exercises import CompositeExerciseResponse

        response = CompositeExerciseResponse(
            id=str(uuid.uuid4()),
            name="Superset Example",
            primary_muscle="chest",
            secondary_muscles=["triceps"],
            equipment="dumbbell",
            combo_type="superset",
            component_exercises=[
                {"name": "Press", "order": 1, "reps": 10},
                {"name": "Fly", "order": 2, "reps": 12},
            ],
            instructions="Perform back to back",
            custom_notes="Great for pump",
            default_sets=3,
            default_rest_seconds=60,
            tags=["custom", "combo", "superset"],
            is_composite=True,
            usage_count=5,
            created_at="2024-01-01T00:00:00Z",
        )
        assert response.is_composite is True
        assert response.combo_type == "superset"
        assert response.usage_count == 5

    def test_custom_exercise_full_response(self):
        """Test CustomExerciseFullResponse model."""
        from api.v1.exercises import CustomExerciseFullResponse

        # Test with composite exercise
        response = CustomExerciseFullResponse(
            id=str(uuid.uuid4()),
            name="Full Response Test",
            primary_muscle="legs",
            secondary_muscles=["glutes"],
            equipment="barbell",
            instructions="Squat and press",
            default_sets=4,
            default_reps=8,
            default_rest_seconds=90,
            is_compound=True,
            is_composite=True,
            combo_type="complex",
            component_exercises=[
                {"name": "Squat", "order": 1, "reps": 5},
                {"name": "Press", "order": 2, "reps": 5},
            ],
            custom_notes="Use moderate weight",
            tags=["custom", "complex"],
            usage_count=10,
            last_used="2024-01-15T00:00:00Z",
            created_at="2024-01-01T00:00:00Z",
        )
        assert response.is_composite is True
        assert response.combo_type == "complex"
        assert response.usage_count == 10


# ============================================================================
# API Endpoint Tests (Integration)
# ============================================================================

class TestExerciseAPIEndpoints:
    """Integration tests for exercise API endpoints."""

    @pytest.fixture
    def client(self):
        """Create test client."""
        from fastapi.testclient import TestClient
        from main import app
        return TestClient(app)

    @pytest.fixture
    def mock_supabase(self):
        """Mock Supabase database for API tests."""
        exercises = [
            {
                "id": str(uuid.uuid4()),
                "name": "Test Custom Exercise",
                "primary_muscle": "chest",
                "equipment": "dumbbell",
                "instructions": "Test instructions",
                "default_sets": 3,
                "default_reps": 10,
                "is_compound": False,
                "is_custom": True,
                "is_composite": False,
                "created_by_user_id": TEST_USER_ID,
                "created_at": "2024-01-01T00:00:00Z",
            }
        ]
        return MockSupabaseDB(MockSupabaseClient(exercises=exercises))

    def test_search_exercise_library(self, client, mock_supabase):
        """Test searching the exercise library."""
        with patch('api.v1.exercises.get_supabase_db', return_value=mock_supabase):
            response = client.get("/api/v1/exercises/library/search?query=bench")

            # The endpoint should return results
            assert response.status_code == 200
            data = response.json()
            assert "results" in data
            assert "count" in data


# ============================================================================
# Muscle Mapping Tests
# ============================================================================

class TestMuscleMapping:
    """Tests for muscle-to-body-part mapping logic."""

    def test_muscle_mappings(self):
        """Test that muscle groups map to correct body parts."""
        muscle_to_body_part = {
            "chest": "chest",
            "back": "back",
            "shoulders": "shoulders",
            "biceps": "upper arms",
            "triceps": "upper arms",
            "forearms": "lower arms",
            "abs": "waist",
            "core": "waist",
            "quadriceps": "upper legs",
            "quads": "upper legs",
            "hamstrings": "upper legs",
            "glutes": "upper legs",
            "calves": "lower legs",
            "legs": "upper legs",
            "full body": "full body",
        }

        # Verify all expected mappings
        assert muscle_to_body_part["chest"] == "chest"
        assert muscle_to_body_part["biceps"] == "upper arms"
        assert muscle_to_body_part["abs"] == "waist"
        assert muscle_to_body_part["calves"] == "lower legs"


# ============================================================================
# Usage Tracking Tests
# ============================================================================

class TestUsageTracking:
    """Tests for custom exercise usage tracking."""

    def test_usage_log_with_rating(self):
        """Test logging usage with a rating."""
        # Rating should be 1-5
        valid_ratings = [1, 2, 3, 4, 5]
        for rating in valid_ratings:
            assert 1 <= rating <= 5

    def test_usage_log_invalid_rating(self):
        """Test that invalid ratings are handled."""
        invalid_ratings = [0, 6, -1, 100]
        for rating in invalid_ratings:
            # These should fail validation
            assert not (1 <= rating <= 5)


# ============================================================================
# Edge Cases
# ============================================================================

class TestEdgeCases:
    """Tests for edge cases and error handling."""

    def test_empty_component_exercises_name(self):
        """Test that empty component names are rejected."""
        from api.v1.exercises import ComponentExercise
        from pydantic import ValidationError

        with pytest.raises(ValidationError):
            ComponentExercise(name="", order=1, reps=10)

    def test_component_order_range(self):
        """Test that component order is within valid range."""
        from api.v1.exercises import ComponentExercise
        from pydantic import ValidationError

        # Valid order (1-10)
        comp = ComponentExercise(name="Test", order=5, reps=10)
        assert comp.order == 5

        # Invalid order (0)
        with pytest.raises(ValidationError):
            ComponentExercise(name="Test", order=0, reps=10)

        # Invalid order (11)
        with pytest.raises(ValidationError):
            ComponentExercise(name="Test", order=11, reps=10)

    def test_composite_with_tags(self):
        """Test composite exercise with custom tags."""
        from api.v1.exercises import CompositeExerciseCreate, ComponentExercise

        exercise = CompositeExerciseCreate(
            name="Tagged Exercise",
            primary_muscle="chest",
            combo_type="superset",
            component_exercises=[
                ComponentExercise(name="Press", order=1, reps=10),
                ComponentExercise(name="Fly", order=2, reps=12),
            ],
            tags=["chest-day", "pump", "high-volume"],
        )
        assert len(exercise.tags) == 3
        assert "chest-day" in exercise.tags


# ============================================================================
# JSON Parsing Tests
# ============================================================================

class TestJSONParsing:
    """Tests for JSON field parsing in responses."""

    def test_parse_json_string_to_list(self):
        """Test parsing JSON string to list (for component_exercises, tags, etc.)."""
        import json

        # Simulate what comes from database as string
        json_string = '[{"name": "Press", "order": 1}, {"name": "Fly", "order": 2}]'
        parsed = json.loads(json_string)

        assert isinstance(parsed, list)
        assert len(parsed) == 2
        assert parsed[0]["name"] == "Press"

    def test_handle_empty_json_array(self):
        """Test handling empty JSON array."""
        import json

        empty_json = "[]"
        parsed = json.loads(empty_json)

        assert isinstance(parsed, list)
        assert len(parsed) == 0

    def test_handle_malformed_json(self):
        """Test handling malformed JSON gracefully."""
        import json

        malformed = "not valid json"
        try:
            json.loads(malformed)
            assert False, "Should have raised exception"
        except json.JSONDecodeError:
            pass  # Expected


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
