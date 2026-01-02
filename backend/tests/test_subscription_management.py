"""
Tests for Subscription Management API endpoints.

Tests:
- Pause subscription
- Resume subscription
- Get retention offers
- Accept retention offer

Run with: pytest backend/tests/test_subscription_management.py -v
"""

import pytest
from unittest.mock import MagicMock, patch, AsyncMock
from datetime import datetime, timedelta
import asyncio


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def mock_supabase_client():
    """Mock Supabase client for subscription operations."""
    with patch("api.v1.subscriptions.get_supabase") as mock_get_supabase:
        mock_supabase = MagicMock()
        mock_client = MagicMock()
        mock_supabase.client = mock_client
        mock_get_supabase.return_value = mock_supabase
        yield mock_client


@pytest.fixture
def mock_activity_logger():
    """Mock activity logger to prevent actual logging."""
    with patch("api.v1.subscriptions.log_user_activity", new_callable=AsyncMock) as mock_log:
        with patch("api.v1.subscriptions.log_user_error", new_callable=AsyncMock) as mock_error:
            yield {"log_activity": mock_log, "log_error": mock_error}


@pytest.fixture
def sample_user_id():
    return "user-123-abc"


@pytest.fixture
def sample_premium_subscription():
    """Sample premium subscription data."""
    return {
        "id": "sub-123",
        "user_id": "user-123-abc",
        "tier": "premium",
        "status": "active",
        "product_id": "premium_monthly",
        "is_trial": False,
        "trial_end_date": None,
        "current_period_start": "2025-01-01T00:00:00Z",
        "current_period_end": "2025-02-01T00:00:00Z",
        "price_paid": 9.99,
        "currency": "USD",
        "canceled_at": None,
        "is_lifetime": False,
        "paused_at": None,
        "pause_resume_date": None
    }


@pytest.fixture
def sample_paused_subscription():
    """Sample paused subscription data."""
    now = datetime.utcnow()
    resume_date = now + timedelta(days=14)
    return {
        "id": "sub-123",
        "user_id": "user-123-abc",
        "tier": "premium",
        "status": "paused",
        "product_id": "premium_monthly",
        "is_trial": False,
        "trial_end_date": None,
        "current_period_start": "2025-01-01T00:00:00Z",
        "current_period_end": "2025-02-01T00:00:00Z",
        "price_paid": 9.99,
        "currency": "USD",
        "canceled_at": None,
        "is_lifetime": False,
        "paused_at": now.isoformat(),
        "pause_resume_date": resume_date.isoformat(),
        "pause_duration_days": 14,
        "pause_reason": "vacation"
    }


@pytest.fixture
def sample_lifetime_subscription():
    """Sample lifetime subscription data."""
    return {
        "id": "sub-456",
        "user_id": "user-123-abc",
        "tier": "lifetime",
        "status": "active",
        "product_id": "lifetime",
        "is_trial": False,
        "is_lifetime": True,
        "price_paid": 149.99,
        "currency": "USD"
    }


@pytest.fixture
def sample_free_subscription():
    """Sample free tier data."""
    return {
        "id": "sub-789",
        "user_id": "user-123-abc",
        "tier": "free",
        "status": "active",
        "is_trial": False,
        "is_lifetime": False
    }


# ============================================================
# PAUSE SUBSCRIPTION TESTS
# ============================================================

class TestPauseSubscription:
    """Tests for the pause subscription endpoint."""

    @pytest.mark.asyncio
    async def test_pause_subscription_success(
        self, mock_supabase_client, mock_activity_logger,
        sample_user_id, sample_premium_subscription
    ):
        """Test successfully pausing a subscription."""
        from api.v1.subscriptions import pause_subscription, PauseSubscriptionRequest

        # Mock database responses
        mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(
            data=sample_premium_subscription
        )
        mock_supabase_client.table.return_value.update.return_value.eq.return_value.execute.return_value = MagicMock(data=[{}])
        mock_supabase_client.table.return_value.insert.return_value.execute.return_value = MagicMock(data=[{}])

        request = PauseSubscriptionRequest(duration_days=14, reason="vacation")
        result = await pause_subscription(sample_user_id, request)

        assert result.status == "paused"
        assert result.duration_days == 14
        assert "paused" in result.message.lower()
        assert result.user_id == sample_user_id

    @pytest.mark.asyncio
    async def test_pause_subscription_invalid_duration(
        self, mock_supabase_client, mock_activity_logger,
        sample_user_id, sample_premium_subscription
    ):
        """Test pausing with invalid duration fails."""
        from api.v1.subscriptions import pause_subscription, PauseSubscriptionRequest
        from fastapi import HTTPException

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(
            data=sample_premium_subscription
        )

        request = PauseSubscriptionRequest(duration_days=100)  # Invalid - max is 90

        with pytest.raises(HTTPException) as exc_info:
            await pause_subscription(sample_user_id, request)

        assert exc_info.value.status_code == 400
        assert "Invalid duration" in exc_info.value.detail

    @pytest.mark.asyncio
    async def test_pause_lifetime_subscription_fails(
        self, mock_supabase_client, mock_activity_logger,
        sample_user_id, sample_lifetime_subscription
    ):
        """Test that lifetime subscriptions cannot be paused."""
        from api.v1.subscriptions import pause_subscription, PauseSubscriptionRequest
        from fastapi import HTTPException

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(
            data=sample_lifetime_subscription
        )

        request = PauseSubscriptionRequest(duration_days=7)

        with pytest.raises(HTTPException) as exc_info:
            await pause_subscription(sample_user_id, request)

        assert exc_info.value.status_code == 400
        assert "Lifetime" in exc_info.value.detail or "lifetime" in exc_info.value.detail

    @pytest.mark.asyncio
    async def test_pause_free_subscription_fails(
        self, mock_supabase_client, mock_activity_logger,
        sample_user_id, sample_free_subscription
    ):
        """Test that free tier cannot be paused."""
        from api.v1.subscriptions import pause_subscription, PauseSubscriptionRequest
        from fastapi import HTTPException

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(
            data=sample_free_subscription
        )

        request = PauseSubscriptionRequest(duration_days=7)

        with pytest.raises(HTTPException) as exc_info:
            await pause_subscription(sample_user_id, request)

        assert exc_info.value.status_code == 400
        assert "Free" in exc_info.value.detail or "free" in exc_info.value.detail

    @pytest.mark.asyncio
    async def test_pause_already_paused_fails(
        self, mock_supabase_client, mock_activity_logger,
        sample_user_id, sample_paused_subscription
    ):
        """Test pausing an already paused subscription fails."""
        from api.v1.subscriptions import pause_subscription, PauseSubscriptionRequest
        from fastapi import HTTPException

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(
            data=sample_paused_subscription
        )

        request = PauseSubscriptionRequest(duration_days=7)

        with pytest.raises(HTTPException) as exc_info:
            await pause_subscription(sample_user_id, request)

        assert exc_info.value.status_code == 400
        assert "already paused" in exc_info.value.detail.lower()

    @pytest.mark.asyncio
    async def test_pause_no_subscription_fails(
        self, mock_supabase_client, mock_activity_logger,
        sample_user_id
    ):
        """Test pausing when no subscription exists fails."""
        from api.v1.subscriptions import pause_subscription, PauseSubscriptionRequest
        from fastapi import HTTPException

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(
            data=None
        )

        request = PauseSubscriptionRequest(duration_days=7)

        with pytest.raises(HTTPException) as exc_info:
            await pause_subscription(sample_user_id, request)

        assert exc_info.value.status_code == 404


# ============================================================
# RESUME SUBSCRIPTION TESTS
# ============================================================

class TestResumeSubscription:
    """Tests for the resume subscription endpoint."""

    @pytest.mark.asyncio
    async def test_resume_subscription_success(
        self, mock_supabase_client, mock_activity_logger,
        sample_user_id, sample_paused_subscription
    ):
        """Test successfully resuming a paused subscription."""
        from api.v1.subscriptions import resume_subscription

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(
            data=sample_paused_subscription
        )
        mock_supabase_client.table.return_value.update.return_value.eq.return_value.execute.return_value = MagicMock(data=[{}])
        mock_supabase_client.table.return_value.update.return_value.eq.return_value.eq.return_value.execute.return_value = MagicMock(data=[{}])
        mock_supabase_client.table.return_value.insert.return_value.execute.return_value = MagicMock(data=[{}])

        result = await resume_subscription(sample_user_id)

        assert result.status == "active"
        assert result.tier == "premium"
        assert "Welcome back" in result.message

    @pytest.mark.asyncio
    async def test_resume_not_paused_fails(
        self, mock_supabase_client, mock_activity_logger,
        sample_user_id, sample_premium_subscription
    ):
        """Test resuming a subscription that is not paused fails."""
        from api.v1.subscriptions import resume_subscription
        from fastapi import HTTPException

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(
            data=sample_premium_subscription  # status is "active", not "paused"
        )

        with pytest.raises(HTTPException) as exc_info:
            await resume_subscription(sample_user_id)

        assert exc_info.value.status_code == 400
        assert "not paused" in exc_info.value.detail.lower()

    @pytest.mark.asyncio
    async def test_resume_no_subscription_fails(
        self, mock_supabase_client, mock_activity_logger,
        sample_user_id
    ):
        """Test resuming when no subscription exists fails."""
        from api.v1.subscriptions import resume_subscription
        from fastapi import HTTPException

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(
            data=None
        )

        with pytest.raises(HTTPException) as exc_info:
            await resume_subscription(sample_user_id)

        assert exc_info.value.status_code == 404


# ============================================================
# RETENTION OFFERS TESTS
# ============================================================

class TestRetentionOffers:
    """Tests for the retention offers endpoint."""

    @pytest.mark.asyncio
    async def test_get_retention_offers_premium_user(
        self, mock_supabase_client, sample_user_id, sample_premium_subscription
    ):
        """Test getting retention offers for a premium user."""
        from api.v1.subscriptions import get_retention_offers

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(
            data=sample_premium_subscription
        )
        mock_supabase_client.table.return_value.select.return_value.eq.return_value.execute.return_value = MagicMock(
            data=[]  # No previous offers accepted
        )

        result = await get_retention_offers(sample_user_id, reason="too_expensive")

        assert result.user_id == sample_user_id
        assert len(result.offers) > 0
        assert result.cancellation_reason == "too_expensive"

        # Should include a pause offer
        pause_offers = [o for o in result.offers if o.type == "pause"]
        assert len(pause_offers) > 0

        # Should include a 50% discount for expensive complaint
        discount_offers = [o for o in result.offers if o.type == "discount"]
        assert len(discount_offers) > 0
        assert any(o.discount_percent == 50 for o in discount_offers)

    @pytest.mark.asyncio
    async def test_get_retention_offers_lifetime_returns_empty(
        self, mock_supabase_client, sample_user_id, sample_lifetime_subscription
    ):
        """Test that lifetime members get no retention offers."""
        from api.v1.subscriptions import get_retention_offers

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(
            data=sample_lifetime_subscription
        )

        result = await get_retention_offers(sample_user_id)

        assert result.user_id == sample_user_id
        assert len(result.offers) == 0

    @pytest.mark.asyncio
    async def test_get_retention_offers_no_subscription(
        self, mock_supabase_client, sample_user_id
    ):
        """Test getting offers when no subscription exists returns empty."""
        from api.v1.subscriptions import get_retention_offers

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(
            data=None
        )

        result = await get_retention_offers(sample_user_id)

        assert result.user_id == sample_user_id
        assert len(result.offers) == 0

    @pytest.mark.asyncio
    async def test_get_retention_offers_filters_previously_accepted(
        self, mock_supabase_client, sample_user_id, sample_premium_subscription
    ):
        """Test that previously accepted offers are filtered out."""
        from api.v1.subscriptions import get_retention_offers

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(
            data=sample_premium_subscription
        )
        mock_supabase_client.table.return_value.select.return_value.eq.return_value.execute.return_value = MagicMock(
            data=[{"offer_type": "pause"}]  # Already accepted pause offer
        )

        result = await get_retention_offers(sample_user_id)

        # Should not include pause offer since already accepted
        pause_offers = [o for o in result.offers if o.type == "pause"]
        assert len(pause_offers) == 0

    @pytest.mark.asyncio
    async def test_get_retention_offers_premium_plus_includes_downgrade(
        self, mock_supabase_client, sample_user_id
    ):
        """Test that premium plus users get downgrade offers."""
        from api.v1.subscriptions import get_retention_offers

        premium_plus_subscription = {
            "id": "sub-premium-plus",
            "user_id": sample_user_id,
            "tier": "premium_plus",
            "status": "active",
            "is_lifetime": False
        }

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(
            data=premium_plus_subscription
        )
        mock_supabase_client.table.return_value.select.return_value.eq.return_value.execute.return_value = MagicMock(
            data=[]
        )

        result = await get_retention_offers(sample_user_id)

        downgrade_offers = [o for o in result.offers if o.type == "downgrade"]
        assert len(downgrade_offers) > 0
        assert any(o.target_tier == "premium" for o in downgrade_offers)


# ============================================================
# ACCEPT OFFER TESTS
# ============================================================

class TestAcceptOffer:
    """Tests for the accept retention offer endpoint."""

    @pytest.mark.asyncio
    async def test_accept_discount_offer(
        self, mock_supabase_client, mock_activity_logger,
        sample_user_id, sample_premium_subscription
    ):
        """Test accepting a discount offer."""
        from api.v1.subscriptions import accept_retention_offer, AcceptOfferRequest

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(
            data=sample_premium_subscription
        )
        mock_supabase_client.table.return_value.insert.return_value.execute.return_value = MagicMock(data=[{}])

        request = AcceptOfferRequest(
            offer_id=f"discount_50_{sample_user_id}_12345",
            cancellation_reason="too_expensive"
        )
        result = await accept_retention_offer(sample_user_id, request)

        assert result.applied == True
        assert result.offer_type == "discount"
        assert result.discount_applied == 50
        assert "discount" in result.message.lower()

    @pytest.mark.asyncio
    async def test_accept_extension_offer(
        self, mock_supabase_client, mock_activity_logger,
        sample_user_id, sample_premium_subscription
    ):
        """Test accepting an extension offer."""
        from api.v1.subscriptions import accept_retention_offer, AcceptOfferRequest

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(
            data=sample_premium_subscription
        )
        mock_supabase_client.table.return_value.insert.return_value.execute.return_value = MagicMock(data=[{}])
        mock_supabase_client.table.return_value.update.return_value.eq.return_value.execute.return_value = MagicMock(data=[{}])

        request = AcceptOfferRequest(
            offer_id=f"extension_14_{sample_user_id}_12345",
            cancellation_reason="busy"
        )
        result = await accept_retention_offer(sample_user_id, request)

        assert result.applied == True
        assert result.offer_type == "extension"
        assert result.extension_days == 14
        assert "days" in result.message.lower()

    @pytest.mark.asyncio
    async def test_accept_downgrade_offer(
        self, mock_supabase_client, mock_activity_logger,
        sample_user_id
    ):
        """Test accepting a downgrade offer."""
        from api.v1.subscriptions import accept_retention_offer, AcceptOfferRequest

        premium_plus_subscription = {
            "id": "sub-premium-plus",
            "user_id": sample_user_id,
            "tier": "premium_plus",
            "status": "active"
        }

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(
            data=premium_plus_subscription
        )
        mock_supabase_client.table.return_value.insert.return_value.execute.return_value = MagicMock(data=[{}])
        mock_supabase_client.table.return_value.update.return_value.eq.return_value.execute.return_value = MagicMock(data=[{}])

        request = AcceptOfferRequest(
            offer_id=f"downgrade_premium_{sample_user_id}_12345"
        )
        result = await accept_retention_offer(sample_user_id, request)

        assert result.applied == True
        assert result.offer_type == "downgrade"
        assert result.new_tier == "premium"

    @pytest.mark.asyncio
    async def test_accept_invalid_offer_id_fails(
        self, mock_supabase_client, mock_activity_logger,
        sample_user_id, sample_premium_subscription
    ):
        """Test that invalid offer ID format fails."""
        from api.v1.subscriptions import accept_retention_offer, AcceptOfferRequest
        from fastapi import HTTPException

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(
            data=sample_premium_subscription
        )

        request = AcceptOfferRequest(offer_id="invalid")

        with pytest.raises(HTTPException) as exc_info:
            await accept_retention_offer(sample_user_id, request)

        assert exc_info.value.status_code == 400

    @pytest.mark.asyncio
    async def test_accept_unknown_offer_type_fails(
        self, mock_supabase_client, mock_activity_logger,
        sample_user_id, sample_premium_subscription
    ):
        """Test that unknown offer type fails."""
        from api.v1.subscriptions import accept_retention_offer, AcceptOfferRequest
        from fastapi import HTTPException

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(
            data=sample_premium_subscription
        )

        request = AcceptOfferRequest(offer_id=f"unknown_type_{sample_user_id}_12345")

        with pytest.raises(HTTPException) as exc_info:
            await accept_retention_offer(sample_user_id, request)

        assert exc_info.value.status_code == 400
        assert "Unknown offer type" in exc_info.value.detail

    @pytest.mark.asyncio
    async def test_accept_offer_no_subscription_fails(
        self, mock_supabase_client, mock_activity_logger,
        sample_user_id
    ):
        """Test accepting offer when no subscription exists fails."""
        from api.v1.subscriptions import accept_retention_offer, AcceptOfferRequest
        from fastapi import HTTPException

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(
            data=None
        )

        request = AcceptOfferRequest(offer_id=f"discount_25_{sample_user_id}_12345")

        with pytest.raises(HTTPException) as exc_info:
            await accept_retention_offer(sample_user_id, request)

        assert exc_info.value.status_code == 404


# ============================================================
# INTEGRATION TESTS
# ============================================================

class TestPauseResumeFlow:
    """Integration tests for pause/resume flow."""

    @pytest.mark.asyncio
    async def test_pause_and_resume_flow(
        self, mock_supabase_client, mock_activity_logger,
        sample_user_id, sample_premium_subscription
    ):
        """Test the full pause and resume flow."""
        from api.v1.subscriptions import pause_subscription, resume_subscription, PauseSubscriptionRequest

        # Step 1: Pause the subscription
        mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(
            data=sample_premium_subscription
        )
        mock_supabase_client.table.return_value.update.return_value.eq.return_value.execute.return_value = MagicMock(data=[{}])
        mock_supabase_client.table.return_value.insert.return_value.execute.return_value = MagicMock(data=[{}])

        pause_request = PauseSubscriptionRequest(duration_days=14, reason="travel")
        pause_result = await pause_subscription(sample_user_id, pause_request)

        assert pause_result.status == "paused"
        assert pause_result.duration_days == 14

        # Step 2: Resume the subscription (simulate paused state)
        paused_sub = sample_premium_subscription.copy()
        paused_sub["status"] = "paused"
        paused_sub["paused_at"] = datetime.utcnow().isoformat()
        paused_sub["pause_resume_date"] = (datetime.utcnow() + timedelta(days=14)).isoformat()

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(
            data=paused_sub
        )
        mock_supabase_client.table.return_value.update.return_value.eq.return_value.eq.return_value.execute.return_value = MagicMock(data=[{}])

        resume_result = await resume_subscription(sample_user_id)

        assert resume_result.status == "active"
        assert resume_result.tier == "premium"


class TestRetentionFlow:
    """Integration tests for retention offer flow."""

    @pytest.mark.asyncio
    async def test_get_and_accept_offer_flow(
        self, mock_supabase_client, mock_activity_logger,
        sample_user_id, sample_premium_subscription
    ):
        """Test getting offers and accepting one."""
        from api.v1.subscriptions import get_retention_offers, accept_retention_offer, AcceptOfferRequest

        # Step 1: Get available offers
        mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(
            data=sample_premium_subscription
        )
        mock_supabase_client.table.return_value.select.return_value.eq.return_value.execute.return_value = MagicMock(
            data=[]
        )

        offers_result = await get_retention_offers(sample_user_id, reason="too_expensive")

        assert len(offers_result.offers) > 0
        discount_offer = next((o for o in offers_result.offers if o.type == "discount"), None)
        assert discount_offer is not None

        # Step 2: Accept the discount offer
        mock_supabase_client.table.return_value.insert.return_value.execute.return_value = MagicMock(data=[{}])

        accept_request = AcceptOfferRequest(
            offer_id=discount_offer.id,
            cancellation_reason="too_expensive"
        )
        accept_result = await accept_retention_offer(sample_user_id, accept_request)

        assert accept_result.applied == True
        assert accept_result.offer_type == "discount"


# ============================================================
# VALID DURATION TESTS
# ============================================================

class TestValidDurations:
    """Test all valid pause durations."""

    @pytest.mark.asyncio
    @pytest.mark.parametrize("duration", [7, 14, 30, 60, 90])
    async def test_valid_pause_durations(
        self, mock_supabase_client, mock_activity_logger,
        sample_user_id, sample_premium_subscription, duration
    ):
        """Test that all valid durations work."""
        from api.v1.subscriptions import pause_subscription, PauseSubscriptionRequest

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(
            data=sample_premium_subscription
        )
        mock_supabase_client.table.return_value.update.return_value.eq.return_value.execute.return_value = MagicMock(data=[{}])
        mock_supabase_client.table.return_value.insert.return_value.execute.return_value = MagicMock(data=[{}])

        request = PauseSubscriptionRequest(duration_days=duration)
        result = await pause_subscription(sample_user_id, request)

        assert result.status == "paused"
        assert result.duration_days == duration

    @pytest.mark.asyncio
    @pytest.mark.parametrize("duration", [1, 5, 10, 21, 45, 100, 365])
    async def test_invalid_pause_durations(
        self, mock_supabase_client, mock_activity_logger,
        sample_user_id, sample_premium_subscription, duration
    ):
        """Test that invalid durations are rejected."""
        from api.v1.subscriptions import pause_subscription, PauseSubscriptionRequest
        from fastapi import HTTPException

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(
            data=sample_premium_subscription
        )

        request = PauseSubscriptionRequest(duration_days=duration)

        with pytest.raises(HTTPException) as exc_info:
            await pause_subscription(sample_user_id, request)

        assert exc_info.value.status_code == 400


# ============================================================
# RUN TESTS
# ============================================================

if __name__ == "__main__":
    pytest.main([__file__, "-v"])
