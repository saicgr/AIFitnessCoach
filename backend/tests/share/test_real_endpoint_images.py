"""End-to-end test against the actual /share/classify FastAPI endpoint.

Boots the real FastAPI app, overrides `get_current_user` to inject a
real Supabase user_id (so the RLS-backed FK constraint is satisfied),
POSTs each committed fixture image as multipart form-data, and prints
the actual JSON response the client would receive.

Demonstrates the FULL endpoint behavior including:
  - The real Gemini classify call
  - A shared_items row created in Supabase
  - The classifier_confidence + routing_hint mapping
  - The shared_item_id returned to the client (for Imports history)

Gated on RUN_ENDPOINT_TESTS=1. Run:

  RUN_ENDPOINT_TESTS=1 backend/.venv/bin/pytest \\
    backend/tests/share/test_real_endpoint_images.py -v -s
"""
from __future__ import annotations

import json
import os
import time
from pathlib import Path

import httpx
import psycopg2
import pytest
import threading
import uvicorn

LIVE = os.environ.get("RUN_ENDPOINT_TESTS") == "1"
pytestmark = pytest.mark.skipif(not LIVE, reason="Set RUN_ENDPOINT_TESTS=1 to run")

FIXTURES = Path(__file__).parent / "fixtures"


def _real_user_id() -> str:
    """Pick a real auth.users id so FK constraints are satisfied."""
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


def _cleanup_user_rows(user_id: str) -> None:
    """Delete any shared_items + rate_counter rows the test inserted."""
    url = (os.environ.get("DATABASE_URL_DIRECT") or os.environ["DATABASE_URL"]).replace(
        "postgresql+asyncpg://", "postgresql://"
    )
    conn = psycopg2.connect(url)
    try:
        cur = conn.cursor()
        cur.execute(
            "DELETE FROM shared_items WHERE user_id = %s AND raw_text LIKE 'ENDPOINT_TEST%%' OR tags->>'test_run' = 'endpoint_images'",
            (user_id,),
        )
        # Reset today's image counter so we don't accidentally hit the cap.
        cur.execute(
            "DELETE FROM share_rate_counters WHERE user_id = %s AND bucket = 'image' AND day_local = CURRENT_DATE",
            (user_id,),
        )
        conn.commit()
    finally:
        conn.close()


def test_share_classify_endpoint_with_real_images() -> None:
    """Threaded uvicorn + httpx (per project memory testclient_httpx_skew).

    Uses FastAPI dependency_overrides to inject a real user, then POSTs
    each fixture image as multipart form-data.
    """
    from main import app
    from core.auth import get_current_user

    user_id = _real_user_id()
    _cleanup_user_rows(user_id)

    async def _fake_user():
        return {"id": user_id, "email": "endpoint-test@local"}

    app.dependency_overrides[get_current_user] = _fake_user

    # ----- spin uvicorn on a free port in a daemon thread ---------------
    import socket
    s = socket.socket(); s.bind(("127.0.0.1", 0)); port = s.getsockname()[1]; s.close()

    config = uvicorn.Config(app, host="127.0.0.1", port=port, log_level="warning",
                            lifespan="off")
    server = uvicorn.Server(config)
    t = threading.Thread(target=server.run, daemon=True)
    t.start()

    # Wait for server to be ready
    base = f"http://127.0.0.1:{port}"
    for _ in range(50):
        try:
            with httpx.Client(timeout=1.0) as client:
                client.get(f"{base}/docs")
            break
        except Exception:
            time.sleep(0.1)

    fixtures: list[tuple[str, str]] = [
        ("food_plate.jpg",      "food plate"),
        ("restaurant_menu.jpg", "restaurant menu"),
        ("gym_equipment.jpg",   "gym equipment"),
        ("exercise_form.jpg",   "exercise form"),
        ("progress_photo.jpg",  "progress photo"),
    ]

    rows: list[dict] = []
    print("\n\n========== POST /api/v1/share/classify — real fixture images ==========\n")
    try:
        with httpx.Client(timeout=30, base_url=base) as client:
            for filename, label in fixtures:
                path = FIXTURES / filename
                with open(path, "rb") as fh:
                    t0 = time.time()
                    resp = client.post(
                        "/api/v1/share/classify",
                        files={"file": (filename, fh.read(), "image/jpeg")},
                        data={"source_origin": "endpoint-test", "track": "true"},
                    )
                elapsed = round(time.time() - t0, 2)
                body = resp.json() if resp.headers.get("content-type", "").startswith("application/json") else resp.text
                rows.append({"label": label, "status": resp.status_code, "body": body, "elapsed_s": elapsed})

                print(f"--- {label} ({filename}) ---")
                print(f"  HTTP {resp.status_code}  ({elapsed}s)")
                print(f"  Response JSON:")
                print(json.dumps(body, indent=4) if isinstance(body, dict) else body)
                print()
    finally:
        app.dependency_overrides.pop(get_current_user, None)
        server.should_exit = True
        time.sleep(0.5)

    # ----- show the Imports history rows that were created --------------
    print("========== shared_items rows persisted by these calls ==========\n")
    url = (os.environ.get("DATABASE_URL_DIRECT") or os.environ["DATABASE_URL"]).replace(
        "postgresql+asyncpg://", "postgresql://"
    )
    conn = psycopg2.connect(url)
    try:
        cur = conn.cursor()
        cur.execute(
            """
            SELECT id, source_kind, source_origin, classifier_confidence,
                   status, target_entity_kind, tags
            FROM shared_items
            WHERE user_id = %s AND source_origin = 'endpoint-test'
            ORDER BY created_at DESC
            LIMIT 20
            """,
            (user_id,),
        )
        for r in cur.fetchall():
            print(f"  id={str(r[0])[:8]}…  kind={r[1]:6}  origin={r[2]:14}  "
                  f"confidence={r[3]!s:6}  status={r[4]:10}  category={r[6].get('category') if r[6] else '—'}")
    finally:
        conn.close()

    # ----- cleanup -------------------------------------------------------
    _cleanup_user_rows(user_id)

    # ----- assertions ----------------------------------------------------
    assert all(r["status"] == 200 for r in rows), "Not every call returned 200"
    successful = sum(1 for r in rows if isinstance(r["body"], dict)
                     and r["body"].get("content_type") not in {None, "unknown"})
    assert successful >= 4, f"Only {successful}/5 endpoint calls returned a real content_type"
