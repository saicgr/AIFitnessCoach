"""
Tests for backend/services/cardio_dedup_service.py.

Strategy: most logic lives in pure helpers (`_is_match`, `_pick_primary`) so
those get exhaustive tests. The DB-touching functions are tested against a
minimal in-memory fake of the Supabase client interface — just the chained
methods this service actually calls (.table().select().eq().execute() and the
update/in_ variants).
"""
from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional
from uuid import uuid4

import pytest

from services.cardio_dedup_service import (
    DURATION_TOLERANCE_PCT,
    TIME_WINDOW_SECONDS,
    _is_match,
    _pick_primary,
    apply_dedup_group,
    list_dedup_groups_for_user,
    override_primary,
    resolve_dedup_group,
    unlink_from_group,
)


UTC = timezone.utc


# ---------------------------------------------------------------------------
# Pure-helper tests
# ---------------------------------------------------------------------------

def _row(activity: str, perf: datetime, duration: int) -> Dict[str, Any]:
    return {
        "activity_type": activity,
        "performed_at": perf,
        "duration_seconds": duration,
    }


class TestIsMatch:
    def test_match_within_window(self):
        t = datetime(2026, 5, 23, 7, 0, 0, tzinfo=UTC)
        a = _row("run", t, 1800)
        b = _row("run", t + timedelta(seconds=89), 1800)
        assert _is_match(a, b) is True

    def test_no_match_just_outside_time_window(self):
        # 91s — boundary check
        t = datetime(2026, 5, 23, 7, 0, 0, tzinfo=UTC)
        a = _row("run", t, 1800)
        b = _row("run", t + timedelta(seconds=TIME_WINDOW_SECONDS + 1), 1800)
        assert _is_match(a, b) is False

    def test_match_at_boundary_inside(self):
        t = datetime(2026, 5, 23, 7, 0, 0, tzinfo=UTC)
        a = _row("run", t, 1800)
        b = _row("run", t + timedelta(seconds=TIME_WINDOW_SECONDS), 1800)
        # ==90 is allowed (<=)
        assert _is_match(a, b) is True

    def test_no_match_different_sport(self):
        t = datetime(2026, 5, 23, 7, 0, 0, tzinfo=UTC)
        a = _row("run", t, 1800)
        b = _row("cycle", t, 1800)
        assert _is_match(a, b) is False

    def test_duration_within_5_percent(self):
        # 1800 vs 1890 = 5.0% on the larger denominator → at boundary
        t = datetime(2026, 5, 23, 7, 0, 0, tzinfo=UTC)
        a = _row("run", t, 1800)
        b = _row("run", t, 1890)  # 90/1890 = 4.76% → match
        assert _is_match(a, b) is True

    def test_duration_outside_5_percent(self):
        t = datetime(2026, 5, 23, 7, 0, 0, tzinfo=UTC)
        a = _row("run", t, 1800)
        b = _row("run", t, 2000)  # 200/2000 = 10% → no match
        assert _is_match(a, b) is False

    def test_zero_duration_never_matches(self):
        t = datetime(2026, 5, 23, 7, 0, 0, tzinfo=UTC)
        a = _row("run", t, 0)
        b = _row("run", t, 1800)
        assert _is_match(a, b) is False


class TestPickPrimary:
    def _r(self, _id: str, source: str, created: datetime) -> Dict[str, Any]:
        return {"id": _id, "source_app": source, "created_at": created}

    def test_strava_beats_garmin(self):
        base = datetime(2026, 5, 23, 7, 0, 0, tzinfo=UTC)
        rows = [
            self._r("a", "garmin", base),
            self._r("b", "strava", base),
        ]
        primary, losers = _pick_primary(rows)
        assert primary == "b"
        assert losers == ["a"]

    def test_garmin_beats_apple_health(self):
        base = datetime(2026, 5, 23, 7, 0, 0, tzinfo=UTC)
        rows = [
            self._r("ah", "apple_health", base),
            self._r("gm", "garmin", base),
        ]
        primary, losers = _pick_primary(rows)
        assert primary == "gm"
        assert losers == ["ah"]

    def test_apple_health_beats_manual(self):
        base = datetime(2026, 5, 23, 7, 0, 0, tzinfo=UTC)
        rows = [
            self._r("mn", "manual", base),
            self._r("ah", "apple_health", base),
        ]
        primary, _ = _pick_primary(rows)
        assert primary == "ah"

    def test_tie_break_newer_wins(self):
        # Two strava rows — newer created_at wins.
        old = datetime(2026, 5, 23, 7, 0, 0, tzinfo=UTC)
        new = datetime(2026, 5, 23, 8, 0, 0, tzinfo=UTC)
        rows = [
            self._r("old", "strava", old),
            self._r("new", "strava", new),
        ]
        primary, losers = _pick_primary(rows)
        assert primary == "new"
        assert losers == ["old"]

    def test_unknown_source_priority_zero(self):
        # peloton isn't in the priority map → 0, loses to anything listed.
        base = datetime(2026, 5, 23, 7, 0, 0, tzinfo=UTC)
        rows = [
            self._r("pl", "peloton", base),
            self._r("mn", "manual", base),
        ]
        primary, _ = _pick_primary(rows)
        assert primary == "mn"

    def test_three_way_full_ordering(self):
        base = datetime(2026, 5, 23, 7, 0, 0, tzinfo=UTC)
        rows = [
            self._r("hc", "health_connect", base),
            self._r("st", "strava", base),
            self._r("mn", "manual", base),
        ]
        primary, losers = _pick_primary(rows)
        assert primary == "st"
        assert set(losers) == {"hc", "mn"}


# ---------------------------------------------------------------------------
# Fake Supabase client — just enough to drive the service methods.
# ---------------------------------------------------------------------------

class _FakeResult:
    def __init__(self, data: List[Dict[str, Any]]):
        self.data = data


class _FakeQuery:
    """Captures filters + executes against the in-memory table state."""

    def __init__(self, table: "_FakeTable", op: str, payload: Optional[Dict[str, Any]] = None):
        self.table = table
        self.op = op  # "select" | "update"
        self.payload = payload or {}
        self.filters: List[tuple] = []
        self._single = False
        self._select_cols = "*"

    # Chainable methods (return self).
    def select(self, cols: str = "*"):
        self._select_cols = cols
        return self

    def eq(self, col, val):
        self.filters.append(("eq", col, val))
        return self

    def in_(self, col, vals):
        self.filters.append(("in", col, list(vals)))
        return self

    def gte(self, col, val):
        self.filters.append(("gte", col, val))
        return self

    def lte(self, col, val):
        self.filters.append(("lte", col, val))
        return self

    @property
    def not_(self):
        # Supports .not_.is_("col", "null")
        outer = self

        class _Not:
            def is_(self, col, val):
                outer.filters.append(("not_is", col, val))
                return outer
        return _Not()

    def order(self, *_a, **_kw):
        return self

    def single(self):
        self._single = True
        return self

    def _matches(self, row: Dict[str, Any]) -> bool:
        for f in self.filters:
            kind = f[0]
            if kind == "eq":
                if row.get(f[1]) != f[2]:
                    return False
            elif kind == "in":
                if row.get(f[1]) not in f[2]:
                    return False
            elif kind == "gte":
                if row.get(f[1]) is None or row.get(f[1]) < f[2]:
                    return False
            elif kind == "lte":
                if row.get(f[1]) is None or row.get(f[1]) > f[2]:
                    return False
            elif kind == "not_is":
                # "null" sentinel
                if f[2] == "null" and row.get(f[1]) is None:
                    return False
        return True

    def execute(self) -> _FakeResult:
        if self.op == "select":
            matched = [dict(r) for r in self.table.rows if self._matches(r)]
            if self._single:
                return _FakeResult(matched[0] if matched else None)  # type: ignore[arg-type]
            return _FakeResult(matched)
        if self.op == "update":
            updated: List[Dict[str, Any]] = []
            for r in self.table.rows:
                if self._matches(r):
                    r.update(self.payload)
                    updated.append(dict(r))
            return _FakeResult(updated)
        raise AssertionError(f"unsupported op {self.op}")


class _FakeTable:
    def __init__(self, rows: List[Dict[str, Any]]):
        self.rows = rows

    def select(self, cols: str = "*"):
        return _FakeQuery(self, "select").select(cols)

    def update(self, payload: Dict[str, Any]):
        return _FakeQuery(self, "update", payload)


class _FakeClient:
    def __init__(self, rows: List[Dict[str, Any]]):
        self._table = _FakeTable(rows)

    def table(self, name: str):
        assert name == "cardio_logs"
        return self._table


class _FakeDB:
    def __init__(self, rows: List[Dict[str, Any]]):
        self.client = _FakeClient(rows)


def _mk_row(
    _id: str,
    user_id: str = "u1",
    activity: str = "run",
    perf: Optional[datetime] = None,
    duration: int = 1800,
    distance: float = 5000.0,
    source: str = "manual",
    created: Optional[datetime] = None,
    dedup_group_id: Optional[str] = None,
    is_hidden_duplicate: bool = False,
) -> Dict[str, Any]:
    perf = perf or datetime(2026, 5, 23, 7, 0, 0, tzinfo=UTC)
    created = created or datetime(2026, 5, 23, 7, 5, 0, tzinfo=UTC)
    return {
        "id": _id,
        "user_id": user_id,
        "activity_type": activity,
        "performed_at": perf.isoformat(),
        "duration_seconds": duration,
        "distance_m": distance,
        "source_app": source,
        "created_at": created.isoformat(),
        "dedup_group_id": dedup_group_id,
        "is_hidden_duplicate": is_hidden_duplicate,
    }


# ---------------------------------------------------------------------------
# DB-facing function tests
# ---------------------------------------------------------------------------

class TestApplyDedupGroup:
    def test_writes_primary_and_hidden(self):
        rows = [
            _mk_row("p"),
            _mk_row("h1"),
            _mk_row("h2"),
        ]
        db = _FakeDB(rows)
        updated = apply_dedup_group(db, "p", ["h1", "h2"])
        assert updated == 3
        by_id = {r["id"]: r for r in db.client._table.rows}
        assert by_id["p"]["dedup_group_id"] == "p"
        assert by_id["p"]["is_hidden_duplicate"] is False
        assert by_id["h1"]["is_hidden_duplicate"] is True
        assert by_id["h2"]["dedup_group_id"] == "p"

    def test_idempotent(self):
        rows = [_mk_row("p"), _mk_row("h1")]
        db = _FakeDB(rows)
        apply_dedup_group(db, "p", ["h1"])
        snapshot = [dict(r) for r in db.client._table.rows]
        apply_dedup_group(db, "p", ["h1"])  # second time
        assert db.client._table.rows == snapshot


class TestOverridePrimary:
    def test_swaps_roles(self):
        # Existing group: primary=a, hidden=b
        rows = [
            _mk_row("a", dedup_group_id="a", is_hidden_duplicate=False),
            _mk_row("b", dedup_group_id="a", is_hidden_duplicate=True),
        ]
        db = _FakeDB(rows)
        override_primary(db, user_id="u1", group_id="a", new_primary_id="b")
        by_id = {r["id"]: r for r in db.client._table.rows}
        assert by_id["b"]["is_hidden_duplicate"] is False
        assert by_id["a"]["is_hidden_duplicate"] is True
        # Both rows now point at the new primary id "b"
        assert by_id["a"]["dedup_group_id"] == "b"
        assert by_id["b"]["dedup_group_id"] == "b"

    def test_rejects_unrelated_log(self):
        rows = [
            _mk_row("a", dedup_group_id="a", is_hidden_duplicate=False),
            _mk_row("b", dedup_group_id="a", is_hidden_duplicate=True),
            _mk_row("c"),  # not in the group
        ]
        db = _FakeDB(rows)
        with pytest.raises(ValueError):
            override_primary(db, user_id="u1", group_id="a", new_primary_id="c")


class TestUnlinkFromGroup:
    def test_restores_standalone(self):
        rows = [
            _mk_row("a", dedup_group_id="a", is_hidden_duplicate=False),
            _mk_row("b", dedup_group_id="a", is_hidden_duplicate=True),
        ]
        db = _FakeDB(rows)
        unlink_from_group(db, user_id="u1", log_id="b")
        by_id = {r["id"]: r for r in db.client._table.rows}
        assert by_id["b"]["dedup_group_id"] is None
        assert by_id["b"]["is_hidden_duplicate"] is False
        # Primary unchanged
        assert by_id["a"]["dedup_group_id"] == "a"

    def test_missing_log_raises(self):
        db = _FakeDB([_mk_row("a")])
        with pytest.raises(ValueError):
            unlink_from_group(db, user_id="u1", log_id="missing")


class TestListDedupGroupsForUser:
    def test_returns_only_multi_member_groups(self):
        rows = [
            _mk_row("a", dedup_group_id="a", is_hidden_duplicate=False),
            _mk_row("b", dedup_group_id="a", is_hidden_duplicate=True, source="strava"),
            _mk_row("c", dedup_group_id="c", is_hidden_duplicate=False),  # solo group
        ]
        db = _FakeDB(rows)
        groups = list_dedup_groups_for_user(db, user_id="u1")
        assert len(groups) == 1
        g = groups[0]
        assert g.primary.id == "a"
        assert [d.id for d in g.duplicates] == ["b"]
