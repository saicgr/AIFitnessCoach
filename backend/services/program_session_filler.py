"""
Deterministic top-up for under-populated curated-program sessions.

WHY THIS EXISTS (read before touching the program pipeline)
-----------------------------------------------------------
The 18 launch programs schedule their content from ``program_variant_weeks.workouts``
(a JSON array of sessions). In 2026-06 an audit found ~1,133 sessions across 48
variants of the 16 variant-backed published programs had only **3 main exercises**
in a 45-60 min slot that should hold ~5. Root cause: the variant generator's
validation gate (`generate_programs.py:validate_week`) only required
``exercises_found >= sessions * 3`` as a WEEK TOTAL, while the prompt's
`_volume_clause` asked for >=5/session — so Gemini Flash-Lite's thin 3/session
weeks cleared the lenient gate and shipped. (See plan
``.claude/plans/one-more-change-to-tingly-wreath.md``.)

This module is the single source of truth for "bring a thin session up to its
floor". It is used in TWO places so the fix can't regress:
  - ``scripts/backfill_thin_program_sessions.py`` — repairs already-shipped data.
  - ``scripts/generate_curated_variants.py`` — a safety net run before ingest, so
    a thin LLM week is topped-up to the floor before it is written.

DESIGN INVARIANTS (decisions confirmed with the product owner)
--------------------------------------------------------------
1. Target is a duration-scaled FLOOR (minimum), constant across weeks — NOT a
   rigid equality and NOT a separate count/difficulty ramp. The programs ALREADY
   periodize via sets + deload weeks (4 & 10); we only fix the thin base count.
2. Added accessories COPY sets/reps/rest from a same-week sibling, so they inherit
   that week's periodized volume + deload automatically (no extra ramp logic).
3. Additions come from the injury/equipment-safe library candidate fetch
   (`exercise_rag.fetch_safe_candidates`) → they carry a real ``exercise_id`` so
   their illustration/media auto-resolves. We NEVER invent a non-library exercise.
4. Equipment is gated PER PROGRAM: the caller passes the program's equipment union,
   so a bodyweight/home program can only ever pull bodyweight additions (never a
   barbell).
5. NEVER pad a pure distance/time conditioning block (HYROX run, row, yoga flow).
6. Additions are appended as standalone STRAIGHT sets (``superset_group=None``);
   existing supersets are never split or joined. (Pairing added isolation work
   into supersets is a judgement call left to the human/agent review layer for
   intermediate+ aesthetic programs only.)
7. Idempotent: a session already at/above its floor is a no-op, and dedupe by
   normalized name means a re-run can never duplicate an addition. Every added
   exercise carries ``"backfilled": True`` for audit.
"""
from __future__ import annotations

import re
from typing import Any, Awaitable, Callable, Dict, List, Optional

try:
    from core.logger import get_logger
    logger = get_logger(__name__)
except Exception:  # pragma: no cover - allow standalone import in tests
    import logging
    logger = logging.getLogger(__name__)

from services.exercise_tracking_metric import (
    TRACK_DISTANCE,
    TRACK_TIME,
    derive_tracking_metadata,
)

# Programs/sessions whose short or non-strength nature makes the floor inapplicable.
_EXEMPT_TYPE_TOKENS = {
    "yoga", "mobility", "recovery", "stretch", "stretching",
    "warmup", "warm-up", "cooldown", "cool-down", "rest", "conditioning",
}
_EXEMPT_NAME_TOKENS = {
    "yoga", "mobility", "express", "plank", "warm-up", "warmup",
    "cool-down", "cooldown", "recovery", "stretch", "amrap finisher",
    "finisher", "flow",
}

# workout_name token  -> focus key understood by fetch_safe_candidates._FOCUS_SYNONYMS
_NAME_FOCUS_RULES = [
    ("push", ["push"]),
    ("pull", ["pull"]),
    ("upper", ["upper_body"]),
    ("lower", ["legs"]),
    ("leg", ["legs"]),
    ("glute", ["legs"]),
    ("full", ["full_body"]),
    ("core", ["core"]),
    ("abs", ["core"]),
    ("ab ", ["core"]),
    ("arm", ["arms"]),
    ("chest", ["chest"]),
    ("back", ["back"]),
    ("shoulder", ["shoulders"]),
    ("delt", ["shoulders"]),
]

# body_part / primary_muscle substring -> focus key (fallback when the name is generic)
_MUSCLE_FOCUS_RULES = [
    (("chest", "pec", "tricep", "shoulder", "delt"), "push"),
    (("back", "lat", "bicep", "trap", "rhomboid"), "pull"),
    (("quad", "hamstring", "glute", "calf", "calves", "leg", "adductor", "abductor"), "legs"),
    (("abdom", "oblique", "core", "waist"), "core"),
]


def _norm(name: Any) -> str:
    """Dedup key: lowercase, alphanumeric-only. Mirrors the loose matching used
    elsewhere for program exercise names (enough to prevent re-adding a name)."""
    return re.sub(r"[^a-z0-9]+", "", str(name or "").lower())


def _session_target_exercises(workout: Dict[str, Any]) -> int:
    """Duration-scaled FLOOR of main exercises for a session.
    <=30min->4, 31-50->5, 51-65->6, 66+->7. Missing duration -> 5."""
    try:
        dur = int(workout.get("duration_minutes") or 0)
    except (TypeError, ValueError):
        dur = 0
    if dur <= 0:
        return 5
    if dur <= 30:
        return 4
    if dur <= 50:
        return 5
    if dur <= 65:
        return 6
    return 7


def _tracking_type(ex: Dict[str, Any]) -> str:
    try:
        return (derive_tracking_metadata(ex).get("tracking_type") or "weight")
    except Exception:  # never let the classifier break a fill
        return "weight"


def _is_conditioning_session(exercises: List[Dict[str, Any]]) -> bool:
    """True when EVERY main exercise is distance/time based (a run/row/timed
    circuit / yoga flow) — padding it with strength accessories makes no sense."""
    if not exercises:
        return False
    kinds = {_tracking_type(e) for e in exercises}
    return kinds.issubset({TRACK_DISTANCE, TRACK_TIME})


def _is_exempt_session(workout: Dict[str, Any]) -> bool:
    """Genuinely-short / non-strength sessions are exempt from the floor."""
    name = (workout.get("workout_name") or workout.get("name") or "").lower()
    wtype = (workout.get("type") or workout.get("workout_type") or "").lower()
    try:
        dur = int(workout.get("duration_minutes") or 0)
    except (TypeError, ValueError):
        dur = 0
    if wtype in _EXEMPT_TYPE_TOKENS:
        return True
    if any(tok in name for tok in _EXEMPT_NAME_TOKENS):
        return True
    if dur and dur <= 10:                       # express / quick-hit
        return True
    return _is_conditioning_session(workout.get("exercises") or [])


def _derive_focus(workout: Dict[str, Any]) -> List[str]:
    """focus_areas for fetch_safe_candidates: session name first, else the
    dominant muscle group of the existing exercises, else full_body."""
    name = (workout.get("workout_name") or workout.get("name") or "").lower()
    for token, focus in _NAME_FOCUS_RULES:
        if token in name:
            return focus
    # Aggregate the existing exercises' muscles into a dominant focus.
    counts: Dict[str, int] = {}
    for e in workout.get("exercises") or []:
        blob = f"{e.get('primary_muscle','')} {e.get('body_part','')}".lower()
        for needles, focus in _MUSCLE_FOCUS_RULES:
            if any(n in blob for n in needles):
                counts[focus] = counts.get(focus, 0) + 1
                break
    if counts:
        return [max(counts, key=counts.get)]
    return ["full_body"]


def _rep_based_template(exercises: List[Dict[str, Any]]) -> Dict[str, Any]:
    """A sibling exercise whose sets/reps/rest we copy onto additions — chosen
    REP-based (skip distance/timed siblings so we never copy a '1000 m' spec).
    Falls back to a sane default when no rep-based sibling exists."""
    for e in exercises:
        if _tracking_type(e) in (TRACK_DISTANCE, TRACK_TIME):
            continue
        if e.get("sets"):
            return e
    return {"sets": 3, "reps": 10, "rest_seconds": 60, "difficulty": "intermediate"}


def _build_session_exercise(
    cand: Dict[str, Any], template: Dict[str, Any], workout: Dict[str, Any]
) -> Dict[str, Any]:
    """Emit the GENERATION-schema session-exercise shape (NOT exercises_json).
    Inherits sets/reps/rest from the same-week template so it tracks the week's
    periodized volume + deload."""
    return {
        "name": cand.get("name"),
        "exercise_id": str(cand["exercise_id"]) if cand.get("exercise_id") else None,
        "sets": int(template.get("sets") or 3),
        "reps": template.get("reps") if template.get("reps") not in (None, "") else 10,
        "rest_seconds": int(template.get("rest_seconds") or 60),
        "weight_guidance": "Moderate — leave 1-2 reps in reserve",
        "equipment": cand.get("equipment") or "",
        "body_part": cand.get("body_part") or "",
        "primary_muscle": cand.get("target_muscle") or "",
        "secondary_muscles": None,
        "difficulty": cand.get("safety_difficulty") or template.get("difficulty") or "intermediate",
        "substitution": None,
        "set_type": "normal",
        "superset_group": None,          # never auto-join an existing superset
        "backfilled": True,              # audit marker — see module docstring inv. 7
    }


async def _default_fetch(
    *, injuries, focus_areas, equipment, difficulty_ceiling, k, **_ignored
) -> List[Dict[str, Any]]:
    # Coarse safety pool — used by the generator's pre-ingest safety net. The
    # backfill passes a higher-quality curated fetcher (junk-filtered + diverse).
    from services.exercise_rag.service import fetch_safe_candidates
    return await fetch_safe_candidates(
        injuries=injuries,
        focus_areas=focus_areas,
        equipment=equipment,
        difficulty_ceiling=difficulty_ceiling,
        k=k,
    )


CandidateFetcher = Callable[..., Awaitable[List[Dict[str, Any]]]]


async def fill_thin_sessions(
    workouts: List[Dict[str, Any]],
    *,
    equipment: List[str],
    difficulty_ceiling: str = "intermediate",
    program_name: Optional[str] = None,
    injuries: Optional[List[str]] = None,
    dry_run: bool = False,
    candidate_fetcher: Optional[CandidateFetcher] = None,
) -> Dict[str, Any]:
    """Top up every thin, non-exempt session in one week's ``workouts`` array to
    its duration-scaled floor. Mutates the session dicts in place (also returns
    them). See the module docstring for the full set of invariants.

    Returns ``{"workouts": [...], "added": [{session, name, exercise_id}, ...]}``.
    ``dry_run`` plans additions and reports them but does NOT mutate ``workouts``.
    """
    fetch = candidate_fetcher or _default_fetch
    added: List[Dict[str, Any]] = []

    for workout in workouts or []:
        if not isinstance(workout, dict):
            continue
        if _is_exempt_session(workout):
            continue
        exercises = workout.get("exercises") or []
        # Defensive: a pure conditioning block can slip past name/type checks.
        if _is_conditioning_session(exercises):
            continue
        target = _session_target_exercises(workout)
        if len(exercises) >= target:
            continue                                  # IDEMPOTENT no-op
        need = target - len(exercises)

        focus = _derive_focus(workout)
        try:
            cands = await fetch(
                injuries=injuries or [],
                focus_areas=focus,
                equipment=equipment or [],
                difficulty_ceiling=difficulty_ceiling,
                k=need + 20,                           # headroom for dedupe/stretch-skip
                # Smart fetchers use the session to de-duplicate by BASE movement
                # (so an existing "Bench Press" blocks adding an incline variant)
                # and to diversify picks. The default fetcher ignores this.
                session=workout,
            )
        except Exception as e:  # never block the whole week on one fetch
            logger.warning(
                "fill_thin_sessions: candidate fetch failed for '%s' (%s): %s",
                workout.get("workout_name"), program_name, e,
            )
            continue

        present = {_norm(e.get("name")) for e in exercises}
        template = _rep_based_template(exercises)
        new_rows: List[Dict[str, Any]] = []
        for cand in cands:
            if len(new_rows) >= need:
                break
            cn = (cand.get("name") or "").strip()
            if not cn or _norm(cn) in present:
                continue
            if cand.get("is_stretch"):                 # never pad strength with a stretch
                continue
            present.add(_norm(cn))
            new_rows.append(_build_session_exercise(cand, template, workout))

        if not new_rows:
            continue
        if len(new_rows) < need:
            logger.warning(
                "fill_thin_sessions: '%s' (%s) only topped up %d/%d "
                "(candidate pool thin for focus=%s) — left as-is, never invented",
                workout.get("workout_name"), program_name, len(new_rows), need, focus,
            )

        for nr in new_rows:
            added.append({
                "session": workout.get("workout_name") or workout.get("name"),
                "name": nr["name"],
                "exercise_id": nr["exercise_id"],
            })
        if not dry_run:
            exercises.extend(new_rows)                 # append → straight sets, after existing
            workout["exercises"] = exercises

    return {"workouts": workouts, "added": added}
