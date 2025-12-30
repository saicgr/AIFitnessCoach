"""
Percentage Training Service - Train at a percentage of your 1RM.

Allows users to:
- Store their 1RMs (manual, calculated, or tested)
- Set global training intensity (e.g., train at 70% of max)
- Set per-exercise intensity overrides
- Calculate working weights based on 1RM and intensity
- Auto-populate 1RMs from workout history
"""
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


class PercentageTrainingService:
    """
    Service for percentage-based 1RM training.

    Allows users to train at a specific percentage of their max lifts.
    """

    # RPE to Percentage mapping (industry standard)
    # RPE 10 = 100%, RPE 6 = 80%
    RPE_TO_PERCENTAGE = {
        10.0: 100,
        9.5: 98,
        9.0: 96,
        8.5: 94,
        8.0: 92,
        7.5: 89,
        7.0: 86,
        6.5: 83,
        6.0: 80,
        5.5: 77,
        5.0: 74,
    }

    # Intensity descriptions
    INTENSITY_DESCRIPTIONS = {
        (50, 60): "Light / Recovery",
        (61, 70): "Moderate / Endurance",
        (71, 80): "Working Weight / Hypertrophy",
        (81, 90): "Heavy / Strength",
        (91, 100): "Near Max / Peaking",
    }

    # Equipment-based weight increments for rounding
    WEIGHT_INCREMENTS = {
        'barbell': 2.5,    # Standard barbell plates
        'dumbbell': 2.0,   # Dumbbell increments (per hand)
        'machine': 5.0,    # Most machines have 5kg increments
        'cable': 2.5,      # Cable stacks
        'kettlebell': 4.0, # Kettlebells jump 4kg typically
        'bodyweight': 0,   # No rounding needed
    }

    def __init__(self, supabase_client=None):
        """Initialize with optional Supabase client for database operations."""
        self.supabase = supabase_client

    # -------------------------------------------------------------------------
    # Working Weight Calculation
    # -------------------------------------------------------------------------

    def calculate_working_weight(
        self,
        one_rep_max_kg: float,
        intensity_percent: int,
        equipment_type: str = 'barbell',
    ) -> float:
        """
        Calculate working weight from 1RM and intensity percentage.

        Args:
            one_rep_max_kg: User's 1RM for the exercise
            intensity_percent: Desired training intensity (50-100)
            equipment_type: Type of equipment for rounding

        Returns:
            Working weight rounded to equipment increment
        """
        if intensity_percent < 50:
            intensity_percent = 50
        elif intensity_percent > 100:
            intensity_percent = 100

        raw_weight = one_rep_max_kg * (intensity_percent / 100)

        # Round to equipment increment
        increment = self.WEIGHT_INCREMENTS.get(equipment_type, 2.5)
        if increment > 0:
            rounded_weight = round(raw_weight / increment) * increment
        else:
            rounded_weight = raw_weight

        return round(rounded_weight, 1)

    def get_intensity_description(self, intensity_percent: int) -> str:
        """Get description for an intensity percentage."""
        for (low, high), description in self.INTENSITY_DESCRIPTIONS.items():
            if low <= intensity_percent <= high:
                return description
        return "Custom Intensity"

    def rpe_to_percentage(self, rpe: float) -> int:
        """Convert RPE to percentage of 1RM."""
        if rpe in self.RPE_TO_PERCENTAGE:
            return self.RPE_TO_PERCENTAGE[rpe]

        # Interpolate for non-standard RPE values
        if rpe >= 10:
            return 100
        if rpe <= 5:
            return 74

        # Linear interpolation
        lower_rpe = int(rpe * 2) / 2  # Round down to nearest 0.5
        upper_rpe = lower_rpe + 0.5

        if lower_rpe in self.RPE_TO_PERCENTAGE and upper_rpe in self.RPE_TO_PERCENTAGE:
            lower_pct = self.RPE_TO_PERCENTAGE[lower_rpe]
            upper_pct = self.RPE_TO_PERCENTAGE[upper_rpe]
            progress = (rpe - lower_rpe) / 0.5
            return int(lower_pct + (upper_pct - lower_pct) * progress)

        return 80  # Default to working weight

    # -------------------------------------------------------------------------
    # Database Operations: 1RM Storage
    # -------------------------------------------------------------------------

    async def get_user_1rms(self, user_id: str) -> List[UserExercise1RM]:
        """Get all stored 1RMs for a user."""
        if not self.supabase:
            return []

        result = self.supabase.table('user_exercise_1rms').select('*').eq(
            'user_id', user_id
        ).execute()

        return [
            UserExercise1RM(
                exercise_name=row['exercise_name'],
                one_rep_max_kg=float(row['one_rep_max_kg']),
                source=row['source'],
                confidence=float(row.get('confidence', 1.0)),
                last_tested_at=row.get('last_tested_at'),
                created_at=row.get('created_at'),
                updated_at=row.get('updated_at'),
            )
            for row in result.data
        ]

    async def get_user_1rm(self, user_id: str, exercise_name: str) -> Optional[UserExercise1RM]:
        """Get stored 1RM for a specific exercise."""
        if not self.supabase:
            return None

        result = self.supabase.table('user_exercise_1rms').select('*').eq(
            'user_id', user_id
        ).eq('exercise_name', exercise_name).single().execute()

        if not result.data:
            return None

        row = result.data
        return UserExercise1RM(
            exercise_name=row['exercise_name'],
            one_rep_max_kg=float(row['one_rep_max_kg']),
            source=row['source'],
            confidence=float(row.get('confidence', 1.0)),
            last_tested_at=row.get('last_tested_at'),
            created_at=row.get('created_at'),
            updated_at=row.get('updated_at'),
        )

    async def set_user_1rm(
        self,
        user_id: str,
        exercise_name: str,
        one_rep_max_kg: float,
        source: str = 'manual',
        confidence: float = 1.0,
        last_tested_at: Optional[datetime] = None,
    ) -> UserExercise1RM:
        """Set or update a user's 1RM for an exercise."""
        if not self.supabase:
            raise ValueError("Supabase client not configured")

        data = {
            'user_id': user_id,
            'exercise_name': exercise_name,
            'one_rep_max_kg': one_rep_max_kg,
            'source': source,
            'confidence': confidence,
        }

        if last_tested_at:
            data['last_tested_at'] = last_tested_at.isoformat()
        elif source == 'tested':
            data['last_tested_at'] = datetime.utcnow().isoformat()

        # Upsert (insert or update)
        result = self.supabase.table('user_exercise_1rms').upsert(
            data,
            on_conflict='user_id,exercise_name'
        ).execute()

        row = result.data[0]
        return UserExercise1RM(
            exercise_name=row['exercise_name'],
            one_rep_max_kg=float(row['one_rep_max_kg']),
            source=row['source'],
            confidence=float(row.get('confidence', 1.0)),
            last_tested_at=row.get('last_tested_at'),
            created_at=row.get('created_at'),
            updated_at=row.get('updated_at'),
        )

    async def delete_user_1rm(self, user_id: str, exercise_name: str) -> bool:
        """Delete a user's stored 1RM for an exercise."""
        if not self.supabase:
            return False

        self.supabase.table('user_exercise_1rms').delete().eq(
            'user_id', user_id
        ).eq('exercise_name', exercise_name).execute()

        return True

    # -------------------------------------------------------------------------
    # Database Operations: Intensity Preferences
    # -------------------------------------------------------------------------

    async def get_training_intensity(
        self,
        user_id: str,
        exercise_name: Optional[str] = None,
    ) -> int:
        """
        Get user's training intensity preference.

        If exercise_name is provided, returns the override if set,
        otherwise returns global preference.
        """
        if not self.supabase:
            return 75  # Default

        # Check for exercise-specific override first
        if exercise_name:
            result = self.supabase.table('exercise_intensity_overrides').select(
                'intensity_percent'
            ).eq('user_id', user_id).eq('exercise_name', exercise_name).single().execute()

            if result.data:
                return result.data['intensity_percent']

        # Fall back to global preference
        result = self.supabase.table('users').select(
            'training_intensity_percent'
        ).eq('id', user_id).single().execute()

        if result.data:
            return result.data.get('training_intensity_percent', 75)

        return 75

    async def set_global_training_intensity(
        self,
        user_id: str,
        intensity_percent: int,
    ) -> int:
        """Set user's global training intensity preference."""
        if not self.supabase:
            raise ValueError("Supabase client not configured")

        # Clamp to valid range
        intensity_percent = max(50, min(100, intensity_percent))

        self.supabase.table('users').update({
            'training_intensity_percent': intensity_percent
        }).eq('id', user_id).execute()

        return intensity_percent

    async def set_exercise_intensity_override(
        self,
        user_id: str,
        exercise_name: str,
        intensity_percent: int,
    ) -> int:
        """Set intensity override for a specific exercise."""
        if not self.supabase:
            raise ValueError("Supabase client not configured")

        # Clamp to valid range
        intensity_percent = max(50, min(100, intensity_percent))

        self.supabase.table('exercise_intensity_overrides').upsert({
            'user_id': user_id,
            'exercise_name': exercise_name,
            'intensity_percent': intensity_percent,
        }, on_conflict='user_id,exercise_name').execute()

        return intensity_percent

    async def delete_exercise_intensity_override(
        self,
        user_id: str,
        exercise_name: str,
    ) -> bool:
        """Remove intensity override for a specific exercise."""
        if not self.supabase:
            return False

        self.supabase.table('exercise_intensity_overrides').delete().eq(
            'user_id', user_id
        ).eq('exercise_name', exercise_name).execute()

        return True

    async def get_all_intensity_overrides(
        self,
        user_id: str,
    ) -> Dict[str, int]:
        """Get all exercise-specific intensity overrides for a user."""
        if not self.supabase:
            return {}

        result = self.supabase.table('exercise_intensity_overrides').select(
            'exercise_name,intensity_percent'
        ).eq('user_id', user_id).execute()

        return {
            row['exercise_name']: row['intensity_percent']
            for row in result.data
        }

    # -------------------------------------------------------------------------
    # Auto-Populate 1RMs from Workout History
    # -------------------------------------------------------------------------

    async def auto_populate_1rms(
        self,
        user_id: str,
        days_lookback: int = 90,
        min_confidence: float = 0.7,
    ) -> int:
        """
        Auto-calculate 1RMs from workout history.

        Looks at completed workout sets and estimates 1RM using
        the strength calculator service.

        Args:
            user_id: User ID
            days_lookback: How far back to look in workout history
            min_confidence: Minimum confidence threshold to save

        Returns:
            Number of 1RMs calculated and saved
        """
        if not self.supabase:
            return 0

        # Get workout history
        cutoff_date = (datetime.utcnow() - timedelta(days=days_lookback)).isoformat()

        result = self.supabase.table('completed_exercises').select('''
            exercise_name,
            weight_kg,
            reps,
            created_at
        ''').eq('user_id', user_id).gte('created_at', cutoff_date).execute()

        if not result.data:
            return 0

        # Group by exercise and find best estimated 1RM
        exercise_best: Dict[str, Tuple[float, float, datetime]] = {}  # name -> (1rm, confidence, date)

        for row in result.data:
            exercise_name = row['exercise_name']
            weight_kg = float(row.get('weight_kg', 0))
            reps = int(row.get('reps', 0))

            if weight_kg <= 0 or reps <= 0 or reps > 20:
                continue

            # Calculate estimated 1RM
            one_rm_result = strength_calculator_service.calculate_1rm(
                weight_kg, reps, formula='brzycki'
            )

            # Only consider if confidence meets threshold
            if one_rm_result.confidence < min_confidence:
                continue

            # Update if better than existing
            if exercise_name not in exercise_best:
                exercise_best[exercise_name] = (
                    one_rm_result.estimated_1rm,
                    one_rm_result.confidence,
                    datetime.fromisoformat(row['created_at'].replace('Z', '+00:00')),
                )
            else:
                existing_1rm, existing_conf, _ = exercise_best[exercise_name]
                # Prefer higher 1RM with similar confidence, or higher confidence
                if (one_rm_result.estimated_1rm > existing_1rm and
                    one_rm_result.confidence >= existing_conf * 0.9):
                    exercise_best[exercise_name] = (
                        one_rm_result.estimated_1rm,
                        one_rm_result.confidence,
                        datetime.fromisoformat(row['created_at'].replace('Z', '+00:00')),
                    )

        # Save calculated 1RMs
        saved_count = 0
        for exercise_name, (one_rm, confidence, tested_date) in exercise_best.items():
            try:
                await self.set_user_1rm(
                    user_id=user_id,
                    exercise_name=exercise_name,
                    one_rep_max_kg=one_rm,
                    source='calculated',
                    confidence=confidence,
                    last_tested_at=tested_date,
                )
                saved_count += 1
            except Exception as e:
                logger.error(f"Error saving 1RM for {exercise_name}: {e}")

        return saved_count

    # -------------------------------------------------------------------------
    # Workout Integration: Calculate Working Weights
    # -------------------------------------------------------------------------

    async def calculate_working_weights_for_workout(
        self,
        user_id: str,
        exercises: List[str],
        equipment_types: Optional[Dict[str, str]] = None,
    ) -> List[WorkingWeightResult]:
        """
        Calculate working weights for a list of exercises.

        Uses stored 1RMs and intensity preferences to calculate
        target working weights.

        Args:
            user_id: User ID
            exercises: List of exercise names
            equipment_types: Optional mapping of exercise -> equipment type

        Returns:
            List of WorkingWeightResult for exercises with known 1RMs
        """
        results = []

        # Get user's 1RMs
        user_1rms = {
            rm.exercise_name.lower(): rm
            for rm in await self.get_user_1rms(user_id)
        }

        # Get intensity overrides
        overrides = await self.get_all_intensity_overrides(user_id)

        # Get global intensity
        global_intensity = await self.get_training_intensity(user_id)

        for exercise in exercises:
            exercise_lower = exercise.lower()

            # Check if we have a 1RM for this exercise
            if exercise_lower not in user_1rms:
                continue

            user_1rm = user_1rms[exercise_lower]

            # Get intensity (override or global)
            is_override = exercise in overrides or exercise_lower in overrides
            intensity = overrides.get(
                exercise,
                overrides.get(exercise_lower, global_intensity)
            )

            # Get equipment type
            equipment = 'barbell'
            if equipment_types:
                equipment = equipment_types.get(exercise, 'barbell')

            # Calculate working weight
            working_weight = self.calculate_working_weight(
                user_1rm.one_rep_max_kg,
                intensity,
                equipment,
            )

            results.append(WorkingWeightResult(
                exercise_name=exercise,
                one_rep_max_kg=user_1rm.one_rep_max_kg,
                intensity_percent=intensity,
                working_weight_kg=working_weight,
                is_from_override=is_override,
            ))

        return results


# Singleton instance (without Supabase - will be initialized in API routes)
percentage_training_service = PercentageTrainingService()
