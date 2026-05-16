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
    intensity_adjusted_met,
    resolve_activity,
    resolve_day_offset,
    steps_to_walking_minutes,
)

logger = get_logger(__name__)
router = APIRouter()

ALLOWED_DOMAINS = {
    "workout", "food", "water", "sleep", "weight", "mood",
    # Phase 6 — universal natural-language logging additions.
    "measurement", "habit", "sauna", "fasting",
}

# Default fasting protocol when the user doesn't name one ("started my fast").
_FASTING_PROTOCOL_GOALS = {
    "12:12": 720, "14:10": 600, "16:8": 960, "18:6": 1080,
    "20:4": 1200, "omad": 1380, "23:1": 1380,
    "24h": 1440, "36h": 2160, "48h": 2880, "5:2": 1440,
}
_DEFAULT_FASTING_PROTOCOL = "16:8"

# Body-measurement type → body_measurements column. Phase 6 measurement domain.
_MEASUREMENT_COLUMN = {
    "waist": "waist_cm",
    "hips": "hip_cm",
    "hip": "hip_cm",
    "chest": "chest_cm",
    "neck": "neck_cm",
    "arms": "bicep_right_cm",
    "bicep": "bicep_right_cm",
    "thighs": "thigh_right_cm",
    "thigh": "thigh_right_cm",
    "shoulders": "shoulder_cm",
    "shoulder": "shoulder_cm",
    "body_fat": "body_fat_percent",
}

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
    domain: str = Field(..., max_length=32)
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

    @field_validator("domain")
    @classmethod
    def _check_domain(cls, v: str) -> str:
        normalized = v.lower().strip()
        # "activity" is an accepted alias for "workout" (the universal
        # logger sometimes emits the friendlier name).
        if normalized == "activity":
            normalized = "workout"
        if normalized not in ALLOWED_DOMAINS:
            raise ValueError(
                f"domain must be one of {sorted(ALLOWED_DOMAINS)} (got {v!r})"
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
    domain: str = Field(..., max_length=32)
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

    intensity = (payload.get("intensity") or activity.default_intensity).lower()

    calories = metadata.get("calories")
    if not calories:
        # X4 — scale the catalog MET by the stated intensity so "hot yoga"
        # / "intense hike" burn more than the moderate baseline.
        adjusted_met = intensity_adjusted_met(activity.met, intensity)
        calories = estimate_calories(adjusted_met, user_weight_kg, duration_minutes)

    workout_name = activity.display_name
    if metadata.get("body_part"):
        workout_name = f"{metadata['body_part'].title()} {workout_name}"

    # A4 — itemized micro-workout. When the chat extractor captured the
    # individual exercises ("20 pushups, 30 squats, 1-min plank"), persist
    # each one into exercises_json so workout history reflects the actual
    # session content. Otherwise fall back to a single synthetic entry.
    logged_exercises = metadata.get("exercises") or []
    if logged_exercises:
        exercises_json = []
        for ex in logged_exercises:
            entry = {
                "name": (ex.get("name") or "exercise").title(),
                "category": activity.category,
                "icon": activity.icon,
                "intensity": intensity,
            }
            if ex.get("sets"):
                entry["sets"] = ex["sets"]
            if ex.get("reps"):
                entry["reps"] = ex["reps"]
            if ex.get("duration_seconds"):
                entry["duration_seconds"] = ex["duration_seconds"]
            exercises_json.append(entry)
        # Reflect the circuit in the workout name when it's a generic log.
        if workout_name == activity.display_name and activity.canonical_id == "calisthenics":
            workout_name = "Bodyweight circuit"
    else:
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
        # A logged-completed activity is NOT the day's canonical plan, so it
        # must NOT claim the is_current slot — otherwise the partial unique
        # index `workouts_one_current_per_user_day` (migration 2048/2049)
        # rejects it whenever the user already has an auto-generated workout
        # for that day. is_current=False keeps it out of the index entirely.
        "is_current": False,
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
        # Sleep is never the canonical daily workout — keep it out of the
        # one-current-per-day partial unique index (see _write_workout).
        "is_current": False,
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


async def _write_measurement(db, user_id: str, source: str, occurred_at: str, payload: Dict[str, Any]) -> Dict[str, Any]:
    """Insert a body measurement (waist/hips/chest/arms/body-fat) into
    body_measurements. Phase 6 — chat-driven measurement logging.
    """
    mtype = (payload.get("measurement_type") or "").lower().strip()
    value = payload.get("value")
    column = _MEASUREMENT_COLUMN.get(mtype)
    if not column:
        raise HTTPException(
            status_code=422,
            detail={"code": "INVALID_MEASUREMENT",
                    "message": f"measurement_type must be one of {sorted(_MEASUREMENT_COLUMN)}"},
        )
    if value is None or float(value) <= 0:
        raise HTTPException(status_code=422, detail={"code": "MISSING_VALUE", "message": "value is required"})
    row = {
        "user_id": user_id,
        column: float(value),
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
        "event_id": f"measurement:{inserted['id']}",
        "raw_id": inserted["id"],
        "name": f"{mtype.replace('_', ' ').title()}: {value}",
    }


async def _write_sauna(db, user_id: str, source: str, occurred_at: str, payload: Dict[str, Any]) -> Dict[str, Any]:
    """Insert a sauna / heat-exposure session into sauna_logs.

    The home flame icon already aggregates `sauna_logs.estimated_calories`
    via `dailySaunaProvider`, so a chat-logged sauna shows up on the flame
    with zero extra wiring.
    """
    duration_minutes = int(payload.get("duration_minutes") or 0)
    if duration_minutes <= 0:
        raise HTTPException(status_code=422, detail={"code": "MISSING_DURATION", "message": "duration_minutes is required"})
    # Sauna burn ≈ 1.5 kcal/min as a conservative passive-heat estimate.
    est_calories = round(duration_minutes * 1.5)
    row = {
        "user_id": user_id,
        "duration_minutes": duration_minutes,
        "estimated_calories": est_calories,
        "logged_at": occurred_at,
        "local_date": occurred_at[:10],
        "notes": payload.get("session_type") or payload.get("notes"),
    }
    row = {k: v for k, v in row.items() if v is not None}
    result = db.client.table("sauna_logs").insert(row).execute()
    if not result.data:
        raise HTTPException(status_code=500, detail="sauna_logs insert returned empty")
    inserted = result.data[0]
    return {
        "event_id": f"sauna:{inserted['id']}",
        "raw_id": inserted["id"],
        "name": f"{duration_minutes} min sauna",
        "calories": est_calories,
    }


async def _write_habit(db, user_id: str, source: str, occurred_at: str, payload: Dict[str, Any]) -> Dict[str, Any]:
    """Check off a habit for the day. Phase 6 — chat-driven habit logging.

    Resolves the user's habit by fuzzy name match. If no matching habit
    exists, auto-creates one (the AI Coach offers to track it) so the user
    never hits a dead end.
    """
    habit_name = (payload.get("habit_name") or "").strip()
    if not habit_name:
        raise HTTPException(status_code=422, detail={"code": "MISSING_HABIT", "message": "habit_name is required"})

    log_date = occurred_at[:10]
    # Find an existing active habit whose name overlaps the request.
    habit_id = None
    matched_name = habit_name
    created_habit = False
    try:
        existing = db.client.table("habits").select("id, name").eq(
            "user_id", user_id
        ).eq("is_active", True).execute()
        needle = habit_name.lower()
        for h in (existing.data or []):
            hn = (h.get("name") or "").lower()
            if hn and (hn in needle or needle in hn):
                habit_id = h["id"]
                matched_name = h["name"]
                break
    except Exception as e:
        logger.warning(f"[Events] habit lookup failed: {e}")

    if not habit_id:
        # Auto-create the habit so chat logging always succeeds.
        new_habit = {
            "user_id": user_id,
            "name": habit_name.title(),
            "category": "general",
            "habit_type": "positive",
            "frequency": "daily",
            "is_suggested": True,
        }
        created = db.client.table("habits").insert(new_habit).execute()
        if not created.data:
            raise HTTPException(status_code=500, detail="habit auto-create failed")
        habit_id = created.data[0]["id"]
        matched_name = created.data[0]["name"]
        created_habit = True

    # Upsert today's habit_log as completed.
    log_row = {
        "habit_id": habit_id,
        "user_id": user_id,
        "log_date": log_date,
        "completed": True,
        "completed_at": occurred_at,
        "notes": payload.get("notes"),
    }
    log_row = {k: v for k, v in log_row.items() if v is not None}
    try:
        result = db.client.table("habit_logs").upsert(
            log_row, on_conflict="habit_id,log_date",
        ).execute()
    except Exception:
        # Fallback: plain insert if the conflict target isn't recognised.
        result = db.client.table("habit_logs").insert(log_row).execute()
    if not result.data:
        raise HTTPException(status_code=500, detail="habit_logs write returned empty")
    inserted = result.data[0]
    return {
        "event_id": f"habit:{inserted['id']}",
        "raw_id": inserted["id"],
        "name": f"{matched_name}" + (" (new habit)" if created_habit else ""),
    }


async def _write_fasting(db, user_id: str, source: str, occurred_at: str, payload: Dict[str, Any]) -> Dict[str, Any]:
    """Start or end an intermittent fast (A18).

    Reuses the fasting_records table directly (same shape the
    /api/v1/fasting/start + /{id}/end endpoints write) so chat-driven
    fasting stays in sync with the Fasting tab — the active-fast timer,
    history, and streak all read this table.

    payload:
        fasting_action: 'start' | 'end'
        protocol: optional protocol id for a start ('16:8', 'OMAD', …)
    """
    action = (payload.get("fasting_action") or "").lower().strip()

    if action == "start":
        # Reject a second concurrent fast — mirrors /fasting/start.
        existing = db.client.table("fasting_records").select("id").eq(
            "user_id", user_id
        ).eq("status", "active").execute()
        if existing.data:
            raise HTTPException(
                status_code=400,
                detail={"code": "FAST_ALREADY_ACTIVE",
                        "message": "You already have an active fast."},
            )
        protocol = (payload.get("protocol") or _DEFAULT_FASTING_PROTOCOL).lower().strip()
        goal_minutes = _FASTING_PROTOCOL_GOALS.get(protocol, 960)
        protocol_display = protocol.upper() if protocol == "omad" else protocol
        ptype = "extended" if goal_minutes >= 1440 else (
            "modified" if protocol in ("5:2",) else "tre")
        row = {
            "user_id": user_id,
            "start_time": occurred_at,
            "goal_duration_minutes": goal_minutes,
            "protocol": protocol_display,
            "protocol_type": ptype,
            "status": "active",
            "completed_goal": False,
            "zones_reached": [],
        }
        result = db.client.table("fasting_records").insert(row).execute()
        if not result.data:
            raise HTTPException(status_code=500, detail="fasting_records insert returned empty")
        inserted = result.data[0]
        return {
            "event_id": f"fasting:{inserted['id']}",
            "raw_id": inserted["id"],
            "name": f"{protocol_display} fast started",
            "fasting_state": "started",
            "goal_minutes": goal_minutes,
        }

    if action == "end":
        active = db.client.table("fasting_records").select("*").eq(
            "user_id", user_id
        ).eq("status", "active").order("start_time", desc=True).limit(1).execute()
        if not active.data:
            raise HTTPException(
                status_code=404,
                detail={"code": "NO_ACTIVE_FAST",
                        "message": "No active fast to end."},
            )
        fast = active.data[0]
        try:
            start_dt = datetime.fromisoformat(fast["start_time"].replace("Z", "+00:00"))
        except Exception:
            start_dt = datetime.now(timezone.utc)
        end_dt = datetime.fromisoformat(occurred_at.replace("Z", "+00:00")) \
            if occurred_at else datetime.now(timezone.utc)
        if end_dt.tzinfo is None:
            end_dt = end_dt.replace(tzinfo=timezone.utc)
        actual_minutes = max(0, int((end_dt - start_dt).total_seconds() / 60))
        goal_minutes = fast.get("goal_duration_minutes") or 1
        completion_pct = round(min(actual_minutes / goal_minutes * 100, 999), 1)
        completed_goal = completion_pct >= 100
        db.client.table("fasting_records").update({
            "end_time": end_dt.isoformat(),
            "actual_duration_minutes": actual_minutes,
            "status": "completed",
            "completed_goal": completed_goal,
            "completion_percentage": completion_pct,
            "updated_at": end_dt.isoformat(),
        }).eq("id", fast["id"]).execute()
        hrs = actual_minutes // 60
        mins = actual_minutes % 60
        return {
            "event_id": f"fasting:{fast['id']}",
            "raw_id": fast["id"],
            "name": f"Fast ended — {hrs}h {mins}m",
            "fasting_state": "ended",
            "actual_minutes": actual_minutes,
        }

    raise HTTPException(
        status_code=422,
        detail={"code": "INVALID_FASTING_ACTION",
                "message": "fasting_action must be 'start' or 'end'"},
    )


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
    elif body.domain == "measurement":
        result = await _write_measurement(db, body.user_id, body.source, occurred_at, body.payload)
    elif body.domain == "sauna":
        result = await _write_sauna(db, body.user_id, body.source, occurred_at, body.payload)
    elif body.domain == "habit":
        result = await _write_habit(db, body.user_id, body.source, occurred_at, body.payload)
    elif body.domain == "fasting":
        result = await _write_fasting(db, body.user_id, body.source, occurred_at, body.payload)
    else:  # pragma: no cover — the domain validator guards this at request parse
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

    # XP / streak parity (X16) — a chat-logged workout must award XP and
    # count for the daily streak EXACTLY like a UI-completed workout. We
    # reuse the same idempotent `_award_workout_complete_xp` helper that the
    # /workouts/complete endpoint uses, so a chat-log + a UI-complete on the
    # same day never double-award (shared `daily_goal_workout_complete`
    # dedup key + user-local-today window).
    if body.domain == "workout":
        try:
            from api.v1.workouts.crud_completion import _award_workout_complete_xp
            _award_workout_complete_xp(
                supabase=db.client, request=request, db=db,
                user_id=body.user_id, workout_id=result["raw_id"],
            )
        except Exception as xp_err:
            logger.warning(f"[Events] workout XP award failed: {xp_err}", exc_info=True)

    # Invalidate caches
    try:
        local_date = occurred_at[:10]
        await invalidate_timeline_cache(body.user_id, local_date)
        if body.domain in ("workout", "sleep"):
            from api.v1.workouts.today import invalidate_today_workout_cache
            await invalidate_today_workout_cache(body.user_id, None, local_date)
    except Exception as cache_err:
        logger.warning(f"[Events] cache invalidation failed: {cache_err}", exc_info=True)

    # Issue an undo token for normal inserts. Fasting is excluded: a fast is
    # a STATE TRANSITION, not a row insert — a blind delete would orphan the
    # timer ("start") or silently discard the completed window ("end"). The
    # user reverses a fast from the Fasting tab instead.
    undo_token = None
    if body.domain != "fasting":
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
        "measurement": "body_measurements",
        "sauna": "sauna_logs",
        "habit": "habit_logs",
        "fasting": "fasting_records",
    }[domain]


def _editable_fields(domain: str) -> set[str]:
    return {
        "workout": {"duration_minutes", "name", "estimated_calories", "exercises_json"},
        "food": {"meal_type", "food_name", "total_calories", "notes"},
        "water": {"amount_ml", "drink_type", "notes"},
        "weight": {"weight_kg", "notes"},
        "mood": {"mood", "energy_level", "notes"},
        "sleep": {"duration_minutes", "exercises_json"},
        "measurement": {"waist_cm", "hip_cm", "chest_cm", "neck_cm",
                        "bicep_right_cm", "thigh_right_cm", "shoulder_cm",
                        "body_fat_percent", "notes"},
        "sauna": {"duration_minutes", "estimated_calories", "notes"},
        "habit": {"completed", "value", "notes"},
        "fasting": {"notes", "mood_after", "energy_level_after"},
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
