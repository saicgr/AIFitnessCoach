"""
Tests for `services/user_context/cardio_activity.get_cardio_context_for_ai`.

Asserts (SLICE_COACH):
  - Empty-history user → returns None.
  - 14d history → compact string under 250 naive tokens.
  - Focus cardio_log_id appears in output prefixed "THIS session".
  - Token cap enforced even with extreme history.
  - VO2max trend included when latest_cardio_metrics has data.
  - 3 PRs only — even if user has 50.

All Supabase access is mocked. No network, no DB.
"""
from __future__ import annotations

import asyncio
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional
from unittest.mock import MagicMock

import pytest

from services.user_context import cardio_activity


# ---------------------------------------------------------------------------
# Fake Supabase query-builder — chainable, table-aware.
# ---------------------------------------------------------------------------
class _FakeExec:
    def __init__(self, data: List[Dict[str, Any]]):
        self.data = data


class _FakeQuery:
    def __init__(self, rows: List[Dict[str, Any]]):
        self._rows = rows

    # All filters are no-ops — the test fixture decides per-table what rows
    # come back. This keeps the mocks tiny while letting us cover branches.
    def select(self, *_a, **_kw):
        return self

    def eq(self, *_a, **_kw):
        return self

    def gte(self, *_a, **_kw):
        return self

    def lte(self, *_a, **_kw):
        return self

    def order(self, *_a, **_kw):
        return self

    def limit(self, *_a, **_kw):
        return self

    @property
    def not_(self):
        return self

    def is_(self, *_a, **_kw):
        return self

    def execute(self):
        return _FakeExec(self._rows)


class _FakeClient:
    def __init__(self, tables: Dict[str, List[Dict[str, Any]]]):
        self._tables = tables

    def table(self, name: str) -> _FakeQuery:
        return _FakeQuery(list(self._tables.get(name, [])))


class _FakeDB:
    def __init__(self, tables: Dict[str, List[Dict[str, Any]]]):
        self.client = _FakeClient(tables)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def _run(coro):
    return asyncio.get_event_loop().run_until_complete(coro)


def _mk_log(
    *, id: str, performed_at: datetime, activity_type: str = "run",
    distance_m: Optional[float] = 5000, duration_seconds: int = 1800,
    pace: Optional[float] = 360.0, hr: Optional[int] = 145,
    user_id: str = "u1",
) -> Dict[str, Any]:
    return {
        "id": id,
        "user_id": user_id,
        "performed_at": performed_at.isoformat(),
        "activity_type": activity_type,
        "distance_m": distance_m,
        "duration_seconds": duration_seconds,
        "avg_pace_seconds_per_km": pace,
        "avg_heart_rate": hr,
        "elevation_gain_m": 0,
        "tags": [],
    }


# ===========================================================================
# Tests
# ===========================================================================
def test_empty_history_returns_none():
    db = _FakeDB({})
    out = _run(cardio_activity.get_cardio_context_for_ai(
        user_id="u1", db=db,
    ))
    assert out is None


def test_14d_history_under_token_cap_and_has_headline():
    now = datetime.now(timezone.utc)
    logs = [
        _mk_log(id=f"l{i}", performed_at=now - timedelta(days=i),
                activity_type="run", distance_m=5000 + i * 100)
        for i in range(6)
    ]
    db = _FakeDB({
        "cardio_logs": logs,
        "cardio_sessions": [],
        "latest_cardio_metrics": [],
        "cardio_metric_snapshots": [],
        "personal_records": [],
    })
    out = _run(cardio_activity.get_cardio_context_for_ai(
        user_id="u1", db=db,
    ))
    assert out is not None
    # Naive token estimate (matches spec verification step).
    assert len(out) // 4 <= 250
    assert "CARDIO" in out
    assert "sessions" in out
    assert "Top sport" in out


def test_focus_session_appears_as_this_session_line():
    now = datetime.now(timezone.utc)
    focus_id = "focus-1"
    focus_row = _mk_log(
        id=focus_id, performed_at=now, activity_type="run",
        distance_m=5200, duration_seconds=1620, pace=311.5, hr=158,
    )
    # focus row also present in cardio_logs window
    logs = [focus_row] + [
        _mk_log(id=f"l{i}", performed_at=now - timedelta(days=i + 1))
        for i in range(3)
    ]

    # cardio_activity does the focus lookup via a separate .eq('id',...)
    # call — our fake query ignores filters, so the table data for that
    # call is simply `[focus_row]`.
    tables = {
        "cardio_logs": logs,
        "cardio_sessions": [],
        "latest_cardio_metrics": [],
        "cardio_metric_snapshots": [],
        "personal_records": [],
    }

    # Patch the table() lookup so the focus query returns ONLY focus_row.
    # We do this by intercepting the second cardio_logs call.
    call_count = {"n": 0}

    class _AwareClient(_FakeClient):
        def table(self, name):  # type: ignore[override]
            if name == "cardio_logs":
                call_count["n"] += 1
                if call_count["n"] == 2:  # focus lookup
                    return _FakeQuery([focus_row])
                return _FakeQuery(logs)
            return _FakeQuery(list(tables.get(name, [])))

    db = MagicMock()
    db.client = _AwareClient(tables)

    out = _run(cardio_activity.get_cardio_context_for_ai(
        user_id="u1", focus_cardio_log_id=focus_id, db=db,
    ))
    assert out is not None
    assert "THIS session" in out
    assert "run" in out


def test_focus_session_other_user_is_silently_omitted():
    now = datetime.now(timezone.utc)
    # Focus row belongs to a DIFFERENT user.
    focus_row = _mk_log(
        id="x", performed_at=now, user_id="other-user",
    )
    logs = [_mk_log(id="l1", performed_at=now - timedelta(days=1))]

    call_count = {"n": 0}

    class _AwareClient(_FakeClient):
        def table(self, name):  # type: ignore[override]
            if name == "cardio_logs":
                call_count["n"] += 1
                if call_count["n"] == 2:
                    return _FakeQuery([focus_row])
                return _FakeQuery(logs)
            return _FakeQuery([])

    db = MagicMock()
    db.client = _AwareClient({})
    out = _run(cardio_activity.get_cardio_context_for_ai(
        user_id="u1", focus_cardio_log_id="x", db=db,
    ))
    assert out is not None
    # Cross-user focus row is silently dropped — no THIS session line.
    assert "THIS session" not in out


def test_token_cap_enforced_with_extreme_history():
    now = datetime.now(timezone.utc)
    # 50 logs all with long-ish data — would blow past the 1000-char cap if
    # unbounded.
    logs = [
        _mk_log(id=f"l{i}", performed_at=now - timedelta(days=i % 14),
                activity_type="trail_run",
                distance_m=12345.678 + i, duration_seconds=3600 + i)
        for i in range(50)
    ]
    db = _FakeDB({
        "cardio_logs": logs,
        "cardio_sessions": [],
        "latest_cardio_metrics": [],
        "cardio_metric_snapshots": [],
        "personal_records": [],
    })
    out = _run(cardio_activity.get_cardio_context_for_ai(
        user_id="u1", db=db,
    ))
    assert out is not None
    assert len(out) <= 1000  # MAX_TOKENS * 4
    assert len(out) // 4 <= 250


def test_vo2max_appears_when_view_has_data():
    now = datetime.now(timezone.utc)
    logs = [_mk_log(id="l1", performed_at=now)]
    db = _FakeDB({
        "cardio_logs": logs,
        "cardio_sessions": [],
        "latest_cardio_metrics": [
            {"vo2_max_estimate": 47.3, "source": "calculated"},
        ],
        "cardio_metric_snapshots": [],
        "personal_records": [],
    })
    out = _run(cardio_activity.get_cardio_context_for_ai(
        user_id="u1", db=db,
    ))
    assert out is not None
    assert "VO2max" in out
    assert "47.3" in out


def test_at_most_three_prs_even_when_user_has_fifty():
    # Even though we mock the fake query to ignore .limit(), the function
    # itself slices [:_MAX_PRS] to enforce the rule. The test pumps in 50
    # rows and asserts only 3 sport-tagged names land in the output.
    now = datetime.now(timezone.utc)
    logs = [_mk_log(id="l1", performed_at=now)]
    prs = [
        {
            "exercise_name": f"PR_{i}",
            "sport": "running",
            "achieved_at": (now - timedelta(days=i)).isoformat(),
            "weight_kg": 0,
            "reps": 0,
        }
        for i in range(50)
    ]
    db = _FakeDB({
        "cardio_logs": logs,
        "cardio_sessions": [],
        "latest_cardio_metrics": [],
        "cardio_metric_snapshots": [],
        "personal_records": prs,
    })
    out = _run(cardio_activity.get_cardio_context_for_ai(
        user_id="u1", db=db,
    ))
    assert out is not None
    assert "Recent PRs:" in out
    # Count PR labels — exactly 3 should appear.
    pr_appearances = sum(1 for i in range(50) if f"PR_{i}" in out)
    assert pr_appearances == 3
