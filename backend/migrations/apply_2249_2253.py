"""
Apply the Samsung-parity health migrations 2249–2253.

  2249_vitals_daily.sql
  2250_heart_health_daily.sql
  2251_fitness_index_daily.sql
  2252_fitness_index_cohort_snapshot.sql   (table + 2 functions)
  2253_nutrient_rdas_antioxidant_flag.sql

All files are idempotent (IF NOT EXISTS / CREATE OR REPLACE / keyed UPDATE), so
re-running on a partial state is safe. Each file applies inside its own transaction;
a lightweight post-check verifies the object landed.

Run from repo root:
    cd backend && .venv/bin/python migrations/apply_2249_2253.py
"""
import asyncio
import os
import re
from pathlib import Path

FILES = [
    "2249_vitals_daily.sql",
    "2250_heart_health_daily.sql",
    "2251_fitness_index_daily.sql",
    "2252_fitness_index_cohort_snapshot.sql",
    "2253_nutrient_rdas_antioxidant_flag.sql",
]

# (label, SQL returning a single value, expected truthy)
CHECKS = [
    ("vitals_daily table",
     "SELECT to_regclass('public.vitals_daily') IS NOT NULL"),
    ("heart_health_daily table",
     "SELECT to_regclass('public.heart_health_daily') IS NOT NULL"),
    ("fitness_index_daily table",
     "SELECT to_regclass('public.fitness_index_daily') IS NOT NULL"),
    ("cohort snapshot table",
     "SELECT to_regclass('public.fitness_index_cohort_snapshot') IS NOT NULL"),
    ("percentile fn",
     "SELECT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'compute_fitness_index_percentile')"),
    ("refresh fn",
     "SELECT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'refresh_fitness_index_cohort_snapshot')"),
    ("is_antioxidant column",
     "SELECT EXISTS (SELECT 1 FROM information_schema.columns "
     "WHERE table_name='nutrient_rdas' AND column_name='is_antioxidant')"),
    ("antioxidants flagged",
     "SELECT COUNT(*) >= 5 FROM nutrient_rdas WHERE is_antioxidant = true"),
]


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
        d = Path(__file__).parent
        for fname in FILES:
            sql = (d / fname).read_text()
            print(f"\n→ Applying {fname} …")
            async with conn.transaction():
                await conn.execute(sql)
            print("  applied.")

        print("\n→ Post-checks:")
        ok = True
        for label, q in CHECKS:
            val = await conn.fetchval(q)
            icon = "✅" if val else "❌"
            if not val:
                ok = False
            print(f"  {icon} {label}: {val}")

        # Prime the cohort snapshot so percentile calls work immediately.
        primed = await conn.fetchval("SELECT refresh_fitness_index_cohort_snapshot()")
        print(f"\n  cohort snapshot primed: {primed} rows")

        if not ok:
            raise RuntimeError("one or more post-checks failed")
        print("\n✅ 2249–2253 applied and verified.")
    finally:
        await conn.close()


if __name__ == "__main__":
    asyncio.run(_main())
