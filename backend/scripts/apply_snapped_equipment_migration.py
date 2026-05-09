"""
Apply migration 2055_snapped_equipment.sql.

Per project memory `feedback_run_migrations_directly`, run via:
    cd backend && .venv/bin/python scripts/apply_snapped_equipment_migration.py
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

    sql_path = Path(__file__).parent.parent / "migrations" / "2055_snapped_equipment.sql"
    sql = sql_path.read_text()

    print(f"🏋️  Applying {sql_path.name} ({len(sql)} chars)...")
    conn = await asyncpg.connect(url)
    try:
        await conn.execute(sql)
        # Verify the table is reachable.
        row = await conn.fetchrow(
            "SELECT to_regclass('public.snapped_equipment') AS exists"
        )
        if not row or not row["exists"]:
            raise RuntimeError("snapped_equipment table not registered post-apply")
        print("✅ Migration applied; snapped_equipment table is live.")
    finally:
        await conn.close()


if __name__ == "__main__":
    asyncio.run(_main())
