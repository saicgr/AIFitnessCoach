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
        out.append(obj)
    return out


# ---------------------------------------------------------------------------
# Main expansion entry point
# ---------------------------------------------------------------------------
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

    # Seed week-1 weights from PRs once (#42).
    all_names: List[str] = []
    for d in training_days:
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

    # When the caller pins specific weekdays (program-assign flow: assigned_days
    # e.g. [1,3,5] = Tue/Thu/Sat in Mon=0 indexing), the template's TRAINING
    # days are laid onto those weekdays in order: the k-th training day of the
    # week → assigned_days[k]. This is the per-day multi-assignment scheduling
    # the carousel renders. assigned_days takes precedence over both alignment
    # modes when present + the week is a calendar week.
    weekday_targets: Optional[List[int]] = None
    if assigned_days and week_length == 7:
        weekday_targets = sorted({int(d) for d in assigned_days if 0 <= int(d) <= 6})
    # Map each training day's day_index -> its ordinal among training days, so we
    # can index into weekday_targets without assuming day_index is contiguous.
    training_day_indices = [
        int(d.get("day_index", 0)) for d in days if not d.get("is_rest")
    ]
    _training_ordinal = {di: k for k, di in enumerate(training_day_indices)}

    deload_weeks: List[int] = []
    rows_to_insert: List[Dict[str, Any]] = []

    for week in range(1, weeks + 1):
        is_deload = bool(
            deload_every and deload_every > 0 and week % deload_every == 0
        )
        if is_deload:
            deload_weeks.append(week)

        for day in days:
            if day.get("is_rest"):
                continue  # #34 - no row for rest days
            day_index = int(day.get("day_index", 0))

            # Day-of-cycle offset. With a week_length of e.g. 10 the cycle is
            # not the calendar week, so we offset off day_index within the
            # week_length-long block.
            offset_days = (week - 1) * week_length + day_index

            if weekday_targets:
                # assigned_days mapping: place the k-th training day of the week
                # on the k-th assigned weekday (cycling if more training days
                # than assigned weekdays). Week 1's first assigned weekday is the
                # first such weekday on/after start_date.
                ordinal = _training_ordinal.get(day_index, 0)
                target_weekday = weekday_targets[ordinal % len(weekday_targets)]
                start_weekday = start_date.weekday()  # Mon=0
                lead = (target_weekday - start_weekday) % 7
                target_date = start_date + timedelta(
                    days=(week - 1) * 7 + lead
                )
            elif day_alignment == "calendar_weekday" and week_length == 7:
                # Align template day_index (0=Mon..6=Sun) to real weekdays:
                # shift start_date forward to the matching weekday.
                start_weekday = start_date.weekday()  # Mon=0
                lead = (day_index - start_weekday) % 7
                target_date = start_date + timedelta(
                    days=(week - 1) * 7 + lead
                )
            else:
                # 'start_today' - day 1 is the picked date (#29 default).
                target_date = start_date + timedelta(days=offset_days)

            t = _parse_hhmm(day_times.get(str(day_index)))
            scheduled = _anchored_scheduled_date(target_date, t)

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

    # ----- transactional insert (all-or-nothing, idempotent) ---------------
    created = 0
    skipped = 0
    conn = psycopg2.connect(_psycopg_dsn())
    try:
        conn.autocommit = False
        with conn.cursor() as cur:
            for row in rows_to_insert:
                cols = list(row.keys())
                placeholders = ", ".join(["%s"] * len(cols))
                col_sql = ", ".join(cols)
                # ON CONFLICT against uq_workouts_template_slot makes the
                # second concurrent / double-tap schedule a no-op (#39/#69).
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

    logger.info(
        "Expanded template %s: %d workouts created, %d skipped (idempotent), "
        "deload weeks=%s",
        template_id, created, skipped, deload_weeks,
    )
    return {
        "workouts_created": created,
        "skipped_existing": skipped,
        "total_attempted": len(rows_to_insert),
        "deload_weeks": deload_weeks,
        "schedule_id": schedule_id,
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
