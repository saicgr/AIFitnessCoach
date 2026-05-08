"""
Idempotent QA-user seed for the workout-generation validation harness.

Creates (or updates) one synthetic user + one active gym profile so the
harness has a stable target. Run it BEFORE validate_workout_generation.py.

Usage:
    cd backend && .venv/bin/python scripts/seed_qa_user.py

Notes:
- Uses the service-role Supabase client; bypasses RLS.
- UUID is hardcoded so the seed is fully deterministic / idempotent.
- We do NOT create an auth.users row. This synthetic user only needs the
  public.users + public.gym_profiles rows the generator reads.
"""
import json
import os
import sys
from datetime import datetime

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.supabase_client import get_supabase  # noqa: E402

# Deterministic UUID — never change. The harness imports this constant.
QA_USER_UUID = "00000000-0000-0000-0000-0000000000aa"
QA_GYM_PROFILE_ID = "00000000-0000-0000-0000-0000000000bb"
QA_EMAIL = "qa-validation+harness@zealova.invalid"


def _user_payload() -> dict:
    """Full preferences for a 30 y/o intermediate male, kg/cm, full gym."""
    prefs = {
        "days_per_week": 4,
        "workout_duration": 45,
        "training_split": "push_pull_legs",
        "intensity_preference": "medium",
        "preferred_time": "evening",
        "progression_pace": "medium",
        "workout_type_preference": "strength",
        "warmup_duration_minutes": 5,
        "stretch_duration_minutes": 5,
        "weight_unit": "kg",
        "workout_environment": "commercial_gym",
    }
    return {
        "id": QA_USER_UUID,
        "email": QA_EMAIL,
        "name": "QA Harness User",
        "fitness_level": "intermediate",
        "goals": json.dumps(["strength", "hypertrophy"]),
        "equipment": json.dumps(
            ["barbell", "dumbbells", "cable_machine", "bench", "pull_up_bar"]
        ),
        "custom_equipment": "[]",
        "preferences": json.dumps(prefs),
        "active_injuries": "[]",
        "onboarding_completed": True,
        "coach_selected": True,
        "paywall_completed": True,
        "age": 30,
        "gender": "male",
        "height_cm": 178.0,
        "weight_kg": 78.0,
        "target_weight_kg": 75.0,
        "activity_level": "moderately_active",
        "timezone": "America/Chicago",
        "weight_unit": "kg",
        "measurement_unit": "cm",
        "primary_goal": "strength_hypertrophy",
    }


def _gym_profile_payload() -> dict:
    return {
        "id": QA_GYM_PROFILE_ID,
        "user_id": QA_USER_UUID,
        "name": "QA Full Gym",
        "icon": "fitness_center",
        "color": "#00BCD4",
        "equipment": [
            "barbell", "dumbbells", "cable_machine", "squat_rack", "bench",
            "pull_up_bar", "kettlebell", "leg_press_machine",
            "lat_pulldown", "smith_machine",
        ],
        "equipment_details": [],
        "workout_environment": "commercial_gym",
        "training_split": "push_pull_legs",
        "workout_days": [0, 2, 4, 5],
        "duration_minutes": 45,
        "goals": ["strength", "hypertrophy"],
        "focus_areas": [],
        "is_active": True,
        "display_order": 0,
    }


def main() -> None:
    db = get_supabase().client

    # User upsert (Postgres ON CONFLICT id) — service-role bypasses RLS.
    user_data = _user_payload()
    existing = db.table("users").select("id").eq("id", QA_USER_UUID).execute()
    if existing.data:
        # `created_at` is set on insert only; don't overwrite on update.
        db.table("users").update(user_data).eq("id", QA_USER_UUID).execute()
        print(f"[seed_qa_user] Updated existing QA user {QA_USER_UUID}")
    else:
        user_data["created_at"] = datetime.utcnow().isoformat()
        db.table("users").insert(user_data).execute()
        print(f"[seed_qa_user] Inserted new QA user {QA_USER_UUID}")

    # Gym profile upsert. Same idempotent pattern.
    gp = _gym_profile_payload()
    existing_gp = (
        db.table("gym_profiles").select("id").eq("id", QA_GYM_PROFILE_ID).execute()
    )
    if existing_gp.data:
        db.table("gym_profiles").update(gp).eq("id", QA_GYM_PROFILE_ID).execute()
        print(f"[seed_qa_user] Updated existing QA gym_profile {QA_GYM_PROFILE_ID}")
    else:
        db.table("gym_profiles").insert(gp).execute()
        print(f"[seed_qa_user] Inserted new QA gym_profile {QA_GYM_PROFILE_ID}")

    print(f"\n✅ Seeded user {QA_USER_UUID}")
    print(f"   gym_profile: {QA_GYM_PROFILE_ID}")


if __name__ == "__main__":
    main()
