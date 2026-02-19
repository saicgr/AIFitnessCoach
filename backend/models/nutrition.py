"""Nutrition and food tracking Pydantic models."""

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


class FoodItem(BaseModel):
    """Individual food item with nutrition data."""
    name: str = Field(..., max_length=200)
    amount: Optional[str] = Field(default=None, max_length=50)  # e.g., "150g", "1 cup"
    calories: Optional[int] = Field(default=None, ge=0, le=10000)
    protein_g: Optional[float] = Field(default=None, ge=0, le=1000)
    carbs_g: Optional[float] = Field(default=None, ge=0, le=1000)
    fat_g: Optional[float] = Field(default=None, ge=0, le=1000)


class FoodLogCreate(BaseModel):
    """Create a new food log."""
    user_id: str = Field(..., max_length=100)  # UUID string
    meal_type: str = Field(..., max_length=50)  # breakfast, lunch, dinner, snack
    food_items: List[FoodItem] = Field(..., max_length=50)
    total_calories: int = Field(..., ge=0, le=20000)
    protein_g: float = Field(..., ge=0, le=2000)
    carbs_g: float = Field(..., ge=0, le=2000)
    fat_g: float = Field(..., ge=0, le=2000)
    fiber_g: Optional[float] = Field(default=None, ge=0, le=500)
    health_score: Optional[int] = Field(default=None, ge=1, le=10)  # 1-10
    ai_feedback: Optional[str] = Field(default=None, max_length=2000)


class FoodLog(BaseModel):
    """Food log response."""
    id: str = Field(..., max_length=100)  # UUID string
    user_id: str = Field(..., max_length=100)
    meal_type: str = Field(..., max_length=50)
    logged_at: datetime
    food_items: List[FoodItem] = Field(..., max_length=50)
    total_calories: int = Field(..., ge=0, le=20000)
    protein_g: float = Field(..., ge=0, le=2000)
    carbs_g: float = Field(..., ge=0, le=2000)
    fat_g: float = Field(..., ge=0, le=2000)
    fiber_g: Optional[float] = Field(default=None, ge=0, le=500)
    health_score: Optional[int] = Field(default=None, ge=1, le=10)
    ai_feedback: Optional[str] = Field(default=None, max_length=2000)
    created_at: datetime


class DailyNutritionSummary(BaseModel):
    """Daily nutrition summary."""
    date: str = Field(..., max_length=20)
    total_calories: int = Field(..., ge=0, le=50000)
    total_protein_g: float = Field(..., ge=0, le=5000)
    total_carbs_g: float = Field(..., ge=0, le=5000)
    total_fat_g: float = Field(..., ge=0, le=5000)
    total_fiber_g: float = Field(..., ge=0, le=1000)
    meal_count: int = Field(..., ge=0, le=50)
    avg_health_score: Optional[float] = Field(default=None, ge=1, le=10)


class NutritionTargets(BaseModel):
    """User's daily nutrition targets."""
    daily_calorie_target: Optional[int] = Field(default=None, ge=0, le=20000)
    daily_protein_target_g: Optional[float] = Field(default=None, ge=0, le=1000)
    daily_carbs_target_g: Optional[float] = Field(default=None, ge=0, le=1000)
    daily_fat_target_g: Optional[float] = Field(default=None, ge=0, le=1000)


class UpdateNutritionTargetsRequest(BaseModel):
    """Request to update user's nutrition targets."""
    user_id: str = Field(..., max_length=100)  # UUID string
    daily_calorie_target: Optional[int] = Field(default=None, ge=0, le=20000)
    daily_protein_target_g: Optional[float] = Field(default=None, ge=0, le=1000)
    daily_carbs_target_g: Optional[float] = Field(default=None, ge=0, le=1000)
    daily_fat_target_g: Optional[float] = Field(default=None, ge=0, le=1000)


# Hydration Models

class HydrationLogCreate(BaseModel):
    """Request to log hydration intake."""
    user_id: str = Field(..., max_length=100)  # UUID string
    drink_type: str = Field(..., max_length=50)  # "water", "protein_shake", "sports_drink", "coffee", "other"
    amount_ml: int = Field(..., ge=1, le=10000)  # Amount in milliliters
    workout_id: Optional[str] = Field(default=None, max_length=100)  # Optional workout association
    notes: Optional[str] = Field(default=None, max_length=500)
    local_date: Optional[str] = Field(default=None, max_length=10)  # Client's local date YYYY-MM-DD for correct day grouping


class HydrationLog(BaseModel):
    """Hydration log entry."""
    id: str = Field(..., max_length=100)
    user_id: str = Field(..., max_length=100)
    drink_type: str = Field(..., max_length=50)
    amount_ml: int = Field(..., ge=1, le=10000)
    workout_id: Optional[str] = Field(default=None, max_length=100)
    notes: Optional[str] = Field(default=None, max_length=500)
    logged_at: Optional[datetime] = None


class DailyHydrationSummary(BaseModel):
    """Summary of daily hydration."""
    date: str = Field(..., max_length=20)  # ISO date string
    total_ml: int = Field(..., ge=0)
    water_ml: int = Field(..., ge=0)
    protein_shake_ml: int = Field(..., ge=0)
    sports_drink_ml: int = Field(..., ge=0)
    other_ml: int = Field(..., ge=0)
    goal_ml: int = Field(..., ge=0)  # User's daily goal
    goal_percentage: float = Field(..., ge=0)  # Percentage of goal reached
    entries: List[HydrationLog]


class HydrationGoalUpdate(BaseModel):
    """Update user's daily hydration goal."""
    daily_goal_ml: int = Field(..., ge=500, le=20000)  # Default 2500ml / ~84oz


class HydrationReminderSettings(BaseModel):
    """Hydration reminder settings."""
    enabled: bool = True
    interval_minutes: int = Field(default=60, ge=15, le=480)  # Remind every 60 minutes
    start_time: str = Field(default="08:00", max_length=10)  # Start reminding at 8 AM
    end_time: str = Field(default="22:00", max_length=10)  # Stop reminding at 10 PM
    during_workout_only: bool = False  # Only remind during active workouts
