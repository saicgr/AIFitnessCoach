"""
Main orchestrator for ingredient inflammation analysis.

Replaces the Gemini AI-based analysis with a deterministic
database + heuristic approach.
"""

import logging
from typing import Dict, Optional, List

from .parser import parse_ingredients
from .lookup import lookup_ingredient, SOURCE_HEURISTIC
from .scoring import (
    calculate_overall_score,
    score_to_category,
    ingredient_score_to_category,
    calculate_confidence,
)
from .summary import generate_summary, generate_recommendation

logger = logging.getLogger(__name__)


class IngredientDatabaseAnalyzer:
    """
    Deterministic ingredient inflammation analyzer.

    Replaces Gemini AI analysis with:
    1. Parse ingredient text -> list of ingredients
    2. Look up each: static dict -> food_database -> heuristic
    3. Calculate weighted overall score
    4. Generate template-based summary & recommendation
    5. Return dict matching the shape of previous Gemini output
    """

    async def analyze(
        self,
        ingredients_text: str,
        product_name: Optional[str] = None,
    ) -> Dict:
        """
        Analyze ingredients for inflammation properties.

        Never raises exceptions. Always returns a valid result dict.

        Args:
            ingredients_text: Raw ingredient string from food label
            product_name: Optional product name for context

        Returns:
            Dict with keys matching the Gemini output format:
            - overall_score, overall_category, summary, recommendation
            - ingredient_analyses, inflammatory_ingredients,
              anti_inflammatory_ingredients, additives_found
            - analysis_confidence
        """
        try:
            return await self._do_analyze(ingredients_text, product_name)
        except Exception as e:
            logger.error(f"Analysis failed, returning neutral fallback: {e}")
            return self._neutral_fallback(ingredients_text, product_name)

    async def _do_analyze(
        self,
        ingredients_text: str,
        product_name: Optional[str],
    ) -> Dict:
        """Core analysis logic."""
        # 1. Parse ingredients
        ingredients = parse_ingredients(ingredients_text)
        if not ingredients:
            return self._neutral_fallback(ingredients_text, product_name)

        # 2. Look up each ingredient
        ingredient_analyses: List[Dict] = []
        inflammatory_names: List[str] = []
        anti_inflammatory_names: List[str] = []
        additives_found: List[str] = []
        heuristic_count = 0

        for ing_name in ingredients:
            source, record = await lookup_ingredient(ing_name)

            if source == SOURCE_HEURISTIC:
                heuristic_count += 1

            # Determine category for this ingredient
            category = record.category
            # Map overall category names to ingredient category names
            # (overall uses "moderately_inflammatory", ingredients use "inflammatory")
            if category == "moderately_inflammatory":
                category = "inflammatory"

            is_inflammatory = record.score >= 7
            is_anti_inflammatory = record.score <= 4

            analysis = {
                "name": ing_name,
                "category": category,
                "score": record.score,
                "reason": record.reason,
                "is_inflammatory": is_inflammatory,
                "is_additive": record.is_additive,
                "scientific_notes": None,
            }
            ingredient_analyses.append(analysis)

            if is_inflammatory:
                inflammatory_names.append(ing_name)
            if is_anti_inflammatory:
                anti_inflammatory_names.append(ing_name)
            if record.is_additive:
                additives_found.append(ing_name)

        # 3. Calculate overall score
        overall_score_raw = calculate_overall_score(ingredient_analyses)
        overall_score = max(1, min(10, round(overall_score_raw)))
        overall_category = score_to_category(overall_score_raw)

        # 4. Calculate confidence
        confidence = calculate_confidence(
            total_count=len(ingredients),
            unknown_count=heuristic_count,
        )

        # 5. Generate summary and recommendation
        summary = generate_summary(
            category=overall_category,
            inflammatory_names=inflammatory_names,
            anti_inflammatory_names=anti_inflammatory_names,
            product_name=product_name,
        )
        recommendation = generate_recommendation(
            category=overall_category,
            inflammatory_names=inflammatory_names,
            anti_inflammatory_names=anti_inflammatory_names,
            product_name=product_name,
        )

        return {
            "overall_score": overall_score,
            "overall_category": overall_category,
            "summary": summary,
            "recommendation": recommendation,
            "ingredient_analyses": ingredient_analyses,
            "inflammatory_ingredients": inflammatory_names,
            "anti_inflammatory_ingredients": anti_inflammatory_names,
            "additives_found": additives_found,
            "analysis_confidence": confidence,
        }

    def _neutral_fallback(
        self,
        ingredients_text: str,
        product_name: Optional[str],
    ) -> Dict:
        """Return a neutral result when no ingredients could be parsed."""
        return {
            "overall_score": 5,
            "overall_category": "neutral",
            "summary": "Could not fully analyze ingredients. The product has an unknown inflammation profile.",
            "recommendation": "Check the ingredient list manually for common inflammatory triggers like added sugars, hydrogenated oils, and artificial additives.",
            "ingredient_analyses": [],
            "inflammatory_ingredients": [],
            "anti_inflammatory_ingredients": [],
            "additives_found": [],
            "analysis_confidence": 0.5,
        }
