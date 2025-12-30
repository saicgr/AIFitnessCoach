"""
Tests for Fasting Tracking API endpoints.

Tests the fasting system endpoints:
- Fasting records (POST /fasting/start, POST /fasting/{id}/end, GET /fasting/active/{user_id})
- Fasting preferences (GET, PUT /fasting/preferences/{user_id})
- Fasting onboarding (POST /fasting/onboarding/complete)
- Fasting streaks (GET /fasting/streak/{user_id})
- Fasting stats (GET /fasting/stats/{user_id})
- Safety screening (GET /fasting/safety-check/{user_id}, POST /fasting/safety-screening)
- Context logging (POST /fasting/context/log, GET /fasting/context/{user_id})

Run with: pytest backend/tests/test_fasting_api.py -v
"""

import pytest
from unittest.mock import MagicMock, patch, AsyncMock
from datetime import datetime, timedelta, date
import uuid
import sys
import os

# Add the backend directory to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def mock_supabase_db():
    """Mock SupabaseDB with chainable Supabase client pattern."""
    with patch("api.v1.fasting.get_supabase_db") as mock_get_db:
        mock_db = MagicMock()
        mock_client = MagicMock()
        mock_db.client = mock_client

        # Create chainable mock for table operations
        mock_table = MagicMock()
        mock_client.table.return_value = mock_table

        # Make all table operations chainable
        mock_table.select.return_value = mock_table
        mock_table.insert.return_value = mock_table
        mock_table.update.return_value = mock_table
        mock_table.delete.return_value = mock_table
        mock_table.upsert.return_value = mock_table
        mock_table.eq.return_value = mock_table
        mock_table.neq.return_value = mock_table
        mock_table.gte.return_value = mock_table
        mock_table.lte.return_value = mock_table
        mock_table.order.return_value = mock_table
        mock_table.limit.return_value = mock_table
        mock_table.range.return_value = mock_table
        mock_table.is_.return_value = mock_table
        mock_table.single.return_value = mock_table
        mock_table.maybe_single.return_value = mock_table

        # Store mock_table for easy access in tests
        mock_db._mock_table = mock_table

        mock_get_db.return_value = mock_db
        yield mock_db


@pytest.fixture
def mock_activity_logger():
    """Mock the activity logger."""
    with patch("api.v1.fasting.log_user_activity", new_callable=AsyncMock) as mock_activity, \
         patch("api.v1.fasting.log_user_error", new_callable=AsyncMock) as mock_error:
        yield {"activity": mock_activity, "error": mock_error}


@pytest.fixture
def sample_user_id():
    return str(uuid.uuid4())


@pytest.fixture
def sample_fasting_record():
    return {
        "id": str(uuid.uuid4()),
        "user_id": "user-123-abc",
        "start_time": "2025-01-15T20:00:00+00:00",
        "end_time": None,
        "goal_duration_minutes": 960,  # 16 hours
        "actual_duration_minutes": None,
        "protocol": "16:8",
        "protocol_type": "tre",
        "status": "active",
        "completed_goal": False,
        "completion_percentage": 0,
        "zones_reached": [],
        "notes": None,
        "mood_before": "good",
        "mood_after": None,
        "energy_level": None,
        "created_at": "2025-01-15T20:00:00+00:00",
        "updated_at": None,
    }


@pytest.fixture
def sample_fasting_preferences():
    return {
        "id": str(uuid.uuid4()),
        "user_id": "user-123-abc",
        "default_protocol": "16:8",
        "custom_fasting_hours": None,
        "custom_eating_hours": None,
        "typical_fast_start_hour": 20,
        "typical_eating_start_hour": 12,
        "fasting_days": None,
        "notifications_enabled": True,
        "notify_zone_transitions": True,
        "notify_goal_reached": True,
        "notify_eating_window_end": True,
        "notify_fast_start_reminder": True,
        "is_keto_adapted": False,
        "meal_reminders_enabled": True,
        "lunch_reminder_hour": 12,
        "dinner_reminder_hour": 18,
        "extended_protocol_acknowledged": False,
        "safety_responses": {},
        "safety_screening_completed": True,
        "safety_warnings_acknowledged": [],
        "has_medical_conditions": False,
        "fasting_onboarding_completed": True,
        "onboarding_completed_at": "2025-01-15T10:00:00+00:00",
        "created_at": "2025-01-15T10:00:00+00:00",
        "updated_at": "2025-01-15T10:00:00+00:00",
    }


@pytest.fixture
def sample_fasting_streak():
    return {
        "id": str(uuid.uuid4()),
        "user_id": "user-123-abc",
        "current_streak": 5,
        "longest_streak": 10,
        "total_fasts_completed": 25,
        "total_fasting_hours": 400,
        "last_fast_date": "2025-01-15",
        "streak_start_date": "2025-01-10",
        "fasts_this_week": 3,
        "week_start_date": "2025-01-13",
        "freezes_available": 2,
        "freezes_used_this_week": 0,
        "created_at": "2025-01-01T00:00:00+00:00",
        "updated_at": "2025-01-15T00:00:00+00:00",
    }


# ============================================================
# HELPER FUNCTION TESTS
# ============================================================

class TestHelperFunctions:
    """Test helper functions for fasting."""

    def test_is_dangerous_protocol(self):
        """Test dangerous protocol detection."""
        from api.v1.fasting import is_dangerous_protocol

        # Dangerous protocols
        assert is_dangerous_protocol("24h Water Fast") is True
        assert is_dangerous_protocol("48h Water Fast") is True
        assert is_dangerous_protocol("72h Water Fast") is True
        assert is_dangerous_protocol("7-Day Water Fast") is True

        # Safe protocols
        assert is_dangerous_protocol("16:8") is False
        assert is_dangerous_protocol("18:6") is False
        assert is_dangerous_protocol("OMAD") is False
        assert is_dangerous_protocol("5:2") is False

    def test_get_protocol_fasting_hours(self):
        """Test protocol fasting hours lookup."""
        from api.v1.fasting import get_protocol_fasting_hours

        assert get_protocol_fasting_hours("12:12") == 12
        assert get_protocol_fasting_hours("14:10") == 14
        assert get_protocol_fasting_hours("16:8") == 16
        assert get_protocol_fasting_hours("18:6") == 18
        assert get_protocol_fasting_hours("20:4") == 20
        assert get_protocol_fasting_hours("OMAD") == 23
        assert get_protocol_fasting_hours("OMAD (One Meal a Day)") == 23
        assert get_protocol_fasting_hours("24h Water Fast") == 24
        assert get_protocol_fasting_hours("48h Water Fast") == 48
        assert get_protocol_fasting_hours("72h Water Fast") == 72
        assert get_protocol_fasting_hours("7-Day Water Fast") == 168
        assert get_protocol_fasting_hours("5:2") == 24
        assert get_protocol_fasting_hours("ADF") == 24
        assert get_protocol_fasting_hours("unknown") == 16  # default

    def test_calculate_completion_percentage(self):
        """Test completion percentage calculation."""
        from api.v1.fasting import calculate_completion_percentage

        assert calculate_completion_percentage(480, 960) == 50.0
        assert calculate_completion_percentage(960, 960) == 100.0
        assert calculate_completion_percentage(1200, 960) == 100.0  # capped at 100
        assert calculate_completion_percentage(0, 960) == 0.0
        assert calculate_completion_percentage(100, 0) == 0.0  # avoid division by zero


# ============================================================
# FASTING RECORDS ENDPOINT TESTS
# ============================================================

class TestStartFast:
    """Test POST /fasting/start endpoint."""

    @pytest.mark.asyncio
    async def test_start_fast_success(self, mock_supabase_db, mock_activity_logger, sample_user_id):
        """Test starting a new fast successfully."""
        from api.v1.fasting import start_fast, StartFastRequest

        # No existing active fast
        mock_supabase_db._mock_table.execute.side_effect = [
            MagicMock(data=[]),  # Check for existing active fast
            MagicMock(data=[{  # Insert new fast
                "id": str(uuid.uuid4()),
                "user_id": sample_user_id,
                "start_time": datetime.utcnow().isoformat(),
                "goal_duration_minutes": 960,
                "protocol": "16:8",
                "protocol_type": "tre",
                "status": "active",
                "completed_goal": False,
                "zones_reached": [],
                "mood_before": "good",
                "notes": None,
                "created_at": datetime.utcnow().isoformat(),
            }]),
        ]

        request = StartFastRequest(
            user_id=sample_user_id,
            protocol="16:8",
            protocol_type="tre",
            goal_duration_minutes=960,
            mood_before="good",
        )

        result = await start_fast(request)

        assert result.protocol == "16:8"
        assert result.status == "active"
        assert result.user_id == sample_user_id

    @pytest.mark.asyncio
    async def test_start_fast_already_active(self, mock_supabase_db, sample_user_id):
        """Test starting a fast when one is already active."""
        from api.v1.fasting import start_fast, StartFastRequest
        from fastapi import HTTPException

        # Existing active fast
        mock_supabase_db._mock_table.execute.return_value = MagicMock(data=[{"id": "existing-fast-id"}])

        request = StartFastRequest(
            user_id=sample_user_id,
            protocol="16:8",
            protocol_type="tre",
            goal_duration_minutes=960,
        )

        with pytest.raises(HTTPException) as exc_info:
            await start_fast(request)

        assert exc_info.value.status_code == 400
        assert "already have an active fast" in str(exc_info.value.detail)


class TestGetActiveFast:
    """Test GET /fasting/active/{user_id} endpoint."""

    @pytest.mark.asyncio
    async def test_get_active_fast_exists(self, mock_supabase_db, sample_fasting_record):
        """Test getting an existing active fast."""
        from api.v1.fasting import get_active_fast

        mock_supabase_db._mock_table.execute.return_value = MagicMock(data=[sample_fasting_record])

        result = await get_active_fast(sample_fasting_record["user_id"])

        assert result is not None
        assert result.protocol == "16:8"
        assert result.status == "active"

    @pytest.mark.asyncio
    async def test_get_active_fast_none(self, mock_supabase_db, sample_user_id):
        """Test getting active fast when none exists."""
        from api.v1.fasting import get_active_fast

        mock_supabase_db._mock_table.execute.return_value = MagicMock(data=[])

        result = await get_active_fast(sample_user_id)

        assert result is None


# ============================================================
# FASTING PREFERENCES ENDPOINT TESTS
# ============================================================

class TestGetPreferences:
    """Test GET /fasting/preferences/{user_id} endpoint."""

    @pytest.mark.asyncio
    async def test_get_preferences_success(self, mock_supabase_db, sample_fasting_preferences):
        """Test getting fasting preferences successfully."""
        from api.v1.fasting import get_preferences

        mock_supabase_db._mock_table.execute.return_value = MagicMock(data=[sample_fasting_preferences])

        result = await get_preferences(sample_fasting_preferences["user_id"])

        assert result is not None
        assert result.default_protocol == "16:8"
        assert result.notifications_enabled is True
        assert result.fasting_onboarding_completed is True
        assert result.meal_reminders_enabled is True
        assert result.lunch_reminder_hour == 12
        assert result.dinner_reminder_hour == 18

    @pytest.mark.asyncio
    async def test_get_preferences_not_found(self, mock_supabase_db, sample_user_id):
        """Test getting preferences when none exist."""
        from api.v1.fasting import get_preferences

        mock_supabase_db._mock_table.execute.return_value = MagicMock(data=[])

        result = await get_preferences(sample_user_id)

        assert result is None


class TestCompleteOnboarding:
    """Test POST /fasting/onboarding/complete endpoint."""

    @pytest.mark.asyncio
    async def test_complete_onboarding_new_user(self, mock_supabase_db, mock_activity_logger, sample_user_id):
        """Test completing onboarding for a new user."""
        from api.v1.fasting import complete_onboarding, CompleteOnboardingRequest

        # No existing preferences
        mock_supabase_db._mock_table.execute.side_effect = [
            MagicMock(data=[]),  # Check for existing
            MagicMock(data=[{"id": str(uuid.uuid4())}]),  # Insert
        ]

        request = CompleteOnboardingRequest(
            user_id=sample_user_id,
            preferences={
                "default_protocol": "16:8",
                "typical_fast_start_hour": 20,
                "typical_eating_start_hour": 12,
                "notifications_enabled": True,
                "meal_reminders_enabled": True,
                "lunch_reminder_hour": 12,
                "dinner_reminder_hour": 18,
            },
            safety_acknowledgments=["type2_diabetes_bp", "medication_with_food"],
        )

        result = await complete_onboarding(request)

        assert result["status"] == "completed"
        assert result["user_id"] == sample_user_id


# ============================================================
# FASTING STREAK ENDPOINT TESTS
# ============================================================

class TestGetStreak:
    """Test GET /fasting/streak/{user_id} endpoint."""

    @pytest.mark.asyncio
    async def test_get_streak_exists(self, mock_supabase_db, sample_fasting_streak):
        """Test getting an existing streak."""
        from api.v1.fasting import get_streak

        mock_supabase_db._mock_table.execute.return_value = MagicMock(data=[sample_fasting_streak])

        result = await get_streak(sample_fasting_streak["user_id"])

        assert result.current_streak == 5
        assert result.longest_streak == 10
        assert result.total_fasts_completed == 25
        assert result.freezes_available == 2

    @pytest.mark.asyncio
    async def test_get_streak_default(self, mock_supabase_db, sample_user_id):
        """Test getting default streak for new user."""
        from api.v1.fasting import get_streak

        mock_supabase_db._mock_table.execute.return_value = MagicMock(data=[])

        result = await get_streak(sample_user_id)

        assert result.current_streak == 0
        assert result.longest_streak == 0
        assert result.total_fasts_completed == 0


# ============================================================
# FASTING STATS ENDPOINT TESTS
# ============================================================

class TestGetStats:
    """Test GET /fasting/stats/{user_id} endpoint."""

    @pytest.mark.asyncio
    async def test_get_stats_with_data(self, mock_supabase_db, sample_user_id):
        """Test getting stats with fasting history."""
        from api.v1.fasting import get_stats

        mock_supabase_db._mock_table.execute.return_value = MagicMock(data=[
            {
                "id": str(uuid.uuid4()),
                "protocol": "16:8",
                "status": "completed",
                "actual_duration_minutes": 960,
                "goal_duration_minutes": 960,
                "completed_goal": True,
            },
            {
                "id": str(uuid.uuid4()),
                "protocol": "16:8",
                "status": "completed",
                "actual_duration_minutes": 900,
                "goal_duration_minutes": 960,
                "completed_goal": False,
            },
            {
                "id": str(uuid.uuid4()),
                "protocol": "18:6",
                "status": "cancelled",
                "actual_duration_minutes": 300,
                "goal_duration_minutes": 1080,
                "completed_goal": False,
            },
        ])

        result = await get_stats(sample_user_id, "month")

        assert result.total_fasts == 3
        assert result.completed_fasts == 2
        assert result.cancelled_fasts == 1
        assert result.most_common_protocol == "16:8"

    @pytest.mark.asyncio
    async def test_get_stats_empty(self, mock_supabase_db, sample_user_id):
        """Test getting stats with no fasting history."""
        from api.v1.fasting import get_stats

        mock_supabase_db._mock_table.execute.return_value = MagicMock(data=[])

        result = await get_stats(sample_user_id, "week")

        assert result.total_fasts == 0
        assert result.completed_fasts == 0
        assert result.completion_rate == 0


# ============================================================
# SAFETY ENDPOINT TESTS
# ============================================================

class TestSafetyCheck:
    """Test GET /fasting/safety-check/{user_id} endpoint."""

    @pytest.mark.asyncio
    async def test_safety_check_no_issues(self, mock_supabase_db, sample_user_id):
        """Test safety check for healthy user."""
        from api.v1.fasting import check_safety_eligibility

        mock_supabase_db._mock_table.execute.return_value = MagicMock(data=[{
            "age": 30,
            "gender": "male",
            "weight_kg": 75,
            "height_cm": 175,
            "health_conditions": [],
            "goals": ["build_muscle"],
        }])

        result = await check_safety_eligibility(sample_user_id)

        assert result.can_use_fasting is True
        assert len(result.blocked_reasons) == 0

    @pytest.mark.asyncio
    async def test_safety_check_underweight(self, mock_supabase_db, sample_user_id):
        """Test safety check for underweight user."""
        from api.v1.fasting import check_safety_eligibility

        mock_supabase_db._mock_table.execute.return_value = MagicMock(data=[{
            "age": 25,
            "gender": "female",
            "weight_kg": 45,
            "height_cm": 170,  # BMI ~15.6
            "health_conditions": [],
            "goals": [],
        }])

        result = await check_safety_eligibility(sample_user_id)

        assert result.can_use_fasting is False
        assert any("underweight" in r.lower() for r in result.blocked_reasons)

    @pytest.mark.asyncio
    async def test_safety_check_type1_diabetes(self, mock_supabase_db, sample_user_id):
        """Test safety check for Type 1 diabetic."""
        from api.v1.fasting import check_safety_eligibility

        mock_supabase_db._mock_table.execute.return_value = MagicMock(data=[{
            "age": 35,
            "gender": "male",
            "weight_kg": 80,
            "height_cm": 180,
            "health_conditions": ["Type 1 Diabetes"],
            "goals": [],
        }])

        result = await check_safety_eligibility(sample_user_id)

        assert result.can_use_fasting is False
        assert any("type 1" in r.lower() for r in result.blocked_reasons)


# ============================================================
# CONTEXT LOGGING ENDPOINT TESTS
# ============================================================

class TestContextLogging:
    """Test POST /fasting/context/log endpoint."""

    @pytest.mark.asyncio
    async def test_log_context_success(self, mock_supabase_db, sample_user_id):
        """Test logging fasting context successfully."""
        from api.v1.fasting import log_fasting_context, LogFastingContextRequest

        mock_supabase_db._mock_table.execute.return_value = MagicMock(data=[{
            "id": str(uuid.uuid4()),
        }])

        request = LogFastingContextRequest(
            user_id=sample_user_id,
            fasting_record_id=str(uuid.uuid4()),
            context_type="zone_entered",
            zone_name="fat_burning",
            protocol="16:8",
            elapsed_minutes=720,
            goal_minutes=960,
        )

        result = await log_fasting_context(request)

        assert result["status"] == "logged"
        assert "context_id" in result

    @pytest.mark.asyncio
    async def test_log_context_table_not_exists(self, mock_supabase_db, sample_user_id):
        """Test logging context when table doesn't exist (graceful failure)."""
        from api.v1.fasting import log_fasting_context, LogFastingContextRequest

        mock_supabase_db._mock_table.execute.return_value = MagicMock(data=[])

        request = LogFastingContextRequest(
            user_id=sample_user_id,
            context_type="fast_started",
            protocol="16:8",
        )

        result = await log_fasting_context(request)

        # Should not fail, just skip
        assert result["status"] == "skipped"


class TestGetContext:
    """Test GET /fasting/context/{user_id} endpoint."""

    @pytest.mark.asyncio
    async def test_get_context_success(self, mock_supabase_db, sample_user_id):
        """Test getting fasting context history."""
        from api.v1.fasting import get_fasting_context

        mock_supabase_db._mock_table.execute.return_value = MagicMock(data=[
            {
                "id": str(uuid.uuid4()),
                "context_type": "fast_started",
                "protocol": "16:8",
                "timestamp": datetime.utcnow().isoformat(),
            },
            {
                "id": str(uuid.uuid4()),
                "context_type": "zone_entered",
                "zone_name": "fat_burning",
                "timestamp": datetime.utcnow().isoformat(),
            },
        ])

        result = await get_fasting_context(sample_user_id, limit=50)

        assert result["count"] == 2
        assert len(result["contexts"]) == 2


# ============================================================
# PYDANTIC MODEL VALIDATION TESTS
# ============================================================

class TestPydanticModels:
    """Test Pydantic model validation."""

    def test_start_fast_request_validation(self):
        """Test StartFastRequest validation."""
        from api.v1.fasting import StartFastRequest

        # Valid request
        request = StartFastRequest(
            user_id="user-123",
            protocol="16:8",
            protocol_type="tre",
            goal_duration_minutes=960,
        )
        assert request.goal_duration_minutes == 960

        # Invalid - duration too short
        with pytest.raises(ValueError):
            StartFastRequest(
                user_id="user-123",
                protocol="16:8",
                protocol_type="tre",
                goal_duration_minutes=30,  # Less than 60
            )

        # Invalid - duration too long
        with pytest.raises(ValueError):
            StartFastRequest(
                user_id="user-123",
                protocol="16:8",
                protocol_type="tre",
                goal_duration_minutes=20000,  # More than 10080 (7 days)
            )

    def test_fasting_preferences_request_validation(self):
        """Test FastingPreferencesRequest validation."""
        from api.v1.fasting import FastingPreferencesRequest

        # Valid request
        request = FastingPreferencesRequest(
            user_id="user-123",
            default_protocol="18:6",
            typical_fast_start_hour=20,
            typical_eating_start_hour=14,
            meal_reminders_enabled=True,
            lunch_reminder_hour=12,
            dinner_reminder_hour=18,
        )
        assert request.default_protocol == "18:6"
        assert request.lunch_reminder_hour == 12

        # Invalid hour (out of range)
        with pytest.raises(ValueError):
            FastingPreferencesRequest(
                user_id="user-123",
                typical_fast_start_hour=25,  # Invalid hour
            )
