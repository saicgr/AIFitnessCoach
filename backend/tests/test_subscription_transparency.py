"""
Tests for Subscription Transparency API endpoints.

Tests:
- Get subscription history
- Get upcoming renewal info
- Submit refund requests
- Get refund request status

These endpoints address the complaint:
"Tried to automatically put me in a more expensive tier"

Run with: pytest backend/tests/test_subscription_transparency.py -v
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
def sample_subscription():
    """Sample subscription data."""
    return {
        "id": "sub-123",
        "user_id": "user-123-abc",
        "tier": "premium",
        "status": "active",
        "product_id": "premium_yearly",
        "is_trial": False,
        "trial_end_date": None,
        "current_period_start": "2025-01-01T00:00:00Z",
        "current_period_end": "2026-01-01T00:00:00Z",
        "price_paid": 79.99,
        "currency": "USD",
        "canceled_at": None,
        "expires_at": None
    }


@pytest.fixture
def sample_subscription_history():
    """Sample subscription history events."""
    return [
        {
            "id": "hist-1",
            "user_id": "user-123-abc",
            "event_type": "purchased",
            "previous_tier": None,
            "new_tier": "premium",
            "product_id": "premium_yearly",
            "price": 79.99,
            "currency": "USD",
            "created_at": "2025-01-01T10:00:00Z",
            "metadata": {}
        },
        {
            "id": "hist-2",
            "user_id": "user-123-abc",
            "event_type": "renewed",
            "previous_tier": None,
            "new_tier": None,
            "product_id": "premium_yearly",
            "price": 79.99,
            "currency": "USD",
            "created_at": "2024-01-01T10:00:00Z",
            "metadata": {}
        }
    ]


@pytest.fixture
def sample_refund_request():
    """Sample refund request data."""
    return {
        "id": "refund-123",
        "user_id": "user-123-abc",
        "subscription_id": "sub-123",
        "tracking_id": "RF-20250130-ABC12",
        "reason": "Was upgraded without my consent",
        "additional_details": "I only wanted the free tier",
        "status": "pending",
        "amount": 79.99,
        "currency": "USD",
        "created_at": "2025-01-30T12:00:00Z",
        "updated_at": "2025-01-30T12:00:00Z",
        "processed_at": None
    }


# ============================================================
# SUBSCRIPTION HISTORY TESTS
# ============================================================

class TestSubscriptionHistory:
    """Test subscription history endpoint."""

    def test_get_subscription_history_success(
        self, mock_supabase_client, mock_activity_logger, sample_user_id, sample_subscription_history
    ):
        """Test getting subscription history successfully."""
        from api.v1.subscriptions import get_subscription_history

        # Mock count query
        mock_count_result = MagicMock()
        mock_count_result.count = 2

        # Mock history query
        mock_history_result = MagicMock()
        mock_history_result.data = sample_subscription_history

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_count_result
        mock_supabase_client.table.return_value.select.return_value.eq.return_value.order.return_value.range.return_value.execute.return_value = mock_history_result

        result = asyncio.get_event_loop().run_until_complete(
            get_subscription_history(sample_user_id)
        )

        assert result.user_id == sample_user_id
        assert len(result.events) == 2
        assert result.events[0].event_type == "purchased"
        assert result.events[0].event_description == "Subscribed to premium"
        assert result.events[0].price == 79.99
        assert result.events[0].price_display == "USD 79.99"

    def test_get_subscription_history_empty(
        self, mock_supabase_client, mock_activity_logger, sample_user_id
    ):
        """Test getting subscription history when no history exists."""
        from api.v1.subscriptions import get_subscription_history

        mock_count_result = MagicMock()
        mock_count_result.count = 0

        mock_history_result = MagicMock()
        mock_history_result.data = []

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_count_result
        mock_supabase_client.table.return_value.select.return_value.eq.return_value.order.return_value.range.return_value.execute.return_value = mock_history_result

        result = asyncio.get_event_loop().run_until_complete(
            get_subscription_history(sample_user_id)
        )

        assert result.user_id == sample_user_id
        assert len(result.events) == 0
        assert result.total_count == 0

    def test_get_subscription_history_with_pagination(
        self, mock_supabase_client, mock_activity_logger, sample_user_id
    ):
        """Test subscription history with pagination."""
        from api.v1.subscriptions import get_subscription_history

        mock_count_result = MagicMock()
        mock_count_result.count = 100

        mock_history_result = MagicMock()
        mock_history_result.data = [
            {
                "id": "hist-50",
                "user_id": sample_user_id,
                "event_type": "renewed",
                "previous_tier": None,
                "new_tier": None,
                "product_id": "premium_yearly",
                "price": 79.99,
                "currency": "USD",
                "created_at": "2024-06-01T10:00:00Z",
                "metadata": {}
            }
        ]

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_count_result
        mock_supabase_client.table.return_value.select.return_value.eq.return_value.order.return_value.range.return_value.execute.return_value = mock_history_result

        result = asyncio.get_event_loop().run_until_complete(
            get_subscription_history(sample_user_id, limit=10, offset=50)
        )

        assert result.total_count == 100
        assert len(result.events) == 1

    def test_get_subscription_history_error(
        self, mock_supabase_client, mock_activity_logger, sample_user_id
    ):
        """Test subscription history error handling."""
        from api.v1.subscriptions import get_subscription_history
        from fastapi import HTTPException

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.execute.side_effect = Exception("Database error")

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                get_subscription_history(sample_user_id)
            )

        assert exc_info.value.status_code == 500


# ============================================================
# UPCOMING RENEWAL TESTS
# ============================================================

class TestUpcomingRenewal:
    """Test upcoming renewal endpoint."""

    def test_get_upcoming_renewal_success(
        self, mock_supabase_client, sample_user_id, sample_subscription
    ):
        """Test getting upcoming renewal info successfully."""
        from api.v1.subscriptions import get_upcoming_renewal

        mock_result = MagicMock()
        mock_result.data = sample_subscription

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = mock_result

        result = asyncio.get_event_loop().run_until_complete(
            get_upcoming_renewal(sample_user_id)
        )

        assert result.user_id == sample_user_id
        assert result.tier == "premium"
        assert result.status == "active"
        assert result.current_price == 79.99
        assert result.currency == "USD"
        assert result.renewal_status_message == "Subscription will auto-renew"
        assert result.will_cancel is False

    def test_get_upcoming_renewal_trial(
        self, mock_supabase_client, sample_user_id
    ):
        """Test getting renewal info during trial."""
        from api.v1.subscriptions import get_upcoming_renewal

        trial_sub = {
            "id": "sub-123",
            "user_id": sample_user_id,
            "tier": "premium",
            "status": "trial",
            "is_trial": True,
            "trial_end_date": "2025-02-15T00:00:00Z",
            "current_period_end": "2025-02-15T00:00:00Z",
            "price_paid": 79.99,
            "currency": "USD",
            "canceled_at": None
        }

        mock_result = MagicMock()
        mock_result.data = trial_sub

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = mock_result

        result = asyncio.get_event_loop().run_until_complete(
            get_upcoming_renewal(sample_user_id)
        )

        assert result.is_trial is True
        assert result.renewal_status_message == "Your trial ends and billing starts"

    def test_get_upcoming_renewal_canceled(
        self, mock_supabase_client, sample_user_id
    ):
        """Test getting renewal info for canceled subscription."""
        from api.v1.subscriptions import get_upcoming_renewal

        canceled_sub = {
            "id": "sub-123",
            "user_id": sample_user_id,
            "tier": "premium",
            "status": "canceled",
            "is_trial": False,
            "current_period_end": "2025-02-01T00:00:00Z",
            "canceled_at": "2025-01-15T00:00:00Z",
            "expires_at": "2025-02-01T00:00:00Z",
            "price_paid": 79.99,
            "currency": "USD"
        }

        mock_result = MagicMock()
        mock_result.data = canceled_sub

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = mock_result

        result = asyncio.get_event_loop().run_until_complete(
            get_upcoming_renewal(sample_user_id)
        )

        assert result.will_cancel is True
        assert result.renewal_status_message == "Subscription will end (canceled)"

    def test_get_upcoming_renewal_no_subscription(
        self, mock_supabase_client, sample_user_id
    ):
        """Test getting renewal info for user with no subscription."""
        from api.v1.subscriptions import get_upcoming_renewal

        mock_result = MagicMock()
        mock_result.data = None

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = mock_result

        result = asyncio.get_event_loop().run_until_complete(
            get_upcoming_renewal(sample_user_id)
        )

        assert result.tier == "free"
        assert result.status == "active"
        assert result.renewal_status_message == "No active subscription - using free tier"
        assert result.days_until_renewal == 0

    def test_get_upcoming_renewal_grace_period(
        self, mock_supabase_client, sample_user_id
    ):
        """Test getting renewal info during grace period."""
        from api.v1.subscriptions import get_upcoming_renewal

        grace_sub = {
            "id": "sub-123",
            "user_id": sample_user_id,
            "tier": "premium",
            "status": "grace_period",
            "is_trial": False,
            "current_period_end": "2025-01-25T00:00:00Z",
            "canceled_at": None,
            "price_paid": 79.99,
            "currency": "USD"
        }

        mock_result = MagicMock()
        mock_result.data = grace_sub

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = mock_result

        result = asyncio.get_event_loop().run_until_complete(
            get_upcoming_renewal(sample_user_id)
        )

        assert result.status == "grace_period"
        assert result.renewal_status_message == "Payment required to continue"

    def test_get_upcoming_renewal_error(
        self, mock_supabase_client, sample_user_id
    ):
        """Test upcoming renewal error handling."""
        from api.v1.subscriptions import get_upcoming_renewal
        from fastapi import HTTPException

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.side_effect = Exception("Database error")

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                get_upcoming_renewal(sample_user_id)
            )

        assert exc_info.value.status_code == 500


# ============================================================
# REFUND REQUEST TESTS
# ============================================================

class TestRefundRequest:
    """Test refund request endpoint."""

    def test_request_refund_success(
        self, mock_supabase_client, mock_activity_logger, sample_user_id, sample_subscription, sample_refund_request
    ):
        """Test submitting a refund request successfully."""
        from api.v1.subscriptions import request_refund, RefundRequest

        # Mock subscription query
        mock_sub_result = MagicMock()
        mock_sub_result.data = {
            "id": "sub-123",
            "tier": "premium",
            "price_paid": 79.99,
            "currency": "USD",
            "product_id": "premium_yearly"
        }

        # Mock refund insert
        mock_refund_result = MagicMock()
        mock_refund_result.data = [sample_refund_request]

        # Mock history insert
        mock_history_result = MagicMock()
        mock_history_result.data = [{"id": "hist-new"}]

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = mock_sub_result
        mock_supabase_client.table.return_value.insert.return_value.execute.return_value = mock_refund_result

        request = RefundRequest(
            reason="Was upgraded without my consent",
            additional_details="I only wanted the free tier"
        )

        result = asyncio.get_event_loop().run_until_complete(
            request_refund(sample_user_id, request)
        )

        assert result.tracking_id == "RF-20250130-ABC12"
        assert result.status.value == "pending"
        assert result.amount == 79.99
        assert "tracking ID" in result.message
        assert "2-3 business days" in result.message

    def test_request_refund_no_subscription(
        self, mock_supabase_client, mock_activity_logger, sample_user_id
    ):
        """Test submitting a refund request without an active subscription."""
        from api.v1.subscriptions import request_refund, RefundRequest

        # Mock no subscription found
        mock_sub_result = MagicMock()
        mock_sub_result.data = None

        # Mock refund insert
        mock_refund_result = MagicMock()
        mock_refund_result.data = [{
            "id": "refund-456",
            "user_id": sample_user_id,
            "tracking_id": "RF-20250130-DEF34",
            "status": "pending",
            "amount": None,
            "currency": "USD",
            "created_at": "2025-01-30T12:00:00Z"
        }]

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = mock_sub_result
        mock_supabase_client.table.return_value.insert.return_value.execute.return_value = mock_refund_result

        request = RefundRequest(reason="Charge appeared on my account")

        result = asyncio.get_event_loop().run_until_complete(
            request_refund(sample_user_id, request)
        )

        # Should still create request even without subscription
        assert result.tracking_id is not None
        assert result.amount is None

    def test_request_refund_database_error(
        self, mock_supabase_client, mock_activity_logger, sample_user_id
    ):
        """Test refund request with database error."""
        from api.v1.subscriptions import request_refund, RefundRequest
        from fastapi import HTTPException

        mock_sub_result = MagicMock()
        mock_sub_result.data = {"id": "sub-123", "price_paid": 79.99, "currency": "USD"}

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = mock_sub_result
        mock_supabase_client.table.return_value.insert.return_value.execute.side_effect = Exception("Insert failed")

        request = RefundRequest(reason="Test refund")

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                request_refund(sample_user_id, request)
            )

        assert exc_info.value.status_code == 500


# ============================================================
# GET REFUND REQUESTS TESTS
# ============================================================

class TestGetRefundRequests:
    """Test get refund requests endpoint."""

    def test_get_refund_requests_success(
        self, mock_supabase_client, sample_user_id, sample_refund_request
    ):
        """Test getting user's refund requests."""
        from api.v1.subscriptions import get_refund_requests

        mock_result = MagicMock()
        mock_result.data = [sample_refund_request]

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value = mock_result

        result = asyncio.get_event_loop().run_until_complete(
            get_refund_requests(sample_user_id)
        )

        assert len(result) == 1
        assert result[0].tracking_id == "RF-20250130-ABC12"
        assert result[0].reason == "Was upgraded without my consent"
        assert result[0].status.value == "pending"

    def test_get_refund_requests_empty(
        self, mock_supabase_client, sample_user_id
    ):
        """Test getting refund requests when none exist."""
        from api.v1.subscriptions import get_refund_requests

        mock_result = MagicMock()
        mock_result.data = []

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value = mock_result

        result = asyncio.get_event_loop().run_until_complete(
            get_refund_requests(sample_user_id)
        )

        assert len(result) == 0

    def test_get_refund_requests_multiple_statuses(
        self, mock_supabase_client, sample_user_id
    ):
        """Test getting refund requests with various statuses."""
        from api.v1.subscriptions import get_refund_requests

        mock_result = MagicMock()
        mock_result.data = [
            {
                "id": "refund-1",
                "tracking_id": "RF-20250130-001",
                "reason": "First request",
                "status": "processed",
                "amount": 79.99,
                "currency": "USD",
                "created_at": "2025-01-30T12:00:00Z",
                "updated_at": "2025-01-31T12:00:00Z",
                "processed_at": "2025-01-31T12:00:00Z"
            },
            {
                "id": "refund-2",
                "tracking_id": "RF-20250130-002",
                "reason": "Second request",
                "status": "pending",
                "amount": 9.99,
                "currency": "USD",
                "created_at": "2025-01-30T14:00:00Z",
                "updated_at": "2025-01-30T14:00:00Z",
                "processed_at": None
            }
        ]

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value = mock_result

        result = asyncio.get_event_loop().run_until_complete(
            get_refund_requests(sample_user_id)
        )

        assert len(result) == 2
        assert result[0].status.value == "processed"
        assert result[0].processed_at is not None
        assert result[1].status.value == "pending"
        assert result[1].processed_at is None


# ============================================================
# MODEL VALIDATION TESTS
# ============================================================

class TestTransparencyModels:
    """Test Pydantic model validation."""

    def test_subscription_history_event_model(self):
        """Test SubscriptionHistoryEvent model."""
        from api.v1.subscriptions import SubscriptionHistoryEvent

        event = SubscriptionHistoryEvent(
            id="hist-123",
            event_type="purchased",
            event_description="Subscribed to premium",
            created_at="2025-01-01T10:00:00Z",
            new_tier="premium",
            price=79.99,
            currency="USD",
            price_display="USD 79.99"
        )

        assert event.event_type == "purchased"
        assert event.new_tier == "premium"
        assert event.previous_tier is None

    def test_upcoming_renewal_response_model(self):
        """Test UpcomingRenewalResponse model."""
        from api.v1.subscriptions import UpcomingRenewalResponse

        response = UpcomingRenewalResponse(
            user_id="user-123",
            tier="premium",
            status="active",
            renewal_status_message="Subscription will auto-renew",
            days_until_renewal=30
        )

        assert response.tier == "premium"
        assert response.will_cancel is False
        assert response.is_trial is False

    def test_refund_request_model(self):
        """Test RefundRequest model."""
        from api.v1.subscriptions import RefundRequest

        request = RefundRequest(
            reason="Unauthorized charge",
            additional_details="I did not approve this"
        )

        assert request.reason == "Unauthorized charge"
        assert request.additional_details is not None

    def test_refund_request_minimal(self):
        """Test RefundRequest model with minimal fields."""
        from api.v1.subscriptions import RefundRequest

        request = RefundRequest(reason="I want a refund")

        assert request.reason == "I want a refund"
        assert request.additional_details is None

    def test_refund_request_response_model(self):
        """Test RefundRequestResponse model."""
        from api.v1.subscriptions import RefundRequestResponse, RefundStatus

        response = RefundRequestResponse(
            id="refund-123",
            tracking_id="RF-20250130-ABC",
            status=RefundStatus.pending,
            amount=79.99,
            currency="USD",
            created_at="2025-01-30T12:00:00Z",
            message="Your request has been submitted."
        )

        assert response.tracking_id.startswith("RF-")
        assert response.status == RefundStatus.pending

    def test_refund_status_enum(self):
        """Test RefundStatus enum values."""
        from api.v1.subscriptions import RefundStatus

        assert RefundStatus.pending.value == "pending"
        assert RefundStatus.approved.value == "approved"
        assert RefundStatus.denied.value == "denied"
        assert RefundStatus.processed.value == "processed"


# ============================================================
# INTEGRATION SCENARIO TESTS
# ============================================================

class TestTransparencyScenarios:
    """Test real-world subscription transparency scenarios."""

    def test_user_checking_unwanted_upgrade(
        self, mock_supabase_client, mock_activity_logger, sample_user_id
    ):
        """
        Scenario: User was upgraded without consent and wants to verify.
        They should be able to see the history and request a refund.
        """
        from api.v1.subscriptions import get_subscription_history

        # History shows an unwanted upgrade
        history_data = [
            {
                "id": "hist-1",
                "user_id": sample_user_id,
                "event_type": "upgraded",
                "previous_tier": "free",
                "new_tier": "premium_plus",
                "product_id": "premium_plus_yearly",
                "price": 199.99,
                "currency": "USD",
                "created_at": "2025-01-15T10:00:00Z",
                "metadata": {}
            }
        ]

        mock_count = MagicMock()
        mock_count.count = 1
        mock_history = MagicMock()
        mock_history.data = history_data

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_count
        mock_supabase_client.table.return_value.select.return_value.eq.return_value.order.return_value.range.return_value.execute.return_value = mock_history

        result = asyncio.get_event_loop().run_until_complete(
            get_subscription_history(sample_user_id)
        )

        # User can see the unwanted upgrade
        assert result.events[0].event_type == "upgraded"
        assert result.events[0].event_description == "Upgraded from free to premium_plus"
        assert result.events[0].price == 199.99

    def test_user_checking_before_renewal(
        self, mock_supabase_client, sample_user_id
    ):
        """
        Scenario: User wants to check what they'll be charged at renewal.
        """
        from api.v1.subscriptions import get_upcoming_renewal

        # Active subscription renewing soon
        sub_data = {
            "id": "sub-123",
            "user_id": sample_user_id,
            "tier": "premium",
            "status": "active",
            "product_id": "premium_yearly",
            "is_trial": False,
            "current_period_end": (datetime.utcnow() + timedelta(days=7)).isoformat() + "Z",
            "price_paid": 79.99,
            "currency": "USD",
            "canceled_at": None
        }

        mock_result = MagicMock()
        mock_result.data = sub_data

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = mock_result

        result = asyncio.get_event_loop().run_until_complete(
            get_upcoming_renewal(sample_user_id)
        )

        # User can see upcoming charge details
        assert result.current_price == 79.99
        assert result.renewal_status_message == "Subscription will auto-renew"
        assert result.days_until_renewal >= 0


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
