"""
Masteries API — levelled badges shown in the Badge Hub's MASTERIES grid.

A "mastery" is a cumulative counter (steps, calories, sessions, km, minutes,
elevation) that levels up as the user crosses pre-seeded thresholds. Unlike
one-shot trophies, masteries keep re-levelling forever — "Steps Lv.6" only
gets higher.

Design:
- `mastery_definitions` is the static catalog (seeded by migration 1969).
- `user_masteries` stores per-user progress (current_value + current_level).
- This router exposes a single read endpoint; the write path lives inside
  the ingestion jobs that already mutate user_masteries (workout log,
  cardio log, steps sync, etc.). Not POSTable via the API — no client
  should fabricate mastery level bumps.
"""

from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from core.logger import get_logger

router = APIRouter(prefix="/masteries", tags=["Masteries"])
logger = get_logger(__name__)


class MasteryEntry(BaseModel):
    """One mastery row for the Badge Hub grid."""
    key: str                 # 'steps' | 'calories' | 'running' | ...
    label: str               # Display name, e.g. "Steps"
    icon: str                # Material icon key
    unit: str                # 'steps' | 'calories' | 'km' | 'sessions' | 'minutes' | 'meters'
    level: int               # Current level (0 if not yet reached Lv 1)
    current_value: int       # Cumulative raw count
    next_threshold: Optional[int] = None  # Value needed for next level (None if at cap)
    progress_to_next: float = 0.0         # 0.0–1.0 fraction toward next level


class MasteriesResponse(BaseModel):
    masteries: List[MasteryEntry]


def _next_threshold_for(thresholds: list, current_value: int) -> Optional[int]:
    """Find the first threshold the user hasn't crossed yet.

    If the user has passed every seeded threshold, the "next" level is
    computed by doubling the last threshold — Garmin-style open-ended
    ladders keep rewarding progression past the initial seed range.
    """
    for t in thresholds:
        if current_value < t:
            return int(t)
    if thresholds:
        # Past the last seed — keep doubling.
        last = int(thresholds[-1])
        next_t = last * 2
        while next_t <= current_value:
            next_t *= 2
        return next_t
    return None


def _level_for_value(thresholds: list, current_value: int) -> int:
    """How many thresholds has the user crossed?"""
    level = 0
    for t in thresholds:
        if current_value >= t:
            level += 1
        else:
            break
    # Open-ended past the last seed — award an extra level for each
    # doubling of the last threshold.
    if thresholds and current_value >= thresholds[-1]:
        last = int(thresholds[-1])
        step = last * 2
        while current_value >= step:
            level += 1
            step *= 2
    return level


def _progress_to_next(prev_threshold: int, next_threshold: Optional[int], current_value: int) -> float:
    if next_threshold is None or next_threshold <= prev_threshold:
        return 1.0
    span = next_threshold - prev_threshold
    gained = max(0, current_value - prev_threshold)
    return min(1.0, gained / span) if span > 0 else 0.0


@router.get("/{user_id}", response_model=MasteriesResponse)
async def get_user_masteries(
    user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Return the MASTERIES grid for the Badge Hub.

    Joins the static `mastery_definitions` catalog with `user_masteries`
    so every user sees every mastery type — even ones they haven't
    reached Lv 1 on yet (those render as "Lv 0" with progress toward the
    first threshold, preventing a "half-populated grid" feel).
    """
    if current_user["id"] != user_id:
        raise HTTPException(status_code=403, detail="Cannot read another user's masteries")

    try:
        db = get_supabase_db()

        defs = db.client.table("mastery_definitions").select(
            "key, label, icon, unit, level_thresholds, sort_order"
        ).order("sort_order").execute()

        progress_rows = db.client.table("user_masteries").select(
            "mastery_key, current_value, current_level"
        ).eq("user_id", user_id).execute()

        progress_by_key = {}
        for row in (progress_rows.data or []):
            progress_by_key[row["mastery_key"]] = row

        result: List[MasteryEntry] = []
        for d in (defs.data or []):
            thresholds = d.get("level_thresholds") or []
            prog = progress_by_key.get(d["key"]) or {}
            current_value = int(prog.get("current_value") or 0)
            # Prefer the server-side stored level (single source of truth
            # for the celebration triggers) but recompute if the row is
            # missing — a brand-new user has no user_masteries rows yet.
            level = int(prog.get("current_level") or _level_for_value(thresholds, current_value))
            next_t = _next_threshold_for(thresholds, current_value)
            prev_t = int(thresholds[level - 1]) if level > 0 and level <= len(thresholds) else 0
            if level > len(thresholds):
                # Past the seeded range — prev is the doubling we just
                # crossed, calculated the same way _next_threshold_for does.
                last = int(thresholds[-1]) if thresholds else 0
                step = last
                for _ in range(level - len(thresholds) + 1):
                    step *= 2
                prev_t = step // 2

            result.append(MasteryEntry(
                key=d["key"],
                label=d["label"],
                icon=d["icon"],
                unit=d["unit"],
                level=level,
                current_value=current_value,
                next_threshold=next_t,
                progress_to_next=_progress_to_next(prev_t, next_t, current_value),
            ))

        return MasteriesResponse(masteries=result)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to fetch masteries for {user_id}: {e}", exc_info=True)
        raise safe_internal_error(e, "masteries")
