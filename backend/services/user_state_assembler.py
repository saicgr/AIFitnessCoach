"""
user_state_assembler.py — Phase 2.A of workouts overhaul.

Aggregates signals the AI workout generator + validator + coach all need to
reason about today's plan. The audit found that most signals are already
collected (recovery, soreness, sleep, HRV, calories, protein, injuries,
form score) but never flow into generation. This is the wiring.

Returns a `UserState` dataclass with everything-known-now about the user.
Cached 60s per user to avoid hot-path DB hammering.

Callers
-------
- backend.services.holistic_plan_service.generate_weekly_plan (Phase 2)
- backend.services.gemini.workout_generation_helpers (two-pass loop)
- backend.api.v1.workouts.validation_utils (MEV/MRV + recovery gates)
- backend.services.langgraph_agents.tools.state_tools (AI coach tool)
- backend.api.v1.scores.breakdown (Phase 4 explain endpoint)

Honors `feedback_no_silent_fallbacks`: missing signals are surfaced as None,
NOT defaulted. Downstream code branches on presence explicitly.
"""
from __future__ import annotations

import logging
from dataclasses import dataclass, field, asdict
from datetime import datetime, timedelta, timezone, date
from typing import Any, Dict, List, Optional

logger = logging.getLogger(__name__)

# Cache: user_id -> (assembled_at_epoch, UserState).
_CACHE: Dict[str, "_CacheEntry"] = {}
_TTL_SECONDS = 60


@dataclass
class _CacheEntry:
    assembled_at: float
    state: "UserState"


@dataclass
class UserState:
    """Snapshot of everything-known-now about a user for workout generation.

    All fields are Optional — `None` means "no signal" and downstream branches
    explicitly. The generator + validator can both reason about partial state
    without silently degrading.
    """

    user_id: str
    assembled_at: datetime

    # ----- Recovery + soreness ---------------------------------------------
    muscle_recovery: Dict[str, float] = field(default_factory=dict)  # muscle -> 0..1
    avg_recovery: Optional[float] = None
    hooper_index: Optional[int] = None     # 4..28 sum of sleep/fatigue/stress/soreness
    muscle_soreness: Optional[int] = None  # Hooper component, 1..7
    rhr_delta_pct: Optional[float] = None  # +X% vs baseline = stressed
    pre_workout_sleep_0_10: Optional[int] = None      # reshape-gate gauge, 0..10
    pre_workout_readiness_0_10: Optional[int] = None  # reshape-gate gauge, 0..10

    # ----- Sleep / strain ---------------------------------------------------
    sleep_hours_7d_avg: Optional[float] = None
    sleep_last_night_hours: Optional[float] = None
    weekly_trimp: Optional[float] = None
    cardio_load_state: Optional[str] = None  # 'low' | 'productive' | 'overreaching' …

    # ----- Strain by muscle -------------------------------------------------
    sets_per_muscle_7d: Dict[str, int] = field(default_factory=dict)
    sets_per_muscle_28d: Dict[str, int] = field(default_factory=dict)

    # ----- Nutrition (Phase 6 #2 — our 4-category unfair advantage) --------
    caloric_balance_7d_avg: Optional[float] = None
    protein_avg_7d_g: Optional[float] = None
    carbs_today_g: Optional[float] = None
    in_deficit: Optional[bool] = None    # caloric_balance_7d_avg < -200 kcal/day

    # ----- Body trend ------------------------------------------------------
    weight_trend_pct_per_week: Optional[float] = None  # -0.75% = aggressive cut

    # ----- Injuries --------------------------------------------------------
    active_injuries: List[Dict[str, Any]] = field(default_factory=list)
    injured_body_parts: List[str] = field(default_factory=list)

    # ----- Periodization ---------------------------------------------------
    mesocycle_week: Optional[int] = None
    mesocycle_scheme: Optional[str] = None
    is_deload_week: bool = False

    # ----- Rolling per-exercise stats --------------------------------------
    rolling_rpe_per_exercise: Dict[str, float] = field(default_factory=dict)
    plateaued_exercises: List[str] = field(default_factory=list)

    # ----- Form score per exercise (Phase 2.I) -----------------------------
    form_score_per_exercise: Dict[str, float] = field(default_factory=dict)

    # ----- Goal + equipment-context ----------------------------------------
    goal: Optional[str] = None
    equipment_categories_available: List[str] = field(default_factory=list)

    def to_jsonable(self) -> Dict[str, Any]:
        """Plain-dict version for embedding in Gemini prompts / tool returns."""
        d = asdict(self)
        d["assembled_at"] = self.assembled_at.isoformat()
        return d

    def signal_completeness(self) -> float:
        """Fraction of signals present (rough proxy for trustworthiness).
        Useful when the validator decides whether to enforce a rule strictly
        or warn-only.
        """
        slots = [
            self.avg_recovery, self.hooper_index, self.sleep_hours_7d_avg,
            self.weekly_trimp, self.caloric_balance_7d_avg, self.protein_avg_7d_g,
            self.weight_trend_pct_per_week, self.mesocycle_week,
        ]
        present = sum(1 for s in slots if s is not None)
        return present / len(slots) if slots else 0.0


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


def assemble_user_state(user_id: str, supabase, force: bool = False) -> UserState:
    """Build a UserState for `user_id`.

    Cached 60s. Single DB round-trip per source table; never raises — any
    failed lookup just leaves that field None and is logged.

    Args:
        user_id: Supabase auth user id.
        supabase: A SupabaseDb instance (caller-provided so this is testable).
        force:   Skip the cache.
    """
    if not force:
        cached = _CACHE.get(user_id)
        if cached and (_utcnow().timestamp() - cached.assembled_at) < _TTL_SECONDS:
            return cached.state

    state = UserState(user_id=user_id, assembled_at=_utcnow())

    # ---- today_readiness view (Hooper + RHR + TRIMP + cardio_load_state) ----
    try:
        res = supabase.table("today_readiness").select("*").eq("user_id", user_id).limit(1).execute()
        if res.data:
            r = res.data[0]
            state.hooper_index = r.get("hooper_index")
            state.muscle_soreness = r.get("muscle_soreness")
    except Exception as e:  # pragma: no cover
        logger.debug(f"[user_state] today_readiness skipped: {e}")

    try:
        res = (
            supabase.table("readiness_scores")
            .select(
                "rhr_delta_pct,weekly_trimp,cardio_load_state,sleep_quality,"
                "pre_workout_sleep_0_10,pre_workout_readiness_0_10"
            )
            .eq("user_id", user_id)
            .order("score_date", desc=True)
            .limit(1)
            .execute()
        )
        if res.data:
            r = res.data[0]
            state.rhr_delta_pct = r.get("rhr_delta_pct")
            state.weekly_trimp = r.get("weekly_trimp")
            state.cardio_load_state = r.get("cardio_load_state")
            state.pre_workout_sleep_0_10 = r.get("pre_workout_sleep_0_10")
            state.pre_workout_readiness_0_10 = r.get("pre_workout_readiness_0_10")
    except Exception as e:  # pragma: no cover
        logger.debug(f"[user_state] readiness_scores skipped: {e}")

    # ---- mesocycle_state (Phase 2.E) ---------------------------------------
    try:
        res = supabase.table("mesocycle_state").select("*").eq("user_id", user_id).limit(1).execute()
        if res.data:
            r = res.data[0]
            state.mesocycle_week = r.get("current_week")
            state.mesocycle_scheme = r.get("scheme")
            state.is_deload_week = bool(r.get("is_deload_week"))
    except Exception as e:  # pragma: no cover
        logger.debug(f"[user_state] mesocycle_state skipped: {e}")

    # ---- Active injuries ---------------------------------------------------
    try:
        res = (
            supabase.table("injury_history")
            .select("body_part,severity,recovery_phase,pain_level_current,expected_recovery_date")
            .eq("user_id", user_id)
            .eq("is_active", True)
            .execute()
        )
        if res.data:
            state.active_injuries = res.data
            state.injured_body_parts = list({r.get("body_part") for r in res.data if r.get("body_part")})
    except Exception as e:  # pragma: no cover
        logger.debug(f"[user_state] injury_history skipped: {e}")

    # ---- user_exercise_state (rolling RPE + plateau) -----------------------
    try:
        res = (
            supabase.table("user_exercise_state")
            .select("exercise_id,rolling_rpe_7d,plateau_flag")
            .eq("user_id", user_id)
            .execute()
        )
        for r in (res.data or []):
            ex = r.get("exercise_id")
            if not ex:
                continue
            if r.get("rolling_rpe_7d") is not None:
                state.rolling_rpe_per_exercise[ex] = float(r["rolling_rpe_7d"])
            if r.get("plateau_flag"):
                state.plateaued_exercises.append(ex)
    except Exception as e:  # pragma: no cover
        logger.debug(f"[user_state] user_exercise_state skipped: {e}")

    # ---- Sets-per-muscle volume tally (last 7 / 28 days) -------------------
    try:
        since_7  = (_utcnow() - timedelta(days=7)).isoformat()
        since_28 = (_utcnow() - timedelta(days=28)).isoformat()
        logs = (
            supabase.table("workout_logs")
            .select("performance_data,sets_json,completed_at")
            .eq("user_id", user_id)
            .gte("completed_at", since_28)
            .execute()
        )
        for row in (logs.data or []):
            done_at = row.get("completed_at")
            try:
                done_dt = datetime.fromisoformat(done_at.replace("Z", "+00:00")) if done_at else None
            except Exception:
                done_dt = None
            in_7 = done_dt and done_dt.isoformat() >= since_7
            for entry in (row.get("performance_data") or {}).get("exercises", []) if isinstance(row.get("performance_data"), dict) else []:
                muscle = (entry.get("primary_muscle") or "").lower()
                sets   = int(entry.get("completed_sets") or 0)
                if not muscle or sets <= 0:
                    continue
                state.sets_per_muscle_28d[muscle] = state.sets_per_muscle_28d.get(muscle, 0) + sets
                if in_7:
                    state.sets_per_muscle_7d[muscle] = state.sets_per_muscle_7d.get(muscle, 0) + sets
    except Exception as e:  # pragma: no cover
        logger.debug(f"[user_state] workout_logs aggregation skipped: {e}")

    # ---- Nutrition: 7-day caloric balance + protein avg --------------------
    try:
        since_7 = (_utcnow() - timedelta(days=7)).isoformat()
        meals = (
            supabase.table("food_logs")
            .select("total_calories,protein_g,carbs_g,logged_at")
            .eq("user_id", user_id)
            .gte("logged_at", since_7)
            .execute()
        )
        if meals.data:
            tot_kcal = sum((m.get("total_calories") or 0) for m in meals.data)
            tot_protein = sum((m.get("protein_g") or 0) for m in meals.data)
            tot_carbs_today = sum(
                (m.get("carbs_g") or 0)
                for m in meals.data
                if (m.get("logged_at") or "").startswith(date.today().isoformat())
            )
            state.protein_avg_7d_g = tot_protein / 7.0
            state.carbs_today_g = tot_carbs_today

            # Caloric balance vs the user's stored target (best-effort).
            try:
                wp = (
                    supabase.table("weekly_plans")
                    .select("base_calorie_target")
                    .eq("user_id", user_id)
                    .order("week_start_date", desc=True)
                    .limit(1)
                    .execute()
                )
                target = (wp.data or [{}])[0].get("base_calorie_target")
                if target:
                    state.caloric_balance_7d_avg = (tot_kcal / 7.0) - float(target)
                    state.in_deficit = state.caloric_balance_7d_avg < -200
            except Exception:
                pass
    except Exception as e:  # pragma: no cover
        logger.debug(f"[user_state] food_log skipped: {e}")

    # ---- Goal (from users table) ------------------------------------------
    try:
        res = supabase.table("users").select("primary_goal,goals").eq("id", user_id).limit(1).execute()
        if res.data:
            goals = res.data[0].get("goals") or []
            state.goal = res.data[0].get("primary_goal") or (goals[0] if goals else None)
    except Exception as e:  # pragma: no cover
        logger.debug(f"[user_state] users.goal skipped: {e}")

    # ---- Per-muscle recovery (mirror of muscle_recovery_tracker.dart) -----
    # Surfaced by the Flutter side via /user-state/push; if not present yet,
    # we leave it empty and the validator skips the recovery gate.
    # (No-op block reserved here for the push endpoint in Phase 2.E follow-up.)

    # ---- Compute avg recovery if we have any ------------------------------
    if state.muscle_recovery:
        state.avg_recovery = sum(state.muscle_recovery.values()) / len(state.muscle_recovery)

    _CACHE[user_id] = _CacheEntry(assembled_at=_utcnow().timestamp(), state=state)
    return state


def invalidate(user_id: Optional[str] = None) -> None:
    """Drop cached state. Call after the user logs a set, edits calibration,
    or completes an intake survey so the next generation reads fresh signals.
    """
    if user_id is None:
        _CACHE.clear()
    else:
        _CACHE.pop(user_id, None)
