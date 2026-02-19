"""
Weekly Plans API endpoints.

This module handles holistic weekly plan generation and management:
- POST /generate - Generate a new weekly plan with AI
- GET /current - Get current week's plan
- GET /{week_start} - Get a specific week's plan
- PUT /{id} - Update plan settings
- DELETE /{id} - Archive a plan
- GET /{id}/daily/{date} - Get daily plan details
- PUT /{id}/daily/{date} - Update daily entry
- POST /meal-suggestions - Generate AI meal suggestions for a day
"""

import json
from datetime import date, datetime, time, timedelta
from typing import List, Optional

from fastapi import APIRouter, BackgroundTasks, HTTPException, Request
from pydantic import BaseModel, Field

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.rate_limiter import limiter
from core.timezone_utils import resolve_timezone, get_user_today
from services.holistic_plan_service import (
    get_holistic_plan_service,
    WeeklyPlan,
    DailyPlanEntry,
    NutritionTargets,
    MealSuggestion,
)
from services.user_context_service import user_context_service, EventType

router = APIRouter()
logger = get_logger(__name__)


# =============================================================================
# Request/Response Models
# =============================================================================

class GenerateWeeklyPlanRequest(BaseModel):
    """Request to generate a new weekly plan."""
    user_id: str
    week_start: Optional[str] = None  # ISO date, defaults to current week
    workout_days: List[int] = Field(default=[0, 2, 4], description="Day indices (0=Mon, 6=Sun)")
    fasting_protocol: Optional[str] = Field(default=None, description="e.g., '16:8', '18:6'")
    nutrition_strategy: str = Field(default="workout_aware", description="workout_aware, static, cutting, bulking")
    goals: Optional[List[str]] = None
    preferred_workout_time: Optional[str] = None  # HH:MM format


class WeeklyPlanResponse(BaseModel):
    """Response containing a weekly plan."""
    id: str
    user_id: str
    week_start_date: str
    status: str
    workout_days: List[int]
    fasting_protocol: Optional[str]
    nutrition_strategy: str
    daily_entries: List[dict]
    generated_at: Optional[str]


class DailyEntryResponse(BaseModel):
    """Response for a single daily entry."""
    id: str
    plan_date: str
    day_type: str
    workout_id: Optional[str]
    workout_time: Optional[str]
    nutrition_targets: dict
    fasting_window: Optional[dict]
    meal_suggestions: List[dict]
    coordination_notes: List[dict]


class UpdateDailyEntryRequest(BaseModel):
    """Request to update a daily entry."""
    workout_time: Optional[str] = None  # HH:MM format
    calorie_target: Optional[int] = None
    protein_target_g: Optional[float] = None
    carbs_target_g: Optional[float] = None
    fat_target_g: Optional[float] = None
    eating_window_start: Optional[str] = None  # HH:MM format
    eating_window_end: Optional[str] = None  # HH:MM format


class GenerateMealSuggestionsRequest(BaseModel):
    """Request to generate meal suggestions for a day."""
    user_id: str
    plan_date: str  # ISO date
    day_type: str = "training"  # training, rest
    calorie_target: int
    protein_target_g: float
    carbs_target_g: float
    fat_target_g: float
    eating_window_start: Optional[str] = None  # HH:MM
    eating_window_end: Optional[str] = None  # HH:MM
    workout_time: Optional[str] = None  # HH:MM
    dietary_restrictions: Optional[List[str]] = None


class MealSuggestionsResponse(BaseModel):
    """Response with generated meal suggestions."""
    meals: List[dict]
    total_macros: dict


# =============================================================================
# API Endpoints
# =============================================================================

async def _log_weekly_plan_event(user_id: str, week_start_iso: str, workout_days: List[int], fasting_protocol: Optional[str], nutrition_strategy: str):
    """Background task: Log the weekly plan generation event (non-critical)."""
    try:
        await user_context_service.log_event(
            user_id=user_id,
            event_type=EventType.FEATURE_INTERACTION,
            metadata={
                "feature": "weekly_plan_generated",
                "week_start": week_start_iso,
                "workout_days": workout_days,
                "fasting_protocol": fasting_protocol,
                "nutrition_strategy": nutrition_strategy,
            },
        )
        logger.debug(f"Background: Logged weekly plan event for user {user_id}")
    except Exception as e:
        logger.warning(f"Background: Failed to log weekly plan event: {e}")


@router.post("/generate", response_model=WeeklyPlanResponse)
@limiter.limit("5/minute")
async def generate_weekly_plan(request: GenerateWeeklyPlanRequest, http_request: Request, background_tasks: BackgroundTasks):
    """
    Generate a new weekly holistic plan.

    This endpoint creates a complete weekly plan that coordinates:
    - Workout schedule based on specified days
    - Nutrition targets adjusted for training vs rest days
    - Fasting windows that work with workout timing
    - Coordination warnings for any conflicts
    """
    logger.info(f"Generating weekly plan for user {request.user_id}")

    try:
        service = get_holistic_plan_service()

        # Parse week start date
        if request.week_start:
            week_start = date.fromisoformat(request.week_start)
        else:
            # Default to current week's Monday
            user_tz = resolve_timezone(http_request, None, request.user_id)
            today = date.fromisoformat(get_user_today(user_tz))
            week_start = today - timedelta(days=today.weekday())

        # Parse preferred workout time
        preferred_time = None
        if request.preferred_workout_time:
            parts = request.preferred_workout_time.split(":")
            preferred_time = time(int(parts[0]), int(parts[1]))

        # Generate the plan
        plan = await service.generate_weekly_plan(
            user_id=request.user_id,
            week_start=week_start,
            workout_days=request.workout_days,
            fasting_protocol=request.fasting_protocol,
            nutrition_strategy=request.nutrition_strategy,
            goals=request.goals,
            preferred_workout_time=preferred_time,
        )

        # Save the plan
        plan_id = await service.save_weekly_plan(plan)
        plan.id = plan_id

        # Log the event in background (non-critical, don't block the response)
        background_tasks.add_task(
            _log_weekly_plan_event,
            user_id=request.user_id,
            week_start_iso=week_start.isoformat(),
            workout_days=request.workout_days,
            fasting_protocol=request.fasting_protocol,
            nutrition_strategy=request.nutrition_strategy,
        )

        logger.info(f"Generated weekly plan {plan_id} for user {request.user_id}")

        return WeeklyPlanResponse(
            id=plan.id,
            user_id=plan.user_id,
            week_start_date=plan.week_start_date.isoformat(),
            status=plan.status,
            workout_days=plan.workout_days,
            fasting_protocol=plan.fasting_protocol,
            nutrition_strategy=plan.nutrition_strategy.value if hasattr(plan.nutrition_strategy, 'value') else plan.nutrition_strategy,
            daily_entries=[e.to_dict() for e in plan.daily_entries],
            generated_at=plan.generated_at.isoformat() if plan.generated_at else None,
        )

    except ValueError as e:
        logger.error(f"Validation error generating plan: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Error generating weekly plan: {e}")
        raise HTTPException(status_code=500, detail="Failed to generate weekly plan")


async def _log_screen_view_event(user_id: str, screen: str, metadata: dict):
    """Background task: Log screen view event (non-critical)."""
    try:
        await user_context_service.log_event(
            user_id=user_id,
            event_type=EventType.SCREEN_VIEW,
            metadata=metadata,
        )
    except Exception as e:
        logger.warning(f"Background: Failed to log screen view event: {e}")


@router.get("/current")
async def get_current_week_plan(user_id: str, background_tasks: BackgroundTasks):
    """
    Get the current week's plan for a user.

    Returns the active plan for the week containing today's date.
    """
    logger.info(f"Getting current week plan for user {user_id}")

    try:
        service = get_holistic_plan_service()
        plan = await service.get_current_week_plan(user_id)

        if not plan:
            return {"message": "No plan found for current week", "plan": None}

        # Log view event in background (non-critical, don't block the response)
        background_tasks.add_task(
            _log_screen_view_event,
            user_id=user_id,
            screen="weekly_plan",
            metadata={"screen": "weekly_plan", "week_start": plan.week_start_date.isoformat()},
        )

        return WeeklyPlanResponse(
            id=plan.id,
            user_id=plan.user_id,
            week_start_date=plan.week_start_date.isoformat(),
            status=plan.status,
            workout_days=plan.workout_days,
            fasting_protocol=plan.fasting_protocol,
            nutrition_strategy=plan.nutrition_strategy.value if hasattr(plan.nutrition_strategy, 'value') else plan.nutrition_strategy,
            daily_entries=[e.to_dict() for e in plan.daily_entries],
            generated_at=plan.generated_at.isoformat() if plan.generated_at else None,
        )

    except Exception as e:
        logger.error(f"Error getting current week plan: {e}")
        raise HTTPException(status_code=500, detail="Failed to get current week plan")


@router.get("/{week_start}")
async def get_week_plan(week_start: str, user_id: str):
    """
    Get a specific week's plan.

    Args:
        week_start: ISO date string for the Monday of the week
        user_id: User ID
    """
    logger.info(f"Getting week plan for user {user_id}, week starting {week_start}")

    try:
        service = get_holistic_plan_service()
        week_start_date = date.fromisoformat(week_start)
        plan = await service.get_week_plan(user_id, week_start_date)

        if not plan:
            raise HTTPException(status_code=404, detail="Plan not found for specified week")

        return WeeklyPlanResponse(
            id=plan.id,
            user_id=plan.user_id,
            week_start_date=plan.week_start_date.isoformat(),
            status=plan.status,
            workout_days=plan.workout_days,
            fasting_protocol=plan.fasting_protocol,
            nutrition_strategy=plan.nutrition_strategy.value if hasattr(plan.nutrition_strategy, 'value') else plan.nutrition_strategy,
            daily_entries=[e.to_dict() for e in plan.daily_entries],
            generated_at=plan.generated_at.isoformat() if plan.generated_at else None,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting week plan: {e}")
        raise HTTPException(status_code=500, detail="Failed to get week plan")


@router.put("/{plan_id}")
async def update_weekly_plan(plan_id: str, user_id: str, updates: dict):
    """
    Update a weekly plan's settings.

    Allows updating:
    - workout_days
    - fasting_protocol
    - nutrition_strategy
    - status (active, archived)
    """
    logger.info(f"Updating weekly plan {plan_id} for user {user_id}")

    try:
        db = get_supabase_db()

        # Verify ownership
        result = db.client.table("weekly_plans").select("user_id").eq("id", plan_id).execute()
        if not result.data or result.data[0]["user_id"] != user_id:
            raise HTTPException(status_code=404, detail="Plan not found")

        # Filter allowed updates
        allowed_fields = ["workout_days", "fasting_protocol", "nutrition_strategy", "status"]
        update_data = {k: v for k, v in updates.items() if k in allowed_fields}
        update_data["updated_at"] = datetime.now().isoformat()

        # Update
        db.client.table("weekly_plans").update(update_data).eq("id", plan_id).execute()

        logger.info(f"Updated weekly plan {plan_id}")
        return {"success": True, "message": "Plan updated"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating weekly plan: {e}")
        raise HTTPException(status_code=500, detail="Failed to update plan")


@router.delete("/{plan_id}")
async def archive_weekly_plan(plan_id: str, user_id: str):
    """
    Archive a weekly plan (soft delete).
    """
    logger.info(f"Archiving weekly plan {plan_id} for user {user_id}")

    try:
        db = get_supabase_db()

        # Verify ownership
        result = db.client.table("weekly_plans").select("user_id").eq("id", plan_id).execute()
        if not result.data or result.data[0]["user_id"] != user_id:
            raise HTTPException(status_code=404, detail="Plan not found")

        # Archive (soft delete)
        db.client.table("weekly_plans").update({
            "status": "archived",
            "updated_at": datetime.now().isoformat(),
        }).eq("id", plan_id).execute()

        logger.info(f"Archived weekly plan {plan_id}")
        return {"success": True, "message": "Plan archived"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error archiving weekly plan: {e}")
        raise HTTPException(status_code=500, detail="Failed to archive plan")


@router.get("/{plan_id}/daily/{plan_date}")
async def get_daily_entry(plan_id: str, plan_date: str, user_id: str, background_tasks: BackgroundTasks):
    """
    Get a specific daily entry from a weekly plan.
    """
    logger.info(f"Getting daily entry for {plan_date} from plan {plan_id}")

    try:
        db = get_supabase_db()

        # Verify ownership
        plan_result = db.client.table("weekly_plans").select("user_id").eq("id", plan_id).execute()
        if not plan_result.data or plan_result.data[0]["user_id"] != user_id:
            raise HTTPException(status_code=404, detail="Plan not found")

        # Get daily entry
        result = db.client.table("daily_plan_entries").select("*").eq(
            "weekly_plan_id", plan_id
        ).eq(
            "plan_date", plan_date
        ).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Daily entry not found")

        entry = result.data[0]

        # Log view event in background (non-critical, don't block the response)
        background_tasks.add_task(
            _log_screen_view_event,
            user_id=user_id,
            screen="daily_plan",
            metadata={"screen": "daily_plan", "date": plan_date, "day_type": entry.get("day_type")},
        )

        return DailyEntryResponse(
            id=entry["id"],
            plan_date=entry["plan_date"],
            day_type=entry["day_type"],
            workout_id=entry.get("workout_id"),
            workout_time=entry.get("workout_time"),
            nutrition_targets={
                "calories": entry["calorie_target"],
                "protein_g": entry["protein_target_g"],
                "carbs_g": entry["carbs_target_g"],
                "fat_g": entry["fat_target_g"],
                "fiber_g": entry.get("fiber_target_g", 25),
            },
            fasting_window={
                "protocol": entry.get("fasting_protocol"),
                "eating_window_start": entry.get("eating_window_start"),
                "eating_window_end": entry.get("eating_window_end"),
                "fasting_duration_hours": entry.get("fasting_duration_hours"),
            } if entry.get("eating_window_start") else None,
            meal_suggestions=entry.get("meal_suggestions", []),
            coordination_notes=entry.get("coordination_notes", []),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting daily entry: {e}")
        raise HTTPException(status_code=500, detail="Failed to get daily entry")


@router.put("/{plan_id}/daily/{plan_date}")
async def update_daily_entry(
    plan_id: str,
    plan_date: str,
    user_id: str,
    request: UpdateDailyEntryRequest,
):
    """
    Update a specific daily entry.

    Allows manual adjustments to:
    - Workout time
    - Nutrition targets
    - Fasting window times
    """
    logger.info(f"Updating daily entry for {plan_date} in plan {plan_id}")

    try:
        db = get_supabase_db()

        # Verify ownership
        plan_result = db.client.table("weekly_plans").select("user_id").eq("id", plan_id).execute()
        if not plan_result.data or plan_result.data[0]["user_id"] != user_id:
            raise HTTPException(status_code=404, detail="Plan not found")

        # Build update data
        update_data = {"updated_at": datetime.now().isoformat()}

        if request.workout_time is not None:
            update_data["workout_time"] = request.workout_time
        if request.calorie_target is not None:
            update_data["calorie_target"] = request.calorie_target
        if request.protein_target_g is not None:
            update_data["protein_target_g"] = request.protein_target_g
        if request.carbs_target_g is not None:
            update_data["carbs_target_g"] = request.carbs_target_g
        if request.fat_target_g is not None:
            update_data["fat_target_g"] = request.fat_target_g
        if request.eating_window_start is not None:
            update_data["eating_window_start"] = request.eating_window_start
        if request.eating_window_end is not None:
            update_data["eating_window_end"] = request.eating_window_end

        # Update entry
        db.client.table("daily_plan_entries").update(update_data).eq(
            "weekly_plan_id", plan_id
        ).eq(
            "plan_date", plan_date
        ).execute()

        logger.info(f"Updated daily entry for {plan_date}")
        return {"success": True, "message": "Daily entry updated"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating daily entry: {e}")
        raise HTTPException(status_code=500, detail="Failed to update daily entry")


@router.post("/meal-suggestions", response_model=MealSuggestionsResponse)
@limiter.limit("10/minute")
async def generate_meal_suggestions(request: GenerateMealSuggestionsRequest, http_request: Request):
    """
    Generate AI meal suggestions for a specific day.

    Creates meal suggestions that:
    - Fit within the specified eating window
    - Meet the macro targets
    - Include pre/post workout meals on training days
    - Respect dietary restrictions
    """
    logger.info(f"Generating meal suggestions for user {request.user_id}, date {request.plan_date}")

    try:
        # Import Gemini service for AI generation
        from services.gemini_service import GeminiService
        gemini = GeminiService()

        # Parse times
        eating_start = request.eating_window_start or "12:00"
        eating_end = request.eating_window_end or "20:00"
        workout_time = request.workout_time

        # Build prompt for AI
        prompt = f"""Generate a meal plan for a {request.day_type} day with these requirements:

NUTRITION TARGETS:
- Calories: {request.calorie_target} kcal
- Protein: {request.protein_target_g}g
- Carbs: {request.carbs_target_g}g
- Fat: {request.fat_target_g}g

EATING WINDOW: {eating_start} - {eating_end}
{"WORKOUT TIME: " + workout_time if workout_time else "REST DAY"}

DIETARY RESTRICTIONS: {', '.join(request.dietary_restrictions) if request.dietary_restrictions else 'None'}

Generate 3-4 meals that:
1. Fit within the eating window
2. Total approximately the target macros
3. {"Include a pre-workout meal 2-3h before workout and post-workout meal within 1h after" if request.day_type == "training" and workout_time else "Spread evenly across eating window"}

Return JSON only:
{{
  "meals": [
    {{
      "meal_type": "breakfast|lunch|dinner|pre_workout|post_workout|snack",
      "suggested_time": "HH:MM",
      "foods": [
        {{"name": "food name", "amount": "portion", "calories": 200, "protein_g": 20, "carbs_g": 25, "fat_g": 8}}
      ],
      "macros": {{"calories": 400, "protein_g": 35, "carbs_g": 45, "fat_g": 12}},
      "notes": "optional notes"
    }}
  ],
  "total_macros": {{"calories": 2000, "protein_g": 150, "carbs_g": 200, "fat_g": 65}}
}}
"""

        # Generate with AI
        response = await gemini.chat(
            user_message=prompt,
            system_prompt="You are a nutrition expert. Generate realistic, practical meal suggestions. Return valid JSON only.",
        )

        # Parse response
        try:
            # Clean markdown if present
            content = response.strip()
            if content.startswith("```json"):
                content = content[7:]
            elif content.startswith("```"):
                content = content[3:]
            if content.endswith("```"):
                content = content[:-3]

            data = json.loads(content.strip())

            # Log success in background (non-critical, don't block the response)
            # Note: http_request is available from the endpoint parameter
            async def _log_meal_event():
                try:
                    await user_context_service.log_event(
                        user_id=request.user_id,
                        event_type=EventType.FEATURE_INTERACTION,
                        metadata={
                            "feature": "meal_suggestions_generated",
                            "date": request.plan_date,
                            "day_type": request.day_type,
                            "meal_count": len(data.get("meals", [])),
                        },
                    )
                except Exception as log_err:
                    logger.warning(f"Background: Failed to log meal suggestions event: {log_err}")

            import asyncio
            asyncio.create_task(_log_meal_event())

            return MealSuggestionsResponse(
                meals=data.get("meals", []),
                total_macros=data.get("total_macros", {}),
            )

        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse AI meal suggestions: {e}")
            # Return fallback basic meals
            return MealSuggestionsResponse(
                meals=[
                    {
                        "meal_type": "breakfast",
                        "suggested_time": eating_start,
                        "foods": [{"name": "Meal suggestion unavailable", "amount": "N/A", "calories": 0, "protein_g": 0, "carbs_g": 0, "fat_g": 0}],
                        "macros": {"calories": 0, "protein_g": 0, "carbs_g": 0, "fat_g": 0},
                        "notes": "AI generation failed. Please log meals manually.",
                    }
                ],
                total_macros={"calories": 0, "protein_g": 0, "carbs_g": 0, "fat_g": 0},
            )

    except Exception as e:
        logger.error(f"Error generating meal suggestions: {e}")
        raise HTTPException(status_code=500, detail="Failed to generate meal suggestions")


@router.post("/{plan_id}/daily/{plan_date}/meal-suggestions")
@limiter.limit("10/minute")
async def save_meal_suggestions_to_daily(
    plan_id: str,
    plan_date: str,
    user_id: str,
    request: Request,
):
    """
    Generate and save meal suggestions directly to a daily entry.
    """
    logger.info(f"Generating and saving meal suggestions for {plan_date} in plan {plan_id}")

    try:
        db = get_supabase_db()

        # Verify ownership and get daily entry
        plan_result = db.client.table("weekly_plans").select("user_id").eq("id", plan_id).execute()
        if not plan_result.data or plan_result.data[0]["user_id"] != user_id:
            raise HTTPException(status_code=404, detail="Plan not found")

        entry_result = db.client.table("daily_plan_entries").select("*").eq(
            "weekly_plan_id", plan_id
        ).eq(
            "plan_date", plan_date
        ).execute()

        if not entry_result.data:
            raise HTTPException(status_code=404, detail="Daily entry not found")

        entry = entry_result.data[0]

        # Generate meal suggestions
        meal_request = GenerateMealSuggestionsRequest(
            user_id=user_id,
            plan_date=plan_date,
            day_type=entry["day_type"],
            calorie_target=entry["calorie_target"],
            protein_target_g=entry["protein_target_g"],
            carbs_target_g=entry["carbs_target_g"],
            fat_target_g=entry["fat_target_g"],
            eating_window_start=entry.get("eating_window_start"),
            eating_window_end=entry.get("eating_window_end"),
            workout_time=entry.get("workout_time"),
        )

        suggestions = await generate_meal_suggestions(meal_request, http_request)

        # Save to daily entry
        db.client.table("daily_plan_entries").update({
            "meal_suggestions": suggestions.meals,
            "updated_at": datetime.now().isoformat(),
        }).eq("id", entry["id"]).execute()

        logger.info(f"Saved {len(suggestions.meals)} meal suggestions to daily entry")

        return {
            "success": True,
            "message": f"Generated {len(suggestions.meals)} meal suggestions",
            "meals": suggestions.meals,
            "total_macros": suggestions.total_macros,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error saving meal suggestions: {e}")
        raise HTTPException(status_code=500, detail="Failed to save meal suggestions")
