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
from datetime import date, datetime, timedelta, timezone
from core.timezone_utils import get_user_today
import logging

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Gamification constants (B6 — Strength-Score gamification, out-punch Gravl)
# ---------------------------------------------------------------------------
# A score is "stale" once its underlying logged data is older than this. The
# HOME nudge ("Your <muscle> score is going stale — train it to refresh it")
# and the score-freshness RAG bias (B7) both key off this single threshold so
# the product never drifts between surfaces.
SCORE_STALE_DAYS = 10

# Per-muscle strength-level thresholds (0-100). MUST match
# StrengthCalculatorService.classify_strength_level's score banding so a
# level-up celebration fires exactly when the muscle's level label changes.
# Ordered ascending; the *next* threshold above the current score is the
# milestone an in-workout target pill nudges the user toward.
MUSCLE_LEVEL_THRESHOLDS: List[tuple] = [
    ("beginner", 0),
    ("novice", 25),
    ("intermediate", 50),
    ("advanced", 70),
    ("elite", 90),
]

# Per-muscle DEFAULT strength standard (a key into STRENGTH_STANDARDS) used to
# anchor a level-up target when the user has NO qualifying best lift on the
# muscle yet AND the current exercise doesn't resolve to a known standard.
# This replaces the old blanket squat fallback, which produced an identical
# (and often absurd: 1.25× bodyweight) target on every muscle — including
# isolation/bodyweight moves. Pick a movement representative of the muscle so
# the ratio is muscle-appropriate. Keys are normalized muscle tokens; lookup is
# substring-tolerant (see _resolve_muscle_default_key).
_MUSCLE_DEFAULT_STANDARD: Dict[str, str] = {
    "chest": "bench_press",
    "pec": "bench_press",
    "back": "lat_pulldown",
    "lat": "lat_pulldown",
    "trap": "barbell_row",
    "rhomboid": "barbell_row",
    "shoulder": "overhead_press",
    "delt": "overhead_press",
    "tricep": "tricep_extension",
    "bicep": "bicep_curl",
    "forearm": "bicep_curl",
    "quad": "squat",
    "hamstring": "leg_curl",
    "glute": "hip_thrust",
    "calf": "calf_raise",
    "calves": "calf_raise",
}

# Rep goal per next-level band for BODYWEIGHT / unloadable exercises, where a
# weight target is meaningless. The pill nudges "Hit N+ clean reps" instead.
_REP_GOAL_BY_NEXT_LEVEL: Dict[str, int] = {
    "novice": 12,
    "intermediate": 15,
    "advanced": 20,
    "elite": 25,
}


def _is_bodyweight_equipment(equipment: str) -> bool:
    """True when the equipment string denotes an unloadable bodyweight move."""
    e = (equipment or "").strip().lower()
    return e in ("", "bodyweight", "body weight", "none", "body_weight")


def _resolve_muscle_default_key(muscle_group: str) -> str:
    """Map a muscle string (e.g. "Shoulders (deltoids)") to a representative
    STRENGTH_STANDARDS key via substring match. Falls back to "bicep_curl"
    (small, conservative ratios) rather than squat for an unrecognized muscle.
    """
    m = (muscle_group or "").strip().lower()
    for token, key in _MUSCLE_DEFAULT_STANDARD.items():
        if token in m:
            return key
    return "bicep_curl"


# Overall-fitness level thresholds (mirror LEVEL_THRESHOLDS below but as an
# ordered ascending list for level-up crossing detection).
OVERALL_LEVEL_THRESHOLDS: List[tuple] = [
    ("beginner", 0),
    ("developing", 25),
    ("fit", 45),
    ("athletic", 65),
    ("elite", 85),
]


def _level_for_score(score: int, thresholds: List[tuple]) -> tuple:
    """Return (level_name, level_index, floor, next_floor_or_None) for a score.

    Deterministic — no LLM. Used for level-up crossing detection and for the
    "points to next level" target pills shown in-workout.
    """
    level_name = thresholds[0][0]
    level_index = 0
    floor = thresholds[0][1]
    next_floor: Optional[int] = None
    for i, (name, t) in enumerate(thresholds):
        if score >= t:
            level_name = name
            level_index = i
            floor = t
            next_floor = thresholds[i + 1][1] if i + 1 < len(thresholds) else None
        else:
            break
    return level_name, level_index, floor, next_floor


def muscle_level_for_score(score: int) -> str:
    """Public helper: muscle strength-level label for a 0-100 score."""
    return _level_for_score(score, MUSCLE_LEVEL_THRESHOLDS)[0]


def overall_level_for_score(score: int) -> str:
    """Public helper: overall fitness-level label for a 0-100 score."""
    return _level_for_score(score, OVERALL_LEVEL_THRESHOLDS)[0]


def detect_level_up(
    previous_score: Optional[int],
    new_score: int,
    *,
    thresholds: List[tuple] = MUSCLE_LEVEL_THRESHOLDS,
) -> Optional[Dict[str, Any]]:
    """Detect whether a score crossed UP into a new level band.

    Returns a celebration payload (or None if no upward crossing). Deterministic.

    Args:
        previous_score: Prior score (None → treat as a fresh 0 baseline only if
                        new_score is itself non-zero; a brand-new muscle hitting
                        its first non-beginner band counts as a level-up).
        new_score: Current score.
        thresholds: Ordered ascending level thresholds.
    """
    if new_score is None:
        return None
    prev = previous_score if previous_score is not None else 0
    if new_score <= prev:
        return None
    prev_level, prev_idx, _, _ = _level_for_score(prev, thresholds)
    new_level, new_idx, new_floor, new_next = _level_for_score(new_score, thresholds)
    if new_idx <= prev_idx:
        return None
    return {
        "leveled_up": True,
        "previous_level": prev_level,
        "previous_level_index": prev_idx,
        "new_level": new_level,
        "new_level_index": new_idx,
        "previous_score": prev,
        "new_score": new_score,
        "level_floor": new_floor,
        "next_level_floor": new_next,
        "levels_gained": new_idx - prev_idx,
    }


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
        timezone_str: str,
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
            calculated_date=date.fromisoformat(get_user_today(timezone_str)),
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

    # -------------------------------------------------------------------------
    # B6 — In-workout score-target pills + stale-score detection
    # -------------------------------------------------------------------------

    def compute_exercise_score_target(
        self,
        *,
        muscle_group: str,
        current_score: int,
        bodyweight_kg: float,
        gender: str,
        best_exercise_name: str,
        best_estimated_1rm_kg: float,
        target_reps: int = 8,
        exercise_name: str = "",
        equipment: str = "",
    ) -> Optional[Dict[str, Any]]:
        """Deterministically compute the target that would raise a muscle's
        strength score into its NEXT level band.

        Shown as an in-workout pill ("Hit 80kg×8 to level up Chest"). No LLM —
        inverts StrengthCalculatorService.classify_strength_level's bodyweight-ratio
        banding, then converts the required 1RM back to a working weight at the
        given rep target via the Brzycki relationship.

        Exercise/equipment aware:
          - The bodyweight-ratio standard is resolved from the CURRENT exercise
            first, then the user's best lift, then a MUSCLE-APPROPRIATE default
            (never a blanket squat — that produced an identical absurd target on
            every muscle for users with no qualifying lift yet).
          - For BODYWEIGHT / unloadable exercises a rep-based target is returned
            (``target_kind="reps"``, ``target_working_weight_kg=None``) instead of
            a nonsensical loaded number.

        Returns None when the muscle is already at the top band (elite) or when
        bodyweight is unknown (can't anchor the ratio).
        """
        # Lazy import to avoid a circular import at module load.
        from services.strength_calculator_service import (
            STRENGTH_STANDARDS,
            StrengthCalculatorService,
        )

        if bodyweight_kg <= 0:
            return None

        _, _, _, next_floor = _level_for_score(current_score, MUSCLE_LEVEL_THRESHOLDS)
        if next_floor is None:
            # Already elite — nothing higher to target.
            return None

        next_level = _level_for_score(next_floor, MUSCLE_LEVEL_THRESHOLDS)[0]

        # --- Bodyweight / unloadable: rep-based target (no load makes sense) ---
        if _is_bodyweight_equipment(equipment):
            rep_goal = _REP_GOAL_BY_NEXT_LEVEL.get(next_level, 15)
            # Don't nudge below what the plan already prescribes.
            rep_goal = max(rep_goal, int(target_reps or 0))
            return {
                "muscle_group": muscle_group,
                "current_score": current_score,
                "next_level": next_level,
                "next_level_score_floor": next_floor,
                "points_to_next_level": max(0, next_floor - current_score),
                "best_exercise_name": best_exercise_name or "",
                "current_best_1rm_kg": round(best_estimated_1rm_kg or 0, 1),
                "target_1rm_kg": None,
                "target_reps": rep_goal,
                "target_working_weight_kg": None,
                "delta_1rm_kg": None,
                "target_kind": "reps",
                "target_label": f"{rep_goal}+ clean reps",
            }

        # --- Loaded: resolve a muscle-appropriate ratio standard ---
        standards = self._resolve_strength_standard(
            STRENGTH_STANDARDS,
            StrengthCalculatorService,
            exercise_name=exercise_name,
            best_exercise_name=best_exercise_name,
            muscle_group=muscle_group,
        )
        if (gender or "male").lower() == "female":
            standards = {k: v * 0.65 for k, v in standards.items()}

        # Map the next level band → the ratio at its floor.
        band_ratio = {
            "novice": standards["novice"],
            "intermediate": standards["intermediate"],
            "advanced": standards["advanced"],
            "elite": standards["elite"],
        }.get(next_level)
        if band_ratio is None:
            return None

        required_1rm_kg = round(band_ratio * bodyweight_kg, 1)

        # Convert required 1RM → working weight at target_reps (invert Brzycki:
        # weight = 1RM × (37 - reps) / 36).
        reps = max(1, min(12, int(target_reps or 8)))
        required_working_weight_kg = round(
            required_1rm_kg * (37 - reps) / 36, 1
        )

        delta_1rm = round(max(0.0, required_1rm_kg - (best_estimated_1rm_kg or 0)), 1)

        return {
            "muscle_group": muscle_group,
            "current_score": current_score,
            "next_level": next_level,
            "next_level_score_floor": next_floor,
            "points_to_next_level": max(0, next_floor - current_score),
            "best_exercise_name": best_exercise_name or "",
            "current_best_1rm_kg": round(best_estimated_1rm_kg or 0, 1),
            "target_1rm_kg": required_1rm_kg,
            "target_reps": reps,
            "target_working_weight_kg": required_working_weight_kg,
            "delta_1rm_kg": delta_1rm,
            "target_kind": "load",
            # Human-readable, unit-agnostic label; the Flutter side localizes
            # kg→lb using the user's workout-weight unit setting.
            "target_label": f"{required_working_weight_kg:g} kg × {reps}",
        }

    @staticmethod
    def _resolve_strength_standard(
        strength_standards: Dict[str, Dict[str, float]],
        calculator_cls,
        *,
        exercise_name: str,
        best_exercise_name: str,
        muscle_group: str,
    ) -> Dict[str, float]:
        """Pick the bodyweight-ratio standard band for a level-up target.

        Resolution order (most specific → most general), NEVER blanket squat:
          1. The CURRENT exercise (exact, then substring against standard keys).
          2. The user's best lift on this muscle (same matching).
          3. A muscle-appropriate default (``_MUSCLE_DEFAULT_STANDARD``).
          4. A conservative isolation default (bicep_curl) — small ratios so an
             unknown movement never demands a 1.25×-bodyweight squat-equivalent.
        """
        def _match(name: str) -> Optional[Dict[str, float]]:
            if not name:
                return None
            norm = calculator_cls._normalize_exercise_name(name)
            if norm in strength_standards:
                return strength_standards[norm]
            # Substring tolerance: "cable_upper_chest_crossover" → "bench_press"
            # won't match, but "close_grip_bench_press" → "bench_press" will.
            for key, band in strength_standards.items():
                if key in norm or norm in key:
                    return band
            return None

        return (
            _match(exercise_name)
            or _match(best_exercise_name)
            or strength_standards.get(
                _resolve_muscle_default_key(muscle_group), {}
            )
            or strength_standards["bicep_curl"]
        )

    @staticmethod
    def is_score_stale(calculated_at: Optional[Any], now: Optional[datetime] = None) -> bool:
        """True when a strength_scores row's data is older than SCORE_STALE_DAYS.

        Accepts an ISO string or datetime. Naive/aware safe.
        """
        if not calculated_at:
            return True
        dt: Optional[datetime] = None
        if isinstance(calculated_at, datetime):
            dt = calculated_at
        elif isinstance(calculated_at, str):
            try:
                dt = datetime.fromisoformat(calculated_at.replace("Z", "+00:00"))
            except ValueError:
                return True
        if dt is None:
            return True
        ref = now or datetime.now(timezone.utc)
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        if ref.tzinfo is None:
            ref = ref.replace(tzinfo=timezone.utc)
        return (ref - dt).days >= SCORE_STALE_DAYS

    @classmethod
    def detect_stale_muscles(
        cls,
        strength_score_rows: List[Dict[str, Any]],
        *,
        now: Optional[datetime] = None,
        excluded_muscles: Optional[List[str]] = None,
    ) -> List[Dict[str, Any]]:
        """Given strength_scores rows (latest per muscle), return the muscles
        whose data is stale (>SCORE_STALE_DAYS old).

        Excluded muscles (preferences.excluded_muscles) are never reported as
        stale — the user opted out of training them, so nudging is noise.

        Each entry: {muscle_group, last_trained_at, days_stale, strength_score}.
        Sorted most-stale first.
        """
        ref = now or datetime.now(timezone.utc)
        excluded = {(m or "").strip().lower() for m in (excluded_muscles or [])}
        out: List[Dict[str, Any]] = []
        seen: set = set()
        for row in strength_score_rows or []:
            mg = (row.get("muscle_group") or "").strip().lower()
            if not mg or mg in seen:
                continue
            seen.add(mg)
            if mg in excluded:
                continue
            calc = row.get("calculated_at")
            if not cls.is_score_stale(calc, ref):
                continue
            days_stale = SCORE_STALE_DAYS
            if calc:
                try:
                    dt = (
                        calc if isinstance(calc, datetime)
                        else datetime.fromisoformat(str(calc).replace("Z", "+00:00"))
                    )
                    if dt.tzinfo is None:
                        dt = dt.replace(tzinfo=timezone.utc)
                    days_stale = (ref - dt).days
                except (ValueError, TypeError):
                    days_stale = 999
            else:
                days_stale = 999
            out.append({
                "muscle_group": mg,
                "last_trained_at": str(calc) if calc else None,
                "days_stale": days_stale,
                "strength_score": int(row.get("strength_score") or 0),
            })
        out.sort(key=lambda e: e["days_stale"], reverse=True)
        return out

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
