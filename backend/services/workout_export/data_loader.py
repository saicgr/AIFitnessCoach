"""
Shared row-loader used by every `to_<format>.py` emitter.

Pulls a user's strength + cardio + template data from Supabase and reshapes
each row into the canonical pydantic model used by the import pipeline
(services.workout_import.canonical). Because the export uses the *same*
canonical shapes as the import, every format emitter operates on exactly
the structure its matching import adapter would produce — which is what
makes the round-trip test matrix tractable.

Data sources:
  - Strength:
      • `workout_history_imports` — rows previously imported from other apps
        (Hevy/Strong/etc). Each row is already one set.
      • `performance_logs` joined with `workout_logs` — sets completed inside
        Zealova. We join so we can attach the workout_name + start/end times
        a format like Hevy requires.
  - Cardio:
      • `cardio_logs` — the one and only home of cardio sessions in Zealova.
  - Templates:
      • `workout_program_templates` — creator programs imported as plans.

Edge cases handled here so the emitters don't each reinvent them:
  - performed_at may be stored as naive string, `...Z`, or `+00:00`. We
    normalize to timezone-aware UTC with `_parse_iso_utc()`. Naive rows get
    UTC attached — documented, matches behavior of the import pipeline which
    requires TZ-aware.
  - `weight_kg` may be null (bodyweight row) — preserved as None, not 0.
  - Exercise name fallback chain: `exercise_name_canonical` → `exercise_name`
    → "Unknown Exercise". Never crash on missing names.
  - Date-range filter: uses `performed_at` (strength) / `performed_at`
    (cardio) / `created_at` (templates) — tz-naive comparison intentional
    because the DB stores timestamptz and Supabase string-compares fine.
"""
from __future__ import annotations

import logging
from datetime import date, datetime, timezone
from typing import Any, Dict, List, Optional
from uuid import UUID

from services.workout_import.canonical import (
    CanonicalCardioRow,
    CanonicalProgramTemplate,
    CanonicalSetRow,
    PrescribedDay,
    PrescribedExercise,
    PrescribedSet,
    PrescribedWeek,
    RepTarget,
    LoadPrescription,
    LoadPrescriptionKind,
    SetType,
    WeightUnit,
)

logger = logging.getLogger(__name__)


# ─────────────────────────────── Helpers ──────────────────────────────── #


def _parse_iso_utc(raw: Any) -> Optional[datetime]:
    """Parse ISO-8601 → tz-aware UTC datetime.

    Accepts '2025-03-28T17:29:00Z', '...+00:00', or naive '...17:29:00'.
    Naive values get UTC attached (matches CanonicalRow field_validator
    requirement of tz-aware). None / empty / garbage → None.
    """
    if raw is None:
        return None
    if isinstance(raw, datetime):
        return raw if raw.tzinfo else raw.replace(tzinfo=timezone.utc)
    s = str(raw).strip()
    if not s:
        return None
    try:
        # fromisoformat in py3.11+ handles 'Z'; under 3.10 we swap manually.
        normalized = s.replace("Z", "+00:00") if s.endswith("Z") else s
        dt = datetime.fromisoformat(normalized)
        return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)
    except (ValueError, TypeError):
        # Last-ditch fallback: split at 'T' and try the date portion; better
        # than crashing the whole export for one malformed cell.
        try:
            return datetime.fromisoformat(s.split(".")[0]).replace(tzinfo=timezone.utc)
        except Exception:
            return None


def _as_uuid(raw: Any) -> Optional[UUID]:
    if raw is None or raw == "":
        return None
    try:
        return UUID(str(raw))
    except (ValueError, TypeError):
        return None


def _safe_float(v: Any) -> Optional[float]:
    if v is None or v == "":
        return None
    try:
        f = float(v)
        if f != f:  # NaN
            return None
        return f
    except (ValueError, TypeError):
        return None


def _safe_int(v: Any) -> Optional[int]:
    if v is None or v == "":
        return None
    try:
        f = float(v)
        if f != f:
            return None
        return int(round(f))
    except (ValueError, TypeError):
        return None


def _range_predicate_iso(from_date: Optional[date], to_date: Optional[date]) -> tuple[Optional[str], Optional[str]]:
    """Convert date→inclusive UTC ISO pair suitable for Supabase .gte/.lte."""
    from_iso = from_date.isoformat() + "T00:00:00Z" if from_date else None
    to_iso = to_date.isoformat() + "T23:59:59Z" if to_date else None
    return from_iso, to_iso


# ───────────────────────────── Strength loader ───────────────────────── #


def _row_hash(
    *, user_id: UUID, source_app: str, performed_at: datetime,
    exercise_name: str, set_number: Optional[int],
    weight_kg: Optional[float], reps: Optional[int],
) -> str:
    """Wrapper so emitters always use the canonical hash implementation."""
    return CanonicalSetRow.compute_row_hash(
        user_id=user_id,
        source_app=source_app,
        performed_at=performed_at,
        exercise_name_canonical=exercise_name,
        set_number=set_number,
        weight_kg=weight_kg,
        reps=reps,
    )


def _map_import_row_to_canonical(row: Dict[str, Any], user_id: UUID) -> Optional[CanonicalSetRow]:
    """Turn one `workout_history_imports` row → CanonicalSetRow.

    Returns None when the row can't be recovered (missing exercise name,
    unparsable date). We prefer dropping malformed rows to silently filling
    with defaults that would then export as misleading data.
    """
    performed_at = _parse_iso_utc(row.get("performed_at"))
    if performed_at is None:
        return None
    ex_name_raw = row.get("exercise_name") or row.get("exercise_name_canonical")
    if not ex_name_raw:
        return None
    ex_canonical = row.get("exercise_name_canonical") or ex_name_raw

    set_type_raw = row.get("set_type") or "working"
    try:
        set_type = SetType(set_type_raw)
    except ValueError:
        set_type = SetType.WORKING

    original_unit_raw = row.get("original_weight_unit")
    try:
        original_unit = WeightUnit(original_unit_raw) if original_unit_raw else None
    except ValueError:
        original_unit = None

    source_app = row.get("source_app") or row.get("source") or "fitwiz"
    set_number = _safe_int(row.get("set_number"))
    weight_kg = _safe_float(row.get("weight_kg"))
    reps = _safe_int(row.get("reps"))

    source_hash = row.get("source_row_hash") or _row_hash(
        user_id=user_id,
        source_app=source_app,
        performed_at=performed_at,
        exercise_name=ex_canonical,
        set_number=set_number,
        weight_kg=weight_kg,
        reps=reps,
    )

    return CanonicalSetRow(
        user_id=user_id,
        performed_at=performed_at,
        workout_name=row.get("workout_name"),
        exercise_name_raw=ex_name_raw,
        exercise_name_canonical=ex_canonical,
        exercise_id=_as_uuid(row.get("exercise_id")),
        set_number=set_number,
        set_type=set_type,
        weight_kg=weight_kg,
        original_weight_value=_safe_float(row.get("original_weight_value")),
        original_weight_unit=original_unit,
        reps=reps,
        duration_seconds=_safe_int(row.get("duration_seconds")),
        distance_m=_safe_float(row.get("distance_m")),
        rpe=_safe_float(row.get("rpe")),
        rir=_safe_int(row.get("rir")),
        superset_id=row.get("superset_id"),
        notes=row.get("notes"),
        source_app=source_app,
        source_row_hash=source_hash,
    )


def _map_perf_log_to_canonical(
    perf: Dict[str, Any],
    workout_log: Optional[Dict[str, Any]],
    user_id: UUID,
) -> Optional[CanonicalSetRow]:
    """performance_logs row (+ matching workout_log) → CanonicalSetRow.

    Uses `recorded_at` on the perf log as the performed_at (falls back to
    the workout_log's `completed_at` or `started_at` when the perf row's
    timestamp is missing — rare but seen in test data).
    """
    performed_at = (
        _parse_iso_utc(perf.get("recorded_at"))
        or _parse_iso_utc(workout_log.get("completed_at") if workout_log else None)
        or _parse_iso_utc(workout_log.get("started_at") if workout_log else None)
    )
    if performed_at is None:
        return None
    ex_name = perf.get("exercise_name")
    if not ex_name:
        return None

    weight_kg = _safe_float(perf.get("weight_kg"))
    reps = _safe_int(perf.get("reps_completed"))
    set_number = _safe_int(perf.get("set_number"))

    source_hash = _row_hash(
        user_id=user_id,
        source_app="fitwiz",
        performed_at=performed_at,
        exercise_name=ex_name,
        set_number=set_number,
        weight_kg=weight_kg,
        reps=reps,
    )

    return CanonicalSetRow(
        user_id=user_id,
        performed_at=performed_at,
        workout_name=(workout_log or {}).get("workout_name"),
        exercise_name_raw=ex_name,
        exercise_name_canonical=ex_name,
        set_number=set_number,
        set_type=SetType.WORKING,
        weight_kg=weight_kg,
        reps=reps,
        duration_seconds=_safe_int(perf.get("duration_seconds")),
        rpe=_safe_float(perf.get("rpe")),
        notes=perf.get("notes"),
        source_app="fitwiz",
        source_row_hash=source_hash,
    )


def load_strength(
    user_id: UUID,
    from_date: Optional[date] = None,
    to_date: Optional[date] = None,
    *,
    db=None,
) -> List[CanonicalSetRow]:
    """Return every strength set we have for the user, unified into canonical rows.

    Combines:
      1. Rows from `workout_history_imports` (previously-imported sessions).
      2. Rows from `performance_logs` joined with `workout_logs` (native Zealova).

    Deduplication is *not* applied here — that's the emitter's responsibility
    if it wants dedup. We deliberately return duplicates because a user who
    re-imported their Hevy history AND completed sessions natively may want
    both paths represented in the export.
    """
    if db is None:
        # Imported lazily so tests can inject a stub without booting Supabase.
        from core.db import get_supabase_db
        db = get_supabase_db()

    from_iso, to_iso = _range_predicate_iso(from_date, to_date)
    rows: List[CanonicalSetRow] = []

    # ─ workout_history_imports ────────────────────────────────────────────
    try:
        q = db.client.table("workout_history_imports").select("*").eq("user_id", str(user_id))
        if from_iso:
            q = q.gte("performed_at", from_iso)
        if to_iso:
            q = q.lte("performed_at", to_iso)
        import_result = q.order("performed_at", desc=False).execute()
        for r in import_result.data or []:
            row = _map_import_row_to_canonical(r, user_id)
            if row:
                rows.append(row)
    except Exception as e:
        logger.warning(f"[WorkoutExport] failed to load workout_history_imports: {e}")

    # ─ workout_logs + performance_logs ────────────────────────────────────
    try:
        wl_q = db.client.table("workout_logs").select("*").eq("user_id", str(user_id))
        if from_iso:
            wl_q = wl_q.gte("completed_at", from_iso)
        if to_iso:
            wl_q = wl_q.lte("completed_at", to_iso)
        workout_logs_result = wl_q.execute()
        workout_logs_by_id: Dict[str, Dict[str, Any]] = {
            str(w["id"]): w for w in (workout_logs_result.data or []) if w.get("id")
        }

        if workout_logs_by_id:
            perf_q = (
                db.client.table("performance_logs")
                .select("*")
                .eq("user_id", str(user_id))
                .in_("workout_log_id", list(workout_logs_by_id.keys()))
            )
            perf_result = perf_q.execute()
            for p in perf_result.data or []:
                wl = workout_logs_by_id.get(str(p.get("workout_log_id", "")))
                row = _map_perf_log_to_canonical(p, wl, user_id)
                if row:
                    rows.append(row)
    except Exception as e:
        logger.warning(f"[WorkoutExport] failed to load workout_logs/performance_logs: {e}")

    # Stable ordering so exports are deterministic across reruns.
    rows.sort(key=lambda r: (r.performed_at, r.workout_name or "", r.exercise_name_canonical or "", r.set_number or 0))
    logger.info(f"[WorkoutExport] load_strength user={user_id}: {len(rows)} rows")
    return rows


# ────────────────────────────── Cardio loader ────────────────────────── #


def _map_cardio_row(row: Dict[str, Any], user_id: UUID) -> Optional[CanonicalCardioRow]:
    performed_at = _parse_iso_utc(row.get("performed_at"))
    if performed_at is None:
        return None
    activity_type = row.get("activity_type") or "other"
    duration = _safe_int(row.get("duration_seconds"))
    if not duration or duration <= 0:
        # Cardio rows require positive duration; dropping malformed keeps
        # the file importable by downstream formats (TCX/GPX require it).
        return None
    source_app = row.get("source_app") or "fitwiz"
    source_hash = row.get("source_row_hash") or CanonicalCardioRow.compute_row_hash(
        user_id=user_id,
        source_app=source_app,
        performed_at=performed_at,
        activity_type=activity_type,
        duration_seconds=duration,
        distance_m=_safe_float(row.get("distance_m")),
    )

    return CanonicalCardioRow(
        user_id=user_id,
        performed_at=performed_at,
        activity_type=activity_type,
        duration_seconds=duration,
        distance_m=_safe_float(row.get("distance_m")),
        elevation_gain_m=_safe_float(row.get("elevation_gain_m")),
        avg_heart_rate=_safe_int(row.get("avg_heart_rate")),
        max_heart_rate=_safe_int(row.get("max_heart_rate")),
        avg_pace_seconds_per_km=_safe_float(row.get("avg_pace_seconds_per_km")),
        avg_speed_mps=_safe_float(row.get("avg_speed_mps")),
        avg_watts=_safe_int(row.get("avg_watts")),
        max_watts=_safe_int(row.get("max_watts")),
        avg_cadence=_safe_int(row.get("avg_cadence")),
        avg_stroke_rate=_safe_int(row.get("avg_stroke_rate")),
        training_effect=_safe_float(row.get("training_effect")),
        vo2max_estimate=_safe_float(row.get("vo2max_estimate")),
        calories=_safe_int(row.get("calories")),
        rpe=_safe_float(row.get("rpe")),
        notes=row.get("notes"),
        gps_polyline=row.get("gps_polyline"),
        splits_json=row.get("splits_json"),
        source_app=source_app,
        source_external_id=row.get("source_external_id"),
        source_row_hash=source_hash,
        sync_account_id=_as_uuid(row.get("sync_account_id")),
    )


def load_cardio(
    user_id: UUID,
    from_date: Optional[date] = None,
    to_date: Optional[date] = None,
    *,
    db=None,
) -> List[CanonicalCardioRow]:
    if db is None:
        from core.db import get_supabase_db
        db = get_supabase_db()

    from_iso, to_iso = _range_predicate_iso(from_date, to_date)
    rows: List[CanonicalCardioRow] = []
    try:
        q = db.client.table("cardio_logs").select("*").eq("user_id", str(user_id))
        if from_iso:
            q = q.gte("performed_at", from_iso)
        if to_iso:
            q = q.lte("performed_at", to_iso)
        result = q.order("performed_at", desc=False).execute()
        for r in result.data or []:
            row = _map_cardio_row(r, user_id)
            if row:
                rows.append(row)
    except Exception as e:
        logger.warning(f"[WorkoutExport] failed to load cardio_logs: {e}")

    rows.sort(key=lambda r: (r.performed_at, r.activity_type))
    logger.info(f"[WorkoutExport] load_cardio user={user_id}: {len(rows)} rows")
    return rows


# ────────────────────────────── Template loader ──────────────────────── #


def _rebuild_template(row: Dict[str, Any], user_id: UUID) -> Optional[CanonicalProgramTemplate]:
    """Convert a workout_program_templates DB row → CanonicalProgramTemplate.

    `raw_prescription` holds the weeks/days/exercises tree exactly as the
    importer stored it; we walk it back into pydantic models so JSON export
    and XLSX sheets round-trip. Falls back to an empty weeks list for rows
    that lack raw_prescription (very old templates) rather than crashing.
    """
    raw = row.get("raw_prescription") or {}
    if isinstance(raw, str):
        # Stored as jsonb-as-text in some environments.
        import json as _json
        try:
            raw = _json.loads(raw)
        except Exception:
            raw = {}

    weeks: List[PrescribedWeek] = []
    for wk in (raw.get("weeks") or []):
        try:
            days: List[PrescribedDay] = []
            for d in wk.get("days", []):
                exs: List[PrescribedExercise] = []
                for e in d.get("exercises", []):
                    sets: List[PrescribedSet] = []
                    for s in e.get("sets", []):
                        try:
                            rep_t = s.get("rep_target") or {"min": 0, "max": 0}
                            load_p = s.get("load_prescription") or {"kind": "unspecified"}
                            sets.append(PrescribedSet(
                                order=s.get("order", 0),
                                set_type=SetType(s.get("set_type") or "working"),
                                rep_target=RepTarget(**rep_t),
                                load_prescription=LoadPrescription(
                                    kind=LoadPrescriptionKind(load_p.get("kind") or "unspecified"),
                                    value_min=load_p.get("value_min"),
                                    value_max=load_p.get("value_max"),
                                    resolved_kg_min=load_p.get("resolved_kg_min"),
                                    resolved_kg_max=load_p.get("resolved_kg_max"),
                                    reference_1rm_exercise=load_p.get("reference_1rm_exercise"),
                                ),
                                rest_seconds_min=s.get("rest_seconds_min"),
                                rest_seconds_max=s.get("rest_seconds_max"),
                                tempo=s.get("tempo"),
                                notes=s.get("notes"),
                            ))
                        except Exception as err:
                            logger.debug(f"[WorkoutExport] skipping malformed set in template: {err}")
                    exs.append(PrescribedExercise(
                        order=e.get("order", 0),
                        exercise_name_raw=e.get("exercise_name_raw") or "Unknown Exercise",
                        exercise_name_canonical=e.get("exercise_name_canonical"),
                        exercise_id=_as_uuid(e.get("exercise_id")),
                        superset_id=e.get("superset_id"),
                        warmup_set_count=e.get("warmup_set_count", 0),
                        sets=sets,
                    ))
                days.append(PrescribedDay(
                    day_number=d.get("day_number", 1),
                    day_label=d.get("day_label"),
                    exercises=exs,
                ))
            weeks.append(PrescribedWeek(
                week_number=wk.get("week_number", 1),
                label=wk.get("label"),
                days=days,
            ))
        except Exception as err:
            logger.debug(f"[WorkoutExport] skipping malformed week in template: {err}")

    unit_hint_raw = row.get("unit_hint") or "kg"
    try:
        unit_hint = WeightUnit(unit_hint_raw)
    except ValueError:
        unit_hint = WeightUnit.KG

    try:
        return CanonicalProgramTemplate(
            user_id=user_id,
            source_app=row.get("source_app") or "fitwiz",
            program_name=row.get("program_name") or "Untitled Program",
            program_creator=row.get("program_creator"),
            program_version=row.get("program_version"),
            total_weeks=max(1, int(row.get("total_weeks") or len(weeks) or 1)),
            days_per_week=max(1, min(7, int(row.get("days_per_week") or 3))),
            unit_hint=unit_hint,
            one_rm_inputs=row.get("one_rm_inputs") or {},
            body_weight_kg=_safe_float(row.get("body_weight_kg")),
            rounding_multiple_kg=_safe_float(row.get("rounding_multiple_kg")) or 2.5,
            training_max_factor=_safe_float(row.get("training_max_factor")) or 1.0,
            weeks=weeks,
            notes=row.get("notes"),
        )
    except Exception as err:
        logger.warning(f"[WorkoutExport] failed to rebuild template {row.get('id')}: {err}")
        return None


def load_templates(user_id: UUID, *, db=None) -> List[CanonicalProgramTemplate]:
    if db is None:
        from core.db import get_supabase_db
        db = get_supabase_db()
    try:
        q = (
            db.client.table("workout_program_templates")
            .select("*")
            .eq("user_id", str(user_id))
            .order("created_at", desc=True)
        )
        result = q.execute()
        out: List[CanonicalProgramTemplate] = []
        for r in result.data or []:
            tpl = _rebuild_template(r, user_id)
            if tpl:
                out.append(tpl)
        logger.info(f"[WorkoutExport] load_templates user={user_id}: {len(out)} templates")
        return out
    except Exception as e:
        logger.warning(f"[WorkoutExport] failed to load templates: {e}")
        return []


# ─────────────────────────── User preferences ───────────────────────── #


def load_user_weight_unit(user_id: UUID, *, db=None) -> str:
    """Returns 'kg' or 'lbs'. Defaults to 'lbs' (Zealova user base is US-centric).

    Used by emitters that must pick one unit column (Strong, Fitbod). Never
    raises — a missing unit_hint shouldn't break an export.
    """
    if db is None:
        from core.db import get_supabase_db
        db = get_supabase_db()
    try:
        result = (
            db.client.table("users")
            .select("weight_unit")
            .eq("id", str(user_id))
            .limit(1)
            .execute()
        )
        if result.data:
            unit = (result.data[0].get("weight_unit") or "").lower()
            if unit in ("kg", "lbs"):
                return unit
    except Exception as e:
        logger.debug(f"[WorkoutExport] user weight_unit lookup failed (defaulting to lbs): {e}")
    return "lbs"


def load_user_first_name(user_id: UUID, *, db=None) -> str:
    """Used only for the PDF cover page. Never raises."""
    if db is None:
        from core.db import get_supabase_db
        db = get_supabase_db()
    try:
        result = (
            db.client.table("users")
            .select("first_name, name")
            .eq("id", str(user_id))
            .limit(1)
            .execute()
        )
        if result.data:
            row = result.data[0]
            for key in ("first_name", "name"):
                v = row.get(key)
                if v:
                    return str(v)
    except Exception:
        pass
    return "Athlete"
