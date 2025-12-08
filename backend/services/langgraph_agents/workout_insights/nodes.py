"""
Node implementations for the Workout Insights LangGraph agent.
Generates structured, easy-to-read insights with formatting.
"""
import json
from typing import Dict, Any, List

from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage, SystemMessage

from .state import WorkoutInsightsState
from core.config import get_settings
from core.logger import get_logger

logger = get_logger(__name__)
settings = get_settings()


def categorize_muscle_group(muscle: str) -> str:
    """Categorize muscle into body region for workout focus."""
    if not muscle:
        return "other"

    muscle_lower = muscle.lower()

    # Upper body pushing
    if any(x in muscle_lower for x in ["chest", "pectoralis", "shoulder", "deltoid", "tricep"]):
        return "upper_push"
    # Upper body pulling
    elif any(x in muscle_lower for x in ["back", "latissimus", "rhomboid", "trapezius", "bicep"]):
        return "upper_pull"
    # Lower body
    elif any(x in muscle_lower for x in ["quad", "hamstring", "glute", "calf", "leg", "thigh"]):
        return "lower"
    # Core
    elif any(x in muscle_lower for x in ["core", "abs", "abdominal", "oblique"]):
        return "core"
    else:
        return "other"


def determine_workout_focus(muscles: List[str]) -> str:
    """Determine the overall focus of the workout based on target muscles."""
    categories = [categorize_muscle_group(m) for m in muscles]

    upper_push = categories.count("upper_push")
    upper_pull = categories.count("upper_pull")
    lower = categories.count("lower")
    core = categories.count("core")

    total = len(categories)
    if total == 0:
        return "full body"

    # Determine focus based on distribution
    if lower >= total * 0.6:
        return "leg day"
    elif upper_push >= total * 0.6:
        return "push day"
    elif upper_pull >= total * 0.6:
        return "pull day"
    elif (upper_push + upper_pull) >= total * 0.6:
        return "upper body"
    elif lower >= total * 0.4 and (upper_push + upper_pull) >= total * 0.4:
        return "full body"
    elif core >= total * 0.5:
        return "core focus"
    else:
        return "full body"


async def analyze_workout_node(state: WorkoutInsightsState) -> Dict[str, Any]:
    """
    Analyze the workout to extract key metrics and determine focus.
    """
    logger.info(f"[Analyze Node] Analyzing workout: {state['workout_name']}")

    exercises = state.get("exercises", [])

    # Extract target muscles
    target_muscles = []
    total_sets = 0

    for exercise in exercises:
        # Get muscle from various possible fields
        muscle = (
            exercise.get("primary_muscle") or
            exercise.get("muscle_group") or
            exercise.get("target") or
            ""
        )
        if muscle and muscle not in target_muscles:
            target_muscles.append(muscle)

        # Count sets
        sets = exercise.get("sets", 3)
        total_sets += sets

    # Determine workout focus
    workout_focus = determine_workout_focus(target_muscles)

    logger.info(f"[Analyze Node] Focus: {workout_focus}, Muscles: {len(target_muscles)}, Sets: {total_sets}")

    return {
        "target_muscles": target_muscles,
        "exercise_count": len(exercises),
        "total_sets": total_sets,
        "workout_focus": workout_focus,
    }


async def generate_structured_insights_node(state: WorkoutInsightsState) -> Dict[str, Any]:
    """
    Generate structured, easy-to-read insights using AI.
    Returns JSON with headline and sections for beautiful UI rendering.
    """
    logger.info("[Generate Node] Generating structured insights...")

    workout_name = state.get("workout_name", "Workout")
    exercises = state.get("exercises", [])
    duration = state.get("duration_minutes", 45)
    workout_focus = state.get("workout_focus", "full body")
    target_muscles = state.get("target_muscles", [])
    total_sets = state.get("total_sets", 0)
    exercise_count = state.get("exercise_count", 0)
    user_goals = state.get("user_goals", [])
    fitness_level = state.get("fitness_level", "intermediate")

    # Get top 3 exercises for context
    exercise_names = [e.get("name", "") for e in exercises[:3]]

    llm = ChatOpenAI(
        model="gpt-4o-mini",
        temperature=0.7,
        max_tokens=300,
        api_key=settings.openai_api_key,
    )

    system_prompt = """You are a fitness coach who gives ULTRA SHORT insights. Generate JSON.

STRICT RULES:
1. Headline: Max 5 words! (e.g., "Build Strong Legs Today!")
2. Each content: Max 8 words ONLY! Very short phrases.
3. NO full sentences - use punchy phrases
4. Focus on ONE key benefit per section

Return ONLY valid JSON:
{
  "headline": "5 word max headline",
  "sections": [
    {
      "icon": "🎯",
      "title": "Goal",
      "content": "8 words max - key benefit",
      "color": "cyan"
    },
    {
      "icon": "💪",
      "title": "Target",
      "content": "8 words max - muscles hit",
      "color": "purple"
    },
    {
      "icon": "⚡",
      "title": "Pro Tip",
      "content": "8 words max - quick tip",
      "color": "orange"
    }
  ]
}

EXAMPLES of good content (8 words or less):
- "Builds core strength and stability"
- "Quads, glutes, hamstrings"
- "Keep your back straight"
- "Breathe out on the push"

DO NOT write long sentences!"""

    user_prompt = f"""Workout: {workout_name}
Type: {workout_focus}
Muscles: {', '.join(target_muscles[:3]) if target_muscles else 'full body'}

Give me 3 ULTRA SHORT insights. Max 8 words per content!"""

    try:
        response = await llm.ainvoke([
            SystemMessage(content=system_prompt),
            HumanMessage(content=user_prompt),
        ])

        content = response.content.strip()

        # Extract JSON from response (handle markdown code blocks)
        if "```json" in content:
            content = content.split("```json")[1].split("```")[0].strip()
        elif "```" in content:
            content = content.split("```")[1].split("```")[0].strip()

        # Parse JSON
        insights = json.loads(content)

        # Validate structure
        headline = insights.get("headline", "Let's crush this workout!")
        sections = insights.get("sections", [])

        # Ensure we have valid sections
        if not sections or len(sections) < 2:
            sections = _generate_fallback_sections(
                workout_focus, target_muscles, exercise_count, duration
            )

        # Truncate headline if too long (max 5 words)
        if len(headline.split()) > 5:
            headline = " ".join(headline.split()[:5]) + "!"

        # Truncate section content if too long (max 8 words)
        for section in sections:
            words = section.get("content", "").split()
            if len(words) > 8:
                section["content"] = " ".join(words[:8])

        logger.info(f"[Generate Node] Generated {len(sections)} sections")

        # Return both structured data and JSON string for API
        return {
            "headline": headline,
            "sections": sections,
            "summary": json.dumps({"headline": headline, "sections": sections}),
        }

    except Exception as e:
        logger.error(f"[Generate Node] Error: {e}")

        # Fallback to structured fallback
        sections = _generate_fallback_sections(
            workout_focus, target_muscles, exercise_count, duration
        )
        headline = f"Time to work your {workout_focus}!"

        return {
            "headline": headline,
            "sections": sections,
            "summary": json.dumps({"headline": headline, "sections": sections}),
        }


def _generate_fallback_sections(
    workout_focus: str,
    target_muscles: List[str],
    exercise_count: int,
    duration: int
) -> List[Dict[str, str]]:
    """Generate fallback sections if AI fails. Max 8 words per content."""
    muscles_text = ", ".join(target_muscles[:2]) if target_muscles else "full body"

    return [
        {
            "icon": "🎯",
            "title": "Focus",
            "content": f"{workout_focus.title()} strength training",
            "color": "cyan"
        },
        {
            "icon": "💪",
            "title": "Target",
            "content": muscles_text,
            "color": "purple"
        },
        {
            "icon": "⏱️",
            "title": "Duration",
            "content": f"{exercise_count} exercises, {duration} min",
            "color": "orange"
        }
    ]
