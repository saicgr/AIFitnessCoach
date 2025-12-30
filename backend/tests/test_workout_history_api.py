"""
Tests for Workout History Import API.

Tests the manual workout history import feature that allows users
to seed their strength data for better AI-generated workouts.
"""
import pytest
from unittest.mock import MagicMock, patch, AsyncMock
from datetime import datetime, timedelta


class TestSingleImport:
    """Tests for single workout history entry import."""

    @pytest.mark.asyncio
    @patch('api.v1.workout_history.get_supabase_db')
    async def test_import_single_entry_success(self, mock_get_db):
        """Test successful single entry import."""
        from api.v1.workout_history import import_workout_history, SingleImportRequest

        mock_db = MagicMock()
        mock_db.client.table.return_value.insert.return_value.execute.return_value.data = [
            {"id": "test-id-123", "exercise_name": "Bench Press", "weight_kg": 80}
        ]
        mock_get_db.return_value = mock_db

        request = SingleImportRequest(
            user_id="user-123",
            exercise_name="Bench Press",
            weight_kg=80,
            reps=10,
            sets=3,
        )

        result = await import_workout_history(request)

        assert result.imported_count == 1
        assert result.failed_count == 0
        assert "Bench Press" in result.exercises_affected
        assert "80" in result.message

    @pytest.mark.asyncio
    @patch('api.v1.workout_history.get_supabase_db')
    async def test_import_with_custom_date(self, mock_get_db):
        """Test import with a custom performed_at date."""
        from api.v1.workout_history import import_workout_history, SingleImportRequest

        mock_db = MagicMock()
        mock_db.client.table.return_value.insert.return_value.execute.return_value.data = [
            {"id": "test-id-123"}
        ]
        mock_get_db.return_value = mock_db

        custom_date = datetime(2024, 6, 15, 10, 30, 0)
        request = SingleImportRequest(
            user_id="user-123",
            exercise_name="Squat",
            weight_kg=100,
            reps=8,
            sets=4,
            performed_at=custom_date,
        )

        result = await import_workout_history(request)

        assert result.imported_count == 1
        # Verify the date was passed to the database
        call_args = mock_db.client.table.return_value.insert.call_args
        assert call_args is not None


class TestBulkImport:
    """Tests for bulk workout history import."""

    @pytest.mark.asyncio
    @patch('api.v1.workout_history.get_supabase_db')
    async def test_bulk_import_success(self, mock_get_db):
        """Test successful bulk import of multiple entries."""
        from api.v1.workout_history import bulk_import_workout_history, BulkImportRequest, WorkoutHistoryEntry

        mock_db = MagicMock()
        mock_db.client.table.return_value.insert.return_value.execute.return_value.data = [
            {"id": "id-1"}, {"id": "id-2"}, {"id": "id-3"}
        ]
        mock_get_db.return_value = mock_db

        request = BulkImportRequest(
            user_id="user-123",
            entries=[
                WorkoutHistoryEntry(exercise_name="Bench Press", weight_kg=80, reps=10),
                WorkoutHistoryEntry(exercise_name="Squat", weight_kg=100, reps=8),
                WorkoutHistoryEntry(exercise_name="Deadlift", weight_kg=120, reps=5),
            ],
            source="spreadsheet",
        )

        result = await bulk_import_workout_history(request)

        assert result.imported_count == 3
        assert result.failed_count == 0
        assert len(result.exercises_affected) == 3

    @pytest.mark.asyncio
    @patch('api.v1.workout_history.get_supabase_db')
    async def test_bulk_import_with_source(self, mock_get_db):
        """Test bulk import with custom source field."""
        from api.v1.workout_history import bulk_import_workout_history, BulkImportRequest, WorkoutHistoryEntry

        mock_db = MagicMock()
        mock_db.client.table.return_value.insert.return_value.execute.return_value.data = [{"id": "id-1"}]
        mock_get_db.return_value = mock_db

        request = BulkImportRequest(
            user_id="user-123",
            entries=[WorkoutHistoryEntry(exercise_name="Curl", weight_kg=20, reps=12)],
            source="import",
        )

        result = await bulk_import_workout_history(request)

        # Verify source was passed
        call_args = mock_db.client.table.return_value.insert.call_args
        inserted_data = call_args[0][0][0]
        assert inserted_data["source"] == "import"


class TestGetHistory:
    """Tests for retrieving workout history."""

    @pytest.mark.asyncio
    @patch('api.v1.workout_history.get_supabase_db')
    async def test_get_user_history_success(self, mock_get_db):
        """Test successful retrieval of user's workout history."""
        from api.v1.workout_history import get_user_workout_history

        mock_db = MagicMock()
        mock_db.client.table.return_value.select.return_value.eq.return_value.order.return_value.range.return_value.execute.return_value.data = [
            {
                "id": "id-1",
                "exercise_name": "Bench Press",
                "weight_kg": 80.0,
                "reps": 10,
                "sets": 3,
                "performed_at": "2024-06-15T10:30:00+00:00",
                "notes": None,
                "source": "manual",
                "created_at": "2024-06-15T10:30:00+00:00",
            }
        ]
        mock_get_db.return_value = mock_db

        result = await get_user_workout_history("user-123")

        assert len(result) == 1
        assert result[0].exercise_name == "Bench Press"
        assert result[0].weight_kg == 80.0

    @pytest.mark.asyncio
    @patch('api.v1.workout_history.get_supabase_db')
    async def test_get_history_with_filter(self, mock_get_db):
        """Test history retrieval with exercise name filter."""
        from api.v1.workout_history import get_user_workout_history

        mock_db = MagicMock()
        # Chain: table().select().eq().ilike().order().range().execute()
        mock_db.client.table.return_value.select.return_value.eq.return_value.ilike.return_value.order.return_value.range.return_value.execute.return_value.data = []
        mock_get_db.return_value = mock_db

        result = await get_user_workout_history("user-123", exercise_name="bench")

        # Verify filter was applied
        mock_db.client.table.return_value.select.return_value.eq.return_value.ilike.assert_called_once()


class TestStrengthSummary:
    """Tests for strength summary aggregation."""

    @pytest.mark.asyncio
    @patch('api.v1.workout_history.get_supabase_db')
    async def test_get_strength_summary(self, mock_get_db):
        """Test aggregated strength summary."""
        from api.v1.workout_history import get_strength_summary

        mock_db = MagicMock()
        # First call is RPC (returns empty), second is fallback query
        mock_db.client.rpc.return_value.execute.return_value.data = None
        mock_db.client.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value.data = [
            {"exercise_name": "Bench Press", "weight_kg": 80.0, "performed_at": "2024-06-15T10:30:00+00:00"},
            {"exercise_name": "Bench Press", "weight_kg": 85.0, "performed_at": "2024-06-10T10:30:00+00:00"},
            {"exercise_name": "Squat", "weight_kg": 100.0, "performed_at": "2024-06-14T10:30:00+00:00"},
        ]
        mock_get_db.return_value = mock_db

        result = await get_strength_summary("user-123")

        assert len(result) == 2  # Two unique exercises
        bench_summary = next((s for s in result if s.exercise_name == "Bench Press"), None)
        assert bench_summary is not None
        assert bench_summary.max_weight_kg == 85.0  # Higher of the two
        assert bench_summary.total_sessions == 2


class TestDeleteHistory:
    """Tests for deleting workout history."""

    @pytest.mark.asyncio
    @patch('api.v1.workout_history.get_supabase_db')
    async def test_delete_single_entry(self, mock_get_db):
        """Test deleting a single history entry."""
        from api.v1.workout_history import delete_workout_history_entry

        mock_db = MagicMock()
        mock_db.client.table.return_value.delete.return_value.eq.return_value.eq.return_value.execute.return_value.data = [
            {"id": "entry-123"}
        ]
        mock_get_db.return_value = mock_db

        result = await delete_workout_history_entry("user-123", "entry-123")

        assert result["id"] == "entry-123"
        assert "deleted" in result["message"].lower()

    @pytest.mark.asyncio
    @patch('api.v1.workout_history.get_supabase_db')
    async def test_delete_nonexistent_entry(self, mock_get_db):
        """Test deleting a nonexistent entry returns 404."""
        from api.v1.workout_history import delete_workout_history_entry
        from fastapi import HTTPException

        mock_db = MagicMock()
        mock_db.client.table.return_value.delete.return_value.eq.return_value.eq.return_value.execute.return_value.data = []
        mock_get_db.return_value = mock_db

        with pytest.raises(HTTPException) as exc_info:
            await delete_workout_history_entry("user-123", "nonexistent")

        assert exc_info.value.status_code == 404

    @pytest.mark.asyncio
    @patch('api.v1.workout_history.get_supabase_db')
    async def test_clear_all_history(self, mock_get_db):
        """Test clearing all history for a user."""
        from api.v1.workout_history import clear_workout_history

        mock_db = MagicMock()
        mock_db.client.table.return_value.delete.return_value.eq.return_value.execute.return_value.data = [
            {"id": "1"}, {"id": "2"}, {"id": "3"}
        ]
        mock_get_db.return_value = mock_db

        result = await clear_workout_history("user-123")

        assert result["deleted_count"] == 3


class TestFuzzyExerciseMatching:
    """Tests for fuzzy exercise name matching in strength history."""

    def test_fuzzy_match_exact(self):
        """Test exact match returns True."""
        from api.v1.workouts.utils import fuzzy_exercise_match

        assert fuzzy_exercise_match("Bench Press", "Bench Press") == True

    def test_fuzzy_match_case_insensitive(self):
        """Test case insensitivity."""
        from api.v1.workouts.utils import fuzzy_exercise_match

        assert fuzzy_exercise_match("bench press", "BENCH PRESS") == True

    def test_fuzzy_match_with_prefix(self):
        """Test matching with equipment prefix."""
        from api.v1.workouts.utils import fuzzy_exercise_match

        assert fuzzy_exercise_match("Bench Press", "Barbell Bench Press") == True
        assert fuzzy_exercise_match("Squat", "Barbell Back Squat") == True

    def test_fuzzy_match_with_variations(self):
        """Test matching with common variations."""
        from api.v1.workouts.utils import fuzzy_exercise_match

        assert fuzzy_exercise_match("Pull Up", "Pullup") == True
        assert fuzzy_exercise_match("Pull-up", "Pull Up") == True

    def test_fuzzy_no_match_different_exercises(self):
        """Test that different exercises don't match."""
        from api.v1.workouts.utils import fuzzy_exercise_match

        assert fuzzy_exercise_match("Bench Press", "Squat") == False
        assert fuzzy_exercise_match("Bicep Curl", "Tricep Extension") == False


class TestStrengthHistoryWithImports:
    """Tests for strength history combining completed workouts and imports."""

    @pytest.mark.asyncio
    @patch('api.v1.workouts.utils.get_supabase_db')
    @patch('services.workout_feedback_rag_service.get_workout_feedback_rag_service')
    async def test_combines_chromadb_and_imports(self, mock_get_rag, mock_get_db):
        """Test that strength history combines both data sources."""
        from api.v1.workouts.utils import get_user_strength_history

        # Mock ChromaDB (completed workouts)
        mock_rag = MagicMock()
        mock_rag.find_similar_exercise_sessions = AsyncMock(return_value=[
            {
                "metadata": {
                    "exercises": [
                        {"name": "Bench Press", "weight_kg": 80, "reps": 8},
                    ]
                }
            }
        ])
        mock_get_rag.return_value = mock_rag

        # Mock Supabase (imported history)
        mock_db = MagicMock()
        mock_db.client.table.return_value.select.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value.data = [
            {"exercise_name": "Squat", "weight_kg": 100, "reps": 6, "performed_at": "2024-06-15T10:30:00+00:00"},
        ]
        mock_get_db.return_value = mock_db

        result = await get_user_strength_history("user-123")

        # Should have both exercises
        assert "Bench Press" in result
        assert "Squat" in result
        assert result["Bench Press"]["source"] == "completed"
        assert result["Squat"]["source"] == "imported"

    @pytest.mark.asyncio
    @patch('api.v1.workouts.utils.get_supabase_db')
    @patch('services.workout_feedback_rag_service.get_workout_feedback_rag_service')
    async def test_imports_fill_gap_when_no_completed_workouts(self, mock_get_rag, mock_get_db):
        """Test that imports provide data when no completed workouts exist."""
        from api.v1.workouts.utils import get_user_strength_history

        # Mock ChromaDB - empty (no completed workouts)
        mock_rag = MagicMock()
        mock_rag.find_similar_exercise_sessions = AsyncMock(return_value=[])
        mock_get_rag.return_value = mock_rag

        # Mock Supabase (imported history exists)
        mock_db = MagicMock()
        mock_db.client.table.return_value.select.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value.data = [
            {"exercise_name": "Bench Press", "weight_kg": 75, "reps": 10, "performed_at": "2024-06-15T10:30:00+00:00"},
            {"exercise_name": "Squat", "weight_kg": 90, "reps": 8, "performed_at": "2024-06-15T10:30:00+00:00"},
        ]
        mock_get_db.return_value = mock_db

        result = await get_user_strength_history("user-123")

        # Should have imported exercises
        assert len(result) == 2
        assert result["Bench Press"]["last_weight_kg"] == 75
        assert result["Bench Press"]["source"] == "imported"


class TestValidation:
    """Tests for request validation."""

    def test_exercise_name_required(self):
        """Test that exercise name is required."""
        from api.v1.workout_history import SingleImportRequest
        from pydantic import ValidationError

        with pytest.raises(ValidationError):
            SingleImportRequest(
                user_id="user-123",
                exercise_name="",  # Empty name
                weight_kg=80,
                reps=10,
            )

    def test_weight_must_be_positive(self):
        """Test that weight must be >= 0."""
        from api.v1.workout_history import SingleImportRequest
        from pydantic import ValidationError

        with pytest.raises(ValidationError):
            SingleImportRequest(
                user_id="user-123",
                exercise_name="Bench Press",
                weight_kg=-10,  # Negative weight
                reps=10,
            )

    def test_reps_must_be_positive(self):
        """Test that reps must be >= 1."""
        from api.v1.workout_history import SingleImportRequest
        from pydantic import ValidationError

        with pytest.raises(ValidationError):
            SingleImportRequest(
                user_id="user-123",
                exercise_name="Bench Press",
                weight_kg=80,
                reps=0,  # Zero reps
            )

    def test_bulk_import_max_entries(self):
        """Test that bulk import has max entry limit."""
        from api.v1.workout_history import BulkImportRequest, WorkoutHistoryEntry
        from pydantic import ValidationError

        # This should fail - too many entries
        with pytest.raises(ValidationError):
            BulkImportRequest(
                user_id="user-123",
                entries=[
                    WorkoutHistoryEntry(exercise_name=f"Exercise {i}", weight_kg=50, reps=10)
                    for i in range(101)  # Max is 100
                ],
            )
