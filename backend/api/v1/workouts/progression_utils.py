"""
Progression philosophy, rep preferences, and workout pattern utilities.

Handles:
- Training focus rep ranges
- Exercise progression chains (leverage-based)
- User rep/sets preferences
- Exercise mastery detection and progression suggestions
- Building Gemini prompt sections for progression
- Historical workout pattern analysis
"""
import json
from datetime import datetime, timedelta
from typing import List, Dict, Any

from core.supabase_db import get_supabase_db
from core.logger import get_logger

logger = get_logger(__name__)


# Default rep ranges by training focus
TRAINING_FOCUS_REP_RANGES = {
    "strength": {"min_reps": 4, "max_reps": 6, "description": "heavy loads, lower reps"},
    "hypertrophy": {"min_reps": 8, "max_reps": 12, "description": "moderate loads, muscle building"},
    "endurance": {"min_reps": 12, "max_reps": 15, "description": "lighter loads, higher reps"},
    "power": {"min_reps": 1, "max_reps": 5, "description": "explosive movements, max effort"},
    "balanced": {"min_reps": 8, "max_reps": 12, "description": "balanced approach"},
}

# Exercise progression chains - from easier to harder variants
EXERCISE_PROGRESSION_CHAINS = {
    # Push progressions
    "push-up": ["Wall Push-ups", "Incline Push-ups", "Knee Push-ups", "Push-ups", "Diamond Push-ups", "Decline Push-ups", "Archer Push-ups", "One-Arm Push-ups"],
    "dip": ["Bench Dips", "Assisted Dips", "Dips", "Weighted Dips", "Ring Dips"],
    "handstand push-up": ["Pike Push-ups", "Elevated Pike Push-ups", "Wall Handstand Hold", "Wall Handstand Push-ups", "Deficit Handstand Push-ups", "Freestanding Handstand Push-ups"],
    # Pull progressions
    "pull-up": ["Dead Hang", "Scapular Pull-ups", "Negative Pull-ups", "Assisted Pull-ups", "Pull-ups", "Chest-to-Bar Pull-ups", "Archer Pull-ups", "One-Arm Pull-ups"],
    "chin-up": ["Dead Hang", "Negative Chin-ups", "Assisted Chin-ups", "Chin-ups", "Weighted Chin-ups", "One-Arm Chin-ups"],
    "row": ["Inverted Rows (High Bar)", "Inverted Rows (Low Bar)", "One-Arm Inverted Rows", "Archer Rows"],
    "muscle-up": ["Pull-ups", "High Pull-ups", "Chest-to-Bar Pull-ups", "Kipping Muscle-up", "Strict Muscle-up", "Ring Muscle-up"],
    # Leg progressions
    "squat": ["Assisted Squats", "Box Squats", "Bodyweight Squats", "Goblet Squats", "Bulgarian Split Squats", "Pistol Squats", "Shrimp Squats"],
    "lunge": ["Stationary Lunges", "Walking Lunges", "Reverse Lunges", "Deficit Lunges", "Jumping Lunges", "Single-Leg Deadlifts"],
    "hip thrust": ["Glute Bridges", "Single-Leg Glute Bridges", "Hip Thrusts", "Single-Leg Hip Thrusts", "Barbell Hip Thrusts"],
    "calf raise": ["Seated Calf Raises", "Standing Calf Raises", "Single-Leg Calf Raises", "Deficit Calf Raises"],
    # Core progressions
    "plank": ["Forearm Plank", "High Plank", "Side Plank", "Plank with Leg Lift", "Plank with Arm Reach", "Ring Plank"],
    "leg raise": ["Lying Leg Raises", "Hanging Knee Raises", "Hanging Leg Raises", "Toes-to-Bar", "L-Sit"],
    "crunch": ["Crunches", "Bicycle Crunches", "Reverse Crunches", "V-ups", "Dragon Flags"],
}


async def get_user_rep_preferences(user_id: str) -> dict:
    """Get user's rep range and sets preferences for workout generation."""
    try:
        db = get_supabase_db()

        result = db.client.table("users").select(
            "preferences"
        ).eq("id", user_id).execute()

        if not result.data:
            return {
                "training_focus": "balanced",
                "min_reps": 8,
                "max_reps": 12,
                "avoid_high_reps": False,
                "max_sets_per_exercise": 4,
                "min_sets_per_exercise": 2,
                "enforce_rep_ceiling": False,
                "description": "balanced approach (8-12 reps, 2-4 sets)"
            }

        preferences = result.data[0].get("preferences") or {}
        if isinstance(preferences, str):
            try:
                preferences = json.loads(preferences)
            except json.JSONDecodeError:
                preferences = {}

        training_focus = preferences.get("training_focus", "balanced")
        if training_focus not in TRAINING_FOCUS_REP_RANGES:
            training_focus = "balanced"

        focus_defaults = TRAINING_FOCUS_REP_RANGES[training_focus]

        min_reps = preferences.get("min_reps", focus_defaults["min_reps"])
        max_reps = preferences.get("max_reps", focus_defaults["max_reps"])
        avoid_high_reps = preferences.get("avoid_high_reps", False)

        max_sets_per_exercise = preferences.get("max_sets_per_exercise", 4)
        min_sets_per_exercise = preferences.get("min_sets_per_exercise", 2)
        enforce_rep_ceiling = preferences.get("enforce_rep_ceiling", False)

        if avoid_high_reps:
            max_reps = min(max_reps, 12)

        if min_reps < 1:
            min_reps = 1
        if max_reps > 30:
            max_reps = 30
        if min_reps > max_reps:
            min_reps = max_reps - 2 if max_reps > 2 else 1

        if max_sets_per_exercise < 1:
            max_sets_per_exercise = 1
        if max_sets_per_exercise > 10:
            max_sets_per_exercise = 10
        if min_sets_per_exercise < 1:
            min_sets_per_exercise = 1
        if min_sets_per_exercise > max_sets_per_exercise:
            min_sets_per_exercise = max_sets_per_exercise

        description = f"{training_focus} ({min_reps}-{max_reps} reps, {min_sets_per_exercise}-{max_sets_per_exercise} sets)"
        logger.debug(f"User {user_id} rep preferences: {description}")

        return {
            "training_focus": training_focus,
            "min_reps": min_reps,
            "max_reps": max_reps,
            "avoid_high_reps": avoid_high_reps,
            "max_sets_per_exercise": max_sets_per_exercise,
            "min_sets_per_exercise": min_sets_per_exercise,
            "enforce_rep_ceiling": enforce_rep_ceiling,
            "description": description,
        }

    except Exception as e:
        logger.debug(f"Could not get rep preferences: {e}")
        return {
            "training_focus": "balanced",
            "min_reps": 8,
            "max_reps": 12,
            "avoid_high_reps": False,
            "max_sets_per_exercise": 4,
            "min_sets_per_exercise": 2,
            "enforce_rep_ceiling": False,
            "description": "balanced approach (8-12 reps, 2-4 sets)"
        }


async def get_user_progression_context(user_id: str, days: int = 30) -> dict:
    """Get user's exercise mastery data for leverage-based progressions."""
    try:
        db = get_supabase_db()
        cutoff_date = (datetime.now() - timedelta(days=days)).isoformat()

        mastered_exercises = []
        progression_suggestions = {}
        exercises_marked_easy = []

        # 1. Get exercises from feedback where user said "too_easy"
        try:
            feedback_result = db.client.table("exercise_feedback").select(
                "exercise_name, difficulty_felt, reps_completed"
            ).eq("user_id", user_id).gte("created_at", cutoff_date).eq(
                "difficulty_felt", "too_easy"
            ).execute()

            if feedback_result.data:
                for fb in feedback_result.data:
                    ex_name = fb.get("exercise_name", "")
                    if ex_name and ex_name not in exercises_marked_easy:
                        exercises_marked_easy.append(ex_name)
                        reps = fb.get("reps_completed", 0)
                        if reps >= 12:
                            mastered_exercises.append({
                                "name": ex_name,
                                "reason": f"User marked as too easy ({reps} reps)",
                                "source": "feedback"
                            })
        except Exception as e:
            logger.debug(f"Could not fetch exercise feedback: {e}")

        # 2. Get exercises where user consistently completes 12+ reps
        try:
            workout_result = db.client.table("completed_exercise_sets").select(
                "exercise_name, reps_completed, sets_completed"
            ).eq("user_id", user_id).gte("completed_at", cutoff_date).execute()

            exercise_performance = {}
            if workout_result.data:
                for row in workout_result.data:
                    ex_name = row.get("exercise_name", "")
                    reps = row.get("reps_completed", 0)
                    if not ex_name or reps <= 0:
                        continue

                    if ex_name not in exercise_performance:
                        exercise_performance[ex_name] = {"total_sets": 0, "high_rep_sets": 0}

                    exercise_performance[ex_name]["total_sets"] += 1
                    if reps >= 12:
                        exercise_performance[ex_name]["high_rep_sets"] += 1

            for ex_name, perf in exercise_performance.items():
                if perf["total_sets"] >= 3:
                    high_rep_ratio = perf["high_rep_sets"] / perf["total_sets"]
                    if high_rep_ratio >= 0.7:
                        if ex_name not in [m["name"] for m in mastered_exercises]:
                            mastered_exercises.append({
                                "name": ex_name,
                                "reason": f"Consistently completing 12+ reps ({int(high_rep_ratio*100)}% of sets)",
                                "source": "performance"
                            })
        except Exception as e:
            logger.debug(f"Could not analyze workout performance: {e}")

        # 3. Find progression suggestions for mastered exercises
        for mastered in mastered_exercises:
            ex_name = mastered["name"].lower()

            for base_exercise, chain in EXERCISE_PROGRESSION_CHAINS.items():
                chain_lower = [c.lower() for c in chain]

                for i, chain_ex in enumerate(chain_lower):
                    if ex_name == chain_ex or ex_name in chain_ex or chain_ex in ex_name:
                        if i < len(chain) - 1:
                            progression_suggestions[mastered["name"]] = {
                                "current": chain[i],
                                "suggested": chain[i + 1],
                                "chain_position": f"{i + 1}/{len(chain)}"
                            }
                        else:
                            progression_suggestions[mastered["name"]] = {
                                "current": chain[i],
                                "suggested": None,
                                "chain_position": f"{i + 1}/{len(chain)} (max level)"
                            }
                        break

        # 4. Build context string for Gemini prompt
        mastery_context_parts = []
        if mastered_exercises:
            for mastered in mastered_exercises[:10]:
                ex_name = mastered["name"]
                reason = mastered["reason"]
                suggestion = progression_suggestions.get(ex_name, {})

                if suggestion.get("suggested"):
                    mastery_context_parts.append(
                        f"- {ex_name}: MASTERED ({reason}) -> Suggest: {suggestion['suggested']}"
                    )
                elif suggestion.get("current"):
                    mastery_context_parts.append(
                        f"- {ex_name}: MASTERED ({reason}) at max progression level"
                    )
                else:
                    mastery_context_parts.append(
                        f"- {ex_name}: MASTERED ({reason})"
                    )

        mastery_context = "\n".join(mastery_context_parts) if mastery_context_parts else "No exercises identified as mastered yet."

        logger.info(
            f"[Progression] User {user_id}: {len(mastered_exercises)} mastered exercises, "
            f"{len(progression_suggestions)} with progression suggestions"
        )

        return {
            "mastered_exercises": mastered_exercises,
            "progression_suggestions": progression_suggestions,
            "exercises_marked_easy": exercises_marked_easy,
            "mastery_context": mastery_context,
        }

    except Exception as e:
        logger.error(f"Error getting progression context: {e}")
        return {
            "mastered_exercises": [],
            "progression_suggestions": {},
            "exercises_marked_easy": [],
            "mastery_context": "Unable to analyze exercise history.",
        }


def build_progression_philosophy_prompt(
    rep_preferences: dict,
    progression_context: dict,
) -> str:
    """Build the progression philosophy section for the Gemini prompt."""
    training_focus = rep_preferences.get("training_focus", "balanced")
    min_reps = rep_preferences.get("min_reps", 8)
    max_reps = rep_preferences.get("max_reps", 12)
    avoid_high_reps = rep_preferences.get("avoid_high_reps", False)
    mastery_context = progression_context.get("mastery_context", "")

    focus_descriptions = {
        "strength": "Strength: 4-6 reps, heavier loads, focus on max effort",
        "hypertrophy": "Hypertrophy: 8-12 reps, moderate loads, muscle building",
        "endurance": "Endurance: 12-15 reps, lighter loads, muscular endurance",
        "power": "Power: 1-5 reps, explosive movements, max speed",
        "balanced": "Balanced: 8-12 reps, moderate loads for general fitness",
    }

    prompt_parts = [
        "",
        "## Progression Philosophy",
        "- When an exercise becomes easy (user can do 12+ reps with good form), progress to a HARDER VARIANT instead of adding more reps",
        "- Prefer leverage-based progressions (e.g., push-up -> diamond push-up -> archer push-up) over simply adding repetitions",
        f"- Keep rep ranges within user's preferred range: {min_reps}-{max_reps} reps for most exercises",
        f"- User's training focus is {focus_descriptions.get(training_focus, training_focus)}",
        "",
    ]

    if mastery_context and mastery_context != "Unable to analyze exercise history.":
        prompt_parts.extend([
            "## Exercise Mastery Context",
            "The user has mastered these exercises and is ready for progressions:",
            mastery_context,
            "",
            "For mastered exercises:",
            "- DO NOT prescribe the mastered version - use the suggested progression instead",
            "- If no harder variant exists, consider weighted versions or tempo variations",
            "",
        ])

    prompt_parts.extend([
        "## Avoid Boring Workouts",
        f"- NEVER prescribe more than {max_reps} reps for strength exercises",
    ])

    if avoid_high_reps:
        prompt_parts.append("- User has indicated 'avoid_high_reps' - cap ALL exercises at 12 reps maximum")

    prompt_parts.extend([
        "- Prioritize exercise progression over rep progression",
        "- Include variety - don't repeat the same exercise pattern every workout",
        "- Suggest harder exercise variants for users who have mastered basics",
        "",
    ])

    return "\n".join(prompt_parts)


async def get_user_workout_patterns(user_id: str, days: int = 30) -> dict:
    """Fetch user's historical workout patterns to inform AI workout generation."""
    try:
        db = get_supabase_db()
        cutoff_date = (datetime.now() - timedelta(days=days)).isoformat()

        exercise_patterns = {}
        typical_adjustments = {
            "sets_increased": 0, "sets_decreased": 0,
            "reps_increased": 0, "reps_decreased": 0,
            "weight_increased": 0, "weight_decreased": 0,
        }
        frequently_used = []

        user = db.get_user(user_id)
        set_rep_limits = {
            "max_sets_per_exercise": 5, "min_sets_per_exercise": 2,
            "max_reps_per_set": 15, "min_reps_per_set": 6,
        }

        if user:
            preferences = user.get("preferences", {})
            if isinstance(preferences, str):
                try:
                    preferences = json.loads(preferences)
                except json.JSONDecodeError:
                    preferences = {}

            set_rep_limits["max_sets_per_exercise"] = preferences.get("max_sets_per_exercise", 5)
            set_rep_limits["min_sets_per_exercise"] = preferences.get("min_sets_per_exercise", 2)
            set_rep_limits["max_reps_per_set"] = preferences.get("max_reps_per_set", 15)
            set_rep_limits["min_reps_per_set"] = preferences.get("min_reps_per_set", 6)

        # 1. Analyze completed workout logs
        try:
            workout_logs_result = db.client.table("workout_logs").select(
                "id, workout_id, sets_json, completed_at"
            ).eq("user_id", user_id).gte("completed_at", cutoff_date).execute()

            if workout_logs_result.data:
                exercise_data = {}

                for log in workout_logs_result.data:
                    sets_json = log.get("sets_json", [])
                    if isinstance(sets_json, str):
                        try:
                            sets_json = json.loads(sets_json)
                        except json.JSONDecodeError:
                            continue

                    for exercise_entry in sets_json:
                        if isinstance(exercise_entry, dict):
                            ex_name = exercise_entry.get("name") or exercise_entry.get("exercise_name", "")
                            if not ex_name:
                                continue

                            ex_name_lower = ex_name.lower()

                            if ex_name_lower not in exercise_data:
                                exercise_data[ex_name_lower] = {
                                    "name": ex_name, "total_sets": 0, "total_reps": 0,
                                    "total_weight": 0, "sessions": 0,
                                    "set_counts": [], "rep_counts": [], "weights": [],
                                }

                            sets = exercise_entry.get("sets", [])
                            if isinstance(sets, list):
                                set_count = len(sets)
                                for s in sets:
                                    if isinstance(s, dict):
                                        reps = s.get("reps", 0) or s.get("reps_completed", 0)
                                        weight = s.get("weight", 0) or s.get("weight_kg", 0)

                                        if isinstance(reps, (int, float)) and reps > 0:
                                            exercise_data[ex_name_lower]["total_reps"] += reps
                                            exercise_data[ex_name_lower]["rep_counts"].append(reps)
                                        if isinstance(weight, (int, float)) and weight > 0:
                                            exercise_data[ex_name_lower]["total_weight"] += weight
                                            exercise_data[ex_name_lower]["weights"].append(weight)

                                if set_count > 0:
                                    exercise_data[ex_name_lower]["total_sets"] += set_count
                                    exercise_data[ex_name_lower]["set_counts"].append(set_count)

                            exercise_data[ex_name_lower]["sessions"] += 1

                for ex_name_lower, data in exercise_data.items():
                    sessions = data["sessions"]
                    if sessions > 0:
                        avg_sets = round(sum(data["set_counts"]) / len(data["set_counts"]), 1) if data["set_counts"] else 3
                        avg_reps = round(sum(data["rep_counts"]) / len(data["rep_counts"]), 1) if data["rep_counts"] else 10
                        avg_weight = round(sum(data["weights"]) / len(data["weights"]), 1) if data["weights"] else 0

                        exercise_patterns[ex_name_lower] = {
                            "name": data["name"],
                            "avg_sets": avg_sets, "avg_reps": avg_reps,
                            "avg_weight_kg": avg_weight,
                            "max_weight_kg": max(data["weights"]) if data["weights"] else 0,
                            "sessions": sessions,
                        }

                frequently_used = [
                    data["name"] for name, data in exercise_data.items()
                    if data["sessions"] >= 3
                ]

                logger.info(f"[Workout Patterns] Found {len(exercise_patterns)} exercises with patterns for user {user_id}")

        except Exception as e:
            logger.debug(f"Could not analyze workout logs: {e}")

        # 2. Analyze set adjustments
        try:
            adjustments_result = db.client.table("set_adjustments").select(
                "adjustment_type, adjustment_value"
            ).eq("user_id", user_id).gte("created_at", cutoff_date).execute()

            if adjustments_result.data:
                for adj in adjustments_result.data:
                    adj_type = adj.get("adjustment_type", "")
                    adj_value = adj.get("adjustment_value", 0)

                    if adj_type == "sets" and adj_value > 0:
                        typical_adjustments["sets_increased"] += 1
                    elif adj_type == "sets" and adj_value < 0:
                        typical_adjustments["sets_decreased"] += 1
                    elif adj_type == "reps" and adj_value > 0:
                        typical_adjustments["reps_increased"] += 1
                    elif adj_type == "reps" and adj_value < 0:
                        typical_adjustments["reps_decreased"] += 1
                    elif adj_type == "weight" and adj_value > 0:
                        typical_adjustments["weight_increased"] += 1
                    elif adj_type == "weight" and adj_value < 0:
                        typical_adjustments["weight_decreased"] += 1

        except Exception as e:
            logger.debug(f"Could not analyze set adjustments (table may not exist): {e}")

        # 3. Build historical context string
        historical_context_parts = []

        if set_rep_limits["max_sets_per_exercise"] < 5 or set_rep_limits["max_reps_per_set"] < 15:
            historical_context_parts.extend([
                "",
                "## USER SET/REP LIMITS (CRITICAL - NEVER EXCEED)",
                f"- Maximum {set_rep_limits['max_sets_per_exercise']} sets per exercise. NEVER prescribe more than this.",
                f"- Maximum {set_rep_limits['max_reps_per_set']} reps per set. NEVER prescribe more than this.",
                f"- Minimum {set_rep_limits['min_sets_per_exercise']} sets per exercise.",
                f"- Minimum {set_rep_limits['min_reps_per_set']} reps per set.",
                "- These are HARD limits set by the user. Violating them will cause the workout to be rejected.",
                "",
            ])

        if exercise_patterns:
            historical_context_parts.extend([
                "",
                "## HISTORICAL EXERCISE DATA",
                "Use these baselines when prescribing exercises the user has done before:",
            ])

            sorted_exercises = sorted(
                exercise_patterns.items(),
                key=lambda x: x[1]["sessions"],
                reverse=True
            )[:15]

            for ex_name_lower, pattern in sorted_exercises:
                weight_str = f", avg weight: {pattern['avg_weight_kg']}kg" if pattern['avg_weight_kg'] > 0 else ""
                historical_context_parts.append(
                    f"- {pattern['name']}: {pattern['avg_sets']} sets x {pattern['avg_reps']} reps{weight_str} (based on {pattern['sessions']} sessions)"
                )

            historical_context_parts.append("")

        total_adjustments = sum(typical_adjustments.values())
        if total_adjustments >= 5:
            historical_context_parts.append("## USER ADJUSTMENT PATTERNS")
            if typical_adjustments["sets_decreased"] > typical_adjustments["sets_increased"]:
                historical_context_parts.append("- User often reduces sets - start with FEWER sets")
            if typical_adjustments["reps_decreased"] > typical_adjustments["reps_increased"]:
                historical_context_parts.append("- User often reduces reps - start with FEWER reps")
            if typical_adjustments["weight_decreased"] > typical_adjustments["weight_increased"]:
                historical_context_parts.append("- User often reduces weight - start LIGHTER")
            historical_context_parts.append("")

        historical_context = "\n".join(historical_context_parts)

        logger.info(
            f"[Workout Patterns] User {user_id}: {len(exercise_patterns)} exercises, "
            f"{len(frequently_used)} frequently used, limits: {set_rep_limits}"
        )

        return {
            "exercise_patterns": exercise_patterns,
            "set_rep_limits": set_rep_limits,
            "typical_adjustments": typical_adjustments,
            "frequently_used": frequently_used,
            "historical_context": historical_context,
        }

    except Exception as e:
        logger.error(f"Error getting workout patterns for user {user_id}: {e}")
        return {
            "exercise_patterns": {},
            "set_rep_limits": {
                "max_sets_per_exercise": 5, "min_sets_per_exercise": 2,
                "max_reps_per_set": 15, "min_reps_per_set": 6,
            },
            "typical_adjustments": {},
            "frequently_used": [],
            "historical_context": "",
        }
