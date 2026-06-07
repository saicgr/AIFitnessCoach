"""
Heart Health Score service — one fused 0-100 cardiovascular habit score.

Samsung-parity "Heart Health Score": fuses four drivers into a single daily
number (the CHRONIC habit score, distinct from the acute recoveryProvider):

  sleep         7-day average sleep duration vs an 8h target
  activity      7-day moderate-to-vigorous active minutes vs WHO 150/wk
  cardio_strain resting-HR trend (recent 7d vs 28d baseline) — the proxy that
                stands in for Samsung's "Vascular load" (we have no BP)
  body_comp     BMI from the latest body_measurements row

Deterministic (no LLM for the number). Weights renormalize over the drivers
that actually have data — a user with no body-comp logged is scored on the
other three, not penalized. Snapshots to heart_health_daily for the trend +
day-over-day delta. Narration is grounded + cost-capped.
"""
from __future__ import annotations

import logging
import statistics
from datetime import date, timedelta
from typing import Any, Dict, List, Optional

from pydantic import BaseModel

logger = logging.getLogger("heart_health_service")

_WEIGHTS = {"sleep": 0.30, "activity": 0.30, "cardio_strain": 0.25, "body_comp": 0.15}


class HeartComponent(BaseModel):
    key: str
    label: str
    score: Optional[int] = None     # 0-100, None when no data
    display: str                    # human value for the tile (e.g. "6h 41m")
    band: str                       # Good | Fair | Poor | No data


class HeartHealthResponse(BaseModel):
    local_date: str
    score: int                      # 0-100
    delta: Optional[int] = None     # vs previous snapshot
    label: str                      # Excellent | Good | Fair | Poor
    components: List[HeartComponent]
    headline: str
    body: str
    delivery: str = "deterministic_fallback"


def _band(score: Optional[int]) -> str:
    if score is None:
        return "No data"
    if score >= 75:
        return "Good"
    if score >= 50:
        return "Fair"
    return "Poor"


def _label(score: int) -> str:
    if score >= 80:
        return "Excellent"
    if score >= 60:
        return "Good"
    if score >= 40:
        return "Fair"
    return "Poor"


def _fmt_minutes(mins: float) -> str:
    m = int(round(mins))
    h, mm = divmod(m, 60)
    if h and mm:
        return f"{h}h {mm}m"
    if h:
        return f"{h}h"
    return f"{mm}m"


def _clamp(v: float) -> int:
    return int(max(0, min(100, round(v))))


def compute_heart_health(sb, user_id: str, local_date: date) -> Dict[str, Any]:
    """Return the deterministic score + component breakdown (no LLM)."""
    win_start = (local_date - timedelta(days=27)).isoformat()
    seven_start = (local_date - timedelta(days=6)).isoformat()

    rows: List[Dict[str, Any]] = []
    try:
        res = sb.client.table("daily_activity").select(
            "activity_date, sleep_minutes, active_minutes, resting_heart_rate"
        ).eq("user_id", user_id).gte(
            "activity_date", win_start
        ).lte("activity_date", local_date.isoformat()).order("activity_date").execute()
        rows = res.data or []
    except Exception as e:
        logger.warning("[heart_health] daily_activity read failed: %s", e)

    def _seven(col: str) -> List[float]:
        out = []
        for r in rows:
            if r.get("activity_date", "") >= seven_start and r.get(col) is not None:
                try:
                    out.append(float(r[col]))
                except (TypeError, ValueError):
                    pass
        return out

    components: List[HeartComponent] = []

    # --- Sleep (7-day average duration) ---
    sleep_vals = [v for v in _seven("sleep_minutes") if v > 0]
    if sleep_vals:
        avg = statistics.fmean(sleep_vals)
        # 300m->40, 450m->90, 480m->100 (clamped).
        sc = _clamp(40 + (avg - 300) / 3.0)
        components.append(HeartComponent(
            key="sleep", label="7-day sleep average", score=sc,
            display=_fmt_minutes(avg), band=_band(sc)))
    else:
        components.append(HeartComponent(
            key="sleep", label="7-day sleep average", display="No data", band="No data"))

    # --- Activity (7-day moderate-vigorous minutes vs WHO 150/wk) ---
    act_vals = _seven("active_minutes")
    if act_vals:
        weekly = sum(act_vals)
        sc = _clamp(weekly / 150.0 * 100.0)
        components.append(HeartComponent(
            key="activity", label="7-day moderate to vigorous", score=sc,
            display=_fmt_minutes(weekly), band=_band(sc)))
    else:
        components.append(HeartComponent(
            key="activity", label="7-day moderate to vigorous", display="No data", band="No data"))

    # --- Cardio strain (resting-HR trend: recent 7d vs 28d baseline) ---
    rhr_all = [(r.get("activity_date"), r.get("resting_heart_rate")) for r in rows
               if r.get("resting_heart_rate") is not None]
    rhr_recent = [float(v) for d, v in rhr_all if d and d >= seven_start]
    rhr_base = [float(v) for d, v in rhr_all if d and d < seven_start]
    if rhr_recent and rhr_base:
        recent = statistics.fmean(rhr_recent)
        base = statistics.fmean(rhr_base)
        diff = recent - base
        # At/under baseline -> 100; each +1 bpm above -> -8 pts.
        sc = _clamp(100 - max(0.0, diff) * 8.0)
        sign = "+" if diff >= 0 else ""
        components.append(HeartComponent(
            key="cardio_strain", label="Cardio strain", score=sc,
            display=f"{int(round(recent))} bpm ({sign}{int(round(diff))})", band=_band(sc)))
    elif rhr_recent:
        recent = statistics.fmean(rhr_recent)
        components.append(HeartComponent(
            key="cardio_strain", label="Cardio strain", display=f"{int(round(recent))} bpm",
            band="No data"))
    else:
        components.append(HeartComponent(
            key="cardio_strain", label="Cardio strain", display="No data", band="No data"))

    # --- Body composition (BMI from latest body_measurements) ---
    bmi: Optional[float] = None
    try:
        bm = sb.client.table("body_measurements").select(
            "bmi, weight_kg, measured_at"
        ).eq("user_id", user_id).order("measured_at", desc=True).limit(1).execute()
        if bm.data and bm.data[0].get("bmi") is not None:
            bmi = float(bm.data[0]["bmi"])
    except Exception as e:
        logger.debug("[heart_health] body_measurements read skipped: %s", e)
    if bmi is not None:
        # 18.5-24.9 ideal -> 100; penalize either side.
        sc = _clamp(100 - 6.0 * max(0.0, bmi - 25.0) - 6.0 * max(0.0, 18.5 - bmi))
        components.append(HeartComponent(
            key="body_comp", label="BMI", score=sc, display=f"{bmi:.1f}", band=_band(sc)))
    else:
        components.append(HeartComponent(
            key="body_comp", label="BMI", display="No data", band="No data"))

    # --- Fuse: weight-renormalized over components with a score ---
    num = den = 0.0
    for c in components:
        if c.score is not None:
            w = _WEIGHTS.get(c.key, 0.0)
            num += w * c.score
            den += w
    overall = _clamp(num / den) if den > 0 else 0

    return {"score": overall, "components": components, "has_data": den > 0}


def _persist_and_delta(sb, user_id: str, local_date: date, score: int,
                       components: List[HeartComponent]) -> Optional[int]:
    """Upsert today's snapshot, return delta vs the previous snapshot."""
    delta: Optional[int] = None
    try:
        prev = sb.client.table("heart_health_daily").select(
            "local_date, score"
        ).eq("user_id", user_id).lt(
            "local_date", local_date.isoformat()
        ).order("local_date", desc=True).limit(1).execute()
        if prev.data:
            delta = score - int(prev.data[0]["score"])
    except Exception as e:
        logger.debug("[heart_health] prev snapshot read skipped: %s", e)
    try:
        sb.client.table("heart_health_daily").upsert({
            "user_id": user_id,
            "local_date": local_date.isoformat(),
            "score": score,
            "delta": delta,
            "components": {c.key: c.model_dump() for c in components},
        }, on_conflict="user_id,local_date").execute()
    except Exception as e:
        logger.warning("[heart_health] snapshot upsert failed: %s", e)
    return delta


async def build_heart_health_response(
    sb, user_id: str, local_date: date, first_name: Optional[str],
) -> HeartHealthResponse:
    computed = compute_heart_health(sb, user_id, local_date)
    score = computed["score"]
    components: List[HeartComponent] = computed["components"]
    delta = _persist_and_delta(sb, user_id, local_date, score, components)

    # Deterministic fallback copy keyed off the weakest scored component.
    scored = [c for c in components if c.score is not None]
    weakest = min(scored, key=lambda c: c.score) if scored else None
    if not computed["has_data"]:
        fb_head, fb_body = "Build your heart picture", (
            "Log sleep, activity, and body metrics for a few days and your "
            "Heart Health Score comes to life.")
    else:
        fb_head = f"Heart health {_label(score).lower()}"
        if weakest and weakest.score is not None and weakest.score < 60:
            fb_body = (f"Your {weakest.label.lower()} is the biggest lever right now. "
                       f"Nudging it up lifts your whole score.")
        else:
            fb_body = "Your habits are keeping your heart health in a good place. Keep it steady."

    delivery, headline, body = "deterministic_fallback", fb_head, fb_body
    if computed["has_data"]:
        facts: Dict[str, Any] = {"score": score}
        if delta is not None:
            facts["delta"] = delta
        for c in scored:
            facts[f"{c.key}_score"] = c.score
            facts[f"{c.key}_value"] = c.display
        from services.gemini.health_insight import generate_grounded_insight
        ins = await generate_grounded_insight(
            user_id=user_id, kind="heart_health", first_name=first_name, facts=facts,
            fallback_headline=fb_head, fallback_body=fb_body,
            guidance=("Lead with the weakest component and give one specific, "
                      "encouraging habit to improve it. Nutrition tie-ins are welcome "
                      "(e.g. potassium-rich foods for cardiovascular load)."),
        )
        headline, body, delivery = ins["headline"], ins["body"], ins["delivery"]

    return HeartHealthResponse(
        local_date=local_date.isoformat(),
        score=score, delta=delta, label=_label(score),
        components=components, headline=headline, body=body, delivery=delivery,
    )
