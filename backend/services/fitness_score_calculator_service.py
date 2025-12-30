"""
Fitness Score Calculator Service
================================
Calculates overall fitness score by combining multiple fitness metrics.

Score Components:
- Strength Score (40%): Overall strength from muscle group scores
- Consistency Score (30%): Workout completion rate
- Nutrition Score (20%): Weekly nutrition adherence
- Readiness Score (10%): Average daily readiness

Fitness Levels:
- beginner: 0-24
- developing: 25-44
- fit: 45-64
- athletic: 65-84
- elite: 85-100
"""

from dataclasses import dataclass, field
from enum import Enum
from typing import Optional, List, Dict, Any
from datetime import date, datetime, timedelta
import logging

logger = logging.getLogger(__name__)


class FitnessLevel(str, Enum):
    """Overall fitness level classification."""
    BEGINNER = "beginner"
    DEVELOPING = "developing"
    FIT = "fit"
    ATHLETIC = "athletic"
    ELITE = "elite"


@dataclass
class ConsistencyData:
    """Data for calculating consistency score."""
    scheduled_workouts: int = 0
    completed_workouts: int = 0
    period_days: int = 30


@dataclass
class FitnessScore:
    """Calculated overall fitness score with breakdown."""
    # Identifiers
    id: Optional[str] = None
    user_id: str = ""
    calculated_date: Optional[date] = None

    # Component scores (0-100)
    strength_score: int = 0
    readiness_score: int = 0
    consistency_score: int = 0
    nutrition_score: int = 0

    # Overall score
    overall_fitness_score: int = 0
    fitness_level: FitnessLevel = FitnessLevel.BEGINNER

    # Weights used (for transparency)
    strength_weight: float = 0.40
    consistency_weight: float = 0.30
    nutrition_weight: float = 0.20
    readiness_weight: float = 0.10

    # AI insights (optional)
    ai_summary: Optional[str] = None
    focus_recommendation: Optional[str] = None

    # Trend
    previous_score: Optional[int] = None
    score_change: Optional[int] = None
    trend: str = "maintaining"  # improving, maintaining, declining

    # Timestamps
    calculated_at: Optional[datetime] = None

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for JSON serialization."""
        return {
            "id": self.id,
            "user_id": self.user_id,
            "calculated_date": self.calculated_date.isoformat() if self.calculated_date else None,
            "strength_score": self.strength_score,
            "readiness_score": self.readiness_score,
            "consistency_score": self.consistency_score,
            "nutrition_score": self.nutrition_score,
            "overall_fitness_score": self.overall_fitness_score,
            "fitness_level": self.fitness_level.value,
            "strength_weight": self.strength_weight,
            "consistency_weight": self.consistency_weight,
            "nutrition_weight": self.nutrition_weight,
            "readiness_weight": self.readiness_weight,
            "ai_summary": self.ai_summary,
            "focus_recommendation": self.focus_recommendation,
            "previous_score": self.previous_score,
            "score_change": self.score_change,
            "trend": self.trend,
            "calculated_at": self.calculated_at.isoformat() if self.calculated_at else None,
        }


class FitnessScoreCalculatorService:
    """Service for calculating overall fitness scores."""

    # Default component weights
    DEFAULT_WEIGHTS = {
        "strength": 0.40,
        "consistency": 0.30,
        "nutrition": 0.20,
        "readiness": 0.10,
    }

    # Level thresholds
    LEVEL_THRESHOLDS = {
        FitnessLevel.ELITE: 85,
        FitnessLevel.ATHLETIC: 65,
        FitnessLevel.FIT: 45,
        FitnessLevel.DEVELOPING: 25,
        FitnessLevel.BEGINNER: 0,
    }

    def __init__(self):
        pass

    def calculate_consistency_score(
        self,
        scheduled: int,
        completed: int,
    ) -> int:
        """
        Calculate workout consistency score.

        Args:
            scheduled: Number of scheduled workouts
            completed: Number of completed workouts

        Returns:
            Consistency score (0-100)
        """
        if scheduled <= 0:
            # No scheduled workouts - give benefit of the doubt
            return 50 if completed == 0 else min(100, completed * 25)

        completion_rate = (completed / scheduled) * 100

        # Bonus for exceeding scheduled workouts
        if completed > scheduled:
            bonus = min(10, (completed - scheduled) * 2)
            completion_rate = min(100, completion_rate + bonus)

        return round(max(0, min(100, completion_rate)))

    def calculate_fitness_score(
        self,
        user_id: str,
        strength_score: int,
        readiness_score: int,
        consistency_score: int,
        nutrition_score: int,
        previous_score: Optional[int] = None,
        custom_weights: Optional[Dict[str, float]] = None,
    ) -> FitnessScore:
        """
        Calculate overall fitness score from components.

        Args:
            user_id: User ID
            strength_score: Overall strength score (0-100)
            readiness_score: Average readiness score (0-100)
            consistency_score: Workout consistency score (0-100)
            nutrition_score: Weekly nutrition score (0-100)
            previous_score: Previous fitness score for trend calculation
            custom_weights: Optional custom weights for components

        Returns:
            FitnessScore with all metrics
        """
        weights = custom_weights or self.DEFAULT_WEIGHTS

        # Validate weights sum to 1.0
        weight_sum = sum(weights.values())
        if abs(weight_sum - 1.0) > 0.01:
            logger.warning(f"Weights sum to {weight_sum}, normalizing...")
            weights = {k: v / weight_sum for k, v in weights.items()}

        # Calculate weighted score
        overall_score = (
            weights.get("strength", 0.40) * strength_score +
            weights.get("consistency", 0.30) * consistency_score +
            weights.get("nutrition", 0.20) * nutrition_score +
            weights.get("readiness", 0.10) * readiness_score
        )

        overall_score = round(max(0, min(100, overall_score)))

        # Determine level
        fitness_level = self._get_fitness_level(overall_score)

        # Calculate trend
        trend = "maintaining"
        score_change = None
        if previous_score is not None:
            score_change = overall_score - previous_score
            if score_change >= 3:
                trend = "improving"
            elif score_change <= -3:
                trend = "declining"

        # Generate focus recommendation
        focus_recommendation = self._get_focus_recommendation(
            strength_score=strength_score,
            readiness_score=readiness_score,
            consistency_score=consistency_score,
            nutrition_score=nutrition_score,
        )

        return FitnessScore(
            user_id=user_id,
            calculated_date=date.today(),
            strength_score=strength_score,
            readiness_score=readiness_score,
            consistency_score=consistency_score,
            nutrition_score=nutrition_score,
            overall_fitness_score=overall_score,
            fitness_level=fitness_level,
            strength_weight=weights.get("strength", 0.40),
            consistency_weight=weights.get("consistency", 0.30),
            nutrition_weight=weights.get("nutrition", 0.20),
            readiness_weight=weights.get("readiness", 0.10),
            focus_recommendation=focus_recommendation,
            previous_score=previous_score,
            score_change=score_change,
            trend=trend,
            calculated_at=datetime.now(),
        )

    def _get_fitness_level(self, score: int) -> FitnessLevel:
        """Get fitness level from score."""
        if score >= self.LEVEL_THRESHOLDS[FitnessLevel.ELITE]:
            return FitnessLevel.ELITE
        elif score >= self.LEVEL_THRESHOLDS[FitnessLevel.ATHLETIC]:
            return FitnessLevel.ATHLETIC
        elif score >= self.LEVEL_THRESHOLDS[FitnessLevel.FIT]:
            return FitnessLevel.FIT
        elif score >= self.LEVEL_THRESHOLDS[FitnessLevel.DEVELOPING]:
            return FitnessLevel.DEVELOPING
        else:
            return FitnessLevel.BEGINNER

    def _get_focus_recommendation(
        self,
        strength_score: int,
        readiness_score: int,
        consistency_score: int,
        nutrition_score: int,
    ) -> str:
        """
        Generate a focus recommendation based on weakest component.

        Args:
            strength_score: Strength score (0-100)
            readiness_score: Readiness score (0-100)
            consistency_score: Consistency score (0-100)
            nutrition_score: Nutrition score (0-100)

        Returns:
            Focus recommendation string
        """
        scores = {
            "strength": strength_score,
            "consistency": consistency_score,
            "nutrition": nutrition_score,
            "readiness": readiness_score,
        }

        # Find the weakest component (weighted by importance)
        weighted_scores = {
            "strength": strength_score * 0.40,
            "consistency": consistency_score * 0.30,
            "nutrition": nutrition_score * 0.20,
            "readiness": readiness_score * 0.10,
        }

        # Find component with most room for improvement
        min_component = min(weighted_scores.keys(), key=lambda k: weighted_scores[k])
        min_score = scores[min_component]

        recommendations = {
            "strength": "Focus on progressive overload in your workouts to build strength.",
            "consistency": "Try to stick to your workout schedule more consistently.",
            "nutrition": "Improve your nutrition by logging meals and hitting macro targets.",
            "readiness": "Prioritize sleep and recovery for better workout performance.",
        }

        # If all scores are good, give positive feedback
        if min(scores.values()) >= 70:
            return "You're doing great across all areas! Keep up the momentum."

        return recommendations.get(min_component, "Keep working on all aspects of your fitness.")

    def get_level_color(self, level: FitnessLevel) -> str:
        """Get color hex for fitness level."""
        colors = {
            FitnessLevel.ELITE: "#9C27B0",  # Purple
            FitnessLevel.ATHLETIC: "#2196F3",  # Blue
            FitnessLevel.FIT: "#4CAF50",  # Green
            FitnessLevel.DEVELOPING: "#FF9800",  # Orange
            FitnessLevel.BEGINNER: "#9E9E9E",  # Grey
        }
        return colors.get(level, "#9E9E9E")

    def get_level_description(self, level: FitnessLevel) -> str:
        """Get description for fitness level."""
        descriptions = {
            FitnessLevel.ELITE: "Top-tier fitness with excellent strength, consistency, and nutrition.",
            FitnessLevel.ATHLETIC: "Strong overall fitness with room for minor improvements.",
            FitnessLevel.FIT: "Good fitness foundation with balanced metrics.",
            FitnessLevel.DEVELOPING: "Building fitness habits with clear progress potential.",
            FitnessLevel.BEGINNER: "Starting your fitness journey - focus on consistency.",
        }
        return descriptions.get(level, "")

    def get_score_breakdown_display(self, score: FitnessScore) -> List[Dict[str, Any]]:
        """
        Get score breakdown for UI display.

        Args:
            score: FitnessScore to break down

        Returns:
            List of component breakdowns with display info
        """
        return [
            {
                "name": "Strength",
                "score": score.strength_score,
                "weight": score.strength_weight,
                "weighted_score": round(score.strength_score * score.strength_weight),
                "icon": "fitness_center",
                "color": "#E91E63",
            },
            {
                "name": "Consistency",
                "score": score.consistency_score,
                "weight": score.consistency_weight,
                "weighted_score": round(score.consistency_score * score.consistency_weight),
                "icon": "calendar_today",
                "color": "#2196F3",
            },
            {
                "name": "Nutrition",
                "score": score.nutrition_score,
                "weight": score.nutrition_weight,
                "weighted_score": round(score.nutrition_score * score.nutrition_weight),
                "icon": "restaurant",
                "color": "#4CAF50",
            },
            {
                "name": "Readiness",
                "score": score.readiness_score,
                "weight": score.readiness_weight,
                "weighted_score": round(score.readiness_score * score.readiness_weight),
                "icon": "battery_charging_full",
                "color": "#FF9800",
            },
        ]


# Singleton instance
fitness_score_calculator_service = FitnessScoreCalculatorService()
