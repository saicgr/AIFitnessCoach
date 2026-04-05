"""
Exercise difficulty scoring, validation, and filtering utilities.

Constants and functions for mapping exercise difficulty to numeric scales,
validating fitness levels, and determining difficulty compatibility.
"""
from typing import Optional

from core.logger import get_logger

logger = get_logger(__name__)

# Difficulty ceiling by fitness level (prevents advanced exercises for beginners)
DIFFICULTY_CEILING = {
    "beginner": 6,
    "intermediate": 8,
    "advanced": 10,
}

# Challenge exercise difficulty range for beginners
CHALLENGE_DIFFICULTY_RANGE = {
    "min": 7,
    "max": 8,
}

# Difficulty preference ratios for workout generation
DIFFICULTY_RATIOS = {
    "beginner": {"beginner": 0.60, "intermediate": 0.30, "advanced": 0.10},
    "intermediate": {"beginner": 0.25, "intermediate": 0.50, "advanced": 0.25},
    "advanced": {"beginner": 0.15, "intermediate": 0.35, "advanced": 0.50},
}

# Map difficulty string values to numeric scale (1-10)
DIFFICULTY_STRING_TO_NUM = {
    "beginner": 2, "easy": 2, "novice": 2,
    "intermediate": 5, "medium": 5, "moderate": 5,
    "advanced": 8, "hard": 8,
    "expert": 9, "elite": 10,
}

VALID_FITNESS_LEVELS = {"beginner", "intermediate", "advanced"}
DEFAULT_FITNESS_LEVEL = "intermediate"

# Exercises that require a flat bench
_BENCH_REQUIRED_PATTERNS = frozenset([
    "pullover", "pull over", "bench press", "incline press",
    "incline dumbbell", "decline press", "decline dumbbell",
    "chest supported", "preacher", "tate press", "jm press",
    "lying tricep", "lying extension",
])

# Exercises that require a squat rack / power rack
_SQUAT_RACK_REQUIRED_PATTERNS = frozenset([
    "barbell squat", "back squat", "front squat",
    "barbell overhead press", "barbell bench press",
])


def _needs_bench(name: str) -> bool:
    """Returns True if exercise name implies a bench is required."""
    n = name.lower()
    if "cable" in n or "machine" in n or "pulldown" in n:
        return False
    if "on floor" in n or "on exercise ball" in n or "floor press" in n:
        return False
    return any(p in n for p in _BENCH_REQUIRED_PATTERNS)


def validate_fitness_level(fitness_level: Optional[str]) -> str:
    """Validate and normalize fitness level, returning a safe default if invalid."""
    if not fitness_level:
        logger.debug(f"[Fitness Level] No fitness level provided, defaulting to {DEFAULT_FITNESS_LEVEL}")
        return DEFAULT_FITNESS_LEVEL

    normalized = str(fitness_level).lower().strip()

    if normalized not in VALID_FITNESS_LEVELS:
        logger.warning(
            f"[Fitness Level] Invalid fitness level '{fitness_level}', "
            f"defaulting to {DEFAULT_FITNESS_LEVEL}. Valid values: {VALID_FITNESS_LEVELS}"
        )
        return DEFAULT_FITNESS_LEVEL

    return normalized


def get_difficulty_numeric(difficulty_value) -> int:
    """Convert difficulty value to numeric scale (1-10)."""
    if difficulty_value is None:
        return 2
    if isinstance(difficulty_value, (int, float)):
        return int(difficulty_value)
    difficulty_str = str(difficulty_value).lower().strip()
    return DIFFICULTY_STRING_TO_NUM.get(difficulty_str, 2)


def get_adjusted_difficulty_ceiling(
    user_fitness_level: str,
    difficulty_adjustment: int = 0,
) -> int:
    """Get the difficulty ceiling adjusted by user feedback (-2 to +2)."""
    validated_level = validate_fitness_level(user_fitness_level)
    base_ceiling = DIFFICULTY_CEILING.get(validated_level, 6)
    adjusted_ceiling = max(1, min(10, base_ceiling + difficulty_adjustment))

    if difficulty_adjustment != 0:
        logger.info(
            f"[Difficulty Adjustment] fitness_level={validated_level}, "
            f"base_ceiling={base_ceiling}, adjustment={difficulty_adjustment:+d}, "
            f"adjusted_ceiling={adjusted_ceiling}"
        )

    return adjusted_ceiling


def get_exercise_difficulty_category(exercise_difficulty) -> str:
    """Get the difficulty category for an exercise: beginner/intermediate/advanced."""
    difficulty_num = get_difficulty_numeric(exercise_difficulty)
    if difficulty_num <= 3:
        return "beginner"
    elif difficulty_num <= 6:
        return "intermediate"
    else:
        return "advanced"


def get_difficulty_score(
    exercise_difficulty,
    user_fitness_level: str,
    difficulty_adjustment: int = 0,
) -> float:
    """Calculate a difficulty compatibility score (0.0 to 1.0) for ranking."""
    validated_level = validate_fitness_level(user_fitness_level)
    exercise_category = get_exercise_difficulty_category(exercise_difficulty)
    ratios = DIFFICULTY_RATIOS.get(validated_level, DIFFICULTY_RATIOS["intermediate"])
    base_score = ratios.get(exercise_category, 0.25)

    if difficulty_adjustment > 0 and exercise_category in ["intermediate", "advanced"]:
        base_score = min(1.0, base_score + 0.1 * difficulty_adjustment)
    elif difficulty_adjustment < 0 and exercise_category in ["beginner", "intermediate"]:
        base_score = min(1.0, base_score + 0.1 * abs(difficulty_adjustment))

    return base_score


def is_exercise_too_difficult(
    exercise_difficulty,
    user_fitness_level: str,
    difficulty_adjustment: int = 0,
) -> bool:
    """Check if an exercise is too difficult (only filters Elite 10 for beginners)."""
    exercise_difficulty_num = get_difficulty_numeric(exercise_difficulty)
    validated_level = validate_fitness_level(user_fitness_level)

    if validated_level == "beginner" and difficulty_adjustment <= 0:
        if exercise_difficulty_num >= 10:
            return True

    return False


def is_exercise_too_difficult_strict(
    exercise_difficulty,
    user_fitness_level: str,
    difficulty_adjustment: int = 0,
) -> bool:
    """STRICT version: Check if exercise exceeds user's difficulty ceiling."""
    max_difficulty = get_adjusted_difficulty_ceiling(user_fitness_level, difficulty_adjustment)
    exercise_difficulty_num = get_difficulty_numeric(exercise_difficulty)
    return exercise_difficulty_num > max_difficulty
