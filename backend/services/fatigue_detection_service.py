"""
Fatigue Detection Service
=========================
Analyzes workout performance in real-time to detect user fatigue
and suggest appropriate set reductions or exercise modifications.

This service monitors:
- Rep decline across sets (>20% decline = fatigue indicator)
- RPE (Rate of Perceived Exertion) increases
- Weight reductions mid-exercise
- Time between sets (longer rest = potential fatigue)
- Historical data for user/exercise combinations

Key Features:
- Real-time fatigue analysis during active workouts
- Personalized thresholds based on user history
- Contextual recommendations (continue, reduce weight, reduce sets, stop)
- Integration with user context logging for AI learning

Usage:
    service = FatigueDetectionService()
    analysis = await service.analyze_performance(
        user_id="user123",
        exercise_name="Bench Press",
        current_set=3,
        total_sets=4,
        set_data=[SetPerformance(reps=10, weight_kg=80, rpe=7), ...]
    )
    recommendation = service.get_set_recommendation(analysis)
"""

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from typing import List, Optional, Literal, Dict, Any
from enum import Enum
import logging
import statistics

from core.db import get_supabase_db

logger = logging.getLogger(__name__)


# =============================================================================
# Data Models
# =============================================================================

@dataclass
class SetPerformance:
    """
    Data from a completed set within an exercise.

    Attributes:
        reps: Number of reps completed in the set
        weight_kg: Weight used in kilograms
        rpe: Rate of Perceived Exertion (1-10 scale, optional)
        duration_seconds: Time taken to complete the set (optional)
        rest_before_seconds: Rest time taken before this set (optional)
        timestamp: When the set was completed (optional)
        is_failure: Whether the set was taken to failure (optional)
        notes: Any notes about the set (optional)
    """
    reps: int
    weight_kg: float
    rpe: Optional[float] = None
    duration_seconds: Optional[int] = None
    rest_before_seconds: Optional[int] = None
    timestamp: Optional[datetime] = None
    is_failure: bool = False
    notes: Optional[str] = None


class FatigueIndicator(str, Enum):
    """Types of fatigue indicators detected."""
    REP_DECLINE = "rep_decline"
    HIGH_RPE = "high_rpe"
    RPE_INCREASE = "rpe_increase"
    WEIGHT_REDUCTION = "weight_reduction"
    EXTENDED_REST = "extended_rest"
    FORM_BREAKDOWN = "form_breakdown"
    FAILURE_SET = "failure_set"
    CUMULATIVE_VOLUME = "cumulative_volume"


class FatigueRecommendation(str, Enum):
    """Possible recommendations based on fatigue analysis."""
    CONTINUE = "continue"
    REDUCE_WEIGHT = "reduce_weight"
    REDUCE_SETS = "reduce_sets"
    STOP_EXERCISE = "stop_exercise"


@dataclass
class FatigueAnalysis:
    """
    Complete analysis of user fatigue for an exercise.

    Attributes:
        fatigue_level: Float 0-1 indicating overall fatigue (0=fresh, 1=exhausted)
        indicators: List of detected fatigue indicators
        confidence: Confidence in the analysis (0-1)
        recommendation: Suggested action based on analysis
        message: Human-readable explanation
        suggested_weight_reduction_pct: If reducing weight, suggested percentage
        suggested_remaining_sets: If reducing sets, suggested remaining count
        historical_context: Comparison to user's typical performance
    """
    fatigue_level: float
    indicators: List[str]
    confidence: float
    recommendation: Literal["continue", "reduce_weight", "reduce_sets", "stop_exercise"]
    message: str = ""
    suggested_weight_reduction_pct: Optional[int] = None
    suggested_remaining_sets: Optional[int] = None
    historical_context: Optional[Dict[str, Any]] = None

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for API response."""
        return {
            "fatigue_level": round(self.fatigue_level, 2),
            "indicators": self.indicators,
            "confidence": round(self.confidence, 2),
            "recommendation": self.recommendation,
            "message": self.message,
            "suggested_weight_reduction_pct": self.suggested_weight_reduction_pct,
            "suggested_remaining_sets": self.suggested_remaining_sets,
            "historical_context": self.historical_context,
        }


@dataclass
class SetRecommendation:
    """
    Actionable recommendation for the user based on fatigue analysis.

    Attributes:
        action: The recommended action
        message: User-friendly message explaining the recommendation
        show_prompt: Whether to show a prompt to the user
        prompt_text: Text for the user prompt (if show_prompt is True)
        confidence: Confidence in this recommendation (0-1)
        alternative_actions: Other options the user could consider
    """
    action: str
    message: str
    show_prompt: bool = False
    prompt_text: Optional[str] = None
    confidence: float = 0.5
    alternative_actions: List[str] = field(default_factory=list)

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for API response."""
        return {
            "action": self.action,
            "message": self.message,
            "show_prompt": self.show_prompt,
            "prompt_text": self.prompt_text,
            "confidence": round(self.confidence, 2),
            "alternative_actions": self.alternative_actions,
        }


# =============================================================================
# Fatigue Detection Service
# =============================================================================

class FatigueDetectionService:
    """
    Service for detecting user fatigue during workouts and suggesting adjustments.

    This service analyzes real-time workout performance to detect signs of fatigue
    and provides recommendations to optimize workout safety and effectiveness.

    Key detection mechanisms:
    1. Rep Decline: >20% drop from first set indicates fatigue
    2. RPE Monitoring: RPE 9-10 on multiple sets = high fatigue
    3. Weight Reductions: Mid-exercise weight drops signal fatigue
    4. Rest Time Analysis: Longer than usual rest suggests recovery needs
    5. Historical Comparison: Performance vs user's typical patterns

    Example:
        >>> service = FatigueDetectionService()
        >>> set_data = [
        ...     SetPerformance(reps=12, weight_kg=60, rpe=6),
        ...     SetPerformance(reps=10, weight_kg=60, rpe=7),
        ...     SetPerformance(reps=8, weight_kg=60, rpe=9),  # Fatigue showing
        ... ]
        >>> analysis = await service.analyze_performance(
        ...     user_id="user123",
        ...     exercise_name="Dumbbell Curl",
        ...     current_set=3,
        ...     total_sets=4,
        ...     set_data=set_data
        ... )
        >>> print(analysis.recommendation)
        "reduce_sets"
    """

    # Threshold constants
    REP_DECLINE_THRESHOLD = 0.20  # 20% decline = fatigue
    SIGNIFICANT_REP_DECLINE_THRESHOLD = 0.30  # 30% = significant fatigue
    HIGH_RPE_THRESHOLD = 9  # RPE >= 9 considered high
    RPE_INCREASE_THRESHOLD = 2  # RPE increase of 2+ between sets
    WEIGHT_REDUCTION_THRESHOLD = 0.10  # 10% weight reduction = fatigue
    EXTENDED_REST_MULTIPLIER = 1.5  # 1.5x normal rest = extended

    # Default expected rest times by exercise type (seconds)
    DEFAULT_REST_TIMES = {
        "compound": 120,  # Squats, Deadlifts, Bench Press
        "isolation": 60,   # Curls, Extensions
        "bodyweight": 60,
        "default": 90,
    }

    def __init__(self, supabase_client=None):
        """
        Initialize the FatigueDetectionService.

        Args:
            supabase_client: Optional Supabase client. If not provided,
                           will use get_supabase_db() for database access.
        """
        self.supabase = supabase_client

    async def analyze_performance(
        self,
        user_id: str,
        exercise_name: str,
        current_set: int,
        total_sets: int,
        set_data: List[SetPerformance],
        workout_id: Optional[str] = None,
        exercise_type: Optional[str] = None,
    ) -> FatigueAnalysis:
        """
        Analyze if user is showing signs of fatigue and suggest adjustments.

        This is the main analysis method that combines all fatigue indicators
        to produce a comprehensive fatigue assessment.

        Args:
            user_id: The user's ID for historical comparison
            exercise_name: Name of the current exercise
            current_set: Current set number (1-indexed)
            total_sets: Total planned sets for this exercise
            set_data: List of SetPerformance data from completed sets
            workout_id: Optional workout ID for context
            exercise_type: Optional exercise type (compound/isolation/bodyweight)

        Returns:
            FatigueAnalysis with fatigue level, indicators, and recommendation

        Raises:
            ValueError: If set_data is empty when current_set > 1

        Example:
            >>> analysis = await service.analyze_performance(
            ...     user_id="user123",
            ...     exercise_name="Squat",
            ...     current_set=3,
            ...     total_sets=5,
            ...     set_data=[SetPerformance(reps=8, weight_kg=100, rpe=7), ...]
            ... )
        """
        logger.info(
            f"[Fatigue Detection] Analyzing {exercise_name} for user {user_id}: "
            f"set {current_set}/{total_sets}, {len(set_data)} sets completed"
        )

        # Initialize tracking variables
        indicators: List[str] = []
        fatigue_scores: List[float] = []
        confidence_factors: List[float] = []

        if not set_data:
            # First set or no data yet - no fatigue to detect
            return FatigueAnalysis(
                fatigue_level=0.0,
                indicators=[],
                confidence=0.5,
                recommendation=FatigueRecommendation.CONTINUE.value,
                message="Starting exercise - no fatigue data yet.",
            )

        # 1. Analyze rep decline across sets
        rep_analysis = self._analyze_rep_decline(set_data)
        if rep_analysis["has_decline"]:
            indicators.append(FatigueIndicator.REP_DECLINE.value)
            fatigue_scores.append(rep_analysis["fatigue_score"])
            confidence_factors.append(0.9)  # High confidence in rep data

        # 2. Analyze RPE patterns
        rpe_analysis = self._analyze_rpe_patterns(set_data)
        if rpe_analysis["has_high_rpe"]:
            indicators.append(FatigueIndicator.HIGH_RPE.value)
            fatigue_scores.append(rpe_analysis["fatigue_score"])
            confidence_factors.append(0.85)  # Subjective but reliable

        if rpe_analysis["has_rpe_increase"]:
            indicators.append(FatigueIndicator.RPE_INCREASE.value)
            fatigue_scores.append(rpe_analysis["increase_score"])
            confidence_factors.append(0.8)

        # 3. Analyze weight reductions
        weight_analysis = self._analyze_weight_reductions(set_data)
        if weight_analysis["has_reduction"]:
            indicators.append(FatigueIndicator.WEIGHT_REDUCTION.value)
            fatigue_scores.append(weight_analysis["fatigue_score"])
            confidence_factors.append(0.95)  # Very objective indicator

        # 4. Analyze rest time patterns
        rest_analysis = self._analyze_rest_patterns(set_data, exercise_type)
        if rest_analysis["has_extended_rest"]:
            indicators.append(FatigueIndicator.EXTENDED_REST.value)
            fatigue_scores.append(rest_analysis["fatigue_score"])
            confidence_factors.append(0.6)  # Less reliable but useful

        # 5. Check for failure sets
        failure_analysis = self._analyze_failure_sets(set_data)
        if failure_analysis["has_failures"]:
            indicators.append(FatigueIndicator.FAILURE_SET.value)
            fatigue_scores.append(failure_analysis["fatigue_score"])
            confidence_factors.append(0.95)  # Very reliable indicator

        # 6. Get historical context if available
        historical_context = await self._get_historical_context(
            user_id, exercise_name, set_data
        )
        if historical_context and historical_context.get("below_average"):
            indicators.append(FatigueIndicator.CUMULATIVE_VOLUME.value)
            fatigue_scores.append(historical_context.get("fatigue_contribution", 0.3))
            confidence_factors.append(0.7)

        # Calculate overall fatigue level (weighted average)
        if fatigue_scores:
            # Weight by confidence
            total_weight = sum(confidence_factors)
            overall_fatigue = sum(
                score * conf for score, conf in zip(fatigue_scores, confidence_factors)
            ) / total_weight if total_weight > 0 else 0
        else:
            overall_fatigue = 0.0

        # Clamp fatigue level to 0-1
        overall_fatigue = max(0.0, min(1.0, overall_fatigue))

        # Calculate confidence in the analysis
        if indicators:
            # More indicators = higher confidence
            indicator_count_factor = min(len(indicators) / 3, 1.0)
            avg_confidence = statistics.mean(confidence_factors) if confidence_factors else 0.5
            overall_confidence = (indicator_count_factor * 0.3) + (avg_confidence * 0.7)
        else:
            overall_confidence = 0.5  # Neutral confidence when no indicators

        # Determine recommendation based on fatigue level and indicators
        recommendation = self._determine_recommendation(
            fatigue_level=overall_fatigue,
            indicators=indicators,
            current_set=current_set,
            total_sets=total_sets,
            set_data=set_data,
        )

        # Generate message
        message = self._generate_fatigue_message(
            fatigue_level=overall_fatigue,
            indicators=indicators,
            recommendation=recommendation,
            current_set=current_set,
            total_sets=total_sets,
        )

        # Calculate suggestions for weight/set reductions
        weight_reduction = None
        remaining_sets = None

        if recommendation == FatigueRecommendation.REDUCE_WEIGHT.value:
            weight_reduction = self._calculate_weight_reduction(overall_fatigue)

        if recommendation == FatigueRecommendation.REDUCE_SETS.value:
            remaining_sets = self._calculate_remaining_sets(
                current_set, total_sets, overall_fatigue
            )

        logger.info(
            f"[Fatigue Detection] Result: fatigue={overall_fatigue:.2f}, "
            f"confidence={overall_confidence:.2f}, recommendation={recommendation}, "
            f"indicators={indicators}"
        )

        return FatigueAnalysis(
            fatigue_level=overall_fatigue,
            indicators=indicators,
            confidence=overall_confidence,
            recommendation=recommendation,
            message=message,
            suggested_weight_reduction_pct=weight_reduction,
            suggested_remaining_sets=remaining_sets,
            historical_context=historical_context,
        )

    def get_set_recommendation(
        self,
        fatigue_analysis: FatigueAnalysis,
    ) -> SetRecommendation:
        """
        Based on fatigue analysis, recommend whether to continue, reduce, or stop.

        This method converts the fatigue analysis into actionable user guidance.

        Args:
            fatigue_analysis: Result from analyze_performance()

        Returns:
            SetRecommendation with action, message, and optional user prompt

        Example:
            >>> analysis = await service.analyze_performance(...)
            >>> recommendation = service.get_set_recommendation(analysis)
            >>> if recommendation.show_prompt:
            ...     print(recommendation.prompt_text)
        """
        rec = fatigue_analysis.recommendation
        fatigue = fatigue_analysis.fatigue_level
        confidence = fatigue_analysis.confidence

        if rec == FatigueRecommendation.CONTINUE.value:
            return SetRecommendation(
                action="continue",
                message="Looking good! Continue with your planned sets.",
                show_prompt=False,
                confidence=confidence,
            )

        elif rec == FatigueRecommendation.REDUCE_WEIGHT.value:
            weight_pct = fatigue_analysis.suggested_weight_reduction_pct or 10
            return SetRecommendation(
                action="reduce_weight",
                message=f"Consider reducing weight by {weight_pct}% for remaining sets.",
                show_prompt=True,
                prompt_text=(
                    f"You seem to be fatiguing. Would you like to reduce the weight "
                    f"by {weight_pct}% for your remaining sets?"
                ),
                confidence=confidence,
                alternative_actions=["continue", "reduce_sets", "stop_exercise"],
            )

        elif rec == FatigueRecommendation.REDUCE_SETS.value:
            remaining = fatigue_analysis.suggested_remaining_sets
            return SetRecommendation(
                action="reduce_sets",
                message=(
                    f"You seem fatigued. Consider ending this exercise after "
                    f"{remaining or 1} more set(s)."
                ),
                show_prompt=True,
                prompt_text=(
                    "You seem fatigued. Would you like to end this exercise early? "
                    "Your performance is declining, and continuing may not be productive."
                ),
                confidence=confidence,
                alternative_actions=["continue", "reduce_weight", "stop_exercise"],
            )

        elif rec == FatigueRecommendation.STOP_EXERCISE.value:
            return SetRecommendation(
                action="stop_exercise",
                message=(
                    "High fatigue detected. It's recommended to stop this exercise "
                    "to prevent injury and overtraining."
                ),
                show_prompt=True,
                prompt_text=(
                    "High fatigue detected! It's strongly recommended to stop "
                    "this exercise. Continuing may increase injury risk. "
                    "Would you like to move to the next exercise?"
                ),
                confidence=confidence,
                alternative_actions=["reduce_weight", "reduce_sets"],
            )

        # Default fallback
        return SetRecommendation(
            action="continue",
            message="Continue with your workout.",
            show_prompt=False,
            confidence=0.5,
        )

    # =========================================================================
    # Private Analysis Methods
    # =========================================================================

    def _analyze_rep_decline(
        self, set_data: List[SetPerformance]
    ) -> Dict[str, Any]:
        """
        Analyze rep decline across sets.

        A decline of >20% from the first set indicates fatigue.
        """
        if len(set_data) < 2:
            return {"has_decline": False, "fatigue_score": 0.0}

        # Compare last set to first set
        first_reps = set_data[0].reps
        last_reps = set_data[-1].reps

        if first_reps == 0:
            return {"has_decline": False, "fatigue_score": 0.0}

        decline_pct = (first_reps - last_reps) / first_reps

        if decline_pct >= self.SIGNIFICANT_REP_DECLINE_THRESHOLD:
            # Significant decline (30%+) = high fatigue
            return {
                "has_decline": True,
                "fatigue_score": min(0.8 + (decline_pct - 0.3) * 0.5, 1.0),
                "decline_percentage": round(decline_pct * 100, 1),
            }
        elif decline_pct >= self.REP_DECLINE_THRESHOLD:
            # Moderate decline (20-30%) = moderate fatigue
            return {
                "has_decline": True,
                "fatigue_score": 0.5 + (decline_pct - 0.2) * 1.5,
                "decline_percentage": round(decline_pct * 100, 1),
            }

        return {
            "has_decline": False,
            "fatigue_score": max(0, decline_pct * 2),
            "decline_percentage": round(decline_pct * 100, 1),
        }

    def _analyze_rpe_patterns(
        self, set_data: List[SetPerformance]
    ) -> Dict[str, Any]:
        """
        Analyze RPE patterns across sets.

        High RPE (9-10) on multiple sets indicates fatigue.
        Increasing RPE across sets also indicates fatigue.
        """
        rpe_values = [s.rpe for s in set_data if s.rpe is not None]

        if not rpe_values:
            return {
                "has_high_rpe": False,
                "has_rpe_increase": False,
                "fatigue_score": 0.0,
                "increase_score": 0.0,
            }

        result = {
            "has_high_rpe": False,
            "has_rpe_increase": False,
            "fatigue_score": 0.0,
            "increase_score": 0.0,
        }

        # Check for high RPE
        high_rpe_sets = [r for r in rpe_values if r >= self.HIGH_RPE_THRESHOLD]
        if len(high_rpe_sets) >= 2:
            result["has_high_rpe"] = True
            result["fatigue_score"] = min(0.7 + (len(high_rpe_sets) - 2) * 0.15, 1.0)
        elif len(high_rpe_sets) == 1:
            # Single high RPE set - moderate concern
            result["fatigue_score"] = 0.4 if rpe_values[-1] >= 9 else 0.2
            if rpe_values[-1] >= 10:
                result["has_high_rpe"] = True
                result["fatigue_score"] = 0.6

        # Check for RPE increase across sets
        if len(rpe_values) >= 2:
            rpe_increase = rpe_values[-1] - rpe_values[0]
            if rpe_increase >= self.RPE_INCREASE_THRESHOLD:
                result["has_rpe_increase"] = True
                result["increase_score"] = min(0.5 + (rpe_increase - 2) * 0.15, 0.8)

        return result

    def _analyze_weight_reductions(
        self, set_data: List[SetPerformance]
    ) -> Dict[str, Any]:
        """
        Analyze if user reduced weight mid-exercise.

        Weight reductions during an exercise often indicate fatigue.
        """
        if len(set_data) < 2:
            return {"has_reduction": False, "fatigue_score": 0.0}

        first_weight = set_data[0].weight_kg
        if first_weight == 0:
            return {"has_reduction": False, "fatigue_score": 0.0}

        # Check for any weight reductions
        reductions = []
        for i, s in enumerate(set_data[1:], 1):
            prev_weight = set_data[i - 1].weight_kg
            if prev_weight > 0 and s.weight_kg < prev_weight:
                reduction_pct = (prev_weight - s.weight_kg) / first_weight
                reductions.append(reduction_pct)

        if not reductions:
            return {"has_reduction": False, "fatigue_score": 0.0}

        total_reduction = sum(reductions)

        if total_reduction >= self.WEIGHT_REDUCTION_THRESHOLD:
            return {
                "has_reduction": True,
                "fatigue_score": min(0.6 + total_reduction * 2, 1.0),
                "reduction_percentage": round(total_reduction * 100, 1),
            }

        return {
            "has_reduction": False,
            "fatigue_score": total_reduction * 3,
            "reduction_percentage": round(total_reduction * 100, 1),
        }

    def _analyze_rest_patterns(
        self,
        set_data: List[SetPerformance],
        exercise_type: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Analyze rest time patterns.

        Longer than expected rest between sets may indicate fatigue.
        """
        rest_times = [
            s.rest_before_seconds for s in set_data
            if s.rest_before_seconds is not None and s.rest_before_seconds > 0
        ]

        if len(rest_times) < 2:
            return {"has_extended_rest": False, "fatigue_score": 0.0}

        # Get expected rest time based on exercise type
        expected_rest = self.DEFAULT_REST_TIMES.get(
            exercise_type or "default",
            self.DEFAULT_REST_TIMES["default"]
        )

        # Calculate average rest in later sets vs earlier
        early_rests = rest_times[:len(rest_times) // 2] if len(rest_times) > 2 else rest_times[:1]
        late_rests = rest_times[len(rest_times) // 2:]

        if not early_rests or not late_rests:
            return {"has_extended_rest": False, "fatigue_score": 0.0}

        avg_early = statistics.mean(early_rests)
        avg_late = statistics.mean(late_rests)

        # Check if late rest times are significantly longer
        if avg_late >= avg_early * self.EXTENDED_REST_MULTIPLIER:
            rest_increase = (avg_late - avg_early) / avg_early
            return {
                "has_extended_rest": True,
                "fatigue_score": min(0.3 + rest_increase * 0.4, 0.7),
                "rest_increase_percentage": round(rest_increase * 100, 1),
            }

        return {"has_extended_rest": False, "fatigue_score": 0.0}

    def _analyze_failure_sets(
        self, set_data: List[SetPerformance]
    ) -> Dict[str, Any]:
        """
        Analyze if any sets were taken to failure.

        Failure sets indicate the muscle is at or near exhaustion.
        """
        failure_sets = [s for s in set_data if s.is_failure]

        if not failure_sets:
            return {"has_failures": False, "fatigue_score": 0.0}

        failure_count = len(failure_sets)

        # More failures = higher fatigue
        if failure_count >= 2:
            return {
                "has_failures": True,
                "fatigue_score": min(0.8 + (failure_count - 2) * 0.1, 1.0),
                "failure_count": failure_count,
            }
        elif failure_count == 1:
            # Single failure set - moderate fatigue indicator
            return {
                "has_failures": True,
                "fatigue_score": 0.5,
                "failure_count": 1,
            }

        return {"has_failures": False, "fatigue_score": 0.0}

    async def _get_historical_context(
        self,
        user_id: str,
        exercise_name: str,
        current_set_data: List[SetPerformance],
    ) -> Optional[Dict[str, Any]]:
        """
        Get historical performance context for comparison.

        Compares current session to user's typical performance for this exercise.
        """
        try:
            db = get_supabase_db()

            # Get recent performance logs for this exercise
            thirty_days_ago = (datetime.now() - timedelta(days=30)).isoformat()

            result = db.client.table("performance_logs").select(
                "weight_kg, reps_completed, rpe, logged_at"
            ).eq("user_id", user_id).ilike(
                "exercise_name", f"%{exercise_name}%"
            ).gte("logged_at", thirty_days_ago).order(
                "logged_at", desc=True
            ).limit(50).execute()

            if not result.data or len(result.data) < 5:
                return None  # Not enough historical data

            # Calculate historical averages
            historical_reps = [r.get("reps_completed", 0) for r in result.data if r.get("reps_completed")]
            historical_weights = [r.get("weight_kg", 0) for r in result.data if r.get("weight_kg")]
            historical_rpes = [r.get("rpe") for r in result.data if r.get("rpe")]

            if not historical_reps or not historical_weights:
                return None

            avg_historical_reps = statistics.mean(historical_reps)
            avg_historical_weight = statistics.mean(historical_weights)
            avg_historical_rpe = statistics.mean(historical_rpes) if historical_rpes else None

            # Compare current session
            current_reps = [s.reps for s in current_set_data]
            current_weights = [s.weight_kg for s in current_set_data]
            current_rpes = [s.rpe for s in current_set_data if s.rpe]

            avg_current_reps = statistics.mean(current_reps) if current_reps else 0
            avg_current_weight = statistics.mean(current_weights) if current_weights else 0
            avg_current_rpe = statistics.mean(current_rpes) if current_rpes else None

            # Determine if below average
            rep_ratio = avg_current_reps / avg_historical_reps if avg_historical_reps > 0 else 1
            weight_ratio = avg_current_weight / avg_historical_weight if avg_historical_weight > 0 else 1

            below_average = rep_ratio < 0.85 or weight_ratio < 0.9

            fatigue_contribution = 0.0
            if rep_ratio < 0.85:
                fatigue_contribution += (0.85 - rep_ratio) * 1.5
            if weight_ratio < 0.9:
                fatigue_contribution += (0.9 - weight_ratio) * 1.0

            return {
                "avg_historical_reps": round(avg_historical_reps, 1),
                "avg_historical_weight": round(avg_historical_weight, 1),
                "avg_historical_rpe": round(avg_historical_rpe, 1) if avg_historical_rpe else None,
                "avg_current_reps": round(avg_current_reps, 1),
                "avg_current_weight": round(avg_current_weight, 1),
                "avg_current_rpe": round(avg_current_rpe, 1) if avg_current_rpe else None,
                "rep_performance_ratio": round(rep_ratio, 2),
                "weight_performance_ratio": round(weight_ratio, 2),
                "below_average": below_average,
                "fatigue_contribution": min(fatigue_contribution, 0.5),
                "historical_sessions_analyzed": len(result.data),
            }

        except Exception as e:
            logger.warning(f"Could not get historical context: {e}")
            return None

    def _determine_recommendation(
        self,
        fatigue_level: float,
        indicators: List[str],
        current_set: int,
        total_sets: int,
        set_data: List[SetPerformance],
    ) -> str:
        """
        Determine the appropriate recommendation based on fatigue analysis.
        """
        remaining_sets = total_sets - current_set

        # Stop exercise if very high fatigue
        if fatigue_level >= 0.85:
            return FatigueRecommendation.STOP_EXERCISE.value

        # Stop if multiple strong indicators present
        strong_indicators = {
            FatigueIndicator.FAILURE_SET.value,
            FatigueIndicator.WEIGHT_REDUCTION.value,
            FatigueIndicator.HIGH_RPE.value,
        }
        strong_count = len(set(indicators) & strong_indicators)
        if strong_count >= 2 and fatigue_level >= 0.6:
            return FatigueRecommendation.STOP_EXERCISE.value

        # Reduce sets if high fatigue and multiple sets remaining
        if fatigue_level >= 0.65 and remaining_sets >= 2:
            return FatigueRecommendation.REDUCE_SETS.value

        # Reduce weight if moderate fatigue with weight-related indicators
        if fatigue_level >= 0.5 and remaining_sets >= 1:
            if FatigueIndicator.HIGH_RPE.value in indicators:
                return FatigueRecommendation.REDUCE_WEIGHT.value
            if FatigueIndicator.REP_DECLINE.value in indicators:
                return FatigueRecommendation.REDUCE_WEIGHT.value

        # Reduce sets for moderate fatigue with only 1 set remaining
        if fatigue_level >= 0.55 and remaining_sets == 1:
            return FatigueRecommendation.REDUCE_SETS.value

        # Continue if fatigue is manageable
        return FatigueRecommendation.CONTINUE.value

    def _generate_fatigue_message(
        self,
        fatigue_level: float,
        indicators: List[str],
        recommendation: str,
        current_set: int,
        total_sets: int,
    ) -> str:
        """
        Generate a human-readable fatigue message.
        """
        if not indicators:
            return "Performance looks good. Continue with your planned sets."

        # Build indicator descriptions
        indicator_messages = []
        if FatigueIndicator.REP_DECLINE.value in indicators:
            indicator_messages.append("rep count is declining")
        if FatigueIndicator.HIGH_RPE.value in indicators:
            indicator_messages.append("effort level is very high")
        if FatigueIndicator.RPE_INCREASE.value in indicators:
            indicator_messages.append("perceived effort is increasing")
        if FatigueIndicator.WEIGHT_REDUCTION.value in indicators:
            indicator_messages.append("weight has been reduced")
        if FatigueIndicator.EXTENDED_REST.value in indicators:
            indicator_messages.append("rest times are getting longer")
        if FatigueIndicator.FAILURE_SET.value in indicators:
            indicator_messages.append("you've hit failure")

        indicators_text = ", ".join(indicator_messages)

        if recommendation == FatigueRecommendation.STOP_EXERCISE.value:
            return f"High fatigue detected: {indicators_text}. Consider stopping this exercise."
        elif recommendation == FatigueRecommendation.REDUCE_SETS.value:
            return f"Fatigue building: {indicators_text}. Consider reducing remaining sets."
        elif recommendation == FatigueRecommendation.REDUCE_WEIGHT.value:
            return f"Some fatigue detected: {indicators_text}. Consider reducing weight."
        else:
            return f"Minor fatigue signs detected: {indicators_text}. Monitor and continue."

    def _calculate_weight_reduction(self, fatigue_level: float) -> int:
        """
        Calculate suggested weight reduction percentage.
        """
        if fatigue_level >= 0.8:
            return 20
        elif fatigue_level >= 0.65:
            return 15
        elif fatigue_level >= 0.5:
            return 10
        else:
            return 5

    def _calculate_remaining_sets(
        self,
        current_set: int,
        total_sets: int,
        fatigue_level: float,
    ) -> int:
        """
        Calculate suggested remaining sets.
        """
        remaining = total_sets - current_set

        if fatigue_level >= 0.85:
            return 0  # Stop now
        elif fatigue_level >= 0.7:
            return max(0, remaining - 2)
        elif fatigue_level >= 0.55:
            return max(1, remaining - 1)
        else:
            return remaining


# =============================================================================
# User Context Logging Integration
# =============================================================================

async def log_fatigue_detection_event(
    user_id: str,
    workout_id: str,
    exercise_name: str,
    fatigue_analysis: FatigueAnalysis,
    user_response: Optional[str] = None,
) -> Optional[str]:
    """
    Log fatigue detection event to user context for AI learning.

    This logs when fatigue is detected and how the user responds,
    enabling future workout generation to learn from user patterns.

    Args:
        user_id: The user's ID
        workout_id: The current workout ID
        exercise_name: The exercise where fatigue was detected
        fatigue_analysis: The fatigue analysis result
        user_response: User's response to suggestion (accepted/declined/ignored)

    Returns:
        Event ID if successful, None otherwise
    """
    try:
        from services.user_context_service import user_context_service, EventType

        event_data = {
            "workout_id": workout_id,
            "exercise_name": exercise_name,
            "fatigue_level": fatigue_analysis.fatigue_level,
            "recommendation": fatigue_analysis.recommendation,
            "indicators": fatigue_analysis.indicators,
            "confidence": fatigue_analysis.confidence,
            "user_response": user_response,
        }

        context = {
            "time_of_day": datetime.now().strftime("%H:%M"),
            "feature": "fatigue_detection",
        }

        # Log as feature interaction
        event_id = await user_context_service.log_event(
            user_id=user_id,
            event_type=EventType.FEATURE_INTERACTION,
            event_data=event_data,
            context=context,
        )

        logger.info(
            f"[Fatigue Detection] Logged event for user {user_id}: "
            f"recommendation={fatigue_analysis.recommendation}, response={user_response}"
        )

        return event_id

    except Exception as e:
        logger.error(f"Failed to log fatigue detection event: {e}")
        return None


# =============================================================================
# Singleton Pattern
# =============================================================================

_fatigue_detection_service_instance: Optional[FatigueDetectionService] = None


def get_fatigue_detection_service() -> FatigueDetectionService:
    """Get or create the FatigueDetectionService singleton."""
    global _fatigue_detection_service_instance
    if _fatigue_detection_service_instance is None:
        _fatigue_detection_service_instance = FatigueDetectionService()
    return _fatigue_detection_service_instance
