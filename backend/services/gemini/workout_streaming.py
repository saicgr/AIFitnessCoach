"""
Gemini Service Workout Streaming - Streaming workout generation and cached variants.
"""
import asyncio
import json
import logging
import time
import re
import hashlib
from typing import Any, List, Dict, Optional
from datetime import datetime

from google.genai import types
from core.config import get_settings
from core.anonymize import age_to_bracket
from core.weight_utils import kg_to_lbs_gym
from models.gemini_schemas import GeneratedWorkoutResponse
from services.split_descriptions import SPLIT_DESCRIPTIONS, get_split_context
from services.gemini.constants import (
    client, cost_tracker, _log_token_usage, _gemini_semaphore, _is_transient_gemini_error, settings,
)
from services.gemini.utils import (
    _sanitize_for_prompt, safe_join_list,
    _build_equipment_usage_rule, validate_set_targets_strict,
)

logger = logging.getLogger("gemini")


class WorkoutStreamingMixin:
    """Mixin providing streaming workout generation methods for GeminiService."""

    async def generate_workout_plan_streaming(
        self,
        fitness_level: str,
        goals: List[str],
        equipment: List[str],
        duration_minutes: int = 45,
        duration_minutes_min: Optional[int] = None,
        duration_minutes_max: Optional[int] = None,
        focus_areas: Optional[List[str]] = None,
        avoid_name_words: Optional[List[str]] = None,
        workout_date: Optional[str] = None,
        age: Optional[int] = None,
        activity_level: Optional[str] = None,
        intensity_preference: Optional[str] = None,
        custom_prompt_override: Optional[str] = None,
        avoided_exercises: Optional[List[str]] = None,
        avoided_muscles: Optional[Dict] = None,
        staple_exercises: Optional[List[str]] = None,
        progression_philosophy: Optional[str] = None,
        exercise_count: int = 6,
        # Coach personality parameters for personalized workout naming
        coach_style: Optional[str] = None,
        coach_tone: Optional[str] = None,
        scheduled_date: Optional[str] = None,
        user_dob: Optional[str] = None,
        user_id: Optional[str] = None,
        strength_history: Optional[Dict] = None,
        training_split: Optional[str] = None,
        workout_days: Optional[List[int]] = None,
        # Per-day overrides — added 2026-05-27. Source:
        # user.preferences.workout_day_overrides JSONB. See
        # _build_per_day_overrides_prompt for the format the prompt expects.
        workout_day_overrides: Optional[Dict[int, Dict[str, Any]]] = None,
        workout_weight_unit: Optional[str] = None,
        # RAG-first refactor (2026-05-08): if provided, constrains Gemini to
        # use ONLY these pre-filtered library exercises (no hallucinations).
        library_exercises: Optional[List[Dict]] = None,
    ):
        """
        Generate a workout plan using streaming for faster perceived response.

        Yields chunks of JSON as they're generated, allowing the client to
        display exercises incrementally.

        Args:
            custom_prompt_override: If provided, use this prompt instead of
                                    building the default workout prompt.
            progression_philosophy: Optional progression philosophy prompt for leverage-based progressions.
            strength_history: Optional dict of user's exercise history for progressive overload.
            training_split: Optional training split identifier for split-aware generation.
            workout_days: Optional user's workout day indices for schedule mapping.

        Yields:
            str: JSON chunks as they arrive from Gemini
        """
        # If custom prompt provided, use it directly
        if custom_prompt_override:
            prompt = custom_prompt_override
            logger.info(f"[Streaming] Using custom prompt override for {fitness_level} user")
        else:
            # Use intensity_preference if provided, otherwise derive from fitness_level
            if intensity_preference:
                difficulty = intensity_preference
            else:
                difficulty = "easy" if fitness_level == "beginner" else ("hard" if fitness_level == "advanced" else "medium")

            avoid_instruction = ""
            if avoid_name_words and len(avoid_name_words) > 0:
                avoid_instruction = f"\n\n⚠️ Do NOT use these words in the workout name: {', '.join(avoid_name_words)}"

            holiday_theme = self._get_holiday_theme(workout_date, user_dob=user_dob)
            holiday_instruction = f"\n\n{holiday_theme}" if holiday_theme else ""

            # Import senior-specific prompt additions
            from services.adaptive_workout_service import get_senior_workout_prompt_additions

            age_activity_context = ""
            senior_instruction = ""  # For seniors 60+, this adds critical limits
            if age:
                if age < 30:
                    age_activity_context += f"\n- Age: {age} (young adult, max 25 reps)"
                elif age < 45:
                    age_activity_context += f"\n- Age: {age} (adult, max 20 reps)"
                elif age < 60:
                    age_activity_context += f"\n- Age: {age} (middle-aged - joint-friendly, max 16 reps)"
                else:
                    # Senior users (60+) - get detailed safety instructions
                    senior_prompt_data = get_senior_workout_prompt_additions(age)
                    if senior_prompt_data:
                        age_activity_context += f"\n- Age: {age} ({senior_prompt_data['age_bracket']} - REDUCED INTENSITY)"
                        senior_instruction = f"\n\n🧓 SENIOR SAFETY (age {age}): Max {senior_prompt_data['max_reps']} reps, Max {senior_prompt_data['max_sets']} sets, {senior_prompt_data['extra_rest_percent']}% more rest. AVOID high-impact/explosive moves."
                    else:
                        age_activity_context += f"\n- Age: {age} (senior - low-impact, max 12 reps)"

            if activity_level:
                activity_descriptions = {
                    'sedentary': 'sedentary (start slow)',
                    'lightly_active': 'lightly active (moderate intensity)',
                    'moderately_active': 'moderately active (challenging workouts)',
                    'very_active': 'very active (high intensity)'
                }
                activity_desc = activity_descriptions.get(activity_level, activity_level)
                age_activity_context += f"\n- Activity Level: {activity_desc}"

            # Build preference constraints for streaming
            preference_constraints = ""

            if avoided_exercises and len(avoided_exercises) > 0:
                logger.info(f"🚫 [Streaming] User has {len(avoided_exercises)} avoided exercises")
                preference_constraints += f"\n\n🚫 EXERCISES TO AVOID (CRITICAL - DO NOT INCLUDE): {', '.join(avoided_exercises[:10])}"

            if avoided_muscles:
                avoid_completely = avoided_muscles.get("avoid", [])
                reduce_usage = avoided_muscles.get("reduce", [])
                if avoid_completely:
                    logger.info(f"🚫 [Streaming] User avoiding muscles: {avoid_completely}")
                    preference_constraints += f"\n🚫 MUSCLES TO AVOID (injury/preference): {', '.join(avoid_completely)}"
                if reduce_usage:
                    preference_constraints += f"\n⚠️ MUSCLES TO MINIMIZE: {', '.join(reduce_usage)}"

            if staple_exercises and len(staple_exercises) > 0:
                logger.info(f"⭐ [Streaming] User has {len(staple_exercises)} MANDATORY staple exercises for this day")
                preference_constraints += f"\n⭐ MANDATORY STAPLE EXERCISES for this workout - MUST include ALL: {', '.join(staple_exercises)}"

            # Add progression philosophy if provided
            progression_instruction = ""
            if progression_philosophy and progression_philosophy.strip():
                logger.info(f"[Streaming] Including progression philosophy for leverage-based progressions")
                progression_instruction = progression_philosophy

            # Add strength history for progressive overload
            strength_history_instruction = ""
            if strength_history:
                history_summary = self._format_strength_history(strength_history, workout_weight_unit=workout_weight_unit or 'kg')
                if history_summary:
                    strength_history_instruction = f"""

## PROGRESSIVE OVERLOAD (CRITICAL)
You MUST reference the user's previous performance data below when setting weights in set_targets.
For each exercise where history is available, set target_weight_kg that follows progressive overload:
- If user handled the weight comfortably (low RPE): increase by smallest increment (2.5kg barbell, 2kg dumbbell)
- If user struggled (high RPE): keep same weight but adjust reps
- Do NOT ignore previous weights and generate from scratch.

STRENGTH HISTORY:
{history_summary}"""
                    logger.info(f"[Streaming] Including strength history for {len(strength_history)} exercises")

            # Build duration text - use range if both min and max provided
            if duration_minutes_min and duration_minutes_max and duration_minutes_min != duration_minutes_max:
                duration_text = f"{duration_minutes_min}-{duration_minutes_max}"
            else:
                duration_text = str(duration_minutes)

            # Build coach-personalized naming context
            # Use scheduled_date if provided, otherwise fall back to workout_date
            naming_date = scheduled_date or workout_date
            naming_context = self._build_coach_naming_context(
                coach_style=coach_style,
                coach_tone=coach_tone,
                workout_date=naming_date,
            )
            logger.info(f"🎨 [Streaming] Coach naming context: style={coach_style}, tone={coach_tone}, date={naming_date}")

            # Build training split context for streaming
            training_split_instruction = ""
            if training_split:
                split_context = get_split_context(training_split, workout_days=workout_days)
                training_split_instruction = f"""

📊 TRAINING SPLIT CONTEXT (Research-Backed):
{split_context}

Use this split information to guide exercise selection and workout structure."""

            # Per-day overrides — focus/duration/intensity per weekday.
            # Added 2026-05-27. Source: user.preferences.workout_day_overrides
            # JSONB. See _build_per_day_overrides_prompt for the format.
            per_day_overrides_instruction = ""
            if workout_day_overrides:
                from services.gemini.workout_generation_helpers import (
                    _build_per_day_overrides_prompt,
                )
                per_day_overrides_instruction = _build_per_day_overrides_prompt(
                    workout_day_overrides, workout_days or []
                )

            # Per-focus muscle whitelist injection. Production focus_validation
            # repeatedly logs mismatches like "Hamstrings does not match glutes
            # focus", "upper back does not match shoulders focus", etc. The
            # post-hoc validator filters them out which then under-fills the
            # workout. Inject the canonical muscle whitelist directly into the
            # prompt so Gemini selects on-target exercises in the first place.
            focus_muscle_constraint = ""
            if focus_areas:
                from api.v1.workouts.focus_validation_utils import FOCUS_AREA_MUSCLES
                _whitelists = []
                for _f in focus_areas:
                    _key = (_f or "").strip().lower()
                    _muscles = FOCUS_AREA_MUSCLES.get(_key)
                    if _muscles:
                        _whitelists.append(
                            f"  - {_f}: ONLY exercises whose primary muscle is one of "
                            f"[{', '.join(_muscles[:6])}]"
                        )
                if _whitelists:
                    focus_muscle_constraint = (
                        "\n\n🎯 FOCUS-MUSCLE WHITELIST (STRICT - validator will reject mismatches):\n"
                        + "\n".join(_whitelists)
                        + "\nDo NOT include exercises whose primary muscle falls outside the whitelist. "
                        "Full-body workouts MUST include at least one Legs/Glutes exercise."
                    )

            # RAG-first: if library_exercises provided, build the
            # "Available Exercises" block and add a hard constraint to use ONLY
            # those names. Mirrors generate_workout_from_library pattern in
            # workout_generation_helpers_part2.py:289-336.
            library_block = ""
            library_constraint = ""
            if library_exercises:
                # Cap at 50 to keep prompt size manageable (~2KB block).
                _capped = library_exercises[:50]
                exercise_list_str = "\n".join([
                    f"- {ex.get('name','Unknown')}: targets "
                    f"{ex.get('muscle_group','unknown')}, equipment: "
                    f"{ex.get('equipment','bodyweight')}"
                    for ex in _capped
                ])
                library_block = (
                    f"\n\n📚 AVAILABLE EXERCISES (pre-filtered from library — "
                    f"use EXACTLY these {len(_capped)} names, no inventions, "
                    f"no substitutions):\n{exercise_list_str}\n"
                )
                library_constraint = (
                    "\n\n🚨 CRITICAL: Every exercise's `name` MUST match EXACTLY "
                    "one of the names in the AVAILABLE EXERCISES list above. "
                    "Do NOT invent exercise names. Do NOT modify or rephrase. "
                    "Pick the most appropriate ones and structure them into the "
                    "workout. If you cannot find suitable exercises, return "
                    "fewer exercises rather than inventing new ones."
                )

            prompt = f"""Generate a {duration_text}-minute workout for:
- Fitness Level: {fitness_level}
- Goals: {safe_join_list(goals, 'General fitness')}
- Equipment: {safe_join_list(equipment, 'Bodyweight only')}
- Focus: {safe_join_list(focus_areas, 'Full body')}{focus_muscle_constraint}{age_activity_context}{training_split_instruction}{per_day_overrides_instruction}{preference_constraints}{library_block}{library_constraint}

Return ONLY valid JSON (no markdown):
{{
  "name": "{naming_context}",
  "type": "strength",
  "difficulty": "{difficulty}",
  "description": "1-2 sentence explanation of the workout's training logic, e.g. 'This upper body session starts with compound pulls, transitions to pressing movements, and finishes with isolation work for biceps and triceps.'",
  "duration_minutes": {duration_minutes},
  "duration_minutes_min": {duration_minutes_min or 'null'},
  "duration_minutes_max": {duration_minutes_max or 'null'},
  "estimated_duration_minutes": null,
  "target_muscles": ["muscle1", "muscle2"],
  "exercises": [
    {{
      "name": "Exercise Name",
      "sets": 4,
      "reps": 10,
      "rest_seconds": 60,
      "equipment": "equipment used",
      "muscle_group": "primary muscle",
      "notes": "Form tips",
      "set_targets": [
        {{"set_number": 1, "set_type": "warmup", "target_reps": 12, "target_weight_kg": 10, "target_rpe": 5}},
        {{"set_number": 2, "set_type": "working", "target_reps": 10, "target_weight_kg": 20, "target_rpe": 7}},
        {{"set_number": 3, "set_type": "working", "target_reps": 10, "target_weight_kg": 20, "target_rpe": 7}},
        {{"set_number": 4, "set_type": "working", "target_reps": 10, "target_weight_kg": 20, "target_rpe": 8}}
      ]
    }}
  ],
  "notes": "Overall tips"
}}

⏱️ DURATION CALCULATION (MANDATORY):
Calculate "estimated_duration_minutes" = SUM of (sets × (reps × 3s + rest)) / 60 + (exercises × 30s) / 60
MUST be ≤ duration_minutes_max if provided. Adjust exercises/sets to fit time constraint!

CRITICAL: Every exercise MUST include "set_targets" array with set_number, set_type (warmup/working/drop/failure/amrap), target_reps, target_weight_kg, and target_rpe for each set.
MINIMUM SETS: Each exercise MUST have at least 3 working sets (set_type "working", "drop", "failure", or "amrap"). Warmup sets do NOT count toward this minimum. Typically generate 1 warmup + 3 working = 4 total sets per exercise.

PER-SET REP CEILINGS (MANDATORY):
- Compound exercises (squat, deadlift, press, row, pull-up, lunge, dip, pulldown): MAX 12 target_reps per set
- Isolation exercises (curl, extension, raise, fly): MAX 15 target_reps per set
- This applies to EVERY set in set_targets including pyramid first sets

Include exactly {exercise_count} exercises for {fitness_level} level using only: {safe_join_list(equipment, 'bodyweight')}

🚨🚨 ABSOLUTE REQUIREMENT - EQUIPMENT USAGE 🚨🚨
If user has gym equipment (full_gym, barbell, dumbbells, cable_machine, machines):
- AT LEAST 4-5 exercises MUST use that equipment (NOT bodyweight!)
- Maximum 1-2 bodyweight exercises allowed
- For beginners with gym: USE machines & dumbbells (Leg Press, Dumbbell Press, Cable Rows) - NOT just push-ups/squats!
- NEVER generate mostly bodyweight when gym equipment is available!
{senior_instruction}{holiday_instruction}{avoid_instruction}{progression_instruction}{strength_history_instruction}"""

            logger.info(f"[Streaming] Starting workout generation for {fitness_level} user")

        try:
            logger.info(f"[Streaming] Calling Gemini API with model={self.model}, prompt length={len(prompt)}")
            _streaming_max_retries = 3
            _streaming_delays = [2.0, 5.0, 10.0]
            # Per-stage timeouts: stream-create hangs are usually fast-fail
            # (auth, prompt rejection); per-chunk hangs are mid-stream socket
            # silences. asyncio.wait_for raises asyncio.TimeoutError which
            # _is_transient_gemini_error treats as retryable, so the existing
            # retry loop handles ReadTimeout transparently (was Sentry
            # PYTHON-FASTAPI-31/32: "ReadTimeout: The read operation timed out"
            # surfacing as a 500 instead of a transparent retry).
            # Two-tier timeouts:
            #   stream-create: 45s — Vertex stream-create handshake under load.
            #   chunk 1: 150s — full inference cost (Vertex DEADLINE_EXCEEDED
            #     occurs at ~120s server-side; we give ourselves a hair more
            #     so the SERVER's error reaches us before our client timeout).
            #   chunk 2+: 30s — once inference done, chunks stream in ms.
            # My earlier blanket 45s per-chunk fired before Vertex returned
            # chunk 1, surfacing PYTHON-FASTAPI-37 "TimeoutError: Gemini stream
            # stalled at chunk 1" as a 500 even though Vertex was still working.
            _STREAM_CREATE_TIMEOUT_S = 45.0
            _FIRST_CHUNK_TIMEOUT_S = 150.0
            _SUBSEQUENT_CHUNK_TIMEOUT_S = 30.0
            stream = None
            for _attempt in range(_streaming_max_retries + 1):
                try:
                    async with _gemini_semaphore(user_id=user_id):
                        stream = await asyncio.wait_for(
                            client.aio.models.generate_content_stream(
                                model=self.model,
                                contents=prompt,
                                config=types.GenerateContentConfig(
                                    response_mime_type="application/json",
                                    response_schema=GeneratedWorkoutResponse,
                                    temperature=0.85,  # bumped from 0.7 for variety (harness 2026-05-08)
                                    max_output_tokens=16384  # Increased to prevent truncation with detailed workouts
                                ),
                            ),
                            timeout=_STREAM_CREATE_TIMEOUT_S,
                        )
                    break
                except Exception as _e:
                    if _is_transient_gemini_error(_e) and _attempt < _streaming_max_retries:
                        import random as _rand
                        _delay = _streaming_delays[min(_attempt, len(_streaming_delays) - 1)] + _rand.uniform(0, 1)
                        logger.warning(f"[Streaming] Attempt {_attempt + 1}/{_streaming_max_retries + 1} failed (transient), retrying in {_delay:.1f}s: {_e}")
                        await asyncio.sleep(_delay)
                        continue
                    raise

            if stream is None:
                logger.error(f"❌ [Streaming] Gemini returned None stream - API may be unavailable or prompt rejected")
                raise ValueError("Gemini streaming returned None - check API key and prompt")

            logger.info(f"[Streaming] Stream created successfully, type={type(stream).__name__}")

            chunk_count = 0
            total_chars = 0
            # Per-chunk timeout: if a single chunk takes >_PER_CHUNK_TIMEOUT_S,
            # abort the stream so caller can retry. async-for doesn't support
            # a per-iteration timeout natively, so we wrap the iterator in an
            # async generator that applies asyncio.wait_for per __anext__.
            async def _with_chunk_timeout(_src, _first_s: float, _rest_s: float):
                """Two-tier timeout: first chunk gets [_first_s] (full inference
                cost), subsequent chunks get [_rest_s] (just streaming bytes).
                """
                _it = _src.__aiter__()
                _idx = 0
                while True:
                    _budget = _first_s if _idx == 0 else _rest_s
                    try:
                        _val = await asyncio.wait_for(
                            _it.__anext__(),
                            timeout=_budget,
                        )
                    except StopAsyncIteration:
                        return
                    except asyncio.TimeoutError as _te:
                        logger.warning(
                            f"⚠️ [Streaming] Chunk {_idx + 1} timed out after "
                            f"{_budget}s — aborting stream so caller can retry"
                        )
                        raise TimeoutError(
                            f"Gemini stream stalled at chunk {_idx + 1}"
                        ) from _te
                    _idx += 1
                    yield _val

            # Mid-stream 429 / RESOURCE_EXHAUSTED handling: Vertex regularly
            # bounces a request after the stream handshake succeeds (logged as
            # "Stream error after N chunks, M chars: 429 RESOURCE_EXHAUSTED").
            # When this happens BEFORE we've yielded text downstream, restart
            # the entire generation with backoff so the user sees a complete
            # workout instead of a half-built one + 500.
            _midstream_attempt = 0
            _MAX_MIDSTREAM_RESTARTS = 2
            while True:
                try:
                    async for chunk in _with_chunk_timeout(stream, _FIRST_CHUNK_TIMEOUT_S, _SUBSEQUENT_CHUNK_TIMEOUT_S):
                        chunk_count += 1
                        logger.debug(f"[Streaming] Received chunk {chunk_count}, type={type(chunk).__name__}")

                        # Check for blocked content or safety issues
                        if hasattr(chunk, 'candidates') and chunk.candidates:
                            candidate = chunk.candidates[0]
                            if hasattr(candidate, 'finish_reason') and candidate.finish_reason:
                                finish_reason = str(candidate.finish_reason)
                                if finish_reason in ['MAX_TOKENS', 'FinishReason.MAX_TOKENS', '2']:
                                    logger.warning(f"⚠️ [Streaming] Response truncated (MAX_TOKENS) at {total_chars} chars - increase max_output_tokens")
                                elif finish_reason not in ['STOP', 'FinishReason.STOP', '1']:
                                    logger.warning(f"⚠️ [Streaming] Unexpected finish reason: {finish_reason}")
                            if hasattr(candidate, 'safety_ratings') and candidate.safety_ratings:
                                for rating in candidate.safety_ratings:
                                    if hasattr(rating, 'blocked') and rating.blocked:
                                        logger.error(f"🚫 [Streaming] Content blocked by safety filter: {rating}")

                        if chunk.text:
                            total_chars += len(chunk.text)
                            yield chunk.text
                    break  # stream finished cleanly
                except Exception as _midstream_err:
                    _can_restart = (
                        total_chars == 0
                        and _midstream_attempt < _MAX_MIDSTREAM_RESTARTS
                        and _is_transient_gemini_error(_midstream_err)
                    )
                    if not _can_restart:
                        raise
                    _midstream_attempt += 1
                    import random as _rand
                    _delay = _streaming_delays[min(_midstream_attempt - 1, len(_streaming_delays) - 1)] + _rand.uniform(0, 1)
                    logger.warning(
                        f"⚠️ [Streaming] Mid-stream transient error "
                        f"(attempt {_midstream_attempt}/{_MAX_MIDSTREAM_RESTARTS}, "
                        f"chunks={chunk_count}, chars={total_chars}): {_midstream_err}. "
                        f"Restarting stream in {_delay:.1f}s."
                    )
                    await asyncio.sleep(_delay)
                    chunk_count = 0
                    async with _gemini_semaphore(user_id=user_id):
                        stream = await asyncio.wait_for(
                            client.aio.models.generate_content_stream(
                                model=self.model,
                                contents=prompt,
                                config=types.GenerateContentConfig(
                                    response_mime_type="application/json",
                                    response_schema=GeneratedWorkoutResponse,
                                    temperature=0.85,
                                    max_output_tokens=16384,
                                ),
                            ),
                            timeout=_STREAM_CREATE_TIMEOUT_S,
                        )

            logger.info(f"✅ [Gemini Streaming] Complete: {chunk_count} chunks, {total_chars} chars")
            if total_chars < 500:
                logger.warning(f"⚠️ [Gemini Streaming] Response seems short ({total_chars} chars) - may be incomplete")

        except Exception as e:
            import traceback
            logger.error(f"Streaming workout generation failed: {e}", exc_info=True)
            logger.error(f"Traceback: {traceback.format_exc()}", exc_info=True)
            raise

    async def generate_workout_plan_streaming_cached(
        self,
        fitness_level: str,
        goals: List[str],
        equipment: List[str],
        duration_minutes: int = 45,
        duration_minutes_min: Optional[int] = None,
        duration_minutes_max: Optional[int] = None,
        focus_areas: Optional[List[str]] = None,
        avoid_name_words: Optional[List[str]] = None,
        workout_date: Optional[str] = None,
        age: Optional[int] = None,
        activity_level: Optional[str] = None,
        intensity_preference: Optional[str] = None,
        avoided_exercises: Optional[List[str]] = None,
        avoided_muscles: Optional[Dict] = None,
        staple_exercises: Optional[List[str]] = None,
        progression_philosophy: Optional[str] = None,
        exercise_count: int = 6,
        coach_style: Optional[str] = None,
        coach_tone: Optional[str] = None,
        scheduled_date: Optional[str] = None,
        strength_history: Optional[Dict] = None,
        user_dob: Optional[str] = None,
        user_id: Optional[str] = None,
        training_split: Optional[str] = None,
        workout_days: Optional[List[int]] = None,
        # Per-day overrides — added 2026-05-27. Source:
        # user.preferences.workout_day_overrides JSONB. See
        # _build_per_day_overrides_prompt for the format the prompt expects.
        workout_day_overrides: Optional[Dict[int, Dict[str, Any]]] = None,
        workout_weight_unit: Optional[str] = None,
        library_exercises: Optional[List[Dict]] = None,  # RAG-first
    ):
        """
        FAST workout generation using Gemini context caching.

        This method caches the static workout generation context (rules, examples,
        system instructions) and only sends user-specific data per request.

        Benefits:
        - 5-10x faster generation (~5-8s vs ~28s)
        - 75% cost reduction on cached input tokens
        - Same AI quality and output

        Falls back to non-cached generation if caching fails.

        Args:
            Same as generate_workout_plan_streaming, plus:
            strength_history: Optional dict of user's exercise history for weight recommendations

        Yields:
            str: JSON chunks as they arrive from Gemini
        """
        start_time = datetime.now()

        # Try to get or create cache
        cache_name = await self._get_or_create_workout_cache()

        if not cache_name:
            # Fallback to non-cached generation
            logger.warning("[CachedStreaming] Cache unavailable, falling back to non-cached generation")
            async for chunk in self.generate_workout_plan_streaming(
                fitness_level=fitness_level,
                goals=goals,
                equipment=equipment,
                duration_minutes=duration_minutes,
                duration_minutes_min=duration_minutes_min,
                duration_minutes_max=duration_minutes_max,
                focus_areas=focus_areas,
                avoid_name_words=avoid_name_words,
                workout_date=workout_date,
                age=age,
                activity_level=activity_level,
                intensity_preference=intensity_preference,
                avoided_exercises=avoided_exercises,
                avoided_muscles=avoided_muscles,
                staple_exercises=staple_exercises,
                progression_philosophy=progression_philosophy,
                exercise_count=exercise_count,
                coach_style=coach_style,
                coach_tone=coach_tone,
                scheduled_date=scheduled_date,
                user_dob=user_dob,
                training_split=training_split,
                workout_days=workout_days,
                workout_weight_unit=workout_weight_unit,
            ):
                yield chunk
            return

        # Build ONLY user-specific prompt (much smaller than full prompt)
        user_prompt = self._build_cached_user_prompt(
            fitness_level=fitness_level,
            goals=goals,
            equipment=equipment,
            duration_minutes=duration_minutes,
            duration_minutes_min=duration_minutes_min,
            duration_minutes_max=duration_minutes_max,
            focus_areas=focus_areas,
            avoid_name_words=avoid_name_words,
            workout_date=workout_date,
            age=age,
            activity_level=activity_level,
            intensity_preference=intensity_preference,
            avoided_exercises=avoided_exercises,
            avoided_muscles=avoided_muscles,
            staple_exercises=staple_exercises,
            progression_philosophy=progression_philosophy,
            exercise_count=exercise_count,
            coach_style=coach_style,
            coach_tone=coach_tone,
            scheduled_date=scheduled_date,
            strength_history=strength_history,
            user_dob=user_dob,
            training_split=training_split,
            workout_days=workout_days,
            workout_weight_unit=workout_weight_unit,
            library_exercises=library_exercises,
        )

        try:
            logger.info(f"[CachedStreaming] Using cache: {cache_name}")
            logger.info(f"[CachedStreaming] User prompt length: {len(user_prompt)} chars (vs ~15000 non-cached)")

            _streaming_max_retries = 3
            _streaming_delays = [2.0, 5.0, 10.0]
            # Per-stage timeouts — see non-cached path above for rationale.
            # Two-tier timeouts:
            #   stream-create: 45s — Vertex stream-create handshake under load.
            #   chunk 1: 150s — full inference cost (Vertex DEADLINE_EXCEEDED
            #     occurs at ~120s server-side; we give ourselves a hair more
            #     so the SERVER's error reaches us before our client timeout).
            #   chunk 2+: 30s — once inference done, chunks stream in ms.
            # My earlier blanket 45s per-chunk fired before Vertex returned
            # chunk 1, surfacing PYTHON-FASTAPI-37 "TimeoutError: Gemini stream
            # stalled at chunk 1" as a 500 even though Vertex was still working.
            _STREAM_CREATE_TIMEOUT_S = 45.0
            _FIRST_CHUNK_TIMEOUT_S = 150.0
            _SUBSEQUENT_CHUNK_TIMEOUT_S = 30.0
            stream = None
            for _attempt in range(_streaming_max_retries + 1):
                try:
                    async with _gemini_semaphore(user_id=user_id):
                        stream = await asyncio.wait_for(
                            client.aio.models.generate_content_stream(
                                model=self.model,
                                contents=user_prompt,
                                config=types.GenerateContentConfig(
                                    cached_content=cache_name,  # USE THE CACHE!
                                    response_mime_type="application/json",
                                    response_schema=GeneratedWorkoutResponse,
                                    temperature=0.85,  # bumped from 0.7 for variety (harness 2026-05-08)
                                    max_output_tokens=16384,  # Must match non-cached - workouts with set_targets can exceed 4000 tokens
                                ),
                            ),
                            timeout=_STREAM_CREATE_TIMEOUT_S,
                        )
                    break
                except Exception as _e:
                    if _is_transient_gemini_error(_e) and _attempt < _streaming_max_retries:
                        import random as _rand
                        _delay = _streaming_delays[min(_attempt, len(_streaming_delays) - 1)] + _rand.uniform(0, 1)
                        logger.warning(f"[CachedStreaming] Attempt {_attempt + 1}/{_streaming_max_retries + 1} failed (transient), retrying in {_delay:.1f}s: {_e}")
                        await asyncio.sleep(_delay)
                        continue
                    raise

            if stream is None:
                logger.error(f"❌ [CachedStreaming] Gemini returned None stream")
                raise ValueError("Gemini streaming returned None")

            chunk_count = 0
            total_chars = 0
            # Per-chunk timeout wrapper — same pattern as non-cached path.
            async def _with_chunk_timeout(_src, _timeout_s: float):
                _it = _src.__aiter__()
                _idx = 0
                while True:
                    try:
                        _val = await asyncio.wait_for(
                            _it.__anext__(),
                            timeout=_timeout_s,
                        )
                    except StopAsyncIteration:
                        return
                    except asyncio.TimeoutError as _te:
                        logger.warning(
                            f"⚠️ [CachedStreaming] Chunk {_idx + 1} timed out after "
                            f"{_timeout_s}s — aborting stream so caller can retry"
                        )
                        raise TimeoutError(
                            f"Gemini stream stalled at chunk {_idx + 1}"
                        ) from _te
                    _idx += 1
                    yield _val

            async for chunk in _with_chunk_timeout(stream, _FIRST_CHUNK_TIMEOUT_S, _SUBSEQUENT_CHUNK_TIMEOUT_S):
                chunk_count += 1

                # Check for blocked content or safety issues
                if hasattr(chunk, 'candidates') and chunk.candidates:
                    candidate = chunk.candidates[0]
                    if hasattr(candidate, 'finish_reason') and candidate.finish_reason:
                        finish_reason = str(candidate.finish_reason)
                        if finish_reason in ['MAX_TOKENS', 'FinishReason.MAX_TOKENS', '2']:
                            logger.warning(f"⚠️ [CachedStreaming] Response truncated (MAX_TOKENS) at {total_chars} chars - increase max_output_tokens")
                        elif finish_reason not in ['STOP', 'FinishReason.STOP', '1']:
                            logger.warning(f"⚠️ [CachedStreaming] Unexpected finish reason: {finish_reason}")

                if chunk.text:
                    total_chars += len(chunk.text)
                    yield chunk.text

            elapsed = (datetime.now() - start_time).total_seconds()
            logger.info(f"✅ [CachedStreaming] Complete: {chunk_count} chunks, {total_chars} chars in {elapsed:.1f}s")

        except Exception as e:
            import traceback
            logger.error(f"[CachedStreaming] Failed: {e}", exc_info=True)
            logger.error(f"Traceback: {traceback.format_exc()}", exc_info=True)

            # Fallback to non-cached generation
            logger.warning("[CachedStreaming] Falling back to non-cached generation", exc_info=True)
            async for chunk in self.generate_workout_plan_streaming(
                fitness_level=fitness_level,
                goals=goals,
                equipment=equipment,
                duration_minutes=duration_minutes,
                duration_minutes_min=duration_minutes_min,
                duration_minutes_max=duration_minutes_max,
                focus_areas=focus_areas,
                avoid_name_words=avoid_name_words,
                workout_date=workout_date,
                age=age,
                activity_level=activity_level,
                intensity_preference=intensity_preference,
                avoided_exercises=avoided_exercises,
                avoided_muscles=avoided_muscles,
                staple_exercises=staple_exercises,
                progression_philosophy=progression_philosophy,
                exercise_count=exercise_count,
                coach_style=coach_style,
                coach_tone=coach_tone,
                scheduled_date=scheduled_date,
            ):
                yield chunk

    def _build_cached_user_prompt(
        self,
        fitness_level: str,
        goals: List[str],
        equipment: List[str],
        duration_minutes: int,
        duration_minutes_min: Optional[int],
        duration_minutes_max: Optional[int],
        focus_areas: Optional[List[str]],
        avoid_name_words: Optional[List[str]],
        workout_date: Optional[str],
        age: Optional[int],
        activity_level: Optional[str],
        intensity_preference: Optional[str],
        avoided_exercises: Optional[List[str]],
        avoided_muscles: Optional[Dict],
        staple_exercises: Optional[List[str]],
        progression_philosophy: Optional[str],
        exercise_count: int,
        coach_style: Optional[str],
        coach_tone: Optional[str],
        scheduled_date: Optional[str],
        strength_history: Optional[Dict],
        user_dob: Optional[str] = None,
        training_split: Optional[str] = None,
        workout_days: Optional[List[int]] = None,
        # Per-day overrides — added 2026-05-27. Source:
        # user.preferences.workout_day_overrides JSONB. See
        # _build_per_day_overrides_prompt for the format the prompt expects.
        workout_day_overrides: Optional[Dict[int, Dict[str, Any]]] = None,
        workout_weight_unit: Optional[str] = None,
        library_exercises: Optional[List[Dict]] = None,
    ) -> str:
        """
        Build the user-specific prompt for cached generation.

        This prompt is MUCH smaller than the full prompt because the cache
        already contains all the static rules, examples, and guidelines.
        """
        # Determine difficulty
        if intensity_preference:
            difficulty = intensity_preference
        else:
            difficulty = "easy" if fitness_level == "beginner" else ("hard" if fitness_level == "advanced" else "medium")

        # Build duration text
        if duration_minutes_min and duration_minutes_max and duration_minutes_min != duration_minutes_max:
            duration_text = f"{duration_minutes_min}-{duration_minutes_max}"
        else:
            duration_text = str(duration_minutes)

        # Build user context section
        user_context_parts = [
            f"Generate a {duration_text}-minute {safe_join_list(focus_areas, 'full body')} workout.",
            "",
            "## USER PROFILE",
            f"- Fitness Level: {fitness_level}",
            f"- Goals: {safe_join_list(goals, 'General fitness')}",
            f"- Equipment: {safe_join_list(equipment, 'Bodyweight only')}",
            f"- Intensity: {difficulty}",
        ]

        if age:
            user_context_parts.append(f"- Age: {age}")
        if activity_level:
            user_context_parts.append(f"- Activity Level: {activity_level}")

        # Training split context
        if training_split:
            split_context = get_split_context(training_split, workout_days=workout_days)
            user_context_parts.append("")
            user_context_parts.append("## TRAINING SPLIT CONTEXT (Research-Backed)")
            user_context_parts.append(split_context)
            user_context_parts.append("Use this split information to guide exercise selection and workout structure.")

        # Per-day overrides (added 2026-05-27).
        if workout_day_overrides:
            from services.gemini.workout_generation_helpers import (
                _build_per_day_overrides_prompt,
            )
            _per_day_block = _build_per_day_overrides_prompt(
                workout_day_overrides, workout_days or []
            )
            if _per_day_block:
                user_context_parts.append(_per_day_block)

        # User preferences section
        user_context_parts.append("")
        user_context_parts.append("## USER PREFERENCES")

        if avoided_exercises and len(avoided_exercises) > 0:
            user_context_parts.append(f"🚫 AVOID these exercises: {', '.join(avoided_exercises[:10])}")

        if avoided_muscles:
            avoid_completely = avoided_muscles.get("avoid", [])
            reduce_usage = avoided_muscles.get("reduce", [])
            if avoid_completely:
                user_context_parts.append(f"🚫 AVOID muscles (injury/preference): {', '.join(avoid_completely)}")
            if reduce_usage:
                user_context_parts.append(f"⚠️ MINIMIZE muscles: {', '.join(reduce_usage)}")

        if staple_exercises and len(staple_exercises) > 0:
            user_context_parts.append(f"⭐ MUST INCLUDE these staple exercises (pre-filtered for this day): {', '.join(staple_exercises)}")

        # Strength history for progressive overload
        if strength_history:
            user_context_parts.append("")
            user_context_parts.append("## PROGRESSIVE OVERLOAD — STRENGTH HISTORY (CRITICAL)")
            user_context_parts.append("You MUST reference this data when setting target_weight_kg in set_targets.")
            user_context_parts.append("For exercises with history: increase weight by smallest increment (2.5kg barbell, 2kg dumbbell) if user handled it comfortably.")
            user_context_parts.append("If user struggled (high RPE / low reps): keep same weight, add 1-2 reps.")
            user_context_parts.append("Do NOT ignore previous weights and generate from scratch.")
            history_summary = self._format_strength_history(strength_history, workout_weight_unit=workout_weight_unit or 'kg')
            if history_summary:
                user_context_parts.append(history_summary)
            else:
                unit = workout_weight_unit or 'kg'
                if unit == 'lbs':
                    user_context_parts.append(
                        "No history. User works out in POUNDS (lbs). "
                        "Generate target_weight_kg values that convert to REAL lb gym weights.\n"
                        "REAL lb weights: Dumbbells: 5,10,15,20,25,30,35,40,45,50 lb (5 lb steps). "
                        "Barbell: 45(bar),55,65,75,85,95,115,135,155,185,225 lb (bar + plate pairs). "
                        "Cable/Machine: 10,20,30,40,50,60,70,80 lb (10 lb steps). "
                        "Kettlebell: 10,15,20,25,30,35 lb.\n"
                        "Beginner defaults: Barbell compound: 65 lb (≈30 kg) | Barbell isolation: 45 lb (≈20 kg) | "
                        "Dumbbell compound: 20-25 lb (≈10 kg) | Dumbbell isolation: 10-15 lb (≈5-7 kg) | "
                        "Cable: 20-30 lb (≈10-15 kg) | Machine: 40-60 lb (≈20-30 kg) | "
                        "NEVER use 10 kg for all exercises. Each exercise must have an appropriate weight."
                    )
                else:
                    user_context_parts.append(
                        "No history. User works out in KG. "
                        "Generate target_weight_kg values using REAL kg gym weights.\n"
                        "REAL kg weights: Dumbbells: 2,4,6,8,10,12,14,16,18,20 kg (2 kg steps). "
                        "Barbell: 20(bar),22,24,26,28,30,40,50,60 kg (bar + plate pairs in 2 kg steps). "
                        "Cable/Machine: 5,10,15,20,25,30,35,40 kg (5 kg steps). "
                        "Kettlebell: 4,8,12,16,20,24 kg (competition standard).\n"
                        "Beginner defaults: Barbell compound: 30-40 kg | Barbell isolation: 20 kg | "
                        "Dumbbell compound: 8-12 kg | Dumbbell isolation: 4-6 kg | "
                        "Cable: 10-15 kg | Machine: 20-30 kg | "
                        "NEVER use 10 kg for all exercises. Each exercise must have an appropriate weight."
                    )
        else:
            user_context_parts.append("")
            user_context_parts.append("## STRENGTH HISTORY")
            unit = workout_weight_unit or 'kg'
            user_context_parts.append(
                f"No history available. User prefers {unit.upper()}. "
                "Use equipment-appropriate beginner weights. NEVER use 10 kg for all exercises."
            )

        # Progression philosophy if provided
        if progression_philosophy and progression_philosophy.strip():
            user_context_parts.append("")
            user_context_parts.append("## PROGRESSION CONTEXT")
            user_context_parts.append(progression_philosophy)

        # Naming context
        naming_date = scheduled_date or workout_date
        naming_context = self._build_coach_naming_context(
            coach_style=coach_style,
            coach_tone=coach_tone,
            workout_date=naming_date,
            user_dob=user_dob,
        )

        # Holiday theme if applicable
        holiday_theme = self._get_holiday_theme(workout_date, user_dob=user_dob)
        if holiday_theme:
            user_context_parts.append("")
            user_context_parts.append(f"## THEME: {holiday_theme}")

        # Words to avoid in name
        if avoid_name_words and len(avoid_name_words) > 0:
            user_context_parts.append("")
            user_context_parts.append(f"⚠️ Do NOT use these words in workout name: {', '.join(avoid_name_words)}")

        # RAG-first library block (validation harness 2026-05-08).
        if library_exercises:
            _capped = library_exercises[:50]
            user_context_parts.append("")
            user_context_parts.append(
                f"## 📚 AVAILABLE EXERCISES ({len(_capped)} pre-filtered from library)"
            )
            for ex in _capped:
                user_context_parts.append(
                    f"- {ex.get('name','Unknown')}: targets "
                    f"{ex.get('muscle_group','unknown')}, equipment: "
                    f"{ex.get('equipment','bodyweight')}"
                )
            user_context_parts.append("")
            user_context_parts.append(
                "🚨 CRITICAL: Every exercise's `name` MUST match EXACTLY one of the "
                "names above. Do NOT invent exercise names. Do NOT modify or "
                "rephrase. Pick the most appropriate ones."
            )

        # Final instructions
        user_context_parts.append("")
        user_context_parts.append("## GENERATION REQUEST")
        user_context_parts.append(f"Generate exactly {exercise_count} exercises with complete set_targets.")
        user_context_parts.append(f"Workout name style: {naming_context}")

        # Movement-pattern diversity + compound-first ordering (validation
        # harness 2026-05-09 found 477 rows with <3 distinct patterns and 68
        # rows where the first 2 strength exercises were both isolation, e.g.
        # "Burpee + Half Burpees"). The 7 canonical patterns mirror
        # mobile/flutter/lib/services/movement_patterns.dart.
        user_context_parts.append(
            "## MOVEMENT PATTERN DIVERSITY (MANDATORY for strength/full-body)\n"
            "Cover at least N distinct patterns from {squat, hinge, push_horizontal, "
            "pull_horizontal, push_vertical, pull_vertical, carry, core}, where:\n"
            "- duration ≤ 5 min  → N = 2\n"
            "- 5 < duration ≤ 15 → N = 3\n"
            "- duration > 15 min → N = 4–5 (cap at 6)\n"
            "Compound lifts (squat/hinge/push/pull pattern) MUST appear before isolation "
            "exercises in the array. The first exercise MUST be a compound lift unless "
            "this is a mobility/recovery/cardio session."
        )

        user_context_parts.append("Return valid JSON only, no markdown.")

        return "\n".join(user_context_parts)

    def _format_strength_history(self, strength_history: Dict, workout_weight_unit: str = "kg") -> str:
        """Format strength history for the prompt in the user's preferred unit."""
        if not strength_history:
            return ""

        use_lbs = workout_weight_unit.lower() == "lbs"
        unit = "lbs" if use_lbs else "kg"
        lines = []
        for exercise_name, data in list(strength_history.items())[:10]:  # Limit to 10 exercises
            if isinstance(data, dict):
                weight_kg = data.get("weight_kg") or data.get("max_weight")
                reps = data.get("reps") or data.get("max_reps")
                if weight_kg:
                    display_weight = kg_to_lbs_gym(weight_kg) if use_lbs else weight_kg
                    lines.append(f"- {exercise_name}: {display_weight:.0f}{unit} × {reps or '?'} reps")
            elif isinstance(data, (int, float)):
                display_weight = kg_to_lbs_gym(data) if use_lbs else data
                lines.append(f"- {exercise_name}: {display_weight}{unit}")

        if lines:
            lines.insert(0, f"(Weights shown in {unit} — generate target_weight_kg in kg that converts cleanly to {unit})")

        return "\n".join(lines) if lines else ""

