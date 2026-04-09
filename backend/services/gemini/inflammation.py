"""
Gemini Service Inflammation Analysis.
"""
import asyncio
import json
import logging
import time
from typing import Dict, Optional

from google.genai import types
from core.config import get_settings
from models.gemini_schemas import InflammationAnalysisGeminiResponse
from services.gemini.constants import (
    client, _log_token_usage, settings, gemini_generate_with_retry,
)

logger = logging.getLogger("gemini")


class InflammationMixin:
    """Mixin providing inflammation analysis methods for GeminiService."""

    async def analyze_ingredient_inflammation(
        self,
        ingredients_text: str,
        product_name: Optional[str] = None,
    ) -> Optional[Dict]:
        """
        Analyze ingredients for inflammatory properties using Gemini AI.

        Args:
            ingredients_text: Raw ingredients list from Open Food Facts
            product_name: Optional product name for context

        Returns:
            Dictionary with overall_score, category, ingredient_analyses, etc.
        """
        product_context = f"Product: {product_name}\n" if product_name else ""

        prompt = f'''You are a nutrition scientist specializing in inflammation and food science. Analyze the following ingredients list and determine the inflammatory properties of each ingredient and the product overall.

{product_context}Ingredients: {ingredients_text}

INFLAMMATION SCORING CRITERIA (1 = lowest inflammation/healthiest, 10 = highest inflammation/unhealthiest):

EXCELLENT - LOW INFLAMMATION (Score 1-2):
- Pure water, mineral water, sparkling water (essential for hydration, zero inflammatory properties)
- Turmeric/curcumin
- Omega-3 rich foods (fish oil, flaxseed)
- Green leafy vegetables
- Berries (blueberries, strawberries)
- Ginger, garlic
- Green tea extract

GOOD - ANTI-INFLAMMATORY (Score 3-4):
- Whole grains (oats, quinoa, brown rice)
- Legumes, beans
- Many vegetables and fruits
- Olive oil, avocado oil
- Nuts and seeds
- Natural herbs and spices

NEUTRAL (Score 5-6):
- Salt in moderate amounts
- Natural flavors (depends on source)
- Many starches
- Unprocessed ingredients with no known inflammatory effect

POOR - MODERATELY INFLAMMATORY (Score 7-8):
- Excessive saturated fats from processed meats
- Refined grains (some white rice, white bread ingredients)
- Excessive sodium compounds
- Some preservatives (sodium benzoate, potassium sorbate)
- Conventional dairy in excess

VERY POOR - HIGHLY INFLAMMATORY (Score 9-10):
- Refined sugars, high-fructose corn syrup
- Trans fats, partially hydrogenated oils
- Heavily processed seed/vegetable oils (soybean oil, corn oil, canola oil)
- Artificial sweeteners (aspartame, sucralose)
- MSG, artificial colors, artificial preservatives
- Refined carbohydrates, white flour

Return ONLY valid JSON in this exact format (no markdown, no explanation):
{{
  "overall_score": 5,
  "overall_category": "neutral",
  "summary": "Plain language summary of the product's inflammatory profile in 1-2 sentences.",
  "recommendation": "Brief actionable recommendation for the consumer.",
  "analysis_confidence": 0.85,
  "ingredient_analyses": [
    {{
      "name": "ingredient name",
      "category": "inflammatory|anti_inflammatory|neutral|additive|unknown",
      "score": 5,
      "reason": "Brief explanation why this ingredient has this score",
      "is_inflammatory": false,
      "is_additive": false,
      "scientific_notes": null
    }}
  ],
  "inflammatory_ingredients": ["ingredient1", "ingredient2"],
  "anti_inflammatory_ingredients": ["ingredient3", "ingredient4"],
  "additives_found": ["additive1", "additive2"]
}}

IMPORTANT RULES:
1. Score each ingredient individually from 1-10 (1=healthiest/lowest inflammation, 10=unhealthiest/highest inflammation)
2. Calculate overall_score as a weighted average (inflammatory ingredients weigh more heavily)
3. overall_category must be one of: highly_inflammatory, moderately_inflammatory, neutral, anti_inflammatory, highly_anti_inflammatory
4. is_inflammatory = true if score >= 7
5. is_additive = true for preservatives, colorings, emulsifiers, stabilizers
6. Keep the summary consumer-friendly, avoid jargon
7. If you cannot identify an ingredient, use category "unknown" with score 5
8. List ALL inflammatory ingredients (score 7-10) in inflammatory_ingredients
9. List ALL anti-inflammatory ingredients (score 1-4) in anti_inflammatory_ingredients
10. List ALL additives/preservatives in additives_found'''

        try:
            logger.info(f"[Gemini] Analyzing ingredient inflammation for: {product_name or 'Unknown product'}")
            try:
                response = await gemini_generate_with_retry(
                    model=self.model,
                    contents=prompt,
                    config=types.GenerateContentConfig(
                        response_mime_type="application/json",
                        response_schema=InflammationAnalysisGeminiResponse,
                        max_output_tokens=4000,
                        temperature=0.2,  # Low temperature for consistent classification
                    ),
                    timeout=30,  # 30s for inflammation analysis
                    method_name="analyze_inflammation",
                )
            except asyncio.TimeoutError:
                logger.error("[Inflammation] Gemini API timed out after 30s", exc_info=True)
                return None

            # Use response.parsed for structured output - SDK handles JSON parsing
            parsed = response.parsed
            if not parsed:
                logger.warning("[Gemini] Empty response from inflammation analysis")
                return None

            result = parsed.model_dump()

            # Validate and fix overall_category
            valid_categories = [
                "highly_inflammatory", "moderately_inflammatory",
                "neutral", "anti_inflammatory", "highly_anti_inflammatory"
            ]
            if result.get("overall_category") not in valid_categories:
                # Derive from score (1=healthiest, 10=most inflammatory)
                score = result.get("overall_score", 5)
                if score <= 2:
                    result["overall_category"] = "highly_anti_inflammatory"
                elif score <= 4:
                    result["overall_category"] = "anti_inflammatory"
                elif score <= 6:
                    result["overall_category"] = "neutral"
                elif score <= 8:
                    result["overall_category"] = "moderately_inflammatory"
                else:
                    result["overall_category"] = "highly_inflammatory"

            # Ensure required fields exist
            result.setdefault("ingredient_analyses", [])
            result.setdefault("inflammatory_ingredients", [])
            result.setdefault("anti_inflammatory_ingredients", [])
            result.setdefault("additives_found", [])
            result.setdefault("summary", "Analysis complete.")
            result.setdefault("recommendation", None)
            result.setdefault("analysis_confidence", 0.8)

            logger.info(f"[Gemini] Inflammation analysis complete: score={result.get('overall_score')}, category={result.get('overall_category')}")
            return result

        except Exception as e:
            logger.error(f"[Gemini] Ingredient inflammation analysis failed: {e}", exc_info=True)
            logger.exception("Full traceback:")
            return None
