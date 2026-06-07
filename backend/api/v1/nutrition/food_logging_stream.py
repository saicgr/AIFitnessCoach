"""Streaming food logging and analysis endpoints."""
from datetime import datetime, timedelta
from typing import Any, List, Optional, AsyncGenerator, Tuple
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
from services.food_analysis.personal_history import (
    lookup_personal_history_for_foods,
)
from services.food_analysis.mood_inference import (
    build_insert_patch,
    infer_mood_from_nutrition,
)
from services.food_logging_rules_service import (
    fetch_food_logging_rules,
    build_rules_prompt_block,
)

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


def _build_remembered_message(food_items: list) -> Optional[str]:
    """L3 — derive the meal-level "Zealova remembered…" affirmation.

    `apply_user_food_overrides` tags each item it auto-corrected with a
    `remembered_label`. We collapse those into one short banner string for
    the result sheet. Returns None when nothing was remembered.
    """
    labels = [
        it.get("remembered_label")
        for it in (food_items or [])
        if isinstance(it, dict) and it.get("remembered_label")
    ]
    if not labels:
        return None
    if len(labels) == 1:
        return labels[0]
    # Multiple foods remembered — list the names compactly.
    names = []
    for it in food_items:
        if isinstance(it, dict) and it.get("remembered_label"):
            n = it.get("name")
            if n:
                names.append(str(n))
    if names:
        return f"Zealova remembered your numbers for {', '.join(names)}"
    return f"Zealova remembered {len(labels)} of your foods"

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
        # Hoisted so the CancelledError handler below can cancel the inflight
        # Gemini call when the client disconnects — otherwise the task leaks
        # and we keep paying for tokens we'll never deliver.
        analysis_task: Optional[asyncio.Task] = None

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
            # Step 0: Check for contextual meal reference (leftovers, same thing,
            # my usual, etc.). Short-circuit: only invoke the DB lookup when the
            # description actually contains a contextual reference word —
            # plain new-food entries ("2 eggs, toast, OJ") skip it entirely and
            # save ~0.5-2s on the hot path.
            _desc_lower = (body.description or "").lower()
            _CONTEXTUAL_KEYWORDS = (
                "leftover", "leftovers", "rest of", "rest of the",
                "same as", "same thing", "same again", "again",
                "my usual", "usual", "yesterday", "yesterday's",
                "last night", "last time", "earlier",
            )
            _has_contextual_ref = any(kw in _desc_lower for kw in _CONTEXTUAL_KEYWORDS)

            contextual_result = None
            if _has_contextual_ref:
                from services.contextual_meal_service import detect_and_resolve as detect_contextual
                from core.db.nutrition_db import NutritionDB

                contextual_db = NutritionDB()
                _ctx_tz = await asyncio.to_thread(resolve_timezone, request, get_supabase_db(), body.user_id)
                contextual_result = await detect_contextual(
                    description=body.description,
                    user_id=body.user_id,
                    current_meal_type=body.meal_type,
                    nutrition_db=contextual_db,
                    timezone_str=_ctx_tz,
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

            # Gap 1 — water-in-text. Detect a beverage in the entry concurrently
            # with the food analysis (language-agnostic Flash-Lite pass). This is
            # analysis-only: we surface `hydration_detected` in the `done` payload
            # and the client logs it on confirm via /hydration/log. Gated on the
            # user's pref so an opted-out user pays zero extra LLM cost (Gap 6).
            hydration_task = None
            try:
                from api.v1.nutrition.food_logging import _is_hydration_tracking_enabled
                from services.food_analysis.hydration_split import detect_hydration_in_text
                if _is_hydration_tracking_enabled(db, body.user_id):
                    hydration_task = asyncio.create_task(
                        detect_hydration_in_text(body.description, body.user_id)
                    )
            except Exception as _hyd_err:
                logger.debug(f"[ANALYZE-STREAM] hydration detect skipped: {_hyd_err}")

            async def _resolve_hydration_detected():
                """Await the concurrent hydration task, swallowing any failure."""
                if hydration_task is None:
                    return None
                try:
                    return await hydration_task
                except Exception:
                    return None

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

            # Fetch personal food history in parallel with the cache check so
            # Gemini (or the cache-hit enrichment) can surface re-log warnings.
            candidate_names = [p.strip() for p in body.description.split(",") if p.strip()]

            async def fetch_history():
                try:
                    return await lookup_personal_history_for_foods(
                        body.user_id, candidate_names
                    )
                except Exception as exc:
                    logger.warning(f"[ANALYZE-STREAM] personal history lookup failed: {exc}")
                    return []

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
                    # personal_history is passed again on the real analyze_food
                    # call below when available; the initial cache hit path
                    # uses apply_personal_history_to_cache_hit instead.
                    # SPEED: macros-only + skip the synchronous cache-hit tip
                    # Gemini call. Tips stream in via the deferred `coach_tips`
                    # event below. This is what makes branded hits sub-second.
                    fast_macros_only=True,
                )

            try:
                user, food_analysis, personal_history = await asyncio.gather(
                    fetch_user_profile(),
                    check_cache(),
                    fetch_history(),
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
                logger.warning(f"[ANALYZE-STREAM] Could not fetch user/cache: {e}", exc_info=True)
                food_analysis = None
                personal_history = []

            # If cache hit, skip to finalizing (but enrich with personal history first)
            if food_analysis and food_analysis.get("cache_hit"):
                cache_source = food_analysis.get("cache_source", "cache")
                logger.info(f"[ANALYZE-STREAM] Cache HIT ({cache_source}) for: {body.description[:50]}...")
                if personal_history:
                    cache_service.apply_personal_history_to_cache_hit(
                        food_analysis, personal_history
                    )
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
                        logger.warning(f"[ANALYZE-STREAM] Could not fetch RAG context: {e}", exc_info=True)

                # Skip cache checks (already done above) — go straight to Gemini
                # Run analysis as a task and send keep-alive pings to prevent
                # Render proxy from closing the SSE connection during long AI calls
                # L3 — fetch the user's standing food-logging rules and build
                # the prompt block so they're applied to this text analysis.
                _rules = await asyncio.to_thread(fetch_food_logging_rules, db, body.user_id)
                _rules_block = build_rules_prompt_block(
                    _rules,
                    has_per_log_instruction=bool((body.description or "").strip()),
                )

                analysis_task = asyncio.create_task(cache_service.analyze_food(
                    description=body.description,
                    user_goals=user_goals,
                    nutrition_targets=nutrition_targets,
                    rag_context=rag_context,
                    use_cache=False,
                    user_id=body.user_id,
                    mood_before=body.mood_before,
                    meal_type=body.meal_type,
                    personal_history=personal_history or None,
                    standing_rules_block=_rules_block,
                    # SPEED: macros-only schema (no coaching prose). Tips stream
                    # in via the deferred `coach_tips` event after `done`.
                    fast_macros_only=True,
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
                # Gap 1 — a beverage-only entry ("a glass of water") parses to
                # zero food items. Rather than erroring, emit a hydration-only
                # `done` so the client can log the water and close.
                _hyd_only = await _resolve_hydration_detected()
                if _hyd_only:
                    yield f"event: done\ndata: " + json.dumps({
                        "success": True,
                        "is_analysis_only": True,
                        "is_hydration_only": True,
                        "food_items": [],
                        "total_calories": 0,
                        "protein_g": 0.0,
                        "carbs_g": 0.0,
                        "fat_g": 0.0,
                        "fiber_g": 0.0,
                        "source_type": "text",
                        "total_time_ms": elapsed_ms(),
                        "hydration_detected": _hyd_only,
                    }) + "\n\n"
                    return
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

            # Apply per-user food overrides on the text-stream path too.
            from services.food_override_service import apply_user_food_overrides
            _ov_db = get_supabase_db()
            food_items, _override_totals, _n_overridden = await asyncio.to_thread(
                apply_user_food_overrides,
                _ov_db, body.user_id, food_items,
            )
            if _n_overridden:
                logger.info(f"[STREAM text] Applied {_n_overridden} override(s) for {body.user_id}")
                total_calories = _override_totals["total_calories"]
                protein_g = _override_totals["protein_g"]
                carbs_g = _override_totals["carbs_g"]
                fat_g = _override_totals["fat_g"]

            # L4 — "accuracy you can trust". When the macros came straight from
            # a verified food-DB row (the 198k-row override / common-foods
            # tables), tag each item so the result sheet shows a 'verified'
            # badge instead of treating it as a shaky AI estimate. The model
            # never sets this — it is a server-side cross-check signal.
            if food_analysis.get("cache_hit") and food_analysis.get(
                "cache_source"
            ) in ("override", "common_foods", "multi_lookup", "user_contributed"):
                # B2 — packaging-size variant integrity (stale-cache guard). Don't
                # stamp a base product 'verified' when the query asked for a size
                # variant it doesn't represent ("almond joy king size" → base bar).
                # A fresh (cache-miss) analysis is corrected upstream in
                # _enhance_food_items_with_nutrition_db; this catches entries that
                # were cached before that guard existed.
                from services.food_match_gate import unsatisfied_packaging_qualifiers
                for _it in food_items:
                    if not isinstance(_it, dict):
                        continue
                    try:
                        _unsat = unsatisfied_packaging_qualifiers([body.description], _it)
                    except Exception:
                        _unsat = set()
                    if _unsat:
                        logger.info(
                            f"[STREAM text] packaging-variant mismatch "
                            f"({sorted(_unsat)}) for '{_it.get('name')}' — not "
                            f"stamping verified, flagging for confirmation"
                        )
                        _it["requires_user_confirmation"] = True
                        if not _it.get("confidence"):
                            _it["confidence"] = "medium"
                    else:
                        _it.setdefault("verified_source", "override_db")

            overall_meal_score = food_analysis.get('overall_meal_score')
            health_score = food_analysis.get('health_score')
            health_score_reasons = food_analysis.get('health_score_reasons')
            goal_alignment_percentage = food_analysis.get('goal_alignment_percentage')
            ai_suggestion = food_analysis.get('ai_suggestion') or food_analysis.get('feedback')
            encouragements = food_analysis.get('encouragements', [])
            warnings = food_analysis.get('warnings', [])
            recommended_swap = food_analysis.get('recommended_swap')
            text_inflammation_score = food_analysis.get('inflammation_score')
            text_is_ultra_processed = food_analysis.get('is_ultra_processed')

            # Micronutrients
            sodium_mg = food_analysis.get('sodium_mg')
            sugar_g = food_analysis.get('sugar_g')
            # Gap 7 — opt-in tracker inputs forwarded to the confirm payload.
            added_sugar_g = food_analysis.get('added_sugar_g')
            caffeine_mg = food_analysis.get('caffeine_mg')
            alcohol_g = food_analysis.get('alcohol_g')
            saturated_fat_g = food_analysis.get('saturated_fat_g')
            cholesterol_mg = food_analysis.get('cholesterol_mg')
            potassium_mg = food_analysis.get('potassium_mg')
            vitamin_a_iu = food_analysis.get('vitamin_a_iu')
            vitamin_c_mg = food_analysis.get('vitamin_c_mg')
            vitamin_d_iu = food_analysis.get('vitamin_d_iu')
            calcium_mg = food_analysis.get('calcium_mg')
            iron_mg = food_analysis.get('iron_mg')

            # SPEED PATH — the macros-only Gemini call no longer emits a score,
            # so compute one deterministically (instant) for the badge. The
            # deferred `coach_tips` event below refines it with the LLM's
            # goal-aware score if it differs.
            if overall_meal_score is None:
                try:
                    overall_meal_score = cache_service._compute_health_score(
                        total_calories, protein_g, fiber_g, carbs_g, sugar_g or 0
                    )
                except Exception as _score_err:
                    logger.debug(f"[ANALYZE-STREAM] score compute skipped: {_score_err}")
            if health_score is None:
                health_score = overall_meal_score

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
                "health_score_reasons": health_score_reasons,
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
                "added_sugar_g": added_sugar_g,
                "caffeine_mg": caffeine_mg,
                "alcohol_g": alcohol_g,
                "saturated_fat_g": saturated_fat_g,
                "cholesterol_mg": cholesterol_mg,
                "potassium_mg": potassium_mg,
                "vitamin_a_iu": vitamin_a_iu,
                "vitamin_c_mg": vitamin_c_mg,
                "vitamin_d_iu": vitamin_d_iu,
                "calcium_mg": calcium_mg,
                "iron_mg": iron_mg,
                # Inflammation / ultra-processed tracking
                "inflammation_score": text_inflammation_score,
                "is_ultra_processed": text_is_ultra_processed,
                # A3 — short note of what the user's instruction changed.
                "applied_instruction_note": food_analysis.get('applied_instruction_note'),
                # L3 — "Zealova remembered your <food>" affirmation when a
                # learned correction was auto-applied.
                "remembered_message": _build_remembered_message(food_items),
                # Gap 1 — water-in-text. {amount_ml, drink_type} when a beverage
                # was detected; the client logs it on confirm. None otherwise.
                "hydration_detected": await _resolve_hydration_detected(),
            }
            yield f"event: done\ndata: {json.dumps(response_data)}\n\n"

            # ── Coaching tips — streamed AFTER `done` ──────────────────────
            # The fast macro estimate already rendered. If the analysis did
            # NOT carry coach commentary (the speed-rearchitected fast path
            # often returns macros only), generate it now via a dedicated
            # follow-up Gemini call and ship it as a late `coach_tips` event.
            # Mirrors the image-stream path so the "Coach's Tip" card is
            # always populated. A client that doesn't handle the event just
            # shows no tips — fully graceful.
            already_has_tips = bool(
                (ai_suggestion and str(ai_suggestion).strip())
                or (encouragements and any(str(e).strip() for e in encouragements))
                or (warnings and any(str(w).strip() for w in warnings))
                or (recommended_swap and str(recommended_swap).strip())
            )
            if not already_has_tips and food_items:
                try:
                    tip_tz = resolve_timezone(request, get_supabase_db(), body.user_id)
                    tips = await cache_service.enrich_with_tips(
                        food_items=food_items,
                        meal_type=body.meal_type,
                        mood_before=body.mood_before,
                        user_id=body.user_id,
                        timezone_str=tip_tz or "",
                    )
                    if tips:
                        coach_tips_data = {
                            "ai_suggestion": tips.get("ai_suggestion"),
                            "encouragements": tips.get("encouragements", []),
                            "warnings": tips.get("warnings", []),
                            "recommended_swap": tips.get("recommended_swap"),
                            "health_score": tips.get("health_score") or health_score,
                            "health_score_reasons": tips.get("health_score_reasons")
                            or health_score_reasons,
                            # Refine the badge with the LLM's goal-aware score
                            # (the `done` event already carried the fast
                            # deterministic score so the badge never waits).
                            "overall_meal_score": tips.get("health_score") or overall_meal_score,
                            # L1 — coaching extras: a concrete next-meal idea and
                            # (when the day is well over budget) a coach fork.
                            "next_meal_suggestion": tips.get("next_meal_suggestion"),
                            "over_budget_fork": tips.get("over_budget_fork"),
                            # Smart sauce/side suggestions for the detected food
                            # (tappable chips on the client). Generated by the
                            # same async review call — zero added latency.
                            "suggested_addons": tips.get("suggested_addons", []),
                            # Inflammation — the fast macro path frequently
                            # omits it, so fill it from the deferred review here
                            # (falling back to whatever the `done` event had).
                            # Lets the client show the "Inflammation N/10" pill
                            # beside Health on the estimate screen.
                            "inflammation_score": tips.get("inflammation_score")
                            if tips.get("inflammation_score") is not None
                            else text_inflammation_score,
                            "inflammation_triggers": tips.get("inflammation_triggers", []),
                        }
                        yield f"event: coach_tips\ndata: {json.dumps(coach_tips_data)}\n\n"
                except Exception as tip_err:
                    logger.warning(
                        f"[ANALYZE-STREAM] coach_tips enrichment failed: {tip_err}"
                    )

        except asyncio.CancelledError:
            # Client disconnected mid-stream. Cancel the inflight Gemini call
            # so we stop awaiting it (we already paid for any in-flight HTTP
            # request, but at least the task doesn't leak and we don't
            # serialize a result no one will read).
            logger.info(f"[ANALYZE-STREAM] Client disconnected for user {body.user_id}")
            if analysis_task is not None and not analysis_task.done():
                analysis_task.cancel()
            raise
        except Exception as e:
            logger.error(f"[ANALYZE-STREAM] Food analysis error: {e}", exc_info=True)
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

            # L3 — standing food-logging rules for the image-log path.
            _log_rules = await asyncio.to_thread(fetch_food_logging_rules, get_supabase_db(), user_id)
            _log_rules_block = build_rules_prompt_block(
                _log_rules, has_per_log_instruction=False,
            )

            # Run Gemini analysis and S3 upload concurrently with keep-alive pings
            analysis_task = asyncio.create_task(asyncio.gather(
                gemini_service.analyze_food_image(
                    image_base64=image_base64,
                    mime_type=content_type,
                    user_id=user_id,
                    standing_rules_block=_log_rules_block,
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

            # Apply per-user food overrides: replace AI estimates with the
            # user's past corrections for the same food (matched by food_item_id
            # or normalized name). Runs AFTER the calorie bias so explicit
            # user edits trump the global heuristic.
            from services.food_override_service import apply_user_food_overrides
            db = get_supabase_db()
            food_items, _override_totals, _n_overridden = await asyncio.to_thread(
                apply_user_food_overrides,
                db, user_id, food_items,
            )
            if _n_overridden:
                logger.info(f"[STREAM image] Applied {_n_overridden} override(s) for {user_id}")
                total_calories = _override_totals["total_calories"]
                protein_g = _override_totals["protein_g"]
                carbs_g = _override_totals["carbs_g"]
                fat_g = _override_totals["fat_g"]

            # L4 — global verified cross-check. The text path gets a 'verified'
            # badge for free via `cache_source`; the image path has no cache
            # hit, so each AI-estimated item is cross-checked here against the
            # 198k-row food_nutrition_overrides table by exact normalized name.
            # On a confident match → verified macros + verified_source.
            from services.food_override_service import apply_global_verified_crosscheck
            food_items, _verified_totals, _n_verified = await asyncio.to_thread(
                apply_global_verified_crosscheck,
                food_items,
            )
            if _n_verified:
                logger.info(f"[STREAM image] Verified {_n_verified} item(s) vs global DB for {user_id}")
                total_calories = _verified_totals["total_calories"]
                protein_g = _verified_totals["protein_g"]
                carbs_g = _verified_totals["carbs_g"]
                fat_g = _verified_totals["fat_g"]

            # Extract micronutrients from analysis
            micronutrients = {}
            micronutrient_keys = [
                'sodium_mg', 'sugar_g', 'saturated_fat_g', 'cholesterol_mg', 'potassium_mg',
                'vitamin_a_ug', 'vitamin_a_iu', 'vitamin_c_mg', 'vitamin_d_iu', 'vitamin_e_mg',
                'vitamin_k_ug', 'vitamin_b1_mg', 'vitamin_b2_mg', 'vitamin_b3_mg', 'vitamin_b5_mg',
                'vitamin_b6_mg', 'vitamin_b7_ug', 'vitamin_b9_ug', 'vitamin_b12_ug',
                'calcium_mg', 'iron_mg', 'magnesium_mg', 'zinc_mg', 'phosphorus_mg',
                'copper_mg', 'manganese_mg', 'selenium_ug', 'choline_mg', 'omega3_g', 'omega6_g',
                # Gap 7 — opt-in tracker inputs.
                'caffeine_mg', 'alcohol_g', 'added_sugar_g',
            ]
            for key in micronutrient_keys:
                value = food_analysis.get(key)
                if value is not None:
                    # Convert vitamin_a_iu to vitamin_a_ug (1 IU = 0.3 ug retinol)
                    if key == 'vitamin_a_iu':
                        micronutrients['vitamin_a_ug'] = float(value) * 0.3
                    else:
                        micronutrients[key] = float(value) if value else None

            # Extract inflammation fields from analysis
            inflammation_score = food_analysis.get('inflammation_score')
            is_ultra_processed = food_analysis.get('is_ultra_processed')
            # New in migration 1978 — structured drivers + added sugar.
            inflammation_triggers = food_analysis.get('inflammation_triggers')
            added_sugar_g = food_analysis.get('added_sugar_g')
            glycemic_load = food_analysis.get('glycemic_load')
            fodmap_rating = food_analysis.get('fodmap_rating')
            fodmap_reason = food_analysis.get('fodmap_reason')

            # Enrich image analysis with contextual coach tips
            ai_suggestion = food_analysis.get('feedback')
            encouragements = []
            warnings = []
            recommended_swap = None
            health_score = None
            health_score_reasons = food_analysis.get('health_score_reasons')
            try:
                cache_service = get_food_analysis_cache_service()
                # Pass the user's timezone so the daily budget (and the L1
                # "remaining" math behind the next-meal suggestion) is scoped
                # to the user's local day, not UTC.
                tip_tz = resolve_timezone(request, get_supabase_db(), user_id)
                tips = await cache_service.enrich_with_tips(
                    food_items=food_items,
                    meal_type=meal_type,
                    user_id=user_id,
                    timezone_str=tip_tz or "",
                )
                if tips:
                    encouragements = tips.get("encouragements", [])
                    warnings = tips.get("warnings", [])
                    ai_suggestion = tips.get("ai_suggestion") or ai_suggestion
                    recommended_swap = tips.get("recommended_swap")
                    health_score = tips.get("health_score")
                    health_score_reasons = tips.get("health_score_reasons") or health_score_reasons
            except Exception as tip_err:
                logger.warning(f"[STREAM] Tip enrichment failed for image log: {tip_err}", exc_info=True)

            # Compose ai_feedback from coach tip fields
            ai_feedback_parts = []
            if encouragements:
                ai_feedback_parts.extend(encouragements)
            if warnings:
                ai_feedback_parts.append("\u26a0\ufe0f " + "; ".join(warnings))
            if ai_suggestion:
                ai_feedback_parts.append("\U0001f4a1 " + ai_suggestion)
            if recommended_swap:
                ai_feedback_parts.append("\U0001f504 " + recommended_swap)
            ai_feedback = " | ".join(ai_feedback_parts) if ai_feedback_parts else ai_suggestion

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
                ai_feedback=ai_feedback,
                health_score=health_score,
                health_score_reasons=health_score_reasons,
                logged_at=stream_logged_at,
                image_url=image_url,
                image_storage_key=storage_key,
                source_type="image",
                input_type="image",
                inflammation_score=inflammation_score,
                is_ultra_processed=is_ultra_processed,
                inflammation_triggers=inflammation_triggers,
                added_sugar_g=added_sugar_g,
                glycemic_load=glycemic_load,
                fodmap_rating=fodmap_rating,
                fodmap_reason=fodmap_reason,
                **micronutrients,
            )

            food_log_id = created_log.get('id') if created_log else "unknown"
            logger.info(f"[STREAM] Successfully logged food from image as {food_log_id}")

            # Invalidate daily summary cache so the next fetch returns fresh data
            from api.v1.nutrition.summaries import invalidate_daily_summary_cache
            from api.v1.home.bootstrap_cache import invalidate_bootstrap_cache
            await invalidate_daily_summary_cache(user_id)
            await invalidate_bootstrap_cache(user_id)

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
                "health_score_reasons": health_score_reasons,
                "total_time_ms": elapsed_ms(),
                # L3 — "Zealova remembered your <food>" affirmation.
                "remembered_message": _build_remembered_message(food_items),
            }
            yield f"event: done\ndata: {json.dumps(response_data)}\n\n"

        except Exception as e:
            logger.error(f"[STREAM] Image food logging error: {e}", exc_info=True)
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
    image_original: Optional[UploadFile] = File(default=None),  # P2.0 — full-res for S3 archive
    current_user: dict = Depends(get_current_user),
):
    """
    Analyze food from an image with streaming progress updates via SSE.

    Phase-2 two-artifact upload (per plan §2.0):
    - `image`: REQUIRED. 768px-resized JPEG used for Gemini Vision (1 tile,
       fast). Frontend resizes via flutter_image_compress before upload.
    - `image_original`: OPTIONAL. Full-resolution original used for S3 archive
       so the user sees a crisp image in the nutrition tab. When omitted
       (legacy clients pre-Phase-2), `image` is used for both purposes.
    """
    # SECURITY: Validate file type and size before processing
    ALLOWED_IMAGE_TYPES = {'image/jpeg', 'image/png', 'image/webp', 'image/heic'}
    MAX_IMAGE_SIZE = 10 * 1024 * 1024  # 10MB
    MAX_ORIGINAL_SIZE = 25 * 1024 * 1024  # 25MB allowance for full-res originals

    if image.content_type and image.content_type not in ALLOWED_IMAGE_TYPES:
        raise HTTPException(status_code=400, detail=f"Invalid image type. Allowed: {', '.join(ALLOWED_IMAGE_TYPES)}")

    verify_user_ownership(current_user, user_id)

    import uuid
    request_id = f"req_{uuid.uuid4().hex[:12]}"

    # Read thumb (used for Vision)
    image_bytes = await image.read()
    if len(image_bytes) > MAX_IMAGE_SIZE:
        raise HTTPException(status_code=400, detail="Image too large (max 10MB)")
    content_type = image.content_type or 'image/jpeg'
    image_size_kb = len(image_bytes) // 1024

    # Read original if provided (used for S3 archive). Falls back to the thumb
    # bytes for legacy clients that don't send image_original yet.
    archive_bytes = image_bytes
    archive_content_type = content_type
    if image_original is not None:
        if image_original.content_type and image_original.content_type not in ALLOWED_IMAGE_TYPES:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid image_original type. Allowed: {', '.join(ALLOWED_IMAGE_TYPES)}",
            )
        archive_bytes = await image_original.read()
        if len(archive_bytes) > MAX_ORIGINAL_SIZE:
            raise HTTPException(status_code=400, detail="Original image too large (max 25MB)")
        archive_content_type = image_original.content_type or 'image/jpeg'

    logger.info(
        f"[ANALYZE-STREAM:{request_id}] START | "
        f"user={user_id} | "
        f"meal_type={meal_type} | "
        f"thumb_kb={image_size_kb} | "
        f"original_kb={len(archive_bytes) // 1024} | "
        f"two_artifact={image_original is not None}"
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

        # Error codes that represent user-recoverable input problems, not system failures.
        # These should be logged at WARNING so they don't trip error alerts.
        USER_RECOVERABLE_ERROR_CODES = {"NO_FOOD_DETECTED", "INVALID_IMAGE", "IMAGE_TOO_LARGE"}

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
            log_fn = logger.warning if error_code in USER_RECOVERABLE_ERROR_CODES else logger.error
            status_label = "USER_INPUT_REJECTED" if error_code in USER_RECOVERABLE_ERROR_CODES else "FAILED"
            log_fn(
                f"[ANALYZE-STREAM:{request_id}] {status_label} | "
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
                """Upload the ORIGINAL (full-res) to S3 with graceful failure
                — don't block analysis. food_log.image_url ends up pointing
                to the high-quality archive."""
                try:
                    return await upload_food_image_to_s3(
                        file_bytes=archive_bytes,
                        user_id=user_id,
                        content_type=archive_content_type,
                    )
                except Exception as s3_err:
                    logger.warning(f"[ANALYZE-STREAM:{request_id}] S3 upload failed (non-blocking): {s3_err}", exc_info=True)
                    return (None, None)

            # Phase 2 pipeline: Stage-1 thin Vision → cache_service.analyze_dishes_from_vision
            # Kill-switch via env: set PHASE2_VISION_PIPELINE=0 to revert to legacy heavyweight path.
            import os as _os
            use_phase2 = _os.environ.get("PHASE2_VISION_PIPELINE", "1") != "0"

            if use_phase2:
                from services.vision_service import get_vision_service
                from services.food_analysis.cache_service import get_food_analysis_cache_service
                vision = get_vision_service()
                cache_svc = get_food_analysis_cache_service()

                async def phase2_analyze() -> dict:
                    """Stage-1 (Vision thin classifier) + Stage-1.5 (cache-stack lookup)."""
                    identification = await vision.identify_dishes_from_image(
                        image_bytes=image_bytes,
                        mime_type=content_type,
                        mode='plate',
                        request_id=request_id,
                    )
                    logger.info(
                        f"[ANALYZE-STREAM:{request_id}] Stage-1 done: "
                        f"{len(identification.dishes)} dishes, "
                        f"cuisine={identification.cuisine_tag}, "
                        f"layout={identification.plate_layout}"
                    )
                    # L3 — standing food-logging rules for the phase-2 image
                    # path. Threaded through user_context into the Stage-2
                    # Gemini macro estimation so prep rules (low-oil, skim
                    # milk, 0-cal sweetener) adjust the estimate.
                    _img_rules = await asyncio.to_thread(fetch_food_logging_rules, get_supabase_db(), user_id)
                    _img_rules_block = build_rules_prompt_block(
                        _img_rules, has_per_log_instruction=False,
                    )
                    return await cache_svc.analyze_dishes_from_vision(
                        dishes=identification.dishes,
                        user_context={
                            "user_id": user_id,
                            "meal_type": meal_type,
                            "cuisine_tag": identification.cuisine_tag,
                            "standing_rules_block": _img_rules_block,
                        },
                    )

                analysis_future = asyncio.ensure_future(asyncio.gather(
                    phase2_analyze(),
                    safe_s3_upload(),
                ))
            else:
                # Legacy heavyweight path — preserved for rollback safety.
                # L3 — standing food-logging rules on the legacy image path.
                _legacy_rules = await asyncio.to_thread(fetch_food_logging_rules, get_supabase_db(), user_id)
                _legacy_rules_block = build_rules_prompt_block(
                    _legacy_rules, has_per_log_instruction=False,
                )
                analysis_future = asyncio.ensure_future(asyncio.gather(
                    gemini_service.analyze_food_image(
                        image_base64=image_base64,
                        mime_type=content_type,
                        request_id=request_id,
                        user_id=user_id,
                        standing_rules_block=_legacy_rules_block,
                    ),
                    safe_s3_upload(),
                ))

            while not analysis_future.done():
                try:
                    await asyncio.wait_for(asyncio.shield(analysis_future), timeout=10.0)
                except asyncio.TimeoutError:
                    yield ": keep-alive\n\n"
            food_analysis, (image_url, image_storage_key) = analysis_future.result()
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

            # Apply per-user overrides BEFORE returning the analysis to the
            # client — the log-meal-sheet preview should show the user's
            # corrected numbers, not fresh Gemini estimates, for foods they
            # edited in the past. No double-apply risk because /log-direct's
            # skip_indices only protects just-edited-in-sheet items.
            from services.food_override_service import apply_user_food_overrides
            _ov_db = get_supabase_db()
            food_items, _override_totals, _n_overridden = await asyncio.to_thread(
                apply_user_food_overrides,
                _ov_db, user_id, food_items,
            )
            if _n_overridden:
                logger.info(f"[ANALYZE-STREAM:{request_id}] Applied {_n_overridden} user override(s)")
                total_calories = _override_totals["total_calories"]
                protein_g = _override_totals["protein_g"]
                carbs_g = _override_totals["carbs_g"]
                fat_g = _override_totals["fat_g"]

            # L4 — global verified cross-check. Match each AI-estimated image
            # item against the 198k-row food_nutrition_overrides table by exact
            # normalized name (same lookup the text/cache path uses). On a
            # confident match → verified macros + verified_source='global_db',
            # which flows out through the `done` event's `food_items` so the
            # frontend's verified badge picks it up.
            from services.food_override_service import apply_global_verified_crosscheck
            food_items, _verified_totals, _n_verified = await asyncio.to_thread(
                apply_global_verified_crosscheck,
                food_items,
            )
            if _n_verified:
                logger.info(f"[ANALYZE-STREAM:{request_id}] Verified {_n_verified} item(s) vs global DB")
                total_calories = _verified_totals["total_calories"]
                protein_g = _verified_totals["protein_g"]
                carbs_g = _verified_totals["carbs_g"]
                fat_g = _verified_totals["fat_g"]

            # Micronutrients
            sodium_mg = food_analysis.get('sodium_mg')
            sugar_g = food_analysis.get('sugar_g')
            # Gap 7 — opt-in tracker inputs forwarded to the confirm payload.
            added_sugar_g = food_analysis.get('added_sugar_g')
            caffeine_mg = food_analysis.get('caffeine_mg')
            alcohol_g = food_analysis.get('alcohol_g')
            saturated_fat_g = food_analysis.get('saturated_fat_g')
            cholesterol_mg = food_analysis.get('cholesterol_mg')
            potassium_mg = food_analysis.get('potassium_mg')
            vitamin_a_iu = food_analysis.get('vitamin_a_iu')
            vitamin_c_mg = food_analysis.get('vitamin_c_mg')
            vitamin_d_iu = food_analysis.get('vitamin_d_iu')
            calcium_mg = food_analysis.get('calcium_mg')
            iron_mg = food_analysis.get('iron_mg')

            plate_description = food_analysis.get('plate_description')

            # Extract inflammation fields from analysis
            analyze_inflammation_score = food_analysis.get('inflammation_score')
            analyze_is_ultra_processed = food_analysis.get('is_ultra_processed')

            # Coaching tips are generated AFTER the `done` event (see below) —
            # the 5-8s Gemini call must NOT block the food card from rendering.
            # The `done` event ships macros + a locally-computed health_score
            # immediately; tips arrive via a follow-up `coach_tips` event.
            ai_suggestion = None
            encouragements = []
            warnings = []
            recommended_swap = None
            # health_score: use the value analyze_dishes_from_vision already
            # computed locally (_compute_health_score — no Gemini).
            health_score = food_analysis.get('health_score')
            health_score_reasons = food_analysis.get('health_score_reasons')

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
                "health_score_reasons": health_score_reasons,
                "source_type": "image",
                "total_time_ms": elapsed_ms(),
                # Micronutrients
                "sodium_mg": sodium_mg,
                "sugar_g": sugar_g,
                "added_sugar_g": added_sugar_g,
                "caffeine_mg": caffeine_mg,
                "alcohol_g": alcohol_g,
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
                # Inflammation / ultra-processed tracking
                "inflammation_score": analyze_inflammation_score,
                "is_ultra_processed": analyze_is_ultra_processed,
                # L3 — "Zealova remembered your <food>" affirmation.
                "remembered_message": _build_remembered_message(food_items),
            }
            yield f"event: done\ndata: {json.dumps(response_data)}\n\n"

            # ── Coaching tips — streamed AFTER `done` ──────────────────────
            # The card already rendered. Now generate the 5-8s coach tips and
            # ship them as a `coach_tips` event. A client that doesn't handle
            # the event just shows no tips — fully graceful.
            try:
                cache_service = get_food_analysis_cache_service()
                # Pass the user's timezone so the daily budget (and the L1
                # "remaining" math behind the next-meal suggestion) is scoped
                # to the user's local day, not UTC.
                tip_tz = resolve_timezone(request, get_supabase_db(), user_id)
                tips = await cache_service.enrich_with_tips(
                    food_items=food_items,
                    meal_type=meal_type,
                    user_id=user_id,
                    timezone_str=tip_tz or "",
                )
                if tips:
                    coach_tips_data = {
                        "request_id": request_id,
                        "ai_suggestion": tips.get("ai_suggestion"),
                        "encouragements": tips.get("encouragements", []),
                        "warnings": tips.get("warnings", []),
                        "recommended_swap": tips.get("recommended_swap"),
                        "health_score": tips.get("health_score") or health_score,
                        "health_score_reasons": tips.get("health_score_reasons") or health_score_reasons,
                        # Refine the score badge with the LLM's goal-aware score.
                        "overall_meal_score": tips.get("health_score") or health_score,
                        # L1 — coaching extras (see analyze-text-stream above).
                        "next_meal_suggestion": tips.get("next_meal_suggestion"),
                        "over_budget_fork": tips.get("over_budget_fork"),
                        # Smart sauce/side suggestions (tappable chips on client).
                        "suggested_addons": tips.get("suggested_addons", []),
                        # Inflammation — fill from the deferred review when the
                        # fast image path omitted it, so the client can show the
                        # "Inflammation N/10" pill beside Health.
                        "inflammation_score": tips.get("inflammation_score")
                        if tips.get("inflammation_score") is not None
                        else analyze_inflammation_score,
                        "inflammation_triggers": tips.get("inflammation_triggers", []),
                    }
                    yield f"event: coach_tips\ndata: {json.dumps(coach_tips_data)}\n\n"
            except Exception as tip_err:
                logger.warning(
                    f"[ANALYZE-STREAM:{request_id}] coach_tips enrichment failed: {tip_err}"
                )

        except Exception as e:
            logger.exception(f"[ANALYZE-STREAM:{request_id}] EXCEPTION | user={user_id} | error={e}")
            # Translate known Stage-1 "no food in image" outcomes into the
            # user-recoverable NO_FOOD_DETECTED code so the frontend can show
            # "Try another photo" instead of a generic crash banner. The
            # Phase-2 Stage-1 path raises RuntimeError with NO_FOOD_DETECTED
            # in the message; older paths raised it via the explicit
            # send_error(..., "NO_FOOD_DETECTED", ...) at line 865.
            err_msg = str(e)
            # NO_FOOD_DETECTED — Stage-1 succeeded but identified no dishes
            # (intentional fail-fast on cat photos / blurry shots / etc).
            # Stage-1 parse failures fall here too — Gemini Vision returned
            # truncated/malformed JSON. Either way the user-correct UX is
            # "couldn't read this photo, try another" not "internal error".
            if (
                "NO_FOOD_DETECTED" in err_msg
                or "Stage-1 JSON parse failure" in err_msg
                or "Stage-1 returned no valid dishes" in err_msg
                or "Empty Stage-1 response" in err_msg
            ):
                yield send_error(
                    "Couldn't read this photo. Try a clearer shot with the plate in frame.",
                    "NO_FOOD_DETECTED",
                    f"{type(e).__name__}: {err_msg}",
                )
            else:
                yield send_error(
                    "An unexpected error occurred. Please try again.",
                    "UNEXPECTED_EXCEPTION",
                    f"{type(e).__name__}: {err_msg}",
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



_ALLOWED_SECTIONS = {
    "breakfast", "appetizers", "mains", "sides",
    "desserts", "drinks", "specials", "uncategorized",
}

_SECTION_ALIASES = {
    # Map common restaurant wording to the canonical enum so the client
    # can render stable section groups without guessing.
    "starter": "appetizers", "starters": "appetizers",
    "small plates": "appetizers", "appetizer": "appetizers",
    "entree": "mains", "entrees": "mains", "entrée": "mains",
    "entrées": "mains", "main course": "mains", "main courses": "mains",
    "mains": "mains", "main": "mains",
    "side": "sides", "side dishes": "sides", "accompaniments": "sides",
    "dessert": "desserts", "sweets": "desserts",
    "beverage": "drinks", "beverages": "drinks", "drinks": "drinks",
    "cocktails": "drinks", "wine": "drinks",
    "brunch": "breakfast", "breakfast": "breakfast",
    "special": "specials", "chef's specials": "specials", "specials": "specials",
}


def _normalize_section(raw: Any) -> str:
    """Map any Gemini section label onto the canonical enum the sheet
    groups by. Unknown labels fall through to 'uncategorized' rather
    than leaking raw free-form text."""
    if not raw:
        return "uncategorized"
    key = str(raw).strip().lower()
    if key in _ALLOWED_SECTIONS:
        return key
    if key in _SECTION_ALIASES:
        return _SECTION_ALIASES[key]
    # Check substring hits so "Grill & Mains" → "mains".
    for alias, canonical in _SECTION_ALIASES.items():
        if alias in key:
            return canonical
    return "uncategorized"


def _flatten_menu_items(analysis_result: dict, actual_mode: str) -> List[dict]:
    """Normalize the Gemini menu/buffet response into a flat list of dish
    dicts ready to ship to the MenuAnalysisSheet. Includes per-dish
    inflammation_score, coach_tip, weight_g, detected_allergens, and
    price/currency so the sheet can surface them inline."""
    flat_items: List[dict] = []
    if actual_mode == "menu":
        for section in analysis_result.get("sections", []) or []:
            section_name = _normalize_section(section.get("section_name"))
            for dish in section.get("dishes", []) or []:
                flat_items.append({
                    "name": dish.get("name", "Unknown"),
                    "section": section_name,
                    "calories": dish.get("calories", 0),
                    "protein_g": dish.get("protein_g", 0),
                    "carbs_g": dish.get("carbs_g", 0),
                    "fat_g": dish.get("fat_g", 0),
                    "weight_g": dish.get("weight_g"),
                    "rating": dish.get("rating"),
                    "rating_reason": dish.get("rating_reason"),
                    "amount": dish.get("serving_description"),
                    "price": dish.get("price"),
                    "currency": dish.get("currency"),
                    "detected_allergens": dish.get("detected_allergens") or [],
                    "inflammation_score": dish.get("inflammation_score"),
                    "coach_tip": dish.get("coach_tip"),
                })
    else:
        for dish in analysis_result.get("dishes", []) or []:
            flat_items.append({
                "name": dish.get("name", "Unknown"),
                "calories": dish.get("calories", 0),
                "protein_g": dish.get("protein_g", 0),
                "carbs_g": dish.get("carbs_g", 0),
                "fat_g": dish.get("fat_g", 0),
                "weight_g": dish.get("weight_g"),
                "rating": dish.get("rating"),
                "rating_reason": dish.get("rating_reason"),
                "amount": dish.get("serving_description"),
                "detected_allergens": dish.get("detected_allergens") or [],
                "inflammation_score": dish.get("inflammation_score"),
                "coach_tip": dish.get("coach_tip"),
            })
    return flat_items


# ─────────────────────────────────────────────────────────────────────────────
# Multi-image log: accepts 1..N photos and an analysis_mode ("auto", "plate",
# "menu", or "buffet"). Plate mode auto-logs a single food_log row and returns
# the standard LogFoodResponse shape. Menu and Buffet modes DO NOT auto-log —
# they return structured dish/section data so the client can render the
# MenuAnalysisSheet checklist and the user ticks off only the items they eat.
# Those selected items are then persisted via /log-selected-items.
#
# Menu + Buffet modes use PER-IMAGE streaming (one Gemini call per page) so
# the client can render page 1 results before later pages finish. Each page
# gets its own full token budget, which dramatically improves dish recall on
# large multi-page menus. SSE events emitted: progress | page | page_error |
# done | error.
# ─────────────────────────────────────────────────────────────────────────────

@router.post("/log-multi-image-stream")
@limiter.limit("6/minute")
async def log_food_from_multi_image_streaming(
    request: Request,
    user_id: str = Form(...),
    meal_type: str = Form(...),
    analysis_mode: str = Form("auto"),
    user_message: Optional[str] = Form(None),
    input_type: Optional[str] = Form(None),
    # When true, plate mode RETURNS the analysis without writing to food_logs.
    # The client is expected to render a review screen and POST to /food-logs
    # (via logFoodDirect) only after the user confirms. Camera single-shot /
    # text / voice paths already work this way; this flag lets multi-image
    # gallery + camera follow the same human-consent flow instead of the
    # legacy "auto-logged, then surprise snackbar" behavior users complained
    # about. Default False preserves backwards compatibility for any caller
    # that hasn't updated yet.
    confirm_before_log: bool = Form(False),
    images: List[UploadFile] = File(...),
    current_user: dict = Depends(get_current_user),
):
    """Log or analyze 1..N food images. Plate auto-logs; Menu/Buffet return structured data."""
    ALLOWED_IMAGE_TYPES = {'image/jpeg', 'image/png', 'image/webp', 'image/heic'}
    MAX_IMAGE_SIZE = 10 * 1024 * 1024
    MAX_IMAGES = 10

    if analysis_mode not in {"auto", "plate", "menu", "buffet"}:
        raise HTTPException(status_code=400, detail="Invalid analysis_mode")
    if not images:
        raise HTTPException(status_code=400, detail="At least one image required")
    if len(images) > MAX_IMAGES:
        raise HTTPException(status_code=400, detail=f"Too many images (max {MAX_IMAGES})")

    verify_user_ownership(current_user, user_id)

    image_payloads: List[Tuple[bytes, str]] = []
    for img in images:
        if img.content_type and img.content_type not in ALLOWED_IMAGE_TYPES:
            raise HTTPException(status_code=400, detail=f"Invalid image type: {img.content_type}")
        data = await img.read()
        if len(data) > MAX_IMAGE_SIZE:
            raise HTTPException(status_code=400, detail=f"Image too large (max {MAX_IMAGE_SIZE // (1024*1024)}MB)")
        image_payloads.append((data, img.content_type or 'image/jpeg'))

    normalized_input_type = (input_type or '').strip().lower() or 'image'

    async def generate_sse() -> AsyncGenerator[str, None]:
        start_time = time.time()

        def elapsed_ms() -> int:
            return int((time.time() - start_time) * 1000)

        def send_progress(step: int, total: int, message: str, detail: str = None):
            data = {"type": "progress", "step": step, "total_steps": total,
                    "message": message, "detail": detail, "elapsed_ms": elapsed_ms()}
            return f"event: progress\ndata: {json.dumps(data)}\n\n"

        def send_error(error: str):
            return f"event: error\ndata: {json.dumps({'type': 'error', 'error': error, 'elapsed_ms': elapsed_ms()})}\n\n"

        try:
            n = len(image_payloads)
            yield send_progress(1, 4, f"Uploading {n} photo{'s' if n != 1 else ''}...", None)

            upload_tasks = [
                upload_food_image_to_s3(
                    file_bytes=data, user_id=user_id, content_type=mime,
                    source="gallery" if normalized_input_type == "gallery" else "camera",
                    meal_type=meal_type,
                )
                for data, mime in image_payloads
            ]
            upload_results = await asyncio.gather(*upload_tasks)
            image_urls = [r[0] for r in upload_results]
            storage_keys = [r[1] for r in upload_results]
            mime_types = [mime for _, mime in image_payloads]

            yield send_progress(2, 4, "Analyzing...", f"{n} image{'s' if n != 1 else ''}")

            from services.vision_service import get_vision_service
            vision = get_vision_service()

            db = get_supabase_db()

            # L3 — standing food-logging rules for the multi-image path.
            # Applied to plate + buffet analyses (the user's own food); the
            # rules service decides whether the rule block is non-empty.
            _multi_rules = await asyncio.to_thread(fetch_food_logging_rules, db, user_id)
            _multi_rules_block = build_rules_prompt_block(
                _multi_rules, has_per_log_instruction=bool((user_message or "").strip()),
            )

            user_tz = resolve_timezone(request, db, user_id)
            user = db.get_user(user_id)
            if user:
                user = db.enrich_user_with_nutrition_targets(user)
            nutrition_context = None
            if user:
                targets = {k: user.get(k) for k in [
                    "daily_calorie_target", "daily_protein_target_g",
                    "daily_carbs_target_g", "daily_fat_target_g",
                ] if user.get(k) is not None}
                if targets:
                    nutrition_context = {"targets": targets}
                    today = get_user_today(user_tz)
                    daily_summary = db.get_daily_nutrition_summary(user_id, today)
                    if daily_summary and daily_summary.get("total_calories"):
                        nutrition_context["consumed_today"] = {
                            "calories_consumed": daily_summary.get("total_calories", 0),
                            "protein_consumed_g": daily_summary.get("total_protein_g", 0),
                            "carbs_consumed_g": daily_summary.get("total_carbs_g", 0),
                            "fat_consumed_g": daily_summary.get("total_fat_g", 0),
                        }

            # Menu + buffet modes use per-image streaming for dramatically
            # better perceived performance on multi-page scans: the first
            # page's dishes reach the client in ~5-8s instead of waiting
            # ~15-30s for all pages to finish as one batch. It also gives
            # each page its own full token budget, boosting dish recall on
            # large menus.
            if analysis_mode in ("menu", "buffet"):
                actual_mode = analysis_mode
                logger.info(
                    f"[STREAM multi] per-image streaming mode={actual_mode} "
                    f"user={user_id} images={n}"
                )
                yield send_progress(3, 4, "Scanning pages...", f"{n} image{'s' if n != 1 else ''}")

                all_items: List[dict] = []
                successful_pages = 0
                # First non-null restaurant name seen across all menu pages.
                # Stays None if no page surfaced a name (emitted as null below).
                restaurant_name: Optional[str] = None
                for idx, (s3_key, mime) in enumerate(zip(storage_keys, mime_types)):
                    page_num = idx + 1
                    try:
                        per_image_result = await asyncio.wait_for(
                            vision.analyze_food_from_s3_keys(
                                s3_keys=[s3_key], mime_types=[mime],
                                user_context=user_message, analysis_mode=actual_mode,
                                nutrition_context=nutrition_context,
                                standing_rules_block=_multi_rules_block,
                            ),
                            timeout=60,
                        )
                        page_items = _flatten_menu_items(per_image_result, actual_mode)
                        all_items.extend(page_items)
                        successful_pages += 1
                        # Capture the restaurant name from the first page that
                        # surfaces one; later pages don't override it.
                        if restaurant_name is None:
                            page_rn = per_image_result.get("restaurant_name")
                            if isinstance(page_rn, str) and page_rn.strip():
                                restaurant_name = page_rn.strip()
                        page_event = {
                            "type": "page",
                            "analysis_type": actual_mode,
                            "page": page_num,
                            "total_pages": n,
                            "items": page_items,
                            "image_url": image_urls[idx],
                            "storage_key": storage_keys[idx],
                            "elapsed_ms": elapsed_ms(),
                        }
                        yield f"event: page\ndata: {json.dumps(page_event)}\n\n"
                    except asyncio.TimeoutError:
                        logger.warning(f"[STREAM multi] page {page_num} timed out")
                        err_event = {"type": "page_error", "page": page_num,
                                     "total_pages": n, "error": "timeout"}
                        yield f"event: page_error\ndata: {json.dumps(err_event)}\n\n"
                    except Exception as e:
                        logger.error(f"[STREAM multi] page {page_num} failed: {e}", exc_info=True)
                        err_event = {"type": "page_error", "page": page_num,
                                     "total_pages": n, "error": str(e)}
                        yield f"event: page_error\ndata: {json.dumps(err_event)}\n\n"

                done_event = {
                    "success": successful_pages > 0,
                    "analysis_type": actual_mode,
                    "food_items": all_items,
                    # First non-null restaurant name across pages, else null.
                    "restaurant_name": restaurant_name,
                    "successful_pages": successful_pages,
                    "total_pages": n,
                    "image_urls": image_urls,
                    "menu_photo_urls": image_urls,  # alias for client readability
                    "storage_keys": storage_keys,
                    "mime_types": mime_types,
                    "total_time_ms": elapsed_ms(),
                    "elapsed_seconds": round(elapsed_ms() / 1000.0, 2),
                }
                yield f"event: done\ndata: {json.dumps(done_event)}\n\n"
                return

            # Auto + plate: one-shot batch analysis (unchanged).
            analysis_result = await asyncio.wait_for(
                vision.analyze_food_from_s3_keys(
                    s3_keys=storage_keys, mime_types=mime_types,
                    user_context=user_message, analysis_mode=analysis_mode,
                    nutrition_context=nutrition_context,
                    standing_rules_block=_multi_rules_block,
                ),
                timeout=90,
            )

            if not analysis_result:
                yield send_error("Could not analyze the images. Please try a clearer photo.")
                return

            actual_mode = analysis_result.get("analysis_type", analysis_mode)
            logger.info(f"[STREAM multi] mode={actual_mode} user={user_id} images={n}")

            if actual_mode == "plate":
                yield send_progress(3, 4, "Calculating nutrition...", None)
                bias = await get_user_calorie_bias(user_id)
                if bias != 0:
                    analysis_result = apply_calorie_bias(analysis_result, bias)

                food_items = analysis_result.get("food_items", [])
                total_calories = analysis_result.get("total_calories", 0)
                protein_g = analysis_result.get("protein_g") or analysis_result.get("total_protein_g", 0.0)
                carbs_g = analysis_result.get("carbs_g") or analysis_result.get("total_carbs_g", 0.0)
                fat_g = analysis_result.get("fat_g") or analysis_result.get("total_fat_g", 0.0)
                fiber_g = analysis_result.get("fiber_g", 0.0) or analysis_result.get("total_fiber_g", 0.0)

                # Gemini occasionally leaves the meal-level macros at 0 even when
                # every food_item has populated protein/carbs/fat. The hero card
                # in the review sheet then reads "0g Protein / 0g Carbs / 0g Fat"
                # while the items below clearly have macros. Fall back to summing
                # the items so the user sees consistent numbers everywhere.
                def _sum_item_field(key: str) -> float:
                    s = 0.0
                    for it in food_items or []:
                        v = it.get(key) if isinstance(it, dict) else None
                        if isinstance(v, (int, float)):
                            s += v
                    return s
                if not total_calories:
                    total_calories = int(round(_sum_item_field("calories")))
                if not protein_g:
                    protein_g = round(_sum_item_field("protein_g"), 1)
                if not carbs_g:
                    carbs_g = round(_sum_item_field("carbs_g"), 1)
                if not fat_g:
                    fat_g = round(_sum_item_field("fat_g"), 1)
                if not fiber_g:
                    fiber_g = round(_sum_item_field("fiber_g"), 1)
                health_score = analysis_result.get("health_score")
                health_score_reasons = analysis_result.get("health_score_reasons")
                ai_feedback = analysis_result.get("feedback")
                inflammation_score = analysis_result.get("inflammation_score")
                is_ultra_processed = analysis_result.get("is_ultra_processed")
                # Migration 1978: carry structured drivers + added sugar + GL/FODMAP
                # so the review sheet + saved row both have the complete signal set.
                inflammation_triggers = analysis_result.get("inflammation_triggers")
                added_sugar_g = analysis_result.get("added_sugar_g")
                # Gap 7 — opt-in tracker inputs from a photographed meal.
                caffeine_mg = analysis_result.get("caffeine_mg")
                alcohol_g = analysis_result.get("alcohol_g")
                glycemic_load = analysis_result.get("glycemic_load")
                fodmap_rating = analysis_result.get("fodmap_rating")
                fodmap_reason = analysis_result.get("fodmap_reason")
                # A3 — short note of what the user's instruction changed.
                applied_instruction_note = analysis_result.get("applied_instruction_note")

                # Human-consent branch: do NOT persist. Client renders a
                # review sheet and posts to /food-logs (via logFoodDirect)
                # once the user confirms. Sub-items can be removed during
                # review — no more phantom "Sugary Fountain Drink" rows the
                # user didn't agree to.
                if confirm_before_log:
                    yield send_progress(4, 4, "Ready for review...", None)
                    response_data = {
                        "success": True,
                        "analysis_type": "plate",
                        "is_analysis_only": True,
                        "food_items": food_items,
                        "total_calories": total_calories,
                        "protein_g": protein_g,
                        "carbs_g": carbs_g,
                        "fat_g": fat_g,
                        "fiber_g": fiber_g,
                        "ai_suggestion": ai_feedback,
                        "feedback": ai_feedback,
                        "health_score": health_score,
                        "health_score_reasons": health_score_reasons,
                        "inflammation_score": inflammation_score,
                        "is_ultra_processed": is_ultra_processed,
                        "applied_instruction_note": applied_instruction_note,
                        # Gap 7 — opt-in tracker inputs for the confirm write.
                        "added_sugar_g": added_sugar_g,
                        "caffeine_mg": caffeine_mg,
                        "alcohol_g": alcohol_g,
                        "image_urls": image_urls,
                        "storage_keys": storage_keys,
                        "total_time_ms": elapsed_ms(),
                    }
                    yield f"event: done\ndata: {json.dumps(response_data)}\n\n"
                    return

                yield send_progress(4, 4, "Saving your meal...", None)
                stream_logged_at = get_user_now_iso(user_tz)
                created_log = db.create_food_log(
                    user_id=user_id, meal_type=meal_type, food_items=food_items,
                    total_calories=total_calories, protein_g=protein_g, carbs_g=carbs_g,
                    fat_g=fat_g, fiber_g=fiber_g, ai_feedback=ai_feedback,
                    health_score=health_score, logged_at=stream_logged_at,
                    image_url=image_urls[0], image_storage_key=storage_keys[0],
                    source_type="image", input_type=normalized_input_type,
                    inflammation_score=inflammation_score,
                    is_ultra_processed=is_ultra_processed,
                    inflammation_triggers=inflammation_triggers,
                    added_sugar_g=added_sugar_g,
                    # Gap 7 — opt-in tracker inputs.
                    caffeine_mg=caffeine_mg,
                    alcohol_g=alcohol_g,
                    glycemic_load=glycemic_load,
                    fodmap_rating=fodmap_rating,
                    fodmap_reason=fodmap_reason,
                    health_score_reasons=health_score_reasons,
                )

                from api.v1.nutrition.summaries import invalidate_daily_summary_cache
                from api.v1.home.bootstrap_cache import invalidate_bootstrap_cache
                await invalidate_daily_summary_cache(user_id)
                await invalidate_bootstrap_cache(user_id)

                response_data = {
                    "success": True, "analysis_type": "plate",
                    "food_log_id": created_log.get("id") if created_log else None,
                    "food_items": food_items, "total_calories": total_calories,
                    "protein_g": protein_g, "carbs_g": carbs_g, "fat_g": fat_g,
                    "fiber_g": fiber_g, "ai_suggestion": ai_feedback,
                    "health_score": health_score,
                    "health_score_reasons": health_score_reasons,
                    "inflammation_score": inflammation_score,
                    "is_ultra_processed": is_ultra_processed,
                    "image_urls": image_urls,
                    "total_time_ms": elapsed_ms(),
                }
                yield f"event: done\ndata: {json.dumps(response_data)}\n\n"
                return

            # Auto-classified as menu/buffet after a batch call — flatten inline.
            yield send_progress(3, 4, "Formatting results...", None)
            flat_items = _flatten_menu_items(analysis_result, actual_mode)

            response_data = {
                "success": True, "analysis_type": actual_mode,
                "food_items": flat_items,
                "sections": analysis_result.get("sections"),
                "suggested_plate": analysis_result.get("suggested_plate"),
                "recommended_order": analysis_result.get("recommended_order"),
                "tips": analysis_result.get("tips", []),
                "restaurant_name": analysis_result.get("restaurant_name"),
                "image_urls": image_urls,
                "menu_photo_urls": image_urls,
                "storage_keys": storage_keys,
                "mime_types": mime_types,
                "total_time_ms": elapsed_ms(),
                "elapsed_seconds": round(elapsed_ms() / 1000.0, 2),
            }
            yield f"event: done\ndata: {json.dumps(response_data)}\n\n"

        except asyncio.TimeoutError:
            yield send_error("Analysis timed out. Try again with fewer or clearer photos.")
        except Exception as e:
            logger.error(f"[STREAM multi] error: {e}", exc_info=True)
            yield send_error(str(e))

    return StreamingResponse(
        generate_sse(),
        media_type="text/event-stream",
        headers={"Cache-Control": "no-cache", "Connection": "keep-alive", "X-Accel-Buffering": "no"},
    )


# ─────────────────────────────────────────────────────────────────────────────
# Log the ticked items from a menu / buffet checklist as food_log rows.
# One row per item so daily summaries / macro charts aggregate correctly.
# ─────────────────────────────────────────────────────────────────────────────

class SelectedItem(BaseModel):
    name: str
    calories: int = 0
    protein_g: float = 0.0
    carbs_g: float = 0.0
    fat_g: float = 0.0
    fiber_g: Optional[float] = None
    weight_g: Optional[int] = None
    portion_multiplier: float = 1.0
    amount: Optional[str] = None
    # Health-condition scoring forwarded from the MenuAnalysisSheet. Without
    # these, the user loses the Gemini-computed context (inflammation, diabetes
    # impact, FODMAP) the moment they log the meal.
    inflammation_score: Optional[int] = None
    is_ultra_processed: Optional[bool] = None
    glycemic_load: Optional[int] = None
    fodmap_rating: Optional[str] = None
    fodmap_reason: Optional[str] = None
    # Structured inflammation drivers + added sugar (migration 1978).
    inflammation_triggers: Optional[List[str]] = None
    added_sugar_g: Optional[float] = None
    rating: Optional[str] = None
    rating_reason: Optional[str] = None
    coach_tip: Optional[str] = None


class LogSelectedItemsRequest(BaseModel):
    user_id: str
    meal_type: str
    analysis_type: str
    items: List[SelectedItem]
    input_type: Optional[str] = None
    image_url: Optional[str] = None
    image_storage_key: Optional[str] = None


@router.post("/log-selected-items")
@limiter.limit("12/minute")
async def log_selected_items(
    request: Request,
    body: LogSelectedItemsRequest,
    background: BackgroundTasks,
    current_user: dict = Depends(get_current_user),
):
    """Persist ticked items from a menu/buffet checklist. One food_log per item.

    Also flips `liked=true` on the corresponding `menu_items` ChromaDB
    entries (background task, best-effort) so the recommendation
    pipeline can use "foods you've liked at other places" as a
    semantic signal on future menu scans.
    """
    verify_user_ownership(current_user, body.user_id)
    if not body.items:
        raise HTTPException(status_code=400, detail="No items to log")

    source_type = {"menu": "menu", "buffet": "buffet", "plate": "image"}.get(body.analysis_type, "image")
    input_type = (body.input_type or {
        "menu": "menu_scan", "buffet": "buffet_scan", "plate": "multi_image_scan",
    }.get(body.analysis_type, "image")).lower()

    db = get_supabase_db()
    user_tz = resolve_timezone(request, db, body.user_id)
    logged_at = get_user_now_iso(user_tz)

    created_ids: List[str] = []
    try:
        for item in body.items:
            # Note: the client already scales calories/protein/carbs/fat by the
            # portion multiplier before sending — see `_handleLog` in
            # menu_analysis_sheet.dart. We DON'T re-scale here (would double-
            # apply) unless the client explicitly sends a non-1.0 multiplier
            # with UNSCALED macros (legacy path). Gate on that.
            mult = 1.0 if (item.portion_multiplier or 1.0) == 1.0 else float(item.portion_multiplier)
            # Ride fiber / weight / coach_tip + health scores into the
            # stored food_items JSON so food history can show the dish
            # context per item (multiple items per row is possible).
            food_item = {
                "name": item.name,
                "calories": int(round(item.calories * mult)) if mult != 1.0 else item.calories,
                "protein_g": round(item.protein_g * mult, 1) if mult != 1.0 else item.protein_g,
                "carbs_g": round(item.carbs_g * mult, 1) if mult != 1.0 else item.carbs_g,
                "fat_g": round(item.fat_g * mult, 1) if mult != 1.0 else item.fat_g,
                "amount": item.amount or "1 serving",
            }
            if item.fiber_g is not None:
                food_item["fiber_g"] = round(item.fiber_g * mult, 1) if mult != 1.0 else item.fiber_g
            if item.weight_g is not None:
                food_item["weight_g"] = int(round(item.weight_g * mult)) if mult != 1.0 else item.weight_g
            if item.coach_tip:
                food_item["coach_tip"] = item.coach_tip
            if item.rating:
                food_item["rating"] = item.rating
            if item.rating_reason:
                food_item["rating_reason"] = item.rating_reason

            food_items = [food_item]
            row = db.create_food_log(
                user_id=body.user_id, meal_type=body.meal_type, food_items=food_items,
                total_calories=food_items[0]["calories"],
                protein_g=food_items[0]["protein_g"],
                carbs_g=food_items[0]["carbs_g"],
                fat_g=food_items[0]["fat_g"],
                fiber_g=food_items[0].get("fiber_g") or 0,
                ai_feedback=item.coach_tip, health_score=None, logged_at=logged_at,
                image_url=body.image_url, image_storage_key=body.image_storage_key,
                source_type=source_type, input_type=input_type,
                # Forward every health-condition score so the DB row captures
                # what the user saw on the menu-analysis card.
                inflammation_score=item.inflammation_score,
                is_ultra_processed=item.is_ultra_processed,
                glycemic_load=item.glycemic_load,
                fodmap_rating=item.fodmap_rating,
                fodmap_reason=item.fodmap_reason,
                # New in migration 1978 — structured drivers + added sugar.
                inflammation_triggers=item.inflammation_triggers,
                added_sugar_g=item.added_sugar_g,
            )
            if row and row.get("id"):
                created_ids.append(row["id"])

        from api.v1.nutrition.summaries import invalidate_daily_summary_cache
        from api.v1.home.bootstrap_cache import invalidate_bootstrap_cache
        await invalidate_daily_summary_cache(body.user_id)
        await invalidate_bootstrap_cache(body.user_id)
    except Exception as e:
        logger.error(f"[log-selected-items] error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Failed to log items")

    # Background: flip `liked=true` on matching menu_items entries for
    # menu/buffet logs. Plate logs don't come from a menu scan so they
    # don't need this annotation.
    if body.analysis_type in ("menu", "buffet"):
        async def _mark_liked_bg():
            try:
                from services.menu_items_rag_service import get_menu_items_rag
                rag = get_menu_items_rag()
                for item in body.items:
                    try:
                        await rag.mark_liked(user_id=body.user_id, dish_name=item.name)
                    except Exception:
                        # Single dish mark_liked failure shouldn't block the others.
                        continue
            except Exception as exc:
                logger.warning(f"[menu_items] mark_liked sweep failed: {exc}", exc_info=True)
        background.add_task(_mark_liked_bg)

    return {"success": True, "food_log_ids": created_ids, "count": len(created_ids)}
