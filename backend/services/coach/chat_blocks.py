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
import time
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
_COLOR_PROTEIN = "#8E44AD"    # purple (macro-specific — protein)
_COLOR_CALORIES = "#F39C12"   # amber

# Tap targets — a data block may deep-link into the full metric screen when
# tapped (Google-Health style). Detail SUB-routes only (push-safe; NEVER a
# StatefulShellRoute branch root like /nutrition — see project memory).
_TOPIC_TAP_ROUTE: Dict[str, str] = {
    "sleep": "/health/sleep",
    "recovery": "/health/combined",
    "heart_rate": "/health/combined",
    "hrv": "/health/combined",
    "steps": "/health/combined",
    "weight": "/metrics",
    "volume": "/metrics",
    # "nutrition" intentionally omitted — its screen is a branch root.
}

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
    ("nutrition", ("protein", "calorie", "calories", "macro", "macros", "carbs", "kcal", "deficit", "maintenance calories", "how much did i eat", "my diet", "my nutrition", "eating enough")),
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


# Phrases that signal the user wants to see a metric's movement OVER TIME (a
# trend), as opposed to a single current value. When present we make sure a
# grounded `chart` block (built from the metric's real timeseries) leads the
# block list and is never trimmed by the cap. Kept as substrings so natural
# phrasings ("how's my weight trending", "weight over the last 30 days",
# "am I making progress") all match.
_TREND_PHRASES: tuple = (
    "trend", "trending", "over time", "over the last", "over the past",
    "last 30 days", "last 7 days", "last week", "last month",
    "past week", "past month", "history", "chart", "graph", "progress",
    "progressing", "going up", "going down", "changed", "change over",
)


def _is_trend_query(message: str) -> bool:
    """True when the message asks about a metric's movement over time."""
    if not message:
        return False
    text = message.lower()
    return any(p in text for p in _TREND_PHRASES)


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
            "nutrition": _build_nutrition_blocks,
        }.get(topic)
        if builder is None:
            return []

        blocks = builder(db, user_id) or []
        # Defensive: drop anything that isn't a dict before any reordering.
        blocks = [b for b in blocks if isinstance(b, dict)]

        # Attach the deep-link route for this topic so the metric/chart blocks
        # are tappable into the full screen. setdefault never clobbers a route a
        # builder set itself.
        route = _TOPIC_TAP_ROUTE.get(topic)
        if route:
            for b in blocks:
                spec = b.get("spec")
                if b.get("type") in ("metric", "chart", "stat_grid") and isinstance(spec, dict):
                    spec.setdefault("tap_route", route)

        # #19 — when the user explicitly asked about a TREND over time, make
        # sure a grounded `chart` block (built above from the metric's real
        # timeseries — weight_logs / daily_activity / performance_logs) LEADS
        # the list and is never trimmed by the cap. The numbers are unchanged
        # (still straight from DB rows); we only reorder so the timeseries the
        # user asked to see is the first thing rendered.
        if _is_trend_query(message or ""):
            charts = [b for b in blocks if b.get("type") == "chart"]
            if charts:
                rest = [b for b in blocks if b.get("type") != "chart"]
                blocks = charts + rest

        return blocks[:_MAX_BLOCKS]
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

    blocks: List[Dict[str, Any]] = []

    # 7-day sleep TREND (oldest -> newest) — the "last week's sleep" graph for the
    # night coach card. `rows` already holds 7 days (newest-first); reverse it.
    series: List[float] = []
    labels: List[str] = []
    for row in reversed(rows):
        m = _safe_num(row.get("sleep_minutes"))
        if m is not None and m > 0:
            series.append(round(m / 60.0, 1))
            d = str(row.get("activity_date") or "")[:10]
            labels.append(d[5:].replace("-", "/") if len(d) >= 10 else "")
    if len(series) >= 2:
        blocks.append({
            "type": "chart",
            "title": "Sleep · last 7 days",
            "spec": {
                "points": series,
                "x_labels": labels,
                "chart_type": "bar",
                "unit": "h",
                "color": _COLOR_SLEEP,
                "highlight_last": True,
            },
        })

    blocks.append({
        "type": "metric",
        "title": "Last night's sleep",
        "spec": {
            "value": hours,
            "unit": "h",
            "color": _COLOR_SLEEP,
            "subtext": f"{int(total_min)} min asleep",
        },
    })

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
                # A labeled LINE (axes on) rather than a bare sparkline, so the
                # resting-HR trend carries date + value labels like the steps
                # chart. The client thins the x-labels to ~6 evenly-spaced ticks.
                "chart_type": "line",
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


def _build_nutrition_blocks(db: Any, user_id: str) -> List[Dict[str, Any]]:
    """Protein (bar) + calories (line) over the trailing 7 LOGGED days, plus a
    latest-day protein-vs-target headline. Grounded in food_logs only."""
    try:
        start = (_utc_today() - timedelta(days=6)).isoformat()
        summaries = db.get_weekly_nutrition_summary(user_id, start) or []
    except Exception as e:
        logger.debug(f"chat_blocks(nutrition): query failed: {e}")
        return []
    if not summaries:
        return []

    # Only days the user actually LOGGED food — a 0-meal day means "didn't log",
    # not "ate nothing", so counting it as a real zero would mislead the trend.
    logged = [s for s in summaries if (s.get("meal_count") or 0) > 0]
    if len(logged) < 2:
        return []

    protein_pts: List[int] = []
    cal_pts: List[int] = []
    labels: List[str] = []
    for s in logged:
        p = _safe_num(s.get("total_protein_g")) or 0.0
        c = _safe_num(s.get("total_calories")) or 0.0
        protein_pts.append(int(round(p)))
        cal_pts.append(int(round(c)))
        labels.append(_day_label(s.get("date")))

    # Target protein for the headline (optional — degrade gracefully).
    target_protein: Optional[float] = None
    try:
        targets = db.get_user_nutrition_targets(user_id) or {}
        target_protein = _safe_num(targets.get("daily_protein_target_g"))
    except Exception:
        target_protein = None

    blocks: List[Dict[str, Any]] = []

    today_protein = protein_pts[-1]
    metric_spec: Dict[str, Any] = {
        "value": today_protein,
        "unit": "g",
        "color": _COLOR_PROTEIN,
        "subtext": f"{len(protein_pts)} logged days",
    }
    if target_protein and target_protein > 0:
        diff = int(round(today_protein - target_protein))
        direction = "flat" if abs(diff) < 5 else ("up" if diff > 0 else "down")
        metric_spec["subtext"] = f"target {int(round(target_protein))} g"
        metric_spec["delta"] = {"value": abs(diff), "unit": "g", "direction": direction}
    blocks.append({"type": "metric", "title": "Protein (latest day)", "spec": metric_spec})

    blocks.append({
        "type": "chart",
        "title": f"Protein · last {len(protein_pts)} logged days",
        "spec": {
            "chart_type": "bar",
            "color": _COLOR_PROTEIN,
            "unit": "g",
            "points": protein_pts,
            "x_labels": labels,
            "y_min": 0,
            "highlight_last": True,
        },
    })
    if any(c > 0 for c in cal_pts):
        blocks.append({
            "type": "chart",
            "title": f"Calories · last {len(cal_pts)} logged days",
            "spec": {
                "chart_type": "line",
                "color": _COLOR_CALORIES,
                "unit": "kcal",
                "points": cal_pts,
                "x_labels": labels,
                "y_min": 0,
                "highlight_last": True,
            },
        })
    return blocks


def _attach_route(blocks: List[Dict[str, Any]], topic: str) -> List[Dict[str, Any]]:
    """Stamp the topic's deep-link route onto each tappable block."""
    route = _TOPIC_TAP_ROUTE.get(topic)
    if route:
        for b in blocks:
            spec = b.get("spec") if isinstance(b, dict) else None
            if isinstance(spec, dict) and b.get("type") in ("metric", "chart", "stat_grid"):
                spec.setdefault("tap_route", route)
    return blocks


# Maps the insight's `leading_pillar` to the per-topic key used below, so a
# nutrition-themed brief leads with its nutrition graph, a move brief with
# steps, etc. "train" has no grounded graph of its own here, so it falls
# through to the default priority order.
_PILLAR_TO_TOPIC_KEY: Dict[str, str] = {
    "nourish": "nourish",
    "fuel": "nourish",
    "move": "move",
    "sleep": "sleep",
}

# Default priority when no leading pillar is supplied (or its topic has no
# data). Nutrition first: it is the most-logged daily lever and was the gap a
# nutrition-themed brief used to render with NO graph at all.
_BRIEFING_TOPIC_PRIORITY = ["nourish", "sleep", "move", "recovery"]


# Short-TTL memo for the EXPENSIVE part of block building: the four topic
# builders (nutrition + sleep + steps + recovery), each with its own DB queries
# (~780ms). It was recomputed on EVERY coach call, including cache hits, making a
# "cache hit" cost ~0.8s. We now memo the per-topic map by USER ONLY (not by
# leading_pillar / max_blocks), so the per-tip ordering can vary for free while
# the expensive build runs at most once per user / TTL. The blocks are a glance
# graph, so a couple minutes of staleness is fine. Per-worker, expiry-on-read,
# hard size cap so it can't grow unbounded.
_BRIEFING_BLOCK_TTL_S = 120
_by_topic_cache: Dict[str, tuple] = {}  # user_id -> (expiry_monotonic, by_topic)
_BY_TOPIC_CACHE_MAX = 5000


def build_briefing_blocks(
    user_id: str,
    leading_pillar: Optional[str] = None,
    max_blocks: int = 3,
    bypass_cache: bool = False,
) -> List[Dict[str, Any]]:
    """Grounded glance graphs for a daily briefing (morning/evening) or the home
    coach card. Leads with the [leading_pillar]'s topic when that topic has data,
    then follows [_BRIEFING_TOPIC_PRIORITY]; capped at [max_blocks]. The cheap
    ordering runs every call; the expensive per-topic build is memoized per user
    (see note above). NEVER raises; returns [] when no topic has data.

    [bypass_cache] skips the 120s memo READ so the per-topic map is recomputed
    fresh from the DB — used when the client just logged a meal/workout/fast/sleep
    and needs the graph numbers to reflect it immediately (the memo is per-worker,
    so a per-process bust would be unreliable; recomputing reads the source of
    truth regardless of which worker serves the request). The recomputed map is
    still written back to the memo so the next non-bypass call is cheap.
    """
    now = time.monotonic()
    hit = _by_topic_cache.get(user_id)
    if hit is not None and hit[0] > now and not bypass_cache:
        by_topic = hit[1]
    else:
        by_topic = _compute_by_topic(user_id)
        if len(_by_topic_cache) >= _BY_TOPIC_CACHE_MAX:
            _by_topic_cache.clear()
        _by_topic_cache[user_id] = (now + _BRIEFING_BLOCK_TTL_S, by_topic)

    # Cheap reorder: leading-pillar topic first (when it has data), then the
    # default priority. De-duped, never the same topic twice.
    order: List[str] = []
    lead_key = _PILLAR_TO_TOPIC_KEY.get((leading_pillar or "").lower())
    if lead_key and lead_key in by_topic:
        order.append(lead_key)
    for k in _BRIEFING_TOPIC_PRIORITY:
        if k in by_topic and k not in order:
            order.append(k)
    out: List[Dict[str, Any]] = []
    for k in order:
        out += by_topic[k]
    return [b for b in out if isinstance(b, dict)][:max_blocks]


def _compute_by_topic(user_id: str) -> Dict[str, List[Dict[str, Any]]]:
    """Build one curated glance block per topic (nutrition protein bar, sleep
    ring, steps trend, recovery signals) from the user's own data. Returns a
    {topic: [block]} map (UNordered, uncapped) — the caller orders + caps. Reuses
    the never-fabricate per-topic builders. NEVER raises; returns {} on no data.
    """
    try:
        try:
            db = get_supabase_db()
        except Exception as e:
            logger.debug(f"chat_blocks(briefing): DB unavailable: {e}")
            return []

        by_topic: Dict[str, List[Dict[str, Any]]] = {}

        # Nutrition — prefer the protein BAR chart (a real graph) so a
        # nutrition brief actually shows nutrition; fall back to the metric.
        nutr = _build_nutrition_blocks(db, user_id) or []
        nutr_pick = [b for b in nutr
                     if isinstance(b, dict) and b.get("type") == "chart"][:1] \
            or [b for b in nutr if isinstance(b, dict)][:1]
        if nutr_pick:
            by_topic["nourish"] = _attach_route(nutr_pick, "nutrition")

        # Sleep — prefer the 7-day TREND chart ("last week's sleep") so a night
        # card shows the trend; fall back to the last-night metric.
        sleep_all = _build_sleep_blocks(db, user_id) or []
        sleep_bl = [b for b in sleep_all
                    if isinstance(b, dict) and b.get("type") == "chart"][:1] \
            or [b for b in sleep_all
                if isinstance(b, dict) and b.get("type") == "metric"][:1]
        if sleep_bl:
            by_topic["sleep"] = _attach_route(sleep_bl, "sleep")

        # Steps (chart only — the trend, not another headline number).
        steps_bl = [b for b in (_build_steps_blocks(db, user_id) or [])
                    if isinstance(b, dict) and b.get("type") == "chart"][:1]
        if steps_bl:
            by_topic["move"] = _attach_route(steps_bl, "steps")

        # Recovery signals (resting-HR metric + sparkline, + HRV if present).
        rec_bl = (_build_recovery_blocks(db, user_id) or [])[:1]
        if rec_bl:
            by_topic["recovery"] = _attach_route(rec_bl, "recovery")

        return by_topic
    except Exception as e:
        logger.warning(f"chat_blocks: briefing block build failed (no blocks): {e}")
        return {}
