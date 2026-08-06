"""Regression gate for UI_E2E 2026-08-05 row 1 (CRIT) / row 56 (HIGH).

Root cause: strength/fitness score recalc (``schedule_score_recalc``) and
trophy checks (``check_workout_completion_trophies``) were wired ONLY into
``POST /workouts/{id}/complete`` (api/v1/workouts/crud_completion.py). But
migration 2256's ``trg_sync_workout_completion`` trigger flips
``workouts.is_completed = true`` directly in Postgres whenever a
``workout_logs`` row's status becomes 'completed' — a path that
``POST /performance/workout-logs`` (create) and
``PATCH /performance/workout-logs/{id}`` (Easy-tier finalize) both take
WITHOUT ever calling ``/complete``. Verified live against the QA account:
2 completed workouts, ZERO rows in strength_scores/fitness_scores/
user_achievements/trophy_progress, and ZERO ``workout_changes`` rows with
change_type='completed' — proving neither completion ever passed through
``/complete``.

These tests assert the DEFECT (the missing wiring), not merely that some
function exists. Each source-inspection test would FAIL against the
pre-fix code (verified by reverting the fix and re-running — see PR
description / task report).
"""
import inspect
import asyncio

import pytest


# ---------------------------------------------------------------------------
# 1. The two previously-silent write paths now call the shared hook.
# ---------------------------------------------------------------------------

def test_create_workout_log_fires_post_completion_hooks_when_status_completed():
    import api.v1.performance_db as pdb

    src = inspect.getsource(pdb.create_workout_log)
    assert "derived_status == \"completed\"" in src, (
        "create_workout_log must gate the hook on the SAME status it derives "
        "and persists — not on a client-supplied field"
    )
    assert "run_post_completion_hooks" in src, (
        "POST /performance/workout-logs can independently flip "
        "workouts.is_completed via migration 2256's trigger; it must fire "
        "the same score-recalc + trophy-check hooks /complete fires, or "
        "every completion that goes through this path (e.g. the reliable "
        "log-first client flow) never gets a strength/fitness score or a "
        "trophy check."
    )


def test_update_workout_log_finalize_fires_post_completion_hooks():
    import api.v1.performance_db as pdb

    src = inspect.getsource(pdb.update_workout_log)
    assert "run_post_completion_hooks" in src, (
        "PATCH /performance/workout-logs/{id} is the Easy-tier finalize call "
        "that actually flips a session to 'completed' for that tier; it must "
        "fire the same post-completion hooks or Easy-tier completions never "
        "get scored or trophy-checked."
    )
    assert "was_already_completed" in src, (
        "the hook must be guarded on the PRE-patch status so a later no-op "
        "PATCH on an already-completed log doesn't re-fire it every time"
    )


# ---------------------------------------------------------------------------
# 2. The shared hook itself: both sub-hooks fire and each is fault-isolated.
# ---------------------------------------------------------------------------

class _FakeSupabase:
    def table(self, name):
        return self

    def select(self, *a, **k):
        return self

    def eq(self, *a, **k):
        return self

    def maybe_single(self):
        return self

    def execute(self):
        class _Resp:
            data = {"exercises_json": [{"name": "Bench Press", "primary_muscle": "chest"}]}
        return _Resp()


def test_run_post_completion_hooks_calls_both_score_and_trophy_paths(monkeypatch):
    from services import workout_completion_hooks as hooks

    calls = {"score": None, "trophy": None}

    def fake_schedule_score_recalc(user_id, supabase, timezone_str):
        calls["score"] = (user_id, timezone_str)

    async def fake_check_workout_completion_trophies(user_id, workout_data):
        calls["trophy"] = (user_id, workout_data)
        return []

    import api.v1.workouts.crud_background_tasks as cbt
    import api.v1.trophy_triggers as tt

    monkeypatch.setattr(cbt, "schedule_score_recalc", fake_schedule_score_recalc)
    monkeypatch.setattr(tt, "check_workout_completion_trophies", fake_check_workout_completion_trophies)

    asyncio.run(hooks.run_post_completion_hooks(
        user_id="u1", supabase=_FakeSupabase(), timezone_str="America/Chicago", workout_id="w1",
    ))

    assert calls["score"] == ("u1", "America/Chicago")
    assert calls["trophy"] is not None
    assert calls["trophy"][0] == "u1"
    assert calls["trophy"][1]["exercises"][0]["name"] == "Bench Press"


def test_run_post_completion_hooks_score_failure_does_not_block_trophy_check(monkeypatch):
    """Fault isolation: a broken score recalc must never suppress trophy checks."""
    from services import workout_completion_hooks as hooks

    trophy_called = {"fired": False}

    def raising_schedule(*a, **k):
        raise RuntimeError("boom")

    async def fake_check_workout_completion_trophies(user_id, workout_data):
        trophy_called["fired"] = True
        return []

    import api.v1.workouts.crud_background_tasks as cbt
    import api.v1.trophy_triggers as tt

    monkeypatch.setattr(cbt, "schedule_score_recalc", raising_schedule)
    monkeypatch.setattr(tt, "check_workout_completion_trophies", fake_check_workout_completion_trophies)

    # Must not raise.
    asyncio.run(hooks.run_post_completion_hooks(
        user_id="u1", supabase=_FakeSupabase(), timezone_str="UTC", workout_id=None,
    ))

    assert trophy_called["fired"] is True
