"""
Exercise difficulty scoring, validation, and filtering utilities.

Constants and functions for mapping exercise difficulty to numeric scales,
validating fitness levels, and determining difficulty compatibility.

Phase 2J (Regenerate Workout Safety Fix):
- `enforce_difficulty_ceiling()` is the NEW hard filter. Use this in selection
  pipelines to drop above-ceiling exercises entirely (fail-closed on NULL).
- `is_exercise_too_difficult()` is the LEGACY permissive filter (only blocks
  Elite-10 for beginners) retained for backwards compatibility with the
  in-service RAG loop and existing tests. New callers should prefer
  `enforce_difficulty_ceiling()`.
- `apply_difficulty_scoring()` (in selection_pipeline.py) is DEPRECATED for
  enforcement but kept for ranking. It must only run AFTER the hard filter.
"""
from typing import Any, Dict, List, Optional

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
    """LEGACY permissive filter: only blocks Elite (10) exercises for beginners.

    Retained for backwards compatibility with `service.py`'s in-loop filtering
    and existing tests. For new call sites prefer `enforce_difficulty_ceiling()`
    which applies the full DIFFICULTY_CEILING strictly and fails closed on NULL.

    Returns True iff the exercise should be blocked.
    """
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


# ---------------------------------------------------------------------------
# Phase 2J — hard difficulty ceiling enforcement
# ---------------------------------------------------------------------------

# Ordinal mapping for `safety_difficulty` (the new Phase 3 safety-index column).
# This is separate from the fuzzy 1-10 legacy scale because the safety index
# uses canonical tiers only.
_SAFETY_DIFFICULTY_ORDINAL = {
    "beginner": 3,
    "intermediate": 6,
    "advanced": 8,
    "elite": 10,
}

# Sentinel for "ordinal could not be determined" — fail-closed.
_UNKNOWN_DIFFICULTY_ORDINAL = 99


def _exercise_difficulty_ordinal(exercise: Dict[str, Any]) -> int:
    """Resolve an exercise's effective numeric difficulty for ceiling checks.

    Resolution order (Phase 2J / coordinates with Phase 3K SQL filter):
    1. `safety_difficulty` — the canonical tier from `exercise_safety_index`
       (Phase 3K). If present, it wins.
    2. Legacy `difficulty` — the noisy string/numeric field on
       `exercise_library_cleaned`. Used during the transition period.
    3. Missing/NULL → fail-closed: return a sentinel higher than any ceiling
       so the exercise is dropped even for advanced users. The caller can log
       and escalate to safety-mode curation.

    This matches the intent in the plan's edge case #16:
    "Exercise has NULL difficulty → treated as above-beginner-ceiling;
     excluded from beginner plans."
    """
    if not isinstance(exercise, dict):
        return _UNKNOWN_DIFFICULTY_ORDINAL

    # 1. Prefer safety_difficulty (Phase 3K)
    safety_val = exercise.get("safety_difficulty")
    if safety_val is not None and safety_val != "":
        key = str(safety_val).lower().strip()
        if key in _SAFETY_DIFFICULTY_ORDINAL:
            return _SAFETY_DIFFICULTY_ORDINAL[key]
        # Unrecognized tier string → fail-closed, don't silently downgrade.
        logger.warning(
            f"[Difficulty] Unknown safety_difficulty='{safety_val}' on "
            f"exercise '{exercise.get('name', '<unknown>')}'. Fail-closed."
        )
        return _UNKNOWN_DIFFICULTY_ORDINAL

    # 2. Fall back to legacy `difficulty` column
    legacy_val = exercise.get("difficulty")
    if legacy_val is None or legacy_val == "":
        # Fail-closed: no difficulty metadata at all.
        return _UNKNOWN_DIFFICULTY_ORDINAL

    # Known legacy value → resolve via string/numeric map.
    # get_difficulty_numeric() falls back to 2 for unknown strings, which is
    # NOT fail-closed. So we check explicitly first.
    if isinstance(legacy_val, (int, float)):
        return int(legacy_val)
    key = str(legacy_val).lower().strip()
    if key in DIFFICULTY_STRING_TO_NUM:
        return DIFFICULTY_STRING_TO_NUM[key]

    # Unrecognized legacy string → fail-closed.
    logger.warning(
        f"[Difficulty] Unknown legacy difficulty='{legacy_val}' on "
        f"exercise '{exercise.get('name', '<unknown>')}'. Fail-closed."
    )
    return _UNKNOWN_DIFFICULTY_ORDINAL


def enforce_difficulty_ceiling(
    exercises: List[Dict[str, Any]],
    user_difficulty: str,
    difficulty_adjustment: int = 0,
) -> List[Dict[str, Any]]:
    """HARD FILTER: drop exercises whose difficulty exceeds the user's ceiling.

    This is the Phase 2J replacement for the old "scoring penalty" behavior.
    Above-ceiling exercises are removed entirely so they cannot resurface after
    similarity re-ranking.

    Rules:
    - Strict inequality against `DIFFICULTY_CEILING[user_difficulty]`
      (adjusted by `difficulty_adjustment` per `get_adjusted_difficulty_ceiling`).
    - NULL/missing/unrecognized difficulty → dropped (fail-closed), consistent
      with the plan's edge case handling for NULL difficulty.
    - Prefers the new `safety_difficulty` field (Phase 3K safety index) when
      present; falls back to the legacy `difficulty` column otherwise.

    Args:
        exercises: Candidate exercise dicts. Must be dicts; non-dicts are dropped.
        user_difficulty: User's fitness level string ("beginner"/"intermediate"/
            "advanced"). Normalized via `validate_fitness_level()`.
        difficulty_adjustment: Optional feedback-based adjustment (-2 to +2).

    Returns:
        New list containing only exercises at or below the ceiling. May be
        empty — the caller is responsible for escalation (e.g., safety-mode
        curation in Phase 3K).
    """
    if not exercises:
        return []

    ceiling = get_adjusted_difficulty_ceiling(user_difficulty, difficulty_adjustment)
    validated_level = validate_fitness_level(user_difficulty)

    kept: List[Dict[str, Any]] = []
    dropped_names: List[str] = []

    for ex in exercises:
        ordinal = _exercise_difficulty_ordinal(ex)
        if ordinal > ceiling:
            # Fail-closed: this includes both "elite for beginner" and
            # "NULL difficulty" (ordinal == _UNKNOWN_DIFFICULTY_ORDINAL).
            name = ex.get("name", "<unknown>") if isinstance(ex, dict) else "<non-dict>"
            dropped_names.append(name)
            continue
        kept.append(ex)

    if dropped_names:
        # Truncate the logged names so we don't blow up log lines for large pools.
        sample = dropped_names[:5]
        more = f" (+{len(dropped_names) - len(sample)} more)" if len(dropped_names) > len(sample) else ""
        logger.info(
            f"🏋️ [Difficulty Ceiling] Dropped {len(dropped_names)} of "
            f"{len(exercises)} exercises above ceiling "
            f"(level={validated_level}, ceiling={ceiling}, adjustment={difficulty_adjustment:+d}). "
            f"Examples: {sample}{more}"
        )

    if not kept:
        logger.warning(
            f"⚠️  [Difficulty Ceiling] All {len(exercises)} candidates dropped "
            f"by hard ceiling (level={validated_level}, ceiling={ceiling}). "
            f"Caller must escalate to safety-mode curation."
        )

    return kept
