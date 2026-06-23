"""Unit tests for the program-change plumbing added 2026-06-23.

Covers the pure / import-safe pieces:
  - `_parse_workout_day_overrides` carries `gym_profile_id`, clamps day keys
    0..6, drops orphans/malformed, returns None when empty.
  - `UpdateProgramRequest.regenerate` defaults True (back-compat) and accepts
    an explicit False (the new "ask me each time" flow).

DB-backed pieces (invalidate_workouts_after_program_change, the
/regenerate-upcoming endpoint, the dont_know->ai_decide write-canon) are
exercised in CI's HTTP suite (threaded uvicorn + httpx); local `.venv` is
py3.9 so heavy imports may fail locally only.
"""
import pytest


def test_parse_overrides_carries_gym_profile_id():
    from api.v1.workouts.generation_endpoints import _parse_workout_day_overrides

    raw = {
        "0": {"focus": "full_body", "gym_profile_id": "gym-1"},
        "1": {"focus": "upper_body", "duration_min": 30, "intensity": "hard"},
    }
    parsed = _parse_workout_day_overrides(raw)
    assert parsed is not None
    assert parsed[0]["gym_profile_id"] == "gym-1"          # mixed-gym week primitive
    assert parsed[1].get("gym_profile_id") is None
    assert parsed[1]["duration_min"] == 30


def test_parse_overrides_clamps_and_drops_orphans():
    from api.v1.workouts.generation_endpoints import _parse_workout_day_overrides

    raw = {
        "2": {"focus": "legs"},
        "9": {"focus": "core"},        # out of 0..6 -> dropped
        "x": {"focus": "push"},        # non-int key -> dropped
        "3": "not-a-dict",             # non-dict value -> dropped
    }
    parsed = _parse_workout_day_overrides(raw)
    assert set(parsed.keys()) == {2}


def test_parse_overrides_empty_returns_none():
    from api.v1.workouts.generation_endpoints import _parse_workout_day_overrides

    assert _parse_workout_day_overrides(None) is None
    assert _parse_workout_day_overrides({}) is None
    assert _parse_workout_day_overrides("garbage") is None


def test_update_program_request_regenerate_default_true():
    from models.schemas import UpdateProgramRequest

    # Existing callers omit the flag -> defaults True (apply immediately).
    req = UpdateProgramRequest(user_id="u1")
    assert req.regenerate is True

    # New "ask me each time" editor opts out explicitly.
    req2 = UpdateProgramRequest(user_id="u1", regenerate=False)
    assert req2.regenerate is False


if __name__ == "__main__":
    import sys
    sys.exit(pytest.main([__file__, "-v"]))
