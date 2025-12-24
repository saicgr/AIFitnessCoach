"""
Tests for Push Notification API endpoints.

Tests:
- Test notification sending
- FCM token registration
- Custom notification sending
- Workout, guilt, nutrition, hydration reminders
- Scheduler endpoints

Run with: pytest backend/tests/test_notifications_api.py -v
"""

import pytest
from unittest.mock import MagicMock, patch, AsyncMock
from datetime import datetime


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def mock_supabase_db():
    """Mock SupabaseDB for notification operations."""
    with patch("api.v1.notifications.get_supabase_db") as mock_get_db:
        mock_db = MagicMock()
        mock_get_db.return_value = mock_db
        yield mock_db


@pytest.fixture
def mock_notification_service():
    """Mock NotificationService."""
    with patch("api.v1.notifications.get_notification_service") as mock_get_service:
        mock_service = MagicMock()
        mock_get_service.return_value = mock_service
        mock_service.send_test_notification = AsyncMock(return_value=True)
        mock_service.send_notification = AsyncMock(return_value=True)
        mock_service.send_workout_reminder = AsyncMock(return_value=True)
        mock_service.send_missed_workout_guilt = AsyncMock(return_value=True)
        mock_service.send_nutrition_reminder = AsyncMock(return_value=True)
        mock_service.send_hydration_reminder = AsyncMock(return_value=True)
        yield mock_service


@pytest.fixture
def sample_user_id():
    return "user-123-abc"


@pytest.fixture
def sample_fcm_token():
    return "fcm_token_abc123xyz"


@pytest.fixture
def sample_user():
    return {
        "id": "user-123-abc",
        "name": "John Doe",
        "fcm_token": "fcm_token_abc123xyz",
        "notification_preferences": {"workout_reminders": True, "streak_alerts": True},
    }


# ============================================================
# TEST NOTIFICATION TESTS
# ============================================================

class TestTestNotification:
    """Test test notification endpoint."""

    def test_send_test_notification_success(self, mock_supabase_db, mock_notification_service, sample_user, sample_user_id, sample_fcm_token):
        """Test successful test notification."""
        from api.v1.notifications import send_test_notification, TestNotificationRequest
        import asyncio

        mock_supabase_db.get_user.return_value = sample_user

        request = TestNotificationRequest(
            user_id=sample_user_id,
            fcm_token=sample_fcm_token
        )

        result = asyncio.get_event_loop().run_until_complete(
            send_test_notification(request)
        )

        assert result["success"] is True
        mock_supabase_db.update_user.assert_called_with(sample_user_id, {"fcm_token": sample_fcm_token})

    def test_send_test_notification_user_not_found(self, mock_supabase_db, mock_notification_service, sample_user_id, sample_fcm_token):
        """Test test notification for non-existent user."""
        from api.v1.notifications import send_test_notification, TestNotificationRequest
        from fastapi import HTTPException
        import asyncio

        mock_supabase_db.get_user.return_value = None

        request = TestNotificationRequest(
            user_id=sample_user_id,
            fcm_token=sample_fcm_token
        )

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                send_test_notification(request)
            )

        assert exc_info.value.status_code == 404

    def test_send_test_notification_failure(self, mock_supabase_db, mock_notification_service, sample_user, sample_user_id, sample_fcm_token):
        """Test test notification failure."""
        from api.v1.notifications import send_test_notification, TestNotificationRequest
        from fastapi import HTTPException
        import asyncio

        mock_supabase_db.get_user.return_value = sample_user
        mock_notification_service.send_test_notification = AsyncMock(return_value=False)

        request = TestNotificationRequest(
            user_id=sample_user_id,
            fcm_token=sample_fcm_token
        )

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                send_test_notification(request)
            )

        assert exc_info.value.status_code == 500


# ============================================================
# REGISTER FCM TOKEN TESTS
# ============================================================

class TestRegisterFCMToken:
    """Test FCM token registration endpoint."""

    def test_register_token_success(self, mock_supabase_db, sample_user, sample_user_id, sample_fcm_token):
        """Test successful FCM token registration."""
        from api.v1.notifications import register_fcm_token, RegisterTokenRequest
        import asyncio

        mock_supabase_db.get_user.return_value = sample_user

        request = RegisterTokenRequest(
            user_id=sample_user_id,
            fcm_token=sample_fcm_token
        )

        result = asyncio.get_event_loop().run_until_complete(
            register_fcm_token(request)
        )

        assert result["success"] is True
        mock_supabase_db.update_user.assert_called_with(sample_user_id, {"fcm_token": sample_fcm_token})

    def test_register_token_user_not_found(self, mock_supabase_db, sample_user_id, sample_fcm_token):
        """Test token registration for non-existent user."""
        from api.v1.notifications import register_fcm_token, RegisterTokenRequest
        from fastapi import HTTPException
        import asyncio

        mock_supabase_db.get_user.return_value = None

        request = RegisterTokenRequest(
            user_id=sample_user_id,
            fcm_token=sample_fcm_token
        )

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                register_fcm_token(request)
            )

        assert exc_info.value.status_code == 404


# ============================================================
# SEND NOTIFICATION TESTS
# ============================================================

class TestSendNotification:
    """Test custom notification sending endpoint."""

    def test_send_notification_success(self, mock_supabase_db, mock_notification_service, sample_user, sample_user_id):
        """Test successful custom notification."""
        from api.v1.notifications import send_notification, SendNotificationRequest
        import asyncio

        mock_supabase_db.get_user.return_value = sample_user

        request = SendNotificationRequest(
            user_id=sample_user_id,
            title="Test Title",
            body="Test Body",
            notification_type="ai_coach",
            data={"key": "value"}
        )

        result = asyncio.get_event_loop().run_until_complete(
            send_notification(request)
        )

        assert result["success"] is True
        mock_notification_service.send_notification.assert_called_once()

    def test_send_notification_no_fcm_token(self, mock_supabase_db, mock_notification_service, sample_user_id):
        """Test notification when user has no FCM token."""
        from api.v1.notifications import send_notification, SendNotificationRequest
        from fastapi import HTTPException
        import asyncio

        user_no_token = {"id": sample_user_id, "name": "No Token User", "fcm_token": None}
        mock_supabase_db.get_user.return_value = user_no_token

        request = SendNotificationRequest(
            user_id=sample_user_id,
            title="Test",
            body="Test"
        )

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                send_notification(request)
            )

        assert exc_info.value.status_code == 400


# ============================================================
# WORKOUT REMINDER TESTS
# ============================================================

class TestWorkoutReminder:
    """Test workout reminder endpoint."""

    def test_send_workout_reminder_success(self, mock_supabase_db, mock_notification_service, sample_user, sample_user_id):
        """Test successful workout reminder."""
        from api.v1.notifications import send_workout_reminder
        import asyncio

        mock_supabase_db.get_user.return_value = sample_user

        result = asyncio.get_event_loop().run_until_complete(
            send_workout_reminder(sample_user_id, workout_name="Upper Body")
        )

        assert result["success"] is True

    def test_send_workout_reminder_no_fcm(self, mock_supabase_db, mock_notification_service, sample_user_id):
        """Test workout reminder without FCM token."""
        from api.v1.notifications import send_workout_reminder
        from fastapi import HTTPException
        import asyncio

        user_no_token = {"id": sample_user_id, "fcm_token": None}
        mock_supabase_db.get_user.return_value = user_no_token

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                send_workout_reminder(sample_user_id)
            )

        assert exc_info.value.status_code == 400


# ============================================================
# GUILT NOTIFICATION TESTS
# ============================================================

class TestGuiltNotification:
    """Test guilt notification endpoint."""

    def test_send_guilt_notification_success(self, mock_supabase_db, mock_notification_service, sample_user, sample_user_id):
        """Test successful guilt notification."""
        from api.v1.notifications import send_guilt_notification
        import asyncio

        mock_supabase_db.get_user.return_value = sample_user

        result = asyncio.get_event_loop().run_until_complete(
            send_guilt_notification(sample_user_id, days_missed=3)
        )

        assert result["success"] is True


# ============================================================
# NUTRITION REMINDER TESTS
# ============================================================

class TestNutritionReminder:
    """Test nutrition reminder endpoint."""

    def test_send_nutrition_reminder_success(self, mock_supabase_db, mock_notification_service, sample_user, sample_user_id):
        """Test successful nutrition reminder."""
        from api.v1.notifications import send_nutrition_reminder
        import asyncio

        mock_supabase_db.get_user.return_value = sample_user

        result = asyncio.get_event_loop().run_until_complete(
            send_nutrition_reminder(sample_user_id, meal_type="lunch")
        )

        assert result["success"] is True


# ============================================================
# HYDRATION REMINDER TESTS
# ============================================================

class TestHydrationReminder:
    """Test hydration reminder endpoint."""

    def test_send_hydration_reminder_success(self, mock_supabase_db, mock_notification_service, sample_user, sample_user_id):
        """Test successful hydration reminder."""
        from api.v1.notifications import send_hydration_reminder
        import asyncio

        mock_supabase_db.get_user.return_value = sample_user

        result = asyncio.get_event_loop().run_until_complete(
            send_hydration_reminder(sample_user_id, current_ml=500, goal_ml=2000)
        )

        assert result["success"] is True


# ============================================================
# SCHEDULER ENDPOINTS TESTS
# ============================================================

class TestSchedulerEndpoints:
    """Test scheduler endpoints."""

    def test_check_inactive_users(self, mock_supabase_db, mock_notification_service):
        """Test checking inactive users scheduler."""
        from api.v1.notifications import check_inactive_users
        import asyncio
        from datetime import datetime, timedelta

        # Mock client for direct table access
        mock_client = MagicMock()
        mock_supabase_db.client = mock_client

        # Users with FCM tokens
        mock_users_response = MagicMock()
        mock_users_response.data = [
            {
                "id": "user-1",
                "name": "User 1",
                "fcm_token": "token-1",
                "notification_preferences": {"streak_alerts": True}
            }
        ]
        mock_client.table.return_value.select.return_value.not_.return_value.is_.return_value.execute.return_value = mock_users_response

        # Last workout 2 days ago
        yesterday = datetime.utcnow() - timedelta(days=2)
        mock_workouts_response = MagicMock()
        mock_workouts_response.data = [{"created_at": yesterday.isoformat()}]
        mock_client.table.return_value.select.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value = mock_workouts_response

        result = asyncio.get_event_loop().run_until_complete(
            check_inactive_users()
        )

        assert "total_users" in result
        assert "notifications_sent" in result

    def test_scheduler_status(self):
        """Test scheduler status endpoint."""
        from api.v1.notifications import scheduler_status
        import asyncio

        result = asyncio.get_event_loop().run_until_complete(
            scheduler_status()
        )

        assert result["status"] == "ok"
        assert len(result["endpoints"]) == 2
        assert any(e["path"] == "/scheduler/check-inactive-users" for e in result["endpoints"])


# ============================================================
# MODEL VALIDATION TESTS
# ============================================================

class TestNotificationModels:
    """Test Pydantic model validation."""

    def test_test_notification_request(self):
        """Test TestNotificationRequest model."""
        from api.v1.notifications import TestNotificationRequest

        request = TestNotificationRequest(
            user_id="user-123",
            fcm_token="token-abc"
        )

        assert request.user_id == "user-123"
        assert request.fcm_token == "token-abc"

    def test_register_token_request(self):
        """Test RegisterTokenRequest model."""
        from api.v1.notifications import RegisterTokenRequest

        request = RegisterTokenRequest(
            user_id="user-123",
            fcm_token="new-token"
        )

        assert request.user_id == "user-123"

    def test_send_notification_request(self):
        """Test SendNotificationRequest model."""
        from api.v1.notifications import SendNotificationRequest

        request = SendNotificationRequest(
            user_id="user-123",
            title="Test Title",
            body="Test Body"
        )

        assert request.notification_type == "ai_coach"  # Default
        assert request.data is None  # Optional


# ============================================================
# ERROR HANDLING TESTS
# ============================================================

class TestErrorHandling:
    """Test error handling across endpoints."""

    def test_notification_service_error(self, mock_supabase_db, mock_notification_service, sample_user, sample_user_id):
        """Test handling notification service errors."""
        from api.v1.notifications import send_notification, SendNotificationRequest
        from fastapi import HTTPException
        import asyncio

        mock_supabase_db.get_user.return_value = sample_user
        mock_notification_service.send_notification = AsyncMock(return_value=False)

        request = SendNotificationRequest(
            user_id=sample_user_id,
            title="Test",
            body="Test"
        )

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                send_notification(request)
            )

        assert exc_info.value.status_code == 500

    def test_database_error(self, mock_supabase_db, sample_user_id, sample_fcm_token):
        """Test handling database errors."""
        from api.v1.notifications import register_fcm_token, RegisterTokenRequest
        from fastapi import HTTPException
        import asyncio

        mock_supabase_db.get_user.side_effect = Exception("Database connection failed")

        request = RegisterTokenRequest(
            user_id=sample_user_id,
            fcm_token=sample_fcm_token
        )

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                register_fcm_token(request)
            )

        assert exc_info.value.status_code == 500


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
