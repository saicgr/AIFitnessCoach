"""Generalized event-log facade.

Routes a single `POST /events/log` call to the right per-domain insert
helper (workouts / food_logs / hydration_logs / mood_log / weight /
sleep). Powers the LangGraph `log_event` tool used by the conversational
logging flow ("I did 30 min yoga today" → write workout row).

Also exposes:
- `DELETE /events/{event_id}` — soft delete (writes deleted_at when
  the underlying table supports it; otherwise hard delete).
- `PATCH /events/{event_id}` — edit duration / intensity / notes.
- `POST /events/undo` — reverse a recent insert via signed token
  (30s window).

Idempotency: every write computes a content-hash key. Duplicate POSTs
within ±15min return the existing event with `created=false`.
"""
import hashlib
import hmac
import json
import os
import time
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, Literal, Optional

from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, Field, field_validator

from api.v1.timeline_cache import invalidate_timeline_cache
from core.auth import get_current_user
from core.db import get_supabase_db
from core.logger import get_logger
from core.timezone_utils import get_user_today, resolve_timezone
from services.logging.catalog import (
    estimate_calories,
    get_activity,
    resolve_activity,
    resolve_day_offset,
    steps_to_walking_minutes,
)

logger = get_logger(__name__)
router = APIRouter()

ALLOWED_DOMAINS = {"workout", "food", "water", "sleep", "weight", "mood"}

ALLOWED_SOURCES = {
    "chat", "manual", "voice", "camera", "menu_scan", "barcode",
    "auto_workout", "ai_plan",
    "wearable_sync_apple_health", "wearable_sync_fitbit",
    "wearable_sync_garmin", "wearable_sync_health_connect",
}

# UNDO token signing — 30s window. Secret derived from APP_SECRET env var,
# with an in-process fallback for local dev (never used in prod where the
# env var is always set).
_UNDO_SECRET = os.environ.get("APP_SECRET", "").encode() or b"dev-only-undo-secret-change-me"
_UNDO_TTL_SECONDS = 30


def _sign_undo_token(domain: str, event_id: str, user_id: str, expires_at: int) -> str:
    payload = f"{domain}|{event_id}|{user_id}|{expires_at}"
    sig = hmac.new(_UNDO_SECRET, payload.encode(), hashlib.sha256).hexdigest()
    return f"{expires_at}.{sig}.{domain}.{event_id}"


def _verify_undo_token(token: str, user_id: str) -> Optional[Dict[str, str]]:
    """Returns {domain, event_id} if the token is valid + unexpired."""
    try:
        expires_str, sig, domain, event_id = token.split(".", 3)
        expires_at = int(expires_str)
        if expires_at < int(time.time()):
            return None
        expected = hmac.new(
            _UNDO_SECRET,
            f"{domain}|{event_id}|{user_id}|{expires_at}".encode(),
            hashlib.sha256,
        ).hexdigest()
        if not hmac.compare_digest(sig, expected):
            return None
        return {"domain": domain, "event_id": event_id}
    except Exception:
        return None


# ---------------------------------------------------------------------------
# Request/response models
# ---------------------------------------------------------------------------

class EventLogRequest(BaseModel):
    user_id: str = Field(..., max_length=64)
    domain: Literal["workout", "food", "water", "sleep", "weight", "mood"]
    source: str = Field("chat", max_length=64)
    occurred_at: Optional[str] = Field(None, description="ISO8601, defaults to now")
    payload: Dict[str, Any] = Field(default_factory=dict)
    idempotency_key: Optional[str] = Field(None, max_length=128)

    @field_validator("source")
    @classmethod
    def _check_source(cls, v: str) -> str:
        normalized = v.lower().strip()
        if normalized not in ALLOWED_SOURCES:
            raise ValueError(
                f"source must be one of {sorted(ALLOWED_SOURCES)} (got {v!r})"
            )
        return normalized


class EventLogResponse(BaseModel):
    event_id: str
    domain: str
    created: bool
    name: Optional[str] = None
    calories: Optional[int] = None
    undo_token: Optional[str] = None
    warning: Optional[str] = None


class EventEditRequest(BaseModel):
    user_id: str = Field(..., max_length=64)
    domain: Literal["workout", "food", "water", "sleep", "weight", "mood"]
    patch: Dict[str, Any] = Field(default_factory=dict)


class EventUndoRequest(BaseModel):
    user_id: str = Field(..., max_length=64)
    undo_token: str = Field(..., max_length=400)


# ---------------------------------------------------------------------------
# Idempotency helpers
# ---------------------------------------------------------------------------

def _compute_idempotency_key(user_id: str, domain: str, payload: Dict[str, Any], occurred_at_iso: str) -> str:
    """sha1(user_id|domain|canonical_payload|±15min window)."""
    # Round occurred_at to nearest 15 minutes to dedupe near-duplicates.
    try:
        dt = datetime.fromisoformat(occurred_at_iso.replace("Z", "+00:00"))
    except Exception:
        dt = datetime.now(timezone.utc)
    bucket_minutes = (dt.minute // 15) * 15
    bucketed = dt.replace(minute=bucket_minutes, second=0, microsecond=0).isoformat()

    canonical = json.dumps(payload, sort_keys=True, default=str)
    payload_str = f"{user_id}|{domain}|{canonical}|{bucketed}"
    return hashlib.sha1(payload_str.encode()).hexdigest()[:32]


# ---------------------------------------------------------------------------
# Per-domain write helpers
# ---------------------------------------------------------------------------

async def _write_workout(
    db, user_id: str, source: str, occurred_at: str, payload: Dict[str, Any], user_tz: str,
) -> Dict[str, Any]:
    """Create a completed-workout row from chat-style payload.

    Expected payload:
        activity_type: str             (canonical id from catalog)
        duration_minutes: int
        intensity: 'easy'|'medium'|'hard' (optional)
        metadata: {steps?, distance_km?, calories?, notes?, body_part?}
    """
    activity_type = (payload.get("activity_type") or "other").lower().strip()
    duration_minutes = int(payload.get("duration_minutes") or 0)

    activity = get_activity(activity_type)
    if activity is None:
        # Fall back to 'other' but preserve user phrasing in notes
        activity = get_activity("other")
        notes = (payload.get("metadata", {}).get("notes")
                 or payload.get("activity_type") or "")
        payload.setdefault("metadata", {})["notes"] = notes

    # Steps → estimated minutes if duration not supplied
    metadata = payload.get("metadata") or {}
    steps = metadata.get("steps")
    if duration_minutes <= 0 and steps:
        duration_minutes = steps_to_walking_minutes(int(steps))

    if duration_minutes <= 0:
        raise HTTPException(
            status_code=422,
            detail={"code": "MISSING_DURATION", "message": "duration_minutes is required"},
        )

    # Calories: explicit override, then catalog MET × user weight.
    user_weight_kg = 70.0
    try:
        user = db.get_user(user_id)
        if user:
            wkg = user.get("weight_kg") or user.get("weight")
            if wkg:
                user_weight_kg = float(wkg)
                user_weight_kg = max(30.0, min(user_weight_kg, 250.0))
    except Exception:
        pass

    calories = metadata.get("calories")
    if not calories:
        calories = estimate_calories(activity.met, user_weight_kg, duration_minutes)

    intensity = (payload.get("intensity") or activity.default_intensity).lower()
    workout_name = activity.display_name
    if metadata.get("body_part"):
        workout_name = f"{metadata['body_part'].title()} {workout_name}"

    # Synthetic exercises_json so workout history reads correctly
    exercises_json = [{
        "name": activity.display_name,
        "duration_minutes": duration_minutes,
        "intensity": intensity,
        "category": activity.category,
        "icon": activity.icon,
        "notes": metadata.get("notes"),
    }]

    row = {
        "user_id": user_id,
        "name": workout_name,
        "type": "cardio" if activity.category in ("cardio", "sport") else activity.category,
        "difficulty": {"easy": "easy", "medium": "medium", "hard": "hard"}.get(intensity, "medium"),
        "scheduled_date": occurred_at,
        "completed_at": occurred_at,
        "is_completed": True,
        "status": "completed",
        "completion_method": "chat" if source == "chat" else "manual",
        "exercises_json": exercises_json,
        "duration_minutes": duration_minutes,
        "estimated_duration_minutes": duration_minutes,
        "estimated_calories": int(calories) if calories else None,
        "generation_method": "manual_log",
        "generation_source": source,
    }
    result = db.client.table("workouts").insert(row).execute()
    if not result.data:
        raise HTTPException(status_code=500, detail="workout insert returned empty")
    inserted = result.data[0]
    return {
        "event_id": f"workout:{inserted['id']}",
        "raw_id": inserted["id"],
        "name": workout_name,
        "calories": int(calories) if calories else None,
    }


async def _write_food(db, user_id: str, source: str, occurred_at: str, payload: Dict[str, Any]) -> Dict[str, Any]:
    """Insert into food_logs. Caller may already have run nutrition parsing."""
    name = payload.get("name") or payload.get("food_name") or "Food entry"
    row = {
        "user_id": user_id,
        "logged_at": occurred_at,
        "meal_type": payload.get("meal_type") or "snack",
        "food_name": name,
        "total_calories": int(payload.get("calories") or 0),
        "protein_g": payload.get("protein_g") or 0,
        "carbs_g": payload.get("carbs_g") or 0,
        "fat_g": payload.get("fat_g") or 0,
        "source_type": source,
        "input_type": payload.get("input_type") or source,
        "raw_input": payload.get("raw_input"),
        "notes": payload.get("notes"),
        "image_url": payload.get("photo_url"),
    }
    # Strip None values so DB defaults take over
    row = {k: v for k, v in row.items() if v is not None}
    result = db.client.table("food_logs").insert(row).execute()
    if not result.data:
        raise HTTPException(status_code=500, detail="food_logs insert returned empty")
    inserted = result.data[0]
    return {
        "event_id": f"food:{inserted['id']}",
        "raw_id": inserted["id"],
        "name": name,
        "calories": row.get("total_calories"),
    }


async def _write_water(db, user_id: str, source: str, occurred_at: str, payload: Dict[str, Any]) -> Dict[str, Any]:
    volume_ml = int(payload.get("volume_ml") or 0)
    if volume_ml <= 0:
        raise HTTPException(status_code=422, detail={"code": "MISSING_VOLUME", "message": "volume_ml is required"})
    row = {
        "user_id": user_id,
        "amount_ml": volume_ml,
        "drink_type": payload.get("drink_type") or "water",
        "logged_at": occurred_at,
        "source": source,
        "notes": payload.get("notes"),
    }
    row = {k: v for k, v in row.items() if v is not None}
    result = db.client.table("hydration_logs").insert(row).execute()
    if not result.data:
        raise HTTPException(status_code=500, detail="hydration_logs insert returned empty")
    inserted = result.data[0]
    return {
        "event_id": f"water:{inserted['id']}",
        "raw_id": inserted["id"],
        "name": f"{volume_ml} ml water",
    }


async def _write_weight(db, user_id: str, source: str, occurred_at: str, payload: Dict[str, Any]) -> Dict[str, Any]:
    weight_kg = payload.get("weight_kg")
    if not weight_kg:
        raise HTTPException(status_code=422, detail={"code": "MISSING_WEIGHT", "message": "weight_kg is required"})
    row = {
        "user_id": user_id,
        "weight_kg": float(weight_kg),
        "measured_at": occurred_at,
        "measurement_source": source,
        "notes": payload.get("notes"),
    }
    row = {k: v for k, v in row.items() if v is not None}
    result = db.client.table("body_measurements").insert(row).execute()
    if not result.data:
        raise HTTPException(status_code=500, detail="body_measurements insert returned empty")
    inserted = result.data[0]
    return {
        "event_id": f"weight:{inserted['id']}",
        "raw_id": inserted["id"],
        "name": f"{float(weight_kg):.1f} kg",
    }


async def _write_mood(db, user_id: str, source: str, occurred_at: str, payload: Dict[str, Any]) -> Dict[str, Any]:
    from .mood import ALLOWED_MOODS
    mood = (payload.get("mood") or "").lower().strip()
    if mood not in ALLOWED_MOODS:
        raise HTTPException(
            status_code=422,
            detail={"code": "INVALID_MOOD", "message": f"mood must be one of {sorted(ALLOWED_MOODS)}"},
        )
    row = {
        "user_id": user_id,
        "mood": mood,
        "energy_level": payload.get("energy_level"),
        "notes": payload.get("notes"),
        "source": source,
        "occurred_at": occurred_at,
    }
    row = {k: v for k, v in row.items() if v is not None}
    result = db.client.table("mood_log").insert(row).execute()
    if not result.data:
        raise HTTPException(status_code=500, detail="mood_log insert returned empty")
    inserted = result.data[0]
    return {
        "event_id": f"mood:{inserted['id']}",
        "raw_id": inserted["id"],
        "name": f"Mood: {mood}",
    }


async def _write_sleep(db, user_id: str, source: str, occurred_at: str, payload: Dict[str, Any]) -> Dict[str, Any]:
    """Sleep events are logged into the workouts table with type=sleep so the
    Timeline aggregator only needs to read one canonical activity stream.
    Mirrors how Health Connect imports work today.
    """
    duration_minutes = int(payload.get("duration_minutes") or 0)
    if duration_minutes <= 0:
        raise HTTPException(status_code=422, detail={"code": "MISSING_DURATION", "message": "duration_minutes is required"})
    row = {
        "user_id": user_id,
        "name": "Sleep",
        "type": "sleep",
        "difficulty": "easy",
        "scheduled_date": occurred_at,
        "completed_at": occurred_at,
        "is_completed": True,
        "status": "completed",
        "completion_method": "chat" if source == "chat" else "manual",
        "exercises_json": [{
            "name": "Sleep",
            "duration_minutes": duration_minutes,
            "category": "recovery",
            "icon": "bedtime",
            "quality": payload.get("quality"),
            "bedtime": payload.get("bedtime"),
            "wake_time": payload.get("wake_time"),
        }],
        "duration_minutes": duration_minutes,
        "estimated_duration_minutes": duration_minutes,
        "estimated_calories": 0,
        "generation_method": "manual_log",
        "generation_source": source,
    }
    result = db.client.table("workouts").insert(row).execute()
    if not result.data:
        raise HTTPException(status_code=500, detail="sleep insert returned empty")
    inserted = result.data[0]
    return {
        "event_id": f"sleep:{inserted['id']}",
        "raw_id": inserted["id"],
        "name": "Sleep",
    }


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------

@router.post("/log", response_model=EventLogResponse)
async def log_event(
    request: Request,
    body: EventLogRequest,
    current_user: dict = Depends(get_current_user),
):
    """Single facade for chat-driven, manual, or voice-driven logging."""
    db = get_supabase_db()
    user_tz = resolve_timezone(request, db, body.user_id)
    occurred_at = body.occurred_at or datetime.now(timezone.utc).isoformat()

    # Idempotency: short-circuit duplicate POSTs in the same 15min bucket.
    # (Currently best-effort via in-memory cache; persist later when we add
    # an `event_idempotency` table.)
    idem_key = body.idempotency_key or _compute_idempotency_key(
        body.user_id, body.domain, body.payload, occurred_at,
    )
    cached = _idempotency_cache.get(idem_key)
    if cached:
        logger.info(f"[Events] Idempotent hit for {body.user_id}/{body.domain} key={idem_key}")
        return EventLogResponse(
            event_id=cached["event_id"],
            domain=body.domain,
            created=False,
            name=cached.get("name"),
            calories=cached.get("calories"),
            undo_token=None,
            warning="Duplicate of recent log — returning existing event.",
        )

    # Future-dated guard
    try:
        dt = datetime.fromisoformat(occurred_at.replace("Z", "+00:00"))
        if dt > datetime.now(timezone.utc) + timedelta(minutes=5):
            raise HTTPException(
                status_code=422,
                detail={"code": "FUTURE_DATED", "message": "Cannot log an event in the future."},
            )
    except HTTPException:
        raise
    except Exception:
        pass

    # Route to per-domain write helper
    if body.domain == "workout":
        result = await _write_workout(db, body.user_id, body.source, occurred_at, body.payload, user_tz)
    elif body.domain == "food":
        result = await _write_food(db, body.user_id, body.source, occurred_at, body.payload)
    elif body.domain == "water":
        result = await _write_water(db, body.user_id, body.source, occurred_at, body.payload)
    elif body.domain == "weight":
        result = await _write_weight(db, body.user_id, body.source, occurred_at, body.payload)
    elif body.domain == "mood":
        result = await _write_mood(db, body.user_id, body.source, occurred_at, body.payload)
    elif body.domain == "sleep":
        result = await _write_sleep(db, body.user_id, body.source, occurred_at, body.payload)
    else:  # pragma: no cover — Literal type guards this at request parse
        raise HTTPException(status_code=400, detail=f"unknown domain {body.domain!r}")

    # Cache for idempotency lookups
    _idempotency_cache.set(idem_key, result)

    # Cross-source overlap check (workouts only): if a wearable already
    # logged a similar workout within ±20min, warn the user but DON'T
    # reject — they may legitimately want to record both (e.g. their
    # phone was in their bag during the actual lift). The Timeline
    # aggregator will additionally annotate the older one as
    # "Possibly the same as Apple Health's...".
    overlap_warning = None
    if body.domain == "workout" and body.source == "chat":
        try:
            occurred_dt = datetime.fromisoformat(occurred_at.replace("Z", "+00:00"))
            window_start = (occurred_dt - timedelta(minutes=20)).isoformat()
            window_end = (occurred_dt + timedelta(minutes=20)).isoformat()
            overlap_q = db.client.table("workouts").select(
                "id, name, generation_source, completed_at"
            ).eq("user_id", body.user_id).neq("id", result["raw_id"]).in_(
                "generation_source",
                [
                    "wearable_sync_apple_health", "wearable_sync_fitbit",
                    "wearable_sync_garmin", "wearable_sync_health_connect",
                    "health_connect",
                ],
            ).gte("completed_at", window_start).lte(
                "completed_at", window_end
            ).execute()
            if overlap_q.data:
                src_label = (overlap_q.data[0].get("generation_source") or "wearable").replace(
                    "wearable_sync_", ""
                ).replace("_", " ").title()
                overlap_warning = (
                    f"{src_label} already logged a similar workout around the "
                    f"same time — both entries kept. Tap either to merge."
                )
        except Exception as e:
            logger.debug(f"[Events] overlap check failed: {e}")

    # Compute achievements (PRs / 1RM / weight trend / streak) — non-blocking
    achievements = []
    try:
        from services.achievements.computer import compute_event_achievements
        achievements = await compute_event_achievements(
            db, body.user_id, body.domain, result["raw_id"], occurred_at,
        )
    except Exception as ach_err:
        logger.warning(f"[Achievements] computer failed: {ach_err}", exc_info=True)

    # Invalidate caches
    try:
        local_date = occurred_at[:10]
        await invalidate_timeline_cache(body.user_id, local_date)
        if body.domain in ("workout", "sleep"):
            from api.v1.workouts.today import invalidate_today_workout_cache
            await invalidate_today_workout_cache(body.user_id, None, local_date)
    except Exception as cache_err:
        logger.warning(f"[Events] cache invalidation failed: {cache_err}", exc_info=True)

    expires_at = int(time.time()) + _UNDO_TTL_SECONDS
    undo_token = _sign_undo_token(body.domain, result["raw_id"], body.user_id, expires_at)

    warning = None
    if overlap_warning:
        warning = overlap_warning
    elif achievements:
        warning = f"{len(achievements)} achievement(s) unlocked"

    return EventLogResponse(
        event_id=result["event_id"],
        domain=body.domain,
        created=True,
        name=result.get("name"),
        calories=result.get("calories"),
        undo_token=undo_token,
        warning=warning,
    )


@router.delete("/{event_id}")
async def delete_event(
    request: Request,
    event_id: str,
    user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Soft-delete an event (when supported) or hard-delete for legacy tables."""
    domain, raw_id = _parse_event_id(event_id)
    db = get_supabase_db()
    table = _table_for_domain(domain)
    deleted = False
    try:
        # Try soft-delete first (deleted_at column)
        try:
            now_iso = datetime.now(timezone.utc).isoformat()
            r = db.client.table(table).update({"deleted_at": now_iso}).eq("id", raw_id).eq("user_id", user_id).execute()
            deleted = bool(r.data)
        except Exception:
            r = db.client.table(table).delete().eq("id", raw_id).eq("user_id", user_id).execute()
            deleted = bool(r.data)
    except Exception as e:
        logger.error(f"[Events] delete failed for {event_id}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="delete failed")

    if not deleted:
        raise HTTPException(status_code=404, detail="event not found")

    # Cleanup achievements that reference this event
    try:
        db.client.table("personal_records").delete().eq("workout_id", raw_id).execute()
    except Exception:
        pass

    # Invalidate timeline cache (use today as best-effort; caller can specify date)
    try:
        user_tz = resolve_timezone(request, db, user_id)
        await invalidate_timeline_cache(user_id, get_user_today(user_tz))
    except Exception:
        pass

    return {"deleted": True, "event_id": event_id}


@router.patch("/{event_id}")
async def edit_event(
    request: Request,
    event_id: str,
    body: EventEditRequest,
    current_user: dict = Depends(get_current_user),
):
    """Edit fields on an event. Whitelist of editable fields per domain."""
    domain, raw_id = _parse_event_id(event_id)
    if domain != body.domain:
        raise HTTPException(status_code=400, detail="domain mismatch with event_id prefix")
    db = get_supabase_db()
    table = _table_for_domain(domain)
    editable = _editable_fields(domain)
    patch = {k: v for k, v in body.patch.items() if k in editable}
    if not patch:
        raise HTTPException(status_code=400, detail="no editable fields supplied")
    try:
        result = db.client.table(table).update(patch).eq("id", raw_id).eq("user_id", body.user_id).execute()
    except Exception as e:
        logger.error(f"[Events] edit failed for {event_id}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="edit failed")
    if not result.data:
        raise HTTPException(status_code=404, detail="event not found")
    try:
        user_tz = resolve_timezone(request, db, body.user_id)
        await invalidate_timeline_cache(body.user_id, get_user_today(user_tz))
    except Exception:
        pass
    return {"updated": True, "event_id": event_id, "patch": patch}


@router.post("/undo")
async def undo_event(
    request: Request,
    body: EventUndoRequest,
    current_user: dict = Depends(get_current_user),
):
    """Reverse a recent log via signed token (30s window)."""
    parsed = _verify_undo_token(body.undo_token, body.user_id)
    if not parsed:
        raise HTTPException(status_code=400, detail={"code": "INVALID_OR_EXPIRED_TOKEN"})
    return await delete_event(
        request=request,
        event_id=f"{parsed['domain']}:{parsed['event_id']}",
        user_id=body.user_id,
        current_user=current_user,
    )


# ---------------------------------------------------------------------------
# Domain → table / editable fields
# ---------------------------------------------------------------------------

def _parse_event_id(event_id: str) -> tuple[str, str]:
    if ":" not in event_id:
        raise HTTPException(status_code=400, detail="event_id must be 'domain:uuid'")
    domain, raw = event_id.split(":", 1)
    if domain not in ALLOWED_DOMAINS:
        raise HTTPException(status_code=400, detail=f"unknown domain {domain!r}")
    return domain, raw


def _table_for_domain(domain: str) -> str:
    return {
        "workout": "workouts",
        "food": "food_logs",
        "water": "hydration_logs",
        "weight": "body_measurements",
        "mood": "mood_log",
        "sleep": "workouts",  # sleep stored in workouts with type='sleep'
    }[domain]


def _editable_fields(domain: str) -> set[str]:
    return {
        "workout": {"duration_minutes", "name", "estimated_calories", "exercises_json"},
        "food": {"meal_type", "food_name", "total_calories", "notes"},
        "water": {"amount_ml", "drink_type", "notes"},
        "weight": {"weight_kg", "notes"},
        "mood": {"mood", "energy_level", "notes"},
        "sleep": {"duration_minutes", "exercises_json"},
    }[domain]


# ---------------------------------------------------------------------------
# In-process idempotency cache (15min)
# ---------------------------------------------------------------------------

class _TTLDict:
    def __init__(self, ttl_seconds: int = 900):
        self._ttl = ttl_seconds
        self._d: Dict[str, tuple[float, Dict[str, Any]]] = {}

    def get(self, k: str) -> Optional[Dict[str, Any]]:
        if k not in self._d:
            return None
        ts, val = self._d[k]
        if time.time() - ts > self._ttl:
            self._d.pop(k, None)
            return None
        return val

    def set(self, k: str, v: Dict[str, Any]):
        self._d[k] = (time.time(), v)
        # Cheap LRU-ish trim
        if len(self._d) > 5000:
            for old_k in list(self._d.keys())[:1000]:
                self._d.pop(old_k, None)


_idempotency_cache = _TTLDict(ttl_seconds=900)
