"""
Tests for Push Notification Service.

Tests:
- Firebase initialization
- Notification sending
- Multicast notifications
- Pre-built notification messages
- Error handling

Run with: pytest backend/tests/test_notification_service.py -v
"""

import pytest
from unittest.mock import MagicMock, patch, AsyncMock
from datetime import datetime


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def mock_firebase():
    """Mock Firebase Admin SDK."""
    with patch("services.notification_service.firebase_admin") as mock_admin:
        with patch("services.notification_service.credentials") as mock_creds:
            with patch("services.notification_service.messaging") as mock_messaging:
                mock_admin.initialize_app = MagicMock()
                mock_creds.Certificate = MagicMock()
                mock_messaging.send = MagicMock(return_value="message-id-123")
                mock_messaging.send_each_for_multicast = MagicMock()
                mock_messaging.Notification = MagicMock()
                mock_messaging.AndroidConfig = MagicMock()
                mock_messaging.AndroidNotification = MagicMock()
                mock_messaging.Message = MagicMock()
                mock_messaging.MulticastMessage = MagicMock()
                yield mock_messaging


@pytest.fixture
def notification_service(mock_firebase):
    """Create notification service with mocked Firebase."""
    # Reset singleton
    import services.notification_service as ns
    ns._firebase_app = MagicMock()  # Pretend Firebase is initialized
    ns._notification_service = None

    from services.notification_service import NotificationService
    service = NotificationService()
    yield service


@pytest.fixture
def sample_fcm_token():
    return "fcm_token_abc123xyz789def456"


# ============================================================
# CHANNEL ID TESTS
# ============================================================

class TestChannelIds:
    """Test notification channel ID mapping."""

    def test_get_channel_id_workout_reminder(self, notification_service):
        """Test channel ID for workout reminder."""
        channel = notification_service._get_channel_id(notification_service.TYPE_WORKOUT_REMINDER)
        assert channel == "workout_coach"

    def test_get_channel_id_nutrition_reminder(self, notification_service):
        """Test channel ID for nutrition reminder."""
        channel = notification_service._get_channel_id(notification_service.TYPE_NUTRITION_REMINDER)
        assert channel == "nutrition_coach"

    def test_get_channel_id_unknown_type(self, notification_service):
        """Test default channel ID for unknown type."""
        channel = notification_service._get_channel_id("unknown_type")
        assert channel == notification_service.DEFAULT_CHANNEL_ID


# ============================================================
# SEND NOTIFICATION TESTS
# ============================================================

class TestSendNotification:
    """Test single notification sending."""

    def test_send_notification_success(self, notification_service, mock_firebase, sample_fcm_token):
        """Test successful notification sending."""
        import asyncio

        result = asyncio.get_event_loop().run_until_complete(
            notification_service.send_notification(
                fcm_token=sample_fcm_token,
                title="Test Title",
                body="Test Body"
            )
        )

        assert result is True
        mock_firebase.send.assert_called_once()

    def test_send_notification_with_data(self, notification_service, mock_firebase, sample_fcm_token):
        """Test notification with custom data payload."""
        import asyncio

        result = asyncio.get_event_loop().run_until_complete(
            notification_service.send_notification(
                fcm_token=sample_fcm_token,
                title="Test",
                body="Test",
                notification_type="workout_reminder",
                data={"workout_id": "123", "action": "open_workout"}
            )
        )

        assert result is True

    def test_send_notification_with_image(self, notification_service, mock_firebase, sample_fcm_token):
        """Test notification with image URL."""
        import asyncio

        result = asyncio.get_event_loop().run_until_complete(
            notification_service.send_notification(
                fcm_token=sample_fcm_token,
                title="Test",
                body="Test",
                image_url="https://example.com/image.png"
            )
        )

        assert result is True

    def test_send_notification_unregistered_error(self, notification_service, mock_firebase, sample_fcm_token):
        """Test handling of unregistered FCM token."""
        import asyncio
        from firebase_admin import messaging

        mock_firebase.UnregisteredError = messaging.UnregisteredError
        mock_firebase.send.side_effect = messaging.UnregisteredError("Token unregistered")

        result = asyncio.get_event_loop().run_until_complete(
            notification_service.send_notification(
                fcm_token=sample_fcm_token,
                title="Test",
                body="Test"
            )
        )

        assert result is False

    def test_send_notification_sender_mismatch_error(self, notification_service, mock_firebase, sample_fcm_token):
        """Test handling of sender ID mismatch."""
        import asyncio
        from firebase_admin import messaging

        mock_firebase.SenderIdMismatchError = messaging.SenderIdMismatchError
        mock_firebase.send.side_effect = messaging.SenderIdMismatchError("Sender mismatch")

        result = asyncio.get_event_loop().run_until_complete(
            notification_service.send_notification(
                fcm_token=sample_fcm_token,
                title="Test",
                body="Test"
            )
        )

        assert result is False

    def test_send_notification_general_error(self, notification_service, mock_firebase, sample_fcm_token):
        """Test handling of general errors."""
        import asyncio

        mock_firebase.send.side_effect = Exception("Network error")

        result = asyncio.get_event_loop().run_until_complete(
            notification_service.send_notification(
                fcm_token=sample_fcm_token,
                title="Test",
                body="Test"
            )
        )

        assert result is False


# ============================================================
# MULTICAST NOTIFICATION TESTS
# ============================================================

class TestMulticastNotification:
    """Test multicast notification sending."""

    def test_send_multicast_success(self, notification_service, mock_firebase):
        """Test successful multicast notification."""
        import asyncio

        mock_response = MagicMock()
        mock_response.success_count = 5
        mock_response.failure_count = 0
        mock_firebase.send_each_for_multicast.return_value = mock_response

        tokens = [f"token_{i}" for i in range(5)]

        result = asyncio.get_event_loop().run_until_complete(
            notification_service.send_multicast(
                fcm_tokens=tokens,
                title="Broadcast",
                body="Message to all"
            )
        )

        assert result["success_count"] == 5
        assert result["failure_count"] == 0

    def test_send_multicast_partial_failure(self, notification_service, mock_firebase):
        """Test multicast with partial failures."""
        import asyncio

        mock_response = MagicMock()
        mock_response.success_count = 3
        mock_response.failure_count = 2
        mock_firebase.send_each_for_multicast.return_value = mock_response

        tokens = [f"token_{i}" for i in range(5)]

        result = asyncio.get_event_loop().run_until_complete(
            notification_service.send_multicast(
                fcm_tokens=tokens,
                title="Broadcast",
                body="Message"
            )
        )

        assert result["success_count"] == 3
        assert result["failure_count"] == 2

    def test_send_multicast_error(self, notification_service, mock_firebase):
        """Test multicast error handling."""
        import asyncio

        mock_firebase.send_each_for_multicast.side_effect = Exception("Multicast error")

        tokens = [f"token_{i}" for i in range(5)]

        result = asyncio.get_event_loop().run_until_complete(
            notification_service.send_multicast(
                fcm_tokens=tokens,
                title="Broadcast",
                body="Message"
            )
        )

        assert result["success_count"] == 0
        assert result["failure_count"] == 5


# ============================================================
# PRE-BUILT NOTIFICATION TESTS
# ============================================================

class TestPrebuiltNotifications:
    """Test pre-built notification messages."""

    def test_send_workout_reminder(self, notification_service, mock_firebase, sample_fcm_token):
        """Test workout reminder notification."""
        import asyncio

        result = asyncio.get_event_loop().run_until_complete(
            notification_service.send_workout_reminder(
                fcm_token=sample_fcm_token,
                workout_name="Upper Body",
                user_name="John"
            )
        )

        assert result is True

    def test_send_workout_reminder_no_user_name(self, notification_service, mock_firebase, sample_fcm_token):
        """Test workout reminder without user name."""
        import asyncio

        result = asyncio.get_event_loop().run_until_complete(
            notification_service.send_workout_reminder(
                fcm_token=sample_fcm_token,
                workout_name="Leg Day"
            )
        )

        assert result is True

    def test_send_missed_workout_guilt_one_day(self, notification_service, mock_firebase, sample_fcm_token):
        """Test guilt notification for 1 day missed."""
        import asyncio

        result = asyncio.get_event_loop().run_until_complete(
            notification_service.send_missed_workout_guilt(
                fcm_token=sample_fcm_token,
                days_missed=1
            )
        )

        assert result is True

    def test_send_missed_workout_guilt_two_days(self, notification_service, mock_firebase, sample_fcm_token):
        """Test guilt notification for 2 days missed."""
        import asyncio

        result = asyncio.get_event_loop().run_until_complete(
            notification_service.send_missed_workout_guilt(
                fcm_token=sample_fcm_token,
                days_missed=2
            )
        )

        assert result is True

    def test_send_missed_workout_guilt_many_days(self, notification_service, mock_firebase, sample_fcm_token):
        """Test guilt notification for 3+ days missed."""
        import asyncio

        result = asyncio.get_event_loop().run_until_complete(
            notification_service.send_missed_workout_guilt(
                fcm_token=sample_fcm_token,
                days_missed=5
            )
        )

        assert result is True

    def test_send_streak_celebration(self, notification_service, mock_firebase, sample_fcm_token):
        """Test streak celebration notification."""
        import asyncio

        result = asyncio.get_event_loop().run_until_complete(
            notification_service.send_streak_celebration(
                fcm_token=sample_fcm_token,
                streak_days=7
            )
        )

        assert result is True

    def test_send_nutrition_reminder(self, notification_service, mock_firebase, sample_fcm_token):
        """Test nutrition reminder notification."""
        import asyncio

        result = asyncio.get_event_loop().run_until_complete(
            notification_service.send_nutrition_reminder(
                fcm_token=sample_fcm_token,
                meal_type="lunch"
            )
        )

        assert result is True

    def test_send_hydration_reminder_low_progress(self, notification_service, mock_firebase, sample_fcm_token):
        """Test hydration reminder when below 50%."""
        import asyncio

        result = asyncio.get_event_loop().run_until_complete(
            notification_service.send_hydration_reminder(
                fcm_token=sample_fcm_token,
                current_ml=500,
                goal_ml=2000
            )
        )

        assert result is True

    def test_send_hydration_reminder_high_progress(self, notification_service, mock_firebase, sample_fcm_token):
        """Test hydration reminder when above 50%."""
        import asyncio

        result = asyncio.get_event_loop().run_until_complete(
            notification_service.send_hydration_reminder(
                fcm_token=sample_fcm_token,
                current_ml=1500,
                goal_ml=2000
            )
        )

        assert result is True

    def test_send_weekly_summary_ready(self, notification_service, mock_firebase, sample_fcm_token):
        """Test weekly summary ready notification."""
        import asyncio

        result = asyncio.get_event_loop().run_until_complete(
            notification_service.send_weekly_summary_ready(
                fcm_token=sample_fcm_token,
                workouts_completed=5
            )
        )

        assert result is True

    def test_send_weekly_summary_singular(self, notification_service, mock_firebase, sample_fcm_token):
        """Test weekly summary with singular workout."""
        import asyncio

        result = asyncio.get_event_loop().run_until_complete(
            notification_service.send_weekly_summary_ready(
                fcm_token=sample_fcm_token,
                workouts_completed=1
            )
        )

        assert result is True

    def test_send_test_notification(self, notification_service, mock_firebase, sample_fcm_token):
        """Test test notification."""
        import asyncio

        result = asyncio.get_event_loop().run_until_complete(
            notification_service.send_test_notification(
                fcm_token=sample_fcm_token
            )
        )

        assert result is True


# ============================================================
# FIREBASE INITIALIZATION TESTS
# ============================================================

class TestFirebaseInitialization:
    """Test Firebase initialization."""

    def test_initialize_firebase_with_credentials_file(self):
        """Test initialization with credentials file."""
        import os
        import tempfile
        import json

        # Create a temporary credentials file
        creds = {
            "type": "service_account",
            "project_id": "test-project",
            "private_key_id": "key-id",
            "private_key": "-----BEGIN RSA PRIVATE KEY-----\ntest\n-----END RSA PRIVATE KEY-----\n",
            "client_email": "test@test-project.iam.gserviceaccount.com",
            "client_id": "123",
            "auth_uri": "https://accounts.google.com/o/oauth2/auth",
            "token_uri": "https://oauth2.googleapis.com/token",
        }

        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(creds, f)
            creds_path = f.name

        try:
            with patch.dict("os.environ", {"FIREBASE_CREDENTIALS_PATH": creds_path}):
                with patch("services.notification_service.firebase_admin") as mock_admin:
                    with patch("services.notification_service.credentials") as mock_creds:
                        # Reset singleton
                        import services.notification_service as ns
                        ns._firebase_app = None

                        from services.notification_service import initialize_firebase

                        initialize_firebase()

                        mock_creds.Certificate.assert_called_once()
                        mock_admin.initialize_app.assert_called_once()
        finally:
            os.unlink(creds_path)

    def test_initialize_firebase_returns_cached(self):
        """Test that initialize_firebase returns cached app."""
        import services.notification_service as ns

        mock_app = MagicMock()
        ns._firebase_app = mock_app

        from services.notification_service import initialize_firebase

        result = initialize_firebase()
        assert result is mock_app


# ============================================================
# SINGLETON TESTS
# ============================================================

class TestNotificationServiceSingleton:
    """Test notification service singleton pattern."""

    def test_get_notification_service_returns_same_instance(self, mock_firebase):
        """Test that get_notification_service returns singleton."""
        import services.notification_service as ns
        ns._firebase_app = MagicMock()
        ns._notification_service = None

        from services.notification_service import get_notification_service

        service1 = get_notification_service()
        service2 = get_notification_service()

        assert service1 is service2


# ============================================================
# NOTIFICATION TYPE CONSTANTS TESTS
# ============================================================

class TestNotificationTypeConstants:
    """Test notification type constants."""

    def test_notification_types_defined(self, notification_service):
        """Test that all notification types are defined."""
        assert notification_service.TYPE_WORKOUT_REMINDER == "workout_reminder"
        assert notification_service.TYPE_NUTRITION_REMINDER == "nutrition_reminder"
        assert notification_service.TYPE_HYDRATION_REMINDER == "hydration_reminder"
        assert notification_service.TYPE_AI_COACH == "ai_coach"
        assert notification_service.TYPE_STREAK_ALERT == "streak_alert"
        assert notification_service.TYPE_WEEKLY_SUMMARY == "weekly_summary"
        assert notification_service.TYPE_TEST == "test"

    def test_channel_ids_mapped(self, notification_service):
        """Test that all types have channel IDs mapped."""
        for notification_type in [
            notification_service.TYPE_WORKOUT_REMINDER,
            notification_service.TYPE_NUTRITION_REMINDER,
            notification_service.TYPE_HYDRATION_REMINDER,
            notification_service.TYPE_STREAK_ALERT,
            notification_service.TYPE_WEEKLY_SUMMARY,
            notification_service.TYPE_AI_COACH,
            notification_service.TYPE_TEST,
        ]:
            channel_id = notification_service._get_channel_id(notification_type)
            assert channel_id is not None
            assert len(channel_id) > 0


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
