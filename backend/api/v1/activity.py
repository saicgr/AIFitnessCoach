"""
Daily Activity API Router.

Provides endpoints for storing and retrieving daily activity data
from Health Connect (Android) / Apple Health (iOS).
"""
from core.db import get_supabase_db
from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import date, datetime

from core.logger import get_logger
from core.activity_logger import log_user_activity, log_user_error
from core.timezone_utils import resolve_timezone, get_user_today
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from services.consent_guard import has_health_data_consent

router = APIRouter(prefix="/activity", tags=["Activity"])
logger = get_logger(__name__)


def _require_health_consent(user_id: str) -> None:
    """Refuse to persist GDPR Art. 9 / special-category health data without
    the user's explicit opt-in captured in user_ai_settings.health_data_consent.

    This is the server-side complement to the onboarding Art. 9 consent
    capture. The frontend should never hit this endpoint if consent is
    off, but a defensive 403 here guarantees a hostile or stale client
    cannot push HealthKit data into our database without opt-in.
    """
    if not has_health_data_consent(user_id):
        raise HTTPException(
            status_code=403,
            detail=(
                "Health data sync is disabled for this account. Enable "
                "'Health data processing' in Settings → Privacy & Data to "
                "allow Zealova to store measurements from Health Connect "
                "or HealthKit."
            ),
        )


class DailyActivityInput(BaseModel):
    """Input for recording daily activity from Health Connect / Apple Health.

    The following fields were removed 2026-05-07 from the active write path
    to keep the Google Play Data Safety declaration honest after the
    Health Connect "Minimum Scope" permission removal:
      ``distance_meters``, ``hrv``, ``blood_oxygen``, ``body_temperature``,
      ``respiratory_rate``, ``flights_climbed``, ``basal_calories``.
    Old app builds in production may still send those keys — Pydantic v2
    ignores unknown fields silently, so no client error is raised, but the
    server no longer persists them. The corresponding ``daily_activity``
    columns are kept for historical data; new writes leave them NULL/0.
    """
    user_id: str
    activity_date: date
    steps: int = Field(default=0, ge=0)
    calories_burned: float = Field(default=0, ge=0, description="Total calories burned")
    active_calories: float = Field(default=0, ge=0, description="Active calories only")
    active_minutes: int = Field(
        default=0, ge=0, le=1440,
        description="Active/exercise minutes — HealthKit appleExerciseTime / Health Connect",
    )
    resting_heart_rate: Optional[int] = Field(None, ge=30, le=250)
    avg_heart_rate: Optional[int] = Field(None, ge=30, le=250)
    max_heart_rate: Optional[int] = Field(None, ge=30, le=250)
    sleep_minutes: Optional[int] = Field(None, ge=0, le=1440)
    deep_sleep_minutes: Optional[int] = Field(None, ge=0, le=1440)
    light_sleep_minutes: Optional[int] = Field(None, ge=0, le=1440)
    awake_sleep_minutes: Optional[int] = Field(None, ge=0, le=1440)
    rem_sleep_minutes: Optional[int] = Field(None, ge=0, le=1440)
    water_ml: Optional[int] = Field(default=0, ge=0)
    source: str = Field(default="health_connect", description="health_connect or apple_health")


class DailyActivityResponse(BaseModel):
    """Response for daily activity data.

    See ``DailyActivityInput`` — the same 7 health metrics were dropped
    from the response shape on 2026-05-07. Old app builds in production
    treat all health fields as Optional and null-check before display, so
    omitting them from the response is safe for backwards compatibility.
    """
    id: str
    user_id: str
    activity_date: date
    steps: int
    calories_burned: float
    active_calories: float
    active_minutes: Optional[int]
    resting_heart_rate: Optional[int]
    avg_heart_rate: Optional[int]
    max_heart_rate: Optional[int]
    sleep_minutes: Optional[int]
    sleep_hours: Optional[float]
    deep_sleep_minutes: Optional[int]
    light_sleep_minutes: Optional[int]
    awake_sleep_minutes: Optional[int]
    rem_sleep_minutes: Optional[int]
    water_ml: int
    source: str
    synced_at: datetime


class ActivitySummaryResponse(BaseModel):
    """Summary of activity over a period.

    `total_distance_km` / `avg_distance_km` removed 2026-05-07 — the
    `daily_activity.distance_meters` column is no longer being written to
    after the Health Connect minimum-scope edit, so the rolling totals
    would have trended toward 0 anyway.
    """
    total_steps: int
    avg_steps: float
    total_calories: float
    avg_calories: float
    avg_heart_rate: Optional[float]
    days_tracked: int


def row_to_activity_response(row: dict) -> DailyActivityResponse:
    """Convert database row to response model.

    Stale columns (``distance_meters`` / ``hrv`` / ``blood_oxygen`` /
    ``body_temperature`` / ``respiratory_rate`` / ``flights_climbed`` /
    ``basal_calories``) on the row are intentionally dropped here — see
    ``DailyActivityResponse`` docstring.
    """
    sleep_min = row.get("sleep_minutes")

    return DailyActivityResponse(
        id=row.get("id"),
        user_id=row.get("user_id"),
        activity_date=row.get("activity_date"),
        steps=row.get("steps") or 0,
        calories_burned=row.get("calories_burned") or 0,
        active_calories=row.get("active_calories") or 0,
        active_minutes=row.get("active_minutes"),
        resting_heart_rate=row.get("resting_heart_rate"),
        avg_heart_rate=row.get("avg_heart_rate"),
        max_heart_rate=row.get("max_heart_rate"),
        sleep_minutes=sleep_min,
        sleep_hours=round(sleep_min / 60, 1) if sleep_min else None,
        deep_sleep_minutes=row.get("deep_sleep_minutes"),
        light_sleep_minutes=row.get("light_sleep_minutes"),
        awake_sleep_minutes=row.get("awake_sleep_minutes"),
        rem_sleep_minutes=row.get("rem_sleep_minutes"),
        water_ml=row.get("water_ml") or 0,
        source=row.get("source") or "health_connect",
        synced_at=row.get("synced_at"),
    )


@router.post("/sync", response_model=DailyActivityResponse)
async def sync_daily_activity(input: DailyActivityInput, current_user: dict = Depends(get_current_user)):
    """
    Sync daily activity data from Health Connect / Apple Health.

    Uses upsert to update existing record for the same date or create new one.
    """
    if str(current_user["id"]) != str(input.user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    _require_health_consent(str(input.user_id))
    logger.info(f"Syncing activity for user {input.user_id} on {input.activity_date}")

    db = get_supabase_db()

    # distance_meters / hrv / blood_oxygen / body_temperature /
    # respiratory_rate / flights_climbed / basal_calories removed from
    # the upsert payload 2026-05-07 — see DailyActivityInput docstring.
    # Existing DB columns are preserved for historical rows.
    data = {
        "user_id": input.user_id,
        "activity_date": input.activity_date.isoformat(),
        "steps": input.steps,
        "calories_burned": input.calories_burned,
        "active_calories": input.active_calories,
        "active_minutes": input.active_minutes or 0,
        "resting_heart_rate": input.resting_heart_rate,
        "avg_heart_rate": input.avg_heart_rate,
        "max_heart_rate": input.max_heart_rate,
        "sleep_minutes": input.sleep_minutes,
        "deep_sleep_minutes": input.deep_sleep_minutes,
        "light_sleep_minutes": input.light_sleep_minutes,
        "awake_sleep_minutes": input.awake_sleep_minutes,
        "rem_sleep_minutes": input.rem_sleep_minutes,
        "water_ml": input.water_ml or 0,
        "source": input.source,
    }

    result = db.upsert_daily_activity(data)

    if not result:
        raise safe_internal_error(ValueError("Failed to sync activity data"), "activity")

    logger.info(f"Successfully synced activity for {input.activity_date}")

    # Log activity sync (wrapped to never prevent response delivery)
    try:
        await log_user_activity(
            user_id=input.user_id,
            action="activity_synced",
            endpoint="/api/v1/activity/sync",
            message=f"Synced activity for {input.activity_date}",
            metadata={
                "date": str(input.activity_date),
                "steps": input.steps,
                "calories": input.calories_burned,
                "source": input.source
            },
            status_code=200
        )
    except Exception as e:
        logger.error(f"Activity logging failed: {e}", exc_info=True, extra={"user_id_full": input.user_id, "failed_action": "activity_synced"})

    return row_to_activity_response(result)


@router.get("/today/{user_id}", response_model=Optional[DailyActivityResponse])
async def get_today_activity(user_id: str, request: Request, current_user: dict = Depends(get_current_user)):
    """Get today's activity for a user."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Fetching today's activity for user {user_id}")

    db = get_supabase_db()
    user_tz = resolve_timezone(request, db, user_id)
    today = get_user_today(user_tz)
    row = db.get_daily_activity(user_id=user_id, activity_date=today)

    if not row:
        return None

    return row_to_activity_response(row)


@router.get("/ai-burned/{user_id}")
async def get_ai_burned_today(user_id: str, request: Request, current_user: dict = Depends(get_current_user)):
    """Sum today's calories burned from chat / manually logged activities.

    Phase 6 — feeds the home "TRACKING" flame icon so an AI-Coach-logged
    activity ("I did 30 min yoga") shows its burned calories even when the
    user hasn't connected HealthKit / Health Connect.

    Double-count safety (X2/X9): AI/chat/manual workouts live in the
    `workouts` table, which is a SEPARATE store from `daily_activity`
    (where HealthKit/Strava sync writes). They never overlap by storage.
    Within `workouts` we additionally EXCLUDE any chat-logged workout that
    has a wearable-synced sibling within ±20min — that sibling's calories
    are already counted by the HealthKit `daily_activity` total, so adding
    the chat copy too would double-count the same real-world session.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")

    db = get_supabase_db()
    user_tz = resolve_timezone(request, db, user_id)
    today = get_user_today(user_tz)

    try:
        # All completed workouts logged today via chat / manual entry.
        rows = db.client.table("workouts").select(
            "id, name, estimated_calories, completed_at, generation_source, generation_method"
        ).eq("user_id", user_id).eq("is_completed", True).gte(
            "completed_at", f"{today}T00:00:00"
        ).lte("completed_at", f"{today}T23:59:59.999999").execute()

        wearable_sources = {
            "wearable_sync_apple_health", "wearable_sync_fitbit",
            "wearable_sync_garmin", "wearable_sync_health_connect",
            "health_connect",
        }
        manual_logs = []
        wearable_times = []
        for r in (rows.data or []):
            src = r.get("generation_source") or ""
            ct = r.get("completed_at")
            if src in wearable_sources:
                if ct:
                    wearable_times.append(datetime.fromisoformat(ct.replace("Z", "+00:00")))
            elif r.get("generation_method") == "manual_log":
                manual_logs.append(r)

        total = 0
        counted = 0
        for r in manual_logs:
            cals = r.get("estimated_calories") or 0
            if cals <= 0:
                continue
            ct = r.get("completed_at")
            # Skip if a wearable already logged a session within ±20min.
            overlapped = False
            if ct:
                try:
                    cdt = datetime.fromisoformat(ct.replace("Z", "+00:00"))
                    for wt in wearable_times:
                        if abs((cdt - wt).total_seconds()) <= 1200:
                            overlapped = True
                            break
                except Exception:
                    pass
            if overlapped:
                continue
            total += int(cals)
            counted += 1

        return {"date": today, "ai_burned_calories": total, "activity_count": counted}
    except Exception as e:
        logger.error(f"[Activity] ai-burned query failed for {user_id}: {e}", exc_info=True)
        return {"date": today, "ai_burned_calories": 0, "activity_count": 0}


@router.get("/date/{user_id}/{activity_date}", response_model=Optional[DailyActivityResponse])
async def get_activity_by_date(user_id: str, activity_date: date, current_user: dict = Depends(get_current_user)):
    """Get activity for a specific date."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Fetching activity for user {user_id} on {activity_date}")

    db = get_supabase_db()
    row = db.get_daily_activity(user_id=user_id, activity_date=activity_date.isoformat())

    if not row:
        return None

    return row_to_activity_response(row)


@router.get("/history/{user_id}", response_model=List[DailyActivityResponse])
async def get_activity_history(
    user_id: str,
    from_date: Optional[date] = None,
    to_date: Optional[date] = None,
    limit: int = 30,
    current_user: dict = Depends(get_current_user),
):
    """
    Get activity history for a user.

    Returns activity records ordered by date descending.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Fetching activity history for user {user_id}")

    db = get_supabase_db()
    rows = db.list_daily_activity(
        user_id=user_id,
        from_date=from_date.isoformat() if from_date else None,
        to_date=to_date.isoformat() if to_date else None,
        limit=limit
    )

    return [row_to_activity_response(row) for row in rows]


@router.get("/summary/{user_id}", response_model=ActivitySummaryResponse)
async def get_activity_summary(user_id: str, days: int = 7, current_user: dict = Depends(get_current_user)):
    """
    Get activity summary over a period.

    Returns aggregated stats for the specified number of days.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Fetching {days}-day activity summary for user {user_id}")

    db = get_supabase_db()
    summary = db.get_activity_summary(user_id=user_id, days=days)

    return ActivitySummaryResponse(
        total_steps=summary.get("total_steps") or 0,
        avg_steps=summary.get("avg_steps") or 0,
        total_calories=summary.get("total_calories") or 0,
        avg_calories=summary.get("avg_calories") or 0,
        avg_heart_rate=summary.get("avg_heart_rate"),
        days_tracked=summary.get("days_tracked") or 0,
    )


@router.delete("/{user_id}/{activity_date}")
async def delete_activity(user_id: str, activity_date: date, current_user: dict = Depends(get_current_user)):
    """Delete activity for a specific date."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Deleting activity for user {user_id} on {activity_date}")

    db = get_supabase_db()
    deleted = db.delete_daily_activity(user_id=user_id, activity_date=activity_date.isoformat())

    if not deleted:
        raise HTTPException(status_code=404, detail="Activity record not found")

    # Log activity deletion (wrapped to never prevent response delivery)
    try:
        await log_user_activity(
            user_id=user_id,
            action="activity_deleted",
            endpoint=f"/api/v1/activity/{user_id}/{activity_date}",
            message=f"Deleted activity for {activity_date}",
            metadata={"date": str(activity_date)},
            status_code=200
        )
    except Exception as e:
        logger.error(f"Activity logging failed: {e}", exc_info=True, extra={"user_id_full": user_id, "failed_action": "activity_deleted"})

    return {"message": "Activity deleted successfully"}


@router.post("/sync-batch")
async def sync_batch_activity(activities: List[DailyActivityInput], current_user: dict = Depends(get_current_user)):
    """
    Sync multiple days of activity data at once.

    Useful for syncing historical data from Health Connect / Apple Health.
    """
    if not activities:
        return {"synced": 0, "results": []}

    user_id = activities[0].user_id
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    _require_health_consent(str(user_id))
    logger.info(f"Batch syncing {len(activities)} activity records for user {user_id}")

    db = get_supabase_db()
    results = []

    for activity in activities:
        try:
            # Same field-strip as `/activity/sync` — see DailyActivityInput
            # docstring (Google Play Health Connect minimum scope, 2026-05-07).
            data = {
                "user_id": activity.user_id,
                "activity_date": activity.activity_date.isoformat(),
                "steps": activity.steps,
                "calories_burned": activity.calories_burned,
                "active_calories": activity.active_calories,
                "resting_heart_rate": activity.resting_heart_rate,
                "avg_heart_rate": activity.avg_heart_rate,
                "max_heart_rate": activity.max_heart_rate,
                "sleep_minutes": activity.sleep_minutes,
                "deep_sleep_minutes": activity.deep_sleep_minutes,
                "light_sleep_minutes": activity.light_sleep_minutes,
                "awake_sleep_minutes": activity.awake_sleep_minutes,
                "rem_sleep_minutes": activity.rem_sleep_minutes,
                "water_ml": activity.water_ml,
                "source": activity.source,
            }

            result = db.upsert_daily_activity(data)
            if result:
                results.append({
                    "date": activity.activity_date.isoformat(),
                    "status": "success"
                })
            else:
                results.append({
                    "date": activity.activity_date.isoformat(),
                    "status": "failed"
                })
        except Exception as e:
            logger.error(f"Failed to sync activity for {activity.activity_date}: {e}", exc_info=True)
            results.append({
                "date": activity.activity_date.isoformat(),
                "status": "error",
                "error": str(e)
            })

    synced = len([r for r in results if r["status"] == "success"])
    logger.info(f"Batch sync complete: {synced}/{len(activities)} records synced")

    # Log batch sync (wrapped to never prevent response delivery)
    try:
        await log_user_activity(
            user_id=user_id,
            action="activity_batch_synced",
            endpoint="/api/v1/activity/sync-batch",
            message=f"Batch synced {synced}/{len(activities)} activity records",
            metadata={"synced": synced, "total": len(activities)},
            status_code=200
        )
    except Exception as e:
        logger.error(f"Activity logging failed: {e}", exc_info=True, extra={"user_id_full": user_id, "failed_action": "activity_batch_synced"})

    return {"synced": synced, "total": len(activities), "results": results}
