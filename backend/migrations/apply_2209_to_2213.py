"""
Apply migrations 2209..2213 (schema-drift cleanup, batch 2) and verify each
landed by re-querying information_schema.columns.

Run from backend/:
    .venv/bin/python migrations/apply_2209_to_2213.py
"""
import asyncio
import os
import re
from pathlib import Path

MIGRATIONS = [
    (
        "2209_neat_feature.sql",
        {
            "daily_neat_activity": {
                "user_id", "activity_date", "total_steps", "step_goal",
                "goal_met", "active_hours", "sedentary_hours", "neat_score",
                "longest_sedentary_period", "updated_at",
            },
            "hourly_neat_activity": {
                "user_id", "activity_date", "hour", "steps", "is_active",
                "source", "recorded_at",
            },
            "user_neat_settings": {
                "user_id", "current_goal", "baseline_steps", "week_number",
                "reminder_enabled", "reminder_interval_minutes",
                "quiet_hours_start", "quiet_hours_end", "work_hours_only",
                "work_hours_start", "work_hours_end", "min_sedentary_hours",
                "exclude_weekends", "updated_at",
            },
            "user_neat_streaks": {
                "user_id", "streak_type", "current_streak", "longest_streak",
                "last_updated",
            },
            "neat_scores": {
                "user_id", "score_date", "total_score", "step_score",
                "consistency_score", "active_hours_score",
                "movement_breaks_score", "total_steps", "active_hours",
                "movement_breaks", "step_goal_met", "grade", "percentile",
                "message", "calculated_at",
            },
            "neat_achievement_definitions": {
                "id", "code", "name", "description", "category", "tier",
                "threshold", "icon", "points", "is_active", "sort_order",
            },
            "neat_settings": {"user_id", "daily_step_goal"},
        },
    ),
    (
        "2210_live_chat_support.sql",
        {
            "live_chat_messages": {
                "ticket_id", "sender_role", "sender_id", "message",
                "is_system_message", "read_at", "created_at",
            },
            "admin_presence": {
                "admin_id", "is_online", "last_seen", "status_message",
            },
            "chat_media_usage": {
                "user_id", "usage_date", "media_count",
            },
        },
    ),
    (
        "2211_google_calendar_sync.sql",
        {
            "google_calendar_connections": {
                "user_id", "access_token", "refresh_token",
                "token_expires_at", "expires_in_seconds", "calendar_id",
                "connected_at",
            },
        },
    ),
    (
        "2212_misc_feature_tables.sql",
        {
            "fasting_impact_analysis": {
                "user_id", "period", "analysis_date",
                "avg_weight_fasting_days", "avg_weight_non_fasting_days",
                "weight_trend_fasting", "workouts_on_fasting_days",
                "workouts_on_non_fasting_days",
                "avg_workout_completion_fasting",
                "avg_workout_completion_non_fasting",
                "goals_hit_on_fasting_days", "goals_hit_on_non_fasting_days",
                "goal_completion_rate_fasting",
                "goal_completion_rate_non_fasting", "correlation_score",
                "fasting_impact_summary", "recommendations",
            },
            "skill_attempt_logs": {
                "user_id", "chain_id", "step_order", "reps", "sets",
                "hold_seconds", "success", "notes", "attempted_at",
            },
            "subscription_transparency_events": {
                "id", "event_type", "user_id", "device_id", "session_id",
                "event_data", "app_version", "platform", "created_at",
            },
            "user_trial_status": {
                "id", "user_id", "trial_start_date", "trial_end_date",
                "trial_plan", "trial_status", "reminder_sent_day_5",
                "reminder_sent_day_7", "features_used",
            },
            "streak_recovery_attempts": {
                "user_id", "previous_streak_length",
                "days_since_last_workout", "recovery_type",
                "motivation_message", "recovery_workout_id",
                "was_successful", "completed_at",
            },
        },
    ),
    (
        "2213_watch_sync_alignment.sql",
        {
            "hydration_settings": {
                "user_id", "daily_goal_ml", "reminder_enabled",
            },
        },
    ),
]


async def _apply_one(conn, sql_path: Path, expected: dict) -> None:
    sql = sql_path.read_text()
    print(f"\n→ Applying {sql_path.name} …")
    async with conn.transaction():
        await conn.execute(sql)

    overall_ok = True
    for table, cols in expected.items():
        rows = await conn.fetch(
            """
            SELECT column_name FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = $1
            """,
            table,
        )
        actual = {r["column_name"] for r in rows}
        missing = cols - actual
        if missing:
            overall_ok = False
            print(f"  ❌ {table}: missing {sorted(missing)}")
        else:
            print(f"  ✅ {table}: all {len(cols)} expected columns present")
    if not overall_ok:
        raise RuntimeError(f"{sql_path.name} verification failed")


async def _pg_class_check(conn, names: list) -> None:
    rows = await conn.fetch(
        """
        SELECT c.relname FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'public'
          AND c.relkind IN ('r','v','m','f','p')
          AND c.relname = ANY($1::text[])
        """,
        names,
    )
    found = {r["relname"] for r in rows}
    print("\n=== pg_class confirmation ===")
    for n in names:
        mark = "✅" if n in found else "❌"
        print(f"  {mark} {n}")


async def _main() -> None:
    import asyncpg
    from dotenv import load_dotenv

    load_dotenv()
    url = os.environ.get("DATABASE_URL_DIRECT") or os.environ["DATABASE_URL"]
    url = re.sub(r"^postgresql\+asyncpg://", "postgresql://", url)
    redacted = re.sub(r"://[^@]+@", "://***@", url)
    print(f"→ Target DB: {redacted}")

    conn = await asyncpg.connect(url, ssl="require")
    try:
        migrations_dir = Path(__file__).parent
        for fname, expected in MIGRATIONS:
            await _apply_one(conn, migrations_dir / fname, expected)

        all_tables = sorted(
            {t for _, exp in MIGRATIONS for t in exp.keys()}
        )
        await _pg_class_check(conn, all_tables)
        print("\n✅ All five migrations applied and verified.")
    finally:
        await conn.close()


if __name__ == "__main__":
    asyncio.run(_main())
