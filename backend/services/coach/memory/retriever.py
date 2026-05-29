"""
Ranked recall for the coach memory subsystem.

Retrieval is a deterministic composite score (local algo, no LLM — per
feedback_prefer_local_algo_over_rag) over the active+open memory pool:

    score = w_sal*salience
          + w_rec*recency_decay(age, type half-life)
          + w_rel*embedding_relevance_to_current_message
          + w_typ*type_priority
          + w_loop*open_loop_flag

Open loops are ALWAYS included regardless of score so the coach never forgets
an outstanding question. The embedding relevance term is best-effort: if the
Chroma index is unavailable the term is 0 and ranking proceeds on the other
signals (the chat path is never blocked on a vector query).
"""
from __future__ import annotations

import logging
import math
from datetime import datetime, timezone
from typing import Dict, List, Optional

from core.db import get_supabase_db
from services.coach.memory import embeddings
from services.coach.memory.schemas import (
    MIN_INJECTABLE_SALIENCE,
    RANK_WEIGHTS,
    RECENCY_HALF_LIFE_DAYS,
    TYPE_PRIORITY,
)

logger = logging.getLogger("coach_memory.retriever")


def _parse_ts(val) -> Optional[datetime]:
    if not val:
        return None
    try:
        s = str(val).replace("Z", "+00:00")
        dt = datetime.fromisoformat(s)
        return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)
    except Exception:
        return None


def _recency_decay(row: Dict, now: datetime) -> float:
    """Exponential decay on age using a type-specific half-life. 1.0 = fresh."""
    ref = _parse_ts(row.get("last_referenced_at")) or _parse_ts(row.get("updated_at")) \
        or _parse_ts(row.get("created_at"))
    if not ref:
        return 0.5
    age_days = max(0.0, (now - ref).total_seconds() / 86400.0)
    half_life = RECENCY_HALF_LIFE_DAYS.get(row.get("memory_type") or "semantic", 21.0)
    return math.exp(-math.log(2) * age_days / half_life)


def _score(row: Dict, relevance: Dict[str, float], now: datetime) -> float:
    w = RANK_WEIGHTS
    is_open = row.get("status") == "open"
    rel = relevance.get(row.get("id"), 0.0)
    return (
        w["salience"] * float(row.get("salience") or 0.5)
        + w["recency"] * _recency_decay(row, now)
        + w["relevance"] * rel
        + w["type_priority"] * TYPE_PRIORITY.get(row.get("memory_type") or "semantic", 0.4)
        + w["open_loop"] * (1.0 if is_open else 0.0)
    )


def retrieve_for_chat(
    user_id: str, current_message: Optional[str] = None, limit: int = 8
) -> List[Dict]:
    """Top memories to inject for a coach turn. Open loops always included."""
    db = get_supabase_db()
    pool = db.memory.list_injectable(user_id, limit=60)
    if not pool:
        return []
    # Noise floor — never inject trivially weak memories unless an open loop.
    pool = [m for m in pool
            if float(m.get("salience") or 0) >= MIN_INJECTABLE_SALIENCE
            or m.get("status") == "open"]

    relevance: Dict[str, float] = {}
    if current_message:
        relevance = embeddings.query_relevant(user_id, current_message, n_results=16)

    now = datetime.now(timezone.utc)
    open_loops = [m for m in pool if m.get("status") == "open"]
    others = [m for m in pool if m.get("status") != "open"]
    others.sort(key=lambda m: _score(m, relevance, now), reverse=True)

    # Open loops first (capped so they can't crowd everything out), then the
    # highest-scoring remaining memories up to the limit.
    selected = open_loops[: max(2, limit // 2)]
    for m in others:
        if len(selected) >= limit:
            break
        selected.append(m)
    return selected[:limit]


def retrieve_for_briefing(user_id: str, limit: int = 8) -> Dict[str, List[Dict]]:
    """Recall tuned for the daily open briefing (no current query):
    due open loops (for the check-in question) + recent durable facts."""
    db = get_supabase_db()
    now = datetime.now(timezone.utc)
    due_loops = db.memory.list_open_loops_due(user_id, limit=limit)
    pool = db.memory.list_injectable(user_id, limit=40)
    pool = [m for m in pool if m.get("status") != "open"]
    pool.sort(key=lambda m: _score(m, {}, now), reverse=True)
    return {
        "open_loops": due_loops,
        "facts": pool[:limit],
    }
