"""Today's logged sets context for the AI Coach — read from the ground truth.

PURPOSE
-------
E2E register row #94: the coach told a user "it looks like you haven't logged
any sets yet" minutes after they logged a real set, because whatever the
coach checked for "did they train" was the `workout_logs` SESSION aggregate
(row 89/90: that row can sit in a contradictory state — e.g.
`total_volume_kg=null` — even while `performance_logs` holds the real set).

`performance_logs` is the durable per-set store — a set can never exist
without a row here. This module reads it DIRECTLY so the coach's "have you
logged anything today" answer is never at the mercy of a stale or
contradictory session summary row.

CONTRACT
--------
``build_todays_sets_context(user_id, user_tz="UTC") -> str``

- Returns a short multi-line string when the user has logged at least one set
  TODAY (local day, per ``core.timezone_utils.local_day_bounds``), e.g.::

      TODAY'S LOGGED SETS (from performance_logs — ground truth, ignore any
      stale session summary that disagrees):
      - Cable Pulldown (pro Lat Bar): 1 set logged (15 kg x 9 reps)

- Returns "" when the user has logged NOTHING today. The empty string is the
  explicit no-data signal — never invent a "you haven't logged anything" line
  here; the coach's own base instructions already handle silence.

- NEVER raises. Any error degrades to "" so this can never block a coach turn.
"""
import asyncio
from typing import Any, Dict, List, Optional

from core.logger import get_logger
from core.timezone_utils import get_user_today, local_day_bounds

logger = get_logger(__name__)

# Hot-path cap — this runs on every coach message, keep it cheap.
_MAX_SETS_FETCHED = 100
_MAX_EXERCISES_SHOWN = 6


def _fetch_todays_sets(client, user_id: str, utc_start: str, utc_end: str) -> List[Dict[str, Any]]:
    """Synchronous Supabase read — run off the event loop via asyncio.to_thread."""
    res = (
        client.table("performance_logs")
        .select("exercise_name, set_number, reps_completed, weight_kg, is_completed, recorded_at")
        .eq("user_id", user_id)
        .gte("recorded_at", utc_start)
        .lt("recorded_at", utc_end)
        .order("recorded_at", desc=False)
        .limit(_MAX_SETS_FETCHED)
        .execute()
    )
    return res.data or []


def _fmt_set(reps: Any, weight_kg: Any) -> str:
    try:
        reps_i = int(reps) if reps is not None else None
    except (TypeError, ValueError):
        reps_i = None
    try:
        weight_f = float(weight_kg) if weight_kg is not None else None
    except (TypeError, ValueError):
        weight_f = None
    if weight_f is not None and reps_i is not None:
        w = int(weight_f) if weight_f == int(weight_f) else round(weight_f, 1)
        return f"{w} kg x {reps_i} reps"
    if reps_i is not None:
        return f"{reps_i} reps"
    return ""


async def build_todays_sets_context(user_id: str, user_tz: str = "UTC") -> str:
    """Compact "what has the user actually logged today" block, from
    ``performance_logs`` directly — never the ``workout_logs`` aggregate."""
    try:
        from core.supabase_db import get_supabase_db

        db = get_supabase_db()
        today = get_user_today(user_tz or "UTC")
        utc_start, utc_end = local_day_bounds(today, user_tz or "UTC")

        # Run the (synchronous) Supabase read off the event loop so the coach
        # hot path is never blocked, mirroring self_tracking_context.py.
        rows = await asyncio.to_thread(_fetch_todays_sets, db.client, user_id, utc_start, utc_end)
        # A set explicitly marked incomplete didn't happen — don't count it.
        rows = [r for r in rows if r.get("is_completed") is not False]
        if not rows:
            return ""

        by_exercise: Dict[str, List[Dict[str, Any]]] = {}
        order: List[str] = []
        for r in rows:
            name = (r.get("exercise_name") or "Unknown exercise").strip()
            if name not in by_exercise:
                by_exercise[name] = []
                order.append(name)
            by_exercise[name].append(r)

        # E2E register row #90/#127: the session-level aggregate (total_sets /
        # total_volume_kg) only ever gets written at workout completion, so a
        # user mid-session asking "how many sets so far, at what weight" has
        # no server-computed answer to fall back on — the coach either reads
        # that not-yet-populated aggregate or invents one. Compute it here,
        # on demand, from the same ground-truth rows, so it's always answered
        # even while the workout is still in progress.
        total_sets = len(rows)
        total_volume_kg = sum(
            (r.get("weight_kg") or 0) * (r.get("reps_completed") or 0) for r in rows
        )
        vol_str = (
            f", ~{int(total_volume_kg)} kg total volume"
            if total_volume_kg > 0
            else ""
        )

        lines = [
            "TODAY'S LOGGED SETS (from performance_logs — ground truth: "
            f"{total_sets} set(s) logged today{vol_str}. This is TRUE even if "
            "another part of your context calls today's workout "
            "'not started'/'scheduled'/incomplete — a workout can be actively "
            "in progress with real logged sets. If a session summary "
            "elsewhere disagrees, trust THIS):"
        ]
        for name in order[:_MAX_EXERCISES_SHOWN]:
            sets = by_exercise[name]
            top = max(sets, key=lambda s: (s.get("weight_kg") or 0))
            set_word = "set" if len(sets) == 1 else "sets"
            top_str = _fmt_set(top.get("reps_completed"), top.get("weight_kg"))
            suffix = f" (top set: {top_str})" if top_str else ""
            lines.append(f"- {name}: {len(sets)} {set_word} logged{suffix}")
        remaining = len(order) - _MAX_EXERCISES_SHOWN
        if remaining > 0:
            lines.append(f"- (+{remaining} more exercise(s) logged today)")

        return "\n".join(lines)
    except Exception as e:  # noqa: BLE001 — fail soft, never block the coach turn
        logger.warning(f"[CoachState] todays_sets_context pre-fetch failed: {e}")
        return ""
