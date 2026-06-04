"""Deterministic muscle-balance + bodyweight-load helpers for exercise selection.

FEATURE 3A (bodyweight generation + progression). When a user has NO real equipment
(bodyweight-only) and asks for a full-body workout, the AI/ranker would happily return
"6 push variations" or stack core moves — there's no barbell to anchor a sensible
push/pull/legs split. These helpers guarantee a balanced bodyweight pick WITHOUT an LLM
or a DB round-trip (pure functions over the already-fetched candidate dicts).

This module also owns:
  * ``_muscles_for_candidate`` — MOVED here from ``service.py`` (and re-imported back)
    to break an import cycle: ``service.py`` imports this module, and this module needs
    the muscle-token extractor; defining it here lets both share one implementation.
  * ``bodyweight_proxy_load_kg`` — the bodyweight "load" proxy used everywhere a
    bodyweight set needs a kg number (PR detection, volume math, the composite strength
    score's relative-strength model). Movement-pattern fractions are cited inline.

``get_movement_pattern`` / ``MOVEMENT_PATTERNS`` live in ``filters.py`` — imported here.
"""

from __future__ import annotations

from typing import Any, Dict, List, Optional

from core.logger import get_logger

from .filters import (
    MOVEMENT_PATTERNS,  # noqa: F401 - re-exported / referenced for pattern names
    get_movement_pattern,
    parse_secondary_muscles,
)

logger = get_logger(__name__)


# ---------------------------------------------------------------------------
# Muscle-token extraction (moved from service.py to break the import cycle).
# ---------------------------------------------------------------------------

def _muscles_for_candidate(candidate: Dict[str, Any]) -> set:
    """Best-effort set of lowercased muscle tokens a candidate trains.

    Pulls from target_muscle, body_part, and parsed secondary_muscles so the
    score-freshness bias and excluded-muscle skip can match against the same
    muscle vocabulary used elsewhere in the pipeline.
    """
    out: set = set()
    tm = (candidate.get("target_muscle") or "").strip().lower()
    if tm:
        out.add(tm)
    bp = (candidate.get("body_part") or "").strip().lower()
    if bp:
        out.add(bp)
    try:
        for sm in parse_secondary_muscles(candidate.get("secondary_muscles")):
            name = (sm.get("muscle") if isinstance(sm, dict) else sm)
            if name:
                out.add(str(name).strip().lower())
    except Exception:  # noqa: BLE001 - secondary parsing must never break selection
        pass
    return out


# ---------------------------------------------------------------------------
# Bodyweight load proxy.
# ---------------------------------------------------------------------------
#
# A bodyweight rep moves some fraction of the lifter's mass. The fraction below maps
# the filters.py movement pattern → the share of bodyweight the working muscles must
# overcome. Values are biomechanics-literature approximations (system-mass fractions in
# the loaded phase), used ONLY as a relative proxy so bodyweight volume/PRs/strength are
# comparable across moves — not a force-plate measurement:
#
#   pull_vertical  1.00  — a strict pull-up lifts ~full bodyweight (lats/biceps).
#   push_horizontal 0.65 — a push-up loads ~64% bodyweight on the hands
#                          (Ebben et al., 2011, J. Strength Cond. Res.).
#   push_vertical  0.65  — pike/handstand-ish vertical push, similar partial load.
#   squat          0.60  — a bodyweight squat moves ~ trunk+thigh mass minus shanks.
#   lunge          0.60  — single-leg, similar moved mass to a squat.
#   hinge          0.50  — hip-hinge (glute bridge / back ext) loads the posterior chain
#                          with roughly half system mass.
#   core           0.50  — planks/leg-raises support/lift ~half the body.
#   default        0.60  — unknown pattern → mid squat-ish fraction.
_BW_FRACTION_BY_PATTERN: Dict[str, float] = {
    "pull_vertical": 1.00,
    "pull_horizontal": 0.65,   # inverted rows ~ similar to a horizontal push share
    "push_horizontal": 0.65,
    "push_vertical": 0.65,
    "squat": 0.60,
    "lunge": 0.60,
    "hinge": 0.50,
    "curl": 0.30,              # bodyweight biceps work is rare; small moved share
    "tricep": 0.35,
    "core_flexion": 0.50,
    "core_stability": 0.50,
}
_BW_FRACTION_DEFAULT = 0.60


def _bw_fraction_for_pattern(pattern: Optional[str]) -> float:
    """Map a filters.py movement pattern to a bodyweight load fraction.

    Collapses the finer-grained core patterns to the spec's ``core`` bucket (0.5).
    """
    if not pattern:
        return _BW_FRACTION_DEFAULT
    if pattern in ("core_flexion", "core_stability"):
        return 0.50
    return _BW_FRACTION_BY_PATTERN.get(pattern, _BW_FRACTION_DEFAULT)


def bodyweight_proxy_load_kg(exercise_name: str, user_bw_kg: float) -> float:
    """Proxy "load" in kg for one rep of a bodyweight exercise.

    ``= user_bw_kg * BW_FRACTION`` where BW_FRACTION is keyed on the exercise's
    movement pattern (see ``_BW_FRACTION_BY_PATTERN`` and the cited fractions above).
    Used by PR detection, volume math, and the strength composite so a bodyweight set
    contributes a sensible, monotonic load instead of 0.

    Returns 0.0 for a non-positive bodyweight (no silent fake fallback to 70kg here —
    callers pass a real bodyweight; a 0 proxy is honest "no load known").
    """
    if not user_bw_kg or user_bw_kg <= 0:
        return 0.0
    pattern = get_movement_pattern(exercise_name or "")
    fraction = _bw_fraction_for_pattern(pattern)
    return round(user_bw_kg * fraction, 1)


# ---------------------------------------------------------------------------
# Core-cap + balanced-window curation.
# ---------------------------------------------------------------------------

# A candidate's coverage group, derived from its movement pattern. "core" is capped;
# the other three (push/pull/legs) must each appear at least once in a full-body pick.
def _coverage_group(candidate: Dict[str, Any]) -> Optional[str]:
    """Classify a candidate into push / pull / legs / core (or None if unknown).

    Uses the candidate's NAME via filters.get_movement_pattern, with a muscle-token
    fallback so a row whose name doesn't match a pattern keyword (AI-named move) still
    buckets via its target/secondary muscles.
    """
    name = candidate.get("name") or candidate.get("exercise_name") or ""
    pattern = get_movement_pattern(name)
    if pattern:
        if pattern in ("push_horizontal", "push_vertical", "tricep"):
            return "push"
        if pattern in ("pull_vertical", "pull_horizontal", "curl"):
            return "pull"
        if pattern in ("squat", "lunge", "hinge"):
            return "legs"
        if pattern in ("core_flexion", "core_stability"):
            return "core"
    # Muscle-token fallback.
    muscles = _muscles_for_candidate(candidate)
    blob = " ".join(muscles)
    if any(k in blob for k in ("chest", "pec", "shoulder", "delt", "tricep")):
        return "push"
    if any(k in blob for k in ("back", "lat", "trap", "rhomboid", "bicep")):
        return "pull"
    if any(k in blob for k in (
        "quad", "hamstring", "glute", "calf", "leg", "thigh", "hip", "adductor", "abductor"
    )):
        return "legs"
    if any(k in blob for k in ("core", "abs", "abdomin", "oblique", "waist")):
        return "core"
    return None


def enforce_core_cap(exercises: List[Dict[str, Any]], cap: int = 2) -> List[Dict[str, Any]]:
    """Return ``exercises`` with at most ``cap`` core movements, preserving order.

    Core moves beyond the cap are dropped (the caller is expected to back-fill from a
    wider pool if it needs to keep the count). Non-core and unknown-group exercises are
    always kept. Deterministic; never raises.
    """
    if cap < 0 or not exercises:
        return list(exercises)
    kept: List[Dict[str, Any]] = []
    core_count = 0
    dropped = 0
    for ex in exercises:
        if _coverage_group(ex) == "core":
            if core_count >= cap:
                dropped += 1
                continue
            core_count += 1
        kept.append(ex)
    if dropped:
        logger.info("[MuscleBalance] enforce_core_cap dropped %d core move(s) over cap=%d", dropped, cap)
    return kept


# Groups that a full-body bodyweight pick must cover (when present in the pool).
_REQUIRED_FULL_BODY_GROUPS = ("push", "pull", "legs")


def balance_candidate_window(
    candidates: List[Dict[str, Any]],
    count: int,
    focus_area: Optional[str] = None,
    core_cap: int = 2,
) -> List[Dict[str, Any]]:
    """Reorder/curate a candidate window so a full-body bodyweight pick is balanced.

    Guarantees, within the first ``count`` returned candidates:
      * >= 1 push, >= 1 pull, >= 1 legs — but ONLY for groups that actually exist in the
        provided pool (a pool with no pull options can't be forced to include one).
      * core <= ``core_cap`` (default 2).

    The returned list is a re-ordering of the SAME candidate dicts (no new picks
    invented, no DB read) followed by the remaining candidates, so the caller's existing
    top-``count`` slice naturally lands a balanced set. Deterministic and stable: relative
    order within a group is preserved (i.e. the ranker's similarity order is respected).

    No-op (returns input unchanged) when:
      * the pool is empty, or
      * ``focus_area`` is a specific region (push/pull/legs/chest/etc.) — balancing only
        applies to full_body / unspecified, where there's no single anchor lift.
    """
    if not candidates:
        return candidates

    fa = (focus_area or "").strip().lower().replace(" ", "_")
    is_full_body = fa in ("", "full_body", "fullbody", "full")
    if not is_full_body:
        return candidates

    # Bucket candidates by coverage group, preserving incoming (similarity) order.
    buckets: Dict[str, List[Dict[str, Any]]] = {"push": [], "pull": [], "legs": [], "core": [], "other": []}
    for c in candidates:
        group = _coverage_group(c) or "other"
        buckets.setdefault(group, []).append(c)

    ordered: List[Dict[str, Any]] = []
    used_ids = set()

    def _take(group: str) -> bool:
        for c in buckets.get(group, []):
            cid = id(c)
            if cid in used_ids:
                continue
            used_ids.add(cid)
            ordered.append(c)
            return True
        return False

    # 1) Seed one of each required group that exists in the pool.
    for group in _REQUIRED_FULL_BODY_GROUPS:
        if buckets.get(group):
            _take(group)

    # 2) Round-robin the remaining slots across push/pull/legs (then other, then a
    #    capped amount of core) so the head of the list stays balanced, not push-heavy.
    core_in_head = 0
    rotation = ["push", "pull", "legs", "other"]
    rot_idx = 0
    # Cap how many we actively curate to a bit beyond `count` so the top-N slice is
    # balanced; the tail is appended verbatim afterward.
    target = max(count, len(_REQUIRED_FULL_BODY_GROUPS))
    safety = 0
    while len([x for x in ordered]) < target and safety < len(candidates) * 2:
        safety += 1
        progressed = False
        for _ in range(len(rotation)):
            group = rotation[rot_idx % len(rotation)]
            rot_idx += 1
            if _take(group):
                progressed = True
                break
        if not progressed:
            # No more push/pull/legs/other left — allow capped core to fill.
            if core_in_head < core_cap and _take("core"):
                core_in_head += 1
                progressed = True
        if not progressed:
            break

    # 3) Append every remaining candidate (any group) verbatim so the caller can still
    #    back-fill beyond the curated head; enforce the global core cap on the WHOLE list.
    for c in candidates:
        if id(c) not in used_ids:
            used_ids.add(id(c))
            ordered.append(c)

    balanced = enforce_core_cap(ordered, cap=core_cap)
    logger.info(
        "[MuscleBalance] balanced full-body window: groups present=%s, head core_cap=%d",
        {g: len(buckets.get(g, [])) for g in ("push", "pull", "legs", "core")},
        core_cap,
    )
    return balanced
