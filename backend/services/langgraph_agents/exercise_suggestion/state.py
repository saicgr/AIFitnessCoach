"""
State schema for the Exercise Suggestion LangGraph agent.
"""
from typing import TypedDict, List, Dict, Any, Optional, Union


class ExerciseSuggestionState(TypedDict):
    """
    State for the exercise suggestion agent.
    """
    # Input
    user_id: Union[str, int]  # UUID from Supabase (string) or legacy int
    user_message: str  # User's request (e.g., "I don't have dumbbells")
    current_exercise: Dict[str, Any]  # Current exercise being swapped
    user_equipment: Optional[List[str]]  # User's available equipment
    user_injuries: Optional[List[str]]  # User's active injuries
    user_fitness_level: Optional[str]  # beginner/intermediate/advanced
    avoided_exercises: Optional[List[str]]  # User's avoided exercises (from preferences)

    # Analysis results
    swap_reason: Optional[str]  # Why user wants to swap (equipment, injury, difficulty, etc.)
    target_muscle_group: Optional[str]  # Muscle group to target
    equipment_constraint: Optional[List[str]]  # Equipment user has/doesn't have
    difficulty_preference: Optional[str]  # easier/similar/harder

    # Search results
    candidate_exercises: List[Dict[str, Any]]  # Exercises from library that match criteria

    # AI-generated suggestions
    suggestions: List[Dict[str, Any]]  # Final ranked suggestions with reasons
    response_message: str  # Natural language response to user

    # Error handling
    error: Optional[str]
