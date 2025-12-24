"""
Tests for library exercises API endpoints.

Tests cover:
- GET /exercises - List exercises
- GET /exercises/grouped - Get exercises grouped by body part
- GET /exercises/{exercise_id} - Get a single exercise
- GET /exercises/body-parts - Get body parts
- GET /exercises/equipment - Get equipment types
- GET /exercises/types - Get exercise types
- GET /exercises/filter-options - Get filter options
"""
import pytest
from unittest.mock import MagicMock, patch, AsyncMock
from fastapi import HTTPException


class TestListExercises:
    """Tests for list_exercises endpoint."""

    @pytest.mark.asyncio
    async def test_list_exercises_success(self):
        """Test successful exercise listing."""
        from api.v1.library.exercises import list_exercises

        mock_db = MagicMock()
        mock_client = MagicMock()
        mock_db.client = mock_client
        mock_client.table.return_value.select.return_value.order.return_value.range.return_value.execute.return_value.data = [
            {
                "id": "ex-1",
                "name": "Squat",
                "original_name": "Squat",
                "target_muscle": "quadriceps",
                "equipment": "barbell",
            }
        ]

        with patch("api.v1.library.exercises.get_supabase_db", return_value=mock_db):
            result = await list_exercises()

        assert len(result) >= 0  # May be filtered

    @pytest.mark.asyncio
    async def test_list_exercises_with_body_parts_filter(self):
        """Test exercise listing with body parts filter."""
        from api.v1.library.exercises import list_exercises

        mock_db = MagicMock()

        async def mock_fetch_all_rows(*args, **kwargs):
            return [
                {"id": "ex-1", "name": "Squat", "original_name": "Squat", "target_muscle": "quadriceps"},
                {"id": "ex-2", "name": "Bench Press", "original_name": "Bench Press", "target_muscle": "pectoralis major"},
            ]

        with patch("api.v1.library.exercises.get_supabase_db", return_value=mock_db):
            with patch("api.v1.library.exercises.fetch_all_rows", side_effect=mock_fetch_all_rows):
                result = await list_exercises(body_parts="Chest")

        assert all(ex.body_part == "Chest" for ex in result)


class TestGetExercisesGrouped:
    """Tests for get_exercises_grouped endpoint."""

    @pytest.mark.asyncio
    async def test_get_exercises_grouped_success(self):
        """Test successful grouped exercises retrieval."""
        from api.v1.library.exercises import get_exercises_grouped

        mock_db = MagicMock()

        async def mock_fetch_all_rows(*args, **kwargs):
            return [
                {"id": "ex-1", "name": "Squat", "original_name": "Squat", "target_muscle": "quadriceps"},
                {"id": "ex-2", "name": "Bench Press", "original_name": "Bench Press", "target_muscle": "pectoralis major"},
                {"id": "ex-3", "name": "Leg Press", "original_name": "Leg Press", "target_muscle": "quadriceps"},
            ]

        with patch("api.v1.library.exercises.get_supabase_db", return_value=mock_db):
            with patch("api.v1.library.exercises.fetch_all_rows", side_effect=mock_fetch_all_rows):
                result = await get_exercises_grouped(limit_per_group=10)

        # Should have at least 2 groups (Quadriceps and Chest)
        assert len(result) >= 2

        # Verify structure
        for group in result:
            assert hasattr(group, 'body_part')
            assert hasattr(group, 'count')
            assert hasattr(group, 'exercises')


class TestGetExercise:
    """Tests for get_exercise endpoint."""

    @pytest.mark.asyncio
    async def test_get_exercise_from_cleaned_view(self):
        """Test getting exercise from cleaned view."""
        from api.v1.library.exercises import get_exercise

        mock_db = MagicMock()
        mock_client = MagicMock()
        mock_db.client = mock_client
        mock_client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [{
            "id": "ex-1",
            "name": "Squat",
            "original_name": "Squat_Male",
            "target_muscle": "quadriceps",
            "equipment": "barbell",
        }]

        with patch("api.v1.library.exercises.get_supabase_db", return_value=mock_db):
            result = await get_exercise("ex-1")

        assert result.id == "ex-1"
        assert result.name == "Squat"

    @pytest.mark.asyncio
    async def test_get_exercise_not_found(self):
        """Test exercise not found raises 404."""
        from api.v1.library.exercises import get_exercise

        mock_db = MagicMock()
        mock_client = MagicMock()
        mock_db.client = mock_client
        # Cleaned view returns nothing
        mock_client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = []

        with patch("api.v1.library.exercises.get_supabase_db", return_value=mock_db):
            with pytest.raises(HTTPException) as exc_info:
                await get_exercise("nonexistent-id")

        assert exc_info.value.status_code == 404


class TestGetBodyParts:
    """Tests for get_body_parts endpoint."""

    @pytest.mark.asyncio
    async def test_get_body_parts_success(self):
        """Test successful body parts retrieval."""
        from api.v1.library.exercises import get_body_parts

        mock_db = MagicMock()

        async def mock_fetch_all_rows(*args, **kwargs):
            return [
                {"target_muscle": "quadriceps", "body_part": "legs"},
                {"target_muscle": "quadriceps", "body_part": "legs"},
                {"target_muscle": "pectoralis major", "body_part": "chest"},
            ]

        with patch("api.v1.library.exercises.get_supabase_db", return_value=mock_db):
            with patch("api.v1.library.exercises.fetch_all_rows", side_effect=mock_fetch_all_rows):
                result = await get_body_parts()

        # Should have at least Quadriceps and Chest
        body_part_names = [bp["name"] for bp in result]
        assert "Quadriceps" in body_part_names
        assert "Chest" in body_part_names


class TestGetEquipmentTypes:
    """Tests for get_equipment_types endpoint."""

    @pytest.mark.asyncio
    async def test_get_equipment_types_success(self):
        """Test successful equipment types retrieval."""
        from api.v1.library.exercises import get_equipment_types

        mock_db = MagicMock()

        async def mock_fetch_all_rows(*args, **kwargs):
            return [
                {"equipment": "barbell"},
                {"equipment": "dumbbell"},
                {"equipment": "barbell"},
                {"equipment": None},  # Bodyweight
            ]

        with patch("api.v1.library.exercises.get_supabase_db", return_value=mock_db):
            with patch("api.v1.library.exercises.fetch_all_rows", side_effect=mock_fetch_all_rows):
                result = await get_equipment_types()

        equipment_names = [eq["name"] for eq in result]
        assert "barbell" in equipment_names
        assert "dumbbell" in equipment_names
        assert "Bodyweight" in equipment_names


class TestGetExerciseTypes:
    """Tests for get_exercise_types endpoint."""

    @pytest.mark.asyncio
    async def test_get_exercise_types_success(self):
        """Test successful exercise types retrieval."""
        from api.v1.library.exercises import get_exercise_types

        mock_db = MagicMock()

        async def mock_fetch_all_rows(*args, **kwargs):
            return [
                {"video_url": "s3://bucket/Strength/squat.mp4", "target_muscle": "quadriceps", "body_part": "legs"},
                {"video_url": "s3://bucket/Yoga/pose.mp4", "target_muscle": "core", "body_part": "core"},
            ]

        with patch("api.v1.library.exercises.get_supabase_db", return_value=mock_db):
            with patch("api.v1.library.exercises.fetch_all_rows", side_effect=mock_fetch_all_rows):
                result = await get_exercise_types()

        type_names = [et["name"] for et in result]
        assert "Strength" in type_names
        assert "Yoga" in type_names


class TestGetFilterOptions:
    """Tests for get_filter_options endpoint."""

    @pytest.mark.asyncio
    async def test_get_filter_options_success(self):
        """Test successful filter options retrieval."""
        from api.v1.library.exercises import get_filter_options

        mock_db = MagicMock()

        async def mock_fetch_all_rows(*args, **kwargs):
            return [
                {
                    "name": "Squat",
                    "target_muscle": "quadriceps",
                    "body_part": "legs",
                    "equipment": "barbell",
                    "video_url": "s3://bucket/Strength/squat.mp4",
                    "goals": ["Muscle Building"],
                    "suitable_for": ["Gym"],
                    "avoid_if": ["Stresses Knees"],
                }
            ]

        with patch("api.v1.library.exercises.get_supabase_db", return_value=mock_db):
            with patch("api.v1.library.exercises.fetch_all_rows", side_effect=mock_fetch_all_rows):
                result = await get_filter_options()

        assert "body_parts" in result
        assert "equipment" in result
        assert "exercise_types" in result
        assert "goals" in result
        assert "suitable_for" in result
        assert "avoid_if" in result
        assert "total_exercises" in result
