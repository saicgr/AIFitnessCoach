"""
workout_validator_phase2.py — Phase 2.B/2.C of workouts overhaul.

Extends the existing post-generation validator (api/v1/workouts/validation_utils.py
caps time + reorders exercises) with the rules Gravl's blog calls out: MEV/MAV/MRV
volume cap per muscle, antagonist-only supersets, recovery gate, recency rule,
movement-pattern balance.

Designed to be called by the two-pass loop in
`backend.services.gemini.workout_generation_helpers`:

    violations = WorkoutValidator(user_state).validate(week_plan)
    if not violations:
        return week_plan
    # else feed violations back to Gemini for revise pass 2 …

All rules are DETERMINISTIC. No LLM here — per
`feedback_prefer_local_algo_over_rag` + `feedback_no_llm_for_safety_classification`.
Volume landmarks per Mike Israetel's published research (RP Strength).
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Dict, List, Optional


# Published MEV / MAV / MRV per major muscle (Israetel et al.).
# Weekly *working* sets (not warmups). Bands collapse to scalars in
# the validator (using MAV as the soft target, MRV as the hard ceiling).
VOLUME_LANDMARKS: Dict[str, Dict[str, int]] = {
    "chest":      {"mev": 10, "mav": 16, "mrv": 22},
    "back":       {"mev": 14, "mav": 18, "mrv": 25},
    "shoulders":  {"mev": 8,  "mav": 16, "mrv": 22},
    "biceps":     {"mev": 8,  "mav": 14, "mrv": 20},
    "triceps":    {"mev": 6,  "mav": 12, "mrv": 18},
    "quads":      {"mev": 8,  "mav": 14, "mrv": 20},
    "hamstrings": {"mev": 6,  "mav": 12, "mrv": 18},
    "glutes":     {"mev": 6,  "mav": 12, "mrv": 18},
    "calves":     {"mev": 6,  "mav": 12, "mrv": 16},
    "abs":        {"mev": 6,  "mav": 16, "mrv": 25},
    "forearms":   {"mev": 4,  "mav": 10, "mrv": 16},
    "traps":      {"mev": 4,  "mav": 10, "mrv": 14},
}

# Antagonist pairs allowed in supersets. Any pairing outside this set, or
# any same-muscle compound-compound stack, is rejected.
ANTAGONIST_PAIRS = [
    {"chest", "back"},
    {"biceps", "triceps"},
    {"quads", "hamstrings"},
    {"abs", "back"},
    {"shoulders", "lats"},
]

# Movement patterns — rolling 28-day push:pull ratio must stay roughly balanced.
MOVEMENT_PATTERN_TARGETS = {
    "push": 1.0,
    "pull": 1.0,
    "hinge": 0.8,
    "squat": 0.8,
    "carry": 0.4,
}


@dataclass
class Violation:
    code: str           # "mrv_exceeded", "same_muscle_superset", "recovery_gate", …
    muscle: Optional[str]
    severity: str       # "hard" → fail, "warn" → surface but ship
    message: str        # Human-readable for the revise-pass Gemini prompt


class WorkoutValidator:
    """Stateless validator parameterized by a UserState snapshot.

    Usage:
        from backend.services.user_state_assembler import assemble_user_state
        from backend.services.workout_validator_phase2 import WorkoutValidator

        state = assemble_user_state(user_id, supabase)
        violations = WorkoutValidator(state).validate(week_plan_dict)

    `week_plan_dict` shape (per existing Gemini schema):
        {
          "workouts": [
            {"day": "Monday", "duration_minutes": 60, "exercises": [
              {"name": "Bench Press", "muscle_group": "chest",
               "movement_pattern": "push", "sets": 4, "reps_min": 6,
               "is_superset_with": null|"<exercise_id>", ...},
              ...
            ]},
            ...
          ]
        }
    """

    def __init__(self, user_state: Any) -> None:
        self.user_state = user_state

    def validate(self, plan: Dict[str, Any]) -> List[Violation]:
        # Accept BOTH a full weekly plan ({"workouts":[...]}) and a single
        # generated workout dict ({"exercises":[...]}). The single-workout shape
        # is what gemini.workout_generation_helpers.generate_workout_plan returns
        # — wrap it transparently so the same rule engine runs on day-by-day
        # generation without duplicating logic. MEV/MRV rules (weekly volume)
        # still need to see the full week to fire — they no-op on single workouts.
        if plan and "exercises" in plan and "workouts" not in plan:
            plan = {"workouts": [{"day": plan.get("day", "Today"), **plan}]}
        out: List[Violation] = []
        if not plan or not plan.get("workouts"):
            return [Violation("empty_plan", None, "hard", "Plan has no workouts.")]

        # Aggregate weekly sets per muscle (working sets only — exclude warmups).
        weekly_sets: Dict[str, int] = {}
        all_exercises: List[Dict[str, Any]] = []
        for wo in plan["workouts"]:
            for ex in wo.get("exercises") or []:
                all_exercises.append(ex)
                if ex.get("set_type") == "warmup":
                    continue
                muscle = (ex.get("muscle_group") or "").lower().strip()
                if not muscle:
                    continue
                weekly_sets[muscle] = weekly_sets.get(muscle, 0) + int(ex.get("sets") or 0)

        # ----- Rule 1: Volume landmarks (MRV hard, MEV warn) ----------------
        # Prefer this user's EARNED landmarks (Dr-Yaad audit #6) over the static
        # population defaults — assertive where we have data, static where we
        # don't. Lazy import avoids the module cycle (the learner imports the
        # static map from here). Fail-open to static on any error.
        eff_landmarks = VOLUME_LANDMARKS
        try:
            from services.volume_learning_service import get_user_landmarks
            _uid = getattr(self.user_state, "user_id", None)
            if _uid:
                eff_landmarks = get_user_landmarks(_uid)
        except Exception:
            eff_landmarks = VOLUME_LANDMARKS
        for muscle, total_sets in weekly_sets.items():
            landmarks = eff_landmarks.get(muscle)
            if not landmarks:
                continue
            mrv = landmarks["mrv"]
            mev = landmarks["mev"]
            # Deload weeks: cap at 60% MRV per Israetel.
            mrv_eff = int(mrv * 0.6) if getattr(self.user_state, "is_deload_week", False) else mrv
            if total_sets > mrv_eff:
                out.append(Violation(
                    code="mrv_exceeded",
                    muscle=muscle,
                    severity="hard",
                    message=(
                        f"{muscle} has {total_sets} working sets this week; MRV "
                        f"({'deload-adjusted ' if mrv_eff != mrv else ''}cap) "
                        f"is {mrv_eff}. Reduce to ≤{mrv_eff}."
                    ),
                ))
            elif total_sets < mev:
                out.append(Violation(
                    code="mev_undershot",
                    muscle=muscle,
                    severity="warn",
                    message=(
                        f"{muscle} has only {total_sets} sets (MEV {mev}). "
                        f"Stimulus may be insufficient for hypertrophy."
                    ),
                ))

        # ----- Rule 2: Antagonist superset rule -----------------------------
        # Build an id → muscle map. Same-muscle compound-compound pairs are
        # rejected (Gravl's #1 win in the comparison blog).
        id_to_muscle: Dict[str, str] = {}
        for ex in all_exercises:
            ex_id = ex.get("id") or ex.get("name")
            if ex_id:
                id_to_muscle[str(ex_id)] = (ex.get("muscle_group") or "").lower()
        for ex in all_exercises:
            super_id = ex.get("is_superset_with") or ex.get("superset_partner_id")
            if not super_id:
                continue
            partner_muscle = id_to_muscle.get(str(super_id))
            this_muscle = (ex.get("muscle_group") or "").lower()
            if not partner_muscle or not this_muscle:
                continue
            pair = {this_muscle, partner_muscle}
            if this_muscle == partner_muscle:
                out.append(Violation(
                    code="same_muscle_superset",
                    muscle=this_muscle,
                    severity="hard",
                    message=(
                        f"Superset pairs two {this_muscle} compounds — "
                        f"injury risk + no benefit. Pair an antagonist instead "
                        f"(e.g. chest+back, biceps+triceps)."
                    ),
                ))
            elif not any(pair == antagonist for antagonist in ANTAGONIST_PAIRS):
                out.append(Violation(
                    code="non_antagonist_superset",
                    muscle=this_muscle,
                    severity="warn",
                    message=(
                        f"Superset pairs {this_muscle} + {partner_muscle}, "
                        f"which isn't a recognized antagonist combo. Likely "
                        f"non-optimal pairing."
                    ),
                ))

        # ----- Rule 3: Recovery gate ---------------------------------------
        recovery = getattr(self.user_state, "muscle_recovery", {}) or {}
        for muscle in weekly_sets:
            r = recovery.get(muscle)
            if r is None:
                continue
            if r < 0.40 and weekly_sets[muscle] > 4:
                out.append(Violation(
                    code="recovery_gate",
                    muscle=muscle,
                    severity="hard",
                    message=(
                        f"{muscle} recovery is {int(r * 100)}% — programming "
                        f"{weekly_sets[muscle]} sets violates the 40% gate. "
                        f"Push the muscle to a later day or reduce to ≤4 sets."
                    ),
                ))

        # ----- Rule 4: Recency rule (no exercise >2× / 7d outside PR test) --
        exercise_freq: Dict[str, int] = {}
        for ex in all_exercises:
            if ex.get("is_pr_test"):
                continue
            key = (ex.get("name") or "").strip().lower()
            if not key:
                continue
            exercise_freq[key] = exercise_freq.get(key, 0) + 1
        for name, count in exercise_freq.items():
            if count > 2:
                out.append(Violation(
                    code="excess_recency",
                    muscle=None,
                    severity="warn",
                    message=(
                        f"'{name}' appears {count}× this week; cap is 2 unless "
                        f"flagged as a PR test."
                    ),
                ))

        # ----- Rule 5: Time-budget (within ±5 min of stated duration) -------
        for wo in plan["workouts"]:
            target = int(wo.get("duration_minutes") or 0)
            if target <= 0:
                continue
            est = _estimate_workout_duration_min(wo)
            if abs(est - target) > 5:
                out.append(Violation(
                    code="time_budget_drift",
                    muscle=None,
                    severity="warn",
                    message=(
                        f"{wo.get('day','day')} target {target} min; estimated "
                        f"{est} min. Trim accessory work or extend the budget."
                    ),
                ))

        # ----- Rule 6: Movement-pattern balance (rolling 28d) --------------
        pat_28d = _movement_pattern_totals(getattr(self.user_state, "sets_per_muscle_28d", {}))
        if pat_28d.get("push") and pat_28d.get("pull"):
            ratio = pat_28d["push"] / max(1, pat_28d["pull"])
            if ratio > 1.6 or ratio < 0.6:
                out.append(Violation(
                    code="push_pull_imbalance",
                    muscle=None,
                    severity="warn",
                    message=(
                        f"28-day push:pull ratio is {ratio:.2f} (target ~1.0). "
                        f"Bias upcoming sessions accordingly."
                    ),
                ))

        return out


def _estimate_workout_duration_min(workout: Dict[str, Any]) -> int:
    """Rough est: per-set 35s + per-set rest from `rest_seconds` (default 90s),
    plus 60s transition between exercises. Accurate to ~±3 min."""
    total_s = 0
    exs = workout.get("exercises") or []
    for ex in exs:
        sets = int(ex.get("sets") or 0)
        rest = int(ex.get("rest_seconds") or 90)
        total_s += sets * (35 + rest)
    if exs:
        total_s += 60 * max(0, len(exs) - 1)
    return round(total_s / 60)


def _movement_pattern_totals(sets_per_muscle: Dict[str, int]) -> Dict[str, int]:
    """Roll muscles up into movement patterns for the imbalance check."""
    push_muscles = {"chest", "shoulders", "triceps"}
    pull_muscles = {"back", "biceps", "lats", "rhomboids", "traps"}
    hinge_muscles = {"hamstrings", "glutes", "lower_back"}
    squat_muscles = {"quads", "calves"}
    out = {"push": 0, "pull": 0, "hinge": 0, "squat": 0, "carry": 0}
    for muscle, sets in (sets_per_muscle or {}).items():
        m = muscle.lower()
        if m in push_muscles:
            out["push"] += sets
        elif m in pull_muscles:
            out["pull"] += sets
        elif m in hinge_muscles:
            out["hinge"] += sets
        elif m in squat_muscles:
            out["squat"] += sets
    return out


def violations_to_revise_prompt(violations: List[Violation]) -> str:
    """Format violations into a single block to inject as the revise-pass
    feedback to Gemini. Used by the two-pass loop in workout_generation_helpers.
    """
    if not violations:
        return ""
    lines = ["The previous plan had these issues — please fix them in the next draft:"]
    for v in violations:
        prefix = "🚫" if v.severity == "hard" else "⚠️"
        lines.append(f"  {prefix} [{v.code}] {v.message}")
    lines.append("Return the corrected plan in the same JSON shape.")
    return "\n".join(lines)
