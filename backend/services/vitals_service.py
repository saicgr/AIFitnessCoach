"""
Vitals service — overnight bio-signals vs the user's own baseline.

Samsung-parity "Vitals": for each of five overnight signals (resting HR, HRV,
respiratory rate, blood oxygen, skin/body temperature) we compare the latest
reading to a trailing-28-day personal baseline (mean +/- SD) and flag only
meaningful deviations. All readings come from daily_activity (the same table
the daily health sync already upserts — columns: resting_heart_rate, hrv,
respiratory_rate, blood_oxygen, body_temperature).

No fabrication: a signal with too little history (or none synced) returns
state="no_data" so the UI shows a per-signal "needs a compatible wearable"
state rather than a fake number. The narration is grounded + cost-capped via
services/gemini/health_insight.py.
"""
from __future__ import annotations

import logging
import statistics
from datetime import date, timedelta
from typing import Any, Dict, List, Optional

from pydantic import BaseModel

logger = logging.getLogger("vitals_service")

# A "meaningful deviation" is >= this many SDs from the personal baseline.
Z_THRESHOLD = 1.5
# Need at least this many prior nights (excluding the latest) to trust a baseline.
MIN_BASELINE_NIGHTS = 4
BASELINE_WINDOW_DAYS = 28

# key, db_column, label, unit, direction
#   high_bad  -> elevated is the concern (flag when z >= +T)
#   low_bad   -> depressed is the concern (flag when z <= -T)
#   either    -> any large swing is the concern (flag when |z| >= T)
_SIGNALS = [
    ("resting_hr", "resting_heart_rate", "Heart rate", "bpm", "high_bad"),
    ("hrv", "hrv", "HRV", "ms", "low_bad"),
    ("respiratory_rate", "respiratory_rate", "Respiratory rate", "br/min", "high_bad"),
    ("spo2", "blood_oxygen", "Blood oxygen", "%", "low_bad"),
    ("skin_temp", "body_temperature", "Skin temperature", "°", "either"),
]


class VitalSignal(BaseModel):
    key: str
    label: str
    unit: str
    value: Optional[float] = None          # latest reading, None when no_data
    baseline: Optional[float] = None       # personal mean over the window
    z: Optional[float] = None
    direction: str                         # high_bad | low_bad | either
    state: str                             # in_range | out_of_range | no_data


class VitalsResponse(BaseModel):
    local_date: str
    signals: List[VitalSignal]
    out_of_range_count: int
    measured_count: int                    # signals with a real latest reading
    headline: str
    body: str
    delivery: str = "deterministic_fallback"


def _series(rows: List[Dict[str, Any]], col: str) -> List[float]:
    """Ascending-by-date values for a column, nulls dropped."""
    out: List[float] = []
    for r in rows:
        v = r.get(col)
        if v is None:
            continue
        try:
            out.append(float(v))
        except (TypeError, ValueError):
            continue
    return out


def _evaluate_signal(key, col, label, unit, direction, rows) -> VitalSignal:
    vals = _series(rows, col)  # ascending by activity_date
    if len(vals) == 0:
        return VitalSignal(key=key, label=label, unit=unit, direction=direction, state="no_data")
    latest = vals[-1]
    prior = vals[:-1]
    if len(prior) < MIN_BASELINE_NIGHTS:
        # We have a reading but not enough history to judge it.
        return VitalSignal(
            key=key, label=label, unit=unit, value=round(latest, 1),
            direction=direction, state="no_data",
        )
    baseline = statistics.fmean(prior)
    sd = statistics.pstdev(prior) if len(prior) > 1 else 0.0
    z = (latest - baseline) / sd if sd > 1e-9 else 0.0

    if direction == "high_bad":
        out = z >= Z_THRESHOLD
    elif direction == "low_bad":
        out = z <= -Z_THRESHOLD
    else:  # either
        out = abs(z) >= Z_THRESHOLD

    return VitalSignal(
        key=key, label=label, unit=unit,
        value=round(latest, 1), baseline=round(baseline, 1),
        z=round(z, 2), direction=direction,
        state="out_of_range" if out else "in_range",
    )


def compute_vitals(sb, user_id: str, local_date: date) -> List[VitalSignal]:
    """Deterministic per-signal evaluation (no LLM, no network beyond the DB)."""
    cutoff = (local_date - timedelta(days=BASELINE_WINDOW_DAYS)).isoformat()
    try:
        res = sb.client.table("daily_activity").select(
            "activity_date, resting_heart_rate, hrv, respiratory_rate, "
            "blood_oxygen, body_temperature"
        ).eq("user_id", user_id).gte(
            "activity_date", cutoff
        ).lte(
            "activity_date", local_date.isoformat()
        ).order("activity_date").execute()
        rows = res.data or []
    except Exception as e:
        logger.warning("[vitals] daily_activity read failed: %s", e)
        rows = []

    return [_evaluate_signal(*sig, rows) for sig in _SIGNALS]


def _deterministic_copy(signals: List[VitalSignal]) -> Dict[str, str]:
    out = [s for s in signals if s.state == "out_of_range"]
    measured = [s for s in signals if s.state != "no_data"]
    if not measured:
        return {
            "headline": "Connect a wearable",
            "body": "Sync a watch or ring overnight and your vitals will start "
                    "tracking against your personal baseline.",
        }
    if not out:
        return {
            "headline": "All vitals in range",
            "body": "Every overnight signal is sitting in your normal range. "
                    "Nice and steady.",
        }
    names = ", ".join(s.label.lower() for s in out)
    n = len(out)
    return {
        "headline": f"{n} out of range",
        "body": f"Your {names} drifted from your usual pattern. This often "
                f"follows stress, short sleep, or a coming illness. Take it "
                f"a little easier and let your body settle.",
    }


async def build_vitals_response(
    sb, user_id: str, local_date: date, first_name: Optional[str],
) -> VitalsResponse:
    signals = compute_vitals(sb, user_id, local_date)
    out_count = sum(1 for s in signals if s.state == "out_of_range")
    measured = sum(1 for s in signals if s.state != "no_data")
    base = _deterministic_copy(signals)

    delivery = "deterministic_fallback"
    headline, body = base["headline"], base["body"]

    if measured:
        # Ground the narration in the real out-of-range signals + values.
        facts: Dict[str, Any] = {"out_of_range_count": out_count}
        for s in signals:
            if s.value is not None:
                facts[f"{s.key}_value"] = s.value
                if s.baseline is not None:
                    facts[f"{s.key}_baseline"] = s.baseline
                facts[f"{s.key}_state"] = s.state
        from services.gemini.health_insight import generate_grounded_insight
        ins = await generate_grounded_insight(
            user_id=user_id, kind="vitals", first_name=first_name, facts=facts,
            fallback_headline=base["headline"], fallback_body=base["body"],
            guidance=(
                "Explain what the out-of-range signals together suggest "
                "(stress, fatigue, under-recovery, possible illness) and give one "
                "calm next step. If nothing is out of range, reassure briefly."
            ),
        )
        headline, body, delivery = ins["headline"], ins["body"], ins["delivery"]

    return VitalsResponse(
        local_date=local_date.isoformat(),
        signals=signals,
        out_of_range_count=out_count,
        measured_count=measured,
        headline=headline,
        body=body,
        delivery=delivery,
    )
