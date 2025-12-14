"""
Node implementations for the Hydration Agent.

The hydration agent is primarily autonomous - it provides advice
and handles logging via action_data (no database tools).
"""
import re
from typing import Dict, Any, Literal

from .state import HydrationAgentState
from services.openai_service import OpenAIService
from models.chat import CoachIntent
from core.logger import get_logger

logger = get_logger(__name__)

# Hydration expertise system prompt
HYDRATION_SYSTEM_PROMPT = """You are Aqua, an expert AI hydration coach. You specialize in:
- Helping users track their water intake
- Providing personalized hydration recommendations
- Explaining the importance of hydration for fitness
- Advising on optimal hydration timing around workouts
- Suggesting ways to increase water consumption

PERSONALITY:
- Refreshing and upbeat
- Encouraging but not preachy
- Knowledgeable about hydration science
- Practical with real-world tips

HYDRATION FACTS:
- General guideline: 8 glasses (64 oz / ~2L) per day for average adults
- Active individuals: Add 16-24 oz (1-3 cups) for every hour of exercise
- Body weight method: Half your body weight in ounces (e.g., 160 lbs = 80 oz)
- Dehydration signs: Dark urine, headache, fatigue, muscle cramps
- Over-hydration is rare but possible - listen to your body

HYDRATION TIMING:
- Start day with 1-2 glasses
- Pre-workout: 16-20 oz 2-3 hours before
- During workout: 7-10 oz every 10-20 minutes
- Post-workout: 16-24 oz for every pound lost during exercise
- Before meals: 1 glass can help with portion control

TIPS TO DRINK MORE WATER:
- Carry a reusable water bottle
- Set reminders on your phone
- Add fruit for flavor (lemon, cucumber, berries)
- Drink a glass before each meal
- Eat water-rich foods (watermelon, cucumber, oranges)

CAPABILITIES:
1. **Log Hydration**: When user says they drank water, acknowledge it
2. **Provide Advice**: Answer questions about hydration
3. **Encourage**: Motivate users to stay hydrated
"""


def extract_hydration_amount(message: str) -> int:
    """Extract the number of glasses/cups from the message."""
    message_lower = message.lower()

    # Common patterns
    patterns = [
        r'(\d+)\s*(?:glasses?|cups?|waters?)',
        r'drank\s+(\d+)',
        r'had\s+(\d+)',
        r'logged?\s+(\d+)',
    ]

    for pattern in patterns:
        match = re.search(pattern, message_lower)
        if match:
            return int(match.group(1))

    # Check for word numbers
    word_numbers = {
        'one': 1, 'a glass': 1, 'a cup': 1,
        'two': 2, 'three': 3, 'four': 4, 'five': 5,
    }
    for word, num in word_numbers.items():
        if word in message_lower:
            return num

    # Default to 1 if talking about drinking but no number
    if any(kw in message_lower for kw in ['drank', 'had', 'drinking', 'just drank', 'finished']):
        return 1

    return 0


def should_log_hydration(state: HydrationAgentState) -> Literal["log", "respond"]:
    """
    Determine if user is logging hydration or asking a question.

    Routes to log if:
    - User says they drank water
    - User wants to log hydration

    Routes to respond for:
    - General hydration questions
    - Hydration advice
    """
    message = state.get("user_message", "").lower()
    intent = state.get("intent")

    # Logging keywords
    log_keywords = [
        "drank", "had", "just drank", "finished", "log water",
        "log hydration", "add water", "glasses", "cups of water"
    ]

    for keyword in log_keywords:
        if keyword in message:
            amount = extract_hydration_amount(message)
            if amount > 0:
                logger.info(f"[Hydration Router] Logging detected: {amount} glasses -> log")
                return "log"

    # Intent-based routing
    if intent == CoachIntent.LOG_HYDRATION:
        logger.info("[Hydration Router] LOG_HYDRATION intent -> log")
        return "log"

    # Default: respond with advice
    logger.info("[Hydration Router] General hydration query -> respond")
    return "respond"


async def hydration_log_node(state: HydrationAgentState) -> Dict[str, Any]:
    """
    Handle hydration logging and provide encouraging response.
    Logging is done via action_data (frontend handles DB update).
    """
    logger.info("[Hydration Log] Processing hydration log...")

    message = state.get("user_message", "")
    amount = state.get("hydration_amount") or extract_hydration_amount(message)

    if amount == 0:
        amount = 1  # Default to 1 glass

    openai_service = OpenAIService()

    context_parts = []

    if state.get("user_profile"):
        profile = state["user_profile"]
        context_parts.append(f"User fitness level: {profile.get('fitness_level', 'beginner')}")
        context_parts.append(f"User goals: {', '.join(profile.get('goals', []))}")

    context = "\n".join(context_parts)

    system_prompt = f"""{HYDRATION_SYSTEM_PROMPT}

CONTEXT:
{context}

The user just logged {amount} glass(es) of water. Respond with:
1. A brief acknowledgment (1-2 sentences)
2. An encouraging message
3. Optionally, a hydration tip or fun fact

Keep it short and refreshing! Don't be too long-winded."""

    conversation_history = [
        {"role": msg["role"], "content": msg["content"]}
        for msg in state.get("conversation_history", [])
    ]

    response = await openai_service.chat(
        user_message=state["user_message"],
        system_prompt=system_prompt,
        conversation_history=conversation_history,
    )

    logger.info(f"[Hydration Log] Response: {response[:100]}...")

    # Build action_data for frontend to log in database
    action_data = {
        "action": "log_hydration",
        "amount": amount,
        "success": True,
    }

    return {
        "ai_response": response,
        "final_response": response,
        "action_data": action_data,
        "hydration_amount": amount,
    }


async def hydration_advice_node(state: HydrationAgentState) -> Dict[str, Any]:
    """
    Provide hydration advice without logging.
    This is the autonomous reasoning capability.
    """
    logger.info("[Hydration Advice] Generating hydration advice...")

    openai_service = OpenAIService()

    context_parts = []

    if state.get("user_profile"):
        profile = state["user_profile"]
        context_parts.append(f"User fitness level: {profile.get('fitness_level', 'beginner')}")
        context_parts.append(f"User goals: {', '.join(profile.get('goals', []))}")

    if state.get("rag_context_formatted"):
        context_parts.append(f"\nPrevious context:\n{state['rag_context_formatted']}")

    context = "\n".join(context_parts)

    system_prompt = f"""{HYDRATION_SYSTEM_PROMPT}

CONTEXT:
{context}

You are responding to a hydration question. Provide helpful, personalized advice.
Be refreshing, upbeat, and practical!"""

    conversation_history = [
        {"role": msg["role"], "content": msg["content"]}
        for msg in state.get("conversation_history", [])
    ]

    response = await openai_service.chat(
        user_message=state["user_message"],
        system_prompt=system_prompt,
        conversation_history=conversation_history,
    )

    logger.info(f"[Hydration Advice] Response: {response[:100]}...")

    return {
        "ai_response": response,
        "final_response": response,
    }
