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
from typing import List, Dict

from core.logger import get_logger

# Import services for background tasks
from services.strength_calculator_service import StrengthCalculatorService
from services.fitness_score_calculator_service import FitnessScoreCalculatorService
from services.nutrition_calculator_service import NutritionCalculatorService

logger = get_logger(__name__)


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


async def recalculate_user_strength_scores(user_id: str, supabase):
    """
    Background task to recalculate strength scores after workout completion.
    """
    try:
        logger.info(f"Background: Recalculating strength scores for user {user_id}")

        strength_service = StrengthCalculatorService()

        # Get user info
        user_response = supabase.table("users").select("weight_kg, gender").eq(
            "id", user_id
        ).maybe_single().execute()

        if not user_response.data:
            logger.warning(f"User not found for strength recalc: {user_id}")
            return

        user = user_response.data
        bodyweight = float(user.get("weight_kg", 70))
        gender = user.get("gender", "male")

        # Get workout data from last 90 days
        start_date = (date.today() - timedelta(days=90)).isoformat()

        workouts_response = supabase.table("workouts").select(
            "id, exercises_json, completed_at"
        ).eq(
            "user_id", user_id
        ).eq(
            "is_completed", True
        ).gte(
            "scheduled_date", start_date
        ).execute()

        # Extract exercise performances
        workout_data = []
        for workout in (workouts_response.data or []):
            exercises = workout.get("exercises_json", [])
            if isinstance(exercises, str):
                exercises = json.loads(exercises)
            for exercise in exercises:
                if isinstance(exercise, dict):
                    sets = exercise.get("sets", [])
                    # Handle case where sets is an integer count instead of a list
                    if isinstance(sets, int) or not isinstance(sets, list):
                        continue
                    if sets:
                        best_set = max(
                            (s for s in sets if s.get("completed", True)),
                            key=lambda s: float(s.get("weight_kg", 0)) * int(s.get("reps", 0)),
                            default=None,
                        )
                        if best_set:
                            workout_data.append({
                                "exercise_name": exercise.get("name", ""),
                                "weight_kg": float(best_set.get("weight_kg", 0)),
                                "reps": int(best_set.get("reps", 0)),
                                "sets": len(sets),
                            })

        # Calculate scores for all muscle groups
        muscle_scores = strength_service.calculate_all_muscle_scores(
            workout_data, bodyweight, gender
        )

        # Get previous scores for trend calculation
        previous_response = supabase.from_("latest_strength_scores").select(
            "muscle_group, strength_score"
        ).eq("user_id", user_id).execute()

        previous_scores = {
            r["muscle_group"]: r["strength_score"]
            for r in (previous_response.data or [])
        }

        # Save new scores
        now = datetime.now()
        period_end = date.today()
        period_start = period_end - timedelta(days=7)

        for mg, score in muscle_scores.items():
            prev_score = previous_scores.get(mg)

            # Determine trend
            if prev_score is not None:
                if score.strength_score > prev_score + 2:
                    trend = "improving"
                elif score.strength_score < prev_score - 2:
                    trend = "declining"
                else:
                    trend = "maintaining"
                score_change = score.strength_score - prev_score
            else:
                trend = "maintaining"
                score_change = None

            record_data = {
                "user_id": user_id,
                "muscle_group": mg,
                "strength_score": score.strength_score,
                "strength_level": score.strength_level.value,
                "best_exercise_name": score.best_exercise_name,
                "best_estimated_1rm_kg": score.best_estimated_1rm_kg,
                "bodyweight_ratio": score.bodyweight_ratio,
                "weekly_sets": score.weekly_sets,
                "weekly_volume_kg": score.weekly_volume_kg,
                "previous_score": prev_score,
                "score_change": score_change,
                "trend": trend,
                "calculated_at": now.isoformat(),
                "period_start": period_start.isoformat(),
                "period_end": period_end.isoformat(),
            }

            supabase.table("strength_scores").upsert(
                record_data,
                on_conflict="user_id,muscle_group,period_end",
            ).execute()

        logger.info(f"Background: Updated strength scores for {len(muscle_scores)} muscle groups")

    except Exception as e:
        logger.error(f"Background: Failed to recalculate strength scores: {e}")


async def recalculate_user_fitness_score(user_id: str, supabase):
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
        thirty_days_ago = (date.today() - timedelta(days=30)).isoformat()

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

        # 3. Get nutrition score (current week)
        week_start, week_end = nutrition_service.get_current_week_range()

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
        seven_days_ago = (date.today() - timedelta(days=7)).isoformat()
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
            previous_score=previous_score,
        )

        # 7. Save to database
        record_data = {
            "user_id": user_id,
            "calculated_date": date.today().isoformat(),
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
        logger.error(f"Background: Failed to recalculate fitness score: {e}")


async def populate_performance_logs(
    user_id: str,
    workout_id: str,
    workout_log_id: str,
    exercises: List[Dict],
    supabase,
):
    """
    Background task to populate performance_logs table with individual set data.

    This enables efficient exercise history queries for AI weight suggestions
    instead of parsing large JSON blobs from workout_logs.
    """
    try:
        logger.info(f"Background: Populating performance_logs for workout_log {workout_log_id}")

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
                notes = set_data.get("notes")
                target_weight_kg = set_data.get("target_weight_kg")
                target_reps = set_data.get("target_reps")
                progression_model = set_data.get("progression_model")

                # Skip sets with no meaningful data
                if reps_completed <= 0 and weight_kg <= 0:
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
                    "notes": notes,
                    "recorded_at": recorded_at,
                    "target_weight_kg": float(target_weight_kg) if target_weight_kg is not None else None,
                    "target_reps": int(target_reps) if target_reps is not None else None,
                    "progression_model": progression_model,
                }

                records_to_insert.append(record)

        if records_to_insert:
            supabase.table("performance_logs").insert(records_to_insert).execute()
            logger.info(f"Background: Inserted {len(records_to_insert)} performance_log records for workout_log {workout_log_id}")
        else:
            logger.info(f"Background: No performance_log records to insert for workout_log {workout_log_id}")

    except Exception as e:
        logger.error(f"Background: Failed to populate performance_logs for workout_log {workout_log_id}: {e}")


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
            logger.warning(f"[Nudge] chat_history insert failed: {e}")

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
        logger.error(f"[Nudge] Post-workout nutrition nudge failed for {user_id}: {e}")


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
        logger.error(f"[Nudge] Streak celebration failed for {user_id}: {e}")
