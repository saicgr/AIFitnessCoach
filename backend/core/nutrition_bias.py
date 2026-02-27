"""
Calorie estimate bias utilities.

Applies a user-configurable multiplier to AI-estimated nutritional values.
This does NOT apply to barcode scans (which use precise database data).

Bias levels:
  -2 = "AI overestimates a lot"  -> multiply by 0.85
  -1 = "AI overestimates a bit"  -> multiply by 0.93
   0 = "AI is about right"       -> multiply by 1.0 (no change)
   1 = "AI underestimates a bit" -> multiply by 1.07
   2 = "AI underestimates a lot" -> multiply by 1.15
"""

import logging

from core.supabase_db import get_supabase_db

logger = logging.getLogger(__name__)

BIAS_MULTIPLIERS = {
    -2: 0.85,
    -1: 0.93,
    0: 1.0,
    1: 1.07,
    2: 1.15,
}


def apply_calorie_bias(food_analysis: dict, bias: int) -> dict:
    """
    Apply calorie estimate bias to all nutritional values in a food analysis dict.

    Multiplies total-level macros/micros AND per-item calories proportionally.
    Returns a new dict (does not mutate the original).
    """
    multiplier = BIAS_MULTIPLIERS.get(bias, 1.0)
    if multiplier == 1.0:
        return food_analysis

    result = dict(food_analysis)

    # Top-level numeric nutrition fields to scale
    top_level_keys = [
        "total_calories", "calories",
        "protein_g", "carbs_g", "fat_g", "fiber_g",
        "sugar_g", "sodium_mg", "cholesterol_mg", "potassium_mg",
        "vitamin_a_ug", "vitamin_c_mg", "vitamin_d_iu",
        "calcium_mg", "iron_mg",
        "saturated_fat_g", "vitamin_e_mg", "vitamin_k_ug",
        "vitamin_b1_mg", "vitamin_b2_mg", "vitamin_b3_mg",
        "vitamin_b5_mg", "vitamin_b6_mg", "vitamin_b7_ug",
        "vitamin_b9_ug", "vitamin_b12_ug",
        "magnesium_mg", "zinc_mg", "phosphorus_mg",
        "copper_mg", "manganese_mg", "selenium_ug",
        "choline_mg", "omega3_g", "omega6_g",
    ]

    for key in top_level_keys:
        if key in result and result[key] is not None:
            val = result[key]
            if isinstance(val, (int, float)):
                if isinstance(val, int):
                    result[key] = round(val * multiplier)
                else:
                    result[key] = round(val * multiplier, 1)

    # Scale per-item nutrition
    if "food_items" in result and isinstance(result["food_items"], list):
        scaled_items = []
        for item in result["food_items"]:
            scaled_item = dict(item)
            item_keys = [
                "calories", "protein_g", "carbs_g", "fat_g", "fiber_g",
                "sugar_g", "sodium_mg",
            ]
            for key in item_keys:
                if key in scaled_item and scaled_item[key] is not None:
                    val = scaled_item[key]
                    if isinstance(val, (int, float)):
                        if isinstance(val, int):
                            scaled_item[key] = round(val * multiplier)
                        else:
                            scaled_item[key] = round(val * multiplier, 1)
            scaled_items.append(scaled_item)
        result["food_items"] = scaled_items

    logger.info(f"Applied calorie bias {bias} (x{multiplier}) to food analysis")
    return result


async def get_user_calorie_bias(user_id: str) -> int:
    """
    Fetch the user's calorie_estimate_bias from the nutrition_preferences table.

    Returns 0 (no bias) if the user has no preference set or on error.
    """
    try:
        db = get_supabase_db()
        result = (
            db.client.table("nutrition_preferences")
            .select("calorie_estimate_bias")
            .eq("user_id", user_id)
            .limit(1)
            .execute()
        )
        if result.data:
            bias = result.data[0].get("calorie_estimate_bias", 0)
            if bias is not None and isinstance(bias, int) and -2 <= bias <= 2:
                return bias
        return 0
    except Exception as e:
        logger.warning(f"Could not fetch calorie_estimate_bias for user {user_id}: {e}")
        return 0
