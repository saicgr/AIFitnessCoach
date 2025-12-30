"""
Nutrition Calculator Service
============================
Calculates weekly nutrition scores based on food logging adherence
and macro nutrient targets.

Score Components:
- Logging adherence (30%): Days logged / 7
- Calorie adherence (25%): How close to calorie target
- Protein adherence (25%): How close to protein target
- Other macros (10%): Carbs + fats adherence
- Average health score (10%): Average food quality score

Nutrition Levels:
- needs_work: 0-39
- fair: 40-59
- good: 60-79
- excellent: 80-100
"""

from dataclasses import dataclass, field
from enum import Enum
from typing import Optional, List, Dict, Any
from datetime import date, datetime, timedelta
import logging

logger = logging.getLogger(__name__)


class NutritionLevel(str, Enum):
    """Nutrition score level classification."""
    NEEDS_WORK = "needs_work"
    FAIR = "fair"
    GOOD = "good"
    EXCELLENT = "excellent"


@dataclass
class NutritionTargets:
    """Daily nutrition targets for a user."""
    calories: int = 2000
    protein_g: int = 150
    carbs_g: int = 200
    fat_g: int = 65
    fiber_g: int = 30


@dataclass
class DailyNutrition:
    """Nutrition data for a single day."""
    date: date
    calories: float = 0
    protein_g: float = 0
    carbs_g: float = 0
    fat_g: float = 0
    fiber_g: float = 0
    health_score: float = 0  # Average health score of foods logged (1-10)
    meals_logged: int = 0


@dataclass
class NutritionScore:
    """Calculated nutrition score with breakdown."""
    # Identifiers
    id: Optional[str] = None
    user_id: str = ""
    week_start: Optional[date] = None
    week_end: Optional[date] = None

    # Adherence metrics
    days_logged: int = 0
    total_days: int = 7
    adherence_percent: float = 0.0

    # Macro adherence percentages (0-100, 100 = perfect adherence)
    calorie_adherence_percent: float = 0.0
    protein_adherence_percent: float = 0.0
    carb_adherence_percent: float = 0.0
    fat_adherence_percent: float = 0.0

    # Quality metrics
    avg_health_score: float = 0.0  # 0-10 scale
    fiber_target_met_days: int = 0

    # Overall score
    nutrition_score: int = 0  # 0-100
    nutrition_level: NutritionLevel = NutritionLevel.NEEDS_WORK

    # AI feedback (optional)
    ai_weekly_summary: Optional[str] = None
    ai_improvement_tips: List[str] = field(default_factory=list)

    # Timestamps
    calculated_at: Optional[datetime] = None

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for JSON serialization."""
        return {
            "id": self.id,
            "user_id": self.user_id,
            "week_start": self.week_start.isoformat() if self.week_start else None,
            "week_end": self.week_end.isoformat() if self.week_end else None,
            "days_logged": self.days_logged,
            "total_days": self.total_days,
            "adherence_percent": round(self.adherence_percent, 1),
            "calorie_adherence_percent": round(self.calorie_adherence_percent, 1),
            "protein_adherence_percent": round(self.protein_adherence_percent, 1),
            "carb_adherence_percent": round(self.carb_adherence_percent, 1),
            "fat_adherence_percent": round(self.fat_adherence_percent, 1),
            "avg_health_score": round(self.avg_health_score, 1),
            "fiber_target_met_days": self.fiber_target_met_days,
            "nutrition_score": self.nutrition_score,
            "nutrition_level": self.nutrition_level.value,
            "ai_weekly_summary": self.ai_weekly_summary,
            "ai_improvement_tips": self.ai_improvement_tips,
            "calculated_at": self.calculated_at.isoformat() if self.calculated_at else None,
        }


class NutritionCalculatorService:
    """Service for calculating nutrition scores."""

    # Score component weights
    WEIGHT_LOGGING_ADHERENCE = 0.30
    WEIGHT_CALORIE_ADHERENCE = 0.25
    WEIGHT_PROTEIN_ADHERENCE = 0.25
    WEIGHT_OTHER_MACROS = 0.10
    WEIGHT_HEALTH_SCORE = 0.10

    # Level thresholds
    LEVEL_THRESHOLDS = {
        NutritionLevel.EXCELLENT: 80,
        NutritionLevel.GOOD: 60,
        NutritionLevel.FAIR: 40,
        NutritionLevel.NEEDS_WORK: 0,
    }

    def __init__(self):
        pass

    def calculate_macro_adherence(
        self,
        actual: float,
        target: float,
        tolerance: float = 0.15,
    ) -> float:
        """
        Calculate adherence percentage for a single macro.

        Args:
            actual: Actual amount consumed
            target: Target amount
            tolerance: Acceptable deviation (default 15%)

        Returns:
            Adherence percentage (0-100)
        """
        if target <= 0:
            return 100.0 if actual == 0 else 0.0

        ratio = actual / target

        # Perfect adherence is within tolerance of target
        # Score decreases as you go further from target (over or under)
        if ratio < (1 - tolerance):
            # Under target - score based on how far under
            adherence = (ratio / (1 - tolerance)) * 100
        elif ratio > (1 + tolerance):
            # Over target - score based on how far over
            # Cap at 2x target = 0%
            if ratio >= 2:
                adherence = 0
            else:
                adherence = ((2 - ratio) / (1 - tolerance)) * 100
        else:
            # Within tolerance = 100%
            adherence = 100

        return max(0, min(100, adherence))

    def calculate_daily_adherence(
        self,
        daily: DailyNutrition,
        targets: NutritionTargets,
    ) -> Dict[str, float]:
        """
        Calculate adherence percentages for a single day.

        Args:
            daily: Daily nutrition data
            targets: User's nutrition targets

        Returns:
            Dictionary of adherence percentages
        """
        return {
            "calorie_adherence": self.calculate_macro_adherence(
                daily.calories, targets.calories
            ),
            "protein_adherence": self.calculate_macro_adherence(
                daily.protein_g, targets.protein_g
            ),
            "carb_adherence": self.calculate_macro_adherence(
                daily.carbs_g, targets.carbs_g
            ),
            "fat_adherence": self.calculate_macro_adherence(
                daily.fat_g, targets.fat_g
            ),
            "fiber_met": daily.fiber_g >= targets.fiber_g,
        }

    def calculate_weekly_nutrition_score(
        self,
        user_id: str,
        week_start: date,
        week_end: date,
        daily_data: List[DailyNutrition],
        targets: NutritionTargets,
    ) -> NutritionScore:
        """
        Calculate nutrition score for a week.

        Args:
            user_id: User ID
            week_start: Start of week
            week_end: End of week
            daily_data: List of daily nutrition data
            targets: User's nutrition targets

        Returns:
            NutritionScore with all metrics
        """
        # Filter data to the specified week
        week_data = [
            d for d in daily_data
            if week_start <= d.date <= week_end
        ]

        # Calculate logging adherence
        days_logged = len(week_data)
        total_days = (week_end - week_start).days + 1
        logging_adherence = (days_logged / total_days) * 100 if total_days > 0 else 0

        # If no days logged, return minimal score
        if days_logged == 0:
            return NutritionScore(
                user_id=user_id,
                week_start=week_start,
                week_end=week_end,
                days_logged=0,
                total_days=total_days,
                adherence_percent=0,
                nutrition_score=0,
                nutrition_level=NutritionLevel.NEEDS_WORK,
                calculated_at=datetime.now(),
            )

        # Calculate average adherence across logged days
        calorie_adherences = []
        protein_adherences = []
        carb_adherences = []
        fat_adherences = []
        health_scores = []
        fiber_met_days = 0

        for daily in week_data:
            adherence = self.calculate_daily_adherence(daily, targets)
            calorie_adherences.append(adherence["calorie_adherence"])
            protein_adherences.append(adherence["protein_adherence"])
            carb_adherences.append(adherence["carb_adherence"])
            fat_adherences.append(adherence["fat_adherence"])

            if adherence["fiber_met"]:
                fiber_met_days += 1

            if daily.health_score > 0:
                health_scores.append(daily.health_score)

        # Calculate averages
        avg_calorie_adherence = sum(calorie_adherences) / len(calorie_adherences)
        avg_protein_adherence = sum(protein_adherences) / len(protein_adherences)
        avg_carb_adherence = sum(carb_adherences) / len(carb_adherences)
        avg_fat_adherence = sum(fat_adherences) / len(fat_adherences)
        avg_health_score = sum(health_scores) / len(health_scores) if health_scores else 5.0

        # Calculate other macros adherence (average of carbs and fats)
        other_macros_adherence = (avg_carb_adherence + avg_fat_adherence) / 2

        # Calculate overall score using weights
        nutrition_score = (
            self.WEIGHT_LOGGING_ADHERENCE * logging_adherence +
            self.WEIGHT_CALORIE_ADHERENCE * avg_calorie_adherence +
            self.WEIGHT_PROTEIN_ADHERENCE * avg_protein_adherence +
            self.WEIGHT_OTHER_MACROS * other_macros_adherence +
            self.WEIGHT_HEALTH_SCORE * (avg_health_score * 10)  # Convert 0-10 to 0-100
        )

        # Round to integer
        nutrition_score = round(max(0, min(100, nutrition_score)))

        # Determine level
        nutrition_level = self._get_nutrition_level(nutrition_score)

        return NutritionScore(
            user_id=user_id,
            week_start=week_start,
            week_end=week_end,
            days_logged=days_logged,
            total_days=total_days,
            adherence_percent=round(logging_adherence, 1),
            calorie_adherence_percent=round(avg_calorie_adherence, 1),
            protein_adherence_percent=round(avg_protein_adherence, 1),
            carb_adherence_percent=round(avg_carb_adherence, 1),
            fat_adherence_percent=round(avg_fat_adherence, 1),
            avg_health_score=round(avg_health_score, 1),
            fiber_target_met_days=fiber_met_days,
            nutrition_score=nutrition_score,
            nutrition_level=nutrition_level,
            calculated_at=datetime.now(),
        )

    def _get_nutrition_level(self, score: int) -> NutritionLevel:
        """Get nutrition level from score."""
        if score >= self.LEVEL_THRESHOLDS[NutritionLevel.EXCELLENT]:
            return NutritionLevel.EXCELLENT
        elif score >= self.LEVEL_THRESHOLDS[NutritionLevel.GOOD]:
            return NutritionLevel.GOOD
        elif score >= self.LEVEL_THRESHOLDS[NutritionLevel.FAIR]:
            return NutritionLevel.FAIR
        else:
            return NutritionLevel.NEEDS_WORK

    def get_level_color(self, level: NutritionLevel) -> str:
        """Get color hex for nutrition level."""
        colors = {
            NutritionLevel.EXCELLENT: "#4CAF50",  # Green
            NutritionLevel.GOOD: "#8BC34A",  # Light Green
            NutritionLevel.FAIR: "#FF9800",  # Orange
            NutritionLevel.NEEDS_WORK: "#F44336",  # Red
        }
        return colors.get(level, "#9E9E9E")

    def get_improvement_tips(self, score: NutritionScore) -> List[str]:
        """
        Generate improvement tips based on score breakdown.

        Args:
            score: Calculated nutrition score

        Returns:
            List of improvement tips
        """
        tips = []

        # Logging adherence tips
        if score.adherence_percent < 70:
            tips.append(
                f"Try to log meals more consistently. You logged {score.days_logged}/{score.total_days} days."
            )

        # Calorie tips
        if score.calorie_adherence_percent < 70:
            if score.calorie_adherence_percent < 50:
                tips.append(
                    "Your calorie intake is significantly off target. Focus on portion awareness."
                )
            else:
                tips.append(
                    "Fine-tune your portion sizes to get closer to your calorie target."
                )

        # Protein tips
        if score.protein_adherence_percent < 70:
            tips.append(
                "Increase protein intake. Try adding lean meats, fish, eggs, or legumes to meals."
            )

        # Fiber tips
        if score.fiber_target_met_days < score.days_logged // 2:
            tips.append(
                "Add more fiber-rich foods like vegetables, fruits, and whole grains."
            )

        # Health score tips
        if score.avg_health_score < 6:
            tips.append(
                "Focus on whole, unprocessed foods to improve your overall food quality."
            )

        # Positive reinforcement
        if not tips:
            tips.append("Great job! Keep up the consistent healthy eating habits.")

        return tips[:4]  # Return max 4 tips

    @staticmethod
    def get_current_week_range() -> tuple:
        """Get start and end dates for current week (Monday-Sunday)."""
        today = date.today()
        week_start = today - timedelta(days=today.weekday())  # Monday
        week_end = week_start + timedelta(days=6)  # Sunday
        return week_start, week_end

    @staticmethod
    def get_previous_week_range() -> tuple:
        """Get start and end dates for previous week."""
        today = date.today()
        current_week_start = today - timedelta(days=today.weekday())
        previous_week_start = current_week_start - timedelta(days=7)
        previous_week_end = current_week_start - timedelta(days=1)
        return previous_week_start, previous_week_end


# Singleton instance
nutrition_calculator_service = NutritionCalculatorService()
