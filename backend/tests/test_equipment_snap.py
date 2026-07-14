"""
Pytest for `POST /api/v1/equipment/snap`.

Covers the response shapes for: matched, low-confidence, not-equipment,
quota_exceeded (429), paywall (402). Vision + extractor + DB are mocked at
the module boundary; we test the endpoint coroutine directly rather than
going through the HTTP layer, so the auth/quota/vision seams stay explicit.

Run with:
    cd backend && .venv312/bin/pytest tests/test_equipment_snap.py -v
"""
from __future__ import annotations

from types import SimpleNamespace
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

# The module under test, imported normally.
#
# This file used to importlib-load snap.py from its path after shoving stub
# `core.*` / `services.*` modules into sys.modules, to dodge Python 3.9's
# inability to parse PEP 604 `X | None` in api/v1/videos.py. That workaround is
# obsolete — tests/conftest.py already does `from main import app`, so the whole
# suite requires 3.10+ (prod runs 3.11) — and it was ACTIVELY CORRUPTING other
# tests: writing to sys.modules at import time replaced the real `core` and
# `services` packages process-wide for every test module imported afterwards,
# so unrelated files died with "module 'services' has no attribute ...".
# Never mutate sys.modules at import time in a test module.
import api.v1.equipment.snap as snap_module


def _fake_db(used_today: int = 0, tier: str = "premium"):
    """Minimal Supabase-client stand-in for the snap endpoint.

    The endpoint chains:
        db.client.table(X).select(Y).eq(...).gte(...).execute()  → count
        db.client.table('subscriptions').select(...).eq(...).limit(1).execute() → tier
        db.client.table('exercise_library_cleaned').select(...).or_(...).limit(...).execute()
        db.client.table('performance_logs')...
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
            # Production reranks from performance_logs (snap.py:283 — "Per-set
            # history lives in performance_logs"). NOTE: `workout_set_logs` does
            # not exist in the schema — the old fake stubbed a dead table, so the
            # recently-used boost silently never fired and this fixture was
            # asserting against a table production has never read.
            if self._t == "performance_logs":
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


# ---------------------------------------------------------------------------
# Quota / paywall denial paths.
#
# ⚠️  `_upload_to_s3` and `_blur_faces` MUST be patched in these two tests even
# though a *correctly ordered* endpoint would never reach them. Reason: with the
# stub `core.config` gone, `get_settings()` inside `_upload_to_s3` reads the real
# `.env` off disk (core/config.py:262 sets `env_file = ".env"`), so it picks up
# live AWS credentials and PUTs to the PRODUCTION bucket from a test run.
#
# That is not hypothetical — it is REAL BUG 3 (see the run report): production
# `snap_equipment` blurs and uploads at snap.py:522-523 and only *then* calls
# `equipment_snap_core`, whose first act is `_check_quota_and_tier`
# (snap.py:339). So a denied (402/429) request still burns an S3 PutObject and
# persists a photo of a user who was refused. An un-patched run of this file
# demonstrably wrote objects into `s3://ai-fitness-coach/snapped_equipment/`.
#
# Once snap.py is reordered to check quota BEFORE the upload branch, add this
# strictly-stronger guarantee to both tests (it fails today, which is the point):
#     mock_upload.assert_not_awaited()
# Not added yet only because api/v1/equipment/snap.py is outside this change's
# ownership and the reorder is a product call (are denied snaps still stored?).
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_snap_paywall_for_free_tier_after_5():
    """Free tier with >=5 snaps in last 24h → 402."""
    from fastapi import HTTPException

    fake_image = MagicMock()
    fake_image.content_type = "image/jpeg"
    fake_image.read = AsyncMock(return_value=b"x")

    with patch.object(snap_module, "get_supabase_db", return_value=_fake_db(used_today=5, tier="free")), \
         patch.object(snap_module, "_upload_to_s3", new=AsyncMock(return_value="k")) as mock_upload, \
         patch.object(snap_module, "_blur_faces", side_effect=lambda b: b):
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

    with patch.object(snap_module, "get_supabase_db", return_value=_fake_db(used_today=50, tier="premium")), \
         patch.object(snap_module, "_upload_to_s3", new=AsyncMock(return_value="k")) as mock_upload, \
         patch.object(snap_module, "_blur_faces", side_effect=lambda b: b):
        with pytest.raises(HTTPException) as ei:
            await snap_module.snap_equipment(
                request=MagicMock(), image=fake_image, mode="identify",
                workout_id=None, replacing_exercise_id=None, reuse_s3_key=None,
                current_user={"id": "u"},
            )

    assert ei.value.status_code == 429
    assert ei.value.detail["error"] == "quota_exceeded"
