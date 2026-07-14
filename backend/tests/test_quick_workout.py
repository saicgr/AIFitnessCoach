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


MOCK_AUTH_USER_ID = "00000000-0000-0000-0000-0000000000aa"


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture(autouse=True)
def authed_client():
    """Satisfy the endpoint's auth dependency and disable the rate limiter.

    POST /generate-from-mood-stream is `Depends(get_current_user)` (see
    api/v1/workouts/mood_generation.py). Without an override every request in
    this module short-circuits at 401, so tests asserting 200/422 were really
    just asserting "unauthenticated" — they never reached the code under test.
    This is the same fixture pattern used by tests/test_add_exercise_sections.py.
    """
    from core.auth import get_current_user
    from core.rate_limiter import limiter

    app.dependency_overrides[get_current_user] = lambda: {
        "id": MOCK_AUTH_USER_ID,
        "email": "test@example.com",
    }
    was_enabled = limiter.enabled
    limiter.enabled = False  # route is @limiter.limit("10/minute")
    try:
        yield
    finally:
        limiter.enabled = was_enabled
        app.dependency_overrides.pop(get_current_user, None)


@pytest.fixture
def sample_user_id():
    """Sample user ID for testing."""
    return str(uuid.uuid4())


@pytest.fixture
def mock_supabase_db():
    """Mock Supabase database for testing.

    Patch target is api.v1.workouts.mood_generation — the mood endpoints were
    split out of generation.py into mood_generation.py, so patching
    `api.v1.workouts.generation.get_supabase_db` rebound a name the endpoint
    never reads and the tests silently talked to the real database.
    """
    with patch("api.v1.workouts.mood_generation.get_supabase_db") as mock:
        db_mock = MagicMock()
        mock.return_value = db_mock
        yield db_mock


@pytest.fixture
def mock_gemini_service():
    """Stub the Gemini call the mood endpoint actually makes.

    The endpoint does NOT use the GeminiService class — it calls
    `gemini_generate_with_retry` (imported inside the handler from
    services.gemini.constants). The old fixture patched
    `api.v1.workouts.generation.GeminiService`, which meant the test issued a
    REAL Gemini network request. Patch the real collaborator instead; the
    returned object mimics the SDK response (`.text` holds the JSON).
    """
    def _set_targets(count, reps, weight_kg=None):
        # Production's validate_set_targets_strict REQUIRES per-set targets on
        # every exercise (no fallback data) — a stub without them is rejected,
        # exactly as a real Gemini response missing them would be.
        return [
            {
                "set_number": i + 1,
                "set_type": "working",
                "target_reps": reps,
                "target_weight_kg": weight_kg,
            }
            for i in range(count)
        ]

    workout_json = json.dumps({
        "name": "High Energy Blast",
        "type": "strength",
        "difficulty": "hard",
        "duration_minutes": 25,
        "exercises": [
            {
                "name": "Push Ups",
                "sets": 4,
                "reps": 15,
                "rest_seconds": 45,
                "set_targets": _set_targets(4, 15),
            },
            {
                "name": "Goblet Squat",
                "sets": 4,
                "reps": 12,
                "rest_seconds": 60,
                "set_targets": _set_targets(4, 12, 24.0),
            },
        ],
        "motivational_message": "Let's go!",
    })
    response = MagicMock()
    response.text = workout_json
    with patch(
        "services.gemini.constants.gemini_generate_with_retry",
        new=AsyncMock(return_value=response),
    ) as mock:
        yield mock


@pytest.fixture
def mock_generation_collaborators():
    """Stub the DB/network collaborators the mood endpoint calls after Gemini.

    warmup/stretch generation, 1RM lookup, training intensity, comeback status,
    change logging and RAG indexing all hit Supabase. Patched in the
    mood_generation namespace so the endpoint's orchestration (mood params ->
    Gemini -> warmup/cooldown -> persist -> SSE 'done') can be exercised
    hermetically. Each of these collaborators is tested on its own elsewhere.
    """
    warmup_svc = MagicMock()
    warmup_svc.generate_warmup = AsyncMock(return_value=[{"name": "Arm Circles", "duration_seconds": 30}])
    warmup_svc.generate_stretches = AsyncMock(return_value=[{"name": "Chest Stretch", "duration_seconds": 45}])

    with patch("api.v1.workouts.mood_generation.get_warmup_stretch_service", return_value=warmup_svc), \
         patch("api.v1.workouts.mood_generation.get_user_1rm_data", new=AsyncMock(return_value={})), \
         patch("api.v1.workouts.mood_generation.get_user_training_intensity", new=AsyncMock(return_value=None)), \
         patch("api.v1.workouts.mood_generation.get_user_intensity_overrides", new=AsyncMock(return_value={})), \
         patch("api.v1.workouts.mood_generation.get_user_comeback_status",
               new=AsyncMock(return_value={"in_comeback_mode": False, "days_since_last_workout": 1})), \
         patch("api.v1.workouts.mood_generation.log_workout_change"), \
         patch("api.v1.workouts.mood_generation.user_context_service") as user_ctx, \
         patch("api.v1.workouts.mood_generation.row_to_workout") as row_to_workout:
        user_ctx.log_mood_checkin = AsyncMock(return_value=None)
        workout_row = MagicMock()
        workout_row.id = "workout-123"
        workout_row.user_id = MOCK_AUTH_USER_ID
        workout_row.name = "High Energy Blast"
        workout_row.type = "strength"
        workout_row.difficulty = "hard"
        workout_row.scheduled_date = None
        row_to_workout.return_value = workout_row
        yield warmup_svc


@pytest.fixture
def mock_mood_workout_service():
    """Mock mood workout service for testing.

    Patch target corrected to api.v1.workouts.mood_generation (see
    mock_supabase_db).
    """
    with patch("api.v1.workouts.mood_generation.mood_workout_service") as mock:
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
        """Test that duration_override drives the resulting workout duration.

        Used to assert `duration_override=10` on a GOOD mood yielded exactly 10.
        That has never been the product's behavior: get_workout_params clamps the
        override into the mood's own duration_range (GOOD = 15-25), and the clamp
        (b8bfc59b, 2025-12-30) predates this test (2026-01-01) — so the assertion
        was written against an intent the service never implemented. The clamp is
        the deliberate, documented contract ("Optional duration override (within
        mood's range)") and is asserted independently by
        tests/test_mood_workout.py::test_get_workout_params_with_duration_override.

        The guarantee protected here is the original intent — the override is not
        ignored — restated against the real contract, still with exact values:
        an in-range override is honored EXACTLY, and an out-of-range one is
        clamped to the nearest bound of the mood's range (never silently dropped
        back to the mood default).
        """
        from services.mood_workout_service import mood_workout_service, MoodType

        # In-range override (GOOD range is 15-25) is honored exactly — and is
        # not the mood's default of 20, proving the override actually applied.
        params = mood_workout_service.get_workout_params(
            mood=MoodType.GOOD,
            user_fitness_level="intermediate",
            user_goals=["Build Muscle"],
            user_equipment=["Dumbbells"],
            duration_override=18,
        )
        assert params["duration_minutes"] == 18

        # Below the mood's range -> clamped up to the minimum.
        params = mood_workout_service.get_workout_params(
            mood=MoodType.GOOD,
            user_fitness_level="intermediate",
            user_goals=["Build Muscle"],
            user_equipment=["Dumbbells"],
            duration_override=10,
        )
        assert params["duration_minutes"] == 15

        # Above the mood's range -> clamped down to the maximum.
        params = mood_workout_service.get_workout_params(
            mood=MoodType.GOOD,
            user_fitness_level="intermediate",
            user_goals=["Build Muscle"],
            user_equipment=["Dumbbells"],
            duration_override=45,
        )
        assert params["duration_minutes"] == 25


# ============================================================
# QUICK WORKOUT GENERATION TESTS
# ============================================================

class TestQuickWorkoutGeneration:
    """Tests for quick workout generation endpoint."""

    def test_generate_quick_workout_great_mood(
        self,
        mock_supabase_db,
        mock_gemini_service,
        mock_generation_collaborators,
        sample_user_id,
        sample_user_data,
    ):
        """Test generating a quick workout with 'great' mood.

        Previously this only asserted `status_code == 200` while every
        collaborator was patched on the wrong module (api.v1.workouts.generation
        instead of .mood_generation) and auth was unsatisfied — so it asserted
        200 against a request that actually 401'd, and the mocked Gemini stream
        was never used. The real mood_workout_service is used now (not mocked)
        so the GREAT mood config is genuinely exercised: the SSE stream must
        carry the started chunk and a 'done' event whose payload is built from
        the GREAT config (25 min default, 🔥) plus the Gemini exercises and the
        algorithmic warmup/cooldown.
        """
        mock_supabase_db.get_user.return_value = sample_user_data
        mock_supabase_db.client.table.return_value.insert.return_value.execute.return_value.data = [
            {"id": "mood-checkin-1"}
        ]
        mock_supabase_db.create_workout.return_value = {
            "id": "workout-123",
            "user_id": sample_user_id,
            "name": "High Energy Blast",
            "type": "strength",
            "difficulty": "hard",
        }

        response = client.post(
            "/api/v1/workouts/generate-from-mood-stream",
            json={
                "user_id": sample_user_id,
                "mood": "great",
            },
        )

        # SSE endpoints return 200 with streaming content
        assert response.status_code == 200
        body = response.text
        assert "event: error" not in body, body

        done_payload = json.loads(
            body.split("event: done\ndata: ")[1].split("\n\n")[0]
        )
        assert done_payload["mood"] == "great"
        assert done_payload["mood_emoji"] == "🔥"  # GREAT config
        assert done_payload["duration_minutes"] == 25  # GREAT duration_default
        assert [e["name"] for e in done_payload["exercises"]] == ["Push Ups", "Goblet Squat"]
        assert done_payload["warmup"] == [{"name": "Arm Circles", "duration_seconds": 30}]
        assert done_payload["cooldown"] == [{"name": "Chest Stretch", "duration_seconds": 45}]
        assert done_payload["motivational_message"] == "Let's go!"
        assert done_payload["comeback_detected"] is False

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
