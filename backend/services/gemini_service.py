"""
Gemini Service - Handles all Gemini AI API interactions.

EASY TO MODIFY:
- Change model: Update GEMINI_MODEL in .env
- Adjust prompts: Modify the prompt strings below
- Add new methods: Follow the pattern of existing methods

Uses the new google-genai SDK (unified SDK for Gemini API).
"""
from google import genai
from google.genai import types
from typing import List, Dict, Optional
import json
from core.config import get_settings
from models.chat import IntentExtraction, CoachIntent

settings = get_settings()

# Initialize the Gemini client
client = genai.Client(api_key=settings.gemini_api_key)


class GeminiService:
    """
    Wrapper for Gemini API calls using the new google-genai SDK.

    Usage:
        service = GeminiService()
        response = await service.chat("Hello!")
    """

    def __init__(self):
        self.model = settings.gemini_model
        self.embedding_model = settings.gemini_embedding_model

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

        response = await client.aio.models.generate_content(
            model=self.model,
            contents=contents,
            config=types.GenerateContentConfig(
                system_instruction=system_prompt,
                max_output_tokens=settings.gemini_max_tokens,
                temperature=settings.gemini_temperature,
            ),
        )

        return response.text

    async def extract_intent(self, user_message: str) -> IntentExtraction:
        """
        Extract structured intent from user message using AI.

        MODIFY THIS to change how intents are detected.
        """
        extraction_prompt = '''You are a fitness app intent extraction system. Analyze the user message and extract structured data.

Return ONLY valid JSON in this exact format (no markdown, no explanation):
{
  "intent": "add_exercise|remove_exercise|swap_workout|modify_intensity|reschedule|report_injury|change_setting|navigate|start_workout|complete_workout|log_hydration|question",
  "exercises": ["exercise name 1", "exercise name 2"],
  "muscle_groups": ["chest", "back", "shoulders", "biceps", "triceps", "legs", "core", "glutes"],
  "modification": "easier|harder|shorter|longer",
  "body_part": "shoulder|back|knee|ankle|wrist|elbow|hip|neck",
  "setting_name": "dark_mode|notifications",
  "setting_value": true,
  "destination": "home|library|profile|achievements|hydration|nutrition|summaries",
  "hydration_amount": 8
}

INTENT DEFINITIONS:
- add_exercise: User wants to ADD an exercise (e.g., "add pull-ups", "include bench press")
- remove_exercise: User wants to REMOVE an exercise (e.g., "remove squats", "take out lunges")
- swap_workout: User wants a DIFFERENT workout type (e.g., "not in mood for leg day")
- modify_intensity: User wants to change difficulty/duration (e.g., "make it easier", "too hard")
- reschedule: User wants to change workout timing (e.g., "move to tomorrow")
- report_injury: User mentions pain/injury (e.g., "my shoulder hurts")
- change_setting: User wants to change app settings (e.g., "turn on dark mode", "enable dark theme", "switch to light mode")
- navigate: User wants to go to a specific screen (e.g., "show my achievements", "open nutrition", "go to profile")
- start_workout: User wants to START their workout NOW (e.g., "start my workout", "let's go", "begin workout", "I'm ready")
- complete_workout: User wants to FINISH/COMPLETE their workout (e.g., "I'm done", "finished", "completed my workout", "mark as done")
- log_hydration: User wants to LOG water intake (e.g., "log 8 glasses of water", "I drank 3 cups", "track my water")
- question: General fitness question or unclear intent

SETTING EXTRACTION:
- For dark mode requests: setting_name="dark_mode", setting_value=true
- For light mode requests: setting_name="dark_mode", setting_value=false
- For notification toggles: setting_name="notifications", setting_value=true/false

NAVIGATION EXTRACTION:
- "show achievements" / "my badges" -> destination="achievements"
- "hydration" / "water intake" -> destination="hydration"
- "nutrition" / "my meals" / "calories" -> destination="nutrition"
- "weekly summary" / "my progress" -> destination="summaries"
- "go home" / "main screen" -> destination="home"
- "exercise library" / "browse exercises" -> destination="library"
- "my profile" / "settings" -> destination="profile"

WORKOUT ACTION EXTRACTION:
- "start my workout" / "let's go" / "begin" / "I'm ready" / "start training" -> intent="start_workout"
- "I'm done" / "finished" / "completed" / "mark as done" / "workout complete" -> intent="complete_workout"

HYDRATION EXTRACTION:
- Extract the NUMBER of glasses/cups from the message
- "log 8 glasses of water" -> hydration_amount=8
- "I drank 3 cups" -> hydration_amount=3
- "track 2 glasses" -> hydration_amount=2
- If no number specified, default to hydration_amount=1

User message: "''' + user_message + '"'

        try:
            response = await client.aio.models.generate_content(
                model=self.model,
                contents=extraction_prompt,
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    max_output_tokens=2000,  # Increased for thinking models
                    temperature=0.1,  # Low temp for consistent extraction
                ),
            )

            content = response.text.strip()

            # Clean markdown if present (shouldn't be needed with response_mime_type)
            if content.startswith("```json"):
                content = content[7:]
            elif content.startswith("```"):
                content = content[3:]
            if content.endswith("```"):
                content = content[:-3]

            data = json.loads(content.strip())

            return IntentExtraction(
                intent=CoachIntent(data.get("intent", "question")),
                exercises=[e.lower() for e in data.get("exercises", [])],
                muscle_groups=[m.lower() for m in data.get("muscle_groups", [])],
                modification=data.get("modification"),
                body_part=data.get("body_part"),
                setting_name=data.get("setting_name"),
                setting_value=data.get("setting_value"),
                destination=data.get("destination"),
                hydration_amount=data.get("hydration_amount"),
            )

        except Exception as e:
            print(f"Intent extraction failed: {e}")
            return IntentExtraction(intent=CoachIntent.QUESTION)

    async def extract_exercises_from_response(self, ai_response: str) -> Optional[List[str]]:
        """
        Extract exercise names from the AI's response.

        This is used to ensure the exercises we add/remove match what the AI
        actually mentioned in its response, not just what the user asked for.
        """
        extraction_prompt = f'''Extract ALL exercise names mentioned in this fitness coach response.

Response: "{ai_response}"

Return ONLY a JSON array of exercise names (no explanation, no markdown):
["Exercise 1", "Exercise 2", ...]

IMPORTANT:
- Include ALL exercises mentioned, including compound names like "Cable Woodchoppers"
- Keep the exact exercise names as written
- If no exercises are mentioned, return an empty array: []'''

        try:
            response = await client.aio.models.generate_content(
                model=self.model,
                contents=extraction_prompt,
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    max_output_tokens=2000,  # Increased for thinking models
                    temperature=0.1,
                ),
            )

            content = response.text.strip()

            # Clean markdown if present
            if content.startswith("```json"):
                content = content[7:]
            elif content.startswith("```"):
                content = content[3:]
            if content.endswith("```"):
                content = content[:-3]

            exercises = json.loads(content.strip())

            if isinstance(exercises, list) and len(exercises) > 0:
                return exercises
            return None

        except Exception as e:
            print(f"Exercise extraction from response failed: {e}")
            return None

    def get_embedding(self, text: str) -> List[float]:
        """
        Get embedding vector for text (used for RAG).

        Args:
            text: Text to embed

        Returns:
            Embedding vector as list of floats
        """
        result = client.models.embed_content(
            model=f"models/{self.embedding_model}",
            contents=text
        )
        return result.embeddings[0].values

    async def get_embedding_async(self, text: str) -> List[float]:
        """
        Get embedding vector for text asynchronously.

        Args:
            text: Text to embed

        Returns:
            Embedding vector as list of floats
        """
        result = await client.aio.models.embed_content(
            model=f"models/{self.embedding_model}",
            contents=text
        )
        return result.embeddings[0].values

    def get_embeddings_batch(self, texts: List[str]) -> List[List[float]]:
        """Get embeddings for multiple texts."""
        return [self.get_embedding(text) for text in texts]

    async def get_embeddings_batch_async(self, texts: List[str]) -> List[List[float]]:
        """Get embeddings for multiple texts asynchronously."""
        embeddings = []
        for text in texts:
            emb = await self.get_embedding_async(text)
            embeddings.append(emb)
        return embeddings

    # ============================================
    # Food Analysis Methods
    # ============================================

    async def analyze_food_image(
        self,
        image_base64: str,
        mime_type: str = "image/jpeg",
    ) -> Optional[Dict]:
        """
        Analyze a food image and extract nutrition information using Gemini Vision.

        Args:
            image_base64: Base64 encoded image data
            mime_type: Image MIME type (e.g., 'image/jpeg', 'image/png')

        Returns:
            Dictionary with food_items, total_calories, protein_g, carbs_g, fat_g, fiber_g, feedback
        """
        prompt = '''Analyze this food image and provide detailed nutrition information.

Return ONLY valid JSON in this exact format (no markdown, no explanation):
{
  "food_items": [
    {
      "name": "Food item name",
      "amount": "Estimated portion (e.g., '1 cup', '200g', '1 medium')",
      "calories": 150,
      "protein_g": 10.0,
      "carbs_g": 15.0,
      "fat_g": 5.0
    }
  ],
  "total_calories": 450,
  "protein_g": 25.0,
  "carbs_g": 40.0,
  "fat_g": 15.0,
  "fiber_g": 5.0,
  "feedback": "Brief nutritional feedback about the meal"
}

IMPORTANT:
- Identify ALL visible food items in the image
- Estimate realistic portion sizes based on visual cues
- Use standard USDA nutrition data for calorie/macro estimates
- If you cannot identify the food, make your best educated guess
- Total values should be the sum of individual items
- Provide helpful feedback about the nutritional quality of the meal'''

        try:
            # Create image part from base64
            image_part = types.Part.from_bytes(
                data=__import__('base64').b64decode(image_base64),
                mime_type=mime_type
            )

            response = await client.aio.models.generate_content(
                model=self.model,
                contents=[prompt, image_part],
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    max_output_tokens=2000,
                    temperature=0.3,
                ),
            )

            content = response.text.strip()

            # Clean markdown if present
            if content.startswith("```json"):
                content = content[7:]
            elif content.startswith("```"):
                content = content[3:]
            if content.endswith("```"):
                content = content[:-3]

            return json.loads(content.strip())

        except Exception as e:
            print(f"Food image analysis failed: {e}")
            return None

    async def parse_food_description(self, description: str) -> Optional[Dict]:
        """
        Parse a text description of food and extract nutrition information.

        Args:
            description: Natural language description of food
                        (e.g., "2 eggs, toast with butter, and orange juice")

        Returns:
            Dictionary with food_items, total_calories, protein_g, carbs_g, fat_g, fiber_g, feedback
        """
        prompt = f'''Parse this food description and provide detailed nutrition information.

Food description: "{description}"

Return ONLY valid JSON in this exact format (no markdown, no explanation):
{{
  "food_items": [
    {{
      "name": "Food item name",
      "amount": "Portion from description or reasonable default",
      "calories": 150,
      "protein_g": 10.0,
      "carbs_g": 15.0,
      "fat_g": 5.0
    }}
  ],
  "total_calories": 450,
  "protein_g": 25.0,
  "carbs_g": 40.0,
  "fat_g": 15.0,
  "fiber_g": 5.0,
  "feedback": "Brief nutritional feedback about the meal"
}}

IMPORTANT:
- Extract ALL food items mentioned in the description
- Use quantities specified (e.g., "2 eggs" = 2 large eggs)
- If no quantity specified, assume a standard single serving
- Use standard USDA nutrition data for calorie/macro estimates
- Total values should be the sum of individual items
- Account for preparation methods mentioned (e.g., "fried" vs "boiled")
- Provide helpful feedback about the nutritional quality'''

        try:
            response = await client.aio.models.generate_content(
                model=self.model,
                contents=prompt,
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    max_output_tokens=2000,
                    temperature=0.3,
                ),
            )

            content = response.text.strip()

            # Clean markdown if present
            if content.startswith("```json"):
                content = content[7:]
            elif content.startswith("```"):
                content = content[3:]
            if content.endswith("```"):
                content = content[:-3]

            return json.loads(content.strip())

        except Exception as e:
            print(f"Food description parsing failed: {e}")
            return None

    def _get_holiday_theme(self, workout_date: Optional[str] = None) -> Optional[str]:
        """
        Check if workout date is near a holiday and return themed naming suggestions.
        Returns None if no holiday nearby.
        """
        from datetime import datetime, timedelta

        if not workout_date:
            check_date = datetime.now()
        else:
            try:
                check_date = datetime.fromisoformat(workout_date.replace('Z', '+00:00'))
            except:
                check_date = datetime.now()

        month, day = check_date.month, check_date.day

        # Define holidays with a 7-day window before/after
        holidays = {
            # US Holidays
            (1, 1): ("New Year", "Fresh Start, Resolution, New Year, Midnight"),
            (2, 14): ("Valentine's Day", "Heart, Love, Cupid, Valentine"),
            (3, 17): ("St Patrick's Day", "Lucky, Shamrock, Irish, Green"),
            (7, 4): ("Independence Day", "Freedom, Firework, Liberty, Patriot"),
            (10, 31): ("Halloween", "Monster, Spooky, Beast, Phantom"),
            (11, 11): ("Veterans Day", "Warrior, Honor, Hero, Valor"),
            (12, 25): ("Christmas", "Blitzen, Reindeer, Jolly, Frost"),
            (12, 31): ("New Year's Eve", "Countdown, Finale, Midnight, Resolution"),
        }

        # Check for Thanksgiving week (Nov 20-28)
        if month == 11 and 20 <= day <= 28:
            return "🦃 THANKSGIVING WEEK! Consider festive names like: 'Turkey Burn Legs', 'Grateful Grind Core', 'Feast Mode Arms', 'Pilgrim Power Back'"

        # Check each holiday with 7-day window
        for (h_month, h_day), (holiday_name, words) in holidays.items():
            holiday_date = check_date.replace(month=h_month, day=h_day)
            days_diff = abs((check_date - holiday_date).days)

            if days_diff <= 7:
                return f"🎉 {holiday_name.upper()} WEEK! Consider festive themed words: {words}. Example: '{words.split(', ')[0]} Power Legs'"

        return None

    async def generate_workout_plan(
        self,
        fitness_level: str,
        goals: List[str],
        equipment: List[str],
        duration_minutes: int = 45,
        focus_areas: Optional[List[str]] = None,
        avoid_name_words: Optional[List[str]] = None,
        workout_date: Optional[str] = None,
        age: Optional[int] = None,
        activity_level: Optional[str] = None
    ) -> Dict:
        """
        Generate a personalized workout plan using AI.

        Args:
            fitness_level: beginner, intermediate, or advanced
            goals: List of fitness goals
            equipment: List of available equipment
            duration_minutes: Target workout duration
            focus_areas: Optional specific areas to focus on
            avoid_name_words: Optional list of words to avoid in the workout name (for variety)
            workout_date: Optional date for the workout (ISO format) to enable holiday theming
            age: Optional user's age for age-appropriate exercise selection
            activity_level: Optional activity level (sedentary, lightly_active, moderately_active, very_active)

        Returns:
            Dict with workout structure including name, type, difficulty, exercises
        """
        # Determine difficulty based on fitness level
        difficulty = "easy" if fitness_level == "beginner" else ("hard" if fitness_level == "advanced" else "medium")

        # Build avoid words instruction if provided
        avoid_instruction = ""
        if avoid_name_words and len(avoid_name_words) > 0:
            avoid_instruction = f"\n\n⚠️ IMPORTANT: Do NOT use these words in the workout name (they've been used recently): {', '.join(avoid_name_words)}"

        # Check for holiday theming
        holiday_theme = self._get_holiday_theme(workout_date)
        holiday_instruction = f"\n\n{holiday_theme}" if holiday_theme else ""

        # Build age and activity level context
        age_activity_context = ""
        if age:
            if age < 25:
                age_activity_context += f"\n- Age: {age} (young adult - can handle higher intensity and explosive movements)"
            elif age < 40:
                age_activity_context += f"\n- Age: {age} (adult - balanced approach to intensity)"
            elif age < 55:
                age_activity_context += f"\n- Age: {age} (middle-aged - focus on joint-friendly exercises, longer warm-ups)"
            else:
                age_activity_context += f"\n- Age: {age} (senior - prioritize low-impact, balance exercises, avoid high-impact jumping)"

        if activity_level:
            activity_descriptions = {
                'sedentary': 'sedentary (new to exercise - start slow, more rest periods)',
                'lightly_active': 'lightly active (exercises 1-3 days/week - moderate intensity)',
                'moderately_active': 'moderately active (exercises 3-5 days/week - can handle challenging workouts)',
                'very_active': 'very active (exercises 6-7 days/week - high intensity appropriate)'
            }
            activity_desc = activity_descriptions.get(activity_level, activity_level)
            age_activity_context += f"\n- Activity Level: {activity_desc}"

        prompt = f"""Generate a {duration_minutes}-minute workout plan for a user with:
- Fitness Level: {fitness_level}
- Goals: {', '.join(goals) if goals else 'General fitness'}
- Available Equipment: {', '.join(equipment) if equipment else 'Bodyweight only'}
- Focus Areas: {', '.join(focus_areas) if focus_areas else 'Full body'}{age_activity_context}

Return a valid JSON object with this exact structure:
{{
  "name": "A CREATIVE, UNIQUE workout name ENDING with body part focus (e.g., 'Thunder Legs', 'Phoenix Chest', 'Cobra Back')",
  "type": "strength",
  "difficulty": "{difficulty}",
  "duration_minutes": {duration_minutes},
  "target_muscles": ["Primary muscle 1", "Primary muscle 2"],
  "exercises": [
    {{
      "name": "Exercise name",
      "sets": 3,
      "reps": 12,
      "rest_seconds": 60,
      "equipment": "equipment used or bodyweight",
      "muscle_group": "primary muscle targeted",
      "notes": "Form tips or modifications"
    }}
  ],
  "notes": "Overall workout tips including warm-up and cool-down recommendations"
}}

🎯 WORKOUT NAME - BE EXTREMELY CREATIVE:
Create a name that makes users PUMPED to work out! Use diverse vocabulary:

ACTION WORDS (pick creatively):
- Power: Blitz, Surge, Blast, Strike, Rush, Bolt, Flash, Charge, Jolt, Spark
- Intensity: Inferno, Blaze, Scorch, Burn, Fire, Flame, Heat, Ember, Torch, Ignite
- Nature: Storm, Thunder, Lightning, Hurricane, Tornado, Avalanche, Earthquake, Tsunami, Cyclone, Tempest
- Force: Crush, Smash, Shatter, Break, Demolish, Destroy, Wreck, Obliterate, Annihilate, Pulverize
- Speed: Sprint, Dash, Zoom, Rocket, Jet, Turbo, Hyper, Sonic, Rapid, Swift
- Combat: Warrior, Gladiator, Viking, Spartan, Samurai, Ninja, Knight, Conqueror, Champion, Fighter
- Animal: Wolf, Lion, Tiger, Bear, Hawk, Eagle, Dragon, Phoenix, Panther, Cobra
- Mythic: Titan, Atlas, Zeus, Thor, Hercules, Apollo, Odin, Valkyrie, Olympus, Valhalla

⚠️ CRITICAL NAMING RULES:
1. Name MUST be 3-4 words
2. Name MUST end with the body part/muscle focus
3. Be creative and motivating!

EXAMPLES OF GOOD 3-4 WORD NAMES:
- "Savage Wolf Legs" ✓ (3 words, ends with body part)
- "Iron Phoenix Chest" ✓ (3 words, ends with body part)
- "Thunder Strike Back" ✓ (3 words, ends with body part)
- "Mighty Storm Core" ✓ (3 words, ends with body part)
- "Ultimate Power Shoulders" ✓ (3 words, ends with body part)
- "Blazing Beast Glutes" ✓ (3 words, ends with body part)

BAD EXAMPLES:
- "Thunder Legs" ✗ (only 2 words!)
- "Blitz Panther Pounce" ✗ (no body part!)
- "Wolf" ✗ (too short, no body part!)

BODY PARTS TO END WITH:
- Upper: Chest, Back, Shoulders, Arms, Biceps, Triceps
- Core: Core, Abs, Obliques
- Lower: Legs, Quads, Glutes, Hamstrings, Calves
- Full: Full Body, Total Body

FORMAT: [Adjective/Action] + [Animal/Mythic/Theme] + [Body Part]
- "Raging Bull Legs", "Silent Ninja Back", "Golden Phoenix Chest"
- "Explosive Tiger Core", "Relentless Warrior Arms", "Primal Beast Shoulders"
{holiday_instruction}{avoid_instruction}

Requirements:
- Include 5-8 exercises appropriate for {fitness_level} fitness level
- ONLY use equipment from this list: {', '.join(equipment) if equipment else 'bodyweight'}
- For beginners: focus on form, include more rest, simpler movements
- For intermediate: balanced challenge, compound movements
- For advanced: higher intensity, complex movements, less rest
- Align exercise selection with goals: {', '.join(goals) if goals else 'general fitness'}
- Include variety - don't repeat the same movement pattern
- Each exercise should have helpful form notes"""

        try:
            response = await client.aio.models.generate_content(
                model=self.model,
                contents=prompt,
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    temperature=0.7,  # Higher creativity for unique workout names
                    max_output_tokens=4000  # Increased for detailed workout plans
                ),
            )

            content = response.text.strip()

            # Clean markdown code blocks if present (shouldn't be needed with response_mime_type)
            if content.startswith("```json"):
                content = content[7:]
            elif content.startswith("```"):
                content = content[3:]
            if content.endswith("```"):
                content = content[:-3]

            workout_data = json.loads(content.strip())

            # Validate required fields
            if "exercises" not in workout_data or not workout_data["exercises"]:
                raise ValueError("AI response missing exercises")

            return workout_data

        except json.JSONDecodeError as e:
            print(f"Failed to parse AI workout response: {e}")
            raise ValueError(f"AI returned invalid JSON: {e}")
        except Exception as e:
            print(f"Workout generation failed: {e}")
            raise

    async def generate_workout_from_library(
        self,
        exercises: List[Dict],
        fitness_level: str,
        goals: List[str],
        duration_minutes: int = 45,
        focus_areas: Optional[List[str]] = None,
        avoid_name_words: Optional[List[str]] = None,
        workout_date: Optional[str] = None,
        age: Optional[int] = None,
        activity_level: Optional[str] = None
    ) -> Dict:
        """
        Generate a workout plan using exercises from the exercise library.

        Instead of having AI invent exercises, this method takes pre-selected
        exercises from the library and asks AI to create a creative workout
        name and organize them appropriately.

        Args:
            exercises: List of exercises from the exercise library
            fitness_level: beginner, intermediate, or advanced
            goals: List of fitness goals
            duration_minutes: Target workout duration
            focus_areas: Optional specific areas to focus on
            avoid_name_words: Words to avoid in workout name
            workout_date: Optional date for holiday theming
            age: Optional user's age for age-appropriate adjustments
            activity_level: Optional activity level

        Returns:
            Dict with workout structure
        """
        if not exercises:
            raise ValueError("No exercises provided")

        difficulty = "easy" if fitness_level == "beginner" else ("hard" if fitness_level == "advanced" else "medium")

        # Build avoid words instruction
        avoid_instruction = ""
        if avoid_name_words and len(avoid_name_words) > 0:
            avoid_instruction = f"\n\n⚠️ Do NOT use these words in the workout name: {', '.join(avoid_name_words[:15])}"

        # Check for holiday theming
        holiday_theme = self._get_holiday_theme(workout_date)
        holiday_instruction = f"\n\n{holiday_theme}" if holiday_theme else ""

        # Format exercises for the prompt
        exercise_list = "\n".join([
            f"- {ex.get('name', 'Unknown')}: targets {ex.get('muscle_group', 'unknown')}, equipment: {ex.get('equipment', 'bodyweight')}"
            for ex in exercises
        ])

        prompt = f"""I have selected these exercises for a {duration_minutes}-minute {focus_areas[0] if focus_areas else 'full body'} workout:

{exercise_list}

User profile:
- Fitness Level: {fitness_level}
- Goals: {', '.join(goals) if goals else 'General fitness'}

Create a CREATIVE and MOTIVATING workout name (3-4 words) that ends with the body part focus.

Examples of good names:
- "Thunder Strike Legs"
- "Phoenix Power Chest"
- "Savage Wolf Back"
- "Iron Storm Arms"
{holiday_instruction}{avoid_instruction}

Return a JSON object with:
{{
  "name": "Your creative workout name here",
  "type": "strength",
  "difficulty": "{difficulty}",
  "notes": "A brief motivational tip for this workout (1-2 sentences)"
}}"""

        try:
            response = await client.aio.models.generate_content(
                model=self.model,
                contents=prompt,
                config=types.GenerateContentConfig(
                    system_instruction="You are a creative fitness coach. Generate motivating workout names. Return ONLY valid JSON.",
                    response_mime_type="application/json",
                    temperature=0.8,
                    max_output_tokens=2000  # Increased for thinking models
                ),
            )

            content = response.text.strip()

            # Clean markdown
            if content.startswith("```json"):
                content = content[7:]
            elif content.startswith("```"):
                content = content[3:]
            if content.endswith("```"):
                content = content[:-3]

            ai_response = json.loads(content.strip())

            # Combine AI response with our exercises
            return {
                "name": ai_response.get("name", "Power Workout"),
                "type": ai_response.get("type", "strength"),
                "difficulty": difficulty,
                "duration_minutes": duration_minutes,
                "target_muscles": list(set([ex.get('muscle_group', '') for ex in exercises if ex.get('muscle_group')])),
                "exercises": exercises,
                "notes": ai_response.get("notes", "Focus on proper form and controlled movements.")
            }

        except Exception as e:
            print(f"Error generating workout name: {e}")
            raise  # No fallback - let errors propagate

    async def generate_workout_summary(
        self,
        workout_name: str,
        exercises: List[Dict],
        target_muscles: List[str],
        user_goals: List[str],
        fitness_level: str,
        workout_id: str = None,
        duration_minutes: int = 45,
        workout_type: str = None,
        difficulty: str = None
    ) -> str:
        """
        Generate an AI summary/description of a workout using the Workout Insights agent.

        Args:
            workout_name: Name of the workout
            exercises: List of exercises with their details
            target_muscles: Target muscle groups
            user_goals: User's fitness goals
            fitness_level: User's fitness level
            workout_id: Optional workout ID
            duration_minutes: Workout duration in minutes
            workout_type: Type of workout (strength, cardio, etc.)
            difficulty: Difficulty level

        Returns:
            Plain-text workout summary (2-3 sentences, no markdown)
        """
        try:
            # Use the Workout Insights LangGraph agent
            from services.langgraph_agents.workout_insights.graph import generate_workout_insights

            summary = await generate_workout_insights(
                workout_id=workout_id or "unknown",
                workout_name=workout_name,
                exercises=exercises,
                duration_minutes=duration_minutes,
                workout_type=workout_type,
                difficulty=difficulty,
                user_goals=user_goals,
                fitness_level=fitness_level,
            )

            return summary

        except Exception as e:
            print(f"Error generating workout summary with agent: {e}")
            raise  # No fallback - let errors propagate

    def get_agent_personality(self, agent_type: str = "coach") -> dict:
        """
        Get agent-specific personality settings.

        Returns dict with:
        - name: Agent display name
        - emoji: Agent emoji
        - greeting: How the agent greets users
        - personality: Core personality traits
        - expertise: What the agent specializes in
        """
        agents = {
            "coach": {
                "name": "AI Coach",
                "emoji": "🏋️",
                "greeting": "Hey there! I'm your AI Fitness Coach.",
                "personality": "motivating, supportive, and knowledgeable about all aspects of fitness",
                "expertise": "workout planning, exercise form, fitness motivation, and overall wellness",
                "color": "cyan",
            },
            "nutrition": {
                "name": "Nutrition Expert",
                "emoji": "🥗",
                "greeting": "Hi! I'm your Nutrition Expert.",
                "personality": "friendly, health-conscious, and passionate about balanced eating",
                "expertise": "meal planning, macros, pre/post workout nutrition, healthy recipes, and dietary advice",
                "color": "green",
            },
            "workout": {
                "name": "Workout Specialist",
                "emoji": "💪",
                "greeting": "What's up! I'm your Workout Specialist.",
                "personality": "energetic, technical, and focused on proper form and technique",
                "expertise": "exercise selection, workout modifications, muscle targeting, and training techniques",
                "color": "orange",
            },
            "injury": {
                "name": "Recovery Advisor",
                "emoji": "🏥",
                "greeting": "Hello! I'm your Recovery Advisor.",
                "personality": "caring, cautious, and focused on safe recovery and injury prevention",
                "expertise": "injury prevention, recovery exercises, stretching, mobility work, and safe modifications",
                "color": "pink",
            },
            "hydration": {
                "name": "Hydration Coach",
                "emoji": "💧",
                "greeting": "Hey! I'm your Hydration Coach.",
                "personality": "refreshing, encouraging, and focused on optimal hydration",
                "expertise": "water intake tracking, hydration timing, electrolytes, and performance hydration",
                "color": "blue",
            },
        }
        return agents.get(agent_type, agents["coach"])

    def get_coach_system_prompt(self, context: str = "", intent: str = None, action_context: dict = None, agent_type: str = "coach") -> str:
        """
        Get the system prompt for the AI coach.

        MODIFY THIS to change the coach's personality/behavior.

        Args:
            context: Current context information
            intent: Detected intent for action acknowledgment
            action_context: Context for the action taken
            agent_type: Type of agent (coach, nutrition, workout, injury, hydration)
        """
        # Get agent-specific personality
        agent = self.get_agent_personality(agent_type)

        # Build action acknowledgment based on intent
        action_acknowledgment = ""
        if intent and action_context:
            if intent == "change_setting":
                setting = action_context.get("setting_name", "")
                value = action_context.get("setting_value", True)
                if setting == "dark_mode":
                    mode = "dark mode" if value else "light mode"
                    action_acknowledgment = f"\n\nACTION TAKEN: You have just switched the app to {mode}. Acknowledge this change naturally and confirm it's done."
            elif intent == "navigate":
                dest = action_context.get("destination", "")
                dest_names = {
                    "home": "home screen",
                    "library": "exercise library",
                    "profile": "profile",
                    "achievements": "achievements",
                    "hydration": "hydration tracker",
                    "nutrition": "nutrition tracker",
                    "summaries": "workout summaries"
                }
                dest_name = dest_names.get(dest, dest)
                action_acknowledgment = f"\n\nACTION TAKEN: You are navigating the user to {dest_name}. Acknowledge this naturally."
            elif intent == "start_workout":
                action_acknowledgment = "\n\nACTION TAKEN: You are starting the user's workout. Motivate them and wish them a great session!"
            elif intent == "complete_workout":
                action_acknowledgment = "\n\nACTION TAKEN: You have marked the user's workout as complete. Congratulate them on finishing!"
            elif intent == "log_hydration":
                amount = action_context.get("hydration_amount", 1)
                action_acknowledgment = f"\n\nACTION TAKEN: You have logged {amount} glass(es) of water for the user. Acknowledge this and encourage good hydration habits."

        # Agent-specific introduction
        agent_intro = f'''{agent["emoji"]} YOU ARE: {agent["name"]}
Your personality is {agent["personality"]}.
You specialize in {agent["expertise"]}.

When greeting users or introducing yourself, say something like: "{agent["greeting"]}"
'''

        return f'''{agent_intro}

You are an expert AI fitness coach. Your role is to:

1. Help users with their fitness journey
2. Modify workouts based on their needs instantly
3. Understand and remember injuries and adjust exercises accordingly
4. Be empathetic, supportive, and motivating
5. Respond naturally in conversation, never output raw JSON

APP CONTROL CAPABILITIES:
You CAN control the app! When users ask you to:
- Change to dark/light mode: You will change it automatically
- Navigate to screens (achievements, hydration, nutrition, etc.): You will navigate them there
- Start their workout: You will begin the workout session
- Complete/finish their workout: You will mark it as done
- Log water intake: You will track their hydration

Always acknowledge when you've taken an action. Don't say you can't do something if it's in your capabilities.
{action_acknowledgment}

CURRENT CONTEXT:
{context}

RESPONSE FORMAT:
- Always respond in natural, conversational language
- Be concise and actionable
- Show empathy and understanding
- When making workout changes, explain what you're doing and why
- Never output raw JSON or technical data to the user
- IMPORTANT: When mentioning workout dates, ALWAYS include the day of the week (e.g., "Friday, November 28th" or "this Friday (Nov 28)"), not just the raw date format

Remember: You're a supportive coach, not a robot. Be human, be helpful, be motivating!'''


# Backward compatibility alias
OpenAIService = GeminiService
