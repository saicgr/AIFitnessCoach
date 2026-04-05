"""
Percentage Training Service - Train at a percentage of your 1RM.

Allows users to:
- Store their 1RMs (manual, calculated, or tested)
- Set global training intensity (e.g., train at 70% of max)
- Set per-exercise intensity overrides
- Calculate working weights based on 1RM and intensity
- Auto-populate 1RMs from workout history
"""

from .percentage_training_service_helpers import (  # noqa: F401
    PercentageTrainingService,
)
from typing import Dict, List, Optional, Tuple
from datetime import datetime, timedelta
from dataclasses import dataclass
from decimal import Decimal
import logging

from .strength_calculator_service import strength_calculator_service

logger = logging.getLogger(__name__)


@dataclass
class UserExercise1RM:
    """User's stored 1RM for an exercise."""
    exercise_name: str
    one_rep_max_kg: float
    source: str  # 'manual', 'calculated', 'tested'
    confidence: float  # 0.0 to 1.0
    last_tested_at: Optional[datetime] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


@dataclass
class TrainingIntensitySettings:
    """User's training intensity preferences."""
    global_intensity_percent: int  # 50-100
    exercise_overrides: Dict[str, int]  # exercise_name -> percent


@dataclass
class WorkingWeightResult:
    """Calculated working weight based on 1RM and intensity."""
    exercise_name: str
    one_rep_max_kg: float
    intensity_percent: int
    working_weight_kg: float
    is_from_override: bool
    # New fields for linked exercises feature
    source_type: str = 'direct'  # 'direct', 'linked', 'muscle_group_fallback'
    source_exercise: Optional[str] = None  # Name of exercise 1RM was derived from
    equipment_multiplier: float = 1.0  # Multiplier applied for equipment difference


@dataclass
class LinkedExercise:
    """User-defined link between exercises for 1RM sharing."""
    id: str
    user_id: str
    primary_exercise_name: str  # The benchmark exercise with stored 1RM
    linked_exercise_name: str   # The exercise that uses the benchmark's 1RM
    strength_multiplier: float  # How weight scales (0.5 - 1.0, default 0.85)
    relationship_type: str      # 'variant', 'angle', 'equipment_swap', 'progression'
    notes: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


