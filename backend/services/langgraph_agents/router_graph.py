"""
Multi-Agent Router Graph - LangGraph orchestration of domain agents.

This creates a hierarchical graph where:
1. Router analyzes the message and selects the appropriate agent
2. Selected agent processes the message
3. Response flows back through the router

         ┌──────────────────────────────────────────┐
         │              ROUTER GRAPH                │
         └──────────────────────────────────────────┘
                          │
                     ┌────┴────┐
                     │  START  │
                     └────┬────┘
                          │
                   ┌──────┴──────┐
                   │   extract   │  (intent extraction)
                   │   intent    │
                   └──────┬──────┘
                          │
                   ┌──────┴──────┐
                   │    route    │  (select agent)
                   └──────┬──────┘
                          │
         ┌────────┬───────┼───────┬────────┐
         ▼        ▼       ▼       ▼        ▼
    ┌─────────┐ ┌─────┐ ┌──────┐ ┌─────┐ ┌───────┐
    │Nutrition│ │Work-│ │Injury│ │Hydr-│ │ Coach │
    │  Agent  │ │ out │ │Agent │ │ation│ │ Agent │
    └────┬────┘ └──┬──┘ └──┬───┘ └──┬──┘ └───┬───┘
         │        │       │        │        │
         └────────┴───────┴────────┴────────┘
                          │
                   ┌──────┴──────┐
                   │   collect   │  (gather response)
                   └──────┬──────┘
                          │
                     ┌────┴────┐
                     │   END   │
                     └─────────┘
"""
import re
from typing import Dict, Any, Literal, TypedDict, List, Optional, Union

from langgraph.graph import StateGraph, START, END

from models.chat import CoachIntent, AgentType
from services.gemini_service import GeminiService
from services.rag_service import RAGService
from core.logger import get_logger

# Import domain agent graphs
from .nutrition_agent import build_nutrition_agent_graph
from .workout_agent import build_workout_agent_graph
from .injury_agent import build_injury_agent_graph
from .hydration_agent import build_hydration_agent_graph
from .coach_agent import build_coach_agent_graph
from .plan_agent import build_plan_agent_graph

logger = get_logger(__name__)


class RouterState(TypedDict):
    """State for the multi-agent router."""
    # Input
    user_message: str
    user_id: Union[str, int]
    user_profile: Optional[Dict[str, Any]]
    current_workout: Optional[Dict[str, Any]]
    workout_schedule: Optional[Dict[str, Any]]
    conversation_history: List[Dict[str, str]]
    image_base64: Optional[str]
    ai_settings: Optional[Dict[str, Any]]  # AI personality settings including coach_name

    # Routing
    selected_agent: Optional[str]  # "nutrition", "workout", "injury", "hydration", "coach", "plan"
    mentioned_agent: Optional[str]

    # Intent extraction
    intent: Optional[CoachIntent]
    extraction_data: Dict[str, Any]

    # RAG
    rag_context: str
    rag_used: bool
    similar_questions: List[str]

    # Agent state (passed to/from selected agent)
    agent_state: Dict[str, Any]

    # Output
    final_response: str
    action_data: Optional[Dict[str, Any]]
    agent_type: Optional[AgentType]


# @mention patterns
AGENT_MENTION_PATTERNS = {
    r"@nutrition\b": "nutrition",
    r"@workout\b": "workout",
    r"@injury\b": "injury",
    r"@hydration\b": "hydration",
    r"@coach\b": "coach",
    r"@plan\b": "plan",
}

# Intent to agent mapping
INTENT_TO_AGENT = {
    CoachIntent.ANALYZE_FOOD: "nutrition",
    CoachIntent.NUTRITION_SUMMARY: "nutrition",
    CoachIntent.RECENT_MEALS: "nutrition",
    CoachIntent.ADD_EXERCISE: "workout",
    CoachIntent.REMOVE_EXERCISE: "workout",
    CoachIntent.SWAP_WORKOUT: "workout",
    CoachIntent.MODIFY_INTENSITY: "workout",
    CoachIntent.RESCHEDULE: "workout",
    CoachIntent.DELETE_WORKOUT: "workout",
    CoachIntent.START_WORKOUT: "workout",
    CoachIntent.COMPLETE_WORKOUT: "workout",
    CoachIntent.REPORT_INJURY: "injury",
    CoachIntent.LOG_HYDRATION: "hydration",
    CoachIntent.QUESTION: "coach",
    CoachIntent.CHANGE_SETTING: "coach",
    CoachIntent.NAVIGATE: "coach",
    CoachIntent.GENERATE_WEEKLY_PLAN: "plan",
    CoachIntent.ADJUST_PLAN: "plan",
    CoachIntent.EXPLAIN_PLAN: "plan",
}

# Keyword patterns for fallback routing
DOMAIN_KEYWORDS = {
    "nutrition": ["food", "eat", "meal", "calories", "protein", "carbs", "diet", "macros"],
    "workout": ["exercise", "workout", "training", "gym", "lift", "muscle", "sets", "reps"],
    "injury": ["hurt", "pain", "injury", "sore", "strain", "recovery", "rehab"],
    "hydration": ["water", "hydration", "drink", "thirsty", "glasses"],
    "plan": ["weekly plan", "full plan", "holistic plan", "plan my week", "create plan", "generate plan"],
}


def detect_mention(message: str) -> tuple[Optional[str], str]:
    """Detect @mention and return (agent_name, cleaned_message)."""
    for pattern, agent in AGENT_MENTION_PATTERNS.items():
        match = re.search(pattern, message, re.IGNORECASE)
        if match:
            cleaned = re.sub(pattern, "", message, flags=re.IGNORECASE).strip()
            return agent, cleaned
    return None, message


def infer_from_keywords(message: str) -> Optional[str]:
    """Infer agent from keywords."""
    message_lower = message.lower()
    scores = {}
    for agent, keywords in DOMAIN_KEYWORDS.items():
        scores[agent] = sum(1 for kw in keywords if kw in message_lower)
    if scores:
        best = max(scores, key=scores.get)
        if scores[best] > 0:
            return best
    return None


async def extract_intent_node(state: RouterState) -> Dict[str, Any]:
    """Extract intent and detect @mentions."""
    logger.info("[Router] Extracting intent...")

    message = state["user_message"]

    # Detect @mention
    mentioned, cleaned_message = detect_mention(message)

    # Extract intent using Gemini
    gemini_service = GeminiService()
    extraction = await gemini_service.extract_intent(cleaned_message)

    # Get RAG context
    rag_context = ""
    rag_used = False
    similar_questions = []
    try:
        rag_service = RAGService(gemini_service=gemini_service)
        similar_docs = await rag_service.find_similar(
            query=cleaned_message,
            user_id=state["user_id"],
            n_results=3
        )
        rag_context = rag_service.format_context(similar_docs)
        rag_used = len(similar_docs) > 0
        similar_questions = [doc.get("metadata", {}).get("question", "") for doc in similar_docs[:3]]
    except Exception as e:
        logger.warning(f"RAG failed: {e}")

    extraction_data = {
        "exercises": extraction.exercises,
        "muscle_groups": extraction.muscle_groups,
        "modification": extraction.modification,
        "body_part": extraction.body_part,
        "setting_name": extraction.setting_name,
        "setting_value": extraction.setting_value,
        "destination": extraction.destination,
        "hydration_amount": extraction.hydration_amount,
    }

    logger.info(f"[Router] Intent: {extraction.intent.value}, Mentioned: {mentioned}")

    return {
        "user_message": cleaned_message,  # Use cleaned message
        "mentioned_agent": mentioned,
        "intent": extraction.intent,
        "extraction_data": extraction_data,
        "rag_context": rag_context,
        "rag_used": rag_used,
        "similar_questions": similar_questions,
    }


def route_to_agent(state: RouterState) -> str:
    """Determine which agent to route to."""
    # Priority 1: @mention
    if state.get("mentioned_agent"):
        agent = state["mentioned_agent"]
        logger.info(f"[Router] @mention -> {agent}")
        return agent

    # Priority 2: Image -> nutrition
    if state.get("image_base64"):
        logger.info("[Router] Image -> nutrition")
        return "nutrition"

    # Priority 3: Intent
    intent = state.get("intent")
    if intent and intent in INTENT_TO_AGENT:
        agent = INTENT_TO_AGENT[intent]
        if agent != "coach":  # Only use if not default
            logger.info(f"[Router] Intent {intent.value} -> {agent}")
            return agent

    # Priority 4: Keywords
    keyword_agent = infer_from_keywords(state["user_message"])
    if keyword_agent:
        logger.info(f"[Router] Keywords -> {keyword_agent}")
        return keyword_agent

    # Default: coach
    logger.info("[Router] Default -> coach")
    return "coach"


def build_agent_state(state: RouterState, agent: str) -> Dict[str, Any]:
    """Build the state dict for the selected agent."""
    base = {
        "user_message": state["user_message"],
        "user_id": state["user_id"],
        "user_profile": state.get("user_profile"),
        "conversation_history": state.get("conversation_history", []),
        "intent": state.get("intent"),
        "rag_documents": [],
        "rag_context_formatted": state.get("rag_context", ""),
        "ai_response": "",
        "final_response": "",
        "action_data": None,
        "rag_context_used": state.get("rag_used", False),
        "similar_questions": state.get("similar_questions", []),
        "error": None,
        # AI personality settings (includes coach_name, coaching_style, etc.)
        "ai_settings": state.get("ai_settings"),
    }

    extraction = state.get("extraction_data", {})

    if agent == "nutrition":
        base["image_base64"] = state.get("image_base64")
        base["tool_calls"] = []
        base["tool_results"] = []
        base["tool_messages"] = []
        base["messages"] = []

    elif agent == "workout":
        base["current_workout"] = state.get("current_workout")
        base["workout_schedule"] = state.get("workout_schedule")
        base["extracted_exercises"] = extraction.get("exercises", [])
        base["extracted_muscle_groups"] = extraction.get("muscle_groups", [])
        base["modification"] = extraction.get("modification")
        base["tool_calls"] = []
        base["tool_results"] = []
        base["tool_messages"] = []
        base["messages"] = []

    elif agent == "injury":
        base["body_part"] = extraction.get("body_part")
        base["tool_calls"] = []
        base["tool_results"] = []
        base["tool_messages"] = []
        base["messages"] = []

    elif agent == "hydration":
        base["hydration_amount"] = extraction.get("hydration_amount")

    elif agent == "coach":
        base["current_workout"] = state.get("current_workout")
        base["workout_schedule"] = state.get("workout_schedule")
        base["setting_name"] = extraction.get("setting_name")
        base["setting_value"] = extraction.get("setting_value")
        base["destination"] = extraction.get("destination")

    elif agent == "plan":
        # Plan agent needs user profile for workout days, fasting, nutrition targets
        base["current_plan"] = None
        base["workout_days"] = []
        base["fasting_protocol"] = None
        base["nutrition_strategy"] = None
        base["nutrition_targets"] = None
        base["preferred_workout_time"] = None
        base["generated_plan"] = None
        base["daily_entries"] = []
        base["meal_suggestions"] = []
        base["coordination_notes"] = []
        base["tool_calls"] = []
        base["tool_results"] = []
        base["tool_messages"] = []
        base["messages"] = []

    return base


# Build individual agent graphs (compiled once)
_agent_graphs = None


def get_agent_graphs():
    """Lazy-load agent graphs."""
    global _agent_graphs
    if _agent_graphs is None:
        logger.info("[Router] Building agent graphs...")
        _agent_graphs = {
            "nutrition": build_nutrition_agent_graph(),
            "workout": build_workout_agent_graph(),
            "injury": build_injury_agent_graph(),
            "hydration": build_hydration_agent_graph(),
            "coach": build_coach_agent_graph(),
            "plan": build_plan_agent_graph(),
        }
        logger.info("[Router] All agent graphs built")
    return _agent_graphs


async def run_nutrition_agent(state: RouterState) -> Dict[str, Any]:
    """Run the nutrition agent."""
    logger.info("[Router] Running nutrition agent...")
    graphs = get_agent_graphs()
    agent_state = build_agent_state(state, "nutrition")
    result = await graphs["nutrition"].ainvoke(agent_state)
    return {
        "final_response": result.get("final_response", ""),
        "action_data": result.get("action_data"),
        "agent_type": AgentType.NUTRITION,
        "selected_agent": "nutrition",
    }


async def run_workout_agent(state: RouterState) -> Dict[str, Any]:
    """Run the workout agent."""
    logger.info("[Router] Running workout agent...")
    graphs = get_agent_graphs()
    agent_state = build_agent_state(state, "workout")
    result = await graphs["workout"].ainvoke(agent_state)
    return {
        "final_response": result.get("final_response", ""),
        "action_data": result.get("action_data"),
        "agent_type": AgentType.WORKOUT,
        "selected_agent": "workout",
    }


async def run_injury_agent(state: RouterState) -> Dict[str, Any]:
    """Run the injury agent."""
    logger.info("[Router] Running injury agent...")
    graphs = get_agent_graphs()
    agent_state = build_agent_state(state, "injury")
    result = await graphs["injury"].ainvoke(agent_state)
    return {
        "final_response": result.get("final_response", ""),
        "action_data": result.get("action_data"),
        "agent_type": AgentType.INJURY,
        "selected_agent": "injury",
    }


async def run_hydration_agent(state: RouterState) -> Dict[str, Any]:
    """Run the hydration agent."""
    logger.info("[Router] Running hydration agent...")
    graphs = get_agent_graphs()
    agent_state = build_agent_state(state, "hydration")
    result = await graphs["hydration"].ainvoke(agent_state)
    return {
        "final_response": result.get("final_response", ""),
        "action_data": result.get("action_data"),
        "agent_type": AgentType.HYDRATION,
        "selected_agent": "hydration",
    }


async def run_coach_agent(state: RouterState) -> Dict[str, Any]:
    """Run the coach agent."""
    logger.info("[Router] Running coach agent...")
    graphs = get_agent_graphs()
    agent_state = build_agent_state(state, "coach")
    result = await graphs["coach"].ainvoke(agent_state)
    return {
        "final_response": result.get("final_response", ""),
        "action_data": result.get("action_data"),
        "agent_type": AgentType.COACH,
        "selected_agent": "coach",
    }


async def run_plan_agent(state: RouterState) -> Dict[str, Any]:
    """Run the plan agent for holistic weekly planning."""
    logger.info("[Router] Running plan agent...")
    graphs = get_agent_graphs()
    agent_state = build_agent_state(state, "plan")
    result = await graphs["plan"].ainvoke(agent_state)
    return {
        "final_response": result.get("final_response", ""),
        "action_data": result.get("action_data"),
        "agent_type": AgentType.PLAN,
        "selected_agent": "plan",
    }


def build_router_graph():
    """
    Build the multi-agent router graph.

    This is a hierarchical graph that:
    1. Extracts intent from the message
    2. Routes to the appropriate domain agent
    3. Collects the response

    The domain agents are nested subgraphs.
    """
    logger.info("[Router] Building multi-agent router graph...")

    graph = StateGraph(RouterState)

    # Add nodes
    graph.add_node("extract_intent", extract_intent_node)
    graph.add_node("nutrition", run_nutrition_agent)
    graph.add_node("workout", run_workout_agent)
    graph.add_node("injury", run_injury_agent)
    graph.add_node("hydration", run_hydration_agent)
    graph.add_node("coach", run_coach_agent)
    graph.add_node("plan", run_plan_agent)

    # Flow: START -> extract_intent -> route to agent -> END
    graph.add_edge(START, "extract_intent")

    # Conditional routing based on agent selection
    graph.add_conditional_edges(
        "extract_intent",
        route_to_agent,
        {
            "nutrition": "nutrition",
            "workout": "workout",
            "injury": "injury",
            "hydration": "hydration",
            "coach": "coach",
            "plan": "plan",
        }
    )

    # All agents go to END
    graph.add_edge("nutrition", END)
    graph.add_edge("workout", END)
    graph.add_edge("injury", END)
    graph.add_edge("hydration", END)
    graph.add_edge("coach", END)
    graph.add_edge("plan", END)

    compiled = graph.compile()
    logger.info("[Router] Multi-agent router graph built successfully")

    return compiled
