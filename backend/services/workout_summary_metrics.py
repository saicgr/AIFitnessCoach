"""Canonical derivation of a logged workout session's headline metrics.

WHY THIS MODULE EXISTS
----------------------
One finished session used to be summed by **three** different formulas:

1. ``api/v1/workouts/crud_completion.py`` (the ``/complete`` aggregator) —
   ``reps x weight``, substituting ``bodyweight_proxy_load_kg`` when the set
   carried no external load. That number landed in
   ``workout_performance_summary.total_volume_kg``.
2. ``services/performance_comparison_service.build_performance_summary`` —
   ``reps x weight`` with **no** bodyweight proxy. That number landed in
   ``exercise_performance_summary.total_volume_kg``.
3. The Flutter summary screen (``summary_hero_stats.dart``) — ``reps x weight``
   with no proxy, used whenever the server rows were missing.

Result (E2E register #72): the same bodyweight session reported ``VOLUME 0 kg``
on the summary screen while the live screen showed ``1,476 kg``, and the two
server tables disagreed with each other (3 780 kg vs 0 kg) for one session.

Every producer of session volume / set counts / rep counts must call the
functions here. There is exactly one definition of each quantity.

DEFINITIONS
-----------
* **effective load** — the external load on the bar, or, when a set carried no
  external load, ``bodyweight_proxy_load_kg(exercise, user_bodyweight_kg)``
  (the same movement-pattern-keyed proxy PR detection and the strength
  composite already use). When the user's bodyweight is genuinely unknown the
  proxy is ``0.0`` — an honest "no load known", never an invented 70 kg.
* **volume** — ``sum(reps x effective_load)``. Time-only and distance-only
  sets have no reps, so they contribute **0 volume by construction** and are
  reported through ``work_seconds`` / ``distance_meters`` instead. Volume is
  never fabricated for them.
* **completed** — a set is completed when the client says so **or** when it
  carries recorded work (reps, hold time, distance, or a logged metric; load
  alone is a prescription, not evidence). A time-based set the client mislabels
  ``is_completed=false`` (register #75) is therefore still counted; a
  zero-stamped "Complete workout now" padding row still is not.

NATURAL KEY
-----------
``(workout_log_id, exercise_name, set_number)`` identifies a set within a
session. It is the key ``PATCH /performance/logs/by-set`` already addresses
rows by, the key the write endpoints upsert on, and the key migration 2342
enforces with a unique index so a re-run cannot double-log a session
(register #71).
"""

from __future__ import annotations

from typing import Any, Dict, Iterable, List, Mapping, Optional, Sequence, Tuple

from core.logger import get_logger
from services.exercise_rag.muscle_balance import bodyweight_proxy_load_kg
from services.metric_registry import FIRST_CLASS_COLUMN, KEY_TO_BAG

logger = get_logger(__name__)

# The columns that identify one logged set inside one session. Kept here so the
# write endpoints, the correction endpoint and the migration all name the same
# key instead of three hand-written tuples drifting apart.
SET_NATURAL_KEY: Tuple[str, str, str] = (
    "workout_log_id",
    "exercise_name",
    "set_number",
)

# PostgREST `on_conflict=` form of the same key.
SET_NATURAL_KEY_ON_CONFLICT: str = ",".join(SET_NATURAL_KEY)


# ---------------------------------------------------------------------------
# Field access — set rows reach us in three shapes.
# ---------------------------------------------------------------------------
# * `performance_logs` rows / `PerformanceLogCreate` payloads: reps_completed,
#   weight_kg, set_duration_seconds, distance_meters.
# * `workout_logs.sets_json` entries (Advanced `buildSetsJson`): reps,
#   reps_completed, weight_kg, set_duration_seconds.
# * the legacy planned-exercise shape: reps, weight_kg, duration_seconds.
#
# One accessor per quantity so a new caller cannot invent a fourth spelling.

_REPS_KEYS = ("reps_completed", "reps")
_WEIGHT_KEYS = ("weight_kg", "weight")
_DURATION_KEYS = ("set_duration_seconds", "duration_seconds")
_DISTANCE_KEYS = ("distance_meters",)
_NAME_KEYS = ("exercise_name", "name")


def _get(row: Any, keys: Sequence[str]) -> Any:
    """First present, non-None value among ``keys`` on a dict or an object."""
    if isinstance(row, Mapping):
        for k in keys:
            if k in row and row[k] is not None:
                return row[k]
        return None
    for k in keys:
        val = getattr(row, k, None)
        if val is not None:
            return val
    return None


def _num(value: Any) -> float:
    """Coerce to float; anything non-numeric is 0.0 (never raises).

    The 0.0 is NOT silent. ``workouts.exercises_json[].reps`` is a string in
    463 production rows and some of those are ranges or prose ("15-20",
    "39 minutes easy"); when the legacy planned-exercise path feeds one of
    those in, the set silently scores 0 reps and drops out of the totals — the
    same "summary says 0" symptom this module exists to kill. Log it so the bad
    shape is visible instead of quietly zeroing a session.
    """
    if value is None:
        return 0.0
    try:
        return float(value)
    except (TypeError, ValueError):
        logger.warning(
            "Non-numeric set quantity %r coerced to 0 — this set contributes "
            "nothing to the session totals; fix the writer's shape",
            value,
        )
        return 0.0


def _field(row: Any, keys: Sequence[str], metric_key: str) -> Any:
    """A first-class quantity, read from the typed shape or the metric bag.

    ``performance_logs.metrics`` is the canonical store for every per-set
    metric (``services/metric_registry``); the typed columns are a mirror. A
    bag-only writer therefore must not be invisible here, so when no typed
    spelling carries the value we fall back to the bag key the registry
    defines for it — never a fourth hand-written spelling.
    """
    val = _get(row, keys)
    if val is None:
        val = _set_metrics(row).get(KEY_TO_BAG[metric_key])
    return val


def set_reps(row: Any) -> int:
    return int(_num(_field(row, _REPS_KEYS, "reps")))


def set_weight_kg(row: Any) -> float:
    return _num(_field(row, _WEIGHT_KEYS, "weight"))


def set_duration_seconds(row: Any) -> int:
    return int(_num(_field(row, _DURATION_KEYS, "time")))


def set_distance_meters(row: Any) -> float:
    return _num(_field(row, _DISTANCE_KEYS, "distance"))


def set_exercise_name(row: Any) -> str:
    return str(_get(row, _NAME_KEYS) or "").strip()


def _set_metrics(row: Any) -> Dict[str, Any]:
    bag = _get(row, ("metrics",))
    return bag if isinstance(bag, dict) else {}


def natural_set_key(row: Any) -> Tuple[Any, str, int]:
    """``(workout_log_id, exercise_name, set_number)`` for a set row.

    ``exercise_name`` is compared case-sensitively because that is how the
    unique index compares it — the key here must match the key the database
    enforces, not a prettier normalisation of it.
    """
    return (
        _get(row, ("workout_log_id",)),
        set_exercise_name(row),
        int(_num(_get(row, ("set_number",)))),
    )


# ---------------------------------------------------------------------------
# Completion.
# ---------------------------------------------------------------------------

def _has_recorded_extra_metric(row: Any) -> bool:
    """True when the metric bag carries a NON-first-class metric with a value.

    The bag's mere presence is NOT evidence. ``build_metrics_bag`` always
    ``setdefault``s the first-class keys ``weight_kg`` and ``reps`` from the
    (required, ``ge=0``) model fields, so a zero-stamped placeholder posted to
    ``/performance/logs`` still arrives carrying ``{"weight_kg": 0.0,
    "reps": 0}``. Testing ``bool(bag)`` therefore marked EVERY set — including
    the ones the user explicitly skipped — as completed, inflating exactly the
    set/rep counts register #73 is about.

    The first-class metrics are already read by the accessors above (typed
    column or bag), so only an EXTRA metric (calories, box height, rpm, …)
    adds information here, and only when it carries a real, non-zero value.
    """
    for key, val in _set_metrics(row).items():
        if key in FIRST_CLASS_COLUMN or val is None:
            continue
        if isinstance(val, bool):
            if val:
                return True
            continue
        if isinstance(val, (int, float)):
            if float(val) != 0:
                return True
            continue
        if isinstance(val, str):
            if val.strip():
                return True
            continue
        if val:
            return True
    return False


def set_has_recorded_work(row: Any) -> bool:
    """True when the set carries evidence the user actually performed it.

    Evidence is reps, hold time, distance, or a logged extra metric — the
    things you can only have if you did the set.

    Load is deliberately NOT evidence. A weight on a set with no reps, no time
    and no distance is a *prescription* the user never executed (a 100 kg bench
    row with ``reps: 0`` is a skipped set, not a performed one), so counting it
    would resurrect exactly the padding rows this check exists to exclude.
    """
    return (
        set_reps(row) > 0
        or set_duration_seconds(row) > 0
        or set_distance_meters(row) > 0
        or _has_recorded_extra_metric(row)
    )


def resolve_set_completed(row: Any, declared: Optional[bool] = None) -> bool:
    """Authoritative ``is_completed`` for a set row.

    ``declared or set_has_recorded_work(row)``. Monotone in one direction only:
    a set carrying recorded work is completed even when the client flagged it
    ``false``, but a client ``true`` is never downgraded.

    This is the fix for register #75 — the Easy and Advanced writers both
    classify a set as a placeholder using ``reps <= 0 && weight <= 0 &&
    distance <= 0 && metrics.isEmpty``, forgetting hold time, so every
    time-based set (plank, wall sit, dead hang) persisted with
    ``is_completed=false`` and was then dropped from the summary's set/rep/
    volume aggregates.
    """
    if declared is None:
        declared = _get(row, ("is_completed", "completed"))
    if declared is True:
        return True
    return set_has_recorded_work(row)


# ---------------------------------------------------------------------------
# Load + volume.
# ---------------------------------------------------------------------------

def effective_load_kg(
    exercise_name: str,
    weight_kg: float,
    user_bodyweight_kg: Optional[float],
) -> float:
    """Load one rep of this set moved, in kg.

    External load when there is one; otherwise the movement-pattern-keyed
    bodyweight proxy. Returns 0.0 when the set is unloaded AND the user's
    bodyweight is unknown — an honest zero, not an invented default.
    """
    if weight_kg and weight_kg > 0:
        return float(weight_kg)
    if not user_bodyweight_kg or user_bodyweight_kg <= 0:
        return 0.0
    return bodyweight_proxy_load_kg(exercise_name or "", float(user_bodyweight_kg))


def set_volume_kg(row: Any, user_bodyweight_kg: Optional[float]) -> float:
    """Volume contributed by one set: ``reps x effective load``.

    Zero for time-only / distance-only sets (they have no reps) — their work
    is reported as ``work_seconds`` / ``distance_meters``.
    """
    reps = set_reps(row)
    if reps <= 0:
        return 0.0
    return reps * effective_load_kg(
        set_exercise_name(row), set_weight_kg(row), user_bodyweight_kg
    )


# ---------------------------------------------------------------------------
# Aggregation.
# ---------------------------------------------------------------------------

class SessionMetrics(dict):
    """Aggregate totals for a set of logged sets.

    A plain dict subclass so callers can splat it straight into a Supabase
    payload while still getting attribute access in code.
    """

    @property
    def total_sets(self) -> int:
        return int(self["total_sets"])

    @property
    def total_reps(self) -> int:
        return int(self["total_reps"])

    @property
    def total_volume_kg(self) -> float:
        return float(self["total_volume_kg"])


def aggregate_sets(
    rows: Iterable[Any],
    user_bodyweight_kg: Optional[float],
) -> SessionMetrics:
    """Totals over an iterable of set rows, counting completed sets only.

    Completion is resolved through :func:`resolve_set_completed`, so a
    mis-flagged time-based set is included and a zero-stamped padding row is
    not.
    """
    total_sets = 0
    total_reps = 0
    total_volume = 0.0
    work_seconds = 0
    distance_meters = 0.0
    max_weight: Optional[float] = None
    loaded_weights: List[float] = []
    rpes: List[float] = []
    rirs: List[float] = []

    for row in rows:
        if not resolve_set_completed(row):
            continue
        total_sets += 1
        total_reps += set_reps(row)
        total_volume += set_volume_kg(row, user_bodyweight_kg)
        work_seconds += set_duration_seconds(row)
        distance_meters += set_distance_meters(row)

        weight = set_weight_kg(row)
        if weight > 0:
            loaded_weights.append(weight)
            if max_weight is None or weight > max_weight:
                max_weight = weight

        rpe = _get(row, ("rpe",))
        if rpe is not None:
            rpes.append(_num(rpe))
        rir = _get(row, ("rir",))
        if rir is not None:
            rirs.append(_num(rir))

    return SessionMetrics(
        total_sets=total_sets,
        total_reps=total_reps,
        total_volume_kg=round(total_volume, 2),
        work_seconds=work_seconds or None,
        distance_meters=round(distance_meters, 2) if distance_meters else None,
        max_weight_kg=round(max_weight, 2) if max_weight is not None else None,
        avg_weight_kg=(
            round(sum(loaded_weights) / len(loaded_weights), 2)
            if loaded_weights
            else None
        ),
        avg_rpe=round(sum(rpes) / len(rpes), 1) if rpes else None,
        avg_rir=round(sum(rirs) / len(rirs), 1) if rirs else None,
    )


def dedupe_sets_by_natural_key(rows: Sequence[Any]) -> List[Any]:
    """Collapse rows sharing a natural key, keeping the LAST occurrence.

    Two reasons this exists:

    * A payload that repeats a key would make Postgres reject the whole
      ``INSERT ... ON CONFLICT DO UPDATE`` batch with *"command cannot affect
      row a second time"*, so the write endpoints must collapse first.
    * Re-running a workout re-sends the same session; the newest values are the
      ones the user just performed, which is the same "keep the latest" rule
      migration 2342 applied to the rows already in the table.
    """
    collapsed: Dict[Tuple[Any, str, int], Any] = {}
    for row in rows:
        collapsed[natural_set_key(row)] = row
    return list(collapsed.values())


# ---------------------------------------------------------------------------
# Bodyweight resolution.
# ---------------------------------------------------------------------------

def resolve_user_bodyweight_kg(user_id: str, supabase=None) -> Optional[float]:
    """The user's most recent real bodyweight in kg, or ``None``.

    Precedence: newest ``user_metrics.weight_kg`` (a measurement the user
    logged) → ``users.weight_kg`` (onboarding / profile) → ``None``.

    ``None`` is a valid answer and callers MUST treat it as "unknown" — never
    substitute a stand-in mass. ``/complete`` used to default to 70.0 kg, and
    since ``user_metrics`` is empty in production that default was in force for
    every user with a real ``users.weight_kg`` on file (82 kg for the account in
    the E2E register), silently skewing every bodyweight volume and every
    bodyweight PR proxy.
    """
    if not user_id:
        return None
    if supabase is None:
        from core.db import get_supabase_db

        supabase = get_supabase_db().client

    try:
        res = (
            supabase.table("user_metrics")
            .select("weight_kg")
            .eq("user_id", user_id)
            .not_.is_("weight_kg", "null")
            .order("recorded_at", desc=True)
            .limit(1)
            .execute()
        )
        rows = (res.data if res else None) or []
        if rows and rows[0].get("weight_kg"):
            return float(rows[0]["weight_kg"])
    except Exception as exc:  # pragma: no cover - network/schema drift
        logger.warning(f"user_metrics bodyweight lookup failed for {user_id}: {exc}")

    try:
        res = (
            supabase.table("users")
            .select("weight_kg")
            .eq("id", user_id)
            .maybe_single()
            .execute()
        )
        # `.maybe_single()` returns None (not a response) on zero rows.
        data = (res.data if res else None) or {}
        if data.get("weight_kg"):
            return float(data["weight_kg"])
    except Exception as exc:  # pragma: no cover - network/schema drift
        logger.warning(f"users bodyweight lookup failed for {user_id}: {exc}")

    return None
