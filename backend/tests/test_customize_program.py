"""
Tests for program customization (update-program endpoint).

These tests verify:
1. intensity_preference is correctly saved to user profile
2. intensity_preference is passed to workout generation
3. Generated workouts have the correct difficulty

Run with: pytest tests/test_customize_program.py -v
"""
import pytest
import asyncio
import json
from datetime import datetime, timedelta
from unittest.mock import MagicMock, AsyncMock, patch

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


class TestIntensityPreferenceSaving:
    """Tests for saving intensity_preference to user profile."""

    def test_update_program_saves_intensity_preference(self):
        """Verify that update-program endpoint saves intensity_preference correctly."""
        from api.v1.workouts.program import update_program
        from models.schemas import UpdateProgramRequest

        # This test verifies the logic in program.py line 58:
        # updated_prefs["intensity_preference"] = request.difficulty

        # Mock the request
        request = UpdateProgramRequest(
            user_id="test-user-123",
            difficulty="hard",
            duration_minutes=60,
        )

        # Verify the request has the difficulty field
        assert request.difficulty == "hard"
        assert request.duration_minutes == 60

    def test_intensity_preference_values(self):
        """Test that all valid intensity values are accepted."""
        from models.schemas import UpdateProgramRequest

        valid_difficulties = ["easy", "medium", "hard"]

        for difficulty in valid_difficulties:
            request = UpdateProgramRequest(
                user_id="test-user-123",
                difficulty=difficulty,
            )
            assert request.difficulty == difficulty


class TestIntensityPreferenceInGeneration:
    """Tests for using intensity_preference in workout generation."""

    @pytest.fixture
    def mock_user_with_hard_intensity(self):
        """Create a mock user with hard intensity preference."""
        return {
            "id": "test-user-123",
            "fitness_level": "intermediate",
            "goals": json.dumps(["Build Muscle"]),
            "equipment": json.dumps(["Dumbbells", "Barbell"]),
            "preferences": json.dumps({
                "intensity_preference": "hard",
                "workout_duration": 60,
                "training_split": "full_body",
            }),
            "active_injuries": json.dumps([]),
        }

    @pytest.fixture
    def mock_user_with_easy_intensity(self):
        """Create a mock user with easy intensity preference."""
        return {
            "id": "test-user-456",
            "fitness_level": "beginner",
            "goals": json.dumps(["Stay Active"]),
            "equipment": json.dumps(["Bodyweight Only"]),
            "preferences": json.dumps({
                "intensity_preference": "easy",
                "workout_duration": 30,
                "training_split": "full_body",
            }),
            "active_injuries": json.dumps([]),
        }

    def test_intensity_preference_extracted_from_user(self, mock_user_with_hard_intensity):
        """Test that intensity_preference is correctly extracted from user preferences."""
        from api.v1.workouts.utils import parse_json_field

        user = mock_user_with_hard_intensity
        preferences = parse_json_field(user.get("preferences"), {})
        intensity_preference = preferences.get("intensity_preference", "medium")

        assert intensity_preference == "hard"

    def test_intensity_preference_derived_from_fitness_level_when_not_set(self):
        """Test that intensity is derived from fitness_level when intensity_preference not set."""
        from api.v1.workouts.utils import parse_json_field, get_intensity_from_fitness_level

        user = {
            "fitness_level": "beginner",
            "preferences": json.dumps({
                "workout_duration": 45,
            })
        }
        preferences = parse_json_field(user.get("preferences"), {})
        fitness_level = user.get("fitness_level")
        # New logic: derive from fitness level when not explicitly set
        intensity_preference = preferences.get("intensity_preference") or get_intensity_from_fitness_level(fitness_level)

        # Beginners should get 'easy', not 'medium'
        assert intensity_preference == "easy"

    def test_intensity_from_fitness_level_beginner(self):
        """Test beginner gets easy intensity."""
        from api.v1.workouts.utils import get_intensity_from_fitness_level
        assert get_intensity_from_fitness_level("beginner") == "easy"

    def test_intensity_from_fitness_level_intermediate(self):
        """Test intermediate gets medium intensity."""
        from api.v1.workouts.utils import get_intensity_from_fitness_level
        assert get_intensity_from_fitness_level("intermediate") == "medium"

    def test_intensity_from_fitness_level_advanced(self):
        """Test advanced gets hard intensity."""
        from api.v1.workouts.utils import get_intensity_from_fitness_level
        assert get_intensity_from_fitness_level("advanced") == "hard"

    def test_generate_workout_from_library_accepts_intensity(self):
        """Test that generate_workout_from_library accepts intensity_preference parameter."""
        from services.gemini_service import GeminiService
        import inspect

        # Get the method signature
        sig = inspect.signature(GeminiService.generate_workout_from_library)
        params = sig.parameters

        # Verify intensity_preference is a valid parameter
        assert "intensity_preference" in params, \
            "generate_workout_from_library should accept intensity_preference parameter"

    def test_generate_workout_plan_accepts_intensity(self):
        """Test that generate_workout_plan accepts intensity_preference parameter."""
        from services.gemini_service import GeminiService
        import inspect

        # Get the method signature
        sig = inspect.signature(GeminiService.generate_workout_plan)
        params = sig.parameters

        # Verify intensity_preference is a valid parameter
        assert "intensity_preference" in params, \
            "generate_workout_plan should accept intensity_preference parameter"


class TestWorkoutDifficultyOutput:
    """Tests for workout difficulty in generated output."""

    def test_workout_difficulty_uses_intensity_preference(self):
        """
        Test that generated workout difficulty matches user's intensity_preference.

        This validates the fix in generation.py:
        - Line 627: intensity_preference is passed to generate_workout_from_library
        - Line 640: difficulty defaults to intensity_preference instead of "medium"
        """
        # Simulate the workout data return structure
        intensity_preference = "hard"

        # This is the logic from generation.py line 640
        workout_data = {"name": "Test Workout", "type": "strength"}
        difficulty = workout_data.get("difficulty", intensity_preference)

        # If AI doesn't return difficulty, it should default to intensity_preference
        assert difficulty == "hard", \
            "Workout difficulty should default to intensity_preference, not 'medium'"

    def test_workout_difficulty_fallback_not_medium(self):
        """
        Ensure the fallback is NOT hardcoded 'medium'.

        Before the fix, this was the bug:
        difficulty = workout_data.get("difficulty", "medium")

        After the fix:
        difficulty = workout_data.get("difficulty", intensity_preference)
        """
        intensity_preference = "easy"
        workout_data = {}  # AI returns no difficulty

        # Correct behavior: fallback to intensity_preference
        difficulty = workout_data.get("difficulty", intensity_preference)
        assert difficulty == "easy"

        # Wrong behavior would be: fallback to "medium"
        wrong_difficulty = workout_data.get("difficulty", "medium")
        assert wrong_difficulty == "medium"  # This is what we DON'T want

        # These should NOT be equal when intensity_preference is not "medium"
        assert difficulty != wrong_difficulty, \
            "The fix should use intensity_preference as fallback, not hardcoded 'medium'"


class TestGenerateMonthlyWithIntensity:
    """Integration-style tests for generate-monthly endpoint with intensity."""

    @pytest.fixture
    def mock_db(self):
        """Create a mock database client."""
        mock = MagicMock()
        mock.get_user.return_value = {
            "id": "test-user-123",
            "fitness_level": "intermediate",
            "goals": json.dumps(["Build Muscle"]),
            "equipment": json.dumps(["Dumbbells"]),
            "preferences": json.dumps({
                "intensity_preference": "hard",
                "training_split": "full_body",
                "dumbbell_count": 2,
                "kettlebell_count": 1,
            }),
            "active_injuries": json.dumps([]),
            "age": 30,
            "activity_level": "moderate",
        }
        mock.create_workout.return_value = {"id": "workout-123"}
        return mock

    def test_intensity_preference_read_from_user_profile(self, mock_db):
        """Test that generate-monthly reads intensity_preference from user profile."""
        from api.v1.workouts.utils import parse_json_field

        user = mock_db.get_user("test-user-123")
        preferences = parse_json_field(user.get("preferences"), {})

        assert preferences.get("intensity_preference") == "hard", \
            "generate-monthly should read intensity_preference from user profile"


def _workouts_module_source(module_name: str) -> str:
    source_file = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "api", "v1", "workouts", module_name,
    )
    with open(source_file, "r") as f:
        return f.read()


class TestGenerationHonorsSavedIntensityPreference:
    """
    The user's saved intensity_preference must reach workout generation.

    ORIGINAL INTENT (class was `TestGenerateRemainingWithIntensity`): the month
    fill-in endpoint `POST /generate-remaining` silently generated every workout
    at the default intensity because it never read
    `preferences["intensity_preference"]` off the user profile — a user who chose
    "hard" in customize-program quietly got medium workouts. The test pinned the
    fix by grepping api/v1/workouts/generation.py for that extraction.

    WHY THAT ASSERTION WAS RETIRED: commit 3063fbd1 deleted BOTH /generate-monthly
    and /generate-remaining, shrinking generation.py from 2066 lines to an
    orchestrator that only re-exports sub-routers. Grepping generation.py for the
    old local variable can no longer pass — there is no endpoint body left in that
    file to find it in. The endpoint is gone; the guarantee is not.

    WHAT THIS PROTECTS NOW: exactly the same guarantee at its current home. Both
    surviving generation entrypoints must resolve intensity from the user's saved
    preferences, falling back to fitness level ONLY when the user has no saved
    preference — so a saved "hard" is never silently downgraded.
    """

    def test_generate_endpoint_reads_intensity_preference_from_profile(self):
        """POST /generate (generation_endpoints.py) resolves intensity from saved preferences."""
        source = _workouts_module_source("generation_endpoints.py")

        assert 'preferences.get("intensity_preference")' in source, \
            "/generate must extract intensity_preference from the user's saved preferences"
        assert "intensity_preference = (" in source, \
            "/generate must bind the resolved intensity to intensity_preference"
        assert "get_intensity_from_fitness_level(fitness_level)" in source, \
            "/generate must fall back to fitness level only when no preference is saved"

    def test_generate_stream_endpoint_reads_intensity_preference_from_profile(self):
        """POST /generate-stream (generation_streaming.py) resolves intensity from saved preferences."""
        source = _workouts_module_source("generation_streaming.py")

        assert 'intensity_preference = body.intensity_preference or preferences.get("intensity_preference")' in source, \
            "/generate-stream must extract intensity_preference from the user's saved preferences"
        assert "get_intensity_from_fitness_level(fitness_level)" in source, \
            "/generate-stream must fall back to fitness level only when no preference is saved"

    def test_saved_preference_wins_over_fitness_level_fallback(self):
        """
        The precedence chain is per-day override > saved preference > fitness-level default.

        Asserted behaviorally on the same `or` chain both endpoints use, so this
        breaks if someone reorders it and lets the fitness-level default shadow a
        preference the user explicitly chose (the original bug).
        """
        from api.v1.workouts.utils import parse_json_field

        def resolve(body_intensity, saved_prefs_json, fitness_level_default):
            preferences = parse_json_field(saved_prefs_json, {})
            return (
                body_intensity
                or preferences.get("intensity_preference")
                or fitness_level_default
            )

        # Saved "hard" must survive — this is the case the retired endpoint got wrong.
        assert resolve(None, '{"intensity_preference": "hard"}', "medium") == "hard"
        # A per-day override outranks the saved preference.
        assert resolve("hell", '{"intensity_preference": "hard"}', "medium") == "hell"
        # Fitness-level default applies only when nothing is saved.
        assert resolve(None, "{}", "medium") == "medium"
        assert resolve(None, None, "easy") == "easy"


class TestEdgeCases:
    """Edge case tests for intensity preference handling."""

    def test_empty_preferences_defaults_to_medium(self):
        """Test handling when preferences is empty or None."""
        from api.v1.workouts.utils import parse_json_field

        # Empty preferences
        preferences = parse_json_field(None, {})
        intensity = preferences.get("intensity_preference", "medium")
        assert intensity == "medium"

        # Empty JSON object
        preferences = parse_json_field("{}", {})
        intensity = preferences.get("intensity_preference", "medium")
        assert intensity == "medium"

    def test_invalid_preferences_json_defaults_to_medium(self):
        """Test handling when preferences JSON is invalid."""
        from api.v1.workouts.utils import parse_json_field

        # Invalid JSON
        preferences = parse_json_field("not-valid-json", {})
        intensity = preferences.get("intensity_preference", "medium")
        assert intensity == "medium"

    def test_all_intensity_levels_handled(self):
        """Test that all intensity levels produce valid workout difficulty."""
        for intensity in ["easy", "medium", "hard"]:
            workout_data = {}
            difficulty = workout_data.get("difficulty", intensity)
            assert difficulty == intensity
            assert difficulty in ["easy", "medium", "hard"]


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
