"""
Workout API module.

This module provides a unified router that combines all workout-related endpoints
from the following submodules:
- crud: Basic CRUD operations
- generation: AI-powered workout generation
- versioning: SCD2 version management
- suggestions: AI workout suggestions
- warmup_stretch: Warmup and stretch operations
- background: Background job management
- exercises: Exercise modifications
- exit_tracking: Workout exit/quit tracking
- program: Program customization
- program_history: Program history and snapshots
- weight_suggestions: AI weight suggestions
- set_adjustments: Set adjustment operations during active workouts
- today: Today's workout for quick start widget
- quick: Quick workouts (5-15 min) for busy users
- modifications: Active workout modifications (body part exclusion, exercise replacement)
"""
from fastapi import APIRouter

from .crud import router as crud_router
from .generation import router as generation_router
from .versioning import router as versioning_router
from .suggestions import router as suggestions_router
from .warmup_stretch import router as warmup_stretch_router
from .background import router as background_router
from .exercises import router as exercises_router
from .exit_tracking import router as exit_tracking_router
from .program import router as program_router
from .program_history import router as program_history_router
from .weight_suggestions import router as weight_suggestions_router
from .set_adjustments import router as set_adjustments_router
from .today import router as today_router
from .quick import router as quick_router
from .modifications import router as modifications_router

# Create the combined router
router = APIRouter()

# Include all sub-routers
# CRUD operations (basic CRUD)
router.include_router(crud_router)

# Generation endpoints
router.include_router(generation_router)

# Versioning (SCD2) endpoints
router.include_router(versioning_router)

# AI suggestions endpoints
router.include_router(suggestions_router)

# Warmup and stretch endpoints
router.include_router(warmup_stretch_router)

# Background job endpoints
router.include_router(background_router)

# Exercise modification endpoints
router.include_router(exercises_router)

# Exit tracking endpoints
router.include_router(exit_tracking_router)

# Program customization endpoints
router.include_router(program_router)

# Program history endpoints
router.include_router(program_history_router)

# AI weight suggestion endpoints
router.include_router(weight_suggestions_router)

# Set adjustment endpoints (tracking set modifications during workouts)
router.include_router(set_adjustments_router)

# Today's workout endpoint (quick start widget)
router.include_router(today_router)

# Quick workout endpoints (5-15 min workouts for busy users)
router.include_router(quick_router)

# Workout modification endpoints (body part exclusion, exercise replacement)
router.include_router(modifications_router)

# Re-export commonly used utilities
from .utils import (
    row_to_workout,
    log_workout_change,
    index_workout_to_rag,
    parse_json_field,
    get_recently_used_exercises,
    get_workout_focus,
    calculate_workout_date,
    calculate_monthly_dates,
    extract_name_words,
    get_workout_rag_service,
    enrich_exercises_with_video_urls,
)

__all__ = [
    'router',
    'row_to_workout',
    'log_workout_change',
    'index_workout_to_rag',
    'parse_json_field',
    'get_recently_used_exercises',
    'get_workout_focus',
    'calculate_workout_date',
    'calculate_monthly_dates',
    'extract_name_words',
    'get_workout_rag_service',
    'enrich_exercises_with_video_urls',
]
