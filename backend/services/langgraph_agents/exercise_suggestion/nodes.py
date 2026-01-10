"""
Node implementations for the Exercise Suggestion LangGraph agent.

Uses ChromaDB (via ExerciseRAGService) for semantic search of exercises.
"""
import json
from typing import Dict, Any, List

from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.messages import HumanMessage, SystemMessage

from .state import ExerciseSuggestionState
from core.config import get_settings
from core.logger import get_logger
from core.supabase_db import get_supabase_db
from services.exercise_rag_service import get_exercise_rag_service
from services.gemini_service import GeminiService

logger = get_logger(__name__)
settings = get_settings()


def normalize_body_part(target_muscle: str) -> str:
    """Normalize target_muscle to a simple body part category."""
    if not target_muscle:
        return "Other"

    target_lower = target_muscle.lower()

    if any(x in target_lower for x in ["chest", "pectoralis"]):
        return "Chest"
    elif any(x in target_lower for x in ["back", "latissimus", "rhomboid", "trapezius"]):
        return "Back"
    elif any(x in target_lower for x in ["shoulder", "deltoid"]):
        return "Shoulders"
    elif any(x in target_lower for x in ["bicep", "brachii"]):
        return "Biceps"
    elif any(x in target_lower for x in ["tricep"]):
        return "Triceps"
    elif any(x in target_lower for x in ["forearm", "wrist"]):
        return "Forearms"
    elif any(x in target_lower for x in ["quad", "thigh"]):
        return "Quadriceps"
    elif any(x in target_lower for x in ["hamstring"]):
        return "Hamstrings"
    elif any(x in target_lower for x in ["glute"]):
        return "Glutes"
    elif any(x in target_lower for x in ["calf", "gastrocnemius", "soleus"]):
        return "Calves"
    elif any(x in target_lower for x in ["abdominal", "rectus abdominis", "core", "oblique"]):
        return "Core"
    elif any(x in target_lower for x in ["lower back", "erector"]):
        return "Lower Back"
    elif any(x in target_lower for x in ["hip", "adduct", "abduct"]):
        return "Hips"
    elif any(x in target_lower for x in ["neck"]):
        return "Neck"
    else:
        return "Other"


async def analyze_request_node(state: ExerciseSuggestionState) -> Dict[str, Any]:
    """
    Analyze user's swap request to understand why they want to swap.
    Uses AI to extract:
    - swap_reason (equipment, injury, difficulty, variety, etc.)
    - equipment_constraint
    - difficulty_preference
    """
    logger.info(f"[Analyze Node] Analyzing request: {state['user_message'][:50]}...")

    current_exercise = state.get("current_exercise", {})
    user_message = state.get("user_message", "")

    llm = ChatGoogleGenerativeAI(
        model=settings.gemini_model,
        temperature=0,
        google_api_key=settings.gemini_api_key,
    )

    system_prompt = """You are an exercise analysis assistant. Analyze the user's request to swap an exercise.

Extract the following information as JSON:
{{
    "swap_reason": "equipment" | "injury" | "difficulty" | "variety" | "preference" | "other",
    "equipment_constraint": ["list of equipment user mentioned they have or don't have"] or null,
    "difficulty_preference": "easier" | "similar" | "harder" | null,
    "target_muscle_group": "the muscle group the replacement should target" or null
}}

Current exercise: {exercise_name}
Current muscle group: {muscle_group}
Current equipment: {equipment}

Respond ONLY with valid JSON, no explanations."""

    messages = [
        SystemMessage(content=system_prompt.format(
            exercise_name=current_exercise.get("name", "unknown"),
            muscle_group=current_exercise.get("muscle_group", "unknown"),
            equipment=current_exercise.get("equipment", "none"),
        )),
        HumanMessage(content=user_message),
    ]

    try:
        response = await llm.ainvoke(messages)
        content = response.content.strip()
        logger.info(f"[Analyze Node] Raw GPT response: {content[:200]}...")

        # Parse JSON response - extract just the JSON object
        # Find the first { and last } to extract the JSON
        start_idx = content.find("{")
        end_idx = content.rfind("}") + 1
        if start_idx != -1 and end_idx > start_idx:
            content = content[start_idx:end_idx]

        analysis = json.loads(content)
        logger.info(f"[Analyze Node] Analysis result: {analysis}")

        # Get muscle group from current exercise if not specified
        target_muscle = analysis.get("target_muscle_group")
        if not target_muscle:
            target_muscle = current_exercise.get("muscle_group") or current_exercise.get("target_muscles", [None])[0]

        return {
            "swap_reason": analysis.get("swap_reason", "variety"),
            "equipment_constraint": analysis.get("equipment_constraint"),
            "difficulty_preference": analysis.get("difficulty_preference"),
            "target_muscle_group": target_muscle,
        }
    except Exception as e:
        logger.error(f"[Analyze Node] Error: {e}")
        # Default analysis
        return {
            "swap_reason": "variety",
            "equipment_constraint": None,
            "difficulty_preference": "similar",
            "target_muscle_group": current_exercise.get("muscle_group"),
        }


async def search_exercises_node(state: ExerciseSuggestionState) -> Dict[str, Any]:
    """
    Search the exercise library for candidate exercises using ChromaDB semantic search.
    Uses the ExerciseRAGService for vector similarity search.
    """
    logger.info("[Search Node] Searching exercise library via ChromaDB...")

    target_muscle = state.get("target_muscle_group", "")
    equipment_constraint = state.get("equipment_constraint", [])
    current_exercise = state.get("current_exercise", {})
    current_name = current_exercise.get("name", "").lower()
    user_message = state.get("user_message", "")
    swap_reason = state.get("swap_reason", "variety")
    user_equipment = state.get("user_equipment", [])
    avoided_exercises = state.get("avoided_exercises", []) or []
    # Normalize avoided exercises to lowercase for case-insensitive matching
    avoided_exercises_lower = {ex.lower() for ex in avoided_exercises}

    try:
        # Get the RAG service (uses ChromaDB)
        rag_service = get_exercise_rag_service()
        gemini_service = GeminiService()

        # Build a semantic search query based on user's request
        search_parts = []

        # Include the current exercise context
        if current_exercise.get("name"):
            search_parts.append(f"Alternative to {current_exercise.get('name')}")

        # Include target muscle
        if target_muscle:
            search_parts.append(f"Target muscle: {target_muscle}")

        # Include user's message for context
        if user_message:
            search_parts.append(user_message)

        # Include swap reason context
        reason_context = {
            "equipment": "exercises with different equipment",
            "injury": "safe exercises that avoid injury",
            "difficulty": "exercises with different difficulty level",
            "variety": "different exercises for variety",
            "preference": "alternative exercises",
        }
        if swap_reason in reason_context:
            search_parts.append(reason_context[swap_reason])

        search_query = " ".join(search_parts)
        logger.info(f"[Search Node] Semantic search query: {search_query[:100]}...")

        # Get embedding for the search query (use async version)
        query_embedding = await gemini_service.get_embedding_async(search_query)

        # Search ChromaDB for similar exercises
        results = rag_service.collection.query(
            query_embeddings=[query_embedding],
            n_results=50,  # Get more to filter
            include=["documents", "metadatas", "distances"],
        )

        if not results["ids"][0]:
            logger.warning("[Search Node] No exercises found in ChromaDB")
            return {"candidate_exercises": []}

        # Process results and filter
        raw_candidates = []
        seen_names: set = set()

        for i, doc_id in enumerate(results["ids"][0]):
            meta = results["metadatas"][0][i]
            distance = results["distances"][0][i]
            # Cosine distance: 0-2 range, convert to similarity 0-1
            similarity = 1 - (distance / 2)

            exercise_name = meta.get("name", "Unknown")

            # Skip the current exercise
            if exercise_name.lower() == current_name:
                continue

            # Case-insensitive deduplication
            lower_name = exercise_name.lower()
            if lower_name in seen_names:
                continue
            seen_names.add(lower_name)

            # Skip avoided exercises (from user preferences)
            if lower_name in avoided_exercises_lower:
                logger.debug(f"[Search Node] Skipping avoided exercise: {exercise_name}")
                continue

            # Get normalized body part
            body_part = normalize_body_part(meta.get("target_muscle") or meta.get("body_part", ""))

            # Filter by target muscle if specified
            if target_muscle:
                target_normalized = normalize_body_part(target_muscle)
                if body_part.lower() != target_normalized.lower():
                    continue

            # Filter by equipment constraints
            exercise_equipment = (meta.get("equipment") or "").lower()
            if equipment_constraint:
                skip = False
                for eq in equipment_constraint:
                    eq_lower = eq.lower()
                    if "no " in eq_lower or "don't have" in eq_lower or "without" in eq_lower:
                        forbidden_eq = eq_lower.replace("no ", "").replace("don't have ", "").replace("without ", "").strip()
                        if forbidden_eq in exercise_equipment:
                            skip = True
                            break
                if skip:
                    continue

            raw_candidates.append({
                "id": meta.get("exercise_id", ""),
                "name": exercise_name,
                "body_part": body_part,
                "equipment": meta.get("equipment"),
                "target_muscle": meta.get("target_muscle"),
                "instructions": meta.get("instructions", ""),
                "difficulty_level": meta.get("difficulty", "intermediate"),
                "similarity": similarity,
            })

        # Sort by similarity score
        raw_candidates.sort(key=lambda x: x.get("similarity", 0), reverse=True)

        logger.info(f"[Search Node] Found {len(raw_candidates)} candidate exercises from ChromaDB (deduplicated)")

        # Limit candidates for AI processing
        return {"candidate_exercises": raw_candidates[:30]}

    except Exception as e:
        logger.error(f"[Search Node] Error: {e}")
        return {"candidate_exercises": [], "error": str(e)}


async def generate_suggestions_node(state: ExerciseSuggestionState) -> Dict[str, Any]:
    """
    Use AI to rank candidates and generate personalized suggestions with reasons.
    """
    logger.info("[Generate Node] Generating AI suggestions...")

    candidates = state.get("candidate_exercises", [])
    current_exercise = state.get("current_exercise", {})
    user_message = state.get("user_message", "")
    swap_reason = state.get("swap_reason", "variety")
    user_injuries = state.get("user_injuries", [])
    user_fitness_level = state.get("user_fitness_level", "intermediate")

    if not candidates:
        return {
            "suggestions": [],
            "response_message": "I couldn't find any suitable alternatives in the exercise library. Try browsing manually or adjusting your preferences.",
        }

    llm = ChatGoogleGenerativeAI(
        model=settings.gemini_model,
        temperature=0.3,
        google_api_key=settings.gemini_api_key,
    )

    # Format candidates for AI
    candidates_text = "\n".join([
        f"- {c['name']} (Equipment: {c.get('equipment', 'none')}, Muscle: {c.get('body_part', 'unknown')})"
        for c in candidates[:20]
    ])

    system_prompt = f"""You are an expert fitness coach helping a user find alternative exercises.

CURRENT EXERCISE: {current_exercise.get('name', 'unknown')}
- Sets: {current_exercise.get('sets', 3)}
- Reps: {current_exercise.get('reps', 10)}
- Muscle Group: {current_exercise.get('muscle_group', 'unknown')}
- Equipment: {current_exercise.get('equipment', 'none')}

USER'S REQUEST: {user_message}
SWAP REASON: {swap_reason}
USER FITNESS LEVEL: {user_fitness_level}
USER INJURIES: {', '.join(user_injuries) if user_injuries else 'None reported'}

AVAILABLE ALTERNATIVES:
{candidates_text}

Select the TOP 5 best alternatives from the list above. For each, provide:
1. The exact exercise name (must match one from the list)
2. A brief reason why it's a good alternative (1-2 sentences)
3. Any modifications or tips

Respond in this JSON format:
{{
    "suggestions": [
        {{
            "name": "Exercise Name",
            "reason": "Why this is a good alternative",
            "tip": "Optional tip or modification"
        }}
    ],
    "message": "A friendly response to the user explaining your recommendations"
}}

IMPORTANT: Only suggest exercises from the provided list. Match names exactly."""

    try:
        response = await llm.ainvoke([
            SystemMessage(content=system_prompt),
            HumanMessage(content="Please suggest the best alternatives."),
        ])

        content = response.content.strip()

        # Parse JSON response - handle code blocks robustly
        if "```" in content:
            # Extract content between code blocks
            parts = content.split("```")
            for part in parts:
                part = part.strip()
                if part.startswith("json"):
                    part = part[4:].strip()
                if part.startswith("{"):
                    content = part
                    break

        # Find the JSON object
        start_idx = content.find("{")
        end_idx = content.rfind("}") + 1
        if start_idx != -1 and end_idx > start_idx:
            content = content[start_idx:end_idx]

        result = json.loads(content)

        suggestions = result.get("suggestions", [])
        message = result.get("message", "Here are some alternative exercises for you:")

        # Enrich suggestions with full exercise data
        enriched_suggestions = []
        for suggestion in suggestions[:5]:
            suggested_name = suggestion.get("name", "").lower()
            # Find matching candidate
            for candidate in candidates:
                if candidate.get("name", "").lower() == suggested_name:
                    enriched_suggestions.append({
                        **candidate,
                        "reason": suggestion.get("reason", ""),
                        "tip": suggestion.get("tip", ""),
                    })
                    break

        # Lookup gif_urls from Supabase for the suggestions
        try:
            db = get_supabase_db()
            suggestion_names = [s.get("name") for s in enriched_suggestions if s.get("name")]
            if suggestion_names:
                # Query the exercise library for gif_urls
                result = db.client.table("exercise_library_cleaned").select("name, gif_url").in_("name", suggestion_names).execute()
                if result.data:
                    gif_map = {row["name"].lower(): row.get("gif_url") for row in result.data}
                    for s in enriched_suggestions:
                        s["gif_url"] = gif_map.get(s.get("name", "").lower())
                    logger.info(f"[Generate Node] Added gif_urls for {len(gif_map)} exercises")
        except Exception as e:
            logger.warning(f"[Generate Node] Could not fetch gif_urls: {e}")

        logger.info(f"[Generate Node] Generated {len(enriched_suggestions)} suggestions")

        return {
            "suggestions": enriched_suggestions,
            "response_message": message,
        }

    except Exception as e:
        logger.error(f"[Generate Node] Error generating AI suggestions: {e}")
        # Fallback: return top candidates without AI ranking
        fallback_suggestions = []
        for candidate in candidates[:5]:
            fallback_suggestions.append({
                **candidate,
                "reason": f"Similar exercise targeting the same muscle group ({candidate.get('body_part', 'unknown')})",
                "tip": "This exercise was selected based on similarity to your current exercise.",
            })
        logger.warning(f"[Generate Node] Returning {len(fallback_suggestions)} fallback suggestions")
        return {
            "suggestions": fallback_suggestions,
            "response_message": "Here are some alternative exercises based on similarity:",
        }
