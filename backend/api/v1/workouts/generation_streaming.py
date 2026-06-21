"""
Streaming workout generation endpoint.

Extracted from generation.py to keep files under 1000 lines.
Provides:
- POST /generate-stream - SSE streaming workout generation
"""
from core.db import get_supabase_db
from api.v1.workouts.generation_endpoints import _parse_workout_day_overrides
import json
import asyncio
from datetime import datetime
from typing import AsyncGenerator, Optional

from fastapi import APIRouter, Depends, Request, HTTPException
from core.auth import get_current_user
from fastapi.responses import StreamingResponse

from core.logger import get_logger
from core.config import get_settings
from models.schemas import GenerateWorkoutRequest
from ._gym_profile_helpers import get_active_gym_profile_id
from services.gemini_service import GeminiService, validate_set_targets_strict
from core.rate_limiter import user_limiter
from core.timezone_utils import resolve_timezone, get_user_today, target_date_to_utc_iso

from .utils import (
    row_to_workout,
    log_workout_change,
    index_workout_to_rag,
    parse_json_field,
    normalize_goals_list,
    get_user_strength_history,
    get_user_favorite_exercises,
    get_user_exercise_queue,
    get_user_staple_exercises,
    get_staple_names,
    get_user_1rm_data,
    get_user_training_intensity,
    get_user_intensity_overrides,
    apply_1rm_weights_to_exercises,
    get_intensity_from_fitness_level,
    get_user_avoided_exercises,
    get_user_avoided_muscles,
    # Exercise parameter validation (safety net)
    validate_and_cap_exercise_parameters,
    get_user_comeback_status,
    # Phase B3: recovery-aware generation
    get_recovery_workout_signal,
    apply_recovery_adjustment,
    # Progression philosophy helpers
    get_user_rep_preferences,
    get_user_progression_context,
    build_progression_philosophy_prompt,
    # Hormonal health context helpers
    get_user_hormonal_context,
    # Focus area validation
    validate_and_filter_focus_mismatches,
    # Duration resolver (request body → gym profile → user preferences → default)
    resolve_target_duration,
)

from .generation_helpers import (
    _estimate_workout_met,
    normalize_exercise_numeric_fields,
    post_filter_equipment_violations,
    post_filter_excluded_exercises,
    coerce_workout_type_from_focus,
)

router = APIRouter()
logger = get_logger(__name__)

# Recent-call short-circuit cache (see /generate-stream entry). 30s TTL.
# Keyed on user_id:scheduled_date:gym_profile_id so the SAME user can still
# manually fire generation for a different date without being blocked.
from core.redis_cache import RedisCache
_genstream_recent_cache = RedisCache(prefix="genstream_recent", ttl_seconds=30, max_size=500)


@router.post("/generate-stream")
# 30/min headroom: BG-GEN sequential top-up bursts up to 14 generations on
# profile activation, plus user-initiated regenerations. The previous 15/min
# tripped on a profile switch + a single manual retry, then cascaded with the
# frontend auto-retry loop. Combined with the new client-side cooldown gate
# (today_workout_provider._lastGenerationFailure) and server-side recent-call
# short-circuit (Redis genstream_recent:{user_id}), 30/min still hard-stops
# spam without breaking the legitimate burst.
@user_limiter.limit("30/minute")
async def generate_workout_streaming(request: Request, body: GenerateWorkoutRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Generate a workout with streaming response for faster perceived performance.

    Returns Server-Sent Events (SSE) with:
    - event: chunk - Partial workout data as it's generated
    - event: done - Final complete workout data
    - event: error - Error message if generation fails
    - event: already_generating - Workout generation already in progress

    Time to first content is typically <500ms vs 3-8s for full generation.
    """
    logger.info(f"Streaming workout generation for user {body.user_id}")

    # Recent-call short-circuit: if the same user fired /generate-stream within
    # the last 30s for the same date, return event:already_generating SSE
    # instead of letting slowapi reject with 429. This converts the auto-retry
    # cascade into a graceful "still in flight" response that the frontend
    # treats as progress, breaking the loop. Tracked separately from the
    # status='generating' DB row because mid-stream failures (e.g. Vertex 429)
    # can leave no DB row but still represent a recently-attempted generation.
    _recent_key = f"{body.user_id}:{body.scheduled_date or 'today'}:{body.gym_profile_id or 'noprofile'}"
    _recent = await _genstream_recent_cache.get(_recent_key)
    if _recent:
        logger.info(
            f"[Streaming] Short-circuit: user {body.user_id} fired /generate-stream "
            f"for {body.scheduled_date} within last 30s — returning already_generating"
        )

        async def _recent_already_sse():
            yield (
                f"event: already_generating\n"
                f"data: {json.dumps({'status': 'already_generating', 'workout_id': _recent.get('workout_id'), 'message': 'Workout generation already in progress'})}\n\n"
            )

        return StreamingResponse(_recent_already_sse(), media_type="text/event-stream")

    # Mark this user/date as recently attempted (cleared on completion or error
    # via the finally block in generate_sse).
    await _genstream_recent_cache.set(_recent_key, {"started_at": datetime.now().isoformat()})

    # Idempotency check: If a workout is already being generated for this user/date, return early
    db = get_supabase_db()
    _user_tz = resolve_timezone(request, db, body.user_id)
    scheduled_date = body.scheduled_date or get_user_today(_user_tz)

    # Preferred-day gate: reject requests whose scheduled_date falls outside the
    # user's configured workout days unless the caller explicitly opted in via
    # force_non_preferred_day (e.g., "Do this today" in the Regenerate sheet).
    # Without this gate, any stale client or accidental call plants a workout on
    # a rest day and the home carousel dutifully surfaces it as TODAY.
    #
    # Schedule resolution mirrors the upstream `_get_upcoming_dates_needing_generation`
    # in today.py — active gym profile's workout_days wins, fallback to user-level
    # preferences. See the matching gate in generation_endpoints.py for the full
    # rationale (2026-05-07 BG-GEN rejection-loop fix).
    if not body.force_non_preferred_day:
        from .today import _resolve_workout_days, _calculate_next_workout_date
        _gate_user = db.get_user(body.user_id)
        if _gate_user:
            _gate_profile = None
            _gate_profile_id = body.gym_profile_id
            if not _gate_profile_id:
                try:
                    _active_resp = await asyncio.to_thread(db.client.table("gym_profiles").select(
                        "id, workout_days"
                    ).eq("user_id", body.user_id).eq("is_active", True).maybe_single().execute)
                    if _active_resp and _active_resp.data:
                        _gate_profile = _active_resp.data
                except Exception:
                    pass
            else:
                try:
                    _profile_resp = await asyncio.to_thread(db.client.table("gym_profiles").select(
                        "id, workout_days"
                    ).eq("id", _gate_profile_id).maybe_single().execute)
                    if _profile_resp and _profile_resp.data:
                        _gate_profile = _profile_resp.data
                except Exception:
                    pass
            _selected_days = _resolve_workout_days(_gate_user, _gate_profile)
            if _selected_days:
                try:
                    _weekday = datetime.strptime(scheduled_date, "%Y-%m-%d").weekday()
                except ValueError:
                    _weekday = None
                if _weekday is not None and _weekday not in _selected_days:
                    _today_str = get_user_today(_user_tz)
                    _suggested = _calculate_next_workout_date(_selected_days, user_today_str=_today_str)
                    logger.info(
                        f"[PreferredDayGate] Rejecting /generate-stream for user={body.user_id} "
                        f"scheduled_date={scheduled_date} (weekday={_weekday}, preferred={_selected_days}); "
                        f"suggested_date={_suggested}"
                    )
                    raise HTTPException(
                        status_code=409,
                        detail={
                            "error": "not_a_workout_day",
                            "scheduled_date": scheduled_date,
                            "suggested_date": _suggested,
                            "selected_days": _selected_days,
                        },
                    )

    # Reject cardio-only equipment + strength focus upfront with a clean 422
    # so the harness/client gets a directed message ("switch focus or add
    # equipment") instead of a generic pool-too-small failure mid-stream.
    # Uses body.equipment when provided (covers harness scenarios + clients
    # that forward the saved profile equipment); otherwise skips and lets
    # the downstream pool gate handle it.
    if body.equipment:
        from .generation_helpers import check_equipment_focus_compatibility
        _preflight_focus = body.focus_areas[0] if body.focus_areas else "full_body"
        check_equipment_focus_compatibility(_preflight_focus, body.equipment)

    # Resolve gym_profile_id early for dedup checks. None is a valid outcome:
    # legacy users or users mid-onboarding may not have an active profile yet,
    # and the generator handles profile_id=None downstream.
    stream_gym_profile_id = body.gym_profile_id or get_active_gym_profile_id(db, body.user_id)

    try:
        # NB: dedup intentionally ignores gym_profile_id. A user can have at most one
        # *current* AI workout per day; gym profile is contextual, not part of the
        # natural key. Filtering by profile lets a parallel writer with profile=NULL
        # (or a different profile) sneak past, producing duplicate today rows.
        existing_generating = await asyncio.to_thread(db.client.table("workouts").select("id").eq(
            "user_id", body.user_id
        ).eq(
            "scheduled_date", scheduled_date
        ).eq(
            "status", "generating"
        ).execute)

        if existing_generating.data:
            workout_id = existing_generating.data[0]["id"]
            logger.info(f"[Idempotency] Workout already generating for {body.user_id} on {scheduled_date} (profile={stream_gym_profile_id}): {workout_id}")

            async def already_generating_sse():
                yield f"event: already_generating\ndata: {json.dumps({'status': 'already_generating', 'workout_id': workout_id, 'message': 'Workout generation already in progress'})}\n\n"

            return StreamingResponse(already_generating_sse(), media_type="text/event-stream")

        # Duplicate check: if a current, non-cancelled workout already exists for
        # this user+date, return it — regardless of gym_profile_id (see comment above).
        existing_workout = await asyncio.to_thread(db.client.table("workouts").select("id,name,status").eq(
            "user_id", body.user_id
        ).eq(
            "scheduled_date", scheduled_date
        ).eq(
            "is_current", True
        ).neq(
            "status", "generating"
        ).neq(
            "status", "cancelled"
        ).limit(1).execute)

        if existing_workout.data:
            workout_id = existing_workout.data[0]["id"]
            logger.info(f"[Duplicate] Workout already exists for {body.user_id} on {scheduled_date}: {workout_id}")
            try:
                full_workout = await asyncio.to_thread(db.client.table("workouts").select("*").eq("id", workout_id).single().execute)
            except Exception as e:
                # Row was deleted between the duplicate-check and the refetch, or RLS
                # blocked the read. Skip the shortcut and fall through to regenerate.
                logger.warning(f"[Duplicate] Failed to refetch workout {workout_id}: {e}")
                full_workout = None

            if full_workout and full_workout.data:
                async def existing_sse():
                    yield f"event: done\ndata: {json.dumps(full_workout.data)}\n\n"

                return StreamingResponse(existing_sse(), media_type="text/event-stream")
    except Exception as e:
        # Log but don't fail - idempotency check is a nice-to-have
        logger.warning(f"[Idempotency] Check failed: {e}", exc_info=True)

    # Premium gate check: enforce free-tier workout generation limits
    from core.premium_gate import check_premium_gate
    await check_premium_gate(body.user_id, "ai_workout_generation", _user_tz)

    async def generate_sse() -> AsyncGenerator[str, None]:
        start_time = datetime.now()
        gym_profile_id = None  # Track which profile this workout is generated for
        # Track user + gym_profile across both branches below so the duration
        # resolver can consult them (short-circuit path leaves both as None).
        user = None
        gym_profile = None
        # Bind defaults so the body-only fast-path below doesn't leave these
        # unbound when downstream code (e.g. line ~455 generator_kwargs) reads
        # them. See generation_endpoints.py for the same fix on /generate.
        training_split = None
        workout_days: List[str] = []
        gym_profile_id = None
        preferences: Dict[str, Any] = {}
        # Bind workout_type_override before the try so the outer except handler
        # and any post-try references (~L611, 889, 895, 982) don't NameError
        # if user-lookup raises before the in-try assignment at L261.
        workout_type_override: Optional[str] = getattr(body, "workout_type", None)

        try:

            # ALWAYS load user record + active gym_profile from Supabase. Body fields
            # act as OVERRIDES on top of persisted state — they don't bypass the user
            # lookup. Mirrors the /generate endpoint refactor (2026-05-08).
            user = db.get_user(body.user_id)
            if not user:
                yield f"event: error\ndata: {json.dumps({'error': 'User not found'})}\n\n"
                return

            fitness_level = body.fitness_level or user.get("fitness_level")
            preferences = parse_json_field(user.get("preferences"), {})

            # Caller-supplied workout type override (matches the pattern used
            # in workouts_db_versioning.py:101). The 4 downstream references
            # below (lines 595, 845, 851, 938) NameError'd in production
            # without this binding — bug introduced by commit 71e4c804
            # ("workout quality base").
            workout_type_override = getattr(body, "workout_type", None)

            gym_profile = None
            if hasattr(body, 'gym_profile_id') and body.gym_profile_id:
                try:
                    profile_result = await asyncio.to_thread(db.client.table("gym_profiles").select("*").eq("id", body.gym_profile_id).single().execute)
                    gym_profile = profile_result.data if profile_result.data else None
                    logger.info(f"[GymProfile] Using requested profile: {body.gym_profile_id}")
                except Exception as e:
                    logger.warning(f"Failed to fetch gym profile: {e}", exc_info=True)
            else:
                try:
                    active_result = await asyncio.to_thread(db.client.table("gym_profiles").select("*").eq("user_id", body.user_id).eq("is_active", True).single().execute)
                    gym_profile = active_result.data if active_result.data else None
                    if gym_profile:
                        logger.info(f"[GymProfile] Using active profile: {gym_profile.get('name')} ({gym_profile.get('id')})")
                except Exception as e:
                    logger.debug(f"No active gym profile found: {e}")

            if gym_profile:
                gym_profile_id = gym_profile.get("id")
                equipment = body.equipment or gym_profile.get("equipment") or []
                training_split = gym_profile.get("training_split")
                workout_days = gym_profile.get("workout_days") or []
                profile_goals = normalize_goals_list(gym_profile.get("goals"))
                user_goals = normalize_goals_list(user.get("goals"))
                goals = normalize_goals_list(body.goals) if body.goals else (profile_goals if profile_goals else user_goals)
                logger.info(f"[GymProfile] Profile equipment: {len(equipment)} items")
                if training_split:
                    logger.info(f"[GymProfile-Stream] Training split: {training_split}")
            else:
                goals = normalize_goals_list(body.goals) if body.goals else normalize_goals_list(user.get("goals"))
                equipment = body.equipment or parse_json_field(user.get("equipment"), [])
                training_split = user.get("training_split")
                workout_days = parse_json_field(user.get("workout_days"), [])

            intensity_preference = preferences.get("intensity_preference") or get_intensity_from_fitness_level(fitness_level)

            # Fetch user preferences in PARALLEL for faster response
            async def fetch_ai_coach_settings():
                """Helper to fetch AI coach settings with error handling."""
                try:
                    ai_result = await asyncio.to_thread(db.client.table("user_ai_settings").select(
                        "coaching_style", "communication_tone", "coach_name", "coach_persona_id"
                    ).eq("user_id", body.user_id).single().execute)
                    return ai_result.data if ai_result.data else None
                except Exception as e:
                    logger.debug(f"[Streaming] No AI coach settings found, using defaults: {e}")
                    return None

            # Injury safety (injury-2026-06): read the UNIFIED active-injury list
            # (user_injuries table + users.active_injuries) so the streaming path —
            # the primary onboarding generator — finally has injury context. Used
            # both to constrain the Gemini prompt and to drive the terminal
            # enforce_injury_safety guard below.
            from api.v1.workouts.readiness_utils import get_active_injuries_with_muscles

            (
                avoided_exercises,
                avoided_muscles,
                staple_exercises,
                rep_preferences,
                progression_context,
                hormonal_context,
                ai_coach_settings,
                strength_history,
                favorite_exercises,
                exercise_queue,
                recovery_signal,
                injury_context,
            ) = await asyncio.gather(
                get_user_avoided_exercises(body.user_id),
                get_user_avoided_muscles(body.user_id),
                get_user_staple_exercises(body.user_id, gym_profile_id=gym_profile_id, scheduled_date=getattr(body, 'scheduled_date', None)),
                get_user_rep_preferences(body.user_id),
                get_user_progression_context(body.user_id),
                get_user_hormonal_context(body.user_id, timezone_str=resolve_timezone(request, db, body.user_id)),
                fetch_ai_coach_settings(),
                get_user_strength_history(body.user_id),
                get_user_favorite_exercises(body.user_id),
                get_user_exercise_queue(body.user_id),
                # Phase B3: recovery-aware generation. {"applies": False} for
                # no-wearable / no-consent / stale / optimal+good users — in
                # which case generation stays byte-identical to a pre-B3 run.
                get_recovery_workout_signal(body.user_id),
                get_active_injuries_with_muscles(body.user_id),
            )
            active_injuries = (injury_context or {}).get("injuries", []) or []
            if active_injuries:
                logger.info(f"🩹 [Streaming] User has {len(active_injuries)} active injuries: {active_injuries}")

            # Log fetched preferences
            if avoided_exercises:
                logger.info(f"[Streaming] User has {len(avoided_exercises)} avoided exercises")
            if avoided_muscles.get("avoid") or avoided_muscles.get("reduce"):
                logger.info(f"[Streaming] User has avoided muscles")
            if staple_exercises:
                logger.info(f"[Streaming] User has {len(staple_exercises)} staple exercises")
            if favorite_exercises:
                logger.info(f"[Streaming] User has {len(favorite_exercises)} favorite exercises: {favorite_exercises[:5]}")
            if exercise_queue:
                logger.info(f"[Streaming] User has {len(exercise_queue)} queued exercises")
            if ai_coach_settings:
                logger.info(f"[Streaming] Coach settings: style={ai_coach_settings.get('coaching_style')}, tone={ai_coach_settings.get('communication_tone')}")

            # Build progression philosophy from fetched data
            progression_philosophy = build_progression_philosophy_prompt(
                rep_preferences=rep_preferences,
                progression_context=progression_context,
            )

            # Process hormonal context
            hormonal_ai_context = hormonal_context.get("ai_context", "")
            if hormonal_context.get("cycle_phase"):
                logger.info(f"[Streaming] User is in {hormonal_context['cycle_phase']} phase")

            # Combine progression philosophy with hormonal context
            combined_context = progression_philosophy or ""
            if hormonal_ai_context:
                combined_context = f"{combined_context}\n\nHORMONAL HEALTH CONTEXT:\n{hormonal_ai_context}" if combined_context else f"HORMONAL HEALTH CONTEXT:\n{hormonal_ai_context}"

            # Phase B3: append the recovery prompt block when a wearable
            # recovery signal applies. Informational only — the load-affecting
            # scaling is applied deterministically post-generation. No-op when
            # recovery_signal["applies"] is False, so the prompt stays
            # byte-identical to a pre-B3 run.
            recovery_prompt_context = (
                recovery_signal.get("prompt_context", "")
                if isinstance(recovery_signal, dict) and recovery_signal.get("applies")
                else ""
            )
            if recovery_prompt_context:
                combined_context = (
                    f"{combined_context}\n{recovery_prompt_context}"
                    if combined_context
                    else recovery_prompt_context
                )

            gemini_service = GeminiService()

            # Resolve target duration from request body → gym profile → user preferences.
            # Without this, body.duration_minutes defaults to None and the effective
            # value silently falls to 45 min even when the user set a different preference.
            resolved_duration = resolve_target_duration(
                body_duration=body.duration_minutes,
                body_duration_min=body.duration_minutes_min,
                body_duration_max=body.duration_minutes_max,
                gym_profile=gym_profile,
                user=user,
            )
            target_duration = resolved_duration["target"]
            target_duration_min = resolved_duration["min"]
            target_duration_max = resolved_duration["max"]
            logger.info(
                f"[Streaming Duration] Resolved target={target_duration}, "
                f"min={target_duration_min}, max={target_duration_max} "
                f"(body={body.duration_minutes}, gym.duration_minutes={gym_profile.get('duration_minutes') if gym_profile else None})"
            )

            # Calculate exercise count with fitness-level caps
            effective_duration = target_duration_max or target_duration_min or target_duration
            base_exercise_count = max(4, min(12, effective_duration // 6))

            EXERCISE_CAPS = {
                "beginner": {30: 4, 45: 5, 60: 5, 75: 6, 90: 6},
                "intermediate": {30: 5, 45: 6, 60: 7, 75: 8, 90: 9},
                "advanced": {30: 5, 45: 7, 60: 8, 75: 10, 90: 11},
            }
            HELL_MODE_EXERCISE_CAPS = {
                "beginner": {30: 5, 45: 6, 60: 6, 75: 7, 90: 7},
                "intermediate": {30: 6, 45: 7, 60: 8, 75: 9, 90: 10},
                "advanced": {30: 6, 45: 8, 60: 10, 75: 11, 90: 12},
            }

            is_hell_mode = intensity_preference and intensity_preference.lower() == "hell"
            cap_table = HELL_MODE_EXERCISE_CAPS if is_hell_mode else EXERCISE_CAPS
            level = fitness_level or "intermediate"
            level_caps = cap_table.get(level, cap_table["intermediate"])

            if effective_duration <= 35:
                duration_bracket = 30
            elif effective_duration <= 50:
                duration_bracket = 45
            elif effective_duration <= 65:
                duration_bracket = 60
            elif effective_duration <= 80:
                duration_bracket = 75
            else:
                duration_bracket = 90

            max_exercises = level_caps.get(duration_bracket, 8)
            exercise_count = min(base_exercise_count, max_exercises)

            logger.info(f"[Streaming Exercise Count] Level: {level}, Duration: {effective_duration}min, Hell: {is_hell_mode}, Cap: {max_exercises}, Final: {exercise_count}")

            # Send initial acknowledgment (time to first byte)
            first_chunk_time = (datetime.now() - start_time).total_seconds() * 1000
            yield f"event: chunk\ndata: {json.dumps({'status': 'started', 'ttfb_ms': first_chunk_time})}\n\n"

            # Stream the workout generation
            accumulated_chunks = []
            total_chars = 0
            chunk_count = 0

            # Equipment guard: filter out "All Profiles" staples whose equipment isn't available
            if equipment and staple_exercises:
                filtered = []
                equipment_lower = [e.lower() for e in equipment]
                for s in staple_exercises:
                    if s.get("gym_profile_id") is not None:
                        filtered.append(s)
                    elif not s.get("equipment") or s["equipment"].lower() in equipment_lower:
                        filtered.append(s)
                    else:
                        logger.info(f"Skipping all-profiles staple '{s['name']}' - requires '{s.get('equipment')}' not in profile equipment")
                staple_exercises = filtered

            staple_names = get_staple_names(staple_exercises) if staple_exercises else None

            # Check if context caching is enabled (faster generation)
            settings = get_settings()
            use_cached = settings.gemini_cache_enabled
            logger.info(f"[Streaming] Using {'CACHED' if use_cached else 'non-cached'} workout generation")

            try:
                generator_func = (
                    gemini_service.generate_workout_plan_streaming_cached
                    if use_cached
                    else gemini_service.generate_workout_plan_streaming
                )

                generator_kwargs = {
                    "fitness_level": fitness_level or "intermediate",
                    "goals": goals if isinstance(goals, list) else [],
                    "equipment": equipment if isinstance(equipment, list) else [],
                    "duration_minutes": target_duration,
                    "duration_minutes_min": target_duration_min,
                    "duration_minutes_max": target_duration_max,
                    "focus_areas": body.focus_areas,
                    "intensity_preference": intensity_preference,
                    "avoided_exercises": avoided_exercises if avoided_exercises else None,
                    "avoided_muscles": avoided_muscles if (avoided_muscles.get("avoid") or avoided_muscles.get("reduce")) else None,
                    # Injury prevention: hard-ban contraindicated movements per
                    # active injury in the prompt (the deterministic post-filter
                    # below is the guarantee; this reduces how often it must fire).
                    "injuries": active_injuries if active_injuries else None,
                    "staple_exercises": staple_names,
                    "progression_philosophy": combined_context if combined_context else None,
                    "exercise_count": exercise_count,
                    "coach_style": ai_coach_settings.get("coaching_style") if ai_coach_settings else None,
                    "coach_tone": ai_coach_settings.get("communication_tone") if ai_coach_settings else None,
                    "scheduled_date": scheduled_date,
                    "user_dob": user.get("date_of_birth") if user else None,
                    "user_id": body.user_id,
                    "training_split": training_split,
                    "workout_days": workout_days if workout_days else None,
                    # Per-day overrides — focus/duration/intensity per
                    # weekday from user.preferences.workout_day_overrides
                    # JSONB. Added 2026-05-27.
                    "workout_day_overrides": _parse_workout_day_overrides(
                        preferences.get("workout_day_overrides") if preferences else None
                    ),
                }

                generator_kwargs["strength_history"] = strength_history
                generator_kwargs["workout_weight_unit"] = user.get("workout_weight_unit") or user.get("weight_unit") or "lbs" if user else "lbs"

                # RAG-FIRST refactor (2026-05-08, user request): pre-fetch
                # library exercises and pass them to Gemini so it can ONLY use
                # library-backed names. Eliminates exercise hallucination —
                # every output gets an exercise_id, video_url, image_s3_path.
                # Falls back to AI-first if library returns nothing (rare).
                try:
                    from services.exercise_library_service import get_exercise_library_service
                    _lib_svc = get_exercise_library_service()
                    _focus_for_lib = (
                        body.focus_areas[0] if body.focus_areas else "full_body"
                    )
                    _eq_for_lib = (
                        equipment if (isinstance(equipment, list) and equipment)
                        else ["body weight"]
                    )
                    # Fetch a generous pool (3× the workout's exercise count)
                    # so Gemini has selection room within the focus/equipment
                    # constraints. Cap at 50 in the prompt block.
                    _library_pool = _lib_svc.get_exercises_for_workout(
                        focus_area=_focus_for_lib,
                        equipment=_eq_for_lib,
                        count=max(15, exercise_count * 3),
                        fitness_level=fitness_level or "intermediate",
                    )
                    if _library_pool:
                        generator_kwargs["library_exercises"] = _library_pool
                        logger.info(
                            f"[Streaming RAG-first] Pre-fetched {len(_library_pool)} "
                            f"library exercises for focus={_focus_for_lib}, "
                            f"eq={len(_eq_for_lib)} items, fl={fitness_level}"
                        )
                    else:
                        logger.warning(
                            f"[Streaming RAG-first] Library returned 0 exercises "
                            f"for focus={_focus_for_lib}/eq={_eq_for_lib} — "
                            f"falling back to AI-first (Gemini may hallucinate)"
                        )
                except Exception as _lib_err:
                    logger.warning(
                        f"[Streaming RAG-first] Library lookup failed: {_lib_err} — "
                        f"falling back to AI-first",
                        exc_info=True,
                    )

                async for chunk in generator_func(**generator_kwargs):
                    accumulated_chunks.append(chunk)
                    total_chars += len(chunk)
                    chunk_count += 1

                    if chunk_count % 3 == 0:
                        elapsed_ms = (datetime.now() - start_time).total_seconds() * 1000
                        yield f"event: chunk\ndata: {json.dumps({'status': 'generating', 'progress': total_chars, 'elapsed_ms': elapsed_ms})}\n\n"

                accumulated_text = "".join(accumulated_chunks)
                logger.info(f"[Streaming] Stream completed: {chunk_count} chunks, {len(accumulated_text)} total chars")
            except Exception as stream_error:
                logger.error(f"[Streaming] Stream error after {chunk_count} chunks, {total_chars} chars: {stream_error}", exc_info=True)
                yield f"event: error\ndata: {json.dumps({'error': f'Streaming failed: {str(stream_error)}'})}\n\n"
                return

            # Parse the complete response
            try:
                content = accumulated_text.strip()
                logger.info(f"[Streaming Parse] Raw response length: {len(accumulated_text)} chars")
                logger.debug(f"[Streaming Parse] Raw content: {accumulated_text[:500]}...")

                if "```json" in content:
                    content = content.split("```json")[1].split("```")[0].strip()
                elif "```" in content:
                    parts = content.split("```")
                    if len(parts) >= 2:
                        content = parts[1].strip()
                        if content.startswith(("json", "JSON")):
                            content = content[4:].strip()

                logger.info(f"[Streaming Parse] Cleaned content length: {len(content)} chars")
                if len(content) < 100:
                    logger.error(f"[Streaming Parse] Content too short, full content: {content}")

                workout_data = json.loads(content)

                if isinstance(workout_data, str):
                    try:
                        workout_data = json.loads(workout_data)
                    except (json.JSONDecodeError, ValueError):
                        logger.error(f"workout_data is a string that cannot be parsed: {workout_data[:200]}", exc_info=True)
                        workout_data = {}

                if not isinstance(workout_data, dict):
                    logger.error(f"workout_data is not a dict: type={type(workout_data).__name__}")
                    workout_data = {}

                exercises = workout_data.get("exercises", [])
                exercises = normalize_exercise_numeric_fields(exercises)

                # Normalize equipment values — Gemini echoes snake_case from user profile
                from services.exercise_rag.utils import normalize_equipment_value
                for ex in exercises:
                    raw_eq = ex.get("equipment", "")
                    if raw_eq and "_" in raw_eq:
                        ex["equipment"] = normalize_equipment_value(raw_eq, ex.get("name", ""))

                # Phase D: Algorithmic naming — replaces Gemini's name field
                # entirely. Gemini collapsed onto ~5 words (Titan/Phoenix/
                # Iron/Steel/Foundation = 58% of recent sweep). We compute
                # workout_type/difficulty below and re-derive name then; for
                # now use a temporary placeholder. The real assignment
                # happens after _derived_type and difficulty are resolved.
                workout_name = "Generated Workout"  # placeholder; replaced below
                # Derive workout_type from focus + goal when Gemini omits it.
                # Default-to-"strength" was making 96% of workouts labeled strength
                # even when actual content was cardio/mobility (validation harness
                # 2026-05-08: idx 15/37/56 had 100% cardio content labeled strength;
                # 0/7 hypertrophy goals returned type=hypertrophy).
                _focus_for_type = (body.focus_areas[0] if body.focus_areas else "").lower()
                _focus_to_type = {
                    "cardio": "cardio",
                    "mobility": "mobility",
                    "stretch": "mobility",
                }
                _derived_type = _focus_to_type.get(_focus_for_type)
                # If focus didn't pin a type, fall back to goal-keyed type.
                if not _derived_type:
                    _goals_lower = [str(g).lower() for g in (goals or [])]
                    if "hypertrophy" in _goals_lower:
                        _derived_type = "hypertrophy"
                    elif "endurance" in _goals_lower or "fat_loss" in _goals_lower:
                        _derived_type = "cardio" if "cardio" in (workout_type_override or "").lower() else "hybrid"
                    elif "mobility" in _goals_lower:
                        _derived_type = "mobility"
                    elif "power" in _goals_lower:
                        _derived_type = "strength"  # power is in the strength family for tagging
                    else:
                        _derived_type = "strength"
                workout_type = workout_data.get("type", body.workout_type or _derived_type)
                difficulty = workout_data.get("difficulty", intensity_preference)

                # Content-vs-declared-type override: if Gemini's exercises clearly
                # don't match the declared type, fix it server-side. Heuristic
                # match on exercise name keywords.
                _ex_names_lower = " | ".join(
                    (ex.get("name", "") or "").lower() for ex in (exercises or [])
                )
                _has_cardio = any(kw in _ex_names_lower for kw in [
                    "treadmill", "rowing machine", "stationary bike", "elliptical",
                    "sprint", "jump rope",
                ])
                _has_stretch = any(kw in _ex_names_lower for kw in [
                    "stretch", " pose", "foam roll", "child pose", "cobra pose",
                ])
                if exercises and len(exercises) >= 3:
                    _cardio_count = sum(
                        1 for ex in exercises
                        if any(kw in (ex.get("name", "") or "").lower() for kw in [
                            "treadmill", "rowing machine", "stationary bike",
                            "elliptical", "sprint", "jump rope",
                        ])
                    )
                    _stretch_count = sum(
                        1 for ex in exercises
                        if any(kw in (ex.get("name", "") or "").lower() for kw in [
                            "stretch", "pose", "foam roll", "release",
                        ])
                    )
                    _total = len(exercises)
                    if _cardio_count / _total >= 0.5 and (workout_type or "").lower() != "cardio":
                        logger.warning(
                            f"⚠️ [TypeContent] {_cardio_count}/{_total} cardio exercises "
                            f"but type='{workout_type}' — overriding to 'cardio'"
                        )
                        workout_type = "cardio"
                    elif _stretch_count / _total >= 0.5 and (workout_type or "").lower() not in ("mobility", "recovery"):
                        logger.warning(
                            f"⚠️ [TypeContent] {_stretch_count}/{_total} stretch exercises "
                            f"but type='{workout_type}' — overriding to 'mobility'"
                        )
                        workout_type = "mobility"

                # Difficulty-ceiling enforcement (validation harness 2026-05-08:
                # beginner request idx 6 returned `difficulty=hard` with Pistol
                # Squats / Pull-ups / Archer Push-ups — strict ceiling violated).
                # Beginners NEVER get hard/hell; advanced+non-mobility never gets easy.
                _fl = (fitness_level or "intermediate").lower()
                _diff = (difficulty or "").lower()
                _focus_str = (body.focus_areas[0] if body.focus_areas else "").lower()
                _is_mobility_intent = (
                    "mobility" in _focus_str or "stretch" in _focus_str
                    or (workout_type or "").lower() in ("mobility", "recovery", "stretch")
                )

                if _fl == "beginner" and _diff in ("hard", "hell"):
                    logger.warning(
                        f"⚠️ [DifficultyCeiling] Beginner request returned '{difficulty}' "
                        f"— forcing to 'medium' (workout='{workout_name}')"
                    )
                    difficulty = "medium"
                    workout_data["difficulty"] = "medium"
                elif _fl == "advanced" and _diff == "easy" and not _is_mobility_intent:
                    logger.warning(
                        f"⚠️ [DifficultyCeiling] Advanced non-mobility request returned 'easy' "
                        f"— bumping to 'medium' (workout='{workout_name}', focus={_focus_str})"
                    )
                    difficulty = "medium"
                    workout_data["difficulty"] = "medium"
                elif _is_mobility_intent and _diff in ("hard", "hell"):
                    # idx 21 (advanced + mobility focus + 30min): output was 'hard'
                    # with 8 resistance-band exercises — wrong intent. Mobility/
                    # stretch sessions cap at 'medium' so users actually get
                    # recovery, not a hard workout in disguise.
                    logger.warning(
                        f"⚠️ [DifficultyCeiling] Mobility/stretch focus returned '{difficulty}' "
                        f"— capping to 'easy' (workout='{workout_name}', focus={_focus_str})"
                    )
                    difficulty = "easy"
                    workout_data["difficulty"] = "easy"

                # workout_type ↔ focus consistency override (idx 52: focus=mobility
                # but type=strength is internally inconsistent).
                _wo_type_lc = (workout_type or "").lower()
                if _is_mobility_intent and _wo_type_lc in ("strength", "hypertrophy"):
                    logger.warning(
                        f"⚠️ [TypeConsistency] Mobility focus + type='{workout_type}' "
                        f"— overriding type to 'mobility'"
                    )
                    workout_type = "mobility"
                elif _focus_str == "cardio" and _wo_type_lc in ("strength", "hypertrophy"):
                    logger.warning(
                        f"⚠️ [TypeConsistency] Cardio focus + type='{workout_type}' "
                        f"— overriding type to 'cardio'"
                    )
                    workout_type = "cardio"

                # Phase D: Algorithmic naming — replace Gemini's name field
                # entirely now that workout_type/difficulty are finalized.
                # Top-10 Gemini names covered 58% of recent sweep ("Titan"
                # alone appeared 172/428 times). Honor body.workout_name
                # if the caller pre-set one (renames), else generate.
                _explicit_name = getattr(body, "workout_name", None)
                if _explicit_name:
                    workout_name = _explicit_name
                else:
                    try:
                        from services.workout_naming import generate_workout_name
                        _primary_goal = (goals[0] if isinstance(goals, list) and goals else None)
                        _primary_focus = (
                            body.focus_areas[0] if body.focus_areas else None
                        )
                        # Seed differentiator: when a plan generates many
                        # workouts for the same user on the same calendar day
                        # (back-to-back streaming calls during plan creation),
                        # workout_id=None + identical params collapse to the
                        # same seed and yield the same name (e.g. Tue & Thu
                        # both "Gentle Upper Flow" for the same user). Use
                        # scheduled_date as the per-call salt so each day gets
                        # a distinct RNG stream.
                        _name_salt = scheduled_date or getattr(body, "scheduled_date", None)
                        workout_name = generate_workout_name(
                            goal=_primary_goal,
                            focus=_primary_focus,
                            equipment=equipment if isinstance(equipment, list) else None,
                            duration_minutes=target_duration,
                            difficulty=difficulty,
                            workout_type=workout_type,
                            user_id=str(body.user_id) if getattr(body, "user_id", None) else None,
                            workout_id=str(_name_salt) if _name_salt else None,
                        )
                    except Exception as _name_err:
                        logger.warning(f"⚠️ [Naming] algorithmic namer failed: {_name_err}")
                        workout_name = workout_data.get("name", "Generated Workout")

                # exclude_exercises + adjacent_day_exercises post-filter.
                # Validation harness 2026-05-09 idx 248: substring filter let
                # "Burpee" pass when exclude=['burpee']; canonical comparison
                # plus the substring backstop catches both alias forms.
                exercises = post_filter_excluded_exercises(
                    exercises,
                    body.exclude_exercises,
                    body.adjacent_day_exercises,
                )
                # Equipment compatibility post-filter (validation harness
                # 2026-05-09: 4 kettlebell exercises leaked into a workout
                # whose request equipment list explicitly excluded kettlebell).
                exercises = post_filter_equipment_violations(
                    exercises,
                    user_equipment=(equipment if isinstance(equipment, list) else None),
                    goals=goals if isinstance(goals, list) else None,
                )

                workout_description = workout_data.get("description")
                estimated_duration = workout_data.get("estimated_duration_minutes")
                if estimated_duration is not None:
                    estimated_duration = int(estimated_duration)
                else:
                    fallback_duration = 0
                    for ex in exercises:
                        sets = ex.get("sets", 3)
                        reps = ex.get("reps", 10)
                        rest = ex.get("rest_seconds", 60)
                        time_per_set = (reps * 3) + rest
                        exercise_time = sets * time_per_set
                        fallback_duration += exercise_time
                    fallback_duration = (fallback_duration + len(exercises) * 30) / 60
                    estimated_duration = max(10, int(fallback_duration))
                    logger.debug(f"[Streaming Duration] Calculated fallback duration: {estimated_duration} min")

                # DURATION VALIDATION (against resolved target, not raw body value)
                if estimated_duration and target_duration_max:
                    if estimated_duration > target_duration_max:
                        logger.warning(f"[Streaming Duration] Estimated duration {estimated_duration} min exceeds max {target_duration_max} min")
                    else:
                        logger.debug(f"[Streaming Duration] Estimated {estimated_duration} min is within range")
                elif estimated_duration:
                    logger.debug(f"[Streaming Duration] Estimated duration: {estimated_duration} min")

                # POST-GENERATION VALIDATION: Filter out exercises that violate user preferences
                if avoided_exercises:
                    original_count = len(exercises)
                    exercises = [
                        ex for ex in exercises
                        if ex.get("name", "").lower() not in [ae.lower() for ae in avoided_exercises]
                    ]
                    filtered_count = original_count - len(exercises)
                    if filtered_count > 0:
                        logger.warning(f"[Streaming Validation] Filtered out {filtered_count} avoided exercises")

                if avoided_muscles and avoided_muscles.get("avoid"):
                    original_count = len(exercises)
                    avoid_muscles_lower = [m.lower() for m in avoided_muscles["avoid"]]
                    exercises = [
                        ex for ex in exercises
                        if ex.get("muscle_group", "").lower() not in avoid_muscles_lower
                    ]
                    filtered_count = original_count - len(exercises)
                    if filtered_count > 0:
                        logger.warning(f"[Streaming Validation] Filtered out {filtered_count} exercises targeting avoided muscles")

                # Handle "reduce" muscles - limit to max 1 exercise per reduced muscle
                if avoided_muscles and avoided_muscles.get("reduce"):
                    reduce_muscles_lower = [m.lower() for m in avoided_muscles["reduce"]]
                    reduced_seen = set()
                    new_exercises = []
                    removed_count = 0

                    for ex in exercises:
                        muscle = ex.get("muscle_group", "").lower()
                        if muscle in reduce_muscles_lower:
                            if muscle not in reduced_seen:
                                reduced_seen.add(muscle)
                                new_exercises.append(ex)
                            else:
                                removed_count += 1
                        else:
                            new_exercises.append(ex)

                    if removed_count > 0:
                        logger.info(f"[Streaming Validation] Limited {removed_count} exercises targeting reduced muscles")
                        exercises = new_exercises

                # Phase 3.5 (streaming): reject exercises requiring equipment the
                # user does not have. Mirrors generation_endpoints.py:691. Also
                # uses name-inference to catch mis-tagged library rows
                # (e.g. "Hanging Toes-to-Bar" stored as bodyweight but needing a bar).
                if equipment and exercises:
                    from services.exercise_rag.filters import filter_by_equipment
                    from services.exercise_rag.utils import infer_equipment_from_name
                    equipment_compatible = []
                    equipment_rejected_names: List[str] = []
                    for ex in exercises:
                        ex_equip = (ex.get("equipment") or "").strip()
                        ex_name = ex.get("name", "") or ex.get("exercise_name", "")
                        # Override bodyweight/empty tags via name inference so
                        # mis-labeled rows don't sneak through.
                        if not ex_equip or ex_equip.lower() in ("bodyweight", "body weight", "none", ""):
                            ex_equip = infer_equipment_from_name(ex_name)
                        if filter_by_equipment(ex_equip, equipment, ex_name):
                            equipment_compatible.append(ex)
                        else:
                            equipment_rejected_names.append(ex_name)
                            logger.warning(
                                f"[Streaming Equipment Filter] Removed '{ex_name}' — "
                                f"requires '{ex_equip}', user has: {equipment}"
                            )
                    if equipment_rejected_names:
                        logger.info(
                            f"[Streaming Equipment Filter] Removed {len(equipment_rejected_names)} "
                            f"exercises with incompatible equipment: {equipment_rejected_names}"
                        )
                        exercises = equipment_compatible

                # Hard filters — drop warmup/stretch leakage and off-region
                # exercises BEFORE dedup. Mirrors versioning.py post-RAG step
                # so /generate-stream and /regenerate-stream behave the same.
                # Note: focus_areas (body regions) is the right signal here —
                # body.workout_type carries training STYLE post-Issue-1 split
                # (Strength/HIIT/Cardio/Push/Pull) which doesn't whitelist
                # muscles. We feed each focus_area through the whitelist and
                # union the survivors so multi-focus selections (e.g. Chest +
                # Full Body) don't get over-filtered.
                if exercises:
                    from services.exercise_rag.filters import (
                        filter_main_exercises,
                        filter_by_workout_type_muscles,
                    )
                    # User rule (2026-05-08): stretches must NEVER appear in
                    # workouts. They belong only in dedicated mobility/stretch
                    # sessions. Pass `is_mobility_workout` so the filter strips
                    # stretches from strength/hypertrophy/cardio workouts but
                    # KEEPS them in mobility/stretch/recovery sessions.
                    _focus_lc = [
                        (s or "").lower()
                        for s in (body.focus_areas or [])
                    ]
                    _is_mobility = any(
                        f in {"mobility", "stretch", "recovery"} for f in _focus_lc
                    ) or (workout_type_override or "").lower() in {
                        "mobility", "recovery", "stretch"
                    }
                    _is_combat = any(
                        f in {"cardio", "hiit", "conditioning", "boxing", "combat"}
                        for f in _focus_lc
                    ) or (workout_type_override or "").lower() in {
                        "cardio", "hiit", "boxing", "combat"
                    }
                    exercises = filter_main_exercises(
                        exercises,
                        is_mobility_workout=_is_mobility,
                        is_combat_workout=_is_combat,
                    )
                    _focus_for_filter = (
                        body.focus_areas
                        if hasattr(body, 'focus_areas') and body.focus_areas
                        else []
                    )
                    if _focus_for_filter:
                        # Union across selected regions: an exercise survives
                        # if it matches ANY selected region.
                        survivor_names: set = set()
                        all_survivors: list = []
                        for region in _focus_for_filter:
                            for ex in filter_by_workout_type_muscles(exercises, region):
                                nm = (ex.get("name") or "").lower()
                                if nm and nm not in survivor_names:
                                    survivor_names.add(nm)
                                    all_survivors.append(ex)
                        if all_survivors:
                            exercises = all_survivors

                # Defensive dedup: strip "(N)" suffixes that come from duplicate
                # library imports (e.g. Burpee vs Burpee(1)), then collapse
                # remaining duplicates by case-insensitive base name.
                if exercises:
                    from services.exercise_rag.utils import dedup_key, strip_dedup_suffix
                    _seen_keys: set = set()
                    _deduped: List[dict] = []
                    _collapsed = 0
                    for ex in exercises:
                        raw_name = ex.get("name", "") or ex.get("exercise_name", "")
                        key = dedup_key(raw_name)
                        if not key or key in _seen_keys:
                            _collapsed += 1
                            continue
                        _seen_keys.add(key)
                        # Normalize the stored name too so the client never sees "(N)".
                        cleaned = strip_dedup_suffix(raw_name)
                        if cleaned != raw_name:
                            ex["name"] = cleaned
                        _deduped.append(ex)
                    if _collapsed:
                        logger.info(f"[Streaming Dedup] Collapsed {_collapsed} duplicate exercises by normalized name")
                    exercises = _deduped

                workout_data["exercises"] = exercises

                # Apply 1RM-based weights
                one_rm_data = await get_user_1rm_data(body.user_id)
                training_intensity = await get_user_training_intensity(body.user_id)
                intensity_overrides = await get_user_intensity_overrides(body.user_id)

                if one_rm_data and exercises:
                    exercises = apply_1rm_weights_to_exercises(
                        exercises, one_rm_data, training_intensity, intensity_overrides
                    )
                    logger.info(f"[Streaming] Applied 1RM-based weights to exercises")

                # CRITICAL SAFETY NET: Validate and cap exercise parameters
                user_age = user.get("age") if user else None
                comeback_status = await get_user_comeback_status(body.user_id)
                is_comeback = comeback_status.get("in_comeback_mode", False)
                if getattr(body, 'skip_comeback', None):
                    is_comeback = False

                if exercises:
                    exercises = validate_and_cap_exercise_parameters(
                        exercises=exercises,
                        fitness_level=fitness_level or "intermediate",
                        age=user_age,
                        is_comeback=is_comeback,
                        difficulty=intensity_preference
                    )
                    # Phase B3: deterministic recovery-aware adjustment. Runs
                    # AFTER validate-and-cap so it composes ONCE on top of the
                    # comeback / age caps. No-op when no recovery signal
                    # applies → output is byte-identical to a pre-B3 run.
                    if isinstance(recovery_signal, dict) and recovery_signal.get("applies"):
                        exercises = apply_recovery_adjustment(
                            exercises, recovery_signal.get("adjustment")
                        )
                    # Density cap: drop exercises beyond ~1 per 7 min (or 1 per 4
                    # min for cardio/HIIT). Validation harness 2026-05-08 found
                    # workouts with 8 ex / 30 min (3.8 min/ex) — too crowded to
                    # execute properly with sets+rest. See validation_utils.py.
                    from api.v1.workouts.validation_utils import (
                        cap_exercise_count_by_density,
                        reorder_exercises_canonically,
                    )
                    _wo_type = (body.workout_type if hasattr(body, "workout_type") else None) or workout_type_override or "strength"
                    exercises = cap_exercise_count_by_density(
                        exercises=exercises,
                        duration_minutes=target_duration or 45,
                        workout_type=_wo_type,
                    )
                    # Reorder to canonical CNS-demand cascade:
                    # plyo → compound → secondary → isolation → core →
                    # static_hold → cardio → stretch (cooldown).
                    # Validation harness 2026-05-08: 11 rows had compound-after-
                    # isolation, 1 started with static hold. This fixes those.
                    exercises = reorder_exercises_canonically(
                        exercises,
                        focus_areas=body.focus_areas,
                        workout_type=_wo_type,
                    )
                    logger.info(f"[Streaming Safety] Validated exercise parameters (fitness={fitness_level}, age={user_age}, comeback={is_comeback}, difficulty={intensity_preference}, density_cap_applied={len(exercises)} exercises for {target_duration}min)")

                # FOCUS AREA VALIDATION
                MIN_EXERCISES_REQUIRED = 3

                focus_areas = body.focus_areas if hasattr(body, 'focus_areas') and body.focus_areas else []

                if focus_areas and len(focus_areas) > 0 and exercises:
                    primary_focus = focus_areas[0]
                    focus_validation = await validate_and_filter_focus_mismatches(
                        exercises=exercises,
                        focus_area=primary_focus,
                        workout_name=workout_name,
                    )

                    missing_groups = focus_validation.get("missing_muscle_groups", [])
                    if missing_groups:
                        friendly = {"legs": "Legs/Glutes", "back": "Back/Pull", "chest_push": "Chest/Shoulders/Push"}
                        missing_names = [friendly.get(g, g) for g in missing_groups]
                        logger.error(
                            f"[Streaming Full Body Validation] Workout '{workout_name}' labeled full_body but MISSING: "
                            f"{', '.join(missing_names)}. Exercises: {[ex.get('name') for ex in exercises]}."
                        )

                    if focus_validation["mismatch_count"] > 0:
                        logger.warning(
                            f"[Streaming Focus Validation] Found {focus_validation['mismatch_count']} mismatched exercises "
                            f"in '{workout_name}' for focus '{primary_focus}'."
                        )

                        valid_exercises = focus_validation["valid_exercises"]

                        if len(valid_exercises) >= MIN_EXERCISES_REQUIRED:
                            logger.info(
                                f"[Streaming Focus Validation] Filtering to {len(valid_exercises)} valid exercises "
                                f"(removed {focus_validation['mismatch_count']} mismatched)"
                            )
                            exercises = valid_exercises
                        else:
                            logger.error(
                                f"[Streaming Focus Validation] CRITICAL: Workout '{workout_name}' has only "
                                f"{len(valid_exercises)} valid exercises for '{primary_focus}' focus "
                                f"(minimum required: {MIN_EXERCISES_REQUIRED}). "
                                f"Keeping all {len(exercises)} exercises to meet minimum."
                            )

                # TERMINAL COMPLETENESS STAGE (WORKOUT_COMPLETENESS_V2) — mirror
                # of the library path. Backfills a thin streaming workout to its
                # floor from the RAG broadening cascade (no reserve on this path).
                # FAIL OPEN: any error keeps the pre-stage list.
                _stream_degraded_reason = None
                from services.workout_completeness import completeness_enabled
                if exercises and completeness_enabled(body.user_id):
                    try:
                        from api.v1.workouts.exercise_target import (
                            target_exercise_count,
                            min_exercise_floor,
                        )
                        from services.workout_completeness import ensure_complete_workout
                        from services.exercise_rag.service import get_exercise_rag_service

                        _ct_target = target_exercise_count(target_duration, fitness_level, _wo_type)
                        _ct_floor = min_exercise_floor(target_duration, fitness_level, _wo_type)
                        exercises, _stream_degraded_reason = await ensure_complete_workout(
                            exercises,
                            target=_ct_target,
                            floor=_ct_floor,
                            focus_area=(focus_areas[0] if focus_areas else (workout_type_override or "full_body")),
                            equipment=equipment if isinstance(equipment, list) else [],
                            fitness_level=fitness_level or "intermediate",
                            goals=goals if isinstance(goals, list) else [],
                            workout_type=_wo_type,
                            reserve_pool=None,
                            avoided_exercises=avoided_exercises or [],
                            avoided_muscles=avoided_muscles,
                            user_id=str(body.user_id),
                            rag_service=get_exercise_rag_service(),
                        )
                    except Exception as _ce:  # noqa: BLE001 — fail open
                        logger.warning(
                            f"[Streaming Completeness] stage raised, keeping pre-stage exercises: {_ce}",
                            exc_info=True,
                        )
                        _stream_degraded_reason = None
                elif len(exercises) < MIN_EXERCISES_REQUIRED:
                    logger.error(
                        f"[Streaming Exercise Count] Workout '{workout_name}' has only {len(exercises)} exercises "
                        f"(minimum required: {MIN_EXERCISES_REQUIRED})."
                    )

                # CRITICAL: Validate set_targets
                user_context = {
                    "user_id": body.user_id,
                    "fitness_level": fitness_level,
                    "difficulty": difficulty,
                    "goals": goals if isinstance(goals, list) else [],
                    "equipment": equipment if isinstance(equipment, list) else [],
                }
                exercises = validate_set_targets_strict(exercises, user_context)

                # ── TERMINAL INJURY-SAFETY GUARD (injury-2026-06) ──────────────
                # The streaming path had NO injury gate; Phase-0 testing showed it
                # shipped contraindicated movements (deadlifts→lower_back,
                # squats→knees, overhead press→shoulders) in 30/50 scenarios.
                # This drops any index-confirmed-unsafe exercise for an active
                # joint injury and backfills a vetted-safe replacement, so the
                # user gets a full, injury-safe workout — never an unsafe one and
                # never a thinned one. Fail-open (keeps the list on any error).
                if exercises and active_injuries:
                    from services.exercise_rag.injury_guard import enforce_injury_safety
                    exercises, _inj_dropped, _inj_added = await enforce_injury_safety(
                        exercises,
                        active_injuries,
                        equipment=equipment if isinstance(equipment, list) else [],
                        focus_areas=(body.focus_areas or []),
                        difficulty_ceiling=(fitness_level or "beginner"),
                        user_id=str(body.user_id),
                    )
                    if _inj_dropped:
                        logger.info(
                            f"🩹 [Streaming InjuryGuard] dropped {len(_inj_dropped)} "
                            f"unsafe → added {len(_inj_added)} safe for {active_injuries}"
                        )

            except json.JSONDecodeError as e:
                logger.error(f"Failed to parse streaming response: {e}", exc_info=True)
                logger.error(f"Raw accumulated text ({len(accumulated_text)} chars): {accumulated_text[:1000]}", exc_info=True)
                logger.error(f"Cleaned content for parsing ({len(content)} chars): {content[:1000]}", exc_info=True)

                if content and (content.rstrip().endswith((',', '{', '[', ':')) or
                               not content.rstrip().endswith(('}', ']'))):
                    logger.error(f"Detected truncated response - Gemini stream ended prematurely", exc_info=True)
                    yield f"event: error\ndata: {json.dumps({'error': 'Workout generation was interrupted. Please try again.', 'raw_length': len(accumulated_text), 'truncated': True})}\n\n"
                else:
                    yield f"event: error\ndata: {json.dumps({'error': 'Failed to parse workout data', 'raw_length': len(accumulated_text)})}\n\n"
                return

            # Determine scheduled date
            _stream_tz = resolve_timezone(request, db, body.user_id)
            if body.scheduled_date:
                try:
                    datetime.strptime(body.scheduled_date, "%Y-%m-%d")
                    scheduled_date_str = target_date_to_utc_iso(body.scheduled_date, _stream_tz)
                    logger.info(f"[Streaming] Using provided scheduled_date: {body.scheduled_date} (tz={_stream_tz})")
                except ValueError:
                    logger.warning(f"Invalid scheduled_date format: {body.scheduled_date}, using today", exc_info=True)
                    scheduled_date_str = target_date_to_utc_iso(get_user_today(_stream_tz), _stream_tz)
            else:
                scheduled_date_str = target_date_to_utc_iso(get_user_today(_stream_tz), _stream_tz)

            # Last-mile type coercion against focus_areas (validation harness
            # 2026-05-09 found 68 rows with focus∈{cardio,endurance,hiit,
            # mobility} but type=strength persisted; existing overrides only
            # caught exact "cardio"/"mobility" focus strings).
            workout_type = coerce_workout_type_from_focus(
                workout_type,
                body.focus_areas,
                goals if isinstance(goals, list) else None,
            )

            # Compute estimated calories using MET-based formula
            _user_weight_kg = float(user.get("weight_kg") or user.get("weight") or 70) if user else 70.0
            _user_weight_kg = max(30.0, min(_user_weight_kg, 250.0))
            _effective_duration = estimated_duration or target_duration
            _met = _estimate_workout_met(exercises, workout_type, difficulty)
            _estimated_calories = round(_met * _user_weight_kg * (_effective_duration / 60.0))

            # Save to database
            workout_db_data = {
                "user_id": body.user_id,
                "gym_profile_id": gym_profile_id,
                "name": workout_name,
                "type": workout_type,
                "difficulty": difficulty,
                "description": workout_description,
                "scheduled_date": scheduled_date_str,
                "exercises_json": exercises,
                "duration_minutes": target_duration,
                "duration_minutes_min": target_duration_min,
                "duration_minutes_max": target_duration_max,
                "estimated_duration_minutes": estimated_duration,
                "estimated_calories": _estimated_calories,
                "generation_method": "ai",
                "generation_source": "streaming_generation",
                "is_degraded": bool(_stream_degraded_reason),
                "degraded_reason": _stream_degraded_reason,
            }

            # Replace today's canonical workout if one already exists for the
            # same (user_id, scheduled_date). Migration 2048's partial unique
            # index `workouts_one_current_per_user_day` blocks the insert
            # otherwise; production prior bug was a 23505 duplicate-key crash
            # on every Regenerate/Replace tap. Mark the prior canonical row
            # is_current=FALSE BEFORE inserting so the index admits the new
            # row, mirroring the SCD2 supersede pattern used elsewhere.
            sd_str = scheduled_date_str[:10] if scheduled_date_str else None
            if sd_str:
                try:
                    now_iso = datetime.utcnow().isoformat()
                    await asyncio.to_thread(db.client.table("workouts").update({
                        "is_current": False,
                        "valid_to": now_iso,
                    }).eq("user_id", body.user_id).gte(
                        "scheduled_date", f"{sd_str}T00:00:00+00:00"
                    ).lte(
                        "scheduled_date", f"{sd_str}T23:59:59+00:00"
                    ).eq("is_current", True).neq("status", "cancelled").execute)
                except Exception as supersede_err:
                    logger.warning(
                        f"[Streaming] supersede prior canonical failed for user "
                        f"{body.user_id} on {sd_str}: {supersede_err}",
                        exc_info=True,
                    )

            # Force is_current=True so the today endpoint's
            # `is_current.eq.true` filter finds the new row even if the
            # column default ever changes. Defensive — observed production
            # case where /today returned needs_generation=true on every
            # poll despite multiple successful generations (see Sentry
            # 2026-05-10: 5 cycles of "Workout ready!" with zero rows
            # appearing in the user's workouts table).
            workout_db_data["is_current"] = True

            try:
                created = db.create_workout(workout_db_data)
            except Exception as insert_err:
                if 'PGRST204' in str(insert_err) and 'estimated_calories' in str(insert_err):
                    logger.warning("[Streaming] estimated_calories column not in schema cache, retrying without it", exc_info=True)
                    workout_db_data.pop('estimated_calories', None)
                    created = db.create_workout(workout_db_data)
                else:
                    logger.error(f"[Streaming] create_workout INSERT FAILED: {insert_err}", exc_info=True)
                    raise

            if not created or not created.get("id"):
                logger.error(
                    f"[Streaming] create_workout returned empty result for user "
                    f"{body.user_id}, scheduled_date={scheduled_date_str}, "
                    f"gym_profile_id={gym_profile_id}. Workout NOT persisted."
                )
                yield f"event: error\ndata: {json.dumps({'error': 'Workout could not be saved. Please try again.'})}\n\n"
                return

            total_time_ms = (datetime.now() - start_time).total_seconds() * 1000

            logger.info(f"[Streaming] Workout {created.get('id')} INSERTED: {len(exercises)} exercises in {total_time_ms:.0f}ms, gym_profile_id={gym_profile_id}, scheduled_date={scheduled_date_str}")

            # Invalidate the /today cache so the next poll surfaces the new
            # workout instead of returning the stale needs_generation=true
            # response that triggered this generation in the first place.
            # Without this, the home screen loops: needs_generation→generate
            # →cache-stale→needs_generation→…
            try:
                from .today import invalidate_today_workout_cache
                _sd_for_invalidate = scheduled_date_str[:10] if scheduled_date_str else None
                # Invalidate for both the active profile AND null profile so
                # the cached key from any /today call permutation gets cleared.
                await invalidate_today_workout_cache(body.user_id, gym_profile_id, _sd_for_invalidate)
                if gym_profile_id:
                    await invalidate_today_workout_cache(body.user_id, None, _sd_for_invalidate)
            except Exception as cache_err:
                logger.warning(f"[Streaming] Today cache invalidation failed: {cache_err}", exc_info=True)

            log_workout_change(
                workout_id=created['id'],
                user_id=body.user_id,
                change_type="generated",
                change_source="streaming_generation",
                new_value={"name": workout_name, "exercises_count": len(exercises)}
            )

            generated_workout = row_to_workout(created)

            # Index to RAG asynchronously (don't wait). Attach a done-callback
            # that swallows the result so an exception inside the coroutine
            # doesn't bubble up to anyio's TaskGroup as an "unhandled errors"
            # crash when the SSE client has already disconnected. CancelledError
            # is silently absorbed (expected on disconnect); other errors are
            # logged at WARNING — RAG indexing is a nice-to-have, not critical
            # to the workout itself.
            _rag_task = asyncio.create_task(index_workout_to_rag(generated_workout))

            def _swallow_rag_error(t: asyncio.Task) -> None:
                if t.cancelled():
                    return
                exc = t.exception()
                if exc is not None:
                    logger.warning(
                        f"[generation_streaming] RAG indexing failed (non-fatal): {exc}"
                    )

            _rag_task.add_done_callback(_swallow_rag_error)

            exercises_list = json.loads(generated_workout.exercises_json) if generated_workout.exercises_json else []

            workout_response = {
                "id": generated_workout.id,
                "user_id": generated_workout.user_id,
                "name": generated_workout.name,
                "type": generated_workout.type,
                "difficulty": generated_workout.difficulty,
                "description": generated_workout.description,
                "scheduled_date": generated_workout.scheduled_date.isoformat() if generated_workout.scheduled_date else None,
                "exercises": exercises_list,
                "exercises_json": generated_workout.exercises_json,
                # Force duration_minutes to the resolved target (request's
                # authoritative value) — defensive against internal drift seen
                # in validation harness 2026-05-08 (idx 6: req=30min, response=60min;
                # idx 8: req=60min, response=30min; idx 11: req=20min, response=45min).
                # The DB row already stores target_duration but downstream readers
                # were sometimes seeing estimated_duration_minutes — pin it here.
                "duration_minutes": target_duration or generated_workout.duration_minutes,
                "total_time_ms": total_time_ms,
                "chunk_count": chunk_count,
                "comeback_detected": comeback_status.get("in_comeback_mode", False),
                "days_since_last_workout": comeback_status.get("days_since_last_workout"),
            }

            # Track premium gate usage after successful streaming generation
            try:
                from core.premium_gate import track_premium_usage
                await track_premium_usage(body.user_id, "ai_workout_generation", _user_tz)
            except Exception as usage_err:
                logger.warning(f"Failed to track workout generation usage: {usage_err}", exc_info=True)

            yield f"event: done\ndata: {json.dumps(workout_response)}\n\n"

        except asyncio.CancelledError:
            # Client disconnected mid-stream — log and re-raise so the task
            # is cleanly cancelled. Do NOT yield (connection is gone).
            logger.info(f"[generate-stream] Client disconnected for user {body.user_id}")
            raise
        except Exception as e:
            logger.error(f"Streaming workout generation failed: {e}", exc_info=True)
            yield f"event: error\ndata: {json.dumps({'error': str(e)})}\n\n"
        finally:
            # Clear the recent-call short-circuit so a legitimate retry after
            # success/failure can fire immediately, instead of being held off
            # for the full 30s TTL.
            try:
                await _genstream_recent_cache.delete(_recent_key)
            except Exception:
                pass

    return StreamingResponse(
        generate_sse(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",  # Disable nginx buffering
        }
    )
