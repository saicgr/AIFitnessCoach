"""End-to-end tests for the Signature v2 feedback endpoints:

  POST /api/v1/feedback/exercise-critique   (Task 1)
  POST /api/v1/feedback/recap/detailed      (Task 2)

Boots a REAL FastAPI server in a daemon thread (TestClient errors repo-wide
here — see project_testclient_httpx_skew) and drives it with httpx. Auth is
satisfied by overriding `get_current_user`; the Gemini call is monkeypatched to
RAISE so we exercise the deterministic FAIL-OPEN path that must hold when the AI
key is absent. Both endpoints must return valid markdown with is_fallback=True
and never 500.

Run:
  backend/.venv/bin/pytest backend/tests/test_signature_v2_feedback_endpoints.py -v -s
"""
from __future__ import annotations

import socket
import threading
import time
import uuid

import httpx
import pytest
import uvicorn


# ---------------------------------------------------------------------------
# Server harness (mirrors tests/share/test_real_endpoint_sse.py)
# ---------------------------------------------------------------------------

def _start_server():
    from main import app
    s = socket.socket(); s.bind(("127.0.0.1", 0)); port = s.getsockname()[1]; s.close()
    config = uvicorn.Config(app, host="127.0.0.1", port=port, log_level="warning",
                            lifespan="off")
    server = uvicorn.Server(config)
    t = threading.Thread(target=server.run, daemon=True)
    t.start()
    base = f"http://127.0.0.1:{port}"
    for _ in range(60):
        try:
            with httpx.Client(timeout=1.0) as client:
                client.get(f"{base}/docs")
            break
        except Exception:
            time.sleep(0.1)
    return server, base


@pytest.fixture()
def live_app(monkeypatch):
    """Yield (base_url, user_id) with auth overridden + Gemini forced to fail.

    Forcing `gemini_generate_with_retry` to raise simulates "the AI key is
    absent": every LLM-backed surface must fall open to its deterministic path.
    """
    from main import app
    from core.auth import get_current_user

    user_id = str(uuid.uuid4())

    async def _fake_user():
        return {"id": user_id, "email": "sigv2-test@local"}

    async def _boom(*args, **kwargs):
        raise RuntimeError("simulated missing Gemini key")

    # Patch the retry wrapper imported INSIDE the service functions (they do a
    # late `from services.gemini.constants import gemini_generate_with_retry`).
    monkeypatch.setattr(
        "services.gemini.constants.gemini_generate_with_retry", _boom, raising=True
    )

    app.dependency_overrides[get_current_user] = _fake_user
    server, base = _start_server()
    try:
        yield base, user_id
    finally:
        app.dependency_overrides.pop(get_current_user, None)
        server.should_exit = True
        time.sleep(0.3)


# ---------------------------------------------------------------------------
# Task 1 — POST /feedback/exercise-critique
# ---------------------------------------------------------------------------

def test_exercise_critique_fails_open_to_markdown(live_app):
    base, _user_id = live_app
    payload = {
        "exercise_name": "Bench Press",
        "exercise_id": None,
        "target": {"weight_kg": 60.0, "reps": 8, "rir": 2},
        "sets": [
            {"weight_kg": 60.0, "reps": 8, "rir": 2, "duration_seconds": None, "set_type": "working"},
            {"weight_kg": 60.0, "reps": 7, "rir": 1, "duration_seconds": None, "set_type": "working"},
            {"weight_kg": 57.5, "reps": 6, "rir": 0, "duration_seconds": None, "set_type": "working"},
        ],
        "use_kg": False,
    }
    with httpx.Client(timeout=30) as client:
        resp = client.post(f"{base}/api/v1/feedback/exercise-critique", json=payload)
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["is_fallback"] is True, "Gemini was forced to fail → must be deterministic"
    md = body["critique_markdown"]
    assert md and "**" in md, "Critique must be non-empty markdown with a bold lead"
    # Weight phrased in lb (use_kg=False) — 60kg ≈ 132lb.
    assert "lb" in md and "kg" not in md, f"Expected lb-only weights, got: {md!r}"
    # Exactly-one-cue convention: the deterministic critique tags its cue bold.
    assert "**Next time:**" in md
    print("\n[critique] ", md)


def test_exercise_critique_empty_sets_is_safe(live_app):
    base, _ = live_app
    payload = {
        "exercise_name": "Plank",
        "target": None,
        "sets": [],
        "use_kg": True,
    }
    with httpx.Client(timeout=30) as client:
        resp = client.post(f"{base}/api/v1/feedback/exercise-critique", json=payload)
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["is_fallback"] is True
    assert body["critique_markdown"].strip(), "Never blank, even with no sets"


# ---------------------------------------------------------------------------
# Task 2 — POST /feedback/recap/detailed
# ---------------------------------------------------------------------------

def test_detailed_summary_fails_open_with_all_sections(live_app):
    base, user_id = live_app
    payload = {
        "user_id": user_id,
        "workout_id": f"test-{uuid.uuid4()}",
        "workout_name": "Push Day",
        "workout_type": "strength",
        "exercises": [
            {"name": "Bench Press", "sets": 3, "reps": 8, "weight_kg": 60.0, "time_seconds": 360},
            {"name": "Overhead Press", "sets": 3, "reps": 10, "weight_kg": 35.0, "time_seconds": 300},
        ],
        "planned_exercises": [
            {"name": "Bench Press", "sets": 3, "reps": 8, "weight_kg": 60.0},
            {"name": "Overhead Press", "sets": 3, "reps": 10, "weight_kg": 35.0},
            {"name": "Triceps Pushdown", "sets": 3, "reps": 12, "weight_kg": 25.0},
        ],
        "total_time_seconds": 1800,
        "total_sets": 6,
        "total_reps": 54,
        "total_volume_kg": 2490.0,
        "force": True,
    }
    with httpx.Client(timeout=40) as client:
        resp = client.post(f"{base}/api/v1/feedback/recap/detailed", json=payload)
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["is_fallback"] is True, "Gemini forced to fail → deterministic summary"
    md = body["summary_markdown"]
    for section in ("**Strengths**", "**Weaknesses**", "**What to improve**", "**What to do next**"):
        assert section in md, f"Missing required section {section!r}:\n{md}"
    # Skipped exercise (Triceps Pushdown) should surface as a weakness.
    assert "Triceps Pushdown" in md
    print("\n[detailed]\n", md)


def test_detailed_summary_access_denied_on_user_mismatch(live_app):
    base, _user_id = live_app
    payload = {
        "user_id": str(uuid.uuid4()),  # not the authed user
        "workout_id": f"test-{uuid.uuid4()}",
        "force": True,
    }
    with httpx.Client(timeout=20) as client:
        resp = client.post(f"{base}/api/v1/feedback/recap/detailed", json=payload)
    assert resp.status_code == 403, resp.text
