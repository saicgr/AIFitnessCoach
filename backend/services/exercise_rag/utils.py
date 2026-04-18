"""
Utility functions for exercise name cleaning and equipment inference.
"""

import re


# Match a trailing `(N)` suffix on exercise names — e.g. `Burpee(1)`,
# `Bird Dog (3)`. These come from duplicate library imports.
_DEDUP_SUFFIX_RE = re.compile(r'\s*\(\s*\d+\s*\)\s*$')


def strip_dedup_suffix(name: str) -> str:
    """Remove a trailing ``(N)`` suffix used by duplicate library imports.

    ``Burpee(1)`` -> ``Burpee``, ``Bird Dog (3)`` -> ``Bird Dog``.
    Idempotent. Safe on empty / None input.
    """
    if not name:
        return name or ""
    return _DEDUP_SUFFIX_RE.sub('', name).strip()


def dedup_key(name: str) -> str:
    """Canonical key for dedup: strip numeric suffix, lowercase, trim.

    Ensures ``Burpee`` and ``Burpee(1)`` collapse to the same key so the
    downstream generator never sends both to the client.
    """
    if not name:
        return ""
    return strip_dedup_suffix(name).lower().strip()


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

    # Gymnastic rings / suspension trainer — checked BEFORE pull-up-bar so that
    # "Ring Pull-Up" and "TRX Row" are classified by the support apparatus
    # rather than by the movement pattern.
    if any(token in name_lower for token in ("gymnastic ring", "ring muscle-up", "ring pull", "ring dip", "rings ", "ring pull-up", "ring chin")):
        return "Gymnastic Rings"
    if any(token in name_lower for token in ("trx", "suspension trainer", "suspension strap")):
        return "Suspension Trainer"

    # Hanging / bar-supported movements take the next-highest priority.
    # Some library rows are mis-tagged "bodyweight" even though the movement
    # physically requires a pull-up bar. Catch them by name.
    if "assisted pull" not in name_lower and "assisted chin" not in name_lower:
        pullup_bar_tokens = (
            "pull-up", "pull up", "pullup",
            "chin-up", "chin up", "chinup",
            "muscle-up", "muscle up", "muscleup",
            "hanging ",
            "toes-to-bar", "toes to bar",
            "knees-to-elbow", "knees to elbow",
            "knee-to-elbow", "knee to elbow",
            "front lever", "back lever", "tuck lever",
            "skin the cat",
            "bar hang",
            "dead hang",
        )
        for token in pullup_bar_tokens:
            if token in name_lower:
                return "Pull-Up Bar"

    # Dip requires a dip station unless it's a bench dip or dumbbell dip.
    if ("dip" in name_lower
            and "bench dip" not in name_lower
            and "chair dip" not in name_lower
            and "dumbbell dip" not in name_lower
            and "dumbell dip" not in name_lower):
        # Avoid false positives like "dipped" or "dipping"
        if re.search(r"\bdip(s|ping|ped)?\b", name_lower):
            return "Dip Station"

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


# Known snake_case equipment identifiers → proper display names
_EQUIPMENT_DISPLAY_MAP = {
    "full_gym": "Full Gym",
    "cable_machine": "Cable Machine",
    "resistance_bands": "Resistance Bands",
    "pull_up_bar": "Pull-Up Bar",
    "no_equipment": "Bodyweight",
    "body_weight": "Bodyweight",
    "smith_machine": "Smith Machine",
    "leg_press": "Leg Press Machine",
    "lat_pulldown": "Lat Pulldown Machine",
    "leg_extension": "Leg Extension Machine",
    "leg_curl": "Leg Curl Machine",
    "hack_squat": "Hack Squat Machine",
    "ez_bar": "EZ Bar",
    "trap_bar": "Trap Bar",
    "pec_deck": "Pec Fly Machine",
    "medicine_ball": "Medicine Ball",
    "exercise_ball": "Exercise Ball",
}


def normalize_equipment_value(raw_equipment: str, exercise_name: str = "") -> str:
    """Normalize equipment value for display.

    Converts snake_case identifiers (e.g. 'leg_press') that Gemini echoes
    from the user's equipment profile into proper display names
    (e.g. 'Leg Press Machine').
    """
    if not raw_equipment:
        return infer_equipment_from_name(exercise_name) if exercise_name else "Bodyweight"

    lower = raw_equipment.strip().lower()

    if lower in ("bodyweight", "body weight", "body_weight", "none", "no_equipment", ""):
        return "Bodyweight"

    if lower in _EQUIPMENT_DISPLAY_MAP:
        return _EQUIPMENT_DISPLAY_MAP[lower]

    if "_" in raw_equipment:
        if exercise_name:
            inferred = infer_equipment_from_name(exercise_name)
            if inferred != "Bodyweight":
                return inferred
        return raw_equipment.replace("_", " ").title()

    return raw_equipment
