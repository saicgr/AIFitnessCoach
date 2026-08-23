"""Pre-workout reshape — Dr-Yaad audit #1 (the advise→act loop).

    POST /api/v1/workouts/{workout_id}/reshape-for-readiness

Takes the user's pre-start check-in — Sleep + Readiness 0–10 gauges, plus
"anything to flag?" inputs (sore parts, a pain part + 0–10 level, minutes
available, a free note) — and **rewrites the already-prescribed session on the
spot**, the way a coach standing next to you would:

  • bad sleep / low readiness → pull the load back (reuse the deterministic
    `adjust_workout_params_for_readiness` scaler),
  • a sore/painful body part (pain ≥ 4 = "swap zone") → swap the aggravators for
    safe alternatives (reuse the injury-safety chokepoint `enforce_injury_safety`),
  • "only N minutes today" → cut the low-priority work (finishers, cooldowns,
    isolation accessories) but keep the priority compounds.

Returns a diff `{original_exercises, reshaped_exercises, reasons}` so the client
can show an Accept/Modify gate. Persists back to the workout only when
`apply=true` (the user accepted). Fail-open: any internal error returns the
original session untouched with `reshaped=false`, never a 500 that blocks Start.
"""
from __future__ import annotations

import json
import logging
from datetime import date, datetime
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException, Path
from pydantic import BaseModel

from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from .readiness_utils import (
    adjust_workout_params_for_readiness,
    get_muscles_to_avoid_from_injuries,
)
from .utils import log_workout_change

logger = logging.getLogger("workout_reshape")

router = APIRouter()


class ReshapeRequest(BaseModel):
    # Pre-start gauges (0–10). Either may be omitted if the user skipped it.
    sleep_score: Optional[int] = None
    readiness_score: Optional[int] = None
    # "Anything to flag?" inputs.
    sore_parts: List[str] = []
    pain_part: Optional[str] = None
    pain_level: Optional[int] = None  # 0–10; ≥4 triggers a swap
    available_minutes: Optional[int] = None
    note: Optional[str] = None
    # User's local date (YYYY-MM-DD) so the persisted check-in is keyed to the
    # day the user actually trained, not the server's UTC day. Optional —
    # falls back to the server date when absent.
    local_date: Optional[str] = None
    # When true the reshaped session is persisted back to the workout (the user
    # tapped Accept). When false the endpoint only previews the diff.
    apply: bool = False


class ReshapeResponse(BaseModel):
    workout_id: str
    reshaped: bool
    applied: bool
    reasons: List[str]
    original_exercises: List[Dict[str, Any]]
    reshaped_exercises: List[Dict[str, Any]]
    # Trust framing (Dr-Yaad audit #12): every reshape decision here is the
    # deterministic engine (readiness scaler + injury-safety swap + time trim),
    # NOT an LLM — and nothing is committed until the user accepts.
    provenance: str = (
        "Adjusted by the deterministic engine — nothing changes until you accept."
    )


# Pain at/above this 0–10 level moves from "monitor" to "swap zone" (#3).
_PAIN_SWAP_THRESHOLD = 4

_SOURCE_SELECT = "id, user_id, exercises_json, duration_minutes, type, difficulty, modification_history"


def _readiness_0_100(req: ReshapeRequest) -> Optional[int]:
    """Fold the two 0–10 gauges into the 0–100 score the scaler expects.

    Sleep + readiness are averaged; either alone still yields a score. None when
    the user provided neither (no readiness scaling then)."""
    vals = [v for v in (req.sleep_score, req.readiness_score) if v is not None]
    if not vals:
        return None
    avg10 = sum(vals) / len(vals)
    return max(0, min(100, round(avg10 * 10)))


def _persist_checkin_gauges(sb, user_id: str, req: ReshapeRequest) -> None:
    """Best-effort: store the raw 0-10 Sleep/Readiness gauges on the user's
    `readiness_scores` row for today so the AI coach can see how the user felt
    going into the session (user_state_assembler + daily_insight read this
    table). Upsert on (user_id, score_date) only touches the new columns, so it
    never clobbers a same-day Hooper check-in. Failures are swallowed — a
    persistence error must never block the workout start."""
    if req.sleep_score is None and req.readiness_score is None:
        return
    try:
        score_date = req.local_date or date.today().isoformat()
        record: Dict[str, Any] = {
            "user_id": user_id,
            "score_date": score_date,
            "pre_workout_checkin_at": datetime.now().isoformat(),
        }
        if req.sleep_score is not None:
            record["pre_workout_sleep_0_10"] = max(0, min(10, int(req.sleep_score)))
        if req.readiness_score is not None:
            record["pre_workout_readiness_0_10"] = max(
                0, min(10, int(req.readiness_score))
            )
        sb.client.table("readiness_scores").upsert(
            record, on_conflict="user_id,score_date"
        ).execute()
    except Exception as e:
        logger.warning(f"[reshape] check-in gauge persist skipped: {e}")


# E2E #146: the duration estimator used to be defined locally here (and
# diverged from program expansion's silence and quick_adjust.py's own
# formula). Moved to the shared chokepoint — see workout_duration_energy.py
# for the full class writeup. Aliased to the old name so every call site
# below is unchanged.
from .workout_duration_energy import (
    estimate_duration_minutes as _estimate_minutes,
    estimate_workout_calories,
    resolve_user_weight_kg,
)


def _priority_rank(ex: Dict[str, Any]) -> int:
    """Lower = drop first when trimming to a time budget. Finishers and
    cooldown/warmup mobility go before isolation accessories, which go before
    the priority compounds (kept last)."""
    if ex.get("is_finisher") is True:
        return 0
    section = (ex.get("section") or "").lower()
    if section in ("cooldown", "warmup"):
        return 1
    if ex.get("movement_category") == "PREHAB":
        return 1
    if (ex.get("mechanic_type") == "isolation") or (
        ex.get("movement_pattern") == "isolation"
    ):
        return 2
    return 3  # compound / primary work — kept


def _reshape_set_targets(
    set_targets: Any, new_sets: Optional[int], new_reps: Optional[int]
) -> Any:
    """Rewrite an exercise's per-set `set_targets` array to match its just-
    scaled `sets`/`reps` scalars.

    Row #? (this fix): reshape used to rewrite ONLY the scalar `sets`/`reps`/
    `rest_seconds` fields — the Advanced session UI reads `set_targets`
    instead, so the accepted trim (e.g. 4 sets -> 3) never reached the
    per-set header ("Set 1 of 4") or the per-set rep targets shown during the
    session. Truncates to `new_sets` entries (never pads — reshape only ever
    reduces or holds steady), scales `target_reps` on WORKING sets to the new
    rep scalar, and deliberately leaves warmup/drop/failure/amrap entries'
    own typing (reps, weight, rpe) untouched so a warmup set doesn't suddenly
    read as a working set. Renumbers `set_number` so it stays 1..N contiguous
    after truncation.
    """
    if not isinstance(set_targets, list) or not set_targets:
        return set_targets
    if not isinstance(new_sets, int) or new_sets <= 0:
        return set_targets

    truncated = set_targets[:new_sets] if new_sets < len(set_targets) else list(set_targets)
    out: List[Any] = []
    for i, st in enumerate(truncated):
        if not isinstance(st, dict):
            out.append(st)
            continue
        new_st = dict(st)
        if new_reps is not None and (new_st.get("set_type") or "working") == "working":
            new_st["target_reps"] = new_reps
        new_st["set_number"] = i + 1
        out.append(new_st)
    return out


def _apply_readiness_scaling(
    exercises: List[Dict[str, Any]], readiness_100: int
) -> List[Dict[str, Any]]:
    """Scale each exercise's sets/reps/rest by the deterministic readiness rule."""
    out: List[Dict[str, Any]] = []
    for ex in exercises:
        if not isinstance(ex, dict):
            out.append(ex)
            continue
        params = {
            "sets": ex.get("sets"),
            "reps": ex.get("reps"),
            "rest_seconds": ex.get("rest_seconds"),
        }
        adj = adjust_workout_params_for_readiness(params, readiness_100)
        new_ex = dict(ex)
        if adj.get("sets") is not None:
            new_ex["sets"] = adj["sets"]
        if adj.get("reps") is not None:
            new_ex["reps"] = adj["reps"]
        if adj.get("rest_seconds") is not None:
            new_ex["rest_seconds"] = adj["rest_seconds"]
        # Keep set_targets — the Advanced session's actual source of truth —
        # in lockstep with the scalars rewritten above. Without this the
        # session UI still reads the pre-reshape set count/reps.
        if "set_targets" in new_ex:
            new_ex["set_targets"] = _reshape_set_targets(
                new_ex.get("set_targets"), new_ex.get("sets"), new_ex.get("reps")
            )
        out.append(new_ex)
    return out


@router.post("/{workout_id}/reshape-for-readiness", response_model=ReshapeResponse)
async def reshape_for_readiness(
    req: ReshapeRequest,
    workout_id: str = Path(..., description="Workout to reshape"),
    current_user: dict = Depends(get_current_user),
):
    sb = get_supabase_db()
    user_id = str(current_user["id"])

    try:
        row = (
            sb.client.table("workouts")
            .select(_SOURCE_SELECT)
            .eq("id", workout_id)
            .maybe_single()
            .execute()
        )
    except Exception as e:
        raise safe_internal_error(e, "reshape_fetch", workout_id=workout_id)

    if not row or not row.data:
        raise HTTPException(status_code=404, detail="Workout not found")
    if str(row.data.get("user_id")) != user_id:
        raise HTTPException(status_code=403, detail="Access denied")

    # Persist the raw check-in gauges so the coach knows how the user felt today
    # (independent of whether the engine reshaped anything). Best-effort.
    _persist_checkin_gauges(sb, user_id, req)

    original = row.data.get("exercises_json") or []
    if not isinstance(original, list) or not original:
        # Nothing to reshape — return as-is.
        return ReshapeResponse(
            workout_id=workout_id, reshaped=False, applied=False,
            reasons=[], original_exercises=[], reshaped_exercises=[],
        )

    reasons: List[str] = []
    reshaped = [dict(e) if isinstance(e, dict) else e for e in original]

    # Everything below is best-effort; a failure in one stage must not block the
    # workout. We accumulate reasons and fall back to the original on hard error.
    try:
        # 1) Pain / soreness → swap the aggravators (≥4 = swap zone). -----------
        avoid_parts: List[str] = [p for p in (req.sore_parts or []) if p]
        if req.pain_part and (req.pain_level or 0) >= _PAIN_SWAP_THRESHOLD:
            avoid_parts.append(req.pain_part)
        elif req.pain_part:
            reasons.append(
                f"Noted {req.pain_part.replace('_', ' ')} discomfort "
                f"({req.pain_level or 0}/10) — monitoring, not swapping yet."
            )

        # Tissue-fatigue ledger feed (Dr-Yaad #4): a VERY hot joint/tendon
        # (heat ≥ 85) joins the swap set so we proactively pull load off it —
        # seeing the injury before it happens. Mapped tissue → injury body part.
        try:
            from services.tissue_fatigue_service import hottest_tissues
            _TISSUE_TO_PART = {
                "lumbar": "lower_back", "achilles": "ankle",
            }
            hot = hottest_tissues(user_id, threshold_heat=85.0)
            for t in hot[:2]:
                part = _TISSUE_TO_PART.get(t, t)
                if part not in avoid_parts:
                    avoid_parts.append(part)
                    reasons.append(
                        f"Your {t} is running hot from recent volume — pulled load "
                        f"off it before it flares."
                    )
        except Exception as e:
            logger.debug(f"[reshape] tissue feed skipped: {e}")

        if avoid_parts:
            try:
                from services.exercise_rag.injury_guard import enforce_injury_safety
                safe, dropped, added = await enforce_injury_safety(
                    reshaped, injuries=avoid_parts, user_id=user_id,
                )
                if dropped:
                    reshaped = safe
                    parts_txt = ", ".join(
                        p.replace("_", " ") for p in avoid_parts
                    )
                    reasons.append(
                        f"Swapped {len(dropped)} exercise(s) that load your "
                        f"{parts_txt}: {', '.join(dropped[:3])}"
                        + (f" +{len(dropped) - 3} more" if len(dropped) > 3 else "")
                    )
            except Exception as e:
                logger.warning(f"[reshape] injury swap skipped: {e}")
                # Deterministic fallback: at minimum, drop exercises whose muscle
                # is in the avoid set so we never KEEP a known aggravator.
                avoid_muscles = set(
                    get_muscles_to_avoid_from_injuries(avoid_parts)
                )
                if avoid_muscles:
                    kept = []
                    dropped_n = 0
                    for ex in reshaped:
                        m = (
                            (ex.get("primary_muscle") or ex.get("muscle_group") or "")
                            if isinstance(ex, dict) else ""
                        ).lower()
                        if m and m in avoid_muscles:
                            dropped_n += 1
                            continue
                        kept.append(ex)
                    if dropped_n and kept:
                        reshaped = kept
                        reasons.append(
                            f"Removed {dropped_n} exercise(s) that load a flagged area."
                        )

        # 2) Low / high readiness → pull the load. ------------------------------
        readiness_100 = _readiness_0_100(req)
        if readiness_100 is not None and (readiness_100 < 50 or readiness_100 > 70):
            reshaped = _apply_readiness_scaling(reshaped, readiness_100)
            if readiness_100 < 50:
                reasons.append(
                    f"Low readiness ({readiness_100}/100): trimmed sets/reps and "
                    f"lengthened rest so today still moves you forward without digging a hole."
                )
            else:
                reasons.append(
                    f"High readiness ({readiness_100}/100): nudged volume up and "
                    f"tightened rest — good day to push."
                )

        # 3) Time budget → cut low-priority work to fit. ------------------------
        if req.available_minutes and req.available_minutes > 0:
            est = _estimate_minutes(reshaped)
            if est > req.available_minutes + 2:  # 2-min slack
                # Drop lowest-priority first, but never below 3 exercises.
                indexed = sorted(
                    range(len(reshaped)),
                    key=lambda i: _priority_rank(reshaped[i])
                    if isinstance(reshaped[i], dict) else 3,
                )
                keep_flags = [True] * len(reshaped)
                cut = 0
                for i in indexed:
                    if sum(keep_flags) <= 3:
                        break
                    if _estimate_minutes(
                        [reshaped[j] for j in range(len(reshaped)) if keep_flags[j]]
                    ) <= req.available_minutes:
                        break
                    keep_flags[i] = False
                    cut += 1
                if cut:
                    reshaped = [
                        reshaped[i] for i in range(len(reshaped)) if keep_flags[i]
                    ]
                    reasons.append(
                        f"Only {req.available_minutes} min today: cut {cut} "
                        f"lower-priority piece(s), kept the work that matters most."
                    )
    except Exception as e:
        logger.warning(f"[reshape] reshape pipeline error, returning original: {e}")
        return ReshapeResponse(
            workout_id=workout_id, reshaped=False, applied=False, reasons=[],
            original_exercises=original, reshaped_exercises=original,
        )

    did_reshape = bool(reasons) and reshaped != original
    applied = False
    if did_reshape:
        # Consistency check (non-fatal, log-only — this endpoint is
        # deliberately fail-open): `sets` and `set_targets` must not drift
        # apart again the way they did before this fix. A warmup/drop/failure
        # entry can legitimately push set_targets one longer than the working
        # `sets` count, so this only flags a WORKING-set shortfall.
        for ex in reshaped:
            if not isinstance(ex, dict):
                continue
            targets = ex.get("set_targets")
            n_sets = ex.get("sets")
            if isinstance(targets, list) and targets and isinstance(n_sets, int):
                working = sum(
                    1 for t in targets
                    if isinstance(t, dict) and (t.get("set_type") or "working") == "working"
                )
                if working < n_sets:
                    logger.warning(
                        "[reshape] set_targets/sets mismatch after reshape: "
                        f"exercise={ex.get('name')!r} sets={n_sets} "
                        f"working_set_targets={working} total_set_targets={len(targets)}"
                    )
    if did_reshape and req.apply:
        try:
            new_minutes = round(_estimate_minutes(reshaped))
            # E2E #146: rewriting duration WITHOUT rewriting energy is exactly
            # the bug — the client re-derived calories from the new duration
            # via its own MET fallback, so the calorie headline moved in
            # lockstep with duration alone (same implied MET). Recompute
            # through the SAME chokepoint program expansion now uses.
            _weight_kg = resolve_user_weight_kg(sb, user_id)
            new_calories = estimate_workout_calories(
                reshaped,
                row.data.get("type"),
                row.data.get("difficulty"),
                new_minutes,
                _weight_kg,
            )

            # Register row #159: this endpoint rewrote exercises_json /
            # duration_minutes / estimated_calories in place with NO audit
            # trail — neither `modification_history` (the column) nor
            # `workout_changes` (via log_workout_change) ever saw it, unlike
            # every other mutation path (see services/workout_modifier.py).
            # A reshaped workout was indistinguishable after the fact from
            # one that was always that size. Stamp both surfaces, same shape.
            existing_history = row.data.get("modification_history") or []
            if isinstance(existing_history, str):
                try:
                    existing_history = json.loads(existing_history) if existing_history else []
                except (ValueError, TypeError):
                    existing_history = []
            history_entry = {
                "type": "reshape_for_readiness",
                "reasons": reasons,
                "exercise_count_before": len(original),
                "exercise_count_after": len(reshaped),
                "duration_minutes": new_minutes,
                "estimated_calories": new_calories,
                "timestamp": datetime.now().isoformat(),
                "method": "pre_workout_checkin",
            }
            new_history = list(existing_history) + [history_entry]

            sb.client.table("workouts").update(
                {
                    "exercises_json": reshaped,
                    "duration_minutes": new_minutes,
                    "estimated_calories": new_calories,
                    "modification_history": new_history,
                    "last_modified_method": "reshape_for_readiness",
                }
            ).eq("id", workout_id).eq("user_id", user_id).execute()
            applied = True

            log_workout_change(
                workout_id,
                user_id,
                "reshape_for_readiness",
                "exercises_json",
                None,
                {
                    "reasons": reasons,
                    "exercise_count_before": len(original),
                    "exercise_count_after": len(reshaped),
                    "duration_minutes": new_minutes,
                    "estimated_calories": new_calories,
                },
                change_source="pre_workout_checkin",
                change_reason="; ".join(reasons) if reasons else None,
            )
        except Exception as e:
            logger.warning(f"[reshape] persist failed (non-fatal): {e}")

    return ReshapeResponse(
        workout_id=workout_id,
        reshaped=did_reshape,
        applied=applied,
        reasons=reasons,
        original_exercises=original,
        reshaped_exercises=reshaped if did_reshape else original,
    )
