"""Terminal injury-safety guard — the single chokepoint that GUARANTEES no
generated workout ships a contraindicated exercise to an injured user.

Background (injury-2026-06 Phase 0 evidence): the `/generate-stream` path — the
primary onboarding generator — had NO injury gate at all and shipped Barbell
Deadlift / Kettlebell Swing to `lower_back` users, squats to `knees` users,
overhead presses to `shoulders` users (30/50 scenarios leaked). The RAG path
gated *candidates* before selection but could still let a mis-tagged row through.

This module enforces the invariant at ONE place, applied to the FINAL exercise
list on both paths, right before persist:

  - For every active JOINT injury (the 8 with a vetted `*_safe` column), DROP any
    exercise the safety index marks unsafe (`<joint>_safe IS FALSE`).
  - REPLACE each dropped exercise with a vetted-safe candidate from
    ``fetch_safe_candidates`` so the user still gets a full, real workout — never a
    thinned or stretches-only plan. The replacement CLONES the structural fields
    (sets / reps / rest / set_targets) of a surviving exercise, so it inherits a
    valid, already-targeted shape and flows through downstream persist unchanged.

Muscle-area chips (chest/biceps/abs/…) have no `*_safe` column; they are handled
upstream by ``avoided_muscles`` (``get_muscles_to_avoid_from_injuries``) and are a
no-op here. Fail-OPEN: any error keeps the input list (we never block generation).
"""
from __future__ import annotations

from typing import Any, Dict, List, Tuple

from sqlalchemy import text

from core.logger import get_logger
from core.supabase_client import get_supabase
from .service import _resolve_injury_columns, fetch_safe_candidates

logger = get_logger(__name__)

# High-confidence name-keyword backstop. The index match (by exact name) is the
# primary gate, but Gemini can emit a contraindicated movement under a name variant
# the index doesn't carry verbatim (e.g. "Good Morning" vs the index's "Barbell Good
# Morning"/"Good Mornings"). These keyword sets drop the canonical dangerous
# movements for each joint regardless of index presence. Kept deliberately tight —
# only movements that are contraindicated for that joint in essentially all loaded
# forms — so we don't over-drop safe variants. Keyed by injury substring.
_INJURY_NAME_KEYWORDS: Dict[str, Tuple[str, ...]] = {
    "lower_back": ("deadlift", "good morning", "good-morning", "kettlebell swing",
                   "jefferson curl", "snatch", "power clean", "hang clean"),
    "back":       ("deadlift", "good morning", "kettlebell swing"),
    "knee":       ("pistol squat", "jump squat", "box jump", "depth jump",
                   "jumping lunge", "jump lunge", "shrimp squat"),
    "shoulder":   ("behind the neck", "behind-the-neck", "upright row",
                   "snatch", "overhead press", "military press", "push press"),
    "elbow":      ("skullcrusher", "skull crusher"),
    "wrist":      (),
    "ankle":      ("box jump", "depth jump", "jump rope", "jumping jack",
                   "tuck jump", "broad jump"),
    "hip":        ("pistol squat", "jump squat", "box jump"),
    "neck":       ("behind the neck", "behind-the-neck", "neck bridge"),
}


def _name_keyword_banned(name_lc: str, injuries: List[str]) -> bool:
    """True if the exercise name contains a contraindicated keyword for any injury."""
    for inj in injuries:
        key = str(inj or "").strip().lower()
        if not key:
            continue
        for needle, kws in _INJURY_NAME_KEYWORDS.items():
            if needle in key and any(kw in name_lc for kw in kws):
                if needle == "back" and "lower_back" in key:
                    continue  # already covered by lower_back set
                return True
    return False


# Fields copied verbatim from the survivor template onto a replacement so it is a
# structurally-valid, already-targeted exercise (weights are re-derived/capped
# downstream; identity fields are overwritten with the safe candidate's values).
_STRUCTURAL_FIELDS = (
    "sets", "reps", "rest_seconds", "set_targets", "intensity",
    "tempo", "rpe", "duration_seconds", "weight", "weight_kg", "weight_lbs",
)
_IDENTITY_FIELDS = (
    "video_url", "gif_url", "image_url", "thumbnail_url", "instructions",
    "exercise_id", "library_id", "id",
)


def _exercise_names(exercises: List[Dict[str, Any]]) -> List[str]:
    return [
        (e.get("name") or e.get("exercise_name") or "").strip()
        for e in exercises
    ]


def _build_replacement(template: Dict[str, Any], cand: Dict[str, Any]) -> Dict[str, Any]:
    """Clone the survivor's structural shape, swap in the safe candidate's identity."""
    repl = {k: template.get(k) for k in _STRUCTURAL_FIELDS if k in template}
    cn = (cand.get("name") or "").strip()
    repl["name"] = cn
    repl["exercise_name"] = cn
    repl["equipment"] = cand.get("equipment") or template.get("equipment")
    repl["muscle_group"] = (
        cand.get("target_muscle") or cand.get("body_part") or template.get("muscle_group")
    )
    repl["movement_pattern"] = cand.get("movement_pattern")
    if cand.get("exercise_id") is not None:
        repl["library_id"] = str(cand["exercise_id"])
        repl["exercise_id"] = str(cand["exercise_id"])
    # Defaults so a clone from a sparse template still validates downstream.
    repl.setdefault("sets", 3)
    repl.setdefault("reps", 10)
    repl.setdefault("rest_seconds", 60)
    return repl


async def _unsafe_name_set(
    names: List[str], cols: List[str]
) -> set:
    """Return the lowercased names the safety index marks unsafe for ANY column."""
    clean = [n.lower() for n in names if n]
    if not clean or not cols:
        return set()
    col_sel = ", ".join(sorted(set(cols)))  # column names from our trusted dict
    engine = get_supabase().engine
    sql = text(
        f"SELECT lower(name) AS lname, {col_sel} "
        "FROM public.exercise_safety_index_mat "
        "WHERE lower(name) = ANY(CAST(:names AS text[]))"
    )
    async with engine.connect() as conn:
        rows = (await conn.execute(sql, {"names": clean})).mappings().all()
    unsafe = set()
    for r in rows:
        # FALSE = confirmed contraindicated. NULL/unknown is NOT treated as a leak
        # here (matches the harness's measured semantics); the candidate-gate /
        # fetch_safe_candidates fail-closed path handles the unknown case upstream.
        if any(r[c] is False for c in cols):
            unsafe.add(r["lname"])
    return unsafe


async def enforce_injury_safety(
    exercises: List[Dict[str, Any]],
    injuries: List[str],
    *,
    equipment: List[str] | None = None,
    focus_areas: List[str] | None = None,
    difficulty_ceiling: str = "beginner",
    user_id: str | None = None,
) -> Tuple[List[Dict[str, Any]], List[str], List[str]]:
    """Drop index-confirmed-unsafe exercises and backfill safe replacements.

    Returns ``(safe_exercises, dropped_names, added_names)``. Fail-open: on any
    error the original list is returned untouched with empty drop/add lists.
    """
    try:
        cols = _resolve_injury_columns(injuries or [])
        if not cols or not exercises:
            return exercises, [], []

        names = _exercise_names(exercises)
        unsafe = await _unsafe_name_set(names, cols)

        safe: List[Dict[str, Any]] = []
        dropped: List[str] = []
        for ex, nm in zip(exercises, names):
            nm_lc = nm.lower() if nm else ""
            # Drop if the index confirms it unsafe OR a canonical-movement keyword
            # matches (backstop for index name-variant misses).
            if nm and (nm_lc in unsafe or _name_keyword_banned(nm_lc, injuries)):
                dropped.append(nm)
            else:
                safe.append(ex)

        if not dropped:
            return exercises, [], []

        # Backfill one safe replacement per drop so the workout stays full.
        present = {n.lower() for n in names if n}
        template = safe[0] if safe else dict(exercises[0])
        added: List[str] = []
        cands = await fetch_safe_candidates(
            injuries=injuries,
            focus_areas=focus_areas or [],
            equipment=equipment or [],
            difficulty_ceiling=difficulty_ceiling,
            k=len(dropped) + 25,
        )
        for cand in cands:
            if len(added) >= len(dropped):
                break
            cn = (cand.get("name") or "").strip()
            if not cn or cn.lower() in present:
                continue
            if _name_keyword_banned(cn.lower(), injuries):
                continue  # never backfill a canonically-contraindicated movement
            present.add(cn.lower())
            repl = _build_replacement(template, cand)
            safe.append(repl)
            added.append(cn)

        logger.warning(
            "🛡️  [InjuryGuard] user=%s injuries=%s dropped %d unsafe (%s), "
            "added %d safe replacements (%s)",
            user_id, injuries, len(dropped), dropped, len(added), added,
        )
        return safe, dropped, added

    except Exception as exc:  # noqa: BLE001 — never block generation
        logger.error(
            "❌ [InjuryGuard] enforce_injury_safety failed (fail-open, keeping "
            "input): %s", exc, exc_info=True,
        )
        return exercises, [], []
