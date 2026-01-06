"""Saved and Scheduled Workouts API endpoints."""

from fastapi import APIRouter, HTTPException, Query
from typing import List, Optional
from datetime import datetime, date, timezone
import json

from models.saved_workouts import (
    SavedWorkout, SavedWorkoutCreate, SavedWorkoutUpdate, SavedWorkoutsResponse,
    ScheduledWorkout, ScheduledWorkoutCreate, ScheduledWorkoutUpdate, ScheduledWorkoutsResponse,
    SaveWorkoutFromActivity, DoWorkoutNow, ScheduleWorkoutRequest,
    MonthlyCalendar, CalendarWorkout, ScheduledWorkoutStatus,
    ExerciseTemplate,
)
from core.supabase_client import get_supabase
from services.social_rag_service import get_social_rag_service
from core.activity_logger import log_user_activity, log_user_error
from core.logger import get_logger

logger = get_logger(__name__)


def get_supabase_client():
    """Get Supabase client for database operations."""
    return get_supabase().client

router = APIRouter(prefix="/saved-workouts")


# ============================================================
# CHALLENGE TRACKING
# ============================================================

@router.post("/challenge/{activity_id}")
async def track_challenge_click(
    user_id: str,
    activity_id: str,
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
        print(f"⚠️ [Challenge] Failed to log to ChromaDB: {e}")

    print(f"✅ [Challenge] User {user_id} challenged activity {activity_id} (count: {new_count})")

    # Log challenge click
    await log_user_activity(
        user_id=user_id,
        action="challenge_accepted",
        endpoint=f"/api/v1/saved-workouts/challenge/{activity_id}",
        message=f"Accepted workout challenge",
        metadata={"activity_id": activity_id, "challenge_count": new_count},
        status_code=200
    )

    return {
        "challenge_count": new_count,
        "message": "Challenge tracked successfully"
    }


# ============================================================
# WORKOUT BADGES
# ============================================================

@router.get("/badges/{activity_id}")
async def get_workout_badges(activity_id: str):
    """
    Get badges for a workout activity.

    Returns badges like TRENDING, HALL OF FAME, MOST COPIED, BEAST MODE.

    Args:
        activity_id: Activity ID

    Returns:
        List of badges with metadata
    """
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


# ============================================================
# SAVED WORKOUTS
# ============================================================

@router.post("/save-from-activity", response_model=SavedWorkout)
async def save_workout_from_activity(
    user_id: str,
    request: SaveWorkoutFromActivity,
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
        raise HTTPException(status_code=500, detail="Failed to save workout")

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
        print(f"✅ [Saved Workouts] Logged save to ChromaDB")
    except Exception as e:
        print(f"⚠️ [Saved Workouts] Failed to log to ChromaDB: {e}")

    print(f"✅ [Saved Workouts] User {user_id} saved workout from activity {request.activity_id}")

    # Log workout save
    await log_user_activity(
        user_id=user_id,
        action="workout_saved",
        endpoint="/api/v1/saved-workouts/save-from-activity",
        message=f"Saved workout: {workout_name}",
        metadata={"saved_workout_id": saved_workout.id, "source_activity_id": request.activity_id, "workout_name": workout_name},
        status_code=200
    )

    return saved_workout


@router.get("/", response_model=SavedWorkoutsResponse)
async def get_saved_workouts(
    user_id: str,
    folder: Optional[str] = None,
    tag: Optional[str] = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
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


@router.get("/{workout_id}", response_model=SavedWorkout)
async def get_saved_workout(
    user_id: str,
    workout_id: str,
):
    """Get a specific saved workout."""
    supabase = get_supabase_client()

    result = supabase.table("saved_workouts_with_source").select("*").eq(
        "id", workout_id
    ).eq("user_id", user_id).execute()

    if not result.data:
        raise HTTPException(status_code=404, detail="Saved workout not found")

    return SavedWorkout(**result.data[0])


@router.put("/{workout_id}", response_model=SavedWorkout)
async def update_saved_workout(
    user_id: str,
    workout_id: str,
    update: SavedWorkoutUpdate,
):
    """Update a saved workout."""
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
        raise HTTPException(status_code=500, detail="Failed to update workout")

    return SavedWorkout(**result.data[0])


@router.delete("/{workout_id}")
async def delete_saved_workout(
    user_id: str,
    workout_id: str,
):
    """Delete a saved workout."""
    supabase = get_supabase_client()

    # Verify ownership
    check = supabase.table("saved_workouts").select("user_id").eq("id", workout_id).execute()
    if not check.data:
        raise HTTPException(status_code=404, detail="Saved workout not found")
    if check.data[0]["user_id"] != user_id:
        raise HTTPException(status_code=403, detail="Not authorized")

    supabase.table("saved_workouts").delete().eq("id", workout_id).execute()

    # Log workout deletion
    await log_user_activity(
        user_id=user_id,
        action="workout_deleted",
        endpoint=f"/api/v1/saved-workouts/{workout_id}",
        message=f"Deleted saved workout",
        metadata={"workout_id": workout_id},
        status_code=200
    )

    return {"message": "Saved workout deleted successfully"}


# ============================================================
# DO WORKOUT NOW
# ============================================================

@router.post("/do-now/{saved_workout_id}")
async def do_workout_now(
    user_id: str,
    saved_workout_id: str,
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

    print(f"✅ [Saved Workouts] User {user_id} starting workout {saved_workout_id}")

    # Log workout start
    await log_user_activity(
        user_id=user_id,
        action="saved_workout_started",
        endpoint=f"/api/v1/saved-workouts/do-now/{saved_workout_id}",
        message=f"Started saved workout: {saved_workout['workout_name']}",
        metadata={"saved_workout_id": saved_workout_id, "workout_name": saved_workout["workout_name"]},
        status_code=200
    )

    return workout_data


# ============================================================
# SCHEDULED WORKOUTS
# ============================================================

@router.post("/schedule", response_model=ScheduledWorkout)
async def schedule_workout(
    user_id: str,
    request: ScheduleWorkoutRequest,
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
        raise HTTPException(status_code=500, detail="Failed to schedule workout")

    print(f"✅ [Scheduled Workouts] User {user_id} scheduled workout for {request.scheduled_date}")

    # Log workout scheduling
    await log_user_activity(
        user_id=user_id,
        action="workout_scheduled",
        endpoint="/api/v1/saved-workouts/schedule",
        message=f"Scheduled workout: {workout_name} for {request.scheduled_date}",
        metadata={"scheduled_workout_id": result.data[0]["id"], "workout_name": workout_name, "scheduled_date": str(request.scheduled_date)},
        status_code=200
    )

    return ScheduledWorkout(**result.data[0])


@router.get("/scheduled/upcoming", response_model=ScheduledWorkoutsResponse)
async def get_upcoming_scheduled_workouts(
    user_id: str,
    days_ahead: int = Query(30, ge=1, le=365),
    limit: Optional[int] = Query(None, ge=1, le=100, description="Maximum number of workouts to return"),
):
    """Get upcoming scheduled workouts.

    Args:
        user_id: User ID to fetch workouts for
        days_ahead: Number of days to look ahead (default 30)
        limit: Maximum number of workouts to return (default unlimited)
    """
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


@router.get("/scheduled/month/{year}/{month}", response_model=MonthlyCalendar)
async def get_monthly_calendar(
    user_id: str,
    year: int,
    month: int,
):
    """Get calendar view for a specific month."""
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


@router.put("/scheduled/{scheduled_id}", response_model=ScheduledWorkout)
async def update_scheduled_workout(
    user_id: str,
    scheduled_id: str,
    update: ScheduledWorkoutUpdate,
):
    """Update a scheduled workout."""
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
        raise HTTPException(status_code=500, detail="Failed to update scheduled workout")

    return ScheduledWorkout(**result.data[0])


@router.delete("/scheduled/{scheduled_id}")
async def delete_scheduled_workout(
    user_id: str,
    scheduled_id: str,
):
    """Delete a scheduled workout."""
    supabase = get_supabase_client()

    # Verify ownership
    check = supabase.table("scheduled_workouts").select("user_id").eq("id", scheduled_id).execute()
    if not check.data:
        raise HTTPException(status_code=404, detail="Scheduled workout not found")
    if check.data[0]["user_id"] != user_id:
        raise HTTPException(status_code=403, detail="Not authorized")

    supabase.table("scheduled_workouts").delete().eq("id", scheduled_id).execute()

    return {"message": "Scheduled workout deleted successfully"}
