"""
Node implementations for the Workout Insights LangGraph agent.
Generates structured, easy-to-read insights with formatting.

Uses google.genai SDK with structured output for guaranteed valid JSON,
with fallback to the centralized AI response parser.
"""
import json
from typing import Any, Dict, List

from google.genai import types
from services.gemini.constants import gemini_generate_with_retry

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
    user_goals = state.get("user_goals") or []
    fitness_level = state.get("fitness_level") or "intermediate"
    difficulty = state.get("difficulty") or "intermediate"
    total_sets = state.get("total_sets", 0)
    exercise_count = state.get("exercise_count", len(exercises))
    history_context = state.get("history_context") or []
    injury_context = state.get("injury_context") or {}

    # Build exercise detail string with sets/reps/equipment context
    exercise_details = []
    for e in exercises[:8]:
        name = e.get("name", "")
        sets = e.get("sets", "")
        reps = e.get("reps", "")
        equipment = e.get("equipment", "")
        muscle = e.get("primary_muscle") or e.get("muscle_group") or e.get("target") or ""
        if name:
            detail = name
            if sets and reps:
                detail += f" ({sets}x{reps})"
            if equipment:
                detail += f" [{equipment}]"
            if muscle:
                detail += f" -> {muscle}"
            exercise_details.append(detail)
    exercises_str = "\n".join(f"  - {d}" for d in exercise_details) if exercise_details else "various exercises"

    goals_str = ", ".join(user_goals) if user_goals else "general fitness"

    # --- Personalization blocks (only included when data exists, so a new
    # user's prompt stays lean and the model never invents history). ---
    history_lines = []
    for h in history_context[:8]:
        nm = h.get("name")
        if not nm:
            continue
        bits = []
        if h.get("last_top_set"):
            when = f" on {h['last_date']}" if h.get("last_date") else ""
            bits.append(f"last best set {h['last_top_set']}{when}")
        if h.get("best_1rm"):
            bits.append(f"all-time est 1RM {h['best_1rm']}")
        elif h.get("est_1rm"):
            bits.append(f"recent est 1RM {h['est_1rm']}")
        if bits:
            history_lines.append(f"  - {nm}: {', '.join(bits)}")
    history_block = ""
    if history_lines:
        history_block = (
            "\nThe user's logged history / strength baselines for exercises in this workout "
            "(use these to set concrete progressive-overload / PR-beating targets):\n"
            + "\n".join(history_lines)
            + "\n"
        )

    injuries = injury_context.get("injuries") or []
    pain_flagged = injury_context.get("pain_flagged_exercises") or []
    injury_block = ""
    if injuries or pain_flagged:
        inj_bits = []
        for i in injuries:
            bp = i.get("body_part") or "area"
            sev = i.get("severity")
            aff = i.get("affects_exercises") or []
            line = bp + (f" ({sev})" if sev else "")
            if aff:
                line += f" — affects: {', '.join([str(a) for a in aff[:4]])}"
            inj_bits.append(line)
        injury_block = (
            "\nACTIVE INJURIES / PAIN — be protective, never tell the user to push through pain:\n"
        )
        if inj_bits:
            injury_block += "\n".join(f"  - {b}" for b in inj_bits) + "\n"
        if pain_flagged:
            injury_block += (
                f"  - Pain-flagged exercises to handle gently: {', '.join([str(p) for p in pain_flagged[:6]])}\n"
            )

    has_history = bool(history_lines)
    has_injury = bool(injuries or pain_flagged)

    prompt = f"""You are an expert strength coach giving a PERSONALIZED pre-workout briefing. Be specific to THIS workout AND this user — reference exact exercise names, their own recent numbers, rep ranges, and muscles. Never be generic.

Workout: {workout_name}
Focus: {workout_focus} | Duration: {duration} min | Difficulty: {difficulty} | Level: {fitness_level}
User goals: {goals_str}
Exercises ({exercise_count} total, {total_sets} sets):
{exercises_str}
{history_block}{injury_block}
Generate 3 to 5 insight sections as JSON. Each MUST name a specific exercise from the list above.

PRIORITIZE personalized, data-driven sections in this order when the data exists:
1. PR / PROGRESSIVE-OVERLOAD OPPORTUNITY ({"INCLUDE THIS — history is available" if has_history else "skip — no history yet"}): use the user's last best set or est 1RM to give a concrete number to beat today — e.g. "You hit 175lb x 5 on Bench Press last time — aim for 180lb x 5 or 175lb x 6 today to push your estimated 1RM." Use the SAME unit shown in the history above.
2. INJURY-AWARE CUE ({"INCLUDE THIS — active injury/pain listed" if has_injury else "skip — none reported"}): give a protective adjustment for the affected exercise(s) — e.g. "Your right shoulder is recovering — keep Overhead Press in a pain-free range and stop the set if it pinches."
Then fill the rest from:
3. A form cue for the hardest exercise (name it, e.g. "On Barbell Squat, push knees out over toes and brace before each rep").
4. Why this exercise selection serves their {goals_str} goal.
5. A mind-muscle / tempo / rest tip tied to a specific exercise.

Rules:
- When history is provided, the FIRST section MUST be the PR/progressive-overload opportunity with a concrete target weight or rep.
- When injuries/pain are provided, you MUST include the injury-aware section.
- headline: 3-5 words, motivational but specific to the workout theme.
- section title: 2-4 words.
- section content: 2 sentences max. MUST reference a specific exercise name. Be concrete, cite real numbers when given.
- icon: one emoji. color: one of cyan, purple, orange, green.
- 3 to 5 sections total.

BAD example (too generic): "These compound movements maximize calorie burn"
GOOD example: "You pressed 175lb x 5 on Bench last session — open with 180lb x 5 today and you'll set a new estimated 1RM while you're fresh." """

    # Deterministic fallback based on workout data (no AI needed)
    def _build_fallback(headline_text: str = None):
        fb_headline = headline_text or "Time to get to work"
        first_exercise = exercises[0].get("name", workout_focus) if exercises else workout_focus
        fb_sections = [
            {"icon": "🎯", "title": "Today's Target", "content": f"This session hits your {workout_focus} — {exercise_count} exercises, {total_sets} total sets. Stay controlled on each rep.", "color": "cyan"},
            {"icon": "💪", "title": "Key Lift", "content": f"Lead with {first_exercise} while your energy is highest. Focus on form before weight.", "color": "orange"},
            {"icon": "🔋", "title": "Recovery", "content": f"After {duration} min of {workout_focus} work, prioritise protein and sleep tonight to maximise adaptation.", "color": "purple"},
        ]
        return {
            "headline": fb_headline,
            "sections": fb_sections,
            "summary": json.dumps({"headline": fb_headline, "sections": fb_sections}),
        }

    try:
        response = await gemini_generate_with_retry(
            model=settings.gemini_model,
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=WorkoutInsightsResponse,
                temperature=0.7,
                max_output_tokens=8192,  # High to account for thinking model token budget
            ),
            method_name="workout_insights",
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
                except (json.JSONDecodeError, ValueError) as e:
                    logger.debug(f"Direct JSON parse failed: {e}")

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

        # Validate we got the expected structure
        if insights is None:
            logger.warning("[Generate Node] Failed to produce insights, using fallback")
            return _build_fallback()

        headline = insights.get("headline", "Let's crush this workout!")
        sections = insights.get("sections", [])

        # Validate section count
        if len(sections) < 3:
            logger.warning(f"[Generate Node] Insufficient sections: {len(sections)}, using fallback")
            return _build_fallback(headline)

        # Truncate headline if too long (max 5 words)
        if len(headline.split()) > 5:
            headline = " ".join(headline.split()[:5])

        # Truncate section content if too long (max 36 words — a PR-target
        # sentence citing weights/reps runs a little longer than a generic cue)
        for section in sections:
            content = section.get("content", "")
            words = content.split()
            if len(words) > 36:
                section["content"] = " ".join(words[:36])

        logger.info(f"[Generate Node] Generated {len(sections)} sections")

        # Return both structured data and JSON string for API
        return {
            "headline": headline,
            "sections": sections,
            "summary": json.dumps({"headline": headline, "sections": sections}),
        }

    except Exception as e:
        logger.error(f"[Generate Node] Failed: {e}, using fallback", exc_info=True)
        return _build_fallback()
