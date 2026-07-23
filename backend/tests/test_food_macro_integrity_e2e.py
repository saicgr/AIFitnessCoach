"""End-to-end macro-integrity regression tests (round 2).

Round 1 shipped `flag_unknown_macros()`, which set a flag but left the item
without protein_g/carbs_g/fat_g. Every caller re-sums with
`item.get('protein_g', 0) or 0`, so the flag changed nothing: the SSE `done`
payload still reported protein=0.0 and the row still persisted 0/0/0.

These tests therefore drive the REAL producers and the REAL persistence call —
not the parser helper in isolation:

  * `FoodAnalysisCacheService.analyze_food` — the single entry point behind
    /analyze-text-stream, /log-text, /analyze-text and saved-food re-analysis.
    ELEVEN cache-stack returns funnel through it and most never touch
    `_enhance_food_items_with_nutrition_db`.
  * `POST /nutrition/log-image-stream` — the photo path that writes to
    `food_logs` with NO user confirmation, driven through the FastAPI app with
    a fake DB that captures the exact `create_food_log(**kwargs)`.

Both directions are asserted:
  1. a >0-calorie NON-alcoholic item never lands as 0/0/0 (macros become an
     explicit NULL + `macros_unknown`), and
  2. a distilled spirit legitimately DOES land as 0P/0C/0F with real calories,
     because ethanol carries ~6.93 kcal/g and none of the other three.

Every DB row used below is copied from PRODUCTION
(`food_nutrition_overrides`, project hpbzfahijszqmgsybuor), not invented:
  - display_name='Vodka (80 Proof)', food_category='alcohol', source='usda',
    231 kcal/100g, 0/0/0  ← the reviewer's reproduced alcohol false positive
  - display_name='Finlandia Vodka', food_category='beverage', 231/0/0/0
  - display_name="Clarke's Court Pure White Rum (151)", food_category=
    'beverage', 345/0/0/0, notes '...151-proof (75.5%)...'
"""

import sys
from pathlib import Path
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from services.gemini.parsers import (  # noqa: E402
    alcohol_accounts_for_calories,
    ai_item_macros_unknown,
    db_row_macros_unusable,
    enforce_macro_integrity,
)


# ---------------------------------------------------------------------------
# Production row fixtures (verbatim shapes from food_nutrition_overrides)
# ---------------------------------------------------------------------------

# The reviewer's repro: a REAL USDA distilled-spirit row. 0/0/0 is CORRECT here.
PROD_VODKA_80_PROOF = {
    "display_name": "Vodka (80 Proof)",
    "food_category": "alcohol",
    "source": "usda",
    "calories_per_100g": 231.0,
    "protein_per_100g": 0.0,
    "carbs_per_100g": 0.0,
    "fat_per_100g": 0.0,
    "fiber_per_100g": 0.0,
}

# Same product family, weaker taxonomy label ('beverage'), but the display name
# declares the strength via the US proof convention.
PROD_RUM_151 = {
    "display_name": "Clarke's Court Pure White Rum (151-proof)",
    "food_category": "beverage",
    "source": "research",
    "calories_per_100g": 345.0,
    "protein_per_100g": 0.0,
    "carbs_per_100g": 0.0,
    "fat_per_100g": 0.0,
    "fiber_per_100g": 0.0,
}

# The actual incident shape: a calories-only import gap. NOT alcohol.
PROD_CAKE_PARTIAL_ROW = {
    "display_name": "Chocolate Layer Cake With Strawberry Coulis",
    "food_category": "dessert",
    "source": "research",
    "calories_per_100g": 385.0,
    "protein_per_100g": 0.0,
    "carbs_per_100g": 0.0,
    "fat_per_100g": 0.0,
    "fiber_per_100g": 0.0,
}

# Explicitly non-alcoholic beverage — must NOT get the ethanol exemption.
PROD_NON_ALCOHOLIC_ROW = {
    "display_name": "Non-Alcoholic Sparkling Cider",
    "food_category": "non_alcoholic_beverage",
    "calories_per_100g": 50.0,
    "protein_per_100g": 0.0,
    "carbs_per_100g": 0.0,
    "fat_per_100g": 0.0,
}


# ---------------------------------------------------------------------------
# 1. Alcohol detection is data-driven and correctly bounded
# ---------------------------------------------------------------------------

class TestAlcoholExemption:
    def test_usda_vodka_row_is_not_flagged_unusable(self):
        """The reviewer's reproduced false positive. 231 kcal/100g with 0/0/0
        is the CORRECT macro profile for a spirit — ethanol carries it."""
        assert db_row_macros_unusable(PROD_VODKA_80_PROOF) is False

    def test_vodka_evidence_comes_from_the_taxonomy_column(self):
        evidence = alcohol_accounts_for_calories(PROD_VODKA_80_PROOF, 231.0, 100.0)
        assert evidence is not None
        assert "food_category" in evidence

    def test_proof_declared_in_text_is_enough_without_an_alcohol_category(self):
        """food_category='beverage' carries no alcohol token; the declared
        151-proof (= 75.5% ABV) does the work."""
        assert db_row_macros_unusable(PROD_RUM_151) is False
        evidence = alcohol_accounts_for_calories(PROD_RUM_151, 345.0, 100.0)
        assert "ABV" in evidence

    def test_detection_is_not_a_liquor_name_list(self):
        """A row NAMED like a spirit but carrying no alcohol data anywhere is
        still flagged — the rule reads data, not names."""
        nameless_evidence_row = {
            "display_name": "Vodka Cream Sauce",
            "food_category": "sauce",
            "calories_per_100g": 112.0,
            "protein_per_100g": 0.0,
            "carbs_per_100g": 0.0,
            "fat_per_100g": 0.0,
        }
        assert db_row_macros_unusable(nameless_evidence_row) is True

    def test_non_alcoholic_label_is_not_treated_as_alcoholic(self):
        assert db_row_macros_unusable(PROD_NON_ALCOHOLIC_ROW) is True

    def test_low_abv_cannot_explain_high_energy(self):
        """A 4%-ABV beer has ~3.2 g ethanol / 100 mL ≈ 22 kcal. A 0/0/0 beer
        row at 43 kcal/100g is a data gap, not an ethanol row."""
        beer = {
            "display_name": "Lager Beer 4% ABV",
            "food_category": "beer",
            "calories_per_100g": 43.0,
            "protein_per_100g": 0.0,
            "carbs_per_100g": 0.0,
            "fat_per_100g": 0.0,
        }
        assert alcohol_accounts_for_calories(beer, 43.0, 100.0) is None
        assert db_row_macros_unusable(beer) is True

    def test_item_level_alcohol_g_declares_the_exemption(self):
        """A 44 ml shot of 40% ABV ≈ 14 g ethanol ≈ 97 kcal."""
        shot = {
            "name": "vodka shot",
            "calories": 97,
            "protein_g": 0,
            "carbs_g": 0,
            "fat_g": 0,
            "weight_g": 44,
            "alcohol_g": 14.0,
        }
        assert ai_item_macros_unknown(shot) is False

    def test_item_inherits_the_alcohol_taxonomy_from_its_matched_db_row(self):
        """A flattened item loses food_category; the attached usda_data row
        still carries it."""
        item = {
            "name": "vodka",
            "calories": 102,
            "protein_g": 0.0,
            "carbs_g": 0.0,
            "fat_g": 0.0,
            "weight_g": 44,
            "usda_data": PROD_VODKA_80_PROOF,
        }
        assert ai_item_macros_unknown(item) is False


# ---------------------------------------------------------------------------
# 2. The gate itself: zeros erased, totals honest
# ---------------------------------------------------------------------------

class TestEnforceMacroIntegrity:
    def test_unknown_item_macros_become_null_and_totals_become_null(self):
        payload = {
            "food_items": [{
                "name": "Chocolate Layer Cake With Strawberry Coulis",
                "amount": "1 slice",
                "calories": 385,
                "weight_g": 110,
            }],
            "total_calories": 385,
            "protein_g": 0.0,
            "carbs_g": 0.0,
            "fat_g": 0.0,
            "fiber_g": 0.0,
        }
        enforce_macro_integrity(payload, "test")

        item = payload["food_items"][0]
        assert item["macros_unknown"] is True
        assert item["requires_user_confirmation"] is True
        # The zeros are GONE — not merely flagged.
        assert item["protein_g"] is None
        assert item["carbs_g"] is None
        assert item["fat_g"] is None
        # And the meal totals say "unknown", not 0.0.
        assert payload["protein_g"] is None
        assert payload["carbs_g"] is None
        assert payload["fat_g"] is None
        # Calories ARE known and must survive untouched.
        assert payload["total_calories"] == 385
        assert payload["macros_unknown"] is True
        assert payload["macros_unknown_items"] == [
            "Chocolate Layer Cake With Strawberry Coulis"
        ]

    def test_zero_default_resum_can_no_longer_fabricate_a_zero(self):
        """The exact arithmetic the reviewer reproduced:
        `sum(item.get('protein_g', 0) or 0 ...)`. After the gate it can no
        longer produce a confident 0.0 total, because the total is None."""
        payload = {
            "food_items": [{"name": "mystery pastry", "calories": 300, "weight_g": 90}],
            "protein_g": 0.0,
        }
        enforce_macro_integrity(payload, "test")
        assert payload["protein_g"] is None
        # A downstream naive re-sum would still yield 0 — which is exactly why
        # the ITEM macros are None and the item is flagged: the flag and the
        # null total are what the persistence layers read.
        assert payload["food_items"][0]["macros_unknown"] is True

    def test_partial_meal_reports_a_labelled_known_subtotal(self):
        payload = {
            "food_items": [
                {"name": "grilled chicken", "calories": 250, "protein_g": 46.0,
                 "carbs_g": 0.0, "fat_g": 5.4, "fiber_g": 0.0, "weight_g": 170},
                {"name": "mystery sauce", "calories": 90, "weight_g": 40},
            ],
            "protein_g": 46.0,
            "carbs_g": 0.0,
            "fat_g": 5.4,
            "fiber_g": 0.0,
        }
        enforce_macro_integrity(payload, "test")
        assert payload["protein_g"] is None
        assert payload["macros_known_subtotal"]["protein_g"] == 46.0
        assert payload["macros_known_subtotal"]["fat_g"] == 5.4
        # The known item is untouched.
        assert payload["food_items"][0]["protein_g"] == 46.0

    def test_spirit_item_is_left_alone(self):
        payload = {
            "food_items": [{
                "name": "vodka, 1.5 oz",
                "calories": 97,
                "protein_g": 0.0,
                "carbs_g": 0.0,
                "fat_g": 0.0,
                "weight_g": 44,
                "alcohol_g": 14.0,
            }],
            "protein_g": 0.0,
            "carbs_g": 0.0,
            "fat_g": 0.0,
        }
        enforce_macro_integrity(payload, "test")
        item = payload["food_items"][0]
        assert item.get("macros_unknown") is not True
        assert item["protein_g"] == 0.0
        assert item["carbs_g"] == 0.0
        assert item["fat_g"] == 0.0
        assert payload["protein_g"] == 0.0
        assert "macros_unknown" not in payload

    def test_zero_calorie_item_is_left_alone(self):
        payload = {
            "food_items": [{"name": "black coffee", "calories": 0,
                            "protein_g": 0.0, "carbs_g": 0.0, "fat_g": 0.0}],
            "protein_g": 0.0,
        }
        enforce_macro_integrity(payload, "test")
        assert payload["food_items"][0].get("macros_unknown") is not True
        assert payload["protein_g"] == 0.0

    def test_gate_is_idempotent(self):
        payload = {
            "food_items": [{"name": "mystery pastry", "calories": 300}],
            "protein_g": 0.0,
        }
        enforce_macro_integrity(payload, "test")
        first = dict(payload)
        enforce_macro_integrity(payload, "test")
        assert payload["macros_unknown_items"] == first["macros_unknown_items"]
        assert payload["protein_g"] is None


# ---------------------------------------------------------------------------
# 3. The text producer chokepoint — cache-stack hits that NEVER call
#    _enhance_food_items_with_nutrition_db (the reviewer's finding 2)
# ---------------------------------------------------------------------------

def _make_cache_service():
    from services.food_analysis.cache_service_helpers import FoodAnalysisCacheService
    return FoodAnalysisCacheService(
        nutrition_db=MagicMock(), gemini_service=MagicMock()
    )


@pytest.mark.asyncio
class TestAnalyzeFoodChokepoint:
    async def test_override_cache_hit_with_calories_only_cannot_report_zero(self):
        """cache_source='override' — the exact branch food_logging_stream.py
        keys its `verified` badge off, and the one that never runs the USDA
        enhancer."""
        svc = _make_cache_service()
        override_analysis = {
            "food_items": [{
                "name": "Chocolate Layer Cake With Strawberry Coulis",
                "amount": "1 slice",
                "calories": 385,
                "protein_g": 0.0,
                "carbs_g": 0.0,
                "fat_g": 0.0,
                "fiber_g": 0.0,
                "weight_g": 110,
            }],
            "total_calories": 385,
            "protein_g": 0.0,
            "carbs_g": 0.0,
            "fat_g": 0.0,
            "fiber_g": 0.0,
        }
        with patch.object(svc, "_try_saved_food", AsyncMock(return_value=None)), \
             patch.object(svc, "_try_recent_log", AsyncMock(return_value=None)), \
             patch.object(svc, "_try_user_contributed", AsyncMock(return_value=None)), \
             patch.object(svc, "_try_override", AsyncMock(return_value=override_analysis)):
            result = await svc.analyze_food(
                description="chocolate layer cake with strawberry coulis",
                user_id="u1",
                fast_macros_only=True,
            )

        assert result["cache_source"] == "override"
        assert result["total_calories"] == 385
        assert result["protein_g"] is None, "meal protein must be UNKNOWN, not 0.0"
        assert result["carbs_g"] is None
        assert result["fat_g"] is None
        item = result["food_items"][0]
        assert item["macros_unknown"] is True
        assert item["protein_g"] is None
        assert item["requires_user_confirmation"] is True

    async def test_override_cache_hit_for_a_spirit_keeps_its_real_zeros(self):
        svc = _make_cache_service()
        spirit_analysis = {
            "food_items": [{
                "name": "Vodka (80 Proof)",
                "amount": "1.5 oz",
                "calories": 102,
                "protein_g": 0.0,
                "carbs_g": 0.0,
                "fat_g": 0.0,
                "fiber_g": 0.0,
                "weight_g": 44,
                "food_category": "alcohol",
            }],
            "total_calories": 102,
            "protein_g": 0.0,
            "carbs_g": 0.0,
            "fat_g": 0.0,
            "fiber_g": 0.0,
        }
        with patch.object(svc, "_try_saved_food", AsyncMock(return_value=None)), \
             patch.object(svc, "_try_recent_log", AsyncMock(return_value=None)), \
             patch.object(svc, "_try_user_contributed", AsyncMock(return_value=None)), \
             patch.object(svc, "_try_override", AsyncMock(return_value=spirit_analysis)):
            result = await svc.analyze_food(description="vodka shot", user_id="u1")

        assert result["total_calories"] == 102
        assert result["protein_g"] == 0.0
        assert result["carbs_g"] == 0.0
        assert result["fat_g"] == 0.0
        assert result["food_items"][0].get("macros_unknown") is not True
        assert result.get("macros_unknown") is not True


# ---------------------------------------------------------------------------
# 4. THE PERSISTENCE PATH — POST /nutrition/log-image-stream writes to
#    food_logs with no confirm step. Assert on the real create_food_log call.
# ---------------------------------------------------------------------------

class _FakeDB:
    """Captures create_food_log kwargs; everything else is a no-op MagicMock."""

    def __init__(self):
        self.created = []
        self.client = MagicMock()

    def create_food_log(self, **kwargs):
        self.created.append(kwargs)
        return {"id": "fake-log-id"}

    def __getattr__(self, name):
        return MagicMock()


@pytest.fixture
def image_stream_env():
    """Drive /log-image-stream with every external dependency stubbed except
    the macro-integrity gate under test."""
    from main import app
    from core.auth import get_current_user
    import api.v1.nutrition.food_logging_stream as stream_mod
    import services.food_override_service as override_mod
    import api.v1.nutrition.summaries as summaries_mod
    import api.v1.home.bootstrap_cache as bootstrap_mod

    fake_db = _FakeDB()
    app.dependency_overrides[get_current_user] = lambda: {
        "id": "user-1", "auth_id": "auth-1", "email": "t@example.com",
    }

    patches = [
        patch.object(stream_mod, "get_supabase_db", lambda: fake_db),
        patch.object(stream_mod, "fetch_food_logging_rules", lambda *a, **k: []),
        patch.object(stream_mod, "build_rules_prompt_block", lambda *a, **k: ""),
        patch.object(stream_mod, "resolve_timezone", lambda *a, **k: "UTC"),
        patch.object(
            stream_mod, "upload_food_image_to_s3",
            AsyncMock(return_value=(None, None)),
        ),
        patch.object(
            stream_mod, "get_food_analysis_cache_service",
            lambda: MagicMock(enrich_with_tips=AsyncMock(return_value={})),
        ),
        patch.object(
            override_mod, "apply_user_food_overrides",
            lambda db, uid, items: (
                items,
                {"total_calories": 0, "protein_g": 0.0, "carbs_g": 0.0, "fat_g": 0.0},
                0,
            ),
        ),
        patch.object(
            override_mod, "apply_global_verified_crosscheck",
            lambda items: (
                items,
                {"total_calories": 0, "protein_g": 0.0, "carbs_g": 0.0, "fat_g": 0.0},
                0,
            ),
        ),
        patch.object(
            summaries_mod, "invalidate_daily_summary_cache", AsyncMock(return_value=None)
        ),
        patch.object(
            bootstrap_mod, "invalidate_bootstrap_cache", AsyncMock(return_value=None)
        ),
        patch.object(
            stream_mod, "get_user_calorie_bias", AsyncMock(return_value=0)
        ),
    ]
    for p in patches:
        p.start()
    try:
        yield app, fake_db
    finally:
        for p in patches:
            p.stop()
        app.dependency_overrides.pop(get_current_user, None)


def _post_image_stream(app, analysis):
    """POST a 1-byte JPEG and return the parsed `done` payload."""
    from fastapi.testclient import TestClient
    from services.gemini_service import GeminiService
    import json as _json

    with patch.object(
        GeminiService, "analyze_food_image", AsyncMock(return_value=analysis)
    ):
        with TestClient(app) as client:
            resp = client.post(
                "/api/v1/nutrition/log-image-stream",
                data={"user_id": "user-1", "meal_type": "dinner"},
                files={"image": ("m.jpg", b"\xff\xd8\xff", "image/jpeg")},
            )
    assert resp.status_code == 200, resp.text
    body = resp.text
    assert "event: error" not in body, body
    done = body.split("event: done\ndata: ", 1)[1].split("\n\n", 1)[0]
    return _json.loads(done)


def test_photo_log_of_a_calories_only_dish_persists_null_not_zero(image_stream_env):
    """THE incident, on THE persisting path: a plated chocolate layer cake with
    strawberry coulis that the analyzer could only price in calories. The row
    written to food_logs must carry NULL macros, never 0/0/0."""
    app, fake_db = image_stream_env
    analysis = {
        "food_items": [{
            "name": "Chocolate Layer Cake With Strawberry Coulis",
            "amount": "1 slice",
            "calories": 385,
            "protein_g": 0.0,
            "carbs_g": 0.0,
            "fat_g": 0.0,
            "fiber_g": 0.0,
            "weight_g": 110,
        }],
        "total_calories": 385,
        "protein_g": 0.0,
        "carbs_g": 0.0,
        "fat_g": 0.0,
        "fiber_g": 0.0,
        "feedback": "",
    }
    done = _post_image_stream(app, analysis)

    assert len(fake_db.created) == 1, "the log must still be written"
    row = fake_db.created[0]
    assert row["total_calories"] == 385, "calories ARE known"
    assert row["protein_g"] is None, f"persisted protein was {row['protein_g']!r}"
    assert row["carbs_g"] is None
    assert row["fat_g"] is None
    assert row["fiber_g"] is None
    persisted_item = row["food_items"][0]
    assert persisted_item["macros_unknown"] is True
    assert persisted_item["protein_g"] is None

    # …and the SSE payload the app renders says unknown too.
    assert done["protein_g"] is None
    assert done["macros_unknown"] is True
    assert done["macros_unknown_items"] == [
        "Chocolate Layer Cake With Strawberry Coulis"
    ]


def test_photo_log_of_a_spirit_persists_real_zero_macros(image_stream_env):
    """A distilled spirit legitimately IS 0P/0C/0F with real calories. The
    guard must not corrupt it into NULL."""
    app, fake_db = image_stream_env
    analysis = {
        "food_items": [{
            "name": "Vodka (80 Proof), 1.5 oz",
            "amount": "1.5 oz",
            "calories": 97,
            "protein_g": 0.0,
            "carbs_g": 0.0,
            "fat_g": 0.0,
            "fiber_g": 0.0,
            "weight_g": 44,
            "alcohol_g": 14.0,
        }],
        "total_calories": 97,
        "protein_g": 0.0,
        "carbs_g": 0.0,
        "fat_g": 0.0,
        "fiber_g": 0.0,
        "alcohol_g": 14.0,
        "feedback": "",
    }
    done = _post_image_stream(app, analysis)

    assert len(fake_db.created) == 1
    row = fake_db.created[0]
    assert row["total_calories"] == 97
    assert row["protein_g"] == 0.0, "a spirit's zeros are REAL data"
    assert row["carbs_g"] == 0.0
    assert row["fat_g"] == 0.0
    assert row["food_items"][0].get("macros_unknown") is not True
    assert done["protein_g"] == 0.0
    assert done["macros_unknown"] is False


def test_photo_log_of_a_normal_meal_is_unaffected(image_stream_env):
    """Control: a meal with real macros must round-trip byte-for-byte."""
    app, fake_db = image_stream_env
    analysis = {
        "food_items": [{
            "name": "Grilled chicken breast",
            "amount": "6 oz",
            "calories": 280,
            "protein_g": 52.0,
            "carbs_g": 0.0,
            "fat_g": 6.1,
            "fiber_g": 0.0,
            "weight_g": 170,
        }],
        "total_calories": 280,
        "protein_g": 52.0,
        "carbs_g": 0.0,
        "fat_g": 6.1,
        "fiber_g": 0.0,
        "feedback": "",
    }
    _post_image_stream(app, analysis)
    row = fake_db.created[0]
    assert row["protein_g"] == 52.0
    assert row["carbs_g"] == 0.0
    assert row["fat_g"] == 6.1
    assert row["food_items"][0].get("macros_unknown") is not True
