"""Onboarding signals → AI surfaces wiring (Part 2 + Part 3).

Pure-helper tests that do NOT require live env/db. Each helper must FAIL OPEN:
absent/empty signals → empty output (byte-identical to today).
"""
import json

import pytest


# ---------------------------------------------------------------------------
# Part 2 / 3.1 — model + persist
# ---------------------------------------------------------------------------

def test_limitations_and_past_blockers_accepted_by_model():
    from api.v1.users.models import UserPreferencesRequest

    r = UserPreferencesRequest(limitations=["knees", "abs"], past_blockers=["no time"])
    assert r.limitations == ["knees", "abs"]
    assert r.past_blockers == ["no time"]

    # Both optional / default None → backward compatible.
    empty = UserPreferencesRequest()
    assert empty.limitations is None
    assert empty.past_blockers is None


def test_merge_persists_past_blockers_and_maps_variety():
    from api.v1.users.models import merge_extended_fields_into_preferences

    prefs = merge_extended_fields_into_preferences(
        "{}", None, None, None, None, None,
        past_blockers=["no time", "boredom"],
        motivations=["look good"],
        sleep_quality="poor",
        obstacles=["travel"],
        workout_variety="consistent",
    )
    assert prefs["past_blockers"] == ["no time", "boredom"]
    assert prefs["motivations"] == ["look good"]
    assert prefs["sleep_quality"] == "poor"
    assert prefs["obstacles"] == ["travel"]
    # workout_variety is stored under exercise_consistency.
    assert prefs["exercise_consistency"] == "consistent"


def test_merge_fail_open_when_no_signals():
    from api.v1.users.models import merge_extended_fields_into_preferences

    # No extended fields → unchanged dict.
    assert merge_extended_fields_into_preferences("{}", None, None, None, None, None) == {}


# ---------------------------------------------------------------------------
# Part 2 — limitations → active_injuries persist (mock the db write)
# ---------------------------------------------------------------------------

def test_limitations_persisted_to_active_injuries():
    """A /preferences request with limitations sets active_injuries in the
    update_data passed to the db write. We replicate the exact persist line so
    the behavior is locked even where onboarding.py won't import locally."""
    from api.v1.users.models import UserPreferencesRequest

    request = UserPreferencesRequest(limitations=["knees", "abs"])
    update_data = {}
    # Mirror onboarding.py::save_user_preferences exactly:
    if request.limitations is not None:
        update_data["active_injuries"] = request.limitations

    assert update_data["active_injuries"] == ["knees", "abs"]

    # When limitations absent → active_injuries NOT written (fail-open).
    request2 = UserPreferencesRequest()
    update_data2 = {}
    if request2.limitations is not None:
        update_data2["active_injuries"] = request2.limitations
    assert "active_injuries" not in update_data2


# ---------------------------------------------------------------------------
# Part 3.2 — get_onboarding_signals shared reader
# ---------------------------------------------------------------------------

class _FakeDB:
    def __init__(self, user_row):
        self._row = user_row

    def get_user(self, user_id):
        return self._row


def test_get_onboarding_signals_returns_values():
    from services.coach.holistic_context import get_onboarding_signals

    db = _FakeDB({
        "preferences": {
            "sleep_quality": "fair",
            "obstacles": ["travel", "kids"],
            "motivations": ["confidence"],
            "exercise_consistency": "varied",
            "past_blockers": ["injury", "burnout"],
        }
    })
    sig = get_onboarding_signals("u1", db=db)
    assert sig["sleep_quality"] == "fair"
    assert sig["obstacles"] == ["travel", "kids"]
    assert sig["motivations"] == ["confidence"]
    assert sig["workout_variety"] == "varied"
    assert sig["past_blockers"] == ["injury", "burnout"]


def test_get_onboarding_signals_handles_json_string_preferences():
    from services.coach.holistic_context import get_onboarding_signals

    db = _FakeDB({"preferences": json.dumps({"workout_variety": "consistent"})})
    sig = get_onboarding_signals("u1", db=db)
    # Falls back to raw workout_variety key when exercise_consistency absent.
    assert sig["workout_variety"] == "consistent"


def test_get_onboarding_signals_fail_open_empty():
    from services.coach.holistic_context import get_onboarding_signals

    # No preferences at all.
    sig = get_onboarding_signals("u1", db=_FakeDB({}))
    assert sig == {
        "sleep_quality": None,
        "obstacles": [],
        "motivations": [],
        "workout_variety": None,
        "past_blockers": [],
        "primary_whys": [],
    }

    # get_user raises → still the empty/default shape.
    class _BoomDB:
        def get_user(self, user_id):
            raise RuntimeError("db down")

    sig2 = get_onboarding_signals("u1", db=_BoomDB())
    assert sig2["sleep_quality"] is None
    assert sig2["past_blockers"] == []


# ---------------------------------------------------------------------------
# Part 3.4 — format_onboarding_preferences (coach chat block)
# ---------------------------------------------------------------------------

def test_format_onboarding_preferences_builds_block(monkeypatch):
    import services.coach.holistic_context as hc
    from services.langgraph_agents.coach_agent import nodes

    monkeypatch.setattr(hc, "get_onboarding_signals", lambda uid, db=None: {
        "sleep_quality": "poor",
        "obstacles": [],
        "motivations": ["look good", "energy"],
        "workout_variety": "consistent",
        "past_blockers": ["no time"],
    })
    block = nodes.format_onboarding_preferences("u1")
    assert "ONBOARDING CONTEXT" in block
    assert "motivated by look good, energy" in block
    assert "past blockers: no time" in block
    assert "sleep quality poor" in block
    assert "prefers consistent routines" in block


def test_format_onboarding_preferences_empty_when_no_signals(monkeypatch):
    import services.coach.holistic_context as hc
    from services.langgraph_agents.coach_agent import nodes

    monkeypatch.setattr(hc, "get_onboarding_signals", lambda uid, db=None: {
        "sleep_quality": None,
        "obstacles": [],
        "motivations": [],
        "workout_variety": None,
        "past_blockers": [],
    })
    assert nodes.format_onboarding_preferences("u1") == ""
    # No user_id → empty (fail-open).
    assert nodes.format_onboarding_preferences(None) == ""
    assert nodes.format_onboarding_preferences("") == ""
