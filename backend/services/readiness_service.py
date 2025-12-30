"""
Readiness Service - Hooper Index calculation and workout readiness scoring.

Implements the Hooper Index methodology used by professional sports teams (FC Barcelona, etc.)
to estimate recovery and training readiness WITHOUT requiring wearables.

Research shows subjective wellness questionnaires are often MORE sensitive to daily
fluctuations than objective markers like HRV.
"""
from typing import Dict, List, Optional, Tuple
from datetime import datetime, date, timedelta
from dataclasses import dataclass
from enum import Enum
import logging

logger = logging.getLogger(__name__)


class ReadinessLevel(str, Enum):
    """Readiness level classifications."""
    LOW = "low"           # 0-40: Rest recommended
    MODERATE = "moderate"  # 41-60: Light activity OK
    GOOD = "good"         # 61-80: Normal training OK
    OPTIMAL = "optimal"   # 81-100: Peak performance


class WorkoutIntensity(str, Enum):
    """Recommended workout intensity levels."""
    REST = "rest"
    LIGHT = "light"
    MODERATE = "moderate"
    HIGH = "high"
    MAX = "max"


@dataclass
class ReadinessCheckIn:
    """User's daily readiness check-in data."""
    sleep_quality: int      # 1-7 (1=excellent, 7=very poor)
    fatigue_level: int      # 1-7 (1=fresh, 7=exhausted)
    stress_level: int       # 1-7 (1=relaxed, 7=extremely stressed)
    muscle_soreness: int    # 1-7 (1=none, 7=severe)
    mood: Optional[int] = None           # 1-7 (1=great, 7=terrible)
    energy_level: Optional[int] = None   # 1-7 (1=high, 7=depleted)


@dataclass
class ReadinessResult:
    """Complete readiness calculation result."""
    hooper_index: int           # Sum of 4 core components (4-28, lower is better)
    readiness_score: int        # 0-100 (higher is better)
    readiness_level: ReadinessLevel
    recommended_intensity: WorkoutIntensity
    ai_workout_recommendation: Optional[str]
    ai_insight: Optional[str]
    component_analysis: Dict[str, str]


class ReadinessService:
    """
    Calculates training readiness using the Hooper Index methodology.

    The Hooper Index is validated in sports science research and used by
    professional teams. It consists of 4 components rated 1-7:
    - Sleep quality
    - Fatigue level
    - Stress level
    - Muscle soreness (DOMS)

    A lower Hooper Index indicates better readiness.
    """

    # Hooper Index thresholds (lower is better, range 4-28)
    HOOPER_THRESHOLDS = {
        "optimal": 8,      # 4-8: Peak readiness
        "good": 12,        # 9-12: Ready for normal training
        "moderate": 18,    # 13-18: Reduced capacity
        "low": 28,         # 19-28: Rest recommended
    }

    # Intensity recommendations based on readiness
    INTENSITY_MAP = {
        ReadinessLevel.OPTIMAL: WorkoutIntensity.HIGH,
        ReadinessLevel.GOOD: WorkoutIntensity.MODERATE,
        ReadinessLevel.MODERATE: WorkoutIntensity.LIGHT,
        ReadinessLevel.LOW: WorkoutIntensity.REST,
    }

    # -------------------------------------------------------------------------
    # Core Calculations
    # -------------------------------------------------------------------------

    def calculate_hooper_index(self, check_in: ReadinessCheckIn) -> int:
        """
        Calculate the Hooper Index from check-in data.

        The Hooper Index is the sum of the 4 core components.
        Range: 4-28 (4 = optimal readiness, 28 = complete exhaustion)

        Args:
            check_in: Daily check-in data

        Returns:
            Hooper Index value (4-28)
        """
        return (
            check_in.sleep_quality +
            check_in.fatigue_level +
            check_in.stress_level +
            check_in.muscle_soreness
        )

    def hooper_to_readiness_score(self, hooper_index: int) -> int:
        """
        Convert Hooper Index to 0-100 readiness score.

        Inverts the scale so higher = better (more intuitive for users).

        Args:
            hooper_index: Hooper Index value (4-28)

        Returns:
            Readiness score (0-100)
        """
        # Hooper range is 4-28 (24-point range)
        # Convert to 0-100 where 4 = 100 and 28 = 0
        normalized = (28 - hooper_index) / 24
        return round(normalized * 100)

    def classify_readiness_level(self, readiness_score: int) -> ReadinessLevel:
        """
        Classify readiness score into a level.

        Args:
            readiness_score: 0-100 readiness score

        Returns:
            ReadinessLevel classification
        """
        if readiness_score >= 81:
            return ReadinessLevel.OPTIMAL
        elif readiness_score >= 61:
            return ReadinessLevel.GOOD
        elif readiness_score >= 41:
            return ReadinessLevel.MODERATE
        else:
            return ReadinessLevel.LOW

    def get_recommended_intensity(
        self,
        readiness_level: ReadinessLevel,
        scheduled_workout_type: Optional[str] = None,
    ) -> WorkoutIntensity:
        """
        Get recommended workout intensity based on readiness.

        Args:
            readiness_level: Current readiness level
            scheduled_workout_type: Optional workout type (for context)

        Returns:
            Recommended intensity level
        """
        base_intensity = self.INTENSITY_MAP.get(readiness_level, WorkoutIntensity.MODERATE)

        # If scheduled workout is strength training, we can sometimes push through
        # moderate readiness (research shows strength is less affected than cardio)
        if scheduled_workout_type in ["strength", "hypertrophy"]:
            if readiness_level == ReadinessLevel.MODERATE:
                return WorkoutIntensity.MODERATE  # Can still do strength training

        return base_intensity

    # -------------------------------------------------------------------------
    # Full Readiness Calculation
    # -------------------------------------------------------------------------

    def calculate_readiness(
        self,
        check_in: ReadinessCheckIn,
        scheduled_workout_type: Optional[str] = None,
        recent_workouts: Optional[List[Dict]] = None,
        user_fitness_level: str = "intermediate",
    ) -> ReadinessResult:
        """
        Calculate complete readiness from check-in data.

        Args:
            check_in: Daily check-in data
            scheduled_workout_type: Type of workout scheduled today
            recent_workouts: Recent workout history for context
            user_fitness_level: User's fitness level

        Returns:
            Complete ReadinessResult with scores and recommendations
        """
        # Calculate core metrics
        hooper_index = self.calculate_hooper_index(check_in)
        readiness_score = self.hooper_to_readiness_score(hooper_index)
        readiness_level = self.classify_readiness_level(readiness_score)

        # Get intensity recommendation
        recommended_intensity = self.get_recommended_intensity(
            readiness_level, scheduled_workout_type
        )

        # Analyze individual components
        component_analysis = self._analyze_components(check_in)

        # Generate AI recommendations (placeholder - will be filled by AI service)
        ai_recommendation, ai_insight = self._generate_basic_recommendations(
            check_in, readiness_level, scheduled_workout_type
        )

        return ReadinessResult(
            hooper_index=hooper_index,
            readiness_score=readiness_score,
            readiness_level=readiness_level,
            recommended_intensity=recommended_intensity,
            ai_workout_recommendation=ai_recommendation,
            ai_insight=ai_insight,
            component_analysis=component_analysis,
        )

    # -------------------------------------------------------------------------
    # Component Analysis
    # -------------------------------------------------------------------------

    def _analyze_components(self, check_in: ReadinessCheckIn) -> Dict[str, str]:
        """
        Analyze individual components to identify limiting factors.

        Args:
            check_in: Check-in data

        Returns:
            Dict mapping component to status description
        """
        analysis = {}

        # Sleep quality analysis
        if check_in.sleep_quality <= 2:
            analysis["sleep"] = "excellent"
        elif check_in.sleep_quality <= 4:
            analysis["sleep"] = "adequate"
        else:
            analysis["sleep"] = "poor - may affect recovery"

        # Fatigue analysis
        if check_in.fatigue_level <= 2:
            analysis["fatigue"] = "fresh and energized"
        elif check_in.fatigue_level <= 4:
            analysis["fatigue"] = "normal"
        else:
            analysis["fatigue"] = "elevated - consider lighter session"

        # Stress analysis
        if check_in.stress_level <= 2:
            analysis["stress"] = "low"
        elif check_in.stress_level <= 4:
            analysis["stress"] = "manageable"
        else:
            analysis["stress"] = "high - may impair performance"

        # Soreness analysis
        if check_in.muscle_soreness <= 2:
            analysis["soreness"] = "minimal"
        elif check_in.muscle_soreness <= 4:
            analysis["soreness"] = "moderate - normal training OK"
        else:
            analysis["soreness"] = "significant - avoid training sore muscles"

        return analysis

    def _identify_limiting_factor(self, check_in: ReadinessCheckIn) -> Tuple[str, int]:
        """
        Identify the most limiting factor in readiness.

        Returns:
            Tuple of (factor_name, severity)
        """
        factors = {
            "sleep": check_in.sleep_quality,
            "fatigue": check_in.fatigue_level,
            "stress": check_in.stress_level,
            "soreness": check_in.muscle_soreness,
        }

        worst_factor = max(factors, key=factors.get)
        return worst_factor, factors[worst_factor]

    # -------------------------------------------------------------------------
    # Basic Recommendations (Before AI Enhancement)
    # -------------------------------------------------------------------------

    def _generate_basic_recommendations(
        self,
        check_in: ReadinessCheckIn,
        readiness_level: ReadinessLevel,
        scheduled_workout_type: Optional[str],
    ) -> Tuple[Optional[str], Optional[str]]:
        """
        Generate basic workout and insight recommendations.

        These are template-based. The AI insights service will enhance these.

        Args:
            check_in: Check-in data
            readiness_level: Calculated readiness level
            scheduled_workout_type: Scheduled workout type

        Returns:
            Tuple of (workout_recommendation, insight)
        """
        # Identify limiting factor
        limiting_factor, severity = self._identify_limiting_factor(check_in)

        # Generate recommendation based on level
        if readiness_level == ReadinessLevel.OPTIMAL:
            recommendation = "You're in peak condition! Go for a challenging workout."
            if scheduled_workout_type:
                recommendation = f"Perfect day for your {scheduled_workout_type} session. Push yourself!"
        elif readiness_level == ReadinessLevel.GOOD:
            recommendation = "You're ready for a normal training session."
            if scheduled_workout_type:
                recommendation = f"Good to go for {scheduled_workout_type}. Normal intensity."
        elif readiness_level == ReadinessLevel.MODERATE:
            recommendation = "Consider a lighter session today."
            if scheduled_workout_type == "strength":
                recommendation = f"Strength training OK, but maybe reduce volume by 20%."
            elif scheduled_workout_type:
                recommendation = f"Consider modifying your {scheduled_workout_type} to lighter intensity."
        else:  # LOW
            recommendation = "Rest day recommended. Light movement like walking is OK."

        # Generate insight based on limiting factor
        insights = {
            "sleep": f"Poor sleep is affecting your readiness. Try to prioritize sleep tonight.",
            "fatigue": "Accumulated fatigue detected. Your body needs recovery time.",
            "stress": "High stress can impair workout quality and recovery. Consider stress management.",
            "soreness": "Significant muscle soreness. Avoid training those muscle groups today.",
        }

        insight = None
        if severity >= 5:  # Only mention if it's notably high
            insight = insights.get(limiting_factor)

        return recommendation, insight

    # -------------------------------------------------------------------------
    # Trend Analysis
    # -------------------------------------------------------------------------

    def calculate_readiness_trend(
        self,
        current_score: int,
        historical_scores: List[int],
        days: int = 7,
    ) -> Dict[str, any]:
        """
        Analyze readiness trends over time.

        Args:
            current_score: Today's readiness score
            historical_scores: Previous readiness scores (oldest first)
            days: Number of days to analyze

        Returns:
            Dict with trend information
        """
        if not historical_scores:
            return {
                "average": current_score,
                "trend": "stable",
                "trend_score": 0,
                "days_above_60": 1 if current_score > 60 else 0,
            }

        recent = historical_scores[-days:] if len(historical_scores) >= days else historical_scores
        average = sum(recent) / len(recent)

        # Calculate trend (linear regression slope simplified)
        if len(recent) >= 3:
            first_half = sum(recent[:len(recent)//2]) / (len(recent)//2)
            second_half = sum(recent[len(recent)//2:]) / (len(recent) - len(recent)//2)
            trend_score = second_half - first_half

            if trend_score > 5:
                trend = "improving"
            elif trend_score < -5:
                trend = "declining"
            else:
                trend = "stable"
        else:
            trend = "stable"
            trend_score = 0

        # Count good readiness days
        days_above_60 = sum(1 for s in recent if s > 60)

        return {
            "average": round(average, 1),
            "trend": trend,
            "trend_score": round(trend_score, 1),
            "days_above_60": days_above_60,
        }

    # -------------------------------------------------------------------------
    # Workout Modification Suggestions
    # -------------------------------------------------------------------------

    def suggest_workout_modifications(
        self,
        readiness_level: ReadinessLevel,
        scheduled_workout: Optional[Dict],
    ) -> List[str]:
        """
        Suggest specific workout modifications based on readiness.

        Args:
            readiness_level: Current readiness level
            scheduled_workout: Scheduled workout details

        Returns:
            List of specific modification suggestions
        """
        modifications = []

        if readiness_level == ReadinessLevel.OPTIMAL:
            modifications = [
                "You can push for PRs today",
                "Consider adding an extra set to compound movements",
                "Good day for high-intensity finishers",
            ]
        elif readiness_level == ReadinessLevel.GOOD:
            modifications = [
                "Train as planned",
                "Monitor energy levels and adjust if needed",
            ]
        elif readiness_level == ReadinessLevel.MODERATE:
            modifications = [
                "Reduce total sets by 20-30%",
                "Lower weights by 10-15%",
                "Increase rest periods between sets",
                "Focus on technique over intensity",
                "Skip AMRAP/finisher sets",
            ]
        else:  # LOW
            modifications = [
                "Take a rest day",
                "Light stretching or yoga instead",
                "15-20 minute walk",
                "Foam rolling and mobility work",
                "Focus on hydration and nutrition",
            ]

        return modifications


# Singleton instance
readiness_service = ReadinessService()
