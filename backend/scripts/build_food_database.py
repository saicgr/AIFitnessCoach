#!/usr/bin/env python3
"""
Build the USDA food database for offline nutrition lookup.

Usage:
  python build_food_database.py [--csv-dir /path/to/usda/csvs] [--output /path/to/output.db]

If --csv-dir is not provided, generates a seed database with ~50 common foods.

USDA SR Legacy CSV files expected:
  - food.csv          (fdc_id, data_type, description, food_category_id, ...)
  - food_nutrient.csv (id, fdc_id, nutrient_id, amount, ...)
  - nutrient.csv      (id, name, unit_name, ...)
"""
import sqlite3
import csv
import argparse
import os
import json
from pathlib import Path

# Nutrient IDs from USDA FDC (SR Legacy)
NUTRIENT_IDS = {
    1008: "calories",        # Energy (kcal)
    1003: "protein_g",       # Protein
    1004: "fat_g",           # Total lipid (fat)
    1005: "carbs_g",         # Carbohydrate, by difference
    1079: "fiber_g",         # Fiber, total dietary
    2000: "sugar_g",         # Sugars, total including NLEA
    1093: "sodium_mg",       # Sodium, Na
    1106: "vitamin_a_mcg",   # Vitamin A, RAE
    1162: "vitamin_c_mg",    # Vitamin C, total ascorbic acid
    1087: "calcium_mg",      # Calcium, Ca
    1089: "iron_mg",         # Iron, Fe
    1092: "potassium_mg",    # Potassium, K
}

# ~50 common fitness-relevant foods with accurate USDA nutrition data (per serving)
COMMON_FOODS = [
    # === PROTEINS ===
    {"fdc_id": 1, "description": "Chicken breast, boneless, skinless, cooked", "food_category": "Poultry", "serving_size_g": 120.0, "household_serving": "1 breast (4 oz)", "calories": 198.0, "protein_g": 37.2, "fat_g": 4.3, "carbs_g": 0.0, "fiber_g": 0.0, "sugar_g": 0.0, "sodium_mg": 89.0, "vitamin_a_mcg": 8.0, "vitamin_c_mg": 0.0, "calcium_mg": 18.0, "iron_mg": 0.6, "potassium_mg": 307.0},
    {"fdc_id": 2, "description": "Egg, whole, hard-boiled", "food_category": "Dairy and Egg Products", "serving_size_g": 50.0, "household_serving": "1 large", "calories": 78.0, "protein_g": 6.3, "fat_g": 5.3, "carbs_g": 0.6, "fiber_g": 0.0, "sugar_g": 0.6, "sodium_mg": 62.0, "vitamin_a_mcg": 75.0, "vitamin_c_mg": 0.0, "calcium_mg": 25.0, "iron_mg": 0.6, "potassium_mg": 63.0},
    {"fdc_id": 3, "description": "Salmon, Atlantic, cooked", "food_category": "Finfish and Shellfish", "serving_size_g": 113.0, "household_serving": "1 fillet (4 oz)", "calories": 234.0, "protein_g": 25.0, "fat_g": 14.0, "carbs_g": 0.0, "fiber_g": 0.0, "sugar_g": 0.0, "sodium_mg": 59.0, "vitamin_a_mcg": 13.0, "vitamin_c_mg": 0.0, "calcium_mg": 13.0, "iron_mg": 0.3, "potassium_mg": 363.0},
    {"fdc_id": 4, "description": "Tuna, canned in water, drained", "food_category": "Finfish and Shellfish", "serving_size_g": 85.0, "household_serving": "1 can (3 oz)", "calories": 73.0, "protein_g": 16.5, "fat_g": 0.8, "carbs_g": 0.0, "fiber_g": 0.0, "sugar_g": 0.0, "sodium_mg": 287.0, "vitamin_a_mcg": 6.0, "vitamin_c_mg": 0.0, "calcium_mg": 9.0, "iron_mg": 0.8, "potassium_mg": 134.0},
    {"fdc_id": 5, "description": "Cod, Atlantic, cooked", "food_category": "Finfish and Shellfish", "serving_size_g": 113.0, "household_serving": "1 fillet (4 oz)", "calories": 105.0, "protein_g": 23.0, "fat_g": 0.9, "carbs_g": 0.0, "fiber_g": 0.0, "sugar_g": 0.0, "sodium_mg": 78.0, "vitamin_a_mcg": 14.0, "vitamin_c_mg": 1.0, "calcium_mg": 14.0, "iron_mg": 0.5, "potassium_mg": 244.0},
    {"fdc_id": 6, "description": "Turkey breast, roasted", "food_category": "Poultry", "serving_size_g": 113.0, "household_serving": "4 oz", "calories": 153.0, "protein_g": 34.0, "fat_g": 0.8, "carbs_g": 0.0, "fiber_g": 0.0, "sugar_g": 0.0, "sodium_mg": 57.0, "vitamin_a_mcg": 0.0, "vitamin_c_mg": 0.0, "calcium_mg": 11.0, "iron_mg": 0.7, "potassium_mg": 293.0},
    {"fdc_id": 7, "description": "Greek yogurt, plain, nonfat", "food_category": "Dairy and Egg Products", "serving_size_g": 170.0, "household_serving": "1 container (6 oz)", "calories": 100.0, "protein_g": 17.0, "fat_g": 0.7, "carbs_g": 6.0, "fiber_g": 0.0, "sugar_g": 6.0, "sodium_mg": 61.0, "vitamin_a_mcg": 0.0, "vitamin_c_mg": 0.0, "calcium_mg": 187.0, "iron_mg": 0.1, "potassium_mg": 220.0},
    {"fdc_id": 8, "description": "Cottage cheese, low fat (2%)", "food_category": "Dairy and Egg Products", "serving_size_g": 113.0, "household_serving": "1/2 cup", "calories": 92.0, "protein_g": 12.0, "fat_g": 2.6, "carbs_g": 5.0, "fiber_g": 0.0, "sugar_g": 5.0, "sodium_mg": 348.0, "vitamin_a_mcg": 25.0, "vitamin_c_mg": 0.0, "calcium_mg": 91.0, "iron_mg": 0.2, "potassium_mg": 104.0},
    {"fdc_id": 9, "description": "Tofu, firm, raw", "food_category": "Legumes and Legume Products", "serving_size_g": 126.0, "household_serving": "1/2 cup", "calories": 88.0, "protein_g": 10.0, "fat_g": 5.3, "carbs_g": 2.2, "fiber_g": 0.4, "sugar_g": 0.7, "sodium_mg": 10.0, "vitamin_a_mcg": 0.0, "vitamin_c_mg": 0.2, "calcium_mg": 253.0, "iron_mg": 1.7, "potassium_mg": 150.0},
    {"fdc_id": 10, "description": "Tempeh", "food_category": "Legumes and Legume Products", "serving_size_g": 84.0, "household_serving": "3 oz", "calories": 162.0, "protein_g": 15.4, "fat_g": 9.0, "carbs_g": 6.4, "fiber_g": 0.0, "sugar_g": 0.0, "sodium_mg": 7.0, "vitamin_a_mcg": 0.0, "vitamin_c_mg": 0.0, "calcium_mg": 92.0, "iron_mg": 2.1, "potassium_mg": 305.0},
    {"fdc_id": 11, "description": "Whey protein powder, unflavored", "food_category": "Supplements", "serving_size_g": 30.0, "household_serving": "1 scoop", "calories": 113.0, "protein_g": 25.0, "fat_g": 0.5, "carbs_g": 1.0, "fiber_g": 0.0, "sugar_g": 0.5, "sodium_mg": 50.0, "vitamin_a_mcg": None, "vitamin_c_mg": None, "calcium_mg": 100.0, "iron_mg": 0.5, "potassium_mg": 150.0},
    {"fdc_id": 12, "description": "Beef, ground, 90% lean, cooked", "food_category": "Beef Products", "serving_size_g": 113.0, "household_serving": "4 oz patty", "calories": 196.0, "protein_g": 28.0, "fat_g": 9.0, "carbs_g": 0.0, "fiber_g": 0.0, "sugar_g": 0.0, "sodium_mg": 76.0, "vitamin_a_mcg": 0.0, "vitamin_c_mg": 0.0, "calcium_mg": 15.0, "iron_mg": 2.9, "potassium_mg": 342.0},
    {"fdc_id": 13, "description": "Shrimp, cooked", "food_category": "Finfish and Shellfish", "serving_size_g": 85.0, "household_serving": "3 oz", "calories": 84.0, "protein_g": 20.4, "fat_g": 0.2, "carbs_g": 0.2, "fiber_g": 0.0, "sugar_g": 0.0, "sodium_mg": 805.0, "vitamin_a_mcg": 0.0, "vitamin_c_mg": 0.0, "calcium_mg": 77.0, "iron_mg": 0.3, "potassium_mg": 155.0},

    # === CARBS / GRAINS ===
    {"fdc_id": 14, "description": "Rice, white, long-grain, cooked", "food_category": "Cereal Grains and Pasta", "serving_size_g": 158.0, "household_serving": "1 cup cooked", "calories": 206.0, "protein_g": 4.3, "fat_g": 0.4, "carbs_g": 45.0, "fiber_g": 0.6, "sugar_g": 0.1, "sodium_mg": 2.0, "vitamin_a_mcg": 0.0, "vitamin_c_mg": 0.0, "calcium_mg": 16.0, "iron_mg": 1.9, "potassium_mg": 55.0},
    {"fdc_id": 15, "description": "Rice, brown, long-grain, cooked", "food_category": "Cereal Grains and Pasta", "serving_size_g": 195.0, "household_serving": "1 cup cooked", "calories": 216.0, "protein_g": 5.0, "fat_g": 1.8, "carbs_g": 45.0, "fiber_g": 3.5, "sugar_g": 0.7, "sodium_mg": 10.0, "vitamin_a_mcg": 0.0, "vitamin_c_mg": 0.0, "calcium_mg": 20.0, "iron_mg": 0.8, "potassium_mg": 84.0},
    {"fdc_id": 16, "description": "Oats, rolled, dry", "food_category": "Cereal Grains and Pasta", "serving_size_g": 40.0, "household_serving": "1/2 cup dry", "calories": 154.0, "protein_g": 5.3, "fat_g": 2.8, "carbs_g": 27.0, "fiber_g": 4.0, "sugar_g": 0.4, "sodium_mg": 0.0, "vitamin_a_mcg": 0.0, "vitamin_c_mg": 0.0, "calcium_mg": 21.0, "iron_mg": 1.5, "potassium_mg": 143.0},
    {"fdc_id": 17, "description": "Sweet potato, baked, flesh only", "food_category": "Vegetables and Vegetable Products", "serving_size_g": 114.0, "household_serving": "1 medium", "calories": 103.0, "protein_g": 2.3, "fat_g": 0.1, "carbs_g": 24.0, "fiber_g": 3.8, "sugar_g": 7.4, "sodium_mg": 41.0, "vitamin_a_mcg": 961.0, "vitamin_c_mg": 19.6, "calcium_mg": 38.0, "iron_mg": 0.7, "potassium_mg": 542.0},
    {"fdc_id": 18, "description": "Banana, raw", "food_category": "Fruits and Fruit Juices", "serving_size_g": 118.0, "household_serving": "1 medium", "calories": 105.0, "protein_g": 1.3, "fat_g": 0.4, "carbs_g": 27.0, "fiber_g": 3.1, "sugar_g": 14.4, "sodium_mg": 1.0, "vitamin_a_mcg": 4.0, "vitamin_c_mg": 10.3, "calcium_mg": 6.0, "iron_mg": 0.3, "potassium_mg": 422.0},
    {"fdc_id": 19, "description": "Bread, whole-wheat", "food_category": "Baked Products", "serving_size_g": 43.0, "household_serving": "1 slice", "calories": 81.0, "protein_g": 4.0, "fat_g": 1.1, "carbs_g": 13.7, "fiber_g": 1.9, "sugar_g": 1.4, "sodium_mg": 146.0, "vitamin_a_mcg": 0.0, "vitamin_c_mg": 0.0, "calcium_mg": 30.0, "iron_mg": 0.7, "potassium_mg": 81.0},
    {"fdc_id": 20, "description": "Quinoa, cooked", "food_category": "Cereal Grains and Pasta", "serving_size_g": 185.0, "household_serving": "1 cup cooked", "calories": 222.0, "protein_g": 8.1, "fat_g": 3.6, "carbs_g": 39.0, "fiber_g": 5.2, "sugar_g": 1.6, "sodium_mg": 13.0, "vitamin_a_mcg": 5.0, "vitamin_c_mg": 0.0, "calcium_mg": 31.0, "iron_mg": 2.8, "potassium_mg": 318.0},
    {"fdc_id": 21, "description": "Pasta, whole-wheat, cooked", "food_category": "Cereal Grains and Pasta", "serving_size_g": 140.0, "household_serving": "1 cup cooked", "calories": 174.0, "protein_g": 7.5, "fat_g": 0.8, "carbs_g": 37.0, "fiber_g": 6.3, "sugar_g": 0.8, "sodium_mg": 4.0, "vitamin_a_mcg": 0.0, "vitamin_c_mg": 0.0, "calcium_mg": 21.0, "iron_mg": 1.5, "potassium_mg": 62.0},
    {"fdc_id": 22, "description": "Apple, raw, with skin", "food_category": "Fruits and Fruit Juices", "serving_size_g": 182.0, "household_serving": "1 medium", "calories": 95.0, "protein_g": 0.5, "fat_g": 0.3, "carbs_g": 25.0, "fiber_g": 4.4, "sugar_g": 19.0, "sodium_mg": 2.0, "vitamin_a_mcg": 3.0, "vitamin_c_mg": 8.4, "calcium_mg": 11.0, "iron_mg": 0.2, "potassium_mg": 195.0},
    {"fdc_id": 23, "description": "Potato, baked, flesh and skin", "food_category": "Vegetables and Vegetable Products", "serving_size_g": 173.0, "household_serving": "1 medium", "calories": 161.0, "protein_g": 4.3, "fat_g": 0.2, "carbs_g": 37.0, "fiber_g": 3.8, "sugar_g": 1.8, "sodium_mg": 17.0, "vitamin_a_mcg": 1.0, "vitamin_c_mg": 16.6, "calcium_mg": 26.0, "iron_mg": 1.9, "potassium_mg": 926.0},

    # === VEGETABLES ===
    {"fdc_id": 24, "description": "Broccoli, cooked, boiled", "food_category": "Vegetables and Vegetable Products", "serving_size_g": 156.0, "household_serving": "1 cup chopped", "calories": 55.0, "protein_g": 3.7, "fat_g": 0.6, "carbs_g": 11.0, "fiber_g": 5.1, "sugar_g": 2.2, "sodium_mg": 64.0, "vitamin_a_mcg": 120.0, "vitamin_c_mg": 101.0, "calcium_mg": 62.0, "iron_mg": 1.1, "potassium_mg": 457.0},
    {"fdc_id": 25, "description": "Spinach, raw", "food_category": "Vegetables and Vegetable Products", "serving_size_g": 30.0, "household_serving": "1 cup", "calories": 7.0, "protein_g": 0.9, "fat_g": 0.1, "carbs_g": 1.1, "fiber_g": 0.7, "sugar_g": 0.1, "sodium_mg": 24.0, "vitamin_a_mcg": 141.0, "vitamin_c_mg": 8.4, "calcium_mg": 30.0, "iron_mg": 0.8, "potassium_mg": 167.0},
    {"fdc_id": 26, "description": "Kale, raw, chopped", "food_category": "Vegetables and Vegetable Products", "serving_size_g": 67.0, "household_serving": "1 cup chopped", "calories": 33.0, "protein_g": 2.2, "fat_g": 0.6, "carbs_g": 6.0, "fiber_g": 1.3, "sugar_g": 1.6, "sodium_mg": 25.0, "vitamin_a_mcg": 241.0, "vitamin_c_mg": 80.0, "calcium_mg": 90.0, "iron_mg": 1.0, "potassium_mg": 296.0},
    {"fdc_id": 27, "description": "Asparagus, cooked, boiled", "food_category": "Vegetables and Vegetable Products", "serving_size_g": 134.0, "household_serving": "6 spears", "calories": 27.0, "protein_g": 3.0, "fat_g": 0.3, "carbs_g": 4.7, "fiber_g": 2.5, "sugar_g": 1.6, "sodium_mg": 18.0, "vitamin_a_mcg": 60.0, "vitamin_c_mg": 7.5, "calcium_mg": 30.0, "iron_mg": 1.1, "potassium_mg": 271.0},
    {"fdc_id": 28, "description": "Green beans, cooked, boiled", "food_category": "Vegetables and Vegetable Products", "serving_size_g": 125.0, "household_serving": "1 cup", "calories": 44.0, "protein_g": 2.4, "fat_g": 0.4, "carbs_g": 10.0, "fiber_g": 4.0, "sugar_g": 3.3, "sodium_mg": 1.0, "vitamin_a_mcg": 44.0, "vitamin_c_mg": 12.1, "calcium_mg": 55.0, "iron_mg": 1.0, "potassium_mg": 182.0},
    {"fdc_id": 29, "description": "Bell pepper, red, raw", "food_category": "Vegetables and Vegetable Products", "serving_size_g": 119.0, "household_serving": "1 medium", "calories": 37.0, "protein_g": 1.2, "fat_g": 0.4, "carbs_g": 7.2, "fiber_g": 2.5, "sugar_g": 5.0, "sodium_mg": 5.0, "vitamin_a_mcg": 187.0, "vitamin_c_mg": 152.0, "calcium_mg": 8.0, "iron_mg": 0.5, "potassium_mg": 251.0},
    {"fdc_id": 30, "description": "Tomato, raw", "food_category": "Vegetables and Vegetable Products", "serving_size_g": 123.0, "household_serving": "1 medium", "calories": 22.0, "protein_g": 1.1, "fat_g": 0.2, "carbs_g": 4.8, "fiber_g": 1.5, "sugar_g": 3.2, "sodium_mg": 6.0, "vitamin_a_mcg": 51.0, "vitamin_c_mg": 16.9, "calcium_mg": 12.0, "iron_mg": 0.3, "potassium_mg": 292.0},
    {"fdc_id": 31, "description": "Avocado, raw", "food_category": "Fruits and Fruit Juices", "serving_size_g": 68.0, "household_serving": "1/3 medium", "calories": 109.0, "protein_g": 1.3, "fat_g": 10.0, "carbs_g": 5.7, "fiber_g": 4.6, "sugar_g": 0.4, "sodium_mg": 5.0, "vitamin_a_mcg": 5.0, "vitamin_c_mg": 6.8, "calcium_mg": 8.0, "iron_mg": 0.4, "potassium_mg": 330.0},
    {"fdc_id": 32, "description": "Cucumber, raw, with peel", "food_category": "Vegetables and Vegetable Products", "serving_size_g": 301.0, "household_serving": "1 large", "calories": 45.0, "protein_g": 2.0, "fat_g": 0.3, "carbs_g": 11.0, "fiber_g": 1.5, "sugar_g": 5.0, "sodium_mg": 6.0, "vitamin_a_mcg": 10.0, "vitamin_c_mg": 8.4, "calcium_mg": 48.0, "iron_mg": 0.8, "potassium_mg": 442.0},
    {"fdc_id": 33, "description": "Mixed salad greens, raw", "food_category": "Vegetables and Vegetable Products", "serving_size_g": 85.0, "household_serving": "3 cups", "calories": 18.0, "protein_g": 1.5, "fat_g": 0.2, "carbs_g": 3.2, "fiber_g": 1.8, "sugar_g": 0.8, "sodium_mg": 27.0, "vitamin_a_mcg": 200.0, "vitamin_c_mg": 18.0, "calcium_mg": 50.0, "iron_mg": 1.1, "potassium_mg": 200.0},

    # === DAIRY ===
    {"fdc_id": 34, "description": "Milk, whole, 3.25% milkfat", "food_category": "Dairy and Egg Products", "serving_size_g": 244.0, "household_serving": "1 cup", "calories": 149.0, "protein_g": 8.0, "fat_g": 8.0, "carbs_g": 12.0, "fiber_g": 0.0, "sugar_g": 12.0, "sodium_mg": 105.0, "vitamin_a_mcg": 68.0, "vitamin_c_mg": 0.0, "calcium_mg": 276.0, "iron_mg": 0.1, "potassium_mg": 322.0},
    {"fdc_id": 35, "description": "Milk, skim (nonfat)", "food_category": "Dairy and Egg Products", "serving_size_g": 245.0, "household_serving": "1 cup", "calories": 83.0, "protein_g": 8.3, "fat_g": 0.2, "carbs_g": 12.0, "fiber_g": 0.0, "sugar_g": 12.0, "sodium_mg": 103.0, "vitamin_a_mcg": 149.0, "vitamin_c_mg": 0.0, "calcium_mg": 299.0, "iron_mg": 0.1, "potassium_mg": 382.0},
    {"fdc_id": 36, "description": "Cheese, cheddar", "food_category": "Dairy and Egg Products", "serving_size_g": 28.0, "household_serving": "1 oz", "calories": 113.0, "protein_g": 7.0, "fat_g": 9.3, "carbs_g": 0.4, "fiber_g": 0.0, "sugar_g": 0.1, "sodium_mg": 185.0, "vitamin_a_mcg": 83.0, "vitamin_c_mg": 0.0, "calcium_mg": 199.0, "iron_mg": 0.2, "potassium_mg": 21.0},
    {"fdc_id": 37, "description": "Butter, salted", "food_category": "Dairy and Egg Products", "serving_size_g": 14.0, "household_serving": "1 tbsp", "calories": 100.0, "protein_g": 0.1, "fat_g": 11.5, "carbs_g": 0.0, "fiber_g": 0.0, "sugar_g": 0.0, "sodium_mg": 82.0, "vitamin_a_mcg": 97.0, "vitamin_c_mg": 0.0, "calcium_mg": 3.0, "iron_mg": 0.0, "potassium_mg": 3.0},
    {"fdc_id": 38, "description": "Cheese, mozzarella, part skim", "food_category": "Dairy and Egg Products", "serving_size_g": 28.0, "household_serving": "1 oz", "calories": 72.0, "protein_g": 7.0, "fat_g": 4.5, "carbs_g": 0.8, "fiber_g": 0.0, "sugar_g": 0.3, "sodium_mg": 175.0, "vitamin_a_mcg": 44.0, "vitamin_c_mg": 0.0, "calcium_mg": 222.0, "iron_mg": 0.1, "potassium_mg": 24.0},

    # === FATS / NUTS ===
    {"fdc_id": 39, "description": "Olive oil, extra virgin", "food_category": "Fats and Oils", "serving_size_g": 14.0, "household_serving": "1 tbsp", "calories": 119.0, "protein_g": 0.0, "fat_g": 14.0, "carbs_g": 0.0, "fiber_g": 0.0, "sugar_g": 0.0, "sodium_mg": 0.0, "vitamin_a_mcg": 0.0, "vitamin_c_mg": 0.0, "calcium_mg": 0.0, "iron_mg": 0.1, "potassium_mg": 0.0},
    {"fdc_id": 40, "description": "Almonds, raw", "food_category": "Nut and Seed Products", "serving_size_g": 28.0, "household_serving": "1 oz (23 almonds)", "calories": 164.0, "protein_g": 6.0, "fat_g": 14.0, "carbs_g": 6.0, "fiber_g": 3.5, "sugar_g": 1.2, "sodium_mg": 0.0, "vitamin_a_mcg": 0.0, "vitamin_c_mg": 0.0, "calcium_mg": 76.0, "iron_mg": 1.0, "potassium_mg": 208.0},
    {"fdc_id": 41, "description": "Peanut butter, smooth", "food_category": "Legumes and Legume Products", "serving_size_g": 32.0, "household_serving": "2 tbsp", "calories": 188.0, "protein_g": 8.0, "fat_g": 16.0, "carbs_g": 6.0, "fiber_g": 2.0, "sugar_g": 3.0, "sodium_mg": 136.0, "vitamin_a_mcg": 0.0, "vitamin_c_mg": 0.0, "calcium_mg": 17.0, "iron_mg": 0.6, "potassium_mg": 189.0},
    {"fdc_id": 42, "description": "Walnuts, raw", "food_category": "Nut and Seed Products", "serving_size_g": 28.0, "household_serving": "1 oz (14 halves)", "calories": 185.0, "protein_g": 4.3, "fat_g": 18.5, "carbs_g": 3.9, "fiber_g": 1.9, "sugar_g": 0.7, "sodium_mg": 1.0, "vitamin_a_mcg": 0.0, "vitamin_c_mg": 0.4, "calcium_mg": 28.0, "iron_mg": 0.8, "potassium_mg": 125.0},
    {"fdc_id": 43, "description": "Coconut oil", "food_category": "Fats and Oils", "serving_size_g": 14.0, "household_serving": "1 tbsp", "calories": 121.0, "protein_g": 0.0, "fat_g": 14.0, "carbs_g": 0.0, "fiber_g": 0.0, "sugar_g": 0.0, "sodium_mg": 0.0, "vitamin_a_mcg": 0.0, "vitamin_c_mg": 0.0, "calcium_mg": 0.0, "iron_mg": 0.0, "potassium_mg": 0.0},

    # === OTHER / MISC ===
    {"fdc_id": 44, "description": "Honey", "food_category": "Sweets", "serving_size_g": 21.0, "household_serving": "1 tbsp", "calories": 64.0, "protein_g": 0.1, "fat_g": 0.0, "carbs_g": 17.3, "fiber_g": 0.0, "sugar_g": 17.2, "sodium_mg": 1.0, "vitamin_a_mcg": 0.0, "vitamin_c_mg": 0.1, "calcium_mg": 1.0, "iron_mg": 0.1, "potassium_mg": 11.0},
    {"fdc_id": 45, "description": "Protein bar, chocolate (generic)", "food_category": "Supplements", "serving_size_g": 60.0, "household_serving": "1 bar", "calories": 210.0, "protein_g": 20.0, "fat_g": 7.0, "carbs_g": 22.0, "fiber_g": 3.0, "sugar_g": 6.0, "sodium_mg": 200.0, "vitamin_a_mcg": None, "vitamin_c_mg": None, "calcium_mg": 100.0, "iron_mg": 2.0, "potassium_mg": 150.0},
    {"fdc_id": 46, "description": "Sports drink (generic)", "food_category": "Beverages", "serving_size_g": 360.0, "household_serving": "12 fl oz", "calories": 75.0, "protein_g": 0.0, "fat_g": 0.0, "carbs_g": 21.0, "fiber_g": 0.0, "sugar_g": 21.0, "sodium_mg": 165.0, "vitamin_a_mcg": None, "vitamin_c_mg": None, "calcium_mg": 0.0, "iron_mg": 0.0, "potassium_mg": 46.0},
    {"fdc_id": 47, "description": "Lentils, cooked, boiled", "food_category": "Legumes and Legume Products", "serving_size_g": 198.0, "household_serving": "1 cup cooked", "calories": 230.0, "protein_g": 18.0, "fat_g": 0.8, "carbs_g": 40.0, "fiber_g": 15.6, "sugar_g": 3.6, "sodium_mg": 4.0, "vitamin_a_mcg": 2.0, "vitamin_c_mg": 3.0, "calcium_mg": 38.0, "iron_mg": 6.6, "potassium_mg": 731.0},
    {"fdc_id": 48, "description": "Chickpeas, canned, drained", "food_category": "Legumes and Legume Products", "serving_size_g": 164.0, "household_serving": "1 cup", "calories": 210.0, "protein_g": 10.7, "fat_g": 3.8, "carbs_g": 35.0, "fiber_g": 9.6, "sugar_g": 5.0, "sodium_mg": 410.0, "vitamin_a_mcg": 2.0, "vitamin_c_mg": 0.8, "calcium_mg": 62.0, "iron_mg": 2.4, "potassium_mg": 293.0},
    {"fdc_id": 49, "description": "Blueberries, raw", "food_category": "Fruits and Fruit Juices", "serving_size_g": 148.0, "household_serving": "1 cup", "calories": 84.0, "protein_g": 1.1, "fat_g": 0.5, "carbs_g": 21.0, "fiber_g": 3.6, "sugar_g": 15.0, "sodium_mg": 1.0, "vitamin_a_mcg": 4.0, "vitamin_c_mg": 14.4, "calcium_mg": 9.0, "iron_mg": 0.4, "potassium_mg": 114.0},
    {"fdc_id": 50, "description": "Strawberries, raw", "food_category": "Fruits and Fruit Juices", "serving_size_g": 152.0, "household_serving": "1 cup", "calories": 49.0, "protein_g": 1.0, "fat_g": 0.5, "carbs_g": 11.7, "fiber_g": 3.0, "sugar_g": 7.4, "sodium_mg": 2.0, "vitamin_a_mcg": 2.0, "vitamin_c_mg": 89.4, "calcium_mg": 24.0, "iron_mg": 0.6, "potassium_mg": 233.0},
    {"fdc_id": 51, "description": "Orange, raw", "food_category": "Fruits and Fruit Juices", "serving_size_g": 131.0, "household_serving": "1 medium", "calories": 62.0, "protein_g": 1.2, "fat_g": 0.2, "carbs_g": 15.4, "fiber_g": 3.1, "sugar_g": 12.2, "sodium_mg": 0.0, "vitamin_a_mcg": 14.0, "vitamin_c_mg": 70.0, "calcium_mg": 52.0, "iron_mg": 0.1, "potassium_mg": 237.0},
    {"fdc_id": 52, "description": "Beef steak, sirloin, cooked", "food_category": "Beef Products", "serving_size_g": 113.0, "household_serving": "4 oz", "calories": 207.0, "protein_g": 33.0, "fat_g": 7.6, "carbs_g": 0.0, "fiber_g": 0.0, "sugar_g": 0.0, "sodium_mg": 60.0, "vitamin_a_mcg": 0.0, "vitamin_c_mg": 0.0, "calcium_mg": 7.0, "iron_mg": 1.8, "potassium_mg": 364.0},
]


def create_schema(conn: sqlite3.Connection):
    """Create the food database schema."""
    conn.execute("""
        CREATE TABLE IF NOT EXISTS foods (
            fdc_id         INTEGER PRIMARY KEY,
            description    TEXT NOT NULL,
            food_category  TEXT,
            serving_size_g REAL DEFAULT 100.0,
            household_serving TEXT,
            calories       REAL DEFAULT 0,
            protein_g      REAL DEFAULT 0,
            fat_g          REAL DEFAULT 0,
            carbs_g        REAL DEFAULT 0,
            fiber_g        REAL DEFAULT 0,
            sugar_g        REAL DEFAULT 0,
            sodium_mg      REAL DEFAULT 0,
            vitamin_a_mcg  REAL,
            vitamin_c_mg   REAL,
            calcium_mg     REAL,
            iron_mg        REAL,
            potassium_mg   REAL
        )
    """)

    # FTS5 full-text search index on description + food_category
    conn.execute("""
        CREATE VIRTUAL TABLE IF NOT EXISTS foods_fts USING fts5(
            description,
            food_category,
            content='foods',
            content_rowid='fdc_id'
        )
    """)

    # Triggers to keep FTS index in sync
    conn.execute("""
        CREATE TRIGGER IF NOT EXISTS foods_ai AFTER INSERT ON foods BEGIN
            INSERT INTO foods_fts(rowid, description, food_category)
            VALUES (new.fdc_id, new.description, new.food_category);
        END
    """)
    conn.execute("""
        CREATE TRIGGER IF NOT EXISTS foods_ad AFTER DELETE ON foods BEGIN
            INSERT INTO foods_fts(foods_fts, rowid, description, food_category)
            VALUES ('delete', old.fdc_id, old.description, old.food_category);
        END
    """)
    conn.execute("""
        CREATE TRIGGER IF NOT EXISTS foods_au AFTER UPDATE ON foods BEGIN
            INSERT INTO foods_fts(foods_fts, rowid, description, food_category)
            VALUES ('delete', old.fdc_id, old.description, old.food_category);
            INSERT INTO foods_fts(rowid, description, food_category)
            VALUES (new.fdc_id, new.description, new.food_category);
        END
    """)

    conn.execute("CREATE INDEX IF NOT EXISTS idx_foods_category ON foods(food_category)")
    conn.commit()


def insert_seed_data(conn: sqlite3.Connection):
    """Insert common fitness-relevant foods as seed data."""
    columns = [
        "fdc_id", "description", "food_category", "serving_size_g",
        "household_serving", "calories", "protein_g", "fat_g", "carbs_g",
        "fiber_g", "sugar_g", "sodium_mg", "vitamin_a_mcg", "vitamin_c_mg",
        "calcium_mg", "iron_mg", "potassium_mg",
    ]
    placeholders = ", ".join(["?"] * len(columns))
    col_names = ", ".join(columns)

    for food in COMMON_FOODS:
        values = [food.get(col) for col in columns]
        conn.execute(
            f"INSERT OR REPLACE INTO foods ({col_names}) VALUES ({placeholders})",
            values,
        )
    conn.commit()
    print(f"Inserted {len(COMMON_FOODS)} seed foods")


def process_usda_csvs(conn: sqlite3.Connection, csv_dir: str):
    """Process USDA SR Legacy CSV files and load into database."""
    csv_path = Path(csv_dir)

    food_csv = csv_path / "food.csv"
    nutrient_csv = csv_path / "nutrient.csv"
    food_nutrient_csv = csv_path / "food_nutrient.csv"

    for f in [food_csv, nutrient_csv, food_nutrient_csv]:
        if not f.exists():
            print(f"WARNING: {f} not found, skipping CSV import")
            return

    # Step 1: Build nutrient ID -> column name mapping from nutrient.csv
    print("Reading nutrient definitions...")
    nutrient_id_map = {}
    with open(nutrient_csv, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            nid = int(row["id"])
            if nid in NUTRIENT_IDS:
                nutrient_id_map[nid] = NUTRIENT_IDS[nid]

    # Step 2: Build fdc_id -> nutrients mapping from food_nutrient.csv
    print("Reading food nutrients (this may take a while)...")
    food_nutrients: dict[int, dict[str, float]] = {}
    with open(food_nutrient_csv, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            nid = int(row["nutrient_id"])
            if nid not in nutrient_id_map:
                continue
            fdc_id = int(row["fdc_id"])
            col_name = nutrient_id_map[nid]
            amount = float(row["amount"]) if row["amount"] else 0.0
            if fdc_id not in food_nutrients:
                food_nutrients[fdc_id] = {}
            food_nutrients[fdc_id][col_name] = amount

    # Step 3: Read foods and merge with nutrients
    print("Reading foods and merging nutrients...")
    count = 0
    with open(food_csv, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            fdc_id = int(row["fdc_id"])
            description = row.get("description", "Unknown")
            food_category = row.get("food_category_id", None)
            nutrients = food_nutrients.get(fdc_id, {})

            conn.execute(
                """INSERT OR REPLACE INTO foods
                   (fdc_id, description, food_category, serving_size_g,
                    calories, protein_g, fat_g, carbs_g, fiber_g, sugar_g,
                    sodium_mg, vitamin_a_mcg, vitamin_c_mg, calcium_mg,
                    iron_mg, potassium_mg)
                   VALUES (?, ?, ?, 100.0, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                (
                    fdc_id,
                    description,
                    food_category,
                    nutrients.get("calories", 0),
                    nutrients.get("protein_g", 0),
                    nutrients.get("fat_g", 0),
                    nutrients.get("carbs_g", 0),
                    nutrients.get("fiber_g", 0),
                    nutrients.get("sugar_g", 0),
                    nutrients.get("sodium_mg", 0),
                    nutrients.get("vitamin_a_mcg"),
                    nutrients.get("vitamin_c_mg"),
                    nutrients.get("calcium_mg"),
                    nutrients.get("iron_mg"),
                    nutrients.get("potassium_mg"),
                ),
            )
            count += 1
            if count % 5000 == 0:
                conn.commit()
                print(f"  Processed {count} foods...")

    conn.commit()
    print(f"Imported {count} foods from USDA CSV files")


def export_seed_json(output_path: str):
    """Export seed data as JSON for Flutter asset embedding."""
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(COMMON_FOODS, f, indent=2)
    print(f"Exported seed data JSON to {output_path}")


def main():
    parser = argparse.ArgumentParser(
        description="Build the USDA food database for offline nutrition lookup."
    )
    parser.add_argument(
        "--csv-dir",
        help="Directory containing USDA SR Legacy CSV files",
    )
    parser.add_argument(
        "--output",
        default="mobile/flutter/assets/food_database.db",
        help="Output SQLite database path",
    )
    parser.add_argument(
        "--json",
        default="mobile/flutter/assets/data/food_seed_data.json",
        help="Output seed data JSON path (for Flutter asset)",
    )
    args = parser.parse_args()

    # Ensure output directories exist
    os.makedirs(os.path.dirname(args.output) or ".", exist_ok=True)
    os.makedirs(os.path.dirname(args.json) or ".", exist_ok=True)

    # Build SQLite database
    print(f"Creating database at {args.output}...")
    conn = sqlite3.connect(args.output)
    create_schema(conn)

    if args.csv_dir:
        process_usda_csvs(conn, args.csv_dir)
    else:
        print("No --csv-dir provided, using seed data only")
        insert_seed_data(conn)

    # Verify
    cursor = conn.execute("SELECT COUNT(*) FROM foods")
    total = cursor.fetchone()[0]
    print(f"Database contains {total} foods")

    # Test FTS search (join back to main table for full data)
    cursor = conn.execute(
        "SELECT f.fdc_id, f.description FROM foods f "
        "JOIN foods_fts ON f.fdc_id = foods_fts.rowid "
        "WHERE foods_fts MATCH 'chicken'"
    )
    results = cursor.fetchall()
    print(f"FTS test 'chicken': {len(results)} results")
    for row in results[:3]:
        print(f"  - [{row[0]}] {row[1]}")

    conn.close()

    # Export seed JSON for Flutter
    export_seed_json(args.json)
    print("Done!")


if __name__ == "__main__":
    main()
