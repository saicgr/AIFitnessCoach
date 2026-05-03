"""
User profile CRUD endpoints: get, update, delete, reset, photo upload/delete.
"""
from core.db import get_supabase_db
import json
from datetime import datetime
from fastapi import APIRouter, BackgroundTasks, Body, Depends, HTTPException, Request
from core.auth import get_current_user, get_verified_auth_token, verify_user_ownership, get_admin_user
from core.exceptions import safe_internal_error
from typing import Optional, List

from core.supabase_client import get_supabase
from core.logger import get_logger
from core.rate_limiter import limiter
from core.activity_logger import log_user_activity, log_user_error
from models.schemas import User, UserCreate, UserUpdate

from api.v1.users.models import (
    DestructiveActionRequest,
    ProgramPreferences,
    row_to_user,
    merge_extended_fields_into_preferences,
)
from api.v1.users.onboarding import create_gym_profiles_from_onboarding

router = APIRouter()
logger = get_logger(__name__)


async def _schedule_welcome_email(
    *,
    background_tasks: "BackgroundTasks",
    user_id: str,
    existing: dict,
    updated: dict,
    preferences: dict,
) -> None:
    """Build the welcome-email payload and queue it as a BackgroundTask.

    Pulled out of update_user() to keep the endpoint readable. Pulls macros
    from the users row (daily_calorie_target etc.), reads tomorrow's
    workout from the `workouts` table, and infers training days from
    preferences. Every data point is optional — missing values cause the
    matching block in the email template to be hidden, never an error.
    """
    from services.email_service import get_email_service

    # Prefer the freshly-updated row, fall back to existing snapshot.
    src: dict = updated or existing or {}
    email_addr = src.get("email") or existing.get("email")
    if not email_addr:
        logger.warning(f"[Welcome-Email] No email on user {user_id}; skipping")
        return

    # ── First name: prefer `name` first token, fall back to email prefix ──
    raw_name = (src.get("name") or existing.get("name") or "").strip()
    first_name = raw_name.split(" ")[0] if raw_name else ""
    if not first_name and email_addr:
        # Last-ditch fallback so emails are never "Hi there".
        first_name = email_addr.split("@")[0].split("+")[0].split(".")[0].title()

    # ── Goal (single string for copy logic) ────────────────────────────────
    goals_raw = src.get("goals") or existing.get("goals")
    goal: Optional[str] = None
    if isinstance(goals_raw, str):
        try:
            parsed = json.loads(goals_raw)
            if isinstance(parsed, list) and parsed:
                goal = str(parsed[0])
            elif isinstance(parsed, str):
                goal = parsed
        except json.JSONDecodeError:
            goal = goals_raw
    elif isinstance(goals_raw, list) and goals_raw:
        goal = str(goals_raw[0])
    elif isinstance(goals_raw, dict):
        goal = goals_raw.get("primary") or goals_raw.get("goal")

    # ── Weights ────────────────────────────────────────────────────────────
    weight_kg = src.get("weight_kg") or existing.get("weight_kg")
    goal_weight_kg = src.get("target_weight_kg") or existing.get("target_weight_kg")
    weight_direction: Optional[str] = None
    try:
        if weight_kg and goal_weight_kg:
            weight_direction = "lose" if float(weight_kg) > float(goal_weight_kg) else "gain"
    except (TypeError, ValueError):
        weight_direction = None

    # ── Macros: read user-row targets first, else compute Mifflin-St Jeor ──
    daily_calories = src.get("daily_calorie_target") or existing.get("daily_calorie_target")
    protein_g = src.get("daily_protein_target_g") or existing.get("daily_protein_target_g")
    carbs_g = src.get("daily_carbs_target_g") or existing.get("daily_carbs_target_g")
    fat_g = src.get("daily_fat_target_g") or existing.get("daily_fat_target_g")

    if not all([daily_calories, protein_g, carbs_g, fat_g]):
        try:
            from services.metrics_calculator import MetricsCalculator
            mc = MetricsCalculator()
            wkg = float(weight_kg) if weight_kg else 0.0
            hcm = float(src.get("height_cm") or existing.get("height_cm") or 0)
            age = int(src.get("age") or existing.get("age") or 0)
            gender = (src.get("gender") or existing.get("gender") or "male").lower()
            activity = (src.get("activity_level") or existing.get("activity_level") or "lightly_active")
            if wkg > 0 and hcm > 0 and age > 0:
                bmr = mc.calculate_bmr_mifflin(wkg, hcm, age, gender)
                tdee = mc.calculate_tdee(bmr, activity)
                # Goal-adjusted target (textbook 7700 kcal per kg rule, ±300 cal).
                goal_l = (goal or "").lower()
                if goal_l in ("lose_weight", "lose", "fat_loss") or weight_direction == "lose":
                    target_cal = tdee - 500
                elif goal_l in ("gain_weight", "gain", "muscle", "bulk") or weight_direction == "gain":
                    target_cal = tdee + 300
                else:
                    target_cal = tdee
                daily_calories = daily_calories or int(round(target_cal))
                # Protein: 1.6 g/kg bodyweight (ACSM lifter range).
                protein_g = protein_g or int(round(wkg * 1.6))
                # Fat: 25% of calories at 9 kcal/g.
                fat_g = fat_g or int(round(target_cal * 0.25 / 9))
                # Carbs: remainder at 4 kcal/g.
                remaining = target_cal - (protein_g * 4) - (fat_g * 9)
                carbs_g = carbs_g or max(0, int(round(remaining / 4)))
        except Exception as macro_err:
            logger.warning(
                f"[Welcome-Email] Macro fallback compute failed for "
                f"{user_id}: {macro_err}"
            )

    # ── Tomorrow's workout (skip silently on any error) ───────────────────
    first_workout_name: Optional[str] = None
    first_workout_duration: Optional[int] = None
    first_workout_exercises: Optional[List[dict]] = None
    try:
        from datetime import date, timedelta
        db = get_supabase_db()
        tomorrow_iso = (date.today() + timedelta(days=1)).isoformat()
        # Look 1-7 days out so we still have something to show even if
        # the user generated their first plan starting later in the week.
        future_iso = (date.today() + timedelta(days=8)).isoformat()
        result = (
            db.client.table("workouts")
            .select("name,duration_minutes,exercises,scheduled_date,type")
            .eq("user_id", user_id)
            .gte("scheduled_date", tomorrow_iso)
            .lt("scheduled_date", future_iso)
            .order("scheduled_date")
            .limit(1)
            .execute()
        )
        rows = (result.data or []) if result else []
        if rows:
            w = rows[0]
            first_workout_name = w.get("name") or (w.get("type") or "").replace("_", " ").title() or None
            try:
                first_workout_duration = int(w.get("duration_minutes")) if w.get("duration_minutes") else None
            except (TypeError, ValueError):
                first_workout_duration = None
            ex_raw = w.get("exercises")
            if isinstance(ex_raw, str):
                try:
                    ex_raw = json.loads(ex_raw)
                except json.JSONDecodeError:
                    ex_raw = None
            if isinstance(ex_raw, list):
                first_workout_exercises = [
                    {
                        "name": e.get("name") or e.get("exercise_name"),
                        "sets": e.get("sets"),
                        "reps": e.get("reps"),
                    }
                    for e in ex_raw[:3]
                    if isinstance(e, dict)
                ]
    except Exception as workout_err:
        logger.warning(
            f"[Welcome-Email] Could not fetch tomorrow's workout for "
            f"{user_id}: {workout_err}"
        )

    # ── Training days: prefs.workout_days or infer from days_per_week ──────
    training_days: Optional[List[str]] = None
    prefs_src = preferences if isinstance(preferences, dict) else {}
    pd = prefs_src.get("workout_days") or prefs_src.get("preferred_training_days")
    if isinstance(pd, list) and pd:
        training_days = [str(d) for d in pd]
    else:
        try:
            dpw = int(prefs_src.get("days_per_week") or src.get("days_per_week") or 0)
        except (TypeError, ValueError):
            dpw = 0
        # Standard Mon/Wed/Fri-style fallback patterns. These are inferred,
        # not authoritative — but they let us render the schedule strip for
        # users whose onboarding didn't capture explicit weekday choices.
        infer_map = {
            1: ["mon"],
            2: ["mon", "thu"],
            3: ["mon", "wed", "fri"],
            4: ["mon", "tue", "thu", "fri"],
            5: ["mon", "tue", "wed", "thu", "fri"],
            6: ["mon", "tue", "wed", "thu", "fri", "sat"],
            7: ["mon", "tue", "wed", "thu", "fri", "sat", "sun"],
        }
        if dpw in infer_map:
            training_days = infer_map[dpw]

    background_tasks.add_task(
        get_email_service().send_welcome_email,
        email_addr,
        first_name,
        goal,
        prefs_src.get("days_per_week") if isinstance(prefs_src, dict) else None,
        weight_kg,
        goal_weight_kg,
        weight_direction,
        daily_calories,
        protein_g,
        carbs_g,
        fat_g,
        first_workout_name,
        first_workout_duration,
        first_workout_exercises,
        training_days,
    )
    logger.info(
        f"[Welcome-Email] Queued for user {user_id} "
        f"(name={bool(first_name)}, macros={bool(daily_calories)}, "
        f"workout={bool(first_workout_name)}, days={bool(training_days)})"
    )


@router.post("/", response_model=User)
@limiter.limit("5/minute")
async def create_user(request, user: UserCreate,
    current_user: dict = Depends(get_current_user),
):
    """Create a new user."""
    logger.info(f"Creating user: level={user.fitness_level}")

    try:
        db = get_supabase_db()

        # Parse JSON strings to actual types for Supabase JSONB
        goals = json.loads(user.goals) if isinstance(user.goals, str) else user.goals
        equipment = json.loads(user.equipment) if isinstance(user.equipment, str) else user.equipment
        active_injuries = json.loads(user.active_injuries) if isinstance(user.active_injuries, str) else user.active_injuries

        # Merge extended onboarding fields into preferences
        final_preferences = merge_extended_fields_into_preferences(
            user.preferences,
            user.days_per_week,
            user.workout_duration,
            user.training_split,
            user.intensity_preference,
            user.preferred_time,
            user.progression_pace,
            user.workout_type_preference,
            user.workout_environment,
            user.gym_name,
            workout_variety=user.workout_variety,
        )
        logger.debug(f"User preferences: {final_preferences}")

        user_data = {
            "fitness_level": user.fitness_level,
            "goals": goals,
            "equipment": equipment,
            "preferences": final_preferences,
            "active_injuries": active_injuries,
        }

        created = db.create_user(user_data)
        logger.info(f"User created: id={created['id']}")

        # Log user creation
        await log_user_activity(
            user_id=created['id'],
            action="user_created",
            endpoint="/api/v1/users/",
            message=f"New user created (fitness_level: {user.fitness_level})",
            metadata={"fitness_level": user.fitness_level},
            status_code=200
        )

        return row_to_user(created)

    except Exception as e:
        logger.error(f"Failed to create user: {e}", exc_info=True)
        raise safe_internal_error(e, "users")


@router.get("/", response_model=List[User])
async def get_all_users(
    current_user: dict = Depends(get_admin_user),
):
    """Get all users."""
    logger.info("Fetching all users")
    try:
        db = get_supabase_db()
        rows = db.get_all_users()
        return [row_to_user(row) for row in rows]
    except Exception as e:
        logger.error(f"Failed to get users: {e}", exc_info=True)
        raise safe_internal_error(e, "users")


@router.get("/by-auth/{auth_id}", response_model=User)
async def get_user_by_auth(auth_id: str,
    verified_token: dict = Depends(get_verified_auth_token),
):
    """
    Get a user by their Supabase auth_id.

    This endpoint is used during session restore when we have the Supabase Auth ID
    but need to look up the user's internal database ID.

    Uses get_verified_auth_token (not get_current_user) because if the user
    doesn't have a DB row yet, get_current_user would fail with 404 before
    this endpoint runs — making it impossible to detect a missing DB row.
    """
    logger.info(f"Fetching user by auth_id: {auth_id}")
    # Security: users can only look up their own auth record
    if verified_token["auth_id"] != auth_id:
        raise HTTPException(status_code=403, detail="Access denied")
    try:
        db = get_supabase_db()
        row = db.get_user_by_auth_id(auth_id)

        if not row:
            # Diagnostic: a 404 here was the first visible symptom of the
            # duplicate-user bug in April 2026. Log enough context to
            # correlate the missing row with what the caller's JWT thinks
            # it is, and cross-check by email in case the DB row exists
            # under a different auth_id.
            token_email = verified_token.get("email")
            by_email = None
            try:
                by_email = db.get_user_by_email(token_email) if token_email else None
            except Exception as lookup_err:
                logger.warning(
                    f"[BY-AUTH-404] by-email fallback failed: {lookup_err!r}"
                )
            logger.warning(
                "[BY-AUTH-404] User not found by auth_id=%s | token_email=%s | "
                "row_found_by_email=%s (auth_id on that row=%s)",
                auth_id,
                token_email,
                bool(by_email),
                (by_email or {}).get("auth_id"),
            )
            raise HTTPException(status_code=404, detail="User not found")

        logger.debug(f"User found by auth_id: id={row.get('id')}, auth_id={auth_id}")
        return row_to_user(row)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get user by auth_id: {e}", exc_info=True)
        raise safe_internal_error(e, "users")


@router.get("/{user_id}", response_model=User)
async def get_user(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Get a user by ID."""
    logger.info(f"Fetching user: id={user_id}")
    try:
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()
        row = db.get_user(user_id)

        if not row:
            logger.warning(f"User not found: id={user_id}")
            raise HTTPException(status_code=404, detail="User not found")

        logger.debug(f"User found: id={user_id}, level={row.get('fitness_level')}")
        return row_to_user(row)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get user: {e}", exc_info=True)
        raise safe_internal_error(e, "users")


@router.get("/{user_id}/stats")
async def get_user_stats(
    user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Aggregate user-level stats for the workout-complete celebration screen.

    Returns at minimum `total_workouts` (count of completed workouts). Extra
    fields can be added without breaking clients — Flutter parses defensively.
    """
    try:
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()

        total_workouts = 0
        try:
            res = (
                db.client.table("workouts")
                .select("id", count="exact")
                .eq("user_id", user_id)
                .eq("is_completed", True)
                .execute()
            )
            total_workouts = int(res.count or 0)
        except Exception as inner:
            # Fall back to a non-counting query so the endpoint never 500s for a
            # missing `count` privilege; total_workouts stays 0 in that case.
            logger.warning(f"[users/stats] count query failed for {user_id}: {inner}")
            try:
                res = (
                    db.client.table("workouts")
                    .select("id")
                    .eq("user_id", user_id)
                    .eq("is_completed", True)
                    .execute()
                )
                total_workouts = len(res.data or [])
            except Exception as inner2:
                logger.error(f"[users/stats] fallback query failed for {user_id}: {inner2}", exc_info=True)

        return {
            "user_id": user_id,
            "total_workouts": total_workouts,
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get user stats: {e}", exc_info=True)
        raise safe_internal_error(e, "users")


@router.get("/{user_id}/program-preferences", response_model=ProgramPreferences)
async def get_program_preferences(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get user's current program preferences for the customize program sheet.

    Merges preferences from:
    1. users.preferences JSONB (base preferences)
    2. Most recent workout_regenerations entry (latest selections)

    Returns unified preferences for pre-populating the edit form.
    """
    logger.info(f"Fetching program preferences for user: id={user_id}")
    try:
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()

        # Get user data
        user_row = db.get_user(user_id)
        if not user_row:
            logger.warning(f"User not found: id={user_id}")
            raise HTTPException(status_code=404, detail="User not found")

        # Get base preferences from user record
        base_prefs = user_row.get("preferences", {})
        if isinstance(base_prefs, str):
            try:
                base_prefs = json.loads(base_prefs)
            except json.JSONDecodeError:
                base_prefs = {}

        # Get user's equipment from user record
        user_equipment = user_row.get("equipment", [])
        if isinstance(user_equipment, str):
            try:
                user_equipment = json.loads(user_equipment)
            except json.JSONDecodeError:
                user_equipment = []

        # Get user's active injuries
        user_injuries = user_row.get("active_injuries", [])
        if isinstance(user_injuries, str):
            try:
                user_injuries = json.loads(user_injuries)
            except json.JSONDecodeError:
                user_injuries = []

        # Get most recent regeneration for latest selections
        latest_regen = db.get_latest_user_regeneration(user_id)

        # Helper to safely parse list fields (may be JSON strings or actual lists)
        def safe_list(value, default=None):
            if default is None:
                default = []
            if value is None:
                return default
            if isinstance(value, list):
                return value
            if isinstance(value, str):
                try:
                    parsed = json.loads(value)
                    return parsed if isinstance(parsed, list) else default
                except json.JSONDecodeError:
                    return default
            return default

        # Build response - latest regeneration takes precedence
        result = ProgramPreferences(
            difficulty=latest_regen.get("selected_difficulty") if latest_regen else base_prefs.get("intensity_preference"),
            duration_minutes=latest_regen.get("selected_duration_minutes") if latest_regen else base_prefs.get("workout_duration"),
            workout_type=latest_regen.get("selected_workout_type") if latest_regen else base_prefs.get("training_split"),
            training_split=base_prefs.get("training_split"),
            workout_days=_get_workout_days(base_prefs, latest_regen),
            equipment=safe_list(latest_regen.get("selected_equipment")) if latest_regen else user_equipment,
            focus_areas=safe_list(latest_regen.get("selected_focus_areas")) if latest_regen else [],
            injuries=safe_list(latest_regen.get("selected_injuries")) if latest_regen else user_injuries,
            last_updated=latest_regen.get("created_at") if latest_regen else user_row.get("updated_at"),
            dumbbell_count=base_prefs.get("dumbbell_count", 2),
            kettlebell_count=base_prefs.get("kettlebell_count", 2),
            workout_environment=base_prefs.get("workout_environment"),
        )

        logger.info(f"Program preferences fetched for user {user_id}")
        return result

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get program preferences: {e}", exc_info=True)
        raise safe_internal_error(e, "users")


def _get_workout_days(base_prefs: dict, latest_regen: Optional[dict]) -> List[str]:
    """Extract workout days from preferences or regeneration data."""
    day_names = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    # Check latest regeneration first (if it has workout_days)
    if latest_regen and latest_regen.get("selected_workout_days"):
        selected_days = latest_regen["selected_workout_days"]
        if isinstance(selected_days, list):
            # Could be indices or day names
            if selected_days and isinstance(selected_days[0], int):
                return [day_names[i] for i in selected_days if 0 <= i < 7]
            elif selected_days and isinstance(selected_days[0], str):
                return selected_days

    # Check base preferences - try multiple key names for compatibility
    # Try "workout_days" first (Flutter app uses this)
    workout_days = base_prefs.get("workout_days", [])
    if workout_days:
        if isinstance(workout_days, list):
            # Could be indices or day names
            if workout_days and isinstance(workout_days[0], int):
                return [day_names[i] for i in workout_days if 0 <= i < 7]
            elif workout_days and isinstance(workout_days[0], str):
                return workout_days

    # Try "selected_days" as fallback
    selected_days = base_prefs.get("selected_days", [])
    if selected_days:
        if isinstance(selected_days, list):
            if selected_days and isinstance(selected_days[0], int):
                return [day_names[i] for i in selected_days if 0 <= i < 7]
            elif selected_days and isinstance(selected_days[0], str):
                return selected_days

    # Fall back to days_per_week and generate default days
    days_per_week = base_prefs.get("days_per_week", 3)

    # Default: spread days evenly across the week
    if days_per_week == 2:
        return ["Mon", "Thu"]
    elif days_per_week == 3:
        return ["Mon", "Wed", "Fri"]
    elif days_per_week == 4:
        return ["Mon", "Tue", "Thu", "Fri"]
    elif days_per_week == 5:
        return ["Mon", "Tue", "Wed", "Thu", "Fri"]
    elif days_per_week == 6:
        return ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    elif days_per_week == 7:
        return ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    else:
        return ["Mon", "Wed", "Fri"]


@router.put("/{user_id}", response_model=User)
async def update_user(user_id: str, user: UserUpdate,
    background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user),
):
    """Update a user."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Updating user: id={user_id}")
    # DEBUG: Log incoming data
    logger.info(f"🔍 [DEBUG] Incoming user data:")
    logger.info(f"🔍 [DEBUG] preferences: {user.preferences}")
    logger.info(f"🔍 [DEBUG] equipment: {user.equipment}")
    logger.info(f"🔍 [DEBUG] goals: {user.goals}")
    try:
        db = get_supabase_db()

        # Check if user exists
        existing = db.get_user(user_id)
        if not existing:
            logger.warning(f"User not found for update: id={user_id}")
            raise HTTPException(status_code=404, detail="User not found")

        # Build update data
        update_data = {}

        # Snapshot the user's existing equipment so we can compare it
        # against the incoming value and trigger workout invalidation
        # ONLY when the equipment actually changes. This prevents
        # spurious regenerations when the same payload is re-sent
        # (e.g. profile screen issues writes for unrelated fields).
        equipment_changed = False

        if user.fitness_level is not None:
            update_data["fitness_level"] = user.fitness_level
        if user.goals is not None:
            update_data["goals"] = json.loads(user.goals) if isinstance(user.goals, str) else user.goals
        if user.equipment is not None:
            # Dual-write to legacy `equipment` VARCHAR + new `equipment_v2`
            # text[]. See migrations/2031_users_equipment_array_v2.sql.
            from api.v1.workouts.utils import equipment_dual_write_payload
            payload = equipment_dual_write_payload(user.equipment)
            update_data.update(payload)

            # Detect change: compare normalised new list to the existing
            # one. We compare on the text[] form which is what the
            # dual-write helper normalises to (lowercase, dedup).
            new_eq = sorted(payload["equipment_v2"])
            existing_eq_raw = existing.get("equipment_v2") or existing.get("equipment")
            existing_eq = sorted(
                equipment_dual_write_payload(existing_eq_raw)["equipment_v2"]
            )
            equipment_changed = new_eq != existing_eq
        if user.custom_equipment is not None:
            update_data["custom_equipment"] = json.loads(user.custom_equipment) if isinstance(user.custom_equipment, str) else user.custom_equipment
            logger.info(f"Updating custom_equipment for user {user_id}")
        if user.active_injuries is not None:
            update_data["active_injuries"] = json.loads(user.active_injuries) if isinstance(user.active_injuries, str) else user.active_injuries
        if user.onboarding_completed is not None:
            update_data["onboarding_completed"] = user.onboarding_completed
            # Set timestamp when onboarding is marked as completed
            if user.onboarding_completed:
                from datetime import datetime, timezone
                update_data["onboarding_completed_at"] = datetime.now(timezone.utc).isoformat()
        if user.coach_selected is not None:
            update_data["coach_selected"] = user.coach_selected
        if user.paywall_completed is not None:
            update_data["paywall_completed"] = user.paywall_completed

        # Handle extended onboarding fields - merge into preferences
        has_extended_fields = any([
            user.days_per_week, user.workout_duration, user.training_split,
            user.intensity_preference, user.preferred_time,
            user.progression_pace, user.workout_type_preference,
            user.workout_environment, user.gym_name, user.workout_variety
        ])

        if user.preferences is not None or has_extended_fields:
            current_prefs = existing.get("preferences", {})
            final_preferences = merge_extended_fields_into_preferences(
                user.preferences if user.preferences else current_prefs,
                user.days_per_week,
                user.workout_duration,
                user.training_split,
                user.intensity_preference,
                user.preferred_time,
                user.progression_pace,
                user.workout_type_preference,
                user.workout_environment,
                user.gym_name,
                workout_variety=user.workout_variety,
            )
            update_data["preferences"] = final_preferences
            logger.info(f"🔍 [DEBUG] Final preferences to save: {final_preferences}")

        # Handle personal/health fields
        if user.name is not None:
            update_data["name"] = user.name
        if user.gender is not None:
            update_data["gender"] = user.gender
        if user.age is not None:
            update_data["age"] = user.age
        if user.date_of_birth is not None:
            update_data["date_of_birth"] = user.date_of_birth
        if user.height_cm is not None:
            update_data["height_cm"] = user.height_cm
        if user.weight_kg is not None:
            update_data["weight_kg"] = user.weight_kg
        if user.target_weight_kg is not None:
            update_data["target_weight_kg"] = user.target_weight_kg
        if user.activity_level is not None:
            update_data["activity_level"] = user.activity_level

        # Handle weight unit preference (kg or lbs)
        if user.weight_unit is not None:
            update_data["weight_unit"] = user.weight_unit
            logger.info(f"Updating weight_unit for user {user_id}: {user.weight_unit}")

        # Handle body measurement unit preference (cm or in)
        if user.measurement_unit is not None:
            update_data["measurement_unit"] = user.measurement_unit
            logger.info(f"Updating measurement_unit for user {user_id}: {user.measurement_unit}")

        # Handle FCM token and device platform for push notifications
        if user.fcm_token is not None:
            update_data["fcm_token"] = user.fcm_token
            logger.info(f"Updating FCM token for user {user_id}")

        if user.device_platform is not None:
            update_data["device_platform"] = user.device_platform
            logger.info(f"Updating device platform for user {user_id}: {user.device_platform}")

        # Handle device info fields
        if user.device_model is not None:
            update_data["device_model"] = user.device_model
        if user.is_foldable is not None:
            update_data["is_foldable"] = user.is_foldable
        if user.os_version is not None:
            update_data["os_version"] = user.os_version
        if user.screen_width is not None:
            update_data["screen_width"] = user.screen_width
        if user.screen_height is not None:
            update_data["screen_height"] = user.screen_height

        # Auto-set last_device_update when any device field is present
        has_device_fields = any([
            user.device_model is not None,
            user.device_platform is not None,
            user.is_foldable is not None,
            user.os_version is not None,
            user.screen_width is not None,
            user.screen_height is not None,
        ])
        if has_device_fields:
            from datetime import datetime as dt, timezone as tz
            update_data["last_device_update"] = dt.now(tz.utc).isoformat()
            logger.info(f"Updating device info for user {user_id}: model={user.device_model}, foldable={user.is_foldable}")

        # Handle notification preferences
        if user.notification_preferences is not None:
            # Merge with existing notification preferences if any
            existing_notif_prefs = existing.get("notification_preferences", {})
            if isinstance(existing_notif_prefs, str):
                try:
                    existing_notif_prefs = json.loads(existing_notif_prefs)
                except json.JSONDecodeError:
                    existing_notif_prefs = {}

            # Merge the new preferences with existing
            merged_prefs = {**existing_notif_prefs, **user.notification_preferences}
            update_data["notification_preferences"] = merged_prefs
            logger.info(f"Updating notification preferences for user {user_id}")

        # Handle detailed equipment with quantities and weights
        if user.equipment_details is not None:
            update_data["equipment_details"] = user.equipment_details
            logger.info(f"Updating equipment_details for user {user_id}: {len(user.equipment_details)} items")

        # Handle bio field
        if user.bio is not None:
            update_data["bio"] = user.bio

        # Handle primary training goal
        if user.primary_goal is not None:
            update_data["primary_goal"] = user.primary_goal
            logger.info(f"Updating primary_goal for user {user_id}: {user.primary_goal}")

        # Vacation mode (migration 1941) — validate date window on write.
        # NULL start/end are legal (immediate / open-ended vacations).
        if user.in_vacation_mode is not None:
            update_data["in_vacation_mode"] = user.in_vacation_mode
            logger.info(f"Setting in_vacation_mode={user.in_vacation_mode} for user {user_id}")
        if user.is_trainer is not None:
            update_data["is_trainer"] = user.is_trainer
            logger.info(f"Setting is_trainer={user.is_trainer} for user {user_id}")

        if user.vacation_start_date is not None:
            # Empty string → NULL (clear the date)
            update_data["vacation_start_date"] = user.vacation_start_date or None

        if user.vacation_end_date is not None:
            update_data["vacation_end_date"] = user.vacation_end_date or None

        # Cross-field validation: start <= end if both provided.
        start_d = update_data.get("vacation_start_date") if "vacation_start_date" in update_data \
            else existing.get("vacation_start_date")
        end_d = update_data.get("vacation_end_date") if "vacation_end_date" in update_data \
            else existing.get("vacation_end_date")
        if start_d and end_d:
            try:
                from datetime import date as _date
                sd = _date.fromisoformat(str(start_d)[:10])
                ed = _date.fromisoformat(str(end_d)[:10])
                if sd > ed:
                    raise HTTPException(
                        status_code=400,
                        detail="vacation_start_date must be on or before vacation_end_date",
                    )
            except (ValueError, TypeError):
                raise HTTPException(
                    status_code=400,
                    detail="vacation dates must be ISO format YYYY-MM-DD",
                )

        # Handle muscle focus points (validate max 5 points)
        if user.muscle_focus_points is not None:
            total_points = sum(user.muscle_focus_points.values()) if user.muscle_focus_points else 0
            if total_points > 5:
                raise HTTPException(
                    status_code=400,
                    detail=f"Muscle focus points cannot exceed 5. Current total: {total_points}"
                )
            update_data["muscle_focus_points"] = user.muscle_focus_points
            logger.info(f"Updating muscle_focus_points for user {user_id}: {user.muscle_focus_points}")

        logger.info(f"🔍 [DEBUG] Final update_data to save: {update_data}")
        if update_data:
            updated = db.update_user(user_id, update_data)
            logger.debug(f"Updated {len(update_data)} fields for user {user_id}")

            # Equipment-change → workout-invalidation hook (plan §D).
            # When the user's equipment selection actually changed, drop
            # today's not-yet-started workout + every upcoming pre-cached
            # workout so the next /today read regenerates them against
            # the new equipment list. In-progress and completed workouts
            # are preserved (history is immutable; mid-workout users are
            # warned via separate UX, not yanked out).
            if equipment_changed:
                try:
                    from api.v1.workouts.utils import (
                        invalidate_workouts_after_equipment_change,
                    )
                    from core.timezone_utils import resolve_timezone

                    tz = resolve_timezone(existing.get("timezone"))
                    counts = invalidate_workouts_after_equipment_change(
                        user_id=user_id,
                        timezone_str=tz,
                    )
                    logger.info(
                        f"[Equipment-Change] User {user_id}: invalidated "
                        f"{counts['today_deleted']} today + "
                        f"{counts['upcoming_deleted']} upcoming workouts"
                    )
                except Exception as inval_err:
                    # Never let invalidation failures block the profile
                    # write — the user-facing change still succeeds.
                    logger.warning(
                        f"[Equipment-Change] Invalidation failed for user "
                        f"{user_id}: {inval_err}",
                        exc_info=True,
                    )

            # NEW: Create gym profile(s) when onboarding is completed
            if user.onboarding_completed and update_data.get("onboarding_completed"):
                # Fetch fresh user data to get equipment saved by the preferences endpoint
                # (equipment is saved in a separate prior request, not in this update_data)
                try:
                    user_row = db.client.table("users").select(
                        "equipment, equipment_details, preferences"
                    ).eq("id", user_id).single().execute().data
                except Exception:
                    user_row = {}

                db_equipment = user_row.get("equipment") or []
                if isinstance(db_equipment, str):
                    try:
                        db_equipment = json.loads(db_equipment)
                    except (json.JSONDecodeError, TypeError):
                        db_equipment = []
                db_equipment_details = user_row.get("equipment_details") or []
                if isinstance(db_equipment_details, str):
                    try:
                        db_equipment_details = json.loads(db_equipment_details)
                    except (json.JSONDecodeError, TypeError):
                        db_equipment_details = []
                db_prefs = user_row.get("preferences") or {}
                if isinstance(db_prefs, str):
                    try:
                        db_prefs = json.loads(db_prefs)
                    except (json.JSONDecodeError, TypeError):
                        db_prefs = {}

                prefs = update_data.get("preferences", {}) or db_prefs

                try:
                    logger.info(f"🏋️ [GymProfile] Onboarding completed - preferences: {prefs}")
                    logger.info(f"🏋️ [GymProfile] Equipment (from DB): {db_equipment}")
                    logger.info(f"🏋️ [GymProfile] Equipment details: {len(db_equipment_details)} items")

                    await create_gym_profiles_from_onboarding(
                        user_id=user_id,
                        gym_name=prefs.get("gym_name"),
                        workout_environment=prefs.get("workout_environment") or db_prefs.get("workout_environment"),
                        equipment=db_equipment,
                        equipment_details=db_equipment_details,
                        preferences=prefs if prefs else db_prefs,
                    )
                    logger.info(f"🏋️ [GymProfile] ✅ Created gym profile(s) for user {user_id} during onboarding")
                except Exception as gym_error:
                    logger.error(f"⚠️ [GymProfile] Failed to create gym profiles during onboarding: {gym_error}", exc_info=True)
                    import traceback
                    logger.error(f"⚠️ [GymProfile] Traceback: {traceback.format_exc()}", exc_info=True)
                    # Don't fail onboarding if gym profile creation fails

                # Index preferences to ChromaDB for AI
                try:
                    from services.rag_service import WorkoutRAGService
                    from services.gemini_service import GeminiService

                    gemini_service = GeminiService()
                    rag_service = WorkoutRAGService(gemini_service)

                    # Parse goals from update_data (stored as JSON string)
                    goals_data = update_data.get("goals")
                    if isinstance(goals_data, str):
                        try:
                            goals_data = json.loads(goals_data)
                        except json.JSONDecodeError:
                            goals_data = [goals_data] if goals_data else []

                    await rag_service.index_program_preferences(
                        user_id=user_id,
                        difficulty=prefs.get("intensity_preference"),
                        duration_minutes=prefs.get("workout_duration"),
                        workout_type=prefs.get("training_split"),
                        workout_days=prefs.get("workout_days"),
                        equipment=db_equipment,
                        focus_areas=prefs.get("focus_areas"),
                        injuries=update_data.get("active_injuries", []),
                        goals=goals_data if isinstance(goals_data, list) else None,
                        motivations=prefs.get("motivations"),
                        dumbbell_count=prefs.get("dumbbell_count"),
                        kettlebell_count=prefs.get("kettlebell_count"),
                        training_experience=prefs.get("training_experience"),
                        workout_environment=prefs.get("workout_environment") or db_prefs.get("workout_environment"),
                        change_reason="onboarding_completed",
                    )
                    logger.info(f"📊 Indexed onboarding preferences to ChromaDB for user {user_id}")
                except Exception as rag_error:
                    logger.warning(f"⚠️ Could not index preferences to ChromaDB: {rag_error}", exc_info=True)

                # ── Welcome email (founder voice) ───────────────────────────
                # Plan A2b + C1: send the welcome email here, AFTER onboarding
                # is marked complete, instead of immediately after auth signup.
                # By this point we have name, goal, weight, macros, training
                # days, and a generated first workout — so the email can show
                # real numbers instead of "Welcome, there.".
                #
                # Edge cases handled:
                #   - First name missing → falls back to "Hey," in template.
                #   - Macros not yet computed → macro grid is hidden.
                #   - Tomorrow's workout not yet generated → block is hidden.
                #   - Training days missing → schedule strip is hidden.
                #   - Existing user re-saving profile (onboarding already done):
                #     guarded by `was_already_onboarded` so we don't re-send.
                try:
                    was_already_onboarded = bool(existing.get("onboarding_completed"))
                except Exception:
                    was_already_onboarded = False

                if not was_already_onboarded:
                    try:
                        from services.email_service import get_email_service
                        await _schedule_welcome_email(
                            background_tasks=background_tasks,
                            user_id=user_id,
                            existing=existing,
                            updated=updated,
                            preferences=prefs if prefs else db_prefs,
                        )
                    except Exception as welcome_err:
                        # Never let welcome-email scheduling break onboarding.
                        logger.error(
                            f"[Welcome-Email] Failed to schedule for user "
                            f"{user_id}: {welcome_err}",
                            exc_info=True,
                        )

            # Index training settings changes to ChromaDB for AI context
            has_training_settings = any([
                user.progression_pace, user.workout_type_preference, user.training_split
            ])
            if has_training_settings:
                try:
                    from services.rag_service import WorkoutRAGService
                    from services.gemini_service import GeminiService

                    gemini_service = GeminiService()
                    rag_service = WorkoutRAGService(gemini_service)

                    await rag_service.index_training_settings(
                        user_id=user_id,
                        action="update_training_preferences",
                        progression_pace=user.progression_pace,
                        training_split=user.training_split,
                        workout_type=user.workout_type_preference,
                    )
                    logger.info(f"📊 Indexed training settings to ChromaDB for user {user_id}")
                except Exception as rag_error:
                    logger.warning(f"⚠️ Could not index training settings to ChromaDB: {rag_error}", exc_info=True)

            # Index exercise variety/consistency settings to ChromaDB for AI context
            prefs = update_data.get("preferences", {})
            if isinstance(prefs, str):
                prefs = json.loads(prefs)

            has_exercise_variety_settings = any([
                prefs.get("exercise_consistency"),
                prefs.get("variation_percentage") is not None,
            ])

            if has_exercise_variety_settings:
                try:
                    from services.rag_service import WorkoutRAGService
                    from services.gemini_service import GeminiService

                    gemini_service = GeminiService()
                    rag_service = WorkoutRAGService(gemini_service)

                    await rag_service.index_training_settings(
                        user_id=user_id,
                        action="update_exercise_variety",
                        exercise_consistency=prefs.get("exercise_consistency"),
                        variation_percentage=prefs.get("variation_percentage"),
                    )
                    logger.info(f"📊 Indexed exercise variety settings to ChromaDB for user {user_id}")
                except Exception as rag_error:
                    logger.warning(f"⚠️ Could not index exercise variety settings to ChromaDB: {rag_error}", exc_info=True)
        else:
            updated = existing

        logger.info(f"User updated: id={user_id}")

        # Log user update
        await log_user_activity(
            user_id=user_id,
            action="user_updated",
            endpoint=f"/api/v1/users/{user_id}",
            message="User profile updated",
            metadata={"fields_updated": list(update_data.keys())},
            status_code=200
        )

        return row_to_user(updated)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update user: {e}", exc_info=True)
        await log_user_error(
            user_id=user_id,
            action="user_updated",
            error=e,
            endpoint=f"/api/v1/users/{user_id}",
            status_code=500
        )
        raise safe_internal_error(e, "users")


@router.delete("/{user_id}")
async def delete_user(user_id: str,
    body: Optional[DestructiveActionRequest] = Body(default=None),
    current_user: dict = Depends(get_current_user),
):
    """
    Delete a user. SECURITY: Requires password re-authentication for email-auth
    accounts. OAuth accounts (google/apple) authenticate via JWT alone, so the
    body is optional for them.
    """
    logger.info(f"Deleting user: id={user_id}")
    try:
        verify_user_ownership(current_user, user_id)

        # SECURITY: Re-authenticate before destructive action.
        # For OAuth users (Google/Apple), no password exists — JWT auth is sufficient.
        auth_provider = current_user.get("app_metadata", {}).get("provider", "email")
        if auth_provider == "email":
            if body is None or not body.password:
                raise HTTPException(status_code=400, detail="Password required for email accounts")
            supabase = get_supabase()
            try:
                supabase.auth_client.auth.sign_in_with_password({
                    "email": current_user["email"],
                    "password": body.password,
                })
            except Exception:
                raise HTTPException(status_code=401, detail="Invalid password — re-authentication required")
            finally:
                # CRITICAL: sign_in_with_password mutates the auth_client's
                # Authorization header to the user's JWT via supabase-py's
                # auth listener. The downstream admin.delete_user call needs
                # service_role, so drop the user session here to restore the
                # apikey header. Without this, admin returns 403 "User not
                # allowed" and the whole reset 500s.
                try:
                    supabase.auth_client.auth.sign_out()
                except Exception as _sign_out_err:
                    logger.warning(
                        "Failed to clear auth_client session after password verify: %s",
                        _sign_out_err,
                    )
        # For OAuth providers (google, apple, etc.), JWT auth via get_current_user() is sufficient

        db = get_supabase_db()

        # Check if user exists
        existing = db.get_user(user_id)
        if not existing:
            logger.warning(f"User not found for deletion: id={user_id}")
            raise HTTPException(status_code=404, detail="User not found")

        db.delete_user(user_id)
        logger.info(f"User deleted: id={user_id}")

        # Log user deletion
        await log_user_activity(
            user_id=user_id,
            action="user_deleted",
            endpoint=f"/api/v1/users/{user_id}",
            message="User account deleted",
            status_code=200
        )

        return {"message": "User deleted successfully"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to delete user: {e}", exc_info=True)
        await log_user_error(
            user_id=user_id,
            action="user_deleted",
            error=e,
            endpoint=f"/api/v1/users/{user_id}",
            status_code=500
        )
        raise safe_internal_error(e, "users")


@router.post("/{user_id}/reset-onboarding")
async def reset_onboarding(user_id: str,
    body: Optional[DestructiveActionRequest] = Body(default=None),
    current_user: dict = Depends(get_current_user),
):
    """
    Reset onboarding - clears workouts and resets onboarding status.

    SECURITY: Password re-auth gates this endpoint in the case that matters —
    an authenticated session on an unlocked phone wiping real user data.
    It is intentionally skipped in two cases where the password prompt would
    be pure friction:
      1) OAuth users (Google/Apple) have no password — the JWT is the credential.
      2) The pre-auth quiz screen legitimately calls this for a freshly-signed-in
         user whose `onboarding_completed == False` — there's no accumulated data
         to protect, and prompting for a password mid-onboarding is bad UX.
    """
    logger.info(f"Resetting onboarding for user: id={user_id}")
    try:
        verify_user_ownership(current_user, user_id)

        db = get_supabase_db()

        # Check if user exists first — we also need onboarding_completed below.
        existing = db.get_user(user_id)
        if not existing:
            logger.warning(f"User not found for onboarding reset: id={user_id}")
            raise HTTPException(status_code=404, detail="User not found")

        auth_provider = current_user.get("app_metadata", {}).get("provider", "email")
        onboarding_completed = bool(existing.get("onboarding_completed"))

        # Only require password re-auth for email users who have completed onboarding
        # (i.e., have real data that deserves a second confirmation).
        if auth_provider == "email" and onboarding_completed:
            password = body.password if body else None
            if not password:
                raise HTTPException(status_code=400, detail="Password required for email accounts")
            supabase = get_supabase()
            try:
                supabase.auth_client.auth.sign_in_with_password({
                    "email": current_user["email"],
                    "password": password,
                })
            except Exception:
                raise HTTPException(status_code=401, detail="Invalid password — re-authentication required")

        # Get workout IDs first
        workouts = db.list_workouts(user_id, limit=1000)
        workout_ids = [w["id"] for w in workouts]

        # Get workout_log IDs
        logs = db.list_workout_logs(user_id, limit=1000)
        log_ids = [log["id"] for log in logs]

        # Delete performance_logs by workout_log IDs
        for log_id in log_ids:
            db.delete_performance_logs_by_workout_log(log_id)

        # Delete workout_logs
        db.delete_workout_logs_by_user(user_id)

        # Delete workout_changes by workout IDs
        for workout_id in workout_ids:
            db.delete_workout_changes_by_workout(workout_id)

        # Delete workouts
        for workout_id in workout_ids:
            db.delete_workout(workout_id)

        # Delete achievements and streaks
        try:
            db.client.table("user_achievements").delete().eq("user_id", user_id).execute()
            db.client.table("user_streaks").delete().eq("user_id", user_id).execute()
        except Exception as e:
            logger.warning(f"Could not delete achievements/streaks: {e}", exc_info=True)

        # Reset onboarding status
        db.update_user(user_id, {
            "onboarding_completed": False,
            "onboarding_conversation": None,
            "onboarding_conversation_completed_at": None
        })

        logger.info(f"Onboarding reset complete for user {user_id}")

        # Return updated user
        updated_user = db.get_user(user_id)
        return row_to_user(updated_user)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to reset onboarding: {e}", exc_info=True)
        raise safe_internal_error(e, "users")


@router.delete("/{user_id}/reset")
async def full_reset(user_id: str,
    background_tasks: BackgroundTasks,
    body: Optional[DestructiveActionRequest] = Body(default=None),
    current_user: dict = Depends(get_current_user),
):
    """
    Full reset - delete ALL user data and return to fresh state.
    SECURITY: Requires password re-authentication for email-auth accounts.
    OAuth accounts (google/apple) authenticate via JWT alone, so the body is
    optional for them.

    This deletes (in order to respect FK constraints):
    1. performance_logs (via workout_logs)
    2. workout_logs
    3. workout_changes
    4. workouts
    5. strength_records
    6. weekly_volumes
    7. injuries
    8. injury_history
    9. user_metrics
    10. chat_history
    11. user record itself
    """
    logger.info(f"Full reset for user: id={user_id}")
    try:
        verify_user_ownership(current_user, user_id)

        # SECURITY: Re-authenticate before destructive action
        # For OAuth users (Google), password is not available — JWT auth is sufficient
        auth_provider = current_user.get("app_metadata", {}).get("provider", "email")
        if auth_provider == "email":
            if body is None or not body.password:
                raise HTTPException(status_code=400, detail="Password required for email accounts")
            supabase = get_supabase()
            try:
                supabase.auth_client.auth.sign_in_with_password({
                    "email": current_user["email"],
                    "password": body.password,
                })
            except Exception:
                raise HTTPException(status_code=401, detail="Invalid password — re-authentication required")
            finally:
                # CRITICAL: sign_in_with_password mutates the auth_client's
                # Authorization header to the user's JWT via supabase-py's
                # auth listener. The downstream admin.delete_user call needs
                # service_role, so drop the user session here to restore the
                # apikey header. Without this, admin returns 403 "User not
                # allowed" and the whole reset 500s.
                try:
                    supabase.auth_client.auth.sign_out()
                except Exception as _sign_out_err:
                    logger.warning(
                        "Failed to clear auth_client session after password verify: %s",
                        _sign_out_err,
                    )
        # For OAuth providers (google, apple, etc.), JWT auth via get_current_user() is sufficient

        db = get_supabase_db()

        # Check if user exists
        existing = db.get_user(user_id)
        if not existing:
            logger.warning(f"User not found for reset: id={user_id}")
            raise HTTPException(status_code=404, detail="User not found")

        # Run the security-critical path inline (DB cascade + auth delete)
        # so the user's JWT is invalidated before we return. Defer the
        # storage purge to a BackgroundTask — orphaned blobs are recoverable
        # and shaving the storage round-trips off the hot path makes the
        # app-side flow ~1-3s faster, which is what users perceive.
        #
        # Pass auth_id explicitly so the auth deletion uses the Supabase Auth
        # UUID, not the public.users.id (they diverge for OAuth users). Without
        # this, admin.delete_user runs against the wrong UUID, leaving the auth
        # row orphaned — and every JWT issued for that auth row then 401s with
        # "User from sub claim in JWT does not exist", bricking the user's app.
        try:
            db.full_user_reset(
                user_id,
                skip_storage=True,
                auth_id=current_user.get("auth_id"),
            )
        except Exception as reset_err:
            # Auth-deletion failure now aborts BEFORE public.users is removed
            # (see facade.full_user_reset). Surface the cause so ops can fix
            # the underlying issue (almost always: SUPABASE_KEY is not the
            # service_role secret).
            logger.error(
                "full_reset aborted for user %s — both auth and public.users "
                "rows left intact: %s",
                user_id, reset_err, exc_info=True,
            )
            raise HTTPException(
                status_code=500,
                detail=(
                    "Account deletion could not be completed. Both your account "
                    "data and login remain intact. Please try again or contact "
                    "support if this persists."
                ),
            )
        background_tasks.add_task(db.purge_user_storage_async, user_id)
        logger.info(f"Full reset complete for user {user_id} (storage purge queued)")

        return {
            "message": "Full reset successful. All user data has been deleted.",
            "user_id": user_id
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to reset user: {e}", exc_info=True)
        raise safe_internal_error(e, "users")


# ============================================================
# WEEK-1 COHORT (migration 1939 / W2)
# ============================================================

from pydantic import BaseModel as _BaseModelCohort


class CohortResponse(_BaseModelCohort):
    is_week_1: bool
    day_number: int  # days since first_workout_completed_at (or created_at if null)
    first_workout_at: Optional[str] = None
    created_at: Optional[str] = None


@router.get("/me/cohort", response_model=CohortResponse)
async def get_my_cohort(current_user: dict = Depends(get_current_user)):
    """
    Return the user's week-1 cohort state.
    Used by Flutter to conditionally surface week-1 UI (home rank card,
    share prompts, forecast sheet triggers) for users in their first 7 days.
    """
    try:
        db = get_supabase_db()
        user_id = current_user["id"]

        result = db.client.table("users") \
            .select("created_at,first_workout_completed_at") \
            .eq("id", user_id).limit(1).execute()

        if not result.data:
            return CohortResponse(is_week_1=False, day_number=0)

        row = result.data[0]
        created_at = row.get("created_at")
        first_workout_at = row.get("first_workout_completed_at")

        # Call the SQL RPC for authoritative week-1 answer
        rpc = db.client.rpc("is_week_1_user", {"p_user_id": user_id}).execute()
        is_week_1 = bool(rpc.data) if rpc.data is not None else False

        # Compute day_number from the most relevant anchor
        day_number = 0
        try:
            anchor_str = first_workout_at or created_at
            if anchor_str:
                anchor = datetime.fromisoformat(anchor_str.replace("Z", "+00:00"))
                day_number = max((datetime.now(anchor.tzinfo) - anchor).days, 0)
        except Exception:
            day_number = 0

        return CohortResponse(
            is_week_1=is_week_1,
            day_number=day_number,
            first_workout_at=first_workout_at,
            created_at=created_at,
        )
    except Exception as e:
        raise safe_internal_error(e, "users")


# ─── Privacy settings (leaderboard visibility) ─────────────────────────────
# Backs the three toggles on the Profile → Privacy section.
# Columns added in migration 1941. Leaderboard RPCs in migration 1942 respect them.

class PrivacySettings(_BaseModelCohort):
    show_on_leaderboard: bool
    leaderboard_anonymous: bool
    profile_stats_visible: bool


@router.get("/me/privacy", response_model=PrivacySettings)
async def get_my_privacy(current_user: dict = Depends(get_current_user)):
    """Return the current user's leaderboard privacy flags."""
    try:
        db = get_supabase_db()
        res = db.client.table("users") \
            .select("show_on_leaderboard,leaderboard_anonymous,profile_stats_visible") \
            .eq("id", current_user["id"]).limit(1).execute()
        if not res.data:
            # Defaults match migration 1941
            return PrivacySettings(
                show_on_leaderboard=True,
                leaderboard_anonymous=False,
                profile_stats_visible=True,
            )
        row = res.data[0]
        return PrivacySettings(
            show_on_leaderboard=bool(row.get("show_on_leaderboard", True)),
            leaderboard_anonymous=bool(row.get("leaderboard_anonymous", False)),
            profile_stats_visible=bool(row.get("profile_stats_visible", True)),
        )
    except Exception as e:
        raise safe_internal_error(e, "users")


@router.put("/me/privacy", response_model=PrivacySettings)
async def update_my_privacy(
    body: PrivacySettings,
    current_user: dict = Depends(get_current_user),
):
    """Update the current user's leaderboard privacy flags."""
    try:
        db = get_supabase_db()
        db.client.table("users").update({
            "show_on_leaderboard":   body.show_on_leaderboard,
            "leaderboard_anonymous": body.leaderboard_anonymous,
            "profile_stats_visible": body.profile_stats_visible,
        }).eq("id", current_user["id"]).execute()
        return body
    except Exception as e:
        raise safe_internal_error(e, "users")


# ─── PATCH /me — partial profile update ───────────────────────────────────
# Why this exists:
#   The Flutter app PATCHes /users/me with small partial bodies (commitment
#   pact accept/skip, future settings toggles). We previously only had
#   PUT /users/{id}, which 405'd on PATCH and forced callers to know their
#   own UUID. This handler accepts an arbitrary JSON dict, filters it
#   against an allowlist of user-mutable columns, and writes through to the
#   same `users` table the PUT route ultimately updates.
#
# Why not reuse update_user() directly:
#   update_user() is bound to the strongly-typed UserUpdate Pydantic model,
#   which doesn't model the smaller "diary-style" fields like
#   commitment_pact_accepted / commitment_pact_accepted_at. Adding every
#   new boolean toggle to UserUpdate is high-friction. PATCH /me takes an
#   open dict and validates against a column allowlist — same DB write
#   path (db.client.table("users").update(...)), no regression risk to the
#   typed PUT contract.
_PATCH_ME_ALLOWED_FIELDS: set = {
    # Commitment pact (onboarding behaviour signal)
    "commitment_pact_accepted",
    "commitment_pact_accepted_at",
    # Founder note seen flag
    "seen_founder_note",
    # Lightweight UI flags users toggle from settings
    "renewal_banner_dismissed_until",
    "last_celebration_ack_at",
    # Notification + privacy toggles already exposed elsewhere but safe to
    # patch here too so settings can use a single endpoint.
    "billing_notifications_enabled",
    "show_on_leaderboard",
    "leaderboard_anonymous",
    "profile_stats_visible",
    "share_favorite_templates",
    "share_template_order",
    # Timezone — set once on app open if device timezone changed.
    "timezone",
    # Trial / paywall state mirrors written by client-side IAP listeners.
    "paywall_completed",
    "trial_start_date",
}


@router.patch("/me")
async def patch_me(
    body: dict = Body(...),
    current_user: dict = Depends(get_current_user),
):
    """
    Partial update of the current user's row. Accepts a flat JSON dict;
    silently drops unknown / non-allowlisted keys so a forward-compatible
    client (sending a field this version doesn't know about) doesn't 4xx.

    Returns the keys that were actually written so the caller can verify.
    """
    if not isinstance(body, dict):
        raise HTTPException(status_code=400, detail="body must be a JSON object")

    # Filter against allowlist — silent drop, not 400, so older backends
    # tolerate newer clients sending fields they don't yet recognise
    # (e.g. commitment_pact_skipped_at — not yet a column, frontend already
    # sends it inside a try/except).
    update_data = {k: v for k, v in body.items() if k in _PATCH_ME_ALLOWED_FIELDS}
    dropped = [k for k in body.keys() if k not in _PATCH_ME_ALLOWED_FIELDS]
    if dropped:
        logger.info(
            "[PATCH /me] user %s — dropped unknown fields: %s",
            current_user.get("id"),
            dropped,
        )

    if not update_data:
        # Nothing to write, but the request itself is valid.
        return {"updated_fields": [], "dropped_fields": dropped}

    try:
        db = get_supabase_db()
        db.client.table("users").update(update_data).eq(
            "id", current_user["id"]
        ).execute()
        logger.info(
            "[PATCH /me] user %s updated fields: %s",
            current_user.get("id"),
            list(update_data.keys()),
        )
        return {
            "updated_fields": list(update_data.keys()),
            "dropped_fields": dropped,
        }
    except Exception as e:
        logger.error(
            f"PATCH /me failed for user {current_user.get('id')}: {e}",
            exc_info=True,
        )
        raise safe_internal_error(e, "users")


@router.post("/me/fitness-snapshot")
async def take_my_fitness_snapshot(
    current_user: dict = Depends(get_current_user),
):
    """
    Capture the current user's fitness shape for today (idempotent upsert).
    Called by Flutter on app-open with a client-side 1x/day debounce via
    SharedPreferences. Replaces the external daily cron — no scheduler needed
    because inactive users don't need snapshots (they're not on leaderboards).
    """
    try:
        db = get_supabase_db()
        user_id = current_user["id"]

        # Compute all six scores for today via the helpers from migration 1943.
        # One round-trip: call get_user_fitness_profile(self, self) and upsert.
        profile_res = db.client.rpc(
            "get_user_fitness_profile",
            {"p_target_user_id": user_id, "p_viewer_user_id": user_id},
        ).execute()
        row = profile_res.data[0] if isinstance(profile_res.data, list) and profile_res.data else (profile_res.data or {})

        def _f(key: str) -> float:
            v = row.get(key)
            return 0.0 if v is None else float(v)

        from datetime import date as _date
        today = _date.today().isoformat()

        db.client.table("fitness_profile_snapshots").upsert({
            "user_id": user_id,
            "snapshot_date": today,
            "strength":    _f("target_strength"),
            "muscle":      _f("target_muscle"),
            "recovery":    _f("target_recovery"),
            "consistency": _f("target_consistency"),
            "endurance":   _f("target_endurance"),
            "nutrition":   _f("target_nutrition"),
        }, on_conflict="user_id,snapshot_date").execute()

        return {"ok": True, "date": today}
    except Exception as e:
        raise safe_internal_error(e, "users")
