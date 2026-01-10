"""
Node implementations for the Workout Insights LangGraph agent.
Generates structured, easy-to-read insights with formatting.
"""
import json
import re
from typing import Dict, Any, List, Optional

from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.messages import HumanMessage, SystemMessage

from .state import WorkoutInsightsState
from core.config import get_settings
from core.logger import get_logger

logger = get_logger(__name__)
settings = get_settings()


def repair_json_string(content: str) -> Optional[str]:
    """
    Attempt to repair common JSON issues from AI responses.
    Returns repaired JSON string or None if repair fails.
    """
    if not content:
        return None

    original = content

    try:
        # First try parsing as-is
        json.loads(content)
        return content
    except json.JSONDecodeError:
        pass

    # Try simple repairs first
    repaired = content

    # Fix unescaped control characters in strings (newlines, tabs, etc)
    # This is a common issue with AI-generated JSON
    repaired = re.sub(r'(?<!\\)\n', r'\\n', repaired)
    repaired = re.sub(r'(?<!\\)\t', r'\\t', repaired)
    repaired = re.sub(r'(?<!\\)\r', r'\\r', repaired)

    # Remove trailing commas before closing brackets/braces
    repaired = re.sub(r',(\s*[}\]])', r'\1', repaired)

    try:
        json.loads(repaired)
        logger.info("[JSON Repair] Fixed control characters and/or trailing commas")
        return repaired
    except json.JSONDecodeError:
        pass

    # Try to find and extract just the JSON object from surrounding text
    json_match = re.search(r'\{[\s\S]*\}', original)
    if json_match:
        extracted = json_match.group(0)
        # Apply same fixes to extracted
        extracted = re.sub(r'(?<!\\)\n', r'\\n', extracted)
        extracted = re.sub(r'(?<!\\)\t', r'\\t', extracted)
        extracted = re.sub(r',(\s*[}\]])', r'\1', extracted)
        try:
            json.loads(extracted)
            logger.info("[JSON Repair] Extracted and fixed JSON from text")
            return extracted
        except json.JSONDecodeError:
            pass

    # Last resort: try to complete truncated JSON
    repaired = original
    # Re-apply control char fixes
    repaired = re.sub(r'(?<!\\)\n', r'\\n', repaired)
    repaired = re.sub(r'(?<!\\)\t', r'\\t', repaired)
    repaired = re.sub(r',(\s*[}\]])', r'\1', repaired)

    # Count braces and brackets
    open_braces = repaired.count('{') - repaired.count('}')
    open_brackets = repaired.count('[') - repaired.count(']')

    # Check for unterminated string
    in_string = False
    i = 0
    while i < len(repaired):
        char = repaired[i]
        if char == '\\' and i + 1 < len(repaired):
            i += 2  # Skip escaped character
            continue
        if char == '"':
            in_string = not in_string
        i += 1

    if in_string:
        # Try to find a reasonable place to end the string
        # Remove any incomplete content and close the string
        repaired = repaired.rstrip()
        if repaired.endswith(','):
            repaired = repaired[:-1]
        repaired += '"'

    # Close any open brackets/braces
    repaired += ']' * max(0, open_brackets)
    repaired += '}' * max(0, open_braces)

    try:
        json.loads(repaired)
        logger.info("[JSON Repair] Completed truncated JSON")
        return repaired
    except json.JSONDecodeError:
        pass

    # More aggressive repair: try to find the last complete section
    # This handles cases where truncation happened mid-object
    try:
        # Find the last complete array element in sections
        sections_match = re.search(r'"sections"\s*:\s*\[(.*)', original, re.DOTALL)
        if sections_match:
            sections_content = sections_match.group(1)
            # Find all complete section objects
            complete_sections = []
            depth = 0
            current_obj = ""
            in_str = False
            prev_char = ''
            for char in sections_content:
                current_obj += char
                # Track string state to avoid counting braces inside strings
                if char == '"' and prev_char != '\\':
                    in_str = not in_str
                if not in_str:
                    if char == '{':
                        depth += 1
                    elif char == '}':
                        depth -= 1
                        if depth == 0:
                            try:
                                obj_str = current_obj.strip().rstrip(',')
                                obj = json.loads(obj_str)
                                complete_sections.append(obj)
                                current_obj = ""
                            except json.JSONDecodeError:
                                current_obj = ""
                                depth = 0
                prev_char = char

            if complete_sections:
                # Extract headline from original
                headline_match = re.search(r'"headline"\s*:\s*"([^"]*)"', original)
                headline = headline_match.group(1) if headline_match else "Let's crush this workout!"

                repaired_obj = {
                    "headline": headline,
                    "sections": complete_sections
                }
                logger.info(f"[JSON Repair] Recovered {len(complete_sections)} complete sections from truncated response")
                return json.dumps(repaired_obj)
    except Exception as repair_error:
        logger.debug(f"[JSON Repair] Aggressive repair failed: {repair_error}")

    logger.warning(f"[JSON Repair] Could not repair JSON after all attempts")
    return None




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

    llm = ChatGoogleGenerativeAI(
        model=settings.gemini_model,
        temperature=0.85,  # Higher for more variety
        max_tokens=1200,  # Increased to prevent truncation of JSON response
        google_api_key=settings.gemini_api_key,
    )

    # Get up to 5 exercise names for context
    exercise_list = [e.get("name", "") for e in exercises[:5] if e.get("name")]
    exercises_str = ", ".join(exercise_list) if exercise_list else "various exercises"

    system_prompt = """You are a knowledgeable fitness coach giving personalized workout insights. Generate JSON.

RULES:
1. Headline: 4-6 words, reference the SPECIFIC workout or key exercise
2. Each content: 10-15 words. Be SPECIFIC about exercises/muscles mentioned
3. Avoid generic phrases like "boost your fitness" or "stay consistent"
4. Reference ACTUAL exercises from this workout when possible
5. Give practical, specific advice that applies to THIS workout

Return ONLY valid JSON with 3 sections. Choose section types from this variety:
- 🎯 Focus: What this workout specifically builds
- 💪 Key Move: Highlight the most impactful exercise
- 🔥 Why It Works: Science/benefit behind the workout
- ⚡ Form Tip: Specific technique for an exercise in this workout
- 🧠 Mind-Muscle: Connection cue for better engagement
- ⏱️ Pacing: How to approach rest/intensity
- 🏆 Challenge: Optional way to push harder

{
  "headline": "4-6 word headline about THIS workout",
  "sections": [
    {
      "icon": "emoji",
      "title": "Short Title",
      "content": "10-15 words - specific to this workout",
      "color": "cyan|purple|orange"
    }
  ]
}

GOOD EXAMPLES (specific):
- "Bench Press builds chest thickness and anterior shoulder strength"
- "On Rows: squeeze shoulder blades together at peak contraction"
- "Squats paired with lunges create complete quad development"

BAD EXAMPLES (too generic):
- "Great workout for building strength"
- "Stay consistent and give your best effort"
- "Push through and you'll see results" """

    user_prompt = f"""Create 3 personalized insights for this specific workout:

Workout Name: {workout_name}
Focus Type: {workout_focus}
Target Muscles: {', '.join(target_muscles[:4]) if target_muscles else 'full body'}
Exercises Include: {exercises_str}
Duration: {duration} minutes
Total Sets: {total_sets}
User Level: {fitness_level}
User Goals: {', '.join(user_goals[:2]) if user_goals else 'general fitness'}

Make each insight SPECIFIC to these exercises and muscles. Avoid generic motivational phrases."""

    max_retries = 2
    last_error = None

    for attempt in range(max_retries + 1):
        try:
            if attempt > 0:
                logger.info(f"[Generate Node] Retry attempt {attempt}/{max_retries}")

            response = await llm.ainvoke([
                SystemMessage(content=system_prompt),
                HumanMessage(content=user_prompt),
            ])

            content = response.content.strip()
            logger.debug(f"[Generate Node] Raw AI response (attempt {attempt}): {content[:500]}...")

            # Extract JSON from response (handle markdown code blocks)
            if "```json" in content:
                content = content.split("```json")[1].split("```")[0].strip()
            elif "```" in content:
                parts = content.split("```")
                if len(parts) >= 2:
                    content = parts[1].strip()
                    # Remove language identifier if present (e.g., "json\n{...")
                    if content.startswith(("json", "JSON")):
                        content = content[4:].strip()

            # Try to parse JSON, with repair if needed
            insights = None
            was_repaired = False
            try:
                insights = json.loads(content)
            except json.JSONDecodeError as parse_error:
                logger.warning(f"[Generate Node] Initial JSON parse failed: {parse_error}")

                # Attempt to repair the JSON
                repaired = repair_json_string(content)
                if repaired:
                    try:
                        insights = json.loads(repaired)
                        was_repaired = True
                        logger.info("[Generate Node] Successfully parsed repaired JSON")
                    except json.JSONDecodeError:
                        logger.warning("[Generate Node] Repaired JSON still invalid")

            # If parsing failed, retry or raise error
            if insights is None:
                last_error = ValueError("Failed to parse AI response as valid JSON after repair attempts")
                if attempt < max_retries:
                    continue  # Retry
                raise last_error

            # Validate structure
            headline = insights.get("headline", "Let's crush this workout!")
            sections = insights.get("sections", [])

            # If sections are empty/insufficient, this likely means truncation - retry
            if not sections or len(sections) < 2:
                last_error = ValueError(f"AI returned invalid structure: expected 2+ sections, got {len(sections)}")
                if was_repaired:
                    logger.warning(f"[Generate Node] Repaired JSON had {len(sections)} sections (likely truncated response)")
                if attempt < max_retries:
                    logger.info("[Generate Node] Retrying due to insufficient sections...")
                    continue  # Retry
                raise last_error

            # Truncate headline if too long (max 7 words)
            if len(headline.split()) > 7:
                headline = " ".join(headline.split()[:7])
                if not headline.endswith(("!", "?")):
                    headline += "!"

            # Truncate section content if too long (max 20 words)
            for section in sections:
                words = section.get("content", "").split()
                if len(words) > 20:
                    section["content"] = " ".join(words[:20]) + "..."

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
