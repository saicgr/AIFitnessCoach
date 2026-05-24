"""
Readiness Service - Hooper Index calculation and workout readiness scoring.

Implements the Hooper Index methodology used by professional sports teams (FC Barcelona, etc.)
to estimate recovery and training readiness WITHOUT requiring wearables.

Research shows subjective wellness questionnaires are often MORE sensitive to daily
fluctuations than objective markers like HRV.
"""
from typing import Any, Dict, List, Optional, Tuple
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
    mood_emoji: Optional[str] = None     # Emoji representing user's mood
    notes: Optional[str] = None          # Free-text wellness notes


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
    objective_sleep_minutes: Optional[int] = None
    objective_recovery_score: Optional[int] = None
    blended: bool = False       # True if any objective data was used


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

    # Sleep minutes -> 1-7 scale (matching Hooper: 1=excellent, 7=very poor)
    SLEEP_MINUTES_SCALE = [
        (480, 1),   # >= 8h = excellent
        (420, 2),   # 7-8h = very good
        (360, 3),   # 6-7h = adequate
        (300, 5),   # 5-6h = poor
        (0,   6),   # < 5h = very poor
    ]

    # -------------------------------------------------------------------------
    # Core Calculations
    # -------------------------------------------------------------------------

    def sleep_minutes_to_scale(self, minutes: int) -> int:
        """
        Convert objective sleep minutes to the 1-7 Hooper scale.

        Args:
            minutes: Total sleep duration in minutes

        Returns:
            Score on 1-7 scale (1=excellent, 7=very poor)
        """
        for threshold, score in self.SLEEP_MINUTES_SCALE:
            if minutes >= threshold:
                return score
        return 6

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
        objective_sleep_minutes: Optional[int] = None,
        objective_recovery_score: Optional[int] = None,
    ) -> ReadinessResult:
        """
        Calculate complete readiness from check-in data.

        Args:
            check_in: Daily check-in data
            scheduled_workout_type: Type of workout scheduled today
            recent_workouts: Recent workout history for context
            user_fitness_level: User's fitness level
            objective_sleep_minutes: Objective sleep duration from wearable (minutes)
            objective_recovery_score: Objective recovery score from wearable (0-100)

        Returns:
            Complete ReadinessResult with scores and recommendations
        """
        blended = False

        # If objective sleep data is provided, blend with subjective sleep
        effective_check_in = check_in
        if objective_sleep_minutes is not None:
            objective_sleep_score = self.sleep_minutes_to_scale(objective_sleep_minutes)
            blended_sleep = round(0.6 * check_in.sleep_quality + 0.4 * objective_sleep_score)
            # Clamp to 1-7
            blended_sleep = max(1, min(7, blended_sleep))
            # Create a new check-in with blended sleep for Hooper calculation
            effective_check_in = ReadinessCheckIn(
                sleep_quality=blended_sleep,
                fatigue_level=check_in.fatigue_level,
                stress_level=check_in.stress_level,
                muscle_soreness=check_in.muscle_soreness,
                mood=check_in.mood,
                energy_level=check_in.energy_level,
            )
            blended = True

        # Calculate core metrics
        hooper_index = self.calculate_hooper_index(effective_check_in)
        readiness_score = self.hooper_to_readiness_score(hooper_index)

        # If objective recovery score is provided, blend with subjective readiness
        if objective_recovery_score is not None:
            readiness_score = round(0.6 * readiness_score + 0.4 * objective_recovery_score)
            readiness_score = max(0, min(100, readiness_score))
            blended = True

        readiness_level = self.classify_readiness_level(readiness_score)

        # Get intensity recommendation
        recommended_intensity = self.get_recommended_intensity(
            readiness_level, scheduled_workout_type
        )

        # Analyze individual components (use original check_in for display)
        component_analysis = self._analyze_components(check_in)

        # Add blend info to component analysis
        if objective_sleep_minutes is not None:
            component_analysis["sleep_blend"] = (
                f"Blended: 60% subjective + 40% objective ({objective_sleep_minutes}min sleep)"
            )
        if objective_recovery_score is not None:
            component_analysis["recovery_blend"] = (
                "Blended: 60% Hooper + 40% objective recovery"
            )

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
            objective_sleep_minutes=objective_sleep_minutes,
            objective_recovery_score=objective_recovery_score,
            blended=blended,
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


# =============================================================================
# Recovery -> training-volume tiers (Phase B1)
# =============================================================================
#
# Maps an objective recovery score (0-100, derived from wearable sleep data —
# see services/user_context/health_activity.py) onto a discrete training tier.
# Recovery-aware workout generation (Phase B3) consumes `volume_multiplier`
# and surfaces `adjustment` to the user / prompt.
#
# This is DELIBERATELY deterministic — no LLM is ever involved in safety- or
# load-affecting classification. The bands and multipliers come directly from
# the approved plan's Phase B1 tier table:
#
#   | Recovery | Tier        | Volume | Adjustment                              |
#   |----------|-------------|--------|-----------------------------------------|
#   | 81-100   | optimal     | 1.0x   | as planned                              |
#   | 61-80    | good        | 1.0x   | as planned                              |
#   | 46-60    | moderate    | 0.85x  | longer rest, trim 1 accessory set       |
#   | 31-45    | compromised | 0.70x  | -10% load, no failure/drop/AMRAP sets   |
#   | 0-30     | low         | 0.55x  | swap to mobility/recovery, -15% load    |
#
# Each entry is keyed by tier name and carries:
#   - min_score / max_score : inclusive recovery-score band
#   - volume_multiplier     : factor applied to planned working-set volume
#   - adjustment            : short human-readable description of the change

RECOVERY_TIERS: Dict[str, Dict[str, Any]] = {
    "optimal": {
        "min_score": 81,
        "max_score": 100,
        "volume_multiplier": 1.0,
        "adjustment": "as planned",
    },
    "good": {
        "min_score": 61,
        "max_score": 80,
        "volume_multiplier": 1.0,
        "adjustment": "as planned",
    },
    "moderate": {
        "min_score": 46,
        "max_score": 60,
        "volume_multiplier": 0.85,
        "adjustment": "longer rest, trim 1 accessory set",
    },
    "compromised": {
        "min_score": 31,
        "max_score": 45,
        "volume_multiplier": 0.70,
        "adjustment": "-10% load, no failure/drop/AMRAP sets",
    },
    "low": {
        "min_score": 0,
        "max_score": 30,
        "volume_multiplier": 0.55,
        "adjustment": "swap to mobility/recovery, -15% load",
    },
}


def map_recovery_to_tier(recovery_score: Optional[int]) -> Optional[Dict[str, Any]]:
    """Map a 0-100 recovery score onto a training-volume tier.

    Deterministic — never calls an LLM. Used by recovery-aware workout
    generation (Phase B3) and the AI-coach health snapshot (Phase B1).

    Args:
        recovery_score: Objective recovery score in 0-100, or None when the
            user has no wearable / no recent sleep data.

    Returns:
        A dict ``{"tier": str, "volume_multiplier": float, "adjustment": str,
        "recovery_score": int}`` for a valid score, or ``None`` when
        ``recovery_score`` is ``None`` — signalling "no adaptation, train as
        planned" to every caller.

    Boundary behaviour (inclusive bands, no gaps):
        30 -> low, 31 -> compromised, 45 -> compromised, 46 -> moderate,
        60 -> moderate, 61 -> good, 80 -> good, 81 -> optimal.
        Scores are clamped to 0-100 so an out-of-range input still resolves.
    """
    if recovery_score is None:
        return None

    # Clamp defensively — an upstream miscalculation must still resolve to a
    # tier rather than silently returning None (which means "no adaptation").
    score = max(0, min(100, int(recovery_score)))

    for tier_name, band in RECOVERY_TIERS.items():
        if band["min_score"] <= score <= band["max_score"]:
            return {
                "tier": tier_name,
                "volume_multiplier": band["volume_multiplier"],
                "adjustment": band["adjustment"],
                "recovery_score": score,
            }

    # Unreachable: the five bands cover 0-100 contiguously. Kept as a guard so
    # a future edit that leaves a gap fails loudly in tests rather than here.
    logger.error(f"map_recovery_to_tier: score {score} matched no tier band")
    return None


# =============================================================================
# Cardio Readiness Extension (Migration 2094) — RHR delta + weekly TRIMP
# =============================================================================
#
# Three optional signals added on top of the subjective Hooper Index when the
# user has wearable / cardio history:
#
# 1. _compute_rhr_delta — today's resting HR vs the user's 28-day baseline,
#    expressed as a percentage. +5% or more is an established overreaching /
#    illness early-warning signal in HRV literature (Buchheit 2014). Returns
#    None when we have fewer than 14 days of RHR readings (calibration).
#
# 2. _compute_weekly_trimp — sum of TRIMP over the last 7 days using the same
#    Banister formula as `training_load_service`. Imported, not reimplemented,
#    so the two views never drift.
#
# 3. _classify_cardio_load_state — coarse 3-bucket label for the tile:
#    undertrained / balanced / overreaching. Driven by ACWR thresholds when
#    available, else weekly-TRIMP volume floors. Returns None during
#    calibration (no chronic baseline).
#
# All three are wired into `compute_readiness` (a thin orchestrator over the
# existing `ReadinessService.calculate_readiness`) which writes the five new
# columns to `readiness_scores`. The original ReadinessService API is
# untouched — callers that don't need the cardio extension keep working.

# Number of days of RHR history required before we surface a baseline.
_RHR_BASELINE_DAYS = 28
_RHR_MIN_HISTORY_DAYS = 14

# RHR delta threshold above which the Hooper-derived readiness score is
# penalised (overreaching / illness signal).
_RHR_PENALTY_DELTA_PCT = 5.0
_RHR_PENALTY_FACTOR = 0.90  # ~10% lower readiness score

# Weekly TRIMP floor (below this → undertrained when no ACWR available).
# 150 = roughly 30 min/day of Z2 cardio across the week.
_WEEKLY_TRIMP_UNDERTRAINED_FLOOR = 150.0


def _compute_rhr_delta(db, user_id: str) -> Optional[Dict[str, Any]]:
    """Compute today's resting-HR delta vs the user's 28-day baseline.

    Pulls resting-HR readings from `cardio_metrics` (the canonical source —
    see migration 2094 docstring + project memory `cardio_metrics`).

    Returns ``{baseline_bpm, today_bpm, delta_pct}`` when at least
    ``_RHR_MIN_HISTORY_DAYS`` (14) distinct days of RHR readings are on file,
    else ``None`` (calibration). Today's value is the most recent reading;
    baseline averages everything inside the last 28 days that is NOT today
    (so today doesn't get compared to itself when there's a single sample).

    All exceptions are swallowed — the readiness write path must not 500 on
    a missing/empty cardio_metrics table for users without wearables.
    """
    try:
        cutoff = (datetime.now(tz=None) - timedelta(days=_RHR_BASELINE_DAYS + 1)).date().isoformat()
        res = (
            db.client.table("cardio_metrics")
            .select("resting_hr, measured_at")
            .eq("user_id", user_id)
            .gte("measured_at", cutoff)
            .order("measured_at", desc=True)
            .execute()
        )
        rows = res.data or []
    except Exception as e:  # pragma: no cover - defensive
        logger.warning(f"[Readiness] _compute_rhr_delta cardio_metrics query failed: {e}")
        rows = []

    # Bucket by day; keep the latest reading per day to avoid weighting a
    # noisy wearable that ships multiple samples on the same day.
    by_day: Dict[date, int] = {}
    for r in rows:
        rhr = r.get("resting_hr")
        if rhr is None or rhr <= 0:
            continue
        when = r.get("measured_at")
        d: Optional[date] = None
        if isinstance(when, str):
            try:
                v = when.replace("Z", "+00:00")
                d = datetime.fromisoformat(v).date() if ("T" in when or " " in when) else date.fromisoformat(when)
            except Exception:
                d = None
        elif isinstance(when, datetime):
            d = when.date()
        elif isinstance(when, date):
            d = when
        if d is None:
            continue
        # Order desc → first hit per day wins (= latest reading per day).
        by_day.setdefault(d, int(rhr))

    # Fallback to users.resting_heart_rate as a single-sample today value
    # when cardio_metrics is empty.
    if not by_day:
        try:
            ures = (
                db.client.table("users")
                .select("resting_heart_rate")
                .eq("id", user_id)
                .limit(1)
                .execute()
            )
            if ures.data and ures.data[0].get("resting_heart_rate"):
                by_day[date.today()] = int(ures.data[0]["resting_heart_rate"])
        except Exception:
            pass

    if len(by_day) < _RHR_MIN_HISTORY_DAYS:
        return None

    today = date.today()
    today_bpm = by_day.get(today) or by_day[max(by_day)]
    baseline_samples = [v for d, v in by_day.items() if d != today]
    if not baseline_samples:
        return None
    baseline_bpm = sum(baseline_samples) / len(baseline_samples)
    if baseline_bpm <= 0:
        return None
    delta_pct = (today_bpm - baseline_bpm) / baseline_bpm * 100.0
    return {
        "baseline_bpm": round(baseline_bpm, 1),
        "today_bpm": int(today_bpm),
        "delta_pct": round(delta_pct, 2),
    }


def _compute_weekly_trimp(db, user_id: str) -> Optional[float]:
    """Sum TRIMP across the last 7 days using `training_load_service`.

    Reuses the same Banister TRIMP math + cardio_logs/cardio_sessions row
    layout, so this number always matches what the training-load timeline
    surfaces. Returns ``None`` when the service surfaces no cardio history
    (so the UI can show "no cardio this week" cleanly vs a misleading 0).
    """
    try:
        # Local import — avoids a top-of-module circular when training_load
        # ever imports readiness (it does not today, but keeps it future-safe).
        from services.training_load_service import compute_training_load_history

        history = compute_training_load_history(db, user_id, days=7)
    except Exception as e:  # pragma: no cover - defensive
        logger.warning(f"[Readiness] _compute_weekly_trimp failed: {e}")
        return None

    if not history:
        return None
    total = sum(p.daily_trimp for p in history)
    # When the last 7 days are all zero AND the user has never logged
    # cardio, surface None (calibration) rather than 0.0.
    if total <= 0:
        return None
    return round(total, 2)


def _classify_cardio_load_state(
    weekly_trimp: Optional[float],
    baseline_acwr: Optional[float],
) -> Optional[str]:
    """Map weekly TRIMP + ACWR onto a 3-bucket cardio-load state.

    Returns one of ``undertrained`` | ``balanced`` | ``overreaching``,
    or ``None`` when there is not enough data to classify.

    ACWR is the primary driver when available (matches the more nuanced
    training_load_service classifier, just compressed from 4→3 buckets):
        acwr < 0.8                       -> undertrained
        0.8 <= acwr <= 1.3               -> balanced
        acwr > 1.3                       -> overreaching   (loading + overreaching merged)

    Falls back to weekly_trimp volume thresholds when ACWR is unavailable
    (calibration window): trimp below the floor → undertrained, else balanced.
    """
    if baseline_acwr is not None:
        if baseline_acwr < 0.8:
            return "undertrained"
        if baseline_acwr <= 1.3:
            return "balanced"
        return "overreaching"

    if weekly_trimp is None:
        return None
    if weekly_trimp < _WEEKLY_TRIMP_UNDERTRAINED_FLOOR:
        return "undertrained"
    return "balanced"


def compute_readiness(
    db,
    user_id: str,
    check_in: ReadinessCheckIn,
    *,
    scheduled_workout_type: Optional[str] = None,
    objective_sleep_minutes: Optional[int] = None,
    objective_recovery_score: Optional[int] = None,
    persist: bool = False,
    score_date: Optional[date] = None,
) -> Dict[str, Any]:
    """Compute readiness + cardio extension fields in one pass.

    Thin orchestrator over `ReadinessService.calculate_readiness` that ALSO:
      - Computes RHR delta, weekly TRIMP, and cardio_load_state.
      - Applies a ~10% readiness penalty when RHR delta is +5% or higher
        (overreaching / illness early-warning signal).
      - Optionally upserts the resulting row into `readiness_scores`,
        populating the new migration-2094 columns alongside the existing
        Hooper fields.

    Returns a dict with the full ReadinessResult fields PLUS:
      rhr_baseline_bpm, rhr_today_bpm, rhr_delta_pct, weekly_trimp,
      cardio_load_state.

    Backward-compat: callers that need only the Hooper score should keep
    using `ReadinessService.calculate_readiness` directly — this function
    is purely additive and never required.
    """
    # 1. Base readiness from existing service (subjective + optional objective).
    base = readiness_service.calculate_readiness(
        check_in,
        scheduled_workout_type=scheduled_workout_type,
        objective_sleep_minutes=objective_sleep_minutes,
        objective_recovery_score=objective_recovery_score,
    )

    # 2. Cardio extension signals (best-effort — None when missing).
    rhr = _compute_rhr_delta(db, user_id) if db is not None else None
    weekly_trimp = _compute_weekly_trimp(db, user_id) if db is not None else None

    baseline_acwr: Optional[float] = None
    try:
        if db is not None:
            from services.training_load_service import current_state

            state = current_state(db, user_id)
            baseline_acwr = state.acwr
    except Exception as e:  # pragma: no cover - defensive
        logger.warning(f"[Readiness] training-load current_state failed: {e}")

    cardio_load_state = _classify_cardio_load_state(weekly_trimp, baseline_acwr)

    # 3. RHR-elevation penalty — drop the Hooper-derived score ~10% when
    # today's RHR is +5% or more above baseline (early overreaching signal).
    readiness_score = base.readiness_score
    if rhr and rhr["delta_pct"] >= _RHR_PENALTY_DELTA_PCT:
        readiness_score = max(0, min(100, round(readiness_score * _RHR_PENALTY_FACTOR)))
        # Reclassify level + intensity after the penalty so the
        # downstream prescription stays consistent.
        readiness_level = readiness_service.classify_readiness_level(readiness_score)
        recommended_intensity = readiness_service.get_recommended_intensity(
            readiness_level, scheduled_workout_type
        )
    else:
        readiness_level = base.readiness_level
        recommended_intensity = base.recommended_intensity

    result: Dict[str, Any] = {
        "hooper_index": base.hooper_index,
        "readiness_score": readiness_score,
        "readiness_level": readiness_level.value,
        "recommended_intensity": recommended_intensity.value,
        "ai_workout_recommendation": base.ai_workout_recommendation,
        "ai_insight": base.ai_insight,
        "component_analysis": base.component_analysis,
        "objective_sleep_minutes": base.objective_sleep_minutes,
        "objective_recovery_score": base.objective_recovery_score,
        "blended": base.blended,
        # Cardio extension fields (migration 2094)
        "rhr_baseline_bpm": rhr["baseline_bpm"] if rhr else None,
        "rhr_today_bpm": rhr["today_bpm"] if rhr else None,
        "rhr_delta_pct": rhr["delta_pct"] if rhr else None,
        "weekly_trimp": weekly_trimp,
        "cardio_load_state": cardio_load_state,
    }

    # 4. Optional persistence — upsert into readiness_scores with both the
    # Hooper columns and the new cardio-extension columns.
    if persist and db is not None:
        try:
            sd = (score_date or date.today()).isoformat()
            record_data = {
                "user_id": user_id,
                "score_date": sd,
                "sleep_quality": check_in.sleep_quality,
                "fatigue_level": check_in.fatigue_level,
                "stress_level": check_in.stress_level,
                "muscle_soreness": check_in.muscle_soreness,
                "mood": check_in.mood,
                "energy_level": check_in.energy_level,
                "hooper_index": result["hooper_index"],
                "readiness_score": result["readiness_score"],
                "readiness_level": result["readiness_level"],
                "ai_workout_recommendation": result["ai_workout_recommendation"],
                "recommended_intensity": result["recommended_intensity"],
                "ai_insight": result["ai_insight"],
                "rhr_baseline_bpm": result["rhr_baseline_bpm"],
                "rhr_today_bpm": result["rhr_today_bpm"],
                "rhr_delta_pct": result["rhr_delta_pct"],
                "weekly_trimp": result["weekly_trimp"],
                "cardio_load_state": result["cardio_load_state"],
                "submitted_at": datetime.now().isoformat(),
            }
            db.client.table("readiness_scores").upsert(
                record_data, on_conflict="user_id,score_date"
            ).execute()
        except Exception as e:
            logger.error(f"[Readiness] compute_readiness persist failed: {e}")

    return result


# Singleton instance
readiness_service = ReadinessService()
