"""
Services module - Business logic layer.

Core services (facades):
- ProgressiveOverloadService: Weight/rep recommendations, 1RM tracking
- AdaptationService: Workout adaptation and split optimization

Specialized services (implementation):
- StrengthTrackingService: 1RM and PR tracking
- VolumeTrackingService: Weekly muscle group volume
- ProgressionService: Weight/rep progression logic
- WorkoutAdaptationService: Workout modifications
- SplitOptimizationService: Weekly split optimization
"""
from services.progressive_overload_service import ProgressiveOverloadService
from services.adaptation_service import AdaptationService

# Specialized services (import directly if needed)
from services.strength_tracking_service import StrengthTrackingService
from services.volume_tracking_service import VolumeTrackingService
from services.progression_service import ProgressionService
from services.workout_adaptation_service import WorkoutAdaptationService
from services.split_optimization_service import SplitOptimizationService

__all__ = [
    # Facades
    "ProgressiveOverloadService",
    "AdaptationService",
    # Specialized services
    "StrengthTrackingService",
    "VolumeTrackingService",
    "ProgressionService",
    "WorkoutAdaptationService",
    "SplitOptimizationService",
]
