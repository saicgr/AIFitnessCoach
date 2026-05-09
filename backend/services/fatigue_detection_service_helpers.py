"""Helper functions extracted from fatigue_detection_service.
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
from __future__ import annotations
import statistics
from typing import Any, Dict, List, Optional, Literal, TYPE_CHECKING
from dataclasses import dataclass
from datetime import datetime
import logging

if TYPE_CHECKING:
    from .fatigue_detection_service import FatigueAnalysis, FatigueDetectionService

logger = logging.getLogger(__name__)


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
        logger.error(f"Failed to log fatigue detection event: {e}", exc_info=True)
        return None


# =============================================================================
# Singleton Pattern
# =============================================================================

_fatigue_detection_service_instance: Optional[FatigueDetectionService] = None


def get_fatigue_detection_service() -> FatigueDetectionService:
    """Get or create the FatigueDetectionService singleton."""
    from .fatigue_detection_service import FatigueDetectionService as _FDS
    global _fatigue_detection_service_instance
    if _fatigue_detection_service_instance is None:
        _fatigue_detection_service_instance = _FDS()
    return _fatigue_detection_service_instance


# =============================================================================
# Standalone Fatigue Detection Function
# =============================================================================

@dataclass
class FatigueAlert:
    """
    Alert generated when significant fatigue is detected during a workout.

    This is a simplified output designed for real-time UI alerts,
    containing only the essential information needed to prompt the user.

    Attributes:
        fatigue_detected: Whether fatigue was detected above threshold
        severity: 'low', 'moderate', 'high', 'critical'
        suggested_weight_reduction: Percentage to reduce weight (0-30)
        suggested_weight: Actual suggested weight expressed in `weight_unit`
            (None for bodyweight exercises where reps are reduced instead).
        weight_unit: Unit for `suggested_weight` ('kg' or 'lb'). Snapshotted
            from the user's workout_weight_unit at alert creation time so a
            mid-session settings flip cannot mismatch labels with values.
        weight_increment: Increment (in `weight_unit`) used to round
            `suggested_weight`. Surfaced so the client can render
            "Reducing weight by N <unit>" without recomputing.
        rep_target_reduction: For bodyweight exercises (no weight to reduce),
            the recommended rep target for the next set. None for weighted
            exercises.
        reasoning: Human-readable explanation of why fatigue was detected
        indicators: List of specific fatigue indicators triggered
        confidence: Confidence score (0-1) in the detection

        suggested_weight_kg: DEPRECATED alias kept for one release of
            backward compatibility (mirrors `suggested_weight` when
            `weight_unit == 'kg'`, otherwise the kg-equivalent).
    """
    fatigue_detected: bool
    severity: Literal["none", "low", "moderate", "high", "critical"]
    suggested_weight_reduction: int
    suggested_weight: Optional[float]
    weight_unit: str
    weight_increment: float
    rep_target_reduction: Optional[int]
    reasoning: str
    indicators: List[str]
    confidence: float
    # Back-compat: callers that still read `.suggested_weight_kg` keep working
    # for one release window. Always populated in kg regardless of `weight_unit`.
    suggested_weight_kg: float = 0.0

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for API response."""
        return {
            "fatigue_detected": self.fatigue_detected,
            "severity": self.severity,
            "suggested_weight_reduction": self.suggested_weight_reduction,
            "suggested_weight": self.suggested_weight,
            "weight_unit": self.weight_unit,
            "weight_increment": self.weight_increment,
            "rep_target_reduction": self.rep_target_reduction,
            # Back-compat field; clients are migrating to `suggested_weight`+`weight_unit`.
            "suggested_weight_kg": self.suggested_weight_kg,
            "reasoning": self.reasoning,
            "indicators": self.indicators,
            "confidence": round(self.confidence, 2),
        }


## Progression pattern properties for fatigue detection context
_PATTERN_PROPERTIES: Dict[str, Dict[str, bool]] = {
    "pyramidUp": {"expects_rep_decline": True, "expects_weight_increase": True, "failure_based": False},
    "reversePyramid": {"expects_rep_decline": False, "expects_weight_decrease": True, "failure_based": False},
    "straightSets": {"expects_rep_decline": False, "expects_weight_decrease": False, "failure_based": False},
    "dropSets": {"expects_rep_decline": False, "expects_weight_decrease": True, "failure_based": True},
    "restPause": {"expects_rep_decline": False, "expects_weight_decrease": False, "failure_based": True},
    "topSetBackOff": {"expects_rep_decline": False, "expects_weight_decrease": True, "failure_based": False},
    "myoReps": {"expects_rep_decline": False, "expects_weight_decrease": False, "failure_based": True},
    "endurance": {"expects_rep_decline": False, "expects_weight_decrease": False, "failure_based": False},
}


def _kg_to_unit(value_kg: float, unit: str) -> float:
    """Convert a kg value to the user's display unit. Pure helper."""
    if unit == "lb":
        return value_kg / 0.453592
    return value_kg


def _unit_to_kg(value: float, unit: str) -> float:
    """Convert a display-unit value back to kg. Pure helper."""
    if unit == "lb":
        return value * 0.453592
    return value


def _round_to_increment(value: float, increment: float) -> float:
    """Round `value` to the nearest `increment`. Falls back to value if
    increment is non-positive (defensive — never divide by zero)."""
    if increment <= 0:
        return round(value, 1)
    return round(value / increment) * increment


def _no_alert(
    current_weight_kg: float,
    weight_unit: str,
    weight_increment: float,
    reasoning: str,
    confidence: float = 0.5,
) -> "FatigueAlert":
    """Build a 'no fatigue' FatigueAlert in the user's display unit.

    Centralized so every early-return path stays consistent.
    """
    suggested_user_unit = _kg_to_unit(current_weight_kg, weight_unit)
    return FatigueAlert(
        fatigue_detected=False,
        severity="none",
        suggested_weight_reduction=0,
        suggested_weight=round(suggested_user_unit, 2),
        weight_unit=weight_unit,
        weight_increment=weight_increment,
        rep_target_reduction=None,
        reasoning=reasoning,
        indicators=[],
        confidence=confidence,
        suggested_weight_kg=round(current_weight_kg, 2),
    )


# Minimum sane load (kg). Below this we recommend rest-pause / stop the
# exercise rather than chasing an even lower weight (edge case 59).
_MIN_LOAD_KG = 2.5


def detect_fatigue(
    session_sets: List[Dict[str, Any]],
    current_weight: float,
    exercise_type: str = "compound",
    target_reps: Optional[int] = None,
    progression_pattern: Optional[str] = None,
    user_workout_unit: str = "kg",
    user_increment_kg: float = 2.5,
    consecutive_dismissals: int = 0,
) -> FatigueAlert:
    """
    Standalone function to detect fatigue from session set data.

    This function analyzes the completed sets in the current exercise session
    and determines if the user is showing signs of fatigue that warrant
    intervention (weight reduction or exercise modification).

    Pattern-aware: when a progression_pattern is provided, expected behaviors
    (e.g., rep decline in Pyramid Up, failure in Drop Sets) are not flagged.

    Triggers for fatigue detection:
    1. Rep decline >= 20% from per-set target (pattern-aware)
    2. RPE increase of 2+ between consecutive sets
    3. Failed set (skipped for failure-based patterns)
    4. Weight reduced mid-exercise (skipped for patterns expecting weight changes)
    5. RIR deviation from expected (primary signal when RIR data available)
    6. RIR trend decline across sets

    Args:
        session_sets: List of completed sets with structure:
            [
                {
                    "reps": int,                    # Reps completed
                    "weight": float,                # Weight used in kg
                    "rpe": Optional[int],           # Rate of Perceived Exertion (6-10)
                    "rir": Optional[int],           # Reps in Reserve (0-5)
                    "is_failure": bool,             # Whether set was to failure
                    "target_reps": Optional[int],   # Per-set target reps from progression
                    "target_weight": Optional[float],# Per-set target weight from progression
                    "target_rir": Optional[int],    # Per-set expected RIR
                },
                ...
            ]
        current_weight: The current weight being used in kg
        exercise_type: Type of exercise ('compound', 'isolation', 'bodyweight')
        target_reps: Optional global target reps (fallback if per-set not provided)
        progression_pattern: Active pattern name (e.g., 'pyramidUp', 'straightSets')

    Returns:
        FatigueAlert with detection result and recommendations
    """
    # Normalize unit: accept 'lbs' (Flutter convention) and 'lb' (backend convention).
    # Edge case: if caller can't fetch user setting, default 'kg' is used so labels
    # never mismatch numbers (feedback_no_silent_fallbacks).
    weight_unit = "lb" if (user_workout_unit or "").lower() in ("lb", "lbs") else "kg"
    # Convert kg increment to user unit so the rounding bucket matches what the
    # user sees on plates / dial. Edge case 49: workout in lb + increment in kg
    # → convert kg increment to lb.
    weight_increment_user = round(_kg_to_unit(user_increment_kg, weight_unit), 3)

    # Edge case 55: per-exercise cooldown — if user has already dismissed two
    # alerts on this exercise, suppress further alerts for the rest of the
    # exercise so we don't nag.
    if consecutive_dismissals >= 2:
        return _no_alert(
            current_weight, weight_unit, weight_increment_user,
            "Alerts paused for this exercise (you've dismissed twice).",
        )

    # Edge case 50/51: first set of session OR swapped-in exercise (no history)
    # → no baseline to compare against. Suppress.
    if not session_sets:
        return _no_alert(
            current_weight, weight_unit, weight_increment_user,
            "No sets completed yet.",
        )

    if len(session_sets) < 2:
        return _no_alert(
            current_weight, weight_unit, weight_increment_user,
            "Only one set completed. Continue with current weight.",
        )

    # Edge case 52: warmup sets must not contribute to fatigue math. They are
    # intentionally light/low-rep and would otherwise pollute decline detection.
    def _is_warmup(s: Dict[str, Any]) -> bool:
        if s.get("is_warmup"):
            return True
        st = (s.get("set_type") or "").lower()
        return st in ("warmup", "warm_up", "warm-up")

    working_sets = [s for s in session_sets if not _is_warmup(s)]
    if len(working_sets) < 2:
        return _no_alert(
            current_weight, weight_unit, weight_increment_user,
            "Need at least 2 working sets to assess fatigue.",
        )

    # Edge case 53: AMRAP sets target RIR 0 — hitting RIR 0 is success, not fatigue.
    # Suppress alerts when the most recent working set was an AMRAP.
    last_target_rir = working_sets[-1].get("target_rir")
    if last_target_rir == 0:
        return _no_alert(
            current_weight, weight_unit, weight_increment_user,
            "AMRAP set — RIR 0 is expected, not fatigue.",
        )

    # Edge case 54: drop sets are intentionally fatiguing within the drop
    # sequence. Skip alerts for those patterns (already covered for failure-
    # based math below, but suppress alerts entirely up front).
    if (progression_pattern or "").lower() in ("dropsets", "drop_sets"):
        return _no_alert(
            current_weight, weight_unit, weight_increment_user,
            "Drop set sequence — fatigue is the intent.",
        )

    # Re-bind: from here on we analyze working_sets only.
    session_sets = working_sets

    # Initialize tracking
    indicators: List[str] = []
    fatigue_scores: List[float] = []
    confidence_factors: List[float] = []
    reasoning_parts: List[str] = []

    # Get pattern properties (empty dict if unknown/not provided)
    pattern_props = _PATTERN_PROPERTIES.get(progression_pattern or "", {})

    # Get reference values.
    # SOURCE FIX (Bug B): we now anchor decline math on the LAST COMPLETED set's
    # actual weight & reps — not target_weight from the progression model. The
    # target is preserved only for the human-readable "below target" framing.
    first_set = session_sets[0]
    last_set = session_sets[-1]
    first_reps = first_set.get("reps", 0)
    last_reps = last_set.get("reps", 0)
    # Actual weight the user lifted on the last completed set (kg). Falls back
    # to current_weight when the set didn't record a weight (bodyweight).
    last_actual_weight_kg = float(last_set.get("weight") or current_weight or 0.0)

    # --------------------------------------------------------------------------
    # Trigger 0 (PRIMARY): RIR deviation from expected
    # --------------------------------------------------------------------------
    for i, s in enumerate(session_sets):
        actual_rir = s.get("rir")
        expected_rir = s.get("target_rir")
        if actual_rir is not None and expected_rir is not None:
            rir_deviation = expected_rir - actual_rir  # positive = harder than expected
            if rir_deviation >= 2:
                indicators.append("rir_deviation")
                fatigue_scores.append(0.70 + min(rir_deviation * 0.05, 0.25))
                confidence_factors.append(0.90)
                reasoning_parts.append(
                    f"Set {i+1}: RIR {actual_rir} vs expected RIR {expected_rir} "
                    f"({rir_deviation} fewer reps in reserve than planned)"
                )
                break  # One deviation is enough

    # RIR trend decline across sets
    rir_values = [s.get("rir") for s in session_sets if s.get("rir") is not None]
    if len(rir_values) >= 2 and "rir_deviation" not in indicators:
        rir_decline = rir_values[0] - rir_values[-1]
        if rir_decline >= 3:
            indicators.append("rir_trend_decline")
            fatigue_scores.append(0.65)
            confidence_factors.append(0.85)
            reasoning_parts.append(
                f"RIR dropped from {rir_values[0]} to {rir_values[-1]} across sets"
            )

    # --------------------------------------------------------------------------
    # Trigger 1: Rep decline from per-set target (pattern-aware)
    # --------------------------------------------------------------------------
    # Use per-set target_reps (from progression model) instead of first-set reps.
    # For patterns that expect rep decline (Pyramid Up), only flag if actual reps
    # fall below the per-set target — not compared to set 1.
    per_set_target = last_set.get("target_reps") or target_reps or first_set.get("target_reps", first_reps)

    if per_set_target > 0 and last_reps > 0:
        # Compare to THIS set's target (not first set or global target)
        decline_from_target = (per_set_target - last_reps) / per_set_target

        # For patterns expecting rep decline, ONLY compare to per-set target
        if pattern_props.get("expects_rep_decline"):
            decline_pct = max(decline_from_target, 0)
        else:
            # Also compare to first set for patterns with constant reps
            first_decline = (first_reps - last_reps) / first_reps if first_reps > 0 else 0
            decline_pct = max(decline_from_target, first_decline)

        if decline_pct >= 0.30:
            indicators.append("severe_rep_decline")
            fatigue_scores.append(0.85)
            confidence_factors.append(0.95)
            reasoning_parts.append(
                f"Reps {round(decline_pct * 100)}% below target for this set"
            )
        elif decline_pct >= 0.20:
            indicators.append("rep_decline")
            fatigue_scores.append(0.65)
            confidence_factors.append(0.90)
            reasoning_parts.append(
                f"Reps {round(decline_pct * 100)}% below target for this set"
            )

    # --------------------------------------------------------------------------
    # Trigger 2: RPE increase of 2+ between consecutive sets
    # --------------------------------------------------------------------------
    rpe_values = [s.get("rpe") for s in session_sets if s.get("rpe") is not None]

    if len(rpe_values) >= 2:
        # Check consecutive set RPE increases
        for i in range(1, len(rpe_values)):
            rpe_jump = rpe_values[i] - rpe_values[i-1]
            if rpe_jump >= 2:
                indicators.append("rpe_spike")
                fatigue_scores.append(0.70 + (rpe_jump - 2) * 0.1)
                confidence_factors.append(0.85)
                reasoning_parts.append(
                    f"RPE jumped from {rpe_values[i-1]} to {rpe_values[i]} "
                    f"(+{rpe_jump}) between sets"
                )
                break  # Only count the first significant spike

        # Check for sustained high RPE
        high_rpe_count = sum(1 for r in rpe_values if r >= 9)
        if high_rpe_count >= 2:
            if "rpe_spike" not in indicators:
                indicators.append("sustained_high_rpe")
                fatigue_scores.append(0.75)
                confidence_factors.append(0.80)
                reasoning_parts.append(
                    f"Multiple sets at high intensity (RPE >= 9 on {high_rpe_count} sets)"
                )

    # --------------------------------------------------------------------------
    # Trigger 3: Failed set (skipped for failure-based patterns)
    # --------------------------------------------------------------------------
    if not pattern_props.get("failure_based"):
        failed_sets = [
            i for i, s in enumerate(session_sets)
            if s.get("reps", 1) == 0 or s.get("is_failure", False)
        ]

        if failed_sets:
            indicators.append("failed_set")
            if len(session_sets) - 1 in failed_sets:
                fatigue_scores.append(0.90)
                confidence_factors.append(0.95)
                reasoning_parts.append("Most recent set resulted in failure")
            else:
                fatigue_scores.append(0.70)
                confidence_factors.append(0.90)
                reasoning_parts.append(
                    f"Set {failed_sets[0] + 1} resulted in failure"
                )

    # --------------------------------------------------------------------------
    # Trigger 4: Weight reduced mid-exercise (skipped for patterns expecting it)
    # --------------------------------------------------------------------------
    expects_weight_change = (
        pattern_props.get("expects_weight_decrease") or
        pattern_props.get("expects_weight_increase")
    )
    if not expects_weight_change:
        weights = [s.get("weight", 0) for s in session_sets]
        if len(weights) >= 2:
            weight_reductions = []
            for i in range(1, len(weights)):
                if weights[i] < weights[i-1]:
                    reduction_pct = (weights[i-1] - weights[i]) / weights[i-1]
                    weight_reductions.append(reduction_pct)

            if weight_reductions:
                total_reduction = sum(weight_reductions)
                indicators.append("weight_reduced")
                fatigue_scores.append(0.60 + min(total_reduction * 2, 0.3))
                confidence_factors.append(0.95)
                reasoning_parts.append(
                    f"Weight was already reduced by {round(total_reduction * 100)}% "
                    f"during this exercise"
                )

    # --------------------------------------------------------------------------
    # Trigger 5: Convert RIR to RPE for analysis (fallback when no target_rir)
    # --------------------------------------------------------------------------
    if "rir_deviation" not in indicators and "rir_trend_decline" not in indicators:
        for s in session_sets:
            rir = s.get("rir")
            if rir is not None and s.get("rpe") is None:
                # Only flag if RIR is lower than expected (or no expectation and very low)
                expected_rir = s.get("target_rir")
                if expected_rir is not None:
                    # Skip — already handled by Trigger 0
                    continue
                # No target RIR — use absolute threshold
                implied_rpe = 10 - rir
                if implied_rpe >= 9:
                    if "sustained_high_rpe" not in indicators and "rpe_spike" not in indicators:
                        indicators.append("high_effort_rir")
                        fatigue_scores.append(0.65)
                        confidence_factors.append(0.75)
                        reasoning_parts.append(
                            f"Set completed with only {rir} rep(s) in reserve"
                        )
                        break

    # --------------------------------------------------------------------------
    # Calculate overall fatigue level and severity
    # --------------------------------------------------------------------------
    if not fatigue_scores:
        return _no_alert(
            current_weight, weight_unit, weight_increment_user,
            "Performance looks good. Continue with current weight.",
            confidence=0.80,
        )

    # Weighted average of fatigue scores
    total_weight = sum(confidence_factors)
    overall_fatigue = sum(
        score * conf for score, conf in zip(fatigue_scores, confidence_factors)
    ) / total_weight if total_weight > 0 else 0

    # Clamp to 0-1
    overall_fatigue = max(0.0, min(1.0, overall_fatigue))

    # Calculate confidence
    avg_confidence = statistics.mean(confidence_factors) if confidence_factors else 0.5
    indicator_boost = min(len(indicators) / 3, 1.0) * 0.2
    overall_confidence = min(avg_confidence + indicator_boost, 1.0)

    # Determine severity
    if overall_fatigue >= 0.85:
        severity = "critical"
    elif overall_fatigue >= 0.70:
        severity = "high"
    elif overall_fatigue >= 0.55:
        severity = "moderate"
    elif overall_fatigue >= 0.40:
        severity = "low"
    else:
        severity = "none"

    # Determine if we should alert
    fatigue_detected = severity in ("moderate", "high", "critical")

    # --------------------------------------------------------------------------
    # Calculate weight reduction recommendation
    # --------------------------------------------------------------------------
    if not fatigue_detected:
        weight_reduction = 0
    elif severity == "critical":
        weight_reduction = 25  # 25% reduction for critical fatigue
    elif severity == "high":
        weight_reduction = 20  # 20% reduction for high fatigue
    elif severity == "moderate":
        weight_reduction = 10  # 10% reduction for moderate fatigue
    else:
        weight_reduction = 5   # 5% reduction for low fatigue

    # Adjust based on exercise type (compound lifts need more careful reduction)
    if exercise_type == "compound":
        # Be slightly more conservative with compound lifts
        weight_reduction = max(weight_reduction - 5, 5) if weight_reduction > 0 else 0
    elif exercise_type == "isolation":
        # Isolation exercises can handle more aggressive reduction
        weight_reduction = min(weight_reduction + 5, 30)

    # ------------------------------------------------------------------
    # Bodyweight branch (edge case 57): no weight to drop → switch to a
    # rep-target reduction instead. We still surface a reasoning string.
    # ------------------------------------------------------------------
    is_bodyweight = exercise_type == "bodyweight" or last_actual_weight_kg <= 0
    if is_bodyweight and fatigue_detected:
        # Reduce target reps by ~weight_reduction% (min 1 rep, never below 1).
        anchor_reps = last_set.get("target_reps") or last_reps or 1
        new_rep_target = max(1, int(round(anchor_reps * (1 - weight_reduction / 100))))
        if reasoning_parts:
            reasoning = ". ".join(reasoning_parts[:3]) + "."
        else:
            reasoning = "Fatigue detected on a bodyweight exercise."
        reasoning += f" Try {new_rep_target} reps next set instead of pushing to failure."
        logger.info(
            f"[Fatigue Detection] detect_fatigue bodyweight: "
            f"detected=True, severity={severity}, rep_target={new_rep_target}, "
            f"indicators={indicators}"
        )
        return FatigueAlert(
            fatigue_detected=True,
            severity=severity,
            suggested_weight_reduction=weight_reduction,
            suggested_weight=None,                     # no weight on bodyweight
            weight_unit=weight_unit,
            weight_increment=weight_increment_user,
            rep_target_reduction=new_rep_target,
            reasoning=reasoning,
            indicators=indicators,
            confidence=overall_confidence,
            suggested_weight_kg=0.0,
        )

    # ------------------------------------------------------------------
    # Weighted branch.
    # SOURCE FIX (Bug B): suggestion anchors on LAST ACTUAL weight, not the
    # progression model's target_weight (which produced the "I never did
    # 45kg" complaint).
    # ------------------------------------------------------------------
    anchor_weight_kg = last_actual_weight_kg if last_actual_weight_kg > 0 else current_weight
    suggested_kg = anchor_weight_kg * (1 - weight_reduction / 100)

    # Edge case 59: already at minimum sane load — recommend rest-pause / stop
    # rather than chasing a lower number that doesn't exist on the rack.
    at_min_load = anchor_weight_kg <= _MIN_LOAD_KG
    if fatigue_detected and at_min_load:
        if reasoning_parts:
            reasoning = ". ".join(reasoning_parts[:3]) + "."
        else:
            reasoning = "Fatigue detected at minimum load."
        reasoning += " Consider rest-pause or ending the exercise."
        return FatigueAlert(
            fatigue_detected=True,
            severity=severity,
            suggested_weight_reduction=0,            # no further reduction possible
            suggested_weight=round(_kg_to_unit(anchor_weight_kg, weight_unit), 2),
            weight_unit=weight_unit,
            weight_increment=weight_increment_user,
            rep_target_reduction=None,
            reasoning=reasoning,
            indicators=indicators,
            confidence=overall_confidence,
            suggested_weight_kg=round(anchor_weight_kg, 2),
        )

    # Convert to user unit, then round to the user's increment in their unit
    # so plate rounding matches what they actually see in the gym.
    suggested_user_unit = _kg_to_unit(suggested_kg, weight_unit)
    suggested_user_unit = _round_to_increment(suggested_user_unit, weight_increment_user)
    # Round-trip back to kg for the back-compat field. We do NOT mutate
    # the user-unit value after this point.
    suggested_kg_rounded = _unit_to_kg(suggested_user_unit, weight_unit)

    # CLAMP FIX (Bug C): only clamp UPWARD when this is actually a progression
    # suggestion (weight_reduction <= 0). A fatigue reduction must NEVER
    # produce a number ≥ the anchor weight — that's the inverted-clamp bug
    # the user hit ("Adjusting weight: 30 → 45 lb").
    if weight_reduction <= 0 and pattern_props.get("expects_weight_increase") and fatigue_detected:
        # Pure progression suggestion — preserve old upward-clamp behavior.
        next_target_weight = last_set.get("target_weight")
        floor_kg = next_target_weight if (next_target_weight and next_target_weight > 0) else anchor_weight_kg
        if suggested_kg_rounded < floor_kg:
            suggested_kg_rounded = floor_kg
            suggested_user_unit = _round_to_increment(
                _kg_to_unit(floor_kg, weight_unit), weight_increment_user,
            )
    elif weight_reduction > 0:
        # Belt-and-suspenders guard: a reduction must strictly decrease.
        # If rounding flipped us above the anchor, force one increment down.
        if suggested_user_unit >= _kg_to_unit(anchor_weight_kg, weight_unit):
            suggested_user_unit = _kg_to_unit(anchor_weight_kg, weight_unit) - weight_increment_user
            suggested_user_unit = max(
                _kg_to_unit(_MIN_LOAD_KG, weight_unit),
                _round_to_increment(suggested_user_unit, weight_increment_user),
            )
            suggested_kg_rounded = _unit_to_kg(suggested_user_unit, weight_unit)

    # Build reasoning message
    if reasoning_parts:
        reasoning = ". ".join(reasoning_parts[:3]) + "."
    else:
        reasoning = "Multiple fatigue indicators detected."

    if fatigue_detected:
        reasoning += f" Consider reducing weight by {weight_reduction}%."

    logger.info(
        f"[Fatigue Detection] detect_fatigue result: "
        f"detected={fatigue_detected}, severity={severity}, "
        f"reduction={weight_reduction}%, suggested={suggested_user_unit}{weight_unit}, "
        f"indicators={indicators}"
    )

    return FatigueAlert(
        fatigue_detected=fatigue_detected,
        severity=severity,
        suggested_weight_reduction=weight_reduction,
        suggested_weight=round(suggested_user_unit, 2),
        weight_unit=weight_unit,
        weight_increment=weight_increment_user,
        rep_target_reduction=None,
        reasoning=reasoning,
        indicators=indicators,
        confidence=overall_confidence,
        suggested_weight_kg=round(suggested_kg_rounded, 2),
    )


# =============================================================================
# Next Set Preview Function
# =============================================================================

@dataclass
class NextSetPreview:
    """
    Preview of recommended parameters for the upcoming set.

    This provides AI-recommended weight and reps for the next set
    based on current performance, 1RM data, and target intensity.

    Attributes:
        recommended_weight: Suggested weight in kg for next set
        recommended_reps: Suggested rep count for next set
        intensity_percentage: Percentage of estimated 1RM
        reasoning: Explanation for the recommendation
        confidence: Confidence in the recommendation (0-1)
        is_final_set: Whether this is recommended as the final set
    """
    recommended_weight: float
    recommended_reps: int
    intensity_percentage: float
    reasoning: str
    confidence: float
    is_final_set: bool = False

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for API response."""
        return {
            "recommended_weight": round(self.recommended_weight, 1),
            "recommended_reps": self.recommended_reps,
            "intensity_percentage": round(self.intensity_percentage, 1),
            "reasoning": self.reasoning,
            "confidence": round(self.confidence, 2),
            "is_final_set": self.is_final_set,
        }


def calculate_next_set_preview(
    session_sets: List[Dict[str, Any]],
    current_set_number: int,
    total_sets: int,
    target_reps: int,
    current_weight: float,
    estimated_1rm: Optional[float] = None,
    target_intensity: float = 0.75,  # Default 75% of 1RM
) -> NextSetPreview:
    """
    Calculate recommended weight and reps for the next set.

    Uses the Brzycki formula for 1RM estimation if not provided,
    and adjusts recommendations based on current performance and fatigue.

    Args:
        session_sets: List of completed sets in current session
        current_set_number: The set number just completed (1-indexed)
        total_sets: Total planned sets for this exercise
        target_reps: Target reps per set
        current_weight: Current weight being used in kg
        estimated_1rm: Optional pre-calculated 1RM in kg
        target_intensity: Target intensity as percentage of 1RM (0.0-1.0)

    Returns:
        NextSetPreview with recommendations

    Example:
        >>> preview = calculate_next_set_preview(
        ...     session_sets=[{"reps": 10, "weight": 100, "rpe": 7}],
        ...     current_set_number=1,
        ...     total_sets=4,
        ...     target_reps=10,
        ...     current_weight=100
        ... )
        >>> print(preview.recommended_weight)  # e.g., 100.0 or 102.5
    """
    next_set_number = current_set_number + 1
    is_final_set = next_set_number >= total_sets

    # If no sets completed, return current parameters
    if not session_sets:
        return NextSetPreview(
            recommended_weight=current_weight,
            recommended_reps=target_reps,
            intensity_percentage=target_intensity * 100,
            reasoning="Starting weight - adjust based on feel.",
            confidence=0.6,
            is_final_set=is_final_set,
        )

    # Get last set data
    last_set = session_sets[-1]
    last_reps = last_set.get("reps", target_reps)
    last_weight = last_set.get("weight", current_weight)
    last_rpe = last_set.get("rpe")
    last_rir = last_set.get("rir")

    # Estimate 1RM if not provided (Brzycki formula)
    if estimated_1rm is None and last_reps > 0 and last_weight > 0:
        # Brzycki: 1RM = weight * (36 / (37 - reps))
        if last_reps < 37:
            estimated_1rm = last_weight * (36 / (37 - last_reps))
        else:
            estimated_1rm = last_weight  # Cap at very high reps

    # Calculate effective RIR (from RPE or RIR)
    effective_rir = None
    if last_rir is not None:
        effective_rir = last_rir
    elif last_rpe is not None:
        effective_rir = max(0, 10 - last_rpe)

    # Determine adjustment based on performance
    recommended_weight = last_weight
    reasoning_parts = []
    confidence = 0.75

    # Check rep performance
    rep_ratio = last_reps / target_reps if target_reps > 0 else 1.0

    if effective_rir is not None:
        if effective_rir >= 4 and rep_ratio >= 1.0:
            # Too easy - increase weight
            increment = 2.5 if last_weight < 50 else 5.0
            recommended_weight = last_weight + increment
            reasoning_parts.append(f"Previous set was easy (RIR {effective_rir})")
            confidence = 0.85
        elif effective_rir >= 2 and rep_ratio >= 0.9:
            # Good working set - maintain
            recommended_weight = last_weight
            reasoning_parts.append("Good intensity, maintain weight")
            confidence = 0.90
        elif effective_rir <= 1 or rep_ratio < 0.8:
            # Struggling - consider reduction
            if is_final_set:
                # Push through on final set
                recommended_weight = last_weight
                reasoning_parts.append("Final set - push through")
                confidence = 0.70
            else:
                # Reduce for sustainability
                reduction = 2.5 if last_weight < 50 else 5.0
                recommended_weight = max(last_weight - reduction, 0)
                reasoning_parts.append("Fatigue detected, reducing for quality reps")
                confidence = 0.80
    else:
        # No RPE/RIR data - use rep performance alone
        if rep_ratio >= 1.1:
            # Exceeded target significantly
            increment = 2.5
            recommended_weight = last_weight + increment
            reasoning_parts.append("Exceeded target reps - try increasing")
            confidence = 0.70
        elif rep_ratio < 0.8:
            # Missed target significantly
            reduction = 2.5
            recommended_weight = max(last_weight - reduction, 0)
            reasoning_parts.append("Below target - reduce for next set")
            confidence = 0.75
        else:
            # Within acceptable range
            recommended_weight = last_weight
            reasoning_parts.append("On track - maintain current weight")
            confidence = 0.80

    # Round to nearest 2.5kg
    recommended_weight = round(recommended_weight / 2.5) * 2.5

    # Calculate intensity percentage
    if estimated_1rm and estimated_1rm > 0:
        intensity_pct = (recommended_weight / estimated_1rm) * 100
    else:
        intensity_pct = target_intensity * 100

    # Build reasoning
    reasoning = ". ".join(reasoning_parts) if reasoning_parts else "Based on previous performance."

    # Adjust reps recommendation based on set number and fatigue
    recommended_reps = target_reps
    if is_final_set and effective_rir is not None and effective_rir <= 1:
        # On final set with low reserves, target same reps but expect fewer
        reasoning += " Final set - give your best effort."

    return NextSetPreview(
        recommended_weight=recommended_weight,
        recommended_reps=recommended_reps,
        intensity_percentage=intensity_pct,
        reasoning=reasoning,
        confidence=confidence,
        is_final_set=is_final_set,
    )
