"""Saved and Scheduled Workouts API endpoints."""

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field, model_validator
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from typing import List, Optional, Dict, Any
from datetime import datetime, date, timezone
import asyncio
import json

from models.saved_workouts import (
    SavedWorkout, SavedWorkoutCreate, SavedWorkoutUpdate, SavedWorkoutsResponse,
    ScheduledWorkout, ScheduledWorkoutCreate, ScheduledWorkoutUpdate, ScheduledWorkoutsResponse,
    SaveWorkoutFromActivity, DoWorkoutNow, ScheduleWorkoutRequest,
    MonthlyCalendar, CalendarWorkout, ScheduledWorkoutStatus,
    ExerciseTemplate,
)
from models.workout_studio import SaveWorkoutFromWorkout
from core.supabase_client import get_supabase
from services.social_rag_service import get_social_rag_service
from core.activity_logger import log_user_activity, log_user_error
from core.logger import get_logger

logger = get_logger(__name__)


def get_supabase_client():
    """Get Supabase client for database operations."""
    return get_supabase().client

router = APIRouter(prefix="/saved-workouts")


async def _notify_workout_interaction(
    supabase, source_user_id: str, actor_user_id: str,
    activity_id: str, workout_name: str,
    action: str, title: str, body: str, extra_data: dict = None,
):
    """Send notification to workout author when someone interacts with their shared workout."""
    if source_user_id == actor_user_id:
        return  # Don't notify yourself

    # Get actor info
    actor = supabase.table("users").select("name, avatar_url").eq("id", actor_user_id).execute()
    actor_name = actor.data[0]["name"] if actor.data else "Someone"
    actor_avatar = actor.data[0].get("avatar_url") if actor.data else None

    # Check privacy
    privacy = supabase.table("user_privacy_settings").select(
        "notify_friend_activity"
    ).eq("user_id", source_user_id).execute()
    should_notify = privacy.data[0].get("notify_friend_activity", True) if privacy.data else True

    if not should_notify:
        return

    data = {"action": action, "workout_name": workout_name}
    if extra_data:
        data.update(extra_data)

    try:
        supabase.table("social_notifications").insert({
            "user_id": source_user_id,
            "type": "workout_shared",
            "from_user_id": actor_user_id,
            "from_user_name": actor_name,
            "from_user_avatar": actor_avatar,
            "reference_id": activity_id,
            "reference_type": "activity",
            "title": title,
            "body": body,
            "data": data,
            "is_read": False,
        }).execute()
    except Exception as e:
        logger.warning(f" [Notifications] Failed to notify {action}: {e}", exc_info=True)


# ============================================================
# AI IMPORT WORKOUT (photo / text / video → reviewable custom workout)
# ============================================================


class ImportAiWorkoutRequest(BaseModel):
    """Request body for POST /saved-workouts/import-ai.

    Exactly one `source` must be supplied with the appropriate payload:
      - source='photo' → s3_key required (runs synchronously, returns workout)
      - source='text'  → raw_text required (runs synchronously, returns workout)
      - source='video' → s3_key required (async — returns job_id to poll)
    """
    user_id: str = Field(..., max_length=100)
    source: str = Field(..., description="'photo' | 'text' | 'video'")
    s3_key: Optional[str] = Field(default=None, description="S3 key for photo/video")
    raw_text: Optional[str] = Field(default=None, description="Workout text for source='text'")
    user_hint: Optional[str] = Field(default=None, max_length=500, description="Optional disambiguation hint")

    @model_validator(mode="after")
    def _check_source_payload(self) -> "ImportAiWorkoutRequest":
        s = (self.source or "").lower().strip()
        if s not in ("photo", "text", "video"):
            raise ValueError("source must be one of: photo, text, video")
        self.source = s
        if s in ("photo", "video") and not self.s3_key:
            raise ValueError(f"s3_key is required when source='{s}'")
        if s == "text" and not (self.raw_text and self.raw_text.strip()):
            raise ValueError("raw_text is required when source='text'")
        return self


class ImportAiWorkoutExercise(BaseModel):
    """A single reviewed exercise in an AI-imported workout."""
    name: str = Field(..., max_length=200)
    sets: int = Field(default=3, ge=1, le=20)
    reps: Optional[int] = Field(default=None, ge=1, le=100)
    rest_seconds: Optional[int] = Field(default=60, ge=0, le=600)
    duration_seconds: Optional[int] = Field(default=None, ge=1, le=3600)
    weight_kg: Optional[float] = Field(default=None, ge=0, le=1000)
    muscle_group: Optional[str] = Field(default=None, max_length=100)
    notes: Optional[str] = Field(default=None, max_length=2000)


class ExtractedWorkout(BaseModel):
    """The reviewable workout returned by the extractor (photo/text sync path)."""
    name: str = Field(..., max_length=200)
    workout_type: str = Field(default="strength", max_length=50)
    difficulty: str = Field(default="medium", max_length=50)
    estimated_duration_minutes: int = Field(default=45, ge=1, le=480)
    exercises: List[ImportAiWorkoutExercise] = Field(..., min_length=1, max_length=100)
    confidence: Optional[float] = Field(default=None, ge=0.0, le=1.0)


class ImportAiWorkoutResponse(BaseModel):
    """Response from POST /saved-workouts/import-ai.

    photo/text → `workout` is populated (review then call import-ai/save).
    video      → `job_id` is populated; poll GET /media-jobs/{job_id}; the
                 completed result_json contains {"workout": <ExtractedWorkout>}.
    """
    workout: Optional[ExtractedWorkout] = None
    job_id: Optional[str] = None
    status: str = Field(default="completed")


class SaveAiWorkoutRequest(BaseModel):
    """Persist a reviewed AI-imported workout into the `workouts` table tagged
    generation_method='ai_import' so the frontend Custom pill shows it."""
    user_id: str = Field(..., max_length=100)
    name: str = Field(..., min_length=1, max_length=200)
    workout_type: str = Field(default="strength", max_length=50)
    difficulty: str = Field(default="medium", max_length=50)
    estimated_duration_minutes: int = Field(default=45, ge=1, le=480)
    exercises: List[ImportAiWorkoutExercise] = Field(..., min_length=1, max_length=100)
    scheduled_date: Optional[date] = Field(
        default=None,
        description="Date to file the workout under. Defaults to today (UTC) when omitted.",
    )
    source_url: Optional[str] = Field(default=None, max_length=2000)


class SaveAiWorkoutResponse(BaseModel):
    """Response from POST /saved-workouts/import-ai/save."""
    workout_id: str
    name: str
    generation_source: str = "ai_import"


def _extracted_to_workout_exercises(exercises: List[ImportAiWorkoutExercise]) -> List[Dict[str, Any]]:
    """Map reviewed exercises onto the `workouts.exercises_json` shape used by
    the active-workout screen + the rest of the workout pipeline."""
    out: List[Dict[str, Any]] = []
    for ex in exercises:
        is_timed = ex.duration_seconds is not None and (ex.reps is None)
        out.append({
            "name": ex.name,
            "sets": ex.sets,
            "reps": ex.reps if ex.reps is not None else 1,
            "weight_kg": ex.weight_kg,
            "rest_seconds": ex.rest_seconds if ex.rest_seconds is not None else 60,
            "duration_seconds": ex.duration_seconds,
            "is_timed": is_timed,
            "muscle_group": ex.muscle_group,
            "notes": ex.notes,
        })
    return out


@router.post("/import-ai", response_model=ImportAiWorkoutResponse, status_code=200)
async def import_ai_workout(
    request: ImportAiWorkoutRequest,
    current_user: dict = Depends(get_current_user),
):
    """Extract a structured workout from a photo/screenshot, pasted text, or a
    short video using AI.

    photo / text run synchronously and return the extracted workout for the
    client to REVIEW (nothing is persisted yet — the client edits then calls
    POST /saved-workouts/import-ai/save). video enqueues a `workout_import`
    media job and returns {job_id}; poll GET /media-jobs/{job_id} — the
    completed result_json carries {"workout": <ExtractedWorkout>}.
    """
    if str(current_user["id"]) != str(request.user_id):
        raise HTTPException(status_code=403, detail="Access denied")

    try:
        if request.source in ("photo", "text"):
            from services.ai_workout_extractor import get_ai_workout_extractor
            extractor = get_ai_workout_extractor()
            if request.source == "photo":
                payload = await extractor.extract_from_photo(
                    s3_key=request.s3_key, user_hint=request.user_hint,
                )
            else:
                payload = await extractor.extract_from_text(
                    raw_text=request.raw_text or "", user_hint=request.user_hint,
                )
            return ImportAiWorkoutResponse(
                workout=ExtractedWorkout(**payload),
                job_id=None,
                status="completed",
            )

        # video → async media job (mirrors custom_exercise_import).
        from services.media_job_service import get_media_job_service
        from services.media_job_runner import run_media_job

        media_job_service = get_media_job_service()
        job_id = media_job_service.create_job(
            user_id=request.user_id,
            job_type="workout_import",
            s3_keys=[request.s3_key or ""],
            mime_types=["video/mp4"],
            media_types=["video"],
            params={
                "user_id": request.user_id,
                "user_hint": request.user_hint,
                "source": "video",
            },
        )
        asyncio.create_task(run_media_job(job_id))
        logger.info(f"🎬 Enqueued workout_import job {job_id} for user {request.user_id}")
        return ImportAiWorkoutResponse(workout=None, job_id=job_id, status="pending")

    except HTTPException:
        raise
    except ValueError as ve:
        logger.warning(f"⚠️ AI workout import validation failure: {ve}")
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        logger.error(f"❌ Failed to AI-import workout: {e}", exc_info=True)
        raise safe_internal_error(e, "saved_workouts")


@router.post("/import-ai/save", response_model=SaveAiWorkoutResponse, status_code=200)
async def save_ai_workout(
    request: SaveAiWorkoutRequest,
    current_user: dict = Depends(get_current_user),
):
    """Persist a reviewed AI-imported workout into the `workouts` table tagged
    generation_method='ai_import' / generation_source='ai_import' so it shows
    under the frontend Custom pill (GET /workouts/?user_id=)."""
    if str(current_user["id"]) != str(request.user_id):
        raise HTTPException(status_code=403, detail="Access denied")

    from core.db import get_supabase_db

    db = get_supabase_db()
    try:
        exercises = _extracted_to_workout_exercises(request.exercises)
        scheduled = request.scheduled_date or datetime.now(timezone.utc).date()
        # workouts.scheduled_date is canonically NOON of the local day, not
        # midnight — scheduled.isoformat() ('YYYY-MM-DD') would land at 00:00Z
        # and mis-day the import for any user west of UTC. No FastAPI Request
        # here, so resolve tz from users.timezone.
        from core.timezone_utils import resolve_timezone, target_date_to_utc_iso
        _tz = resolve_timezone(None, db, request.user_id)
        scheduled_ts = target_date_to_utc_iso(scheduled.isoformat(), _tz)

        # Reuse the difficulty normaliser the Workout schema validator uses so a
        # stray 'beginner'/'advanced' never 500s the insert.
        from models.schemas import _coerce_workout_difficulty
        try:
            difficulty = _coerce_workout_difficulty(request.difficulty) or "medium"
        except ValueError:
            difficulty = "medium"

        workout_data = {
            "user_id": request.user_id,
            "name": request.name[:200],
            "type": (request.workout_type or "strength")[:50],
            "difficulty": difficulty,
            "scheduled_date": scheduled_ts,
            "exercises_json": exercises,
            "duration_minutes": request.estimated_duration_minutes,
            "generation_method": "ai_import",
            "generation_source": "ai_import",
            "generation_metadata": {
                "imported_via": "ai_workout_import",
                "source_url": request.source_url,
                "exercise_count": len(exercises),
            },
            # Manual/imported workouts coexist with the day's canonical workout.
            "is_current": False,
        }

        created = db.create_workout(workout_data)
        if not created:
            raise safe_internal_error(Exception("Insert returned no rows"), "saved_workouts")

        workout_id = str(created.get("id"))
        logger.info(
            f"🏋️ AI-imported workout saved: id={workout_id} "
            f"'{request.name}' ({len(exercises)} exercises) for user {request.user_id}"
        )

        try:
            await log_user_activity(
                user_id=request.user_id,
                action="workout_ai_imported",
                endpoint="/api/v1/saved-workouts/import-ai/save",
                message=f"AI-imported workout: {request.name}",
                metadata={"workout_id": workout_id, "exercise_count": len(exercises)},
                status_code=200,
            )
        except Exception as e:
            logger.error(f"Activity logging failed: {e}", exc_info=True, extra={"user_id_full": request.user_id, "failed_action": "workout_ai_imported"})

        return SaveAiWorkoutResponse(workout_id=workout_id, name=request.name)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Failed to save AI-imported workout: {e}", exc_info=True)
        raise safe_internal_error(e, "saved_workouts")


# ============================================================
# CHALLENGE TRACKING
# ============================================================

@router.post("/challenge/{activity_id}")
async def track_challenge_click(
    user_id: str,
    activity_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Track when user clicks 'BEAT THIS WORKOUT' button.
    Increments challenge_count in workout_shares.

    Args:
        user_id: User who accepted the challenge
        activity_id: Activity ID being challenged

    Returns:
        Updated challenge count
    """
    try:
        supabase = get_supabase_client()

        # Get or create workout_shares entry
        shares_result = supabase.table("workout_shares").select("*").eq(
            "activity_id", activity_id
        ).execute()

        if shares_result.data:
            # Update existing
            share_id = shares_result.data[0]["id"]
            new_count = shares_result.data[0]["challenge_count"] + 1

            supabase.table("workout_shares").update({
                "challenge_count": new_count,
                "updated_at": datetime.now(timezone.utc).isoformat(),
            }).eq("id", share_id).execute()

        else:
            # Create new workout_shares entry
            activity_result = supabase.table("activity_feed").select("user_id").eq(
                "id", activity_id
            ).execute()

            if not activity_result.data:
                raise HTTPException(status_code=404, detail="Activity not found")

            new_count = 1
            supabase.table("workout_shares").insert({
                "shared_by": activity_result.data[0]["user_id"],
                "activity_id": activity_id,
                "challenge_count": new_count,
                "is_public": True,
            }).execute()

        # Store challenge in ChromaDB for AI insights
        try:
            social_rag = get_social_rag_service()
            user_result = supabase.table("users").select("name").eq("id", user_id).execute()
            user_name = user_result.data[0]["name"] if user_result.data else "User"

            # Log challenge acceptance
            collection = social_rag.get_social_collection()
            collection.add(
                documents=[f"{user_name} accepted challenge for activity {activity_id}"],
                metadatas=[{
                    "user_id": user_id,
                    "activity_id": activity_id,
                    "interaction_type": "challenge",
                    "created_at": datetime.now(timezone.utc).isoformat(),
                }],
                ids=[f"challenge_{user_id}_{activity_id}_{datetime.now().timestamp()}"],
            )
        except Exception as e:
            logger.warning(f" [Challenge] Failed to log to ChromaDB: {e}", exc_info=True)

        logger.info(f" [Challenge] User {user_id} challenged activity {activity_id} (count: {new_count})")

        # Notify the workout author
        try:
            # Get source user from activity or shares
            source_user_id = None
            if shares_result.data:
                source_user_id = shares_result.data[0].get("shared_by")
            if not source_user_id:
                act_result = supabase.table("activity_feed").select("user_id").eq("id", activity_id).execute()
                if act_result.data:
                    source_user_id = act_result.data[0]["user_id"]
            if source_user_id:
                # Get actor name for notification body
                actor_info = supabase.table("users").select("name").eq("id", user_id).execute()
                actor_display = actor_info.data[0]["name"] if actor_info.data else "Someone"
                await _notify_workout_interaction(
                    supabase, source_user_id=source_user_id, actor_user_id=user_id,
                    activity_id=activity_id, workout_name="",
                    action="challenge_accepted", title="Challenge Accepted!",
                    body=f"{actor_display} accepted your workout challenge",
                )
        except Exception as e:
            logger.warning(f" [Challenge] Failed to send notification: {e}", exc_info=True)

        # Log challenge click
        try:
            await log_user_activity(
                user_id=user_id,
                action="challenge_accepted",
                endpoint=f"/api/v1/saved-workouts/challenge/{activity_id}",
                message=f"Accepted workout challenge",
                metadata={"activity_id": activity_id, "challenge_count": new_count},
                status_code=200
            )
        except Exception as e:
            logger.error(f"Activity logging failed: {e}", exc_info=True, extra={"user_id_full": user_id, "failed_action": "challenge_accepted"})

        return {
            "challenge_count": new_count,
            "message": "Challenge tracked successfully"
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in track_challenge_click: {e}", exc_info=True)
        raise safe_internal_error(e, "saved_workouts")


# ============================================================
# WORKOUT BADGES
# ============================================================

@router.get("/badges/{activity_id}")
async def get_workout_badges(activity_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get badges for a workout activity.

    Returns badges like TRENDING, HALL OF FAME, MOST COPIED, BEAST MODE.

    Args:
        activity_id: Activity ID

    Returns:
        List of badges with metadata
    """
    try:
        supabase = get_supabase_client()

        # Get workout_shares data
        shares_result = supabase.table("workout_shares").select("*").eq(
            "activity_id", activity_id
        ).execute()

        badges = []

        if shares_result.data:
            share = shares_result.data[0]

            # TRENDING badge
            if share.get("is_trending"):
                badges.append({
                    "type": "trending",
                    "label": "🔥 TRENDING",
                    "color": "orange",
                    "description": f"{share['share_count']} saves in last 7 days"
                })

            # HALL OF FAME badge
            if share.get("is_hall_of_fame") or share.get("share_count", 0) >= 100:
                badges.append({
                    "type": "hall_of_fame",
                    "label": "👑 HALL OF FAME",
                    "color": "gold",
                    "description": f"{share['share_count']} total saves"
                })

            # MOST COPIED badge
            if share.get("is_most_copied"):
                badges.append({
                    "type": "most_copied",
                    "label": "⭐ MOST COPIED",
                    "color": "cyan",
                    "description": "Top 10 this week"
                })

            # BEAST MODE badge
            if share.get("is_beast_mode") or share.get("challenge_count", 0) >= 50:
                badges.append({
                    "type": "beast_mode",
                    "label": "💀 BEAST MODE",
                    "color": "red",
                    "description": f"{share['challenge_count']} challenges accepted"
                })

        return {
            "activity_id": activity_id,
            "badges": badges,
            "share_count": shares_result.data[0]["share_count"] if shares_result.data else 0,
            "challenge_count": shares_result.data[0]["challenge_count"] if shares_result.data else 0,
            "completion_count": shares_result.data[0]["completion_count"] if shares_result.data else 0,
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in get_workout_badges: {e}", exc_info=True)
        raise safe_internal_error(e, "saved_workouts")


# ============================================================
# SAVED WORKOUTS
# ============================================================

@router.post("/save-from-activity", response_model=SavedWorkout)
async def save_workout_from_activity(
    user_id: str,
    request: SaveWorkoutFromActivity,
    current_user: dict = Depends(get_current_user),
):
    """
    Save a workout from a social feed activity to user's library.

    Args:
        user_id: User ID
        request: Activity ID and save options

    Returns:
        Saved workout

    Raises:
        404: Activity not found
        400: Activity has no workout data
    """
    try:
        supabase = get_supabase_client()

        # Get activity data
        activity_result = supabase.table("activity_feed").select(
            "*, users(name, avatar_url)"
        ).eq("id", request.activity_id).execute()

        if not activity_result.data:
            raise HTTPException(status_code=404, detail="Activity not found")

        activity = activity_result.data[0]
        activity_data = activity.get("activity_data", {})

        # Extract workout information
        workout_name = activity_data.get("workout_name")
        if not workout_name:
            raise HTTPException(status_code=400, detail="Activity does not contain workout data")

        exercises_performance = activity_data.get("exercises_performance", [])
        if not exercises_performance:
            raise HTTPException(status_code=400, detail="Activity has no exercise data")

        # Convert to exercise templates
        exercises = []
        for ex in exercises_performance:
            exercises.append({
                "name": ex.get("name", ""),
                "sets": ex.get("sets", 3),
                "reps": ex.get("reps", 10),
                "weight_kg": ex.get("weight_kg", 0),
                "rest_seconds": 60,
            })

        # Calculate metadata
        total_exercises = len(exercises)
        duration = activity_data.get("duration_minutes", total_exercises * 5)

        # Check if already saved
        existing = supabase.table("saved_workouts").select("id").eq(
            "user_id", user_id
        ).eq("source_activity_id", request.activity_id).execute()

        if existing.data:
            raise HTTPException(status_code=400, detail="Workout already saved")

        # Create saved workout
        result = supabase.table("saved_workouts").insert({
            "user_id": user_id,
            "source_activity_id": request.activity_id,
            "source_user_id": activity["user_id"],
            "workout_name": workout_name,
            "workout_description": f"Saved from {activity.get('users', {}).get('name', 'a friend')}'s workout",
            "exercises": exercises,
            "total_exercises": total_exercises,
            "estimated_duration_minutes": duration,
            "folder": request.folder or "From Friends",
            "tags": ["friend-workout", "social"],
            "notes": request.notes,
        }).execute()

        if not result.data:
            raise safe_internal_error(Exception("Failed to save workout"), "saved_workouts")

        saved_workout = SavedWorkout(**result.data[0])

        # Add source user info
        if activity.get("users"):
            saved_workout.source_user_name = activity["users"].get("name")
            saved_workout.source_user_avatar = activity["users"].get("avatar_url")

        # Store in ChromaDB for recommendations
        try:
            social_rag = get_social_rag_service()
            user_result = supabase.table("users").select("name").eq("id", user_id).execute()
            user_name = user_result.data[0]["name"] if user_result.data else "User"

            collection = social_rag.get_social_collection()
            collection.add(
                documents=[f"{user_name} saved {workout_name} from {saved_workout.source_user_name}"],
                metadatas=[{
                    "user_id": user_id,
                    "saved_workout_id": saved_workout.id,
                    "source_activity_id": request.activity_id,
                    "interaction_type": "save",
                    "workout_name": workout_name,
                    "created_at": datetime.now(timezone.utc).isoformat(),
                }],
                ids=[f"save_{saved_workout.id}"],
            )
            logger.info(f" [Saved Workouts] Logged save to ChromaDB")
        except Exception as e:
            logger.warning(f" [Saved Workouts] Failed to log to ChromaDB: {e}", exc_info=True)

        logger.info(f" [Saved Workouts] User {user_id} saved workout from activity {request.activity_id}")

        # Notify the workout author
        try:
            actor_info = supabase.table("users").select("name").eq("id", user_id).execute()
            actor_display = actor_info.data[0]["name"] if actor_info.data else "Someone"
            await _notify_workout_interaction(
                supabase, source_user_id=activity["user_id"], actor_user_id=user_id,
                activity_id=request.activity_id, workout_name=workout_name,
                action="saved", title="Workout Saved",
                body=f'{actor_display} saved your workout "{workout_name}"',
            )
        except Exception as e:
            logger.warning(f" [Saved Workouts] Failed to send notification: {e}", exc_info=True)

        # Log workout save
        try:
            await log_user_activity(
                user_id=user_id,
                action="workout_saved",
                endpoint="/api/v1/saved-workouts/save-from-activity",
                message=f"Saved workout: {workout_name}",
                metadata={"saved_workout_id": saved_workout.id, "source_activity_id": request.activity_id, "workout_name": workout_name},
                status_code=200
            )
        except Exception as e:
            logger.error(f"Activity logging failed: {e}", exc_info=True, extra={"user_id_full": user_id, "failed_action": "workout_saved"})

        return saved_workout
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in save_workout_from_activity: {e}", exc_info=True)
        raise safe_internal_error(e, "saved_workouts")


def _coerce_sets(val) -> int:
    """exercises_json `sets` may be an int (planned) or a list (logged)."""
    if isinstance(val, list):
        return max(1, len(val))
    if isinstance(val, int):
        return max(1, min(val, 20))
    return 1


def _workout_ex_to_template(ex: dict) -> dict:
    """Map a workout exercise -> a normalized, ExerciseTemplate-VALID dict.

    Extra keys are dropped by pydantic; structure (timed/superset/set_targets/
    media) is preserved so the saved copy renders and runs like the original.
    The result is routed through ExerciseTemplate so real-world scalar shapes
    (reps "8-12" range strings, equipment lists) are coerced to the canonical
    scalars BEFORE the dict is written to JSONB — guaranteeing the stored row
    round-trips back through SavedWorkout(**row) with no ValidationError. This
    is the single normalization chokepoint every save path shares."""
    mapped = {
        "name": ex.get("name", ""),
        "sets": _coerce_sets(ex.get("sets")),
        "reps": ex.get("reps"),
        "weight_kg": ex.get("weight_kg") or ex.get("weight"),
        "rest_seconds": ex.get("rest_seconds", 60),
        "duration_seconds": ex.get("duration_seconds"),
        "hold_seconds": ex.get("hold_seconds"),
        "notes": ex.get("notes"),
        "muscle_group": ex.get("muscle_group") or ex.get("body_part"),
        "equipment": ex.get("equipment"),
        "superset_group": ex.get("superset_group"),
        "superset_order": ex.get("superset_order"),
        "is_unilateral": ex.get("is_unilateral"),
        "is_timed": ex.get("is_timed"),
        "is_amrap": ex.get("is_amrap"),
        "is_drop_set": ex.get("is_drop_set"),
        "drop_set_count": ex.get("drop_set_count"),
        "drop_set_percentage": ex.get("drop_set_percentage"),
        "set_targets": ex.get("set_targets"),
        "gif_url": ex.get("gif_url"),
        "video_url": ex.get("video_url"),
        "image_url": ex.get("image_url"),
        "library_id": ex.get("library_id") or ex.get("exercise_id"),
    }
    return ExerciseTemplate.model_validate(mapped).model_dump(mode="json")


@router.post("/from-workout", response_model=SavedWorkout)
async def save_workout_from_workout(
    request: SaveWorkoutFromWorkout,
    current_user: dict = Depends(get_current_user),
):
    """Save any live/generated workout to the user's library (no social
    activity required). Duplicates are allowed (Google-style 'Copy of X');
    the name auto-suffixes on collision. The snapshot is independent of the
    source workout (deleting the source does not affect the saved copy)."""
    try:
        supabase = get_supabase_client()
        user_id = current_user["id"]

        wr = supabase.table("workouts").select("*").eq("id", request.workout_id).execute()
        if not wr.data:
            raise HTTPException(status_code=404, detail="Workout not found")
        workout = wr.data[0]
        if workout.get("user_id") != user_id:
            raise HTTPException(status_code=403, detail="Not your workout")

        raw_exercises = workout.get("exercises_json") or workout.get("exercises") or []
        if isinstance(raw_exercises, str):
            raw_exercises = json.loads(raw_exercises)
        exercises = [_workout_ex_to_template(e) for e in raw_exercises if e.get("name")]
        if not exercises:
            raise HTTPException(status_code=400, detail="Workout has no exercises to save")

        # Name (default "Copy of <name>"), auto-suffixed on collision.
        base_name = (request.name or f"Copy of {workout.get('name', 'Workout')}")[:200]
        name = base_name
        existing_names = {
            r["workout_name"] for r in (
                supabase.table("saved_workouts").select("workout_name")
                .eq("user_id", user_id).execute().data or []
            )
        }
        n = 2
        while name in existing_names:
            name = f"{base_name} ({n})"[:200]
            n += 1

        meta = workout.get("generation_metadata") or {}
        duration = workout.get("duration_minutes") or (len(exercises) * 5)
        result = supabase.table("saved_workouts").insert({
            "user_id": user_id,
            "workout_name": name,
            "workout_description": workout.get("description"),
            "exercises": exercises,
            "total_exercises": len(exercises),
            "estimated_duration_minutes": min(int(duration), 480) if duration else None,
            "folder": request.folder or "My Workouts",
            "tags": ["custom"],
            "notes": request.notes,
        }).execute()

        if not result.data:
            raise safe_internal_error(Exception("Failed to save workout"), "saved_workouts")

        saved = SavedWorkout(**result.data[0])
        try:
            await log_user_activity(
                user_id=user_id, action="workout_saved",
                endpoint="/api/v1/saved-workouts/from-workout",
                message=f"Saved workout: {name}",
                metadata={"saved_workout_id": saved.id, "source_workout_id": request.workout_id},
                status_code=200,
            )
        except Exception:
            pass
        return saved
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in save_workout_from_workout: {e}", exc_info=True)
        raise safe_internal_error(e, "saved_workouts")


@router.get("/", response_model=SavedWorkoutsResponse)
async def get_saved_workouts(
    user_id: str,
    folder: Optional[str] = None,
    tag: Optional[str] = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: dict = Depends(get_current_user),
):
    """
    Get user's saved workouts.

    Args:
        user_id: User ID
        folder: Optional filter by folder
        tag: Optional filter by tag
        page: Page number
        page_size: Items per page

    Returns:
        Paginated saved workouts
    """
    try:
        supabase = get_supabase_client()

        query = supabase.table("saved_workouts_with_source").select(
            "*", count="exact"
        ).eq("user_id", user_id).order("saved_at", desc=True)

        if folder:
            query = query.eq("folder", folder)
        if tag:
            query = query.contains("tags", [tag])

        # Pagination
        offset = (page - 1) * page_size
        query = query.range(offset, offset + page_size - 1)

        result = query.execute()

        workouts = [SavedWorkout(**row) for row in result.data]

        # Get unique folders
        folders_result = supabase.table("saved_workouts").select("folder").eq(
            "user_id", user_id
        ).execute()

        folders = list(set(row["folder"] for row in folders_result.data if row.get("folder")))

        return SavedWorkoutsResponse(
            workouts=workouts,
            total_count=result.count or 0,
            folders=sorted(folders),
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in get_saved_workouts: {e}", exc_info=True)
        raise safe_internal_error(e, "saved_workouts")


@router.get("/{workout_id}", response_model=SavedWorkout)
async def get_saved_workout(
    user_id: str,
    workout_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Get a specific saved workout."""
    try:
        supabase = get_supabase_client()

        result = supabase.table("saved_workouts_with_source").select("*").eq(
            "id", workout_id
        ).eq("user_id", user_id).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Saved workout not found")

        return SavedWorkout(**result.data[0])
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in get_saved_workout: {e}", exc_info=True)
        raise safe_internal_error(e, "saved_workouts")


@router.put("/{workout_id}", response_model=SavedWorkout)
async def update_saved_workout(
    user_id: str,
    workout_id: str,
    update: SavedWorkoutUpdate,
    current_user: dict = Depends(get_current_user),
):
    """Update a saved workout."""
    try:
        supabase = get_supabase_client()

        # Verify ownership
        check = supabase.table("saved_workouts").select("user_id").eq("id", workout_id).execute()
        if not check.data:
            raise HTTPException(status_code=404, detail="Saved workout not found")
        if check.data[0]["user_id"] != user_id:
            raise HTTPException(status_code=403, detail="Not authorized")

        # Build update dict
        update_data = {k: v for k, v in update.dict(exclude_unset=True).items() if v is not None}
        update_data["updated_at"] = datetime.now(timezone.utc).isoformat()

        result = supabase.table("saved_workouts").update(update_data).eq("id", workout_id).execute()

        if not result.data:
            raise safe_internal_error(Exception("Failed to update workout"), "saved_workouts")

        return SavedWorkout(**result.data[0])
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in update_saved_workout: {e}", exc_info=True)
        raise safe_internal_error(e, "saved_workouts")


@router.delete("/{workout_id}")
async def delete_saved_workout(
    user_id: str,
    workout_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Delete a saved workout."""
    try:
        supabase = get_supabase_client()

        # Verify ownership
        check = supabase.table("saved_workouts").select("user_id").eq("id", workout_id).execute()
        if not check.data:
            raise HTTPException(status_code=404, detail="Saved workout not found")
        if check.data[0]["user_id"] != user_id:
            raise HTTPException(status_code=403, detail="Not authorized")

        supabase.table("saved_workouts").delete().eq("id", workout_id).execute()

        # Log workout deletion
        try:
            await log_user_activity(
                user_id=user_id,
                action="workout_deleted",
                endpoint=f"/api/v1/saved-workouts/{workout_id}",
                message=f"Deleted saved workout",
                metadata={"workout_id": workout_id},
                status_code=200
            )
        except Exception as e:
            logger.error(f"Activity logging failed: {e}", exc_info=True, extra={"user_id_full": user_id, "failed_action": "workout_deleted"})

        return {"message": "Saved workout deleted successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in delete_saved_workout: {e}", exc_info=True)
        raise safe_internal_error(e, "saved_workouts")


# ============================================================
# DO WORKOUT NOW
# ============================================================

@router.post("/do-now/{saved_workout_id}")
async def do_workout_now(
    user_id: str,
    saved_workout_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Start a saved workout immediately.

    Returns workout data formatted for ActiveWorkoutScreen.

    Args:
        user_id: User ID
        saved_workout_id: Saved workout ID

    Returns:
        Workout data ready for workout session
    """
    try:
        supabase = get_supabase_client()

        # Get saved workout
        result = supabase.table("saved_workouts").select("*").eq(
            "id", saved_workout_id
        ).eq("user_id", user_id).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Saved workout not found")

        saved_workout = result.data[0]

        # Format for workout screen
        workout_data = {
            "id": saved_workout["id"],
            "name": saved_workout["workout_name"],
            "description": saved_workout.get("workout_description"),
            "exercises": saved_workout["exercises"],
            "total_exercises": saved_workout["total_exercises"],
            "estimated_duration_minutes": saved_workout.get("estimated_duration_minutes"),
            "source": "saved_workout",
            "source_id": saved_workout_id,
        }

        logger.info(f" [Saved Workouts] User {user_id} starting workout {saved_workout_id}")

        # Log workout start
        try:
            await log_user_activity(
                user_id=user_id,
                action="saved_workout_started",
                endpoint=f"/api/v1/saved-workouts/do-now/{saved_workout_id}",
                message=f"Started saved workout: {saved_workout['workout_name']}",
                metadata={"saved_workout_id": saved_workout_id, "workout_name": saved_workout["workout_name"]},
                status_code=200
            )
        except Exception as e:
            logger.error(f"Activity logging failed: {e}", exc_info=True, extra={"user_id_full": user_id, "failed_action": "saved_workout_started"})

        return workout_data
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in do_workout_now: {e}", exc_info=True)
        raise safe_internal_error(e, "saved_workouts")


# ============================================================
# SCHEDULED WORKOUTS
# ============================================================

@router.post("/schedule", response_model=ScheduledWorkout)
async def schedule_workout(
    user_id: str,
    request: ScheduleWorkoutRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Schedule a workout for a future date.

    Can schedule from:
    - A saved workout (saved_workout_id)
    - Directly from an activity (activity_id)

    Args:
        user_id: User ID
        request: Schedule request

    Returns:
        Scheduled workout
    """
    try:
        supabase = get_supabase_client()

        workout_name = None
        exercises = []

        if request.saved_workout_id:
            # Schedule from saved workout
            saved_result = supabase.table("saved_workouts").select("*").eq(
                "id", request.saved_workout_id
            ).eq("user_id", user_id).execute()

            if not saved_result.data:
                raise HTTPException(status_code=404, detail="Saved workout not found")

            saved = saved_result.data[0]
            workout_name = saved["workout_name"]
            exercises = saved["exercises"]

        elif request.activity_id:
            # Schedule directly from activity
            activity_result = supabase.table("activity_feed").select("*").eq(
                "id", request.activity_id
            ).execute()

            if not activity_result.data:
                raise HTTPException(status_code=404, detail="Activity not found")

            activity_data = activity_result.data[0].get("activity_data", {})
            workout_name = activity_data.get("workout_name")
            exercises_perf = activity_data.get("exercises_performance", [])

            for ex in exercises_perf:
                exercises.append({
                    "name": ex.get("name", ""),
                    "sets": ex.get("sets", 3),
                    "reps": ex.get("reps", 10),
                    "weight_kg": ex.get("weight_kg", 0),
                    "rest_seconds": 60,
                })
        else:
            raise HTTPException(status_code=400, detail="Must provide saved_workout_id or activity_id")

        if not workout_name or not exercises:
            raise HTTPException(status_code=400, detail="Invalid workout data")

        # Create scheduled workout
        result = supabase.table("scheduled_workouts").insert({
            "user_id": user_id,
            "saved_workout_id": request.saved_workout_id,
            "scheduled_date": request.scheduled_date.isoformat(),
            "scheduled_time": request.scheduled_time.isoformat() if request.scheduled_time else None,
            "workout_name": workout_name,
            "exercises": exercises,
            "reminder_enabled": request.reminder_enabled,
            "reminder_minutes_before": request.reminder_minutes_before,
            "notes": request.notes,
            "status": "scheduled",
        }).execute()

        if not result.data:
            raise safe_internal_error(Exception("Failed to schedule workout"), "saved_workouts")

        logger.info(f" [Scheduled Workouts] User {user_id} scheduled workout for {request.scheduled_date}")

        # Notify the workout author (only when scheduling from an activity)
        if request.activity_id:
            try:
                activity_for_notify = supabase.table("activity_feed").select("user_id").eq(
                    "id", request.activity_id
                ).execute()
                if activity_for_notify.data:
                    source_uid = activity_for_notify.data[0]["user_id"]
                    actor_info = supabase.table("users").select("name").eq("id", user_id).execute()
                    actor_display = actor_info.data[0]["name"] if actor_info.data else "Someone"
                    await _notify_workout_interaction(
                        supabase, source_user_id=source_uid, actor_user_id=user_id,
                        activity_id=request.activity_id, workout_name=workout_name,
                        action="scheduled", title="Workout Scheduled",
                        body=f'{actor_display} scheduled your workout "{workout_name}" for {request.scheduled_date}',
                        extra_data={"scheduled_date": str(request.scheduled_date)},
                    )
            except Exception as e:
                logger.warning(f" [Scheduled Workouts] Failed to send notification: {e}", exc_info=True)

        # Log workout scheduling
        try:
            await log_user_activity(
                user_id=user_id,
                action="workout_scheduled",
                endpoint="/api/v1/saved-workouts/schedule",
                message=f"Scheduled workout: {workout_name} for {request.scheduled_date}",
                metadata={"scheduled_workout_id": result.data[0]["id"], "workout_name": workout_name, "scheduled_date": str(request.scheduled_date)},
                status_code=200
            )
        except Exception as e:
            logger.error(f"Activity logging failed: {e}", exc_info=True, extra={"user_id_full": user_id, "failed_action": "workout_scheduled"})

        return ScheduledWorkout(**result.data[0])
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in schedule_workout: {e}", exc_info=True)
        raise safe_internal_error(e, "saved_workouts")


@router.get("/scheduled/by-date")
async def get_scheduled_by_date(
    user_id: str,
    date: str = Query(..., description="Date in YYYY-MM-DD"),
    current_user: dict = Depends(get_current_user),
):
    """Check for existing workouts scheduled on a specific date."""
    try:
        supabase = get_supabase_client()

        # Check scheduled_workouts table
        scheduled = supabase.table("scheduled_workouts").select(
            "id, workout_name, scheduled_time, status"
        ).eq("user_id", user_id).eq(
            "scheduled_date", date
        ).eq("status", "scheduled").execute()

        # Also check regular workouts table for that date
        workouts = supabase.table("workouts").select(
            "id, name"
        ).eq("user_id", user_id).eq(
            "scheduled_date", date
        ).execute()

        results = []
        for s in (scheduled.data or []):
            results.append({"workout_name": s["workout_name"], "source": "scheduled"})
        for w in (workouts.data or []):
            results.append({"workout_name": w["name"], "source": "plan"})

        return results
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in get_scheduled_by_date: {e}", exc_info=True)
        raise safe_internal_error(e, "saved_workouts")


@router.get("/scheduled/upcoming", response_model=ScheduledWorkoutsResponse)
async def get_upcoming_scheduled_workouts(
    user_id: str,
    days_ahead: int = Query(30, ge=1, le=365),
    limit: Optional[int] = Query(None, ge=1, le=100, description="Maximum number of workouts to return"),
    current_user: dict = Depends(get_current_user),
):
    """Get upcoming scheduled workouts.

    Args:
        user_id: User ID to fetch workouts for
        days_ahead: Number of days to look ahead (default 30)
        limit: Maximum number of workouts to return (default unlimited)
    """
    try:
        supabase = get_supabase_client()

        query = supabase.table("upcoming_scheduled_workouts").select(
            "*", count="exact"
        ).eq("user_id", user_id)

        # Apply limit if specified
        if limit:
            query = query.limit(limit)

        result = query.execute()

        workouts = [ScheduledWorkout(**row) for row in result.data]

        return ScheduledWorkoutsResponse(
            scheduled=workouts,
            total_count=result.count or 0,
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in get_upcoming_scheduled_workouts: {e}", exc_info=True)
        raise safe_internal_error(e, "saved_workouts")


@router.get("/scheduled/month/{year}/{month}", response_model=MonthlyCalendar)
async def get_monthly_calendar(
    user_id: str,
    year: int,
    month: int,
    current_user: dict = Depends(get_current_user),
):
    """Get calendar view for a specific month."""
    try:
        supabase = get_supabase_client()

        # Get all workouts for the month
        start_date = date(year, month, 1)
        if month == 12:
            end_date = date(year + 1, 1, 1)
        else:
            end_date = date(year, month + 1, 1)

        result = supabase.table("scheduled_workouts").select("*").eq(
            "user_id", user_id
        ).gte("scheduled_date", start_date.isoformat()).lt(
            "scheduled_date", end_date.isoformat()
        ).order("scheduled_date").execute()

        workouts = []
        total_scheduled = 0
        total_completed = 0

        for row in result.data:
            workouts.append(CalendarWorkout(
                id=row["id"],
                date=row["scheduled_date"],
                time=row.get("scheduled_time"),
                name=row["workout_name"],
                status=ScheduledWorkoutStatus(row["status"]),
                exercise_count=len(row.get("exercises", [])),
                estimated_duration=sum(ex.get("sets", 3) * 2 for ex in row.get("exercises", [])),
            ))

            if row["status"] == "scheduled":
                total_scheduled += 1
            elif row["status"] == "completed":
                total_completed += 1

        return MonthlyCalendar(
            year=year,
            month=month,
            workouts=workouts,
            total_scheduled=total_scheduled,
            total_completed=total_completed,
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in get_monthly_calendar: {e}", exc_info=True)
        raise safe_internal_error(e, "saved_workouts")


@router.put("/scheduled/{scheduled_id}", response_model=ScheduledWorkout)
async def update_scheduled_workout(
    user_id: str,
    scheduled_id: str,
    update: ScheduledWorkoutUpdate,
    current_user: dict = Depends(get_current_user),
):
    """Update a scheduled workout."""
    try:
        supabase = get_supabase_client()

        # Verify ownership
        check = supabase.table("scheduled_workouts").select("user_id").eq("id", scheduled_id).execute()
        if not check.data:
            raise HTTPException(status_code=404, detail="Scheduled workout not found")
        if check.data[0]["user_id"] != user_id:
            raise HTTPException(status_code=403, detail="Not authorized")

        # Build update dict
        update_data = {}
        for key, value in update.dict(exclude_unset=True).items():
            if value is not None:
                if isinstance(value, (date, datetime)):
                    update_data[key] = value.isoformat()
                elif isinstance(value, ScheduledWorkoutStatus):
                    update_data[key] = value.value
                else:
                    update_data[key] = value

        update_data["updated_at"] = datetime.now(timezone.utc).isoformat()

        # If marking as completed, set completed_at
        if update.status == ScheduledWorkoutStatus.COMPLETED:
            update_data["completed_at"] = datetime.now(timezone.utc).isoformat()

        result = supabase.table("scheduled_workouts").update(update_data).eq("id", scheduled_id).execute()

        if not result.data:
            raise safe_internal_error(Exception("Failed to update scheduled workout"), "saved_workouts")

        return ScheduledWorkout(**result.data[0])
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in update_scheduled_workout: {e}", exc_info=True)
        raise safe_internal_error(e, "saved_workouts")


@router.delete("/scheduled/{scheduled_id}")
async def delete_scheduled_workout(
    user_id: str,
    scheduled_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Delete a scheduled workout."""
    try:
        supabase = get_supabase_client()

        # Verify ownership
        check = supabase.table("scheduled_workouts").select("user_id").eq("id", scheduled_id).execute()
        if not check.data:
            raise HTTPException(status_code=404, detail="Scheduled workout not found")
        if check.data[0]["user_id"] != user_id:
            raise HTTPException(status_code=403, detail="Not authorized")

        supabase.table("scheduled_workouts").delete().eq("id", scheduled_id).execute()

        return {"message": "Scheduled workout deleted successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in delete_scheduled_workout: {e}", exc_info=True)
        raise safe_internal_error(e, "saved_workouts")
