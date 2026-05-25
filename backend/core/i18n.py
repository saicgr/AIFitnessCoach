"""
Backend notification template dictionary for Zealova.

Covers ~30 notification keys across 36 locales.

IMPORTANT — Translation status
────────────────────────────────────────────────────────────────────
Non-en translations TODO — currently English fallback for all locales.
Do NOT add LLM translation calls per project policy (no paid APIs for
translation work). Translations should be supplied by a professional
localization vendor or community contributors per locale sprint.
────────────────────────────────────────────────────────────────────

Template format: Python str.format()-compatible {var} placeholders.
All templates are safe to call via get_template(locale, key, **vars).
"""
from __future__ import annotations

import logging

logger = logging.getLogger(__name__)

# ── Template keys ─────────────────────────────────────────────────────────────
# Each key maps to a notification title or body. Variables are documented
# inline as {var_name}.

_EN_TEMPLATES: dict[str, str] = {
    # ── Morning recovery nudge (HRV-based AM nudge) ───────────────────────
    "morning_recovery_nudge_title": "Good morning, {name}!",
    "morning_recovery_nudge_body": (
        "Your HRV is {hrv_score} today — your body is {recovery_status}. "
        "Here's what {coach_name} recommends for today."
    ),

    # ── Streak at risk (afternoon before quiet hours) ──────────────────────
    "streak_at_risk_title": "Your {streak_count}-day streak ends tonight!",
    "streak_at_risk_body": (
        "{name}, you still have time. One quick session keeps the chain alive. "
        "You've got this!"
    ),

    # ── Weekly Wrapped (Sunday recap) ─────────────────────────────────────
    "weekly_wrapped_title": "Your week in review, {name}!",
    "weekly_wrapped_body": (
        "{workouts_done} workouts, {calories_burned} kcal burned. "
        "Check your weekly summary inside."
    ),

    # ── New PR celebration ─────────────────────────────────────────────────
    "new_pr_celebration_title": "New PR, {name}!",
    "new_pr_celebration_body": (
        "You just hit a personal record on {exercise_name}: {value} {unit}. "
        "That's what hard work looks like!"
    ),

    # ── Workout reminder ──────────────────────────────────────────────────
    "workout_reminder_title": "Time to train, {name}!",
    "workout_reminder_body": (
        "Your {workout_name} is ready and waiting. Let's make today count."
    ),

    # ── Meal log reminder ────────────────────────────────────────────────
    "meal_log_reminder_title": "Don't forget to log your {meal_name}, {name}!",
    "meal_log_reminder_body": (
        "Tracking your food is half the battle. Tap to log {meal_name} now."
    ),

    # ── Water reminder ───────────────────────────────────────────────────
    "water_reminder_title": "Hydration check!",
    "water_reminder_body": (
        "{name}, you're at {glasses_logged}/{glasses_goal} glasses today. "
        "Keep sipping!"
    ),

    # ── Weekly review email ───────────────────────────────────────────────
    "weekly_review_email_subject": "Your Zealova week — {date_range}",
    "weekly_review_email_greeting": "Hey {name},",
    "weekly_review_email_intro": (
        "Here's a snapshot of what you accomplished this week. "
        "{coach_name} is proud of your progress."
    ),
    "weekly_review_email_signoff": "Keep pushing, {coach_name} via Zealova",

    # ── Plateau break suggestion ──────────────────────────────────────────
    "plateau_break_suggestion_title": "Time to shake things up, {name}!",
    "plateau_break_suggestion_body": (
        "You've been consistent — now {coach_name} has a new challenge to break "
        "through your plateau. Tap to see it."
    ),

    # ── Challenge complete ────────────────────────────────────────────────
    "challenge_complete_title": "Challenge complete!",
    "challenge_complete_body": (
        "You finished the {challenge_name} challenge, {name}! "
        "{coach_name} is cheering for you."
    ),

    # ── Morning motivation ────────────────────────────────────────────────
    "morning_motivation_title": "Rise and grind, {name}!",
    "morning_motivation_body": (
        "{coach_name} has your {workout_name} loaded and ready. "
        "Today is another step toward your goal."
    ),

    # ── Evening reflection ───────────────────────────────────────────────
    "evening_reflection_title": "How was your day, {name}?",
    "evening_reflection_body": (
        "Take a moment to log your food and activity. "
        "Small consistent logs lead to big insights."
    ),

    # ── AI coach insight ─────────────────────────────────────────────────
    "ai_coach_insight_title": "{coach_name} has something for you!",
    "ai_coach_insight_body": (
        "Based on your recent performance, {coach_name} has a personalized tip. "
        "Tap to read it."
    ),

    # ── Rest day tip ─────────────────────────────────────────────────────
    "rest_day_tip_title": "Rest day — let your muscles grow, {name}!",
    "rest_day_tip_body": (
        "Active recovery, good sleep, and solid nutrition make your next "
        "session even better."
    ),

    # ── Post-workout nutrition ────────────────────────────────────────────
    "post_workout_nutrition_title": "Refuel time, {name}!",
    "post_workout_nutrition_body": (
        "Log your post-workout meal to hit your {protein_goal}g protein goal today."
    ),

    # ── Habit streak reward ───────────────────────────────────────────────
    "habit_streak_reward_title": "{streak_count}-day streak!",
    "habit_streak_reward_body": (
        "{name}, you've logged {habit_name} {streak_count} days in a row. "
        "Keep the momentum going!"
    ),

    # ── Progress comparison ────────────────────────────────────────────────
    "progress_comparison_title": "You're ahead of last {period}, {name}!",
    "progress_comparison_body": (
        "{workouts_done} workouts vs {prev_workouts_done} last {period}. "
        "That's real progress."
    ),

    # ── Inactivity comeback ────────────────────────────────────────────────
    "inactivity_comeback_title": "We miss you, {name}!",
    "inactivity_comeback_body": (
        "It's been {days_inactive} days. Your workout plan is still here, "
        "ready when you are. No pressure."
    ),

    # ── Trial ending reminder ──────────────────────────────────────────────
    "trial_reminder_title": "Your trial ends in {days_left} days, {name}!",
    "trial_reminder_body": (
        "Don't lose access to your AI workouts and coaching. "
        "Subscribe now to keep your streak and progress."
    ),

    # ── Weekly check-in ────────────────────────────────────────────────────
    "weekly_checkin_title": "Weekly check-in time!",
    "weekly_checkin_body": (
        "{name}, how are you feeling this week? Log a quick note so "
        "{coach_name} can adjust your plan."
    ),

    # ── Merch milestone ────────────────────────────────────────────────────
    "merch_proximity_title": "You're almost at {xp_threshold} XP, {name}!",
    "merch_proximity_body": (
        "{xp_gap} more XP unlocks exclusive Zealova merch. Keep training!"
    ),
}

# ── Full template table: locale → {key: template_string} ─────────────────────
# Non-English locales currently fall back to English. See module docstring.
# To add a locale's translations, add a sub-dict here with only the keys that
# have been professionally translated; get_template() will fill the rest from
# the English fallback automatically.

_LOCALE_OVERRIDES: dict[str, dict[str, str]] = {
    # Example structure (currently empty — waiting for translation sprint):
    # "es": {
    #     "morning_recovery_nudge_title": "¡Buenos días, {name}!",
    #     ...
    # },
}

# Build the full TEMPLATES dict: each locale gets English base + any overrides.
TEMPLATES: dict[str, dict[str, str]] = {}
_ALL_LOCALES = (
    "en", "ar", "bn", "cs", "de", "es", "fi", "fr", "ha", "hi",
    "id", "it", "ja", "jv", "kn", "ko", "ml", "mr", "ms", "ne",
    "nl", "or", "pa", "pl", "pt", "ru", "sv", "sw", "ta", "te",
    "th", "tl", "tr", "ur", "vi", "zh",
)
for _loc in _ALL_LOCALES:
    _merged = dict(_EN_TEMPLATES)  # copy English base
    _merged.update(_LOCALE_OVERRIDES.get(_loc, {}))  # apply any overrides
    TEMPLATES[_loc] = _merged


# ── Public helper ────────────────────────────────────────────────────────────

def get_template(locale: str, key: str, **fmt) -> str:
    """Retrieve and format a notification template.

    Lookup order:
        1. TEMPLATES[locale][key]   — locale-specific (once translations land)
        2. TEMPLATES["en"][key]     — English fallback (current default for all)
        3. key itself               — last-resort so callers never get an error

    Applies .format(**fmt) for variable substitution. Missing variables leave
    the placeholder literal rather than raising KeyError.

    Args:
        locale: ISO 639-1 code, e.g. "hi", "fr".
        key:    Template key, e.g. "streak_at_risk_title".
        **fmt:  Substitution variables, e.g. name="Alice", streak_count=7.

    Returns:
        Formatted string, never raises.
    """
    locale_map = TEMPLATES.get(locale) or TEMPLATES.get("en", {})
    template = locale_map.get(key)

    if template is None:
        # Try English fallback explicitly
        template = TEMPLATES.get("en", {}).get(key)

    if template is None:
        logger.warning(f"[i18n] Unknown template key '{key}' — returning key as-is")
        return key

    if not fmt:
        return template

    try:
        return template.format(**fmt)
    except (KeyError, IndexError) as exc:
        # Partial substitution failure: return the raw template rather than
        # crashing the notification pipeline.
        logger.debug(f"[i18n] Template '{key}' format failed ({exc}), returning raw template")
        return template
