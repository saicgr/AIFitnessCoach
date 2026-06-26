"""Strength→skill ratio block recommender (Dr-Yaad audit #7).

Dr-Yaad's onboarding computes a RATIO of basic-lift strength vs skill level and
picks the training block from it — "the ratio decides, not a template": Skill /
Foundational Strength / Hypertrophy. We already ship the blocks (mesocycle
phases) but nothing SELECTED one from an assessment. This does.

Signals (both already in the DB):
  • strength_index 0–100 — mean of the user's latest per-muscle strength_scores.
  • skill_index   0–100  — how far they've climbed the progression ladders
                           (accepted variant progressions in user_exercise_mastery).

Decision:
  • Both very low      → Foundational Strength (the right default for most).
  • Skill ≫ strength   → Foundational Strength (skills outpace the base — build it).
  • Strength ≫ skill   → Skill (strong base, skills lagging — go train them).
  • Strong + balanced  → Hypertrophy (add size on a solid base).
  • Otherwise          → Foundational Strength.

Pure read + arithmetic; fail-open to Foundational Strength with low confidence.
"""
from __future__ import annotations

import logging
from typing import Any, Dict, Optional

from core.db import get_supabase_db

logger = logging.getLogger("block_recommender")

BLOCK_SKILL = "Skill"
BLOCK_FOUNDATION = "Foundational Strength"
BLOCK_HYPERTROPHY = "Hypertrophy"


def _strength_index(db, user_id: str) -> Optional[float]:
    """Mean of the user's latest per-muscle strength_scores (0–100)."""
    try:
        rows = (
            db.client.table("latest_strength_scores")
            .select("strength_score")
            .eq("user_id", user_id)
            .execute()
        ).data or []
    except Exception as e:
        logger.warning(f"[block] strength read failed: {e}")
        return None
    vals = [float(r["strength_score"]) for r in rows
            if r.get("strength_score") is not None]
    if not vals:
        return None
    return sum(vals) / len(vals)


def _skill_index(db, user_id: str) -> float:
    """0–100 from accepted variant progressions — climbing the ladder = skill."""
    try:
        rows = (
            db.client.table("user_exercise_mastery")
            .select("progression_accepted_count, total_sessions")
            .eq("user_id", user_id)
            .execute()
        ).data or []
    except Exception as e:
        logger.warning(f"[block] skill read failed: {e}")
        return 0.0
    accepted = sum(int(r.get("progression_accepted_count") or 0) for r in rows)
    # Each accepted progression ≈ +12 skill; a little credit for breadth.
    breadth = min(20.0, len(rows) * 2.0)
    return min(100.0, accepted * 12.0 + breadth)


def recommend_block(user_id: str, db=None) -> Dict[str, Any]:
    """Return {block, reason, strength_index, skill_index, ratio, confidence}."""
    db = db or get_supabase_db()
    s = _strength_index(db, user_id)
    k = _skill_index(db, user_id)

    if s is None:
        return {
            "block": BLOCK_FOUNDATION,
            "reason": "Not enough lifting history yet — start with foundational "
                      "strength to build a base the skills can stand on.",
            "strength_index": None,
            "skill_index": round(k, 1),
            "ratio": None,
            "confidence": 0.2,
        }

    ratio = s / max(k, 1.0)
    confidence = 0.5 if (s and k) else 0.35

    if s < 20 and k < 20:
        block = BLOCK_FOUNDATION
        reason = ("You're early on — foundational strength builds the base most "
                  "skills and size depend on.")
    elif k > s * 1.4:
        block = BLOCK_FOUNDATION
        reason = (f"Your skills ({round(k)}) are ahead of your base strength "
                  f"({round(s)}) — a foundational-strength block closes the gap.")
    elif s > k * 1.4 + 10:
        block = BLOCK_SKILL
        reason = (f"Strong base ({round(s)}) with skills lagging ({round(k)}) — "
                  f"a skill block puts that strength to work on the moves you want.")
    elif s >= 55:
        block = BLOCK_HYPERTROPHY
        reason = (f"Strong and balanced (strength {round(s)}, skill {round(k)}) — "
                  f"a hypertrophy block adds size on a solid base.")
    else:
        block = BLOCK_FOUNDATION
        reason = ("Foundational strength is the highest-leverage block at your "
                  "level — it feeds both skill and size next.")

    return {
        "block": block,
        "reason": reason,
        "strength_index": round(s, 1),
        "skill_index": round(k, 1),
        "ratio": round(ratio, 2),
        "confidence": confidence,
    }
