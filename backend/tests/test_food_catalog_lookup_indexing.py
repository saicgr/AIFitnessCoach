"""Regression gate: the FREE food-catalog tiers must actually resolve.

`food_database` is 718k OpenFoodFacts-derived rows (1.8 GB) and is heavily
duplicated on name — 33,022 distinct `name_normalized` values carry more than
one row with an image, and 'spaghetti' alone has 437. Two call sites read it,
and both failed silently:

  1. `services.dish_image_service._lookup_food_database` matched on raw,
     case-sensitive `name` equality and capped the result at `.limit(200)`
     ROWS. Because the index emits rows in name order, a couple of
     duplicate-heavy dishes consumed the whole budget and the alphabetical tail
     of every menu fell through to the PAID image-generation path. Measured on
     production before the fix: a realistic 60-dish menu resolved 21 of the 54
     dishes that had a free image; after it, 53 of 60.

  2. `GET /nutrition/search` ran `ilike("name", "%q%")` — a leading-wildcard
     match on a column whose only index is equality-only. Measured: 13.0 s seq
     scan, killed by the 8 s `authenticated` statement_timeout and swallowed by
     a bare except, so the "database" tier returned nothing on every uncached
     query. It also read `calories`/`protein_g`/`serving_size`, columns that do
     not exist on the table, and passed a bigint id to a `str` field.

Both now go through indexed, deduped paths (migration 2385).

Run: backend/.venv312/bin/python -m pytest tests/test_food_catalog_lookup_indexing.py -v
"""
from types import SimpleNamespace
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from fastapi.testclient import TestClient

from core.auth import get_current_user
from main import app
from services import dish_image_service

TEST_USER_ID = "77777777-8888-9999-aaaa-bbbbbbbbbbbb"


# ── 1. dish images: one best row per dish, no row budget ────────────────────


def test_dish_lookup_asks_for_every_dish_and_never_truncates():
    """60+ dishes must all be queried — the old code sliced the menu to 60 and
    then let a 200-ROW cap decide which of those survived."""
    calls = []

    def _fake_rpc(name, params):
        calls.append((name, params["p_keys"]))
        return SimpleNamespace(
            execute=lambda: SimpleNamespace(
                data=[
                    {
                        "dish_key": key,
                        "food_name": key.title(),
                        "food_image_url": f"https://img.example/{key}.jpg",
                    }
                    for key in params["p_keys"]
                ]
            )
        )

    db = MagicMock()
    db.client.rpc.side_effect = _fake_rpc

    wanted = {f"dish {i}": f"Dish {i}" for i in range(600)}
    with patch.object(dish_image_service, "get_supabase_db", return_value=db):
        out = dish_image_service._lookup_food_database(wanted)

    assert calls and calls[0][0] == "dish_image_food_lookup"
    queried = [key for _, chunk in calls for key in chunk]
    assert sorted(queried) == sorted(wanted), "some dishes were never looked up"
    assert len(out) == len(wanted)
    assert out["dish 7"]["source"] == "food_db"
    assert out["dish 7"]["external_url"] == "https://img.example/dish 7.jpg"


def test_dish_lookup_ignores_rows_without_an_image():
    """A catalog row with a null image resolves to nothing, not a broken URL."""
    db = MagicMock()
    db.client.rpc.return_value.execute.return_value = SimpleNamespace(
        data=[
            {"dish_key": "guacamole", "food_name": "Guacamole", "food_image_url": None},
            {"dish_key": "hummus", "food_name": "Hummus", "food_image_url": "https://i/x.jpg"},
        ]
    )
    with patch.object(dish_image_service, "get_supabase_db", return_value=db):
        out = dish_image_service._lookup_food_database(
            {"guacamole": "Guacamole", "hummus": "Hummus"}
        )
    assert "guacamole" not in out
    assert out["hummus"]["external_url"] == "https://i/x.jpg"


def test_dish_lookup_no_longer_selects_the_raw_name_column_with_a_row_cap():
    """Structural guard on the COMPILED function (comments can't satisfy it):
    the PostgREST `table(...).limit(200)` shape is gone and the deduping RPC is
    what the function actually calls."""
    code = dish_image_service._lookup_food_database.__code__
    assert "rpc" in code.co_names
    assert "dish_image_food_lookup" in code.co_consts
    assert "table" not in code.co_names, "still building a PostgREST table query"
    assert "limit" not in code.co_names, "a row cap is back"
    assert 200 not in code.co_consts


# ── 2. /nutrition/search hits an index that exists ──────────────────────────


class _Recorder:
    """Chainable PostgREST stand-in that records the filters applied."""

    def __init__(self, table, canned, log):
        self.table = table
        self._canned = canned
        self._log = log

    def _record(self, op, *args):
        self._log.append((self.table, op, args))
        return self

    def select(self, *a, **k):
        return self._record("select", *a)

    def eq(self, *a, **k):
        return self._record("eq", *a)

    def ilike(self, *a, **k):
        return self._record("ilike", *a)

    def like(self, *a, **k):
        return self._record("like", *a)

    def limit(self, *a, **k):
        return self._record("limit", *a)

    def __getattr__(self, _name):
        return lambda *a, **k: self

    def execute(self):
        return SimpleNamespace(data=self._canned.get(self.table, []))


CATALOG_ROW = {
    "id": 918273645,  # bigint — the model field is a str
    "name": "Greek Yogurt",
    "brand": "Fage",
    "has_serving": True,
    "serving_description": "1 container (170 g)",
    "serving_weight_g": 170.0,
    "calories_per_serving": 100.0,
    "protein_per_serving": 18.0,
    "carbs_per_serving": 6.0,
    "fat_per_serving": 0.7,
    "calories_per_100g": 59.0,
    "protein_per_100g": 10.6,
    "carbs_per_100g": 3.6,
    "fat_per_100g": 0.4,
    "fiber_per_100g": 1.0,
}


@pytest.fixture(autouse=True)
def override_auth():
    app.dependency_overrides[get_current_user] = lambda: {
        "id": TEST_USER_ID,
        "email": "catalog-test@example.com",
    }
    yield
    app.dependency_overrides.pop(get_current_user, None)


def _search(query: str, canned: dict):
    log: list = []
    db = MagicMock()
    db.client.table.side_effect = lambda name: _Recorder(name, canned, log)
    context_service = MagicMock()
    context_service.log_food_search_performed = AsyncMock()
    with patch(
        "api.v1.nutrition_preferences_endpoints.get_supabase_db", return_value=db
    ), patch(
        "api.v1.nutrition_preferences_endpoints.user_context_service", context_service
    ):
        response = TestClient(app).get(f"/api/v1/nutrition/search?q={query}")
    return response, log


def test_search_matches_the_trigram_indexed_column_not_the_bare_name():
    response, log = _search("greek yogurt", {"food_database": [CATALOG_ROW]})

    assert response.status_code == 200, response.text
    catalog_ops = [entry for entry in log if entry[0] == "food_database"]
    assert ("food_database", "ilike", ("name_normalized", "%greek yogurt%")) in catalog_ops, catalog_ops
    # The GIN trigram index is partial on is_primary, so the filter is required
    # for the planner to use it at all.
    assert ("food_database", "eq", ("is_primary", True)) in catalog_ops
    # The old, unindexable shape must not come back.
    assert not [e for e in catalog_ops if e[1] == "ilike" and e[2][0] == "name"]


def test_search_uses_a_prefix_match_when_the_query_is_shorter_than_a_trigram():
    """pg_trgm cannot index a 1-2 char pattern; those use the btree prefix
    index instead of falling back to a full seq scan."""
    _, log = _search("eg", {"food_database": [CATALOG_ROW]})
    catalog_ops = [e for e in log if e[0] == "food_database"]
    assert ("food_database", "like", ("name_normalized", "eg%")) in catalog_ops
    assert not [e for e in catalog_ops if e[1] == "ilike"]


def test_search_maps_the_columns_that_actually_exist():
    """The old code read `calories`/`protein_g`/`serving_size` — none of which
    are columns on food_database — so every catalog hit rendered as 0 kcal."""
    response, _ = _search("greek yogurt", {"food_database": [CATALOG_ROW]})

    assert response.status_code == 200, response.text
    results = [r for r in response.json()["results"] if r["source"] == "database"]
    assert len(results) == 1
    row = results[0]
    assert row["id"] == "918273645"  # bigint coerced to the model's str field
    assert row["total_calories"] == 100
    assert row["protein_g"] == 18.0
    assert row["serving_size"] == "1 container (170 g)"
    assert row["fiber_g"] == pytest.approx(1.7)  # 1.0/100g scaled to 170 g


def test_search_falls_back_to_per_100g_when_there_is_no_serving_block():
    row = dict(CATALOG_ROW, has_serving=False, calories_per_serving=None)
    response, _ = _search("greek yogurt", {"food_database": [row]})

    result = [r for r in response.json()["results"] if r["source"] == "database"][0]
    assert result["total_calories"] == 59
    assert result["serving_size"] == "100 g"


def test_search_drops_a_catalog_row_with_no_energy_value():
    """Showing an unloggable row as '0 kcal' would be a fabricated number."""
    row = dict(
        CATALOG_ROW,
        has_serving=False,
        calories_per_serving=None,
        calories_per_100g=None,
    )
    response, _ = _search("greek yogurt", {"food_database": [row]})
    assert [r for r in response.json()["results"] if r["source"] == "database"] == []
