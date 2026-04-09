"""
Gemini Service Chat - Chat, intent extraction, embeddings, workout input parsing.
"""
import asyncio
import hashlib
import json
import logging
import time
from typing import Any, Dict, List, Optional

from google.genai import types
from core.config import get_settings
from models.chat import IntentExtraction, CoachIntent
from models.gemini_schemas import (
    IntentExtractionResponse,
    ExerciseListResponse,
    ParseWorkoutInputResponse,
    ParseWorkoutInputV2Response,
)
from services.gemini.constants import (
    client, _log_token_usage, _gemini_semaphore,
    _intent_cache, _embedding_cache, settings,
    gemini_generate_with_retry, _is_transient_gemini_error,
)
from services.gemini.utils import _sanitize_for_prompt

logger = logging.getLogger("gemini")


class ChatMixin:
    """Mixin providing chat and extraction methods for GeminiService."""

    async def chat(
        self,
        user_message: str,
        system_prompt: Optional[str] = None,
        conversation_history: Optional[List[Dict[str, str]]] = None,
    ) -> str:
        """
        Send a chat message to Gemini and get a response.

        Args:
            user_message: The user's message
            system_prompt: Optional system prompt for context
            conversation_history: List of previous messages

        Returns:
            AI response string
        """
        contents = []

        # Add conversation history
        if conversation_history:
            for msg in conversation_history:
                role = "user" if msg["role"] == "user" else "model"
                contents.append(types.Content(role=role, parts=[types.Part.from_text(text=msg["content"])]))

        # Add current message
        contents.append(types.Content(role="user", parts=[types.Part.from_text(text=user_message)]))

        # Relaxed safety settings for chat — users may vent or use profanity,
        # and the coach personas are designed to handle it in-character.
        # Block only BLOCK_ONLY_HIGH to avoid false positives on fitness content.
        chat_safety_settings = [
            types.SafetySetting(
                category="HARM_CATEGORY_HARASSMENT",
                threshold="BLOCK_ONLY_HIGH",
            ),
            types.SafetySetting(
                category="HARM_CATEGORY_HATE_SPEECH",
                threshold="BLOCK_ONLY_HIGH",
            ),
            types.SafetySetting(
                category="HARM_CATEGORY_SEXUALLY_EXPLICIT",
                threshold="BLOCK_MEDIUM_AND_ABOVE",
            ),
            types.SafetySetting(
                category="HARM_CATEGORY_DANGEROUS_CONTENT",
                threshold="BLOCK_MEDIUM_AND_ABOVE",
            ),
        ]

        response = await gemini_generate_with_retry(
            model=self.model,
            contents=contents,
            config=types.GenerateContentConfig(
                system_instruction=system_prompt,
                max_output_tokens=settings.gemini_max_tokens,
                temperature=settings.gemini_temperature,
                safety_settings=chat_safety_settings,
            ),
            timeout=60,
            method_name="chat",
        )

        return response.text

    async def extract_intent(self, user_message: str, user_id: Optional[str] = None) -> IntentExtraction:
        """
        Extract structured intent from user message using AI.

        MODIFY THIS to change how intents are detected.
        """
        extraction_prompt = '''You are a fitness app intent extraction system. Analyze the user message and extract structured data.

Return ONLY valid JSON in this exact format (no markdown, no explanation):
{
  "intent": "add_exercise|remove_exercise|swap_workout|modify_intensity|reschedule|delete_workout|report_injury|change_setting|navigate|start_workout|complete_workout|log_hydration|set_water_goal|log_weight|generate_quick_workout|nutrition_summary|recent_meals|question",
  "exercises": ["exercise name 1", "exercise name 2"],
  "muscle_groups": ["chest", "back", "shoulders", "biceps", "triceps", "legs", "core", "glutes"],
  "modification": "easier|harder|shorter|longer",
  "body_part": "shoulder|back|knee|ankle|wrist|elbow|hip|neck",
  "setting_name": "dark_mode|sounds|countdown_sounds|rest_timer_sounds|voice_announcements|tts|background_music|haptics|notifications|equipment|workout_days|training_split|ai_coach_style|coaching_style|font_size",
  "setting_value": true,
  "destination": "home|nutrition|social|profile|workouts|library|schedule|workout_builder|hydration|fasting|food_history|food_library|recipe_suggestions|nutrition_settings|stats|progress|milestones|exercise_history|muscle_analytics|progress_charts|consistency|measurements|chat|support|help|glossary|injuries|habits|neat|metrics|diabetes|plateau|strain_prevention|hormonal_health|mood_history|achievements|trophy_room|leaderboard|rewards|summaries|settings|workout_settings|ai_coach|appearance|sound_notifications|equipment|offline_mode|privacy|subscription",
  "hydration_amount": 8,
  "water_goal_glasses": 10,
  "weight_value": 75.5
}

INTENT DEFINITIONS:
- add_exercise: User wants to ADD an exercise (e.g., "add pull-ups", "include bench press")
- remove_exercise: User wants to REMOVE an exercise (e.g., "remove squats", "take out lunges")
- swap_workout: User wants a DIFFERENT workout type (e.g., "not in mood for leg day")
- modify_intensity: User wants to change difficulty/duration (e.g., "make it easier", "too hard")
- reschedule: User wants to change workout timing (e.g., "move to tomorrow")
- delete_workout: User wants to DELETE/CANCEL a workout entirely (e.g., "delete today's workout", "cancel my workout", "remove this workout")
- report_injury: User mentions pain/injury (e.g., "my shoulder hurts")
- change_setting: User wants to change app settings (e.g., "turn on dark mode", "enable dark theme", "switch to light mode")
- navigate: User wants to go to a specific screen (e.g., "show my achievements", "open nutrition", "go to profile")
- start_workout: User wants to START their workout NOW (e.g., "start my workout", "let's go", "begin workout", "I'm ready")
- complete_workout: User wants to FINISH/COMPLETE their workout (e.g., "I'm done", "finished", "completed my workout", "mark as done")
- log_hydration: User wants to LOG water intake (e.g., "log 8 glasses of water", "I drank 3 cups", "track my water")
- set_water_goal: User wants to SET their daily water goal (e.g., "set my water goal to 10 glasses", "change my daily water target to 12 cups")
- log_weight: User wants to LOG their weight (e.g., "log my weight as 75kg", "I weigh 165 lbs", "record my weight")
- generate_quick_workout: User wants to CREATE/GENERATE a new workout (e.g., "give me a quick workout", "create a 15-minute workout", "make me a cardio workout", "I need a short workout", "new workout please")
- nutrition_summary: User wants a SUMMARY of their nutrition/diet (e.g., "how's my diet today?", "show my macros", "nutrition summary", "what did I eat today?", "calorie report")
- recent_meals: User wants to see their RECENT MEALS or food log (e.g., "what did I eat?", "show my meals", "recent food", "meal history")
- question: General fitness question or unclear intent

SETTING EXTRACTION:
- For dark mode requests: setting_name="dark_mode", setting_value=true
- For light mode requests: setting_name="dark_mode", setting_value=false
- For notification toggles: setting_name="notifications", setting_value=true/false
- For mute/unmute sounds: setting_name="sounds", setting_value=false (mute) / true (unmute)
- For countdown beeps: setting_name="countdown_sounds", setting_value=true/false
- For rest timer sounds: setting_name="rest_timer_sounds", setting_value=true/false
- For voice/TTS toggle: setting_name="voice_announcements", setting_value=true/false
- For background music: setting_name="background_music", setting_value=true/false
- For haptic feedback: setting_name="haptics", setting_value=true/false
- For equipment setup: setting_name="equipment" (no setting_value needed, opens settings)
- For workout days/split: setting_name="workout_days" (opens settings)
- For AI coach style: setting_name="ai_coach_style" (opens settings)
- For font size: setting_name="font_size" (opens settings)

NAVIGATION EXTRACTION:
- "show achievements" / "my badges" -> destination="achievements"
- "hydration" / "water intake" -> destination="hydration"
- "nutrition" / "my meals" / "calories" -> destination="nutrition"
- "weekly summary" / "my progress" -> destination="summaries"
- "go home" / "main screen" -> destination="home"
- "exercise library" / "browse exercises" -> destination="library"
- "my profile" -> destination="profile"
- "open settings" / "app settings" -> destination="settings"
- "my stats" / "statistics" / "progress" -> destination="stats"
- "my schedule" / "workout schedule" -> destination="schedule"
- "fasting" / "intermittent fasting" -> destination="fasting"
- "open chat" / "go to chat" -> destination="chat"
- "neat tracking" / "step tracking" -> destination="neat"
- "my metrics" / "body metrics" -> destination="metrics"
- "help" / "support" / "contact" -> destination="support"
- "workout settings" / "exercise preferences" -> destination="workout_settings"
- "ai coach settings" / "coach preferences" -> destination="ai_coach"
- "appearance" / "theme settings" -> destination="appearance"
- "social" / "friends" / "community" -> destination="social"
- "workout history" / "past workouts" -> destination="workouts"
- "build workout" / "custom workout" -> destination="workout_builder"
- "injuries" / "injury tracker" -> destination="injuries"
- "habits" / "daily habits" -> destination="habits"
- "measurements" / "body measurements" -> destination="measurements"
- "milestones" -> destination="milestones"
- "exercise history" / "exercise progress" -> destination="exercise_history"
- "muscle analytics" / "muscle distribution" -> destination="muscle_analytics"
- "consistency" / "streaks" -> destination="consistency"
- "trophy room" / "trophies" -> destination="trophy_room"
- "leaderboard" / "ranking" -> destination="leaderboard"
- "recipes" / "meal suggestions" -> destination="recipe_suggestions"
- "sound settings" / "notification settings" -> destination="sound_notifications"
- "equipment" / "gym equipment" -> destination="equipment"
- "offline mode" / "download workouts" -> destination="offline_mode"
- "privacy" / "data settings" -> destination="privacy"
- "subscription" / "my plan" / "billing" -> destination="subscription"
- "diabetes" / "blood sugar" / "glucose" -> destination="diabetes"
- "plateau" / "stagnation" -> destination="plateau"
- "strain prevention" / "overtraining" -> destination="strain_prevention"
- "hormonal health" / "cycle tracking" -> destination="hormonal_health"

WORKOUT ACTION EXTRACTION:
- "start my workout" / "let's go" / "begin" / "I'm ready" / "start training" -> intent="start_workout"
- "I'm done" / "finished" / "completed" / "mark as done" / "workout complete" -> intent="complete_workout"

HYDRATION EXTRACTION:
- Extract the NUMBER of glasses/cups from the message
- "log 8 glasses of water" -> hydration_amount=8
- "I drank 3 cups" -> hydration_amount=3
- "track 2 glasses" -> hydration_amount=2
- If no number specified, default to hydration_amount=1

WATER GOAL EXTRACTION:
- "set my water goal to 10 glasses" -> intent="set_water_goal", water_goal_glasses=10
- "change my daily water target to 12" -> intent="set_water_goal", water_goal_glasses=12
- If no number specified, default to water_goal_glasses=8

WEIGHT LOGGING EXTRACTION:
- "log my weight as 75kg" -> intent="log_weight", weight_value=75.0
- "I weigh 165 lbs" -> intent="log_weight", weight_value=165.0
- "record weight 80" -> intent="log_weight", weight_value=80.0

User message: "''' + _sanitize_for_prompt(user_message) + '"'

        # Check intent cache first (common intents like greetings hit this often)
        try:
            cache_key = _intent_cache.make_key("intent", user_message.strip().lower())
            cached_result = await _intent_cache.get(cache_key)
            if cached_result is not None:
                logger.info(f"[IntentCache] Cache HIT for message: '{user_message[:50]}...'")
                return cached_result
        except Exception as cache_err:
            logger.warning(f"[IntentCache] Cache lookup error (falling through): {cache_err}", exc_info=True)

        try:
            response = await gemini_generate_with_retry(
                model=self.model,
                contents=extraction_prompt,
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    response_schema=IntentExtractionResponse,
                    max_output_tokens=2000,  # Increased for thinking models
                    temperature=0.1,  # Low temp for consistent extraction
                ),
                user_id=user_id,
                method_name="extract_intent",
                timeout=15,
            )

            # Use response.parsed for structured output - SDK handles JSON parsing
            data = response.parsed
            if not data:
                raise ValueError("Gemini returned empty intent extraction response")

            result = IntentExtraction(
                intent=CoachIntent(data.intent or "question"),
                exercises=[e.lower() for e in (data.exercises or [])],
                muscle_groups=[m.lower() for m in (data.muscle_groups or [])],
                modification=data.modification,
                body_part=data.body_part,
                setting_name=data.setting_name,
                setting_value=data.setting_value,
                destination=data.destination,
                hydration_amount=data.hydration_amount,
                water_goal_glasses=data.water_goal_glasses,
                weight_value=data.weight_value,
            )

            # Cache the result
            try:
                await _intent_cache.set(cache_key, result)
                logger.info(f"[IntentCache] Cache MISS - stored result for: '{user_message[:50]}...'")
            except Exception as cache_err:
                logger.warning(f"[IntentCache] Failed to store result: {cache_err}", exc_info=True)

            return result

        except asyncio.TimeoutError:
            logger.error(f"[Intent] Gemini API timed out after 15s for intent extraction", exc_info=True)
            return IntentExtraction(intent=CoachIntent.QUESTION)
        except Exception as e:
            logger.error(f"Intent extraction failed: {e}", exc_info=True)
            return IntentExtraction(intent=CoachIntent.QUESTION)

    async def extract_exercises_from_response(self, ai_response: str) -> Optional[List[str]]:
        """
        Extract exercise names from the AI's response.

        This is used to ensure the exercises we add/remove match what the AI
        actually mentioned in its response, not just what the user asked for.
        """
        extraction_prompt = f'''Extract ALL exercise names mentioned in this fitness coach response.

Response: "{_sanitize_for_prompt(ai_response, max_len=5000)}"

Return a JSON object with an "exercises" array containing the exercise names:
{{"exercises": ["Exercise 1", "Exercise 2", ...]}}

IMPORTANT:
- Include ALL exercises mentioned, including compound names like "Cable Woodchoppers"
- Keep the exact exercise names as written
- If no exercises are mentioned, return: {{"exercises": []}}'''

        try:
            response = await gemini_generate_with_retry(
                model=self.model,
                contents=extraction_prompt,
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    response_schema=ExerciseListResponse,
                    max_output_tokens=2000,  # Increased for thinking models
                    temperature=0.1,
                ),
                method_name="extract_exercises",
                timeout=15,
            )

            # Use response.parsed for structured output - SDK handles JSON parsing
            data = response.parsed
            if not data:
                return None
            exercises = data.exercises or []

            if isinstance(exercises, list) and len(exercises) > 0:
                return exercises
            return None

        except Exception as e:
            logger.error(f"Exercise extraction from response failed: {e}", exc_info=True)
            return None

    async def parse_workout_input(
        self,
        input_text: Optional[str] = None,
        image_base64: Optional[str] = None,
        voice_transcript: Optional[str] = None,
        user_unit_preference: str = "lbs",
    ) -> Dict:
        """
        Parse natural language workout input into structured exercises.

        Supports text, image, or voice transcript input. Uses Gemini to extract
        exercise names, sets, reps, and weights from free-form input like:
        - "3x10 deadlift at 135, 5x5 squat at 140"
        - "bench press 4 sets of 8 at 80"
        - Image of a workout log or whiteboard

        Args:
            input_text: Natural language text input
            image_base64: Base64 encoded image of workout notes
            voice_transcript: Transcribed voice input
            user_unit_preference: User's preferred weight unit ('kg' or 'lbs')

        Returns:
            Dictionary with 'exercises', 'summary', and 'warnings'
        """
        logger.info(f"🤖 [ParseWorkout] Parsing input: text={bool(input_text)}, image={bool(image_base64)}, voice={bool(voice_transcript)}")

        # Combine input sources
        combined_input = ""
        if input_text:
            combined_input += input_text
        if voice_transcript:
            combined_input += f" {voice_transcript}" if combined_input else voice_transcript

        if not combined_input and not image_base64:
            logger.warning("❌ [ParseWorkout] No input provided")
            return {
                "exercises": [],
                "summary": "No input provided",
                "warnings": ["Please provide text, image, or voice input"]
            }

        parse_prompt = f'''Parse workout exercises from the input. Extract each exercise with:
- name: Standard gym exercise name (e.g., "Bench Press", "Back Squat", "Deadlift")
- sets: Number of sets (the number before 'x' or after "sets")
- reps: Number of reps (the number after 'x' or after "reps")
- weight_value: Weight number if specified
- weight_unit: "{user_unit_preference}" unless explicitly stated otherwise (kg/lbs)
- rest_seconds: Rest period if mentioned, otherwise default to 60
- original_text: The exact text segment that was parsed for this exercise
- confidence: Your confidence in the parsing (0.0-1.0)
- notes: Any additional notes or form cues mentioned

PARSING RULES:
1. "3x10" means 3 sets of 10 reps
2. "4 sets of 8" means 4 sets of 8 reps
3. "at 135" or "@135" means 135 {user_unit_preference}
4. "100kg" or "100 kg" means 100 kilograms
5. "225lbs" or "225 lbs" means 225 pounds
6. If no weight specified, leave weight_value as null
7. Use standard exercise names (capitalize properly)

EXAMPLES:
- "3x10 deadlift at 135" → name="Deadlift", sets=3, reps=10, weight=135
- "bench 5x5 @ 225" → name="Bench Press", sets=5, reps=5, weight=225
- "4 sets of squats" → name="Back Squat", sets=4, reps=10 (default)
- "pull-ups 3x12" → name="Pull-ups", sets=3, reps=12, weight=null

INPUT TO PARSE:
"{_sanitize_for_prompt(combined_input, max_len=2000) or 'See image below'}"

Return a summary describing what was found and any warnings about unclear parsing.'''

        try:
            # Build content list
            contents = [parse_prompt]

            # Add image if provided
            if image_base64:
                import base64
                contents.append(types.Part.from_bytes(
                    data=base64.b64decode(image_base64),
                    mime_type="image/jpeg"
                ))

            response = await gemini_generate_with_retry(
                model=self.model,
                contents=contents,
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    response_schema=ParseWorkoutInputResponse,
                    max_output_tokens=4000,
                    temperature=0.2,  # Low for consistent parsing
                ),
                method_name="parse_workout_input",
                timeout=30,
            )

            data = response.parsed
            if not data:
                raise ValueError("Gemini returned empty parse response")

            exercises = []
            for ex in data.exercises:
                exercise_dict = {
                    "name": ex.name,
                    "sets": ex.sets,
                    "reps": ex.reps,
                    "weight_value": ex.weight_value,
                    "weight_unit": ex.weight_unit,
                    "rest_seconds": ex.rest_seconds,
                    "original_text": ex.original_text,
                    "confidence": ex.confidence,
                    "notes": ex.notes,
                }
                # Convert weight to both units for convenience
                if ex.weight_value is not None:
                    if ex.weight_unit.lower() == "kg":
                        exercise_dict["weight_kg"] = ex.weight_value
                        exercise_dict["weight_lbs"] = round(ex.weight_value * 2.20462, 1)
                    else:
                        exercise_dict["weight_lbs"] = ex.weight_value
                        exercise_dict["weight_kg"] = round(ex.weight_value / 2.20462, 1)
                else:
                    exercise_dict["weight_kg"] = None
                    exercise_dict["weight_lbs"] = None

                exercises.append(exercise_dict)

            result = {
                "exercises": exercises,
                "summary": data.summary,
                "warnings": data.warnings or [],
            }

            logger.info(f"✅ [ParseWorkout] Parsed {len(exercises)} exercises: {[e['name'] for e in exercises]}")
            return result

        except Exception as e:
            logger.error(f"❌ [ParseWorkout] Failed to parse workout input: {e}", exc_info=True)
            return {
                "exercises": [],
                "summary": f"Failed to parse input: {str(e)}",
                "warnings": ["Parsing failed. Please try rephrasing your input."]
            }

    async def parse_workout_input_v2(
        self,
        input_text: Optional[str] = None,
        image_base64: Optional[str] = None,
        voice_transcript: Optional[str] = None,
        user_unit_preference: str = "lbs",
        current_exercise_name: Optional[str] = None,
        last_set_weight: Optional[float] = None,
        last_set_reps: Optional[int] = None,
    ) -> Dict:
        """
        Parse workout input with dual-mode support.

        Supports TWO use cases simultaneously:
        1. Set logging: "135*8, 145*6" -> logs sets for CURRENT exercise
        2. Add exercise: "3x10 deadlift at 135" -> adds NEW exercise

        Smart shortcuts:
        - "+10" -> add 10 to last weight, keep same reps
        - "-10" -> subtract 10 from last weight
        - "same" -> repeat last set exactly
        - "drop" -> 10% weight reduction
        - "up" -> +5 progression

        Args:
            input_text: Natural language text input
            image_base64: Base64 encoded image
            voice_transcript: Transcribed voice input
            user_unit_preference: User's preferred weight unit
            current_exercise_name: Name of current exercise (for set logging context)
            last_set_weight: Weight from last set (for shortcuts)
            last_set_reps: Reps from last set (for shortcuts)

        Returns:
            Dictionary with 'sets_to_log', 'exercises_to_add', 'summary', 'warnings'
        """
        logger.info(
            f"🤖 [ParseWorkoutV2] Parsing: exercise={current_exercise_name}, "
            f"text={bool(input_text)}, image={bool(image_base64)}"
        )

        # Combine input sources
        combined_input = ""
        if input_text:
            combined_input += input_text
        if voice_transcript:
            combined_input += f" {voice_transcript}" if combined_input else voice_transcript

        if not combined_input and not image_base64:
            logger.warning("❌ [ParseWorkoutV2] No input provided")
            return {
                "sets_to_log": [],
                "exercises_to_add": [],
                "summary": "No input provided",
                "warnings": ["Please provide text, image, or voice input"]
            }

        # Build context for smart shortcuts
        last_set_context = ""
        if last_set_weight is not None and last_set_reps is not None:
            last_set_context = f"Last logged set: {last_set_weight} {user_unit_preference} × {last_set_reps} reps"
        else:
            last_set_context = "No previous set logged yet"

        current_ex_context = current_exercise_name or "Unknown Exercise"

        # Build smart shortcuts section based on available last set data
        if last_set_weight is not None:
            smart_shortcuts_section = f'''- "+10" -> {last_set_weight + 10} x {last_set_reps or "N/A"} reps (add 10 to last weight)
- "-10" -> {last_set_weight - 10} x {last_set_reps or "N/A"} reps (subtract 10)
- "+10*6" -> {last_set_weight + 10} x 6 reps (add 10, override reps)
- "same" -> {last_set_weight} x {last_set_reps or "N/A"} (repeat last set exactly)
- "same*10" -> {last_set_weight} x 10 (same weight, different reps)
- "drop" -> {round(last_set_weight * 0.9, 1)} x {last_set_reps or "N/A"} (10% drop)
- "drop 20" -> {last_set_weight - 20} x {last_set_reps or "N/A"} (subtract 20)
- "up" -> {last_set_weight + 5} x {last_set_reps or "N/A"} (standard +5 progression)'''
        else:
            smart_shortcuts_section = "Shortcuts not available - no previous set data"

        # Build the comprehensive prompt
        parse_prompt = f'''You are a workout input parser. Parse the user's input and determine their intent.

CONTEXT:
- Current exercise: "{current_ex_context}"
- User's preferred unit: {user_unit_preference} (use this when unit not specified)
- {last_set_context}

YOUR TASK: Categorize each line/segment as either:
1. SET LOG - Numbers only (no exercise name) → applies to current exercise "{current_ex_context}"
2. NEW EXERCISE - Contains exercise name → adds new exercise to workout

═══════════════════════════════════════════════════════════════
SET LOGGING PATTERNS (for current exercise: "{current_ex_context}")
═══════════════════════════════════════════════════════════════

Recognize these formats for WEIGHT × REPS:
- "135*8" or "135x8" or "135X8" or "135×8" → 135 {user_unit_preference} × 8 reps
- "135 * 8" or "135 x 8" → same with spaces
- "135, 8" or "135 8" → weight then reps (comma or space separator)
- "135lbs*8" or "135 lbs x 8" → 135 lbs × 8 (explicit unit overrides preference)
- "60kg*10" or "60 kg x 10" → 60 kg × 10 (explicit metric)
- "135#*8" → 135 lbs × 8 (# symbol means pounds)

BODYWEIGHT indicators (weight = 0, is_bodyweight = true):
- "bw*12" or "BW*12" or "bodyweight*12" → 0 × 12 reps (bodyweight)
- "0*12" or "-*12" → 0 × 12 reps (bodyweight)

DECIMAL weights:
- "135.5*8" → 135.5 {user_unit_preference} × 8 reps
- "60.5kg*10" → 60.5 kg × 10 reps

SPECIAL reps (is_failure = true):
- "135*AMRAP" or "135*max" or "135*F" → 135 × 0 reps with is_failure=true
- "135*8-10" → 135 × 8 reps (use lower bound of range)

SMART SHORTCUTS (ONLY when last set data is available):
{smart_shortcuts_section}

MULTIPLE sets on one line:
- "135*8, 145*6, 155*5" → 3 separate sets (comma-separated)
- "135*8; 145*6; 155*5" → 3 separate sets (semicolon-separated)

LABELED formats (strip labels, just parse numbers):
- "Set 1: 135*8" → parse as 135*8
- "1. 135*8" or "- 135*8" → parse as 135*8

═══════════════════════════════════════════════════════════════
NEW EXERCISE PATTERNS (adds to workout)
═══════════════════════════════════════════════════════════════

If input contains an exercise NAME, it's a NEW EXERCISE.

Formats:
- "3x10 deadlift at 135" → Deadlift: 3 sets × 10 reps @ 135 {user_unit_preference}
- "3*10 deadlift at 135" → same (star works too)
- "deadlift 3x10 at 135" → name first also works
- "deadlift 3x10 @ 135" → @ symbol for "at"
- "deadlift 3x10 135" → no preposition needed
- "deadlift 3x10 135lbs" → explicit unit
- "deadlift 135*8" → single set: 1 × 8 @ 135
- "bench 5x5 225" → Bench Press: 5×5 @ 225

ABBREVIATIONS to expand to full names:
- bench, bp → Bench Press
- squat, sq → Back Squat
- deadlift, dl → Deadlift
- ohp, press → Overhead Press
- row, br → Barbell Row
- pullups, pull-ups → Pull-ups
- dips → Dips
- rdl → Romanian Deadlift
- lat, pulldown → Lat Pulldown
- curl, bc → Bicep Curl
- tri, tricep → Tricep Extension
- leg press, lp → Leg Press

BODYWEIGHT exercises (is_bodyweight = true, no weight needed):
- "pull-ups 3x10" → Pull-ups: 3×10 @ bodyweight
- "dips 3x12" → Dips: 3×12 @ bodyweight
- "push-ups 3x15" → Push-ups: 3×15 @ bodyweight
- "weighted dips 3x8 +45" → Dips: 3×8 @ 45 lbs added weight

PLATE MATH (only if user says "plates"):
- "1 plate" = 135 lbs OR 60 kg (bar + 2×45lb plates)
- "2 plates" = 225 lbs OR 100 kg
- "bar only" = 45 lbs OR 20 kg

═══════════════════════════════════════════════════════════════
IMAGE ANALYSIS (if image provided)
═══════════════════════════════════════════════════════════════

Analyze the image for workout data:
1. Handwritten/printed text: exercise names, sets, reps, weights
2. App screenshots: extract exercise data from other fitness apps
3. Gym whiteboards: parse WOD/workout of the day
4. Weight plates on barbell: count plates, calculate total weight
   - 45lb plates (red/blue), 25lb (green), 10lb (yellow), 5lb, 2.5lb
   - Bar = 45 lbs / 20 kg
5. Cardio machine displays: distance, time, calories

═══════════════════════════════════════════════════════════════
OUTPUT FORMAT
═══════════════════════════════════════════════════════════════

Return JSON with this structure:
{{
  "sets_to_log": [
    {{
      "weight": 135.0,
      "reps": 8,
      "unit": "{user_unit_preference}",
      "is_bodyweight": false,
      "is_failure": false,
      "is_warmup": false,
      "original_input": "135*8",
      "notes": null
    }}
  ],
  "exercises_to_add": [
    {{
      "name": "Deadlift",
      "sets": 3,
      "reps": 10,
      "weight_kg": 61.2,
      "weight_lbs": 135.0,
      "rest_seconds": 60,
      "is_bodyweight": false,
      "original_text": "3x10 deadlift at 135",
      "confidence": 1.0,
      "notes": null
    }}
  ],
  "summary": "Log 1 set for {current_ex_context}, Add Deadlift",
  "warnings": []
}}

IMPORTANT RULES:
1. If NO exercise name → goes to sets_to_log
2. If HAS exercise name → goes to exercises_to_add
3. Both can be non-empty for mixed input
4. Expand abbreviations to full exercise names
5. Always provide both weight_kg and weight_lbs for exercises_to_add
6. Use is_bodyweight=true for bodyweight exercises

═══════════════════════════════════════════════════════════════
INPUT TO PARSE:
═══════════════════════════════════════════════════════════════
{_sanitize_for_prompt(combined_input, max_len=2000) or "See image below"}
'''

        try:
            # Build content list
            contents = [parse_prompt]

            # Add image if provided
            if image_base64:
                import base64
                contents.append(types.Part.from_bytes(
                    data=base64.b64decode(image_base64),
                    mime_type="image/jpeg"
                ))

            response = await gemini_generate_with_retry(
                model=self.model,
                contents=contents,
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    response_schema=ParseWorkoutInputV2Response,
                    max_output_tokens=4000,
                    temperature=0.2,  # Low for consistent parsing
                ),
                method_name="parse_workout_input_v2",
                timeout=30,
            )

            data = response.parsed
            if not data:
                raise ValueError("Gemini returned empty parse response")

            # Convert to dict format
            sets_to_log = []
            for s in data.sets_to_log:
                sets_to_log.append({
                    "weight": s.weight,
                    "reps": s.reps,
                    "unit": s.unit,
                    "is_bodyweight": s.is_bodyweight,
                    "is_failure": s.is_failure,
                    "is_warmup": s.is_warmup,
                    "original_input": s.original_input,
                    "notes": s.notes,
                })

            exercises_to_add = []
            for ex in data.exercises_to_add:
                exercises_to_add.append({
                    "name": ex.name,
                    "sets": ex.sets,
                    "reps": ex.reps,
                    "weight_kg": ex.weight_kg,
                    "weight_lbs": ex.weight_lbs,
                    "rest_seconds": ex.rest_seconds,
                    "is_bodyweight": ex.is_bodyweight,
                    "original_text": ex.original_text,
                    "confidence": ex.confidence,
                    "notes": ex.notes,
                })

            result = {
                "sets_to_log": sets_to_log,
                "exercises_to_add": exercises_to_add,
                "summary": data.summary,
                "warnings": data.warnings or [],
            }

            logger.info(
                f"✅ [ParseWorkoutV2] Parsed {len(sets_to_log)} sets, "
                f"{len(exercises_to_add)} exercises"
            )
            return result

        except Exception as e:
            logger.error(f"❌ [ParseWorkoutV2] Failed to parse: {e}", exc_info=True)
            return {
                "sets_to_log": [],
                "exercises_to_add": [],
                "summary": f"Failed to parse input: {str(e)}",
                "warnings": ["Parsing failed. Please try rephrasing your input."]
            }

    def get_embedding(self, text: str) -> List[float]:
        """
        Get embedding vector for text (used for RAG).
        Uses local cache to avoid redundant embedding API calls.

        Args:
            text: Text to embed

        Returns:
            Embedding vector as list of floats
        """
        # Check embedding cache first (sync path — local cache only)
        try:
            cache_key = _embedding_cache.make_key("emb", text.strip().lower())
            cached = _embedding_cache.get_sync(cache_key)
            if cached is not None:
                logger.debug(f"[EmbeddingCache] Cache HIT for: '{text[:40]}...'")
                return cached
        except Exception as cache_err:
            logger.warning(f"[EmbeddingCache] Cache lookup error (falling through): {cache_err}", exc_info=True)

        result = client.models.embed_content(
            model=self.embedding_model,
            contents=text,
            config=types.EmbedContentConfig(output_dimensionality=768),
        )
        embedding = result.embeddings[0].values

        # Cache the result (sync path — local cache only)
        try:
            _embedding_cache.set_sync(cache_key, embedding)
            logger.debug(f"[EmbeddingCache] Cache MISS - stored embedding for: '{text[:40]}...'")
        except Exception as cache_err:
            logger.warning(f"[EmbeddingCache] Failed to store embedding: {cache_err}", exc_info=True)

        return embedding

    async def get_embedding_async(self, text: str) -> List[float]:
        """
        Get embedding vector for text asynchronously.
        Uses local cache to avoid redundant embedding API calls.

        Args:
            text: Text to embed

        Returns:
            Embedding vector as list of floats
        """
        # Check embedding cache first
        try:
            cache_key = _embedding_cache.make_key("emb", text.strip().lower())
            cached = await _embedding_cache.get(cache_key)
            if cached is not None:
                logger.debug(f"[EmbeddingCache] Cache HIT (async) for: '{text[:40]}...'")
                return cached
        except Exception as cache_err:
            logger.warning(f"[EmbeddingCache] Cache lookup error (falling through): {cache_err}", exc_info=True)

        delays = [2.0, 5.0, 10.0]
        max_retries = 3
        for attempt in range(max_retries + 1):
            try:
                async with _gemini_semaphore(user_id=None):
                    result = await client.aio.models.embed_content(
                        model=self.embedding_model,
                        contents=text,
                        config=types.EmbedContentConfig(output_dimensionality=768),
                    )
                break
            except Exception as e:
                if _is_transient_gemini_error(e) and attempt < max_retries:
                    import random
                    delay = delays[min(attempt, len(delays) - 1)] + random.uniform(0, 1)
                    logger.warning(
                        f"[get_embedding_async] Attempt {attempt + 1}/{max_retries + 1} failed (transient), "
                        f"retrying in {delay:.1f}s: {e}"
                    )
                    await asyncio.sleep(delay)
                    continue
                raise
        embedding = result.embeddings[0].values

        # Cache the result
        try:
            await _embedding_cache.set(cache_key, embedding)
            logger.debug(f"[EmbeddingCache] Cache MISS (async) - stored embedding for: '{text[:40]}...'")
        except Exception as cache_err:
            logger.warning(f"[EmbeddingCache] Failed to store embedding: {cache_err}", exc_info=True)

        return embedding

    def get_embeddings_batch(self, texts: List[str]) -> List[List[float]]:
        """Get embeddings for multiple texts."""
        return [self.get_embedding(text) for text in texts]

    async def get_embeddings_batch_async(self, texts: List[str]) -> List[List[float]]:
        """Get embeddings for multiple texts asynchronously (parallel via gather)."""
        embeddings = await asyncio.gather(*[self.get_embedding_async(t) for t in texts])
        return list(embeddings)
