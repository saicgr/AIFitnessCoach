"""End-to-end tests for B4 — auto-apply a user's OWN food correction.

Flow under test:
  1. POST /api/v1/nutrition/food-report  (report_type='wrong_nutrition')
       → stores the user's corrected macros.
  2. GET  /api/v1/nutrition/food-search?user_id=<id>
       → that user's corrected macros are overlaid on the matched food, and the
         result carries user_corrected=True. ANOTHER user gets the canonical
         (uncorrected) macros with user_corrected=False.

Boots a REAL FastAPI server in a daemon thread (TestClient errors repo-wide
here — see project_testclient_httpx_skew) and drives it with httpx. Only the DB
boundaries are stubbed — the report INSERT, the correction-row FETCH, and the
override search are replaced with in-memory fakes so the test is hermetic. The
behaviour under test (name matching, per-macro ratio overlay, user-scoping, the
user_corrected flag) runs for real, end to end through both HTTP endpoints.

Run:
  backend/.venv/bin/pytest backend/tests/test_user_food_corrections.py -v -s
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
# Server harness (mirrors tests/test_signature_v2_feedback_endpoints.py)
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


# A deterministic canonical food the (stubbed) override search always returns.
# Per-100g, source='verified' so the endpoint maps it to verification_level
# 'curated' and never trips the near-zero-calorie bad-data filter.
_FOOD_NAME = "ZZ Test Burger"
_BASE_FOOD = {
    "name": _FOOD_NAME,
    "calories_per_100g": 250.0,
    "protein_per_100g": 10.0,
    "carbs_per_100g": 20.0,
    "fat_per_100g": 12.0,
    "fiber_per_100g": 1.0,
    "source": "verified",
    "similarity_score": 1.0,
    "verification_level": "verified",
}


@pytest.fixture()
def live_app(monkeypatch):
    """Yield (base_url, user_a, user_b, store) with auth + DB boundaries stubbed."""
    import core.db as core_db
    from main import app
    from core.auth import get_current_user
    from services.food_database_lookup_service import get_food_db_lookup_service

    user_a = str(uuid.uuid4())
    user_b = str(uuid.uuid4())

    # In-memory food_reports table.
    store: list[dict] = []

    # --- Stub the report INSERT (food_reports.py uses core.db.get_supabase_db) ---
    class _FakeInsert:
        def __init__(self, table, data):
            self._data = data

        def execute(self):
            row = dict(self._data)
            row.setdefault("id", str(uuid.uuid4()))
            row.setdefault("created_at", time.time())
            store.append(row)
            return type("R", (), {"data": [row]})()

    class _FakeTable:
        def __init__(self, name):
            self._name = name

        def insert(self, data):
            return _FakeInsert(self._name, data)

    class _FakeClient:
        def table(self, name):
            return _FakeTable(name)

    class _FakeDb:
        client = _FakeClient()

    monkeypatch.setattr(core_db, "get_supabase_db", lambda: _FakeDb(), raising=True)

    # --- Stub the service DB boundaries (override search + correction fetch) ---
    svc = get_food_db_lookup_service()
    # Clear any cross-test cache contamination.
    svc._cache.clear()
    svc._user_corrections_cache.clear()

    async def _fake_override_search(query, *args, **kwargs):
        # Always return the canonical food for any non-empty query.
        return [dict(_BASE_FOOD)] if query else []

    async def _fake_fetch_rows(user_id):
        # Mirror the real SQL: this user's applicable wrong_nutrition rows,
        # newest first.
        rows = [
            r for r in store
            if str(r.get("user_id")) == str(user_id)
            and r.get("report_type") == "wrong_nutrition"
            and r.get("corrected_calories") is not None
            and r.get("status", "pending") in ("pending", "reviewed", "resolved")
        ]
        rows.sort(key=lambda r: r.get("created_at", 0), reverse=True)
        return rows

    monkeypatch.setattr(svc, "_search_overrides_db", _fake_override_search, raising=True)
    monkeypatch.setattr(svc, "_fetch_user_correction_rows", _fake_fetch_rows, raising=True)

    # Auth: default to user A (the reporter). The search user is driven by the
    # `user_id` query param, independent of the authenticated principal.
    async def _fake_user():
        return {"id": user_a, "email": "b4-test@local"}

    app.dependency_overrides[get_current_user] = _fake_user
    server, base = _start_server()
    try:
        yield base, user_a, user_b, svc
    finally:
        app.dependency_overrides.pop(get_current_user, None)
        server.should_exit = True
        time.sleep(0.3)


def _search(base: str, user_id: str) -> dict:
    with httpx.Client(timeout=30) as client:
        resp = client.get(
            f"{base}/api/v1/nutrition/food-search",
            params={"query": "zz test burger", "user_id": user_id},
        )
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["foods"], f"expected a result, got {body}"
    return body["foods"][0]


def test_user_correction_applied_and_scoped(live_app):
    base, user_a, user_b, svc = live_app

    # 1) Baseline — no correction yet.
    food = _search(base, user_a)
    assert food["nutrients"]["kcal"] == 250.0
    assert food["nutrients"]["protein_g"] == 10.0
    assert food["user_corrected"] is False

    # 2) User A reports the macros as wrong (doubles calories + protein).
    #    original_* mirror the canonical per-100g values so the ratio overlay
    #    resolves to exactly the corrected values here.
    payload = {
        "user_id": user_a,
        "food_name": _FOOD_NAME,
        "report_type": "wrong_nutrition",
        "original_calories": 250.0,
        "original_protein": 10.0,
        "original_carbs": 20.0,
        "original_fat": 12.0,
        "corrected_calories": 500.0,
        "corrected_protein": 20.0,
        "corrected_carbs": 20.0,
        "corrected_fat": 12.0,
    }
    with httpx.Client(timeout=30) as client:
        rep = client.post(f"{base}/api/v1/nutrition/food-report", json=payload)
    assert rep.status_code == 200, rep.text
    assert rep.json()["success"] is True

    # The baseline search cached an empty correction set for user A (60s TTL);
    # expire it so the just-submitted correction is picked up immediately.
    svc._user_corrections_cache.clear()

    # 3) User A now sees THEIR corrected macros + the user_corrected flag.
    food_a = _search(base, user_a)
    assert food_a["nutrients"]["kcal"] == 500.0, food_a
    assert food_a["nutrients"]["protein_g"] == 20.0, food_a
    # Unchanged macros stay at canonical values.
    assert food_a["nutrients"]["carbs_g"] == 20.0, food_a
    assert food_a["nutrients"]["fat_g"] == 12.0, food_a
    assert food_a["user_corrected"] is True

    # 4) A DIFFERENT user gets the canonical (uncorrected) data.
    food_b = _search(base, user_b)
    assert food_b["nutrients"]["kcal"] == 250.0, food_b
    assert food_b["nutrients"]["protein_g"] == 10.0, food_b
    assert food_b["user_corrected"] is False


def test_partial_correction_uses_ratio_not_serving_units(live_app):
    """A correction reported in per-SERVING units is overlaid as a ratio, so a
    food whose per-100g value differs from the reported serving still scales
    correctly (×2 here), never copying the raw serving number into per-100g."""
    base, user_a, _user_b, svc = live_app

    # User reported a 200g serving: original 500 kcal → corrected 1000 kcal (×2).
    # Canonical per-100g is 250; the overlay must yield 500 (250 × 2), NOT 1000.
    payload = {
        "user_id": user_a,
        "food_name": _FOOD_NAME,
        "report_type": "wrong_nutrition",
        "original_calories": 500.0,   # per-serving value the user saw
        "corrected_calories": 1000.0,  # corrected per-serving value
    }
    with httpx.Client(timeout=30) as client:
        rep = client.post(f"{base}/api/v1/nutrition/food-report", json=payload)
    assert rep.status_code == 200, rep.text
    svc._user_corrections_cache.clear()

    food = _search(base, user_a)
    assert food["nutrients"]["kcal"] == 500.0, food  # 250 per-100g × (1000/500)
    assert food["user_corrected"] is True
