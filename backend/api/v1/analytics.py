"""
Analytics API endpoints for tracking user behavior and screen time.

ENDPOINTS:
- POST /api/v1/analytics/session/start - Start a new session
- POST /api/v1/analytics/session/end - End a session
- POST /api/v1/analytics/screen-view - Track screen view
- POST /api/v1/analytics/screen-exit - Track screen exit with duration
- POST /api/v1/analytics/event - Track custom event
- POST /api/v1/analytics/funnel - Track funnel event
- POST /api/v1/analytics/onboarding - Track onboarding step
- POST /api/v1/analytics/error - Track app error
- POST /api/v1/analytics/batch - Batch upload analytics events
- GET  /api/v1/analytics/{user_id}/summary - Get user's analytics summary
- GET  /api/v1/analytics/{user_id}/screen-time - Get screen time breakdown
"""
from datetime import datetime, date, timedelta
from fastapi import APIRouter, Depends, HTTPException
from typing import Optional, List
from pydantic import BaseModel
import uuid

from core.supabase_client import get_supabase
from core.logger import get_logger
from core.auth import get_current_user
from core.exceptions import safe_internal_error


class SessionStartRequest(BaseModel):
    """Request to start a new session."""
    user_id: Optional[str] = None
    anonymous_id: Optional[str] = None
    device_type: Optional[str] = None
    device_model: Optional[str] = None
    os_version: Optional[str] = None
    app_version: Optional[str] = None
    app_build: Optional[str] = None
    entry_point: Optional[str] = None
    referrer: Optional[str] = None
    country: Optional[str] = None
    timezone: Optional[str] = None


class SessionEndRequest(BaseModel):
    """Request to end a session."""
    session_id: str


class ScreenViewRequest(BaseModel):
    """Request to track screen view."""
    user_id: Optional[str] = None
    session_id: str
    screen_name: str
    screen_class: Optional[str] = None
    previous_screen: Optional[str] = None
    extra_params: Optional[dict] = None


class ScreenExitRequest(BaseModel):
    """Request to track screen exit."""
    screen_view_id: str
    duration_ms: int
    scroll_depth_percent: Optional[int] = None
    interactions_count: Optional[int] = None


class EventRequest(BaseModel):
    """Request to track custom event."""
    user_id: Optional[str] = None
    session_id: Optional[str] = None
    anonymous_id: Optional[str] = None
    event_name: str
    event_category: Optional[str] = None
    properties: Optional[dict] = None
    screen_name: Optional[str] = None
    device_type: Optional[str] = None
    app_version: Optional[str] = None


class FunnelEventRequest(BaseModel):
    """Request to track funnel event."""
    user_id: Optional[str] = None
    session_id: Optional[str] = None
    anonymous_id: Optional[str] = None
    funnel_name: str
    step_name: str
    step_number: Optional[int] = None
    time_since_funnel_start_ms: Optional[int] = None
    completed: bool = False
    dropped_off: bool = False
    drop_off_reason: Optional[str] = None
    properties: Optional[dict] = None


class OnboardingStepRequest(BaseModel):
    """Request to track onboarding step."""
    user_id: Optional[str] = None
    session_id: Optional[str] = None
    anonymous_id: Optional[str] = None
    step_name: str
    step_number: Optional[int] = None
    completed: bool = False
    skipped: bool = False
    duration_ms: Optional[int] = None
    ai_messages_received: Optional[int] = None
    user_messages_sent: Optional[int] = None
    options_selected: Optional[List[str]] = None
    error: Optional[str] = None
    experiment_id: Optional[str] = None
    variant: Optional[str] = None


class ErrorRequest(BaseModel):
    """Request to track app error."""
    user_id: Optional[str] = None
    session_id: Optional[str] = None
    error_type: str
    error_message: Optional[str] = None
    error_code: Optional[str] = None
    stack_trace: Optional[str] = None
    screen_name: Optional[str] = None
    action: Optional[str] = None
    device_type: Optional[str] = None
    os_version: Optional[str] = None
    app_version: Optional[str] = None
    extra_data: Optional[dict] = None


class BatchEventItem(BaseModel):
    """Single event in a batch."""
    type: str  # 'screen_view', 'screen_exit', 'event', 'funnel', 'onboarding', 'error'
    data: dict
    timestamp: Optional[str] = None


class BatchRequest(BaseModel):
    """Batch analytics upload request."""
    user_id: Optional[str] = None
    session_id: Optional[str] = None
    events: List[BatchEventItem]


class ScreenTimeSummary(BaseModel):
    """Screen time breakdown."""
    total_time_seconds: int
    home_time_seconds: int
    workout_time_seconds: int
    chat_time_seconds: int
    nutrition_time_seconds: int
    profile_time_seconds: int
    other_time_seconds: int


class DailySummary(BaseModel):
    """Daily analytics summary."""
    date: str
    sessions_count: int
    total_session_time_seconds: int
    screens_viewed: int
    screen_time: ScreenTimeSummary


router = APIRouter()
logger = get_logger(__name__)


@router.post("/session/start")
async def start_session(request: SessionStartRequest, current_user: dict = Depends(get_current_user)):
    """Start a new analytics session."""
    logger.info(f"Starting session for user: {request.user_id or request.anonymous_id}")

    try:
        supabase = get_supabase()
        session_id = str(uuid.uuid4())

        # Insert session record
        supabase.client.table("user_sessions").insert({
            "session_id": session_id,
            "user_id": request.user_id,
            "anonymous_id": request.anonymous_id,
            "device_type": request.device_type,
            "device_model": request.device_model,
            "os_version": request.os_version,
            "app_version": request.app_version,
            "app_build": request.app_build,
            "entry_point": request.entry_point,
            "referrer": request.referrer,
            "country": request.country,
            "timezone": request.timezone,
            "started_at": datetime.utcnow().isoformat(),
        }).execute()

        # Update daily stats
        if request.user_id:
            _increment_daily_sessions(supabase, request.user_id)

        return {"session_id": session_id, "started_at": datetime.utcnow().isoformat()}

    except Exception as e:
        logger.error(f"Failed to start session: {e}")
        raise safe_internal_error(e, "start_session")


@router.post("/session/end")
async def end_session(request: SessionEndRequest, current_user: dict = Depends(get_current_user)):
    """End an analytics session."""
    logger.info(f"Ending session: {request.session_id}")

    try:
        supabase = get_supabase()

        # Update session with end time
        result = supabase.client.table("user_sessions")\
            .update({"ended_at": datetime.utcnow().isoformat()})\
            .eq("session_id", request.session_id)\
            .execute()

        if not result.data:
            logger.warning(f"Session not found: {request.session_id}")
            return {"status": "not_found"}

        return {"status": "ended", "ended_at": datetime.utcnow().isoformat()}

    except Exception as e:
        logger.error(f"Failed to end session: {e}")
        raise safe_internal_error(e, "end_session")


@router.post("/screen-view")
async def track_screen_view(request: ScreenViewRequest, current_user: dict = Depends(get_current_user)):
    """Track a screen view."""
    logger.debug(f"Screen view: {request.screen_name} for user: {request.user_id}")

    try:
        supabase = get_supabase()

        # Insert screen view
        result = supabase.client.table("screen_views").insert({
            "user_id": request.user_id,
            "session_id": request.session_id,
            "screen_name": request.screen_name,
            "screen_class": request.screen_class,
            "previous_screen": request.previous_screen,
            "entered_at": datetime.utcnow().isoformat(),
            "extra_params": request.extra_params or {},
        }).execute()

        screen_view_id = result.data[0]["id"] if result.data else None

        return {"screen_view_id": screen_view_id, "tracked": True}

    except Exception as e:
        logger.error(f"Failed to track screen view: {e}")
        # Don't fail request for analytics errors
        return {"tracked": False, "error": str(e)}


@router.post("/screen-exit")
async def track_screen_exit(request: ScreenExitRequest, current_user: dict = Depends(get_current_user)):
    """Track screen exit with duration."""
    logger.debug(f"Screen exit: {request.screen_view_id}, duration: {request.duration_ms}ms")

    try:
        supabase = get_supabase()

        # Update screen view with exit info
        supabase.client.table("screen_views")\
            .update({
                "exited_at": datetime.utcnow().isoformat(),
                "duration_ms": request.duration_ms,
                "scroll_depth_percent": request.scroll_depth_percent,
                "interactions_count": request.interactions_count,
            })\
            .eq("id", request.screen_view_id)\
            .execute()

        return {"tracked": True}

    except Exception as e:
        logger.error(f"Failed to track screen exit: {e}")
        return {"tracked": False, "error": str(e)}


@router.post("/event")
async def track_event(request: EventRequest, current_user: dict = Depends(get_current_user)):
    """Track a custom event."""
    logger.debug(f"Event: {request.event_name} for user: {request.user_id}")

    try:
        supabase = get_supabase()

        # Insert event
        supabase.client.table("user_events").insert({
            "user_id": request.user_id,
            "session_id": request.session_id,
            "anonymous_id": request.anonymous_id,
            "event_name": request.event_name,
            "event_category": request.event_category,
            "properties": request.properties or {},
            "screen_name": request.screen_name,
            "device_type": request.device_type,
            "app_version": request.app_version,
            "timestamp": datetime.utcnow().isoformat(),
        }).execute()

        # Update daily stats for specific events
        if request.user_id:
            _track_daily_event(supabase, request.user_id, request.event_name)

        return {"tracked": True}

    except Exception as e:
        logger.error(f"Failed to track event: {e}")
        return {"tracked": False, "error": str(e)}


@router.post("/funnel")
async def track_funnel_event(request: FunnelEventRequest, current_user: dict = Depends(get_current_user)):
    """Track a funnel event."""
    logger.info(f"Funnel: {request.funnel_name}/{request.step_name} for user: {request.user_id}")

    try:
        supabase = get_supabase()

        # Insert funnel event
        supabase.client.table("funnel_events").insert({
            "user_id": request.user_id,
            "session_id": request.session_id,
            "anonymous_id": request.anonymous_id,
            "funnel_name": request.funnel_name,
            "step_name": request.step_name,
            "step_number": request.step_number,
            "time_since_funnel_start_ms": request.time_since_funnel_start_ms,
            "completed": request.completed,
            "dropped_off": request.dropped_off,
            "drop_off_reason": request.drop_off_reason,
            "properties": request.properties or {},
            "timestamp": datetime.utcnow().isoformat(),
        }).execute()

        return {"tracked": True}

    except Exception as e:
        logger.error(f"Failed to track funnel event: {e}")
        return {"tracked": False, "error": str(e)}


@router.post("/onboarding")
async def track_onboarding_step(request: OnboardingStepRequest, current_user: dict = Depends(get_current_user)):
    """Track onboarding step."""
    logger.info(f"Onboarding step: {request.step_name} for user: {request.user_id}")

    try:
        supabase = get_supabase()

        # Insert onboarding analytics
        supabase.client.table("onboarding_analytics").insert({
            "user_id": request.user_id,
            "session_id": request.session_id,
            "anonymous_id": request.anonymous_id,
            "step_name": request.step_name,
            "step_number": request.step_number,
            "started_at": datetime.utcnow().isoformat(),
            "completed_at": datetime.utcnow().isoformat() if request.completed else None,
            "duration_ms": request.duration_ms,
            "ai_messages_received": request.ai_messages_received,
            "user_messages_sent": request.user_messages_sent,
            "options_selected": request.options_selected or [],
            "completed": request.completed,
            "skipped": request.skipped,
            "error": request.error,
            "experiment_id": request.experiment_id,
            "variant": request.variant,
        }).execute()

        return {"tracked": True}

    except Exception as e:
        logger.error(f"Failed to track onboarding step: {e}")
        return {"tracked": False, "error": str(e)}


@router.post("/error")
async def track_error(request: ErrorRequest, current_user: dict = Depends(get_current_user)):
    """Track app error."""
    logger.warning(f"App error: {request.error_type} - {request.error_message}")

    try:
        supabase = get_supabase()

        # Insert error record
        supabase.client.table("app_errors").insert({
            "user_id": request.user_id,
            "session_id": request.session_id,
            "error_type": request.error_type,
            "error_message": request.error_message,
            "error_code": request.error_code,
            "stack_trace": request.stack_trace,
            "screen_name": request.screen_name,
            "action": request.action,
            "device_type": request.device_type,
            "os_version": request.os_version,
            "app_version": request.app_version,
            "extra_data": request.extra_data or {},
        }).execute()

        return {"tracked": True}

    except Exception as e:
        logger.error(f"Failed to track error: {e}")
        return {"tracked": False, "error": str(e)}


@router.post("/batch")
async def batch_upload(request: BatchRequest, current_user: dict = Depends(get_current_user)):
    """
    Batch upload multiple analytics events.

    Useful for offline sync or reducing API calls.
    """
    logger.info(f"Batch upload: {len(request.events)} events for user: {request.user_id}")

    try:
        supabase = get_supabase()
        processed = 0
        errors = []

        for event in request.events:
            try:
                event_type = event.type
                data = event.data

                # Add user_id and session_id if not present
                if request.user_id and "user_id" not in data:
                    data["user_id"] = request.user_id
                if request.session_id and "session_id" not in data:
                    data["session_id"] = request.session_id

                # Route to appropriate handler
                if event_type == "screen_view":
                    supabase.client.table("screen_views").insert(data).execute()
                elif event_type == "screen_exit":
                    screen_view_id = data.pop("screen_view_id", None)
                    if screen_view_id:
                        supabase.client.table("screen_views")\
                            .update(data)\
                            .eq("id", screen_view_id)\
                            .execute()
                elif event_type == "event":
                    supabase.client.table("user_events").insert(data).execute()
                elif event_type == "funnel":
                    supabase.client.table("funnel_events").insert(data).execute()
                elif event_type == "onboarding":
                    supabase.client.table("onboarding_analytics").insert(data).execute()
                elif event_type == "error":
                    supabase.client.table("app_errors").insert(data).execute()

                processed += 1

            except Exception as e:
                errors.append({"type": event_type, "error": str(e)})

        return {
            "processed": processed,
            "total": len(request.events),
            "errors": errors if errors else None
        }

    except Exception as e:
        logger.error(f"Failed batch upload: {e}")
        raise safe_internal_error(e, "batch_upload")


@router.get("/{user_id}/summary")
async def get_analytics_summary(
    user_id: str,
    days: int = 7,
    current_user: dict = Depends(get_current_user),
):
    """Get user's analytics summary for the past N days."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Fetching analytics summary for user: {user_id}, days: {days}")

    try:
        supabase = get_supabase()
        start_date = (date.today() - timedelta(days=days)).isoformat()

        # Get daily stats
        result = supabase.client.table("daily_user_stats")\
            .select("*")\
            .eq("user_id", user_id)\
            .gte("date", start_date)\
            .order("date", desc=True)\
            .execute()

        summaries = []
        for row in result.data or []:
            summaries.append(DailySummary(
                date=row["date"],
                sessions_count=row.get("sessions_count", 0),
                total_session_time_seconds=row.get("total_session_time_seconds", 0),
                screens_viewed=row.get("screens_viewed", 0),
                screen_time=ScreenTimeSummary(
                    total_time_seconds=(
                        row.get("home_time_seconds", 0) +
                        row.get("workout_time_seconds", 0) +
                        row.get("chat_time_seconds", 0) +
                        row.get("nutrition_time_seconds", 0) +
                        row.get("profile_time_seconds", 0) +
                        row.get("other_time_seconds", 0)
                    ),
                    home_time_seconds=row.get("home_time_seconds", 0),
                    workout_time_seconds=row.get("workout_time_seconds", 0),
                    chat_time_seconds=row.get("chat_time_seconds", 0),
                    nutrition_time_seconds=row.get("nutrition_time_seconds", 0),
                    profile_time_seconds=row.get("profile_time_seconds", 0),
                    other_time_seconds=row.get("other_time_seconds", 0),
                )
            ))

        # Calculate totals
        total_sessions = sum(s.sessions_count for s in summaries)
        total_time = sum(s.total_session_time_seconds for s in summaries)
        total_screens = sum(s.screens_viewed for s in summaries)

        return {
            "user_id": user_id,
            "period_days": days,
            "total_sessions": total_sessions,
            "total_time_seconds": total_time,
            "total_screens_viewed": total_screens,
            "avg_session_time_seconds": total_time // total_sessions if total_sessions > 0 else 0,
            "daily_summaries": summaries
        }

    except Exception as e:
        logger.error(f"Failed to get analytics summary: {e}")
        raise safe_internal_error(e, "get_analytics_summary")


@router.get("/{user_id}/screen-time")
async def get_screen_time(
    user_id: str,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    current_user: dict = Depends(get_current_user),
):
    """Get detailed screen time breakdown."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Fetching screen time for user: {user_id}")

    try:
        supabase = get_supabase()

        # Default to last 7 days
        if not start_date:
            start_date = (date.today() - timedelta(days=7)).isoformat()
        if not end_date:
            end_date = date.today().isoformat()

        # Get screen views with duration
        result = supabase.client.table("screen_views")\
            .select("screen_name, duration_ms, entered_at")\
            .eq("user_id", user_id)\
            .gte("entered_at", start_date)\
            .lte("entered_at", end_date)\
            .not_.is_("duration_ms", "null")\
            .execute()

        # Aggregate by screen
        screen_times = {}
        for row in result.data or []:
            screen = row["screen_name"]
            duration_sec = (row.get("duration_ms") or 0) / 1000

            if screen not in screen_times:
                screen_times[screen] = {"total_seconds": 0, "views": 0}

            screen_times[screen]["total_seconds"] += duration_sec
            screen_times[screen]["views"] += 1

        # Sort by time spent
        sorted_screens = sorted(
            screen_times.items(),
            key=lambda x: x[1]["total_seconds"],
            reverse=True
        )

        return {
            "user_id": user_id,
            "start_date": start_date,
            "end_date": end_date,
            "screens": [
                {
                    "screen_name": screen,
                    "total_seconds": int(data["total_seconds"]),
                    "views": data["views"],
                    "avg_seconds_per_view": int(data["total_seconds"] / data["views"]) if data["views"] > 0 else 0
                }
                for screen, data in sorted_screens
            ],
            "total_tracked_seconds": int(sum(d["total_seconds"] for d in screen_times.values()))
        }

    except Exception as e:
        logger.error(f"Failed to get screen time: {e}")
        raise safe_internal_error(e, "get_screen_time")


def _increment_daily_sessions(supabase, user_id: str):
    """Increment daily session count."""
    try:
        today = date.today().isoformat()

        # Try to increment existing
        result = supabase.client.table("daily_user_stats")\
            .select("id, sessions_count")\
            .eq("user_id", user_id)\
            .eq("date", today)\
            .single()\
            .execute()

        if result.data:
            supabase.client.table("daily_user_stats")\
                .update({"sessions_count": result.data["sessions_count"] + 1})\
                .eq("id", result.data["id"])\
                .execute()
        else:
            supabase.client.table("daily_user_stats").insert({
                "user_id": user_id,
                "date": today,
                "sessions_count": 1
            }).execute()

    except Exception as e:
        logger.error(f"Failed to increment daily sessions: {e}")


def _track_daily_event(supabase, user_id: str, event_name: str):
    """Track specific events in daily stats."""
    try:
        today = date.today().isoformat()

        # Map event names to columns
        column_map = {
            "message_sent": "ai_messages_sent",
            "ai_message_sent": "ai_messages_sent",
            "workout_started": "workouts_started",
            "workout_completed": "workouts_completed",
            "paywall_viewed": "paywall_views",
            "purchase_attempt": "purchase_attempts",
        }

        column = column_map.get(event_name)
        if not column:
            return

        # Get or create daily stats
        result = supabase.client.table("daily_user_stats")\
            .select(f"id, {column}")\
            .eq("user_id", user_id)\
            .eq("date", today)\
            .single()\
            .execute()

        if result.data:
            current_val = result.data.get(column, 0) or 0
            supabase.client.table("daily_user_stats")\
                .update({column: current_val + 1, "events_count": result.data.get("events_count", 0) + 1})\
                .eq("id", result.data["id"])\
                .execute()
        else:
            supabase.client.table("daily_user_stats").insert({
                "user_id": user_id,
                "date": today,
                column: 1,
                "events_count": 1
            }).execute()

    except Exception as e:
        logger.error(f"Failed to track daily event: {e}")
