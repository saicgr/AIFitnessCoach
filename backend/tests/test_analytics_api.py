"""
Tests for Analytics API endpoints.

Tests:
- Session management (start/end)
- Screen view tracking
- Event tracking
- Funnel events
- Onboarding analytics
- Error tracking
- Batch upload
- Summary and screen time endpoints

Run with: pytest backend/tests/test_analytics_api.py -v
"""

import pytest
from unittest.mock import MagicMock, patch
from datetime import datetime, date


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def mock_supabase_client():
    """Mock Supabase client for analytics operations."""
    with patch("api.v1.analytics.get_supabase") as mock_get_supabase:
        mock_supabase = MagicMock()
        mock_client = MagicMock()
        mock_supabase.client = mock_client
        mock_get_supabase.return_value = mock_supabase
        yield mock_client


@pytest.fixture
def sample_user_id():
    return "user-123-abc"


@pytest.fixture
def sample_session_id():
    return "session-abc-123"


# ============================================================
# SESSION START TESTS
# ============================================================

class TestSessionStart:
    """Test session start endpoint."""

    def test_start_session_success(self, mock_supabase_client, sample_user_id):
        """Test successful session start."""
        from api.v1.analytics import start_session, SessionStartRequest
        import asyncio

        mock_supabase_client.table.return_value.insert.return_value.execute.return_value = MagicMock()

        # Mock daily stats query for _increment_daily_sessions
        mock_supabase_client.table.return_value.select.return_value.eq.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(data=None)

        request = SessionStartRequest(
            user_id=sample_user_id,
            device_type="ios",
            app_version="1.0.0",
            entry_point="app_launch"
        )

        result = asyncio.get_event_loop().run_until_complete(
            start_session(request)
        )

        assert "session_id" in result
        assert "started_at" in result

    def test_start_session_anonymous(self, mock_supabase_client):
        """Test session start with anonymous user."""
        from api.v1.analytics import start_session, SessionStartRequest
        import asyncio

        mock_supabase_client.table.return_value.insert.return_value.execute.return_value = MagicMock()

        request = SessionStartRequest(
            anonymous_id="anon-123",
            device_type="android"
        )

        result = asyncio.get_event_loop().run_until_complete(
            start_session(request)
        )

        assert "session_id" in result

    def test_start_session_error(self, mock_supabase_client, sample_user_id):
        """Test session start error handling."""
        from api.v1.analytics import start_session, SessionStartRequest
        from fastapi import HTTPException
        import asyncio

        mock_supabase_client.table.return_value.insert.return_value.execute.side_effect = Exception("Database error")

        request = SessionStartRequest(user_id=sample_user_id)

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                start_session(request)
            )

        assert exc_info.value.status_code == 500


# ============================================================
# SESSION END TESTS
# ============================================================

class TestSessionEnd:
    """Test session end endpoint."""

    def test_end_session_success(self, mock_supabase_client, sample_session_id):
        """Test successful session end."""
        from api.v1.analytics import end_session, SessionEndRequest
        import asyncio

        mock_result = MagicMock()
        mock_result.data = [{"session_id": sample_session_id}]
        mock_supabase_client.table.return_value.update.return_value.eq.return_value.execute.return_value = mock_result

        request = SessionEndRequest(session_id=sample_session_id)

        result = asyncio.get_event_loop().run_until_complete(
            end_session(request)
        )

        assert result["status"] == "ended"

    def test_end_session_not_found(self, mock_supabase_client, sample_session_id):
        """Test ending non-existent session."""
        from api.v1.analytics import end_session, SessionEndRequest
        import asyncio

        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase_client.table.return_value.update.return_value.eq.return_value.execute.return_value = mock_result

        request = SessionEndRequest(session_id="nonexistent")

        result = asyncio.get_event_loop().run_until_complete(
            end_session(request)
        )

        assert result["status"] == "not_found"


# ============================================================
# SCREEN VIEW TESTS
# ============================================================

class TestScreenView:
    """Test screen view tracking endpoint."""

    def test_track_screen_view_success(self, mock_supabase_client, sample_user_id, sample_session_id):
        """Test successful screen view tracking."""
        from api.v1.analytics import track_screen_view, ScreenViewRequest
        import asyncio

        mock_result = MagicMock()
        mock_result.data = [{"id": "sv-123"}]
        mock_supabase_client.table.return_value.insert.return_value.execute.return_value = mock_result

        request = ScreenViewRequest(
            user_id=sample_user_id,
            session_id=sample_session_id,
            screen_name="home",
            previous_screen="splash"
        )

        result = asyncio.get_event_loop().run_until_complete(
            track_screen_view(request)
        )

        assert result["tracked"] is True
        assert result["screen_view_id"] == "sv-123"

    def test_track_screen_view_error(self, mock_supabase_client, sample_session_id):
        """Test screen view tracking error handling."""
        from api.v1.analytics import track_screen_view, ScreenViewRequest
        import asyncio

        mock_supabase_client.table.return_value.insert.return_value.execute.side_effect = Exception("Insert failed")

        request = ScreenViewRequest(
            session_id=sample_session_id,
            screen_name="home"
        )

        result = asyncio.get_event_loop().run_until_complete(
            track_screen_view(request)
        )

        # Should not raise, but return tracked=False
        assert result["tracked"] is False


# ============================================================
# SCREEN EXIT TESTS
# ============================================================

class TestScreenExit:
    """Test screen exit tracking endpoint."""

    def test_track_screen_exit_success(self, mock_supabase_client):
        """Test successful screen exit tracking."""
        from api.v1.analytics import track_screen_exit, ScreenExitRequest
        import asyncio

        mock_supabase_client.table.return_value.update.return_value.eq.return_value.execute.return_value = MagicMock()

        request = ScreenExitRequest(
            screen_view_id="sv-123",
            duration_ms=5000,
            scroll_depth_percent=75,
            interactions_count=3
        )

        result = asyncio.get_event_loop().run_until_complete(
            track_screen_exit(request)
        )

        assert result["tracked"] is True


# ============================================================
# EVENT TRACKING TESTS
# ============================================================

class TestEventTracking:
    """Test custom event tracking endpoint."""

    def test_track_event_success(self, mock_supabase_client, sample_user_id, sample_session_id):
        """Test successful event tracking."""
        from api.v1.analytics import track_event, EventRequest
        import asyncio

        mock_supabase_client.table.return_value.insert.return_value.execute.return_value = MagicMock()

        # Mock daily stats for _track_daily_event
        mock_supabase_client.table.return_value.select.return_value.eq.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(data=None)

        request = EventRequest(
            user_id=sample_user_id,
            session_id=sample_session_id,
            event_name="button_click",
            event_category="interaction",
            properties={"button_id": "start_workout"}
        )

        result = asyncio.get_event_loop().run_until_complete(
            track_event(request)
        )

        assert result["tracked"] is True

    def test_track_event_tracks_daily_stats(self, mock_supabase_client, sample_user_id):
        """Test that specific events update daily stats."""
        from api.v1.analytics import track_event, EventRequest
        import asyncio

        mock_supabase_client.table.return_value.insert.return_value.execute.return_value = MagicMock()

        # Mock daily stats
        mock_stats_result = MagicMock()
        mock_stats_result.data = {"id": "stat-1", "workouts_started": 0}
        mock_supabase_client.table.return_value.select.return_value.eq.return_value.eq.return_value.single.return_value.execute.return_value = mock_stats_result

        request = EventRequest(
            user_id=sample_user_id,
            event_name="workout_started"
        )

        asyncio.get_event_loop().run_until_complete(
            track_event(request)
        )

        # Should update daily stats
        mock_supabase_client.table.return_value.update.assert_called()


# ============================================================
# FUNNEL EVENT TESTS
# ============================================================

class TestFunnelEvent:
    """Test funnel event tracking endpoint."""

    def test_track_funnel_event_success(self, mock_supabase_client, sample_user_id):
        """Test successful funnel event tracking."""
        from api.v1.analytics import track_funnel_event, FunnelEventRequest
        import asyncio

        mock_supabase_client.table.return_value.insert.return_value.execute.return_value = MagicMock()

        request = FunnelEventRequest(
            user_id=sample_user_id,
            funnel_name="onboarding",
            step_name="profile_creation",
            step_number=2,
            completed=True
        )

        result = asyncio.get_event_loop().run_until_complete(
            track_funnel_event(request)
        )

        assert result["tracked"] is True

    def test_track_funnel_event_drop_off(self, mock_supabase_client, sample_user_id):
        """Test tracking funnel drop-off."""
        from api.v1.analytics import track_funnel_event, FunnelEventRequest
        import asyncio

        mock_supabase_client.table.return_value.insert.return_value.execute.return_value = MagicMock()

        request = FunnelEventRequest(
            user_id=sample_user_id,
            funnel_name="checkout",
            step_name="payment",
            dropped_off=True,
            drop_off_reason="card_declined"
        )

        result = asyncio.get_event_loop().run_until_complete(
            track_funnel_event(request)
        )

        assert result["tracked"] is True


# ============================================================
# ONBOARDING ANALYTICS TESTS
# ============================================================

class TestOnboardingAnalytics:
    """Test onboarding step tracking endpoint."""

    def test_track_onboarding_step_success(self, mock_supabase_client, sample_user_id):
        """Test successful onboarding step tracking."""
        from api.v1.analytics import track_onboarding_step, OnboardingStepRequest
        import asyncio

        mock_supabase_client.table.return_value.insert.return_value.execute.return_value = MagicMock()

        request = OnboardingStepRequest(
            user_id=sample_user_id,
            step_name="fitness_goals",
            step_number=3,
            completed=True,
            duration_ms=15000,
            options_selected=["weight_loss", "muscle_gain"]
        )

        result = asyncio.get_event_loop().run_until_complete(
            track_onboarding_step(request)
        )

        assert result["tracked"] is True

    def test_track_onboarding_step_skipped(self, mock_supabase_client, sample_user_id):
        """Test tracking skipped onboarding step."""
        from api.v1.analytics import track_onboarding_step, OnboardingStepRequest
        import asyncio

        mock_supabase_client.table.return_value.insert.return_value.execute.return_value = MagicMock()

        request = OnboardingStepRequest(
            user_id=sample_user_id,
            step_name="connect_health",
            skipped=True
        )

        result = asyncio.get_event_loop().run_until_complete(
            track_onboarding_step(request)
        )

        assert result["tracked"] is True


# ============================================================
# ERROR TRACKING TESTS
# ============================================================

class TestErrorTracking:
    """Test app error tracking endpoint."""

    def test_track_error_success(self, mock_supabase_client, sample_user_id, sample_session_id):
        """Test successful error tracking."""
        from api.v1.analytics import track_error, ErrorRequest
        import asyncio

        mock_supabase_client.table.return_value.insert.return_value.execute.return_value = MagicMock()

        request = ErrorRequest(
            user_id=sample_user_id,
            session_id=sample_session_id,
            error_type="network_error",
            error_message="Connection timeout",
            screen_name="workout_detail",
            app_version="1.0.0"
        )

        result = asyncio.get_event_loop().run_until_complete(
            track_error(request)
        )

        assert result["tracked"] is True

    def test_track_error_with_stack_trace(self, mock_supabase_client, sample_user_id):
        """Test error tracking with stack trace."""
        from api.v1.analytics import track_error, ErrorRequest
        import asyncio

        mock_supabase_client.table.return_value.insert.return_value.execute.return_value = MagicMock()

        request = ErrorRequest(
            user_id=sample_user_id,
            error_type="exception",
            error_message="Null pointer exception",
            stack_trace="at com.app.MainActivity.onCreate()\nat com.app.Loader.load()"
        )

        result = asyncio.get_event_loop().run_until_complete(
            track_error(request)
        )

        assert result["tracked"] is True


# ============================================================
# BATCH UPLOAD TESTS
# ============================================================

class TestBatchUpload:
    """Test batch analytics upload endpoint."""

    def test_batch_upload_success(self, mock_supabase_client, sample_user_id, sample_session_id):
        """Test successful batch upload."""
        from api.v1.analytics import batch_upload, BatchRequest, BatchEventItem
        import asyncio

        mock_supabase_client.table.return_value.insert.return_value.execute.return_value = MagicMock()
        mock_supabase_client.table.return_value.update.return_value.eq.return_value.execute.return_value = MagicMock()

        request = BatchRequest(
            user_id=sample_user_id,
            session_id=sample_session_id,
            events=[
                BatchEventItem(type="screen_view", data={"screen_name": "home"}),
                BatchEventItem(type="event", data={"event_name": "click"}),
            ]
        )

        result = asyncio.get_event_loop().run_until_complete(
            batch_upload(request)
        )

        assert result["processed"] == 2
        assert result["total"] == 2
        assert result["errors"] is None

    def test_batch_upload_partial_failure(self, mock_supabase_client, sample_user_id):
        """Test batch upload with partial failures."""
        from api.v1.analytics import batch_upload, BatchRequest, BatchEventItem
        import asyncio

        # First succeeds, second fails
        mock_supabase_client.table.return_value.insert.return_value.execute.side_effect = [
            MagicMock(),
            Exception("Insert failed")
        ]

        request = BatchRequest(
            user_id=sample_user_id,
            events=[
                BatchEventItem(type="event", data={"event_name": "event1"}),
                BatchEventItem(type="event", data={"event_name": "event2"}),
            ]
        )

        result = asyncio.get_event_loop().run_until_complete(
            batch_upload(request)
        )

        assert result["processed"] == 1
        assert result["total"] == 2
        assert len(result["errors"]) == 1


# ============================================================
# ANALYTICS SUMMARY TESTS
# ============================================================

class TestAnalyticsSummary:
    """Test analytics summary endpoint."""

    def test_get_analytics_summary_success(self, mock_supabase_client, sample_user_id):
        """Test getting analytics summary."""
        from api.v1.analytics import get_analytics_summary
        import asyncio

        mock_result = MagicMock()
        mock_result.data = [
            {
                "date": "2025-01-10",
                "sessions_count": 3,
                "total_session_time_seconds": 1800,
                "screens_viewed": 25,
                "home_time_seconds": 300,
                "workout_time_seconds": 900,
                "chat_time_seconds": 200,
                "nutrition_time_seconds": 150,
                "profile_time_seconds": 100,
                "other_time_seconds": 150,
            }
        ]
        mock_supabase_client.table.return_value.select.return_value.eq.return_value.gte.return_value.order.return_value.execute.return_value = mock_result

        result = asyncio.get_event_loop().run_until_complete(
            get_analytics_summary(sample_user_id, days=7)
        )

        assert result["user_id"] == sample_user_id
        assert result["period_days"] == 7
        assert result["total_sessions"] == 3


# ============================================================
# SCREEN TIME TESTS
# ============================================================

class TestScreenTime:
    """Test screen time endpoint."""

    def test_get_screen_time_success(self, mock_supabase_client, sample_user_id):
        """Test getting screen time breakdown."""
        from api.v1.analytics import get_screen_time
        import asyncio

        mock_result = MagicMock()
        mock_result.data = [
            {"screen_name": "home", "duration_ms": 60000, "entered_at": "2025-01-10T10:00:00"},
            {"screen_name": "home", "duration_ms": 30000, "entered_at": "2025-01-10T11:00:00"},
            {"screen_name": "workout", "duration_ms": 120000, "entered_at": "2025-01-10T12:00:00"},
        ]
        mock_supabase_client.table.return_value.select.return_value.eq.return_value.gte.return_value.lte.return_value.not_.return_value.is_.return_value.execute.return_value = mock_result

        result = asyncio.get_event_loop().run_until_complete(
            get_screen_time(sample_user_id)
        )

        assert result["user_id"] == sample_user_id
        assert len(result["screens"]) == 2
        # Workout should be first (120 sec)
        assert result["screens"][0]["screen_name"] == "workout"


# ============================================================
# MODEL VALIDATION TESTS
# ============================================================

class TestAnalyticsModels:
    """Test Pydantic model validation."""

    def test_session_start_request(self):
        """Test SessionStartRequest model."""
        from api.v1.analytics import SessionStartRequest

        request = SessionStartRequest(
            user_id="user-123",
            device_type="ios",
            app_version="1.0.0"
        )

        assert request.user_id == "user-123"
        assert request.anonymous_id is None

    def test_screen_view_request(self):
        """Test ScreenViewRequest model."""
        from api.v1.analytics import ScreenViewRequest

        request = ScreenViewRequest(
            session_id="session-123",
            screen_name="home"
        )

        assert request.screen_name == "home"
        assert request.user_id is None

    def test_event_request(self):
        """Test EventRequest model."""
        from api.v1.analytics import EventRequest

        request = EventRequest(
            event_name="workout_completed",
            properties={"workout_id": "w-123", "duration_min": 45}
        )

        assert request.event_name == "workout_completed"
        assert request.properties["duration_min"] == 45

    def test_funnel_event_request(self):
        """Test FunnelEventRequest model."""
        from api.v1.analytics import FunnelEventRequest

        request = FunnelEventRequest(
            funnel_name="onboarding",
            step_name="welcome",
            step_number=1,
            completed=True
        )

        assert request.funnel_name == "onboarding"
        assert request.dropped_off is False

    def test_batch_event_item(self):
        """Test BatchEventItem model."""
        from api.v1.analytics import BatchEventItem

        item = BatchEventItem(
            type="screen_view",
            data={"screen_name": "home"},
            timestamp="2025-01-10T10:00:00"
        )

        assert item.type == "screen_view"


# ============================================================
# HELPER FUNCTION TESTS
# ============================================================

class TestHelperFunctions:
    """Test helper functions."""

    def test_increment_daily_sessions_new(self, mock_supabase_client):
        """Test incrementing daily sessions for new record."""
        from api.v1.analytics import _increment_daily_sessions

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(data=None)
        mock_supabase_client.table.return_value.insert.return_value.execute.return_value = MagicMock()

        _increment_daily_sessions(MagicMock(client=mock_supabase_client), "user-123")

        mock_supabase_client.table.return_value.insert.assert_called()

    def test_increment_daily_sessions_existing(self, mock_supabase_client):
        """Test incrementing daily sessions for existing record."""
        from api.v1.analytics import _increment_daily_sessions

        mock_result = MagicMock()
        mock_result.data = {"id": "stat-1", "sessions_count": 2}
        mock_supabase_client.table.return_value.select.return_value.eq.return_value.eq.return_value.single.return_value.execute.return_value = mock_result
        mock_supabase_client.table.return_value.update.return_value.eq.return_value.execute.return_value = MagicMock()

        _increment_daily_sessions(MagicMock(client=mock_supabase_client), "user-123")

        mock_supabase_client.table.return_value.update.assert_called()


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
