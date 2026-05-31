"""Unit tests for the coach-copy number-grounding guardrail.

These prove the core no-fabrication guarantee behind the data-grounded coach
notifications: every number a model writes must trace back to data we provided,
or the output is rejected (and the cron falls back to deterministic copy).

Pure functions, no Gemini / DB / app needed — run with:
    cd backend && python3 -m pytest tests/test_coach_grounding.py -q
or as a plain script:
    cd backend && python3 tests/test_coach_grounding.py
"""
import os
import sys

# Put the backend root FIRST on the path so `services` resolves to
# backend/services and not the sibling `tests/services` package (which would
# shadow it when this file is run directly as a script).
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from services.coach.grounding import number_set, numbers_grounded, parse_json_object  # noqa: E402


_SNAPSHOT = {
    "first_name": "Chetan",
    "sleep": {"total_minutes": 360, "deep_minutes": 95, "rem_minutes": 80},
    "heart_rate": {"resting": 74, "resting_baseline": 72.0, "resting_vs_baseline": 2.0},
    "steps": {"today": 3200, "goal": 8000, "goal_pct": 40},
    "recent_training": [{"name": "Push Day", "days_ago": 2}],
}


def test_grounded_numbers_pass():
    grounded = number_set(_SNAPSHOT)
    # Every number here is present in the snapshot.
    body = (
        "Chetan, you logged 95 minutes of deep sleep and your resting heart "
        "rate is 74 bpm. You are at 3200 steps today toward 8000."
    )
    assert numbers_grounded(body, grounded) is True


def test_fabricated_number_rejected():
    grounded = number_set(_SNAPSHOT)
    # 88 bpm is NOT in the snapshot (resting is 74) -> must be rejected.
    body = "Your resting heart rate is 88 bpm, time to rest."
    assert numbers_grounded(body, grounded) is False


def test_small_counters_always_allowed():
    grounded = number_set(_SNAPSHOT)
    # 1 and 2 are sentence counters, always allowed even if not in data.
    assert numbers_grounded("Take 1 walk and 2 short breaks.", grounded) is True


def test_float_one_decimal_grounded():
    grounded = number_set({"resting_vs_baseline": 2.0, "hours": 6.5})
    assert numbers_grounded("You slept 6.5 hours.", grounded) is True


def test_comma_thousands_normalized():
    grounded = number_set({"steps": 4200})
    assert numbers_grounded("You hit 4,200 steps.", grounded) is True


def test_empty_text_is_grounded():
    assert numbers_grounded("", number_set(_SNAPSHOT)) is True


def test_parse_json_with_fence():
    assert parse_json_object('```json\n{"title": "x", "body": "y"}\n```') == {
        "title": "x",
        "body": "y",
    }


def test_parse_json_plain():
    assert parse_json_object('{"a": 1}') == {"a": 1}


def test_parse_json_garbage_returns_none():
    assert parse_json_object("not json at all") is None


def test_parse_json_embedded_object():
    assert parse_json_object('prefix {"a": 1} suffix') == {"a": 1}


if __name__ == "__main__":
    import sys

    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    failed = 0
    for t in tests:
        try:
            t()
            print(f"  ✅ {t.__name__}")
        except AssertionError as e:
            failed += 1
            print(f"  ❌ {t.__name__}: {e}")
    print(f"\n{len(tests) - failed}/{len(tests)} passed")
    sys.exit(1 if failed else 0)
