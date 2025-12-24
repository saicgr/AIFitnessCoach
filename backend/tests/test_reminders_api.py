"""
Tests for Email Reminder API endpoints.

Tests:
- Email service status
- Daily reminder sending
- Single user reminder sending
- Test reminder sending

Run with: pytest backend/tests/test_reminders_api.py -v
"""

import pytest
from unittest.mock import MagicMock, patch, AsyncMock
from datetime import date


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def mock_supabase_db():
    """Mock SupabaseDB for reminder operations."""
    with patch("api.v1.reminders.get_supabase_db") as mock_get_db:
        mock_db = MagicMock()
        mock_get_db.return_value = mock_db
        yield mock_db


@pytest.fixture
def mock_email_service():
    """Mock EmailService."""
    with patch("api.v1.reminders.get_email_service") as mock_get_service:
        mock_service = MagicMock()
        mock_get_service.return_value = mock_service
        mock_service.is_configured.return_value = True
        mock_service.from_email = "noreply@aifitness.com"
        mock_service.send_workout_reminder = AsyncMock(return_value={"success": True, "id": "email-123"})
        yield mock_service


@pytest.fixture
def sample_user_id():
    return "user-123-abc"


@pytest.fixture
def sample_user():
    return {
        "id": "user-123-abc",
        "name": "John Doe",
        "email": "john@example.com",
        "preferences": {
            "email": "john@example.com",
            "name": "John",
        }
    }


@pytest.fixture
def sample_workout():
    return {
        "id": "workout-1",
        "name": "Upper Body Strength",
        "type": "strength",
        "exercises_json": '[{"name": "Bench Press", "sets": 4, "reps": 8}]',
    }


# ============================================================
# EMAIL STATUS TESTS
# ============================================================

class TestEmailStatus:
    """Test email service status endpoint."""

    def test_get_email_status_configured(self, mock_email_service):
        """Test getting email status when configured."""
        from api.v1.reminders import get_email_status
        import asyncio

        result = asyncio.get_event_loop().run_until_complete(
            get_email_status()
        )

        assert result["configured"] is True
        assert result["from_email"] == "noreply@aifitness.com"

    def test_get_email_status_not_configured(self, mock_email_service):
        """Test getting email status when not configured."""
        from api.v1.reminders import get_email_status
        import asyncio

        mock_email_service.is_configured.return_value = False

        result = asyncio.get_event_loop().run_until_complete(
            get_email_status()
        )

        assert result["configured"] is False


# ============================================================
# SEND DAILY REMINDERS TESTS
# ============================================================

class TestSendDailyReminders:
    """Test daily reminder sending endpoint."""

    def test_send_daily_reminders_success(self, mock_supabase_db, mock_email_service, sample_user, sample_workout):
        """Test successful daily reminder sending."""
        from api.v1.reminders import send_daily_reminders
        import asyncio

        mock_supabase_db.get_all_users.return_value = [sample_user]
        mock_supabase_db.list_current_workouts.return_value = [sample_workout]

        result = asyncio.get_event_loop().run_until_complete(
            send_daily_reminders()
        )

        assert result.success is True
        assert result.sent_count == 1
        assert result.failed_count == 0

    def test_send_daily_reminders_no_workouts(self, mock_supabase_db, mock_email_service, sample_user):
        """Test daily reminders when users have no workouts."""
        from api.v1.reminders import send_daily_reminders
        import asyncio

        mock_supabase_db.get_all_users.return_value = [sample_user]
        mock_supabase_db.list_current_workouts.return_value = []

        result = asyncio.get_event_loop().run_until_complete(
            send_daily_reminders()
        )

        assert result.sent_count == 0
        assert result.failed_count == 0

    def test_send_daily_reminders_no_email(self, mock_supabase_db, mock_email_service, sample_workout):
        """Test daily reminders when user has no email."""
        from api.v1.reminders import send_daily_reminders
        import asyncio

        user_no_email = {"id": "user-123", "name": "No Email User", "preferences": {}}
        mock_supabase_db.get_all_users.return_value = [user_no_email]
        mock_supabase_db.list_current_workouts.return_value = [sample_workout]

        result = asyncio.get_event_loop().run_until_complete(
            send_daily_reminders()
        )

        assert result.sent_count == 0
        assert result.failed_count == 1

    def test_send_daily_reminders_email_not_configured(self, mock_supabase_db, mock_email_service):
        """Test daily reminders when email service is not configured."""
        from api.v1.reminders import send_daily_reminders
        from fastapi import HTTPException
        import asyncio

        mock_email_service.is_configured.return_value = False

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                send_daily_reminders()
            )

        assert exc_info.value.status_code == 503

    def test_send_daily_reminders_with_target_date(self, mock_supabase_db, mock_email_service, sample_user, sample_workout):
        """Test daily reminders with specific target date."""
        from api.v1.reminders import send_daily_reminders
        import asyncio

        mock_supabase_db.get_all_users.return_value = [sample_user]
        mock_supabase_db.list_current_workouts.return_value = [sample_workout]

        asyncio.get_event_loop().run_until_complete(
            send_daily_reminders(target_date="2025-01-15")
        )

        # Verify the date was used in the query
        call_args = mock_supabase_db.list_current_workouts.call_args
        assert call_args[1]["from_date"] == "2025-01-15"
        assert call_args[1]["to_date"] == "2025-01-15"

    def test_send_daily_reminders_invalid_date(self, mock_supabase_db, mock_email_service):
        """Test daily reminders with invalid date format."""
        from api.v1.reminders import send_daily_reminders
        from fastapi import HTTPException
        import asyncio

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                send_daily_reminders(target_date="invalid-date")
            )

        assert exc_info.value.status_code == 400

    def test_send_daily_reminders_email_failure(self, mock_supabase_db, mock_email_service, sample_user, sample_workout):
        """Test handling email send failures."""
        from api.v1.reminders import send_daily_reminders
        import asyncio

        mock_supabase_db.get_all_users.return_value = [sample_user]
        mock_supabase_db.list_current_workouts.return_value = [sample_workout]
        mock_email_service.send_workout_reminder = AsyncMock(
            return_value={"success": False, "error": "SMTP error"}
        )

        result = asyncio.get_event_loop().run_until_complete(
            send_daily_reminders()
        )

        assert result.sent_count == 0
        assert result.failed_count == 1


# ============================================================
# SEND USER REMINDER TESTS
# ============================================================

class TestSendUserReminder:
    """Test single user reminder endpoint."""

    def test_send_user_reminder_success(self, mock_supabase_db, mock_email_service, sample_user, sample_workout, sample_user_id):
        """Test successful single user reminder."""
        from api.v1.reminders import send_user_reminder
        import asyncio

        mock_supabase_db.get_user.return_value = sample_user
        mock_supabase_db.list_current_workouts.return_value = [sample_workout]

        result = asyncio.get_event_loop().run_until_complete(
            send_user_reminder(sample_user_id)
        )

        assert result.success is True
        assert "john@example.com" in result.message

    def test_send_user_reminder_user_not_found(self, mock_supabase_db, mock_email_service, sample_user_id):
        """Test reminder for non-existent user."""
        from api.v1.reminders import send_user_reminder
        from fastapi import HTTPException
        import asyncio

        mock_supabase_db.get_user.return_value = None

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                send_user_reminder(sample_user_id)
            )

        assert exc_info.value.status_code == 404

    def test_send_user_reminder_no_workouts(self, mock_supabase_db, mock_email_service, sample_user, sample_user_id):
        """Test reminder when user has no workouts scheduled."""
        from api.v1.reminders import send_user_reminder
        import asyncio

        mock_supabase_db.get_user.return_value = sample_user
        mock_supabase_db.list_current_workouts.return_value = []

        result = asyncio.get_event_loop().run_until_complete(
            send_user_reminder(sample_user_id)
        )

        assert result.success is False
        assert "No workouts scheduled" in result.message

    def test_send_user_reminder_no_email(self, mock_supabase_db, mock_email_service, sample_workout, sample_user_id):
        """Test reminder when user has no email configured."""
        from api.v1.reminders import send_user_reminder
        from fastapi import HTTPException
        import asyncio

        user_no_email = {"id": sample_user_id, "name": "No Email", "preferences": {}}
        mock_supabase_db.get_user.return_value = user_no_email
        mock_supabase_db.list_current_workouts.return_value = [sample_workout]

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                send_user_reminder(sample_user_id)
            )

        assert exc_info.value.status_code == 400

    def test_send_user_reminder_email_failure(self, mock_supabase_db, mock_email_service, sample_user, sample_workout, sample_user_id):
        """Test handling email send failure."""
        from api.v1.reminders import send_user_reminder
        from fastapi import HTTPException
        import asyncio

        mock_supabase_db.get_user.return_value = sample_user
        mock_supabase_db.list_current_workouts.return_value = [sample_workout]
        mock_email_service.send_workout_reminder = AsyncMock(
            return_value={"success": False, "error": "SMTP error"}
        )

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                send_user_reminder(sample_user_id)
            )

        assert exc_info.value.status_code == 500


# ============================================================
# SEND TEST REMINDER TESTS
# ============================================================

class TestSendTestReminder:
    """Test test reminder endpoint."""

    def test_send_test_reminder_success(self, mock_email_service):
        """Test successful test reminder."""
        from api.v1.reminders import send_test_reminder
        import asyncio

        result = asyncio.get_event_loop().run_until_complete(
            send_test_reminder("test@example.com")
        )

        assert result["success"] is True
        assert result["email_id"] == "email-123"

    def test_send_test_reminder_not_configured(self, mock_email_service):
        """Test test reminder when email not configured."""
        from api.v1.reminders import send_test_reminder
        from fastapi import HTTPException
        import asyncio

        mock_email_service.is_configured.return_value = False

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                send_test_reminder("test@example.com")
            )

        assert exc_info.value.status_code == 503

    def test_send_test_reminder_failure(self, mock_email_service):
        """Test test reminder failure."""
        from api.v1.reminders import send_test_reminder
        from fastapi import HTTPException
        import asyncio

        mock_email_service.send_workout_reminder = AsyncMock(
            return_value={"success": False, "error": "Invalid email"}
        )

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                send_test_reminder("invalid-email")
            )

        assert exc_info.value.status_code == 500


# ============================================================
# MODEL VALIDATION TESTS
# ============================================================

class TestReminderModels:
    """Test Pydantic model validation."""

    def test_reminder_response_model(self):
        """Test ReminderResponse model."""
        from api.v1.reminders import ReminderResponse

        response = ReminderResponse(
            success=True,
            sent_count=5,
            failed_count=1,
            details=[
                {"user_id": "user-1", "success": True},
                {"user_id": "user-2", "success": False, "error": "No email"},
            ]
        )

        assert response.success is True
        assert response.sent_count == 5

    def test_single_reminder_response_model(self):
        """Test SingleReminderResponse model."""
        from api.v1.reminders import SingleReminderResponse

        response = SingleReminderResponse(
            success=True,
            message="Reminder sent",
            email_id="email-123"
        )

        assert response.success is True
        assert response.email_id == "email-123"


# ============================================================
# EDGE CASES
# ============================================================

class TestEdgeCases:
    """Test edge cases and special scenarios."""

    def test_preferences_as_string(self, mock_supabase_db, mock_email_service, sample_workout, sample_user_id):
        """Test handling preferences stored as JSON string."""
        from api.v1.reminders import send_user_reminder
        import asyncio
        import json

        user_with_string_prefs = {
            "id": sample_user_id,
            "name": "String Prefs User",
            "preferences": json.dumps({"email": "string@example.com", "name": "String"}),
        }
        mock_supabase_db.get_user.return_value = user_with_string_prefs
        mock_supabase_db.list_current_workouts.return_value = [sample_workout]

        result = asyncio.get_event_loop().run_until_complete(
            send_user_reminder(sample_user_id)
        )

        assert result.success is True

    def test_exercises_as_list(self, mock_supabase_db, mock_email_service, sample_user, sample_user_id):
        """Test handling exercises_json as list instead of string."""
        from api.v1.reminders import send_user_reminder
        import asyncio

        workout_with_list = {
            "id": "workout-1",
            "name": "List Exercises Workout",
            "type": "strength",
            "exercises_json": [{"name": "Squat", "sets": 5, "reps": 5}],
        }
        mock_supabase_db.get_user.return_value = sample_user
        mock_supabase_db.list_current_workouts.return_value = [workout_with_list]

        result = asyncio.get_event_loop().run_until_complete(
            send_user_reminder(sample_user_id)
        )

        assert result.success is True

    def test_malformed_exercises_json(self, mock_supabase_db, mock_email_service, sample_user, sample_user_id):
        """Test handling malformed exercises_json."""
        from api.v1.reminders import send_user_reminder
        import asyncio

        workout_with_bad_json = {
            "id": "workout-1",
            "name": "Bad JSON Workout",
            "type": "strength",
            "exercises_json": "not valid json {",
        }
        mock_supabase_db.get_user.return_value = sample_user
        mock_supabase_db.list_current_workouts.return_value = [workout_with_bad_json]

        # Should still send reminder with empty exercises
        result = asyncio.get_event_loop().run_until_complete(
            send_user_reminder(sample_user_id)
        )

        assert result.success is True


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
