"""Second part of workout_generation_helpers.py (auto-split for size)."""
from typing import Dict, List, Optional
import asyncio
import logging

from google.genai import types
from models.gemini_schemas import WorkoutNamingResponse
from services.gemini.constants import gemini_generate_with_retry

logger = logging.getLogger(__name__)


class WorkoutGenerationMixinPart2:
    """Second half of WorkoutGenerationMixin methods. Use as mixin."""

    async def generate_workout_from_library(
        self,
        exercises: List[Dict],
        fitness_level: str,
        goals: List[str],
        duration_minutes: int = 45,
        focus_areas: Optional[List[str]] = None,
        avoid_name_words: Optional[List[str]] = None,
        workout_date: Optional[str] = None,
        age: Optional[int] = None,
        activity_level: Optional[str] = None,
        intensity_preference: Optional[str] = None,
        custom_program_description: Optional[str] = None,
        workout_type_preference: Optional[str] = None,
        comeback_context: Optional[str] = None,
        strength_history: Optional[Dict[str, Dict]] = None,
        personal_bests: Optional[Dict[str, Dict]] = None,
        user_dob: Optional[str] = None,
    ) -> Dict:
        """
        Generate a workout plan using exercises from the exercise library.

        Instead of having AI invent exercises, this method takes pre-selected
        exercises from the library and asks AI to create a creative workout
        name and organize them appropriately.

        Args:
            exercises: List of exercises from the exercise library
            fitness_level: beginner, intermediate, or advanced
            goals: List of fitness goals
            duration_minutes: Target workout duration
            focus_areas: Optional specific areas to focus on
            avoid_name_words: Words to avoid in workout name
            workout_date: Optional date for holiday theming
            age: Optional user's age for age-appropriate adjustments
            activity_level: Optional activity level
            intensity_preference: Optional intensity preference (easy, medium, hard)
            custom_program_description: Optional user's custom program description (e.g., "Train for HYROX")
            workout_type_preference: Optional workout type preference (strength, cardio, mixed)
            comeback_context: Optional context string for users returning from extended breaks
            strength_history: Optional dict of exercise performance history (last weight, max weight, reps)
            personal_bests: Optional dict of user's personal records per exercise

        Returns:
            Dict with workout structure
        """
        if not exercises:
            raise ValueError("No exercises provided")

        # Use intensity_preference if provided, otherwise derive from fitness_level
        if intensity_preference:
            difficulty = intensity_preference

            # Warn about potentially dangerous combinations
            if fitness_level == "beginner" and intensity_preference == "hell":
                logger.warning(f"[Gemini] Beginner fitness level with HELL intensity - this is extremely challenging!")
            elif fitness_level == "beginner" and intensity_preference == "hard":
                logger.warning(f"[Gemini] Beginner fitness level with hard intensity preference - ensure exercises are scaled appropriately")
            elif fitness_level == "intermediate" and intensity_preference == "hell":
                logger.info(f"[Gemini] Intermediate fitness level with HELL intensity - maximum challenge mode")
            elif fitness_level == "intermediate" and intensity_preference == "hard":
                logger.info(f"[Gemini] Intermediate fitness level with hard intensity - will challenge the user")
            elif intensity_preference == "hell":
                logger.info(f"[Gemini] HELL MODE ACTIVATED - generating maximum intensity workout from library")
        else:
            difficulty = "easy" if fitness_level == "beginner" else ("hard" if fitness_level == "advanced" else "medium")

        # Build avoid words instruction
        avoid_instruction = ""
        if avoid_name_words and len(avoid_name_words) > 0:
            avoid_instruction = f"\n\n⚠️ Do NOT use these words in the workout name: {', '.join(avoid_name_words[:15])}"

        # Check for holiday theming
        holiday_theme = self._get_holiday_theme(workout_date, user_dob=user_dob)
        holiday_instruction = f"\n\n{holiday_theme}" if holiday_theme else ""

        # Add safety instruction if there's a mismatch between fitness level and intensity
        safety_instruction = ""
        if fitness_level == "beginner" and difficulty == "hard":
            safety_instruction = "\n\n⚠️ SAFETY NOTE: User is a beginner but wants hard intensity. Structure exercises with more rest periods and ensure reps/sets are achievable with proper form. Focus on compound movements rather than advanced techniques."

        # Build custom program context if user has specified a custom training goal
        custom_program_context = ""
        if custom_program_description and custom_program_description.strip():
            custom_program_context = f"\n- Custom Training Goal: {custom_program_description}"

        # Add age context for appropriate naming and notes
        age_context = ""
        if age:
            if age >= 75:
                age_context = f"\n- Age: {age} (elderly - focus on gentle, supportive movements)"
            elif age >= 60:
                age_context = f"\n- Age: {age} (senior - prioritize low-impact, balance-focused exercises)"
            elif age >= 45:
                age_context = f"\n- Age: {age} (middle-aged - joint-friendly approach)"
            else:
                age_context = f"\n- Age: {age}"

        # Determine workout type
        workout_type = workout_type_preference if workout_type_preference else "strength"

        # Build comeback instruction
        comeback_instruction = ""
        if comeback_context and comeback_context.strip():
            logger.info(f"🔄 [Gemini Service] Library workout - user in comeback mode")
            comeback_instruction = f"\n\n🔄 COMEBACK NOTE: User is returning from an extended break. Include comeback/return-to-training themes in the name (e.g., 'Comeback', 'Return', 'Fresh Start')."

        # Build performance context from strength history and personal bests
        performance_context = ""
        if strength_history or personal_bests:
            from api.v1.workouts.utils import format_performance_context
            performance_context = format_performance_context(
                exercises, strength_history or {}, personal_bests or {}
            )
            if performance_context:
                performance_context = f"\n\n{performance_context}"
                logger.info(f"[Gemini Service] Added performance context for {len([ex for ex in exercises if strength_history.get(ex.get('name')) or personal_bests.get(ex.get('name'))])} exercises")

        # Format exercises for the prompt
        exercise_list = "\n".join([
            f"- {ex.get('name', 'Unknown')}: targets {ex.get('muscle_group', 'unknown')}, equipment: {ex.get('equipment', 'bodyweight')}"
            for ex in exercises
        ])

        # Difficulty-aware naming hints
        difficulty_naming = ""
        if difficulty in ("hell", "extreme"):
            difficulty_naming = "\nThis is HELL MODE. Name MUST reflect EXTREME intensity (Inferno, Destroyer, Savage, Beast, Annihilation)."
        elif difficulty == "hard":
            difficulty_naming = "\nThis is a hard workout. Name should reflect high intensity and challenge."
        elif difficulty == "easy":
            difficulty_naming = "\nThis is an easy/recovery workout. Name should be approachable and light."

        prompt = f"""I have selected these exercises for a {duration_minutes}-minute {focus_areas[0] if focus_areas else 'full body'} workout:

{exercise_list}

User profile:
- Fitness Level: {fitness_level}
- Goals: {', '.join(goals) if goals else 'General fitness'}{age_context}{custom_program_context}{performance_context}{safety_instruction}
{difficulty_naming}
Create a CREATIVE and MOTIVATING workout name (3-4 words) that reflects the user's training focus.

Examples of good names:
- "Thunder Strike Legs"
- "Phoenix Power Chest"
- "Savage Wolf Back"
- "Iron Storm Arms"
{holiday_instruction}{avoid_instruction}{comeback_instruction}

Return a JSON object with:
{{
  "name": "Your creative workout name here",
  "type": "{workout_type}",
  "difficulty": "{difficulty}",
  "notes": "A personalized tip for this workout based on the user's performance history (1-2 sentences). Reference their progress towards PRs or recent improvements if available."
}}"""

        # Log the full prompt for debugging
        logger.info("=" * 80)
        logger.info("[GEMINI PROMPT - generate_workout_from_library]")
        logger.info(f"Parameters: fitness_level={fitness_level}, goals={goals}, duration={duration_minutes}min")
        logger.info(f"Focus areas: {focus_areas}, intensity_preference={intensity_preference}")
        logger.info(f"Custom program description: {custom_program_description}")
        logger.info(f"Exercise count: {len(exercises)}")
        logger.info(f"Exercise names: {[ex.get('name') for ex in exercises]}")
        logger.info(f"Strength history: {len(strength_history) if strength_history else 0} exercises")
        logger.info(f"Personal bests: {len(personal_bests) if personal_bests else 0} exercises")
        logger.info("-" * 40)
        logger.info(f"FULL PROMPT:\n{prompt}")
        logger.info("=" * 80)

        try:
            response = await gemini_generate_with_retry(
                model=self.model,
                contents=prompt,
                config=types.GenerateContentConfig(
                    system_instruction="You are a creative fitness coach. Generate motivating workout names. Return ONLY valid JSON.",
                    response_mime_type="application/json",
                    response_schema=WorkoutNamingResponse,
                    temperature=0.8,
                    max_output_tokens=2000  # Increased for thinking models
                ),
                timeout=30,
                method_name="generate_workout_from_library",
            )

            # Use response.parsed for structured output - SDK handles JSON parsing
            ai_response = response.parsed
            if not ai_response:
                raise ValueError("Gemini returned empty workout naming response")

            # Combine AI response with our exercises
            return {
                "name": ai_response.name or "Power Workout",
                "type": ai_response.type or "strength",
                "difficulty": difficulty,
                "duration_minutes": duration_minutes,
                "target_muscles": list(set([ex.get('muscle_group', '') for ex in exercises if ex.get('muscle_group')])),
                "exercises": exercises,
                "notes": ai_response.notes or "Focus on proper form and controlled movements."
            }

        except Exception as e:
            logger.error(f"Error generating workout name: {e}", exc_info=True)
            raise  # No fallback - let errors propagate

