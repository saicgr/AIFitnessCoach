"""
Pytest for `POST /api/v1/equipment/snap`.

Covers the response shapes for: matched, low-confidence, not-equipment,
quota_exceeded (429), paywall (402). Vision + extractor + DB are mocked at
the module boundary; we test the endpoint coroutine directly to avoid
spinning the full FastAPI app (whose top-level imports require Python 3.10+
syntax that isn't compatible with this repo's 3.9 venv).

Run with:
    cd backend && .venv/bin/pytest tests/test_equipment_snap.py -v
"""
from __future__ import annotations

from datetime import datetime, timezone
from types import SimpleNamespace
from unittest.mock import AsyncMock, MagicMock, patch

import pytest


# Top-level helpers from the module under test ---------------------------
#
# IMPORTANT: we cannot do `from api.v1.equipment import snap` because the
# `api.v1` package __init__ imports `videos.py` which uses Python 3.10+ PEP 604
# `X | None` syntax. The local repo venv is pinned to 3.9 (the production runtime
# uses 3.10+). We sidestep that by loading `snap.py` directly via importlib.
import importlib.util as _il
import os as _os
import sys as _sys

# Stub the `core.auth.get_current_user` dependency that snap.py imports at
# module load time — the real one pulls Supabase clients we don't need here.
import types as _t
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
import logging as _logging
def _stub_get_logger(name): return _logging.getLogger(name)
_core_logger.get_logger = _stub_get_logger
_core_config = _t.ModuleType("core.config")
def _stub_get_settings():  # pragma: no cover
    return _t.SimpleNamespace(s3_bucket_name="b", aws_access_key_id="x",
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
_spec = _il.spec_from_file_location("snap_under_test", _SNAP_PATH)
snap_module = _il.module_from_spec(_spec)
_spec.loader.exec_module(snap_module)


def _fake_db(used_today: int = 0, tier: str = "premium"):
    """Minimal Supabase-client stand-in for the snap endpoint.

    The endpoint chains:
        db.client.table(X).select(Y).eq(...).gte(...).execute()  → count
        db.client.table('subscriptions').select(...).eq(...).limit(1).execute() → tier
        db.client.table('exercise_library_cleaned').select(...).or_(...).limit(...).execute()
        db.client.table('workout_set_logs')...
        db.client.table('snapped_equipment').insert({...}).execute()
    Everything is fluent-chained, so we return self until .execute() is called.
    """
    class _Q:
        def __init__(self, table_name):
            self._t = table_name
        def select(self, *a, **kw): return self
        def insert(self, *a, **kw):
            self._inserted = a[0] if a else None
            return self
        def eq(self, *a, **kw): return self
        def neq(self, *a, **kw): return self
        def gte(self, *a, **kw): return self
        def lt(self, *a, **kw): return self
        def or_(self, *a, **kw): return self
        def order(self, *a, **kw): return self
        def limit(self, *a, **kw): return self
        def range(self, *a, **kw): return self
        def execute(self):
            if self._t == "snapped_equipment":
                # If this is the quota-count path the endpoint reads .count
                return SimpleNamespace(count=used_today,
                                       data=[{"id": "snap-uuid-1"}])
            if self._t == "subscriptions":
                return SimpleNamespace(data=[{"tier": tier, "is_lifetime": False}])
            if self._t == "exercise_library_cleaned":
                return SimpleNamespace(data=[
                    {"id": "ex-1", "name": "Lat Pulldown",
                     "image_url": "https://x/y.jpg",
                     "primary_muscle": "lats", "secondary_muscles": ["biceps"],
                     "equipment": "lat pulldown machine",
                     "primary_equipment": "lat_pulldown"},
                    {"id": "ex-2", "name": "Wide-Grip Pulldown",
                     "image_url": None,
                     "primary_muscle": "lats", "secondary_muscles": [],
                     "equipment": "lat pulldown machine",
                     "primary_equipment": "lat_pulldown"},
                ])
            if self._t == "workout_set_logs":
                return SimpleNamespace(data=[{"exercise_id": "ex-1"}, {"exercise_id": "ex-1"}])
            return SimpleNamespace(data=[])

    class _Client:
        def table(self, name):
            return _Q(name)

    db = MagicMock()
    db.client = _Client()
    return db


@pytest.mark.asyncio
async def test_snap_matched_high_confidence():
    """Happy path: vision says gym_equipment, extractor finds canonical with
    high confidence, library returns matches, response is `matched=true`."""
    fake_image = MagicMock()
    fake_image.content_type = "image/jpeg"
    fake_image.read = AsyncMock(return_value=b"\xff\xd8\xff\xe0fakejpegbytes")

    with patch.object(snap_module, "get_supabase_db", return_value=_fake_db(used_today=2, tier="premium")), \
         patch.object(snap_module, "_upload_to_s3", new=AsyncMock(return_value="snapped_equipment/u1/abc.jpg")), \
         patch.object(snap_module, "_blur_faces", side_effect=lambda b: b), \
         patch.object(snap_module, "get_vision_service") as mock_vision_factory, \
         patch.object(snap_module, "GymEquipmentExtractor") as mock_extractor_cls:

        mock_vision = MagicMock()
        mock_vision.classify_media_content = AsyncMock(return_value="gym_equipment")
        mock_vision_factory.return_value = mock_vision

        mock_extractor = MagicMock()
        mock_extractor.classify_single_image = AsyncMock(return_value={
            "canonical": "lat_pulldown", "raw_name": "lat pulldown machine",
            "confidence": 0.92, "all_candidates": [],
        })
        mock_extractor_cls.return_value = mock_extractor

        resp = await snap_module.snap_equipment(
            request=MagicMock(),
            image=fake_image,
            mode="swap",
            workout_id=None,
            replacing_exercise_id=None,
            reuse_s3_key=None,
            current_user={"id": "11111111-1111-1111-1111-111111111111"},
        )

    assert resp.matched is True
    assert resp.equipment_canonical_name == "lat_pulldown"
    assert resp.confidence == 0.92
    assert resp.disambiguate is False
    assert len(resp.matches) == 2
    # The recently-used boost should put ex-1 first (2 logged sets vs 0).
    assert resp.matches[0]["id"] == "ex-1"
    assert resp.matches[0].get("badge") == "Recently used"


@pytest.mark.asyncio
async def test_snap_disambiguate_when_confidence_borderline():
    fake_image = MagicMock()
    fake_image.content_type = "image/jpeg"
    fake_image.read = AsyncMock(return_value=b"x" * 100)

    with patch.object(snap_module, "get_supabase_db", return_value=_fake_db(tier="premium")), \
         patch.object(snap_module, "_upload_to_s3", new=AsyncMock(return_value="k")), \
         patch.object(snap_module, "_blur_faces", side_effect=lambda b: b), \
         patch.object(snap_module, "get_vision_service") as mock_vision_factory, \
         patch.object(snap_module, "GymEquipmentExtractor") as mock_extractor_cls:

        mock_vision_factory.return_value = MagicMock(
            classify_media_content=AsyncMock(return_value="gym_equipment"))
        mock_extractor_cls.return_value = MagicMock(
            classify_single_image=AsyncMock(return_value={
                "canonical": "lat_pulldown", "raw_name": "lat pulldown",
                "confidence": 0.6, "all_candidates": [],
            }))

        resp = await snap_module.snap_equipment(
            request=MagicMock(), image=fake_image, mode="identify",
            workout_id=None, replacing_exercise_id=None, reuse_s3_key=None,
            current_user={"id": "u"},
        )

    assert resp.matched is True
    assert resp.disambiguate is True


@pytest.mark.asyncio
async def test_snap_not_equipment_returns_unmatched():
    fake_image = MagicMock()
    fake_image.content_type = "image/jpeg"
    fake_image.read = AsyncMock(return_value=b"x")

    with patch.object(snap_module, "get_supabase_db", return_value=_fake_db(tier="premium")), \
         patch.object(snap_module, "_upload_to_s3", new=AsyncMock(return_value="k")), \
         patch.object(snap_module, "_blur_faces", side_effect=lambda b: b), \
         patch.object(snap_module, "get_vision_service") as mock_vision_factory:

        mock_vision_factory.return_value = MagicMock(
            classify_media_content=AsyncMock(return_value="food_plate"))

        resp = await snap_module.snap_equipment(
            request=MagicMock(), image=fake_image, mode="identify",
            workout_id=None, replacing_exercise_id=None, reuse_s3_key=None,
            current_user={"id": "u"},
        )

    assert resp.matched is False
    assert resp.unmatched_reason == "not_equipment"
    assert resp.vision_label == "food_plate"


@pytest.mark.asyncio
async def test_snap_low_confidence_returns_unmatched():
    fake_image = MagicMock()
    fake_image.content_type = "image/jpeg"
    fake_image.read = AsyncMock(return_value=b"x")

    with patch.object(snap_module, "get_supabase_db", return_value=_fake_db(tier="premium")), \
         patch.object(snap_module, "_upload_to_s3", new=AsyncMock(return_value="k")), \
         patch.object(snap_module, "_blur_faces", side_effect=lambda b: b), \
         patch.object(snap_module, "get_vision_service") as mock_vision_factory, \
         patch.object(snap_module, "GymEquipmentExtractor") as mock_extractor_cls:

        mock_vision_factory.return_value = MagicMock(
            classify_media_content=AsyncMock(return_value="gym_equipment"))
        mock_extractor_cls.return_value = MagicMock(
            classify_single_image=AsyncMock(return_value={
                "canonical": "lat_pulldown", "raw_name": "lat pulldown",
                "confidence": 0.3, "all_candidates": [],
            }))

        resp = await snap_module.snap_equipment(
            request=MagicMock(), image=fake_image, mode="identify",
            workout_id=None, replacing_exercise_id=None, reuse_s3_key=None,
            current_user={"id": "u"},
        )

    assert resp.matched is False
    assert resp.unmatched_reason == "low_confidence"


@pytest.mark.asyncio
async def test_snap_paywall_for_free_tier_after_5():
    """Free tier with >=5 snaps in last 24h → 402."""
    from fastapi import HTTPException

    fake_image = MagicMock()
    fake_image.content_type = "image/jpeg"
    fake_image.read = AsyncMock(return_value=b"x")

    with patch.object(snap_module, "get_supabase_db", return_value=_fake_db(used_today=5, tier="free")):
        with pytest.raises(HTTPException) as ei:
            await snap_module.snap_equipment(
                request=MagicMock(), image=fake_image, mode="identify",
                workout_id=None, replacing_exercise_id=None, reuse_s3_key=None,
                current_user={"id": "u"},
            )

    assert ei.value.status_code == 402
    assert ei.value.detail["error"] == "paywall"


@pytest.mark.asyncio
async def test_snap_429_when_over_hard_quota():
    from fastapi import HTTPException

    fake_image = MagicMock()
    fake_image.content_type = "image/jpeg"
    fake_image.read = AsyncMock(return_value=b"x")

    with patch.object(snap_module, "get_supabase_db", return_value=_fake_db(used_today=50, tier="premium")):
        with pytest.raises(HTTPException) as ei:
            await snap_module.snap_equipment(
                request=MagicMock(), image=fake_image, mode="identify",
                workout_id=None, replacing_exercise_id=None, reuse_s3_key=None,
                current_user={"id": "u"},
            )

    assert ei.value.status_code == 429
    assert ei.value.detail["error"] == "quota_exceeded"
