"""
Tests for Email Preferences API endpoints.

Tests CRUD operations for email subscription preferences.
"""

import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from datetime import datetime


# ─────────────────────────────────────────────────────────────────────────────
# FIXTURES
# ─────────────────────────────────────────────────────────────────────────────


@pytest.fixture
def mock_user_id():
    """Sample user ID for testing."""
    return "test-user-123"


@pytest.fixture
def mock_user_data(mock_user_id):
    """Sample user data."""
    return {
        "id": mock_user_id,
        "email": "test@example.com",
        "name": "Test User",
    }


@pytest.fixture
def mock_email_preferences(mock_user_id):
    """Sample email preferences data."""
    return {
        "id": "pref-123",
        "user_id": mock_user_id,
        "workout_reminders": True,
        "weekly_summary": True,
        "coach_tips": True,
        "product_updates": True,
        "promotional": False,
        "created_at": datetime.utcnow().isoformat(),
        "updated_at": datetime.utcnow().isoformat(),
    }


@pytest.fixture
def mock_supabase():
    """Mock Supabase client."""
    mock = MagicMock()
    return mock


# ─────────────────────────────────────────────────────────────────────────────
# UNIT TESTS: Helper Functions
# ─────────────────────────────────────────────────────────────────────────────


def test_get_default_preferences():
    """Test that default preferences have correct values."""
    from api.v1.email_preferences import _get_default_preferences

    user_id = "test-user-123"
    defaults = _get_default_preferences(user_id)

    # Check all defaults
    assert defaults["user_id"] == user_id
    assert defaults["workout_reminders"] is True  # Essential
    assert defaults["weekly_summary"] is True
    assert defaults["coach_tips"] is True
    assert defaults["product_updates"] is True
    assert defaults["promotional"] is False  # Opt-in only


def test_preferences_to_response(mock_email_preferences):
    """Test conversion from database row to response model."""
    from api.v1.email_preferences import _preferences_to_response

    response = _preferences_to_response(mock_email_preferences)

    assert response.id == mock_email_preferences["id"]
    assert response.user_id == mock_email_preferences["user_id"]
    assert response.workout_reminders == mock_email_preferences["workout_reminders"]
    assert response.weekly_summary == mock_email_preferences["weekly_summary"]
    assert response.coach_tips == mock_email_preferences["coach_tips"]
    assert response.product_updates == mock_email_preferences["product_updates"]
    assert response.promotional == mock_email_preferences["promotional"]


def test_preferences_to_response_with_missing_fields():
    """Test conversion handles missing fields gracefully."""
    from api.v1.email_preferences import _preferences_to_response

    incomplete_data = {
        "id": "pref-123",
        "user_id": "user-123",
        # Missing other fields
    }

    response = _preferences_to_response(incomplete_data)

    # Should use defaults for missing fields
    assert response.workout_reminders is True
    assert response.weekly_summary is True
    assert response.coach_tips is True
    assert response.product_updates is True
    assert response.promotional is False


# ─────────────────────────────────────────────────────────────────────────────
# UNIT TESTS: Request Models
# ─────────────────────────────────────────────────────────────────────────────


def test_email_preferences_update_partial():
    """Test that update model accepts partial updates."""
    from api.v1.email_preferences import EmailPreferencesUpdate

    # Only update one field
    update = EmailPreferencesUpdate(promotional=True)
    data = update.model_dump(exclude_none=True)

    assert len(data) == 1
    assert data["promotional"] is True


def test_email_preferences_update_all_fields():
    """Test that update model accepts all fields."""
    from api.v1.email_preferences import EmailPreferencesUpdate

    update = EmailPreferencesUpdate(
        workout_reminders=False,
        weekly_summary=False,
        coach_tips=False,
        product_updates=False,
        promotional=True,
    )
    data = update.model_dump(exclude_none=True)

    assert len(data) == 5
    assert data["workout_reminders"] is False
    assert data["promotional"] is True


def test_email_preferences_update_empty():
    """Test that update model allows no fields (no-op update)."""
    from api.v1.email_preferences import EmailPreferencesUpdate

    update = EmailPreferencesUpdate()
    data = update.model_dump(exclude_none=True)

    assert len(data) == 0


# ─────────────────────────────────────────────────────────────────────────────
# INTEGRATION TESTS: API Endpoints
# ─────────────────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_get_email_preferences_existing(mock_user_id, mock_user_data, mock_email_preferences):
    """Test getting existing email preferences."""
    with patch("api.v1.email_preferences.get_supabase") as mock_get_supabase, \
         patch("api.v1.email_preferences.log_user_activity", new_callable=AsyncMock):

        # Setup mock
        mock_supabase = MagicMock()
        mock_get_supabase.return_value = mock_supabase

        # Mock user exists check
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(
            data=mock_user_data
        )

        # Import endpoint
        from api.v1.email_preferences import get_email_preferences

        # First call returns user, second returns preferences
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.side_effect = [
            MagicMock(data=mock_user_data),
            MagicMock(data=mock_email_preferences),
        ]

        result = await get_email_preferences(mock_user_id)

        assert result.user_id == mock_user_id
        assert result.workout_reminders is True


@pytest.mark.asyncio
async def test_get_email_preferences_user_not_found():
    """Test getting preferences for non-existent user."""
    with patch("api.v1.email_preferences.get_supabase") as mock_get_supabase:

        mock_supabase = MagicMock()
        mock_get_supabase.return_value = mock_supabase

        # Mock user not found
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(
            data=None
        )

        from api.v1.email_preferences import get_email_preferences
        from fastapi import HTTPException

        with pytest.raises(HTTPException) as exc_info:
            await get_email_preferences("non-existent-user")

        assert exc_info.value.status_code == 404
        assert "User not found" in exc_info.value.detail


@pytest.mark.asyncio
async def test_update_email_preferences(mock_user_id, mock_user_data, mock_email_preferences):
    """Test updating email preferences."""
    with patch("api.v1.email_preferences.get_supabase") as mock_get_supabase, \
         patch("api.v1.email_preferences.log_user_activity", new_callable=AsyncMock):

        mock_supabase = MagicMock()
        mock_get_supabase.return_value = mock_supabase

        from api.v1.email_preferences import update_email_preferences, EmailPreferencesUpdate

        # Mock responses
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.side_effect = [
            MagicMock(data=mock_user_data),  # User exists check
            MagicMock(data={"id": "pref-123"}),  # Preferences exist check
        ]

        updated_prefs = {**mock_email_preferences, "promotional": True}
        mock_supabase.client.table.return_value.update.return_value.eq.return_value.execute.return_value = MagicMock(
            data=[updated_prefs]
        )

        update = EmailPreferencesUpdate(promotional=True)
        result = await update_email_preferences(mock_user_id, update)

        assert result.promotional is True


@pytest.mark.asyncio
async def test_unsubscribe_from_marketing(mock_user_id, mock_user_data, mock_email_preferences):
    """Test unsubscribing from all marketing emails."""
    with patch("api.v1.email_preferences.get_supabase") as mock_get_supabase, \
         patch("api.v1.email_preferences.log_user_activity", new_callable=AsyncMock):

        mock_supabase = MagicMock()
        mock_get_supabase.return_value = mock_supabase

        from api.v1.email_preferences import unsubscribe_from_marketing

        # Mock responses
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.side_effect = [
            MagicMock(data=mock_user_data),  # User exists check
            MagicMock(data={"id": "pref-123"}),  # Preferences exist check
        ]

        # Unsubscribed preferences
        unsubscribed_prefs = {
            **mock_email_preferences,
            "workout_reminders": True,  # Keep essential
            "weekly_summary": False,
            "coach_tips": False,
            "product_updates": False,
            "promotional": False,
        }
        mock_supabase.client.table.return_value.update.return_value.eq.return_value.execute.return_value = MagicMock(
            data=[unsubscribed_prefs]
        )

        result = await unsubscribe_from_marketing(mock_user_id)

        assert result.success is True
        assert "unsubscribed" in result.message.lower()
        assert result.preferences.workout_reminders is True  # Essential kept
        assert result.preferences.weekly_summary is False
        assert result.preferences.coach_tips is False
        assert result.preferences.product_updates is False
        assert result.preferences.promotional is False


@pytest.mark.asyncio
async def test_subscribe_to_all(mock_user_id, mock_user_data, mock_email_preferences):
    """Test subscribing to all email types."""
    with patch("api.v1.email_preferences.get_supabase") as mock_get_supabase, \
         patch("api.v1.email_preferences.log_user_activity", new_callable=AsyncMock):

        mock_supabase = MagicMock()
        mock_get_supabase.return_value = mock_supabase

        from api.v1.email_preferences import subscribe_to_all

        # Mock responses
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.side_effect = [
            MagicMock(data=mock_user_data),  # User exists check
            MagicMock(data={"id": "pref-123"}),  # Preferences exist check
        ]

        # All subscribed
        all_subscribed = {
            **mock_email_preferences,
            "workout_reminders": True,
            "weekly_summary": True,
            "coach_tips": True,
            "product_updates": True,
            "promotional": True,
        }
        mock_supabase.client.table.return_value.update.return_value.eq.return_value.execute.return_value = MagicMock(
            data=[all_subscribed]
        )

        result = await subscribe_to_all(mock_user_id)

        assert result.workout_reminders is True
        assert result.weekly_summary is True
        assert result.coach_tips is True
        assert result.product_updates is True
        assert result.promotional is True


# ─────────────────────────────────────────────────────────────────────────────
# EDGE CASE TESTS
# ─────────────────────────────────────────────────────────────────────────────


def test_email_preferences_response_model():
    """Test EmailPreferencesResponse model validation."""
    from api.v1.email_preferences import EmailPreferencesResponse

    response = EmailPreferencesResponse(
        id="pref-123",
        user_id="user-123",
        workout_reminders=True,
        weekly_summary=True,
        coach_tips=False,
        product_updates=True,
        promotional=False,
        created_at="2025-01-01T00:00:00Z",
        updated_at="2025-01-01T00:00:00Z",
    )

    assert response.id == "pref-123"
    assert response.coach_tips is False


def test_unsubscribe_marketing_response_model():
    """Test UnsubscribeMarketingResponse model validation."""
    from api.v1.email_preferences import UnsubscribeMarketingResponse, EmailPreferencesResponse

    prefs = EmailPreferencesResponse(
        id="pref-123",
        user_id="user-123",
        workout_reminders=True,
        weekly_summary=False,
        coach_tips=False,
        product_updates=False,
        promotional=False,
        created_at="2025-01-01T00:00:00Z",
        updated_at="2025-01-01T00:00:00Z",
    )

    response = UnsubscribeMarketingResponse(
        success=True,
        message="Unsubscribed from marketing emails",
        preferences=prefs,
    )

    assert response.success is True
    assert response.preferences.weekly_summary is False


# ─────────────────────────────────────────────────────────────────────────────
# RLS POLICY TESTS (conceptual - these would need a real database)
# ─────────────────────────────────────────────────────────────────────────────


def test_rls_policy_documentation():
    """
    Document expected RLS behavior.

    In a real integration test with a database:
    1. User A should only be able to read their own preferences
    2. User A should only be able to update their own preferences
    3. User A should NOT be able to read User B's preferences
    4. Service role should have full access for backend operations
    """
    # These are documentation tests - actual RLS testing requires
    # integration tests with a real Supabase instance

    expected_policies = [
        "Users can view own email preferences",
        "Users can insert own email preferences",
        "Users can update own email preferences",
        "Users can delete own email preferences",
        "Service role has full access to email preferences",
    ]

    # Verify our migration includes these policies
    with open("backend/migrations/088_email_preferences.sql", "r") as f:
        migration_content = f.read()

    for policy in expected_policies:
        assert policy in migration_content, f"Missing RLS policy: {policy}"


# ─────────────────────────────────────────────────────────────────────────────
# LOGGING TESTS
# ─────────────────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_activity_logging_on_update(mock_user_id, mock_user_data, mock_email_preferences):
    """Test that preference updates are logged for analytics."""
    with patch("api.v1.email_preferences.get_supabase") as mock_get_supabase, \
         patch("api.v1.email_preferences.log_user_activity", new_callable=AsyncMock) as mock_log:

        mock_supabase = MagicMock()
        mock_get_supabase.return_value = mock_supabase

        from api.v1.email_preferences import update_email_preferences, EmailPreferencesUpdate

        # Mock responses
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.side_effect = [
            MagicMock(data=mock_user_data),
            MagicMock(data={"id": "pref-123"}),
        ]

        mock_supabase.client.table.return_value.update.return_value.eq.return_value.execute.return_value = MagicMock(
            data=[mock_email_preferences]
        )

        update = EmailPreferencesUpdate(promotional=True)
        await update_email_preferences(mock_user_id, update)

        # Verify logging was called
        mock_log.assert_called_once()
        call_kwargs = mock_log.call_args.kwargs
        assert call_kwargs["action"] == "email_preferences_updated"
        assert "promotional" in call_kwargs["metadata"]["changed_fields"]


@pytest.mark.asyncio
async def test_activity_logging_on_unsubscribe(mock_user_id, mock_user_data, mock_email_preferences):
    """Test that unsubscribing from marketing is logged."""
    with patch("api.v1.email_preferences.get_supabase") as mock_get_supabase, \
         patch("api.v1.email_preferences.log_user_activity", new_callable=AsyncMock) as mock_log:

        mock_supabase = MagicMock()
        mock_get_supabase.return_value = mock_supabase

        from api.v1.email_preferences import unsubscribe_from_marketing

        # Mock responses
        unsubscribed_prefs = {**mock_email_preferences, "weekly_summary": False, "coach_tips": False, "product_updates": False}
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.side_effect = [
            MagicMock(data=mock_user_data),
            MagicMock(data={"id": "pref-123"}),
        ]
        mock_supabase.client.table.return_value.update.return_value.eq.return_value.execute.return_value = MagicMock(
            data=[unsubscribed_prefs]
        )

        await unsubscribe_from_marketing(mock_user_id)

        # Verify logging was called with correct action
        mock_log.assert_called_once()
        call_kwargs = mock_log.call_args.kwargs
        assert call_kwargs["action"] == "unsubscribed_from_marketing"
