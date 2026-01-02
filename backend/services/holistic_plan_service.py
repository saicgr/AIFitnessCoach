"""
Holistic Plan Service
=====================
Coordinates workout scheduling, nutrition targets, and fasting windows
into unified weekly plans.

This service is the core of the "Full Plan" feature that integrates:
- Workout days with appropriate rest days
- Workout-aware nutrition (higher targets on training days)
- Fasting windows that coordinate with workout timing
- AI-generated meal suggestions

Usage:
    service = HolisticPlanService()
    plan = await service.generate_weekly_plan(
        user_id="...",
        week_start=date.today(),
        workout_days=[0, 1, 3, 4],  # Mon, Tue, Thu, Fri
        fasting_protocol="16:8",
        nutrition_strategy="workout_aware",
        goals=["build_muscle", "lose_fat"],
    )
"""

import json
import logging
from dataclasses import dataclass, field
from datetime import date, datetime, time, timedelta
from typing import Dict, List, Optional, Tuple, Any
from enum import Enum

from core.supabase_db import get_supabase_db
from core.logger import get_logger

logger = get_logger(__name__)


class NutritionStrategy(str, Enum):
    """How nutrition targets are adjusted throughout the week."""
    WORKOUT_AWARE = "workout_aware"  # +calories/protein on training days
    STATIC = "static"  # Same targets every day
    CUTTING = "cutting"  # Deficit on rest days
    BULKING = "bulking"  # Surplus on all days
    MAINTENANCE = "maintenance"  # Slight surplus on training, maintenance on rest


class DayType(str, Enum):
    """Type of day in the plan."""
    TRAINING = "training"
    REST = "rest"
    ACTIVE_RECOVERY = "active_recovery"


@dataclass
class NutritionTargets:
    """Nutrition targets for a day."""
    calories: int
    protein_g: float
    carbs_g: float
    fat_g: float
    fiber_g: float = 25.0

    def to_dict(self) -> Dict[str, Any]:
        return {
            "calories": self.calories,
            "protein_g": self.protein_g,
            "carbs_g": self.carbs_g,
            "fat_g": self.fat_g,
            "fiber_g": self.fiber_g,
        }


@dataclass
class FastingWindow:
    """Fasting window for a day."""
    protocol: str  # e.g., "16:8"
    fasting_start_time: time
    eating_window_start: time
    eating_window_end: time
    fasting_duration_hours: int

    def to_dict(self) -> Dict[str, Any]:
        return {
            "protocol": self.protocol,
            "fasting_start_time": self.fasting_start_time.isoformat() if self.fasting_start_time else None,
            "eating_window_start": self.eating_window_start.isoformat() if self.eating_window_start else None,
            "eating_window_end": self.eating_window_end.isoformat() if self.eating_window_end else None,
            "fasting_duration_hours": self.fasting_duration_hours,
        }


@dataclass
class MealSuggestion:
    """AI-generated meal suggestion."""
    meal_type: str  # breakfast, pre_workout, post_workout, lunch, dinner, snack
    suggested_time: time
    foods: List[Dict[str, Any]]  # [{name, amount, calories, protein_g, carbs_g, fat_g}]
    macros: Dict[str, float]  # {calories, protein_g, carbs_g, fat_g}
    notes: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        return {
            "meal_type": self.meal_type,
            "suggested_time": self.suggested_time.isoformat() if self.suggested_time else None,
            "foods": self.foods,
            "macros": self.macros,
            "notes": self.notes,
        }


@dataclass
class CoordinationNote:
    """Warning or note about plan coordination."""
    note_type: str  # fasting_workout_conflict, nutrition_timing, recovery_note
    message: str
    severity: str  # info, warning, critical
    suggestion: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        return {
            "type": self.note_type,
            "message": self.message,
            "severity": self.severity,
            "suggestion": self.suggestion,
        }


@dataclass
class DailyPlanEntry:
    """Complete plan for a single day."""
    plan_date: date
    day_type: DayType
    workout_id: Optional[str] = None
    workout_time: Optional[time] = None
    workout_duration_minutes: Optional[int] = None
    nutrition_targets: NutritionTargets = None
    fasting_window: Optional[FastingWindow] = None
    meal_suggestions: List[MealSuggestion] = field(default_factory=list)
    coordination_notes: List[CoordinationNote] = field(default_factory=list)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "plan_date": self.plan_date.isoformat(),
            "day_type": self.day_type.value,
            "workout_id": self.workout_id,
            "workout_time": self.workout_time.isoformat() if self.workout_time else None,
            "workout_duration_minutes": self.workout_duration_minutes,
            "nutrition_targets": self.nutrition_targets.to_dict() if self.nutrition_targets else None,
            "fasting_window": self.fasting_window.to_dict() if self.fasting_window else None,
            "meal_suggestions": [m.to_dict() for m in self.meal_suggestions],
            "coordination_notes": [n.to_dict() for n in self.coordination_notes],
        }


@dataclass
class WeeklyPlan:
    """Complete weekly holistic plan."""
    id: Optional[str] = None
    user_id: str = ""
    week_start_date: date = None
    status: str = "active"
    workout_days: List[int] = field(default_factory=list)
    fasting_protocol: Optional[str] = None
    nutrition_strategy: NutritionStrategy = NutritionStrategy.WORKOUT_AWARE
    base_nutrition: Optional[NutritionTargets] = None
    daily_entries: List[DailyPlanEntry] = field(default_factory=list)
    generated_at: Optional[datetime] = None

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "user_id": self.user_id,
            "week_start_date": self.week_start_date.isoformat() if self.week_start_date else None,
            "status": self.status,
            "workout_days": self.workout_days,
            "fasting_protocol": self.fasting_protocol,
            "nutrition_strategy": self.nutrition_strategy.value if isinstance(self.nutrition_strategy, NutritionStrategy) else self.nutrition_strategy,
            "base_nutrition": self.base_nutrition.to_dict() if self.base_nutrition else None,
            "daily_entries": [e.to_dict() for e in self.daily_entries],
            "generated_at": self.generated_at.isoformat() if self.generated_at else None,
        }


class HolisticPlanService:
    """
    Service for generating and managing holistic weekly plans.

    Coordinates:
    - Workout scheduling on specified days
    - Nutrition targets adjusted for training vs rest days
    - Fasting windows that work with workout timing
    - AI-generated meal suggestions
    """

    # Nutrition adjustment factors
    TRAINING_DAY_CALORIE_BOOST = 300  # Extra calories on training days
    TRAINING_DAY_PROTEIN_BOOST = 25  # Extra grams protein
    TRAINING_DAY_CARB_BOOST = 40  # Extra grams carbs
    CUTTING_REST_DAY_DEFICIT = 200  # Calorie deficit on rest days when cutting

    # Fasting protocols (fasting_hours, eating_hours)
    FASTING_PROTOCOLS = {
        "12:12": (12, 12),
        "14:10": (14, 10),
        "16:8": (16, 8),
        "18:6": (18, 6),
        "20:4": (20, 4),
        "OMAD": (23, 1),
    }

    def __init__(self):
        self.db = get_supabase_db()

    async def generate_weekly_plan(
        self,
        user_id: str,
        week_start: date,
        workout_days: List[int],
        fasting_protocol: Optional[str] = None,
        nutrition_strategy: str = "workout_aware",
        goals: Optional[List[str]] = None,
        preferred_workout_time: Optional[time] = None,
    ) -> WeeklyPlan:
        """
        Generate a complete weekly plan.

        Args:
            user_id: User ID
            week_start: Start date of the week (Monday)
            workout_days: List of day indices (0=Monday, 6=Sunday)
            fasting_protocol: Fasting protocol like "16:8"
            nutrition_strategy: How to adjust nutrition
            goals: User's fitness goals
            preferred_workout_time: Preferred time for workouts

        Returns:
            Complete WeeklyPlan with all daily entries
        """
        logger.info(f"Generating weekly plan for user {user_id}, week starting {week_start}")

        # Get user profile for base nutrition targets
        user = self.db.get_user(user_id)
        if not user:
            raise ValueError(f"User {user_id} not found")

        # Get base nutrition targets from user profile
        base_nutrition = self._get_base_nutrition(user)

        # Get fasting preferences if not specified
        if not fasting_protocol:
            fasting_prefs = self._get_user_fasting_preferences(user_id)
            fasting_protocol = fasting_prefs.get("default_protocol") if fasting_prefs else None

        # Default workout time if not specified
        if not preferred_workout_time:
            preferences = user.get("preferences", {})
            if isinstance(preferences, str):
                preferences = json.loads(preferences)
            preferred_workout_time = time(hour=preferences.get("workout_hour", 17), minute=0)

        # Create the weekly plan
        plan = WeeklyPlan(
            user_id=user_id,
            week_start_date=week_start,
            workout_days=workout_days,
            fasting_protocol=fasting_protocol,
            nutrition_strategy=NutritionStrategy(nutrition_strategy),
            base_nutrition=base_nutrition,
            generated_at=datetime.now(),
        )

        # Generate daily entries for each day of the week
        for day_offset in range(7):
            current_date = week_start + timedelta(days=day_offset)
            day_index = day_offset  # 0=Monday in our system

            # Determine day type
            is_training_day = day_index in workout_days
            day_type = DayType.TRAINING if is_training_day else DayType.REST

            # Calculate nutrition for this day
            daily_nutrition = self._calculate_daily_nutrition(
                base_nutrition=base_nutrition,
                day_type=day_type,
                strategy=plan.nutrition_strategy,
            )

            # Calculate fasting window for this day
            fasting_window = None
            if fasting_protocol:
                fasting_window = self._calculate_fasting_window(
                    protocol=fasting_protocol,
                    workout_time=preferred_workout_time if is_training_day else None,
                    is_training_day=is_training_day,
                )

            # Check for coordination issues
            coordination_notes = self._check_coordination(
                day_type=day_type,
                workout_time=preferred_workout_time if is_training_day else None,
                fasting_window=fasting_window,
            )

            # Create daily entry
            daily_entry = DailyPlanEntry(
                plan_date=current_date,
                day_type=day_type,
                workout_time=preferred_workout_time if is_training_day else None,
                nutrition_targets=daily_nutrition,
                fasting_window=fasting_window,
                coordination_notes=coordination_notes,
            )

            plan.daily_entries.append(daily_entry)

        logger.info(f"Generated weekly plan with {len(plan.daily_entries)} daily entries")
        return plan

    async def save_weekly_plan(self, plan: WeeklyPlan) -> str:
        """Save a weekly plan to the database."""
        try:
            # Insert weekly plan
            plan_data = {
                "user_id": plan.user_id,
                "week_start_date": plan.week_start_date.isoformat(),
                "status": plan.status,
                "workout_days": plan.workout_days,
                "fasting_protocol": plan.fasting_protocol,
                "nutrition_strategy": plan.nutrition_strategy.value if isinstance(plan.nutrition_strategy, NutritionStrategy) else plan.nutrition_strategy,
                "base_calorie_target": plan.base_nutrition.calories if plan.base_nutrition else None,
                "base_protein_target_g": plan.base_nutrition.protein_g if plan.base_nutrition else None,
                "base_carbs_target_g": plan.base_nutrition.carbs_g if plan.base_nutrition else None,
                "base_fat_target_g": plan.base_nutrition.fat_g if plan.base_nutrition else None,
                "generated_at": datetime.now().isoformat(),
            }

            result = self.db.client.table("weekly_plans").insert(plan_data).execute()
            plan_id = result.data[0]["id"]
            plan.id = plan_id

            # Insert daily entries
            for entry in plan.daily_entries:
                entry_data = {
                    "weekly_plan_id": plan_id,
                    "plan_date": entry.plan_date.isoformat(),
                    "day_type": entry.day_type.value,
                    "workout_id": entry.workout_id,
                    "workout_time": entry.workout_time.isoformat() if entry.workout_time else None,
                    "workout_duration_minutes": entry.workout_duration_minutes,
                    "calorie_target": entry.nutrition_targets.calories,
                    "protein_target_g": entry.nutrition_targets.protein_g,
                    "carbs_target_g": entry.nutrition_targets.carbs_g,
                    "fat_target_g": entry.nutrition_targets.fat_g,
                    "fiber_target_g": entry.nutrition_targets.fiber_g,
                    "fasting_start_time": entry.fasting_window.fasting_start_time.isoformat() if entry.fasting_window else None,
                    "eating_window_start": entry.fasting_window.eating_window_start.isoformat() if entry.fasting_window else None,
                    "eating_window_end": entry.fasting_window.eating_window_end.isoformat() if entry.fasting_window else None,
                    "fasting_protocol": entry.fasting_window.protocol if entry.fasting_window else None,
                    "fasting_duration_hours": entry.fasting_window.fasting_duration_hours if entry.fasting_window else None,
                    "meal_suggestions": [m.to_dict() for m in entry.meal_suggestions],
                    "coordination_notes": [n.to_dict() for n in entry.coordination_notes],
                }
                self.db.client.table("daily_plan_entries").insert(entry_data).execute()

            logger.info(f"Saved weekly plan {plan_id} with {len(plan.daily_entries)} daily entries")
            return plan_id

        except Exception as e:
            logger.error(f"Failed to save weekly plan: {e}")
            raise

    async def get_current_week_plan(self, user_id: str) -> Optional[WeeklyPlan]:
        """Get the current week's plan for a user."""
        # Calculate Monday of current week
        today = date.today()
        monday = today - timedelta(days=today.weekday())

        return await self.get_week_plan(user_id, monday)

    async def get_week_plan(self, user_id: str, week_start: date) -> Optional[WeeklyPlan]:
        """Get a specific week's plan."""
        try:
            # Get weekly plan
            result = self.db.client.table("weekly_plans").select("*").eq(
                "user_id", user_id
            ).eq(
                "week_start_date", week_start.isoformat()
            ).execute()

            if not result.data:
                return None

            plan_data = result.data[0]

            # Get daily entries
            entries_result = self.db.client.table("daily_plan_entries").select("*").eq(
                "weekly_plan_id", plan_data["id"]
            ).order("plan_date").execute()

            # Build plan object
            plan = WeeklyPlan(
                id=plan_data["id"],
                user_id=plan_data["user_id"],
                week_start_date=date.fromisoformat(plan_data["week_start_date"]),
                status=plan_data["status"],
                workout_days=plan_data.get("workout_days", []),
                fasting_protocol=plan_data.get("fasting_protocol"),
                nutrition_strategy=NutritionStrategy(plan_data.get("nutrition_strategy", "workout_aware")),
                generated_at=datetime.fromisoformat(plan_data["generated_at"]) if plan_data.get("generated_at") else None,
            )

            # Build daily entries
            for entry_data in entries_result.data:
                entry = DailyPlanEntry(
                    plan_date=date.fromisoformat(entry_data["plan_date"]),
                    day_type=DayType(entry_data["day_type"]),
                    workout_id=entry_data.get("workout_id"),
                    workout_time=time.fromisoformat(entry_data["workout_time"]) if entry_data.get("workout_time") else None,
                    nutrition_targets=NutritionTargets(
                        calories=entry_data["calorie_target"],
                        protein_g=entry_data["protein_target_g"],
                        carbs_g=entry_data["carbs_target_g"],
                        fat_g=entry_data["fat_target_g"],
                        fiber_g=entry_data.get("fiber_target_g", 25),
                    ),
                )

                # Add fasting window if present
                if entry_data.get("eating_window_start"):
                    entry.fasting_window = FastingWindow(
                        protocol=entry_data.get("fasting_protocol", ""),
                        fasting_start_time=time.fromisoformat(entry_data["fasting_start_time"]) if entry_data.get("fasting_start_time") else None,
                        eating_window_start=time.fromisoformat(entry_data["eating_window_start"]),
                        eating_window_end=time.fromisoformat(entry_data["eating_window_end"]) if entry_data.get("eating_window_end") else None,
                        fasting_duration_hours=entry_data.get("fasting_duration_hours", 16),
                    )

                # Add meal suggestions
                if entry_data.get("meal_suggestions"):
                    for meal in entry_data["meal_suggestions"]:
                        entry.meal_suggestions.append(MealSuggestion(
                            meal_type=meal.get("meal_type", "meal"),
                            suggested_time=time.fromisoformat(meal["suggested_time"]) if meal.get("suggested_time") else time(12, 0),
                            foods=meal.get("foods", []),
                            macros=meal.get("macros", {}),
                            notes=meal.get("notes"),
                        ))

                # Add coordination notes
                if entry_data.get("coordination_notes"):
                    for note in entry_data["coordination_notes"]:
                        entry.coordination_notes.append(CoordinationNote(
                            note_type=note.get("type", "info"),
                            message=note.get("message", ""),
                            severity=note.get("severity", "info"),
                            suggestion=note.get("suggestion"),
                        ))

                plan.daily_entries.append(entry)

            return plan

        except Exception as e:
            logger.error(f"Failed to get week plan: {e}")
            return None

    def _get_base_nutrition(self, user: Dict) -> NutritionTargets:
        """Get base nutrition targets from user profile."""
        return NutritionTargets(
            calories=user.get("daily_calorie_target", 2000),
            protein_g=user.get("daily_protein_target_g", 150),
            carbs_g=user.get("daily_carbs_target_g", 200),
            fat_g=user.get("daily_fat_target_g", 65),
            fiber_g=25.0,
        )

    def _get_user_fasting_preferences(self, user_id: str) -> Optional[Dict]:
        """Get user's fasting preferences."""
        try:
            result = self.db.client.table("fasting_preferences").select("*").eq(
                "user_id", user_id
            ).execute()
            return result.data[0] if result.data else None
        except Exception:
            return None

    def _calculate_daily_nutrition(
        self,
        base_nutrition: NutritionTargets,
        day_type: DayType,
        strategy: NutritionStrategy,
    ) -> NutritionTargets:
        """
        Calculate nutrition targets for a specific day.

        Adjustments:
        - Training days: +300 cal, +25g protein, +40g carbs
        - Rest days (cutting): -200 cal
        - Rest days (other): base targets
        """
        calories = base_nutrition.calories
        protein = base_nutrition.protein_g
        carbs = base_nutrition.carbs_g
        fat = base_nutrition.fat_g

        if day_type == DayType.TRAINING:
            if strategy in [NutritionStrategy.WORKOUT_AWARE, NutritionStrategy.BULKING]:
                calories += self.TRAINING_DAY_CALORIE_BOOST
                protein += self.TRAINING_DAY_PROTEIN_BOOST
                carbs += self.TRAINING_DAY_CARB_BOOST
            elif strategy == NutritionStrategy.MAINTENANCE:
                calories += self.TRAINING_DAY_CALORIE_BOOST // 2
                protein += self.TRAINING_DAY_PROTEIN_BOOST // 2
                carbs += self.TRAINING_DAY_CARB_BOOST // 2
        else:  # REST or ACTIVE_RECOVERY
            if strategy == NutritionStrategy.CUTTING:
                calories -= self.CUTTING_REST_DAY_DEFICIT
                carbs -= 30  # Reduce carbs on rest days when cutting

        return NutritionTargets(
            calories=max(calories, 1200),  # Minimum safe calories
            protein_g=max(protein, 50),
            carbs_g=max(carbs, 50),
            fat_g=fat,
            fiber_g=base_nutrition.fiber_g,
        )

    def _calculate_fasting_window(
        self,
        protocol: str,
        workout_time: Optional[time],
        is_training_day: bool,
    ) -> FastingWindow:
        """
        Calculate fasting window for a day.

        Logic:
        - If training day, try to place workout within eating window
        - Adjust eating window start/end to accommodate workout timing
        - For morning workouts, might need to shift window earlier
        """
        fasting_hours, eating_hours = self.FASTING_PROTOCOLS.get(protocol, (16, 8))

        # Default eating window: 12pm - 8pm for 16:8
        default_eating_start = time(12, 0)
        default_eating_end = time(20, 0)

        eating_start = default_eating_start
        eating_end = default_eating_end

        if is_training_day and workout_time:
            workout_hour = workout_time.hour

            # If workout is before default eating window starts
            if workout_hour < 12:
                # Shift eating window to start 1 hour before workout for pre-workout nutrition
                # Or accept fasted training with BCAA recommendation
                eating_start = time(max(workout_hour - 1, 6), 0)
                eating_end = time(eating_start.hour + eating_hours, 0)

            # If workout is after default eating window ends
            elif workout_hour >= 20:
                # Extend eating window to include post-workout meal
                eating_end = time(min(workout_hour + 2, 23), 0)
                eating_start = time(eating_end.hour - eating_hours, 0)

        # Calculate fasting start (end of eating window)
        fasting_start = eating_end

        return FastingWindow(
            protocol=protocol,
            fasting_start_time=fasting_start,
            eating_window_start=eating_start,
            eating_window_end=eating_end,
            fasting_duration_hours=fasting_hours,
        )

    def _check_coordination(
        self,
        day_type: DayType,
        workout_time: Optional[time],
        fasting_window: Optional[FastingWindow],
    ) -> List[CoordinationNote]:
        """
        Check for coordination issues between workout and fasting.

        Returns list of warnings/notes for the user.
        """
        notes = []

        if not fasting_window or day_type != DayType.TRAINING or not workout_time:
            return notes

        workout_hour = workout_time.hour
        eating_start_hour = fasting_window.eating_window_start.hour if fasting_window.eating_window_start else 12
        eating_end_hour = fasting_window.eating_window_end.hour if fasting_window.eating_window_end else 20

        # Check if workout is during fasting period (before eating window starts)
        if workout_hour < eating_start_hour:
            hours_fasted = 24 - (fasting_window.fasting_start_time.hour if fasting_window.fasting_start_time else 20) + workout_hour

            if hours_fasted > 16:
                notes.append(CoordinationNote(
                    note_type="fasting_workout_conflict",
                    message=f"Workout scheduled after {hours_fasted}h of fasting",
                    severity="warning",
                    suggestion="Consider BCAAs before fasted training, or shift your eating window earlier",
                ))
            else:
                notes.append(CoordinationNote(
                    note_type="fasting_workout_info",
                    message="Training in fasted state",
                    severity="info",
                    suggestion="Some prefer fasted training. Consider BCAAs if you feel low energy.",
                ))

        # Check if workout is near end of eating window
        elif workout_hour >= eating_end_hour - 1:
            notes.append(CoordinationNote(
                note_type="nutrition_timing",
                message="Workout near end of eating window",
                severity="info",
                suggestion="Plan your post-workout meal immediately after training before eating window closes",
            ))

        # Check for extended fasts (20:4, OMAD)
        if fasting_window.fasting_duration_hours >= 20:
            notes.append(CoordinationNote(
                note_type="extended_fast_warning",
                message="Extended fasting protocol on training day",
                severity="warning",
                suggestion="Schedule workout close to your eating window for optimal performance and recovery",
            ))

        return notes


# Singleton instance
_holistic_plan_service: Optional[HolisticPlanService] = None


def get_holistic_plan_service() -> HolisticPlanService:
    """Get the singleton HolisticPlanService instance."""
    global _holistic_plan_service
    if _holistic_plan_service is None:
        _holistic_plan_service = HolisticPlanService()
    return _holistic_plan_service
