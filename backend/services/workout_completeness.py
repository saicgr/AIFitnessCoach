"""Terminal completeness stage — the guarantee that a generated workout is never
shipped *thin* (the "1 exercise, 60-min" bug).

Workout generation is a chain of subtractive filters (movement-pattern dedup,
bodyweight trim, equipment filter, focus-mismatch filter, …). Each can drop
exercises, and historically the only floor was "reject literally zero", so a
healthy 7-exercise RAG selection could collapse to 1 and still persist.

This stage runs ONCE, last, on every generation path. It treats the post-cascade
list as a candidate set and restores the workout up to its duration/type-derived
target by:

  1. backfilling from the **reserve** — exercises the *aesthetic* trims
     (variety / bodyweight) discarded, which are exactly the good gym moves we
     want back. Cheap (no I/O) and quality-preserving.
  2. if still short, backfilling from the RAG **broadening cascade**
     (`select_exercises_with_fallback`, which never returns < floor).

It re-applies only **safety** constraints to backfilled items (dedupe, injury,
hard-equipment, user-avoided) — never the variety trims that caused the collapse.

It returns a ``degraded_reason`` ONLY when the user's real candidate pool is
genuinely below the floor (niche equipment / injury-constrained / heavy
exclusions); otherwise it guarantees ≥ floor. The caller persists that reason +
``is_degraded`` (migration 2255) and is expected to FAIL OPEN: any exception here
must fall back to the pre-stage list, never block the workout.
"""

from __future__ import annotations

import os
from typing import Any, Dict, List, Optional, Tuple

from core.logger import get_logger

logger = get_logger(__name__)

# degraded_reason enum (mirrors migration 2255 comment)
REASON_TINY_EQUIPMENT = "tiny_equipment_pool"
REASON_INJURY = "injury_constrained"
REASON_NICHE_FOCUS = "niche_focus"
REASON_HEAVY_EXCLUSIONS = "heavy_exclusions"

_ON = {"on", "1", "true", "yes", "all", "enabled"}
_OFF = {"off", "0", "false", "no", "", "disabled"}


def completeness_enabled(user_id: Optional[str] = None) -> bool:
    """The completeness terminal stage is ON by default — no variable to set.

    It is safe-by-construction: a no-op (zero latency) when a workout already
    meets its target, and fail-open everywhere. The optional
    ``WORKOUT_COMPLETENESS_V2`` env var exists ONLY as an emergency kill switch
    / scoping override; it never needs to be set for normal operation:
      * unset (default) → enabled for everyone
      * "off" / "false" → disabled (legacy path), the kill switch
      * "on" / "true"   → enabled for everyone (explicit)
      * a comma-separated list of user_ids → enabled only for those users
    """
    val = os.getenv("WORKOUT_COMPLETENESS_V2", "on").strip().lower()
    if val in _ON:
        return True
    if val in _OFF:
        return False
    ids = {x.strip() for x in val.split(",") if x.strip()}
    return bool(user_id) and str(user_id).strip().lower() in ids


def _key(ex: Dict[str, Any]) -> str:
    """Canonical dedupe key for an exercise dict."""
    try:
        from services.exercise_rag.utils import canonicalize_exercise_name
        nm = ex.get("name") or ex.get("exercise_name") or ""
        canon = canonicalize_exercise_name(nm) or nm
    except Exception:  # noqa: BLE001
        canon = ex.get("name") or ex.get("exercise_name") or ""
    return (canon or "").strip().lower()


def _lib_key(ex: Dict[str, Any]) -> str:
    return (ex.get("library_id") or ex.get("exercise_id") or "").strip()


def distinct_count(exercises: List[Dict[str, Any]]) -> int:
    """Count distinct exercises the way persistence/display does (by name)."""
    seen = set()
    for ex in exercises or []:
        k = _key(ex)
        if k:
            seen.add(k)
    return len(seen)


def _is_equipment_ok(ex: Dict[str, Any], equipment: Optional[List[str]]) -> bool:
    """Hard-equipment compatibility — don't backfill a move the user can't do."""
    if not equipment:
        return True
    try:
        from services.exercise_rag.filters import filter_by_equipment
        from services.exercise_rag.utils import infer_equipment_from_name
        ex_equip = (ex.get("equipment") or "").strip()
        ex_name = ex.get("name") or ex.get("exercise_name") or ""
        if not ex_equip or ex_equip.lower() in ("bodyweight", "body weight", "none", ""):
            ex_equip = infer_equipment_from_name(ex_name)
        return filter_by_equipment(ex_equip, equipment, ex_name)
    except Exception:  # noqa: BLE001
        return True  # fail open — a backfill candidate is better than a thin workout


def _is_injury_safe(ex: Dict[str, Any], injury_muscles: set) -> bool:
    if not injury_muscles:
        return True
    muscle = (ex.get("muscle_group") or ex.get("target_muscle") or "").lower()
    return not any(m in muscle for m in injury_muscles if m)


async def ensure_complete_workout(
    exercises: List[Dict[str, Any]],
    *,
    target: int,
    floor: int,
    focus_area: str,
    equipment: Optional[List[str]] = None,
    fitness_level: str = "intermediate",
    goals: Optional[List[str]] = None,
    workout_type: str = "strength",
    reserve_pool: Optional[List[Dict[str, Any]]] = None,
    injuries: Optional[List[str]] = None,
    avoided_exercises: Optional[List[str]] = None,
    avoided_muscles: Optional[Dict[str, List[str]]] = None,
    candidate_pool_size: Optional[int] = None,
    user_id: Optional[str] = None,
    rag_service: Any = None,
) -> Tuple[List[Dict[str, Any]], Optional[str]]:
    """Restore ``exercises`` toward ``target``; degrade truthfully if impossible.

    Returns ``(exercises, degraded_reason)``. ``degraded_reason`` is None when the
    workout meets the floor. Never raises for routine shortfalls; the caller
    should still wrap the call defensively (fail open).
    """
    exercises = list(exercises or [])
    have = distinct_count(exercises)
    if have >= target:
        return exercises, None

    seen = {_key(e) for e in exercises if _key(e)}
    seen_lib = {_lib_key(e) for e in exercises if _lib_key(e)}
    avoided_lower = {a.strip().lower() for a in (avoided_exercises or []) if a}
    injury_muscles = {m.strip().lower() for m in (injuries or []) if m}
    # also fold injury-derived avoided muscles
    if avoided_muscles and avoided_muscles.get("avoid"):
        injury_muscles |= {m.strip().lower() for m in avoided_muscles["avoid"] if m}

    def _admit(cand: Dict[str, Any]) -> bool:
        k = _key(cand)
        if not k or k in seen:
            return False
        lib = _lib_key(cand)
        if lib and lib in seen_lib:
            return False
        if (cand.get("name") or "").strip().lower() in avoided_lower:
            return False
        if not _is_injury_safe(cand, injury_muscles):
            return False
        if not _is_equipment_ok(cand, equipment):
            return False
        return True

    def _add(cand: Dict[str, Any]) -> None:
        exercises.append(cand)
        seen.add(_key(cand))
        if _lib_key(cand):
            seen_lib.add(_lib_key(cand))

    # ---- Step 1: restore from the reserve (the trims' discards) -------------
    restored = 0
    for cand in (reserve_pool or []):
        if distinct_count(exercises) >= target:
            break
        if _admit(cand):
            _add(cand)
            restored += 1
    if restored:
        logger.info(
            f"🧩 [Completeness] Restored {restored} exercise(s) from reserve "
            f"({have} → {distinct_count(exercises)}, target {target})"
        )

    have = distinct_count(exercises)
    if have >= target:
        return exercises, None

    # ---- Step 2: backfill from the RAG broadening cascade -------------------
    if rag_service is not None:
        try:
            need = target  # ask for the full target; we merge only what's new
            cascade, tier = await rag_service.select_exercises_with_fallback(
                focus_area=focus_area,
                equipment=equipment or [],
                fitness_level=fitness_level or "intermediate",
                goals=goals or [],
                count=max(need, floor) + len(seen),  # over-fetch to survive dedupe
                injuries=injuries,
                avoid_exercises=list(avoided_lower) if avoided_lower else None,
                user_id=user_id,
                workout_type_preference=workout_type or "strength",
                min_floor=floor,
            )
            added = 0
            for cand in (cascade or []):
                if distinct_count(exercises) >= target:
                    break
                if _admit(cand):
                    _add(cand)
                    added += 1
            logger.info(
                f"🧩 [Completeness] Backfilled {added} from RAG cascade "
                f"(tier={tier}, now {distinct_count(exercises)}/{target})"
            )
        except Exception as e:  # noqa: BLE001 — fail open, keep what we have
            logger.warning(f"⚠️ [Completeness] RAG backfill raised, keeping current: {e}")

    have = distinct_count(exercises)
    if have >= floor:
        return exercises, None

    # ---- Step 3: genuinely below floor → truthful degrade ------------------
    reason = _degraded_reason(
        candidate_pool_size=candidate_pool_size,
        floor=floor,
        injuries=injuries,
        avoided_exercises=avoided_exercises,
        avoided_muscles=avoided_muscles,
        equipment=equipment,
    )
    logger.warning(
        f"⚠️ [Completeness] Shipping DEGRADED workout: {have} distinct exercise(s) "
        f"< floor {floor} for focus={focus_area} (reason={reason}, "
        f"pool={candidate_pool_size})"
    )
    return exercises, reason


def _degraded_reason(
    *,
    candidate_pool_size: Optional[int],
    floor: int,
    injuries: Optional[List[str]],
    avoided_exercises: Optional[List[str]],
    avoided_muscles: Optional[Dict[str, List[str]]],
    equipment: Optional[List[str]],
) -> str:
    """Pick the most accurate machine-readable reason for a thin workout."""
    has_injury = bool(injuries) or bool((avoided_muscles or {}).get("avoid"))
    heavy_excl = len(avoided_exercises or []) >= 5 or bool((avoided_muscles or {}).get("reduce"))
    # A genuinely small equipment set (e.g. bodyweight-only or 1-2 items).
    _bw = {"bodyweight", "body weight", "none", "no_equipment", ""}
    real_equip = [e for e in (equipment or []) if (e or "").lower() not in _bw]
    tiny_equipment = len(real_equip) <= 2

    if has_injury:
        return REASON_INJURY
    if tiny_equipment:
        return REASON_TINY_EQUIPMENT
    if heavy_excl:
        return REASON_HEAVY_EXCLUSIONS
    return REASON_NICHE_FOCUS
