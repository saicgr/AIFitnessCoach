"""
Single duration/energy derivation for a workout's exercise list — E2E #146.

WHY THIS EXISTS
----------------
The SAME workout used to report 45 MIN / 226 CAL, then later 11 MIN / 55 CAL,
because FOUR different models computed duration/calories and never agreed —
and worse, most of them never PERSISTED anything, so the client fell back to
its own MET formula whenever a field was null:

  1. ``/generate`` + ``/generate-stream`` (generation_endpoints.py:1770,
     generation_streaming.py:1422) DO write ``estimated_calories`` —
     ``round(met * weight_kg * duration_min / 60)`` using
     ``_estimate_workout_met`` (generation_helpers.py) against the
     AI-decided ``target_duration``.
  2. Program expansion (``program_template_expander.py``
     ``expand_template`` / ``expand_variant_weeks``) never wrote
     ``duration_minutes`` OR ``estimated_calories`` at all — the row dict
     simply has no such keys — so a program-expanded session's client had
     to derive BOTH from scratch via its own MET fallback.
  3. ``api/v1/workouts/reshape.py`` ``POST /reshape-for-readiness`` rewrites
     ``duration_minutes`` via its OWN third estimator
     (``sets * (40 + rest) / 60``) but never touched ``estimated_calories``
     — so the client's MET fallback recomputed calories against the NEW
     duration with the SAME implied MET, moving the calorie headline in
     lockstep with duration alone (226/45 = 55/11 = 5.02 kcal/min).
  4. ``api/v1/workouts/quick_adjust.py`` has a FOURTH estimator
     (``sets * 90s + 30s`` per exercise) that only ever appears in the
     response payload — never persisted, but yet another number the user
     could see disagree with the stored row.

THE FIX
-------
One duration estimator (moved here from reshape.py — the more
composition-aware ``sets * (work + rest)`` model) and one energy estimator
(the existing MET formula, unchanged, so /generate's numbers don't shift).
Both wrapped by :func:`derive_duration_and_calories`, which every writer of
a workout's ``duration_minutes`` / ``estimated_calories`` should route
through:

  * Program expansion calls it at INSERT time, so ``estimated_calories`` is
    never null for a program-expanded session.
  * Reshape calls it whenever it rewrites ``duration_minutes``, so the
    energy figure moves with the ACTUAL new exercise composition instead of
    being silently left to a client-side re-derivation.

Pure + dependency-light (no DB) so it is trivially unit-testable; the one
DB touch (resolving a user's ``weight_kg``) is a separate, optional helper
callers can skip if they already have the weight on hand.
"""
from __future__ import annotations

from typing import Any, Dict, List, Optional, Tuple

from .generation_helpers import _estimate_workout_met

DEFAULT_WEIGHT_KG = 70.0
_MIN_WEIGHT_KG = 30.0
_MAX_WEIGHT_KG = 250.0


def estimate_duration_minutes(exercises: List[Dict[str, Any]]) -> int:
    """Rough wall-clock estimate: per exercise ~= sets x (work + rest).

    Canonical duration model (moved from ``reshape.py._estimate_minutes`` —
    identical formula, so this is a pure relocation, not a behavior change
    for the site that already used it).
    """
    total = 0.0
    for ex in exercises or []:
        if not isinstance(ex, dict):
            continue
        sets = ex.get("sets") or 3
        rest = ex.get("rest_seconds") or 60
        try:
            sets = int(sets)
        except (TypeError, ValueError):
            sets = 3
        try:
            rest = int(rest)
        except (TypeError, ValueError):
            rest = 60
        # ~40s of work per set + the prescribed rest, in minutes.
        total += sets * (40 + rest) / 60.0
    return max(1, round(total))


def _sanitized_for_met(exercises: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Coerce `sets`/`reps`/`weight` to numbers `_estimate_workout_met` can do
    arithmetic on. Program-expanded exercises can carry a range/string `reps`
    ("8-12") or a `weight_kg` key instead of `weight` — passing those straight
    through raises inside the MET formula's `sets * reps * weight` volume
    calc. Never raises; unparseable fields just fall back to a neutral value.
    """
    out: List[Dict[str, Any]] = []
    for ex in exercises or []:
        if not isinstance(ex, dict):
            continue
        clean = dict(ex)
        sets = ex.get("sets")
        try:
            clean["sets"] = int(sets) if sets is not None else 3
        except (TypeError, ValueError):
            clean["sets"] = 3

        reps = ex.get("reps")
        reps_num: Optional[int] = None
        if isinstance(reps, (int, float)):
            reps_num = int(reps)
        elif isinstance(reps, str):
            # "8-12" -> 8 (lower end); "AMRAP"/"30s"/"" -> unparseable -> default.
            head = reps.split("-")[0].strip()
            if head.isdigit():
                reps_num = int(head)
        clean["reps"] = reps_num if reps_num is not None else 10

        weight = ex.get("weight")
        if weight is None:
            weight = ex.get("weight_kg")  # program-expanded exercises use this key
        try:
            clean["weight"] = float(weight) if weight is not None else 0.0
        except (TypeError, ValueError):
            clean["weight"] = 0.0
        out.append(clean)
    return out


def estimate_workout_calories(
    exercises: List[Dict[str, Any]],
    workout_type: Optional[str],
    difficulty: Optional[str],
    duration_minutes: int,
    weight_kg: Optional[float] = None,
) -> int:
    """MET-based calorie estimate — the SAME formula /generate has always
    used (``_estimate_workout_met`` x weight x duration/60), just made
    reusable and defensive against the looser exercise shapes program
    expansion / reshape produce. Never raises: returns 0 on any failure
    (fail-open — a workout must never fail to save because of this).
    """
    try:
        w = float(weight_kg) if weight_kg is not None else DEFAULT_WEIGHT_KG
        w = max(_MIN_WEIGHT_KG, min(w, _MAX_WEIGHT_KG))
        safe_exercises = _sanitized_for_met(exercises)
        met = _estimate_workout_met(safe_exercises, workout_type, difficulty)
        return round(met * w * (max(0, duration_minutes) / 60.0))
    except Exception:  # noqa: BLE001 — never block a workout save over calories
        return 0


def derive_duration_and_calories(
    exercises: List[Dict[str, Any]],
    workout_type: Optional[str] = None,
    difficulty: Optional[str] = None,
    weight_kg: Optional[float] = None,
    duration_minutes: Optional[int] = None,
) -> Tuple[int, int]:
    """Return ``(duration_minutes, estimated_calories)`` for one workout.

    ``duration_minutes``: pass an authored/requested duration to use it
    verbatim for the calorie calc (e.g. the user's target duration at
    generation time); omit it to DERIVE duration from the exercise
    composition (``estimate_duration_minutes``) — the case program
    expansion and reshape both need, since neither has an authored target.
    """
    resolved_duration = (
        int(duration_minutes)
        if duration_minutes is not None
        else estimate_duration_minutes(exercises)
    )
    calories = estimate_workout_calories(
        exercises, workout_type, difficulty, resolved_duration, weight_kg
    )
    return resolved_duration, calories


def resolve_user_weight_kg(db, user_id: str) -> float:
    """Fetch a user's weight in kg for the calorie formula, clamped to a sane
    range. Mirrors the inline logic generation_endpoints.py has used since
    the MET formula was introduced. Fails open to ``DEFAULT_WEIGHT_KG``.
    """
    try:
        client = getattr(db, "client", db)
        # `users` has weight_kg / target_weight_kg / weight_unit /
        # workout_weight_unit — there is NO bare `weight` column. Selecting one
        # made PostgREST reject the WHOLE query with 42703 (including the valid
        # weight_kg beside it), which the except below then swallowed, so every
        # calorie estimate silently fell back to DEFAULT_WEIGHT_KG. That is the
        # phantom-column class documented in CLAUDE.md and caught by
        # scripts/audit_supabase_column_drift.py --check.
        res = (
            client.table("users")
            .select("weight_kg")
            .eq("id", user_id)
            .limit(1)
            .execute()
        )
        rows = res.data or []
        if rows:
            raw = rows[0].get("weight_kg")
            if raw is not None:
                w = float(raw)
                return max(_MIN_WEIGHT_KG, min(w, _MAX_WEIGHT_KG))
    except Exception:  # noqa: BLE001 — fail open to the default
        pass
    return DEFAULT_WEIGHT_KG
