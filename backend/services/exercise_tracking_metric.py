"""
Exercise tracking-metric derivation (the single source of truth).

Cardio / functional / timed exercises (SkiErg, Sled Push/Pull, Farmers Carry,
Rowing/RowErg, runs, Plank Hold, Wall Balls, Burpees…) must NOT render in the
active-workout UI as "weight × reps". The workout payload historically carried
no structured tracking metadata, so the Flutter client fell back to a phantom
10 kg × reps card and ``num.tryParse("1000 m") -> null`` dropped the unit.

This module derives, per exercise, a ``tracking_type`` enum + the structured
target (distance / duration) the client needs, plus a raw unit-bearing
``reps_spec`` string as a last-resort display/parse fallback.

Pure + deterministic + dependency-free (no DB, no network) so it can be:
  • applied at every serve-time chokepoint (``/today``, workout-detail,
    program expansion) with zero added latency, and
  • unit-tested in isolation.

The decision is sourced FIRST from canonical ``exercise_library`` metadata
(``equipment``, ``is_timed``, ``movement_pattern`` — when present on the
exercise dict or passed as ``library_meta``), then falls back to parsing the
program's reps / reps_spec string + the exercise name. This mirrors the
fail-open, name-classifier philosophy of ``_attach_movement_meta`` in
``api/v1/workouts/today.py``: an unknown exercise yields ``tracking_type=None``
(the frontend has its own classifier), never a wrong default.
"""
from __future__ import annotations

import re
from typing import Any, Dict, List, Optional


# ---------------------------------------------------------------------------
# Tracking-type enum (string literals shared with the Flutter contract)
# ---------------------------------------------------------------------------
TRACK_WEIGHT = "weight"
TRACK_BODYWEIGHT = "bodyweight"
TRACK_TIME = "time"
TRACK_DISTANCE = "distance"


# ---------------------------------------------------------------------------
# Name lexicons (lowercase substring match). Kept deliberately specific — a
# false positive here mislabels a real loaded lift, so we only list movements
# whose PRIMARY metric is unambiguous.
# ---------------------------------------------------------------------------

# Distance-primary: cardio machines, sleds, loaded carries, measured runs,
# horizontal jumps. These may ALSO be timed; distance wins for the primary
# metric but we still surface duration when present.
_DISTANCE_NAME_HINTS = (
    "skierg", "ski erg", "ski-erg",
    "rowerg", "row erg", "row-erg", "rowing machine", "erg row",
    "rowing", "row machine",
    "sled push", "sled pull", "sled drag", "sled sprint", "prowler",
    "farmer", "farmers carry", "farmer's carry", "farmers walk",
    "suitcase carry", "suitcase walk", "loaded carry", "yoke carry",
    "yoke walk", "sandbag carry", "overhead carry", "waiter walk",
    "broad jump", "standing long jump",
    "shuttle run", "shuttle sprint", "beep test",
    "run", "jog", "sprint", "walk lunge distance",
    "bike erg", "bikeerg", "assault bike distance",
)

# Names that look like a carry/run but are NOT distance-tracked, so the broad
# hints above never mislabel them. (e.g. "carry" inside "farmers carry hold").
_DISTANCE_NAME_EXCLUDE = (
    "calf raise", "farmer hold",  # static holds, not measured by distance
)

# Bodyweight rep movements (equipment-free, rep-counted). Wall Ball is included
# per the product contract even though it uses a med ball — its load is fixed
# and the user counts reps, not weight.
_BODYWEIGHT_NAME_HINTS = (
    "burpee", "air squat", "bodyweight squat", "push-up", "push up", "pushup",
    "pull-up", "pull up", "pullup", "chin-up", "chin up", "chinup",
    "mountain climber", "jumping jack", "box jump", "tuck jump", "jump squat",
    "squat jump", "wall ball", "wall-ball", "sit-up", "sit up", "situp",
    "v-up", "v up", "toes to bar", "toes-to-bar", "knees to elbow",
    "inverted row", "muscle-up", "muscle up", "high knees", "butt kick",
    "bear crawl", "crab walk", "skater", "star jump",
)

# Timed holds (isometric / duration-based). The user tracks seconds, not reps.
_TIME_NAME_HINTS = (
    "plank", "wall sit", "wall-sit", "dead hang", "dead-hang", "bar hang",
    "hollow hold", "hollow body hold", "l-sit", "l sit", "side plank",
    "superman hold", "glute bridge hold", "hold", "isometric",
    "static hold", "wall squat hold", "boat pose", "chair pose",
)

# Bodyweight equipment tokens — equipment values that mean "no external load".
_BODYWEIGHT_EQUIPMENT = {"bodyweight", "body weight", "none", "no equipment", ""}

# Movement patterns (from services.exercise_rag.sane_ranges) that are
# rep-based bodyweight movements.
_BODYWEIGHT_PATTERNS = {
    "bodyweight_push", "bodyweight_pull", "bodyweight_squat",
}
_CARRY_PATTERNS = {"carry"}

# Loaded sleds / carries: a distance/time station that ALSO takes a load, so its
# metric set includes `weight`. Mirrored in the Flutter classifier
# (ExerciseTrackingMetric.isLoadedCarry).
_LOADED_CARRY_HINTS = (
    "sled", "prowler", "yoke", "farmer", "suitcase carry", "loaded carry",
    "overhead carry", "waiter walk", "sandbag carry", "sandbag lunge",
)
_LOADED_EQUIPMENT = {
    "sled", "sandbag", "dumbbell", "dumbbells", "kettlebell", "kettlebells",
    "barbell", "weight plate", "trap bar", "yoke",
}


def _is_loaded_carry(name: str, equipment_tokens: List[str]) -> bool:
    if _name_matches(name, _LOADED_CARRY_HINTS):
        return True
    return any(t in _LOADED_EQUIPMENT for t in equipment_tokens)


def _metric_keys_for(result: Dict[str, Any], exercise: Dict[str, Any],
                     library_meta: Optional[Dict[str, Any]]) -> Optional[List[str]]:
    """Ordered metric columns for an exercise, from its primary tracking_type +
    the loaded-carry rule. weight lift -> [weight,reps]; bodyweight -> [reps];
    time -> [time]; distance -> [distance]; loaded carry -> weight prepended."""
    tt = result.get("tracking_type")
    if tt == TRACK_WEIGHT:
        keys = ["weight", "reps"]
    elif tt == TRACK_BODYWEIGHT:
        keys = ["reps"]
    elif tt == TRACK_TIME:
        keys = ["time"]
    elif tt == TRACK_DISTANCE:
        keys = ["distance"]
    else:
        return None
    if tt in (TRACK_DISTANCE, TRACK_TIME) and _is_loaded_carry(
        _name_of(exercise), _equipment_tokens(exercise, library_meta)
    ):
        keys = ["weight"] + keys
    return keys


# ---------------------------------------------------------------------------
# String parsers (robust, unit-bearing).
# ---------------------------------------------------------------------------

# Distance: "1 km", "1km", "1.5 km", "1000 m", "1000m", "200 meters",
# "400 yards", "400 yd", "1 mile", "1.2 miles", "880 yards".
_DISTANCE_RE = re.compile(
    r"(\d+(?:\.\d+)?)\s*"
    r"(km|kilometers?|kilometres?|m(?:eters?|etres?)?|mi(?:les?)?|yd|yards?)\b",
    re.IGNORECASE,
)

# Duration: "8 minutes", "8 min", "2 min", "30s", "45s hold", "30 sec",
# "90 seconds", "1 hour". NOTE: a bare "m"/"meters" is distance, never minutes,
# so the minute token requires "min". Hour supported for completeness.
_DURATION_RE = re.compile(
    r"(\d+(?:\.\d+)?)\s*"
    r"(h(?:ours?|rs?)?|min(?:utes?|s)?|s(?:ec(?:onds?|s)?)?)\b",
    re.IGNORECASE,
)


def parse_distance_meters(text: Any) -> Optional[float]:
    """Parse a free-text distance target into meters, or None.

    "1 km"->1000, "1000 m"->1000, "200m"->200, "400 yards"->365.76,
    "1 mile"->1609.34. Returns None when no distance unit is present.
    """
    if text is None:
        return None
    if isinstance(text, (int, float)):
        # Bare number with no unit is ambiguous (reps vs meters) — refuse.
        return None
    m = _DISTANCE_RE.search(str(text))
    if not m:
        return None
    value = float(m.group(1))
    unit = m.group(2).lower()
    if unit.startswith("km") or unit.startswith("kilom"):
        return round(value * 1000.0, 2)
    if unit.startswith("mi"):
        return round(value * 1609.34, 2)
    if unit.startswith("yd") or unit.startswith("yard"):
        return round(value * 0.9144, 2)
    # meters family ("m", "meter", "metre", "meters")
    return round(value, 2)


def parse_duration_seconds(text: Any) -> Optional[int]:
    """Parse a free-text duration target into whole seconds, or None.

    "8 minutes"->480, "30s"->30, "45s hold"->45, "2 min"->120, "1 hour"->3600.
    A bare number or a distance unit returns None.
    """
    if text is None:
        return None
    if isinstance(text, (int, float)):
        return None
    m = _DURATION_RE.search(str(text))
    if not m:
        return None
    value = float(m.group(1))
    unit = m.group(2).lower()
    if unit.startswith("h"):
        return int(round(value * 3600))
    if unit.startswith("min"):
        return int(round(value * 60))
    # seconds family
    return int(round(value))


# ---------------------------------------------------------------------------
# Field readers (tolerant of the many shapes an exercise dict takes across the
# AI / curated / custom generation paths).
# ---------------------------------------------------------------------------
def _name_of(ex: Dict[str, Any]) -> str:
    return str(ex.get("name") or ex.get("exercise_name") or "").strip().lower()


def _reps_target_string(ex: Dict[str, Any]) -> Optional[str]:
    """Best raw, unit-bearing target string for display/parse fallback.

    Prefers an explicit reps string; renders a structured ``reps_spec`` dict
    to its human form; tolerates a bare numeric reps value.
    """
    spec = ex.get("reps_spec")
    if isinstance(spec, dict):
        try:
            from services.program_library_importer import reps_spec_display
            rendered = reps_spec_display(spec)
            if rendered:
                return rendered
        except Exception:
            # Fall through to the raw reps below — never raise from a serializer.
            pass
    if isinstance(spec, str) and spec.strip():
        return spec.strip()
    reps = ex.get("reps")
    if reps is None:
        # Time-based holds sometimes carry duration only.
        for k in ("duration", "duration_text", "target"):
            v = ex.get(k)
            if v:
                return str(v)
        return None
    return str(reps)


def _equipment_tokens(ex: Dict[str, Any], library_meta: Optional[Dict[str, Any]]) -> List[str]:
    raw = None
    if library_meta and library_meta.get("equipment") is not None:
        raw = library_meta.get("equipment")
    if raw is None:
        raw = ex.get("equipment")
    tokens: List[str] = []
    if isinstance(raw, str):
        tokens = [raw.strip().lower()]
    elif isinstance(raw, list):
        tokens = [str(t).strip().lower() for t in raw if t is not None]
    return tokens


def _is_bodyweight_equipment(tokens: List[str]) -> bool:
    if not tokens:
        return False
    return all(t in _BODYWEIGHT_EQUIPMENT for t in tokens)


def _name_matches(name: str, hints: tuple) -> bool:
    return any(h in name for h in hints)


# ---------------------------------------------------------------------------
# The single derivation entry point.
# ---------------------------------------------------------------------------
def _derive_core(
    exercise: Dict[str, Any],
    library_meta: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """Derive structured tracking metadata for one exercise dict.

    Returns a dict with keys:
      ``tracking_type``   : "weight"|"bodyweight"|"time"|"distance"|None
      ``distance_meters`` : float target meters (distance only) | None
      ``duration_seconds``: int target seconds (when known) | None
      ``hold_seconds``    : int hold seconds (timed holds) | None
      ``reps_spec``       : raw unit-bearing target string | None

    ``library_meta`` (optional) is the canonical ``exercise_library`` row for
    this exercise (``equipment``, ``is_timed``, ``movement_pattern``,
    ``default_hold_seconds``); when supplied it is consulted FIRST.

    Pure + fail-open: any ambiguity that can't be resolved yields
    ``tracking_type=None`` so the client's own classifier decides.
    """
    lm = library_meta or {}
    name = _name_of(exercise)
    reps_spec_str = _reps_target_string(exercise)

    # Corroborating signals, library-first.
    pattern = lm.get("movement_pattern") or exercise.get("movement_pattern")
    is_timed = lm.get("is_timed")
    if is_timed is None:
        is_timed = exercise.get("is_timed")
    hold_seconds = (
        lm.get("default_hold_seconds")
        or exercise.get("hold_seconds")
        or exercise.get("default_hold_seconds")
    )
    duration_seconds = exercise.get("duration_seconds") or lm.get("duration_seconds")
    equipment_tokens = _equipment_tokens(exercise, library_meta)

    # Parse the unit-bearing target string once.
    parsed_distance = parse_distance_meters(reps_spec_str)
    parsed_duration = parse_duration_seconds(reps_spec_str)

    result: Dict[str, Any] = {
        "tracking_type": None,
        "distance_meters": None,
        "duration_seconds": None,
        "hold_seconds": None,
        "reps_spec": reps_spec_str,
    }

    # --- 1) DISTANCE (highest precedence for the primary metric) -------------
    name_is_distance = (
        _name_matches(name, _DISTANCE_NAME_HINTS)
        and not _name_matches(name, _DISTANCE_NAME_EXCLUDE)
    )
    pattern_is_carry = pattern in _CARRY_PATTERNS
    if parsed_distance is not None or name_is_distance or pattern_is_carry:
        result["tracking_type"] = TRACK_DISTANCE
        result["distance_meters"] = parsed_distance
        # Distance stations can also be timed (e.g. "8 minutes" AMRAP row).
        if parsed_duration is not None:
            result["duration_seconds"] = parsed_duration
        elif isinstance(duration_seconds, (int, float)) and duration_seconds:
            result["duration_seconds"] = int(duration_seconds)
        return result

    # --- 2) TIME (isometric holds / duration-based) --------------------------
    name_is_time = _name_matches(name, _TIME_NAME_HINTS)
    has_hold = bool(hold_seconds) or bool(is_timed)
    if parsed_duration is not None or name_is_time or has_hold:
        result["tracking_type"] = TRACK_TIME
        secs = (
            parsed_duration
            if parsed_duration is not None
            else (int(hold_seconds) if hold_seconds else None)
        )
        if secs is None and isinstance(duration_seconds, (int, float)) and duration_seconds:
            secs = int(duration_seconds)
        result["duration_seconds"] = secs
        if hold_seconds:
            result["hold_seconds"] = int(hold_seconds)
        elif secs is not None and (name_is_time or is_timed):
            result["hold_seconds"] = secs
        return result

    # --- 3) BODYWEIGHT (rep-based, no external load) -------------------------
    name_is_bodyweight = _name_matches(name, _BODYWEIGHT_NAME_HINTS)
    pattern_is_bodyweight = pattern in _BODYWEIGHT_PATTERNS
    equip_is_bodyweight = _is_bodyweight_equipment(equipment_tokens)
    if name_is_bodyweight or pattern_is_bodyweight or (
        equip_is_bodyweight and result["reps_spec"] is not None
    ):
        result["tracking_type"] = TRACK_BODYWEIGHT
        return result

    # --- 4) WEIGHT (default: everything else is a loaded lift) ---------------
    result["tracking_type"] = TRACK_WEIGHT
    return result


def derive_tracking_metadata(
    exercise: Dict[str, Any],
    library_meta: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """Derive tracking metadata for one exercise: the primary ``tracking_type``,
    structured targets (distance/duration/hold), AND the ordered ``metric_keys``
    column list (the generic capability set — e.g. a loaded sled push yields
    ``["weight","distance"]``). Pure + fail-open. ``library_meta`` is consulted
    first when supplied. See module docstring.
    """
    result = _derive_core(exercise, library_meta)
    keys = _metric_keys_for(result, exercise, library_meta)
    if keys:
        result["metric_keys"] = keys
    return result


# ---------------------------------------------------------------------------
# In-place applier used at the serve-time chokepoints.
# ---------------------------------------------------------------------------
def attach_tracking_metadata(exercises: Any) -> None:
    """In-place: tag each exercise dict in ``exercises`` with tracking metadata.

    Sets ``tracking_type`` + ``distance_meters`` always; backfills
    ``duration_seconds`` / ``hold_seconds`` / ``reps_spec`` only when derived
    and not already present (never clobbers a real generation-time value).

    Cheap + deterministic — safe to call on every workout serialize. No-op for
    non-list / non-dict entries.
    """
    if not isinstance(exercises, list):
        return
    for ex in exercises:
        if not isinstance(ex, dict):
            continue
        try:
            meta = derive_tracking_metadata(ex)
        except Exception:
            # A serializer must never raise — skip a single bad entry.
            continue
        if meta.get("tracking_type"):
            ex["tracking_type"] = meta["tracking_type"]
        if meta.get("metric_keys"):
            ex["metric_keys"] = meta["metric_keys"]
        if meta.get("distance_meters") is not None:
            ex["distance_meters"] = meta["distance_meters"]
        # Backfill duration/hold/reps_spec without overwriting real values.
        if meta.get("duration_seconds") is not None and not ex.get("duration_seconds"):
            ex["duration_seconds"] = meta["duration_seconds"]
        if meta.get("hold_seconds") is not None and not ex.get("hold_seconds"):
            ex["hold_seconds"] = meta["hold_seconds"]
        # reps_spec is the raw unit-bearing string the frontend parses as a last
        # resort. Only set it as a string when it isn't already a non-empty
        # string (preserve any structured value the program path persisted).
        if meta.get("reps_spec") and not (
            isinstance(ex.get("reps_spec"), str) and ex.get("reps_spec").strip()
        ):
            ex["reps_spec"] = meta["reps_spec"]
