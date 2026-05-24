"""
Cardio Auto-Tag Service
-----------------------

Computes a set of derived, user-visible "vibe" tags for a cardio session
(`is_hill_workout`, `is_negative_split`, `is_new_route`, `is_dawn_run`,
`is_dusk_run`, `is_pr_session`) and persists them to
`cardio_logs.tags text[]` or `cardio_sessions.tags text[]` (migration 2094).

Design notes
~~~~~~~~~~~~
* **Stateless, pure-function `compute_tags(...)`** so it can be unit-tested
  without a DB. The caller passes the cardio row dict + a slice of the user's
  recent logs.
* **Table auto-detection** — migration 2094 added the `tags` column to both
  `cardio_logs` and `cardio_sessions`. The newer code path uses
  `cardio_logs`; older synced sessions land in `cardio_sessions`. The
  `update_tags` writer tries the modern table first and falls back to the
  legacy one so a single endpoint covers both.
* **`is_new_route` simplification** — full Hausdorff polyline matching is
  heavy (every polyline pair → O(n*m) distance scan). For v1 we approximate:
  *new route = no recent log shares the same first GPS coord (≤100m haversine)
   AND ends within 100m AND has distance within ±5%.*
  This catches the obvious "ran a brand-new loop" case while staying cheap.
  Upgrade path: precompute a polyline hash bucket on insert.
* **No silent fallback** (per CLAUDE.md `feedback_no_silent_fallbacks.md`):
  malformed `splits_json` returns `False` for the negative-split flag rather
  than swallowing the row, and DB-write failures surface up to the caller.
* **PR flag is set by the integrator** — `is_pr_session` is exposed in the
  tag vocabulary so SLICE_CARDIO_PR's later wiring can OR-merge into the
  same column without a schema change.
"""
from __future__ import annotations

import json
import math
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Tuple

try:
    from zoneinfo import ZoneInfo
except ImportError:  # pragma: no cover - python <3.9 fallback (not expected)
    ZoneInfo = None  # type: ignore

from core.logger import get_logger

logger = get_logger(__name__)


# ---------------------------------------------------------------------------
# Tag vocabulary
# ---------------------------------------------------------------------------
TAG_HILL = "is_hill_workout"
TAG_NEGATIVE_SPLIT = "is_negative_split"
TAG_NEW_ROUTE = "is_new_route"
TAG_DAWN = "is_dawn_run"
TAG_DUSK = "is_dusk_run"
TAG_PR = "is_pr_session"

ALL_TAGS = {
    TAG_HILL, TAG_NEGATIVE_SPLIT, TAG_NEW_ROUTE,
    TAG_DAWN, TAG_DUSK, TAG_PR,
}

# Boundaries — exposed as constants so tests can assert them and product can
# tune them without code-spelunking.
HILL_MIN_ELEVATION_M = 100.0
HILL_MAX_DISTANCE_M = 10000.0
NEGATIVE_SPLIT_THRESHOLD = 0.02  # 2nd half must be ≥2% FASTER (lower pace)

# Dawn/dusk windows in user-local hour (inclusive of lower, exclusive of upper)
DAWN_HOUR_RANGE: Tuple[int, int] = (4, 8)   # 04:00–07:59
DUSK_HOUR_RANGE: Tuple[int, int] = (19, 23)  # 19:00–22:59

NEW_ROUTE_ENDPOINT_RADIUS_M = 100.0
NEW_ROUTE_DISTANCE_TOLERANCE = 0.05  # ±5%


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def _haversine_m(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Great-circle distance between two lat/lon points in meters."""
    r = 6371000.0
    p1 = math.radians(lat1)
    p2 = math.radians(lat2)
    dp = math.radians(lat2 - lat1)
    dl = math.radians(lon2 - lon1)
    a = (math.sin(dp / 2) ** 2 +
         math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2)
    return 2 * r * math.asin(math.sqrt(a))


def _decode_polyline(polyline: str) -> List[Tuple[float, float]]:
    """Decode a Google-encoded polyline (used by Strava / Mapbox / Apple).
    Returns [(lat, lon), ...]. Falls back to empty list on garbage input."""
    if not polyline or not isinstance(polyline, str):
        return []
    try:
        coords: List[Tuple[float, float]] = []
        index = 0
        lat = 0
        lng = 0
        length = len(polyline)
        while index < length:
            for target in ("lat", "lng"):
                result = 1
                shift = 0
                while True:
                    if index >= length:
                        return coords  # malformed mid-token — best-effort return
                    b = ord(polyline[index]) - 63 - 1
                    index += 1
                    result += b << shift
                    shift += 5
                    if b < 0x1f:
                        break
                delta = (~(result >> 1)) if (result & 1) else (result >> 1)
                if target == "lat":
                    lat += delta
                else:
                    lng += delta
            coords.append((lat * 1e-5, lng * 1e-5))
        return coords
    except Exception as e:  # pragma: no cover - defensive
        logger.debug(f"[CardioAutoTag] polyline decode failed: {e}")
        return []


def _polyline_endpoints(raw: Any) -> Optional[Tuple[Tuple[float, float], Tuple[float, float]]]:
    """Extract (first_point, last_point) lat/lon pair from a polyline-ish field.
    Accepts:
      * Google-encoded polyline string
      * JSON list of [lat, lon] pairs
      * dict {"points": "<encoded>"}
    Returns None if we can't get at least 2 coords.
    """
    if raw is None:
        return None
    coords: List[Tuple[float, float]] = []
    if isinstance(raw, str):
        # First try JSON list, then fall back to encoded polyline.
        try:
            parsed = json.loads(raw)
            if isinstance(parsed, list) and parsed:
                for p in parsed:
                    if isinstance(p, (list, tuple)) and len(p) >= 2:
                        coords.append((float(p[0]), float(p[1])))
        except (ValueError, TypeError):
            coords = _decode_polyline(raw)
    elif isinstance(raw, list):
        for p in raw:
            if isinstance(p, (list, tuple)) and len(p) >= 2:
                coords.append((float(p[0]), float(p[1])))
    elif isinstance(raw, dict):
        pts = raw.get("points") or raw.get("polyline")
        if isinstance(pts, str):
            coords = _decode_polyline(pts)
    if len(coords) < 2:
        return None
    return coords[0], coords[-1]


def _local_hour(performed_at: Any, tz_name: Optional[str]) -> Optional[int]:
    """Convert a performed_at timestamp to the user's local hour (0–23)."""
    if performed_at is None:
        return None
    if isinstance(performed_at, str):
        try:
            dt = datetime.fromisoformat(performed_at.replace("Z", "+00:00"))
        except ValueError:
            return None
    elif isinstance(performed_at, datetime):
        dt = performed_at
    else:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    if tz_name and ZoneInfo is not None:
        try:
            dt = dt.astimezone(ZoneInfo(tz_name))
        except Exception:
            dt = dt.astimezone(timezone.utc)
    else:
        dt = dt.astimezone(timezone.utc)
    return dt.hour


# ---------------------------------------------------------------------------
# Individual rule checks (kept small + pure for testability)
# ---------------------------------------------------------------------------
def _is_hill_workout(row: Dict[str, Any]) -> bool:
    elev = row.get("elevation_gain_m")
    dist = row.get("distance_m")
    if elev is None or dist is None:
        return False
    try:
        elev_f = float(elev)
        dist_f = float(dist)
    except (TypeError, ValueError):
        return False
    return elev_f >= HILL_MIN_ELEVATION_M and dist_f <= HILL_MAX_DISTANCE_M


def _is_negative_split(row: Dict[str, Any]) -> bool:
    """A negative split = 2nd half avg pace is at least 2% FASTER (lower
    seconds/km) than the 1st half. Returns False on missing/malformed data."""
    splits = row.get("splits_json")
    if splits is None:
        return False
    if isinstance(splits, str):
        try:
            splits = json.loads(splits)
        except (ValueError, TypeError):
            return False
    if not isinstance(splits, list) or len(splits) < 2:
        return False

    paces: List[float] = []
    for s in splits:
        if not isinstance(s, dict):
            continue
        pace = (s.get("avg_pace_seconds_per_km")
                or s.get("pace_seconds_per_km")
                or s.get("pace"))
        if pace is None:
            # Try to derive from split duration + distance.
            dur = s.get("duration_seconds") or s.get("elapsed_seconds")
            dist = s.get("distance_m")
            if dur and dist and dist > 0:
                pace = (float(dur) / float(dist)) * 1000.0
        if pace is None:
            continue
        try:
            paces.append(float(pace))
        except (TypeError, ValueError):
            continue

    if len(paces) < 2:
        return False
    mid = len(paces) // 2
    first_half = paces[:mid]
    second_half = paces[mid:]
    if not first_half or not second_half:
        return False
    avg1 = sum(first_half) / len(first_half)
    avg2 = sum(second_half) / len(second_half)
    if avg1 <= 0:
        return False
    improvement = (avg1 - avg2) / avg1
    return improvement >= NEGATIVE_SPLIT_THRESHOLD


def _is_new_route(row: Dict[str, Any], recent_logs: List[Dict[str, Any]]) -> bool:
    """SIMPLIFIED Hausdorff: a route is "new" if no recent log shares both
    endpoints (start and end coords within 100m) AND has a similar total
    distance (±5%). Documented simplification in the module docstring."""
    raw_polyline = row.get("gps_polyline") or row.get("route_polyline_s3_key")
    if not raw_polyline:
        return False
    endpoints = _polyline_endpoints(raw_polyline)
    if endpoints is None:
        # Polyline present but unparseable — be conservative: don't tag as new.
        return False
    start, end = endpoints
    this_distance = row.get("distance_m")

    for prior in recent_logs:
        prior_raw = prior.get("gps_polyline") or prior.get("route_polyline_s3_key")
        if not prior_raw:
            continue
        prior_ep = _polyline_endpoints(prior_raw)
        if prior_ep is None:
            continue
        prior_start, prior_end = prior_ep
        d_start = _haversine_m(start[0], start[1], prior_start[0], prior_start[1])
        d_end = _haversine_m(end[0], end[1], prior_end[0], prior_end[1])
        if d_start > NEW_ROUTE_ENDPOINT_RADIUS_M or d_end > NEW_ROUTE_ENDPOINT_RADIUS_M:
            continue
        # Endpoints match — check distance similarity if available.
        if this_distance and prior.get("distance_m"):
            try:
                delta = abs(float(this_distance) - float(prior["distance_m"])) / float(this_distance)
                if delta <= NEW_ROUTE_DISTANCE_TOLERANCE:
                    return False  # matches a known route
            except (TypeError, ValueError, ZeroDivisionError):
                return False
        else:
            return False  # endpoints match and no distance to disprove
    return True


def _is_dawn(row: Dict[str, Any], tz_name: Optional[str]) -> bool:
    h = _local_hour(row.get("performed_at"), tz_name)
    if h is None:
        return False
    return DAWN_HOUR_RANGE[0] <= h < DAWN_HOUR_RANGE[1]


def _is_dusk(row: Dict[str, Any], tz_name: Optional[str]) -> bool:
    h = _local_hour(row.get("performed_at"), tz_name)
    if h is None:
        return False
    return DUSK_HOUR_RANGE[0] <= h < DUSK_HOUR_RANGE[1]


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------
def compute_tags(
    db: Any,
    cardio_log_dict: Dict[str, Any],
    recent_logs: List[Dict[str, Any]],
    user_timezone: Optional[str] = None,
) -> List[str]:
    """Compute the list of vibe tags for a single cardio log.

    Parameters
    ----------
    db : Supabase client wrapper (may be None for pure-function tests).
    cardio_log_dict : the cardio row being tagged.
    recent_logs : the user's recent cardio rows (last 30) — used for
        new-route detection.
    user_timezone : IANA tz string (e.g. "America/Chicago"). If None we
        try to read it from `cardio_log_dict["user_timezone"]` then default
        to UTC.

    Returns the subset of `ALL_TAGS` whose flag is True. Stable order.
    """
    tz = user_timezone or cardio_log_dict.get("user_timezone")
    tags: List[str] = []
    if _is_hill_workout(cardio_log_dict):
        tags.append(TAG_HILL)
    if _is_negative_split(cardio_log_dict):
        tags.append(TAG_NEGATIVE_SPLIT)
    if _is_new_route(cardio_log_dict, recent_logs or []):
        tags.append(TAG_NEW_ROUTE)
    if _is_dawn(cardio_log_dict, tz):
        tags.append(TAG_DAWN)
    if _is_dusk(cardio_log_dict, tz):
        tags.append(TAG_DUSK)
    # is_pr_session — the PR slice flips this on after detection. Preserve
    # an existing PR tag if the caller passed one in.
    existing = cardio_log_dict.get("tags") or []
    if isinstance(existing, list) and TAG_PR in existing:
        tags.append(TAG_PR)
    return tags


# ---------------------------------------------------------------------------
# Persistence — auto-detect cardio_logs vs cardio_sessions
# ---------------------------------------------------------------------------
def _fetch_log_and_table(db: Any, cardio_log_id: str) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    """Return (row, table_name) for whichever of cardio_logs / cardio_sessions
    contains this id. Returns (None, None) if neither has it."""
    for table in ("cardio_logs", "cardio_sessions"):
        try:
            res = (
                db.client.table(table)
                .select("*")
                .eq("id", cardio_log_id)
                .limit(1)
                .execute()
            )
            if res.data:
                return res.data[0], table
        except Exception as e:
            logger.debug(f"[CardioAutoTag] probe {table} failed: {e}")
            continue
    return None, None


def _fetch_recent_logs(db: Any, table: str, user_id: str, exclude_id: str, limit: int = 30) -> List[Dict[str, Any]]:
    try:
        res = (
            db.client.table(table)
            .select("id, performed_at, distance_m, gps_polyline, route_polyline_s3_key")
            .eq("user_id", user_id)
            .neq("id", exclude_id)
            .order("performed_at", desc=True)
            .limit(limit)
            .execute()
        )
        return res.data or []
    except Exception as e:
        logger.warning(f"[CardioAutoTag] recent_logs fetch failed for {user_id}: {e}")
        return []


def _fetch_user_timezone(db: Any, user_id: str) -> Optional[str]:
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
    except Exception as e:
        logger.debug(f"[CardioAutoTag] timezone lookup failed: {e}")
    return None


def update_tags(db: Any, cardio_log_id: str) -> List[str]:
    """Compute tags for the given log id and persist them to the appropriate
    table's `tags` column. Returns the persisted tag list. Idempotent —
    running this twice in a row produces the same result and no row change."""
    row, table = _fetch_log_and_table(db, cardio_log_id)
    if not row or not table:
        raise ValueError(f"No cardio log/session found with id={cardio_log_id}")

    user_id = row.get("user_id")
    if not user_id:
        raise ValueError(f"Row {cardio_log_id} missing user_id")

    recent = _fetch_recent_logs(db, table, user_id, cardio_log_id)
    tz = _fetch_user_timezone(db, user_id)
    tags = compute_tags(db, row, recent, user_timezone=tz)

    try:
        (
            db.client.table(table)
            .update({"tags": tags})
            .eq("id", cardio_log_id)
            .execute()
        )
    except Exception as e:
        logger.error(f"[CardioAutoTag] persist failed for {cardio_log_id}: {e}", exc_info=True)
        raise
    logger.info(f"[CardioAutoTag] {table} id={cardio_log_id} tags={tags}")
    return tags
