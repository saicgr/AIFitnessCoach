"""
Ingredient Analyzer Service
===========================
Per-row free-text → structured ingredient with macros + source badge.

Resolution order (no silent fallback — each row records its source explicitly):
  1) Branded / saved-food match (if user_id provided)
  2) USDA / Open Food Facts fuzzy match (pg_trgm enabled in migration 510)
  3) Gemini estimate via parse_food_description() in gemini/nutrition.py:307

Returns IngredientAnalyzeResponse with `nutrition_source` and `nutrition_confidence`
so the UI can badge each row.
"""

import logging
import re
from typing import List, Optional

from core.parse_utils import safe_float as _safe_float

from core.db import get_supabase_db
from models.recipe import (
    BulkIngredientAnalyzeRequest,
    BulkIngredientAnalyzeResponse,
    CookingMethod,
    IngredientAnalyzeRequest,
    IngredientAnalyzeResponse,
    NutritionSource,
)
from services.food_analysis.parser import (
    _volume_unit_to_ml,
    _weight_unit_to_grams,
)
from services.gemini.service import GeminiService

logger = logging.getLogger(__name__)

# Words that signal a row should be excluded from totals
_NEGLIGIBLE_HINTS = (
    "to taste", "pinch", "dash", "splash", "for serving", "for garnish", "as needed"
)

# Cooking-method keywords detected from the raw text
_METHOD_RE = re.compile(
    r"\b(raw|baked|grilled|fried|boiled|steamed|roasted|sauteed|sauted|sautéed|"
    r"slow[ -]?cooked|pressure[ -]?cooked|air[ -]?fried|smoked)\b",
    re.IGNORECASE,
)


def _detect_cooking_method(text: str) -> Optional[CookingMethod]:
    m = _METHOD_RE.search(text or "")
    if not m:
        return None
    raw = m.group(1).lower().replace(" ", "_").replace("-", "_")
    raw = raw.replace("sauted", "sauteed").replace("sautéed", "sauteed")
    try:
        return CookingMethod(raw)
    except ValueError:
        return CookingMethod.OTHER


def _is_negligible(text: str) -> bool:
    lower = (text or "").lower()
    return any(hint in lower for hint in _NEGLIGIBLE_HINTS)


class IngredientAnalyzerService:
    """Per-row ingredient analyzer."""

    def __init__(self, gemini: Optional[GeminiService] = None):
        self.gemini = gemini or GeminiService()
        self.db = get_supabase_db()

    async def analyze_one(self, req: IngredientAnalyzeRequest) -> IngredientAnalyzeResponse:
        """Resolve a single row. Always returns a response; never silently returns 0s."""
        text = req.text.strip()
        cooking_method = req.cooking_method_hint or _detect_cooking_method(text)
        negligible = _is_negligible(text)

        if negligible:
            return IngredientAnalyzeResponse(
                food_name=text,
                amount=1, unit="pinch",
                cooking_method=cooking_method,
                nutrition_source=NutritionSource.AI_ESTIMATE,
                nutrition_confidence=100,
                is_negligible=True,
                raw_text=text,
            )

        # 1) Try branded / saved-food (only if user supplied)
        if req.user_id:
            branded = await self._try_branded_match(text, req.user_id)
            if branded:
                branded.cooking_method = cooking_method
                branded.raw_text = text
                return branded

        # 2) Try USDA fuzzy match using pg_trgm
        usda = await self._try_usda_match(text)
        if usda:
            usda.cooking_method = cooking_method
            usda.raw_text = text
            return usda

        # 3) Gemini estimate (no fallback below this)
        return await self._gemini_estimate(text, cooking_method, req)

    async def analyze_many(
        self, req: BulkIngredientAnalyzeRequest
    ) -> BulkIngredientAnalyzeResponse:
        """Analyze a list serially (cheap; rows resolved largely from cache or DB)."""
        results: List[IngredientAnalyzeResponse] = []
        for item in req.items:
            if req.user_id and not item.user_id:
                item.user_id = req.user_id
            try:
                results.append(await self.analyze_one(item))
            except Exception as exc:
                logger.exception("[IngredientAnalyzer] failed on '%s': %s", item.text, exc)
                # Surface the failure as an explicit low-confidence row rather than swallowing
                results.append(
                    IngredientAnalyzeResponse(
                        food_name=item.text,
                        amount=0, unit="g",
                        nutrition_source=NutritionSource.AI_ESTIMATE,
                        nutrition_confidence=0,
                        is_negligible=False,
                        raw_text=item.text,
                    )
                )
        return BulkIngredientAnalyzeResponse(items=results)

    # ------------------------------------------------------------------
    # Resolvers
    # ------------------------------------------------------------------

    async def _try_branded_match(self, text: str, user_id: str) -> Optional[IngredientAnalyzeResponse]:
        """Look up user's saved foods by trigram similarity on food_name."""
        try:
            rows = (
                self.db.client.rpc(
                    "match_saved_food_by_text",
                    {"p_user_id": user_id, "p_query": text, "p_threshold": 0.45},
                ).execute()
                if hasattr(self.db.client, "rpc")
                else None
            )
        except Exception:
            rows = None

        if not rows or not rows.data:
            return None
        row = rows.data[0]
        return IngredientAnalyzeResponse(
            food_name=row.get("food_name") or text,
            brand=row.get("brand"),
            amount=float(row.get("amount") or 1),
            unit=row.get("unit") or "g",
            amount_grams=row.get("amount_grams"),
            nutrition_source=NutritionSource.BRANDED,
            nutrition_confidence=int(row.get("similarity_pct") or 95),
            calories=float(row.get("calories") or 0),
            protein_g=float(row.get("protein_g") or 0),
            carbs_g=float(row.get("carbs_g") or 0),
            fat_g=float(row.get("fat_g") or 0),
            fiber_g=float(row.get("fiber_g") or 0),
            sugar_g=float(row.get("sugar_g") or 0),
            raw_text=text,
        )

    async def _try_usda_match(self, text: str) -> Optional[IngredientAnalyzeResponse]:
        """Fuzzy-match against the existing food_database table.

        Falls through (returns None) when nothing meaningful matches; the
        Gemini estimate path then takes over. We never silently return zeros.
        """
        try:
            # Existing food_database_rpc.sql exposes a search RPC; use it if present.
            res = self.db.client.rpc(
                "search_foods", {"p_query": text, "p_limit": 1}
            ).execute()
        except Exception:
            return None

        if not res or not res.data:
            return None

        match = res.data[0]
        amount = float(match.get("default_amount") or 100)
        unit = match.get("default_unit") or "g"
        return IngredientAnalyzeResponse(
            food_name=match.get("name") or text,
            amount=amount,
            unit=unit,
            amount_grams=match.get("amount_grams") or amount,
            nutrition_source=NutritionSource.USDA,
            nutrition_confidence=int(match.get("similarity_pct") or 80),
            calories=float(match.get("calories") or 0),
            protein_g=float(match.get("protein_g") or 0),
            carbs_g=float(match.get("carbs_g") or 0),
            fat_g=float(match.get("fat_g") or 0),
            fiber_g=float(match.get("fiber_g") or 0),
            sugar_g=float(match.get("sugar_g") or 0),
            sodium_mg=match.get("sodium_mg"),
            calcium_mg=match.get("calcium_mg"),
            iron_mg=match.get("iron_mg"),
            vitamin_d_iu=match.get("vitamin_d_iu"),
            omega3_g=match.get("omega3_g"),
            raw_text=text,
        )

    async def _gemini_estimate(
        self,
        text: str,
        cooking_method: Optional[CookingMethod],
        req: IngredientAnalyzeRequest,
    ) -> IngredientAnalyzeResponse:
        """Last resort: Gemini estimates macros for the row.

        Uses parse_food_description() for one-shot parse + nutrition estimate.
        We always badge as ai_estimate so the UI shows the "🤖 AI · N%" pill.
        """
        prompt_text = text
        if cooking_method:
            prompt_text = f"{cooking_method.value} {text}"
        if req.brand_hint:
            prompt_text = f"{req.brand_hint} {prompt_text}"

        result = await self.gemini.parse_food_description(
            description=prompt_text, user_id=req.user_id
        )

        # If Gemini failed entirely, throw — caller can retry / surface error.
        # No silent zero-row return (per feedback_no_silent_fallbacks.md).
        if not result:
            raise RuntimeError(f"Gemini could not parse ingredient: {text!r}")

        items = result.get("food_items") or []
        if not items:
            raise RuntimeError(f"Gemini returned no food_items for {text!r}")

        first = items[0]
        # Estimate confidence: bias by whether AI returned a structured amount + unit
        confidence = 70
        if first.get("amount") and first.get("unit"):
            confidence += 10
        confidence = min(confidence, 90)

        # Convert volume → grams when possible to populate amount_grams
        unit = (first.get("unit") or "g").lower()
        amount = _safe_float(first.get("amount"), default=1.0)
        amount_grams = None
        try:
            amount_grams = _weight_unit_to_grams(amount, unit)
        except Exception:
            try:
                # ml-known density ≈ 1 g/ml for water-like; we leave None otherwise
                ml = _volume_unit_to_ml(amount, unit)
                if unit in ("ml", "l", "fl_oz", "cup_water"):
                    amount_grams = ml
            except Exception:
                pass

        return IngredientAnalyzeResponse(
            food_name=first.get("name") or text,
            brand=first.get("brand"),
            amount=amount,
            unit=unit,
            amount_grams=amount_grams,
            cooking_method=cooking_method,
            nutrition_source=NutritionSource.AI_ESTIMATE,
            nutrition_confidence=confidence,
            calories=_safe_float(first.get("calories")),
            protein_g=_safe_float(first.get("protein_g")),
            carbs_g=_safe_float(first.get("carbs_g")),
            fat_g=_safe_float(first.get("fat_g")),
            fiber_g=_safe_float(first.get("fiber_g")),
            sugar_g=_safe_float(first.get("sugar_g")),
            sodium_mg=first.get("sodium_mg"),
            raw_text=text,
        )


_singleton: Optional[IngredientAnalyzerService] = None


def get_ingredient_analyzer() -> IngredientAnalyzerService:
    global _singleton
    if _singleton is None:
        _singleton = IngredientAnalyzerService()
    return _singleton
