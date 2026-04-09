"""
Gemini Service Meal Plans & Agent Config - Meal planning, agent personality, coach prompts.
"""
import asyncio
import json
import logging
import time
from typing import List, Dict, Optional

from google.genai import types
from core.config import get_settings
from models.gemini_schemas import DailyMealPlanResponse, MealSuggestionsResponse, SnackSuggestionsResponse
from services.gemini.constants import (
    client, _log_token_usage, _gemini_semaphore, settings,
)
from services.gemini.utils import _sanitize_for_prompt, safe_join_list
from core.anonymize import age_to_bracket
from core.ai_response_parser import parse_ai_json

logger = logging.getLogger("gemini")


class MealPlansMixin:
    """Mixin providing meal planning and agent personality methods for GeminiService."""

    async def generate_weekly_holistic_plan(
        self,
        user_profile: Dict,
        workout_days: List[int],
        fasting_protocol: str,
        nutrition_strategy: str,
        nutrition_targets: Dict,
        week_start_date: str,
        preferred_workout_time: str = "17:00",
    ) -> Dict:
        """
        Generate a complete weekly holistic plan integrating workouts, nutrition, and fasting.

        Args:
            user_profile: User's fitness profile (level, goals, equipment, age, restrictions)
            workout_days: Days of week for training (0=Monday, 6=Sunday)
            fasting_protocol: Fasting protocol (16:8, 18:6, OMAD, etc.)
            nutrition_strategy: Strategy (workout_aware, static, cutting, bulking, maintenance)
            nutrition_targets: Base nutrition targets (calories, protein_g, carbs_g, fat_g)
            week_start_date: Start date of the week (YYYY-MM-DD)
            preferred_workout_time: Preferred workout time (HH:MM)

        Returns:
            Dict with weekly plan structure including daily entries
        """
        day_names = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        workout_day_names = [day_names[d] for d in workout_days if 0 <= d < 7]

        prompt = f'''Generate a complete weekly holistic fitness plan coordinating workouts, nutrition, and fasting.

USER PROFILE:
- Fitness Level: {user_profile.get('fitness_level', 'intermediate')}
- Goals: {', '.join(user_profile.get('goals', ['general fitness']))}
- Equipment: {', '.join(user_profile.get('equipment', ['dumbbells', 'bodyweight']))}
- Age group: {age_to_bracket(user_profile['age']) if isinstance(user_profile.get('age'), (int, float)) else user_profile.get('age_bracket', 'adult')}
- Dietary Restrictions: {', '.join(user_profile.get('dietary_restrictions', []))}

WORKOUT SCHEDULE:
- Training Days: {workout_day_names} (indices: {workout_days})
- Preferred Workout Time: {preferred_workout_time}
- Week Starting: {week_start_date}

NUTRITION TARGETS (base):
- Daily Calories: {nutrition_targets.get('calories', 2000)}
- Protein: {nutrition_targets.get('protein_g', 150)}g
- Carbs: {nutrition_targets.get('carbs_g', 200)}g
- Fat: {nutrition_targets.get('fat_g', 65)}g

NUTRITION STRATEGY: {nutrition_strategy}
- If workout_aware: Increase calories by 200-400 on training days, boost protein +20-30g, boost carbs +30-50g
- If cutting: Reduce rest day calories by 200-300
- If bulking: Increase all days by 300-500 calories
- If maintenance/static: Keep targets consistent

FASTING PROTOCOL: {fasting_protocol}
- 16:8: 16 hour fast, 8 hour eating window (typical: 12pm-8pm)
- 18:6: 18 hour fast, 6 hour eating window (typical: 12pm-6pm)
- OMAD: One meal a day, 1-2 hour eating window
- None: No fasting restrictions

COORDINATION RULES:
1. On training days, ensure eating window includes time for pre-workout and post-workout meals
2. Pre-workout meal should be 2-3 hours before workout
3. Post-workout meal should be within 1-2 hours after workout
4. If workout falls during fasting period, note this as a warning
5. If OMAD or extended fasting with intense workout, suggest BCAA supplementation

Return ONLY valid JSON (no markdown, no explanation) in this exact format:
{{
  "daily_entries": [
    {{
      "day_index": 0,
      "day_name": "Monday",
      "day_type": "training",
      "workout_time": "17:00",
      "workout_focus": "Upper Body Push",
      "workout_duration_minutes": 45,
      "calorie_target": 2400,
      "protein_target_g": 180,
      "carbs_target_g": 250,
      "fat_target_g": 70,
      "fiber_target_g": 30,
      "eating_window_start": "11:00",
      "eating_window_end": "19:00",
      "fasting_start_time": "19:00",
      "fasting_duration_hours": 16,
      "meal_suggestions": [
        {{
          "meal_type": "pre_workout",
          "suggested_time": "14:00",
          "foods": [
            {{"name": "Oatmeal with banana", "amount": "1 bowl", "calories": 350, "protein_g": 12, "carbs_g": 60, "fat_g": 8}}
          ],
          "notes": "Light carbs for energy"
        }},
        {{
          "meal_type": "post_workout",
          "suggested_time": "18:30",
          "foods": [
            {{"name": "Grilled chicken breast", "amount": "200g", "calories": 330, "protein_g": 62, "carbs_g": 0, "fat_g": 7}},
            {{"name": "Brown rice", "amount": "1 cup", "calories": 215, "protein_g": 5, "carbs_g": 45, "fat_g": 2}}
          ],
          "notes": "High protein for muscle recovery"
        }}
      ],
      "coordination_notes": []
    }},
    {{
      "day_index": 1,
      "day_name": "Tuesday",
      "day_type": "rest",
      "workout_time": null,
      "workout_focus": null,
      "workout_duration_minutes": 0,
      "calorie_target": 2000,
      "protein_target_g": 150,
      "carbs_target_g": 180,
      "fat_target_g": 65,
      "fiber_target_g": 30,
      "eating_window_start": "12:00",
      "eating_window_end": "20:00",
      "fasting_start_time": "20:00",
      "fasting_duration_hours": 16,
      "meal_suggestions": [
        {{
          "meal_type": "lunch",
          "suggested_time": "12:30",
          "foods": [...],
          "notes": "..."
        }}
      ],
      "coordination_notes": []
    }}
  ],
  "weekly_summary": {{
    "total_training_days": 4,
    "total_rest_days": 3,
    "avg_daily_calories": 2200,
    "weekly_protein_total": 1120,
    "focus_areas": ["Upper Body", "Lower Body", "Core"],
    "notes": "Balanced week with adequate recovery"
  }}
}}

Generate entries for ALL 7 days of the week (Monday through Sunday).
Ensure meal suggestions total approximately match the daily calorie/macro targets.
Include 2-4 meals per day that fit within the eating window.
Add coordination_notes array with warnings if any conflicts exist (e.g., workout during fast).
'''

        try:
            response = await asyncio.wait_for(
                client.aio.models.generate_content(
                    model=self.model,
                    contents=[types.Content(role="user", parts=[types.Part.from_text(text=prompt)])],
                    config=types.GenerateContentConfig(
                        system_instruction="You are a fitness and nutrition planning AI. Return only valid JSON.",
                        max_output_tokens=8000,
                        temperature=0.7,
                    ),
                ),
                timeout=90,  # 90s for large weekly plan generation
            )

            # Extract JSON from response
            text = response.text.strip()
            if text.startswith("```json"):
                text = text[7:]
            if text.startswith("```"):
                text = text[3:]
            if text.endswith("```"):
                text = text[:-3]

            return json.loads(text.strip())

        except asyncio.TimeoutError:
            logger.error("[WeeklyPlan] Gemini API timed out after 90s", exc_info=True)
            raise Exception("Weekly plan generation timed out. Please try again.")
        except Exception as e:
            logger.error(f"Error generating weekly holistic plan: {e}", exc_info=True)
            raise

    async def generate_daily_meal_plan(
        self,
        nutrition_targets: Dict,
        eating_window_start: str,
        eating_window_end: str,
        workout_time: Optional[str],
        day_type: str,
        dietary_restrictions: List[str],
        preferences: Dict,
    ) -> List[Dict]:
        """
        Generate AI meal suggestions for a specific day.

        Args:
            nutrition_targets: Daily nutrition targets (calories, protein_g, carbs_g, fat_g)
            eating_window_start: Start of eating window (HH:MM)
            eating_window_end: End of eating window (HH:MM)
            workout_time: Workout time if training day (HH:MM or None)
            day_type: Type of day (training, rest, active_recovery)
            dietary_restrictions: User's dietary restrictions
            preferences: User's food preferences (cuisine, dislikes, etc.)

        Returns:
            List of meal suggestions with foods and macros
        """
        workout_context = ""
        if day_type == "training" and workout_time:
            workout_context = f"""
WORKOUT TIMING:
- Workout at: {workout_time}
- Include a pre-workout meal 2-3 hours before
- Include a post-workout meal within 1-2 hours after
- Pre-workout: Moderate carbs, some protein, low fat
- Post-workout: High protein (30-40g), fast-digesting carbs
"""

        restrictions_text = ", ".join(dietary_restrictions) if dietary_restrictions else "None"
        cuisine_pref = preferences.get("preferred_cuisines", ["varied"])
        dislikes = preferences.get("dislikes", [])

        prompt = f'''Generate a practical daily meal plan for the following requirements:

NUTRITION TARGETS:
- Calories: {nutrition_targets.get('calories', 2000)}
- Protein: {nutrition_targets.get('protein_g', 150)}g
- Carbs: {nutrition_targets.get('carbs_g', 200)}g
- Fat: {nutrition_targets.get('fat_g', 65)}g

EATING WINDOW:
- Start: {eating_window_start}
- End: {eating_window_end}

DAY TYPE: {day_type}
{workout_context}

DIETARY RESTRICTIONS: {restrictions_text}
PREFERRED CUISINES: {', '.join(cuisine_pref)}
DISLIKES: {', '.join(dislikes) if dislikes else 'None specified'}

Generate 3-4 meals that:
1. Fit within the eating window times
2. Total approximately the target macros
3. Are practical and easy to prepare
4. Respect dietary restrictions
5. Include pre/post workout meals if training day

Return ONLY valid JSON (no markdown) as an array:
[
  {{
    "meal_type": "breakfast|lunch|dinner|snack|pre_workout|post_workout",
    "suggested_time": "HH:MM",
    "foods": [
      {{"name": "Food name", "amount": "serving size", "calories": 300, "protein_g": 25, "carbs_g": 30, "fat_g": 10}}
    ],
    "total_calories": 450,
    "total_protein_g": 35,
    "total_carbs_g": 45,
    "total_fat_g": 15,
    "prep_time_minutes": 15,
    "notes": "Quick and high protein"
  }}
]
'''

        try:
            response = await asyncio.wait_for(
                client.aio.models.generate_content(
                    model=self.model,
                    contents=[types.Content(role="user", parts=[types.Part.from_text(text=prompt)])],
                    config=types.GenerateContentConfig(
                        system_instruction="You are a nutrition planning AI. Generate practical, healthy meal suggestions. Return only valid JSON.",
                        max_output_tokens=4000,
                        temperature=0.7,
                    ),
                ),
                timeout=60,  # 60s for daily meal plan
            )

            # Extract JSON from response
            text = response.text.strip()
            if text.startswith("```json"):
                text = text[7:]
            if text.startswith("```"):
                text = text[3:]
            if text.endswith("```"):
                text = text[:-3]

            return json.loads(text.strip())

        except asyncio.TimeoutError:
            logger.error("[MealPlan] Gemini API timed out after 60s", exc_info=True)
            raise Exception("Meal plan generation timed out. Please try again.")
        except Exception as e:
            logger.error(f"Error generating daily meal plan: {e}", exc_info=True)
            raise

    async def regenerate_meal_for_day(
        self,
        meal_type: str,
        current_day_totals: Dict,
        remaining_targets: Dict,
        eating_window_end: str,
        dietary_restrictions: List[str],
        reason: str = "user_request",
    ) -> Dict:
        """
        Regenerate a single meal while maintaining macro balance.

        Args:
            meal_type: Type of meal to regenerate (lunch, dinner, etc.)
            current_day_totals: What's already been consumed/planned
            remaining_targets: Remaining macros to hit
            eating_window_end: When eating window ends
            dietary_restrictions: User's dietary restrictions
            reason: Why regenerating (user_request, dislike, variety)

        Returns:
            Single meal suggestion dict
        """
        prompt = f'''Generate a replacement {meal_type} meal.

REMAINING NUTRITION TARGETS (what this meal should approximately hit):
- Calories: {remaining_targets.get('calories', 500)}
- Protein: {remaining_targets.get('protein_g', 40)}g
- Carbs: {remaining_targets.get('carbs_g', 50)}g
- Fat: {remaining_targets.get('fat_g', 20)}g

ALREADY CONSUMED TODAY:
- Calories: {current_day_totals.get('calories', 0)}
- Protein: {current_day_totals.get('protein_g', 0)}g

CONSTRAINTS:
- Must finish by: {eating_window_end}
- Dietary restrictions: {', '.join(dietary_restrictions) if dietary_restrictions else 'None'}
- Reason for regeneration: {reason}

Generate a single meal that helps hit the remaining targets.

Return ONLY valid JSON (no markdown):
{{
  "meal_type": "{meal_type}",
  "suggested_time": "HH:MM",
  "foods": [
    {{"name": "Food name", "amount": "serving size", "calories": 300, "protein_g": 25, "carbs_g": 30, "fat_g": 10}}
  ],
  "total_calories": 500,
  "total_protein_g": 40,
  "total_carbs_g": 50,
  "total_fat_g": 20,
  "prep_time_minutes": 20,
  "notes": "High protein dinner option"
}}
'''

        try:
            response = await asyncio.wait_for(
                client.aio.models.generate_content(
                    model=self.model,
                    contents=[types.Content(role="user", parts=[types.Part.from_text(text=prompt)])],
                    config=types.GenerateContentConfig(
                        system_instruction="You are a nutrition planning AI. Return only valid JSON.",
                        max_output_tokens=2000,
                        temperature=0.8,
                    ),
                ),
                timeout=30,  # 30s for single meal regeneration
            )

            text = response.text.strip()
            if text.startswith("```json"):
                text = text[7:]
            if text.startswith("```"):
                text = text[3:]
            if text.endswith("```"):
                text = text[:-3]

            return json.loads(text.strip())

        except asyncio.TimeoutError:
            logger.error("[MealRegenerate] Gemini API timed out after 30s", exc_info=True)
            raise Exception("Meal regeneration timed out. Please try again.")
        except Exception as e:
            logger.error(f"Error regenerating meal: {e}", exc_info=True)
            raise

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
                "greeting": "Hey there! I'm your FitWiz.",
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

    async def generate_food_review(
        self,
        food_name: str,
        macros: dict,
        user_goals: list,
        nutrition_targets: dict,
        meal_type: Optional[str] = None,
        mood_before: Optional[str] = None,
        calories_consumed_today: Optional[int] = None,
        calories_remaining: Optional[int] = None,
        health_score: Optional[int] = None,
        coach_name: Optional[str] = None,
        coaching_style: Optional[str] = None,
        communication_tone: Optional[str] = None,
    ) -> dict:
        """
        Generate an AI-powered food review based on user goals and nutrition targets.

        Args:
            food_name: Name of the food item
            macros: Dict with calories, protein_g, carbs_g, fat_g
            user_goals: List of user fitness goals (e.g. ["build_muscle", "lose_fat"])
            nutrition_targets: Dict with daily calorie/macro targets
            meal_type: Meal type (breakfast, lunch, dinner, snack)
            mood_before: User's current mood/state (e.g. "bloated", "tired")
            calories_consumed_today: Total calories consumed today so far
            calories_remaining: Calories remaining in daily budget
            health_score: Pre-computed health score (1-10) for score-stratified guidance

        Returns:
            Dict with encouragements, warnings, ai_suggestion, recommended_swap, health_score
        """
        goals_str = ", ".join(user_goals) if user_goals else "general health"
        targets_str = ", ".join(
            f"{k}: {v}" for k, v in nutrition_targets.items() if v is not None
        ) if nutrition_targets else "no specific targets"
        macros_str = (
            f"calories={macros.get('calories', 0)}, "
            f"protein={macros.get('protein_g', 0)}g, "
            f"carbs={macros.get('carbs_g', 0)}g, "
            f"fat={macros.get('fat_g', 0)}g"
        )

        # Build contextual sections
        mood_section = ""
        if mood_before:
            mood_section = f"\nUser's current mood/state: {mood_before}. Factor this into your tip — if they feel bloated, don't suggest intense exercise; if tired, note energy impact; if hungry, acknowledge satiety.\n"

        meal_type_section = ""
        if meal_type:
            meal_type_section = f"\nThis is the user's {meal_type}. Tailor tip to meal timing (e.g., breakfast = energy for the day, dinner = avoid heavy foods before sleep, snack = portion awareness).\n"

        calorie_budget_section = ""
        if calories_consumed_today is not None and calories_remaining is not None:
            target = (calories_consumed_today or 0) + (calories_remaining or 0)
            calorie_budget_section = f"\nUser has consumed {calories_consumed_today} calories today out of a {target} calorie target ({calories_remaining} remaining). If this meal would put them significantly over budget, mention it tactfully. If they have plenty of room, note that this fits within their plan.\n"

        # Coach persona section
        coach_section = ""
        if coach_name or coaching_style or communication_tone:
            effective_coach = coach_name or "Coach"
            style_map = {
                "motivational": "Be encouraging, celebrate wins, use positive reinforcement.",
                "professional": "Be efficient, factual, and straightforward.",
                "friendly": "Be warm, conversational, and supportive like a good friend.",
                "tough-love": "Be direct and challenging. Don't sugarcoat things.",
                "drill-sergeant": "Be intense and demanding. Use ALL CAPS for emphasis. Accept NO excuses.",
                "zen-master": "Be calm, peaceful, and philosophical. Use metaphors about balance.",
                "hype-beast": "BE ABSOLUTELY HYPED! Use exclamation marks! Everything is INCREDIBLE!",
                "scientist": "Be analytical and data-driven. Focus on the science and cite specifics.",
                "comedian": "Use humor and fitness puns. Make it fun but still give solid advice.",
                "old-school": "Channel classic bodybuilding vibes. Talk about gains and the pump.",
                "college-coach": "Be an intense coach! Question their commitment, demand excellence.",
            }
            tone_map = {
                "casual": "Use casual, conversational language.",
                "encouraging": "Be supportive and positive.",
                "formal": "Use professional, polished language.",
                "gen-z": "Use Gen Z slang like 'no cap', 'fr fr', 'slay', 'bussin'.",
                "sarcastic": "Be witty and sarcastic with dry humor.",
                "roast-mode": "Roast them lovingly! Mock excuses, use playful insults.",
                "pirate": "Talk like a pirate! Use nautical terms.",
                "british": "Be posh and British. Use 'brilliant', 'proper', 'smashing'.",
                "surfer": "Keep it chill, bro! Use surfer vibes - 'gnarly', 'stoked', 'rad'.",
                "anime": "Channel anime protagonist energy! Dramatic declarations!",
            }
            style_desc = style_map.get(coaching_style or "", "Be encouraging and supportive.")
            tone_desc = tone_map.get(communication_tone or "", "Be supportive and positive.")
            coach_section = f"\nYou are {effective_coach}, a fitness nutrition coach.\nCoaching style: {style_desc}\nCommunication tone: {tone_desc}\nWrite ALL tips, encouragements, warnings, and suggestions in this persona's voice and tone.\n"

        # Score-stratified tip guidance
        score_guidance = ""
        effective_score = health_score
        if effective_score is not None:
            if effective_score <= 3:
                score_guidance = """
SCORE CONTEXT: This is a POOR nutritional choice (score {}/10).
- Do NOT include generic positive encouragements like 'quick option', 'convenient', 'tasty', or 'good portion size'
- Encouragements MUST be limited to genuinely redeeming nutritional facts (e.g., 'provides 24g protein'). If there are NONE, return an EMPTY encouragements array []
- Warnings MUST include specific health concerns: excess sodium, trans fats, seed oils, refined carbs, calorie density
- recommended_swap MUST be a specific healthier alternative, not just 'eat less of it'
- Be direct and honest about the nutritional impact. Do NOT sugarcoat or soften the message.
""".format(effective_score)
            elif effective_score <= 5:
                score_guidance = """
SCORE CONTEXT: This is a BELOW-AVERAGE choice (score {}/10).
- Encouragements must reference specific macro/micro nutritional benefits ONLY — not convenience, taste, or availability
- Do NOT praise fast food, processed food, or fried food for being 'a quick option' or 'fitting in a busy schedule'
- Emphasize better alternatives and portion control
""".format(effective_score)
            elif effective_score <= 7:
                score_guidance = "\nSCORE CONTEXT: This is a DECENT choice (score {}/10). Highlight the nutritional benefits and suggest small improvements.\n".format(effective_score)
            else:
                score_guidance = "\nSCORE CONTEXT: This is an EXCELLENT choice (score {}/10). Reinforce the positive behavior and explain specific health benefits.\n".format(effective_score)

        prompt = f'''Given user goals of [{goals_str}] and daily targets of [{targets_str}], review this food: "{food_name}" with macros: {macros_str}.
{coach_section}{mood_section}{meal_type_section}{calorie_budget_section}{score_guidance}
IMPORTANT SEED OIL AWARENESS:
- If this food is commonly fried, packaged, or fast food, check if it is likely cooked in or contains seed oils (canola oil, soybean oil, sunflower oil, corn oil, cottonseed oil, vegetable oil).
- Seed oils are high in inflammatory omega-6 fatty acids and should be flagged as a warning.
- If seed oils are likely present, suggest a healthier alternative cooked in olive oil, ghee, avocado oil, or coconut oil.
- Common seed oil offenders: fried snacks, chips, crackers, packaged baked goods, fast food fries, restaurant fried items, margarine-based products.

Return ONLY valid JSON (no markdown) with this exact structure:
{{
  "encouragements": ["list of positive aspects — mention EACH food item by name"],
  "warnings": ["list of concerns — mention EACH food item by name if applicable"],
  "ai_suggestion": "a detailed, actionable suggestion covering the overall meal composition and how to improve it",
  "recommended_swap": "specific healthier alternatives for the weakest items, or empty string if the meal is already great",
  "health_score": 7
}}

Rules:
- health_score is an integer from 1 to 10 (1=very unhealthy for goals, 10=perfect for goals)
- CRITICAL: Review ALL food items individually — do NOT focus on just one item. Each encouragement/warning should name the specific food it's about.
- For multi-item meals: provide 1 encouragement/warning per food item that deserves one (up to 5 each). A 5-item meal should have more feedback than a 1-item snack.
- Be specific to the user's goals
- Keep each string concise (under 100 chars)
- NEVER encourage fast food, deep-fried items, or heavily processed food for convenience or taste
- NEVER say 'okay as an occasional treat' or 'fine in moderation' for foods scoring <= 3
- If food is from a fast food chain (McDonald's, KFC, Burger King, Taco Bell, Wendy's, etc.), warnings MUST mention: high sodium, seed oils, additives, low nutrient density
- If food is high-calorie (>500 kcal) and low-protein (<20g), warn about poor calorie-to-protein ratio
- For sugary drinks, candy, desserts, pastries: do NOT encourage — focus on sugar content, insulin impact, and healthier swaps
- For fried foods: always warn about seed oils and inflammatory omega-6
- ai_suggestion must be specific and actionable — NOT generic like 'pair with a salad' or 'balance it out later'
- If health_score <= 3, recommended_swap is REQUIRED (non-empty string)
'''

        try:
            response = await asyncio.wait_for(
                client.aio.models.generate_content(
                    model=self.model,
                    contents=[types.Content(role="user", parts=[types.Part.from_text(text=prompt)])],
                    config=types.GenerateContentConfig(
                        system_instruction="You are a nutrition expert AI. Return only valid JSON.",
                        max_output_tokens=500,
                        temperature=0.1,
                    ),
                ),
                timeout=15,
            )

            if not response.text:
                logger.warning("[FoodReview] Empty response from Gemini")
                return None

            # Robust JSON extraction (handle markdown code blocks)
            text = response.text.strip()
            parse_result = parse_ai_json(text, context="food_review")
            if parse_result.success:
                data = parse_result.data
                return {
                    "encouragements": data.get("encouragements", []),
                    "warnings": data.get("warnings", []),
                    "ai_suggestion": data.get("ai_suggestion", ""),
                    "recommended_swap": data.get("recommended_swap", ""),
                    "health_score": max(1, min(10, int(data.get("health_score", 5)))),
                }

            # Fallback: manual markdown strip
            if text.startswith("```json"):
                text = text[7:]
            if text.startswith("```"):
                text = text[3:]
            if text.endswith("```"):
                text = text[:-3]

            data = json.loads(text.strip())
            return {
                "encouragements": data.get("encouragements", []),
                "warnings": data.get("warnings", []),
                "ai_suggestion": data.get("ai_suggestion", ""),
                "recommended_swap": data.get("recommended_swap", ""),
                "health_score": max(1, min(10, int(data.get("health_score", 5)))),
            }

        except asyncio.TimeoutError:
            logger.error("[FoodReview] Gemini API timed out", exc_info=True)
            return None
        except Exception as e:
            logger.error(f"[FoodReview] Error generating food review: {e}", exc_info=True)
            return None
