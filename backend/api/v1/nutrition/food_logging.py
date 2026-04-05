"""Food logging endpoints (image, text, direct)."""
from datetime import datetime, timedelta
from typing import List, Optional, Tuple
import uuid
import base64
import json
import time
import asyncio

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query, UploadFile, File, Form, Request
from pydantic import BaseModel

from core.timezone_utils import resolve_timezone, local_date_to_utc_range, get_user_today, get_user_now_iso, target_date_to_utc_iso
from core.rate_limiter import limiter
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.activity_logger import log_user_activity, log_user_error
from core.nutrition_bias import apply_calorie_bias, get_user_calorie_bias
from models.schemas import FoodLog, FoodItem

from services.gemini_service import GeminiService
from services.nutrition_rag_service import get_nutrition_rag_service
from services.food_analysis_cache_service import get_food_analysis_cache_service
from services.saved_foods_rag_service import get_saved_foods_rag_service

from api.v1.nutrition.models import (
    LogTextRequest,
    LogDirectRequest,
    LogFoodResponse,
    AnalyzeTextRequest,
    FoodReviewRequest,
)
from api.v1.nutrition.helpers import (
    upload_food_image_to_s3,
    _REGIONAL_KEYWORDS,
)

router = APIRouter()
logger = get_logger(__name__)

# ============================================


@router.post("/log-image", response_model=LogFoodResponse)
@limiter.limit("10/minute")
async def log_food_from_image(
    request: Request,
    background_tasks: BackgroundTasks,
    user_id: str = Form(...),
    meal_type: str = Form(...),
    image: UploadFile = File(...),
    current_user: dict = Depends(get_current_user),
):
    """
    Log food from an image using Gemini Vision.

    This endpoint:
    1. Uploads image to S3 and analyzes with Gemini Vision IN PARALLEL (no delay)
    2. Extracts food items with weight/count fields for portion editing
    3. Creates a food log entry with image URL
    """
    logger.info(f"Logging food from image for user {user_id}, meal_type={meal_type}")

    # SECURITY: Validate file type and size before processing
    ALLOWED_IMAGE_TYPES = {'image/jpeg', 'image/png', 'image/webp', 'image/heic'}
    MAX_IMAGE_SIZE = 10 * 1024 * 1024  # 10MB

    if image.content_type and image.content_type not in ALLOWED_IMAGE_TYPES:
        raise HTTPException(status_code=400, detail=f"Invalid image type. Allowed: {', '.join(ALLOWED_IMAGE_TYPES)}")

    verify_user_ownership(current_user, user_id)

    try:
        # Read and encode image
        image_bytes = await image.read()
        if len(image_bytes) > MAX_IMAGE_SIZE:
            raise HTTPException(status_code=400, detail="Image too large (max 10MB)")
        image_base64 = base64.b64encode(image_bytes).decode('utf-8')

        # Determine mime type
        content_type = image.content_type or 'image/jpeg'

        # Run Gemini analysis and S3 upload IN PARALLEL (no added delay for user)
        logger.info(f"Analyzing image + uploading to S3: size={len(image_bytes)} bytes, mime_type={content_type}")
        gemini_service = GeminiService()

        # Both tasks run concurrently - total time = max(gemini_time, s3_time)
        food_analysis, (image_url, storage_key) = await asyncio.gather(
            gemini_service.analyze_food_image(
                image_base64=image_base64,
                mime_type=content_type,
                user_id=user_id,
            ),
            upload_food_image_to_s3(
                file_bytes=image_bytes,
                user_id=user_id,
                content_type=content_type,
                source="camera",
                meal_type=meal_type,
            ),
        )
        logger.info(f"Gemini analysis result: {food_analysis}")
        logger.info(f"S3 upload complete: {image_url}")

        if not food_analysis or not food_analysis.get('food_items'):
            logger.warning(f"No food items identified in image. Analysis result: {food_analysis}")
            raise HTTPException(
                status_code=400,
                detail="Could not identify any food items in the image"
            )

        # Apply calorie estimate bias (AI estimates only, not barcode)
        bias = await get_user_calorie_bias(user_id)
        if bias != 0:
            food_analysis = apply_calorie_bias(food_analysis, bias)

        # Extract data from analysis (includes weight_g, unit, count, weight_per_unit_g)
        food_items = food_analysis.get('food_items', [])
        total_calories = food_analysis.get('total_calories', 0)
        protein_g = food_analysis.get('protein_g', 0.0)
        carbs_g = food_analysis.get('carbs_g', 0.0)
        fat_g = food_analysis.get('fat_g', 0.0)
        fiber_g = food_analysis.get('fiber_g', 0.0)

        # Extract micronutrients from Gemini analysis
        sugar_g = food_analysis.get('sugar_g')
        sodium_mg = food_analysis.get('sodium_mg')
        cholesterol_mg = food_analysis.get('cholesterol_mg')
        potassium_mg = food_analysis.get('potassium_mg')
        vitamin_a_ug = food_analysis.get('vitamin_a_ug')
        vitamin_c_mg = food_analysis.get('vitamin_c_mg')
        vitamin_d_iu = food_analysis.get('vitamin_d_iu')
        calcium_mg = food_analysis.get('calcium_mg')
        iron_mg = food_analysis.get('iron_mg')

        # Create food log with image URL
        db = get_supabase_db()

        # Resolve timezone for logged_at timestamp
        user_tz = resolve_timezone(request, db, user_id)
        user_tz_logged_at = get_user_now_iso(user_tz)

        created_log = db.create_food_log(
            user_id=user_id,
            meal_type=meal_type,
            food_items=food_items,
            total_calories=total_calories,
            protein_g=protein_g,
            carbs_g=carbs_g,
            fat_g=fat_g,
            fiber_g=fiber_g,
            ai_feedback=food_analysis.get('feedback'),
            health_score=None,
            logged_at=user_tz_logged_at,
            image_url=image_url,
            image_storage_key=storage_key,
            source_type="image",
            # Micronutrients from Gemini analysis
            sugar_g=sugar_g,
            sodium_mg=sodium_mg,
            cholesterol_mg=cholesterol_mg,
            potassium_mg=potassium_mg,
            vitamin_a_ug=vitamin_a_ug,
            vitamin_c_mg=vitamin_c_mg,
            vitamin_d_iu=vitamin_d_iu,
            calcium_mg=calcium_mg,
            iron_mg=iron_mg,
        )

        food_log_id = created_log.get('id') if created_log else "unknown"
        logger.info(f"Successfully logged food from image as {food_log_id}")

        # Background: Log activity analytics (non-critical, don't block response)
        background_tasks.add_task(
            log_user_activity,
            user_id=user_id,
            action="food_log_image",
            endpoint="/api/v1/nutrition/log-image",
            message=f"Logged {len(food_items)} food items from image ({total_calories} cal)",
            metadata={
                "food_log_id": food_log_id,
                "meal_type": meal_type,
                "total_calories": total_calories,
                "food_items_count": len(food_items),
            },
            status_code=200,
        )

        # Calculate confidence based on image analysis factors
        # Higher confidence for clearer images with identifiable foods
        confidence_score = 0.7  # Base confidence for image analysis
        if len(food_items) == 1:
            confidence_score = 0.8  # Single item is more accurate
        elif len(food_items) > 5:
            confidence_score = 0.6  # Complex meals have lower confidence

        confidence_level = "high" if confidence_score >= 0.75 else "medium" if confidence_score >= 0.5 else "low"

        return LogFoodResponse(
            success=True,
            food_log_id=food_log_id,
            food_items=food_items,
            total_calories=total_calories,
            protein_g=protein_g,
            carbs_g=carbs_g,
            fat_g=fat_g,
            fiber_g=fiber_g,
            confidence_score=confidence_score,
            confidence_level=confidence_level,
            source_type="image",
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to log food from image: {e}")
        # Background: Log error analytics (non-critical)
        background_tasks.add_task(
            log_user_error,
            user_id=user_id,
            action="food_log_image",
            error=e,
            endpoint="/api/v1/nutrition/log-image",
            metadata={"meal_type": meal_type},
            status_code=500,
        )
        raise safe_internal_error(e, "nutrition")


@router.post("/log-text", response_model=LogFoodResponse)
@limiter.limit("10/minute")
async def log_food_from_text(body: LogTextRequest, background_tasks: BackgroundTasks, request: Request, current_user: dict = Depends(get_current_user)):
    """
    Log food from a text description using Gemini with goal-based analysis.

    This endpoint:
    1. Fetches user's fitness goals and nutrition targets
    2. Parses the text description with Gemini (with goal context)
    3. Extracts food items with per-item rankings
    4. Creates a food log entry with AI suggestions

    Example descriptions:
    - "2 eggs, toast with butter, and orange juice"
    - "chicken salad with grilled chicken, lettuce, tomatoes, and ranch dressing"
    - "a bowl of oatmeal with banana and honey"
    """
    logger.info(f"Logging food from text for user {body.user_id}: {body.description[:50]}...")

    try:
        db = get_supabase_db()

        # Fetch user goals and nutrition targets for personalized analysis
        user_goals = None
        nutrition_targets = None
        try:
            user = db.get_user(body.user_id)
            if user:
                user = db.enrich_user_with_nutrition_targets(user)
                # Parse goals from JSON string
                goals_str = user.get('goals', '[]')
                if isinstance(goals_str, str):
                    import json
                    try:
                        user_goals = json.loads(goals_str)
                    except json.JSONDecodeError:
                        user_goals = []
                elif isinstance(goals_str, list):
                    user_goals = goals_str

                # Get nutrition targets
                nutrition_targets = {
                    'daily_calorie_target': user.get('daily_calorie_target'),
                    'daily_protein_target_g': user.get('daily_protein_target_g'),
                    'daily_carbs_target_g': user.get('daily_carbs_target_g'),
                    'daily_fat_target_g': user.get('daily_fat_target_g'),
                }
                logger.info(f"User goals: {user_goals}, targets: {nutrition_targets}")
        except Exception as e:
            logger.warning(f"Could not fetch user goals/targets: {e}")

        # Get RAG context from nutrition knowledge base (if user has goals)
        rag_context = None
        if user_goals:
            try:
                nutrition_rag = get_nutrition_rag_service()
                rag_context = await nutrition_rag.get_context_for_goals(
                    food_description=body.description,
                    user_goals=user_goals,
                    n_results=5,
                )
                if rag_context:
                    logger.info(f"Retrieved RAG context ({len(rag_context)} chars) for goals: {user_goals}")
            except Exception as e:
                logger.warning(f"Could not fetch RAG context: {e}")

        # Parse description through cache service (DB-first, then Gemini)
        cache_service = get_food_analysis_cache_service()
        food_analysis = await cache_service.analyze_food(
            description=body.description,
            user_goals=user_goals,
            nutrition_targets=nutrition_targets,
            rag_context=rag_context,
            use_cache=True,
            user_id=body.user_id,
            mood_before=body.mood_before,
            meal_type=body.meal_type,
        )

        if not food_analysis or not food_analysis.get('food_items'):
            raise HTTPException(
                status_code=400,
                detail="Could not parse any food items from the description"
            )

        # Apply calorie estimate bias (AI estimates only, not DB-sourced)
        bias = await get_user_calorie_bias(body.user_id)
        cache_source = food_analysis.get('cache_source')
        is_ai_estimate = cache_source in (None, 'gemini_fresh', 'analysis_cache')
        if bias != 0 and is_ai_estimate:
            food_analysis = apply_calorie_bias(food_analysis, bias)

        # Extract data from analysis
        food_items = food_analysis.get('food_items', [])
        total_calories = food_analysis.get('total_calories', 0)
        protein_g = food_analysis.get('protein_g', 0.0)
        carbs_g = food_analysis.get('carbs_g', 0.0)
        fat_g = food_analysis.get('fat_g', 0.0)
        fiber_g = food_analysis.get('fiber_g', 0.0)

        # Extract enhanced analysis fields
        overall_meal_score = food_analysis.get('overall_meal_score')
        health_score = food_analysis.get('health_score')
        goal_alignment_percentage = food_analysis.get('goal_alignment_percentage')
        ai_suggestion = food_analysis.get('ai_suggestion') or food_analysis.get('feedback')
        encouragements = food_analysis.get('encouragements', [])
        warnings = food_analysis.get('warnings', [])
        recommended_swap = food_analysis.get('recommended_swap')

        # Extract micronutrients from Gemini analysis
        sugar_g = food_analysis.get('sugar_g')
        sodium_mg = food_analysis.get('sodium_mg')
        cholesterol_mg = food_analysis.get('cholesterol_mg')
        potassium_mg = food_analysis.get('potassium_mg')
        vitamin_a_ug = food_analysis.get('vitamin_a_ug')
        vitamin_c_mg = food_analysis.get('vitamin_c_mg')
        vitamin_d_iu = food_analysis.get('vitamin_d_iu')
        calcium_mg = food_analysis.get('calcium_mg')
        iron_mg = food_analysis.get('iron_mg')

        # Resolve timezone for logged_at timestamp
        user_tz_logged_at = None
        if request:
            user_tz = resolve_timezone(request, db, body.user_id)
            user_tz_logged_at = get_user_now_iso(user_tz)

        # Save to database using positional arguments
        created_log = db.create_food_log(
            user_id=body.user_id,
            meal_type=body.meal_type,
            food_items=food_items,
            total_calories=total_calories,
            protein_g=protein_g,
            carbs_g=carbs_g,
            fat_g=fat_g,
            fiber_g=fiber_g,
            ai_feedback=ai_suggestion,
            health_score=health_score,
            logged_at=user_tz_logged_at,
            # Micronutrients from Gemini analysis
            sugar_g=sugar_g,
            sodium_mg=sodium_mg,
            cholesterol_mg=cholesterol_mg,
            potassium_mg=potassium_mg,
            vitamin_a_ug=vitamin_a_ug,
            vitamin_c_mg=vitamin_c_mg,
            vitamin_d_iu=vitamin_d_iu,
            calcium_mg=calcium_mg,
            iron_mg=iron_mg,
        )

        # Get the food log ID from the created record
        food_log_id = created_log.get('id') if created_log else "unknown"

        logger.info(f"Successfully logged food from text as {food_log_id}")

        # Background: Log activity analytics (non-critical, don't block response)
        background_tasks.add_task(
            log_user_activity,
            user_id=body.user_id,
            action="food_log_text",
            endpoint="/api/v1/nutrition/log-text",
            message=f"Logged {len(food_items)} food items from text ({total_calories} cal)",
            metadata={
                "food_log_id": food_log_id,
                "meal_type": body.meal_type,
                "total_calories": total_calories,
                "food_items_count": len(food_items),
                "health_score": health_score,
            },
            status_code=200,
        )

        # Text descriptions are generally more accurate than images
        confidence_score = 0.85  # Base confidence for text
        if len(body.description) < 20:
            confidence_score = 0.7  # Short descriptions have less context
        elif "about" in body.description.lower() or "roughly" in body.description.lower():
            confidence_score = 0.65  # Approximate language reduces confidence

        confidence_level = "high" if confidence_score >= 0.75 else "medium" if confidence_score >= 0.5 else "low"

        return LogFoodResponse(
            success=True,
            food_log_id=food_log_id,
            food_items=food_items,
            total_calories=total_calories,
            protein_g=protein_g,
            carbs_g=carbs_g,
            fat_g=fat_g,
            fiber_g=fiber_g,
            overall_meal_score=overall_meal_score,
            health_score=health_score,
            goal_alignment_percentage=goal_alignment_percentage,
            ai_suggestion=ai_suggestion,
            encouragements=encouragements,
            warnings=warnings,
            recommended_swap=recommended_swap,
            confidence_score=confidence_score,
            confidence_level=confidence_level,
            source_type="text",
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to log food from text: {e}")
        # Background: Log error analytics (non-critical)
        background_tasks.add_task(
            log_user_error,
            user_id=body.user_id,
            action="food_log_text",
            error=e,
            endpoint="/api/v1/nutrition/log-text",
            metadata={
                "meal_type": body.meal_type,
                "description": body.description[:100] if body.description else None,
            },
            status_code=500,
        )
        raise safe_internal_error(e, "nutrition")


# ============================================
# Direct Food Logging (for restaurant mode, manual adjustments)
# ============================================


@router.post("/log-direct", response_model=LogFoodResponse)
@limiter.limit("10/minute")
async def log_food_direct(body: LogDirectRequest, request: Request, current_user: dict = Depends(get_current_user)):
    """
    Log pre-analyzed food directly without AI processing.

    Used for:
    - Restaurant mode with portion adjustments
    - Manual food entry
    - Adjusted servings from previous logs

    The caller provides the nutrition data directly, which is logged as-is.
    """
    logger.info(f"Logging food directly for user {body.user_id}, source: {body.source_type}")

    # Debug: Log incoming values
    logger.info(
        f"[LOG-DIRECT] RECEIVED VALUES | "
        f"user={body.user_id} | "
        f"calories={body.total_calories} | "
        f"protein={body.total_protein} | "
        f"carbs={body.total_carbs} | "
        f"fat={body.total_fat} | "
        f"food_items_count={len(body.food_items)}"
    )
    if body.food_items:
        for idx, item in enumerate(body.food_items[:3]):  # Log first 3 items
            logger.info(f"[LOG-DIRECT] ITEM[{idx}] | name={item.get('name')} | calories={item.get('calories')}")

    try:
        db = get_supabase_db()

        # Build micronutrients dict from request
        micronutrients = {}
        micronutrient_fields = [
            'sodium_mg', 'sugar_g', 'saturated_fat_g', 'cholesterol_mg', 'potassium_mg',
            'vitamin_a_ug', 'vitamin_c_mg', 'vitamin_d_iu', 'vitamin_e_mg', 'vitamin_k_ug',
            'vitamin_b1_mg', 'vitamin_b2_mg', 'vitamin_b3_mg', 'vitamin_b5_mg', 'vitamin_b6_mg',
            'vitamin_b7_ug', 'vitamin_b9_ug', 'vitamin_b12_ug',
            'calcium_mg', 'iron_mg', 'magnesium_mg', 'zinc_mg', 'phosphorus_mg',
            'copper_mg', 'manganese_mg', 'selenium_ug', 'choline_mg', 'omega3_g', 'omega6_g',
        ]
        for field in micronutrient_fields:
            value = getattr(body, field, None)
            if value is not None:
                micronutrients[field] = value

        # Resolve timezone for logged_at timestamp
        user_tz_logged_at = None
        if request:
            user_tz = resolve_timezone(request, db, body.user_id)
            user_tz_logged_at = get_user_now_iso(user_tz)

        # Create food log directly
        created_log = db.create_food_log(
            user_id=body.user_id,
            meal_type=body.meal_type,
            food_items=body.food_items,
            total_calories=body.total_calories,
            protein_g=body.total_protein,
            carbs_g=body.total_carbs,
            fat_g=body.total_fat,
            fiber_g=body.total_fiber,
            ai_feedback=f"Logged via {body.source_type}" + (f": {body.notes}" if body.notes else ""),
            health_score=None,  # No AI scoring for direct logs
            logged_at=user_tz_logged_at,
            **micronutrients,
        )

        food_log_id = created_log.get('id') if created_log else "unknown"
        logger.info(f"Successfully logged food directly as {food_log_id}")

        # Restaurant mode has lower confidence due to portion estimation
        confidence_score = 0.6 if body.source_type == "restaurant" else 0.9
        confidence_level = "medium" if body.source_type == "restaurant" else "high"

        return LogFoodResponse(
            success=True,
            food_log_id=food_log_id,
            food_items=body.food_items,
            total_calories=body.total_calories,
            protein_g=float(body.total_protein),
            carbs_g=float(body.total_carbs),
            fat_g=float(body.total_fat),
            fiber_g=float(body.total_fiber) if body.total_fiber else 0.0,
            overall_meal_score=None,
            ai_suggestion=None,
            confidence_score=confidence_score,
            confidence_level=confidence_level,
            source_type=body.source_type,
        )
    except Exception as e:
        logger.error(f"Error logging food directly: {e}")
        raise safe_internal_error(e, "nutrition")


# ============================================
# Streaming Food Logging Endpoints
# ============================================


@router.post("/log-text-stream")
@limiter.limit("10/minute")
async def log_food_from_text_streaming(request: Request, body: LogTextRequest, current_user: dict = Depends(get_current_user)):
    """
    Log food from text description with streaming progress updates via SSE.

    Provides real-time feedback during food analysis:
    - Step 1: Loading user profile and goals
    - Step 2: Analyzing food with AI
    - Step 3: Calculating nutrition
    - Step 4: Saving to database

    Returns SSE events with progress updates and final food log.
    """
    logger.info(f"[STREAM] Logging food from text for user {body.user_id}: {body.description[:50]}...")

    async def generate_sse() -> AsyncGenerator[str, None]:
        start_time = time.time()

        def elapsed_ms() -> int:
            return int((time.time() - start_time) * 1000)

        def send_progress(step: int, total: int, message: str, detail: str = None):
            data = {
                "type": "progress",
                "step": step,
                "total_steps": total,
                "message": message,
                "detail": detail,
                "elapsed_ms": elapsed_ms()
            }
            return f"event: progress\ndata: {json.dumps(data)}\n\n"

        def send_error(error: str):
            data = {"type": "error", "error": error, "elapsed_ms": elapsed_ms()}
            return f"event: error\ndata: {json.dumps(data)}\n\n"

        try:
            # Step 1: Load user profile and goals
            yield send_progress(1, 4, "Loading your profile...", "Fetching nutrition goals")

            db = get_supabase_db()

            user_goals = None
            nutrition_targets = None
            try:
                user = db.get_user(body.user_id)
                if user:
                    user = db.enrich_user_with_nutrition_targets(user)
                    goals_str = user.get('goals', '[]')
                    if isinstance(goals_str, str):
                        try:
                            user_goals = json.loads(goals_str)
                        except json.JSONDecodeError:
                            user_goals = []
                    elif isinstance(goals_str, list):
                        user_goals = goals_str

                    nutrition_targets = {
                        'daily_calorie_target': user.get('daily_calorie_target'),
                        'daily_protein_target_g': user.get('daily_protein_target_g'),
                        'daily_carbs_target_g': user.get('daily_carbs_target_g'),
                        'daily_fat_target_g': user.get('daily_fat_target_g'),
                    }
            except Exception as e:
                logger.warning(f"[STREAM] Could not fetch user goals: {e}")

            # Step 2: Check cache and analyze with AI
            yield send_progress(2, 4, "Analyzing your food...", "Checking food database")

            # Use caching service for faster lookups
            cache_service = get_food_analysis_cache_service()

            # First try cache (saved foods + overrides + common foods + cached AI responses)
            cache_task = asyncio.create_task(cache_service.analyze_food(
                description=body.description,
                user_goals=user_goals,
                nutrition_targets=nutrition_targets,
                rag_context=None,  # Skip RAG on cache hit for speed
                use_cache=True,
                user_id=body.user_id,
                mood_before=body.mood_before,
                meal_type=body.meal_type,
            ))
            while not cache_task.done():
                try:
                    await asyncio.wait_for(asyncio.shield(cache_task), timeout=10.0)
                except asyncio.TimeoutError:
                    yield ": keep-alive\n\n"
            food_analysis = cache_task.result()

            # If cache hit, log it
            if food_analysis and food_analysis.get("cache_hit"):
                cache_source = food_analysis.get("cache_source", "cache")
                logger.info(f"[STREAM] 🎯 Cache HIT ({cache_source}) for: {body.description[:50]}...")
            else:
                # Cache miss - get RAG context for better AI response
                rag_context = None
                if user_goals:
                    try:
                        nutrition_rag = get_nutrition_rag_service()
                        rag_context = await nutrition_rag.get_context_for_goals(
                            food_description=body.description,
                            user_goals=user_goals,
                            n_results=3,  # Reduced from 5 for speed
                        )
                    except Exception as e:
                        logger.warning(f"[STREAM] Could not fetch RAG context: {e}")

                # Re-analyze with RAG context (cache will save for next time)
                analysis_task = asyncio.create_task(cache_service.analyze_food(
                    description=body.description,
                    user_goals=user_goals,
                    nutrition_targets=nutrition_targets,
                    rag_context=rag_context,
                    use_cache=True,  # Will cache this new result
                    user_id=body.user_id,
                    mood_before=body.mood_before,
                    meal_type=body.meal_type,
                ))
                while not analysis_task.done():
                    try:
                        await asyncio.wait_for(asyncio.shield(analysis_task), timeout=10.0)
                    except asyncio.TimeoutError:
                        yield ": keep-alive\n\n"
                food_analysis = analysis_task.result()

            if not food_analysis or not food_analysis.get('food_items'):
                yield send_error("Could not identify any food items from your description")
                return

            # Apply calorie estimate bias (AI estimates only)
            bias = await get_user_calorie_bias(body.user_id)
            if bias != 0:
                food_analysis = apply_calorie_bias(food_analysis, bias)

            # Step 3: Calculate nutrition
            yield send_progress(3, 4, "Calculating nutrition...", f"Found {len(food_analysis.get('food_items', []))} items")

            food_items = food_analysis.get('food_items', [])
            total_calories = food_analysis.get('total_calories', 0)
            protein_g = food_analysis.get('protein_g', 0.0)
            carbs_g = food_analysis.get('carbs_g', 0.0)
            fat_g = food_analysis.get('fat_g', 0.0)
            fiber_g = food_analysis.get('fiber_g', 0.0)
            overall_meal_score = food_analysis.get('overall_meal_score')
            health_score = food_analysis.get('health_score')
            goal_alignment_percentage = food_analysis.get('goal_alignment_percentage')
            ai_suggestion = food_analysis.get('ai_suggestion') or food_analysis.get('feedback')
            encouragements = food_analysis.get('encouragements', [])
            warnings = food_analysis.get('warnings', [])
            recommended_swap = food_analysis.get('recommended_swap')

            # Extract micronutrients from analysis
            micronutrients = {}
            micronutrient_keys = [
                'sodium_mg', 'sugar_g', 'saturated_fat_g', 'cholesterol_mg', 'potassium_mg',
                'vitamin_a_ug', 'vitamin_a_iu', 'vitamin_c_mg', 'vitamin_d_iu', 'vitamin_e_mg',
                'vitamin_k_ug', 'vitamin_b1_mg', 'vitamin_b2_mg', 'vitamin_b3_mg', 'vitamin_b5_mg',
                'vitamin_b6_mg', 'vitamin_b7_ug', 'vitamin_b9_ug', 'vitamin_b12_ug',
                'calcium_mg', 'iron_mg', 'magnesium_mg', 'zinc_mg', 'phosphorus_mg',
                'copper_mg', 'manganese_mg', 'selenium_ug', 'choline_mg', 'omega3_g', 'omega6_g',
            ]
            for key in micronutrient_keys:
                value = food_analysis.get(key)
                if value is not None:
                    # Convert vitamin_a_iu to vitamin_a_ug (1 IU = 0.3 ug retinol)
                    if key == 'vitamin_a_iu':
                        micronutrients['vitamin_a_ug'] = float(value) * 0.3
                    else:
                        micronutrients[key] = float(value) if value else None

            # Step 4: Save to database
            yield send_progress(4, 4, "Saving your meal...", "Almost done!")

            # Resolve timezone for logged_at timestamp
            stream_user_tz = resolve_timezone(request, db, body.user_id)
            stream_logged_at = get_user_now_iso(stream_user_tz)

            created_log = db.create_food_log(
                user_id=body.user_id,
                meal_type=body.meal_type,
                food_items=food_items,
                total_calories=total_calories,
                protein_g=protein_g,
                carbs_g=carbs_g,
                fat_g=fat_g,
                fiber_g=fiber_g,
                ai_feedback=ai_suggestion,
                health_score=health_score,
                logged_at=stream_logged_at,
                **micronutrients,
            )

            food_log_id = created_log.get('id') if created_log else "unknown"
            logger.info(f"[STREAM] Successfully logged food from text as {food_log_id}")

            # Send the completed food log
            cache_hit = food_analysis.get("cache_hit", False) if food_analysis else False
            cache_source = food_analysis.get("cache_source") if food_analysis else None

            response_data = {
                "success": True,
                "food_log_id": food_log_id,
                "food_items": food_items,
                "total_calories": total_calories,
                "protein_g": protein_g,
                "carbs_g": carbs_g,
                "fat_g": fat_g,
                "fiber_g": fiber_g,
                "overall_meal_score": overall_meal_score,
                "health_score": health_score,
                "goal_alignment_percentage": goal_alignment_percentage,
                "ai_suggestion": ai_suggestion,
                "encouragements": encouragements,
                "warnings": warnings,
                "recommended_swap": recommended_swap,
                "total_time_ms": elapsed_ms(),
                "cache_hit": cache_hit,
                "cache_source": cache_source,
            }
            yield f"event: done\ndata: {json.dumps(response_data)}\n\n"

        except Exception as e:
            logger.error(f"[STREAM] Food logging error: {e}")
            yield send_error(str(e))

    return StreamingResponse(
        generate_sse(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        }
    )


@router.post("/analyze-text")
@limiter.limit("10/minute")
async def analyze_food_text(
    request: Request,
    body: AnalyzeTextRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Analyze food from text description (non-streaming).

    DOES NOT save to database - returns analysis only for user review.
    Use /log-direct to save after user confirmation.

    Returns the full analysis result as JSON with an 8s timeout.
    On timeout, returns HTTP 504.
    """
    logger.info(f"[ANALYZE-TEXT] Analyzing food for user {current_user['id']}: {body.description[:80]}...")

    cache_service = get_food_analysis_cache_service()
    try:
        result = await asyncio.wait_for(
            cache_service.analyze_food(
                description=body.description,
                user_id=current_user["id"],
                use_cache=True,
            ),
            timeout=8.0,
        )
        if result:
            return result
        raise HTTPException(status_code=422, detail="Could not analyze food")
    except asyncio.TimeoutError:
        logger.warning(f"[ANALYZE-TEXT] Timed out for: {body.description[:80]}")
        raise HTTPException(status_code=504, detail="Analysis timed out")
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[ANALYZE-TEXT] Error: {e}")
        raise safe_internal_error(e, "nutrition")



@router.post("/food-review")
@limiter.limit("20/minute")
async def review_food(
    request: Request,
    body: FoodReviewRequest,
    current_user: dict = Depends(get_current_user),
):
    """AI-powered food review based on user goals."""
    logger.info(f"[FOOD-REVIEW] Reviewing '{body.food_name}' for user {current_user['id']}")

    cache_service = get_food_analysis_cache_service()
    macros = {
        "calories": body.calories,
        "protein_g": body.protein_g,
        "carbs_g": body.carbs_g,
        "fat_g": body.fat_g,
    }
    try:
        result = await asyncio.wait_for(
            cache_service.review_food(
                food_name=body.food_name,
                macros=macros,
                user_id=current_user["id"],
            ),
            timeout=10.0,
        )
        return result
    except asyncio.TimeoutError:
        logger.warning(f"[FOOD-REVIEW] Timed out for: {body.food_name}")
        raise HTTPException(status_code=504, detail="Food review timed out")
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[FOOD-REVIEW] Error: {e}")
        raise safe_internal_error(e, "nutrition")


