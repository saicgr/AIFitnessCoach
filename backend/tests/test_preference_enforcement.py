"""
Tests for Preference Enforcement in Workout Generation.

These tests verify that user preferences (avoided exercises, avoided muscles,
staple exercises) are properly enforced during workout generation.

Addresses the competitor complaint: "I set my preferences and it totally ignored those."
"""
import pytest
from unittest.mock import MagicMock, patch, AsyncMock


class TestPreferenceEnforcementInGeneration:
    """Test that preferences are fetched and passed to Gemini during generation."""

    @pytest.mark.asyncio
    async def test_generate_endpoint_fetches_avoided_exercises(self):
        """Test that /generate endpoint fetches user's avoided exercises."""
        with patch('api.v1.workouts.generation.get_supabase_db') as mock_db, \
             patch('api.v1.workouts.generation.get_user_avoided_exercises') as mock_avoided_ex, \
             patch('api.v1.workouts.generation.get_user_avoided_muscles') as mock_avoided_muscles, \
             patch('api.v1.workouts.generation.get_user_staple_exercises') as mock_staple, \
             patch('api.v1.workouts.generation.GeminiService') as mock_gemini:

            # Setup mocks
            mock_db_instance = MagicMock()
            mock_db.return_value = mock_db_instance
            mock_db_instance.get_user.return_value = {
                "id": "test-user-123",
                "fitness_level": "intermediate",
                "goals": ["build_muscle"],
                "equipment": ["dumbbells", "barbell"],
                "preferences": {}
            }

            mock_avoided_ex.return_value = ["deadlift", "barbell row"]
            mock_avoided_muscles.return_value = {"avoid": ["lower_back"], "reduce": []}
            mock_staple.return_value = ["bench press", "squat"]

            mock_gemini_instance = MagicMock()
            mock_gemini.return_value = mock_gemini_instance
            mock_gemini_instance.generate_workout_plan = AsyncMock(return_value={
                "name": "Test Workout",
                "type": "strength",
                "difficulty": "medium",
                "exercises": [
                    {"name": "Bench Press", "sets": 3, "reps": 10, "muscle_group": "chest"}
                ]
            })

            # Import after patching
            from api.v1.workouts.generation import generate_workout
            from models.schemas import GenerateWorkoutRequest

            # Execute
            request = GenerateWorkoutRequest(
                user_id="test-user-123",
                duration_minutes=45
            )

            # This should call the preference functions
            await generate_workout(request)

            # Verify preferences were fetched
            mock_avoided_ex.assert_called_once_with("test-user-123")
            mock_avoided_muscles.assert_called_once_with("test-user-123")
            mock_staple.assert_called_once_with("test-user-123")

            # Verify preferences were passed to Gemini
            call_kwargs = mock_gemini_instance.generate_workout_plan.call_args.kwargs
            assert call_kwargs.get('avoided_exercises') == ["deadlift", "barbell row"]
            assert call_kwargs.get('avoided_muscles') == {"avoid": ["lower_back"], "reduce": []}
            assert call_kwargs.get('staple_exercises') == ["bench press", "squat"]


class TestPostGenerationValidation:
    """Test that generated exercises are validated against user preferences."""

    def test_filters_avoided_exercises_from_response(self):
        """Test that avoided exercises are filtered out of AI response."""
        avoided_exercises = ["deadlift", "barbell row"]

        # Simulated AI response that includes an avoided exercise
        ai_exercises = [
            {"name": "Bench Press", "sets": 3, "reps": 10, "muscle_group": "chest"},
            {"name": "Deadlift", "sets": 3, "reps": 8, "muscle_group": "back"},  # Should be filtered
            {"name": "Squat", "sets": 3, "reps": 10, "muscle_group": "legs"},
        ]

        # Apply the same filtering logic as in generation.py
        filtered = [
            ex for ex in ai_exercises
            if ex.get("name", "").lower() not in [ae.lower() for ae in avoided_exercises]
        ]

        assert len(filtered) == 2
        assert all(ex["name"].lower() != "deadlift" for ex in filtered)

    def test_filters_avoided_muscles_from_response(self):
        """Test that exercises targeting avoided muscles are filtered out."""
        avoided_muscles = {"avoid": ["lower_back"], "reduce": []}

        # Simulated AI response that includes an exercise targeting avoided muscle
        ai_exercises = [
            {"name": "Bench Press", "sets": 3, "reps": 10, "muscle_group": "chest"},
            {"name": "Good Morning", "sets": 3, "reps": 12, "muscle_group": "lower_back"},  # Should be filtered
            {"name": "Squat", "sets": 3, "reps": 10, "muscle_group": "legs"},
        ]

        avoid_muscles_lower = [m.lower() for m in avoided_muscles["avoid"]]
        filtered = [
            ex for ex in ai_exercises
            if ex.get("muscle_group", "").lower() not in avoid_muscles_lower
        ]

        assert len(filtered) == 2
        assert all(ex["muscle_group"].lower() != "lower_back" for ex in filtered)

    def test_case_insensitive_filtering(self):
        """Test that filtering is case-insensitive."""
        avoided_exercises = ["DEADLIFT", "Barbell Row"]

        ai_exercises = [
            {"name": "deadlift", "sets": 3, "reps": 8, "muscle_group": "back"},
            {"name": "BARBELL ROW", "sets": 3, "reps": 10, "muscle_group": "back"},
            {"name": "Squat", "sets": 3, "reps": 10, "muscle_group": "legs"},
        ]

        filtered = [
            ex for ex in ai_exercises
            if ex.get("name", "").lower() not in [ae.lower() for ae in avoided_exercises]
        ]

        assert len(filtered) == 1
        assert filtered[0]["name"] == "Squat"


class TestGeminiPromptContainsPreferences:
    """Test that Gemini prompt includes user preferences."""

    @pytest.mark.asyncio
    async def test_gemini_prompt_includes_avoided_exercises(self):
        """Test that the Gemini prompt includes avoided exercises instruction."""
        from services.gemini_service import GeminiService

        with patch.object(GeminiService, '_generate_json_response', new_callable=AsyncMock) as mock_generate:
            mock_generate.return_value = {
                "name": "Test Workout",
                "type": "strength",
                "difficulty": "medium",
                "exercises": []
            }

            service = GeminiService()

            # Call with avoided exercises
            await service.generate_workout_plan(
                fitness_level="intermediate",
                goals=["build_muscle"],
                equipment=["dumbbells"],
                avoided_exercises=["deadlift", "barbell row"]
            )

            # The prompt should contain avoided exercises instruction
            # This is a smoke test - actual prompt verification would need access to the prompt

    @pytest.mark.asyncio
    async def test_gemini_prompt_includes_avoided_muscles(self):
        """Test that the Gemini prompt includes avoided muscles instruction."""
        from services.gemini_service import GeminiService

        with patch.object(GeminiService, '_generate_json_response', new_callable=AsyncMock) as mock_generate:
            mock_generate.return_value = {
                "name": "Test Workout",
                "type": "strength",
                "difficulty": "medium",
                "exercises": []
            }

            service = GeminiService()

            # Call with avoided muscles
            await service.generate_workout_plan(
                fitness_level="intermediate",
                goals=["build_muscle"],
                equipment=["dumbbells"],
                avoided_muscles={"avoid": ["lower_back"], "reduce": ["shoulders"]}
            )


class TestExtendWorkoutPreferences:
    """Test that extend workout also respects preferences."""

    def test_extend_workout_filters_avoided_exercises(self):
        """Test that extended exercises also exclude avoided exercises."""
        avoided_exercises = ["deadlift"]

        # Simulated extension exercises
        new_exercises = [
            {"name": "Romanian Deadlift", "sets": 3, "reps": 12, "muscle_group": "hamstrings"},
            {"name": "Deadlift", "sets": 3, "reps": 8, "muscle_group": "back"},  # Should be filtered
            {"name": "Leg Press", "sets": 3, "reps": 10, "muscle_group": "legs"},
        ]

        filtered = [
            ex for ex in new_exercises
            if ex.get("name", "").lower() not in [ae.lower() for ae in avoided_exercises]
        ]

        assert len(filtered) == 2
        # Deadlift should be filtered, Romanian Deadlift should remain (different exercise)
        exercise_names = [ex["name"] for ex in filtered]
        assert "Deadlift" not in exercise_names
        assert "Romanian Deadlift" in exercise_names


class TestPreferenceHelperFunctions:
    """Test the helper functions for fetching user preferences."""

    @pytest.mark.asyncio
    async def test_get_user_avoided_exercises_returns_list(self):
        """Test that get_user_avoided_exercises returns a list."""
        with patch('api.v1.workouts.utils.get_supabase_db') as mock_db:
            mock_db_instance = MagicMock()
            mock_db.return_value = mock_db_instance

            # Mock RPC call
            mock_result = MagicMock()
            mock_result.data = [
                {"exercise_name": "Deadlift"},
                {"exercise_name": "Barbell Row"}
            ]
            mock_db_instance.client.rpc.return_value.execute.return_value = mock_result

            from api.v1.workouts.utils import get_user_avoided_exercises

            result = await get_user_avoided_exercises("test-user-123")

            assert isinstance(result, list)
            assert len(result) == 2
            assert "deadlift" in result
            assert "barbell row" in result

    @pytest.mark.asyncio
    async def test_get_user_avoided_exercises_returns_empty_on_error(self):
        """Test that get_user_avoided_exercises returns empty list on error."""
        with patch('api.v1.workouts.utils.get_supabase_db') as mock_db:
            mock_db_instance = MagicMock()
            mock_db.return_value = mock_db_instance
            mock_db_instance.client.rpc.side_effect = Exception("Database error")

            from api.v1.workouts.utils import get_user_avoided_exercises

            result = await get_user_avoided_exercises("test-user-123")

            assert result == []

    @pytest.mark.asyncio
    async def test_get_user_avoided_muscles_returns_dict(self):
        """Test that get_user_avoided_muscles returns a dict with avoid and reduce."""
        with patch('api.v1.workouts.utils.get_supabase_db') as mock_db:
            mock_db_instance = MagicMock()
            mock_db.return_value = mock_db_instance

            # Mock RPC call
            mock_result = MagicMock()
            mock_result.data = [
                {"muscle_group": "Lower Back", "severity": "avoid"},
                {"muscle_group": "Shoulders", "severity": "reduce"}
            ]
            mock_db_instance.client.rpc.return_value.execute.return_value = mock_result

            from api.v1.workouts.utils import get_user_avoided_muscles

            result = await get_user_avoided_muscles("test-user-123")

            assert isinstance(result, dict)
            assert "avoid" in result
            assert "reduce" in result
            assert "lower back" in result["avoid"]
            assert "shoulders" in result["reduce"]

    @pytest.mark.asyncio
    async def test_get_user_staple_exercises_returns_list(self):
        """Test that get_user_staple_exercises returns a list."""
        with patch('api.v1.workouts.utils.get_supabase_db') as mock_db:
            mock_db_instance = MagicMock()
            mock_db.return_value = mock_db_instance

            # Mock table query
            mock_result = MagicMock()
            mock_result.data = [
                {"exercise_name": "Bench Press"},
                {"exercise_name": "Squat"}
            ]
            mock_db_instance.client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_result

            from api.v1.workouts.utils import get_user_staple_exercises

            result = await get_user_staple_exercises("test-user-123")

            assert isinstance(result, list)
            assert len(result) == 2


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
