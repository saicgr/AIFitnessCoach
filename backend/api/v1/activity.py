"""
Daily Activity API Router.

Provides endpoints for storing and retrieving daily activity data
from Health Connect (Android) / Apple Health (iOS).
"""
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import date, datetime

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.activity_logger import log_user_activity, log_user_error

router = APIRouter(prefix="/activity", tags=["Activity"])
logger = get_logger(__name__)


class DailyActivityInput(BaseModel):
    """Input for recording daily activity from Health Connect / Apple Health."""
    user_id: str
    activity_date: date
    steps: int = Field(default=0, ge=0)
    calories_burned: float = Field(default=0, ge=0, description="Total calories burned")
    active_calories: float = Field(default=0, ge=0, description="Active calories only")
    distance_meters: float = Field(default=0, ge=0, description="Distance in meters")
    resting_heart_rate: Optional[int] = Field(None, ge=30, le=250)
    avg_heart_rate: Optional[int] = Field(None, ge=30, le=250)
    max_heart_rate: Optional[int] = Field(None, ge=30, le=250)
    sleep_minutes: Optional[int] = Field(None, ge=0, le=1440)
    hrv: Optional[float] = Field(None, ge=0, le=500)
    blood_oxygen: Optional[float] = Field(None, ge=0, le=100)
    body_temperature: Optional[float] = Field(None, ge=30, le=45)
    respiratory_rate: Optional[int] = Field(None, ge=5, le=60)
    flights_climbed: int = Field(default=0, ge=0)
    basal_calories: float = Field(default=0, ge=0)
    deep_sleep_minutes: Optional[int] = Field(None, ge=0, le=1440)
    light_sleep_minutes: Optional[int] = Field(None, ge=0, le=1440)
    awake_sleep_minutes: Optional[int] = Field(None, ge=0, le=1440)
    rem_sleep_minutes: Optional[int] = Field(None, ge=0, le=1440)
    water_ml: int = Field(default=0, ge=0)
    source: str = Field(default="health_connect", description="health_connect or apple_health")


class DailyActivityResponse(BaseModel):
    """Response for daily activity data."""
    id: str
    user_id: str
    activity_date: date
    steps: int
    calories_burned: float
    active_calories: float
    distance_meters: float
    distance_km: float
    resting_heart_rate: Optional[int]
    avg_heart_rate: Optional[int]
    max_heart_rate: Optional[int]
    sleep_minutes: Optional[int]
    sleep_hours: Optional[float]
    hrv: Optional[float]
    blood_oxygen: Optional[float]
    body_temperature: Optional[float]
    respiratory_rate: Optional[int]
    flights_climbed: int
    basal_calories: float
    deep_sleep_minutes: Optional[int]
    light_sleep_minutes: Optional[int]
    awake_sleep_minutes: Optional[int]
    rem_sleep_minutes: Optional[int]
    water_ml: int
    source: str
    synced_at: datetime


class ActivitySummaryResponse(BaseModel):
    """Summary of activity over a period."""
    total_steps: int
    avg_steps: float
    total_calories: float
    avg_calories: float
    total_distance_km: float
    avg_distance_km: float
    avg_heart_rate: Optional[float]
    days_tracked: int


def row_to_activity_response(row: dict) -> DailyActivityResponse:
    """Convert database row to response model."""
    distance_m = row.get("distance_meters") or 0
    sleep_min = row.get("sleep_minutes")

    return DailyActivityResponse(
        id=row.get("id"),
        user_id=row.get("user_id"),
        activity_date=row.get("activity_date"),
        steps=row.get("steps") or 0,
        calories_burned=row.get("calories_burned") or 0,
        active_calories=row.get("active_calories") or 0,
        distance_meters=distance_m,
        distance_km=round(distance_m / 1000, 2),
        resting_heart_rate=row.get("resting_heart_rate"),
        avg_heart_rate=row.get("avg_heart_rate"),
        max_heart_rate=row.get("max_heart_rate"),
        sleep_minutes=sleep_min,
        sleep_hours=round(sleep_min / 60, 1) if sleep_min else None,
        hrv=row.get("hrv"),
        blood_oxygen=row.get("blood_oxygen"),
        body_temperature=row.get("body_temperature"),
        respiratory_rate=row.get("respiratory_rate"),
        flights_climbed=row.get("flights_climbed") or 0,
        basal_calories=row.get("basal_calories") or 0,
        deep_sleep_minutes=row.get("deep_sleep_minutes"),
        light_sleep_minutes=row.get("light_sleep_minutes"),
        awake_sleep_minutes=row.get("awake_sleep_minutes"),
        rem_sleep_minutes=row.get("rem_sleep_minutes"),
        water_ml=row.get("water_ml") or 0,
        source=row.get("source") or "health_connect",
        synced_at=row.get("synced_at"),
    )


@router.post("/sync", response_model=DailyActivityResponse)
async def sync_daily_activity(input: DailyActivityInput):
    """
    Sync daily activity data from Health Connect / Apple Health.

    Uses upsert to update existing record for the same date or create new one.
    """
    logger.info(f"Syncing activity for user {input.user_id} on {input.activity_date}")

    db = get_supabase_db()

    data = {
        "user_id": input.user_id,
        "activity_date": input.activity_date.isoformat(),
        "steps": input.steps,
        "calories_burned": input.calories_burned,
        "active_calories": input.active_calories,
        "distance_meters": input.distance_meters,
        "resting_heart_rate": input.resting_heart_rate,
        "avg_heart_rate": input.avg_heart_rate,
        "max_heart_rate": input.max_heart_rate,
        "sleep_minutes": input.sleep_minutes,
        "hrv": input.hrv,
        "blood_oxygen": input.blood_oxygen,
        "body_temperature": input.body_temperature,
        "respiratory_rate": input.respiratory_rate,
        "flights_climbed": input.flights_climbed,
        "basal_calories": input.basal_calories,
        "deep_sleep_minutes": input.deep_sleep_minutes,
        "light_sleep_minutes": input.light_sleep_minutes,
        "awake_sleep_minutes": input.awake_sleep_minutes,
        "rem_sleep_minutes": input.rem_sleep_minutes,
        "water_ml": input.water_ml,
        "source": input.source,
    }

    result = db.upsert_daily_activity(data)

    if not result:
        raise HTTPException(status_code=500, detail="Failed to sync activity data")

    logger.info(f"Successfully synced activity for {input.activity_date}")

    # Log activity sync
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

    return row_to_activity_response(result)


@router.get("/today/{user_id}", response_model=Optional[DailyActivityResponse])
async def get_today_activity(user_id: str):
    """Get today's activity for a user."""
    logger.info(f"Fetching today's activity for user {user_id}")

    db = get_supabase_db()
    today = date.today().isoformat()
    row = db.get_daily_activity(user_id=user_id, activity_date=today)

    if not row:
        return None

    return row_to_activity_response(row)


@router.get("/date/{user_id}/{activity_date}", response_model=Optional[DailyActivityResponse])
async def get_activity_by_date(user_id: str, activity_date: date):
    """Get activity for a specific date."""
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
    limit: int = 30
):
    """
    Get activity history for a user.

    Returns activity records ordered by date descending.
    """
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
async def get_activity_summary(user_id: str, days: int = 7):
    """
    Get activity summary over a period.

    Returns aggregated stats for the specified number of days.
    """
    logger.info(f"Fetching {days}-day activity summary for user {user_id}")

    db = get_supabase_db()
    summary = db.get_activity_summary(user_id=user_id, days=days)

    return ActivitySummaryResponse(
        total_steps=summary.get("total_steps") or 0,
        avg_steps=summary.get("avg_steps") or 0,
        total_calories=summary.get("total_calories") or 0,
        avg_calories=summary.get("avg_calories") or 0,
        total_distance_km=summary.get("total_distance_km") or 0,
        avg_distance_km=summary.get("avg_distance_km") or 0,
        avg_heart_rate=summary.get("avg_heart_rate"),
        days_tracked=summary.get("days_tracked") or 0,
    )


@router.delete("/{user_id}/{activity_date}")
async def delete_activity(user_id: str, activity_date: date):
    """Delete activity for a specific date."""
    logger.info(f"Deleting activity for user {user_id} on {activity_date}")

    db = get_supabase_db()
    deleted = db.delete_daily_activity(user_id=user_id, activity_date=activity_date.isoformat())

    if not deleted:
        raise HTTPException(status_code=404, detail="Activity record not found")

    # Log activity deletion
    await log_user_activity(
        user_id=user_id,
        action="activity_deleted",
        endpoint=f"/api/v1/activity/{user_id}/{activity_date}",
        message=f"Deleted activity for {activity_date}",
        metadata={"date": str(activity_date)},
        status_code=200
    )

    return {"message": "Activity deleted successfully"}


@router.post("/sync-batch")
async def sync_batch_activity(activities: List[DailyActivityInput]):
    """
    Sync multiple days of activity data at once.

    Useful for syncing historical data from Health Connect / Apple Health.
    """
    if not activities:
        return {"synced": 0, "results": []}

    user_id = activities[0].user_id
    logger.info(f"Batch syncing {len(activities)} activity records for user {user_id}")

    db = get_supabase_db()
    results = []

    for activity in activities:
        try:
            data = {
                "user_id": activity.user_id,
                "activity_date": activity.activity_date.isoformat(),
                "steps": activity.steps,
                "calories_burned": activity.calories_burned,
                "active_calories": activity.active_calories,
                "distance_meters": activity.distance_meters,
                "resting_heart_rate": activity.resting_heart_rate,
                "avg_heart_rate": activity.avg_heart_rate,
                "max_heart_rate": activity.max_heart_rate,
                "sleep_minutes": activity.sleep_minutes,
                "hrv": activity.hrv,
                "blood_oxygen": activity.blood_oxygen,
                "body_temperature": activity.body_temperature,
                "respiratory_rate": activity.respiratory_rate,
                "flights_climbed": activity.flights_climbed,
                "basal_calories": activity.basal_calories,
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
            logger.error(f"Failed to sync activity for {activity.activity_date}: {e}")
            results.append({
                "date": activity.activity_date.isoformat(),
                "status": "error",
                "error": str(e)
            })

    synced = len([r for r in results if r["status"] == "success"])
    logger.info(f"Batch sync complete: {synced}/{len(activities)} records synced")

    # Log batch sync
    await log_user_activity(
        user_id=user_id,
        action="activity_batch_synced",
        endpoint="/api/v1/activity/sync-batch",
        message=f"Batch synced {synced}/{len(activities)} activity records",
        metadata={"synced": synced, "total": len(activities)},
        status_code=200
    )

    return {"synced": synced, "total": len(activities), "results": results}
