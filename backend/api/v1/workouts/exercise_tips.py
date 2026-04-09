"""
AI-Powered Exercise Coach Tips.

Generates personalized, per-exercise tips using Gemini AI that reflect
the user's selected coach persona (tone, style, encouragement level)
and incorporate previous performance data for the exercise.
"""

from fastapi import APIRouter, Depends, Request
from core.auth import get_current_user
from core.rate_limiter import limiter
from typing import List, Optional
from pydantic import BaseModel, Field

from core.logger import get_logger
from services.gemini_service import GeminiService

router = APIRouter()
logger = get_logger(__name__)

_gemini_service: Optional[GeminiService] = None


def get_gemini_service() -> GeminiService:
    global _gemini_service
    if _gemini_service is None:
        _gemini_service = GeminiService()
    return _gemini_service


class PreviousSetData(BaseModel):
    weight: Optional[float] = None
    reps: Optional[int] = None
    rpe: Optional[int] = None
    rir: Optional[int] = None


class ExerciseTipRequest(BaseModel):
    exercise_name: str
    body_part: Optional[str] = None
    equipment: Optional[str] = None
    sets: int = 3
    reps: Optional[int] = None
    target_weight: Optional[float] = None
    use_kg: bool = False
    user_goal: Optional[str] = None  # muscle_strength, muscle_hypertrophy, etc.
    progression_pattern: Optional[str] = None  # pyramidUp, straightSets, etc.
    previous_sets: Optional[List[PreviousSetData]] = None
    pr_weight: Optional[float] = None

    # Coach persona
    coach_name: str = "Coach"
    coaching_style: str = "motivational"  # motivational, scientist, drill-sergeant, zen-master, hype-beast
    communication_tone: str = "encouraging"  # encouraging, formal, tough-love, casual, gen-z
    encouragement_level: float = Field(default=0.7, ge=0.0, le=1.0)


class ExerciseTipResponse(BaseModel):
    tip: str
    exercise_name: str


# ── Tone templates for each coaching style ──

STYLE_SYSTEM_PROMPTS = {
    "motivational": (
        "You are {coach_name}, an upbeat motivational fitness coach. "
        "You pump people up and believe in them. Speak with energy and positivity. "
        "Use direct, action-oriented language."
    ),
    "scientist": (
        "You are {coach_name}, an evidence-based sports scientist. "
        "You reference training principles (progressive overload, time under tension, etc.) "
        "in a clear, professional way. Be precise but approachable."
    ),
    "drill-sergeant": (
        "You are {coach_name}, a no-nonsense drill-sergeant style coach. "
        "You push hard with tough love. Be blunt, direct, and demanding. "
        "No sugarcoating — tell them what they need to hear."
    ),
    "zen-master": (
        "You are {coach_name}, a calm, mindful fitness guide. "
        "You focus on breath, body awareness, and the mind-muscle connection. "
        "Speak gently but with purpose."
    ),
    "hype-beast": (
        "You are {coach_name}, a high-energy gen-z fitness hype coach. "
        "You use trendy slang, ALL CAPS for emphasis, and radiate pure excitement. "
        "Keep it fun and fire."
    ),
}

TONE_MODIFIERS = {
    "encouraging": "Be warm and supportive.",
    "formal": "Keep a professional, structured tone.",
    "tough-love": "Be direct and push them to do better.",
    "casual": "Keep it conversational and friendly, like a buddy.",
    "gen-z": "Use modern slang, abbreviations, and high energy. Think 'no cap', 'fr fr', 'let's goooo'.",
}


def _build_system_prompt(req: ExerciseTipRequest) -> str:
    style_template = STYLE_SYSTEM_PROMPTS.get(
        req.coaching_style,
        STYLE_SYSTEM_PROMPTS["motivational"],
    )
    system = style_template.format(coach_name=req.coach_name)

    tone_mod = TONE_MODIFIERS.get(req.communication_tone, "")
    if tone_mod:
        system += f" {tone_mod}"

    if req.encouragement_level < 0.3:
        system += " Keep encouragement minimal — focus on instruction."
    elif req.encouragement_level > 0.8:
        system += " Be extra encouraging and hype them up."

    return system


def _build_user_prompt(req: ExerciseTipRequest) -> str:
    unit = "kg" if req.use_kg else "lbs"
    parts = [
        f"Generate a SHORT coach tip (1-3 sentences max) for the exercise: {req.exercise_name}.",
    ]

    # Exercise context
    context_parts = []
    if req.body_part:
        context_parts.append(f"Target: {req.body_part}")
    if req.equipment:
        context_parts.append(f"Equipment: {req.equipment}")
    if req.sets:
        context_parts.append(f"Sets: {req.sets}")
    if req.reps:
        context_parts.append(f"Target reps: {req.reps}")
    if req.target_weight and req.target_weight > 0:
        context_parts.append(f"Weight: {req.target_weight:.0f}{unit}")
    if req.progression_pattern:
        context_parts.append(f"Set pattern: {req.progression_pattern}")
    if req.user_goal:
        goal_display = req.user_goal.replace("_", " ").title()
        context_parts.append(f"User's goal: {goal_display}")

    if context_parts:
        parts.append("Exercise context: " + ", ".join(context_parts))

    # Previous performance
    if req.previous_sets and len(req.previous_sets) > 0:
        prev_lines = []
        for i, s in enumerate(req.previous_sets, 1):
            set_parts = []
            if s.weight is not None:
                set_parts.append(f"{s.weight:.0f}{unit}")
            if s.reps is not None:
                set_parts.append(f"{s.reps} reps")
            if s.rpe is not None:
                set_parts.append(f"RPE {s.rpe}")
            if set_parts:
                prev_lines.append(f"  Set {i}: {', '.join(set_parts)}")
        if prev_lines:
            parts.append("Last session performance:\n" + "\n".join(prev_lines))

    if req.pr_weight and req.pr_weight > 0:
        parts.append(f"Personal record: {req.pr_weight:.0f}{unit}")

    parts.append(
        "\nGuidelines:"
        "\n- Keep it SHORT (1-3 sentences, under 150 characters ideal)"
        "\n- Make it specific to THIS exercise and the user's data"
        "\n- If previous data is available, reference their performance (progress, weight suggestions, form focus)"
        "\n- If near PR, mention it"
        "\n- Include one actionable cue (form tip, tempo, breathing, or intensity)"
        "\n- Do NOT use generic advice like 'stay hydrated' or 'warm up first'"
        "\n- Do NOT start with the exercise name"
        "\n- Do NOT use hashtags"
        "\n- Return ONLY the tip text, nothing else"
    )

    return "\n".join(parts)


@router.post("/exercise-tip", response_model=ExerciseTipResponse)
@limiter.limit("30/minute")
async def get_exercise_tip(
    body: ExerciseTipRequest,
    request: Request,
    user=Depends(get_current_user),
):
    """Generate a personalized AI coach tip for a specific exercise."""
    gemini = get_gemini_service()

    system_prompt = _build_system_prompt(body)
    user_prompt = _build_user_prompt(body)

    try:
        response = await gemini.chat(
            user_message=user_prompt,
            system_prompt=system_prompt,
        )

        tip = response.strip()

        # Clean up quotes
        if tip.startswith('"') and tip.endswith('"'):
            tip = tip[1:-1]
        if tip.startswith("'") and tip.endswith("'"):
            tip = tip[1:-1]

        # Truncate if too long
        if len(tip) > 200:
            # Try to cut at sentence boundary
            last_period = tip[:200].rfind(".")
            if last_period > 100:
                tip = tip[: last_period + 1]
            else:
                tip = tip[:197] + "..."

        return ExerciseTipResponse(
            tip=tip,
            exercise_name=body.exercise_name,
        )

    except Exception as e:
        logger.warning(f"Exercise tip generation failed: {e}", exc_info=True)
        # Return a fallback tip based on coaching style
        fallback = _get_fallback_tip(body)
        return ExerciseTipResponse(
            tip=fallback,
            exercise_name=body.exercise_name,
        )


def _get_fallback_tip(req: ExerciseTipRequest) -> str:
    """Generate a style-appropriate fallback tip when AI is unavailable."""
    name = req.exercise_name
    style = req.coaching_style

    if style == "drill-sergeant":
        return f"Lock in. Control every rep. No half reps on {name}."
    elif style == "zen-master":
        return f"Breathe into the movement. Feel each rep of {name} with intention."
    elif style == "hype-beast":
        return f"Time to GO OFF on {name}! Every rep counts, let's get it!"
    elif style == "scientist":
        return f"Focus on full range of motion and controlled tempo for {name}."
    else:  # motivational
        return f"You've got this! Focus on strong, controlled reps for {name}."
