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
import re

from core.supabase_client import get_supabase
from core.logger import get_logger
from services.exercise_rag_service import _infer_equipment_from_name

logger = get_logger(__name__)

# How wide a candidate pool to pull before sampling down to the caller's `limit`.
# The pool is what gives repeat generations variety; `limit` is only how many we
# hand back. Previously the two were the same number, so the "pool" was a single
# arbitrary heap-ordered slice and every generation drew from the same rows.
POOL_OVERSAMPLE = 10
MIN_POOL = 150

# PostgREST forwards `.ilike()` patterns straight to Postgres ILIKE, where `%`
# and `_` are wildcards and `\` is the escape character. A user-supplied name
# containing one of those (e.g. "100% grip") must have them escaped before
# being interpolated into a pattern, or the literal character turns into a
# wildcard and silently widens the match.
_ILIKE_SPECIAL_RE = re.compile(r"([%_\\])")


def escape_ilike(value: str) -> str:
    """Escape `%`, `_` and `\\` so ``value`` matches ILIKE literally."""
    return _ILIKE_SPECIAL_RE.sub(r"\\\1", value or "")


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
                # Apply the equipment predicate SERVER-SIDE.
                #
                # This block used to build `equipment_filters` and then never use
                # it — `.limit(limit)` ran on the unfiltered query and the Python
                # filter was applied to whatever those first N rows happened to be.
                # Combined with the absent ORDER BY (Postgres returns heap order),
                # every request saw substantially the same ~15 rows per body part
                # out of hundreds, and equipment filtering could only ever shrink
                # that arbitrary slice. This is the single biggest reason
                # quick-generate and generate-stream felt like they ignored the
                # library.
                or_terms = []
                for eq in equipment:
                    eq_clean = (eq or "").strip().replace(",", " ")
                    if eq_clean:
                        or_terms.append(f"equipment.ilike.%{eq_clean}%")
                # Bodyweight is always available to everyone.
                or_terms.append("equipment.ilike.%body weight%")
                or_terms.append("equipment.ilike.%bodyweight%")
                or_terms.append("equipment.ilike.%none%")
                # An exercise with no stated equipment requires nothing — include
                # it rather than silently dropping it. Matches the RAG pipeline's
                # rule (services/exercise_rag/filters.py: empty equipment → allowed).
                or_terms.append("equipment.is.null")
                or_terms.append("equipment.eq.")
                query = query.or_(",".join(or_terms))

            # Deterministic ordering so the pool is reproducible instead of
            # heap-ordered, and a pool cap far above `limit` so the caller's
            # random sampling has real breadth to draw from.
            pool_cap = max(limit * POOL_OVERSAMPLE, MIN_POOL)
            result = query.order("exercise_name").limit(pool_cap).execute()
            pool = result.data or []

            # Belt-and-suspenders: the OR above is a substring match on a free-text
            # column, so re-check in Python for anything it let through loosely.
            # Runs on the POOL, never before it — filtering must precede truncation.
            if equipment and pool:
                equipment_lower = [eq.lower() for eq in equipment]
                equipment_lower.extend(['body weight', 'bodyweight', 'none'])
                filtered = []
                for ex in pool:
                    ex_equipment = (ex.get('equipment') or '').strip().lower()
                    if not ex_equipment:
                        filtered.append(ex)      # no requirement → always usable
                    elif any(eq in ex_equipment for eq in equipment_lower):
                        filtered.append(ex)
                pool = filtered

            # Sample from the whole eligible pool so repeat generations vary.
            if len(pool) > limit:
                exercises = random.sample(pool, limit)
            else:
                exercises = pool

            logger.info(
                f"Found {len(exercises)} exercises for body_part={body_part} "
                f"(eligible pool={len(pool)}, cap={pool_cap}, equipment={equipment})"
            )
            return exercises

        except Exception as e:
            logger.error(f"Error fetching exercises: {e}", exc_info=True)
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
            logger.error(f"Error fetching exercises by muscle: {e}", exc_info=True)
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

        # Fetch exercises for each body part.
        # Scale with `count` instead of the old hardcoded 15: this pool is what a
        # generator (or Gemini prompt block) gets to choose from, so a fixed 15 per
        # body part capped variety no matter how many exercises the caller wanted.
        per_body_part = max(30, count * 5)
        for body_part in body_parts:
            exercises = self.get_exercises_by_body_part(
                body_part=body_part,
                equipment=equipment,
                limit=per_body_part
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
                # Real how-to text belongs in `instructions` (the detail
                # screen's Instructions section reads it); `notes` keeps the
                # legacy mirror for older clients that only render notes.
                'instructions': ex.get('instructions') or None,
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
        """Search exercises by name, preferring the closest name match.

        Resolution order (register: prod incident — swapping/adding a
        user-named exercise silently persisted a different, unrelated one):
          1. case-insensitive EXACT name match
          2. then PREFIX match
          3. then substring match — only when nothing better exists

        The old query was `.ilike(f"%{query}%").limit(limit)` with no ORDER
        BY, so with `limit=1` the row handed back was whichever substring
        match Postgres's heap order happened to put first — e.g. requesting
        "jumping jack" could persist "Med ball jumping jacks", and
        "Pull-Up normal grip" could persist "assisted Pull-Up normal grip".
        A prod sweep found 723 library names are substrings of another.

        Returns exercises with normalized field names:
        - 'name' instead of 'exercise_name'
        - 'muscle_group' mapped from 'target_muscle' or 'body_part'
        """
        try:
            q = (query or "").strip()
            if not q:
                return []
            escaped = escape_ilike(q)
            q_lower = q.lower()

            # Exact-match probe as its OWN query — cheap, and guarantees the
            # exact row is found whenever one exists, rather than hoping it
            # survives a `limit=1` (or even a raised-limit) substring fetch.
            # No wildcards in the pattern -> a literal case-insensitive match.
            exact_result = (
                self.client.table("exercise_library")
                .select("*")
                .ilike("exercise_name", escaped)
                .limit(limit)
                .execute()
            )
            exercises = exact_result.data or []

            if len(exercises) < limit:
                # Oversample substring candidates so prefix matches are
                # actually IN the pool (mirrors get_exercises_by_body_part's
                # pool-then-rank approach above), then rank in Python: prefix
                # before mid-string substring. Deterministic ORDER BY makes
                # the pool reproducible instead of heap-ordered.
                pool_cap = max(limit * POOL_OVERSAMPLE, MIN_POOL)
                pool_result = (
                    self.client.table("exercise_library")
                    .select("*")
                    .ilike("exercise_name", f"%{escaped}%")
                    .order("exercise_name")
                    .limit(pool_cap)
                    .execute()
                )
                pool = pool_result.data or []
                seen_ids = {ex.get("id") for ex in exercises}
                candidates = [ex for ex in pool if ex.get("id") not in seen_ids]

                def _rank(ex: Dict[str, Any]) -> int:
                    name = (ex.get("exercise_name") or "").strip().lower()
                    if name == q_lower:
                        return 0  # case-insensitive exact, caught again here
                                  # in case the exact probe missed it (e.g.
                                  # trailing whitespace variance in the row)
                    if name.startswith(q_lower):
                        return 1
                    return 2

                candidates.sort(key=_rank)
                exercises = exercises + candidates

            exercises = exercises[:limit]

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
            logger.error(f"Error searching exercises: {e}", exc_info=True)
            return []

    def get_exercise_by_id(self, exercise_id: str) -> Optional[Dict[str, Any]]:
        """Get a single exercise by its library ID (exact primary-key lookup)."""
        try:
            result = self.client.table("exercise_library").select("*").eq("id", exercise_id).limit(1).execute()
            if not result.data:
                return None
            ex = result.data[0]
            raw_name = ex.get('exercise_name', 'Unknown Exercise')
            from services.exercise_rag_service import _clean_exercise_name_for_display
            clean_name = _clean_exercise_name_for_display(raw_name)
            raw_eq = ex.get('equipment', '')
            if not raw_eq or raw_eq.lower() in ['bodyweight', 'body weight', 'none', '']:
                equipment = _infer_equipment_from_name(clean_name)
            else:
                equipment = raw_eq
            return {
                **ex,
                'name': clean_name,
                'equipment': equipment,
                'muscle_group': ex.get('target_muscle', ex.get('body_part', 'unknown')),
            }
        except Exception as e:
            logger.error(f"Error getting exercise by ID {exercise_id}: {e}", exc_info=True)
            return None


# Singleton instance
_exercise_library_service: Optional[ExerciseLibraryService] = None


def get_exercise_library_service() -> ExerciseLibraryService:
    """Get the global ExerciseLibraryService instance."""
    global _exercise_library_service
    if _exercise_library_service is None:
        _exercise_library_service = ExerciseLibraryService()
    return _exercise_library_service
