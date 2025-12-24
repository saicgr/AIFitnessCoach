"""
Tests for library programs API endpoints.

Tests cover:
- GET /programs - List programs
- GET /programs/grouped - Get programs grouped by category
- GET /programs/{program_id} - Get a single program
- GET /programs/categories - Get program categories
"""
import pytest
from unittest.mock import MagicMock, patch
from fastapi import HTTPException


class TestListPrograms:
    """Tests for list_programs endpoint."""

    @pytest.mark.asyncio
    async def test_list_programs_success(self):
        """Test successful program listing."""
        from api.v1.library.programs import list_programs

        mock_db = MagicMock()
        mock_client = MagicMock()
        mock_db.client = mock_client
        mock_client.table.return_value.select.return_value.order.return_value.range.return_value.execute.return_value.data = [
            {
                "id": "prog-1",
                "program_name": "Strength Builder",
                "program_category": "Strength Training",
                "duration_weeks": 8,
            }
        ]

        with patch("api.v1.library.programs.get_supabase_db", return_value=mock_db):
            result = await list_programs()

        assert len(result) == 1
        assert result[0].name == "Strength Builder"

    @pytest.mark.asyncio
    async def test_list_programs_with_category_filter(self):
        """Test program listing with category filter."""
        from api.v1.library.programs import list_programs

        mock_db = MagicMock()
        mock_client = MagicMock()
        mock_db.client = mock_client
        mock_client.table.return_value.select.return_value.eq.return_value.order.return_value.range.return_value.execute.return_value.data = [
            {
                "id": "prog-1",
                "program_name": "HIIT Blast",
                "program_category": "Cardio",
            }
        ]

        with patch("api.v1.library.programs.get_supabase_db", return_value=mock_db):
            result = await list_programs(category="Cardio")

        assert len(result) == 1
        assert result[0].category == "Cardio"

    @pytest.mark.asyncio
    async def test_list_programs_with_search(self):
        """Test program listing with search filter."""
        from api.v1.library.programs import list_programs

        mock_db = MagicMock()
        mock_client = MagicMock()
        mock_db.client = mock_client
        mock_client.table.return_value.select.return_value.ilike.return_value.order.return_value.range.return_value.execute.return_value.data = [
            {
                "id": "prog-1",
                "program_name": "Arnold Classic",
                "program_category": "Celebrity",
            }
        ]

        with patch("api.v1.library.programs.get_supabase_db", return_value=mock_db):
            result = await list_programs(search="Arnold")

        assert len(result) == 1
        assert "Arnold" in result[0].name


class TestGetProgramsGrouped:
    """Tests for get_programs_grouped endpoint."""

    @pytest.mark.asyncio
    async def test_get_programs_grouped_success(self):
        """Test successful grouped programs retrieval."""
        from api.v1.library.programs import get_programs_grouped

        mock_db = MagicMock()
        mock_client = MagicMock()
        mock_db.client = mock_client
        mock_client.table.return_value.select.return_value.execute.return_value.data = [
            {"id": "prog-1", "program_name": "HIIT 1", "program_category": "Cardio"},
            {"id": "prog-2", "program_name": "HIIT 2", "program_category": "Cardio"},
            {"id": "prog-3", "program_name": "Strength 1", "program_category": "Strength Training"},
        ]

        with patch("api.v1.library.programs.get_supabase_db", return_value=mock_db):
            result = await get_programs_grouped(limit_per_group=10)

        # Should have 2 categories
        assert len(result) == 2

        categories = [g.category for g in result]
        assert "Cardio" in categories
        assert "Strength Training" in categories


class TestGetProgram:
    """Tests for get_program endpoint."""

    @pytest.mark.asyncio
    async def test_get_program_success(self):
        """Test successful program retrieval."""
        from api.v1.library.programs import get_program

        mock_db = MagicMock()
        mock_client = MagicMock()
        mock_db.client = mock_client
        mock_client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [{
            "id": "prog-1",
            "program_name": "Strength Builder",
            "program_category": "Strength Training",
            "duration_weeks": 8,
            "sessions_per_week": 4,
            "workouts": [{"week": 1, "day": 1, "exercises": []}],
        }]

        with patch("api.v1.library.programs.get_supabase_db", return_value=mock_db):
            result = await get_program("prog-1")

        assert result["id"] == "prog-1"
        assert result["name"] == "Strength Builder"
        assert "workouts" in result

    @pytest.mark.asyncio
    async def test_get_program_not_found(self):
        """Test program not found raises 404."""
        from api.v1.library.programs import get_program

        mock_db = MagicMock()
        mock_client = MagicMock()
        mock_db.client = mock_client
        mock_client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = []

        with patch("api.v1.library.programs.get_supabase_db", return_value=mock_db):
            with pytest.raises(HTTPException) as exc_info:
                await get_program("nonexistent-id")

        assert exc_info.value.status_code == 404


class TestGetProgramCategories:
    """Tests for get_program_categories endpoint."""

    @pytest.mark.asyncio
    async def test_get_program_categories_success(self):
        """Test successful program categories retrieval."""
        from api.v1.library.programs import get_program_categories

        mock_db = MagicMock()
        mock_client = MagicMock()
        mock_db.client = mock_client
        mock_client.table.return_value.select.return_value.execute.return_value.data = [
            {"program_category": "Cardio"},
            {"program_category": "Cardio"},
            {"program_category": "Strength Training"},
            {"program_category": "Celebrity Workout"},
        ]

        with patch("api.v1.library.programs.get_supabase_db", return_value=mock_db):
            result = await get_program_categories()

        # Should have 3 unique categories
        assert len(result) == 3

        category_names = [cat["name"] for cat in result]
        assert "Cardio" in category_names
        assert "Strength Training" in category_names
        assert "Celebrity Workout" in category_names

        # Cardio should have highest count
        cardio_cat = next(cat for cat in result if cat["name"] == "Cardio")
        assert cardio_cat["count"] == 2

    @pytest.mark.asyncio
    async def test_get_program_categories_empty(self):
        """Test empty program categories."""
        from api.v1.library.programs import get_program_categories

        mock_db = MagicMock()
        mock_client = MagicMock()
        mock_db.client = mock_client
        mock_client.table.return_value.select.return_value.execute.return_value.data = []

        with patch("api.v1.library.programs.get_supabase_db", return_value=mock_db):
            result = await get_program_categories()

        assert result == []
