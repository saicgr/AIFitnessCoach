"""
Vision Service for analyzing food images using Gemini Vision.

This service handles:
- Food image analysis for nutrition estimation
- Multi-image food analysis (plates, buffets, menus)
- Auto-detection of meal type based on time of day
- JSON-formatted nutrition responses
"""

import asyncio
import json
import base64
from datetime import datetime
from typing import Optional
from google import genai
from google.genai import types

import boto3

from core.config import get_settings
from core.gemini_client import get_genai_client
from core.logger import get_logger
from models.gemini_schemas import FoodAnalysisResponse

logger = get_logger(__name__)
settings = get_settings()

# Initialize Gemini client
client = get_genai_client()


def _get_nutrition_cache() -> Optional[str]:
    """Get the nutrition analysis cache name from GeminiService (if available)."""
    try:
        from services.gemini_service import GeminiService
        return GeminiService._nutrition_analysis_cache
    except Exception:
        return None


class VisionService:
    """Service for analyzing images using Gemini Vision."""

    def __init__(self):
        self.model = settings.gemini_model
        # Initialize S3 client for multi-image analysis
        if settings.aws_access_key_id and settings.s3_bucket_name:
            self._s3_client = boto3.client(
                "s3",
                aws_access_key_id=settings.aws_access_key_id,
                aws_secret_access_key=settings.aws_secret_access_key,
                region_name=settings.aws_default_region,
            )
            self._bucket = settings.s3_bucket_name
        else:
            self._s3_client = None
            self._bucket = None

    def _get_suggested_meal_type(self) -> str:
        """Determine likely meal type based on current time."""
        hour = datetime.now().hour
        if 5 <= hour < 11:
            return "breakfast"
        elif 11 <= hour < 15:
            return "lunch"
        elif 15 <= hour < 18:
            return "snack"
        else:
            return "dinner"

    async def analyze_food_image(
        self,
        image_base64: str,
        user_context: Optional[str] = None,
    ) -> dict:
        """
        Analyze a food image to extract nutrition information.

        Args:
            image_base64: Base64 encoded image data (without data:image prefix)
            user_context: Optional message from user about the meal

        Returns:
            Dictionary with nutrition analysis including:
            - meal_type: Detected meal type
            - food_items: List of identified foods with individual nutrition
            - total_calories, total_protein_g, total_carbs_g, total_fat_g, total_fiber_g
            - health_score: 1-10 rating
            - feedback: Coaching feedback on the meal
        """
        suggested_meal = self._get_suggested_meal_type()

        # Check for nutrition context cache
        cache_name = _get_nutrition_cache()

        if cache_name:
            # Dynamic-only prompt (static guidelines/schema/reference data are in the cache)
            prompt = f"""Analyze this food image and provide detailed nutrition estimates.

Current time suggests this is likely {suggested_meal}, but override based on the food if it clearly indicates otherwise.

{f'User says: "{user_context}"' if user_context else ''}

Use the plate analysis JSON schema from your cached reference. Return valid JSON."""
        else:
            # Full prompt (no cache available — include everything inline)
            prompt = f"""Analyze this food image and provide detailed nutrition estimates.

Current time suggests this is likely {suggested_meal}, but override based on the food if it clearly indicates otherwise (e.g., pancakes are breakfast even at dinner time).

{f'User says: "{user_context}"' if user_context else ''}

Return ONLY valid JSON with this exact structure:
{{
    "meal_type": "breakfast" | "lunch" | "dinner" | "snack",
    "food_items": [
        {{
            "name": "food name",
            "amount": "estimated amount (e.g., '1 cup', '150g', '1 medium')",
            "calories": <integer>,
            "protein_g": <float>,
            "carbs_g": <float>,
            "fat_g": <float>
        }}
    ],
    "total_calories": <integer>,
    "total_protein_g": <float>,
    "total_carbs_g": <float>,
    "total_fat_g": <float>,
    "total_fiber_g": <float>,
    "health_score": <integer 1-10>,
    "feedback": "Brief, encouraging coaching feedback about this meal (2-3 sentences max)"
}}

Guidelines:
- Be realistic with portion estimates based on what you see
- If you can't identify something clearly, make a reasonable guess
- Health score: 1-3 (poor), 4-6 (average), 7-8 (good), 9-10 (excellent)
- Feedback should be constructive and encouraging, mentioning positives first
- Include fiber estimate if vegetables/whole grains are present"""

        try:
            logger.info(f"🍽️ Analyzing food image with Gemini (cache={'yes' if cache_name else 'no'})")

            # Decode base64 image data
            image_bytes = base64.b64decode(image_base64)

            # Create image part for Gemini using the new SDK
            image_part = types.Part.from_bytes(
                data=image_bytes,
                mime_type="image/jpeg"
            )

            # Build config with optional cached_content
            gen_config = types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=FoodAnalysisResponse,
                max_output_tokens=3000,
                temperature=0.3,
            )
            if cache_name:
                gen_config.cached_content = cache_name

            # Generate content with image
            response = await client.aio.models.generate_content(
                model=self.model,
                contents=[prompt, image_part],
                config=gen_config,
            )

            # Parse the response - structured output guarantees valid JSON
            content = response.text.strip()
            logger.info(f"✅ Vision API response received")
            result = json.loads(content)

            # Validate required fields
            required_fields = [
                "meal_type",
                "food_items",
                "total_calories",
                "total_protein_g",
                "total_carbs_g",
                "total_fat_g",
                "health_score",
                "feedback",
            ]
            for field in required_fields:
                if field not in result:
                    logger.warning(f"Missing field in response: {field}")
                    result[field] = self._get_default_value(field)

            # Ensure fiber is present
            if "total_fiber_g" not in result:
                result["total_fiber_g"] = 0.0

            # Normalize response - add non-prefixed versions for consistency with GeminiService
            # This ensures both total_protein_g and protein_g are available
            result["protein_g"] = result.get("total_protein_g", 0.0)
            result["carbs_g"] = result.get("total_carbs_g", 0.0)
            result["fat_g"] = result.get("total_fat_g", 0.0)
            result["fiber_g"] = result.get("total_fiber_g", 0.0)

            logger.info(
                f"✅ Food analysis complete: {result['total_calories']} cal, "
                f"{len(result['food_items'])} items identified"
            )

            return result

        except json.JSONDecodeError as e:
            logger.error(f"❌ Failed to parse JSON response: {e}")
            logger.error(f"Raw content: {content[:500]}...")
            raise ValueError(f"Invalid JSON in vision response: {e}")

        except Exception as e:
            logger.error(f"❌ Vision analysis failed: {e}")
            raise

    # Valid media content types for classification
    VALID_CONTENT_TYPES = {
        "food_plate", "food_menu", "food_buffet", "exercise_form",
        "progress_photo", "app_screenshot", "nutrition_label",
        "document", "gym_equipment", "unknown",
    }

    async def classify_media_content(
        self,
        image_data: bytes | None = None,
        image_base64: str | None = None,
        mime_type: str = "image/jpeg",
        s3_key: str | None = None,
    ) -> str:
        """
        Classify what media content shows. Lightweight Gemini Vision call (~10 tokens output).

        Used for intelligent agent routing before the message reaches a domain agent.

        Returns one of: food_plate, food_menu, food_buffet, exercise_form,
        progress_photo, app_screenshot, nutrition_label, document,
        gym_equipment, unknown
        """
        import time as _time
        start = _time.time()

        classify_prompt = (
            "Look at this image/frame. Classify what it shows as ONE of these categories. "
            "Respond with ONLY the category name, nothing else.\n\n"
            "Categories:\n"
            "- food_plate: A plate, bowl, or serving of food/drink\n"
            "- food_menu: A restaurant or cafe menu (printed or digital)\n"
            "- food_buffet: A buffet spread or multiple dishes laid out on a table\n"
            "- exercise_form: A person performing a physical exercise or workout movement\n"
            "- progress_photo: A body/physique photo, mirror selfie, or before/after comparison\n"
            "- app_screenshot: A screenshot from a phone app (fitness tracker, MyFitnessPal, etc.)\n"
            "- nutrition_label: A nutrition facts label on food packaging\n"
            "- document: A text document, handwritten note, printed paper, or PDF\n"
            "- gym_equipment: Gym equipment or machines with no person exercising\n"
            "- unknown: Cannot determine or none of the above"
        )

        try:
            # Resolve image bytes from the various input sources
            if image_data:
                raw_bytes = image_data
            elif image_base64:
                raw_bytes = base64.b64decode(image_base64)
            elif s3_key:
                raw_bytes = await self._download_image_from_s3(s3_key)
            else:
                logger.warning("[MediaClassifier] No image data provided")
                return "unknown"

            image_part = types.Part.from_bytes(data=raw_bytes, mime_type=mime_type)

            response = await client.aio.models.generate_content(
                model=self.model,
                contents=[classify_prompt, image_part],
                config=types.GenerateContentConfig(
                    temperature=0.1,
                    max_output_tokens=15,
                ),
            )

            raw_text = response.text.strip().lower()
            # Match against valid types with substring matching
            for content_type in self.VALID_CONTENT_TYPES:
                if content_type in raw_text:
                    elapsed = _time.time() - start
                    logger.info(f"[MediaClassifier] Classified as: {content_type} (took {elapsed:.2f}s)")
                    return content_type

            elapsed = _time.time() - start
            logger.warning(f"[MediaClassifier] Unrecognized response '{raw_text}', defaulting to unknown (took {elapsed:.2f}s)")
            return "unknown"

        except Exception as e:
            elapsed = _time.time() - start
            logger.warning(f"[MediaClassifier] Classification failed (took {elapsed:.2f}s): {e}")
            return "unknown"

    async def _download_image_from_s3(self, s3_key: str) -> bytes:
        """Download an image from S3 into memory (max ~1.5MB per image)."""
        if not self._s3_client or not self._bucket:
            raise RuntimeError("S3 client not configured for multi-image analysis")

        s3_obj = await asyncio.to_thread(
            self._s3_client.get_object,
            Bucket=self._bucket,
            Key=s3_key,
        )
        body = s3_obj["Body"]
        data = await asyncio.to_thread(body.read)
        logger.debug(f"Downloaded {len(data)} bytes from S3 key: {s3_key}")
        return data

    async def _classify_food_images(self, image_parts: list) -> str:
        """Quick classification: plate, buffet, or menu."""
        classify_prompt = (
            "Look at these food-related images. Classify what they show as ONE of: "
            "plate, buffet, menu. Respond with one word only."
        )
        response = await client.aio.models.generate_content(
            model=self.model,
            contents=[classify_prompt] + image_parts,
            config=types.GenerateContentConfig(
                temperature=0.1,
                max_output_tokens=10,
            ),
        )
        classification = response.text.strip().lower()
        if "buffet" in classification or "spread" in classification:
            return "buffet"
        elif "menu" in classification:
            return "menu"
        return "plate"

    async def analyze_food_from_s3_keys(
        self,
        s3_keys: list[str],
        mime_types: list[str],
        user_context: str | None = None,
        analysis_mode: str = "auto",
        nutrition_context: dict | None = None,
    ) -> dict:
        """
        Analyze multiple food images from S3 for nutrition estimation.

        Supports plates, buffets, and restaurant menus.

        Args:
            s3_keys: List of S3 object keys for the images
            mime_types: List of MIME types for each image
            user_context: Optional user context message
            analysis_mode: "auto", "plate", "buffet", or "menu"
            nutrition_context: User's daily targets + remaining budget

        Returns:
            Dict with nutrition analysis results
        """
        logger.info(f"Analyzing {len(s3_keys)} food images, mode={analysis_mode}")

        try:
            # Step 1: Download all images from S3 in parallel
            download_tasks = [self._download_image_from_s3(key) for key in s3_keys]
            image_data_list = await asyncio.gather(*download_tasks)

            # Step 2: Create Gemini Parts for each image
            image_parts = []
            for data, mime_type in zip(image_data_list, mime_types):
                image_parts.append(types.Part.from_bytes(data=data, mime_type=mime_type))

            # Step 3: Auto-classify if needed
            if analysis_mode == "auto":
                analysis_mode = await self._classify_food_images(image_parts)
                logger.info(f"Auto-classified food images as: {analysis_mode}")

            # Step 4: Build prompt based on mode
            cache_name = _get_nutrition_cache()
            nutrition_ctx_str = ""
            if nutrition_context:
                nutrition_ctx_str = f"\nUser's nutrition context: {json.dumps(nutrition_context)}"

            user_ctx_str = f'\nUser says: "{user_context}"' if user_context else ""
            suggested_meal = self._get_suggested_meal_type()

            if analysis_mode == "buffet":
                if cache_name:
                    # Dynamic-only prompt (buffet schema + guidelines are in cache)
                    prompt = f"""Analyze this buffet/food spread. For each dish visible:
1. Identify the dish name
2. Estimate calories and macros per single serving
3. Rate as "green" (great for goals), "yellow" (moderate), or "red" (should skip) based on user's goals
{nutrition_ctx_str}{user_ctx_str}

Suggest an optimal plate composition that fits within remaining daily budget.
Use the buffet analysis JSON schema from your cached reference. Return valid JSON."""
                else:
                    prompt = f"""Analyze this buffet/food spread. For each dish visible:
1. Identify the dish name
2. Estimate calories and macros per single serving
3. Rate as "green" (great for goals), "yellow" (moderate), or "red" (should skip) based on user's goals
{nutrition_ctx_str}{user_ctx_str}

Suggest an optimal plate composition that fits within remaining daily budget.

Return JSON matching this schema:
{{
    "analysis_type": "buffet",
    "dishes": [
        {{
            "name": "dish name",
            "calories": 0,
            "protein_g": 0.0,
            "carbs_g": 0.0,
            "fat_g": 0.0,
            "serving_description": "estimated serving size",
            "rating": "green",
            "rating_reason": "why this rating"
        }}
    ],
    "suggested_plate": {{
        "items": [
            {{"name": "dish name", "serving": "amount", "calories": 0, "protein_g": 0.0}}
        ],
        "total_calories": 0,
        "total_protein_g": 0.0,
        "total_carbs_g": 0.0,
        "total_fat_g": 0.0
    }},
    "daily_budget_remaining": {{"calories": 0, "protein_g": 0.0}},
    "tips": ["tip1", "tip2"]
}}"""

            elif analysis_mode == "menu":
                if cache_name:
                    # Dynamic-only prompt (menu schema + guidelines are in cache)
                    prompt = f"""Analyze this restaurant menu. OCR extract dish names, estimate calories and macros.
Rate each as green/yellow/red based on user's goals.
Suggest a recommended order.
{nutrition_ctx_str}{user_ctx_str}

Use the menu analysis JSON schema from your cached reference. Return valid JSON."""
                else:
                    prompt = f"""Analyze this restaurant menu. OCR extract dish names, estimate calories and macros.
Rate each as green/yellow/red based on user's goals.
Suggest a recommended order.
{nutrition_ctx_str}{user_ctx_str}

Return JSON:
{{
    "analysis_type": "menu",
    "restaurant_name": null,
    "sections": [
        {{
            "section_name": "section name",
            "dishes": [
                {{
                    "name": "dish name",
                    "price": null,
                    "calories": 0,
                    "protein_g": 0.0,
                    "carbs_g": 0.0,
                    "fat_g": 0.0,
                    "rating": "green",
                    "rating_reason": "why this rating"
                }}
            ]
        }}
    ],
    "recommended_order": {{
        "items": [
            {{"name": "dish name", "calories": 0, "protein_g": 0.0}}
        ],
        "total_calories": 0,
        "total_protein_g": 0.0,
        "total_carbs_g": 0.0,
        "total_fat_g": 0.0
    }},
    "daily_budget_remaining": {{"calories": 0, "protein_g": 0.0}},
    "tips": ["tip1", "tip2"]
}}"""

            else:
                # plate mode (default)
                if cache_name:
                    # Dynamic-only prompt (plate schema + guidelines are in cache)
                    prompt = f"""Analyze these food images and provide detailed nutrition estimates.
Identify all food items across all images.

Current time suggests this is likely {suggested_meal}.
{nutrition_ctx_str}{user_ctx_str}

Use the plate analysis JSON schema from your cached reference. Return valid JSON."""
                else:
                    prompt = f"""Analyze these food images and provide detailed nutrition estimates.
Identify all food items across all images.

Current time suggests this is likely {suggested_meal}.
{nutrition_ctx_str}{user_ctx_str}

Return ONLY valid JSON with this exact structure:
{{
    "analysis_type": "plate",
    "meal_type": "breakfast" | "lunch" | "dinner" | "snack",
    "food_items": [
        {{
            "name": "food name",
            "amount": "estimated amount (e.g., '1 cup', '150g')",
            "calories": 0,
            "protein_g": 0.0,
            "carbs_g": 0.0,
            "fat_g": 0.0
        }}
    ],
    "total_calories": 0,
    "total_protein_g": 0.0,
    "total_carbs_g": 0.0,
    "total_fat_g": 0.0,
    "total_fiber_g": 0.0,
    "health_score": 5,
    "feedback": "Brief coaching feedback"
}}

Guidelines:
- Be realistic with portion estimates
- Health score: 1-3 (poor), 4-6 (average), 7-8 (good), 9-10 (excellent)
- Feedback should be constructive and encouraging"""

            # Step 5: Call Gemini with all images
            gen_config = types.GenerateContentConfig(
                temperature=0.2,
                response_mime_type="application/json",
                max_output_tokens=4000,
            )
            if cache_name:
                gen_config.cached_content = cache_name

            logger.info(f"Multi-image food analysis: mode={analysis_mode}, cache={'yes' if cache_name else 'no'}")

            response = await client.aio.models.generate_content(
                model=self.model,
                contents=[prompt] + image_parts,
                config=gen_config,
            )

            content = response.text.strip()
            logger.info(f"Multi-image food analysis response received ({len(content)} chars)")
            result = json.loads(content)

            # Normalize plate mode results for compatibility
            if analysis_mode == "plate":
                result.setdefault("meal_type", suggested_meal)
                result.setdefault("food_items", [])
                result.setdefault("total_calories", 0)
                result.setdefault("total_protein_g", 0.0)
                result.setdefault("total_carbs_g", 0.0)
                result.setdefault("total_fat_g", 0.0)
                result.setdefault("total_fiber_g", 0.0)
                result.setdefault("health_score", 5)
                result.setdefault("feedback", "")
                # Add non-prefixed versions
                result["protein_g"] = result.get("total_protein_g", 0.0)
                result["carbs_g"] = result.get("total_carbs_g", 0.0)
                result["fat_g"] = result.get("total_fat_g", 0.0)
                result["fiber_g"] = result.get("total_fiber_g", 0.0)

            result["analysis_type"] = analysis_mode
            logger.info(f"Multi-image food analysis complete: mode={analysis_mode}")
            return result

        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse multi-image JSON response: {e}")
            raise ValueError(f"Invalid JSON in multi-image vision response: {e}")
        except Exception as e:
            logger.error(f"Multi-image food analysis failed: {e}")
            raise

    async def analyze_app_screenshot(
        self,
        image_base64: str = None,
        s3_key: str = None,
        mime_type: str = "image/jpeg",
        user_context: Optional[str] = None,
    ) -> dict:
        """
        Analyze a screenshot from a nutrition/fitness app (MyFitnessPal, Cronometer, etc.).
        OCR extracts food entries with calories and macros.
        """
        suggested_meal = self._get_suggested_meal_type()

        prompt = f"""You are an expert OCR system for nutrition app screenshots.
Analyze this screenshot from a nutrition/fitness tracking app.

TASKS:
1. Identify the source app (MyFitnessPal, Cronometer, LoseIt, Samsung Health, etc.)
2. Extract ALL food entries visible with their calories and macros
3. Determine the meal type from context or time-based suggestion: {suggested_meal}

{f'User says: "{user_context}"' if user_context else ''}

Return ONLY valid JSON with this exact structure:
{{
    "source_app": "app name or unknown",
    "meal_type": "breakfast" | "lunch" | "dinner" | "snack",
    "food_items": [
        {{
            "name": "food name",
            "amount": "amount as shown in app",
            "calories": <integer>,
            "protein_g": <float>,
            "carbs_g": <float>,
            "fat_g": <float>
        }}
    ],
    "total_calories": <integer>,
    "total_protein_g": <float>,
    "total_carbs_g": <float>,
    "total_fat_g": <float>,
    "total_fiber_g": <float>,
    "health_score": <integer 1-10>,
    "feedback": "Brief coaching feedback about the logged meals (2-3 sentences)"
}}

Guidelines:
- Extract exact values shown in the app when visible
- If macros are partially visible, estimate from calories and food type
- Health score based on overall meal quality
- Feedback should acknowledge the tracking effort and provide tips"""

        try:
            logger.info("Analyzing app screenshot with Gemini OCR")

            # Resolve image bytes
            if image_base64:
                image_bytes = base64.b64decode(image_base64)
            elif s3_key:
                image_bytes = await self._download_image_from_s3(s3_key)
            else:
                raise ValueError("Either image_base64 or s3_key must be provided")

            image_part = types.Part.from_bytes(data=image_bytes, mime_type=mime_type)

            response = await client.aio.models.generate_content(
                model=self.model,
                contents=[prompt, image_part],
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    max_output_tokens=4000,
                    temperature=0.2,
                ),
            )

            content = response.text.strip()
            result = json.loads(content)

            # Validate required fields
            for field in ["meal_type", "food_items", "total_calories", "total_protein_g", "total_carbs_g", "total_fat_g"]:
                if field not in result:
                    result[field] = self._get_default_value(field)

            result.setdefault("source_app", "unknown")
            result.setdefault("total_fiber_g", 0.0)
            result.setdefault("health_score", 5)
            result.setdefault("feedback", "")

            # Add non-prefixed versions for consistency
            result["protein_g"] = result.get("total_protein_g", 0.0)
            result["carbs_g"] = result.get("total_carbs_g", 0.0)
            result["fat_g"] = result.get("total_fat_g", 0.0)
            result["fiber_g"] = result.get("total_fiber_g", 0.0)

            logger.info(
                f"App screenshot analysis complete: {result['total_calories']} cal, "
                f"{len(result.get('food_items', []))} items from {result.get('source_app', 'unknown')}"
            )
            return result

        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse app screenshot JSON: {e}")
            raise ValueError(f"Invalid JSON in app screenshot response: {e}")
        except Exception as e:
            logger.error(f"App screenshot analysis failed: {e}")
            raise

    async def analyze_nutrition_label(
        self,
        image_base64: str = None,
        s3_key: str = None,
        mime_type: str = "image/jpeg",
        servings_consumed: float = 1.0,
        user_context: Optional[str] = None,
    ) -> dict:
        """
        Analyze a nutrition facts label from food packaging.
        Reads per-serving macros and multiplies by servings_consumed.
        """
        suggested_meal = self._get_suggested_meal_type()

        prompt = f"""You are an expert OCR system for nutrition facts labels.
Analyze this nutrition facts label from food packaging.

TASKS:
1. Read the product name if visible
2. Extract serving size and servings per container
3. Extract ALL nutrition facts per serving
4. The user consumed {servings_consumed} serving(s) - multiply all values accordingly

{f'User says: "{user_context}"' if user_context else ''}

Return ONLY valid JSON with this exact structure:
{{
    "product_name": "product name or unknown",
    "serving_size": "serving size as shown on label",
    "servings_per_container": <float or null>,
    "meal_type": "{suggested_meal}",
    "food_items": [
        {{
            "name": "product name",
            "amount": "{servings_consumed} serving(s)",
            "calories": <integer - per serving * {servings_consumed}>,
            "protein_g": <float - per serving * {servings_consumed}>,
            "carbs_g": <float - per serving * {servings_consumed}>,
            "fat_g": <float - per serving * {servings_consumed}>
        }}
    ],
    "total_calories": <integer - total for {servings_consumed} servings>,
    "total_protein_g": <float>,
    "total_carbs_g": <float>,
    "total_fat_g": <float>,
    "total_fiber_g": <float>,
    "health_score": <integer 1-10>,
    "feedback": "Brief coaching feedback about this food choice (2-3 sentences)"
}}

Guidelines:
- Read exact values from the label
- Multiply ALL values by {servings_consumed} servings consumed
- Health score based on nutritional quality
- Note high sodium, sugar, or trans fat if present in feedback"""

        try:
            logger.info(f"Analyzing nutrition label ({servings_consumed} servings) with Gemini OCR")

            # Resolve image bytes
            if image_base64:
                image_bytes = base64.b64decode(image_base64)
            elif s3_key:
                image_bytes = await self._download_image_from_s3(s3_key)
            else:
                raise ValueError("Either image_base64 or s3_key must be provided")

            image_part = types.Part.from_bytes(data=image_bytes, mime_type=mime_type)

            response = await client.aio.models.generate_content(
                model=self.model,
                contents=[prompt, image_part],
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    max_output_tokens=3000,
                    temperature=0.2,
                ),
            )

            content = response.text.strip()
            result = json.loads(content)

            # Validate required fields
            for field in ["meal_type", "food_items", "total_calories", "total_protein_g", "total_carbs_g", "total_fat_g"]:
                if field not in result:
                    result[field] = self._get_default_value(field)

            result.setdefault("product_name", "unknown")
            result.setdefault("serving_size", "unknown")
            result.setdefault("servings_per_container", None)
            result.setdefault("total_fiber_g", 0.0)
            result.setdefault("health_score", 5)
            result.setdefault("feedback", "")

            # Add non-prefixed versions for consistency
            result["protein_g"] = result.get("total_protein_g", 0.0)
            result["carbs_g"] = result.get("total_carbs_g", 0.0)
            result["fat_g"] = result.get("total_fat_g", 0.0)
            result["fiber_g"] = result.get("total_fiber_g", 0.0)

            logger.info(
                f"Nutrition label analysis complete: {result['total_calories']} cal "
                f"({servings_consumed} servings of {result.get('product_name', 'unknown')})"
            )
            return result

        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse nutrition label JSON: {e}")
            raise ValueError(f"Invalid JSON in nutrition label response: {e}")
        except Exception as e:
            logger.error(f"Nutrition label analysis failed: {e}")
            raise

    def _get_default_value(self, field: str):
        """Get default value for missing fields."""
        defaults = {
            "meal_type": "snack",
            "food_items": [],
            "total_calories": 0,
            "total_protein_g": 0.0,
            "total_carbs_g": 0.0,
            "total_fat_g": 0.0,
            "total_fiber_g": 0.0,
            "health_score": 5,
            "feedback": "Unable to fully analyze this image.",
        }
        return defaults.get(field)


# Singleton instance
_vision_service: Optional[VisionService] = None


def get_vision_service() -> VisionService:
    """Get the singleton VisionService instance."""
    global _vision_service
    if _vision_service is None:
        _vision_service = VisionService()
    return _vision_service
