"""
State schema for the Workout Insights LangGraph agent.
Generates structured, easy-to-read insights with formatting.
"""
from typing import TypedDict, List, Dict, Any, Optional


class InsightSection(TypedDict):
    """A single insight section with title and content."""
    icon: str  # Emoji icon for the section
    title: str  # Bold title
    content: str  # Short content (1-2 sentences max)
    color: str  # Color hint: "cyan", "purple", "orange", "green"


class WorkoutInsightsState(TypedDict):
    """
    State for the workout insights agent.
    """
    # Input
    workout_id: str
    workout_name: str
    exercises: List[Dict[str, Any]]
    duration_minutes: Optional[int]
    workout_type: Optional[str]
    difficulty: Optional[str]

    # User context
    user_goals: Optional[List[str]]
    fitness_level: Optional[str]

    # Analysis results
    target_muscles: List[str]
    exercise_count: int
    total_sets: int
    workout_focus: Optional[str]  # e.g., "upper body", "full body", "leg day"

    # Structured Output
    headline: str  # One-liner motivational headline
    sections: List[InsightSection]  # 3-4 short insight sections

    # Legacy output (for backwards compatibility)
    summary: str  # JSON string of structured insights

    # Error handling
    error: Optional[str]
