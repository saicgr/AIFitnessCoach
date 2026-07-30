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

Muscle-area chips (chest/biceps/abs/upper_back/…) have no `*_safe` column. They
used to be a NO-OP here — `/generate-stream` computed `injury_context
["avoided_muscles"]` and then discarded it, so an `Abs` or `Quads` limitation
only ever reached the Gemini prompt (E2E register row 86). They are now enforced
deterministically in this same pass: any exercise whose PRIMARY target matches an
avoided-muscle token derived (via the app's own `INJURY_TO_AVOIDED_MUSCLES` /
`BODY_MAP_MUSCLE_NORMALIZATION` maps — no new enumeration, no LLM) from a
NON-joint limitation is dropped and backfilled like any other violation.

Public surface — every workout-producing path funnels through one of these:
  - ``enforce_injury_safety``    — whole-list terminal gate (generate / regenerate
                                   / quick / variant-swap).
  - ``filter_injury_unsafe``     — same rules over a CANDIDATE list, for anything
                                   appended after the list gate (equipment
                                   finishers) so the gate stays genuinely terminal.
  - ``screen_exercise_for_injury`` — single-exercise verdict, for swap surfaces
                                   where the user picks the replacement.
  - ``resolve_user_chosen_exercise`` — the ONLY library lookup the user-driven
                                   swap/add surfaces may use. It resolves AND
                                   screens in one call, with ``injuries`` a
                                   REQUIRED keyword-only argument, so a call site
                                   physically cannot obtain a replacement row
                                   without the screen having run (register row 88;
                                   same "make it structurally unavoidable" shape
                                   as row 84's ``ensure_requested_equipment_represented``).

Fail-OPEN: any error keeps the input list (we never block generation).
"""
from __future__ import annotations

import re
from typing import Any, Dict, List, Optional, Sequence, Tuple

from sqlalchemy import text

from core.logger import get_logger
from core.supabase_client import get_supabase
from services.workout_safety_validator import (
    canonicalize_injury_token,
    canonicalize_injury_tokens,
)
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

# Primary-target backstop. The name/index gates above catch exercises BY NAME, but a
# movement whose PRIMARY target IS the injured region (e.g. a back extension /
# hyperextension / superman tagged lower_back_safe=TRUE, or a neck curl) directly
# loads the injured area and should never reach an injured user — even when the index
# marks it "safe" and its name carries no banned keyword. Matched ONLY against the
# exercise's PRIMARY target fields (target_muscle / muscle_group / body_part), NEVER
# secondary muscles: secondary involvement (e.g. erectors as a stabilizer in a leg
# press) is a normal part of compound work and is handled by `avoided_muscles`
# down-ranking upstream — matching it here would over-drop nearly every loaded lift.
# Kept deliberately tight + region-specific so it never false-positives on leg/upper
# work. Keyed by injury substring (same needle-matching as the name keywords).
_INJURY_TARGET_MUSCLE_KEYWORDS: Dict[str, Tuple[str, ...]] = {
    "lower_back": ("lower back", "erector spinae", "erector", "spinae", "lumbar"),
    "neck":       ("neck", "sternocleidomastoid", "cervical"),
}


_WORD_SPLIT_RE = re.compile(r"[^a-z0-9]+")


def _words(value: str) -> List[str]:
    return [w for w in _WORD_SPLIT_RE.split(value.strip().lower()) if w]


def _injury_key_covers(key: str, needle: str) -> bool:
    """Does injury token ``key`` name the region ``needle``?

    WORD-SEQUENCE matching, not a raw substring scan. Both keyword tables above
    are keyed by a region needle (``knee``, ``lower_back``) and the injury token
    can be a canonical id (``knee``), a plural app id already canonicalized
    (``knees`` -> ``knee``), or free text a user typed (``left knee``, ``knee
    pain``) that the canonicalizer leaves alone. A bare ``needle in key`` test
    both OVER-matches (``back`` fires on ``backache``; ``hip`` on ``whiplash``)
    and reads as an accident. Matching whole words keeps every legitimate hit —
    ``left knee`` -> ``knee``, ``lower_back`` -> ``lower_back`` — and drops the
    accidental ones.
    """
    key_words = _words(key)
    needle_words = _words(needle)
    if not key_words or not needle_words:
        return False
    span = len(needle_words)
    return any(
        key_words[i:i + span] == needle_words
        for i in range(len(key_words) - span + 1)
    )


def resolve_avoided_muscle_tokens(injuries: Sequence[Any]) -> List[str]:
    """Muscle-name tokens to hard-avoid, derived ONLY from non-joint limitations.

    Row 86. The 11 muscle-area chips (Abs, Chest, Biceps, Triceps, Forearms,
    Upper Back, Glutes, Groin, Quads, Hamstrings, Calves) have no ``*_safe``
    column, so the index gate above can never see them. Their meaning is already
    defined deterministically by the app's own maps
    (``INJURY_TO_AVOIDED_MUSCLES`` / ``BODY_MAP_MUSCLE_NORMALIZATION`` in
    ``api.v1.workouts.readiness_utils``) — reused verbatim here so there is ONE
    table, not a second copy that can drift.

    JOINT entries are deliberately EXCLUDED: a knee injury maps to
    quads/hams/calves/glutes, and hard-dropping all of those would delete every
    leg exercise instead of the contraindicated ones. Joints are governed by the
    vetted ``<joint>_safe`` columns; only the muscle-area chips fall through to
    muscle matching.
    """
    tokens: List[str] = []
    seen: set = set()
    try:
        # Lazy import: the maps live with the injury/limitation reader. Imported
        # here (not at module scope) to keep the services→api edge off the
        # import graph at startup.
        from api.v1.workouts.readiness_utils import get_muscles_to_avoid_from_injuries
    except Exception as exc:  # noqa: BLE001 — fail-open, joints still enforced
        logger.error("❌ [InjuryGuard] muscle-map import failed: %s", exc)
        return []

    for key in canonicalize_injury_tokens(injuries):
        if _resolve_injury_columns([key]):
            continue  # a real joint — handled by the <joint>_safe index gate
        for muscle in get_muscles_to_avoid_from_injuries([key]) or []:
            tok = str(muscle or "").strip().lower()
            if tok and tok not in seen:
                seen.add(tok)
                tokens.append(tok)
    return tokens


def _muscle_terms(value: Any) -> Tuple[List[str], List[str]]:
    """Split ONE primary-target field into (group terms, anatomical terms).

    The library writes `target_muscle` as ``Group (Anatomy, Anatomy), Group2
    (Anatomy)`` — e.g. ``"Hamstrings (Biceps Femoris, Semitendinosus,
    Semimembranosus), Glutes (Gluteus Maximus)"``. The GROUP is the muscle the
    exercise actually trains; the parenthesised names are the individual heads
    that make it up. `body_part` / `muscle_group` carry a bare group
    (``"upper legs"``, ``"quadriceps"``), which parses as a group term with no
    anatomy.

    Commas inside parentheses do NOT separate groups, so the top-level split is
    depth-aware.
    """
    raw = str(value or "").strip().lower()
    if not raw:
        return [], []
    groups: List[str] = []
    anatomy: List[str] = []
    buf: List[str] = []
    depth = 0
    chunks: List[str] = []
    for ch in raw:
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth = max(0, depth - 1)
        if ch == "," and depth == 0:
            chunks.append("".join(buf))
            buf = []
        else:
            buf.append(ch)
    chunks.append("".join(buf))
    for chunk in chunks:
        chunk = chunk.strip()
        if not chunk:
            continue
        head, sep, tail = chunk.partition("(")
        head = head.strip()
        if head:
            groups.append(head)
        if sep:
            for part in tail.rstrip(") ").split(","):
                part = part.strip().strip(")").strip()
                if part:
                    anatomy.append(part)
    return groups, anatomy


def _targets_avoided_muscle(item: Dict[str, Any], muscle_tokens: Sequence[str]) -> bool:
    """True if the exercise's PRIMARY target matches an avoided-muscle token.

    Primary fields only (same rationale as `_targets_injured_region`): secondary
    involvement is normal in compound work and is handled by down-ranking
    upstream — matching it here would over-drop nearly every loaded lift.

    Matching is STRUCTURE-AWARE, not a substring scan of the whole field. A flat
    ``tok in blob`` test made the `biceps` chip drop every hamstring movement,
    because the hamstring group is spelled ``"Hamstrings (Biceps Femoris, …)"``
    and *biceps femoris* is a hamstring head, not the biceps brachii — 214 of the
    413 library rows containing "biceps" are hamstring rows. So:

      * a token matches a GROUP term by substring (``"legs"`` ⊂ ``"upper legs"``,
        ``"biceps"`` ⊂ ``"biceps"``), because group names are the coarse label
        the avoided-muscle vocabulary is written in; and
      * a token matches an ANATOMY term only when it is that term in FULL
        (``"latissimus dorsi"`` == ``"latissimus dorsi"`` drops lat work for an
        upper-back limitation, while ``"biceps"`` != ``"biceps femoris"`` leaves
        hamstring work alone).
    """
    if not muscle_tokens:
        return False
    groups: List[str] = []
    anatomy: List[str] = []
    for key in ("target_muscle", "muscle_group", "body_part"):
        g, a = _muscle_terms(item.get(key))
        groups.extend(g)
        anatomy.extend(a)
    if not groups and not anatomy:
        return False
    anatomy_set = set(anatomy)
    for tok in muscle_tokens:
        if tok in anatomy_set:
            return True
        if any(tok in grp for grp in groups):
            return True
    return False


def _looks_like_stretch(cand: Dict[str, Any]) -> bool:
    """Heuristic: is this candidate a stretch/mobility move (not real loaded work)?"""
    blob = " ".join(str(cand.get(k) or "") for k in ("name", "movement_pattern",
                                                      "target_muscle", "body_part")).lower()
    return "stretch" in blob or "mobility" in blob


def _name_keyword_banned(name_lc: str, injuries: List[str]) -> bool:
    """True if the exercise name contains a contraindicated keyword for any injury."""
    for inj in injuries:
        # Canonicalize FIRST: callers pass the raw stored ids, which are PLURAL
        # ("knees", "ankles"). Word matching against the singular needles only
        # works once they have been collapsed onto the canonical spelling.
        key = canonicalize_injury_token(inj)
        if not key:
            continue
        for needle, kws in _INJURY_NAME_KEYWORDS.items():
            if _injury_key_covers(key, needle) and any(kw in name_lc for kw in kws):
                if needle == "back" and _injury_key_covers(key, "lower_back"):
                    continue  # already covered by lower_back set
                return True
    return False


def _primary_target_blob(item: Dict[str, Any]) -> str:
    """Lowercased blob of an exercise's PRIMARY target fields only.

    Deliberately excludes `secondary_muscles` — secondary involvement is normal in
    compound work and is governed by `avoided_muscles` down-ranking upstream.
    """
    return " ".join(
        str(item.get(k) or "")
        for k in ("target_muscle", "muscle_group", "body_part")
    ).lower()


def _targets_injured_region(item: Dict[str, Any], injuries: List[str]) -> bool:
    """True if the exercise's PRIMARY target is the injured region itself.

    Backstop for index rows mistakenly tagged ``<joint>_safe=TRUE`` even though the
    movement directly loads the injured area (e.g. a back extension for a lower_back
    user). Tight + region-specific so leg/upper work never false-positives.
    """
    blob = _primary_target_blob(item)
    if not blob.strip():
        return False
    for inj in injuries:
        key = canonicalize_injury_token(inj)  # plural app ids -> singular needles
        if not key:
            continue
        for needle, kws in _INJURY_TARGET_MUSCLE_KEYWORDS.items():
            if _injury_key_covers(key, needle) and any(kw in blob for kw in kws):
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


def _inherit_field(templates: Sequence[Dict[str, Any]], field: str) -> Any:
    """First non-None value of ``field`` across the donor exercises, else None."""
    for t in templates:
        if isinstance(t, dict):
            v = t.get(field)
            if v is not None:
                return v
    return None


def _build_replacement(
    templates: Sequence[Dict[str, Any]], cand: Dict[str, Any]
) -> Dict[str, Any]:
    """Clone the workout's own structural shape, swap in the safe candidate's identity.

    Structural fields (sets / reps / rest / set_targets / …) are INHERITED from
    the workout's other exercises — survivors first, then the dropped originals,
    which are unsafe in identity but perfectly good as a shape donor. There are
    deliberately NO invented defaults: a hardcoded ``sets=3, reps=10,
    rest=60`` in a safety path silently re-prescribes the user's dose, and in a
    duration-only session (intervals, circuits, mobility) it fabricates a set
    scheme that never existed. If no exercise in the whole workout carries a
    field, the replacement doesn't carry it either and downstream normalization
    handles it exactly as it already handles the originals.
    """
    donors = [t for t in templates if isinstance(t, dict)]
    repl: Dict[str, Any] = {}
    for key in _STRUCTURAL_FIELDS:
        value = _inherit_field(donors, key)
        if value is not None:
            repl[key] = value
    cn = (cand.get("name") or "").strip()
    repl["name"] = cn
    repl["exercise_name"] = cn
    repl["equipment"] = cand.get("equipment") or _inherit_field(donors, "equipment")
    repl["muscle_group"] = (
        cand.get("target_muscle")
        or cand.get("body_part")
        or _inherit_field(donors, "muscle_group")
    )
    repl["movement_pattern"] = cand.get("movement_pattern")
    if cand.get("exercise_id") is not None:
        repl["library_id"] = str(cand["exercise_id"])
        repl["exercise_id"] = str(cand["exercise_id"])
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


def _violation_reason(
    item: Dict[str, Any],
    name_lc: str,
    unsafe_names: set,
    injuries: Sequence[Any],
    muscle_tokens: Sequence[str],
) -> Optional[str]:
    """The ONE rule set. Returns a short reason string, or None when the
    exercise is acceptable for this user's injuries/limitations."""
    if name_lc and name_lc in unsafe_names:
        return "safety_index"
    if name_lc and _name_keyword_banned(name_lc, list(injuries)):
        return "contraindicated_movement"
    if _targets_injured_region(item, list(injuries)):
        return "primary_target_is_injured_region"
    if _targets_avoided_muscle(item, muscle_tokens):
        return "primary_target_is_avoided_muscle"
    return None


async def screen_exercise_for_injury(
    exercise: Dict[str, Any],
    injuries: List[str],
) -> Optional[str]:
    """Single-exercise verdict for the SWAP surfaces (register row 88).

    ``/workouts/swap-exercise`` and ``/workouts/preview/swap-exercise`` let the
    user name the replacement, so there is no candidate list to filter — but a
    knee-injured user must still not be handed a Barbell Front Squat
    (``knee_safe = FALSE``). Returns a reason string when the exercise is
    contraindicated, else ``None``. Fail-OPEN (returns None) on any error.
    """
    try:
        if not exercise or not injuries:
            return None
        cols = _resolve_injury_columns(injuries)
        muscle_tokens = resolve_avoided_muscle_tokens(injuries)
        if not cols and not muscle_tokens:
            return None
        name = (exercise.get("name") or exercise.get("exercise_name") or "").strip()
        name_lc = name.lower()
        unsafe = await _unsafe_name_set([name], cols) if (name and cols) else set()
        return _violation_reason(exercise, name_lc, unsafe, injuries, muscle_tokens)
    except Exception as exc:  # noqa: BLE001 — never block a swap
        logger.error(
            "❌ [InjuryGuard] screen_exercise_for_injury failed (fail-open): %s",
            exc, exc_info=True,
        )
        return None


class InjuryUnsafeExerciseError(RuntimeError):
    """A user-picked exercise is contraindicated for that user's active injuries.

    Raised by :func:`resolve_user_chosen_exercise`. The swap/add endpoints turn
    it into a 409 the client can explain — we never silently substitute a
    different exercise for the one the user asked for, and we never persist the
    unsafe one.
    """

    def __init__(self, exercise_name: str, reason: str, injuries: Sequence[Any]):
        self.exercise_name = exercise_name
        self.reason = reason
        self.injuries = [str(i) for i in (injuries or []) if i]
        super().__init__(
            f"{exercise_name!r} is contraindicated ({reason}) for injuries "
            f"{self.injuries}"
        )


def _lookup_library_exercise(
    exercise_name: str, exercise_id: Optional[str] = None
) -> Optional[Dict[str, Any]]:
    """Resolve one exercise by id or name across both library stores.

    Private on purpose: the user-driven surfaces must go through
    :func:`resolve_user_chosen_exercise`, which cannot be called without the
    injury screen. This is the single copy of what used to be duplicated in
    ``api/v1/workouts/exercises.py`` and ``api/v1/workouts/workout_operations.py``.
    """
    from services.exercise_library_service import get_exercise_library_service

    lib = get_exercise_library_service()
    if exercise_id:
        found = lib.get_exercise_by_id(exercise_id)
        if found:
            return found
    results = lib.search_exercises(exercise_name, limit=1)
    if results:
        return results[0]

    try:
        from core.db import get_supabase_db

        cleaned = (
            get_supabase_db()
            .client.table("exercise_library_cleaned")
            .select(
                "id, name, target_muscle, body_part, equipment, gif_url, "
                "video_url, secondary_muscles, instructions"
            )
            .ilike("name", exercise_name)
            .limit(1)
            .execute()
        )
        if cleaned.data:
            row = cleaned.data[0]
            return {
                **row,
                "name": row.get("name", exercise_name),
                "muscle_group": row.get("target_muscle") or row.get("body_part", ""),
            }
    except Exception as exc:  # noqa: BLE001 — lookup miss is not a failure
        logger.warning(
            "exercise_library_cleaned lookup failed for %r: %s",
            exercise_name, exc, exc_info=True,
        )
    return None


async def resolve_user_chosen_exercise(
    exercise_name: str,
    exercise_id: Optional[str] = None,
    *,
    injuries: Sequence[Any],
) -> Optional[Dict[str, Any]]:
    """Resolve a user-picked exercise AND screen it — register row 88.

    ``/workouts/swap-exercise``, ``/workouts/add-exercise`` and their preview
    twins let the USER name the exercise, so there is no candidate list for
    ``enforce_injury_safety`` to filter. They used to do a bare library lookup
    and write whatever came back, which is how a knee-injured user could be
    handed "Barbell Front Squat" (``knee_safe = FALSE`` in the live index).

    ``injuries`` is keyword-only and REQUIRED: a call site that forgets it gets a
    TypeError, not an unscreened exercise. Pass the user's resolved active
    injuries (``get_active_injuries_with_muscles``), never a literal.

    Returns the library row (or None when the library has no match — callers
    keep their existing bare-name behaviour, and the bare name is screened too).
    Raises :class:`InjuryUnsafeExerciseError` when the exercise is
    contraindicated. Fail-OPEN inside the screen itself: an infrastructure error
    never blocks a swap.
    """
    resolved = _lookup_library_exercise(exercise_name, exercise_id)
    # Screen what the user would actually get: the library row when we have one,
    # otherwise the bare name (still enough for the keyword backstop to fire).
    candidate: Dict[str, Any] = dict(resolved) if resolved else {}
    if not (candidate.get("name") or candidate.get("exercise_name")):
        candidate["name"] = exercise_name
    reason = await screen_exercise_for_injury(candidate, list(injuries or []))
    if reason:
        blocked = candidate.get("name") or exercise_name
        logger.warning(
            "🛡️  [InjuryGuard] blocked user-chosen '%s' (%s) for injuries=%s",
            blocked, reason, list(injuries or []),
        )
        raise InjuryUnsafeExerciseError(blocked, reason, injuries)
    return resolved


async def filter_injury_unsafe(
    candidates: List[Dict[str, Any]],
    injuries: List[str],
) -> Tuple[List[Dict[str, Any]], List[str]]:
    """Drop contraindicated entries from a candidate/appended list.

    Register row 84: the equipment "finisher" is appended AFTER the terminal
    guard has already run, with an avoid-set of JOINT names matched against
    exercise NAMES (a no-op) — so a knee-injured user who asks for the leg-press
    machine gets "Horizontal Leg Press" (``knee_safe = FALSE``) bolted onto an
    otherwise-clean workout. Anything appended after the list gate MUST come
    through here so the gate stays genuinely terminal.

    Returns ``(kept, dropped_names)``. Fail-OPEN: returns the input on error.
    """
    try:
        if not candidates or not injuries:
            return candidates, []
        cols = _resolve_injury_columns(injuries)
        muscle_tokens = resolve_avoided_muscle_tokens(injuries)
        if not cols and not muscle_tokens:
            return candidates, []
        names = _exercise_names(candidates)
        unsafe = await _unsafe_name_set(names, cols) if cols else set()
        kept: List[Dict[str, Any]] = []
        dropped: List[str] = []
        for item, nm in zip(candidates, names):
            reason = _violation_reason(
                item, nm.lower() if nm else "", unsafe, injuries, muscle_tokens
            )
            if reason:
                dropped.append(nm or "(unnamed)")
                logger.warning(
                    "🛡️  [InjuryGuard] blocked appended '%s' (%s) for injuries=%s",
                    nm, reason, injuries,
                )
            else:
                kept.append(item)
        return kept, dropped
    except Exception as exc:  # noqa: BLE001 — never block generation
        logger.error(
            "❌ [InjuryGuard] filter_injury_unsafe failed (fail-open): %s",
            exc, exc_info=True,
        )
        return candidates, []


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
        # Row 86: muscle-area limitations have no `*_safe` column but ARE
        # enforceable deterministically — resolve them here so the guard no
        # longer returns early (and silently) for an Abs/Quads-only selection.
        muscle_tokens = resolve_avoided_muscle_tokens(injuries or [])
        if (not cols and not muscle_tokens) or not exercises:
            return exercises, [], []

        names = _exercise_names(exercises)
        unsafe = await _unsafe_name_set(names, cols) if cols else set()

        safe: List[Dict[str, Any]] = []
        dropped: List[str] = []
        dropped_by_muscle: List[str] = []
        for ex, nm in zip(exercises, names):
            reason = _violation_reason(
                ex, nm.lower() if nm else "", unsafe, injuries or [], muscle_tokens
            )
            if reason:
                label = nm or "(unnamed)"
                dropped.append(label)
                if reason in (
                    "primary_target_is_injured_region",
                    "primary_target_is_avoided_muscle",
                ):
                    dropped_by_muscle.append(f"{label}[{reason}]")
            else:
                safe.append(ex)

        if not dropped:
            return exercises, [], []

        # Backfill one safe replacement per drop so the workout stays full.
        present = {n.lower() for n in names if n}
        # Shape donors: survivors first (they are the session's real prescription),
        # then the dropped originals — unsafe by identity, still valid as a shape.
        shape_donors: List[Dict[str, Any]] = [
            e for e in list(safe) + list(exercises) if isinstance(e, dict)
        ]
        added: List[str] = []
        cands = await fetch_safe_candidates(
            injuries=injuries,
            focus_areas=focus_areas or [],
            equipment=equipment or [],
            difficulty_ceiling=difficulty_ceiling,
            k=len(dropped) + 25,
        )
        # Two passes: REAL loaded movements first, stretches only if the real-safe
        # pool can't cover the drops. Prevents replacing a dropped squat with a hip
        # stretch when real safe options (glute bridges, machines) exist.
        for stretch_pass in (False, True):
            for cand in cands:
                if len(added) >= len(dropped):
                    break
                cn = (cand.get("name") or "").strip()
                if not cn or cn.lower() in present:
                    continue
                if _name_keyword_banned(cn.lower(), injuries):
                    continue  # never backfill a canonically-contraindicated movement
                if _targets_injured_region(cand, injuries):
                    continue  # never backfill a movement that loads the injured region
                if _targets_avoided_muscle(cand, muscle_tokens):
                    continue  # never backfill into an avoided muscle area (row 86)
                is_stretch = _looks_like_stretch(cand)
                if is_stretch and not stretch_pass:
                    continue  # defer stretches to the fallback pass
                present.add(cn.lower())
                repl = _build_replacement(shape_donors, cand)
                safe.append(repl)
                added.append(cn)
            if len(added) >= len(dropped):
                break

        logger.warning(
            "🛡️  [InjuryGuard] user=%s injuries=%s dropped %d unsafe (%s) "
            "[%d by primary-target: %s], added %d safe replacements (%s)",
            user_id, injuries, len(dropped), dropped,
            len(dropped_by_muscle), dropped_by_muscle, len(added), added,
        )
        return safe, dropped, added

    except Exception as exc:  # noqa: BLE001 — never block generation
        logger.error(
            "❌ [InjuryGuard] enforce_injury_safety failed (fail-open, keeping "
            "input): %s", exc, exc_info=True,
        )
        return exercises, [], []
