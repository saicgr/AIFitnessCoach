"""
Tests for race_predictor_service.

Covers:
  - Riegel math correctness (5K 24:00 → 10K ≈ 50:00)
  - Cameron formula used for marathon prediction when base is shorter
  - <3 runs ever → all-None
  - Confidence decays with base age
  - Base shorter than predicted → confidence ≤ 0.7
  - Very short base (<800m) ignored
"""
from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List
from unittest.mock import MagicMock

import pytest

from services.race_predictor_service import (
    FIVE_K_M,
    MARATHON_M,
    HALF_M,
    TEN_K_M,
    cameron_predict,
    predict_for_user,
    riegel_predict,
)


# ---------------------------------------------------------------------------
# Pure-math tests
# ---------------------------------------------------------------------------

def test_riegel_5k_to_10k():
    """5K in 24:00 → predicted 10K within 30s of ~50:00 via Riegel."""
    t1 = 24 * 60  # 1440
    predicted = riegel_predict(t1, FIVE_K_M, TEN_K_M)
    # Riegel: 1440 * 2^1.06 = 1440 * 2.0851 ≈ 3002s ≈ 50:02
    assert 3000 - 30 <= predicted <= 3000 + 30, (
        f"expected ~3000s (50:00), got {predicted:.0f}"
    )


def test_riegel_inverse_consistency():
    """Predict 10K from 5K, then 5K from that 10K — should round-trip."""
    t1 = 24 * 60
    t_10k = riegel_predict(t1, FIVE_K_M, TEN_K_M)
    t_5k_back = riegel_predict(t_10k, TEN_K_M, FIVE_K_M)
    assert abs(t_5k_back - t1) < 0.5


def test_cameron_slower_than_riegel_at_marathon():
    """Cameron should predict a SLOWER marathon than Riegel from a 10K base —
    that's the whole reason we use it (Riegel over-predicts at long range)."""
    t_10k = 50 * 60  # 50:00 — a recreational 10K
    riegel_marathon = riegel_predict(t_10k, TEN_K_M, MARATHON_M)
    cameron_marathon = cameron_predict(t_10k, TEN_K_M, MARATHON_M)
    # Cameron is harsher (slower predicted time) for the marathon extrapolation.
    assert cameron_marathon > riegel_marathon, (
        f"Cameron {cameron_marathon:.0f} should be > Riegel {riegel_marathon:.0f}"
    )


def test_cameron_reasonable_marathon_from_strong_10k():
    """A 40:00 10K should predict ~3:05-3:20 marathon via Cameron (well-known
    benchmark from Runner's World pace charts)."""
    t_10k = 40 * 60  # 2400s
    cameron_marathon = cameron_predict(t_10k, TEN_K_M, MARATHON_M)
    # 3:00 (10800) to 3:30 (12600) is the realistic band for a 40-min 10K runner.
    assert 10_800 <= cameron_marathon <= 12_600, (
        f"unrealistic marathon prediction: {cameron_marathon:.0f}s"
    )


# ---------------------------------------------------------------------------
# End-to-end predict_for_user
# ---------------------------------------------------------------------------

def _mock_db(rows: List[Dict[str, Any]]):
    db = MagicMock()
    chain = (
        db.client.table.return_value
        .select.return_value
        .eq.return_value
        .in_.return_value
    )
    chain.execute.return_value = MagicMock(data=rows)
    return db


def _row(*, distance_m: float, duration_seconds: int, days_ago: int = 1, id_: str = "r1") -> Dict[str, Any]:
    performed_at = (datetime.now(timezone.utc) - timedelta(days=days_ago)).isoformat()
    return {
        "id": id_,
        "activity_type": "run",
        "distance_m": distance_m,
        "duration_seconds": duration_seconds,
        "performed_at": performed_at,
    }


def test_fewer_than_3_runs_returns_all_none():
    db = _mock_db([
        _row(distance_m=5000, duration_seconds=1440, id_="a"),
        _row(distance_m=10000, duration_seconds=3000, id_="b"),
    ])
    result = predict_for_user(db, "user-x")
    assert all(v is None for v in result.values())
    assert set(result.keys()) == {"five_k", "ten_k", "half_marathon", "marathon"}


def test_three_runs_produces_all_predictions():
    db = _mock_db([
        _row(distance_m=5000, duration_seconds=1440, id_="a"),
        _row(distance_m=3000, duration_seconds=900, id_="b"),
        _row(distance_m=8000, duration_seconds=2500, id_="c"),
    ])
    result = predict_for_user(db, "user-x")
    for key in ("five_k", "ten_k", "half_marathon", "marathon"):
        assert result[key] is not None, f"{key} should have a prediction"
        assert result[key].predicted_seconds > 0
        assert result[key].distance_m > 0


def test_marathon_uses_cameron_when_base_is_shorter():
    """If best base is a 10K, marathon prediction should use Cameron formula."""
    db = _mock_db([
        _row(distance_m=10000, duration_seconds=2400, id_="a"),  # 40:00 10K
        _row(distance_m=5000, duration_seconds=1300, id_="b"),
        _row(distance_m=8000, duration_seconds=2100, id_="c"),
    ])
    result = predict_for_user(db, "user-x")
    assert result["marathon"].formula == "cameron"
    assert result["half_marathon"].formula == "cameron"
    # 10K target = base distance, so Riegel still applies there.
    assert result["ten_k"].formula == "riegel"
    assert result["five_k"].formula == "riegel"


def test_confidence_decays_with_age():
    """Same base run, older performed_at → lower confidence."""
    fresh = _mock_db([
        _row(distance_m=5000, duration_seconds=1440, id_="a", days_ago=5),
        _row(distance_m=3000, duration_seconds=900, id_="b", days_ago=6),
        _row(distance_m=8000, duration_seconds=2500, id_="c", days_ago=10),
    ])
    aged = _mock_db([
        _row(distance_m=5000, duration_seconds=1440, id_="a", days_ago=120),
        _row(distance_m=3000, duration_seconds=900, id_="b", days_ago=121),
        _row(distance_m=8000, duration_seconds=2500, id_="c", days_ago=125),
    ])
    fresh_conf = predict_for_user(fresh, "u").get("five_k").confidence
    aged_conf = predict_for_user(aged, "u").get("five_k").confidence
    assert aged_conf < fresh_conf


def test_base_shorter_than_predicted_has_lower_confidence():
    """Best base is a 5K. Marathon prediction is extrapolation → conf ≤ 0.7."""
    db = _mock_db([
        _row(distance_m=5000, duration_seconds=1200, id_="a", days_ago=2),  # 20:00 5K — clearly fastest
        _row(distance_m=3000, duration_seconds=900, id_="b", days_ago=3),
        _row(distance_m=4500, duration_seconds=1280, id_="c", days_ago=4),
    ])
    result = predict_for_user(db, "user-x")
    # Best base by 5K-equivalent is the 5K itself (1440s) — it's the fastest.
    # Marathon + half are extrapolations, conf base = 0.7 minus tiny age decay.
    assert result["marathon"].confidence <= 0.7
    assert result["half_marathon"].confidence <= 0.7
    # 5K target == base distance → interpolation, conf should be > 0.7.
    assert result["five_k"].confidence > 0.7


def test_very_short_base_returns_all_none():
    """All runs < 800m — no qualifying base → all-None even with 3+ runs."""
    db = _mock_db([
        _row(distance_m=400, duration_seconds=90, id_="a"),
        _row(distance_m=600, duration_seconds=150, id_="b"),
        _row(distance_m=500, duration_seconds=120, id_="c"),
    ])
    result = predict_for_user(db, "user-x")
    assert all(v is None for v in result.values())


def test_picks_fastest_equivalent_5k_not_longest_run():
    """A sharp 5K at 20:00 should beat a casual 20K at 2:00:00 as the base."""
    db = _mock_db([
        _row(distance_m=5000, duration_seconds=1200, id_="sharp_5k"),  # 20:00 — implied 5K = 20:00
        _row(distance_m=20000, duration_seconds=7200, id_="casual_20k"),  # 2:00:00 — implied 5K much slower
        _row(distance_m=3000, duration_seconds=900, id_="filler"),
    ])
    result = predict_for_user(db, "user-x")
    assert result["five_k"].base_run["cardio_log_id"] == "sharp_5k"
