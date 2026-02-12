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
    prompt = f"""Generate 2 short workout insights as JSON.

Workout: {workout_name} | Focus: {workout_focus} | {duration} min | Exercises: {exercises_str}

Rules: headline 3-5 words, each section content 6-10 words, exactly 2 sections. Icons: 💪🎯🔥⚡ Colors: cyan, purple, orange, green."""

    # Initialize google.genai client
    from core.gemini_client import get_genai_client
    client = get_genai_client()

    # Deterministic fallback based on workout data (no AI needed)
    def _build_fallback(headline_text: str = None):
        fb_headline = headline_text or "Let's crush this workout!"
        fb_sections = [
            {"icon": "🎯", "title": "Focus", "content": f"Target {workout_focus} with intensity", "color": "cyan"},
            {"icon": "💪", "title": "Duration", "content": f"{duration} min of focused training", "color": "purple"},
        ]
        return {
            "headline": fb_headline,
            "sections": fb_sections,
            "summary": json.dumps({"headline": fb_headline, "sections": fb_sections}),
        }

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
                    max_output_tokens=2048,
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
                # Log diagnostic info to understand why structured output failed
                finish_reason = None
                if hasattr(response, 'candidates') and response.candidates:
                    finish_reason = response.candidates[0].finish_reason
                raw_text = response.text if response.text else ""
                logger.warning(
                    f"[Generate Node] Structured output empty. "
                    f"finish_reason={finish_reason}, "
                    f"raw_text_len={len(raw_text)}, "
                    f"raw_text_preview={raw_text[:200] if raw_text else 'None'}"
                )

                # Fallback 1: Try direct json.loads on raw text (SDK parse can fail even with valid JSON)
                if raw_text:
                    try:
                        insights = json.loads(raw_text)
                        if isinstance(insights, str):
                            insights = json.loads(insights)
                        if isinstance(insights, dict):
                            logger.info("[Generate Node] Direct json.loads succeeded on raw text")
                        else:
                            insights = None
                    except (json.JSONDecodeError, ValueError):
                        pass

                # Fallback 2: Use centralized AI response parser
                if insights is None and raw_text:
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

            # Validate we got the expected structure
            if insights is None:
                last_error = ValueError("No insights generated")
                if attempt < max_retries:
                    continue
                # All retries exhausted - use deterministic fallback
                logger.warning(f"[Generate Node] All {max_retries + 1} attempts failed to produce insights, using fallback")
                return _build_fallback()

            headline = insights.get("headline", "Let's crush this workout!")
            sections = insights.get("sections", [])

            # Validate section count
            if len(sections) < 2:
                logger.warning(f"[Generate Node] Insufficient sections: {len(sections)}")
                if attempt < max_retries:
                    continue  # Retry
                # All retries exhausted - use deterministic fallback sections
                logger.warning(f"[Generate Node] Using fallback sections after {max_retries + 1} attempts")
                return _build_fallback(headline)

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
            logger.error(f"[Generate Node] All {max_retries + 1} attempts failed: {e}, using fallback")
            return _build_fallback()
