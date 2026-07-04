"""
Workout card context API — server-side resolver for the home workout card.

Endpoint:
  GET /api/v1/workouts/card-context?tz=America/Chicago

Plan: §1b.1, §1b.2, §1b.5, §1b.6.

Behaviour:
- Pulls today/tomorrow/yesterday workout rows + user_history_snapshot
  (already-shipped helper) + cycle/sleep signals.
- Resolves `recommended_mode` server-side using a Python port of the
  Flutter mode resolver — keep both in sync, comments call out the
  Dart counterpart enum names.
- Generates / cache-fetches lighter + cycle variants via
  services.workout.variant_generator when relevant.
- Generates / cache-fetches the PR opportunity via
  services.workout.pr_opportunity_finder.
- Returns the §1b.1 JSON shape. On error → safe_internal_error so the
  client falls back to its own pure Dart resolver (per §1b.1 "always
  fail-safe").

Cache: 1h per (user_id, hour_bucket). In-process dict mirrored from the
history_snapshot endpoint. Per §1b.6 — short cache so time-of-day shifts
pick up new modes within the hour.

NO Gemini calls in this endpoint (per §1b.6 — body copy is the Agent C
surface). Rationale text uses deterministic template lines (§1b.3 fallback).
"""
from __future__ import annotations

import logging
import time
from datetime import date, datetime, timedelta, timezone
from typing import Any, Dict, List, Optional, Tuple

from fastapi import APIRouter, BackgroundTasks, Depends, Query, Request
from pydantic import BaseModel
from zoneinfo import ZoneInfo

from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from core.timezone_utils import resolve_timezone, user_today_date

logger = logging.getLogger("workout_card_context")
router = APIRouter()


# ---------------------------------------------------------------------------
# Cache. Keyed by (user_id, local_date_iso, hour_bucket). 1h TTL.
# ---------------------------------------------------------------------------
_CACHE_TTL_SECONDS = 60 * 60
_CONTEXT_CACHE: Dict[Tuple[str, str, int], Tuple[float, Dict[str, Any]]] = {}


def _cache_get(user_id: str, local_date_iso: str, hour: int) -> Optional[Dict[str, Any]]:
    key = (user_id, local_date_iso, hour)
    entry = _CONTEXT_CACHE.get(key)
    if not entry:
        return None
    ts, payload = entry
    if time.time() - ts > _CACHE_TTL_SECONDS:
        _CONTEXT_CACHE.pop(key, None)
        return None
    return payload


def _cache_put(user_id: str, local_date_iso: str, hour: int,
               payload: Dict[str, Any]) -> None:
    _CONTEXT_CACHE[(user_id, local_date_iso, hour)] = (time.time(), payload)


# ---------------------------------------------------------------------------
# Workout-row helpers — mirror history_snapshot shape exactly so callers
# can pass the row straight to the variant generator + PR finder.
# ---------------------------------------------------------------------------
_WORKOUT_SELECT = (
    "id, user_id, name, type, difficulty, scheduled_date, exercises_json, "
    "duration_minutes, completed_at, is_completed, intensity_mode, equipment, status"
)


def _workout_for_date(sb, user_id: str, local_iso: str) -> Optional[Dict[str, Any]]:
    try:
        start = f"{local_iso}T00:00:00+00:00"
        end = f"{local_iso}T23:59:59+00:00"
        wr = sb.client.table("workouts").select(_WORKOUT_SELECT).eq(
            "user_id", user_id
        ).gte("scheduled_date", start).lte(
            "scheduled_date", end
        ).limit(1).execute()
        if wr and wr.data:
            return wr.data[0]
    except Exception as e:
        logger.warning(f"[card_context] workout-for-date {local_iso} failed: {e}")
    return None


def _next_future_workout(sb, user_id: str, today_iso: str) -> Optional[Dict[str, Any]]:
    try:
        start = f"{today_iso}T23:59:59+00:00"
        wr = sb.client.table("workouts").select(_WORKOUT_SELECT).eq(
            "user_id", user_id
        ).gt("scheduled_date", start).order(
            "scheduled_date"
        ).limit(1).execute()
        if wr and wr.data:
            return wr.data[0]
    except Exception as e:
        logger.warning(f"[card_context] next-future-workout failed: {e}")
    return None


def _workout_summary(row: Optional[Dict[str, Any]]) -> Optional[Dict[str, Any]]:
    if not row:
        return None
    exs = row.get("exercises_json") or []
    count = len(exs) if isinstance(exs, list) else 0
    return {
        "id": row.get("id"),
        "name": row.get("name"),
        "duration_minutes": row.get("duration_minutes"),
        "exercise_count": count,
        "scheduled_date": row.get("scheduled_date"),
        "completed": bool(row.get("completed_at") or row.get("is_completed")),
        "intensity_mode": row.get("intensity_mode"),
    }


# ---------------------------------------------------------------------------
# Recovery bucket — mirrors the Flutter resolver's `recovery` var
# (`green` | `yellow` | `red` | `unknown`) based on last night's sleep
# minutes (no sleep_score column per schema verification).
# ---------------------------------------------------------------------------
def _recovery_bucket(sb, user_id: str, yesterday_iso: str) -> Tuple[str, Optional[Dict[str, Any]]]:
    try:
        da = sb.client.table("daily_activity").select(
            "sleep_minutes, hrv, resting_heart_rate, activity_date"
        ).eq("user_id", user_id).eq(
            "activity_date", yesterday_iso
        ).maybe_single().execute()
        if not (da and da.data):
            return ("unknown", None)
        sm = da.data.get("sleep_minutes") or 0
        if sm <= 0:
            return ("unknown", None)
        signals = {
            "sleep_minutes": int(sm),
            "hrv": da.data.get("hrv"),
            "resting_heart_rate": da.data.get("resting_heart_rate"),
        }
        # Crude buckets: <6.5h red, 6.5-7.5h yellow, >7.5h green. HRV
        # only nudges within the same tier when present (per Flutter
        # resolver — kept simple to stay in sync).
        if sm < 390:
            return ("red", signals)
        if sm < 450:
            return ("yellow", signals)
        return ("green", signals)
    except Exception as e:
        logger.warning(f"[card_context] recovery_bucket failed: {e}")
        return ("unknown", None)


# ---------------------------------------------------------------------------
# Cycle phase — read the user's current cycle phase. user_current_cycle_phase
# holds one already-derived row per user (current_phase), so no per-log
# ordering is needed. Best-effort. Returns None when the user has no cycle data
# (men, or users who haven't opted in).
# ---------------------------------------------------------------------------
def _cycle_phase(sb, user_id: str) -> Optional[str]:
    try:
        cl = sb.client.table("user_current_cycle_phase").select(
            "current_phase"
        ).eq("user_id", user_id).maybe_single().execute()
        if cl and cl.data:
            return cl.data.get("current_phase")
    except Exception:
        # Cycle tracking opt-in — silent skip is correct here.
        pass
    return None


# ---------------------------------------------------------------------------
# Equipment match — compare today's workout `equipment` jsonb against the
# user's active gym profile.
# ---------------------------------------------------------------------------
def _equipment_match(sb, user_id: str, today_row: Optional[Dict[str, Any]]) -> str:
    if not today_row:
        return "unknown"
    workout_equipment = today_row.get("equipment")
    if not workout_equipment:
        return "unknown"
    try:
        ur = sb.client.table("users").select(
            "active_gym_profile_id, equipment_v2"
        ).eq("id", user_id).maybe_single().execute()
        if not (ur and ur.data):
            return "unknown"
        user_eq: List[str] = []
        if ur.data.get("equipment_v2"):
            user_eq = [str(e).lower() for e in ur.data["equipment_v2"]]
        else:
            gym_id = ur.data.get("active_gym_profile_id")
            if gym_id:
                gp = sb.client.table("gym_profiles").select("equipment").eq(
                    "id", gym_id
                ).maybe_single().execute()
                if gp and gp.data and gp.data.get("equipment"):
                    user_eq = [str(e).lower() for e in gp.data["equipment"]]
        if not user_eq:
            return "unknown"
        needs: List[str] = []
        if isinstance(workout_equipment, list):
            needs = [str(e).lower() for e in workout_equipment]
        elif isinstance(workout_equipment, dict):
            needs = [str(k).lower() for k in workout_equipment.keys()]
        if not needs:
            return "unknown"
        missing = [n for n in needs if n != "bodyweight" and n not in user_eq]
        return "missing" if missing else "match"
    except Exception as e:
        logger.warning(f"[card_context] equipment_match failed: {e}")
        return "unknown"


# ---------------------------------------------------------------------------
# Mode resolver — Python port of the Flutter `chooseWorkoutCardMode()`
# enum. KEEP IN SYNC. The Flutter enum values are the source of truth;
# any string here must exactly match what the Flutter `WorkoutCardMode`
# .name reports, so the client's switch on the returned `recommended_mode`
# doesn't fall through.
#
# Flutter enum (lib/screens/home/widgets/hero_workout_card_mode.dart):
#   inProgress, completed, windDown, recoveryLighter, cycleAdjusted,
#   equipmentMismatch, yesterdayMissed, scheduledNotStarted,
#   nextWorkoutInFuture, restDayWithCoach, restDay, paused,
#   noPlan, bonus, preWorkoutFuelGap, postWorkoutRefuel, loading, error.
# ---------------------------------------------------------------------------
def _resolve_mode(*, hour: int, today_row: Optional[Dict[str, Any]],
                  next_workout: Optional[Dict[str, Any]],
                  yesterday_missed: bool, recovery: str,
                  cycle_phase: Optional[str], equipment_match: str,
                  paused: bool) -> str:
    if paused:
        return "paused"
    if today_row:
        if today_row.get("completed_at") or today_row.get("is_completed"):
            return "completed"
        # Late-evening guard — recommend wind-down when the user hasn't
        # started today's session and it's past 21:00 local.
        if hour >= 21:
            return "windDown"
        if equipment_match == "missing":
            return "equipmentMismatch"
        if recovery == "red":
            return "recoveryLighter"
        if cycle_phase in ("luteal", "menstrual"):
            return "cycleAdjusted"
        return "scheduledNotStarted"
    # No workout scheduled for today
    if yesterday_missed:
        return "yesterdayMissed"
    if next_workout:
        return "nextWorkoutInFuture"
    return "restDay"


# ---------------------------------------------------------------------------
# Deterministic rationale templates (§1b.3 — Gemini surface is Agent C's
# scope; we ship template fallbacks here so the card always has body copy.)
# Per feedback_dynamic_copy_not_robotic — at least 1 variant per mode for
# now; the LLM surface will expand variety.
# ---------------------------------------------------------------------------
def _rationale(mode: str, *, sleep_minutes: Optional[int] = None,
               cycle_phase: Optional[str] = None,
               yesterday_workout_name: Optional[str] = None) -> str:
    if mode == "windDown":
        return "It's late — anything you start now eats into sleep recovery."
    if mode == "recoveryLighter":
        if sleep_minutes:
            hrs = round(sleep_minutes / 60.0, 1)
            return f"Only {hrs}h of sleep last night — keep today lighter."
        return "Recovery markers are low — keep today lighter."
    if mode == "cycleAdjusted":
        if cycle_phase:
            return f"You're in your {cycle_phase} phase — moderate intensity fits better today."
        return "Cycle-aware: a moderate session fits today better."
    if mode == "equipmentMismatch":
        return "Some equipment for today's plan isn't in your active gym — swap to a bodyweight version."
    if mode == "yesterdayMissed":
        if yesterday_workout_name:
            return f"You missed yesterday's {yesterday_workout_name}. Pick it up or skip — your call."
        return "Yesterday's workout was missed. Pick it up today or skip cleanly."
    if mode == "nextWorkoutInFuture":
        return "Rest day. Your next workout is queued up."
    if mode == "restDay":
        return "Rest day — recovery counts as training."
    if mode == "completed":
        return "Done. Refuel within the next hour for best recovery."
    if mode == "paused":
        return "Plan paused. Resume from Settings when you're ready."
    return "Tap to start when you're ready."


# ---------------------------------------------------------------------------
# Streak helper — does completing today's workout extend the current
# streak? Crude rule: yes when the user already has at least one completed
# workout within the previous 2 days. Avoids fabrication.
# ---------------------------------------------------------------------------
def _streak_extends_if_complete(sb, user_id: str, today_iso: str) -> bool:
    try:
        start = (date.fromisoformat(today_iso) - timedelta(days=2)).isoformat()
        end = today_iso
        wr = sb.client.table("workouts").select(
            "id, completed_at"
        ).eq("user_id", user_id).gte(
            "scheduled_date", f"{start}T00:00:00+00:00"
        ).lt("scheduled_date", f"{end}T00:00:00+00:00").execute()
        for r in (wr.data or []):
            if r.get("completed_at"):
                return True
    except Exception as e:
        logger.warning(f"[card_context] streak check failed: {e}")
    return False


# ---------------------------------------------------------------------------
# Response model
# ---------------------------------------------------------------------------
class WorkoutSummary(BaseModel):
    id: Optional[str] = None
    name: Optional[str] = None
    duration_minutes: Optional[int] = None
    exercise_count: Optional[int] = None
    scheduled_date: Optional[str] = None
    completed: bool = False
    intensity_mode: Optional[str] = None


class VariantSummary(BaseModel):
    id: Optional[str] = None
    intensity: str
    duration_minutes: Optional[int] = None
    swap_count: int = 0


class PrOpportunity(BaseModel):
    exercise_name: str
    current_top: str
    target: str
    confidence: str


class CardContextResponse(BaseModel):
    recommended_mode: str
    local_date: str
    hour_bucket: int
    today_workout: Optional[WorkoutSummary] = None
    tomorrow_workout: Optional[WorkoutSummary] = None
    yesterday_workout_missed: bool = False
    lighter_variant: Optional[VariantSummary] = None
    cycle_variant: Optional[VariantSummary] = None
    equipment_match: str = "unknown"
    recovery_bucket: str = "unknown"
    rationale: str
    streak_extends_if_complete: bool = False
    pr_opportunity_today: Optional[PrOpportunity] = None
    cached: bool = False
    generated_at: str


# ---------------------------------------------------------------------------
# Endpoint
# ---------------------------------------------------------------------------
@router.get("/card-context", response_model=CardContextResponse)
async def workout_card_context(
    request: Request,
    background_tasks: BackgroundTasks,
    tz: Optional[str] = Query(None, description="IANA tz override; header X-User-Timezone wins"),
    refresh: bool = Query(False, description="Force regenerate, bypassing 1h cache"),
    current_user: dict = Depends(get_current_user),
):
    try:
        sb = get_supabase_db()
        user_id = current_user["id"]

        tz_resolved = resolve_timezone(request, sb, user_id)
        if tz_resolved == "UTC" and tz:
            tz_resolved = tz
        try:
            tzinfo = ZoneInfo(tz_resolved)
        except Exception:
            tzinfo = ZoneInfo("UTC")
            tz_resolved = "UTC"

        today_local = user_today_date(request, sb, user_id)
        today_iso = today_local.isoformat()
        yesterday_iso = (today_local - timedelta(days=1)).isoformat()
        tomorrow_iso = (today_local + timedelta(days=1)).isoformat()
        now_local = datetime.now(tzinfo)
        hour_bucket = now_local.hour

        if not refresh:
            cached = _cache_get(user_id, today_iso, hour_bucket)
            if cached is not None:
                payload = dict(cached)
                payload["cached"] = True
                return CardContextResponse(**payload)

        # ---- Pull rows (each best-effort) ---------------------------------
        today_row = _workout_for_date(sb, user_id, today_iso)
        yesterday_row = _workout_for_date(sb, user_id, yesterday_iso)
        tomorrow_row = _workout_for_date(sb, user_id, tomorrow_iso)
        next_row = tomorrow_row or _next_future_workout(sb, user_id, today_iso)

        yesterday_missed = bool(
            yesterday_row and not (
                yesterday_row.get("completed_at") or yesterday_row.get("is_completed")
            )
        )

        recovery, recovery_signals = _recovery_bucket(sb, user_id, yesterday_iso)
        cycle = _cycle_phase(sb, user_id)
        equipment = _equipment_match(sb, user_id, today_row)

        # Paused state — best-effort.
        paused = False
        try:
            ur = sb.client.table("users").select(
                "in_vacation_mode, paused_at"
            ).eq("id", user_id).maybe_single().execute()
            if ur and ur.data:
                paused = bool(ur.data.get("in_vacation_mode") or ur.data.get("paused_at"))
        except Exception:
            pass

        mode = _resolve_mode(
            hour=hour_bucket,
            today_row=today_row,
            next_workout=next_row,
            yesterday_missed=yesterday_missed,
            recovery=recovery,
            cycle_phase=cycle,
            equipment_match=equipment,
            paused=paused,
        )

        # ---- Variants — only build when relevant to the chosen mode -------
        lighter_summary: Optional[Dict[str, Any]] = None
        cycle_summary: Optional[Dict[str, Any]] = None
        if today_row:
            from services.workout.variant_generator import (
                generate_variant, get_cached_variant, persist_variant_cache_row,
            )
            # Lighter variant — produced for `recoveryLighter` AND
            # always pre-cached when recovery is red so the client's
            # one-tap swap is instant.
            if mode in ("recoveryLighter", "equipmentMismatch") or recovery == "red":
                cached_l = get_cached_variant(sb, today_row["id"], "deload")
                if cached_l:
                    lighter_summary = {
                        "id": cached_l.get("id"),
                        "intensity": "deload",
                        "duration_minutes": cached_l.get("duration_minutes"),
                        "swap_count": len(cached_l.get("swaps") or []),
                    }
                else:
                    try:
                        var = generate_variant(today_row, "deload")
                        background_tasks.add_task(
                            persist_variant_cache_row, sb, today_row, var
                        )
                        lighter_summary = {
                            "id": var.get("id"),
                            "intensity": "deload",
                            "duration_minutes": var.get("duration_minutes"),
                            "swap_count": len(var.get("swaps") or []),
                        }
                    except Exception as e:
                        logger.warning(f"[card_context] lighter variant gen failed: {e}")

            # Cycle variant — only when the user is in luteal/menstrual.
            if cycle in ("luteal", "menstrual"):
                cached_c = get_cached_variant(sb, today_row["id"], "moderate")
                if cached_c:
                    cycle_summary = {
                        "id": cached_c.get("id"),
                        "intensity": "moderate",
                        "duration_minutes": cached_c.get("duration_minutes"),
                        "swap_count": len(cached_c.get("swaps") or []),
                    }
                else:
                    try:
                        var = generate_variant(today_row, "moderate")
                        background_tasks.add_task(
                            persist_variant_cache_row, sb, today_row, var
                        )
                        cycle_summary = {
                            "id": var.get("id"),
                            "intensity": "moderate",
                            "duration_minutes": var.get("duration_minutes"),
                            "swap_count": len(var.get("swaps") or []),
                        }
                    except Exception as e:
                        logger.warning(f"[card_context] cycle variant gen failed: {e}")

        # ---- PR opportunity (cache → compute → persist) -------------------
        pr_opp: Optional[Dict[str, Any]] = None
        if today_row and mode in ("scheduledNotStarted", "recoveryLighter", "cycleAdjusted"):
            from services.workout.pr_opportunity_finder import (
                find_pr_opportunity, get_cached_pr_opportunity, persist_pr_opportunity,
            )
            pr_opp = get_cached_pr_opportunity(sb, user_id, today_row["id"], today_local)
            if not pr_opp:
                pr_opp = find_pr_opportunity(user_id, today_row, history_snapshot=None, sb=sb)
                if pr_opp:
                    background_tasks.add_task(
                        persist_pr_opportunity, sb, user_id,
                        today_row["id"], today_local, pr_opp,
                    )

        rationale = _rationale(
            mode,
            sleep_minutes=(recovery_signals or {}).get("sleep_minutes"),
            cycle_phase=cycle,
            yesterday_workout_name=(yesterday_row or {}).get("name"),
        )

        payload: Dict[str, Any] = {
            "recommended_mode": mode,
            "local_date": today_iso,
            "hour_bucket": hour_bucket,
            "today_workout": _workout_summary(today_row),
            "tomorrow_workout": _workout_summary(tomorrow_row) or _workout_summary(next_row),
            "yesterday_workout_missed": yesterday_missed,
            "lighter_variant": lighter_summary,
            "cycle_variant": cycle_summary,
            "equipment_match": equipment,
            "recovery_bucket": recovery,
            "rationale": rationale,
            "streak_extends_if_complete": _streak_extends_if_complete(sb, user_id, today_iso),
            "pr_opportunity_today": pr_opp,
            "cached": False,
            "generated_at": datetime.now(timezone.utc).isoformat(),
        }

        _cache_put(user_id, today_iso, hour_bucket, payload)
        return CardContextResponse(**payload)
    except Exception as e:
        raise safe_internal_error(e, "workout_card_context")
