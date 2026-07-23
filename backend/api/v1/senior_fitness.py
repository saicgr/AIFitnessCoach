"""
Senior Fitness API - Age-appropriate workout modifications and recovery settings.

This module manages fitness settings for older adults (55+):
- Age-based recovery multipliers and scaling
- Low-impact exercise alternatives
- Senior-specific mobility and balance exercises
- Workout modification for joint protection
- Recovery tracking for seniors

Database tables:
- senior_recovery_settings: User recovery preferences
- low_impact_alternatives: Exercise alternatives for seniors
- senior_mobility_exercises: Recommended mobility work
- senior_workout_log: Logged senior-specific workouts

ENDPOINTS:
- GET  /api/v1/senior-fitness/{user_id}/settings - Get senior fitness settings
- PUT  /api/v1/senior-fitness/{user_id}/settings - Update senior fitness settings
- GET  /api/v1/senior-fitness/{user_id}/recovery-status - Get recovery recommendations
- POST /api/v1/senior-fitness/apply-workout-modifications - Apply senior mods to workout
- GET  /api/v1/senior-fitness/{user_id}/is-senior - Check if user qualifies as senior
- GET  /api/v1/senior-fitness/mobility-exercises - Get mobility exercise library
- GET  /api/v1/senior-fitness/balance-exercises - Get balance exercise library
- GET  /api/v1/senior-fitness/low-impact-alternative/{exercise_name} - Get alternative
- GET  /api/v1/senior-fitness/{user_id}/prompt-context - Get AI context for seniors
"""

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime, date, timedelta
import logging

from core.supabase_client import get_supabase
from core.logger import get_logger
from core.timezone_utils import resolve_timezone, get_user_today

router = APIRouter()
logger = get_logger(__name__)


# =============================================================================
# Pydantic Models
# =============================================================================

class SeniorFitnessSettings(BaseModel):
    """Senior fitness settings for a user."""
    user_id: str
    is_senior: bool = False
    age: Optional[int] = None
    age_bracket: Optional[str] = None  # "60-64", "65-69", "70-74", "75+"

    # Recovery settings
    recovery_multiplier: float = Field(default=1.0, ge=1.0, le=3.0)
    rest_between_sets_multiplier: float = Field(default=1.0, ge=1.0, le=2.0)
    min_rest_days_between_workouts: int = Field(default=1, ge=0, le=4)

    # Intensity settings
    max_intensity_percent: int = Field(default=100, ge=50, le=100)
    prefer_low_impact: bool = False
    avoid_high_impact: bool = False
    prefer_seated_exercises: bool = False

    # Safety settings
    include_warmup_extension: bool = True
    warmup_extension_minutes: int = Field(default=5, ge=0, le=15)
    include_cooldown_extension: bool = True
    cooldown_extension_minutes: int = Field(default=5, ge=0, le=15)
    include_balance_work: bool = True

    # Joint protection
    joint_protection_mode: bool = False
    protected_joints: List[str] = Field(default_factory=list)

    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class SeniorSettingsUpdate(BaseModel):
    """Request to update senior fitness settings."""
    recovery_multiplier: Optional[float] = Field(default=None, ge=1.0, le=3.0)
    rest_between_sets_multiplier: Optional[float] = Field(default=None, ge=1.0, le=2.0)
    min_rest_days_between_workouts: Optional[int] = Field(default=None, ge=0, le=4)
    max_intensity_percent: Optional[int] = Field(default=None, ge=50, le=100)
    prefer_low_impact: Optional[bool] = None
    avoid_high_impact: Optional[bool] = None
    prefer_seated_exercises: Optional[bool] = None
    include_warmup_extension: Optional[bool] = None
    warmup_extension_minutes: Optional[int] = Field(default=None, ge=0, le=15)
    include_cooldown_extension: Optional[bool] = None
    cooldown_extension_minutes: Optional[int] = Field(default=None, ge=0, le=15)
    include_balance_work: Optional[bool] = None
    joint_protection_mode: Optional[bool] = None
    protected_joints: Optional[List[str]] = None


class RecoveryStatus(BaseModel):
    """Recovery status and recommendations for a senior user."""
    user_id: str
    last_workout_date: Optional[date] = None
    days_since_last_workout: int = 0
    recommended_rest_days: int = 1
    is_recovered: bool = True
    recovery_percentage: float = 100.0
    recommendations: List[str] = []
    can_do_full_workout: bool = True
    suggested_intensity: str = "normal"  # "light", "normal", "moderate"


class MobilityExercise(BaseModel):
    """A mobility exercise for seniors."""
    id: str
    name: str
    description: str
    target_areas: List[str]
    duration_seconds: int
    difficulty: str  # "easy", "moderate"
    video_url: Optional[str] = None
    instructions: List[str] = []
    benefits: List[str] = []


class BalanceExercise(BaseModel):
    """A balance exercise for seniors."""
    id: str
    name: str
    description: str
    difficulty: str  # "beginner", "intermediate"
    duration_seconds: int
    requires_support: bool = False
    video_url: Optional[str] = None
    instructions: List[str] = []
    safety_notes: List[str] = []


class LowImpactAlternative(BaseModel):
    """A low-impact alternative to a high-impact exercise."""
    original_exercise: str
    alternative_exercise: str
    reason: str
    muscle_groups: List[str]
    intensity_modifier: float = 1.0
    notes: Optional[str] = None


class WorkoutModificationRequest(BaseModel):
    """Request to apply senior modifications to a workout."""
    user_id: str
    workout_exercises: List[Dict[str, Any]]


class WorkoutModificationResponse(BaseModel):
    """Response with modified workout for seniors."""
    user_id: str
    modifications_applied: List[str]
    modified_exercises: List[Dict[str, Any]]
    warmup_added_minutes: int = 0
    cooldown_added_minutes: int = 0
    total_rest_increase_percent: int = 0


class IsSeniorResponse(BaseModel):
    """Response for checking senior status."""
    user_id: str
    is_senior: bool
    age: Optional[int] = None
    age_bracket: Optional[str] = None
    has_senior_settings: bool = False


class PromptContextResponse(BaseModel):
    """AI prompt context for senior users."""
    user_id: str
    is_senior: bool
    context_text: str
    key_considerations: List[str]


# =============================================================================
# API field -> senior_recovery_settings column mapping
# =============================================================================
# This module's field names drifted from the table migration 113 actually
# created. Eight are pure rename drift (the column exists under another name);
# six had NO column at all until migration 2318 added them.
#
# Why this mattered: PostgREST rejects an ENTIRE write payload when one key is
# not a real column (PGRST204 / 42703), so every PUT /senior-fitness/{id}/settings
# that touched any drifted field silently failed in full — including its valid
# keys — behind the endpoint's try/except. Reads were equally dead: select("*")
# succeeds, but every drifted key came back missing and fell through to the
# Pydantic default, so a senior's saved preferences were never actually applied.
#
# Canonical column names verified against:
#   - backend/scripts/schema_columns_snapshot.json (production information_schema)
#   - migrations/113_senior_recovery_scaling.sql (the CREATE TABLE)
#   - services/senior_workout_service.py, the sibling implementation, whose
#     `allowed_fields` whitelist already uses the real names
#   - tests/test_senior_fitness_api.py `generate_mock_senior_settings()`
#
# Reads AND writes both go through this map, so the two sides cannot drift
# apart again.
SETTINGS_COLUMN_MAP: Dict[str, str] = {
    # --- name drift: the column already existed under a different name -------
    "recovery_multiplier": "recovery_multiplier",
    # The schema models rest days per modality (strength / cardio); this API
    # exposes a single generic knob. The strength floor is the binding
    # constraint — /recovery-status compares it against the last completed
    # workout of ANY type, and the SQL check_senior_recovery_status() reads the
    # same column for strength days. min_rest_days_cardio keeps its own value
    # and is deliberately NOT overwritten by this generic field.
    "min_rest_days_between_workouts": "min_rest_days_strength",
    "max_intensity_percent": "max_intensity_percent",
    "prefer_low_impact": "prefer_low_impact",
    # "high impact" here means jumping/pounding movements (the low-impact
    # alternatives table below is jump/plyo/cardio work) — the same preference
    # migration 113 filed under joint-friendly settings.
    "avoid_high_impact": "avoid_high_impact_cardio",
    "warmup_extension_minutes": "extended_warmup_minutes",
    "cooldown_extension_minutes": "extended_cooldown_minutes",
    "include_balance_work": "include_balance_exercises",
    # --- added by migration 2318 (no column existed for these at all) --------
    "rest_between_sets_multiplier": "rest_between_sets_multiplier",
    "prefer_seated_exercises": "prefer_seated_exercises",
    "include_warmup_extension": "include_warmup_extension",
    "include_cooldown_extension": "include_cooldown_extension",
    "joint_protection_mode": "joint_protection_mode",
    "protected_joints": "protected_joints",
}

# Import-time regression gate: a settings field added to the request model
# without a column mapping would otherwise be dropped on the floor (or, worse,
# poison the whole payload again). Fail loudly at startup instead.
_UNMAPPED_SETTINGS_FIELDS = set(SeniorSettingsUpdate.model_fields) - set(SETTINGS_COLUMN_MAP)
if _UNMAPPED_SETTINGS_FIELDS:  # pragma: no cover - startup guard
    raise RuntimeError(
        "senior_fitness: SeniorSettingsUpdate fields have no senior_recovery_settings "
        f"column mapping: {sorted(_UNMAPPED_SETTINGS_FIELDS)}"
    )


# =============================================================================
# Helper Functions
# =============================================================================

def get_age_bracket(age: int) -> str:
    """Get age bracket string from age."""
    if age < 60:
        return "under_60"
    elif age < 65:
        return "60-64"
    elif age < 70:
        return "65-69"
    elif age < 75:
        return "70-74"
    else:
        return "75+"


def get_default_settings_for_age(age: int) -> Dict[str, Any]:
    """Get default senior settings based on age."""
    if age < 55:
        return {
            "recovery_multiplier": 1.0,
            "rest_between_sets_multiplier": 1.0,
            "min_rest_days_between_workouts": 0,
            "max_intensity_percent": 100,
            "prefer_low_impact": False,
            "avoid_high_impact": False,
        }
    elif age < 65:
        return {
            "recovery_multiplier": 1.2,
            "rest_between_sets_multiplier": 1.1,
            "min_rest_days_between_workouts": 1,
            "max_intensity_percent": 90,
            "prefer_low_impact": False,
            "avoid_high_impact": False,
        }
    elif age < 70:
        return {
            "recovery_multiplier": 1.4,
            "rest_between_sets_multiplier": 1.2,
            "min_rest_days_between_workouts": 1,
            "max_intensity_percent": 85,
            "prefer_low_impact": True,
            "avoid_high_impact": False,
        }
    elif age < 75:
        return {
            "recovery_multiplier": 1.6,
            "rest_between_sets_multiplier": 1.3,
            "min_rest_days_between_workouts": 2,
            "max_intensity_percent": 80,
            "prefer_low_impact": True,
            "avoid_high_impact": True,
        }
    else:  # 75+
        return {
            "recovery_multiplier": 2.0,
            "rest_between_sets_multiplier": 1.5,
            "min_rest_days_between_workouts": 2,
            "max_intensity_percent": 70,
            "prefer_low_impact": True,
            "avoid_high_impact": True,
            "prefer_seated_exercises": True,
        }


def get_mobility_exercise_library() -> List[Dict[str, Any]]:
    """Get default mobility exercises for seniors."""
    return [
        {
            "id": "mob_1",
            "name": "Neck Circles",
            "description": "Gentle neck rotation to improve mobility",
            "target_areas": ["neck", "upper_back"],
            "duration_seconds": 60,
            "difficulty": "easy",
            "instructions": [
                "Sit or stand with good posture",
                "Slowly rotate head in a circle",
                "Complete 5 circles each direction",
            ],
            "benefits": ["Reduces neck stiffness", "Improves range of motion"],
        },
        {
            "id": "mob_2",
            "name": "Shoulder Rolls",
            "description": "Shoulder mobility for upper body flexibility",
            "target_areas": ["shoulders", "upper_back"],
            "duration_seconds": 45,
            "difficulty": "easy",
            "instructions": [
                "Roll shoulders forward 10 times",
                "Roll shoulders backward 10 times",
                "Keep movements slow and controlled",
            ],
            "benefits": ["Reduces shoulder tension", "Improves posture"],
        },
        {
            "id": "mob_3",
            "name": "Ankle Circles",
            "description": "Ankle mobility for better balance",
            "target_areas": ["ankles", "calves"],
            "duration_seconds": 60,
            "difficulty": "easy",
            "instructions": [
                "Lift one foot off the ground",
                "Rotate ankle in circles (10 each way)",
                "Repeat with other foot",
            ],
            "benefits": ["Improves balance", "Reduces fall risk"],
        },
        {
            "id": "mob_4",
            "name": "Hip Circles",
            "description": "Hip mobility for lower body flexibility",
            "target_areas": ["hips", "lower_back"],
            "duration_seconds": 60,
            "difficulty": "moderate",
            "instructions": [
                "Stand with hands on hips",
                "Make large circles with hips",
                "Complete 10 circles each direction",
            ],
            "benefits": ["Improves hip mobility", "Reduces lower back stiffness"],
        },
        {
            "id": "mob_5",
            "name": "Wrist Circles",
            "description": "Wrist mobility for grip strength",
            "target_areas": ["wrists", "forearms"],
            "duration_seconds": 45,
            "difficulty": "easy",
            "instructions": [
                "Extend arms in front",
                "Make circles with wrists",
                "10 circles each direction",
            ],
            "benefits": ["Reduces wrist stiffness", "Improves grip"],
        },
    ]


def get_balance_exercise_library() -> List[Dict[str, Any]]:
    """Get default balance exercises for seniors."""
    return [
        {
            "id": "bal_1",
            "name": "Single Leg Stand",
            "description": "Basic balance exercise with support option",
            "difficulty": "beginner",
            "duration_seconds": 30,
            "requires_support": True,
            "instructions": [
                "Stand near a chair or wall for support",
                "Lift one foot slightly off ground",
                "Hold for 10-30 seconds",
                "Switch legs",
            ],
            "safety_notes": ["Keep support within reach", "Start with short holds"],
        },
        {
            "id": "bal_2",
            "name": "Heel-to-Toe Walk",
            "description": "Walking in a line to improve balance",
            "difficulty": "intermediate",
            "duration_seconds": 60,
            "requires_support": True,
            "instructions": [
                "Walk in a straight line",
                "Place heel directly in front of toe",
                "Take 10-20 steps",
            ],
            "safety_notes": ["Walk near a wall", "Look straight ahead"],
        },
        {
            "id": "bal_3",
            "name": "Weight Shifts",
            "description": "Side-to-side weight transfer",
            "difficulty": "beginner",
            "duration_seconds": 45,
            "requires_support": False,
            "instructions": [
                "Stand with feet hip-width apart",
                "Shift weight to right foot",
                "Hold briefly, then shift to left",
                "Repeat 10 times each side",
            ],
            "safety_notes": ["Keep knees slightly bent", "Move slowly"],
        },
        {
            "id": "bal_4",
            "name": "Chair Stand",
            "description": "Sit-to-stand for functional strength and balance",
            "difficulty": "beginner",
            "duration_seconds": 60,
            "requires_support": False,
            "instructions": [
                "Sit at edge of sturdy chair",
                "Stand up without using arms",
                "Sit back down slowly",
                "Repeat 5-10 times",
            ],
            "safety_notes": ["Use a stable chair", "Go at your own pace"],
        },
    ]


def get_low_impact_alternatives() -> Dict[str, Dict[str, Any]]:
    """Get low-impact alternatives for common exercises."""
    return {
        "running": {
            "alternative": "Walking",
            "reason": "Reduces joint impact while maintaining cardiovascular benefits",
            "muscle_groups": ["legs", "cardio"],
            "intensity_modifier": 0.7,
        },
        "jump_squats": {
            "alternative": "Bodyweight Squats",
            "reason": "Eliminates jumping impact on knees",
            "muscle_groups": ["quads", "glutes"],
            "intensity_modifier": 0.8,
        },
        "burpees": {
            "alternative": "Step-Back Burpees",
            "reason": "Removes jumping component, reduces impact",
            "muscle_groups": ["full_body"],
            "intensity_modifier": 0.75,
        },
        "box_jumps": {
            "alternative": "Step-Ups",
            "reason": "Achieves similar muscle activation without impact",
            "muscle_groups": ["quads", "glutes"],
            "intensity_modifier": 0.7,
        },
        "high_knees": {
            "alternative": "Marching in Place",
            "reason": "Keeps one foot on ground at all times",
            "muscle_groups": ["cardio", "hip_flexors"],
            "intensity_modifier": 0.6,
        },
        "jumping_jacks": {
            "alternative": "Step Jacks",
            "reason": "Steps out instead of jumping",
            "muscle_groups": ["cardio", "shoulders"],
            "intensity_modifier": 0.65,
        },
        "mountain_climbers": {
            "alternative": "Standing Mountain Climbers",
            "reason": "Upright position reduces wrist and shoulder stress",
            "muscle_groups": ["core", "cardio"],
            "intensity_modifier": 0.7,
        },
        "lunges": {
            "alternative": "Reverse Lunges",
            "reason": "Better knee tracking, less impact",
            "muscle_groups": ["quads", "glutes"],
            "intensity_modifier": 0.9,
        },
        "deadlifts": {
            "alternative": "Romanian Deadlifts",
            "reason": "Lighter weight, more controlled movement",
            "muscle_groups": ["hamstrings", "lower_back"],
            "intensity_modifier": 0.85,
        },
    }


# =============================================================================
# API Endpoints
# =============================================================================

@router.get("/{user_id}/settings", response_model=SeniorFitnessSettings)
async def get_senior_settings(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Get senior fitness settings for a user."""
    logger.info(f"Getting senior fitness settings for user {user_id}")

    try:
        supabase = get_supabase()

        # Get user age
        user_result = supabase.client.table("users").select(
            "age, date_of_birth"
        ).eq("id", user_id).execute()

        age = None
        if user_result.data:
            age = user_result.data[0].get("age")
            if not age and user_result.data[0].get("date_of_birth"):
                try:
                    dob = datetime.fromisoformat(
                        str(user_result.data[0].get("date_of_birth")).replace("Z", "+00:00")
                    )
                    age = (datetime.now(dob.tzinfo) - dob).days // 365
                except Exception as e:
                    logger.debug(f"Failed to parse date of birth: {e}")

        is_senior = age is not None and age >= 55
        age_bracket = get_age_bracket(age) if age else None

        # Get senior settings from database
        settings_result = supabase.client.table("senior_recovery_settings").select(
            "*"
        ).eq("user_id", user_id).execute()

        if settings_result.data and len(settings_result.data) > 0:
            settings = settings_result.data[0]
            # Read through SETTINGS_COLUMN_MAP so stored preferences actually
            # reach the response. Only values the row genuinely holds are passed
            # through — the field defaults declared on SeniorFitnessSettings own
            # the "not configured" case, so no default is duplicated here.
            stored = {
                field: settings[column]
                for field, column in SETTINGS_COLUMN_MAP.items()
                if settings.get(column) is not None
            }
            return SeniorFitnessSettings(
                user_id=user_id,
                is_senior=is_senior,
                age=age,
                age_bracket=age_bracket,
                created_at=settings.get("created_at"),
                updated_at=settings.get("updated_at"),
                **stored,
            )
        else:
            # Return defaults based on age
            defaults = get_default_settings_for_age(age or 50)
            return SeniorFitnessSettings(
                user_id=user_id,
                is_senior=is_senior,
                age=age,
                age_bracket=age_bracket,
                **defaults,
            )

    except Exception as e:
        logger.error(f"Failed to get senior settings: {e}", exc_info=True)
        raise safe_internal_error(e, "senior_fitness")


@router.put("/{user_id}/settings", response_model=SeniorFitnessSettings)
async def update_senior_settings(user_id: str, update: SeniorSettingsUpdate,
    current_user: dict = Depends(get_current_user),
):
    """Update senior fitness settings for a user."""
    logger.info(f"Updating senior fitness settings for user {user_id}")

    try:
        supabase = get_supabase()
        now = datetime.utcnow().isoformat()

        # Check if settings exist
        existing = supabase.client.table("senior_recovery_settings").select(
            "id"
        ).eq("user_id", user_id).execute()

        # Build update data. Every key below is a REAL senior_recovery_settings
        # column (see SETTINGS_COLUMN_MAP for the API-field -> column reasoning);
        # writing the API's own names instead made PostgREST reject the whole
        # payload with PGRST204, so nothing was ever persisted.
        #
        # The keys are spelled out literally, rather than mapped in a
        # comprehension, so scripts/audit_supabase_column_drift.py can keep
        # statically extracting this payload — a comprehension is invisible to
        # it, which would silently retire the gate on the exact file that had
        # the worst drift in the tree. The map-completeness assertion below is
        # what keeps the two representations honest.
        update_data: Dict[str, Any] = {}
        if update.recovery_multiplier is not None:
            update_data["recovery_multiplier"] = update.recovery_multiplier
        if update.rest_between_sets_multiplier is not None:
            update_data["rest_between_sets_multiplier"] = update.rest_between_sets_multiplier
        if update.min_rest_days_between_workouts is not None:
            update_data["min_rest_days_strength"] = update.min_rest_days_between_workouts
        if update.max_intensity_percent is not None:
            update_data["max_intensity_percent"] = update.max_intensity_percent
        if update.prefer_low_impact is not None:
            update_data["prefer_low_impact"] = update.prefer_low_impact
        if update.avoid_high_impact is not None:
            update_data["avoid_high_impact_cardio"] = update.avoid_high_impact
        if update.prefer_seated_exercises is not None:
            update_data["prefer_seated_exercises"] = update.prefer_seated_exercises
        if update.include_warmup_extension is not None:
            update_data["include_warmup_extension"] = update.include_warmup_extension
        if update.warmup_extension_minutes is not None:
            update_data["extended_warmup_minutes"] = update.warmup_extension_minutes
        if update.include_cooldown_extension is not None:
            update_data["include_cooldown_extension"] = update.include_cooldown_extension
        if update.cooldown_extension_minutes is not None:
            update_data["extended_cooldown_minutes"] = update.cooldown_extension_minutes
        if update.include_balance_work is not None:
            update_data["include_balance_exercises"] = update.include_balance_work
        if update.joint_protection_mode is not None:
            update_data["joint_protection_mode"] = update.joint_protection_mode
        if update.protected_joints is not None:
            update_data["protected_joints"] = update.protected_joints

        # Nothing the caller set may be dropped on the floor. If a field is
        # added to SeniorSettingsUpdate + SETTINGS_COLUMN_MAP but a write branch
        # above is forgotten, fail loudly here instead of persisting a partial
        # save the user thinks succeeded.
        expected_columns = {
            SETTINGS_COLUMN_MAP[field]
            for field in update.model_dump(exclude_none=True)
        }
        missing_columns = expected_columns - set(update_data)
        if missing_columns:
            raise RuntimeError(
                "senior_fitness: settings update would silently drop column(s) "
                f"{sorted(missing_columns)} — add the write branch above."
            )

        if not update_data:
            raise HTTPException(status_code=400, detail="No fields to update")

        update_data["updated_at"] = now

        if existing.data and len(existing.data) > 0:
            supabase.client.table("senior_recovery_settings").update(
                update_data
            ).eq("user_id", user_id).execute()
        else:
            update_data["user_id"] = user_id
            update_data["created_at"] = now
            supabase.client.table("senior_recovery_settings").insert(
                update_data
            ).execute()

        return await get_senior_settings(user_id)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update senior settings: {e}", exc_info=True)
        raise safe_internal_error(e, "senior_fitness")


@router.get("/{user_id}/recovery-status", response_model=RecoveryStatus)
async def get_recovery_status(user_id: str, request: Request,
    current_user: dict = Depends(get_current_user),
):
    """Get recovery status and recommendations for a senior user."""
    logger.info(f"Getting recovery status for user {user_id}")

    try:
        supabase = get_supabase()

        # Get senior settings
        settings = await get_senior_settings(user_id)

        # Resolve user timezone for date logic
        user_tz = resolve_timezone(request, None, user_id)
        today_date = date.fromisoformat(get_user_today(user_tz))

        # Get last workout date
        workout_result = supabase.client.table("workouts").select(
            "completed_at"
        ).eq("user_id", user_id).eq(
            "status", "completed"
        ).order("completed_at", desc=True).limit(1).execute()

        last_workout_date = None
        days_since = 0

        if workout_result.data:
            completed_at = workout_result.data[0].get("completed_at")
            if completed_at:
                last_workout_date = datetime.fromisoformat(
                    completed_at.replace("Z", "+00:00")
                ).date()
                days_since = (today_date - last_workout_date).days

        recommended_rest = settings.min_rest_days_between_workouts
        is_recovered = days_since >= recommended_rest
        recovery_pct = min(100.0, (days_since / max(1, recommended_rest)) * 100)

        recommendations = []
        can_full_workout = True
        suggested_intensity = "normal"

        if not is_recovered:
            recommendations.append(f"Consider waiting {recommended_rest - days_since} more day(s) for full recovery")
            can_full_workout = False
            suggested_intensity = "light"
        elif days_since == recommended_rest:
            recommendations.append("You're ready for your next workout!")
        elif days_since > recommended_rest + 2:
            recommendations.append("Great to get back to training - consider a moderate start")
            suggested_intensity = "moderate"

        if settings.is_senior:
            recommendations.append("Remember to include extra warm-up time")
            if settings.include_balance_work:
                recommendations.append("Include balance exercises in your routine")

        return RecoveryStatus(
            user_id=user_id,
            last_workout_date=last_workout_date,
            days_since_last_workout=days_since,
            recommended_rest_days=recommended_rest,
            is_recovered=is_recovered,
            recovery_percentage=recovery_pct,
            recommendations=recommendations,
            can_do_full_workout=can_full_workout,
            suggested_intensity=suggested_intensity,
        )

    except Exception as e:
        logger.error(f"Failed to get recovery status: {e}", exc_info=True)
        raise safe_internal_error(e, "senior_fitness")


@router.get("/{user_id}/is-senior", response_model=IsSeniorResponse)
async def check_is_senior(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Check if a user qualifies as a senior (55+)."""
    logger.info(f"Checking senior status for user {user_id}")

    try:
        supabase = get_supabase()

        # Get user age
        user_result = supabase.client.table("users").select(
            "age, date_of_birth"
        ).eq("id", user_id).execute()

        age = None
        if user_result.data:
            age = user_result.data[0].get("age")
            if not age and user_result.data[0].get("date_of_birth"):
                try:
                    dob = datetime.fromisoformat(
                        str(user_result.data[0].get("date_of_birth")).replace("Z", "+00:00")
                    )
                    age = (datetime.now(dob.tzinfo) - dob).days // 365
                except Exception as e:
                    logger.debug(f"Failed to parse date of birth: {e}")

        is_senior = age is not None and age >= 55
        age_bracket = get_age_bracket(age) if age else None

        # Check if has settings
        settings_result = supabase.client.table("senior_recovery_settings").select(
            "id"
        ).eq("user_id", user_id).execute()

        has_settings = bool(settings_result.data)

        return IsSeniorResponse(
            user_id=user_id,
            is_senior=is_senior,
            age=age,
            age_bracket=age_bracket,
            has_senior_settings=has_settings,
        )

    except Exception as e:
        logger.error(f"Failed to check senior status: {e}", exc_info=True)
        raise safe_internal_error(e, "senior_fitness")


@router.get("/mobility-exercises", response_model=List[MobilityExercise])
async def get_mobility_exercises(
    target_area: Optional[str] = Query(default=None, description="Filter by target area"),
    current_user: dict = Depends(get_current_user),
):
    """Get library of mobility exercises for seniors."""
    logger.info("Getting mobility exercises")

    exercises = get_mobility_exercise_library()

    if target_area:
        exercises = [e for e in exercises if target_area.lower() in [t.lower() for t in e["target_areas"]]]

    return [MobilityExercise(**e) for e in exercises]


@router.get("/balance-exercises", response_model=List[BalanceExercise])
async def get_balance_exercises(
    difficulty: Optional[str] = Query(default=None, description="Filter by difficulty"),
    current_user: dict = Depends(get_current_user),
):
    """Get library of balance exercises for seniors."""
    logger.info("Getting balance exercises")

    exercises = get_balance_exercise_library()

    if difficulty:
        exercises = [e for e in exercises if e["difficulty"].lower() == difficulty.lower()]

    return [BalanceExercise(**e) for e in exercises]


@router.get("/low-impact-alternative/{exercise_name}", response_model=LowImpactAlternative)
async def get_low_impact_alternative(exercise_name: str,
    current_user: dict = Depends(get_current_user),
):
    """Get a low-impact alternative for a high-impact exercise."""
    logger.info(f"Getting low-impact alternative for: {exercise_name}")

    alternatives = get_low_impact_alternatives()
    exercise_key = exercise_name.lower().replace(" ", "_").replace("-", "_")

    if exercise_key not in alternatives:
        raise HTTPException(
            status_code=404,
            detail=f"No alternative found for {exercise_name}. This exercise may already be low-impact."
        )

    alt = alternatives[exercise_key]
    return LowImpactAlternative(
        original_exercise=exercise_name,
        alternative_exercise=alt["alternative"],
        reason=alt["reason"],
        muscle_groups=alt["muscle_groups"],
        intensity_modifier=alt["intensity_modifier"],
    )


@router.post("/apply-workout-modifications", response_model=WorkoutModificationResponse)
async def apply_workout_modifications(request: WorkoutModificationRequest,
    current_user: dict = Depends(get_current_user),
):
    """Apply senior modifications to a workout."""
    logger.info(f"Applying senior modifications for user {request.user_id}")

    try:
        settings = await get_senior_settings(request.user_id)

        if not settings.is_senior:
            return WorkoutModificationResponse(
                user_id=request.user_id,
                modifications_applied=[],
                modified_exercises=request.workout_exercises,
                warmup_added_minutes=0,
                cooldown_added_minutes=0,
                total_rest_increase_percent=0,
            )

        modifications_applied = []
        modified_exercises = []
        alternatives = get_low_impact_alternatives()

        for exercise in request.workout_exercises:
            modified = exercise.copy()
            exercise_name = exercise.get("name", "").lower().replace(" ", "_").replace("-", "_")

            # Apply low-impact alternatives if needed
            if settings.avoid_high_impact and exercise_name in alternatives:
                alt = alternatives[exercise_name]
                modified["name"] = alt["alternative"]
                modified["original_name"] = exercise.get("name")
                modifications_applied.append(
                    f"Replaced {exercise.get('name')} with {alt['alternative']} (low-impact)"
                )

            # Reduce intensity if needed
            if settings.max_intensity_percent < 100:
                if "weight" in modified:
                    original_weight = modified["weight"]
                    modified["weight"] = int(original_weight * (settings.max_intensity_percent / 100))
                    if modified["weight"] != original_weight:
                        modifications_applied.append(
                            f"Reduced weight for {exercise.get('name')} to {settings.max_intensity_percent}%"
                        )

            # Increase rest time
            if "rest_seconds" in modified and settings.rest_between_sets_multiplier > 1.0:
                original_rest = modified["rest_seconds"]
                modified["rest_seconds"] = int(original_rest * settings.rest_between_sets_multiplier)

            modified_exercises.append(modified)

        # Calculate added time
        warmup_added = settings.warmup_extension_minutes if settings.include_warmup_extension else 0
        cooldown_added = settings.cooldown_extension_minutes if settings.include_cooldown_extension else 0
        rest_increase = int((settings.rest_between_sets_multiplier - 1) * 100)

        if warmup_added > 0:
            modifications_applied.append(f"Added {warmup_added} minutes to warm-up")
        if cooldown_added > 0:
            modifications_applied.append(f"Added {cooldown_added} minutes to cool-down")
        if rest_increase > 0:
            modifications_applied.append(f"Increased rest between sets by {rest_increase}%")

        return WorkoutModificationResponse(
            user_id=request.user_id,
            modifications_applied=modifications_applied,
            modified_exercises=modified_exercises,
            warmup_added_minutes=warmup_added,
            cooldown_added_minutes=cooldown_added,
            total_rest_increase_percent=rest_increase,
        )

    except Exception as e:
        logger.error(f"Failed to apply workout modifications: {e}", exc_info=True)
        raise safe_internal_error(e, "senior_fitness")


@router.get("/{user_id}/prompt-context", response_model=PromptContextResponse)
async def get_prompt_context(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Get AI prompt context for senior users."""
    logger.info(f"Getting prompt context for user {user_id}")

    try:
        settings = await get_senior_settings(user_id)

        if not settings.is_senior:
            return PromptContextResponse(
                user_id=user_id,
                is_senior=False,
                context_text="",
                key_considerations=[],
            )

        considerations = []
        context_parts = []

        context_parts.append(f"User is a senior athlete (age: {settings.age}, bracket: {settings.age_bracket})")

        if settings.prefer_low_impact:
            considerations.append("Prefer low-impact exercises")
            context_parts.append("Prefers low-impact exercises")

        if settings.avoid_high_impact:
            considerations.append("Avoid high-impact exercises (no jumping)")
            context_parts.append("Must avoid high-impact movements")

        if settings.prefer_seated_exercises:
            considerations.append("Include seated exercise options")
            context_parts.append("Prefers seated exercises when possible")

        if settings.joint_protection_mode and settings.protected_joints:
            joints_str = ", ".join(settings.protected_joints)
            considerations.append(f"Protect joints: {joints_str}")
            context_parts.append(f"Has joint concerns: {joints_str}")

        if settings.recovery_multiplier > 1.0:
            considerations.append(f"Recovery multiplier: {settings.recovery_multiplier}x")

        considerations.append(f"Max intensity: {settings.max_intensity_percent}%")
        considerations.append(f"Min rest days between workouts: {settings.min_rest_days_between_workouts}")

        if settings.include_balance_work:
            considerations.append("Include balance exercises")

        context_text = ". ".join(context_parts) + "."

        return PromptContextResponse(
            user_id=user_id,
            is_senior=True,
            context_text=context_text,
            key_considerations=considerations,
        )

    except Exception as e:
        logger.error(f"Failed to get prompt context: {e}", exc_info=True)
        raise safe_internal_error(e, "senior_fitness")
