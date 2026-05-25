"""End-to-end test against the SSE share endpoints:
  POST /api/v1/share/import-text   (text payload)
  POST /api/v1/share/import-audio  (multipart audio file)
  POST /api/v1/share/import-pdf    (multipart PDF file)

Boots a real FastAPI server in a daemon thread, overrides
`get_current_user` to inject a real Supabase user (so RLS + FK
constraints are satisfied), POSTs each fixture, captures the FULL SSE
event stream, and prints every event the client would receive.

Run:
  RUN_ENDPOINT_TESTS=1 backend/.venv/bin/pytest \\
    backend/tests/share/test_real_endpoint_sse.py -v -s
"""
from __future__ import annotations

import json
import os
import socket
import threading
import time
from pathlib import Path

import httpx
import psycopg2
import pytest
import uvicorn

LIVE = os.environ.get("RUN_ENDPOINT_TESTS") == "1"
pytestmark = pytest.mark.skipif(not LIVE, reason="Set RUN_ENDPOINT_TESTS=1 to run")

FIXTURES = Path(__file__).parent / "fixtures"


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _db_url() -> str:
    return (os.environ.get("DATABASE_URL_DIRECT") or os.environ["DATABASE_URL"]).replace(
        "postgresql+asyncpg://", "postgresql://"
    )


def _real_user_id() -> str:
    conn = psycopg2.connect(_db_url())
    try:
        cur = conn.cursor()
        cur.execute("SELECT id FROM auth.users LIMIT 1")
        row = cur.fetchone()
        if not row:
            pytest.skip("auth.users is empty")
        return str(row[0])
    finally:
        conn.close()


def _cleanup_user(user_id: str) -> None:
    """Aggressively purge every row created by the SSE endpoint test so
    soft-dedupe doesn't short-circuit subsequent runs."""
    conn = psycopg2.connect(_db_url())
    try:
        cur = conn.cursor()
        # By origin (covers text + audio + PDF + every URL source)
        cur.execute(
            """DELETE FROM shared_items
               WHERE user_id = %s
                 AND source_origin = ANY(%s)""",
            (user_id, [
                "endpoint-test-text", "voicememos", "files",
                "manual_paste", "chatgpt", "claude", "perplexity",
                "web", "youtube", "reddit", "x", "instagram", "tiktok",
            ]),
        )
        # Reset today's counters for every bucket
        cur.execute(
            """DELETE FROM share_rate_counters
               WHERE user_id = %s
                 AND bucket = ANY(%s)
                 AND day_local = CURRENT_DATE""",
            (user_id, ["text", "audio", "pdf", "url", "image"]),
        )
        conn.commit()
    finally:
        conn.close()


def _start_server() -> tuple[uvicorn.Server, str]:
    from main import app
    # pick a free port
    s = socket.socket(); s.bind(("127.0.0.1", 0)); port = s.getsockname()[1]; s.close()
    config = uvicorn.Config(app, host="127.0.0.1", port=port, log_level="warning",
                            lifespan="off")
    server = uvicorn.Server(config)
    t = threading.Thread(target=server.run, daemon=True)
    t.start()
    base = f"http://127.0.0.1:{port}"
    # Wait until /docs is up
    for _ in range(60):
        try:
            with httpx.Client(timeout=1.0) as client:
                client.get(f"{base}/docs")
            break
        except Exception:
            time.sleep(0.1)
    return server, base


def _stream_sse(method: str, url: str, **kwargs) -> list[dict]:
    """Hit an SSE endpoint and return the full ordered list of parsed
    events. Each event was originally `data: {…}\\n\\n`."""
    events: list[dict] = []
    with httpx.Client(timeout=60) as client:
        with client.stream(method, url, **kwargs) as resp:
            assert resp.status_code == 200, f"HTTP {resp.status_code}: {resp.read()!r}"
            buf = ""
            for raw_line in resp.iter_lines():
                line = raw_line if isinstance(raw_line, str) else raw_line.decode("utf-8", errors="replace")
                if not line:
                    if buf:
                        try:
                            events.append(json.loads(buf))
                        except json.JSONDecodeError:
                            pass
                        buf = ""
                    continue
                if line.startswith("data:"):
                    buf += line[5:].strip()
    return events


def _print_events(events: list[dict]) -> None:
    for evt in events:
        stage = evt.get("stage", "(no stage)")
        # Keep prints terse — only show the most informative keys
        head = {k: v for k, v in evt.items() if k != "stage" and k not in {"payload"}}
        head_str = ""
        if head:
            # Truncate long string values
            shrunk = {k: (v[:120] + "…" if isinstance(v, str) and len(v) > 120 else v)
                      for k, v in head.items()}
            head_str = "  " + json.dumps(shrunk, default=str)
        print(f"  • {stage}{head_str}")
        # If a 'payload' object is present (done event), summarize it
        if isinstance(evt.get("payload"), dict):
            p = evt["payload"]
            keys = sorted(p.keys())
            print(f"      payload keys: {keys}")
            if "exercises" in p:
                exs = p["exercises"]
                print(f"      exercises ({len(exs)}):")
                for ex in exs[:6]:
                    print(f"        - {ex.get('name'):30}  sets={ex.get('sets')}  reps={ex.get('reps')}  rest_s={ex.get('rest_s')}")
            if "text_preview" in p:
                print(f"      text_preview: {p['text_preview'][:120]!r}…")


# ---------------------------------------------------------------------------
# Combined SSE endpoint test (text + audio + PDF + URL).
# ---------------------------------------------------------------------------

def test_share_sse_endpoints_end_to_end() -> None:
    from main import app
    from core.auth import get_current_user

    user_id = _real_user_id()
    _cleanup_user(user_id)

    async def _fake_user():
        return {"id": user_id, "email": "sse-test@local"}

    app.dependency_overrides[get_current_user] = _fake_user
    server, base = _start_server()

    try:
        # ----- 1) /share/import-text -----------------------------------
        print("\n\n========== POST /api/v1/share/import-text ==========\n")
        for fname, hint in [
            ("chatgpt_workout.txt",  "chatgpt"),
            ("chatgpt_recipe.txt",   "chatgpt"),
            ("claude_meal_plan.txt", "claude"),
            ("perplexity_tip.txt",   "perplexity"),
        ]:
            text = (FIXTURES / fname).read_text(encoding="utf-8")
            print(f"--- {fname}  (source_hint={hint}, {len(text)} chars) ---")
            t0 = time.time()
            events = _stream_sse(
                "POST", f"{base}/api/v1/share/import-text",
                json={"text": text, "source_hint": hint},
            )
            elapsed = round(time.time() - t0, 2)
            print(f"  total events: {len(events)}   elapsed: {elapsed}s")
            _print_events(events)
            print()

        # ----- 2) /share/import-audio ----------------------------------
        print("\n========== POST /api/v1/share/import-audio ==========\n")
        for fname in ["voice_workout_log.m4a", "voice_food_log.m4a", "voice_trainer_tip.m4a"]:
            path = FIXTURES / fname
            print(f"--- {fname}  ({path.stat().st_size} bytes) ---")
            with open(path, "rb") as fh:
                t0 = time.time()
                events = _stream_sse(
                    "POST", f"{base}/api/v1/share/import-audio",
                    files={"file": (fname, fh.read(), "audio/mp4")},
                )
            elapsed = round(time.time() - t0, 2)
            print(f"  total events: {len(events)}   elapsed: {elapsed}s")
            _print_events(events)
            print()

        # ----- 3) /share/import-pdf ------------------------------------
        print("\n========== POST /api/v1/share/import-pdf ==========\n")
        for fname in ["recipe_cookbook.pdf", "workout_program.pdf"]:
            path = FIXTURES / fname
            print(f"--- {fname}  ({path.stat().st_size} bytes) ---")
            with open(path, "rb") as fh:
                t0 = time.time()
                events = _stream_sse(
                    "POST", f"{base}/api/v1/share/import-pdf",
                    files={"file": (fname, fh.read(), "application/pdf")},
                )
            elapsed = round(time.time() - t0, 2)
            print(f"  total events: {len(events)}   elapsed: {elapsed}s")
            _print_events(events)
            print()

        # ----- 4) /share/fetch-url — recipe blogs, Reddit, X, YouTube --
        print("\n========== POST /api/v1/share/fetch-url (real public URLs) ==========\n")

        url_targets: list[tuple[str, str]] = [
            ("NYT Cooking recipe (blog)",
             "https://cooking.nytimes.com/recipes/1019047-creamy-roasted-tomato-soup"),
            ("Wikipedia recipe page",
             "https://en.wikipedia.org/wiki/Chicken_tikka_masala"),
            ("Reddit r/Fitness post",
             "https://www.reddit.com/r/Fitness/comments/1tn1bsc/moronic_monday_your_weekly_stupid_questions_thread/"),
        ]
        if os.environ.get("YT_DATA_API_KEY"):
            url_targets.append(
                # "The PERFECT Home Workout (Sets and Reps Included)" —
                # AthleanX, public, 528 captioned segments. Exactly the
                # share a fitness user would actually do.
                ("YouTube workout video (real captioned)",
                 "https://www.youtube.com/watch?v=vc1E5CfRfos")
            )
        else:
            print("(YouTube test skipped — set YT_DATA_API_KEY in backend/.env to enable)\n")

        for label, url in url_targets:
            print(f"--- {label} ---")
            print(f"  url: {url}")
            t0 = time.time()
            events = _stream_sse(
                "POST", f"{base}/api/v1/share/fetch-url",
                json={"url": url},
            )
            elapsed = round(time.time() - t0, 2)
            print(f"  total events: {len(events)}   elapsed: {elapsed}s")
            _print_events(events)
            print()

    finally:
        app.dependency_overrides.pop(get_current_user, None)
        server.should_exit = True
        time.sleep(0.5)
        _cleanup_user(user_id)
