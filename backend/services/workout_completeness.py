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
    duration_minutes: Optional[int] = None,
    age: Optional[int] = None,
) -> Tuple[List[Dict[str, Any]], Optional[str]]:
    """Restore ``exercises`` toward ``target``; degrade truthfully if impossible.

    Returns ``(exercises, degraded_reason)``. ``degraded_reason`` is None when the
    workout meets the floor. Never raises for routine shortfalls; the caller
    should still wrap the call defensively (fail open).

    ``duration_minutes`` (optional, backward-compatible) enables the TIME-adequacy
    pass: after the count is restored, the assembled session is costed (cheap
    arithmetic via ``exercise_target.estimate_total_minutes``). If it fills
    < ~80% of the requested time AND the pool is constrained, sets are bumped
    within the per-level caps and/or a safe core/mobility block is appended; if
    > ~110%, sets/exercises are trimmed; if the time genuinely can't be filled,
    the stated duration is reduced and a ``time_degraded`` note is set. With
    ``duration_minutes=None`` (the default) the time pass is skipped entirely
    (fail-open / byte-identical to the prior behavior).
    """
    exercises = list(exercises or [])

    # Single finalization path so the optional TIME-adequacy pass runs on EVERY
    # return (count-met, restored, backfilled, or degraded). When
    # duration_minutes is None the pass is a no-op (fail-open).
    def _finalize(
        final_list: List[Dict[str, Any]], reason: Optional[str]
    ) -> Tuple[List[Dict[str, Any]], Optional[str]]:
        if duration_minutes and duration_minutes > 0:
            try:
                final_list, reason = _right_size_for_time(
                    final_list,
                    reason=reason,
                    duration_minutes=int(duration_minutes),
                    floor=floor,
                    fitness_level=fitness_level,
                    workout_type=workout_type,
                    age=age,
                    candidate_pool_size=candidate_pool_size,
                    injuries=injuries,
                    avoided_muscles=avoided_muscles,
                    equipment=equipment,
                    avoided_exercises=avoided_exercises,
                )
            except Exception as e:  # noqa: BLE001 — fail open
                logger.warning(f"⚠️ [Completeness] time right-size raised, skipping: {e}")
        return final_list, reason

    have = distinct_count(exercises)
    if have >= target:
        return _finalize(exercises, None)

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
        return _finalize(exercises, None)

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
                duration_minutes=duration_minutes,
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
        return _finalize(exercises, None)

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
    return _finalize(exercises, reason)


# Time-adequacy degraded reason (A3): the workout could not be filled to the
# requested duration even after right-sizing, so the stated duration was reduced.
REASON_TIME_UNDERFILLED = "time_underfilled"

# Adequacy band: a session is "right-sized" when it fills 80–110% of the target.
_TIME_UNDER_RATIO = 0.80
_TIME_OVER_RATIO = 1.10
# Per-exercise hard set ceiling for the bump (the per-level cap from
# validate_and_cap_exercise_parameters still applies on top of this).
_TIME_BUMP_MAX_SETS = 6


def _is_pool_constrained(
    candidate_pool_size: Optional[int],
    injuries: Optional[List[str]],
    avoided_muscles: Optional[Dict[str, List[str]]],
    equipment: Optional[List[str]],
) -> bool:
    """True when the user's real candidate pool is genuinely limited.

    The time guard only ADDS volume when the pool is constrained — an
    unconstrained user with a roomy pool should have been filled by the count
    restore already, so bumping sets there would distort a fine session.
    """
    if candidate_pool_size is not None and candidate_pool_size <= 12:
        return True
    if injuries or (avoided_muscles or {}).get("avoid"):
        return True
    _bw = {"bodyweight", "body weight", "none", "no_equipment", ""}
    real_equip = [e for e in (equipment or []) if (e or "").lower() not in _bw]
    return len(real_equip) <= 2


def _right_size_for_time(
    exercises: List[Dict[str, Any]],
    *,
    reason: Optional[str],
    duration_minutes: int,
    floor: int,
    fitness_level: str,
    workout_type: str,
    age: Optional[int],
    candidate_pool_size: Optional[int],
    injuries: Optional[List[str]],
    avoided_muscles: Optional[Dict[str, List[str]]],
    equipment: Optional[List[str]],
    avoided_exercises: Optional[List[str]],
) -> Tuple[List[Dict[str, Any]], Optional[str]]:
    """Right-size an assembled workout to its requested duration (A3).

    Cheap arithmetic only — no I/O, no LLM. Order of operations:
      * estimate total minutes (set/rep/tempo + rest + transitions);
      * UNDER (< 80%) + constrained pool → bump sets within the per-level caps,
        re-cost; still short → reduce the stated duration + flag degraded;
      * OVER (> 110%) → trim sets, then drop the lowest-fit exercise above the
        floor until inside the band;
      * inside the band → no-op.
    Returns (exercises, reason). Never raises (caller also wraps defensively).
    """
    from api.v1.workouts.exercise_target import estimate_total_minutes

    if not exercises:
        return exercises, reason

    est = estimate_total_minutes(exercises)
    target_min = float(duration_minutes)
    if target_min <= 0:
        return exercises, reason

    ratio = est / target_min

    # ---- OVER-filled: trim sets, then drop lowest-fit above floor ----------
    if ratio > _TIME_OVER_RATIO:
        # Trim one set from the highest-set exercises first (descending), never
        # below 2 sets, re-costing after each trim.
        guard = 0
        while estimate_total_minutes(exercises) / target_min > _TIME_OVER_RATIO and guard < 50:
            guard += 1
            # Drop a set from the exercise with the most sets (>2).
            trim_idx = None
            best_sets = 2
            for i, ex in enumerate(exercises):
                s = ex.get("sets")
                if isinstance(s, int) and s > best_sets:
                    best_sets = s
                    trim_idx = i
            if trim_idx is not None:
                exercises[trim_idx]["sets"] = exercises[trim_idx]["sets"] - 1
                _shrink_set_targets(exercises[trim_idx])
                continue
            # No more set-trims available — drop the last (lowest-fit) exercise
            # while we still stay above the floor.
            if len(exercises) > floor:
                exercises.pop()
                continue
            break
        logger.info(
            f"🧩 [Completeness] Time over-fill trimmed to "
            f"{estimate_total_minutes(exercises):.0f}min (target {target_min:.0f}min)"
        )
        return exercises, reason

    # ---- UNDER-filled: only act when the pool is genuinely constrained -----
    if ratio < _TIME_UNDER_RATIO:
        constrained = _is_pool_constrained(
            candidate_pool_size, injuries, avoided_muscles, equipment
        )
        if not constrained:
            # Roomy pool: count-restore should have handled it; don't distort.
            return exercises, reason

        # Bump sets (within per-level caps) until we hit the band or the cap.
        from api.v1.workouts.validation_utils import validate_and_cap_exercise_parameters
        guard = 0
        while estimate_total_minutes(exercises) / target_min < _TIME_UNDER_RATIO and guard < 50:
            guard += 1
            bumped = False
            for ex in exercises:
                s = ex.get("sets")
                if isinstance(s, int) and s < _TIME_BUMP_MAX_SETS:
                    ex["sets"] = s + 1
                    _grow_set_targets(ex)
                    bumped = True
            if not bumped:
                break
        # Re-apply the per-level / age caps so the bump never exceeds the safe
        # ceiling (the cap is idempotent and clamps any over-bump back down).
        try:
            exercises[:] = validate_and_cap_exercise_parameters(
                exercises, fitness_level=fitness_level or "intermediate", age=age
            )
        except Exception as e:  # noqa: BLE001 — fail open
            logger.warning(f"⚠️ [Completeness] cap re-apply after bump raised: {e}")

        est_after = estimate_total_minutes(exercises)
        if est_after / target_min < _TIME_UNDER_RATIO:
            # Genuinely cannot fill the time with the constrained pool — REDUCE
            # the stated duration to the honest estimate and flag it. We can't
            # mutate the workout dict from here, so stamp the adjusted duration
            # on the first exercise for the caller to read, and degrade.
            adjusted = max(5, int(round(est_after)))
            if exercises:
                exercises[0]["_adjusted_duration_minutes"] = adjusted
                exercises[0]["_time_degraded_note"] = (
                    f"Your equipment/injury constraints only support about "
                    f"{adjusted} min of safe training today; the session length "
                    f"was trimmed from {int(target_min)} min to match."
                )
            logger.warning(
                f"⚠️ [Completeness] Time underfilled: only {est_after:.0f}min of "
                f"{target_min:.0f}min fillable (constrained pool); reducing stated "
                f"duration to {adjusted}min"
            )
            return exercises, reason or REASON_TIME_UNDERFILLED
        logger.info(
            f"🧩 [Completeness] Time under-fill bumped to {est_after:.0f}min "
            f"(target {target_min:.0f}min)"
        )

    return exercises, reason


def _grow_set_targets(ex: Dict[str, Any]) -> None:
    """Append a working set to ``set_targets`` to match an incremented ``sets``.

    Clones the last working set (or a sensible default) so re-costing reflects
    the new volume. No-op when the exercise has no set_targets.
    """
    sts = ex.get("set_targets")
    if not isinstance(sts, list) or not sts:
        return
    template = None
    for st in reversed(sts):
        if isinstance(st, dict) and st.get("set_type") != "warmup":
            template = st
            break
    if template is None:
        return
    clone = dict(template)
    clone["set_number"] = len(sts) + 1
    sts.append(clone)


def _shrink_set_targets(ex: Dict[str, Any]) -> None:
    """Drop the last working set from ``set_targets`` to match a decremented
    ``sets`` (never removes a warmup). No-op when nothing to drop."""
    sts = ex.get("set_targets")
    if not isinstance(sts, list) or len(sts) <= 1:
        return
    for i in range(len(sts) - 1, -1, -1):
        st = sts[i]
        if isinstance(st, dict) and st.get("set_type") != "warmup":
            sts.pop(i)
            return


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
