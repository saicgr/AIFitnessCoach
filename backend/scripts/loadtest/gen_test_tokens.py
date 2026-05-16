#!/usr/bin/env python3
"""
Generate a pool of test JWTs for the k6 launch-burst load test.

What it does, idempotently:
  1. Ensures N test auth users exist in Supabase Auth
     (loadtest+0001@zealova-loadtest.dev ... created via the admin API).
  2. Ensures each has a matching row in the `users` table
     (get_current_user requires a DB row — minimal onboarding-complete row).
  3. Signs each in via the GoTrue password grant to mint a fresh access
     token (tokens expire ~1h, so re-run this right before a load test).
  4. Writes tokens.json — the [{user_id, token}] pool launch_burst.js reads.

A pool of ~200 distinct users is plenty: it gives the server cache
diversity without hammering Supabase Auth. The k6 VUs cycle through them.

USAGE
  cd backend
  .venv/bin/python scripts/loadtest/gen_test_tokens.py            # default 200
  .venv/bin/python scripts/loadtest/gen_test_tokens.py --count 500
  .venv/bin/python scripts/loadtest/gen_test_tokens.py --refresh-only

Reads SUPABASE_URL + SUPABASE_KEY (service role) + DATABASE_URL from
backend/.env. The test users are namespaced under @zealova-loadtest.dev
and are safe to delete with --cleanup.
"""
import argparse
import asyncio
import json
import os
import sys
import uuid
from pathlib import Path

import asyncpg
import httpx
from dotenv import load_dotenv

BACKEND_DIR = Path(__file__).resolve().parents[2]
load_dotenv(BACKEND_DIR / ".env")

SUPABASE_URL = os.environ["SUPABASE_URL"].rstrip("/")
SERVICE_KEY = os.environ["SUPABASE_KEY"]
DATABASE_URL = os.environ["DATABASE_URL"].replace("postgresql+asyncpg://", "postgresql://")

EMAIL_DOMAIN = "zealova-loadtest.dev"
PASSWORD = "LoadTest!2026-zealova"  # shared — these are throwaway test accounts
OUT_FILE = Path(__file__).resolve().parent / "tokens.json"

ADMIN_HEADERS = {"apikey": SERVICE_KEY, "Authorization": f"Bearer {SERVICE_KEY}"}


def email_for(i: int) -> str:
    return f"loadtest+{i:04d}@{EMAIL_DOMAIN}"


async def ensure_auth_user(client: httpx.AsyncClient, email: str) -> str:
    """Create the Supabase Auth user if missing; return its auth id (uuid)."""
    # Admin create — 422 if the user already exists.
    resp = await client.post(
        f"{SUPABASE_URL}/auth/v1/admin/users",
        headers=ADMIN_HEADERS,
        json={"email": email, "password": PASSWORD, "email_confirm": True},
    )
    if resp.status_code in (200, 201):
        return resp.json()["id"]
    # Already exists — look it up.
    resp = await client.get(
        f"{SUPABASE_URL}/auth/v1/admin/users",
        headers=ADMIN_HEADERS,
        params={"filter": email, "per_page": 1},
    )
    resp.raise_for_status()
    users = resp.json().get("users", [])
    if not users:
        raise RuntimeError(f"could not create or find auth user {email}: {resp.text}")
    return users[0]["id"]


async def sign_in(client: httpx.AsyncClient, email: str) -> str:
    """Password grant — returns a fresh access_token (JWT)."""
    resp = await client.post(
        f"{SUPABASE_URL}/auth/v1/token",
        headers={"apikey": SERVICE_KEY, "Content-Type": "application/json"},
        params={"grant_type": "password"},
        json={"email": email, "password": PASSWORD},
    )
    resp.raise_for_status()
    return resp.json()["access_token"]


async def ensure_db_row(conn: asyncpg.Connection, auth_id: str, email: str) -> str:
    """Ensure a `users` row exists for this auth user; return the users.id."""
    row = await conn.fetchrow("SELECT id FROM users WHERE auth_id=$1", uuid.UUID(auth_id))
    if row:
        return str(row["id"])
    user_id = uuid.uuid4()
    await conn.execute(
        """
        INSERT INTO users (id, auth_id, email, name, username,
                           onboarding_completed, onboarding_completed_at,
                           fitness_level, goals, equipment, equipment_v2,
                           created_at)
        VALUES ($1, $2, $3, 'Load Test', $4, true, now(),
                'intermediate', '["build_muscle"]',
                '["bodyweight","dumbbells"]', ARRAY['bodyweight','dumbbells'],
                now())
        """,
        user_id, uuid.UUID(auth_id), email, f"loadtest_{user_id.hex[:8]}",
    )
    return str(user_id)


async def cleanup(conn: asyncpg.Connection, client: httpx.AsyncClient) -> None:
    """Delete all load-test users (auth + DB rows)."""
    rows = await conn.fetch(
        "SELECT auth_id FROM users WHERE email LIKE $1", f"%@{EMAIL_DOMAIN}"
    )
    for r in rows:
        await client.delete(
            f"{SUPABASE_URL}/auth/v1/admin/users/{r['auth_id']}", headers=ADMIN_HEADERS
        )
    deleted = await conn.fetchval(
        "WITH d AS (DELETE FROM users WHERE email LIKE $1 RETURNING 1) SELECT count(*) FROM d",
        f"%@{EMAIL_DOMAIN}",
    )
    print(f"Cleaned up {deleted} load-test users.")


async def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--count", type=int, default=200, help="size of the token pool")
    ap.add_argument("--refresh-only", action="store_true",
                    help="skip create/ensure, just re-mint tokens for existing test users")
    ap.add_argument("--cleanup", action="store_true", help="delete all load-test users and exit")
    args = ap.parse_args()

    conn = await asyncpg.connect(DATABASE_URL, statement_cache_size=0)
    async with httpx.AsyncClient(timeout=30) as client:
        if args.cleanup:
            await cleanup(conn, client)
            await conn.close()
            return

        pool = []
        for i in range(1, args.count + 1):
            email = email_for(i)
            try:
                auth_id = await ensure_auth_user(client, email)
                user_id = await ensure_db_row(conn, auth_id, email)
                token = await sign_in(client, email)
                pool.append({"user_id": user_id, "token": token})
                if i % 25 == 0:
                    print(f"  ...{i}/{args.count}")
            except Exception as e:  # noqa: BLE001 — keep going, report at end
                print(f"  ! {email}: {e}", file=sys.stderr)

    await conn.close()
    if not pool:
        print("No tokens generated — aborting.", file=sys.stderr)
        sys.exit(1)
    OUT_FILE.write_text(json.dumps(pool, indent=2))
    print(f"Wrote {len(pool)} tokens to {OUT_FILE}")
    print("Tokens expire in ~1h — re-run with --refresh-only right before a load test.")


if __name__ == "__main__":
    asyncio.run(main())
