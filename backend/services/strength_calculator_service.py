"""
Strength Calculator Service - 1RM estimation, strength level classification, and muscle group scoring.

Handles:
- 1RM estimation using multiple formulas (Brzycki, Epley, Lombardi)
- Strength level classification (Beginner → Elite) based on bodyweight ratios
- Per-muscle-group strength scoring (0-100)
- Trend analysis and progress tracking
"""
from typing import Dict, List, Optional, Tuple
from datetime import datetime, date, timedelta
from decimal import Decimal
from dataclasses import dataclass
from enum import Enum
import logging

logger = logging.getLogger(__name__)


class StrengthLevel(str, Enum):
    """Strength level classifications based on industry standards."""
    BEGINNER = "beginner"
    NOVICE = "novice"
    INTERMEDIATE = "intermediate"
    ADVANCED = "advanced"
    ELITE = "elite"


class MuscleGroup(str, Enum):
    """Supported muscle groups for scoring."""
    CHEST = "chest"
    BACK = "back"
    SHOULDERS = "shoulders"
    BICEPS = "biceps"
    TRICEPS = "triceps"
    FOREARMS = "forearms"
    QUADS = "quads"
    HAMSTRINGS = "hamstrings"
    GLUTES = "glutes"
    CALVES = "calves"
    CORE = "core"
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
            # Most accurate for 1-10 reps
            estimated = weight_kg * (36 / (37 - reps))
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
            estimated = weight_kg * (36 / (37 - reps))

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

        brzycki = weight_kg * (36 / (37 - reps))
        epley = weight_kg * (1 + reps / 30)
        lombardi = weight_kg * (reps ** 0.1)

        return round((brzycki + epley + lombardi) / 3, 2)

    # -------------------------------------------------------------------------
    # Strength Level Classification
    # -------------------------------------------------------------------------

    def classify_strength_level(
        self,
        exercise_name: str,
        estimated_1rm: float,
        bodyweight_kg: float,
        gender: str = "male",
    ) -> Tuple[StrengthLevel, float, int]:
        """
        Classify strength level based on bodyweight ratio.

        Args:
            exercise_name: Name of the exercise (normalized)
            estimated_1rm: Estimated 1RM in kg
            bodyweight_kg: User's bodyweight in kg
            gender: 'male' or 'female' (affects thresholds)

        Returns:
            Tuple of (level, bodyweight_ratio, score_0_100)
        """
        # Normalize exercise name
        normalized_name = self._normalize_exercise_name(exercise_name)

        # Get standards for this exercise
        standards = STRENGTH_STANDARDS.get(normalized_name)
        if not standards:
            # Use generic compound exercise standards
            standards = STRENGTH_STANDARDS["squat"]

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
    ) -> StrengthScore:
        """
        Calculate strength score for a specific muscle group.

        Args:
            muscle_group: Target muscle group
            exercise_performances: List of exercise data with weight/reps
            bodyweight_kg: User's bodyweight
            gender: User's gender

        Returns:
            Complete StrengthScore for the muscle group
        """
        if not exercise_performances:
            return StrengthScore(
                muscle_group=muscle_group,
                strength_score=0,
                strength_level=StrengthLevel.BEGINNER,
                best_exercise_name="",
                best_estimated_1rm_kg=0,
                bodyweight_ratio=0,
                weekly_sets=0,
                weekly_volume_kg=0,
                trend="maintaining",
                previous_score=None,
                score_change=None,
            )

        # Find the best 1RM among exercises for this muscle group
        best_1rm = 0
        best_exercise = ""
        total_sets = 0
        total_volume = 0

        for perf in exercise_performances:
            exercise_name = perf.get("exercise_name", "")
            weight_kg = float(perf.get("weight_kg", 0))
            reps = int(perf.get("reps", 0))
            sets = int(perf.get("sets", 1))

            # Calculate 1RM
            one_rm = self.calculate_1rm_average(weight_kg, reps)

            if one_rm > best_1rm:
                best_1rm = one_rm
                best_exercise = exercise_name

            # Accumulate volume
            total_sets += sets
            total_volume += weight_kg * reps * sets

        # Classify strength level
        level, ratio, score = self.classify_strength_level(
            best_exercise, best_1rm, bodyweight_kg, gender
        )

        return StrengthScore(
            muscle_group=muscle_group,
            strength_score=score,
            strength_level=level,
            best_exercise_name=best_exercise,
            best_estimated_1rm_kg=round(best_1rm, 2),
            bodyweight_ratio=ratio,
            weekly_sets=total_sets,
            weekly_volume_kg=round(total_volume, 2),
            trend="maintaining",  # Will be calculated separately with historical data
            previous_score=None,
            score_change=None,
        )

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
            normalized = self._normalize_exercise_name(exercise_name)

            # Find muscle groups for this exercise
            muscle_groups = EXERCISE_MUSCLE_GROUPS.get(normalized, [])

            # If not found, try partial matching
            if not muscle_groups:
                for key, groups in EXERCISE_MUSCLE_GROUPS.items():
                    if key in normalized or normalized in key:
                        muscle_groups = groups
                        break

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
    def get_exercise_muscle_groups(exercise_name: str) -> List[str]:
        """Get muscle groups targeted by an exercise."""
        normalized = StrengthCalculatorService._normalize_exercise_name(exercise_name)

        # Direct lookup
        if normalized in EXERCISE_MUSCLE_GROUPS:
            return EXERCISE_MUSCLE_GROUPS[normalized]

        # Partial matching
        for key, groups in EXERCISE_MUSCLE_GROUPS.items():
            if key in normalized or normalized in key:
                return groups

        # Default to empty list
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


# Singleton instance
strength_calculator_service = StrengthCalculatorService()
