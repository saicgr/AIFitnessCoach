"""
Garmin FIT adapter.

.FIT is Garmin's native binary format. The `fitparse` library handles
the header / record layout / endianness, so this file focuses on the
semantic mapping: FIT messages → CanonicalCardioRow (or CanonicalSetRow
for strength sessions).

Key implementation notes (edge cases from the plan):

#39 FIT epoch offset — FIT timestamps are seconds since 1989-12-31
    00:00 UTC. `fitparse` returns these as Python datetimes already
    offset correctly, but without tz info. We force UTC via
    ensure_tz_aware().

Strength sessions: Garmin records "Strength Training" and
    "Weightlifting" as activity types with `set` messages per rep/weight.
    Those should land in workout_history_imports, not cardio_logs. The
    adapter detects the session's sport and routes accordingly.

Cadence: FIT uses "cycles" as a generic unit — strokes/min for rowing,
    steps/min for running, revolutions/min for cycling. We preserve the
    raw integer and let the UI apply unit labels.

Lap splits: emitted via splits_json when ≥ 2 laps are present; a single
    lap is uninteresting (it just duplicates the session totals).
"""
from __future__ import annotations

from datetime import datetime, timezone
from typing import Any, Optional
from uuid import UUID

from ..canonical import (
    CanonicalCardioRow,
    CanonicalSetRow,
    ImportMode,
    ParseResult,
    SetType,
    WeightUnit,
    convert_to_kg,
)
from ._cardio_common import (
    STRENGTH_ACTIVITY_KEYWORDS,
    derive_pace_and_speed,
    ensure_tz_aware,
    normalize_activity_type,
)


def _is_strength_sport(sport: Optional[str], sub_sport: Optional[str]) -> bool:
    """FIT tags strength sessions with sport='training' and one of many
    sub_sport variants (strength_training, cardio_training, etc.). We treat
    the sub_sport as authoritative when present."""
    joined = " ".join(filter(None, [str(sport or "").lower(), str(sub_sport or "").lower()]))
    return any(kw in joined for kw in STRENGTH_ACTIVITY_KEYWORDS)


def _extract_session_fields(session_values: dict[str, Any]) -> dict[str, Any]:
    """Pull out the session-level summary that maps to cardio_logs columns.
    `fitparse` returns `get_values()` as a dict; values are already in SI
    units for things like distance (meters) and duration (seconds)."""
    return {
        "sport": session_values.get("sport"),
        "sub_sport": session_values.get("sub_sport"),
        "start_time": session_values.get("start_time"),
        "total_elapsed_time": session_values.get("total_elapsed_time"),
        "total_timer_time": session_values.get("total_timer_time"),
        "total_distance": session_values.get("total_distance"),
        "total_ascent": session_values.get("total_ascent"),
        "avg_heart_rate": session_values.get("avg_heart_rate"),
        "max_heart_rate": session_values.get("max_heart_rate"),
        "avg_cadence": session_values.get("avg_cadence"),
        "avg_power": session_values.get("avg_power"),
        "max_power": session_values.get("max_power"),
        "total_calories": session_values.get("total_calories"),
        "training_effect": session_values.get("total_training_effect"),
        "weight_display_unit": session_values.get("weight_display_unit"),
    }


def _build_cardio_row(
    session: dict[str, Any],
    user_id: UUID,
    laps: list[dict[str, Any]],
    external_id: Optional[str],
) -> Optional[CanonicalCardioRow]:
    sport = session.get("sport")
    sub_sport = session.get("sub_sport")
    # sub_sport is more specific (trail, treadmill, indoor_cycling, etc.) —
    # prefer it when it's *not* the generic placeholder. FIT uses 'generic'
    # as a pseudo-null sub_sport value; in that case fall back to sport.
    if sub_sport and str(sub_sport).lower() != "generic":
        raw_type = sub_sport
    else:
        raw_type = sport or "other"
    activity_type = normalize_activity_type(raw_type) or "other"

    start_time = session.get("start_time")
    if not isinstance(start_time, datetime):
        return None
    start_time = ensure_tz_aware(start_time, "UTC")

    # total_elapsed_time includes pauses; total_timer_time excludes them.
    # Strava and Garmin Connect both display elapsed, so we do too — users
    # expect the run they "went for" to match the watch's displayed duration.
    duration_raw = session.get("total_elapsed_time") or session.get("total_timer_time") or 0
    duration_seconds = int(round(float(duration_raw))) if duration_raw else 0
    if duration_seconds <= 0:
        return None

    distance_m = session.get("total_distance")
    distance_m = float(distance_m) if distance_m is not None else None
    avg_pace, avg_speed = derive_pace_and_speed(duration_seconds, distance_m)

    splits: Optional[list[dict[str, Any]]] = None
    if len(laps) >= 2:
        splits = []
        for i, lap in enumerate(laps, start=1):
            lap_seconds = lap.get("total_elapsed_time") or lap.get("total_timer_time") or 0
            lap_distance = lap.get("total_distance")
            split_entry: dict[str, Any] = {"lap": i, "lap_seconds": int(round(float(lap_seconds or 0)))}
            if lap_distance is not None:
                split_entry["lap_distance_m"] = round(float(lap_distance), 2)
                if float(lap_distance) >= 100:
                    split_entry["pace_seconds_per_km"] = round(float(lap_seconds) / (float(lap_distance) / 1000), 2)
            if lap.get("avg_heart_rate") is not None:
                split_entry["avg_hr"] = int(lap["avg_heart_rate"])
            splits.append(split_entry)

    row_hash = CanonicalCardioRow.compute_row_hash(
        user_id=user_id,
        source_app="garmin",
        performed_at=start_time,
        activity_type=activity_type,
        duration_seconds=duration_seconds,
        distance_m=distance_m,
    )

    return CanonicalCardioRow(
        user_id=user_id,
        performed_at=start_time,
        activity_type=activity_type,
        duration_seconds=duration_seconds,
        distance_m=round(distance_m, 2) if distance_m else None,
        elevation_gain_m=float(session["total_ascent"]) if session.get("total_ascent") is not None else None,
        avg_heart_rate=int(session["avg_heart_rate"]) if session.get("avg_heart_rate") is not None else None,
        max_heart_rate=int(session["max_heart_rate"]) if session.get("max_heart_rate") is not None else None,
        avg_cadence=int(session["avg_cadence"]) if session.get("avg_cadence") is not None else None,
        avg_watts=int(session["avg_power"]) if session.get("avg_power") is not None else None,
        max_watts=int(session["max_power"]) if session.get("max_power") is not None else None,
        avg_pace_seconds_per_km=avg_pace,
        avg_speed_mps=avg_speed,
        training_effect=float(session["training_effect"]) if session.get("training_effect") is not None else None,
        calories=int(session["total_calories"]) if session.get("total_calories") is not None else None,
        splits_json=splits,
        source_app="garmin",
        source_external_id=external_id,
        source_row_hash=row_hash,
    )


def _build_strength_rows(
    *,
    session: dict[str, Any],
    set_messages: list[dict[str, Any]],
    user_id: UUID,
) -> list[CanonicalSetRow]:
    """Map FIT `set` messages (one per logged set) to CanonicalSetRow.

    FIT strength sessions encode exercise as a two-field enum
    (category + name index). We fall back to a human-readable name when
    fitparse has resolved the enum, otherwise keep the raw category.
    """
    rows: list[CanonicalSetRow] = []
    session_start = session.get("start_time")
    if not isinstance(session_start, datetime):
        session_start = datetime.now(tz=timezone.utc)
    session_start = ensure_tz_aware(session_start, "UTC")

    # Garmin's weight_display_unit is a session-level attribute honored for
    # every set in the session. Default to kg — most Garmin users in the EU
    # leave it at kg, and US users tend to explicitly set it.
    weight_unit_raw = session.get("weight_display_unit") or "kg"
    weight_unit = WeightUnit.LB if str(weight_unit_raw).lower().startswith("lb") else WeightUnit.KG

    for i, msg in enumerate(set_messages, start=1):
        set_type_raw = (msg.get("set_type") or "active").lower()
        if "rest" in set_type_raw:
            # FIT emits "rest" messages interleaved; those aren't logged sets.
            continue
        reps = msg.get("repetitions")
        if reps is None:
            continue
        weight = msg.get("weight")
        weight_kg = convert_to_kg(float(weight), weight_unit) if weight is not None else None
        performed_at = msg.get("timestamp") or msg.get("start_time") or session_start
        if not isinstance(performed_at, datetime):
            performed_at = session_start
        performed_at = ensure_tz_aware(performed_at, "UTC")
        exercise_name = (
            msg.get("exercise_name")
            or msg.get("exercise_category")
            or "Unknown Strength Exercise"
        )

        set_type = SetType.WORKING
        if "warm" in set_type_raw:
            set_type = SetType.WARMUP

        row_hash = CanonicalSetRow.compute_row_hash(
            user_id=user_id,
            source_app="garmin",
            performed_at=performed_at,
            exercise_name_canonical=str(exercise_name).lower(),
            set_number=i,
            weight_kg=weight_kg,
            reps=int(reps),
        )
        rows.append(CanonicalSetRow(
            user_id=user_id,
            performed_at=performed_at,
            exercise_name_raw=str(exercise_name),
            exercise_name_canonical=str(exercise_name).lower(),
            set_number=i,
            set_type=set_type,
            weight_kg=weight_kg,
            original_weight_value=float(weight) if weight is not None else None,
            original_weight_unit=weight_unit,
            reps=int(reps),
            source_app="garmin",
            source_row_hash=row_hash,
        ))
    return rows


async def parse(
    *,
    data: bytes,
    filename: str,
    user_id: UUID,
    unit_hint: str,
    tz_hint: str,
    mode_hint: ImportMode,
) -> ParseResult:
    from fitparse import FitFile

    warnings: list[str] = []
    try:
        fit = FitFile(data)
        fit.parse()
    except Exception as e:
        return ParseResult(
            mode=ImportMode.CARDIO_ONLY,
            source_app="garmin",
            warnings=[f"FIT parse error: {e}"],
        )

    # Garmin FIT writers emit `set` and `lap` messages BEFORE the closing
    # `session` that summarizes them (see fit-tool / Garmin watches in the
    # wild). So we buffer everything and assign to sessions after parsing
    # by timestamp proximity: each set/lap joins the first session whose
    # [start_time, start_time + total_elapsed_time] contains it.
    sessions: list[dict[str, Any]] = []
    all_laps: list[dict[str, Any]] = []
    all_sets: list[dict[str, Any]] = []
    file_id_external: Optional[str] = None

    for message in fit.get_messages():
        name = message.name
        values = message.get_values()
        if name == "file_id":
            created = values.get("time_created")
            serial = values.get("serial_number")
            if created and serial:
                file_id_external = f"{int(serial)}-{int(created.timestamp())}"
        elif name == "session":
            sessions.append(_extract_session_fields(values))
        elif name == "lap":
            all_laps.append(values)
        elif name == "set":
            all_sets.append(values)

    # Bucket laps/sets to sessions by the session's time window. When there's
    # exactly one session (the common case), everything trivially lands there.
    laps_by_session_idx: list[list[dict[str, Any]]] = [[] for _ in sessions]
    set_messages_by_session_idx: list[list[dict[str, Any]]] = [[] for _ in sessions]

    def _session_window(s: dict[str, Any]):
        start = s.get("start_time")
        if not isinstance(start, datetime):
            return None, None
        duration = s.get("total_elapsed_time") or s.get("total_timer_time") or 0
        try:
            end = start.replace() + (duration and __import__("datetime").timedelta(seconds=float(duration)))
        except Exception:
            return start, None
        return start, end

    for bucket, items in (("lap", all_laps), ("set", all_sets)):
        for item in items:
            ts = item.get("timestamp") or item.get("start_time")
            assigned = False
            if isinstance(ts, datetime):
                for i, s in enumerate(sessions):
                    start, end = _session_window(s)
                    if start is None:
                        continue
                    # Inclusive-ish window; allow a 5-minute lead so
                    # set-timestamps that precede the session start by a
                    # second (fitparse rounding) still land in-scope.
                    if end is None or (start <= ts <= end) or abs((ts - start).total_seconds()) <= 300:
                        (laps_by_session_idx if bucket == "lap" else set_messages_by_session_idx)[i].append(item)
                        assigned = True
                        break
            if not assigned and sessions:
                # Fall back to the single session (or the last one) — a FIT
                # file with one session and sets-before-session lands here.
                (laps_by_session_idx if bucket == "lap" else set_messages_by_session_idx)[-1].append(item)

    if not sessions:
        return ParseResult(
            mode=ImportMode.CARDIO_ONLY,
            source_app="garmin",
            warnings=["FIT file contained no session records"],
        )

    cardio_rows: list[CanonicalCardioRow] = []
    strength_rows: list[CanonicalSetRow] = []

    for idx, session in enumerate(sessions):
        if _is_strength_sport(session.get("sport"), session.get("sub_sport")):
            # Strength session → emit CanonicalSetRow, skip cardio row.
            strength = _build_strength_rows(
                session=session,
                set_messages=set_messages_by_session_idx[idx],
                user_id=user_id,
            )
            if not strength:
                warnings.append(
                    f"FIT strength session at {session.get('start_time')} had no usable `set` messages"
                )
            strength_rows.extend(strength)
        else:
            row = _build_cardio_row(
                session=session,
                user_id=user_id,
                laps=laps_by_session_idx[idx],
                external_id=file_id_external,
            )
            if row is not None:
                cardio_rows.append(row)
            else:
                warnings.append(
                    f"Could not derive cardio row for FIT session sport={session.get('sport')}"
                )

    # A FIT file may carry pure-strength data, pure-cardio, or both; the
    # ImportMode should reflect what we actually produced.
    if strength_rows and not cardio_rows:
        mode = ImportMode.HISTORY
    elif cardio_rows and strength_rows:
        mode = ImportMode.HISTORY  # mixed — the detector/UI preview will surface both
    else:
        mode = ImportMode.CARDIO_ONLY

    return ParseResult(
        mode=mode,
        source_app="garmin",
        strength_rows=strength_rows,
        cardio_rows=cardio_rows,
        warnings=warnings,
    )
