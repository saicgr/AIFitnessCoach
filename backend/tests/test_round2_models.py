"""Round-2 model contract tests (2026-06-23).

Locks the two schema fixes that unblock per-day customization:
  - UserUpdate.preferences accepts a dict (the app PUTs a JSON object) — the
    str-only typing was the 422 that prevented per-day overrides from saving.
  - GenerateWorkoutRequest.intensity_preference exists so today.py can thread a
    per-day "Hell"/"Hard" into generation.

Import-safe under py3.9 (no app/conftest import needed).
"""
import pytest


def test_user_update_accepts_preferences_dict():
    from models.user import UserUpdate

    # The per-day editor PUTs preferences as a dict — must NOT raise.
    u = UserUpdate(preferences={"workout_day_overrides": {"1": {"focus": "upper_body",
                                                                "duration_min": 90,
                                                                "intensity": "hell"}}})
    assert isinstance(u.preferences, dict)
    assert u.preferences["workout_day_overrides"]["1"]["intensity"] == "hell"


def test_user_update_still_accepts_preferences_string():
    from models.user import UserUpdate

    u = UserUpdate(preferences='{"a": 1}')
    assert isinstance(u.preferences, str)


def test_generate_request_has_intensity_preference():
    from models.schemas import GenerateWorkoutRequest

    r = GenerateWorkoutRequest(user_id="u1", intensity_preference="hell",
                               duration_minutes=90, focus_areas=["upper_body"])
    assert r.intensity_preference == "hell"
    assert r.duration_minutes == 90

    # Default is None so endpoints can fall back to stored prefs.
    assert GenerateWorkoutRequest(user_id="u1").intensity_preference is None


if __name__ == "__main__":
    import sys
    sys.exit(pytest.main([__file__, "-v"]))
