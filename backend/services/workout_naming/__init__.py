"""
Algorithmic workout namer (Phase D).

Replaces Gemini-generated workout names and the hard-coded
``"Gentle Mobility Session"`` literal with a deterministic-but-varied
combinator over hand-curated word pools.

Public surface:

    from services.workout_naming import generate_workout_name

The function is pure stdlib (no LLM, no network), takes structured
inputs (goal, focus, equipment, duration, difficulty, ...), and returns
a stable name for a given ``(user_id, workout_id, today_iso)`` seed
while still producing >95% unique names across random seeds.
"""

from .generator import generate_workout_name

__all__ = ["generate_workout_name"]
