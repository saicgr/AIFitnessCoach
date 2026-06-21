"""
Readiness, mood, injury, and comeback utilities.

Handles:
- User readiness score fetching and interpretation
- Mood check-in data
- Injury-to-muscle mapping
- Workout parameter adjustments for readiness/mood
- Active injuries with muscle avoidance
- Comeback/break detection and adjustments
"""
import json
from datetime import datetime, timedelta
from typing import List, Optional, Dict, Any

from core.supabase_db import get_supabase_db
from core.logger import get_logger
# map_recovery_to_tier is called below (recovery-adaptation path). It was used
# without being imported → NameError that 500'd get_today_workout for any user
# on the recovery path (Sentry PYTHON-FASTAPI-50 / -4Z). No circular import:
# readiness_service does not import this module.
from services.readiness_service import map_recovery_to_tier

logger = get_logger(__name__)


# Mapping from injury body parts to muscles that should be avoided
INJURY_TO_AVOIDED_MUSCLES = {
    "shoulder": ["shoulders", "chest", "triceps", "delts", "anterior_delts", "lateral_delts", "rear_delts"],
    "back": ["back", "lats", "lower_back", "traps", "rhomboids", "erector_spinae"],
    "lower_back": ["lower_back", "back", "erector_spinae", "glutes", "hamstrings"],
    "knee": ["quads", "hamstrings", "calves", "legs", "quadriceps", "glutes"],
    "wrist": ["forearms", "biceps", "triceps", "grip"],
    "ankle": ["calves", "legs", "tibialis", "soleus", "gastrocnemius"],
    "hip": ["glutes", "hip_flexors", "legs", "quads", "hamstrings", "adductors", "abductors"],
    "elbow": ["biceps", "triceps", "forearms", "brachialis"],
    "neck": ["traps", "shoulders", "neck", "upper_back"],
    "chest": ["chest", "pectorals", "shoulders", "triceps"],
    "groin": ["adductors", "hip_flexors", "legs", "quads"],
    "hamstring": ["hamstrings", "glutes", "legs"],
    "quad": ["quads", "quadriceps", "legs", "knee"],
    "calf": ["calves", "legs", "ankle"],
    "rotator_cuff": ["shoulders", "chest", "delts", "rotator_cuff"],
    # Muscle-area limitations — the onboarding head-to-toe quick chips (Abs,
    # Chest, Upper Back, Biceps, Triceps, Forearms, Glutes, Groin, Quads,
    # Hamstrings, Calves) and direct body-map taps. Unlike the joint entries
    # above (which avoid a whole region), these are SURGICAL: a sore biceps
    # should skip biceps work, not nuke all leg/push training. Tokens use the
    # library's spellings (see BODY_MAP_MUSCLE_NORMALIZATION) so
    # filter_by_avoided_muscles matches. Keyed by the exact chip id (plural),
    # checked before the singular substring fallback.
    "abs": ["abdominals", "abs", "core", "obliques"],
    "core": ["core", "abdominals", "abs"],
    "obliques": ["obliques", "abdominals", "core"],
    "upper_back": ["upper back", "lats", "latissimus dorsi", "traps", "trapezius", "rhomboids"],
    "biceps": ["biceps", "brachialis"],
    "triceps": ["triceps"],
    "forearms": ["forearms", "grip"],
    "glutes": ["glutes"],
    "quads": ["quadriceps", "quads"],
    "hamstrings": ["hamstrings"],
    "calves": ["calves", "soleus", "gastrocnemius"],
}


# Body-map muscle vocabulary (from the onboarding injury/limitations body map).
# The limitations list may now contain RAW muscle-group names (the user tapped a
# muscle on the body map) in addition to injury chip ids + free text. These are
# NOT injuries — each maps to itself (avoid exercises targeting that muscle).
#
# Each entry expands a body-map name to the library substring token(s) that
# actually appear in exercise_library_cleaned.target_muscle / body_part — those
# are free-text strings like "upper back (trapezius, rhomboids)" or
# "abdominals (rectus abdominis)", matched downstream by substring contains
# (filter_by_avoided_muscles). So we must reconcile naming:
#   - underscores -> spaces: "upper_back" -> "upper back" (library never stores
#     the underscore form, so the raw token would match nothing)
#   - synonyms the library prefers: "abs" -> "abdominals"+"core",
#     "lats" -> "latissimus dorsi"(+"lats"), "traps" -> "trapezius"(+"traps")
# Tokens are lowercase; downstream lowercases both sides before matching.
BODY_MAP_MUSCLE_NORMALIZATION = {
    "chest": ["chest"],
    "shoulders": ["shoulders"],
    "obliques": ["obliques"],
    "abs": ["abdominals", "abs", "core"],
    "abductors": ["abductors"],
    "biceps": ["biceps"],
    "calves": ["calves"],
    "forearms": ["forearms"],
    "glutes": ["glutes"],
    "hamstrings": ["hamstrings"],
    "lats": ["latissimus dorsi", "lats"],
    "upper_back": ["upper back"],
    "quadriceps": ["quadriceps"],
    "traps": ["trapezius", "traps"],
    "triceps": ["triceps"],
    "adductors": ["adductors"],
    "lower_back": ["lower back", "erector spinae"],
    "core": ["core"],
}


async def get_user_readiness_score(user_id: str) -> Optional[int]:
    """Get the user's latest readiness score (0-100) or None if not available."""
    try:
        db = get_supabase_db()

        result = db.client.table("readiness_scores") \
            .select("readiness_score, submitted_at") \
            .eq("user_id", user_id) \
            .order("submitted_at", desc=True) \
            .limit(1) \
            .execute()

        if result.data and len(result.data) > 0:
            score = result.data[0].get("readiness_score")
            created_at = result.data[0].get("submitted_at", "")

            if created_at:
                try:
                    score_time = datetime.fromisoformat(created_at.replace("Z", "+00:00"))
                    age_hours = (datetime.now(score_time.tzinfo) - score_time).total_seconds() / 3600

                    if age_hours > 24:
                        logger.info(f"🔍 [Readiness] Score for user {user_id} is {age_hours:.1f} hours old, may be stale")
                except Exception as e:
                    logger.debug(f"Failed to parse readiness timestamp: {e}")

            logger.info(f"✅ [Readiness] User {user_id} readiness score: {score}")
            return score

        logger.debug(f"[Readiness] No readiness score found for user {user_id}")
        return None

    except Exception as e:
        logger.error(f"❌ [Readiness] Error getting readiness score for user {user_id}: {e}", exc_info=True)
        return None


async def get_user_latest_mood(user_id: str) -> Optional[dict]:
    """Get the user's latest mood check-in from today."""
    try:
        db = get_supabase_db()

        try:
            result = db.client.table("today_mood_checkin") \
                .select("mood, check_in_time") \
                .eq("user_id", user_id) \
                .limit(1) \
                .execute()
        except Exception:
            today_start = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0).isoformat()

            result = db.client.table("mood_checkins") \
                .select("mood, check_in_time") \
                .eq("user_id", user_id) \
                .gte("check_in_time", today_start) \
                .order("check_in_time", desc=True) \
                .limit(1) \
                .execute()

        if result.data and len(result.data) > 0:
            mood_data = {
                "mood": result.data[0].get("mood", "good"),
                "check_in_time": result.data[0].get("check_in_time"),
            }
            logger.info(f"✅ [Mood] User {user_id} mood: {mood_data['mood']}")
            return mood_data

        logger.debug(f"[Mood] No mood check-in found for user {user_id} today")
        return None

    except Exception as e:
        logger.error(f"❌ [Mood] Error getting mood for user {user_id}: {e}", exc_info=True)
        return None


def get_muscles_to_avoid_from_injuries(injuries: List[str]) -> List[str]:
    """Convert a mixed injuries/limitations list into muscles to avoid.

    The input list may now contain THREE kinds of entries, all flowing through
    the same `limitations`/`injuries` field (quiz -> preferences -> generation):
      1. Injury chip ids (knee, shoulder, lower_back, ...) -> mapped to the
         muscles they implicate via INJURY_TO_AVOIDED_MUSCLES. (Unchanged.)
      2. RAW muscle-group names from the onboarding body map (chest, abs, lats,
         upper_back, ...) -> the user tapped that muscle; avoid exercises that
         target it. Normalized to the library's token spellings via
         BODY_MAP_MUSCLE_NORMALIZATION (underscore->space, abs->abdominals/core,
         lats->latissimus dorsi, traps->trapezius).
      3. 'none' / 'other' / free text -> ignored for muscle avoidance.

    Fail-open: empty / unrecognized entries contribute nothing; an unknown entry
    is logged and skipped (never raises). Injury-id behavior is preserved exactly
    (checked first), so this never regresses existing injury avoidance.
    """
    if not injuries:
        return []

    # Free-text / sentinel tokens that must never drive muscle avoidance.
    IGNORED_TOKENS = {"none", "other", "", "n/a", "na"}

    muscles_to_avoid = set()

    for injury in injuries:
        if not injury or not isinstance(injury, str):
            continue
        injury_lower = injury.lower().strip()

        if injury_lower in IGNORED_TOKENS:
            continue

        # 1. Injury chip id -> implicated muscles (exact). Checked FIRST so the
        #    existing injury-avoidance behavior is unchanged.
        if injury_lower in INJURY_TO_AVOIDED_MUSCLES:
            muscles_to_avoid.update(INJURY_TO_AVOIDED_MUSCLES[injury_lower])
            logger.info(f"🔍 [Injury Mapping] {injury} -> avoiding: {INJURY_TO_AVOIDED_MUSCLES[injury_lower]}")
            continue

        # 2. Raw body-map muscle name -> normalized library tokens (avoid that
        #    muscle directly). Also tolerate a space form of the underscored key.
        muscle_key = injury_lower.replace(" ", "_")
        if muscle_key in BODY_MAP_MUSCLE_NORMALIZATION:
            tokens = BODY_MAP_MUSCLE_NORMALIZATION[muscle_key]
            muscles_to_avoid.update(tokens)
            logger.info(f"🔍 [Body-map Muscle] {injury} -> avoiding tokens: {tokens}")
            continue

        # 3. Substring fallback against the injury map (e.g. "left knee").
        matched = False
        for injury_key, muscles in INJURY_TO_AVOIDED_MUSCLES.items():
            if injury_key in injury_lower or injury_lower in injury_key:
                muscles_to_avoid.update(muscles)
                logger.info(f"🔍 [Injury Mapping] {injury} (partial match: {injury_key}) -> avoiding: {muscles}")
                matched = True
                break
        if matched:
            continue

        # 4. Free text we can't map -> skip (fail-open; no muscle avoidance).
        logger.warning(f"⚠️ [Injury Mapping] Unmapped limitation: {injury!r}, no muscle avoidance applied")

    result = list(muscles_to_avoid)
    logger.info(f"✅ [Injury Mapping] Total muscles to avoid: {result}")
    return result


def adjust_workout_params_for_readiness(
    workout_params: dict,
    readiness_score: Optional[int],
    mood: Optional[str] = None,
) -> dict:
    """Adjust workout parameters based on user's readiness score and mood."""
    if not workout_params:
        workout_params = {}

    adjusted = dict(workout_params)
    adjustments_made = []

    base_sets = adjusted.get("sets", 3)
    base_reps = adjusted.get("reps", 10)
    base_rest = adjusted.get("rest_seconds", 60)

    if isinstance(base_reps, str):
        try:
            if "-" in base_reps:
                low, high = base_reps.split("-")
                base_reps = (int(low) + int(high)) // 2
            else:
                base_reps = int(base_reps)
        except ValueError:
            base_reps = 10

    if readiness_score is not None:
        if readiness_score < 50:
            adjusted["sets"] = max(2, int(base_sets * 0.8))
            adjusted["reps"] = max(6, int(base_reps * 0.8))
            adjusted["rest_seconds"] = int(base_rest * 1.3)
            adjusted["readiness_adjustment"] = "low_readiness"
            adjustments_made.append(f"Low readiness ({readiness_score}): reduced sets/reps 20%, increased rest 30%")
        elif readiness_score > 70:
            adjusted["sets"] = min(5, int(base_sets * 1.1))
            adjusted["reps"] = min(15, int(base_reps * 1.1))
            adjusted["rest_seconds"] = max(45, int(base_rest * 0.9))
            adjusted["readiness_adjustment"] = "high_readiness"
            adjustments_made.append(f"High readiness ({readiness_score}): increased sets/reps 10%, reduced rest 10%")
        else:
            adjusted["sets"] = base_sets
            adjusted["reps"] = base_reps
            adjusted["rest_seconds"] = base_rest
            adjusted["readiness_adjustment"] = "normal"

    if mood:
        mood_lower = mood.lower()

        if mood_lower in ["tired", "stressed", "anxious"]:
            current_sets = adjusted.get("sets", base_sets)
            current_reps = adjusted.get("reps", base_reps)
            current_rest = adjusted.get("rest_seconds", base_rest)

            adjusted["sets"] = max(2, int(current_sets * 0.9))
            adjusted["reps"] = max(5, int(current_reps * 0.9))
            adjusted["rest_seconds"] = int(current_rest * 1.2)
            adjusted["mood_adjustment"] = mood_lower
            adjustments_made.append(f"Mood ({mood_lower}): further reduced intensity")

            adjusted["suggest_workout_type"] = "recovery"

        elif mood_lower == "great":
            adjusted["mood_adjustment"] = "great"

    if adjustments_made:
        logger.info(f"🎯 [Workout Params] Adjustments: {', '.join(adjustments_made)}")
        logger.info(f"🎯 [Workout Params] Final: sets={adjusted.get('sets')}, reps={adjusted.get('reps')}, rest={adjusted.get('rest_seconds')}s")

    return adjusted


async def get_active_injuries_with_muscles(user_id: str) -> dict:
    """Get user's active injuries AND automatically map them to avoided muscles."""
    try:
        db = get_supabase_db()

        injuries_result = db.client.table("user_injuries") \
            .select("body_part, severity, status") \
            .eq("user_id", user_id) \
            .eq("status", "active") \
            .execute()

        active_injuries = []
        if injuries_result.data:
            for injury in injuries_result.data:
                body_part = injury.get("body_part", "")
                if body_part:
                    active_injuries.append(body_part)

        user = db.get_user(user_id)
        if user:
            user_injuries = user.get("active_injuries", [])
            if isinstance(user_injuries, str):
                try:
                    user_injuries = json.loads(user_injuries)
                except json.JSONDecodeError:
                    user_injuries = []

            for inj in user_injuries:
                if isinstance(inj, dict):
                    body_part = inj.get("body_part", "")
                elif isinstance(inj, str):
                    body_part = inj
                else:
                    body_part = ""

                if body_part and body_part not in active_injuries:
                    active_injuries.append(body_part)

        avoided_muscles = get_muscles_to_avoid_from_injuries(active_injuries)

        result = {
            "injuries": active_injuries,
            "avoided_muscles": avoided_muscles,
        }

        if active_injuries:
            logger.info(f"✅ [Injuries] User {user_id}: {len(active_injuries)} active injuries -> {len(avoided_muscles)} muscles to avoid")
            logger.info(f"   Injuries: {active_injuries}")
            logger.info(f"   Avoided muscles: {avoided_muscles}")

        return result

    except Exception as e:
        logger.error(f"❌ [Injuries] Error getting active injuries for user {user_id}: {e}", exc_info=True)
        return {"injuries": [], "avoided_muscles": []}


async def get_user_comeback_status(user_id: str) -> dict:
    """Check if user is in comeback mode (returning from a break)."""
    try:
        db = get_supabase_db()

        user = db.get_user(user_id)
        if not user:
            return {"in_comeback_mode": False, "days_since_last_workout": None, "reason": "User not found"}

        created_at = user.get("created_at")
        if created_at:
            try:
                if isinstance(created_at, str):
                    created = datetime.fromisoformat(created_at.replace("Z", "+00:00"))
                else:
                    created = created_at
                account_age_days = (datetime.now(created.tzinfo) - created).days
                if account_age_days < 14:
                    return {
                        "in_comeback_mode": False,
                        "days_since_last_workout": None,
                        "reason": f"Account only {account_age_days} days old (< 14 day threshold)"
                    }
            except Exception as e:
                logger.debug(f"Failed to parse account age: {e}")

        preferences = user.get("preferences", {})
        if isinstance(preferences, str):
            try:
                preferences = json.loads(preferences)
            except json.JSONDecodeError:
                preferences = {}

        if preferences.get("comeback_mode", False):
            return {
                "in_comeback_mode": True,
                "days_since_last_workout": None,
                "reason": "User marked as in comeback mode"
            }

        cutoff_date = (datetime.now() - timedelta(days=14)).isoformat()

        result = db.client.table("workouts") \
            .select("scheduled_date, is_completed") \
            .eq("user_id", user_id) \
            .eq("is_completed", True) \
            .order("scheduled_date", desc=True) \
            .limit(1) \
            .execute()

        if not result.data:
            return {
                "in_comeback_mode": False,
                "days_since_last_workout": None,
                "reason": "No workout history found"
            }

        last_workout_date = result.data[0].get("scheduled_date")
        if last_workout_date:
            try:
                last_date = datetime.fromisoformat(last_workout_date.replace("Z", "+00:00"))
                days_since = (datetime.now(last_date.tzinfo) - last_date).days

                if days_since >= 14:
                    logger.info(f"🔄 [Comeback] User {user_id} is in comeback mode: {days_since} days since last workout")
                    return {
                        "in_comeback_mode": True,
                        "days_since_last_workout": days_since,
                        "reason": f"No workouts in {days_since} days (14+ day break)"
                    }
                else:
                    return {
                        "in_comeback_mode": False,
                        "days_since_last_workout": days_since,
                        "reason": f"Last workout {days_since} days ago (< 14 day threshold)"
                    }
            except Exception as e:
                logger.warning(f"Failed to check workout history: {e}", exc_info=True)

        return {
            "in_comeback_mode": False,
            "days_since_last_workout": None,
            "reason": "Could not determine workout history"
        }

    except Exception as e:
        logger.error(f"❌ [Comeback] Error checking comeback status for user {user_id}: {e}", exc_info=True)
        return {"in_comeback_mode": False, "days_since_last_workout": None, "reason": str(e)}


async def get_comeback_context(user_id: str) -> dict:
    """Get complete comeback context for workout generation."""
    try:
        from services.comeback_service import get_comeback_service

        comeback_service = get_comeback_service()
        break_status = await comeback_service.detect_break_status(user_id)

        needs_comeback = break_status.break_type.value != "active"

        if not needs_comeback:
            return {
                "needs_comeback": False,
                "break_status": None,
                "adjustments": None,
                "prompt_context": "",
                "extra_warmup_minutes": 0,
            }

        logger.info(
            f"🔄 [Comeback] User {user_id} returning after {break_status.days_since_last_workout} days "
            f"({break_status.break_type.value})"
        )

        if break_status.user_age and break_status.user_age >= 60:
            logger.info(f"👴 [Comeback] Senior user (age {break_status.user_age}) - applying additional adjustments")

        return {
            "needs_comeback": True,
            "break_status": {
                "days_off": break_status.days_since_last_workout,
                "break_type": break_status.break_type.value,
                "comeback_week": break_status.comeback_week,
                "in_comeback_mode": break_status.in_comeback_mode,
                "recommended_weeks": break_status.recommended_comeback_weeks,
                "user_age": break_status.user_age,
            },
            "adjustments": {
                "volume_multiplier": break_status.adjustments.volume_multiplier,
                "intensity_multiplier": break_status.adjustments.intensity_multiplier,
                "extra_rest_seconds": break_status.adjustments.extra_rest_seconds,
                "extra_warmup_minutes": break_status.adjustments.extra_warmup_minutes,
                "max_exercise_count": break_status.adjustments.max_exercise_count,
                "avoid_movements": break_status.adjustments.avoid_movements,
                "focus_areas": break_status.adjustments.focus_areas,
            },
            "prompt_context": break_status.prompt_context,
            "extra_warmup_minutes": break_status.adjustments.extra_warmup_minutes,
        }

    except Exception as e:
        logger.error(f"❌ [Comeback] Error getting comeback context: {e}", exc_info=True)
        return {
            "needs_comeback": False,
            "break_status": None,
            "adjustments": None,
            "prompt_context": "",
            "extra_warmup_minutes": 0,
        }


async def apply_comeback_adjustments_to_exercises(
    exercises: List[dict],
    comeback_context: dict,
) -> List[dict]:
    """Apply comeback adjustments to a list of exercises."""
    if not comeback_context.get("needs_comeback") or not exercises:
        return exercises

    adjustments = comeback_context.get("adjustments", {})
    if not adjustments:
        return exercises

    volume_mult = adjustments.get("volume_multiplier", 1.0)
    intensity_mult = adjustments.get("intensity_multiplier", 1.0)
    extra_rest = adjustments.get("extra_rest_seconds", 0)
    max_exercises = adjustments.get("max_exercise_count", 8)

    exercises = exercises[:max_exercises]

    modified = []
    for ex in exercises:
        mod_ex = dict(ex)

        if "sets" in mod_ex:
            original_sets = mod_ex["sets"]
            mod_ex["sets"] = max(2, int(original_sets * volume_mult))

        if "reps" in mod_ex:
            original_reps = mod_ex["reps"]
            if isinstance(original_reps, int):
                mod_ex["reps"] = max(6, int(original_reps * (volume_mult + 0.1)))

        if "weight_kg" in mod_ex and mod_ex["weight_kg"]:
            original_weight = float(mod_ex["weight_kg"])
            new_weight = original_weight * intensity_mult
            mod_ex["weight_kg"] = round(new_weight / 2.5) * 2.5

        rest = mod_ex.get("rest_seconds", 60)
        mod_ex["rest_seconds"] = rest + extra_rest

        break_info = comeback_context.get("break_status", {})
        if break_info:
            days_off = break_info.get("days_off", 0)
            comeback_note = f"[COMEBACK: {days_off} days off] Reduced intensity for safe return."
            existing_notes = mod_ex.get("notes", "")
            mod_ex["notes"] = f"{comeback_note} {existing_notes}".strip()

        modified.append(mod_ex)

    logger.info(
        f"✅ [Comeback] Applied adjustments: volume x{volume_mult:.2f}, "
        f"intensity x{intensity_mult:.2f}, +{extra_rest}s rest, "
        f"{len(modified)}/{max_exercises} exercises"
    )

    return modified


async def start_comeback_mode_if_needed(user_id: str) -> bool:
    """Start comeback mode for user if they need it."""
    try:
        from services.comeback_service import get_comeback_service

        comeback_service = get_comeback_service()

        if await comeback_service.should_trigger_comeback(user_id):
            history_id = await comeback_service.start_comeback_mode(user_id)
            if history_id:
                logger.info(f"🔄 [Comeback] Started comeback mode for user {user_id}")
                return True

        return False

    except Exception as e:
        logger.error(f"❌ [Comeback] Error starting comeback mode: {e}", exc_info=True)
        return False


def get_comeback_prompt_context(
    days_off: int,
    user_age: Optional[int] = None,
    volume_reduction_pct: float = 0,
    intensity_reduction_pct: float = 0,
) -> str:
    """Generate a context string for Gemini prompt about comeback workout."""
    if days_off < 7:
        return ""

    context_parts = [
        "",
        "## Comeback/Return-to-Training Context",
        f"- User is returning after {days_off} days off"
    ]

    if volume_reduction_pct > 0:
        context_parts.append(f"- Apply {int(volume_reduction_pct)}% volume reduction (fewer sets/reps)")

    if intensity_reduction_pct > 0:
        context_parts.append(f"- Apply {int(intensity_reduction_pct)}% intensity reduction (lighter weights)")

    context_parts.extend([
        "- Focus on: reactivation, joint mobility, proper form",
        "- Avoid: heavy loads, high rep counts, explosive movements",
        "- Include: extra warm-up time, mobility work, longer rest periods"
    ])

    if user_age:
        if user_age >= 70:
            context_parts.extend([
                "",
                "## SENIOR RETURN-TO-TRAINING (Age 70+):",
                "- CRITICAL: Extra caution required for safe return",
                "- Prioritize: controlled movements, balance work, joint health",
                "- Avoid: jumping, explosive movements, rapid changes of direction",
                "- Include: extended warmup (10+ minutes), balance exercises",
                "- Maximum 4 exercises per session",
                "- Minimum 90 seconds rest between sets",
                "- Focus on quality of movement over intensity"
            ])
        elif user_age >= 60:
            context_parts.extend([
                "",
                "## OLDER ADULT PROTOCOL (Age 60+):",
                "- Include balance and stability exercises",
                "- Avoid high-impact movements",
                "- Extended warmup recommended (7-10 minutes)",
                "- Focus on joint-friendly exercises"
            ])
        elif user_age >= 50:
            context_parts.extend([
                "",
                "## MIDDLE-AGED PROTOCOL (Age 50+):",
                "- Emphasize proper warmup and cooldown",
                "- Prioritize joint-friendly exercise variations",
                "- Allow for longer recovery between intense movements"
            ])

    return "\n".join(context_parts)


# =============================================================================
# Recovery-aware workout generation (Phase B3)
# =============================================================================
#
# Turns the objective wearable recovery score (Phase B1's
# `get_health_activity_snapshot` → `recovery.score`, mapped to a tier by
# `map_recovery_to_tier`) into a concrete, DETERMINISTIC workout adjustment.
#
# Hard rules (per the approved plan + CLAUDE.md):
#   * The recovery → volume scaling is deterministic — never an LLM. The LLM
#     only receives a short prompt block as informational context; the actual
#     set/weight/rest scaling is applied by `apply_recovery_adjustment` here.
#   * It NEVER rejects, blocks, or guilts the user. A low-recovery day still
#     produces a real workout — a gentler one.
#   * No-data / stale (>36h) recovery → `{"applies": False}` so generation is
#     byte-identical to a pre-Phase-B3 run.
#   * Composes ONCE, ordered after the comeback / age multipliers (it runs in
#     the post-generation block, right after `validate_and_cap_exercise_parameters`).

# A recovery snapshot older than this many hours does NOT drive adaptation
# (edge case D21). `get_health_activity_snapshot` already nulls `recovery.score`
# for stale sleep; this is a belt-and-braces guard on the staleness block.
_RECOVERY_STALENESS_HOURS = 36

# Set types stripped from the workout on a compromised / low recovery day.
# These deliberately push the user past technical failure — inappropriate when
# the body has not recovered (the tier `adjustment` text says "no failure/drop/
# AMRAP sets"). Stripping is deterministic: any truthy flag clears.
_FATIGUE_SET_FLAGS = ("is_failure_set", "is_drop_set", "is_amrap_set")

# Tiers for which fatigue-pushing set types are stripped.
_STRIP_FATIGUE_SET_TIERS = {"compromised", "low"}

# Tier whose workout is swapped toward mobility/recovery work.
_MOBILITY_SWAP_TIER = "low"

# Weight / load reduction per tier (fraction removed from weight_kg). Mirrors
# the tier `adjustment` text: compromised "-10% load", low "-15% load".
_TIER_LOAD_REDUCTION = {
    "moderate": 0.0,
    "compromised": 0.10,
    "low": 0.15,
}

# Rest-period multiplier per tier — a lower-recovery day gets longer rest so
# the trimmed volume is still executed with good form. Mirrors the tier text
# ("longer rest"). Only tiers below `good` extend rest.
_TIER_REST_MULTIPLIER = {
    "moderate": 1.20,
    "compromised": 1.30,
    "low": 1.40,
}


async def get_recovery_workout_signal(user_id: str) -> Dict[str, Any]:
    """Resolve the user's recovery state into a workout-generation signal.

    Reads the Phase B1 health/activity snapshot, maps its objective recovery
    score onto a training tier, and packages everything the two generation
    endpoints need: a short LLM prompt block plus the deterministic
    `adjustment` payload consumed by `apply_recovery_adjustment`.

    Args:
        user_id: User's UUID.

    Returns:
        ``{"applies": False}`` when there is no usable recovery signal — no
        wearable / no consent / sleep can't be scored / data is stale (>36h),
        or the resolved tier needs no change (optimal / good). In this case
        workout generation must behave byte-identically to a pre-Phase-B3 run.

        Otherwise ``{"applies": True, "tier": str, "recovery_score": int,
        "volume_multiplier": float, "adjustment": <dict>, "prompt_context":
        <str>}`` where ``adjustment`` is the dict passed straight to
        ``apply_recovery_adjustment`` and ``prompt_context`` is an
        informational block to append to the generation prompt.
    """
    try:
        # Import here (not at module load) to avoid a circular import:
        # user_context.service imports from the workouts package.
        from services.user_context.health_activity import HealthActivityMixin

        snapshot = await HealthActivityMixin().get_health_activity_snapshot(
            user_id, days=7
        )
    except Exception as e:
        # Any failure → no adaptation. Recovery awareness is additive; it must
        # never break or degrade generation (CLAUDE.md: no silent bad data, but
        # a missing signal is a normal state, not an error to surface).
        logger.error(
            f"❌ [Recovery] get_recovery_workout_signal failed for {user_id}: {e}",
            exc_info=True,
        )
        return {"applies": False}

    if not snapshot.get("has_data"):
        # No wearable / no consent — a normal state for non-wearable users.
        return {"applies": False}

    # --- staleness guard (edge case D21) -------------------------------------
    # `get_health_activity_snapshot` already nulls recovery.score for stale
    # sleep, but re-check the sleep row's own staleness flag explicitly so a
    # future snapshot change can't silently re-enable adaptation on old data.
    sleep = snapshot.get("last_night_sleep") or {}
    if sleep.get("is_stale"):
        logger.info(
            f"🔍 [Recovery] User {user_id} sleep data is stale "
            f"(>{_RECOVERY_STALENESS_HOURS}h) — no recovery adaptation"
        )
        return {"applies": False}

    recovery = snapshot.get("recovery") or {}
    recovery_score = recovery.get("score")
    if recovery_score is None:
        # Sleep present but unscoreable (partial data) — no adaptation.
        return {"applies": False}

    tier_info = map_recovery_to_tier(recovery_score)
    if not tier_info:
        return {"applies": False}

    tier = tier_info["tier"]
    volume_multiplier = tier_info["volume_multiplier"]

    # optimal / good both carry volume_multiplier 1.0 and "as planned" — there
    # is nothing to change, so signal "no adaptation" and keep generation
    # byte-identical to a pre-Phase-B3 run.
    if tier in ("optimal", "good") or volume_multiplier >= 1.0:
        logger.info(
            f"✅ [Recovery] User {user_id} recovery {recovery_score}/100 "
            f"({tier}) — train as planned, no adaptation"
        )
        return {"applies": False}

    adjustment = {
        "tier": tier,
        "recovery_score": recovery_score,
        "volume_multiplier": volume_multiplier,
        "load_reduction": _TIER_LOAD_REDUCTION.get(tier, 0.0),
        "rest_multiplier": _TIER_REST_MULTIPLIER.get(tier, 1.0),
        "strip_fatigue_sets": tier in _STRIP_FATIGUE_SET_TIERS,
        "swap_to_mobility": tier == _MOBILITY_SWAP_TIER,
        "adjustment_text": tier_info["adjustment"],
    }

    prompt_context = _build_recovery_prompt_context(adjustment)

    logger.info(
        f"🛌 [Recovery] User {user_id} recovery {recovery_score}/100 ({tier}) — "
        f"applying x{volume_multiplier:.2f} volume, "
        f"-{int(adjustment['load_reduction'] * 100)}% load, "
        f"strip_fatigue_sets={adjustment['strip_fatigue_sets']}, "
        f"swap_to_mobility={adjustment['swap_to_mobility']}"
    )

    return {
        "applies": True,
        "tier": tier,
        "recovery_score": recovery_score,
        "volume_multiplier": volume_multiplier,
        "adjustment": adjustment,
        "prompt_context": prompt_context,
    }


def _build_recovery_prompt_context(adjustment: Dict[str, Any]) -> str:
    """Build a short, informational recovery block for the generation prompt.

    The LLM uses this only as context for naming / framing — the actual
    set/weight/rest scaling is applied deterministically by
    `apply_recovery_adjustment` after generation. The block never instructs
    the model to reject the workout; it asks for a gentler session.
    """
    tier = adjustment["tier"]
    score = adjustment["recovery_score"]
    parts = [
        "",
        "## RECOVERY-AWARE ADJUSTMENT",
        f"- User's objective recovery score is {score}/100 ({tier}) based on "
        f"last night's tracked sleep.",
        f"- Plan a GENTLER session today: {adjustment['adjustment_text']}.",
        "- Keep it a real, productive workout — do not skip or cancel it.",
        "- Favor controlled tempo and solid technique over intensity.",
    ]
    if adjustment["strip_fatigue_sets"]:
        parts.append(
            "- Avoid training-to-failure, drop sets, and AMRAP finishers today."
        )
    if adjustment["swap_to_mobility"]:
        parts.append(
            "- Lean toward mobility, light recovery, and joint-friendly movements."
        )
    return "\n".join(parts)


def _scale_int(value: Any, multiplier: float, minimum: int) -> Optional[int]:
    """Scale a numeric set/rep field by `multiplier`, flooring at `minimum`.

    Returns None when the input is not a usable number, so a missing field is
    left untouched rather than fabricated."""
    num = _coerce_number(value)
    if num is None:
        return None
    return max(minimum, int(round(num * multiplier)))


def _coerce_number(value: Any) -> Optional[float]:
    """Best-effort numeric coercion. Handles ints, floats, numeric strings, and
    rep ranges like "8-12" (uses the range midpoint). Returns None otherwise."""
    if value is None:
        return None
    if isinstance(value, (int, float)):
        return float(value)
    if isinstance(value, str):
        s = value.strip()
        if not s:
            return None
        if "-" in s:
            try:
                low, high = s.split("-", 1)
                return (float(low) + float(high)) / 2.0
            except (ValueError, TypeError):
                return None
        try:
            return float(s)
        except (ValueError, TypeError):
            return None
    return None


def apply_recovery_adjustment(
    exercises: List[dict],
    adjustment: Optional[Dict[str, Any]],
) -> List[dict]:
    """Deterministically scale a generated workout for the user's recovery tier.

    This is the load-affecting half of Phase B3 — it is intentionally pure
    Python with NO LLM involvement. It runs in the post-generation block,
    AFTER `validate_and_cap_exercise_parameters`, so it composes once on top of
    the comeback / age caps rather than fighting them.

    For the resolved tier it:
      * scales each exercise's ``sets`` by ``volume_multiplier`` (floor 1 set),
      * reduces ``weight_kg`` by ``load_reduction`` (rounded to 2.5 kg),
      * extends ``rest_seconds`` by ``rest_multiplier``,
      * strips failure / drop / AMRAP set flags for the compromised + low tiers
        (and removes the now-misleading drop-set parameters),
      * tags every exercise ``recovery_adjusted: True`` with the tier + score so
        the client / analytics can surface the adaptation,
      * for the LOW tier only, marks the workout as a mobility/recovery swap via
        ``recovery_mobility_swap`` and lengthens rest further — the actual
        exercise pool was already biased toward mobility by the prompt block.

    Args:
        exercises: The generated exercise list (post validate-and-cap).
        adjustment: The ``adjustment`` dict from ``get_recovery_workout_signal``;
            ``None`` (or an empty list of exercises) is a no-op — the list is
            returned unchanged so a no-data run is byte-identical.

    Returns:
        The adjusted exercise list (a new list of shallow-copied dicts) when an
        adjustment applies, otherwise the original list unchanged.
    """
    if not adjustment or not exercises:
        return exercises

    volume_multiplier = float(adjustment.get("volume_multiplier", 1.0))
    load_reduction = float(adjustment.get("load_reduction", 0.0))
    rest_multiplier = float(adjustment.get("rest_multiplier", 1.0))
    strip_fatigue_sets = bool(adjustment.get("strip_fatigue_sets", False))
    swap_to_mobility = bool(adjustment.get("swap_to_mobility", False))
    tier = adjustment.get("tier", "moderate")
    recovery_score = adjustment.get("recovery_score")

    # Nothing to do — guards against a malformed "applies" adjustment.
    if (
        volume_multiplier >= 1.0
        and load_reduction <= 0.0
        and rest_multiplier <= 1.0
        and not strip_fatigue_sets
    ):
        return exercises

    adjusted: List[dict] = []
    sets_scaled = 0
    weights_scaled = 0
    fatigue_sets_stripped = 0

    for ex in exercises:
        mod = dict(ex)  # shallow copy — never mutate the caller's dicts

        # --- sets: scale by volume multiplier, floor at 1 -------------------
        if "sets" in mod:
            new_sets = _scale_int(mod.get("sets"), volume_multiplier, minimum=1)
            if new_sets is not None and new_sets != _coerce_number(ex.get("sets")):
                mod["sets"] = new_sets
                sets_scaled += 1

        # --- weight: reduce load (rounded to a 2.5 kg plate increment) ------
        if load_reduction > 0.0 and mod.get("weight_kg"):
            base_weight = _coerce_number(mod.get("weight_kg"))
            if base_weight is not None and base_weight > 0:
                reduced = base_weight * (1.0 - load_reduction)
                # Round to the nearest 2.5 kg, mirroring the comeback path.
                rounded = round(reduced / 2.5) * 2.5
                # Never round a real working weight down to 0.
                mod["weight_kg"] = rounded if rounded > 0 else round(reduced, 1)
                weights_scaled += 1

        # --- rest: extend recovery between sets -----------------------------
        if rest_multiplier > 1.0:
            base_rest = _coerce_number(mod.get("rest_seconds"))
            if base_rest is None:
                base_rest = 60.0  # same default the readiness path uses
            mod["rest_seconds"] = int(round(base_rest * rest_multiplier))

        # --- strip fatigue-pushing set types (compromised / low) ------------
        if strip_fatigue_sets:
            stripped_here = False
            for flag in _FATIGUE_SET_FLAGS:
                if mod.get(flag):
                    mod[flag] = False
                    stripped_here = True
            # Drop-set parameters are meaningless once is_drop_set is cleared.
            if stripped_here:
                for drop_param in ("drop_set_count", "drop_set_percentage"):
                    mod.pop(drop_param, None)
                fatigue_sets_stripped += 1

        # --- recovery tag ---------------------------------------------------
        mod["recovery_adjusted"] = True
        mod["recovery_tier"] = tier
        if recovery_score is not None:
            mod["recovery_score"] = recovery_score
        if swap_to_mobility:
            mod["recovery_mobility_swap"] = True

        adjusted.append(mod)

    logger.info(
        f"🛌 [Recovery] Applied recovery adjustment (tier={tier}, "
        f"score={recovery_score}): scaled sets on {sets_scaled} exercise(s), "
        f"reduced load on {weights_scaled}, stripped fatigue sets on "
        f"{fatigue_sets_stripped}, swap_to_mobility={swap_to_mobility}"
    )

    return adjusted
