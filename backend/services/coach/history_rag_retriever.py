"""
History RAG retriever — prompt-time helpers for the coach.

Plan: §1b.9.

Three small helpers the daily-insight (morning + evening) prompt assembler
calls to inject "all-previous" semantic recall into the Gemini prompt as a
`relevant_past_events` array. Each helper returns a list of doc strings
bounded to ≤300 tokens total so prompt cost stays flat.

These functions DO NOT call Gemini — vector lookups only (free per
§1b.9 cost note). Token bounding is character-based as a cheap proxy
(~4 chars/token).
"""
from __future__ import annotations

import logging
from typing import Any, Dict, List, Optional

from services.chroma.user_history_collection import (
    NUTRITION_COLLECTION,
    SLEEP_COLLECTION,
    WORKOUT_COLLECTION,
)

logger = logging.getLogger("history_rag_retriever")

# 300 token budget ≈ 1200 characters. Used as a hard cap when joining
# multiple retrieved docs.
_MAX_CHARS = 1200


def _bound_docs(docs: List[str], max_chars: int = _MAX_CHARS) -> List[str]:
    """Drop docs from the tail once the cumulative character count exceeds
    the budget. Preserves the highest-similarity items (Chroma returns
    results ordered by distance ascending)."""
    out: List[str] = []
    total = 0
    for d in docs:
        if not d:
            continue
        if total + len(d) > max_chars:
            break
        out.append(d)
        total += len(d)
    return out


def _query(collection_name: str, query: str,
           user_id: str, n: int) -> List[str]:
    """Common path: filter to this user's docs, return document strings.

    Computes the query embedding via GeminiService (cached) and passes it
    explicitly to Chroma. Chroma Cloud collections in this project have NO
    server-side embedding function configured — `query_texts=` returns 422.
    """
    try:
        from core.chroma_cloud import get_chroma_cloud_client
        from services.gemini_service import GeminiService
        emb = GeminiService().get_embedding(query)
        if not emb:
            return []
        client = get_chroma_cloud_client()
        collection = client.get_or_create_collection(collection_name)
        results = collection.query(
            query_embeddings=[emb],
            n_results=n,
            where={"user_id": user_id},
        )
        docs_row = (results or {}).get("documents") or [[]]
        docs = docs_row[0] if docs_row else []
        return [d for d in docs if isinstance(d, str) and d.strip()]
    except Exception as e:
        logger.warning(f"[history_rag_retriever] query {collection_name} failed: {e}")
        return []


# ---------------------------------------------------------------------------
# Public retrieval helpers
# ---------------------------------------------------------------------------
def retrieve_similar_workouts(user_id: str,
                              today_workout: Optional[Dict[str, Any]],
                              k: int = 3) -> List[str]:
    """Top-K past workouts similar to today's planned workout.

    Query phrasing per §1b.9:
        "morning brief for {today_planned_workout}"
    """
    if not user_id:
        return []
    name = "today's workout"
    if isinstance(today_workout, dict):
        n = today_workout.get("name")
        if n:
            name = n
    query = f"morning brief for {name}"
    docs = _query(WORKOUT_COLLECTION, query, user_id, k)
    return _bound_docs(docs)


def retrieve_nutrition_pattern(user_id: str,
                               time_of_day: str,
                               day_of_week: str,
                               k: int = 3) -> List[str]:
    """Top-K past nutrition days that look like (time_of_day, day_of_week).

    Query phrasing per §1b.9:
        "nutrition pattern for {time_of_day} {day_of_week}"
    """
    if not user_id:
        return []
    query = f"nutrition pattern for {time_of_day} {day_of_week}"
    docs = _query(NUTRITION_COLLECTION, query, user_id, k)
    return _bound_docs(docs)


def retrieve_similar_day(user_id: str, k: int = 3) -> List[str]:
    """Top-K past 'similar end-of-day' summaries. Used by the evening recap
    branch (§1b.9 third query)."""
    if not user_id:
        return []
    query = "end-of-day reflection for similar day"
    docs = _query(SLEEP_COLLECTION, query, user_id, k)
    return _bound_docs(docs)
