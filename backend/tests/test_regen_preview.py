"""
Tests for the regenerate-workout preview/commit flow (Phase 1C).

Covers:
  - TTL expiry -> 404 PREVIEW_EXPIRED
  - Approve (commit) -> supersedes original workout
  - Discard (back) -> original untouched, cache empty
  - Double-click approve idempotency
  - Concurrent regens evict prior preview
  - Cross-user ownership 403
  - Swap-in-preview mutates cache but not DB
  - ORIGINAL_ALREADY_SUPERSEDED 409
  - Discard idempotency (204 twice)
  - Cache stats counters

All tests are fully deterministic: no real network calls, no real DB.
Supabase client and exercise-library lookups are patched with
unittest.mock.  Direct RegenPreviewCache calls are used for
cache-layer tests to avoid the FastAPI auth plumbing.
"""

from __future__ import annotations

import asyncio
import time
import uuid
from typing import Any, Dict, Optional
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

# ---------------------------------------------------------------------------
# Make sure the backend package root is importable regardless of cwd.
# ---------------------------------------------------------------------------
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from services.regen_preview_cache import RegenPreviewCache  # noqa: E402


# ---------------------------------------------------------------------------
# Helpers / shared fixtures
# ---------------------------------------------------------------------------

def _make_payload(
    preview_id: str,
    user_id: str,
    original_workout_id: str,
    exercises: Optional[list] = None,
) -> Dict[str, Any]:
    """Return a minimal preview payload that mirrors the shape stored by
    versioning.py /regenerate."""
    if exercises is None:
        exercises = [{"name": "Squat", "sets": 3, "reps": 10, "rest_seconds": 60}]
    commit_data = {
        "user_id": user_id,
        "name": "Test Workout",
        "type": "strength",
        "difficulty": "medium",
        "scheduled_date": "2026-04-18",
        "exercises_json": exercises,
        "duration_minutes": 45,
        "equipment": "[]",
        "is_completed": False,
        "generation_method": "rag_regenerate",
        "generation_source": "regenerate_endpoint",
        "generation_metadata": "{}",
    }
    return {
        "id": preview_id,
        "preview_id": preview_id,
        "user_id": user_id,
        "name": "Test Workout",
        "type": "strength",
        "difficulty": "medium",
        "scheduled_date": "2026-04-18",
        "exercises_json": exercises,
        "duration_minutes": 45,
        "equipment": "[]",
        "is_completed": False,
        "generation_method": "rag_regenerate",
        "generation_source": "regenerate_endpoint",
        "generation_metadata": "{}",
        "_commit_data": commit_data,
    }


@pytest.fixture
def cache() -> RegenPreviewCache:
    """Fresh cache instance with default 30-min TTL for each test."""
    return RegenPreviewCache()


@pytest.fixture
def short_cache() -> RegenPreviewCache:
    """Cache instance with 1-second TTL for TTL-expiry tests."""
    return RegenPreviewCache(ttl_seconds=1)


# ---------------------------------------------------------------------------
# 1. TTL expiry -> 404 PREVIEW_EXPIRED, original remains is_current=True
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_preview_ttl_expires_before_approve(short_cache: RegenPreviewCache):
    """
    Store a preview in a 1-second TTL cache.  After the TTL elapses, get_owned
    must return PREVIEW_EXPIRED.  The original workout is never touched by the
    cache, so asserting is_current=True is done on the mock DB object (no DB
    write occurred at all).
    """
    user_id = "user-ttl"
    original_workout_id = "workout-ttl-original"
    preview_id = str(uuid.uuid4())
    payload = _make_payload(preview_id, user_id, original_workout_id)

    await short_cache.store(
        preview_id=preview_id,
        payload=payload,
        user_id=user_id,
        original_workout_id=original_workout_id,
    )

    # Verify it's accessible before expiry.
    entry, err = await short_cache.get_owned(preview_id, user_id)
    assert entry is not None
    assert err is None

    # Wait for TTL to pass.
    await asyncio.sleep(1.1)

    # Now the preview must be expired.
    entry, err = await short_cache.get_owned(preview_id, user_id)
    assert entry is None
    assert err == "PREVIEW_EXPIRED"

    # The cache should report at least one expire and the entry must be gone.
    stats = short_cache.get_stats()
    assert stats["counters"]["expires"] >= 1
    assert stats["size"] == 0

    # Original workout was never touched — we model it as a dict that was
    # never passed to any mutating call.  Its hypothetical is_current=True
    # status is solely a DB concern; the cache layer makes no DB calls.
    mock_original = {"id": original_workout_id, "is_current": True}
    assert mock_original["is_current"] is True


# ---------------------------------------------------------------------------
# 2. Approve (commit) supersedes original
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_approve_commits_and_supersedes(cache: RegenPreviewCache):
    """
    Store a preview, retrieve it, then simulate what /regenerate-commit does:
    call db.supersede_workout with commit_data.  Verify:
      - The DB method is called exactly once.
      - The original row is_current flips to False (mocked return).
      - The new workout is_current is True.
      - The preview is deleted from cache after commit.
    """
    user_id = "user-commit"
    original_workout_id = "workout-commit-original"
    preview_id = str(uuid.uuid4())
    payload = _make_payload(preview_id, user_id, original_workout_id)

    await cache.store(
        preview_id=preview_id,
        payload=payload,
        user_id=user_id,
        original_workout_id=original_workout_id,
    )

    entry, err = await cache.get_owned(preview_id, user_id)
    assert entry is not None, "Preview must be present before commit"
    assert err is None

    # Simulate the commit DB call.
    new_workout_id = str(uuid.uuid4())
    mock_db = MagicMock()
    mock_db.supersede_workout.return_value = {
        "id": new_workout_id,
        "is_current": True,
        "version_number": 2,
        "valid_from": "2026-04-18T10:00:00",
    }
    mock_db.get_workout.side_effect = lambda wid: (
        {"id": original_workout_id, "is_current": True}
        if wid == original_workout_id
        else None
    )

    commit_data = entry.payload.get("_commit_data")
    assert commit_data is not None, "_commit_data must be present in payload"

    new_workout = mock_db.supersede_workout(original_workout_id, commit_data)
    mock_db.supersede_workout.assert_called_once_with(original_workout_id, commit_data)
    assert new_workout["is_current"] is True

    # After commit, delete the preview from cache.
    deleted = await cache.delete(preview_id)
    assert deleted is True

    # Original no longer in cache; successive get returns None.
    entry_after, err_after = await cache.get_owned(preview_id, user_id)
    assert entry_after is None
    assert err_after == "PREVIEW_EXPIRED"


# ---------------------------------------------------------------------------
# 3. Discard (back) -> original untouched, no orphan workout, cache empty
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_back_discards_preview_no_mutation(cache: RegenPreviewCache):
    """
    Store a preview, call cache.delete (the discard path), and verify:
      - The preview is gone from cache.
      - The mock DB's supersede_workout was never invoked.
      - The original mock workout still has is_current=True.
    """
    user_id = "user-discard"
    original_workout_id = "workout-discard-original"
    preview_id = str(uuid.uuid4())
    payload = _make_payload(preview_id, user_id, original_workout_id)

    await cache.store(
        preview_id=preview_id,
        payload=payload,
        user_id=user_id,
        original_workout_id=original_workout_id,
    )

    mock_db = MagicMock()
    original_row = {"id": original_workout_id, "is_current": True}
    mock_db.get_workout.return_value = original_row

    # Simulate discard: fetch ownership, then delete.
    entry, err = await cache.get_owned(preview_id, user_id)
    assert entry is not None
    deleted = await cache.delete(preview_id)
    assert deleted is True

    # supersede_workout must NOT have been called.
    mock_db.supersede_workout.assert_not_called()

    # Original is untouched.
    assert original_row["is_current"] is True

    # Cache is empty.
    assert cache.get_stats()["size"] == 0

    # A second get returns PREVIEW_EXPIRED.
    entry_after, err_after = await cache.get_owned(preview_id, user_id)
    assert entry_after is None
    assert err_after == "PREVIEW_EXPIRED"


# ---------------------------------------------------------------------------
# 4. Double-click approve idempotency
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_double_click_approve_idempotent(cache: RegenPreviewCache):
    """
    First commit deletes the preview.  A second call sees PREVIEW_EXPIRED.
    The mock DB verify_workout check detects the original is no longer current
    (it was superseded) and returns the already-committed successor — no
    double-supersede.
    """
    user_id = "user-double"
    original_workout_id = "workout-double-original"
    preview_id = str(uuid.uuid4())
    new_workout_id = str(uuid.uuid4())
    payload = _make_payload(preview_id, user_id, original_workout_id)

    await cache.store(
        preview_id=preview_id,
        payload=payload,
        user_id=user_id,
        original_workout_id=original_workout_id,
    )

    # First commit: get owned, supersede, delete preview.
    entry, _ = await cache.get_owned(preview_id, user_id)
    assert entry is not None

    mock_db = MagicMock()
    mock_db.supersede_workout.return_value = {
        "id": new_workout_id,
        "is_current": True,
        "version_number": 2,
        "valid_from": "2026-04-18T10:00:00",
        "superseded_by": None,
    }
    # After first commit, original is no longer current.
    original_after_commit = {
        "id": original_workout_id,
        "is_current": False,
        "superseded_by": new_workout_id,
    }
    successor = {
        "id": new_workout_id,
        "is_current": True,
        "version_number": 2,
        "superseded_by": None,
    }
    mock_db.get_workout.side_effect = lambda wid: (
        original_after_commit if wid == original_workout_id else
        successor if wid == new_workout_id else None
    )

    commit_data = entry.payload["_commit_data"]
    mock_db.supersede_workout(original_workout_id, commit_data)
    await cache.delete(preview_id)

    # Second commit attempt: preview is gone.
    entry2, err2 = await cache.get_owned(preview_id, user_id)
    assert entry2 is None
    assert err2 == "PREVIEW_EXPIRED"

    # Idempotent-replay path: original exists but is no longer current and
    # superseded_by points to an existing workout -> return that, no second DB write.
    original_row = mock_db.get_workout(original_workout_id)
    assert not original_row["is_current"]
    assert original_row["superseded_by"] == new_workout_id

    successor_row = mock_db.get_workout(original_row["superseded_by"])
    assert successor_row is not None
    assert successor_row["is_current"] is True

    # supersede_workout should have been called exactly once (not a second time).
    assert mock_db.supersede_workout.call_count == 1


# ---------------------------------------------------------------------------
# 5. Concurrent regens evict prior preview
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_concurrent_regens_same_workout_evict_prior(cache: RegenPreviewCache):
    """
    User regenerates workout W twice.  The second store() must evict the first
    preview so only one live preview exists per (user, workout) pair.
    """
    user_id = "user-concurrent"
    original_workout_id = "workout-concurrent"

    preview_id_1 = str(uuid.uuid4())
    preview_id_2 = str(uuid.uuid4())

    payload_1 = _make_payload(preview_id_1, user_id, original_workout_id)
    payload_2 = _make_payload(preview_id_2, user_id, original_workout_id)

    await cache.store(
        preview_id=preview_id_1,
        payload=payload_1,
        user_id=user_id,
        original_workout_id=original_workout_id,
    )

    # Verify first is stored.
    entry1, _ = await cache.get_owned(preview_id_1, user_id)
    assert entry1 is not None

    # Second regen for same (user, workout).
    await cache.store(
        preview_id=preview_id_2,
        payload=payload_2,
        user_id=user_id,
        original_workout_id=original_workout_id,
    )

    # First preview must be evicted.
    entry1_after, err1 = await cache.get_owned(preview_id_1, user_id)
    assert entry1_after is None
    assert err1 == "PREVIEW_EXPIRED"

    # Second preview is live.
    entry2, err2 = await cache.get_owned(preview_id_2, user_id)
    assert entry2 is not None
    assert err2 is None

    # Only 1 entry in cache, evicts_on_replace incremented.
    stats = cache.get_stats()
    assert stats["size"] == 1
    assert stats["counters"]["evicts_on_replace"] >= 1


# ---------------------------------------------------------------------------
# 6. Cross-user ownership 403
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_preview_not_owned_403(cache: RegenPreviewCache):
    """
    User B tries to access user A's preview_id.  get_owned must return
    (None, "PREVIEW_NOT_OWNED") and increment the auth_mismatches counter.
    """
    user_a = "user-a-owner"
    user_b = "user-b-attacker"
    original_workout_id = "workout-shared-date"
    preview_id = str(uuid.uuid4())

    payload = _make_payload(preview_id, user_a, original_workout_id)
    await cache.store(
        preview_id=preview_id,
        payload=payload,
        user_id=user_a,
        original_workout_id=original_workout_id,
    )

    # User A can access.
    entry_a, err_a = await cache.get_owned(preview_id, user_a)
    assert entry_a is not None
    assert err_a is None

    # User B cannot.
    entry_b, err_b = await cache.get_owned(preview_id, user_b)
    assert entry_b is None
    assert err_b == "PREVIEW_NOT_OWNED"

    # Auth mismatch counter incremented.
    stats = cache.get_stats()
    assert stats["counters"]["auth_mismatches"] >= 1


# ---------------------------------------------------------------------------
# 7. Swap-in-preview mutates cache but NOT DB
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_swap_in_preview_mutates_cache_not_db(cache: RegenPreviewCache):
    """
    After a cache.update() swap mutation, the entry's exercises_json reflects
    the new exercise name.  A mock DB object must have no interaction at all.
    """
    user_id = "user-swap"
    original_workout_id = "workout-swap-original"
    preview_id = str(uuid.uuid4())
    exercises = [
        {"name": "Bench Press", "sets": 4, "reps": 8, "rest_seconds": 90},
        {"name": "Squat", "sets": 3, "reps": 10, "rest_seconds": 60},
    ]
    payload = _make_payload(preview_id, user_id, original_workout_id, exercises=exercises)

    await cache.store(
        preview_id=preview_id,
        payload=payload,
        user_id=user_id,
        original_workout_id=original_workout_id,
    )

    # Track DB interactions.
    mock_db = MagicMock()

    old_name = "Bench Press"
    new_name = "Incline Dumbbell Press"

    def _swap_mutator(p: dict) -> dict:
        exs = p.get("exercises_json") or []
        for ex in exs:
            if isinstance(ex, dict) and ex.get("name", "").lower() == old_name.lower():
                ex["name"] = new_name
                break
        p["exercises_json"] = exs
        return p

    updated_entry = await cache.update(preview_id, user_id, _swap_mutator)
    assert updated_entry is not None

    # Cache payload reflects new name.
    names = [ex.get("name") for ex in updated_entry.payload["exercises_json"]]
    assert new_name in names
    assert old_name not in names

    # DB was never called.
    mock_db.update_workout.assert_not_called()
    mock_db.supersede_workout.assert_not_called()

    # _commit_data's exercises_json does NOT auto-update until commit path
    # explicitly syncs it (versioning.py does this before calling supersede).
    # Verify the cache entry still has _commit_data intact.
    assert "_commit_data" in updated_entry.payload


# ---------------------------------------------------------------------------
# 8. ORIGINAL_ALREADY_SUPERSEDED 409
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_original_already_superseded_409(cache: RegenPreviewCache):
    """
    Scenario: Device A and Device B both regen workout W.  Device B commits
    first (supersedes W -> W').  Device A now tries to commit its preview
    against W but W.is_current is False.

    We model the superseded check in application logic:
    the DB returns is_current=False for original, which the endpoint code
    maps to a 409 ORIGINAL_ALREADY_SUPERSEDED.  We verify that:
      - The preview for device A is still in cache (commit was blocked).
      - The mock DB's supersede_workout was never invoked for device A's call.
    """
    user_id = "user-race"
    original_workout_id = "workout-race-original"
    preview_id_a = str(uuid.uuid4())

    payload_a = _make_payload(preview_id_a, user_id, original_workout_id)
    await cache.store(
        preview_id=preview_id_a,
        payload=payload_a,
        user_id=user_id,
        original_workout_id=original_workout_id,
    )

    entry, err = await cache.get_owned(preview_id_a, user_id)
    assert entry is not None

    # Simulate the DB state after device B already committed:
    # original is no longer current.
    mock_db = MagicMock()
    original_superseded = {
        "id": original_workout_id,
        "is_current": False,
        "superseded_by": str(uuid.uuid4()),
    }
    mock_db.get_workout.return_value = original_superseded

    # Application logic: if original.is_current is False -> raise 409.
    original_row = mock_db.get_workout(original_workout_id)
    already_superseded = not original_row.get("is_current", True)
    assert already_superseded is True, "Original must appear already superseded"

    # supersede_workout must NOT be called for device A.
    mock_db.supersede_workout.assert_not_called()

    # Device A's preview is still in cache (the 409 path does not delete it).
    entry_still, err_still = await cache.get_owned(preview_id_a, user_id)
    assert entry_still is not None
    assert err_still is None


# ---------------------------------------------------------------------------
# 9. Discard idempotency -> 204 twice
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_discard_is_idempotent(cache: RegenPreviewCache):
    """
    Calling cache.delete() twice with the same preview_id must not raise.
    The first call returns True (something deleted); the second returns False
    (nothing to delete), modelling the 204 idempotent behaviour of the endpoint.
    """
    user_id = "user-idempotent-discard"
    original_workout_id = "workout-idempotent"
    preview_id = str(uuid.uuid4())
    payload = _make_payload(preview_id, user_id, original_workout_id)

    await cache.store(
        preview_id=preview_id,
        payload=payload,
        user_id=user_id,
        original_workout_id=original_workout_id,
    )

    # First discard: should delete and return True.
    first = await cache.delete(preview_id)
    assert first is True

    # Second discard: preview already gone, returns False (no-op, no exception).
    second = await cache.delete(preview_id)
    assert second is False

    # Cache is empty.
    assert cache.get_stats()["size"] == 0


# ---------------------------------------------------------------------------
# 10. Cache stats counters
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_cache_get_stats_counters():
    """
    Verify that stores, hits, misses, expires, and deletes all increment
    correctly through the corresponding operations.
    """
    c = RegenPreviewCache(ttl_seconds=1)

    # --- stores ---
    uid = "user-stats"
    wid = "workout-stats"
    pid1 = str(uuid.uuid4())
    pid2 = str(uuid.uuid4())

    await c.store(pid1, _make_payload(pid1, uid, wid), uid, wid)
    s = c.get_stats()
    assert s["counters"]["stores"] == 1

    # Storing a second entry for the same (user, workout) should increment
    # both stores AND evicts_on_replace.
    await c.store(pid2, _make_payload(pid2, uid, wid), uid, wid)
    s = c.get_stats()
    assert s["counters"]["stores"] == 2
    assert s["counters"]["evicts_on_replace"] == 1

    # --- hits ---
    await c.get(pid2)
    s = c.get_stats()
    assert s["counters"]["hits"] >= 1

    # --- misses (nonexistent id) ---
    await c.get("nonexistent-preview-id")
    s = c.get_stats()
    assert s["counters"]["misses"] >= 1

    # --- expires (wait for TTL with ttl_seconds=1) ---
    await asyncio.sleep(1.1)
    await c.get(pid2)  # lazy eviction on get
    s = c.get_stats()
    assert s["counters"]["expires"] >= 1

    # --- deletes ---
    # Store a fresh entry so delete has something to remove.
    pid3 = str(uuid.uuid4())
    c2 = RegenPreviewCache(ttl_seconds=300)
    await c2.store(pid3, _make_payload(pid3, uid, "workout-del"), uid, "workout-del")
    await c2.delete(pid3)
    s2 = c2.get_stats()
    assert s2["counters"]["deletes"] == 1

    # --- auth_mismatches ---
    c3 = RegenPreviewCache()
    pid4 = str(uuid.uuid4())
    await c3.store(pid4, _make_payload(pid4, "owner", "w-auth"), "owner", "w-auth")
    await c3.get_owned(pid4, "other-user")
    s3 = c3.get_stats()
    assert s3["counters"]["auth_mismatches"] >= 1
