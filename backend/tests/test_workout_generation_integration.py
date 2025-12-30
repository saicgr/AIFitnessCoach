"""
Integration tests for workout generation with exercise preferences.

Tests that strength history, favorites, queue, and consistency mode
are properly integrated into the workout generation flow.
"""
import pytest
from unittest.mock import MagicMock, patch, AsyncMock
from datetime import datetime, timedelta


class TestStrengthHistoryIntegration:
    """Tests for strength history integration in workout generation."""

    @pytest.mark.asyncio
    @patch('services.workout_feedback_rag_service.get_workout_feedback_rag_service')
    async def test_get_user_strength_history_returns_dict(self, mock_get_rag):
        """Test that strength history returns properly formatted dict."""
        from api.v1.workouts.utils import get_user_strength_history

        # Mock the RAG service
        mock_rag = MagicMock()
        mock_rag.find_similar_exercise_sessions = AsyncMock(return_value=[
            {
                "metadata": {
                    "exercises": [
                        {"name": "Bench Press", "weight_kg": 70, "reps": 8},
                        {"name": "Squat", "weight_kg": 100, "reps": 6},
                    ]
                }
            },
            {
                "metadata": {
                    "exercises": [
                        {"name": "Bench Press", "weight_kg": 75, "reps": 6},
                    ]
                }
            }
        ])
        mock_get_rag.return_value = mock_rag

        result = await get_user_strength_history("test-user")

        # Should have both exercises
        assert "Bench Press" in result
        assert "Squat" in result

        # Bench Press should have max weight of 75 (from second session)
        assert result["Bench Press"]["max_weight_kg"] == 75
        assert result["Bench Press"]["last_weight_kg"] == 70  # First session

        # Squat data
        assert result["Squat"]["last_weight_kg"] == 100

    @pytest.mark.asyncio
    @patch('services.workout_feedback_rag_service.get_workout_feedback_rag_service')
    async def test_get_user_strength_history_handles_empty(self, mock_get_rag):
        """Test that empty history is handled gracefully."""
        from api.v1.workouts.utils import get_user_strength_history

        mock_rag = MagicMock()
        mock_rag.find_similar_exercise_sessions = AsyncMock(return_value=[])
        mock_get_rag.return_value = mock_rag

        result = await get_user_strength_history("test-user")

        assert result == {}

    @pytest.mark.asyncio
    @patch('services.workout_feedback_rag_service.get_workout_feedback_rag_service')
    async def test_get_user_strength_history_handles_error(self, mock_get_rag):
        """Test that errors return empty dict."""
        from api.v1.workouts.utils import get_user_strength_history

        mock_get_rag.side_effect = Exception("Connection failed")

        result = await get_user_strength_history("test-user")

        assert result == {}


class TestFavoritesIntegration:
    """Tests for favorite exercises integration in workout generation."""

    @pytest.mark.asyncio
    @patch('api.v1.workouts.utils.get_supabase_db')
    async def test_get_user_favorite_exercises_returns_list(self, mock_get_db):
        """Test that favorites returns list of exercise names."""
        from api.v1.workouts.utils import get_user_favorite_exercises

        mock_db = MagicMock()
        mock_db.client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
            {"exercise_name": "Bench Press"},
            {"exercise_name": "Deadlift"},
            {"exercise_name": "Pull-up"},
        ]
        mock_get_db.return_value = mock_db

        result = await get_user_favorite_exercises("test-user")

        assert len(result) == 3
        assert "Bench Press" in result
        assert "Deadlift" in result
        assert "Pull-up" in result

    @pytest.mark.asyncio
    @patch('api.v1.workouts.utils.get_supabase_db')
    async def test_get_user_favorite_exercises_empty(self, mock_get_db):
        """Test that empty favorites returns empty list."""
        from api.v1.workouts.utils import get_user_favorite_exercises

        mock_db = MagicMock()
        mock_db.client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = []
        mock_get_db.return_value = mock_db

        result = await get_user_favorite_exercises("test-user")

        assert result == []


class TestConsistencyModeIntegration:
    """Tests for consistency mode integration in workout generation."""

    @pytest.mark.asyncio
    @patch('api.v1.workouts.utils.get_supabase_db')
    async def test_get_consistency_mode_vary(self, mock_get_db):
        """Test that vary mode is returned correctly."""
        from api.v1.workouts.utils import get_user_consistency_mode

        mock_db = MagicMock()
        mock_db.get_user.return_value = {
            "id": "test-user",
            "preferences": {"exercise_consistency": "vary"}
        }
        mock_get_db.return_value = mock_db

        result = await get_user_consistency_mode("test-user")

        assert result == "vary"

    @pytest.mark.asyncio
    @patch('api.v1.workouts.utils.get_supabase_db')
    async def test_get_consistency_mode_consistent(self, mock_get_db):
        """Test that consistent mode is returned correctly."""
        from api.v1.workouts.utils import get_user_consistency_mode

        mock_db = MagicMock()
        mock_db.get_user.return_value = {
            "id": "test-user",
            "preferences": {"exercise_consistency": "consistent"}
        }
        mock_get_db.return_value = mock_db

        result = await get_user_consistency_mode("test-user")

        assert result == "consistent"

    @pytest.mark.asyncio
    @patch('api.v1.workouts.utils.get_supabase_db')
    async def test_get_consistency_mode_default_vary(self, mock_get_db):
        """Test that default is vary when not set."""
        from api.v1.workouts.utils import get_user_consistency_mode

        mock_db = MagicMock()
        mock_db.get_user.return_value = {
            "id": "test-user",
            "preferences": {}  # No consistency setting
        }
        mock_get_db.return_value = mock_db

        result = await get_user_consistency_mode("test-user")

        assert result == "vary"

    @pytest.mark.asyncio
    @patch('api.v1.workouts.utils.get_supabase_db')
    async def test_get_consistency_mode_handles_json_string(self, mock_get_db):
        """Test that JSON string preferences are parsed."""
        from api.v1.workouts.utils import get_user_consistency_mode

        mock_db = MagicMock()
        mock_db.get_user.return_value = {
            "id": "test-user",
            "preferences": '{"exercise_consistency": "consistent"}'  # JSON string
        }
        mock_get_db.return_value = mock_db

        result = await get_user_consistency_mode("test-user")

        assert result == "consistent"


class TestExerciseQueueIntegration:
    """Tests for exercise queue integration in workout generation."""

    @pytest.mark.asyncio
    @patch('api.v1.workouts.utils.get_supabase_db')
    async def test_get_exercise_queue_returns_list(self, mock_get_db):
        """Test that queue returns list of exercise dicts."""
        from api.v1.workouts.utils import get_user_exercise_queue

        future_date = (datetime.now() + timedelta(days=5)).isoformat()

        mock_db = MagicMock()
        query_mock = MagicMock()
        mock_db.client.table.return_value.select.return_value.eq.return_value.is_.return_value.gte.return_value = query_mock
        query_mock.order.return_value.execute.return_value.data = [
            {
                "id": "q1",
                "exercise_name": "Lat Pulldown",
                "exercise_id": None,
                "priority": 0,
                "target_muscle_group": "back",
            },
            {
                "id": "q2",
                "exercise_name": "Bicep Curl",
                "exercise_id": "ex-123",
                "priority": 1,
                "target_muscle_group": "arms",
            }
        ]
        mock_get_db.return_value = mock_db

        result = await get_user_exercise_queue("test-user")

        assert len(result) == 2
        assert result[0]["name"] == "Lat Pulldown"
        assert result[1]["name"] == "Bicep Curl"

    @pytest.mark.asyncio
    @patch('api.v1.workouts.utils.get_supabase_db')
    async def test_get_exercise_queue_filters_by_focus(self, mock_get_db):
        """Test that queue filters by focus area."""
        from api.v1.workouts.utils import get_user_exercise_queue

        mock_db = MagicMock()
        query_mock = MagicMock()
        mock_db.client.table.return_value.select.return_value.eq.return_value.is_.return_value.gte.return_value = query_mock
        query_mock.order.return_value.execute.return_value.data = [
            {
                "id": "q1",
                "exercise_name": "Lat Pulldown",
                "exercise_id": None,
                "priority": 0,
                "target_muscle_group": "back",
            },
            {
                "id": "q2",
                "exercise_name": "Bicep Curl",
                "exercise_id": None,
                "priority": 1,
                "target_muscle_group": "arms",
            }
        ]
        mock_get_db.return_value = mock_db

        # Filter to only back exercises
        result = await get_user_exercise_queue("test-user", focus_area="back")

        assert len(result) == 1
        assert result[0]["name"] == "Lat Pulldown"

    @pytest.mark.asyncio
    @patch('api.v1.workouts.utils.get_supabase_db')
    async def test_get_exercise_queue_empty(self, mock_get_db):
        """Test that empty queue returns empty list."""
        from api.v1.workouts.utils import get_user_exercise_queue

        mock_db = MagicMock()
        query_mock = MagicMock()
        mock_db.client.table.return_value.select.return_value.eq.return_value.is_.return_value.gte.return_value = query_mock
        query_mock.order.return_value.execute.return_value.data = []
        mock_get_db.return_value = mock_db

        result = await get_user_exercise_queue("test-user")

        assert result == []


class TestExerciseRAGWithPreferences:
    """Tests for exercise RAG service using preferences."""

    def test_format_exercise_uses_historical_weight(self):
        """Test that historical weight is used over generic estimate."""
        from services.exercise_rag.service import ExerciseRAGService

        # Create a mock service
        service = ExerciseRAGService.__new__(ExerciseRAGService)

        exercise = {
            "name": "Bench Press",
            "equipment": "barbell",
            "target_muscle": "chest",
            "body_part": "chest",
        }

        strength_history = {
            "Bench Press": {
                "last_weight_kg": 80,
                "max_weight_kg": 90,
                "last_reps": 8
            }
        }

        result = service._format_exercise_for_workout(
            exercise=exercise,
            fitness_level="intermediate",
            workout_params=None,
            strength_history=strength_history
        )

        # Should use historical weight of 80kg, not generic estimate
        assert result["weight_kg"] == 80
        assert result["weight_source"] == "historical"

    def test_format_exercise_falls_back_to_generic(self):
        """Test that generic weight is used when no history."""
        from services.exercise_rag.service import ExerciseRAGService

        service = ExerciseRAGService.__new__(ExerciseRAGService)

        exercise = {
            "name": "Bench Press",
            "equipment": "barbell",
            "target_muscle": "chest",
            "body_part": "chest",
        }

        result = service._format_exercise_for_workout(
            exercise=exercise,
            fitness_level="intermediate",
            workout_params=None,
            strength_history=None  # No history
        )

        # Should use generic weight
        assert result["weight_kg"] > 0
        assert result["weight_source"] == "generic"


class TestGeminiWorkoutFromLibrary:
    """Tests for Gemini workout generation from library exercises."""

    @pytest.mark.asyncio
    async def test_generate_workout_preserves_exercise_weights(self):
        """Test that Gemini doesn't override exercise weights from RAG."""
        from services.gemini_service import GeminiService

        # The key is that generate_workout_from_library returns exercises as-is
        # We verify this by checking the function signature and return value

        exercises = [
            {
                "name": "Bench Press",
                "sets": 3,
                "reps": 10,
                "weight_kg": 80,  # From historical data
                "weight_source": "historical",
                "equipment": "barbell",
                "muscle_group": "chest",
            },
            {
                "name": "Squat",
                "sets": 4,
                "reps": 8,
                "weight_kg": 100,  # From historical data
                "weight_source": "historical",
                "equipment": "barbell",
                "muscle_group": "legs",
            }
        ]

        # Mock the Gemini response (only workout name, not exercises)
        with patch('services.gemini_service.client') as mock_client:
            mock_response = MagicMock()
            mock_response.text = '{"name": "Power Chest Day", "type": "strength", "notes": "Focus on form"}'
            mock_client.aio.models.generate_content = AsyncMock(return_value=mock_response)

            service = GeminiService()
            result = await service.generate_workout_from_library(
                exercises=exercises,
                fitness_level="intermediate",
                goals=["build_muscle"],
                duration_minutes=45,
                focus_areas=["chest"]
            )

            # Verify exercises are passed through unchanged
            assert result["exercises"] == exercises
            assert result["exercises"][0]["weight_kg"] == 80
            assert result["exercises"][1]["weight_kg"] == 100

            # Verify AI generated the name
            assert result["name"] == "Power Chest Day"
