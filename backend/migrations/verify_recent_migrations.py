"""
One-shot verifier: are the 7 recent migrations actually applied to the DB
the backend currently points at?

For each SQL file we check the artifacts the migration is supposed to leave
behind (columns, indexes, seeded rows, RPCs, views) and report applied /
missing / partially-applied.

Run:
    cd backend && .venv/bin/python migrations/verify_recent_migrations.py
"""
import asyncio
import os
import re
from typing import Optional

MIGRATIONS = [
    "1981_seed_workout_time_consistency_achievements.sql",
    "1982_dynamic_pinned_nutrients.sql",
    "1982_workout_share_token.sql",
    "1983_hydration_source.sql",
    "1984_food_log_score_status.sql",
    "2030_performance_logs_rich_set_data.sql",
    "2031_users_equipment_array_v2.sql",
]


async def _column_exists(conn, table: str, column: str) -> bool:
    return bool(
        await conn.fetchval(
            """
            SELECT 1 FROM information_schema.columns
            WHERE table_name = $1 AND column_name = $2
            """,
            table,
            column,
        )
    )


async def _column_udt(conn, table: str, column: str) -> Optional[str]:
    return await conn.fetchval(
        """
        SELECT udt_name FROM information_schema.columns
        WHERE table_name = $1 AND column_name = $2
        """,
        table,
        column,
    )


async def _column_data_type(conn, table: str, column: str) -> Optional[str]:
    return await conn.fetchval(
        """
        SELECT data_type FROM information_schema.columns
        WHERE table_name = $1 AND column_name = $2
        """,
        table,
        column,
    )


async def _index_exists(conn, name: str) -> bool:
    return bool(
        await conn.fetchval(
            "SELECT 1 FROM pg_indexes WHERE indexname = $1", name
        )
    )


async def _function_exists(conn, name: str) -> bool:
    return bool(
        await conn.fetchval(
            "SELECT 1 FROM pg_proc WHERE proname = $1", name
        )
    )


async def _view_exists(conn, name: str) -> bool:
    return bool(
        await conn.fetchval(
            "SELECT 1 FROM information_schema.views WHERE table_name = $1",
            name,
        )
    )


def _print(name: str, status: str, detail: str = "") -> None:
    icon = {"OK": "✅", "MISSING": "❌", "PARTIAL": "⚠️ "}.get(status, "  ")
    print(f"{icon} {name:<55} {status}{(' — ' + detail) if detail else ''}")


async def verify_1981(conn):
    """1981: 10 achievement rows + 2 RPC functions."""
    expected_ids = [
        'consistency_workouts_bronze', 'consistency_workouts_silver',
        'consistency_workouts_gold', 'consistency_workouts_platinum',
        'consistency_workouts_diamond',
        'time_workout_bronze', 'time_workout_silver', 'time_workout_gold',
        'time_workout_platinum', 'time_workout_diamond',
    ]
    rows = await conn.fetch(
        "SELECT id FROM achievement_types WHERE id = ANY($1::text[])",
        expected_ids,
    )
    found = {r['id'] for r in rows}
    missing_rows = [i for i in expected_ids if i not in found]

    fn1 = await _function_exists(conn, 'count_muscle_group_exercises')
    fn2 = await _function_exists(conn, 'get_user_volume_stats')

    parts = []
    if missing_rows:
        parts.append(f"missing achievements: {missing_rows}")
    if not fn1:
        parts.append("count_muscle_group_exercises missing")
    if not fn2:
        parts.append("get_user_volume_stats missing")

    if not parts:
        return "OK", f"all 10 achievements seeded, both RPCs exist"
    if len(found) == 0 and not fn1 and not fn2:
        return "MISSING", "; ".join(parts)
    return "PARTIAL", "; ".join(parts)


async def verify_1982_pinned(conn):
    """1982 (pinned): users.pinned_nutrients_mode + nutrient_rdas.penalty."""
    has_mode = await _column_exists(conn, 'users', 'pinned_nutrients_mode')
    has_penalty = await _column_exists(conn, 'nutrient_rdas', 'penalty')

    if has_mode and has_penalty:
        # Spot-check that penalty was actually seeded for some nutrients
        seeded = await conn.fetchval(
            "SELECT COUNT(*) FROM nutrient_rdas WHERE penalty = TRUE"
        )
        return "OK", f"both columns present; {seeded} penalty rows seeded"
    parts = []
    if not has_mode:
        parts.append("users.pinned_nutrients_mode missing")
    if not has_penalty:
        parts.append("nutrient_rdas.penalty missing")
    return ("MISSING" if not has_mode and not has_penalty else "PARTIAL", "; ".join(parts))


async def verify_1982_share(conn):
    """1982 (share): workouts.share_token + idx + public_workouts_v view."""
    has_col = await _column_exists(conn, 'workouts', 'share_token')
    has_idx = await _index_exists(conn, 'idx_workouts_share_token')
    has_view = await _view_exists(conn, 'public_workouts_v')

    if has_col and has_idx and has_view:
        return "OK", "share_token col + idx + public_workouts_v view"
    parts = []
    if not has_col:
        parts.append("share_token col missing")
    if not has_idx:
        parts.append("idx_workouts_share_token missing")
    if not has_view:
        parts.append("public_workouts_v view missing")
    return ("MISSING" if not (has_col or has_idx or has_view) else "PARTIAL", "; ".join(parts))


async def verify_1983(conn):
    """1983: hydration_logs.source + composite index."""
    has_col = await _column_exists(conn, 'hydration_logs', 'source')
    has_idx = await _index_exists(conn, 'ix_hydration_logs_user_source')
    if has_col and has_idx:
        return "OK", "source col + ix_hydration_logs_user_source"
    parts = []
    if not has_col:
        parts.append("source col missing")
    if not has_idx:
        parts.append("ix_hydration_logs_user_source missing")
    return ("MISSING" if not has_col and not has_idx else "PARTIAL", "; ".join(parts))


async def verify_1984(conn):
    """1984: food_logs.score_status."""
    has_col = await _column_exists(conn, 'food_logs', 'score_status')
    if has_col:
        return "OK", "food_logs.score_status present"
    return "MISSING", "food_logs.score_status missing"


async def verify_2030(conn):
    """2030: performance_logs notes TEXT[] + 4 new cols."""
    notes_udt = await _column_udt(conn, 'performance_logs', 'notes')
    notes_dt = await _column_data_type(conn, 'performance_logs', 'notes')
    audio = await _column_exists(conn, 'performance_logs', 'notes_audio_url')
    photos = await _column_exists(conn, 'performance_logs', 'notes_photo_urls')
    started = await _column_exists(conn, 'performance_logs', 'started_at')
    mode = await _column_exists(conn, 'performance_logs', 'logging_mode')

    notes_is_array = notes_dt == 'ARRAY' and notes_udt == '_text'

    parts = []
    if not notes_is_array:
        parts.append(f"notes not TEXT[] (data_type={notes_dt}, udt={notes_udt})")
    if not audio:
        parts.append("notes_audio_url missing")
    if not photos:
        parts.append("notes_photo_urls missing")
    if not started:
        parts.append("started_at missing")
    if not mode:
        parts.append("logging_mode missing")

    if not parts:
        return "OK", "notes TEXT[]; audio/photos/started_at/logging_mode all present"
    if not (notes_is_array or audio or photos or started or mode):
        return "MISSING", "; ".join(parts)
    return "PARTIAL", "; ".join(parts)


async def verify_2031(conn):
    """2031 deploy 1 of 3: users.equipment_v2 text[] + GIN index + backfill."""
    udt = await _column_udt(conn, 'users', 'equipment_v2')
    dt = await _column_data_type(conn, 'users', 'equipment_v2')
    has_idx = await _index_exists(conn, 'idx_users_equipment_v2_gin')

    if dt != 'ARRAY' or udt != '_text':
        return "MISSING", f"equipment_v2 missing or wrong type (data_type={dt}, udt={udt})"

    # Backfill quality check: how many users still have an empty array.
    empty = await conn.fetchval(
        "SELECT COUNT(*) FROM users WHERE cardinality(equipment_v2) = 0"
    )
    total = await conn.fetchval("SELECT COUNT(*) FROM users")

    parts = []
    if not has_idx:
        parts.append("idx_users_equipment_v2_gin missing")
    if empty:
        parts.append(f"{empty}/{total} users have empty equipment_v2")
    if not parts:
        return "OK", f"text[] col + GIN idx; backfill clean ({total} users)"
    return "PARTIAL", "; ".join(parts)


VERIFIERS = {
    "1981_seed_workout_time_consistency_achievements.sql": verify_1981,
    "1982_dynamic_pinned_nutrients.sql": verify_1982_pinned,
    "1982_workout_share_token.sql": verify_1982_share,
    "1983_hydration_source.sql": verify_1983,
    "1984_food_log_score_status.sql": verify_1984,
    "2030_performance_logs_rich_set_data.sql": verify_2030,
    "2031_users_equipment_array_v2.sql": verify_2031,
}


async def _main() -> None:
    import asyncpg
    from dotenv import load_dotenv

    load_dotenv()
    url = os.environ["DATABASE_URL"]
    url = re.sub(r"^postgresql\+asyncpg://", "postgresql://", url)
    redacted = re.sub(r"://[^@]+@", "://***@", url)
    print(f"→ Verifying against {redacted}\n")

    conn = await asyncpg.connect(url, ssl="require")
    try:
        for name in MIGRATIONS:
            verifier = VERIFIERS[name]
            try:
                status, detail = await verifier(conn)
            except Exception as e:
                status, detail = "MISSING", f"verifier raised: {e!r}"
            _print(name, status, detail)
    finally:
        await conn.close()


if __name__ == "__main__":
    asyncio.run(_main())
