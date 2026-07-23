"""
Nutrition tracking tools for LangGraph agents.

Contains tools for analyzing food images, getting nutrition summaries,
logging food from text descriptions, and retrieving recent meals.
"""

from typing import Dict, Any, List, Optional
from datetime import datetime
import asyncio
import json

from langchain_core.tools import tool

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.nutrition_bias import apply_calorie_bias, get_user_calorie_bias
from core.timezone_utils import get_user_today, utc_to_local_date
from .base import get_vision_service, run_async_in_sync

logger = get_logger(__name__)


def _get_gemini_service():
    """Lazy import to avoid circular dependencies."""
    from services.gemini_service import GeminiService
    return GeminiService()


async def _bust_daily_summary_cache(user_id: str) -> None:
    """Invalidate the 60s GET /summary/daily cache after a chat-tool food write.

    Without this, the client's immediate `food_logged` refresh can be served
    the pre-log cached summary, which it then treats as fresh for 5 minutes —
    the "coach logged my meal but the Nutrition tab shows 0" bug. Best-effort:
    a cache failure must never fail the log itself.
    """
    try:
        from api.v1.nutrition.summaries import invalidate_daily_summary_cache
        await invalidate_daily_summary_cache(user_id)
    except Exception as e:
        logger.warning(f"daily-summary cache invalidation failed for {user_id}: {e}")


@tool
async def analyze_food_image(
    user_id: str,
    image_base64: str,
    user_message: str = None
) -> Dict[str, Any]:
    """
    Analyze a food image to estimate calories, macros, and nutritional content.

    Uses Gemini Vision to analyze the food in the image.

    Args:
        user_id: The user's ID (UUID string)
        image_base64: Base64 encoded image data (without data:image prefix)
        user_message: Optional context from the user about the meal

    Returns:
        Result dict with nutrition analysis, saved food log, and coaching feedback
    """
    logger.info(f"Tool: Analyzing food image for user {user_id}")

    try:
        db = get_supabase_db()
        vision_service = get_vision_service()

        # Get user's nutrition targets for context
        user = db.get_user(user_id)
        if user:
            user = db.enrich_user_with_nutrition_targets(user)
        user_context = None
        if user:
            targets = {
                "daily_calorie_target": user.get("daily_calorie_target"),
                "daily_protein_target_g": user.get("daily_protein_target_g"),
                "daily_carbs_target_g": user.get("daily_carbs_target_g"),
                "daily_fat_target_g": user.get("daily_fat_target_g"),
            }
            targets = {k: v for k, v in targets.items() if v is not None}
            if targets:
                user_context = f"User's nutrition targets: {json.dumps(targets)}"
            if user_message:
                user_context = f"{user_context or ''}\nUser says: {user_message}"

        # Analyze the image using Vision service (async — stays on main event loop)
        analysis_result = await asyncio.wait_for(
            vision_service.analyze_food_image(image_base64, user_context),
            timeout=90
        )

        # VisionService returns the result directly (not wrapped in success/data)
        if not analysis_result or not analysis_result.get("food_items"):
            return {
                "success": False,
                "action": "analyze_food_image",
                "user_id": user_id,
                "message": "Failed to analyze food image - no food items identified"
            }

        # Apply calorie estimate bias (AI estimates only)
        bias = await asyncio.wait_for(get_user_calorie_bias(user_id), timeout=10)
        if bias != 0:
            analysis_result = apply_calorie_bias(analysis_result, bias)

        # Extract nutrition data directly from the result
        # VisionService returns total_protein_g, total_carbs_g, etc.
        meal_type = analysis_result.get("meal_type", "snack")
        food_items = analysis_result.get("food_items", [])
        total_calories = analysis_result.get("total_calories", 0)
        protein_g = analysis_result.get("total_protein_g", 0) or analysis_result.get("protein_g", 0)
        carbs_g = analysis_result.get("total_carbs_g", 0) or analysis_result.get("carbs_g", 0)
        fat_g = analysis_result.get("total_fat_g", 0) or analysis_result.get("fat_g", 0)
        fiber_g = analysis_result.get("total_fiber_g", 0) or analysis_result.get("fiber_g", 0)
        health_score = analysis_result.get("health_score", 5)
        ai_feedback = analysis_result.get("feedback", "")

        # Format food items for response
        food_list = ", ".join([
            f"{item.get('name', 'Unknown')} ({item.get('amount', '')})"
            for item in food_items
        ])

        # Build response message
        message = (
            f"**{meal_type.title()} Analysis**\n\n"
            f"**Food Items:** {food_list}\n\n"
            f"**Nutrition:**\n"
            f"- Calories: {total_calories} kcal\n"
            f"- Protein: {protein_g}g\n"
            f"- Carbs: {carbs_g}g\n"
            f"- Fat: {fat_g}g\n"
            f"- Fiber: {fiber_g}g\n\n"
            f"**Health Score:** {health_score}/10\n\n"
            f"**Coach Feedback:** {ai_feedback}"
        )

        return {
            "success": True,
            "action": "analyze_food_image",
            "user_id": user_id,
            "meal_type": meal_type,
            "food_items": food_items,
            "total_calories": total_calories,
            "protein_g": protein_g,
            "carbs_g": carbs_g,
            "fat_g": fat_g,
            "fiber_g": fiber_g,
            "health_score": health_score,
            "ai_feedback": ai_feedback,
            "message": message
        }

    except asyncio.TimeoutError:
        logger.error(f"Food image analysis timed out after 90s for user {user_id}", exc_info=True)
        return {
            "success": False,
            "action": "analyze_food_image",
            "user_id": user_id,
            "message": "Food analysis timed out. Please try again."
        }
    except Exception as e:
        logger.error(f"Analyze food image failed: {e}", exc_info=True)
        return {
            "success": False,
            "action": "analyze_food_image",
            "user_id": user_id,
            "message": f"Failed to analyze food image: {str(e)}"
        }


@tool
async def analyze_multi_food_images(
    user_id: str,
    s3_keys: List[str],
    mime_types: List[str],
    user_message: Optional[str] = None,
    analysis_mode: str = "auto",
    timezone_str: str = "UTC",
) -> Dict[str, Any]:
    """
    Analyze multiple food images for nutrition estimation.
    Supports plates, buffets, and restaurant menus.

    Args:
        user_id: User's UUID
        s3_keys: List of S3 object keys for the images
        mime_types: List of MIME types for each image
        user_message: Optional user context
        analysis_mode: "auto", "plate", "buffet", or "menu"
        timezone_str: IANA timezone string for resolving "today" (e.g. "Asia/Kolkata")

    Returns:
        Nutrition analysis with food items, recommendations, and traffic-light ratings
    """
    logger.info(f"Tool: Analyzing {len(s3_keys)} food images for user {user_id}, mode={analysis_mode}")

    # Menu and buffet modes previously dispatched to background queue, but that created
    # a dead-end (no frontend polling). Now all modes run synchronously — the sync path
    # handles menu/buffet with a 90s timeout and returns formatted results directly.

    try:
        db = get_supabase_db()
        vision_service = get_vision_service()

        # Get user from DB for nutrition targets
        user = db.get_user(user_id)
        if user:
            user = db.enrich_user_with_nutrition_targets(user)
        nutrition_context = None
        if user:
            targets = {
                "daily_calorie_target": user.get("daily_calorie_target"),
                "daily_protein_target_g": user.get("daily_protein_target_g"),
                "daily_carbs_target_g": user.get("daily_carbs_target_g"),
                "daily_fat_target_g": user.get("daily_fat_target_g"),
            }
            targets = {k: v for k, v in targets.items() if v is not None}

            # Get today's nutrition summary for remaining budget. `today` is the
            # user's LOCAL date and logged_at is a UTC timestamptz, so the tz has
            # to travel with it — otherwise last night's dinner counts as today.
            today = get_user_today(timezone_str)
            daily_summary = db.get_daily_nutrition_summary(
                user_id, today, timezone_str=timezone_str
            )

            if targets:
                nutrition_context = {"targets": targets}
                if daily_summary and daily_summary.get("total_calories"):
                    consumed = {
                        "calories_consumed": daily_summary.get("total_calories", 0),
                        "protein_consumed_g": daily_summary.get("total_protein_g", 0),
                        "carbs_consumed_g": daily_summary.get("total_carbs_g", 0),
                        "fat_consumed_g": daily_summary.get("total_fat_g", 0),
                    }
                    remaining = {}
                    if targets.get("daily_calorie_target"):
                        remaining["calories"] = targets["daily_calorie_target"] - consumed["calories_consumed"]
                    if targets.get("daily_protein_target_g"):
                        remaining["protein_g"] = targets["daily_protein_target_g"] - consumed["protein_consumed_g"]
                    nutrition_context["consumed_today"] = consumed
                    nutrition_context["remaining"] = remaining

        # Call vision service for multi-image analysis
        analysis_result = await asyncio.wait_for(
            vision_service.analyze_food_from_s3_keys(
                s3_keys=s3_keys,
                mime_types=mime_types,
                user_context=user_message,
                analysis_mode=analysis_mode,
                nutrition_context=nutrition_context,
            ),
            timeout=90,
        )

        if not analysis_result:
            return {
                "success": False,
                "action": "analyze_multi_food_images",
                "user_id": user_id,
                "message": "Failed to analyze food images - no results returned",
            }

        actual_mode = analysis_result.get("analysis_type", analysis_mode)

        # For plate mode: apply calorie bias
        if actual_mode == "plate":
            # Apply calorie estimate bias
            bias = await asyncio.wait_for(get_user_calorie_bias(user_id), timeout=10)
            if bias != 0:
                analysis_result = apply_calorie_bias(analysis_result, bias)

            # Format plate mode message
            food_items = analysis_result.get("food_items", [])
            food_list = ", ".join([
                f"{item.get('name', 'Unknown')} ({item.get('amount', '')})"
                for item in food_items
            ])
            message = (
                f"**{analysis_result.get('meal_type', 'Meal').title()} Analysis**\n\n"
                f"**Food Items:** {food_list}\n\n"
                f"**Nutrition:**\n"
                f"- Calories: {analysis_result.get('total_calories', 0)} kcal\n"
                f"- Protein: {analysis_result.get('total_protein_g', 0)}g\n"
                f"- Carbs: {analysis_result.get('total_carbs_g', 0)}g\n"
                f"- Fat: {analysis_result.get('total_fat_g', 0)}g\n\n"
                f"**Health Score:** {analysis_result.get('health_score', 5)}/10\n\n"
                f"**Coach Feedback:** {analysis_result.get('feedback', '')}"
            )

        elif actual_mode == "buffet":
            # Format buffet mode message (do NOT auto-log)
            dishes = analysis_result.get("dishes", [])
            suggested_plate = analysis_result.get("suggested_plate", {})
            tips = analysis_result.get("tips", [])

            message = "**Buffet Analysis**\n\n"
            message += f"Found {len(dishes)} dishes:\n\n"
            for dish in dishes:
                rating_emoji = {"green": "+", "yellow": "~", "red": "-"}.get(dish.get("rating", "yellow"), "~")
                message += f"[{rating_emoji}] **{dish.get('name', 'Unknown')}** - {dish.get('calories', 0)} kcal ({dish.get('serving_description', '')})\n"
                message += f"    {dish.get('rating_reason', '')}\n"

            if suggested_plate and suggested_plate.get("items"):
                message += "\n**Suggested Plate:**\n"
                for item in suggested_plate["items"]:
                    message += f"- {item.get('name', '')} ({item.get('serving', '')}): {item.get('calories', 0)} kcal\n"
                message += f"\nTotal: {suggested_plate.get('total_calories', 0)} kcal, {suggested_plate.get('total_protein_g', 0):.1f}g protein\n"

            if tips:
                message += "\n**Tips:**\n"
                for tip in tips:
                    message += f"- {tip}\n"

        elif actual_mode == "menu":
            # Format menu mode message (do NOT auto-log)
            sections = analysis_result.get("sections", [])
            recommended = analysis_result.get("recommended_order", {})
            tips = analysis_result.get("tips", [])
            restaurant = analysis_result.get("restaurant_name")

            message = f"**Menu Analysis{f' - {restaurant}' if restaurant else ''}**\n\n"
            for section in sections:
                message += f"**{section.get('section_name', 'Section')}:**\n"
                for dish in section.get("dishes", []):
                    rating_emoji = {"green": "+", "yellow": "~", "red": "-"}.get(dish.get("rating", "yellow"), "~")
                    price_str = f" ({dish.get('price', '')})" if dish.get("price") else ""
                    message += f"  [{rating_emoji}] {dish.get('name', 'Unknown')}{price_str} - {dish.get('calories', 0)} kcal\n"
                message += "\n"

            if recommended and recommended.get("items"):
                message += "**Recommended Order:**\n"
                for item in recommended["items"]:
                    message += f"- {item.get('name', '')}: {item.get('calories', 0)} kcal\n"
                message += f"\nTotal: {recommended.get('total_calories', 0)} kcal, {recommended.get('total_protein_g', 0):.1f}g protein\n"

            if tips:
                message += "\n**Tips:**\n"
                for tip in tips:
                    message += f"- {tip}\n"
        else:
            message = json.dumps(analysis_result, indent=2)

        return {
            "success": True,
            "action": "analyze_multi_food_images",
            "analysis_type": actual_mode,
            "user_id": user_id,
            "result": analysis_result,
            "message": message,
        }

    except asyncio.TimeoutError:
        logger.error(f"Multi food image analysis timed out for user {user_id}", exc_info=True)
        return {
            "success": False,
            "action": "analyze_multi_food_images",
            "user_id": user_id,
            "message": "Food analysis timed out. Please try again.",
        }
    except Exception as e:
        logger.error(f"Analyze multi food images failed: {e}", exc_info=True)
        return {
            "success": False,
            "action": "analyze_multi_food_images",
            "user_id": user_id,
            "message": f"Failed to analyze food images: {str(e)}",
        }


@tool
async def parse_app_screenshot(
    user_id: str,
    s3_keys: List[str] = None,
    mime_types: List[str] = None,
    image_base64: str = None,
    user_message: str = None,
    timezone_str: str = "UTC",
) -> Dict[str, Any]:
    """
    Parse a screenshot from a nutrition app (MyFitnessPal, Cronometer, etc.).
    Extracts food items, calories, macros via OCR and saves to food log.
    Use when user sends a screenshot of a nutrition/fitness tracking app.

    Args:
        user_id: The user's ID (UUID string)
        s3_keys: List of S3 object keys for the screenshot images
        mime_types: List of MIME types for each image
        image_base64: Base64 encoded image data (alternative to s3_keys)
        user_message: Optional context from the user

    Returns:
        Result dict with parsed nutrition data and saved food log
    """
    logger.info(f"Tool: Parsing app screenshot for user {user_id}")

    try:
        db = get_supabase_db()
        vision_service = get_vision_service()

        # Resolve image source
        s3_key = s3_keys[0] if s3_keys else None
        mime_type = mime_types[0] if mime_types else "image/jpeg"

        # Analyze the screenshot
        analysis_result = await asyncio.wait_for(
            vision_service.analyze_app_screenshot(
                image_base64=image_base64,
                s3_key=s3_key,
                mime_type=mime_type,
                user_context=user_message,
            ),
            timeout=60,
        )

        if not analysis_result or not analysis_result.get("food_items"):
            return {
                "success": False,
                "action": "parse_app_screenshot",
                "user_id": user_id,
                "message": "Could not extract food entries from the screenshot. Please try a clearer image.",
            }

        # Apply calorie bias
        bias = await asyncio.wait_for(get_user_calorie_bias(user_id), timeout=10)
        if bias != 0:
            analysis_result = apply_calorie_bias(analysis_result, bias)

        # Extract nutrition data
        meal_type = analysis_result.get("meal_type", "snack")
        food_items = analysis_result.get("food_items", [])
        total_calories = analysis_result.get("total_calories", 0)
        protein_g = analysis_result.get("total_protein_g", 0) or analysis_result.get("protein_g", 0)
        carbs_g = analysis_result.get("total_carbs_g", 0) or analysis_result.get("carbs_g", 0)
        fat_g = analysis_result.get("total_fat_g", 0) or analysis_result.get("fat_g", 0)
        fiber_g = analysis_result.get("total_fiber_g", 0) or analysis_result.get("fiber_g", 0)
        health_score = analysis_result.get("health_score", 5)
        ai_feedback = analysis_result.get("feedback", "")
        source_app = analysis_result.get("source_app", "unknown")

        # Apply per-user food overrides so chat-logged meals learn from the
        # user's past cal/P/C/F corrections (same as the /log-* endpoints).
        from services.food_override_service import apply_user_food_overrides
        food_items, _override_totals, _n_overridden = apply_user_food_overrides(
            db, user_id, food_items,
        )
        if _n_overridden:
            logger.info(f"[parse_app_screenshot] Applied {_n_overridden} override(s) for {user_id}")
            total_calories = _override_totals["total_calories"]
            protein_g = _override_totals["protein_g"]
            carbs_g = _override_totals["carbs_g"]
            fat_g = _override_totals["fat_g"]

        # Save to database
        food_log = db.create_food_log(
            user_id=user_id,
            meal_type=meal_type,
            food_items=food_items,
            total_calories=total_calories,
            protein_g=protein_g,
            carbs_g=carbs_g,
            fat_g=fat_g,
            fiber_g=fiber_g,
            health_score=health_score,
            ai_feedback=ai_feedback,
            source_type="image",
            input_type="chat",
            user_query=user_message if user_message else None,
        )

        food_log_id = food_log.get("id") if food_log else None
        await _bust_daily_summary_cache(user_id)

        # Get daily summary — `today` is the user's LOCAL date, so the summary
        # must bound the day in that same tz (logged_at is UTC).
        today = get_user_today(timezone_str)
        daily_summary = db.get_daily_nutrition_summary(
            user_id, today, timezone_str=timezone_str
        )

        # Format response
        food_list = ", ".join([
            f"{item.get('name', 'Unknown')} ({item.get('amount', '')})"
            for item in food_items
        ])

        message = (
            f"**Screenshot Imported from {source_app.title()}!**\n\n"
            f"**Food Items:** {food_list}\n\n"
            f"**Nutrition:**\n"
            f"- Calories: {total_calories} kcal\n"
            f"- Protein: {protein_g}g\n"
            f"- Carbs: {carbs_g}g\n"
            f"- Fat: {fat_g}g\n"
            f"- Fiber: {fiber_g}g\n\n"
            f"**Health Score:** {health_score}/10\n\n"
            f"**Coach Feedback:** {ai_feedback}"
        )

        if daily_summary and daily_summary.get("total_calories"):
            message += (
                f"\n\n**Today's Total:**\n"
                f"- Calories: {daily_summary.get('total_calories', 0)} kcal\n"
                f"- Protein: {daily_summary.get('total_protein_g', 0):.1f}g\n"
                f"- Carbs: {daily_summary.get('total_carbs_g', 0):.1f}g\n"
                f"- Fat: {daily_summary.get('total_fat_g', 0):.1f}g"
            )

        return {
            "success": True,
            "action": "parse_app_screenshot",
            "user_id": user_id,
            "food_log_id": food_log_id,
            "meal_type": meal_type,
            "food_items": food_items,
            "total_calories": total_calories,
            "protein_g": protein_g,
            "carbs_g": carbs_g,
            "fat_g": fat_g,
            "fiber_g": fiber_g,
            "health_score": health_score,
            "source_app": source_app,
            "daily_summary": daily_summary,
            "message": message,
        }

    except Exception as e:
        logger.error(f"Parse app screenshot failed: {e}", exc_info=True)
        return {
            "success": False,
            "action": "parse_app_screenshot",
            "user_id": user_id,
            "message": f"Failed to parse app screenshot: {str(e)}",
        }


@tool
async def parse_nutrition_label(
    user_id: str,
    s3_keys: List[str] = None,
    mime_types: List[str] = None,
    image_base64: str = None,
    servings_consumed: float = 1.0,
    user_message: str = None,
    timezone_str: str = "UTC",
) -> Dict[str, Any]:
    """
    Parse a nutrition facts label from food packaging.
    Reads per-serving macros, multiplies by servings_consumed, and saves to food log.
    Use when user sends a photo of a nutrition label on packaging.

    Args:
        user_id: The user's ID (UUID string)
        s3_keys: List of S3 object keys for the label images
        mime_types: List of MIME types for each image
        image_base64: Base64 encoded image data (alternative to s3_keys)
        servings_consumed: Number of servings eaten (default 1.0)
        user_message: Optional context from the user

    Returns:
        Result dict with parsed nutrition data and saved food log
    """
    logger.info(f"Tool: Parsing nutrition label for user {user_id} ({servings_consumed} servings)")

    try:
        db = get_supabase_db()
        vision_service = get_vision_service()

        # Resolve image source
        s3_key = s3_keys[0] if s3_keys else None
        mime_type = mime_types[0] if mime_types else "image/jpeg"

        # Analyze the nutrition label
        analysis_result = await asyncio.wait_for(
            vision_service.analyze_nutrition_label(
                image_base64=image_base64,
                s3_key=s3_key,
                mime_type=mime_type,
                servings_consumed=servings_consumed,
                user_context=user_message,
            ),
            timeout=60,
        )

        if not analysis_result or not analysis_result.get("food_items"):
            return {
                "success": False,
                "action": "parse_nutrition_label",
                "user_id": user_id,
                "message": "Could not read the nutrition label. Please try a clearer photo.",
            }

        # Apply calorie bias
        bias = await asyncio.wait_for(get_user_calorie_bias(user_id), timeout=10)
        if bias != 0:
            analysis_result = apply_calorie_bias(analysis_result, bias)

        # Extract nutrition data
        meal_type = analysis_result.get("meal_type", "snack")
        food_items = analysis_result.get("food_items", [])
        total_calories = analysis_result.get("total_calories", 0)
        protein_g = analysis_result.get("total_protein_g", 0) or analysis_result.get("protein_g", 0)
        carbs_g = analysis_result.get("total_carbs_g", 0) or analysis_result.get("carbs_g", 0)
        fat_g = analysis_result.get("total_fat_g", 0) or analysis_result.get("fat_g", 0)
        fiber_g = analysis_result.get("total_fiber_g", 0) or analysis_result.get("fiber_g", 0)
        health_score = analysis_result.get("health_score", 5)
        ai_feedback = analysis_result.get("feedback", "")
        product_name = analysis_result.get("product_name", "unknown")
        serving_size = analysis_result.get("serving_size", "unknown")

        # Apply per-user food overrides — nutrition-label scans benefit just
        # as much as photo logs when the user has corrected a branded item.
        from services.food_override_service import apply_user_food_overrides
        food_items, _override_totals, _n_overridden = apply_user_food_overrides(
            db, user_id, food_items,
        )
        if _n_overridden:
            logger.info(f"[parse_nutrition_label] Applied {_n_overridden} override(s) for {user_id}")
            total_calories = _override_totals["total_calories"]
            protein_g = _override_totals["protein_g"]
            carbs_g = _override_totals["carbs_g"]
            fat_g = _override_totals["fat_g"]

        # Save to database
        food_log = db.create_food_log(
            user_id=user_id,
            meal_type=meal_type,
            food_items=food_items,
            total_calories=total_calories,
            protein_g=protein_g,
            carbs_g=carbs_g,
            fat_g=fat_g,
            fiber_g=fiber_g,
            health_score=health_score,
            ai_feedback=ai_feedback,
            source_type="image",
            input_type="chat",
            user_query=product_name if product_name and product_name != "unknown" else (user_message if user_message else None),
        )

        food_log_id = food_log.get("id") if food_log else None
        await _bust_daily_summary_cache(user_id)

        # Get daily summary — `today` is the user's LOCAL date, so the summary
        # must bound the day in that same tz (logged_at is UTC).
        today = get_user_today(timezone_str)
        daily_summary = db.get_daily_nutrition_summary(
            user_id, today, timezone_str=timezone_str
        )

        # Format response
        servings_str = f" ({servings_consumed} servings)" if servings_consumed != 1.0 else ""
        message = (
            f"**Nutrition Label Logged: {product_name.title()}{servings_str}**\n\n"
            f"**Serving Size:** {serving_size}\n\n"
            f"**Nutrition:**\n"
            f"- Calories: {total_calories} kcal\n"
            f"- Protein: {protein_g}g\n"
            f"- Carbs: {carbs_g}g\n"
            f"- Fat: {fat_g}g\n"
            f"- Fiber: {fiber_g}g\n\n"
            f"**Health Score:** {health_score}/10\n\n"
            f"**Coach Feedback:** {ai_feedback}"
        )

        if daily_summary and daily_summary.get("total_calories"):
            message += (
                f"\n\n**Today's Total:**\n"
                f"- Calories: {daily_summary.get('total_calories', 0)} kcal\n"
                f"- Protein: {daily_summary.get('total_protein_g', 0):.1f}g\n"
                f"- Carbs: {daily_summary.get('total_carbs_g', 0):.1f}g\n"
                f"- Fat: {daily_summary.get('total_fat_g', 0):.1f}g"
            )

        return {
            "success": True,
            "action": "parse_nutrition_label",
            "user_id": user_id,
            "food_log_id": food_log_id,
            "meal_type": meal_type,
            "food_items": food_items,
            "total_calories": total_calories,
            "protein_g": protein_g,
            "carbs_g": carbs_g,
            "fat_g": fat_g,
            "fiber_g": fiber_g,
            "health_score": health_score,
            "product_name": product_name,
            "serving_size": serving_size,
            "daily_summary": daily_summary,
            "message": message,
        }

    except Exception as e:
        logger.error(f"Parse nutrition label failed: {e}", exc_info=True)
        return {
            "success": False,
            "action": "parse_nutrition_label",
            "user_id": user_id,
            "message": f"Failed to parse nutrition label: {str(e)}",
        }


@tool
def get_nutrition_summary(
    user_id: str,
    date: str = None,
    period: str = "day",
    timezone_str: str = "UTC",
) -> Dict[str, Any]:
    """
    Get a nutrition summary for a user for a specific day or week.

    Args:
        user_id: The user's ID (UUID string)
        date: Date to get summary for (YYYY-MM-DD format). Defaults to today.
        period: "day" for daily summary, "week" for weekly summary
        timezone_str: IANA timezone string for resolving "today" (e.g. "Asia/Kolkata")

    Returns:
        Result dict with nutrition totals and meal breakdown
    """
    logger.info(f"Tool: Getting nutrition summary for user {user_id}, period: {period}")

    try:
        db = get_supabase_db()

        if date is None:
            date = get_user_today(timezone_str)

        # `date` is a LOCAL calendar date (either supplied by the agent or
        # resolved above from the user's tz). Both summary helpers slice a UTC
        # `logged_at` column, so the tz must travel with the date — otherwise
        # every day in the window starts/ends at the wrong wall-clock moment.
        if period == "week":
            summary = db.get_weekly_nutrition_summary(
                user_id, date, timezone_str=timezone_str
            )

            if not summary:
                return {
                    "success": True,
                    "action": "get_nutrition_summary",
                    "user_id": user_id,
                    "period": "week",
                    "summary": [],
                    "message": "No meals logged this week yet."
                }

            total_calories = sum(day.get("total_calories", 0) or 0 for day in summary)
            avg_calories = total_calories / len(summary) if summary else 0

            message = (
                f"**Weekly Nutrition Summary**\n"
                f"(Starting {date})\n\n"
                f"**Average Daily Intake:**\n"
                f"- Calories: {avg_calories:.0f} kcal\n"
                f"- Meals logged: {sum(day.get('meal_count', 0) for day in summary)} total\n"
            )

            return {
                "success": True,
                "action": "get_nutrition_summary",
                "user_id": user_id,
                "period": "week",
                "start_date": date,
                "daily_summaries": summary,
                "total_calories": total_calories,
                "average_daily_calories": avg_calories,
                "message": message
            }

        else:
            summary = db.get_daily_nutrition_summary(
                user_id, date, timezone_str=timezone_str
            )

            if not summary or not summary.get("total_calories"):
                return {
                    "success": True,
                    "action": "get_nutrition_summary",
                    "user_id": user_id,
                    "period": "day",
                    "date": date,
                    "summary": None,
                    "message": f"No meals logged for {date} yet."
                }

            message = (
                f"**Daily Nutrition Summary for {date}**\n\n"
                f"**Total Intake:**\n"
                f"- Calories: {summary.get('total_calories', 0)} kcal\n"
                f"- Protein: {summary.get('total_protein_g', 0):.1f}g\n"
                f"- Carbs: {summary.get('total_carbs_g', 0):.1f}g\n"
                f"- Fat: {summary.get('total_fat_g', 0):.1f}g\n"
                f"- Fiber: {summary.get('total_fiber_g', 0):.1f}g\n\n"
                f"**Meals Logged:** {summary.get('meal_count', 0)}\n"
                f"**Avg Health Score:** {summary.get('avg_health_score', 0):.1f}/10"
            )

            return {
                "success": True,
                "action": "get_nutrition_summary",
                "user_id": user_id,
                "period": "day",
                "date": date,
                "summary": summary,
                "message": message
            }

    except Exception as e:
        logger.error(f"Get nutrition summary failed: {e}", exc_info=True)
        return {
            "success": False,
            "action": "get_nutrition_summary",
            "user_id": user_id,
            "message": f"Failed to get nutrition summary: {str(e)}"
        }


@tool
def get_recent_meals(
    user_id: str,
    limit: int = 5,
    timezone_str: str = "UTC",
) -> Dict[str, Any]:
    """
    Get the user's recent meal logs.

    Args:
        user_id: The user's ID (UUID string)
        limit: Maximum number of meals to return (default 5)
        timezone_str: IANA timezone string used to date-stamp each meal in the
                      user's own calendar (e.g. "America/Chicago")

    Returns:
        Result dict with list of recent meals
    """
    logger.info(f"Tool: Getting recent meals for user {user_id}")

    try:
        db = get_supabase_db()

        meals = db.list_food_logs(user_id, limit=limit)

        if not meals:
            return {
                "success": True,
                "action": "get_recent_meals",
                "user_id": user_id,
                "meals": [],
                "message": "No meals logged yet. Send me a photo of your food to start tracking!"
            }

        meal_list = []
        for meal in meals:
            # logged_at is a UTC timestamptz — slicing the raw string stamps a
            # 9pm-local meal with TOMORROW's date in the list we read back to
            # the user. Bucket into the user's local calendar day instead.
            logged_at = utc_to_local_date(meal.get("logged_at"), timezone_str)

            food_items = meal.get("food_items", [])
            food_names = ", ".join([
                item.get("name", "Unknown") for item in food_items[:3]
            ])
            if len(food_items) > 3:
                food_names += f" +{len(food_items) - 3} more"

            meal_list.append({
                "id": meal.get("id"),
                "date": logged_at,
                "meal_type": meal.get("meal_type"),
                "food_items": food_names,
                "calories": meal.get("total_calories"),
                "health_score": meal.get("health_score")
            })

        message = f"**Recent Meals ({len(meals)}):**\n\n"
        for m in meal_list:
            message += (
                f"- **{m['meal_type'].title()}** ({m['date']}): "
                f"{m['food_items']} - {m['calories']} kcal\n"
            )

        return {
            "success": True,
            "action": "get_recent_meals",
            "user_id": user_id,
            "meals": meal_list,
            "count": len(meal_list),
            "message": message
        }

    except Exception as e:
        logger.error(f"Get recent meals failed: {e}", exc_info=True)
        return {
            "success": False,
            "action": "get_recent_meals",
            "user_id": user_id,
            "message": f"Failed to get recent meals: {str(e)}"
        }


@tool
async def log_food_from_text(
    user_id: str,
    food_description: str,
    meal_type: str = None,
    timezone_str: str = "UTC",
) -> Dict[str, Any]:
    """
    Log food from a text description. Use this when the user describes what they ate.

    This tool parses the food description, estimates calories and macros,
    saves it to the database, and provides coaching feedback.

    Args:
        user_id: The user's ID (UUID string)
        food_description: Natural language description of the food eaten
                         (e.g., "I ate thalapakattu mutton biryani" or "2 eggs and toast")
        meal_type: Optional meal type (breakfast, lunch, dinner, snack). Auto-detected if not provided.
        timezone_str: IANA timezone string for resolving "today" and meal-type auto-detection (e.g. "Asia/Kolkata")

    Returns:
        Result dict with nutrition analysis, saved food log, and coaching feedback
    """
    logger.info(f"Tool: Logging food from text for user {user_id}: {food_description[:50]}...")

    try:
        db = get_supabase_db()
        gemini_service = _get_gemini_service()

        # Get user's nutrition targets and goals for context
        user = db.get_user(user_id)
        if user:
            user = db.enrich_user_with_nutrition_targets(user)
        user_goals = []
        nutrition_targets = {}

        if user:
            # Get goals from user profile
            if user.get("fitness_goals"):
                user_goals = user.get("fitness_goals", [])

            # Get nutrition targets (enriched from nutrition_preferences)
            nutrition_targets = {
                "daily_calorie_target": user.get("daily_calorie_target"),
                "daily_protein_target_g": user.get("daily_protein_target_g"),
                "daily_carbs_target_g": user.get("daily_carbs_target_g"),
                "daily_fat_target_g": user.get("daily_fat_target_g"),
            }
            nutrition_targets = {k: v for k, v in nutrition_targets.items() if v is not None}

        # Parse the food description using Gemini
        analysis_result = await asyncio.wait_for(
            gemini_service.parse_food_description(
                description=food_description,
                user_goals=user_goals if user_goals else None,
                nutrition_targets=nutrition_targets if nutrition_targets else None
            ),
            timeout=60
        )

        if not analysis_result or not analysis_result.get("food_items"):
            return {
                "success": False,
                "action": "log_food_from_text",
                "user_id": user_id,
                "message": "I couldn't identify the food you mentioned. Could you describe it more specifically?"
            }

        # Apply calorie estimate bias (AI estimates only)
        bias = await asyncio.wait_for(get_user_calorie_bias(user_id), timeout=10)
        if bias != 0:
            analysis_result = apply_calorie_bias(analysis_result, bias)

        # Extract nutrition data
        food_items = analysis_result.get("food_items", [])
        total_calories = analysis_result.get("total_calories", 0)
        protein_g = analysis_result.get("protein_g", 0)
        carbs_g = analysis_result.get("carbs_g", 0)
        fat_g = analysis_result.get("fat_g", 0)
        fiber_g = analysis_result.get("fiber_g", 0)
        health_score = analysis_result.get("overall_meal_score") or analysis_result.get("health_score", 5)
        ai_feedback = analysis_result.get("ai_suggestion", "")

        # Auto-detect meal type based on user's local time if not provided
        if not meal_type:
            from zoneinfo import ZoneInfo
            try:
                user_tz = ZoneInfo(timezone_str)
            except Exception:
                user_tz = ZoneInfo("UTC")
            hour = datetime.now(user_tz).hour
            if 5 <= hour < 11:
                meal_type = "breakfast"
            elif 11 <= hour < 15:
                meal_type = "lunch"
            elif 15 <= hour < 18:
                meal_type = "snack"
            else:
                meal_type = "dinner"

        # Apply per-user food overrides — coach-chat auto-logs need to honor
        # the user's corrections just like the /log-* endpoints.
        from services.food_override_service import apply_user_food_overrides
        food_items, _override_totals, _n_overridden = apply_user_food_overrides(
            db, user_id, food_items,
        )
        if _n_overridden:
            logger.info(f"[log_food_from_text] Applied {_n_overridden} override(s) for {user_id}")
            total_calories = _override_totals["total_calories"]
            protein_g = _override_totals["protein_g"]
            carbs_g = _override_totals["carbs_g"]
            fat_g = _override_totals["fat_g"]

        # F5 — persist micronutrients estimated by Gemini (parse_food_description
        # uses the FoodAnalysisResponse schema, which carries the full RDA-tracked
        # micro set). Previously the chat-logging tool dropped these, so a meal
        # logged via the coach showed 0/28 micros. Additive — macros unchanged.
        _MICRO_KEYS = [
            'sodium_mg', 'sugar_g', 'saturated_fat_g', 'cholesterol_mg', 'potassium_mg',
            'vitamin_a_ug', 'vitamin_c_mg', 'vitamin_d_iu', 'vitamin_e_mg', 'vitamin_k_ug',
            'vitamin_b1_mg', 'vitamin_b2_mg', 'vitamin_b3_mg', 'vitamin_b6_mg',
            'vitamin_b9_ug', 'vitamin_b12_ug', 'choline_mg',
            'calcium_mg', 'iron_mg', 'magnesium_mg', 'zinc_mg', 'selenium_ug',
            'phosphorus_mg', 'copper_mg', 'manganese_mg', 'iodine_ug',
            'omega3_g', 'omega6_g', 'caffeine_mg', 'added_sugar_g',
        ]
        micronutrients = {}
        for _k in _MICRO_KEYS:
            _v = analysis_result.get(_k)
            if _v is not None:
                try:
                    micronutrients[_k] = float(_v)
                except (TypeError, ValueError):
                    pass

        # Save to database
        food_log = db.create_food_log(
            user_id=user_id,
            meal_type=meal_type,
            food_items=food_items,
            total_calories=total_calories,
            protein_g=protein_g,
            carbs_g=carbs_g,
            fat_g=fat_g,
            fiber_g=fiber_g,
            health_score=health_score,
            ai_feedback=ai_feedback,
            source_type="text",
            input_type="chat",
            user_query=food_description,
            **micronutrients,
        )

        food_log_id = food_log.get("id") if food_log else None
        await _bust_daily_summary_cache(user_id)

        # Get today's nutrition summary — `today` is the user's LOCAL date, so
        # the summary has to bound the day in that same tz (logged_at is UTC).
        # Without it the "Today's Total" line we echo back double-counts the
        # previous evening's meals.
        today = get_user_today(timezone_str)
        daily_summary = db.get_daily_nutrition_summary(
            user_id, today, timezone_str=timezone_str
        )

        # Format food items for response
        food_list = ", ".join([
            f"{item.get('name', 'Unknown')} ({item.get('amount', '')})"
            for item in food_items
        ])

        # Build response message
        message = (
            f"**{meal_type.title()} Logged!**\n\n"
            f"**Food:** {food_list}\n\n"
            f"**Nutrition:**\n"
            f"- Calories: {total_calories} kcal\n"
            f"- Protein: {protein_g}g\n"
            f"- Carbs: {carbs_g}g\n"
            f"- Fat: {fat_g}g\n"
            f"- Fiber: {fiber_g}g\n\n"
            f"**Health Score:** {health_score}/10\n\n"
        )

        if ai_feedback:
            message += f"**Coach Feedback:** {ai_feedback}\n"

        if daily_summary and daily_summary.get("total_calories"):
            remaining_calories = nutrition_targets.get("daily_calorie_target", 2000) - daily_summary.get("total_calories", 0)
            message += (
                f"\n**Today's Total:**\n"
                f"- Calories: {daily_summary.get('total_calories', 0)} kcal"
            )
            if nutrition_targets.get("daily_calorie_target"):
                message += f" / {nutrition_targets['daily_calorie_target']} kcal target"
                if remaining_calories > 0:
                    message += f"\n- Remaining: {remaining_calories} kcal"

        return {
            "success": True,
            "action": "log_food_from_text",
            "user_id": user_id,
            "food_log_id": food_log_id,
            "meal_type": meal_type,
            "food_items": food_items,
            "total_calories": total_calories,
            "protein_g": protein_g,
            "carbs_g": carbs_g,
            "fat_g": fat_g,
            "fiber_g": fiber_g,
            "health_score": health_score,
            "ai_feedback": ai_feedback,
            "daily_summary": daily_summary,
            "message": message
        }

    except Exception as e:
        logger.error(f"Log food from text failed: {e}", exc_info=True)
        return {
            "success": False,
            "action": "log_food_from_text",
            "user_id": user_id,
            "message": f"Failed to log food: {str(e)}"
        }


# ───────────────────────────────────────────────────────────────────────────
# Context tools for freeform queries (preset pills pre-fetch context via
# _build_agent_state; these @tool wrappers are for when the agent decides
# mid-conversation that it needs the same info).
# ───────────────────────────────────────────────────────────────────────────

@tool
def get_calorie_remainder(
    user_id: str,
    timezone_str: str = "UTC",
) -> Dict[str, Any]:
    """
    Get how many calories and macros the user has left for TODAY.

    Use this tool when the user asks about remaining budget, "can I eat this?",
    "how much room do I have left?", or "am I over?". Returns the day's total
    consumed vs. target plus per-macro remainders.

    Args:
        user_id: User's UUID
        timezone_str: IANA timezone (e.g., "America/Chicago")

    Returns:
        Dict with calorie_remainder, macros_remaining, over_budget, and the
        underlying consumed/target totals.
    """
    try:
        from services.langgraph_agents.tools.nutrition_context_helpers import (
            fetch_daily_nutrition_context,
        )
        ctx = run_async_in_sync(fetch_daily_nutrition_context(user_id, timezone_str))
        return {
            "success": True,
            "action": "get_calorie_remainder",
            "user_id": user_id,
            **ctx,
        }
    except Exception as e:
        logger.error(f"get_calorie_remainder failed: {e}", exc_info=True)
        return {
            "success": False,
            "action": "get_calorie_remainder",
            "user_id": user_id,
            "message": f"Failed to compute remainder: {str(e)}",
        }


@tool
def get_favorite_foods(
    user_id: str,
    limit: int = 5,
    exclude_days: int = 0,
) -> Dict[str, Any]:
    """
    Return the user's saved/favorite foods ordered by how often they've logged them.

    Use this tool when the user asks "what should I eat?", "suggest a favorite",
    or "something I've had before?". Set `exclude_days=7` to bias toward
    favorites they haven't eaten in the past week.

    Args:
        user_id: User's UUID
        limit: Max number of favorites to return (default 5)
        exclude_days: If >0, skip favorites logged within the last N days

    Returns:
        Dict with a "favorites" list ordered by times_logged desc.
    """
    try:
        from services.langgraph_agents.tools.nutrition_context_helpers import (
            fetch_recent_favorites,
        )
        favs = run_async_in_sync(fetch_recent_favorites(user_id, limit=limit, exclude_days=exclude_days))
        return {
            "success": True,
            "action": "get_favorite_foods",
            "user_id": user_id,
            "favorites": favs,
            "count": len(favs),
            "message": (
                f"User has {len(favs)} saved favorite(s)."
                if favs else "User has no saved favorites yet."
            ),
        }
    except Exception as e:
        logger.error(f"get_favorite_foods failed: {e}", exc_info=True)
        return {
            "success": False,
            "action": "get_favorite_foods",
            "user_id": user_id,
            "message": f"Failed to load favorites: {str(e)}",
        }


@tool
def get_todays_workout_for_meal(
    user_id: str,
    timezone_str: str = "UTC",
) -> Dict[str, Any]:
    """
    Get today's scheduled workout for meal-timing reasoning.

    Use this tool to answer "what should I eat before/after my workout?" or
    "is today a workout day?". Returns the workout name, type, scheduled time,
    and completion status — or a rest-day marker when nothing is scheduled.

    Note: this is the NUTRITION agent's workout-lookup. The workout agent has
    its own (richer) workout tool; they intentionally have different names to
    avoid tool-binding conflicts.

    Args:
        user_id: User's UUID
        timezone_str: IANA timezone

    Returns:
        Dict with a "workout" key (or null) plus a "rest_day" bool.
    """
    try:
        from services.langgraph_agents.tools.nutrition_context_helpers import (
            fetch_todays_workout,
        )
        w = run_async_in_sync(fetch_todays_workout(user_id, timezone_str))
        if w is None:
            return {
                "success": True,
                "action": "get_todays_workout_for_meal",
                "user_id": user_id,
                "workout": None,
                "rest_day": True,
                "message": "Today is a rest day.",
            }
        return {
            "success": True,
            "action": "get_todays_workout_for_meal",
            "user_id": user_id,
            "workout": w,
            "rest_day": False,
            "message": f"Today's workout: {w.get('name')} ({w.get('type')}).",
        }
    except Exception as e:
        logger.error(f"get_todays_workout_for_meal failed: {e}", exc_info=True)
        return {
            "success": False,
            "action": "get_todays_workout_for_meal",
            "user_id": user_id,
            "message": f"Failed to load workout: {str(e)}",
        }


def _fetch_disliked_foods(db, user_id: str) -> List[str]:
    """Best-effort read of foods the user has told the coach they dislike.

    Reads ACTIVE `coach_memory` preference rows (migration 2217) and keeps the
    content phrases that signal a dislike. Conservative: returns short food-ish
    tokens only. Any failure (table absent on an env where the coach-memory
    branch isn't merged) returns [] — the tool still respects allergens +
    dietary restrictions, which are the safety-critical constraints."""
    out: List[str] = []
    try:
        resp = (
            db.client.table("coach_memory")
            .select("content, category, status")
            .eq("user_id", user_id)
            .eq("category", "preference")
            .eq("status", "active")
            .limit(50)
            .execute()
        )
        _DISLIKE_CUES = ("dislike", "don't like", "doesnt like", "doesn't like",
                         "hate", "hates", "avoid", "avoids", "won't eat",
                         "wont eat", "allergic", "no ", "not a fan")
        for row in (resp.data or []):
            content = (row.get("content") or "").strip().lower()
            if not content:
                continue
            if any(cue in content for cue in _DISLIKE_CUES):
                # Strip the cue verb to leave the food-ish remainder.
                food = content
                for cue in ("dislikes ", "dislike ", "doesn't like ", "doesnt like ",
                            "hates ", "hate ", "avoids ", "avoid ", "won't eat ",
                            "wont eat ", "not a fan of "):
                    if cue in food:
                        food = food.split(cue, 1)[1]
                        break
                food = food.strip(" .,:;")
                if 2 <= len(food) <= 40:
                    out.append(food)
    except Exception as e:
        logger.debug(f"[recommend_meal] dislikes read skipped for {user_id}: {e}")
    return out[:20]


@tool
def recommend_meal(
    user_id: str,
    meal_type: Optional[str] = None,
    timezone_str: str = "UTC",
) -> Dict[str, Any]:
    """
    Recommend ONE concrete meal that fits the user's REMAINING macros for today.

    Use this tool whenever the user asks "what should I eat?", "fill my macros",
    "suggest a meal/dinner/lunch", "what fits my remaining calories?", or similar.
    Do NOT free-generate a meal in prose — call this so the recommendation
    respects the user's allergens, dietary restrictions, disliked foods, cuisine
    preference, fasting window, the burn-adjusted remaining budget, and the safe
    calorie floor, and so the app can render a tappable "Log it" meal card.

    Args:
        user_id: User's UUID.
        meal_type: Optional slot (breakfast/lunch/dinner/snack). Inferred from
                   local time + already-logged meals when omitted.
        timezone_str: IANA timezone (e.g. "America/Chicago").

    Returns:
        Dict carrying a `meal_recommended` action_data the UI renders as a meal
        card with a Log CTA, plus a human-readable `message`.
    """
    try:
        from services.langgraph_agents.tools.nutrition_context_helpers import (
            fetch_daily_nutrition_context,
            fetch_recent_favorites,
            fetch_todays_workout,
        )
        from services.nutrition_meal_recommendation import (
            collect_forbidden_tokens,
            infer_slot,
            is_in_fasting_window,
            cache_key,
            cache_get,
            cache_put,
            generate_suggestion,
            SNACK_REMAINDER_THRESHOLD,
            SAFE_FLOOR_KCAL,
        )

        db = get_supabase_db()

        # Day context (includes F4 burn-adjusted remainder), favorites, workout.
        daily_ctx = run_async_in_sync(
            fetch_daily_nutrition_context(user_id, timezone_str)
        )
        favs = run_async_in_sync(
            fetch_recent_favorites(user_id, limit=5, exclude_days=0)
        )
        workout = run_async_in_sync(fetch_todays_workout(user_id, timezone_str))

        # Preferences: allergens, dietary restrictions, cuisines, locale, fasting.
        # Read nutrition_preferences via the client (the db facade doesn't expose
        # a typed getter for it).
        prefs = {}
        try:
            _pr = (
                db.client.table("nutrition_preferences")
                .select(
                    "allergies, dietary_restrictions, favorite_cuisines, "
                    "adjust_calories_for_training, intermittent_fasting_enabled, "
                    "eating_window_start_hour, eating_window_end_hour"
                )
                .eq("user_id", user_id)
                .maybe_single()
                .execute()
            )
            prefs = (_pr.data if _pr and _pr.data else {}) or {}
        except Exception as _pe:
            logger.debug(f"[recommend_meal] prefs read fell back to defaults: {_pe}")
        user = db.get_user(user_id) or {}
        locale = user.get("preferred_locale") or user.get("chat_locale") or "en"
        gender = (user.get("gender") or "").strip().lower()
        safe_floor = SAFE_FLOOR_KCAL.get(
            "female" if gender in ("female", "f", "woman") else "male"
            if gender in ("male", "m", "man") else "female"
        )

        # Fasting: never push food during a fast.
        if is_in_fasting_window(prefs, timezone_str):
            return {
                "success": True,
                "action": "recommend_meal",
                "user_id": user_id,
                "fasting": True,
                "message": (
                    "You're in your fasting window right now, so I'll hold off on "
                    "a meal idea. Want me to line one up for when your eating "
                    "window opens?"
                ),
            }

        allergens, restrictions, _ = collect_forbidden_tokens(
            allergies=prefs.get("allergies"),
            dietary_restrictions=prefs.get("dietary_restrictions"),
            dislikes=[],
        )
        dislikes = _fetch_disliked_foods(db, user_id)
        cuisines = []
        raw_cuisines = prefs.get("favorite_cuisines")
        if isinstance(raw_cuisines, list):
            cuisines = [str(c).strip() for c in raw_cuisines if c]
        elif isinstance(raw_cuisines, str) and raw_cuisines.strip():
            cuisines = [raw_cuisines.strip()]

        # Resolve slot.
        logged_today = daily_ctx.get("meal_types_logged") or []
        if meal_type and meal_type.lower() in {"breakfast", "lunch", "dinner", "snack"}:
            slot = meal_type.lower()
        else:
            slot = infer_slot(timezone_str, logged_today)

        # Budget: prefer the burn-adjusted remainder (F4).
        eatable = daily_ctx.get("net_calorie_remainder")
        if eatable is None:
            eatable = daily_ctx.get("calorie_remainder")
        over_budget = bool(daily_ctx.get("over_budget"))
        # Never push the day below the safe floor: if eating the suggested
        # calories would drop the day under the floor, treat as over-budget
        # (light option only). consumed = target - remainder.
        snack_only = False
        if isinstance(eatable, int):
            if eatable < SNACK_REMAINDER_THRESHOLD:
                snack_only = eatable > 0  # tiny positive remainder → snack
                if eatable <= 0:
                    over_budget = True
            cal_target = daily_ctx.get("target_calories")
            if cal_target and (cal_target - max(eatable, 0)) >= (cal_target - 0) and eatable < 0:
                over_budget = True

        # Shared (user, slot, hour) cache — no parallel Gemini call.
        key = cache_key(user_id, slot)
        parsed = cache_get(key)
        if parsed is None:
            parsed = run_async_in_sync(
                generate_suggestion(
                    user_id=user_id,
                    meal_slot=slot,
                    eatable_calories=eatable if isinstance(eatable, int) else None,
                    macros_remaining=daily_ctx.get("macros_remaining") or {},
                    favs=favs,
                    workout=workout,
                    allergens=allergens,
                    dietary_restrictions=restrictions,
                    dislikes=dislikes,
                    cuisines=cuisines,
                    over_budget=over_budget,
                    snack_only=snack_only,
                    locale=locale,
                )
            )
            cache_put(key, parsed)

        # Build the `meal_recommended` action_data (shared contract).
        food_items = [
            {
                "name": fi.name,
                "calories": int(fi.calories),
                "protein_g": float(fi.protein_g),
                "carbs_g": float(fi.carbs_g),
                "fat_g": float(fi.fat_g),
            }
            for fi in (parsed.food_items or [])
        ]
        macros_rem = daily_ctx.get("macros_remaining") or {}
        action_data = {
            "action": "meal_recommended",
            "meal": {
                "emoji": parsed.emoji,
                "title": parsed.title,
                "subtitle": parsed.subtitle,
                "calories": int(parsed.calories),
                "protein_g": float(parsed.protein_g),
                "carbs_g": float(parsed.carbs_g),
                "fat_g": float(parsed.fat_g),
                "food_items": food_items,
            },
            "macros_fit": {
                "protein_g": float(macros_rem.get("protein_g") or 0),
                "carbs_g": float(macros_rem.get("carbs_g") or 0),
                "fat_g": float(macros_rem.get("fat_g") or 0),
                "calories": int(eatable) if isinstance(eatable, int) else 0,
            },
            "meal_slot": slot,
            "log_cta": True,
        }

        message = (
            f"{parsed.emoji} **{parsed.title}** — {parsed.subtitle}\n"
            f"{int(parsed.calories)} kcal · {parsed.protein_g:.0f}P "
            f"{parsed.carbs_g:.0f}C {parsed.fat_g:.0f}F"
        )

        return {
            "success": True,
            "action": "recommend_meal",
            "user_id": user_id,
            "meal_slot": slot,
            "message": message,
            "action_data": action_data,
        }

    except Exception as e:
        logger.error(f"recommend_meal failed: {e}", exc_info=True)
        return {
            "success": False,
            "action": "recommend_meal",
            "user_id": user_id,
            "message": f"Failed to build a meal recommendation: {str(e)}",
        }


@tool
def get_micronutrient_gaps(
    user_id: str,
    days: int = 7,
    timezone_str: str = "UTC",
) -> Dict[str, Any]:
    """
    Report micronutrients the user is running BELOW the RDA estimate on, over a
    recent window. Use this for "am I low on any vitamins?", "what nutrients am
    I missing?", "any gaps in my diet?".

    Gated on data coverage: returns gaps ONLY when there are at least a few days
    of logged foods that carry micro data — otherwise it says there isn't enough
    data yet (missing data is NOT a deficiency). Uses the gender-appropriate RDA
    row. Frames everything as "below the RDA estimate", NEVER a clinical
    "deficiency" or diagnosis.

    Args:
        user_id: User's UUID.
        days: Trailing window in days (default 7).
        timezone_str: IANA timezone.

    Returns:
        Dict with a `gaps` list (nutrient, avg_daily, rda, pct) when coverage is
        sufficient, plus a `coverage` object; or `insufficient_data=True`.
    """
    try:
        from core.timezone_utils import local_range_bounds, get_user_today

        db = get_supabase_db()
        rda_rows = (
            db.client.table("nutrient_rdas").select("*").execute().data or []
        )
        rdas = {r["nutrient_key"]: r for r in rda_rows}

        user = db.get_user(user_id) or {}
        gender = (user.get("gender") or "").strip().lower()
        is_female = gender in ("female", "f", "woman")
        is_pregnant = bool(user.get("is_pregnant"))
        is_lactating = bool(user.get("is_lactating"))

        def _rda_for(r: dict):
            # Pregnancy/lactation columns when present, else gender-specific.
            if is_pregnant and r.get("rda_target_pregnant"):
                return float(r["rda_target_pregnant"])
            if is_lactating and r.get("rda_target_lactating"):
                return float(r["rda_target_lactating"])
            key = "rda_target_female" if is_female else "rda_target_male"
            return float(r.get(key) or r.get("rda_target") or 0)

        # Pull the window's logs once.
        today = get_user_today(timezone_str)
        from datetime import date as _d, timedelta as _td
        base = _d.fromisoformat(today)
        start_iso = (base - _td(days=days - 1)).isoformat()
        # Half-open [start, end) over the user's local days — `end` is local
        # midnight AFTER `today`, so .lt() (never .lte()) is the correct
        # operator and DST-length days stay exact.
        start_utc, end_utc = local_range_bounds(start_iso, today, timezone_str)

        logs = (
            db.client.table("food_logs").select("*")
            .eq("user_id", user_id)
            .is_("deleted_at", "null")
            .gte("logged_at", start_utc)
            .lt("logged_at", end_utc)
            .limit(300)
            .execute()
        ).data or []

        total_foods = len(logs)
        foods_with_micro = 0
        sums: Dict[str, float] = {}
        # Days that had at least one food with micro data → coverage in days.
        days_with_data = set()
        for log in logs:
            has_any = False
            for key in rdas.keys():
                v = log.get(key)
                if v is None:
                    continue
                try:
                    fv = float(v)
                except (TypeError, ValueError):
                    continue
                sums[key] = sums.get(key, 0.0) + fv
                if fv > 0:
                    has_any = True
            if has_any:
                foods_with_micro += 1
                # Bucket by the user's LOCAL day — slicing the UTC string rolls
                # a 9pm-local meal onto the next day, which both inflates the
                # coverage day-count and dilutes the per-day averages below.
                la = utc_to_local_date(log.get("logged_at"), timezone_str)
                if la:
                    days_with_data.add(la)

        # Coverage gate — need at least 3 distinct days of micro data.
        if len(days_with_data) < 3:
            return {
                "success": True,
                "action": "get_micronutrient_gaps",
                "user_id": user_id,
                "insufficient_data": True,
                "coverage": {
                    "foods_with_micro_data": foods_with_micro,
                    "total_foods": total_foods,
                    "days_with_data": len(days_with_data),
                },
                "message": (
                    "Not enough logged days with nutrient detail yet to call out "
                    "gaps reliably — keep logging and I'll spot patterns."
                ),
            }

        n_days = max(1, len(days_with_data))
        gaps = []
        for key, r in rdas.items():
            if key in ("calories", "protein_g", "carbs_g", "fat_g"):
                continue
            rda = _rda_for(r)
            if rda <= 0:
                continue
            # Penalty nutrients (sodium/sugar/etc) aren't "gaps" when low.
            if r.get("penalty"):
                continue
            avg_daily = sums.get(key, 0.0) / n_days
            pct = round((avg_daily / rda) * 100, 0)
            if pct < 70:  # meaningfully below the RDA estimate
                gaps.append({
                    "nutrient_key": key,
                    "display_name": r.get("display_name", key),
                    "unit": r.get("unit", ""),
                    "avg_daily": round(avg_daily, 1),
                    "rda": round(rda, 1),
                    "pct_of_rda": pct,
                })
        gaps.sort(key=lambda g: g["pct_of_rda"])

        return {
            "success": True,
            "action": "get_micronutrient_gaps",
            "user_id": user_id,
            "gaps": gaps[:5],
            "coverage": {
                "foods_with_micro_data": foods_with_micro,
                "total_foods": total_foods,
                "days_with_data": len(days_with_data),
            },
            "framing": "below_rda_estimate_not_deficiency",
            "message": (
                f"Based on {foods_with_micro} of {total_foods} logged foods over "
                f"{len(days_with_data)} days, "
                + (
                    "you're tracking below the RDA estimate on: "
                    + ", ".join(g["display_name"] for g in gaps[:5])
                    if gaps else "you're meeting the RDA estimate on the tracked nutrients."
                )
            ),
        }
    except Exception as e:
        logger.error(f"get_micronutrient_gaps failed: {e}", exc_info=True)
        return {
            "success": False,
            "action": "get_micronutrient_gaps",
            "user_id": user_id,
            "message": f"Failed to compute micronutrient gaps: {str(e)}",
        }


@tool
def log_food_barcode(
    user_id: str,
    barcode: str,
    meal_type: str = "snack",
    consumed_fraction: float = 1.0,
    timezone_str: str = "UTC",
) -> Dict[str, Any]:
    """
    Log a packaged food to the diary by its scanned barcode (UPC/EAN).

    Use this when the user gives a barcode number or asks to log a scanned
    product. Looks the product up (verified override → Open Food Facts → USDA),
    prefers the verified barcode/override value over any AI guess, scales by
    `consumed_fraction` (fraction of the package eaten, default whole), persists
    macros + micros, and emits a `food_logged` action_data with
    source_type="barcode".

    Args:
        user_id: User's UUID.
        barcode: The numeric barcode (8-14 digits).
        meal_type: breakfast/lunch/dinner/snack (default snack).
        consumed_fraction: Fraction of the package consumed (0<f<=1, default 1.0).
        timezone_str: IANA timezone.

    Returns:
        Dict with the logged macros + a `food_logged` action_data (source_type
        "barcode"), or a clear not-found message so the coach can ask the user
        to describe the food instead.
    """
    try:
        from services.food_database_service import get_food_database_service
        from core.timezone_utils import get_user_now_iso

        db = get_supabase_db()
        service = get_food_database_service()

        product = run_async_in_sync(service.lookup_barcode(barcode))
        if not product:
            return {
                "success": False,
                "action": "log_food_barcode",
                "user_id": user_id,
                "not_found": True,
                "message": (
                    f"I couldn't find a product for barcode {barcode} in the food "
                    f"databases. Tell me what it is (name + serving) and I'll log it."
                ),
            }

        frac = consumed_fraction if consumed_fraction and consumed_fraction > 0 else 1.0
        frac = min(frac, 1.0)
        serving_g = product.nutrients.serving_size_g or 100.0
        total_grams = serving_g * frac
        mult = total_grams / 100.0

        food_item = {
            "name": product.product_name,
            "amount": f"{total_grams:.0f}g ({int(frac * 100)}% of package)"
            if frac != 1.0 else f"{total_grams:.0f}g",
            "calories": int(product.nutrients.calories_per_100g * mult),
            "protein_g": round(product.nutrients.protein_per_100g * mult, 1),
            "carbs_g": round(product.nutrients.carbs_per_100g * mult, 1),
            "fat_g": round(product.nutrients.fat_per_100g * mult, 1),
            "barcode": barcode,
            "brand": product.brand,
            "verified_source": "barcode",
        }

        # Apply the user's learned per-food correction on top of the barcode row.
        from services.food_override_service import apply_user_food_overrides
        items, totals, n_over = apply_user_food_overrides(db, user_id, [food_item])
        food_item = items[0]
        total_calories = totals["total_calories"]
        protein_g = totals["protein_g"]
        carbs_g = totals["carbs_g"]
        fat_g = totals["fat_g"]
        fiber_g = round(product.nutrients.fiber_per_100g * mult, 1)

        user_tz_logged_at = get_user_now_iso(timezone_str)
        created = db.create_food_log(
            user_id=user_id,
            meal_type=meal_type,
            food_items=[food_item],
            total_calories=total_calories,
            protein_g=protein_g,
            carbs_g=carbs_g,
            fat_g=fat_g,
            fiber_g=fiber_g,
            ai_feedback=None,
            health_score=None,
            logged_at=user_tz_logged_at,
            source_type="barcode",
            input_type="chat",
            user_query=product.product_name,
        )
        food_log_id = created.get("id") if created else None

        try:
            from api.v1.nutrition.summaries import invalidate_daily_summary_cache
            run_async_in_sync(invalidate_daily_summary_cache(user_id))
        except Exception:
            pass

        return {
            "success": True,
            "action": "log_food_barcode",
            "user_id": user_id,
            "food_log_id": food_log_id,
            "meal_type": meal_type,
            "total_calories": total_calories,
            "protein_g": protein_g,
            "carbs_g": carbs_g,
            "fat_g": fat_g,
            "message": (
                f"Logged **{product.product_name}** — {total_calories} kcal, "
                f"{protein_g:.0f}g protein."
            ),
            "action_data": {
                "action": "food_logged",
                "food_log_id": food_log_id,
                "meal_type": meal_type,
                "total_calories": total_calories,
                "protein_g": protein_g,
                "carbs_g": carbs_g,
                "fat_g": fat_g,
                "food_item_count": 1,
                "source_type": "barcode",
                "success": True,
            },
        }
    except Exception as e:
        logger.error(f"log_food_barcode failed: {e}", exc_info=True)
        return {
            "success": False,
            "action": "log_food_barcode",
            "user_id": user_id,
            "message": f"Failed to log barcode: {str(e)}",
        }


@tool
def build_grocery_list(
    user_id: str,
    scope: str,
    subject_id: str,
    suppress_staples: bool = True,
) -> Dict[str, Any]:
    """
    Build a grocery list from a meal plan or a single recipe.

    Use this when the user asks something like "make me a grocery list for my
    plan today" or "what do I need to buy for the chili recipe?". The list is
    persisted; the response includes a list_id the UI can deep-link into.

    Args:
        user_id: User's UUID.
        scope: "plan" to build from a meal plan; "recipe" for a single recipe.
        subject_id: meal_plan_id when scope=plan; recipe_id when scope=recipe.
        suppress_staples: hide the user's staples (oil/salt/pepper) by default.

    Returns:
        Dict with success flag, list_id, item_count, aisles touched, and an
        action_data payload the UI can read to navigate to grocery_list_screen.
    """
    try:
        from models.grocery_list import GroceryListCreate
        from services.grocery_list_service import get_grocery_service

        scope_clean = (scope or "").strip().lower()
        if scope_clean not in ("plan", "recipe"):
            return {
                "success": False,
                "action": "build_grocery_list",
                "message": "scope must be 'plan' or 'recipe'",
            }

        req = GroceryListCreate(
            meal_plan_id=subject_id if scope_clean == "plan" else None,
            source_recipe_id=subject_id if scope_clean == "recipe" else None,
            suppress_staples=suppress_staples,
        )
        gl = run_async_in_sync(get_grocery_service().build(user_id, req))

        aisles = sorted({(item.aisle.value if item.aisle else "other") for item in gl.items})
        return {
            "success": True,
            "action": "build_grocery_list",
            "list_id": gl.id,
            "name": gl.name,
            "item_count": len(gl.items),
            "aisles": aisles,
            "message": f"Built grocery list ({len(gl.items)} items across {len(aisles)} aisles).",
            # action_data is consumed by the Flutter chat handler to deep-link
            # into grocery_list_screen — see notification_action_handler / chat
            # message renderers.
            "action_data": {
                "action": "open_grocery_list",
                "list_id": gl.id,
            },
        }
    except Exception as e:
        logger.error(f"build_grocery_list failed: {e}", exc_info=True)
        return {
            "success": False,
            "action": "build_grocery_list",
            "message": f"Failed to build grocery list: {str(e)}",
        }
