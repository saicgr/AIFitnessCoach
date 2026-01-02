"""
Node functions for the Plan Agent.

Handles:
- Weekly plan generation
- Nutrition target adjustments
- Fasting-workout coordination
- Meal suggestion generation
- Plan queries and modifications
"""
from typing import Dict, Any, Literal
from datetime import datetime, date, timedelta

from core.logger import get_logger
from services.gemini_service import gemini_service
from services.holistic_plan_service import HolisticPlanService
from models.chat import CoachIntent

from .state import PlanAgentState

logger = get_logger(__name__)

# Plan service instance
plan_service = HolisticPlanService()


def should_generate_plan(state: PlanAgentState) -> Literal["generate", "query", "modify", "respond"]:
    """
    Router: Determine what type of plan operation is needed.

    Routes to:
    - generate: Create a new weekly plan
    - query: Answer questions about existing plan
    - modify: Update or adjust existing plan
    - respond: General response (no plan operation needed)
    """
    intent = state.get("intent")
    user_message = state.get("user_message", "").lower()

    # Keywords for plan generation
    generate_keywords = [
        "create a plan", "generate plan", "make a plan", "new plan",
        "plan for next week", "weekly plan", "full plan", "holistic plan",
        "plan my week", "set up my plan"
    ]

    # Keywords for plan queries
    query_keywords = [
        "what's my plan", "show my plan", "my weekly plan",
        "what should i eat", "what workout", "today's plan",
        "what's tomorrow", "this week's plan"
    ]

    # Keywords for modifications
    modify_keywords = [
        "change my plan", "update plan", "adjust plan",
        "reschedule", "swap day", "different meal"
    ]

    # Check intent first
    if intent == CoachIntent.GENERATE_WEEKLY_PLAN:
        return "generate"
    elif intent == CoachIntent.ADJUST_PLAN:
        return "modify"
    elif intent == CoachIntent.EXPLAIN_PLAN:
        return "query"

    # Fall back to keyword matching
    for keyword in generate_keywords:
        if keyword in user_message:
            return "generate"

    for keyword in query_keywords:
        if keyword in user_message:
            return "query"

    for keyword in modify_keywords:
        if keyword in user_message:
            return "modify"

    return "respond"


async def plan_generate_node(state: PlanAgentState) -> Dict[str, Any]:
    """
    Generate a new weekly plan using AI.
    """
    logger.info("Plan Agent: Generating new weekly plan")

    user_id = state.get("user_id")
    user_profile = state.get("user_profile", {})

    # Get plan parameters from state or user profile
    workout_days = state.get("workout_days") or user_profile.get("workout_days", [0, 1, 3, 4])
    fasting_protocol = state.get("fasting_protocol") or user_profile.get("fasting_protocol", "16:8")
    nutrition_strategy = state.get("nutrition_strategy") or user_profile.get("nutrition_strategy", "workout_aware")
    preferred_workout_time = state.get("preferred_workout_time") or user_profile.get("preferred_workout_time", "17:00")

    # Get base nutrition targets
    nutrition_targets = state.get("nutrition_targets") or {
        "calories": user_profile.get("daily_calorie_target", 2000),
        "protein_g": user_profile.get("daily_protein_target_g", 150),
        "carbs_g": user_profile.get("daily_carbs_target_g", 200),
        "fat_g": user_profile.get("daily_fat_target_g", 65),
    }

    # Calculate week start (next Monday)
    today = date.today()
    days_until_monday = (7 - today.weekday()) % 7
    if days_until_monday == 0:
        days_until_monday = 7  # If today is Monday, use next Monday
    week_start = today + timedelta(days=days_until_monday)

    try:
        # Generate plan using Gemini
        generated_plan = await gemini_service.generate_weekly_holistic_plan(
            user_profile=user_profile,
            workout_days=workout_days,
            fasting_protocol=fasting_protocol,
            nutrition_strategy=nutrition_strategy,
            nutrition_targets=nutrition_targets,
            week_start_date=week_start.isoformat(),
            preferred_workout_time=preferred_workout_time,
        )

        # Extract daily entries and coordination notes
        daily_entries = generated_plan.get("daily_entries", [])
        coordination_notes = []
        for entry in daily_entries:
            notes = entry.get("coordination_notes", [])
            if notes:
                coordination_notes.extend(notes)

        # Save the plan to database
        saved_plan = await plan_service.generate_weekly_plan(
            user_id=str(user_id),
            week_start=week_start,
            workout_days=workout_days,
            fasting_protocol=fasting_protocol,
            nutrition_strategy=nutrition_strategy,
            goals=user_profile.get("goals", []),
            preferred_workout_time=preferred_workout_time,
        )

        # Format response message
        training_days = len([d for d in daily_entries if d.get("day_type") == "training"])
        rest_days = 7 - training_days

        response = f"""I've created your holistic weekly plan starting {week_start.strftime('%A, %B %d')}!

**Your Week Overview:**
- {training_days} training days
- {rest_days} rest/recovery days
- Fasting protocol: {fasting_protocol or 'None'}
- Nutrition strategy: {nutrition_strategy}

"""

        # Add any coordination warnings
        if coordination_notes:
            response += "**Important Notes:**\n"
            for note in coordination_notes[:3]:  # Limit to 3 notes
                response += f"- {note.get('message', str(note))}\n"
            response += "\n"

        response += "You can view your full plan in the Weekly Plan section. Each day shows your workout, nutrition targets, and meal suggestions coordinated with your fasting windows."

        return {
            "generated_plan": generated_plan,
            "daily_entries": daily_entries,
            "coordination_notes": coordination_notes,
            "ai_response": response,
            "final_response": response,
            "action_data": {
                "action": "plan_generated",
                "plan_id": str(saved_plan.id) if saved_plan else None,
                "week_start": week_start.isoformat(),
            }
        }

    except Exception as e:
        logger.error(f"Error generating weekly plan: {e}")
        error_response = "I encountered an issue generating your weekly plan. Please try again or adjust your preferences in Settings."
        return {
            "ai_response": error_response,
            "final_response": error_response,
            "error": str(e),
        }


async def plan_query_node(state: PlanAgentState) -> Dict[str, Any]:
    """
    Answer questions about the user's existing plan.
    """
    logger.info("Plan Agent: Querying existing plan")

    user_id = state.get("user_id")
    user_message = state.get("user_message", "").lower()

    try:
        # Get current week's plan
        current_plan = await plan_service.get_current_week_plan(str(user_id))

        if not current_plan:
            response = """You don't have an active weekly plan yet!

Would you like me to create one for you? Just say "Create my weekly plan" and I'll generate a holistic plan that coordinates your workouts, nutrition, and fasting schedule."""
            return {
                "ai_response": response,
                "final_response": response,
                "action_data": {"action": "no_plan_found"}
            }

        # Determine what they're asking about
        today = date.today()

        if "today" in user_message:
            # Find today's entry
            today_entry = None
            for entry in current_plan.daily_entries:
                if entry.plan_date == today:
                    today_entry = entry
                    break

            if today_entry:
                response = format_daily_summary(today_entry, "Today")
            else:
                response = "I couldn't find today's plan entry. Your current plan may be for a different week."

        elif "tomorrow" in user_message:
            tomorrow = today + timedelta(days=1)
            tomorrow_entry = None
            for entry in current_plan.daily_entries:
                if entry.plan_date == tomorrow:
                    tomorrow_entry = entry
                    break

            if tomorrow_entry:
                response = format_daily_summary(tomorrow_entry, "Tomorrow")
            else:
                response = "Tomorrow's plan isn't available in your current weekly plan."

        else:
            # General plan overview
            response = format_weekly_summary(current_plan)

        return {
            "current_plan": current_plan.__dict__ if hasattr(current_plan, '__dict__') else current_plan,
            "ai_response": response,
            "final_response": response,
            "action_data": {
                "action": "plan_queried",
                "plan_id": str(current_plan.id) if current_plan else None,
            }
        }

    except Exception as e:
        logger.error(f"Error querying plan: {e}")
        error_response = "I had trouble retrieving your plan. Please check the Weekly Plan section in the app."
        return {
            "ai_response": error_response,
            "final_response": error_response,
            "error": str(e),
        }


async def plan_modify_node(state: PlanAgentState) -> Dict[str, Any]:
    """
    Handle plan modifications and adjustments.
    """
    logger.info("Plan Agent: Modifying plan")

    user_message = state.get("user_message", "")
    user_id = state.get("user_id")

    # For now, provide guidance on modifications
    response = """I can help you adjust your plan! Here are some options:

1. **Regenerate meals** - Say "Give me different meal suggestions for tomorrow"
2. **Swap a rest day** - Say "Move my rest day from Tuesday to Wednesday"
3. **Adjust nutrition** - Say "Increase my calories on training days"
4. **Change fasting window** - You can update this in Settings > Fasting

What would you like to change?"""

    return {
        "ai_response": response,
        "final_response": response,
        "action_data": {"action": "modification_guidance"}
    }


async def plan_respond_node(state: PlanAgentState) -> Dict[str, Any]:
    """
    Handle general plan-related responses that don't require operations.
    """
    logger.info("Plan Agent: General response")

    user_message = state.get("user_message", "")
    conversation_history = state.get("conversation_history", [])
    user_profile = state.get("user_profile", {})

    # Build context for response
    context = f"""User is asking about their fitness plan.
User's goals: {user_profile.get('goals', [])}
User's fitness level: {user_profile.get('fitness_level', 'intermediate')}
"""

    try:
        response = await gemini_service.chat(
            user_message=user_message,
            system_prompt=f"""You are a helpful fitness planning assistant.
{context}

Help the user understand how holistic planning works - coordinating workouts, nutrition, and fasting.
Be encouraging and explain the benefits of having an integrated plan.
If they seem interested in creating a plan, guide them to say "Create my weekly plan".""",
            conversation_history=conversation_history[-5:],  # Last 5 messages for context
        )

        return {
            "ai_response": response,
            "final_response": response,
            "action_data": None
        }

    except Exception as e:
        logger.error(f"Error in plan respond: {e}")
        return {
            "ai_response": "I'm here to help with your fitness planning! Would you like to create a holistic weekly plan?",
            "final_response": "I'm here to help with your fitness planning! Would you like to create a holistic weekly plan?",
            "error": str(e),
        }


async def plan_action_data_node(state: PlanAgentState) -> Dict[str, Any]:
    """
    Finalize action data for the response.
    """
    action_data = state.get("action_data")

    if action_data is None:
        action_data = {"action": "plan_conversation"}

    return {
        "action_data": action_data,
        "rag_context_used": False,
    }


def format_daily_summary(entry: Any, day_label: str) -> str:
    """Format a daily plan entry as a readable summary."""
    day_type = getattr(entry, 'day_type', entry.get('day_type', 'rest'))

    summary = f"**{day_label}'s Plan:**\n\n"

    if day_type == "training":
        workout_focus = getattr(entry, 'workout_focus', entry.get('workout_focus', 'Workout'))
        workout_time = getattr(entry, 'workout_time', entry.get('workout_time'))
        summary += f"🏋️ **Workout:** {workout_focus}"
        if workout_time:
            summary += f" at {workout_time}"
        summary += "\n\n"
    else:
        summary += "😴 **Rest Day** - Focus on recovery\n\n"

    # Nutrition
    calories = getattr(entry, 'calorie_target', entry.get('calorie_target', 0))
    protein = getattr(entry, 'protein_target_g', entry.get('protein_target_g', 0))
    summary += f"🍽️ **Nutrition Targets:**\n"
    summary += f"- Calories: {calories}\n"
    summary += f"- Protein: {protein}g\n\n"

    # Fasting
    eating_start = getattr(entry, 'eating_window_start', entry.get('eating_window_start'))
    eating_end = getattr(entry, 'eating_window_end', entry.get('eating_window_end'))
    if eating_start and eating_end:
        summary += f"⏰ **Eating Window:** {eating_start} - {eating_end}\n\n"

    # Meal suggestions
    meals = getattr(entry, 'meal_suggestions', entry.get('meal_suggestions', []))
    if meals:
        summary += "🥗 **Meal Suggestions:**\n"
        for meal in meals[:3]:  # Limit to 3 meals
            meal_type = meal.get('meal_type', 'Meal')
            time = meal.get('suggested_time', '')
            summary += f"- {meal_type.title()} ({time})\n"

    return summary


def format_weekly_summary(plan: Any) -> str:
    """Format a weekly plan as a readable summary."""
    daily_entries = getattr(plan, 'daily_entries', [])

    training_count = sum(1 for e in daily_entries if getattr(e, 'day_type', e.get('day_type')) == 'training')
    rest_count = 7 - training_count

    summary = f"""**Your Weekly Plan Overview:**

📅 **Schedule:**
- Training days: {training_count}
- Rest days: {rest_count}

**Daily Breakdown:**
"""

    day_names = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

    for i, entry in enumerate(daily_entries[:7]):
        day_type = getattr(entry, 'day_type', entry.get('day_type', 'rest'))
        day_name = day_names[i] if i < len(day_names) else f"Day {i+1}"

        if day_type == "training":
            focus = getattr(entry, 'workout_focus', entry.get('workout_focus', 'Workout'))
            summary += f"- **{day_name}:** 🏋️ {focus}\n"
        else:
            summary += f"- **{day_name}:** 😴 Rest\n"

    summary += "\nTap on any day in the Weekly Plan screen to see detailed nutrition targets and meal suggestions!"

    return summary
