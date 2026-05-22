"""
Apply migration 2092 (cycle research-data consent) and verify it landed.

The SQL is fully idempotent (ADD COLUMN IF NOT EXISTS) and carries its own
BEGIN/COMMIT, so re-running on a partial state is safe.

Run from repo root:
    cd backend && .venv/bin/python migrations/apply_2092_cycle_nutrition_consent.py
"""
import asyncio
import os
import re
from pathlib import Path


async def _main() -> None:
    import asyncpg
    from dotenv import load_dotenv

    load_dotenv()
    url = re.sub(r"^postgresql\+asyncpg://", "postgresql://", os.environ["DATABASE_URL"])
    print(f"→ Target DB: {re.sub(r'://[^@]+@', '://***@', url)}")

    conn = await asyncpg.connect(url, ssl="require")
    try:
        sql = (Path(__file__).parent / "2092_cycle_nutrition_consent.sql").read_text()
        print("→ Applying 2092_cycle_nutrition_consent.sql …")
        await conn.execute(sql)

        checks = {
            "user_ai_settings.cycle_research_consent column":
                "SELECT EXISTS (SELECT 1 FROM information_schema.columns "
                "WHERE table_name='user_ai_settings' AND column_name='cycle_research_consent')",
            "user_ai_settings.cycle_research_consented_at column":
                "SELECT EXISTS (SELECT 1 FROM information_schema.columns "
                "WHERE table_name='user_ai_settings' AND column_name='cycle_research_consented_at')",
            "cycle_research_consent defaults to false":
                "SELECT column_default = 'false' FROM information_schema.columns "
                "WHERE table_name='user_ai_settings' AND column_name='cycle_research_consent'",
            "cycle_research_consent is NOT NULL":
                "SELECT is_nullable = 'NO' FROM information_schema.columns "
                "WHERE table_name='user_ai_settings' AND column_name='cycle_research_consent'",
        }
        all_ok = True
        for name, query in checks.items():
            ok = await conn.fetchval(query)
            print(f"{'✅' if ok else '❌'} {name}")
            all_ok = all_ok and bool(ok)
        if not all_ok:
            raise RuntimeError("Migration 2092 verification failed.")

        # Sanity: confirm no existing row was opted in by the migration.
        opted_in = await conn.fetchval(
            "SELECT count(*) FROM public.user_ai_settings WHERE cycle_research_consent = true"
        )
        print(f"→ user_ai_settings rows with cycle_research_consent=true: {opted_in} (expected 0)")
        print("\n✅ Migration 2092 applied and verified.")
    finally:
        await conn.close()


if __name__ == "__main__":
    asyncio.run(_main())
