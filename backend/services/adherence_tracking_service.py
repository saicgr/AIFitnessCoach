"""
Adherence Tracking Service
==========================
Tracks how well users adhere to their nutrition targets and calculates
sustainability scores.

This service provides:
1. Daily adherence calculation (actual vs target for each macro)
2. Weekly adherence summaries
3. Sustainability scoring (can the user maintain their current targets?)
4. Recommendations based on adherence patterns
"""

from dataclasses import dataclass
from datetime import datetime, date, timedelta
from typing import List, Optional, Dict, Any
from enum import Enum
import logging

logger = logging.getLogger(__name__)


class SustainabilityRating(str, Enum):
    """Sustainability rating levels."""
    HIGH = "high"  # >70% adherence, low variance
    MEDIUM = "medium"  # 50-70% adherence or moderate variance
    LOW = "low"  # <50% adherence or high variance


@dataclass
class NutritionTargets:
    """User's nutrition targets for a day."""
    calories: int
    protein_g: float
    carbs_g: float
    fat_g: float


@dataclass
class NutritionActuals:
    """User's actual nutrition intake for a day."""
    date: date
    calories: int
    protein_g: float
    carbs_g: float
    fat_g: float
    meals_logged: int = 0


@dataclass
class DailyAdherence:
    """Adherence metrics for a single day."""
    date: date
    calorie_adherence_pct: float
    protein_adherence_pct: float
    carbs_adherence_pct: float
    fat_adherence_pct: float
    overall_adherence_pct: float

    # Direction indicators
    calories_over: bool = False
    protein_over: bool = False

    def to_dict(self) -> Dict[str, Any]:
        return {
            "date": self.date.isoformat(),
            "calorie_adherence_pct": round(self.calorie_adherence_pct, 1),
            "protein_adherence_pct": round(self.protein_adherence_pct, 1),
            "carbs_adherence_pct": round(self.carbs_adherence_pct, 1),
            "fat_adherence_pct": round(self.fat_adherence_pct, 1),
            "overall_adherence_pct": round(self.overall_adherence_pct, 1),
            "calories_over": self.calories_over,
            "protein_over": self.protein_over,
        }


@dataclass
class WeeklyAdherenceSummary:
    """Summary of adherence for a week.

    A week in which the user logged NOTHING is *unknown*, not 0%. All the
    ``avg_*`` fields and ``adherence_variance`` are therefore ``Optional`` and
    stay ``None`` for such a week — there is no honest number to put there, and
    a 0 would grade a user who was on holiday (or simply hadn't started logging)
    as having failed. Use :attr:`has_data` to branch; never coerce these to 0.

    ``days_logged`` / ``days_in_week`` remain real integers for every week:
    "you logged 0 of 7 days" is an observed FACT about coverage, distinct from
    the unobservable "how close to target were you on the days you didn't log".
    """
    week_start: date
    week_end: date
    days_logged: int
    days_in_week: int = 7

    avg_calorie_adherence: Optional[float] = None
    avg_protein_adherence: Optional[float] = None
    avg_carbs_adherence: Optional[float] = None
    avg_fat_adherence: Optional[float] = None
    avg_overall_adherence: Optional[float] = None

    # Consistency (lower = more consistent). None when there is nothing to
    # measure the spread of.
    adherence_variance: Optional[float] = None

    # Days meeting targets (within 5% tolerance)
    days_on_target_calories: int = 0
    days_on_target_protein: int = 0

    @property
    def has_data(self) -> bool:
        """True only when this week has at least one logged day to score."""
        return self.days_logged > 0 and self.avg_overall_adherence is not None

    def to_dict(self) -> Dict[str, Any]:
        def _round(value: Optional[float], digits: int) -> Optional[float]:
            # Explicit null in the payload, NOT 0.0 — the difference between
            # "we don't know" and "you scored zero".
            return None if value is None else round(value, digits)

        return {
            "week_start": self.week_start.isoformat(),
            "week_end": self.week_end.isoformat(),
            "days_logged": self.days_logged,
            "days_in_week": self.days_in_week,
            "has_data": self.has_data,
            "avg_calorie_adherence": _round(self.avg_calorie_adherence, 1),
            "avg_protein_adherence": _round(self.avg_protein_adherence, 1),
            "avg_carbs_adherence": _round(self.avg_carbs_adherence, 1),
            "avg_fat_adherence": _round(self.avg_fat_adherence, 1),
            "avg_overall_adherence": _round(self.avg_overall_adherence, 1),
            "adherence_variance": _round(self.adherence_variance, 2),
            "days_on_target_calories": self.days_on_target_calories,
            "days_on_target_protein": self.days_on_target_protein,
            "logging_rate_pct": (
                round((self.days_logged / self.days_in_week) * 100, 1)
                if self.days_in_week > 0
                else None
            ),
        }


@dataclass
class SustainabilityScore:
    """Overall sustainability assessment.

    Only ever constructed from at least one week that HAS data — see
    :meth:`AdherenceTrackingService.calculate_sustainability_score`, which
    returns ``None`` rather than manufacturing a score out of nothing.
    """
    score: float  # 0-1
    rating: SustainabilityRating
    avg_adherence: float
    consistency_score: float
    logging_score: float
    recommendation: str
    # How many of the supplied weeks actually contained logged days, and how
    # many weeks were in the window at all. Callers surface the first as
    # "weeks analyzed" — counting empty weeks there overstates the evidence.
    weeks_with_data: int = 0
    weeks_in_window: int = 0

    def to_dict(self) -> Dict[str, Any]:
        return {
            "score": round(self.score, 2),
            "rating": self.rating.value,
            "avg_adherence_pct": round(self.avg_adherence, 1),
            "consistency_score": round(self.consistency_score, 2),
            "logging_score": round(self.logging_score, 2),
            "recommendation": self.recommendation,
            "weeks_with_data": self.weeks_with_data,
            "weeks_in_window": self.weeks_in_window,
        }


class AdherenceTrackingService:
    """
    Service for tracking nutrition adherence and sustainability.

    Adherence is calculated as how close actual intake is to targets.
    Perfect adherence (100%) = within 5% of target
    Adherence decreases linearly as deviation increases.

    Weights for overall adherence:
    - Calories: 40% (most important for weight goals)
    - Protein: 35% (critical for body composition)
    - Carbs: 15% (energy and performance)
    - Fat: 10% (hormone function and satiety)
    """

    # Tolerance for "perfect" adherence (5% deviation allowed)
    TOLERANCE = 0.05

    # Weights for overall adherence calculation
    WEIGHT_CALORIES = 0.40
    WEIGHT_PROTEIN = 0.35
    WEIGHT_CARBS = 0.15
    WEIGHT_FAT = 0.10

    # Thresholds for sustainability rating
    SUSTAINABILITY_HIGH_THRESHOLD = 0.70
    SUSTAINABILITY_MEDIUM_THRESHOLD = 0.50

    def __init__(self):
        pass

    def calculate_macro_adherence(
        self,
        actual: float,
        target: float
    ) -> tuple[float, bool]:
        """
        Calculate adherence percentage for a single macro.

        Returns (adherence_pct, is_over)

        Adherence formula:
        - Within tolerance (±5%): 100%
        - Beyond tolerance: Linear decrease
        - At 2x target or 0: 0%
        """
        if target <= 0:
            return (100.0, actual > 0)

        ratio = actual / target

        # Check if over target
        is_over = ratio > 1.0

        # Calculate deviation from target
        deviation = abs(ratio - 1.0)

        if deviation <= self.TOLERANCE:
            # Within tolerance = 100% adherence
            return (100.0, is_over)

        # Linear decrease from tolerance point to 100% deviation
        # At 50% over/under = 50% adherence
        # At 100% over/under = 0% adherence
        excess_deviation = deviation - self.TOLERANCE
        max_excess = 1.0 - self.TOLERANCE  # ~0.95

        adherence = 100.0 * (1.0 - excess_deviation / max_excess)
        adherence = max(0, min(100, adherence))

        return (adherence, is_over)

    def calculate_daily_adherence(
        self,
        targets: NutritionTargets,
        actuals: NutritionActuals
    ) -> DailyAdherence:
        """
        Calculate adherence percentages for a single day.

        Returns DailyAdherence with per-macro and overall scores.
        """
        cal_adh, cal_over = self.calculate_macro_adherence(actuals.calories, targets.calories)
        pro_adh, pro_over = self.calculate_macro_adherence(actuals.protein_g, targets.protein_g)
        carb_adh, _ = self.calculate_macro_adherence(actuals.carbs_g, targets.carbs_g)
        fat_adh, _ = self.calculate_macro_adherence(actuals.fat_g, targets.fat_g)

        # Weighted overall adherence
        overall = (
            cal_adh * self.WEIGHT_CALORIES +
            pro_adh * self.WEIGHT_PROTEIN +
            carb_adh * self.WEIGHT_CARBS +
            fat_adh * self.WEIGHT_FAT
        )

        return DailyAdherence(
            date=actuals.date,
            calorie_adherence_pct=cal_adh,
            protein_adherence_pct=pro_adh,
            carbs_adherence_pct=carb_adh,
            fat_adherence_pct=fat_adh,
            overall_adherence_pct=overall,
            calories_over=cal_over,
            protein_over=pro_over,
        )

    def calculate_weekly_summary(
        self,
        daily_adherences: List[DailyAdherence],
        week_start: date,
        days_in_week: int = 7,
    ) -> WeeklyAdherenceSummary:
        """
        Calculate weekly adherence summary from daily data.

        ``days_in_week`` is the number of days of this week that actually fall
        inside the requested window (7 for a whole week, fewer for the partial
        week at either edge). It is only the denominator of the *coverage*
        metric — pass the real number so a 3-day partial week isn't scored as
        though the user missed 4 days that hadn't happened yet.

        A week with no logged days comes back with ``days_logged=0`` and every
        adherence field left as ``None`` (unknown) — see
        :class:`WeeklyAdherenceSummary`. It is NOT a 0% week.
        """
        week_end = week_start + timedelta(days=6)

        if not daily_adherences:
            return WeeklyAdherenceSummary(
                week_start=week_start,
                week_end=week_end,
                days_logged=0,
                days_in_week=days_in_week,
            )

        days_logged = len(daily_adherences)

        # Calculate averages
        avg_cal = sum(d.calorie_adherence_pct for d in daily_adherences) / days_logged
        avg_pro = sum(d.protein_adherence_pct for d in daily_adherences) / days_logged
        avg_carb = sum(d.carbs_adherence_pct for d in daily_adherences) / days_logged
        avg_fat = sum(d.fat_adherence_pct for d in daily_adherences) / days_logged
        avg_overall = sum(d.overall_adherence_pct for d in daily_adherences) / days_logged

        # Calculate variance (consistency). A single logged day has NO
        # measurable spread — that is unknown, not "perfectly consistent", so
        # it stays None instead of the 0 it used to report (which read as a
        # flawless consistency score off one data point).
        if days_logged > 1:
            overall_values = [d.overall_adherence_pct for d in daily_adherences]
            mean = avg_overall
            variance = sum((v - mean) ** 2 for v in overall_values) / (days_logged - 1)
        else:
            variance = None

        # Count days on target (>95% adherence = on target)
        on_target_threshold = 95
        days_on_target_cal = sum(1 for d in daily_adherences if d.calorie_adherence_pct >= on_target_threshold)
        days_on_target_pro = sum(1 for d in daily_adherences if d.protein_adherence_pct >= on_target_threshold)

        return WeeklyAdherenceSummary(
            week_start=week_start,
            week_end=week_end,
            days_logged=days_logged,
            days_in_week=days_in_week,
            avg_calorie_adherence=avg_cal,
            avg_protein_adherence=avg_pro,
            avg_carbs_adherence=avg_carb,
            avg_fat_adherence=avg_fat,
            avg_overall_adherence=avg_overall,
            adherence_variance=variance,
            days_on_target_calories=days_on_target_cal,
            days_on_target_protein=days_on_target_pro,
        )

    def calculate_sustainability_score(
        self,
        weekly_summaries: List[WeeklyAdherenceSummary]
    ) -> Optional[SustainabilityScore]:
        """
        Calculate overall sustainability score based on adherence history.

        Sustainability = High adherence + Low variance + Consistent logging

        A high sustainability score means the user can likely maintain
        their current targets long-term.

        Returns ``None`` when NO week in the window contains a logged day.
        There is then nothing to assess and the honest answer is "unknown" —
        callers must render an empty state, not a number. (This previously
        returned ``score=0.5 / rating=MEDIUM``, which downstream code read as a
        real 50% sustainability and used to pick the user's calorie deficit.)

        Weeks with ``days_logged == 0`` are excluded from the adherence and
        consistency averages: those weeks are UNKNOWN, not 0%, and averaging a
        manufactured zero in grades a user who logged nothing (holiday, illness,
        a break from tracking) as having failed their targets. They ARE still
        counted in ``logging_score``, whose denominator is the whole window —
        "you logged 6 of the last 28 days" is an observed fact about coverage.
        """
        weeks_in_window = len(weekly_summaries)
        weeks_with_data = [w for w in weekly_summaries if w.has_data]

        if not weeks_with_data:
            logger.info(
                "calculate_sustainability_score: %d week(s) supplied, none with "
                "logged days — sustainability is unknown, returning None",
                weeks_in_window,
            )
            return None

        # Calculate average adherence across the weeks that HAVE data
        avg_adherence = (
            sum(w.avg_overall_adherence for w in weeks_with_data) / len(weeks_with_data)
        )

        # Calculate consistency score (lower variance = higher score).
        # Only weeks with >1 logged day have a measurable variance; a week with
        # exactly one logged day contributes nothing rather than a fake 0.
        measurable = [w for w in weeks_with_data if w.adherence_variance is not None]
        if measurable:
            avg_variance = sum(w.adherence_variance for w in measurable) / len(measurable)
            # Normalize variance: 0 variance = 1.0, 50+ variance = 0
            consistency_score = max(0, 1 - avg_variance / 50)
        else:
            # Nothing to measure spread over. Rather than inventing a number,
            # fall back to the adherence level itself so the composite score
            # neither rewards nor punishes the missing signal.
            consistency_score = avg_adherence / 100

        # Calculate logging consistency score over the FULL window (empty weeks
        # included — a week with zero logged days really is zero coverage).
        total_logged = sum(w.days_logged for w in weekly_summaries)
        total_possible = sum(w.days_in_week for w in weekly_summaries)
        logging_score = total_logged / total_possible if total_possible > 0 else 0

        # Combined sustainability score (weighted)
        # Adherence matters most, then consistency, then logging frequency
        adherence_normalized = avg_adherence / 100
        score = (
            adherence_normalized * 0.60 +
            consistency_score * 0.25 +
            logging_score * 0.15
        )

        # Determine rating
        if score >= self.SUSTAINABILITY_HIGH_THRESHOLD:
            rating = SustainabilityRating.HIGH
        elif score >= self.SUSTAINABILITY_MEDIUM_THRESHOLD:
            rating = SustainabilityRating.MEDIUM
        else:
            rating = SustainabilityRating.LOW

        # Generate recommendation
        recommendation = self._get_sustainability_recommendation(
            score, avg_adherence, consistency_score, logging_score
        )

        return SustainabilityScore(
            score=score,
            rating=rating,
            avg_adherence=avg_adherence,
            consistency_score=consistency_score,
            logging_score=logging_score,
            recommendation=recommendation,
            weeks_with_data=len(weeks_with_data),
            weeks_in_window=weeks_in_window,
        )

    def _get_sustainability_recommendation(
        self,
        score: float,
        adherence: float,
        consistency: float,
        logging: float
    ) -> str:
        """Generate recommendation based on sustainability factors."""
        if score >= 0.8:
            return "Excellent sustainability! Your current targets are working well for you."

        if score >= 0.7:
            return "Good sustainability. Keep up the consistent tracking."

        issues = []

        if adherence < 70:
            issues.append("Your targets may be too aggressive. Consider a smaller caloric deficit.")

        if consistency < 0.6:
            issues.append("Your intake varies a lot day-to-day. Try meal prepping for more consistency.")

        if logging < 0.7:
            issues.append("Log meals more consistently for better adherence tracking.")

        if not issues:
            return "Room for improvement. Focus on hitting your targets more consistently."

        return " ".join(issues)

    def get_adherence_recommendation(
        self,
        sustainability: Optional[SustainabilityScore],
        current_goal: str
    ) -> str:
        """
        Get specific recommendation based on adherence patterns.

        ``sustainability`` is Optional because
        :meth:`calculate_sustainability_score` returns ``None`` when there is no
        logged data to assess. In that case we say so instead of picking one of
        the graded messages (all of which assert something about how the user
        has been doing).
        """
        if sustainability is None:
            return (
                "Not enough logged data yet to assess how sustainable your "
                "targets are. Log meals for a couple of weeks and this will fill in."
            )

        if sustainability.rating == SustainabilityRating.HIGH:
            if current_goal == "lose_fat":
                return "Your adherence is excellent. You can maintain this pace or slightly increase your deficit if desired."
            elif current_goal == "build_muscle":
                return "Great adherence! Keep hitting your protein targets for optimal muscle growth."
            else:
                return "You're doing great at maintenance. Keep up the consistent tracking."

        elif sustainability.rating == SustainabilityRating.MEDIUM:
            if sustainability.avg_adherence < 60:
                return "Your targets might be too aggressive. Consider a smaller deficit for better adherence."
            else:
                return "Focus on consistency. Try to hit similar macros each day rather than large variations."

        else:  # LOW
            return "Consider adjusting your targets to be more achievable. Sustainable progress beats aggressive unsustainable dieting."


# Singleton instance
adherence_tracking_service = AdherenceTrackingService()


def get_adherence_tracking_service() -> AdherenceTrackingService:
    """Get the adherence tracking service instance."""
    return adherence_tracking_service
