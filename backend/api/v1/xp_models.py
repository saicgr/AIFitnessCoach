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


