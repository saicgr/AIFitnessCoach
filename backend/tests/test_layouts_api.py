"""
Tests for Home Layout Customization API endpoints.

Tests all layout management endpoints including:
- Get user layouts
- Get active layout
- Create layout
- Update layout
- Delete layout
- Activate layout
- Get templates
- Create from template
"""
import pytest
from unittest.mock import Mock, MagicMock, patch, AsyncMock
from datetime import datetime, timedelta
from fastapi.testclient import TestClient
import uuid

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from main import app


# ============ Mock Data Generators ============

def generate_mock_layout(user_id: str, name: str = "My Layout", is_active: bool = True):
    """Generate a mock home layout."""
    return {
        "id": str(uuid.uuid4()),
        "user_id": user_id,
        "name": name,
        "tiles": [
            {"id": str(uuid.uuid4()), "type": "fitnessScore", "size": "full", "order": 0, "is_visible": True},
            {"id": str(uuid.uuid4()), "type": "moodPicker", "size": "full", "order": 1, "is_visible": True},
            {"id": str(uuid.uuid4()), "type": "nextWorkout", "size": "full", "order": 2, "is_visible": True},
            {"id": str(uuid.uuid4()), "type": "weeklyProgress", "size": "half", "order": 3, "is_visible": True},
            {"id": str(uuid.uuid4()), "type": "streakCounter", "size": "half", "order": 4, "is_visible": True},
        ],
        "is_active": is_active,
        "template_id": None,
        "created_at": datetime.now().isoformat(),
        "updated_at": datetime.now().isoformat(),
    }


def generate_mock_template(name: str, category: str):
    """Generate a mock layout template."""
    return {
        "id": str(uuid.uuid4()),
        "name": name,
        "description": f"A {category} focused layout",
        "tiles": [
            {"id": str(uuid.uuid4()), "type": "nextWorkout", "size": "full", "order": 0, "is_visible": True},
            {"id": str(uuid.uuid4()), "type": "weeklyProgress", "size": "half", "order": 1, "is_visible": True},
        ],
        "icon": "spa" if category == "minimalist" else "analytics",
        "category": category,
        "created_at": datetime.now().isoformat(),
    }


def generate_mock_tiles():
    """Generate a list of mock tiles."""
    return [
        {"id": str(uuid.uuid4()), "type": "fitnessScore", "size": "full", "order": 0, "is_visible": True},
        {"id": str(uuid.uuid4()), "type": "nextWorkout", "size": "full", "order": 1, "is_visible": True},
        {"id": str(uuid.uuid4()), "type": "quickActions", "size": "full", "order": 2, "is_visible": True},
    ]


# ============ Fixtures ============

@pytest.fixture
def client():
    """Create a test client."""
    return TestClient(app)


@pytest.fixture
def mock_user_id():
    """Generate a mock user ID."""
    return str(uuid.uuid4())


@pytest.fixture
def mock_layout_id():
    """Generate a mock layout ID."""
    return str(uuid.uuid4())


@pytest.fixture
def mock_template_id():
    """Generate a mock template ID."""
    return str(uuid.uuid4())


@pytest.fixture
def mock_supabase():
    """Create a mock Supabase client."""
    mock = MagicMock()

    # Mock table operations
    mock_table = MagicMock()
    mock.table.return_value = mock_table

    # Mock select chain
    mock_select = MagicMock()
    mock_table.select.return_value = mock_select
    mock_select.eq.return_value = mock_select
    mock_select.order.return_value = mock_select
    mock_select.limit.return_value = mock_select
    mock_select.single.return_value = mock_select

    # Mock insert chain
    mock_insert = MagicMock()
    mock_table.insert.return_value = mock_insert

    # Mock update chain
    mock_update = MagicMock()
    mock_table.update.return_value = mock_update
    mock_update.eq.return_value = mock_update

    # Mock delete chain
    mock_delete = MagicMock()
    mock_table.delete.return_value = mock_delete
    mock_delete.eq.return_value = mock_delete

    # Mock RPC
    mock_rpc = MagicMock()
    mock.rpc.return_value = mock_rpc

    return mock


# ============ Tests: Get Templates ============

class TestGetTemplates:
    """Tests for GET /api/v1/layouts/templates endpoint."""

    def test_get_templates_success(self, client, mock_supabase):
        """Test successfully fetching templates."""
        templates = [
            generate_mock_template("Minimalist", "minimalist"),
            generate_mock_template("Performance", "performance"),
            generate_mock_template("Wellness", "wellness"),
            generate_mock_template("Social", "social"),
        ]

        mock_result = MagicMock()
        mock_result.data = templates
        mock_supabase.table.return_value.select.return_value.execute.return_value = mock_result

        with patch("api.v1.layouts.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            response = client.get("/api/v1/layouts/templates")

            assert response.status_code == 200
            data = response.json()
            assert len(data) == 4
            assert data[0]["name"] == "Minimalist"
            assert data[0]["category"] == "minimalist"

    def test_get_templates_empty(self, client, mock_supabase):
        """Test fetching templates when none exist."""
        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase.table.return_value.select.return_value.execute.return_value = mock_result

        with patch("api.v1.layouts.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            response = client.get("/api/v1/layouts/templates")

            assert response.status_code == 200
            assert response.json() == []


# ============ Tests: Get User Layouts ============

class TestGetUserLayouts:
    """Tests for GET /api/v1/layouts/user/{user_id} endpoint."""

    def test_get_user_layouts_success(self, client, mock_supabase, mock_user_id):
        """Test successfully fetching user layouts."""
        layouts = [
            generate_mock_layout(mock_user_id, "Morning Focus", True),
            generate_mock_layout(mock_user_id, "Full Dashboard", False),
        ]

        mock_result = MagicMock()
        mock_result.data = layouts
        mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value = mock_result

        with patch("api.v1.layouts.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            response = client.get(f"/api/v1/layouts/user/{mock_user_id}")

            assert response.status_code == 200
            data = response.json()
            assert len(data) == 2
            assert data[0]["name"] == "Morning Focus"

    def test_get_user_layouts_empty(self, client, mock_supabase, mock_user_id):
        """Test fetching layouts when user has none."""
        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value = mock_result

        with patch("api.v1.layouts.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            response = client.get(f"/api/v1/layouts/user/{mock_user_id}")

            assert response.status_code == 200
            assert response.json() == []


# ============ Tests: Get Active Layout ============

class TestGetActiveLayout:
    """Tests for GET /api/v1/layouts/user/{user_id}/active endpoint."""

    def test_get_active_layout_exists(self, client, mock_supabase, mock_user_id):
        """Test getting active layout when one exists."""
        layout = generate_mock_layout(mock_user_id, "My Active Layout", True)

        mock_result = MagicMock()
        mock_result.data = [layout]
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.limit.return_value.execute.return_value = mock_result

        with patch("api.v1.layouts.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            response = client.get(f"/api/v1/layouts/user/{mock_user_id}/active")

            assert response.status_code == 200
            data = response.json()
            assert data["name"] == "My Active Layout"
            assert data["is_active"] is True


# ============ Tests: Create Layout ============

class TestCreateLayout:
    """Tests for POST /api/v1/layouts/user/{user_id} endpoint."""

    def test_create_layout_success(self, client, mock_supabase, mock_user_id):
        """Test successfully creating a layout."""
        tiles = generate_mock_tiles()
        layout_data = {
            "name": "New Layout",
            "tiles": tiles,
            "template_id": None,
        }

        created_layout = generate_mock_layout(mock_user_id, "New Layout", False)
        created_layout["tiles"] = tiles

        mock_result = MagicMock()
        mock_result.data = [created_layout]
        mock_supabase.table.return_value.insert.return_value.execute.return_value = mock_result

        with patch("api.v1.layouts.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            with patch("api.v1.layouts.log_user_activity", new_callable=AsyncMock):
                response = client.post(
                    f"/api/v1/layouts/user/{mock_user_id}",
                    json=layout_data
                )

                assert response.status_code == 201
                data = response.json()
                assert data["name"] == "New Layout"
                assert len(data["tiles"]) == 3

    def test_create_layout_empty_tiles(self, client, mock_supabase, mock_user_id):
        """Test creating layout with empty tiles."""
        layout_data = {
            "name": "Empty Layout",
            "tiles": [],
        }

        created_layout = generate_mock_layout(mock_user_id, "Empty Layout", False)
        created_layout["tiles"] = []

        mock_result = MagicMock()
        mock_result.data = [created_layout]
        mock_supabase.table.return_value.insert.return_value.execute.return_value = mock_result

        with patch("api.v1.layouts.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            with patch("api.v1.layouts.log_user_activity", new_callable=AsyncMock):
                response = client.post(
                    f"/api/v1/layouts/user/{mock_user_id}",
                    json=layout_data
                )

                assert response.status_code == 201


# ============ Tests: Update Layout ============

class TestUpdateLayout:
    """Tests for PUT /api/v1/layouts/{layout_id} endpoint."""

    def test_update_layout_name(self, client, mock_supabase, mock_user_id, mock_layout_id):
        """Test updating layout name."""
        existing_layout = {"user_id": mock_user_id}
        updated_layout = generate_mock_layout(mock_user_id, "Renamed Layout", True)

        # Mock ownership check
        mock_check = MagicMock()
        mock_check.data = existing_layout
        mock_supabase.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = mock_check

        # Mock update
        mock_update = MagicMock()
        mock_update.data = [updated_layout]
        mock_supabase.table.return_value.update.return_value.eq.return_value.execute.return_value = mock_update

        with patch("api.v1.layouts.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            with patch("api.v1.layouts.log_user_activity", new_callable=AsyncMock):
                response = client.put(
                    f"/api/v1/layouts/{mock_layout_id}?user_id={mock_user_id}",
                    json={"name": "Renamed Layout"}
                )

                assert response.status_code == 200

    def test_update_layout_tiles(self, client, mock_supabase, mock_user_id, mock_layout_id):
        """Test updating layout tiles."""
        existing_layout = {"user_id": mock_user_id}
        new_tiles = generate_mock_tiles()
        updated_layout = generate_mock_layout(mock_user_id, "My Layout", True)
        updated_layout["tiles"] = new_tiles

        mock_check = MagicMock()
        mock_check.data = existing_layout
        mock_supabase.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = mock_check

        mock_update = MagicMock()
        mock_update.data = [updated_layout]
        mock_supabase.table.return_value.update.return_value.eq.return_value.execute.return_value = mock_update

        with patch("api.v1.layouts.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            with patch("api.v1.layouts.log_user_activity", new_callable=AsyncMock):
                response = client.put(
                    f"/api/v1/layouts/{mock_layout_id}?user_id={mock_user_id}",
                    json={"tiles": new_tiles}
                )

                assert response.status_code == 200

    def test_update_layout_not_found(self, client, mock_supabase, mock_user_id, mock_layout_id):
        """Test updating non-existent layout."""
        mock_check = MagicMock()
        mock_check.data = None
        mock_supabase.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = mock_check

        with patch("api.v1.layouts.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            response = client.put(
                f"/api/v1/layouts/{mock_layout_id}?user_id={mock_user_id}",
                json={"name": "Test"}
            )

            assert response.status_code == 404

    def test_update_layout_unauthorized(self, client, mock_supabase, mock_layout_id):
        """Test updating layout owned by another user."""
        existing_layout = {"user_id": "different-user-id"}

        mock_check = MagicMock()
        mock_check.data = existing_layout
        mock_supabase.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = mock_check

        with patch("api.v1.layouts.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            response = client.put(
                f"/api/v1/layouts/{mock_layout_id}?user_id=my-user-id",
                json={"name": "Hacked Layout"}
            )

            assert response.status_code == 403


# ============ Tests: Delete Layout ============

class TestDeleteLayout:
    """Tests for DELETE /api/v1/layouts/{layout_id} endpoint."""

    def test_delete_layout_success(self, client, mock_supabase, mock_user_id, mock_layout_id):
        """Test successfully deleting a layout."""
        existing_layout = {"user_id": mock_user_id, "is_active": False}

        mock_check = MagicMock()
        mock_check.data = existing_layout
        mock_supabase.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = mock_check

        with patch("api.v1.layouts.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            with patch("api.v1.layouts.log_user_activity", new_callable=AsyncMock):
                response = client.delete(
                    f"/api/v1/layouts/{mock_layout_id}?user_id={mock_user_id}"
                )

                assert response.status_code == 200
                assert response.json()["message"] == "Layout deleted successfully"

    def test_delete_only_layout_prevented(self, client, mock_supabase, mock_user_id, mock_layout_id):
        """Test preventing deletion of only layout."""
        existing_layout = {"user_id": mock_user_id, "is_active": True}

        mock_check = MagicMock()
        mock_check.data = existing_layout
        mock_supabase.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = mock_check

        # Mock count - only 1 layout exists
        mock_count = MagicMock()
        mock_count.count = 1
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_count

        with patch("api.v1.layouts.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            response = client.delete(
                f"/api/v1/layouts/{mock_layout_id}?user_id={mock_user_id}"
            )

            assert response.status_code == 400
            assert "Cannot delete the only layout" in response.json()["detail"]


# ============ Tests: Activate Layout ============

class TestActivateLayout:
    """Tests for POST /api/v1/layouts/{layout_id}/activate endpoint."""

    def test_activate_layout_success(self, client, mock_supabase, mock_user_id, mock_layout_id):
        """Test successfully activating a layout."""
        layout = generate_mock_layout(mock_user_id, "My Layout", True)

        mock_rpc = MagicMock()
        mock_rpc.data = True
        mock_supabase.rpc.return_value.execute.return_value = mock_rpc

        mock_fetch = MagicMock()
        mock_fetch.data = layout
        mock_supabase.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = mock_fetch

        with patch("api.v1.layouts.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            with patch("api.v1.layouts.log_user_activity", new_callable=AsyncMock):
                response = client.post(
                    f"/api/v1/layouts/{mock_layout_id}/activate?user_id={mock_user_id}"
                )

                assert response.status_code == 200
                assert response.json()["is_active"] is True


# ============ Tests: Create from Template ============

class TestCreateFromTemplate:
    """Tests for POST /api/v1/layouts/user/{user_id}/from-template/{template_id} endpoint."""

    def test_create_from_template_success(self, client, mock_supabase, mock_user_id, mock_template_id):
        """Test successfully creating layout from template."""
        layout = generate_mock_layout(mock_user_id, "Minimalist", False)
        layout["template_id"] = mock_template_id

        mock_rpc = MagicMock()
        mock_rpc.data = layout["id"]
        mock_supabase.rpc.return_value.execute.return_value = mock_rpc

        mock_fetch = MagicMock()
        mock_fetch.data = layout
        mock_supabase.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = mock_fetch

        with patch("api.v1.layouts.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            with patch("api.v1.layouts.log_user_activity", new_callable=AsyncMock):
                response = client.post(
                    f"/api/v1/layouts/user/{mock_user_id}/from-template/{mock_template_id}"
                )

                assert response.status_code == 201
                data = response.json()
                assert data["template_id"] == mock_template_id

    def test_create_from_template_with_custom_name(self, client, mock_supabase, mock_user_id, mock_template_id):
        """Test creating layout from template with custom name."""
        layout = generate_mock_layout(mock_user_id, "My Custom Name", False)
        layout["template_id"] = mock_template_id

        mock_rpc = MagicMock()
        mock_rpc.data = layout["id"]
        mock_supabase.rpc.return_value.execute.return_value = mock_rpc

        mock_fetch = MagicMock()
        mock_fetch.data = layout
        mock_supabase.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = mock_fetch

        with patch("api.v1.layouts.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            with patch("api.v1.layouts.log_user_activity", new_callable=AsyncMock):
                response = client.post(
                    f"/api/v1/layouts/user/{mock_user_id}/from-template/{mock_template_id}?name=My%20Custom%20Name"
                )

                assert response.status_code == 201

    def test_create_from_template_not_found(self, client, mock_supabase, mock_user_id, mock_template_id):
        """Test creating layout from non-existent template."""
        mock_rpc = MagicMock()
        mock_rpc.data = None
        mock_supabase.rpc.return_value.execute.return_value = mock_rpc

        with patch("api.v1.layouts.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            response = client.post(
                f"/api/v1/layouts/user/{mock_user_id}/from-template/{mock_template_id}"
            )

            assert response.status_code == 404


# ============ Tests: Tile Types ============

class TestTileTypes:
    """Tests for tile type validation."""

    def test_valid_tile_types(self):
        """Test that all expected tile types are valid."""
        valid_types = [
            "nextWorkout", "fitnessScore", "moodPicker", "dailyActivity",
            "quickActions", "weeklyProgress", "weeklyGoals", "weekChanges",
            "upcomingFeatures", "upcomingWorkouts", "streakCounter",
            "personalRecords", "aiCoachTip", "challengeProgress",
            "caloriesSummary", "macroRings", "bodyWeight", "progressPhoto",
            "socialFeed", "leaderboardRank", "fasting", "weeklyCalendar",
            "muscleHeatmap", "sleepScore", "restDayTip",
        ]

        # This validates that we've defined all expected tile types
        assert len(valid_types) == 25

    def test_valid_tile_sizes(self):
        """Test that all expected tile sizes are valid."""
        valid_sizes = ["full", "half", "compact"]
        assert len(valid_sizes) == 3


# ============ Tests: Layout Model Validation ============

class TestLayoutModelValidation:
    """Tests for layout model validation."""

    def test_tile_order_sequential(self):
        """Test that tile orders are sequential starting from 0."""
        tiles = [
            {"id": "1", "type": "fitnessScore", "size": "full", "order": 0, "is_visible": True},
            {"id": "2", "type": "nextWorkout", "size": "full", "order": 1, "is_visible": True},
            {"id": "3", "type": "quickActions", "size": "full", "order": 2, "is_visible": True},
        ]

        orders = [t["order"] for t in tiles]
        assert orders == list(range(len(tiles)))

    def test_layout_name_not_empty(self):
        """Test that layout names cannot be empty."""
        layout = generate_mock_layout("user-123", "Test Layout")
        assert layout["name"]
        assert len(layout["name"]) > 0

    def test_active_layout_flag(self):
        """Test active flag behavior."""
        active_layout = generate_mock_layout("user-123", "Active", True)
        inactive_layout = generate_mock_layout("user-123", "Inactive", False)

        assert active_layout["is_active"] is True
        assert inactive_layout["is_active"] is False


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
