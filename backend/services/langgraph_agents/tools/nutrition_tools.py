"""
Nutrition tracking tools for LangGraph agents.

Contains tools for analyzing food images, getting nutrition summaries,
logging food from text descriptions, and retrieving recent meals.
"""

from typing import Dict, Any, List, Optional
from datetime import datetime
import json

from langchain_core.tools import tool

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.nutrition_bias import apply_calorie_bias, get_user_calorie_bias
from .base import get_vision_service, run_async_in_sync

logger = get_logger(__name__)


def _get_gemini_service():
    """Lazy import to avoid circular dependencies."""
    from services.gemini_service import GeminiService
    return GeminiService()


@tool
def analyze_food_image(
    user_id: str,
    image_base64: str,
    user_message: str = None
) -> Dict[str, Any]:
    """
    Analyze a food image to estimate calories, macros, and nutritional content.

    Uses GPT-4o-mini Vision to analyze the food in the image.

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

        # Analyze the image using Vision service
        analysis_result = run_async_in_sync(
            vision_service.analyze_food_image(image_base64, user_context),
            timeout=60
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
        bias = run_async_in_sync(get_user_calorie_bias(user_id), timeout=10)
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
            ai_feedback=ai_feedback
        )

        food_log_id = food_log.get("id") if food_log else None

        # Get today's nutrition summary
        today = datetime.now().strftime("%Y-%m-%d")
        daily_summary = db.get_daily_nutrition_summary(user_id, today)

        # Format food items for response
        food_list = ", ".join([
            f"{item.get('name', 'Unknown')} ({item.get('amount', '')})"
            for item in food_items
        ])

        # Build response message
        message = (
            f"**{meal_type.title()} Logged!**\n\n"
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
            "action": "analyze_food_image",
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
        logger.error(f"Analyze food image failed: {e}")
        return {
            "success": False,
            "action": "analyze_food_image",
            "user_id": user_id,
            "message": f"Failed to analyze food image: {str(e)}"
        }


@tool
def get_nutrition_summary(
    user_id: str,
    date: str = None,
    period: str = "day"
) -> Dict[str, Any]:
    """
    Get a nutrition summary for a user for a specific day or week.

    Args:
        user_id: The user's ID (UUID string)
        date: Date to get summary for (YYYY-MM-DD format). Defaults to today.
        period: "day" for daily summary, "week" for weekly summary

    Returns:
        Result dict with nutrition totals and meal breakdown
    """
    logger.info(f"Tool: Getting nutrition summary for user {user_id}, period: {period}")

    try:
        db = get_supabase_db()

        if date is None:
            date = datetime.now().strftime("%Y-%m-%d")

        if period == "week":
            summary = db.get_weekly_nutrition_summary(user_id, date)

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
            summary = db.get_daily_nutrition_summary(user_id, date)

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
        logger.error(f"Get nutrition summary failed: {e}")
        return {
            "success": False,
            "action": "get_nutrition_summary",
            "user_id": user_id,
            "message": f"Failed to get nutrition summary: {str(e)}"
        }


@tool
def get_recent_meals(
    user_id: str,
    limit: int = 5
) -> Dict[str, Any]:
    """
    Get the user's recent meal logs.

    Args:
        user_id: The user's ID (UUID string)
        limit: Maximum number of meals to return (default 5)

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
            logged_at = meal.get("logged_at", "")
            if isinstance(logged_at, str) and "T" in logged_at:
                logged_at = logged_at.split("T")[0]

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
        logger.error(f"Get recent meals failed: {e}")
        return {
            "success": False,
            "action": "get_recent_meals",
            "user_id": user_id,
            "message": f"Failed to get recent meals: {str(e)}"
        }


@tool
def log_food_from_text(
    user_id: str,
    food_description: str,
    meal_type: str = None
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

    Returns:
        Result dict with nutrition analysis, saved food log, and coaching feedback
    """
    logger.info(f"Tool: Logging food from text for user {user_id}: {food_description[:50]}...")

    try:
        db = get_supabase_db()
        gemini_service = _get_gemini_service()

        # Get user's nutrition targets and goals for context
        user = db.get_user(user_id)
        user_goals = []
        nutrition_targets = {}

        if user:
            # Get goals from user profile
            if user.get("fitness_goals"):
                user_goals = user.get("fitness_goals", [])

            # Get nutrition targets
            nutrition_targets = {
                "daily_calorie_target": user.get("daily_calorie_target"),
                "daily_protein_target_g": user.get("daily_protein_target_g"),
                "daily_carbs_target_g": user.get("daily_carbs_target_g"),
                "daily_fat_target_g": user.get("daily_fat_target_g"),
            }
            nutrition_targets = {k: v for k, v in nutrition_targets.items() if v is not None}

        # Also check nutrition_preferences table
        try:
            prefs_result = db.client.table("nutrition_preferences").select(
                "target_calories, target_protein_g, target_carbs_g, target_fat_g, nutrition_goals"
            ).eq("user_id", user_id).maybe_single().execute()

            if prefs_result and prefs_result.data:
                prefs = prefs_result.data
                if prefs.get("target_calories") and not nutrition_targets.get("daily_calorie_target"):
                    nutrition_targets["daily_calorie_target"] = prefs["target_calories"]
                if prefs.get("target_protein_g") and not nutrition_targets.get("daily_protein_target_g"):
                    nutrition_targets["daily_protein_target_g"] = prefs["target_protein_g"]
                if prefs.get("target_carbs_g") and not nutrition_targets.get("daily_carbs_target_g"):
                    nutrition_targets["daily_carbs_target_g"] = prefs["target_carbs_g"]
                if prefs.get("target_fat_g") and not nutrition_targets.get("daily_fat_target_g"):
                    nutrition_targets["daily_fat_target_g"] = prefs["target_fat_g"]
                if prefs.get("nutrition_goals") and not user_goals:
                    user_goals = prefs["nutrition_goals"]
        except Exception as e:
            logger.warning(f"Could not fetch nutrition_preferences: {e}")

        # Parse the food description using Gemini
        analysis_result = run_async_in_sync(
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
        bias = run_async_in_sync(get_user_calorie_bias(user_id), timeout=10)
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

        # Auto-detect meal type based on time if not provided
        if not meal_type:
            hour = datetime.now().hour
            if 5 <= hour < 11:
                meal_type = "breakfast"
            elif 11 <= hour < 15:
                meal_type = "lunch"
            elif 15 <= hour < 18:
                meal_type = "snack"
            else:
                meal_type = "dinner"

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
            ai_feedback=ai_feedback
        )

        food_log_id = food_log.get("id") if food_log else None

        # Get today's nutrition summary
        today = datetime.now().strftime("%Y-%m-%d")
        daily_summary = db.get_daily_nutrition_summary(user_id, today)

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
        logger.error(f"Log food from text failed: {e}")
        return {
            "success": False,
            "action": "log_food_from_text",
            "user_id": user_id,
            "message": f"Failed to log food: {str(e)}"
        }
