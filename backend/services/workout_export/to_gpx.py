"""
Emit GPX for cardio rows that carry an encoded polyline.

GPX is the gold-standard for route data (Strava, MapMyRun, Runkeeper, Garmin
Connect all export / import it). We only emit rows with a `gps_polyline`;
strength sessions and cardio rows without GPS data are skipped with a
top-level comment noting the count so consumers know they weren't dropped
silently.

Implementation:
  - `polyline` library decodes Google's encoded-polyline format → list of
    (lat, lng) tuples at 1e-5 precision.
  - Each activity becomes one <trk> (track) with one <trkseg> (segment)
    holding every waypoint. We don't have per-waypoint timestamps stored
    (only the start time), so we linearly interpolate timestamps across the
    duration — good enough for heatmap / map overlays.
"""
from __future__ import annotations

import logging
from datetime import datetime, timedelta, timezone
from typing import List

import polyline as _polyline  # type: ignore[import-untyped]
from lxml import etree

from core import branding
from services.workout_import.canonical import CanonicalCardioRow

logger = logging.getLogger(__name__)

GPX_NS = "http://www.topografix.com/GPX/1/1"
XSI_NS = "http://www.w3.org/2001/XMLSchema-instance"
SCHEMA_LOCATION = (
    "http://www.topografix.com/GPX/1/1 "
    "http://www.topografix.com/GPX/1/1/gpx.xsd"
)


def _iso_z(dt: datetime) -> str:
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _decode_polyline_safely(encoded: str):
    """Tolerate malformed polylines — corrupt GPS data shouldn't fail the export."""
    if not encoded:
        return []
    try:
        return _polyline.decode(encoded)
    except Exception as e:
        logger.debug(f"[WorkoutExport GPX] polyline decode failed: {e}")
        return []


def export_gpx(cardio_rows: List[CanonicalCardioRow]) -> bytes:
    root = etree.Element(
        f"{{{GPX_NS}}}gpx",
        nsmap={
            None: GPX_NS,
            "xsi": XSI_NS,
        },
        version="1.1",
        creator=f"{branding.APP_NAME} ({branding.WEBSITE_URL})",
    )
    root.set(f"{{{XSI_NS}}}schemaLocation", SCHEMA_LOCATION)

    metadata = etree.SubElement(root, f"{{{GPX_NS}}}metadata")
    time_el = etree.SubElement(metadata, f"{{{GPX_NS}}}time")
    time_el.text = _iso_z(datetime.utcnow().replace(tzinfo=timezone.utc))

    emitted = 0
    skipped = 0
    for row in cardio_rows:
        waypoints = _decode_polyline_safely(row.gps_polyline or "")
        if not waypoints:
            skipped += 1
            continue

        trk = etree.SubElement(root, f"{{{GPX_NS}}}trk")
        name = etree.SubElement(trk, f"{{{GPX_NS}}}name")
        name.text = f"{row.activity_type.replace('_', ' ').title()} — {_iso_z(row.performed_at)}"

        trktype = etree.SubElement(trk, f"{{{GPX_NS}}}type")
        trktype.text = row.activity_type

        seg = etree.SubElement(trk, f"{{{GPX_NS}}}trkseg")

        n_points = len(waypoints)
        # Linear time interpolation across the lap. Close enough for most
        # consumers; if we ever store per-waypoint timestamps, replace this.
        if n_points > 1 and row.duration_seconds:
            step = row.duration_seconds / (n_points - 1)
        else:
            step = 0

        for i, (lat, lng) in enumerate(waypoints):
            pt = etree.SubElement(
                seg, f"{{{GPX_NS}}}trkpt",
                lat=f"{lat:.6f}", lon=f"{lng:.6f}",
            )
            t = etree.SubElement(pt, f"{{{GPX_NS}}}time")
            t.text = _iso_z(row.performed_at + timedelta(seconds=step * i))
        emitted += 1

    # Footer comment so consumers know why some rows are missing. lxml
    # supports processing instructions but comments are more portable.
    if skipped:
        root.append(etree.Comment(f"skipped {skipped} cardio rows without gps_polyline"))

    logger.info(f"[WorkoutExport GPX] emitted={emitted} skipped={skipped}")
    return etree.tostring(root, pretty_print=True, xml_declaration=True, encoding="UTF-8")
