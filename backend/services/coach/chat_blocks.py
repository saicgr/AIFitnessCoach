"""
In-Chat "Blocks" Builder — grounded inline metric cards + charts
=================================================================
Best-effort *decoration* for an AI-coach reply. Given the user's message we
detect the health/training topic it's about and, if (and only if) we have real
data in the user's own tables, we emit a small list of structured "blocks" the
Flutter chat renders inline beneath the text reply (a metric card, a sparkline /
line / bar chart, a stat grid, etc.).

Hard rules (per CLAUDE.md + the approved plan):
  * **GROUNDED BY CONSTRUCTION.** Every number in every block comes straight
    from a DB row. We NEVER fabricate a point, a delta, or a value. When there
    is no relevant data we return ``[]`` — the reply simply has no blocks.
  * **NEVER raise.** Block-building is decoration; a failure must never break
    the chat reply. Every DB read and the whole entrypoint are wrapped so any
    exception degrades to ``[]``.
  * **Charts need >= 2 real points**; metric / stat_grid need the value present.
  * **Cheap + fast.** A couple of already-indexed reads (the same
    ``daily_activity`` / ``user_metrics`` / ``performance_logs`` tables the
    health-context mixin already reads). Capped at ~3 blocks total.

THE BLOCK SCHEMA (verbatim contract the frontend depends on):
  block = {"type": <str>, "title"?: <str>, "spec": <obj>}
    - "metric":    spec={ value: number|str, unit?, subtext?, color?,
                          delta?: { value: number, unit?, direction:
                                    "up"|"down"|"flat" } }
    - "chart":     spec={ chart_type: "line"|"bar"|"sparkline", color?, unit?,
                          points: [number], x_labels?: [str] (aligned to
                          points), y_min?, y_max?, highlight_last?: bool }
                          (x is the index of each point)
    - "stat_grid": spec={ items: [ { label, value: number|str, unit?,
                          status?: "good"|"warn"|"bad"|"neutral" } ] }
    - "text":      spec={ text: str }
    - "divider":   spec={}
"""

from __future__ import annotations

import logging
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

from core.db import get_supabase_db

logger = logging.getLogger(__name__)

# Max blocks we ever attach to a single reply — keeps the chat scroll tidy and
# the payload small.
_MAX_BLOCKS = 3

# Accent colors (hex) per topic — purely presentational; the frontend may
# override. Kept here so a topic's metric + chart read as one visual group.
_COLOR_SLEEP = "#6C5CE7"      # indigo
_COLOR_HR = "#E74C3C"         # red
_COLOR_HRV = "#16A085"        # teal
_COLOR_STEPS = "#0984E3"      # blue
_COLOR_WEIGHT = "#00B894"     # green
_COLOR_VOLUME = "#E67E22"     # orange

# How far back each chart looks. Bounded so the query is cheap and the chart
# stays readable on a phone.
_HR_DAYS = 14
_STEPS_DAYS = 30
_WEIGHT_DAYS = 90
_VOLUME_WEEKS = 8

_KG_TO_LB = 2.2046226218


# -----------------------------------------------------------------------------
# Small coercion helpers (mirror health_activity._safe_num / _opt_int)
# -----------------------------------------------------------------------------
def _safe_num(value: Any) -> Optional[float]:
    """Coerce a DB value to float; None for null / unparseable (never raises)."""
    if value is None:
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def _utc_today():
    return datetime.now(timezone.utc).date()


def _day_label(date_str: Any) -> str:
    """Short 'MM/DD' x-axis label from an ISO date/datetime string."""
    try:
        d = datetime.fromisoformat(str(date_str)[:10]).date()
        return f"{d.month}/{d.day}"
    except (ValueError, TypeError):
        return ""


# -----------------------------------------------------------------------------
# Topic detection — simple, robust lowercase keyword match.
# -----------------------------------------------------------------------------
# Ordered by specificity: HRV/HR before generic "recovery", "volume/training"
# last so a generic "progress" question still routes to training volume. The
# first topic whose any-keyword appears wins.
_TOPICS: List[tuple] = [
    ("hrv", ("hrv", "heart rate variability", "variability")),
    ("heart_rate", ("resting heart rate", "resting hr", "heart rate", "rhr", " bpm", "pulse")),
    ("sleep", ("sleep", "slept", "sleeping", "rem", "deep sleep", "bedtime", "rest last night")),
    ("steps", ("steps", "step count", "walking", "walked", "activity", "active", "move", "movement")),
    ("weight", ("weight", "weigh", "bodyweight", "body weight", "lbs", "kgs", "scale", "leaner", "lost weight", "gained weight")),
    ("recovery", ("recovery", "recovered", "readiness", "recover")),
    ("volume", ("volume", "training", "tonnage", "progress", "progressing", "getting stronger", "strength gains", "lifting more")),
]


def _detect_topic(message: str) -> Optional[str]:
    """Return the first matching topic key, or None when nothing matches."""
    if not message:
        return None
    text = message.lower()
    for topic, keywords in _TOPICS:
        for kw in keywords:
            if kw in text:
                return topic
    return None


# -----------------------------------------------------------------------------
# Public entrypoint
# -----------------------------------------------------------------------------
async def build_blocks_for_response(
    *,
    message: str,
    user_id: str,
    intent: Any = None,
    agent_type: Any = None,
) -> List[Dict[str, Any]]:
    """Build grounded inline blocks for a coach reply.

    Args:
        message:    The user's message — drives topic detection.
        user_id:    The user's UUID (DB owner of all data read).
        intent:     Detected CoachIntent (optional; currently advisory).
        agent_type: Routed AgentType (optional; currently advisory).

    Returns:
        A list of 0..~3 block dicts matching the schema above. ``[]`` when the
        topic is unknown or there is no relevant real data. NEVER raises.
    """
    try:
        topic = _detect_topic(message or "")
        if topic is None:
            return []

        try:
            db = get_supabase_db()
        except Exception as e:  # DB unavailable → no decoration, not an error.
            logger.debug(f"chat_blocks: DB unavailable, skipping blocks: {e}")
            return []

        builder = {
            "sleep": _build_sleep_blocks,
            "recovery": _build_recovery_blocks,
            "heart_rate": _build_recovery_blocks,
            "hrv": _build_recovery_blocks,
            "steps": _build_steps_blocks,
            "weight": _build_weight_blocks,
            "volume": _build_volume_blocks,
        }.get(topic)
        if builder is None:
            return []

        blocks = builder(db, user_id) or []
        # Defensive: enforce the cap and drop anything that isn't a dict.
        blocks = [b for b in blocks if isinstance(b, dict)][:_MAX_BLOCKS]
        return blocks
    except Exception as e:
        # Decoration is strictly best-effort — swallow everything.
        logger.warning(f"chat_blocks: build failed (returning no blocks): {e}")
        return []


# -----------------------------------------------------------------------------
# Per-topic builders — each reads real rows and returns [] when data is absent.
# Each builder is itself wrapped in try/except so one topic's DB hiccup degrades
# to [] rather than bubbling up.
# -----------------------------------------------------------------------------
def _recent_activity(db: Any, user_id: str, days: int) -> List[Dict[str, Any]]:
    """Newest-first ``daily_activity`` rows over the trailing `days` window."""
    to_date = _utc_today()
    from_date = to_date - timedelta(days=days)
    rows = db.list_daily_activity(
        user_id=user_id,
        from_date=from_date.isoformat(),
        to_date=to_date.isoformat(),
        limit=days + 1,
    )
    return list(rows or [])


def _build_sleep_blocks(db: Any, user_id: str) -> List[Dict[str, Any]]:
    """Last-night sleep: a metric (hours) + a stat_grid of stages if present."""
    try:
        rows = _recent_activity(db, user_id, 7)
    except Exception as e:
        logger.debug(f"chat_blocks(sleep): query failed: {e}")
        return []
    if not rows:
        return []

    # Newest row carrying a plausible sleep total (matches health_activity).
    sleep_row: Optional[Dict[str, Any]] = None
    for row in rows:  # already newest-first
        total = _safe_num(row.get("sleep_minutes"))
        if total is not None and 30 <= total <= 16 * 60:
            sleep_row = row
            break
    if sleep_row is None:
        return []

    total_min = _safe_num(sleep_row.get("sleep_minutes"))
    if total_min is None or total_min <= 0:
        return []
    hours = round(total_min / 60.0, 1)

    blocks: List[Dict[str, Any]] = [
        {
            "type": "metric",
            "title": "Last night's sleep",
            "spec": {
                "value": hours,
                "unit": "h",
                "color": _COLOR_SLEEP,
                "subtext": f"{int(total_min)} min asleep",
            },
        }
    ]

    # Stage breakdown — only the stages that are actually present.
    stage_items: List[Dict[str, Any]] = []
    for label, col in (("Deep", "deep_sleep_minutes"),
                       ("REM", "rem_sleep_minutes"),
                       ("Light", "light_sleep_minutes")):
        val = _safe_num(sleep_row.get(col))
        if val is not None and val > 0:
            stage_items.append({"label": label, "value": int(round(val)), "unit": "m"})
    if stage_items:
        blocks.append({
            "type": "stat_grid",
            "title": "Sleep stages",
            "spec": {"items": stage_items},
        })

    return blocks


def _build_recovery_blocks(db: Any, user_id: str) -> List[Dict[str, Any]]:
    """Resting-HR sparkline (+ HRV sparkline if present) + today-vs-baseline RHR."""
    try:
        rows = _recent_activity(db, user_id, _HR_DAYS)
    except Exception as e:
        logger.debug(f"chat_blocks(recovery): query failed: {e}")
        return []
    if not rows:
        return []

    # Oldest → newest for a left-to-right chart (rows come newest-first).
    rows_chrono = list(reversed(rows))

    blocks: List[Dict[str, Any]] = []

    # --- resting HR ------------------------------------------------------
    rhr_points: List[float] = []
    rhr_labels: List[str] = []
    for r in rows_chrono:
        v = _safe_num(r.get("resting_heart_rate"))
        if v is not None and v > 0:
            rhr_points.append(round(v, 1))
            rhr_labels.append(_day_label(r.get("activity_date")))

    if len(rhr_points) >= 2:
        # Today vs baseline metric (baseline = mean of the window).
        baseline = round(sum(rhr_points) / len(rhr_points), 1)
        today = rhr_points[-1]
        diff = round(today - baseline, 1)
        direction = "flat" if abs(diff) < 0.5 else ("up" if diff > 0 else "down")
        blocks.append({
            "type": "metric",
            "title": "Resting heart rate",
            "spec": {
                "value": int(round(today)),
                "unit": "bpm",
                "color": _COLOR_HR,
                "subtext": f"{len(rhr_points)}-day avg {int(round(baseline))} bpm",
                "delta": {"value": abs(diff), "unit": "bpm", "direction": direction},
            },
        })
        blocks.append({
            "type": "chart",
            "title": f"Resting HR · last {len(rhr_points)} days",
            "spec": {
                "chart_type": "sparkline",
                "color": _COLOR_HR,
                "unit": "bpm",
                "points": rhr_points,
                "x_labels": rhr_labels,
                "highlight_last": True,
            },
        })

    # --- HRV (only if the column carries real data) ----------------------
    hrv_points: List[float] = []
    hrv_labels: List[str] = []
    for r in rows_chrono:
        v = _safe_num(r.get("hrv"))
        if v is not None and v > 0:
            hrv_points.append(round(v, 1))
            hrv_labels.append(_day_label(r.get("activity_date")))
    if len(hrv_points) >= 2:
        blocks.append({
            "type": "chart",
            "title": f"HRV · last {len(hrv_points)} days",
            "spec": {
                "chart_type": "sparkline",
                "color": _COLOR_HRV,
                "unit": "ms",
                "points": hrv_points,
                "x_labels": hrv_labels,
                "highlight_last": True,
            },
        })

    return blocks


def _build_steps_blocks(db: Any, user_id: str) -> List[Dict[str, Any]]:
    """Daily steps line chart over the trailing 30 days."""
    try:
        rows = _recent_activity(db, user_id, _STEPS_DAYS)
    except Exception as e:
        logger.debug(f"chat_blocks(steps): query failed: {e}")
        return []
    if not rows:
        return []

    rows_chrono = list(reversed(rows))
    points: List[float] = []
    labels: List[str] = []
    for r in rows_chrono:
        v = _safe_num(r.get("steps"))
        if v is not None and v >= 0:
            points.append(int(round(v)))
            labels.append(_day_label(r.get("activity_date")))

    if len(points) < 2:
        return []

    blocks: List[Dict[str, Any]] = [{
        "type": "chart",
        "title": f"Steps · last {len(points)} days",
        "spec": {
            "chart_type": "line",
            "color": _COLOR_STEPS,
            "unit": "steps",
            "points": points,
            "x_labels": labels,
            "y_min": 0,
            "highlight_last": True,
        },
    }]

    # A headline metric for today's steps, when present.
    today = points[-1]
    avg = int(round(sum(points) / len(points)))
    diff = today - avg
    direction = "flat" if abs(diff) < (0.05 * avg if avg else 1) else ("up" if diff > 0 else "down")
    blocks.insert(0, {
        "type": "metric",
        "title": "Steps today",
        "spec": {
            "value": today,
            "unit": "steps",
            "color": _COLOR_STEPS,
            "subtext": f"{len(points)}-day avg {avg:,}",
            "delta": {"value": abs(diff), "unit": "steps", "direction": direction},
        },
    })
    return blocks


def _build_weight_blocks(db: Any, user_id: str) -> List[Dict[str, Any]]:
    """Body-weight line chart over the trailing 90 days (kg).

    Source: ``weight_logs`` (purpose-built, date-ranged). Respecting a user's
    lb preference is not cheaply available at this layer, so we report kg —
    the frontend renders the unit label we pass and may convert if it knows the
    user's preference.
    """
    try:
        to_date = _utc_today()
        from_date = to_date - timedelta(days=_WEIGHT_DAYS)
        rows = db.nutrition.get_weight_logs(
            user_id=user_id,
            limit=120,
            from_date=from_date.isoformat(),
            to_date=to_date.isoformat(),
        ) or []
    except Exception as e:
        logger.debug(f"chat_blocks(weight): query failed: {e}")
        return []
    if not rows:
        return []

    # get_weight_logs orders logged_at DESC → reverse for chronological chart.
    rows_chrono = list(reversed(rows))
    points: List[float] = []
    labels: List[str] = []
    for r in rows_chrono:
        v = _safe_num(r.get("weight_kg"))
        if v is not None and v > 0:
            points.append(round(v, 1))
            labels.append(_day_label(r.get("logged_at")))

    if len(points) < 2:
        return []

    latest = points[-1]
    first = points[0]
    diff = round(latest - first, 1)
    direction = "flat" if abs(diff) < 0.3 else ("up" if diff > 0 else "down")

    return [
        {
            "type": "metric",
            "title": "Current weight",
            "spec": {
                "value": latest,
                "unit": "kg",
                "color": _COLOR_WEIGHT,
                "subtext": f"over {len(points)} logs",
                "delta": {"value": abs(diff), "unit": "kg", "direction": direction},
            },
        },
        {
            "type": "chart",
            "title": f"Weight · last {len(points)} logs",
            "spec": {
                "chart_type": "line",
                "color": _COLOR_WEIGHT,
                "unit": "kg",
                "points": points,
                "x_labels": labels,
                "highlight_last": True,
            },
        },
    ]


def _build_volume_blocks(db: Any, user_id: str) -> List[Dict[str, Any]]:
    """Weekly training volume (sum of reps × weight_kg) bar chart.

    Reads ``performance_logs`` over the trailing ~8 weeks and rolls each set up
    into its ISO-week bucket. Emits a bar chart only when >= 2 weeks carry real
    volume; otherwise [].
    """
    try:
        # Pull a generous window; performance_logs is indexed on (user_id,
        # recorded_at) and capped by limit so this stays cheap.
        logs = db.list_performance_logs(user_id=user_id, limit=600) or []
    except Exception as e:
        logger.debug(f"chat_blocks(volume): query failed: {e}")
        return []
    if not logs:
        return []

    cutoff = _utc_today() - timedelta(weeks=_VOLUME_WEEKS)
    # week_key (ISO year-week) → [total_volume, week_start_date]
    buckets: Dict[tuple, Dict[str, Any]] = {}
    for log in logs:
        recorded = log.get("recorded_at")
        if not recorded:
            continue
        try:
            d = datetime.fromisoformat(str(recorded)[:10]).date()
        except (ValueError, TypeError):
            continue
        if d < cutoff:
            continue
        reps = _safe_num(log.get("reps_completed"))
        weight = _safe_num(log.get("weight_kg"))
        if reps is None or weight is None:
            continue
        vol = reps * weight
        if vol <= 0:
            continue
        iso = d.isocalendar()  # (year, week, weekday)
        key = (iso[0], iso[1])
        # Monday of that ISO week for the label.
        week_start = d - timedelta(days=d.weekday())
        bucket = buckets.setdefault(key, {"vol": 0.0, "start": week_start})
        bucket["vol"] += vol
        if week_start < bucket["start"]:
            bucket["start"] = week_start

    if len(buckets) < 2:
        return []

    # Oldest → newest week.
    ordered = sorted(buckets.items(), key=lambda kv: kv[0])
    points = [int(round(b["vol"])) for _, b in ordered]
    labels = [_day_label(b["start"].isoformat()) for _, b in ordered]

    blocks: List[Dict[str, Any]] = [{
        "type": "chart",
        "title": f"Weekly training volume · last {len(points)} weeks",
        "spec": {
            "chart_type": "bar",
            "color": _COLOR_VOLUME,
            "unit": "kg",
            "points": points,
            "x_labels": labels,
            "y_min": 0,
            "highlight_last": True,
        },
    }]

    # Headline: this week vs last week.
    this_week = points[-1]
    last_week = points[-2]
    diff = this_week - last_week
    direction = "flat" if last_week and abs(diff) < (0.05 * last_week) else ("up" if diff > 0 else "down")
    blocks.insert(0, {
        "type": "metric",
        "title": "This week's volume",
        "spec": {
            "value": this_week,
            "unit": "kg",
            "color": _COLOR_VOLUME,
            "subtext": f"last week {last_week:,} kg",
            "delta": {"value": abs(diff), "unit": "kg", "direction": direction},
        },
    })
    return blocks
