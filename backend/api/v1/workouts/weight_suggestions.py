"""
AI-Powered Weight Suggestion API.

Provides real-time weight suggestions during active workouts based on:
- Current set performance (reps achieved, RPE, RIR)
- Historical workout data for this exercise
- User's fitness level and goals
- Equipment-aware weight increments

Uses Gemini AI to generate intelligent, personalized suggestions.
"""

from fastapi import APIRouter, Depends, HTTPException, Request
from core.auth import get_current_user
from core.rate_limiter import limiter
from core.exceptions import safe_internal_error
from typing import List, Optional
from datetime import datetime
from pydantic import BaseModel

from core.supabase_db import get_supabase_db
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


# Equipment-aware weight increments
EQUIPMENT_INCREMENTS = {
    "dumbbell": 2.5,
    "dumbbells": 2.5,
    "barbell": 2.5,
    "machine": 5.0,
    "cable": 2.5,
    "kettlebell": 4.0,
    "bodyweight": 0,
}


class SetPerformance(BaseModel):
    """Data about a completed set."""
    set_number: int
    reps_completed: int
    target_reps: int
    weight_kg: float
    rpe: Optional[int] = None  # Rate of Perceived Exertion (6-10)
    rir: Optional[int] = None  # Reps in Reserve (0-5)


class ExerciseHistory(BaseModel):
    """Historical performance data for an exercise."""
    date: str
    weight_kg: float
    reps: int
    sets: int
    rpe: Optional[int] = None
    rir: Optional[int] = None


class WeightSuggestionRequest(BaseModel):
    """Request for AI weight suggestion."""
    user_id: str
    exercise_name: str
    exercise_id: Optional[str] = None
    equipment: str = "dumbbell"
    muscle_group: str = "unknown"
    current_set: SetPerformance
    total_sets: int
    is_last_set: bool = False
    fitness_level: str = "intermediate"
    goals: List[str] = []
    # AI Settings from user preferences
    coaching_style: str = "motivational"
    communication_tone: str = "encouraging"
    encouragement_level: float = 0.7
    response_length: str = "balanced"


class WeightSuggestionResponse(BaseModel):
    """AI-generated weight suggestion response."""
    suggested_weight: float
    weight_delta: float
    suggestion_type: str  # "increase", "maintain", "decrease"
    reason: str
    encouragement: str
    confidence: float
    ai_powered: bool = True


async def get_exercise_history(
    user_id: str,
    exercise_name: str,
    limit: int = 5
) -> List[dict]:
    """
    Fetch user's recent performance history for an exercise.

    Returns the last N workout sessions where this exercise was performed,
    including weight, reps, and intensity feedback.

    Uses the performance_logs table with efficient indexed queries instead of
    parsing large JSON blobs from workout_logs.
    """
    try:
        db = get_supabase_db()

        # Try the efficient database function first (uses indexed performance_logs)
        try:
            result = db.client.rpc(
                "get_exercise_history",
                {
                    "p_user_id": user_id,
                    "p_exercise_name": exercise_name,
                    "p_limit": limit,
                }
            ).execute()

            if result.data:
                history = []
                for row in result.data:
                    history.append({
                        "date": row.get("workout_date"),
                        "weight_kg": row.get("weight_kg", 0),
                        "reps": row.get("reps", 0),
                        "sets": row.get("sets_count", 1),
                        "rpe": row.get("rpe"),
                        "rir": row.get("rir"),
                    })
                return history

        except Exception as rpc_error:
            logger.debug(f"RPC get_exercise_history not available, falling back to direct query: {rpc_error}")

        # Fallback: Query performance_logs directly (still efficient with index)
        result = db.client.table("performance_logs").select(
            "workout_log_id, recorded_at, weight_kg, reps_completed, rpe, rir"
        ).eq(
            "user_id", user_id
        ).ilike(
            "exercise_name", exercise_name
        ).eq(
            "is_completed", True
        ).order(
            "recorded_at", desc=True
        ).limit(limit * 5).execute()  # Get more rows to group by workout

        if result.data:
            # Group by workout_log_id to get best set per workout
            from collections import defaultdict
            by_workout = defaultdict(list)
            for row in result.data:
                by_workout[row["workout_log_id"]].append(row)

            history = []
            for workout_log_id, sets in by_workout.items():
                # Get best set by weight
                best_set = max(sets, key=lambda s: s.get("weight_kg", 0))
                history.append({
                    "date": best_set.get("recorded_at"),
                    "weight_kg": best_set.get("weight_kg", 0),
                    "reps": best_set.get("reps_completed", 0),
                    "sets": len(sets),
                    "rpe": best_set.get("rpe"),
                    "rir": best_set.get("rir"),
                })

                if len(history) >= limit:
                    break

            # Sort by date descending
            history.sort(key=lambda x: x.get("date", ""), reverse=True)
            return history[:limit]

        # Final fallback: Legacy JSON parsing (for old data not yet migrated)
        logger.debug(f"No performance_logs found for {exercise_name}, trying legacy JSON parsing")
        result = db.client.table("workout_logs").select(
            "id, completed_at, sets_json, workout_id"
        ).eq(
            "user_id", user_id
        ).not_.is_(
            "completed_at", "null"
        ).order(
            "completed_at", desc=True
        ).limit(20).execute()

        history = []
        for log in result.data or []:
            sets_json = log.get("sets_json", {}) or {}

            # Handle both dict and string formats
            if isinstance(sets_json, str):
                import json
                try:
                    sets_json = json.loads(sets_json)
                except:
                    continue

            # sets_json structure: {exercise_name: [{reps, weight, rpe, rir, ...}]}
            if exercise_name.lower() in [k.lower() for k in sets_json.keys()]:
                matching_key = next(
                    k for k in sets_json.keys()
                    if k.lower() == exercise_name.lower()
                )
                sets_data = sets_json[matching_key]

                if sets_data:
                    best_set = max(sets_data, key=lambda s: s.get("weight", 0))
                    history.append({
                        "date": log["completed_at"],
                        "weight_kg": best_set.get("weight", 0),
                        "reps": best_set.get("reps", 0),
                        "sets": len(sets_data),
                        "rpe": best_set.get("rpe"),
                        "rir": best_set.get("rir"),
                    })

                    if len(history) >= limit:
                        break

        return history

    except Exception as e:
        logger.warning(f"Failed to fetch exercise history: {e}")
        return []


def get_equipment_increment(equipment: str) -> float:
    """Get the appropriate weight increment for equipment type."""
    equipment_lower = equipment.lower()

    for key, increment in EQUIPMENT_INCREMENTS.items():
        if key in equipment_lower:
            return increment

    return 2.5  # Default increment


def generate_rule_based_suggestion(
    request: WeightSuggestionRequest,
    equipment_increment: float
) -> WeightSuggestionResponse:
    """
    Generate a rule-based weight suggestion as fallback.

    This is used when:
    - AI service is unavailable
    - No RPE/RIR data provided
    - Need a quick response without API call
    """
    current = request.current_set

    # Calculate rep performance ratio
    rep_ratio = current.reps_completed / current.target_reps if current.target_reps > 0 else 1.0

    # Determine effective RIR (convert RPE if needed)
    effective_rir = None
    if current.rir is not None:
        effective_rir = current.rir
    elif current.rpe is not None:
        effective_rir = max(0, 10 - current.rpe)

    if effective_rir is None:
        # Without intensity data, suggest maintaining weight
        return WeightSuggestionResponse(
            suggested_weight=current.weight_kg,
            weight_delta=0,
            suggestion_type="maintain",
            reason="Track your RPE/RIR to get personalized suggestions!",
            encouragement="Keep pushing! 💪",
            confidence=0.5,
            ai_powered=False,
        )

    # Decision logic based on RIR and rep achievement
    if effective_rir >= 4 and rep_ratio >= 1.0:
        # Very easy - increase by double increment
        delta = equipment_increment * 2
        return WeightSuggestionResponse(
            suggested_weight=current.weight_kg + delta,
            weight_delta=delta,
            suggestion_type="increase",
            reason=f"That set was too easy! You had {effective_rir}+ reps left.",
            encouragement="Time to level up! 💪",
            confidence=0.9,
            ai_powered=False,
        )
    elif effective_rir >= 3 and rep_ratio >= 1.0:
        # Easy - increase by one increment
        delta = equipment_increment
        return WeightSuggestionResponse(
            suggested_weight=current.weight_kg + delta,
            weight_delta=delta,
            suggestion_type="increase",
            reason=f"Great form with {effective_rir} reps in reserve.",
            encouragement="Let's push a bit harder!",
            confidence=0.85,
            ai_powered=False,
        )
    elif effective_rir >= 2 and rep_ratio >= 0.9:
        # Good working set
        return WeightSuggestionResponse(
            suggested_weight=current.weight_kg,
            weight_delta=0,
            suggestion_type="maintain",
            reason="Perfect intensity! Keep this weight.",
            encouragement="You're in the zone! 🎯",
            confidence=0.9,
            ai_powered=False,
        )
    elif effective_rir <= 1 and rep_ratio >= 0.8:
        # Hard set
        if request.is_last_set:
            return WeightSuggestionResponse(
                suggested_weight=current.weight_kg,
                weight_delta=0,
                suggestion_type="maintain",
                reason="Pushed hard on the last set - perfect!",
                encouragement="Great finish! 🔥",
                confidence=0.85,
                ai_powered=False,
            )
        else:
            return WeightSuggestionResponse(
                suggested_weight=current.weight_kg,
                weight_delta=0,
                suggestion_type="maintain",
                reason="Working hard! Save energy for remaining sets.",
                encouragement="Stay strong!",
                confidence=0.7,
                ai_powered=False,
            )
    elif effective_rir == 0 or rep_ratio < 0.7:
        # Failed or struggled
        delta = -equipment_increment
        return WeightSuggestionResponse(
            suggested_weight=max(0, current.weight_kg + delta),
            weight_delta=delta,
            suggestion_type="decrease",
            reason="Reduce weight to maintain form and hit targets.",
            encouragement="Smart training is sustainable training.",
            confidence=0.85,
            ai_powered=False,
        )
    else:
        # Default - maintain
        return WeightSuggestionResponse(
            suggested_weight=current.weight_kg,
            weight_delta=0,
            suggestion_type="maintain",
            reason="Good effort. Maintain current weight.",
            encouragement="Keep pushing!",
            confidence=0.7,
            ai_powered=False,
        )


async def generate_ai_suggestion(
    gemini: GeminiService,
    request: WeightSuggestionRequest,
    history: List[dict],
    equipment_increment: float
) -> WeightSuggestionResponse:
    """
    Generate an AI-powered weight suggestion using Gemini.

    Takes into account:
    - Current set performance
    - Historical data for this exercise
    - User's fitness level and goals
    - Equipment-specific increments
    - User's AI settings for personalized coaching style
    """
    current = request.current_set

    # Build coaching persona based on user's AI settings
    coaching_personas = {
        "motivational": "You are an enthusiastic, supportive coach who celebrates every win and keeps athletes motivated",
        "professional": "You are a professional, data-driven coach who focuses on facts and optimal performance",
        "friendly": "You are a friendly, approachable coach who feels like a supportive workout buddy",
        "tough-love": "You are a direct, no-nonsense coach who challenges athletes to push their limits",
        "drill-sergeant": "You are an intense, demanding coach who expects excellence and maximum effort",
        "college-coach": "You are an energetic college coach with team spirit and competitive drive",
        "zen-master": "You are a calm, mindful coach who emphasizes form, breathing, and body awareness",
        "hype-beast": "You are an extremely energetic coach with maximum enthusiasm and hype",
        "scientist": "You are a data-driven coach who explains the science behind each suggestion",
        "comedian": "You are a funny coach who uses humor while still giving solid advice",
        "old-school": "You are a classic, traditional coach with old-school training wisdom",
    }

    tone_instructions = {
        "casual": "Use casual, friendly language with relaxed phrasing",
        "encouraging": "Use warm, supportive language that builds confidence",
        "formal": "Use professional, precise language",
        "gen-z": "Use modern slang like 'no cap', 'lowkey', 'fr fr', 'bussin'",
        "sarcastic": "Use playful sarcasm while still being helpful",
        "roast-mode": "Roast them a little (playfully) while giving good advice",
        "pirate": "Talk like a pirate, arrr!",
        "british": "Use British English with dry wit and proper phrasing",
        "surfer": "Talk like a chill surfer dude, bro",
        "anime": "Use anime-style expressions and enthusiasm",
    }

    # Build encouragement guidance based on level
    if request.encouragement_level >= 0.8:
        encouragement_note = "Be VERY enthusiastic and celebratory in your encouragement message. Use exclamation marks!"
    elif request.encouragement_level >= 0.5:
        encouragement_note = "Be moderately encouraging and positive in your message"
    else:
        encouragement_note = "Keep encouragement minimal and focus on the data. Be concise."

    # Build response length guidance
    length_guidance = {
        "concise": "Keep your reason to ONE short sentence (max 15 words)",
        "balanced": "Keep your reason to 1-2 sentences",
        "detailed": "Provide a detailed 2-3 sentence explanation with specific data points",
    }

    persona = coaching_personas.get(request.coaching_style, coaching_personas["motivational"])
    tone = tone_instructions.get(request.communication_tone, tone_instructions["encouraging"])
    length = length_guidance.get(request.response_length, length_guidance["balanced"])

    # Build history context
    history_context = ""
    if history:
        history_lines = []
        for h in history[:5]:
            history_lines.append(
                f"- {h['date'][:10]}: {h['weight_kg']}kg x {h['reps']} reps"
                + (f", RPE {h['rpe']}" if h.get('rpe') else "")
            )
        history_context = "\n".join(history_lines)
    else:
        history_context = "No previous history for this exercise."

    # Build RPE/RIR context
    intensity_context = ""
    if current.rpe is not None:
        rpe_desc = {
            6: "Light - could do 4+ more reps",
            7: "Moderate - could do 3 more reps",
            8: "Challenging - could do 2 more reps",
            9: "Hard - could do 1 more rep",
            10: "Max effort - couldn't do another rep",
        }
        intensity_context += f"RPE {current.rpe}: {rpe_desc.get(current.rpe, 'Unknown')}\n"

    if current.rir is not None:
        intensity_context += f"RIR {current.rir}: {current.rir} reps left in the tank"

    if not intensity_context:
        intensity_context = "No intensity data provided"

    prompt = f"""{persona}
{tone}
{encouragement_note}
{length}

CURRENT SET PERFORMANCE:
- Exercise: {request.exercise_name}
- Equipment: {request.equipment}
- Muscle Group: {request.muscle_group}
- Set {current.set_number} of {request.total_sets}
- Target: {current.target_reps} reps
- Achieved: {current.reps_completed} reps
- Weight Used: {current.weight_kg}kg
- Intensity: {intensity_context}
- Is Last Set: {request.is_last_set}

USER PROFILE:
- Fitness Level: {request.fitness_level}
- Goals: {', '.join(request.goals) if request.goals else 'General fitness'}

EXERCISE HISTORY (Recent Sessions):
{history_context}

EQUIPMENT CONSTRAINTS:
- Minimum weight increment: {equipment_increment}kg
- Available increments must be in multiples of {equipment_increment}kg

ANALYZE the performance and provide a weight suggestion for the NEXT set.

Return ONLY valid JSON (no markdown):
{{
  "suggested_weight": <number - the suggested weight in kg>,
  "weight_delta": <number - change from current weight>,
  "suggestion_type": "<increase|maintain|decrease>",
  "reason": "<explanation following the length guidance above>",
  "encouragement": "<motivational message matching your coaching persona and tone>",
  "confidence": <0.0-1.0 - how confident you are in this suggestion>
}}

IMPORTANT:
- Consider the user's historical performance trend
- Account for fatigue (later sets may need lower weight)
- If they're building up (earlier sets), consider progressive overload
- Weight suggestions must align with equipment increments
- Stay in character with your coaching persona throughout"""

    try:
        response = await gemini.chat(
            user_message=prompt,
            system_prompt="You are a precision fitness coach. Analyze set performance and provide optimal weight suggestions. Return only valid JSON."
        )

        # Parse response
        import json
        content = response.strip()

        # Clean markdown if present
        if content.startswith("```json"):
            content = content[7:]
        elif content.startswith("```"):
            content = content[3:]
        if content.endswith("```"):
            content = content[:-3]

        data = json.loads(content.strip())

        # Validate and round to equipment increment
        suggested = data.get("suggested_weight", current.weight_kg)
        suggested = round(suggested / equipment_increment) * equipment_increment
        suggested = max(0, suggested)  # No negative weights

        delta = suggested - current.weight_kg

        # Determine suggestion type based on delta
        if delta > 0:
            suggestion_type = "increase"
        elif delta < 0:
            suggestion_type = "decrease"
        else:
            suggestion_type = "maintain"

        return WeightSuggestionResponse(
            suggested_weight=suggested,
            weight_delta=delta,
            suggestion_type=suggestion_type,
            reason=data.get("reason", "Based on your performance."),
            encouragement=data.get("encouragement", "Keep it up!"),
            confidence=min(1.0, max(0.0, data.get("confidence", 0.8))),
            ai_powered=True,
        )

    except Exception as e:
        logger.error(f"AI suggestion generation failed: {e}")
        raise


@router.post("/weight-suggestion", response_model=WeightSuggestionResponse)
@limiter.limit("5/minute")
async def get_weight_suggestion(body: WeightSuggestionRequest,
    request: Request = None,
    current_user: dict = Depends(get_current_user),
):
    """
    Get an AI-powered weight suggestion for the next set.

    This endpoint is called during active workouts after completing a set.
    It analyzes:
    - Current set performance (reps, weight, RPE/RIR)
    - Historical exercise data
    - User profile and goals
    - AI settings for personalized coaching style

    Returns a personalized weight suggestion with reasoning.

    Falls back to rule-based suggestions if AI is unavailable.
    """
    logger.info(
        f"Weight suggestion request: user={body.user_id}, "
        f"exercise={body.exercise_name}, "
        f"set={body.current_set.set_number}/{body.total_sets}"
    )

    # Validate input - reject obviously invalid data
    if body.current_set.reps_completed <= 0:
        logger.info("Invalid data: 0 reps completed, returning prompt to enter data")
        return WeightSuggestionResponse(
            suggested_weight=body.current_set.weight_kg,
            weight_delta=0,
            suggestion_type="invalid",
            reason="Please enter valid reps to get personalized suggestions",
            encouragement="Track your sets to unlock AI-powered weight recommendations!",
            confidence=0,
            ai_powered=False,
        )

    try:
        # Get equipment-specific increment
        equipment_increment = get_equipment_increment(body.equipment)

        # Check if we have intensity data for AI suggestion
        has_intensity_data = (
            body.current_set.rpe is not None or
            body.current_set.rir is not None
        )

        if not has_intensity_data:
            # Without RPE/RIR, use rule-based
            logger.info("No intensity data provided, using rule-based suggestion")
            return generate_rule_based_suggestion(body, equipment_increment)

        # Fetch exercise history
        history = await get_exercise_history(
            user_id=body.user_id,
            exercise_name=body.exercise_name,
            limit=5
        )

        # Try AI-powered suggestion
        try:
            gemini = get_gemini_service()
            suggestion = await generate_ai_suggestion(
                gemini=gemini,
                request=body,
                history=history,
                equipment_increment=equipment_increment
            )
            logger.info(
                f"AI suggestion: {suggestion.suggestion_type} to {suggestion.suggested_weight}kg "
                f"(delta: {suggestion.weight_delta:+.1f}kg, confidence: {suggestion.confidence:.0%})"
            )
            return suggestion

        except Exception as ai_error:
            logger.warning(f"AI suggestion failed, falling back to rules: {ai_error}")
            return generate_rule_based_suggestion(body, equipment_increment)

    except Exception as e:
        logger.error(f"Weight suggestion failed: {e}")
        raise safe_internal_error(e, "weight_suggestions")


@router.get("/weight-suggestion/history/{user_id}/{exercise_name}")
async def get_weight_history(user_id: str, exercise_name: str, limit: int = 10,
    current_user: dict = Depends(get_current_user),
):
    """
    Get weight history for an exercise.

    Returns the user's recent performance data for the specified exercise,
    useful for displaying progress charts or informing manual weight selection.
    """
    try:
        history = await get_exercise_history(
            user_id=user_id,
            exercise_name=exercise_name,
            limit=limit
        )

        return {
            "user_id": user_id,
            "exercise_name": exercise_name,
            "history": history,
            "data_points": len(history),
        }

    except Exception as e:
        logger.error(f"Failed to get weight history: {e}")
        raise safe_internal_error(e, "weight_suggestions")
