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
import logging
from core.config import get_settings
from models.chat import IntentExtraction, CoachIntent

settings = get_settings()
logger = logging.getLogger("gemini")

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
            logger.error(f"Food image analysis failed: {e}")
            logger.exception("Full traceback:")
            return None

    async def parse_food_description(
        self,
        description: str,
        user_goals: Optional[List[str]] = None,
        nutrition_targets: Optional[Dict] = None,
        rag_context: Optional[str] = None
    ) -> Optional[Dict]:
        """
        Parse a text description of food and extract nutrition information with goal-based rankings.

        Args:
            description: Natural language description of food
                        (e.g., "2 eggs, toast with butter, and orange juice")
            user_goals: List of user fitness goals (e.g., ["build_muscle", "lose_weight"])
            nutrition_targets: Dict with daily_calorie_target, daily_protein_target_g, etc.
            rag_context: Optional RAG context from ChromaDB for personalized feedback

        Returns:
            Dictionary with food_items (with rankings), total_calories, macros, ai_suggestion, etc.
        """
        # Build user context section for goal-based scoring
        user_context = ""
        if user_goals or nutrition_targets:
            user_context = "\nUSER FITNESS CONTEXT:\n"
            if user_goals:
                user_context += f"- Fitness Goals: {', '.join(user_goals)}\n"
            if nutrition_targets:
                if nutrition_targets.get('daily_calorie_target'):
                    user_context += f"- Daily Calorie Target: {nutrition_targets['daily_calorie_target']} kcal\n"
                if nutrition_targets.get('daily_protein_target_g'):
                    user_context += f"- Daily Protein Target: {nutrition_targets['daily_protein_target_g']}g\n"
                if nutrition_targets.get('daily_carbs_target_g'):
                    user_context += f"- Daily Carbs Target: {nutrition_targets['daily_carbs_target_g']}g\n"
                if nutrition_targets.get('daily_fat_target_g'):
                    user_context += f"- Daily Fat Target: {nutrition_targets['daily_fat_target_g']}g\n"

        # Add RAG context if available
        rag_section = ""
        if rag_context:
            rag_section = f"\nNUTRITION KNOWLEDGE CONTEXT:\n{rag_context}\n"

        # Build scoring criteria based on goals
        scoring_criteria = """
GOAL-BASED SCORING CRITERIA (score each food 1-10):
- "build_muscle" / "gain_muscle": High score for high protein (>20g/serving), moderate carbs, quality proteins
- "lose_weight" / "fat_loss": High score for low calorie density, high fiber, high protein, whole foods
- "improve_endurance": High score for complex carbs, moderate protein, sustained energy foods
- "general_fitness" / "stay_active": High score for balanced macros, whole foods, nutrient density
- "maintain_weight": High score for appropriate calorie density, balanced nutrition

HEALTH FLAGS TO DETECT:
- High sodium (>500mg/serving): Flag as warning
- High added sugar (>10g/serving): Flag as warning
- Highly processed foods: Flag as warning
- High protein content: Flag as positive for muscle building
- High fiber content: Flag as positive for weight loss/health
- Whole food/unprocessed: Flag as positive"""

        # Choose response format based on whether we have user context
        if user_goals or nutrition_targets:
            response_format = '''{{
  "food_items": [
    {{
      "name": "Food item name",
      "amount": "Portion from description or reasonable default",
      "calories": 150,
      "protein_g": 10.0,
      "carbs_g": 15.0,
      "fat_g": 5.0,
      "fiber_g": 2.0,
      "goal_score": 8,
      "goal_alignment": "excellent",
      "reason": "High protein content supports your muscle building goal"
    }}
  ],
  "total_calories": 450,
  "protein_g": 25.0,
  "carbs_g": 40.0,
  "fat_g": 15.0,
  "fiber_g": 5.0,
  "overall_meal_score": 7,
  "health_score": 8,
  "goal_alignment_percentage": 75,
  "ai_suggestion": "Great protein choice! Consider adding vegetables for more fiber and micronutrients.",
  "encouragements": ["High protein intake - excellent for muscle building!", "Good portion control"],
  "warnings": ["High sodium content - consider low-sodium alternatives"],
  "recommended_swap": "Try brown rice instead of white rice for more fiber and sustained energy."
}}'''
        else:
            response_format = '''{{
  "food_items": [
    {{
      "name": "Food item name",
      "amount": "Portion from description or reasonable default",
      "calories": 150,
      "protein_g": 10.0,
      "carbs_g": 15.0,
      "fat_g": 5.0,
      "fiber_g": 2.0
    }}
  ],
  "total_calories": 450,
  "protein_g": 25.0,
  "carbs_g": 40.0,
  "fat_g": 15.0,
  "fiber_g": 5.0,
  "health_score": 7,
  "ai_suggestion": "Brief nutritional feedback about the meal"
}}'''

        prompt = f'''Parse this food description and provide detailed nutrition information with goal-based analysis.

Food description: "{description}"
{user_context}
{rag_section}
{scoring_criteria if user_goals else ""}

Return ONLY valid JSON in this exact format (no markdown, no explanation):
{response_format}

IMPORTANT:
- Extract ALL food items mentioned in the description
- Use quantities specified (e.g., "2 eggs" = 2 large eggs)
- If no quantity specified, assume a standard single serving
- Use standard USDA nutrition data for calorie/macro estimates
- Total values should be the sum of individual items
- Account for preparation methods mentioned (e.g., "fried" vs "boiled")
- goal_score: 1-10 based on how well the food aligns with user's specific goals
- goal_alignment: "excellent" (8-10), "good" (6-7), "neutral" (4-5), "poor" (1-3)
- reason: Brief explanation of why the food scored that way for the user's goals
- overall_meal_score: Weighted average of individual food scores
- goal_alignment_percentage: 0-100% indicating overall meal alignment with goals
- encouragements: Array of positive aspects (what's helping their goals)
- warnings: Array of concerns (high sodium, sugar, processed, etc.)
- recommended_swap: Specific healthier alternative suggestion'''

        # Retry logic for intermittent Gemini failures
        max_retries = 3
        last_error = None
        content = ""

        for attempt in range(max_retries):
            try:
                print(f"🔍 [Gemini] Parsing food description (attempt {attempt + 1}/{max_retries}): {description[:100]}...")
                response = await client.aio.models.generate_content(
                    model=self.model,
                    contents=prompt,
                    config=types.GenerateContentConfig(
                        response_mime_type="application/json",
                        max_output_tokens=4096,  # Increased from 2000 to prevent truncation
                        temperature=0.3,
                    ),
                )

                content = response.text.strip() if response.text else ""
                print(f"🔍 [Gemini] Raw response: {content[:500]}...")

                if not content:
                    print(f"⚠️ [Gemini] Empty response from API (attempt {attempt + 1})")
                    last_error = "Empty response"
                    continue

                # Parse with robust JSON extraction
                result = self._extract_json_robust(content)
                if result and result.get('food_items'):
                    print(f"✅ [Gemini] Parsed {len(result.get('food_items', []))} food items")
                    return result
                else:
                    print(f"⚠️ [Gemini] Failed to extract valid JSON with food_items (attempt {attempt + 1})")
                    last_error = "No food_items in response"
                    continue

            except json.JSONDecodeError as e:
                print(f"⚠️ [Gemini] JSON parsing failed (attempt {attempt + 1}): {e}")
                last_error = str(e)
                continue
            except Exception as e:
                print(f"⚠️ [Gemini] Food description parsing failed (attempt {attempt + 1}): {e}")
                last_error = str(e)
                continue

        # All retries exhausted
        print(f"❌ [Gemini] All {max_retries} attempts failed. Last error: {last_error}")
        print(f"❌ [Gemini] Last content was: {content[:500] if content else 'empty'}")
        return None

    def _extract_json_robust(self, content: str) -> Optional[Dict]:
        """
        Robustly extract and parse JSON from Gemini response.
        Handles various edge cases like markdown wrappers, trailing commas, and malformed responses.
        """
        import re

        if not content:
            return None

        original_content = content

        # Step 1: Remove markdown code blocks
        if content.startswith("```json"):
            content = content[7:]
        elif content.startswith("```"):
            content = content[3:]
        if content.endswith("```"):
            content = content[:-3]
        content = content.strip()

        # Step 2: Try direct parse first
        try:
            return json.loads(content)
        except json.JSONDecodeError:
            pass

        # Step 3: Find JSON object boundaries (outermost { and })
        first_brace = content.find('{')
        last_brace = content.rfind('}')
        if first_brace != -1 and last_brace != -1 and last_brace > first_brace:
            json_str = content[first_brace:last_brace + 1]
            try:
                return json.loads(json_str)
            except json.JSONDecodeError:
                pass

            # Step 4: Fix common JSON issues
            fixed_json = json_str

            # Remove trailing commas before } or ]
            fixed_json = re.sub(r',\s*([}\]])', r'\1', fixed_json)

            # Fix reversed JSON format (where Gemini outputs properties in reverse)
            # This handles the case where content looks like: "value": ..., "key"
            # Try to detect and fix property order issues

            try:
                return json.loads(fixed_json)
            except json.JSONDecodeError:
                pass

            # Step 5: Try to parse with Python's ast for more flexibility
            try:
                import ast
                # Replace JSON literals with Python equivalents
                python_str = fixed_json.replace('true', 'True').replace('false', 'False').replace('null', 'None')
                result = ast.literal_eval(python_str)
                if isinstance(result, dict):
                    return result
            except (SyntaxError, ValueError):
                pass

        # Step 6: If all else fails, try regex extraction for key fields
        print(f"⚠️ [Gemini] Attempting regex-based JSON recovery...")
        try:
            # Try to extract food_items array
            food_items_match = re.search(r'"food_items"\s*:\s*\[(.*?)\]', content, re.DOTALL)
            if food_items_match:
                # Try to manually build a valid response
                items_str = food_items_match.group(1)
                # Extract individual food objects
                food_objects = []
                obj_pattern = r'\{[^{}]*\}'
                for obj_match in re.finditer(obj_pattern, items_str):
                    try:
                        obj = json.loads(obj_match.group())
                        food_objects.append(obj)
                    except json.JSONDecodeError:
                        # Try to fix the individual object
                        obj_str = obj_match.group()
                        obj_str = re.sub(r',\s*([}\]])', r'\1', obj_str)
                        try:
                            obj = json.loads(obj_str)
                            food_objects.append(obj)
                        except:
                            pass

                if food_objects:
                    # Calculate totals from individual items
                    total_calories = sum(item.get('calories', 0) for item in food_objects)
                    total_protein = sum(item.get('protein_g', 0) for item in food_objects)
                    total_carbs = sum(item.get('carbs_g', 0) for item in food_objects)
                    total_fat = sum(item.get('fat_g', 0) for item in food_objects)
                    total_fiber = sum(item.get('fiber_g', 0) for item in food_objects)

                    recovered_result = {
                        "food_items": food_objects,
                        "total_calories": total_calories,
                        "protein_g": total_protein,
                        "carbs_g": total_carbs,
                        "fat_g": total_fat,
                        "fiber_g": total_fiber,
                        "health_score": 5,  # Default neutral score
                        "ai_suggestion": "Unable to fully parse AI response, nutritional values may be approximate."
                    }
                    print(f"✅ [Gemini] Recovered {len(food_objects)} food items via regex extraction")
                    return recovered_result
        except Exception as e:
            print(f"⚠️ [Gemini] Regex recovery failed: {e}")

        print(f"❌ [Gemini] All JSON parsing attempts failed. Content preview: {original_content[:200]}")
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
        activity_level: Optional[str] = None,
        intensity_preference: Optional[str] = None,
        custom_program_description: Optional[str] = None,
        workout_type_preference: Optional[str] = None,
        custom_exercises: Optional[List[Dict]] = None,
        workout_environment: Optional[str] = None,
        equipment_details: Optional[List[Dict]] = None,
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
            intensity_preference: Optional intensity preference (easy, medium, hard) - overrides fitness_level for difficulty
            custom_program_description: Optional user's custom program description (e.g., "Train for HYROX", "Improve box jump height")
            workout_type_preference: Optional workout type preference (strength, cardio, mixed) - affects exercise selection
            custom_exercises: Optional list of user's custom exercises to potentially include
            workout_environment: Optional workout environment (commercial_gym, home_gym, home, outdoors, hotel, etc.)
            equipment_details: Optional detailed equipment info with quantities and weights
                               [{"name": "dumbbells", "quantity": 2, "weights": [15, 25, 40], "weight_unit": "lbs"}]

        Returns:
            Dict with workout structure including name, type, difficulty, exercises
        """
        # Use intensity_preference if provided, otherwise derive from fitness_level
        if intensity_preference:
            difficulty = intensity_preference

            # Warn about potentially dangerous combinations
            if fitness_level == "beginner" and intensity_preference == "hard":
                print(f"⚠️ [Gemini] WARNING: Beginner fitness level with hard intensity preference - ensure exercises are scaled appropriately")
            elif fitness_level == "intermediate" and intensity_preference == "hard":
                print(f"🔍 [Gemini] Note: Intermediate fitness level with hard intensity - will challenge the user")
        else:
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

        # Add safety instruction if there's a mismatch between fitness level and intensity
        safety_instruction = ""
        if fitness_level == "beginner" and difficulty == "hard":
            safety_instruction = "\n\n⚠️ SAFETY NOTE: User is a beginner but wants hard intensity. Choose challenging exercises but ensure proper form is achievable. Include more rest periods and focus on compound movements with moderate weights rather than advanced techniques."

        # Determine workout type (strength, cardio, or mixed)
        # Addresses competitor feedback: "I hate how you can't pick cardio for one of your workouts"
        workout_type = workout_type_preference if workout_type_preference else "strength"
        workout_type_instruction = ""
        if workout_type == "cardio":
            workout_type_instruction = """

🏃 CARDIO WORKOUT TYPE:
This is a CARDIO-focused workout. You MUST:
1. Include time-based exercises (running, cycling, rowing, jump rope)
2. Use duration_seconds instead of reps for cardio exercises (e.g., "30 seconds jump rope")
3. Focus on heart rate elevation and endurance
4. Include intervals if appropriate (e.g., 30s work / 15s rest)
5. Minimize rest periods between exercises (30-45 seconds max)
6. For cardio exercises, use sets=1 and reps=1, with duration_seconds for the work period

CARDIO EXERCISE EXAMPLES:
- Jumping Jacks: 45 duration_seconds, sets=1, reps=1
- High Knees: 30 duration_seconds, sets=3
- Burpees: 20 duration_seconds, sets=4
- Mountain Climbers: 30 duration_seconds, sets=3
- Running in Place: 60 duration_seconds, sets=1
- Jump Rope: 45 duration_seconds, sets=4"""
        elif workout_type == "mixed":
            workout_type_instruction = """

🔥 MIXED WORKOUT TYPE:
This is a MIXED workout combining strength AND cardio. You MUST:
1. Alternate between strength and cardio exercises
2. Include 2-3 cardio bursts between strength sets
3. Use circuit-style training where possible
4. Keep rest periods shorter than pure strength workouts (45-60 seconds)
5. Include both weighted exercises AND time-based cardio movements

STRUCTURE SUGGESTION:
- Start with compound strength movement
- Follow with cardio burst (30-45 seconds)
- Repeat pattern for full workout"""

        # Build custom program instruction if user has specified a custom training goal
        custom_program_instruction = ""
        if custom_program_description and custom_program_description.strip():
            custom_program_instruction = f"""

🎯 CRITICAL - CUSTOM TRAINING PROGRAM:
The user has specified a custom training goal: "{custom_program_description}"

This is the user's PRIMARY training focus. You MUST:
1. Select exercises that directly support this goal
2. Structure sets/reps/rest to match this training style
3. Include skill-specific progressions where applicable
4. Name the workout to reflect this training focus

Examples:
- "Train for HYROX" → Include sled-style pushes, farmer carries, rowing, running intervals
- "Improve box jump height" → Plyometrics, power movements, explosive leg work
- "Prepare for marathon" → Running-focused, leg endurance, core stability
- "Get better at pull-ups" → Back strengthening, lat work, grip training, assisted progressions"""

        # Build custom exercises instruction if user has custom exercises
        custom_exercises_instruction = ""
        if custom_exercises and len(custom_exercises) > 0:
            logger.info(f"🏋️ [Gemini Service] Including {len(custom_exercises)} custom exercises in prompt")
            exercise_list = []
            for ex in custom_exercises:
                name = ex.get("name", "")
                muscle = ex.get("primary_muscle", "")
                equip = ex.get("equipment", "")
                sets = ex.get("default_sets", 3)
                reps = ex.get("default_reps", 10)
                exercise_list.append(f"  - {name} (targets: {muscle}, equipment: {equip}, default: {sets}x{reps})")
                logger.info(f"🏋️ [Gemini Service] Custom exercise: {name} - {muscle}/{equip}")
            custom_exercises_instruction = f"""

🏋️ USER'S CUSTOM EXERCISES:
The user has created these custom exercises. You SHOULD include 1-2 of them if they match the workout focus:
{chr(10).join(exercise_list)}

When including custom exercises, use the user's default sets/reps as a starting point."""
        else:
            logger.info(f"🏋️ [Gemini Service] No custom exercises to include in prompt")

        # Build workout environment instruction if provided
        environment_instruction = ""
        if workout_environment:
            env_descriptions = {
                'commercial_gym': ('🏢 COMMERCIAL GYM', 'Full access to machines, cables, and free weights. Can use any equipment.'),
                'home_gym': ('🏠 HOME GYM', 'Dedicated home gym setup. Focus on free weights and basic equipment available.'),
                'home': ('🏡 HOME (MINIMAL)', 'Limited equipment at home. Prefer bodyweight exercises and minimal equipment.'),
                'outdoors': ('🌳 OUTDOORS', 'Outdoor workout (park, trail). Use bodyweight exercises, running, outdoor-friendly movements.'),
                'hotel': ('🧳 HOTEL/TRAVEL', 'Hotel gym with limited equipment. Focus on bodyweight and dumbbells.'),
                'apartment_gym': ('🏬 APARTMENT GYM', 'Basic apartment building gym. Focus on machines and basic weights.'),
                'office_gym': ('💼 OFFICE GYM', 'Workplace fitness center. Use machines and basic equipment.'),
                'custom': ('⚙️ CUSTOM SETUP', 'User has specific equipment they selected. Use only the equipment listed.'),
            }
            env_name, env_desc = env_descriptions.get(workout_environment, ('', workout_environment))
            if env_name:
                environment_instruction = f"\n- Workout Environment: {env_name} - {env_desc}"

        # Build detailed equipment instruction if provided
        equipment_details_instruction = ""
        if equipment_details and len(equipment_details) > 0:
            logger.info(f"🏋️ [Gemini Service] Including {len(equipment_details)} detailed equipment items in prompt")
            equip_list = []
            for item in equipment_details:
                name = item.get("name", "unknown")
                quantity = item.get("quantity", 1)
                weights = item.get("weights", [])
                unit = item.get("weight_unit", "lbs")
                notes = item.get("notes", "")

                if weights:
                    weights_str = f", weights: {', '.join(str(w) for w in weights)} {unit}"
                else:
                    weights_str = ""

                notes_str = f" ({notes})" if notes else ""
                equip_list.append(f"  - {name}: qty {quantity}{weights_str}{notes_str}")

            equipment_details_instruction = f"""

🏋️ DETAILED EQUIPMENT AVAILABLE:
The user has specified exact equipment with quantities and weights. Use ONLY these items and recommend weights from this list:
{chr(10).join(equip_list)}

When recommending weights for exercises, select from the user's available weights listed above.
If user has multiple weight options, pick appropriate weights based on fitness level and exercise type."""

        # Build focus area instruction based on the training split/focus
        focus_instruction = ""
        if focus_areas and len(focus_areas) > 0:
            focus = focus_areas[0].lower()
            logger.info(f"🎯 [Gemini Service] Workout focus area: {focus}")
            # Map focus areas to strict exercise selection guidelines
            focus_mapping = {
                'push': '🎯 PUSH FOCUS: Select exercises that target chest, shoulders, and triceps. Include bench press variations, shoulder press, push-ups, dips, tricep extensions.',
                'pull': '🎯 PULL FOCUS: Select exercises that target back and biceps. Include rows, pull-ups/lat pulldowns, deadlifts, curls, face pulls.',
                'legs': '🎯 LEG FOCUS: Select exercises that target quads, hamstrings, glutes, and calves. Include squats, lunges, leg press, deadlifts, calf raises.',
                'upper': '🎯 UPPER BODY: Select exercises for chest, back, shoulders, and arms. Mix pushing and pulling movements.',
                'lower': '🎯 LOWER BODY: Select exercises for quads, hamstrings, glutes, and calves. Focus on compound leg movements.',
                'chest': '🎯 CHEST FOCUS: At least 70% of exercises must target chest. Include bench press, flyes, push-ups, cable crossovers.',
                'back': '🎯 BACK FOCUS: At least 70% of exercises must target back. Include rows, pull-ups, lat pulldowns, deadlifts.',
                'shoulders': '🎯 SHOULDER FOCUS: At least 70% of exercises must target shoulders. Include overhead press, lateral raises, front raises, rear delts.',
                'arms': '🎯 ARMS FOCUS: At least 70% of exercises must target biceps and triceps. Include curls, extensions, dips, hammer curls.',
                'core': '🎯 CORE FOCUS: At least 70% of exercises must target abs and obliques. Include planks, crunches, leg raises, russian twists.',
                'glutes': '🎯 GLUTE FOCUS: At least 70% of exercises must target glutes. Include hip thrusts, glute bridges, lunges, deadlifts.',
                'full_body': '🎯 FULL BODY: Include at least one exercise for each major muscle group: chest, back, shoulders, legs, core.',
                'full_body_push': '🎯 FULL BODY with PUSH EMPHASIS: Include exercises for all major muscle groups, but prioritize chest, shoulders, and triceps (at least 50% pushing movements).',
                'full_body_pull': '🎯 FULL BODY with PULL EMPHASIS: Include exercises for all major muscle groups, but prioritize back and biceps (at least 50% pulling movements).',
                'full_body_legs': '🎯 FULL BODY with LEG EMPHASIS: Include exercises for all major muscle groups, but prioritize legs and glutes (at least 50% lower body movements).',
                'full_body_core': '🎯 FULL BODY with CORE EMPHASIS: Include exercises for all major muscle groups, but prioritize core/abs (at least 40% core movements).',
                'full_body_upper': '🎯 FULL BODY with UPPER EMPHASIS: Include exercises for all major muscle groups, but prioritize upper body (at least 60% upper body movements).',
                'full_body_lower': '🎯 FULL BODY with LOWER EMPHASIS: Include exercises for all major muscle groups, but prioritize lower body (at least 60% lower body movements).',
                'full_body_power': '🎯 FULL BODY POWER: Focus on explosive, compound movements across all muscle groups. Include power cleans, box jumps, kettlebell swings.',
                'upper_power': '🎯 UPPER BODY POWER: Heavy compound upper body movements. Lower reps (4-6), higher weight. Include bench press, overhead press, rows.',
                'lower_power': '🎯 LOWER BODY POWER: Heavy compound leg movements. Lower reps (4-6), higher weight. Include squats, deadlifts, leg press.',
                'upper_hypertrophy': '🎯 UPPER BODY HYPERTROPHY: Moderate weight, higher reps (8-12). Focus on time under tension for chest, back, shoulders, arms.',
                'lower_hypertrophy': '🎯 LOWER BODY HYPERTROPHY: Moderate weight, higher reps (8-12). Focus on time under tension for quads, hamstrings, glutes.',
            }
            focus_instruction = focus_mapping.get(focus, f'🎯 FOCUS: {focus.upper()} - Select exercises primarily targeting this area.')

        prompt = f"""Generate a {duration_minutes}-minute workout plan for a user with:
- Fitness Level: {fitness_level}
- Goals: {', '.join(goals) if goals else 'General fitness'}
- Available Equipment: {', '.join(equipment) if equipment else 'Bodyweight only'}
- Focus Areas: {', '.join(focus_areas) if focus_areas else 'Full body'}
- Workout Type: {workout_type}{environment_instruction}{age_activity_context}{safety_instruction}{workout_type_instruction}{custom_program_instruction}{custom_exercises_instruction}{equipment_details_instruction}

⚠️ CRITICAL - MUSCLE GROUP TARGETING:
{focus_instruction if focus_instruction else 'Select a balanced mix of exercises.'}
You MUST follow this focus area strictly. Do NOT give random exercises that don't match the focus.

Return a valid JSON object with this exact structure:
{{
  "name": "A CREATIVE, UNIQUE workout name ENDING with body part focus (e.g., 'Thunder Legs', 'Phoenix Chest', 'Cobra Back')",
  "type": "{workout_type}",
  "difficulty": "{difficulty}",
  "duration_minutes": {duration_minutes},
  "target_muscles": ["Primary muscle 1", "Primary muscle 2"],
  "exercises": [
    {{
      "name": "Exercise name",
      "sets": 3,
      "reps": 12,
      "weight_kg": 10,
      "rest_seconds": 60,
      "duration_seconds": null,
      "equipment": "equipment used or bodyweight",
      "muscle_group": "primary muscle targeted",
      "notes": "Form tips or modifications"
    }}
  ],
  "notes": "Overall workout tips including warm-up and cool-down recommendations"
}}

NOTE: For cardio exercises, use duration_seconds (e.g., 30) instead of reps (set reps to 1).
For strength exercises, set duration_seconds to null and use reps normally.

⚠️ CRITICAL - REALISTIC WEIGHT RECOMMENDATIONS:
For each exercise, include a starting weight_kg that follows industry-standard equipment increments:
- Dumbbell exercises: Use weights in 2.5kg (5lb) increments (2.5, 5, 7.5, 10, 12.5, 15, 17.5, 20...)
- Barbell exercises: Use weights in 2.5kg (5lb) increments
- Machine exercises: Use weights in 5kg (10lb) increments (5, 10, 15, 20, 25...)
- Kettlebell exercises: Use weights in 4kg (8lb) increments (4, 8, 12, 16, 20, 24...)
- Bodyweight exercises: Use weight_kg: 0

Starting weight guidelines by fitness level:
- Beginner: Compound exercises 5-10kg, Isolation exercises 2.5-5kg
- Intermediate: Compound exercises 15-25kg, Isolation exercises 7.5-12.5kg
- Advanced: Compound exercises 30-50kg, Isolation exercises 15-20kg

NEVER recommend unrealistic increments like 2.5 lbs for dumbbells - the minimum is 5 lbs (2.5 kg)!

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

        # Log the full prompt for debugging
        logger.info("=" * 80)
        logger.info("[GEMINI PROMPT - generate_workout_plan]")
        logger.info(f"Parameters: fitness_level={fitness_level}, goals={goals}, equipment={equipment}, duration={duration_minutes}min")
        logger.info(f"Focus areas: {focus_areas}, intensity_preference={intensity_preference}")
        logger.info(f"Custom program description: {custom_program_description}")
        logger.info(f"Age: {age}, Activity level: {activity_level}")
        logger.info("-" * 40)
        logger.info(f"FULL PROMPT:\n{prompt}")
        logger.info("=" * 80)

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

    async def generate_workout_plan_streaming(
        self,
        fitness_level: str,
        goals: List[str],
        equipment: List[str],
        duration_minutes: int = 45,
        focus_areas: Optional[List[str]] = None,
        avoid_name_words: Optional[List[str]] = None,
        workout_date: Optional[str] = None,
        age: Optional[int] = None,
        activity_level: Optional[str] = None,
        intensity_preference: Optional[str] = None
    ):
        """
        Generate a workout plan using streaming for faster perceived response.

        Yields chunks of JSON as they're generated, allowing the client to
        display exercises incrementally.

        Yields:
            str: JSON chunks as they arrive from Gemini
        """
        # Use intensity_preference if provided, otherwise derive from fitness_level
        if intensity_preference:
            difficulty = intensity_preference
        else:
            difficulty = "easy" if fitness_level == "beginner" else ("hard" if fitness_level == "advanced" else "medium")

        avoid_instruction = ""
        if avoid_name_words and len(avoid_name_words) > 0:
            avoid_instruction = f"\n\n⚠️ Do NOT use these words in the workout name: {', '.join(avoid_name_words)}"

        holiday_theme = self._get_holiday_theme(workout_date)
        holiday_instruction = f"\n\n{holiday_theme}" if holiday_theme else ""

        age_activity_context = ""
        if age:
            if age < 25:
                age_activity_context += f"\n- Age: {age} (young adult)"
            elif age < 40:
                age_activity_context += f"\n- Age: {age} (adult)"
            elif age < 55:
                age_activity_context += f"\n- Age: {age} (middle-aged - joint-friendly)"
            else:
                age_activity_context += f"\n- Age: {age} (senior - low-impact)"

        if activity_level:
            activity_descriptions = {
                'sedentary': 'sedentary (start slow)',
                'lightly_active': 'lightly active (moderate intensity)',
                'moderately_active': 'moderately active (challenging workouts)',
                'very_active': 'very active (high intensity)'
            }
            activity_desc = activity_descriptions.get(activity_level, activity_level)
            age_activity_context += f"\n- Activity Level: {activity_desc}"

        prompt = f"""Generate a {duration_minutes}-minute workout for:
- Fitness Level: {fitness_level}
- Goals: {', '.join(goals) if goals else 'General fitness'}
- Equipment: {', '.join(equipment) if equipment else 'Bodyweight only'}
- Focus: {', '.join(focus_areas) if focus_areas else 'Full body'}{age_activity_context}

Return ONLY valid JSON (no markdown):
{{
  "name": "Creative 3-4 word name ending with body part",
  "type": "strength",
  "difficulty": "{difficulty}",
  "duration_minutes": {duration_minutes},
  "target_muscles": ["muscle1", "muscle2"],
  "exercises": [
    {{"name": "Exercise", "sets": 3, "reps": 12, "rest_seconds": 60, "equipment": "equipment", "muscle_group": "muscle", "notes": "tips"}}
  ],
  "notes": "Overall tips"
}}

Include 5-8 exercises for {fitness_level} level using only: {', '.join(equipment) if equipment else 'bodyweight'}
{holiday_instruction}{avoid_instruction}"""

        logger.info(f"[Streaming] Starting workout generation for {fitness_level} user")

        try:
            stream = await client.aio.models.generate_content_stream(
                model=self.model,
                contents=prompt,
                config=types.GenerateContentConfig(
                    temperature=0.7,
                    max_output_tokens=4000
                ),
            )

            async for chunk in stream:
                if chunk.text:
                    yield chunk.text

        except Exception as e:
            logger.error(f"Streaming workout generation failed: {e}")
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
        activity_level: Optional[str] = None,
        intensity_preference: Optional[str] = None,
        custom_program_description: Optional[str] = None,
        workout_type_preference: Optional[str] = None
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
            intensity_preference: Optional intensity preference (easy, medium, hard)
            custom_program_description: Optional user's custom program description (e.g., "Train for HYROX")
            workout_type_preference: Optional workout type preference (strength, cardio, mixed)

        Returns:
            Dict with workout structure
        """
        if not exercises:
            raise ValueError("No exercises provided")

        # Use intensity_preference if provided, otherwise derive from fitness_level
        if intensity_preference:
            difficulty = intensity_preference

            # Warn about potentially dangerous combinations
            if fitness_level == "beginner" and intensity_preference == "hard":
                print(f"⚠️ [Gemini] WARNING: Beginner fitness level with hard intensity preference - ensure exercises are scaled appropriately")
            elif fitness_level == "intermediate" and intensity_preference == "hard":
                print(f"🔍 [Gemini] Note: Intermediate fitness level with hard intensity - will challenge the user")
        else:
            difficulty = "easy" if fitness_level == "beginner" else ("hard" if fitness_level == "advanced" else "medium")

        # Build avoid words instruction
        avoid_instruction = ""
        if avoid_name_words and len(avoid_name_words) > 0:
            avoid_instruction = f"\n\n⚠️ Do NOT use these words in the workout name: {', '.join(avoid_name_words[:15])}"

        # Check for holiday theming
        holiday_theme = self._get_holiday_theme(workout_date)
        holiday_instruction = f"\n\n{holiday_theme}" if holiday_theme else ""

        # Add safety instruction if there's a mismatch between fitness level and intensity
        safety_instruction = ""
        if fitness_level == "beginner" and difficulty == "hard":
            safety_instruction = "\n\n⚠️ SAFETY NOTE: User is a beginner but wants hard intensity. Structure exercises with more rest periods and ensure reps/sets are achievable with proper form. Focus on compound movements rather than advanced techniques."

        # Build custom program context if user has specified a custom training goal
        custom_program_context = ""
        if custom_program_description and custom_program_description.strip():
            custom_program_context = f"\n- Custom Training Goal: {custom_program_description}"

        # Determine workout type
        workout_type = workout_type_preference if workout_type_preference else "strength"

        # Format exercises for the prompt
        exercise_list = "\n".join([
            f"- {ex.get('name', 'Unknown')}: targets {ex.get('muscle_group', 'unknown')}, equipment: {ex.get('equipment', 'bodyweight')}"
            for ex in exercises
        ])

        prompt = f"""I have selected these exercises for a {duration_minutes}-minute {focus_areas[0] if focus_areas else 'full body'} workout:

{exercise_list}

User profile:
- Fitness Level: {fitness_level}
- Goals: {', '.join(goals) if goals else 'General fitness'}{custom_program_context}{safety_instruction}

Create a CREATIVE and MOTIVATING workout name (3-4 words) that reflects the user's training focus.

Examples of good names:
- "Thunder Strike Legs"
- "Phoenix Power Chest"
- "Savage Wolf Back"
- "Iron Storm Arms"
{holiday_instruction}{avoid_instruction}

Return a JSON object with:
{{
  "name": "Your creative workout name here",
  "type": "{workout_type}",
  "difficulty": "{difficulty}",
  "notes": "A brief motivational tip for this workout (1-2 sentences)"
}}"""

        # Log the full prompt for debugging
        logger.info("=" * 80)
        logger.info("[GEMINI PROMPT - generate_workout_from_library]")
        logger.info(f"Parameters: fitness_level={fitness_level}, goals={goals}, duration={duration_minutes}min")
        logger.info(f"Focus areas: {focus_areas}, intensity_preference={intensity_preference}")
        logger.info(f"Custom program description: {custom_program_description}")
        logger.info(f"Exercise count: {len(exercises)}")
        logger.info(f"Exercise names: {[ex.get('name') for ex in exercises]}")
        logger.info("-" * 40)
        logger.info(f"FULL PROMPT:\n{prompt}")
        logger.info("=" * 80)

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


# Singleton instance for services that need it
_gemini_service_instance: Optional[GeminiService] = None


def get_gemini_service() -> GeminiService:
    """Get or create singleton GeminiService instance."""
    global _gemini_service_instance
    if _gemini_service_instance is None:
        _gemini_service_instance = GeminiService()
    return _gemini_service_instance


# Module-level singleton for backward compatibility
gemini_service = GeminiService()
