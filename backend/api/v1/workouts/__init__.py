"""
Workout API module.

This module provides a unified router that combines all workout-related endpoints
from the following submodules:
- crud: Basic CRUD operations
- generation: AI-powered workout generation
- versioning: SCD2 version management
- suggestions: AI workout suggestions
- warmup_stretch: Warmup and stretch operations
- exercises: Exercise modifications
- exit_tracking: Workout exit/quit tracking
- program: Program customization
- program_history: Program history and snapshots
- weight_suggestions: AI weight suggestions
- set_adjustments: Set adjustment operations during active workouts
- today: Today's workout for quick start widget
- quick: Quick workouts (5-15 min) for busy users
- modifications: Active workout modifications (body part exclusion, exercise replacement)
- batch_generation: Batch upcoming workout retrieval for offline pre-caching
"""
from fastapi import APIRouter

from .crud import router as crud_router
from .generation import router as generation_router
from .versioning import router as versioning_router
from .suggestions import router as suggestions_router
from .warmup_stretch import router as warmup_stretch_router
from .exercises import router as exercises_router
from .exit_tracking import router as exit_tracking_router
from .program import router as program_router
from .program_history import router as program_history_router
from .weight_suggestions import router as weight_suggestions_router
from .smart_weights import router as smart_weights_router
from .set_adjustments import router as set_adjustments_router
from .today import router as today_router
from .quick import router as quick_router
from .batch_generation import router as batch_generation_router
from .modifications import router as modifications_router
from .rest_suggestions import router as rest_suggestions_router
from .fatigue_alerts import router as fatigue_alerts_router
from .parse_input import router as parse_input_router

# Create the combined router
router = APIRouter()

# Include all sub-routers
# IMPORTANT: Static routes must be included BEFORE dynamic routes like /{workout_id}
# Today's workout endpoint (quick start widget) - must come before CRUD
router.include_router(today_router)

# Quick workout endpoints (5-15 min workouts for busy users) - must come before CRUD
router.include_router(quick_router)

# Batch upcoming workout retrieval (offline pre-caching) - must come before CRUD
router.include_router(batch_generation_router)

# CRUD operations (basic CRUD) - has /{workout_id} which would match "today" and "quick"
router.include_router(crud_router)

# Generation endpoints
router.include_router(generation_router)

# Versioning (SCD2) endpoints
router.include_router(versioning_router)

# AI suggestions endpoints
router.include_router(suggestions_router)

# Warmup and stretch endpoints
router.include_router(warmup_stretch_router)

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

# Smart weight auto-fill endpoints (pre-workout 1RM-based suggestions)
router.include_router(smart_weights_router)

# Set adjustment endpoints (tracking set modifications during workouts)
router.include_router(set_adjustments_router)

# Workout modification endpoints (body part exclusion, exercise replacement)
router.include_router(modifications_router)

# AI rest time suggestion endpoints
router.include_router(rest_suggestions_router)

# Fatigue detection and next set preview endpoints
router.include_router(fatigue_alerts_router)

# AI workout input parsing (text/image/voice to exercises)
router.include_router(parse_input_router)

# Re-export commonly used utilities
from .utils import (
    row_to_workout,
    log_workout_change,
    index_workout_to_rag,
    parse_json_field,
    get_recently_used_exercises,
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
    'get_workout_rag_service',
    'enrich_exercises_with_video_urls',
]
