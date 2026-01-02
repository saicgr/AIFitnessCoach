"""
Backfill user columns from preferences JSON.

This script migrates weight_kg, height_cm, gender, and name from the preferences
JSON column to their dedicated database columns for users who completed onboarding
before the fix was applied.

Usage:
    python scripts/backfill_user_columns.py

Environment variables:
    SUPABASE_URL - Supabase project URL
    SUPABASE_SERVICE_KEY - Supabase service role key (not anon key)
"""

import json
import os
import sys

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.supabase_client import get_supabase


def backfill_user_columns():
    """Migrate preferences JSON fields to dedicated columns."""
    db = get_supabase().client

    # Get all users with preferences but missing column values
    response = db.table("users").select(
        "id, name, gender, height_cm, weight_kg, target_weight_kg, preferences"
    ).eq("onboarding_completed", True).execute()

    if not response.data:
        print("No users found with completed onboarding")
        return

    updated_count = 0
    skipped_count = 0

    for user in response.data:
        user_id = user["id"]
        prefs = user.get("preferences")

        # Parse preferences JSON
        if isinstance(prefs, str):
            try:
                prefs = json.loads(prefs)
            except (json.JSONDecodeError, TypeError):
                prefs = {}
        elif not isinstance(prefs, dict):
            prefs = {}

        if not prefs:
            skipped_count += 1
            continue

        # Build update dict with missing values from preferences
        update_data = {}

        if user.get("name") is None and prefs.get("name"):
            update_data["name"] = prefs["name"]

        if user.get("gender") is None and prefs.get("gender"):
            update_data["gender"] = prefs["gender"]

        if user.get("height_cm") is None and prefs.get("height_cm"):
            update_data["height_cm"] = prefs["height_cm"]

        if user.get("weight_kg") is None and prefs.get("weight_kg"):
            update_data["weight_kg"] = prefs["weight_kg"]

        if user.get("target_weight_kg") is None and prefs.get("target_weight_kg"):
            update_data["target_weight_kg"] = prefs["target_weight_kg"]

        if update_data:
            print(f"Updating user {user_id}: {list(update_data.keys())}")
            db.table("users").update(update_data).eq("id", user_id).execute()
            updated_count += 1
        else:
            skipped_count += 1

    print(f"\nDone! Updated {updated_count} users, skipped {skipped_count}")


if __name__ == "__main__":
    backfill_user_columns()
