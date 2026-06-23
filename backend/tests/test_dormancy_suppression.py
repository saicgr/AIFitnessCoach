"""Unit tests for dormancy-band push suppression + win-back taper gating.

Covers the fail-open guarantees that protect ACTIVE users and the per-band
allow-lists. The suppression module is pure (stdlib only), so these run without
DB or app wiring. The DORMANCY_TAPER_ENABLED flag is read at import time, so we
set it before importing and reload to flip it.
"""
import importlib
import os
import sys

# Make the backend root importable regardless of how this file is invoked.
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def _load(enabled: bool):
    os.environ["DORMANCY_TAPER_ENABLED"] = "true" if enabled else "false"
    import services.notification_suppression as m
    importlib.reload(m)
    return m


def _user():
    return {"id": "u1", "timezone": "UTC"}


def test_flag_off_is_noop():
    m = _load(False)
    # Even a dormant user with a routine reminder is NOT suppressed when off.
    assert m.should_suppress_notification(_user(), "morning_workout",
                                          dormancy_band="dormant") is None


def test_active_band_never_suppresses():
    m = _load(True)
    for nt in ("morning_workout", "meal_reminder", "habit_reminder", "daily_crate"):
        assert m.should_suppress_notification(_user(), nt, dormancy_band="active") is None


def test_missing_band_fails_open():
    m = _load(True)
    assert m.should_suppress_notification(_user(), "meal_reminder", dormancy_band=None) is None


def test_cooling_keeps_workout_drops_routine():
    m = _load(True)
    # Allowed in cooling.
    assert m.should_suppress_notification(_user(), "morning_workout", dormancy_band="cooling") is None
    assert m.should_suppress_notification(_user(), "streak_at_risk", dormancy_band="cooling") is None
    # Routine noise suppressed in cooling.
    assert m.should_suppress_notification(_user(), "meal_reminder", dormancy_band="cooling") == "dormancy_cooling"
    assert m.should_suppress_notification(_user(), "daily_crate", dormancy_band="cooling") == "dormancy_cooling"


def test_lapsed_suppresses_routine_allows_winback_and_health():
    m = _load(True)
    assert m.should_suppress_notification(_user(), "morning_workout", dormancy_band="lapsed") == "dormancy_lapsed"
    assert m.should_suppress_notification(_user(), "winback_day7", dormancy_band="lapsed") is None
    assert m.should_suppress_notification(_user(), "sleep_score", dormancy_band="lapsed") is None


def test_dormant_only_winback():
    m = _load(True)
    assert m.should_suppress_notification(_user(), "sleep_score", dormancy_band="dormant") == "dormancy_dormant"
    assert m.should_suppress_notification(_user(), "winback_day14", dormancy_band="dormant") is None


def test_critical_always_passes_every_band():
    m = _load(True)
    for band in ("cooling", "lapsed", "dormant", "deep_dormant"):
        assert m.should_suppress_notification(_user(), "billing_reminder", dormancy_band=band) is None
        assert m.should_suppress_notification(_user(), "live_chat_message", dormancy_band=band) is None


def test_unknown_band_fails_open():
    m = _load(True)
    assert m.should_suppress_notification(_user(), "meal_reminder", dormancy_band="weird") is None


if __name__ == "__main__":
    test_flag_off_is_noop()
    test_active_band_never_suppresses()
    test_missing_band_fails_open()
    test_cooling_keeps_workout_drops_routine()
    test_lapsed_suppresses_routine_allows_winback_and_health()
    test_dormant_only_winback()
    test_critical_always_passes_every_band()
    test_unknown_band_fails_open()
    print("✅ all dormancy suppression tests passed")
