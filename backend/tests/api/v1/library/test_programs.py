"""
Tests for library programs API endpoints.

Tests cover:
- GET /programs - List programs
- GET /programs/grouped - Get programs grouped by category
- GET /programs/{program_id} - Get a single program
- GET /programs/categories - Get program categories

Two calling conventions these tests must respect (both are why they used to
fail — neither is a product bug):

1. Query-parameter sentinels. `list_programs` / `get_programs_grouped` declare
   their pagination args as `limit: int = Query(default=50, ...)`. Under a real
   request FastAPI substitutes the int; calling the coroutine DIRECTLY (as these
   unit tests do) leaves the `Query` object in place, so `offset + limit - 1`
   raised `TypeError: unsupported operand type(s) for +: 'Query' and 'Query'`.
   The tests therefore pass pagination explicitly.

2. The table is `branded_programs`, not the legacy `programs` table. Every
   handler filters `.eq("is_active", True)` before `.order()/.range()`, and the
   columns are `name`/`category` (see `row_to_library_program` in
   api/v1/library/utils.py, which documents the mapping). The old mocks chained
   `select().order().range()` with no `.eq()`, so `result.data` resolved to an
   auto-created MagicMock instead of the seeded list — which iterates EMPTY
   (MagicMock.__iter__ defaults to iter([])) and makes `row.get(...)` return a
   MagicMock. `_mock_db` below models the PostgREST builder faithfully: every
   filter/order/range call returns the same query object.
"""
import pytest
from unittest.mock import MagicMock, patch
from fastapi import HTTPException


def _mock_db(rows):
    """Build a Supabase-client double that mirrors the PostgREST query builder.

    Returns (db, query) — `query` is the chainable builder every
    `.eq()/.ilike()/.order()/.range()` call returns, so tests can assert which
    filters the handler applied.
    """
    query = MagicMock()
    query.eq.return_value = query
    query.ilike.return_value = query
    query.order.return_value = query
    query.range.return_value = query
    query.execute.return_value = MagicMock(data=rows)

    client = MagicMock()
    client.table.return_value.select.return_value = query

    db = MagicMock()
    db.client = client
    return db, query


class TestListPrograms:
    """Tests for list_programs endpoint."""

    @pytest.mark.asyncio
    async def test_list_programs_success(self):
        """Test successful program listing."""
        from api.v1.library.programs import list_programs

        mock_db, query = _mock_db([
            {
                "id": "prog-1",
                "name": "Strength Builder",
                "category": "Strength Training",
                "duration_weeks": 8,
                "sessions_per_week": 4,
            }
        ])

        with patch("api.v1.library.programs.get_supabase_db", return_value=mock_db):
            result = await list_programs(limit=50, offset=0)

        assert len(result) == 1
        assert result[0].name == "Strength Builder"
        # Only active programs are ever listed.
        query.eq.assert_any_call("is_active", True)

    @pytest.mark.asyncio
    async def test_list_programs_with_category_filter(self):
        """Test program listing with category filter."""
        from api.v1.library.programs import list_programs

        mock_db, query = _mock_db([
            {
                "id": "prog-1",
                "name": "HIIT Blast",
                "category": "Cardio",
                "sessions_per_week": 5,
            }
        ])

        with patch("api.v1.library.programs.get_supabase_db", return_value=mock_db):
            result = await list_programs(category="Cardio", limit=50, offset=0)

        assert len(result) == 1
        assert result[0].category == "Cardio"
        # The filter must reach the DB, not just the response mapping.
        query.eq.assert_any_call("category", "Cardio")

    @pytest.mark.asyncio
    async def test_list_programs_with_search(self):
        """Test program listing with search filter."""
        from api.v1.library.programs import list_programs

        mock_db, query = _mock_db([
            {
                "id": "prog-1",
                "name": "Arnold Classic",
                "category": "Celebrity",
                "sessions_per_week": 6,
            }
        ])

        with patch("api.v1.library.programs.get_supabase_db", return_value=mock_db):
            result = await list_programs(search="Arnold", limit=50, offset=0)

        assert len(result) == 1
        assert "Arnold" in result[0].name
        # Search is a case-insensitive name match at the DB level.
        query.ilike.assert_any_call("name", "%Arnold%")


class TestGetProgramsGrouped:
    """Tests for get_programs_grouped endpoint."""

    @pytest.mark.asyncio
    async def test_get_programs_grouped_success(self):
        """Test successful grouped programs retrieval."""
        from api.v1.library.programs import get_programs_grouped

        mock_db, _ = _mock_db([
            {"id": "prog-1", "name": "HIIT 1", "category": "Cardio", "sessions_per_week": 5},
            {"id": "prog-2", "name": "HIIT 2", "category": "Cardio", "sessions_per_week": 5},
            {"id": "prog-3", "name": "Strength 1", "category": "Strength Training", "sessions_per_week": 4},
        ])

        with patch("api.v1.library.programs.get_supabase_db", return_value=mock_db):
            result = await get_programs_grouped(limit_per_group=10)

        # Should have 2 categories
        assert len(result) == 2

        categories = [g.category for g in result]
        assert "Cardio" in categories
        assert "Strength Training" in categories

        # Groups are ordered by count descending, so Cardio (2) leads.
        assert result[0].category == "Cardio"
        assert result[0].count == 2


class TestGetProgram:
    """Tests for get_program endpoint."""

    @pytest.mark.asyncio
    async def test_get_program_success(self):
        """Test successful program retrieval.

        RETIRED ASSERTION: this test used to assert `"workouts" in result`. That
        was true when the library detail endpoint read the legacy `programs`
        table, whose row carried a `workouts` blob. The endpoint now reads
        `branded_programs`, which has NO workouts column at all (per-session
        content lives in `program_variant_weeks` and is served by the /programs
        API) — so there is nothing to return, and the only consumer
        (frontend/src/api/client.ts) already types it as optional
        (`LibraryProgram & { workouts?: unknown }`).

        The guarantee this test protects is unchanged: a known id resolves to a
        single active program and every branded_programs column is mapped onto
        the documented response shape. It now asserts that mapping — including
        the derived `session_duration_minutes` (45 when sessions_per_week <= 4,
        else 60) and the tagline → short_description / split_type → subcategory
        renames that a silent column rename would otherwise break.
        """
        from api.v1.library.programs import get_program

        mock_db, query = _mock_db([{
            "id": "prog-1",
            "name": "Strength Builder",
            "category": "Strength Training",
            "duration_weeks": 8,
            "sessions_per_week": 4,
            "difficulty_level": "intermediate",
            "split_type": "upper_lower",
            "tagline": "Get strong in 8 weeks",
            "description": "A full strength program.",
            "goals": ["build_muscle"],
        }])

        with patch("api.v1.library.programs.get_supabase_db", return_value=mock_db):
            result = await get_program("prog-1")

        assert result["id"] == "prog-1"
        assert result["name"] == "Strength Builder"
        assert result["category"] == "Strength Training"
        assert result["duration_weeks"] == 8
        assert result["sessions_per_week"] == 4
        assert result["session_duration_minutes"] == 45  # <= 4 sessions/week
        assert result["difficulty_level"] == "intermediate"
        assert result["subcategory"] == "upper_lower"        # split_type
        assert result["short_description"] == "Get strong in 8 weeks"  # tagline
        assert result["goals"] == ["build_muscle"]
        assert result["tags"] == ["build_muscle"]

        # Only the requested, still-active program is fetched.
        query.eq.assert_any_call("id", "prog-1")
        query.eq.assert_any_call("is_active", True)

    @pytest.mark.asyncio
    async def test_get_program_not_found(self):
        """Test program not found raises 404."""
        from api.v1.library.programs import get_program

        mock_db, _ = _mock_db([])

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

        mock_db, _ = _mock_db([
            {"category": "Cardio"},
            {"category": "Cardio"},
            {"category": "Strength Training"},
            {"category": "Celebrity Workout"},
        ])

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

        mock_db, _ = _mock_db([])

        with patch("api.v1.library.programs.get_supabase_db", return_value=mock_db):
            result = await get_program_categories()

        assert result == []
