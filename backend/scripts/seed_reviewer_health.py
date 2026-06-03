"""
Seed / tear down realistic demo health data for the App Store / Play
**reviewer account** so the new sleep & health features are reviewable
(and screenshot-able) WITHOUT a paired wearable.

Why this exists
---------------
App Store / Play reviewers cannot pair a wearable, and Health Connect /
HealthKit do not run on emulators — so the new health UI (Sleep detail
screen, Combined Health hub, the home health cards, the AI coach's health
context) shows empty for them. This is a standard *disclosed* demo account,
NOT deception: the reviewer signs into `reviewer@zealova.com` and the
backend serves pre-seeded `daily_activity` rows; the Flutter app reads
those rows for this one account via `demoHealthModeProvider`.

Scope guarantee
---------------
This script ONLY ever touches the single reviewer user
(`d8f9677f-3cda-413b-8df7-0bb0035f69b1`):
  * ``--seed``   writes ~45 days of varied `daily_activity` rows ending
                 *yesterday* (user-local-ish; the rows are date-keyed),
                 sets `user_ai_settings.health_data_consent = true`, and
                 upserts a `health_goals` row.
  * ``--delete`` removes exactly the seeded `daily_activity` rows (the
                 contiguous 45-day window ending yesterday) and, with
                 ``--reset-goals``, deletes the `health_goals` row. It
                 never touches any other user or table.

Realism
-------
The founder explicitly does NOT want fake-looking data. A fixed RNG seed
keeps re-runs byte-stable, but every metric is *varied*, not flat or
round:
  * Sleep total mostly 6h20m-7h50m, with 5-6 genuinely poor nights
    (5h00m-5h55m) and several good ones (7h50m-8h30m); weekend nights
    run slightly longer.
  * Per-night stages: deep ~13-20 %, REM ~20-26 %, light = remainder,
    plus 12-45 min awake-in-bed.
  * sleep_start 22:15-00:45, sleep_end 05:45-08:15, latency 6-32 min,
    efficiency 0.82-0.95.
  * steps 2,500-15,000 with realistic scatter (a couple of low rest
    days); calories correlate with steps.
  * resting_heart_rate 50-63 with one 2-3 day elevated stretch
    (+5-8 bpm) so the anomaly feature has a real signal.
  * water_ml 900-2,900.
  * The most recent 1-2 nights are deliberately a moderately poor night
    so the recovery-aware briefing visibly does something.
  * A subtle correlation (poorer sleep -> slightly fewer steps next day)
    so the smart-insights engine can surface a real pair.

Usage
-----
    backend/.venv/bin/python scripts/seed_reviewer_health.py --seed
    backend/.venv/bin/python scripts/seed_reviewer_health.py --delete
    backend/.venv/bin/python scripts/seed_reviewer_health.py --delete --reset-goals

Environment: read from ``backend/.env`` (SUPABASE_URL + SUPABASE_KEY /
SUPABASE_SERVICE_KEY). The repo grants standing approval to run admin
scripts this way.
"""
from __future__ import annotations

import argparse
import os
import random
import sys
from datetime import date, datetime, time, timedelta
from pathlib import Path

from dotenv import load_dotenv
from supabase import Client, create_client

# --------------------------------------------------------------------------
# Config
# --------------------------------------------------------------------------
BACKEND = Path(__file__).resolve().parent.parent
load_dotenv(BACKEND / ".env")

# The ONLY account that ever receives demo behaviour. Mirrors the
# `demoHealthModeProvider` allowlist in the Flutter app.
REVIEWER_USER_ID = "d8f9677f-3cda-413b-8df7-0bb0035f69b1"
REVIEWER_EMAIL = "reviewer@zealova.com"

# Number of days of history to seed. Covers the Sleep detail screen's
# 35-night window, the Combined Health hub's 35-day window, the 14-night
# sleep-debt window, and the >=14-night monthly-summary gate, all with a
# comfortable margin.
SEED_DAYS = 45

# Base RNG seed for byte-stable per-run output. Rolled forward whenever the
# demo numbers need refreshing (the most-recent day is otherwise deterministic
# and would repeat the same "today" value on every reseed).
RNG_SEED = 20260602

# Demo data source tag — distinguishes seeded rows from any real
# health_connect / apple_health rows. Used by --delete as a safety belt.
DEMO_SOURCE = "reviewer_demo"


def _supabase() -> Client:
    url = os.environ.get("SUPABASE_URL")
    # Prefer the service-role key so we bypass RLS for the upserts/deletes.
    key = os.environ.get("SUPABASE_SERVICE_KEY") or os.environ.get("SUPABASE_KEY")
    if not url or not key:
        print("❌ SUPABASE_URL / SUPABASE_KEY missing from backend/.env")
        sys.exit(1)
    return create_client(url, key)


# --------------------------------------------------------------------------
# Realistic data generation
# --------------------------------------------------------------------------
def _build_seed_rows() -> list[dict]:
    """Build ~SEED_DAYS realistic `daily_activity` rows ending yesterday.

    Returns rows newest-LAST (chronological) — order does not matter for the
    upsert but it keeps the correlation logic readable.
    """
    rng = random.Random(RNG_SEED)
    today = date.today()
    # Window ends TODAY (inclusive) so the reviewer/demo always has a CURRENT
    # row for the current date — never a stale past row presented as "today".
    # Run daily (cron) so the window slides forward and today is always fresh.
    start = today - timedelta(days=SEED_DAYS - 1)

    # Pick 5-6 genuinely poor nights and several good nights up front so the
    # distribution is controlled rather than emergent. Indices are day
    # offsets 0..SEED_DAYS-1 (0 = oldest).
    all_idx = list(range(SEED_DAYS))
    rng.shuffle(all_idx)
    poor_nights = set(all_idx[:6])          # 6 genuinely poor nights
    good_nights = set(all_idx[6:13])        # 7 good nights
    # Force the most recent 1-2 nights to be a moderately poor night so the
    # recovery-aware briefing visibly does something for the reviewer.
    poor_nights.discard(SEED_DAYS - 1)
    poor_nights.discard(SEED_DAYS - 2)
    good_nights.discard(SEED_DAYS - 1)
    good_nights.discard(SEED_DAYS - 2)
    moderately_poor = {SEED_DAYS - 1, SEED_DAYS - 2}

    # One 2-3 day elevated-RHR stretch (a mild illness / poor recovery
    # signal) somewhere in the middle third of the window.
    elevated_start = rng.randint(SEED_DAYS // 3, SEED_DAYS // 3 + SEED_DAYS // 3)
    elevated_len = rng.choice([2, 3])
    elevated_days = set(range(elevated_start, elevated_start + elevated_len))

    rows: list[dict] = []
    prev_sleep_minutes: int | None = None

    for i in range(SEED_DAYS):
        d = start + timedelta(days=i)
        is_weekend = d.weekday() >= 5  # Sat=5, Sun=6

        # --- Sleep total -------------------------------------------------
        if i in poor_nights:
            # Genuinely poor: 5h00m - 5h55m
            sleep_minutes = rng.randint(300, 355)
        elif i in moderately_poor:
            # Moderately poor recent nights: 5h40m - 6h25m
            sleep_minutes = rng.randint(340, 385)
        elif i in good_nights:
            # Good night: 7h50m - 8h30m
            sleep_minutes = rng.randint(470, 510)
        else:
            # Typical night: 6h20m - 7h50m
            sleep_minutes = rng.randint(380, 470)
        # Weekend nights run slightly longer (catch-up sleep).
        if is_weekend:
            sleep_minutes += rng.randint(10, 35)
        # Tiny jitter so no two nights are an exact round-number match.
        sleep_minutes += rng.randint(-7, 7)
        sleep_minutes = max(290, min(sleep_minutes, 540))

        # --- Stage split -------------------------------------------------
        # deep ~13-20 %, REM ~20-26 %, light = remainder.
        deep_frac = rng.uniform(0.13, 0.20)
        rem_frac = rng.uniform(0.20, 0.26)
        deep_minutes = round(sleep_minutes * deep_frac)
        rem_minutes = round(sleep_minutes * rem_frac)
        light_minutes = sleep_minutes - deep_minutes - rem_minutes
        if light_minutes < 0:
            # Defensive: pull from REM if rounding overshot.
            rem_minutes += light_minutes
            light_minutes = 0
        # Awake-in-bed 12-45 min — poorer nights skew toward more awake time.
        if i in poor_nights or i in moderately_poor:
            awake_minutes = rng.randint(28, 45)
        else:
            awake_minutes = rng.randint(12, 30)

        # --- Sleep window ------------------------------------------------
        # sleep_start 22:15 - 00:45 (clock minutes-from-22:00, 0..165).
        start_offset = rng.randint(15, 165)
        if is_weekend:
            start_offset += rng.randint(10, 40)  # later weekend bedtime
        bed_hour = (22 + start_offset // 60) % 24
        bed_minute = start_offset % 60
        # The bed datetime is on the PREVIOUS calendar date when after
        # midnight it would be on `d` itself; we anchor it so sleep_end
        # lands on `d` (the wake date == the row's activity_date).
        # Wake = activity_date morning; bed = wake minus time-in-bed.
        time_in_bed_minutes = sleep_minutes + awake_minutes
        # latency 6-32 min — included in time-in-bed.
        latency_minutes = rng.randint(6, 32)
        time_in_bed_minutes += latency_minutes

        # sleep_end 05:45 - 08:15 on the morning of `d`.
        end_minute_of_day = rng.randint(5 * 60 + 45, 8 * 60 + 15)
        sleep_end = datetime.combine(
            d, time(end_minute_of_day // 60, end_minute_of_day % 60)
        )
        sleep_start = sleep_end - timedelta(minutes=time_in_bed_minutes)

        # efficiency 0.82 - 0.95 = asleep / time-in-bed.
        efficiency = round(sleep_minutes / time_in_bed_minutes, 3)
        efficiency = max(0.82, min(efficiency, 0.95))

        # --- Steps -------------------------------------------------------
        # 2,500 - 15,000 with realistic scatter. A couple of low rest days.
        # Subtle correlation: poorer sleep last night -> slightly fewer
        # steps today.
        is_rest_day = (i % 7 in (rng.randint(0, 2),)) and rng.random() < 0.5
        if is_rest_day:
            steps = rng.randint(2500, 5200)
        elif is_weekend:
            steps = rng.randint(6500, 14500)
        else:
            steps = rng.randint(5200, 13000)
        if prev_sleep_minutes is not None and prev_sleep_minutes < 360:
            # Slept poorly last night -> drag today's steps down ~8-18 %.
            steps = int(steps * rng.uniform(0.82, 0.92))
        steps = max(2400, min(steps, 15000))

        # --- Calories ----------------------------------------------------
        # Correlated with steps: BMR-ish base + per-step energy + jitter.
        calories = round(1850 + steps * 0.046 + rng.uniform(-110, 130))

        # --- Resting heart rate -----------------------------------------
        resting_hr = rng.randint(50, 58)
        if i in elevated_days:
            resting_hr += rng.randint(5, 8)  # elevated stretch
        resting_hr = max(48, min(resting_hr, 66))

        avg_hr = resting_hr + rng.randint(14, 26)
        max_hr = avg_hr + rng.randint(38, 70)

        # --- Active minutes ---------------------------------------------
        active_minutes = max(8, round(steps / 220 + rng.randint(-6, 10)))

        # --- Water -------------------------------------------------------
        water_ml = rng.randint(900, 2900)

        rows.append(
            {
                "user_id": REVIEWER_USER_ID,
                "activity_date": d.isoformat(),
                "steps": steps,
                "calories_burned": float(calories),
                "active_calories": float(round(calories * rng.uniform(0.32, 0.42))),
                "active_minutes": active_minutes,
                "resting_heart_rate": resting_hr,
                "avg_heart_rate": avg_hr,
                "max_heart_rate": max_hr,
                "sleep_minutes": sleep_minutes,
                "deep_sleep_minutes": deep_minutes,
                "light_sleep_minutes": light_minutes,
                "rem_sleep_minutes": rem_minutes,
                "awake_sleep_minutes": awake_minutes,
                "sleep_start": sleep_start.isoformat(),
                "sleep_end": sleep_end.isoformat(),
                "sleep_latency_minutes": latency_minutes,
                "sleep_efficiency": efficiency,
                "water_ml": water_ml,
                "source": DEMO_SOURCE,
            }
        )
        prev_sleep_minutes = sleep_minutes

    return rows


# --------------------------------------------------------------------------
# Seed
# --------------------------------------------------------------------------
def seed(db: Client) -> None:
    rows = _build_seed_rows()
    first = rows[0]["activity_date"]
    last = rows[-1]["activity_date"]
    print(f"🌱 Seeding {len(rows)} daily_activity rows for {REVIEWER_EMAIL}")
    print(f"   user_id={REVIEWER_USER_ID}")
    print(f"   window {first} .. {last}")

    # Upsert on (user_id, activity_date) — migration 019 defines the UNIQUE
    # constraint, so re-running --seed overwrites cleanly with stable RNG
    # output rather than creating duplicates.
    db.table("daily_activity").upsert(
        rows, on_conflict="user_id,activity_date"
    ).execute()
    print(f"✅ Upserted {len(rows)} daily_activity rows")

    # --- health_data_consent ------------------------------------------------
    # The /activity/* endpoints 403 without this; the demo provider also
    # treats it as the "connected" signal source of record.
    settings = (
        db.table("user_ai_settings")
        .select("user_id")
        .eq("user_id", REVIEWER_USER_ID)
        .execute()
    )
    if settings.data:
        db.table("user_ai_settings").update(
            {"health_data_consent": True}
        ).eq("user_id", REVIEWER_USER_ID).execute()
        print("✅ user_ai_settings.health_data_consent = true (updated)")
    else:
        db.table("user_ai_settings").insert(
            {"user_id": REVIEWER_USER_ID, "health_data_consent": True}
        ).execute()
        print("✅ user_ai_settings row created with health_data_consent = true")

    # --- health_goals -------------------------------------------------------
    # Upsert a sensible per-user target row so the Sleep / Combined Health
    # screens render goal lines instead of contract defaults.
    db.table("health_goals").upsert(
        {
            "user_id": REVIEWER_USER_ID,
            "step_goal": 9000,
            "active_minutes_goal": 30,
            "sleep_duration_goal_minutes": 465,  # 7h45m
            "bedtime_goal": "23:00:00",
        },
        on_conflict="user_id",
    ).execute()
    print("✅ health_goals upserted (9000 steps / 30 min / 7h45m / 23:00 bedtime)")

    print("\n🎯 Seed complete — reviewer health features are now reviewable.")


# --------------------------------------------------------------------------
# Delete
# --------------------------------------------------------------------------
def delete(db: Client, reset_goals: bool) -> None:
    """Remove exactly the seeded rows. Touches no other user.

    Deletes the contiguous SEED_DAYS-day `daily_activity` window ending
    yesterday for the reviewer user only. `source = reviewer_demo` is also
    matched as a safety belt so a real wearable row that happened to land
    in the window (it should not — reviewers cannot pair one) is left
    alone.
    """
    today = date.today()
    start = (today - timedelta(days=SEED_DAYS - 1)).isoformat()
    end = today.isoformat()
    print(f"🧹 Deleting seeded daily_activity rows for {REVIEWER_EMAIL}")
    print(f"   user_id={REVIEWER_USER_ID}")
    print(f"   window {start} .. {end}, source={DEMO_SOURCE}")

    existing = (
        db.table("daily_activity")
        .select("id", count="exact")
        .eq("user_id", REVIEWER_USER_ID)
        .eq("source", DEMO_SOURCE)
        .gte("activity_date", start)
        .lte("activity_date", end)
        .execute()
    )
    n = existing.count if existing.count is not None else len(existing.data or [])

    db.table("daily_activity").delete().eq(
        "user_id", REVIEWER_USER_ID
    ).eq("source", DEMO_SOURCE).gte("activity_date", start).lte(
        "activity_date", end
    ).execute()
    print(f"✅ Deleted {n} seeded daily_activity rows")

    if reset_goals:
        db.table("health_goals").delete().eq(
            "user_id", REVIEWER_USER_ID
        ).execute()
        print("✅ health_goals row removed for reviewer")
    else:
        print("ℹ️  health_goals row left in place (pass --reset-goals to remove)")

    # health_data_consent is intentionally NOT reset — it is a real consent
    # record and the reviewer account legitimately consents to the demo.
    print("\n🎯 Teardown complete — no other user or table was touched.")


# --------------------------------------------------------------------------
# Verify (read-back helper, used by --seed and --verify)
# --------------------------------------------------------------------------
def verify(db: Client) -> None:
    today = date.today()
    start = (today - timedelta(days=SEED_DAYS - 1)).isoformat()
    end = today.isoformat()
    res = (
        db.table("daily_activity")
        .select(
            "activity_date,steps,calories_burned,sleep_minutes,"
            "resting_heart_rate,sleep_efficiency,water_ml",
            count="exact",
        )
        .eq("user_id", REVIEWER_USER_ID)
        .gte("activity_date", start)
        .lte("activity_date", end)
        .order("activity_date", desc=True)
        .execute()
    )
    n = res.count if res.count is not None else len(res.data or [])
    print(f"\n🔍 daily_activity rows in window: {n}")
    for row in (res.data or [])[:5]:
        print(
            f"   {row['activity_date']}  steps={row['steps']:>6}  "
            f"sleep={row['sleep_minutes']}m  rhr={row['resting_heart_rate']}  "
            f"eff={row['sleep_efficiency']}  water={row['water_ml']}ml"
        )

    settings = (
        db.table("user_ai_settings")
        .select("health_data_consent")
        .eq("user_id", REVIEWER_USER_ID)
        .execute()
    )
    consent = settings.data[0]["health_data_consent"] if settings.data else None
    print(f"🔍 user_ai_settings.health_data_consent = {consent}")

    goals = (
        db.table("health_goals")
        .select("step_goal,sleep_duration_goal_minutes,bedtime_goal")
        .eq("user_id", REVIEWER_USER_ID)
        .execute()
    )
    print(f"🔍 health_goals = {goals.data[0] if goals.data else None}")


# --------------------------------------------------------------------------
# Entrypoint
# --------------------------------------------------------------------------
def main() -> None:
    parser = argparse.ArgumentParser(
        description="Seed / delete disclosed demo health data for the "
        "Zealova App Store / Play reviewer account."
    )
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        "--seed", action="store_true", help="Write ~45 days of demo health data"
    )
    group.add_argument(
        "--delete", action="store_true", help="Remove the seeded demo health data"
    )
    group.add_argument(
        "--verify", action="store_true", help="Read back and print current state"
    )
    parser.add_argument(
        "--reset-goals",
        action="store_true",
        help="With --delete, also remove the reviewer's health_goals row",
    )
    args = parser.parse_args()

    db = _supabase()

    if args.seed:
        seed(db)
        verify(db)
    elif args.delete:
        delete(db, reset_goals=args.reset_goals)
        verify(db)
    elif args.verify:
        verify(db)


if __name__ == "__main__":
    main()
