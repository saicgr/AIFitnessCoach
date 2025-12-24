"""
Search query building for exercise RAG.
"""

from typing import List

from services.training_program_service import get_training_program_keywords_sync


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
    "full_body": "full body balanced workout compound exercises",

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
