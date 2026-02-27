"""
Exercise filtering utilities for equipment, injuries, and similarity detection.
"""

import re
import json
from typing import List, Dict, Any, Optional, Set, Tuple

from core.logger import get_logger

logger = get_logger(__name__)


# Default involvement threshold for secondary muscles to trigger AVOID filtering
# Muscles with >20% involvement will be filtered out when the muscle is marked as "avoid"
SECONDARY_MUSCLE_AVOID_THRESHOLD = 0.20

# Penalty multiplier for exercises with secondary muscles in the "reduce" list
SECONDARY_MUSCLE_REDUCE_PENALTY = 0.7

# Penalty multiplier for exercises with primary muscles in the "reduce" list
# Primary muscles get a stronger penalty since they're the main target
PRIMARY_MUSCLE_REDUCE_PENALTY = 0.5


# Full gym equipment list
FULL_GYM_EQUIPMENT = [
    "barbell", "dumbbell", "dumbbells", "cable", "cable machine",
    "machine", "kettlebell", "bench", "ez bar", "smith machine",
    "lat pulldown", "leg press", "pull-up bar", "pullup bar",
    "resistance band", "medicine ball", "slam ball", "stability ball", "trx",
    "body weight", "bodyweight", "none"
]

# Home gym equipment list
HOME_GYM_EQUIPMENT = [
    "dumbbell", "dumbbells", "kettlebell", "resistance band",
    "pull-up bar", "pullup bar", "bench", "stability ball",
    "body weight", "bodyweight", "none"
]

# Injury contraindications mapping
INJURY_CONTRAINDICATIONS = {
    # Leg/Knee injuries
    "leg": ["squat", "lunge", "leg press", "leg extension", "leg curl", "step-up",
            "box jump", "jump squat", "burpee", "mountain climber", "deadlift",
            "romanian deadlift", "calf raise", "hack squat", "pistol squat",
            "leg drive", "split squat", "jump", "hop", "sprint"],
    "knee": ["squat", "lunge", "leg press", "leg extension", "leg curl", "step-up",
             "box jump", "jump squat", "burpee", "mountain climber", "deadlift",
             "pistol squat", "split squat", "jump", "hop"],

    # Back injuries
    "back": ["deadlift", "romanian deadlift", "good morning", "bent-over row",
             "squat", "leg press", "overhead press", "military press",
             "sit-up", "crunch", "superman", "hyperextension", "back extension"],
    "spine": ["deadlift", "romanian deadlift", "good morning", "squat",
              "overhead press", "sit-up", "crunch", "hyperextension"],
    "lower back": ["deadlift", "romanian deadlift", "good morning", "bent-over row",
                   "squat", "leg press", "sit-up", "crunch", "hyperextension",
                   "back extension", "superman"],

    # Shoulder injuries
    "shoulder": ["overhead press", "military press", "arnold press", "shoulder press",
                 "lateral raise", "upright row", "behind neck", "dip", "bench press",
                 "incline press", "fly", "pullover"],
    "rotator": ["overhead press", "lateral raise", "upright row", "behind neck",
                "dip", "fly", "pullover"],

    # Wrist/Hand injuries
    "wrist": ["push-up", "pushup", "plank", "handstand", "clean", "snatch",
              "front squat", "overhead squat", "bench press"],
    "hand": ["push-up", "pushup", "plank", "handstand", "clean", "deadlift"],

    # Hip injuries
    "hip": ["squat", "lunge", "hip thrust", "leg press", "deadlift", "step-up",
            "glute bridge", "romanian deadlift", "sumo deadlift"],

    # Neck injuries
    "neck": ["shrug", "upright row", "sit-up", "crunch", "neck curl",
             "neck extension", "behind neck press"],

    # Elbow/Arm injuries
    "elbow": ["curl", "tricep extension", "skull crusher", "close grip",
              "diamond push-up", "dip"],
    "arm": ["curl", "tricep extension", "skull crusher", "overhead extension"],

    # Ankle injuries
    "ankle": ["calf raise", "jump", "hop", "skip", "run", "sprint",
              "box jump", "jump squat", "burpee", "lunge"],
}


# Movement patterns for detecting similar exercises within the same movement category
# This prevents workouts like "6 push-up variations" by grouping similar movements
# NOTE: Order matters! More specific patterns should come first to avoid false matches.
# Each keyword list is ordered from most specific to least specific.
MOVEMENT_PATTERNS = {
    # Pull vertical - check first to catch chin-ups and pulldowns before "row" pattern
    "pull_vertical": ["pull up", "pull-up", "pullup", "chin up", "chin-up", "chinup", "pulldown", "lat pulldown"],
    # Pull horizontal - rows
    "pull_horizontal": ["barbell row", "dumbbell row", "cable row", "seated row", "bent over row", "t-bar row", "pendlay row"],
    # Push horizontal
    "push_horizontal": ["push up", "push-up", "pushup", "bench press", "chest press", "dip", "fly", "flye", "pec deck"],
    # Push vertical
    "push_vertical": ["overhead press", "shoulder press", "military press", "arnold press", "lateral raise", "front raise"],
    # Squat
    "squat": ["squat", "goblet squat", "front squat", "back squat", "hack squat", "sissy squat", "split squat"],
    # Hinge
    "hinge": ["deadlift", "rdl", "romanian deadlift", "hip hinge", "good morning", "stiff leg"],
    # Lunge
    "lunge": ["lunge", "reverse lunge", "walking lunge", "step up", "step-up", "bulgarian"],
    # Curl - bicep isolation
    "curl": ["bicep curl", "hammer curl", "preacher curl", "concentration curl", "ez bar curl", "incline curl"],
    # Tricep - tricep isolation
    "tricep": ["tricep extension", "tricep pushdown", "skull crusher", "overhead extension", "kickback", "close grip"],
    # Core flexion
    "core_flexion": ["crunch", "sit up", "sit-up", "situp", "leg raise", "knee raise", "v-up"],
    # Core stability
    "core_stability": ["plank", "dead bug", "hollow hold", "bird dog", "pallof"],
}


def get_movement_pattern(exercise_name: str) -> Optional[str]:
    """
    Extract the movement pattern category from an exercise name.

    This helps detect similar exercises that belong to the same movement pattern,
    even if their names don't directly overlap.

    Examples:
        "Push Up" -> "push_horizontal"
        "Diamond Push-Up" -> "push_horizontal"
        "Barbell Row" -> "pull_horizontal"
        "Bicep Curl" -> "curl"

    Args:
        exercise_name: The exercise name

    Returns:
        The movement pattern category, or None if not recognized
    """
    name_lower = exercise_name.lower()
    for pattern, keywords in MOVEMENT_PATTERNS.items():
        for keyword in keywords:
            if keyword in name_lower:
                return pattern
    return None


def get_base_exercise_name(name: str) -> str:
    """
    Extract the normalized base exercise name for deduplication.

    Removes version suffixes, gender variants, and normalizes the name.

    Examples:
        "Push-up (version 2)" -> "push up"
        "Squat variation 3" -> "squat"
        "Air Bike_female" -> "air bike"

    Args:
        name: The exercise name

    Returns:
        Normalized base name for comparison
    """
    # Lowercase for comparison
    name = name.lower()

    # Remove "_female" or "_Female" suffix
    name = re.sub(r'[_\s]female$', '', name, flags=re.IGNORECASE)

    # Remove "(version X)" suffix
    name = re.sub(r'\s*\(version\s*\d+\)\s*', '', name, flags=re.IGNORECASE)

    # Remove "version X" suffix without parentheses
    name = re.sub(r'\s+version\s*\d+\s*', '', name, flags=re.IGNORECASE)

    # Remove "variation X" suffix
    name = re.sub(r'\s*\(variation\s*\d+\)\s*', '', name, flags=re.IGNORECASE)
    name = re.sub(r'\s+variation\s*\d+\s*', '', name, flags=re.IGNORECASE)

    # Remove "v2", "v3" etc suffix
    name = re.sub(r'\s+v\d+\s*', '', name, flags=re.IGNORECASE)

    # Remove common filler words
    filler_words = ['with', 'and', 'the', 'a', 'an', 'on', 'in', 'to', 'for']
    words = name.split()
    words = [w for w in words if w not in filler_words]
    name = ' '.join(words)

    # Normalize hyphens, underscores and multiple spaces
    name = name.replace('-', ' ')
    name = name.replace('_', ' ')
    name = re.sub(r'\s+', ' ', name)

    return name.strip()


def is_similar_exercise(name1: str, name2: str, check_movement_pattern: bool = True) -> bool:
    """
    Check if two exercise names are similar enough to be considered duplicates.

    Uses multiple strategies to detect similar exercises:
    1. Exact match after normalization
    2. Word overlap analysis
    3. Movement pattern matching (e.g., "Push Up" and "Diamond Push-Up" are both push_horizontal)

    Args:
        name1: First exercise name
        name2: Second exercise name
        check_movement_pattern: If True, also checks if exercises share the same movement pattern

    Returns:
        True if exercises are similar
    """
    base1 = get_base_exercise_name(name1)
    base2 = get_base_exercise_name(name2)

    # Exact match after normalization
    if base1 == base2:
        return True

    # Check word overlap
    words1 = set(base1.split())
    words2 = set(base2.split())

    # If smaller set is fully contained in larger set
    if words1.issubset(words2) or words2.issubset(words1):
        return True

    # High overlap (80%+ of smaller set matches)
    smaller = words1 if len(words1) < len(words2) else words2
    larger = words2 if len(words1) < len(words2) else words1
    overlap = len(smaller & larger)
    if len(smaller) > 0 and overlap / len(smaller) >= 0.8:
        return True

    # Check movement pattern similarity
    # This catches cases like "Push Up" vs "Decline Diamond Pike Push-Up"
    # Both are in the "push_horizontal" pattern
    if check_movement_pattern:
        pattern1 = get_movement_pattern(name1)
        pattern2 = get_movement_pattern(name2)
        if pattern1 and pattern2 and pattern1 == pattern2:
            return True

    return False


def count_movement_patterns(exercises: List[Dict]) -> Dict[str, int]:
    """
    Count exercises per movement pattern.

    This helps identify workouts with too many exercises of the same pattern
    (e.g., 6 push-up variations).

    Args:
        exercises: List of exercise dictionaries with 'name' or 'exercise_name' key

    Returns:
        Dictionary mapping pattern names to exercise counts
    """
    pattern_counts = {}
    for ex in exercises:
        name = ex.get("name", "") or ex.get("exercise_name", "")
        pattern = get_movement_pattern(name)
        if pattern:
            pattern_counts[pattern] = pattern_counts.get(pattern, 0) + 1
    return pattern_counts


def filter_by_equipment(
    ex_equipment: str,
    user_equipment: List[str],
    exercise_name: str,
) -> bool:
    """
    Check if exercise equipment matches user's available equipment.

    Args:
        ex_equipment: Exercise's required equipment
        user_equipment: User's available equipment
        exercise_name: Exercise name (for additional matching)

    Returns:
        True if exercise is compatible with user's equipment
    """
    equipment_lower = [eq.lower() for eq in user_equipment]

    # Expand general equipment options (use 'any' to match partial strings)
    # Handle both 'full_gym' (app storage format) and 'full gym' (display format)
    if any("full_gym" in eq or "full gym" in eq for eq in equipment_lower):
        equipment_lower = FULL_GYM_EQUIPMENT
    elif any("home_gym" in eq or "home gym" in eq for eq in equipment_lower):
        equipment_lower = HOME_GYM_EQUIPMENT
    elif any("bodyweight only" in eq or "bodyweight_only" in eq for eq in equipment_lower):
        equipment_lower = ["body weight", "bodyweight", "none"]
    else:
        # Always include bodyweight as an option
        equipment_lower = equipment_lower + ["body weight", "bodyweight", "none"]

    ex_equipment_lower = ex_equipment.lower() if ex_equipment else ""

    # Check if exercise equipment matches user's equipment
    # Use word-based matching to avoid false positives like "bar" matching "barbell"
    equipment_match = False
    for eq in equipment_lower:
        if not eq or not ex_equipment_lower:
            continue
        # Exact match
        if eq == ex_equipment_lower:
            equipment_match = True
            break
        # Word-based matching: check if equipment is a complete word in the exercise equipment
        # This prevents "bar" from matching "barbell" but allows "dumbbell" to match "dumbbell"
        ex_words = set(ex_equipment_lower.replace("-", " ").replace("_", " ").split())
        eq_words = set(eq.replace("-", " ").replace("_", " ").split())
        # Match if all words in user equipment are found in exercise equipment
        if eq_words and eq_words.issubset(ex_words):
            equipment_match = True
            break
        # Also match if exercise equipment is a single word that matches any user equipment word
        if len(ex_words) == 1 and ex_words.issubset(eq_words):
            equipment_match = True
            break

    if not equipment_match:
        # Also check exercise name for equipment clues (word-based)
        exercise_name_lower = exercise_name.lower() if exercise_name else ""
        exercise_words = set(exercise_name_lower.replace("-", " ").replace("_", " ").split())
        for eq in equipment_lower:
            if not eq:
                continue
            eq_words = set(eq.replace("-", " ").replace("_", " ").split())
            # Check if equipment words appear in exercise name
            if eq_words and eq_words.issubset(exercise_words):
                equipment_match = True
                break

    return equipment_match


def pre_filter_by_injuries(
    candidates: List[Dict],
    injuries: List[str],
) -> List[Dict]:
    """
    Pre-filter exercises that are contraindicated for user's injuries.

    This is a safety net to catch dangerous exercises before AI selection.

    Args:
        candidates: List of exercise candidates
        injuries: List of user's injuries

    Returns:
        Filtered list of safe candidates
    """
    # Determine which injury categories apply
    active_patterns: Set[str] = set()
    injuries_lower = [inj.lower() for inj in injuries]

    for injury in injuries_lower:
        for key, patterns in INJURY_CONTRAINDICATIONS.items():
            if key in injury:
                active_patterns.update(patterns)

    if not active_patterns:
        logger.info("No specific contraindication patterns found for injuries")
        return candidates

    logger.info(f"Filtering out exercises matching: {active_patterns}")

    # Filter candidates
    safe_candidates = []
    for candidate in candidates:
        exercise_name = candidate.get("name", "").lower()
        target_muscle = candidate.get("target_muscle", "").lower()
        body_part = candidate.get("body_part", "").lower()

        # Check if exercise matches any contraindicated pattern
        is_unsafe = False
        for pattern in active_patterns:
            if pattern in exercise_name or pattern in target_muscle or pattern in body_part:
                logger.debug(f"Filtering out '{candidate.get('name')}' (matches '{pattern}')")
                is_unsafe = True
                break

        if not is_unsafe:
            safe_candidates.append(candidate)

    return safe_candidates


def parse_secondary_muscles(secondary_muscles_raw: Any) -> List[Dict[str, Any]]:
    """
    Parse secondary muscles from various formats into a list of dicts.

    The secondary_muscles field may be:
    - A JSON string like '["biceps", "forearms"]' (simple list)
    - A JSON string like '[{"muscle": "biceps", "involvement": 0.3}]' (with involvement)
    - An already-parsed list
    - A comma-separated string like "biceps, forearms"
    - None or empty

    Returns:
        List of dicts with 'muscle' and 'involvement' keys.
        If involvement is not specified, defaults to 0.3 (30%).
    """
    DEFAULT_INVOLVEMENT = 0.30

    if not secondary_muscles_raw:
        return []

    # Already a list
    if isinstance(secondary_muscles_raw, list):
        result = []
        for item in secondary_muscles_raw:
            if isinstance(item, dict):
                result.append({
                    "muscle": str(item.get("muscle", "")).lower().strip(),
                    "involvement": float(item.get("involvement", DEFAULT_INVOLVEMENT))
                })
            elif isinstance(item, str):
                result.append({
                    "muscle": item.lower().strip(),
                    "involvement": DEFAULT_INVOLVEMENT
                })
        return [r for r in result if r["muscle"]]  # Filter out empty muscles

    # JSON string
    if isinstance(secondary_muscles_raw, str):
        secondary_muscles_raw = secondary_muscles_raw.strip()

        # Try to parse as JSON
        if secondary_muscles_raw.startswith("["):
            try:
                parsed = json.loads(secondary_muscles_raw)
                # Recursively handle the parsed list
                return parse_secondary_muscles(parsed)
            except json.JSONDecodeError as e:
                logger.debug(f"Failed to parse muscles JSON: {e}")

        # Handle comma-separated string
        if "," in secondary_muscles_raw:
            muscles = [m.strip().lower() for m in secondary_muscles_raw.split(",")]
            return [{"muscle": m, "involvement": DEFAULT_INVOLVEMENT} for m in muscles if m]

        # Single muscle name
        if secondary_muscles_raw:
            return [{"muscle": secondary_muscles_raw.lower(), "involvement": DEFAULT_INVOLVEMENT}]

    return []


def check_secondary_muscles_for_avoided(
    secondary_muscles: List[Dict[str, Any]],
    avoided_muscles: List[str],
    threshold: float = SECONDARY_MUSCLE_AVOID_THRESHOLD,
) -> Tuple[bool, Optional[str]]:
    """
    Check if any secondary muscle with significant involvement is in the avoided list.

    Args:
        secondary_muscles: Parsed list of secondary muscles with involvement
        avoided_muscles: List of muscle names to avoid (lowercase)
        threshold: Minimum involvement percentage to trigger avoidance (default 0.20 = 20%)

    Returns:
        Tuple of (should_filter, matched_muscle).
        - should_filter: True if the exercise should be filtered out
        - matched_muscle: The name of the avoided muscle that was matched (for logging)
    """
    for muscle_info in secondary_muscles:
        muscle_name = muscle_info.get("muscle", "").lower()
        involvement = muscle_info.get("involvement", 0.30)

        # Skip muscles with low involvement
        if involvement <= threshold:
            continue

        for avoided in avoided_muscles:
            if avoided in muscle_name or muscle_name in avoided:
                return True, muscle_name

    return False, None


def check_secondary_muscles_for_reduced(
    secondary_muscles: List[Dict[str, Any]],
    reduced_muscles: List[str],
) -> Tuple[bool, Optional[str], float]:
    """
    Check if any secondary muscle is in the reduced list and calculate penalty.

    Args:
        secondary_muscles: Parsed list of secondary muscles with involvement
        reduced_muscles: List of muscle names to reduce (lowercase)

    Returns:
        Tuple of (should_penalize, matched_muscle, penalty_factor).
        - should_penalize: True if the exercise should be penalized
        - matched_muscle: The name of the reduced muscle that was matched
        - penalty_factor: The penalty multiplier to apply (based on involvement)
    """
    for muscle_info in secondary_muscles:
        muscle_name = muscle_info.get("muscle", "").lower()
        involvement = muscle_info.get("involvement", 0.30)

        for reduced in reduced_muscles:
            if reduced in muscle_name or muscle_name in reduced:
                # Calculate penalty based on involvement
                # Higher involvement = stronger penalty
                # involvement=0.5 -> penalty=0.75 (25% reduction)
                # involvement=0.3 -> penalty=0.85 (15% reduction)
                penalty = 1.0 - (involvement * 0.5)
                return True, muscle_name, penalty

    return False, None, 1.0


def filter_by_avoided_muscles(
    candidates: List[Dict],
    avoided_muscles: Dict[str, List[str]],
) -> Tuple[List[Dict], int, int]:
    """
    Filter exercises based on avoided muscles, including secondary muscles.

    This function filters out exercises that:
    1. Have a primary target muscle in the "avoid" list
    2. Have a body_part matching an "avoid" muscle
    3. Have secondary muscles with >20% involvement in the "avoid" list

    For "reduce" muscles, it applies a penalty to similarity scores instead of filtering.

    Args:
        candidates: List of exercise candidates
        avoided_muscles: Dict with 'avoid' and 'reduce' lists

    Returns:
        Tuple of (filtered_candidates, primary_filtered_count, secondary_filtered_count)
    """
    avoid_muscles_list = [m.lower() for m in avoided_muscles.get("avoid", [])]
    reduce_muscles_list = [m.lower() for m in avoided_muscles.get("reduce", [])]

    if not avoid_muscles_list and not reduce_muscles_list:
        return candidates, 0, 0

    filtered_candidates = []
    primary_filtered_count = 0
    secondary_filtered_count = 0

    for candidate in candidates:
        target_muscle = (candidate.get("target_muscle") or "").lower()
        body_part = (candidate.get("body_part") or "").lower()
        secondary_muscles_raw = candidate.get("secondary_muscles", [])

        # Parse secondary muscles
        secondary_muscles = parse_secondary_muscles(secondary_muscles_raw)

        should_filter = False
        filter_reason = None

        if avoid_muscles_list:
            # Check primary muscle and body part
            for avoided in avoid_muscles_list:
                if avoided in target_muscle or avoided in body_part:
                    should_filter = True
                    filter_reason = f"primary muscle: {avoided}"
                    primary_filtered_count += 1
                    break

            # Check secondary muscles if not already filtered
            if not should_filter and secondary_muscles:
                should_filter, matched_muscle = check_secondary_muscles_for_avoided(
                    secondary_muscles, avoid_muscles_list
                )
                if should_filter:
                    filter_reason = f"secondary muscle: {matched_muscle} (>20% involvement)"
                    secondary_filtered_count += 1

        if should_filter:
            logger.debug(f"Filtered out '{candidate.get('name')}' - targets avoided {filter_reason}")
            continue

        # Apply reduce penalties (don't filter, just penalize)
        if reduce_muscles_list:
            # Check primary muscle and body part
            primary_reduced = False
            for reduced in reduce_muscles_list:
                if reduced in target_muscle or reduced in body_part:
                    original_sim = candidate.get("similarity", 1.0)
                    candidate["similarity"] = original_sim * PRIMARY_MUSCLE_REDUCE_PENALTY
                    candidate["reduced_muscle_penalty"] = True
                    candidate["reduced_muscle_reason"] = f"primary: {reduced}"
                    primary_reduced = True
                    logger.debug(f"Reduced priority for '{candidate.get('name')}' - targets reduced muscle: {reduced} (penalty={PRIMARY_MUSCLE_REDUCE_PENALTY})")
                    break

            # Check secondary muscles if primary wasn't reduced
            if not primary_reduced and secondary_muscles:
                should_penalize, matched_muscle, penalty = check_secondary_muscles_for_reduced(
                    secondary_muscles, reduce_muscles_list
                )
                if should_penalize:
                    original_sim = candidate.get("similarity", 1.0)
                    candidate["similarity"] = original_sim * penalty
                    candidate["reduced_muscle_penalty"] = True
                    candidate["reduced_muscle_reason"] = f"secondary: {matched_muscle}"
                    logger.debug(
                        f"Reduced priority for '{candidate.get('name')}' - "
                        f"secondary muscle: {matched_muscle} (penalty={penalty:.2f})"
                    )

        filtered_candidates.append(candidate)

    return filtered_candidates, primary_filtered_count, secondary_filtered_count
