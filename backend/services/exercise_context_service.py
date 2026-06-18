"""
Exercise Context Service — batch assembler for post-workout AI surfaces.

Everything the post-workout recap / per-exercise AI wants to "know" about a lift
(prior per-set history, current PR, all-time / effective 1RM, today-is-a-PR,
effort, injury/pain flags, recent form analysis) already lives in the DB — this
service forwards it to the LLM in a SMALL, FIXED number of queries (NO N+1).

Design contract:
  * `assemble_exercise_contexts(...)` runs at most THREE queries for ALL exercises:
        Q1  per-set history          (performance_logs, batched, warmups filtered)
        Q2  current PRs              (exercise_personal_records, batched)
        Q3  1RM bests                (strength_exercise_bests, batched)
  * `fetch_active_injury_context(...)` runs TWO queries (user_injuries + avoided).
  * `fetch_recent_form_analysis(...)` runs ONE query (media_analysis_jobs).
  * Pure helpers (1RM, PR grouping) are REUSED from existing services, never
    re-derived. Deterministic & honest: no history → has_history=False; no PR →
    current_pr=None; bodyweight (weight 0) → bodyweight=True, framed in reps.

All weights are kept in kg (the storage unit); the recap/critique layer converts
to the user's display unit. This module never raises for empty data — it returns
empty/None fields so the prompt layer can omit blocks cleanly.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

from core.logger import get_logger
from services.personal_records_service import personal_records_service
from services.strength_calculator_service import StrengthCalculatorService

logger = get_logger(__name__)

# Near-PR threshold: today's top-set 1RM within this fraction of the best counts
# as "near PR" (~2.5%).
_NEAR_PR_FRACTION = 0.025

_WARMUP_SET_TYPES = {"warmup", "warm_up", "warm-up"}

_strength_calc = StrengthCalculatorService()


# ---------------------------------------------------------------------------
# Data shapes
# ---------------------------------------------------------------------------

@dataclass
class ExerciseContext:
    """Everything the AI knows about ONE exercise for THIS session.

    `recent_sessions` is newest-first; each item is
    {date: 'YYYY-MM-DD', sets: [{weight_kg, reps, rir, rpe, set_type}]} with
    warmups already filtered. All 1RM/weight figures are kg.
    """
    exercise_name: str
    recent_sessions: List[Dict[str, Any]] = field(default_factory=list)
    current_pr: Optional[Dict[str, Any]] = None          # from get_exercise_pr_history
    all_time_best_1rm_kg: Optional[float] = None
    effective_1rm_kg: Optional[float] = None
    pr_timeline_highlights: List[Dict[str, Any]] = field(default_factory=list)
    today_top_1rm: Optional[float] = None
    is_pr: bool = False
    is_near_pr: bool = False
    has_history: bool = False
    bodyweight: bool = False
    avg_rir: Optional[float] = None
    avg_rpe: Optional[float] = None
    form: Optional[Dict[str, Any]] = None                 # {form_score, top_issues}


@dataclass
class InjuryContext:
    """Active injury / pain picture for the user (zero-cost when empty)."""
    injuries: List[Dict[str, Any]] = field(default_factory=list)
    pain_flagged_exercises: List[str] = field(default_factory=list)

    @property
    def is_empty(self) -> bool:
        return not self.injuries and not self.pain_flagged_exercises


# ---------------------------------------------------------------------------
# Q1 — shared per-set history (refactored out of exercise_history.get_batch...)
# ---------------------------------------------------------------------------

def fetch_batch_perset_history(
    db,
    user_id: str,
    exercise_names: List[str],
    gym_profile_id: Optional[str] = None,
    days_back: int = 84,
    limit_per_exercise: int = 5,
) -> Dict[str, List[Dict[str, Any]]]:
    """Per-set workout history for multiple exercises in a SINGLE query.

    This is the canonical implementation that `exercise_history.get_batch_exercise_history`
    also calls (DRY — one query, warmups filtered, newest-session-first).

    Returns: {original_name -> newest-first list of session dicts}, each session
    dict = {"date": "YYYY-MM-DD", "sets": [{weight_kg, reps, rir, rpe, set_type,
    workout_log_id}, ...]}. The full per-set fields are returned so callers can
    derive effort (avg RIR/RPE) and today-vs-history without re-querying.
    """
    if not exercise_names:
        return {}

    normalized = [n.lower() for n in exercise_names]
    since = (datetime.utcnow().date() - timedelta(days=days_back)).isoformat()

    pl_query = (
        db.client.from_("performance_logs")
        .select(
            "exercise_name, set_number, reps_completed, weight_kg, rpe, rir, "
            "set_type, recorded_at, workout_log_id"
        )
        .eq("user_id", user_id)
        .in_("exercise_name", normalized)
        .gte("recorded_at", since)
    )
    if gym_profile_id:
        pl_query = pl_query.eq("gym_profile_id", gym_profile_id)
    result = (
        pl_query
        .order("recorded_at", desc=True)
        .limit(limit_per_exercise * len(normalized) * 10)
        .execute()
    )
    rows = result.data or []

    # Group rows by (exercise_name_lower, session_key). A workout_log_id
    # approximates one session; fall back to the date if it's missing.
    grouped: Dict[str, Dict[str, Dict[str, Any]]] = {n: {} for n in normalized}

    for row in rows:
        ex_name = (row.get("exercise_name") or "").lower()
        if ex_name not in grouped:
            continue
        set_type = (row.get("set_type") or "working").lower()
        if set_type in _WARMUP_SET_TYPES:
            continue
        reps = row.get("reps_completed")
        if reps is None or int(reps) <= 0:
            continue

        session_key = row.get("workout_log_id") or (row.get("recorded_at") or "")[:10]
        if not session_key:
            continue

        bucket = grouped[ex_name].setdefault(
            session_key,
            {"date": (row.get("recorded_at") or "")[:10], "sets": []},
        )
        bucket["sets"].append(
            {
                "weight_kg": float(row.get("weight_kg") or 0.0),
                "reps": int(reps),
                "rir": int(row["rir"]) if row.get("rir") is not None else None,
                "rpe": float(row["rpe"]) if row.get("rpe") is not None else None,
                "set_type": set_type,
                "workout_log_id": row.get("workout_log_id"),
            }
        )

    histories: Dict[str, List[Dict[str, Any]]] = {}
    for original_name, normalized_name in zip(exercise_names, normalized):
        bucket = grouped.get(normalized_name, {})
        sorted_sessions = sorted(
            bucket.values(), key=lambda x: x["date"], reverse=True
        )[:limit_per_exercise]
        histories[original_name] = [s for s in sorted_sessions if s["sets"]]

    return histories


# ---------------------------------------------------------------------------
# 1RM helpers (reuse the existing estimator — never re-derive)
# ---------------------------------------------------------------------------

def _top_set_1rm(sets: List[Dict[str, Any]]) -> tuple[Optional[float], bool]:
    """Estimate today's top-set 1RM (kg) over the given working sets.

    Returns (top_1rm_kg | None, bodyweight). The top set is the one with the
    highest estimated 1RM (reuses StrengthCalculatorService.calculate_1rm_average).
    Bodyweight is True when every working set has zero load — then 1RM is None and
    the caller frames progress in reps.
    """
    loaded = [
        s for s in sets
        if float(s.get("weight_kg") or 0) > 0 and int(s.get("reps") or 0) > 0
    ]
    if not loaded:
        # Bodyweight (or no load logged): no 1RM, frame in reps.
        any_reps = any(int(s.get("reps") or 0) > 0 for s in sets)
        return None, any_reps

    best = 0.0
    for s in loaded:
        est = _strength_calc.calculate_1rm_average(
            float(s.get("weight_kg") or 0), int(s.get("reps") or 0)
        )
        best = max(best, est)
    return (round(best, 2) if best > 0 else None), False


def _avg(values: List[float]) -> Optional[float]:
    nums = [v for v in values if v is not None]
    return round(sum(nums) / len(nums), 1) if nums else None


# ---------------------------------------------------------------------------
# Q2 / Q3 — PRs + 1RM bests, then assemble
# ---------------------------------------------------------------------------

def _map_pr_rows_for_history(rows: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Adapt `exercise_personal_records` rows to the shape the PURE
    `PersonalRecordsService.get_exercise_pr_history` expects.

    The stored schema is (record_type, record_value, previous_value,
    improvement_percent, achieved_at) — there is no `estimated_1rm_kg` column.
    The pure function sorts a timeline by `estimated_1rm_kg`, so we synthesize it
    from the `best_1rm` record rows (record_value IS the estimated 1RM in kg for
    those rows). Non-1RM record rows are dropped from the timeline (they don't
    carry a comparable 1RM).
    """
    mapped: List[Dict[str, Any]] = []
    for r in rows:
        rtype = (r.get("record_type") or "").lower()
        if rtype not in ("best_1rm", "1rm", "max_weight"):
            # Only 1RM-comparable rows feed the timeline; weight/volume/rep rows
            # without a comparable 1RM are skipped (they'd corrupt the sort).
            continue
        one_rm = float(r.get("record_value") or 0)
        mapped.append(
            {
                "exercise_name": r.get("exercise_name"),
                "estimated_1rm_kg": one_rm,
                # The PR rows don't store raw weight/reps; surface what we have.
                "weight_kg": one_rm if rtype == "max_weight" else 0.0,
                "reps": 0,
                "achieved_at": r.get("achieved_at"),
                "improvement_percent": r.get("improvement_percent"),
            }
        )
    return mapped


def assemble_exercise_contexts(
    db,
    user_id: str,
    exercise_names: List[str],
    gym_profile_id: Optional[str],
    current_session_by_name: Dict[str, List[Dict[str, Any]]],
) -> Dict[str, ExerciseContext]:
    """Assemble {exercise_name -> ExerciseContext} in <=3 total queries.

    Args:
        db: supabase db wrapper (db.client is the postgrest client).
        user_id: user id.
        exercise_names: display names of the exercises in THIS session.
        gym_profile_id: optional per-gym scope.
        current_session_by_name: {name -> [today's working sets]} for this session
            (used to compute today_top_1rm / is_pr / avg effort). May be empty for
            a marked-done session — then is_pr/near_pr stay False and effort None.

    Returns:
        {name -> ExerciseContext}. Never raises; on a query failure the affected
        block degrades to empty (honest) rather than fabricating data.
    """
    contexts: Dict[str, ExerciseContext] = {
        name: ExerciseContext(exercise_name=name) for name in exercise_names
    }
    if not exercise_names:
        return contexts

    normalized = [n.lower() for n in exercise_names]
    norm_to_display = {n.lower(): n for n in exercise_names}

    # --- Q1: per-set history (also covers TODAY's rows for effort derivation) ---
    try:
        histories = fetch_batch_perset_history(
            db, user_id, exercise_names, gym_profile_id,
            days_back=84, limit_per_exercise=5,
        )
    except Exception as e:
        logger.warning(f"[ctx] perset history failed: {e}")
        histories = {n: [] for n in exercise_names}

    # --- Q2: current PRs (one query for all names) ---
    pr_rows_by_name: Dict[str, List[Dict[str, Any]]] = {n: [] for n in normalized}
    try:
        pr_query = (
            db.client.from_("exercise_personal_records")
            .select(
                "exercise_name, record_type, record_value, previous_value, "
                "improvement_percent, achieved_at, gym_profile_id"
            )
            .eq("user_id", user_id)
            .eq("is_current_record", True)
            .in_("exercise_name", normalized)
        )
        if gym_profile_id:
            pr_query = pr_query.eq("gym_profile_id", gym_profile_id)
        pr_res = pr_query.execute()
        for r in (pr_res.data or []):
            key = (r.get("exercise_name") or "").lower()
            if key in pr_rows_by_name:
                pr_rows_by_name[key].append(r)
    except Exception as e:
        logger.warning(f"[ctx] PR query failed: {e}")

    # --- Q3: 1RM bests (one query for all names) ---
    bests_by_name: Dict[str, Dict[str, Any]] = {}
    try:
        bests_query = (
            db.client.from_("strength_exercise_bests")
            .select("exercise_key, all_time_best_1rm_kg, effective_1rm_kg, gym_profile_id")
            .eq("user_id", user_id)
            .in_("exercise_key", normalized)
        )
        if gym_profile_id:
            bests_query = bests_query.eq("gym_profile_id", gym_profile_id)
        bests_res = bests_query.execute()
        for r in (bests_res.data or []):
            key = (r.get("exercise_key") or "").lower()
            # Keep the highest all-time best if multiple gym rows match.
            existing = bests_by_name.get(key)
            if existing is None or float(r.get("all_time_best_1rm_kg") or 0) > float(
                existing.get("all_time_best_1rm_kg") or 0
            ):
                bests_by_name[key] = r
    except Exception as e:
        logger.warning(f"[ctx] strength_exercise_bests query failed: {e}")

    # --- Assemble per exercise (pure, in Python — zero extra queries) ---
    for norm in normalized:
        display = norm_to_display[norm]
        ctx = contexts[display]

        sessions = histories.get(display, []) or []
        ctx.recent_sessions = [
            {
                "date": s["date"],
                "sets": [
                    {k: v for k, v in st.items() if k != "workout_log_id"}
                    for st in s["sets"]
                ],
            }
            for s in sessions
        ]
        ctx.has_history = bool(sessions)

        # PR history via the PURE function (mapped to its expected shape).
        pr_rows = pr_rows_by_name.get(norm, [])
        if pr_rows:
            try:
                pr_hist = personal_records_service.get_exercise_pr_history(
                    display, _map_pr_rows_for_history(pr_rows)
                )
                if pr_hist.get("total_prs"):
                    ctx.current_pr = pr_hist.get("current_pr")
                    ctx.pr_timeline_highlights = (pr_hist.get("pr_timeline") or [])[-3:]
            except Exception as e:
                logger.debug(f"[ctx] pr_history failed for {display}: {e}")

        # 1RM bests.
        best_row = bests_by_name.get(norm)
        if best_row:
            atb = float(best_row.get("all_time_best_1rm_kg") or 0)
            eff = float(best_row.get("effective_1rm_kg") or 0)
            ctx.all_time_best_1rm_kg = atb if atb > 0 else None
            ctx.effective_1rm_kg = eff if eff > 0 else None

        # --- Today's session: top 1RM, PR flags, effort (no extra queries) ---
        today_sets = current_session_by_name.get(display) or current_session_by_name.get(norm) or []
        if today_sets:
            top_1rm, is_bw = _top_set_1rm(today_sets)
            ctx.today_top_1rm = top_1rm
            ctx.bodyweight = is_bw and top_1rm is None

            ctx.avg_rir = _avg([s.get("rir") for s in today_sets])
            ctx.avg_rpe = _avg([s.get("rpe") for s in today_sets])

            # PR / near-PR vs the best known 1RM (prefer all-time, else current PR,
            # else effective). Only meaningful for loaded lifts.
            if top_1rm is not None:
                baseline = (
                    ctx.all_time_best_1rm_kg
                    or (ctx.current_pr or {}).get("estimated_1rm_kg")
                    or ctx.effective_1rm_kg
                )
                if baseline and baseline > 0:
                    if top_1rm > baseline:
                        ctx.is_pr = True
                    elif top_1rm >= baseline * (1 - _NEAR_PR_FRACTION):
                        ctx.is_near_pr = True
                elif not ctx.has_history:
                    # First loaded session of its kind → treat as a PR (nothing to beat).
                    ctx.is_pr = True

    return contexts


def assemble_single_exercise_context(
    db,
    user_id: str,
    exercise_name: str,
    gym_profile_id: Optional[str],
    current_sets: List[Dict[str, Any]],
) -> ExerciseContext:
    """Thin wrapper over the batch assembler for the on-demand per-exercise endpoint."""
    ctxs = assemble_exercise_contexts(
        db, user_id, [exercise_name], gym_profile_id,
        {exercise_name: current_sets or []},
    )
    return ctxs.get(exercise_name, ExerciseContext(exercise_name=exercise_name))


# ---------------------------------------------------------------------------
# Injury / pain context (two queries, zero cost when empty)
# ---------------------------------------------------------------------------

def fetch_active_injury_context(db, user_id: str) -> InjuryContext:
    """Active injury picture + pain-flagged exercises for the user.

    Q1: user_injuries where status in ('active','recovering').
    Q2: avoided_exercises where reason like 'pain:%'.
    Returns an InjuryContext; `.is_empty` is True when there's nothing to inject
    (so the prompt layer omits the INJURY block entirely — no token cost).
    """
    ctx = InjuryContext()
    try:
        inj_res = (
            db.client.from_("user_injuries")
            .select(
                "body_part, injury_type, severity, recovery_phase, pain_level, "
                "affects_exercises, affects_muscles, status"
            )
            .eq("user_id", user_id)
            .in_("status", ["active", "recovering"])
            .execute()
        )
        for r in (inj_res.data or []):
            ctx.injuries.append(
                {
                    "body_part": r.get("body_part"),
                    "injury_type": r.get("injury_type"),
                    "severity": r.get("severity"),
                    "recovery_phase": r.get("recovery_phase"),
                    "pain_level": r.get("pain_level"),
                    "affects_exercises": r.get("affects_exercises") or [],
                    "affects_muscles": r.get("affects_muscles") or [],
                }
            )
    except Exception as e:
        logger.warning(f"[ctx] user_injuries query failed: {e}")

    try:
        av_res = (
            db.client.from_("avoided_exercises")
            .select("exercise_name, reason")
            .eq("user_id", user_id)
            .ilike("reason", "pain:%")
            .execute()
        )
        names = [
            r.get("exercise_name")
            for r in (av_res.data or [])
            if r.get("exercise_name")
        ]
        # Dedup, preserve order.
        seen = set()
        for n in names:
            low = n.lower()
            if low not in seen:
                seen.add(low)
                ctx.pain_flagged_exercises.append(n)
    except Exception as e:
        logger.warning(f"[ctx] avoided_exercises query failed: {e}")

    return ctx


# ---------------------------------------------------------------------------
# Recent form analysis (one query — A3 v1, no schema change)
# ---------------------------------------------------------------------------

def fetch_recent_form_analysis(
    db,
    user_id: str,
    exercise_name: str,
    exercise_id: Optional[str] = None,
    gym_profile_id: Optional[str] = None,
    days: int = 30,
) -> Optional[Dict[str, Any]]:
    """Most recent COMPLETED form analysis for an exercise (A3 v1).

    Queries media_analysis_jobs where job_type='form_analysis', status='completed',
    completed_at within `days`, and params->>'exercise' (or params->>'exercise_id')
    matches. Returns {form_score, top_issues:[{description, correction}]} from the
    result jsonb, or None when there's no recent analysis (FORM block then omitted).
    """
    since = (datetime.now(timezone.utc) - timedelta(days=days)).isoformat()
    try:
        q = (
            db.client.from_("media_analysis_jobs")
            .select("result, params, completed_at, gym_profile_id")
            .eq("user_id", user_id)
            .eq("job_type", "form_analysis")
            .eq("status", "completed")
            .gte("completed_at", since)
            .order("completed_at", desc=True)
            .limit(20)
        )
        if gym_profile_id:
            q = q.eq("gym_profile_id", gym_profile_id)
        res = q.execute()
    except Exception as e:
        logger.warning(f"[ctx] form analysis query failed: {e}")
        return None

    rows = res.data or []
    if not rows:
        return None

    target_name = (exercise_name or "").lower().strip()
    target_id = str(exercise_id) if exercise_id else None

    # Rows are newest-first; pick the first whose params match this exercise.
    chosen = None
    for r in rows:
        params = r.get("params") or {}
        p_ex = str(params.get("exercise") or "").lower().strip()
        p_id = str(params.get("exercise_id") or "") if params.get("exercise_id") else None
        if target_id and p_id and p_id == target_id:
            chosen = r
            break
        if target_name and p_ex and (p_ex == target_name or target_name in p_ex or p_ex in target_name):
            chosen = r
            break
    if chosen is None:
        return None

    result = chosen.get("result") or {}
    if isinstance(result, str):
        import json
        try:
            result = json.loads(result)
        except (json.JSONDecodeError, TypeError):
            return None

    form_score = result.get("form_score")
    if form_score is None:
        return None

    issues = result.get("issues") or []
    top_issues = [
        {
            "description": i.get("description"),
            "correction": i.get("correction"),
            "body_part": i.get("body_part"),
            "severity": i.get("severity"),
        }
        for i in issues[:2]
        if i.get("description")
    ]

    return {
        "form_score": form_score,
        "top_issues": top_issues,
        "analyzed_at": chosen.get("completed_at"),
    }
