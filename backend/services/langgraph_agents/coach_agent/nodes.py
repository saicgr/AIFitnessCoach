"""
Node implementations for the Coach Agent.

The coach agent is autonomous - it handles:
1. General fitness questions
2. Motivation and greetings
3. App settings and navigation (via action_data)
"""
from typing import Dict, Any, Literal
from datetime import datetime
import base64
import pytz

from google.genai import types
from services.gemini.constants import gemini_generate_with_retry

from .state import CoachAgentState
from ..personality import build_personality_prompt, sanitize_coach_name
from models.chat import AISettings, CoachIntent
from services.gemini_service import GeminiService
from core.logger import get_logger

logger = get_logger(__name__)

# Coach expertise base prompt template (coach name is inserted dynamically)
COACH_BASE_PROMPT_TEMPLATE = """You are {coach_name}, an AI fitness coach. You are the main point of contact for users and handle:
- General fitness questions and advice
- Motivation and encouragement
- App navigation guidance
- Overall wellness tips

NOTE ON PERSONALITY:
Your voice, tone, energy level, and how you celebrate (or don't celebrate)
are defined entirely in the PERSONALITY CUSTOMIZATION section further down.
That section OVERRIDES any default warmth or enthusiasm. If the user picked
a reserved or stoic persona, stay reserved — do NOT default to hype or
celebratory phrasing.

CAPABILITIES:
1. **General Fitness**: Answer questions about training, rest, recovery
2. **Motivation**: Provide encouragement and support
3. **App Control**: Help users navigate the app and change settings
4. **Wellness**: Tips on sleep, stress, and overall health
5. **Nutrition**: Provide dietary advice and meal suggestions
6. **Injury/Recovery**: Help with pain and recovery questions
7. **Hydration**: Guide water intake and hydration
8. **Vision**: Analyze progress photos, identify gym equipment, read fitness documents and workout plans

You are a comprehensive fitness coach who can handle ALL aspects of fitness and wellness.
Do NOT tell users to ask other agents or use @mentions - YOU handle everything!

APP FEATURES & NAVIGATION GUIDE:
You can guide users to any feature and trigger navigation via action_data.

MAIN SCREENS (Bottom Nav):
- Home: Today's workout, quick actions, weekly calendar, progress stats
- Nutrition: Meal logging (photo/barcode/text), hydration (tab 3), macro targets
- Social: Activity feed, friends, challenges, leaderboards
- Profile: User stats, workout history, measurements, progress photos

WORKOUT FEATURES:
- Today's Workout: AI-generated daily workout on home screen
- Exercise Library (/library): 500+ exercises with form videos
- Custom Workouts (/workout/build): Build from any exercise
- Schedule (/schedule): Weekly view with drag & drop
- Workout History (/workouts): Past workouts with stats
- Modifications: the Workout specialist handles these (add/remove/replace, intensity, reschedule). If the user asks for a change or a recommended change, acknowledge briefly and tell them you'll pass it along — the router forwards these to the Workout agent automatically.

NUTRITION:
- Meal Logging: Photo analysis, barcode scan, or text search
- Menu/Buffet Analysis: Photo of restaurant menu for analysis
- Hydration: Water intake tracking (Nutrition tab 3)
- Recipes (/recipe-suggestions): AI-powered based on goals
- Food History (/food-history): Past logged meals

PROGRESS & ANALYTICS:
- Stats (/stats): Comprehensive dashboard
- Exercise History (/stats/exercise-history): Weight/rep progression
- Muscle Analytics (/stats/muscle-analytics): Training distribution
- Consistency (/consistency): Streaks and patterns
- Measurements (/measurements): Body measurements
- Milestones (/stats/milestones): Achievement celebrations

HEALTH & WELLNESS:
- Injuries (/injuries): Log injuries, get modified workouts
- Habits (/habits): Daily habit tracking
- NEAT (/neat): Daily activity and steps
- Metrics (/metrics): Apple Health / Google Fit data
- Strain Prevention (/strain-prevention): Overtraining monitoring
- Plateau Detection (/plateau): Stagnation alerts
- Hormonal Health (/hormonal-health): Cycle-aware adjustments
- Diabetes (/diabetes): Blood glucose tracking

GAMIFICATION:
- XP System: Earn XP for workouts, meals, streaks
- Trophy Room (/trophy-room): Earned badges
- Leaderboard (/xp-leaderboard): Compare with friends
- Achievements (/achievements): Full achievement list
- Fitness Wrapped (/wrapped): Monthly recap stories

SETTINGS (navigate users here):
- Workout Settings (/settings/workout-settings): Days/week, duration, split
- AI Coach (/settings/ai-coach): Personality, voice, style
- Appearance (/settings/appearance): Dark/light mode, colors, font size
- Sound & Notifications (/settings/sound-notifications): Audio, haptics, push
- Equipment (/settings/equipment): Available gym equipment
- Offline Mode (/settings/offline-mode): Download workouts offline
- Privacy (/settings/privacy-data): Data export, account management
- Subscription (/settings/subscription): Plan management

THINGS YOU CAN DO DIRECTLY (via action_data):
1. Navigate to any screen ("take me to...", "open...", "show me...")
2. Toggle dark/light mode on/off
3. Toggle ALL workout sounds on/off ("mute sounds", "turn off sounds")
4. Toggle countdown sounds specifically
5. Toggle rest timer sounds specifically
6. Toggle voice announcements / TTS on/off
7. Toggle background music on/off
8. Toggle haptic feedback on/off
9. Handle workout questions. IMPORTANT: you yourself have NO workout mutation tools. If the user wants to change a workout (add/remove/replace/reschedule/intensity) or asks for a recommended change, tell them briefly that you'll pass it to the workout specialist — the router will forward the next message to the Workout agent automatically when it sees a modification or recommendation intent.
10. Analyze food photos for calories & macros
11. Check exercise form from video
12. Compare form across multiple videos
13. Log hydration ("I drank 3 glasses of water")
14. Set daily water goal ("set my water goal to 10 glasses")
15. Report injuries and get modified workouts
16. Generate quick custom workouts
17. Start today's workout
18. Mark workout as complete
19. Answer any fitness, nutrition, or wellness question

VALID DESTINATIONS (for action_data with action: "navigate"):
home, nutrition, social, profile, workouts, library, schedule, workout_builder,
hydration, fasting, food_history, food_library, recipe_suggestions, nutrition_settings,
stats, progress, milestones, exercise_history, muscle_analytics, progress_charts,
consistency, measurements, chat, support, live_chat, help, glossary,
injuries, habits, neat, metrics, diabetes, plateau, strain_prevention,
hormonal_health, mood_history, achievements, trophy_room, leaderboard,
rewards, summaries, settings, workout_settings, ai_coach, appearance,
sound_notifications, equipment, offline_mode, privacy, subscription

DIRECTLY TOGGLEABLE SETTINGS (action: "change_setting", setting_value: true/false):
- dark_mode / theme_mode: Toggle dark mode (true=dark, false=light)
- sounds / sound_effects / mute: Toggle ALL workout sounds
- countdown_sounds: Toggle countdown beeps (3, 2, 1)
- rest_timer_sounds: Toggle rest timer end chime
- voice_announcements / tts / text_to_speech: Toggle voice coach during workouts
- background_music: Allow/block background music apps during workouts
- haptics: Toggle vibration feedback

SETTINGS THAT OPEN SETTINGS PAGE (action: "change_setting"):
- notifications: Opens Sound & Notifications settings
- equipment: Opens Equipment settings
- workout_days / training_split: Opens Workout Settings
- ai_coach_style / coaching_style: Opens AI Coach settings
- font_size: Opens Appearance settings

ADDITIONAL ACTIONS:
- action: "log_hydration", amount: N - Log N glasses of water
- action: "set_water_goal", glasses: N - Set daily water goal to N glasses
- action: "log_weight", weight: N - Navigate to log weight
- action: "start_workout", workout_id: ID - Start a specific workout
- action: "complete_workout", workout_id: ID - Mark workout as done

AI IMPORT TOOLS (delegated to the tool-binding agent path):
- import_gym_equipment(source='file'|'images'|'text'|'url', s3_keys?, mime_types?, raw_text?, url?)
  * When a user uploads a gym equipment list (PDF/Word/photo/URL) or says
    something like "import my gym equipment from this PDF", call this tool.
  * Returns {{action: "import_gym_equipment", job_id}} — the frontend polls
    /media-jobs/{{job_id}} and shows a confirmation sheet when the job
    completes. DO NOT attempt to list equipment yourself — the tool handles
    extraction, taxonomy matching, and environment inference.
- import_exercise(source='photo'|'video'|'text', s3_key?, raw_text?, user_hint?)
  * Use when the user wants to save a new custom exercise to their library
    — e.g. "add barbell hip thrust to my exercises", a photo of a new
    machine, or a video demo. Photo/text return the saved row synchronously;
    video returns a job_id for the preview sheet.
"""


def get_coach_system_prompt(ai_settings: Dict[str, Any] = None) -> str:
    """Build the full system prompt with personality customization."""
    settings_obj = AISettings(**ai_settings) if ai_settings else None

    # Get the coach name from settings or use default (sanitized)
    coach_name = sanitize_coach_name(settings_obj.coach_name, default="Coach") if settings_obj and settings_obj.coach_name else "Coach"

    # Build the base prompt with the coach name
    base_prompt = COACH_BASE_PROMPT_TEMPLATE.format(coach_name=coach_name)

    personality = build_personality_prompt(
        ai_settings=settings_obj,
        agent_name="Coach",  # Fallback agent name if coach_name not set
        agent_specialty="fitness coaching and wellness guidance"
    )
    return f"{base_prompt}\n\n{personality}"


def format_workout_context(schedule: Dict[str, Any]) -> str:
    """Format workout schedule for context."""
    if not schedule:
        return ""

    parts = ["\nWORKOUT OVERVIEW:"]

    def format_date(date_str: str) -> str:
        if not date_str:
            return ""
        if "T" in date_str:
            date_str = date_str.split("T")[0]
        try:
            date_obj = datetime.strptime(date_str, "%Y-%m-%d")
            return date_obj.strftime("%A, %B %d")
        except ValueError:
            return date_str

    today = schedule.get("today")
    if today:
        status = "COMPLETED" if today.get("is_completed") else "scheduled"
        parts.append(f"- Today: {today.get('name', 'Unknown')} ({status})")

    tomorrow = schedule.get("tomorrow")
    if tomorrow:
        parts.append(f"- Tomorrow: {tomorrow.get('name', 'Unknown')}")

    this_week = schedule.get("thisWeek", [])
    completed_count = sum(1 for w in this_week if w.get("is_completed"))
    total_count = len(this_week)
    if total_count > 0:
        parts.append(f"- This week: {completed_count}/{total_count} workouts completed")

    return "\n".join(parts)


def should_handle_action(state: CoachAgentState) -> Literal["action", "respond"]:
    """
    Determine if this is an action request or general question.

    Routes to action if:
    - User wants to change settings
    - User wants to navigate somewhere
    - User wants to start/complete a workout

    Routes to respond for:
    - General questions
    - Greetings
    - Motivation requests
    """
    intent = state.get("intent")

    action_intents = [
        CoachIntent.CHANGE_SETTING,
        CoachIntent.NAVIGATE,
        CoachIntent.START_WORKOUT,
        CoachIntent.COMPLETE_WORKOUT,
        CoachIntent.SET_WATER_GOAL,
        CoachIntent.LOG_WEIGHT,
    ]

    if intent in action_intents:
        logger.info(f"[Coach Router] Action intent: {intent} -> action")
        return "action"

    # Default: respond with coaching
    logger.info("[Coach Router] General query -> respond")
    return "respond"


async def coach_action_node(state: CoachAgentState) -> Dict[str, Any]:
    """
    Handle app actions (settings, navigation, workout control).
    """
    logger.info("[Coach Action] Processing app action...")

    intent = state.get("intent")
    gemini_service = GeminiService()

    action_data = None
    action_context = None

    if intent == CoachIntent.CHANGE_SETTING:
        setting_name = state.get("setting_name")
        setting_value = state.get("setting_value")
        if setting_name is not None:
            action_data = {
                "action": "change_setting",
                "setting_name": setting_name,
                "setting_value": setting_value,
                "success": True,
            }
            action_context = f"Changed setting '{setting_name}' to {setting_value}"

    elif intent == CoachIntent.NAVIGATE:
        destination = state.get("destination")
        if destination:
            action_data = {
                "action": "navigate",
                "destination": destination,
                "success": True,
            }
            action_context = f"Navigating to {destination}"

    elif intent == CoachIntent.START_WORKOUT:
        workout = state.get("current_workout")
        workout_id = workout.get("id") if workout else None
        action_data = {
            "action": "start_workout",
            "workout_id": workout_id,
            "success": True,
        }
        action_context = f"Starting workout: {workout.get('name') if workout else 'your workout'}"

    elif intent == CoachIntent.COMPLETE_WORKOUT:
        workout = state.get("current_workout")
        workout_id = workout.get("id") if workout else None
        action_data = {
            "action": "complete_workout",
            "workout_id": workout_id,
            "success": True,
        }
        action_context = f"Completing workout: {workout.get('name') if workout else 'your workout'}"

    elif intent == CoachIntent.SET_WATER_GOAL:
        glasses = state.get("water_goal_glasses", 8)
        action_data = {
            "action": "set_water_goal",
            "glasses": glasses,
            "success": True,
        }
        action_context = f"Setting daily water goal to {glasses} glasses"

    elif intent == CoachIntent.LOG_WEIGHT:
        weight = state.get("weight_value")
        action_data = {
            "action": "log_weight",
            "weight": weight,
            "success": True,
        }
        action_context = f"Logging weight: {weight}"

    # Generate a natural response for the action
    context_parts = []

    if state.get("user_profile"):
        profile = state["user_profile"]
    if action_context:
        context_parts.append(f"\nACTION: {action_context}")

    context = "\n".join(context_parts)

    # Get personalized system prompt
    ai_settings = state.get("ai_settings")
    base_system_prompt = get_coach_system_prompt(ai_settings)

    system_prompt = f"""{base_system_prompt}

CONTEXT:
{context}

You just performed an app action for the user. Acknowledge it naturally and briefly.
Be friendly and helpful!"""

    conversation_history = [
        {"role": msg["role"], "content": msg["content"]}
        for msg in state.get("conversation_history", [])
    ]

    response = await gemini_service.chat(
        user_message=state["user_message"],
        system_prompt=system_prompt,
        conversation_history=conversation_history,
    )

    logger.info(f"[Coach Action] Response: {response[:100]}...")

    return {
        "ai_response": response,
        "final_response": response,
        "action_data": action_data,
    }


async def coach_response_node(state: CoachAgentState) -> Dict[str, Any]:
    """
    Handle general coaching responses.
    This is the main autonomous response node.
    """
    logger.info("[Coach Response] Generating coaching response...")

    gemini_service = GeminiService()

    context_parts = []

    # Add current date/time
    pacific = pytz.timezone('America/Los_Angeles')
    now = datetime.now(pacific)
    context_parts.append(f"CURRENT DATE/TIME: {now.strftime('%A, %B %d, %Y at %I:%M %p')} (Pacific Time)")

    if state.get("user_profile"):
        profile = state["user_profile"]
        context_parts.append(f"\nUSER PROFILE:")
        context_parts.append(f"- Fitness Level: {profile.get('fitness_level', 'beginner')}")
        context_parts.append(f"- Goals: {', '.join(profile.get('goals', []))}")

    if state.get("workout_schedule"):
        context_parts.append(format_workout_context(state["workout_schedule"]))

    if state.get("rag_context_formatted"):
        context_parts.append(f"\nPrevious context:\n{state['rag_context_formatted']}")

    context = "\n".join(context_parts)

    # Get personalized system prompt
    ai_settings = state.get("ai_settings")
    base_system_prompt = get_coach_system_prompt(ai_settings)

    system_prompt = f"""{base_system_prompt}

CONTEXT:
{context}

Respond to the user's message with friendly, helpful coaching advice.
Be personable, encouraging, and adapt to their fitness level!"""

    conversation_history = [
        {"role": msg["role"], "content": msg["content"]}
        for msg in state.get("conversation_history", [])
    ]

    # Check if media is present for vision-aware response
    has_media = (
        state.get("image_base64")
        or state.get("media_ref")
        or state.get("media_refs")
    )

    if has_media:
        # Vision-aware response using multimodal Gemini
        media_content_type = state.get("media_content_type", "unknown")
        vision_hints = {
            "progress_photo": "Analyze the physique in this progress photo. Note visible muscle development, body composition, and provide encouraging, constructive feedback. Compare to fitness goals if known.",
            "gym_equipment": "Identify the gym equipment or machine in this image. Explain proper usage, suggest exercises that can be done with it, and provide safety tips.",
            "document": "Read and analyze this fitness-related document (workout plan, medical note, etc.). Provide relevant coaching advice based on its contents.",
        }
        vision_hint = vision_hints.get(media_content_type, "Analyze the image and provide relevant coaching advice.")

        # Add vision hint to system prompt
        vision_system_prompt = f"""{system_prompt}

VISION CONTEXT:
You have been sent an image. {vision_hint}
Respond naturally as a coach who can see the image."""

        # Resolve image bytes
        image_bytes = None
        image_mime = "image/jpeg"
        try:
            if state.get("image_base64"):
                image_bytes = base64.b64decode(state["image_base64"])
            elif state.get("media_refs"):
                ref = state["media_refs"][0]
                s3_key = ref.get("s3_key")
                image_mime = ref.get("mime_type", "image/jpeg")
                if s3_key:
                    from services.vision_service import get_vision_service
                    vision_svc = get_vision_service()
                    image_bytes = await vision_svc._download_image_from_s3(s3_key)
            elif state.get("media_ref"):
                ref = state["media_ref"]
                s3_key = ref.get("s3_key")
                image_mime = ref.get("mime_type", "image/jpeg")
                if s3_key:
                    from services.vision_service import get_vision_service
                    vision_svc = get_vision_service()
                    image_bytes = await vision_svc._download_image_from_s3(s3_key)
        except Exception as e:
            logger.warning(f"[Coach Response] Failed to resolve image: {e}", exc_info=True)

        if image_bytes:
            # Build multimodal content
            image_part = types.Part.from_bytes(data=image_bytes, mime_type=image_mime)

            # Build conversation as text
            conv_text = ""
            for msg in conversation_history:
                role = msg.get("role", "user")
                conv_text += f"{role}: {msg.get('content', '')}\n"

            from core.config import get_settings as get_app_settings
            app_settings = get_app_settings()

            vision_response = await gemini_generate_with_retry(
                model=app_settings.gemini_model,
                contents=[
                    f"{vision_system_prompt}\n\nConversation:\n{conv_text}\n\nUser: {state['user_message']}",
                    image_part,
                ],
                config=types.GenerateContentConfig(
                    temperature=0.7,
                    max_output_tokens=2000,
                ),
                user_id=str(state.get("user_id", "")),
                method_name="coach_respond",
            )
            response = vision_response.text
            logger.info(f"[Coach Response] Vision response: {response[:100]}...")
        else:
            # Fallback to text-only if image resolution failed
            logger.warning("[Coach Response] Media indicated but image bytes not resolved, falling back to text")
            response = await gemini_service.chat(
                user_message=state["user_message"],
                system_prompt=system_prompt,
                conversation_history=conversation_history,
            )
    else:
        response = await gemini_service.chat(
            user_message=state["user_message"],
            system_prompt=system_prompt,
            conversation_history=conversation_history,
        )

    logger.info(f"[Coach Response] Response: {response[:100]}...")

    return {
        "ai_response": response,
        "final_response": response,
    }
