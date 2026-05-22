"""
Adaptive TDEE Service
=====================
MacroFactor-style TDEE calculation with EMA smoothing, confidence intervals,
and metabolic adaptation detection.

This service provides:
1. Exponential Moving Average (EMA) weight smoothing
2. Energy balance equation for TDEE calculation
3. Confidence intervals based on data quality
4. Weight trend analysis with outlier filtering
"""

from dataclasses import dataclass, field
from datetime import datetime, date, timedelta
from typing import List, Optional, Dict, Any
import logging
from statistics import stdev, mean

logger = logging.getLogger(__name__)


@dataclass
class WeightLog:
    """Weight log entry.

    `cycle_phase` is an optional cycle-aware annotation: when menstrual
    tracking is enabled for the user, each weigh-in is tagged with the cycle
    phase ("menstrual" / "follicular" / "ovulation" / "luteal") that fell on
    its `logged_at` date. It stays None for users without cycle tracking, so
    every cycle-aware code path below is a no-op for them.
    """
    id: str
    user_id: str
    weight_kg: float
    logged_at: datetime
    source: str = "manual"
    cycle_phase: Optional[str] = None


@dataclass
class FoodLogSummary:
    """Daily food log summary."""
    date: date
    total_calories: int
    protein_g: float
    carbs_g: float
    fat_g: float


@dataclass
class TDEECalculation:
    """Result of TDEE calculation with confidence intervals."""
    tdee: int
    confidence_low: int
    confidence_high: int
    uncertainty_calories: int
    data_quality_score: float
    weight_change_kg: float
    avg_daily_intake: int
    start_weight_kg: float
    end_weight_kg: float
    days_analyzed: int
    food_logs_count: int
    weight_logs_count: int

    def to_dict(self) -> Dict[str, Any]:
        return {
            "tdee": self.tdee,
            "confidence_low": self.confidence_low,
            "confidence_high": self.confidence_high,
            "uncertainty_calories": self.uncertainty_calories,
            "uncertainty_display": f"±{self.uncertainty_calories}",
            "data_quality_score": round(self.data_quality_score, 2),
            "weight_change_kg": round(self.weight_change_kg, 2),
            "avg_daily_intake": self.avg_daily_intake,
            "start_weight_kg": round(self.start_weight_kg, 2),
            "end_weight_kg": round(self.end_weight_kg, 2),
            "days_analyzed": self.days_analyzed,
            "food_logs_count": self.food_logs_count,
            "weight_logs_count": self.weight_logs_count,
        }


@dataclass
class WeightTrend:
    """Weight trend analysis result."""
    smoothed_weight: float
    raw_weight: float
    trend_direction: str  # 'losing', 'stable', 'gaining'
    weekly_rate_kg: float
    confidence: str  # 'low', 'medium', 'high'


class AdaptiveTDEEService:
    """
    MacroFactor-style TDEE calculation service.

    Uses energy balance equation:
    TDEE = Calories In - (Weight Change × Caloric Content)

    Features:
    - EMA smoothing for weight trends
    - Outlier detection and filtering
    - Confidence intervals based on data quality
    - Handles both fat and lean tissue changes
    """

    # EMA smoothing factor (lower = more smoothing, 0.1-0.3 typical)
    EMA_ALPHA = 0.15

    # Caloric content of tissue (kcal per kg)
    CALORIC_CONTENT_FAT = 7700  # ~3500 kcal/lb
    CALORIC_CONTENT_LEAN = 1800  # ~800 kcal/lb

    # Assumed ratio of weight change that is fat vs lean
    # During weight loss: ~75% fat, 25% lean
    # During weight gain: ~50% fat, 50% lean (varies with protein intake)
    ASSUMED_FAT_RATIO_LOSS = 0.75
    ASSUMED_FAT_RATIO_GAIN = 0.50

    # Minimum data requirements
    MIN_FOOD_LOGS = 5
    MIN_WEIGHT_LOGS = 2
    MIN_DAYS = 7

    # TDEE bounds
    MIN_TDEE = 1000
    MAX_TDEE = 6000

    # --- Cycle-aware tuning ----------------------------------------------
    # Luteal-phase water retention spikes scale weight ~1-2 kg without any
    # change in fat mass. A naive energy-balance read of a window that starts
    # and ends in different cycle phases mistakes that water for stored
    # energy. These constants down-weight the noisy weigh-ins and widen the
    # confidence interval when a window is "cycle-contaminated".
    #
    # Phases whose weigh-ins carry transient water weight and so should count
    # less toward the trend / energy-balance calculation.
    CYCLE_NOISY_PHASES = ("luteal", "menstrual")
    # Multiplier applied to a noisy-phase weigh-in's contribution (vs 1.0 for
    # a clean follicular/ovulation reading). 0.4 keeps the point informative
    # without letting luteal water dominate.
    CYCLE_NOISY_WEIGHT = 0.4
    # Extra ±calories added to the TDEE confidence interval when the analysis
    # window is cycle-contaminated (start phase != end phase).
    CYCLE_CONTAMINATION_UNCERTAINTY = 120

    def __init__(self):
        pass

    def calculate_ema_weight(
        self,
        weight_logs: List[WeightLog],
        alpha: float = None
    ) -> float:
        """
        Calculate Exponential Moving Average of weight.

        EMA gives more weight to recent observations while still
        considering historical data. This smooths out daily fluctuations.

        Args:
            weight_logs: List of weight entries sorted by date
            alpha: Smoothing factor (0-1). Higher = less smoothing.

        Returns:
            EMA-smoothed weight value
        """
        if not weight_logs:
            return 0.0

        if len(weight_logs) == 1:
            return weight_logs[0].weight_kg

        alpha = alpha or self.EMA_ALPHA

        # Sort by date (oldest first for forward calculation)
        sorted_logs = sorted(weight_logs, key=lambda x: x.logged_at)

        # Filter outliers first (±3 std dev)
        weights = [log.weight_kg for log in sorted_logs]
        filtered_logs = self._filter_outliers(sorted_logs)

        if not filtered_logs:
            return sorted_logs[-1].weight_kg

        # Calculate EMA
        ema = filtered_logs[0].weight_kg
        for log in filtered_logs[1:]:
            ema = alpha * log.weight_kg + (1 - alpha) * ema

        return round(ema, 2)

    def _filter_outliers(
        self,
        weight_logs: List[WeightLog],
        std_threshold: float = 3.0
    ) -> List[WeightLog]:
        """
        Remove outliers that are more than std_threshold standard deviations
        from the mean.

        This handles measurement errors (wrong scale, clothes on, etc.)
        """
        if len(weight_logs) < 3:
            return weight_logs

        weights = [log.weight_kg for log in weight_logs]
        avg = mean(weights)

        try:
            std = stdev(weights)
        except Exception:
            return weight_logs

        if std == 0:
            return weight_logs

        filtered = [
            log for log in weight_logs
            if abs(log.weight_kg - avg) <= std_threshold * std
        ]

        # Don't filter too aggressively - keep at least 50%
        if len(filtered) < len(weight_logs) * 0.5:
            return weight_logs

        return filtered

    def calculate_cycle_aware_ema_weight(
        self,
        weight_logs: List[WeightLog],
        alpha: float = None
    ) -> float:
        """EMA weight that down-weights luteal/menstrual weigh-ins.

        Identical to `calculate_ema_weight` for users without cycle tracking
        (every `cycle_phase` is None → every blend factor is 1.0). When a
        weigh-in is tagged with a noisy phase its EMA blend factor is scaled
        by `CYCLE_NOISY_WEIGHT`, so transient luteal water retention nudges
        the smoothed trend far less than a clean follicular reading.
        """
        if not weight_logs:
            return 0.0
        if len(weight_logs) == 1:
            return weight_logs[0].weight_kg

        alpha = alpha or self.EMA_ALPHA
        sorted_logs = sorted(weight_logs, key=lambda x: x.logged_at)
        filtered_logs = self._filter_outliers(sorted_logs)
        if not filtered_logs:
            return sorted_logs[-1].weight_kg

        # No cycle tags at all → behave exactly like the plain EMA.
        if not any(log.cycle_phase for log in filtered_logs):
            return self.calculate_ema_weight(weight_logs, alpha)

        ema = filtered_logs[0].weight_kg
        for log in filtered_logs[1:]:
            # A noisy-phase point contributes less new information; an
            # untagged or clean point contributes fully.
            phase_factor = (
                self.CYCLE_NOISY_WEIGHT
                if log.cycle_phase in self.CYCLE_NOISY_PHASES
                else 1.0
            )
            effective_alpha = alpha * phase_factor
            ema = effective_alpha * log.weight_kg + (1 - effective_alpha) * ema

        return round(ema, 2)

    def _is_cycle_contaminated(
        self,
        weight_logs: List[WeightLog]
    ) -> bool:
        """A window is "cycle-contaminated" when its first and last tagged
        weigh-ins sit in different cycle phases — luteal water weight then
        does not cancel start-to-end, so the energy-balance read is noisier.

        No-op (returns False) for users without cycle tracking: with no phase
        tags there is nothing to compare.
        """
        tagged = [log for log in sorted(weight_logs, key=lambda x: x.logged_at)
                  if log.cycle_phase]
        if len(tagged) < 2:
            return False
        return tagged[0].cycle_phase != tagged[-1].cycle_phase

    def calculate_tdee_with_confidence(
        self,
        food_logs: List[FoodLogSummary],
        weight_logs: List[WeightLog],
        days: int = 14
    ) -> Optional[TDEECalculation]:
        """
        Calculate TDEE using energy balance equation with confidence intervals.

        Energy Balance: Calories In - Calories Out = Change in Stored Energy
        Rearranged: TDEE = Calories In - (Weight Change × Caloric Content)

        Args:
            food_logs: Daily food log summaries
            weight_logs: Weight log entries
            days: Analysis period in days

        Returns:
            TDEECalculation with confidence intervals, or None if insufficient data
        """
        # Validate minimum data requirements
        if len(food_logs) < self.MIN_FOOD_LOGS:
            logger.warning(f"Insufficient food logs: {len(food_logs)} < {self.MIN_FOOD_LOGS}")
            return None

        if len(weight_logs) < self.MIN_WEIGHT_LOGS:
            logger.warning(f"Insufficient weight logs: {len(weight_logs)} < {self.MIN_WEIGHT_LOGS}")
            return None

        # Sort weight logs by date
        sorted_weights = sorted(weight_logs, key=lambda x: x.logged_at)

        # Calculate smoothed weights for start and end of period
        # Use first half for start, second half for end
        mid_point = len(sorted_weights) // 2
        start_weights = sorted_weights[:max(mid_point, 1)]
        end_weights = sorted_weights[mid_point:] if mid_point > 0 else sorted_weights

        # Cycle-aware EMA: luteal/menstrual weigh-ins are down-weighted so
        # transient water retention does not masquerade as stored energy.
        # For users without cycle tracking this is identical to the plain EMA.
        start_weight = self.calculate_cycle_aware_ema_weight(start_weights)
        end_weight = self.calculate_cycle_aware_ema_weight(end_weights)
        weight_change_kg = end_weight - start_weight

        # Calculate average daily calorie intake
        total_calories = sum(log.total_calories for log in food_logs)
        avg_daily_intake = total_calories / len(food_logs)

        # Determine fat ratio based on direction of weight change
        if weight_change_kg < 0:  # Losing weight
            fat_ratio = self.ASSUMED_FAT_RATIO_LOSS
        else:  # Gaining weight
            fat_ratio = self.ASSUMED_FAT_RATIO_GAIN

        # Calculate caloric content of weight change
        # (weighted average of fat and lean tissue)
        caloric_content = (
            fat_ratio * self.CALORIC_CONTENT_FAT +
            (1 - fat_ratio) * self.CALORIC_CONTENT_LEAN
        )

        # Calculate actual days between first and last weight
        first_weight_date = sorted_weights[0].logged_at.date()
        last_weight_date = sorted_weights[-1].logged_at.date()
        actual_days = max(1, (last_weight_date - first_weight_date).days)

        # Energy balance equation
        # Daily deficit/surplus from weight change
        daily_energy_change = (weight_change_kg * caloric_content) / actual_days

        # TDEE = What you ate - What you stored/lost
        calculated_tdee = int(avg_daily_intake - daily_energy_change)

        # Clamp to reasonable bounds
        calculated_tdee = max(self.MIN_TDEE, min(self.MAX_TDEE, calculated_tdee))

        # Calculate data quality score
        data_quality = self._calculate_data_quality(
            food_logs_count=len(food_logs),
            weight_logs_count=len(weight_logs),
            days_span=actual_days
        )

        # Calculate confidence interval based on data quality
        uncertainty = self._calculate_uncertainty(data_quality, len(food_logs), len(weight_logs))

        # Cycle-contaminated window: the start and end weigh-ins sit in
        # different cycle phases, so luteal water weight does not cancel
        # start-to-end. Widen the confidence interval to reflect that the
        # TDEE read is genuinely noisier (no-op without cycle tracking).
        if self._is_cycle_contaminated(weight_logs):
            uncertainty += self.CYCLE_CONTAMINATION_UNCERTAINTY
            logger.info(
                "Cycle-contaminated TDEE window — widening uncertainty by "
                f"±{self.CYCLE_CONTAMINATION_UNCERTAINTY} kcal"
            )

        return TDEECalculation(
            tdee=calculated_tdee,
            confidence_low=max(self.MIN_TDEE, calculated_tdee - uncertainty),
            confidence_high=min(self.MAX_TDEE, calculated_tdee + uncertainty),
            uncertainty_calories=uncertainty,
            data_quality_score=data_quality,
            weight_change_kg=weight_change_kg,
            avg_daily_intake=int(avg_daily_intake),
            start_weight_kg=start_weight,
            end_weight_kg=end_weight,
            days_analyzed=actual_days,
            food_logs_count=len(food_logs),
            weight_logs_count=len(weight_logs)
        )

    def _calculate_data_quality(
        self,
        food_logs_count: int,
        weight_logs_count: int,
        days_span: int
    ) -> float:
        """
        Calculate data quality score (0-1) based on:
        - Food logging consistency (logs per day)
        - Weight logging frequency
        - Time span of data

        Higher score = more reliable TDEE estimate
        """
        # Food logging score (target: at least 1 log per day for 14 days)
        target_food_logs = 14
        food_score = min(1.0, food_logs_count / target_food_logs)

        # Weight logging score (target: at least 7 weights over period)
        target_weight_logs = 7
        weight_score = min(1.0, weight_logs_count / target_weight_logs)

        # Time span score (target: at least 14 days)
        target_days = 14
        time_score = min(1.0, days_span / target_days)

        # Weighted average (food logging matters most)
        quality = (
            food_score * 0.50 +
            weight_score * 0.30 +
            time_score * 0.20
        )

        return round(quality, 2)

    def _calculate_uncertainty(
        self,
        data_quality: float,
        food_logs: int,
        weight_logs: int
    ) -> int:
        """
        Calculate uncertainty (±calories) for TDEE estimate.

        Base uncertainty is ±300 cal, which decreases with better data quality.
        MacroFactor achieves ±60-240 cal with good data.
        """
        # Base uncertainty
        base_uncertainty = 300

        # Reduce uncertainty with better data quality
        # At quality=1.0, uncertainty = 100 cal
        # At quality=0.5, uncertainty = 200 cal
        # At quality=0.0, uncertainty = 300 cal
        quality_factor = 1.0 - (data_quality * 0.67)  # 0.33 to 1.0

        uncertainty = int(base_uncertainty * quality_factor)

        # Floor at 60 (MacroFactor's best case)
        return max(60, uncertainty)

    def get_weight_trend(
        self,
        weight_logs: List[WeightLog],
        weeks: int = 2
    ) -> Optional[WeightTrend]:
        """
        Analyze weight trend over specified period.

        Returns smoothed weight, direction, and weekly rate of change.
        """
        if len(weight_logs) < 2:
            return None

        sorted_logs = sorted(weight_logs, key=lambda x: x.logged_at)

        # Get smoothed current weight — cycle-aware so luteal water retention
        # does not show up as a discouraging upward trend (no-op without
        # cycle tracking).
        smoothed = self.calculate_cycle_aware_ema_weight(sorted_logs)
        raw = sorted_logs[-1].weight_kg

        # Calculate weekly rate
        first_weight = sorted_logs[0].weight_kg
        last_weight = sorted_logs[-1].weight_kg
        days = max(1, (sorted_logs[-1].logged_at - sorted_logs[0].logged_at).days)
        weekly_rate = ((last_weight - first_weight) / days) * 7

        # Determine direction
        if weekly_rate < -0.2:
            direction = "losing"
        elif weekly_rate > 0.2:
            direction = "gaining"
        else:
            direction = "stable"

        # Determine confidence
        if len(weight_logs) >= 7:
            confidence = "high"
        elif len(weight_logs) >= 4:
            confidence = "medium"
        else:
            confidence = "low"

        return WeightTrend(
            smoothed_weight=smoothed,
            raw_weight=raw,
            trend_direction=direction,
            weekly_rate_kg=round(weekly_rate, 2),
            confidence=confidence
        )


def tag_weight_logs_with_cycle_phase(
    weight_logs: List[WeightLog],
    period_starts: List[date],
    period_ends: Optional[Dict[date, date]] = None,
    cycle_length_default: int = 28,
    period_length_default: int = 5,
    luteal_length_override: Optional[int] = None,
) -> List[WeightLog]:
    """Annotate each weigh-in with the cycle phase on its `logged_at` date.

    Only call this for users with menstrual tracking enabled — for everyone
    else `weight_logs` should be passed through untouched so the entire
    cycle-aware pathway stays a no-op.

    Mutates and returns the same `WeightLog` objects (sets `.cycle_phase`).
    A weigh-in that cannot be placed in any logged cycle (e.g. it predates
    all period history) keeps `cycle_phase = None` and is treated as
    phase-unknown — never down-weighted.

    The phase math is delegated to `cycle_predictor.phase_on_date`, the single
    source of truth, so the tag agrees with what the rest of the cycle
    feature shows.
    """
    if not weight_logs or not period_starts:
        return weight_logs

    # Imported lazily so the TDEE service has no hard dependency on the
    # cycle module for non-tracking users / other call sites.
    from services.cycle.cycle_predictor import phase_on_date

    for log in weight_logs:
        try:
            log_date = log.logged_at.date()
        except AttributeError:
            # logged_at already a date
            log_date = log.logged_at
        log.cycle_phase = phase_on_date(
            log_date,
            period_starts,
            period_ends=period_ends,
            cycle_length_default=cycle_length_default,
            period_length_default=period_length_default,
            luteal_length_override=luteal_length_override,
        )
    return weight_logs


# Singleton instance
adaptive_tdee_service = AdaptiveTDEEService()


def get_adaptive_tdee_service() -> AdaptiveTDEEService:
    """Get the adaptive TDEE service instance."""
    return adaptive_tdee_service
