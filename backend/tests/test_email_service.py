"""
Tests for EmailService — the send methods that build the Resend payload.

WHAT THIS FILE GUARDS
---------------------
The payload regression gate: subject line, HTML body, recipient. Every send now
routes through the ONE chokepoint `services.email_sender.send`, so the mock is
installed at `services.email_sender.resend` — NOT at `services.email_service.resend`,
which no longer exists (email_service.py imports `email_sender`, never `resend`).
Patching the old target raised AttributeError at fixture setup and silently killed
every assertion in this file.

Two consequences of the chokepoint that this file also locks down:
  * Recipients must be DELIVERABLE. `example.com` is a reserved TLD in
    `email_sender.UNDELIVERABLE_TLDS`, so a test that sends to `user@example.com`
    is blocked before Resend is reached and asserts nothing. Tests send to
    `@zealova.com`; the undeliverable path gets its own explicit test.
  * A blocked send is NORMAL CONTROL FLOW: it returns
    {"success": False, "skipped": True, "reason": ...} and never raises.

Cap semantics live in tests/test_email_frequency_cap.py; the domain guard in
tests/test_email_sender_guard.py. This file owns the message content.

Run with: pytest backend/tests/test_email_service.py -v
"""
from __future__ import annotations

import asyncio
from datetime import date
from unittest.mock import MagicMock, patch

import pytest

from models.email import UserStats
from services import email_sender
from services.cardio_digest_service import WeeklyCardioSummary
from services.weekly_progress_service import Award, Tile, WeeklyProgress


TO = "user@zealova.com"          # deliverable — a reserved TLD would be blocked
TO_UNDELIVERABLE = "harness@zealova.invalid"


def run(coro):
    """Drive one async send. (asyncio.get_event_loop() is deprecated on 3.12.)"""
    return asyncio.run(coro)


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture(autouse=True)
def _clean_sender_state():
    """The chokepoint keeps an in-process frequency ledger — never leak it."""
    email_sender.reset_state()
    yield
    email_sender.reset_state()


@pytest.fixture
def mock_resend():
    """Mock the resend module AS SEEN BY THE CHOKEPOINT.

    `services/email_sender.py` does `import resend` and calls
    `resend.Emails.send(params)` by attribute lookup at call time, so patching the
    module object here intercepts every send in the backend. The MagicMock's
    truthy `.api_key` also satisfies the chokepoint's `_configured()` check.
    """
    with patch("services.email_sender.resend") as mock:
        mock.api_key = "test-api-key"
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


@pytest.fixture
def stats():
    """Personalization payload every send method takes."""
    return UserStats(coach_name="Coach Max")


def sent_payload(mock_resend):
    """The exact dict handed to Resend."""
    return mock_resend.Emails.send.call_args[0][0]


def make_progress(**overrides) -> WeeklyProgress:
    base = dict(
        week_label="Jan 6 – 12",
        has_wearable=False,
        is_first_week=False,
        empty_week=False,
        total_steps=0,
        avg_steps=0,
        day_steps=[(d, None) for d in ("M", "T", "W", "T", "F", "S", "S")],
        workouts_this_week=5,
        workouts_subline="5 of 7 sessions done",
        activity_tiles=[],
        zealova_tiles=[Tile(icon="dumbbell", value="8,500 lbs", label="Volume", delta="")],
        awards=[Award(icon="medal", title="Best week yet", detail="5 sessions")],
    )
    base.update(overrides)
    return WeeklyProgress(**base)


def make_cardio() -> WeeklyCardioSummary:
    return WeeklyCardioSummary(
        km_this_week=21.5,
        km_last_week=18.0,
        delta_pct=19.4,
        longest_run_km=10.0,
        longest_run_date=date(2025, 1, 11),
        fastest_mile_sec=445.0,
        fastest_mile_date=date(2025, 1, 9),
        total_hours=2.4,
        session_count=3,
        is_first_week=False,
    )


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

    def test_send_workout_reminder_success(self, email_service_configured, mock_resend, stats):
        """Test successful workout reminder."""
        result = run(
            email_service_configured.send_workout_reminder(
                to_email=TO,
                first_name_value="John",
                stats=stats,
                workout_name="Upper Body Strength",
                workout_type="strength",
                scheduled_date=date(2025, 1, 15),
                exercises=[
                    {"name": "Bench Press", "sets": 4, "reps": 8},
                    {"name": "Shoulder Press", "sets": 3, "reps": 10},
                ],
            )
        )

        assert result["success"] is True
        assert result["id"] == "email-abc123"
        mock_resend.Emails.send.assert_called_once()
        assert sent_payload(mock_resend)["to"] == [TO]

    def test_send_workout_reminder_not_configured(self, email_service_unconfigured, stats):
        """Test workout reminder when service not configured."""
        result = run(
            email_service_unconfigured.send_workout_reminder(
                to_email=TO,
                first_name_value="John",
                stats=stats,
                workout_name="Test Workout",
                workout_type="strength",
                scheduled_date=date(2025, 1, 15),
                exercises=[],
            )
        )

        assert "error" in result

    def test_send_workout_reminder_many_exercises(self, email_service_configured, mock_resend, stats):
        """Test workout reminder with many exercises (preview shows 3 + an overflow row)."""
        exercises = [{"name": f"Exercise {i}", "sets": 3, "reps": 10} for i in range(15)]

        result = run(
            email_service_configured.send_workout_reminder(
                to_email=TO,
                first_name_value="John",
                stats=stats,
                workout_name="Full Body",
                workout_type="full_body",
                scheduled_date=date(2025, 1, 15),
                exercises=exercises,
            )
        )

        assert result["success"] is True

        html = sent_payload(mock_resend)["html"]
        assert "+12 more exercises" in html          # 15 - 3 previewed
        assert "Exercise 14" not in html             # the tail is NOT dumped into the email

    def test_send_workout_reminder_email_error(self, email_service_configured, mock_resend, stats):
        """Test workout reminder when the Resend call raises."""
        mock_resend.Emails.send.side_effect = Exception("SMTP Error")

        result = run(
            email_service_configured.send_workout_reminder(
                to_email=TO,
                first_name_value="John",
                stats=stats,
                workout_name="Test Workout",
                workout_type="strength",
                scheduled_date=date(2025, 1, 15),
                exercises=[],
            )
        )

        assert "error" in result
        assert result["error"] == "SMTP Error"

    def test_send_workout_reminder_no_user_name(self, email_service_configured, mock_resend, stats):
        """Test workout reminder without user name falls back to 'there'."""
        result = run(
            email_service_configured.send_workout_reminder(
                to_email=TO,
                first_name_value=None,
                stats=stats,
                workout_name="Test Workout",
                workout_type="strength",
                scheduled_date=date(2025, 1, 15),
                exercises=[],
            )
        )

        assert result["success"] is True

        payload = sent_payload(mock_resend)
        assert "Test Workout, there" in payload["html"]      # title = f"{workout}, {name}"
        assert payload["subject"].startswith("there.")


# ============================================================
# CHOKEPOINT TESTS — undeliverable recipients never reach Resend
# ============================================================

class TestUndeliverableRecipient:
    """A harness address must be blocked BEFORE Resend (SES bounce reputation)."""

    def test_workout_reminder_to_invalid_domain_is_skipped(
        self, email_service_configured, mock_resend, stats
    ):
        result = run(
            email_service_configured.send_workout_reminder(
                to_email=TO_UNDELIVERABLE,
                first_name_value="Harness",
                stats=stats,
                workout_name="Test Workout",
                workout_type="strength",
                scheduled_date=date(2025, 1, 15),
                exercises=[],
            )
        )

        mock_resend.Emails.send.assert_not_called()         # nothing left the building
        assert result["success"] is False                    # → no email_send_log row
        assert result["skipped"] is True
        assert result["reason"] == "undeliverable_domain"
        assert result["id"] is None
        assert "error" not in result                         # a block is not an error

    def test_weekly_summary_to_invalid_domain_is_skipped(
        self, email_service_configured, mock_resend, stats
    ):
        result = run(
            email_service_configured.send_weekly_summary(
                to_email=TO_UNDELIVERABLE,
                first_name_value="Harness",
                stats=stats,
                progress=make_progress(),
            )
        )

        mock_resend.Emails.send.assert_not_called()
        assert result["skipped"] is True
        assert result["reason"] == "undeliverable_domain"


# ============================================================
# WEEKLY SUMMARY TESTS
# ============================================================

class TestWeeklySummary:
    """Test weekly summary emails."""

    def test_send_weekly_summary_success(self, email_service_configured, mock_resend, stats):
        """Test successful weekly summary."""
        result = run(
            email_service_configured.send_weekly_summary(
                to_email=TO,
                first_name_value="John",
                stats=stats,
                progress=make_progress(),
            )
        )

        assert result["success"] is True
        assert result["id"] == "email-abc123"
        assert sent_payload(mock_resend)["to"] == [TO]

    def test_send_weekly_summary_not_configured(self, email_service_unconfigured, stats):
        """Test weekly summary when service not configured."""
        result = run(
            email_service_unconfigured.send_weekly_summary(
                to_email=TO,
                first_name_value="John",
                stats=stats,
                progress=make_progress(),
            )
        )

        assert "error" in result

    def test_send_weekly_summary_without_progress(self, email_service_configured, mock_resend, stats):
        """No WeeklyProgress → minimal coach check-in, never a crash."""
        result = run(
            email_service_configured.send_weekly_summary(
                to_email=TO,
                first_name_value="John",
                stats=stats,
                progress=None,
            )
        )

        assert result["success"] is True
        payload = sent_payload(mock_resend)
        assert "John" in payload["subject"]
        assert "Coach Max" in payload["html"]

    def test_send_weekly_summary_empty_week(self, email_service_configured, mock_resend, stats):
        """A zero-activity week still renders (no division-by-zero, no crash)."""
        result = run(
            email_service_configured.send_weekly_summary(
                to_email=TO,
                first_name_value="John",
                stats=stats,
                progress=make_progress(
                    empty_week=True, workouts_this_week=0, workouts_subline="",
                    zealova_tiles=[], awards=[],
                ),
            )
        )

        assert result["success"] is True

    def test_send_weekly_summary_email_error(self, email_service_configured, mock_resend, stats):
        """Test weekly summary when the Resend call raises."""
        mock_resend.Emails.send.side_effect = Exception("Connection Error")

        result = run(
            email_service_configured.send_weekly_summary(
                to_email=TO,
                first_name_value="John",
                stats=stats,
                progress=make_progress(),
            )
        )

        assert "error" in result


# ============================================================
# CARDIO MERGE — the Sunday digest now lives INSIDE the Monday summary
# ============================================================

class TestWeeklySummaryCardioMerge:
    """`cardio=` renders a band in the ONE Monday recap. Absent → zero visual diff."""

    def test_cardio_section_rendered_when_cardio_present(
        self, email_service_configured, mock_resend, stats
    ):
        result = run(
            email_service_configured.send_weekly_summary(
                to_email=TO,
                first_name_value="John",
                stats=stats,
                progress=make_progress(),
                cardio=make_cardio(),
            )
        )

        assert result["success"] is True
        html = sent_payload(mock_resend)["html"]
        assert "Your cardio week" in html
        assert "21.5 km" in html                 # distance tile
        assert "10 km" in html                   # longest run tile

    def test_no_cardio_section_when_cardio_is_none(
        self, email_service_configured, mock_resend, stats
    ):
        run(
            email_service_configured.send_weekly_summary(
                to_email=TO,
                first_name_value="John",
                stats=stats,
                progress=make_progress(),
                cardio=None,
            )
        )

        html = sent_payload(mock_resend)["html"]
        assert "Your cardio week" not in html

    def test_cardio_is_optional_kwarg(self, email_service_configured, mock_resend, stats):
        """Backward compat: callers that never heard of cardio still work."""
        result = run(
            email_service_configured.send_weekly_summary(
                to_email=TO,
                first_name_value="John",
                stats=stats,
                progress=make_progress(),
            )
        )

        assert result["success"] is True
        assert "Your cardio week" not in sent_payload(mock_resend)["html"]


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

    def test_workout_reminder_subject_format(self, email_service_configured, mock_resend, stats):
        """Subject = "{name}. {workout}. {weekday, month day}." """
        run(
            email_service_configured.send_workout_reminder(
                to_email=TO,
                first_name_value="John",
                stats=stats,
                workout_name="Upper Body",
                workout_type="strength",
                scheduled_date=date(2025, 1, 15),
                exercises=[],
            )
        )

        subject = sent_payload(mock_resend)["subject"]
        assert "John" in subject
        assert "Upper Body" in subject
        assert "Wednesday, January 15" in subject

    def test_workout_reminder_html_structure(self, email_service_configured, mock_resend, stats):
        """Test workout reminder HTML contains expected elements."""
        run(
            email_service_configured.send_workout_reminder(
                to_email=TO,
                first_name_value="TestUser",
                stats=stats,
                workout_name="Leg Day",
                workout_type="legs",
                scheduled_date=date(2025, 1, 15),
                exercises=[{"name": "Squat", "sets": 5, "reps": 5}],
            )
        )

        html = sent_payload(mock_resend)["html"]

        assert "TestUser" in html
        assert "Leg Day" in html
        assert "Squat" in html
        assert "5 sets × 5 reps" in html
        assert "Coach Max" in html

    def test_weekly_summary_html_structure(self, email_service_configured, mock_resend, stats):
        """Test weekly summary HTML contains expected elements."""
        run(
            email_service_configured.send_weekly_summary(
                to_email=TO,
                first_name_value="Champion",
                stats=stats,
                progress=make_progress(),
            )
        )

        html = sent_payload(mock_resend)["html"]

        assert "Champion" in html
        assert "Jan 6 – 12" in html          # week label
        assert "8,500 lbs" in html           # zealova tile
        assert "Best week yet" in html       # award band


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
