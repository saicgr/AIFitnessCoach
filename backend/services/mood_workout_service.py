"""
Mood Workout Service
====================
Maps user moods to workout parameters and generates quick workouts
based on how the user is feeling.

Mood Types:
- great: High energy, ready for challenging workout
- good: Normal energy, balanced workout
- tired: Low energy, recovery/mobility focus
- stressed: Mental stress, stress-relief cardio/flow
"""

from dataclasses import dataclass
from enum import Enum
from typing import Optional, List, Dict, Any
from datetime import datetime
import logging

logger = logging.getLogger(__name__)


class MoodType(str, Enum):
    """User mood types for quick workout generation."""
    GREAT = "great"
    GOOD = "good"
    TIRED = "tired"
    STRESSED = "stressed"


@dataclass
class MoodWorkoutConfig:
    """Configuration for workout generation based on mood."""
    intensity_preference: str  # easy, medium, hard
    workout_type_preference: str  # strength, cardio, mixed, mobility, recovery
    duration_default: int  # minutes
    duration_range: tuple  # (min, max) minutes
    focus_keywords: List[str]
    ai_prompt_suffix: str
    warmup_duration: int  # minutes
    cooldown_duration: int  # minutes
    max_exercises: int
    rest_multiplier: float  # Multiplier for rest periods (1.0 = normal)
    emoji: str
    color_hex: str


# Mood to workout parameter mapping
MOOD_CONFIGS: Dict[MoodType, MoodWorkoutConfig] = {
    MoodType.GREAT: MoodWorkoutConfig(
        intensity_preference="hard",
        workout_type_preference="strength",
        duration_default=25,
        duration_range=(20, 30),
        focus_keywords=["power", "explosive", "challenging", "intense", "push limits"],
        ai_prompt_suffix="Create an energizing, challenging workout. User is feeling great and ready to push themselves. Include compound movements and higher intensity exercises.",
        warmup_duration=3,
        cooldown_duration=2,
        max_exercises=6,
        rest_multiplier=0.8,  # Shorter rest for high energy
        emoji="🔥",
        color_hex="#4CAF50",  # Green
    ),
    MoodType.GOOD: MoodWorkoutConfig(
        intensity_preference="medium",
        workout_type_preference="mixed",
        duration_default=20,
        duration_range=(15, 25),
        focus_keywords=["balanced", "effective", "steady", "productive"],
        ai_prompt_suffix="Create a balanced workout with steady progression. User is feeling good and ready for a solid session. Mix of strength and conditioning.",
        warmup_duration=3,
        cooldown_duration=2,
        max_exercises=5,
        rest_multiplier=1.0,  # Normal rest
        emoji="😊",
        color_hex="#2196F3",  # Blue
    ),
    MoodType.TIRED: MoodWorkoutConfig(
        intensity_preference="easy",
        workout_type_preference="mobility",
        duration_default=15,
        duration_range=(10, 20),
        focus_keywords=["gentle", "restorative", "light", "energizing", "recovery"],
        ai_prompt_suffix="Create a gentle, restorative workout. User is feeling tired - focus on mobility, light movement, and recovery. Goal is to energize without exhausting.",
        warmup_duration=2,
        cooldown_duration=3,  # Longer cooldown for recovery
        max_exercises=4,
        rest_multiplier=1.5,  # Longer rest for low energy
        emoji="😴",
        color_hex="#FF9800",  # Orange
    ),
    MoodType.STRESSED: MoodWorkoutConfig(
        intensity_preference="medium",
        workout_type_preference="cardio",
        duration_default=20,
        duration_range=(15, 25),
        focus_keywords=["stress-relief", "flowing", "rhythmic", "mindful", "calming"],
        ai_prompt_suffix="Create a stress-relieving workout. User is feeling stressed - focus on rhythmic cardio, flowing movements, and exercises that help release tension. Include breathing cues.",
        warmup_duration=3,
        cooldown_duration=4,  # Longer cooldown for stress relief
        max_exercises=5,
        rest_multiplier=1.2,  # Slightly longer rest
        emoji="😤",
        color_hex="#9C27B0",  # Purple
    ),
}


@dataclass
class MoodCheckIn:
    """Represents a mood check-in record."""
    id: Optional[str] = None
    user_id: str = ""
    mood: MoodType = MoodType.GOOD
    check_in_time: Optional[datetime] = None
    workout_generated: bool = False
    workout_id: Optional[str] = None
    workout_completed: bool = False
    context: Optional[Dict[str, Any]] = None


class MoodWorkoutService:
    """Service for generating workouts based on user mood."""

    def __init__(self):
        self.configs = MOOD_CONFIGS

    def get_mood_config(self, mood: MoodType) -> MoodWorkoutConfig:
        """Get workout configuration for a specific mood."""
        return self.configs[mood]

    def get_workout_params(
        self,
        mood: MoodType,
        user_fitness_level: str = "intermediate",
        user_goals: Optional[List[str]] = None,
        user_equipment: Optional[List[str]] = None,
        duration_override: Optional[int] = None,
    ) -> Dict[str, Any]:
        """
        Generate workout parameters based on mood and user profile.

        Args:
            mood: User's current mood
            user_fitness_level: User's fitness level (beginner/intermediate/advanced)
            user_goals: User's fitness goals
            user_equipment: Available equipment
            duration_override: Optional duration override (within mood's range)

        Returns:
            Dictionary of workout generation parameters
        """
        config = self.get_mood_config(mood)

        # Determine duration
        if duration_override:
            # Clamp to mood's valid range
            duration = max(
                config.duration_range[0],
                min(config.duration_range[1], duration_override)
            )
        else:
            duration = config.duration_default

        # Adjust intensity based on fitness level
        intensity = config.intensity_preference
        if user_fitness_level == "beginner" and intensity == "hard":
            intensity = "medium"
        elif user_fitness_level == "advanced" and intensity == "easy":
            intensity = "medium"

        # Calculate workout structure
        main_workout_duration = duration - config.warmup_duration - config.cooldown_duration
        time_per_exercise = main_workout_duration / config.max_exercises

        return {
            "mood": mood.value,
            "mood_emoji": config.emoji,
            "mood_color": config.color_hex,
            "duration_minutes": duration,
            "intensity_preference": intensity,
            "workout_type_preference": config.workout_type_preference,
            "fitness_level": user_fitness_level,
            "goals": user_goals or [],
            "equipment": user_equipment or [],
            "focus_keywords": config.focus_keywords,
            "ai_prompt_suffix": config.ai_prompt_suffix,
            "warmup_duration": config.warmup_duration,
            "cooldown_duration": config.cooldown_duration,
            "max_exercises": config.max_exercises,
            "rest_multiplier": config.rest_multiplier,
            "main_workout_duration": main_workout_duration,
            "time_per_exercise": time_per_exercise,
        }

    def build_generation_prompt(
        self,
        mood: MoodType,
        user_fitness_level: str,
        user_goals: List[str],
        user_equipment: List[str],
        duration_minutes: int,
    ) -> str:
        """
        Build a Gemini prompt for mood-based workout generation.

        Args:
            mood: User's current mood
            user_fitness_level: beginner/intermediate/advanced
            user_goals: User's fitness goals
            user_equipment: Available equipment
            duration_minutes: Target workout duration

        Returns:
            Formatted prompt string for Gemini
        """
        config = self.get_mood_config(mood)
        params = self.get_workout_params(
            mood=mood,
            user_fitness_level=user_fitness_level,
            user_goals=user_goals,
            user_equipment=user_equipment,
            duration_override=duration_minutes,
        )

        # Safely join lists - handle case where items might be dicts
        def safe_join(items, default=""):
            if not items:
                return default
            result = []
            for item in items:
                if isinstance(item, str):
                    result.append(item)
                elif isinstance(item, dict):
                    name = item.get("name") or item.get("goal") or item.get("title") or str(item)
                    result.append(str(name))
                else:
                    result.append(str(item))
            return ", ".join(result) if result else default

        equipment_str = safe_join(user_equipment, "Bodyweight only")
        goals_str = safe_join(user_goals, "General fitness")

        # Calculate main workout duration (excluding warmup/cooldown which are added separately)
        main_workout_duration = params['main_workout_duration']

        prompt = f"""Generate a {main_workout_duration}-minute quick workout for a user who is feeling {mood.value.upper()} {config.emoji}.

{config.ai_prompt_suffix}

USER PROFILE:
- Fitness Level: {user_fitness_level}
- Goals: {goals_str}
- Available Equipment: {equipment_str}

WORKOUT REQUIREMENTS:
- Duration: {main_workout_duration} minutes (MAIN EXERCISES ONLY - warmup/cooldown added separately)
- Intensity: {params['intensity_preference']}
- Type: {config.workout_type_preference}
- Maximum Exercises: {config.max_exercises}

IMPORTANT GUIDELINES:
- Create a motivating workout name that reflects the "{mood.value}" mood (3-5 words max)
- Focus on exercises that match the mood: {', '.join(config.focus_keywords)}
- Rest periods should be {"shorter" if config.rest_multiplier < 1 else "longer" if config.rest_multiplier > 1 else "normal"} than usual
- Include clear form cues in exercise notes
- Make it achievable within the time limit

🚨 CRITICAL - EQUIPMENT USAGE:
If the user has gym equipment (dumbbells, barbell, machines, full_gym, cable_machine):
- AT LEAST 70% of exercises MUST use that equipment
- Do NOT generate mostly bodyweight exercises when gym equipment is available
- For beginners with gym access: Use machines and dumbbells, NOT just push-ups and planks
- Example: If user has dumbbells → Dumbbell Press, Dumbbell Rows, Goblet Squats, etc.

Return a JSON object with this exact structure:
{{
    "name": "Creative Workout Name",
    "type": "{config.workout_type_preference}",
    "difficulty": "{params['intensity_preference']}",
    "mood_based": true,
    "mood": "{mood.value}",
    "exercises": [
        {{
            "name": "Exercise Name",
            "sets": 3,
            "reps": "10-12",
            "rest_seconds": 45,
            "muscle_group": "chest",
            "equipment": "dumbbells",
            "notes": "Form cue or modification"
        }}
    ],
    "estimated_duration_minutes": {main_workout_duration},
    "motivational_message": "A brief encouraging message for someone feeling {mood.value}"
}}

Return ONLY the JSON object, no additional text.
NOTE: Warmup and cooldown exercises will be added separately using our exercise library - only generate main workout exercises."""

        return prompt

    def get_context_data(
        self,
        device: Optional[str] = None,
        app_version: Optional[str] = None,
        previous_mood: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Build context data for logging.

        Args:
            device: Device type (ios/android)
            app_version: App version string
            previous_mood: User's previous mood (if any)

        Returns:
            Context dictionary for logging
        """
        now = datetime.now()
        hour = now.hour

        # Determine time of day
        if 5 <= hour < 12:
            time_of_day = "morning"
        elif 12 <= hour < 17:
            time_of_day = "afternoon"
        elif 17 <= hour < 21:
            time_of_day = "evening"
        else:
            time_of_day = "night"

        return {
            "time_of_day": time_of_day,
            "day_of_week": now.strftime("%A").lower(),
            "hour": hour,
            "device": device,
            "app_version": app_version,
            "previous_mood": previous_mood,
        }

    @staticmethod
    def validate_mood(mood_str: str) -> MoodType:
        """
        Validate and convert mood string to MoodType.

        Args:
            mood_str: Mood string to validate

        Returns:
            MoodType enum value

        Raises:
            ValueError: If mood string is invalid
        """
        try:
            return MoodType(mood_str.lower())
        except ValueError:
            valid_moods = [m.value for m in MoodType]
            raise ValueError(
                f"Invalid mood '{mood_str}'. Must be one of: {', '.join(valid_moods)}"
            )

    def get_all_moods(self) -> List[Dict[str, Any]]:
        """
        Get all available moods with their display info.

        Returns:
            List of mood info dictionaries
        """
        return [
            {
                "value": mood.value,
                "emoji": config.emoji,
                "color": config.color_hex,
                "label": mood.value.capitalize(),
                "description": config.ai_prompt_suffix.split(".")[0],
            }
            for mood, config in self.configs.items()
        ]


# Singleton instance
mood_workout_service = MoodWorkoutService()
