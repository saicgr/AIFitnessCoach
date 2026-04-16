"""Scheduled meal reminder endpoints (recurring + batch)."""
import logging
import uuid
from datetime import date, datetime, timedelta, timezone
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query

from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from models.scheduled_recipe_log import (
    ScheduleKind,
    ScheduleMode,
    ScheduledRecipeLog,
    ScheduledRecipeLogCreate,
    ScheduledRecipeLogUpdate,
    ScheduledRecipeLogsResponse,
    UpcomingScheduledFire,
)

logger = logging.getLogger(__name__)
router = APIRouter()


def _next_fire_recurring(req: ScheduledRecipeLogCreate) -> datetime:
    """Compute the next UTC fire timestamp for a recurring schedule.

    Reasons in user-local time per feedback_user_local_time_only.md.
    Falls back to a naive UTC conversion if the timezone string is unknown.
    """
    try:
        from zoneinfo import ZoneInfo

        tz = ZoneInfo(req.timezone)
    except Exception:
        tz = timezone.utc

    now_local = datetime.now(tz)
    candidate_days = _expand_days(req.schedule_kind, req.days_of_week)
    # Find the next day matching the kind, at the requested local_time.
    # Sun=0..Sat=6 in our convention; Python's weekday() is Mon=0..Sun=6, so map.
    for offset in range(0, 8):
        d = now_local.date() + timedelta(days=offset)
        sun_idx = (d.weekday() + 1) % 7  # Mon=0..Sun=6 -> Sun=0..Sat=6
        if sun_idx in candidate_days:
            candidate = datetime.combine(d, req.local_time, tzinfo=tz)
            if candidate > now_local:
                return candidate.astimezone(timezone.utc)
    # Should never happen, but fall back to tomorrow same time
    return (now_local + timedelta(days=1)).astimezone(timezone.utc)


def _expand_days(kind: Optional[ScheduleKind], custom: Optional[List[int]]) -> set:
    if kind == ScheduleKind.DAILY:
        return {0, 1, 2, 3, 4, 5, 6}
    if kind == ScheduleKind.WEEKDAYS:
        return {1, 2, 3, 4, 5}  # Mon..Fri (Sun=0)
    if kind == ScheduleKind.WEEKENDS:
        return {0, 6}
    return set(custom or [])


def _next_fire_batch(req: ScheduledRecipeLogCreate) -> datetime:
    try:
        from zoneinfo import ZoneInfo

        tz = ZoneInfo(req.timezone)
    except Exception:
        tz = timezone.utc
    if not req.batch_slots:
        # Validator should prevent this, but be defensive
        return datetime.now(timezone.utc)
    first = req.batch_slots[0]
    return datetime.combine(first.local_date, first.local_time, tzinfo=tz).astimezone(timezone.utc)


@router.post("/scheduled-recipes", response_model=ScheduledRecipeLog)
async def create_scheduled_recipe(
    request: ScheduledRecipeLogCreate,
    user_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
):
    try:
        db = get_supabase_db()
        sched_id = str(uuid.uuid4())
        now_iso = datetime.utcnow().isoformat()

        if request.schedule_mode == ScheduleMode.RECURRING:
            next_fire = _next_fire_recurring(request)
        else:
            next_fire = _next_fire_batch(request)

        row = {
            "id": sched_id,
            "user_id": user_id,
            "recipe_id": request.recipe_id,
            "schedule_mode": request.schedule_mode.value,
            "meal_type": request.meal_type.value,
            "servings": request.servings,
            "schedule_kind": request.schedule_kind.value if request.schedule_kind else None,
            "days_of_week": request.days_of_week,
            "local_time": request.local_time.isoformat() if request.local_time else None,
            "timezone": request.timezone,
            "next_fire_at": next_fire.isoformat(),
            "cook_event_id": request.cook_event_id,
            "batch_slots": [s.model_dump(mode="json") for s in (request.batch_slots or [])] or None,
            "next_slot_index": 0,
            "enabled": True,
            "silent_log": request.silent_log,
            "created_at": now_iso,
            "updated_at": now_iso,
        }
        db.client.table("scheduled_recipe_logs").insert(row).execute()
        return ScheduledRecipeLog(**row)
    except Exception as exc:
        raise safe_internal_error(exc, "nutrition")


@router.get("/scheduled-recipes", response_model=ScheduledRecipeLogsResponse)
async def list_scheduled_recipes(
    user_id: str = Query(...),
    enabled_only: bool = Query(True),
    current_user: dict = Depends(get_current_user),
):
    db = get_supabase_db()
    q = db.client.table("scheduled_recipe_logs").select("*").eq("user_id", user_id)
    if enabled_only:
        q = q.eq("enabled", True)
    res = q.order("next_fire_at").execute()
    items = [ScheduledRecipeLog(**r) for r in (res.data or [])]
    return ScheduledRecipeLogsResponse(items=items, total_count=len(items))


@router.get("/scheduled-recipes/upcoming", response_model=List[UpcomingScheduledFire])
async def upcoming_scheduled(
    user_id: str = Query(...),
    days: int = Query(7, ge=1, le=30),
    current_user: dict = Depends(get_current_user),
):
    db = get_supabase_db()
    horizon = (datetime.utcnow() + timedelta(days=days)).isoformat()
    res = (
        db.client.table("scheduled_recipe_logs")
        .select("*").eq("user_id", user_id).eq("enabled", True)
        .lte("next_fire_at", horizon)
        .order("next_fire_at").limit(50).execute()
    )
    rows = res.data or []
    recipe_ids = [r["recipe_id"] for r in rows if r.get("recipe_id")]
    recipe_map = {}
    if recipe_ids:
        rec_res = (
            db.client.table("user_recipes")
            .select("id,name,image_url").in_("id", recipe_ids).execute()
        )
        recipe_map = {r["id"]: r for r in (rec_res.data or [])}
    return [
        UpcomingScheduledFire(
            schedule_id=r["id"],
            recipe_id=r.get("recipe_id"),
            recipe_name=(recipe_map.get(r.get("recipe_id")) or {}).get("name"),
            recipe_image_url=(recipe_map.get(r.get("recipe_id")) or {}).get("image_url"),
            meal_type=r["meal_type"],
            servings=float(r.get("servings") or 1),
            fire_at=r["next_fire_at"],
            schedule_mode=r["schedule_mode"],
            is_batch_last_slot=(
                r["schedule_mode"] == "batch"
                and r.get("batch_slots")
                and r.get("next_slot_index", 0) == len(r["batch_slots"]) - 1
            ),
        )
        for r in rows
    ]


@router.patch("/scheduled-recipes/{schedule_id}", response_model=ScheduledRecipeLog)
async def update_scheduled_recipe(
    schedule_id: str,
    request: ScheduledRecipeLogUpdate,
    current_user: dict = Depends(get_current_user),
):
    db = get_supabase_db()
    patch = {}
    for k, v in request.model_dump(exclude_none=True).items():
        if hasattr(v, "value"):
            patch[k] = v.value
        elif k == "local_time" and v is not None:
            patch[k] = v.isoformat()
        elif k == "paused_until" and v is not None:
            patch[k] = v.isoformat()
        elif k == "batch_slots" and v is not None:
            patch[k] = [s.model_dump(mode="json") if hasattr(s, "model_dump") else s for s in v]
        else:
            patch[k] = v
    if patch:
        patch["updated_at"] = datetime.utcnow().isoformat()
        db.client.table("scheduled_recipe_logs").update(patch).eq("id", schedule_id).execute()
    res = db.client.table("scheduled_recipe_logs").select("*").eq("id", schedule_id).limit(1).execute()
    if not res.data:
        raise HTTPException(status_code=404, detail="schedule not found")
    return ScheduledRecipeLog(**res.data[0])


@router.post("/scheduled-recipes/{schedule_id}/pause", response_model=ScheduledRecipeLog)
async def pause_scheduled_recipe(
    schedule_id: str,
    until: Optional[date] = Query(None),
    current_user: dict = Depends(get_current_user),
):
    db = get_supabase_db()
    db.client.table("scheduled_recipe_logs").update(
        {"paused_until": until.isoformat() if until else None,
         "enabled": False,
         "updated_at": datetime.utcnow().isoformat()}
    ).eq("id", schedule_id).execute()
    res = db.client.table("scheduled_recipe_logs").select("*").eq("id", schedule_id).limit(1).execute()
    if not res.data:
        raise HTTPException(status_code=404, detail="schedule not found")
    return ScheduledRecipeLog(**res.data[0])


@router.delete("/scheduled-recipes/{schedule_id}")
async def delete_scheduled_recipe(schedule_id: str, current_user: dict = Depends(get_current_user)):
    db = get_supabase_db()
    db.client.table("scheduled_recipe_logs").delete().eq("id", schedule_id).execute()
    return {"status": "deleted", "id": schedule_id}
