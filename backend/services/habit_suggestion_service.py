"""
Habit Suggestion Service - AI-powered habit suggestions using Gemini.

Provides personalized habit suggestions based on:
- User's fitness goals
- Current habit patterns
- Fitness level and workout frequency
- Nutrition preferences
"""

from google import genai
from google.genai import types
from typing import List, Dict, Optional, Any
import json
import logging
import re
from core.config import get_settings
from core.logger import get_logger

settings = get_settings()
logger = get_logger(__name__)

# Initialize the Gemini client
client = genai.Client(api_key=settings.gemini_api_key)


class HabitSuggestionService:
    """
    AI-powered habit suggestion service using Gemini.

    Generates personalized habit suggestions based on user context
    and existing habits to avoid duplicates.
    """

    def __init__(self):
        self.model = settings.gemini_model

    async def get_personalized_suggestions(
        self,
        user_context: Dict[str, Any],
        current_habits: List[str],
        goals: Optional[List[str]] = None,
        max_suggestions: int = 5,
    ) -> List[Dict[str, Any]]:
        """
        Get AI-generated personalized habit suggestions.

        Args:
            user_context: User profile data (fitness_level, workout_frequency, goals)
            current_habits: List of habit names the user already has
            goals: Optional list of specific goals to focus on
            max_suggestions: Maximum number of suggestions to return

        Returns:
            List of habit suggestion dictionaries
        """
        logger.info(f"🤖 Generating personalized habit suggestions")
        logger.info(f"   User context: {user_context}")
        logger.info(f"   Current habits: {current_habits}")
        logger.info(f"   Goals: {goals}")

        try:
            # Build the prompt
            prompt = self._build_suggestion_prompt(
                user_context=user_context,
                current_habits=current_habits,
                goals=goals,
                max_suggestions=max_suggestions,
            )

            # Call Gemini
            response = await client.aio.models.generate_content(
                model=self.model,
                contents=[types.Content(role="user", parts=[types.Part.from_text(text=prompt)])],
                config=types.GenerateContentConfig(
                    system_instruction=self._get_system_prompt(),
                    max_output_tokens=2048,
                    temperature=0.7,  # Slightly creative but not too random
                ),
            )

            # Parse the response
            suggestions = self._parse_suggestions(response.text)

            logger.info(f"✅ Generated {len(suggestions)} habit suggestions")
            return suggestions

        except Exception as e:
            logger.error(f"❌ Error generating habit suggestions: {e}")
            # Return fallback suggestions
            return self._get_fallback_suggestions(goals, current_habits)

    def _get_system_prompt(self) -> str:
        """Get the system prompt for habit suggestion generation."""
        return """You are a fitness and wellness habit expert. Your role is to suggest personalized daily habits that help users achieve their health and fitness goals.

Key principles:
1. Suggest habits that are SPECIFIC and ACTIONABLE
2. Consider the user's fitness level and schedule
3. Focus on habits that complement workouts and nutrition
4. Include both positive habits (things to do) and negative habits (things to avoid)
5. Suggest habits across different categories: nutrition, activity, health, lifestyle

Always respond with valid JSON only. No markdown, no explanations, just the JSON array."""

    def _build_suggestion_prompt(
        self,
        user_context: Dict[str, Any],
        current_habits: List[str],
        goals: Optional[List[str]],
        max_suggestions: int,
    ) -> str:
        """Build the prompt for habit suggestions."""

        fitness_level = user_context.get("fitness_level", "intermediate")
        workout_frequency = user_context.get("workout_frequency", 3)
        user_goals = goals or user_context.get("goals", ["general fitness"])

        current_habits_str = ", ".join(current_habits) if current_habits else "None"
        goals_str = ", ".join(user_goals) if isinstance(user_goals, list) else str(user_goals)

        prompt = f"""Generate {max_suggestions} personalized habit suggestions for a user with the following profile:

FITNESS LEVEL: {fitness_level}
WORKOUT FREQUENCY: {workout_frequency} days per week
GOALS: {goals_str}
CURRENT HABITS (avoid duplicates): {current_habits_str}

Return a JSON array of habit suggestions. Each habit should have:
- name: Short, clear habit name (e.g., "Drink 8 glasses of water")
- description: Brief explanation of why this habit helps
- category: One of "nutrition", "activity", "health", "lifestyle"
- habit_type: "positive" (do this) or "negative" (avoid this)
- suggested_target: Optional numeric target (e.g., 8 for 8 glasses)
- unit: Optional unit for the target (e.g., "glasses", "minutes", "steps")
- icon: Material icon name (e.g., "water_drop", "directions_walk", "bedtime")
- color: Hex color code (e.g., "#4CAF50")
- difficulty: "easy", "medium", or "hard"
- impact: Brief statement on how this helps achieve their goals

Example response format:
[
  {{
    "name": "Walk 10,000 steps",
    "description": "Daily step goal for active recovery and NEAT calories",
    "category": "activity",
    "habit_type": "positive",
    "suggested_target": 10000,
    "unit": "steps",
    "icon": "directions_walk",
    "color": "#4CAF50",
    "difficulty": "medium",
    "impact": "Increases daily calorie burn and improves cardiovascular health"
  }}
]

Return ONLY the JSON array. No markdown, no explanation."""

        return prompt

    def _parse_suggestions(self, response_text: str) -> List[Dict[str, Any]]:
        """Parse the AI response into structured suggestions."""
        try:
            # Clean up the response - remove markdown code blocks if present
            cleaned = response_text.strip()

            # Remove markdown code blocks
            if cleaned.startswith("```"):
                # Find the end of the opening code block line
                first_newline = cleaned.find("\n")
                if first_newline != -1:
                    cleaned = cleaned[first_newline + 1:]
                # Remove closing code block
                if cleaned.endswith("```"):
                    cleaned = cleaned[:-3].strip()

            # Try to find JSON array in the response
            json_match = re.search(r'\[[\s\S]*\]', cleaned)
            if json_match:
                cleaned = json_match.group(0)

            suggestions = json.loads(cleaned)

            if not isinstance(suggestions, list):
                logger.warning("Response is not a list, wrapping in list")
                suggestions = [suggestions]

            # Validate and clean each suggestion
            valid_suggestions = []
            for suggestion in suggestions:
                if self._validate_suggestion(suggestion):
                    # Convert to HabitTemplate-compatible format
                    template = {
                        "name": suggestion.get("name", "Unnamed Habit"),
                        "description": suggestion.get("description", ""),
                        "category": suggestion.get("category", "lifestyle"),
                        "habit_type": suggestion.get("habit_type", "positive"),
                        "suggested_target": suggestion.get("suggested_target"),
                        "unit": suggestion.get("unit"),
                        "icon": suggestion.get("icon", "check_circle"),
                        "color": suggestion.get("color", "#4CAF50"),
                        "difficulty": suggestion.get("difficulty", "medium"),
                        "impact": suggestion.get("impact", ""),
                    }
                    valid_suggestions.append(template)

            return valid_suggestions

        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse AI response as JSON: {e}")
            logger.error(f"Response was: {response_text[:500]}")
            return []
        except Exception as e:
            logger.error(f"Error parsing suggestions: {e}")
            return []

    def _validate_suggestion(self, suggestion: Dict[str, Any]) -> bool:
        """Validate that a suggestion has required fields."""
        required_fields = ["name", "category", "habit_type"]
        return all(field in suggestion and suggestion[field] for field in required_fields)

    def _get_fallback_suggestions(
        self,
        goals: Optional[List[str]],
        current_habits: List[str],
    ) -> List[Dict[str, Any]]:
        """Return fallback suggestions when AI fails."""
        logger.info("🔄 Using fallback habit suggestions")

        all_fallbacks = [
            {
                "name": "Drink 8 glasses of water",
                "description": "Stay hydrated throughout the day for optimal performance",
                "category": "health",
                "habit_type": "positive",
                "suggested_target": 8,
                "unit": "glasses",
                "icon": "water_drop",
                "color": "#2196F3",
                "difficulty": "easy",
                "impact": "Improves energy, focus, and workout performance",
            },
            {
                "name": "Walk 10,000 steps",
                "description": "Daily step goal for active recovery",
                "category": "activity",
                "habit_type": "positive",
                "suggested_target": 10000,
                "unit": "steps",
                "icon": "directions_walk",
                "color": "#4CAF50",
                "difficulty": "medium",
                "impact": "Burns extra calories and improves cardiovascular health",
            },
            {
                "name": "Get 7-8 hours of sleep",
                "description": "Prioritize quality sleep for recovery",
                "category": "health",
                "habit_type": "positive",
                "suggested_target": 8,
                "unit": "hours",
                "icon": "bedtime",
                "color": "#9C27B0",
                "difficulty": "medium",
                "impact": "Essential for muscle recovery and mental clarity",
            },
            {
                "name": "Eat protein with every meal",
                "description": "Include a protein source in each meal",
                "category": "nutrition",
                "habit_type": "positive",
                "suggested_target": 3,
                "unit": "meals",
                "icon": "restaurant",
                "color": "#FF5722",
                "difficulty": "medium",
                "impact": "Supports muscle growth and keeps you feeling full",
            },
            {
                "name": "No sugary drinks",
                "description": "Avoid sodas, juices, and sweetened beverages",
                "category": "nutrition",
                "habit_type": "negative",
                "suggested_target": None,
                "unit": None,
                "icon": "no_drinks",
                "color": "#F44336",
                "difficulty": "medium",
                "impact": "Reduces empty calories and blood sugar spikes",
            },
            {
                "name": "Meditate for 10 minutes",
                "description": "Daily mindfulness practice for stress management",
                "category": "lifestyle",
                "habit_type": "positive",
                "suggested_target": 10,
                "unit": "minutes",
                "icon": "self_improvement",
                "color": "#00BCD4",
                "difficulty": "easy",
                "impact": "Reduces stress and improves focus",
            },
            {
                "name": "No eating after 8pm",
                "description": "Avoid late-night snacking",
                "category": "nutrition",
                "habit_type": "negative",
                "suggested_target": None,
                "unit": None,
                "icon": "do_not_disturb",
                "color": "#FF9800",
                "difficulty": "medium",
                "impact": "Improves digestion and sleep quality",
            },
            {
                "name": "Stretch for 5 minutes",
                "description": "Daily stretching routine",
                "category": "activity",
                "habit_type": "positive",
                "suggested_target": 5,
                "unit": "minutes",
                "icon": "fitness_center",
                "color": "#E91E63",
                "difficulty": "easy",
                "impact": "Improves flexibility and reduces injury risk",
            },
        ]

        # Filter out habits that already exist
        current_lower = [h.lower() for h in current_habits]
        filtered = [
            h for h in all_fallbacks
            if h["name"].lower() not in current_lower
        ]

        return filtered[:5]

    async def get_habit_insights(
        self,
        habits_data: List[Dict[str, Any]],
        completion_stats: Dict[str, Any],
    ) -> Dict[str, Any]:
        """
        Generate AI insights about habit performance.

        Args:
            habits_data: List of habit data with completion rates
            completion_stats: Overall completion statistics

        Returns:
            Dictionary with insights and recommendations
        """
        logger.info("🤖 Generating habit insights")

        try:
            # Build insight prompt
            prompt = self._build_insights_prompt(habits_data, completion_stats)

            response = await client.aio.models.generate_content(
                model=self.model,
                contents=[types.Content(role="user", parts=[types.Part.from_text(text=prompt)])],
                config=types.GenerateContentConfig(
                    system_instruction="You are a habit coach providing encouraging and actionable insights. Respond with valid JSON only.",
                    max_output_tokens=1024,
                    temperature=0.5,
                ),
            )

            return self._parse_insights(response.text)

        except Exception as e:
            logger.error(f"❌ Error generating insights: {e}")
            return {
                "summary": "Keep building your habits consistently!",
                "top_insight": "Consistency is key - focus on completing your habits daily.",
                "recommendations": ["Try to complete at least one more habit each day"],
            }

    def _build_insights_prompt(
        self,
        habits_data: List[Dict[str, Any]],
        completion_stats: Dict[str, Any],
    ) -> str:
        """Build prompt for habit insights."""
        habits_summary = []
        for habit in habits_data:
            habits_summary.append(
                f"- {habit.get('name', 'Unknown')}: "
                f"{habit.get('completion_rate', 0)}% completion, "
                f"streak: {habit.get('current_streak', 0)} days"
            )

        habits_str = "\n".join(habits_summary) if habits_summary else "No habits tracked yet"

        return f"""Analyze this user's habit performance and provide insights:

HABITS:
{habits_str}

OVERALL STATS:
- Total habits: {completion_stats.get('total_habits', 0)}
- Average completion rate: {completion_stats.get('average_completion', 0)}%
- Longest streak: {completion_stats.get('longest_streak', 0)} days

Return a JSON object with:
- summary: One sentence summary of their performance
- top_insight: The most important observation
- recommendations: Array of 2-3 specific, actionable recommendations
- celebration: Something positive to celebrate (if applicable)

Return ONLY the JSON object."""

    def _parse_insights(self, response_text: str) -> Dict[str, Any]:
        """Parse AI insights response."""
        try:
            # Clean up response
            cleaned = response_text.strip()
            if cleaned.startswith("```"):
                first_newline = cleaned.find("\n")
                if first_newline != -1:
                    cleaned = cleaned[first_newline + 1:]
                if cleaned.endswith("```"):
                    cleaned = cleaned[:-3].strip()

            # Find JSON object
            json_match = re.search(r'\{[\s\S]*\}', cleaned)
            if json_match:
                cleaned = json_match.group(0)

            return json.loads(cleaned)

        except (json.JSONDecodeError, Exception) as e:
            logger.error(f"Failed to parse insights: {e}")
            return {
                "summary": "Keep up the good work with your habits!",
                "top_insight": "Every day you complete your habits is a step toward your goals.",
                "recommendations": ["Stay consistent", "Focus on one habit at a time"],
            }
