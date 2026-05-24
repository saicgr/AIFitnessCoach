"""
Cardio Personal Records Service — sibling to `personal_records_service.py`.

Cardio PRs live in the SAME `personal_records` table as strength PRs
(migration 2094 added `sport` + `is_first_time_activity` columns). Cardio
rows leave `weight_kg`/`reps`/`estimated_1rm_kg` NULL and use the existing
`record_value` / `record_unit` / `previous_value` / `improvement_percent`
columns plus the new `sport` field.

Record types (cardio):
  - longest_distance              (record_unit = 'm')
  - fastest_mile                  (record_unit = 'sec')   — per-mile pace from gps/splits
  - fastest_5k                    (record_unit = 'sec')
  - fastest_10k                   (record_unit = 'sec')
  - longest_duration_session      (record_unit = 'sec')
  - best_avg_speed                (record_unit = 'mph' for cycling display, stored kmh)
  - biggest_weekly_distance_km    (record_unit = 'km')   — rolling 7-day sum

Anti-spam: duplicate-metric PRs within 7d are suppressed unless improvement
exceeds 2%. First-ever activity of a sport short-circuits to is_first_time
candidates on longest_distance + longest_duration_session ONLY (no "fastest
5K" badge for someone's first 5K — that would always be a PR by definition).
"""
from __future__ import annotations

import logging
from datetime import datetime, timezone, timedelta, date
from typing import List, Optional, Dict, Any, Tuple

from pydantic import BaseModel

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

# Cardio activity_type → high-level sport bucket. Cardio PRs are grouped per
# sport, not per fine-grained activity_type (a treadmill run and an outdoor
# run both count toward "running" longest_distance).
ACTIVITY_TYPE_TO_SPORT: Dict[str, str] = {
    "run": "running",
    "trail_run": "running",
    "treadmill": "running",
    "walk": "walking",
    "hike": "hiking",
    "cycle": "cycling",
    "indoor_cycle": "cycling",
    "mountain_bike": "cycling",
    "gravel_bike": "cycling",
    "row": "rowing",
    "erg": "rowing",
    "swim": "swimming",
    "open_water_swim": "swimming",
    "elliptical": "elliptical",
    "stair": "stairs",
    "stepmill": "stairs",
    "ski_erg": "skiing",
    "skate_ski": "skiing",
    "nordic_ski": "skiing",
    "downhill_ski": "skiing",
    "snowboard": "snowboarding",
}

# Distances (meters) used for rolling fastest_5k / fastest_10k / fastest_mile.
MILE_M = 1609.344
FIVE_K_M = 5000.0
TEN_K_M = 10000.0

ANTI_SPAM_WINDOW_DAYS = 7
ANTI_SPAM_MIN_IMPROVEMENT_PCT = 2.0

# Record types that are eligible for the first-time activity short-circuit.
FIRST_TIME_KINDS = ("longest_distance", "longest_duration_session")

ALL_KINDS = (
    "longest_distance",
    "fastest_mile",
    "fastest_5k",
    "fastest_10k",
    "longest_duration_session",
    "best_avg_speed",
    "biggest_weekly_distance_km",
)


# ---------------------------------------------------------------------------
# Models
# ---------------------------------------------------------------------------

class CardioPrCandidate(BaseModel):
    """A potential cardio PR detected from a single cardio_log session.

    `record_value` semantics depend on `kind`:
      - longest_distance      → meters (higher is better)
      - longest_duration_*    → seconds (higher is better)
      - fastest_*             → seconds for the rolling window (LOWER is better)
      - best_avg_speed        → km/h (higher is better)
      - biggest_weekly_distance_km → km (higher is better)
    """
    user_id: str
    sport: str
    kind: str
    record_value: float
    record_unit: str
    previous_value: Optional[float] = None
    improvement_percent: Optional[float] = None
    is_first_time: bool = False
    achieved_at: datetime
    workout_log_id: Optional[str] = None
    celebration_message: str


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _parse_dt(value: Any) -> datetime:
    """Defensive parser — supabase returns ISO strings, tests pass datetimes."""
    if isinstance(value, datetime):
        return value if value.tzinfo else value.replace(tzinfo=timezone.utc)
    if isinstance(value, date):
        return datetime.combine(value, datetime.min.time()).replace(tzinfo=timezone.utc)
    if isinstance(value, str):
        try:
            dt = datetime.fromisoformat(value.replace("Z", "+00:00"))
            return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)
        except ValueError:
            return datetime.now(timezone.utc)
    return datetime.now(timezone.utc)


def _is_lower_better(kind: str) -> bool:
    return kind.startswith("fastest_")


def _improvement_percent(new_value: float, old_value: float, lower_is_better: bool) -> Optional[float]:
    """Returns positive % improvement, or None if no prior or no change."""
    if old_value is None or old_value <= 0:
        return None
    if lower_is_better:
        delta = old_value - new_value
    else:
        delta = new_value - old_value
    if delta <= 0:
        return None
    return round((delta / old_value) * 100, 2)


def _format_pace(sec: float) -> str:
    m, s = divmod(int(round(sec)), 60)
    return f"{m}:{s:02d}"


def _celebration(kind: str, value: float, sport: str, is_first_time: bool) -> str:
    sport_title = sport.title()
    if is_first_time:
        return f"First {sport_title} session logged — welcome to the board!"
    if kind == "longest_distance":
        return f"New longest {sport_title} session — {value/1000:.2f} km!"
    if kind == "longest_duration_session":
        m = int(round(value / 60))
        return f"New longest {sport_title} session — {m} min!"
    if kind == "fastest_mile":
        return f"New fastest mile — {_format_pace(value)}!"
    if kind == "fastest_5k":
        return f"New fastest 5K — {_format_pace(value)}!"
    if kind == "fastest_10k":
        return f"New fastest 10K — {_format_pace(value)}!"
    if kind == "best_avg_speed":
        return f"New top {sport_title} avg speed — {value:.1f} km/h!"
    if kind == "biggest_weekly_distance_km":
        return f"Biggest week of {sport_title} so far — {value:.1f} km!"
    return f"New {sport_title} PR!"


def _rolling_best_time_for_distance(
    splits_json: Optional[List[Dict[str, Any]]],
    gps_polyline: Optional[str],
    target_distance_m: float,
) -> Optional[float]:
    """Compute the fastest rolling time over `target_distance_m`.

    Prefers splits_json (Strava/Garmin per-km/per-mile splits). gps_polyline
    parsing is non-trivial (encoded polyline + per-point timestamps) — the
    detection layer can pass already-decoded points via splits_json. If
    neither is present, returns None and the metric is skipped silently.

    splits_json format expected (flexible, mirrors Strava/Garmin):
      [{"distance_m": 1000.0, "elapsed_sec": 300.0}, ...]
      OR [{"distance": 1.0, "time": 300}] (km + sec — back-compat)
    """
    if not splits_json:
        return None

    # Normalize each split to (distance_m, elapsed_sec).
    norm: List[Tuple[float, float]] = []
    for s in splits_json:
        if not isinstance(s, dict):
            continue
        d = s.get("distance_m")
        if d is None and "distance" in s:
            d = float(s["distance"]) * 1000.0  # assume km
        t = s.get("elapsed_sec") or s.get("time") or s.get("duration_sec")
        if d is None or t is None or d <= 0 or t <= 0:
            continue
        norm.append((float(d), float(t)))

    if not norm:
        return None

    # Rolling window: walk cumulative distance, find min time covering target.
    cum_d, cum_t = 0.0, 0.0
    cumulative: List[Tuple[float, float]] = [(0.0, 0.0)]
    for d, t in norm:
        cum_d += d
        cum_t += t
        cumulative.append((cum_d, cum_t))

    if cum_d < target_distance_m:
        return None

    # For each end-point, find the latest start-point whose cumulative
    # distance is <= (cum_d_end - target). The window time is
    # cum_t_end - cum_t_start; if the gap distance >= target we have a
    # candidate. This is O(n^2) but n = ~26 (marathon split count) — fine.
    best: Optional[float] = None
    for i in range(1, len(cumulative)):
        d_end, t_end = cumulative[i]
        for j in range(i):
            d_start, t_start = cumulative[j]
            if d_end - d_start >= target_distance_m:
                window_t = t_end - t_start
                # Pro-rate if the window is longer than target (overshoot).
                window_d = d_end - d_start
                if window_d > 0:
                    proj = window_t * (target_distance_m / window_d)
                    if best is None or proj < best:
                        best = proj
                break
    return best


# ---------------------------------------------------------------------------
# Service
# ---------------------------------------------------------------------------

class CardioPrService:
    """Detects and persists cardio personal records."""

    # ----- public API ------------------------------------------------------

    def detect_cardio_prs(
        self,
        db: Any,
        cardio_log_id: str,
        *,
        cardio_log_override: Optional[Dict[str, Any]] = None,
    ) -> List[CardioPrCandidate]:
        """Detect all cardio PRs for the given cardio_log row.

        `cardio_log_override` lets tests inject a row without a live DB
        round-trip. Production passes `None` and the row is loaded via
        `db.client.table("cardio_logs")`.
        """
        row = cardio_log_override or self._load_cardio_log(db, cardio_log_id)
        if not row:
            return []

        activity_type = row.get("activity_type")
        sport = ACTIVITY_TYPE_TO_SPORT.get(activity_type)
        if not sport:
            logger.debug("[CardioPR] no sport mapping for activity=%s", activity_type)
            return []

        user_id = str(row["user_id"])
        achieved_at = _parse_dt(row.get("performed_at"))

        existing = self._load_existing_prs(db, user_id, sport)
        is_first_time = len(existing) == 0

        # Pre-compute per-kind candidate values.
        duration_s = float(row.get("duration_seconds") or 0)
        distance_m = float(row.get("distance_m") or 0)
        avg_speed_mps = row.get("avg_speed_mps")
        splits_json = row.get("splits_json")
        gps_polyline = row.get("gps_polyline")

        candidates: List[CardioPrCandidate] = []

        def _maybe_emit(kind: str, value: float, unit: str) -> None:
            prior = self._best_existing(existing, kind)
            lower_better = _is_lower_better(kind)
            if prior is None:
                # No prior record for this kind. Emit unless first_time
                # short-circuit is active (handled below).
                if not is_first_time:
                    candidates.append(CardioPrCandidate(
                        user_id=user_id,
                        sport=sport,
                        kind=kind,
                        record_value=round(value, 4),
                        record_unit=unit,
                        previous_value=None,
                        improvement_percent=None,
                        is_first_time=False,
                        achieved_at=achieved_at,
                        workout_log_id=str(row.get("id")) if row.get("id") else None,
                        celebration_message=_celebration(kind, value, sport, False),
                    ))
                return

            prior_value = float(prior["record_value"])
            beats = (value < prior_value) if lower_better else (value > prior_value)
            if not beats:
                return

            improvement = _improvement_percent(value, prior_value, lower_better) or 0.0

            # Anti-spam: skip if a same-metric PR was set in the last
            # ANTI_SPAM_WINDOW_DAYS unless the improvement exceeds threshold.
            last_dt = _parse_dt(prior.get("achieved_at"))
            if (achieved_at - last_dt) < timedelta(days=ANTI_SPAM_WINDOW_DAYS) \
                    and improvement < ANTI_SPAM_MIN_IMPROVEMENT_PCT:
                logger.debug(
                    "[CardioPR] suppress %s — only %.2f%% in <7d", kind, improvement
                )
                return

            candidates.append(CardioPrCandidate(
                user_id=user_id,
                sport=sport,
                kind=kind,
                record_value=round(value, 4),
                record_unit=unit,
                previous_value=round(prior_value, 4),
                improvement_percent=improvement or None,
                is_first_time=False,
                achieved_at=achieved_at,
                workout_log_id=str(row.get("id")) if row.get("id") else None,
                celebration_message=_celebration(kind, value, sport, False),
            ))

        # --- per-kind detection --------------------------------------------
        if is_first_time:
            # First-ever session of this sport. Emit ONLY the two
            # foundational kinds with the first-time flag — suppress all
            # other kinds (otherwise every value would trivially be a PR).
            if distance_m > 0:
                candidates.append(CardioPrCandidate(
                    user_id=user_id,
                    sport=sport,
                    kind="longest_distance",
                    record_value=round(distance_m, 2),
                    record_unit="m",
                    previous_value=None,
                    improvement_percent=None,
                    is_first_time=True,
                    achieved_at=achieved_at,
                    workout_log_id=str(row.get("id")) if row.get("id") else None,
                    celebration_message=_celebration("longest_distance", distance_m, sport, True),
                ))
            if duration_s > 0:
                candidates.append(CardioPrCandidate(
                    user_id=user_id,
                    sport=sport,
                    kind="longest_duration_session",
                    record_value=round(duration_s, 0),
                    record_unit="sec",
                    previous_value=None,
                    improvement_percent=None,
                    is_first_time=True,
                    achieved_at=achieved_at,
                    workout_log_id=str(row.get("id")) if row.get("id") else None,
                    celebration_message=_celebration("longest_duration_session", duration_s, sport, True),
                ))
            return candidates

        # Regular detection path.
        if distance_m > 0:
            _maybe_emit("longest_distance", distance_m, "m")
        if duration_s > 0:
            _maybe_emit("longest_duration_session", duration_s, "sec")

        # fastest_mile / 5K / 10K — only when we have per-split data
        # (or, eventually, decoded gps points). Without that, we cannot
        # compute a true rolling-window pace, so we skip silently.
        if splits_json or gps_polyline:
            mile_best = _rolling_best_time_for_distance(splits_json, gps_polyline, MILE_M)
            if mile_best:
                _maybe_emit("fastest_mile", mile_best, "sec")
            fivek_best = _rolling_best_time_for_distance(splits_json, gps_polyline, FIVE_K_M)
            if fivek_best:
                _maybe_emit("fastest_5k", fivek_best, "sec")
            tenk_best = _rolling_best_time_for_distance(splits_json, gps_polyline, TEN_K_M)
            if tenk_best:
                _maybe_emit("fastest_10k", tenk_best, "sec")

        # best_avg_speed — cycling-only metric (running uses pace, swimming
        # uses split times, walking is too low-variance to be meaningful).
        if sport == "cycling" and avg_speed_mps is not None and float(avg_speed_mps) > 0:
            kmh = float(avg_speed_mps) * 3.6
            _maybe_emit("best_avg_speed", round(kmh, 2), "kmh")

        # biggest_weekly_distance_km — sum the rolling 7-day window ending at
        # this session and compare against the historic best week.
        weekly_km = self._rolling_7d_distance_km(db, user_id, sport, achieved_at)
        if weekly_km > 0:
            _maybe_emit("biggest_weekly_distance_km", round(weekly_km, 2), "km")

        return candidates

    def persist_prs(
        self,
        db: Any,
        user_id: str,
        candidates: List[CardioPrCandidate],
    ) -> List[str]:
        """Insert PR rows into `personal_records`. Idempotent — re-inserting
        the same (user_id, sport, kind, achieved_at) is a no-op via the
        same-row pre-check.
        """
        if not candidates:
            return []

        new_ids: List[str] = []
        for c in candidates:
            payload = {
                "user_id": c.user_id,
                "exercise_name": f"{c.sport.title()} ({c.kind})",
                "record_type": c.kind,
                "record_value": c.record_value,
                "record_unit": c.record_unit,
                "previous_value": c.previous_value,
                "improvement_percent": c.improvement_percent,
                "achieved_at": c.achieved_at.isoformat(),
                "sport": c.sport,
                "is_first_time_activity": c.is_first_time,
                "celebration_message": c.celebration_message,
                # Strength PR cols intentionally left NULL for cardio rows.
            }

            # Idempotency guard: same user+sport+kind+achieved_at = skip.
            try:
                existing = db.client.table("personal_records").select("id").eq(
                    "user_id", c.user_id
                ).eq("sport", c.sport).eq(
                    "record_type", c.kind
                ).eq("achieved_at", c.achieved_at.isoformat()).limit(1).execute()
                if existing.data:
                    continue
            except Exception as e:  # pragma: no cover — DB lookup is best-effort
                logger.warning("[CardioPR] idempotency check failed: %s", e)

            try:
                resp = db.client.table("personal_records").insert(payload).execute()
                if resp.data:
                    new_ids.append(str(resp.data[0]["id"]))
            except Exception as e:  # pragma: no cover
                logger.error("[CardioPR] insert failed for %s/%s: %s", c.sport, c.kind, e)
        return new_ids

    def list_cardio_prs_for_user(self, db: Any, user_id: str) -> List[Dict[str, Any]]:
        """Group current cardio PRs by (sport, kind). Returns one row per
        group with the most recent record + a small sparkline series.
        """
        try:
            resp = db.client.table("personal_records").select("*").eq(
                "user_id", user_id
            ).not_.is_("sport", "null").order(
                "achieved_at", desc=True
            ).execute()
        except Exception as e:  # pragma: no cover
            logger.error("[CardioPR] list failed: %s", e)
            return []

        rows = resp.data or []
        grouped: Dict[Tuple[str, str], List[Dict[str, Any]]] = {}
        for r in rows:
            sport = r.get("sport")
            kind = r.get("record_type")
            if not sport or not kind:
                continue
            grouped.setdefault((sport, kind), []).append(r)

        out: List[Dict[str, Any]] = []
        for (sport, kind), items in grouped.items():
            items_sorted = sorted(items, key=lambda x: _parse_dt(x.get("achieved_at")))
            current = items_sorted[-1]
            sparkline = [
                {
                    "achieved_at": _parse_dt(it.get("achieved_at")).isoformat(),
                    "record_value": float(it.get("record_value") or 0),
                }
                for it in items_sorted[-10:]
            ]
            out.append({
                "sport": sport,
                "kind": kind,
                "record_value": float(current.get("record_value") or 0),
                "record_unit": current.get("record_unit"),
                "previous_value": float(current["previous_value"])
                    if current.get("previous_value") is not None else None,
                "improvement_percent": current.get("improvement_percent"),
                "is_first_time_activity": bool(current.get("is_first_time_activity")),
                "achieved_at": _parse_dt(current.get("achieved_at")).isoformat(),
                "celebration_message": current.get("celebration_message"),
                "sparkline": sparkline,
            })
        return out

    def history_for_kind(
        self,
        db: Any,
        user_id: str,
        kind: str,
        *,
        sport: Optional[str] = None,
        limit: int = 30,
    ) -> List[Dict[str, Any]]:
        """Time-series of attempts for a single (kind[, sport]) — sparkline source."""
        try:
            q = db.client.table("personal_records").select("*").eq(
                "user_id", user_id
            ).eq("record_type", kind)
            if sport:
                q = q.eq("sport", sport)
            resp = q.order("achieved_at", desc=False).limit(limit).execute()
        except Exception as e:  # pragma: no cover
            logger.error("[CardioPR] history failed: %s", e)
            return []
        return [
            {
                "achieved_at": _parse_dt(r.get("achieved_at")).isoformat(),
                "record_value": float(r.get("record_value") or 0),
                "record_unit": r.get("record_unit"),
                "sport": r.get("sport"),
                "kind": r.get("record_type"),
                "is_first_time_activity": bool(r.get("is_first_time_activity")),
            }
            for r in (resp.data or [])
        ]

    # ----- internals -------------------------------------------------------

    def _load_cardio_log(self, db: Any, cardio_log_id: str) -> Optional[Dict[str, Any]]:
        try:
            resp = db.client.table("cardio_logs").select("*").eq(
                "id", cardio_log_id
            ).limit(1).execute()
        except Exception as e:  # pragma: no cover
            logger.error("[CardioPR] load cardio_log failed: %s", e)
            return None
        rows = resp.data or []
        return rows[0] if rows else None

    def _load_existing_prs(
        self, db: Any, user_id: str, sport: str
    ) -> List[Dict[str, Any]]:
        try:
            resp = db.client.table("personal_records").select("*").eq(
                "user_id", user_id
            ).eq("sport", sport).execute()
        except Exception as e:  # pragma: no cover
            logger.warning("[CardioPR] load existing failed: %s", e)
            return []
        return resp.data or []

    @staticmethod
    def _best_existing(
        existing: List[Dict[str, Any]], kind: str
    ) -> Optional[Dict[str, Any]]:
        """Return the best prior row for `kind` (lowest if pace-like, highest else)."""
        rows = [r for r in existing if r.get("record_type") == kind and r.get("record_value") is not None]
        if not rows:
            return None
        if _is_lower_better(kind):
            return min(rows, key=lambda r: float(r["record_value"]))
        return max(rows, key=lambda r: float(r["record_value"]))

    def _rolling_7d_distance_km(
        self, db: Any, user_id: str, sport: str, end_dt: datetime
    ) -> float:
        """Sum distance_m over the 7d window ending at end_dt (inclusive),
        across all activity_types that map to this sport. Returns km.
        """
        start_dt = end_dt - timedelta(days=7)
        # Resolve activity_types belonging to this sport.
        activity_types = [
            a for a, s in ACTIVITY_TYPE_TO_SPORT.items() if s == sport
        ]
        if not activity_types:
            return 0.0
        try:
            resp = db.client.table("cardio_logs").select(
                "distance_m,performed_at,activity_type"
            ).eq("user_id", user_id).in_(
                "activity_type", activity_types
            ).gte("performed_at", start_dt.isoformat()).lte(
                "performed_at", end_dt.isoformat()
            ).execute()
        except Exception as e:  # pragma: no cover
            logger.warning("[CardioPR] rolling weekly query failed: %s", e)
            return 0.0
        total_m = sum(float(r.get("distance_m") or 0) for r in (resp.data or []))
        return total_m / 1000.0


# Module-level singleton — mirrors `personal_records_service`.
cardio_pr_service = CardioPrService()
