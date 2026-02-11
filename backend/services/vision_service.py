"""
Vision Service for analyzing food images using Gemini Vision.

This service handles:
- Food image analysis for nutrition estimation
- Auto-detection of meal type based on time of day
- JSON-formatted nutrition responses
"""

import json
import base64
from datetime import datetime
from typing import Optional
from google import genai
from google.genai import types

from core.config import get_settings
from core.gemini_client import get_genai_client
from core.logger import get_logger
from models.gemini_schemas import FoodAnalysisResponse

logger = get_logger(__name__)
settings = get_settings()

# Initialize Gemini client
client = get_genai_client()


class VisionService:
    """Service for analyzing images using Gemini Vision."""

    def __init__(self):
        self.model = settings.gemini_model

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

        # Build the analysis prompt
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
            logger.info(f"🍽️ Analyzing food image with Gemini")

            # Decode base64 image data
            image_bytes = base64.b64decode(image_base64)

            # Create image part for Gemini using the new SDK
            image_part = types.Part.from_bytes(
                data=image_bytes,
                mime_type="image/jpeg"
            )

            # Generate content with image
            response = await client.aio.models.generate_content(
                model=self.model,
                contents=[prompt, image_part],
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    response_schema=FoodAnalysisResponse,
                    max_output_tokens=3000,  # Increased for thinking models
                    temperature=0.3,  # Lower temperature for more consistent nutrition estimates
                ),
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
