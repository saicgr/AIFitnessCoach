"""
Exercise Library Service - Fetches exercises from the exercise_library table in Supabase.

This service provides methods to query exercises by:
- Body part (chest, back, legs, etc.)
- Equipment (barbell, dumbbells, bodyweight, etc.)
- Target muscle
- Difficulty level
"""
from typing import List, Dict, Any, Optional
import random

from core.supabase_client import get_supabase
from core.logger import get_logger
from services.exercise_rag_service import _infer_equipment_from_name

logger = get_logger(__name__)


class ExerciseLibraryService:
    """Service to fetch exercises from the exercise_library table."""

    def __init__(self):
        self.supabase = get_supabase()
        self.client = self.supabase.client

    def get_exercises_by_body_part(
        self,
        body_part: str,
        equipment: Optional[List[str]] = None,
        limit: int = 20
    ) -> List[Dict[str, Any]]:
        """
        Get exercises for a specific body part.

        Args:
            body_part: The body part to target (e.g., 'chest', 'back', 'legs')
            equipment: Optional list of available equipment to filter by
            limit: Maximum number of exercises to return

        Returns:
            List of exercise dictionaries
        """
        try:
            query = self.client.table("exercise_library").select("*").ilike("body_part", f"%{body_part}%")

            if equipment:
                # Filter by equipment - match any of the provided equipment
                equipment_filters = [f"equipment.ilike.%{eq}%" for eq in equipment]
                # Also include bodyweight exercises
                equipment_filters.append("equipment.ilike.%body weight%")
                equipment_filters.append("equipment.ilike.%bodyweight%")

            result = query.limit(limit).execute()
            exercises = result.data or []

            # If we have equipment filter, apply it in Python (Supabase OR queries are tricky)
            if equipment and exercises:
                equipment_lower = [eq.lower() for eq in equipment]
                equipment_lower.extend(['body weight', 'bodyweight', 'none'])

                filtered = []
                for ex in exercises:
                    ex_equipment = (ex.get('equipment') or '').lower()
                    if any(eq in ex_equipment for eq in equipment_lower):
                        filtered.append(ex)
                exercises = filtered

            logger.info(f"Found {len(exercises)} exercises for body_part={body_part}")
            return exercises

        except Exception as e:
            logger.error(f"Error fetching exercises: {e}")
            return []

    def get_exercises_by_muscle(
        self,
        target_muscle: str,
        equipment: Optional[List[str]] = None,
        limit: int = 10
    ) -> List[Dict[str, Any]]:
        """Get exercises targeting a specific muscle."""
        try:
            query = self.client.table("exercise_library").select("*").ilike("target_muscle", f"%{target_muscle}%")
            result = query.limit(limit).execute()
            exercises = result.data or []

            if equipment and exercises:
                equipment_lower = [eq.lower() for eq in equipment]
                equipment_lower.extend(['body weight', 'bodyweight', 'none'])

                filtered = []
                for ex in exercises:
                    ex_equipment = (ex.get('equipment') or '').lower()
                    if any(eq in ex_equipment for eq in equipment_lower):
                        filtered.append(ex)
                exercises = filtered

            return exercises

        except Exception as e:
            logger.error(f"Error fetching exercises by muscle: {e}")
            return []

    def get_exercises_for_workout(
        self,
        focus_area: str,
        equipment: List[str],
        count: int = 6,
        fitness_level: str = "intermediate"
    ) -> List[Dict[str, Any]]:
        """
        Get a balanced set of exercises for a workout.

        Args:
            focus_area: The focus of the workout (e.g., 'chest', 'back', 'legs', 'full_body')
            equipment: List of available equipment
            count: Number of exercises to return
            fitness_level: User's fitness level for difficulty filtering

        Returns:
            List of exercise dictionaries formatted for workout
        """
        # Map focus areas to body parts
        focus_to_body_parts = {
            'chest': ['chest'],
            'back': ['back'],
            'shoulders': ['shoulders'],
            'arms': ['upper arms', 'lower arms'],
            'biceps': ['upper arms'],
            'triceps': ['upper arms'],
            'legs': ['upper legs', 'lower legs'],
            'glutes': ['upper legs'],
            'core': ['waist'],
            'abs': ['waist'],
            'full_body': ['chest', 'back', 'upper legs', 'shoulders', 'waist'],
        }

        body_parts = focus_to_body_parts.get(focus_area.lower(), ['chest', 'back', 'upper legs'])

        all_exercises = []

        # Fetch exercises for each body part
        for body_part in body_parts:
            exercises = self.get_exercises_by_body_part(
                body_part=body_part,
                equipment=equipment,
                limit=15
            )
            all_exercises.extend(exercises)

        # Remove duplicates by exercise name
        seen_names = set()
        unique_exercises = []
        for ex in all_exercises:
            name = ex.get('exercise_name', '').lower()
            if name and name not in seen_names:
                seen_names.add(name)
                unique_exercises.append(ex)

        # Shuffle and select
        random.shuffle(unique_exercises)
        selected = unique_exercises[:count]

        # Format for workout
        formatted_exercises = []
        for ex in selected:
            # Determine sets/reps based on fitness level
            if fitness_level == 'beginner':
                sets, reps = 2, 10
            elif fitness_level == 'advanced':
                sets, reps = 4, 12
            else:
                sets, reps = 3, 12

            # Get equipment - infer from name if missing
            raw_exercise_name = ex.get('exercise_name', 'Unknown Exercise')
            # Clean exercise name for display (remove _female, version suffixes etc)
            from services.exercise_rag_service import _clean_exercise_name_for_display
            exercise_name = _clean_exercise_name_for_display(raw_exercise_name)

            raw_eq = ex.get('equipment', '')
            if not raw_eq or raw_eq.lower() in ['bodyweight', 'body weight', 'none', '']:
                equipment = _infer_equipment_from_name(exercise_name)
            else:
                equipment = raw_eq

            formatted_exercises.append({
                'name': exercise_name,
                'sets': sets,
                'reps': reps,
                'rest_seconds': 60 if fitness_level != 'advanced' else 45,
                'equipment': equipment,
                'muscle_group': ex.get('target_muscle', ex.get('body_part', 'unknown')),
                'body_part': ex.get('body_part', ''),
                'notes': ex.get('instructions', '') or 'Focus on proper form',
                'gif_url': ex.get('gif_url', ''),
                'image_s3_path': ex.get('image_s3_path', ''),
                'video_s3_path': ex.get('video_s3_path', ''),
                'library_id': ex.get('id', ''),
            })

        logger.info(f"Selected {len(formatted_exercises)} exercises for {focus_area} workout")
        return formatted_exercises

    def search_exercises(
        self,
        query: str,
        limit: int = 20
    ) -> List[Dict[str, Any]]:
        """Search exercises by name.

        Returns exercises with normalized field names:
        - 'name' instead of 'exercise_name'
        - 'muscle_group' mapped from 'target_muscle' or 'body_part'
        """
        try:
            result = self.client.table("exercise_library").select("*").ilike("exercise_name", f"%{query}%").limit(limit).execute()
            exercises = result.data or []

            # Normalize field names to match expected format
            normalized = []
            for ex in exercises:
                raw_name = ex.get('exercise_name', 'Unknown Exercise')
                # Clean exercise name for display
                from services.exercise_rag_service import _clean_exercise_name_for_display
                clean_name = _clean_exercise_name_for_display(raw_name)

                # Get equipment - infer from name if missing
                raw_eq = ex.get('equipment', '')
                if not raw_eq or raw_eq.lower() in ['bodyweight', 'body weight', 'none', '']:
                    equipment = _infer_equipment_from_name(clean_name)
                else:
                    equipment = raw_eq

                normalized.append({
                    **ex,  # Include all original fields
                    'name': clean_name,  # Add normalized 'name' field
                    'equipment': equipment,
                    'muscle_group': ex.get('target_muscle', ex.get('body_part', 'unknown')),
                })

            return normalized
        except Exception as e:
            logger.error(f"Error searching exercises: {e}")
            return []


# Singleton instance
_exercise_library_service: Optional[ExerciseLibraryService] = None


def get_exercise_library_service() -> ExerciseLibraryService:
    """Get the global ExerciseLibraryService instance."""
    global _exercise_library_service
    if _exercise_library_service is None:
        _exercise_library_service = ExerciseLibraryService()
    return _exercise_library_service
