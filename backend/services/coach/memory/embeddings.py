"""
ChromaDB relevance index for coach_memory.

Postgres (coach_memory) is the system of record. This module mirrors each
memory's content into a ChromaDB collection so the retriever can add a semantic
"relevance to the current message" term to its deterministic ranking. The index
is rebuildable and entirely best-effort: every function swallows its own errors
and returns a safe value, because a Chroma hiccup must NEVER break the chat path
or a memory write. When the index is unavailable the retriever simply ranks
without the relevance term.
"""
from __future__ import annotations

import logging
from typing import Dict, List, Optional, Tuple

from core.chroma_cloud import get_chroma_cloud_client
from services.coach.memory.schemas import MEMORY_COLLECTION

logger = logging.getLogger("coach_memory.embeddings")


def _embed(text: str) -> Optional[List[float]]:
    """Sync embedding via GeminiService (locally cached). None on failure."""
    if not text:
        return None
    try:
        from services.gemini_service import GeminiService
        return GeminiService().get_embedding(text)
    except Exception as e:
        logger.warning(f"[memory.embeddings] embed failed: {e}")
        return None


def _doc_id(user_id: str, memory_id: str) -> str:
    return f"{user_id}:{memory_id}"


def index_memory(memory_row: Dict) -> bool:
    """Upsert one memory into the relevance index. Idempotent (stable id)."""
    user_id = memory_row.get("user_id")
    memory_id = memory_row.get("id")
    content = memory_row.get("content")
    if not (user_id and memory_id and content):
        return False
    try:
        emb = _embed(content)
        if emb is None:
            return False
        collection = get_chroma_cloud_client().get_or_create_collection(MEMORY_COLLECTION)
        collection.upsert(
            documents=[content],
            metadatas=[{
                "user_id": user_id,
                "memory_id": memory_id,
                "memory_type": memory_row.get("memory_type") or "semantic",
                "category": memory_row.get("category") or "other",
                "status": memory_row.get("status") or "active",
            }],
            ids=[_doc_id(user_id, memory_id)],
            embeddings=[emb],
        )
        return True
    except Exception as e:
        logger.warning(f"[memory.embeddings] index_memory failed: {e}")
        return False


def delete_memory(user_id: str, memory_id: str) -> bool:
    """Remove one memory from the relevance index (on hard delete)."""
    if not (user_id and memory_id):
        return False
    try:
        collection = get_chroma_cloud_client().get_or_create_collection(MEMORY_COLLECTION)
        collection.delete(ids=[_doc_id(user_id, memory_id)])
        return True
    except Exception as e:
        logger.warning(f"[memory.embeddings] delete_memory failed: {e}")
        return False


def query_relevant(
    user_id: str, query_text: str, n_results: int = 12
) -> Dict[str, float]:
    """Return {memory_id: relevance_score in 0..1} for memories semantically
    near the query. Empty dict on any failure (retriever degrades gracefully).
    Relevance = 1 - normalized_distance, clamped to [0, 1]."""
    if not (user_id and query_text):
        return {}
    try:
        emb = _embed(query_text)
        if emb is None:
            return {}
        res = get_chroma_cloud_client().query_collection(
            collection_name=MEMORY_COLLECTION,
            query_embeddings=[emb],
            n_results=n_results,
            where={"user_id": user_id},
        )
        ids = (res.get("ids") or [[]])[0]
        dists = (res.get("distances") or [[]])[0]
        metas = (res.get("metadatas") or [[]])[0]
        out: Dict[str, float] = {}
        for i, doc_id in enumerate(ids):
            meta = metas[i] if i < len(metas) else {}
            mem_id = (meta or {}).get("memory_id")
            if not mem_id:
                # Fall back to parsing "user:memory" id form.
                mem_id = doc_id.split(":", 1)[-1] if ":" in doc_id else doc_id
            dist = dists[i] if i < len(dists) else None
            if dist is None:
                continue
            # Cosine distance in [0,2]; map to similarity in [0,1].
            score = max(0.0, min(1.0, 1.0 - (float(dist) / 2.0)))
            out[mem_id] = score
        return out
    except Exception as e:
        logger.warning(f"[memory.embeddings] query_relevant failed: {e}")
        return {}
