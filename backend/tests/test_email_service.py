"""
Tests for Email Service.

Tests:
- Service configuration
- Workout reminder emails
- Weekly summary emails

Run with: pytest backend/tests/test_email_service.py -v
"""

import pytest
from unittest.mock import MagicMock, patch, AsyncMock
from datetime import date


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def mock_resend():
    """Mock resend module."""
    with patch("services.email_service.resend") as mock:
        mock.Emails = MagicMock()
        mock.Emails.send = MagicMock(return_value={"id": "email-abc123"})
        yield mock


@pytest.fixture
def email_service_configured(mock_resend):
    """Create configured email service."""
    with patch.dict("os.environ", {"RESEND_API_KEY": "test-api-key"}):
        from services.email_service import EmailService
        service = EmailService()
        yield service


@pytest.fixture
def email_service_unconfigured():
    """Create unconfigured email service."""
    with patch.dict("os.environ", {}, clear=True):
        from services.email_service import EmailService
        service = EmailService()
        yield service


# ============================================================
# CONFIGURATION TESTS
# ============================================================

class TestEmailServiceConfiguration:
    """Test email service configuration."""

    def test_is_configured_with_api_key(self, email_service_configured):
        """Test is_configured returns True when API key is set."""
        assert email_service_configured.is_configured() is True

    def test_is_configured_without_api_key(self, email_service_unconfigured):
        """Test is_configured returns False when API key is not set."""
        assert email_service_unconfigured.is_configured() is False

    def test_default_from_email(self, email_service_configured):
        """Test default from email is set."""
        assert email_service_configured.from_email is not None
        assert "@" in email_service_configured.from_email


# ============================================================
# WORKOUT REMINDER TESTS
# ============================================================

class TestWorkoutReminder:
    """Test workout reminder emails."""

    def test_send_workout_reminder_success(self, email_service_configured, mock_resend):
        """Test successful workout reminder."""
        import asyncio

        result = asyncio.get_event_loop().run_until_complete(
            email_service_configured.send_workout_reminder(
                to_email="user@example.com",
                user_name="John",
                workout_name="Upper Body Strength",
                workout_type="strength",
                scheduled_date=date(2025, 1, 15),
                exercises=[
                    {"name": "Bench Press", "sets": 4, "reps": 8},
                    {"name": "Shoulder Press", "sets": 3, "reps": 10},
                ]
            )
        )

        assert result["success"] is True
        assert result["id"] == "email-abc123"
        mock_resend.Emails.send.assert_called_once()

    def test_send_workout_reminder_not_configured(self, email_service_unconfigured):
        """Test workout reminder when service not configured."""
        import asyncio

        result = asyncio.get_event_loop().run_until_complete(
            email_service_unconfigured.send_workout_reminder(
                to_email="user@example.com",
                user_name="John",
                workout_name="Test Workout",
                workout_type="strength",
                scheduled_date=date(2025, 1, 15),
                exercises=[]
            )
        )

        assert "error" in result

    def test_send_workout_reminder_many_exercises(self, email_service_configured, mock_resend):
        """Test workout reminder with many exercises (should limit to 8)."""
        import asyncio

        exercises = [{"name": f"Exercise {i}", "sets": 3, "reps": 10} for i in range(15)]

        result = asyncio.get_event_loop().run_until_complete(
            email_service_configured.send_workout_reminder(
                to_email="user@example.com",
                user_name="John",
                workout_name="Full Body",
                workout_type="full_body",
                scheduled_date=date(2025, 1, 15),
                exercises=exercises
            )
        )

        assert result["success"] is True

        # Check that HTML contains "and X more exercises"
        call_args = mock_resend.Emails.send.call_args[0][0]
        assert "...and 7 more exercises" in call_args["html"]

    def test_send_workout_reminder_email_error(self, email_service_configured, mock_resend):
        """Test workout reminder when email send fails."""
        import asyncio

        mock_resend.Emails.send.side_effect = Exception("SMTP Error")

        result = asyncio.get_event_loop().run_until_complete(
            email_service_configured.send_workout_reminder(
                to_email="user@example.com",
                user_name="John",
                workout_name="Test Workout",
                workout_type="strength",
                scheduled_date=date(2025, 1, 15),
                exercises=[]
            )
        )

        assert "error" in result

    def test_send_workout_reminder_no_user_name(self, email_service_configured, mock_resend):
        """Test workout reminder without user name."""
        import asyncio

        result = asyncio.get_event_loop().run_until_complete(
            email_service_configured.send_workout_reminder(
                to_email="user@example.com",
                user_name=None,
                workout_name="Test Workout",
                workout_type="strength",
                scheduled_date=date(2025, 1, 15),
                exercises=[]
            )
        )

        assert result["success"] is True

        # Check that "there" is used instead of name
        call_args = mock_resend.Emails.send.call_args[0][0]
        assert "Hey there" in call_args["html"]


# ============================================================
# WEEKLY SUMMARY TESTS
# ============================================================

class TestWeeklySummary:
    """Test weekly summary emails."""

    def test_send_weekly_summary_success(self, email_service_configured, mock_resend):
        """Test successful weekly summary."""
        import asyncio

        result = asyncio.get_event_loop().run_until_complete(
            email_service_configured.send_weekly_summary(
                to_email="user@example.com",
                user_name="John",
                completed_workouts=4,
                total_workouts=5,
                total_volume_kg=5000.0,
                top_exercises=["Bench Press", "Squat", "Deadlift"]
            )
        )

        assert result["success"] is True
        assert result["id"] == "email-abc123"

    def test_send_weekly_summary_not_configured(self, email_service_unconfigured):
        """Test weekly summary when service not configured."""
        import asyncio

        result = asyncio.get_event_loop().run_until_complete(
            email_service_unconfigured.send_weekly_summary(
                to_email="user@example.com",
                user_name="John",
                completed_workouts=0,
                total_workouts=0,
                total_volume_kg=0,
                top_exercises=[]
            )
        )

        assert "error" in result

    def test_send_weekly_summary_zero_workouts(self, email_service_configured, mock_resend):
        """Test weekly summary with zero workouts (division by zero edge case)."""
        import asyncio

        result = asyncio.get_event_loop().run_until_complete(
            email_service_configured.send_weekly_summary(
                to_email="user@example.com",
                user_name="John",
                completed_workouts=0,
                total_workouts=0,
                total_volume_kg=0,
                top_exercises=[]
            )
        )

        assert result["success"] is True

    def test_send_weekly_summary_perfect_completion(self, email_service_configured, mock_resend):
        """Test weekly summary with 100% completion."""
        import asyncio

        result = asyncio.get_event_loop().run_until_complete(
            email_service_configured.send_weekly_summary(
                to_email="user@example.com",
                user_name="Champion",
                completed_workouts=7,
                total_workouts=7,
                total_volume_kg=10000.0,
                top_exercises=["Squat", "Bench Press", "Deadlift", "Pull-up", "Row"]
            )
        )

        assert result["success"] is True

        # Check completion rate is 100%
        call_args = mock_resend.Emails.send.call_args[0][0]
        assert "100%" in call_args["html"]

    def test_send_weekly_summary_email_error(self, email_service_configured, mock_resend):
        """Test weekly summary when email send fails."""
        import asyncio

        mock_resend.Emails.send.side_effect = Exception("Connection Error")

        result = asyncio.get_event_loop().run_until_complete(
            email_service_configured.send_weekly_summary(
                to_email="user@example.com",
                user_name="John",
                completed_workouts=3,
                total_workouts=5,
                total_volume_kg=3000.0,
                top_exercises=["Squat"]
            )
        )

        assert "error" in result


# ============================================================
# SINGLETON TESTS
# ============================================================

class TestEmailServiceSingleton:
    """Test email service singleton pattern."""

    def test_get_email_service_returns_same_instance(self, mock_resend):
        """Test that get_email_service returns singleton."""
        with patch.dict("os.environ", {"RESEND_API_KEY": "test-key"}):
            # Reset singleton
            import services.email_service as es
            es._email_service = None

            from services.email_service import get_email_service

            service1 = get_email_service()
            service2 = get_email_service()

            assert service1 is service2


# ============================================================
# EMAIL CONTENT TESTS
# ============================================================

class TestEmailContent:
    """Test email content formatting."""

    def test_workout_reminder_subject_format(self, email_service_configured, mock_resend):
        """Test workout reminder email subject format."""
        import asyncio

        asyncio.get_event_loop().run_until_complete(
            email_service_configured.send_workout_reminder(
                to_email="user@example.com",
                user_name="John",
                workout_name="Upper Body",
                workout_type="strength",
                scheduled_date=date(2025, 1, 15),
                exercises=[]
            )
        )

        call_args = mock_resend.Emails.send.call_args[0][0]
        assert "Upper Body" in call_args["subject"]
        assert "January" in call_args["subject"]
        assert "2025" in call_args["subject"]

    def test_workout_reminder_html_structure(self, email_service_configured, mock_resend):
        """Test workout reminder HTML contains expected elements."""
        import asyncio

        asyncio.get_event_loop().run_until_complete(
            email_service_configured.send_workout_reminder(
                to_email="user@example.com",
                user_name="TestUser",
                workout_name="Leg Day",
                workout_type="legs",
                scheduled_date=date(2025, 1, 15),
                exercises=[{"name": "Squat", "sets": 5, "reps": 5}]
            )
        )

        call_args = mock_resend.Emails.send.call_args[0][0]
        html = call_args["html"]

        assert "TestUser" in html
        assert "Leg Day" in html
        assert "Squat" in html
        assert "5 sets x 5 reps" in html
        assert "Time to Train!" in html

    def test_weekly_summary_html_structure(self, email_service_configured, mock_resend):
        """Test weekly summary HTML contains expected elements."""
        import asyncio

        asyncio.get_event_loop().run_until_complete(
            email_service_configured.send_weekly_summary(
                to_email="user@example.com",
                user_name="Champion",
                completed_workouts=5,
                total_workouts=7,
                total_volume_kg=8500.0,
                top_exercises=["Deadlift", "Bench Press"]
            )
        )

        call_args = mock_resend.Emails.send.call_args[0][0]
        html = call_args["html"]

        assert "Champion" in html
        assert "5/7" in html
        assert "8,500" in html
        assert "Deadlift" in html
        assert "Bench Press" in html


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
