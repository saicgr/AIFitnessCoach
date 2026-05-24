"""
Daily cardio-metric snapshot job (Wave 2 / SLICE_TRENDS).

For each active user, compute 13 derived cardio metrics for today and UPSERT
them into `public.cardio_metric_snapshots` so the Custom Trends chart has a
stable, idempotent per-day history without recomputing on every render.

The 13 registered metric keys (these are the EXACT strings consumed by both
the Flutter `TrendMetric` enum and the read endpoint `/trends/cardio-series`):

  - race_predicted_5k_sec
  - race_predicted_10k_sec
  - race_predicted_half_sec
  - race_predicted_marathon_sec
  - training_load_acute
  - training_load_chronic
  - training_load_acwr
  - cardio_weekly_distance_m
  - cardio_longest_run_m
  - cardio_fastest_mile_sec
  - cardio_pace_avg_sec_per_km
  - cardio_weather_temp_at_run_c
  - refuel_carbs_recommended_g          (best-effort — skipped if no data)

Boolean tags (is_hill_workout etc.) are NOT registered as Custom Trends
metrics — Wave-1 trend infra is numeric-only, by design.

The job is idempotent. Re-running on the same day overwrites values via the
(user_id, snapshot_date, metric_key) UNIQUE constraint.
"""
from __future__ import annotations

import logging
from dataclasses import dataclass
from datetime import date, datetime, timedelta, timezone
from typing import Any, Dict, Iterable, List, Optional

from core.db import get_supabase_db
from services import race_predictor_service, training_load_service

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Constants — kept identical to the Flutter enum + endpoint allowlist.
# ---------------------------------------------------------------------------

ROLLING_WINDOW_DAYS = 7
MILE_M = 1609.34

# Mapping from race_predictor_service key → metric_key persisted in DB.
_RACE_KEY_TO_METRIC = {
    "five_k": "race_predicted_5k_sec",
    "ten_k": "race_predicted_10k_sec",
    "half_marathon": "race_predicted_half_sec",
    "marathon": "race_predicted_marathon_sec",
}

# The authoritative metric-key allowlist (also re-exported below).
REGISTERED_METRIC_KEYS: List[str] = [
    "race_predicted_5k_sec",
    "race_predicted_10k_sec",
    "race_predicted_half_sec",
    "race_predicted_marathon_sec",
    "training_load_acute",
    "training_load_chronic",
    "training_load_acwr",
    "cardio_weekly_distance_m",
    "cardio_longest_run_m",
    "cardio_fastest_mile_sec",
    "cardio_pace_avg_sec_per_km",
    "cardio_weather_temp_at_run_c",
    "refuel_carbs_recommended_g",
]


_RUNNING_ACTIVITY_TYPES = {"run", "running", "trail_run", "treadmill_run"}


@dataclass
class SnapshotRecord:
    """One row to UPSERT into cardio_metric_snapshots."""

    user_id: str
    snapshot_date: date
    metric_key: str
    value_numeric: float
    meta: Optional[Dict[str, Any]] = None

    def to_row(self) -> Dict[str, Any]:
        return {
            "user_id": self.user_id,
            "snapshot_date": self.snapshot_date.isoformat(),
            "metric_key": self.metric_key,
            "value_numeric": float(self.value_numeric),
            "meta": self.meta or {},
        }


# ---------------------------------------------------------------------------
# Cardio activity loader — shared by 7d rolling-window metrics.
# ---------------------------------------------------------------------------

def _fetch_recent_cardio(
    db, user_id: str, since: datetime
) -> List[Dict[str, Any]]:
    """Pull cardio activity from BOTH cardio_logs + cardio_sessions in a window.

    Returns a normalised list of dicts with the keys consumers actually need:
      activity_type, distance_m, duration_seconds, performed_at, weather_json.

    Edge case: missing distance / duration are treated as None (the consumer
    metric simply skips the row instead of fabricating a zero).
    """
    out: List[Dict[str, Any]] = []
    since_iso = since.isoformat()

    # cardio_logs (imported sessions)
    try:
        r = (
            db.client.table("cardio_logs")
            .select("activity_type,distance_m,duration_seconds,performed_at,weather_json")
            .eq("user_id", user_id)
            .gte("performed_at", since_iso)
            .execute()
        )
        for row in (r.data or []):
            out.append({
                "activity_type": (row.get("activity_type") or "").lower(),
                "distance_m": row.get("distance_m"),
                "duration_seconds": row.get("duration_seconds"),
                "performed_at": row.get("performed_at"),
                "weather_json": row.get("weather_json"),
            })
    except Exception as e:  # noqa: BLE001
        logger.warning(f"[CardioSnapshot] cardio_logs fetch failed user={user_id}: {e}")

    # cardio_sessions (manual in-app)
    try:
        r = (
            db.client.table("cardio_sessions")
            .select("cardio_type,distance_m,duration_seconds,started_at,weather_json")
            .eq("user_id", user_id)
            .gte("started_at", since_iso)
            .execute()
        )
        for row in (r.data or []):
            out.append({
                "activity_type": (row.get("cardio_type") or "").lower(),
                "distance_m": row.get("distance_m"),
                "duration_seconds": row.get("duration_seconds"),
                "performed_at": row.get("started_at"),
                "weather_json": row.get("weather_json"),
            })
    except Exception as e:  # noqa: BLE001
        logger.warning(f"[CardioSnapshot] cardio_sessions fetch failed user={user_id}: {e}")

    return out


# ---------------------------------------------------------------------------
# Per-metric computers — each returns Optional[float] (None ⇒ skip metric).
# ---------------------------------------------------------------------------

def _weekly_distance_m(cardio: List[Dict[str, Any]]) -> Optional[float]:
    total = 0.0
    seen = False
    for r in cardio:
        d = r.get("distance_m")
        if d is None:
            continue
        try:
            total += float(d)
            seen = True
        except (TypeError, ValueError):
            continue
    return total if seen else None


def _longest_run_m(cardio: List[Dict[str, Any]]) -> Optional[float]:
    best: Optional[float] = None
    for r in cardio:
        if r["activity_type"] not in _RUNNING_ACTIVITY_TYPES:
            continue
        d = r.get("distance_m")
        if d is None:
            continue
        try:
            v = float(d)
        except (TypeError, ValueError):
            continue
        if best is None or v > best:
            best = v
    return best


def _fastest_mile_sec(cardio: List[Dict[str, Any]]) -> Optional[float]:
    """Best mile-equivalent pace across the rolling window.

    For runs >= 1 mile we compute the proportional time for one mile at the
    session's avg pace. This is a deliberate proxy — we do not have lap data,
    so the "fastest mile" is read as "the best 1-mile-equivalent pace".
    """
    best: Optional[float] = None
    for r in cardio:
        if r["activity_type"] not in _RUNNING_ACTIVITY_TYPES:
            continue
        d, t = r.get("distance_m"), r.get("duration_seconds")
        if d is None or t is None:
            continue
        try:
            d_f, t_f = float(d), float(t)
        except (TypeError, ValueError):
            continue
        if d_f < MILE_M or t_f <= 0:
            continue
        mile_eq = t_f * (MILE_M / d_f)
        if best is None or mile_eq < best:
            best = mile_eq
    return best


def _pace_avg_sec_per_km(cardio: List[Dict[str, Any]]) -> Optional[float]:
    """Distance-weighted average running pace in s/km over the window."""
    tot_d, tot_t = 0.0, 0.0
    for r in cardio:
        if r["activity_type"] not in _RUNNING_ACTIVITY_TYPES:
            continue
        d, t = r.get("distance_m"), r.get("duration_seconds")
        if d is None or t is None:
            continue
        try:
            d_f, t_f = float(d), float(t)
        except (TypeError, ValueError):
            continue
        if d_f <= 0 or t_f <= 0:
            continue
        tot_d += d_f
        tot_t += t_f
    if tot_d <= 0:
        return None
    return (tot_t / tot_d) * 1000.0


def _avg_weather_temp_c(cardio: List[Dict[str, Any]]) -> Optional[float]:
    """Mean run-day temperature from weather_json.{temperature_c}."""
    vals: List[float] = []
    for r in cardio:
        wj = r.get("weather_json") or {}
        if not isinstance(wj, dict):
            continue
        t = wj.get("temperature_c") or wj.get("temp_c")
        if t is None:
            continue
        try:
            vals.append(float(t))
        except (TypeError, ValueError):
            continue
    if not vals:
        return None
    return sum(vals) / len(vals)


def _refuel_carbs_recommended_g(
    db, user_id: str, since: datetime
) -> Optional[float]:
    """Sum of refuel-card recommended carbs over the rolling window.

    The refuel prescription is computed on-demand (no persistence table at
    time of writing). We therefore return None unless a future migration adds
    a `cardio_refuel_prescriptions` table — at which point the lookup below
    will start returning data and the metric becomes populated.
    """
    try:
        r = (
            db.client.table("cardio_refuel_prescriptions")
            .select("carbs_g,issued_at")
            .eq("user_id", user_id)
            .gte("issued_at", since.isoformat())
            .execute()
        )
        rows = r.data or []
    except Exception:
        # Table doesn't exist → metric is genuinely unavailable today.
        return None
    if not rows:
        return None
    total = 0.0
    seen = False
    for row in rows:
        try:
            total += float(row.get("carbs_g") or 0)
            seen = True
        except (TypeError, ValueError):
            continue
    return total if seen else None


# ---------------------------------------------------------------------------
# Per-user compute → list of SnapshotRecord.
# ---------------------------------------------------------------------------

def compute_snapshots_for_user(
    db, user_id: str, *, snapshot_date: Optional[date] = None
) -> List[SnapshotRecord]:
    """Compute every registered metric for one user. Pure function over `db`.

    Returns only records whose value is non-null — a metric with no data is
    NEVER written as 0.0 (silent-fallback violation). The corresponding day
    simply has no row, and the Custom Trends chart honours that gap.
    """
    snapshot_date = snapshot_date or date.today()
    now = datetime.combine(snapshot_date, datetime.min.time(), tzinfo=timezone.utc)
    window_start = now - timedelta(days=ROLLING_WINDOW_DAYS)

    records: List[SnapshotRecord] = []

    # 1) Race predictions (4 metrics)
    try:
        predictions = race_predictor_service.predict_for_user(db, user_id, now=now)
    except Exception as e:  # noqa: BLE001
        logger.warning(f"[CardioSnapshot] race predict failed user={user_id}: {e}")
        predictions = {}
    for race_key, metric_key in _RACE_KEY_TO_METRIC.items():
        p = predictions.get(race_key)
        if p is None:
            continue
        records.append(SnapshotRecord(
            user_id=user_id,
            snapshot_date=snapshot_date,
            metric_key=metric_key,
            value_numeric=float(p.predicted_seconds),
            meta={"confidence": p.confidence, "formula": p.formula,
                  "age_days_of_base": p.age_days_of_base},
        ))

    # 2) Training load (3 metrics)
    try:
        tl_state = training_load_service.current_state(db, user_id)
        if tl_state.daily_trimp > 0 or tl_state.acute_load > 0 or tl_state.chronic_load > 0:
            records.append(SnapshotRecord(
                user_id=user_id, snapshot_date=snapshot_date,
                metric_key="training_load_acute",
                value_numeric=float(tl_state.acute_load),
                meta={"state": tl_state.state},
            ))
            records.append(SnapshotRecord(
                user_id=user_id, snapshot_date=snapshot_date,
                metric_key="training_load_chronic",
                value_numeric=float(tl_state.chronic_load),
                meta={"state": tl_state.state},
            ))
            if tl_state.acwr is not None:
                records.append(SnapshotRecord(
                    user_id=user_id, snapshot_date=snapshot_date,
                    metric_key="training_load_acwr",
                    value_numeric=float(tl_state.acwr),
                    meta={"state": tl_state.state},
                ))
    except Exception as e:  # noqa: BLE001
        logger.warning(f"[CardioSnapshot] training-load failed user={user_id}: {e}")

    # 3) Rolling-window cardio metrics (5 metrics)
    cardio = _fetch_recent_cardio(db, user_id, window_start)

    def _add(key: str, val: Optional[float], **meta: Any) -> None:
        if val is None:
            return
        records.append(SnapshotRecord(
            user_id=user_id, snapshot_date=snapshot_date,
            metric_key=key, value_numeric=float(val), meta=dict(meta) if meta else None,
        ))

    _add("cardio_weekly_distance_m", _weekly_distance_m(cardio),
         window_days=ROLLING_WINDOW_DAYS)
    _add("cardio_longest_run_m", _longest_run_m(cardio),
         window_days=ROLLING_WINDOW_DAYS)
    _add("cardio_fastest_mile_sec", _fastest_mile_sec(cardio),
         window_days=ROLLING_WINDOW_DAYS)
    _add("cardio_pace_avg_sec_per_km", _pace_avg_sec_per_km(cardio),
         window_days=ROLLING_WINDOW_DAYS)
    _add("cardio_weather_temp_at_run_c", _avg_weather_temp_c(cardio),
         window_days=ROLLING_WINDOW_DAYS)

    # 4) Refuel carbs recommended (1 metric — optional/no-op if table absent)
    _add("refuel_carbs_recommended_g",
         _refuel_carbs_recommended_g(db, user_id, window_start),
         window_days=ROLLING_WINDOW_DAYS)

    return records


# ---------------------------------------------------------------------------
# Persistence — idempotent UPSERT.
# ---------------------------------------------------------------------------

def upsert_snapshots(db, records: Iterable[SnapshotRecord]) -> int:
    """UPSERT a batch of snapshot rows. Returns count written.

    Uses the UNIQUE (user_id, snapshot_date, metric_key) constraint so a
    re-run of the same day's job overwrites instead of duplicating.
    """
    rows = [r.to_row() for r in records]
    if not rows:
        return 0
    try:
        (
            db.client.table("cardio_metric_snapshots")
            .upsert(rows, on_conflict="user_id,snapshot_date,metric_key")
            .execute()
        )
        return len(rows)
    except Exception as e:  # noqa: BLE001
        logger.error(f"[CardioSnapshot] upsert failed ({len(rows)} rows): {e}")
        raise


# ---------------------------------------------------------------------------
# Sweep entrypoints — single user + all-users.
# ---------------------------------------------------------------------------

def run_for_user(
    db,
    user_id: str,
    *,
    snapshot_date: Optional[date] = None,
    dry_run: bool = False,
) -> Dict[str, Any]:
    """Compute + (optionally) persist one user's snapshots. Returns summary."""
    records = compute_snapshots_for_user(db, user_id, snapshot_date=snapshot_date)
    if dry_run:
        logger.info(f"[CardioSnapshot] DRY user={user_id} would_write={len(records)}")
        return {"user_id": user_id, "computed": len(records), "wrote": 0,
                "metric_keys": [r.metric_key for r in records]}
    wrote = upsert_snapshots(db, records)
    return {"user_id": user_id, "computed": len(records), "wrote": wrote,
            "metric_keys": [r.metric_key for r in records]}


def _iter_active_users(db) -> Iterable[str]:
    """Stream user_ids for the full sweep.

    "Active" is defined narrowly: users with at least one cardio activity
    in the last 30 days OR a race-prediction-eligible run on record. The
    cheap proxy is "user has any row in cardio_logs OR cardio_sessions in
    the last 30 days" — anyone outside that window cannot produce non-null
    snapshots today anyway.
    """
    cutoff = (datetime.now(timezone.utc) - timedelta(days=30)).isoformat()
    seen: set = set()
    try:
        r = (
            db.client.table("cardio_logs")
            .select("user_id")
            .gte("performed_at", cutoff)
            .execute()
        )
        for row in (r.data or []):
            uid = row.get("user_id")
            if uid and uid not in seen:
                seen.add(uid)
                yield uid
    except Exception as e:  # noqa: BLE001
        logger.warning(f"[CardioSnapshot] active-user fetch (logs) failed: {e}")
    try:
        r = (
            db.client.table("cardio_sessions")
            .select("user_id")
            .gte("started_at", cutoff)
            .execute()
        )
        for row in (r.data or []):
            uid = row.get("user_id")
            if uid and uid not in seen:
                seen.add(uid)
                yield uid
    except Exception as e:  # noqa: BLE001
        logger.warning(f"[CardioSnapshot] active-user fetch (sessions) failed: {e}")


def run_full_sweep(
    db=None,
    *,
    snapshot_date: Optional[date] = None,
    dry_run: bool = False,
) -> Dict[str, Any]:
    """Sweep every active user. Intended to be invoked once per day via cron."""
    db = db or get_supabase_db()
    summaries: List[Dict[str, Any]] = []
    for uid in _iter_active_users(db):
        try:
            summaries.append(run_for_user(
                db, uid, snapshot_date=snapshot_date, dry_run=dry_run,
            ))
        except Exception as e:  # noqa: BLE001
            logger.error(f"[CardioSnapshot] user={uid} failed: {e}")
            summaries.append({"user_id": uid, "error": str(e)})
    total_wrote = sum(s.get("wrote", 0) for s in summaries)
    logger.info(
        f"[CardioSnapshot] sweep done: users={len(summaries)} rows_written={total_wrote}"
    )
    return {"users": len(summaries), "rows_written": total_wrote,
            "dry_run": dry_run, "summaries": summaries}
