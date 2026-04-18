#!/usr/bin/env python3
"""Run migration 1929 — Amp level-up rewards + add merch_claims table."""
import os
import sys
from pathlib import Path

import psycopg2

DATABASE_HOST = "db.hpbzfahijszqmgsybuor.supabase.co"
DATABASE_PORT = 5432
DATABASE_NAME = "postgres"
DATABASE_USER = "postgres"
DATABASE_PASSWORD = os.environ.get("DATABASE_PASSWORD") or os.environ.get("SUPABASE_DB_PASSWORD")
if not DATABASE_PASSWORD:
    raise SystemExit("DATABASE_PASSWORD or SUPABASE_DB_PASSWORD env var required")


def run():
    migrations_dir = Path(__file__).parent.parent / "migrations"
    sql_path = migrations_dir / "1929_amp_rewards_and_merch.sql"
    if not sql_path.exists():
        raise SystemExit(f"Migration file not found: {sql_path}")

    print("=" * 60)
    print("MIGRATION 1929: Amp Rewards + Merch Claims")
    print("=" * 60)
    conn = psycopg2.connect(
        host=DATABASE_HOST, port=DATABASE_PORT, dbname=DATABASE_NAME,
        user=DATABASE_USER, password=DATABASE_PASSWORD, sslmode="require",
    )
    try:
        with conn.cursor() as cur:
            cur.execute(sql_path.read_text())
        conn.commit()
        print("SUCCESS: 1929 applied.")

        # Verify
        with conn.cursor() as cur:
            cur.execute("SELECT to_regclass('public.merch_claims') IS NOT NULL")
            print(f"  merch_claims table exists: {cur.fetchone()[0]}")
            cur.execute("SELECT COUNT(*) FROM pg_proc WHERE proname IN ('distribute_level_rewards','get_user_merch_claims','submit_merch_claim_address','cancel_merch_claim','merch_type_for_level')")
            print(f"  required functions present: {cur.fetchone()[0]}/5")
    finally:
        conn.close()


if __name__ == "__main__":
    run()
