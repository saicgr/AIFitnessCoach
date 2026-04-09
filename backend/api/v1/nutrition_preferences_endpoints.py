"""Secondary endpoints for nutrition_preferences.  Sub-router included by main module.
Nutrition Preferences API - Quick logging, meal templates, and food search.

This module provides endpoints for:
1. Nutrition UI preferences (disable_ai_tips, quick_log_mode, etc.)
2. Quick logging of saved foods without AI analysis
3. Personalized quick food suggestions based on logging history
4. Meal templates for one-tap logging
5. Fast food search with caching

ENDPOINTS:

Preferences:
- GET  /api/v1/nutrition/preferences - Get nutrition UI preferences
- PUT  /api/v1/nutrition/preferences - Update nutrition preferences
- POST /api/v1/nutrition/preferences/reset - Reset to default preferences

Quick Log:
- POST /api/v1/nutrition/quick-log - Instant log a saved food
- GET  /api/v1/nutrition/quick-suggestions - Get personalized quick suggestions

Meal Templates:
- GET  /api/v1/nutrition/templates - List all meal templates
- POST /api/v1/nutrition/templates - Create a meal template
- PUT  /api/v1/nutrition/templates/{template_id} - Update a template
- DELETE /api/v1/nutrition/templates/{template_id} - Delete a template
- POST /api/v1/nutrition/templates/{template_id}/log - Log a template as food

Food Search:
- GET  /api/v1/nutrition/search - Fast food search with caching
"""
from typing import Optional
from datetime import datetime, timedelta
import uuid
from fastapi import APIRouter, Depends, HTTPException, Query
import logging
logger = logging.getLogger(__name__)
from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from core.activity_logger import log_user_activity, log_user_error
from services.user_context_service import UserContextService


def _nutrition_prefs_parent():
    """Lazy import to avoid circular dependency."""
    from .nutrition_preferences import calculate_template_totals
    return calculate_template_totals


from .nutrition_preferences_models import (
    NutritionPreferences,
    NutritionPreferencesResponse,
    NutritionPreferencesUpdate,
    QuickLogRequest,
    QuickLogResponse,
    QuickSuggestion,
    QuickSuggestionsResponse,
    MealTemplateFoodItem,
    MealTemplateBase,
    MealTemplateCreate,
    MealTemplate,
    MealTemplateUpdate,
    MealTemplatesResponse,
    LogTemplateRequest,
    LogTemplateResponse,
    FoodSearchResult,
    FoodSearchResponse,
)

router = APIRouter()

@router.get("/templates", response_model=MealTemplatesResponse)
async def list_meal_templates(
    current_user: dict = Depends(get_current_user),
    meal_type: Optional[str] = Query(default=None, description="Filter by meal type"),
    include_system: bool = Query(default=True, description="Include system templates"),
):
    """
    List all meal templates (user's + system templates).

    Use meal_type query param to filter by specific meal type.
    """
    user_id = current_user["id"]
    logger.info(f"Listing meal templates for user {user_id}, meal_type={meal_type}")

    try:
        db = get_supabase_db()

        # Build query for user templates
        query = db.client.table("meal_templates").select("*")

        if include_system:
            query = query.or_(f"user_id.eq.{user_id},is_system_template.eq.true")
        else:
            query = query.eq("user_id", user_id)

        if meal_type:
            query = query.eq("meal_type", meal_type)

        query = query.order("created_at", desc=True)
        result = query.execute()

        templates = []
        for row in result.data or []:
            # Parse food items from JSONB
            food_items_raw = row.get("food_items") or []
            food_items = [MealTemplateFoodItem(**item) for item in food_items_raw]

            templates.append(MealTemplate(
                id=row["id"],
                user_id=row.get("user_id"),
                name=row.get("name", ""),
                description=row.get("description"),
                meal_type=row.get("meal_type", ""),
                food_items=food_items,
                tags=row.get("tags") or [],
                is_system_template=row.get("is_system_template", False),
                total_calories=row.get("total_calories") or 0,
                total_protein_g=row.get("total_protein_g") or 0.0,
                total_carbs_g=row.get("total_carbs_g") or 0.0,
                total_fat_g=row.get("total_fat_g") or 0.0,
                total_fiber_g=row.get("total_fiber_g"),
                times_used=row.get("times_used") or 0,
                last_used_at=row.get("last_used_at"),
                created_at=row.get("created_at"),
                updated_at=row.get("updated_at"),
            ))

        return MealTemplatesResponse(
            templates=templates,
            total_count=len(templates),
        )

    except Exception as e:
        logger.error(f"Error listing meal templates: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition_preferences")


@router.post("/templates", response_model=MealTemplate)
async def create_meal_template(
    request: MealTemplateCreate,
    current_user: dict = Depends(get_current_user)
):
    """
    Create a new meal template.

    Templates allow one-tap logging of common meals.
    """
    calculate_template_totals = _nutrition_prefs_parent()
    user_id = current_user["id"]
    logger.info(f"Creating meal template '{request.name}' for user {user_id}")

    try:
        db = get_supabase_db()

        # Calculate totals
        totals = calculate_template_totals(request.food_items)

        # Prepare food items for storage
        food_items_data = [item.model_dump() for item in request.food_items]

        template_id = str(uuid.uuid4())
        now = datetime.utcnow().isoformat()

        # Insert template
        result = db.client.table("meal_templates").insert({
            "id": template_id,
            "user_id": user_id,
            "name": request.name,
            "description": request.description,
            "meal_type": request.meal_type,
            "food_items": food_items_data,
            "tags": request.tags,
            "is_system_template": False,  # User templates are never system templates
            **totals,
            "times_used": 0,
            "created_at": now,
            "updated_at": now,
        }).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to create template")

        row = result.data[0]

        # Log activity
        await log_user_activity(
            user_id=user_id,
            action="meal_template_create",
            endpoint="/api/v1/nutrition/templates",
            message=f"Created meal template '{request.name}'",
            metadata={
                "template_id": template_id,
                "meal_type": request.meal_type,
                "total_calories": totals["total_calories"],
                "food_items_count": len(request.food_items),
            },
            status_code=201
        )

        # Log user context for analytics
        await user_context_service.log_meal_template_created(
            user_id=user_id,
            template_name=request.name,
            total_calories=totals["total_calories"],
            food_count=len(request.food_items),
        )

        return MealTemplate(
            id=row["id"],
            user_id=row.get("user_id"),
            name=row.get("name", ""),
            description=row.get("description"),
            meal_type=row.get("meal_type", ""),
            food_items=request.food_items,
            tags=row.get("tags") or [],
            is_system_template=row.get("is_system_template", False),
            total_calories=row.get("total_calories") or 0,
            total_protein_g=row.get("total_protein_g") or 0.0,
            total_carbs_g=row.get("total_carbs_g") or 0.0,
            total_fat_g=row.get("total_fat_g") or 0.0,
            total_fiber_g=row.get("total_fiber_g"),
            times_used=row.get("times_used") or 0,
            last_used_at=row.get("last_used_at"),
            created_at=row.get("created_at"),
            updated_at=row.get("updated_at"),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating meal template: {e}", exc_info=True)
        await log_user_error(
            user_id=user_id,
            action="meal_template_create",
            error=e,
            endpoint="/api/v1/nutrition/templates",
            status_code=500
        )
        raise safe_internal_error(e, "nutrition_preferences")


@router.put("/templates/{template_id}", response_model=MealTemplate)
async def update_meal_template(
    template_id: str,
    request: MealTemplateUpdate,
    current_user: dict = Depends(get_current_user)
):
    """
    Update an existing meal template.

    Only user-owned templates can be updated. System templates cannot be modified.
    """
    calculate_template_totals = _nutrition_prefs_parent()
    user_id = current_user["id"]
    logger.info(f"Updating meal template {template_id} for user {user_id}")

    try:
        db = get_supabase_db()

        # Verify ownership
        existing = db.client.table("meal_templates").select("*").eq("id", template_id).maybeSingle().execute()

        if not existing.data:
            raise HTTPException(status_code=404, detail="Template not found")

        if existing.data.get("is_system_template"):
            raise HTTPException(status_code=403, detail="Cannot modify system templates")

        if existing.data.get("user_id") != user_id:
            raise HTTPException(status_code=403, detail="Access denied")

        # Build update data
        update_data = {"updated_at": datetime.utcnow().isoformat()}

        for field, value in request.model_dump(exclude_unset=True).items():
            if value is not None:
                if field == "food_items":
                    update_data["food_items"] = [item.model_dump() for item in value]
                    # Recalculate totals
                    totals = calculate_template_totals(value)
                    update_data.update(totals)
                else:
                    update_data[field] = value

        # Update template
        result = db.client.table("meal_templates").update(update_data).eq("id", template_id).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to update template")

        row = result.data[0]

        # Parse food items
        food_items_raw = row.get("food_items") or []
        food_items = [MealTemplateFoodItem(**item) for item in food_items_raw]

        # Log activity
        await log_user_activity(
            user_id=user_id,
            action="meal_template_update",
            endpoint=f"/api/v1/nutrition/templates/{template_id}",
            message=f"Updated meal template '{row.get('name')}'",
            metadata={
                "template_id": template_id,
                "updated_fields": list(update_data.keys()),
            },
            status_code=200
        )

        return MealTemplate(
            id=row["id"],
            user_id=row.get("user_id"),
            name=row.get("name", ""),
            description=row.get("description"),
            meal_type=row.get("meal_type", ""),
            food_items=food_items,
            tags=row.get("tags") or [],
            is_system_template=row.get("is_system_template", False),
            total_calories=row.get("total_calories") or 0,
            total_protein_g=row.get("total_protein_g") or 0.0,
            total_carbs_g=row.get("total_carbs_g") or 0.0,
            total_fat_g=row.get("total_fat_g") or 0.0,
            total_fiber_g=row.get("total_fiber_g"),
            times_used=row.get("times_used") or 0,
            last_used_at=row.get("last_used_at"),
            created_at=row.get("created_at"),
            updated_at=row.get("updated_at"),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating meal template: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition_preferences")


@router.delete("/templates/{template_id}")
async def delete_meal_template(
    template_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Delete a meal template.

    Only user-owned templates can be deleted. System templates cannot be removed.
    """
    user_id = current_user["id"]
    logger.info(f"Deleting meal template {template_id} for user {user_id}")

    try:
        db = get_supabase_db()

        # Verify ownership
        existing = db.client.table("meal_templates").select("*").eq("id", template_id).maybeSingle().execute()

        if not existing.data:
            raise HTTPException(status_code=404, detail="Template not found")

        if existing.data.get("is_system_template"):
            raise HTTPException(status_code=403, detail="Cannot delete system templates")

        if existing.data.get("user_id") != user_id:
            raise HTTPException(status_code=403, detail="Access denied")

        template_name = existing.data.get("name")

        # Delete template
        db.client.table("meal_templates").delete().eq("id", template_id).execute()

        # Log activity
        await log_user_activity(
            user_id=user_id,
            action="meal_template_delete",
            endpoint=f"/api/v1/nutrition/templates/{template_id}",
            message=f"Deleted meal template '{template_name}'",
            metadata={"template_id": template_id},
            status_code=200
        )

        # Log user context for analytics
        await user_context_service.log_meal_template_deleted(
            user_id=user_id,
            template_id=template_id,
            template_name=template_name,
        )

        return {"status": "deleted", "id": template_id}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting meal template: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition_preferences")


@router.post("/templates/{template_id}/log", response_model=LogTemplateResponse)
async def log_meal_template(
    template_id: str,
    request: LogTemplateRequest,
    current_user: dict = Depends(get_current_user)
):
    """
    Log a meal template as a food log entry.

    Optionally override the meal type and adjust servings.
    """
    user_id = current_user["id"]
    logger.info(f"Logging meal template {template_id} for user {user_id}")

    try:
        db = get_supabase_db()

        # Get template
        result = db.client.table("meal_templates").select("*").eq("id", template_id).maybeSingle().execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Template not found")

        template = result.data

        # Check access (user template or system template)
        if not template.get("is_system_template") and template.get("user_id") != user_id:
            raise HTTPException(status_code=403, detail="Access denied")

        # Calculate nutrition based on servings
        servings = request.servings
        total_calories = int((template.get("total_calories") or 0) * servings)
        protein_g = float((template.get("total_protein_g") or 0) * servings)
        carbs_g = float((template.get("total_carbs_g") or 0) * servings)
        fat_g = float((template.get("total_fat_g") or 0) * servings)
        fiber_g = float((template.get("total_fiber_g") or 0) * servings) if template.get("total_fiber_g") else None

        # Scale food items
        food_items_raw = template.get("food_items") or []
        scaled_items = []
        for item in food_items_raw:
            scaled_item = {
                "name": item.get("name"),
                "amount": item.get("amount"),
                "calories": int((item.get("calories") or 0) * servings),
                "protein_g": float((item.get("protein_g") or 0) * servings),
                "carbs_g": float((item.get("carbs_g") or 0) * servings),
                "fat_g": float((item.get("fat_g") or 0) * servings),
            }
            if item.get("fiber_g"):
                scaled_item["fiber_g"] = float(item["fiber_g"] * servings)
            scaled_items.append(scaled_item)

        # Use override meal type or template's meal type
        meal_type = request.meal_type or template.get("meal_type")

        # Create food log
        logged_at = datetime.utcnow()
        food_log = db.create_food_log(
            user_id=user_id,
            meal_type=meal_type,
            food_items=scaled_items,
            total_calories=total_calories,
            protein_g=protein_g,
            carbs_g=carbs_g,
            fat_g=fat_g,
            fiber_g=fiber_g,
            ai_feedback=f"Logged from template: {template.get('name')}",
            health_score=None,
        )

        food_log_id = food_log.get("id") if food_log else str(uuid.uuid4())

        # Update template usage stats
        db.client.table("meal_templates").update({
            "times_used": (template.get("times_used") or 0) + 1,
            "last_used_at": logged_at.isoformat(),
        }).eq("id", template_id).execute()

        # Log activity
        await log_user_activity(
            user_id=user_id,
            action="meal_template_log",
            endpoint=f"/api/v1/nutrition/templates/{template_id}/log",
            message=f"Logged template '{template.get('name')}' ({total_calories} cal)",
            metadata={
                "food_log_id": food_log_id,
                "template_id": template_id,
                "meal_type": meal_type,
                "servings": servings,
                "total_calories": total_calories,
            },
            status_code=200
        )

        # Log user context for analytics
        await user_context_service.log_meal_template_logged(
            user_id=user_id,
            template_id=template_id,
            template_name=template.get("name", "Unknown"),
            meal_type=meal_type,
            total_calories=total_calories,
        )

        return LogTemplateResponse(
            success=True,
            food_log_id=food_log_id,
            template_id=template_id,
            template_name=template.get("name"),
            meal_type=meal_type,
            servings=servings,
            total_calories=total_calories,
            protein_g=protein_g,
            carbs_g=carbs_g,
            fat_g=fat_g,
            fiber_g=fiber_g,
            logged_at=logged_at,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error logging meal template: {e}", exc_info=True)
        await log_user_error(
            user_id=user_id,
            action="meal_template_log",
            error=e,
            endpoint=f"/api/v1/nutrition/templates/{template_id}/log",
            status_code=500
        )
        raise safe_internal_error(e, "nutrition_preferences")


# =============================================================================
# Food Search Endpoints
# =============================================================================

@router.get("/search", response_model=FoodSearchResponse)
async def search_foods(
    current_user: dict = Depends(get_current_user),
    q: str = Query(..., min_length=1, max_length=100, description="Search query"),
    limit: int = Query(default=20, ge=1, le=50),
):
    """
    Fast food search with caching.

    Searches across:
    - User's saved foods
    - Meal templates
    - Food database (if available)

    Results are cached for repeated queries.
    """
    user_id = current_user["id"]
    search_query = q.strip().lower()
    logger.info(f"Searching foods for user {user_id}, query='{q}'")

    try:
        db = get_supabase_db()

        # Check cache first
        cache_key = f"{user_id}:{search_query}"
        cache_result = db.client.table("food_search_cache").select("*").eq("cache_key", cache_key).maybeSingle().execute()

        if cache_result.data:
            cache_entry = cache_result.data
            # Check if cache is still valid (1 hour)
            cached_at = datetime.fromisoformat(cache_entry.get("cached_at").replace("Z", "+00:00"))
            if datetime.now(cached_at.tzinfo) - cached_at < timedelta(hours=1):
                logger.info(f"Returning cached search results for query '{q}'")
                # Log user context for analytics (cache hit)
                await user_context_service.log_food_search_performed(
                    user_id=user_id,
                    query=q,
                    result_count=len(cache_entry.get("results") or []),
                    cache_hit=True,
                    source="cache",
                )
                return FoodSearchResponse(
                    results=cache_entry.get("results") or [],
                    query=q,
                    total_count=len(cache_entry.get("results") or []),
                    cached=True,
                )

        results = []

        # 1. Search user's saved foods
        saved_result = db.client.table("saved_foods").select("*").eq("user_id", user_id).ilike("name", f"%{search_query}%").limit(limit // 2).execute()

        for food in saved_result.data or []:
            results.append(FoodSearchResult(
                id=food["id"],
                name=food.get("name", "Unknown"),
                source="saved",
                total_calories=food.get("total_calories") or 0,
                protein_g=food.get("total_protein_g") or 0.0,
                carbs_g=food.get("total_carbs_g") or 0.0,
                fat_g=food.get("total_fat_g") or 0.0,
                fiber_g=food.get("total_fiber_g"),
                is_user_food=True,
            ))

        # 2. Search meal templates
        template_result = db.client.table("meal_templates").select("*").or_(f"user_id.eq.{user_id},is_system_template.eq.true").ilike("name", f"%{search_query}%").limit(limit // 4).execute()

        for template in template_result.data or []:
            results.append(FoodSearchResult(
                id=f"template:{template['id']}",
                name=template.get("name", "Unknown"),
                source="template",
                total_calories=template.get("total_calories") or 0,
                protein_g=template.get("total_protein_g") or 0.0,
                carbs_g=template.get("total_carbs_g") or 0.0,
                fat_g=template.get("total_fat_g") or 0.0,
                fiber_g=template.get("total_fiber_g"),
                is_user_food=template.get("user_id") == user_id,
            ))

        # 3. Search food database (if table exists)
        try:
            food_db_result = db.client.table("food_database").select("*").ilike("name", f"%{search_query}%").limit(limit // 4).execute()

            for food in food_db_result.data or []:
                results.append(FoodSearchResult(
                    id=food["id"],
                    name=food.get("name", "Unknown"),
                    source="database",
                    total_calories=food.get("calories") or 0,
                    protein_g=food.get("protein_g") or 0.0,
                    carbs_g=food.get("carbs_g") or 0.0,
                    fat_g=food.get("fat_g") or 0.0,
                    fiber_g=food.get("fiber_g"),
                    serving_size=food.get("serving_size"),
                    brand=food.get("brand"),
                    is_user_food=False,
                ))
        except Exception as e:
            # Food database table might not exist
            logger.debug(f"Food database search skipped: {e}")

        # Limit results
        results = results[:limit]

        # Cache results
        try:
            cache_data = {
                "cache_key": cache_key,
                "user_id": user_id,
                "query": search_query,
                "results": [r.model_dump() for r in results],
                "cached_at": datetime.utcnow().isoformat(),
            }
            db.client.table("food_search_cache").upsert(
                cache_data,
                on_conflict="cache_key"
            ).execute()
        except Exception as e:
            # Cache table might not exist
            logger.debug(f"Failed to cache search results: {e}")

        # Log user context for analytics (fresh search)
        await user_context_service.log_food_search_performed(
            user_id=user_id,
            query=q,
            result_count=len(results),
            cache_hit=False,
            source="api",
        )

        return FoodSearchResponse(
            results=results,
            query=q,
            total_count=len(results),
            cached=False,
        )

    except Exception as e:
        logger.error(f"Error searching foods: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition_preferences")
