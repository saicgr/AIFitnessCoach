"""
Background tasks for workout completion.

Extracted from crud.py to keep files under 1000 lines.
Contains:
- recalculate_user_strength_scores
- recalculate_user_fitness_score
- populate_performance_logs
- _send_post_workout_nutrition_nudge
- _send_streak_celebration_if_milestone
- _calculate_completion_calories
"""
import asyncio
import json
from datetime import datetime, date, timedelta
from typing import List, Dict, Optional

from core.logger import get_logger
from core.timezone_utils import get_user_today

# Import services for background tasks
from services.strength_calculator_service import StrengthCalculatorService
from services.fitness_score_calculator_service import FitnessScoreCalculatorService
from services.nutrition_calculator_service import NutritionCalculatorService

logger = get_logger(__name__)


# Per-user coalesce/debounce locks for score recalculation. When five workouts
# complete within a few seconds (sync queue replay, bulk import, rapid manual
# logging), each one would otherwise enqueue its own strength + fitness recalc
# pair, fanning out 5×2 = 10 expensive DB jobs that all read the same rows.
# `_recalc_locks[user_id]` holds the in-flight task; subsequent enqueues during
# the debounce window become no-ops because the existing task will pick up the
# latest data when it runs.
_recalc_locks: Dict[str, asyncio.Task] = {}
_RECALC_DEBOUNCE_SECONDS = 5.0


def schedule_score_recalc(user_id: str, supabase, timezone_str: str) -> None:
    """Coalesce strength + fitness recalc per user.

    First call schedules a task that fires after [_RECALC_DEBOUNCE_SECONDS].
    Concurrent calls during the debounce window are absorbed — the already-
    scheduled task will read the latest workout data when it runs, so the
    coalescing is safe (correctness preserved, work compressed).

    Drop-in replacement for the two prior `background_tasks.add_task(
    recalculate_user_strength_scores, ...)` + `background_tasks.add_task(
    recalculate_user_fitness_score, ...)` calls. Failures swallowed; never
    raises into the caller.
    """
    existing = _recalc_locks.get(user_id)
    if existing is not None and not existing.done():
        # Already scheduled for this user — skip.
        return

    async def _run():
        try:
            await asyncio.sleep(_RECALC_DEBOUNCE_SECONDS)
            await recalculate_user_strength_scores(user_id, supabase, timezone_str)
            await recalculate_user_fitness_score(user_id, supabase, timezone_str)
        except Exception as e:
            logger.warning(f"Background: Coalesced recalc for {user_id} failed: {e}")
        finally:
            _recalc_locks.pop(user_id, None)

    _recalc_locks[user_id] = asyncio.create_task(_run())


def _calculate_completion_calories(
    exercises: list,
    duration_seconds: int,
    total_sets: int,
    total_reps: int,
    total_volume_kg: float,
    workout_type: str = None,
    difficulty: str = None,
    user_id: str = None,
    supabase=None,
) -> int:
    """Calculate calories burned for a completed workout using all logged data.

    Uses MET-based formula: calories = MET x body_weight_kg x (duration_hours)
    MET is estimated from actual workout data: exercises, sets, reps, weight,
    rest periods, supersets, drop sets, difficulty, and workout type.
    """
    duration_minutes = duration_seconds / 60.0 if duration_seconds else 45
    if duration_minutes <= 0:
        return 0

    # Get user weight
    user_weight_kg = 70.0
    if user_id and supabase:
        try:
            user_resp = supabase.table("users").select("weight_kg").eq(
                "id", user_id
            ).maybe_single().execute()
            if user_resp.data:
                user_weight_kg = float(user_resp.data.get("weight_kg") or 70)
                user_weight_kg = max(30.0, min(user_weight_kg, 250.0))
        except Exception:
            pass

    # Estimate MET from actual workout data
    met = 3.5
    if not exercises:
        return round(met * user_weight_kg * (duration_minutes / 60.0))

    compound_muscles = {
        'legs', 'back', 'chest', 'full_body', 'glutes',
        'quadriceps', 'hamstrings', 'shoulders',
    }
    compound_count = 0
    superset_groups = set()
    drop_set_count = 0
    rest_values = []

    for ex in exercises:
        muscle = (ex.get('muscle_group', '') or ex.get('primary_muscle', '') or '').lower()
        if muscle in compound_muscles:
            compound_count += 1
        rest_sec = ex.get('rest_seconds')
        if rest_sec:
            rest_values.append(rest_sec)
        sg = ex.get('superset_group')
        if sg is not None:
            superset_groups.add(sg)
        if ex.get('is_drop_set'):
            drop_set_count += 1

    avg_rest = sum(rest_values) / len(rest_values) if rest_values else 60

    # Exercise count
    if len(exercises) >= 6:
        met += 0.3
    if len(exercises) >= 9:
        met += 0.2

    # Compound lifts
    if compound_count >= 3:
        met += 0.5
    if compound_count >= 5:
        met += 0.3

    # Total sets
    if total_sets >= 15:
        met += 0.3
    if total_sets >= 25:
        met += 0.3

    # Rep volume per exercise
    avg_reps = total_reps / len(exercises) if exercises else 10
    if avg_reps >= 12:
        met += 0.3
    if avg_reps >= 15:
        met += 0.2

    # Weight volume
    if total_volume_kg > 5000:
        met += 0.3
    if total_volume_kg > 15000:
        met += 0.3

    # Rest periods
    if avg_rest < 60:
        met += 0.5
    if avg_rest < 30:
        met += 0.3

    # Supersets
    if superset_groups:
        met += 0.3 + min(len(superset_groups) * 0.1, 0.5)

    # Drop sets
    if drop_set_count > 0:
        met += 0.2 + min(drop_set_count * 0.1, 0.4)

    # Workout type
    if workout_type:
        wt = workout_type.lower()
        if 'hiit' in wt or 'circuit' in wt:
            met += 1.5
        elif 'cardio' in wt:
            met += 1.0

    # Difficulty
    if difficulty:
        d = difficulty.lower()
        if d in ('hell', 'extreme', 'insane'):
            met += 2.0
        elif d in ('hard', 'advanced', 'challenging'):
            met += 1.2
        elif d in ('moderate', 'intermediate'):
            met += 0.5

    met = min(met, 10.0)
    calories = round(met * user_weight_kg * (duration_minutes / 60.0))
    logger.info(
        f"[Completion Calories] MET={met:.1f}, weight={user_weight_kg}kg, "
        f"duration={duration_minutes:.0f}min, sets={total_sets}, reps={total_reps}, "
        f"volume={total_volume_kg:.0f}kg, supersets={len(superset_groups)}, "
        f"dropsets={drop_set_count} -> {calories} cal"
    )
    return calories


async def recalculate_user_strength_scores(user_id: str, supabase, timezone_str: str):
    """
    Background task to recalculate strength scores after workout completion.

    FEATURE 4: delegates to the SHARED recompute (strength_recalc) so the background
    task and the manual POST /strength/calculate endpoint run identical code. This fixes
    two pre-existing divergences:
      1. it used to read `workouts.exercises_json` (often empty on logged sessions)
         instead of `workout_logs.sets_json` (the actual source of truth);
      2. it used `on_conflict="user_id,muscle_group,period_end"` — a unique constraint
         migration 2237 DROPPED (replaced by a gym-aware unique index), so the upsert
         would error. The shared recompute inserts (matching the endpoint) instead.
    """
    try:
        logger.info(f"Background: Recalculating strength scores for user {user_id}")
        from services.strength_recalc import _recompute_strength_for_user

        gym_count = _recompute_strength_for_user(
            user_id=user_id, supabase=supabase, tz=timezone_str
        )
        logger.info(
            f"Background: Recomputed composite strength scores for {user_id} "
            f"({gym_count} gym profiles)"
        )

    except Exception as e:
        logger.error(f"Background: Failed to recalculate strength scores: {e}", exc_info=True)


async def recalculate_user_fitness_score(user_id: str, supabase, timezone_str: str):
    """
    Background task to recalculate overall fitness score after workout completion.

    The fitness score combines:
    - Strength score (40%)
    - Consistency score (30%)
    - Nutrition score (20%)
    - Readiness score (10%)
    """
    try:
        logger.info(f"Background: Recalculating fitness score for user {user_id}")

        fitness_service = FitnessScoreCalculatorService()
        strength_service = StrengthCalculatorService()
        nutrition_service = NutritionCalculatorService()

        # 1. Get strength score (overall)
        strength_response = supabase.from_("latest_strength_scores").select(
            "muscle_group, strength_score"
        ).eq("user_id", user_id).execute()

        if strength_response.data:
            score_objects = {
                r["muscle_group"]: type('obj', (object,), {'strength_score': r["strength_score"] or 0})()
                for r in strength_response.data
            }
            strength_score, _ = strength_service.calculate_overall_strength_score(score_objects)
        else:
            strength_score = 0

        # 2. Get consistency score (workout completion rate for last 30 days)
        thirty_days_ago = (date.fromisoformat(get_user_today(timezone_str)) - timedelta(days=30)).isoformat()

        # Count scheduled workouts
        scheduled_response = supabase.table("workouts").select(
            "id", count="exact"
        ).eq(
            "user_id", user_id
        ).gte(
            "scheduled_date", thirty_days_ago
        ).execute()
        scheduled_count = scheduled_response.count or 0

        # Count completed workouts
        completed_response = supabase.table("workouts").select(
            "id", count="exact"
        ).eq(
            "user_id", user_id
        ).eq(
            "is_completed", True
        ).gte(
            "scheduled_date", thirty_days_ago
        ).execute()
        completed_count = completed_response.count or 0

        consistency_score = fitness_service.calculate_consistency_score(
            scheduled=scheduled_count,
            completed=completed_count,
        )

        # 3. Get nutrition score (current week) — user-local week boundaries.
        week_start, week_end = nutrition_service.get_current_week_range(timezone_str)

        nutrition_response = supabase.table("nutrition_scores").select(
            "nutrition_score"
        ).eq(
            "user_id", user_id
        ).eq(
            "week_start", week_start.isoformat()
        ).limit(1).execute()

        nutrition_rows = nutrition_response.data or []
        nutrition_score = nutrition_rows[0].get("nutrition_score", 0) if nutrition_rows else 0

        # 4. Get readiness score (7-day average)
        seven_days_ago = (date.fromisoformat(get_user_today(timezone_str)) - timedelta(days=7)).isoformat()
        readiness_response = supabase.table("readiness_scores").select(
            "readiness_score"
        ).eq(
            "user_id", user_id
        ).gte(
            "score_date", seven_days_ago
        ).execute()

        readiness_scores = [r["readiness_score"] for r in (readiness_response.data or [])]
        readiness_score = round(sum(readiness_scores) / len(readiness_scores)) if readiness_scores else 50

        # 5. Get previous fitness score
        previous_response = supabase.table("fitness_scores").select(
            "overall_fitness_score"
        ).eq(
            "user_id", user_id
        ).order(
            "calculated_at", desc=True
        ).limit(1).execute()

        previous_rows = previous_response.data or []
        previous_score = previous_rows[0].get("overall_fitness_score") if previous_rows else None

        # 6. Calculate overall fitness score
        score = fitness_service.calculate_fitness_score(
            user_id=user_id,
            strength_score=strength_score,
            readiness_score=readiness_score,
            consistency_score=consistency_score,
            nutrition_score=nutrition_score,
            timezone_str=timezone_str,
            previous_score=previous_score,
        )

        # 7. Save to database
        record_data = {
            "user_id": user_id,
            "calculated_date": get_user_today(timezone_str),
            "strength_score": score.strength_score,
            "readiness_score": score.readiness_score,
            "consistency_score": score.consistency_score,
            "nutrition_score": score.nutrition_score,
            "overall_fitness_score": score.overall_fitness_score,
            "fitness_level": score.fitness_level.value,
            "strength_weight": score.strength_weight,
            "consistency_weight": score.consistency_weight,
            "nutrition_weight": score.nutrition_weight,
            "readiness_weight": score.readiness_weight,
            "focus_recommendation": score.focus_recommendation,
            "previous_score": score.previous_score,
            "score_change": score.score_change,
            "trend": score.trend,
            "calculated_at": datetime.now().isoformat(),
        }

        supabase.table("fitness_scores").upsert(
            record_data,
            on_conflict="user_id,calculated_date",
        ).execute()

        logger.info(f"Background: Updated fitness score for user {user_id}: {score.overall_fitness_score} ({score.fitness_level.value})")

    except Exception as e:
        logger.error(f"Background: Failed to recalculate fitness score: {e}", exc_info=True)


def _derive_gym_for_populate(
    supabase,
    workout_log_id: Optional[str],
    workout_id: Optional[str],
    user_id: str,
) -> Optional[str]:
    """Resolve the gym for server-populated performance_logs when the /complete
    caller didn't thread one in.

    Precedence mirrors the performance_db write path so both attribute identically:
      1. parent workout_log.gym_profile_id (already stamped by create_workout_log)
      2. workouts.gym_profile_id (the gym the workout was generated for)
      3. users.active_gym_profile_id (legacy/ad-hoc fallback)
      4. None (legacy/unassigned — valid, never crashes)

    Takes the raw supabase client (this module is handed `supabase = db.client`),
    so it queries tables directly rather than via the db facade.
    """
    # 1. Parent workout_log
    if workout_log_id:
        try:
            resp = (
                supabase.table("workout_logs")
                .select("gym_profile_id")
                .eq("id", workout_log_id)
                .maybe_single()
                .execute()
            )
            if resp is not None and resp.data and resp.data.get("gym_profile_id"):
                return resp.data["gym_profile_id"]
        except Exception as e:
            logger.debug(f"[gym] populate: workout_log {workout_log_id} lookup failed: {e}")

    # 2. Workout provenance
    if workout_id:
        try:
            resp = (
                supabase.table("workouts")
                .select("gym_profile_id")
                .eq("id", workout_id)
                .maybe_single()
                .execute()
            )
            if resp is not None and resp.data and resp.data.get("gym_profile_id"):
                return resp.data["gym_profile_id"]
        except Exception as e:
            logger.debug(f"[gym] populate: workout {workout_id} lookup failed: {e}")

    # 3. Active gym fallback
    try:
        resp = (
            supabase.table("gym_profiles")
            .select("id")
            .eq("user_id", user_id)
            .eq("is_active", True)
            .single()
            .execute()
        )
        if resp is not None and resp.data:
            return resp.data.get("id")
    except Exception as e:
        logger.debug(f"[gym] populate: active-gym fallback failed for {user_id}: {e}")

    return None


async def populate_performance_logs(
    user_id: str,
    workout_id: str,
    workout_log_id: str,
    exercises: List[Dict],
    supabase,
    gym_profile_id: Optional[str] = None,
):
    """
    Background task to populate performance_logs table with individual set data.

    This enables efficient exercise history queries for AI weight suggestions
    instead of parsing large JSON blobs from workout_logs.

    Args:
        gym_profile_id: Per-gym progress attribution for every set this run
            inserts. The /complete caller passes the WORKOUT's gym
            (workouts.gym_profile_id) so the server-populated rows attribute to
            the SAME gym as the client `/logs/bulk` path. When None, we derive
            it here from the parent workout_log (which the create-workout-log
            endpoint already stamped), then the workout, then the active gym —
            so a missing arg never leaves the rows unstamped when a gym exists.
            NULL is valid (legacy/ad-hoc workout) and never crashes.
    """
    try:
        logger.info(f"Background: Populating performance_logs for workout_log {workout_log_id}")

        # Resolve gym SERVER-SIDE if the caller didn't supply it. Same
        # precedence as the performance_db write path so both paths agree:
        # parent workout_log.gym_profile_id → workout.gym_profile_id → active.
        if gym_profile_id is None:
            gym_profile_id = _derive_gym_for_populate(
                supabase, workout_log_id, workout_id, user_id
            )

        records_to_insert = []
        recorded_at = datetime.now().isoformat()

        for exercise in exercises:
            exercise_name = exercise.get("name", "")
            exercise_id = exercise.get("id") or exercise.get("exercise_id") or exercise.get("libraryId", "")

            if not exercise_name:
                continue

            # Get AI-recommended set type info from exercise definition
            ai_recommended_drop_set = exercise.get("is_drop_set", False)
            ai_recommended_failure_set = exercise.get("is_failure_set", False)
            raw_sets = exercise.get("sets", [])
            total_sets_count = raw_sets if isinstance(raw_sets, int) else len(raw_sets)

            sets = raw_sets if isinstance(raw_sets, list) else []

            for set_data in sets:
                # Only log completed sets
                if not set_data.get("completed", True):
                    continue

                set_number = set_data.get("set_number", 1)
                reps_completed = set_data.get("reps_completed") or set_data.get("reps", 0)
                weight_kg = set_data.get("weight_kg") or set_data.get("weight", 0)
                rpe = set_data.get("rpe")
                rir = set_data.get("rir")
                set_type = set_data.get("set_type", "working")
                tempo = set_data.get("tempo")
                is_completed = set_data.get("completed", True)
                failed_at_rep = set_data.get("failed_at_rep")
                # Notes is now TEXT[] in the DB. Coerce list / single string /
                # null into a clean list of non-empty strings so the column
                # write succeeds regardless of client version.
                raw_notes = set_data.get("notes")
                if raw_notes is None:
                    notes = []
                elif isinstance(raw_notes, list):
                    notes = [str(n).strip() for n in raw_notes if n is not None and str(n).strip()]
                elif isinstance(raw_notes, str):
                    notes = [raw_notes.strip()] if raw_notes.strip() else []
                else:
                    notes = []
                notes_audio_url = set_data.get("notes_audio_url")
                notes_photo_urls = set_data.get("notes_photo_urls")
                target_weight_kg = set_data.get("target_weight_kg")
                target_reps = set_data.get("target_reps")
                progression_model = set_data.get("progression_model")
                # New fields wired in 2030_performance_logs_rich_set_data.sql.
                started_at = set_data.get("started_at")
                logging_mode = set_data.get("logging_mode")
                ai_input_source = set_data.get("ai_input_source")
                set_duration_seconds = set_data.get("set_duration_seconds")
                rest_duration_seconds = set_data.get("rest_duration_seconds")
                # Distance-tracked sets (SkiErg/sled/carry/run) carry meters
                # instead of weight×reps. Migration 2298.
                distance_meters = set_data.get("distance_meters")

                # Skip sets with no meaningful data. A distance- or duration-only
                # set (cardio/carry/timed station) legitimately has reps=0 &
                # weight=0 — keep it when it carries distance or duration so the
                # set is not silently dropped from history.
                _has_distance = distance_meters is not None and float(distance_meters or 0) > 0
                _has_duration = set_duration_seconds is not None and int(set_duration_seconds or 0) > 0
                if reps_completed <= 0 and weight_kg <= 0 and not _has_distance and not _has_duration:
                    continue

                # Determine if this set type was AI-recommended
                is_ai_recommended = False
                if set_type == "drop_set" and ai_recommended_drop_set:
                    is_ai_recommended = True
                elif set_type == "failure" and ai_recommended_failure_set and set_number == total_sets_count:
                    is_ai_recommended = True
                elif set_type == "amrap" and ai_recommended_failure_set and set_number == total_sets_count:
                    is_ai_recommended = True
                elif set_type == "working" and not ai_recommended_drop_set and not ai_recommended_failure_set:
                    is_ai_recommended = True
                elif set_type == "warmup":
                    is_ai_recommended = False

                record = {
                    "workout_log_id": workout_log_id,
                    "user_id": user_id,
                    "exercise_id": str(exercise_id) if exercise_id else exercise_name.lower().replace(" ", "_"),
                    "exercise_name": exercise_name,
                    "set_number": set_number,
                    "reps_completed": reps_completed,
                    "weight_kg": float(weight_kg) if weight_kg else 0.0,
                    "rpe": float(rpe) if rpe is not None else None,
                    "rir": int(rir) if rir is not None else None,
                    "set_type": set_type,
                    "is_ai_recommended_set_type": is_ai_recommended,
                    "tempo": tempo,
                    "is_completed": is_completed,
                    "failed_at_rep": failed_at_rep,
                    # Per-gym progress: server-derived gym for this session
                    # (same value the /logs/bulk client path resolves). NULL
                    # is valid (legacy/ad-hoc) — the column is nullable.
                    "gym_profile_id": gym_profile_id,
                    # `notes` always emitted as a list (possibly empty) so the
                    # TEXT[] column gets a stable shape across client versions.
                    "notes": notes,
                    "notes_audio_url": notes_audio_url,
                    "notes_photo_urls": notes_photo_urls if notes_photo_urls else None,
                    "recorded_at": recorded_at,
                    "target_weight_kg": float(target_weight_kg) if target_weight_kg is not None else None,
                    "target_reps": int(target_reps) if target_reps is not None else None,
                    "progression_model": progression_model,
                    # Rich fields added in migration 2030 — only emit when
                    # present so older clients (which don't send these) still
                    # insert cleanly without overriding column defaults.
                    **({"started_at": started_at} if started_at else {}),
                    **({"logging_mode": logging_mode} if logging_mode else {}),
                    **({"ai_input_source": ai_input_source} if ai_input_source else {}),
                    **({"set_duration_seconds": int(set_duration_seconds)} if set_duration_seconds is not None else {}),
                    **({"rest_duration_seconds": int(rest_duration_seconds)} if rest_duration_seconds is not None else {}),
                    **({"distance_meters": float(distance_meters)} if distance_meters is not None else {}),
                }

                records_to_insert.append(record)

        if records_to_insert:
            supabase.table("performance_logs").insert(records_to_insert).execute()
            logger.info(f"Background: Inserted {len(records_to_insert)} performance_log records for workout_log {workout_log_id}")
        else:
            logger.info(f"Background: No performance_log records to insert for workout_log {workout_log_id}")

    except Exception as e:
        logger.error(f"Background: Failed to populate performance_logs for workout_log {workout_log_id}: {e}", exc_info=True)


async def _send_post_workout_nutrition_nudge(user_id: str, workout_name: str):
    """Wait configured delay, then nudge user to log post-workout meal.

    Runs as a BackgroundTask after workout completion. Waits the user's
    configured delay (default 30 min), then checks if they've logged a meal.
    If not, saves a coach message to chat and sends a push notification.
    """
    try:
        from core.supabase_client import get_supabase
        from services.notification_service import get_notification_service

        supabase = get_supabase()

        # Get user preferences
        user_result = supabase.client.table("users") \
            .select("id, name, fcm_token, timezone, notification_preferences") \
            .eq("id", user_id) \
            .limit(1) \
            .execute()

        if not user_result.data:
            return
        user = user_result.data[0]
        prefs = user.get("notification_preferences") or {}

        # EDGE CASE: Check if preference is enabled
        if not prefs.get("post_workout_meal_reminder", True):
            return

        # Wait configured delay
        delay_minutes = prefs.get("post_workout_meal_delay_minutes", 30)
        await asyncio.sleep(delay_minutes * 60)

        # EDGE CASE: Check if user already logged a meal since workout completion
        tz_str = user.get("timezone") or "UTC"
        from zoneinfo import ZoneInfo
        user_today = datetime.now(ZoneInfo(tz_str) if tz_str != "UTC" else ZoneInfo("UTC")).strftime("%Y-%m-%d")

        try:
            recent_meal = supabase.client.table("food_logs") \
                .select("id") \
                .eq("user_id", user_id) \
                .gte("logged_at", f"{user_today}T00:00:00") \
                .order("logged_at", desc=True) \
                .limit(1) \
                .execute()

            # If they logged a meal in the last delay_minutes, skip
            if recent_meal.data:
                logged_at = recent_meal.data[0].get("logged_at", "")
                if isinstance(logged_at, str):
                    logged_time = datetime.fromisoformat(logged_at.replace("Z", "+00:00"))
                    minutes_ago = (datetime.now(ZoneInfo("UTC")) - logged_time).total_seconds() / 60
                    if minutes_ago < delay_minutes:
                        logger.info(f"[Nudge] Post-workout meal already logged for {user_id}, skipping nudge")
                        return
        except Exception:
            pass  # Continue with nudge if check fails

        # Get coach persona
        ai_map_result = supabase.client.table("user_ai_settings") \
            .select("coach_name, coaching_style, communication_tone, use_emojis") \
            .eq("user_id", user_id) \
            .limit(1) \
            .execute()
        ai_settings = ai_map_result.data[0] if ai_map_result.data else {}

        notif_svc = get_notification_service()
        coach_name = ai_settings.get("coach_name") or "Your Coach"
        intensity = prefs.get("accountability_intensity", "balanced")

        # Generate message
        message = await notif_svc.generate_accountability_message(
            nudge_type="post_workout_meal",
            context_dict={"workout_name": workout_name},
            user_name=user.get("name"),
            coach_name=coach_name,
            coaching_style=ai_settings.get("coaching_style", "motivational"),
            communication_tone=ai_settings.get("communication_tone", "encouraging"),
            use_emojis=ai_settings.get("use_emojis", True),
            accountability_intensity=intensity,
            use_ai=prefs.get("ai_personalized_nudges", True),
        )

        # Save to chat_history (proactive AI message)
        try:
            supabase.client.table("chat_history").insert({
                "user_id": user_id,
                "user_message": "",
                "ai_response": message,
                "context_json": {
                    "nudge_type": "post_workout_meal",
                    "proactive": True,
                    "coach_name": coach_name,
                    "workout_name": workout_name,
                }
            }).execute()
        except Exception as e:
            logger.warning(f"[Nudge] chat_history insert failed: {e}", exc_info=True)

        # Send push notification
        fcm_token = user.get("fcm_token")
        if fcm_token:
            await notif_svc.send_accountability_nudge(
                fcm_token=fcm_token,
                nudge_type="post_workout_meal",
                context_dict={"workout_name": workout_name},
                user_name=user.get("name"),
                coach_name=coach_name,
                coaching_style=ai_settings.get("coaching_style"),
                communication_tone=ai_settings.get("communication_tone"),
                use_emojis=ai_settings.get("use_emojis", True),
                accountability_intensity=intensity,
                use_ai=False,  # Already generated message
            )
            logger.info(f"[Nudge] Post-workout nutrition sent to {user_id}")

    except Exception as e:
        logger.error(f"[Nudge] Post-workout nutrition nudge failed for {user_id}: {e}", exc_info=True)


async def _send_streak_celebration_if_milestone(user_id: str):
    """Check streak and send celebration push if it's a milestone.

    Runs as a BackgroundTask after workout completion. Checks the user's
    current streak and sends a celebration if it hits a milestone number.

    Milestones: 3, 7, 14, 30, 50, 100, 365 days
    """
    MILESTONE_DAYS = {3, 7, 14, 30, 50, 100, 365}

    try:
        from core.supabase_client import get_supabase
        from services.notification_service import get_notification_service

        supabase = get_supabase()

        # Get user and streak data
        user_result = supabase.client.table("users") \
            .select("id, name, fcm_token, notification_preferences") \
            .eq("id", user_id) \
            .limit(1) \
            .execute()

        if not user_result.data:
            return
        user = user_result.data[0]
        prefs = user.get("notification_preferences") or {}

        # EDGE CASE: Check if celebration preference is enabled
        if not prefs.get("streak_celebration", True):
            return

        # Get current streak
        streak_result = supabase.client.table("user_login_streaks") \
            .select("current_streak") \
            .eq("user_id", user_id) \
            .limit(1) \
            .execute()

        if not streak_result.data:
            return

        current_streak = streak_result.data[0].get("current_streak", 0)
        if current_streak not in MILESTONE_DAYS:
            return

        # Send celebration via existing notification service
        notif_svc = get_notification_service()
        fcm_token = user.get("fcm_token")
        if fcm_token:
            await notif_svc.send_streak_celebration(
                fcm_token=fcm_token,
                streak_days=current_streak,
                user_name=user.get("name"),
            )
            logger.info(f"[Nudge] Streak celebration ({current_streak} days) sent to {user_id}")

    except Exception as e:
        logger.error(f"[Nudge] Streak celebration failed for {user_id}: {e}", exc_info=True)
