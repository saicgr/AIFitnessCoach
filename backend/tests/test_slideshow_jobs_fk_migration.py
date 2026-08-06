"""
Regression guard for migration 2402_fix_slideshow_jobs_user_id_fk.sql.

REGRESSION GUARD (real bug, Sentry PYTHON-FASTAPI-7N / rolled into the noisy
PYTHON-FASTAPI-1X bucket): `slideshow_jobs.user_id` (migration 2267) was
created `REFERENCES auth.users(id)`, copied from media_analysis_jobs (264)
instead of matching its own sibling table workout_photos (2265), which
correctly targets `users(id)`. `create_slideshow`
(api/v1/workout_photos.py) always inserts `current_user["id"]` — the backend
`public.users.id` — never the Supabase auth id, so every slideshow create
violated `slideshow_jobs_user_id_fkey` for any user whose `public.users.id`
differs from their `auth.users.id` (the normal case).

This connects to the real DATABASE_URL and asserts the live constraint
targets `users(id)`, not `auth.users(id)` — a schema fix has no application
code to unit-test, so the constraint itself is the thing under test. Skipped
when DATABASE_URL isn't configured (e.g. a sandboxed CI runner with no DB).
"""
import os
import re

import pytest

pytestmark = pytest.mark.asyncio


def _has_database_url() -> bool:
    try:
        from dotenv import load_dotenv
        load_dotenv()
    except Exception:
        pass
    return bool(os.environ.get("DATABASE_URL"))


@pytest.mark.skipif(not _has_database_url(), reason="DATABASE_URL not configured")
async def test_slideshow_jobs_user_id_fk_targets_public_users():
    import asyncpg

    url = os.environ["DATABASE_URL"]
    url = re.sub(r"^postgresql\+asyncpg://", "postgresql://", url)
    conn = await asyncpg.connect(url, ssl="require", statement_cache_size=0)
    try:
        row = await conn.fetchrow(
            """
            SELECT con.conname, pg_get_constraintdef(con.oid) AS def
            FROM pg_constraint con
            JOIN pg_class rel ON rel.oid = con.conrelid
            JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
            WHERE rel.relname = 'slideshow_jobs'
              AND nsp.nspname = 'public'
              AND con.contype = 'f'
              AND con.conname = 'slideshow_jobs_user_id_fkey'
            """
        )
        assert row is not None, "slideshow_jobs_user_id_fkey constraint not found"
        definition = row["def"]
        assert "auth.users" not in definition, (
            f"slideshow_jobs.user_id still references auth.users — every insert "
            f"(which writes public.users.id) will 23503 for any user whose "
            f"public.users.id != auth.users.id: {definition}"
        )
        assert re.search(r"REFERENCES\s+users\s*\(", definition), (
            f"slideshow_jobs.user_id must reference public.users(id), matching "
            f"the sibling workout_photos table and what create_slideshow inserts: "
            f"{definition}"
        )
    finally:
        await conn.close()
