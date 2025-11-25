"""
OpenAI Service - Handles all OpenAI API interactions.

EASY TO MODIFY:
- Change model: Update OPENAI_MODEL in .env
- Adjust prompts: Modify the prompt strings below
- Add new methods: Follow the pattern of existing methods
"""
from openai import AsyncOpenAI
from typing import List, Dict, Optional
import json
from core.config import get_settings
from models.chat import IntentExtraction, CoachIntent

settings = get_settings()


class OpenAIService:
    """
    Wrapper for OpenAI API calls.

    Usage:
        service = OpenAIService()
        response = await service.chat("Hello!")
    """

    def __init__(self):
        self.client = AsyncOpenAI(api_key=settings.openai_api_key)
        self.model = settings.openai_model
        self.embedding_model = settings.openai_embedding_model

    async def chat(
        self,
        user_message: str,
        system_prompt: Optional[str] = None,
        conversation_history: Optional[List[Dict[str, str]]] = None,
    ) -> str:
        """
        Send a chat message to OpenAI and get a response.

        Args:
            user_message: The user's message
            system_prompt: Optional system prompt for context
            conversation_history: List of previous messages

        Returns:
            AI response string
        """
        messages = []

        # Add system prompt
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})

        # Add conversation history (only role and content for OpenAI)
        if conversation_history:
            messages.extend([
                {"role": msg["role"], "content": msg["content"]}
                for msg in conversation_history
            ])

        # Add current message
        messages.append({"role": "user", "content": user_message})

        response = await self.client.chat.completions.create(
            model=self.model,
            messages=messages,
            max_tokens=settings.openai_max_tokens,
            temperature=settings.openai_temperature,
        )

        return response.choices[0].message.content

    async def extract_intent(self, user_message: str) -> IntentExtraction:
        """
        Extract structured intent from user message using AI.

        MODIFY THIS to change how intents are detected.
        """
        extraction_prompt = '''You are a fitness intent extraction system. Analyze the user message and extract structured data.

Return ONLY valid JSON in this exact format (no markdown, no explanation):
{
  "intent": "add_exercise|remove_exercise|swap_workout|modify_intensity|reschedule|report_injury|question",
  "exercises": ["exercise name 1", "exercise name 2"],
  "muscle_groups": ["chest", "back", "shoulders", "biceps", "triceps", "legs", "core", "glutes"],
  "modification": "easier|harder|shorter|longer",
  "body_part": "shoulder|back|knee|ankle|wrist|elbow|hip|neck"
}

INTENT DEFINITIONS:
- add_exercise: User wants to ADD an exercise (e.g., "add pull-ups", "include bench press")
- remove_exercise: User wants to REMOVE an exercise (e.g., "remove squats", "take out lunges")
- swap_workout: User wants a DIFFERENT workout type (e.g., "not in mood for leg day")
- modify_intensity: User wants to change difficulty/duration (e.g., "make it easier", "too hard")
- reschedule: User wants to change workout timing (e.g., "move to tomorrow")
- report_injury: User mentions pain/injury (e.g., "my shoulder hurts")
- question: General fitness question or unclear intent

User message: "''' + user_message + '"'

        try:
            response = await self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": "You are a JSON extraction system. Return ONLY valid JSON."},
                    {"role": "user", "content": extraction_prompt},
                ],
                max_tokens=300,
                temperature=0.1,  # Low temp for consistent extraction
            )

            content = response.choices[0].message.content.strip()

            # Clean markdown if present
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
            response = await self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": "You are a JSON extraction system. Return ONLY valid JSON arrays."},
                    {"role": "user", "content": extraction_prompt},
                ],
                max_tokens=500,
                temperature=0.1,
            )

            content = response.choices[0].message.content.strip()

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

    async def get_embedding(self, text: str) -> List[float]:
        """
        Get embedding vector for text (used for RAG).

        Args:
            text: Text to embed

        Returns:
            Embedding vector as list of floats
        """
        response = await self.client.embeddings.create(
            model=self.embedding_model,
            input=text,
        )
        return response.data[0].embedding

    async def get_embeddings_batch(self, texts: List[str]) -> List[List[float]]:
        """Get embeddings for multiple texts at once."""
        response = await self.client.embeddings.create(
            model=self.embedding_model,
            input=texts,
        )
        return [item.embedding for item in response.data]

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
            # Thanksgiving (4th Thursday of Nov - approximate with Nov 20-28)
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
        workout_date: Optional[str] = None
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

        prompt = f"""Generate a {duration_minutes}-minute workout plan for a user with:
- Fitness Level: {fitness_level}
- Goals: {', '.join(goals) if goals else 'General fitness'}
- Available Equipment: {', '.join(equipment) if equipment else 'Bodyweight only'}
- Focus Areas: {', '.join(focus_areas) if focus_areas else 'Full body'}

Return ONLY a valid JSON object with this exact structure (no markdown, no explanation):
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
            response = await self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {
                        "role": "system",
                        "content": "You are an expert fitness coach and personal trainer. Generate workout plans in valid JSON format only. No markdown, no explanations - just the JSON object."
                    },
                    {"role": "user", "content": prompt}
                ],
                temperature=0.7,  # Higher creativity for unique workout names
                max_tokens=2000
            )

            content = response.choices[0].message.content.strip()

            # Clean markdown code blocks if present
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

    def get_coach_system_prompt(self, context: str = "") -> str:
        """
        Get the system prompt for the AI coach.

        MODIFY THIS to change the coach's personality/behavior.
        """
        return f'''You are an expert AI fitness coach. Your role is to:

1. Help users with their fitness journey
2. Modify workouts based on their needs instantly
3. Understand and remember injuries and adjust exercises accordingly
4. Be empathetic, supportive, and motivating
5. Respond naturally in conversation, never output raw JSON

CURRENT CONTEXT:
{context}

RESPONSE FORMAT:
- Always respond in natural, conversational language
- Be concise and actionable
- Show empathy and understanding
- When making workout changes, explain what you're doing and why
- Never output raw JSON or technical data to the user

Remember: You're a supportive coach, not a robot. Be human, be helpful, be motivating!'''
