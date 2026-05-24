"""
Tests for cardio_pr_service.

These avoid hitting Supabase by injecting `cardio_log_override` for the row
under test + a thin fake DB whose `client.table(...).select(...)` chain
returns pre-canned responses for `personal_records` and `cardio_logs`
weekly queries.

Run: cd backend && .venv/bin/python -m pytest tests/test_cardio_pr_service.py -v
"""
from __future__ import annotations

from datetime import datetime, timezone, timedelta
from typing import Any, Dict, List, Optional
import uuid

import pytest

from services.cardio_pr_service import (
    CardioPrService,
    CardioPrCandidate,
    ACTIVITY_TYPE_TO_SPORT,
    MILE_M,
    FIVE_K_M,
)


# ---------------------------------------------------------------------------
# Fake DB
# ---------------------------------------------------------------------------

class _FakeResp:
    def __init__(self, data: List[Dict[str, Any]]):
        self.data = data


class _FakeQuery:
    """Records filters; resolves on .execute() against `_FakeDB`'s table store.

    Only supports the chain shapes the service actually uses:
      .select(...).eq(...).eq(...)[.in_(...)][.gte(...).lte(...)][.order(...)]
        [.limit(...)][.not_.is_(col, "null")].execute()
    """

    def __init__(self, db: "_FakeDB", table_name: str):
        self._db = db
        self._table = table_name
        self._filters: List[tuple] = []  # (op, col, value)
        self._inserts: Optional[Dict[str, Any]] = None
        self._not = False

    def select(self, *_args, **_kwargs) -> "_FakeQuery":
        return self

    def eq(self, col, value) -> "_FakeQuery":
        self._filters.append(("eq", col, value))
        return self

    def in_(self, col, values) -> "_FakeQuery":
        self._filters.append(("in", col, list(values)))
        return self

    def gte(self, col, value) -> "_FakeQuery":
        self._filters.append(("gte", col, value))
        return self

    def lte(self, col, value) -> "_FakeQuery":
        self._filters.append(("lte", col, value))
        return self

    def order(self, *_args, **_kwargs) -> "_FakeQuery":
        return self

    def limit(self, _n) -> "_FakeQuery":
        return self

    @property
    def not_(self) -> "_FakeQuery":
        self._not = True
        return self

    def is_(self, col, value) -> "_FakeQuery":
        # "not is null" — leave value-pass-through; filter logic ignores it.
        return self

    def insert(self, payload: Dict[str, Any]) -> "_FakeQuery":
        self._inserts = payload
        return self

    def execute(self) -> _FakeResp:
        if self._inserts is not None:
            new_row = dict(self._inserts)
            new_row.setdefault("id", str(uuid.uuid4()))
            self._db.tables.setdefault(self._table, []).append(new_row)
            return _FakeResp([new_row])

        rows = list(self._db.tables.get(self._table, []))
        for op, col, val in self._filters:
            if op == "eq":
                rows = [r for r in rows if str(r.get(col)) == str(val)]
            elif op == "in":
                rows = [r for r in rows if r.get(col) in val]
            elif op == "gte":
                rows = [r for r in rows if (r.get(col) is not None and str(r.get(col)) >= str(val))]
            elif op == "lte":
                rows = [r for r in rows if (r.get(col) is not None and str(r.get(col)) <= str(val))]
        return _FakeResp(rows)


class _FakeClient:
    def __init__(self, db: "_FakeDB"):
        self._db = db

    def table(self, name: str) -> _FakeQuery:
        return _FakeQuery(self._db, name)


class _FakeDB:
    def __init__(self) -> None:
        self.tables: Dict[str, List[Dict[str, Any]]] = {
            "personal_records": [],
            "cardio_logs": [],
        }
        self.client = _FakeClient(self)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

USER = "11111111-1111-1111-1111-111111111111"


def _log(
    *,
    activity_type: str = "run",
    distance_m: float = 5200.0,
    duration_s: int = 1700,
    performed_at: Optional[datetime] = None,
    splits_json: Optional[list] = None,
    avg_speed_mps: Optional[float] = None,
) -> Dict[str, Any]:
    return {
        "id": str(uuid.uuid4()),
        "user_id": USER,
        "activity_type": activity_type,
        "distance_m": distance_m,
        "duration_seconds": duration_s,
        "performed_at": (performed_at or datetime.now(timezone.utc)).isoformat(),
        "splits_json": splits_json,
        "gps_polyline": None,
        "avg_speed_mps": avg_speed_mps,
    }


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

def test_first_ever_activity_only_emits_two_first_time_kinds():
    svc = CardioPrService()
    db = _FakeDB()
    row = _log()
    candidates = svc.detect_cardio_prs(db, row["id"], cardio_log_override=row)

    kinds = {c.kind for c in candidates}
    assert kinds == {"longest_distance", "longest_duration_session"}, kinds
    for c in candidates:
        assert c.is_first_time is True
        assert c.previous_value is None
        assert c.improvement_percent is None
        assert c.sport == "running"


def test_subsequent_session_matching_best_does_not_pr():
    svc = CardioPrService()
    db = _FakeDB()
    # Seed existing PR — longest_distance 6000m running.
    db.tables["personal_records"].append({
        "id": str(uuid.uuid4()),
        "user_id": USER,
        "sport": "running",
        "record_type": "longest_distance",
        "record_value": 6000.0,
        "record_unit": "m",
        "achieved_at": (datetime.now(timezone.utc) - timedelta(days=30)).isoformat(),
    })
    # Equal distance — must NOT beat.
    row = _log(distance_m=6000.0, duration_s=1500)
    cands = svc.detect_cardio_prs(db, row["id"], cardio_log_override=row)
    kinds = {c.kind for c in cands}
    assert "longest_distance" not in kinds


def test_small_improvement_within_7d_suppressed():
    svc = CardioPrService()
    db = _FakeDB()
    # Existing PR set 2 days ago — 6000m.
    db.tables["personal_records"].append({
        "id": str(uuid.uuid4()),
        "user_id": USER,
        "sport": "running",
        "record_type": "longest_distance",
        "record_value": 6000.0,
        "record_unit": "m",
        "achieved_at": (datetime.now(timezone.utc) - timedelta(days=2)).isoformat(),
    })
    # 1.5% improvement — below threshold within 7d window.
    row = _log(distance_m=6090.0, duration_s=1600)
    cands = svc.detect_cardio_prs(db, row["id"], cardio_log_override=row)
    assert all(c.kind != "longest_distance" for c in cands)


def test_large_improvement_within_7d_fires():
    svc = CardioPrService()
    db = _FakeDB()
    db.tables["personal_records"].append({
        "id": str(uuid.uuid4()),
        "user_id": USER,
        "sport": "running",
        "record_type": "longest_distance",
        "record_value": 6000.0,
        "record_unit": "m",
        "achieved_at": (datetime.now(timezone.utc) - timedelta(days=3)).isoformat(),
    })
    # 3% improvement — should fire.
    row = _log(distance_m=6180.0, duration_s=1800)
    cands = svc.detect_cardio_prs(db, row["id"], cardio_log_override=row)
    distance_prs = [c for c in cands if c.kind == "longest_distance"]
    assert len(distance_prs) == 1
    assert distance_prs[0].improvement_percent is not None
    assert distance_prs[0].improvement_percent >= 2.0


def test_fastest_mile_skipped_when_no_splits_or_gps():
    svc = CardioPrService()
    db = _FakeDB()
    # Already an existing PR to avoid the first-time short-circuit.
    db.tables["personal_records"].append({
        "id": str(uuid.uuid4()),
        "user_id": USER,
        "sport": "running",
        "record_type": "longest_distance",
        "record_value": 1000.0,
        "record_unit": "m",
        "achieved_at": (datetime.now(timezone.utc) - timedelta(days=60)).isoformat(),
    })
    row = _log(distance_m=8000.0, duration_s=2700, splits_json=None)
    cands = svc.detect_cardio_prs(db, row["id"], cardio_log_override=row)
    assert all(c.kind != "fastest_mile" for c in cands)
    assert all(c.kind != "fastest_5k" for c in cands)


def test_best_avg_speed_only_for_cycling():
    svc = CardioPrService()
    db = _FakeDB()
    # Existing running PRs (not first-time).
    db.tables["personal_records"].append({
        "id": str(uuid.uuid4()),
        "user_id": USER,
        "sport": "running",
        "record_type": "longest_distance",
        "record_value": 1000.0,
        "record_unit": "m",
        "achieved_at": (datetime.now(timezone.utc) - timedelta(days=60)).isoformat(),
    })
    running_row = _log(activity_type="run", distance_m=8000.0, avg_speed_mps=4.0)
    cands = svc.detect_cardio_prs(db, running_row["id"], cardio_log_override=running_row)
    assert all(c.kind != "best_avg_speed" for c in cands)

    # Cycling: existing cycling PR to bypass first-time.
    db.tables["personal_records"].append({
        "id": str(uuid.uuid4()),
        "user_id": USER,
        "sport": "cycling",
        "record_type": "best_avg_speed",
        "record_value": 25.0,  # km/h
        "record_unit": "kmh",
        "achieved_at": (datetime.now(timezone.utc) - timedelta(days=60)).isoformat(),
    })
    cycle_row = _log(
        activity_type="cycle",
        distance_m=20000.0,
        duration_s=2400,
        avg_speed_mps=9.0,  # 32.4 km/h
    )
    cands = svc.detect_cardio_prs(db, cycle_row["id"], cardio_log_override=cycle_row)
    speed = [c for c in cands if c.kind == "best_avg_speed"]
    assert len(speed) == 1
    assert speed[0].record_unit == "kmh"
    assert speed[0].record_value > 25.0


def test_rolling_7d_distance_window():
    svc = CardioPrService()
    db = _FakeDB()
    # Existing running PR rows seed first-time bypass and a prior weekly PR.
    now = datetime.now(timezone.utc)
    db.tables["personal_records"].append({
        "id": str(uuid.uuid4()),
        "user_id": USER,
        "sport": "running",
        "record_type": "longest_distance",
        "record_value": 1000.0,
        "record_unit": "m",
        "achieved_at": (now - timedelta(days=60)).isoformat(),
    })
    db.tables["personal_records"].append({
        "id": str(uuid.uuid4()),
        "user_id": USER,
        "sport": "running",
        "record_type": "biggest_weekly_distance_km",
        "record_value": 10.0,
        "record_unit": "km",
        "achieved_at": (now - timedelta(days=60)).isoformat(),
    })
    # Seed a week of runs: 4km each on five recent days = 20km.
    for i in range(5):
        db.tables["cardio_logs"].append({
            "id": str(uuid.uuid4()),
            "user_id": USER,
            "activity_type": "run",
            "distance_m": 4000.0,
            "performed_at": (now - timedelta(days=i)).isoformat(),
        })
    # Trigger a new session today (also already counted).
    row = _log(distance_m=4000.0, duration_s=1200, performed_at=now)
    # Append it so the rolling query picks it up.
    db.tables["cardio_logs"].append(row)

    cands = svc.detect_cardio_prs(db, row["id"], cardio_log_override=row)
    weekly = [c for c in cands if c.kind == "biggest_weekly_distance_km"]
    assert len(weekly) == 1
    assert weekly[0].record_value >= 20.0


def test_persist_prs_idempotent():
    svc = CardioPrService()
    db = _FakeDB()
    achieved_at = datetime.now(timezone.utc)
    cand = CardioPrCandidate(
        user_id=USER,
        sport="running",
        kind="longest_distance",
        record_value=8000.0,
        record_unit="m",
        previous_value=None,
        improvement_percent=None,
        is_first_time=True,
        achieved_at=achieved_at,
        celebration_message="x",
    )
    ids1 = svc.persist_prs(db, USER, [cand])
    ids2 = svc.persist_prs(db, USER, [cand])  # same achieved_at — must dedupe.
    assert len(ids1) == 1
    assert len(ids2) == 0
    assert len(db.tables["personal_records"]) == 1


def test_rolling_best_time_for_distance_via_splits():
    """Direct unit test on the rolling-window helper."""
    from services.cardio_pr_service import _rolling_best_time_for_distance
    # 6 splits of 1km, all 5:00 except split #3 = 4:30. Best mile should
    # span split 3 plus part of an adjacent split, so under 8:00 / mile.
    splits = [
        {"distance_m": 1000.0, "elapsed_sec": 300.0},
        {"distance_m": 1000.0, "elapsed_sec": 300.0},
        {"distance_m": 1000.0, "elapsed_sec": 270.0},
        {"distance_m": 1000.0, "elapsed_sec": 300.0},
        {"distance_m": 1000.0, "elapsed_sec": 300.0},
        {"distance_m": 1000.0, "elapsed_sec": 300.0},
    ]
    best_mile = _rolling_best_time_for_distance(splits, None, MILE_M)
    assert best_mile is not None
    assert best_mile < 8 * 60  # under 8 minutes
    best_5k = _rolling_best_time_for_distance(splits, None, FIVE_K_M)
    assert best_5k is not None
    assert best_5k < 26 * 60  # under 26 minutes
