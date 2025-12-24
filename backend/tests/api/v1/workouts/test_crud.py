"""
Tests for workouts CRUD API endpoints.

Tests cover:
- POST / - Create workout
- GET / - List workouts
- GET /{id} - Get workout by ID
- PUT /{id} - Update workout
- DELETE /{id} - Delete workout
- POST /{id}/complete - Complete workout
"""
import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from datetime import datetime
from fastapi import HTTPException


class TestCreateWorkout:
    """Tests for create_workout endpoint."""

    @pytest.mark.asyncio
    async def test_create_workout_success(self):
        """Test successful workout creation."""
        from api.v1.workouts.crud import create_workout
        from models.schemas import WorkoutCreate

        mock_db = MagicMock()
        mock_db.create_workout.return_value = {
            "id": "new-workout-id",
            "user_id": "user-1",
            "name": "Test Workout",
            "type": "strength",
            "difficulty": "medium",
            "scheduled_date": "2024-01-15",
            "exercises_json": [{"name": "Squat"}],
            "duration_minutes": 45,
            "is_completed": False,
        }

        workout_create = WorkoutCreate(
            user_id="user-1",
            name="Test Workout",
            type="strength",
            difficulty="medium",
            scheduled_date="2024-01-15",
            exercises_json='[{"name": "Squat"}]',
            duration_minutes=45,
        )

        with patch("api.v1.workouts.crud.get_supabase_db", return_value=mock_db):
            with patch("api.v1.workouts.crud.index_workout_to_rag", new_callable=AsyncMock):
                result = await create_workout(workout_create)

        assert result.id == "new-workout-id"
        assert result.name == "Test Workout"
        mock_db.create_workout.assert_called_once()

    @pytest.mark.asyncio
    async def test_create_workout_with_exercises_string(self):
        """Test workout creation with exercises as JSON string."""
        from api.v1.workouts.crud import create_workout
        from models.schemas import WorkoutCreate

        mock_db = MagicMock()
        mock_db.create_workout.return_value = {
            "id": "new-id",
            "user_id": "user-1",
            "name": "Test",
            "type": "strength",
            "difficulty": "medium",
            "scheduled_date": "2024-01-15",
            "exercises_json": [{"name": "Push-ups"}],
            "duration_minutes": 30,
        }

        workout_create = WorkoutCreate(
            user_id="user-1",
            name="Test",
            type="strength",
            difficulty="medium",
            scheduled_date="2024-01-15",
            exercises_json='[{"name": "Push-ups"}]',
            duration_minutes=30,
        )

        with patch("api.v1.workouts.crud.get_supabase_db", return_value=mock_db):
            with patch("api.v1.workouts.crud.index_workout_to_rag", new_callable=AsyncMock):
                result = await create_workout(workout_create)

        assert result.name == "Test"


class TestListWorkouts:
    """Tests for list_workouts endpoint."""

    @pytest.mark.asyncio
    async def test_list_workouts_success(self):
        """Test successful workout listing."""
        from api.v1.workouts.crud import list_workouts

        mock_db = MagicMock()
        mock_db.list_workouts.return_value = [
            {
                "id": "workout-1",
                "user_id": "user-1",
                "name": "Workout 1",
                "type": "strength",
                "difficulty": "medium",
                "scheduled_date": "2024-01-15",
            },
            {
                "id": "workout-2",
                "user_id": "user-1",
                "name": "Workout 2",
                "type": "cardio",
                "difficulty": "hard",
                "scheduled_date": "2024-01-16",
            },
        ]

        with patch("api.v1.workouts.crud.get_supabase_db", return_value=mock_db):
            result = await list_workouts(user_id="user-1")

        assert len(result) == 2
        assert result[0].name == "Workout 1"
        assert result[1].name == "Workout 2"

    @pytest.mark.asyncio
    async def test_list_workouts_with_filters(self):
        """Test workout listing with filters."""
        from api.v1.workouts.crud import list_workouts

        mock_db = MagicMock()
        mock_db.list_workouts.return_value = []

        with patch("api.v1.workouts.crud.get_supabase_db", return_value=mock_db):
            result = await list_workouts(
                user_id="user-1",
                is_completed=False,
                from_date=datetime(2024, 1, 1),
                limit=10
            )

        assert result == []
        mock_db.list_workouts.assert_called_once()


class TestGetWorkout:
    """Tests for get_workout endpoint."""

    @pytest.mark.asyncio
    async def test_get_workout_success(self):
        """Test successful workout retrieval."""
        from api.v1.workouts.crud import get_workout

        mock_db = MagicMock()
        mock_db.get_workout.return_value = {
            "id": "workout-1",
            "user_id": "user-1",
            "name": "Test Workout",
            "type": "strength",
            "difficulty": "medium",
            "scheduled_date": "2024-01-15",
        }

        with patch("api.v1.workouts.crud.get_supabase_db", return_value=mock_db):
            result = await get_workout("workout-1")

        assert result.id == "workout-1"
        assert result.name == "Test Workout"

    @pytest.mark.asyncio
    async def test_get_workout_not_found(self):
        """Test workout not found raises 404."""
        from api.v1.workouts.crud import get_workout

        mock_db = MagicMock()
        mock_db.get_workout.return_value = None

        with patch("api.v1.workouts.crud.get_supabase_db", return_value=mock_db):
            with pytest.raises(HTTPException) as exc_info:
                await get_workout("nonexistent-id")

        assert exc_info.value.status_code == 404


class TestUpdateWorkout:
    """Tests for update_workout endpoint."""

    @pytest.mark.asyncio
    async def test_update_workout_success(self):
        """Test successful workout update."""
        from api.v1.workouts.crud import update_workout
        from models.schemas import WorkoutUpdate

        mock_db = MagicMock()
        mock_db.get_workout.return_value = {
            "id": "workout-1",
            "user_id": "user-1",
            "name": "Old Name",
            "type": "strength",
            "difficulty": "medium",
            "scheduled_date": "2024-01-15",
        }
        mock_db.update_workout.return_value = {
            "id": "workout-1",
            "user_id": "user-1",
            "name": "New Name",
            "type": "strength",
            "difficulty": "medium",
            "scheduled_date": "2024-01-15",
        }

        update_data = WorkoutUpdate(name="New Name")

        with patch("api.v1.workouts.crud.get_supabase_db", return_value=mock_db):
            with patch("api.v1.workouts.crud.index_workout_to_rag", new_callable=AsyncMock):
                result = await update_workout("workout-1", update_data)

        assert result.name == "New Name"

    @pytest.mark.asyncio
    async def test_update_workout_not_found(self):
        """Test update workout not found raises 404."""
        from api.v1.workouts.crud import update_workout
        from models.schemas import WorkoutUpdate

        mock_db = MagicMock()
        mock_db.get_workout.return_value = None

        with patch("api.v1.workouts.crud.get_supabase_db", return_value=mock_db):
            with pytest.raises(HTTPException) as exc_info:
                await update_workout("nonexistent-id", WorkoutUpdate(name="Test"))

        assert exc_info.value.status_code == 404


class TestDeleteWorkout:
    """Tests for delete_workout endpoint."""

    @pytest.mark.asyncio
    async def test_delete_workout_success(self):
        """Test successful workout deletion."""
        from api.v1.workouts.crud import delete_workout

        mock_db = MagicMock()
        mock_db.get_workout.return_value = {
            "id": "workout-1",
            "user_id": "user-1",
        }

        with patch("api.v1.workouts.crud.get_supabase_db", return_value=mock_db):
            result = await delete_workout("workout-1")

        assert result["message"] == "Workout deleted successfully"
        mock_db.delete_workout.assert_called_once()

    @pytest.mark.asyncio
    async def test_delete_workout_not_found(self):
        """Test delete workout not found raises 404."""
        from api.v1.workouts.crud import delete_workout

        mock_db = MagicMock()
        mock_db.get_workout.return_value = None

        with patch("api.v1.workouts.crud.get_supabase_db", return_value=mock_db):
            with pytest.raises(HTTPException) as exc_info:
                await delete_workout("nonexistent-id")

        assert exc_info.value.status_code == 404


class TestCompleteWorkout:
    """Tests for complete_workout endpoint."""

    @pytest.mark.asyncio
    async def test_complete_workout_success(self):
        """Test successful workout completion."""
        from api.v1.workouts.crud import complete_workout

        mock_db = MagicMock()
        mock_db.get_workout.return_value = {
            "id": "workout-1",
            "user_id": "user-1",
            "name": "Test",
            "type": "strength",
            "difficulty": "medium",
            "scheduled_date": "2024-01-15",
            "is_completed": False,
        }
        mock_db.update_workout.return_value = {
            "id": "workout-1",
            "user_id": "user-1",
            "name": "Test",
            "type": "strength",
            "difficulty": "medium",
            "scheduled_date": "2024-01-15",
            "is_completed": True,
        }

        with patch("api.v1.workouts.crud.get_supabase_db", return_value=mock_db):
            with patch("api.v1.workouts.crud.index_workout_to_rag", new_callable=AsyncMock):
                result = await complete_workout("workout-1")

        assert result.is_completed is True

    @pytest.mark.asyncio
    async def test_complete_workout_not_found(self):
        """Test complete workout not found raises 404."""
        from api.v1.workouts.crud import complete_workout

        mock_db = MagicMock()
        mock_db.get_workout.return_value = None

        with patch("api.v1.workouts.crud.get_supabase_db", return_value=mock_db):
            with pytest.raises(HTTPException) as exc_info:
                await complete_workout("nonexistent-id")

        assert exc_info.value.status_code == 404
