"""Deterministic, equipment-free cardio block for cardio-in-split.

The primary RAG generation path fixes the exercise list before Gemini names the
workout, so a prompt-based finisher (as in the free-form path) can't add cardio
there. This appends (placement='after') or prepends (placement='before') a short
bodyweight conditioning block when the user's cardio preference asks for it.

Bodyweight by design — applies regardless of the user's gym equipment, and the
library ids below are verified present in exercise_library_cleaned so media /
instructions resolve like any other exercise. Equipment-aware / protocol-aware
cardio (rower intervals, zone-2, etc.) is the VO2max plan's later scope.
"""
from typing import List

from core.logger import get_logger

logger = get_logger(__name__)

# Verified ids in exercise_library_cleaned (all Bodyweight).
_FINISHER_POOL = [
    {"library_id": "c4d421fe-3e28-471b-8a95-293f0733d161", "name": "Burpee", "muscle_group": "full body"},
    {"library_id": "3284b7dd-367d-471e-a1ff-ec34fcb633f9", "name": "Mountain Climber", "muscle_group": "core"},
    {"library_id": "d9e75684-4be9-4071-9f40-3eec7c9fa7f4", "name": "High Knees", "muscle_group": "legs"},
    {"library_id": "fa1778bc-774d-4a50-b770-d77d03acbd4c", "name": "Jumping Jack", "muscle_group": "full body"},
]


def _block_exercise(spec: dict, work_seconds: int = 40) -> dict:
    return {
        "name": spec["name"],
        "library_id": spec["library_id"],
        "muscle_group": spec["muscle_group"],
        "equipment": "Bodyweight",
        "sets": 3,
        "reps": 1,
        "duration_seconds": work_seconds,
        "rest_seconds": 20,
        "is_timed": True,
        "is_cardio_block": True,
        "notes": "Conditioning — steady, hard pace; short rest between rounds.",
    }


def build_cardio_block(count: int = 2, work_seconds: int = 40) -> List[dict]:
    """`count` bodyweight conditioning exercises (deterministic order)."""
    count = max(1, min(count, len(_FINISHER_POOL)))
    return [_block_exercise(s, work_seconds) for s in _FINISHER_POOL[:count]]


def apply_cardio_block(exercises: List[dict], placement: str = "after", count: int = 2) -> List[dict]:
    """Add a cardio conditioning block before/after the main exercises.

    Idempotent — no-op if a cardio block is already present (so a regenerate or a
    double-pass doesn't stack finishers).
    """
    if not exercises:
        return exercises
    if any(e.get("is_cardio_block") for e in exercises):
        return exercises
    block = build_cardio_block(count=count)
    if (placement or "after").lower() == "before":
        logger.info("🏃 [Cardio] prepended conditioning block (before lifting)")
        return block + exercises
    logger.info("🏃 [Cardio] appended conditioning finisher (after lifting)")
    return exercises + block
