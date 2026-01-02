"""
Senior Workout Service - Age-appropriate workout modifications.

Provides recovery-aware workout scaling for older users (60+).
Addresses user feedback: "older person. trying to get moving."

Features:
1. Extended recovery periods between workouts
2. Lower intensity caps for safety
3. Joint-friendly exercise selection (low-impact alternatives)
4. Mandatory extended warmup/cooldown
5. Mobility exercise inclusion
6. Balance exercise inclusion (fall prevention)

Age-based default settings:
- 60-64: 1.25x recovery, 80% max intensity, 8 min warmup
- 65-69: 1.5x recovery, 75% max intensity, 10 min warmup
- 70-74: 1.75x recovery, 70% max intensity, 12 min warmup
- 75+:   2.0x recovery, 65% max intensity, 15 min warmup
"""

from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import List, Dict, Optional, Any, Tuple
import logging

from core.supabase_db import get_supabase_db

logger = logging.getLogger(__name__)


# Age-based default settings
AGE_SETTINGS = {
    (60, 64): {
        "recovery_multiplier": 1.25,
        "max_intensity": 80,
        "min_rest_days_strength": 1,
        "min_rest_days_cardio": 1,
        "extended_warmup": 8,
        "extended_cooldown": 8,
        "max_exercises": 7,
    },
    (65, 69): {
        "recovery_multiplier": 1.5,
        "max_intensity": 75,
        "min_rest_days_strength": 2,
        "min_rest_days_cardio": 1,
        "extended_warmup": 10,
        "extended_cooldown": 10,
        "max_exercises": 6,
    },
    (70, 74): {
        "recovery_multiplier": 1.75,
        "max_intensity": 70,
        "min_rest_days_strength": 2,
        "min_rest_days_cardio": 1,
        "extended_warmup": 12,
        "extended_cooldown": 12,
        "max_exercises": 5,
    },
    (75, 100): {
        "recovery_multiplier": 2.0,
        "max_intensity": 65,
        "min_rest_days_strength": 3,
        "min_rest_days_cardio": 2,
        "extended_warmup": 15,
        "extended_cooldown": 15,
        "max_exercises": 4,
    },
}

# Low-impact alternatives for high-impact exercises
LOW_IMPACT_ALTERNATIVES = {
    "Running": "Walking",
    "Jump Squats": "Bodyweight Squats",
    "Burpees": "Step-Back Burpees",
    "Box Jumps": "Step-Ups",
    "Jumping Lunges": "Stationary Lunges",
    "High Knees": "Marching in Place",
    "Mountain Climbers": "Standing Knee Raises",
    "Tuck Jumps": "Chair Squats",
    "Jumping Jacks": "Step Jacks",
    "Plyo Push-ups": "Wall Push-ups",
    "Sprints": "Brisk Walking",
    "Jump Rope": "Walking in Place",
    "Depth Jumps": "Box Step Downs",
    "Lunge Jumps": "Reverse Lunges",
    "Squat Jumps": "Chair-Assisted Squats",
}

# Default mobility exercises
DEFAULT_MOBILITY_EXERCISES = [
    {
        "name": "Cat-Cow Stretch",
        "type": "mobility",
        "sets": 2,
        "reps": 10,
        "duration_seconds": None,
        "rest_seconds": 30,
        "target_muscles": ["spine", "lower back"],
        "instructions": [
            "Start on hands and knees",
            "Inhale, drop belly and look up (cow)",
            "Exhale, round spine and tuck chin (cat)",
            "Move slowly and breathe deeply",
        ],
    },
    {
        "name": "Hip Circles",
        "type": "mobility",
        "sets": 2,
        "reps": 10,
        "duration_seconds": None,
        "rest_seconds": 30,
        "target_muscles": ["hip flexors", "glutes"],
        "instructions": [
            "Stand with feet hip-width apart",
            "Place hands on hips",
            "Make slow circles with your hips",
            "Do both directions",
        ],
    },
    {
        "name": "Arm Circles",
        "type": "mobility",
        "sets": 2,
        "reps": 15,
        "duration_seconds": None,
        "rest_seconds": 30,
        "target_muscles": ["shoulders", "rotator cuff"],
        "instructions": [
            "Stand with arms extended to sides",
            "Make small circles forward",
            "Gradually increase circle size",
            "Reverse direction",
        ],
    },
    {
        "name": "Ankle Rotations",
        "type": "mobility",
        "sets": 2,
        "reps": 10,
        "duration_seconds": None,
        "rest_seconds": 30,
        "target_muscles": ["ankles", "calves"],
        "instructions": [
            "Sit or stand with support",
            "Lift one foot off ground",
            "Rotate ankle in circles",
            "Do both directions, then switch feet",
        ],
    },
    {
        "name": "Neck Rolls",
        "type": "mobility",
        "sets": 1,
        "reps": 5,
        "duration_seconds": None,
        "rest_seconds": 30,
        "target_muscles": ["neck", "upper back"],
        "instructions": [
            "Sit or stand tall",
            "Slowly roll head in half circles (ear to ear)",
            "Never roll head backward",
            "Keep movements slow and controlled",
        ],
    },
    {
        "name": "Seated Spinal Twist",
        "type": "mobility",
        "sets": 2,
        "reps": 5,
        "duration_seconds": None,
        "rest_seconds": 30,
        "target_muscles": ["spine", "obliques"],
        "instructions": [
            "Sit in chair with feet flat",
            "Place right hand on left knee",
            "Gently twist torso left",
            "Hold 10-15 seconds, then switch",
        ],
    },
]

# Default balance exercises for fall prevention
DEFAULT_BALANCE_EXERCISES = [
    {
        "name": "Single Leg Stand",
        "type": "balance",
        "sets": 2,
        "reps": None,
        "duration_seconds": 30,
        "rest_seconds": 30,
        "target_muscles": ["core", "ankles"],
        "instructions": [
            "Stand near wall for support if needed",
            "Lift one foot slightly off ground",
            "Hold for 30 seconds",
            "Switch legs",
        ],
    },
    {
        "name": "Heel-to-Toe Walk",
        "type": "balance",
        "sets": 2,
        "reps": 10,
        "duration_seconds": None,
        "rest_seconds": 30,
        "target_muscles": ["core", "legs"],
        "instructions": [
            "Walk in a straight line",
            "Place heel directly in front of toes",
            "Use wall for support if needed",
            "Take 10 steps each set",
        ],
    },
]


@dataclass
class SeniorSettings:
    """Data class for senior-specific settings."""
    user_id: str
    recovery_multiplier: float
    min_rest_days_strength: int
    min_rest_days_cardio: int
    max_intensity_percent: int
    max_workout_duration_minutes: int
    max_exercises_per_session: int
    extended_warmup_minutes: int
    extended_cooldown_minutes: int
    prefer_low_impact: bool
    avoid_high_impact_cardio: bool
    include_mobility_exercises: bool
    mobility_exercises_per_session: int
    include_balance_exercises: bool
    balance_exercises_per_session: int
    custom_notes: Optional[str]
    user_age: Optional[int]


@dataclass
class RecoveryStatus:
    """Data class for recovery status check."""
    ready: bool
    days_since_last: Optional[int]
    min_rest_required: Optional[int]
    days_until_ready: Optional[int]
    recommendation: Optional[str]
    settings_applied: bool


@dataclass
class WorkoutModificationResult:
    """Data class for workout modification results."""
    workout: Dict[str, Any]
    exercises: List[Dict[str, Any]]
    modified: bool
    modifications: List[str]
    senior_settings: Optional[SeniorSettings]


class SeniorWorkoutService:
    """
    Service for senior-specific workout modifications.

    Provides age-appropriate workout adjustments including:
    - Extended recovery periods
    - Lower intensity caps
    - Joint-friendly exercise selection
    - Mandatory warmup/cooldown
    - Mobility and balance exercise inclusion
    """

    def __init__(self):
        self._db = None

    @property
    def db(self):
        if self._db is None:
            self._db = get_supabase_db()
        return self._db

    # -------------------------------------------------------------------------
    # Settings Retrieval
    # -------------------------------------------------------------------------

    async def get_user_settings(self, user_id: str) -> Optional[SeniorSettings]:
        """
        Get senior-specific settings for a user.

        Args:
            user_id: User ID

        Returns:
            SeniorSettings if user is a senior (60+), None otherwise
        """
        try:
            # First try to get settings from database
            result = self.db.client.table("senior_recovery_settings").select(
                "*, users(age)"
            ).eq("user_id", user_id).execute()

            if result.data:
                settings_data = result.data[0]
                user_data = settings_data.get("users", {})
                user_age = user_data.get("age") if user_data else None

                logger.info(f"Found senior settings for user {user_id}, age: {user_age}")

                return SeniorSettings(
                    user_id=user_id,
                    recovery_multiplier=float(settings_data.get("recovery_multiplier", 1.5)),
                    min_rest_days_strength=settings_data.get("min_rest_days_strength", 2),
                    min_rest_days_cardio=settings_data.get("min_rest_days_cardio", 1),
                    max_intensity_percent=settings_data.get("max_intensity_percent", 75),
                    max_workout_duration_minutes=settings_data.get("max_workout_duration_minutes", 45),
                    max_exercises_per_session=settings_data.get("max_exercises_per_session", 6),
                    extended_warmup_minutes=settings_data.get("extended_warmup_minutes", 10),
                    extended_cooldown_minutes=settings_data.get("extended_cooldown_minutes", 10),
                    prefer_low_impact=settings_data.get("prefer_low_impact", True),
                    avoid_high_impact_cardio=settings_data.get("avoid_high_impact_cardio", True),
                    include_mobility_exercises=settings_data.get("include_mobility_exercises", True),
                    mobility_exercises_per_session=settings_data.get("mobility_exercises_per_session", 2),
                    include_balance_exercises=settings_data.get("include_balance_exercises", True),
                    balance_exercises_per_session=settings_data.get("balance_exercises_per_session", 1),
                    custom_notes=settings_data.get("custom_notes"),
                    user_age=user_age,
                )

            # If no settings in DB, check user age and return defaults
            user_result = self.db.client.table("users").select("age").eq("id", user_id).execute()
            if user_result.data:
                user_age = user_result.data[0].get("age")
                if user_age and user_age >= 60:
                    logger.info(f"No DB settings, creating defaults for user {user_id}, age: {user_age}")
                    return self._get_default_settings(user_id, user_age)

            return None

        except Exception as e:
            logger.error(f"Failed to get senior settings for user {user_id}: {e}")
            return None

    def _get_default_settings(self, user_id: str, age: int) -> Optional[SeniorSettings]:
        """Get default settings based on age."""
        for (min_age, max_age), settings in AGE_SETTINGS.items():
            if min_age <= age <= max_age:
                return SeniorSettings(
                    user_id=user_id,
                    recovery_multiplier=settings["recovery_multiplier"],
                    min_rest_days_strength=settings["min_rest_days_strength"],
                    min_rest_days_cardio=settings["min_rest_days_cardio"],
                    max_intensity_percent=settings["max_intensity"],
                    max_workout_duration_minutes=45,
                    max_exercises_per_session=settings["max_exercises"],
                    extended_warmup_minutes=settings["extended_warmup"],
                    extended_cooldown_minutes=settings["extended_cooldown"],
                    prefer_low_impact=True,
                    avoid_high_impact_cardio=True,
                    include_mobility_exercises=True,
                    mobility_exercises_per_session=2,
                    include_balance_exercises=True,
                    balance_exercises_per_session=1,
                    custom_notes=None,
                    user_age=age,
                )
        return None

    async def update_user_settings(
        self,
        user_id: str,
        settings: Dict[str, Any]
    ) -> Optional[SeniorSettings]:
        """
        Update senior settings for a user.

        Args:
            user_id: User ID
            settings: Dictionary of settings to update

        Returns:
            Updated SeniorSettings or None if failed
        """
        try:
            now = datetime.utcnow().isoformat()

            # Prepare update data
            update_data = {
                "updated_at": now,
            }

            # Map allowed fields
            allowed_fields = [
                "recovery_multiplier", "min_rest_days_strength", "min_rest_days_cardio",
                "max_intensity_percent", "max_workout_duration_minutes",
                "max_exercises_per_session", "extended_warmup_minutes",
                "extended_cooldown_minutes", "prefer_low_impact",
                "avoid_high_impact_cardio", "include_mobility_exercises",
                "mobility_exercises_per_session", "include_balance_exercises",
                "balance_exercises_per_session", "custom_notes",
            ]

            for field in allowed_fields:
                if field in settings:
                    update_data[field] = settings[field]

            # Upsert settings
            result = self.db.client.table("senior_recovery_settings").upsert({
                "user_id": user_id,
                **update_data,
            }, on_conflict="user_id").execute()

            if not result.data:
                logger.error(f"Failed to upsert senior settings for user {user_id}")
                return None

            logger.info(f"Updated senior settings for user {user_id}")
            return await self.get_user_settings(user_id)

        except Exception as e:
            logger.error(f"Failed to update senior settings: {e}")
            return None

    # -------------------------------------------------------------------------
    # Recovery Status
    # -------------------------------------------------------------------------

    async def check_recovery_status(
        self,
        user_id: str,
        workout_type: str = "strength"
    ) -> RecoveryStatus:
        """
        Check if user has had enough recovery since last workout.

        Args:
            user_id: User ID
            workout_type: Type of workout ('strength' or 'cardio')

        Returns:
            RecoveryStatus with readiness information
        """
        try:
            settings = await self.get_user_settings(user_id)

            if not settings:
                logger.debug(f"No senior settings for user {user_id}, no recovery check needed")
                return RecoveryStatus(
                    ready=True,
                    days_since_last=None,
                    min_rest_required=None,
                    days_until_ready=None,
                    recommendation=None,
                    settings_applied=False,
                )

            # Determine minimum rest days
            min_rest = (
                settings.min_rest_days_strength
                if workout_type == "strength"
                else settings.min_rest_days_cardio
            )

            # Get last completed workout of this type
            result = self.db.client.table("senior_workout_log").select(
                "completed_at"
            ).eq("user_id", user_id).eq("workout_type", workout_type).order(
                "completed_at", desc=True
            ).limit(1).execute()

            if not result.data:
                logger.info(f"No previous {workout_type} workouts for user {user_id}")
                return RecoveryStatus(
                    ready=True,
                    days_since_last=None,
                    min_rest_required=min_rest,
                    days_until_ready=None,
                    recommendation="Welcome! This will be your first recorded workout.",
                    settings_applied=True,
                )

            # Calculate days since last workout
            last_completed = result.data[0]["completed_at"]
            if isinstance(last_completed, str):
                last_dt = datetime.fromisoformat(last_completed.replace("Z", "+00:00"))
            else:
                last_dt = last_completed

            now = datetime.now(last_dt.tzinfo) if last_dt.tzinfo else datetime.utcnow()
            days_since = (now - last_dt).days

            if days_since >= min_rest:
                return RecoveryStatus(
                    ready=True,
                    days_since_last=days_since,
                    min_rest_required=min_rest,
                    days_until_ready=0,
                    recommendation="Well rested and ready for your workout!",
                    settings_applied=True,
                )
            else:
                days_until = min_rest - days_since
                return RecoveryStatus(
                    ready=False,
                    days_since_last=days_since,
                    min_rest_required=min_rest,
                    days_until_ready=days_until,
                    recommendation=f"Consider resting {days_until} more day(s) for optimal recovery. Your body needs time to adapt and grow stronger.",
                    settings_applied=True,
                )

        except Exception as e:
            logger.error(f"Failed to check recovery status: {e}")
            return RecoveryStatus(
                ready=True,
                days_since_last=None,
                min_rest_required=None,
                days_until_ready=None,
                recommendation=None,
                settings_applied=False,
            )

    # -------------------------------------------------------------------------
    # Workout Modifications
    # -------------------------------------------------------------------------

    async def apply_senior_modifications(
        self,
        user_id: str,
        workout: Dict[str, Any],
        exercises: List[Dict[str, Any]]
    ) -> WorkoutModificationResult:
        """
        Apply senior-appropriate modifications to a workout.

        Args:
            user_id: User ID
            workout: Workout dictionary
            exercises: List of exercise dictionaries

        Returns:
            WorkoutModificationResult with modified workout and exercises
        """
        settings = await self.get_user_settings(user_id)

        if not settings:
            return WorkoutModificationResult(
                workout=workout,
                exercises=exercises,
                modified=False,
                modifications=[],
                senior_settings=None,
            )

        logger.info(f"Applying senior modifications for user {user_id}, age: {settings.user_age}")

        modified_exercises = []
        modifications_made = []

        for exercise in exercises:
            modified = exercise.copy()

            # 1. Replace high-impact exercises with low-impact alternatives
            if settings.prefer_low_impact:
                original_name = exercise.get("name", "")
                for high_impact, low_impact in LOW_IMPACT_ALTERNATIVES.items():
                    if high_impact.lower() in original_name.lower():
                        modified["name"] = low_impact
                        modified["original_name"] = original_name
                        modifications_made.append(
                            f"Replaced '{original_name}' with '{low_impact}' (low impact)"
                        )
                        break

            # 2. Reduce intensity/weight
            if "weight_kg" in modified and modified["weight_kg"]:
                intensity_factor = settings.max_intensity_percent / 100
                original_weight = modified["weight_kg"]
                new_weight = round(original_weight * intensity_factor, 1)
                modified["weight_kg"] = new_weight
                if original_weight != new_weight:
                    modifications_made.append(
                        f"Reduced weight for '{modified.get('name')}' from {original_weight}kg to {new_weight}kg"
                    )

            # 3. Cap sets at 3 for seniors
            if "sets" in modified and modified["sets"] > 3:
                original_sets = modified["sets"]
                modified["sets"] = 3
                modifications_made.append(
                    f"Reduced sets for '{modified.get('name')}' from {original_sets} to 3"
                )

            # 4. Cap reps at 12 for strength exercises
            if "reps" in modified and modified["reps"] and modified["reps"] > 12:
                exercise_type = modified.get("type", "strength")
                if exercise_type != "cardio":
                    original_reps = modified["reps"]
                    modified["reps"] = 12
                    modifications_made.append(
                        f"Reduced reps for '{modified.get('name')}' from {original_reps} to 12"
                    )

            # 5. Increase rest periods
            if "rest_seconds" in modified:
                original_rest = modified["rest_seconds"]
                new_rest = int(original_rest * settings.recovery_multiplier)
                modified["rest_seconds"] = new_rest
            else:
                modified["rest_seconds"] = int(60 * settings.recovery_multiplier)

            modified_exercises.append(modified)

        # 6. Limit number of exercises
        max_exercises = settings.max_exercises_per_session
        if len(modified_exercises) > max_exercises:
            removed_count = len(modified_exercises) - max_exercises
            modified_exercises = modified_exercises[:max_exercises]
            modifications_made.append(
                f"Limited to {max_exercises} exercises (removed {removed_count})"
            )

        # 7. Add mobility exercises at the beginning
        if settings.include_mobility_exercises:
            mobility_count = settings.mobility_exercises_per_session
            mobility_exercises = await self._get_mobility_exercises(mobility_count)
            modified_exercises = mobility_exercises + modified_exercises
            modifications_made.append(
                f"Added {mobility_count} mobility exercises for joint preparation"
            )

        # 8. Add balance exercises
        if settings.include_balance_exercises:
            balance_count = settings.balance_exercises_per_session
            balance_exercises = await self._get_balance_exercises(balance_count)
            # Add balance exercises after mobility, before main workout
            insert_index = settings.mobility_exercises_per_session if settings.include_mobility_exercises else 0
            for i, ex in enumerate(balance_exercises):
                modified_exercises.insert(insert_index + i, ex)
            modifications_made.append(
                f"Added {balance_count} balance exercises for stability"
            )

        # 9. Adjust workout metadata
        modified_workout = workout.copy()
        modified_workout["extended_warmup_minutes"] = settings.extended_warmup_minutes
        modified_workout["extended_cooldown_minutes"] = settings.extended_cooldown_minutes
        modified_workout["senior_modified"] = True
        modified_workout["max_intensity_applied"] = settings.max_intensity_percent

        if settings.custom_notes:
            existing_notes = modified_workout.get("notes", "")
            modified_workout["notes"] = f"{existing_notes}\n\nSenior notes: {settings.custom_notes}".strip()

        return WorkoutModificationResult(
            workout=modified_workout,
            exercises=modified_exercises,
            modified=True,
            modifications=modifications_made,
            senior_settings=settings,
        )

    async def _get_mobility_exercises(self, count: int) -> List[Dict[str, Any]]:
        """Get mobility exercises from database or use defaults."""
        try:
            result = self.db.client.table("senior_mobility_exercises").select(
                "*"
            ).eq("is_active", True).limit(count).execute()

            if result.data:
                return [
                    {
                        "name": ex["name"],
                        "type": "mobility",
                        "sets": ex.get("sets", 2),
                        "reps": ex.get("reps", 10),
                        "duration_seconds": ex.get("duration_seconds"),
                        "rest_seconds": 30,
                        "target_muscles": ex.get("target_muscles", []),
                        "instructions": ex.get("instructions", []),
                    }
                    for ex in result.data
                ]
        except Exception as e:
            logger.warning(f"Failed to get mobility exercises from DB: {e}")

        # Return defaults
        return DEFAULT_MOBILITY_EXERCISES[:count]

    async def _get_balance_exercises(self, count: int) -> List[Dict[str, Any]]:
        """Get balance exercises for fall prevention."""
        return DEFAULT_BALANCE_EXERCISES[:count]

    # -------------------------------------------------------------------------
    # Workout Logging
    # -------------------------------------------------------------------------

    async def log_workout_completion(
        self,
        user_id: str,
        workout_id: Optional[str],
        workout_type: str,
        intensity_level: int,
        duration_minutes: int,
        modifications_applied: Optional[List[str]] = None,
        post_workout_feeling: Optional[str] = None,
        notes: Optional[str] = None,
    ) -> bool:
        """
        Log a completed workout for recovery tracking.

        Args:
            user_id: User ID
            workout_id: Optional workout ID
            workout_type: Type of workout (strength, cardio, mixed)
            intensity_level: Intensity level (0-100)
            duration_minutes: Duration in minutes
            modifications_applied: List of modifications made
            post_workout_feeling: How user felt after (great, good, tired, sore, painful)
            notes: Additional notes

        Returns:
            True if logged successfully
        """
        try:
            self.db.client.table("senior_workout_log").insert({
                "user_id": user_id,
                "workout_id": workout_id,
                "workout_type": workout_type,
                "intensity_level": min(100, max(0, intensity_level)),
                "duration_minutes": duration_minutes,
                "modifications_applied": modifications_applied,
                "post_workout_feeling": post_workout_feeling,
                "notes": notes,
                "completed_at": datetime.utcnow().isoformat(),
            }).execute()

            logger.info(f"Logged senior workout for user {user_id}: {workout_type}, intensity {intensity_level}")
            return True

        except Exception as e:
            logger.error(f"Failed to log senior workout: {e}")
            return False

    # -------------------------------------------------------------------------
    # AI Prompt Context
    # -------------------------------------------------------------------------

    def generate_prompt_context(self, settings: SeniorSettings) -> str:
        """
        Generate context string for AI workout generation prompts.

        Args:
            settings: SeniorSettings for the user

        Returns:
            Context string to append to AI prompts
        """
        context_parts = [
            "## Senior Fitness Considerations",
            f"User is {settings.user_age} years old - apply age-appropriate modifications:",
            "",
            "### Key Guidelines:",
            f"- Maximum intensity: {settings.max_intensity_percent}% of normal",
            f"- Maximum {settings.max_exercises_per_session} exercises per session",
            f"- Extended warmup required: {settings.extended_warmup_minutes} minutes",
            f"- Extended cooldown required: {settings.extended_cooldown_minutes} minutes",
            f"- Rest periods multiplied by {settings.recovery_multiplier}x",
        ]

        if settings.prefer_low_impact:
            context_parts.extend([
                "",
                "### Low-Impact Requirements:",
                "- AVOID: Jump squats, burpees, box jumps, jumping lunges, high knees",
                "- PREFER: Bodyweight squats, step-ups, stationary lunges, marching in place",
                "- AVOID: Explosive or ballistic movements",
                "- PREFER: Controlled, steady movements",
            ])

        if settings.include_mobility_exercises:
            context_parts.extend([
                "",
                f"### Mobility Focus:",
                f"- Include {settings.mobility_exercises_per_session} mobility exercises",
                "- Focus on joint preparation and range of motion",
            ])

        if settings.include_balance_exercises:
            context_parts.extend([
                "",
                f"### Balance & Stability:",
                f"- Include {settings.balance_exercises_per_session} balance exercises",
                "- Important for fall prevention",
            ])

        age_specific = []
        if settings.user_age and settings.user_age >= 75:
            age_specific = [
                "",
                "### Special Age 75+ Considerations:",
                "- Extra caution with all movements",
                "- Chair-assisted exercises when possible",
                "- Shorter workout duration preferred",
                "- Quality over quantity always",
                "- Immediate rest if any discomfort",
            ]
        elif settings.user_age and settings.user_age >= 70:
            age_specific = [
                "",
                "### Special Age 70+ Considerations:",
                "- Focus on functional movements",
                "- Include sit-to-stand exercises",
                "- Prioritize core stability",
            ]

        context_parts.extend(age_specific)

        if settings.custom_notes:
            context_parts.extend([
                "",
                "### User Notes:",
                settings.custom_notes,
            ])

        return "\n".join(context_parts)

    # -------------------------------------------------------------------------
    # Quick Checks
    # -------------------------------------------------------------------------

    async def is_senior_user(self, user_id: str) -> Tuple[bool, Optional[int]]:
        """
        Check if a user is a senior (60+).

        Args:
            user_id: User ID

        Returns:
            Tuple of (is_senior: bool, age: Optional[int])
        """
        try:
            result = self.db.client.table("users").select("age").eq("id", user_id).execute()
            if result.data:
                age = result.data[0].get("age")
                if age and age >= 60:
                    return (True, age)
            return (False, result.data[0].get("age") if result.data else None)
        except Exception as e:
            logger.error(f"Failed to check if user is senior: {e}")
            return (False, None)

    async def get_low_impact_alternative(self, exercise_name: str) -> str:
        """
        Get low-impact alternative for an exercise.

        Args:
            exercise_name: Original exercise name

        Returns:
            Alternative exercise name or original if no alternative
        """
        # Check database first
        try:
            result = self.db.client.table("low_impact_alternatives").select(
                "alternative_exercise"
            ).ilike("original_exercise", exercise_name).execute()

            if result.data:
                return result.data[0]["alternative_exercise"]
        except Exception as e:
            logger.warning(f"Failed to check low impact alternatives in DB: {e}")

        # Fall back to in-memory mapping
        for original, alternative in LOW_IMPACT_ALTERNATIVES.items():
            if original.lower() in exercise_name.lower():
                return alternative

        return exercise_name


# Singleton instance
_senior_workout_service: Optional[SeniorWorkoutService] = None


def get_senior_workout_service() -> SeniorWorkoutService:
    """Get the singleton SeniorWorkoutService instance."""
    global _senior_workout_service
    if _senior_workout_service is None:
        _senior_workout_service = SeniorWorkoutService()
    return _senior_workout_service
