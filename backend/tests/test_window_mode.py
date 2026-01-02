"""
Tests for Window Mode API endpoints.

This module tests:
1. POST /api/v1/window-mode/{user_id}/log - Log window mode changes
2. GET /api/v1/window-mode/{user_id}/stats - Get window mode statistics
3. Input validation for mode values
4. Timestamp validation
"""
import pytest
from datetime import datetime, timedelta
from unittest.mock import MagicMock, patch
from fastapi.testclient import TestClient


# Mock UUID for testing
MOCK_USER_ID = "test-user-window-mode-123"
MOCK_LOG_ID = "log-window-mode-456"


# =============================================================================
# Fixtures
# =============================================================================

@pytest.fixture
def mock_supabase():
    """Create a mock Supabase client."""
    with patch("api.v1.window_mode.get_supabase") as mock:
        mock_db = MagicMock()
        mock.return_value = mock_db
        yield mock_db


@pytest.fixture
def mock_activity_logger():
    """Mock the activity logger to prevent actual logging."""
    with patch("api.v1.window_mode.log_user_activity") as mock_activity, \
         patch("api.v1.window_mode.log_user_error") as mock_error:
        yield mock_activity, mock_error


@pytest.fixture
def client():
    """Create a test client."""
    from main import app
    return TestClient(app)


def generate_mock_window_log(
    mode: str = "split_screen",
    width: int = 400,
    height: int = 800,
    duration_seconds: int = None,
):
    """Generate a mock window mode log response."""
    log = {
        "id": MOCK_LOG_ID,
        "user_id": MOCK_USER_ID,
        "mode": mode,
        "window_width": width,
        "window_height": height,
        "duration_seconds": duration_seconds,
        "device_info": None,
        "logged_at": datetime.utcnow().isoformat(),
    }
    return log


# =============================================================================
# Log Window Mode Tests
# =============================================================================

class TestLogWindowMode:
    """Tests for POST /api/v1/window-mode/{user_id}/log"""

    def test_log_split_screen_mode_success(self, client, mock_supabase, mock_activity_logger):
        """Test successfully logging a split screen mode change."""
        # Setup mock
        mock_result = MagicMock()
        mock_result.data = [generate_mock_window_log()]
        mock_supabase.client.table.return_value.insert.return_value.execute.return_value = mock_result

        # Make request
        response = client.post(
            f"/api/v1/window-mode/{MOCK_USER_ID}/log",
            json={
                "mode": "split_screen",
                "width": 400,
                "height": 800,
                "timestamp": datetime.utcnow().isoformat(),
            }
        )

        # Verify
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["mode"] == "split_screen"
        assert data["window_width"] == 400
        assert data["window_height"] == 800
        assert data["user_id"] == MOCK_USER_ID

    def test_log_full_screen_mode_success(self, client, mock_supabase, mock_activity_logger):
        """Test successfully logging a full screen mode change."""
        mock_result = MagicMock()
        mock_result.data = [generate_mock_window_log(mode="full_screen", width=1080, height=1920)]
        mock_supabase.client.table.return_value.insert.return_value.execute.return_value = mock_result

        response = client.post(
            f"/api/v1/window-mode/{MOCK_USER_ID}/log",
            json={
                "mode": "full_screen",
                "width": 1080,
                "height": 1920,
                "timestamp": datetime.utcnow().isoformat(),
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["mode"] == "full_screen"

    def test_log_pip_mode_success(self, client, mock_supabase, mock_activity_logger):
        """Test successfully logging a PiP (Picture-in-Picture) mode change."""
        mock_result = MagicMock()
        mock_result.data = [generate_mock_window_log(mode="pip", width=200, height=300)]
        mock_supabase.client.table.return_value.insert.return_value.execute.return_value = mock_result

        response = client.post(
            f"/api/v1/window-mode/{MOCK_USER_ID}/log",
            json={
                "mode": "pip",
                "width": 200,
                "height": 300,
                "timestamp": datetime.utcnow().isoformat(),
            }
        )

        assert response.status_code == 200
        assert response.json()["mode"] == "pip"

    def test_log_freeform_mode_success(self, client, mock_supabase, mock_activity_logger):
        """Test successfully logging a freeform window mode change."""
        mock_result = MagicMock()
        mock_result.data = [generate_mock_window_log(mode="freeform", width=600, height=400)]
        mock_supabase.client.table.return_value.insert.return_value.execute.return_value = mock_result

        response = client.post(
            f"/api/v1/window-mode/{MOCK_USER_ID}/log",
            json={
                "mode": "freeform",
                "width": 600,
                "height": 400,
                "timestamp": datetime.utcnow().isoformat(),
            }
        )

        assert response.status_code == 200
        assert response.json()["mode"] == "freeform"

    def test_log_split_screen_session_with_duration(self, client, mock_supabase, mock_activity_logger):
        """Test logging a split screen session with duration tracking."""
        mock_result = MagicMock()
        mock_result.data = [generate_mock_window_log(
            mode="split_screen_session",
            width=400,
            height=800,
            duration_seconds=300
        )]
        mock_supabase.client.table.return_value.insert.return_value.execute.return_value = mock_result

        response = client.post(
            f"/api/v1/window-mode/{MOCK_USER_ID}/log",
            json={
                "mode": "split_screen_session",
                "width": 400,
                "height": 800,
                "timestamp": datetime.utcnow().isoformat(),
                "duration_seconds": 300,
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["mode"] == "split_screen_session"

    def test_log_with_device_info(self, client, mock_supabase, mock_activity_logger):
        """Test logging with optional device info."""
        device_info = {
            "model": "Pixel 8",
            "os_version": "Android 14",
            "manufacturer": "Google",
        }
        mock_result = MagicMock()
        mock_result.data = [generate_mock_window_log()]
        mock_supabase.client.table.return_value.insert.return_value.execute.return_value = mock_result

        response = client.post(
            f"/api/v1/window-mode/{MOCK_USER_ID}/log",
            json={
                "mode": "split_screen",
                "width": 400,
                "height": 800,
                "timestamp": datetime.utcnow().isoformat(),
                "device_info": device_info,
            }
        )

        assert response.status_code == 200


class TestLogWindowModeValidation:
    """Tests for input validation on window mode logging."""

    def test_invalid_mode_rejected(self, client, mock_supabase):
        """Test that invalid mode values are rejected."""
        response = client.post(
            f"/api/v1/window-mode/{MOCK_USER_ID}/log",
            json={
                "mode": "invalid_mode",
                "width": 400,
                "height": 800,
                "timestamp": datetime.utcnow().isoformat(),
            }
        )

        assert response.status_code == 422  # Validation error
        assert "Invalid mode" in response.text or "mode" in response.text.lower()

    def test_negative_width_rejected(self, client, mock_supabase):
        """Test that negative width is rejected."""
        response = client.post(
            f"/api/v1/window-mode/{MOCK_USER_ID}/log",
            json={
                "mode": "split_screen",
                "width": -100,
                "height": 800,
                "timestamp": datetime.utcnow().isoformat(),
            }
        )

        assert response.status_code == 422

    def test_negative_height_rejected(self, client, mock_supabase):
        """Test that negative height is rejected."""
        response = client.post(
            f"/api/v1/window-mode/{MOCK_USER_ID}/log",
            json={
                "mode": "split_screen",
                "width": 400,
                "height": -100,
                "timestamp": datetime.utcnow().isoformat(),
            }
        )

        assert response.status_code == 422

    def test_excessive_dimensions_rejected(self, client, mock_supabase):
        """Test that excessively large dimensions are rejected."""
        response = client.post(
            f"/api/v1/window-mode/{MOCK_USER_ID}/log",
            json={
                "mode": "split_screen",
                "width": 999999,
                "height": 800,
                "timestamp": datetime.utcnow().isoformat(),
            }
        )

        assert response.status_code == 422

    def test_invalid_timestamp_rejected(self, client, mock_supabase):
        """Test that invalid timestamp format is rejected."""
        response = client.post(
            f"/api/v1/window-mode/{MOCK_USER_ID}/log",
            json={
                "mode": "split_screen",
                "width": 400,
                "height": 800,
                "timestamp": "not-a-timestamp",
            }
        )

        assert response.status_code == 422

    def test_negative_duration_rejected(self, client, mock_supabase):
        """Test that negative duration is rejected."""
        response = client.post(
            f"/api/v1/window-mode/{MOCK_USER_ID}/log",
            json={
                "mode": "split_screen_session",
                "width": 400,
                "height": 800,
                "timestamp": datetime.utcnow().isoformat(),
                "duration_seconds": -60,
            }
        )

        assert response.status_code == 422

    def test_missing_required_fields(self, client, mock_supabase):
        """Test that missing required fields are rejected."""
        response = client.post(
            f"/api/v1/window-mode/{MOCK_USER_ID}/log",
            json={
                "mode": "split_screen",
                # Missing width, height, timestamp
            }
        )

        assert response.status_code == 422


# =============================================================================
# Get Window Mode Stats Tests
# =============================================================================

class TestGetWindowModeStats:
    """Tests for GET /api/v1/window-mode/{user_id}/stats"""

    def test_get_stats_with_data(self, client, mock_supabase):
        """Test getting statistics when user has window mode logs."""
        # Setup mock with varied data
        mock_result = MagicMock()
        mock_result.data = [
            {"mode": "split_screen", "window_width": 400, "window_height": 800, "duration_seconds": None, "logged_at": datetime.utcnow().isoformat()},
            {"mode": "split_screen", "window_width": 450, "window_height": 850, "duration_seconds": None, "logged_at": datetime.utcnow().isoformat()},
            {"mode": "full_screen", "window_width": 1080, "window_height": 1920, "duration_seconds": None, "logged_at": datetime.utcnow().isoformat()},
            {"mode": "split_screen_session", "window_width": 400, "window_height": 800, "duration_seconds": 300, "logged_at": datetime.utcnow().isoformat()},
            {"mode": "split_screen_session", "window_width": 400, "window_height": 800, "duration_seconds": 600, "logged_at": datetime.utcnow().isoformat()},
        ]
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value = mock_result

        response = client.get(f"/api/v1/window-mode/{MOCK_USER_ID}/stats")

        assert response.status_code == 200
        data = response.json()
        assert data["user_id"] == MOCK_USER_ID
        assert data["total_logs"] == 5
        assert data["mode_counts"]["split_screen"] == 2
        assert data["mode_counts"]["full_screen"] == 1
        assert data["mode_counts"]["split_screen_session"] == 2
        assert data["split_screen_total_seconds"] == 900  # 300 + 600
        assert data["avg_split_screen_session_seconds"] == 450.0  # (300 + 600) / 2
        assert data["most_common_mode"] == "split_screen"

    def test_get_stats_no_data(self, client, mock_supabase):
        """Test getting statistics when user has no window mode logs."""
        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value = mock_result

        response = client.get(f"/api/v1/window-mode/{MOCK_USER_ID}/stats")

        assert response.status_code == 200
        data = response.json()
        assert data["user_id"] == MOCK_USER_ID
        assert data["total_logs"] == 0
        assert data["mode_counts"] == {}
        assert data["split_screen_total_seconds"] == 0
        assert data["avg_split_screen_session_seconds"] == 0.0
        assert data["most_common_mode"] is None
        assert data["last_mode_change"] is None

    def test_get_stats_only_full_screen(self, client, mock_supabase):
        """Test statistics when user only uses full screen mode."""
        mock_result = MagicMock()
        mock_result.data = [
            {"mode": "full_screen", "window_width": 1080, "window_height": 1920, "duration_seconds": None, "logged_at": datetime.utcnow().isoformat()},
            {"mode": "full_screen", "window_width": 1080, "window_height": 1920, "duration_seconds": None, "logged_at": datetime.utcnow().isoformat()},
        ]
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value = mock_result

        response = client.get(f"/api/v1/window-mode/{MOCK_USER_ID}/stats")

        assert response.status_code == 200
        data = response.json()
        assert data["most_common_mode"] == "full_screen"
        assert data["split_screen_total_seconds"] == 0


# =============================================================================
# Mode Validation Tests
# =============================================================================

class TestModeValidation:
    """Tests for the WindowMode enum and validation."""

    def test_all_valid_modes_accepted(self, client, mock_supabase, mock_activity_logger):
        """Test that all valid mode values are accepted."""
        valid_modes = ["split_screen", "full_screen", "pip", "freeform", "split_screen_session"]

        for mode in valid_modes:
            mock_result = MagicMock()
            mock_result.data = [generate_mock_window_log(mode=mode)]
            mock_supabase.client.table.return_value.insert.return_value.execute.return_value = mock_result

            response = client.post(
                f"/api/v1/window-mode/{MOCK_USER_ID}/log",
                json={
                    "mode": mode,
                    "width": 400,
                    "height": 800,
                    "timestamp": datetime.utcnow().isoformat(),
                }
            )

            assert response.status_code == 200, f"Mode '{mode}' should be accepted"

    def test_case_sensitive_mode(self, client, mock_supabase):
        """Test that mode is case-sensitive."""
        response = client.post(
            f"/api/v1/window-mode/{MOCK_USER_ID}/log",
            json={
                "mode": "SPLIT_SCREEN",  # uppercase
                "width": 400,
                "height": 800,
                "timestamp": datetime.utcnow().isoformat(),
            }
        )

        assert response.status_code == 422  # Should fail validation


# =============================================================================
# Edge Cases
# =============================================================================

class TestEdgeCases:
    """Test edge cases and boundary conditions."""

    def test_zero_dimensions(self, client, mock_supabase, mock_activity_logger):
        """Test that zero dimensions are accepted (edge case for minimized windows)."""
        mock_result = MagicMock()
        mock_result.data = [generate_mock_window_log(width=0, height=0)]
        mock_supabase.client.table.return_value.insert.return_value.execute.return_value = mock_result

        response = client.post(
            f"/api/v1/window-mode/{MOCK_USER_ID}/log",
            json={
                "mode": "pip",
                "width": 0,
                "height": 0,
                "timestamp": datetime.utcnow().isoformat(),
            }
        )

        assert response.status_code == 200

    def test_utc_z_timestamp_format(self, client, mock_supabase, mock_activity_logger):
        """Test that UTC 'Z' suffix timestamp format is accepted."""
        mock_result = MagicMock()
        mock_result.data = [generate_mock_window_log()]
        mock_supabase.client.table.return_value.insert.return_value.execute.return_value = mock_result

        response = client.post(
            f"/api/v1/window-mode/{MOCK_USER_ID}/log",
            json={
                "mode": "split_screen",
                "width": 400,
                "height": 800,
                "timestamp": "2025-01-15T10:30:00Z",
            }
        )

        assert response.status_code == 200

    def test_timezone_offset_timestamp(self, client, mock_supabase, mock_activity_logger):
        """Test that timezone offset timestamp format is accepted."""
        mock_result = MagicMock()
        mock_result.data = [generate_mock_window_log()]
        mock_supabase.client.table.return_value.insert.return_value.execute.return_value = mock_result

        response = client.post(
            f"/api/v1/window-mode/{MOCK_USER_ID}/log",
            json={
                "mode": "split_screen",
                "width": 400,
                "height": 800,
                "timestamp": "2025-01-15T10:30:00+05:30",
            }
        )

        assert response.status_code == 200

    def test_zero_duration_session(self, client, mock_supabase, mock_activity_logger):
        """Test that zero duration sessions are accepted (user exited immediately)."""
        mock_result = MagicMock()
        mock_result.data = [generate_mock_window_log(mode="split_screen_session", duration_seconds=0)]
        mock_supabase.client.table.return_value.insert.return_value.execute.return_value = mock_result

        response = client.post(
            f"/api/v1/window-mode/{MOCK_USER_ID}/log",
            json={
                "mode": "split_screen_session",
                "width": 400,
                "height": 800,
                "timestamp": datetime.utcnow().isoformat(),
                "duration_seconds": 0,
            }
        )

        assert response.status_code == 200

    def test_max_dimensions(self, client, mock_supabase, mock_activity_logger):
        """Test maximum allowed dimensions."""
        mock_result = MagicMock()
        mock_result.data = [generate_mock_window_log(width=10000, height=10000)]
        mock_supabase.client.table.return_value.insert.return_value.execute.return_value = mock_result

        response = client.post(
            f"/api/v1/window-mode/{MOCK_USER_ID}/log",
            json={
                "mode": "full_screen",
                "width": 10000,
                "height": 10000,
                "timestamp": datetime.utcnow().isoformat(),
            }
        )

        assert response.status_code == 200
