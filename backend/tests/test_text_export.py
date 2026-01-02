"""
Tests for Text Export Service.

Tests:
- Text export format structure
- Date filtering for text export
- Empty logs handling
- Workout data completeness (sets, reps, weight, RPE, notes)
- API endpoint content-type

Run with: pytest backend/tests/test_text_export.py -v
"""

import pytest
from unittest.mock import MagicMock, patch
from datetime import datetime

from services.data_export import export_workout_logs_text


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def mock_db():
    """Create mock database client."""
    mock = MagicMock()
    return mock


@pytest.fixture
def sample_user():
    """Sample user data."""
    return {
        "id": "user-123",
        "name": "John Doe",
        "email": "john@example.com",
        "fitness_level": "intermediate",
    }


@pytest.fixture
def sample_workout_logs():
    """Sample workout logs data."""
    return [
        {
            "id": "log-101",
            "workout_id": 1,
            "workout_name": "Push Day",
            "completed_at": "2025-01-15T18:00:00Z",
            "total_time_seconds": 3600,
            "notes": "Felt strong today",
        },
        {
            "id": "log-102",
            "workout_id": 2,
            "workout_name": "Pull Day",
            "completed_at": "2025-01-17T10:30:00Z",
            "total_time_seconds": 2700,
            "notes": "",
        },
    ]


@pytest.fixture
def sample_performance_logs():
    """Sample performance logs with full workout data."""
    return [
        # Push Day exercises
        {
            "workout_log_id": "log-101",
            "exercise_name": "Bench Press",
            "set_number": 1,
            "reps_completed": 10,
            "weight_kg": 80.0,
            "rpe": 7.0,
            "is_completed": True,
            "notes": "Warmup set",
        },
        {
            "workout_log_id": "log-101",
            "exercise_name": "Bench Press",
            "set_number": 2,
            "reps_completed": 8,
            "weight_kg": 100.0,
            "rpe": 8.5,
            "is_completed": True,
            "notes": "",
        },
        {
            "workout_log_id": "log-101",
            "exercise_name": "Bench Press",
            "set_number": 3,
            "reps_completed": 6,
            "weight_kg": 100.0,
            "rpe": 9.0,
            "is_completed": True,
            "notes": "Hard set",
        },
        {
            "workout_log_id": "log-101",
            "exercise_name": "Incline Dumbbell Press",
            "set_number": 1,
            "reps_completed": 12,
            "weight_kg": 30.0,
            "rpe": 7.5,
            "is_completed": True,
            "notes": "",
        },
        # Pull Day exercises
        {
            "workout_log_id": "log-102",
            "exercise_name": "Barbell Rows",
            "set_number": 1,
            "reps_completed": 8,
            "weight_kg": 60.0,
            "rpe": 7.0,
            "is_completed": True,
            "notes": "",
        },
        {
            "workout_log_id": "log-102",
            "exercise_name": "Pull-ups",
            "set_number": 1,
            "reps_completed": 10,
            "weight_kg": None,
            "rpe": 8.0,
            "is_completed": True,
            "notes": "Bodyweight",
        },
    ]


@pytest.fixture
def single_workout_log():
    """Single workout log for simpler testing."""
    return [
        {
            "id": "log-201",
            "workout_id": 3,
            "workout_name": "Leg Day",
            "completed_at": "2025-01-20T09:00:00Z",
            "total_time_seconds": 4500,
            "notes": "",
        },
    ]


@pytest.fixture
def single_workout_performance_logs():
    """Performance logs for single workout."""
    return [
        {
            "workout_log_id": "log-201",
            "exercise_name": "Squats",
            "set_number": 1,
            "reps_completed": 8,
            "weight_kg": 100.0,
            "rpe": 7.0,
            "is_completed": True,
            "notes": "",
        },
        {
            "workout_log_id": "log-201",
            "exercise_name": "Squats",
            "set_number": 2,
            "reps_completed": 8,
            "weight_kg": 100.0,
            "rpe": 8.0,
            "is_completed": True,
            "notes": "Good depth",
        },
    ]


# ============================================================
# TEXT EXPORT FORMAT STRUCTURE TESTS
# ============================================================

class TestExportTextFormatStructure:
    """Test text export has correct headers and formatting."""

    def test_export_text_format_has_header(self, mock_db, sample_user, sample_workout_logs, sample_performance_logs):
        """Test that text export includes proper header."""
        mock_db.get_user.return_value = sample_user

        with patch("services.data_export.get_supabase_db", return_value=mock_db):
            with patch("services.data_export._get_filtered_workout_logs", return_value=sample_workout_logs):
                with patch("services.data_export._get_filtered_performance_logs", return_value=sample_performance_logs):
                    result = export_workout_logs_text("user-123")

        # Check header elements
        assert "AI FITNESS COACH - WORKOUT LOG EXPORT" in result
        assert "Generated:" in result
        assert "Period:" in result
        assert "=" * 68 in result  # Check separator line

    def test_export_text_format_has_workout_sections(self, mock_db, sample_user, sample_workout_logs, sample_performance_logs):
        """Test that each workout has proper section formatting."""
        mock_db.get_user.return_value = sample_user

        with patch("services.data_export.get_supabase_db", return_value=mock_db):
            with patch("services.data_export._get_filtered_workout_logs", return_value=sample_workout_logs):
                with patch("services.data_export._get_filtered_performance_logs", return_value=sample_performance_logs):
                    result = export_workout_logs_text("user-123")

        # Check workout section elements
        assert "WORKOUT: Push Day" in result
        assert "WORKOUT: Pull Day" in result
        assert "Date:" in result
        assert "-" * 68 in result  # Check workout separator

    def test_export_text_format_has_summary_line(self, mock_db, sample_user, sample_workout_logs, sample_performance_logs):
        """Test that workout sections include summary line."""
        mock_db.get_user.return_value = sample_user

        with patch("services.data_export.get_supabase_db", return_value=mock_db):
            with patch("services.data_export._get_filtered_workout_logs", return_value=sample_workout_logs):
                with patch("services.data_export._get_filtered_performance_logs", return_value=sample_performance_logs):
                    result = export_workout_logs_text("user-123")

        # Check summary elements
        assert "Duration:" in result
        assert "Total Sets:" in result
        assert "Total Reps:" in result
        assert "Total Volume:" in result

    def test_export_text_format_has_footer(self, mock_db, sample_user, sample_workout_logs, sample_performance_logs):
        """Test that text export includes proper footer."""
        mock_db.get_user.return_value = sample_user

        with patch("services.data_export.get_supabase_db", return_value=mock_db):
            with patch("services.data_export._get_filtered_workout_logs", return_value=sample_workout_logs):
                with patch("services.data_export._get_filtered_performance_logs", return_value=sample_performance_logs):
                    result = export_workout_logs_text("user-123")

        # Check footer
        assert "Total Workouts: 2" in result


# ============================================================
# DATE RANGE FILTERING TESTS
# ============================================================

class TestExportTextWithDateRange:
    """Test date filtering works correctly."""

    def test_export_text_with_date_range_shows_period(self, mock_db, sample_user, sample_workout_logs, sample_performance_logs):
        """Test that date range is reflected in the output."""
        mock_db.get_user.return_value = sample_user

        with patch("services.data_export.get_supabase_db", return_value=mock_db):
            with patch("services.data_export._get_filtered_workout_logs", return_value=sample_workout_logs):
                with patch("services.data_export._get_filtered_performance_logs", return_value=sample_performance_logs):
                    result = export_workout_logs_text(
                        "user-123",
                        start_date="2025-01-01",
                        end_date="2025-01-31"
                    )

        assert "Period: 2025-01-01 to 2025-01-31" in result

    def test_export_text_without_start_date_shows_all_time(self, mock_db, sample_user, sample_workout_logs, sample_performance_logs):
        """Test that missing start date shows 'All time'."""
        mock_db.get_user.return_value = sample_user

        with patch("services.data_export.get_supabase_db", return_value=mock_db):
            with patch("services.data_export._get_filtered_workout_logs", return_value=sample_workout_logs):
                with patch("services.data_export._get_filtered_performance_logs", return_value=sample_performance_logs):
                    result = export_workout_logs_text("user-123")

        assert "Period: All time to" in result

    def test_export_text_date_filter_passed_to_queries(self, mock_db, sample_user):
        """Test that date filters are passed to database queries."""
        mock_db.get_user.return_value = sample_user

        mock_get_logs = MagicMock(return_value=[])
        mock_get_perf = MagicMock(return_value=[])

        with patch("services.data_export.get_supabase_db", return_value=mock_db):
            with patch("services.data_export._get_filtered_workout_logs", mock_get_logs):
                with patch("services.data_export._get_filtered_performance_logs", mock_get_perf):
                    export_workout_logs_text(
                        "user-123",
                        start_date="2025-01-15",
                        end_date="2025-01-20"
                    )

        # Verify filters were passed
        mock_get_logs.assert_called_once()
        call_args = mock_get_logs.call_args[0]
        assert call_args[1] == "user-123"  # user_id
        assert call_args[2] == "2025-01-15"  # start_date
        assert call_args[3] == "2025-01-20"  # end_date


# ============================================================
# EMPTY LOGS HANDLING TESTS
# ============================================================

class TestExportTextEmptyLogs:
    """Test graceful handling of no data."""

    def test_export_text_empty_logs_shows_message(self, mock_db, sample_user):
        """Test that empty logs shows appropriate message."""
        mock_db.get_user.return_value = sample_user

        with patch("services.data_export.get_supabase_db", return_value=mock_db):
            with patch("services.data_export._get_filtered_workout_logs", return_value=[]):
                with patch("services.data_export._get_filtered_performance_logs", return_value=[]):
                    result = export_workout_logs_text("user-123")

        assert "No workout logs found for this period." in result

    def test_export_text_empty_logs_still_has_header(self, mock_db, sample_user):
        """Test that empty export still includes header."""
        mock_db.get_user.return_value = sample_user

        with patch("services.data_export.get_supabase_db", return_value=mock_db):
            with patch("services.data_export._get_filtered_workout_logs", return_value=[]):
                with patch("services.data_export._get_filtered_performance_logs", return_value=[]):
                    result = export_workout_logs_text("user-123")

        assert "AI FITNESS COACH - WORKOUT LOG EXPORT" in result
        assert "Generated:" in result

    def test_export_text_workout_without_performance_logs(self, mock_db, sample_user, single_workout_log):
        """Test workout with no exercise data recorded."""
        mock_db.get_user.return_value = sample_user

        with patch("services.data_export.get_supabase_db", return_value=mock_db):
            with patch("services.data_export._get_filtered_workout_logs", return_value=single_workout_log):
                with patch("services.data_export._get_filtered_performance_logs", return_value=[]):
                    result = export_workout_logs_text("user-123")

        assert "WORKOUT: Leg Day" in result
        assert "No exercise data recorded." in result


# ============================================================
# WORKOUT DATA COMPLETENESS TESTS
# ============================================================

class TestExportTextIncludesAllWorkoutData:
    """Test that all fields are present (sets, reps, weight, RPE, notes)."""

    def test_export_text_includes_sets(self, mock_db, sample_user, single_workout_log, single_workout_performance_logs):
        """Test that set numbers are included."""
        mock_db.get_user.return_value = sample_user

        with patch("services.data_export.get_supabase_db", return_value=mock_db):
            with patch("services.data_export._get_filtered_workout_logs", return_value=single_workout_log):
                with patch("services.data_export._get_filtered_performance_logs", return_value=single_workout_performance_logs):
                    result = export_workout_logs_text("user-123")

        assert "Set 1:" in result
        assert "Set 2:" in result

    def test_export_text_includes_reps(self, mock_db, sample_user, single_workout_log, single_workout_performance_logs):
        """Test that reps are included."""
        mock_db.get_user.return_value = sample_user

        with patch("services.data_export.get_supabase_db", return_value=mock_db):
            with patch("services.data_export._get_filtered_workout_logs", return_value=single_workout_log):
                with patch("services.data_export._get_filtered_performance_logs", return_value=single_workout_performance_logs):
                    result = export_workout_logs_text("user-123")

        assert "8 reps" in result

    def test_export_text_includes_weight(self, mock_db, sample_user, single_workout_log, single_workout_performance_logs):
        """Test that weight is included when present."""
        mock_db.get_user.return_value = sample_user

        with patch("services.data_export.get_supabase_db", return_value=mock_db):
            with patch("services.data_export._get_filtered_workout_logs", return_value=single_workout_log):
                with patch("services.data_export._get_filtered_performance_logs", return_value=single_workout_performance_logs):
                    result = export_workout_logs_text("user-123")

        assert "100.0 kg" in result or "100 kg" in result

    def test_export_text_includes_rpe(self, mock_db, sample_user, sample_workout_logs, sample_performance_logs):
        """Test that RPE is included when present."""
        mock_db.get_user.return_value = sample_user

        with patch("services.data_export.get_supabase_db", return_value=mock_db):
            with patch("services.data_export._get_filtered_workout_logs", return_value=sample_workout_logs):
                with patch("services.data_export._get_filtered_performance_logs", return_value=sample_performance_logs):
                    result = export_workout_logs_text("user-123")

        assert "RPE" in result

    def test_export_text_includes_exercise_notes(self, mock_db, sample_user, sample_workout_logs, sample_performance_logs):
        """Test that exercise notes are included when present."""
        mock_db.get_user.return_value = sample_user

        with patch("services.data_export.get_supabase_db", return_value=mock_db):
            with patch("services.data_export._get_filtered_workout_logs", return_value=sample_workout_logs):
                with patch("services.data_export._get_filtered_performance_logs", return_value=sample_performance_logs):
                    result = export_workout_logs_text("user-123")

        # Check that notes from performance logs appear
        assert "Warmup set" in result
        assert "Hard set" in result
        assert "Bodyweight" in result

    def test_export_text_includes_workout_notes(self, mock_db, sample_user, sample_workout_logs, sample_performance_logs):
        """Test that workout-level notes are included when present."""
        mock_db.get_user.return_value = sample_user

        with patch("services.data_export.get_supabase_db", return_value=mock_db):
            with patch("services.data_export._get_filtered_workout_logs", return_value=sample_workout_logs):
                with patch("services.data_export._get_filtered_performance_logs", return_value=sample_performance_logs):
                    result = export_workout_logs_text("user-123")

        assert "Notes: Felt strong today" in result

    def test_export_text_includes_exercise_names(self, mock_db, sample_user, sample_workout_logs, sample_performance_logs):
        """Test that exercise names are included."""
        mock_db.get_user.return_value = sample_user

        with patch("services.data_export.get_supabase_db", return_value=mock_db):
            with patch("services.data_export._get_filtered_workout_logs", return_value=sample_workout_logs):
                with patch("services.data_export._get_filtered_performance_logs", return_value=sample_performance_logs):
                    result = export_workout_logs_text("user-123")

        assert "Bench Press" in result
        assert "Incline Dumbbell Press" in result
        assert "Barbell Rows" in result
        assert "Pull-ups" in result

    def test_export_text_handles_bodyweight_exercises(self, mock_db, sample_user, sample_workout_logs, sample_performance_logs):
        """Test that bodyweight exercises (no weight) are handled correctly."""
        mock_db.get_user.return_value = sample_user

        with patch("services.data_export.get_supabase_db", return_value=mock_db):
            with patch("services.data_export._get_filtered_workout_logs", return_value=sample_workout_logs):
                with patch("services.data_export._get_filtered_performance_logs", return_value=sample_performance_logs):
                    result = export_workout_logs_text("user-123")

        # Pull-ups has weight_kg=None, should still appear
        assert "Pull-ups" in result

    def test_export_text_calculates_total_volume(self, mock_db, sample_user, single_workout_log, single_workout_performance_logs):
        """Test that total volume is calculated correctly."""
        mock_db.get_user.return_value = sample_user

        with patch("services.data_export.get_supabase_db", return_value=mock_db):
            with patch("services.data_export._get_filtered_workout_logs", return_value=single_workout_log):
                with patch("services.data_export._get_filtered_performance_logs", return_value=single_workout_performance_logs):
                    result = export_workout_logs_text("user-123")

        # 8 reps * 100 kg + 8 reps * 100 kg = 1600 kg
        assert "Total Volume: 1600" in result

    def test_export_text_groups_exercises_correctly(self, mock_db, sample_user, sample_workout_logs, sample_performance_logs):
        """Test that exercises are grouped by name with numbered listing."""
        mock_db.get_user.return_value = sample_user

        with patch("services.data_export.get_supabase_db", return_value=mock_db):
            with patch("services.data_export._get_filtered_workout_logs", return_value=sample_workout_logs):
                with patch("services.data_export._get_filtered_performance_logs", return_value=sample_performance_logs):
                    result = export_workout_logs_text("user-123")

        # Check exercises are numbered
        assert "1. Bench Press" in result
        assert "2. Incline Dumbbell Press" in result


# ============================================================
# API ENDPOINT TESTS
# ============================================================

# Try to import FastAPI app, skip API tests if not available
try:
    from fastapi.testclient import TestClient
    from main import app
    FASTAPI_AVAILABLE = True
except (ImportError, ModuleNotFoundError):
    FASTAPI_AVAILABLE = False
    app = None
    TestClient = None


@pytest.mark.skipif(not FASTAPI_AVAILABLE, reason="FastAPI app not available - skipping API tests")
class TestExportTextApiEndpoint:
    """Test the API endpoint returns correct content-type."""

    def test_export_text_api_returns_plain_text_content_type(self, mock_db, sample_user, sample_workout_logs, sample_performance_logs):
        """Test API endpoint returns correct content-type header."""
        # Setup mocks
        mock_db.get_user.return_value = sample_user

        with patch("api.v1.users.get_supabase_db", return_value=mock_db):
            with patch("services.data_export.get_supabase_db", return_value=mock_db):
                with patch("services.data_export._get_filtered_workout_logs", return_value=sample_workout_logs):
                    with patch("services.data_export._get_filtered_performance_logs", return_value=sample_performance_logs):
                        client = TestClient(app)
                        response = client.get("/api/v1/users/user-123/export-text")

        assert response.status_code == 200
        assert "text/plain" in response.headers.get("content-type", "")

    def test_export_text_api_returns_attachment_disposition(self, mock_db, sample_user, sample_workout_logs, sample_performance_logs):
        """Test API endpoint returns Content-Disposition header for download."""
        mock_db.get_user.return_value = sample_user

        with patch("api.v1.users.get_supabase_db", return_value=mock_db):
            with patch("services.data_export.get_supabase_db", return_value=mock_db):
                with patch("services.data_export._get_filtered_workout_logs", return_value=sample_workout_logs):
                    with patch("services.data_export._get_filtered_performance_logs", return_value=sample_performance_logs):
                        client = TestClient(app)
                        response = client.get("/api/v1/users/user-123/export-text")

        assert response.status_code == 200
        content_disposition = response.headers.get("content-disposition", "")
        assert "attachment" in content_disposition
        assert "workout_log_" in content_disposition
        assert ".txt" in content_disposition

    def test_export_text_api_user_not_found_returns_404(self, mock_db):
        """Test API returns 404 for non-existent user."""
        mock_db.get_user.return_value = None

        with patch("api.v1.users.get_supabase_db", return_value=mock_db):
            client = TestClient(app)
            response = client.get("/api/v1/users/nonexistent-user/export-text")

        assert response.status_code == 404

    def test_export_text_api_with_date_parameters(self, mock_db, sample_user, sample_workout_logs, sample_performance_logs):
        """Test API endpoint accepts date query parameters."""
        mock_db.get_user.return_value = sample_user

        with patch("api.v1.users.get_supabase_db", return_value=mock_db):
            with patch("services.data_export.get_supabase_db", return_value=mock_db):
                with patch("services.data_export._get_filtered_workout_logs", return_value=sample_workout_logs):
                    with patch("services.data_export._get_filtered_performance_logs", return_value=sample_performance_logs):
                        client = TestClient(app)
                        response = client.get(
                            "/api/v1/users/user-123/export-text",
                            params={"start_date": "2025-01-01", "end_date": "2025-01-31"}
                        )

        assert response.status_code == 200
        assert "Period: 2025-01-01 to 2025-01-31" in response.text


# ============================================================
# ERROR HANDLING TESTS
# ============================================================

class TestExportTextErrorHandling:
    """Test error handling scenarios."""

    def test_export_text_user_not_found_raises_error(self, mock_db):
        """Test that non-existent user raises ValueError."""
        mock_db.get_user.return_value = None

        with patch("services.data_export.get_supabase_db", return_value=mock_db):
            with pytest.raises(ValueError, match="not found"):
                export_workout_logs_text("nonexistent-user")

    def test_export_text_handles_malformed_date(self, mock_db, sample_user, sample_workout_logs, sample_performance_logs):
        """Test that malformed dates in logs are handled gracefully."""
        mock_db.get_user.return_value = sample_user

        # Create log with malformed date
        logs_with_bad_date = [
            {
                "id": "log-999",
                "workout_id": 1,
                "workout_name": "Test Workout",
                "completed_at": "not-a-date",
                "total_time_seconds": 1800,
                "notes": "",
            },
        ]

        with patch("services.data_export.get_supabase_db", return_value=mock_db):
            with patch("services.data_export._get_filtered_workout_logs", return_value=logs_with_bad_date):
                with patch("services.data_export._get_filtered_performance_logs", return_value=[]):
                    # Should not raise - should handle gracefully
                    result = export_workout_logs_text("user-123")

        assert "WORKOUT: Test Workout" in result


# ============================================================
# CHRONOLOGICAL ORDER TESTS
# ============================================================

class TestExportTextChronologicalOrder:
    """Test that workouts are exported in chronological order."""

    def test_export_text_workouts_in_chronological_order(self, mock_db, sample_user, sample_performance_logs):
        """Test workouts are ordered oldest to newest."""
        mock_db.get_user.return_value = sample_user

        # Out of order logs
        unordered_logs = [
            {
                "id": "log-102",
                "workout_name": "Second Workout",
                "completed_at": "2025-01-17T10:00:00Z",
                "total_time_seconds": 1800,
                "notes": "",
            },
            {
                "id": "log-101",
                "workout_name": "First Workout",
                "completed_at": "2025-01-15T10:00:00Z",
                "total_time_seconds": 1800,
                "notes": "",
            },
        ]

        with patch("services.data_export.get_supabase_db", return_value=mock_db):
            with patch("services.data_export._get_filtered_workout_logs", return_value=unordered_logs):
                with patch("services.data_export._get_filtered_performance_logs", return_value=[]):
                    result = export_workout_logs_text("user-123")

        # First Workout should appear before Second Workout
        first_pos = result.find("First Workout")
        second_pos = result.find("Second Workout")
        assert first_pos < second_pos, "Workouts should be in chronological order (oldest first)"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
