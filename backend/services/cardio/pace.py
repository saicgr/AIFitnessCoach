"""Pace formatting for cardio sessions.

Single chokepoint for turning (duration, distance) into a "MM:SS" per-km pace.

Why this exists: the three call sites that used to compute pace inline
(create session, update session, per-type stats) all did

    pace_minutes = duration_minutes / distance_km
    pace_mins = int(pace_minutes)
    pace_secs = int((pace_minutes - pace_mins) * 60)

which loses a second whenever the fractional part of `pace_minutes` is not
exactly representable in binary floating point. 60 minutes over 25 km is
exactly 2:24/km, but `2.4 - 2 == 0.3999999999999999`, so `int(... * 60)`
truncated to 23 and the session was stored as 2:23/km. Same for 30min/12.5km,
and any pace whose seconds land on a non-representable fraction.

Computing the whole thing in seconds and rounding once removes the error.
"""

from typing import Optional


def format_pace_per_km(duration_minutes: Optional[float], distance_km: Optional[float]) -> Optional[str]:
    """Return the per-km pace as "M:SS", or None when it is undefined.

    Undefined = missing/zero distance or missing duration (a 0 km session has
    no pace; dividing would raise or produce inf).
    """
    if duration_minutes is None or distance_km is None:
        return None

    duration = float(duration_minutes)
    distance = float(distance_km)
    if distance <= 0:
        return None

    total_seconds = int(round((duration / distance) * 60))
    return f"{total_seconds // 60}:{total_seconds % 60:02d}"
