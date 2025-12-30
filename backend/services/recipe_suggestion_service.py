"""
Recipe Suggestion Service
=========================
AI-powered recipe suggestions based on user preferences:
- Body type (ectomorph/mesomorph/endomorph)
- Cultural/cuisine preferences
- Dietary restrictions and allergies
- Nutrition goals
- Cooking skill and time available

Uses Gemini AI to generate personalized recipe suggestions.
"""

import json
import logging
import uuid
from datetime import datetime
from typing import List, Dict, Any, Optional
from dataclasses import dataclass, asdict
from enum import Enum

from google import genai
from google.genai import types

from core.config import get_settings
from core.db import get_supabase_db

settings = get_settings()
logger = logging.getLogger(__name__)

# Initialize Gemini client
client = genai.Client(api_key=settings.gemini_api_key)


class BodyType(str, Enum):
    ECTOMORPH = "ectomorph"
    MESOMORPH = "mesomorph"
    ENDOMORPH = "endomorph"
    BALANCED = "balanced"


class MealType(str, Enum):
    BREAKFAST = "breakfast"
    LUNCH = "lunch"
    DINNER = "dinner"
    SNACK = "snack"
    ANY = "any"


@dataclass
class RecipeIngredient:
    """Single ingredient in a recipe."""
    name: str
    amount: float
    unit: str
    calories: float = 0
    protein_g: float = 0
    carbs_g: float = 0
    fat_g: float = 0
    notes: Optional[str] = None


@dataclass
class RecipeSuggestion:
    """A single recipe suggestion."""
    recipe_name: str
    recipe_description: str
    cuisine: str
    category: str
    ingredients: List[RecipeIngredient]
    instructions: List[str]
    servings: int
    calories_per_serving: int
    protein_per_serving_g: float
    carbs_per_serving_g: float
    fat_per_serving_g: float
    fiber_per_serving_g: float
    prep_time_minutes: int
    cook_time_minutes: int
    suggestion_reason: str
    goal_alignment_score: int
    cuisine_match_score: int
    diet_compliance_score: int
    overall_match_score: int

    def to_dict(self) -> Dict[str, Any]:
        return {
            **asdict(self),
            "ingredients": [asdict(i) for i in self.ingredients],
        }


@dataclass
class UserRecipeContext:
    """User context for recipe generation."""
    user_id: str
    body_type: str
    diet_type: str
    nutrition_goals: List[str]
    allergies: List[str]
    dietary_restrictions: List[str]
    disliked_foods: List[str]
    favorite_cuisines: List[str]
    cooking_skill: str
    cooking_time_minutes: int
    budget_level: str
    spice_tolerance: str
    target_calories: int
    target_protein_g: int
    target_carbs_g: int
    target_fat_g: int


class RecipeSuggestionService:
    """Service for generating personalized recipe suggestions."""

    def __init__(self):
        self.model = settings.gemini_model

    async def get_user_context(self, user_id: str) -> Optional[UserRecipeContext]:
        """
        Fetch user's nutrition preferences and build context for recipe generation.
        """
        try:
            db = get_supabase_db()

            # Get nutrition preferences
            prefs_response = db.client.table("nutrition_preferences").select("*").eq(
                "user_id", user_id
            ).execute()

            prefs = prefs_response.data[0] if prefs_response.data else {}

            # Get user basic info for weight/height if needed
            user_response = db.client.table("users").select(
                "weight_kg, height_cm, age, gender, fitness_level"
            ).eq("id", user_id).execute()

            user = user_response.data[0] if user_response.data else {}

            # Parse nutrition goals (may be array or single value)
            nutrition_goals = prefs.get("nutrition_goals", [])
            if isinstance(nutrition_goals, str):
                nutrition_goals = [nutrition_goals]
            elif not nutrition_goals:
                nutrition_goals = [prefs.get("nutrition_goal", "maintain")]

            return UserRecipeContext(
                user_id=user_id,
                body_type=prefs.get("body_type", "balanced"),
                diet_type=prefs.get("diet_type", "balanced"),
                nutrition_goals=nutrition_goals,
                allergies=prefs.get("allergies", []) or [],
                dietary_restrictions=prefs.get("dietary_restrictions", []) or [],
                disliked_foods=prefs.get("disliked_foods", []) or [],
                favorite_cuisines=prefs.get("favorite_cuisines", []) or [],
                cooking_skill=prefs.get("cooking_skill", "intermediate"),
                cooking_time_minutes=prefs.get("cooking_time_minutes", 30),
                budget_level=prefs.get("budget_level", "moderate"),
                spice_tolerance=prefs.get("spice_tolerance", "medium"),
                target_calories=prefs.get("target_calories", 2000),
                target_protein_g=prefs.get("target_protein_g", 150),
                target_carbs_g=prefs.get("target_carbs_g", 200),
                target_fat_g=prefs.get("target_fat_g", 70),
            )

        except Exception as e:
            logger.error(f"❌ [RecipeSuggestion] Error fetching user context: {e}")
            return None

    def _build_recipe_prompt(
        self,
        context: UserRecipeContext,
        meal_type: MealType,
        count: int = 3,
        additional_requirements: Optional[str] = None,
    ) -> str:
        """Build the Gemini prompt for recipe generation."""

        # Body type specific guidance
        body_type_guidance = {
            "ectomorph": "Focus on calorie-dense recipes with healthy fats and complex carbs. Higher portion sizes recommended.",
            "mesomorph": "Balanced macros with good protein content. Moderate portions with variety.",
            "endomorph": "Lower carb, higher protein recipes. Focus on fiber-rich vegetables and lean proteins.",
            "balanced": "Balanced nutrition with emphasis on whole foods and variety.",
        }

        # Diet type specific guidance
        diet_guidance = {
            "balanced": "Standard balanced nutrition",
            "low_carb": "Keep carbs under 30g per serving",
            "keto": "Very low carb (under 10g net carbs), high fat",
            "high_protein": "Minimum 30g protein per serving",
            "vegetarian": "No meat or fish, eggs and dairy allowed",
            "vegan": "No animal products whatsoever",
            "mediterranean": "Olive oil, fish, whole grains, vegetables",
            "paleo": "No grains, legumes, or processed foods",
        }

        # Build allergy and restriction string
        avoid_list = []
        if context.allergies:
            avoid_list.extend([f"ALLERGY: {a}" for a in context.allergies])
        if context.dietary_restrictions:
            avoid_list.extend([f"RESTRICTION: {r}" for r in context.dietary_restrictions])
        if context.disliked_foods:
            avoid_list.extend([f"DISLIKE: {f}" for f in context.disliked_foods])

        avoid_string = "\n".join(avoid_list) if avoid_list else "None"

        # Cuisine preference string
        cuisine_string = ", ".join(context.favorite_cuisines) if context.favorite_cuisines else "any cuisine"

        # Cooking skill instructions
        skill_instructions = {
            "beginner": "Use simple techniques, minimal steps, common ingredients",
            "intermediate": "Standard cooking techniques, reasonable complexity",
            "advanced": "Can include complex techniques and exotic ingredients",
        }

        prompt = f"""You are a professional nutritionist and chef creating personalized recipe suggestions.

## USER PROFILE

**Body Type:** {context.body_type}
{body_type_guidance.get(context.body_type, body_type_guidance["balanced"])}

**Diet Type:** {context.diet_type}
{diet_guidance.get(context.diet_type, diet_guidance["balanced"])}

**Nutrition Goals:** {", ".join(context.nutrition_goals)}

**Daily Targets:**
- Calories: {context.target_calories} kcal
- Protein: {context.target_protein_g}g
- Carbs: {context.target_carbs_g}g
- Fat: {context.target_fat_g}g

**MUST AVOID (Critical - these could cause allergic reactions or violate beliefs):**
{avoid_string}

**Cuisine Preferences:** {cuisine_string}

**Cooking Constraints:**
- Skill Level: {context.cooking_skill} ({skill_instructions.get(context.cooking_skill, "")})
- Max Cooking Time: {context.cooking_time_minutes} minutes
- Budget: {context.budget_level}
- Spice Tolerance: {context.spice_tolerance}

## REQUEST

Generate {count} {meal_type.value if meal_type != MealType.ANY else "meal"} recipes that:
1. Match the user's cuisine preferences when possible
2. Align with their nutrition goals and body type
3. Respect ALL allergies and dietary restrictions
4. Can be prepared within their time/skill constraints
5. Have accurate nutrition information

{f"Additional requirements: {additional_requirements}" if additional_requirements else ""}

## RESPONSE FORMAT

Return ONLY valid JSON (no markdown, no explanation) in this exact format:
{{
  "recipes": [
    {{
      "recipe_name": "Recipe Name",
      "recipe_description": "Brief appetizing description",
      "cuisine": "italian",
      "category": "{meal_type.value if meal_type != MealType.ANY else 'lunch'}",
      "servings": 2,
      "prep_time_minutes": 15,
      "cook_time_minutes": 20,
      "ingredients": [
        {{"name": "ingredient name", "amount": 200, "unit": "g", "calories": 150, "protein_g": 25, "carbs_g": 5, "fat_g": 3, "notes": "diced"}}
      ],
      "instructions": [
        "Step 1: Do this...",
        "Step 2: Then this..."
      ],
      "calories_per_serving": 450,
      "protein_per_serving_g": 35,
      "carbs_per_serving_g": 30,
      "fat_per_serving_g": 20,
      "fiber_per_serving_g": 5,
      "suggestion_reason": "High protein for muscle building, matches Italian cuisine preference, quick 35-min prep",
      "goal_alignment_score": 85,
      "cuisine_match_score": 100,
      "diet_compliance_score": 100,
      "overall_match_score": 92
    }}
  ]
}}

IMPORTANT:
- Scores are 0-100 where 100 is perfect match
- All nutrition values must be realistic and accurate
- NEVER include any ingredients the user is allergic to or must avoid
- Ensure cuisine field matches one of: indian, italian, mexican, chinese, japanese, thai, korean, mediterranean, middle_eastern, american, french, greek, spanish, vietnamese, brazilian, african, caribbean, german, turkish, persian, fusion
"""
        return prompt

    async def suggest_recipes(
        self,
        user_id: str,
        meal_type: MealType = MealType.ANY,
        count: int = 3,
        additional_requirements: Optional[str] = None,
    ) -> List[RecipeSuggestion]:
        """
        Generate personalized recipe suggestions for a user.

        Args:
            user_id: The user's ID
            meal_type: Type of meal (breakfast, lunch, dinner, snack, any)
            count: Number of recipes to generate (1-5)
            additional_requirements: Extra requirements (e.g., "high fiber", "under 400 calories")

        Returns:
            List of RecipeSuggestion objects
        """
        logger.info(f"🍳 [RecipeSuggestion] Generating {count} {meal_type.value} recipes for user {user_id}")

        # Get user context
        context = await self.get_user_context(user_id)
        if not context:
            logger.error(f"❌ [RecipeSuggestion] Could not fetch user context for {user_id}")
            raise ValueError("Could not fetch user preferences")

        logger.info(f"🍳 [RecipeSuggestion] User context: body_type={context.body_type}, diet={context.diet_type}, cuisines={context.favorite_cuisines}")

        # Build prompt
        prompt = self._build_recipe_prompt(
            context=context,
            meal_type=meal_type,
            count=count,
            additional_requirements=additional_requirements,
        )

        try:
            # Call Gemini
            start_time = datetime.now()

            response = await client.aio.models.generate_content(
                model=self.model,
                contents=[types.Content(role="user", parts=[types.Part.from_text(text=prompt)])],
                config=types.GenerateContentConfig(
                    max_output_tokens=8000,
                    temperature=0.7,  # Some creativity for recipes
                ),
            )

            generation_time_ms = int((datetime.now() - start_time).total_seconds() * 1000)
            logger.info(f"✅ [RecipeSuggestion] Gemini response in {generation_time_ms}ms")

            # Parse response
            response_text = response.text.strip()

            # Clean up markdown if present
            if response_text.startswith("```"):
                response_text = response_text.split("```")[1]
                if response_text.startswith("json"):
                    response_text = response_text[4:]

            data = json.loads(response_text)
            recipes_data = data.get("recipes", [])

            # Convert to RecipeSuggestion objects
            suggestions = []
            for recipe in recipes_data:
                ingredients = [
                    RecipeIngredient(
                        name=ing.get("name", ""),
                        amount=float(ing.get("amount", 0)),
                        unit=ing.get("unit", "g"),
                        calories=float(ing.get("calories", 0)),
                        protein_g=float(ing.get("protein_g", 0)),
                        carbs_g=float(ing.get("carbs_g", 0)),
                        fat_g=float(ing.get("fat_g", 0)),
                        notes=ing.get("notes"),
                    )
                    for ing in recipe.get("ingredients", [])
                ]

                suggestion = RecipeSuggestion(
                    recipe_name=recipe.get("recipe_name", "Unnamed Recipe"),
                    recipe_description=recipe.get("recipe_description", ""),
                    cuisine=recipe.get("cuisine", "fusion"),
                    category=recipe.get("category", meal_type.value),
                    ingredients=ingredients,
                    instructions=recipe.get("instructions", []),
                    servings=int(recipe.get("servings", 1)),
                    calories_per_serving=int(recipe.get("calories_per_serving", 0)),
                    protein_per_serving_g=float(recipe.get("protein_per_serving_g", 0)),
                    carbs_per_serving_g=float(recipe.get("carbs_per_serving_g", 0)),
                    fat_per_serving_g=float(recipe.get("fat_per_serving_g", 0)),
                    fiber_per_serving_g=float(recipe.get("fiber_per_serving_g", 0)),
                    prep_time_minutes=int(recipe.get("prep_time_minutes", 0)),
                    cook_time_minutes=int(recipe.get("cook_time_minutes", 0)),
                    suggestion_reason=recipe.get("suggestion_reason", ""),
                    goal_alignment_score=int(recipe.get("goal_alignment_score", 50)),
                    cuisine_match_score=int(recipe.get("cuisine_match_score", 50)),
                    diet_compliance_score=int(recipe.get("diet_compliance_score", 100)),
                    overall_match_score=int(recipe.get("overall_match_score", 50)),
                )
                suggestions.append(suggestion)

            logger.info(f"✅ [RecipeSuggestion] Generated {len(suggestions)} recipes")

            # Save session to database
            await self._save_suggestion_session(
                user_id=user_id,
                meal_type=meal_type,
                context=context,
                suggestions=suggestions,
                generation_time_ms=generation_time_ms,
            )

            return suggestions

        except json.JSONDecodeError as e:
            logger.error(f"❌ [RecipeSuggestion] JSON parse error: {e}")
            logger.error(f"Response text: {response_text[:500]}...")
            raise ValueError("Failed to parse recipe suggestions from AI")
        except Exception as e:
            logger.error(f"❌ [RecipeSuggestion] Error generating recipes: {e}")
            raise

    async def _save_suggestion_session(
        self,
        user_id: str,
        meal_type: MealType,
        context: UserRecipeContext,
        suggestions: List[RecipeSuggestion],
        generation_time_ms: int,
    ) -> str:
        """Save recipe suggestion session to database."""
        try:
            db = get_supabase_db()

            session_id = str(uuid.uuid4())
            suggestion_ids = []

            # Save each suggestion
            for suggestion in suggestions:
                suggestion_id = str(uuid.uuid4())
                suggestion_ids.append(suggestion_id)

                suggestion_data = {
                    "id": suggestion_id,
                    "user_id": user_id,
                    "recipe_name": suggestion.recipe_name,
                    "recipe_description": suggestion.recipe_description,
                    "cuisine": suggestion.cuisine,
                    "category": suggestion.category,
                    "ingredients": [asdict(i) for i in suggestion.ingredients],
                    "instructions": suggestion.instructions,
                    "servings": suggestion.servings,
                    "calories_per_serving": suggestion.calories_per_serving,
                    "protein_per_serving_g": suggestion.protein_per_serving_g,
                    "carbs_per_serving_g": suggestion.carbs_per_serving_g,
                    "fat_per_serving_g": suggestion.fat_per_serving_g,
                    "fiber_per_serving_g": suggestion.fiber_per_serving_g,
                    "prep_time_minutes": suggestion.prep_time_minutes,
                    "cook_time_minutes": suggestion.cook_time_minutes,
                    "suggestion_reason": suggestion.suggestion_reason,
                    "goal_alignment_score": suggestion.goal_alignment_score,
                    "cuisine_match_score": suggestion.cuisine_match_score,
                    "diet_compliance_score": suggestion.diet_compliance_score,
                    "overall_match_score": suggestion.overall_match_score,
                    "generation_context": {
                        "body_type": context.body_type,
                        "diet_type": context.diet_type,
                        "nutrition_goals": context.nutrition_goals,
                        "allergies": context.allergies,
                        "dietary_restrictions": context.dietary_restrictions,
                        "favorite_cuisines": context.favorite_cuisines,
                    },
                }

                db.client.table("recipe_suggestions").insert(suggestion_data).execute()

            # Save session
            session_data = {
                "id": session_id,
                "user_id": user_id,
                "meal_type": meal_type.value,
                "request_type": "general",
                "user_context": {
                    "body_type": context.body_type,
                    "diet_type": context.diet_type,
                    "nutrition_goals": context.nutrition_goals,
                    "allergies": context.allergies,
                    "dietary_restrictions": context.dietary_restrictions,
                    "favorite_cuisines": context.favorite_cuisines,
                    "cooking_skill": context.cooking_skill,
                    "cooking_time_available": context.cooking_time_minutes,
                    "budget_level": context.budget_level,
                    "spice_tolerance": context.spice_tolerance,
                    "target_calories": context.target_calories,
                    "target_protein_g": context.target_protein_g,
                },
                "suggestions_count": len(suggestions),
                "suggestions_generated": suggestion_ids,
                "ai_model_used": self.model,
                "generation_time_ms": generation_time_ms,
            }

            db.client.table("recipe_suggestion_sessions").insert(session_data).execute()

            logger.info(f"✅ [RecipeSuggestion] Saved session {session_id} with {len(suggestion_ids)} suggestions")
            return session_id

        except Exception as e:
            logger.warning(f"⚠️ [RecipeSuggestion] Failed to save session: {e}")
            return ""

    async def get_saved_suggestions(
        self,
        user_id: str,
        limit: int = 20,
        saved_only: bool = False,
    ) -> List[Dict[str, Any]]:
        """Get user's previous recipe suggestions."""
        try:
            db = get_supabase_db()

            query = db.client.table("recipe_suggestions").select("*").eq(
                "user_id", user_id
            ).order("created_at", desc=True).limit(limit)

            if saved_only:
                query = query.eq("user_saved", True)

            response = query.execute()
            return response.data or []

        except Exception as e:
            logger.error(f"❌ [RecipeSuggestion] Error getting saved suggestions: {e}")
            return []

    async def rate_suggestion(
        self,
        user_id: str,
        suggestion_id: str,
        rating: int,
        feedback: Optional[str] = None,
    ) -> bool:
        """Rate a recipe suggestion."""
        try:
            if rating < 1 or rating > 5:
                raise ValueError("Rating must be between 1 and 5")

            db = get_supabase_db()

            db.client.table("recipe_suggestions").update({
                "user_rating": rating,
                "user_feedback": feedback,
                "interacted_at": datetime.now().isoformat(),
            }).eq("id", suggestion_id).eq("user_id", user_id).execute()

            logger.info(f"✅ [RecipeSuggestion] Rated suggestion {suggestion_id} with {rating} stars")
            return True

        except Exception as e:
            logger.error(f"❌ [RecipeSuggestion] Error rating suggestion: {e}")
            return False

    async def save_suggestion(
        self,
        user_id: str,
        suggestion_id: str,
    ) -> bool:
        """Mark a suggestion as saved (favorite)."""
        try:
            db = get_supabase_db()

            db.client.table("recipe_suggestions").update({
                "user_saved": True,
                "interacted_at": datetime.now().isoformat(),
            }).eq("id", suggestion_id).eq("user_id", user_id).execute()

            logger.info(f"✅ [RecipeSuggestion] Saved suggestion {suggestion_id}")
            return True

        except Exception as e:
            logger.error(f"❌ [RecipeSuggestion] Error saving suggestion: {e}")
            return False

    async def mark_cooked(
        self,
        user_id: str,
        suggestion_id: str,
    ) -> bool:
        """Mark a suggestion as cooked."""
        try:
            db = get_supabase_db()

            db.client.table("recipe_suggestions").update({
                "user_cooked": True,
                "interacted_at": datetime.now().isoformat(),
            }).eq("id", suggestion_id).eq("user_id", user_id).execute()

            logger.info(f"✅ [RecipeSuggestion] Marked suggestion {suggestion_id} as cooked")
            return True

        except Exception as e:
            logger.error(f"❌ [RecipeSuggestion] Error marking cooked: {e}")
            return False

    async def convert_to_user_recipe(
        self,
        user_id: str,
        suggestion_id: str,
    ) -> Optional[str]:
        """Convert a suggestion to a user recipe in user_recipes table."""
        try:
            db = get_supabase_db()

            # Get the suggestion
            response = db.client.table("recipe_suggestions").select("*").eq(
                "id", suggestion_id
            ).eq("user_id", user_id).execute()

            if not response.data:
                logger.error(f"❌ [RecipeSuggestion] Suggestion {suggestion_id} not found")
                return None

            suggestion = response.data[0]

            # Create user recipe
            recipe_id = str(uuid.uuid4())
            recipe_data = {
                "id": recipe_id,
                "user_id": user_id,
                "name": suggestion["recipe_name"],
                "description": suggestion["recipe_description"],
                "servings": suggestion["servings"],
                "prep_time_minutes": suggestion["prep_time_minutes"],
                "cook_time_minutes": suggestion["cook_time_minutes"],
                "instructions": "\n".join(suggestion.get("instructions", [])),
                "category": suggestion["category"],
                "cuisine": suggestion["cuisine"],
                "tags": ["ai_generated", suggestion["cuisine"]],
                "calories_per_serving": suggestion["calories_per_serving"],
                "protein_per_serving_g": suggestion["protein_per_serving_g"],
                "carbs_per_serving_g": suggestion["carbs_per_serving_g"],
                "fat_per_serving_g": suggestion["fat_per_serving_g"],
                "fiber_per_serving_g": suggestion["fiber_per_serving_g"],
                "source_type": "ai_generated",
            }

            db.client.table("user_recipes").insert(recipe_data).execute()

            # Add ingredients
            for idx, ing in enumerate(suggestion.get("ingredients", [])):
                ing_data = {
                    "recipe_id": recipe_id,
                    "ingredient_order": idx,
                    "food_name": ing.get("name", ""),
                    "amount": ing.get("amount", 0),
                    "unit": ing.get("unit", "g"),
                    "calories": ing.get("calories", 0),
                    "protein_g": ing.get("protein_g", 0),
                    "carbs_g": ing.get("carbs_g", 0),
                    "fat_g": ing.get("fat_g", 0),
                    "notes": ing.get("notes"),
                }
                db.client.table("recipe_ingredients").insert(ing_data).execute()

            # Update suggestion with conversion reference
            db.client.table("recipe_suggestions").update({
                "converted_to_recipe_id": recipe_id,
                "user_saved": True,
            }).eq("id", suggestion_id).execute()

            logger.info(f"✅ [RecipeSuggestion] Converted suggestion {suggestion_id} to recipe {recipe_id}")
            return recipe_id

        except Exception as e:
            logger.error(f"❌ [RecipeSuggestion] Error converting to recipe: {e}")
            return None

    async def get_cuisines_list(self) -> List[Dict[str, Any]]:
        """Get list of available cuisines."""
        try:
            db = get_supabase_db()
            response = db.client.table("cuisine_types").select("*").order("display_order").execute()
            return response.data or []
        except Exception as e:
            logger.error(f"❌ [RecipeSuggestion] Error getting cuisines: {e}")
            # Return hardcoded fallback
            return [
                {"code": "indian", "name": "Indian", "region": "South Asia"},
                {"code": "italian", "name": "Italian", "region": "Europe"},
                {"code": "mexican", "name": "Mexican", "region": "Americas"},
                {"code": "chinese", "name": "Chinese", "region": "East Asia"},
                {"code": "japanese", "name": "Japanese", "region": "East Asia"},
                {"code": "thai", "name": "Thai", "region": "Southeast Asia"},
                {"code": "mediterranean", "name": "Mediterranean", "region": "Europe/Middle East"},
                {"code": "american", "name": "American", "region": "Americas"},
            ]

    async def get_body_types_list(self) -> List[Dict[str, Any]]:
        """Get list of body types with descriptions."""
        try:
            db = get_supabase_db()
            response = db.client.table("body_types").select("*").order("display_order").execute()
            return response.data or []
        except Exception as e:
            logger.error(f"❌ [RecipeSuggestion] Error getting body types: {e}")
            # Return hardcoded fallback
            return [
                {"code": "ectomorph", "name": "Ectomorph", "description": "Lean build, fast metabolism"},
                {"code": "mesomorph", "name": "Mesomorph", "description": "Athletic build, moderate metabolism"},
                {"code": "endomorph", "name": "Endomorph", "description": "Rounder build, slower metabolism"},
                {"code": "balanced", "name": "Balanced", "description": "Combination of body types"},
            ]


# Singleton instance
recipe_suggestion_service = RecipeSuggestionService()
