"""
Apply migration 2089 (cycle-tracking upgrade) and verify it landed.

The SQL is fully idempotent (IF NOT EXISTS / ADD COLUMN IF NOT EXISTS /
DROP POLICY IF EXISTS / ON CONFLICT DO NOTHING) and carries its own
BEGIN/COMMIT, so re-running on a partial state is safe.

Run from repo root:
    cd backend && .venv/bin/python migrations/apply_2089_cycle_tracking.py
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
        sql = (Path(__file__).parent / "2089_cycle_tracking_upgrade.sql").read_text()
        print("→ Applying 2089_cycle_tracking_upgrade.sql …")
        await conn.execute(sql)

        checks = {
            "cycle_periods table exists":
                "SELECT to_regclass('public.cycle_periods') IS NOT NULL",
            "cycle_periods RLS enabled":
                "SELECT relrowsecurity FROM pg_class WHERE relname = 'cycle_periods'",
            "hormone_logs.lh_test_result column":
                "SELECT EXISTS (SELECT 1 FROM information_schema.columns "
                "WHERE table_name='hormone_logs' AND column_name='lh_test_result')",
            "hormone_logs.ovulation_confirmed column":
                "SELECT EXISTS (SELECT 1 FROM information_schema.columns "
                "WHERE table_name='hormone_logs' AND column_name='ovulation_confirmed')",
            "hormonal_profiles.tracking_mode column":
                "SELECT EXISTS (SELECT 1 FROM information_schema.columns "
                "WHERE table_name='hormonal_profiles' AND column_name='tracking_mode')",
            "hormonal_profiles.has_menstrual_periods column":
                "SELECT EXISTS (SELECT 1 FROM information_schema.columns "
                "WHERE table_name='hormonal_profiles' AND column_name='has_menstrual_periods')",
            "hormonal_profiles.luteal_length_days column":
                "SELECT EXISTS (SELECT 1 FROM information_schema.columns "
                "WHERE table_name='hormonal_profiles' AND column_name='luteal_length_days')",
        }
        all_ok = True
        for name, query in checks.items():
            ok = await conn.fetchval(query)
            print(f"{'✅' if ok else '❌'} {name}")
            all_ok = all_ok and bool(ok)
        if not all_ok:
            raise RuntimeError("Migration 2089 verification failed.")

        backfilled = await conn.fetchval("SELECT count(*) FROM public.cycle_periods")
        print(f"→ cycle_periods rows after backfill: {backfilled}")
        print("\n✅ Migration 2089 applied and verified.")
    finally:
        await conn.close()


if __name__ == "__main__":
    asyncio.run(_main())
