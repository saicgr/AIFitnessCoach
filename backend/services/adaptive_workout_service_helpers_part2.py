"""Second part of adaptive_workout_service_helpers.py (auto-split for size)."""
from typing import Any, Dict, List
import logging
logger = logging.getLogger(__name__)


class AdaptiveWorkoutServicePart2:
    """Second half of AdaptiveWorkoutService methods. Use as mixin."""

    def _determine_focus(
        self,
        user_goals: List[str] = None,
        performance_context: Dict[str, Any] = None,
    ) -> str:
        """
        Determine workout focus based on user goals and recent training.

        Uses undulating periodization - varies focus based on recent history.
        """
        if not user_goals:
            return "hypertrophy"

        # Map goals to workout focus
        goal_to_focus = {
            "muscle_gain": "hypertrophy",
            "build_muscle": "hypertrophy",
            "strength": "strength",
            "get_stronger": "strength",
            "weight_loss": "endurance",
            "lose_weight": "endurance",
            "endurance": "endurance",
            "athletic": "power",
            "sport_performance": "power",
            "general_fitness": "hypertrophy",
        }

        # Find primary focus from goals
        primary_focus = "hypertrophy"
        for goal in user_goals:
            goal_lower = goal.lower().replace(" ", "_")
            if goal_lower in goal_to_focus:
                primary_focus = goal_to_focus[goal_lower]
                break

        # For undulating periodization, vary the focus
        # If user has been doing a lot of one type, switch it up
        if performance_context and performance_context.get("workouts_completed", 0) > 0:
            workouts_this_week = performance_context.get("workouts_completed", 0)

            # Every 3rd workout, switch focus for variety
            if workouts_this_week % 3 == 0:
                focus_rotation = {
                    "hypertrophy": "strength",
                    "strength": "hypertrophy",
                    "endurance": "hypertrophy",
                    "power": "strength",
                }
                return focus_rotation.get(primary_focus, primary_focus)

        return primary_focus

    def get_varied_rest_time(
        self,
        exercise_type: str,
        workout_focus: str,
    ) -> int:
        """
        Get appropriate rest time based on exercise type and workout focus.

        Args:
            exercise_type: 'compound' or 'isolation'
            workout_focus: 'strength', 'hypertrophy', 'endurance', 'power'

        Returns:
            Rest time in seconds
        """
        structure = self.WORKOUT_STRUCTURES.get(workout_focus, self.WORKOUT_STRUCTURES["hypertrophy"])
        base_rest = (structure["rest_seconds"][0] + structure["rest_seconds"][1]) // 2

        # Compound exercises need more rest
        if exercise_type == "compound":
            return min(300, base_rest + 30)

        # Isolation exercises need less rest
        return max(30, base_rest - 15)

    def should_use_supersets(
        self,
        workout_focus: str,
        duration_minutes: int,
        exercise_count: int,
    ) -> bool:
        """
        Determine if supersets should be used in this workout.

        Supersets are good for:
        - Hypertrophy workouts
        - Time-efficient workouts
        - Higher volume with less rest

        Args:
            workout_focus: The type of workout
            duration_minutes: Target duration
            exercise_count: Number of exercises

        Returns:
            True if supersets should be included
        """
        structure = self.WORKOUT_STRUCTURES.get(workout_focus, self.WORKOUT_STRUCTURES["hypertrophy"])

        if not structure.get("allow_supersets", False):
            return False

        # Use supersets when:
        # 1. We have enough exercises to pair (at least 4)
        # 2. Duration is moderate (15-45 min) where time efficiency matters
        # 3. Focus allows for it
        return exercise_count >= 4 and 15 <= duration_minutes <= 45

    def should_include_amrap(
        self,
        workout_focus: str,
        user_fitness_level: str = "intermediate",
    ) -> bool:
        """
        Determine if an AMRAP finisher should be included.

        AMRAP (As Many Reps As Possible) is great for:
        - Pushing limits safely
        - Metabolic conditioning
        - Building mental toughness

        Args:
            workout_focus: The type of workout
            user_fitness_level: User's fitness level

        Returns:
            True if AMRAP should be included
        """
        structure = self.WORKOUT_STRUCTURES.get(workout_focus, self.WORKOUT_STRUCTURES["hypertrophy"])

        if not structure.get("allow_amrap", False):
            return False

        # Include AMRAP for intermediate and above
        # Beginners should focus on form and consistent reps first
        return user_fitness_level in ["intermediate", "advanced"]

    def create_superset_pairs(
        self,
        exercises: List[Dict[str, Any]],
    ) -> List[Dict[str, Any]]:
        """
        Group exercises into supersets based on muscle group antagonism.

        Pairs:
        - Chest/Back
        - Biceps/Triceps
        - Quads/Hamstrings
        - Anterior deltoids/Posterior deltoids

        Args:
            exercises: List of exercises to potentially pair

        Returns:
            Exercises with superset_group assignments
        """
        if len(exercises) < 2:
            return exercises

        # Antagonist muscle group pairs
        antagonist_pairs = {
            "chest": ["back", "lats"],
            "back": ["chest", "pectorals"],
            "lats": ["chest", "pectorals"],
            "biceps": ["triceps"],
            "triceps": ["biceps"],
            "quadriceps": ["hamstrings", "glutes"],
            "hamstrings": ["quadriceps"],
            "shoulders": ["back"],  # Front/rear delts
        }

        superset_group = 1
        assigned = set()
        result = []

        for i, ex in enumerate(exercises):
            if i in assigned:
                continue

            muscle = ex.get("muscle_group", "").lower()
            ex_copy = ex.copy()

            # Try to find a pair
            paired = False
            for j, other in enumerate(exercises):
                if j <= i or j in assigned:
                    continue

                other_muscle = other.get("muscle_group", "").lower()

                # Check if they're antagonist pairs
                if other_muscle in antagonist_pairs.get(muscle, []):
                    # Found a pair!
                    ex_copy["superset_group"] = superset_group
                    ex_copy["superset_order"] = 1

                    other_copy = other.copy()
                    other_copy["superset_group"] = superset_group
                    other_copy["superset_order"] = 2
                    other_copy["rest_seconds"] = 0  # No rest between superset exercises

                    result.append(ex_copy)
                    result.append(other_copy)
                    assigned.add(i)
                    assigned.add(j)
                    superset_group += 1
                    paired = True
                    break

            if not paired:
                result.append(ex_copy)
                assigned.add(i)

        return result

    def create_amrap_finisher(
        self,
        workout_exercises: List[Dict[str, Any]],
        workout_focus: str,
    ) -> Dict[str, Any]:
        """
        Create an AMRAP finisher exercise based on the workout.

        Args:
            workout_exercises: The exercises in the workout
            workout_focus: Type of workout

        Returns:
            AMRAP exercise dict
        """
        # Choose a suitable exercise for AMRAP based on workout type
        amrap_exercises = {
            "hypertrophy": ["Push-Ups", "Pull-Ups", "Dips", "Bodyweight Squats"],
            "endurance": ["Burpees", "Mountain Climbers", "Jumping Jacks", "High Knees"],
            "hiit": ["Burpees", "Box Jumps", "Kettlebell Swings", "Battle Ropes"],
        }

        options = amrap_exercises.get(workout_focus, amrap_exercises["hypertrophy"])

        # Pick one that's not already in the workout
        existing_names = [e.get("name", "").lower() for e in workout_exercises]
        selected = None
        for option in options:
            if option.lower() not in existing_names:
                selected = option
                break

        if not selected:
            selected = options[0]

        return {
            "name": selected,
            "sets": 1,
            "reps": 0,  # AMRAP - no fixed reps
            "is_amrap": True,
            "duration_seconds": 60,  # 1 minute AMRAP
            "rest_seconds": 0,
            "muscle_group": "Full Body",
            "equipment": "Bodyweight",
            "notes": "AMRAP - As Many Reps As Possible in 60 seconds. Push yourself!",
            "set_targets": [
                {
                    "set_number": 1,
                    "set_type": "amrap",
                    "target_reps": 0,  # AMRAP - no fixed reps
                    "target_weight_kg": 0,  # Bodyweight
                    "target_rpe": 10,  # Max effort
                    "target_rir": 0,  # Go to failure
                }
            ],
        }

    def should_use_drop_sets(
        self,
        workout_focus: str,
        user_fitness_level: str,
    ) -> bool:
        """
        Determine if drop sets should be used in this workout.

        Drop sets are good for:
        - Hypertrophy workouts (muscle building)
        - Endurance workouts (muscular endurance)
        - Intermediate and advanced users

        Args:
            workout_focus: The type of workout
            user_fitness_level: User's fitness level

        Returns:
            True if drop sets should be included
        """
        structure = self.WORKOUT_STRUCTURES.get(workout_focus, self.WORKOUT_STRUCTURES["hypertrophy"])

        if not structure.get("allow_drop_sets", False):
            return False

        # Only for intermediate and advanced users
        # Beginners should focus on form and consistent technique first
        return user_fitness_level in ["intermediate", "advanced"]

    def add_drop_sets_to_exercise(
        self,
        exercise: Dict[str, Any],
        drop_set_count: int = 2,
        drop_percentage: int = 20,
    ) -> Dict[str, Any]:
        """
        Configure an exercise to use drop sets.

        Drop sets involve:
        - Performing a set to near failure
        - Immediately reducing weight by a percentage
        - Continuing without rest for additional reps

        Args:
            exercise: The exercise dict to modify
            drop_set_count: Number of drop sets (typically 2-3)
            drop_percentage: Percentage to reduce weight each drop (typically 20-25%)

        Returns:
            Modified exercise dict with drop set configuration
        """
        exercise_copy = exercise.copy()
        exercise_copy["is_drop_set"] = True
        exercise_copy["drop_set_count"] = drop_set_count
        exercise_copy["drop_set_percentage"] = drop_percentage
        exercise_copy["notes"] = (
            f"Drop Set: Complete main set, then immediately reduce weight by {drop_percentage}% "
            f"and continue for {drop_set_count} more drops. No rest between drops."
        )
        return exercise_copy

    def apply_drop_sets_to_workout(
        self,
        exercises: List[Dict[str, Any]],
        workout_focus: str,
        user_fitness_level: str,
        max_drop_set_exercises: int = 2,
    ) -> List[Dict[str, Any]]:
        """
        Apply drop sets to suitable exercises in a workout.

        Best exercises for drop sets:
        - Isolation exercises (curls, extensions, flyes)
        - Machine exercises (easy to change weight)
        - Cable exercises

        Exercises to avoid for drop sets:
        - Compound barbell exercises (squats, deadlifts)
        - Power movements
        - Exercises requiring spotters

        Args:
            exercises: List of exercises in the workout
            workout_focus: Type of workout
            user_fitness_level: User's fitness level
            max_drop_set_exercises: Maximum number of exercises to apply drop sets to

        Returns:
            Modified exercise list with drop sets applied where appropriate
        """
        if not self.should_use_drop_sets(workout_focus, user_fitness_level):
            return exercises

        # Exercise types good for drop sets
        good_for_drop_sets = {
            "machine", "cable", "dumbbell", "isolation",
            "curl", "extension", "fly", "raise", "pushdown",
            "pulldown", "row"  # Machine rows are fine
        }

        # Exercise types to avoid for drop sets
        avoid_drop_sets = {
            "barbell squat", "deadlift", "bench press", "overhead press",
            "clean", "snatch", "jerk", "power", "explosive"
        }

        result = []
        drop_set_count = 0

        for exercise in exercises:
            exercise_copy = exercise.copy()
            name_lower = exercise.get("name", "").lower()
            equipment_lower = exercise.get("equipment", "").lower()

            # Check if this exercise is suitable for drop sets
            is_suitable = False
            if drop_set_count < max_drop_set_exercises:
                # Check if it's a good candidate
                for keyword in good_for_drop_sets:
                    if keyword in name_lower or keyword in equipment_lower:
                        is_suitable = True
                        break

                # Check if it should be avoided
                for keyword in avoid_drop_sets:
                    if keyword in name_lower:
                        is_suitable = False
                        break

            if is_suitable:
                exercise_copy = self.add_drop_sets_to_exercise(exercise_copy)
                drop_set_count += 1

            result.append(exercise_copy)

        return result


# =============================================================================
# SET TYPE PREFERENCE FUNCTIONS (Feedback Loop for Gemini)
# =============================================================================

async def get_user_set_type_preferences(user_id: str, supabase_client=None, days: int = 90) -> Dict[str, Any]:
    """
    Query v_user_set_type_analytics view for user's set type patterns.

    This provides the feedback loop data for Gemini to learn from user's
    historical acceptance of AI-recommended set types (drop sets, failure sets, AMRAP).

    Args:
        user_id: The user's UUID
        supabase_client: Supabase client instance
        days: Number of days to look back (default 90)

    Returns:
        Dict mapping set_type to preference data:
        {
            "drop_set": {
                "total_performed": 15,
                "ai_recommended_accepted": 12,
                "user_selected": 3,
                "acceptance_rate": 0.8,
                "avg_reps": 10.5,
                "avg_weight_kg": 25.0,
                "first_used": "2024-10-15T...",
                "last_used": "2025-01-10T...",
            },
            "failure": {...},
            "amrap": {...},
            ...
        }
    """
    if not supabase_client:
        logger.warning("[SetTypePrefs] No supabase client provided")
        return {}

    try:
        # Query the analytics view created in migration 148
        result = supabase_client.table("v_user_set_type_analytics") \
            .select("*") \
            .eq("user_id", user_id) \
            .execute()

        if not result.data:
            logger.info(f"[SetTypePrefs] No set type history for user {user_id[:8]}...")
            return {}

        # Process rows into structured preference data
        set_type_data = {}
        for row in result.data:
            set_type = row.get("set_type", "working")
            total = row.get("total_sets", 0) or 0
            ai_recommended = row.get("ai_recommended_count", 0) or 0
            user_selected = row.get("user_selected_count", 0) or 0

            # Calculate acceptance rate (how often user accepts AI recommendations)
            acceptance_rate = ai_recommended / total if total > 0 else 0

            set_type_data[set_type] = {
                "total_performed": total,
                "ai_recommended_accepted": ai_recommended,
                "user_selected": user_selected,
                "acceptance_rate": acceptance_rate,
                "avg_reps": float(row.get("avg_reps", 0) or 0),
                "avg_weight_kg": float(row.get("avg_weight_kg", 0) or 0),
                "first_used": row.get("first_used"),
                "last_used": row.get("last_used"),
            }

        logger.info(
            f"[SetTypePrefs] Retrieved preferences for user {user_id[:8]}...: "
            f"{len(set_type_data)} set types tracked"
        )

        return set_type_data

    except Exception as e:
        logger.error(f"[SetTypePrefs] Error fetching set type preferences: {e}")
        return {}


def build_set_type_context(set_type_prefs: Dict[str, Any]) -> str:
    """
    Format user's set type history for Gemini prompt injection.

    This creates a context string that tells Gemini about the user's
    historical preferences for advanced set types, enabling personalized
    recommendations based on acceptance rates.

    Args:
        set_type_prefs: Dict from get_user_set_type_preferences()

    Returns:
        Formatted context string for Gemini prompt
    """
    if not set_type_prefs:
        return ""

    # Filter out 'working' and 'warmup' sets - we only care about advanced types
    advanced_types = {k: v for k, v in set_type_prefs.items()
                      if k not in ["working", "warmup"]}

    if not advanced_types:
        return "\n## User's Advanced Set Type History\n- No advanced set type history - use conservative defaults based on fitness level\n"

    context = "\n## User's Advanced Set Type History (Based on 90 Days)\n"
    context += "Use this data to personalize advanced set type recommendations:\n\n"

    # Drop sets analysis
    drop_sets = set_type_prefs.get("drop_set", {})
    if drop_sets.get("total_performed", 0) > 0:
        total = drop_sets["total_performed"]
        rate = drop_sets.get("acceptance_rate", 0) * 100
        context += f"- **Drop Sets**: {total} performed, {rate:.0f}% were AI-recommended\n"
        if rate > 75:
            context += "  → User LOVES drop sets - include 1-2 per hypertrophy workout\n"
        elif rate > 50:
            context += "  → User accepts drop sets moderately - include occasionally\n"
        elif rate < 25 and total >= 5:
            context += "  → User RARELY accepts AI drop set recommendations - avoid unless requested\n"

    # Failure sets analysis
    failure = set_type_prefs.get("failure", {})
    if failure.get("total_performed", 0) > 0:
        total = failure["total_performed"]
        rate = failure.get("acceptance_rate", 0) * 100
        context += f"- **Failure Sets**: {total} performed, {rate:.0f}% were AI-recommended\n"
        if rate > 75:
            context += "  → User ACCEPTS failure sets - recommend on final sets of compound exercises\n"
        elif rate > 50:
            context += "  → User uses failure sets selectively - recommend sparingly\n"
        elif rate < 25 and total >= 5:
            context += "  → User AVOIDS failure sets - don't recommend (user prefers leaving reps in reserve)\n"

    # AMRAP analysis
    amrap = set_type_prefs.get("amrap", {})
    if amrap.get("total_performed", 0) > 0:
        total = amrap["total_performed"]
        rate = amrap.get("acceptance_rate", 0) * 100
        context += f"- **AMRAP Sets**: {total} performed, {rate:.0f}% were AI-recommended\n"
        if rate > 75:
            context += "  → User ENJOYS AMRAP - include as workout finishers\n"
        elif rate > 50:
            context += "  → User accepts AMRAP occasionally - include when appropriate\n"
        elif rate < 25 and total >= 5:
            context += "  → User prefers fixed rep schemes - avoid AMRAP recommendations\n"

    # Summary guidance for Gemini
    context += "\n**IMPORTANT**: Respect these preferences when setting is_failure_set and is_drop_set fields.\n"

    return context


# Singleton instance for easy import
_adaptive_service_instance = None


def get_adaptive_workout_service(supabase_client=None) -> "AdaptiveWorkoutService":
    """Get or create the AdaptiveWorkoutService singleton."""
    from .adaptive_workout_service_helpers import AdaptiveWorkoutService
    global _adaptive_service_instance
    if _adaptive_service_instance is None:
        _adaptive_service_instance = AdaptiveWorkoutService(supabase_client)
    return _adaptive_service_instance
