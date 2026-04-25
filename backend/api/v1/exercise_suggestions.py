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

# Process-lifetime alias cache so repeated misses on the same plural /
# typo'd exercise name ("Bodyweight Inverted Rows" vs the canonical
# "Bodyweight Inverted Row") only pay the fuzzy-lookup cost once.
# {lowercased_input: canonical_library_name} — None cached values mean
# "no match even after fuzzy lookup" so we don't re-hit the DB on retry.
_EXERCISE_ALIAS_CACHE: Dict[str, Optional[str]] = {}


def _normalize_exercise_lookup_key(name: str) -> str:
    """Lowercase + strip common pluralization on the last word. Many
    library exercises are stored singular ("Row", "Pull-Up") while users
    say plural ("Rows", "Pull-Ups"); this dodges the first-order mismatch
    before we fall back to expensive trigram lookup."""
    if not name:
        return ""
    s = re.sub(r"\s+", " ", name.strip().lower())
    words = s.split(" ")
    if words:
        last = words[-1]
        # Heuristic: strip a trailing 's' only if ≥4 chars and doesn't
        # end in "ss"/"us"/"is"/"es" (avoid "press" → "pres").
        if (
            len(last) >= 4
            and last.endswith("s")
            and not last.endswith(("ss", "us", "is", "es"))
        ):
            words[-1] = last[:-1]
    return " ".join(words)


async def _resolve_exercise_name(db, raw_name: str) -> Optional[Dict[str, Any]]:
    """Resolve a (possibly plural / slightly typo'd) exercise name to a
    row from exercise_library_cleaned. Tries: exact ilike → substring
    ilike → normalized-singular ilike → pg_trgm similarity. Caches the
    resolved canonical name for the lifetime of the process so the
    second request for the same misspelling costs nothing.

    Returns the library row dict or None if nothing matches.
    """
    if not raw_name:
        return None
    cache_key = raw_name.strip().lower()
    if cache_key in _EXERCISE_ALIAS_CACHE:
        canonical = _EXERCISE_ALIAS_CACHE[cache_key]
        if canonical is None:
            return None
        hit = db.client.table("exercise_library_cleaned") \
            .select("name, target_muscle, body_part, equipment") \
            .eq("name", canonical).limit(1).execute()
        if hit.data:
            return hit.data[0]
        # Canonical went stale — fall through and re-resolve.
        _EXERCISE_ALIAS_CACHE.pop(cache_key, None)

    # 1. Exact ilike on the raw input
    res = db.client.table("exercise_library_cleaned") \
        .select("name, target_muscle, body_part, equipment") \
        .ilike("name", raw_name).limit(1).execute()
    if res.data:
        _EXERCISE_ALIAS_CACHE[cache_key] = res.data[0]["name"]
        return res.data[0]

    # 2. Substring ilike
    res = db.client.table("exercise_library_cleaned") \
        .select("name, target_muscle, body_part, equipment") \
        .ilike("name", f"%{raw_name}%").limit(1).execute()
    if res.data:
        _EXERCISE_ALIAS_CACHE[cache_key] = res.data[0]["name"]
        return res.data[0]

    # 3. Normalized-singular exact ilike ("Bodyweight Inverted Rows" →
    # "Bodyweight Inverted Row").
    normalized = _normalize_exercise_lookup_key(raw_name)
    if normalized and normalized != cache_key:
        res = db.client.table("exercise_library_cleaned") \
            .select("name, target_muscle, body_part, equipment") \
            .ilike("name", normalized).limit(1).execute()
        if res.data:
            _EXERCISE_ALIAS_CACHE[cache_key] = res.data[0]["name"]
            return res.data[0]

    # 4. pg_trgm similarity — last-resort fuzzy match. Requires the
    # `fuzzy_search_exercises(q TEXT, lim INT)` RPC; if it's absent or
    # returns nothing we just accept the miss and cache a None.
    try:
        rpc = db.client.rpc(
            "fuzzy_search_exercises",
            {"q": raw_name, "lim": 1},
        ).execute()
        if rpc.data:
            row = rpc.data[0] if isinstance(rpc.data, list) else rpc.data
            if isinstance(row, dict) and row.get("name"):
                # Fetch full row so we have target_muscle / body_part / equipment.
                hit = db.client.table("exercise_library_cleaned") \
                    .select("name, target_muscle, body_part, equipment") \
                    .eq("name", row["name"]).limit(1).execute()
                if hit.data:
                    _EXERCISE_ALIAS_CACHE[cache_key] = hit.data[0]["name"]
                    return hit.data[0]
    except Exception as e:
        logger.debug(f"fuzzy_search_exercises RPC unavailable or failed for '{raw_name}': {e}")

    _EXERCISE_ALIAS_CACHE[cache_key] = None
    return None

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

    # Server-side fallback: if the client didn't pass user_equipment, load
    # it from the users row. This is the safety net for clients that
    # haven't been updated yet — without it, the search node would fall
    # through to the old free-text-constraint-only behaviour and serve
    # equipment-mismatched suggestions (the bug we're fixing).
    user_equipment_resolved = body.user_equipment
    if user_equipment_resolved is None:
        try:
            from api.v1.workouts.utils import parse_json_field
            db = get_supabase_db()
            user_row = db.client.table("users").select("equipment").eq(
                "id", body.user_id
            ).limit(1).execute()
            if user_row.data:
                user_equipment_resolved = parse_json_field(
                    user_row.data[0].get("equipment"), []
                )
                logger.info(
                    f"[Suggest] Loaded user_equipment from DB: {user_equipment_resolved}"
                )
        except Exception as e:
            logger.warning(f"[Suggest] Failed to load user_equipment: {e}")
            # Leave as None so the search node falls back to old behaviour.

    try:
        graph = get_suggestion_graph()

        # Build initial state
        initial_state: ExerciseSuggestionState = {
            "user_id": body.user_id,
            "user_message": body.message,
            "current_exercise": body.current_exercise.model_dump(),
            "user_equipment": user_equipment_resolved,
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
        logger.error(f"Exercise suggestion failed: {e}", exc_info=True)
        raise safe_internal_error(e, "exercise_suggestions")


# ==================== Fast Suggestion Endpoint ====================

class FastSuggestionRequest(BaseModel):
    """Request for fast database-based suggestions (no AI)."""
    exercise_name: str
    user_id: str
    avoided_exercises: Optional[List[str]] = None
    # User's configured equipment list. When None, the endpoint loads it
    # from the users row server-side. When provided as an empty list, it
    # means "no equipment" → bodyweight-only filtering.
    user_equipment: Optional[List[str]] = None


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


class FastSuggestionsResponse(BaseModel):
    """Wrapped response with typed empty_reason for honest client copy.

    Replaces the legacy bare-list response. The frontend Similar tab
    branches its empty-state copy on `empty_reason` so it can say what
    actually happened ("we couldn't find this exercise" vs "no
    equipment-compatible alternatives") rather than the previous
    misleading blanket "no exercises match this muscle group".
    """
    suggestions: List[FastExerciseSuggestion]
    empty_reason: Optional[str] = None  # 'exercise_not_found' | 'filtered_out' | 'no_match' | None when results found


@router.post("/suggest-fast", response_model=FastSuggestionsResponse)
async def get_fast_exercise_suggestions(body: FastSuggestionRequest, current_user: dict = Depends(get_current_user)):
    """
    Get exercise suggestions using fast database queries (no AI).
    Returns 8 similar exercises based on muscle group and equipment.

    This endpoint is ~20x faster than /suggest (~500ms vs ~10s) because
    it uses direct database queries instead of AI analysis.
    """
    if str(current_user["id"]) != str(body.user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    import random

    logger.info(f"Fast suggestion request for: {body.exercise_name}")

    try:
        db = get_supabase_db()

        # Server-side fallback for user_equipment when client didn't pass it.
        # Without this, the suspension-trainer leak resurfaces for any client
        # that forgets to send the field.
        user_equipment_resolved = body.user_equipment
        if user_equipment_resolved is None:
            try:
                from api.v1.workouts.utils import parse_json_field
                user_row = db.client.table("users").select("equipment").eq(
                    "id", body.user_id
                ).limit(1).execute()
                if user_row.data:
                    user_equipment_resolved = parse_json_field(
                        user_row.data[0].get("equipment"), []
                    )
                    logger.info(
                        f"[Suggest-Fast] Loaded user_equipment from DB: "
                        f"{user_equipment_resolved}"
                    )
            except Exception as e:
                logger.warning(
                    f"[Suggest-Fast] Failed to load user_equipment: {e}"
                )

        # Resolve exercise name through exact → substring → singular
        # normalization → pg_trgm fuzzy. Cached in-process.
        current_ex = await _resolve_exercise_name(db, body.exercise_name)

        if not current_ex:
            logger.warning(f"Exercise not found: {body.exercise_name}")
            # Honest empty_reason so the frontend can say "we couldn't find
            # this exercise in our library" instead of misleading "no
            # exercises match this muscle group".
            return FastSuggestionsResponse(
                suggestions=[],
                empty_reason="exercise_not_found",
            )
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
            return FastSuggestionsResponse(
                suggestions=[],
                empty_reason="no_match",
            )

        # Filter out avoided exercises
        avoided_lower = set((body.avoided_exercises or []))
        avoided_lower = {ex.lower() for ex in avoided_lower}

        candidates = [
            ex for ex in result.data
            if ex["name"].lower() not in avoided_lower
        ]

        # Equipment filter: drop candidates the user can't actually do.
        # `user_equipment_resolved is None` means we didn't get a value from
        # the client AND couldn't load one server-side — fall through to
        # legacy behaviour (no filter) rather than wrongly hiding everything.
        # Empty list = "no equipment" → bodyweight-only (the hardened filter
        # handles that case).
        had_candidates_before_equipment_filter = len(candidates) > 0
        if user_equipment_resolved is not None and candidates:
            from services.exercise_rag.filters import filter_by_equipment
            candidates = [
                ex for ex in candidates
                if filter_by_equipment(
                    ex.get("equipment") or "",
                    user_equipment_resolved,
                    ex.get("name") or "",
                )
            ]
            logger.info(
                f"[Suggest-Fast] Equipment filter: "
                f"{len(result.data)} → {len(candidates)} for "
                f"user_equipment={user_equipment_resolved}"
            )

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

        # Honest empty_reason: 'filtered_out' when we had candidates from the
        # DB but the user's equipment filter eliminated every one (e.g. a
        # bodyweight user swapping a barbell row — there's nothing in the
        # library tagged for what they can do). 'no_match' when the muscle
        # query itself returned nothing.
        if not suggestions and had_candidates_before_equipment_filter:
            empty_reason = "filtered_out"
        elif not suggestions:
            empty_reason = "no_match"
        else:
            empty_reason = None

        logger.info(
            f"Returning {len(suggestions)} fast suggestions "
            f"(empty_reason={empty_reason})"
        )
        return FastSuggestionsResponse(
            suggestions=suggestions,
            empty_reason=empty_reason,
        )

    except Exception as e:
        logger.error(f"Fast suggestion failed: {e}", exc_info=True)
        raise safe_internal_error(e, "exercise_suggestions")
