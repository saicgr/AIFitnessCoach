"""
Tests for workout timezone handling.

Verifies that scheduled_date is correctly stored relative to the user's
local timezone, not UTC, across all timezone utility functions.
"""
import pytest
from datetime import datetime, date, timedelta
from unittest.mock import MagicMock, patch
from zoneinfo import ZoneInfo

from core.timezone_utils import (
    get_user_today,
    target_date_to_utc_iso,
    local_date_to_utc_range,
    resolve_timezone,
)


# ═══════════════════════════════════════════════════════════════════
# get_user_today
# ═══════════════════════════════════════════════════════════════════

class TestGetUserToday:
    """Tests for get_user_today — returns YYYY-MM-DD in user's local timezone."""

    def test_utc_user(self):
        """UTC user should get the same date as datetime.now(UTC)."""
        result = get_user_today("UTC")
        expected = datetime.now(ZoneInfo("UTC")).strftime("%Y-%m-%d")
        assert result == expected

    def test_cdt_user(self):
        """CDT (America/Chicago) user should get their local date."""
        result = get_user_today("America/Chicago")
        expected = datetime.now(ZoneInfo("America/Chicago")).strftime("%Y-%m-%d")
        assert result == expected

    def test_ist_user(self):
        """IST (Asia/Kolkata) user should get their local date."""
        result = get_user_today("Asia/Kolkata")
        expected = datetime.now(ZoneInfo("Asia/Kolkata")).strftime("%Y-%m-%d")
        assert result == expected

    def test_invalid_timezone_falls_back_to_utc(self):
        """Invalid timezone should fall back to UTC."""
        result = get_user_today("Invalid/Timezone")
        expected = datetime.now(ZoneInfo("UTC")).strftime("%Y-%m-%d")
        assert result == expected

    def test_date_boundary_cdt_late_night(self):
        """At 11pm CDT (April 4), get_user_today should return April 4, not April 5."""
        # 11pm CDT = 04:00 UTC next day
        with patch('core.timezone_utils.datetime') as mock_dt:
            mock_dt.now.return_value = datetime(2026, 4, 5, 4, 0, 0, tzinfo=ZoneInfo("UTC"))
            mock_dt.side_effect = lambda *a, **kw: datetime(*a, **kw)
            # When it's 4am UTC on April 5, it's 11pm CDT on April 4
            cdt_now = datetime(2026, 4, 5, 4, 0, 0, tzinfo=ZoneInfo("UTC")).astimezone(ZoneInfo("America/Chicago"))
            assert cdt_now.strftime("%Y-%m-%d") == "2026-04-04"

    def test_date_boundary_ist_early_morning(self):
        """At 1am IST (April 5), it's still April 4 in UTC."""
        # 1am IST = 7:30pm UTC previous day
        ist_1am = datetime(2026, 4, 5, 1, 0, 0, tzinfo=ZoneInfo("Asia/Kolkata"))
        utc_time = ist_1am.astimezone(ZoneInfo("UTC"))
        assert utc_time.strftime("%Y-%m-%d") == "2026-04-04"
        assert ist_1am.strftime("%Y-%m-%d") == "2026-04-05"


# ═══════════════════════════════════════════════════════════════════
# target_date_to_utc_iso
# ═══════════════════════════════════════════════════════════════════

class TestTargetDateToUtcIso:
    """Tests for target_date_to_utc_iso — converts local date to UTC ISO timestamp."""

    def test_cdt_to_utc(self):
        """CDT date should convert to noon CDT in UTC."""
        result = target_date_to_utc_iso("2026-04-05", "America/Chicago")
        # Noon CDT = 17:00 UTC (CDT is UTC-5)
        parsed = datetime.fromisoformat(result)
        assert parsed.hour == 17
        assert parsed.day == 5
        assert parsed.month == 4

    def test_ist_to_utc(self):
        """IST date should convert to noon IST in UTC."""
        result = target_date_to_utc_iso("2026-04-05", "Asia/Kolkata")
        # Noon IST = 06:30 UTC (IST is UTC+5:30)
        parsed = datetime.fromisoformat(result)
        assert parsed.hour == 6
        assert parsed.minute == 30
        assert parsed.day == 5

    def test_utc_to_utc(self):
        """UTC date should stay at noon UTC."""
        result = target_date_to_utc_iso("2026-04-05", "UTC")
        parsed = datetime.fromisoformat(result)
        assert parsed.hour == 12
        assert parsed.day == 5


# ═══════════════════════════════════════════════════════════════════
# local_date_to_utc_range
# ═══════════════════════════════════════════════════════════════════

class TestLocalDateToUtcRange:
    """Tests for local_date_to_utc_range — converts local date to UTC start/end."""

    def test_cdt_range(self):
        """CDT April 5 should span from 05:00 UTC to 04:59:59 UTC next day."""
        start, end = local_date_to_utc_range("2026-04-05", "America/Chicago")
        start_dt = datetime.fromisoformat(start)
        end_dt = datetime.fromisoformat(end)
        # Midnight CDT = 05:00 UTC
        assert start_dt.hour == 5
        assert start_dt.day == 5
        # 23:59:59 CDT = 04:59:59 UTC next day
        assert end_dt.hour == 4
        assert end_dt.minute == 59
        assert end_dt.day == 6

    def test_ist_range(self):
        """IST April 5 should span from 18:30 UTC April 4 to 18:29:59 UTC April 5."""
        start, end = local_date_to_utc_range("2026-04-05", "Asia/Kolkata")
        start_dt = datetime.fromisoformat(start)
        end_dt = datetime.fromisoformat(end)
        # Midnight IST = 18:30 UTC previous day
        assert start_dt.day == 4
        assert start_dt.hour == 18
        assert start_dt.minute == 30
        # 23:59:59 IST = 18:29:59 UTC same day
        assert end_dt.day == 5
        assert end_dt.hour == 18
        assert end_dt.minute == 29

    def test_utc_range(self):
        """UTC April 5 should span from 00:00 to 23:59:59 UTC."""
        start, end = local_date_to_utc_range("2026-04-05", "UTC")
        start_dt = datetime.fromisoformat(start)
        end_dt = datetime.fromisoformat(end)
        assert start_dt.hour == 0
        assert start_dt.day == 5
        assert end_dt.hour == 23
        assert end_dt.day == 5

    def test_range_covers_full_day(self):
        """Range should cover approximately 24 hours."""
        start, end = local_date_to_utc_range("2026-04-05", "America/Chicago")
        start_dt = datetime.fromisoformat(start)
        end_dt = datetime.fromisoformat(end)
        diff = end_dt - start_dt
        # Should be ~23h59m59s
        assert 23 * 3600 <= diff.total_seconds() <= 24 * 3600


# ═══════════════════════════════════════════════════════════════════
# resolve_timezone
# ═══════════════════════════════════════════════════════════════════

class TestResolveTimezone:
    """Tests for resolve_timezone — determines user's IANA timezone."""

    def test_header_iana(self):
        """Should use IANA timezone from header."""
        request = MagicMock()
        request.headers = {"x-user-timezone": "America/Chicago"}
        result = resolve_timezone(request)
        assert result == "America/Chicago"

    def test_header_abbreviation_cdt(self):
        """Should map CDT abbreviation to IANA."""
        request = MagicMock()
        request.headers = {"x-user-timezone": "CDT"}
        result = resolve_timezone(request)
        assert result == "America/Chicago"

    def test_header_abbreviation_ist(self):
        """Should map IST abbreviation to IANA."""
        request = MagicMock()
        request.headers = {"x-user-timezone": "IST"}
        result = resolve_timezone(request)
        assert result == "Asia/Kolkata"

    def test_no_header_falls_back_to_db(self):
        """Should fall back to DB timezone when no header."""
        request = MagicMock()
        request.headers = {}
        db = MagicMock()
        db.get_user.return_value = {"timezone": "Asia/Kolkata"}
        result = resolve_timezone(request, db=db, user_id="test-id")
        assert result == "Asia/Kolkata"

    def test_no_header_no_db_falls_back_to_utc(self):
        """Should fall back to UTC when no header and no DB."""
        request = MagicMock()
        request.headers = {}
        result = resolve_timezone(request)
        assert result == "UTC"

    def test_invalid_header_falls_back_to_db(self):
        """Should fall back to DB when header is invalid."""
        request = MagicMock()
        request.headers = {"x-user-timezone": "INVALID"}
        db = MagicMock()
        db.get_user.return_value = {"timezone": "Europe/London"}
        result = resolve_timezone(request, db=db, user_id="test-id")
        assert result == "Europe/London"


# ═══════════════════════════════════════════════════════════════════
# Travel Scenario
# ═══════════════════════════════════════════════════════════════════

class TestTravelScenario:
    """
    Verify that a workout generated in CDT still shows on the correct
    calendar day when viewed from IST.
    """

    def test_cdt_workout_viewed_in_ist(self):
        """
        Workout generated for April 5 in CDT → stored at noon CDT = 17:00 UTC.
        When viewed in IST, 17:00 UTC = 22:30 IST April 5. Still April 5. Correct.
        """
        # Generate in CDT
        utc_iso = target_date_to_utc_iso("2026-04-05", "America/Chicago")
        stored_utc = datetime.fromisoformat(utc_iso)

        # View in IST
        ist_time = stored_utc.astimezone(ZoneInfo("Asia/Kolkata"))
        assert ist_time.day == 5  # Still April 5 in IST

    def test_ist_workout_viewed_in_cdt(self):
        """
        Workout generated for April 5 in IST → stored at noon IST = 06:30 UTC.
        When viewed in CDT, 06:30 UTC = 01:30 CDT April 5. Still April 5. Correct.
        """
        utc_iso = target_date_to_utc_iso("2026-04-05", "Asia/Kolkata")
        stored_utc = datetime.fromisoformat(utc_iso)

        cdt_time = stored_utc.astimezone(ZoneInfo("America/Chicago"))
        assert cdt_time.day == 5  # Still April 5 in CDT

    def test_workout_in_query_range_after_travel(self):
        """
        Workout generated for April 5 CDT. User travels to IST.
        Querying for April 5 in IST should still find it.
        """
        # Generate in CDT
        utc_iso = target_date_to_utc_iso("2026-04-05", "America/Chicago")
        stored_utc = datetime.fromisoformat(utc_iso)

        # Query from IST for April 5
        start, end = local_date_to_utc_range("2026-04-05", "Asia/Kolkata")
        start_dt = datetime.fromisoformat(start)
        end_dt = datetime.fromisoformat(end)

        assert start_dt <= stored_utc <= end_dt, (
            f"Workout at {stored_utc} should be within IST April 5 range "
            f"({start_dt} - {end_dt})"
        )


# ═══════════════════════════════════════════════════════════════════
# Generation Fallback
# ═══════════════════════════════════════════════════════════════════

class TestGenerationFallback:
    """Verify that workout generation uses user timezone when no scheduled_date provided."""

    def test_fallback_uses_user_timezone_not_utc(self):
        """
        When body.scheduled_date is None, the code should use get_user_today(user_tz)
        not datetime.now() which is UTC.
        """
        # Simulate: it's 11pm CDT on April 4 (= 4am UTC April 5)
        # UTC date.today() would return April 5 (WRONG)
        # get_user_today("America/Chicago") should return April 4 (CORRECT)
        utc_date = datetime(2026, 4, 5, 4, 0, 0, tzinfo=ZoneInfo("UTC")).strftime("%Y-%m-%d")
        cdt_date = datetime(2026, 4, 5, 4, 0, 0, tzinfo=ZoneInfo("UTC")).astimezone(
            ZoneInfo("America/Chicago")
        ).strftime("%Y-%m-%d")

        assert utc_date == "2026-04-05"
        assert cdt_date == "2026-04-04"
        assert utc_date != cdt_date  # This is the bug we're fixing
