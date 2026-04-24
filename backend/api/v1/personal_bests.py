"""
Personal Bests endpoint.

Feeds the Badge Hub's PERSONAL BESTS grid (Heaviest Lift / Longest Session /
Most Volume). Previously the grid was derived from the trophies feed
filtered by category=='strength' which left it empty ("No data") for users
with real workout history but no formal strength trophy yet.

Source tables (verified against live schema):
  - `personal_records`  → heaviest lift (already populated by the
    PR-detection path in /workouts/{id}/complete).
  - `workouts`          → name + scheduled_date + duration_minutes +
    is_completed for the longest session.
  - `workout_logs.sets_json` → per-set weight/reps as jsonb; we sum
    weight × reps per log to pick the most-volume session. The legacy
    code referred to a `workout_sets` table that does not exist.

Weights returned in lbs (user preference per feedback_weight_units.md).
"""
from __future__ import annotations

import json
from typing import Any, Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from core.logger import get_logger

router = APIRouter(prefix="/personal_bests", tags=["Personal Bests"])
logger = get_logger(__name__)

KG_TO_LB = 2.20462262


class HeaviestLift(BaseModel):
    exercise_name: str
    weight_lb: float
    reps: int
    date: Optional[str] = None


class LongestSession(BaseModel):
    workout_name: str
    duration_minutes: int
    date: Optional[str] = None


class MostVolume(BaseModel):
    workout_name: str
    total_volume_lb: float
    date: Optional[str] = None


class PersonalBestsResponse(BaseModel):
    heaviest_lift: Optional[HeaviestLift] = None
    longest_session: Optional[LongestSession] = None
    most_volume: Optional[MostVolume] = None


def _iso_date(value: Any) -> Optional[str]:
    if not value:
        return None
    s = str(value)
    return s[:10] if len(s) >= 10 else s


def _coerce_jsonb(raw: Any) -> Any:
    """sets_json is stored as jsonb but can come back as a string."""
    if raw is None:
        return None
    if isinstance(raw, (list, dict)):
        return raw
    if isinstance(raw, str):
        try:
            return json.loads(raw)
        except Exception:
            return None
    return None


def _weight_lb(item: dict) -> float:
    """Return weight in lbs, preferring weight_lbs/weight_lb, falling
    back to converting weight_kg. 0 when unset."""
    w = item.get("weight_lbs")
    if w is None:
        w = item.get("weight_lb")
    if w is None:
        kg = item.get("weight_kg")
        if isinstance(kg, (int, float)) and kg > 0:
            return float(kg) * KG_TO_LB
        return 0.0
    if isinstance(w, (int, float)):
        return float(w)
    return 0.0


def _volume_from_sets_json(raw: Any) -> float:
    """Sum weight × reps × set_count across every exercise in a
    workout_log.sets_json. Handles two in-production shapes:

      A) Per-set rows (logged exercises, post-completion):
         [{"reps": 5, "weight_lbs": 185, ...}, …]

      B) Exercise summaries (AI-authored templates saved at completion):
         [{"name": "Bench", "sets": 4, "reps": 8, "weight_kg": 80}, …]
         Here `sets` is an INTEGER (count of sets performed, all at the
         same weight/reps), not a nested list. Volume = w * reps * sets.

      C) Nested list: [{"name": "...", "sets": [{weight, reps}, …]}]
    """
    payload = _coerce_jsonb(raw)
    if payload is None:
        return 0.0

    total = 0.0

    def _add_row(item: dict) -> None:
        nonlocal total
        w_lb = _weight_lb(item)
        reps = item.get("reps")
        if not (isinstance(reps, (int, float)) and reps > 0):
            return
        if w_lb <= 0:
            return
        sets_val = item.get("sets")
        set_count = 1
        if isinstance(sets_val, (int, float)) and sets_val > 0:
            set_count = int(sets_val)
        total += w_lb * float(reps) * float(set_count)

    if isinstance(payload, list):
        for el in payload:
            if not isinstance(el, dict):
                continue
            sets_field = el.get("sets")
            if isinstance(sets_field, list):
                # Shape C: nested per-set list under an exercise dict.
                for s in sets_field:
                    if isinstance(s, dict):
                        _add_row({**s, "sets": 1})
                continue
            # Shape A (sets absent) or Shape B (sets is integer count).
            if "reps" in el and (
                "weight_lbs" in el or "weight_lb" in el or "weight_kg" in el
            ):
                _add_row(el)
    elif isinstance(payload, dict):
        arr = payload.get("exercises") or payload.get("sets")
        if isinstance(arr, list):
            return _volume_from_sets_json(arr)

    return total


@router.get("/{user_id}", response_model=PersonalBestsResponse)
async def get_personal_bests(
    user_id: str,
    current_user: dict = Depends(get_current_user),
) -> PersonalBestsResponse:
    if current_user["id"] != user_id:
        raise HTTPException(
            status_code=403,
            detail="Cannot read another user's personal bests",
        )

    try:
        db = get_supabase_db()

        heaviest: Optional[HeaviestLift] = None
        longest: Optional[LongestSession] = None
        most_vol: Optional[MostVolume] = None

        # ─────────────────────────── Heaviest Lift ───────────────────────────
        # personal_records contains cardio PRs too (weight_kg IS NULL),
        # so filter to strength rows before ordering.
        try:
            pr_rows = (
                db.client.table("personal_records")
                .select("exercise_name, weight_kg, reps, achieved_at")
                .eq("user_id", user_id)
                .not_.is_("weight_kg", "null")
                .gt("weight_kg", 0)
                .order("weight_kg", desc=True)
                .limit(1)
                .execute()
            )
            if pr_rows.data:
                row = pr_rows.data[0]
                weight_kg = float(row.get("weight_kg") or 0)
                if weight_kg > 0:
                    heaviest = HeaviestLift(
                        exercise_name=row.get("exercise_name", "Lift"),
                        weight_lb=round(weight_kg * KG_TO_LB, 1),
                        reps=int(row.get("reps") or 0),
                        date=_iso_date(row.get("achieved_at")),
                    )
        except Exception as e:
            logger.warning(f"[personal_bests] heaviest-lift query failed: {e}")

        # ─────────────────────────── Longest Session ─────────────────────────
        try:
            workout_rows = (
                db.client.table("workouts")
                .select("name, duration_minutes, scheduled_date, completed_at, is_completed")
                .eq("user_id", user_id)
                .eq("is_completed", True)
                .order("duration_minutes", desc=True, nullsfirst=False)
                .limit(1)
                .execute()
            )
            if workout_rows.data:
                w = workout_rows.data[0]
                dur = int(w.get("duration_minutes") or 0)
                if dur > 0:
                    longest = LongestSession(
                        workout_name=w.get("name") or "Workout",
                        duration_minutes=dur,
                        date=_iso_date(
                            w.get("completed_at") or w.get("scheduled_date")
                        ),
                    )
        except Exception as e:
            logger.warning(f"[personal_bests] longest-session query failed: {e}")

        # ─────────────────────────── Most Volume ────────────────────────────
        # No workout_sets table in prod — sets live inside
        # workout_logs.sets_json. Pull all logs, sum per log, pick the
        # biggest. Join back to workouts for the display name/date.
        try:
            log_rows = (
                db.client.table("workout_logs")
                .select("id, workout_id, sets_json, completed_at")
                .eq("user_id", user_id)
                .eq("status", "completed")
                .limit(500)
                .execute()
            )
            best_volume = 0.0
            best_log: Optional[dict] = None
            for row in (log_rows.data or []):
                vol = _volume_from_sets_json(row.get("sets_json"))
                if vol > best_volume:
                    best_volume = vol
                    best_log = row
            if best_log and best_volume > 0:
                name = "Workout"
                date_src = best_log.get("completed_at")
                wid = best_log.get("workout_id")
                if wid:
                    meta = (
                        db.client.table("workouts")
                        .select("name, scheduled_date, completed_at")
                        .eq("id", wid)
                        .limit(1)
                        .execute()
                    )
                    if meta.data:
                        m = meta.data[0]
                        name = m.get("name") or name
                        date_src = (
                            m.get("completed_at")
                            or m.get("scheduled_date")
                            or date_src
                        )
                most_vol = MostVolume(
                    workout_name=name,
                    total_volume_lb=round(best_volume, 0),
                    date=_iso_date(date_src),
                )
        except Exception as e:
            logger.warning(f"[personal_bests] most-volume query failed: {e}")

        return PersonalBestsResponse(
            heaviest_lift=heaviest,
            longest_session=longest,
            most_volume=most_vol,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(
            f"Failed to compute personal bests for {user_id}: {e}",
            exc_info=True,
        )
        raise safe_internal_error(e, "personal_bests")
