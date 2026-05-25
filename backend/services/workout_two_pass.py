"""
workout_two_pass.py — Phase 2.C of workouts overhaul.

Two-pass generation loop. Callers pass a Gemini-generating async callable +
a UserState; this module runs it, validates the output with
`workout_validator_phase2`, and if there are HARD violations, re-prompts
Gemini once with explicit feedback. On a second hard failure, falls back to
the deterministic builder (Phase 2.J).

Designed as a wrapper around existing generation entry points so the 1300-line
`workout_generation_helpers.py` doesn't need invasive edits. Adopting callers:
- `holistic_plan_service.generate_weekly_plan` (recommended)
- Any future generation endpoint that wants validator-backed quality.

Telemetry: counts pass-1 / pass-2 / fallback outcomes to /metrics so a
regression in validator pass rate is visible.
"""
from __future__ import annotations

import logging
from typing import Any, Awaitable, Callable, Dict, List, Optional

from .deterministic_workout_builder import (
    BuildOptions,
    build_weekly_plan as deterministic_weekly,
)
from .workout_validator_phase2 import (
    Violation,
    WorkoutValidator,
    violations_to_revise_prompt,
)

logger = logging.getLogger(__name__)


# Lightweight in-process metrics. Replace with prometheus_client when /metrics
# is plumbed; the count names match what we'd export.
_METRICS = {
    "two_pass_pass1_ok": 0,
    "two_pass_pass1_warned": 0,
    "two_pass_pass2_ok": 0,
    "two_pass_pass2_failed": 0,
    "two_pass_fallback_fired": 0,
}


def get_metrics() -> Dict[str, int]:
    return dict(_METRICS)


async def generate_with_validation(
    user_state: Any,
    primary_generator: Callable[..., Awaitable[Dict[str, Any]]],
    revise_generator: Optional[Callable[..., Awaitable[Dict[str, Any]]]] = None,
    deterministic_fallback_args: Optional[Dict[str, Any]] = None,
    *gen_args: Any,
    **gen_kwargs: Any,
) -> Dict[str, Any]:
    """Generate a weekly plan with two passes + deterministic fallback.

    Args:
        user_state: UserState from assemble_user_state(); passed to validator.
        primary_generator: async callable returning a plan dict
            (shape: {"workouts": [...]}).
        revise_generator: optional separate callable for the revise pass. If
            omitted, primary_generator is called again with a `revise_feedback`
            kwarg containing the violations text.
        deterministic_fallback_args: if both Gemini passes fail, this dict is
            unpacked into BuildOptions for the deterministic builder. Must
            include at least `splits: List[str]`.
        *gen_args / **gen_kwargs: forwarded to primary_generator.

    Returns:
        The validated plan dict with `_validation` metadata attached:
            {"_validation": {"passes": int, "violations": [str], "source": str}}
    """
    # Pass 1
    pass1 = await primary_generator(*gen_args, **gen_kwargs)
    violations = WorkoutValidator(user_state).validate(pass1)
    hard = [v for v in violations if v.severity == "hard"]
    warn = [v for v in violations if v.severity == "warn"]

    if not hard:
        _METRICS["two_pass_pass1_ok"] += 1
        if warn:
            _METRICS["two_pass_pass1_warned"] += 1
        pass1["_validation"] = {
            "passes": 1,
            "violations": [v.message for v in warn],
            "source": "gemini_pass1",
        }
        return pass1

    # Revise pass
    feedback = violations_to_revise_prompt(violations)
    logger.warning(
        f"🔁 [two-pass] pass1 hard violations={len(hard)}; "
        f"revising with feedback:\n{feedback}"
    )
    try:
        if revise_generator is not None:
            pass2 = await revise_generator(feedback, *gen_args, **gen_kwargs)
        else:
            pass2 = await primary_generator(
                *gen_args, revise_feedback=feedback, **gen_kwargs
            )
    except TypeError:
        # Caller doesn't accept revise_feedback kwarg — call again unchanged.
        pass2 = await primary_generator(*gen_args, **gen_kwargs)

    violations2 = WorkoutValidator(user_state).validate(pass2)
    hard2 = [v for v in violations2 if v.severity == "hard"]
    warn2 = [v for v in violations2 if v.severity == "warn"]

    if not hard2:
        _METRICS["two_pass_pass2_ok"] += 1
        pass2["_validation"] = {
            "passes": 2,
            "violations": [v.message for v in warn2],
            "source": "gemini_pass2",
        }
        return pass2

    # Deterministic fallback
    _METRICS["two_pass_pass2_failed"] += 1
    _METRICS["two_pass_fallback_fired"] += 1
    logger.error(
        f"🛟 [two-pass] both passes failed — falling back to deterministic builder. "
        f"pass2 hard violations: {[v.code for v in hard2]}"
    )

    if not deterministic_fallback_args or "splits" not in deterministic_fallback_args:
        # No fallback args supplied — return pass2 with warning, surface to caller.
        pass2["_validation"] = {
            "passes": 2,
            "violations": [v.message for v in hard2],
            "source": "gemini_pass2_failed_no_fallback",
        }
        return pass2

    options = BuildOptions(
        duration_minutes=deterministic_fallback_args.get("duration_minutes", 60),
        progression_style=deterministic_fallback_args.get("progression_style", "straight"),
        is_deload_week=bool(getattr(user_state, "is_deload_week", False)),
        user_equipment_categories=deterministic_fallback_args.get(
            "user_equipment_categories",
            list(getattr(user_state, "equipment_categories_available", [])) or None,
        ),
        injured_body_parts=list(getattr(user_state, "injured_body_parts", []) or []),
        muscle_recovery=dict(getattr(user_state, "muscle_recovery", {}) or {}),
    )
    fallback = deterministic_weekly(deterministic_fallback_args["splits"], options)
    fallback["_validation"] = {
        "passes": 2,
        "violations": [v.message for v in hard2],
        "source": "deterministic_fallback",
    }
    return fallback
