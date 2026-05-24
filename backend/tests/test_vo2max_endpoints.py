"""
Tests for /vo2max/history and /vo2max/latest.

Run:
    cd backend && .venv/bin/python -m pytest \
        tests/test_vo2max_endpoints.py -v --noconftest

Per feedback_testclient_httpx_skew, we don't use fastapi.testclient — we
call the endpoint functions directly with mocked DB deps.
"""
from __future__ import annotations

import asyncio
from typing import Any, Dict, List, Optional
from unittest.mock import MagicMock, patch

import pytest

from api.v1 import vo2max_endpoints as ep


# ---------------------------------------------------------------------------
# Fake Supabase chain
# ---------------------------------------------------------------------------
class _Exec:
    def __init__(self, data: List[Dict[str, Any]]):
        self.data = data


class _Not:
    def __init__(self, parent: "_Q"):
        self._parent = parent

    def is_(self, *_a, **_kw) -> "_Q":
        return self._parent


class _Q:
    """Mimics the subset of postgrest's chained query API the endpoints use."""

    def __init__(self, data: List[Dict[str, Any]]):
        self._data = data
        self.not_ = _Not(self)

    def select(self, *_a, **_kw) -> "_Q":
        return self

    def eq(self, *_a, **_kw) -> "_Q":
        return self

    def gte(self, *_a, **_kw) -> "_Q":
        return self

    def lte(self, *_a, **_kw) -> "_Q":
        return self

    def order(self, *_a, **_kw) -> "_Q":
        return self

    def limit(self, *_a, **_kw) -> "_Q":
        return self

    def execute(self) -> _Exec:
        return _Exec(self._data)


def _mk_db(rows_by_table: Dict[str, List[Dict[str, Any]]]) -> MagicMock:
    db = MagicMock()

    def _table(name: str) -> _Q:
        return _Q(rows_by_table.get(name, []))

    db.client.table.side_effect = _table
    return db


def _run(coro):
    return asyncio.get_event_loop().run_until_complete(coro)


USER = {"id": "11111111-1111-1111-1111-111111111111"}


# ---------------------------------------------------------------------------
# /vo2max/history
# ---------------------------------------------------------------------------
def test_history_empty_when_no_metrics():
    db = _mk_db({"cardio_metrics": []})
    with patch.object(ep, "get_supabase_db", return_value=db):
        result = _run(ep.get_vo2max_history(days=180, current_user=USER))
    assert result == []


def test_history_filters_null_vo2_rows():
    """Defense-in-depth: even if the DB-level NOT NULL filter is skipped
    (older postgrest-py without `.not_`), the Python guard must drop NULL
    rows so the contract holds."""
    rows = [
        {
            "measured_at": "2026-04-01T12:00:00+00:00",
            "vo2_max_estimate": 48.5,
            "source": "health_kit",
        },
        {
            "measured_at": "2026-04-15T12:00:00+00:00",
            "vo2_max_estimate": None,  # must be filtered out
            "source": "calculated",
        },
        {
            "measured_at": "2026-05-01T12:00:00+00:00",
            "vo2_max_estimate": 49.1,
            "source": "health_kit",
        },
    ]
    db = _mk_db({"cardio_metrics": rows})
    with patch.object(ep, "get_supabase_db", return_value=db):
        result = _run(ep.get_vo2max_history(days=180, current_user=USER))

    assert len(result) == 2
    assert [round(p.ml_per_kg_per_min, 2) for p in result] == [48.5, 49.1]
    assert all(p.source == "health_kit" for p in result)


def test_history_passes_through_source_label():
    rows = [
        {
            "measured_at": "2026-05-10T08:00:00+00:00",
            "vo2_max_estimate": 51.0,
            "source": "manual",
        },
    ]
    db = _mk_db({"cardio_metrics": rows})
    with patch.object(ep, "get_supabase_db", return_value=db):
        result = _run(ep.get_vo2max_history(days=30, current_user=USER))
    assert len(result) == 1
    assert result[0].source == "manual"
    assert result[0].ml_per_kg_per_min == 51.0


# ---------------------------------------------------------------------------
# /vo2max/latest
# ---------------------------------------------------------------------------
def test_latest_returns_nulls_when_no_data():
    db = _mk_db({"latest_cardio_metrics": []})
    with patch.object(ep, "get_supabase_db", return_value=db):
        result = _run(ep.get_vo2max_latest(current_user=USER))
    assert result.recorded_at is None
    assert result.ml_per_kg_per_min is None
    assert result.source is None
    assert result.fitness_age is None


def test_latest_returns_nulls_when_row_has_null_vo2():
    """The `latest_cardio_metrics` view picks the most recent row regardless
    of which column is populated — a max-HR-only row must surface as 'no
    VO2max' to the client, not as a partial payload."""
    db = _mk_db(
        {
            "latest_cardio_metrics": [
                {
                    "measured_at": "2026-05-20T10:00:00+00:00",
                    "vo2_max_estimate": None,
                    "source": "calculated",
                    "fitness_age": None,
                }
            ]
        }
    )
    with patch.object(ep, "get_supabase_db", return_value=db):
        result = _run(ep.get_vo2max_latest(current_user=USER))
    assert result.ml_per_kg_per_min is None
    assert result.recorded_at is None


def test_latest_returns_full_payload():
    db = _mk_db(
        {
            "latest_cardio_metrics": [
                {
                    "measured_at": "2026-05-22T07:30:00+00:00",
                    "vo2_max_estimate": 52.4,
                    "source": "health_kit",
                    "fitness_age": 28,
                }
            ]
        }
    )
    with patch.object(ep, "get_supabase_db", return_value=db):
        result = _run(ep.get_vo2max_latest(current_user=USER))
    assert result.ml_per_kg_per_min == 52.4
    assert result.source == "health_kit"
    assert result.fitness_age == 28
    assert result.recorded_at is not None
