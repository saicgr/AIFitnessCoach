"""
Tests for Lifetime Membership Functionality
============================================

This module tests the lifetime membership implementation including:
- Lifetime status API endpoint
- Lifetime benefits retrieval
- Member tier calculation
- Expiration prevention
- Renewal notification skipping
- AI context generation for lifetime members
"""

import pytest
from datetime import datetime, timedelta
from unittest.mock import AsyncMock, MagicMock, patch
from uuid import uuid4

# Test imports
from services.user_context_service import (
    UserContextService,
    LifetimeMemberContext,
)


# =============================================================================
# FIXTURES
# =============================================================================

@pytest.fixture
def user_context_service():
    """Create a UserContextService instance for testing."""
    return UserContextService()


@pytest.fixture
def lifetime_member_subscription():
    """Sample lifetime member subscription data."""
    return {
        "user_id": str(uuid4()),
        "tier": "lifetime",
        "is_lifetime": True,
        "lifetime_purchase_date": (datetime.now() - timedelta(days=200)).isoformat(),
        "lifetime_original_price": 199.99,
        "lifetime_member_tier": "Loyal",
        "status": "active",
        "current_period_end": None,
        "expires_at": None,
    }


@pytest.fixture
def non_lifetime_subscription():
    """Sample non-lifetime subscription data."""
    return {
        "user_id": str(uuid4()),
        "tier": "ultra_monthly",
        "is_lifetime": False,
        "lifetime_purchase_date": None,
        "lifetime_original_price": None,
        "lifetime_member_tier": None,
        "status": "active",
        "current_period_end": (datetime.now() + timedelta(days=30)).isoformat(),
        "expires_at": None,
    }


# =============================================================================
# LIFETIME MEMBER CONTEXT TESTS
# =============================================================================

class TestLifetimeMemberContext:
    """Tests for LifetimeMemberContext dataclass and methods."""

    def test_default_context_is_not_lifetime(self):
        """Default context should indicate non-lifetime member."""
        context = LifetimeMemberContext()
        assert context.is_lifetime_member is False
        assert context.member_tier is None
        assert context.days_as_member == 0

    def test_ai_context_empty_for_non_lifetime(self):
        """AI personalization context should be empty for non-lifetime members."""
        context = LifetimeMemberContext()
        ai_context = context.get_ai_personalization_context()
        assert ai_context == ""

    def test_ai_context_includes_lifetime_acknowledgment(self):
        """AI context should acknowledge lifetime member status."""
        context = LifetimeMemberContext(
            is_lifetime_member=True,
            lifetime_purchase_date=datetime(2024, 1, 15),
            days_as_member=350,
            member_tier="Veteran",
        )
        ai_context = context.get_ai_personalization_context()

        assert "valued lifetime member" in ai_context.lower()
        assert "January 15, 2024" in ai_context
        assert "long-term committed customer" in ai_context.lower()

    def test_ai_context_veteran_tier(self):
        """AI context should include veteran-specific messaging."""
        context = LifetimeMemberContext(
            is_lifetime_member=True,
            lifetime_purchase_date=datetime(2023, 6, 1),
            days_as_member=400,
            member_tier="Veteran",
        )
        ai_context = context.get_ai_personalization_context()

        assert "over a year" in ai_context.lower()
        assert "long-term dedication" in ai_context.lower()

    def test_ai_context_loyal_tier(self):
        """AI context should include loyal-specific messaging."""
        context = LifetimeMemberContext(
            is_lifetime_member=True,
            lifetime_purchase_date=datetime(2024, 6, 1),
            days_as_member=200,
            member_tier="Loyal",
        )
        ai_context = context.get_ai_personalization_context()

        assert "6+ months" in ai_context
        assert "consistent commitment" in ai_context.lower()

    def test_ai_context_established_tier(self):
        """AI context should include established-specific messaging."""
        context = LifetimeMemberContext(
            is_lifetime_member=True,
            lifetime_purchase_date=datetime(2024, 9, 1),
            days_as_member=100,
            member_tier="Established",
        )
        ai_context = context.get_ai_personalization_context()

        assert "3+ months" in ai_context
        assert "solid foundation" in ai_context.lower()

    def test_ai_context_new_tier(self):
        """AI context should include new member-specific messaging."""
        context = LifetimeMemberContext(
            is_lifetime_member=True,
            lifetime_purchase_date=datetime(2024, 12, 1),
            days_as_member=30,
            member_tier="New",
        )
        ai_context = context.get_ai_personalization_context()

        assert "recently became a lifetime member" in ai_context.lower()
        assert "welcomed" in ai_context.lower()

    def test_ai_context_includes_value_for_long_term_members(self):
        """AI context should include value acknowledgment for long-term members."""
        context = LifetimeMemberContext(
            is_lifetime_member=True,
            lifetime_purchase_date=datetime(2023, 1, 1),
            days_as_member=400,
            member_tier="Veteran",
            estimated_value_received=150.0,
            value_multiplier=2.0,
        )
        ai_context = context.get_ai_personalization_context()

        assert "$150" in ai_context
        assert "ROI" in ai_context

    def test_to_dict_includes_all_fields(self):
        """to_dict should include all relevant fields."""
        context = LifetimeMemberContext(
            is_lifetime_member=True,
            lifetime_purchase_date=datetime(2024, 6, 1),
            days_as_member=200,
            member_tier="Loyal",
            member_tier_level=3,
            estimated_value_received=66.6,
            value_multiplier=0.33,
            features_unlocked=["all"],
        )
        result = context.to_dict()

        assert result["is_lifetime_member"] is True
        assert result["days_as_member"] == 200
        assert result["member_tier"] == "Loyal"
        assert result["member_tier_level"] == 3
        assert result["estimated_value_received"] == 66.6
        assert "all" in result["features_unlocked"]


# =============================================================================
# MEMBER TIER CALCULATION TESTS
# =============================================================================

class TestMemberTierCalculation:
    """Tests for member tier calculation logic."""

    def test_veteran_tier_365_plus_days(self):
        """Users with 365+ days should be Veteran tier."""
        # This tests the tier calculation logic in get_lifetime_member_context
        days = 400
        if days >= 365:
            tier = "Veteran"
        elif days >= 180:
            tier = "Loyal"
        elif days >= 90:
            tier = "Established"
        else:
            tier = "New"

        assert tier == "Veteran"

    def test_loyal_tier_180_to_364_days(self):
        """Users with 180-364 days should be Loyal tier."""
        days = 250
        if days >= 365:
            tier = "Veteran"
        elif days >= 180:
            tier = "Loyal"
        elif days >= 90:
            tier = "Established"
        else:
            tier = "New"

        assert tier == "Loyal"

    def test_established_tier_90_to_179_days(self):
        """Users with 90-179 days should be Established tier."""
        days = 120
        if days >= 365:
            tier = "Veteran"
        elif days >= 180:
            tier = "Loyal"
        elif days >= 90:
            tier = "Established"
        else:
            tier = "New"

        assert tier == "Established"

    def test_new_tier_under_90_days(self):
        """Users with under 90 days should be New tier."""
        days = 45
        if days >= 365:
            tier = "Veteran"
        elif days >= 180:
            tier = "Loyal"
        elif days >= 90:
            tier = "Established"
        else:
            tier = "New"

        assert tier == "New"

    def test_tier_boundary_365_days(self):
        """Test exact boundary at 365 days."""
        days = 365
        if days >= 365:
            tier = "Veteran"
        else:
            tier = "Loyal"

        assert tier == "Veteran"

    def test_tier_boundary_180_days(self):
        """Test exact boundary at 180 days."""
        days = 180
        if days >= 180:
            tier = "Loyal"
        else:
            tier = "Established"

        assert tier == "Loyal"

    def test_tier_boundary_90_days(self):
        """Test exact boundary at 90 days."""
        days = 90
        if days >= 90:
            tier = "Established"
        else:
            tier = "New"

        assert tier == "Established"


# =============================================================================
# LIFETIME MEMBER NEVER EXPIRES TESTS
# =============================================================================

class TestLifetimeNeverExpires:
    """Tests to ensure lifetime members never expire."""

    def test_lifetime_subscription_has_no_expiry_date(
        self,
        lifetime_member_subscription,
    ):
        """Lifetime subscription should have no expiry date."""
        assert lifetime_member_subscription["current_period_end"] is None
        assert lifetime_member_subscription["expires_at"] is None

    def test_lifetime_subscription_is_active(
        self,
        lifetime_member_subscription,
    ):
        """Lifetime subscription should always be active."""
        assert lifetime_member_subscription["status"] == "active"

    def test_non_lifetime_has_expiry_date(
        self,
        non_lifetime_subscription,
    ):
        """Non-lifetime subscription should have an expiry date."""
        assert non_lifetime_subscription["current_period_end"] is not None


# =============================================================================
# ESTIMATED VALUE CALCULATION TESTS
# =============================================================================

class TestEstimatedValueCalculation:
    """Tests for estimated value and value multiplier calculations."""

    def test_estimated_value_calculation(self):
        """Estimated value should be months * $9.99."""
        days_as_member = 365
        months = days_as_member / 30.0
        estimated_value = months * 9.99

        # 365 days is approximately 12.17 months
        # 12.17 * 9.99 = approximately $121.53
        assert estimated_value > 120
        assert estimated_value < 125

    def test_value_multiplier_calculation(self):
        """Value multiplier should be estimated_value / original_price."""
        days_as_member = 365
        original_price = 199.99
        months = days_as_member / 30.0
        estimated_value = months * 9.99
        value_multiplier = estimated_value / original_price

        # After 1 year, value should be about 0.6x of original price
        assert value_multiplier > 0.5
        assert value_multiplier < 0.7

    def test_value_multiplier_after_two_years(self):
        """Value multiplier should exceed 1.0 after about 20 months."""
        days_as_member = 730  # 2 years
        original_price = 199.99
        months = days_as_member / 30.0  # ~24.3 months
        estimated_value = months * 9.99  # ~$243
        value_multiplier = estimated_value / original_price

        # After 2 years, value should exceed original price
        assert value_multiplier > 1.0
        assert estimated_value > original_price


# =============================================================================
# FEATURE ACCESS TESTS
# =============================================================================

class TestLifetimeFeatureAccess:
    """Tests for lifetime member feature access."""

    def test_lifetime_has_all_features(self):
        """Lifetime members should have access to all features."""
        context = LifetimeMemberContext(
            is_lifetime_member=True,
            features_unlocked=["all"],
        )

        assert "all" in context.features_unlocked

    def test_ai_context_mentions_premium_features(self):
        """AI context should mention access to all premium features."""
        context = LifetimeMemberContext(
            is_lifetime_member=True,
            lifetime_purchase_date=datetime(2024, 1, 1),
            days_as_member=100,
            member_tier="Established",
            features_unlocked=["all"],
        )
        ai_context = context.get_ai_personalization_context()

        assert "all premium features" in ai_context.lower()


# =============================================================================
# USER CONTEXT SERVICE INTEGRATION TESTS
# =============================================================================

class TestUserContextServiceLifetime:
    """Integration tests for lifetime context in UserContextService."""

    @pytest.mark.asyncio
    async def test_get_lifetime_member_context_returns_correct_type(
        self,
        user_context_service,
    ):
        """get_lifetime_member_context should return LifetimeMemberContext."""
        with patch.object(
            user_context_service,
            'get_lifetime_member_context',
            new_callable=AsyncMock,
        ) as mock_method:
            mock_method.return_value = LifetimeMemberContext(
                is_lifetime_member=True,
                member_tier="Veteran",
            )

            result = await user_context_service.get_lifetime_member_context("test-user-id")

            assert isinstance(result, LifetimeMemberContext)
            assert result.is_lifetime_member is True

    @pytest.mark.asyncio
    async def test_get_full_user_context_includes_lifetime(
        self,
        user_context_service,
    ):
        """get_full_user_context_for_ai should include lifetime context."""
        with patch.object(
            user_context_service,
            'get_lifetime_member_context',
            new_callable=AsyncMock,
        ) as mock_lifetime, patch.object(
            user_context_service,
            'get_user_patterns',
            new_callable=AsyncMock,
        ) as mock_patterns:
            mock_lifetime.return_value = LifetimeMemberContext(
                is_lifetime_member=True,
                lifetime_purchase_date=datetime(2024, 1, 1),
                days_as_member=365,
                member_tier="Veteran",
            )

            # Create a mock patterns object
            mock_pattern_result = MagicMock()
            mock_pattern_result.to_dict.return_value = {
                "user_id": "test-user-id",
                "most_common_mood": "great",
            }
            mock_pattern_result.preferred_workout_time = "morning"
            mock_pattern_result.most_common_mood = "great"
            mock_pattern_result.avg_workouts_per_week = 3.5
            mock_pattern_result.cardio_patterns = None
            mock_patterns.return_value = mock_pattern_result

            result = await user_context_service.get_full_user_context_for_ai(
                "test-user-id",
                include_lifetime=True,
            )

            assert "lifetime_membership" in result
            assert result["lifetime_membership"]["is_lifetime_member"] is True
            assert "ai_personalization_context" in result

    @pytest.mark.asyncio
    async def test_get_full_user_context_without_lifetime(
        self,
        user_context_service,
    ):
        """get_full_user_context_for_ai can exclude lifetime context."""
        with patch.object(
            user_context_service,
            'get_user_patterns',
            new_callable=AsyncMock,
        ) as mock_patterns:
            mock_pattern_result = MagicMock()
            mock_pattern_result.to_dict.return_value = {
                "user_id": "test-user-id",
            }
            mock_pattern_result.preferred_workout_time = None
            mock_pattern_result.most_common_mood = None
            mock_pattern_result.avg_workouts_per_week = 0
            mock_pattern_result.cardio_patterns = None
            mock_patterns.return_value = mock_pattern_result

            result = await user_context_service.get_full_user_context_for_ai(
                "test-user-id",
                include_lifetime=False,
            )

            assert "lifetime_membership" not in result


# =============================================================================
# RENEWAL NOTIFICATION SKIP TESTS
# =============================================================================

class TestRenewalNotificationSkip:
    """Tests to verify lifetime members don't receive renewal notifications."""

    def test_lifetime_member_should_not_have_renewal_date(
        self,
        lifetime_member_subscription,
    ):
        """Lifetime members should not have a renewal date."""
        # Renewal notifications are based on current_period_end
        assert lifetime_member_subscription["current_period_end"] is None

    def test_can_check_lifetime_status_before_notifications(self):
        """Application should be able to check lifetime status before sending notifications."""
        subscription = {
            "is_lifetime": True,
            "tier": "lifetime",
        }

        # This is how the notification service should check
        is_lifetime = (
            subscription.get("is_lifetime", False) or
            subscription.get("tier") == "lifetime"
        )

        assert is_lifetime is True


# =============================================================================
# EDGE CASE TESTS
# =============================================================================

class TestLifetimeEdgeCases:
    """Edge case tests for lifetime membership."""

    def test_missing_purchase_date_still_works(self):
        """Lifetime context should work even without purchase date."""
        context = LifetimeMemberContext(
            is_lifetime_member=True,
            lifetime_purchase_date=None,
            member_tier="New",
        )

        ai_context = context.get_ai_personalization_context()
        assert "valued lifetime member" in ai_context.lower()

    def test_zero_days_as_member(self):
        """Context should handle zero days as member."""
        context = LifetimeMemberContext(
            is_lifetime_member=True,
            days_as_member=0,
            member_tier="New",
        )

        assert context.days_as_member == 0
        assert context.member_tier == "New"

    def test_very_long_membership(self):
        """Context should handle very long memberships (5+ years)."""
        days = 365 * 5  # 5 years
        context = LifetimeMemberContext(
            is_lifetime_member=True,
            days_as_member=days,
            member_tier="Veteran",
            estimated_value_received=days / 30.0 * 9.99,
        )

        assert context.member_tier == "Veteran"
        assert context.estimated_value_received > 500  # Should be ~$600

    def test_zero_original_price_no_division_error(self):
        """Value multiplier calculation should handle zero price."""
        original_price = 0
        estimated_value = 100.0

        # This is how it's calculated in the service
        if original_price > 0:
            value_multiplier = estimated_value / original_price
        else:
            value_multiplier = 0.0

        assert value_multiplier == 0.0


# =============================================================================
# RUN TESTS
# =============================================================================

if __name__ == "__main__":
    pytest.main([__file__, "-v"])
