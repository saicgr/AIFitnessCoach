"""Secondary endpoints for cardio.  Sub-router included by main module.
Cardio API Endpoints
====================
Handles heart rate zones, cardio metrics, cardio sessions, and endurance training features.

Endpoints:
- GET /cardio/hr-zones/{user_id} - Get personalized heart rate training zones
- GET /cardio/metrics/{user_id} - Get full cardio metrics including VO2 max estimate
- POST /cardio/metrics - Save measured cardio metrics (custom max HR, resting HR)
- GET /cardio/metrics/history/{user_id} - Get cardio metrics history

Cardio Sessions:
- POST /cardio/sessions - Create a new cardio session
- GET /cardio/sessions/{user_id} - List cardio sessions with filters
- GET /cardio/sessions/{user_id}/{session_id} - Get a specific session
- PUT /cardio/sessions/{session_id} - Update a session
- DELETE /cardio/sessions/{session_id} - Delete a session
- GET /cardio/sessions/{user_id}/stats - Get aggregate cardio statistics
"""
from typing import Dict, List, Optional
from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException, Query
import logging
logger = logging.getLogger(__name__)
from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error

from .cardio_models import (
    HRZoneResponse,
    HRZonesResponse,
    CardioMetricsResponse,
    SaveCardioMetricsRequest,
    CardioMetricsHistoryEntry,
    CardioMetricsHistoryResponse,
)

router = APIRouter()

@router.get("/sessions/{user_id}", response_model=CardioSessionsListResponse, tags=["Cardio Sessions"])
async def list_cardio_sessions(
    user_id: str,
    cardio_type: Optional[CardioType] = Query(None, description="Filter by cardio type"),
    location: Optional[CardioLocation] = Query(None, description="Filter by location"),
    start_date: Optional[str] = Query(None, description="Filter sessions from this date (YYYY-MM-DD)"),
    end_date: Optional[str] = Query(None, description="Filter sessions until this date (YYYY-MM-DD)"),
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Number of sessions per page"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get a list of cardio sessions for a user.

    Supports filtering by cardio type, location, and date range.
    Results are paginated and ordered by most recent first.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    db = get_supabase_db()

    # Verify user exists
    user_response = db.client.table("users").select("id").eq(
        "id", user_id
    ).maybe_single().execute()

    if not user_response.data:
        raise HTTPException(status_code=404, detail="User not found")

    # Build query
    query = db.client.table("cardio_sessions").select("*", count="exact").eq("user_id", user_id)

    # Apply filters
    if cardio_type:
        query = query.eq("cardio_type", cardio_type.value)

    if location:
        query = query.eq("location", location.value)

    if start_date:
        query = query.gte("created_at", f"{start_date}T00:00:00")

    if end_date:
        query = query.lte("created_at", f"{end_date}T23:59:59")

    # Calculate pagination
    offset = (page - 1) * page_size

    # Execute query with pagination
    response = query.order(
        "created_at", desc=True
    ).range(offset, offset + page_size - 1).execute()

    sessions = [_parse_cardio_session(row) for row in (response.data or [])]
    total_count = response.count or 0

    return CardioSessionsListResponse(
        user_id=user_id,
        sessions=sessions,
        total_count=total_count,
        page=page,
        page_size=page_size,
    )


@router.get("/sessions/{user_id}/stats", response_model=CardioSessionStatsResponse, tags=["Cardio Sessions"])
async def get_cardio_session_stats(
    user_id: str,
    days: int = Query(30, ge=1, le=365, description="Number of days to analyze"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get aggregate statistics for a user's cardio sessions.

    Returns totals, averages, per-type breakdowns, trends compared to
    the previous period, and best performances.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    db = get_supabase_db()

    # Verify user exists
    user_response = db.client.table("users").select("id").eq(
        "id", user_id
    ).maybe_single().execute()

    if not user_response.data:
        raise HTTPException(status_code=404, detail="User not found")

    # Get sessions for current period
    current_start = datetime.now() - timedelta(days=days)
    previous_start = current_start - timedelta(days=days)

    current_response = db.client.table("cardio_sessions").select("*").eq(
        "user_id", user_id
    ).gte(
        "created_at", current_start.isoformat()
    ).execute()

    previous_response = db.client.table("cardio_sessions").select("*").eq(
        "user_id", user_id
    ).gte(
        "created_at", previous_start.isoformat()
    ).lt(
        "created_at", current_start.isoformat()
    ).execute()

    current_sessions = current_response.data or []
    previous_sessions = previous_response.data or []

    # Calculate overall stats
    total_sessions = len(current_sessions)
    total_distance = sum(float(s.get("distance_km") or 0) for s in current_sessions)
    total_duration = sum(s.get("duration_minutes") or 0 for s in current_sessions)
    total_calories = sum(s.get("calories_burned") or 0 for s in current_sessions)
    total_elevation = sum(s.get("elevation_gain_m") or 0 for s in current_sessions)

    # Calculate averages
    avg_sessions_per_week = (total_sessions / days) * 7 if days > 0 else 0
    avg_distance = total_distance / total_sessions if total_sessions > 0 else 0
    avg_duration = total_duration / total_sessions if total_sessions > 0 else 0
    avg_calories = total_calories / total_sessions if total_sessions > 0 else 0

    # Calculate average heart rate
    hr_sessions = [s for s in current_sessions if s.get("avg_heart_rate")]
    avg_hr = None
    if hr_sessions:
        avg_hr = sum(s["avg_heart_rate"] for s in hr_sessions) / len(hr_sessions)

    # Calculate stats by type
    stats_by_type = []
    type_groups: Dict[str, List[dict]] = {}
    for session in current_sessions:
        cardio_type = session["cardio_type"]
        if cardio_type not in type_groups:
            type_groups[cardio_type] = []
        type_groups[cardio_type].append(session)

    for cardio_type, sessions in type_groups.items():
        type_distance = sum(float(s.get("distance_km") or 0) for s in sessions)
        type_duration = sum(s.get("duration_minutes") or 0 for s in sessions)
        type_calories = sum(s.get("calories_burned") or 0 for s in sessions)
        type_elevation = sum(s.get("elevation_gain_m") or 0 for s in sessions)
        type_hr_sessions = [s for s in sessions if s.get("avg_heart_rate")]

        # Calculate average pace
        avg_pace = None
        if type_distance > 0:
            pace_minutes = type_duration / type_distance
            pace_mins = int(pace_minutes)
            pace_secs = int((pace_minutes - pace_mins) * 60)
            avg_pace = f"{pace_mins}:{pace_secs:02d}"

        # Calculate average speed
        avg_speed = (type_distance / type_duration * 60) if type_duration > 0 else 0

        # Find first and last sessions
        sorted_sessions = sorted(sessions, key=lambda s: s["created_at"])
        first_session = datetime.fromisoformat(sorted_sessions[0]["created_at"].replace("Z", "+00:00")) if sorted_sessions else None
        last_session = datetime.fromisoformat(sorted_sessions[-1]["created_at"].replace("Z", "+00:00")) if sorted_sessions else None

        stats_by_type.append(CardioTypeStats(
            cardio_type=CardioType(cardio_type),
            session_count=len(sessions),
            total_distance_km=round(type_distance, 2),
            total_duration_minutes=type_duration,
            avg_distance_km=round(type_distance / len(sessions), 2) if sessions else 0,
            avg_duration_minutes=round(type_duration / len(sessions), 1) if sessions else 0,
            avg_pace_per_km=avg_pace,
            avg_speed_kmh=round(avg_speed, 2),
            avg_heart_rate=round(sum(s["avg_heart_rate"] for s in type_hr_sessions) / len(type_hr_sessions), 1) if type_hr_sessions else None,
            total_calories_burned=type_calories,
            total_elevation_gain_m=type_elevation,
            first_session=first_session,
            last_session=last_session,
        ))

    # Calculate trends
    prev_distance = sum(float(s.get("distance_km") or 0) for s in previous_sessions)
    prev_duration = sum(s.get("duration_minutes") or 0 for s in previous_sessions)
    prev_sessions_count = len(previous_sessions)

    distance_trend = None
    duration_trend = None
    frequency_trend = None

    if prev_distance > 0:
        distance_trend = round(((total_distance - prev_distance) / prev_distance) * 100, 1)
    if prev_duration > 0:
        duration_trend = round(((total_duration - prev_duration) / prev_duration) * 100, 1)
    if prev_sessions_count > 0:
        frequency_trend = round(((total_sessions - prev_sessions_count) / prev_sessions_count) * 100, 1)

    # Find best performances
    longest_distance_session = None
    longest_duration_session = None
    fastest_pace_session = None
    highest_calorie_session = None

    if current_sessions:
        # Longest distance
        distance_sessions = [s for s in current_sessions if s.get("distance_km")]
        if distance_sessions:
            best_distance = max(distance_sessions, key=lambda s: float(s["distance_km"]))
            longest_distance_session = _parse_cardio_session_summary(best_distance)

        # Longest duration
        best_duration = max(current_sessions, key=lambda s: s["duration_minutes"])
        longest_duration_session = _parse_cardio_session_summary(best_duration)

        # Fastest pace (lowest pace value)
        pace_sessions = [s for s in current_sessions if s.get("avg_pace_per_km") and s.get("distance_km")]
        if pace_sessions:
            def pace_to_seconds(pace: str) -> int:
                parts = pace.split(":")
                return int(parts[0]) * 60 + int(parts[1])
            best_pace = min(pace_sessions, key=lambda s: pace_to_seconds(s["avg_pace_per_km"]))
            fastest_pace_session = _parse_cardio_session_summary(best_pace)

        # Highest calories
        calorie_sessions = [s for s in current_sessions if s.get("calories_burned")]
        if calorie_sessions:
            best_calories = max(calorie_sessions, key=lambda s: s["calories_burned"])
            highest_calorie_session = _parse_cardio_session_summary(best_calories)

    return CardioSessionStatsResponse(
        user_id=user_id,
        period_days=days,
        total_sessions=total_sessions,
        total_distance_km=round(total_distance, 2),
        total_duration_minutes=total_duration,
        total_calories_burned=total_calories,
        total_elevation_gain_m=total_elevation,
        avg_sessions_per_week=round(avg_sessions_per_week, 1),
        avg_distance_per_session_km=round(avg_distance, 2),
        avg_duration_per_session_minutes=round(avg_duration, 1),
        avg_calories_per_session=round(avg_calories, 0),
        avg_heart_rate=round(avg_hr, 1) if avg_hr else None,
        stats_by_type=stats_by_type,
        distance_trend_percent=distance_trend,
        duration_trend_percent=duration_trend,
        frequency_trend_percent=frequency_trend,
        longest_distance_session=longest_distance_session,
        longest_duration_session=longest_duration_session,
        fastest_pace_session=fastest_pace_session,
        highest_calorie_session=highest_calorie_session,
    )


@router.get("/sessions/{user_id}/{session_id}", response_model=CardioSession, tags=["Cardio Sessions"])
async def get_cardio_session(
    user_id: str,
    session_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get a specific cardio session by ID.

    Returns full details of the requested session.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    db = get_supabase_db()

    # Get the session
    response = db.client.table("cardio_sessions").select("*").eq(
        "id", session_id
    ).eq(
        "user_id", user_id
    ).maybe_single().execute()

    if not response.data:
        raise HTTPException(status_code=404, detail="Cardio session not found")

    return _parse_cardio_session(response.data)


@router.put("/sessions/{session_id}", response_model=CardioSession, tags=["Cardio Sessions"])
async def update_cardio_session(
    session_id: str,
    request: CardioSessionUpdate,
    current_user: dict = Depends(get_current_user),
):
    """
    Update an existing cardio session.

    Only the fields provided in the request will be updated.
    """
    db = get_supabase_db()

    # Verify session exists
    existing_response = db.client.table("cardio_sessions").select("*").eq(
        "id", session_id
    ).maybe_single().execute()

    if not existing_response.data:
        raise HTTPException(status_code=404, detail="Cardio session not found")

    existing = existing_response.data
    if str(current_user["id"]) != str(existing["user_id"]):
        raise HTTPException(status_code=403, detail="Access denied")

    # Build update data - only include fields that are provided
    update_data = {}

    if request.workout_id is not None:
        # Verify workout exists
        workout_response = db.client.table("workouts").select("id").eq(
            "id", request.workout_id
        ).maybe_single().execute()
        if not workout_response.data:
            raise HTTPException(status_code=404, detail="Workout not found")
        update_data["workout_id"] = request.workout_id

    if request.cardio_type is not None:
        update_data["cardio_type"] = request.cardio_type.value

    if request.location is not None:
        update_data["location"] = request.location.value

    if request.distance_km is not None:
        update_data["distance_km"] = request.distance_km

    if request.duration_minutes is not None:
        update_data["duration_minutes"] = request.duration_minutes

    if request.avg_pace_per_km is not None:
        update_data["avg_pace_per_km"] = request.avg_pace_per_km

    if request.avg_speed_kmh is not None:
        update_data["avg_speed_kmh"] = request.avg_speed_kmh

    if request.elevation_gain_m is not None:
        update_data["elevation_gain_m"] = request.elevation_gain_m

    if request.avg_heart_rate is not None:
        update_data["avg_heart_rate"] = request.avg_heart_rate

    if request.max_heart_rate is not None:
        update_data["max_heart_rate"] = request.max_heart_rate

    if request.calories_burned is not None:
        update_data["calories_burned"] = request.calories_burned

    if request.notes is not None:
        update_data["notes"] = request.notes

    if request.weather_conditions is not None:
        update_data["weather_conditions"] = request.weather_conditions

    # Recalculate pace/speed if distance or duration changed
    new_distance = update_data.get("distance_km", existing.get("distance_km"))
    new_duration = update_data.get("duration_minutes", existing.get("duration_minutes"))

    if "distance_km" in update_data or "duration_minutes" in update_data:
        if new_distance and new_duration:
            # Recalculate speed if not explicitly provided
            if "avg_speed_kmh" not in update_data:
                update_data["avg_speed_kmh"] = round((float(new_distance) / new_duration) * 60, 2)

            # Recalculate pace if not explicitly provided
            if "avg_pace_per_km" not in update_data and float(new_distance) > 0:
                pace_minutes = new_duration / float(new_distance)
                pace_mins = int(pace_minutes)
                pace_secs = int((pace_minutes - pace_mins) * 60)
                update_data["avg_pace_per_km"] = f"{pace_mins}:{pace_secs:02d}"

    if not update_data:
        # No changes requested
        return _parse_cardio_session(existing)

    # Update session
    response = db.client.table("cardio_sessions").update(
        update_data
    ).eq("id", session_id).execute()

    if not response.data:
        raise safe_internal_error(Exception("Failed to update cardio session"), "update_cardio_session")

    logger.info(f"Updated cardio session {session_id}")

    return _parse_cardio_session(response.data[0])


@router.delete("/sessions/{session_id}", tags=["Cardio Sessions"])
async def delete_cardio_session(
    session_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Delete a cardio session.

    Permanently removes the session record.
    """
    db = get_supabase_db()

    # Verify session exists
    existing_response = db.client.table("cardio_sessions").select("id, user_id").eq(
        "id", session_id
    ).maybe_single().execute()

    if not existing_response.data:
        raise HTTPException(status_code=404, detail="Cardio session not found")

    if str(current_user["id"]) != str(existing_response.data["user_id"]):
        raise HTTPException(status_code=403, detail="Access denied")

    # Delete session
    response = db.client.table("cardio_sessions").delete().eq(
        "id", session_id
    ).execute()

    logger.info(f"Deleted cardio session {session_id}")

    return {"success": True, "message": "Cardio session deleted successfully"}
