"""
User data anonymization for AI prompts.

Strips PII (name, email, phone, etc.) and transforms age into brackets
before sending user profiles to Gemini or any LLM.
"""

# Fields to remove entirely before sending to AI
_STRIP_FIELDS = frozenset({
    "name", "email", "phone", "timezone", "user_id",
    "date_of_birth", "photo_url", "username",
})

# Fields safe to pass through as-is
_KEEP_FIELDS = frozenset({
    "fitness_level", "goals", "equipment", "injuries",
    "activity_level", "height_cm", "weight_kg",
    "workout_environment", "training_split",
})


def age_to_bracket(age: int) -> str:
    """Convert a numeric age to a privacy-safe bracket label."""
    if age < 18:
        return "teen"
    elif age < 30:
        return "young adult"
    elif age < 45:
        return "adult"
    elif age < 60:
        return "middle-aged"
    elif age < 70:
        return "active senior"
    else:
        return "senior"


def anonymize_user_data(profile: dict) -> dict:
    """Return a copy of *profile* with PII stripped and age bracketed.

    - Fields in _STRIP_FIELDS are removed entirely.
    - ``age`` is replaced by ``age_bracket`` (string label).
    - All other fields are kept as-is.
    """
    if not profile:
        return {}

    out: dict = {}
    for key, value in profile.items():
        if key in _STRIP_FIELDS:
            continue
        if key == "age":
            out["age_bracket"] = age_to_bracket(value) if isinstance(value, (int, float)) else "adult"
            continue
        out[key] = value

    return out
