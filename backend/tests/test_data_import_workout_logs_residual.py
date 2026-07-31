"""
Tests for the E2E register #120 residual fix in `_import_workout_logs` /
`import_user_data` (services/data_import.py).

Three defects fixed:
  1. `status` was never set on the imported row. Migration 2390 flipped
     `workout_logs.status`'s column DEFAULT to 'in_progress', so every
     restored historical log became invisible to every status='completed'
     reader (progress, streaks, PRs) — silently defeating the GDPR restore
     path's entire purpose.
  2. `duration_minutes` and `exercises_completed` were never imported at all,
     even though both are real `workout_logs` columns and derivable from data
     already present in the export (`total_time_seconds`, and
     `exercise_sets.csv` respectively).
  3. The per-row try/except swallowed failures — `import_user_data` reported
     `counts["workout_logs"]` as though every row landed, with no signal that
     some rows were dropped.
"""
import io
import zipfile
from unittest.mock import MagicMock, patch

import pytest

from services.data_import import import_user_data


@pytest.fixture
def mock_db():
    mock = MagicMock()
    return mock


@pytest.fixture
def sample_user():
    return {"id": "user-123", "name": "Jane Doe"}


def _zip_with(files: dict) -> bytes:
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w") as zf:
        zf.writestr("_metadata.csv", "key,value\nexport_version,2.0\n")
        for name, content in files.items():
            zf.writestr(name, content)
    return buf.getvalue()


class TestWorkoutLogStatus:
    def test_completed_session_restores_as_completed(self, mock_db, sample_user):
        """A normal exported row (exit_reason absent/'completed', as every real
        export today produces — see `_export_workout_logs`) must restore with
        status='completed', not fall through to the 'in_progress' column
        default."""
        mock_db.get_user.return_value = sample_user
        mock_db.create_workout_log.return_value = {"id": "new-log-1"}

        zip_bytes = _zip_with({
            "workout_logs.csv": (
                "log_id,workout_id,workout_name,completed_at,total_time_seconds,"
                "total_sets,total_reps,exit_reason\n"
                "101,,Push Day,2025-01-15T18:00:00Z,3600,20,160,completed\n"
            ),
        })

        with patch("services.data_import.get_supabase_db", return_value=mock_db):
            counts = import_user_data("user-123", zip_bytes)

        assert counts.get("workout_logs") == 1
        assert counts.get("workout_logs_failed") is None
        written = mock_db.create_workout_log.call_args.args[0]
        assert written["status"] == "completed"

    def test_early_exit_reason_restores_as_abandoned_not_in_progress(self, mock_db, sample_user):
        """A row with a genuine non-completed exit_reason must NOT silently
        fall through to the 'in_progress' column default either — an early
        exit is 'abandoned', a known, honest terminal state."""
        mock_db.get_user.return_value = sample_user
        mock_db.create_workout_log.return_value = {"id": "new-log-2"}

        zip_bytes = _zip_with({
            "workout_logs.csv": (
                "log_id,workout_id,workout_name,completed_at,total_time_seconds,"
                "total_sets,total_reps,exit_reason\n"
                "102,,Leg Day,2025-01-16T18:00:00Z,600,3,20,too_tired\n"
            ),
        })

        with patch("services.data_import.get_supabase_db", return_value=mock_db):
            import_user_data("user-123", zip_bytes)

        written = mock_db.create_workout_log.call_args.args[0]
        assert written["status"] == "abandoned"
        assert written["status"] != "in_progress"

    def test_explicit_valid_status_column_is_honored(self, mock_db, sample_user):
        """If a future/different export ever includes a genuine `status`
        column, it wins over the exit_reason inference."""
        mock_db.get_user.return_value = sample_user
        mock_db.create_workout_log.return_value = {"id": "new-log-3"}

        zip_bytes = _zip_with({
            "workout_logs.csv": (
                "log_id,workout_id,workout_name,completed_at,total_time_seconds,"
                "status\n"
                "103,,Rest Day Attempt,2025-01-17T18:00:00Z,120,paused\n"
            ),
        })

        with patch("services.data_import.get_supabase_db", return_value=mock_db):
            import_user_data("user-123", zip_bytes)

        written = mock_db.create_workout_log.call_args.args[0]
        assert written["status"] == "paused"


class TestWorkoutLogDurationAndExercisesCompleted:
    def test_duration_minutes_derived_from_total_time_seconds(self, mock_db, sample_user):
        mock_db.get_user.return_value = sample_user
        mock_db.create_workout_log.return_value = {"id": "new-log-4"}

        zip_bytes = _zip_with({
            "workout_logs.csv": (
                "log_id,workout_id,workout_name,completed_at,total_time_seconds\n"
                "104,,Push Day,2025-01-15T18:00:00Z,3600\n"
            ),
        })

        with patch("services.data_import.get_supabase_db", return_value=mock_db):
            import_user_data("user-123", zip_bytes)

        written = mock_db.create_workout_log.call_args.args[0]
        assert written["duration_minutes"] == 60

    def test_exercises_completed_derived_from_exercise_sets_csv(self, mock_db, sample_user):
        mock_db.get_user.return_value = sample_user
        mock_db.create_workout_log.return_value = {"id": "new-log-5"}
        mock_db.create_performance_log.return_value = {"id": "set-1"}

        zip_bytes = _zip_with({
            "workout_logs.csv": (
                "log_id,workout_id,workout_name,completed_at,total_time_seconds\n"
                "105,,Push Day,2025-01-15T18:00:00Z,3600\n"
            ),
            "exercise_sets.csv": (
                "log_id,exercise_name,set_number,reps_completed,weight_kg\n"
                "105,Bench Press,1,8,80\n"
                "105,Bench Press,2,8,80\n"
                "105,Overhead Press,1,10,40\n"
            ),
        })

        with patch("services.data_import.get_supabase_db", return_value=mock_db):
            import_user_data("user-123", zip_bytes)

        written = mock_db.create_workout_log.call_args.args[0]
        # 2 DISTINCT exercises (Bench Press, Overhead Press), not 3 sets.
        assert written["exercises_completed"] == 2

    def test_exercises_completed_absent_when_no_exercise_sets_file(self, mock_db, sample_user):
        """No exercise_sets.csv in the archive at all -> don't fabricate a 0."""
        mock_db.get_user.return_value = sample_user
        mock_db.create_workout_log.return_value = {"id": "new-log-6"}

        zip_bytes = _zip_with({
            "workout_logs.csv": (
                "log_id,workout_id,workout_name,completed_at,total_time_seconds\n"
                "106,,Push Day,2025-01-15T18:00:00Z,3600\n"
            ),
        })

        with patch("services.data_import.get_supabase_db", return_value=mock_db):
            import_user_data("user-123", zip_bytes)

        written = mock_db.create_workout_log.call_args.args[0]
        assert "exercises_completed" not in written


class TestWorkoutLogFailureReporting:
    def test_failed_rows_are_reported_not_silently_dropped(self, mock_db, sample_user):
        """One row succeeds, one raises inside db.create_workout_log — the
        failure must surface in `counts`, not just vanish into a smaller
        success count."""
        mock_db.get_user.return_value = sample_user
        mock_db.create_workout_log.side_effect = [
            {"id": "ok-1"},
            Exception("simulated DB failure"),
        ]

        zip_bytes = _zip_with({
            "workout_logs.csv": (
                "log_id,workout_id,workout_name,completed_at,total_time_seconds\n"
                "201,,Push Day,2025-01-15T18:00:00Z,3600\n"
                "202,,Pull Day,2025-01-16T18:00:00Z,3000\n"
            ),
        })

        with patch("services.data_import.get_supabase_db", return_value=mock_db):
            counts = import_user_data("user-123", zip_bytes)

        assert counts.get("workout_logs") == 1
        assert counts.get("workout_logs_failed") == 1

    def test_all_rows_succeed_no_failed_key(self, mock_db, sample_user):
        """When nothing fails, no `_failed` key is added (keeps the common
        case's response uncluttered)."""
        mock_db.get_user.return_value = sample_user
        mock_db.create_workout_log.return_value = {"id": "ok-1"}

        zip_bytes = _zip_with({
            "workout_logs.csv": (
                "log_id,workout_id,workout_name,completed_at,total_time_seconds\n"
                "301,,Push Day,2025-01-15T18:00:00Z,3600\n"
            ),
        })

        with patch("services.data_import.get_supabase_db", return_value=mock_db):
            counts = import_user_data("user-123", zip_bytes)

        assert counts.get("workout_logs") == 1
        assert "workout_logs_failed" not in counts
