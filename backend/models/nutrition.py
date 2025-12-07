"""Nutrition and food tracking Pydantic models."""

from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime


class FoodItem(BaseModel):
    """Individual food item with nutrition data."""
    name: str
    amount: Optional[str] = None  # e.g., "150g", "1 cup"
    calories: Optional[int] = None
    protein_g: Optional[float] = None
    carbs_g: Optional[float] = None
    fat_g: Optional[float] = None


class FoodLogCreate(BaseModel):
    """Create a new food log."""
    user_id: str  # UUID string
    meal_type: str  # breakfast, lunch, dinner, snack
    food_items: List[FoodItem]
    total_calories: int
    protein_g: float
    carbs_g: float
    fat_g: float
    fiber_g: Optional[float] = None
    health_score: Optional[int] = None  # 1-10
    ai_feedback: Optional[str] = None


class FoodLog(BaseModel):
    """Food log response."""
    id: str  # UUID string
    user_id: str
    meal_type: str
    logged_at: datetime
    food_items: List[FoodItem]
    total_calories: int
    protein_g: float
    carbs_g: float
    fat_g: float
    fiber_g: Optional[float] = None
    health_score: Optional[int] = None
    ai_feedback: Optional[str] = None
    created_at: datetime


class DailyNutritionSummary(BaseModel):
    """Daily nutrition summary."""
    date: str
    total_calories: int
    total_protein_g: float
    total_carbs_g: float
    total_fat_g: float
    total_fiber_g: float
    meal_count: int
    avg_health_score: Optional[float] = None


class NutritionTargets(BaseModel):
    """User's daily nutrition targets."""
    daily_calorie_target: Optional[int] = None
    daily_protein_target_g: Optional[float] = None
    daily_carbs_target_g: Optional[float] = None
    daily_fat_target_g: Optional[float] = None


class UpdateNutritionTargetsRequest(BaseModel):
    """Request to update user's nutrition targets."""
    user_id: str  # UUID string
    daily_calorie_target: Optional[int] = None
    daily_protein_target_g: Optional[float] = None
    daily_carbs_target_g: Optional[float] = None
    daily_fat_target_g: Optional[float] = None


# Hydration Models

class HydrationLogCreate(BaseModel):
    """Request to log hydration intake."""
    user_id: str  # UUID string
    drink_type: str  # "water", "protein_shake", "sports_drink", "coffee", "other"
    amount_ml: int  # Amount in milliliters
    workout_id: Optional[str] = None  # Optional workout association
    notes: Optional[str] = None


class HydrationLog(BaseModel):
    """Hydration log entry."""
    id: str
    user_id: str
    drink_type: str
    amount_ml: int
    workout_id: Optional[str] = None
    notes: Optional[str] = None
    logged_at: Optional[datetime] = None


class DailyHydrationSummary(BaseModel):
    """Summary of daily hydration."""
    date: str  # ISO date string
    total_ml: int
    water_ml: int
    protein_shake_ml: int
    sports_drink_ml: int
    other_ml: int
    goal_ml: int  # User's daily goal
    goal_percentage: float  # Percentage of goal reached
    entries: List[HydrationLog]


class HydrationGoalUpdate(BaseModel):
    """Update user's daily hydration goal."""
    daily_goal_ml: int  # Default 2500ml / ~84oz


class HydrationReminderSettings(BaseModel):
    """Hydration reminder settings."""
    enabled: bool = True
    interval_minutes: int = 60  # Remind every 60 minutes
    start_time: str = "08:00"  # Start reminding at 8 AM
    end_time: str = "22:00"  # Stop reminding at 10 PM
    during_workout_only: bool = False  # Only remind during active workouts
