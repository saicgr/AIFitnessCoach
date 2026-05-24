"""
Apply migration 2093 (tdee_hold_snapshots) and verify it landed.

The SQL is fully idempotent (CREATE TABLE IF NOT EXISTS + DROP/CREATE POLICY)
and carries its own BEGIN/COMMIT, so re-running on a partial state is safe.

Run from repo root:
    cd backend && .venv/bin/python migrations/apply_2093_tdee_hold_snapshots.py
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
        sql = (Path(__file__).parent / "2093_tdee_hold_snapshots.sql").read_text()
        print("→ Applying 2093_tdee_hold_snapshots.sql …")
        await conn.execute(sql)

        checks = {
            "tdee_hold_snapshots table exists":
                "SELECT EXISTS (SELECT 1 FROM information_schema.tables "
                "WHERE table_schema='public' AND table_name='tdee_hold_snapshots')",
            "hold_window_start_date column":
                "SELECT EXISTS (SELECT 1 FROM information_schema.columns "
                "WHERE table_name='tdee_hold_snapshots' AND column_name='hold_window_start_date')",
            "calorie_target_at_entry column":
                "SELECT EXISTS (SELECT 1 FROM information_schema.columns "
                "WHERE table_name='tdee_hold_snapshots' AND column_name='calorie_target_at_entry')",
            "cycle_calorie_delta_at_entry column":
                "SELECT EXISTS (SELECT 1 FROM information_schema.columns "
                "WHERE table_name='tdee_hold_snapshots' AND column_name='cycle_calorie_delta_at_entry')",
            "hold_reason check constraint":
                "SELECT EXISTS (SELECT 1 FROM information_schema.check_constraints cc "
                "JOIN information_schema.constraint_column_usage ccu USING (constraint_name) "
                "WHERE ccu.table_name='tdee_hold_snapshots' AND ccu.column_name='hold_reason')",
            "unique (user_id, hold_window_start_date)":
                "SELECT EXISTS (SELECT 1 FROM pg_indexes "
                "WHERE tablename='tdee_hold_snapshots' AND indexdef ILIKE '%UNIQUE%user_id%hold_window_start_date%')",
            "RLS enabled":
                "SELECT relrowsecurity FROM pg_class WHERE relname='tdee_hold_snapshots'",
        }
        all_ok = True
        for name, query in checks.items():
            ok = await conn.fetchval(query)
            print(f"{'✅' if ok else '❌'} {name}")
            all_ok = all_ok and bool(ok)
        if not all_ok:
            raise RuntimeError("Migration 2093 verification failed.")

        rowcount = await conn.fetchval("SELECT count(*) FROM public.tdee_hold_snapshots")
        print(f"→ tdee_hold_snapshots row count: {rowcount} (expected 0 on first apply)")
        print("\n✅ Migration 2093 applied and verified.")
    finally:
        await conn.close()


if __name__ == "__main__":
    asyncio.run(_main())
