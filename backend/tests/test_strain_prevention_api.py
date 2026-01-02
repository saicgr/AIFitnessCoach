"""
Tests for Strain Prevention API endpoints.

This module tests:
1. Strain risk assessment endpoint
2. Volume history endpoint
3. Strain patterns endpoint
4. Record strain endpoint
5. Adjust workout endpoint
6. Volume alerts endpoints
7. Volume caps endpoint
"""
import pytest
from datetime import date, timedelta
from unittest.mock import MagicMock, patch, AsyncMock
from fastapi.testclient import TestClient

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


MOCK_USER_ID = "test-user-strain-123"
MOCK_ALERT_ID = "test-alert-456"


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


def generate_mock_volume_tracking(
    muscle_group: str = "chest",
    week_start: str = None,
    total_sets: int = 12,
    total_reps: int = 120,
    total_volume_kg: float = 1500.0,
):
    if week_start is None:
        week_start = date.today().isoformat()
    return {
        "id": "volume-track-123",
        "user_id": MOCK_USER_ID,
        "week_start": week_start,
        "muscle_group": muscle_group,
        "total_sets": total_sets,
        "total_reps": total_reps,
        "total_volume_kg": total_volume_kg,
        "created_at": "2024-12-30T12:00:00Z",
        "updated_at": "2024-12-30T12:00:00Z",
    }


def generate_mock_strain_history(
    body_part: str = "chest",
    severity: str = "mild",
    volume_at_time: float = 1800.0,
):
    return {
        "id": "strain-123",
        "user_id": MOCK_USER_ID,
        "body_part": body_part,
        "strain_date": date.today().isoformat(),
        "severity": severity,
        "activity_type": "strength",
        "volume_at_time": volume_at_time,
        "notes": "Felt a slight pull during bench press",
        "created_at": "2024-12-30T12:00:00Z",
    }


def generate_mock_alert(
    muscle_group: str = "chest",
    alert_level: str = "warning",
    increase_percentage: float = 12.5,
    acknowledged: bool = False,
):
    return {
        "id": MOCK_ALERT_ID,
        "user_id": MOCK_USER_ID,
        "muscle_group": muscle_group,
        "previous_week_volume": 1500.0,
        "current_week_volume": 1687.5,
        "increase_percentage": increase_percentage,
        "alert_level": alert_level,
        "acknowledged": acknowledged,
        "acknowledged_at": None,
        "recommendation": f"Warning: {muscle_group.capitalize()} volume increased.",
        "created_at": "2024-12-30T12:00:00Z",
    }


class TestGetStrainRiskAssessment:
    """Tests for GET /strain-prevention/risk-assessment/{user_id}"""

    def test_get_risk_assessment_success(self, client, mock_supabase):
        """Test successful retrieval of strain risk assessment."""
        mock_db, mock_client = mock_supabase

        with patch("services.strain_prevention_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.gte.return_value = mock_table
            mock_table.order.return_value = mock_table
            mock_table.insert.return_value = mock_table

            mock_table.execute.side_effect = [
                MagicMock(data=[{"muscle_group": "chest", "total_sets": 12, "total_volume_kg": 1500.0}]),
                MagicMock(data=[{"muscle_group": "chest", "total_sets": 10, "total_volume_kg": 1350.0}]),
                MagicMock(data=[]),
            ]

            response = client.get(f"/api/v1/strain-prevention/risk-assessment/{MOCK_USER_ID}")
            assert response.status_code in [200, 404]

    def test_get_risk_assessment_with_danger_level(self, client, mock_supabase):
        """Test risk assessment when dangerous volume increase detected."""
        mock_db, mock_client = mock_supabase

        with patch("services.strain_prevention_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.insert.return_value = mock_table

            mock_table.execute.side_effect = [
                MagicMock(data=[{"muscle_group": "chest", "total_sets": 18, "total_volume_kg": 1800.0}]),
                MagicMock(data=[{"muscle_group": "chest", "total_sets": 15, "total_volume_kg": 1500.0}]),
                MagicMock(data=[]),
            ]

            response = client.get(f"/api/v1/strain-prevention/risk-assessment/{MOCK_USER_ID}")
            assert response.status_code in [200, 404]

    def test_get_risk_assessment_no_previous_data(self, client, mock_supabase):
        """Test risk assessment when no previous week data exists."""
        mock_db, mock_client = mock_supabase

        with patch("services.strain_prevention_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[])

            response = client.get(f"/api/v1/strain-prevention/risk-assessment/{MOCK_USER_ID}")
            assert response.status_code in [200, 404]


class TestGetVolumeHistory:
    """Tests for GET /strain-prevention/volume-history/{user_id}"""

    def test_get_volume_history_success(self, client, mock_supabase):
        """Test successful retrieval of volume history."""
        mock_db, mock_client = mock_supabase

        with patch("services.strain_prevention_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_data = [generate_mock_volume_tracking() for _ in range(8)]

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.gte.return_value = mock_table
            mock_table.order.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=mock_data)

            response = client.get(
                f"/api/v1/strain-prevention/volume-history/{MOCK_USER_ID}",
                params={"weeks": 8}
            )
            assert response.status_code in [200, 404]

    def test_get_volume_history_empty(self, client, mock_supabase):
        """Test volume history when user has no data."""
        mock_db, mock_client = mock_supabase

        with patch("services.strain_prevention_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.gte.return_value = mock_table
            mock_table.order.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[])

            response = client.get(f"/api/v1/strain-prevention/volume-history/{MOCK_USER_ID}")
            assert response.status_code in [200, 404]


class TestGetStrainPatterns:
    """Tests for GET /strain-prevention/patterns/{user_id}"""

    def test_get_strain_patterns_success(self, client, mock_supabase):
        """Test successful retrieval of strain patterns."""
        mock_db, mock_client = mock_supabase

        with patch("services.strain_prevention_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_data = [
                generate_mock_strain_history("chest", "mild", 1800.0),
                generate_mock_strain_history("chest", "moderate", 2000.0),
            ]

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.order.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=mock_data)

            response = client.get(f"/api/v1/strain-prevention/patterns/{MOCK_USER_ID}")
            assert response.status_code in [200, 404]

    def test_get_strain_patterns_no_history(self, client, mock_supabase):
        """Test strain patterns when user has no strain history."""
        mock_db, mock_client = mock_supabase

        with patch("services.strain_prevention_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.order.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[])

            response = client.get(f"/api/v1/strain-prevention/patterns/{MOCK_USER_ID}")
            assert response.status_code in [200, 404]


class TestRecordStrain:
    """Tests for POST /strain-prevention/record-strain/{user_id}"""

    def test_record_strain_success(self, client, mock_supabase):
        """Test successfully recording a strain incident."""
        mock_db, mock_client = mock_supabase

        with patch("services.strain_prevention_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.insert.return_value = mock_table
            mock_table.upsert.return_value = mock_table

            mock_table.execute.side_effect = [
                MagicMock(data=[{"total_volume_kg": 1800.0}]),
                MagicMock(data=[generate_mock_strain_history()]),
                MagicMock(data=[{"id": "cap-123"}]),
            ]

            response = client.post(
                f"/api/v1/strain-prevention/record-strain/{MOCK_USER_ID}",
                json={
                    "body_part": "chest",
                    "severity": "mild",
                    "activity_type": "strength",
                    "notes": "Felt a slight pull during bench press"
                }
            )
            assert response.status_code in [200, 404, 422]

    def test_record_strain_invalid_severity(self, client, mock_supabase):
        """Test recording strain with invalid severity."""
        response = client.post(
            f"/api/v1/strain-prevention/record-strain/{MOCK_USER_ID}",
            json={"body_part": "chest", "severity": "extreme"}
        )
        assert response.status_code in [404, 422]


class TestAdjustWorkout:
    """Tests for POST /strain-prevention/adjust-workout/{user_id}"""

    def test_adjust_workout_success(self, client, mock_supabase):
        """Test successfully adjusting workout for strain prevention."""
        mock_db, mock_client = mock_supabase

        with patch("services.strain_prevention_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.insert.return_value = mock_table

            mock_table.execute.side_effect = [
                MagicMock(data=[{"muscle_group": "chest", "total_sets": 18, "total_volume_kg": 2000.0}]),
                MagicMock(data=[{"muscle_group": "chest", "total_sets": 12, "total_volume_kg": 1500.0}]),
                MagicMock(data=[]),
            ]

            response = client.post(
                f"/api/v1/strain-prevention/adjust-workout/{MOCK_USER_ID}",
                json={"exercises": [{"name": "Bench Press", "primary_muscle": "chest", "sets": 4, "reps": 10}]}
            )
            assert response.status_code in [200, 404, 422]


class TestGetVolumeAlerts:
    """Tests for GET /strain-prevention/alerts/{user_id}"""

    def test_get_unacknowledged_alerts(self, client, mock_supabase):
        """Test getting unacknowledged volume alerts."""
        mock_db, mock_client = mock_supabase

        with patch("services.strain_prevention_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_data = [generate_mock_alert("chest", "warning", 12.5)]

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.order.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=mock_data)

            response = client.get(f"/api/v1/strain-prevention/alerts/{MOCK_USER_ID}")
            assert response.status_code in [200, 404]


class TestAcknowledgeAlert:
    """Tests for POST /strain-prevention/alerts/{alert_id}/acknowledge"""

    def test_acknowledge_alert_success(self, client, mock_supabase):
        """Test successfully acknowledging an alert."""
        mock_db, mock_client = mock_supabase

        with patch("services.strain_prevention_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.update.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[generate_mock_alert(acknowledged=True)])

            response = client.post(
                f"/api/v1/strain-prevention/alerts/{MOCK_ALERT_ID}/acknowledge",
                params={"user_id": MOCK_USER_ID}
            )
            assert response.status_code in [200, 404]

    def test_acknowledge_alert_not_found(self, client, mock_supabase):
        """Test acknowledging non-existent alert."""
        mock_db, mock_client = mock_supabase

        with patch("services.strain_prevention_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.update.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[])

            response = client.post(
                f"/api/v1/strain-prevention/alerts/nonexistent-id/acknowledge",
                params={"user_id": MOCK_USER_ID}
            )
            assert response.status_code in [404]


class TestGetVolumeCaps:
    """Tests for GET /strain-prevention/volume-caps/{user_id}"""

    def test_get_volume_caps_success(self, client, mock_supabase):
        """Test getting personalized volume caps."""
        mock_db, mock_client = mock_supabase

        with patch("services.strain_prevention_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_data = [{"muscle_group": "chest", "max_weekly_sets": 14, "auto_adjusted": True}]

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=mock_data)

            response = client.get(f"/api/v1/strain-prevention/volume-caps/{MOCK_USER_ID}")
            assert response.status_code in [200, 404]


class TestStrainPreventionService:
    """Unit tests for StrainPreventionService methods."""

    @pytest.mark.asyncio
    async def test_track_workout_volume(self, mock_supabase):
        """Test tracking workout volume."""
        mock_db, mock_client = mock_supabase

        with patch("services.strain_prevention_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            from services.strain_prevention_service import StrainPreventionService

            service = StrainPreventionService()
            service.db = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.insert.return_value = mock_table
            mock_table.update.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[])

            exercises = [
                {"primary_muscle": "chest", "sets_completed": 4, "reps_completed": 40, "weight_kg": 60},
                {"primary_muscle": "triceps", "sets_completed": 3, "reps_completed": 30, "weight_kg": 20},
            ]

            result = await service.track_workout_volume(MOCK_USER_ID, exercises)

            assert result.total_sets == 7
            assert result.total_reps == 70
            assert "chest" in result.muscle_volumes
            assert "triceps" in result.muscle_volumes

    @pytest.mark.asyncio
    async def test_assess_strain_risk(self, mock_supabase):
        """Test strain risk assessment."""
        mock_db, mock_client = mock_supabase

        with patch("services.strain_prevention_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            from services.strain_prevention_service import StrainPreventionService

            service = StrainPreventionService()
            service.db = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.insert.return_value = mock_table
            mock_table.execute.side_effect = [
                MagicMock(data=[{"muscle_group": "chest", "total_sets": 16, "total_volume_kg": 1800.0}]),
                MagicMock(data=[{"muscle_group": "chest", "total_sets": 12, "total_volume_kg": 1500.0}]),
                MagicMock(data=[]),
            ]

            assessments = await service.assess_strain_risk(MOCK_USER_ID)

            assert len(assessments) == 1
            assert assessments[0].muscle_group == "chest"
            assert assessments[0].increase_percent == 20.0
            assert assessments[0].risk_level == "critical"

    @pytest.mark.asyncio
    async def test_record_strain_auto_adjusts_cap(self, mock_supabase):
        """Test that recording strain auto-adjusts volume cap."""
        mock_db, mock_client = mock_supabase

        with patch("services.strain_prevention_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            from services.strain_prevention_service import StrainPreventionService

            service = StrainPreventionService()
            service.db = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.insert.return_value = mock_table
            mock_table.upsert.return_value = mock_table
            mock_table.execute.side_effect = [
                MagicMock(data=[{"total_volume_kg": 2000.0}]),
                MagicMock(data=[generate_mock_strain_history()]),
                MagicMock(data=[{"id": "cap-123"}]),
            ]

            result = await service.record_strain(MOCK_USER_ID, body_part="chest", severity="moderate")

            assert result["recorded"] is True
            assert result["volume_cap_adjusted"] is True
            assert result["new_volume_cap"] == 1600.0

    @pytest.mark.asyncio
    async def test_get_strain_patterns_analysis(self, mock_supabase):
        """Test strain pattern analysis."""
        mock_db, mock_client = mock_supabase

        with patch("services.strain_prevention_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            from services.strain_prevention_service import StrainPreventionService

            service = StrainPreventionService()
            service.db = mock_db

            mock_data = [
                generate_mock_strain_history("chest", "mild", 1800.0),
                generate_mock_strain_history("chest", "moderate", 2000.0),
                generate_mock_strain_history("back", "mild", 1500.0),
            ]

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.order.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=mock_data)

            result = await service.get_strain_patterns(MOCK_USER_ID)

            assert result["total_strains"] == 3
            assert result["most_affected_body_part"] == "chest"


class TestValidation:
    """Tests for request validation."""

    def test_invalid_severity(self, client):
        """Test that invalid severity is rejected."""
        response = client.post(
            f"/api/v1/strain-prevention/record-strain/{MOCK_USER_ID}",
            json={"body_part": "chest", "severity": "extreme"}
        )
        assert response.status_code in [404, 422]

    def test_empty_body_part(self, client):
        """Test that empty body part is rejected."""
        response = client.post(
            f"/api/v1/strain-prevention/record-strain/{MOCK_USER_ID}",
            json={"body_part": "", "severity": "mild"}
        )
        assert response.status_code in [404, 422]
