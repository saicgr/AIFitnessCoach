"""
Workout completion and summary endpoints.

Extracted from crud.py to keep files under 1000 lines.
Provides:
- POST /{workout_id}/complete - Mark workout as completed (with PR detection)
- POST /{workout_id}/uncomplete - Revert a marked-done workout
- GET /{workout_id}/completion-summary - Get combined summary data
- PATCH /{workout_id}/exercise-sets - Update exercise sets post-completion
"""
import asyncio
import json
from datetime import datetime, date, timedelta
from typing import List, Optional, Dict, Any

from fastapi import APIRouter, Depends, HTTPException, Query, BackgroundTasks, Request
from core.auth import get_current_user, verify_resource_ownership
from core.exceptions import safe_internal_error
from core.timezone_utils import resolve_timezone

from core.db import get_supabase_db
from core.logger import get_logger
from models.schemas import Workout

from .utils import (
    row_to_workout,
    log_workout_change,
    index_workout_to_rag,
)

from services.personal_records_service import PersonalRecordsService
from services.ai_insights_service import ai_insights_service
from services.performance_comparison_service import PerformanceComparisonService
from services.user_context_service import user_context_service

from .crud_models import (
    PersonalRecordInfo,
    ExerciseComparisonInfo,
    WorkoutComparisonInfo,
    PerformanceComparisonInfo,
    WorkoutCompletionResponse,
    SetLogInfo,
    WorkoutSummaryResponse,
    UpdateExerciseSetsRequest,
)
from .crud_background_tasks import (
    _calculate_completion_calories,
    recalculate_user_strength_scores,
    recalculate_user_fitness_score,
    populate_performance_logs,
    _send_post_workout_nutrition_nudge,
    _send_streak_celebration_if_milestone,
)
from .today import invalidate_today_workout_cache
# Trophy + milestone post-completion check. Wired as a background task so a
# failure inside the trophy logic never blocks the completion API response.
from ..trophy_triggers import check_workout_completion_trophies

router = APIRouter()
logger = get_logger(__name__)


@router.post("/{workout_id}/complete", response_model=WorkoutCompletionResponse)
async def complete_workout(
    request: Request,
    workout_id: str,
    background_tasks: BackgroundTasks,
    completion_method: str = Query(default="tracked", description="How the workout was completed: 'tracked' or 'marked_done'"),
    current_user: dict = Depends(get_current_user),
):
    """
    Mark a workout as completed with PR detection and strength score updates.

    This endpoint:
    1. Marks the workout as completed
    2. Detects any new personal records from the workout exercises
    3. Saves PRs to the database with AI-generated celebration messages
    4. Triggers background recalculation of strength scores
    """
    logger.info(f"Completing workout: id={workout_id}")
    try:
        db = get_supabase_db()
        supabase = db.client

        existing = db.get_workout(workout_id)
        if not existing:
            logger.warning(f"Workout not found: id={workout_id}")
            raise HTTPException(status_code=404, detail="Workout not found")
        verify_resource_ownership(current_user, existing, "Workout")

        user_id = existing.get("user_id")

        from datetime import timezone
        now = datetime.now(timezone.utc)
        update_data = {
            "is_completed": True,
            "completed_at": now.isoformat(),
            "last_modified_at": now.isoformat(),
            "last_modified_method": "completed",
            "completion_method": completion_method,
        }
        updated = db.update_workout(workout_id, update_data)
        workout = row_to_workout(updated)

        logger.info(f"Workout completed: id={workout_id}")

        log_workout_change(
            workout_id=workout_id,
            user_id=workout.user_id,
            change_type="completed",
            field_changed="is_completed",
            old_value=False,
            new_value={"is_completed": True, "completion_method": completion_method},
            change_source="user"
        )

        # Referral qualification (migration 1932) — only fires if:
        #   (a) this is the user's first-ever completed workout, AND
        #   (b) they signed up with a referral code
        # RPC is idempotent (COALESCE on first_workout_completed_at) and returns
        # {qualified: false} for users without a pending referral — cheap to call.
        # Capture is_first_workout BEFORE we update the timestamp, so we can
        # tell the frontend to fire the first-workout forecast sheet (W1).
        is_first_workout = False
        try:
            user_row = supabase.table("users") \
                .select("first_workout_completed_at,referred_by_code") \
                .eq("id", user_id) \
                .limit(1) \
                .execute()
            urow = (user_row.data or [{}])[0]
            is_first_workout = urow.get("first_workout_completed_at") is None
            has_referral = urow.get("referred_by_code") is not None
            if is_first_workout and has_referral:
                background_tasks.add_task(
                    lambda: supabase.rpc("mark_referral_qualified", {"p_referred_id": user_id}).execute()
                )
                logger.info(f"[Referrals] Qualifying referral for user={user_id}")
            elif is_first_workout:
                # Still set the first_workout timestamp for users without a referrer
                supabase.table("users").update(
                    {"first_workout_completed_at": now.isoformat()}
                ).eq("id", user_id).execute()
        except Exception as ref_err:
            logger.warning(f"[Referrals] qualification hook failed: {ref_err}")
            # Non-critical — don't block workout completion

        # PR Detection
        detected_prs: List[PersonalRecordInfo] = []

        try:
            pr_service = PersonalRecordsService()

            exercises = existing.get("exercises") or existing.get("exercises_json") or []
            if isinstance(exercises, str):
                exercises = json.loads(exercises)

            if exercises:
                existing_prs_response = supabase.table("personal_records").select("*").eq(
                    "user_id", user_id
                ).execute()

                existing_prs_by_exercise: Dict[str, List[Dict]] = {}
                for pr in (existing_prs_response.data or []):
                    exercise_key = pr_service._normalize_exercise_name(pr.get("exercise_name", ""))
                    if exercise_key not in existing_prs_by_exercise:
                        existing_prs_by_exercise[exercise_key] = []
                    existing_prs_by_exercise[exercise_key].append(pr)

                workout_exercises = []
                for ex in exercises:
                    sets = ex.get("sets", [])
                    if sets:
                        workout_exercises.append({
                            "exercise_name": ex.get("name", ""),
                            "exercise_id": ex.get("id") or ex.get("exercise_id"),
                            "workout_id": workout_id,
                            "sets": sets,
                        })

                new_prs = pr_service.detect_prs_in_workout(
                    workout_exercises=workout_exercises,
                    existing_prs_by_exercise=existing_prs_by_exercise,
                )

                logger.info(f"Detected {len(new_prs)} PRs in workout {workout_id}")

                # Generate every PR celebration in parallel — each Gemini call
                # is ~1–3s; running N sequentially was pushing the Save spinner
                # past 6s on PR-heavy workouts. gather() collects exceptions as
                # values so one failure doesn't skip the others.
                async def _celebrate(pr):
                    try:
                        return await ai_insights_service.generate_pr_celebration(
                            pr_data={
                                "exercise_name": pr.exercise_name,
                                "weight_kg": pr.weight_kg,
                                "reps": pr.reps,
                                "estimated_1rm_kg": pr.estimated_1rm_kg,
                                "previous_1rm_kg": pr.previous_1rm_kg,
                                "improvement_kg": pr.improvement_kg,
                                "improvement_percent": pr.improvement_percent,
                            },
                            user_profile={"id": user_id},
                        )
                    except Exception as e:
                        logger.warning(f"Failed to generate AI celebration: {e}", exc_info=True)
                        return pr.celebration_message

                celebrations = await asyncio.gather(*[_celebrate(pr) for pr in new_prs])

                now_iso = datetime.now().isoformat()
                pr_records = []
                for pr, ai_celebration in zip(new_prs, celebrations):
                    pr_records.append({
                        "user_id": user_id,
                        "exercise_name": pr.exercise_name,
                        "exercise_id": pr.exercise_id,
                        "muscle_group": pr.muscle_group,
                        "weight_kg": pr.weight_kg,
                        "reps": pr.reps,
                        "estimated_1rm_kg": pr.estimated_1rm_kg,
                        "set_type": pr.set_type,
                        "rpe": pr.rpe,
                        "achieved_at": now_iso,
                        "workout_id": workout_id,
                        "previous_weight_kg": pr.previous_weight_kg,
                        "previous_1rm_kg": pr.previous_1rm_kg,
                        "improvement_kg": pr.improvement_kg,
                        "improvement_percent": pr.improvement_percent,
                        "is_all_time_pr": pr.is_all_time_pr,
                        "celebration_message": ai_celebration,
                    })
                    detected_prs.append(PersonalRecordInfo(
                        exercise_name=pr.exercise_name,
                        weight_kg=pr.weight_kg,
                        reps=pr.reps,
                        estimated_1rm_kg=pr.estimated_1rm_kg,
                        previous_1rm_kg=pr.previous_1rm_kg,
                        improvement_kg=pr.improvement_kg,
                        improvement_percent=pr.improvement_percent,
                        is_all_time_pr=pr.is_all_time_pr,
                        celebration_message=ai_celebration,
                    ))

                # Single bulk insert instead of one round trip per PR.
                if pr_records:
                    supabase.table("personal_records").insert(pr_records).execute()

                logger.info(f"Saved {len(detected_prs)} PRs for workout {workout_id}")

        except Exception as e:
            logger.error(f"Error during PR detection: {e}", exc_info=True)

        # Background: Populate performance_logs
        workout_log_response = supabase.table("workout_logs").select(
            "id"
        ).eq("workout_id", workout_id).order("completed_at", desc=True).limit(1).execute()

        if workout_log_response.data:
            perf_log_workout_log_id = workout_log_response.data[0].get("id")
            background_tasks.add_task(
                populate_performance_logs,
                user_id=user_id,
                workout_id=workout_id,
                workout_log_id=perf_log_workout_log_id,
                exercises=exercises,
                supabase=supabase,
            )

        # Background: Recalculate Strength Scores and Fitness Score
        tz_str = resolve_timezone(request, db, user_id)
        background_tasks.add_task(recalculate_user_strength_scores, user_id=user_id, supabase=supabase, timezone_str=tz_str)
        background_tasks.add_task(recalculate_user_fitness_score, user_id=user_id, supabase=supabase, timezone_str=tz_str)

        # Background: Trophy + milestone awards (volume / time / consistency
        # / muscle-mastery / specific-exercise). The function inspects the
        # just-logged workout and idempotently awards anything newly earned.
        # Wired here so achievements unlock instantly on completion instead
        # of waiting for the next stats-screen refresh. Failures must never
        # block the response — `check_workout_completion_trophies` swallows
        # its own errors via its inner try/except branches.
        background_tasks.add_task(
            check_workout_completion_trophies,
            user_id=user_id,
            workout_data={"exercises": exercises},
        )

        await index_workout_to_rag(workout)

        # Performance Comparison
        performance_comparison: Optional[PerformanceComparisonInfo] = None

        try:
            comparison_service = PerformanceComparisonService()
            total_volume = 0.0
            total_sets = 0
            total_reps = 0

            # Pull the actual logged sets from workout_logs.sets_json — that's
            # the source of truth for what the user did, not the workouts.exercises
            # plan (which carries integer "sets" + target reps but no completion
            # state, so summing it gives planned volume, not performed). For
            # bodyweight workouts the plan often shapes `sets` as an int (e.g.
            # `{"sets": 3, "reps": 10}`) which the legacy aggregator dropped to
            # `[]`, producing the 0/0/0 stats grid the user reported.
            workout_log_response = supabase.table("workout_logs").select(
                "id, total_time_seconds, sets_json"
            ).eq("workout_id", workout_id).order("completed_at", desc=True).limit(1).execute()

            workout_log_id = None
            duration_seconds = 0
            logged_sets_json = None
            if workout_log_response.data:
                workout_log_id = workout_log_response.data[0].get("id")
                duration_seconds = workout_log_response.data[0].get("total_time_seconds", 0)
                logged_sets_json = workout_log_response.data[0].get("sets_json")

            # Decode legacy string-encoded JSON if needed.
            if isinstance(logged_sets_json, str):
                try:
                    logged_sets_json = json.loads(logged_sets_json)
                except (json.JSONDecodeError, TypeError):
                    logged_sets_json = None

            exercises = existing.get("exercises") or existing.get("exercises_json") or []
            if isinstance(exercises, str):
                exercises = json.loads(exercises)

            exercises_performance: List[Dict] = []

            if isinstance(logged_sets_json, list) and logged_sets_json:
                # New shape: flat list of per-set records (set_logging_mixin.dart
                # buildSetsJson). Group by exercise to feed the comparison
                # service and aggregate true totals.
                grouped: Dict[str, Dict[str, Any]] = {}
                for s in logged_sets_json:
                    if not isinstance(s, dict):
                        continue
                    ex_name = s.get("exercise_name") or s.get("name", "")
                    if not ex_name:
                        continue
                    bucket = grouped.setdefault(ex_name, {
                        "exercise_name": ex_name,
                        "exercise_id": s.get("exercise_id"),
                        "sets": [],
                    })
                    # Normalize the per-set shape so build_performance_summary
                    # finds reps + weight_kg under the keys it already reads.
                    bucket["sets"].append({
                        "completed": True,
                        "reps": s.get("reps") or s.get("reps_completed", 0),
                        "reps_completed": s.get("reps") or s.get("reps_completed", 0),
                        "weight_kg": s.get("weight_kg", 0) or 0,
                        "rpe": s.get("rpe"),
                        "rir": s.get("rir"),
                        "duration_seconds": s.get("set_duration_seconds"),
                    })
                for entry in grouped.values():
                    set_count = len(entry["sets"])
                    ex_reps = sum(int(x["reps"] or 0) for x in entry["sets"])
                    ex_volume = sum(
                        (int(x["reps"] or 0)) * float(x["weight_kg"] or 0)
                        for x in entry["sets"]
                    )
                    total_sets += set_count
                    total_reps += ex_reps
                    total_volume += ex_volume
                    exercises_performance.append(entry)
            else:
                # Fallback for older clients that didn't post sets_json: derive
                # from the planned exercises. Same code path as before, but we
                # also expand integer `sets` so bodyweight plans (sets=3, reps=10)
                # don't silently zero out.
                for ex in exercises:
                    sets = ex.get("sets", [])
                    if isinstance(sets, int):
                        # Expand into n placeholder sets using the exercise-level
                        # reps + weight (zero for bodyweight). Mark them completed
                        # since we have no actual log to disagree.
                        n = max(0, int(sets))
                        sets = [{
                            "completed": True,
                            "reps": ex.get("reps", 0) or 0,
                            "weight_kg": ex.get("weight_kg", ex.get("weight", 0)) or 0,
                        } for _ in range(n)]
                    elif not isinstance(sets, list):
                        sets = []
                    completed_sets = [s for s in sets if s.get("completed", True)]
                    ex_volume = sum(
                        (s.get("reps", 0) or s.get("reps_completed", 0)) * s.get("weight_kg", 0)
                        for s in completed_sets
                    )
                    ex_reps = sum(s.get("reps", 0) or s.get("reps_completed", 0) for s in completed_sets)
                    total_volume += ex_volume
                    total_sets += len(completed_sets)
                    total_reps += ex_reps
                    exercises_performance.append({
                        "exercise_name": ex.get("name", ""),
                        "exercise_id": ex.get("id") or ex.get("exercise_id"),
                        "sets": sets,
                    })

            calories_burned = _calculate_completion_calories(
                exercises=exercises, duration_seconds=duration_seconds,
                total_sets=total_sets, total_reps=total_reps,
                total_volume_kg=total_volume, workout_type=workout.type,
                difficulty=existing.get("difficulty"), user_id=user_id, supabase=supabase,
            )

            workout_stats = {
                "workout_name": workout.name, "workout_type": workout.type,
                "total_sets": total_sets, "total_reps": total_reps,
                "total_volume_kg": total_volume, "duration_seconds": duration_seconds,
                "calories": calories_burned, "new_prs_count": len(detected_prs),
                "completed_at": datetime.now().isoformat(),
            }

            if workout_log_id:
                workout_summary, exercise_summaries = comparison_service.build_performance_summary(
                    workout_log_id=workout_log_id, user_id=user_id,
                    workout_id=workout_id, exercises_performance=exercises_performance,
                    workout_stats=workout_stats,
                )
                try:
                    supabase.table("workout_performance_summary").upsert(workout_summary, on_conflict="workout_log_id").execute()
                except Exception as e:
                    logger.warning(f"Failed to store workout summary: {e}", exc_info=True)
                for ex_summary in exercise_summaries:
                    try:
                        supabase.table("exercise_performance_summary").upsert(ex_summary, on_conflict="workout_log_id,exercise_name").execute()
                    except Exception as e:
                        logger.warning(f"Failed to store exercise summary: {e}", exc_info=True)

            # Fetch previous performance for every exercise in parallel.
            # Each RPC was ~150–300 ms; on a 6-exercise workout that serial
            # loop was ~1.5s of blocking time on the Save spinner.
            def _fetch_prev(ex_name: str):
                return supabase.rpc(
                    "get_previous_exercise_performance",
                    {
                        "p_user_id": user_id,
                        "p_exercise_name": ex_name,
                        "p_current_workout_log_id": workout_log_id,
                        "p_limit": 1,
                    },
                ).execute()

            ex_names_ordered = [
                ex_perf.get("exercise_name", "") for ex_perf in exercises_performance
            ]
            prev_results = await asyncio.gather(
                *[
                    asyncio.to_thread(_fetch_prev, name) if name else asyncio.sleep(0, result=None)
                    for name in ex_names_ordered
                ]
            )

            exercise_comparisons: List[ExerciseComparisonInfo] = []
            for ex_perf, prev_response in zip(exercises_performance, prev_results):
                ex_name = ex_perf.get("exercise_name", "")
                if not ex_name:
                    continue
                previous_performances = (
                    prev_response.data if prev_response and prev_response.data else []
                )

                sets = ex_perf.get("sets", [])
                completed_sets = [s for s in sets if s.get("completed", True)]
                weights = [s.get("weight_kg", 0) for s in completed_sets if s.get("weight_kg", 0) > 0]
                reps_list = [s.get("reps", 0) or s.get("reps_completed", 0) for s in completed_sets]

                current_perf = {
                    "exercise_id": ex_perf.get("exercise_id"),
                    "total_sets": len(completed_sets), "total_reps": sum(reps_list),
                    "total_volume_kg": sum(r * w for r, w in zip(reps_list, weights) if w > 0),
                    "max_weight_kg": max(weights) if weights else None, "estimated_1rm_kg": None,
                }
                if completed_sets:
                    best_1rm = 0
                    for s in completed_sets:
                        reps = s.get("reps", 0) or s.get("reps_completed", 0)
                        weight = s.get("weight_kg", 0)
                        if weight > 0 and 0 < reps < 37:
                            set_1rm = weight * (36 / (37 - reps))
                            best_1rm = max(best_1rm, set_1rm)
                    if best_1rm > 0:
                        current_perf["estimated_1rm_kg"] = round(best_1rm, 2)

                comparison = comparison_service.compute_exercise_comparison(
                    exercise_name=ex_name, current_performance=current_perf,
                    previous_performances=previous_performances,
                )
                comparison.is_pr = any(pr.exercise_name.lower() == ex_name.lower() for pr in detected_prs)
                exercise_comparisons.append(ExerciseComparisonInfo(
                    exercise_name=comparison.exercise_name, exercise_id=comparison.exercise_id,
                    current_sets=comparison.current_sets, current_reps=comparison.current_reps,
                    current_volume_kg=comparison.current_volume_kg, current_max_weight_kg=comparison.current_max_weight_kg,
                    current_1rm_kg=comparison.current_1rm_kg, current_time_seconds=comparison.current_time_seconds,
                    previous_sets=comparison.previous_sets, previous_reps=comparison.previous_reps,
                    previous_volume_kg=comparison.previous_volume_kg, previous_max_weight_kg=comparison.previous_max_weight_kg,
                    previous_1rm_kg=comparison.previous_1rm_kg, previous_time_seconds=comparison.previous_time_seconds,
                    previous_date=comparison.previous_date,
                    volume_diff_kg=comparison.volume_diff_kg, volume_diff_percent=comparison.volume_diff_percent,
                    weight_diff_kg=comparison.weight_diff_kg, weight_diff_percent=comparison.weight_diff_percent,
                    rm_diff_kg=comparison.rm_diff_kg, rm_diff_percent=comparison.rm_diff_percent,
                    time_diff_seconds=comparison.time_diff_seconds, time_diff_percent=comparison.time_diff_percent,
                    reps_diff=comparison.reps_diff, sets_diff=comparison.sets_diff, status=comparison.status,
                ))

            improved_count = sum(1 for e in exercise_comparisons if e.status == 'improved')
            maintained_count = sum(1 for e in exercise_comparisons if e.status == 'maintained')
            declined_count = sum(1 for e in exercise_comparisons if e.status == 'declined')
            first_time_count = sum(1 for e in exercise_comparisons if e.status == 'first_time')

            if workout_log_id:
                prev_workout_response = supabase.table("workout_performance_summary").select("*").eq("user_id", user_id).neq("workout_log_id", workout_log_id).order("performed_at", desc=True).limit(1).execute()
                prev_workout_stats = prev_workout_response.data[0] if prev_workout_response.data else None
            else:
                prev_workout_response = supabase.table("workout_performance_summary").select("*").eq("user_id", user_id).order("performed_at", desc=True).limit(1).execute()
                prev_workout_stats = prev_workout_response.data[0] if prev_workout_response.data else None

            workout_comparison = comparison_service.compute_workout_comparison(current_stats=workout_stats, previous_stats=prev_workout_stats)

            performance_comparison = PerformanceComparisonInfo(
                workout_comparison=WorkoutComparisonInfo(
                    current_duration_seconds=workout_comparison.current_duration_seconds,
                    current_total_volume_kg=workout_comparison.current_total_volume_kg,
                    current_total_sets=workout_comparison.current_total_sets,
                    current_total_reps=workout_comparison.current_total_reps,
                    current_exercises=workout_comparison.current_exercises,
                    current_calories=workout_comparison.current_calories,
                    has_previous=workout_comparison.has_previous,
                    previous_duration_seconds=workout_comparison.previous_duration_seconds,
                    previous_total_volume_kg=workout_comparison.previous_total_volume_kg,
                    previous_total_sets=workout_comparison.previous_total_sets,
                    previous_total_reps=workout_comparison.previous_total_reps,
                    previous_performed_at=workout_comparison.previous_performed_at,
                    duration_diff_seconds=workout_comparison.duration_diff_seconds,
                    duration_diff_percent=workout_comparison.duration_diff_percent,
                    volume_diff_kg=workout_comparison.volume_diff_kg,
                    volume_diff_percent=workout_comparison.volume_diff_percent,
                    overall_status=workout_comparison.overall_status,
                ),
                exercise_comparisons=exercise_comparisons,
                improved_count=improved_count, maintained_count=maintained_count,
                declined_count=declined_count, first_time_count=first_time_count,
            )

            logger.info(f"Performance comparison: {improved_count} improved, {declined_count} declined, {maintained_count} maintained")

            # Telemetry only — don't block the Save response on it. Swallow
            # any failure inside the bg task instead of bubbling back.
            async def _log_view_safe(
                uid: str, wid: str, wlog_id: str,
                imp: int, dec: int, ft: int, ex_count: int,
                dur_diff: Optional[int], vol_diff_pct: Optional[float],
            ) -> None:
                try:
                    await user_context_service.log_performance_comparison_viewed(
                        user_id=uid, workout_id=wid, workout_log_id=wlog_id,
                        improved_count=imp, declined_count=dec,
                        first_time_count=ft, exercises_compared=ex_count,
                        duration_diff_seconds=dur_diff,
                        volume_diff_percentage=vol_diff_pct,
                    )
                except Exception as log_error:
                    logger.warning(
                        f"Failed to log performance comparison view: {log_error}",
                        exc_info=True,
                    )

            background_tasks.add_task(
                _log_view_safe,
                user_id, str(workout_id), workout_log_id or "",
                improved_count, declined_count, first_time_count, len(exercise_comparisons),
                workout_comparison.duration_diff_seconds,
                workout_comparison.volume_diff_percent,
            )

        except Exception as e:
            logger.error(f"Error calculating performance comparison: {e}", exc_info=True)

        # Background: Accountability Coach Nudges
        workout_name = existing.get("name", "your workout")
        background_tasks.add_task(_send_post_workout_nutrition_nudge, user_id=user_id, workout_name=workout_name)
        background_tasks.add_task(_send_streak_celebration_if_milestone, user_id=user_id)

        # Trophies + masteries recompute. Previously neither fired after
        # complete_workout — users could finish 10 sessions and still see
        # Lv.0 / "No badges". Spawned via asyncio.create_task (not
        # BackgroundTasks) because BaseHTTPMiddleware serializes
        # BackgroundTasks into the response timer — a single slow trophy
        # query had inflated one completion log to 30 minutes of
        # "response time". Helper swallows its own errors + enforces a
        # 60s timeout so it can never break the Save response.
        from services.mastery_writes import fire_trophy_check_detached
        fire_trophy_check_detached(user_id)

        if detected_prs:
            pr_count = len(detected_prs)
            message = f"Workout completed! You set {pr_count} new personal record{'s' if pr_count > 1 else ''}!"
        else:
            message = "Workout completed successfully!"

        # Invalidate /today cache so next poll reflects the completed state
        scheduled_date = str(existing.get("scheduled_date", ""))[:10] or None
        gym_profile_id = existing.get("gym_profile_id")
        await invalidate_today_workout_cache(user_id, gym_profile_id, scheduled_date)

        # N2 First-Workout-Done email — fire in background if this is the user's
        # first ever completed workout. Caller-side gate: count workout_logs,
        # require == 1. One-shot dedup via email_send_log.
        background_tasks.add_task(
            _maybe_send_first_workout_email,
            supabase=supabase,
            user_id=user_id,
            workout_name=workout.name,
            duration_seconds=duration_seconds,
        )

        # Server-side guaranteed XP award (fixes the leaderboard "completed
        # workout but 0 XP" bug — previously the Flutter client was the sole
        # caller of /xp/award-goal-xp, and any network/app-crash between
        # /complete and that call silently robbed the user of their 100 XP).
        # Mirrors the dedup-by-source-and-day logic from api/v1/xp.py so the
        # client's subsequent call becomes a harmless no-op.
        xp_awarded_flag = False
        xp_amount_awarded = 0
        try:
            xp_awarded_flag, xp_amount_awarded = _award_workout_complete_xp(
                supabase=supabase,
                request=request,
                db=db,
                user_id=user_id,
                workout_id=workout_id,
            )
        except Exception as xp_err:
            # XP award is non-critical to workout completion. Log, don't raise.
            logger.warning(f"[XP] inline workout_complete award failed: {xp_err}", exc_info=True)

        return WorkoutCompletionResponse(
            workout=workout, personal_records=detected_prs,
            performance_comparison=performance_comparison,
            strength_scores_updated=True, fitness_score_updated=True,
            completion_method=completion_method, message=message,
            is_first_workout=is_first_workout,  # W1: trigger forecast sheet
            xp_awarded=xp_awarded_flag,
            xp_amount=xp_amount_awarded,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to complete workout: {e}", exc_info=True)
        raise safe_internal_error(e, "crud")


def _award_workout_complete_xp(
    *, supabase, request: Request, db, user_id: str, workout_id: str,
) -> tuple[bool, int]:
    """
    Guarantee a `workout_complete` XP transaction exists for today.

    Returns `(awarded_this_call, xp_amount)`:
      - `(True, amount)` if this call inserted the transaction
      - `(False, 0)` if already claimed today (dedup hit) or on error
      - `(False, 0)` if the RPC didn't produce a transaction row

    Idempotency:
      - Source string `daily_goal_workout_complete` + user-local "today"
        window is the dedup key (mirrors api/v1/xp.py `award_goal_xp`).
      - If the Flutter client also calls POST /xp/award-goal-xp after
        /complete returns, that call will hit the same dedup and return
        `already_claimed=True` — no double-award.

    Also ensures a `user_xp` seed row exists so the `award_xp` RPC can
    increment `total_xp`.
    """
    from core.timezone_utils import (
        resolve_timezone,
        get_user_today,
        local_date_to_utc_range,
    )

    try:
        user_tz = resolve_timezone(request, db, user_id)
        today_str = get_user_today(user_tz)
        today_start_iso, today_end_iso = local_date_to_utc_range(today_str, user_tz)

        source = "daily_goal_workout_complete"
        xp_amount = 100  # matches goal_xp_amounts["workout_complete"] in xp.py

        # Seed user_xp row so award_xp RPC can update it
        try:
            supabase.table("user_xp").upsert(
                {
                    "user_id": user_id,
                    "total_xp": 0,
                    "current_level": 1,
                    "title": "Novice",
                    "trust_level": 1,
                },
                on_conflict="user_id",
                ignore_duplicates=True,
            ).execute()
        except Exception as seed_err:
            logger.warning(f"[XP] user_xp seed failed: {seed_err}")

        # Dedup check: already awarded today?
        existing = (
            supabase.table("xp_transactions")
            .select("id")
            .eq("user_id", user_id)
            .eq("source", source)
            .gte("created_at", today_start_iso)
            .lt("created_at", today_end_iso)
            .execute()
        )
        if existing.data and len(existing.data) > 0:
            logger.info(f"[XP] workout_complete already claimed today for user {user_id}")
            return (False, 0)

        # Call award_xp RPC (trust_level-aware; returns updated user_xp record)
        supabase.rpc(
            "award_xp",
            {
                "p_user_id": user_id,
                "p_xp_amount": xp_amount,
                "p_source": source,
                "p_source_id": workout_id,
                "p_description": "Daily goal: workout complete",
                "p_is_verified": True,  # server-awarded = verified
            },
        ).execute()

        # Read back the actual amount (accounts for trust-level multiplier)
        actual_amount = xp_amount
        try:
            recent = (
                supabase.table("xp_transactions")
                .select("xp_amount")
                .eq("user_id", user_id)
                .eq("source", source)
                .order("created_at", desc=True)
                .limit(1)
                .execute()
            )
            if recent.data:
                actual_amount = int(recent.data[0].get("xp_amount") or xp_amount)
        except Exception:
            pass

        logger.info(f"[XP] awarded {actual_amount} XP for workout_complete (user={user_id}, workout={workout_id})")
        return (True, actual_amount)
    except Exception as e:
        logger.warning(f"[XP] _award_workout_complete_xp failed: {e}", exc_info=True)
        return (False, 0)


async def _maybe_send_first_workout_email(
    *, supabase, user_id: str, workout_name: str, duration_seconds: int = 0,
):
    """Background task: send N2 first-workout-done email iff this is the first.

    Gate cascade (all must be true):
      - workouts_total == 1 (from workout_logs count)
      - email_preferences.workout_reminders != false
      - no prior "first_workout_done" row in email_send_log (one-shot)
    Any failure logs a warning and returns silently — never blocks the
    completion response.
    """
    try:
        # Must be exactly 1 completed workout (this one)
        logs = supabase.table("workout_logs") \
            .select("id") \
            .eq("user_id", user_id) \
            .limit(2) \
            .execute()
        if not logs.data or len(logs.data) != 1:
            return

        # Email prefs check
        prefs = supabase.table("email_preferences") \
            .select("workout_reminders") \
            .eq("user_id", user_id) \
            .limit(1) \
            .execute()
        if prefs.data and prefs.data[0].get("workout_reminders") is False:
            return

        # One-shot dedup — has this email ever fired for this user?
        prior = supabase.table("email_send_log") \
            .select("id") \
            .eq("user_id", user_id) \
            .eq("email_type", "first_workout_done") \
            .limit(1) \
            .execute()
        if prior.data:
            return

        # User row for email + name + timezone
        u = supabase.table("users") \
            .select("id, email, name, timezone") \
            .eq("id", user_id) \
            .limit(1) \
            .execute()
        if not u.data:
            return
        user = u.data[0]

        # Import lazily to avoid slowing every /complete request
        from services.email_service import get_email_service
        from services.email_helpers import first_name
        from api.v1.email_cron import _get_user_stats

        stats = _get_user_stats(supabase, user)
        email_svc = get_email_service()
        await email_svc.send_first_workout_done(
            to_email=user["email"],
            first_name_value=first_name(user),
            stats=stats,
            workout_name=workout_name,
            duration_min=max(1, int(duration_seconds // 60)),
        )
        # Record one-shot fire
        supabase.table("email_send_log").insert({
            "user_id": user_id,
            "email_type": "first_workout_done",
            "metadata": {"workout_name": workout_name},
        }).execute()
    except Exception as e:
        logger.warning(f"N2 first-workout email skipped for user {user_id}: {e}")


@router.post("/{workout_id}/uncomplete", response_model=Workout)
async def uncomplete_workout(workout_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Revert a workout that was marked as done (completion_method='marked_done').
    Cannot undo a fully tracked workout that has performance logs.
    """
    logger.info(f"Uncompleting workout: id={workout_id}")
    try:
        db = get_supabase_db()
        existing = db.get_workout(workout_id)
        if not existing:
            raise HTTPException(status_code=404, detail="Workout not found")
        if not existing.get("is_completed"):
            raise HTTPException(status_code=400, detail="Workout is not completed")
        if existing.get("completion_method") not in (None, "marked_done"):
            raise HTTPException(status_code=400, detail="Cannot undo a fully tracked workout. Only 'marked_done' workouts can be reverted.")
        if existing.get("completion_method") is None:
            raise HTTPException(status_code=400, detail="Cannot undo this workout. Only workouts marked as done (not tracked) can be reverted.")

        from datetime import timezone
        now = datetime.now(timezone.utc)
        update_data = {
            "is_completed": False, "completed_at": None, "completion_method": None,
            "last_modified_at": now.isoformat(), "last_modified_method": "uncompleted",
        }
        updated = db.update_workout(workout_id, update_data)
        workout = row_to_workout(updated)

        log_workout_change(
            workout_id=workout_id, user_id=workout.user_id,
            change_type="uncompleted", field_changed="is_completed",
            old_value=True, new_value=False, change_source="user"
        )

        logger.info(f"Workout uncompleted: id={workout_id}")

        # Invalidate /today cache so next poll reflects the uncompleted state
        scheduled_date = str(existing.get("scheduled_date", ""))[:10] or None
        gym_profile_id = existing.get("gym_profile_id")
        await invalidate_today_workout_cache(existing.get("user_id"), gym_profile_id, scheduled_date)

        return workout

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to uncomplete workout: {e}", exc_info=True)
        raise safe_internal_error(e, "crud")


@router.get("/{workout_id}/completion-summary", response_model=WorkoutSummaryResponse)
async def get_workout_completion_summary(workout_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get a combined summary of a completed workout for the View Summary screen.
    Returns workout details, performance comparison, personal records,
    and an AI coach summary. For 'marked_done' workouts, returns minimal data.
    """
    logger.info(f"Fetching workout summary: id={workout_id}")
    try:
        db = get_supabase_db()
        supabase = db.client

        existing = db.get_workout(workout_id)
        if not existing:
            raise HTTPException(status_code=404, detail="Workout not found")
        if not existing.get("is_completed"):
            raise HTTPException(status_code=400, detail="Workout is not completed")

        user_id = existing.get("user_id")
        completion_method = existing.get("completion_method")
        completed_at = existing.get("completed_at")

        workout_data = {
            "id": str(existing.get("id")), "name": existing.get("name"),
            "type": existing.get("type"), "difficulty": existing.get("difficulty"),
            "scheduled_date": str(existing.get("scheduled_date")),
            "exercises_json": existing.get("exercises_json") or existing.get("exercises") or [],
            "duration_minutes": existing.get("duration_minutes", 45),
            "completion_method": completion_method,
            "completed_at": str(completed_at) if completed_at else None,
        }

        if completion_method == "marked_done":
            return WorkoutSummaryResponse(
                workout=workout_data, performance_comparison=None, personal_records=[],
                coach_summary=f"Manually marked as done{' at ' + str(completed_at) if completed_at else ''}.",
                completion_method=completion_method, completed_at=str(completed_at) if completed_at else None,
            )

        # Get workout log
        workout_log_response = supabase.table("workout_logs").select(
            "id, total_time_seconds"
        ).eq("workout_id", workout_id).order("completed_at", desc=True).limit(1).execute()

        workout_log_id = None
        duration_seconds = 0
        if workout_log_response.data:
            workout_log_id = workout_log_response.data[0].get("id")
            duration_seconds = workout_log_response.data[0].get("total_time_seconds", 0)

        # Get per-set log data — return everything the active-workout client
        # writes so the summary screen can render notes (incl. audio/photo),
        # target deltas, set timing, and the logging-mode tier.
        set_logs = []
        if workout_log_id:
            try:
                perf_logs_response = supabase.table("performance_logs").select(
                    "exercise_name, set_number, reps_completed, weight_kg, rpe, rir, set_type, "
                    "notes, notes_audio_url, notes_photo_urls, "
                    "target_reps, target_weight_kg, failed_at_rep, recorded_at, started_at, "
                    "set_duration_seconds, rest_duration_seconds, logging_mode, "
                    "ai_input_source, is_ai_recommended_set_type, tempo, is_completed"
                ).eq("workout_log_id", workout_log_id).order("exercise_name").order("set_number").execute()
                for pl in perf_logs_response.data or []:
                    # `notes` may be TEXT[] (post-migration), a legacy single
                    # string, or null. Coerce to a list of non-empty strings.
                    raw_notes = pl.get("notes")
                    if raw_notes is None:
                        notes_list: List[str] = []
                    elif isinstance(raw_notes, list):
                        notes_list = [str(n).strip() for n in raw_notes if n and str(n).strip()]
                    elif isinstance(raw_notes, str):
                        notes_list = [raw_notes.strip()] if raw_notes.strip() else []
                    else:
                        notes_list = []

                    raw_photos = pl.get("notes_photo_urls")
                    if isinstance(raw_photos, list):
                        photos_list = [str(u) for u in raw_photos if u]
                    else:
                        photos_list = []

                    def _to_iso(val):
                        if val is None:
                            return None
                        # Supabase returns timestamps as ISO strings already.
                        return str(val) if not isinstance(val, str) else val

                    set_logs.append(SetLogInfo(
                        exercise_name=pl.get("exercise_name", ""),
                        set_number=pl.get("set_number", 0),
                        reps_completed=pl.get("reps_completed", 0),
                        weight_kg=float(pl.get("weight_kg", 0) or 0),
                        rpe=float(pl.get("rpe")) if pl.get("rpe") is not None else None,
                        rir=pl.get("rir"),
                        set_type=pl.get("set_type", "working"),
                        notes=notes_list,
                        notes_audio_url=pl.get("notes_audio_url"),
                        notes_photo_urls=photos_list,
                        target_reps=pl.get("target_reps"),
                        target_weight_kg=float(pl["target_weight_kg"]) if pl.get("target_weight_kg") is not None else None,
                        failed_at_rep=pl.get("failed_at_rep"),
                        recorded_at=_to_iso(pl.get("recorded_at")),
                        started_at=_to_iso(pl.get("started_at")),
                        set_duration_seconds=pl.get("set_duration_seconds"),
                        rest_duration_seconds=pl.get("rest_duration_seconds"),
                        logging_mode=pl.get("logging_mode"),
                        ai_input_source=pl.get("ai_input_source"),
                        is_ai_recommended_set_type=pl.get("is_ai_recommended_set_type"),
                        tempo=pl.get("tempo"),
                        is_completed=pl.get("is_completed"),
                    ))
            except Exception as e:
                logger.warning(f"Failed to fetch performance logs for summary: {e}", exc_info=True)

        # Get personal records
        prs_response = supabase.table("personal_records").select("*").eq("workout_id", workout_id).execute()
        personal_records = []
        for pr in (prs_response.data or []):
            personal_records.append(PersonalRecordInfo(
                exercise_name=pr.get("exercise_name", ""), weight_kg=pr.get("weight_kg", 0),
                reps=pr.get("reps", 0), estimated_1rm_kg=pr.get("estimated_1rm_kg", 0),
                previous_1rm_kg=pr.get("previous_1rm_kg"), improvement_kg=pr.get("improvement_kg"),
                improvement_percent=pr.get("improvement_percent"),
                is_all_time_pr=pr.get("is_all_time_pr", True), celebration_message=pr.get("celebration_message"),
            ))

        # Get performance comparison from stored summaries
        performance_comparison = None
        exercise_comparisons = []
        workout_comparison_info = None
        if workout_log_id:
            try:
                comparison_service = PerformanceComparisonService()
                wp_response = supabase.table("workout_performance_summary").select("*").eq("workout_log_id", workout_log_id).maybe_single().execute()
                ep_response = supabase.table("exercise_performance_summary").select("*").eq("workout_log_id", workout_log_id).execute()

                for ep in (ep_response.data or []):
                    exercise_name = ep.get("exercise_name", "")
                    try:
                        prev_response = supabase.table("exercise_performance_summary").select("*").eq("user_id", user_id).eq("exercise_name", exercise_name).neq("workout_log_id", workout_log_id).order("performed_at", desc=True).limit(1).execute()
                        previous_performances = prev_response.data or []
                    except Exception:
                        previous_performances = []

                    comparison = comparison_service.compute_exercise_comparison(
                        exercise_name=exercise_name, current_performance=ep, previous_performances=previous_performances,
                    )
                    exercise_comparisons.append(ExerciseComparisonInfo(
                        exercise_name=comparison.exercise_name, exercise_id=comparison.exercise_id,
                        current_sets=comparison.current_sets, current_reps=comparison.current_reps,
                        current_volume_kg=comparison.current_volume_kg, current_max_weight_kg=comparison.current_max_weight_kg,
                        current_1rm_kg=comparison.current_1rm_kg, current_time_seconds=comparison.current_time_seconds,
                        previous_sets=comparison.previous_sets, previous_reps=comparison.previous_reps,
                        previous_volume_kg=comparison.previous_volume_kg, previous_max_weight_kg=comparison.previous_max_weight_kg,
                        previous_1rm_kg=comparison.previous_1rm_kg, previous_time_seconds=comparison.previous_time_seconds,
                        previous_date=comparison.previous_date,
                        volume_diff_kg=comparison.volume_diff_kg, volume_diff_percent=comparison.volume_diff_percent,
                        weight_diff_kg=comparison.weight_diff_kg, weight_diff_percent=comparison.weight_diff_percent,
                        rm_diff_kg=comparison.rm_diff_kg, rm_diff_percent=comparison.rm_diff_percent,
                        time_diff_seconds=comparison.time_diff_seconds, time_diff_percent=comparison.time_diff_percent,
                        reps_diff=comparison.reps_diff, sets_diff=comparison.sets_diff, status=comparison.status,
                    ))

                improved_count = sum(1 for e in exercise_comparisons if e.status == 'improved')
                maintained_count = sum(1 for e in exercise_comparisons if e.status == 'maintained')
                declined_count = sum(1 for e in exercise_comparisons if e.status == 'declined')
                first_time_count = sum(1 for e in exercise_comparisons if e.status == 'first_time')

                wp_data = wp_response.data if wp_response and wp_response.data else {}
                try:
                    prev_wp_response = supabase.table("workout_performance_summary").select("*").eq("user_id", user_id).neq("workout_log_id", workout_log_id).order("performed_at", desc=True).limit(1).execute()
                except Exception:
                    prev_wp_response = None
                prev_wp_data = prev_wp_response.data[0] if prev_wp_response and prev_wp_response.data else None

                workout_comparison_result = comparison_service.compute_workout_comparison(current_stats=wp_data, previous_stats=prev_wp_data)

                workout_comparison_info = WorkoutComparisonInfo(
                    current_duration_seconds=workout_comparison_result.current_duration_seconds,
                    current_total_volume_kg=workout_comparison_result.current_total_volume_kg,
                    current_total_sets=workout_comparison_result.current_total_sets,
                    current_total_reps=workout_comparison_result.current_total_reps,
                    current_exercises=workout_comparison_result.current_exercises,
                    current_calories=workout_comparison_result.current_calories,
                    has_previous=workout_comparison_result.has_previous,
                    previous_duration_seconds=workout_comparison_result.previous_duration_seconds,
                    previous_total_volume_kg=workout_comparison_result.previous_total_volume_kg,
                    previous_total_sets=workout_comparison_result.previous_total_sets,
                    previous_total_reps=workout_comparison_result.previous_total_reps,
                    previous_performed_at=workout_comparison_result.previous_performed_at,
                    duration_diff_seconds=workout_comparison_result.duration_diff_seconds,
                    duration_diff_percent=workout_comparison_result.duration_diff_percent,
                    volume_diff_kg=workout_comparison_result.volume_diff_kg,
                    volume_diff_percent=workout_comparison_result.volume_diff_percent,
                    overall_status=workout_comparison_result.overall_status,
                )

                performance_comparison = PerformanceComparisonInfo(
                    workout_comparison=workout_comparison_info,
                    exercise_comparisons=exercise_comparisons,
                    improved_count=improved_count, maintained_count=maintained_count,
                    declined_count=declined_count, first_time_count=first_time_count,
                )
            except Exception as e:
                logger.warning(f"Failed to build performance comparison for summary: {e}", exc_info=True)

        # Generate AI coach summary (long-form) and hero_narrative (punchy
        # one-liner) in parallel — both share the same context but speak in
        # different voices.
        coach_summary = None
        hero_narrative = None
        try:
            exercises = existing.get("exercises") or existing.get("exercises_json") or []
            if isinstance(exercises, str):
                exercises = json.loads(exercises)

            exercise_details = []
            for ec in exercise_comparisons:
                detail = f"- {ec.exercise_name}: {ec.current_sets}x{ec.current_reps} @ {ec.current_max_weight_kg or 0:.1f}kg"
                if ec.status == 'improved' and ec.volume_diff_percent:
                    detail += f" (IMPROVED: volume +{ec.volume_diff_percent:.1f}%)"
                elif ec.status == 'declined' and ec.volume_diff_percent:
                    detail += f" (DECLINED: volume {ec.volume_diff_percent:.1f}%)"
                elif ec.status == 'first_time':
                    detail += " (first time)"
                exercise_details.append(detail)

            wc = workout_comparison_info
            total_vol = wc.current_total_volume_kg if wc else 0
            calories = wc.current_calories if wc else 0
            vol_change = f"{wc.volume_diff_percent:+.1f}%" if wc and wc.volume_diff_percent else "N/A"

            pr_details = [
                f"- {pr.exercise_name}: {pr.weight_kg:.1f}kg x {pr.reps} reps (1RM: {pr.estimated_1rm_kg:.1f}kg, +{pr.improvement_percent:.1f}%)"
                for pr in personal_records if pr.improvement_percent
            ] or ["None"]

            summary_prompt = (
                f"You are an expert fitness coach analyzing a completed workout. "
                f"Respond ONLY with valid JSON (no markdown, no code fences).\n\n"
                f"Workout: {existing.get('name')} ({existing.get('type')})\n"
                f"Duration: {duration_seconds // 60} minutes\n"
                f"Total Volume: {total_vol:.0f} kg (change: {vol_change})\n"
                f"Calories: {calories}\n\n"
                f"Exercises:\n" + "\n".join(exercise_details) + "\n\n"
                f"Personal Records:\n" + "\n".join(pr_details) + "\n\n"
                f"Respond with this JSON structure:\n"
                f'{{"highlights": ["specific positive callout 1", "specific positive callout 2"], '
                f'"areas_to_improve": ["specific improvement suggestion"], '
                f'"overall_rating": 8, '
                f'"summary": "2-3 sentence encouraging overall summary"}}\n\n'
                f"Rules:\n"
                f"- highlights: 2-3 bullet points mentioning specific exercises and numbers\n"
                f"- areas_to_improve: 0-2 items, only if exercises declined. Empty array if all improved\n"
                f"- overall_rating: 1-10 based on effort and progression\n"
                f"- summary: Personalized, encouraging, mention specific achievements. Under 60 words.\n"
                f"- No emojis anywhere"
            )

            # Punchy hero card — one sentence, anchored to a real delta.
            hero_prompt = (
                f"You are a concise fitness coach writing a ONE-LINE headline "
                f"for a post-workout hero card. Plain text, no JSON, no quotes, "
                f"no emojis.\n\n"
                f"Workout: {existing.get('name')}\n"
                f"Total Volume: {total_vol:.0f} kg ({vol_change} vs last)\n"
                f"New PRs: {len([p for p in personal_records if p.improvement_percent])}\n"
                f"Exercises improved: {improved_count}, declined: {declined_count}, first-time: {first_time_count}\n"
                f"Top PRs: " + "; ".join(pr_details[:2]) + "\n\n"
                f"Rules:\n"
                f"- Exactly ONE sentence, max 18 words.\n"
                f"- Anchor to a specific number or exercise from the data above "
                f"(e.g. a PR, a volume delta, a 'first time' exercise).\n"
                f"- Encouraging but not cheesy; skip generic phrases like "
                f"'great job' or 'you crushed it'.\n"
                f"- If the session declined vs last, acknowledge honestly "
                f"(e.g. 'Lighter session — use it to sharpen form before "
                f"next week').\n"
                f"- No emojis, no markdown, no hashtags, no exclamation "
                f"marks unless a PR was hit."
            )

            coach_summary, hero_narrative = await asyncio.gather(
                ai_insights_service.gemini.chat(user_message=summary_prompt),
                ai_insights_service.gemini.chat(user_message=hero_prompt),
                return_exceptions=True,
            )
            if isinstance(coach_summary, Exception):
                logger.warning(f"Failed to generate AI coach summary: {coach_summary}")
                coach_summary = "Great work completing your workout!"
            if isinstance(hero_narrative, Exception):
                logger.warning(f"Failed to generate hero narrative: {hero_narrative}")
                hero_narrative = None
            elif hero_narrative:
                # Defensive trim — strip stray quotes or trailing whitespace
                # the model sometimes returns despite the prompt.
                hero_narrative = hero_narrative.strip().strip('"').strip("'").strip()
        except Exception as e:
            logger.warning(f"Failed to generate AI coach summary: {e}", exc_info=True)
            coach_summary = "Great work completing your workout!"

        return WorkoutSummaryResponse(
            workout=workout_data, performance_comparison=performance_comparison,
            personal_records=personal_records, coach_summary=coach_summary,
            hero_narrative=hero_narrative,
            completion_method=completion_method, completed_at=str(completed_at) if completed_at else None,
            set_logs=set_logs,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get workout summary: {e}", exc_info=True)
        raise safe_internal_error(e, "crud")


@router.patch("/{workout_id}/exercise-sets")
async def update_exercise_sets(
    workout_id: str, request: UpdateExerciseSetsRequest,
    current_user: dict = Depends(get_current_user),
):
    """Update exercise sets for a completed workout (post-completion editing)."""
    logger.info(f"Updating exercise sets: workout={workout_id}, exercise_index={request.exercise_index}")
    try:
        db = get_supabase_db()
        supabase = db.client

        existing = db.get_workout(workout_id)
        if not existing:
            raise HTTPException(status_code=404, detail="Workout not found")
        verify_resource_ownership(current_user, existing, "Workout")

        exercises = existing.get("exercises") or existing.get("exercises_json") or []
        if isinstance(exercises, str):
            exercises = json.loads(exercises)

        if request.exercise_index < 0 or request.exercise_index >= len(exercises):
            raise HTTPException(status_code=400, detail="Invalid exercise index")

        exercise = exercises[request.exercise_index]
        exercise_name = exercise.get("name", "")

        # Coerce notes to a list to match the TEXT[] storage shape. Accepts
        # legacy single-string payloads from older clients, drops empties.
        def _coerce_notes(raw):
            if raw is None:
                return []
            if isinstance(raw, list):
                return [str(n).strip() for n in raw if n and str(n).strip()]
            if isinstance(raw, str) and raw.strip():
                return [raw.strip()]
            return []

        new_sets = []
        for s in request.sets:
            new_sets.append({
                "set_number": s.get("set_number", 1), "reps": s.get("reps", 0),
                "reps_completed": s.get("reps", 0), "weight_kg": s.get("weight_kg", 0),
                "rpe": s.get("rpe"), "completed": True, "set_type": s.get("set_type", "working"),
                "notes": _coerce_notes(s.get("notes")),
                "notes_audio_url": s.get("notes_audio_url"),
                "notes_photo_urls": s.get("notes_photo_urls") or [],
            })

        exercises[request.exercise_index]["sets"] = new_sets
        exercises[request.exercise_index]["sets_count"] = len(new_sets)

        update_data = {"exercises": exercises, "last_modified_at": datetime.now().isoformat(), "last_modified_method": "post_completion_edit"}
        db.update_workout(workout_id, update_data)

        workout_log_response = supabase.table("workout_logs").select("id").eq("workout_id", workout_id).order("completed_at", desc=True).limit(1).execute()

        if workout_log_response.data:
            wl_id = workout_log_response.data[0].get("id")
            supabase.table("performance_logs").delete().eq("workout_log_id", wl_id).eq("exercise_name", exercise_name).execute()

            user_id = existing.get("user_id")
            for s in request.sets:
                # Notes/audio/photos preserved alongside the edit so the
                # post-completion summary keeps the user's annotations
                # after a reps/weight correction. Notes coerced to TEXT[].
                set_notes = _coerce_notes(s.get("notes"))
                photos = s.get("notes_photo_urls")
                perf_record = {
                    "workout_log_id": wl_id, "user_id": user_id,
                    "exercise_id": exercise.get("id") or exercise.get("exercise_id"),
                    "exercise_name": exercise_name, "set_number": s.get("set_number", 1),
                    "reps_completed": s.get("reps", 0), "weight_kg": s.get("weight_kg", 0),
                    "rpe": s.get("rpe"), "is_completed": True, "set_type": s.get("set_type", "working"),
                    "recorded_at": datetime.now().isoformat(),
                    "target_weight_kg": float(s["target_weight_kg"]) if s.get("target_weight_kg") is not None else None,
                    "target_reps": int(s["target_reps"]) if s.get("target_reps") is not None else None,
                    "progression_model": s.get("progression_model"),
                    "notes": set_notes,
                    "notes_audio_url": s.get("notes_audio_url"),
                    "notes_photo_urls": photos if isinstance(photos, list) and photos else None,
                }
                supabase.table("performance_logs").insert(perf_record).execute()

            total_reps = sum(s.get("reps", 0) for s in request.sets)
            weights = [s.get("weight_kg", 0) for s in request.sets if s.get("weight_kg", 0) > 0]
            max_weight = max(weights) if weights else 0
            total_volume = sum(s.get("reps", 0) * s.get("weight_kg", 0) for s in request.sets)

            supabase.table("exercise_performance_summary").update({
                "total_sets": len(request.sets), "total_reps": total_reps,
                "total_volume_kg": total_volume, "max_weight_kg": max_weight,
            }).eq("workout_log_id", wl_id).eq("exercise_name", exercise_name).execute()

            all_ep = supabase.table("exercise_performance_summary").select("total_sets, total_reps, total_volume_kg").eq("workout_log_id", wl_id).execute()
            if all_ep.data:
                supabase.table("workout_performance_summary").update({
                    "total_sets": sum(e.get("total_sets", 0) for e in all_ep.data),
                    "total_reps": sum(e.get("total_reps", 0) for e in all_ep.data),
                    "total_volume_kg": sum(e.get("total_volume_kg", 0) for e in all_ep.data),
                }).eq("workout_log_id", wl_id).execute()

        logger.info(f"Updated exercise sets for workout {workout_id}, exercise {request.exercise_index}")
        return {"success": True, "message": "Exercise sets updated"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update exercise sets: {e}", exc_info=True)
        raise safe_internal_error(e, "crud")
