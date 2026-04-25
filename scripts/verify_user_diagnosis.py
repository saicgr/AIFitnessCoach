#!/usr/bin/env python3
"""
One-shot diagnostic dump for saichetangrandhe@gmail.com / digithat123@gmail.com.

Reads the user's profile + nutrition prefs + today's food/hydration logs +
any dead-letter sync rows directly from Supabase via the project's own
DATABASE_URL. Output is structured JSON suitable for pasting back to verify
the calorie/scoring/sync fixes will actually resolve the user's account.

Run from project root:
    cd backend && python3 ../scripts/verify_user_diagnosis.py
"""
from __future__ import annotations

import json
import os
import sys
from datetime import datetime, timezone, timedelta

import psycopg2
from psycopg2.extras import RealDictCursor
from dotenv import load_dotenv

EMAILS = ("saichetangrandhe@gmail.com", "digithat123@gmail.com")
USER_TZ_OFFSET_HOURS = -5  # CST (CDT in summer would be -5; UTC-5 either way today)


def _serialize(obj):
    if isinstance(obj, datetime):
        return obj.isoformat()
    if hasattr(obj, "isoformat"):
        return obj.isoformat()
    return str(obj)


def _print(label: str, data) -> None:
    print(f"\n=== {label} ===")
    print(json.dumps(data, indent=2, default=_serialize))


def main() -> int:
    load_dotenv()
    url = os.environ.get("DATABASE_URL", "").replace(
        "postgresql+asyncpg://", "postgresql://"
    )
    if not url:
        print("ERROR: DATABASE_URL not in env. Run from backend/ dir.", file=sys.stderr)
        return 1

    conn = psycopg2.connect(url, cursor_factory=RealDictCursor)
    cur = conn.cursor()

    # 1. Discover users by email + their last sign-in for tie-breaking.
    cur.execute(
        """
        SELECT id, email, last_sign_in_at, created_at
        FROM auth.users
        WHERE email = ANY(%s)
        ORDER BY last_sign_in_at DESC NULLS LAST
        """,
        (list(EMAILS),),
    )
    users = cur.fetchall()
    _print("AUTH USERS MATCHING EMAILS", users)

    if not users:
        print("\nNo users matched. Done.")
        return 0

    primary = users[0]
    user_id = str(primary["id"])
    print(f"\n>>> Using primary user_id={user_id} (email={primary['email']})")

    # 2. Discover columns on users + nutrition_preferences so the SELECT *
    #    below doesn't crash on schema drift.
    cur.execute(
        """
        SELECT column_name FROM information_schema.columns
        WHERE table_schema='public' AND table_name='users'
        """
    )
    user_cols = {r["column_name"] for r in cur.fetchall()}
    cur.execute(
        """
        SELECT column_name FROM information_schema.columns
        WHERE table_schema='public' AND table_name='nutrition_preferences'
        """
    )
    pref_cols = {r["column_name"] for r in cur.fetchall()}

    # 3. Profile from public.users (best-effort — only select columns we
    #    care about that actually exist).
    desired_user = [
        "id", "email", "name", "age", "gender", "activity_level",
        "weight_kg", "height_cm", "target_weight_kg", "weight_lbs",
        "height_cm", "timezone", "pinned_nutrients", "pinned_nutrients_mode",
    ]
    select_user = [c for c in desired_user if c in user_cols]
    if select_user:
        cur.execute(
            f"SELECT {', '.join(select_user)} FROM public.users WHERE id = %s::uuid",
            (user_id,),
        )
        _print("PUBLIC.USERS PROFILE", cur.fetchone())

    # 4. Nutrition prefs.
    desired_pref = [
        "user_id", "nutrition_goal", "rate_of_change", "diet_type",
        "calculated_bmr", "calculated_tdee", "target_calories",
        "target_protein_g", "target_carbs_g", "target_fat_g",
        "custom_protein_percent", "custom_carbs_percent", "custom_fat_percent",
        "last_recalculated_at", "nutrition_onboarding_completed",
    ]
    select_pref = [c for c in desired_pref if c in pref_cols]
    if select_pref:
        cur.execute(
            f"SELECT {', '.join(select_pref)} FROM public.nutrition_preferences WHERE user_id = %s::uuid",
            (user_id,),
        )
        _print("NUTRITION_PREFERENCES", cur.fetchone())

    # 5. Today's food_log entries (CST window = 05:00 → 05:00 UTC for the
    #    user's local day).
    user_local_now = datetime.utcnow() + timedelta(hours=USER_TZ_OFFSET_HOURS)
    local_midnight = user_local_now.replace(hour=0, minute=0, second=0, microsecond=0)
    start_utc = local_midnight - timedelta(hours=USER_TZ_OFFSET_HOURS)
    end_utc = start_utc + timedelta(days=1)

    cur.execute(
        """
        SELECT id, meal_type, total_calories, protein_g, carbs_g, fat_g,
               inflammation_score, fodmap_rating, glycemic_load, added_sugar_g,
               is_ultra_processed, sodium_mg, vitamin_d_iu, vitamin_c_mg,
               score_status, source_type, input_type, logged_at, deleted_at
        FROM public.food_logs
        WHERE user_id = %s::uuid
          AND deleted_at IS NULL
          AND logged_at >= %s
          AND logged_at < %s
        ORDER BY logged_at DESC
        """,
        (user_id, start_utc.isoformat(), end_utc.isoformat()),
    )
    food_rows = cur.fetchall()
    _print(f"TODAY'S FOOD_LOGS (UTC window {start_utc} → {end_utc})", food_rows)

    # 6. Today's hydration_logs.
    cur.execute(
        """
        SELECT id, drink_type, amount_ml, workout_id, source, notes, logged_at
        FROM public.hydration_logs
        WHERE user_id = %s::uuid
          AND logged_at >= %s
          AND logged_at < %s
        ORDER BY logged_at DESC
        """,
        (user_id, start_utc.isoformat(), end_utc.isoformat()),
    )
    hyd_rows = cur.fetchall()
    _print("TODAY'S HYDRATION_LOGS", hyd_rows)

    # 7. Any pending_sync_queue / dead_letter rows on the server side
    #    (probably empty — the sync queue is local Drift, not Supabase —
    #    but check just in case there's a server-side mirror).
    cur.execute(
        """
        SELECT table_name FROM information_schema.tables
        WHERE table_schema = 'public'
          AND table_name LIKE '%sync%'
        """
    )
    sync_tables = [r["table_name"] for r in cur.fetchall()]
    print(f"\nServer-side sync tables: {sync_tables}")

    # 8. Anomaly summary — what we'd flag for the user.
    print("\n=== ANOMALY FLAGS ===")
    flags = []
    if select_pref:
        cur.execute(
            "SELECT target_calories, rate_of_change, calculated_tdee FROM public.nutrition_preferences WHERE user_id = %s::uuid",
            (user_id,),
        )
        prefs = cur.fetchone()
        if prefs:
            tc = prefs.get("target_calories") or 0
            roc = prefs.get("rate_of_change")
            tdee = prefs.get("calculated_tdee") or 0
            if roc == "aggressive" and tc and tdee:
                expected_deficit = 1100  # 1.0 kg/wk * 7700 / 7
                actual_deficit = tdee - tc
                flags.append(
                    f"Aggressive rate (1.0 kg/wk) selected: stored target={tc}, "
                    f"TDEE={tdee}, actual deficit={actual_deficit} cal/d "
                    f"(should be ~{expected_deficit} → expected target ~{tdee - expected_deficit})"
                )
    if food_rows:
        no_score = sum(
            1
            for r in food_rows
            if r.get("inflammation_score") is None
            and r.get("fodmap_rating") is None
            and r.get("glycemic_load") is None
        )
        if no_score:
            flags.append(
                f"{no_score}/{len(food_rows)} of today's food_logs have no scoring fields "
                "→ Issue 3 enrichment will backfill these on next /log-direct write or via batch backfill"
            )
    if hyd_rows:
        unsourced = sum(1 for r in hyd_rows if r.get("source") in (None, "manual"))
        flags.append(
            f"{unsourced}/{len(hyd_rows)} hydration entries have null/manual source "
            "→ Issue 4 backfills as 'manual'; new logs will carry surface tags"
        )
    if flags:
        for f in flags:
            print(f"  • {f}")
    else:
        print("  No anomalies detected (matches expected post-fix state).")

    cur.close()
    conn.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
