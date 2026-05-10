"""Unit tests for services/logging/catalog.py.

Verifies the deterministic activity / unit / time resolvers used by the
conversational event-logging pipeline.
"""
import os
import sys

import pytest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from services.logging.catalog import (
    estimate_calories,
    get_activity,
    resolve_activity,
    resolve_day_offset,
    resolve_time_of_day,
    resolve_unit,
    steps_to_walking_minutes,
)


# ---------------------------------------------------------------------------
# Activity resolution
# ---------------------------------------------------------------------------

@pytest.mark.parametrize("phrase,canonical_id", [
    ("I did 30 min yoga today", "yoga"),
    ("Did vinyasa for 45 mins", "yoga"),
    ("Played pickup basketball with friends", "basketball"),
    ("Went for a 10000 step walk in the evening", "walk"),
    ("Walked the dog for an hour", "walk"),
    ("Ran 5k this morning", "run"),
    ("Just got back from a 1 hour swim practice", "swim"),
    ("Did 30 min cycling at the gym", "cycling"),
    ("Stairmaster 20 min level 8", "stairmaster"),
    ("Hit the gym today", "strength"),
    ("Crushed legs at the gym", "strength"),
    ("Quick 20 minute HIIT session", "hiit"),
    ("Did some stretching for 15 mins", "stretching"),
    ("Foam rolled for 10 minutes", "stretching"),
    ("Played soccer scrimmage", "soccer"),
    ("Pickleball with my friend", "pickleball"),
    ("BJJ training", "martial_arts"),
    ("Bouldering session", "climbing"),
    ("Surfed for an hour", "surfing"),
    ("Took a rest day", "rest"),
    ("Reformer pilates class", "pilates"),
])
def test_resolve_activity_known_phrasings(phrase: str, canonical_id: str):
    activity = resolve_activity(phrase)
    assert activity is not None, f"Failed to resolve {phrase!r}"
    assert activity.canonical_id == canonical_id, (
        f"{phrase!r} → {activity.canonical_id} (expected {canonical_id})"
    )


def test_resolve_activity_returns_none_for_unknown():
    assert resolve_activity("ate a sandwich") is None
    assert resolve_activity("") is None
    assert resolve_activity(None) is None


def test_get_activity_by_canonical_id():
    a = get_activity("yoga")
    assert a is not None
    assert a.display_name == "Yoga"
    assert a.met == 2.5
    assert a.icon == "self_improvement"
    assert get_activity("bogus") is None


def test_strength_needs_followup_body_part():
    a = get_activity("strength")
    assert a is not None
    assert "body_part" in a.needs_followup


def test_rest_logs_as_rest_day_not_workout():
    a = get_activity("rest")
    assert a is not None
    assert a.logs_as == "rest_day"
    assert a.met == 0.0


# Disambiguation: longer alias should win over shorter substring.
def test_lap_swim_resolves_to_swim_not_a_substring_collision():
    activity = resolve_activity("Did some lap swim today")
    assert activity is not None
    assert activity.canonical_id == "swim"


def test_dog_walk_resolves_to_walk():
    activity = resolve_activity("Took the dog walk after dinner")
    assert activity is not None
    assert activity.canonical_id == "walk"


# ---------------------------------------------------------------------------
# Unit conversion
# ---------------------------------------------------------------------------

@pytest.mark.parametrize("unit_str,canonical_value", [
    # time → minutes
    ("min", 60),
    ("minutes", 60),
    ("hours", 3600),  # 60 hours → 3600 minutes
    ("h", 3600),
    ("seconds", 1),  # 60 seconds → 1 minute
    # distance → km
    ("km", 60),
    ("miles", pytest.approx(96.5604)),
    ("mi", pytest.approx(96.5604)),
    # volume → ml
    ("oz", pytest.approx(1774.41, rel=1e-3)),  # 60 oz → 1774 ml
    ("cups", 14400),
    ("liters", 60000),
    ("gallon", pytest.approx(227124.6)),
    # weight → kg
    ("lbs", pytest.approx(27.2155, rel=1e-3)),  # 60 lbs → 27.2 kg
    ("kg", 60),
])
def test_resolve_unit_and_convert_60(unit_str: str, canonical_value):
    unit = resolve_unit(unit_str)
    assert unit is not None, f"Failed to resolve unit {unit_str!r}"
    assert unit.to_canonical(60) == canonical_value


def test_unknown_unit_returns_none():
    assert resolve_unit("furlongs") is None
    assert resolve_unit("") is None


# ---------------------------------------------------------------------------
# Steps → minutes estimation
# ---------------------------------------------------------------------------

def test_steps_to_walking_minutes_typical():
    # 10,000 steps ÷ 110 steps/min ≈ 91 min
    assert steps_to_walking_minutes(10000) == 91


def test_steps_to_walking_minutes_handles_edges():
    assert steps_to_walking_minutes(0) == 0
    assert steps_to_walking_minutes(50) == 1  # rounds up to a sensible minimum
    assert steps_to_walking_minutes(-100) == 0


# ---------------------------------------------------------------------------
# Calorie estimation (MET formula)
# ---------------------------------------------------------------------------

def test_estimate_calories_yoga_30min_70kg():
    # Yoga MET 2.5 × 70kg × 0.5h = 87.5 kcal
    assert estimate_calories(2.5, 70.0, 30) == 88


def test_estimate_calories_hiit_20min_80kg():
    # HIIT MET 9.0 × 80kg × (20/60)h = 240 kcal
    assert estimate_calories(9.0, 80.0, 20) == 240


def test_estimate_calories_zero_inputs_return_zero():
    assert estimate_calories(0, 70, 30) == 0
    assert estimate_calories(5, 0, 30) == 0
    assert estimate_calories(5, 70, 0) == 0


# ---------------------------------------------------------------------------
# Time-of-day + day-offset hints
# ---------------------------------------------------------------------------

@pytest.mark.parametrize("phrase,window", [
    ("I did yoga this morning", (5, 11)),
    ("Walked at lunch", (11, 14)),
    ("Worked out this evening", (17, 21)),
    ("Slept 8 hours last night", (19, 23)),
    ("Ran tonight after dinner", (19, 23)),
])
def test_resolve_time_of_day_hints(phrase: str, window):
    assert resolve_time_of_day(phrase) == window


def test_resolve_time_of_day_returns_none_when_absent():
    assert resolve_time_of_day("just a regular workout") is None


@pytest.mark.parametrize("phrase,offset", [
    ("today",                0),
    ("did yoga today",       0),
    ("yesterday",           -1),
    ("forgot to log my walk yesterday at 3pm", -1),
    ("last night",          -1),
    ("the day before yesterday", -2),
    ("did pilates this morning", 0),
])
def test_resolve_day_offset(phrase: str, offset: int):
    assert resolve_day_offset(phrase) == offset


def test_resolve_day_offset_default_today():
    # Phrases with no hint default to today (0)
    assert resolve_day_offset("did 30 min yoga") == 0
    assert resolve_day_offset("") == 0
