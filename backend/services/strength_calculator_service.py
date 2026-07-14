"""
Strength Calculator Service - 1RM estimation, strength level classification, and muscle group scoring.

Handles:
- 1RM estimation using multiple formulas (Brzycki, Epley, Lombardi)
- Strength level classification (Beginner → Elite) based on bodyweight ratios
- Per-muscle-group strength scoring (0-100)
- Trend analysis and progress tracking
"""
from typing import Any, Dict, List, Optional, Tuple
from datetime import datetime, date, timedelta
from decimal import Decimal
from dataclasses import dataclass
from enum import Enum
import logging

from services.strength_movement_patterns import standards_for as _pattern_standards_for

logger = logging.getLogger(__name__)


# FEATURE 4: per-muscle weekly-volume landmarks (MEV / MAV / MRV) in working sets/week.
# Ported from the Flutter info-sheet table `volumeGuidelinesTable` in
# mobile/flutter/lib/data/models/muscle_status.dart — KEEP IN SYNC with that table.
# Used by the composite score's volume-tolerance sub-score (S2). MAV is stored as the
# midpoint of the client's mavRange string so the backend has a single number to curve
# against. Sources: Israetel/Renaissance Periodization volume-landmark research.
VOLUME_LANDMARKS: Dict[str, Dict[str, float]] = {
    "chest":      {"mev": 10, "mav": 16, "mrv": 22},   # client mavRange "12-20"
    "back":       {"mev": 10, "mav": 18, "mrv": 25},   # "14-22"
    "shoulders":  {"mev": 8,  "mav": 19, "mrv": 26},   # "16-22"
    "quads":      {"mev": 8,  "mav": 15, "mrv": 20},   # "12-18"
    "hamstrings": {"mev": 6,  "mav": 13, "mrv": 20},   # "10-16"
    "biceps":     {"mev": 8,  "mav": 17, "mrv": 26},   # "14-20"
    "triceps":    {"mev": 6,  "mav": 12, "mrv": 18},   # "10-14"
    "calves":     {"mev": 8,  "mav": 14, "mrv": 20},   # "12-16"
    "glutes":     {"mev": 4,  "mav": 10, "mrv": 16},   # "8-12"
    "core":       {"mev": 4,  "mav": 12, "mrv": 20},   # Abs "8-16"
    "traps":      {"mev": 6,  "mav": 16, "mrv": 26},   # "12-20"
    "forearms":   {"mev": 6,  "mav": 12, "mrv": 18},   # not in client table; conservative
    # 2026-06 additions (16-group expansion). Conservative landmarks; KEEP IN SYNC
    # with the Flutter volumeGuidelinesTable in muscle_status.dart.
    "rear_delts": {"mev": 6,  "mav": 12, "mrv": 20},   # small, high-frequency tolerant
    "obliques":   {"mev": 4,  "mav": 10, "mrv": 16},   # like core, slightly lower
    "adductors":  {"mev": 4,  "mav": 10, "mrv": 16},   # accessory of lower compounds
    "lower_back": {"mev": 4,  "mav": 9,  "mrv": 14},   # high systemic fatigue → low MRV
}
# Fallback when a muscle group isn't in the table (e.g. "lower_back").
_DEFAULT_LANDMARK = {"mev": 6, "mav": 12, "mrv": 18}


class StrengthLevel(str, Enum):
    """Strength level classifications based on industry standards."""
    BEGINNER = "beginner"
    NOVICE = "novice"
    INTERMEDIATE = "intermediate"
    ADVANCED = "advanced"
    ELITE = "elite"


class MuscleGroup(str, Enum):
    """Supported muscle groups for scoring.

    Expanded 2026-06 from 12 → 16: added REAR_DELTS, OBLIQUES, ADDUCTORS, LOWER_BACK
    so the score (and the radar) reflect finer training breadth. These four degrade
    gracefully — they read ``is_establishing`` until a user has enough signal and
    never blank (the empty-state hint covers them).
    """
    CHEST = "chest"
    BACK = "back"
    SHOULDERS = "shoulders"
    REAR_DELTS = "rear_delts"
    BICEPS = "biceps"
    TRICEPS = "triceps"
    FOREARMS = "forearms"
    QUADS = "quads"
    HAMSTRINGS = "hamstrings"
    GLUTES = "glutes"
    ADDUCTORS = "adductors"
    CALVES = "calves"
    CORE = "core"
    OBLIQUES = "obliques"
    LOWER_BACK = "lower_back"
    TRAPS = "traps"


# Bodyweight ratio standards for key exercises
# Source: Symmetric Strength, Strength Level, ExRx standards
# Format: {exercise_name: {level: bodyweight_ratio}}
STRENGTH_STANDARDS = {
    # Compound Lower Body
    "squat": {
        "beginner": 0.75,
        "novice": 1.25,
        "intermediate": 1.50,
        "advanced": 2.00,
        "elite": 2.50,
    },
    "back_squat": {
        "beginner": 0.75,
        "novice": 1.25,
        "intermediate": 1.50,
        "advanced": 2.00,
        "elite": 2.50,
    },
    "front_squat": {
        "beginner": 0.60,
        "novice": 1.00,
        "intermediate": 1.25,
        "advanced": 1.65,
        "elite": 2.00,
    },
    "deadlift": {
        "beginner": 1.00,
        "novice": 1.50,
        "intermediate": 2.00,
        "advanced": 2.50,
        "elite": 3.00,
    },
    "romanian_deadlift": {
        "beginner": 0.75,
        "novice": 1.10,
        "intermediate": 1.40,
        "advanced": 1.80,
        "elite": 2.20,
    },
    "leg_press": {
        "beginner": 1.50,
        "novice": 2.25,
        "intermediate": 3.00,
        "advanced": 4.00,
        "elite": 5.00,
    },
    "lunge": {
        "beginner": 0.25,
        "novice": 0.50,
        "intermediate": 0.75,
        "advanced": 1.00,
        "elite": 1.25,
    },
    "bulgarian_split_squat": {
        "beginner": 0.25,
        "novice": 0.50,
        "intermediate": 0.75,
        "advanced": 1.00,
        "elite": 1.25,
    },

    # Compound Upper Body - Push
    "bench_press": {
        "beginner": 0.50,
        "novice": 1.00,
        "intermediate": 1.25,
        "advanced": 1.50,
        "elite": 2.00,
    },
    "incline_bench_press": {
        "beginner": 0.40,
        "novice": 0.80,
        "intermediate": 1.05,
        "advanced": 1.30,
        "elite": 1.70,
    },
    "overhead_press": {
        "beginner": 0.35,
        "novice": 0.55,
        "intermediate": 0.75,
        "advanced": 1.00,
        "elite": 1.25,
    },
    "dumbbell_shoulder_press": {
        "beginner": 0.20,
        "novice": 0.35,
        "intermediate": 0.50,
        "advanced": 0.65,
        "elite": 0.85,
    },
    "dips": {
        "beginner": 0.00,  # Bodyweight
        "novice": 0.10,
        "intermediate": 0.30,
        "advanced": 0.50,
        "elite": 0.75,
    },

    # Compound Upper Body - Pull
    "barbell_row": {
        "beginner": 0.50,
        "novice": 0.75,
        "intermediate": 1.00,
        "advanced": 1.25,
        "elite": 1.50,
    },
    "pull_up": {
        "beginner": 0.00,
        "novice": 0.10,
        "intermediate": 0.25,
        "advanced": 0.50,
        "elite": 0.75,
    },
    "chin_up": {
        "beginner": 0.00,
        "novice": 0.15,
        "intermediate": 0.30,
        "advanced": 0.55,
        "elite": 0.80,
    },
    "lat_pulldown": {
        "beginner": 0.50,
        "novice": 0.75,
        "intermediate": 1.00,
        "advanced": 1.25,
        "elite": 1.50,
    },

    # Isolation - Arms
    "bicep_curl": {
        "beginner": 0.15,
        "novice": 0.25,
        "intermediate": 0.40,
        "advanced": 0.55,
        "elite": 0.70,
    },
    "tricep_extension": {
        "beginner": 0.15,
        "novice": 0.25,
        "intermediate": 0.35,
        "advanced": 0.50,
        "elite": 0.65,
    },
    "hammer_curl": {
        "beginner": 0.15,
        "novice": 0.25,
        "intermediate": 0.40,
        "advanced": 0.55,
        "elite": 0.70,
    },

    # Isolation - Legs
    "leg_curl": {
        "beginner": 0.30,
        "novice": 0.50,
        "intermediate": 0.70,
        "advanced": 0.90,
        "elite": 1.15,
    },
    "leg_extension": {
        "beginner": 0.40,
        "novice": 0.65,
        "intermediate": 0.90,
        "advanced": 1.15,
        "elite": 1.45,
    },
    "calf_raise": {
        "beginner": 0.75,
        "novice": 1.25,
        "intermediate": 1.75,
        "advanced": 2.25,
        "elite": 3.00,
    },
    "hip_thrust": {
        "beginner": 0.75,
        "novice": 1.25,
        "intermediate": 1.75,
        "advanced": 2.25,
        "elite": 3.00,
    },
}

# Mapping exercises to muscle groups
EXERCISE_MUSCLE_GROUPS: Dict[str, List[str]] = {
    # Quads-focused
    "squat": ["quads", "glutes"],
    "back_squat": ["quads", "glutes"],
    "front_squat": ["quads", "core"],
    "leg_press": ["quads", "glutes"],
    "leg_extension": ["quads"],
    "lunge": ["quads", "glutes"],
    "bulgarian_split_squat": ["quads", "glutes"],

    # Hamstrings/Glutes
    "deadlift": ["hamstrings", "glutes", "back"],
    "romanian_deadlift": ["hamstrings", "glutes"],
    "leg_curl": ["hamstrings"],
    "hip_thrust": ["glutes", "hamstrings"],

    # Chest
    "bench_press": ["chest", "triceps", "shoulders"],
    "incline_bench_press": ["chest", "shoulders", "triceps"],
    "dumbbell_bench_press": ["chest", "triceps"],
    "dips": ["chest", "triceps", "shoulders"],

    # Back
    "barbell_row": ["back", "biceps"],
    "pull_up": ["back", "biceps"],
    "chin_up": ["back", "biceps"],
    "lat_pulldown": ["back", "biceps"],

    # Shoulders
    "overhead_press": ["shoulders", "triceps"],
    "dumbbell_shoulder_press": ["shoulders", "triceps"],
    "lateral_raise": ["shoulders"],

    # Arms
    "bicep_curl": ["biceps"],
    "hammer_curl": ["biceps", "forearms"],
    "tricep_extension": ["triceps"],
    "skull_crusher": ["triceps"],

    # Shoulders — rear delt isolations (2026-06 expansion)
    "reverse_fly": ["rear_delts"],
    "rear_delt_fly": ["rear_delts"],
    "face_pull": ["rear_delts", "traps"],
    "bent_over_lateral_raise": ["rear_delts"],

    # Adductors / inner thigh (2026-06 expansion)
    "hip_adduction": ["adductors"],
    "adductor_machine": ["adductors"],
    "copenhagen_plank": ["adductors", "core"],
    "sumo_deadlift": ["hamstrings", "glutes", "adductors", "back"],

    # Lower back / posterior chain (2026-06 expansion)
    "back_extension": ["lower_back"],
    "hyperextension": ["lower_back"],
    "good_morning": ["lower_back", "hamstrings", "glutes"],

    # Obliques (2026-06 expansion)
    "russian_twist": ["obliques", "core"],
    "side_plank": ["obliques", "core"],
    "woodchopper": ["obliques", "core"],
    "side_bend": ["obliques"],

    # Other
    "calf_raise": ["calves"],
    "plank": ["core"],
    "crunch": ["core"],
    "shrug": ["traps"],
}


@dataclass
class OneRepMax:
    """Estimated 1RM with formula information."""
    weight_kg: float
    reps: int
    estimated_1rm: float
    formula_used: str
    confidence: float  # 0-1, higher for lower reps


@dataclass
class StrengthScore:
    """Complete strength score for a muscle group."""
    muscle_group: str
    strength_score: int  # 0-100
    strength_level: StrengthLevel
    best_exercise_name: str
    best_estimated_1rm_kg: float
    bodyweight_ratio: float
    weekly_sets: int
    weekly_volume_kg: float
    trend: str  # 'improving', 'maintaining', 'declining'
    previous_score: Optional[int]
    score_change: Optional[int]
    # FEATURE 4 (composite score) additive fields. Default so every existing
    # constructor call (legacy single-factor path) keeps working unchanged.
    is_establishing: bool = False
    score_range_low: Optional[int] = None
    score_range_high: Optional[int] = None
    composite_breakdown: Optional[Dict[str, Any]] = None
    # 2026-06 — population percentile ("stronger than X% of comparable lifters"),
    # null when the muscle's best lift has no real population standard or is
    # machine-derived (brands vary too much for an honest cross-user claim).
    population_percentile: Optional[float] = None
    best_is_machine: bool = False


# Brzycki (1RM = W × 36 / (37 - R)) has a pole at R = 37: it divides by zero at
# exactly 37 reps and returns a NEGATIVE 1RM for 38+. High-rep sets are routine in
# this product (bodyweight push-ups / sit-ups / air squats are fed straight through
# calculate_1rm_average by personal_records_service.check_for_rep_pr), so the raw
# formula must never see a rep count past its supported range. calculate_1rm's own
# contract documents reps as 1-30, so we clamp the Brzycki term to that bound.
# Epley and Lombardi stay monotonic and positive at any rep count and are NOT clamped.
_BRZYCKI_MAX_REPS = 30


def _brzycki_1rm(weight_kg: float, reps: int) -> float:
    """Brzycki estimate, clamped to the formula's supported rep range (see above)."""
    safe_reps = min(max(reps, 1), _BRZYCKI_MAX_REPS)
    return weight_kg * (36 / (37 - safe_reps))


class StrengthCalculatorService:
    """
    Calculates strength metrics, 1RM estimates, and strength scores.

    Uses evidence-based formulas and industry-standard strength benchmarks.
    """

    # -------------------------------------------------------------------------
    # 1RM Estimation
    # -------------------------------------------------------------------------

    @staticmethod
    def calculate_1rm(weight_kg: float, reps: int, formula: str = "brzycki") -> OneRepMax:
        """
        Calculate estimated 1RM using specified formula.

        Args:
            weight_kg: Weight lifted
            reps: Number of repetitions (1-30)
            formula: 'brzycki', 'epley', or 'lombardi'

        Returns:
            OneRepMax with estimated value and confidence
        """
        if reps <= 0:
            return OneRepMax(
                weight_kg=weight_kg,
                reps=reps,
                estimated_1rm=weight_kg,
                formula_used=formula,
                confidence=0.0,
            )

        if reps == 1:
            return OneRepMax(
                weight_kg=weight_kg,
                reps=1,
                estimated_1rm=weight_kg,
                formula_used="actual",
                confidence=1.0,
            )

        # Calculate based on formula
        if formula == "brzycki":
            # Brzycki: 1RM = W × (36 / (37 - R))
            # Most accurate for 1-10 reps; clamped past 30 reps (pole at 37).
            estimated = _brzycki_1rm(weight_kg, reps)
        elif formula == "epley":
            # Epley: 1RM = W × (1 + R/30)
            # Good for moderate rep ranges
            estimated = weight_kg * (1 + reps / 30)
        elif formula == "lombardi":
            # Lombardi: 1RM = W × R^0.1
            # Conservative estimate
            estimated = weight_kg * (reps ** 0.1)
        else:
            # Default to Brzycki
            estimated = _brzycki_1rm(weight_kg, reps)

        # Confidence decreases with higher reps
        # 1-5 reps: high confidence (0.95-0.85)
        # 6-10 reps: moderate confidence (0.85-0.70)
        # 11+ reps: lower confidence (0.70-0.50)
        if reps <= 5:
            confidence = 0.95 - (reps - 1) * 0.025
        elif reps <= 10:
            confidence = 0.85 - (reps - 5) * 0.03
        else:
            confidence = max(0.50, 0.70 - (reps - 10) * 0.02)

        return OneRepMax(
            weight_kg=weight_kg,
            reps=reps,
            estimated_1rm=round(estimated, 2),
            formula_used=formula,
            confidence=round(confidence, 2),
        )

    @staticmethod
    def calculate_1rm_average(weight_kg: float, reps: int) -> float:
        """
        Calculate 1RM using average of multiple formulas for best accuracy.

        Args:
            weight_kg: Weight lifted
            reps: Number of repetitions

        Returns:
            Averaged 1RM estimate
        """
        if reps <= 1:
            return weight_kg

        brzycki = _brzycki_1rm(weight_kg, reps)
        epley = weight_kg * (1 + reps / 30)
        lombardi = weight_kg * (reps ** 0.1)

        return round((brzycki + epley + lombardi) / 3, 2)

    # -------------------------------------------------------------------------
    # Strength Level Classification
    # -------------------------------------------------------------------------

    def _resolve_standards(
        self,
        exercise_name: str,
        equipment: Optional[str] = None,
    ) -> Dict[str, float]:
        """Resolve the beginner..elite bodyweight-ratio ladder for an exercise.

        FEATURE 4 — fixes the old "fall back to SQUAT" bug (which over-scaled every
        unmapped isolation move to ~0). Lookup order:
            1. exact STRENGTH_STANDARDS entry (hand-curated, most accurate)
            2. strength_movement_patterns.standards_for (movement-pattern ladder)
            3. isolation_upper ladder (conservative default — NEVER squat)
        """
        normalized_name = self._normalize_exercise_name(exercise_name)
        standards = STRENGTH_STANDARDS.get(normalized_name)
        if standards:
            return standards
        # Tier 2 + tier 3 both live in strength_movement_patterns: standards_for
        # returns the pattern ladder, and an unclassifiable name resolves to its
        # isolation_upper default there (never squat).
        return _pattern_standards_for(exercise_name, equipment)

    def classify_strength_level(
        self,
        exercise_name: str,
        estimated_1rm: float,
        bodyweight_kg: float,
        gender: str = "male",
        equipment: Optional[str] = None,
    ) -> Tuple[StrengthLevel, float, int]:
        """
        Classify strength level based on bodyweight ratio.

        Args:
            exercise_name: Name of the exercise (normalized)
            estimated_1rm: Estimated 1RM in kg
            bodyweight_kg: User's bodyweight in kg
            gender: 'male' or 'female' (affects thresholds)
            equipment: Optional equipment string — threaded into the movement-pattern
                standards resolver so machine/cable moves classify against a sensible
                ladder instead of the old squat fallback.

        Returns:
            Tuple of (level, bodyweight_ratio, score_0_100)
        """
        # Get standards for this exercise via the pattern-aware resolver (NEVER the
        # bare squat fallback the old code used).
        standards = self._resolve_standards(exercise_name, equipment)

        # Calculate bodyweight ratio
        ratio = estimated_1rm / bodyweight_kg if bodyweight_kg > 0 else 0

        # Adjust standards for gender (women typically ~60-70% of male standards)
        if gender == "female":
            standards = {k: v * 0.65 for k, v in standards.items()}

        # Determine level based on ratio
        if ratio >= standards["elite"]:
            level = StrengthLevel.ELITE
            # Score 90-100 for elite
            score = 90 + min(10, int((ratio - standards["elite"]) / standards["elite"] * 20))
        elif ratio >= standards["advanced"]:
            level = StrengthLevel.ADVANCED
            # Score 70-89 for advanced
            progress = (ratio - standards["advanced"]) / (standards["elite"] - standards["advanced"])
            score = 70 + int(progress * 19)
        elif ratio >= standards["intermediate"]:
            level = StrengthLevel.INTERMEDIATE
            # Score 50-69 for intermediate
            progress = (ratio - standards["intermediate"]) / (standards["advanced"] - standards["intermediate"])
            score = 50 + int(progress * 19)
        elif ratio >= standards["novice"]:
            level = StrengthLevel.NOVICE
            # Score 25-49 for novice
            progress = (ratio - standards["novice"]) / (standards["intermediate"] - standards["novice"])
            score = 25 + int(progress * 24)
        else:
            level = StrengthLevel.BEGINNER
            # Score 0-24 for beginner
            progress = ratio / standards["novice"] if standards["novice"] > 0 else 0
            score = int(progress * 24)

        return level, round(ratio, 2), min(100, max(0, score))

    # -------------------------------------------------------------------------
    # Muscle Group Scoring
    # -------------------------------------------------------------------------

    def calculate_muscle_group_score(
        self,
        muscle_group: str,
        exercise_performances: List[Dict],
        bodyweight_kg: float,
        gender: str = "male",
        *,
        context: Optional[Dict[str, Any]] = None,
    ) -> StrengthScore:
        """
        Calculate strength score for a specific muscle group.

        Delegates to ``compute_composite_muscle_score`` (FEATURE 4). The optional
        ``context`` carries the per-muscle inputs the composite needs (carry-forward
        effective 1RM, weekly sets, sessions_28d, bodyweight trend, etc.). With no
        context it falls back to safe defaults so legacy callers are unaffected.

        Args:
            muscle_group: Target muscle group
            exercise_performances: List of exercise data with weight/reps
            bodyweight_kg: User's bodyweight
            gender: User's gender
            context: Optional dict of composite-score inputs (see compute_composite).

        Returns:
            Complete StrengthScore for the muscle group
        """
        return self.compute_composite_muscle_score(
            muscle_group=muscle_group,
            exercise_performances=exercise_performances,
            bodyweight_kg=bodyweight_kg,
            gender=gender,
            context=context or {},
        )

    # -------------------------------------------------------------------------
    # FEATURE 4 — Composite muscle score
    # -------------------------------------------------------------------------

    @staticmethod
    def _volume_tolerance_score(weekly_sets: float, muscle_group: str) -> float:
        """S2 — weekly-sets vs MEV/MAV/MRV curve (0-100).

            <MEV         : 40 * (sets / MEV)            (ramp toward the floor)
            MEV..MAV     : 40 + 60 * (sets-MEV)/(MAV-MEV)
            MAV..MRV     : 100                          (optimal plateau)
            >MRV         : max(70, 100 - 6*excess)      (overreaching penalty)
        """
        lm = VOLUME_LANDMARKS.get((muscle_group or "").lower(), _DEFAULT_LANDMARK)
        mev, mav, mrv = lm["mev"], lm["mav"], lm["mrv"]
        s = max(0.0, float(weekly_sets))
        if s <= 0:
            return 0.0
        if s < mev:
            return 40.0 * (s / mev) if mev > 0 else 0.0
        if s <= mav:
            denom = (mav - mev) or 1.0
            return 40.0 + 60.0 * ((s - mev) / denom)
        if s <= mrv:
            return 100.0
        excess = s - mrv
        return max(70.0, 100.0 - 6.0 * excess)

    @staticmethod
    def _consistency_score(sessions_28d: float, days_since_last_set: Optional[float]) -> float:
        """S3 — frequency * recency (0-100).

            freqScore  = min(100, sessions_28d / 8 * 100)
            recencyMult = 1.0 if <=7d
                          else clamp(0.5, 1.0, 1 - 0.5*(days-7)/21)
        """
        freq = min(100.0, (max(0.0, float(sessions_28d)) / 8.0) * 100.0)
        if days_since_last_set is None:
            recency_mult = 1.0
        else:
            d = max(0.0, float(days_since_last_set))
            if d <= 7:
                recency_mult = 1.0
            else:
                recency_mult = max(0.5, min(1.0, 1.0 - 0.5 * (d - 7) / 21.0))
        return freq * recency_mult

    @staticmethod
    def _bodyweight_context_delta(
        score_change: float,
        bodyweight_trend_pct: Optional[float],
    ) -> int:
        """bwContextDelta in [-5, +5], applied ONLY when |scoreChange| >= 2.

            relStrength up & bodyweight DOWN > 1.5%   -> +5  (recomposition win)
            relStrength up & bodyweight UP   > 3%     -> -3  (gains partly from mass)
            else                                       ->  0
            missing weight history                     ->  0
        """
        if abs(score_change) < 2:
            return 0
        if bodyweight_trend_pct is None:
            return 0
        going_up = score_change > 0
        if going_up and bodyweight_trend_pct < -1.5:
            return 5
        if going_up and bodyweight_trend_pct > 3.0:
            return -3
        return 0

    def compute_composite_muscle_score(
        self,
        muscle_group: str,
        exercise_performances: List[Dict],
        bodyweight_kg: float,
        gender: str = "male",
        *,
        context: Optional[Dict[str, Any]] = None,
    ) -> StrengthScore:
        """Composite per-muscle strength score (FEATURE 4).

            composite = clamp(0, 100, round(0.60*S1 + 0.25*S2 + 0.15*S3 + bwDelta))

        where:
          * S1 relStrength — classify_strength_level interpolation on the carry-forward
            effective 1RM (from context["effective_1rm_kg"] if present, else the best
            fresh 1RM), machine-aware via equipment, with a bodyweight model for
            unloaded muscles (proxy load = bodyweight_proxy_load_kg, reps → relative
            ladder via the estimated 1RM of that proxy).
          * S2 volTolerance — weekly_sets vs MEV/MAV/MRV (see _volume_tolerance_score).
          * S3 consistency — frequency * recency (see _consistency_score).
          * bwContextDelta — [-5, +5] recomposition nudge (see _bodyweight_context_delta).

        context keys (all optional, safe defaults):
          effective_1rm_kg, effective_1rm_exercise, effective_1rm_equipment,
          weekly_sets, sessions_28d, days_since_last_set, distinct_exercises_alltime,
          days_since_first_set, bodyweight_trend_pct, previous_score.
        """
        ctx = context or {}

        if not exercise_performances and not ctx.get("effective_1rm_kg"):
            return StrengthScore(
                muscle_group=muscle_group,
                strength_score=0,
                strength_level=StrengthLevel.BEGINNER,
                best_exercise_name="",
                best_estimated_1rm_kg=0,
                bodyweight_ratio=0,
                weekly_sets=int(ctx.get("weekly_sets", 0) or 0),
                weekly_volume_kg=0,
                trend="maintaining",
                previous_score=ctx.get("previous_score"),
                score_change=None,
                is_establishing=False,
                score_range_low=None,
                score_range_high=None,
                composite_breakdown={"s1": 0, "s2": 0, "s3": 0, "bw_delta": 0},
            )

        # ── Find the best fresh 1RM + accumulate volume from this window ──────
        best_1rm = 0.0
        best_exercise = ""
        best_equipment: Optional[str] = None
        total_sets = 0
        total_volume = 0.0
        # Per-exercise best 1RM (for the breadth blend, A2). Keyed on exercise name.
        per_exercise_best: Dict[str, Dict[str, Any]] = {}

        # Lazy import to avoid an import cycle (muscle_balance imports filters which
        # is fine; strength service must not pull RAG at module load).
        try:
            from services.exercise_rag.muscle_balance import bodyweight_proxy_load_kg
        except Exception:  # noqa: BLE001
            bodyweight_proxy_load_kg = None  # type: ignore

        for perf in exercise_performances:
            exercise_name = perf.get("exercise_name", "")
            weight_kg = float(perf.get("weight_kg", 0) or 0)
            reps = int(perf.get("reps", 0) or 0)
            sets = int(perf.get("sets", 1) or 1)
            equipment = perf.get("equipment")

            # Bodyweight model: unloaded set → proxy load from bodyweight so an
            # unloaded muscle still produces a non-zero relative-strength signal.
            effective_weight = weight_kg
            if weight_kg <= 0 and reps > 0 and bodyweight_proxy_load_kg is not None:
                effective_weight = bodyweight_proxy_load_kg(exercise_name, bodyweight_kg)

            one_rm = self.calculate_1rm_average(effective_weight, reps)
            if one_rm > best_1rm:
                best_1rm = one_rm
                best_exercise = exercise_name
                best_equipment = equipment

            key = (exercise_name or "").strip().lower()
            if key:
                prev = per_exercise_best.get(key)
                if prev is None or one_rm > prev["one_rm"]:
                    per_exercise_best[key] = {
                        "one_rm": one_rm, "name": exercise_name, "equipment": equipment,
                    }

            total_sets += sets
            total_volume += effective_weight * reps * sets

        # Carry-forward effective 1RM (decayed all-time best) wins over the fresh
        # window if it's higher — the score shouldn't crater on a light week.
        carry_1rm = float(ctx.get("effective_1rm_kg") or 0)
        if carry_1rm > best_1rm:
            best_1rm = carry_1rm
            best_exercise = ctx.get("effective_1rm_exercise") or best_exercise
            best_equipment = ctx.get("effective_1rm_equipment") or best_equipment

        # ── S1 relative strength ─────────────────────────────────────────────
        level, ratio, s1 = self.classify_strength_level(
            best_exercise, best_1rm, bodyweight_kg, gender, equipment=best_equipment
        )

        # ── S1 breadth bonus (A2) — a BROAD base of moderate lifts should count,
        # not just the single strongest lift. Blend the S1 of the top-3 distinct
        # exercises by their own 1RM, then take max(single_best_s1, blended) so the
        # score can ONLY rise from this — no existing user's number can drop.
        # Fail-open: any error keeps the original single-best s1.
        s1_breadth_exercises = 0
        try:
            ranked = sorted(
                per_exercise_best.values(), key=lambda d: d["one_rm"], reverse=True
            )[:3]
            s1_breadth_exercises = len([r for r in ranked if r["one_rm"] > 0])
            if len(ranked) >= 2:
                weights = [0.6, 0.3, 0.1][: len(ranked)]
                wsum = sum(weights)
                blend_acc = 0.0
                for w, r in zip(weights, ranked):
                    _, _, r_s1 = self.classify_strength_level(
                        r["name"], r["one_rm"], bodyweight_kg, gender,
                        equipment=r.get("equipment"),
                    )
                    blend_acc += w * r_s1
                s1_blend = blend_acc / wsum if wsum > 0 else s1
                # 85% blended + 15% single-best, but never below the single-best s1.
                s1 = max(s1, 0.85 * s1_blend + 0.15 * s1)
        except Exception:  # noqa: BLE001 - breadth bonus must never break the score
            pass

        # ── S2 volume tolerance ──────────────────────────────────────────────
        weekly_sets = float(ctx.get("weekly_sets", total_sets) or 0)
        s2 = self._volume_tolerance_score(weekly_sets, muscle_group)

        # ── S3 consistency ───────────────────────────────────────────────────
        sessions_28d = float(ctx.get("sessions_28d", 0) or 0)
        days_since_last = ctx.get("days_since_last_set")
        s3 = self._consistency_score(sessions_28d, days_since_last)

        # ── Composite (pre-bw-delta) + bodyweight context delta ──────────────
        base_composite = 0.60 * s1 + 0.25 * s2 + 0.15 * s3
        previous_score = ctx.get("previous_score")
        provisional = int(round(base_composite))
        score_change_for_delta = (
            (provisional - previous_score) if previous_score is not None else 0
        )
        bw_delta = self._bodyweight_context_delta(
            score_change_for_delta, ctx.get("bodyweight_trend_pct")
        )

        composite = max(0, min(100, int(round(base_composite + bw_delta))))

        # ── Establishing flag + score range ──────────────────────────────────
        distinct_alltime = int(ctx.get("distinct_exercises_alltime", 0) or 0)
        days_since_first = ctx.get("days_since_first_set")
        # A muscle is ESTABLISHED (trusted, show a firm number) only once it has
        # enough signal: trained >=3 times in the last 28d, across >=2 distinct
        # lifts, with its first set >=14 days ago. Until then it is still
        # establishing/calibrating and we show a soft range so an early dip never
        # reads as a real regression. (Establishing is the NEGATION of established.)
        is_established = (
            sessions_28d >= 3
            and distinct_alltime >= 2
            and (days_since_first is not None and float(days_since_first) >= 14)
        )
        is_establishing = not is_established
        score_range_low: Optional[int] = None
        score_range_high: Optional[int] = None
        if is_establishing:
            score_range_low = max(0, composite - 8)
            score_range_high = min(100, composite + 8)

        # Re-derive level from the FINAL composite so the badge matches the number.
        final_level = self._level_from_score(composite)

        # ── Population percentile (A4) + machine flag ─────────────────────────
        # "Stronger than X% of comparable lifters" for the muscle's best lift —
        # ONLY when that lift has a real standard and isn't machine-derived.
        best_is_machine = False
        population_percentile: Optional[float] = None
        try:
            from services.exercise_muscle_resolver import is_machine_equipment
            from services.strength_movement_patterns import matched_known_pattern
            from services.strength_population_standards import ratio_to_percentile

            best_is_machine = is_machine_equipment(best_equipment)
            norm_best = self._normalize_exercise_name(best_exercise)
            has_exact = norm_best in STRENGTH_STANDARDS
            has_real_standard = has_exact or matched_known_pattern(best_exercise, best_equipment)
            if best_1rm > 0 and ratio > 0 and has_real_standard and not best_is_machine:
                ladder = self._resolve_standards(best_exercise, best_equipment)
                if gender == "female":
                    ladder = {k: v * 0.65 for k, v in ladder.items()}
                population_percentile = ratio_to_percentile(ladder, ratio)
        except Exception:  # noqa: BLE001 - percentile is additive, never break the score
            population_percentile = None

        return StrengthScore(
            muscle_group=muscle_group,
            strength_score=composite,
            strength_level=final_level,
            best_exercise_name=best_exercise,
            best_estimated_1rm_kg=round(best_1rm, 2),
            bodyweight_ratio=ratio,
            weekly_sets=int(weekly_sets),
            weekly_volume_kg=round(total_volume, 2),
            trend="maintaining",  # filled by the caller from historical scores
            previous_score=previous_score,
            score_change=None,     # filled by the caller (vs persisted previous)
            is_establishing=is_establishing,
            score_range_low=score_range_low,
            score_range_high=score_range_high,
            composite_breakdown={
                "s1_rel_strength": round(s1, 1),
                "s2_vol_tolerance": round(s2, 1),
                "s3_consistency": round(s3, 1),
                "bw_context_delta": bw_delta,
                "s1_breadth_exercises": s1_breadth_exercises,
                "best_is_machine": best_is_machine,
            },
            population_percentile=population_percentile,
            best_is_machine=best_is_machine,
        )

    @staticmethod
    def _level_from_score(score: int) -> StrengthLevel:
        """Map a 0-100 score to a StrengthLevel band (same bands as overall)."""
        if score >= 90:
            return StrengthLevel.ELITE
        if score >= 70:
            return StrengthLevel.ADVANCED
        if score >= 50:
            return StrengthLevel.INTERMEDIATE
        if score >= 25:
            return StrengthLevel.NOVICE
        return StrengthLevel.BEGINNER

    def calculate_all_muscle_scores(
        self,
        workout_data: List[Dict],
        bodyweight_kg: float,
        gender: str = "male",
    ) -> Dict[str, StrengthScore]:
        """
        Calculate strength scores for all muscle groups.

        Args:
            workout_data: All exercise performances from workouts
            bodyweight_kg: User's bodyweight
            gender: User's gender

        Returns:
            Dict mapping muscle group to StrengthScore
        """
        # Group exercises by muscle group
        muscle_exercises: Dict[str, List[Dict]] = {mg.value: [] for mg in MuscleGroup}

        for exercise in workout_data:
            exercise_name = exercise.get("exercise_name", "")
            # Use the unified resolver so AI-generated bodyweight exercises
            # whose names aren't in the static map still attribute via the
            # `primary_muscle` / `muscle_groups` fields the frontend now
            # includes in each per-set record.
            muscle_groups = self.get_exercise_muscle_groups(
                exercise_name, exercise_data=exercise
            )

            # Assign to each muscle group (primary contribution)
            for i, mg in enumerate(muscle_groups):
                if mg in muscle_exercises:
                    # First muscle group gets full credit, others get partial
                    weight_factor = 1.0 if i == 0 else 0.5
                    exercise_copy = exercise.copy()
                    exercise_copy["weight_kg"] = float(exercise.get("weight_kg", 0)) * weight_factor
                    muscle_exercises[mg].append(exercise_copy)

        # Calculate score for each muscle group
        scores = {}
        for mg in MuscleGroup:
            scores[mg.value] = self.calculate_muscle_group_score(
                mg.value,
                muscle_exercises[mg.value],
                bodyweight_kg,
                gender,
            )

        return scores

    # -------------------------------------------------------------------------
    # Trend Analysis
    # -------------------------------------------------------------------------

    @staticmethod
    def calculate_trend(
        current_score: int,
        previous_scores: List[int],
        threshold: int = 3,
    ) -> str:
        """
        Determine strength trend based on score history.

        Args:
            current_score: Current strength score
            previous_scores: List of previous scores (oldest first)
            threshold: Minimum change to be considered improving/declining

        Returns:
            'improving', 'maintaining', or 'declining'
        """
        if not previous_scores:
            return "maintaining"

        # Use the average of last 2-4 scores as baseline
        baseline = sum(previous_scores[-4:]) / len(previous_scores[-4:])

        change = current_score - baseline

        if change >= threshold:
            return "improving"
        elif change <= -threshold:
            return "declining"
        else:
            return "maintaining"

    # -------------------------------------------------------------------------
    # Overall Strength Score
    # -------------------------------------------------------------------------

    def calculate_overall_strength_score(
        self,
        muscle_scores: Dict[str, StrengthScore],
    ) -> Tuple[int, StrengthLevel]:
        """
        Calculate overall strength score from muscle group scores.

        Uses weighted average with compound lift muscles weighted higher.

        Args:
            muscle_scores: Dict of muscle group scores

        Returns:
            Tuple of (overall_score, overall_level)
        """
        # Weights for different muscle groups
        # Higher weight for muscles involved in main compound lifts
        weights = {
            "quads": 1.5,
            "hamstrings": 1.2,
            "glutes": 1.2,
            "chest": 1.5,
            "back": 1.5,
            "shoulders": 1.0,
            "biceps": 0.7,
            "triceps": 0.7,
            "forearms": 0.5,
            "calves": 0.5,
            "core": 0.8,
            "traps": 0.6,
        }

        total_weighted_score = 0
        total_weight = 0

        for mg, score in muscle_scores.items():
            weight = weights.get(mg, 1.0)
            total_weighted_score += score.strength_score * weight
            total_weight += weight

        overall_score = int(total_weighted_score / total_weight) if total_weight > 0 else 0

        # Determine level from overall score
        if overall_score >= 90:
            level = StrengthLevel.ELITE
        elif overall_score >= 70:
            level = StrengthLevel.ADVANCED
        elif overall_score >= 50:
            level = StrengthLevel.INTERMEDIATE
        elif overall_score >= 25:
            level = StrengthLevel.NOVICE
        else:
            level = StrengthLevel.BEGINNER

        return overall_score, level

    # -------------------------------------------------------------------------
    # Helper Methods
    # -------------------------------------------------------------------------

    @staticmethod
    def _normalize_exercise_name(name: str) -> str:
        """Normalize exercise name for matching."""
        # Convert to lowercase, replace spaces/hyphens with underscores
        normalized = name.lower().strip()
        normalized = normalized.replace(" ", "_").replace("-", "_")
        normalized = normalized.replace("dumbbell_", "").replace("barbell_", "")
        return normalized

    @staticmethod
    def get_exercise_muscle_groups(
        exercise_name: str,
        exercise_data: Optional[Dict[str, Any]] = None,
        *,
        library_index: Optional[Dict[str, Any]] = None,
    ) -> List[str]:
        """Get muscle groups targeted by an exercise.

        Lookup order (each tier wins on first hit — fast, hand-curated tiers first):
          1. Static map keyed on the normalized name (substring fallback).
          2. Caller-provided `exercise_data` muscle metadata (AI plan JSON).
          3. Library index (2026-06): the app's ``exercise_library_cleaned`` muscle
             data, normalized to canonical groups by ``exercise_muscle_resolver``.
             This tier is what makes machine/cable/accessory exercises (whose logs
             carry no AI muscle fields and aren't in the static map) finally count
             toward the strength score — the core "my exercise isn't reflected" fix.
          4. Empty list (caller decides whether to bucket under generic
             "full_body" or skip).

        `library_index` is optional and defaults to None → tier 3 is a no-op and
        behavior is byte-identical to before (fail-open).
        """
        normalized = StrengthCalculatorService._normalize_exercise_name(exercise_name)

        # 1. Direct lookup
        if normalized in EXERCISE_MUSCLE_GROUPS:
            return EXERCISE_MUSCLE_GROUPS[normalized]

        # Partial matching
        for key, groups in EXERCISE_MUSCLE_GROUPS.items():
            if key in normalized or normalized in key:
                return groups

        # 2. Fallback to caller-provided exercise metadata (AI plan).
        if isinstance(exercise_data, dict):
            mg_raw = exercise_data.get("muscle_groups")
            if isinstance(mg_raw, list) and mg_raw:
                cleaned = [str(m).strip().lower() for m in mg_raw if m]
                if cleaned:
                    return cleaned
            primary = exercise_data.get("primary_muscle") or exercise_data.get("muscle_group")
            if isinstance(primary, str) and primary.strip():
                return [primary.strip().lower()]

        # 3. Library index (data-driven breadth tier).
        if library_index:
            try:
                from services.exercise_muscle_resolver import lookup_library_muscles
                lib_muscles = lookup_library_muscles(exercise_name, library_index)
                if lib_muscles:
                    return lib_muscles
            except Exception:  # noqa: BLE001 - never let attribution break the score
                pass

        return []


    # -------------------------------------------------------------------------
    # RPE Estimation
    # -------------------------------------------------------------------------

    @staticmethod
    def estimate_rpe(
        weight_kg: float,
        reps_completed: int,
        estimated_1rm: float,
    ) -> Tuple[float, float, str]:
        """
        Estimate RPE (Rate of Perceived Exertion) from reps completed and %1RM.

        Uses standard RPE-to-%1RM tables based on research by Mike Tuchscherer
        and Eric Helms.

        Args:
            weight_kg: Weight lifted in kg
            reps_completed: Number of reps completed
            estimated_1rm: User's estimated 1RM for this exercise

        Returns:
            Tuple of (estimated_rpe, confidence, description)
            - estimated_rpe: 6.0 to 10.0
            - confidence: 0.0 to 1.0 (higher for lower reps)
            - description: Human-readable description
        """
        if estimated_1rm <= 0 or weight_kg <= 0:
            return (7.0, 0.3, "Insufficient data for accurate RPE estimation")

        # Calculate percentage of 1RM
        percent_1rm = weight_kg / estimated_1rm

        # RPE chart mapping: (reps, %1RM) -> RPE
        # Based on Tuchscherer/Helms research
        # Format: RPE -> list of (reps, %1RM)
        RPE_TABLE = {
            10.0: [(1, 1.00), (2, 0.955), (3, 0.922), (4, 0.892), (5, 0.863),
                   (6, 0.837), (7, 0.811), (8, 0.786), (9, 0.762), (10, 0.739)],
            9.5: [(1, 0.978), (2, 0.939), (3, 0.907), (4, 0.878), (5, 0.850),
                  (6, 0.824), (7, 0.799), (8, 0.774), (9, 0.751), (10, 0.728)],
            9.0: [(1, 0.955), (2, 0.922), (3, 0.892), (4, 0.863), (5, 0.837),
                  (6, 0.811), (7, 0.786), (8, 0.762), (9, 0.739), (10, 0.717)],
            8.5: [(1, 0.939), (2, 0.907), (3, 0.878), (4, 0.850), (5, 0.824),
                  (6, 0.799), (7, 0.774), (8, 0.751), (9, 0.728), (10, 0.707)],
            8.0: [(1, 0.922), (2, 0.892), (3, 0.863), (4, 0.837), (5, 0.811),
                  (6, 0.786), (7, 0.762), (8, 0.739), (9, 0.717), (10, 0.696)],
            7.5: [(1, 0.907), (2, 0.878), (3, 0.850), (4, 0.824), (5, 0.799),
                  (6, 0.774), (7, 0.751), (8, 0.728), (9, 0.707), (10, 0.686)],
            7.0: [(1, 0.892), (2, 0.863), (3, 0.837), (4, 0.811), (5, 0.786),
                  (6, 0.762), (7, 0.739), (8, 0.717), (9, 0.696), (10, 0.676)],
            6.5: [(1, 0.878), (2, 0.850), (3, 0.824), (4, 0.799), (5, 0.774),
                  (6, 0.751), (7, 0.728), (8, 0.707), (9, 0.686), (10, 0.666)],
            6.0: [(1, 0.863), (2, 0.837), (3, 0.811), (4, 0.786), (5, 0.762),
                  (6, 0.739), (7, 0.717), (8, 0.696), (9, 0.676), (10, 0.656)],
        }

        # Cap reps at 10 for table lookup
        lookup_reps = min(reps_completed, 10)
        if lookup_reps < 1:
            lookup_reps = 1

        # Find the closest RPE match
        best_rpe = 7.0
        best_diff = float('inf')

        for rpe, rep_percent_pairs in RPE_TABLE.items():
            for reps, expected_percent in rep_percent_pairs:
                if reps == lookup_reps:
                    diff = abs(percent_1rm - expected_percent)
                    if diff < best_diff:
                        best_diff = diff
                        best_rpe = rpe
                    break

        # Adjust for reps > 10 (higher reps = lower effective RPE)
        if reps_completed > 10:
            # Each rep beyond 10 typically lowers RPE by ~0.2
            adjustment = (reps_completed - 10) * 0.1
            best_rpe = max(6.0, best_rpe - adjustment)

        # Calculate confidence based on rep range
        # Lower reps = more reliable 1RM = higher confidence
        if reps_completed <= 3:
            confidence = 0.90
        elif reps_completed <= 5:
            confidence = 0.85
        elif reps_completed <= 8:
            confidence = 0.75
        elif reps_completed <= 10:
            confidence = 0.65
        else:
            # High rep ranges are less reliable
            confidence = max(0.40, 0.65 - (reps_completed - 10) * 0.03)

        # Generate description
        if best_rpe >= 9.5:
            description = "Maximum effort - at or very near failure"
        elif best_rpe >= 9.0:
            description = "Very hard - could do 1 more rep"
        elif best_rpe >= 8.0:
            description = "Challenging - could do 2 more reps"
        elif best_rpe >= 7.0:
            description = "Moderate - could do 3 more reps"
        else:
            description = "Light - could do 4+ more reps"

        return (round(best_rpe, 1), round(confidence, 2), description)

    @staticmethod
    def calculate_weight_for_rpe(
        estimated_1rm: float,
        target_reps: int,
        target_rpe: float = 8.0,
    ) -> float:
        """
        Calculate the weight needed to hit a target RPE for given reps.

        This is the inverse of estimate_rpe - given a target RPE and reps,
        calculate what weight to use.

        Args:
            estimated_1rm: User's estimated 1RM for this exercise
            target_reps: Number of reps planned
            target_rpe: Target RPE (6.0 to 10.0), default 8.0

        Returns:
            Suggested weight in kg
        """
        # RPE to %1RM lookup table (for common rep ranges)
        # Based on Tuchscherer/Helms research
        RPE_PERCENT_MAP = {
            # (RPE, reps) -> %1RM
            (10.0, 1): 1.00, (10.0, 3): 0.922, (10.0, 5): 0.863, (10.0, 8): 0.786, (10.0, 10): 0.739,
            (9.0, 1): 0.955, (9.0, 3): 0.892, (9.0, 5): 0.837, (9.0, 8): 0.762, (9.0, 10): 0.717,
            (8.0, 1): 0.922, (8.0, 3): 0.863, (8.0, 5): 0.811, (8.0, 8): 0.739, (8.0, 10): 0.696,
            (7.0, 1): 0.892, (7.0, 3): 0.837, (7.0, 5): 0.786, (7.0, 8): 0.717, (7.0, 10): 0.676,
            (6.0, 1): 0.863, (6.0, 3): 0.811, (6.0, 5): 0.762, (6.0, 8): 0.696, (6.0, 10): 0.656,
        }

        # Clamp inputs
        target_rpe = max(6.0, min(10.0, target_rpe))
        target_reps = max(1, min(10, target_reps))

        # Find closest match in table
        best_key = None
        best_diff = float('inf')

        for (rpe, reps) in RPE_PERCENT_MAP.keys():
            diff = abs(rpe - target_rpe) + abs(reps - target_reps) * 0.1
            if diff < best_diff:
                best_diff = diff
                best_key = (rpe, reps)

        if best_key:
            percent = RPE_PERCENT_MAP[best_key]
        else:
            # Default to 75% if no match
            percent = 0.75

        return round(estimated_1rm * percent, 1)

    # -------------------------------------------------------------------------
    # DOTS / Wilks Score
    # -------------------------------------------------------------------------

    @staticmethod
    def calculate_dots_score(
        bodyweight_kg: float,
        total_kg: float,
        gender: str = "male",
    ) -> Dict[str, float]:
        """
        Calculate DOTS and Wilks scores for powerlifting total.

        DOTS (Dynamic Objective Team Scoring) is the modern IPF replacement
        for Wilks, using a quintic polynomial denominator.

        Args:
            bodyweight_kg: User's body weight in kg
            total_kg: Sum of best squat + bench + deadlift 1RMs in kg
            gender: "male" or "female"

        Returns:
            Dict with dots_score, wilks_score
        """
        bw = max(bodyweight_kg, 40.0)  # floor to avoid division issues

        # ── DOTS coefficients (IPF, effective 2020) ──
        if gender == "female":
            a = -1.1057e-07
            b = 1.1258e-04
            c = -4.7585e-02
            d = 1.3206e+01
            e = -5.7294e+02
        else:
            a = -1.0930e-07
            b = 1.1497e-04
            c = -5.0317e-02
            d = 1.3814e+01
            e = -5.8650e+02

        denominator = a * bw**4 + b * bw**3 + c * bw**2 + d * bw + e
        dots = round(total_kg * (500.0 / denominator), 2) if denominator != 0 else 0.0

        # ── Wilks coefficients (2020 revision) ──
        if gender == "female":
            wa = -2.16195e-06
            wb = 1.30567e-03
            wc = -2.28420e-01
            wd = -7.01863e+00
            we = 1.29192e+03
            wf = -8.67270e+04
        else:
            wa = -2.16195e-06
            wb = 1.61400e-03
            wc = -3.30725e-01
            wd = 2.48867e+01
            we = 3.54016e+02
            wf = -5.72299e+04

        w_denom = wf + we * bw + wd * bw**2 + wc * bw**3 + wb * bw**4 + wa * bw**5
        wilks = round(total_kg * (600.0 / w_denom), 2) if w_denom != 0 else 0.0

        return {"dots_score": dots, "wilks_score": wilks}


# Singleton instance
strength_calculator_service = StrengthCalculatorService()
