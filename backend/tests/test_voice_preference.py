"""
Tests for Voice Announcements Preference API.

Tests the voice_announcements_enabled setting within notification_preferences.
This preference controls TTS announcements during workouts.

CALLING CONVENTION (updated 2026-07):
- `PUT /api/v1/users/{user_id}` now takes `current_user: dict = Depends(get_current_user)`
  and rejects any caller whose id != user_id (IDOR guard). Tests must override the
  dependency, otherwise every request short-circuits at 401 and the body below is
  never executed.
- The endpoint moved from `api/v1/users.py` to the package module
  `api/v1/users/profile.py`, which does `from core.db import get_supabase_db` /
  `from core.activity_logger import log_user_activity`. Those names must be patched
  in `api.v1.users.profile` — patching the `api.v1.users` package re-export leaves
  the endpoint bound to the real client.
- `log_user_activity` is awaited, so it needs an AsyncMock.

The assertions themselves are unchanged: the merge semantics of
notification_preferences are what this file guards.
"""
import pytest
from contextlib import contextmanager
from unittest.mock import AsyncMock, MagicMock, patch

from fastapi.testclient import TestClient

from main import app


@contextmanager
def authenticated_as(user_id: str):
    """Yield a TestClient authenticated as `user_id` (satisfies the ownership check)."""
    from core.auth import get_current_user

    app.dependency_overrides[get_current_user] = lambda: {
        "id": user_id,
        "email": "test@example.com",
    }
    try:
        yield TestClient(app)
    finally:
        app.dependency_overrides.pop(get_current_user, None)


class TestVoiceAnnouncementsPreference:
    """Tests for voice announcements preference in notification_preferences."""

    @patch('api.v1.users.profile.get_supabase_db')
    @patch('api.v1.users.profile.log_user_activity', new_callable=AsyncMock)
    def test_enable_voice_announcements(self, mock_log, mock_db):
        """Test enabling voice announcements via notification_preferences update."""
        user_id = "test-user-voice-123"

        # Mock existing user without voice announcements setting
        existing_user = {
            "id": user_id,
            "email": "test@example.com",
            "name": "Test User",
            "onboarding_completed": True,
            "fitness_level": "intermediate",
            "goals": '["build_muscle"]',
            "equipment": '["dumbbells"]',
            "preferences": '{}',
            "active_injuries": '[]',
            "created_at": "2024-01-01T00:00:00Z",
            "notification_preferences": {},
        }

        # Mock updated user
        updated_user = {
            **existing_user,
            "notification_preferences": {"voice_announcements_enabled": True},
        }

        mock_db_instance = MagicMock()
        mock_db_instance.get_user.return_value = existing_user
        mock_db_instance.update_user.return_value = updated_user
        mock_db.return_value = mock_db_instance

        mock_log.return_value = None

        # Enable voice announcements
        with authenticated_as(user_id) as client:
            response = client.put(
                f"/api/v1/users/{user_id}",
                json={
                    "notification_preferences": {
                        "voice_announcements_enabled": True
                    }
                }
            )

        assert response.status_code == 200

        # Verify update_user was called with correct notification_preferences
        mock_db_instance.update_user.assert_called_once()
        call_args = mock_db_instance.update_user.call_args[0]
        update_data = call_args[1]

        assert "notification_preferences" in update_data
        assert update_data["notification_preferences"]["voice_announcements_enabled"] is True

    @patch('api.v1.users.profile.get_supabase_db')
    @patch('api.v1.users.profile.log_user_activity', new_callable=AsyncMock)
    def test_disable_voice_announcements(self, mock_log, mock_db):
        """Test disabling voice announcements via notification_preferences update."""
        user_id = "test-user-voice-456"

        # Mock existing user with voice announcements enabled
        existing_user = {
            "id": user_id,
            "email": "test@example.com",
            "name": "Test User",
            "onboarding_completed": True,
            "fitness_level": "intermediate",
            "goals": '["build_muscle"]',
            "equipment": '["dumbbells"]',
            "preferences": '{}',
            "active_injuries": '[]',
            "created_at": "2024-01-01T00:00:00Z",
            "notification_preferences": {"voice_announcements_enabled": True},
        }

        # Mock updated user
        updated_user = {
            **existing_user,
            "notification_preferences": {"voice_announcements_enabled": False},
        }

        mock_db_instance = MagicMock()
        mock_db_instance.get_user.return_value = existing_user
        mock_db_instance.update_user.return_value = updated_user
        mock_db.return_value = mock_db_instance

        mock_log.return_value = None

        # Disable voice announcements
        with authenticated_as(user_id) as client:
            response = client.put(
                f"/api/v1/users/{user_id}",
                json={
                    "notification_preferences": {
                        "voice_announcements_enabled": False
                    }
                }
            )

        assert response.status_code == 200

        # Verify update_user was called
        mock_db_instance.update_user.assert_called_once()
        call_args = mock_db_instance.update_user.call_args[0]
        update_data = call_args[1]

        assert "notification_preferences" in update_data
        assert update_data["notification_preferences"]["voice_announcements_enabled"] is False

    @patch('api.v1.users.profile.get_supabase_db')
    @patch('api.v1.users.profile.log_user_activity', new_callable=AsyncMock)
    def test_voice_announcements_preserves_other_notification_prefs(self, mock_log, mock_db):
        """Test that updating voice announcements preserves other notification preferences."""
        user_id = "test-user-voice-789"

        # Mock existing user with other notification preferences
        existing_user = {
            "id": user_id,
            "email": "test@example.com",
            "name": "Test User",
            "onboarding_completed": True,
            "fitness_level": "intermediate",
            "goals": '["build_muscle"]',
            "equipment": '["dumbbells"]',
            "preferences": '{}',
            "active_injuries": '[]',
            "created_at": "2024-01-01T00:00:00Z",
            "notification_preferences": {
                "workout_reminders": True,
                "daily_tips": False,
            },
        }

        # Mock updated user with merged preferences
        updated_user = {
            **existing_user,
            "notification_preferences": {
                "workout_reminders": True,
                "daily_tips": False,
                "voice_announcements_enabled": True,
            },
        }

        mock_db_instance = MagicMock()
        mock_db_instance.get_user.return_value = existing_user
        mock_db_instance.update_user.return_value = updated_user
        mock_db.return_value = mock_db_instance

        mock_log.return_value = None

        # Enable voice announcements
        with authenticated_as(user_id) as client:
            response = client.put(
                f"/api/v1/users/{user_id}",
                json={
                    "notification_preferences": {
                        "voice_announcements_enabled": True
                    }
                }
            )

        assert response.status_code == 200

        # Verify the merged preferences contain all values
        mock_db_instance.update_user.assert_called_once()
        call_args = mock_db_instance.update_user.call_args[0]
        update_data = call_args[1]

        prefs = update_data["notification_preferences"]
        # Original preferences should be preserved
        assert prefs["workout_reminders"] is True
        assert prefs["daily_tips"] is False
        # New preference should be added
        assert prefs["voice_announcements_enabled"] is True

    @patch('api.v1.users.profile.get_supabase_db')
    @patch('api.v1.users.profile.log_user_activity', new_callable=AsyncMock)
    def test_voice_announcements_with_new_user(self, mock_log, mock_db):
        """Test setting voice announcements for user with no prior notification_preferences.

        REGRESSION: `users.notification_preferences` is nullable, so a row that has
        never had prefs written comes back from PostgREST as an explicit
        `"notification_preferences": None` (the key IS present). The endpoint merged
        with `existing.get("notification_preferences", {})`, whose default only fires
        on a MISSING key — so it returned None and `{**None}` raised
        TypeError: 'NoneType' object is not a mapping → 500 for every user setting a
        notification preference for the first time.
        """
        user_id = "test-user-voice-new"

        # Mock existing user with NULL notification_preferences
        existing_user = {
            "id": user_id,
            "email": "test@example.com",
            "name": "New User",
            "onboarding_completed": True,
            "fitness_level": "beginner",
            "goals": '["general_fitness"]',
            "equipment": '[]',
            "preferences": '{}',
            "active_injuries": '[]',
            "created_at": "2024-01-01T00:00:00Z",
            "notification_preferences": None,
        }

        # Mock updated user
        updated_user = {
            **existing_user,
            "notification_preferences": {"voice_announcements_enabled": True},
        }

        mock_db_instance = MagicMock()
        mock_db_instance.get_user.return_value = existing_user
        mock_db_instance.update_user.return_value = updated_user
        mock_db.return_value = mock_db_instance

        mock_log.return_value = None

        # Enable voice announcements
        with authenticated_as(user_id) as client:
            response = client.put(
                f"/api/v1/users/{user_id}",
                json={
                    "notification_preferences": {
                        "voice_announcements_enabled": True
                    }
                }
            )

        assert response.status_code == 200

        # Verify update was called
        mock_db_instance.update_user.assert_called_once()
        call_args = mock_db_instance.update_user.call_args[0]
        update_data = call_args[1]

        assert "notification_preferences" in update_data
        assert update_data["notification_preferences"]["voice_announcements_enabled"] is True

    @patch('api.v1.users.profile.get_supabase_db')
    def test_voice_announcements_requires_authentication(self, mock_db):
        """An unauthenticated caller must not be able to write another user's prefs."""
        user_id = "test-user-voice-123"

        mock_db_instance = MagicMock()
        mock_db.return_value = mock_db_instance

        client = TestClient(app)
        response = client.put(
            f"/api/v1/users/{user_id}",
            json={"notification_preferences": {"voice_announcements_enabled": True}},
        )

        assert response.status_code == 401
        mock_db_instance.update_user.assert_not_called()
