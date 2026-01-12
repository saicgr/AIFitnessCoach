"""
Metabolic Adaptation Service
============================
Detects plateaus and metabolic adaptation during dieting.

This service identifies:
1. Weight plateaus (weight stalled despite caloric deficit)
2. Metabolic adaptation (TDEE dropped significantly)
3. Suggests appropriate interventions (diet break, refeed, etc.)

Based on research showing metabolic adaptation occurs during prolonged dieting:
- TDEE can drop 10-15% beyond what weight loss alone would predict
- Plateaus often occur after 8-12 weeks of continuous dieting
"""

from dataclasses import dataclass
from datetime import datetime, date, timedelta
from typing import List, Optional, Dict, Any
from enum import Enum
import logging

logger = logging.getLogger(__name__)


class AdaptationEventType(str, Enum):
    """Types of metabolic adaptation events."""
    PLATEAU = "plateau"  # Weight stalled despite deficit
    ADAPTATION = "adaptation"  # TDEE dropped significantly
    RECOVERY = "recovery"  # TDEE recovering after diet break


class SuggestedAction(str, Enum):
    """Suggested interventions for adaptation."""
    DIET_BREAK = "diet_break"  # 1-2 weeks at maintenance
    REFEED = "refeed"  # 2-3 high carb days
    INCREASE_ACTIVITY = "increase_activity"  # Add cardio/steps
    REDUCE_DEFICIT = "reduce_deficit"  # Smaller caloric deficit
    PATIENCE = "patience"  # Normal fluctuation, wait it out


@dataclass
class TDEEHistoryEntry:
    """Historical TDEE calculation entry."""
    id: str
    user_id: str
    calculated_at: datetime
    calculated_tdee: int
    weight_change_kg: float
    avg_daily_intake: int
    data_quality_score: float


@dataclass
class MetabolicAdaptationEvent:
    """Detected metabolic adaptation event."""
    event_type: AdaptationEventType
    detected_at: datetime

    # Plateau metrics
    plateau_weeks: Optional[int] = None
    expected_weight_change_kg: Optional[float] = None
    actual_weight_change_kg: Optional[float] = None

    # Adaptation metrics
    previous_tdee: Optional[int] = None
    current_tdee: Optional[int] = None
    tdee_drop_percent: Optional[float] = None
    tdee_drop_calories: Optional[int] = None

    # Recommendation
    suggested_action: SuggestedAction = SuggestedAction.PATIENCE
    action_description: str = ""
    severity: str = "low"  # 'low', 'medium', 'high'

    def to_dict(self) -> Dict[str, Any]:
        return {
            "event_type": self.event_type.value,
            "detected_at": self.detected_at.isoformat(),
            "plateau_weeks": self.plateau_weeks,
            "expected_weight_change_kg": self.expected_weight_change_kg,
            "actual_weight_change_kg": self.actual_weight_change_kg,
            "previous_tdee": self.previous_tdee,
            "current_tdee": self.current_tdee,
            "tdee_drop_percent": round(self.tdee_drop_percent, 1) if self.tdee_drop_percent else None,
            "tdee_drop_calories": self.tdee_drop_calories,
            "suggested_action": self.suggested_action.value,
            "action_description": self.action_description,
            "severity": self.severity,
        }


class MetabolicAdaptationService:
    """
    Service for detecting metabolic adaptation and plateaus.

    Metabolic adaptation occurs when the body reduces energy expenditure
    in response to prolonged caloric restriction. This goes beyond the
    expected reduction from weight loss alone.

    Detection criteria:
    1. TDEE drop >10% over 4 weeks (beyond weight loss prediction)
    2. Weight plateau: <0.1kg change over 3 weeks despite deficit
    3. Progress slowdown: Rate of loss decreased >50%
    """

    # Thresholds for detection
    TDEE_DROP_THRESHOLD_MODERATE = 10  # % drop for moderate concern
    TDEE_DROP_THRESHOLD_SEVERE = 15  # % drop for severe concern
    TDEE_DROP_THRESHOLD_CRITICAL = 20  # % drop for critical concern

    PLATEAU_THRESHOLD_KG = 0.2  # Less than this change = plateau
    PLATEAU_MIN_WEEKS = 3  # Minimum weeks to consider a plateau

    PROGRESS_SLOWDOWN_THRESHOLD = 50  # % slowdown in rate of change

    def __init__(self):
        pass

    def detect_metabolic_adaptation(
        self,
        tdee_history: List[TDEEHistoryEntry],
        current_goal: str,
        current_deficit: int = 500
    ) -> Optional[MetabolicAdaptationEvent]:
        """
        Detect if user has experienced metabolic adaptation.

        Args:
            tdee_history: List of TDEE calculations, newest first
            current_goal: User's nutrition goal ('lose_fat', 'build_muscle', 'maintain')
            current_deficit: Current caloric deficit (positive number)

        Returns:
            MetabolicAdaptationEvent if detected, None otherwise
        """
        if len(tdee_history) < 3:
            logger.debug("Insufficient TDEE history for adaptation detection")
            return None

        # Only check for adaptation during fat loss
        if current_goal not in ["lose_fat", "lose_weight"]:
            return None

        # Sort by date (newest first)
        sorted_history = sorted(tdee_history, key=lambda x: x.calculated_at, reverse=True)

        current = sorted_history[0]
        oldest = sorted_history[-1]

        # Calculate TDEE change over the period
        if oldest.calculated_tdee <= 0:
            return None

        tdee_drop = oldest.calculated_tdee - current.calculated_tdee
        tdee_drop_percent = (tdee_drop / oldest.calculated_tdee) * 100

        # Calculate expected TDEE drop from weight loss
        # Rule of thumb: TDEE drops ~10-15 cal per kg of weight lost
        total_weight_change = sum(entry.weight_change_kg for entry in sorted_history)
        expected_tdee_drop = abs(total_weight_change) * 15  # 15 cal/kg

        # Adaptive component = actual drop - expected drop
        adaptive_drop = max(0, tdee_drop - expected_tdee_drop)
        adaptive_drop_percent = (adaptive_drop / oldest.calculated_tdee) * 100 if oldest.calculated_tdee > 0 else 0

        # Check for significant adaptation (beyond expected from weight loss)
        if adaptive_drop_percent >= self.TDEE_DROP_THRESHOLD_MODERATE:
            severity = self._get_severity(adaptive_drop_percent)
            action = self._get_adaptation_recommendation(adaptive_drop_percent, current_deficit)

            return MetabolicAdaptationEvent(
                event_type=AdaptationEventType.ADAPTATION,
                detected_at=datetime.utcnow(),
                previous_tdee=oldest.calculated_tdee,
                current_tdee=current.calculated_tdee,
                tdee_drop_percent=adaptive_drop_percent,
                tdee_drop_calories=int(adaptive_drop),
                suggested_action=action,
                action_description=self._get_action_description(action, adaptive_drop_percent),
                severity=severity
            )

        return None

    def detect_plateau(
        self,
        weight_changes: List[float],  # Weekly weight changes (kg)
        current_goal: str,
        current_deficit: int = 500
    ) -> Optional[MetabolicAdaptationEvent]:
        """
        Detect if user has hit a weight plateau.

        A plateau is defined as minimal weight change over 3+ weeks
        despite maintaining a caloric deficit.

        Args:
            weight_changes: List of weekly weight changes, newest first
            current_goal: User's nutrition goal
            current_deficit: Current caloric deficit

        Returns:
            MetabolicAdaptationEvent if plateau detected, None otherwise
        """
        if len(weight_changes) < self.PLATEAU_MIN_WEEKS:
            return None

        # Only check for plateaus during fat loss
        if current_goal not in ["lose_fat", "lose_weight"]:
            return None

        # Check recent weeks for plateau
        recent_changes = weight_changes[:self.PLATEAU_MIN_WEEKS]
        total_change = sum(recent_changes)

        # Expected change based on deficit (500 cal deficit = ~0.45 kg/week)
        expected_weekly_change = -(current_deficit / 7700)  # 7700 cal per kg
        expected_total_change = expected_weekly_change * len(recent_changes)

        # Is the actual change much less than expected?
        is_plateau = abs(total_change) < self.PLATEAU_THRESHOLD_KG and current_deficit > 300

        if is_plateau:
            action = SuggestedAction.DIET_BREAK

            return MetabolicAdaptationEvent(
                event_type=AdaptationEventType.PLATEAU,
                detected_at=datetime.utcnow(),
                plateau_weeks=len(recent_changes),
                expected_weight_change_kg=round(expected_total_change, 2),
                actual_weight_change_kg=round(total_change, 2),
                suggested_action=action,
                action_description=self._get_action_description(action, plateau_weeks=len(recent_changes)),
                severity="medium"
            )

        return None

    def _get_severity(self, drop_percent: float) -> str:
        """Get severity level based on TDEE drop percentage."""
        if drop_percent >= self.TDEE_DROP_THRESHOLD_CRITICAL:
            return "high"
        elif drop_percent >= self.TDEE_DROP_THRESHOLD_SEVERE:
            return "medium"
        else:
            return "low"

    def _get_adaptation_recommendation(
        self,
        drop_percent: float,
        current_deficit: int
    ) -> SuggestedAction:
        """Get recommended action based on adaptation severity."""
        if drop_percent >= self.TDEE_DROP_THRESHOLD_CRITICAL:
            return SuggestedAction.DIET_BREAK
        elif drop_percent >= self.TDEE_DROP_THRESHOLD_SEVERE:
            return SuggestedAction.REFEED
        elif current_deficit >= 500:
            return SuggestedAction.REDUCE_DEFICIT
        else:
            return SuggestedAction.INCREASE_ACTIVITY

    def _get_action_description(
        self,
        action: SuggestedAction,
        drop_percent: float = 0,
        plateau_weeks: int = 0
    ) -> str:
        """Get human-readable description of recommended action."""
        descriptions = {
            SuggestedAction.DIET_BREAK: (
                f"Your metabolism has slowed by {drop_percent:.0f}%. "
                "Consider a 1-2 week diet break at maintenance calories to restore metabolic rate."
            ) if drop_percent > 0 else (
                f"Weight has stalled for {plateau_weeks} weeks despite your deficit. "
                "A 1-2 week diet break at maintenance can help reset your metabolism."
            ),

            SuggestedAction.REFEED: (
                f"Moderate metabolic adaptation detected ({drop_percent:.0f}% drop). "
                "Try 2-3 high carb refeed days at maintenance to boost metabolic rate."
            ),

            SuggestedAction.INCREASE_ACTIVITY: (
                "Mild metabolic slowdown detected. "
                "Adding 2,000-3,000 steps per day or 2-3 cardio sessions can help."
            ),

            SuggestedAction.REDUCE_DEFICIT: (
                "Your deficit may be too aggressive. "
                "Consider reducing to a 300-400 calorie deficit for more sustainable progress."
            ),

            SuggestedAction.PATIENCE: (
                "Weight fluctuations are normal. "
                "Continue your current plan and reassess in 1-2 weeks."
            ),
        }
        return descriptions.get(action, "")

    def get_adaptation_status(
        self,
        tdee_history: List[TDEEHistoryEntry],
        weight_changes: List[float],
        current_goal: str,
        current_deficit: int = 500
    ) -> Dict[str, Any]:
        """
        Get comprehensive adaptation status including both plateau and TDEE analysis.

        Returns status summary with any detected events and recommendations.
        """
        adaptation_event = self.detect_metabolic_adaptation(
            tdee_history, current_goal, current_deficit
        )

        plateau_event = self.detect_plateau(
            weight_changes, current_goal, current_deficit
        )

        # Determine primary concern
        events = [e for e in [adaptation_event, plateau_event] if e is not None]
        primary_event = None

        if events:
            # Prioritize by severity
            severity_order = {"high": 0, "medium": 1, "low": 2}
            events.sort(key=lambda e: severity_order.get(e.severity, 3))
            primary_event = events[0]

        return {
            "has_adaptation": adaptation_event is not None,
            "has_plateau": plateau_event is not None,
            "primary_event": primary_event.to_dict() if primary_event else None,
            "all_events": [e.to_dict() for e in events],
            "status": "concern" if events else "healthy",
            "message": primary_event.action_description if primary_event else "No metabolic concerns detected."
        }


# Singleton instance
metabolic_adaptation_service = MetabolicAdaptationService()


def get_metabolic_adaptation_service() -> MetabolicAdaptationService:
    """Get the metabolic adaptation service instance."""
    return metabolic_adaptation_service
