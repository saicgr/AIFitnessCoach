"""
Safety-Mode plan builder — Phase 2H (companion to workout_safety_validator).

When `workout_safety_validator.validate_and_repair` decides that a user's
injury load is too high for the generated plan (>= 50% violations, or the
safe candidate pool is empty), the caller hands off to this module to build
a deterministic, gentle PT-friendly session from the pre-computed
`exercise_safety_index`.

Guarantees
----------
- NEVER calls an LLM.
- Every exercise returned satisfies every one of the user's injury flags
  (`*_safe IS TRUE`), drawn from `movement_pattern IN ('mobility', 'isometric',
  'anti_rotation')`, with `safety_difficulty IN ('beginner','intermediate')`
  and `is_beginner_safe = TRUE`.
- Falls back to a static hardcoded seated-breathing routine only if the
  safe pool is literally empty — we still return SOMETHING so the UI isn't
  a blank page, but we tag the response so the frontend shows the PT
  disclaimer banner.

Ownership
---------
Exclusive owner: Phase 2H. Phase 3L calls this from versioning.py when
`ValidationResult.safety_mode_triggered` is True.
"""

from __future__ import annotations

import asyncio
from typing import Any, Dict, List, Optional, Sequence

from sqlalchemy import text

from core.logger import get_logger
from core.supabase_client import get_supabase
from services.workout_safety_validator import (
    SUPPORTED_INJURY_JOINTS,
    UserSafetyContext,
)

logger = get_logger(__name__)


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

# Maximum duration we ever schedule in safety mode, regardless of the user's
# requested duration. Rationale: an injured user asking for a 60-min session
# should still only get ~20 min of gentle mobility — anything longer risks
# re-injury from over-exertion.
MAX_SAFETY_MODE_MINUTES: int = 20

# Movement patterns considered inherently safe regardless of injury. These
# never load any joint in a way the reference taxonomy classifies as
# contraindicated, per the yaml `movement_patterns` block. This is the ONLY
# allow-list in the entire validator path.
SAFE_PATTERNS: tuple = ("mobility", "isometric", "anti_rotation")

# Conservative sets/reps defaults. 2 sets x 10 reps at 45s rest is
# intentionally below any strength dosage — think physical-therapy HEP,
# not a workout.
_DEFAULT_SETS: int = 2
_DEFAULT_REPS: int = 10
_DEFAULT_REST_SECONDS: int = 45
_DEFAULT_DURATION_SECONDS: int = 30  # for isometric holds

# The static last-resort fallback, if even the safe pool is empty. These
# are universal — seated breathing is contraindicated to no joint injury.
_LAST_RESORT_EXERCISES: List[Dict[str, Any]] = [
    {
        "exercise_id": None,
        "name": "Diaphragmatic Breathing",
        "body_part": "core",
        "equipment": "none",
        "movement_pattern": "isometric",
        "safety_difficulty": "beginner",
        "sets": 2,
        "reps": None,
        "duration_seconds": 60,
        "rest_seconds": 30,
        "instructions": "Sit tall. Place one hand on belly, one on chest. "
        "Inhale through the nose for 4s, letting the belly expand. "
        "Exhale through pursed lips for 6s. Chest stays still.",
    },
    {
        "exercise_id": None,
        "name": "Seated Cat-Cow (Gentle)",
        "body_part": "back",
        "equipment": "none",
        "movement_pattern": "mobility",
        "safety_difficulty": "beginner",
        "sets": 2,
        "reps": 8,
        "duration_seconds": None,
        "rest_seconds": 30,
        "instructions": "Seated upright. Alternate gently arching the upper "
        "back (cow) and rounding forward (cat). Movement is small; stay "
        "well within pain-free range.",
    },
    {
        "exercise_id": None,
        "name": "Ankle Circles",
        "body_part": "lower legs",
        "equipment": "none",
        "movement_pattern": "mobility",
        "safety_difficulty": "beginner",
        "sets": 2,
        "reps": 10,
        "duration_seconds": None,
        "rest_seconds": 20,
        "instructions": "Seated. Slowly rotate each ankle 10 times clockwise "
        "and 10 times counter-clockwise. No pain, no sudden movement.",
    },
    {
        "exercise_id": None,
        "name": "Chin Tuck",
        "body_part": "neck",
        "equipment": "none",
        "movement_pattern": "isometric",
        "safety_difficulty": "beginner",
        "sets": 2,
        "reps": 8,
        "duration_seconds": None,
        "rest_seconds": 30,
        "instructions": "Seated or standing with neutral spine. Gently draw "
        "the chin straight back (double-chin cue). Hold 5s. Do not tilt "
        "the head up or down.",
    },
]


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------


def _get_engine():
    return get_supabase().engine


def _build_injury_clause(injuries: Sequence[str]) -> str:
    """Same fail-closed semantics as the validator: NULL counts as UNSAFE."""
    if not injuries:
        return ""
    return " AND " + " AND ".join(f"{joint}_safe IS TRUE" for joint in injuries)


def _normalize_focus_areas(focus_areas: Optional[List[str]]) -> List[str]:
    """Lowercased, de-duped focus area tokens — matched against `body_part`."""
    if not focus_areas:
        return []
    out: List[str] = []
    seen: set = set()
    for fa in focus_areas:
        key = (fa or "").strip().lower()
        if key and key not in seen:
            seen.add(key)
            out.append(key)
    return out


def _shape_exercise(row: Dict[str, Any]) -> Dict[str, Any]:
    """
    Convert a safety-index row into the workout exercise payload shape used
    by the rest of the system. Conservative sets/reps are stamped in; the
    library's reps/duration are ignored because library metadata may be
    tuned for strength, not rehab.
    """
    pattern = (row.get("movement_pattern") or "").lower()
    is_hold = pattern == "isometric"
    return {
        "exercise_id": row.get("exercise_id"),
        "name": row.get("name"),
        "body_part": row.get("body_part"),
        "target_muscle": row.get("target_muscle"),
        "equipment": row.get("equipment") or "none",
        "movement_pattern": row.get("movement_pattern"),
        "safety_difficulty": row.get("safety_difficulty"),
        "gif_url": row.get("gif_url"),
        "video_url": row.get("video_url"),
        "image_url": row.get("image_url"),
        "instructions": row.get("instructions"),
        "sets": _DEFAULT_SETS,
        "reps": None if is_hold else _DEFAULT_REPS,
        "duration_seconds": _DEFAULT_DURATION_SECONDS if is_hold else None,
        "rest_seconds": _DEFAULT_REST_SECONDS,
    }


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------


async def build_plan(
    ctx: UserSafetyContext,
    duration_minutes: int,
    focus_areas: Optional[List[str]] = None,
    supabase_client=None,  # Unused; kept for signature parity with the plan.
) -> Dict[str, Any]:
    """
    Build the gentle PT-friendly session.

    Returns a workout dict matching the schema used by regular generation:
      {
        "name": "Gentle Mobility Session",
        "difficulty": "beginner",
        "duration_minutes": <int, <= MAX_SAFETY_MODE_MINUTES>,
        "exercises": [ ... ],
        "safety_mode": True,
        "notice": "...",
        "focus_areas": [...],
      }

    Algorithm:
      1. SQL SELECT from `exercise_safety_index` WHERE:
         - movement_pattern IN SAFE_PATTERNS
         - safety_difficulty IN ('beginner','intermediate')
         - is_beginner_safe IS TRUE
         - every injury flag the user needs is TRUE
         - is_tagged IS TRUE  (never trust an un-tagged row)
      2. If focus_areas provided, prefer rows whose `body_part` matches.
      3. Pick 4-6 exercises, weighting toward focus_areas but always
         including at least one mobility row so the session isn't all holds.
      4. If the query returns zero rows, return the static fallback list.
    """
    injuries = ctx.normalized_injuries()
    fa = _normalize_focus_areas(focus_areas)

    # Cap the requested duration. The user's preference is honored only
    # downward — a 60-min request still becomes 20 minutes in safety mode.
    capped = min(
        int(duration_minutes) if duration_minutes and duration_minutes > 0 else MAX_SAFETY_MODE_MINUTES,
        MAX_SAFETY_MODE_MINUTES,
    )

    injury_clause = _build_injury_clause(injuries)

    # When the user supplies focus_areas, we use a preference-ordering trick:
    # score each row 1 if its body_part matches, 0 otherwise, and ORDER BY
    # that score DESC. This prefers focus matches without hard-excluding the
    # rest (which keeps the pool large enough for 4-6 picks).
    fa_score_expr = "0"
    params: Dict[str, Any] = {"safe_patterns": list(SAFE_PATTERNS)}
    if fa:
        # Use CAST(... AS text[]) rather than `::text[]` — SQLAlchemy's named-
        # bindparam parser treats `:fa::text[]` as an ambiguous double-colon.
        fa_score_expr = (
            "CASE WHEN EXISTS ("
            "  SELECT 1 FROM unnest(CAST(:fa AS text[])) AS f(val) "
            "  WHERE lower(body_part) = f.val OR body_part ILIKE '%' || f.val || '%'"
            ") THEN 1 ELSE 0 END"
        )
        params["fa"] = fa

    sql = f"""
        SELECT
            exercise_id,
            name,
            name_normalized,
            body_part,
            target_muscle,
            equipment,
            movement_pattern,
            safety_difficulty,
            is_beginner_safe,
            gif_url,
            video_url,
            image_url,
            instructions,
            {fa_score_expr} AS fa_score
        FROM public.exercise_safety_index
        WHERE is_tagged IS TRUE
          AND is_beginner_safe IS TRUE
          AND movement_pattern = ANY(:safe_patterns)
          AND lower(safety_difficulty) IN ('beginner', 'intermediate')
          {injury_clause}
        ORDER BY fa_score DESC, safety_difficulty ASC, random()
        LIMIT 30
    """

    engine = _get_engine()
    rows: List[Dict[str, Any]] = []
    try:
        async with engine.connect() as conn:
            res = await conn.execute(text(sql), params)
            for r in res.fetchall():
                rows.append({k: v for k, v in r._mapping.items()})
    except Exception as e:
        logger.error(
            "❌ [SafetyMode] query failed user=%s: %s", ctx.user_id, e
        )
        rows = []

    picks: List[Dict[str, Any]]
    if not rows:
        logger.warning(
            "⚠️  [SafetyMode] empty safe pool — returning static fallback "
            "(user=%s injuries=%s)",
            ctx.user_id,
            injuries,
        )
        picks = list(_LAST_RESORT_EXERCISES)
    else:
        # Choose 4-6 exercises. Ensure at least one mobility and, where
        # possible, one isometric core/anti-rotation so the session has
        # both mobility and gentle activation.
        picks = []
        seen_ids: set = set()

        def _add(row: Dict[str, Any]) -> None:
            key = row.get("exercise_id") or row.get("name")
            if key in seen_ids:
                return
            seen_ids.add(key)
            picks.append(_shape_exercise(row))

        mobility = [r for r in rows if (r.get("movement_pattern") or "").lower() == "mobility"]
        isometric = [r for r in rows if (r.get("movement_pattern") or "").lower() == "isometric"]
        anti_rot = [r for r in rows if (r.get("movement_pattern") or "").lower() == "anti_rotation"]

        # Seed with one of each category when available.
        if mobility:
            _add(mobility[0])
        if isometric:
            _add(isometric[0])
        if anti_rot:
            _add(anti_rot[0])

        # Fill up to 6 total from the ranked pool (fa_score-first).
        target_count = 6 if capped >= 15 else 4
        for r in rows:
            if len(picks) >= target_count:
                break
            _add(r)

        # If we somehow still have 0 (shouldn't happen — rows was non-empty),
        # fall back to the static list.
        if not picks:
            picks = list(_LAST_RESORT_EXERCISES)

    plan = {
        "name": "Gentle Mobility Session",
        "difficulty": "beginner",
        "duration_minutes": capped,
        "exercises": picks,
        "safety_mode": True,
        "focus_areas": fa,
        "notice": (
            "With the injuries you've selected, we recommend consulting a "
            "physical therapist before training. This is a gentle mobility "
            "session designed to be safe for your selected injuries."
        ),
        "injuries_applied": injuries,
    }

    logger.info(
        "🛡️  [SafetyMode] built plan user=%s injuries=%s picks=%d duration=%dmin",
        ctx.user_id,
        injuries,
        len(picks),
        capped,
    )
    return plan


# ---------------------------------------------------------------------------
# Smoke test — run directly:  python -m services.exercise_rag.safety_mode
# ---------------------------------------------------------------------------


async def _smoke() -> None:
    ctx = UserSafetyContext(
        injuries=list(SUPPORTED_INJURY_JOINTS),
        difficulty="beginner",
        equipment=["bodyweight"],
        user_id="smoke-safety-mode",
    )
    plan = await build_plan(ctx, duration_minutes=15, focus_areas=["core", "back"])
    print("🛡️  [SafetyMode Smoke] plan:")
    print(f"  name={plan['name']} duration={plan['duration_minutes']}min "
          f"safety_mode={plan['safety_mode']} picks={len(plan['exercises'])}")
    for ex in plan["exercises"]:
        print(
            f"    - {ex['name']} ({ex.get('movement_pattern')}, "
            f"{ex.get('safety_difficulty')}) sets={ex.get('sets')} reps={ex.get('reps')}"
        )
    print(f"  notice: {plan['notice'][:80]}...")


if __name__ == "__main__":  # pragma: no cover
    asyncio.run(_smoke())
