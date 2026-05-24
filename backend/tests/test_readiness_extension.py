"""
Tests for the cardio-extension half of readiness_service (Migration 2094).

Covers:
- _compute_rhr_delta: <14 days → None; math correct with mock data.
- _compute_weekly_trimp: integrates with training_load_service.
- _classify_cardio_load_state: ACWR + TRIMP threshold buckets.
- compute_readiness: backward-compat (no RHR/TRIMP), writes new fields,
  applies +5% RHR penalty.

These tests use small in-memory fakes for the Supabase client — they do
NOT require a live DB, and they do NOT touch the existing
test_readiness_service tests (which keep covering the Hooper half).
"""
from __future__ import annotations

from datetime import date, datetime, timedelta, timezone
from types import SimpleNamespace
from typing import Any, Dict, List, Optional

import pytest

from services.readiness_service import (
    ReadinessCheckIn,
    _classify_cardio_load_state,
    _compute_rhr_delta,
    _compute_weekly_trimp,
    compute_readiness,
)


# ---------------------------------------------------------------------------
# Fake Supabase client — minimal chain that mirrors the service's query shape.
# ---------------------------------------------------------------------------


class _FakeQuery:
    def __init__(self, rows: List[Dict[str, Any]]):
        self._rows = rows

    def select(self, *_a, **_k):
        return self

    def eq(self, *_a, **_k):
        return self

    def gte(self, *_a, **_k):
        return self

    def order(self, *_a, **_k):
        return self

    def limit(self, *_a, **_k):
        return self

    def execute(self):
        return SimpleNamespace(data=self._rows)


class _FakeTable:
    def __init__(self, name: str, store: Dict[str, List[Dict[str, Any]]]):
        self._name = name
        self._store = store
        self.upserts: List[Dict[str, Any]] = []

    def select(self, *_a, **_k):
        return _FakeQuery(self._store.get(self._name, []))

    def upsert(self, record_data, **_k):
        self.upserts.append(record_data)
        self._store.setdefault(self._name, []).append(record_data)
        return _FakeQuery([record_data])


class _FakeClient:
    def __init__(self, store: Optional[Dict[str, List[Dict[str, Any]]]] = None):
        self._store = store or {}
        self._tables: Dict[str, _FakeTable] = {}

    def table(self, name: str) -> _FakeTable:
        if name not in self._tables:
            self._tables[name] = _FakeTable(name, self._store)
        return self._tables[name]


class _FakeDb:
    def __init__(self, store: Optional[Dict[str, List[Dict[str, Any]]]] = None):
        self.client = _FakeClient(store)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _rhr_rows(start: date, days: int, bpm: int) -> List[Dict[str, Any]]:
    return [
        {"resting_hr": bpm, "measured_at": (start - timedelta(days=i)).isoformat()}
        for i in range(days)
    ]


# ---------------------------------------------------------------------------
# _compute_rhr_delta
# ---------------------------------------------------------------------------


class TestComputeRhrDelta:
    def test_returns_none_when_fewer_than_14_days(self):
        store = {"cardio_metrics": _rhr_rows(date.today(), 10, 60)}
        db = _FakeDb(store)

        assert _compute_rhr_delta(db, "user-1") is None

    def test_returns_none_with_zero_history(self):
        db = _FakeDb({"cardio_metrics": []})
        assert _compute_rhr_delta(db, "user-1") is None

    def test_baseline_and_today_math_flat_baseline(self):
        # 28 days at 60bpm + today at 66bpm = +10% elevation.
        today = date.today()
        rows = _rhr_rows(today - timedelta(days=1), 28, 60)
        rows.insert(0, {"resting_hr": 66, "measured_at": today.isoformat()})
        db = _FakeDb({"cardio_metrics": rows})

        out = _compute_rhr_delta(db, "user-1")
        assert out is not None
        assert out["today_bpm"] == 66
        assert out["baseline_bpm"] == 60.0
        assert out["delta_pct"] == 10.0

    def test_dedupes_multiple_readings_per_day(self):
        today = date.today()
        # Two readings same day → latest wins (desc order in query).
        rows = [
            {"resting_hr": 70, "measured_at": today.isoformat() + "T08:00:00Z"},
            {"resting_hr": 65, "measured_at": today.isoformat() + "T20:00:00Z"},
        ]
        # Plus 14 prior days of 60bpm.
        for i in range(1, 15):
            rows.append(
                {
                    "resting_hr": 60,
                    "measured_at": (today - timedelta(days=i)).isoformat(),
                }
            )
        db = _FakeDb({"cardio_metrics": rows})

        out = _compute_rhr_delta(db, "user-1")
        assert out is not None
        # Today should be ONE value (the first/latest per day), baseline 60.
        assert out["baseline_bpm"] == 60.0
        assert out["today_bpm"] in (65, 70)

    def test_negative_delta_when_today_is_lower(self):
        today = date.today()
        rows = _rhr_rows(today - timedelta(days=1), 20, 70)
        rows.insert(0, {"resting_hr": 63, "measured_at": today.isoformat()})
        db = _FakeDb({"cardio_metrics": rows})

        out = _compute_rhr_delta(db, "user-1")
        assert out is not None
        assert out["delta_pct"] == pytest.approx(-10.0, abs=0.01)


# ---------------------------------------------------------------------------
# _classify_cardio_load_state
# ---------------------------------------------------------------------------


class TestClassifyCardioLoadState:
    def test_none_when_no_signal(self):
        assert _classify_cardio_load_state(None, None) is None

    def test_acwr_undertrained(self):
        assert _classify_cardio_load_state(500.0, 0.5) == "undertrained"

    def test_acwr_balanced_lower_bound(self):
        assert _classify_cardio_load_state(500.0, 0.8) == "balanced"

    def test_acwr_balanced_upper_bound(self):
        assert _classify_cardio_load_state(500.0, 1.3) == "balanced"

    def test_acwr_overreaching(self):
        assert _classify_cardio_load_state(500.0, 1.6) == "overreaching"

    def test_trimp_fallback_undertrained(self):
        # Below the 150 weekly TRIMP floor.
        assert _classify_cardio_load_state(50.0, None) == "undertrained"

    def test_trimp_fallback_balanced(self):
        assert _classify_cardio_load_state(300.0, None) == "balanced"


# ---------------------------------------------------------------------------
# _compute_weekly_trimp (integration with training_load_service)
# ---------------------------------------------------------------------------


class TestComputeWeeklyTrimp:
    def test_none_when_no_cardio(self, monkeypatch):
        # training_load_service returns empty → None.
        from services import training_load_service

        monkeypatch.setattr(
            training_load_service,
            "compute_training_load_history",
            lambda db, uid, days=120: [],
        )
        db = _FakeDb()
        assert _compute_weekly_trimp(db, "user-1") is None

    def test_sums_history_points(self, monkeypatch):
        from services import training_load_service
        from services.training_load_service import TrainingLoadDayPoint

        today = date.today()
        history = [
            TrainingLoadDayPoint(
                date=today - timedelta(days=i),
                daily_trimp=20.0,
                acute_load=0.0,
                chronic_load=0.0,
                acwr=None,
            )
            for i in range(7)
        ]
        monkeypatch.setattr(
            training_load_service,
            "compute_training_load_history",
            lambda db, uid, days=120: history,
        )
        db = _FakeDb()
        assert _compute_weekly_trimp(db, "user-1") == pytest.approx(140.0)

    def test_returns_none_when_all_zeros(self, monkeypatch):
        from services import training_load_service
        from services.training_load_service import TrainingLoadDayPoint

        today = date.today()
        history = [
            TrainingLoadDayPoint(
                date=today - timedelta(days=i),
                daily_trimp=0.0,
                acute_load=0.0,
                chronic_load=0.0,
                acwr=None,
            )
            for i in range(7)
        ]
        monkeypatch.setattr(
            training_load_service,
            "compute_training_load_history",
            lambda db, uid, days=120: history,
        )
        db = _FakeDb()
        assert _compute_weekly_trimp(db, "user-1") is None


# ---------------------------------------------------------------------------
# compute_readiness — backward compat + new fields
# ---------------------------------------------------------------------------


@pytest.fixture
def baseline_check_in() -> ReadinessCheckIn:
    return ReadinessCheckIn(
        sleep_quality=2,
        fatigue_level=2,
        stress_level=2,
        muscle_soreness=2,
    )


class TestComputeReadiness:
    def test_existing_callers_still_work_without_cardio(
        self, baseline_check_in, monkeypatch
    ):
        # No RHR data, no cardio → all extension fields are None,
        # Hooper score and level still computed.
        from services import training_load_service

        monkeypatch.setattr(
            training_load_service,
            "compute_training_load_history",
            lambda db, uid, days=120: [],
        )
        monkeypatch.setattr(
            training_load_service,
            "current_state",
            lambda db, uid: SimpleNamespace(acwr=None),
        )

        db = _FakeDb({"cardio_metrics": []})
        out = compute_readiness(db, "user-1", baseline_check_in)

        assert out["hooper_index"] == 8
        assert out["readiness_score"] > 80
        assert out["readiness_level"] in {"optimal", "good"}
        assert out["rhr_baseline_bpm"] is None
        assert out["rhr_today_bpm"] is None
        assert out["rhr_delta_pct"] is None
        assert out["weekly_trimp"] is None
        assert out["cardio_load_state"] is None

    def test_populates_rhr_fields_when_data_present(
        self, baseline_check_in, monkeypatch
    ):
        from services import training_load_service

        monkeypatch.setattr(
            training_load_service,
            "compute_training_load_history",
            lambda db, uid, days=120: [],
        )
        monkeypatch.setattr(
            training_load_service,
            "current_state",
            lambda db, uid: SimpleNamespace(acwr=None),
        )

        today = date.today()
        rows = _rhr_rows(today - timedelta(days=1), 20, 60)
        rows.insert(0, {"resting_hr": 60, "measured_at": today.isoformat()})
        db = _FakeDb({"cardio_metrics": rows})

        out = compute_readiness(db, "user-1", baseline_check_in)
        assert out["rhr_baseline_bpm"] == 60.0
        assert out["rhr_today_bpm"] == 60
        assert out["rhr_delta_pct"] == 0.0

    def test_rhr_elevation_penalty_lowers_score(
        self, baseline_check_in, monkeypatch
    ):
        from services import training_load_service

        monkeypatch.setattr(
            training_load_service,
            "compute_training_load_history",
            lambda db, uid, days=120: [],
        )
        monkeypatch.setattr(
            training_load_service,
            "current_state",
            lambda db, uid: SimpleNamespace(acwr=None),
        )

        # 20-day flat baseline at 60bpm + today at 66bpm = +10% (above 5% threshold).
        today = date.today()
        rows = _rhr_rows(today - timedelta(days=1), 20, 60)
        rows.insert(0, {"resting_hr": 66, "measured_at": today.isoformat()})
        db = _FakeDb({"cardio_metrics": rows})

        # Baseline run (no RHR penalty) → run with same Hooper but no metrics.
        unpenalised = compute_readiness(_FakeDb({"cardio_metrics": []}), "u", baseline_check_in)
        penalised = compute_readiness(db, "user-1", baseline_check_in)

        assert penalised["rhr_delta_pct"] >= 5.0
        assert penalised["readiness_score"] < unpenalised["readiness_score"]
        # ~10% drop (allow rounding).
        assert penalised["readiness_score"] == round(
            unpenalised["readiness_score"] * 0.90
        )

    def test_persist_writes_extension_columns(
        self, baseline_check_in, monkeypatch
    ):
        from services import training_load_service

        monkeypatch.setattr(
            training_load_service,
            "compute_training_load_history",
            lambda db, uid, days=120: [],
        )
        monkeypatch.setattr(
            training_load_service,
            "current_state",
            lambda db, uid: SimpleNamespace(acwr=None),
        )

        db = _FakeDb({"cardio_metrics": []})
        compute_readiness(db, "user-1", baseline_check_in, persist=True)

        upserts = db.client.table("readiness_scores").upserts
        assert len(upserts) == 1
        row = upserts[0]
        # New columns present (even when null) so backfill/migration is honoured.
        for col in (
            "rhr_baseline_bpm",
            "rhr_today_bpm",
            "rhr_delta_pct",
            "weekly_trimp",
            "cardio_load_state",
        ):
            assert col in row
