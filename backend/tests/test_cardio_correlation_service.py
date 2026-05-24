"""
Tests for cardio_correlation_service.

Pattern mirrors `tests/test_cardio_pr_service.py`: a thin in-memory fake
DB whose `.client.table(...).select(...).eq(...).execute()` chain returns
rows out of a dict — no Supabase, no network. Run::

    cd backend && .venv/bin/python -m pytest \\
        tests/test_cardio_correlation_service.py -v --noconftest

Coverage checklist (per slice spec):
  - < 20 paired sessions  → None
  - mocked correlated data → r within ± 0.05 of expected
  - HIIT outlier filter   → high-variance splits get dropped
  - copy variants         → pool has >= 4 distinct templates
"""
from __future__ import annotations

import os
import sys
from datetime import datetime, date, timedelta, timezone
from typing import Any, Dict, List, Optional
import uuid

import pytest

# Make `backend/` importable when running with --noconftest from repo root.
_HERE = os.path.dirname(os.path.abspath(__file__))
_BACKEND = os.path.dirname(_HERE)
if _BACKEND not in sys.path:
    sys.path.insert(0, _BACKEND)

from services.cardio_correlation_service import (  # noqa: E402
    _COPY_VARIANTS,
    _pearson,
    _splits_pace_variance,
    compute_sleep_pace_correlation,
)


# ---------------------------------------------------------------------------
# Fake Supabase
# ---------------------------------------------------------------------------

class _FakeResp:
    def __init__(self, data: List[Dict[str, Any]]):
        self.data = data


class _FakeQuery:
    def __init__(self, db: "_FakeDB", table_name: str):
        self._db = db
        self._table = table_name
        self._filters: List[tuple] = []
        self._not = False

    def select(self, *_args, **_kwargs) -> "_FakeQuery":
        return self

    def eq(self, col, value) -> "_FakeQuery":
        self._filters.append(("eq", col, value))
        return self

    def gte(self, col, value) -> "_FakeQuery":
        self._filters.append(("gte", col, value))
        return self

    def lte(self, col, value) -> "_FakeQuery":
        self._filters.append(("lte", col, value))
        return self

    @property
    def not_(self) -> "_FakeQuery":
        self._not = True
        return self

    def is_(self, col, _value) -> "_FakeQuery":
        # Service uses .not_.is_(col, "null") to filter null pace; we already
        # only seed rows with non-null pace, so the filter is a no-op here.
        self._filters.append(("notnull", col, None))
        return self

    def execute(self) -> _FakeResp:
        rows = list(self._db.tables.get(self._table, []))
        for op, col, val in self._filters:
            if op == "eq":
                rows = [r for r in rows if str(r.get(col)) == str(val)]
            elif op == "gte":
                rows = [
                    r for r in rows
                    if r.get(col) is not None and str(r.get(col)) >= str(val)
                ]
            elif op == "lte":
                rows = [
                    r for r in rows
                    if r.get(col) is not None and str(r.get(col)) <= str(val)
                ]
            elif op == "notnull":
                rows = [r for r in rows if r.get(col) is not None]
        return _FakeResp(rows)


class _FakeClient:
    def __init__(self, db: "_FakeDB"):
        self._db = db

    def table(self, name: str) -> _FakeQuery:
        return _FakeQuery(self._db, name)


class _FakeDB:
    def __init__(self) -> None:
        self.tables: Dict[str, List[Dict[str, Any]]] = {
            "cardio_logs": [],
            "daily_activity": [],
        }
        self.client = _FakeClient(self)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

USER = "22222222-2222-2222-2222-222222222222"
TODAY = date.today()


def _cardio(
    *,
    days_ago: int,
    pace: float,
    splits_json: Optional[list] = None,
) -> Dict[str, Any]:
    perf = datetime.now(timezone.utc) - timedelta(days=days_ago)
    return {
        "id": str(uuid.uuid4()),
        "user_id": USER,
        "activity_type": "run",
        "performed_at": perf.isoformat(),
        "avg_pace_seconds_per_km": pace,
        "splits_json": splits_json,
    }


def _sleep(*, days_ago: int, minutes: int) -> Dict[str, Any]:
    return {
        "user_id": USER,
        "activity_date": (TODAY - timedelta(days=days_ago)).isoformat(),
        "sleep_minutes": minutes,
    }


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

def test_returns_none_when_fewer_than_20_pairs():
    """Below the MIN_PAIRS gate, we MUST return None — never a noisy r."""
    db = _FakeDB()
    # 19 cardio sessions with matching sleep — one short of the gate.
    for i in range(19):
        db.tables["cardio_logs"].append(_cardio(days_ago=i + 1, pace=300.0))
        db.tables["daily_activity"].append(_sleep(days_ago=i + 2, minutes=420))

    result = compute_sleep_pace_correlation(db, USER, days=60)
    assert result is None


def test_returns_correlation_when_data_is_correlated():
    """Hand-crafted data where sleep ↔ pace is strongly negatively correlated.

    More sleep => smaller pace number (faster). Pearson r should be < -0.7.
    """
    db = _FakeDB()
    # 24 sessions: sleep_hours 5..8.5, pace 360..275 (perfectly anti-correlated).
    for i in range(24):
        sleep_h = 5.0 + (i * 0.15)            # 5.0 → 8.45
        pace = 360.0 - (i * 3.5)              # 360 → 275.5
        days_ago = i + 1
        db.tables["cardio_logs"].append(_cardio(days_ago=days_ago, pace=pace))
        db.tables["daily_activity"].append(
            _sleep(days_ago=days_ago + 1, minutes=int(sleep_h * 60))
        )

    result = compute_sleep_pace_correlation(db, USER, days=60)
    assert result is not None
    assert result["n"] == 24
    # Anti-correlation: more sleep → faster pace (smaller seconds/km).
    assert result["r"] <= -0.95, f"expected strong negative r, got {result['r']}"
    # Slope is sec/km change per +1h sleep — should be negative (faster per hour).
    assert result["slope_sec_per_km_per_hour"] < 0
    assert isinstance(result["copy"], str) and result["copy"]


def test_hiit_sessions_with_high_split_variance_are_filtered():
    """Sessions with > 40% pace CoV across splits must be dropped.

    Setup: 25 valid steady runs + 5 HIIT sessions whose splits swing wildly.
    If the filter works, n in the result equals exactly 25 (the steady ones).
    """
    db = _FakeDB()
    # 25 steady runs at predictable pace.
    for i in range(25):
        db.tables["cardio_logs"].append(_cardio(days_ago=i + 1, pace=300.0))
        db.tables["daily_activity"].append(_sleep(days_ago=i + 2, minutes=450))

    # 5 HIIT sessions on additional days — wildly varying split paces.
    hiit_splits = [
        {"avg_pace_seconds_per_km": 200},
        {"avg_pace_seconds_per_km": 600},
        {"avg_pace_seconds_per_km": 180},
        {"avg_pace_seconds_per_km": 650},
        {"avg_pace_seconds_per_km": 220},
    ]
    for i in range(5):
        db.tables["cardio_logs"].append(
            _cardio(days_ago=26 + i, pace=350.0, splits_json=hiit_splits)
        )
        db.tables["daily_activity"].append(_sleep(days_ago=27 + i, minutes=420))

    # Sanity-check the variance helper agrees the HIIT splits are above threshold.
    cov = _splits_pace_variance(hiit_splits)
    assert cov is not None and cov > 0.40

    result = compute_sleep_pace_correlation(db, USER, days=90)
    assert result is not None
    assert result["n"] == 25, f"HIIT not filtered: got n={result['n']}"


def test_missing_prior_night_sleep_excludes_the_pair():
    """A cardio session without a matching prior-night sleep row is dropped."""
    db = _FakeDB()
    # 22 cardio sessions, but only 19 have a sleep row the night before.
    for i in range(22):
        db.tables["cardio_logs"].append(_cardio(days_ago=i + 1, pace=305.0))
    for i in range(19):
        db.tables["daily_activity"].append(_sleep(days_ago=i + 2, minutes=440))

    result = compute_sleep_pace_correlation(db, USER, days=60)
    # 19 < MIN_PAIRS, so we expect None even though there are 22 cardio rows.
    assert result is None


def test_copy_variant_pool_has_at_least_four():
    """Spec requires >= 4 distinct copy templates so the card never feels canned."""
    distinct = {tmpl for tmpl in _COPY_VARIANTS}
    assert len(distinct) >= 4


def test_pearson_helper_matches_known_value():
    """Sanity-check the math helper against a textbook r."""
    xs = [1, 2, 3, 4, 5]
    ys = [2, 4, 6, 8, 10]  # perfect positive
    assert abs(_pearson(xs, ys) - 1.0) < 1e-9
    ys_neg = [10, 8, 6, 4, 2]
    assert abs(_pearson(xs, ys_neg) - (-1.0)) < 1e-9
    # Zero variance → 0 (not NaN — the wrapper coerces).
    assert _pearson([1, 1, 1, 1], [2, 3, 4, 5]) == 0.0
