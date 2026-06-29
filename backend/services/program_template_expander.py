"""
Program Template Expander - expands a `user_program_templates` row into
concrete `workouts` rows when the user schedules it.

Given (template, start_date, weeks, day_alignment, day_times) it produces one
`workouts` row per training day per week:
  - per-day user-local time anchoring (day_times -> noon default) (T1/T2/T5)
  - staple injection when template.apply_staples=true, reusing the existing
    preference-engine staple logic (Group 8 S1-S4)
  - deload weeks marked intensity_mode='deload' (#45)
  - rest days skipped (#34)
  - week-1 target weights seeded from personal_records 1RM (#42)
  - transaction-wrapped, all-or-nothing (#38)
  - idempotent: dedupes on (template_id, week, day_index, scheduled_date)
    via the unique index from migration 2087 (#39/#69)

Edge cases covered: Group 3 (#28-41), Group 4 seeding (#42), Group 7 (#69-72),
Group 8 staples + times (S1-S6, T1-T5).
"""
from __future__ import annotations

import logging
import os
import uuid
from datetime import date, datetime, time, timedelta
from typing import Any, Dict, List, Optional

import psycopg2
import psycopg2.extras

from core.supabase_client import get_supabase

logger = logging.getLogger(__name__)

# Hard cap on generated workouts (#41): 12 weeks * 7-day week.
MAX_TOTAL_WORKOUTS = 84
MAX_WEEKS = 12


# ---------------------------------------------------------------------------
# Per-day collision resolution (assign / assign-preview parity)
# ---------------------------------------------------------------------------
# A single source of truth for "what happens on a date that already has a
# workout", shared by _build_assign_preview (the dry-run the client renders) AND
# the expander (what assign actually materializes). Returning the SAME value
# from one function is what guarantees the preview can never drift from the
# commit. Vocabulary:
#   "add"     - no existing workout that day → just create the new one.
#   "stack"   - keep the existing AND add the new (new tagged program_slot
#               'addon' so it shows as an extra alongside, not a replacement).
#   "replace" - remove the existing workout(s) that day and create the new one.
#
# A per-day OVERRIDE in `day_resolutions` (ISO date → "replace" | "add") is
# authoritative: it wins even on a date with no materialized row, so the user's
# explicit choice on a conflict card is always honored identically by preview
# and commit. With no override, conflicts fall back to slot/replace defaults
# (primary+replace → replace; addon or primary run-alongside → stack).
def resolve_collision(
    *,
    date_iso: str,
    has_existing: bool,
    slot: str,
    replace: bool,
    day_resolutions: Optional[Dict[str, str]] = None,
) -> str:
    """Resolve one date to 'add' | 'stack' | 'replace'. See module note above."""
    override = (day_resolutions or {}).get(date_iso)
    if override == "add":
        return "stack"
    if override == "replace":
        return "replace"
    if not has_existing:
        return "add"
    if (slot or "primary") == "addon":
        return "stack"
    if (slot or "primary") == "primary" and replace:
        return "replace"
    return "stack"  # primary, run-alongside


def _find_colliding_workouts(
    user_id: str, dates: List[str]
) -> Dict[str, List[str]]:
    """Map ISO date 'YYYY-MM-DD' → [workout_id, ...] of existing schedulable
    workouts on that date. Mirrors the assign-preview collision filter: drops
    health-connect imports + completed/skipped rows (those are never replaced).
    Best-effort — any read error returns {} so scheduling never fails on the
    collision probe (the program just stacks rather than replacing)."""
    if not dates:
        return {}
    dateset = set(dates)
    db = get_supabase()
    out: Dict[str, List[str]] = {}
    try:
        lo = min(dates)
        hi = (date.fromisoformat(max(dates)) + timedelta(days=1)).isoformat()
        resp = (
            db.client.table("workouts")
            .select(
                "id, scheduled_date, status, generation_method"
            )
            .eq("user_id", user_id)
            .gte("scheduled_date", lo)
            .lte("scheduled_date", hi)
            .execute()
        )
        for w in resp.data or []:
            if (w.get("generation_method") or "") == "health_connect_import":
                continue
            if (w.get("status") or "") in ("completed", "skipped"):
                continue
            sd = (w.get("scheduled_date") or "")[:10]
            if sd in dateset:
                out.setdefault(sd, []).append(str(w["id"]))
    except Exception as e:  # noqa: BLE001 — collision probe is best-effort
        logger.warning("collision lookup failed for %s: %s", user_id, e)
        return {}
    return out


# ---------------------------------------------------------------------------
# DB DSN helper - psycopg2 wants a plain postgresql:// DSN with sslmode.
# ---------------------------------------------------------------------------
def _psycopg_dsn() -> str:
    dsn = os.environ.get("DATABASE_URL", "")
    if not dsn:
        raise RuntimeError("DATABASE_URL is not set")
    dsn = dsn.replace("postgresql+asyncpg://", "postgresql://")
    if "sslmode" not in dsn:
        sep = "&" if "?" in dsn else "?"
        dsn = dsn + sep + "sslmode=require"
    return dsn


# ---------------------------------------------------------------------------
# Time anchoring
# ---------------------------------------------------------------------------
def _parse_hhmm(value: Optional[str]) -> time:
    """Parse 'HH:MM' to a time; default to noon (T2)."""
    if not value:
        return time(12, 0)
    try:
        parts = str(value).split(":")
        return time(int(parts[0]), int(parts[1]) if len(parts) > 1 else 0)
    except Exception:  # noqa: BLE001
        return time(12, 0)


def _anchored_scheduled_date(day: date, t: time) -> str:
    """Combine a calendar date + user-local time into an ISO datetime string.

    Stored as a naive local datetime (no UTC offset) so the wall-clock time
    the user picked survives DST and timezone travel (T4/T5, #35/#74),
    consistent with the noon-user-local anchoring pattern from commit
    8bc847f2.
    """
    return datetime.combine(day, t).isoformat()


# ---------------------------------------------------------------------------
# Week-1 weight seeding from personal_records
# ---------------------------------------------------------------------------
def _seed_target_weights(
    user_id: str, exercise_names: List[str]
) -> Dict[str, float]:
    """Return {exercise_name_lower: working_weight_kg} seeded from the user's
    most recent 1RM estimate (#42). Working weight ~= 75% of estimated 1RM.
    Exercises with no PR are simply absent from the map.
    """
    if not exercise_names:
        return {}
    db = get_supabase()
    seeds: Dict[str, float] = {}
    try:
        resp = (
            db.client.table("personal_records")
            .select("exercise_name, estimated_1rm_kg, weight_kg, achieved_at")
            .eq("user_id", user_id)
            .order("achieved_at", desc=True)
            .execute()
        )
        wanted = {n.lower() for n in exercise_names}
        for row in resp.data or []:
            name = (row.get("exercise_name") or "").lower()
            if name not in wanted or name in seeds:
                continue
            one_rm = row.get("estimated_1rm_kg") or row.get("weight_kg")
            if one_rm:
                seeds[name] = round(float(one_rm) * 0.75, 2)
    except Exception as e:  # noqa: BLE001 - seeding is best-effort
        logger.warning("PR weight seeding failed for %s: %s", user_id, e)
    return seeds


# ---------------------------------------------------------------------------
# Staple loading + injection (reuses the preference-engine helpers)
# ---------------------------------------------------------------------------
def _load_staples_for_profile(
    user_id: str, gym_profile_id: Optional[str]
) -> List[Dict[str, Any]]:
    """Load the user's staples scoped to the expansion gym profile (S4):
    only staples whose gym_profile_id matches OR is null ('All Profiles').
    """
    db = get_supabase()
    try:
        resp = (
            db.client.table("user_staples_with_details")
            .select("*")
            .eq("user_id", user_id)
            .execute()
        )
        rows = resp.data or []
    except Exception:  # noqa: BLE001 - fall back to base table
        try:
            resp = (
                db.client.table("staple_exercises")
                .select("*")
                .eq("user_id", user_id)
                .execute()
            )
            rows = resp.data or []
        except Exception as e:  # noqa: BLE001
            logger.warning("Staple load failed for %s: %s", user_id, e)
            return []
    scoped: List[Dict[str, Any]] = []
    for s in rows:
        sp = s.get("gym_profile_id")
        if sp is None or str(sp) == str(gym_profile_id):
            scoped.append(s)
    return scoped


def _inject_staples(
    day_exercises: List[Dict[str, Any]],
    staples: List[Dict[str, Any]],
) -> Dict[str, List[Dict[str, Any]]]:
    """Inject staples per section, reusing the preference-engine param +
    builder helpers. Returns {'warmup': [...], 'main': [...], 'stretch': [...]}.

    - warmup staples prepended (own section)
    - stretch/cooldown staples appended (own section)
    - main staples merged into the main exercise list
    - S3: a staple already present in that day's exercises is NOT injected
    """
    from api.v1.workouts.preference_engine import (
        get_exercise_params,
        _build_exercise_object,
    )

    existing_lower = {
        (ex.get("name") or "").lower() for ex in day_exercises
    }
    warmup: List[Dict[str, Any]] = []
    stretch: List[Dict[str, Any]] = []
    main_extra: List[Dict[str, Any]] = []

    for staple in staples:
        name = staple.get("exercise_name") or staple.get("name")
        if not name or name.lower() in existing_lower:
            continue  # S3 dedupe
        section = (staple.get("section") or "main").lower()
        try:
            params = get_exercise_params(
                name, staple, user_overrides=staple
            )
            obj = _build_exercise_object(name, staple, params, order=1)
        except Exception as e:  # noqa: BLE001 - one bad staple never aborts
            logger.warning("Staple build failed for '%s': %s", name, e)
            continue
        obj["is_staple"] = True
        if section in ("warmup", "warm-up"):
            warmup.append(obj)
        elif section in ("stretch", "stretches", "cooldown", "cool-down"):
            stretch.append(obj)
        else:
            main_extra.append(obj)
        existing_lower.add(name.lower())

    return {"warmup": warmup, "main": main_extra, "stretch": stretch}


# ---------------------------------------------------------------------------
# Library-metadata lookup (process-cached: a program repeats the same exercise
# across many weeks/days, so we never re-query the same exercise_id twice).
# ---------------------------------------------------------------------------
_LIBRARY_META_CACHE: Dict[str, Optional[Dict[str, Any]]] = {}


def _library_meta_for(exercise_id: Optional[str]) -> Optional[Dict[str, Any]]:
    """Fetch the canonical exercise_library row (equipment/is_timed/
    movement_pattern/default_hold_seconds) for an exercise_id, cached per
    process. Fail-open: any error returns None so expansion never blocks."""
    if not exercise_id:
        return None
    if exercise_id in _LIBRARY_META_CACHE:
        return _LIBRARY_META_CACHE[exercise_id]
    meta: Optional[Dict[str, Any]] = None
    try:
        from core.db import get_supabase_db
        db = get_supabase_db()
        res = (
            db.client.table("exercise_library")
            .select("equipment,is_timed,movement_pattern,default_hold_seconds")
            .eq("id", exercise_id)
            .limit(1)
            .execute()
        )
        if res.data:
            meta = res.data[0]
    except Exception:  # noqa: BLE001 — never block expansion on a lookup
        meta = None
    _LIBRARY_META_CACHE[exercise_id] = meta
    return meta


# ---------------------------------------------------------------------------
# Per-day -> exercises_json
# ---------------------------------------------------------------------------
def _day_to_exercises_json(
    day: Dict[str, Any],
    seed_weights: Dict[str, float],
    is_deload: bool,
) -> List[Dict[str, Any]]:
    """Build the literal `exercises_json` list for one template day."""
    out: List[Dict[str, Any]] = []
    for i, ex in enumerate(day.get("exercises") or []):
        name = ex.get("name") or ex.get("original_name") or ""
        weight = ex.get("target_weight_kg")
        if weight is None:
            weight = seed_weights.get(name.lower())
        if weight is not None and is_deload:
            # Scheduled deload week: ~60% load, same sets/reps (#45).
            weight = round(float(weight) * 0.6, 2)
        obj: Dict[str, Any] = {
            "name": name,
            "exercise_id": ex.get("exercise_id"),
            "order": i + 1,
            "sets": ex.get("sets", 3),
            "reps": ex.get("reps"),
            "reps_spec": ex.get("reps_spec"),
            "per_side": ex.get("per_side", False),
            "rest_seconds": ex.get("rest_seconds", 60),
            "target_rir": ex.get("target_rir"),
            "set_type": ex.get("set_type", "normal"),
            "notes": ex.get("notes", ""),
        }
        if ex.get("superset_group"):
            obj["superset_group"] = ex["superset_group"]
        if weight is not None:
            obj["weight_kg"] = weight
        if ex.get("unresolved"):
            obj["unresolved"] = True
        # Bake tracking_type + distance_meters at EXPANSION time, while the
        # unit-bearing reps_spec ("1000 m", "8 minutes") is still intact — a
        # later AI-tailoring pass may rewrite reps into bare numbers and destroy
        # the unit. Only set the two new keys; leave the structured reps_spec
        # dict untouched for downstream readers (serve-time stringifies it).
        try:
            from services.exercise_tracking_metric import derive_tracking_metadata
            # Consult the canonical library row first (authoritative equipment /
            # is_timed / movement_pattern) so the derived tracking_type +
            # metric_keys are correct even when the template blob is sparse.
            _lib = _library_meta_for(ex.get("exercise_id"))
            _tm = derive_tracking_metadata(obj, library_meta=_lib)
            if _tm.get("tracking_type"):
                obj["tracking_type"] = _tm["tracking_type"]
            if _tm.get("metric_keys"):
                obj["metric_keys"] = _tm["metric_keys"]
            if _tm.get("distance_meters") is not None:
                obj["distance_meters"] = _tm["distance_meters"]
            # Pass through authoritative library fields so the client has them.
            if _lib:
                if _lib.get("equipment") is not None:
                    obj["equipment"] = _lib["equipment"]
                if _lib.get("is_timed") is not None:
                    obj["is_timed"] = _lib["is_timed"]
        except Exception:
            pass  # never block program expansion on metadata derivation
        out.append(obj)
    return out


# ---------------------------------------------------------------------------
# Main expansion entry point
# ---------------------------------------------------------------------------
def plan_template_days(
    days: List[Dict[str, Any]],
    *,
    week_length: int,
    deload_every: Optional[int],
    start_date: date,
    weeks: int,
    day_alignment: str,
    day_times: Dict[str, str],
    assigned_days: Optional[List[int]] = None,
) -> Dict[str, Any]:
    """Pure date planner shared by [expand_template] (to build rows) and the
    assign-preview dry-run (to SHOW the schedule). NO DB writes.

    Given the template `days` blob + scheduling inputs, computes — for every
    training day of every week — the exact calendar date, anchored datetime, and
    deload flag, using the IDENTICAL mapping `expand_template` writes with. This
    is the single source of truth for "which date a program day lands on", so a
    preview can never drift from what assignment actually creates.

    Returns {"planned": [ {week, day, day_index, target_date, scheduled,
    is_deload} ... ], "deload_weeks": [int...]} in insert order. Raises
    ValueError on invalid input / cap breaches (same caps as expand_template).
    """
    training_days = [d for d in days if not d.get("is_rest")]
    if not training_days:
        raise ValueError("Template has no training days to schedule")
    if weeks < 1:
        raise ValueError("weeks must be >= 1")
    if weeks > MAX_WEEKS:
        raise ValueError(f"weeks capped at {MAX_WEEKS}")

    total_training = len(training_days) * weeks
    if total_training > MAX_TOTAL_WORKOUTS:
        raise ValueError(
            f"This schedule would create {total_training} workouts; "
            f"the cap is {MAX_TOTAL_WORKOUTS}. Reduce weeks or training days."
        )

    week_length = int(week_length or 7)

    # When the caller pins weekdays (program-assign: assigned_days e.g. [1,3,5]),
    # the template's k-th training day → assigned_days[k] (cycling). Mirrors the
    # weekday_targets branch in expand_template exactly.
    weekday_targets: Optional[List[int]] = None
    if assigned_days and week_length == 7:
        weekday_targets = sorted(
            {int(d) for d in assigned_days if 0 <= int(d) <= 6}
        )
    training_day_indices = [
        int(d.get("day_index", 0)) for d in days if not d.get("is_rest")
    ]
    _training_ordinal = {di: k for k, di in enumerate(training_day_indices)}

    deload_weeks: List[int] = []
    planned: List[Dict[str, Any]] = []

    for week in range(1, weeks + 1):
        is_deload = bool(
            deload_every and deload_every > 0 and week % deload_every == 0
        )
        if is_deload:
            deload_weeks.append(week)

        for day in days:
            if day.get("is_rest"):
                continue
            day_index = int(day.get("day_index", 0))
            offset_days = (week - 1) * week_length + day_index

            if weekday_targets:
                ordinal = _training_ordinal.get(day_index, 0)
                target_weekday = weekday_targets[ordinal % len(weekday_targets)]
                start_weekday = start_date.weekday()  # Mon=0
                lead = (target_weekday - start_weekday) % 7
                target_date = start_date + timedelta(days=(week - 1) * 7 + lead)
            elif day_alignment == "calendar_weekday" and week_length == 7:
                start_weekday = start_date.weekday()  # Mon=0
                lead = (day_index - start_weekday) % 7
                target_date = start_date + timedelta(days=(week - 1) * 7 + lead)
            else:
                target_date = start_date + timedelta(days=offset_days)

            t = _parse_hhmm(day_times.get(str(day_index)))
            scheduled = _anchored_scheduled_date(target_date, t)

            planned.append({
                "week": week,
                "day": day,
                "day_index": day_index,
                "target_date": target_date,
                "scheduled": scheduled,
                "is_deload": is_deload,
            })

    return {"planned": planned, "deload_weeks": deload_weeks}


def expand_template(
    template: Dict[str, Any],
    schedule_id: str,
    user_id: str,
    start_date: date,
    weeks: int,
    day_alignment: str,
    day_times: Dict[str, str],
    gym_profile_id: Optional[str] = None,
    assignment_id: Optional[str] = None,
    program_slot: Optional[str] = None,
    assigned_days: Optional[List[int]] = None,
    replace: bool = True,
    day_resolutions: Optional[Dict[str, str]] = None,
    resolve_collisions: bool = False,
) -> Dict[str, Any]:
    """Expand a template into `workouts` rows inside a single DB transaction.

    Args:
        template: the user_program_templates row (must include `days`).
        schedule_id: the user_program_schedules row id (provenance).
        user_id: owner.
        start_date: first calendar date.
        weeks: number of weeks to expand (capped at MAX_WEEKS).
        day_alignment: 'start_today' | 'calendar_weekday'.
        day_times: {str(day_index): 'HH:MM'} user-local times.
        gym_profile_id: the active gym profile rows are tagged with (#36).
        replace: primary-slot default for conflicting dates (True → replace the
            existing workout, False → run alongside). Only consulted when
            resolve_collisions=True.
        day_resolutions: optional {ISO date → "replace" | "add"} per-day override
            of the conflict outcome (authoritative on that date).
        resolve_collisions: when True, each date is checked against existing
            workouts and materialized per resolve_collision() (assign path).
            When False (plain /schedule), rows are inserted as-is — no deletes,
            no re-tagging — preserving the original behavior.

    Returns:
        {"workouts_created": int, "deload_weeks": [int...],
         "skipped_existing": int, "total_attempted": int}

    Raises ValueError on invalid input; the transaction guarantees no partial
    rows on any failure (#38).
    """
    days = template.get("days") or []
    week_length = int(template.get("week_length") or 7)
    deload_every = template.get("deload_every_n_weeks")
    apply_staples = bool(template.get("apply_staples", True))
    template_id = template["id"]

    # Single source of truth for which date each training day lands on; the
    # assign-preview dry-run calls the SAME planner so the preview matches.
    plan = plan_template_days(
        days,
        week_length=week_length,
        deload_every=deload_every,
        start_date=start_date,
        weeks=weeks,
        day_alignment=day_alignment,
        day_times=day_times,
        assigned_days=assigned_days,
    )
    planned = plan["planned"]
    deload_weeks = plan["deload_weeks"]

    # Seed week-1 weights from PRs once (#42).
    all_names: List[str] = []
    for d in (d for d in days if not d.get("is_rest")):
        for ex in d.get("exercises") or []:
            n = ex.get("name") or ex.get("original_name")
            if n:
                all_names.append(n)
    seed_weights = _seed_target_weights(user_id, all_names)

    # Load staples once if needed (S1/S4).
    staples = (
        _load_staples_for_profile(user_id, gym_profile_id)
        if apply_staples
        else []
    )

    rows_to_insert: List[Dict[str, Any]] = []

    for p in planned:
        week = p["week"]
        day = p["day"]
        day_index = p["day_index"]
        is_deload = p["is_deload"]
        scheduled = p["scheduled"]

        exercises_json = _day_to_exercises_json(
            day, seed_weights, is_deload
        )

        workout_type = day.get("workout_type", "strength")
        # workouts.difficulty is NOT-NULL (easy|medium|hard|hell). Read it
        # from the template day; safe fallback 'medium' for any older
        # authored template whose days[] predates the difficulty key.
        difficulty = day.get("difficulty") or "medium"
        row: Dict[str, Any] = {
            "id": str(uuid.uuid4()),
            "user_id": user_id,
            "name": day.get("day_name") or f"Day {day_index + 1}",
            "description": (
                f"{template.get('name', 'Program')} - week {week}"
            ),
            "scheduled_date": scheduled,
            "exercises_json": psycopg2.extras.Json(exercises_json),
            # workouts_status_check allows scheduled | completed | missed |
            # skipped | rescheduled | generating - a future expanded
            # workout is 'scheduled'.
            "status": "scheduled",
            # is_current=false: these are forward-scheduled rows, not the
            # live "current" workout. The partial unique index
            # workouts_one_current_per_user_day only permits ONE
            # is_current=true row per user per day - a 6-week expansion
            # must not claim all of them, and must not collide with an
            # existing AI-plan workout on the same date. today.py serves
            # by scheduled_date, not is_current.
            "is_current": False,
            "is_completed": False,
            "type": workout_type,
            "difficulty": difficulty,
            "generation_source": "template",
            "generation_method": "program_template",
            "template_id": template_id,
            "template_week": week,
            "template_day_index": day_index,
            "intensity_mode": "deload" if is_deload else "normal",
            "gym_profile_id": gym_profile_id,
            # Intra-day ordering (migration 2294): the template day index gives a
            # stable order for any sessions that share a date (today.py orders by
            # slot, then display_order, then created_at).
            "display_order": day_index,
        }
        # Program-assignment tagging (migration 2285) — lets today.py label
        # the carousel (program name/week/slot) by resolving the assignment.
        if assignment_id:
            row["assignment_id"] = assignment_id
        if program_slot:
            row["program_slot"] = program_slot

        if apply_staples and staples:
            injected = _inject_staples(day.get("exercises") or [], staples)
            if injected["warmup"]:
                row["warmup_json"] = psycopg2.extras.Json(
                    injected["warmup"]
                )
            if injected["stretch"]:
                row["stretch_json"] = psycopg2.extras.Json(
                    injected["stretch"]
                )
            if injected["main"]:
                merged = exercises_json + injected["main"]
                for idx, ex in enumerate(merged):
                    ex["order"] = idx + 1
                row["exercises_json"] = psycopg2.extras.Json(merged)

        rows_to_insert.append(row)

    # ----- per-day collision resolution (assign path only) -----------------
    supersede_ids: List[str] = []
    if resolve_collisions:
        supersede_ids = _apply_collision_resolution(
            rows_to_insert,
            user_id=user_id,
            slot=program_slot,
            replace=replace,
            day_resolutions=day_resolutions,
        )

    # ----- transactional insert (all-or-nothing, idempotent) ---------------
    created, skipped, superseded = _insert_workout_rows(
        rows_to_insert, supersede_ids
    )

    logger.info(
        "Expanded template %s: %d workouts created, %d skipped (idempotent), "
        "%d superseded, deload weeks=%s",
        template_id, created, skipped, superseded, deload_weeks,
    )
    return {
        "workouts_created": created,
        "skipped_existing": skipped,
        "superseded_existing": superseded,
        "total_attempted": len(rows_to_insert),
        "deload_weeks": deload_weeks,
        "schedule_id": schedule_id,
    }


def _insert_workout_rows(
    rows_to_insert: List[Dict[str, Any]],
    supersede_ids: Optional[List[str]] = None,
) -> tuple:
    """Transactional, all-or-nothing, idempotent insert of workout rows. Dedupes
    on uq_workouts_template_slot (template_id, template_week, template_day_index,
    scheduled_date) so a double-tap / concurrent schedule is a no-op (#39/#69).

    When `supersede_ids` is given (the existing workouts on dates the user/slot
    resolved to "replace"), those rows are DELETED in the SAME transaction as the
    insert — so replace is atomic with the new program landing (never a window
    where the date has neither workout). Only non-completed/non-skipped rows are
    removed (completed history is preserved even if mistakenly passed in).

    Returns (created, skipped, superseded). Shared by expand_template +
    expand_variant_weeks."""
    created = 0
    skipped = 0
    superseded = 0
    conn = psycopg2.connect(_psycopg_dsn())
    try:
        conn.autocommit = False
        with conn.cursor() as cur:
            if supersede_ids:
                # Replace semantics: clear the colliding rows this program now
                # owns. Guard on status so completed/skipped history survives.
                cur.execute(
                    # workouts.id is uuid; supersede_ids arrive as text → cast the
                    # array to uuid[] so ANY() type-matches (was: operator does not
                    # exist: uuid = text).
                    "DELETE FROM workouts WHERE id = ANY(%s::uuid[]) "
                    "AND is_completed = false "
                    "AND status NOT IN ('completed', 'skipped')",
                    ([str(x) for x in supersede_ids],),
                )
                superseded = cur.rowcount or 0
            for row in rows_to_insert:
                cols = list(row.keys())
                placeholders = ", ".join(["%s"] * len(cols))
                col_sql = ", ".join(cols)
                sql = (
                    f"INSERT INTO workouts ({col_sql}) "
                    f"VALUES ({placeholders}) "
                    f"ON CONFLICT (template_id, template_week, "
                    f"template_day_index, scheduled_date) "
                    f"WHERE template_id IS NOT NULL DO NOTHING "
                    f"RETURNING id"
                )
                cur.execute(sql, [row[c] for c in cols])
                if cur.fetchone():
                    created += 1
                else:
                    skipped += 1
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()
    return created, skipped, superseded


# ---------------------------------------------------------------------------
# Per-row collision materialization (shared by both expanders)
# ---------------------------------------------------------------------------
def _apply_collision_resolution(
    rows_to_insert: List[Dict[str, Any]],
    *,
    user_id: str,
    slot: Optional[str],
    replace: bool,
    day_resolutions: Optional[Dict[str, str]],
) -> List[str]:
    """Resolve each built row against existing workouts on its date, mutating the
    rows in place for "stack" (re-tag program_slot='addon') and collecting the
    workout ids to delete for "replace". Returns the supersede id list to hand to
    _insert_workout_rows so the delete + insert are one transaction.

    Uses the SAME resolve_collision() the assign-preview renders with, so the
    materialized result matches the preview exactly for every overridden date."""
    planned_dates = sorted({row["scheduled_date"][:10] for row in rows_to_insert})
    collision_map = _find_colliding_workouts(user_id, planned_dates)
    supersede_ids: List[str] = []
    seen_replace_dates: set = set()
    for row in rows_to_insert:
        diso = row["scheduled_date"][:10]
        existing_ids = collision_map.get(diso) or []
        res = resolve_collision(
            date_iso=diso,
            has_existing=bool(existing_ids),
            slot=slot or "primary",
            replace=replace,
            day_resolutions=day_resolutions,
        )
        if res == "stack":
            # Keep the existing workout; this new one stacks as an extra.
            row["program_slot"] = "addon"
        elif res == "replace" and existing_ids and diso not in seen_replace_dates:
            supersede_ids.extend(existing_ids)
            seen_replace_dates.add(diso)
    return supersede_ids


# ---------------------------------------------------------------------------
# Variant-week scheduling — curated multi-week programs store their REAL
# week-by-week plan in program_variant_weeks (the source the program-detail
# schedule view reads). plan_variant_schedule / expand_variant_weeks schedule
# from that directly so each calendar week gets its OWN sessions (distinct per
# week), instead of the flattened base `workouts` blob (which for some programs
# — e.g. HYROX — is all weeks flattened → blows the workout cap).
# ---------------------------------------------------------------------------
def plan_variant_schedule(
    weeks_rows: List[Dict[str, Any]],
    *,
    assigned_days: Optional[List[int]],
    start_date: date,
    max_weeks: int = MAX_WEEKS,
    max_total: int = MAX_TOTAL_WORKOUTS,
) -> Dict[str, Any]:
    """Pure planner for a variant's program_variant_weeks. Week index wi (0-based,
    in week_number order) lands on calendar week wi; session si of that week → the
    weekday sorted(assigned_days)[si % n] (cycling), date = start + wi*7 + lead.
    With no assigned_days, sessions fall on consecutive days from start_date.

    Returns {"planned": [ {week_number, session_idx, weekday, target_date,
    scheduled, session} ... ], "weeks_used": int, "sessions_per_week": int}.
    Raises ValueError if the schedule would exceed max_total."""
    rows = sorted(
        [w for w in (weeks_rows or []) if isinstance(w, dict)],
        key=lambda w: w.get("week_number") or 0,
    )[:max_weeks]
    targets = sorted({int(d) for d in (assigned_days or []) if 0 <= int(d) <= 6})

    planned: List[Dict[str, Any]] = []
    sessions_pw = 0
    total = 0
    for wi, wrow in enumerate(rows):
        sessions = wrow.get("workouts") or []
        if not isinstance(sessions, list):
            sessions = []
        sessions = [s for s in sessions if isinstance(s, dict)]
        sessions_pw = max(sessions_pw, len(sessions))
        for si, sess in enumerate(sessions):
            total += 1
            if total > max_total:
                raise ValueError(
                    f"This schedule would create more than {max_total} "
                    "workouts. Reduce weeks or sessions."
                )
            if targets:
                weekday = targets[si % len(targets)]
                lead = (weekday - start_date.weekday()) % 7
                target_date = start_date + timedelta(days=wi * 7 + lead)
            else:
                target_date = start_date + timedelta(days=wi * 7 + si)
                weekday = target_date.weekday()
            scheduled = _anchored_scheduled_date(target_date, _parse_hhmm(None))
            planned.append({
                "week_number": wrow.get("week_number") or (wi + 1),
                "session_idx": si,
                "weekday": weekday,
                "target_date": target_date,
                "scheduled": scheduled,
                "session": sess,
            })
    return {
        "planned": planned,
        "weeks_used": len(rows),
        "sessions_per_week": sessions_pw,
    }


def expand_variant_weeks(
    *,
    weeks_rows: List[Dict[str, Any]],
    template: Dict[str, Any],
    schedule_id: str,
    user_id: str,
    start_date: date,
    assigned_days: Optional[List[int]],
    gym_profile_id: Optional[str] = None,
    assignment_id: Optional[str] = None,
    program_slot: Optional[str] = None,
    apply_staples: bool = True,
    replace: bool = True,
    day_resolutions: Optional[Dict[str, str]] = None,
    resolve_collisions: bool = False,
) -> Dict[str, Any]:
    """Expand a curated program's program_variant_weeks into dated `workouts`
    rows — one per session per week, each carrying its OWN week's content. Same
    columns / idempotency / staples / PR-seeding as expand_template; deload is
    left to the variant's own authored content (no synthetic deload scaling).

    `replace` / `day_resolutions` / `resolve_collisions` behave exactly as in
    expand_template: when resolve_collisions=True each session date is resolved
    against existing workouts via resolve_collision() (replace → supersede,
    stack → re-tag program_slot='addon'); when False, rows insert as-is."""
    plan = plan_variant_schedule(
        weeks_rows, assigned_days=assigned_days, start_date=start_date
    )
    planned = plan["planned"]
    if not planned:
        raise ValueError("Variant has no sessions to schedule")
    template_id = template["id"]
    program_name = template.get("name", "Program")

    all_names: List[str] = []
    for p in planned:
        for ex in (p["session"].get("exercises") or []):
            n = ex.get("name") or ex.get("original_name")
            if n:
                all_names.append(n)
    seed_weights = _seed_target_weights(user_id, all_names)
    staples = (
        _load_staples_for_profile(user_id, gym_profile_id)
        if apply_staples
        else []
    )

    rows_to_insert: List[Dict[str, Any]] = []
    for p in planned:
        sess = p["session"]
        day = {
            "day_name": (
                sess.get("workout_name")
                or sess.get("name")
                or f"Day {p['session_idx'] + 1}"
            ),
            "workout_type": sess.get("type") or sess.get("workout_type")
            or "strength",
            "exercises": sess.get("exercises") or [],
        }
        exercises_json = _day_to_exercises_json(day, seed_weights, False)
        row: Dict[str, Any] = {
            "id": str(uuid.uuid4()),
            "user_id": user_id,
            "name": day["day_name"],
            "description": f"{program_name} - week {p['week_number']}",
            "scheduled_date": p["scheduled"],
            "exercises_json": psycopg2.extras.Json(exercises_json),
            "status": "scheduled",
            "is_current": False,
            "is_completed": False,
            "type": day["workout_type"],
            # workouts.difficulty is NOT-NULL + CHECK(easy|medium|hard|hell);
            # variant sessions carry per-exercise difficulty only, so default.
            "difficulty": "medium",
            "generation_source": "template",
            "generation_method": "program_template",
            "template_id": template_id,
            "template_week": p["week_number"],
            "template_day_index": p["session_idx"],
            "intensity_mode": "normal",
            "gym_profile_id": gym_profile_id,
            # Intra-day ordering (migration 2294): session index within the week
            # orders sessions that land on the same date (e.g. sessions/week >
            # training weekdays) so the home card never flickers between them.
            "display_order": p["session_idx"],
        }
        if assignment_id:
            row["assignment_id"] = assignment_id
        if program_slot:
            row["program_slot"] = program_slot

        if apply_staples and staples:
            injected = _inject_staples(day["exercises"], staples)
            if injected["warmup"]:
                row["warmup_json"] = psycopg2.extras.Json(injected["warmup"])
            if injected["stretch"]:
                row["stretch_json"] = psycopg2.extras.Json(injected["stretch"])
            if injected["main"]:
                merged = exercises_json + injected["main"]
                for idx, ex in enumerate(merged):
                    ex["order"] = idx + 1
                row["exercises_json"] = psycopg2.extras.Json(merged)

        rows_to_insert.append(row)

    supersede_ids: List[str] = []
    if resolve_collisions:
        supersede_ids = _apply_collision_resolution(
            rows_to_insert,
            user_id=user_id,
            slot=program_slot,
            replace=replace,
            day_resolutions=day_resolutions,
        )

    created, skipped, superseded = _insert_workout_rows(
        rows_to_insert, supersede_ids
    )
    logger.info(
        "Expanded variant for template %s: %d created, %d skipped, "
        "%d superseded (%d weeks)",
        template_id, created, skipped, superseded, plan["weeks_used"],
    )
    return {
        "workouts_created": created,
        "skipped_existing": skipped,
        "superseded_existing": superseded,
        "total_attempted": len(rows_to_insert),
        "deload_weeks": [],
        "schedule_id": schedule_id,
        "weeks_used": plan["weeks_used"],
    }


def regenerate_future(
    template: Dict[str, Any],
    user_id: str,
) -> Dict[str, Any]:
    """Rebuild not-yet-started future template workouts after a template edit
    (#54-58, S5/S6).

    Strategy: find every workout row for this template that has zero completed
    sets AND a future scheduled_date; for each, recompute exercises_json from
    the (now edited) template day, preserving the existing scheduled_date and
    week/day-index. Rows flagged detached_from_template are skipped (#60).
    Wrapped in a transaction.
    """
    template_id = template["id"]
    days_by_index = {
        int(d.get("day_index", 0)): d
        for d in (template.get("days") or [])
    }
    deload_every = template.get("deload_every_n_weeks")
    db = get_supabase()

    now_iso = datetime.now().isoformat()
    resp = (
        db.client.table("workouts")
        .select("id, template_week, template_day_index, scheduled_date, "
                "modification_history, generation_metadata")
        .eq("template_id", template_id)
        .eq("user_id", user_id)
        .gte("scheduled_date", now_iso)
        .execute()
    )
    candidates = resp.data or []

    # Filter to uncompleted, non-detached rows.
    targets: List[Dict[str, Any]] = []
    for w in candidates:
        meta = w.get("generation_metadata") or {}
        if isinstance(meta, dict) and meta.get("detached_from_template"):
            continue  # #60 - user's manual edit wins
        # Skip rows with any logged set. completed_set_count is not a column;
        # we infer "started" from is_completed / status.
        targets.append(w)

    seed_names: List[str] = []
    for d in days_by_index.values():
        for ex in d.get("exercises") or []:
            n = ex.get("name") or ex.get("original_name")
            if n:
                seed_names.append(n)
    seed_weights = _seed_target_weights(user_id, seed_names)

    updated = 0
    removed = 0
    conn = psycopg2.connect(_psycopg_dsn())
    try:
        conn.autocommit = False
        with conn.cursor() as cur:
            for w in targets:
                # Only touch rows that are still scheduled and not started.
                cur.execute(
                    "SELECT status, is_completed FROM workouts WHERE id = %s "
                    "FOR UPDATE",
                    (w["id"],),
                )
                cur_row = cur.fetchone()
                if not cur_row:
                    continue
                status, is_completed = cur_row
                if is_completed or status not in ("scheduled", None):
                    continue  # #55 - in-progress / completed untouched

                week = w.get("template_week") or 1
                day_idx = w.get("template_day_index")
                day = days_by_index.get(day_idx)
                if day is None or day.get("is_rest"):
                    # Day removed from template or now a rest day -> delete
                    # the future row (#57 for whole-day removal).
                    cur.execute(
                        "DELETE FROM workouts WHERE id = %s", (w["id"],)
                    )
                    removed += 1
                    continue

                is_deload = bool(
                    deload_every and deload_every > 0
                    and week % deload_every == 0
                )
                exercises_json = _day_to_exercises_json(
                    day, seed_weights, is_deload
                )
                cur.execute(
                    "UPDATE workouts SET exercises_json = %s, "
                    "name = %s, difficulty = %s, intensity_mode = %s, "
                    "last_modified_at = %s, last_modified_method = %s "
                    "WHERE id = %s",
                    (
                        psycopg2.extras.Json(exercises_json),
                        day.get("day_name") or f"Day {(day_idx or 0) + 1}",
                        day.get("difficulty") or "medium",
                        "deload" if is_deload else "normal",
                        now_iso,
                        "template_regenerate",
                        w["id"],
                    ),
                )
                updated += 1
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()

    logger.info(
        "regenerate_future template %s: %d updated, %d removed",
        template_id, updated, removed,
    )
    return {"workouts_updated": updated, "workouts_removed": removed}
