#!/usr/bin/env python3
"""
Test script to calculate nutrition metrics for a specific user.
Queries user profile data and calls the calculate_nutrition_metrics function.
"""

import os
import sys
from supabase import create_client

# Supabase credentials
SUPABASE_URL = "https://hpbzfahijszqmgsybuor.supabase.co"
SUPABASE_KEY = os.environ.get("SUPABASE_KEY")
if not SUPABASE_KEY:
    raise SystemExit("SUPABASE_KEY environment variable is required")

# User to test
USER_ID = "c30a0993-b88c-4cd6-bf7b-fc631cd290c5"
USER_EMAIL = "chetangrandhe@gmail.com"


def main():
    print(f"[TEST] Testing nutrition calculation for user: {USER_EMAIL}")
    print(f"[TEST] User ID: {USER_ID}")
    print("=" * 60)

    # Create Supabase client
    supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

    # Step 1: Query user profile data
    print("\n[STEP 1] Querying user profile data...")

    user_response = supabase.table("users").select(
        "id, email, weight_kg, height_cm, age, gender, activity_level, preferences"
    ).eq("id", USER_ID).execute()

    if not user_response.data:
        print(f"[ERROR] User not found with ID: {USER_ID}")
        return

    user = user_response.data[0]
    print(f"\n[RESULT] User Profile:")
    print(f"  - Email: {user.get('email')}")
    print(f"  - Weight: {user.get('weight_kg')} kg")
    print(f"  - Height: {user.get('height_cm')} cm")
    print(f"  - Age: {user.get('age')}")
    print(f"  - Gender: {user.get('gender')}")
    print(f"  - Activity Level: {user.get('activity_level')}")

    preferences = user.get('preferences') or {}
    print(f"\n[RESULT] Preferences JSON:")
    print(f"  - weight_direction: {preferences.get('weight_direction')}")
    print(f"  - weight_change_rate: {preferences.get('weight_change_rate')}")
    print(f"  - goal_weight_kg: {preferences.get('goal_weight_kg')}")
    print(f"  - nutrition_goals: {preferences.get('nutrition_goals')}")
    print(f"  - days_per_week: {preferences.get('days_per_week')}")

    # Validate required fields
    weight_kg = user.get('weight_kg')
    height_cm = user.get('height_cm')
    age = user.get('age')
    gender = user.get('gender')

    if not all([weight_kg, height_cm, age, gender]):
        print(f"\n[ERROR] Missing required fields:")
        if not weight_kg: print("  - weight_kg is missing")
        if not height_cm: print("  - height_cm is missing")
        if not age: print("  - age is missing")
        if not gender: print("  - gender is missing")
        return

    # Step 2: Call the calculate_nutrition_metrics function
    print("\n" + "=" * 60)
    print("[STEP 2] Calling calculate_nutrition_metrics function...")

    # Prepare parameters
    activity_level = user.get('activity_level') or 'lightly_active'
    weight_direction = preferences.get('weight_direction') or 'maintain'
    weight_change_rate = preferences.get('weight_change_rate') or 'moderate'
    goal_weight_kg = preferences.get('goal_weight_kg')
    nutrition_goals = preferences.get('nutrition_goals') or []
    days_per_week = preferences.get('days_per_week') or 3

    # Ensure nutrition_goals is a list
    if isinstance(nutrition_goals, str):
        nutrition_goals = [nutrition_goals]

    print(f"\n[PARAMS] Function parameters:")
    print(f"  - p_user_id: {USER_ID}")
    print(f"  - p_weight_kg: {weight_kg}")
    print(f"  - p_height_cm: {height_cm}")
    print(f"  - p_age: {age}")
    print(f"  - p_gender: {gender}")
    print(f"  - p_activity_level: {activity_level}")
    print(f"  - p_weight_direction: {weight_direction}")
    print(f"  - p_weight_change_rate: {weight_change_rate}")
    print(f"  - p_goal_weight_kg: {goal_weight_kg}")
    print(f"  - p_nutrition_goals: {nutrition_goals}")
    print(f"  - p_workout_days_per_week: {days_per_week}")

    # Call the RPC function
    try:
        rpc_response = supabase.rpc(
            "calculate_nutrition_metrics",
            {
                "p_user_id": USER_ID,
                "p_weight_kg": float(weight_kg),
                "p_height_cm": float(height_cm),
                "p_age": int(age),
                "p_gender": str(gender),
                "p_activity_level": str(activity_level),
                "p_weight_direction": str(weight_direction),
                "p_weight_change_rate": str(weight_change_rate),
                "p_goal_weight_kg": float(goal_weight_kg) if goal_weight_kg else None,
                "p_nutrition_goals": nutrition_goals if nutrition_goals else None,
                "p_workout_days_per_week": int(days_per_week) if days_per_week else 3
            }
        ).execute()

        print(f"\n[SUCCESS] Function returned:")
        result = rpc_response.data
        if isinstance(result, dict):
            for key, value in result.items():
                print(f"  - {key}: {value}")
        else:
            print(f"  {result}")

    except Exception as e:
        print(f"\n[ERROR] RPC call failed: {e}")
        return

    # Step 3: Verify the nutrition_preferences table was populated
    print("\n" + "=" * 60)
    print("[STEP 3] Verifying nutrition_preferences table...")

    nutrition_response = supabase.table("nutrition_preferences").select(
        "user_id, target_calories, target_protein_g, target_carbs_g, target_fat_g, "
        "calculated_bmr, calculated_tdee, metabolic_age, water_intake_liters, "
        "estimated_body_fat_percent, lean_mass_kg, fat_mass_kg, protein_per_kg, "
        "ideal_weight_min_kg, ideal_weight_max_kg, goal_date, weeks_to_goal, "
        "metrics_calculated_at"
    ).eq("user_id", USER_ID).execute()

    if not nutrition_response.data:
        print("[ERROR] No data found in nutrition_preferences for this user!")
        return

    nutrition = nutrition_response.data[0]
    print(f"\n[RESULT] Nutrition Preferences (Calculated Metrics):")
    print(f"  - Target Calories: {nutrition.get('target_calories')} kcal")
    print(f"  - Target Protein: {nutrition.get('target_protein_g')} g")
    print(f"  - Target Carbs: {nutrition.get('target_carbs_g')} g")
    print(f"  - Target Fat: {nutrition.get('target_fat_g')} g")
    print(f"  - BMR: {nutrition.get('calculated_bmr')} kcal")
    print(f"  - TDEE: {nutrition.get('calculated_tdee')} kcal")
    print(f"  - Metabolic Age: {nutrition.get('metabolic_age')} years")
    print(f"  - Water Intake: {nutrition.get('water_intake_liters')} L/day")
    print(f"  - Est. Body Fat: {nutrition.get('estimated_body_fat_percent')}%")
    print(f"  - Lean Mass: {nutrition.get('lean_mass_kg')} kg")
    print(f"  - Fat Mass: {nutrition.get('fat_mass_kg')} kg")
    print(f"  - Protein/kg: {nutrition.get('protein_per_kg')} g/kg")
    print(f"  - Ideal Weight Range: {nutrition.get('ideal_weight_min_kg')} - {nutrition.get('ideal_weight_max_kg')} kg")
    print(f"  - Goal Date: {nutrition.get('goal_date')}")
    print(f"  - Weeks to Goal: {nutrition.get('weeks_to_goal')}")
    print(f"  - Calculated At: {nutrition.get('metrics_calculated_at')}")

    print("\n" + "=" * 60)
    print("[DONE] Nutrition calculation test completed successfully!")


if __name__ == "__main__":
    main()
