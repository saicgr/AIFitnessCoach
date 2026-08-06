"""
Apply migration 2402_fix_slideshow_jobs_user_id_fk.sql — repoints
slideshow_jobs.user_id's FK from auth.users(id) to users(id), matching every
write path (which inserts current_user["id"], the backend users.id).

Run from repo root:
    cd backend && .venv312/bin/python migrations/apply_2402_slideshow_jobs_fk.py
"""
import asyncio
import os
import re
from pathlib import Path


async def _main() -> None:
    import asyncpg
    from dotenv import load_dotenv

    load_dotenv()
    url = os.environ["DATABASE_URL"]
    url = re.sub(r"^postgresql\+asyncpg://", "postgresql://", url)
    redacted = re.sub(r"://[^@]+@", "://***@", url)
    print(f"-> Target DB: {redacted}")

    conn = await asyncpg.connect(url, ssl="require", statement_cache_size=0)
    try:
        before = await conn.fetchrow(
            """
            SELECT con.conname, pg_get_constraintdef(con.oid) AS def
            FROM pg_constraint con
            JOIN pg_class rel ON rel.oid = con.conrelid
            JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
            WHERE rel.relname = 'slideshow_jobs' AND nsp.nspname = 'public' AND con.contype = 'f'
            """
        )
        print(f"-> Before: {dict(before) if before else None}")

        sql_path = Path(__file__).parent / "2402_fix_slideshow_jobs_user_id_fk.sql"
        sql = sql_path.read_text()
        async with conn.transaction():
            await conn.execute(sql)

        after = await conn.fetchrow(
            """
            SELECT con.conname, pg_get_constraintdef(con.oid) AS def
            FROM pg_constraint con
            JOIN pg_class rel ON rel.oid = con.conrelid
            JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
            WHERE rel.relname = 'slideshow_jobs' AND nsp.nspname = 'public' AND con.contype = 'f'
            """
        )
        print(f"-> After:  {dict(after) if after else None}")
        if not after or "users(id)" not in after["def"] or "auth.users" in after["def"]:
            raise RuntimeError(f"Migration did not land as expected: {after}")
        print("OK migration verified")
    finally:
        await conn.close()


if __name__ == "__main__":
    asyncio.run(_main())
