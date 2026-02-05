"""
Node implementations for the Workout Insights LangGraph agent.
Generates structured, easy-to-read insights with formatting.

Uses google.genai SDK with structured output for guaranteed valid JSON,
with fallback to the centralized AI response parser.
"""
import json
from typing import Any, Dict, List

from google import genai
from google.genai import types

from .state import WorkoutInsightsState
from core.config import get_settings
from core.logger import get_logger
from core.ai_response_parser import parse_ai_json
from models.gemini_schemas import WorkoutInsightsResponse

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
    Generate structured, easy-to-read insights using AI with guaranteed JSON output.

    Uses google.genai SDK with response_schema for structured output.
    Falls back to the centralized AI response parser if structured output fails.
    """
    logger.info("[Generate Node] Generating structured insights...")

    workout_name = state.get("workout_name", "Workout")
    exercises = state.get("exercises", [])
    duration = state.get("duration_minutes", 45)
    workout_focus = state.get("workout_focus", "full body")

    # Get up to 5 exercise names for context
    exercise_list = [e.get("name", "") for e in exercises[:5] if e.get("name")]
    exercises_str = ", ".join(exercise_list) if exercise_list else "various exercises"

    # Build the prompt (simpler since schema enforces structure)
    prompt = f"""You are a fitness coach. Generate SHORT workout insights.

RULES:
1. Headline: 3-5 words max, motivational
2. Each section content: 6-10 words max. Be direct.
3. Generate exactly 2 sections.
4. Icons to use: 💪 🎯 🔥 ⚡
5. Colors: cyan, purple, orange, green

Workout: {workout_name}
Focus: {workout_focus}
Exercises: {exercises_str}
Duration: {duration} min

Generate 2 short, motivational insights for this workout."""

    # Initialize google.genai client
    client = genai.Client(api_key=settings.gemini_api_key)

    max_retries = 2
    last_error = None

    for attempt in range(max_retries + 1):
        try:
            if attempt > 0:
                logger.info(f"[Generate Node] Retry attempt {attempt}/{max_retries}")

            response = await client.aio.models.generate_content(
                model=settings.gemini_model,
                contents=prompt,
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    response_schema=WorkoutInsightsResponse,
                    temperature=0.7,
                    max_output_tokens=512,
                ),
            )

            # Primary: Use structured output (response.parsed)
            # The SDK automatically parses JSON when response_schema is provided
            insights = None

            if response.parsed:
                # Structured output succeeded - convert Pydantic model to dict
                insights = response.parsed.model_dump()
                logger.debug("[Generate Node] Structured output parsing succeeded")
            else:
                # Fallback: Use centralized AI response parser on raw text
                logger.warning("[Generate Node] Structured output empty, using fallback parser")
                raw_text = response.text if response.text else ""

                parse_result = parse_ai_json(
                    raw_text,
                    expected_fields=["headline", "sections"],
                    context="workout_insights"
                )

                if parse_result.success:
                    insights = parse_result.data
                    if parse_result.was_repaired:
                        logger.info(f"[Generate Node] JSON repaired using {parse_result.strategy_used.value}: {parse_result.repair_steps}")
                else:
                    logger.warning(f"[Generate Node] Fallback parser failed: {parse_result.error}")
                    last_error = ValueError(f"Failed to parse AI response: {parse_result.error}")
                    if attempt < max_retries:
                        continue  # Retry
                    raise last_error

            # Validate we got the expected structure
            if insights is None:
                last_error = ValueError("No insights generated")
                if attempt < max_retries:
                    continue
                raise last_error

            headline = insights.get("headline", "Let's crush this workout!")
            sections = insights.get("sections", [])

            # Validate section count
            if len(sections) < 2:
                last_error = ValueError(f"Expected 2 sections, got {len(sections)}")
                logger.warning(f"[Generate Node] Insufficient sections: {len(sections)}")
                if attempt < max_retries:
                    continue  # Retry
                raise last_error

            # Truncate headline if too long (max 5 words)
            if len(headline.split()) > 5:
                headline = " ".join(headline.split()[:5])

            # Truncate section content if too long (max 10 words)
            for section in sections:
                content = section.get("content", "")
                words = content.split()
                if len(words) > 10:
                    section["content"] = " ".join(words[:10])

            logger.info(f"[Generate Node] Generated {len(sections)} sections (attempt {attempt})")

            # Return both structured data and JSON string for API
            return {
                "headline": headline,
                "sections": sections,
                "summary": json.dumps({"headline": headline, "sections": sections}),
            }

        except Exception as e:
            last_error = e
            if attempt < max_retries:
                logger.warning(f"[Generate Node] Attempt {attempt} failed: {e}, retrying...")
                continue
            logger.error(f"[Generate Node] Error generating insights after {max_retries + 1} attempts: {e}")
            raise  # Fail fast - propagate error rather than show incorrect content

    # Should not reach here, but just in case
    if last_error:
        raise last_error
    raise ValueError("Unknown error in insight generation")
