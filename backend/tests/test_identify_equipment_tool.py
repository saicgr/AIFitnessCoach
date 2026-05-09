"""
Pytest for the Issue 2 LangGraph tool `identify_equipment(s3_key, user_id)`.

Mirrors the loader trick from `test_equipment_snap.py`: the local 3.9 venv
can't import `api.v1.__init__` (PEP 604 syntax in `videos.py`), so we load
`api/v1/equipment/snap.py` and `services/langgraph_agents/tools/equipment_tools.py`
directly via importlib.

Covers:
  • success path: matched + canonical → action='open_swap_or_add' with matches
  • empty matches: vision says gym_equipment but library lookup returns 0
  • not_equipment: vision classifier rejects → still success=True with
    empty matches and unmatched_reason='not_equipment'

Run:
    cd backend && .venv/bin/pytest tests/test_identify_equipment_tool.py -v
"""
from __future__ import annotations

import importlib.util as _il
import logging as _logging
import os as _os
import sys as _sys
import types as _t
from types import SimpleNamespace
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

# ── Stub the same `core.*` modules used by snap.py + the tool wrapper ──
_core = _t.ModuleType("core")
_core_auth = _t.ModuleType("core.auth")
async def _stub_get_current_user(*a, **kw):  # pragma: no cover
    return {"id": "u"}
_core_auth.get_current_user = _stub_get_current_user
_core_db = _t.ModuleType("core.db")
def _stub_get_supabase_db(*a, **kw):  # pragma: no cover
    return MagicMock()
_core_db.get_supabase_db = _stub_get_supabase_db
_core_logger = _t.ModuleType("core.logger")
def _stub_get_logger(name): return _logging.getLogger(name)
_core_logger.get_logger = _stub_get_logger
_core_config = _t.ModuleType("core.config")
def _stub_get_settings():  # pragma: no cover
    return SimpleNamespace(s3_bucket_name="b", aws_access_key_id="x",
                           aws_secret_access_key="y", aws_default_region="us-east-1")
_core_config.get_settings = _stub_get_settings

_services = _t.ModuleType("services")
_services_vision = _t.ModuleType("services.vision_service")
def _stub_get_vision_service():  # pragma: no cover
    return MagicMock()
_services_vision.get_vision_service = _stub_get_vision_service
_services_extr = _t.ModuleType("services.gym_equipment_extractor")
class _StubExtractor:  # pragma: no cover
    def __init__(self, *a, **kw): pass
_services_extr.GymEquipmentExtractor = _StubExtractor

for _m in (_core, _core_auth, _core_db, _core_logger, _core_config,
           _services, _services_vision, _services_extr):
    _sys.modules[_m.__name__] = _m

_HERE = _os.path.dirname(_os.path.dirname(_os.path.abspath(__file__)))
_SNAP_PATH = _os.path.join(_HERE, "api", "v1", "equipment", "snap.py")
_spec = _il.spec_from_file_location("snap_under_test_for_tool", _SNAP_PATH)
snap_module = _il.module_from_spec(_spec)
_spec.loader.exec_module(snap_module)

# Register snap_module as the importable path the tool uses, so the lazy
# `from api.v1.equipment.snap import equipment_snap_core` succeeds at the
# point the tool calls it.
_api_pkg = _t.ModuleType("api")
_api_v1 = _t.ModuleType("api.v1")
_api_v1_eq = _t.ModuleType("api.v1.equipment")
_api_v1_eq_snap = snap_module
_sys.modules["api"] = _api_pkg
_sys.modules["api.v1"] = _api_v1
_sys.modules["api.v1.equipment"] = _api_v1_eq
_sys.modules["api.v1.equipment.snap"] = _api_v1_eq_snap

_TOOL_PATH = _os.path.join(
    _HERE,
    "services",
    "langgraph_agents",
    "tools",
    "equipment_tools.py",
)
_tspec = _il.spec_from_file_location("equipment_tools_under_test", _TOOL_PATH)
equipment_tools = _il.module_from_spec(_tspec)
_tspec.loader.exec_module(equipment_tools)


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
            if self._t == "workout_set_logs":
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
