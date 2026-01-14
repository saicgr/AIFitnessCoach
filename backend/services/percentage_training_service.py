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

    # Equipment multipliers for linked exercise weight scaling
    # Used when calculating working weight from a benchmark exercise with different equipment
    EQUIPMENT_MULTIPLIERS = {
        'barbell': 1.0,      # Reference baseline
        'dumbbell': 0.85,    # Dumbbells require more stabilization (~85% of barbell)
        'machine': 0.90,     # Fixed path, slightly easier (~90% of barbell)
        'cable': 0.80,       # Cable resistance curve differs (~80% of barbell)
        'kettlebell': 0.75,  # Different mechanics (~75% of barbell)
        'bodyweight': 0.70,  # Bodyweight progressions (~70% of barbell)
        'smith_machine': 0.95,  # Guided barbell (~95% of barbell)
        'ez_bar': 0.95,      # Curved bar, similar to barbell (~95%)
        'trap_bar': 1.0,     # Similar loading to barbell
        'resistance_band': 0.60,  # Variable resistance (~60% of barbell)
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
    # Linked Exercises: CRUD Operations
    # -------------------------------------------------------------------------

    async def get_linked_exercises(
        self,
        user_id: str,
        primary_exercise_name: Optional[str] = None,
    ) -> List[LinkedExercise]:
        """
        Get linked exercises for a user.

        Args:
            user_id: User ID
            primary_exercise_name: Optional filter by primary exercise

        Returns:
            List of LinkedExercise objects
        """
        if not self.supabase:
            return []

        query = self.supabase.table('exercise_relationships').select('*').eq(
            'user_id', user_id
        )

        if primary_exercise_name:
            query = query.eq('primary_exercise_name', primary_exercise_name)

        result = query.execute()

        return [
            LinkedExercise(
                id=row['id'],
                user_id=row['user_id'],
                primary_exercise_name=row['primary_exercise_name'],
                linked_exercise_name=row['linked_exercise_name'],
                strength_multiplier=float(row.get('strength_multiplier', 0.85)),
                relationship_type=row.get('relationship_type', 'variant'),
                notes=row.get('notes'),
                created_at=row.get('created_at'),
                updated_at=row.get('updated_at'),
            )
            for row in result.data
        ]

    async def create_linked_exercise(
        self,
        user_id: str,
        primary_exercise_name: str,
        linked_exercise_name: str,
        strength_multiplier: float = 0.85,
        relationship_type: str = 'variant',
        notes: Optional[str] = None,
    ) -> LinkedExercise:
        """
        Create a link between two exercises for 1RM sharing.

        Args:
            user_id: User ID
            primary_exercise_name: The benchmark exercise with stored 1RM
            linked_exercise_name: The exercise that will use the benchmark's 1RM
            strength_multiplier: How weight scales (0.5 - 1.0)
            relationship_type: Type of relationship
            notes: Optional notes about the link

        Returns:
            Created LinkedExercise object
        """
        if not self.supabase:
            raise ValueError("Supabase client not configured")

        # Clamp multiplier to valid range
        strength_multiplier = max(0.5, min(1.0, strength_multiplier))

        data = {
            'user_id': user_id,
            'primary_exercise_name': primary_exercise_name,
            'linked_exercise_name': linked_exercise_name,
            'strength_multiplier': strength_multiplier,
            'relationship_type': relationship_type,
            'notes': notes,
        }

        result = self.supabase.table('exercise_relationships').upsert(
            data,
            on_conflict='user_id,primary_exercise_name,linked_exercise_name'
        ).execute()

        row = result.data[0]
        return LinkedExercise(
            id=row['id'],
            user_id=row['user_id'],
            primary_exercise_name=row['primary_exercise_name'],
            linked_exercise_name=row['linked_exercise_name'],
            strength_multiplier=float(row.get('strength_multiplier', 0.85)),
            relationship_type=row.get('relationship_type', 'variant'),
            notes=row.get('notes'),
            created_at=row.get('created_at'),
            updated_at=row.get('updated_at'),
        )

    async def update_linked_exercise(
        self,
        link_id: str,
        user_id: str,
        strength_multiplier: Optional[float] = None,
        relationship_type: Optional[str] = None,
        notes: Optional[str] = None,
    ) -> Optional[LinkedExercise]:
        """
        Update a linked exercise relationship.

        Args:
            link_id: The relationship ID
            user_id: User ID (for security check)
            strength_multiplier: New multiplier (optional)
            relationship_type: New relationship type (optional)
            notes: New notes (optional)

        Returns:
            Updated LinkedExercise or None if not found
        """
        if not self.supabase:
            raise ValueError("Supabase client not configured")

        update_data = {}
        if strength_multiplier is not None:
            update_data['strength_multiplier'] = max(0.5, min(1.0, strength_multiplier))
        if relationship_type is not None:
            update_data['relationship_type'] = relationship_type
        if notes is not None:
            update_data['notes'] = notes

        if not update_data:
            return None

        result = self.supabase.table('exercise_relationships').update(
            update_data
        ).eq('id', link_id).eq('user_id', user_id).execute()

        if not result.data:
            return None

        row = result.data[0]
        return LinkedExercise(
            id=row['id'],
            user_id=row['user_id'],
            primary_exercise_name=row['primary_exercise_name'],
            linked_exercise_name=row['linked_exercise_name'],
            strength_multiplier=float(row.get('strength_multiplier', 0.85)),
            relationship_type=row.get('relationship_type', 'variant'),
            notes=row.get('notes'),
            created_at=row.get('created_at'),
            updated_at=row.get('updated_at'),
        )

    async def delete_linked_exercise(
        self,
        link_id: str,
        user_id: str,
    ) -> bool:
        """
        Delete a linked exercise relationship.

        Args:
            link_id: The relationship ID
            user_id: User ID (for security check)

        Returns:
            True if deleted, False otherwise
        """
        if not self.supabase:
            return False

        self.supabase.table('exercise_relationships').delete().eq(
            'id', link_id
        ).eq('user_id', user_id).execute()

        return True

    # -------------------------------------------------------------------------
    # Linked Exercises: Lookup Methods
    # -------------------------------------------------------------------------

    async def get_primary_muscle(self, exercise_name: str) -> Optional[str]:
        """
        Get primary muscle group for an exercise from the database.

        Args:
            exercise_name: Name of the exercise

        Returns:
            Primary muscle group or None if not found
        """
        if not self.supabase:
            return None

        result = self.supabase.table('exercises').select(
            'primary_muscle'
        ).ilike('name', exercise_name).limit(1).execute()

        if result.data:
            return result.data[0].get('primary_muscle')
        return None

    async def get_exercise_equipment(self, exercise_name: str) -> Optional[str]:
        """
        Get equipment type for an exercise from the database.

        Args:
            exercise_name: Name of the exercise

        Returns:
            Equipment type or None if not found
        """
        if not self.supabase:
            return None

        result = self.supabase.table('exercises').select(
            'equipment'
        ).ilike('name', exercise_name).limit(1).execute()

        if result.data:
            return result.data[0].get('equipment')
        return None

    async def find_1rm_via_link(
        self,
        user_id: str,
        exercise_name: str,
    ) -> Optional[Tuple[float, str, float]]:
        """
        Find a 1RM for an exercise via explicit user-defined links.

        Args:
            user_id: User ID
            exercise_name: Name of the exercise to find 1RM for

        Returns:
            Tuple of (1rm_kg, source_exercise_name, multiplier) or None
        """
        if not self.supabase:
            return None

        # Check if this exercise is linked to any primary exercise
        result = self.supabase.table('exercise_relationships').select(
            'primary_exercise_name,strength_multiplier'
        ).eq('user_id', user_id).ilike(
            'linked_exercise_name', exercise_name
        ).limit(1).execute()

        if not result.data:
            return None

        link = result.data[0]
        primary_name = link['primary_exercise_name']
        multiplier = float(link.get('strength_multiplier', 0.85))

        # Get the 1RM for the primary exercise
        rm_result = self.supabase.table('user_exercise_1rms').select(
            'one_rep_max_kg'
        ).eq('user_id', user_id).ilike(
            'exercise_name', primary_name
        ).limit(1).execute()

        if rm_result.data:
            one_rm = float(rm_result.data[0]['one_rep_max_kg'])
            return (one_rm * multiplier, primary_name, multiplier)

        return None

    async def find_1rm_by_muscle_group(
        self,
        user_id: str,
        exercise_name: str,
        target_equipment: Optional[str] = None,
    ) -> Optional[Tuple[float, str, float]]:
        """
        Find a 1RM for an exercise by looking up related exercises in the same muscle group.

        This is the fallback when no direct 1RM or explicit link exists.

        Args:
            user_id: User ID
            exercise_name: Name of the exercise to find 1RM for
            target_equipment: Equipment type of the target exercise (for multiplier)

        Returns:
            Tuple of (estimated_1rm_kg, source_exercise_name, equipment_multiplier) or None
        """
        if not self.supabase:
            return None

        # Get the target exercise's primary muscle
        primary_muscle = await self.get_primary_muscle(exercise_name)
        if not primary_muscle:
            return None

        # Get target equipment if not provided
        if not target_equipment:
            target_equipment = await self.get_exercise_equipment(exercise_name) or 'barbell'

        # Get all exercises with the same primary muscle
        exercises_result = self.supabase.table('exercises').select(
            'name,equipment'
        ).eq('primary_muscle', primary_muscle).execute()

        if not exercises_result.data:
            return None

        exercise_lookup = {
            e['name'].lower(): e.get('equipment', 'barbell')
            for e in exercises_result.data
        }

        # Get user's 1RMs for these exercises, ordered by confidence
        user_1rms_result = self.supabase.table('user_exercise_1rms').select(
            'exercise_name,one_rep_max_kg,confidence'
        ).eq('user_id', user_id).order('confidence', desc=True).execute()

        if not user_1rms_result.data:
            return None

        # Find the best matching 1RM in this muscle group
        for rm in user_1rms_result.data:
            rm_exercise_lower = rm['exercise_name'].lower()
            if rm_exercise_lower in exercise_lookup:
                source_equipment = exercise_lookup[rm_exercise_lower]
                source_1rm = float(rm['one_rep_max_kg'])

                # Calculate equipment multiplier
                source_mult = self.EQUIPMENT_MULTIPLIERS.get(source_equipment, 1.0)
                target_mult = self.EQUIPMENT_MULTIPLIERS.get(target_equipment, 1.0)

                # Scale from source equipment to target equipment
                # If going from barbell (1.0) to dumbbell (0.85), multiply by 0.85
                # If going from dumbbell (0.85) to barbell (1.0), multiply by 1.0/0.85
                if source_mult > 0:
                    equipment_ratio = target_mult / source_mult
                else:
                    equipment_ratio = 1.0

                estimated_1rm = source_1rm * equipment_ratio
                return (estimated_1rm, rm['exercise_name'], equipment_ratio)

        return None

    async def get_suggested_exercises_for_linking(
        self,
        user_id: str,
        primary_exercise_name: str,
        limit: int = 10,
    ) -> List[Dict[str, any]]:
        """
        Get suggested exercises to link to a primary exercise.

        Suggests exercises in the same muscle group that don't have their own 1RM.

        Args:
            user_id: User ID
            primary_exercise_name: The benchmark exercise
            limit: Maximum number of suggestions

        Returns:
            List of exercise suggestions with name, equipment, and suggested multiplier
        """
        if not self.supabase:
            return []

        # Get primary muscle of the primary exercise
        primary_muscle = await self.get_primary_muscle(primary_exercise_name)
        if not primary_muscle:
            return []

        # Get primary exercise's equipment
        primary_equipment = await self.get_exercise_equipment(primary_exercise_name) or 'barbell'

        # Get all exercises in the same muscle group
        exercises_result = self.supabase.table('exercises').select(
            'name,equipment,primary_muscle,secondary_muscles'
        ).eq('primary_muscle', primary_muscle).limit(50).execute()

        if not exercises_result.data:
            return []

        # Get user's existing 1RMs
        user_1rms_result = self.supabase.table('user_exercise_1rms').select(
            'exercise_name'
        ).eq('user_id', user_id).execute()

        existing_1rms = {rm['exercise_name'].lower() for rm in user_1rms_result.data or []}

        # Get existing links
        links_result = self.supabase.table('exercise_relationships').select(
            'linked_exercise_name'
        ).eq('user_id', user_id).eq('primary_exercise_name', primary_exercise_name).execute()

        existing_links = {link['linked_exercise_name'].lower() for link in links_result.data or []}

        suggestions = []
        for exercise in exercises_result.data:
            name = exercise['name']
            name_lower = name.lower()

            # Skip if it's the primary exercise, has its own 1RM, or is already linked
            if (name_lower == primary_exercise_name.lower() or
                name_lower in existing_1rms or
                name_lower in existing_links):
                continue

            equipment = exercise.get('equipment', 'barbell')
            primary_mult = self.EQUIPMENT_MULTIPLIERS.get(primary_equipment, 1.0)
            target_mult = self.EQUIPMENT_MULTIPLIERS.get(equipment, 1.0)

            # Suggest multiplier based on equipment difference
            suggested_multiplier = round(target_mult / primary_mult, 2) if primary_mult > 0 else 0.85

            suggestions.append({
                'name': name,
                'equipment': equipment,
                'suggested_multiplier': min(1.0, max(0.5, suggested_multiplier)),
                'muscle_group': primary_muscle,
            })

        return suggestions[:limit]

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
        use_linked_exercises: bool = True,
        use_muscle_group_fallback: bool = True,
    ) -> List[WorkingWeightResult]:
        """
        Calculate working weights for a list of exercises.

        Uses a 3-level fallback chain to find 1RMs:
        1. Direct 1RM lookup (exact exercise name match)
        2. Linked exercises (user-defined exercise relationships)
        3. Muscle group fallback (same muscle group with equipment scaling)

        Args:
            user_id: User ID
            exercises: List of exercise names
            equipment_types: Optional mapping of exercise -> equipment type
            use_linked_exercises: Whether to use explicit exercise links
            use_muscle_group_fallback: Whether to fall back to muscle group lookup

        Returns:
            List of WorkingWeightResult for all exercises (including estimated 1RMs)
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

            # Get equipment type
            equipment = 'barbell'
            if equipment_types:
                equipment = equipment_types.get(exercise, 'barbell')

            # Initialize source tracking
            source_type = 'direct'
            source_exercise = None
            equipment_multiplier = 1.0
            one_rm_kg = None

            # ===== FALLBACK CHAIN =====

            # Level 1: Direct 1RM lookup (exact match)
            if exercise_lower in user_1rms:
                user_1rm = user_1rms[exercise_lower]
                one_rm_kg = user_1rm.one_rep_max_kg
                source_type = 'direct'
                source_exercise = None

            # Level 2: Linked exercise lookup
            elif use_linked_exercises:
                link_result = await self.find_1rm_via_link(user_id, exercise)
                if link_result:
                    one_rm_kg, source_exercise, equipment_multiplier = link_result
                    source_type = 'linked'

            # Level 3: Muscle group fallback
            if one_rm_kg is None and use_muscle_group_fallback:
                fallback_result = await self.find_1rm_by_muscle_group(
                    user_id, exercise, equipment
                )
                if fallback_result:
                    one_rm_kg, source_exercise, equipment_multiplier = fallback_result
                    source_type = 'muscle_group_fallback'

            # Skip if no 1RM found through any method
            if one_rm_kg is None:
                continue

            # Get intensity (override or global)
            is_override = exercise in overrides or exercise_lower in overrides
            intensity = overrides.get(
                exercise,
                overrides.get(exercise_lower, global_intensity)
            )

            # Calculate working weight
            working_weight = self.calculate_working_weight(
                one_rm_kg,
                intensity,
                equipment,
            )

            results.append(WorkingWeightResult(
                exercise_name=exercise,
                one_rep_max_kg=one_rm_kg,
                intensity_percent=intensity,
                working_weight_kg=working_weight,
                is_from_override=is_override,
                source_type=source_type,
                source_exercise=source_exercise,
                equipment_multiplier=equipment_multiplier,
            ))

        return results


# Singleton instance (without Supabase - will be initialized in API routes)
percentage_training_service = PercentageTrainingService()
