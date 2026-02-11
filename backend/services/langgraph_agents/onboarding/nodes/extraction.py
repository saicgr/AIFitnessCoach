"""
Data extraction node for onboarding.

Contains the node that extracts structured data from user messages using AI
and pattern matching.
"""

import json
import re
import time
from typing import Dict, Any

from langchain_core.messages import HumanMessage, SystemMessage

from core.gemini_client import get_langchain_llm
from ..state import OnboardingState
from ..prompts import DATA_EXTRACTION_SYSTEM_PROMPT, REQUIRED_FIELDS
from .utils import ensure_string, get_field_value, detect_non_gym_activity
from core.config import get_settings
from core.logger import get_logger
from services.training_program_service import get_training_program_map_sync

logger = get_logger(__name__)
settings = get_settings()


def _extract_name(user_message: str) -> str:
    """Extract name from user message using pattern matching."""
    user_lower = user_message.lower().strip()

    name_patterns = [
        r"(?:my name is|i'm|i am|call me|it's|im)\s+([a-zA-Z][a-zA-Z\s'-]*?)(?:,|\.|\!|$|\s+i'm|\s+i am|\s+and)",
        r"^([a-zA-Z][a-zA-Z'-]*?)(?:,|\.|\!|$)",
    ]

    for pattern in name_patterns:
        match = re.search(pattern, user_lower, re.IGNORECASE)
        if match:
            name = match.group(1).strip().title()
            common_words = {'the', 'and', 'or', 'but', 'if', 'then', 'yes', 'no', 'ok', 'okay', 'hi', 'hey', 'what', 'how', 'when', 'where', 'why'}
            if len(name) <= 30 and name.lower() not in common_words:
                return name
    return None


def _extract_age(user_message: str) -> int:
    """Extract age from user message using pattern matching."""
    age_patterns = [
        r"(?:i'm|i am|age|aged)\s*(\d{1,3})\s*(?:years?\s*old)?",
        r"(\d{1,3})\s*years?\s*old",
        r"^(\d{1,3})$",
    ]

    for pattern in age_patterns:
        match = re.search(pattern, user_message, re.IGNORECASE)
        if match:
            age = int(match.group(1))
            if 13 <= age <= 100:
                return age
    return None


def _extract_gender(user_message: str) -> str:
    """Extract gender from user message."""
    user_lower = user_message.lower()

    if 'male' in user_lower and 'female' not in user_lower:
        return "male"
    elif 'female' in user_lower:
        return "female"
    elif user_lower.strip() in ['m', 'man', 'guy', 'boy']:
        return "male"
    elif user_lower.strip() in ['f', 'woman', 'girl', 'lady']:
        return "female"
    return None


def _extract_height(user_message: str) -> int:
    """Extract height in cm from user message."""
    user_lower = user_message.lower()

    cm_match = re.search(r'(\d{2,3})\s*(?:cm|centimeters?)', user_lower)
    m_match = re.search(r'(\d+)[.,](\d+)\s*(?:m|meters?)', user_lower)
    ft_in_match = re.search(r"(\d+)['\s]*(?:feet?|ft)?['\s]*(\d+)?[\"]*(?:\s*(?:inches?|in))?", user_lower)

    if cm_match:
        height = int(cm_match.group(1))
        if 100 <= height <= 250:
            return height
    elif m_match:
        meters = float(f"{m_match.group(1)}.{m_match.group(2)}")
        height = int(meters * 100)
        if 100 <= height <= 250:
            return height
    elif ft_in_match:
        feet = int(ft_in_match.group(1))
        inches = int(ft_in_match.group(2)) if ft_in_match.group(2) else 0
        height = int((feet * 12 + inches) * 2.54)
        if 100 <= height <= 250:
            return height
    return None


def _extract_weight(user_message: str) -> float:
    """Extract weight in kg from user message."""
    user_lower = user_message.lower()

    kg_match = re.search(r'(\d{2,3}(?:\.\d+)?)\s*(?:kg|kilograms?|kilos?)', user_lower)
    lbs_match = re.search(r'(\d{2,3}(?:\.\d+)?)\s*(?:lbs?|pounds?)', user_lower)
    weigh_match = re.search(r'weigh\s+(\d{2,3}(?:\.\d+)?)\s*(?:kg|kilograms?|kilos?)?', user_lower)

    if kg_match:
        weight = float(kg_match.group(1))
        if 30 <= weight <= 300:
            return round(weight, 1)
    elif weigh_match:
        weight = float(weigh_match.group(1))
        if 30 <= weight <= 300:
            return round(weight, 1)
    elif lbs_match:
        lbs = float(lbs_match.group(1))
        weight = round(lbs * 0.453592, 1)
        if 30 <= weight <= 300:
            return weight
    return None


def _extract_days_per_week(user_message: str) -> int:
    """Extract days per week from user message."""
    stripped = user_message.strip()

    if stripped in ["1", "2", "3", "4", "5", "6", "7"]:
        return int(stripped)
    elif stripped.lower() in ["1 day", "2 days", "3 days", "4 days", "5 days", "6 days", "7 days"]:
        return int(stripped.split()[0])
    return None


def _extract_workout_duration(user_message: str) -> int:
    """Extract workout duration in minutes from user message."""
    stripped = user_message.strip()

    if stripped in ["30", "45", "60", "90"]:
        return int(stripped)
    elif stripped.lower() in ["30 min", "45 min", "60 min", "90 min"]:
        return int(stripped.split()[0])
    return None


def _extract_selected_days(user_message: str) -> list:
    """Extract selected workout days from user message."""
    day_name_to_index = {
        'monday': 0, 'tuesday': 1, 'wednesday': 2, 'thursday': 3,
        'friday': 4, 'saturday': 5, 'sunday': 6,
        'mon': 0, 'tue': 1, 'wed': 2, 'thu': 3, 'fri': 4, 'sat': 5, 'sun': 6
    }
    user_lower = user_message.strip().lower()

    selected_indices = []
    for day_name, idx in day_name_to_index.items():
        if day_name in user_lower:
            if idx not in selected_indices:
                selected_indices.append(idx)

    if selected_indices:
        selected_indices.sort()
        return selected_indices
    return None


def _extract_equipment(user_message: str, existing_equipment: list = None) -> list:
    """Extract equipment from user message.

    Returns lowercase with underscores to match Flutter app format:
    - full_gym, dumbbells, barbell, resistance_bands, pull_up_bar, kettlebell, cable_machine
    """
    equipment_map = {
        'full gym': 'full_gym',
        'dumbbells': 'dumbbells',
        'dumbbell': 'dumbbells',
        'resistance bands': 'resistance_bands',
        'resistance band': 'resistance_bands',
        'bands': 'resistance_bands',
        'bodyweight only': 'bodyweight',
        'bodyweight': 'bodyweight',
        'barbell': 'barbell',
        'kettlebell': 'kettlebell',
        'kettlebells': 'kettlebell',
        'cable machine': 'cable_machine',
        'cable': 'cable_machine',
        'pull-up bar': 'pull_up_bar',
        'pull up bar': 'pull_up_bar',
        'bench': 'bench',
    }

    user_lower = user_message.strip().lower()
    matched_equipment = []

    if user_lower in equipment_map:
        matched_equipment.append(equipment_map[user_lower])
    else:
        for key, value in equipment_map.items():
            if key in user_lower:
                if value not in matched_equipment:
                    matched_equipment.append(value)

    if matched_equipment:
        existing = existing_equipment or []
        return list(set(existing + matched_equipment))
    return None


def _extract_goals(user_message: str, existing_goals: list = None) -> list:
    """Extract fitness goals from user message."""
    goals_map = {
        'build muscle': 'Build Muscle',
        'muscle': 'Build Muscle',
        'lose weight': 'Lose Weight',
        'weight loss': 'Lose Weight',
        'fat loss': 'Lose Weight',
        'increase strength': 'Increase Strength',
        'get stronger': 'Increase Strength',
        'strength': 'Increase Strength',
        'improve endurance': 'Improve Endurance',
        'endurance': 'Improve Endurance',
        'cardio': 'Improve Endurance',
        'general fitness': 'General Fitness',
        'stay fit': 'General Fitness',
        'stay healthy': 'General Fitness',
        'tone': 'General Fitness',
        'toning': 'General Fitness',
    }

    training_program_map = get_training_program_map_sync()

    user_lower = user_message.strip().lower()
    matched_goals = []

    if user_lower in goals_map:
        matched_goals.append(goals_map[user_lower])
    else:
        for key, value in goals_map.items():
            if key in user_lower:
                if value not in matched_goals:
                    matched_goals.append(value)

    for key, goals_list in training_program_map.items():
        if key in user_lower:
            for goal in goals_list:
                if goal not in matched_goals:
                    matched_goals.append(goal)

    if matched_goals:
        existing = existing_goals or []
        return list(set(existing + matched_goals))
    return None


def _extract_fitness_level(user_message: str) -> str:
    """Extract fitness level from user message."""
    fitness_level_map = {
        'beginner': 'beginner',
        'newbie': 'beginner',
        'new': 'beginner',
        'intermediate': 'intermediate',
        'medium': 'intermediate',
        'advanced': 'advanced',
        'expert': 'advanced',
        'pro': 'advanced',
    }

    user_lower = user_message.strip().lower()
    if user_lower in fitness_level_map:
        return fitness_level_map[user_lower]
    return None


def _extract_training_experience(user_message: str) -> str:
    """Extract training experience from user message."""
    experience_map = {
        'never': 'never',
        'never lifted': 'never',
        'first time': 'never',
        'brand new': 'never',
        'few weeks': 'less_than_6_months',
        'few months': 'less_than_6_months',
        'couple months': 'less_than_6_months',
        'less than 6 months': 'less_than_6_months',
        '6 months': '6_months_to_2_years',
        'a year': '6_months_to_2_years',
        'about a year': '6_months_to_2_years',
        '1 year': '6_months_to_2_years',
        '2 years': '6_months_to_2_years',
        'couple years': '6_months_to_2_years',
        '2-5 years': '2_to_5_years',
        '3 years': '2_to_5_years',
        '4 years': '2_to_5_years',
        'few years': '2_to_5_years',
        'several years': '2_to_5_years',
        '5+ years': '5_plus_years',
        '5 years': '5_plus_years',
        'over 5 years': '5_plus_years',
        'many years': '5_plus_years',
        'long time': '5_plus_years',
        'decade': '5_plus_years',
        '10 years': '5_plus_years',
    }

    user_lower = user_message.strip().lower()
    for key, value in experience_map.items():
        if key in user_lower:
            return value
    return None


def _extract_workout_environment(user_message: str) -> str:
    """Extract workout environment from user message."""
    environment_map = {
        'commercial gym': 'commercial_gym',
        'gym': 'commercial_gym',
        'fitness center': 'commercial_gym',
        'la fitness': 'commercial_gym',
        'planet fitness': 'commercial_gym',
        'equinox': 'commercial_gym',
        '24 hour': 'commercial_gym',
        'home gym': 'home_gym',
        'garage gym': 'home_gym',
        'basement gym': 'home_gym',
        'home': 'home',
        'living room': 'home',
        'outdoors': 'outdoors',
        'outside': 'outdoors',
        'park': 'outdoors',
        'backyard': 'outdoors',
        'hotel': 'hotel',
        'travel': 'hotel',
        'on the road': 'hotel',
        # New environments
        'apartment gym': 'apartment_gym',
        'building gym': 'apartment_gym',
        'condo gym': 'apartment_gym',
        'office gym': 'office_gym',
        'work gym': 'office_gym',
        'workplace gym': 'office_gym',
        'custom': 'custom',
        'my own setup': 'custom',
        'my own equipment': 'custom',
    }

    user_lower = user_message.strip().lower()
    for key, value in environment_map.items():
        if key in user_lower:
            return value
    return None


def _extract_focus_areas(user_message: str) -> list:
    """Extract focus areas from user message."""
    focus_map = {
        'chest': 'chest',
        'pecs': 'chest',
        'back': 'back',
        'lats': 'back',
        'shoulders': 'shoulders',
        'delts': 'shoulders',
        'arms': 'arms',
        'biceps': 'arms',
        'triceps': 'arms',
        'core': 'core',
        'abs': 'core',
        'legs': 'legs',
        'quads': 'legs',
        'hamstrings': 'legs',
        'glutes': 'glutes',
        'booty': 'glutes',
        'butt': 'glutes',
        'full body': 'full_body',
        'everything': 'full_body',
        'balanced': 'full_body',
    }

    user_lower = user_message.strip().lower()
    found_areas = []

    for key, value in focus_map.items():
        if key in user_lower and value not in found_areas:
            found_areas.append(value)

    return found_areas if found_areas else None


def _extract_workout_variety(user_message: str) -> str:
    """Extract workout variety preference from user message."""
    variety_map = {
        'consistent': 'consistent',
        'same exercises': 'consistent',
        'same': 'consistent',
        'track progress': 'consistent',
        'varied': 'varied',
        'mix it up': 'varied',
        'mix up': 'varied',
        'variety': 'varied',
        'fresh': 'varied',
        'mixed': 'mixed',
        'both': 'mixed',
        'both!': 'mixed',
    }

    user_lower = user_message.strip().lower()
    for key, value in variety_map.items():
        if key in user_lower:
            return value
    return None


def _extract_biggest_obstacle(user_message: str) -> str:
    """Extract biggest obstacle from user message."""
    obstacle_map = {
        'time': 'time',
        'busy': 'time',
        'schedule': 'time',
        'motivation': 'motivation',
        'lazy': 'motivation',
        'unmotivated': 'motivation',
        'consistency': 'consistency',
        'consistent': 'consistency',
        'stick with it': 'consistency',
        'knowledge': 'knowledge',
        "don't know": 'knowledge',
        'not sure': 'knowledge',
        'injuries': 'injuries',
        'injury': 'injuries',
        'pain': 'injuries',
        'boredom': 'boredom',
        'boring': 'boredom',
        'bored': 'boredom',
        'life events': 'life_events',
        'life': 'life_events',
    }

    user_lower = user_message.strip().lower()
    for key, value in obstacle_map.items():
        if key in user_lower:
            return value
    return None


def _extract_target_weight(user_message: str, current_weight_kg: float = None) -> dict:
    """
    Extract target weight from user message.

    Returns a dict that can contain:
    - target_weight_delta: relative change like "lose_10", "gain_20"
    - target_weight_kg: absolute target weight in kg

    If user selects a relative option and we know current weight, we calculate the absolute.
    """
    user_lower = user_message.strip().lower()
    result = {}

    # Check for skip/happy where I am
    skip_patterns = ['happy where i am', 'happy where you are', 'not sure', '__skip__', 'skip']
    for pattern in skip_patterns:
        if pattern in user_lower:
            result["target_weight_delta"] = "__skip__"
            return result

    # Check for relative weight changes (quick reply values)
    relative_patterns = {
        'lose_10': ('lose', 10, -1),
        'lose_20': ('lose', 20, -1),
        'lose_30': ('lose', 30, -1),
        'gain_10': ('gain', 10, 1),
        'gain_20': ('gain', 20, 1),
    }

    # Direct quick reply value match
    for delta_key in relative_patterns.keys():
        if delta_key in user_lower:
            result["target_weight_delta"] = delta_key
            if current_weight_kg:
                _, lbs, direction = relative_patterns[delta_key]
                kg_change = lbs * 0.453592 * direction
                result["target_weight_kg"] = round(current_weight_kg + kg_change, 1)
            return result

    # Natural language patterns for relative changes
    lose_match = re.search(r'lose\s+(\d+)\s*(?:lbs?|pounds?|kg|kilos?)?', user_lower)
    gain_match = re.search(r'gain\s+(\d+)\s*(?:lbs?|pounds?|kg|kilos?)?', user_lower)

    if lose_match:
        amount = int(lose_match.group(1))
        is_kg = 'kg' in user_lower or 'kilo' in user_lower

        if amount <= 15:
            result["target_weight_delta"] = "lose_10"
        elif amount <= 25:
            result["target_weight_delta"] = "lose_20"
        else:
            result["target_weight_delta"] = "lose_30"

        if current_weight_kg:
            kg_change = amount if is_kg else amount * 0.453592
            result["target_weight_kg"] = round(current_weight_kg - kg_change, 1)
        return result

    if gain_match:
        amount = int(gain_match.group(1))
        is_kg = 'kg' in user_lower or 'kilo' in user_lower

        if amount <= 15:
            result["target_weight_delta"] = "gain_10"
        else:
            result["target_weight_delta"] = "gain_20"

        if current_weight_kg:
            kg_change = amount if is_kg else amount * 0.453592
            result["target_weight_kg"] = round(current_weight_kg + kg_change, 1)
        return result

    # Absolute target weight patterns
    # "want to be 160 lbs", "goal is 70kg", "drop to 150"
    absolute_patterns = [
        r'(?:want to (?:be|weigh)|goal (?:is|weight)|target (?:is|weight)|drop to|get to|aim for)\s*(\d{2,3})\s*(?:lbs?|pounds?)?',
        r'(\d{2,3})\s*(?:lbs?|pounds?|kg|kilos?)\s*(?:goal|target)?',
    ]

    for pattern in absolute_patterns:
        match = re.search(pattern, user_lower)
        if match:
            target = float(match.group(1))
            is_kg = 'kg' in user_lower or 'kilo' in user_lower

            if not is_kg:
                # Convert lbs to kg
                target = round(target * 0.453592, 1)

            if 30 <= target <= 200:  # Reasonable weight range in kg
                result["target_weight_kg"] = target

                # Calculate delta if we know current weight
                if current_weight_kg:
                    diff_kg = target - current_weight_kg
                    diff_lbs = diff_kg / 0.453592

                    if diff_lbs < -25:
                        result["target_weight_delta"] = "lose_30"
                    elif diff_lbs < -15:
                        result["target_weight_delta"] = "lose_20"
                    elif diff_lbs < -5:
                        result["target_weight_delta"] = "lose_10"
                    elif diff_lbs > 15:
                        result["target_weight_delta"] = "gain_20"
                    elif diff_lbs > 5:
                        result["target_weight_delta"] = "gain_10"
                    else:
                        result["target_weight_delta"] = "__skip__"  # Very close to current weight

                return result

    return result


async def extract_data_node(state: OnboardingState) -> Dict[str, Any]:
    """
    Extract structured data from user's message using AI.

    Uses pattern matching for simple extractions and falls back to AI
    for complex messages.

    Args:
        state: The current onboarding state

    Returns:
        Updated state with collected data and validation errors
    """
    start_time = time.time()
    logger.info("=" * 60)
    logger.info("[Extract Data] STARTING DATA EXTRACTION")
    logger.info("=" * 60)

    user_message = ensure_string(state.get("user_message", ""))
    collected_data = state.get("collected_data", {})

    # Auto-fill past_programs from trainingSplit if available
    # If user selected a specific training split in the quiz, they have experience with it
    training_split = get_field_value(collected_data, "trainingSplit") or get_field_value(collected_data, "training_split")
    past_programs = get_field_value(collected_data, "past_programs")

    if training_split and not past_programs:
        split_to_program_map = {
            "push_pull_legs": ["ppl"],
            "ppl": ["ppl"],
            "bro_split": ["bro_split"],
            "upper_lower": ["upper_lower"],
            "full_body": ["full_body"],
            "body_part": ["bro_split"],
        }
        inferred_program = split_to_program_map.get(training_split.lower())
        if inferred_program:
            collected_data["past_programs"] = inferred_program
            logger.info(f"[Extract Data] Auto-filled past_programs={inferred_program} from trainingSplit={training_split}")

    # Calculate what's missing
    missing = []
    for field in REQUIRED_FIELDS:
        value = get_field_value(collected_data, field)
        if value is None or value == "" or (isinstance(value, list) and len(value) == 0):
            missing.append(field)

    logger.info(f"[Extract Data] Collected data keys: {list(collected_data.keys())}")
    logger.info(f"[Extract Data] Current missing fields: {missing}")
    logger.info(f"[Extract Data] User message: {user_message}")

    # Non-gym activity detection
    if "goals" in missing:
        non_gym_info = detect_non_gym_activity(user_message)
        if non_gym_info:
            activity_goals = {
                'walking': ["General Fitness", "Flexibility", "Improve Endurance"],
                'step counting': ["General Fitness", "Flexibility", "Improve Endurance"],
                'outdoor cycling': ["General Fitness", "Increase Strength", "Improve Endurance"],
                'mountain biking': ["General Fitness", "Increase Strength", "Improve Endurance"],
                'jogging': ["General Fitness", "Flexibility", "Improve Endurance"],
                'running': ["General Fitness", "Flexibility", "Improve Endurance"],
                'meditation': ["General Fitness", "Flexibility"],
                'recreational sports': ["General Fitness", "Flexibility"],
                'stretching': ["General Fitness", "Flexibility"],
            }
            goals = activity_goals.get(non_gym_info['activity'], ["General Fitness", "Flexibility"])
            logger.info(f"[Extract Data] Non-gym activity detected, setting goals: {goals}")
            return {
                "collected_data": {**collected_data, "goals": goals},
                "validation_errors": {},
            }

    # Pre-processing: Extract data using pattern matching
    extracted = {}

    if "name" in missing:
        name = _extract_name(user_message)
        if name:
            extracted["name"] = name
            logger.info(f"[Extract Data] Pre-processed: name = {name}")

    if "age" in missing:
        age = _extract_age(user_message)
        if age:
            extracted["age"] = age
            logger.info(f"[Extract Data] Pre-processed: age = {age}")

    if "gender" in missing:
        gender = _extract_gender(user_message)
        if gender:
            extracted["gender"] = gender
            logger.info(f"[Extract Data] Pre-processed: gender = {gender}")

    if "heightCm" in missing:
        height = _extract_height(user_message)
        if height:
            extracted["heightCm"] = height
            logger.info(f"[Extract Data] Pre-processed: heightCm = {height}")

    if "weightKg" in missing:
        weight = _extract_weight(user_message)
        if weight:
            extracted["weightKg"] = weight
            logger.info(f"[Extract Data] Pre-processed: weightKg = {weight}")

    if "days_per_week" in missing:
        days = _extract_days_per_week(user_message)
        if days:
            extracted["days_per_week"] = days
            logger.info(f"[Extract Data] Pre-processed: days_per_week = {days}")

    if "workout_duration" in missing:
        duration = _extract_workout_duration(user_message)
        if duration:
            extracted["workout_duration"] = duration
            logger.info(f"[Extract Data] Pre-processed: workout_duration = {duration}")

    if "selected_days" in missing:
        days = _extract_selected_days(user_message)
        if days:
            extracted["selected_days"] = days
            logger.info(f"[Extract Data] Pre-processed: selected_days = {days}")

    if "equipment" in missing:
        equipment = _extract_equipment(user_message, collected_data.get("equipment", []))
        if equipment:
            extracted["equipment"] = equipment
            logger.info(f"[Extract Data] Pre-processed: equipment = {equipment}")

    if "goals" in missing:
        goals = _extract_goals(user_message, collected_data.get("goals", []))
        if goals:
            extracted["goals"] = goals
            logger.info(f"[Extract Data] Pre-processed: goals = {goals}")

    if "fitness_level" in missing:
        level = _extract_fitness_level(user_message)
        if level:
            extracted["fitness_level"] = level
            logger.info(f"[Extract Data] Pre-processed: fitness_level = {level}")

    # Personalization fields
    existing_training_exp = get_field_value(collected_data, "training_experience")
    if "training_experience" in missing or not existing_training_exp:
        exp = _extract_training_experience(user_message)
        if exp:
            extracted["training_experience"] = exp
            logger.info(f"[Extract Data] Pre-processed: training_experience = {exp}")

    existing_workout_env = get_field_value(collected_data, "workout_environment")
    if "workout_environment" in missing or not existing_workout_env:
        env = _extract_workout_environment(user_message)
        if env:
            extracted["workout_environment"] = env
            logger.info(f"[Extract Data] Pre-processed: workout_environment = {env}")

    existing_focus_areas = get_field_value(collected_data, "focus_areas")
    if "focus_areas" in missing or not existing_focus_areas:
        areas = _extract_focus_areas(user_message)
        if areas:
            extracted["focus_areas"] = areas
            logger.info(f"[Extract Data] Pre-processed: focus_areas = {areas}")

    existing_variety = get_field_value(collected_data, "workout_variety")
    if "workout_variety" in missing or not existing_variety:
        variety = _extract_workout_variety(user_message)
        if variety:
            extracted["workout_variety"] = variety
            logger.info(f"[Extract Data] Pre-processed: workout_variety = {variety}")

    existing_obstacle = get_field_value(collected_data, "biggest_obstacle")
    if "biggest_obstacle" in missing or not existing_obstacle:
        obstacle = _extract_biggest_obstacle(user_message)
        if obstacle:
            extracted["biggest_obstacle"] = obstacle
            logger.info(f"[Extract Data] Pre-processed: biggest_obstacle = {obstacle}")

    # Target weight extraction - needs current weight to calculate absolute value
    existing_target_weight = get_field_value(collected_data, "target_weight_kg")
    if "target_weight_kg" in missing or not existing_target_weight:
        current_weight = get_field_value(collected_data, "weightKg")
        target_data = _extract_target_weight(user_message, current_weight)
        if target_data:
            # Store both delta and calculated absolute weight if available
            if "target_weight_delta" in target_data:
                extracted["target_weight_delta"] = target_data["target_weight_delta"]
                logger.info(f"[Extract Data] Pre-processed: target_weight_delta = {target_data['target_weight_delta']}")
            if "target_weight_kg" in target_data:
                extracted["target_weight_kg"] = target_data["target_weight_kg"]
                logger.info(f"[Extract Data] Pre-processed: target_weight_kg = {target_data['target_weight_kg']}")

    # Merge extracted data
    if extracted:
        merged = collected_data.copy()

        pre_filled_fields = {
            "training_experience", "trainingExperience",
            "workout_environment", "workoutEnvironment",
            "fitness_level", "fitnessLevel",
            "days_per_week", "daysPerWeek",
            "workout_days", "workoutDays",
            "selected_days", "selectedDays",
            "motivations", "goals", "equipment",
        }

        for key, value in extracted.items():
            if key in pre_filled_fields:
                existing_value = get_field_value(merged, key)
                if not existing_value:
                    merged[key] = value
                else:
                    logger.info(f"[Extract Data] Preserving pre-filled {key}")
            else:
                merged[key] = value

        logger.info(f"[Extract Data] Pre-processed: {list(extracted.keys())}")

        # Calculate remaining missing
        remaining_missing = []
        for field in REQUIRED_FIELDS:
            value = get_field_value(merged, field)
            if value is None or value == "" or (isinstance(value, list) and len(value) == 0):
                remaining_missing.append(field)

        is_simple_message = len(user_message.strip().split()) <= 2 or user_message.strip().isdigit()

        if len(extracted) >= 3 or len(remaining_missing) == 0 or (len(extracted) >= 1 and is_simple_message):
            logger.info(f"[Extract Data] Pre-processing extracted {len(extracted)} fields, skipping AI")
            return {
                "collected_data": merged,
                "validation_errors": {},
            }
        else:
            collected_data = merged
            logger.info(f"[Extract Data] Pre-processing got {len(extracted)} fields, trying AI for remaining: {remaining_missing}")

    # Continue with AI extraction for complex messages
    extraction_prompt = DATA_EXTRACTION_SYSTEM_PROMPT.format(
        user_message=user_message,
        collected_data=json.dumps(collected_data, indent=2) if collected_data else "{}",
    )

    logger.info("=" * 60)
    logger.info("[Extract Data] EXTRACTION PROMPT:")
    logger.info("=" * 60)
    logger.info(extraction_prompt)
    logger.info("=" * 60)

    llm = get_langchain_llm(temperature=0.3, timeout=60)

    max_retries = 3
    response = None
    last_error = None

    for attempt in range(max_retries):
        try:
            logger.info(f"[Extract Data] Calling Gemini API (attempt {attempt + 1}/{max_retries})...")
            llm_start = time.time()
            response = await llm.ainvoke([
                SystemMessage(content="You are a data extraction expert. Extract structured fitness data from user messages."),
                HumanMessage(content=extraction_prompt)
            ])
            llm_elapsed = time.time() - llm_start
            logger.info(f"[Extract Data] Gemini API responded in {llm_elapsed:.2f}s")
            break
        except Exception as e:
            last_error = e
            logger.warning(f"[Extract Data] Attempt {attempt + 1} failed: {e}")
            if attempt < max_retries - 1:
                wait_time = 2 ** attempt
                logger.info(f"[Extract Data] Retrying in {wait_time}s...")
                import asyncio
                await asyncio.sleep(wait_time)

    if response is None:
        logger.error(f"[Extract Data] All {max_retries} attempts failed: {last_error}")
        return {
            "collected_data": collected_data,
            "validation_errors": {"_error": str(last_error)},
        }

    # Parse JSON from response
    try:
        content = response.content
        logger.info(f"[Extract Data] Raw response.content type: {type(content)}")

        if isinstance(content, dict):
            content = content.get("text", str(content))
        elif isinstance(content, list):
            parts = []
            for item in content:
                if isinstance(item, dict):
                    parts.append(item.get("text", str(item)))
                else:
                    parts.append(str(item))
            content = " ".join(parts) if parts else ""
        elif not isinstance(content, str):
            content = str(content) if content else ""

        content = content.strip()
        if content.startswith("```json"):
            content = content[7:]
        if content.startswith("```"):
            content = content[3:]
        if content.endswith("```"):
            content = content[:-3]
        content = content.strip()

        extracted_ai = json.loads(content)
        logger.info(f"[Extract Data] Extracted from user message: {extracted_ai}")

        # Merge with collected data
        merged = collected_data.copy()

        pre_filled_fields = {
            "training_experience", "trainingExperience",
            "workout_environment", "workoutEnvironment",
            "fitness_level", "fitnessLevel",
            "days_per_week", "daysPerWeek",
            "workout_days", "workoutDays",
            "selected_days", "selectedDays",
            "motivations",
        }

        for key, value in extracted_ai.items():
            if key in ["goals", "equipment", "active_injuries", "health_conditions"]:
                existing = merged.get(key, [])
                if isinstance(value, list):
                    merged[key] = list(set(existing + value))
                else:
                    merged[key] = existing + [value]
            elif key in pre_filled_fields:
                existing_value = get_field_value(merged, key)
                if not existing_value:
                    merged[key] = value
                else:
                    logger.info(f"[Extract Data] Preserving pre-filled {key}")
            else:
                merged[key] = value

        logger.info(f"[Extract Data] Merged data: {merged}")

        total_elapsed = time.time() - start_time
        logger.info("=" * 60)
        logger.info(f"[Extract Data] COMPLETED in {total_elapsed:.2f}s")
        logger.info(f"[Extract Data] Extracted fields: {list(extracted_ai.keys()) if extracted_ai else 'none'}")
        logger.info(f"[Extract Data] Total collected: {len(merged)} fields")
        logger.info("=" * 60)

        return {
            "collected_data": merged,
            "validation_errors": {},
        }

    except json.JSONDecodeError as e:
        logger.error(f"[Extract Data] JSON parse error: {e}")
        logger.error(f"[Extract Data] Response was: {response.content}")

        return {
            "collected_data": collected_data,
            "validation_errors": {},
        }
