"""
Exercise parameter validation and safety caps.

This module provides the CRITICAL safety net that prevents extreme workouts
(e.g., 90 squats) from reaching users, regardless of what Gemini generates.

Handles:
- Fitness level caps (beginner/intermediate/advanced)
- Age-based caps (young_adult through elderly)
- Hell mode elevated caps
- Advanced exercise filtering for beginners
- Comeback mode reductions
- Set/rep limit enforcement
- Duration truncation
"""
from typing import List, Dict, Any, Optional

from core.logger import get_logger
from core.exercise_data import get_exercise_type, get_rep_limits

logger = get_logger(__name__)


# Absolute maximums (safety net - never exceed regardless of fitness level)
ABSOLUTE_MAX_REPS = 30  # Never more than 30 reps of anything
ABSOLUTE_MAX_SETS = 6   # Never more than 6 sets
ABSOLUTE_MIN_REST = 30  # Always at least 30 sec rest

# Advanced calisthenics exercises that require YEARS of training
# These should NEVER be given to beginners - they risk injury
ADVANCED_EXERCISES_BLOCKLIST = {
    # Planche movements (require years of strength)
    "planche", "planche push up", "planche push-up", "full planche", "straddle planche",
    "planche lean", "pseudo planche",
    # Front lever movements
    "front lever", "front lever pull up", "front lever row", "front lever raise",
    # Muscle ups
    "muscle up", "muscle-up", "bar muscle up", "ring muscle up",
    # Handstand movements
    "handstand push up", "handstand push-up", "90 degree push up", "pike push up on wall",
    "freestanding handstand push up",
    # One arm movements
    "one arm pull up", "one arm pull-up", "one arm chin up", "one arm push up",
    "one arm push-up", "archer pull up", "archer push up",
    # Pistol squat variations
    "pistol squat", "one leg squat", "shrimp squat", "dragon squat",
    # Human flag and other advanced
    "human flag", "back lever", "iron cross", "maltese", "victorian",
    # L-sit and V-sit
    "l-sit", "l sit", "v-sit", "v sit", "manna",
    # Advanced ring movements
    "iron cross", "maltese cross", "ring handstand",
}

# Fitness level caps - applied to all exercises from Gemini
FITNESS_LEVEL_CAPS = {
    "beginner": {"max_sets": 3, "max_reps": 12, "min_rest": 60},
    "intermediate": {"max_sets": 4, "max_reps": 15, "min_rest": 45},
    "advanced": {"max_sets": 5, "max_reps": 20, "min_rest": 30},
}

# Exercises that naturally use higher rep ranges (bodyweight, isolation, core, etc.)
# These get a +8 rep bonus on top of the fitness level cap
HIGH_REP_EXERCISE_KEYWORDS = {
    # Core / abs
    "crunch", "sit-up", "sit up", "situp", "bicycle", "russian twist",
    "leg raise", "flutter kick", "scissor kick", "mountain climber",
    "dead bug", "bird dog", "plank jack", "toe touch",
    "heel tap", "v-up", "v up",
    # Calves
    "calf raise", "calf press", "heel raise",
    # Glutes / hip
    "glute bridge", "hip thrust", "fire hydrant", "clamshell",
    "donkey kick", "kickback", "hip circle", "band walk",
    # Light isolation
    "face pull", "band pull apart", "band pull-apart",
    "lateral raise", "front raise", "reverse fly",
    "wrist curl", "forearm curl",
    # Bodyweight conditioning
    "jumping jack", "high knee", "butt kick", "burpee",
    "squat jump", "jump squat", "box step", "step up", "step-up",
    "wall sit", "wall squat",
}


def is_high_rep_exercise(exercise_name: str) -> bool:
    """Check if an exercise naturally uses higher rep ranges."""
    name_lower = exercise_name.lower().strip()
    return any(kw in name_lower for kw in HIGH_REP_EXERCISE_KEYWORDS)


# Hell mode caps - higher limits for maximum intensity workouts
# Users must accept risk warning before Hell mode is enabled
HELL_MODE_CAPS = {
    "max_sets": 6,
    "max_reps": 20,
    "min_rest": 30,
}

# Age-based additional caps - comprehensive age brackets
AGE_CAPS = {
    "young_adult": {
        "max_age": 29, "min_age": 18,
        "max_reps": 25, "max_sets": 6, "min_rest": 30,
        "intensity_ceiling": 1.0, "rest_multiplier": 1.0,
    },
    "adult": {
        "max_age": 44, "min_age": 30,
        "max_reps": 20, "max_sets": 5, "min_rest": 45,
        "intensity_ceiling": 0.95, "rest_multiplier": 1.1,
    },
    "middle_aged": {
        "max_age": 59, "min_age": 45,
        "max_reps": 16, "max_sets": 4, "min_rest": 60,
        "intensity_ceiling": 0.85, "rest_multiplier": 1.25,
    },
    "senior": {
        "max_age": 74, "min_age": 60,
        "max_reps": 12, "max_sets": 3, "min_rest": 75,
        "intensity_ceiling": 0.75, "rest_multiplier": 1.5,
    },
    "elderly": {
        "max_age": None, "min_age": 75,
        "max_reps": 10, "max_sets": 3, "min_rest": 90,
        "intensity_ceiling": 0.65, "rest_multiplier": 2.0,
    },
}


def get_age_bracket_from_age(age: int) -> str:
    """Get the age bracket for a given age."""
    if age < 30:
        return "young_adult"
    elif age < 45:
        return "adult"
    elif age < 60:
        return "middle_aged"
    elif age < 75:
        return "senior"
    else:
        return "elderly"


def is_advanced_exercise(exercise_name: str) -> bool:
    """
    Check if an exercise is an advanced calisthenics movement.

    These exercises require years of progressive training and should
    NOT be given to beginners as they risk injury.
    """
    if not exercise_name:
        return False

    name_lower = exercise_name.lower().strip()

    # Direct match
    if name_lower in ADVANCED_EXERCISES_BLOCKLIST:
        return True

    # Partial match
    for blocked_term in ADVANCED_EXERCISES_BLOCKLIST:
        if blocked_term in name_lower:
            return True

    return False


def validate_and_cap_exercise_parameters(
    exercises: List[dict],
    fitness_level: str = "intermediate",
    age: int = None,
    is_comeback: bool = False,
    rep_preferences: dict = None,
    difficulty: str = None
) -> List[dict]:
    """
    Validate and cap exercise parameters to prevent extreme workouts.

    This is a CRITICAL safety net that runs AFTER Gemini generates exercises.
    It ensures that regardless of what Gemini returns, users never get
    dangerous workout parameters like 90 squats.

    Args:
        exercises: List of exercise dicts from Gemini
        fitness_level: User's fitness level (beginner, intermediate, advanced)
        age: User's age (for age-based caps)
        is_comeback: Whether user is returning from a break
        rep_preferences: User's rep preferences from get_user_rep_preferences()
        difficulty: Workout difficulty level ('easy', 'medium', 'hard', 'hell').

    Returns:
        Exercises with capped reps, sets, and adjusted rest times
    """
    if not exercises:
        return exercises

    # Check if this is Hell mode
    is_hell_mode = difficulty and difficulty.lower() == "hell"

    if is_hell_mode:
        caps = HELL_MODE_CAPS
        logger.debug("[Hell Mode] Using elevated caps for maximum intensity workout")
    else:
        caps = FITNESS_LEVEL_CAPS.get(fitness_level.lower() if fitness_level else "intermediate",
                                       FITNESS_LEVEL_CAPS["intermediate"])

    # Get user's sets preferences (with defaults)
    user_max_sets = ABSOLUTE_MAX_SETS
    user_min_sets = 2
    enforce_rep_ceiling = False
    user_max_reps_ceiling = None

    if rep_preferences:
        user_max_sets = rep_preferences.get("max_sets_per_exercise", ABSOLUTE_MAX_SETS)
        user_min_sets = rep_preferences.get("min_sets_per_exercise", 2)
        enforce_rep_ceiling = rep_preferences.get("enforce_rep_ceiling", False)
        if enforce_rep_ceiling:
            user_max_reps_ceiling = rep_preferences.get("max_reps")

    validated_exercises = []
    filtered_count = 0

    for ex in exercises:
        # SAFETY: Filter out advanced exercises for beginners
        exercise_name = ex.get("name", "")
        if fitness_level and fitness_level.lower() == "beginner":
            if is_advanced_exercise(exercise_name):
                logger.warning(
                    f"Filtered out advanced exercise '{exercise_name}' for beginner user"
                )
                filtered_count += 1
                continue

        validated_ex = dict(ex)

        # Get original values (with defaults)
        original_sets = ex.get("sets", 3)
        original_reps = ex.get("reps", 10)
        original_rest = ex.get("rest_seconds", 60)

        # Handle reps if it's a string like "8-12"
        if isinstance(original_reps, str):
            try:
                if "-" in original_reps:
                    parts = original_reps.split("-")
                    original_reps = int(parts[1].strip())
                else:
                    original_reps = int(original_reps.strip())
            except (ValueError, IndexError):
                original_reps = 10

        try:
            original_reps = int(original_reps)
        except (ValueError, TypeError):
            original_reps = 10

        try:
            original_sets = int(original_sets)
        except (ValueError, TypeError):
            original_sets = 3

        try:
            original_rest = int(original_rest)
        except (ValueError, TypeError):
            original_rest = 60

        # Step 1: Apply fitness level caps AND user's sets preference
        effective_max_sets = min(caps["max_sets"], user_max_sets, ABSOLUTE_MAX_SETS)
        capped_sets = min(original_sets, effective_max_sets)
        capped_sets = max(capped_sets, user_min_sets)

        effective_max_reps = caps["max_reps"]
        if is_high_rep_exercise(exercise_name):
            effective_max_reps = min(caps["max_reps"] + 8, ABSOLUTE_MAX_REPS)

        capped_reps = min(original_reps, effective_max_reps, ABSOLUTE_MAX_REPS)

        if enforce_rep_ceiling and user_max_reps_ceiling:
            capped_reps = min(capped_reps, user_max_reps_ceiling)

        capped_rest = max(original_rest, caps["min_rest"], ABSOLUTE_MIN_REST)

        # Step 2: Apply age-based caps (SKIP for Hell mode)
        if age and age >= 18 and not is_hell_mode:
            age_bracket = get_age_bracket_from_age(age)
            age_limits = AGE_CAPS[age_bracket]

            capped_reps = min(capped_reps, age_limits["max_reps"])
            capped_sets = min(capped_sets, age_limits["max_sets"])
            capped_rest = max(capped_rest, age_limits["min_rest"])

            if age_limits["rest_multiplier"] > 1.0:
                capped_rest = int(capped_rest * age_limits["rest_multiplier"])

            if validated_ex.get("weight_kg") and age_limits["intensity_ceiling"] < 1.0:
                original_weight = validated_ex["weight_kg"]
                validated_ex["weight_kg"] = round(original_weight * age_limits["intensity_ceiling"], 1)
                if original_weight != validated_ex["weight_kg"]:
                    logger.debug(
                        f"[Age Caps] Reduced weight for {ex.get('name', 'Unknown')}: "
                        f"{original_weight}kg -> {validated_ex['weight_kg']}kg "
                        f"(age={age}, intensity_ceiling={age_limits['intensity_ceiling']})"
                    )
        elif age and age >= 18 and is_hell_mode:
            logger.debug(
                f"[Hell Mode] Skipping ALL age-based caps for {ex.get('name', 'Unknown')}: "
                f"sets={original_sets}, reps={original_reps}, weight={validated_ex.get('weight_kg')}kg "
                f"(difficulty=hell, age={age})"
            )

        # Step 3: Apply comeback reduction
        if is_comeback:
            capped_reps = max(3, int(capped_reps * 0.7))
            capped_sets = max(2, capped_sets - 1)
            capped_rest = int(capped_rest * 1.2)

        # Apply the validated values
        validated_ex["sets"] = capped_sets
        validated_ex["reps"] = capped_reps
        validated_ex["rest_seconds"] = capped_rest

        # Cap per-set target_reps using exercise-type ceiling
        if "set_targets" in validated_ex and validated_ex["set_targets"]:
            ex_type = get_exercise_type(exercise_name)
            _, type_max_reps = get_rep_limits(ex_type)
            per_set_ceiling = min(capped_reps, type_max_reps)
            for st in validated_ex["set_targets"]:
                if isinstance(st, dict) and "target_reps" in st:
                    if isinstance(st["target_reps"], int) and st["target_reps"] > per_set_ceiling:
                        st["target_reps"] = per_set_ceiling

        # Log when significant capping occurs
        if original_reps > capped_reps + 5 or original_sets > capped_sets + 1:
            logger.warning(
                f"⚠️ [Validation] Capped '{ex.get('name', 'Unknown')}': "
                f"sets {original_sets}->{capped_sets}, reps {original_reps}->{capped_reps}, "
                f"rest {original_rest}->{capped_rest}s "
                f"(fitness={fitness_level}, age={age}, comeback={is_comeback})"
            )

        validated_exercises.append(validated_ex)

    # Log summary if any exercise was capped
    total_original_volume = sum(
        (ex.get("sets", 3) * (int(ex.get("reps", 10)) if isinstance(ex.get("reps", 10), int)
                              else 10))
        for ex in exercises
    )
    total_capped_volume = sum(ex["sets"] * ex["reps"] for ex in validated_exercises)

    if total_capped_volume < total_original_volume * 0.9:
        reduction_pct = (1 - total_capped_volume / total_original_volume) * 100
        logger.info(
            f"🛡️ [Validation] Total workout volume reduced by {reduction_pct:.1f}% "
            f"(fitness={fitness_level}, age={age}, comeback={is_comeback})"
        )

    return validated_exercises


def enforce_set_rep_limits(
    exercises: List[dict],
    set_rep_limits: dict,
    exercise_patterns: dict = None,
) -> List[dict]:
    """
    Post-generation validation to enforce user's set/rep limits.

    This is a CRITICAL safety net that runs AFTER Gemini generates exercises
    and AFTER validate_and_cap_exercise_parameters.
    """
    if not exercises:
        return exercises

    max_sets = set_rep_limits.get("max_sets_per_exercise", 5)
    min_sets = set_rep_limits.get("min_sets_per_exercise", 2)
    max_reps = set_rep_limits.get("max_reps_per_set", 15)
    min_reps = set_rep_limits.get("min_reps_per_set", 6)

    enforced_exercises = []
    violations_fixed = 0

    for ex in exercises:
        enforced_ex = dict(ex)
        original_sets = ex.get("sets", 3)
        original_reps = ex.get("reps", 10)

        if isinstance(original_reps, str):
            try:
                if "-" in original_reps:
                    parts = original_reps.split("-")
                    original_reps = int(parts[1].strip())
                else:
                    original_reps = int(original_reps.strip())
            except (ValueError, IndexError):
                original_reps = 10

        try:
            original_sets = int(original_sets)
        except (ValueError, TypeError):
            original_sets = 3

        ex_name_lower = (ex.get("name") or "").lower()
        if exercise_patterns and ex_name_lower in exercise_patterns:
            pattern = exercise_patterns[ex_name_lower]
            suggested_sets = min(max(int(pattern["avg_sets"]), min_sets), max_sets)
            suggested_reps = min(max(int(pattern["avg_reps"]), min_reps), max_reps)

            if min_sets <= suggested_sets <= max_sets:
                enforced_ex["sets"] = suggested_sets
            if min_reps <= suggested_reps <= max_reps:
                enforced_ex["reps"] = suggested_reps

            enforced_ex["weight_source"] = enforced_ex.get("weight_source", "historical")
        else:
            new_sets = min(max(original_sets, min_sets), max_sets)
            new_reps = min(max(original_reps, min_reps), max_reps)

            if new_sets != original_sets or new_reps != original_reps:
                violations_fixed += 1
                logger.warning(
                    f"[Set/Rep Limits] Fixed '{ex.get('name', 'Unknown')}': "
                    f"sets {original_sets}->{new_sets}, reps {original_reps}->{new_reps} "
                    f"(limits: sets {min_sets}-{max_sets}, reps {min_reps}-{max_reps})"
                )

            enforced_ex["sets"] = new_sets
            enforced_ex["reps"] = new_reps

        # Cap per-set target_reps using exercise-type ceiling
        if "set_targets" in enforced_ex and enforced_ex["set_targets"]:
            ex_type = get_exercise_type(enforced_ex.get("name", ""))
            _, type_max_reps = get_rep_limits(ex_type)
            per_set_ceiling = min(max_reps, type_max_reps)
            for st in enforced_ex["set_targets"]:
                if isinstance(st, dict) and "target_reps" in st:
                    if isinstance(st["target_reps"], int) and st["target_reps"] > per_set_ceiling:
                        st["target_reps"] = per_set_ceiling

        enforced_exercises.append(enforced_ex)

    if violations_fixed > 0:
        logger.info(f"[Set/Rep Limits] Fixed {violations_fixed} exercises exceeding user limits")

    return enforced_exercises


def truncate_exercises_to_duration(
    exercises: List[Dict[str, Any]],
    max_duration_minutes: int,
    transition_time_seconds: int = 30
) -> List[Dict[str, Any]]:
    """
    Truncate exercises to fit within the specified duration constraint.

    This is a fallback when Gemini generates a workout that exceeds the time limit.
    """
    if not exercises:
        return exercises

    max_duration_seconds = max_duration_minutes * 60

    def calculate_exercise_duration(exercise: Dict[str, Any]) -> int:
        sets = exercise.get("sets", 3)
        reps = exercise.get("reps", 10)
        rest_seconds = exercise.get("rest_seconds", 60)
        duration_seconds = exercise.get("duration_seconds")

        if duration_seconds:
            return sets * (duration_seconds + rest_seconds)
        else:
            return sets * (reps * 3 + rest_seconds)

    truncated_exercises = []
    cumulative_duration = 0

    for i, exercise in enumerate(exercises):
        exercise_duration = calculate_exercise_duration(exercise)
        transition_time = transition_time_seconds if i > 0 else 0

        if cumulative_duration + exercise_duration + transition_time <= max_duration_seconds:
            truncated_exercises.append(exercise)
            cumulative_duration += exercise_duration + transition_time
        else:
            removed_count = len(exercises) - len(truncated_exercises)
            logger.warning(
                f"⚠️ [Duration Truncate] Removed {removed_count} exercises to fit within "
                f"{max_duration_minutes} min (estimated: {cumulative_duration / 60:.1f} min)"
            )
            break

    return truncated_exercises
