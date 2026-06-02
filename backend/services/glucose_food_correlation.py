"""Glucose ↔ food correlation (Gap 15).

Glucose logging (`glucose_readings`) and food logging (`food_logs`) are siloed —
nothing learns which foods spike THIS user. This correlates each food item to
the post-meal glucose response (peak in the 30-120 min window after the meal)
and surfaces the highest-response foods to the nutrition coach.

Deterministic + grounded: real readings only, no LLM classification, no
fabricated numbers. Diabetes users only (no glucose data → empty result, the
coach line is simply omitted).
"""
from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

from core.db import get_supabase_db
from core.logger import get_logger

logger = get_logger(__name__)

# Post-meal glucose response window. Peak post-prandial glucose typically lands
# ~45-90 min after eating; we scan 30-120 min and take the peak reading.
_WINDOW_START_MIN = 30
_WINDOW_END_MIN = 120
_MIN_OCCURRENCES = 2  # need ≥2 meals with a reading to report a food


def _parse_dt(s: Any) -> Optional[datetime]:
    if not s:
        return None
    try:
        dt = datetime.fromisoformat(str(s).replace("Z", "+00:00"))
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt.astimezone(timezone.utc)
    except Exception:
        return None


def compute_glucose_food_correlations(
    user_id: str,
    db: Any = None,
    days: int = 30,
    top_n: int = 5,
) -> List[Dict[str, Any]]:
    """Return [{food, avg_peak_mg_dl, n, avg_delta_mg_dl}], highest peak first.

    `avg_delta` is peak minus the nearest pre-meal reading (within 30 min before)
    when available — the cleaner "this food raised me by X" signal. Falls back to
    absolute peak when no clean baseline exists. Never raises.
    """
    db = db or get_supabase_db()
    since = (datetime.now(timezone.utc) - timedelta(days=days)).isoformat()

    try:
        foods = (
            db.client.table("food_logs")
            .select("logged_at, food_items")
            .eq("user_id", user_id)
            .gte("logged_at", since)
            .order("logged_at", desc=True)
            .limit(300)
            .execute()
        ).data or []
    except Exception as e:
        logger.debug(f"[glucose_corr] food_logs read failed for {user_id}: {e}")
        return []
    if not foods:
        return []

    try:
        readings = (
            db.client.table("glucose_readings")
            .select("value_mg_dl, recorded_at")
            .eq("user_id", user_id)
            .gte("recorded_at", since)
            .order("recorded_at", desc=False)
            .limit(2000)
            .execute()
        ).data or []
    except Exception as e:
        logger.debug(f"[glucose_corr] glucose read failed for {user_id}: {e}")
        return []
    if not readings:
        return []

    # Pre-parse readings once.
    parsed = []
    for r in readings:
        dt = _parse_dt(r.get("recorded_at"))
        v = r.get("value_mg_dl")
        if dt is not None and v is not None:
            try:
                parsed.append((dt, float(v)))
            except (TypeError, ValueError):
                pass
    parsed.sort(key=lambda x: x[0])
    if not parsed:
        return []

    # Aggregate per food item name.
    agg: Dict[str, Dict[str, float]] = {}

    for log in foods:
        meal_dt = _parse_dt(log.get("logged_at"))
        if meal_dt is None:
            continue
        win_start = meal_dt + timedelta(minutes=_WINDOW_START_MIN)
        win_end = meal_dt + timedelta(minutes=_WINDOW_END_MIN)
        base_start = meal_dt - timedelta(minutes=30)

        peak = None
        baseline = None
        for dt, v in parsed:
            if base_start <= dt <= meal_dt:
                baseline = v  # nearest pre-meal reading (list is time-sorted)
            if win_start <= dt <= win_end:
                if peak is None or v > peak:
                    peak = v
            if dt > win_end:
                break
        if peak is None:
            continue

        delta = (peak - baseline) if baseline is not None else None
        items = log.get("food_items") or []
        for it in items:
            name = (it.get("name") or "").strip().lower() if isinstance(it, dict) else ""
            if not name:
                continue
            a = agg.setdefault(name, {"peak_sum": 0.0, "n": 0.0, "delta_sum": 0.0, "delta_n": 0.0})
            a["peak_sum"] += peak
            a["n"] += 1
            if delta is not None:
                a["delta_sum"] += delta
                a["delta_n"] += 1

    out: List[Dict[str, Any]] = []
    for name, a in agg.items():
        if a["n"] < _MIN_OCCURRENCES:
            continue
        out.append({
            "food": name,
            "avg_peak_mg_dl": round(a["peak_sum"] / a["n"]),
            "avg_delta_mg_dl": round(a["delta_sum"] / a["delta_n"]) if a["delta_n"] else None,
            "n": int(a["n"]),
        })

    # Highest post-meal response first (prefer delta when present, else peak).
    out.sort(key=lambda d: (d["avg_delta_mg_dl"] if d["avg_delta_mg_dl"] is not None else d["avg_peak_mg_dl"]), reverse=True)
    return out[:top_n]


def format_glucose_correlations_for_ai(correlations: List[Dict[str, Any]]) -> str:
    """One compact grounded block for the nutrition coach. '' when empty."""
    if not correlations:
        return ""
    lines = ["GLUCOSE RESPONSE (this user's measured post-meal readings — use to steer picks, never as a diagnosis):"]
    for c in correlations:
        if c.get("avg_delta_mg_dl") is not None:
            lines.append(
                f"- {c['food']}: +{c['avg_delta_mg_dl']} mg/dL post-meal "
                f"(peak ~{c['avg_peak_mg_dl']}, n={c['n']})"
            )
        else:
            lines.append(f"- {c['food']}: peak ~{c['avg_peak_mg_dl']} mg/dL (n={c['n']})")
    lines.append("Favor lower-response foods + pairings (fiber/protein/fat) for this user when relevant.")
    return "\n".join(lines)
