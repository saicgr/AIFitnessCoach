#!/usr/bin/env python3
"""One-off applier for migration 2401_user_warmup_templates.sql.

Mirrors check_migrations.py's connection recipe. Idempotent (CREATE TABLE
IF NOT EXISTS / CREATE INDEX IF NOT EXISTS), safe to re-run.
"""
import os
import sys

try:
    import psycopg2
except ImportError:
    os.system(f"{sys.executable} -m pip install psycopg2-binary -q")
    import psycopg2

HERE = os.path.dirname(os.path.abspath(__file__))
SQL_PATH = os.path.join(HERE, "2401_user_warmup_templates.sql")


def get_conn():
    return psycopg2.connect(
        host="db.hpbzfahijszqmgsybuor.supabase.co",
        port=5432,
        database="postgres",
        user="postgres",
        password=os.environ["SUPABASE_DB_PASSWORD"],
        sslmode="require",
    )


def main():
    with open(SQL_PATH) as f:
        sql = f.read()

    conn = get_conn()
    conn.autocommit = False
    try:
        with conn.cursor() as cur:
            cur.execute(sql)
        conn.commit()
        print("✅ Migration 2401 applied.")
    except Exception as e:
        conn.rollback()
        print(f"❌ Migration 2401 failed: {e}")
        raise
    finally:
        conn.close()

    # Verify.
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT column_name, data_type, is_nullable
                FROM information_schema.columns
                WHERE table_schema = 'public' AND table_name = 'user_warmup_templates'
                ORDER BY ordinal_position
                """
            )
            rows = cur.fetchall()
            print("Columns:")
            for r in rows:
                print(f"  {r[0]:<20} {r[1]:<20} nullable={r[2]}")

            cur.execute(
                """
                SELECT indexname FROM pg_indexes
                WHERE schemaname = 'public' AND tablename = 'user_warmup_templates'
                ORDER BY indexname
                """
            )
            print("Indexes:", [r[0] for r in cur.fetchall()])

            cur.execute(
                """
                SELECT polname FROM pg_policy
                WHERE polrelid = 'public.user_warmup_templates'::regclass
                ORDER BY polname
                """
            )
            print("Policies:", [r[0] for r in cur.fetchall()])
    finally:
        conn.close()


if __name__ == "__main__":
    main()
