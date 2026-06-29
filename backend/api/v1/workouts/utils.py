"""
Shared utilities and helper functions for workout endpoints.

This module re-exports all utilities from focused sub-modules for
backwards compatibility. New code should import directly from the
specific sub-module when possible.

Sub-modules:
- schedule_utils: Training splits, focus areas, workout type inference
- validation_utils: Exercise parameter caps, safety nets, set/rep limits
- user_preference_utils: DB fetch helpers for user preferences
- readiness_utils: Readiness, mood, injuries, comeback
- progression_utils: Rep preferences, mastery, workout patterns
- hormonal_utils: Cycle phase, kegels, gender-specific adjustments
- focus_validation_utils: Focus area matching, muscle profiles
"""
import json
import time
from datetime import datetime, date, timedelta
from typing import List, Optional, Dict, Any

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.timezone_utils import get_user_today
from models.schemas import Workout
from services.gemini_service import GeminiService
from services.rag_service import WorkoutRAGService

logger = get_logger(__name__)

# ============================================================================
# Core utilities that remain in this file (small, foundational)
# ============================================================================

# Initialize workout RAG service (lazy loading)
_workout_rag_service: Optional[WorkoutRAGService] = None


def get_workout_rag_service() -> WorkoutRAGService:
    """Get or create the workout RAG service instance."""
    global _workout_rag_service
    if _workout_rag_service is None:
        gemini_service = GeminiService()
        _workout_rag_service = WorkoutRAGService(gemini_service)
    return _workout_rag_service


def invalidate_upcoming_workouts(
    user_id: str,
    reason: str,
    only_next: bool = False,
    timezone_str: str = None,
) -> int:
    """Delete upcoming non-completed workouts so the next /today call regenerates them.

    ``timezone_str`` should be passed from the caller (resolved via
    ``resolve_timezone``).  When *None* the function falls back to UTC
    which may be wrong near midnight for non-UTC users.
    """
    try:
        db = get_supabase_db()
        if timezone_str:
            today_str = get_user_today(timezone_str)
        else:
            # Last-resort fallback — callers should always supply timezone_str
            today_str = get_user_today("UTC")

        query = db.client.table("workouts").select(
            "id, scheduled_date, status, is_user_modified"
        ).eq(
            "user_id", user_id
        ).gt(
            "scheduled_date", today_str
        ).eq(
            "is_completed", False
        )

        rows = query.execute()
        if not rows.data:
            return 0

        # Skip user-pinned workouts: a future workout the user hand-edited must
        # survive the regenerate cascade (F5 — granular edits). "Reset to plan"
        # clears the flag to let it regenerate again.
        def _eligible(r):
            return r.get("status") != "generating" and not r.get("is_user_modified")

        ids_to_delete = [r["id"] for r in rows.data if _eligible(r)]

        if only_next:
            dated = sorted(
                [(r["id"], r.get("scheduled_date", "")) for r in rows.data if _eligible(r)],
                key=lambda x: x[1],
            )
            ids_to_delete = [dated[0][0]] if dated else []

        if not ids_to_delete:
            return 0

        deleted = db.client.table("workouts").delete().in_("id", ids_to_delete).execute()
        count = len(deleted.data) if deleted.data else 0
        logger.info(f"[INVALIDATE] Deleted {count} upcoming workouts for user {user_id} ({reason})")
        return count

    except Exception as e:
        logger.warning(f"[INVALIDATE] Failed to invalidate workouts for user {user_id} ({reason}): {e}", exc_info=True)
        return 0


def invalidate_workouts_after_equipment_change(
    user_id: str,
    timezone_str: str = None,
) -> dict:
    """Delete the user's not-yet-started today + upcoming workouts so the
    next read of `/today` (and the upcoming pre-cache) regenerates them
    against the new equipment list. Workouts that are already in progress
    or completed are LEFT ALONE — see plan §D for the policy:

      - Today not started      → delete (regenerate on next /today read)
      - Today in progress      → leave alone (warn user via separate UX)
      - Today completed        → never touch history
      - Tomorrow / upcoming    → delete via invalidate_upcoming_workouts
      - Past                   → never touch history

    Returns a dict {today_deleted, upcoming_deleted} for caller telemetry.
    Safe under partial failure: if the today-delete step throws, the
    upcoming-delete step still runs.
    """
    today_deleted = 0
    upcoming_deleted = 0

    try:
        db = get_supabase_db()
        if timezone_str:
            today_str = get_user_today(timezone_str)
        else:
            today_str = get_user_today("UTC")

        # Today: delete only if not started and not completed.
        # `is_completed=False` matches the same column the upcoming helper
        # uses. `status != 'in_progress'` ensures we don't yank a workout
        # mid-set. `status != 'generating'` mirrors upcoming-helper logic.
        today_rows = db.client.table("workouts").select(
            "id, status, is_completed"
        ).eq("user_id", user_id).eq("scheduled_date", today_str).execute()

        ids_to_delete = [
            r["id"] for r in (today_rows.data or [])
            if not r.get("is_completed")
            and r.get("status") not in ("generating", "in_progress")
        ]
        if ids_to_delete:
            res = db.client.table("workouts").delete().in_(
                "id", ids_to_delete
            ).execute()
            today_deleted = len(res.data) if res.data else 0
            logger.info(
                f"[INVALIDATE-EQUIP] Deleted {today_deleted} today workouts "
                f"for user {user_id}"
            )
    except Exception as e:
        logger.warning(
            f"[INVALIDATE-EQUIP] Failed to delete today's workout for "
            f"user {user_id}: {e}",
            exc_info=True,
        )

    upcoming_deleted = invalidate_upcoming_workouts(
        user_id, reason="equipment_change", timezone_str=timezone_str
    )

    return {
        "today_deleted": today_deleted,
        "upcoming_deleted": upcoming_deleted,
    }


def invalidate_workouts_after_program_change(
    user_id: str,
    timezone_str: str = None,
) -> dict:
    """Single chokepoint for "the user changed their program — regenerate".

    Deletes the user's not-yet-started today + all upcoming incomplete
    workouts so the next `/today` read (and the upcoming pre-cache)
    regenerates them against the new split / per-day / workout-type prefs.
    In-progress and completed rows are left untouched (same guards as the
    equipment helper). This is what the "Apply now?" confirm and the
    `POST /workouts/regenerate-upcoming` endpoint call — so every program
    mutation path invalidates identically instead of each endpoint rolling
    its own (or silently doing nothing, the bug this fixes).
    """
    today_deleted = 0
    upcoming_deleted = 0

    try:
        from core.timezone_utils import local_date_to_utc_range
        db = get_supabase_db()
        _tz = timezone_str or "UTC"
        today_str = get_user_today(_tz)
        # scheduled_date is TIMESTAMPTZ (e.g. "2026-06-23 17:00:00+00"), so an
        # `.eq("scheduled_date", "2026-06-23")` date match NEVER matches (time
        # component differs). Use the day's UTC range instead.
        _start, _end = local_date_to_utc_range(today_str, _tz)
        today_rows = db.client.table("workouts").select(
            "id, status, is_completed, is_user_modified"
        ).eq("user_id", user_id).gte(
            "scheduled_date", _start
        ).lte("scheduled_date", _end).execute()
        ids_to_delete = [
            r["id"] for r in (today_rows.data or [])
            if not r.get("is_completed")
            and not r.get("is_user_modified")
            and r.get("status") not in ("generating", "in_progress")
        ]
        if ids_to_delete:
            res = db.client.table("workouts").delete().in_(
                "id", ids_to_delete
            ).execute()
            today_deleted = len(res.data) if res.data else 0
            logger.info(
                f"[INVALIDATE-PROGRAM] Deleted {today_deleted} today workouts "
                f"for user {user_id}"
            )
    except Exception as e:
        logger.warning(
            f"[INVALIDATE-PROGRAM] Failed to delete today's workout for "
            f"user {user_id}: {e}",
            exc_info=True,
        )

    upcoming_deleted = invalidate_upcoming_workouts(
        user_id, reason="program_change", timezone_str=timezone_str
    )

    return {
        "today_deleted": today_deleted,
        "upcoming_deleted": upcoming_deleted,
    }


def invalidate_workouts_after_schedule_change(
    user_id: str,
    timezone_str: str = None,
    new_workout_days: List[int] = None,
) -> dict:
    """Delete workouts that fall on days no longer in the user's schedule.

    Mirrors `invalidate_workouts_after_equipment_change` but the predicate is
    "weekday is no longer scheduled" instead of "always". Same status guards:
    in-progress / completed rows are preserved.

      - Today not started, today's weekday not in new_workout_days → delete
      - Today scheduled in new list                                → leave (still valid)
      - Today in progress / completed                              → never touch
      - Upcoming on dropped weekday, not started                   → delete
      - Upcoming on still-scheduled weekday                        → leave

    Returns {today_deleted, upcoming_deleted} for caller telemetry.
    `new_workout_days` is a list of ints 0=Mon..6=Sun (matches Python's
    `date.weekday()`).
    """
    today_deleted = 0
    upcoming_deleted = 0
    new_days_set = set(new_workout_days or [])

    try:
        db = get_supabase_db()
        if timezone_str:
            today_str = get_user_today(timezone_str)
        else:
            today_str = get_user_today("UTC")

        today_dt = date.fromisoformat(today_str)

        # Today: delete only if today's weekday was removed AND row is not
        # in-progress / completed / generating.
        if today_dt.weekday() not in new_days_set:
            today_rows = db.client.table("workouts").select(
                "id, status, is_completed"
            ).eq("user_id", user_id).eq("scheduled_date", today_str).execute()

            ids_to_delete = [
                r["id"] for r in (today_rows.data or [])
                if not r.get("is_completed")
                and r.get("status") not in ("generating", "in_progress")
            ]
            if ids_to_delete:
                res = db.client.table("workouts").delete().in_(
                    "id", ids_to_delete
                ).execute()
                today_deleted = len(res.data) if res.data else 0
                logger.info(
                    f"[INVALIDATE-SCHED] Deleted {today_deleted} today workouts "
                    f"for user {user_id} (today weekday {today_dt.weekday()} no "
                    f"longer scheduled)"
                )
    except Exception as e:
        logger.warning(
            f"[INVALIDATE-SCHED] Failed to delete today's workout for user "
            f"{user_id}: {e}",
            exc_info=True,
        )

    try:
        # Upcoming: only delete rows whose scheduled_date.weekday() was dropped.
        # Bound to ~180 days ahead. Pre-2026-05-27 this fetch was unbounded and
        # users with months/years of pre-scheduled rows tripped the Dio 25s
        # client timeout. Anything further out gets caught by the daily-cleanup
        # cron / the next schedule-change.
        upper_bound = (today_dt + timedelta(days=180)).isoformat()
        rows = db.client.table("workouts").select(
            "id, scheduled_date, status"
        ).eq("user_id", user_id).gt(
            "scheduled_date", today_str
        ).lte(
            "scheduled_date", upper_bound
        ).eq("is_completed", False).limit(500).execute()

        ids_to_delete = []
        for r in (rows.data or []):
            if r.get("status") == "generating":
                continue
            sd = r.get("scheduled_date")
            if not sd:
                continue
            try:
                wd = date.fromisoformat(str(sd)[:10]).weekday()
            except (ValueError, TypeError):
                continue
            if wd not in new_days_set:
                ids_to_delete.append(r["id"])

        if ids_to_delete:
            deleted = db.client.table("workouts").delete().in_(
                "id", ids_to_delete
            ).execute()
            upcoming_deleted = len(deleted.data) if deleted.data else 0
            logger.info(
                f"[INVALIDATE-SCHED] Deleted {upcoming_deleted} upcoming "
                f"workouts for user {user_id} on dropped weekdays"
            )
    except Exception as e:
        logger.warning(
            f"[INVALIDATE-SCHED] Failed to delete upcoming workouts for user "
            f"{user_id}: {e}",
            exc_info=True,
        )

    return {
        "today_deleted": today_deleted,
        "upcoming_deleted": upcoming_deleted,
    }


def invalidate_workouts_after_injury_change(
    user_id: str,
    timezone_str: str = None,
) -> dict:
    """Delete the user's not-yet-started today + upcoming workouts so the next
    `/today` read regenerates them against the user's CURRENT injuries.

    E3 — a newly-flagged (or resolved) injury must not leave stale, potentially
    unsafe future workouts on the calendar. The predicate is identical to the
    equipment-change helper ("always delete future incomplete, leave history /
    in-progress alone") because an injury change can affect ANY scheduled day's
    safety, not just a subset of weekdays. Reuses the same status guards:

      - Today not started   → delete (regenerate safe on next /today read)
      - Today in progress   → leave alone (don't yank a workout mid-set)
      - Today completed      → never touch history
      - Tomorrow / upcoming → delete via invalidate_upcoming_workouts
      - Past                 → never touch history

    Returns {today_deleted, upcoming_deleted}. Safe under partial failure: if
    the today-delete step throws, the upcoming-delete step still runs. The
    dedicated injury-report endpoint (api/v1/injuries.py::report_injury) already
    calls invalidate_upcoming_workouts; this sibling additionally clears a
    not-started TODAY row and is the canonical call for any injury write site
    that updates active_injuries (e.g. program.py::update_program).
    """
    today_deleted = 0
    upcoming_deleted = 0

    try:
        db = get_supabase_db()
        today_str = get_user_today(timezone_str) if timezone_str else get_user_today("UTC")

        today_rows = db.client.table("workouts").select(
            "id, status, is_completed"
        ).eq("user_id", user_id).eq("scheduled_date", today_str).execute()

        ids_to_delete = [
            r["id"] for r in (today_rows.data or [])
            if not r.get("is_completed")
            and r.get("status") not in ("generating", "in_progress")
        ]
        if ids_to_delete:
            res = db.client.table("workouts").delete().in_(
                "id", ids_to_delete
            ).execute()
            today_deleted = len(res.data) if res.data else 0
            logger.info(
                f"[INVALIDATE-INJURY] Deleted {today_deleted} today workouts "
                f"for user {user_id}"
            )
    except Exception as e:
        logger.warning(
            f"[INVALIDATE-INJURY] Failed to delete today's workout for "
            f"user {user_id}: {e}",
            exc_info=True,
        )

    upcoming_deleted = invalidate_upcoming_workouts(
        user_id, reason="injury_change", timezone_str=timezone_str
    )

    return {
        "today_deleted": today_deleted,
        "upcoming_deleted": upcoming_deleted,
    }


def _normalize_injury_body_parts(value) -> list:
    """Normalize an active_injuries value (list of strings or {body_part} dicts,
    or a JSON string) to a deduped, lowercased list of body-part slugs."""
    import json as _json
    if isinstance(value, str):
        try:
            value = _json.loads(value)
        except (ValueError, TypeError):
            value = [value] if value else []
    if not isinstance(value, list):
        return []
    out = []
    for item in value:
        if isinstance(item, dict):
            bp = item.get("body_part") or item.get("name") or ""
        else:
            bp = str(item or "")
        bp = bp.strip().lower()
        if bp and bp not in ("none", ""):
            out.append(bp)
    # preserve first-seen order, deduped
    seen = set()
    return [b for b in out if not (b in seen or seen.add(b))]


def sync_active_injuries_to_history(user_id: str, active_injuries) -> dict:
    """Mirror a user's ``active_injuries`` into the ``injury_history`` table so the
    COACH (which reads injury_history, not active_injuries/user_injuries) finally
    sees onboarding + profile-pill injuries — the unifier that makes "AI remembers
    your injury and offers to remove it" actually work (injury-2026-06 Phase 3).

    On ADD  → insert an active injury_history row (reported_at=now) if none active.
    On REMOVE → mark the active row(s) is_active=false + actual_recovery_date=now,
                which is what the coach's recovery/resolution nudges key off.

    Idempotent and fail-soft: never raises (an injury_history sync failure must
    not block the user-facing profile/onboarding write). Returns a small summary.
    """
    added, resolved = [], []
    try:
        db = get_supabase_db()
        desired = set(_normalize_injury_body_parts(active_injuries))

        existing_rows = db.client.table("injury_history").select(
            "id, body_part, is_active"
        ).eq("user_id", user_id).eq("is_active", True).execute()
        active_now = {}
        for r in (existing_rows.data or []):
            bp = (r.get("body_part") or "").strip().lower()
            if bp:
                active_now.setdefault(bp, []).append(r["id"])

        # ADD: desired injuries with no active history row.
        for bp in desired:
            if bp not in active_now:
                try:
                    db.client.table("injury_history").insert({
                        "user_id": user_id,
                        "body_part": bp,
                        "is_active": True,
                    }).execute()
                    added.append(bp)
                except Exception as ins_err:
                    logger.warning(
                        f"[InjurySync] insert failed for {user_id}/{bp}: {ins_err}",
                        exc_info=True,
                    )

        # REMOVE: active history rows no longer in the desired set → resolved.
        from datetime import datetime, timezone as _tz
        _now = datetime.now(_tz.utc).isoformat()
        for bp, ids in active_now.items():
            if bp not in desired:
                payload = {"is_active": False}
                if _now:
                    payload["actual_recovery_date"] = _now
                try:
                    db.client.table("injury_history").update(payload).in_(
                        "id", ids
                    ).execute()
                    resolved.append(bp)
                except Exception as upd_err:
                    logger.warning(
                        f"[InjurySync] resolve failed for {user_id}/{bp}: {upd_err}",
                        exc_info=True,
                    )

        if added or resolved:
            logger.info(
                f"[InjurySync] user={user_id} added={added} resolved={resolved}"
            )
    except Exception as e:
        logger.warning(
            f"[InjurySync] sync failed for user {user_id} (fail-soft): {e}",
            exc_info=True,
        )
    return {"added": added, "resolved": resolved}


# ============================================================================
# Request-boundary safety clamps (Phase D) — pure, deterministic, in-memory.
#
# These run at every generation entry point BEFORE generation so a bad request
# (7-day-a-week schedule, a goal weight implying a sub-floor BMI, a "kg" body
# weight that's clearly a lb value, a 0-minute session) can never drive the
# generator into unsafe or degenerate output. FAIL-OPEN by construction: a
# normal sane request passes through with values unchanged. No DB, no I/O.
# ============================================================================

# Schedule bounds. 6 hard sessions/week is the safe ceiling; a 7th day must be
# rest / active-recovery. 1 is the floor (0 days = no plan at all).
DAYS_PER_WEEK_MIN = 1
DAYS_PER_WEEK_MAX = 6
# A session shorter than this isn't a workout — clamp up so duration→exercise
# math downstream never divides toward 0 exercises.
MIN_SESSION_MINUTES = 10
# Body-measurement sanity bounds (metric). Used only to reject absurd/zero
# values and pick a sane default — never to "correct" a plausible measurement.
_MIN_HEIGHT_CM = 120.0
_MAX_HEIGHT_CM = 230.0
_MIN_WEIGHT_KG = 30.0
_MAX_WEIGHT_KG = 250.0
_DEFAULT_HEIGHT_CM = 170.0
_DEFAULT_WEIGHT_KG = 70.0
# NHS / clinical safe weekly weight-change rate (kg/week). Mirrors the bound the
# goal-projection already references; clamped here before it can drive volume.
_MAX_SAFE_WEEKLY_RATE_KG = 0.9
# BMI floor — a goal weight implying a BMI below this is unsafe; clamp the goal
# up to the weight that yields exactly this BMI for the user's height.
_MIN_SAFE_BMI = 18.5


def clamp_days_per_week(days_per_week: Any) -> int:
    """Clamp days_per_week into [1, 6]. Non-int / None / <=0 → 1.

    7 is intentionally clamped to 6: the 7th day must remain rest /
    active-recovery, never a 7th hard session (see reconcile_workout_days).
    """
    n = _coerce_positive_int(days_per_week)
    if n is None:
        return DAYS_PER_WEEK_MIN
    return max(DAYS_PER_WEEK_MIN, min(DAYS_PER_WEEK_MAX, n))


def reconcile_workout_days(
    workout_days: Optional[List[int]],
    days_per_week: Optional[int],
) -> List[int]:
    """Return a clean weekday list (0=Mon..6=Sun) reconciled with days_per_week.

    Guarantees:
      - every entry is an int in [0,6], de-duplicated, sorted;
      - at most 6 training days (a 7th weekday is dropped so it stays rest);
      - the count matches the clamped days_per_week when that is supplied:
        too many → trim the tail; too few → leave as-is (caller fills via the
        normal split logic — we never invent arbitrary days here);
      - empty / malformed input with a positive days_per_week → the first N
        weekdays (Mon-first) so generation never sees 0 days.
    """
    capped_dpw = clamp_days_per_week(days_per_week) if days_per_week is not None else None

    cleaned: List[int] = []
    seen: set = set()
    for d in (workout_days or []):
        di = _coerce_day_index(d)
        if di is not None and di not in seen:
            seen.add(di)
            cleaned.append(di)
    cleaned.sort()

    # Never allow 7 hard days — drop the overflow so day 7 stays rest.
    if len(cleaned) > DAYS_PER_WEEK_MAX:
        cleaned = cleaned[:DAYS_PER_WEEK_MAX]

    if capped_dpw is not None:
        if not cleaned:
            # Backfill the first N weekdays so generation has a schedule.
            cleaned = list(range(capped_dpw))
        elif len(cleaned) > capped_dpw:
            cleaned = cleaned[:capped_dpw]
    return cleaned


def _coerce_day_index(value: Any) -> Optional[int]:
    """Coerce a weekday value to int in [0,6], else None."""
    try:
        di = int(value)
    except (TypeError, ValueError):
        return None
    return di if 0 <= di <= 6 else None


def clamp_session_minutes(duration_minutes: Any, default: int = 45) -> int:
    """Clamp a session length up to MIN_SESSION_MINUTES; 0/None/garbage → default.

    Never returns below MIN_SESSION_MINUTES so the duration→exercise-count math
    downstream can't collapse to 0 exercises on a degenerate request.
    """
    n = _coerce_positive_int(duration_minutes)
    if n is None:
        n = default
    return max(MIN_SESSION_MINUTES, n)


def normalize_body_measurements(
    height_cm: Any,
    weight_kg: Any,
) -> Dict[str, float]:
    """Guard + sanity-check height/weight before any BMR/BMI/duration math.

    Returns {"height_cm", "weight_kg", "weight_normalized"} with:
      - missing / zero / out-of-range height → _DEFAULT_HEIGHT_CM;
      - missing / zero weight → _DEFAULT_WEIGHT_KG;
      - a "kg" weight that's clearly a lb value (e.g. 200 "kg" for a 175cm
        person) divided by 2.20462 and flagged via weight_normalized=True. We
        only convert when the raw value is above the human-kg ceiling AND the
        lb→kg conversion lands in a plausible kg range — never touch a value
        that's already plausible as kg.
    """
    h = _coerce_float(height_cm)
    w = _coerce_float(weight_kg)

    if h is None or h <= 0 or h < _MIN_HEIGHT_CM or h > _MAX_HEIGHT_CM:
        h = _DEFAULT_HEIGHT_CM

    weight_normalized = False
    if w is None or w <= 0:
        w = _DEFAULT_WEIGHT_KG
    elif w > _MAX_WEIGHT_KG:
        # Possibly a lb value mislabeled kg. Convert and accept only if the
        # result is a plausible human kg; otherwise clamp to the kg ceiling.
        as_kg = w / 2.20462
        if _MIN_WEIGHT_KG <= as_kg <= _MAX_WEIGHT_KG:
            w = round(as_kg, 1)
            weight_normalized = True
        else:
            w = _MAX_WEIGHT_KG
    elif w < _MIN_WEIGHT_KG:
        w = _MIN_WEIGHT_KG

    return {"height_cm": h, "weight_kg": w, "weight_normalized": weight_normalized}


def clamp_goal_and_rate(
    current_weight_kg: Any,
    goal_weight_kg: Any,
    weekly_rate_kg: Any,
    height_cm: Any = None,
) -> Dict[str, Any]:
    """Clamp a goal weight + weekly change rate to clinically safe bounds.

    - weekly_rate magnitude is capped at _MAX_SAFE_WEEKLY_RATE_KG (NHS rule),
      preserving sign (gain vs loss);
    - a goal weight implying BMI < _MIN_SAFE_BMI is raised to the weight that
      yields exactly _MIN_SAFE_BMI for the given height (when height is usable).

    Returns {"goal_weight_kg", "weekly_rate_kg", "goal_clamped", "rate_clamped"}.
    Any field that's missing/unusable is returned as-is (None) and not clamped —
    fail-open: a request that doesn't carry a goal is untouched.
    """
    goal = _coerce_float(goal_weight_kg)
    rate = _coerce_float(weekly_rate_kg)
    cur = _coerce_float(current_weight_kg)
    h = _coerce_float(height_cm)

    rate_clamped = False
    if rate is not None:
        capped = max(-_MAX_SAFE_WEEKLY_RATE_KG, min(_MAX_SAFE_WEEKLY_RATE_KG, rate))
        if capped != rate:
            rate_clamped = True
        rate = capped

    goal_clamped = False
    if goal is not None and h is not None and _MIN_HEIGHT_CM <= h <= _MAX_HEIGHT_CM:
        h_m = h / 100.0
        min_safe_weight = _MIN_SAFE_BMI * h_m * h_m
        if goal < min_safe_weight:
            goal = round(min_safe_weight, 1)
            goal_clamped = True

    return {
        "goal_weight_kg": goal,
        "weekly_rate_kg": rate,
        "goal_clamped": goal_clamped,
        "rate_clamped": rate_clamped,
    }


def _coerce_float(value: Any) -> Optional[float]:
    """Coerce a value to float, or None if not parseable."""
    if value is None:
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


# ============================================================================
# Generation idempotency (Phase E2) — short-lived in-process dedupe.
#
# A rapid double-tap "generate"/"regenerate" must not create two workouts.
# We hash the request signature (user + target window + the few fields that
# change output) and hold the hash for a short TTL. The SECOND call within the
# window sees the in-flight marker and the caller returns the just-created
# result instead of generating again. In-process only (mirrors the
# auto_generate_workout per-worker set); the cross-worker DB unique index
# (workouts_one_current_per_user_day) remains the durable backstop.
# ============================================================================

import hashlib as _hashlib
import threading as _threading

_GEN_IDEMPOTENCY_TTL_SECONDS = 8.0
_gen_idempotency_lock = _threading.Lock()
# request_hash -> inserted_at (monotonic seconds)
_gen_idempotency_seen: Dict[str, float] = {}


def generation_request_hash(user_id: str, *parts: Any) -> str:
    """Stable hash of a generation request's identity-bearing fields.

    `parts` should be the fields that determine the OUTPUT slot — typically the
    target date/window and the workout_id (regenerate) or scheduled_date
    (generate). Order-stable; None-safe.
    """
    raw = "|".join([str(user_id)] + [("" if p is None else str(p)) for p in parts])
    return _hashlib.sha256(raw.encode("utf-8")).hexdigest()


def claim_generation_slot(request_hash: str, ttl_seconds: float = _GEN_IDEMPOTENCY_TTL_SECONDS) -> bool:
    """Try to claim a generation slot for `request_hash`.

    Returns True if this caller is the FIRST within the TTL window (proceed with
    generation); False if a duplicate is already in-flight (caller should return
    the existing/just-created result instead of generating again). Evicts
    expired entries on each call so the map stays small. Fail-open: any internal
    error returns True (never blocks a legitimate generation).
    """
    try:
        now = time.monotonic()
        with _gen_idempotency_lock:
            # Evict expired.
            expired = [k for k, t in _gen_idempotency_seen.items() if now - t > ttl_seconds]
            for k in expired:
                _gen_idempotency_seen.pop(k, None)
            if request_hash in _gen_idempotency_seen:
                return False
            _gen_idempotency_seen[request_hash] = now
            return True
    except Exception:
        return True


def release_generation_slot(request_hash: str) -> None:
    """Release a previously claimed slot (e.g. on generation failure so a retry
    isn't suppressed). Best-effort; safe to call with an unknown hash."""
    try:
        with _gen_idempotency_lock:
            _gen_idempotency_seen.pop(request_hash, None)
    except Exception:
        pass


def parse_json_field(value, default):
    """Parse a field that could be a JSON string or already parsed."""
    if value is None:
        return default
    if isinstance(value, str):
        try:
            return json.loads(value)
        except json.JSONDecodeError:
            return default
    return value if isinstance(value, (list, dict)) else default


def equipment_dual_write_payload(value) -> dict:
    """Build a partial payload that writes BOTH the legacy `equipment`
    VARCHAR-of-JSON column AND the new `equipment_v2` text[] column.

    During Deploy 1 → Deploy 3 of the users.equipment migration the two
    columns coexist; reads still use the old column but writes must
    populate both so the backfill stays current. Once Deploy 2 cuts
    reads over, this helper continues to maintain both for one more
    cycle, then Deploy 3 drops the old column and this helper becomes a
    no-op (returns just `equipment_v2`).

    Accepts the same shapes the migration's backfill handles:
        - list[str]                       → ['bodyweight', 'dumbbells']
        - JSON-array string '["..."]'     → parsed
        - CSV string 'bw, dumbbells'      → split
        - single value 'Bodyweight'       → ['bodyweight']
        - None / ''                       → ['bodyweight'] (defensive)

    All entries are lowercased + trimmed + deduped on the way in.
    """
    parsed: list[str]
    if value is None or (isinstance(value, str) and not value.strip()):
        parsed = ["bodyweight"]
    elif isinstance(value, list):
        parsed = [str(v).strip().lower() for v in value if str(v).strip()]
    elif isinstance(value, str):
        s = value.strip()
        if s.startswith("[") and s.endswith("]"):
            try:
                items = json.loads(s)
                parsed = [str(v).strip().lower() for v in items if str(v).strip()]
            except json.JSONDecodeError:
                parsed = ["bodyweight"]
        elif "," in s:
            parsed = [piece.strip().lower() for piece in s.split(",") if piece.strip()]
        else:
            parsed = [s.lower()]
    else:
        parsed = ["bodyweight"]

    if not parsed:
        parsed = ["bodyweight"]
    # Dedup while preserving order.
    seen: set = set()
    deduped = [p for p in parsed if not (p in seen or seen.add(p))]

    # Re-encode the legacy column as a JSON-array string for compatibility
    # with read sites that still call `parse_json_field`.
    return {
        "equipment": json.dumps(deduped),
        "equipment_v2": deduped,
    }


def normalize_goals_list(goals) -> List[str]:
    """Normalize goals to a list of strings from various DB formats."""
    if goals is None:
        return []

    if isinstance(goals, str):
        try:
            goals = json.loads(goals)
        except json.JSONDecodeError:
            return [goals] if goals.strip() else []

    if not isinstance(goals, list):
        return []

    result = []
    for item in goals:
        if isinstance(item, str):
            if item.strip():
                result.append(item.strip())
        elif isinstance(item, dict):
            goal_name = (
                item.get("name") or
                item.get("goal") or
                item.get("title") or
                item.get("value") or
                item.get("id") or
                str(item)
            )
            if goal_name and isinstance(goal_name, str):
                result.append(goal_name.strip())

    return result


def get_intensity_from_fitness_level(fitness_level: Optional[str]) -> str:
    """Derive workout intensity/difficulty from user's fitness level."""
    if not fitness_level:
        return "medium"

    level_lower = fitness_level.lower().strip()
    if level_lower == "beginner":
        return "easy"
    elif level_lower == "advanced":
        return "hard"
    else:
        return "medium"


def _coerce_positive_int(value: Any) -> Optional[int]:
    """Coerce a DB/JSON value (int, str, float, None) into a positive int or None."""
    if value is None:
        return None
    try:
        as_int = int(value)
    except (TypeError, ValueError):
        return None
    return as_int if as_int > 0 else None


def resolve_target_duration(
    body_duration: Optional[int],
    body_duration_min: Optional[int],
    body_duration_max: Optional[int],
    gym_profile: Optional[Dict[str, Any]],
    user: Optional[Dict[str, Any]],
    default: int = 45,
) -> Dict[str, int]:
    """Resolve the target workout duration from request body, gym profile, and user preferences.

    Resolution priority (first non-None wins per field):
        1. request body (body_duration / body_duration_min / body_duration_max)
        2. active gym profile (duration_minutes / _min / _max)
        3. users.preferences (workout_duration / workout_duration_min / workout_duration_max)
        4. ``default`` for the target only (min/max stay None if unspecified).

    The request body defaults to ``None`` (see ``GenerateWorkoutRequest`` in schemas.py)
    so we can tell "user didn't specify" from "user picked 45".

    Returns a dict with keys ``target``, ``min``, ``max`` — all positive ints or None
    (except ``target`` which always has a value because of the default fallback).
    """
    prefs: Dict[str, Any] = {}
    if user:
        raw_prefs = user.get("preferences")
        prefs = parse_json_field(raw_prefs, {}) if raw_prefs is not None else {}
        if not isinstance(prefs, dict):
            prefs = {}

    # Gym profile sources
    gym_target = _coerce_positive_int(gym_profile.get("duration_minutes")) if gym_profile else None
    gym_min = _coerce_positive_int(gym_profile.get("duration_minutes_min")) if gym_profile else None
    gym_max = _coerce_positive_int(gym_profile.get("duration_minutes_max")) if gym_profile else None

    # User preference sources
    pref_target = _coerce_positive_int(prefs.get("workout_duration"))
    pref_min = _coerce_positive_int(prefs.get("workout_duration_min"))
    pref_max = _coerce_positive_int(prefs.get("workout_duration_max"))

    body_target = _coerce_positive_int(body_duration)
    body_min = _coerce_positive_int(body_duration_min)
    body_max = _coerce_positive_int(body_duration_max)

    resolved_min = body_min if body_min is not None else (gym_min if gym_min is not None else pref_min)
    resolved_max = body_max if body_max is not None else (gym_max if gym_max is not None else pref_max)

    # Target: body -> gym -> user pref -> max -> default
    resolved_target = (
        body_target
        or gym_target
        or pref_target
        or resolved_max
        or default
    )

    return {
        "target": int(resolved_target),
        "min": resolved_min,
        "max": resolved_max,
    }


def get_all_equipment(user: dict) -> List[str]:
    """Get combined list of standard and custom equipment for a user."""
    standard = parse_json_field(user.get("equipment"), [])
    custom = parse_json_field(user.get("custom_equipment"), [])

    if not isinstance(standard, list):
        standard = []
    if not isinstance(custom, list):
        custom = []

    all_equipment = list(standard)
    for item in custom:
        if item and item not in all_equipment:
            all_equipment.append(item)

    return all_equipment


# Module-level cache for exercise library media URLs
_exercise_library_cache: Optional[Dict[str, Dict]] = None
_exercise_library_cache_time: float = 0
_EXERCISE_LIBRARY_CACHE_TTL = 300  # 5 minutes


def _get_exercise_library_url_map(db) -> Dict[str, Dict]:
    """Get cached exercise library URL map."""
    global _exercise_library_cache, _exercise_library_cache_time

    now = time.time()
    if _exercise_library_cache is not None and (now - _exercise_library_cache_time) < _EXERCISE_LIBRARY_CACHE_TTL:
        return _exercise_library_cache

    result = db.client.table("exercise_library_cleaned").select(
        "name, gif_url, video_url, image_url"
    ).execute()

    url_map: Dict[str, Dict] = {}
    if result.data:
        for row in result.data:
            lib_name = (row.get("name") or "").lower().strip()
            if not lib_name:
                continue
            new_entry = {
                "gif_url": row.get("gif_url"),
                "video_url": row.get("video_url"),
                "image_s3_path": row.get("image_url"),
            }
            existing = url_map.get(lib_name)
            if existing is None:
                url_map[lib_name] = new_entry
                continue
            # Deterministic merge: keep the variant that has more media. A row
            # with image_s3_path beats a row without one — kills the "tile vs
            # detail screen disagree on which dupe to use" race when the
            # library has multiple rows under the same display name.
            existing_score = sum(1 for v in existing.values() if v)
            new_score = sum(1 for v in new_entry.values() if v)
            if new_score > existing_score:
                url_map[lib_name] = new_entry

    _exercise_library_cache = url_map
    _exercise_library_cache_time = now
    return url_map


def enrich_exercises_with_video_urls(exercises: List[Dict], db=None) -> List[Dict]:
    """Enrich exercises with video/image URLs from the exercise library."""
    if not exercises:
        return exercises

    if db is None:
        db = get_supabase_db()

    exercise_names = []
    name_mapping = {}
    for ex in exercises:
        name = ex.get("name", "")
        if name:
            normalized = name.lower().strip()
            exercise_names.append(normalized)
            name_mapping[normalized] = name

    if not exercise_names:
        return exercises

    try:
        url_map = _get_exercise_library_url_map(db)

        if not url_map:
            logger.debug("No exercises found in library for media enrichment")
            return exercises

        from api.v1.library.utils import presign_s3_path, resolve_image_url

        enriched_count = 0
        for ex in exercises:
            ex_name = (ex.get("name") or "").lower().strip()
            if ex_name in url_map:
                urls = url_map[ex_name]
                if not ex.get("gif_url") and urls.get("gif_url"):
                    ex["gif_url"] = urls["gif_url"]
                    enriched_count += 1
                if not ex.get("video_url") and urls.get("video_url"):
                    # Presign S3 paths so clients get HTTPS URLs, not s3:// URIs
                    ex["video_url"] = presign_s3_path(urls["video_url"])
                    enriched_count += 1
                if not ex.get("image_s3_path") and urls.get("image_s3_path"):
                    ex["image_s3_path"] = resolve_image_url(urls["image_s3_path"])
                    enriched_count += 1

        if enriched_count > 0:
            logger.info(f"✅ Enriched {enriched_count} exercise media URLs from library")

    except Exception as e:
        logger.warning(f"⚠️ Failed to enrich exercises with media URLs: {e}", exc_info=True)

    return exercises


def row_to_workout(row: dict, enrich_videos: bool = True) -> Workout:
    """Convert a Supabase row dict to Workout model."""
    exercises_json = row.get("exercises_json") or row.get("exercises")

    if isinstance(exercises_json, str):
        try:
            exercises_list = json.loads(exercises_json)
        except json.JSONDecodeError:
            exercises_list = []
    elif isinstance(exercises_json, list):
        exercises_list = exercises_json
    else:
        exercises_list = []

    if enrich_videos and exercises_list:
        exercises_list = enrich_exercises_with_video_urls(exercises_list)

    # Structured tracking metadata (tracking_type + distance_meters + reps_spec)
    # so the workout-detail / active-workout client renders cardio / carry /
    # timed / bodyweight stations correctly instead of "weight × reps". Pure +
    # serve-time; response-only (never written back to the row).
    if isinstance(exercises_list, list) and exercises_list:
        from services.exercise_tracking_metric import attach_tracking_metadata
        attach_tracking_metadata(exercises_list)

    exercises_json = json.dumps(exercises_list) if exercises_list else "[]"

    generation_metadata = row.get("generation_metadata")
    if isinstance(generation_metadata, (dict, list)):
        generation_metadata = json.dumps(generation_metadata)

    modification_history = row.get("modification_history")
    if isinstance(modification_history, (dict, list)):
        modification_history = json.dumps(modification_history)

    return Workout(
        id=str(row.get("id")),
        user_id=str(row.get("user_id")),
        name=row.get("name") or "Workout",
        type=row.get("type") or "strength",
        difficulty=row.get("difficulty") or "intermediate",
        description=row.get("description"),
        scheduled_date=row.get("scheduled_date"),
        is_completed=row.get("is_completed", False),
        exercises_json=exercises_json,
        duration_minutes=row.get("duration_minutes", 45),
        created_at=row.get("created_at"),
        generation_method=row.get("generation_method"),
        generation_source=row.get("generation_source"),
        generation_metadata=generation_metadata,
        generated_at=row.get("generated_at"),
        last_modified_method=row.get("last_modified_method"),
        last_modified_at=row.get("last_modified_at"),
        modification_history=modification_history,
        version_number=row.get("version_number", 1),
        is_current=row.get("is_current", True),
        valid_from=row.get("valid_from"),
        valid_to=row.get("valid_to"),
        parent_workout_id=row.get("parent_workout_id"),
        superseded_by=row.get("superseded_by"),
        completed_at=row.get("completed_at"),
        completion_method=row.get("completion_method"),
        is_favorite=bool(row.get("is_favorite", False)),
    )


def log_workout_change(
    workout_id: str,
    user_id: str,
    change_type: str,
    field_changed: str = None,
    old_value=None,
    new_value=None,
    change_source: str = "api",
    change_reason: str = None
):
    """Log a change to a workout for audit trail."""
    try:
        db = get_supabase_db()
        change_data = {
            "workout_id": workout_id,
            "user_id": user_id,
            "change_type": change_type,
            "field_changed": field_changed,
            "old_value": json.dumps(old_value) if old_value is not None else None,
            "new_value": json.dumps(new_value) if new_value is not None else None,
            "change_source": change_source,
            "change_reason": change_reason,
        }
        db.create_workout_change(change_data)
        logger.debug(f"Logged workout change: workout_id={workout_id}, type={change_type}")
    except Exception as e:
        # FK violation on workout_changes_workout_id_fkey means the workout
        # was deleted/replaced between create and log (race with the
        # workouts_one_current_per_user_day refetch path, or a delete during
        # an in-flight modification). The audit log isn't user-facing and a
        # missing entry isn't worth a Sentry event — demote to WARNING so it
        # stays out of Sentry's default capture (Sentry PYTHON-FASTAPI-36).
        err_str = str(e)
        is_fk_violation = (
            "workout_changes_workout_id_fkey" in err_str
            or ("foreign key" in err_str.lower() and "workout_changes" in err_str)
            or "23503" in err_str  # Postgres foreign_key_violation
        )
        if is_fk_violation:
            logger.warning(
                f"Skipping workout_change log — workout {workout_id} no longer exists "
                f"(likely a refetch race or concurrent delete)"
            )
        else:
            logger.error(f"Failed to log workout change: {e}", exc_info=True)


async def index_workout_to_rag(workout: Workout):
    """Index a workout to RAG for retrieval (fire-and-forget)."""
    try:
        rag_service = get_workout_rag_service()
        exercises = json.loads(workout.exercises_json) if isinstance(workout.exercises_json, str) else workout.exercises_json
        scheduled_date = workout.scheduled_date
        if hasattr(scheduled_date, 'isoformat'):
            scheduled_date = scheduled_date.isoformat()
        await rag_service.index_workout(
            workout_id=workout.id,
            user_id=workout.user_id,
            name=workout.name,
            workout_type=workout.type,
            difficulty=workout.difficulty,
            exercises=exercises,
            scheduled_date=str(scheduled_date),
            is_completed=workout.is_completed,
            generation_method=workout.generation_method,
        )
    except Exception as e:
        logger.error(f"Failed to index workout to RAG: {e}", exc_info=True)


async def get_recently_used_exercises(user_id: str, days: int = 7) -> List[str]:
    """Get list of exercise names used by user in recent workouts."""
    try:
        db = get_supabase_db()
        cutoff_date = (datetime.now() - timedelta(days=days)).isoformat()

        response = db.client.table("workouts").select(
            "exercises_json"
        ).eq("user_id", user_id).gte(
            "scheduled_date", cutoff_date
        ).execute()

        if not response.data:
            return []

        recent_exercises = set()
        for workout in response.data:
            exercises_json = workout.get("exercises_json", [])
            if isinstance(exercises_json, str):
                try:
                    exercises_json = json.loads(exercises_json)
                except json.JSONDecodeError:
                    continue

            for exercise in exercises_json:
                if isinstance(exercise, dict):
                    name = exercise.get("name") or exercise.get("exercise_name")
                    if name:
                        recent_exercises.add(name)

        logger.info(f"Found {len(recent_exercises)} recently used exercises for user {user_id} (last {days} days)")
        return list(recent_exercises)

    except Exception as e:
        logger.error(f"Error getting recently used exercises: {e}", exc_info=True)
        return []


async def get_recent_workout_name_words(user_id: str, days: int = 14) -> List[str]:
    """Get significant words from recent workout names to avoid repetition."""
    try:
        db = get_supabase_db()
        cutoff_date = (datetime.now() - timedelta(days=days)).isoformat()
        response = db.client.table("workouts").select("name").eq(
            "user_id", user_id
        ).gte("scheduled_date", cutoff_date).neq("name", "Generating...").execute()

        if not response.data:
            return []

        from .schedule_utils import extract_name_words

        all_words = set()
        for workout in response.data:
            name = workout.get("name")
            if name:
                all_words.update(extract_name_words(name))

        logger.info(f"[NameDedup] {len(all_words)} name words to avoid for user (last {days} days)")
        return list(all_words)
    except Exception as e:
        logger.error(f"Error getting recent workout name words: {e}", exc_info=True)
        return []


# ============================================================================
# Re-exports from sub-modules for backwards compatibility
# ============================================================================

# schedule_utils
from .schedule_utils import (
    resolve_training_split,
    infer_workout_type_from_focus,
    get_workout_focus,
    extract_name_words,
)

# validation_utils
from .validation_utils import (
    validate_and_cap_exercise_parameters,
    enforce_set_rep_limits,
    truncate_exercises_to_duration,
    ABSOLUTE_MAX_REPS,
    ABSOLUTE_MAX_SETS,
    ABSOLUTE_MIN_REST,
    FITNESS_LEVEL_CAPS,
    HELL_MODE_CAPS,
    AGE_CAPS,
    HIGH_REP_EXERCISE_KEYWORDS,
    ADVANCED_EXERCISES_BLOCKLIST,
    is_high_rep_exercise,
    is_advanced_exercise,
    get_age_bracket_from_age,
)

# user_preference_utils
from .user_preference_utils import (
    fuzzy_exercise_match,
    get_user_strength_history,
    get_user_personal_bests,
    format_performance_context,
    get_user_favorite_exercises,
    get_user_consistency_mode,
    get_user_exercise_queue,
    mark_queued_exercises_used,
    get_user_staple_exercises,
    get_staple_names,
    get_user_variation_percentage,
    get_user_1rm_data,
    get_user_training_intensity,
    get_user_intensity_overrides,
    calculate_working_weight_from_1rm,
    apply_1rm_weights_to_exercises,
    get_user_avoided_exercises,
    get_user_avoided_muscles,
    get_user_progression_pace,
    get_user_workout_type_preference,
    get_substitute_exercise,
    auto_substitute_filtered_exercises,
)

# readiness_utils
from .readiness_utils import (
    INJURY_TO_AVOIDED_MUSCLES,
    get_user_readiness_score,
    get_user_latest_mood,
    get_muscles_to_avoid_from_injuries,
    adjust_workout_params_for_readiness,
    get_active_injuries_with_muscles,
    get_user_comeback_status,
    get_comeback_context,
    apply_comeback_adjustments_to_exercises,
    start_comeback_mode_if_needed,
    get_comeback_prompt_context,
    get_recovery_workout_signal,
    apply_recovery_adjustment,
)

# progression_utils
from .progression_utils import (
    get_user_rep_preferences,
    get_user_progression_context,
    build_progression_philosophy_prompt,
    get_user_workout_patterns,
    TRAINING_FOCUS_REP_RANGES,
    EXERCISE_PROGRESSION_CHAINS,
)

# hormonal_utils
from .hormonal_utils import (
    get_user_hormonal_context,
    adjust_workout_for_cycle_phase,
    get_kegel_exercises_for_workout,
)

# focus_validation_utils
from .focus_validation_utils import (
    validate_and_filter_focus_mismatches,
    validate_exercise_matches_focus,
    get_all_muscles_for_exercise,
    compare_muscle_profiles,
    get_user_favorite_workouts,
    build_favorite_workouts_context,
    FOCUS_AREA_MUSCLES,
    FOCUS_AREA_EXCLUDED_EXERCISES,
)
