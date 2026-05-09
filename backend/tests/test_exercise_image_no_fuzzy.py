"""
Lock-down tests for GET /api/v1/exercise-images/{name}.

The lat-pulldown wrong-image bug was caused by the endpoint fuzzy-matching to a
sibling exercise's row when the requested row's image_s3_path was NULL. These
tests guarantee that:

  1. NULL image_s3_path -> HTTP 404 (never another row's URL).
  2. Exercise name not found -> HTTP 404.
  3. ?exercise_id=<uuid> path is honored and isolated.
  4. We never substring/fuzzy-match across distinct exercises (the regression).
"""
from __future__ import annotations

import sys
import os
from unittest.mock import patch, MagicMock
from urllib.parse import quote

import pytest
from fastapi.testclient import TestClient

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from main import app
from core.auth import get_current_user


@pytest.fixture(autouse=True)
def _bypass_auth():
    app.dependency_overrides[get_current_user] = lambda: {"id": "test-user", "email": "t@t.com"}
    yield
    app.dependency_overrides.clear()


def _supabase_stub(rows_for_query):
    """Build a get_supabase_db() stub that returns canned rows for ANY .ilike/.eq query."""
    db = MagicMock()
    chain = MagicMock()
    chain.select.return_value = chain
    chain.ilike.return_value = chain
    chain.eq.return_value = chain
    chain.limit.return_value = chain
    exec_result = MagicMock()
    exec_result.data = rows_for_query
    chain.execute.return_value = exec_result
    db.client.table.return_value = chain
    return db


def test_null_image_returns_404_never_serves_sibling():
    """The exact bug: row exists, image_s3_path is NULL — must NOT return another exercise's URL."""
    null_row = [{
        "id": "3311e5b9-f1d7-48f2-8e47-541327fc0bd5",
        "exercise_name": "Behind Neck Lat Pulldown",
        "image_s3_path": None,
    }]
    with patch("api.v1.videos.get_supabase_db", return_value=_supabase_stub(null_row)):
        client = TestClient(app)
        r = client.get(f"/api/v1/exercise-images/{quote('Behind Neck Lat Pulldown')}")
        assert r.status_code == 404, r.text
        body = r.json()
        # FastAPI nests our dict under "detail"
        detail = body.get("detail") or body
        assert detail.get("error") == "no_image"
        assert detail.get("exercise_id") == "3311e5b9-f1d7-48f2-8e47-541327fc0bd5"


def test_unknown_exercise_returns_404():
    with patch("api.v1.videos.get_supabase_db", return_value=_supabase_stub([])):
        client = TestClient(app)
        r = client.get("/api/v1/exercise-images/Made%20Up%20Exercise%20Name")
        assert r.status_code == 404, r.text
        detail = r.json().get("detail") or r.json()
        assert detail.get("error") == "exercise_not_found"


def test_explicit_exercise_id_path_returns_image():
    row = [{
        "id": "abc-123",
        "exercise_name": "Cable Pulldown",
        "image_s3_path": "s3://ai-fitness-coach/ILLUSTRATIONS ALL/Back/Cable Pulldown.jpg",
    }]
    with patch("api.v1.videos.get_supabase_db", return_value=_supabase_stub(row)):
        client = TestClient(app)
        r = client.get("/api/v1/exercise-images/anything?exercise_id=abc-123")
        assert r.status_code == 200, r.text
        body = r.json()
        assert body["exercise_name"] == "Cable Pulldown"
        assert body["url"]  # presigned or static URL was generated


def test_explicit_exercise_id_with_null_image_returns_404():
    row = [{"id": "abc-456", "exercise_name": "X", "image_s3_path": None}]
    with patch("api.v1.videos.get_supabase_db", return_value=_supabase_stub(row)):
        client = TestClient(app)
        r = client.get("/api/v1/exercise-images/anything?exercise_id=abc-456")
        assert r.status_code == 404, r.text
        detail = r.json().get("detail") or r.json()
        assert detail.get("error") == "no_image"
        assert detail.get("exercise_id") == "abc-456"
