"""
Recipe Import Service
=====================
Parses external recipes from three sources, normalizes to RecipeCreate:
  1) URL    — fetched with httpx, main content extracted with trafilatura, parsed by Gemini
  2) Text   — pasted free-text recipe, parsed by Gemini
  3) Image  — handwritten or printed recipe photo, OCR + structured by Gemini Vision

Each path:
  - Streams progress events (steps: fetching → extracting → parsing → matching → done)
  - Returns a RecipeCreate ready for POST /nutrition/recipes
  - Sets source_type to imported_url / imported_text / imported_handwritten
  - Records ingredient nutrition_source as ai_estimate (recipe builder will refresh later)
  - Throws explicit errors on low confidence (no silent garbage)
"""

import asyncio
import json
import logging
import re
from typing import AsyncIterator, Dict, List, Optional

import httpx

from core import branding
from core.parse_utils import safe_int
from models.recipe import (
    CookingMethod,
    NutritionSource,
    RecipeCategory,
    RecipeCreate,
    RecipeIngredientCreate,
    RecipeSourceType,
)
from services.gemini.service import GeminiService
from services.gemini_text_helper import gemini_text
from services.ingredient_analyzer_service import get_ingredient_analyzer
from services.vision_service import VisionService

logger = logging.getLogger(__name__)

# Heuristic: minimum confidence the import reached a "this is actually a recipe" state
_MIN_RECIPE_CONFIDENCE = 60

# Unicode fraction map (from OCR / web scraping)
_UNICODE_FRACTIONS = {
    "½": 0.5, "⅓": 1/3, "⅔": 2/3, "¼": 0.25, "¾": 0.75,
    "⅕": 0.2, "⅖": 0.4, "⅗": 0.6, "⅘": 0.8,
    "⅙": 1/6, "⅚": 5/6, "⅛": 0.125, "⅜": 0.375, "⅝": 0.625, "⅞": 0.875,
}

# Known unit strings — used to detect when Gemini merges amount+unit into
# the "amount" field (e.g. "2.0 cup" instead of amount=2.0, unit="cup").
_KNOWN_UNITS = frozenset({
    "g", "kg", "oz", "lb", "lbs", "ml", "l", "dl", "cl",
    "cup", "cups", "tbsp", "tsp", "tablespoon", "tablespoons",
    "teaspoon", "teaspoons", "piece", "pieces", "slice", "slices",
    "clove", "cloves", "bunch", "bunches", "pinch", "dash",
    "handful", "can", "cans", "bottle", "bottles", "packet", "packets",
    "sprig", "sprigs", "stick", "sticks", "head", "heads",
    "stalk", "stalks", "fillet", "fillets", "leaf", "leaves",
    "strip", "strips", "scoop", "scoops", "quart", "pint", "gallon",
    "drop", "drops", "bag", "bags", "jar", "jars", "box", "boxes",
    "large", "medium", "small",
})


def _parse_amount(raw: object) -> float:
    """Robustly parse an ingredient amount from Gemini's JSON output.

    Handles: numeric, string-numeric, amount+unit merged ("2.0 cup"),
    fractions ("1/2"), mixed fractions ("1 1/2"), unicode ("½"),
    ranges ("2-3"), European decimals ("1,5"), descriptive ("a pinch"),
    and None / empty.
    """
    if raw is None:
        return 1.0
    if isinstance(raw, (int, float)):
        return float(raw) if raw > 0 else 1.0

    s = str(raw).strip()
    if not s:
        return 1.0

    # European comma decimal ("1,5" → "1.5") — only when no other commas
    if s.count(",") == 1 and "." not in s:
        s = s.replace(",", ".")

    # Strip unit suffix if Gemini merged amount+unit ("2.0 cup" → "2.0")
    parts = s.split()
    if len(parts) >= 2 and parts[-1].lower().rstrip("s.") in _KNOWN_UNITS or parts[-1].lower() in _KNOWN_UNITS:
        s = " ".join(parts[:-1])

    # Try plain float first
    try:
        val = float(s)
        return val if val > 0 else 1.0
    except ValueError:
        pass

    # Unicode fractions: "½", "1½", "1 ½"
    for uf, fval in _UNICODE_FRACTIONS.items():
        if uf in s:
            # "1½" → 1 + 0.5;  "½" → 0.5
            prefix = s.replace(uf, "").strip()
            whole = float(prefix) if prefix else 0.0
            return whole + fval

    # Slash fractions: "1/2", "1 1/2", "3/4"
    frac_match = re.match(r"^(\d+)\s+(\d+)\s*/\s*(\d+)$", s)
    if frac_match:
        whole, num, den = int(frac_match.group(1)), int(frac_match.group(2)), int(frac_match.group(3))
        return whole + (num / den if den else 0)

    frac_match = re.match(r"^(\d+)\s*/\s*(\d+)$", s)
    if frac_match:
        num, den = int(frac_match.group(1)), int(frac_match.group(2))
        return num / den if den else 1.0

    # Ranges: "2-3", "2 to 3" → take the first value
    range_match = re.match(r"^([\d.]+)\s*(?:-|to)\s*[\d.]+", s)
    if range_match:
        return float(range_match.group(1))

    # Last resort: extract first number-like token
    num_match = re.search(r"[\d.]+", s)
    if num_match:
        try:
            return float(num_match.group())
        except ValueError:
            pass

    return 1.0


def _split_amount_unit(ing: dict) -> tuple:
    """Extract clean (amount_str, unit, food_name) from a Gemini ingredient dict.

    Handles the case where Gemini merges amount+unit into the amount field
    (e.g. amount="2.0 cup", unit="" instead of amount=2.0, unit="cup").
    """
    raw_amount = ing.get("amount", "")
    unit = ing.get("unit", "")
    food_name = ing.get("food_name", "")

    # If amount is already numeric, nothing to split
    if isinstance(raw_amount, (int, float)):
        return str(raw_amount), unit, food_name

    amount_str = str(raw_amount).strip()
    parts = amount_str.split()

    # Detect merged amount+unit: "2.0 cup" → amount="2.0", unit="cup"
    if len(parts) >= 2 and not unit:
        tail = parts[-1].lower()
        if tail.rstrip("s.") in _KNOWN_UNITS or tail in _KNOWN_UNITS:
            return " ".join(parts[:-1]), parts[-1], food_name

    return amount_str, unit, food_name

_RECIPE_PARSE_PROMPT = """You are a strict recipe parser. Given the input, return ONLY valid JSON
with this exact schema (no markdown, no commentary):
{
  "is_recipe": true|false,
  "confidence": 0-100,
  "recipe": {
    "name": "...",
    "description": "...",
    "servings": 1,
    "prep_time_minutes": 0,
    "cook_time_minutes": 0,
    "cuisine": "...",
    "category": "breakfast|lunch|dinner|snack|dessert|drink|other",
    "cooking_method": "raw|baked|grilled|fried|boiled|steamed|roasted|sauteed|slow_cooked|pressure_cooked|air_fried|smoked|other|null",
    "instructions": "Step 1. ...\\nStep 2. ...",
    "tags": [],
    "ingredients": [
      {"food_name": "...", "amount": 1.0, "unit": "g|oz|cup|tbsp|tsp|ml|piece",
       "notes": "optional",
       "amount_grams": 0.0,
       "calories": 0, "protein_g": 0.0, "carbs_g": 0.0, "fat_g": 0.0, "fiber_g": 0.0}
    ]
  }
}
For EACH ingredient also estimate its nutrition for the AMOUNT used in the
recipe (not per-100g): amount_grams = the ingredient's weight in grams for
the stated amount/unit, and calories/protein_g/carbs_g/fat_g/fiber_g for
that whole amount. Use standard nutrition knowledge — these are estimates.
If the input is not a recipe (e.g., random article, shopping list, blog intro only), set is_recipe=false and recipe=null.
"""


def _strip_markdown_json(text: str) -> str:
    """Gemini sometimes wraps JSON in ```json fences; strip them."""
    text = text.strip()
    if text.startswith("```"):
        text = re.sub(r"^```(?:json)?\s*", "", text)
        text = re.sub(r"\s*```$", "", text)
    return text


class RecipeImportService:
    """Three-mode recipe importer with streaming progress."""

    def __init__(self):
        self.gemini = GeminiService()
        self.vision = VisionService()
        self.analyzer = get_ingredient_analyzer()

    # ------------------------------------------------------------------
    # URL import
    # ------------------------------------------------------------------

    async def import_url(
        self, url: str, user_id: Optional[str] = None
    ) -> AsyncIterator[Dict]:
        yield {"step": "fetching", "message": f"Fetching {url}"}

        try:
            async with httpx.AsyncClient(timeout=15) as client:
                resp = await client.get(
                    url,
                    follow_redirects=True,
                    headers={"User-Agent": f"{branding.APP_NAME} Recipe Importer"},
                )
                resp.raise_for_status()
                html = resp.text
        except Exception as exc:
            yield {"step": "error", "message": f"Could not fetch URL: {exc}"}
            return

        yield {"step": "extracting", "message": "Extracting main content"}

        # Use trafilatura for main-content extraction; fall back to raw HTML head
        try:
            import trafilatura

            extracted = trafilatura.extract(html, include_images=False) or ""
        except Exception:
            # Strip tags as a last resort; recipe parser only needs text
            extracted = re.sub(r"<[^>]+>", " ", html)
            extracted = re.sub(r"\s+", " ", extracted)[:8000]

        if not extracted or len(extracted) < 80:
            yield {"step": "error", "message": "Page content was too short to parse"}
            return

        async for event in self._parse_text_to_recipe(
            extracted, user_id, source_type=RecipeSourceType.IMPORTED_URL, source_url=url
        ):
            yield event

    # ------------------------------------------------------------------
    # Text import
    # ------------------------------------------------------------------

    async def import_text(
        self, text: str, user_id: Optional[str] = None
    ) -> AsyncIterator[Dict]:
        yield {"step": "parsing", "message": "Parsing recipe text"}
        async for event in self._parse_text_to_recipe(
            text, user_id, source_type=RecipeSourceType.IMPORTED_TEXT
        ):
            yield event

    # ------------------------------------------------------------------
    # Handwritten image import
    # ------------------------------------------------------------------

    async def import_handwritten(
        self, image_b64: str, user_id: Optional[str] = None
    ) -> AsyncIterator[Dict]:
        yield {"step": "ocr", "message": "Reading handwriting…"}

        ocr_text = await self.vision.extract_handwritten_recipe(image_b64)
        if not ocr_text or len(ocr_text) < 30:
            yield {"step": "error", "message": "Couldn't read enough text from the image"}
            return

        yield {"step": "parsing", "message": "Structuring recipe"}
        async for event in self._parse_text_to_recipe(
            ocr_text, user_id, source_type=RecipeSourceType.IMPORTED_HANDWRITTEN
        ):
            yield event

    # ------------------------------------------------------------------
    # Social video import (Instagram / TikTok / YouTube / Pinterest)
    # ------------------------------------------------------------------

    async def import_social(
        self, url: str, user_id: Optional[str] = None
    ) -> AsyncIterator[Dict]:
        """Import a recipe from a social video URL.

        Reuses the share-pipeline fetcher (`url_content_fetcher.fetch`) which
        already handles platform detection, yt-dlp download (IG/TikTok), the
        official YouTube transcript API, and cookie auth. We then enrich the
        text with on-screen-text OCR + spoken-audio transcription of the video
        frames, and hand the combined blob to the same `_parse_text_to_recipe`
        used by the URL/text/handwritten paths.

        YouTube never downloads the bitstream (App Store compliance) — its
        official transcript already comes back inside `SharedContent.as_text()`.
        Pinterest and other hosts fall through to the generic web fetch.
        """
        from services.url_content_fetcher import detect_source, fetch

        source = detect_source(url)
        yield {"step": "fetching", "message": f"Fetching {source} post…"}

        content = await fetch(url)
        if content.locked:
            yield {
                "step": "error",
                "message": content.error
                or "This post is private or blocked. Open it in the app and tap "
                "Share → Zealova, or paste the recipe text instead.",
            }
            return
        if content.error:
            yield {"step": "error", "message": content.error}
            return

        # Base text: title + caption + body + (YouTube) transcript.
        base_text = content.as_text()

        # Enrich IG/TikTok videos with on-screen text (OCR) + narration (audio).
        media_text = ""
        if content.media and content.source in ("instagram", "tiktok"):
            yield {"step": "transcribing", "message": "Reading the video (text + narration)…"}
            frames: List = []
            try:
                from services.workout_extractor import _sample_video_frames

                frames = await _sample_video_frames(content)
            except Exception as exc:
                logger.info("[RecipeImport] frame sampling skipped: %s", exc)
            audio_part = await self._extract_audio_part(content)
            if frames or audio_part is not None:
                media_text = await self.vision.extract_text_from_frames(
                    frames, audio_part=audio_part
                )

        blob = "\n\n".join(p for p in (base_text, media_text) if p).strip()

        # No silent fallback — if we couldn't read enough to be a recipe, say so.
        if len(blob) < 40:
            yield {
                "step": "error",
                "message": "Couldn't read a recipe from this video. Try a post with "
                "the recipe in the caption or shown on-screen.",
            }
            return

        yield {"step": "parsing", "message": "Parsing recipe content"}
        async for event in self._parse_text_to_recipe(
            blob, user_id, source_type=RecipeSourceType.IMPORTED_VIDEO, source_url=url
        ):
            yield event

    async def _extract_audio_part(self, content):
        """Extract the audio track from the downloaded social video as a Gemini
        audio Part (16 kHz mono WAV). Best-effort: returns None when there is no
        video asset, ffmpeg is unavailable, the clip is silent, or extraction
        fails. Re-downloads the asset from S3 (cheap for a short reel) so it
        stays independent of the frame sampler.
        """
        import os
        import shutil
        import tempfile

        from google.genai import types

        if not content.media:
            return None
        asset = content.media[0]
        if getattr(asset, "type", None) != "video" or not getattr(asset, "s3_key", None):
            return None
        if shutil.which("ffmpeg") is None:
            return None

        try:
            from services.s3_service import get_s3_service

            video_bytes = await asyncio.to_thread(
                get_s3_service().download_bytes, asset.s3_key
            )
        except Exception as exc:
            logger.info("[RecipeImport] audio S3 download failed: %s", exc)
            return None

        tmp_dir = tempfile.mkdtemp(prefix="zealova-audio-")
        try:
            in_path = os.path.join(tmp_dir, "in.mp4")
            out_path = os.path.join(tmp_dir, "out.wav")
            with open(in_path, "wb") as fh:
                fh.write(video_bytes)
            proc = await asyncio.create_subprocess_exec(
                "ffmpeg", "-y", "-i", in_path,
                "-vn", "-ac", "1", "-ar", "16000", "-c:a", "pcm_s16le",
                out_path,
                stdout=asyncio.subprocess.DEVNULL,
                stderr=asyncio.subprocess.DEVNULL,
            )
            await proc.wait()
            # < 1 KB → no audio stream / silent clip.
            if not os.path.exists(out_path) or os.path.getsize(out_path) < 1024:
                return None
            with open(out_path, "rb") as fh:
                wav = fh.read()
            # Cap payload (~25 MB ≈ 13 min @ 16 kHz mono) so a mis-detected long
            # video doesn't blow up the Gemini request.
            if len(wav) > 25 * 1024 * 1024:
                return None
            return types.Part.from_bytes(data=wav, mime_type="audio/wav")
        except Exception as exc:
            logger.info("[RecipeImport] audio extraction failed: %s", exc)
            return None
        finally:
            shutil.rmtree(tmp_dir, ignore_errors=True)

    # ------------------------------------------------------------------
    # Shared text → recipe with ingredient analysis
    # ------------------------------------------------------------------

    async def _parse_text_to_recipe(
        self,
        text: str,
        user_id: Optional[str],
        source_type: RecipeSourceType,
        source_url: Optional[str] = None,
    ) -> AsyncIterator[Dict]:
        # 1) Ask Gemini to extract structured recipe
        try:
            raw = await gemini_text(
                f"{_RECIPE_PARSE_PROMPT}\n\nINPUT:\n{text[:8000]}",
                temperature=0.2,
                method_name="recipe_import_parse",
            )
            parsed = json.loads(_strip_markdown_json(raw))
        except Exception as exc:
            logger.exception("[RecipeImport] Gemini parse failed")
            yield {"step": "error", "message": f"Couldn't parse recipe: {exc}"}
            return

        if not parsed.get("is_recipe") or (parsed.get("confidence", 0) < _MIN_RECIPE_CONFIDENCE):
            yield {
                "step": "error",
                "message": "This doesn't look like a recipe. Try pasting the recipe content directly.",
            }
            return

        recipe = parsed.get("recipe") or {}
        ingredients_raw = recipe.get("ingredients") or []

        yield {
            "step": "analyzing",
            "message": f"Estimating nutrition for {len(ingredients_raw)} ingredients",
        }

        # FAST PATH: the recipe-parse Gemini call now returns per-ingredient
        # nutrition inline (amount_grams + calories/protein/carbs/fat/fiber).
        # So for ingredients that came back with nutrition we build the row
        # directly — ZERO extra Gemini calls. Only ingredients missing
        # nutrition fall back to the per-ingredient analyzer (rare). This
        # collapses ~12 sequential Gemini calls into the single parse call:
        # recipe import 25s → ~4-6s.
        from models.recipe import IngredientAnalyzeRequest

        def _has_inline_nutrition(ing: dict) -> bool:
            cal = ing.get("calories")
            return cal is not None and float(cal or 0) > 0

        def _num(v, default=0.0) -> float:
            try:
                return float(v)
            except (TypeError, ValueError):
                return default

        def _inline_row(idx: int, ing: dict) -> RecipeIngredientCreate:
            amt_str, unit_str, food_name = _split_amount_unit(ing)
            return RecipeIngredientCreate(
                ingredient_order=idx,
                food_name=food_name or ing.get("food_name") or "ingredient",
                amount=_parse_amount(ing.get("amount")),
                unit=unit_str or "g",
                amount_grams=_num(ing.get("amount_grams")) or None,
                calories=_num(ing.get("calories")),
                protein_g=_num(ing.get("protein_g")),
                carbs_g=_num(ing.get("carbs_g")),
                fat_g=_num(ing.get("fat_g")),
                fiber_g=_num(ing.get("fiber_g")),
                nutrition_source=NutritionSource.AI_ESTIMATE,
                nutrition_confidence=60,
                raw_text=f"{amt_str} {unit_str} {food_name}".strip(),
                notes=ing.get("notes"),
            )

        _ing_sem = asyncio.Semaphore(8)

        async def _analyze_ingredient(idx: int, ing: dict) -> RecipeIngredientCreate:
            # Fallback only — ingredient came back without inline nutrition.
            amt_str, unit_str, food_name = _split_amount_unit(ing)
            ing_text = f"{amt_str} {unit_str} {food_name}".strip()
            try:
                async with _ing_sem:
                    analyzed = await self.analyzer.analyze_one(
                        IngredientAnalyzeRequest(text=ing_text, user_id=user_id)
                    )
                return RecipeIngredientCreate(
                    ingredient_order=idx,
                    food_name=analyzed.food_name, brand=analyzed.brand,
                    amount=analyzed.amount, unit=analyzed.unit,
                    amount_grams=analyzed.amount_grams,
                    calories=analyzed.calories, protein_g=analyzed.protein_g,
                    carbs_g=analyzed.carbs_g, fat_g=analyzed.fat_g,
                    fiber_g=analyzed.fiber_g, sugar_g=analyzed.sugar_g,
                    sodium_mg=analyzed.sodium_mg, calcium_mg=analyzed.calcium_mg,
                    iron_mg=analyzed.iron_mg, omega3_g=analyzed.omega3_g,
                    vitamin_d_iu=analyzed.vitamin_d_iu,
                    cooking_method=analyzed.cooking_method,
                    nutrition_source=analyzed.nutrition_source,
                    nutrition_confidence=analyzed.nutrition_confidence,
                    is_negligible=analyzed.is_negligible,
                    raw_text=analyzed.raw_text, notes=ing.get("notes"),
                )
            except Exception as exc:
                logger.warning("[RecipeImport] ingredient analyze failed: %s", exc)
                return RecipeIngredientCreate(
                    ingredient_order=idx,
                    food_name=food_name or ing_text,
                    amount=_parse_amount(ing.get("amount")),
                    unit=unit_str or "g",
                    nutrition_source=NutritionSource.AI_ESTIMATE,
                    nutrition_confidence=0, raw_text=ing_text,
                )

        capped = list(enumerate(ingredients_raw[:50]))
        ingredients: List[Optional[RecipeIngredientCreate]] = [None] * len(capped)
        fallback_tasks = []
        for idx, ing in capped:
            if _has_inline_nutrition(ing):
                ingredients[idx] = _inline_row(idx, ing)
            else:
                fallback_tasks.append((idx, asyncio.create_task(
                    _analyze_ingredient(idx, ing))))
        for idx, task in fallback_tasks:
            ingredients[idx] = await task
        ingredients = [r for r in ingredients if r is not None]

        try:
            category = RecipeCategory(recipe.get("category") or "other")
        except ValueError:
            category = RecipeCategory.OTHER
        try:
            cooking_method_val = recipe.get("cooking_method")
            cooking_method = CookingMethod(cooking_method_val) if cooking_method_val else None
        except ValueError:
            cooking_method = None

        recipe_create = RecipeCreate(
            name=recipe.get("name") or "Imported recipe",
            description=recipe.get("description"),
            servings=safe_int(recipe.get("servings"), default=1),
            prep_time_minutes=recipe.get("prep_time_minutes"),
            cook_time_minutes=recipe.get("cook_time_minutes"),
            instructions=recipe.get("instructions"),
            cuisine=recipe.get("cuisine"),
            category=category,
            tags=recipe.get("tags") or [],
            cooking_method=cooking_method,
            source_type=source_type,
            source_url=source_url,
            ingredients=ingredients,
        )

        yield {
            "step": "done",
            "message": "Recipe ready",
            "recipe": recipe_create.model_dump(mode="json"),
            "confidence": parsed.get("confidence", 0),
        }


_singleton: Optional[RecipeImportService] = None


def get_recipe_import_service() -> RecipeImportService:
    global _singleton
    if _singleton is None:
        _singleton = RecipeImportService()
    return _singleton
