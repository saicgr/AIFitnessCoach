"""Injured-user generation must produce a REAL workout, never crash.

Covers the two root causes behind a stuck onboarding for an injured user:
  1. `.strip()` on a native asyncpg UUID `exercise_id` → 500 (type-safety).
  2. The `lower_back` avoided-muscle set was so broad it discarded every
     vetted-safe loaded exercise → empty pool → stretches.

The pipeline-level fixes (focus normalization + safe-pool backfill) need the
live DB/ChromaDB and are verified end-to-end; these are the pure-logic guards.
"""
import uuid

import pytest


# ---------------------------------------------------------------------------
# 1. Crash: id fields can be native UUIDs — string ops must never raise.
# ---------------------------------------------------------------------------

def test_lib_key_handles_uuid_exercise_id():
    from services.workout_completeness import _lib_key

    u = uuid.uuid4()  # proxy for asyncpg.pgproto UUID (also lacks .strip())
    # Native-UUID exercise_id must coerce to str, not raise.
    assert _lib_key({"exercise_id": u}) == str(u)
    assert isinstance(_lib_key({"exercise_id": u}), str)
    # library_id wins when present; whitespace stripped.
    assert _lib_key({"library_id": " abc ", "exercise_id": u}) == "abc"
    # Empty / missing → empty string (no crash).
    assert _lib_key({}) == ""


def test_dedupe_strip_pattern_handles_uuid():
    """Mirror generation_endpoints.py:1328 — str(...) before .strip()."""
    u = uuid.uuid4()
    lib_id = str({"exercise_id": u}.get("library_id")
                 or {"exercise_id": u}.get("exercise_id") or "").strip()
    assert lib_id == str(u)


# ---------------------------------------------------------------------------
# 2. lower_back avoidance is right-sized to the lumbar region only.
# ---------------------------------------------------------------------------

def test_lower_back_avoidance_is_right_sized():
    from api.v1.workouts.readiness_utils import get_muscles_to_avoid_from_injuries

    avoided = set(get_muscles_to_avoid_from_injuries(["lower_back"]))
    assert "lower_back" in avoided
    assert "erector_spinae" in avoided
    # The over-broad muscles that collapsed the pool must be GONE — the vetted
    # `lower_back_safe` index tag handles those, not blunt muscle avoidance.
    for over_broad in ("glutes", "hamstrings", "back", "lats"):
        assert over_broad not in avoided, (
            f"{over_broad!r} should not be avoided for a lower_back injury — "
            "it discarded vetted-safe loaded exercises"
        )


def test_other_injuries_still_resolve():
    """Right-sizing lower_back must not break other chips (no empty avoidance)."""
    from api.v1.workouts.readiness_utils import get_muscles_to_avoid_from_injuries

    for chip in ("knees", "shoulders", "abs", "chest", "quads", "calves"):
        assert get_muscles_to_avoid_from_injuries([chip]), f"{chip} resolved empty"
    # none/other never drive avoidance.
    assert get_muscles_to_avoid_from_injuries(["none"]) == []
