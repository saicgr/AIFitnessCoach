"""
Tests for Hormonal Health API Endpoints
"""

import pytest
from datetime import date, timedelta
from unittest.mock import patch, MagicMock
from fastapi.testclient import TestClient
from uuid import uuid4

# Test data
TEST_USER_ID = str(uuid4())


class TestHormonalProfileEndpoints:
    """Tests for hormonal profile CRUD operations."""

    def test_get_profile_not_found(self, client, mock_supabase):
        """Test getting profile when none exists."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = []

        response = client.get(f"/api/v1/hormonal-health/profile/{TEST_USER_ID}")
        assert response.status_code == 200
        assert response.json() is None

    def test_get_profile_success(self, client, mock_supabase):
        """Test getting existing profile."""
        mock_data = {
            "id": str(uuid4()),
            "user_id": TEST_USER_ID,
            "gender": "female",
            "hormone_goals": ["balance_estrogen", "pcos_management"],
            "menstrual_tracking_enabled": True,
            "cycle_length_days": 28,
            "testosterone_optimization_enabled": False,
            "created_at": "2025-01-01T00:00:00Z",
            "updated_at": "2025-01-01T00:00:00Z",
        }
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [mock_data]

        response = client.get(f"/api/v1/hormonal-health/profile/{TEST_USER_ID}")
        assert response.status_code == 200
        data = response.json()
        assert data["user_id"] == TEST_USER_ID
        assert "balance_estrogen" in data["hormone_goals"]

    def test_upsert_profile_create(self, client, mock_supabase):
        """Test creating a new profile."""
        # No existing profile
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = []

        # Mock insert
        mock_result = {
            "id": str(uuid4()),
            "user_id": TEST_USER_ID,
            "gender": "male",
            "hormone_goals": ["optimize_testosterone"],
            "testosterone_optimization_enabled": True,
            "created_at": "2025-01-01T00:00:00Z",
            "updated_at": "2025-01-01T00:00:00Z",
        }
        mock_supabase.table.return_value.insert.return_value.execute.return_value.data = [mock_result]

        profile_data = {
            "gender": "male",
            "hormone_goals": ["optimize_testosterone"],
            "testosterone_optimization_enabled": True,
        }

        response = client.put(f"/api/v1/hormonal-health/profile/{TEST_USER_ID}", json=profile_data)
        assert response.status_code == 200

    def test_upsert_profile_update(self, client, mock_supabase):
        """Test updating an existing profile."""
        # Existing profile
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
            {"id": str(uuid4())}
        ]

        # Mock update
        mock_result = {
            "id": str(uuid4()),
            "user_id": TEST_USER_ID,
            "hormone_goals": ["balance_estrogen", "menopause_support"],
            "updated_at": "2025-01-01T00:00:00Z",
        }
        mock_supabase.table.return_value.update.return_value.eq.return_value.execute.return_value.data = [mock_result]

        profile_data = {
            "hormone_goals": ["balance_estrogen", "menopause_support"],
        }

        response = client.put(f"/api/v1/hormonal-health/profile/{TEST_USER_ID}", json=profile_data)
        assert response.status_code == 200


class TestHormoneLogEndpoints:
    """Tests for hormone log CRUD operations."""

    def test_create_log(self, client, mock_supabase):
        """Test creating a hormone log."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = []

        mock_result = {
            "id": str(uuid4()),
            "user_id": TEST_USER_ID,
            "log_date": "2025-01-01",
            "energy_level": 7,
            "mood": "good",
            "symptoms": ["fatigue"],
            "created_at": "2025-01-01T00:00:00Z",
        }
        mock_supabase.table.return_value.upsert.return_value.execute.return_value.data = [mock_result]

        log_data = {
            "log_date": "2025-01-01",
            "energy_level": 7,
            "mood": "good",
            "symptoms": ["fatigue"],
        }

        response = client.post(f"/api/v1/hormonal-health/logs/{TEST_USER_ID}", json=log_data)
        assert response.status_code == 200
        data = response.json()
        assert data["energy_level"] == 7

    def test_get_logs(self, client, mock_supabase):
        """Test getting hormone logs."""
        mock_data = [
            {
                "id": str(uuid4()),
                "user_id": TEST_USER_ID,
                "log_date": "2025-01-01",
                "energy_level": 7,
                "created_at": "2025-01-01T00:00:00Z",
            },
            {
                "id": str(uuid4()),
                "user_id": TEST_USER_ID,
                "log_date": "2024-12-31",
                "energy_level": 6,
                "created_at": "2024-12-31T00:00:00Z",
            },
        ]
        mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value.data = mock_data

        response = client.get(f"/api/v1/hormonal-health/logs/{TEST_USER_ID}")
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2

    def test_get_logs_with_date_filter(self, client, mock_supabase):
        """Test getting hormone logs with date filter."""
        mock_data = [
            {
                "id": str(uuid4()),
                "user_id": TEST_USER_ID,
                "log_date": "2025-01-01",
                "energy_level": 7,
                "created_at": "2025-01-01T00:00:00Z",
            },
        ]
        mock_supabase.table.return_value.select.return_value.eq.return_value.gte.return_value.lte.return_value.order.return_value.limit.return_value.execute.return_value.data = mock_data

        response = client.get(
            f"/api/v1/hormonal-health/logs/{TEST_USER_ID}",
            params={"start_date": "2025-01-01", "end_date": "2025-01-07"},
        )
        assert response.status_code == 200


class TestCyclePhaseEndpoints:
    """Tests for cycle phase calculations."""

    def test_get_cycle_phase_not_tracking(self, client, mock_supabase):
        """Test cycle phase when tracking is disabled."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
            {"menstrual_tracking_enabled": False}
        ]

        response = client.get(f"/api/v1/hormonal-health/cycle-phase/{TEST_USER_ID}")
        assert response.status_code == 200
        data = response.json()
        assert data["menstrual_tracking_enabled"] is False

    def test_get_cycle_phase_menstrual(self, client, mock_supabase):
        """Test cycle phase calculation - menstrual phase."""
        # Day 3 should be menstrual phase
        last_period = (date.today() - timedelta(days=2)).isoformat()

        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
            {
                "menstrual_tracking_enabled": True,
                "last_period_start_date": last_period,
                "cycle_length_days": 28,
            }
        ]

        response = client.get(f"/api/v1/hormonal-health/cycle-phase/{TEST_USER_ID}")
        assert response.status_code == 200
        data = response.json()
        assert data["current_phase"] == "menstrual"
        assert data["current_cycle_day"] == 3

    def test_get_cycle_phase_follicular(self, client, mock_supabase):
        """Test cycle phase calculation - follicular phase."""
        # Day 10 should be follicular phase
        last_period = (date.today() - timedelta(days=9)).isoformat()

        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
            {
                "menstrual_tracking_enabled": True,
                "last_period_start_date": last_period,
                "cycle_length_days": 28,
            }
        ]

        response = client.get(f"/api/v1/hormonal-health/cycle-phase/{TEST_USER_ID}")
        assert response.status_code == 200
        data = response.json()
        assert data["current_phase"] == "follicular"

    def test_get_cycle_phase_ovulation(self, client, mock_supabase):
        """Test cycle phase calculation - ovulation phase."""
        # Day 15 should be ovulation phase
        last_period = (date.today() - timedelta(days=14)).isoformat()

        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
            {
                "menstrual_tracking_enabled": True,
                "last_period_start_date": last_period,
                "cycle_length_days": 28,
            }
        ]

        response = client.get(f"/api/v1/hormonal-health/cycle-phase/{TEST_USER_ID}")
        assert response.status_code == 200
        data = response.json()
        assert data["current_phase"] == "ovulation"

    def test_get_cycle_phase_luteal(self, client, mock_supabase):
        """Test cycle phase calculation - luteal phase."""
        # Day 20 should be luteal phase
        last_period = (date.today() - timedelta(days=19)).isoformat()

        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
            {
                "menstrual_tracking_enabled": True,
                "last_period_start_date": last_period,
                "cycle_length_days": 28,
            }
        ]

        response = client.get(f"/api/v1/hormonal-health/cycle-phase/{TEST_USER_ID}")
        assert response.status_code == 200
        data = response.json()
        assert data["current_phase"] == "luteal"

    def test_log_period_start(self, client, mock_supabase):
        """Test logging period start."""
        mock_supabase.table.return_value.update.return_value.eq.return_value.execute.return_value.data = [
            {"id": str(uuid4())}
        ]
        mock_supabase.table.return_value.upsert.return_value.execute.return_value.data = [{}]

        response = client.post(f"/api/v1/hormonal-health/cycle-phase/{TEST_USER_ID}/log-period")
        assert response.status_code == 200


class TestHormoneSupportiveFoodsEndpoints:
    """Tests for hormone-supportive foods endpoints."""

    def test_get_foods_all(self, client, mock_supabase):
        """Test getting all hormone-supportive foods."""
        mock_data = [
            {
                "id": str(uuid4()),
                "name": "Oysters",
                "category": "seafood",
                "supports_testosterone": True,
                "key_nutrients": ["zinc", "vitamin_d"],
            },
            {
                "id": str(uuid4()),
                "name": "Flaxseeds",
                "category": "seed",
                "supports_estrogen_balance": True,
                "key_nutrients": ["lignans", "omega3"],
            },
        ]
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = mock_data

        response = client.get("/api/v1/hormonal-health/foods")
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2

    def test_get_foods_filtered_by_goal(self, client, mock_supabase):
        """Test getting foods filtered by hormone goal."""
        mock_data = [
            {
                "id": str(uuid4()),
                "name": "Oysters",
                "category": "seafood",
                "supports_testosterone": True,
                "key_nutrients": ["zinc"],
            },
        ]
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = mock_data

        response = client.get(
            "/api/v1/hormonal-health/foods",
            params={"goal": "optimize_testosterone"},
        )
        assert response.status_code == 200


class TestHormonalInsightsEndpoint:
    """Tests for comprehensive insights endpoint."""

    def test_get_insights(self, client, mock_supabase):
        """Test getting comprehensive hormonal insights."""
        # Mock profile
        mock_profile = {
            "user_id": TEST_USER_ID,
            "hormone_goals": ["optimize_testosterone"],
            "menstrual_tracking_enabled": False,
        }
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [mock_profile]

        # Mock logs
        mock_supabase.table.return_value.select.return_value.eq.return_value.gte.return_value.order.return_value.execute.return_value.data = []

        # Mock foods
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = []

        response = client.get(f"/api/v1/hormonal-health/insights/{TEST_USER_ID}")
        assert response.status_code == 200


# Pytest fixtures
@pytest.fixture
def client():
    """Create test client."""
    from main import app
    return TestClient(app)


@pytest.fixture
def mock_supabase():
    """Mock Supabase client."""
    with patch("api.v1.hormonal_health.get_supabase_client") as mock:
        mock_client = MagicMock()
        mock.return_value = mock_client
        yield mock_client
