"""
Library API module.

This module provides a unified router that combines all library-related endpoints
from the following submodules:
- exercises: Exercise library operations
- programs: Program library operations
"""
from fastapi import APIRouter

from .exercises import router as exercises_router
from .programs import router as programs_router

# Create the combined router
router = APIRouter()

# Include all sub-routers
router.include_router(exercises_router)
router.include_router(programs_router)

# Re-export models and utilities
from .models import (
    LibraryExercise,
    LibraryProgram,
    ExercisesByBodyPart,
    ProgramsByCategory,
)
from .utils import (
    fetch_all_rows,
    normalize_body_part,
    row_to_library_exercise,
    row_to_library_program,
    derive_exercise_type,
    derive_goals,
    derive_suitable_for,
    derive_avoids,
)

__all__ = [
    'router',
    'LibraryExercise',
    'LibraryProgram',
    'ExercisesByBodyPart',
    'ProgramsByCategory',
    'fetch_all_rows',
    'normalize_body_part',
    'row_to_library_exercise',
    'row_to_library_program',
    'derive_exercise_type',
    'derive_goals',
    'derive_suitable_for',
    'derive_avoids',
]
