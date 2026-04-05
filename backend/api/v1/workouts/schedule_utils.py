"""
Schedule and training split utilities.

Handles:
- Training split resolution (dont_know -> auto-pick)
- Focus area mapping for different splits (PPL, upper/lower, bro split, etc.)
- Workout type inference from focus areas
- Workout name deduplication
"""
from typing import List, Optional

from core.logger import get_logger

logger = get_logger(__name__)


def resolve_training_split(split: Optional[str], num_days: int) -> str:
    """
    Resolve 'dont_know' to an actual training split based on workout days.

    When user selects "Don't know" / "Let AI decide", we auto-pick the best
    split based on how many days per week they train.

    Args:
        split: The stored training split (may be 'dont_know')
        num_days: Number of workout days per week

    Returns:
        Resolved split name (never returns 'dont_know')
    """
    if split and split.lower() != "dont_know":
        return split  # Already a specific split

    # Auto-pick based on days per week
    if num_days <= 3:
        return "full_body"  # Most efficient for low frequency
    elif num_days == 4:
        return "upper_lower"  # Classic 4-day split
    elif num_days <= 6:
        return "push_pull_legs"  # PPL for 5-6 days
    else:
        return "full_body"  # 7 days - full body rotation


def infer_workout_type_from_focus(focus_area: str, exercises: List[dict] = None) -> str:
    """
    Infer workout type from focus area for PPL tracking.

    This maps focus areas to workout types so the PPL rotation system
    can track which workout types have been completed.

    Maps:
        - push/chest/shoulders/triceps -> "push"
        - pull/back/biceps -> "pull"
        - legs/lower/glutes/quads/hamstrings -> "legs"
        - full_body* -> "full_body"
        - upper* -> "upper"
        - core/abs -> "core"

    Args:
        focus_area: The focus area string (e.g., "push", "chest", "legs")
        exercises: Optional list of exercises (for future muscle-based inference)

    Returns:
        Workout type string for PPL tracking
    """
    if not focus_area:
        return "strength"

    focus_lower = focus_area.lower().replace(" ", "_").replace("-", "_")

    # Check for full_body variants first (most specific match)
    if "full" in focus_lower and "body" in focus_lower:
        return "full_body"

    # Mapping from focus area keywords to workout types
    type_mapping = {
        # Push muscles
        "push": "push",
        "chest": "push",
        "shoulders": "push",
        "shoulder": "push",
        "triceps": "push",
        "tricep": "push",
        # Pull muscles
        "pull": "pull",
        "back": "pull",
        "biceps": "pull",
        "bicep": "pull",
        "lats": "pull",
        # Leg muscles
        "legs": "legs",
        "leg": "legs",
        "lower": "legs",
        "glutes": "legs",
        "glute": "legs",
        "quads": "legs",
        "quad": "legs",
        "hamstrings": "legs",
        "hamstring": "legs",
        "calves": "legs",
        "calf": "legs",
        # Other types
        "core": "core",
        "abs": "core",
        "abdominals": "core",
        "upper": "upper",
        "arms": "arms",
        "cardio": "cardio",
        "hiit": "cardio",
    }

    for key, workout_type in type_mapping.items():
        if key in focus_lower:
            return workout_type

    # Default to strength if no match found
    return "strength"


def _ensure_no_consecutive_same_focus(focus_map: dict, available_focuses: List[str]) -> dict:
    """Ensure no two adjacent workout days share the same focus.

    Adjacent means weekday numbers that differ by 1 (including 6->0 wrap).
    If duplicates are found, swap with the nearest non-adjacent day that has
    a different focus.
    """
    sorted_days = sorted(focus_map.keys())
    if len(sorted_days) <= 1:
        return focus_map

    result = dict(focus_map)

    def _are_adjacent(day_a: int, day_b: int) -> bool:
        return abs(day_a - day_b) == 1 or {day_a, day_b} == {0, 6}

    # With only 2 days, just ensure they differ if adjacent; no swap candidates exist
    if len(sorted_days) == 2:
        day_a, day_b = sorted_days
        if _are_adjacent(day_a, day_b) and result[day_a] == result[day_b]:
            for alt in available_focuses:
                if alt != result[day_a]:
                    result[day_b] = alt
                    break
        return result

    # Multiple passes to resolve cascading swaps
    for _ in range(len(sorted_days)):
        changed = False
        for idx in range(len(sorted_days) - 1):
            day_a = sorted_days[idx]
            day_b = sorted_days[idx + 1]
            if _are_adjacent(day_a, day_b) and result[day_a] == result[day_b]:
                # Try to swap day_b with a non-adjacent day that has a different focus
                swapped = False
                for swap_idx in range(len(sorted_days)):
                    if swap_idx == idx or swap_idx == idx + 1:
                        continue
                    swap_day = sorted_days[swap_idx]
                    if result[swap_day] != result[day_b]:
                        ok = True
                        for neighbor_idx in [swap_idx - 1, swap_idx + 1]:
                            if 0 <= neighbor_idx < len(sorted_days) and neighbor_idx != idx + 1:
                                neighbor_day = sorted_days[neighbor_idx]
                                if _are_adjacent(swap_day, neighbor_day) and result[day_b] == result[neighbor_day]:
                                    ok = False
                                    break
                        if ok:
                            result[day_b], result[swap_day] = result[swap_day], result[day_b]
                            swapped = True
                            changed = True
                            break
                if not swapped:
                    for alt in available_focuses:
                        if alt != result[day_a]:
                            result[day_b] = alt
                            changed = True
                            break
        # Also check wrap-around (last day -> first day)
        if len(sorted_days) >= 3:
            first_day = sorted_days[0]
            last_day = sorted_days[-1]
            if _are_adjacent(first_day, last_day) and result[first_day] == result[last_day]:
                for alt in available_focuses:
                    if alt != result[first_day] and (alt != result[sorted_days[-2]] if len(sorted_days) > 1 else True):
                        result[last_day] = alt
                        changed = True
                        break
        if not changed:
            break

    return result


def get_workout_focus(split: str, selected_days: List[int], focus_areas: List[str] = None) -> dict:
    """Return workout focus for each day based on training split.

    For full_body split, we rotate through different emphasis areas to ensure variety
    while still targeting the whole body.

    Supported training programs:
    - full_body: 3-4 days, all muscle groups with rotating emphasis
    - upper_lower: 4 days, alternating upper/lower body
    - push_pull_legs: 3-6 days, classic PPL split
    - phul: 4 days, Power Hypertrophy Upper Lower
    - arnold_split: 6 days, chest/back, shoulders/arms, legs
    - hyrox: 4-5 days, hybrid running + functional fitness
    - bro_split: 5-6 days, one muscle group per day
    - body_part: Legacy support for bro split
    - custom: User-defined focus areas (rotates through selected focus_areas)

    Args:
        split: The training split/program type
        selected_days: List of day indices (0=Monday, 6=Sunday)
        focus_areas: Optional list of focus areas for 'custom' split
    """
    num_days = len(selected_days)

    if split == "full_body":
        full_body_emphases = [
            "full_body_push",
            "full_body_pull",
            "full_body_legs",
            "full_body_core",
            "full_body_upper",
            "full_body_lower",
            "full_body_power",
        ]
        return {day: full_body_emphases[i % len(full_body_emphases)] for i, day in enumerate(selected_days)}

    elif split == "upper_lower":
        focuses = ["upper", "lower"] * (num_days // 2 + 1)
        return {day: focuses[i] for i, day in enumerate(selected_days)}

    elif split == "push_pull_legs":
        focuses = ["push", "pull", "legs"] * (num_days // 3 + 1)
        return {day: focuses[i] for i, day in enumerate(selected_days)}

    elif split == "phul":
        phul_focuses = [
            "upper_power",
            "lower_power",
            "upper_hypertrophy",
            "lower_hypertrophy",
        ]
        return {day: phul_focuses[i % len(phul_focuses)] for i, day in enumerate(selected_days)}

    elif split == "arnold_split":
        arnold_focuses = [
            "chest_back",
            "shoulders_arms",
            "legs",
            "chest_back",
            "shoulders_arms",
            "legs",
        ]
        return {day: arnold_focuses[i % len(arnold_focuses)] for i, day in enumerate(selected_days)}

    elif split == "hyrox":
        hyrox_focuses = [
            "hyrox_strength",
            "hyrox_running",
            "hyrox_stations",
            "hyrox_endurance",
            "hyrox_simulation",
        ]
        return {day: hyrox_focuses[i % len(hyrox_focuses)] for i, day in enumerate(selected_days)}

    elif split == "bro_split" or split == "body_part":
        body_parts = [
            "chest",
            "back",
            "shoulders",
            "legs",
            "arms",
            "core_cardio"
        ]
        return {day: body_parts[i % len(body_parts)] for i, day in enumerate(selected_days)}

    elif split == "custom":
        if focus_areas and len(focus_areas) > 0:
            normalized = []
            for fa in focus_areas:
                norm = fa.lower().replace(" ", "_")
                normalized.append(norm)
            return {day: normalized[i % len(normalized)] for i, day in enumerate(selected_days)}
        else:
            logger.warning("Custom split selected but no focus_areas provided, using balanced rotation")
            balanced = ["upper", "lower", "full_body", "push", "pull", "legs"]
            return {day: balanced[i % len(balanced)] for i, day in enumerate(selected_days)}

    elif split == "dont_know" or split is None:
        if num_days <= 3:
            full_body_emphases = [
                "full_body_push",
                "full_body_pull",
                "full_body_legs",
            ]
            focus_map = {day: full_body_emphases[i % len(full_body_emphases)] for i, day in enumerate(selected_days)}
            return _ensure_no_consecutive_same_focus(focus_map, full_body_emphases)
        elif num_days == 4:
            focuses = ["upper", "lower", "upper", "lower"]
            focus_map = {day: focuses[i] for i, day in enumerate(selected_days)}
            return _ensure_no_consecutive_same_focus(focus_map, ["upper", "lower"])
        elif num_days <= 6:
            focuses = ["push", "pull", "legs"] * 2
            focus_map = {day: focuses[i] for i, day in enumerate(selected_days)}
            return _ensure_no_consecutive_same_focus(focus_map, ["push", "pull", "legs"])
        else:
            seven_day_emphases = [
                "full_body_push",
                "full_body_pull",
                "full_body_legs",
                "full_body_core",
                "full_body_upper",
                "full_body_lower",
                "active_recovery",
            ]
            focus_map = {day: seven_day_emphases[i % len(seven_day_emphases)] for i, day in enumerate(selected_days)}
            return _ensure_no_consecutive_same_focus(focus_map, seven_day_emphases)

    # Default to full body with variety if unknown split
    default_emphases = [
        "full_body_push", "full_body_pull", "full_body_legs",
        "full_body_core", "full_body_upper", "full_body_lower", "full_body_power",
    ]
    focus_map = {day: default_emphases[i % len(default_emphases)] for i, day in enumerate(selected_days)}
    return _ensure_no_consecutive_same_focus(focus_map, default_emphases)


def extract_name_words(workout_name: str) -> List[str]:
    """Extract significant words from a workout name."""
    import re
    ignore_words = {'the', 'a', 'an', 'of', 'for', 'and', 'or', 'to', 'workout', 'session'}
    words = re.findall(r'[A-Za-z]{3,}', workout_name.lower())
    return [w for w in words if w not in ignore_words]
