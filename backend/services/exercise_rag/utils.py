"""
Utility functions for exercise name cleaning and equipment inference.
"""

import re


def clean_exercise_name_for_display(exercise_name: str) -> str:
    """
    Clean exercise name for display by removing gender suffixes, version markers, video metadata, and numeric IDs.

    Examples:
    - "Band Hammer Grip Incline Bench Two Arm Row_female" -> "Band Hammer Grip Incline Bench Two Arm Row"
    - "Air Bike_Female" -> "Air Bike"
    - "Push-up (version 2)" -> "Push-up"
    - "Barbell Deadlift 360" -> "Barbell Deadlift"
    - "Barbell Deadlift 360 Degrees" -> "Barbell Deadlift"
    - "Dumbbell Scott Press (360 degrees)" -> "Dumbbell Scott Press"
    - "Gada 360-Degree Swing" -> "Gada 360-Degree Swing" (preserved - degree is part of name)

    Args:
        exercise_name: The raw exercise name

    Returns:
        Cleaned exercise name for display
    """
    if not exercise_name:
        return "Unknown Exercise"

    # Remove _female or _male suffix (case insensitive)
    cleaned = re.sub(r'[_\s](female|male)$', '', exercise_name, flags=re.IGNORECASE)

    # Remove (version X) suffix
    cleaned = re.sub(r'\s*\(version\s*\d+\)\s*$', '', cleaned, flags=re.IGNORECASE)

    # Remove "360 degrees" video metadata (with or without parentheses)
    cleaned = re.sub(r'\s*\(?\s*360\s*degrees?\s*\)?\s*$', '', cleaned, flags=re.IGNORECASE)

    # Remove trailing numeric IDs (e.g., "Barbell Deadlift 360" -> "Barbell Deadlift")
    # But preserve numbers that are part of the exercise name (e.g., "360-Degree Swing")
    # Only remove standalone trailing numbers not followed by text
    cleaned = re.sub(r'\s+\d+$', '', cleaned)

    # Remove trailing underscores or spaces
    cleaned = cleaned.strip().rstrip('_')

    return cleaned


def infer_equipment_from_name(exercise_name: str) -> str:
    """
    Infer equipment type from exercise name when equipment data is missing.

    Examples:
    - "cable machine low to high" -> "Cable Machine"
    - "barbell bench press" -> "Barbell"
    - "dumbbell curl" -> "Dumbbells"

    Args:
        exercise_name: The exercise name

    Returns:
        Inferred equipment type
    """
    if not exercise_name:
        return "Bodyweight"

    name_lower = exercise_name.lower()

    # Equipment inference rules (order matters - more specific first)
    equipment_patterns = [
        # Specific equipment first (longer/more specific patterns)
        (["cable machine"], "Cable Machine"),
        (["cable "], "Cable Machine"),
        (["smith machine"], "Smith Machine"),
        (["ez bar", "ez-bar", "curl bar"], "EZ Bar"),
        (["trap bar", "hex bar"], "Trap Bar"),
        (["lat pulldown", "lat pull down"], "Lat Pulldown Machine"),
        (["leg press"], "Leg Press Machine"),
        (["leg extension"], "Leg Extension Machine"),
        (["leg curl"], "Leg Curl Machine"),
        (["hack squat"], "Hack Squat Machine"),
        (["pec deck", "pec fly machine"], "Pec Fly Machine"),
        (["chest press machine"], "Chest Press Machine"),
        (["shoulder press machine"], "Shoulder Press Machine"),
        (["assisted pull"], "Assisted Pull-Up Machine"),
        (["hyperextension"], "Hyperextension Bench"),
        # Free weights
        (["barbell", "bar bell"], "Barbell"),
        (["dumbbell", "dumb bell", "db "], "Dumbbells"),
        (["kettlebell", "kettle bell", "kb "], "Kettlebell"),
        (["weight plate", "plate front raise"], "Weight Plate"),
        # Accessories
        (["resistance band", "band "], "Resistance Band"),
        (["bosu ball", "bosu"], "Bosu Ball"),
        (["exercise ball"], "Exercise Ball"),
        (["stability ball", "swiss ball"], "Exercise Ball"),
        (["slam ball", "ball slam"], "Slam Ball"),
        (["medicine ball", "med ball"], "Medicine Ball"),
        (["foam roller"], "Foam Roller"),
        (["ab wheel", "ab roller"], "Ab Wheel"),
        (["jump rope", "skipping rope"], "Jump Rope"),
        # Bars and racks
        (["pull-up bar", "pullup bar", "chin-up bar", "chinup bar", "pull up bar"], "Pull-Up Bar"),
        (["hanging "], "Pull-Up Bar"),
        (["dip station", "dip stand", "parallel bar"], "Dip Station"),
        (["landmine"], "Landmine"),
        (["bench ", " bench"], "Bench"),
        # Specialty
        (["suspension trainer", "trx", "suspension"], "Suspension Trainer"),
        (["battle rope"], "Battle Ropes"),
        (["gymnastic ring", "ring dip"], "Gymnastic Rings"),
        (["agility ladder"], "Agility Ladder"),
        (["plyo box", "box jump", "step box"], "Plyo Box"),
        # Unconventional
        (["sandbag"], "Sandbag"),
        # Cardio
        (["treadmill"], "Treadmill"),
        (["rebounder", "mini trampoline"], "Rebounder"),
        (["stepmill", "stair climber"], "Stair Climber"),
        (["rowing machine", "rower"], "Rowing Machine"),
        (["assault bike", "air bike", "airbike"], "Assault Bike"),
        (["stationary bike", "exercise bike"], "Stationary Bike"),
        (["elliptical"], "Elliptical"),
        # Generic machine (LAST - catches remaining machine exercises)
        (["machine"], "Machine"),
    ]

    for patterns, equipment in equipment_patterns:
        for pattern in patterns:
            if pattern in name_lower:
                return equipment

    # If no equipment matched, default to Bodyweight
    return "Bodyweight"
