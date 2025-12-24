"""
Tests for Data Import and Export Services.

Tests:
- Data export to ZIP
- Data import from ZIP
- CSV parsing and generation
- ID mapping during import
- Date filtering

Run with: pytest backend/tests/test_data_import_export.py -v
"""

import pytest
import csv
import io
import json
import zipfile
from unittest.mock import MagicMock, patch
from datetime import datetime

from services.data_export import (
    export_user_data, EXPORT_VERSION, APP_VERSION,
    _export_profile, _export_body_metrics, _export_workouts,
    _export_workout_logs, _export_exercise_sets, _export_strength_records,
    _export_achievements, _export_streaks, _export_metadata
)
from services.data_import import (
    import_user_data, SUPPORTED_VERSIONS,
    _parse_csv, _parse_metadata, _validate_metadata, _parse_profile
)


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
        "goals": ["build_muscle", "lose_fat"],
        "equipment": ["barbell", "dumbbells"],
        "height_cm": 175,
        "weight_kg": 80,
        "target_weight_kg": 75,
        "age": 30,
        "gender": "male",
        "activity_level": "moderately_active",
        "active_injuries": ["back"],
    }


@pytest.fixture
def sample_metrics():
    """Sample body metrics data."""
    return [
        {
            "recorded_at": "2025-01-15T10:00:00Z",
            "weight_kg": 80.0,
            "waist_cm": 85.0,
            "hip_cm": 100.0,
            "neck_cm": 40.0,
            "body_fat_measured": 18.0,
            "resting_heart_rate": 65,
        },
    ]


@pytest.fixture
def sample_workouts():
    """Sample workouts data."""
    return [
        {
            "id": 1,
            "name": "Push Day",
            "type": "strength",
            "difficulty": "intermediate",
            "scheduled_date": "2025-01-15",
            "is_completed": True,
            "duration_minutes": 60,
            "exercises_json": [
                {"name": "Bench Press", "sets": 4, "reps": 8}
            ],
        },
    ]


@pytest.fixture
def sample_workout_logs():
    """Sample workout logs data."""
    return [
        {
            "id": 101,
            "workout_id": 1,
            "workout_name": "Push Day",
            "completed_at": "2025-01-15T18:00:00Z",
            "total_time_seconds": 3600,
            "sets_json": [
                {"exercise": "Bench Press", "set": 1, "reps": 8, "weight": 80}
            ],
        },
    ]


@pytest.fixture
def sample_performance_logs():
    """Sample performance logs data."""
    return [
        {
            "workout_log_id": 101,
            "exercise_name": "Bench Press",
            "set_number": 1,
            "reps_completed": 8,
            "weight_kg": 80.0,
            "rpe": 7.5,
            "is_completed": True,
            "notes": "Felt strong",
        },
    ]


@pytest.fixture
def sample_strength_records():
    """Sample strength records data."""
    return [
        {
            "exercise_name": "Bench Press",
            "weight_kg": 100.0,
            "reps": 1,
            "estimated_1rm": 100.0,
            "achieved_at": "2025-01-15T18:30:00Z",
            "is_pr": True,
        },
    ]


@pytest.fixture
def sample_achievements():
    """Sample achievements data."""
    return [
        {
            "earned_at": "2025-01-15T18:30:00Z",
            "trigger_value": 100.0,
            "achievement_types": {
                "name": "100kg Club",
                "category": "strength",
                "tier": "gold",
            },
        },
    ]


@pytest.fixture
def sample_streaks():
    """Sample streaks data."""
    return [
        {
            "streak_type": "workout",
            "current_streak": 7,
            "longest_streak": 14,
            "last_activity_date": "2025-01-15",
            "streak_start_date": "2025-01-08",
        },
    ]


# ============================================================
# EXPORT PROFILE TESTS
# ============================================================

class TestExportProfile:
    """Test profile export."""

    def test_export_profile_basic(self, sample_user):
        """Test exporting profile to CSV."""
        csv_content = _export_profile(sample_user)

        # Parse CSV
        reader = csv.DictReader(io.StringIO(csv_content))
        rows = list(reader)

        assert len(rows) == 1
        assert rows[0]["name"] == "John Doe"
        assert rows[0]["email"] == "john@example.com"
        assert rows[0]["fitness_level"] == "intermediate"

    def test_export_profile_lists_as_comma_separated(self, sample_user):
        """Test list fields are exported as comma-separated."""
        csv_content = _export_profile(sample_user)

        reader = csv.DictReader(io.StringIO(csv_content))
        row = list(reader)[0]

        assert "build_muscle" in row["goals"]
        assert "lose_fat" in row["goals"]
        assert "barbell" in row["equipment"]

    def test_export_profile_handles_json_strings(self):
        """Test handling JSON string fields."""
        user = {
            "name": "Test",
            "email": "test@test.com",
            "goals": '["goal1", "goal2"]',  # JSON string
            "equipment": '["eq1"]',  # JSON string
            "active_injuries": '[]',
        }

        csv_content = _export_profile(user)
        reader = csv.DictReader(io.StringIO(csv_content))
        row = list(reader)[0]

        assert "goal1" in row["goals"]


# ============================================================
# EXPORT BODY METRICS TESTS
# ============================================================

class TestExportBodyMetrics:
    """Test body metrics export."""

    def test_export_body_metrics_basic(self, sample_metrics):
        """Test exporting body metrics."""
        csv_content = _export_body_metrics(sample_metrics)

        reader = csv.DictReader(io.StringIO(csv_content))
        rows = list(reader)

        assert len(rows) == 1
        assert rows[0]["weight_kg"] == "80.0"
        assert rows[0]["waist_cm"] == "85.0"

    def test_export_body_metrics_empty(self):
        """Test exporting empty metrics."""
        csv_content = _export_body_metrics([])

        reader = csv.DictReader(io.StringIO(csv_content))
        rows = list(reader)

        assert len(rows) == 0

    def test_export_body_metrics_uses_measured_over_calculated(self):
        """Test body fat uses measured value over calculated."""
        metrics = [{
            "recorded_at": "2025-01-15",
            "body_fat_measured": 18.0,
            "body_fat_calculated": 20.0,
        }]

        csv_content = _export_body_metrics(metrics)
        reader = csv.DictReader(io.StringIO(csv_content))
        row = list(reader)[0]

        assert row["body_fat_percent"] == "18.0"


# ============================================================
# EXPORT WORKOUTS TESTS
# ============================================================

class TestExportWorkouts:
    """Test workouts export."""

    def test_export_workouts_basic(self, sample_workouts):
        """Test exporting workouts."""
        csv_content = _export_workouts(sample_workouts)

        reader = csv.DictReader(io.StringIO(csv_content))
        rows = list(reader)

        assert len(rows) == 1
        assert rows[0]["name"] == "Push Day"
        assert rows[0]["type"] == "strength"

    def test_export_workouts_exercises_as_json(self, sample_workouts):
        """Test exercises are exported as JSON."""
        csv_content = _export_workouts(sample_workouts)

        reader = csv.DictReader(io.StringIO(csv_content))
        row = list(reader)[0]

        exercises = json.loads(row["exercises_json"])
        assert len(exercises) == 1
        assert exercises[0]["name"] == "Bench Press"


# ============================================================
# EXPORT WORKOUT LOGS TESTS
# ============================================================

class TestExportWorkoutLogs:
    """Test workout logs export."""

    def test_export_workout_logs_basic(self, sample_workout_logs):
        """Test exporting workout logs."""
        csv_content = _export_workout_logs(sample_workout_logs)

        reader = csv.DictReader(io.StringIO(csv_content))
        rows = list(reader)

        assert len(rows) == 1
        assert rows[0]["workout_name"] == "Push Day"
        assert rows[0]["total_time_seconds"] == "3600"

    def test_export_workout_logs_calculates_totals(self, sample_workout_logs):
        """Test totals are calculated from sets_json."""
        csv_content = _export_workout_logs(sample_workout_logs)

        reader = csv.DictReader(io.StringIO(csv_content))
        row = list(reader)[0]

        assert row["total_sets"] == "1"
        assert row["total_reps"] == "8"


# ============================================================
# EXPORT EXERCISE SETS TESTS
# ============================================================

class TestExportExerciseSets:
    """Test exercise sets export."""

    def test_export_exercise_sets_basic(self, sample_performance_logs):
        """Test exporting exercise sets."""
        csv_content = _export_exercise_sets(sample_performance_logs)

        reader = csv.DictReader(io.StringIO(csv_content))
        rows = list(reader)

        assert len(rows) == 1
        assert rows[0]["exercise_name"] == "Bench Press"
        assert rows[0]["weight_kg"] == "80.0"


# ============================================================
# EXPORT STRENGTH RECORDS TESTS
# ============================================================

class TestExportStrengthRecords:
    """Test strength records export."""

    def test_export_strength_records_basic(self, sample_strength_records):
        """Test exporting strength records."""
        csv_content = _export_strength_records(sample_strength_records)

        reader = csv.DictReader(io.StringIO(csv_content))
        rows = list(reader)

        assert len(rows) == 1
        assert rows[0]["exercise_name"] == "Bench Press"
        assert rows[0]["estimated_1rm"] == "100.0"
        assert rows[0]["is_pr"] == "True"


# ============================================================
# EXPORT ACHIEVEMENTS TESTS
# ============================================================

class TestExportAchievements:
    """Test achievements export."""

    def test_export_achievements_basic(self, sample_achievements):
        """Test exporting achievements."""
        csv_content = _export_achievements(sample_achievements)

        reader = csv.DictReader(io.StringIO(csv_content))
        rows = list(reader)

        assert len(rows) == 1
        assert rows[0]["achievement_name"] == "100kg Club"
        assert rows[0]["achievement_type"] == "strength"
        assert rows[0]["tier"] == "gold"


# ============================================================
# EXPORT STREAKS TESTS
# ============================================================

class TestExportStreaks:
    """Test streaks export."""

    def test_export_streaks_basic(self, sample_streaks):
        """Test exporting streaks."""
        csv_content = _export_streaks(sample_streaks)

        reader = csv.DictReader(io.StringIO(csv_content))
        rows = list(reader)

        assert len(rows) == 1
        assert rows[0]["streak_type"] == "workout"
        assert rows[0]["current_streak"] == "7"
        assert rows[0]["longest_streak"] == "14"


# ============================================================
# EXPORT METADATA TESTS
# ============================================================

class TestExportMetadata:
    """Test metadata export."""

    def test_export_metadata_includes_version(self):
        """Test metadata includes version info."""
        csv_content = _export_metadata("user-123", {"workouts": 10}, None, None)

        reader = csv.DictReader(io.StringIO(csv_content))
        rows = {row["key"]: row["value"] for row in reader}

        assert rows["export_version"] == EXPORT_VERSION
        assert rows["app_version"] == APP_VERSION

    def test_export_metadata_includes_counts(self):
        """Test metadata includes counts."""
        counts = {"workouts": 10, "workout_logs": 5}
        csv_content = _export_metadata("user-123", counts, None, None)

        reader = csv.DictReader(io.StringIO(csv_content))
        rows = {row["key"]: row["value"] for row in reader}

        assert rows["total_workouts"] == "10"
        assert rows["total_workout_logs"] == "5"

    def test_export_metadata_includes_date_filter(self):
        """Test metadata includes date filter when set."""
        csv_content = _export_metadata("user-123", {}, "2025-01-01", "2025-01-31")

        reader = csv.DictReader(io.StringIO(csv_content))
        rows = {row["key"]: row["value"] for row in reader}

        assert rows["filter_start_date"] == "2025-01-01"
        assert rows["filter_end_date"] == "2025-01-31"


# ============================================================
# FULL EXPORT TESTS
# ============================================================

class TestFullExport:
    """Test full data export."""

    def test_export_creates_valid_zip(self, mock_db, sample_user):
        """Test export creates valid ZIP file."""
        mock_db.get_user.return_value = sample_user

        # Mock all queries to return empty
        mock_db.client.table.return_value.select.return_value.eq.return_value = MagicMock()
        mock_db.client.table.return_value.select.return_value.eq.return_value.execute.return_value = MagicMock(data=[])
        mock_db.client.table.return_value.select.return_value.eq.return_value.gte.return_value.lte.return_value.order.return_value.limit.return_value.execute.return_value = MagicMock(data=[])
        mock_db.client.table.return_value.select.return_value.eq.return_value.gte.return_value.lte.return_value.execute.return_value = MagicMock(data=[])
        mock_db.client.table.return_value.select.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value = MagicMock(data=[])

        with patch("services.data_export.get_supabase_db", return_value=mock_db):
            zip_bytes = export_user_data("user-123")

        # Verify it's a valid ZIP
        zip_buffer = io.BytesIO(zip_bytes)
        with zipfile.ZipFile(zip_buffer, 'r') as zip_file:
            file_list = zip_file.namelist()

            assert "profile.csv" in file_list
            assert "_metadata.csv" in file_list


# ============================================================
# IMPORT PARSE TESTS
# ============================================================

class TestImportParse:
    """Test import parsing functions."""

    def test_parse_csv(self):
        """Test CSV parsing."""
        csv_content = "name,value\ntest,123\n"
        rows = _parse_csv(csv_content)

        assert len(rows) == 1
        assert rows[0]["name"] == "test"
        assert rows[0]["value"] == "123"

    def test_parse_metadata(self):
        """Test metadata parsing."""
        csv_content = "key,value\nexport_version,1.0\napp_version,1.0.0\n"
        metadata = _parse_metadata(csv_content)

        assert metadata["export_version"] == "1.0"
        assert metadata["app_version"] == "1.0.0"

    def test_validate_metadata_supported_version(self):
        """Test metadata validation with supported version."""
        metadata = {"export_version": "1.0"}

        # Should not raise
        _validate_metadata(metadata)

    def test_validate_metadata_unsupported_version_warns(self):
        """Test metadata validation with unsupported version warns."""
        metadata = {"export_version": "99.0"}

        # Should not raise, just warn
        _validate_metadata(metadata)

    def test_parse_profile(self):
        """Test profile parsing."""
        csv_content = "name,fitness_level\nJohn,intermediate\n"
        profile = _parse_profile(csv_content)

        assert profile["name"] == "John"
        assert profile["fitness_level"] == "intermediate"

    def test_parse_profile_empty(self):
        """Test parsing empty profile."""
        csv_content = "name,fitness_level\n"
        profile = _parse_profile(csv_content)

        assert profile is None


# ============================================================
# FULL IMPORT TESTS
# ============================================================

class TestFullImport:
    """Test full data import."""

    def test_import_user_not_found(self, mock_db):
        """Test import fails if user not found."""
        mock_db.get_user.return_value = None

        # Create minimal ZIP
        zip_buffer = io.BytesIO()
        with zipfile.ZipFile(zip_buffer, 'w') as zip_file:
            zip_file.writestr("_metadata.csv", "key,value\nexport_version,1.0\n")
        zip_bytes = zip_buffer.getvalue()

        with patch("services.data_import.get_supabase_db", return_value=mock_db):
            with pytest.raises(ValueError, match="not found"):
                import_user_data("nonexistent", zip_bytes)

    def test_import_invalid_zip(self, mock_db, sample_user):
        """Test import fails with invalid ZIP."""
        mock_db.get_user.return_value = sample_user

        with patch("services.data_import.get_supabase_db", return_value=mock_db):
            with pytest.raises(ValueError, match="Invalid ZIP"):
                import_user_data("user-123", b"not a zip file")

    def test_import_with_profile(self, mock_db, sample_user):
        """Test importing profile data."""
        mock_db.get_user.return_value = sample_user
        mock_db.update_user.return_value = None

        # Create ZIP with profile
        zip_buffer = io.BytesIO()
        with zipfile.ZipFile(zip_buffer, 'w') as zip_file:
            zip_file.writestr("_metadata.csv", "key,value\nexport_version,1.0\n")
            zip_file.writestr("profile.csv", "fitness_level,goals\nadvanced,strength,endurance\n")
        zip_bytes = zip_buffer.getvalue()

        with patch("services.data_import.get_supabase_db", return_value=mock_db):
            counts = import_user_data("user-123", zip_bytes)

        assert counts.get("profile") == 1
        mock_db.update_user.assert_called_once()

    def test_import_with_workouts(self, mock_db, sample_user):
        """Test importing workout data."""
        mock_db.get_user.return_value = sample_user
        mock_db.create_workout.return_value = {"id": 999}

        # Create ZIP with workouts
        zip_buffer = io.BytesIO()
        with zipfile.ZipFile(zip_buffer, 'w') as zip_file:
            zip_file.writestr("_metadata.csv", "key,value\nexport_version,1.0\n")
            zip_file.writestr(
                "workouts.csv",
                "workout_id,name,type,difficulty,scheduled_date,is_completed,exercises_json\n"
                "1,Push Day,strength,intermediate,2025-01-15,true,[]\n"
            )
        zip_bytes = zip_buffer.getvalue()

        with patch("services.data_import.get_supabase_db", return_value=mock_db):
            counts = import_user_data("user-123", zip_bytes)

        assert counts.get("workouts") == 1

    def test_import_without_metadata_still_works(self, mock_db, sample_user):
        """Test import works without metadata file (lenient)."""
        mock_db.get_user.return_value = sample_user

        # Create ZIP without metadata
        zip_buffer = io.BytesIO()
        with zipfile.ZipFile(zip_buffer, 'w') as zip_file:
            zip_file.writestr("profile.csv", "fitness_level\nadvanced\n")
        zip_bytes = zip_buffer.getvalue()

        with patch("services.data_import.get_supabase_db", return_value=mock_db):
            counts = import_user_data("user-123", zip_bytes)

        assert counts.get("profile") == 1


# ============================================================
# CONSTANTS TESTS
# ============================================================

class TestConstants:
    """Test constants."""

    def test_export_version_defined(self):
        """Test export version is defined."""
        assert EXPORT_VERSION is not None
        assert len(EXPORT_VERSION) > 0

    def test_supported_versions_includes_current(self):
        """Test supported versions includes current version."""
        assert EXPORT_VERSION in SUPPORTED_VERSIONS

    def test_app_version_defined(self):
        """Test app version is defined."""
        assert APP_VERSION is not None


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
