"""Second part of workout_generation_helpers.py (auto-split for size)."""
from typing import Dict, List, Optional, Tuple
import asyncio
import logging
import re

from google.genai import types
from models.gemini_schemas import WorkoutNamingResponse
from services.gemini.constants import gemini_generate_with_retry

logger = logging.getLogger(__name__)


# Per-injury plain-English coaching bullets injected into the Gemini prompt.
# Only bullets for injuries the user ACTUALLY has are included (filtered dynamically).
# This is the upstream defense-in-depth layer; the downstream validator + swap
# algorithm (Phase 2.4) is the authoritative safety gate.
_INJURY_PROMPT_BULLETS: Dict[str, str] = {
    "shoulder": "Shoulder: avoid overhead pressing/pulling language.",
    "lower_back": "Lower back: avoid loaded rotation, spinal flexion, or hip-hinge language.",
    "back": "Lower back: avoid loaded rotation, spinal flexion, or hip-hinge language.",
    "knee": "Knee: avoid plyometric, deep-squat, single-leg-jump language.",
    "elbow": "Elbow: avoid grip-heavy pulling language.",
    "wrist": "Wrist: avoid weight-loaded push-up or hanging language.",
    "ankle": "Ankle: avoid jumping, pivoting, or balance-under-load language.",
    "hip": "Hip: avoid rotational or deep-flexion language.",
    "neck": "Neck: avoid overhead or inverted language.",
}


def _normalize_injury_key(injury: str) -> str:
    """Normalize an injury string for dict lookup (lowercase, spaces/dashes -> underscore)."""
    return re.sub(r"[\s\-]+", "_", (injury or "").strip().lower())


def _build_safety_constraints_block(
    injuries: Optional[List[str]],
    difficulty: str,
) -> str:
    """
    Build the CRITICAL SAFETY CONSTRAINTS block injected into the prompt.

    Only per-injury bullets for injuries the user ACTUALLY reports are included
    (defensive filter — keeps the prompt tight and the instructions relevant).
    """
    injuries_list = [i for i in (injuries or []) if i and str(i).strip()]
    injuries_display = ", ".join(injuries_list) if injuries_list else "none"

    # Dedup bullets while preserving first-seen order (e.g. 'back' and 'lower_back'
    # both map to the same bullet — don't double-print it).
    seen_bullets: set = set()
    bullets: List[str] = []
    for inj in injuries_list:
        key = _normalize_injury_key(inj)
        bullet = _INJURY_PROMPT_BULLETS.get(key)
        if bullet and bullet not in seen_bullets:
            seen_bullets.add(bullet)
            bullets.append(f"   - {bullet}")

    per_injury_section = (
        "\n".join(bullets)
        if bullets
        else "   - (No injuries reported — treat exercise list as pre-cleared.)"
    )

    # Difficulty-specific rep guidance (rule 5 below). Beginner gets explicit
    # lower rep-range floor to prevent 1RM / near-max prescriptions.
    if difficulty == "beginner" or difficulty == "easy":
        difficulty_guidance = (
            '5. Respect the user\'s selected difficulty tier. For "beginner", use lower rep\n'
            "   ranges (e.g., 2-3 sets x 10-15 reps with 60-90s rest). Do NOT prescribe\n"
            "   1RM or near-maximal loads."
        )
    else:
        difficulty_guidance = (
            "5. Respect the user's selected difficulty tier. Do NOT escalate exercise\n"
            "   complexity beyond the tier of the provided list."
        )

    return f"""
CRITICAL SAFETY CONSTRAINTS
The user has reported injuries in: {injuries_display}.

Rules (these are ABSOLUTE and override creative freedom):
1. You may ONLY use exercises from the provided "Available Exercises" list below.
   Do NOT invent exercises, variations, or combinations. Do NOT suggest alternative
   exercises not in the list, even if they seem like good replacements.
2. Each exercise in the Available Exercises list has ALREADY been pre-filtered to
   be safe for this user's injury profile. You do NOT need to re-evaluate safety.
3. For each injury, here is a plain-English summary of why the pre-filter matters
   (so your workout naming + instructions acknowledge the context):
{per_injury_section}
4. Your output MUST include exactly the exercises provided, in the same order, with
   the same count. You may adjust sets/reps/rest per exercise to match difficulty.
{difficulty_guidance}

If you need to omit an exercise for any reason, return a "SAFETY_REJECT" field
explaining why. Do NOT silently substitute.
"""


def _normalize_exercise_name(name: str) -> str:
    """Lowercase + collapse whitespace for case-insensitive exercise-name comparison."""
    return re.sub(r"\s+", " ", (name or "").strip().lower())


def _audit_gemini_output_against_library(
    ai_response: object,
    input_exercises: List[Dict],
) -> Tuple[List[str], List[str]]:
    """
    Audit the Gemini response for:
      1. Hallucinated exercise names (not in the input library list) — telemetry only;
         the downstream validator is the authoritative gate.
      2. SAFETY_REJECT markers returned by Gemini — treated as violations so the
         downstream swap algorithm can repair them.

    Returns (hallucinations, safety_rejects) — two lists of exercise names.
    Never raises. Best-effort introspection over the parsed response.
    """
    hallucinations: List[str] = []
    safety_rejects: List[str] = []

    if ai_response is None:
        return hallucinations, safety_rejects

    allowed_names = {_normalize_exercise_name(ex.get("name", "")) for ex in input_exercises}

    # Gemini returns a structured Pydantic object (WorkoutNamingResponse) plus it
    # MAY include an "exercises" field if it decided to echo them. We also check
    # for a top-level "safety_reject" style field. All access is defensive.
    def _get_attr_or_key(obj, key):
        if obj is None:
            return None
        if hasattr(obj, key):
            return getattr(obj, key)
        if isinstance(obj, dict):
            return obj.get(key)
        return None

    # SAFETY_REJECT can come back as a field, dict value, or nested under exercises.
    safety_reject_field = _get_attr_or_key(ai_response, "safety_reject") or \
        _get_attr_or_key(ai_response, "SAFETY_REJECT")
    if safety_reject_field:
        if isinstance(safety_reject_field, (list, tuple)):
            safety_rejects.extend([str(x) for x in safety_reject_field if x])
        else:
            safety_rejects.append(str(safety_reject_field))

    exercises_field = _get_attr_or_key(ai_response, "exercises")
    if isinstance(exercises_field, list):
        for ex in exercises_field:
            name = _get_attr_or_key(ex, "name")
            if not name:
                continue
            if _normalize_exercise_name(name) not in allowed_names:
                hallucinations.append(str(name))
            # Per-exercise SAFETY_REJECT marker
            rej = _get_attr_or_key(ex, "safety_reject") or _get_attr_or_key(ex, "SAFETY_REJECT")
            if rej:
                safety_rejects.append(str(name))

    return hallucinations, safety_rejects


class WorkoutGenerationMixinPart2:
    """Second half of WorkoutGenerationMixin methods. Use as mixin."""

    async def generate_workout_from_library(
        self,
        exercises: List[Dict],
        fitness_level: str,
        goals: List[str],
        duration_minutes: int = 45,
        focus_areas: Optional[List[str]] = None,
        avoid_name_words: Optional[List[str]] = None,
        workout_date: Optional[str] = None,
        age: Optional[int] = None,
        activity_level: Optional[str] = None,
        intensity_preference: Optional[str] = None,
        custom_program_description: Optional[str] = None,
        workout_type_preference: Optional[str] = None,
        comeback_context: Optional[str] = None,
        strength_history: Optional[Dict[str, Dict]] = None,
        personal_bests: Optional[Dict[str, Dict]] = None,
        user_dob: Optional[str] = None,
        injuries: Optional[List[str]] = None,
    ) -> Dict:
        """
        Generate a workout plan using exercises from the exercise library.

        Instead of having AI invent exercises, this method takes pre-selected
        exercises from the library and asks AI to create a creative workout
        name and organize them appropriately.

        Args:
            exercises: List of exercises from the exercise library
            fitness_level: beginner, intermediate, or advanced
            goals: List of fitness goals
            duration_minutes: Target workout duration
            focus_areas: Optional specific areas to focus on
            avoid_name_words: Words to avoid in workout name
            workout_date: Optional date for holiday theming
            age: Optional user's age for age-appropriate adjustments
            activity_level: Optional activity level
            intensity_preference: Optional intensity preference (easy, medium, hard)
            custom_program_description: Optional user's custom program description (e.g., "Train for HYROX")
            workout_type_preference: Optional workout type preference (strength, cardio, mixed)
            comeback_context: Optional context string for users returning from extended breaks
            strength_history: Optional dict of exercise performance history (last weight, max weight, reps)
            personal_bests: Optional dict of user's personal records per exercise

        Returns:
            Dict with workout structure
        """
        if not exercises:
            raise ValueError("No exercises provided")

        # Use intensity_preference if provided, otherwise derive from fitness_level
        if intensity_preference:
            difficulty = intensity_preference

            # Warn about potentially dangerous combinations
            if fitness_level == "beginner" and intensity_preference == "hell":
                logger.warning(f"[Gemini] Beginner fitness level with HELL intensity - this is extremely challenging!")
            elif fitness_level == "beginner" and intensity_preference == "hard":
                logger.warning(f"[Gemini] Beginner fitness level with hard intensity preference - ensure exercises are scaled appropriately")
            elif fitness_level == "intermediate" and intensity_preference == "hell":
                logger.info(f"[Gemini] Intermediate fitness level with HELL intensity - maximum challenge mode")
            elif fitness_level == "intermediate" and intensity_preference == "hard":
                logger.info(f"[Gemini] Intermediate fitness level with hard intensity - will challenge the user")
            elif intensity_preference == "hell":
                logger.info(f"[Gemini] HELL MODE ACTIVATED - generating maximum intensity workout from library")
        else:
            difficulty = "easy" if fitness_level == "beginner" else ("hard" if fitness_level == "advanced" else "medium")

        # Build avoid words instruction
        avoid_instruction = ""
        if avoid_name_words and len(avoid_name_words) > 0:
            avoid_instruction = f"\n\n⚠️ Do NOT use these words in the workout name: {', '.join(avoid_name_words[:15])}"

        # Check for holiday theming
        holiday_theme = self._get_holiday_theme(workout_date, user_dob=user_dob)
        holiday_instruction = f"\n\n{holiday_theme}" if holiday_theme else ""

        # Add safety instruction if there's a mismatch between fitness level and intensity
        safety_instruction = ""
        if fitness_level == "beginner" and difficulty == "hard":
            safety_instruction = "\n\n⚠️ SAFETY NOTE: User is a beginner but wants hard intensity. Structure exercises with more rest periods and ensure reps/sets are achievable with proper form. Focus on compound movements rather than advanced techniques."

        # Build custom program context if user has specified a custom training goal
        custom_program_context = ""
        if custom_program_description and custom_program_description.strip():
            custom_program_context = f"\n- Custom Training Goal: {custom_program_description}"

        # Add age context for appropriate naming and notes
        age_context = ""
        if age:
            if age >= 75:
                age_context = f"\n- Age: {age} (elderly - focus on gentle, supportive movements)"
            elif age >= 60:
                age_context = f"\n- Age: {age} (senior - prioritize low-impact, balance-focused exercises)"
            elif age >= 45:
                age_context = f"\n- Age: {age} (middle-aged - joint-friendly approach)"
            else:
                age_context = f"\n- Age: {age}"

        # Determine workout type
        workout_type = workout_type_preference if workout_type_preference else "strength"

        # Build comeback instruction
        comeback_instruction = ""
        if comeback_context and comeback_context.strip():
            logger.info(f"🔄 [Gemini Service] Library workout - user in comeback mode")
            comeback_instruction = f"\n\n🔄 COMEBACK NOTE: User is returning from an extended break. Include comeback/return-to-training themes in the name (e.g., 'Comeback', 'Return', 'Fresh Start')."

        # Build performance context from strength history and personal bests
        performance_context = ""
        if strength_history or personal_bests:
            from api.v1.workouts.utils import format_performance_context
            performance_context = format_performance_context(
                exercises, strength_history or {}, personal_bests or {}
            )
            if performance_context:
                performance_context = f"\n\n{performance_context}"
                logger.info(f"[Gemini Service] Added performance context for {len([ex for ex in exercises if strength_history.get(ex.get('name')) or personal_bests.get(ex.get('name'))])} exercises")

        # Format exercises for the prompt
        exercise_list = "\n".join([
            f"- {ex.get('name', 'Unknown')}: targets {ex.get('muscle_group', 'unknown')}, equipment: {ex.get('equipment', 'bodyweight')}"
            for ex in exercises
        ])

        # Difficulty-aware naming hints
        difficulty_naming = ""
        if difficulty in ("hell", "extreme"):
            difficulty_naming = "\nThis is HELL MODE. Name MUST reflect EXTREME intensity (Inferno, Destroyer, Savage, Beast, Annihilation)."
        elif difficulty == "hard":
            difficulty_naming = "\nThis is a hard workout. Name should reflect high intensity and challenge."
        elif difficulty == "easy":
            difficulty_naming = "\nThis is an easy/recovery workout. Name should be approachable and light."

        # Defense-in-depth safety constraints block. Validator + swap downstream are
        # authoritative; this reduces upstream violations so the swap round-trip is
        # rarely needed. See plan Part 2.6.
        safety_constraints_block = _build_safety_constraints_block(
            injuries=injuries,
            difficulty=fitness_level if fitness_level == "beginner" else difficulty,
        )

        prompt = f"""I have selected these exercises for a {duration_minutes}-minute {focus_areas[0] if focus_areas else 'full body'} workout.

User profile:
- Fitness Level: {fitness_level}
- Goals: {', '.join(goals) if goals else 'General fitness'}{age_context}{custom_program_context}{performance_context}{safety_instruction}
{difficulty_naming}
{safety_constraints_block}
Available Exercises (pre-filtered for safety — use EXACTLY these, no substitutions):
{exercise_list}

Create a CREATIVE and MOTIVATING workout name (3-4 words) that reflects the user's training focus.

Examples of good names:
- "Thunder Strike Legs"
- "Phoenix Power Chest"
- "Savage Wolf Back"
- "Iron Storm Arms"
{holiday_instruction}{avoid_instruction}{comeback_instruction}

Return a JSON object with:
{{
  "name": "Your creative workout name here",
  "type": "{workout_type}",
  "difficulty": "{difficulty}",
  "notes": "A personalized tip for this workout based on the user's performance history (1-2 sentences). Reference their progress towards PRs or recent improvements if available."
}}"""

        # Log the full prompt for debugging
        logger.info("=" * 80)
        logger.info("[GEMINI PROMPT - generate_workout_from_library]")
        logger.info(f"Parameters: fitness_level={fitness_level}, goals={goals}, duration={duration_minutes}min")
        logger.info(f"Focus areas: {focus_areas}, intensity_preference={intensity_preference}")
        logger.info(f"Custom program description: {custom_program_description}")
        logger.info(f"🤖 Injuries (safety-block injected): {injuries or []}")
        logger.info(f"Exercise count: {len(exercises)}")
        logger.info(f"Exercise names: {[ex.get('name') for ex in exercises]}")
        logger.info(f"Strength history: {len(strength_history) if strength_history else 0} exercises")
        logger.info(f"Personal bests: {len(personal_bests) if personal_bests else 0} exercises")
        logger.info("-" * 40)
        logger.info(f"FULL PROMPT:\n{prompt}")
        logger.info("=" * 80)

        try:
            response = await gemini_generate_with_retry(
                model=self.model,
                contents=prompt,
                config=types.GenerateContentConfig(
                    system_instruction="You are a creative fitness coach. Generate motivating workout names. Return ONLY valid JSON.",
                    response_mime_type="application/json",
                    response_schema=WorkoutNamingResponse,
                    temperature=0.8,
                    max_output_tokens=2000  # Increased for thinking models
                ),
                timeout=30,
                method_name="generate_workout_from_library",
            )

            # Use response.parsed for structured output - SDK handles JSON parsing
            ai_response = response.parsed
            if not ai_response:
                raise ValueError("Gemini returned empty workout naming response")

            # Post-processing safety audit (telemetry only — downstream validator is
            # the authoritative gate; see plan Part 2.4). We log hallucinated exercise
            # names (Gemini invented a name not in the input list) and SAFETY_REJECT
            # markers for observability.
            try:
                hallucinations, safety_rejects = _audit_gemini_output_against_library(
                    ai_response=ai_response,
                    input_exercises=exercises,
                )
                if hallucinations:
                    logger.warning(
                        f"⚠️ 🤖 [Gemini audit] Hallucinated exercise names (not in input list) "
                        f"— downstream validator will catch: {hallucinations}"
                    )
                if safety_rejects:
                    logger.warning(
                        f"⚠️ 🤖 [Gemini audit] SAFETY_REJECT markers returned — "
                        f"downstream swap will repair: {safety_rejects}"
                    )
            except Exception as audit_err:
                # Audit is telemetry only — never let it break generation.
                logger.error(f"❌ [Gemini audit] Non-fatal audit error: {audit_err}")

            # Combine AI response with our exercises
            return {
                "name": ai_response.name or "Power Workout",
                "type": ai_response.type or "strength",
                "difficulty": difficulty,
                "duration_minutes": duration_minutes,
                "target_muscles": list(set([ex.get('muscle_group', '') for ex in exercises if ex.get('muscle_group')])),
                "exercises": exercises,
                "notes": ai_response.notes or "Focus on proper form and controlled movements."
            }

        except Exception as e:
            logger.error(f"Error generating workout name: {e}", exc_info=True)
            raise  # No fallback - let errors propagate


# ---------------------------------------------------------------------------
# Manual sanity-check harness
# ---------------------------------------------------------------------------
# Run:  python -m services.gemini.workout_generation_helpers_part2
# Prints the fully-rendered CRITICAL SAFETY CONSTRAINTS block so humans can
# eyeball correctness without needing to stand up the full Gemini pipeline.
if __name__ == "__main__":
    print("=" * 80)
    print("SAMPLE 1: 3 injuries (shoulder, lower_back, knee), beginner")
    print("=" * 80)
    print(_build_safety_constraints_block(
        injuries=["shoulder", "lower_back", "knee"],
        difficulty="beginner",
    ))

    print("=" * 80)
    print("SAMPLE 2: all 8 injuries, beginner")
    print("=" * 80)
    print(_build_safety_constraints_block(
        injuries=["shoulder", "lower_back", "knee", "elbow",
                  "wrist", "ankle", "hip", "neck"],
        difficulty="beginner",
    ))

    print("=" * 80)
    print("SAMPLE 3: no injuries, intermediate")
    print("=" * 80)
    print(_build_safety_constraints_block(injuries=None, difficulty="medium"))

    print("=" * 80)
    print("SAMPLE 4: dedup test ('back' and 'lower_back' both map to same bullet)")
    print("=" * 80)
    print(_build_safety_constraints_block(
        injuries=["back", "lower_back", "shoulder"],
        difficulty="beginner",
    ))

    # Inline assertions (print-based — no test framework dep)
    block_shoulder = _build_safety_constraints_block(["shoulder"], "beginner")
    assert "avoid overhead pressing" in block_shoulder, \
        "Expected shoulder bullet to mention 'avoid overhead pressing'"
    assert "2-3 sets x 10-15 reps" in block_shoulder, \
        "Expected beginner rep-range guidance"
    assert "SAFETY_REJECT" in block_shoulder, \
        "Expected SAFETY_REJECT instruction"
    assert "ABSOLUTE and override creative freedom" in block_shoulder, \
        "Expected ABSOLUTE rules header"

    block_none = _build_safety_constraints_block(None, "medium")
    assert "injuries in: none" in block_none, "Expected 'none' when no injuries"
    assert "No injuries reported" in block_none, "Expected no-injury fallback bullet"

    block_knee = _build_safety_constraints_block(["knee"], "beginner")
    assert "avoid overhead pressing" not in block_knee, \
        "Knee-only should NOT contain shoulder bullet"
    assert "plyometric, deep-squat" in block_knee, \
        "Expected knee-specific bullet"

    # Dedup: 'back' and 'lower_back' both map to the same bullet — print ONCE.
    block_dedup = _build_safety_constraints_block(
        ["back", "lower_back"], "beginner"
    )
    assert block_dedup.count("avoid loaded rotation") == 1, \
        "Expected duplicate injury keys to dedup the bullet"

    print("\n✅ All inline assertions passed.")
