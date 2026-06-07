"""
Fitness Index service — 5-axis fitness radar + peer percentile.

Samsung-parity "Fitness Index": five axes each 0-100, an overall, a goal-driven
"focus", and a per-axis percentile vs peers. Every axis is derived from data we
already store; mappings are deterministic heuristics (v1) and clearly bounded.

  body_comp    BMI from body_measurements (ideal 18.5-24.9 band)
  cardio       VO2 max estimate from cardio_metrics
  strength     completed working sets over the last 7 days (volume proxy)
  endurance    chronic training-load capacity (training_load_service)
  flexibility  logged mobility/stretch/yoga sets over 28 days (lowest-data axis)

An axis with no data returns None (the radar greys that spoke) — no fabrication.
Peer percentile comes from the k-anonymous compute_fitness_index_percentile RPC
(NULL until the cohort for an axis reaches 30). Narration is grounded + capped.
"""
from __future__ import annotations

import logging
import math
import statistics
from datetime import date, datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

from pydantic import BaseModel

logger = logging.getLogger("fitness_index_service")

_AXES = ["body_comp", "cardio", "strength", "endurance", "flexibility"]
_AXIS_LABELS = {
    "body_comp": "Body composition",
    "cardio": "Cardio",
    "strength": "Strength",
    "endurance": "Endurance",
    "flexibility": "Flexibility",
}
_MOBILITY_KEYWORDS = (
    "stretch", "yoga", "mobility", "foam", "pigeon", "hip opener",
    "hamstring stretch", "cat cow", "cobra", "child's pose", "thoracic",
)


class FitnessAxis(BaseModel):
    key: str
    label: str
    value: Optional[int] = None       # 0-100, None when no data
    percentile: Optional[int] = None  # vs peers, None under k-anon threshold
    cohort_size: Optional[int] = None


class FitnessIndexResponse(BaseModel):
    local_date: str
    overall: Optional[int] = None
    focus: str
    axes: List[FitnessAxis]
    headline: str
    body: str
    delivery: str = "deterministic_fallback"


def _clamp(v: float) -> int:
    return int(max(0, min(100, round(v))))


def _axis_body_comp(sb, user_id: str) -> Optional[int]:
    try:
        bm = sb.client.table("body_measurements").select(
            "bmi, body_fat_percent, measured_at"
        ).eq("user_id", user_id).order("measured_at", desc=True).limit(1).execute()
        if not bm.data:
            return None
        row = bm.data[0]
        bmi = row.get("bmi")
        if bmi is not None:
            bmi = float(bmi)
            return _clamp(100 - 6.0 * max(0.0, bmi - 25.0) - 6.0 * max(0.0, 18.5 - bmi))
    except Exception as e:
        logger.debug("[fitness_index] body_comp skipped: %s", e)
    return None


def _axis_cardio(sb, user_id: str) -> Optional[int]:
    try:
        cm = sb.client.table("cardio_metrics").select(
            "vo2_max_estimate, measured_at"
        ).eq("user_id", user_id).not_.is_(
            "vo2_max_estimate", "null"
        ).order("measured_at", desc=True).limit(1).execute()
        if not cm.data:
            return None
        vo2 = cm.data[0].get("vo2_max_estimate")
        if vo2 is None:
            return None
        # 25 -> 0, 60 -> 100 (population-rough; monotonic).
        return _clamp((float(vo2) - 25.0) / (60.0 - 25.0) * 100.0)
    except Exception as e:
        logger.debug("[fitness_index] cardio skipped: %s", e)
    return None


def _axis_strength(sb, user_id: str) -> Optional[int]:
    """Completed working sets in the last 7 days -> 0-100 (60 sets/wk = 100)."""
    try:
        cutoff = (datetime.now(timezone.utc) - timedelta(days=7)).isoformat()
        rows = sb.client.table("performance_logs").select(
            "id, is_completed, recorded_at"
        ).eq("user_id", user_id).gte("recorded_at", cutoff).execute()
        data = rows.data or []
        if not data:
            return None
        sets = sum(1 for r in data if r.get("is_completed") is not False)
        return _clamp(sets / 60.0 * 100.0)
    except Exception as e:
        logger.debug("[fitness_index] strength skipped: %s", e)
    return None


def _axis_endurance(sb, user_id: str) -> Optional[int]:
    try:
        from services.training_load_service import current_state
        st = current_state(sb, user_id)
        if not st or st.state == "calibration":
            return None
        # Chronic load (28d capacity). ~80 TRIMP sustained -> 100.
        return _clamp(float(st.chronic_load) / 80.0 * 100.0)
    except Exception as e:
        logger.debug("[fitness_index] endurance skipped: %s", e)
    return None


def _axis_flexibility(sb, user_id: str) -> Optional[int]:
    """Logged mobility/stretch/yoga sets over 28 days. Lowest-data axis."""
    try:
        cutoff = (datetime.now(timezone.utc) - timedelta(days=28)).isoformat()
        rows = sb.client.table("performance_logs").select(
            "exercise_name, recorded_at"
        ).eq("user_id", user_id).gte("recorded_at", cutoff).execute()
        data = rows.data or []
        if not data:
            return None
        mob = 0
        for r in data:
            nm = (r.get("exercise_name") or "").lower()
            if any(kw in nm for kw in _MOBILITY_KEYWORDS):
                mob += 1
        if mob == 0:
            # No mobility work logged in 28 days — honest zero, not "no data",
            # so the radar shows the gap the user can act on.
            return 0
        # 24 mobility sets / 4wk (~daily) -> 100.
        return _clamp(mob / 24.0 * 100.0)
    except Exception as e:
        logger.debug("[fitness_index] flexibility skipped: %s", e)
    return None


def _focus_for_goal(goal: Optional[str]) -> str:
    g = (goal or "").lower()
    if "run" in g or "endurance" in g or "cardio" in g:
        return "Running"
    if "strength" in g or "muscle" in g or "gain" in g or "bulk" in g:
        return "Strength"
    if "lose" in g or "fat" in g or "lean" in g:
        return "Body composition"
    if "flex" in g or "mobility" in g:
        return "Flexibility"
    return "Overall"


def _percentiles(sb, user_id: str) -> Dict[str, Dict[str, Optional[int]]]:
    """Call the k-anonymous percentile RPC. Returns {axis: {percentile, cohort_size}}."""
    out: Dict[str, Dict[str, Optional[int]]] = {}
    try:
        res = sb.client.rpc(
            "compute_fitness_index_percentile", {"p_user_id": user_id}
        ).execute()
        for row in (res.data or []):
            out[row["axis"]] = {
                "percentile": row.get("percentile"),
                "cohort_size": row.get("cohort_size"),
            }
    except Exception as e:
        logger.debug("[fitness_index] percentile RPC skipped: %s", e)
    return out


def compute_fitness_index(sb, user_id: str, local_date: date) -> Dict[str, Any]:
    values: Dict[str, Optional[int]] = {
        "body_comp": _axis_body_comp(sb, user_id),
        "cardio": _axis_cardio(sb, user_id),
        "strength": _axis_strength(sb, user_id),
        "endurance": _axis_endurance(sb, user_id),
        "flexibility": _axis_flexibility(sb, user_id),
    }
    scored = [v for v in values.values() if v is not None]
    overall = _clamp(statistics.fmean(scored)) if scored else None

    focus = "Overall"
    try:
        u = sb.client.table("users").select("primary_goal").eq(
            "id", user_id).maybe_single().execute()
        if u and u.data:
            focus = _focus_for_goal(u.data.get("primary_goal"))
    except Exception as e:
        logger.debug("[fitness_index] goal read skipped: %s", e)

    return {"values": values, "overall": overall, "focus": focus}


def _persist(sb, user_id: str, local_date: date, values: Dict[str, Optional[int]],
             overall: Optional[int], focus: str) -> None:
    try:
        sb.client.table("fitness_index_daily").upsert({
            "user_id": user_id,
            "local_date": local_date.isoformat(),
            "body_comp": values.get("body_comp"),
            "cardio": values.get("cardio"),
            "strength": values.get("strength"),
            "endurance": values.get("endurance"),
            "flexibility": values.get("flexibility"),
            "overall": overall,
            "focus": focus,
        }, on_conflict="user_id,local_date").execute()
    except Exception as e:
        logger.warning("[fitness_index] snapshot upsert failed: %s", e)


async def build_fitness_index_response(
    sb, user_id: str, local_date: date, first_name: Optional[str],
) -> FitnessIndexResponse:
    computed = compute_fitness_index(sb, user_id, local_date)
    values: Dict[str, Optional[int]] = computed["values"]
    overall = computed["overall"]
    focus = computed["focus"]

    _persist(sb, user_id, local_date, values, overall, focus)
    pct = _percentiles(sb, user_id)

    axes = [
        FitnessAxis(
            key=k, label=_AXIS_LABELS[k], value=values.get(k),
            percentile=(pct.get(k) or {}).get("percentile"),
            cohort_size=(pct.get(k) or {}).get("cohort_size"),
        )
        for k in _AXES
    ]

    scored = [a for a in axes if a.value is not None]
    strongest = max(scored, key=lambda a: a.value) if scored else None
    weakest = min(scored, key=lambda a: a.value) if scored else None

    if not scored:
        fb_head, fb_body = "Build your Fitness Index", (
            "Log a workout, a cardio session, and your body metrics and your "
            "five-axis fitness picture fills in.")
    else:
        fb_head = "Your fitness profile"
        fb_body = (f"{strongest.label} is your strength right now"
                   + (f", while {weakest.label.lower()} has the most room to grow."
                      if weakest and weakest.key != strongest.key else ".")
                   + " Train the gap to round out the radar.")

    delivery, headline, body = "deterministic_fallback", fb_head, fb_body
    if scored:
        facts: Dict[str, Any] = {"overall": overall} if overall is not None else {}
        for a in scored:
            facts[f"{a.key}"] = a.value
            if a.percentile is not None:
                facts[f"{a.key}_percentile"] = a.percentile
        from services.gemini.health_insight import generate_grounded_insight
        ins = await generate_grounded_insight(
            user_id=user_id, kind="fitness_index", first_name=first_name, facts=facts,
            fallback_headline=fb_head, fallback_body=fb_body,
            guidance=(f"Name the strongest and weakest axis and give one targeted "
                      f"action to lift the weakest. The user's focus is {focus}."),
        )
        headline, body, delivery = ins["headline"], ins["body"], ins["delivery"]

    return FitnessIndexResponse(
        local_date=local_date.isoformat(),
        overall=overall, focus=focus, axes=axes,
        headline=headline, body=body, delivery=delivery,
    )
