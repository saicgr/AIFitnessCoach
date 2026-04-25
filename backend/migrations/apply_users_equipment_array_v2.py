"""
Apply the `2031_users_equipment_array_v2.sql` migration (Deploy 1 of 3
for the users.equipment VARCHAR → text[] move).

Run from repo root:
    cd backend && .venv/bin/python migrations/apply_users_equipment_array_v2.py

Uses DATABASE_URL from backend/.env. Mirrors apply_set_note_media.py.

Non-destructive: only ADDs the new column + GIN index + backfills it.
The old `equipment` VARCHAR stays in place. Code must dual-write to both
columns until Deploy 2 (read cutover) and Deploy 3 (drop old column).
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

    sql_path = Path(__file__).parent / "2031_users_equipment_array_v2.sql"
    sql = sql_path.read_text()

    conn = await asyncpg.connect(url, ssl="require")
    try:
        print(f"→ Applying {sql_path.name} to {url.split('@', 1)[-1]} …")
        await conn.execute(sql)

        # Verify the column landed and the index exists.
        col = await conn.fetchrow(
            """
            SELECT data_type, udt_name
            FROM information_schema.columns
            WHERE table_name = 'users' AND column_name = 'equipment_v2'
            """
        )
        if not col:
            raise RuntimeError("equipment_v2 column missing post-migration")
        print(f"✅ users.equipment_v2: {dict(col)}")

        idx = await conn.fetchrow(
            "SELECT indexname FROM pg_indexes WHERE indexname = 'idx_users_equipment_v2_gin'"
        )
        print(f"✅ GIN index: {idx['indexname'] if idx else 'MISSING'}")

        # Spot-check the backfill: distribution of equipment_v2 sizes.
        dist = await conn.fetch(
            """
            SELECT cardinality(equipment_v2) AS size, COUNT(*) AS users
            FROM users
            GROUP BY size
            ORDER BY size
            """
        )
        print("✅ equipment_v2 size distribution:")
        for r in dist:
            print(f"     size={r['size']:>3}  users={r['users']}")

        empty = await conn.fetchval(
            "SELECT COUNT(*) FROM users WHERE cardinality(equipment_v2) = 0"
        )
        if empty:
            print(f"⚠️  {empty} users still have empty equipment_v2 (should be 0)")
    finally:
        await conn.close()


if __name__ == "__main__":
    asyncio.run(_main())
