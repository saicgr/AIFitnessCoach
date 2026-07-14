"""
Cardio × sleep correlation service.

Computes a Pearson correlation between nightly sleep duration (the night
BEFORE a cardio session) and that session's average pace. Used by
`/cardio-correlation/sleep-pace` and surfaced in the app via the sleep
correlation insight card.

Design notes
------------
- **Paired session definition.** A pair = (cardio_log with a non-null
  `avg_pace_seconds_per_km`) + (the `daily_activity` row dated `performed_at
  - 1 day` with non-null `sleep_minutes > 0`). Mapping cardio→prior-night
  is correct domain modeling: the recovery state at workout start is
  driven by the previous night's sleep, not the night after.
- **Timezone.** `cardio_logs.performed_at` is a UTC instant, but
  `daily_activity.activity_date` is a **user-local calendar date**. The
  workout's local date MUST therefore be resolved in the user's IANA zone
  (`users.timezone`) before we subtract a day — reading `.date()` straight
  off the UTC timestamp mis-pairs every evening workout in a negative-UTC
  offset (a 7pm run in America/Chicago is already "tomorrow" in UTC, so the
  naive math grabs the night *after* the run). Same convention as
  `cardio_autotag_service._local_hour` / `cardio_digest_service`.
- **Source of sleep.** `daily_activity.sleep_minutes` (see
  `backend/api/v1/activity.py` — the same column Apple Health / Health
  Connect imports write). NOTE: per `project_health_connect_sleep_aggregation`
  the import path already aggregates per-session, so reading the daily
  column is correct (no per-stage re-summation needed here).
- **HIIT outlier filter.** Cardio sessions whose `splits_json` shows pace
  variance > 40% across splits are excluded — that's interval work
  (HIIT/fartlek) where avg pace doesn't correlate with steady-state
  fitness. Sessions without splits are kept (assumed steady).
- **Numpy preferred, pure-Python fallback.** `numpy.corrcoef` is fast and
  numerically stable; the fallback exists so unit tests don't depend on
  numpy and so this still runs in stripped-down deploys.

Returned shape (when n >= 20)::

    {
      "r": -0.41,                            # Pearson r in [-1, 1]
      "n": 24,                               # paired sessions
      "slope_sec_per_km_per_hour": -8.3,     # OLS slope of pace on sleep_h
      "copy": "Strong correlation — under-6h nights tank your pace by ~7%.",
    }

Returns `None` if fewer than 20 valid pairs — surfacing a low-signal r
would be irresponsible.
"""
from __future__ import annotations

import hashlib
import random
from datetime import date, datetime, timedelta, timezone
from typing import Any, Dict, List, Optional, Sequence, Tuple
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

try:
    import numpy as _np  # type: ignore
    _HAS_NUMPY = True
except Exception:  # pragma: no cover - numpy is in requirements
    _HAS_NUMPY = False

from core.logger import get_logger

logger = get_logger(__name__)


MIN_PAIRS = 20
SHORT_SLEEP_HOUR_THRESHOLD = 6.0
HIIT_PACE_VARIANCE_THRESHOLD = 0.40  # 40% — flagged as interval work


# Copy variant pool (>= 4 — required by spec / no_caveats_just_fix policy).
# Each template takes (r, pct_slower) and renders a human, single-sentence line.
# We pick deterministically per (user, n, r) so the copy is stable across
# refreshes until the underlying data changes.
_COPY_VARIANTS = [
    "Your pace is {pct:.0f}% slower after nights under 6h.",
    "Strong correlation — under-6h nights tank your pace by ~{pct:.0f}%.",
    "Pattern detected: short sleep → slower runs (r={r:.2f}).",
    "30-day data shows pace dips ~{pct:.0f}% when you sleep <6h.",
    "Heads up — nights under 6h cost you about {pct:.0f}% on pace (r={r:.2f}).",
]


# ---------------------------------------------------------------------------
# Math helpers
# ---------------------------------------------------------------------------

def _pearson(xs: Sequence[float], ys: Sequence[float]) -> float:
    """Pearson correlation. Returns 0.0 for degenerate input (zero variance)."""
    if _HAS_NUMPY:
        try:
            arr = _np.corrcoef(_np.asarray(xs, dtype=float),
                               _np.asarray(ys, dtype=float))
            r = float(arr[0, 1])
            if r != r:  # NaN — zero variance on one side
                return 0.0
            return max(-1.0, min(1.0, r))
        except Exception:  # pragma: no cover - falls through to pure python
            pass

    n = len(xs)
    if n < 2:
        return 0.0
    mx = sum(xs) / n
    my = sum(ys) / n
    num = sum((x - mx) * (y - my) for x, y in zip(xs, ys))
    denx = sum((x - mx) ** 2 for x in xs)
    deny = sum((y - my) ** 2 for y in ys)
    if denx <= 0 or deny <= 0:
        return 0.0
    return max(-1.0, min(1.0, num / ((denx * deny) ** 0.5)))


def _ols_slope(xs: Sequence[float], ys: Sequence[float]) -> float:
    """OLS slope of y on x. Used for the human-readable "sec/km per hour" stat."""
    n = len(xs)
    if n < 2:
        return 0.0
    mx = sum(xs) / n
    my = sum(ys) / n
    num = sum((x - mx) * (y - my) for x, y in zip(xs, ys))
    den = sum((x - mx) ** 2 for x in xs)
    if den <= 0:
        return 0.0
    return num / den


def _splits_pace_variance(splits_json: Optional[List[Dict[str, Any]]]) -> Optional[float]:
    """Coefficient of variation of per-split pace.

    Returns None when splits are missing/unusable (caller treats as steady).
    """
    if not splits_json or not isinstance(splits_json, list):
        return None
    paces: List[float] = []
    for s in splits_json:
        if not isinstance(s, dict):
            continue
        p = s.get("avg_pace_seconds_per_km") or s.get("pace_seconds_per_km") or s.get("pace")
        try:
            pv = float(p) if p is not None else None
        except (TypeError, ValueError):
            pv = None
        if pv is not None and pv > 0:
            paces.append(pv)
    if len(paces) < 3:
        return None
    mean = sum(paces) / len(paces)
    if mean <= 0:
        return None
    var = sum((p - mean) ** 2 for p in paces) / len(paces)
    return (var ** 0.5) / mean


# ---------------------------------------------------------------------------
# Copy selection
# ---------------------------------------------------------------------------

def _short_sleep_pace_penalty_pct(
    sleep_hours: Sequence[float], pace_sec_per_km: Sequence[float]
) -> float:
    """Average % slower pace on <6h nights vs >=6h nights.

    Returns 0.0 if either bucket is empty.
    """
    short = [p for h, p in zip(sleep_hours, pace_sec_per_km) if h < SHORT_SLEEP_HOUR_THRESHOLD]
    normal = [p for h, p in zip(sleep_hours, pace_sec_per_km) if h >= SHORT_SLEEP_HOUR_THRESHOLD]
    if not short or not normal:
        return 0.0
    short_mean = sum(short) / len(short)
    normal_mean = sum(normal) / len(normal)
    if normal_mean <= 0:
        return 0.0
    # Higher seconds/km = slower. Positive % = slower on short-sleep nights.
    return max(0.0, (short_mean - normal_mean) / normal_mean * 100.0)


def _pick_copy(r: float, pct: float, user_id: str, n: int) -> str:
    """Deterministically pick a copy variant — stable per (user, n, r-bucket)."""
    # r-bucket avoids re-rolling the variant when r drifts by 0.001.
    seed_key = f"{user_id}|{n}|{round(r, 1)}"
    digest = hashlib.md5(seed_key.encode()).digest()
    idx = digest[0] % len(_COPY_VARIANTS)
    template = _COPY_VARIANTS[idx]
    # Some templates ignore one of the args — Python str.format tolerates extras.
    return template.format(r=r, pct=pct)


# ---------------------------------------------------------------------------
# Timezone helpers
# ---------------------------------------------------------------------------

def _safe_zone(tz: Optional[str]) -> ZoneInfo:
    """User's IANA zone, falling back to UTC on a missing/garbage value."""
    try:
        return ZoneInfo(tz or "UTC")
    except (ZoneInfoNotFoundError, KeyError, ValueError):
        return ZoneInfo("UTC")


def _fetch_user_timezone(db, user_id: str) -> Optional[str]:
    """`users.timezone` for this user (same lookup as cardio_autotag_service)."""
    try:
        res = (
            db.client.table("users")
            .select("timezone")
            .eq("id", user_id)
            .limit(1)
            .execute()
        )
        if res.data:
            return res.data[0].get("timezone")
    except Exception as exc:
        logger.debug("[CardioCorrelation] timezone lookup failed: %s", exc)
    return None


def _local_date(performed: Any, zone: ZoneInfo) -> Optional[date]:
    """Calendar date of a cardio session **in the user's timezone**.

    `performed_at` is a UTC instant; `daily_activity.activity_date` is a
    user-local date. Converting into `zone` before taking `.date()` is what
    keeps the two aligned (see module docstring).
    """
    if isinstance(performed, str):
        try:
            dt = datetime.fromisoformat(performed.replace("Z", "+00:00"))
        except ValueError:
            return None
    elif isinstance(performed, datetime):
        dt = performed
    else:
        return None
    if dt.tzinfo is None:  # naive rows are UTC by convention
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(zone).date()


# ---------------------------------------------------------------------------
# Data loading
# ---------------------------------------------------------------------------

def _load_cardio_logs(db, user_id: str, days: int) -> List[Dict[str, Any]]:
    """Cardio sessions in the lookback window with a non-null pace.

    Pulls the full row so we can inspect `splits_json` for the HIIT filter.
    """
    since = (datetime.now(timezone.utc) - timedelta(days=days)).isoformat()
    try:
        resp = (
            db.client.table("cardio_logs")
            .select("*")
            .eq("user_id", user_id)
            .gte("performed_at", since)
            .not_.is_("avg_pace_seconds_per_km", "null")
            .execute()
        )
    except Exception as exc:
        logger.warning("[CardioCorrelation] cardio_logs query failed: %s", exc)
        return []
    return list(resp.data or [])


def _load_sleep_by_date(db, user_id: str, days: int, zone: ZoneInfo) -> Dict[date, int]:
    """`{activity_date: sleep_minutes}` for the lookback window.

    The window bound is computed from the user's local "today" — these rows
    are keyed by user-local calendar dates, so anchoring on the server's
    date would clip (or over-fetch) a day at the edge.
    """
    # +1 because the night-before for the oldest cardio session falls outside the cardio window.
    today_local = datetime.now(zone).date()
    since = (today_local - timedelta(days=days + 1)).isoformat()
    try:
        resp = (
            db.client.table("daily_activity")
            .select("activity_date,sleep_minutes")
            .eq("user_id", user_id)
            .gte("activity_date", since)
            .execute()
        )
    except Exception as exc:
        logger.warning("[CardioCorrelation] daily_activity query failed: %s", exc)
        return {}
    out: Dict[date, int] = {}
    for row in (resp.data or []):
        d = row.get("activity_date")
        s = row.get("sleep_minutes")
        if not d or s is None:
            continue
        if isinstance(d, str):
            try:
                d = date.fromisoformat(d[:10])
            except ValueError:
                continue
        try:
            sm = int(s)
        except (TypeError, ValueError):
            continue
        if sm <= 0:
            continue
        out[d] = sm
    return out


def _pair_sessions(
    cardio: List[Dict[str, Any]],
    sleep_by_date: Dict[date, int],
    zone: ZoneInfo,
) -> List[Tuple[float, float]]:
    """Build (sleep_hours_prior_night, pace_seconds_per_km) pairs.

    Drops HIIT (high split variance), missing prior-night sleep, and
    sessions with unparseable timestamps. `zone` is the user's IANA zone —
    the workout's calendar date is resolved there, NOT in UTC.
    """
    pairs: List[Tuple[float, float]] = []
    for row in cardio:
        pace = row.get("avg_pace_seconds_per_km")
        performed = row.get("performed_at")
        if pace is None or performed is None:
            continue
        try:
            pace_f = float(pace)
        except (TypeError, ValueError):
            continue
        if pace_f <= 0:
            continue

        # HIIT outlier filter.
        cov = _splits_pace_variance(row.get("splits_json"))
        if cov is not None and cov > HIIT_PACE_VARIANCE_THRESHOLD:
            continue

        # Local calendar date of the session (UTC instant -> user's zone).
        session_day = _local_date(performed, zone)
        if session_day is None:
            continue

        # Prior-night sleep = sleep dated the day BEFORE the cardio session.
        prior_night = session_day - timedelta(days=1)
        sleep_min = sleep_by_date.get(prior_night)
        if sleep_min is None:
            continue
        sleep_hours = sleep_min / 60.0
        pairs.append((sleep_hours, pace_f))
    return pairs


# ---------------------------------------------------------------------------
# Public entry point
# ---------------------------------------------------------------------------

def compute_sleep_pace_correlation(
    db, user_id: str, days: int = 30
) -> Optional[Dict[str, Any]]:
    """Correlate prior-night sleep duration with cardio pace.

    Returns None when fewer than `MIN_PAIRS` valid pairs exist — a low-N
    correlation is noise; surfacing it would lie to the user.

    Parameters
    ----------
    db
        Supabase wrapper with `.client.table(...)` (see `core.db.facade`).
    user_id
        Authenticated user UUID.
    days
        Lookback window in days. Default 30.
    """
    cardio = _load_cardio_logs(db, user_id, days)
    if len(cardio) < MIN_PAIRS:
        logger.info(
            "[CardioCorrelation] user=%s cardio=%d <%d — skip",
            user_id, len(cardio), MIN_PAIRS,
        )
        return None

    # Sleep rows are keyed by user-local dates — resolve the zone once and do
    # every calendar comparison in it.
    zone = _safe_zone(_fetch_user_timezone(db, user_id))

    sleep_by_date = _load_sleep_by_date(db, user_id, days, zone)
    if not sleep_by_date:
        logger.info("[CardioCorrelation] user=%s no sleep data — skip", user_id)
        return None

    pairs = _pair_sessions(cardio, sleep_by_date, zone)
    if len(pairs) < MIN_PAIRS:
        logger.info(
            "[CardioCorrelation] user=%s paired=%d <%d — skip",
            user_id, len(pairs), MIN_PAIRS,
        )
        return None

    sleep_h = [p[0] for p in pairs]
    pace = [p[1] for p in pairs]
    r = _pearson(sleep_h, pace)
    slope = _ols_slope(sleep_h, pace)  # sec/km change per +1 hour of sleep
    pct = _short_sleep_pace_penalty_pct(sleep_h, pace)
    copy = _pick_copy(r, pct, user_id, len(pairs))

    return {
        "r": round(r, 3),
        "n": len(pairs),
        "slope_sec_per_km_per_hour": round(slope, 2),
        "copy": copy,
    }
