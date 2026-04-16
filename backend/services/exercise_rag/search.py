"""
Search query building for exercise RAG.

Includes support for custom user goals with AI-generated keywords.
Also includes helpers to merge results from the `exercise_library` and
`custom_exercise_library` ChromaDB collections.
"""

from typing import Any, Dict, List, Optional

from core.logger import get_logger
from services.training_program_service import get_training_program_keywords_sync

logger = get_logger(__name__)


def merge_library_and_custom_results(
    library_results: Dict[str, Any],
    custom_results: Dict[str, Any],
    top_n: int,
) -> Dict[str, Any]:
    """
    Merge ChromaDB query results from `exercise_library` and `custom_exercise_library`.

    Results are combined and re-sorted by distance ascending (lower = more similar),
    then truncated to `top_n`. Preserves the ChromaDB result shape:
      { "ids": [[...]], "metadatas": [[...]], "distances": [[...]], "documents": [[...]] }

    Args:
        library_results: Result dict from `collection.query(...)` on exercise_library.
        custom_results:  Result dict from `custom_collection.query(...)` filtered by user.
        top_n:           Max number of merged results to return.

    Returns:
        Merged ChromaDB-shaped result dict.
    """
    def _safe_first(result: Dict[str, Any], key: str) -> List[Any]:
        v = result.get(key) if result else None
        if not v:
            return []
        if isinstance(v, list) and v and isinstance(v[0], list):
            return v[0]
        return v

    lib_ids = _safe_first(library_results, "ids")
    lib_meta = _safe_first(library_results, "metadatas")
    lib_dist = _safe_first(library_results, "distances")
    lib_docs = _safe_first(library_results, "documents")

    cust_ids = _safe_first(custom_results, "ids")
    cust_meta = _safe_first(custom_results, "metadatas")
    cust_dist = _safe_first(custom_results, "distances")
    cust_docs = _safe_first(custom_results, "documents")

    combined: List[Dict[str, Any]] = []
    for i, _id in enumerate(lib_ids):
        combined.append({
            "id": _id,
            "meta": lib_meta[i] if i < len(lib_meta) else {},
            "distance": lib_dist[i] if i < len(lib_dist) else 2.0,
            "document": lib_docs[i] if i < len(lib_docs) else "",
        })
    for i, _id in enumerate(cust_ids):
        m = cust_meta[i] if i < len(cust_meta) else {}
        # Ensure is_custom flag is present on custom-collection items even if the
        # metadata was partially populated.
        if "is_custom" not in m:
            m = {**m, "is_custom": "true"}
        combined.append({
            "id": _id,
            "meta": m,
            "distance": cust_dist[i] if i < len(cust_dist) else 2.0,
            "document": cust_docs[i] if i < len(cust_docs) else "",
        })

    # Lower distance = closer match. Sort ascending.
    combined.sort(key=lambda x: x["distance"])
    combined = combined[:top_n]

    return {
        "ids": [[c["id"] for c in combined]],
        "metadatas": [[c["meta"] for c in combined]],
        "distances": [[c["distance"] for c in combined]],
        "documents": [[c["document"] for c in combined]],
    }


# Focus area keywords for semantic search
FOCUS_AREA_KEYWORDS = {
    # Full body variations
    "full_body_push": "full body workout emphasis on push movements chest shoulders triceps pressing",
    "full_body_pull": "full body workout emphasis on pull movements back biceps rowing pulling",
    "full_body_legs": "full body workout emphasis on legs lower body squats lunges glutes hamstrings",
    "full_body_core": "full body workout emphasis on core abs stability planks",
    "full_body_upper": "full body workout upper body focus chest back shoulders arms",
    "full_body_lower": "full body workout lower body focus legs glutes quads hamstrings calves",
    "full_body_power": "full body workout power explosive movements plyometrics jumps",
    "full_body": "full body balanced workout compound exercises barbell dumbbell cable machine kettlebell strength training",

    # Upper/Lower split focus areas
    "upper": "upper body workout chest back shoulders arms biceps triceps pressing pulling rows",
    "lower": "lower body workout legs glutes quadriceps hamstrings calves squats lunges deadlifts",

    # Push/Pull/Legs (PPL) split focus areas
    "push": "push workout chest shoulders triceps bench press overhead press dips pushing movements",
    "pull": "pull workout back biceps rows pull-ups chin-ups lat pulldown pulling movements",
    "legs": "legs workout quadriceps hamstrings glutes calves squats lunges leg press deadlifts",

    # PHUL (Power Hypertrophy Upper Lower) focus areas
    "upper_power": "upper body power heavy compound movements bench press barbell rows overhead press weighted dips strength",
    "lower_power": "lower body power heavy compound movements squats deadlifts power cleans leg press strength",
    "upper_hypertrophy": "upper body hypertrophy higher reps muscle building chest back shoulders arms isolation exercises",
    "lower_hypertrophy": "lower body hypertrophy higher reps muscle building legs glutes quad hamstring isolation exercises",

    # Arnold Split focus areas
    "chest_back": "chest and back workout antagonist pairing bench press rows flyes pulldowns compound movements",
    "shoulders_arms": "shoulders and arms workout deltoids biceps triceps overhead press curls extensions",

    # Bro Split / Body Part focus areas
    "chest": "chest workout pectorals bench press incline decline flyes dips pressing movements",
    "back": "back workout lats rhomboids traps rows pulldowns pull-ups deadlifts pulling movements",
    "shoulders": "shoulders workout deltoids front side rear overhead press lateral raises face pulls",
    "arms": "arms workout biceps triceps curls extensions dips chin-ups isolation movements",
    "core_cardio": "core and cardio workout abs obliques planks crunches conditioning metabolic",

    # HYROX focus areas
    "hyrox_strength": "hyrox strength training sled push sled pull farmers carry sandbag exercises functional strength",
    "hyrox_running": "hyrox running intervals zone 2 compromised running aerobic base building endurance",
    "hyrox_stations": "hyrox stations ski erg rowing wall balls burpee broad jumps functional fitness conditioning",
    "hyrox_endurance": "hyrox endurance long aerobic work functional conditioning sustained effort stamina",
    "hyrox_simulation": "hyrox race simulation run station transitions competition preparation race pace",

    # Sport-specific workout types
    "boxing": "boxing workout punching power jab cross hook uppercut footwork conditioning cardio core rotation speed agility combat",
    "hyrox": "hyrox workout functional fitness running lunges burpees rowing sled push farmer carry wall balls ski erg endurance strength hybrid competition",
    "crossfit": "crossfit wod functional movements olympic lifts thrusters pull-ups box jumps kettlebell swings burpees muscle-ups high intensity amrap emom",
    "martial_arts": "martial arts mma grappling striking takedowns conditioning explosive power kicks punches combat training",
    "hiit": "hiit high intensity interval training cardio burpees jumping jacks mountain climbers explosive movements metabolic conditioning",
    "strength": "strength training heavy compound exercises squat deadlift bench press overhead press powerlifting maximal strength",
    "endurance": "endurance stamina cardio running cycling sustained effort aerobic conditioning long duration",
    "flexibility": "flexibility stretching yoga mobility range of motion static stretches dynamic stretches",
    "mobility": "mobility joint health functional movement dynamic stretching foam rolling warm-up activation",

    # Power and Plyometric training
    "plyometrics": "plyometric exercises explosive power jump training box jumps squat jumps depth jumps bounding hops reactive strength power development",
    "power": "explosive power training Olympic lifts power cleans snatches jump squats medicine ball throws plyometrics speed strength rate of force development",
    "vertical_jump": "vertical jump training box jumps depth jumps squat jumps countermovement jumps plyometrics leg power explosive strength calf raises",
    "speed": "speed training sprints acceleration agility drills quick feet ladder drills explosive movements fast twitch muscle development",
    "explosiveness": "explosive movement training power plyometrics jumps medicine ball throws olympic lifts rapid force production athletic performance",

    # Ball sports
    "cricket": "cricket training rotational power batting bowling throwing shoulder stability agility sprints lateral movement core strength explosive power conditioning",
    "football": "football soccer training sprinting agility change direction lower body power endurance conditioning kicks",
    "basketball": "basketball training vertical jump explosive power lateral movement agility conditioning court sprints",
    "tennis": "tennis training lateral movement agility rotational power shoulder stability core conditioning footwork",
}

# Goal keywords for semantic search
GOAL_KEYWORDS = {
    "Build Muscle": "hypertrophy muscle building compound exercises",
    "Lose Weight": "fat burning high intensity metabolic exercises",
    "Increase Strength": "strength power heavy compound exercises",
    "Improve Endurance": "cardio endurance stamina exercises",
    "Flexibility": "stretching mobility flexibility exercises",
    "General Fitness": "functional fitness full body exercises",
}

# Custom program description keyword mappings
# Maps keywords in custom descriptions to focus areas for better RAG matching
CUSTOM_PROGRAM_KEYWORDS = {
    # Jump/Plyometric related
    "box jump": "plyometrics vertical_jump",
    "jump": "plyometrics vertical_jump power",
    "vertical jump": "vertical_jump plyometrics",
    "plyometric": "plyometrics power explosiveness",
    "explosive": "explosiveness power plyometrics",
    "power": "power explosiveness strength",

    # Sport-specific
    "hyrox": "hyrox",
    "marathon": "endurance",
    "running": "endurance speed",
    "sprint": "speed power explosiveness",
    "basketball": "basketball vertical_jump",
    "football": "football speed power",
    "soccer": "football endurance speed",
    "boxing": "boxing",
    "mma": "martial_arts",
    "tennis": "tennis",
    "cricket": "cricket",
    "crossfit": "crossfit",

    # Skill-specific
    "pull-up": "full_body_pull strength",
    "pullup": "full_body_pull strength",
    "pushup": "full_body_push strength",
    "push-up": "full_body_push strength",
    "deadlift": "strength full_body_pull",
    "squat": "strength full_body_legs",
    "bench": "strength full_body_push",

    # General
    "strength": "strength",
    "muscle": "strength",
    "endurance": "endurance",
    "speed": "speed",
    "agility": "speed",
    "flexibility": "flexibility mobility",
    "mobility": "mobility flexibility",
}


def extract_focus_areas_from_description(description: str) -> List[str]:
    """
    Extract relevant focus areas from a custom program description.

    Args:
        description: Custom program description like "Improve box jump height"

    Returns:
        List of focus area keywords to enhance RAG search
    """
    if not description:
        return []

    description_lower = description.lower()
    found_focuses = set()

    # Check for keyword matches (longer phrases first)
    sorted_keywords = sorted(CUSTOM_PROGRAM_KEYWORDS.keys(), key=len, reverse=True)

    for keyword in sorted_keywords:
        if keyword in description_lower:
            focus_areas = CUSTOM_PROGRAM_KEYWORDS[keyword].split()
            for focus in focus_areas:
                if focus in FOCUS_AREA_KEYWORDS:
                    found_focuses.add(focus)

    return list(found_focuses)


def build_search_query(
    focus_area: str,
    equipment: List[str],
    fitness_level: str,
    goals: List[str],
) -> str:
    """
    Build a semantic search query for exercises.

    Args:
        focus_area: Target body area or workout type
        equipment: Available equipment
        fitness_level: User's fitness level
        goals: User's fitness goals

    Returns:
        Semantic search query string
    """
    focus_query = FOCUS_AREA_KEYWORDS.get(focus_area, f"Exercises for {focus_area} workout")

    query_parts = [
        focus_query,
        f"Equipment: {', '.join(equipment) if equipment else 'bodyweight'}",
        f"Fitness level: {fitness_level}",
    ]

    # Add goal-specific terms
    training_program_keywords = get_training_program_keywords_sync()

    for goal in goals:
        if goal in GOAL_KEYWORDS:
            query_parts.append(GOAL_KEYWORDS[goal])
        # Check if goal matches a training program
        if goal in training_program_keywords:
            query_parts.append(training_program_keywords[goal])

    return " ".join(query_parts)


async def build_search_query_with_custom_goals(
    focus_area: str,
    equipment: List[str],
    fitness_level: str,
    goals: List[str],
    user_id: Optional[str] = None,
) -> str:
    """
    Build a semantic search query incorporating user's custom goals.

    This extends build_search_query to include:
    1. User's custom goal keywords from custom_goals table
    2. User's custom_program_description from preferences

    Args:
        focus_area: Target body area or workout type
        equipment: Available equipment
        fitness_level: User's fitness level
        goals: User's fitness goals
        user_id: User ID for fetching custom goal keywords (optional)

    Returns:
        Enhanced semantic search query with custom goal keywords
    """
    # Start with the base query
    base_query = build_search_query(focus_area, equipment, fitness_level, goals)

    # If no user_id, just return base query
    if not user_id:
        return base_query

    enhanced_parts = [base_query]

    # Get custom program description from user preferences
    try:
        from core.supabase_db import get_supabase_db
        db = get_supabase_db()
        user = db.get_user(user_id)
        if user:
            preferences = user.get("preferences", {})
            if isinstance(preferences, str):
                import json
                try:
                    preferences = json.loads(preferences)
                except json.JSONDecodeError:
                    preferences = {}

            custom_program_description = preferences.get("custom_program_description")
            if custom_program_description and custom_program_description.strip():
                # Extract relevant focus areas from the description
                extracted_focuses = extract_focus_areas_from_description(custom_program_description)

                if extracted_focuses:
                    # Add the focus area keywords to strongly influence RAG results
                    for focus in extracted_focuses:
                        if focus in FOCUS_AREA_KEYWORDS:
                            enhanced_parts.append(FOCUS_AREA_KEYWORDS[focus])
                    logger.info(f"Extracted focus areas from custom program: {extracted_focuses}")

                # Also add the raw description for semantic matching
                enhanced_parts.append(f"Custom training goal: {custom_program_description}")
                logger.debug(f"Added custom program description to query for user {user_id}")

    except Exception as e:
        logger.warning(f"Failed to get custom program description for user {user_id}: {e}", exc_info=True)

    # Get custom goal keywords (no Gemini call - reads from DB cache)
    try:
        from services.custom_goal_service import get_custom_goal_service
        custom_goal_service = get_custom_goal_service()
        custom_keywords = await custom_goal_service.get_combined_keywords(user_id)

        if custom_keywords:
            # Take top 10 keywords (weighted by priority, already sorted)
            top_keywords = custom_keywords[:10]
            enhanced_parts.append(f"Custom focus: {' '.join(top_keywords)}")
            logger.debug(f"Enhanced query with {len(top_keywords)} custom keywords for user {user_id}")

    except Exception as e:
        logger.warning(f"Failed to get custom goal keywords for user {user_id}: {e}", exc_info=True)

    final_query = " ".join(enhanced_parts)

    # Log the final RAG search query for debugging custom programs
    logger.info("=" * 60)
    logger.info(f"[RAG SEARCH QUERY] User: {user_id}")
    logger.info(f"Base focus area: {focus_area}")
    logger.info(f"FINAL QUERY: {final_query}")
    logger.info("=" * 60)

    return final_query
