"""
Ingredient Inflammation Analysis Package.

Deterministic ingredient-based inflammation scoring using a curated
static database, food_database fallback, and heuristic rules.
Replaces the previous Gemini AI-based analysis.
"""

from .analyzer import IngredientDatabaseAnalyzer
from .parser import parse_ingredients
from .lookup import lookup_ingredient
from .scoring import calculate_overall_score, score_to_category, calculate_confidence
from .summary import generate_summary, generate_recommendation

__all__ = [
    "IngredientDatabaseAnalyzer",
    "parse_ingredients",
    "lookup_ingredient",
    "calculate_overall_score",
    "score_to_category",
    "calculate_confidence",
    "generate_summary",
    "generate_recommendation",
]
