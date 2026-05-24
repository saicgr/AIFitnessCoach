"""
Tests for GET /coach/cardio-insight/{cardio_log_id}.

Asserts (SLICE_COACH):
  - Cache hit returns same insight without re-invoking the agent.
  - Cache invalidated when cardio_log.updated_at changes.
  - Concurrent requests dedupe via asyncio.Lock (agent invoked exactly once).
  - source="cardio_auto_insight" appears in agent input.
  - Cardio_log belonging to a different user → 403.
  - Returns 204 when insight is empty.

Per the project memory (feedback_testclient_httpx_skew.md), this test file
does NOT use fastapi.testclient — it calls the endpoint function directly
with mocked deps.
"""
from __future__ import annotations

import asyncio
from typing import Any, Dict, List, Optional
from unittest.mock import MagicMock, patch, AsyncMock

import pytest
from fastapi import HTTPException
from fastapi import Response as FastAPIResponse

from api.v1 import coach_insight_endpoints as ep


# ---------------------------------------------------------------------------
# Helpers / fakes
# ---------------------------------------------------------------------------
def _run(coro):
    return asyncio.get_event_loop().run_until_complete(coro)


class _Exec:
    def __init__(self, data):
        self.data = data


class _Q:
    def __init__(self, data):
        self._data = data

    def select(self, *a, **kw): return self
    def eq(self, *a, **kw): return self
    def limit(self, *a, **kw): return self
    def execute(self): return _Exec(self._data)


def _mk_db(row: Optional[Dict[str, Any]]):
    db = MagicMock()
    db.client.table = MagicMock(return_value=_Q([row] if row else []))
    return db


def _reset():
    ep._reset_cache_for_tests()


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------
def test_404_when_cardio_log_missing():
    _reset()
    with patch.object(ep, "get_supabase_db", return_value=_mk_db(None)):
        with pytest.raises(HTTPException) as exc:
            _run(ep.get_cardio_insight(
                cardio_log_id="nope",
                current_user={"id": "u1"},
            ))
    assert exc.value.status_code == 404


def test_403_when_different_user_owns_row():
    _reset()
    db = _mk_db({"id": "c1", "user_id": "OTHER", "updated_at": "2026-01-01"})
    with patch.object(ep, "get_supabase_db", return_value=db):
        with pytest.raises(HTTPException) as exc:
            _run(ep.get_cardio_insight(
                cardio_log_id="c1",
                current_user={"id": "u1"},
            ))
    assert exc.value.status_code == 403


def test_204_when_insight_is_empty():
    _reset()
    db = _mk_db({"id": "c1", "user_id": "u1", "updated_at": "2026-01-01"})

    async def fake_invoke(*, user_id, cardio_log_id):
        return ""

    with patch.object(ep, "get_supabase_db", return_value=db), \
         patch.object(ep, "_invoke_coach_for_insight", side_effect=fake_invoke):
        result = _run(ep.get_cardio_insight(
            cardio_log_id="c1",
            current_user={"id": "u1"},
        ))
    assert isinstance(result, FastAPIResponse)
    assert result.status_code == 204


def test_cache_hit_skips_agent_invocation():
    _reset()
    db = _mk_db({"id": "c1", "user_id": "u1", "updated_at": "2026-01-01T00:00:00Z"})
    calls = {"n": 0}

    async def fake_invoke(*, user_id, cardio_log_id):
        calls["n"] += 1
        return "Same route as last week, 7% faster."

    with patch.object(ep, "get_supabase_db", return_value=db), \
         patch.object(ep, "_invoke_coach_for_insight", side_effect=fake_invoke):
        r1 = _run(ep.get_cardio_insight(
            cardio_log_id="c1", current_user={"id": "u1"},
        ))
        r2 = _run(ep.get_cardio_insight(
            cardio_log_id="c1", current_user={"id": "u1"},
        ))

    assert r1["insight"] == r2["insight"]
    assert r1["cached"] is False
    assert r2["cached"] is True
    assert calls["n"] == 1


def test_cache_invalidated_on_updated_at_change():
    _reset()
    # First DB returns v1, then v2 with a different updated_at.
    state = {"current": {"id": "c1", "user_id": "u1",
                         "updated_at": "2026-01-01T00:00:00Z"}}

    def mk():
        d = MagicMock()
        d.client.table = MagicMock(return_value=_Q([state["current"]]))
        return d

    calls = {"n": 0}

    async def fake_invoke(*, user_id, cardio_log_id):
        calls["n"] += 1
        return f"insight-{calls['n']}"

    with patch.object(ep, "get_supabase_db", side_effect=lambda: mk()), \
         patch.object(ep, "_invoke_coach_for_insight", side_effect=fake_invoke):
        r1 = _run(ep.get_cardio_insight(
            cardio_log_id="c1", current_user={"id": "u1"},
        ))
        # Mutate the row's updated_at — should bust the cache.
        state["current"] = {"id": "c1", "user_id": "u1",
                            "updated_at": "2026-02-02T00:00:00Z"}
        r2 = _run(ep.get_cardio_insight(
            cardio_log_id="c1", current_user={"id": "u1"},
        ))
    assert r1["insight"] == "insight-1"
    assert r2["insight"] == "insight-2"
    assert calls["n"] == 2


def test_concurrent_requests_dedupe_via_lock():
    _reset()
    db_row = {"id": "c1", "user_id": "u1", "updated_at": "2026-01-01"}

    calls = {"n": 0}
    barrier = asyncio.Event()

    async def fake_invoke(*, user_id, cardio_log_id):
        calls["n"] += 1
        # Hold the first invocation long enough that the second request has
        # to wait on the asyncio.Lock — if dedupe is broken, the second
        # request invokes the agent a second time and the count goes to 2.
        await asyncio.sleep(0.05)
        barrier.set()
        return "Solid effort today."

    async def driver():
        with patch.object(ep, "get_supabase_db", return_value=_mk_db(db_row)), \
             patch.object(ep, "_invoke_coach_for_insight",
                          side_effect=fake_invoke):
            r1_task = asyncio.create_task(ep.get_cardio_insight(
                cardio_log_id="c1", current_user={"id": "u1"},
            ))
            r2_task = asyncio.create_task(ep.get_cardio_insight(
                cardio_log_id="c1", current_user={"id": "u1"},
            ))
            return await asyncio.gather(r1_task, r2_task)

    r1, r2 = asyncio.get_event_loop().run_until_complete(driver())

    assert r1["insight"] == r2["insight"]
    # Exactly one invocation across both concurrent requests.
    assert calls["n"] == 1
    # One served fresh, the other from cache.
    cached_flags = sorted([r1["cached"], r2["cached"]])
    assert cached_flags == [False, True]


def test_source_bias_cardio_auto_insight_reaches_agent():
    """When _invoke_coach_for_insight runs, it calls coach_response_node with
    state['source']=='cardio_auto_insight'. Patch the node and assert the
    state it received carries that source string."""
    _reset()
    captured: Dict[str, Any] = {}

    async def fake_node(state: Dict[str, Any]) -> Dict[str, Any]:
        captured.update(state)
        return {"final_response": "ok", "ai_response": "ok"}

    async def fake_cardio_ctx(**_kw):
        return "CARDIO (last 14d): 4 sessions, 22.0 km total."

    db = _mk_db({"id": "c1", "user_id": "u1", "updated_at": "2026-01-01"})

    with patch.object(ep, "get_supabase_db", return_value=db), \
         patch.object(ep, "get_cardio_context_for_ai",
                      side_effect=fake_cardio_ctx), \
         patch(
             "services.langgraph_agents.coach_agent.nodes.coach_response_node",
             side_effect=fake_node,
         ):
        result = _run(ep.get_cardio_insight(
            cardio_log_id="c1", current_user={"id": "u1"},
        ))

    assert result["insight"] == "ok"
    assert captured.get("source") == "cardio_auto_insight"
    assert captured.get("cardio_context", "").startswith("CARDIO")
