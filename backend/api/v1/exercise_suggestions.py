"""
Exercise Suggestions API - LangGraph agent-powered exercise alternatives.

ENDPOINTS:
- POST /api/v1/exercise-suggestions/suggest - Get AI-powered exercise suggestions

RATE LIMITS:
- /suggest: 5 requests/minute (AI-intensive)

Updated: 2025-12-21 - Trigger Render redeploy for swap exercise feature
"""
from core.db import get_supabase_db
import re
from fastapi import APIRouter, HTTPException, Request, Depends
from typing import List, Optional, Dict, Any
from pydantic import BaseModel

from core.auth import get_current_user
from core.exceptions import safe_internal_error
from services.langgraph_agents.exercise_suggestion import (
    ExerciseSuggestionState,
    build_exercise_suggestion_graph,
)
from core.logger import get_logger
from core.rate_limiter import limiter

router = APIRouter()
logger = get_logger(__name__)

# Build the graph once at module load
exercise_suggestion_graph = None


def get_suggestion_graph():
    """Lazy initialization of the suggestion graph."""
    global exercise_suggestion_graph
    if exercise_suggestion_graph is None:
        exercise_suggestion_graph = build_exercise_suggestion_graph()
    return exercise_suggestion_graph


# ==================== Request/Response Models ====================

class CurrentExercise(BaseModel):
    """Current exercise being swapped."""
    name: str
    sets: int = 3
    reps: int = 10
    muscle_group: Optional[str] = None
    equipment: Optional[str] = None


class SuggestionRequest(BaseModel):
    """Request for exercise suggestions."""
    user_id: str  # UUID string
    message: str  # User's request (e.g., "I don't have dumbbells")
    current_exercise: CurrentExercise
    user_equipment: Optional[List[str]] = None
    user_injuries: Optional[List[str]] = None
    user_fitness_level: Optional[str] = "intermediate"
    avoided_exercises: Optional[List[str]] = None  # Exercises user wants to avoid
    existing_exercises: Optional[List[str]] = None  # Exercises already in the workout (for "add" mode)
    mode: Optional[str] = "swap"  # "swap" or "add"


class ExerciseSuggestion(BaseModel):
    """A single exercise suggestion."""
    id: Optional[str] = None
    name: str
    body_part: Optional[str] = None
    equipment: Optional[str] = None
    target_muscle: Optional[str] = None
    reason: str
    tip: Optional[str] = None
    rank: int = 1  # 1 = best match, 2 = second best, etc.


class SuggestionResponse(BaseModel):
    """Response with exercise suggestions."""
    suggestions: List[ExerciseSuggestion]
    message: str
    swap_reason: Optional[str] = None


# ==================== Endpoints ====================

@router.post("/suggest", response_model=SuggestionResponse)
@limiter.limit("5/minute")
async def get_exercise_suggestions(request: Request, body: SuggestionRequest, current_user: dict = Depends(get_current_user)):
    """
    Get AI-powered exercise suggestions.

    This endpoint uses a LangGraph agent that:
    1. Analyzes WHY the user wants to swap (equipment, injury, difficulty, etc.)
    2. Searches the exercise library for matching alternatives
    3. Uses AI to rank and explain the best options

    Example requests:
    - "I don't have dumbbells" -> finds bodyweight or barbell alternatives
    - "I have a shoulder injury" -> finds exercises that avoid shoulders
    - "I want something easier" -> finds lower difficulty alternatives
    - "Give me variety" -> finds different exercises targeting same muscle
    """
    if str(current_user["id"]) != str(body.user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Exercise suggestion request: {body.message[:50]}...")

    try:
        graph = get_suggestion_graph()

        # Build initial state
        initial_state: ExerciseSuggestionState = {
            "user_id": body.user_id,
            "user_message": body.message,
            "current_exercise": body.current_exercise.model_dump(),
            "user_equipment": body.user_equipment,
            "user_injuries": body.user_injuries,
            "user_fitness_level": body.user_fitness_level,
            "avoided_exercises": body.avoided_exercises,  # Pass avoided exercises to filter
            "existing_exercises": body.existing_exercises,
            "mode": body.mode or "swap",
            # Will be filled by nodes
            "swap_reason": None,
            "target_muscle_group": None,
            "equipment_constraint": None,
            "difficulty_preference": None,
            "candidate_exercises": [],
            "suggestions": [],
            "response_message": "",
            "error": None,
        }

        # Execute the graph
        final_state = await graph.ainvoke(initial_state)

        # Check for errors
        if final_state.get("error"):
            logger.error(f"Suggestion agent error: {final_state['error']}")

        # Build response with ranking (order matters - first is best match)
        suggestions = [
            ExerciseSuggestion(
                id=s.get("id"),
                name=s.get("name", "Unknown"),
                body_part=s.get("body_part"),
                equipment=s.get("equipment"),
                target_muscle=s.get("target_muscle"),
                reason=s.get("reason", ""),
                tip=s.get("tip"),
                rank=idx + 1,  # 1-indexed rank
            )
            for idx, s in enumerate(final_state.get("suggestions", []))
        ]

        response = SuggestionResponse(
            suggestions=suggestions,
            message=final_state.get("response_message", "Here are some alternatives:"),
            swap_reason=final_state.get("swap_reason"),
        )

        logger.info(f"Returning {len(suggestions)} suggestions")
        return response

    except Exception as e:
        logger.error(f"Exercise suggestion failed: {e}")
        raise safe_internal_error(e, "exercise_suggestions")


# ==================== Fast Suggestion Endpoint ====================

class FastSuggestionRequest(BaseModel):
    """Request for fast database-based suggestions (no AI)."""
    exercise_name: str
    user_id: str
    avoided_exercises: Optional[List[str]] = None


class FastExerciseSuggestion(BaseModel):
    """A fast suggestion result."""
    name: str
    target_muscle: Optional[str] = None
    body_part: Optional[str] = None
    equipment: Optional[str] = None
    gif_url: Optional[str] = None
    video_url: Optional[str] = None
    reason: str
    rank: int


@router.post("/suggest-fast", response_model=List[FastExerciseSuggestion])
async def get_fast_exercise_suggestions(body: FastSuggestionRequest, current_user: dict = Depends(get_current_user)):
    """
    Get exercise suggestions using fast database queries (no AI).
    Returns 8 similar exercises based on muscle group and equipment.

    This endpoint is ~20x faster than /suggest (~500ms vs ~10s) because
    it uses direct database queries instead of AI analysis.
    """
    if str(current_user["id"]) != str(body.user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    from core.supabase_db import get_supabase_db
    import random

    logger.info(f"Fast suggestion request for: {body.exercise_name}")

    try:
        db = get_supabase_db()

        # Get current exercise details from cleaned library
        current_result = db.client.table("exercise_library_cleaned") \
            .select("name, target_muscle, body_part, equipment") \
            .ilike("name", body.exercise_name) \
            .limit(1) \
            .execute()

        if not current_result.data:
            # Try partial match if exact match fails
            current_result = db.client.table("exercise_library_cleaned") \
                .select("name, target_muscle, body_part, equipment") \
                .ilike("name", f"%{body.exercise_name}%") \
                .limit(1) \
                .execute()

        if not current_result.data:
            logger.warning(f"Exercise not found: {body.exercise_name}")
            return []

        current_ex = current_result.data[0]
        target_muscle_raw = current_ex.get("target_muscle") or current_ex.get("body_part")
        equipment = current_ex.get("equipment")
        body_part = current_ex.get("body_part")

        # Non-anatomical body_part values that describe equipment categories, not body regions.
        # Including these in filters pollutes results (e.g., "Free Weights" matches ALL barbell exercises).
        NON_ANATOMICAL_BODY_PARTS = {"bodyweight", "free weights", "resistance"}

        # Strip parenthetical details from muscle names to avoid breaking
        # PostgREST .or_() parser — e.g. "Chest (Pectoralis Major)" → "Chest"
        def _strip_parens(value: str | None) -> str | None:
            if not value:
                return value
            return re.sub(r"\s*\(.*?\)", "", value).strip() or value

        # Extract specific muscles from parentheses BEFORE stripping them.
        # e.g. "Core (Rectus Abdominis, Obliques)" → ["Rectus Abdominis", "Obliques"]
        # This lets us also match exercises tagged as "Abdominals (rectus abdominis)".
        parens_muscles = []
        if target_muscle_raw:
            for parens_match in re.findall(r'\(([^)]+)\)', target_muscle_raw):
                for m in parens_match.split(","):
                    cleaned = " ".join(m.split()).strip()
                    if cleaned and len(cleaned) > 2:
                        parens_muscles.append(cleaned)

        target_muscle = _strip_parens(target_muscle_raw)

        logger.info(f"Current exercise: {current_ex['name']}, muscle: {target_muscle} (raw: {target_muscle_raw}), parens_muscles: {parens_muscles}, equipment: {equipment}")

        # Initialize equipment resolver for category-aware scoring
        from services.equipment_resolver import EquipmentResolver
        resolver = await EquipmentResolver.get_instance()
        current_canonical = resolver.resolve(equipment) if equipment else None
        current_category = resolver.get_category(equipment) if equipment else None
        current_substitutes = dict(resolver.get_substitutes(equipment)) if equipment else {}
        logger.info(f"Equipment resolved: canonical={current_canonical}, category={current_category}, substitutes={list(current_substitutes.keys())}")

        # Build query for similar exercises
        # Query by target muscle OR body part for better matches
        query = db.client.table("exercise_library_cleaned") \
            .select("name, target_muscle, body_part, equipment, gif_url, video_url")

        # Build OR filter for muscle/body part matching
        # Strip parens from body_part too in case it contains them
        clean_body_part = _strip_parens(body_part)
        # Split multi-muscle values (e.g., "Chest, Middle  Back") into separate ilike
        # conditions so PostgREST doesn't corrupt the query on the embedded commas.
        # Also normalize whitespace per segment ("Middle  Back" → "Middle Back").
        target_muscles = [" ".join(m.split()) for m in target_muscle.split(",") if m.strip()] if target_muscle else []
        filters = []
        for muscle in target_muscles:
            filters.append(f"target_muscle.ilike.%{muscle}%")
        # Also add filters for specific muscles extracted from parentheses
        for pm in parens_muscles:
            filters.append(f"target_muscle.ilike.%{pm}%")
        # Only include body_part filter if it's an actual anatomical term
        if clean_body_part and clean_body_part.lower() not in NON_ANATOMICAL_BODY_PARTS:
            filters.append(f"body_part.ilike.%{clean_body_part}%")

        if filters:
            query = query.or_(",".join(filters))

        # Exclude current exercise (case-insensitive)
        query = query.neq("name", current_ex["name"])

        # Fetch more candidates to ensure diverse equipment representation in the pool
        result = query.limit(150).execute()

        if not result.data:
            logger.info("No similar exercises found")
            return []

        # Filter out avoided exercises
        avoided_lower = set((body.avoided_exercises or []))
        avoided_lower = {ex.lower() for ex in avoided_lower}

        candidates = [
            ex for ex in result.data
            if ex["name"].lower() not in avoided_lower
        ]

        # Generic muscle tokens that indicate a non-specific target
        GENERIC_MUSCLE_TOKENS = {"full body", "general", "multiple", "all", "whole body"}

        # Score candidates
        scored = []
        for ex in candidates:
            score = 0.0
            reasons = []

            # --- Muscle match ---
            ex_muscle = " ".join((ex.get("target_muscle") or "").split()).lower()
            is_generic_muscle = (
                ex_muscle.strip() in GENERIC_MUSCLE_TOKENS
                or len(ex_muscle.strip()) < 4
            )

            if target_muscles:
                matched = [m for m in target_muscles if m.lower() in ex_muscle]
                n_matched = len(matched)
                if n_matched == len(target_muscles):
                    if is_generic_muscle:
                        score += 0.8
                        reasons.append("General fitness exercise")
                    else:
                        score += 2.0
                        reasons.append(f"Targets {', '.join(matched)}")
                elif n_matched > 0:
                    score += 2.0 * (n_matched / len(target_muscles))
                    reasons.append(f"Targets {', '.join(matched)}")
                else:
                    # Check if parens-extracted muscles match
                    parens_matched = [pm for pm in parens_muscles if pm.lower() in ex_muscle]
                    if parens_matched:
                        score += 1.8
                        reasons.append(f"Targets {', '.join(parens_matched)}")
                    elif body_part and body_part.lower() not in NON_ANATOMICAL_BODY_PARTS and body_part.lower() in (ex.get("body_part") or "").lower():
                        score += 1.5
                        reasons.append(f"Works {body_part}")
            elif target_muscle and target_muscle.lower() in ex_muscle:
                score += 0.8 if is_generic_muscle else 2.0
                reasons.append("General fitness exercise" if is_generic_muscle else f"Targets {target_muscle}")
            elif body_part and body_part.lower() not in NON_ANATOMICAL_BODY_PARTS and body_part.lower() in (ex.get("body_part") or "").lower():
                score += 1.5
                reasons.append(f"Works {body_part}")

            # --- Equipment match (category-aware, dominant signal) ---
            ex_equipment = (ex.get("equipment") or "").strip()
            ex_canonical = resolver.resolve(ex_equipment) if ex_equipment else None
            ex_category = resolver.get_category(ex_equipment) if ex_equipment else None

            if current_canonical and ex_canonical:
                if current_canonical == ex_canonical:
                    score += 3.0
                    reasons.append(f"Uses {ex_equipment}")
                elif ex_canonical in current_substitutes:
                    compat_score = current_substitutes[ex_canonical]
                    score += compat_score * 3.0
                    reasons.append(f"Similar equipment ({ex_equipment})")
                elif current_category and ex_category and current_category == ex_category:
                    score += 1.5
                    reasons.append(f"Same equipment type ({ex_equipment})")
            elif equipment and ex_equipment and equipment.lower() == ex_equipment.lower():
                # Exact string fallback for equipment not in resolver
                score += 3.0
                reasons.append(f"Uses {equipment}")

            # Small random factor for variety (kept small so equipment dominates)
            score += random.uniform(0, 0.3)

            reason = " • ".join(reasons) if reasons else "Similar exercise"
            scored.append({
                **ex,
                "score": score,
                "reason": reason,
            })

        # Sort by score descending
        scored.sort(key=lambda x: x["score"], reverse=True)

        # Take top 8
        top_suggestions = scored[:8]

        # Build response with ranks
        suggestions = [
            FastExerciseSuggestion(
                name=s["name"],
                target_muscle=s.get("target_muscle"),
                body_part=s.get("body_part"),
                equipment=s.get("equipment"),
                gif_url=s.get("gif_url"),
                video_url=s.get("video_url"),
                reason=s["reason"],
                rank=idx + 1,
            )
            for idx, s in enumerate(top_suggestions)
        ]

        logger.info(f"Returning {len(suggestions)} fast suggestions")
        return suggestions

    except Exception as e:
        logger.error(f"Fast suggestion failed: {e}")
        raise safe_internal_error(e, "exercise_suggestions")
