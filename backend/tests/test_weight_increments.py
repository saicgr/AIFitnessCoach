"""
Tests for weight increments API endpoints.

Tests GET, PUT, DELETE operations for user weight increment preferences.
"""

import pytest
from fastapi.testclient import TestClient
from unittest.mock import MagicMock, patch, AsyncMock


# Create mock outside fixtures to ensure consistent patching
@pytest.fixture(scope="module")
def mock_db():
    """Mock Supabase database."""
    mock = MagicMock()
    return mock


@pytest.fixture(scope="module")
def client(mock_db):
    """Test client with mocked DB and activity logger."""
    with patch("api.v1.weight_increments.get_supabase_db", return_value=mock_db):
        with patch("api.v1.weight_increments.log_user_activity", new_callable=AsyncMock):
            from main import app
            yield TestClient(app)


class TestWeightIncrementsAPI:
    """Tests for weight increments endpoints."""

    def test_get_returns_defaults_when_no_record(self, client, mock_db):
        """GET returns defaults when user has no saved preferences."""
        mock_db.client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = []

        response = client.get("/api/v1/weight-increments/test-user-123")

        assert response.status_code == 200
        data = response.json()
        assert data["user_id"] == "test-user-123"
        assert data["dumbbell"] == 2.5
        assert data["barbell"] == 2.5
        assert data["machine"] == 5.0
        assert data["kettlebell"] == 4.0
        assert data["cable"] == 2.5
        assert data["unit"] == "kg"

    def test_get_returns_saved_preferences(self, client, mock_db):
        """GET returns user's saved preferences."""
        mock_db.client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [{
            "user_id": "test-user-123",
            "dumbbell": 1.25,
            "barbell": 2.5,
            "machine": 5.0,
            "kettlebell": 4.0,
            "cable": 2.5,
            "unit": "lbs"
        }]

        response = client.get("/api/v1/weight-increments/test-user-123")

        assert response.status_code == 200
        data = response.json()
        assert data["dumbbell"] == 1.25
        assert data["unit"] == "lbs"

    def test_put_updates_single_field(self, client, mock_db):
        """PUT updates only provided fields (partial update)."""
        mock_db.client.table.return_value.upsert.return_value.execute.return_value.data = [{
            "user_id": "test-user-123",
            "dumbbell": 1.0,
            "barbell": 2.5,
            "machine": 5.0,
            "kettlebell": 4.0,
            "cable": 2.5,
            "unit": "kg"
        }]

        response = client.put(
            "/api/v1/weight-increments/test-user-123",
            json={"dumbbell": 1.0}
        )

        assert response.status_code == 200
        assert response.json()["dumbbell"] == 1.0

    def test_put_updates_unit(self, client, mock_db):
        """PUT can change unit from kg to lbs."""
        mock_db.client.table.return_value.upsert.return_value.execute.return_value.data = [{
            "user_id": "test-user-123",
            "dumbbell": 2.5,
            "barbell": 2.5,
            "machine": 5.0,
            "kettlebell": 4.0,
            "cable": 2.5,
            "unit": "lbs"
        }]

        response = client.put(
            "/api/v1/weight-increments/test-user-123",
            json={"unit": "lbs"}
        )

        assert response.status_code == 200
        assert response.json()["unit"] == "lbs"

    def test_put_updates_multiple_fields(self, client, mock_db):
        """PUT can update multiple fields at once."""
        mock_db.client.table.return_value.upsert.return_value.execute.return_value.data = [{
            "user_id": "test-user-123",
            "dumbbell": 1.25,
            "barbell": 5.0,
            "machine": 10.0,
            "kettlebell": 4.0,
            "cable": 2.5,
            "unit": "lbs"
        }]

        response = client.put(
            "/api/v1/weight-increments/test-user-123",
            json={
                "dumbbell": 1.25,
                "barbell": 5.0,
                "machine": 10.0,
                "unit": "lbs"
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["dumbbell"] == 1.25
        assert data["barbell"] == 5.0
        assert data["machine"] == 10.0
        assert data["unit"] == "lbs"

    def test_put_validates_increment_too_high(self, client, mock_db):
        """PUT rejects increments above maximum (50)."""
        response = client.put(
            "/api/v1/weight-increments/test-user-123",
            json={"dumbbell": 100}
        )

        assert response.status_code == 422  # Validation error

    def test_put_validates_increment_too_low(self, client, mock_db):
        """PUT rejects increments below minimum (0.5)."""
        response = client.put(
            "/api/v1/weight-increments/test-user-123",
            json={"dumbbell": 0.1}
        )

        assert response.status_code == 422  # Validation error

    def test_put_validates_invalid_unit(self, client, mock_db):
        """PUT rejects invalid unit values."""
        response = client.put(
            "/api/v1/weight-increments/test-user-123",
            json={"unit": "stones"}  # Invalid unit
        )

        assert response.status_code == 422  # Validation error

    def test_delete_resets_to_defaults(self, client, mock_db):
        """DELETE removes user record, returning defaults info."""
        mock_db.client.table.return_value.delete.return_value.eq.return_value.execute.return_value = MagicMock()

        response = client.delete("/api/v1/weight-increments/test-user-123")

        assert response.status_code == 200
        data = response.json()
        assert data["message"] == "Reset to defaults"
        assert "defaults" in data
        assert data["defaults"]["dumbbell"] == 2.5
        assert data["defaults"]["unit"] == "kg"

    def test_delete_calls_database(self, client, mock_db):
        """DELETE actually calls the database delete method."""
        response = client.delete("/api/v1/weight-increments/test-user-123")

        assert response.status_code == 200
        # Verify the delete was called
        mock_db.client.table.assert_called_with("weight_increments")


class TestWeightIncrementsValidation:
    """Tests for request validation."""

    def test_accepts_valid_kg_increments(self, client, mock_db):
        """PUT accepts valid increment values for kg."""
        mock_db.client.table.return_value.upsert.return_value.execute.return_value.data = [{
            "user_id": "test-user",
            "dumbbell": 2.5,
            "barbell": 2.5,
            "machine": 5.0,
            "kettlebell": 4.0,
            "cable": 2.5,
            "unit": "kg"
        }]

        valid_increments = [0.5, 1.0, 1.25, 2.0, 2.5, 4.0, 5.0, 10.0, 20.0, 25.0, 50.0]
        for increment in valid_increments:
            response = client.put(
                "/api/v1/weight-increments/test-user",
                json={"dumbbell": increment}
            )
            assert response.status_code == 200, f"Failed for increment {increment}"

    def test_accepts_valid_lbs_increments(self, client, mock_db):
        """PUT accepts valid increment values for lbs."""
        mock_db.client.table.return_value.upsert.return_value.execute.return_value.data = [{
            "user_id": "test-user",
            "dumbbell": 5.0,
            "barbell": 2.5,
            "machine": 5.0,
            "kettlebell": 4.0,
            "cable": 2.5,
            "unit": "lbs"
        }]

        response = client.put(
            "/api/v1/weight-increments/test-user",
            json={"dumbbell": 5.0, "unit": "lbs"}
        )
        assert response.status_code == 200

    def test_empty_body_is_valid(self, client, mock_db):
        """PUT with empty body is valid (no-op)."""
        mock_db.client.table.return_value.upsert.return_value.execute.return_value.data = [{
            "user_id": "test-user",
            "dumbbell": 2.5,
            "barbell": 2.5,
            "machine": 5.0,
            "kettlebell": 4.0,
            "cable": 2.5,
            "unit": "kg"
        }]

        response = client.put(
            "/api/v1/weight-increments/test-user",
            json={}
        )
        assert response.status_code == 200
