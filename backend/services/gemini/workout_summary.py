"""
Gemini Service Workout Summary & Exercise Reasoning.
"""
import asyncio
import json
import logging
import time
from typing import List, Dict, Optional

from google.genai import types
from core.config import get_settings
from models.gemini_schemas import ExerciseReasoningResponse
from services.gemini.constants import (
    client, _log_token_usage, _gemini_semaphore,
    _summary_cache, settings,
)
from services.gemini.utils import _sanitize_for_prompt

logger = logging.getLogger("gemini")


class WorkoutSummaryMixin:
    """Mixin providing workout summary and exercise reasoning methods for GeminiService."""

    async def generate_workout_summary(
        self,
        workout_name: str,
        exercises: List[Dict],
        target_muscles: List[str],
        user_goals: List[str],
        fitness_level: str,
        workout_id: str = None,
        duration_minutes: int = 45,
        workout_type: str = None,
        difficulty: str = None
    ) -> str:
        """
        Generate an AI summary/description of a workout using the Workout Insights agent.

        Args:
            workout_name: Name of the workout
            exercises: List of exercises with their details
            target_muscles: Target muscle groups
            user_goals: User's fitness goals
            fitness_level: User's fitness level
            workout_id: Optional workout ID
            duration_minutes: Workout duration in minutes
            workout_type: Type of workout (strength, cardio, etc.)
            difficulty: Difficulty level

        Returns:
            Plain-text workout summary (2-3 sentences, no markdown)
        """
        # Check summary cache first (same workout data should return same summary)
        try:
            # Build cache key from workout content (exercises define the workout)
            exercise_names = [ex.get("name", "") for ex in exercises] if exercises else []
            cache_key = _summary_cache.make_key(
                "summary", workout_name, exercise_names, target_muscles,
                user_goals, fitness_level, duration_minutes, workout_type, difficulty
            )
            cached_result = await _summary_cache.get(cache_key)
            if cached_result is not None:
                logger.info(f"[SummaryCache] Cache HIT for workout: '{workout_name}'")
                return cached_result
        except Exception as cache_err:
            logger.warning(f"[SummaryCache] Cache lookup error (falling through): {cache_err}")

        try:
            # Use the Workout Insights LangGraph agent
            from services.langgraph_agents.workout_insights.graph import generate_workout_insights

            summary = await generate_workout_insights(
                workout_id=workout_id or "unknown",
                workout_name=workout_name,
                exercises=exercises,
                duration_minutes=duration_minutes,
                workout_type=workout_type,
                difficulty=difficulty,
                user_goals=user_goals,
                fitness_level=fitness_level,
            )

            # Cache the result
            try:
                await _summary_cache.set(cache_key, summary)
                logger.info(f"[SummaryCache] Cache MISS - stored summary for: '{workout_name}'")
            except Exception as cache_err:
                logger.warning(f"[SummaryCache] Failed to store result: {cache_err}")

            return summary

        except Exception as e:
            logger.error(f"Error generating workout summary with agent: {e}")
            raise  # No fallback - let errors propagate

    async def generate_exercise_reasoning(
        self,
        workout_name: str,
        exercises: List[Dict],
        user_profile: Dict,
        program_preferences: Dict,
        workout_type: str = "strength",
        difficulty: str = "intermediate",
    ) -> Dict:
        """
        Generate AI-powered reasoning for why each exercise was selected.

        Args:
            workout_name: Name of the workout
            exercises: List of exercises with their details
            user_profile: User's profile (goals, fitness_level, equipment, injuries)
            program_preferences: Program preferences (training_split, focus_areas)
            workout_type: Type of workout
            difficulty: Difficulty level

        Returns:
            Dict with 'workout_reasoning' (str) and 'exercise_reasoning' (list of dicts)
        """
        try:
            # Extract relevant data
            exercise_list = []
            for ex in exercises[:8]:  # Limit to 8 exercises for token efficiency
                exercise_list.append({
                    "name": ex.get("name", "Unknown"),
                    "muscle": ex.get("muscle_group") or ex.get("primary_muscle") or "general",
                    "equipment": ex.get("equipment", "bodyweight"),
                    "sets": ex.get("sets", 3),
                    "reps": ex.get("reps", "8-12"),
                })

            user_goals = user_profile.get("goals", [])
            fitness_level = user_profile.get("fitness_level", "intermediate")
            user_equipment = user_profile.get("equipment", [])
            injuries = user_profile.get("injuries", [])
            training_split = program_preferences.get("training_split", "full_body")
            focus_areas = program_preferences.get("focus_areas", [])

            # Get rich split context with scientific rationale
            split_context = get_split_context(training_split)

            prompt = f"""You are a certified personal trainer explaining workout design to a client.

WORKOUT: {workout_name}
TYPE: {workout_type}
DIFFICULTY: {difficulty}

{split_context}

USER PROFILE:
- Fitness Level: {fitness_level}
- Goals: {safe_join_list(user_goals, 'general fitness')}
- Equipment Available: {safe_join_list(user_equipment, 'various')}
- Injuries/Limitations: {safe_join_list(injuries, 'none noted')}
- Focus Areas: {safe_join_list(focus_areas, 'balanced')}

EXERCISES:
{chr(10).join([f"- {ex['name']} ({ex['muscle']}, {ex['sets']}x{ex['reps']}, {ex['equipment']})" for ex in exercise_list])}

Generate personalized reasoning. Return ONLY valid JSON:

{{
    "workout_reasoning": "1-2 sentences explaining the overall workout design philosophy and how it matches the user's goals",
    "exercise_reasoning": [
        {{
            "exercise_name": "exact exercise name",
            "reasoning": "1 sentence explaining why THIS exercise was chosen for THIS user (mention specific goals, equipment match, or how it fits their level)"
        }}
    ]
}}

RULES:
1. Be specific - mention actual goals, equipment, or fitness level
2. Each exercise reasoning should be unique and personal
3. Reference the training split/focus if relevant
4. Keep each reasoning to ONE focused sentence
5. Avoid generic phrases like "great exercise" or "builds strength"
"""

            # Retry logic for intermittent failures
            max_retries = 2
            last_error = None
            content = ""

            for attempt in range(max_retries + 1):
                try:
                    response = await asyncio.wait_for(
                        client.aio.models.generate_content(
                            model=self.model,
                            contents=prompt,
                            config=types.GenerateContentConfig(
                                response_mime_type="application/json",
                                response_schema=ExerciseReasoningResponse,
                                temperature=0.7,
                                max_output_tokens=4000,  # Increased to prevent truncation
                            ),
                        ),
                        timeout=30,  # 30s for exercise reasoning
                    )

                    # Use response.parsed for structured output - SDK handles JSON parsing
                    parsed = response.parsed
                    if not parsed:
                        logger.warning(f"[Exercise Reasoning] Empty response (attempt {attempt + 1})")
                        last_error = "Empty response from Gemini"
                        continue

                    result = parsed.model_dump()

                    if result.get("workout_reasoning") and result.get("exercise_reasoning"):
                        return {
                            "workout_reasoning": result.get("workout_reasoning", ""),
                            "exercise_reasoning": result.get("exercise_reasoning", []),
                        }
                    else:
                        logger.warning(f"[Exercise Reasoning] Incomplete result (attempt {attempt + 1})")
                        last_error = "Incomplete result from Gemini"
                        continue

                except Exception as e:
                    logger.warning(f"[Exercise Reasoning] Failed (attempt {attempt + 1}): {e}")
                    last_error = str(e)
                    continue

            logger.error(f"[Exercise Reasoning] All {max_retries + 1} attempts failed. Last error: {last_error}")
            return {
                "workout_reasoning": "",
                "exercise_reasoning": [],
            }

        except Exception as e:
            logger.error(f"Error generating exercise reasoning: {e}")
            # Return empty result - caller should use fallback
            return {
                "workout_reasoning": "",
                "exercise_reasoning": [],
            }

