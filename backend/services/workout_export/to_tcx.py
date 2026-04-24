"""
Emit TCX (Training Center XML) for cardio sessions.

TCX is Garmin's format and the lowest-common-denominator across Garmin
Connect, Strava, TrainingPeaks, Golden Cheetah, etc. One `<Activity>` per
cardio row, each with at least one `<Lap>` child carrying duration,
distance, avg/max HR, calories.

Namespaces the TCX spec requires:
  - http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2
  - http://www.garmin.com/xmlschemas/ActivityExtension/v2 (for cadence/watts)

Activity type mapping (TCX's Sport enum is Running / Biking / Other):
  - run, trail_run, treadmill, walk, hike → Running
  - cycle, indoor_cycle, mountain_bike, gravel_bike → Biking
  - everything else → Other
"""
from __future__ import annotations

from datetime import datetime, timezone
from typing import List
from uuid import UUID

from lxml import etree

from services.workout_import.canonical import CanonicalCardioRow


TCX_NS = "http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2"
ACT_EXT_NS = "http://www.garmin.com/xmlschemas/ActivityExtension/v2"
XSI_NS = "http://www.w3.org/2001/XMLSchema-instance"
SCHEMA_LOCATION = (
    "http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2 "
    "http://www.garmin.com/xmlschemas/TrainingCenterDatabasev2.xsd"
)

_SPORT_MAP = {
    "run": "Running",
    "trail_run": "Running",
    "treadmill": "Running",
    "walk": "Running",
    "hike": "Running",
    "cycle": "Biking",
    "indoor_cycle": "Biking",
    "mountain_bike": "Biking",
    "gravel_bike": "Biking",
}


def _sport_for(activity_type: str) -> str:
    return _SPORT_MAP.get(activity_type, "Other")


def _iso_z(dt: datetime) -> str:
    """TCX wants ISO-8601 UTC Zulu. Always convert to UTC first."""
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.000Z")


def _E(tag: str, text=None, **attrs):
    """Helper to build a namespaced element concisely."""
    el = etree.SubElement if False else etree.Element  # keep type-checkers quiet
    e = etree.Element(f"{{{TCX_NS}}}{tag}", nsmap={None: TCX_NS})
    if text is not None:
        e.text = str(text)
    for k, v in attrs.items():
        e.set(k, str(v))
    return e


def _lap_for(row: CanonicalCardioRow) -> etree._Element:
    lap = etree.Element(f"{{{TCX_NS}}}Lap", StartTime=_iso_z(row.performed_at))

    total_time = etree.SubElement(lap, f"{{{TCX_NS}}}TotalTimeSeconds")
    total_time.text = f"{row.duration_seconds}"

    distance = etree.SubElement(lap, f"{{{TCX_NS}}}DistanceMeters")
    distance.text = f"{(row.distance_m or 0):.2f}"

    # TCX requires MaximumSpeed — derive from average if max isn't stored.
    max_speed = etree.SubElement(lap, f"{{{TCX_NS}}}MaximumSpeed")
    max_speed.text = f"{(row.avg_speed_mps or 0):.3f}"

    calories = etree.SubElement(lap, f"{{{TCX_NS}}}Calories")
    calories.text = f"{row.calories or 0}"

    if row.avg_heart_rate is not None:
        avg_hr = etree.SubElement(lap, f"{{{TCX_NS}}}AverageHeartRateBpm")
        avg_hr_value = etree.SubElement(avg_hr, f"{{{TCX_NS}}}Value")
        avg_hr_value.text = str(row.avg_heart_rate)

    if row.max_heart_rate is not None:
        max_hr = etree.SubElement(lap, f"{{{TCX_NS}}}MaximumHeartRateBpm")
        max_hr_value = etree.SubElement(max_hr, f"{{{TCX_NS}}}Value")
        max_hr_value.text = str(row.max_heart_rate)

    # Required by the schema even if we don't track it.
    intensity = etree.SubElement(lap, f"{{{TCX_NS}}}Intensity")
    intensity.text = "Active"
    trigger = etree.SubElement(lap, f"{{{TCX_NS}}}TriggerMethod")
    trigger.text = "Manual"

    # Extensions for cadence / watts so high-fidelity importers pick them up.
    if row.avg_cadence is not None or row.avg_watts is not None:
        ext = etree.SubElement(lap, f"{{{TCX_NS}}}Extensions")
        lx = etree.SubElement(ext, f"{{{ACT_EXT_NS}}}LX")
        if row.avg_cadence is not None:
            avg_cad = etree.SubElement(lx, f"{{{ACT_EXT_NS}}}AvgRunCadence")
            avg_cad.text = str(row.avg_cadence)
        if row.avg_watts is not None:
            avg_w = etree.SubElement(lx, f"{{{ACT_EXT_NS}}}AvgWatts")
            avg_w.text = str(row.avg_watts)
    return lap


def export_tcx(cardio_rows: List[CanonicalCardioRow]) -> bytes:
    """Build a TCX XML byte blob with every passed cardio row as an Activity."""
    root = etree.Element(
        f"{{{TCX_NS}}}TrainingCenterDatabase",
        nsmap={
            None: TCX_NS,
            "ext": ACT_EXT_NS,
            "xsi": XSI_NS,
        },
    )
    root.set(f"{{{XSI_NS}}}schemaLocation", SCHEMA_LOCATION)

    activities = etree.SubElement(root, f"{{{TCX_NS}}}Activities")
    for row in cardio_rows:
        act = etree.SubElement(
            activities, f"{{{TCX_NS}}}Activity",
            Sport=_sport_for(row.activity_type),
        )
        # <Id> must be a TCX-formatted datetime per the schema.
        act_id = etree.SubElement(act, f"{{{TCX_NS}}}Id")
        act_id.text = _iso_z(row.performed_at)
        act.append(_lap_for(row))

        if row.notes:
            notes = etree.SubElement(act, f"{{{TCX_NS}}}Notes")
            notes.text = row.notes

    return etree.tostring(root, pretty_print=True, xml_declaration=True, encoding="UTF-8")
