"""
LangGraph graph assembly for the Fitness Coach agent.

Uses proper LangGraph patterns:
- LLM with bound tools decides which tools to call
- Tool execution node
- Response generation after tools
"""
from langgraph.graph import StateGraph, START, END

from .state import FitnessCoachState
from .nodes import (
    intent_extractor_node,
    rag_context_node,
    should_use_tools,
    agent_node,
    tool_executor_node,
    response_after_tools_node,
    simple_response_node,
    storage_node,
    build_action_data_node,
)
from .onboarding import (
    OnboardingState,
    check_completion_node,
    onboarding_agent_node,
    extract_data_node,
    determine_next_step,
)
from core.logger import get_logger

logger = get_logger(__name__)


def check_for_tool_calls(state: FitnessCoachState) -> str:
    """
    After agent node, check if tools were called.
    """
    tool_calls = state.get("tool_calls", [])
    logger.info(f"[check_for_tool_calls] tool_calls = {tool_calls}")
    if tool_calls:
        logger.info(f"[check_for_tool_calls] -> execute_tools ({len(tool_calls)} tools)")
        return "execute_tools"
    else:
        logger.info("[check_for_tool_calls] -> finalize (no tools)")
        return "finalize"


def build_fitness_coach_graph():
    """
    Build and compile the fitness coach agent graph.

    PROPER LANGGRAPH FLOW:
        START
          ↓
        intent_extractor (classify intent)
          ↓
        rag_context (get similar past conversations)
          ↓
        router (should_use_tools)
          ├─→ agent (LLM with bound tools decides)
          │     ↓
          │   check_for_tool_calls
          │     ├─→ tool_executor → response_after_tools
          │     └─→ (no tools called)
          │                ↓
          └─→ simple_response (no tools needed)
                    ↓
              build_action_data
                    ↓
                 storage
                    ↓
                   END

    Key: The LLM with bound tools DECIDES which tools to call.
    No manual if/else logic - the AI is in control.
    """
    logger.info("Building fitness coach graph (with proper tool calling)...")

    # Create the graph with our state schema
    graph = StateGraph(FitnessCoachState)

    # Add nodes
    graph.add_node("intent_extractor", intent_extractor_node)
    graph.add_node("rag_context", rag_context_node)
    graph.add_node("agent", agent_node)
    graph.add_node("tool_executor", tool_executor_node)
    graph.add_node("response_after_tools", response_after_tools_node)
    graph.add_node("simple_response", simple_response_node)
    graph.add_node("build_action_data", build_action_data_node)
    graph.add_node("storage", storage_node)

    # Linear flow: START → intent → rag
    graph.add_edge(START, "intent_extractor")
    graph.add_edge("intent_extractor", "rag_context")

    # Conditional: should we use tools or just respond?
    graph.add_conditional_edges(
        "rag_context",
        should_use_tools,
        {
            "agent": "agent",
            "respond": "simple_response",
        }
    )

    # After agent, check if tools were called
    graph.add_conditional_edges(
        "agent",
        check_for_tool_calls,
        {
            "execute_tools": "tool_executor",
            "finalize": "build_action_data",
        }
    )

    # After tool execution, generate final response
    graph.add_edge("tool_executor", "response_after_tools")
    graph.add_edge("response_after_tools", "build_action_data")

    # Simple response goes directly to action data
    graph.add_edge("simple_response", "build_action_data")

    # Final flow
    graph.add_edge("build_action_data", "storage")
    graph.add_edge("storage", END)

    # Compile the graph
    compiled_graph = graph.compile()

    logger.info("Fitness coach graph built successfully (with proper tool calling)")

    return compiled_graph


def build_onboarding_agent_graph():
    """
    Build and compile the onboarding agent graph.

    AI-DRIVEN ONBOARDING FLOW (NO HARDCODED QUESTIONS):
        START
          ↓
        extract_data (extract data from user message using AI)
          ↓
        check_completion (determine what's missing)
          ↓
        router (determine_next_step)
          ├─→ ask_question (onboarding_agent generates next question)
          │     ↓
          │   (loops back to user input, then extract_data)
          │
          └─→ complete (onboarding finished)
                ↓
               END

    Key: The AI DECIDES what to ask based on missing data and context.
    No hardcoded question templates!
    """
    logger.info("Building onboarding agent graph (AI-driven, no hardcoded questions)...")

    # Create the graph with onboarding state schema
    graph = StateGraph(OnboardingState)

    # Add nodes
    graph.add_node("extract_data", extract_data_node)
    graph.add_node("check_completion", check_completion_node)
    graph.add_node("ask_question", onboarding_agent_node)

    # Linear flow: START → extract_data → check_completion
    graph.add_edge(START, "extract_data")
    graph.add_edge("extract_data", "check_completion")

    # Conditional: are we done or need more data?
    graph.add_conditional_edges(
        "check_completion",
        determine_next_step,
        {
            "ask_question": "ask_question",  # Need more data
            "complete": END,  # Onboarding complete
        }
    )

    # After asking question, we END and wait for user's next message
    # The next user message will start the flow again from START
    graph.add_edge("ask_question", END)

    # Compile the graph
    compiled_graph = graph.compile()

    logger.info("Onboarding agent graph built successfully (AI-driven)")

    return compiled_graph
