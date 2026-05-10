"""Scenario coverage for the conversational logging pipeline.

These tests assert that:
1. The activity catalog resolves the same canonical_id we use to dispatch
   the per-domain write helper, for every phrasing in the C4 matrix.
2. Time-of-day + day-offset hints map cleanly to occurred_at parameters.
3. Unit conversions feed the right canonical numeric values.
4. Idempotency keying produces stable hashes for ±15min duplicates.

We do NOT exercise the LLM extraction path here (that requires Gemini and
is tested separately via prod sweeps). The contract under test is the
deterministic catalog + idempotency layer those LLM outputs flow into.

Run with: pytest tests/test_log_event_extraction.py -v
"""
import os
import sys
from datetime import datetime, timedelta, timezone

import pytest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from api.v1.wellness.events import _compute_idempotency_key
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
# C4 scenario matrix — each row is (user_phrase, expected canonical_id).
# When the canonical_id is None, the LLM extractor handles it (catalog
# alone can't resolve), and we just assert that the phrase doesn't
# misroute to a wrong activity.
# ---------------------------------------------------------------------------

@pytest.mark.parametrize("phrase,expected_id", [
    # 1-10: explicit phrasings + duration variants
    ("I did 30 min yoga today", "yoga"),
    ("Did 30 mins yoga", "yoga"),
    ("Played basketball for 30 mins", "basketball"),
    ("Ran 5k this morning", "run"),
    ("Walked the dog for an hour", "walk"),
    ("I went for a 10000 step walk", "walk"),
    # 7 ("just did your assigned workout") routes via different intent → not the catalog
    ("Hit the gym today", "strength"),
    ("Quick 20 min HIIT", "hiit"),
    ("I went hiking yesterday for 3 hours", "hike"),
    # 11-15: edge activity types
    ("Rest day today", "rest"),
    ("Crushed legs at the gym, like 45 min", "strength"),
    ("Stairmaster 20 min level 8", "stairmaster"),
    ("Burned 400 cal on elliptical", "elliptical"),
    # 16-20 (food/water/sleep/weight/mood — handled by domain dispatcher,
    # so just assert the workout catalog doesn't false-match)
    ("Drank 32 oz water", None),
    ("Drank a gallon today", None),
    ("Ate a chicken burrito for lunch", None),
    ("Slept 8 hours last night", None),
    ("I weigh 175 today", None),
    ("Feeling great today", None),
    # 22-30: more phrasings
    ("Did pilates", "pilates"),
    ("30 min stretching", "stretching"),
    ("I did the 7-minute workout", "hiit"),
    ("Just got back from a 1 hour swim practice", "swim"),
])
def test_scenario_catalog_resolution(phrase: str, expected_id):
    matched = resolve_activity(phrase)
    if expected_id is None:
        # Either the catalog returns None OR a non-misleading match.
        # Verify there's no false-positive for non-workout phrasings.
        if matched is not None:
            # The food-only phrases ("Drank 32 oz water") MUST NOT resolve
            # to a workout activity — that would route to the wrong domain.
            assert matched.canonical_id in (None,), (
                f"{phrase!r} false-matched to workout activity "
                f"{matched.canonical_id!r}"
            )
    else:
        assert matched is not None, f"Catalog failed to resolve {phrase!r}"
        assert matched.canonical_id == expected_id, (
            f"{phrase!r} → {matched.canonical_id} (expected {expected_id})"
        )


# ---------------------------------------------------------------------------
# Time-of-day + day-offset hints
# ---------------------------------------------------------------------------

@pytest.mark.parametrize("hint,expected_offset", [
    ("today", 0),
    ("yesterday", -1),
    ("yesterday at 3pm", -1),
    ("last night", -1),
    ("the day before yesterday", -2),
    ("this morning", 0),
    ("this evening", 0),
    ("tonight", 0),
])
def test_day_offset_resolves(hint: str, expected_offset: int):
    assert resolve_day_offset(hint) == expected_offset


@pytest.mark.parametrize("hint,expected_window", [
    ("this morning", (5, 11)),
    ("morning", (5, 11)),
    ("noon", (11, 13)),
    ("afternoon", (12, 17)),
    ("this evening", (17, 21)),
    ("tonight", (19, 23)),
    ("last night", (19, 23)),
])
def test_time_of_day_window(hint: str, expected_window):
    assert resolve_time_of_day(hint) == expected_window


# ---------------------------------------------------------------------------
# Unit conversions (the agent passes these through normalize → canonical)
# ---------------------------------------------------------------------------

def test_steps_to_walking_minutes_10000():
    # ~110 steps/min → 91 min for 10k steps
    assert steps_to_walking_minutes(10000) == 91


def test_oz_to_ml_32oz_to_about_946():
    unit = resolve_unit("oz")
    assert unit is not None
    ml = unit.to_canonical(32)
    assert 945 <= ml <= 947  # 32 × 29.5735


def test_gallon_to_ml():
    unit = resolve_unit("gallon")
    assert unit is not None
    ml = unit.to_canonical(1)
    assert 3784 <= ml <= 3786


def test_lbs_to_kg_175lbs():
    unit = resolve_unit("lbs")
    assert unit is not None
    kg = unit.to_canonical(175)
    assert 79.3 <= kg <= 79.5  # 175 × 0.453592


def test_hours_to_minutes_8h():
    unit = resolve_unit("hours")
    assert unit is not None
    assert unit.to_canonical(8) == 480


# ---------------------------------------------------------------------------
# Calorie estimation (MET formula)
# ---------------------------------------------------------------------------

def test_yoga_30min_70kg_about_88_kcal():
    # 2.5 MET × 70 kg × 0.5 hr = 87.5 → rounds to 88
    assert estimate_calories(2.5, 70.0, 30) == 88


def test_basketball_30min_80kg_about_260_kcal():
    # 6.5 MET × 80 kg × 0.5 hr = 260
    assert estimate_calories(6.5, 80.0, 30) == 260


def test_walk_91min_70kg_about_372_kcal():
    # 3.5 MET × 70 kg × (91/60) = 371.6 → 372
    assert estimate_calories(3.5, 70.0, 91) == 372


# ---------------------------------------------------------------------------
# Idempotency: same payload in same 15-min bucket → same key
# ---------------------------------------------------------------------------

def test_idempotency_same_payload_same_bucket():
    user_id = "abc123"
    payload = {"activity_type": "yoga", "duration_minutes": 30}
    t = datetime(2026, 5, 10, 14, 7, tzinfo=timezone.utc).isoformat()  # bucket = 14:00
    t2 = datetime(2026, 5, 10, 14, 13, tzinfo=timezone.utc).isoformat()  # same bucket
    k1 = _compute_idempotency_key(user_id, "workout", payload, t)
    k2 = _compute_idempotency_key(user_id, "workout", payload, t2)
    assert k1 == k2, "Same 15-min bucket should produce same idempotency key"


def test_idempotency_different_buckets():
    user_id = "abc123"
    payload = {"activity_type": "yoga", "duration_minutes": 30}
    t1 = datetime(2026, 5, 10, 14, 7, tzinfo=timezone.utc).isoformat()
    t2 = datetime(2026, 5, 10, 14, 30, tzinfo=timezone.utc).isoformat()  # next bucket
    k1 = _compute_idempotency_key(user_id, "workout", payload, t1)
    k2 = _compute_idempotency_key(user_id, "workout", payload, t2)
    assert k1 != k2, "Different 15-min buckets must produce different keys"


def test_idempotency_payload_canonicalization():
    """Payloads that differ only in key ordering must produce the same key."""
    user_id = "abc123"
    p_a = {"activity_type": "yoga", "duration_minutes": 30, "intensity": "easy"}
    p_b = {"intensity": "easy", "duration_minutes": 30, "activity_type": "yoga"}
    t = datetime(2026, 5, 10, 14, 7, tzinfo=timezone.utc).isoformat()
    assert (
        _compute_idempotency_key(user_id, "workout", p_a, t)
        == _compute_idempotency_key(user_id, "workout", p_b, t)
    )


def test_idempotency_different_users():
    payload = {"activity_type": "yoga", "duration_minutes": 30}
    t = datetime(2026, 5, 10, 14, 7, tzinfo=timezone.utc).isoformat()
    assert (
        _compute_idempotency_key("user_a", "workout", payload, t)
        != _compute_idempotency_key("user_b", "workout", payload, t)
    )


# ---------------------------------------------------------------------------
# Activity-specific defaults (intensity, MET, follow-up fields)
# ---------------------------------------------------------------------------

def test_yoga_default_intensity_easy():
    a = get_activity("yoga")
    assert a.default_intensity == "easy"


def test_strength_needs_followup_body_part():
    a = get_activity("strength")
    assert "body_part" in a.needs_followup


def test_hiit_default_intensity_hard():
    a = get_activity("hiit")
    assert a.default_intensity == "hard"


def test_rest_logs_as_rest_day_with_zero_calories():
    a = get_activity("rest")
    assert a.met == 0.0
    assert a.logs_as == "rest_day"
