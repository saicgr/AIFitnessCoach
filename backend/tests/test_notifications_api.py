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
import asyncio

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
def current_user(sample_user_id):
    """The authenticated caller.

    These endpoints are called directly as plain coroutines (not through the
    ASGI stack), so FastAPI never resolves `current_user: dict =
    Depends(get_current_user)` for us — the parameter default is the raw
    `Depends` marker object. Endpoints that IDOR-check the caller
    (`verify_user_ownership(current_user, request.user_id)`) then blow up with
    `TypeError: 'Depends' object is not subscriptable`, which the endpoint's
    own `except Exception` converts into a 500. Passing the identity explicitly
    is what FastAPI would have injected, and lets the real behavior under test
    (404 / success / DB-error paths) actually run.
    """
    return {"id": sample_user_id, "email": "user@example.com"}


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

    def test_send_test_notification_success(self, mock_supabase_db, mock_notification_service, sample_user, sample_user_id, sample_fcm_token, current_user):
        """Test successful test notification."""
        from api.v1.notifications import send_test_notification, TestNotificationRequest
        import asyncio

        mock_supabase_db.get_user.return_value = sample_user

        request = TestNotificationRequest(
            user_id=sample_user_id,
            fcm_token=sample_fcm_token
        )

        result = asyncio.get_event_loop().run_until_complete(
            send_test_notification(request, current_user=current_user)
        )

        assert result["success"] is True
        mock_supabase_db.update_user.assert_called_with(sample_user_id, {"fcm_token": sample_fcm_token})

    def test_send_test_notification_user_not_found(self, mock_supabase_db, mock_notification_service, sample_user_id, sample_fcm_token, current_user):
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
                send_test_notification(request, current_user=current_user)
            )

        assert exc_info.value.status_code == 404

    def test_send_test_notification_failure(self, mock_supabase_db, mock_notification_service, sample_user, sample_user_id, sample_fcm_token, current_user):
        """Test test notification failure.

        Was passing for the WRONG reason: with no `current_user` the endpoint
        died on `TypeError: 'Depends' object is not subscriptable` inside
        verify_user_ownership, which its `except Exception` mapped to the very
        500 this test asserts — so the FCM-send-failed path was never reached.
        """
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
                send_test_notification(request, current_user=current_user)
            )

        assert exc_info.value.status_code == 500


# ============================================================
# REGISTER FCM TOKEN TESTS
# ============================================================

class TestRegisterFCMToken:
    """Test FCM token registration endpoint."""

    def test_register_token_success(self, mock_supabase_db, sample_user, sample_user_id, sample_fcm_token, current_user):
        """Test successful FCM token registration.

        UPDATED WRITE PAYLOAD: /register used to persist exactly
        {"fcm_token": ...}. It now ALSO stamps `last_active_at` — a token
        register (login / token refresh / reinstall) is a real foreground
        signal, and the dormancy-taper notification engine reads that column.
        The original guarantee (the token the client sent is what gets written,
        under that user's id) is asserted exactly as before; the new column is
        asserted too, so a silent regression in either is still caught.
        """
        from api.v1.notifications import register_fcm_token, RegisterTokenRequest
        from datetime import datetime
        import asyncio

        mock_supabase_db.get_user.return_value = sample_user

        request = RegisterTokenRequest(
            user_id=sample_user_id,
            fcm_token=sample_fcm_token
        )

        result = asyncio.get_event_loop().run_until_complete(
            register_fcm_token(request, current_user=current_user)
        )

        assert result["success"] is True
        mock_supabase_db.update_user.assert_called_once()
        called_user_id, payload = mock_supabase_db.update_user.call_args[0]
        assert called_user_id == sample_user_id
        assert set(payload.keys()) == {"fcm_token", "last_active_at"}
        assert payload["fcm_token"] == sample_fcm_token
        # last_active_at must be a real ISO-8601 timestamp, not a placeholder
        assert datetime.fromisoformat(payload["last_active_at"]) is not None

    def test_register_token_user_not_found(self, mock_supabase_db, sample_user_id, sample_fcm_token, current_user):
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
                register_fcm_token(request, current_user=current_user)
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

    def test_scheduler_status(self, current_user):
        """Test scheduler status endpoint.

        RETIRED ASSERTION: `len(result["endpoints"]) == 2`. The scheduler had 2
        cron endpoints when this was written; it now has 5 (billing reminders,
        NEAT movement reminders and optimal-send-time recalculation were added
        after). A bare count is also a weak assertion — it can't tell WHICH
        endpoint went missing. It is replaced by an exact-set assertion on the
        advertised paths, which is strictly stronger: it fails if any cron
        endpoint disappears from the manifest the external cron jobs are wired
        against, and it fails if one appears undocumented.
        """
        from api.v1.notifications import scheduler_status
        import asyncio

        result = asyncio.get_event_loop().run_until_complete(
            scheduler_status(current_user=current_user)
        )

        assert result["status"] == "ok"
        assert {e["path"] for e in result["endpoints"]} == {
            "/scheduler/check-inactive-users",
            "/scheduler/send-workout-reminders",
            "/scheduler/send-billing-reminders",
            "/scheduler/send-movement-reminders",
            "/scheduler/recalculate-optimal-times",
        }
        assert any(e["path"] == "/scheduler/check-inactive-users" for e in result["endpoints"])
        # Every advertised endpoint must carry the info a cron operator needs
        for e in result["endpoints"]:
            assert e["method"] == "POST"
            assert e["description"]
            assert e["recommended_schedule"]


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

    def test_database_error(self, mock_supabase_db, sample_user_id, sample_fcm_token, current_user):
        """Test handling database errors.

        Was passing for the WRONG reason: with no `current_user` the endpoint
        raised TypeError in verify_user_ownership *before* touching the DB, and
        that TypeError produced the asserted 500 — the DB-failure path was
        never exercised. Now the caller is authenticated, so the 500 really
        does come from `get_user` raising.
        """
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
                register_fcm_token(request, current_user=current_user)
            )

        assert exc_info.value.status_code == 500


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
