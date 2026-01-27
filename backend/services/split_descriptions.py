"""
Training Split Descriptions - Research-Backed Scientific Data

Based on research from Built With Science, Hevy, StrengthLog, Legion Athletics.
Hypertrophy scores based on: frequency, volume, recovery, proven effectiveness.
"""

# =============================================================================
# COMPREHENSIVE SPLIT DESCRIPTIONS (Research-Backed)
# =============================================================================

SPLIT_DESCRIPTIONS = {
    # === BEGINNER FRIENDLY ===
    'full_body': {
        'name': 'Full Body',
        'days_per_week': 3,
        'schedule': 'Mon: Full Body A, Wed: Full Body B, Fri: Full Body C',
        'hypertrophy_score': 7.5,
        'rationale': 'Train every muscle 3x/week. Research shows 50% better strength gains vs 1x/week. Perfect for beginners.',
        'benefits': ['Maximum frequency', 'Learn compound lifts', 'Fast progress for beginners'],
    },
    'full_body_minimal': {
        'name': 'Full Body (2-Day)',
        'days_per_week': 2,
        'schedule': 'Mon: Full Body A, Thu: Full Body B',
        'hypertrophy_score': 6.0,
        'rationale': 'For busy schedules. Hit all muscles twice per week with efficient compound movements.',
        'benefits': ['Time efficient', 'Maintains muscle', 'Good for busy people'],
    },

    # === INTERMEDIATE ===
    'upper_lower': {
        'name': 'Upper/Lower',
        'days_per_week': 4,
        'schedule': 'Mon: Upper, Tue: Lower, Thu: Upper, Fri: Lower',
        'hypertrophy_score': 8.4,
        'rationale': '85% of max gains with 30% less gym time. Each muscle trained 2x/week with optimal recovery.',
        'benefits': ['Great recovery', 'High frequency', 'Balanced growth'],
    },
    'push_pull_legs': {
        'name': 'Push/Pull/Legs',
        'days_per_week': 3,
        'schedule': 'Mon: Push (chest/shoulders/triceps), Wed: Pull (back/biceps), Fri: Legs',
        'hypertrophy_score': 7.8,
        'rationale': 'Most popular split. Groups muscles by movement pattern for efficient training.',
        'benefits': ['Simple structure', 'Prevents overlap', 'Flexible scheduling'],
    },
    'phul': {
        'name': 'PHUL (Power Hypertrophy)',
        'days_per_week': 4,
        'schedule': 'Mon: Upper Power, Tue: Lower Power, Thu: Upper Hypertrophy, Fri: Lower Hypertrophy',
        'hypertrophy_score': 8.6,
        'rationale': '2 power days + 2 hypertrophy days. Build strength AND size with varied rep ranges.',
        'benefits': ['Strength + size', 'Varied rep ranges', 'Powerbuilding focus'],
    },
    'upper_lower_full': {
        'name': 'Upper/Lower/Full Body',
        'days_per_week': 3,
        'schedule': 'Mon: Upper, Wed: Lower, Fri: Full Body',
        'hypertrophy_score': 7.9,
        'rationale': 'Hybrid approach combining best of both worlds for balanced development.',
        'benefits': ['Flexibility', '2x frequency', 'Balanced volume'],
    },

    # === INTERMEDIATE-ADVANCED ===
    'pplul': {
        'name': 'PPLUL (5-Day Hybrid)',
        'days_per_week': 5,
        'schedule': 'Mon: Push, Tue: Pull, Wed: Legs, Thu: Upper, Fri: Lower',
        'hypertrophy_score': 9.0,
        'rationale': 'Combines PPL + Upper/Lower. More volume than 4-day without 6-day commitment. Optimal for gains.',
        'benefits': ['High volume', '2x frequency per muscle', 'Best hybrid approach'],
    },
    'ppl_6day': {
        'name': 'Push/Pull/Legs (6-Day)',
        'days_per_week': 6,
        'schedule': 'Mon: Push, Tue: Pull, Wed: Legs, Thu: Push, Fri: Pull, Sat: Legs',
        'hypertrophy_score': 9.7,
        'rationale': 'Maximum hypertrophy. Each muscle 2x/week with high volume. For serious lifters.',
        'benefits': ['Maximum volume', 'Highest hypertrophy score', 'Serious gains'],
    },

    # === ADVANCED ===
    'arnold_split': {
        'name': 'Arnold Split',
        'days_per_week': 6,
        'schedule': 'Mon: Chest+Back, Tue: Shoulders+Arms, Wed: Legs, repeat Thu-Sat',
        'hypertrophy_score': 8.8,
        'rationale': "Arnold Schwarzenegger's legendary split with antagonist supersets. Fresh shoulders and arms.",
        'benefits': ['Antagonist supersets', 'Fresh shoulders/arms', 'Classic bodybuilding'],
    },
    'body_part': {
        'name': 'Bro Split',
        'days_per_week': 5,
        'schedule': 'Mon: Chest, Tue: Back, Wed: Shoulders, Thu: Arms, Fri: Legs',
        'hypertrophy_score': 6.5,
        'rationale': 'One muscle per day with maximum volume per session. Classic bodybuilding approach.',
        'benefits': ['Maximum pump', 'Simple focus', 'Short sessions'],
    },

    # === SPECIALTY ===
    'lower_focused': {
        'name': 'Lower Focused + Upper',
        'days_per_week': 3,
        'schedule': 'Mon: Lower, Wed: Upper, Fri: Lower',
        'hypertrophy_score': 7.5,
        'rationale': 'Extra leg volume for those wanting bigger legs. 2 leg days + 1 upper day.',
        'benefits': ['Leg emphasis', 'Glute development', 'Athletic base'],
    },
    'chest_back_focus': {
        'name': 'Chest & Back Focus',
        'days_per_week': 4,
        'schedule': 'Mon: Chest+Triceps, Tue: Back+Biceps, Thu: Shoulders+Legs, Fri: Chest+Back',
        'hypertrophy_score': 7.8,
        'rationale': 'Upper body emphasis with extra chest and back volume. Legs maintained.',
        'benefits': ['V-taper focus', 'Upper body priority', 'Aesthetic goals'],
    },

    # === AI MODES ===
    'ai_adaptive': {
        'name': 'AI Adaptive',
        'days_per_week': 0,  # Flexible
        'schedule': 'AI determines optimal training days based on user schedule and recovery',
        'hypertrophy_score': 8.5,
        'rationale': 'AI learns your progress and auto-adjusts difficulty. Gets harder as you get stronger.',
        'benefits': ['Personalized progression', 'Prevents plateaus', 'Learns your limits'],
    },
    'dont_know': {
        'name': 'Let AI Decide',
        'days_per_week': 0,
        'schedule': 'AI picks optimal split based on your schedule and goals',
        'hypertrophy_score': 8.0,
        'rationale': 'Not sure which split to use? AI will analyze your schedule and recommend the best fit.',
        'benefits': ['No decision fatigue', 'Optimized for your schedule', 'AI-guided'],
    },

    # === SPECIAL PROGRAMS ===
    'hyrox': {
        'name': 'HYROX',
        'days_per_week': 4,
        'schedule': 'Hybrid running + functional fitness training',
        'hypertrophy_score': 6.0,
        'rationale': 'Competition-focused training for HYROX events. Balance of cardio and strength.',
        'benefits': ['Competition prep', 'Functional fitness', 'Cardio + strength'],
    },
}


def get_split_context(training_split: str) -> str:
    """
    Get rich context for a training split to include in AI prompts.

    Args:
        training_split: The split identifier (e.g., 'pplul', 'arnold_split')

    Returns:
        Formatted string with split details for AI context
    """
    split_info = SPLIT_DESCRIPTIONS.get(training_split, {})

    if split_info:
        lines = [
            f"Training Split: {split_info['name']}",
            f"  Schedule: {split_info['schedule']}",
            f"  Days per week: {split_info['days_per_week'] if split_info['days_per_week'] > 0 else 'Flexible'}",
            f"  Hypertrophy Score: {split_info['hypertrophy_score']}/10",
            f"  Rationale: {split_info['rationale']}",
            f"  Benefits: {', '.join(split_info['benefits'])}",
        ]
        return "\n".join(lines)
    else:
        # Fallback for unknown splits
        return f"Training Split: {training_split}"


def get_split_required_days(training_split: str):
    """
    Get the number of days required for a training split.

    Args:
        training_split: The split identifier (e.g., 'pplul', 'arnold_split')

    Returns:
        int: Number of days required, or None if flexible/unknown
    """
    split_info = SPLIT_DESCRIPTIONS.get(training_split, {})
    days = split_info.get('days_per_week', 0)
    return days if days > 0 else None


def get_split_default_days(training_split: str):
    """
    Get the default workout day indices for a split.

    Args:
        training_split: The split identifier

    Returns:
        List of day indices (0=Mon, 6=Sun)
    """
    days_per_week = get_split_required_days(training_split)
    if not days_per_week:
        return []

    # Map common day counts to sensible default schedules
    default_schedules = {
        2: [0, 3],              # Mon, Thu
        3: [0, 2, 4],           # Mon, Wed, Fri
        4: [0, 1, 3, 4],        # Mon, Tue, Thu, Fri
        5: [0, 1, 2, 3, 4],     # Mon-Fri
        6: [0, 1, 2, 3, 4, 5],  # Mon-Sat
    }
    return default_schedules.get(days_per_week, [])


def get_compatible_split_for_days(day_count: int) -> str:
    """
    Suggest a compatible training split for a given number of workout days.

    Args:
        day_count: Number of workout days per week

    Returns:
        Suggested training split identifier
    """
    suggestions = {
        2: 'full_body_minimal',
        3: 'full_body',
        4: 'upper_lower',
        5: 'pplul',
        6: 'ppl_6day',
    }
    return suggestions.get(day_count, 'dont_know')
