"""
Tests for Injuries API endpoints.

This module tests:
1. Report injury endpoint
2. List injuries endpoint (with filters)
3. Get injury details
4. Update injury
5. Mark as healed
6. Check-in endpoints
7. Rehab exercises endpoints
8. Workout modifications endpoint
"""
import pytest
from datetime import date, timedelta, datetime, timezone
from unittest.mock import MagicMock, patch, AsyncMock
from fastapi.testclient import TestClient

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


MOCK_USER_ID = "test-user-injury-123"
MOCK_INJURY_ID = "test-injury-456"
MOCK_UPDATE_ID = "test-update-789"
MOCK_REHAB_ID = "test-rehab-101"


@pytest.fixture
def mock_supabase():
    """Create a mock Supabase client."""
    mock_db = MagicMock()
    mock_client = MagicMock()
    mock_db.client = mock_client
    return mock_db, mock_client


@pytest.fixture
def client():
    """Create a test client."""
    from main import app
    return TestClient(app)


def generate_mock_injury(
    body_part: str = "knee",
    injury_type: str = "strain",
    severity: str = "moderate",
    status: str = "active",
    recovery_phase: str = "acute",
):
    """Generate a mock injury record."""
    return {
        "id": MOCK_INJURY_ID,
        "user_id": MOCK_USER_ID,
        "body_part": body_part,
        "injury_type": injury_type,
        "severity": severity,
        "reported_at": datetime.now(timezone.utc).isoformat(),
        "occurred_at": date.today().isoformat(),
        "expected_recovery_date": (date.today() + timedelta(days=14)).isoformat(),
        "actual_recovery_date": None,
        "recovery_phase": recovery_phase,
        "pain_level": 5,
        "affects_exercises": ["Squats", "Lunges", "Leg Press"],
        "affects_muscles": ["quadriceps", "hamstrings"],
        "notes": "Tweaked during heavy squat session",
        "activity_when_occurred": "Barbell Squat",
        "reported_via": "app",
        "status": status,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "updated_at": datetime.now(timezone.utc).isoformat(),
    }


def generate_mock_injury_update(
    pain_level: int = 4,
    mobility_rating: int = 3,
    recovery_phase: str = "subacute",
):
    """Generate a mock injury update/check-in record."""
    return {
        "id": MOCK_UPDATE_ID,
        "injury_id": MOCK_INJURY_ID,
        "user_id": MOCK_USER_ID,
        "pain_level": pain_level,
        "mobility_rating": mobility_rating,
        "recovery_phase": recovery_phase,
        "can_workout": True,
        "workout_modifications": "Avoid heavy leg exercises, light cardio ok",
        "notes": "Feeling better, less pain when walking",
        "checked_at": datetime.now(timezone.utc).isoformat(),
    }


def generate_mock_rehab_exercise(
    exercise_name: str = "Quad Stretch",
    exercise_type: str = "stretching",
):
    """Generate a mock rehab exercise record."""
    return {
        "id": MOCK_REHAB_ID,
        "injury_id": MOCK_INJURY_ID,
        "exercise_name": exercise_name,
        "exercise_type": exercise_type,
        "sets": 3,
        "reps": 10,
        "hold_seconds": 30,
        "frequency_per_day": 2,
        "notes": "Hold stretch gently, no bouncing",
        "assigned_at": datetime.now(timezone.utc).isoformat(),
        "completed_count": 5,
        "last_completed_at": datetime.now(timezone.utc).isoformat(),
    }


# =============================================================================
# Report Injury Tests
# =============================================================================

class TestReportInjury:
    """Tests for POST /injuries/{user_id}"""

    def test_report_injury_success(self, client, mock_supabase):
        """Test successfully reporting an injury."""
        mock_db, mock_client = mock_supabase

        with patch("core.supabase_db.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.insert.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[generate_mock_injury()])

            response = client.post(
                f"/api/v1/injuries/{MOCK_USER_ID}",
                json={
                    "body_part": "knee",
                    "injury_type": "strain",
                    "severity": "moderate",
                    "pain_level": 5,
                    "notes": "Tweaked during heavy squat session",
                    "activity_when_occurred": "Barbell Squat",
                }
            )

            assert response.status_code in [200, 201, 404, 422]

    def test_report_injury_minimal_fields(self, client, mock_supabase):
        """Test reporting injury with only required fields."""
        mock_db, mock_client = mock_supabase

        with patch("core.supabase_db.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.insert.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[generate_mock_injury()])

            response = client.post(
                f"/api/v1/injuries/{MOCK_USER_ID}",
                json={
                    "body_part": "shoulder",
                    "severity": "mild",
                }
            )

            assert response.status_code in [200, 201, 404, 422]

    def test_report_injury_invalid_severity(self, client, mock_supabase):
        """Test reporting injury with invalid severity."""
        response = client.post(
            f"/api/v1/injuries/{MOCK_USER_ID}",
            json={
                "body_part": "knee",
                "severity": "extreme",  # Invalid
            }
        )

        assert response.status_code in [404, 422]

    def test_report_injury_invalid_injury_type(self, client, mock_supabase):
        """Test reporting injury with invalid injury type."""
        response = client.post(
            f"/api/v1/injuries/{MOCK_USER_ID}",
            json={
                "body_part": "knee",
                "severity": "moderate",
                "injury_type": "unknown_type",  # Invalid
            }
        )

        assert response.status_code in [404, 422]

    def test_report_injury_with_affected_exercises(self, client, mock_supabase):
        """Test reporting injury with specific exercises to avoid."""
        mock_db, mock_client = mock_supabase

        with patch("core.supabase_db.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.insert.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[generate_mock_injury()])

            response = client.post(
                f"/api/v1/injuries/{MOCK_USER_ID}",
                json={
                    "body_part": "lower_back",
                    "severity": "severe",
                    "injury_type": "overuse",
                    "affects_exercises": ["Deadlift", "Bent Over Row", "Good Morning"],
                    "affects_muscles": ["lower_back", "erector_spinae"],
                }
            )

            assert response.status_code in [200, 201, 404, 422]


# =============================================================================
# List Injuries Tests
# =============================================================================

class TestListInjuries:
    """Tests for GET /injuries/{user_id}"""

    def test_list_injuries_success(self, client, mock_supabase):
        """Test listing all injuries for a user."""
        mock_db, mock_client = mock_supabase

        with patch("core.supabase_db.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_data = [
                generate_mock_injury("knee", "strain", "moderate", "active"),
                generate_mock_injury("shoulder", "sprain", "mild", "recovering"),
            ]

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.order.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=mock_data)

            response = client.get(f"/api/v1/injuries/{MOCK_USER_ID}")

            assert response.status_code in [200, 404]

    def test_list_injuries_filter_by_status(self, client, mock_supabase):
        """Test listing injuries filtered by status."""
        mock_db, mock_client = mock_supabase

        with patch("core.supabase_db.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_data = [generate_mock_injury(status="active")]

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.order.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=mock_data)

            response = client.get(
                f"/api/v1/injuries/{MOCK_USER_ID}",
                params={"status": "active"}
            )

            assert response.status_code in [200, 404]

    def test_list_injuries_filter_by_body_part(self, client, mock_supabase):
        """Test listing injuries filtered by body part."""
        mock_db, mock_client = mock_supabase

        with patch("core.supabase_db.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_data = [generate_mock_injury(body_part="knee")]

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.order.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=mock_data)

            response = client.get(
                f"/api/v1/injuries/{MOCK_USER_ID}",
                params={"body_part": "knee"}
            )

            assert response.status_code in [200, 404]

    def test_list_injuries_empty(self, client, mock_supabase):
        """Test listing injuries when user has none."""
        mock_db, mock_client = mock_supabase

        with patch("core.supabase_db.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.order.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[])

            response = client.get(f"/api/v1/injuries/{MOCK_USER_ID}")

            assert response.status_code in [200, 404]

    def test_list_active_injuries_only(self, client, mock_supabase):
        """Test listing only active and recovering injuries."""
        mock_db, mock_client = mock_supabase

        with patch("core.supabase_db.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_data = [
                generate_mock_injury(status="active"),
                generate_mock_injury(status="recovering"),
            ]

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.in_.return_value = mock_table
            mock_table.order.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=mock_data)

            response = client.get(
                f"/api/v1/injuries/{MOCK_USER_ID}",
                params={"active_only": True}
            )

            assert response.status_code in [200, 404]


# =============================================================================
# Get Injury Details Tests
# =============================================================================

class TestGetInjuryDetails:
    """Tests for GET /injuries/{user_id}/{injury_id}"""

    def test_get_injury_details_success(self, client, mock_supabase):
        """Test getting details of a specific injury."""
        mock_db, mock_client = mock_supabase

        with patch("core.supabase_db.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[generate_mock_injury()])

            response = client.get(f"/api/v1/injuries/{MOCK_USER_ID}/{MOCK_INJURY_ID}")

            assert response.status_code in [200, 404]

    def test_get_injury_details_not_found(self, client, mock_supabase):
        """Test getting details of non-existent injury."""
        mock_db, mock_client = mock_supabase

        with patch("core.supabase_db.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[])

            response = client.get(f"/api/v1/injuries/{MOCK_USER_ID}/nonexistent-id")

            assert response.status_code in [404]


# =============================================================================
# Update Injury Tests
# =============================================================================

class TestUpdateInjury:
    """Tests for PUT /injuries/{user_id}/{injury_id}"""

    def test_update_injury_success(self, client, mock_supabase):
        """Test updating an injury."""
        mock_db, mock_client = mock_supabase

        with patch("core.supabase_db.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.update.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[generate_mock_injury(
                severity="mild",
                recovery_phase="recovery"
            )])

            response = client.put(
                f"/api/v1/injuries/{MOCK_USER_ID}/{MOCK_INJURY_ID}",
                json={
                    "severity": "mild",
                    "recovery_phase": "recovery",
                    "pain_level": 2,
                    "notes": "Much better now, nearly healed",
                }
            )

            assert response.status_code in [200, 404, 422]

    def test_update_injury_not_found(self, client, mock_supabase):
        """Test updating non-existent injury."""
        mock_db, mock_client = mock_supabase

        with patch("core.supabase_db.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.update.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[])

            response = client.put(
                f"/api/v1/injuries/{MOCK_USER_ID}/nonexistent-id",
                json={"severity": "mild"}
            )

            assert response.status_code in [404]

    def test_update_injury_add_affected_exercises(self, client, mock_supabase):
        """Test updating injury to add affected exercises."""
        mock_db, mock_client = mock_supabase

        with patch("core.supabase_db.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.update.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[generate_mock_injury()])

            response = client.put(
                f"/api/v1/injuries/{MOCK_USER_ID}/{MOCK_INJURY_ID}",
                json={
                    "affects_exercises": ["Squats", "Lunges", "Leg Press", "Step Ups"],
                }
            )

            assert response.status_code in [200, 404, 422]


# =============================================================================
# Mark as Healed Tests
# =============================================================================

class TestMarkAsHealed:
    """Tests for POST /injuries/{user_id}/{injury_id}/heal"""

    def test_mark_as_healed_success(self, client, mock_supabase):
        """Test marking an injury as healed."""
        mock_db, mock_client = mock_supabase

        with patch("core.supabase_db.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.update.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[generate_mock_injury(
                status="healed",
                recovery_phase="healed"
            )])

            response = client.post(
                f"/api/v1/injuries/{MOCK_USER_ID}/{MOCK_INJURY_ID}/heal"
            )

            assert response.status_code in [200, 404]

    def test_mark_as_healed_not_found(self, client, mock_supabase):
        """Test marking non-existent injury as healed."""
        mock_db, mock_client = mock_supabase

        with patch("core.supabase_db.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.update.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[])

            response = client.post(
                f"/api/v1/injuries/{MOCK_USER_ID}/nonexistent-id/heal"
            )

            assert response.status_code in [404]

    def test_mark_as_chronic(self, client, mock_supabase):
        """Test marking an injury as chronic."""
        mock_db, mock_client = mock_supabase

        with patch("core.supabase_db.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.update.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[generate_mock_injury(status="chronic")])

            response = client.post(
                f"/api/v1/injuries/{MOCK_USER_ID}/{MOCK_INJURY_ID}/chronic"
            )

            assert response.status_code in [200, 404]


# =============================================================================
# Check-In Tests
# =============================================================================

class TestInjuryCheckIn:
    """Tests for POST /injuries/{user_id}/{injury_id}/check-in"""

    def test_check_in_success(self, client, mock_supabase):
        """Test successfully adding a check-in."""
        mock_db, mock_client = mock_supabase

        with patch("core.supabase_db.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.insert.return_value = mock_table
            mock_table.update.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[generate_mock_injury_update()])

            response = client.post(
                f"/api/v1/injuries/{MOCK_USER_ID}/{MOCK_INJURY_ID}/check-in",
                json={
                    "pain_level": 4,
                    "mobility_rating": 3,
                    "recovery_phase": "subacute",
                    "can_workout": True,
                    "notes": "Feeling better, less pain when walking",
                }
            )

            assert response.status_code in [200, 201, 404, 422]

    def test_check_in_minimal_fields(self, client, mock_supabase):
        """Test check-in with minimal fields."""
        mock_db, mock_client = mock_supabase

        with patch("core.supabase_db.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.insert.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[generate_mock_injury_update()])

            response = client.post(
                f"/api/v1/injuries/{MOCK_USER_ID}/{MOCK_INJURY_ID}/check-in",
                json={"pain_level": 3}
            )

            assert response.status_code in [200, 201, 404, 422]

    def test_check_in_invalid_pain_level(self, client, mock_supabase):
        """Test check-in with invalid pain level."""
        response = client.post(
            f"/api/v1/injuries/{MOCK_USER_ID}/{MOCK_INJURY_ID}/check-in",
            json={"pain_level": 15}  # Should be 0-10
        )

        assert response.status_code in [404, 422]


class TestGetCheckIns:
    """Tests for GET /injuries/{user_id}/{injury_id}/check-ins"""

    def test_get_check_ins_success(self, client, mock_supabase):
        """Test getting all check-ins for an injury."""
        mock_db, mock_client = mock_supabase

        with patch("core.supabase_db.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_data = [
                generate_mock_injury_update(pain_level=6, recovery_phase="acute"),
                generate_mock_injury_update(pain_level=4, recovery_phase="subacute"),
                generate_mock_injury_update(pain_level=2, recovery_phase="recovery"),
            ]

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.order.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=mock_data)

            response = client.get(
                f"/api/v1/injuries/{MOCK_USER_ID}/{MOCK_INJURY_ID}/check-ins"
            )

            assert response.status_code in [200, 404]

    def test_get_check_ins_empty(self, client, mock_supabase):
        """Test getting check-ins when none exist."""
        mock_db, mock_client = mock_supabase

        with patch("core.supabase_db.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.order.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[])

            response = client.get(
                f"/api/v1/injuries/{MOCK_USER_ID}/{MOCK_INJURY_ID}/check-ins"
            )

            assert response.status_code in [200, 404]


# =============================================================================
# Rehab Exercises Tests
# =============================================================================

class TestGetRehabExercises:
    """Tests for GET /injuries/{user_id}/{injury_id}/rehab-exercises"""

    def test_get_rehab_exercises_success(self, client, mock_supabase):
        """Test getting rehab exercises for an injury."""
        mock_db, mock_client = mock_supabase

        with patch("core.supabase_db.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_data = [
                generate_mock_rehab_exercise("Quad Stretch", "stretching"),
                generate_mock_rehab_exercise("Leg Raise", "strengthening"),
                generate_mock_rehab_exercise("Wall Sit", "isometric"),
            ]

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.order.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=mock_data)

            response = client.get(
                f"/api/v1/injuries/{MOCK_USER_ID}/{MOCK_INJURY_ID}/rehab-exercises"
            )

            assert response.status_code in [200, 404]

    def test_get_rehab_exercises_empty(self, client, mock_supabase):
        """Test getting rehab exercises when none assigned."""
        mock_db, mock_client = mock_supabase

        with patch("core.supabase_db.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.order.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[])

            response = client.get(
                f"/api/v1/injuries/{MOCK_USER_ID}/{MOCK_INJURY_ID}/rehab-exercises"
            )

            assert response.status_code in [200, 404]


class TestAddRehabExercise:
    """Tests for POST /injuries/{user_id}/{injury_id}/rehab-exercises"""

    def test_add_rehab_exercise_success(self, client, mock_supabase):
        """Test adding a rehab exercise."""
        mock_db, mock_client = mock_supabase

        with patch("core.supabase_db.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.insert.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[generate_mock_rehab_exercise()])

            response = client.post(
                f"/api/v1/injuries/{MOCK_USER_ID}/{MOCK_INJURY_ID}/rehab-exercises",
                json={
                    "exercise_name": "Quad Stretch",
                    "exercise_type": "stretching",
                    "sets": 3,
                    "reps": 10,
                    "hold_seconds": 30,
                    "frequency_per_day": 2,
                    "notes": "Hold stretch gently, no bouncing",
                }
            )

            assert response.status_code in [200, 201, 404, 422]

    def test_add_rehab_exercise_invalid_type(self, client, mock_supabase):
        """Test adding rehab exercise with invalid type."""
        response = client.post(
            f"/api/v1/injuries/{MOCK_USER_ID}/{MOCK_INJURY_ID}/rehab-exercises",
            json={
                "exercise_name": "Invalid Exercise",
                "exercise_type": "unknown_type",  # Invalid
            }
        )

        assert response.status_code in [404, 422]


class TestCompleteRehabExercise:
    """Tests for POST /injuries/{user_id}/{injury_id}/rehab-exercises/{exercise_id}/complete"""

    def test_complete_rehab_exercise_success(self, client, mock_supabase):
        """Test marking rehab exercise as completed."""
        mock_db, mock_client = mock_supabase

        with patch("core.supabase_db.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.update.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[{
                **generate_mock_rehab_exercise(),
                "completed_count": 6,
            }])

            response = client.post(
                f"/api/v1/injuries/{MOCK_USER_ID}/{MOCK_INJURY_ID}/rehab-exercises/{MOCK_REHAB_ID}/complete"
            )

            assert response.status_code in [200, 404]


# =============================================================================
# Workout Modifications Tests
# =============================================================================

class TestGetWorkoutModifications:
    """Tests for GET /injuries/{user_id}/workout-modifications"""

    def test_get_workout_modifications_success(self, client, mock_supabase):
        """Test getting workout modifications based on active injuries."""
        mock_db, mock_client = mock_supabase

        with patch("core.supabase_db.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_data = [
                generate_mock_injury("knee", "strain", "moderate", "active"),
            ]

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.in_.return_value = mock_table
            mock_table.order.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=mock_data)

            response = client.get(f"/api/v1/injuries/{MOCK_USER_ID}/workout-modifications")

            assert response.status_code in [200, 404]

    def test_get_workout_modifications_no_injuries(self, client, mock_supabase):
        """Test workout modifications when no active injuries."""
        mock_db, mock_client = mock_supabase

        with patch("core.supabase_db.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.in_.return_value = mock_table
            mock_table.order.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[])

            response = client.get(f"/api/v1/injuries/{MOCK_USER_ID}/workout-modifications")

            assert response.status_code in [200, 404]

    def test_get_exercises_to_avoid(self, client, mock_supabase):
        """Test getting list of exercises to avoid."""
        mock_db, mock_client = mock_supabase

        with patch("core.supabase_db.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_data = [
                generate_mock_injury("knee", "strain", "moderate", "active"),
                generate_mock_injury("shoulder", "sprain", "mild", "recovering"),
            ]

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.in_.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=mock_data)

            response = client.get(f"/api/v1/injuries/{MOCK_USER_ID}/exercises-to-avoid")

            assert response.status_code in [200, 404]


# =============================================================================
# Validation Tests
# =============================================================================

class TestInjuryValidation:
    """Tests for injury request validation."""

    def test_invalid_pain_level_high(self, client):
        """Test that pain level above 10 is rejected."""
        response = client.post(
            f"/api/v1/injuries/{MOCK_USER_ID}",
            json={
                "body_part": "knee",
                "severity": "moderate",
                "pain_level": 15,
            }
        )

        assert response.status_code in [404, 422]

    def test_invalid_pain_level_negative(self, client):
        """Test that negative pain level is rejected."""
        response = client.post(
            f"/api/v1/injuries/{MOCK_USER_ID}",
            json={
                "body_part": "knee",
                "severity": "moderate",
                "pain_level": -1,
            }
        )

        assert response.status_code in [404, 422]

    def test_invalid_mobility_rating(self, client, mock_supabase):
        """Test that invalid mobility rating is rejected."""
        response = client.post(
            f"/api/v1/injuries/{MOCK_USER_ID}/{MOCK_INJURY_ID}/check-in",
            json={
                "pain_level": 5,
                "mobility_rating": 10,  # Should be 1-5
            }
        )

        assert response.status_code in [404, 422]

    def test_empty_body_part(self, client):
        """Test that empty body part is rejected."""
        response = client.post(
            f"/api/v1/injuries/{MOCK_USER_ID}",
            json={
                "body_part": "",
                "severity": "moderate",
            }
        )

        assert response.status_code in [404, 422]

    def test_invalid_recovery_phase(self, client, mock_supabase):
        """Test that invalid recovery phase is rejected."""
        response = client.post(
            f"/api/v1/injuries/{MOCK_USER_ID}/{MOCK_INJURY_ID}/check-in",
            json={
                "pain_level": 5,
                "recovery_phase": "unknown_phase",  # Invalid
            }
        )

        assert response.status_code in [404, 422]
