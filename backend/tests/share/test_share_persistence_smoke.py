"""Smoke tests against a live Supabase connection — exercises the
shared_items table schema + the share_recent_softhash RPC.

These tests run against the dev Supabase project (DATABASE_URL_DIRECT
in backend/.env) and clean up after themselves. They are
opt-in via the SHARE_LIVE_TESTS env var so CI doesn't accidentally hit
the dev DB.

Run with:
  SHARE_LIVE_TESTS=1 backend/.venv/bin/pytest backend/tests/share/test_share_persistence_smoke.py -v
"""
from __future__ import annotations

import os
import uuid

import pytest

LIVE = os.environ.get("SHARE_LIVE_TESTS") == "1"
pytestmark = pytest.mark.skipif(not LIVE, reason="Set SHARE_LIVE_TESTS=1 to run")


@pytest.fixture
def db():
    from core.db import get_supabase_db
    return get_supabase_db()


@pytest.fixture
def real_user_id() -> str:
    """Pick any real user id from auth.users (not public.users — the FK on
    shared_items references auth.users). Uses a direct psycopg2 connection
    since postgrest doesn't expose the auth schema to anon/authenticated."""
    import psycopg2
    url = (os.environ.get("DATABASE_URL_DIRECT") or os.environ["DATABASE_URL"]).replace(
        "postgresql+asyncpg://", "postgresql://"
    )
    conn = psycopg2.connect(url)
    try:
        cur = conn.cursor()
        cur.execute("SELECT id FROM auth.users LIMIT 1")
        row = cur.fetchone()
        if not row:
            pytest.skip("auth.users is empty")
        return str(row[0])
    finally:
        conn.close()


def test_shared_items_insert_and_select(db, real_user_id: str) -> None:
    row = {
        "user_id": real_user_id,
        "source_kind": "text",
        "source_origin": "manual_paste",
        "raw_text": "smoke test",
        "tags": {"format": "text", "origin": "manual_paste", "soft_hash": "abc"},
        "status": "received",
    }
    res = db.client.table("shared_items").insert(row).execute()
    assert res.data, res
    item_id = res.data[0]["id"]

    try:
        # Select back
        got = (
            db.client.table("shared_items")
            .select("*")
            .eq("id", item_id)
            .limit(1)
            .execute()
        )
        assert got.data[0]["source_kind"] == "text"
        assert got.data[0]["tags"]["origin"] == "manual_paste"

        # share_recent_softhash returns it for the same hash
        rpc = db.client.rpc(
            "share_recent_softhash",
            {"p_user_id": real_user_id, "p_soft_hash": "abc", "p_window_seconds": 600},
        ).execute()
        assert any(str(r["id"]) == item_id for r in (rpc.data or []))
    finally:
        db.client.table("shared_items").delete().eq("id", item_id).execute()


def test_share_rate_increment_counts_and_returns_new_value(db, real_user_id: str) -> None:
    today = "2099-01-01"  # far-future day so we don't pollute today's counters
    bucket = "smoke"
    try:
        for expected in range(1, 4):
            res = db.client.rpc(
                "share_rate_increment",
                {"p_user_id": real_user_id, "p_day": today, "p_bucket": bucket},
            ).execute()
            count = (res.data[0]["count"] if isinstance(res.data, list) and res.data else None)
            assert count == expected, (count, expected, res.data)
    finally:
        db.client.table("share_rate_counters").delete().eq(
            "user_id", real_user_id
        ).eq("day_local", today).execute()
