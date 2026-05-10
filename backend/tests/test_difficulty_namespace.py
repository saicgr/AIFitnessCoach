"""Phase F — workout `difficulty` is strictly {easy, medium, hard, hell}.

The 2026-05-08 sweep shipped `difficulty="beginner"` on 145/428 OK rows
because `safety_mode.build_plan` and the validator allowed fitness-level
tokens to leak into the workout-difficulty namespace. This test fails
loudly if that regression returns.
"""
import pytest
from pydantic import ValidationError

from models.schemas import (
    _coerce_workout_difficulty,
    ALLOWED_WORKOUT_DIFFICULTIES,
    Workout,
    WorkoutCreate,
    WorkoutUpdate,
    RegenerateWorkoutRequest,
)


def test_allowed_set_is_strict():
    assert ALLOWED_WORKOUT_DIFFICULTIES == {"easy", "medium", "hard", "hell"}


@pytest.mark.parametrize("legacy,expected", [
    ("beginner", "easy"),
    ("Beginner", "easy"),
    ("INTERMEDIATE", "medium"),
    ("advanced", "hard"),
    ("hell", "hell"),
    ("MEDIUM", "medium"),
    ("Easy", "easy"),
])
def test_legacy_fitness_level_normalized(legacy, expected):
    assert _coerce_workout_difficulty(legacy) == expected


@pytest.mark.parametrize("bad", ["bogus", "extreme", "ultra", "novice", "expert"])
def test_unknown_value_rejected(bad):
    with pytest.raises(ValueError):
        _coerce_workout_difficulty(bad)


def test_none_passthrough():
    assert _coerce_workout_difficulty(None) is None
    assert _coerce_workout_difficulty("") == ""


def test_workout_create_normalizes_legacy():
    w = WorkoutCreate(
        user_id="u", name="x", type="strength", difficulty="beginner",
        scheduled_date="2026-04-20T00:00:00+00:00",
        exercises_json="[]",
    )
    assert w.difficulty == "easy"


def test_workout_create_rejects_bogus():
    with pytest.raises(ValidationError):
        WorkoutCreate(
            user_id="u", name="x", type="strength", difficulty="bogus",
            scheduled_date="2026-04-20T00:00:00+00:00",
            exercises_json="[]",
        )


def test_regenerate_request_normalizes():
    r = RegenerateWorkoutRequest(
        workout_id="w", user_id="u", difficulty="advanced",
    )
    assert r.difficulty == "hard"


def test_safety_mode_returns_easy_not_beginner():
    """The literal that caused 145/428 sweep rows to ship `beginner`."""
    import asyncio
    from unittest.mock import patch
    from services.exercise_rag.safety_mode import build_plan
    from services.workout_safety_validator import UserSafetyContext

    async def _run():
        with patch("services.exercise_rag.safety_mode._get_engine") as ge:
            # No-op engine — force the static fallback path. We only care
            # about the `difficulty` field on the returned plan.
            class _NoopConn:
                async def __aenter__(self): return self
                async def __aexit__(self, *a): return None
                async def execute(self, *a, **kw):
                    raise RuntimeError("noop")
            class _NoopEng:
                def connect(self): return _NoopConn()
            ge.return_value = _NoopEng()
            ctx = UserSafetyContext(
                injuries=["knee"], difficulty="easy", equipment=[], user_id="u",
            )
            return await build_plan(ctx, duration_minutes=15, focus_areas=["mobility"])

    plan = asyncio.run(_run())
    assert plan["difficulty"] == "easy", (
        "safety_mode must return difficulty='easy', not 'beginner' — "
        f"got {plan['difficulty']!r}"
    )
    assert plan["difficulty"] in ALLOWED_WORKOUT_DIFFICULTIES
