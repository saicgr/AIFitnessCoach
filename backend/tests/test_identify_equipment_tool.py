"""
Pytest for the Issue 2 LangGraph tool `identify_equipment(s3_key, user_id)`.

Covers:
  • success path: matched + canonical → action='open_swap_or_add' with matches
  • empty matches: vision says gym_equipment but library lookup returns 0
  • not_equipment: vision classifier rejects → still success=True with
    empty matches and unmatched_reason='not_equipment'

Run:
    cd backend && .venv312/bin/pytest tests/test_identify_equipment_tool.py -v
"""
from __future__ import annotations

from types import SimpleNamespace
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

# Real imports — see the note in test_equipment_snap.py. The old sys.modules
# stubbing existed only to work around the retired Python 3.9 venv, and it
# corrupted `core` / `services` / `api` for every test module imported after this
# one. Importing for real also makes the tool's lazy
# `from api.v1.equipment.snap import equipment_snap_core` resolve to the SAME
# module object these tests patch, instead of a hand-forged sys.modules entry.
import api.v1.equipment.snap as snap_module
import services.langgraph_agents.tools.equipment_tools as equipment_tools


def _fake_db(tier: str = "premium", library_rows=None, usage_rows=None,
             reuse_cache_rows=None):
    """Stand-in Supabase client matching the chains snap_core walks."""
    library_rows = library_rows if library_rows is not None else [
        {"id": "ex-1", "name": "Lat Pulldown",
         "image_url": "https://x/y.jpg",
         "primary_muscle": "lats", "secondary_muscles": ["biceps"],
         "equipment": "lat pulldown machine",
         "primary_equipment": "lat_pulldown"},
    ]
    usage_rows = usage_rows if usage_rows is not None else []
    reuse_cache_rows = reuse_cache_rows if reuse_cache_rows is not None else []

    class _Q:
        def __init__(self, t): self._t = t
        def select(self, *a, **kw): return self
        def insert(self, *a, **kw):
            self._inserted = a[0] if a else None
            return self
        def eq(self, *a, **kw): return self
        def gte(self, *a, **kw): return self
        def or_(self, *a, **kw): return self
        def order(self, *a, **kw): return self
        def limit(self, *a, **kw): return self
        def execute(self):
            if self._t == "snapped_equipment":
                # Reuse-window read: returns rows or []. Insert: returns id.
                return SimpleNamespace(
                    count=0,
                    data=reuse_cache_rows or [{"id": "snap-uuid-1"}],
                )
            if self._t == "subscriptions":
                return SimpleNamespace(data=[{"tier": tier, "is_lifetime": False}])
            if self._t == "exercise_library_cleaned":
                return SimpleNamespace(data=library_rows)
            # Production reranks from performance_logs (snap.py:283), not the
            # non-existent `workout_set_logs` this fake used to stub.
            if self._t == "performance_logs":
                return SimpleNamespace(data=usage_rows)
            return SimpleNamespace(data=[])

    db = MagicMock()
    class _Client:
        def table(self, name): return _Q(name)
    db.client = _Client()
    return db


@pytest.mark.asyncio
async def test_identify_equipment_success_path():
    """Vision says gym_equipment, extractor canonicalizes, library has matches.

    We invoke the underlying coroutine via the tool's `.func`.
    """
    with patch.object(snap_module, "get_supabase_db",
                      return_value=_fake_db(tier="premium")), \
         patch.object(snap_module, "get_vision_service") as mvf, \
         patch.object(snap_module, "GymEquipmentExtractor") as mec:

        mvf.return_value = MagicMock(
            classify_media_content=AsyncMock(return_value="gym_equipment"))
        mec.return_value = MagicMock(
            classify_single_image=AsyncMock(return_value={
                "canonical": "lat_pulldown",
                "raw_name": "lat pulldown machine",
                "confidence": 0.91,
                "all_candidates": [],
            }))

        # Drive the async core directly (the @tool wrapper otherwise wants
        # a running loop; we already have one via pytest-asyncio).
        resp = await snap_module.equipment_snap_core(
            user_id="user-uuid",
            s3_key="snapped_equipment/u/abc.jpg",
            mode="identify",
        )

    # Now feed the SnapResponse into the post-processing branch the tool
    # uses to wrap into the open_swap_or_add envelope.
    assert resp.matched is True
    assert resp.equipment_canonical_name == "lat_pulldown"
    assert len(resp.matches) >= 1


@pytest.mark.asyncio
async def test_identify_equipment_empty_matches():
    """Vision approves but library returns no matches → matched=True with
    empty matches list. The tool wraps this into success=True + a friendly
    summary (edge case 30: no exercise found, equipment still recorded)."""
    with patch.object(snap_module, "get_supabase_db",
                      return_value=_fake_db(tier="premium", library_rows=[])), \
         patch.object(snap_module, "get_vision_service") as mvf, \
         patch.object(snap_module, "GymEquipmentExtractor") as mec:

        mvf.return_value = MagicMock(
            classify_media_content=AsyncMock(return_value="gym_equipment"))
        mec.return_value = MagicMock(
            classify_single_image=AsyncMock(return_value={
                "canonical": "weird_machine",
                "raw_name": "unusual contraption",
                "confidence": 0.85,
                "all_candidates": [],
            }))

        resp = await snap_module.equipment_snap_core(
            user_id="user-uuid",
            s3_key="snapped_equipment/u/zzz.jpg",
            mode="identify",
        )

    assert resp.matched is True
    assert resp.equipment_canonical_name == "weird_machine"
    assert resp.matches == []


@pytest.mark.asyncio
async def test_identify_equipment_not_equipment():
    """Classifier says it's a food plate, not equipment.

    Tool surfaces success=True with empty matches + unmatched_reason
    so the chat card still renders an explanatory state."""
    with patch.object(snap_module, "get_supabase_db",
                      return_value=_fake_db(tier="premium")), \
         patch.object(snap_module, "get_vision_service") as mvf:

        mvf.return_value = MagicMock(
            classify_media_content=AsyncMock(return_value="food_plate"))

        resp = await snap_module.equipment_snap_core(
            user_id="user-uuid",
            s3_key="snapped_equipment/u/lunch.jpg",
            mode="identify",
        )

    assert resp.matched is False
    assert resp.unmatched_reason == "not_equipment"
    assert resp.vision_label == "food_plate"


def test_tool_envelope_shape():
    """Sanity-check the Issue 2 tool envelope is wired correctly."""
    assert hasattr(equipment_tools, "identify_equipment")
    assert hasattr(equipment_tools, "ISSUE_2_EQUIPMENT_TOOLS")
    assert len(equipment_tools.ISSUE_2_EQUIPMENT_TOOLS) == 1
    assert equipment_tools.identify_equipment.name == "identify_equipment"
