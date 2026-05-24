"""
Race-time predictor service.

Predicts 5K / 10K / half-marathon / marathon finish times from the user's
all-time best run in `cardio_logs`. Uses two classic formulas:

  Riegel (1981):   T2 = T1 * (D2 / D1) ^ 1.06
                   Accurate for short to mid distances where D2 / D1 stays
                   within ~2×. Tends to OVER-PREDICT speed at marathon range.

  Cameron (1998):  Tuned for distances ≥ 10K. Empirically derived to be more
                   accurate at the half / marathon range where Riegel breaks
                   down. We use Cameron when the base run is shorter than the
                   target AND target ≥ half-marathon distance.

                   Cameron formula (Pete Riegel's published derivation of
                   Cameron's coefficients — `bigfeet.com/cameron.html`):
                     a = 13.49681 - 0.048865 * D1_km + 2.438936 / D1_km^0.7905
                     b = 13.49681 - 0.048865 * D2_km + 2.438936 / D2_km^0.7905
                     T2 = (T1 / D1_km) * (a / b) * D2_km

References:
  - Riegel PS. "Athletic records and human endurance" (Am Sci, 1981)
  - Cameron K, derived in Riegel PS, https://www.runningforfitness.org/calc/

No fallback. If fewer than 3 runs exist, returns None values; clients render
the empty state. Per CLAUDE.md "no mock data" and the no-silent-fallbacks
feedback rule.
"""
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any, Dict, Literal, Optional

from pydantic import BaseModel, Field

from core.logger import get_logger

logger = get_logger(__name__)


# =============================================================================
# Constants
# =============================================================================

FIVE_K_M = 5_000
TEN_K_M = 10_000
HALF_M = 21_097.5
MARATHON_M = 42_195.0

PREDICTION_TARGETS: Dict[str, float] = {
    "five_k": FIVE_K_M,
    "ten_k": TEN_K_M,
    "half_marathon": HALF_M,
    "marathon": MARATHON_M,
}

RUN_ACTIVITY_TYPES = {"running", "run", "trail_run", "treadmill"}

# Below this base distance the formulas explode. A 400m sprint can't predict
# marathon time. Per the prompt: hard floor at 800m.
MIN_BASE_DISTANCE_M = 800

# Below this we don't have enough signal to build any prediction.
MIN_RUNS_REQUIRED = 3

# Riegel exponent — the canonical value.
RIEGEL_EXPONENT = 1.06


# =============================================================================
# Models
# =============================================================================

class BaseRunRef(BaseModel):
    cardio_log_id: Optional[str] = None
    distance_m: float
    time_seconds: int
    performed_at: datetime


class RacePrediction(BaseModel):
    predicted_seconds: int = Field(..., gt=0)
    distance_m: int = Field(..., gt=0)
    base_run: Dict[str, Any]
    confidence: float = Field(..., ge=0, le=1)
    formula: Literal["riegel", "cameron"]
    age_days_of_base: int = Field(..., ge=0)


@dataclass
class _Run:
    cardio_log_id: Optional[str]
    distance_m: float
    time_seconds: int
    performed_at: datetime


# =============================================================================
# Math
# =============================================================================

def riegel_predict(t1_seconds: float, d1_m: float, d2_m: float) -> float:
    """T2 = T1 * (D2 / D1) ^ 1.06"""
    if d1_m <= 0 or d2_m <= 0 or t1_seconds <= 0:
        raise ValueError("riegel_predict requires positive distances and time")
    return t1_seconds * ((d2_m / d1_m) ** RIEGEL_EXPONENT)


def _cameron_a(distance_km: float) -> float:
    return 13.49681 - 0.048865 * distance_km + 2.438936 / (distance_km ** 0.7905)


def cameron_predict(t1_seconds: float, d1_m: float, d2_m: float) -> float:
    """Cameron formula — better than Riegel at half/marathon range.

    Returns predicted T2 in seconds. Inputs in metres / seconds.
    """
    if d1_m <= 0 or d2_m <= 0 or t1_seconds <= 0:
        raise ValueError("cameron_predict requires positive distances and time")
    d1_km = d1_m / 1000.0
    d2_km = d2_m / 1000.0
    a1 = _cameron_a(d1_km)
    a2 = _cameron_a(d2_km)
    # T2 = (T1 / D1_km) * (a1 / a2) * D2_km
    return (t1_seconds / d1_km) * (a1 / a2) * d2_km


def _pick_formula(d1_m: float, d2_m: float) -> Literal["riegel", "cameron"]:
    """Riegel is sound up to ~2× extrapolation. Beyond that, and when the
    target is at least half-marathon, Cameron is more accurate."""
    if d2_m >= HALF_M and d2_m > d1_m:
        return "cameron"
    return "riegel"


def _confidence(d1_m: float, d2_m: float, age_days: int) -> float:
    """Confidence band:
      - base distance >= target: 1.0 (interpolation; very reliable)
      - base distance <  target: 0.7 (extrapolation; less reliable)
      - decay 0.05 per 30 days of base age
      - floor at 0.1
    """
    base = 1.0 if d1_m >= d2_m else 0.7
    decay = 0.05 * (age_days / 30.0)
    return max(0.1, min(1.0, base - decay))


# =============================================================================
# DB-facing entrypoint
# =============================================================================

def _fetch_runs(db, user_id: str) -> list[_Run]:
    """Fetch all running cardio_logs for the user.

    Schema reference: backend/api/v1/cardio_logs.py — cardio_logs table.
    We pull distance_m, duration_seconds, performed_at, and filter to running
    activity types. Walking and hiking are excluded — pace dynamics differ.
    """
    try:
        result = (
            db.client.table("cardio_logs")
            .select("id,activity_type,distance_m,duration_seconds,performed_at")
            .eq("user_id", user_id)
            .in_("activity_type", list(RUN_ACTIVITY_TYPES))
            .execute()
        )
    except Exception as e:
        logger.error(f"[RacePredictor] cardio_logs fetch failed user={user_id}: {e}")
        raise

    runs: list[_Run] = []
    for row in result.data or []:
        distance = row.get("distance_m")
        duration = row.get("duration_seconds")
        performed_at_raw = row.get("performed_at")
        if distance is None or duration is None or performed_at_raw is None:
            continue
        try:
            distance_f = float(distance)
            duration_i = int(duration)
        except (TypeError, ValueError):
            continue
        if distance_f < MIN_BASE_DISTANCE_M or duration_i <= 0:
            # Too-short row — keep it for the count but it can't serve as a base.
            # We still append so the MIN_RUNS_REQUIRED gate counts it as a run.
            try:
                performed_at = _parse_dt(performed_at_raw)
            except Exception:
                continue
            runs.append(_Run(row.get("id"), distance_f, duration_i, performed_at))
            continue
        try:
            performed_at = _parse_dt(performed_at_raw)
        except Exception:
            continue
        runs.append(_Run(row.get("id"), distance_f, duration_i, performed_at))
    return runs


def _parse_dt(raw: Any) -> datetime:
    if isinstance(raw, datetime):
        return raw if raw.tzinfo else raw.replace(tzinfo=timezone.utc)
    s = str(raw).replace("Z", "+00:00")
    return datetime.fromisoformat(s)


def _pick_base_run(runs: list[_Run]) -> Optional[_Run]:
    """Pick the user's best base run.

    Strategy: equivalent 5K time via Riegel — for every run with distance
    >= MIN_BASE_DISTANCE_M, compute what it implies for a 5K, take the
    fastest. This avoids "longest run dominates" (a casual 20K beats a
    sharp 5K PR even though the 5K is the better predictor).
    """
    best: Optional[_Run] = None
    best_5k_equiv: Optional[float] = None
    for r in runs:
        if r.distance_m < MIN_BASE_DISTANCE_M:
            continue
        try:
            equiv = riegel_predict(r.time_seconds, r.distance_m, FIVE_K_M)
        except ValueError:
            continue
        if best_5k_equiv is None or equiv < best_5k_equiv:
            best_5k_equiv = equiv
            best = r
    return best


def predict_for_user(db, user_id: str, *, now: Optional[datetime] = None) -> Dict[str, Optional[RacePrediction]]:
    """Return predictions for 5K/10K/half/marathon.

    Empty dict values (None) when:
      - User has fewer than MIN_RUNS_REQUIRED runs total
      - No qualifying base run (none ≥ MIN_BASE_DISTANCE_M)
    """
    now = now or datetime.now(timezone.utc)
    runs = _fetch_runs(db, user_id)

    empty: Dict[str, Optional[RacePrediction]] = {k: None for k in PREDICTION_TARGETS}

    if len(runs) < MIN_RUNS_REQUIRED:
        logger.debug(f"[RacePredictor] user={user_id} only {len(runs)} runs — need {MIN_RUNS_REQUIRED}")
        return empty

    base = _pick_base_run(runs)
    if base is None:
        logger.debug(f"[RacePredictor] user={user_id} no qualifying base run (>= {MIN_BASE_DISTANCE_M}m)")
        return empty

    age_days = max(0, (now - base.performed_at).days)
    base_dict = {
        "cardio_log_id": base.cardio_log_id,
        "distance_m": base.distance_m,
        "time_seconds": base.time_seconds,
        "performed_at": base.performed_at.isoformat(),
    }

    out: Dict[str, Optional[RacePrediction]] = {}
    for key, target_m in PREDICTION_TARGETS.items():
        formula = _pick_formula(base.distance_m, target_m)
        try:
            if formula == "cameron":
                predicted = cameron_predict(base.time_seconds, base.distance_m, target_m)
            else:
                predicted = riegel_predict(base.time_seconds, base.distance_m, target_m)
        except ValueError as e:
            logger.warning(f"[RacePredictor] {key} math failed: {e}")
            out[key] = None
            continue

        confidence = _confidence(base.distance_m, target_m, age_days)
        out[key] = RacePrediction(
            predicted_seconds=int(round(predicted)),
            distance_m=int(round(target_m)),
            base_run=base_dict,
            confidence=round(confidence, 3),
            formula=formula,
            age_days_of_base=age_days,
        )
    return out
