"""
Exercise RAG Service Package.

This package contains the modular implementation of the Exercise RAG service:
- utils: Utility functions for exercise name cleaning and equipment inference
- filters: Exercise filtering by equipment, injuries, and similarity
- indexing: Exercise indexing to ChromaDB
- search: Exercise search and AI selection
- service: Main ExerciseRAGService class
"""

from .utils import (
    clean_exercise_name_for_display,
    infer_equipment_from_name,
)

from .filters import (
    FULL_GYM_EQUIPMENT,
    HOME_GYM_EQUIPMENT,
    INJURY_CONTRAINDICATIONS,
    pre_filter_by_injuries,
    filter_by_equipment,
    is_similar_exercise,
    get_base_exercise_name,
)

from .search import build_search_query

from .service import ExerciseRAGService, get_exercise_rag_service

__all__ = [
    # Utils
    "clean_exercise_name_for_display",
    "infer_equipment_from_name",
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
]
