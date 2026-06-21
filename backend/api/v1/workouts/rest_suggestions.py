"""
AI-Powered Rest Time Suggestion API.

Provides intelligent rest duration suggestions during active workouts based on:
- Exercise type (compound vs isolation)
- Rate of Perceived Exertion (RPE)
- Remaining sets in the workout
- User's fitness goals
- Fatigue accumulation (later sets need more rest)

Uses Gemini AI to generate personalized reasoning for suggestions.
"""

from fastapi import APIRouter, Depends, HTTPException, Request
from core.auth import get_current_user
from core.rate_limiter import user_limiter
from core.exceptions import safe_internal_error
from typing import List, Optional
from pydantic import BaseModel, Field

from core.logger import get_logger
from services.gemini_service import GeminiService

router = APIRouter()
logger = get_logger(__name__)

# Singleton Gemini service
_gemini_service: Optional[GeminiService] = None


def get_gemini_service() -> GeminiService:
    """Get or create Gemini service singleton."""
    global _gemini_service
    if _gemini_service is None:
        _gemini_service = GeminiService()
    return _gemini_service


# Rest time constants based on exercise science
REST_RANGES = {
    "compound_heavy": {"min": 180, "max": 300, "quick": 120},  # RPE 9+
    "compound_moderate": {"min": 120, "max": 180, "quick": 90},  # RPE 7-8
    "compound_light": {"min": 90, "max": 120, "quick": 60},  # RPE 6 or lower
    "isolation_heavy": {"min": 90, "max": 120, "quick": 60},  # RPE 9+
    "isolation_moderate": {"min": 60, "max": 90, "quick": 45},  # RPE 7-8
    "isolation_light": {"min": 45, "max": 60, "quick": 30},  # RPE 6 or lower
}

# Fatigue multiplier for later sets (percentage increase)
FATIGUE_MULTIPLIER = {
    1: 1.0,   # First set - baseline
    2: 1.0,   # Second set - still fresh
    3: 1.05,  # Third set - slight fatigue
    4: 1.10,  # Fourth set - moderate fatigue
    5: 1.15,  # Fifth set - noticeable fatigue
    6: 1.20,  # Sixth+ set - significant fatigue
}


class RestSuggestionRequest(BaseModel):
    """Request for AI rest time suggestion."""
    rpe: int = Field(..., ge=5, le=10, description="Rate of Perceived Exertion (5-10)")
    exercise_type: str = Field(..., description="Type of exercise (e.g., 'strength', 'cardio')")
    exercise_name: Optional[str] = Field(None, description="Name of the current exercise")
    sets_remaining: int = Field(..., ge=0, description="Number of sets remaining")
    sets_completed: int = Field(default=0, ge=0, description="Number of sets already completed")
    is_compound: bool = Field(..., description="Whether the exercise is a compound movement")
    user_goals: List[str] = Field(default=[], description="User's fitness goals")
    muscle_group: Optional[str] = Field(None, description="Primary muscle group being worked")

    # Optional heart-rate context. All default None so existing callers that
    # never send HR data behave exactly as before (byte-for-byte identical).
    current_hr: Optional[int] = Field(
        None, ge=30, le=250, description="Live BPM at the moment the rest timer hit zero"
    )
    peak_hr: Optional[int] = Field(
        None, ge=30, le=250, description="Peak BPM during the just-finished set"
    )
    resting_hr: Optional[int] = Field(
        None, ge=30, le=250, description="User's resting heart rate, if known"
    )
    max_hr: Optional[int] = Field(
        None, ge=30, le=250, description="User's estimated max heart rate, if known"
    )
    hr_recovered: Optional[bool] = Field(
        None, description="Client's local determination of whether HR has recovered to target"
    )


class RestSuggestionResponse(BaseModel):
    """AI-generated rest time suggestion response."""
    suggested_seconds: int = Field(..., description="Recommended rest duration in seconds")
    reasoning: str = Field(..., description="Personalized explanation for the suggestion")
    quick_option_seconds: int = Field(..., description="Shorter rest option for time-pressed users")
    rest_category: str = Field(..., description="Category of rest (short, moderate, long)")
    ai_powered: bool = Field(default=True, description="Whether this suggestion used AI")


def _hr_is_elevated(request: "RestSuggestionRequest") -> Optional[bool]:
    """
    Decide whether heart rate is still meaningfully elevated.

    Returns:
        True  - HR is still up; the lifter should rest longer.
        False - HR has settled; the RPE-based suggestion stands.
        None  - No usable HR signal was sent; caller should ignore HR entirely.

    Determination order (most explicit signal first):
    1. The client's own `hr_recovered` flag, when provided, is authoritative.
    2. Otherwise, if `current_hr` plus a recovery reference is available, compare
       against the higher of two thresholds:
         - 70% of max HR, and
         - the Karvonen target: resting + 0.6 * (max - resting)  [reserve method]
       HR above the applicable threshold => still elevated.
    """
    if request.hr_recovered is not None:
        return not request.hr_recovered

    if request.current_hr is None:
        return None

    thresholds = []
    if request.max_hr is not None and request.max_hr > 0:
        thresholds.append(request.max_hr * 0.70)
        if request.resting_hr is not None and request.max_hr > request.resting_hr:
            # Heart-rate reserve (Karvonen) target.
            thresholds.append(
                request.resting_hr + 0.6 * (request.max_hr - request.resting_hr)
            )

    if not thresholds:
        # current_hr alone, without max_hr, isn't enough to judge recovery.
        return None

    threshold = max(thresholds)
    return request.current_hr > threshold


# Deterministically-chosen, human-varying phrasings for the "HR still up" case.
# Chosen by current_hr % len so the same input always yields the same line, but
# repeated sets with drifting HR rotate through variants instead of repeating.
_HR_ELEVATED_REASONS = [
    "Your heart rate's still up around {hr} bpm — give it ~{extra}s more to settle.",
    "HR is sitting near {hr} bpm, so I've added about {extra}s to let it come down.",
    "You're still elevated at roughly {hr} bpm; a little extra rest (~{extra}s) here pays off.",
    "Pulse is hovering around {hr} bpm — stretching this rest by ~{extra}s keeps the next set strong.",
]

_HR_SETTLED_REASONS = [
    "HR's already settled — you're good to go.",
    "Your heart rate has come back down, so no need to wait around.",
    "Pulse looks recovered — you're clear to start the next set.",
]


def get_rest_category(seconds: int) -> str:
    """Categorize rest duration."""
    if seconds <= 60:
        return "short"
    elif seconds <= 120:
        return "moderate"
    elif seconds <= 180:
        return "long"
    else:
        return "extended"


def generate_rule_based_suggestion(request: RestSuggestionRequest) -> RestSuggestionResponse:
    """
    Generate a rule-based rest suggestion as fallback.

    This is used when:
    - AI service is unavailable
    - Need a quick response without API call

    Logic based on exercise science research:
    - Compound exercises need more rest than isolation
    - Higher RPE means more recovery needed
    - Later sets require more rest due to fatigue accumulation
    """
    # Determine base rest range based on exercise type and RPE
    if request.is_compound:
        if request.rpe >= 9:
            base_range = REST_RANGES["compound_heavy"]
        elif request.rpe >= 7:
            base_range = REST_RANGES["compound_moderate"]
        else:
            base_range = REST_RANGES["compound_light"]
    else:
        if request.rpe >= 9:
            base_range = REST_RANGES["isolation_heavy"]
        elif request.rpe >= 7:
            base_range = REST_RANGES["isolation_moderate"]
        else:
            base_range = REST_RANGES["isolation_light"]

    # Calculate set number for fatigue multiplier
    set_number = request.sets_completed + 1
    fatigue_mult = FATIGUE_MULTIPLIER.get(min(set_number, 6), 1.20)

    # Calculate suggested rest (middle of range, adjusted for fatigue)
    base_rest = (base_range["min"] + base_range["max"]) / 2
    suggested_seconds = int(base_rest * fatigue_mult)

    # Round to nearest 15 seconds for cleaner numbers
    suggested_seconds = round(suggested_seconds / 15) * 15

    # Calculate quick option (lower bound with slight reduction)
    quick_option = base_range["quick"]

    # Adjust for user goals
    if "strength" in [g.lower() for g in request.user_goals]:
        # Strength training benefits from longer rest for ATP recovery
        suggested_seconds = int(suggested_seconds * 1.1)
        suggested_seconds = round(suggested_seconds / 15) * 15
    elif "endurance" in [g.lower() for g in request.user_goals] or "weight_loss" in [g.lower() for g in request.user_goals]:
        # Shorter rest maintains elevated heart rate
        suggested_seconds = int(suggested_seconds * 0.85)
        suggested_seconds = round(suggested_seconds / 15) * 15

    # Generate reasoning
    movement_type = "compound" if request.is_compound else "isolation"
    intensity = "high" if request.rpe >= 9 else "moderate" if request.rpe >= 7 else "manageable"

    reasoning = f"Based on your {intensity} effort (RPE {request.rpe}) on this {movement_type} exercise"

    if set_number >= 4:
        reasoning += f", and accounting for fatigue after {set_number - 1} sets"

    if request.sets_remaining > 0:
        reasoning += f", with {request.sets_remaining} sets still to go"

    reasoning += ". This rest duration optimizes muscle recovery while maintaining workout momentum."

    # --- Optional heart-rate adjustment -------------------------------------
    # Only runs when HR data was actually sent. With no HR fields, hr_elevated is
    # None and this block is skipped entirely, so behavior is unchanged.
    hr_elevated = _hr_is_elevated(request)
    if hr_elevated is True:
        # Nudge rest UP modestly (~20-40s) and bump the quick option a touch.
        # Scale the bump a little by how far over threshold we are when we have a
        # current_hr, otherwise default to a sensible ~30s.
        extra = 30
        if request.current_hr is not None and request.max_hr is not None and request.max_hr > 0:
            over_frac = max(0.0, (request.current_hr / request.max_hr) - 0.70)
            extra = int(min(40, max(20, 20 + over_frac * 200)))
        extra = round(extra / 5) * 5  # clean 5s steps

        suggested_seconds += extra
        suggested_seconds = round(suggested_seconds / 15) * 15
        quick_option = min(suggested_seconds, quick_option + 15)

        hr_for_copy = request.current_hr if request.current_hr is not None else request.peak_hr
        variant = _HR_ELEVATED_REASONS[(hr_for_copy or 0) % len(_HR_ELEVATED_REASONS)]
        hr_sentence = variant.format(hr=hr_for_copy if hr_for_copy is not None else "elevated", extra=extra)
        reasoning = f"{hr_sentence} {reasoning}"
    elif hr_elevated is False:
        # HR has recovered: keep the RPE-based suggestion, add a reassuring note.
        hr_for_copy = request.current_hr if request.current_hr is not None else request.peak_hr
        settled = _HR_SETTLED_REASONS[(hr_for_copy or 0) % len(_HR_SETTLED_REASONS)]
        reasoning = f"{settled} {reasoning}"

    return RestSuggestionResponse(
        suggested_seconds=suggested_seconds,
        reasoning=reasoning,
        quick_option_seconds=quick_option,
        rest_category=get_rest_category(suggested_seconds),
        ai_powered=False,
    )


async def generate_ai_suggestion(
    gemini: GeminiService,
    request: RestSuggestionRequest,
    rule_based: RestSuggestionResponse
) -> RestSuggestionResponse:
    """
    Generate an AI-powered rest suggestion using Gemini.

    Takes the rule-based suggestion as a baseline and generates
    personalized reasoning using AI.
    """
    # Build prompt for AI
    movement_type = "compound" if request.is_compound else "isolation"
    goals_str = ", ".join(request.user_goals) if request.user_goals else "general fitness"
    exercise_name = request.exercise_name or "this exercise"
    muscle_info = f" targeting {request.muscle_group}" if request.muscle_group else ""

    prompt = f"""You are an expert fitness coach providing rest time advice during a workout.

CURRENT SITUATION:
- Exercise: {exercise_name}{muscle_info}
- Movement Type: {movement_type.capitalize()} exercise
- RPE (Rate of Perceived Exertion): {request.rpe}/10
- Sets Completed: {request.sets_completed}
- Sets Remaining: {request.sets_remaining}
- User Goals: {goals_str}

CALCULATED REST TIME: {rule_based.suggested_seconds} seconds

Your task is to provide a SHORT (1-2 sentences max), motivational explanation for why this rest duration is optimal.

Guidelines:
- Be encouraging and coach-like
- Reference the specific effort level and exercise type
- If relevant, mention how this rest supports their goals
- Keep it brief - this appears on a mobile screen during workout
- NO emojis
- Do NOT just repeat the numbers

Return ONLY the reasoning text, nothing else."""

    try:
        response = await gemini.chat(
            user_message=prompt,
            system_prompt="You are a concise fitness coach. Provide brief, motivational rest time explanations."
        )

        # Clean up response
        reasoning = response.strip()

        # Remove any markdown or quotes
        if reasoning.startswith('"') and reasoning.endswith('"'):
            reasoning = reasoning[1:-1]
        if reasoning.startswith("'") and reasoning.endswith("'"):
            reasoning = reasoning[1:-1]

        # Truncate if too long (max 200 chars for mobile display)
        if len(reasoning) > 200:
            reasoning = reasoning[:197] + "..."

        return RestSuggestionResponse(
            suggested_seconds=rule_based.suggested_seconds,
            reasoning=reasoning,
            quick_option_seconds=rule_based.quick_option_seconds,
            rest_category=rule_based.rest_category,
            ai_powered=True,
        )

    except Exception as e:
        logger.warning(f"AI reasoning generation failed: {e}", exc_info=True)
        raise


@router.post("/rest-suggestion", response_model=RestSuggestionResponse)
# Per-USER (not per-IP) + 20/min so a normal multi-set workout (one call per
# set) never trips it, even on a shared gym/NAT IP.
@user_limiter.limit("20/minute")
async def get_rest_suggestion(body: RestSuggestionRequest,
    request: Request,
    current_user: dict = Depends(get_current_user),
):
    """
    Get an AI-powered rest time suggestion.

    This endpoint is called during active workouts after completing a set.
    It analyzes:
    - Exercise type (compound vs isolation)
    - Current RPE (Rate of Perceived Exertion)
    - Sets remaining (fatigue accumulation)
    - User's fitness goals

    Returns a personalized rest duration with AI-generated reasoning.

    Falls back to rule-based suggestions with generic reasoning if AI is unavailable.
    """
    logger.info(
        f"Rest suggestion request: exercise_type={body.exercise_type}, "
        f"rpe={body.rpe}, is_compound={body.is_compound}, "
        f"sets_remaining={body.sets_remaining}"
    )

    try:
        # First, generate rule-based suggestion (always works)
        rule_based = generate_rule_based_suggestion(body)

        logger.info(
            f"Rule-based suggestion: {rule_based.suggested_seconds}s "
            f"(quick: {rule_based.quick_option_seconds}s)"
        )

        # Try to enhance with AI-generated reasoning
        try:
            gemini = get_gemini_service()
            suggestion = await generate_ai_suggestion(gemini, body, rule_based)

            logger.info(
                f"AI suggestion: {suggestion.suggested_seconds}s, "
                f"ai_powered={suggestion.ai_powered}"
            )

            return suggestion

        except Exception as ai_error:
            logger.warning(f"AI suggestion failed, using rule-based: {ai_error}", exc_info=True)
            return rule_based

    except Exception as e:
        logger.error(f"Rest suggestion failed: {e}", exc_info=True)
        raise safe_internal_error(e, "rest_suggestions")


@router.get("/rest-suggestion/ranges")
async def get_rest_ranges(
    current_user: dict = Depends(get_current_user),
):
    """
    Get the standard rest time ranges used for suggestions.

    Returns the base rest ranges before fatigue adjustments.
    Useful for displaying rest time guidelines to users.
    """
    return {
        "ranges": REST_RANGES,
        "fatigue_multipliers": FATIGUE_MULTIPLIER,
        "description": {
            "compound_heavy": "Heavy compound lifts (squats, deadlifts) at RPE 9-10",
            "compound_moderate": "Moderate compound lifts at RPE 7-8",
            "compound_light": "Light compound lifts at RPE 6 or below",
            "isolation_heavy": "Heavy isolation exercises at RPE 9-10",
            "isolation_moderate": "Moderate isolation exercises at RPE 7-8",
            "isolation_light": "Light isolation exercises at RPE 6 or below",
        },
    }
