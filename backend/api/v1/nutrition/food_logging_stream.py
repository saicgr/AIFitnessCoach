"""Streaming food logging and analysis endpoints."""
from datetime import datetime, timedelta
from typing import List, Optional, AsyncGenerator, Tuple
import uuid
import base64
import json
import time
import asyncio

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query, UploadFile, File, Form, Request
from fastapi.responses import StreamingResponse
from pydantic import BaseModel

from core.timezone_utils import resolve_timezone, local_date_to_utc_range, get_user_today, get_user_now_iso, target_date_to_utc_iso
from core.rate_limiter import limiter
from core.auth import get_current_user, verify_user_ownership
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
    LogFoodResponse,
)
from api.v1.nutrition.helpers import (
    upload_food_image_to_s3,
    _REGIONAL_KEYWORDS,
)

router = APIRouter()
logger = get_logger(__name__)

@router.post("/analyze-text-stream")
@limiter.limit("10/minute")
async def analyze_food_from_text_streaming(request: Request, body: LogTextRequest, current_user: dict = Depends(get_current_user)):
    """
    Analyze food from text description with streaming progress updates via SSE.

    DOES NOT save to database - returns analysis only for user review.
    Use /log-direct to save after user confirmation.

    Provides real-time feedback during food analysis:
    - Step 1: Analyzing your food (parallel profile + cache check)
    - Step 2: Calculating nutrition (AI analysis, skipped on cache hit)
    - Step 3: Finalizing results

    Returns SSE events with progress updates and final analysis (no save).
    """
    logger.info(f"[ANALYZE-STREAM] Analyzing food from text for user {body.user_id}: {body.description[:50]}...")

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
            # Step 0: Check for contextual meal reference (leftovers, same thing, my usual, etc.)
            from services.contextual_meal_service import detect_and_resolve as detect_contextual
            from core.db.nutrition_db import NutritionDB

            contextual_db = NutritionDB()
            contextual_result = await detect_contextual(
                description=body.description,
                user_id=body.user_id,
                current_meal_type=body.meal_type,
                nutrition_db=contextual_db,
            )

            if contextual_result is not None:
                if contextual_result.found:
                    # Resolved from history — return items directly, skip Gemini
                    logger.info(f"[ANALYZE-STREAM] Contextual match: {contextual_result.source_label}")
                    yield send_progress(1, 1, "Found in your history!", contextual_result.source_label)

                    response_data = {
                        "success": True,
                        "is_analysis_only": True,
                        "food_items": contextual_result.items,
                        "total_calories": contextual_result.total_calories,
                        "protein_g": contextual_result.protein_g,
                        "carbs_g": contextual_result.carbs_g,
                        "fat_g": contextual_result.fat_g,
                        "fiber_g": contextual_result.fiber_g,
                        "source_type": "history",
                        "source_label": contextual_result.source_label,
                        "total_time_ms": elapsed_ms(),
                        "cache_hit": True,
                        "cache_source": "meal_history",
                    }
                    yield f"event: done\ndata: {json.dumps(response_data)}\n\n"
                    return
                else:
                    # Reference detected but no matching history — return error with helpful message
                    logger.info(f"[ANALYZE-STREAM] Contextual reference not found: {contextual_result.message}")
                    yield send_error(contextual_result.message or "No matching meals found.")
                    return

            # Step 1: Analyze food (parallel user profile + cache check)
            yield send_progress(1, 3, "Analyzing your food...", "Loading profile & checking cache")

            db = get_supabase_db()
            cache_service = get_food_analysis_cache_service()

            # Check if this is a complex/regional food that may take longer
            description_lower = body.description.lower()
            description_words = set(description_lower.split())
            is_complex = bool(description_words & _REGIONAL_KEYWORDS)

            # Run user profile fetch and cache check in parallel
            user_goals = None
            nutrition_targets = None

            async def fetch_user_profile():
                """Fetch user profile in executor since db.get_user() is sync."""
                loop = asyncio.get_event_loop()
                return await loop.run_in_executor(None, db.get_user, body.user_id)

            async def check_cache():
                """Initial cache check without RAG context."""
                return await cache_service.analyze_food(
                    description=body.description,
                    user_goals=None,  # No user goals yet during parallel fetch
                    nutrition_targets=None,
                    rag_context=None,
                    use_cache=True,
                    user_id=body.user_id,
                    mood_before=body.mood_before,
                    meal_type=body.meal_type,
                )

            try:
                user, food_analysis = await asyncio.gather(
                    fetch_user_profile(),
                    check_cache(),
                )

                # Process user profile
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
                logger.warning(f"[ANALYZE-STREAM] Could not fetch user/cache: {e}")
                food_analysis = None

            # If cache hit, skip to finalizing
            if food_analysis and food_analysis.get("cache_hit"):
                cache_source = food_analysis.get("cache_source", "cache")
                logger.info(f"[ANALYZE-STREAM] Cache HIT ({cache_source}) for: {body.description[:50]}...")
                yield send_progress(3, 3, "Finalizing results...", f"Found in {cache_source}!")
            else:
                # Cache miss - do full AI analysis
                # Step 2: Calculate nutrition with AI
                desc_preview = body.description[:30] + "..." if len(body.description) > 30 else body.description
                if is_complex:
                    yield send_progress(2, 3, "Calculating nutrition...", f"Analyzing regional cuisine: {desc_preview}")
                else:
                    yield send_progress(2, 3, "Calculating nutrition...", f"Analyzing: {desc_preview}")

                # Get RAG context only for complex foods with user goals
                rag_context = None
                if user_goals and is_complex:
                    try:
                        nutrition_rag = get_nutrition_rag_service()
                        rag_context = await nutrition_rag.get_context_for_goals(
                            food_description=body.description,
                            user_goals=user_goals,
                            n_results=3,
                        )
                    except Exception as e:
                        logger.warning(f"[ANALYZE-STREAM] Could not fetch RAG context: {e}")

                # Skip cache checks (already done above) — go straight to Gemini
                # Run analysis as a task and send keep-alive pings to prevent
                # Render proxy from closing the SSE connection during long AI calls
                analysis_task = asyncio.create_task(cache_service.analyze_food(
                    description=body.description,
                    user_goals=user_goals,
                    nutrition_targets=nutrition_targets,
                    rag_context=rag_context,
                    use_cache=False,
                    user_id=body.user_id,
                    mood_before=body.mood_before,
                    meal_type=body.meal_type,
                ))

                # Send SSE keep-alive comments every 10s while waiting for Gemini
                while not analysis_task.done():
                    try:
                        await asyncio.wait_for(asyncio.shield(analysis_task), timeout=10.0)
                    except asyncio.TimeoutError:
                        # Task still running — send keep-alive to prevent proxy timeout
                        yield ": keep-alive\n\n"

                food_analysis = analysis_task.result()

            if not food_analysis or not food_analysis.get('food_items'):
                yield send_error("Could not identify any food items from your description")
                return

            if not food_analysis.get("cache_hit"):
                # Step 3: Finalize results (only show for non-cached)
                yield send_progress(3, 3, "Finalizing results...", f"Found {len(food_analysis.get('food_items', []))} items")

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

            # Micronutrients
            sodium_mg = food_analysis.get('sodium_mg')
            sugar_g = food_analysis.get('sugar_g')
            saturated_fat_g = food_analysis.get('saturated_fat_g')
            cholesterol_mg = food_analysis.get('cholesterol_mg')
            potassium_mg = food_analysis.get('potassium_mg')
            vitamin_a_iu = food_analysis.get('vitamin_a_iu')
            vitamin_c_mg = food_analysis.get('vitamin_c_mg')
            vitamin_d_iu = food_analysis.get('vitamin_d_iu')
            calcium_mg = food_analysis.get('calcium_mg')
            iron_mg = food_analysis.get('iron_mg')

            logger.info(f"[ANALYZE-STREAM] Analysis complete for user {body.user_id}: {total_calories} calories")

            # Send the analysis result (NO database save - user must confirm first)
            cache_hit = food_analysis.get("cache_hit", False) if food_analysis else False
            cache_source = food_analysis.get("cache_source") if food_analysis else None

            response_data = {
                "success": True,
                "is_analysis_only": True,  # Flag to indicate this is not yet saved
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
                "source_type": "text",
                "total_time_ms": elapsed_ms(),
                "cache_hit": cache_hit,
                "cache_source": cache_source,
                # Micronutrients
                "sodium_mg": sodium_mg,
                "sugar_g": sugar_g,
                "saturated_fat_g": saturated_fat_g,
                "cholesterol_mg": cholesterol_mg,
                "potassium_mg": potassium_mg,
                "vitamin_a_iu": vitamin_a_iu,
                "vitamin_c_mg": vitamin_c_mg,
                "vitamin_d_iu": vitamin_d_iu,
                "calcium_mg": calcium_mg,
                "iron_mg": iron_mg,
            }
            yield f"event: done\ndata: {json.dumps(response_data)}\n\n"

        except Exception as e:
            logger.error(f"[ANALYZE-STREAM] Food analysis error: {e}")
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


@router.post("/log-image-stream")
@limiter.limit("10/minute")
async def log_food_from_image_streaming(
    request: Request,
    user_id: str = Form(...),
    meal_type: str = Form(...),
    image: UploadFile = File(...),
    current_user: dict = Depends(get_current_user),
):
    """
    Log food from an image with streaming progress updates via SSE.

    Provides real-time feedback during food image analysis:
    - Step 1: Processing image
    - Step 2: AI analyzing food
    - Step 3: Calculating nutrition
    - Step 4: Saving to database

    Returns SSE events with progress updates and final food log.
    """
    logger.info(f"[STREAM] Logging food from image for user {user_id}, meal_type={meal_type}")

    # SECURITY: Validate file type and size before processing
    ALLOWED_IMAGE_TYPES = {'image/jpeg', 'image/png', 'image/webp', 'image/heic'}
    MAX_IMAGE_SIZE = 10 * 1024 * 1024  # 10MB

    if image.content_type and image.content_type not in ALLOWED_IMAGE_TYPES:
        raise HTTPException(status_code=400, detail=f"Invalid image type. Allowed: {', '.join(ALLOWED_IMAGE_TYPES)}")

    verify_user_ownership(current_user, user_id)

    # Read image upfront (before generator)
    image_bytes = await image.read()
    if len(image_bytes) > MAX_IMAGE_SIZE:
        raise HTTPException(status_code=400, detail="Image too large (max 10MB)")
    content_type = image.content_type or 'image/jpeg'

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
            # Step 1: Process image
            yield send_progress(1, 4, "Processing image...", f"{len(image_bytes) // 1024} KB")

            image_base64 = base64.b64encode(image_bytes).decode('utf-8')

            # Step 2: Analyze with AI + Upload to S3 (in parallel)
            yield send_progress(2, 4, "Analyzing your food...", "AI is identifying ingredients")

            gemini_service = GeminiService()

            # Run Gemini analysis and S3 upload concurrently with keep-alive pings
            analysis_task = asyncio.create_task(asyncio.gather(
                gemini_service.analyze_food_image(
                    image_base64=image_base64,
                    mime_type=content_type,
                    user_id=user_id,
                ),
                upload_food_image_to_s3(
                    file_bytes=image_bytes,
                    user_id=user_id,
                    content_type=content_type,
                ),
            ))

            # Send SSE keep-alive comments every 10s while waiting
            while not analysis_task.done():
                try:
                    await asyncio.wait_for(asyncio.shield(analysis_task), timeout=10.0)
                except asyncio.TimeoutError:
                    yield ": keep-alive\n\n"

            food_analysis, (image_url, storage_key) = analysis_task.result()
            logger.info(f"[STREAM] S3 upload complete: {image_url}")

            if not food_analysis or not food_analysis.get('food_items'):
                yield send_error("Could not identify any food items in the image")
                return

            # Apply calorie estimate bias (AI estimates only)
            bias = await get_user_calorie_bias(user_id)
            if bias != 0:
                food_analysis = apply_calorie_bias(food_analysis, bias)

            # Step 3: Calculate nutrition
            food_items = food_analysis.get('food_items', [])
            yield send_progress(3, 4, "Calculating nutrition...", f"Found {len(food_items)} items")

            total_calories = food_analysis.get('total_calories', 0)
            protein_g = food_analysis.get('protein_g', 0.0)
            carbs_g = food_analysis.get('carbs_g', 0.0)
            fat_g = food_analysis.get('fat_g', 0.0)
            fiber_g = food_analysis.get('fiber_g', 0.0)

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

            # Enrich image analysis with contextual coach tips
            ai_suggestion = food_analysis.get('feedback')
            health_score = None
            try:
                cache_service = get_food_analysis_cache_service()
                tips = await cache_service.enrich_with_tips(
                    food_items=food_items,
                    meal_type=meal_type,
                    user_id=user_id,
                )
                if tips:
                    ai_suggestion = tips.get("ai_suggestion") or ai_suggestion
                    health_score = tips.get("health_score")
            except Exception as tip_err:
                logger.warning(f"[STREAM] Tip enrichment failed for image log: {tip_err}")

            # Step 4: Save to database
            yield send_progress(4, 4, "Saving your meal...", "Almost done!")

            db = get_supabase_db()

            # Resolve timezone for logged_at timestamp
            stream_user_tz = resolve_timezone(request, db, user_id)
            stream_logged_at = get_user_now_iso(stream_user_tz)

            created_log = db.create_food_log(
                user_id=user_id,
                meal_type=meal_type,
                food_items=food_items,
                total_calories=total_calories,
                protein_g=protein_g,
                carbs_g=carbs_g,
                fat_g=fat_g,
                fiber_g=fiber_g,
                ai_feedback=ai_suggestion,
                health_score=health_score,
                logged_at=stream_logged_at,
                image_url=image_url,
                image_storage_key=storage_key,
                source_type="image",
                **micronutrients,
            )

            food_log_id = created_log.get('id') if created_log else "unknown"
            logger.info(f"[STREAM] Successfully logged food from image as {food_log_id}")

            # Send the completed food log
            response_data = {
                "success": True,
                "food_log_id": food_log_id,
                "food_items": food_items,
                "total_calories": total_calories,
                "protein_g": protein_g,
                "carbs_g": carbs_g,
                "fat_g": fat_g,
                "fiber_g": fiber_g,
                "ai_suggestion": ai_suggestion,
                "health_score": health_score,
                "total_time_ms": elapsed_ms(),
            }
            yield f"event: done\ndata: {json.dumps(response_data)}\n\n"

        except Exception as e:
            logger.error(f"[STREAM] Image food logging error: {e}")
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


@router.post("/analyze-image-stream")
@limiter.limit("10/minute")
async def analyze_food_from_image_streaming(
    request: Request,
    user_id: str = Form(...),
    meal_type: str = Form(...),
    image: UploadFile = File(...),
    current_user: dict = Depends(get_current_user),
):
    """
    Analyze food from an image with streaming progress updates via SSE.

    DOES NOT save to database - returns analysis only for user review.
    Use /log-direct to save after user confirmation.

    Provides real-time feedback during food image analysis:
    - Step 1: Processing image
    - Step 2: AI analyzing food
    - Step 3: Calculating nutrition (analysis complete)

    Returns SSE events with progress updates and final analysis (no save).
    """
    # SECURITY: Validate file type and size before processing
    ALLOWED_IMAGE_TYPES = {'image/jpeg', 'image/png', 'image/webp', 'image/heic'}
    MAX_IMAGE_SIZE = 10 * 1024 * 1024  # 10MB

    if image.content_type and image.content_type not in ALLOWED_IMAGE_TYPES:
        raise HTTPException(status_code=400, detail=f"Invalid image type. Allowed: {', '.join(ALLOWED_IMAGE_TYPES)}")

    verify_user_ownership(current_user, user_id)

    import uuid
    request_id = f"req_{uuid.uuid4().hex[:12]}"

    # Read image upfront (before generator)
    image_bytes = await image.read()
    if len(image_bytes) > MAX_IMAGE_SIZE:
        raise HTTPException(status_code=400, detail="Image too large (max 10MB)")
    content_type = image.content_type or 'image/jpeg'
    image_size_kb = len(image_bytes) // 1024

    logger.info(
        f"[ANALYZE-STREAM:{request_id}] START | "
        f"user={user_id} | "
        f"meal_type={meal_type} | "
        f"content_type={content_type} | "
        f"image_size_kb={image_size_kb}"
    )

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
                "request_id": request_id,
                "elapsed_ms": elapsed_ms()
            }
            return f"event: progress\ndata: {json.dumps(data)}\n\n"

        def send_error(error: str, error_code: str = "UNKNOWN_ERROR", error_details: str = None):
            data = {
                "type": "error",
                "error": error,
                "error_code": error_code,
                "error_details": error_details,
                "request_id": request_id,
                "user_id": user_id,
                "elapsed_ms": elapsed_ms()
            }
            logger.error(
                f"[ANALYZE-STREAM:{request_id}] FAILED | "
                f"user={user_id} | "
                f"error_code={error_code} | "
                f"error={error} | "
                f"details={error_details} | "
                f"elapsed_ms={elapsed_ms()}"
            )
            return f"event: error\ndata: {json.dumps(data)}\n\n"

        try:
            # Step 1: Process image
            yield send_progress(1, 3, "Processing image...", f"{image_size_kb} KB")
            logger.info(f"[ANALYZE-STREAM:{request_id}] Step 1: Image processing started")

            image_base64 = base64.b64encode(image_bytes).decode('utf-8')

            # Step 2: Analyze with AI
            yield send_progress(2, 3, "Analyzing your food...", "AI is identifying ingredients")
            logger.info(f"[ANALYZE-STREAM:{request_id}] Step 2: Sending to Gemini for analysis")

            gemini_service = GeminiService()

            # Run Gemini analysis and S3 upload in parallel with keep-alive pings
            async def safe_s3_upload():
                """Upload to S3 with graceful failure — don't block analysis."""
                try:
                    return await upload_food_image_to_s3(
                        file_bytes=image_bytes,
                        user_id=user_id,
                        content_type=content_type,
                    )
                except Exception as s3_err:
                    logger.warning(f"[ANALYZE-STREAM:{request_id}] S3 upload failed (non-blocking): {s3_err}")
                    return (None, None)

            analysis_task = asyncio.create_task(asyncio.gather(
                gemini_service.analyze_food_image(
                    image_base64=image_base64,
                    mime_type=content_type,
                    request_id=request_id,
                    user_id=user_id,
                ),
                safe_s3_upload(),
            ))
            while not analysis_task.done():
                try:
                    await asyncio.wait_for(asyncio.shield(analysis_task), timeout=10.0)
                except asyncio.TimeoutError:
                    yield ": keep-alive\n\n"
            food_analysis, (image_url, image_storage_key) = analysis_task.result()
            if image_url:
                logger.info(f"[ANALYZE-STREAM:{request_id}] S3 upload complete: {image_url}")

            # Check if Gemini returned an error structure
            if food_analysis and food_analysis.get('error'):
                yield send_error(
                    food_analysis.get('error'),
                    food_analysis.get('error_code', 'GEMINI_ERROR'),
                    food_analysis.get('error_details')
                )
                return

            # Check for empty or missing food items
            if not food_analysis or not food_analysis.get('food_items'):
                yield send_error(
                    "Could not identify any food items in the image. Please try a clearer photo.",
                    "NO_FOOD_DETECTED",
                    "Gemini analysis returned empty food_items"
                )
                return

            # Step 3: Calculate nutrition (analysis complete - NO SAVE)
            food_items = food_analysis.get('food_items', [])
            yield send_progress(3, 3, "Calculating nutrition...", f"Found {len(food_items)} items")
            logger.info(f"[ANALYZE-STREAM:{request_id}] Step 3: Found {len(food_items)} food items")

            total_calories = food_analysis.get('total_calories', 0)
            protein_g = food_analysis.get('protein_g', 0.0)
            carbs_g = food_analysis.get('carbs_g', 0.0)
            fat_g = food_analysis.get('fat_g', 0.0)
            fiber_g = food_analysis.get('fiber_g', 0.0)

            # Micronutrients
            sodium_mg = food_analysis.get('sodium_mg')
            sugar_g = food_analysis.get('sugar_g')
            saturated_fat_g = food_analysis.get('saturated_fat_g')
            cholesterol_mg = food_analysis.get('cholesterol_mg')
            potassium_mg = food_analysis.get('potassium_mg')
            vitamin_a_iu = food_analysis.get('vitamin_a_iu')
            vitamin_c_mg = food_analysis.get('vitamin_c_mg')
            vitamin_d_iu = food_analysis.get('vitamin_d_iu')
            calcium_mg = food_analysis.get('calcium_mg')
            iron_mg = food_analysis.get('iron_mg')

            plate_description = food_analysis.get('plate_description')

            # Enrich image analysis with contextual coach tips
            ai_suggestion = food_analysis.get('feedback')
            encouragements = []
            warnings = []
            recommended_swap = None
            health_score = None
            try:
                cache_service = get_food_analysis_cache_service()
                tips = await cache_service.enrich_with_tips(
                    food_items=food_items,
                    meal_type=meal_type,
                    user_id=user_id,
                )
                if tips:
                    encouragements = tips.get("encouragements", [])
                    warnings = tips.get("warnings", [])
                    ai_suggestion = tips.get("ai_suggestion") or ai_suggestion
                    recommended_swap = tips.get("recommended_swap")
                    health_score = tips.get("health_score")
            except Exception as tip_err:
                logger.warning(f"[ANALYZE-STREAM:{request_id}] Tip enrichment failed: {tip_err}")

            # Log success with full details
            logger.info(
                f"[ANALYZE-STREAM:{request_id}] SUCCESS | "
                f"user={user_id} | "
                f"meal_type={meal_type} | "
                f"items={len(food_items)} | "
                f"calories={total_calories} | "
                f"protein={protein_g}g | "
                f"carbs={carbs_g}g | "
                f"fat={fat_g}g | "
                f"elapsed_ms={elapsed_ms()}"
            )

            # Send the analysis result (NO database save - user must confirm first)
            response_data = {
                "success": True,
                "is_analysis_only": True,  # Flag to indicate this is not yet saved
                "request_id": request_id,
                "food_items": food_items,
                "total_calories": total_calories,
                "protein_g": protein_g,
                "carbs_g": carbs_g,
                "fat_g": fat_g,
                "fiber_g": fiber_g,
                "ai_suggestion": ai_suggestion,
                "encouragements": encouragements,
                "warnings": warnings,
                "recommended_swap": recommended_swap,
                "health_score": health_score,
                "source_type": "image",
                "total_time_ms": elapsed_ms(),
                # Micronutrients
                "sodium_mg": sodium_mg,
                "sugar_g": sugar_g,
                "saturated_fat_g": saturated_fat_g,
                "cholesterol_mg": cholesterol_mg,
                "potassium_mg": potassium_mg,
                "vitamin_a_iu": vitamin_a_iu,
                "vitamin_c_mg": vitamin_c_mg,
                "vitamin_d_iu": vitamin_d_iu,
                "calcium_mg": calcium_mg,
                "iron_mg": iron_mg,
                # Image storage (from parallel S3 upload)
                "image_url": image_url,
                "image_storage_key": image_storage_key,
                # Visual description of what AI sees
                "plate_description": plate_description,
            }
            yield f"event: done\ndata: {json.dumps(response_data)}\n\n"

        except Exception as e:
            logger.exception(f"[ANALYZE-STREAM:{request_id}] EXCEPTION | user={user_id} | error={e}")
            yield send_error(
                "An unexpected error occurred. Please try again.",
                "UNEXPECTED_EXCEPTION",
                f"{type(e).__name__}: {str(e)}"
            )

    return StreamingResponse(
        generate_sse(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        }
    )


