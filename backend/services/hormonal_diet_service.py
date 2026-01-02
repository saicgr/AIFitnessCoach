"""
Hormonal Diet Service
Provides hormone-supportive nutrition recommendations and meal planning using Gemini AI.
"""

from typing import List, Dict, Optional
from datetime import date
from dataclasses import dataclass
import json

from models.hormonal_health import (
    HormoneGoal, CyclePhase, HormonalProfile,
    HormoneSupportiveFood, HormonalFoodRecommendation
)
from core.supabase_client import get_supabase_client


@dataclass
class HormonalFood:
    """Food with hormonal benefits."""
    name: str
    category: str
    benefits: List[str]
    key_nutrients: List[str]
    serving_suggestion: str
    hormone_goals: List[str]
    cycle_phases: List[str]


@dataclass
class HormonalMealPlan:
    """Daily meal plan optimized for hormonal health."""
    date: date
    hormone_goals: List[str]
    cycle_phase: Optional[str]
    breakfast: Dict
    lunch: Dict
    dinner: Dict
    snacks: List[Dict]
    daily_tips: List[str]
    key_nutrients_focus: List[str]


class HormonalDietService:
    """Service for hormone-supportive nutrition recommendations."""

    # ============================================================================
    # STATIC FOOD DATABASES
    # ============================================================================

    TESTOSTERONE_BOOSTING_FOODS = [
        HormonalFood(
            name="Oysters",
            category="seafood",
            benefits=["Highest natural zinc source", "Supports testosterone production"],
            key_nutrients=["zinc", "vitamin_d", "b12", "selenium"],
            serving_suggestion="6 oysters, 2-3 times per week",
            hormone_goals=["optimize_testosterone", "improve_fertility"],
            cycle_phases=[]
        ),
        HormonalFood(
            name="Eggs (whole)",
            category="protein",
            benefits=["Contains cholesterol for hormone synthesis", "Complete protein"],
            key_nutrients=["cholesterol", "vitamin_d", "choline", "protein"],
            serving_suggestion="2-3 whole eggs daily",
            hormone_goals=["optimize_testosterone", "general_wellness"],
            cycle_phases=["menstrual", "follicular", "ovulation", "luteal"]
        ),
        HormonalFood(
            name="Grass-fed Beef",
            category="protein",
            benefits=["Rich in zinc and saturated fats", "High-quality protein"],
            key_nutrients=["zinc", "iron", "b12", "protein", "creatine"],
            serving_suggestion="4-6 oz, 2-3 times per week",
            hormone_goals=["optimize_testosterone"],
            cycle_phases=["menstrual"]
        ),
        HormonalFood(
            name="Tuna",
            category="seafood",
            benefits=["Excellent vitamin D source", "Omega-3 fatty acids"],
            key_nutrients=["vitamin_d", "omega3", "protein", "selenium"],
            serving_suggestion="3-4 oz, 2-3 times per week",
            hormone_goals=["optimize_testosterone", "improve_fertility"],
            cycle_phases=["follicular"]
        ),
        HormonalFood(
            name="Pomegranate",
            category="fruit",
            benefits=["May increase testosterone", "Improves blood flow", "Antioxidant-rich"],
            key_nutrients=["antioxidants", "nitrates", "vitamin_c"],
            serving_suggestion="1 cup seeds or 8 oz juice daily",
            hormone_goals=["optimize_testosterone", "balance_estrogen"],
            cycle_phases=["follicular", "ovulation"]
        ),
        HormonalFood(
            name="Garlic",
            category="vegetable",
            benefits=["Contains allicin for testosterone support", "Anti-inflammatory"],
            key_nutrients=["allicin", "selenium", "vitamin_c"],
            serving_suggestion="2-3 cloves daily, raw or lightly cooked",
            hormone_goals=["optimize_testosterone", "balance_estrogen"],
            cycle_phases=["follicular", "ovulation", "luteal"]
        ),
        HormonalFood(
            name="Ginger",
            category="spice",
            benefits=["Anti-inflammatory", "May boost testosterone"],
            key_nutrients=["gingerol", "antioxidants"],
            serving_suggestion="1-2 inches fresh ginger daily in meals or tea",
            hormone_goals=["optimize_testosterone", "pcos_management"],
            cycle_phases=["menstrual", "luteal"]
        ),
        HormonalFood(
            name="Brazil Nuts",
            category="nut",
            benefits=["Selenium for thyroid and testosterone", "Healthy fats"],
            key_nutrients=["selenium", "magnesium", "zinc"],
            serving_suggestion="2-3 nuts daily (selenium toxicity if more)",
            hormone_goals=["optimize_testosterone", "general_wellness"],
            cycle_phases=["follicular"]
        ),
        HormonalFood(
            name="Avocado",
            category="fruit",
            benefits=["Healthy fats for hormone production", "Vitamin E"],
            key_nutrients=["monounsaturated_fats", "vitamin_e", "potassium"],
            serving_suggestion="Half to 1 avocado daily",
            hormone_goals=["optimize_testosterone", "balance_estrogen", "pcos_management"],
            cycle_phases=["follicular", "ovulation", "luteal"]
        ),
        HormonalFood(
            name="Olive Oil (Extra Virgin)",
            category="fat",
            benefits=["Supports Leydig cell function", "Anti-inflammatory"],
            key_nutrients=["monounsaturated_fats", "antioxidants", "vitamin_e"],
            serving_suggestion="2-3 tablespoons daily",
            hormone_goals=["optimize_testosterone", "balance_estrogen"],
            cycle_phases=["follicular", "ovulation", "luteal"]
        ),
    ]

    ESTROGEN_BALANCING_FOODS = [
        HormonalFood(
            name="Flaxseeds",
            category="seed",
            benefits=["Lignans help balance estrogen", "Omega-3s", "Fiber"],
            key_nutrients=["lignans", "omega3", "fiber"],
            serving_suggestion="1-2 tablespoons ground flaxseed daily",
            hormone_goals=["balance_estrogen", "pcos_management", "menopause_support"],
            cycle_phases=["menstrual", "follicular", "luteal"]
        ),
        HormonalFood(
            name="Cruciferous Vegetables",
            category="vegetable",
            benefits=["DIM for estrogen metabolism", "Fiber", "Antioxidants"],
            key_nutrients=["indole_3_carbinol", "dim", "fiber", "vitamin_c"],
            serving_suggestion="1-2 cups daily (broccoli, cauliflower, kale, Brussels sprouts)",
            hormone_goals=["balance_estrogen", "pcos_management", "menopause_support"],
            cycle_phases=["follicular", "ovulation"]
        ),
        HormonalFood(
            name="Berries",
            category="fruit",
            benefits=["Antioxidants support hormone balance", "Low glycemic"],
            key_nutrients=["antioxidants", "fiber", "vitamin_c"],
            serving_suggestion="1 cup mixed berries daily",
            hormone_goals=["balance_estrogen", "pcos_management", "improve_fertility"],
            cycle_phases=["menstrual", "follicular", "ovulation", "luteal"]
        ),
        HormonalFood(
            name="Turmeric",
            category="spice",
            benefits=["Curcumin supports estrogen metabolism", "Anti-inflammatory"],
            key_nutrients=["curcumin", "antioxidants"],
            serving_suggestion="1-2 teaspoons daily with black pepper for absorption",
            hormone_goals=["balance_estrogen", "pcos_management", "menopause_support"],
            cycle_phases=["menstrual", "luteal"]
        ),
        HormonalFood(
            name="Green Tea",
            category="beverage",
            benefits=["EGCG supports estrogen balance", "Antioxidants"],
            key_nutrients=["egcg", "antioxidants", "l_theanine"],
            serving_suggestion="2-3 cups daily",
            hormone_goals=["balance_estrogen", "pcos_management"],
            cycle_phases=["follicular", "ovulation"]
        ),
    ]

    PCOS_SUPPORTIVE_FOODS = [
        HormonalFood(
            name="Salmon (Wild-Caught)",
            category="seafood",
            benefits=["Omega-3s reduce inflammation", "Protein for blood sugar"],
            key_nutrients=["omega3", "vitamin_d", "protein", "selenium"],
            serving_suggestion="4-6 oz, 2-3 times per week",
            hormone_goals=["pcos_management", "balance_estrogen", "improve_fertility"],
            cycle_phases=["menstrual", "follicular", "ovulation", "luteal"]
        ),
        HormonalFood(
            name="Leafy Greens",
            category="vegetable",
            benefits=["Low calorie, nutrient dense", "Supports insulin sensitivity"],
            key_nutrients=["folate", "iron", "magnesium", "fiber"],
            serving_suggestion="2-3 cups daily (spinach, kale, Swiss chard)",
            hormone_goals=["pcos_management", "balance_estrogen", "improve_fertility"],
            cycle_phases=["menstrual", "follicular", "ovulation", "luteal"]
        ),
        HormonalFood(
            name="Cinnamon",
            category="spice",
            benefits=["Improves insulin sensitivity", "Blood sugar regulation"],
            key_nutrients=["cinnamaldehyde", "antioxidants"],
            serving_suggestion="1/2 to 1 teaspoon daily",
            hormone_goals=["pcos_management"],
            cycle_phases=["follicular", "luteal"]
        ),
        HormonalFood(
            name="Lentils",
            category="legume",
            benefits=["Slow-release carbs", "Plant protein", "Fiber"],
            key_nutrients=["protein", "fiber", "iron", "folate"],
            serving_suggestion="1/2 to 1 cup cooked, several times per week",
            hormone_goals=["pcos_management", "balance_estrogen", "improve_fertility"],
            cycle_phases=["menstrual", "follicular", "luteal"]
        ),
        HormonalFood(
            name="Walnuts",
            category="nut",
            benefits=["May lower androgens in PCOS", "Omega-3s"],
            key_nutrients=["omega3", "protein", "magnesium"],
            serving_suggestion="1 oz (about 14 halves) daily",
            hormone_goals=["pcos_management", "balance_estrogen"],
            cycle_phases=["follicular", "ovulation", "luteal"]
        ),
    ]

    MENOPAUSE_SUPPORTIVE_FOODS = [
        HormonalFood(
            name="Soy (Organic/Fermented)",
            category="legume",
            benefits=["Phytoestrogens may reduce hot flashes", "Plant protein"],
            key_nutrients=["phytoestrogens", "protein", "calcium"],
            serving_suggestion="1-2 servings daily (tofu, tempeh, edamame)",
            hormone_goals=["menopause_support", "balance_estrogen"],
            cycle_phases=["luteal"]
        ),
        HormonalFood(
            name="Chickpeas",
            category="legume",
            benefits=["Phytoestrogens", "Fiber for gut health"],
            key_nutrients=["phytoestrogens", "fiber", "protein"],
            serving_suggestion="1/2 cup cooked, several times per week",
            hormone_goals=["menopause_support", "balance_estrogen", "improve_fertility"],
            cycle_phases=["follicular", "ovulation", "luteal"]
        ),
        HormonalFood(
            name="Whole Grains",
            category="grain",
            benefits=["Fiber for estrogen balance", "B vitamins"],
            key_nutrients=["fiber", "b_vitamins", "magnesium"],
            serving_suggestion="3-4 servings daily (oats, quinoa, brown rice)",
            hormone_goals=["menopause_support", "pcos_management", "general_wellness"],
            cycle_phases=["menstrual", "follicular", "ovulation", "luteal"]
        ),
        HormonalFood(
            name="Calcium-Rich Foods",
            category="dairy",
            benefits=["Bone health support", "May reduce menopause symptoms"],
            key_nutrients=["calcium", "vitamin_d", "protein"],
            serving_suggestion="3 servings daily (dairy, fortified alternatives, leafy greens)",
            hormone_goals=["menopause_support"],
            cycle_phases=[]
        ),
    ]

    FERTILITY_SUPPORTIVE_FOODS = [
        HormonalFood(
            name="Spinach",
            category="vegetable",
            benefits=["Folate essential for fertility", "Iron"],
            key_nutrients=["folate", "iron", "magnesium", "vitamin_k"],
            serving_suggestion="1-2 cups daily",
            hormone_goals=["improve_fertility", "balance_estrogen"],
            cycle_phases=["menstrual", "follicular", "ovulation", "luteal"]
        ),
        HormonalFood(
            name="Citrus Fruits",
            category="fruit",
            benefits=["Vitamin C supports reproductive health", "Folate"],
            key_nutrients=["vitamin_c", "folate", "antioxidants"],
            serving_suggestion="1-2 servings daily",
            hormone_goals=["improve_fertility"],
            cycle_phases=["follicular", "ovulation"]
        ),
        HormonalFood(
            name="Sweet Potatoes",
            category="vegetable",
            benefits=["Beta-carotene may support ovulation", "Complex carbs"],
            key_nutrients=["beta_carotene", "vitamin_a", "fiber"],
            serving_suggestion="1 medium sweet potato, several times per week",
            hormone_goals=["improve_fertility", "menopause_support"],
            cycle_phases=["follicular", "luteal"]
        ),
        HormonalFood(
            name="Full-Fat Dairy",
            category="dairy",
            benefits=["May improve ovulation vs low-fat", "Calcium"],
            key_nutrients=["calcium", "vitamin_d", "healthy_fats"],
            serving_suggestion="1-2 servings daily",
            hormone_goals=["improve_fertility"],
            cycle_phases=["follicular", "ovulation"]
        ),
    ]

    # Cycle phase-specific nutrition focuses
    CYCLE_PHASE_NUTRITION = {
        CyclePhase.MENSTRUAL: {
            "focus": "Iron replenishment and anti-inflammatory foods",
            "key_nutrients": ["iron", "vitamin_c", "omega3", "magnesium"],
            "foods_to_emphasize": [
                "Red meat or iron-rich alternatives",
                "Dark leafy greens",
                "Dark chocolate (magnesium)",
                "Ginger and turmeric (anti-inflammatory)",
                "Warm, comforting foods"
            ],
            "foods_to_limit": [
                "Excessive salt (increases bloating)",
                "Caffeine (may worsen cramps)",
                "Alcohol",
                "Processed foods"
            ],
            "meal_timing": "Regular meals to maintain energy; warm foods are soothing"
        },
        CyclePhase.FOLLICULAR: {
            "focus": "Light, fresh foods as estrogen rises",
            "key_nutrients": ["probiotics", "fermented_foods", "lean_protein", "zinc"],
            "foods_to_emphasize": [
                "Fermented foods (kimchi, sauerkraut, yogurt)",
                "Fresh vegetables and salads",
                "Lean proteins",
                "Sprouted grains",
                "Light cooking methods (steaming, raw)"
            ],
            "foods_to_limit": [
                "Heavy, rich foods",
                "Excessive saturated fats"
            ],
            "meal_timing": "Great time to try new foods; appetite may be lower"
        },
        CyclePhase.OVULATION: {
            "focus": "Fiber and antioxidants for estrogen metabolism",
            "key_nutrients": ["fiber", "antioxidants", "glutathione", "b_vitamins"],
            "foods_to_emphasize": [
                "Fiber-rich vegetables",
                "Cruciferous vegetables (broccoli, cauliflower)",
                "Raw vegetables and fruits",
                "Light proteins",
                "Colorful foods high in antioxidants"
            ],
            "foods_to_limit": [
                "Alcohol (interferes with estrogen metabolism)",
                "Excessive sugar"
            ],
            "meal_timing": "Smaller, more frequent meals; energy is highest"
        },
        CyclePhase.LUTEAL: {
            "focus": "Complex carbs and magnesium for PMS prevention",
            "key_nutrients": ["magnesium", "b6", "complex_carbs", "tryptophan"],
            "foods_to_emphasize": [
                "Complex carbohydrates (quinoa, sweet potato, oats)",
                "Magnesium-rich foods (nuts, seeds, dark chocolate)",
                "B vitamin-rich foods",
                "Tryptophan foods for serotonin (turkey, pumpkin seeds)",
                "Cooked, warming foods"
            ],
            "foods_to_limit": [
                "Refined sugar (blood sugar spikes worsen PMS)",
                "Excessive salt",
                "Caffeine",
                "Alcohol"
            ],
            "meal_timing": "More frequent meals to stabilize blood sugar; appetite increases"
        }
    }

    def __init__(self):
        """Initialize the hormonal diet service."""
        self.supabase = get_supabase_client()

    def get_testosterone_boosting_foods(self) -> List[HormonalFood]:
        """Get list of testosterone-boosting foods."""
        return self.TESTOSTERONE_BOOSTING_FOODS

    def get_estrogen_balancing_foods(self) -> List[HormonalFood]:
        """Get list of estrogen-balancing foods."""
        return self.ESTROGEN_BALANCING_FOODS

    def get_pcos_supportive_foods(self) -> List[HormonalFood]:
        """Get list of PCOS-supportive foods."""
        return self.PCOS_SUPPORTIVE_FOODS

    def get_menopause_supportive_foods(self) -> List[HormonalFood]:
        """Get list of menopause-supportive foods."""
        return self.MENOPAUSE_SUPPORTIVE_FOODS

    def get_fertility_supportive_foods(self) -> List[HormonalFood]:
        """Get list of fertility-supportive foods."""
        return self.FERTILITY_SUPPORTIVE_FOODS

    def get_cycle_phase_foods(self, phase: CyclePhase) -> Dict:
        """Get nutrition recommendations for a specific cycle phase."""
        return self.CYCLE_PHASE_NUTRITION.get(phase, {})

    def get_foods_for_goals(self, goals: List[HormoneGoal]) -> List[HormonalFood]:
        """Get foods that support the given hormone goals."""
        all_foods = []

        goal_to_foods = {
            HormoneGoal.OPTIMIZE_TESTOSTERONE: self.TESTOSTERONE_BOOSTING_FOODS,
            HormoneGoal.BALANCE_ESTROGEN: self.ESTROGEN_BALANCING_FOODS,
            HormoneGoal.PCOS_MANAGEMENT: self.PCOS_SUPPORTIVE_FOODS,
            HormoneGoal.MENOPAUSE_SUPPORT: self.MENOPAUSE_SUPPORTIVE_FOODS,
            HormoneGoal.PERIMENOPAUSE_SUPPORT: self.MENOPAUSE_SUPPORTIVE_FOODS,
            HormoneGoal.IMPROVE_FERTILITY: self.FERTILITY_SUPPORTIVE_FOODS,
        }

        seen_names = set()
        for goal in goals:
            foods = goal_to_foods.get(goal, [])
            for food in foods:
                if food.name not in seen_names:
                    all_foods.append(food)
                    seen_names.add(food.name)

        return all_foods

    def get_foods_for_phase(self, phase: CyclePhase) -> List[HormonalFood]:
        """Get foods recommended for a specific cycle phase."""
        phase_value = phase.value
        all_foods = (
            self.TESTOSTERONE_BOOSTING_FOODS +
            self.ESTROGEN_BALANCING_FOODS +
            self.PCOS_SUPPORTIVE_FOODS +
            self.MENOPAUSE_SUPPORTIVE_FOODS +
            self.FERTILITY_SUPPORTIVE_FOODS
        )

        seen_names = set()
        phase_foods = []
        for food in all_foods:
            if phase_value in food.cycle_phases and food.name not in seen_names:
                phase_foods.append(food)
                seen_names.add(food.name)

        return phase_foods

    async def get_hormonal_diet_recommendations(
        self,
        user_id: str,
        goals: List[HormoneGoal],
        current_phase: Optional[CyclePhase] = None,
        dietary_restrictions: List[str] = None
    ) -> Dict:
        """
        Get comprehensive hormonal diet recommendations.

        Args:
            user_id: User ID
            goals: List of hormone goals
            current_phase: Current menstrual cycle phase (if applicable)
            dietary_restrictions: List of dietary restrictions/allergies

        Returns:
            Dictionary with food recommendations, tips, and meal ideas
        """
        print(f"🔍 [HormonalDiet] Getting recommendations for user {user_id}")

        recommendations = {
            "user_id": user_id,
            "hormone_goals": [g.value for g in goals],
            "current_phase": current_phase.value if current_phase else None,
            "recommended_foods": [],
            "foods_to_limit": [],
            "key_nutrients": [],
            "meal_timing_tips": [],
            "daily_tips": [],
            "phase_specific": None
        }

        # Get foods for goals
        goal_foods = self.get_foods_for_goals(goals)
        recommendations["recommended_foods"] = [
            {
                "name": f.name,
                "category": f.category,
                "benefits": f.benefits,
                "serving": f.serving_suggestion,
                "nutrients": f.key_nutrients
            }
            for f in goal_foods[:15]  # Top 15 foods
        ]

        # Collect key nutrients
        all_nutrients = set()
        for food in goal_foods:
            all_nutrients.update(food.key_nutrients)
        recommendations["key_nutrients"] = list(all_nutrients)[:10]

        # Add phase-specific recommendations if applicable
        if current_phase:
            phase_info = self.get_cycle_phase_foods(current_phase)
            recommendations["phase_specific"] = phase_info
            recommendations["foods_to_limit"] = phase_info.get("foods_to_limit", [])
            recommendations["meal_timing_tips"].append(phase_info.get("meal_timing", ""))

        # Add general tips based on goals
        for goal in goals:
            if goal == HormoneGoal.OPTIMIZE_TESTOSTERONE:
                recommendations["daily_tips"].extend([
                    "Eat protein with every meal",
                    "Include healthy fats (olive oil, avocado, nuts)",
                    "Don't skip breakfast - it affects cortisol",
                    "Post-workout nutrition is crucial for testosterone",
                    "Limit sugar and processed foods"
                ])
                recommendations["foods_to_limit"].extend([
                    "Excessive alcohol",
                    "Soy products (in excess)",
                    "Refined sugars",
                    "Trans fats"
                ])

            elif goal == HormoneGoal.BALANCE_ESTROGEN:
                recommendations["daily_tips"].extend([
                    "Eat plenty of fiber to help excrete excess estrogen",
                    "Include cruciferous vegetables daily",
                    "Choose organic when possible to reduce xenoestrogens",
                    "Support liver health with leafy greens"
                ])
                recommendations["foods_to_limit"].extend([
                    "Non-organic dairy",
                    "Conventionally raised meat",
                    "Alcohol",
                    "Excessive caffeine"
                ])

            elif goal == HormoneGoal.PCOS_MANAGEMENT:
                recommendations["daily_tips"].extend([
                    "Focus on low glycemic index foods",
                    "Pair carbs with protein or fat to stabilize blood sugar",
                    "Eat anti-inflammatory foods",
                    "Consider intermittent fasting (consult healthcare provider)"
                ])
                recommendations["foods_to_limit"].extend([
                    "Refined carbohydrates",
                    "Sugary drinks",
                    "Processed foods",
                    "Excessive dairy"
                ])

            elif goal == HormoneGoal.MENOPAUSE_SUPPORT:
                recommendations["daily_tips"].extend([
                    "Include calcium-rich foods for bone health",
                    "Eat phytoestrogen-containing foods",
                    "Stay well hydrated",
                    "Small, frequent meals may help with hot flashes"
                ])
                recommendations["foods_to_limit"].extend([
                    "Spicy foods (may trigger hot flashes)",
                    "Caffeine",
                    "Alcohol",
                    "Very hot beverages"
                ])

        # Remove duplicates
        recommendations["foods_to_limit"] = list(set(recommendations["foods_to_limit"]))
        recommendations["daily_tips"] = list(set(recommendations["daily_tips"]))[:8]

        # Filter out restricted foods if provided
        if dietary_restrictions:
            restrictions_lower = [r.lower() for r in dietary_restrictions]
            recommendations["recommended_foods"] = [
                f for f in recommendations["recommended_foods"]
                if not any(r in f["name"].lower() for r in restrictions_lower)
            ]

        print(f"✅ [HormonalDiet] Generated recommendations with {len(recommendations['recommended_foods'])} foods")
        return recommendations

    async def generate_hormonal_meal_plan_prompt(
        self,
        goals: List[HormoneGoal],
        current_phase: Optional[CyclePhase],
        dietary_restrictions: List[str],
        calorie_target: int,
        protein_target: int
    ) -> str:
        """
        Generate a Gemini prompt for creating a hormonal meal plan.

        Returns a prompt string to be used with Gemini API.
        """
        goals_str = ", ".join([g.value.replace("_", " ") for g in goals])
        phase_str = current_phase.value if current_phase else "not tracking cycle"
        restrictions_str = ", ".join(dietary_restrictions) if dietary_restrictions else "none"

        # Get phase-specific info
        phase_info = ""
        if current_phase:
            phase_data = self.CYCLE_PHASE_NUTRITION.get(current_phase, {})
            phase_info = f"""
Current menstrual cycle phase: {current_phase.value}
Phase nutrition focus: {phase_data.get('focus', '')}
Key nutrients for this phase: {', '.join(phase_data.get('key_nutrients', []))}
Foods to emphasize: {', '.join(phase_data.get('foods_to_emphasize', [])[:5])}
Foods to limit: {', '.join(phase_data.get('foods_to_limit', [])[:3])}
"""

        # Get goal-specific foods
        goal_foods = self.get_foods_for_goals(goals)
        top_foods = ", ".join([f.name for f in goal_foods[:10]])

        prompt = f"""Create a one-day meal plan optimized for hormonal health.

USER GOALS: {goals_str}
DIETARY RESTRICTIONS: {restrictions_str}
CALORIE TARGET: {calorie_target} calories
PROTEIN TARGET: {protein_target}g
{phase_info}

HORMONE-SUPPORTIVE FOODS TO INCLUDE:
{top_foods}

Please create a meal plan with:
1. Breakfast (with hormonal benefits explanation)
2. Lunch (with hormonal benefits explanation)
3. Dinner (with hormonal benefits explanation)
4. 2 Snacks (with hormonal benefits explanation)

For each meal, include:
- Meal name
- Ingredients list with portions
- Approximate calories and macros
- Which hormone goal it supports and why

Also provide:
- 3 daily hormonal nutrition tips
- Best time to eat each meal for hormone optimization

Return as JSON with this structure:
{{
    "breakfast": {{"name": "", "ingredients": [], "calories": 0, "protein": 0, "carbs": 0, "fat": 0, "hormone_benefits": ""}},
    "lunch": {{"name": "", "ingredients": [], "calories": 0, "protein": 0, "carbs": 0, "fat": 0, "hormone_benefits": ""}},
    "dinner": {{"name": "", "ingredients": [], "calories": 0, "protein": 0, "carbs": 0, "fat": 0, "hormone_benefits": ""}},
    "snacks": [{{"name": "", "ingredients": [], "calories": 0, "hormone_benefits": ""}}],
    "daily_tips": [],
    "meal_timing": {{}}
}}
"""
        return prompt


# Singleton instance
_hormonal_diet_service: Optional[HormonalDietService] = None


def get_hormonal_diet_service() -> HormonalDietService:
    """Get the hormonal diet service singleton."""
    global _hormonal_diet_service
    if _hormonal_diet_service is None:
        _hormonal_diet_service = HormonalDietService()
    return _hormonal_diet_service
