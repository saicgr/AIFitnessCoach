"""Pydantic models for xp."""
from datetime import datetime, date
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any


class DailyLoginResponse(BaseModel):
    is_first_login: bool
    streak_broken: bool
    current_streak: int
    longest_streak: int
    total_logins: int
    daily_xp: int
    first_login_xp: int
    streak_milestone_xp: int
    total_xp_awarded: int
    active_events: Optional[List[dict]] = None
    multiplier: float
    message: str
    already_claimed: bool = False
    # Migration 1938: streak shield auto-consume
    streak_saved_by_shield: bool = False
    shields_remaining: int = 0
    saved_streak_count: int = 0


class LoginStreakInfo(BaseModel):
    current_streak: int
    longest_streak: int
    total_logins: int
    last_login_date: Optional[str] = None
    first_login_at: Optional[str] = None
    streak_start_date: Optional[str] = None
    has_logged_in_today: bool


class XPEvent(BaseModel):
    id: str
    event_name: str
    event_type: str
    description: Optional[str] = None
    xp_multiplier: float
    start_at: datetime
    end_at: datetime
    is_active: bool
    applies_to: List[str]
    icon_name: Optional[str] = None
    banner_color: Optional[str] = None


class CreateEventRequest(BaseModel):
    event_name: str = "Double XP Weekend"
    event_type: str = "weekend_bonus"
    multiplier: float = 2.0
    duration_hours: int = 48


class BonusTemplate(BaseModel):
    id: str
    bonus_type: str
    base_xp: int
    description: Optional[str] = None
    streak_multiplier: bool
    max_streak_multiplier: int
    is_active: bool


# =============================================================================
# ENDPOINTS
# =============================================================================

class AwardGoalXPRequest(BaseModel):
    goal_type: str  # 'weight_log', 'meal_log', 'workout_complete', 'protein_goal'
    source_id: Optional[str] = None  # Optional ID of the source (e.g., workout ID)


class AwardGoalXPResponse(BaseModel):
    success: bool
    xp_awarded: int
    message: str
    already_claimed: bool = False


class DailyGoalsStatusResponse(BaseModel):
    weight_log: bool = False
    meal_log: bool = False
    workout_complete: bool = False
    protein_goal: bool = False
    body_measurements: bool = False
    steps_goal: bool = False
    hydration_goal: bool = False
    calorie_goal: bool = False


class FirstTimeBonusRequest(BaseModel):
    bonus_type: str


class FirstTimeBonusResponse(BaseModel):
    awarded: bool
    xp: int
    bonus_type: str
    message: str


class FirstTimeBonusInfo(BaseModel):
    bonus_type: str
    xp_awarded: int
    awarded_at: str


class UseConsumableRequest(BaseModel):
    item_type: str  # 'streak_shield', 'xp_token_2x', 'fitness_crate', 'premium_crate'


class ConsumablesResponse(BaseModel):
    streak_shield: int = 0
    xp_token_2x: int = 0
    fitness_crate: int = 0
    premium_crate: int = 0
    active_2x_until: Optional[str] = None


class OpenCrateRequest(BaseModel):
    crate_type: str  # 'fitness_crate' or 'premium_crate'


class DailyCratesResponse(BaseModel):
    daily_crate_available: bool = True
    streak_crate_available: bool = False
    activity_crate_available: bool = False
    selected_crate: Optional[str] = None
    reward: Optional[dict] = None
    claimed: bool = False
    claimed_at: Optional[str] = None
    crate_date: str


class ClaimDailyCrateRequest(BaseModel):
    crate_type: str  # 'daily', 'streak', or 'activity'
    crate_date: Optional[str] = None  # ISO date e.g. '2026-04-05'; defaults to today


class ClaimDailyCrateResponse(BaseModel):
    success: bool
    crate_type: Optional[str] = None
    crate_date: Optional[str] = None
    reward: Optional[dict] = None
    message: str


class UnclaimedCrateItem(BaseModel):
    crate_date: str
    daily_crate_available: bool = True
    streak_crate_available: bool = False
    activity_crate_available: bool = False


class UnclaimedCratesResponse(BaseModel):
    unclaimed: List[UnclaimedCrateItem] = []
    count: int = 0


# =============================================================================
# MERCH CLAIMS
# =============================================================================


class MerchClaim(BaseModel):
    """A physical merchandise reward earned at a milestone level."""
    id: str
    merch_type: str  # shaker_bottle | t_shirt | hoodie | full_merch_kit | signed_premium_kit
    awarded_at_level: int
    status: str  # pending_address | address_submitted | shipped | delivered | cancelled
    shipping_full_name: Optional[str] = None
    shipping_address_line1: Optional[str] = None
    shipping_address_line2: Optional[str] = None
    shipping_city: Optional[str] = None
    shipping_state: Optional[str] = None
    shipping_postal_code: Optional[str] = None
    shipping_country: Optional[str] = None
    shipping_phone: Optional[str] = None
    size: Optional[str] = None
    sizes: Optional[Dict[str, Any]] = None
    notes: Optional[str] = None
    address_submitted_at: Optional[str] = None
    tracking_number: Optional[str] = None
    carrier: Optional[str] = None
    shipped_at: Optional[str] = None
    delivered_at: Optional[str] = None
    cancelled_at: Optional[str] = None
    created_at: str
    updated_at: str


class MerchClaimListResponse(BaseModel):
    claims: List[MerchClaim] = []
    pending_count: int = 0
    total_count: int = 0


class SubmitMerchAddressRequest(BaseModel):
    full_name: str = Field(..., min_length=1, max_length=200)
    address_line1: str = Field(..., min_length=1, max_length=200)
    address_line2: Optional[str] = Field(None, max_length=200)
    city: str = Field(..., min_length=1, max_length=100)
    state: str = Field(..., min_length=1, max_length=100)
    postal_code: str = Field(..., min_length=1, max_length=20)
    country: str = Field(..., min_length=2, max_length=2, description="ISO 3166-1 alpha-2")
    phone: Optional[str] = Field(None, max_length=30)
    size: Optional[str] = Field(None, max_length=10)
    sizes: Optional[Dict[str, str]] = None
    notes: Optional[str] = Field(None, max_length=500)

