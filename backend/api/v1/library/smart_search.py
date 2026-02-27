"""
Hybrid AI exercise search endpoint.

Combines fuzzy (PostgreSQL trigram) search with semantic (ChromaDB embedding)
search using Reciprocal Rank Fusion for natural language exercise queries.

Examples:
- "I want to walk on treadmill" -> Walking, Treadmill
- "something for bad knees" -> low-impact exercises
- "threadmill" -> Treadmill exercises (with spelling correction)
"""
import asyncio
import hashlib
import json
import time
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, BackgroundTasks, Query

from core.logger import get_logger
from core.supabase_db import get_supabase_db
from services.gemini_service import ResponseCache

from .exercises import _extract_best_correction
from .utils import fetch_fuzzy_search_results, normalize_body_part, row_to_library_exercise

router = APIRouter()
logger = get_logger(__name__)

# In-memory cache: 5-minute TTL, 500 entries max
_smart_search_cache = ResponseCache(prefix="smart_search", ttl_seconds=300, max_size=500)


def _make_cache_key(query: str, equipment: Optional[str], body_parts: Optional[str], limit: int) -> str:
    """Create a deterministic cache key from search parameters."""
    normalized = query.strip().lower()
    parts = f"{normalized}|{equipment or ''}|{body_parts or ''}|{limit}"
    return hashlib.sha256(parts.encode()).hexdigest()


def _exercise_row_to_dict(row: dict) -> dict:
    """Convert a DB row to a serializable exercise dict for the response."""
    exercise = row_to_library_exercise(row, from_cleaned_view=True)
    return {
        "id": exercise.id,
        "name": exercise.name,
        "original_name": exercise.original_name,
        "body_part": exercise.body_part,
        "equipment": exercise.equipment,
        "target_muscle": exercise.target_muscle,
        "secondary_muscles": exercise.secondary_muscles,
        "instructions": exercise.instructions,
        "difficulty_level": exercise.difficulty_level,
        "category": exercise.category,
        "gif_url": exercise.gif_url,
        "video_url": exercise.video_url,
        "image_url": exercise.image_url,
        "goals": exercise.goals,
        "suitable_for": exercise.suitable_for,
        "avoid_if": exercise.avoid_if,
    }


def _reciprocal_rank_fusion(
    fuzzy_results: List[dict],
    semantic_results: List[dict],
    k: int = 60,
    fuzzy_weight: float = 1.0,
    semantic_weight: float = 1.2,
) -> List[dict]:
    """
    Merge two ranked lists using Reciprocal Rank Fusion.

    RRF score = sum(weight_i / (k + rank_i)) for each system.
    Exercises found by BOTH systems score higher because scores sum.

    Args:
        fuzzy_results: Exercises from fuzzy/trigram search (already ranked)
        semantic_results: Exercises from semantic/embedding search (already ranked)
        k: Smoothing constant (default 60, standard RRF)
        fuzzy_weight: Weight for fuzzy results
        semantic_weight: Weight for semantic results (1.2 = slight boost for intent)

    Returns:
        Merged list sorted by RRF score, with relevance_score and match_sources
    """
    scores: Dict[str, float] = {}
    exercise_data: Dict[str, dict] = {}
    sources: Dict[str, List[str]] = {}

    # Score fuzzy results
    for rank, row in enumerate(fuzzy_results):
        eid = str(row.get("id", ""))
        if not eid:
            continue
        scores[eid] = scores.get(eid, 0) + fuzzy_weight / (k + rank)
        exercise_data[eid] = row
        sources.setdefault(eid, []).append("fuzzy")

    # Score semantic results
    for rank, row in enumerate(semantic_results):
        eid = str(row.get("id", ""))
        if not eid:
            continue
        scores[eid] = scores.get(eid, 0) + semantic_weight / (k + rank)
        if eid not in exercise_data:
            exercise_data[eid] = row
        sources.setdefault(eid, []).append("semantic")

    if not scores:
        return []

    # Normalize scores to 0.0-1.0
    max_score = max(scores.values())

    # Build merged results
    merged = []
    for eid, score in sorted(scores.items(), key=lambda x: x[-1], reverse=True):
        row = exercise_data[eid]
        exercise_dict = _exercise_row_to_dict(row)
        exercise_dict["relevance_score"] = round(score / max_score, 4) if max_score > 0 else 0
        exercise_dict["match_sources"] = sources.get(eid, [])
        merged.append(exercise_dict)

    return merged


async def _run_semantic_search(
    query: str,
    equipment: Optional[str],
    body_parts: Optional[str],
    limit: int,
) -> List[dict]:
    """
    Run semantic search via ChromaDB embeddings.
    Expands query with FOCUS_AREA_KEYWORDS for better matching.
    Returns exercise rows from the database.
    """
    try:
        from core.chroma_cloud import get_chroma_cloud_client
        from services.gemini_service import get_gemini_service

        gemini = get_gemini_service()
        chroma = get_chroma_cloud_client()

        # Expand query with focus area keywords for better semantic matching
        expanded_query = query
        query_lower = query.lower()

        try:
            from services.exercise_rag.search import FOCUS_AREA_KEYWORDS
            for key, expansion in FOCUS_AREA_KEYWORDS.items():
                if key.replace("_", " ") in query_lower or key in query_lower:
                    expanded_query = f"{query} {expansion}"
                    break
        except ImportError as e:
            logger.debug(f"Focus area keywords not available: {e}")

        # Get embedding for the query
        embedding = await gemini.get_embedding_async(expanded_query)

        # Build ChromaDB where filter
        where_filter = None
        if equipment or body_parts:
            conditions = []
            if equipment:
                conditions.append({"equipment": {"$eq": equipment}})
            if body_parts:
                conditions.append({"body_part": {"$eq": body_parts}})

            if len(conditions) == 1:
                where_filter = conditions[0]
            else:
                where_filter = {"$and": conditions}

        # Query ChromaDB
        results = chroma.query_collection(
            collection_name="fitness_exercises",
            query_embeddings=[embedding],
            n_results=min(limit, 30),
            where=where_filter,
        )

        if not results or not results.get("ids") or not results["ids"][0]:
            return []

        # Get exercise IDs from ChromaDB results
        chroma_ids = results["ids"][0]
        metadatas = results.get("metadatas", [[]])[0]

        # Fetch full exercise data from Supabase for these IDs
        db = get_supabase_db()
        exercise_rows = []

        # Batch fetch in chunks of 50
        for i in range(0, len(chroma_ids), 50):
            chunk_ids = chroma_ids[i:i + 50]
            result = db.client.table("exercise_library_cleaned").select("*").in_("id", chunk_ids).execute()
            if result.data:
                exercise_rows.extend(result.data)

        # Maintain ChromaDB ranking order
        id_to_row = {str(row["id"]): row for row in exercise_rows}
        ordered_rows = [id_to_row[cid] for cid in chroma_ids if cid in id_to_row]

        return ordered_rows

    except Exception as e:
        logger.warning(f"Semantic search failed (falling back to fuzzy-only): {e}")
        return []


async def _write_cache_to_db(
    query_hash: str,
    query_text: str,
    filters_json: dict,
    results: List[dict],
):
    """Background task: write search results to DB cache."""
    try:
        db = get_supabase_db()
        db.client.rpc(
            "upsert_exercise_search_cache",
            {
                "p_query_hash": query_hash,
                "p_query_text": query_text,
                "p_filters_json": json.dumps(filters_json),
                "p_results": json.dumps(results),
                "p_ttl_hours": 24,
            },
        ).execute()
    except Exception as e:
        logger.warning(f"Failed to write exercise search cache: {e}")


@router.get("/exercises/smart-search")
async def smart_search_exercises(
    background_tasks: BackgroundTasks,
    q: str = Query(..., min_length=2, max_length=200, description="Search query"),
    equipment: Optional[str] = Query(default=None, description="Equipment filter"),
    body_parts: Optional[str] = Query(default=None, description="Body part filter"),
    limit: int = Query(default=20, ge=1, le=50, description="Max results"),
    semantic: bool = Query(default=True, description="Enable semantic search"),
):
    """
    Hybrid exercise search combining fuzzy (trigram) and semantic (embedding) search.

    Uses Reciprocal Rank Fusion to merge results from both systems.
    Natural language queries like "I want to walk on treadmill" or "something for
    bad knees" are matched via ChromaDB embeddings alongside traditional fuzzy search.

    Results are cached in-memory (5min) and in the database (24hr).
    """
    start_time = time.time()

    cache_key = _make_cache_key(q, equipment, body_parts, limit)
    filters = {"equipment": equipment, "body_parts": body_parts}

    # --- Tier 0: In-memory cache ---
    cached = await _smart_search_cache.get(cache_key)
    if cached is not None:
        elapsed_ms = round((time.time() - start_time) * 1000, 1)
        return {
            "results": cached["results"][:limit],
            "query": q,
            "total": len(cached["results"]),
            "search_time_ms": elapsed_ms,
            "cache_hit": True,
            "correction": cached.get("correction"),
        }

    # --- Tier 0b: DB cache ---
    try:
        db = get_supabase_db()
        db_cached = db.client.rpc(
            "lookup_exercise_search_cache",
            {"p_query_hash": cache_key},
        ).execute()
        if db_cached.data:
            results_data = db_cached.data
            if isinstance(results_data, str):
                results_data = json.loads(results_data)
            if results_data:
                # Warm the in-memory cache
                await _smart_search_cache.set(cache_key, {"results": results_data, "correction": None})
                elapsed_ms = round((time.time() - start_time) * 1000, 1)
                return {
                    "results": results_data[:limit],
                    "query": q,
                    "total": len(results_data),
                    "search_time_ms": elapsed_ms,
                    "cache_hit": True,
                    "correction": None,
                }
    except Exception as e:
        logger.debug(f"DB cache lookup failed (proceeding with search): {e}")

    # --- Tier 1: Parallel search ---
    async def run_fuzzy():
        try:
            db = get_supabase_db()
            return await fetch_fuzzy_search_results(
                db,
                q,
                equipment_filter=equipment,
                body_part_filter=body_parts,
                limit=limit * 2,
            )
        except Exception as e:
            logger.warning(f"Fuzzy search failed: {e}")
            return []

    async def run_semantic():
        if not semantic:
            return []
        return await _run_semantic_search(q, equipment, body_parts, limit)

    fuzzy_results, semantic_results = await asyncio.gather(
        run_fuzzy(), run_semantic()
    )

    # --- Tier 2: RRF merge ---
    if semantic_results:
        merged = _reciprocal_rank_fusion(
            fuzzy_results,
            semantic_results,
            k=60,
            fuzzy_weight=1.0,
            semantic_weight=1.2,
        )
    else:
        # Semantic failed or disabled - use fuzzy only
        merged = []
        for rank, row in enumerate(fuzzy_results):
            exercise_dict = _exercise_row_to_dict(row)
            exercise_dict["relevance_score"] = round(1.0 / (1 + rank * 0.05), 4)
            exercise_dict["match_sources"] = ["fuzzy"]
            merged.append(exercise_dict)

    # Spelling correction from top fuzzy results
    correction = None
    if fuzzy_results:
        search_lower = q.lower().strip()
        top_name = fuzzy_results[0].get("name", "").lower()
        if search_lower not in top_name:
            correction = _extract_best_correction(search_lower, fuzzy_results[:5])

    # Trim to limit
    final_results = merged[:limit]

    # Cache the results
    cache_entry = {"results": merged, "correction": correction}
    await _smart_search_cache.set(cache_key, cache_entry)

    # Background DB cache write
    background_tasks.add_task(
        _write_cache_to_db, cache_key, q, filters, final_results
    )

    elapsed_ms = round((time.time() - start_time) * 1000, 1)

    return {
        "results": final_results,
        "query": q,
        "total": len(merged),
        "search_time_ms": elapsed_ms,
        "cache_hit": False,
        "correction": correction,
    }
