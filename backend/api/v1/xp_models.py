"""Pydantic models for xp.

IMPORTANT: This is the SINGLE source of truth for every XP/progression
response model. Do NOT re-declare these classes in xp.py or
xp_endpoints.py — a local redefinition silently diverges and breaks the
null-coercion behavior below (see process_daily_login 500, Apr 2026).
"""
import typing
from datetime import datetime, date
from pydantic import BaseModel, Field, model_validator
from typing import List, Optional, Dict, Any


# =============================================================================
# BASE CLASS — null-tolerant response model
# =============================================================================

# Cache of (cls → {field_name: default}) for fields whose annotation is a
# strict scalar (int / float / bool / str) with no Optional wrapper. These
# are the fields that will 500 if the RPC returns NULL; we coerce to a
# sensible zero value before validation.
_STRICT_DEFAULTS: Dict[type, Dict[str, Any]] = {}

_SCALAR_DEFAULTS = {int: 0, float: 0.0, bool: False, str: ""}


def _compute_strict_defaults(cls: type) -> Dict[str, Any]:
    cached = _STRICT_DEFAULTS.get(cls)
    if cached is not None:
        return cached

    defaults: Dict[str, Any] = {}
    # Pydantic v2 stores parsed field info on .model_fields
    for name, info in getattr(cls, "model_fields", {}).items():
        ann = info.annotation
        # Unwrap Optional[X] / Union[X, None] — these already accept None
        origin = typing.get_origin(ann)
        args = typing.get_args(ann)
        if origin is typing.Union and type(None) in args:
            continue
        if ann in _SCALAR_DEFAULTS:
            defaults[name] = _SCALAR_DEFAULTS[ann]

    _STRICT_DEFAULTS[cls] = defaults
    return defaults


class NullTolerantResponse(BaseModel):
    """Base class for response models fed from Supabase RPCs.

    Supabase RPCs frequently return NULL for numeric/boolean columns when
    a row is missing (e.g. brand-new user, missing streak row, legacy
    rows that predate a migration). Pydantic strict-int / strict-bool
    fields reject NULL and raise ValidationError → 500.

    This mixin intercepts validation *before* field validation runs and
    swaps any NULL value whose target type is a strict scalar with that
    type's zero value. Optional fields are left alone (NULL is valid for
    Optional). Complex types (lists, dicts, nested models) are untouched.
    """

    @model_validator(mode="before")
    @classmethod
    def _coerce_strict_nulls(cls, data):
        if not isinstance(data, dict):
            return data
        strict = _compute_strict_defaults(cls)
        if not strict:
            return data
        for name, default in strict.items():
            if name in data and data[name] is None:
                data[name] = default
        return data


# =============================================================================
# DAILY LOGIN / STREAK
# =============================================================================

class DailyLoginResponse(NullTolerantResponse):
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


class LoginStreakInfo(NullTolerantResponse):
    current_streak: int
    longest_streak: int
    total_logins: int
    last_login_date: Optional[str] = None
    first_login_at: Optional[str] = None
    streak_start_date: Optional[str] = None
    has_logged_in_today: bool


# =============================================================================
# XP EVENTS / BONUS TEMPLATES
# =============================================================================

class XPEvent(NullTolerantResponse):
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


class BonusTemplate(NullTolerantResponse):
    id: str
    bonus_type: str
    base_xp: int
    description: Optional[str] = None
    streak_multiplier: bool
    max_streak_multiplier: int
    is_active: bool


# =============================================================================
# DAILY GOALS / AWARD XP
# =============================================================================

class AwardGoalXPRequest(BaseModel):
    goal_type: str
    source_id: Optional[str] = None


class AwardGoalXPResponse(NullTolerantResponse):
    success: bool
    xp_awarded: int
    message: str
    already_claimed: bool = False


class DailyGoalsStatusResponse(NullTolerantResponse):
    weight_log: bool = False
    meal_log: bool = False
    workout_complete: bool = False
    protein_goal: bool = False
    body_measurements: bool = False
    steps_goal: bool = False
    hydration_goal: bool = False
    calorie_goal: bool = False


# =============================================================================
# FIRST-TIME BONUSES
# =============================================================================

class FirstTimeBonusRequest(BaseModel):
    bonus_type: str


class FirstTimeBonusResponse(NullTolerantResponse):
    awarded: bool
    xp: int
    bonus_type: str
    message: str


class FirstTimeBonusInfo(NullTolerantResponse):
    bonus_type: str
    xp_awarded: int
    awarded_at: str


# =============================================================================
# CONSUMABLES / CRATES
# =============================================================================

class UseConsumableRequest(BaseModel):
    item_type: str


class ConsumablesResponse(NullTolerantResponse):
    streak_shield: int = 0
    xp_token_2x: int = 0
    fitness_crate: int = 0
    premium_crate: int = 0
    active_2x_until: Optional[str] = None


class OpenCrateRequest(BaseModel):
    crate_type: str


class DailyCratesResponse(NullTolerantResponse):
    daily_crate_available: bool = True
    streak_crate_available: bool = False
    activity_crate_available: bool = False
    selected_crate: Optional[str] = None
    reward: Optional[dict] = None
    claimed: bool = False
    claimed_at: Optional[str] = None
    crate_date: str


class ClaimDailyCrateRequest(BaseModel):
    crate_type: str
    crate_date: Optional[str] = None


class ClaimDailyCrateResponse(NullTolerantResponse):
    success: bool
    crate_type: Optional[str] = None
    crate_date: Optional[str] = None
    reward: Optional[dict] = None
    message: str


class UnclaimedCrateItem(NullTolerantResponse):
    crate_date: str
    daily_crate_available: bool = True
    streak_crate_available: bool = False
    activity_crate_available: bool = False


class UnclaimedCratesResponse(NullTolerantResponse):
    unclaimed: List[UnclaimedCrateItem] = []
    count: int = 0


# =============================================================================
# WEEKLY SUMMARY / NEXT LEVEL PREVIEW
# =============================================================================

class WeeklySummaryResponse(NullTolerantResponse):
    this_week_xp: int
    last_week_xp: int
    sparkline_7day: List[int]
    next_nudge: str


class NextLevelRewardBlock(NullTolerantResponse):
    kind: str
    label: str
    icon: str
    tier: str


class NextLevelPreviewResponse(NullTolerantResponse):
    level: int
    xp_in_level: int
    xp_to_next: int
    reward: NextLevelRewardBlock


# =============================================================================
# REFERRALS (migration 1932)
# =============================================================================

class ReferralApplyRequest(BaseModel):
    code: str


class ReferralSummaryResponse(NullTolerantResponse):
    referral_code: str
    pending_count: int
    qualified_count: int
    next_milestone: Optional[int] = None
    next_merch_type: Optional[str] = None


class ReferralApplyResponse(NullTolerantResponse):
    success: bool
    message: str
    referrer_id: Optional[str] = None


# =============================================================================
# MERCH CLAIMS
# =============================================================================

class MerchClaim(NullTolerantResponse):
    """A physical merchandise reward earned at a milestone level."""
    id: str
    merch_type: str
    awarded_at_level: int
    status: str
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


class MerchClaimListResponse(NullTolerantResponse):
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
