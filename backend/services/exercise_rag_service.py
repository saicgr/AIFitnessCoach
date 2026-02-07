"""
Exercise RAG Service - Intelligent exercise selection using embeddings.

This module re-exports all functionality from the modular exercise_rag package
for backwards compatibility.

This service:
1. Indexes all exercises from exercise_library with embeddings
2. Uses AI to select the best exercises based on user profile, goals, equipment
3. Considers exercise variety, muscle balance, and progression

Also re-exports RAGCache and module-level cache instances from rag_service
so that the exercise_rag package can use shared caching for embeddings.
"""

# Re-export everything from the exercise_rag package
from .exercise_rag import (
    # Utils
    clean_exercise_name_for_display,
    infer_equipment_from_name,
    # Filters
    FULL_GYM_EQUIPMENT,
    HOME_GYM_EQUIPMENT,
    INJURY_CONTRAINDICATIONS,
    pre_filter_by_injuries,
    filter_by_equipment,
    is_similar_exercise,
    get_base_exercise_name,
    # Search
    build_search_query,
    # Service
    ExerciseRAGService,
    get_exercise_rag_service,
)

# Re-export caching utilities from rag_service for shared use
from .rag_service import RAGCache, _embedding_cache, _query_cache

# Maintain backwards compatibility with old function names
_clean_exercise_name_for_display = clean_exercise_name_for_display
_infer_equipment_from_name = infer_equipment_from_name

__all__ = [
    # Utils
    "clean_exercise_name_for_display",
    "infer_equipment_from_name",
    "_clean_exercise_name_for_display",
    "_infer_equipment_from_name",
    # Filters
    "FULL_GYM_EQUIPMENT",
    "HOME_GYM_EQUIPMENT",
    "INJURY_CONTRAINDICATIONS",
    "pre_filter_by_injuries",
    "filter_by_equipment",
    "is_similar_exercise",
    "get_base_exercise_name",
    # Search
    "build_search_query",
    # Service
    "ExerciseRAGService",
    "get_exercise_rag_service",
    # Caching (shared across RAG services)
    "RAGCache",
    "_embedding_cache",
    "_query_cache",
]
