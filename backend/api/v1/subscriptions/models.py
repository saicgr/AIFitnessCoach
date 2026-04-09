"""
Pydantic models and enums for subscription endpoints.
"""
from datetime import datetime, date, timedelta
from typing import Optional, List
from pydantic import BaseModel
from enum import Enum


class SubscriptionTier(str, Enum):
    free = "free"
    premium = "premium"
    premium_plus = "premium_plus"
    lifetime = "lifetime"


class SubscriptionStatus(str, Enum):
    active = "active"
    canceled = "canceled"
    expired = "expired"
    trial = "trial"
    grace_period = "grace_period"
    paused = "paused"


class SubscriptionResponse(BaseModel):
    """User's current subscription details."""
    user_id: str
    tier: SubscriptionTier
    status: SubscriptionStatus
    is_trial: bool = False
    trial_end_date: Optional[str] = None
    current_period_end: Optional[str] = None
    features: dict = {}


class FeatureAccessRequest(BaseModel):
    """Request to check feature access."""
    feature_key: str


class FeatureAccessResponse(BaseModel):
    """Response for feature access check."""
    feature_key: str
    has_access: bool
    remaining_uses: Optional[int] = None
    limit: Optional[int] = None
    upgrade_required: bool = False
    minimum_tier: Optional[str] = None


class FeatureUsageRequest(BaseModel):
    """Request to track feature usage."""
    feature_key: str
    metadata: Optional[dict] = None


class PaywallImpressionRequest(BaseModel):
    """Request to track paywall interaction."""
    screen: str  # 'features', 'timeline', 'pricing'
    source: Optional[str] = None  # 'onboarding', 'upgrade_prompt', 'settings'
    action: str  # 'viewed', 'dismissed', 'continued', 'purchased', 'restored'
    selected_product: Optional[str] = None
    time_on_screen_ms: Optional[int] = None
    session_id: Optional[str] = None
    device_type: Optional[str] = None
    app_version: Optional[str] = None
    experiment_id: Optional[str] = None
    variant: Optional[str] = None


class UsageStatsResponse(BaseModel):
    """Feature usage statistics for a user."""
    feature_key: str
    today_usage: int
    week_usage: int
    month_usage: int
    limit: Optional[int] = None


class RevenueCatEvent(BaseModel):
    """RevenueCat webhook event."""
    event: dict
    api_version: str


class RefundStatus(str, Enum):
    """Refund request status."""
    pending = "pending"
    approved = "approved"
    denied = "denied"
    processed = "processed"


class SubscriptionHistoryEvent(BaseModel):
    """A single subscription history event."""
    id: str
    event_type: str
    event_description: str
    created_at: str
    previous_tier: Optional[str] = None
    new_tier: Optional[str] = None
    product_id: Optional[str] = None
    price: Optional[float] = None
    currency: Optional[str] = None
    price_display: Optional[str] = None


class SubscriptionHistoryResponse(BaseModel):
    """User's subscription change history."""
    user_id: str
    events: List[SubscriptionHistoryEvent]
    total_count: int


class UpcomingRenewalResponse(BaseModel):
    """Upcoming subscription renewal details."""
    user_id: str
    tier: str
    status: str
    product_id: Optional[str] = None
    renewal_date: Optional[str] = None
    current_price: Optional[float] = None
    currency: Optional[str] = None
    is_trial: bool = False
    trial_end_date: Optional[str] = None
    will_cancel: bool = False
    cancellation_effective_date: Optional[str] = None
    renewal_status_message: str
    days_until_renewal: int = 0


class RefundRequest(BaseModel):
    """Request to submit a refund."""
    reason: str
    additional_details: Optional[str] = None


class RefundRequestResponse(BaseModel):
    """Response after submitting a refund request."""
    id: str
    tracking_id: str
    status: RefundStatus
    amount: Optional[float] = None
    currency: Optional[str] = None
    created_at: str
    message: str


class RefundRequestDetails(BaseModel):
    """Full details of a refund request."""
    id: str
    tracking_id: str
    reason: str
    additional_details: Optional[str] = None
    status: RefundStatus
    amount: Optional[float] = None
    currency: Optional[str] = None
    created_at: str
    updated_at: str
    processed_at: Optional[str] = None


class TrialEligibilityResponse(BaseModel):
    """Response for trial eligibility check."""
    user_id: str
    is_eligible: bool
    reason: Optional[str] = None
    trial_duration_days: int = 7
    available_plans: List[str] = []
    previous_trials: int = 0
    can_extend: bool = False
    extension_reason: Optional[str] = None


class StartTrialRequest(BaseModel):
    """Request to start a free trial."""
    plan_type: str  # monthly, yearly, lifetime_intro
    demo_session_id: Optional[str] = None
    source: Optional[str] = None  # onboarding, paywall, settings


class StartTrialResponse(BaseModel):
    """Response after starting a trial."""
    user_id: str
    tier: str
    status: str
    trial_started: bool
    trial_end_date: str
    trial_plan_type: str
    message: str
    features_unlocked: List[str] = []


class TrialConversionRequest(BaseModel):
    """Request to convert trial to paid subscription."""
    product_id: str
    transaction_id: Optional[str] = None


class LifetimeMemberTier(str, Enum):
    """Lifetime member recognition tiers based on membership duration."""
    veteran = "Veteran"      # 365+ days
    loyal = "Loyal"          # 180+ days
    established = "Established"  # 90+ days
    new = "New"              # < 90 days


class LifetimeStatusResponse(BaseModel):
    """Response for lifetime membership status check."""
    user_id: str
    is_lifetime: bool
    purchase_date: Optional[str] = None
    days_as_member: int = 0
    months_as_member: int = 0
    member_tier: Optional[str] = None
    member_tier_level: int = 0
    features_unlocked: List[str] = []
    estimated_value_received: Optional[float] = None
    value_multiplier: Optional[float] = None
    ai_context: Optional[str] = None
    original_price: Optional[float] = None


class LifetimeMemberBenefitsResponse(BaseModel):
    """Detailed lifetime member benefits."""
    user_id: str
    is_lifetime: bool
    member_tier: str
    purchase_date: str
    days_as_member: int
    features: List[str]
    perks: List[dict]
    estimated_savings: float
    message: str


class PauseSubscriptionRequest(BaseModel):
    """Request to pause a subscription."""
    duration_days: int  # 7, 14, 30, 60, or 90 days
    reason: Optional[str] = None


class PauseSubscriptionResponse(BaseModel):
    """Response after pausing subscription."""
    user_id: str
    status: str
    paused_at: str
    resume_date: str
    duration_days: int
    message: str


class ResumeSubscriptionResponse(BaseModel):
    """Response after resuming subscription."""
    user_id: str
    status: str
    resumed_at: str
    tier: str
    message: str


class RetentionOffer(BaseModel):
    """A retention offer to prevent cancellation."""
    id: str
    type: str  # discount, extension, downgrade, pause
    title: str
    description: str
    value: Optional[str] = None
    discount_percent: Optional[int] = None
    extension_days: Optional[int] = None
    target_tier: Optional[str] = None
    expires_in_hours: int = 24


class RetentionOffersResponse(BaseModel):
    """Available retention offers for a user."""
    user_id: str
    offers: List[RetentionOffer]
    cancellation_reason: Optional[str] = None


class AcceptOfferRequest(BaseModel):
    """Request to accept a retention offer."""
    offer_id: str
    cancellation_reason: Optional[str] = None


class AcceptOfferResponse(BaseModel):
    """Response after accepting a retention offer."""
    user_id: str
    offer_id: str
    offer_type: str
    applied: bool
    new_status: Optional[str] = None
    new_tier: Optional[str] = None
    discount_applied: Optional[int] = None
    extension_days: Optional[int] = None
    message: str


def _get_next_tier(current_tier: str) -> str:
    """Get the next tier for upgrade prompt."""
    tiers = ["free", "premium", "premium_plus", "lifetime"]
    try:
        idx = tiers.index(current_tier)
        if idx < len(tiers) - 1:
            return tiers[idx + 1]
    except ValueError:
        pass
    return "premium"


def _product_to_tier(product_id: str) -> str:
    """Map RevenueCat product ID to subscription tier."""
    product_id = product_id.lower()

    if "lifetime" in product_id:
        return "lifetime"
    elif "premium_plus" in product_id:
        return "premium_plus"
    elif "premium" in product_id:
        return "premium"
    else:
        return "free"


def is_lifetime_member(supabase, user_id: str) -> bool:
    """Check if a user is a lifetime member."""
    from core.logger import get_logger
    logger = get_logger(__name__)
    try:
        result = supabase.client.table("user_subscriptions")\
            .select("is_lifetime, tier")\
            .eq("user_id", user_id)\
            .single()\
            .execute()

        if not result.data:
            return False

        return result.data.get("is_lifetime", False) or result.data.get("tier") == "lifetime"

    except Exception as e:
        logger.warning(f"Error checking lifetime status: {e}", exc_info=True)
        return False


def get_lifetime_member_tier(days_as_member: int) -> tuple:
    """Calculate lifetime member tier based on days of membership."""
    if days_as_member >= 365:
        return ("Veteran", 4)
    elif days_as_member >= 180:
        return ("Loyal", 3)
    elif days_as_member >= 90:
        return ("Established", 2)
    else:
        return ("New", 1)


def calculate_lifetime_value(months_as_member: int, monthly_price: float = 9.99) -> float:
    """Calculate estimated value received by lifetime member."""
    return round(months_as_member * monthly_price, 2)
