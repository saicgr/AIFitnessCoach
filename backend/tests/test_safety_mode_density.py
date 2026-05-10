"""Phase H — `safety_mode.build_plan` exercise count must scale with capped duration.

Sweep idx 21/22/31/269 had 6 exercises crammed into 15-min sessions
(density 2.5 < 4). This pins the new duration-bucketed formula.
"""
import asyncio
from typing import List, Dict, Any
from unittest.mock import patch

import pytest


def _row(name: str, pattern: str = "mobility") -> Dict[str, Any]:
    return {
        "exercise_id": f"id_{name}",
        "name": name,
        "name_normalized": name.lower(),
        "body_part": "core",
        "target_muscle": "abs",
        "equipment": "bodyweight",
        "movement_pattern": pattern,
        "safety_difficulty": "beginner",
        "is_beginner_safe": True,
        "gif_url": None, "video_url": None, "image_url": None,
        "instructions": "demo",
    }


_FAKE_ROWS: List[Dict[str, Any]] = [
    _row(f"ex{i}", "mobility" if i % 2 == 0 else "isometric")
    for i in range(15)
]


class _FakeResult:
    def fetchall(self):
        class _R:
            def __init__(self, m): self._mapping = m
        return [_R(r) for r in _FAKE_ROWS]


class _FakeConn:
    async def __aenter__(self): return self
    async def __aexit__(self, *a): return None
    async def execute(self, *a, **kw): return _FakeResult()


class _FakeEng:
    def connect(self): return _FakeConn()


def _run(coro):
    loop = asyncio.new_event_loop()
    try:
        return loop.run_until_complete(coro)
    finally:
        loop.close()


@pytest.mark.parametrize("requested,expected_count", [
    (5, 3),    # capped=5  → ≤10 → 3
    (10, 3),   # capped=10 → ≤10 → 3
    (15, 4),   # capped=15 → ≤15 → 4
    (20, 5),   # capped=20 → ≤20 → 5
    # Anything > MAX_SAFETY_MODE_MINUTES (20) is capped down to 20, so count
    # stays at 5 — NOT 6. The "> 20 → 6" branch is unreachable in practice
    # and is kept only for defensive symmetry. This is the correct, safe
    # behavior: no surprise 6-exercise mobility for a 60-min request.
    (45, 5),
    (60, 5),
])
def test_density_scales_with_duration(requested, expected_count):
    from services.exercise_rag.safety_mode import build_plan
    from services.workout_safety_validator import UserSafetyContext

    async def _go():
        with patch("services.exercise_rag.safety_mode._get_engine", return_value=_FakeEng()):
            ctx = UserSafetyContext(
                injuries=[], difficulty="easy", equipment=[], user_id="t",
            )
            return await build_plan(ctx, duration_minutes=requested, focus_areas=["mobility"])

    plan = _run(_go())
    assert plan["difficulty"] == "easy"
    # MAX_SAFETY_MODE_MINUTES caps at 20 internally, so requested>20 still
    # routes to expected_count for the 20-min bucket (6).
    assert len(plan["exercises"]) == expected_count, (
        f"requested={requested} expected={expected_count} "
        f"got={len(plan['exercises'])}"
    )


def test_static_fallback_when_db_returns_empty():
    """If DB query returns no rows, static fallback list is used."""
    from services.exercise_rag.safety_mode import build_plan, _LAST_RESORT_EXERCISES
    from services.workout_safety_validator import UserSafetyContext

    class _EmptyResult:
        def fetchall(self): return []

    class _EmptyConn:
        async def __aenter__(self): return self
        async def __aexit__(self, *a): return None
        async def execute(self, *a, **kw): return _EmptyResult()

    class _EmptyEng:
        def connect(self): return _EmptyConn()

    async def _go():
        with patch("services.exercise_rag.safety_mode._get_engine", return_value=_EmptyEng()):
            ctx = UserSafetyContext(
                injuries=["knee"], difficulty="easy", equipment=[], user_id="t",
            )
            return await build_plan(ctx, duration_minutes=15, focus_areas=["mobility"])

    plan = _run(_go())
    # Static fallback gives all _LAST_RESORT_EXERCISES; difficulty stays "easy".
    assert plan["difficulty"] == "easy"
    assert len(plan["exercises"]) == len(_LAST_RESORT_EXERCISES)


def test_ai_prompt_keyword_bias_extracts_body_parts():
    """Phase C bias — 'phase 1 PT post-op knee' should add 'knee' to fa."""
    from services.exercise_rag import safety_mode

    captured: Dict[str, Any] = {}

    class _CapturingResult:
        def fetchall(self): return [type("_R", (), {"_mapping": _FAKE_ROWS[0]})()]

    class _CapturingConn:
        async def __aenter__(self): return self
        async def __aexit__(self, *a): return None
        async def execute(self, sql, params=None):
            captured["params"] = params
            return _CapturingResult()

    class _CapturingEng:
        def connect(self): return _CapturingConn()

    from services.workout_safety_validator import UserSafetyContext

    async def _go():
        with patch.object(safety_mode, "_get_engine", return_value=_CapturingEng()):
            ctx = UserSafetyContext(
                injuries=[], difficulty="easy", equipment=[], user_id="t",
            )
            return await safety_mode.build_plan(
                ctx, duration_minutes=15,
                focus_areas=None,
                ai_prompt="phase 1 PT post-op knee",
            )

    _run(_go())
    fa = captured.get("params", {}).get("fa") or []
    assert "knee" in fa, f"expected ai_prompt keyword 'knee' in fa params; got {fa}"
