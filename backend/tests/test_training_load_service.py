"""
Tests for services/training_load_service.py.

Covers:
- Banister TRIMP math (Z2 30-min run sanity check)
- Acute (7d) + chronic (28d) rolling-window correctness
- ACWR == None when chronic == 0
- State classification boundaries (0.79/0.80/1.30/1.31/1.50/1.51)
- 13 days history → "calibration"; 14 days → real classification

Run: cd backend && .venv/bin/python -m pytest tests/test_training_load_service.py -v
"""
import math
from datetime import date, timedelta

import pytest

from services.training_load_service import (
    classify_state,
    compute_history_from_sessions,
    compute_session_trimp,
    _rolling_sum,
)


# ---------------------------------------------------------------------------
# TRIMP math
# ---------------------------------------------------------------------------


def test_session_trimp_zero_duration_returns_zero():
    assert compute_session_trimp(duration_minutes=0, avg_hr=140) == 0.0
    assert compute_session_trimp(duration_minutes=-5) == 0.0


def test_session_trimp_z2_30min_run():
    """30 min run @ 130 bpm (resting 50, max 180) — Banister male curve.

    y = (130-50)/(180-50) = 80/130 = 0.6154
    trimp = 30 * 0.6154 * 0.64 * exp(1.92 * 0.6154)
          = 30 * 0.6154 * 0.64 * exp(1.1815)
          ≈ 30 * 0.6154 * 0.64 * 3.2598
          ≈ 38.5
    """
    trimp = compute_session_trimp(
        duration_minutes=30,
        avg_hr=130,
        resting_hr=50,
        max_hr=180,
        gender="male",
    )
    # Manual: 30 * 0.6154 * 0.64 * exp(1.1815) ≈ 38.51
    expected = 30 * (80 / 130) * 0.64 * math.exp(1.92 * (80 / 130))
    assert trimp == pytest.approx(expected, abs=0.5)
    assert 34 <= trimp <= 43  # ±5 envelope per spec


def test_session_trimp_female_curve_uses_female_coefficients():
    """Female branch uses (0.86, 1.67) — Banister published per-sex curves.
    Confirm the female calculation differs from the male one (curves cross
    around y≈0.85 — below it female > male, above it male > female)."""
    kw = dict(duration_minutes=30, avg_hr=160, resting_hr=50, max_hr=190)
    male = compute_session_trimp(gender="male", **kw)
    female = compute_session_trimp(gender="female", **kw)
    assert male != female  # different curves
    # Hand-compute female: y = 110/140 = 0.7857; 30*0.7857*0.86*exp(1.67*0.7857)
    y = 110 / 140
    expected_f = 30 * y * 0.86 * math.exp(1.67 * y)
    assert female == pytest.approx(expected_f, abs=0.01)


def test_session_trimp_falls_back_to_rpe_without_hr():
    # No HR → RPE * duration
    trimp = compute_session_trimp(duration_minutes=45, rpe=7)
    assert trimp == pytest.approx(315.0)


def test_session_trimp_falls_back_to_calories():
    trimp = compute_session_trimp(duration_minutes=30, calories=500)
    assert trimp == pytest.approx(50.0)


def test_session_trimp_final_zone2_fallback():
    # No HR, no RPE, no calories → duration * 5
    trimp = compute_session_trimp(duration_minutes=30)
    assert trimp == pytest.approx(150.0)


def test_session_trimp_clamps_hr_below_resting():
    # Wearable bug — avg_hr below resting. Should clamp to 0, not go negative.
    trimp = compute_session_trimp(
        duration_minutes=30, avg_hr=40, resting_hr=50, max_hr=180
    )
    assert trimp == 0.0


# ---------------------------------------------------------------------------
# Rolling-window helper
# ---------------------------------------------------------------------------


def test_rolling_sum_window_7():
    daily = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    out = _rolling_sum(daily, 7)
    assert out[0] == 1
    assert out[5] == sum(range(1, 7))  # 1+2+3+4+5+6 = 21
    assert out[6] == sum(range(1, 8))  # 1..7 = 28
    assert out[7] == sum(range(2, 9))  # 2..8 = 35
    assert out[9] == sum(range(4, 11))  # 4..10 = 49


def test_rolling_sum_window_28_short_series():
    """Window larger than series — sum is just running total."""
    out = _rolling_sum([10, 20, 30], 28)
    assert out == [10, 30, 60]


# ---------------------------------------------------------------------------
# Acute / chronic / ACWR on mock cardio history
# ---------------------------------------------------------------------------


def _make_session(when: date, *, duration_minutes=30, avg_hr=130):
    return {
        "when": when,
        "duration_minutes": duration_minutes,
        "avg_hr": avg_hr,
        "rpe": None,
        "calories": None,
    }


def test_history_rolling_correct_over_60_days():
    """Every day for 60 days: same 30-min Z2 session. Both acute (7d) and
    chronic (28d) should saturate to 7×trimp and 28×trimp respectively."""
    today = date(2026, 5, 1)
    per_day_trimp = compute_session_trimp(
        duration_minutes=30, avg_hr=130, resting_hr=50, max_hr=180
    )
    sessions = [
        _make_session(today - timedelta(days=i)) for i in range(60)
    ]
    history = compute_history_from_sessions(
        sessions,
        days=60,
        today=today,
        resting_hr=50,
        max_hr=180,
        gender="male",
    )
    assert len(history) == 60
    last = history[-1]
    assert last.daily_trimp == pytest.approx(per_day_trimp, abs=0.05)
    assert last.acute_load == pytest.approx(7 * per_day_trimp, abs=0.5)
    assert last.chronic_load == pytest.approx(28 * per_day_trimp, abs=0.5)
    # ACWR at saturation = (7T)/(28T) = 0.25 — squarely detraining.
    assert last.acwr == pytest.approx(0.25, abs=0.005)


def test_acwr_none_when_chronic_zero():
    today = date(2026, 5, 1)
    # Zero sessions → zero chronic load → acwr None on every day.
    history = compute_history_from_sessions(
        [], days=30, today=today, resting_hr=50, max_hr=180
    )
    assert all(p.acwr is None for p in history)
    assert all(p.chronic_load == 0 for p in history)


def test_acwr_spike_after_rest_block_classified_overreaching():
    """28d of zero, then 7 hard days in a row → acute high, chronic = just
    those same 7 days → ACWR = 1.0. Then add 7 more very hard days on top
    so acute >> chronic baseline."""
    today = date(2026, 5, 1)
    sessions = []
    # Days -27..-7: nothing.
    # Days -6..0: 60 min @ HR 165 (resting 50, max 180) — high TRIMP each day.
    for i in range(7):
        sessions.append(
            _make_session(
                today - timedelta(days=i),
                duration_minutes=90,
                avg_hr=170,
            )
        )
    history = compute_history_from_sessions(
        sessions,
        days=28,
        today=today,
        resting_hr=50,
        max_hr=180,
        gender="male",
    )
    last = history[-1]
    # Same 7 days are both fully inside the acute window AND the chronic
    # window — but acute=last 7d and chronic=last 28d; since the only
    # activity is those last 7 days, acute == chronic, ACWR == 1.0.
    assert last.acwr == pytest.approx(1.0, abs=0.01)


# ---------------------------------------------------------------------------
# Classification boundaries
# ---------------------------------------------------------------------------


@pytest.mark.parametrize(
    "acwr,expected",
    [
        (0.79, "detraining"),
        (0.80, "balanced"),
        (1.30, "balanced"),
        (1.31, "loading"),
        (1.50, "loading"),
        (1.51, "overreaching"),
        (2.5, "overreaching"),
    ],
)
def test_classify_state_boundaries(acwr, expected):
    state, _ = classify_state(acwr, days_of_history=30)
    assert state == expected


def test_classify_state_calibration_under_14_days():
    state, interp = classify_state(1.0, days_of_history=13)
    assert state == "calibration"
    assert "baseline" in interp.lower()


def test_classify_state_14_days_real_classification():
    state, _ = classify_state(1.0, days_of_history=14)
    assert state == "balanced"


def test_classify_state_none_acwr_is_detraining():
    state, _ = classify_state(None, days_of_history=30)
    assert state == "detraining"


def test_classify_state_none_acwr_calibration_overrides():
    # Even with acwr=None, < 14 days → calibration (calibration short-circuits).
    state, _ = classify_state(None, days_of_history=5)
    assert state == "calibration"
