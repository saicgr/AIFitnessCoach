"""Phase A — `select_exercises_with_fallback` cascade smoke tests.

These tests use mock-patches to drive the cascade through each tier
without a live DB. Verify that:
  - Tier 0 returns when primary RAG hits the floor.
  - Tier 1 (over-fetch) kicks in when tier 0 is short.
  - Tier 2 (curated alternatives) kicks in when tier 1 is still short.
  - Tier 3 (drop focus) is the last RAG attempt before safety_mode.
  - Tier 5 (safety_mode pool) fires only when everything above failed.
  - Cascade NEVER returns < min_floor and NEVER raises.
"""
import asyncio
from typing import List, Dict, Any
from unittest.mock import patch, AsyncMock

import pytest


def _make_exs(prefix: str, n: int) -> List[Dict[str, Any]]:
    return [{"name": f"{prefix}_{i}", "exercise_id": f"id_{prefix}_{i}"} for i in range(n)]


def _run(coro):
    loop = asyncio.new_event_loop()
    try:
        return loop.run_until_complete(coro)
    finally:
        loop.close()


@pytest.fixture
def svc():
    """Bypass the singleton + ChromaDB init by constructing manually."""
    from services.exercise_rag.service import ExerciseRAGService
    inst = ExerciseRAGService.__new__(ExerciseRAGService)  # skip __init__
    return inst


def test_tier0_passes_through_when_floor_met(svc):
    """If primary RAG returns ≥ min_floor, no further tiers fire."""
    primary = _make_exs("primary", 6)
    with patch.object(svc, "select_exercises_for_workout", new=AsyncMock(return_value=primary)) as m:
        out, tier = _run(svc.select_exercises_with_fallback(
            focus_area="push", equipment=[], fitness_level="intermediate",
            goals=[], count=6, injuries=["shoulder"], min_floor=4,
        ))
    assert tier == "rag_primary"
    assert len(out) >= 4
    # Should have only called once.
    assert m.await_count == 1


def test_tier1_overfetch_fires_when_tier0_short(svc):
    """Tier 0 returns 1 → tier 1 (count*4 + no avoid) returns 5 more."""
    calls: List[Dict] = []

    async def fake_select(**kwargs):
        calls.append(kwargs)
        if len(calls) == 1:
            return _make_exs("tier0", 1)
        return _make_exs("tier1", 5)

    with patch.object(svc, "select_exercises_for_workout", new=AsyncMock(side_effect=fake_select)):
        out, tier = _run(svc.select_exercises_with_fallback(
            focus_area="push", equipment=[], fitness_level="intermediate",
            goals=[], count=4, injuries=["shoulder"], min_floor=4,
        ))
    assert tier == "rag_overfetch"
    assert len(out) >= 4
    # Tier 1 must request count * 4 (= 16) and avoid_exercises=None.
    assert calls[1]["count"] == 16
    assert calls[1]["avoid_exercises"] is None


def test_tier2_curated_alternatives(svc):
    """Tier 0+1 both short → tier 2 hits the curated map and returns alts."""
    async def empty_rag(**_kw):
        return []

    curated_alts = _make_exs("curated", 5)
    with patch.object(svc, "select_exercises_for_workout", new=AsyncMock(side_effect=empty_rag)), \
         patch.object(svc, "_fetch_by_name_substrings", new=AsyncMock(return_value=curated_alts)):
        out, tier = _run(svc.select_exercises_with_fallback(
            focus_area="push", equipment=[], fitness_level="intermediate",
            goals=[], count=4, injuries=["shoulder"], min_floor=4,
        ))
    assert tier == "curated_alternatives"
    assert len(out) >= 4


def test_tier3_drops_focus(svc):
    """Tier 0/1/2 all short → tier 3 re-queries with focus_area='full_body'."""
    seen_focuses = []

    async def by_focus(focus_area, **_kw):
        seen_focuses.append(focus_area)
        if focus_area == "full_body":
            return _make_exs("fullbody", 5)
        return []

    with patch.object(svc, "select_exercises_for_workout", new=AsyncMock(side_effect=by_focus)), \
         patch.object(svc, "_fetch_by_name_substrings", new=AsyncMock(return_value=[])):
        out, tier = _run(svc.select_exercises_with_fallback(
            focus_area="legs", equipment=[], fitness_level="intermediate",
            goals=[], count=4, injuries=["knee"], min_floor=4,
        ))
    assert tier == "rag_no_focus"
    assert len(out) >= 4
    # Tier 3 always falls back to "full_body".
    assert "full_body" in seen_focuses


def test_tier5_safety_mode_fires_when_everything_else_empty(svc):
    """Last resort — safety_mode pool always works."""
    async def empty_rag(**_kw):
        return []

    safety_plan = {"exercises": _make_exs("safety", 6)}

    async def fake_safety_plan(**_kw):
        return safety_plan

    with patch.object(svc, "select_exercises_for_workout", new=AsyncMock(side_effect=empty_rag)), \
         patch.object(svc, "_fetch_by_name_substrings", new=AsyncMock(return_value=[])), \
         patch("services.exercise_rag.safety_mode.build_plan", new=AsyncMock(side_effect=fake_safety_plan)):
        out, tier = _run(svc.select_exercises_with_fallback(
            focus_area="push", equipment=[], fitness_level="intermediate",
            goals=[], count=4, injuries=["shoulder", "wrist", "elbow"], min_floor=4,
        ))
    assert tier == "safety_mode_fallback"
    assert len(out) >= 4


def test_cascade_never_raises_on_inner_exception(svc):
    """If any inner tier raises, cascade swallows + falls through."""
    async def boom(**_kw):
        raise RuntimeError("simulated DB outage")

    safety_plan = {"exercises": _make_exs("safety", 4)}
    with patch.object(svc, "select_exercises_for_workout", new=AsyncMock(side_effect=boom)), \
         patch.object(svc, "_fetch_by_name_substrings", new=AsyncMock(side_effect=boom)), \
         patch("services.exercise_rag.safety_mode.build_plan",
               new=AsyncMock(return_value=safety_plan)):
        out, tier = _run(svc.select_exercises_with_fallback(
            focus_area="push", equipment=[], fitness_level="intermediate",
            goals=[], count=4, injuries=["shoulder"], min_floor=4,
        ))
    assert tier == "safety_mode_fallback"
    assert len(out) >= 4


def test_cascade_with_no_injuries_skips_tier2(svc):
    """No injury list → curated alternatives lookup skipped (would return [])."""
    primary = _make_exs("primary", 6)
    fetch_subs_mock = AsyncMock(return_value=[])
    with patch.object(svc, "select_exercises_for_workout", new=AsyncMock(return_value=primary)), \
         patch.object(svc, "_fetch_by_name_substrings", new=fetch_subs_mock):
        out, tier = _run(svc.select_exercises_with_fallback(
            focus_area="push", equipment=[], fitness_level="intermediate",
            goals=[], count=6, injuries=None, min_floor=4,
        ))
    assert tier == "rag_primary"
    fetch_subs_mock.assert_not_called()
