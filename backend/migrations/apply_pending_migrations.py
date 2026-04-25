"""
Apply the two recent migrations the verifier flagged as MISSING:

  - 1982_workout_share_token.sql       (share_token + view)
  - 2031_users_equipment_array_v2.sql  (equipment_v2 backfill)

Both SQL files are idempotent (IF NOT EXISTS / coalesces / DO blocks),
so re-running on a partial state is safe. After each file we re-call the
matching verifier from verify_recent_migrations.py and bail if anything
still reads MISSING.

Run from repo root:
    cd backend && .venv/bin/python migrations/apply_pending_migrations.py
"""
import asyncio
import os
import re
from pathlib import Path

from verify_recent_migrations import verify_1982_share, verify_2031


PENDING = [
    ("1982_workout_share_token.sql", verify_1982_share),
    ("2031_users_equipment_array_v2.sql", verify_2031),
]


async def _apply_one(conn, sql_path: Path, verifier) -> None:
    sql = sql_path.read_text()
    print(f"\n→ Applying {sql_path.name} …")
    # Wrap in a transaction so a mid-file failure rolls back cleanly.
    async with conn.transaction():
        await conn.execute(sql)
    status, detail = await verifier(conn)
    icon = {"OK": "✅", "PARTIAL": "⚠️ ", "MISSING": "❌"}.get(status, "  ")
    print(f"{icon} post-apply verifier: {status} — {detail}")
    if status != "OK":
        raise RuntimeError(
            f"{sql_path.name} did not land cleanly: {status} — {detail}"
        )


async def _main() -> None:
    import asyncpg
    from dotenv import load_dotenv

    load_dotenv()
    url = os.environ["DATABASE_URL"]
    url = re.sub(r"^postgresql\+asyncpg://", "postgresql://", url)
    redacted = re.sub(r"://[^@]+@", "://***@", url)
    print(f"→ Target DB: {redacted}")

    conn = await asyncpg.connect(url, ssl="require")
    try:
        migrations_dir = Path(__file__).parent
        for fname, verifier in PENDING:
            await _apply_one(conn, migrations_dir / fname, verifier)
        print("\n✅ All pending migrations applied and verified.")
    finally:
        await conn.close()


if __name__ == "__main__":
    asyncio.run(_main())
