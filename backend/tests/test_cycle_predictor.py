"""
Unit tests for the deterministic cycle prediction engine.

Pure-function tests — no DB, no network. Runnable two ways:
    cd backend && .venv/bin/python -m pytest tests/test_cycle_predictor.py -q
    cd backend && .venv/bin/python tests/test_cycle_predictor.py
"""
import os
import sys
from datetime import date, timedelta

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from services.cycle.cycle_predictor import predict  # noqa: E402

TODAY = date(2026, 5, 22)


def _regular_starts(count: int, cycle_len: int, last_offset: int):
    """`count` period starts `cycle_len` days apart; last one TODAY-last_offset."""
    last = TODAY - timedelta(days=last_offset)
    return [last - timedelta(days=cycle_len * k) for k in range(count - 1, -1, -1)]


def test_no_periods():
    r = predict(today=TODAY, period_starts=[])
    assert r["predictions_available"] is False
    assert r["stats"]["periods_logged"] == 0
    assert any("first period" in n for n in r["notes"])


def test_single_period_low_confidence():
    r = predict(today=TODAY, period_starts=[TODAY - timedelta(days=10)])
    assert r["predictions_available"] is True
    assert r["confidence"] == "low"
    assert r["stats"]["cycles_tracked"] == 0
    # default 28-day cycle from a single anchor
    assert r["next_period_date"] == TODAY - timedelta(days=10) + timedelta(days=28)


def test_six_regular_cycles():
    # 7 starts 28 days apart -> 6 cycle gaps; last period started 3 days ago.
    starts = _regular_starts(7, 28, last_offset=3)
    r = predict(today=TODAY, period_starts=starts)
    assert r["predictions_available"] is True
    assert r["confidence"] == "high"
    assert r["stats"]["regularity"] == "regular"
    assert r["stats"]["avg_cycle_length"] == 28.0
    last = TODAY - timedelta(days=3)
    assert r["next_period_date"] == last + timedelta(days=28)
    # ovulation = next period - 14
    assert r["ovulation_date"] == last + timedelta(days=28 - 14)
    # fertile window = ovulation -5 .. +1
    assert r["fertile_window_start"] == r["ovulation_date"] - timedelta(days=5)
    assert r["fertile_window_end"] == r["ovulation_date"] + timedelta(days=1)
    assert r["current_cycle_day"] == 4
    assert r["current_phase"] == "menstrual"


def test_irregular_cycles_widen_window():
    # gaps: 25,35,28,40,26,33 -> high stddev -> irregular
    lengths = [25, 35, 28, 40, 26, 33]
    starts = [TODAY - timedelta(days=3)]
    for ln in reversed(lengths):
        starts.insert(0, starts[0] - timedelta(days=ln))
    r = predict(today=TODAY, period_starts=starts)
    assert r["stats"]["regularity"] == "irregular"
    # irregular fertile window is the union with the calendar method -> wider
    width = (r["fertile_window_end"] - r["fertile_window_start"]).days
    assert width > 6, f"expected widened fertile window, got {width} days"


def test_late_period():
    # regular 28-day cycles but the last one started 40 days ago
    starts = _regular_starts(7, 28, last_offset=40)
    r = predict(today=TODAY, period_starts=starts)
    assert r["period_late_by"] == 12, r["period_late_by"]
    assert any("late" in n for n in r["notes"])


def test_bbt_confirms_ovulation():
    last = TODAY - timedelta(days=20)
    starts = [last - timedelta(days=28 * k) for k in range(6, -1, -1)]
    # 6 low readings then 3 elevated -> Marshall three-over-six shift
    bbt = []
    for i in range(6):
        bbt.append((last + timedelta(days=5 + i), 36.40))
    bbt.append((last + timedelta(days=11), 36.55))
    bbt.append((last + timedelta(days=12), 36.65))  # >= baseline + 0.22
    bbt.append((last + timedelta(days=13), 36.58))
    r = predict(today=TODAY, period_starts=starts, bbt_points=bbt)
    assert r["ovulation_status"] == "confirmed"
    # ovulation = day before the first elevated reading
    assert r["ovulation_date"] == last + timedelta(days=10)
    assert r["cover_line_celsius"] is not None


def test_symptom_only_profile():
    starts = _regular_starts(7, 28, last_offset=3)
    r = predict(today=TODAY, period_starts=starts, has_menstrual_periods=False)
    assert r["predictions_available"] is False


def test_pregnancy_mode_pauses():
    starts = _regular_starts(7, 28, last_offset=3)
    r = predict(today=TODAY, period_starts=starts, tracking_mode="pregnancy")
    assert r["predictions_available"] is False
    assert any("pregnancy" in n.lower() for n in r["notes"])


def test_conception_chance_in_fertile_window():
    # last period 11 days ago, default 28-day cycle from a single period:
    # ovulation ~ today (28 - 14 = day 14, last+14 ... let's verify high near it)
    starts = _regular_starts(7, 28, last_offset=14)
    r = predict(today=TODAY, period_starts=starts)
    last = TODAY - timedelta(days=14)
    ovu = last + timedelta(days=14)
    in_window = ovu - timedelta(days=5) <= TODAY <= ovu + timedelta(days=1)
    assert r["conception_chance"] == ("high" if in_window else "low")


def _run_all():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    passed = 0
    for t in tests:
        try:
            t()
            print(f"✅ {t.__name__}")
            passed += 1
        except AssertionError as e:
            print(f"❌ {t.__name__}: {e}")
        except Exception as e:  # noqa: BLE001
            print(f"💥 {t.__name__}: {type(e).__name__}: {e}")
    print(f"\n{passed}/{len(tests)} passed")
    return passed == len(tests)


if __name__ == "__main__":
    sys.exit(0 if _run_all() else 1)
