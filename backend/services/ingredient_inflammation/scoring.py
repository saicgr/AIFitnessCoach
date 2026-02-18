"""
Inflammation score calculation and category mapping.

Score convention (matches existing system):
  1-2 = highly anti-inflammatory
  3-4 = anti-inflammatory
  5-6 = neutral
  7-8 = moderately inflammatory
  9-10 = highly inflammatory
"""

from typing import List, Dict


def calculate_overall_score(ingredient_scores: List[Dict]) -> float:
    """
    Calculate weighted overall inflammation score.

    Inflammatory ingredients (score >= 7) get 2x weight to penalize
    products with even a few highly inflammatory ingredients.

    Args:
        ingredient_scores: List of dicts with at least a "score" key (1-10)

    Returns:
        Weighted average score (1.0 - 10.0), or 5.0 if no ingredients
    """
    if not ingredient_scores:
        return 5.0

    total_weight = 0.0
    weighted_sum = 0.0

    for item in ingredient_scores:
        score = item.get("score", 5)
        # Inflammatory ingredients get double weight
        weight = 2.0 if score >= 7 else 1.0
        weighted_sum += score * weight
        total_weight += weight

    if total_weight == 0:
        return 5.0

    return round(weighted_sum / total_weight, 1)


def score_to_category(score: float) -> str:
    """
    Map a numeric score (1-10) to an inflammation category string.

    Returns one of the InflammationCategory enum values.
    """
    if score <= 2.5:
        return "highly_anti_inflammatory"
    elif score <= 4.5:
        return "anti_inflammatory"
    elif score <= 6.5:
        return "neutral"
    elif score <= 8.5:
        return "moderately_inflammatory"
    else:
        return "highly_inflammatory"


def ingredient_score_to_category(score: int) -> str:
    """
    Map an individual ingredient score to its IngredientCategory enum value.

    Categories:
      1-2 -> highly_anti_inflammatory
      3-4 -> anti_inflammatory
      5-6 -> neutral
      7-8 -> inflammatory (maps to "inflammatory" not "moderately_inflammatory")
      9-10 -> highly_inflammatory
    """
    if score <= 2:
        return "highly_anti_inflammatory"
    elif score <= 4:
        return "anti_inflammatory"
    elif score <= 6:
        return "neutral"
    elif score <= 8:
        return "inflammatory"
    else:
        return "highly_inflammatory"


def calculate_confidence(total_count: int, unknown_count: int) -> float:
    """
    Calculate analysis confidence based on how many ingredients were
    found in our database vs. unknown/heuristic-scored.

    Args:
        total_count: Total number of ingredients analyzed
        unknown_count: Number scored by heuristic (not in static DB or food_database)

    Returns:
        Confidence between 0.5 and 0.95
    """
    if total_count == 0:
        return 0.5

    known_ratio = (total_count - unknown_count) / total_count
    # Scale from 0.5 (all unknown) to 0.95 (all known)
    return round(0.5 + (known_ratio * 0.45), 2)
