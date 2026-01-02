"""
Tests for Voice Announcements Preference API.

Tests the voice_announcements_enabled setting within notification_preferences.
This preference controls TTS announcements during workouts.
"""
import pytest
from unittest.mock import MagicMock, patch


class TestVoiceAnnouncementsPreference:
    """Tests for voice announcements preference in notification_preferences."""

    @patch('api.v1.users.get_supabase_db')
    @patch('api.v1.users.log_user_activity')
    def test_enable_voice_announcements(self, mock_log, mock_db, client):
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

    @patch('api.v1.users.get_supabase_db')
    @patch('api.v1.users.log_user_activity')
    def test_disable_voice_announcements(self, mock_log, mock_db, client):
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

    @patch('api.v1.users.get_supabase_db')
    @patch('api.v1.users.log_user_activity')
    def test_voice_announcements_preserves_other_notification_prefs(self, mock_log, mock_db, client):
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

    @patch('api.v1.users.get_supabase_db')
    @patch('api.v1.users.log_user_activity')
    def test_voice_announcements_with_new_user(self, mock_log, mock_db, client):
        """Test setting voice announcements for user with no prior notification_preferences."""
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
