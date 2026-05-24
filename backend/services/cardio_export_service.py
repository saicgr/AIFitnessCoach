"""
Single-session cardio export — GPX 1.1 / TCX / FIT.

Distinct from `services.workout_export.to_gpx` / `to_tcx` (which emit
multi-row bulk exports keyed off CanonicalCardioRow for the GDPR-style
data-export pipeline). This module targets the *single-session share*
flow: user taps "Share" on one cardio detail screen, picks a format,
gets a file they can AirDrop / send to Strava / drop in Garmin Connect.

Inputs are the `cardio_logs` row dict (as Supabase returns it) + optional
sidecar series:
  - route_points: List[(lat, lng)] decoded from the S3 `route_polyline_s3_key`
    JSON blob (see `api/v1/cardio_route.py` — schema is `{"points":[[lat,lng],...]}`).
  - hr_samples: List[(elapsed_seconds, bpm)] — optional per-second-ish HR series.
  - splits: List[dict] — optional km/mi split rows (only used in TCX laps).

Each format returns:
  (bytes, filename, mime_type)

Indoor activities (no GPS):
  - GPX export raises ValueError("indoor_no_gps") — surface as 422 at the
    HTTP layer. GPX is fundamentally about position.
  - TCX and FIT still work — they're timer-driven.

FIT writing uses `fit_tool` (already in requirements). If the library
fails to assemble the file for any reason we re-raise so the endpoint
can return 501 — Garmin/Strava both accept GPX or TCX as fallback.
"""
from __future__ import annotations

import json
import logging
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional, Tuple

from lxml import etree

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Constants — namespaces, schema URIs, sport maps.
# ---------------------------------------------------------------------------

GPX_NS = "http://www.topografix.com/GPX/1/1"
GPX_XSI_NS = "http://www.w3.org/2001/XMLSchema-instance"
GPX_TPX_NS = "http://www.garmin.com/xmlschemas/TrackPointExtension/v1"
GPX_SCHEMA_LOCATION = (
    "http://www.topografix.com/GPX/1/1 "
    "http://www.topografix.com/GPX/1/1/gpx.xsd"
)

TCX_NS = "http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2"
TCX_ACT_EXT_NS = "http://www.garmin.com/xmlschemas/ActivityExtension/v2"
TCX_XSI_NS = "http://www.w3.org/2001/XMLSchema-instance"
TCX_SCHEMA_LOCATION = (
    "http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2 "
    "http://www.garmin.com/xmlschemas/TrainingCenterDatabasev2.xsd"
)

# Activity types that don't produce GPS data even in theory. Used to short
# circuit GPX with a clear error rather than emit an empty <trk>.
INDOOR_ACTIVITY_TYPES = frozenset({
    "treadmill", "indoor_cycle", "row", "erg", "elliptical",
    "stair", "stepmill", "ski_erg",
    "yoga", "pilates", "hiit", "boxing", "kickboxing",
})

# TCX Sport enum is only Running / Biking / Other.
_TCX_SPORT_MAP = {
    "run": "Running", "trail_run": "Running", "treadmill": "Running",
    "walk": "Running", "hike": "Running",
    "cycle": "Biking", "indoor_cycle": "Biking",
    "mountain_bike": "Biking", "gravel_bike": "Biking",
}

# Branding string used in the <creator> attribute of each file.
_CREATOR = "Zealova (https://zealova.com)"


# ---------------------------------------------------------------------------
# Public dataclass
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class CardioExport:
    """Return shape of every export_* function."""
    payload: bytes
    filename: str
    mime_type: str


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _parse_performed_at(row: Dict[str, Any]) -> datetime:
    """Always return a tz-aware UTC datetime — Supabase gives ISO strings."""
    raw = row.get("performed_at")
    if isinstance(raw, datetime):
        dt = raw
    elif isinstance(raw, str):
        # Supabase returns "...+00:00" or trailing "Z"; fromisoformat handles
        # the former from py3.11+ and the latter we patch.
        dt = datetime.fromisoformat(raw.replace("Z", "+00:00"))
    else:
        # Best-effort fallback; never silently use "now" — feedback_no_silent_fallbacks.
        raise ValueError(f"cardio_log missing performed_at (got {type(raw).__name__})")
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def _iso_z(dt: datetime) -> str:
    """Strict ISO-8601 UTC Zulu — required by both GPX and TCX schemas."""
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _iso_z_ms(dt: datetime) -> str:
    """TCX historically wants .000Z fractional seconds."""
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.000Z")


def _filename(activity_type: str, performed_at: datetime, ext: str) -> str:
    stamp = performed_at.strftime("%Y%m%d-%H%M%S")
    safe_activity = "".join(c if c.isalnum() else "_" for c in activity_type)
    return f"zealova-{safe_activity}-{stamp}.{ext}"


def _is_indoor(row: Dict[str, Any], route_points: Optional[List[Tuple[float, float]]]) -> bool:
    """A row is indoor if the activity type is in our indoor set OR there
    are zero route points. We treat zero-point outdoor rows as indoor for
    the purpose of GPX gating — emitting GPX with no waypoints is useless
    and most importers reject it.
    """
    if (row.get("activity_type") or "") in INDOOR_ACTIVITY_TYPES:
        return True
    return not route_points


def _hr_at_index(
    hr_samples: Optional[List[Tuple[float, int]]],
    i: int,
    n: int,
    duration_seconds: float,
) -> Optional[int]:
    """Find the HR sample closest in time to point index `i` of `n`.

    HR samples are a `(elapsed_seconds, bpm)` series, almost always sparser
    than the GPS series. We do an O(log) search if we sorted, but n+m here
    are tiny (a 1h run is ~3600 GPS pts and ~60 HR samples), so a linear
    pass per point is fine.
    """
    if not hr_samples or n <= 0 or duration_seconds <= 0:
        return None
    target_t = (i / max(n - 1, 1)) * duration_seconds
    best = min(hr_samples, key=lambda s: abs(s[0] - target_t))
    return int(best[1]) if best and best[1] is not None else None


# ---------------------------------------------------------------------------
# Polyline loader from S3 blob (call this from the endpoint, not the service)
# ---------------------------------------------------------------------------

def decode_route_blob(blob: bytes) -> List[Tuple[float, float]]:
    """Decode the JSON shape written by `api/v1/cardio_route.py`.

    Returns [] on any malformed shape — corrupt routes shouldn't fail the
    export entirely; TCX/FIT will still emit timer data.
    """
    if not blob:
        return []
    try:
        obj = json.loads(blob.decode("utf-8"))
    except Exception as e:
        logger.warning("[CardioExport] route blob json decode failed: %s", e)
        return []
    pts = obj.get("points") if isinstance(obj, dict) else None
    if not isinstance(pts, list):
        return []
    out: List[Tuple[float, float]] = []
    for p in pts:
        if isinstance(p, (list, tuple)) and len(p) == 2:
            try:
                lat, lng = float(p[0]), float(p[1])
            except (TypeError, ValueError):
                continue
            if -90.0 <= lat <= 90.0 and -180.0 <= lng <= 180.0:
                out.append((lat, lng))
    return out


# ---------------------------------------------------------------------------
# GPX
# ---------------------------------------------------------------------------

def export_gpx(
    row: Dict[str, Any],
    route_points: Optional[List[Tuple[float, float]]] = None,
    hr_samples: Optional[List[Tuple[float, int]]] = None,
) -> CardioExport:
    """Emit a GPX 1.1 file for a single cardio session.

    Raises:
        ValueError("indoor_no_gps") — when the row has no usable route data.
            Endpoint should map this to HTTP 422 with a helpful message.
    """
    if _is_indoor(row, route_points):
        raise ValueError("indoor_no_gps")

    performed_at = _parse_performed_at(row)
    activity_type = row.get("activity_type") or "other"
    duration_seconds = float(row.get("duration_seconds") or 0)

    nsmap = {None: GPX_NS, "xsi": GPX_XSI_NS, "gpxtpx": GPX_TPX_NS}
    root = etree.Element(
        f"{{{GPX_NS}}}gpx",
        nsmap=nsmap,
        version="1.1",
        creator=_CREATOR,
    )
    root.set(f"{{{GPX_XSI_NS}}}schemaLocation", GPX_SCHEMA_LOCATION)

    metadata = etree.SubElement(root, f"{{{GPX_NS}}}metadata")
    meta_time = etree.SubElement(metadata, f"{{{GPX_NS}}}time")
    meta_time.text = _iso_z(performed_at)

    trk = etree.SubElement(root, f"{{{GPX_NS}}}trk")
    name = etree.SubElement(trk, f"{{{GPX_NS}}}name")
    name.text = f"{activity_type.replace('_', ' ').title()} {_iso_z(performed_at)}"
    trk_type = etree.SubElement(trk, f"{{{GPX_NS}}}type")
    trk_type.text = activity_type

    seg = etree.SubElement(trk, f"{{{GPX_NS}}}trkseg")

    # Linear time interpolation across the session — we don't store per-point
    # timestamps yet (see api/v1/cardio_route.py, which only stores [lat,lng]).
    pts = route_points or []
    n = len(pts)
    step = (duration_seconds / (n - 1)) if (n > 1 and duration_seconds > 0) else 0.0

    for i, (lat, lng) in enumerate(pts):
        pt = etree.SubElement(
            seg, f"{{{GPX_NS}}}trkpt",
            lat=f"{lat:.6f}", lon=f"{lng:.6f}",
        )
        t = etree.SubElement(pt, f"{{{GPX_NS}}}time")
        t.text = _iso_z(performed_at + timedelta(seconds=step * i))
        # Per-point HR via the Garmin TrackPointExtension namespace — Strava
        # and Garmin Connect both consume this for HR overlays on the map.
        bpm = _hr_at_index(hr_samples, i, n, duration_seconds)
        if bpm is not None:
            ext = etree.SubElement(pt, f"{{{GPX_NS}}}extensions")
            tpe = etree.SubElement(ext, f"{{{GPX_TPX_NS}}}TrackPointExtension")
            hr_el = etree.SubElement(tpe, f"{{{GPX_TPX_NS}}}hr")
            hr_el.text = str(bpm)

    payload = etree.tostring(
        root, pretty_print=True, xml_declaration=True, encoding="UTF-8",
    )
    return CardioExport(
        payload=payload,
        filename=_filename(activity_type, performed_at, "gpx"),
        mime_type="application/gpx+xml",
    )


# ---------------------------------------------------------------------------
# TCX
# ---------------------------------------------------------------------------

def export_tcx(
    row: Dict[str, Any],
    route_points: Optional[List[Tuple[float, float]]] = None,
    hr_samples: Optional[List[Tuple[float, int]]] = None,
    splits: Optional[List[Dict[str, Any]]] = None,
) -> CardioExport:
    """Emit a single-Activity TCX file. Works for indoor + outdoor."""
    performed_at = _parse_performed_at(row)
    activity_type = row.get("activity_type") or "other"
    duration_seconds = float(row.get("duration_seconds") or 0)
    distance_m = float(row.get("distance_m") or 0)
    calories = int(row.get("calories") or 0)
    avg_hr = row.get("avg_heart_rate")
    max_hr = row.get("max_heart_rate")
    avg_speed = row.get("avg_speed_mps") or 0
    avg_cadence = row.get("avg_cadence")
    avg_watts = row.get("avg_watts")
    notes = row.get("notes")

    nsmap = {None: TCX_NS, "ext": TCX_ACT_EXT_NS, "xsi": TCX_XSI_NS}
    root = etree.Element(f"{{{TCX_NS}}}TrainingCenterDatabase", nsmap=nsmap)
    root.set(f"{{{TCX_XSI_NS}}}schemaLocation", TCX_SCHEMA_LOCATION)

    activities = etree.SubElement(root, f"{{{TCX_NS}}}Activities")
    act = etree.SubElement(
        activities, f"{{{TCX_NS}}}Activity",
        Sport=_TCX_SPORT_MAP.get(activity_type, "Other"),
    )
    act_id = etree.SubElement(act, f"{{{TCX_NS}}}Id")
    act_id.text = _iso_z_ms(performed_at)

    lap = etree.SubElement(act, f"{{{TCX_NS}}}Lap", StartTime=_iso_z_ms(performed_at))

    _sub_text(lap, "TotalTimeSeconds", f"{duration_seconds:.0f}")
    _sub_text(lap, "DistanceMeters", f"{distance_m:.2f}")
    # MaximumSpeed is schema-required — fall back to avg when max is absent.
    _sub_text(lap, "MaximumSpeed", f"{float(avg_speed):.3f}")
    _sub_text(lap, "Calories", str(calories))

    if avg_hr is not None:
        _hr_bucket(lap, "AverageHeartRateBpm", int(avg_hr))
    if max_hr is not None:
        _hr_bucket(lap, "MaximumHeartRateBpm", int(max_hr))

    _sub_text(lap, "Intensity", "Active")
    _sub_text(lap, "TriggerMethod", "Manual")

    # Track points: emit one per route point with HR overlay if available.
    pts = route_points or []
    n = len(pts)
    if n > 0:
        track = etree.SubElement(lap, f"{{{TCX_NS}}}Track")
        step = (duration_seconds / (n - 1)) if (n > 1 and duration_seconds > 0) else 0.0
        for i, (lat, lng) in enumerate(pts):
            tp = etree.SubElement(track, f"{{{TCX_NS}}}Trackpoint")
            _sub_text(tp, "Time", _iso_z_ms(performed_at + timedelta(seconds=step * i)))
            pos = etree.SubElement(tp, f"{{{TCX_NS}}}Position")
            _sub_text(pos, "LatitudeDegrees", f"{lat:.6f}")
            _sub_text(pos, "LongitudeDegrees", f"{lng:.6f}")
            bpm = _hr_at_index(hr_samples, i, n, duration_seconds)
            if bpm is not None:
                _hr_bucket(tp, "HeartRateBpm", bpm)
    elif hr_samples:
        # Indoor row with HR but no GPS: emit a Track of Time+HR only so
        # importers still pick up the bpm trace for HR-zone analytics.
        track = etree.SubElement(lap, f"{{{TCX_NS}}}Track")
        for elapsed, bpm in hr_samples:
            tp = etree.SubElement(track, f"{{{TCX_NS}}}Trackpoint")
            _sub_text(tp, "Time", _iso_z_ms(performed_at + timedelta(seconds=float(elapsed))))
            _hr_bucket(tp, "HeartRateBpm", int(bpm))

    # Lap-level cadence/watts extensions.
    if avg_cadence is not None or avg_watts is not None:
        ext = etree.SubElement(lap, f"{{{TCX_NS}}}Extensions")
        lx = etree.SubElement(ext, f"{{{TCX_ACT_EXT_NS}}}LX")
        if avg_cadence is not None:
            _sub_text_ns(lx, TCX_ACT_EXT_NS, "AvgRunCadence", str(int(avg_cadence)))
        if avg_watts is not None:
            _sub_text_ns(lx, TCX_ACT_EXT_NS, "AvgWatts", str(int(avg_watts)))

    # Split laps — informational. The first Lap above is the whole session;
    # if `splits` is populated we additionally emit one Lap per split for
    # importers that key off them (Strava). Splits are dicts with at minimum
    # `duration_seconds` and `distance_m`.
    if splits:
        cursor = performed_at
        for sp in splits:
            sp_dur = float(sp.get("duration_seconds") or 0)
            sp_dist = float(sp.get("distance_m") or 0)
            if sp_dur <= 0:
                continue
            sp_lap = etree.SubElement(act, f"{{{TCX_NS}}}Lap", StartTime=_iso_z_ms(cursor))
            _sub_text(sp_lap, "TotalTimeSeconds", f"{sp_dur:.0f}")
            _sub_text(sp_lap, "DistanceMeters", f"{sp_dist:.2f}")
            _sub_text(sp_lap, "MaximumSpeed", "0.000")
            _sub_text(sp_lap, "Calories", "0")
            _sub_text(sp_lap, "Intensity", "Active")
            _sub_text(sp_lap, "TriggerMethod", "Distance")
            cursor = cursor + timedelta(seconds=sp_dur)

    if notes:
        _sub_text(act, "Notes", str(notes))

    payload = etree.tostring(
        root, pretty_print=True, xml_declaration=True, encoding="UTF-8",
    )
    return CardioExport(
        payload=payload,
        filename=_filename(activity_type, performed_at, "tcx"),
        mime_type="application/vnd.garmin.tcx+xml",
    )


def _sub_text(parent, tag: str, text: str) -> None:
    el = etree.SubElement(parent, f"{{{TCX_NS}}}{tag}")
    el.text = text


def _sub_text_ns(parent, ns: str, tag: str, text: str) -> None:
    el = etree.SubElement(parent, f"{{{ns}}}{tag}")
    el.text = text


def _hr_bucket(parent, tag: str, bpm: int) -> None:
    """Wrap a bpm value in TCX's required <HeartRateBpm><Value>N</Value> shape."""
    el = etree.SubElement(parent, f"{{{TCX_NS}}}{tag}")
    val = etree.SubElement(el, f"{{{TCX_NS}}}Value")
    val.text = str(int(bpm))


# ---------------------------------------------------------------------------
# FIT (binary)
# ---------------------------------------------------------------------------

# FIT sport / sub-sport mapping. The Sport enum in fit_tool follows the
# Garmin FIT SDK. Any activity not mapped falls back to GENERIC + GENERIC.
_FIT_SPORT_MAP: Dict[str, Tuple[str, str]] = {
    "run": ("running", "generic"),
    "trail_run": ("running", "trail"),
    "treadmill": ("running", "treadmill"),
    "walk": ("walking", "generic"),
    "hike": ("hiking", "generic"),
    "cycle": ("cycling", "road"),
    "indoor_cycle": ("cycling", "indoor_cycling"),
    "mountain_bike": ("cycling", "mountain"),
    "gravel_bike": ("cycling", "gravel_cycling"),
    "row": ("rowing", "indoor_rowing"),
    "erg": ("rowing", "indoor_rowing"),
    "swim": ("swimming", "open_water"),
    "open_water_swim": ("swimming", "open_water"),
    "elliptical": ("fitness_equipment", "elliptical"),
    "stair": ("fitness_equipment", "stair_climbing"),
    "stepmill": ("fitness_equipment", "stair_climbing"),
    "yoga": ("training", "yoga"),
    "pilates": ("training", "pilates"),
    "hiit": ("training", "cardio_training"),
    "boxing": ("boxing", "generic"),
    "kickboxing": ("boxing", "generic"),
}


def export_fit(
    row: Dict[str, Any],
    route_points: Optional[List[Tuple[float, float]]] = None,
    hr_samples: Optional[List[Tuple[float, int]]] = None,
) -> CardioExport:
    """Emit a binary .FIT file via fit_tool.

    On any failure during assembly we re-raise — the endpoint maps this
    to HTTP 501 so the client can fall back to GPX/TCX (which Garmin
    Connect, Strava, TrainingPeaks all accept).
    """
    # Local imports — fit_tool imports a lot of profile data and we don't
    # want to slow down module import for the GPX/TCX paths.
    try:
        from fit_tool.fit_file_builder import FitFileBuilder
        from fit_tool.profile.messages.file_id_message import FileIdMessage
        from fit_tool.profile.messages.activity_message import ActivityMessage
        from fit_tool.profile.messages.session_message import SessionMessage
        from fit_tool.profile.messages.record_message import RecordMessage
        from fit_tool.profile.messages.event_message import EventMessage
        from fit_tool.profile.profile_type import (
            FileType, Manufacturer, Sport, SubSport,
            Event, EventType,
        )
    except Exception as e:  # pragma: no cover — only if dep is broken
        logger.exception("[CardioExport] fit_tool import failed: %s", e)
        raise

    performed_at = _parse_performed_at(row)
    activity_type = row.get("activity_type") or "other"
    duration_seconds = float(row.get("duration_seconds") or 0)
    distance_m = float(row.get("distance_m") or 0)
    calories = int(row.get("calories") or 0)
    avg_hr = row.get("avg_heart_rate")
    max_hr = row.get("max_heart_rate")
    avg_speed = float(row.get("avg_speed_mps") or 0)

    sport_name, subsport_name = _FIT_SPORT_MAP.get(activity_type, ("generic", "generic"))

    # FIT timestamps are seconds-since-FIT-epoch but fit_tool accepts python
    # millisecond epochs and converts internally.
    start_ms = int(performed_at.timestamp() * 1000)
    end_ms = int((performed_at + timedelta(seconds=duration_seconds)).timestamp() * 1000)

    builder = FitFileBuilder(auto_define=True, min_string_size=50)

    # 1) File ID — required first message in every FIT file.
    file_id = FileIdMessage()
    file_id.type = FileType.ACTIVITY
    file_id.manufacturer = Manufacturer.DEVELOPMENT.value
    file_id.product = 0
    file_id.time_created = start_ms
    file_id.serial_number = 0x12345678
    builder.add(file_id)

    # 2) Start event.
    start_event = EventMessage()
    start_event.timestamp = start_ms
    start_event.event = Event.TIMER
    start_event.event_type = EventType.START
    builder.add(start_event)

    # 3) Per-point records. GPS positions are encoded as semicircles
    # (degrees * 2^31 / 180); fit_tool's `position_lat`/`position_long`
    # setters accept degrees directly, which is the friendlier API.
    pts = route_points or []
    n = len(pts)
    step = (duration_seconds / (n - 1)) if (n > 1 and duration_seconds > 0) else 0.0

    def _emit_record(i: int, lat: Optional[float], lng: Optional[float]) -> None:
        rec = RecordMessage()
        rec.timestamp = start_ms + int(step * i * 1000)
        if lat is not None and lng is not None:
            rec.position_lat = lat
            rec.position_long = lng
        bpm = _hr_at_index(hr_samples, i, max(n, 1), duration_seconds)
        if bpm is not None:
            rec.heart_rate = bpm
        if avg_speed > 0:
            rec.speed = avg_speed
        builder.add(rec)

    if n > 0:
        for i, (lat, lng) in enumerate(pts):
            _emit_record(i, lat, lng)
    elif hr_samples:
        # Indoor session — emit position-less records to carry HR trace.
        for elapsed, bpm in hr_samples:
            rec = RecordMessage()
            rec.timestamp = start_ms + int(float(elapsed) * 1000)
            rec.heart_rate = int(bpm)
            builder.add(rec)
    else:
        # No streams at all — at least emit start + end records so the
        # session is a valid 2-record activity.
        _emit_record(0, None, None)
        _emit_record(1, None, None) if duration_seconds > 0 else None  # noqa: B015

    # 4) Stop event.
    stop_event = EventMessage()
    stop_event.timestamp = end_ms
    stop_event.event = Event.TIMER
    stop_event.event_type = EventType.STOP_ALL
    builder.add(stop_event)

    # 5) Session summary.
    session = SessionMessage()
    session.timestamp = end_ms
    session.start_time = start_ms
    session.total_elapsed_time = duration_seconds
    session.total_timer_time = duration_seconds
    session.total_distance = distance_m
    session.total_calories = calories
    try:
        session.sport = getattr(Sport, sport_name.upper())
    except AttributeError:
        session.sport = Sport.GENERIC
    try:
        session.sub_sport = getattr(SubSport, subsport_name.upper())
    except AttributeError:
        session.sub_sport = SubSport.GENERIC
    if avg_hr is not None:
        session.avg_heart_rate = int(avg_hr)
    if max_hr is not None:
        session.max_heart_rate = int(max_hr)
    if avg_speed > 0:
        session.avg_speed = avg_speed
    session.first_lap_index = 0
    session.num_laps = 1
    builder.add(session)

    # 6) Activity summary — required tail message.
    activity = ActivityMessage()
    activity.timestamp = end_ms
    activity.total_timer_time = duration_seconds
    activity.num_sessions = 1
    builder.add(activity)

    fit_file = builder.build()
    payload = fit_file.to_bytes()

    return CardioExport(
        payload=bytes(payload),
        filename=_filename(activity_type, performed_at, "fit"),
        mime_type="application/vnd.ant.fit",
    )


# ---------------------------------------------------------------------------
# Format dispatcher
# ---------------------------------------------------------------------------

SUPPORTED_FORMATS = ("gpx", "tcx", "fit")


def export(
    fmt: str,
    row: Dict[str, Any],
    route_points: Optional[List[Tuple[float, float]]] = None,
    hr_samples: Optional[List[Tuple[float, int]]] = None,
    splits: Optional[List[Dict[str, Any]]] = None,
) -> CardioExport:
    """Format-name dispatcher. Raises ValueError("unsupported_format") on
    unknown `fmt`; endpoint maps that to HTTP 415.
    """
    f = (fmt or "").lower().strip()
    if f == "gpx":
        return export_gpx(row, route_points=route_points, hr_samples=hr_samples)
    if f == "tcx":
        return export_tcx(row, route_points=route_points, hr_samples=hr_samples, splits=splits)
    if f == "fit":
        return export_fit(row, route_points=route_points, hr_samples=hr_samples)
    raise ValueError("unsupported_format")
