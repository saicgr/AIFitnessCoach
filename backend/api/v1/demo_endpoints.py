"""Secondary endpoints for demo.  Sub-router included by main module.
Demo and Trial API endpoints.

These endpoints allow users to preview the app before signing up,
and track their engagement to understand conversion patterns.

This addresses the common complaint:
"One of those apps where you answer a bunch of questions to get a 'tailored plan',
but then hit a paywall to even see how the app works, let alone what your plan
might look like."
"""
from typing import Any, Dict, List, Optional
from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException, Query, Request
from pydantic import BaseModel
import logging
logger = logging.getLogger(__name__)
from core.db import get_supabase_db
from core.exceptions import safe_internal_error

from .demo_models import (
    PreviewPlanRequest,
    DemoInteraction,
    DemoSession,
    SessionConvertRequest,
    PersonalizedSampleWorkoutRequest,
    TourStartRequest,
    TourStepCompletedRequest,
    TourCompletedRequest,
    FullPreviewPlanRequest,
    TryWorkoutRequest,
    TryWorkoutCompleteRequest,
)

router = APIRouter()

@router.post("/tour/start")
@limiter.limit("5/hour")
async def start_app_tour(request: Request, body: TourStartRequest):
    """
    Start an app tour session.

    This endpoint creates a new tour session and returns tour configuration.
    For new users, it always shows the tour. For returning users from settings
    or deep links, it allows retaking the tour.
    """
    try:
        db = get_supabase_db()
        session_id = str(uuid.uuid4())

        should_show_tour = True

        # Check if user has already completed the tour (only for new_user source)
        if body.source == "new_user":
            if body.user_id:
                existing = db.client.table("app_tour_sessions").select(
                    "id, status"
                ).eq("user_id", body.user_id).eq("status", "completed").execute()

                if existing.data:
                    should_show_tour = False
            elif body.device_id:
                existing = db.client.table("app_tour_sessions").select(
                    "id, status"
                ).eq("device_id", body.device_id).eq("status", "completed").execute()

                if existing.data:
                    should_show_tour = False

        # Create tour session
        session_data = {
            "session_id": session_id,
            "user_id": body.user_id,
            "device_id": body.device_id,
            "source": body.source,
            "device_info": body.device_info or {},
            "app_version": body.app_version,
            "platform": body.platform,
            "status": "started",
            "steps_completed": [],
            "deep_links_clicked": [],
            "started_at": datetime.utcnow().isoformat(),
        }

        db.client.table("app_tour_sessions").insert(session_data).execute()

        # Log to user_context_logs if user_id provided
        if body.user_id:
            try:
                db.client.table("user_context_logs").insert({
                    "user_id": body.user_id,
                    "event_type": "app_tour_started",
                    "event_data": {
                        "session_id": session_id,
                        "source": body.source,
                        "platform": body.platform,
                    },
                }).execute()
            except Exception as e:
                logger.warning(f"Failed to log tour start to user_context_logs: {e}")

        return {
            "session_id": session_id,
            "should_show_tour": should_show_tour,
            "tour_config": DEFAULT_TOUR_CONFIG,
        }

    except Exception as e:
        logger.error(f"Failed to start app tour: {e}")
        raise safe_internal_error(e, "demo")


@router.post("/tour/step-completed")
@limiter.limit("30/hour")
async def complete_tour_step(request: Request, body: TourStepCompletedRequest):
    """
    Log tour step completion.

    Updates the session with completed step info and tracks
    any deep links that were clicked.
    """
    try:
        db = get_supabase_db()

        # Get current session
        result = db.client.table("app_tour_sessions").select("*").eq(
            "session_id", body.session_id
        ).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Tour session not found")

        session = result.data[0]

        # Update steps_completed array
        steps_completed = session.get("steps_completed", []) or []
        step_data = {
            "step_id": body.step_id,
            "completed_at": datetime.utcnow().isoformat(),
            "duration_seconds": body.duration_seconds,
            "action_taken": body.action_taken,
        }
        steps_completed.append(step_data)

        # Track deep_links_clicked
        deep_links_clicked = session.get("deep_links_clicked", []) or []
        if body.deep_link_target:
            deep_links_clicked.append({
                "step_id": body.step_id,
                "target": body.deep_link_target,
                "clicked_at": datetime.utcnow().isoformat(),
            })

        # Update session
        db.client.table("app_tour_sessions").update({
            "steps_completed": steps_completed,
            "deep_links_clicked": deep_links_clicked,
            "last_activity_at": datetime.utcnow().isoformat(),
        }).eq("session_id", body.session_id).execute()

        return {
            "status": "logged",
            "step_id": body.step_id,
            "total_steps_completed": len(steps_completed),
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to log tour step completion: {e}")
        raise safe_internal_error(e, "demo")


@router.post("/tour/completed")
@limiter.limit("5/hour")
async def complete_app_tour(request: Request, body: TourCompletedRequest):
    """
    Mark tour as completed or skipped.

    Calculates duration, updates session status, and logs
    to user_context_logs for analytics.
    """
    try:
        db = get_supabase_db()

        # Get current session
        result = db.client.table("app_tour_sessions").select("*").eq(
            "session_id", body.session_id
        ).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Tour session not found")

        session = result.data[0]

        # Calculate duration
        total_duration = body.total_duration_seconds
        if not total_duration and session.get("started_at"):
            try:
                started_at = datetime.fromisoformat(
                    session["started_at"].replace("Z", "+00:00")
                )
                total_duration = int(
                    (datetime.utcnow() - started_at.replace(tzinfo=None)).total_seconds()
                )
            except Exception as e:
                logger.warning(f"Failed to calculate tour duration: {e}")

        # Update session with completion data
        update_data = {
            "status": body.status,
            "completed_at": datetime.utcnow().isoformat(),
            "skip_step": body.skip_step,
            "demo_workout_started": body.demo_workout_started,
            "demo_workout_completed": body.demo_workout_completed,
            "plan_preview_viewed": body.plan_preview_viewed,
            "total_duration_seconds": total_duration,
        }

        # Merge deep_links_clicked with existing
        if body.deep_links_clicked:
            existing_links = session.get("deep_links_clicked", []) or []
            for link in body.deep_links_clicked:
                if link not in [dl.get("target") for dl in existing_links]:
                    existing_links.append({
                        "target": link,
                        "clicked_at": datetime.utcnow().isoformat(),
                    })
            update_data["deep_links_clicked"] = existing_links

        db.client.table("app_tour_sessions").update(update_data).eq(
            "session_id", body.session_id
        ).execute()

        # Log to user_context_logs
        user_id = session.get("user_id")
        if user_id:
            try:
                db.client.table("user_context_logs").insert({
                    "user_id": user_id,
                    "event_type": f"app_tour_{body.status}",
                    "event_data": {
                        "session_id": body.session_id,
                        "skip_step": body.skip_step,
                        "demo_workout_started": body.demo_workout_started,
                        "demo_workout_completed": body.demo_workout_completed,
                        "total_duration_seconds": total_duration,
                        "deep_links_clicked": body.deep_links_clicked,
                    },
                }).execute()
            except Exception as e:
                logger.warning(f"Failed to log tour completion to user_context_logs: {e}")

        # Update ui_onboarding_state JSONB if user_id exists
        if user_id:
            try:
                # Get current user data
                user_result = db.client.table("users").select(
                    "ui_onboarding_state"
                ).eq("id", user_id).execute()

                if user_result.data:
                    current_state = user_result.data[0].get("ui_onboarding_state", {}) or {}
                    current_state["app_tour_completed"] = body.status == "completed"
                    current_state["app_tour_skipped"] = body.status == "skipped"
                    current_state["app_tour_completed_at"] = datetime.utcnow().isoformat()

                    db.client.table("users").update({
                        "ui_onboarding_state": current_state,
                    }).eq("id", user_id).execute()
            except Exception as e:
                logger.warning(f"Failed to update ui_onboarding_state: {e}")

        return {
            "status": body.status,
            "total_duration_seconds": total_duration,
            "steps_completed": len(session.get("steps_completed", []) or []),
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to complete app tour: {e}")
        raise safe_internal_error(e, "demo")


@router.get("/tour/status/{identifier}")
async def get_tour_status(
    identifier: str,
    identifier_type: str = Query("user_id", description="Type of identifier: user_id or device_id"),
):
    """
    Get tour status for a user or device.

    Returns whether the user/device has completed the tour,
    total tour sessions, and latest session info.
    """
    try:
        db = get_supabase_db()

        # Validate identifier_type
        if identifier_type not in ["user_id", "device_id"]:
            raise HTTPException(
                status_code=400,
                detail="identifier_type must be 'user_id' or 'device_id'"
            )

        # Query sessions for this identifier
        result = db.client.table("app_tour_sessions").select("*").eq(
            identifier_type, identifier
        ).order("started_at", desc=True).execute()

        sessions = result.data or []

        has_completed_tour = any(
            s.get("status") == "completed" for s in sessions
        )

        latest_session = sessions[0] if sessions else None

        # Determine if we should show the tour
        should_show_tour = not has_completed_tour

        return {
            "identifier": identifier,
            "identifier_type": identifier_type,
            "has_completed_tour": has_completed_tour,
            "total_tour_sessions": len(sessions),
            "latest_session": {
                "session_id": latest_session.get("session_id"),
                "status": latest_session.get("status"),
                "source": latest_session.get("source"),
                "started_at": latest_session.get("started_at"),
                "completed_at": latest_session.get("completed_at"),
                "steps_completed": len(latest_session.get("steps_completed", []) or []),
            } if latest_session else None,
            "should_show_tour": should_show_tour,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get tour status: {e}")
        raise safe_internal_error(e, "demo")


@router.get("/tour/analytics")
async def get_tour_analytics(
    days: int = Query(30, ge=1, le=90, description="Number of days to analyze"),
    source: Optional[str] = Query(None, description="Filter by source"),
    platform: Optional[str] = Query(None, description="Filter by platform"),
    admin: dict = Depends(get_admin_user),  # SECURITY: Admin-only
):
    """
    Get tour analytics (admin endpoint).

    Returns aggregated analytics about tour completion rates,
    step drop-off points, and engagement metrics.
    """
    try:
        db = get_supabase_db()

        # Try to get data from tour_analytics view first
        try:
            result = db.client.from_("tour_analytics").select("*").execute()
            if result.data:
                analytics = result.data[0] if result.data else {}
                return {
                    "period_days": days,
                    "source_filter": source,
                    "platform_filter": platform,
                    "analytics": analytics,
                }
        except Exception:
            # View doesn't exist, calculate manually
            pass

        # Calculate analytics from app_tour_sessions table
        cutoff_date = (datetime.utcnow() - timedelta(days=days)).isoformat()

        # Build query
        query = db.client.table("app_tour_sessions").select("*").gte(
            "started_at", cutoff_date
        )

        if source:
            query = query.eq("source", source)
        if platform:
            query = query.eq("platform", platform)

        result = query.execute()
        sessions = result.data or []

        # Calculate metrics
        total_sessions = len(sessions)
        completed_sessions = sum(1 for s in sessions if s.get("status") == "completed")
        skipped_sessions = sum(1 for s in sessions if s.get("status") == "skipped")

        # Calculate step completion rates
        step_completions = {}
        for session in sessions:
            for step in (session.get("steps_completed") or []):
                step_id = step.get("step_id", "unknown")
                step_completions[step_id] = step_completions.get(step_id, 0) + 1

        # Calculate average duration
        durations = [
            s.get("total_duration_seconds")
            for s in sessions
            if s.get("total_duration_seconds")
        ]
        avg_duration = sum(durations) / len(durations) if durations else 0

        # Demo workout engagement
        demo_started = sum(1 for s in sessions if s.get("demo_workout_started"))
        demo_completed = sum(1 for s in sessions if s.get("demo_workout_completed"))

        # Deep link engagement
        total_deep_links = sum(
            len(s.get("deep_links_clicked") or [])
            for s in sessions
        )

        # Source breakdown
        source_breakdown = {}
        for session in sessions:
            src = session.get("source", "unknown")
            source_breakdown[src] = source_breakdown.get(src, 0) + 1

        # Platform breakdown
        platform_breakdown = {}
        for session in sessions:
            plat = session.get("platform", "unknown")
            platform_breakdown[plat] = platform_breakdown.get(plat, 0) + 1

        return {
            "period_days": days,
            "source_filter": source,
            "platform_filter": platform,
            "analytics": {
                "total_sessions": total_sessions,
                "completed_sessions": completed_sessions,
                "skipped_sessions": skipped_sessions,
                "completion_rate": round(
                    completed_sessions / total_sessions * 100, 2
                ) if total_sessions > 0 else 0,
                "skip_rate": round(
                    skipped_sessions / total_sessions * 100, 2
                ) if total_sessions > 0 else 0,
                "average_duration_seconds": round(avg_duration, 1),
                "step_completion_rates": {
                    step_id: round(count / total_sessions * 100, 2)
                    for step_id, count in step_completions.items()
                } if total_sessions > 0 else {},
                "demo_workout_engagement": {
                    "started": demo_started,
                    "completed": demo_completed,
                    "start_rate": round(
                        demo_started / total_sessions * 100, 2
                    ) if total_sessions > 0 else 0,
                    "completion_rate": round(
                        demo_completed / demo_started * 100, 2
                    ) if demo_started > 0 else 0,
                },
                "deep_link_engagement": {
                    "total_clicks": total_deep_links,
                    "avg_per_session": round(
                        total_deep_links / total_sessions, 2
                    ) if total_sessions > 0 else 0,
                },
                "source_breakdown": source_breakdown,
                "platform_breakdown": platform_breakdown,
            },
        }

    except Exception as e:
        logger.error(f"Failed to get tour analytics: {e}")
        raise safe_internal_error(e, "demo")


# ============================================================================
# ENHANCED PREVIEW WORKOUT ENDPOINTS
# ============================================================================


class FullPreviewPlanRequest(BaseModel):
    """Request for generating a full 4-week preview plan with AI."""
    goals: List[str]
    fitness_level: str  # beginner, intermediate, advanced
    equipment: List[str]
    days_per_week: int
    training_split: Optional[str] = "push_pull_legs"
    session_id: Optional[str] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    height_cm: Optional[float] = None
    weight_kg: Optional[float] = None


class TryWorkoutRequest(BaseModel):
    """Request to try a demo workout."""
    session_id: str
    workout_id: str  # demo workout ID like "demo-beginner-full-body"
    started_at: Optional[str] = None


class TryWorkoutCompleteRequest(BaseModel):
    """Request when demo workout is completed."""
    session_id: str
    workout_id: str
    duration_seconds: int
    exercises_completed: int
    exercises_total: int
    feedback: Optional[str] = None  # too_easy, just_right, too_hard


@router.get("/preview-workout/{day}")
async def get_preview_workout(
    day: int,
    session_id: Optional[str] = Query(None, description="Demo session ID"),
    fitness_level: str = Query("intermediate", description="Fitness level"),
    training_split: str = Query("push_pull_legs", description="Training split"),
):
    """
    Get a specific day's workout from the preview plan.

    This endpoint does NOT require authentication and returns the full
    workout details for a specific day.

    Args:
        day: Day number (1-7)
        session_id: Optional session ID for tracking
        fitness_level: User's fitness level
        training_split: Training split type

    Returns:
        Full workout with exercises, sets, reps, and instructions
    """
    try:
        if day < 1 or day > 7:
            raise HTTPException(status_code=400, detail="Day must be between 1 and 7")

        # Get workout template based on training split
        templates = CURATED_TEMPLATES.get(training_split, CURATED_TEMPLATES["full_body"])
        template = templates[(day - 1) % len(templates)]

        # Get more detailed exercises for this day
        exercises = []
        for muscle in template["focus"]:
            muscle_lower = muscle.lower()
            if muscle_lower in CURATED_EXERCISES:
                for ex in CURATED_EXERCISES[muscle_lower]:
                    exercise = ex.copy()
                    # Add more detail for preview
                    exercise["id"] = f"preview-{muscle_lower}-{len(exercises)}"
                    exercise["instructions"] = _get_exercise_instructions(ex["name"])
                    exercise["rest_seconds"] = 60 if fitness_level == "beginner" else 45
                    exercise["tempo"] = "2-1-2" if fitness_level == "beginner" else "2-0-2"
                    exercises.append(exercise)

        workout = {
            "id": f"preview-day-{day}",
            "day": day,
            "name": template["name"],
            "focus_muscles": template["focus"],
            "workout_type": template["type"],
            "fitness_level": fitness_level,
            "exercises": exercises,
            "duration_minutes": 30 + (len(exercises) * 5),
            "estimated_calories": 150 + (len(exercises) * 30),
            "warmup": _get_preview_warmup(template["focus"]),
            "cooldown": _get_preview_cooldown(),
        }

        # Log the preview view
        if session_id:
            try:
                db = get_supabase_db()
                db.client.table("demo_interactions").insert({
                    "session_id": session_id,
                    "action_type": "preview_workout_viewed",
                    "screen": f"preview_day_{day}",
                    "metadata": {
                        "day": day,
                        "workout_name": template["name"],
                        "exercise_count": len(exercises),
                        "fitness_level": fitness_level,
                    }
                }).execute()
            except Exception as e:
                logger.warning(f"Failed to log preview workout view: {e}")

        return {
            "workout": workout,
            "preview_info": {
                "is_preview": True,
                "full_access_features": [
                    "AI-personalized exercise selection",
                    "Video demonstrations for each exercise",
                    "Real-time workout tracking",
                    "Progress analytics",
                    "Chat with AI coach",
                ],
                "cta": "Start your 7-day free trial to unlock all features!",
            }
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get preview workout: {e}")
        raise safe_internal_error(e, "demo")


@router.post("/try-workout")
@limiter.limit("5/hour")
async def start_try_workout(request: Request, body: TryWorkoutRequest):
    """
    Let users try ONE workout before subscribing.

    This allows demo users to actually start a workout and experience
    the app's workout tracking features before committing.

    Returns:
        - The full workout to try
        - A token that expires in 1 hour
        - Instructions for completing the trial workout
    """
    try:
        db = get_supabase_db()

        # Check if this session has already tried a workout
        existing = db.client.table("demo_interactions").select("id").eq(
            "session_id", body.session_id
        ).eq(
            "action_type", "try_workout_started"
        ).execute()

        if existing.data and len(existing.data) >= 1:
            # Allow one retry, but no more
            if len(existing.data) >= 2:
                return {
                    "status": "limit_reached",
                    "message": "You've already tried a workout. Sign up for full access!",
                    "cta": {
                        "action": "start_trial",
                        "text": "Start 7-Day Free Trial",
                        "benefit": "Unlimited workouts + AI coaching",
                    }
                }

        # Get the sample workout
        sample_workouts = await get_sample_workouts()
        workout = None
        for w in sample_workouts["workouts"]:
            if w["id"] == body.workout_id:
                workout = w
                break

        if not workout:
            # If workout_id doesn't match, provide the first sample
            workout = sample_workouts["workouts"][0]

        # Generate a try-workout token (simple UUID, could be JWT in production)
        try_token = str(uuid.uuid4())

        # Log the try workout start
        db.client.table("demo_interactions").insert({
            "session_id": body.session_id,
            "action_type": "try_workout_started",
            "feature": "try_workout",
            "metadata": {
                "workout_id": workout["id"],
                "workout_name": workout["name"],
                "try_token": try_token,
                "started_at": body.started_at or datetime.utcnow().isoformat(),
            }
        }).execute()

        # Add tracking info to workout
        workout["try_token"] = try_token
        workout["try_expires_at"] = (datetime.utcnow().replace(microsecond=0) +
                                      timedelta(hours=1)).isoformat() + "Z"

        return {
            "status": "started",
            "workout": workout,
            "try_token": try_token,
            "expires_in_minutes": 60,
            "instructions": {
                "1": "Complete the workout at your own pace",
                "2": "Track your sets and reps as you go",
                "3": "Rate the workout when you finish",
            },
            "preview_limitations": [
                "No exercise swap (premium feature)",
                "No rest timer customization",
                "No workout history saved",
            ],
            "upgrade_cta": {
                "text": "Sign up to save this workout and unlock 1700+ exercises!",
                "trial_available": True,
            }
        }

    except Exception as e:
        logger.error(f"Failed to start try workout: {e}")
        raise safe_internal_error(e, "demo")


@router.post("/try-workout/complete")
@limiter.limit("5/hour")
async def complete_try_workout(request: Request, body: TryWorkoutCompleteRequest):
    """
    Complete a try workout and record the experience.

    This captures valuable data about the demo user's workout experience
    and provides a strong conversion opportunity.
    """
    try:
        db = get_supabase_db()

        # Log the completion
        db.client.table("demo_interactions").insert({
            "session_id": body.session_id,
            "action_type": "try_workout_completed",
            "feature": "try_workout",
            "duration_seconds": body.duration_seconds,
            "metadata": {
                "workout_id": body.workout_id,
                "exercises_completed": body.exercises_completed,
                "exercises_total": body.exercises_total,
                "completion_rate": round(body.exercises_completed / body.exercises_total * 100, 1) if body.exercises_total > 0 else 0,
                "feedback": body.feedback,
            }
        }).execute()

        # Calculate a mock "results" to show value
        completion_rate = (body.exercises_completed / body.exercises_total * 100) if body.exercises_total > 0 else 0

        return {
            "status": "completed",
            "summary": {
                "duration_minutes": round(body.duration_seconds / 60, 1),
                "exercises_completed": body.exercises_completed,
                "exercises_total": body.exercises_total,
                "completion_rate": round(completion_rate, 1),
                "estimated_calories": 50 + (body.exercises_completed * 25),
            },
            "motivation": _get_completion_motivation(completion_rate),
            "conversion_offer": {
                "headline": "You crushed it! Keep the momentum going.",
                "offer": "Start your 7-day FREE trial",
                "benefits": [
                    "Personalized AI-generated workout plans",
                    "Track progress and see real results",
                    "Access to 1700+ exercises with video guides",
                    "AI coach to answer your questions",
                ],
                "urgency": "Limited time: First week completely free!",
            },
            "next_steps": {
                "primary": {
                    "action": "start_trial",
                    "text": "Start Free Trial",
                },
                "secondary": {
                    "action": "view_plans",
                    "text": "See All Plans",
                },
            }
        }

    except Exception as e:
        logger.error(f"Failed to complete try workout: {e}")
        raise safe_internal_error(e, "demo")


@router.get("/exercises-previewed/{session_id}")
async def get_previewed_exercises(session_id: str):
    """
    Get list of exercises/workouts that were previewed in a session.

    Useful for:
    - Showing users what they've explored
    - Personalized conversion messaging
    - Analytics on feature engagement
    """
    try:
        db = get_supabase_db()

        result = db.client.table("demo_interactions").select(
            "action_type, screen, feature, metadata, created_at"
        ).eq(
            "session_id", session_id
        ).in_(
            "action_type", ["preview_workout_viewed", "exercise_view", "workout_preview", "try_workout_started", "try_workout_completed"]
        ).order("created_at", desc=True).execute()

        interactions = result.data or []

        # Extract unique exercises and workouts viewed
        exercises_viewed = set()
        workouts_viewed = set()
        try_workout_data = None

        for interaction in interactions:
            metadata = interaction.get("metadata", {})

            if interaction["action_type"] == "exercise_view":
                exercises_viewed.add(metadata.get("exercise_name", "Unknown"))
            elif interaction["action_type"] in ["preview_workout_viewed", "workout_preview"]:
                workouts_viewed.add(metadata.get("workout_name", interaction.get("screen", "Unknown")))
            elif interaction["action_type"] == "try_workout_completed":
                try_workout_data = metadata

        return {
            "session_id": session_id,
            "exercises_viewed": list(exercises_viewed),
            "workouts_viewed": list(workouts_viewed),
            "total_interactions": len(interactions),
            "try_workout_completed": try_workout_data is not None,
            "try_workout_summary": try_workout_data,
        }

    except Exception as e:
        logger.error(f"Failed to get previewed exercises: {e}")
        raise safe_internal_error(e, "demo")


# ============================================================================
# HELPER FUNCTIONS
# ============================================================================


def _get_exercise_instructions(exercise_name: str) -> List[str]:
    """Get basic instructions for an exercise."""
    # In production, this would come from the exercise database
    instructions_map = {
        "Push-ups": [
            "Start in a plank position with hands shoulder-width apart",
            "Lower your body until chest nearly touches the floor",
            "Push back up to starting position",
            "Keep core tight throughout the movement",
        ],
        "Dumbbell Bench Press": [
            "Lie on a flat bench holding dumbbells at chest level",
            "Press dumbbells up until arms are extended",
            "Lower back down with control",
            "Keep feet flat on the floor for stability",
        ],
        "Goblet Squats": [
            "Hold a dumbbell vertically at chest level",
            "Stand with feet shoulder-width apart",
            "Squat down keeping chest up and knees tracking over toes",
            "Push through heels to return to standing",
        ],
        "Lat Pulldowns": [
            "Sit at the lat pulldown machine with thighs secured",
            "Grip the bar wider than shoulder-width",
            "Pull the bar down to upper chest while squeezing shoulder blades",
            "Control the weight back up, stretching lats fully",
        ],
    }

    return instructions_map.get(exercise_name, [
        "Perform the exercise with controlled movement",
        "Focus on proper form over speed",
        "Breathe out during exertion, in during recovery",
        "Rest as needed between sets",
    ])


def _get_preview_warmup(focus_muscles: List[str]) -> Dict[str, Any]:
    """Get a preview warmup based on focus muscles."""
    warmup_exercises = [
        {"name": "Jumping Jacks", "duration_seconds": 60, "type": "cardio"},
        {"name": "Arm Circles", "duration_seconds": 30, "type": "dynamic"},
        {"name": "Leg Swings", "duration_seconds": 30, "type": "dynamic"},
        {"name": "Hip Circles", "duration_seconds": 30, "type": "dynamic"},
    ]

    # Add muscle-specific warmups
    if "chest" in focus_muscles or "shoulders" in focus_muscles:
        warmup_exercises.append(
            {"name": "Band Pull-Aparts", "duration_seconds": 30, "type": "activation"}
        )
    if "quadriceps" in focus_muscles or "hamstrings" in focus_muscles:
        warmup_exercises.append(
            {"name": "Bodyweight Squats", "reps": 10, "type": "activation"}
        )

    return {
        "duration_minutes": 5,
        "exercises": warmup_exercises,
    }


def _get_preview_cooldown() -> Dict[str, Any]:
    """Get a preview cooldown routine."""
    return {
        "duration_minutes": 5,
        "exercises": [
            {"name": "Static Chest Stretch", "duration_seconds": 30},
            {"name": "Shoulder Stretch", "duration_seconds": 30},
            {"name": "Quad Stretch", "duration_seconds": 30},
            {"name": "Hamstring Stretch", "duration_seconds": 30},
            {"name": "Deep Breathing", "duration_seconds": 60},
        ],
    }


def _get_completion_motivation(completion_rate: float) -> str:
    """Get a motivational message based on completion rate."""
    if completion_rate >= 100:
        return "Perfect workout! You completed every exercise. You're already on your way to reaching your goals!"
    elif completion_rate >= 80:
        return "Great job! You pushed through and completed most of the workout. Consistency like this builds real results!"
    elif completion_rate >= 50:
        return "Good effort! Every rep counts, and showing up is half the battle. Keep building that habit!"
    else:
        return "You showed up and that's what matters! Starting is the hardest part. Let's build from here!"
