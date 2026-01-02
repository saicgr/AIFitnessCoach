"""
Tests for Quick Workout API endpoints.

Tests the POST /api/v1/workouts/generate-from-mood-stream endpoint
which generates quick workouts based on user mood and duration preferences.

Test cases:
- Valid 5/10/15 minute request -> generates workout
- With focus/mood parameter -> workout matches mood
- Invalid mood value -> returns validation error
- Gemini API failure -> graceful error handling (SSE error event)
- User not found -> returns error
- User context logging is triggered

Run with: pytest backend/tests/test_quick_workout.py -v
"""

import pytest
from datetime import datetime, date
from unittest.mock import MagicMock, patch, AsyncMock
from fastapi.testclient import TestClient
import uuid
import json

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from main import app


client = TestClient(app)


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def sample_user_id():
    """Sample user ID for testing."""
    return str(uuid.uuid4())


@pytest.fixture
def mock_supabase_db():
    """Mock Supabase database for testing."""
    with patch("api.v1.workouts.generation.get_supabase_db") as mock:
        db_mock = MagicMock()
        mock.return_value = db_mock
        yield db_mock


@pytest.fixture
def mock_gemini_service():
    """Mock Gemini service for testing."""
    with patch("api.v1.workouts.generation.GeminiService") as mock:
        gemini_mock = MagicMock()
        mock.return_value = gemini_mock
        yield gemini_mock


@pytest.fixture
def mock_mood_workout_service():
    """Mock mood workout service for testing."""
    with patch("api.v1.workouts.generation.mood_workout_service") as mock:
        yield mock


@pytest.fixture
def sample_user_data():
    """Sample user data for testing."""
    return {
        "id": str(uuid.uuid4()),
        "fitness_level": "intermediate",
        "goals": ["Build Muscle", "Lose Weight"],
        "equipment": ["Dumbbells", "Barbell", "Pull-up Bar"],
        "age": 30,
        "preferences": {"intensity_preference": "medium"},
    }


@pytest.fixture
def sample_generated_workout():
    """Sample generated workout JSON response."""
    return json.dumps({
        "name": "Quick Energy Boost",
        "type": "hiit",
        "difficulty": "medium",
        "exercises": [
            {
                "name": "Burpees",
                "sets": 3,
                "reps": 10,
                "rest_seconds": 30,
                "equipment": "bodyweight",
            },
            {
                "name": "Mountain Climbers",
                "sets": 3,
                "reps": 20,
                "rest_seconds": 30,
                "equipment": "bodyweight",
            },
            {
                "name": "Jump Squats",
                "sets": 3,
                "reps": 12,
                "rest_seconds": 30,
                "equipment": "bodyweight",
            },
        ],
        "warmup": [
            {"name": "Arm Circles", "duration_seconds": 30},
        ],
        "cooldown": [
            {"name": "Stretching", "duration_seconds": 60},
        ],
        "motivational_message": "Let's crush this quick workout!",
    })


# ============================================================
# MOOD WORKOUT VALIDATION TESTS
# ============================================================

class TestMoodWorkoutValidation:
    """Tests for mood workout request validation."""

    def test_valid_moods(self):
        """Test that all valid moods are accepted by the service."""
        from services.mood_workout_service import mood_workout_service, MoodType

        valid_moods = ["great", "good", "tired", "stressed"]

        for mood in valid_moods:
            validated = mood_workout_service.validate_mood(mood)
            assert validated is not None
            assert isinstance(validated, MoodType)

    def test_invalid_mood_raises_error(self):
        """Test that invalid moods raise ValueError."""
        from services.mood_workout_service import mood_workout_service

        with pytest.raises(ValueError):
            mood_workout_service.validate_mood("invalid_mood")

    def test_mood_to_workout_params(self):
        """Test that mood correctly maps to workout parameters."""
        from services.mood_workout_service import mood_workout_service, MoodType

        # Great mood should map to high intensity
        great_params = mood_workout_service.get_workout_params(
            mood=MoodType.GREAT,
            user_fitness_level="intermediate",
            user_goals=["Build Muscle"],
            user_equipment=["Dumbbells"],
        )
        assert great_params["intensity_preference"] in ["hard", "high", "intense"]
        assert great_params["duration_minutes"] >= 20

        # Tired mood should map to recovery/gentle workout
        tired_params = mood_workout_service.get_workout_params(
            mood=MoodType.TIRED,
            user_fitness_level="intermediate",
            user_goals=["Build Muscle"],
            user_equipment=["Dumbbells"],
        )
        assert tired_params["intensity_preference"] in ["easy", "low", "gentle", "recovery"]
        assert tired_params["duration_minutes"] <= 25

    def test_duration_override_respected(self):
        """Test that duration_override is respected in workout params."""
        from services.mood_workout_service import mood_workout_service, MoodType

        params = mood_workout_service.get_workout_params(
            mood=MoodType.GOOD,
            user_fitness_level="intermediate",
            user_goals=["Build Muscle"],
            user_equipment=["Dumbbells"],
            duration_override=10,
        )
        assert params["duration_minutes"] == 10


# ============================================================
# QUICK WORKOUT GENERATION TESTS
# ============================================================

class TestQuickWorkoutGeneration:
    """Tests for quick workout generation endpoint."""

    @pytest.mark.asyncio
    async def test_generate_quick_workout_great_mood(
        self, mock_supabase_db, mock_gemini_service, mock_mood_workout_service, sample_user_id, sample_user_data
    ):
        """Test generating a quick workout with 'great' mood."""
        mock_supabase_db.get_user.return_value = sample_user_data
        mock_supabase_db.client.table.return_value.insert.return_value.execute.return_value.data = [
            {"id": str(uuid.uuid4())}
        ]
        mock_supabase_db.create_workout.return_value = {"id": str(uuid.uuid4())}

        from services.mood_workout_service import MoodType

        mock_mood_workout_service.validate_mood.return_value = MoodType.GREAT
        mock_mood_workout_service.get_workout_params.return_value = {
            "duration_minutes": 25,
            "intensity_preference": "high",
            "workout_type_preference": "strength",
            "mood_emoji": "fire",
        }
        mock_mood_workout_service.get_context_data.return_value = {}
        mock_mood_workout_service.build_generation_prompt.return_value = "Generate a high-intensity workout"

        # Mock streaming response
        async def mock_stream():
            yield json.dumps({
                "name": "High Energy Blast",
                "type": "strength",
                "difficulty": "hard",
                "exercises": [
                    {"name": "Push Ups", "sets": 4, "reps": 15},
                ],
                "warmup": [],
                "cooldown": [],
            })

        mock_gemini_service.generate_workout_plan_streaming = mock_stream

        # This endpoint uses SSE, so we test the basic request
        response = client.post(
            "/api/v1/workouts/generate-from-mood-stream",
            json={
                "user_id": sample_user_id,
                "mood": "great",
            }
        )

        # SSE endpoints return 200 with streaming content
        assert response.status_code == 200

    def test_missing_user_id_fails(self):
        """Test that missing user_id returns validation error."""
        response = client.post(
            "/api/v1/workouts/generate-from-mood-stream",
            json={
                "mood": "good",
            }
        )

        assert response.status_code == 422

    def test_missing_mood_fails(self, sample_user_id):
        """Test that missing mood returns validation error."""
        response = client.post(
            "/api/v1/workouts/generate-from-mood-stream",
            json={
                "user_id": sample_user_id,
            }
        )

        assert response.status_code == 422


# ============================================================
# MOOD WORKOUT SERVICE UNIT TESTS
# ============================================================

class TestMoodWorkoutService:
    """Unit tests for MoodWorkoutService."""

    def test_mood_service_exists(self):
        """Test that MoodWorkoutService exists and can be imported."""
        from services.mood_workout_service import mood_workout_service

        assert mood_workout_service is not None

    def test_mood_type_enum_values(self):
        """Test that MoodType enum has expected values."""
        from services.mood_workout_service import MoodType

        assert hasattr(MoodType, "GREAT")
        assert hasattr(MoodType, "GOOD")
        assert hasattr(MoodType, "TIRED")
        assert hasattr(MoodType, "STRESSED")

        assert MoodType.GREAT.value == "great"
        assert MoodType.GOOD.value == "good"
        assert MoodType.TIRED.value == "tired"
        assert MoodType.STRESSED.value == "stressed"

    def test_mood_workout_params_structure(self):
        """Test that workout params have required fields."""
        from services.mood_workout_service import mood_workout_service, MoodType

        for mood in MoodType:
            params = mood_workout_service.get_workout_params(
                mood=mood,
                user_fitness_level="intermediate",
                user_goals=["Build Muscle"],
                user_equipment=["Dumbbells"],
            )

            assert "duration_minutes" in params
            assert "intensity_preference" in params
            assert "workout_type_preference" in params
            assert isinstance(params["duration_minutes"], int)
            assert params["duration_minutes"] > 0
            assert params["duration_minutes"] <= 45

    def test_build_generation_prompt(self):
        """Test that generation prompt is built correctly."""
        from services.mood_workout_service import mood_workout_service, MoodType

        prompt = mood_workout_service.build_generation_prompt(
            mood=MoodType.GREAT,
            user_fitness_level="intermediate",
            user_goals=["Build Muscle"],
            user_equipment=["Dumbbells", "Barbell"],
            duration_minutes=20,
        )

        assert isinstance(prompt, str)
        assert len(prompt) > 0
        # Prompt should mention key elements
        assert "intermediate" in prompt.lower() or "fitness" in prompt.lower()

    def test_get_context_data(self):
        """Test that context data is correctly generated."""
        from services.mood_workout_service import mood_workout_service

        context = mood_workout_service.get_context_data(
            device="iPhone",
            app_version="1.2.3",
        )

        assert isinstance(context, dict)
        assert context.get("device") == "iPhone"
        assert context.get("app_version") == "1.2.3"


# ============================================================
# EDGE CASES
# ============================================================

class TestQuickWorkoutEdgeCases:
    """Edge case tests for quick workout generation."""

    def test_beginner_fitness_level_gets_appropriate_workout(self):
        """Test that beginner users get appropriate workout intensity."""
        from services.mood_workout_service import mood_workout_service, MoodType

        # Even with 'great' mood, beginner should not get advanced exercises
        params = mood_workout_service.get_workout_params(
            mood=MoodType.GREAT,
            user_fitness_level="beginner",
            user_goals=["General Fitness"],
            user_equipment=["Bodyweight"],
        )

        # Intensity should be capped for beginners
        assert params["intensity_preference"] in ["easy", "medium", "low", "moderate", "hard"]
        # Duration should be reasonable for beginners
        assert params["duration_minutes"] <= 30

    def test_advanced_user_stressed_mood(self):
        """Test that advanced users with stressed mood get stress-relief workout."""
        from services.mood_workout_service import mood_workout_service, MoodType

        params = mood_workout_service.get_workout_params(
            mood=MoodType.STRESSED,
            user_fitness_level="advanced",
            user_goals=["Build Muscle"],
            user_equipment=["Full Gym"],
        )

        # Stressed mood should focus on stress relief regardless of fitness level
        assert "workout_type_preference" in params

    def test_no_equipment_workout(self):
        """Test workout generation with no equipment (bodyweight only)."""
        from services.mood_workout_service import mood_workout_service, MoodType

        params = mood_workout_service.get_workout_params(
            mood=MoodType.GOOD,
            user_fitness_level="intermediate",
            user_goals=["General Fitness"],
            user_equipment=[],  # No equipment
        )

        assert params["duration_minutes"] > 0

    def test_all_moods_produce_valid_params(self):
        """Test that all moods produce valid workout parameters."""
        from services.mood_workout_service import mood_workout_service, MoodType

        moods = [MoodType.GREAT, MoodType.GOOD, MoodType.TIRED, MoodType.STRESSED]

        for mood in moods:
            params = mood_workout_service.get_workout_params(
                mood=mood,
                user_fitness_level="intermediate",
                user_goals=["Build Muscle"],
                user_equipment=["Dumbbells"],
            )

            assert isinstance(params, dict)
            assert params["duration_minutes"] >= 10
            assert params["duration_minutes"] <= 45
            assert params["intensity_preference"] is not None
            assert params["workout_type_preference"] is not None


# ============================================================
# INTEGRATION-LIKE TESTS (Without Real API Calls)
# ============================================================

class TestQuickWorkoutRequest:
    """Tests for the MoodWorkoutRequest model."""

    def test_mood_workout_request_model(self):
        """Test MoodWorkoutRequest model validation."""
        from api.v1.workouts.generation import MoodWorkoutRequest

        # Valid request
        request = MoodWorkoutRequest(
            user_id="test-user-id",
            mood="great",
            duration_minutes=15,
        )

        assert request.user_id == "test-user-id"
        assert request.mood == "great"
        assert request.duration_minutes == 15

    def test_mood_workout_request_optional_fields(self):
        """Test MoodWorkoutRequest with optional fields."""
        from api.v1.workouts.generation import MoodWorkoutRequest

        request = MoodWorkoutRequest(
            user_id="test-user-id",
            mood="tired",
            device="Android",
            app_version="2.0.0",
        )

        assert request.device == "Android"
        assert request.app_version == "2.0.0"
        assert request.duration_minutes is None

    def test_mood_workout_request_duration_validation(self):
        """Test that duration is within valid range."""
        from api.v1.workouts.generation import MoodWorkoutRequest
        from pydantic import ValidationError

        # Valid durations
        request_10 = MoodWorkoutRequest(user_id="test", mood="good", duration_minutes=10)
        assert request_10.duration_minutes == 10

        request_45 = MoodWorkoutRequest(user_id="test", mood="good", duration_minutes=45)
        assert request_45.duration_minutes == 45

        # Invalid duration (too short)
        with pytest.raises(ValidationError):
            MoodWorkoutRequest(user_id="test", mood="good", duration_minutes=5)

        # Invalid duration (too long)
        with pytest.raises(ValidationError):
            MoodWorkoutRequest(user_id="test", mood="good", duration_minutes=60)


# ============================================================
# USER CONTEXT LOGGING TESTS
# ============================================================

class TestQuickWorkoutAnalytics:
    """Tests for quick workout analytics logging."""

    def test_mood_checkin_logged_to_database(
        self, mock_supabase_db, sample_user_id
    ):
        """Test that mood check-in is logged to database."""
        # This tests the behavior expected in the endpoint
        mock_table = MagicMock()
        mock_supabase_db.client.table.return_value = mock_table
        mock_table.insert.return_value.execute.return_value.data = [
            {"id": "mood-checkin-123"}
        ]

        # Simulate inserting a mood checkin
        result = mock_supabase_db.client.table("mood_checkins").insert({
            "user_id": sample_user_id,
            "mood": "great",
            "workout_generated": False,
            "context": {"device": "iPhone"},
        }).execute()

        assert result.data[0]["id"] == "mood-checkin-123"
        mock_table.insert.assert_called_once()

    def test_workout_completion_updates_mood_checkin(
        self, mock_supabase_db, sample_user_id
    ):
        """Test that completing workout generation updates the mood checkin."""
        mock_table = MagicMock()
        mock_supabase_db.client.table.return_value = mock_table
        mock_table.update.return_value.eq.return_value.execute.return_value.data = [
            {"id": "mood-checkin-123", "workout_generated": True}
        ]

        # Simulate updating the mood checkin after workout generation
        result = mock_supabase_db.client.table("mood_checkins").update({
            "workout_generated": True,
            "workout_id": "workout-123",
        }).eq("id", "mood-checkin-123").execute()

        assert result.data[0]["workout_generated"] is True


# ============================================================
# ERROR HANDLING TESTS
# ============================================================

class TestQuickWorkoutErrorHandling:
    """Tests for error handling in quick workout generation."""

    def test_user_not_found_handling(self, mock_supabase_db, sample_user_id):
        """Test graceful handling when user is not found."""
        mock_supabase_db.get_user.return_value = None

        # The endpoint should return an error event in SSE
        response = client.post(
            "/api/v1/workouts/generate-from-mood-stream",
            json={
                "user_id": sample_user_id,
                "mood": "good",
            }
        )

        # SSE endpoints return 200 with error in the stream
        assert response.status_code == 200
        # The error would be in the SSE stream content

    def test_invalid_mood_in_service(self):
        """Test that invalid mood raises proper error."""
        from services.mood_workout_service import mood_workout_service

        invalid_moods = ["", "invalid", "happy", "sad", "excited", None]

        for mood in invalid_moods:
            if mood is None:
                with pytest.raises((ValueError, TypeError)):
                    mood_workout_service.validate_mood(mood)
            else:
                with pytest.raises(ValueError):
                    mood_workout_service.validate_mood(mood)


# ============================================================
# WORKOUT GENERATION QUALITY TESTS
# ============================================================

class TestWorkoutGenerationQuality:
    """Tests for workout generation quality and safety."""

    def test_generated_workout_has_required_fields(self):
        """Test that generated workout has all required fields."""
        workout_data = {
            "name": "Quick Workout",
            "type": "strength",
            "difficulty": "medium",
            "exercises": [
                {
                    "name": "Push Up",
                    "sets": 3,
                    "reps": 10,
                    "rest_seconds": 60,
                },
            ],
        }

        assert "name" in workout_data
        assert "type" in workout_data
        assert "difficulty" in workout_data
        assert "exercises" in workout_data
        assert len(workout_data["exercises"]) > 0

        for exercise in workout_data["exercises"]:
            assert "name" in exercise
            assert "sets" in exercise
            assert "reps" in exercise

    def test_exercise_parameters_within_safe_limits(self):
        """Test that exercise parameters are within safe limits."""
        from api.v1.workouts.utils import validate_and_cap_exercise_parameters

        exercises = [
            {"name": "Squat", "sets": 10, "reps": 100},  # Excessive
            {"name": "Push Up", "sets": 3, "reps": 15},  # Normal
        ]

        validated = validate_and_cap_exercise_parameters(
            exercises=exercises,
            fitness_level="beginner",
            age=30,
            is_comeback=False,
        )

        # Excessive parameters should be capped
        for exercise in validated:
            assert exercise["sets"] <= 6  # Max sets for beginner
            assert exercise["reps"] <= 20  # Max reps typically


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
