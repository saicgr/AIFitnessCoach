"""
Tests for Nutrition API endpoints.

Tests:
- Food logs listing, retrieval, deletion
- Daily and weekly summaries
- Nutrition targets CRUD

Run with: pytest backend/tests/test_nutrition_api.py -v
"""
import asyncio

import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from types import SimpleNamespace
from datetime import datetime


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def mock_supabase_db():
    """Mock SupabaseDB for nutrition operations.

    `api/v1/nutrition.py` was split into the `api.v1.nutrition` PACKAGE, so
    `get_supabase_db` no longer lives on the package namespace — each submodule
    imports it directly. Patching the old `api.v1.nutrition.get_supabase_db`
    target therefore raised `AttributeError: module 'api.v1.nutrition' does not
    have the attribute 'get_supabase_db'`. Patch the real call sites instead.
    """
    with patch("api.v1.nutrition.food_logs.get_supabase_db") as mock_food_logs_db, \
         patch("api.v1.nutrition.summaries.get_supabase_db") as mock_summaries_db:
        mock_db = MagicMock()
        mock_food_logs_db.return_value = mock_db
        mock_summaries_db.return_value = mock_db
        yield mock_db


@pytest.fixture(autouse=True)
def isolate_nutrition_side_effects():
    """Keep these unit tests hermetic and order-independent.

    - The 60s `_daily_summary_cache` is process-global. Without clearing it,
      an earlier test's cached summary would be served to a later test that
      uses the same (user, date) key — silently masking real behavior.
    - `_fetch_active_calories_and_pref` (the F4 burn overlay) opens its OWN
      Supabase connection, so it would make a live network call.
    - `log_user_activity` writes an audit row to Supabase.
    """
    from api.v1.nutrition.summaries import _daily_summary_cache

    _daily_summary_cache._local.clear()
    with patch(
        "services.langgraph_agents.tools.nutrition_context_helpers._fetch_active_calories_and_pref",
        new=AsyncMock(return_value=(0, False)),
    ), patch("api.v1.nutrition.food_logs.log_user_activity", new=AsyncMock(return_value=None)):
        yield
    _daily_summary_cache._local.clear()


@pytest.fixture
def sample_user_id():
    return "user-123-abc"


@pytest.fixture
def current_user(sample_user_id):
    """What `Depends(get_current_user)` resolves to at request time.

    These tests call the endpoint coroutines directly, so FastAPI never
    resolves the dependency — it must be passed explicitly or the parameter
    stays a `Depends` sentinel.
    """
    return {"id": sample_user_id}


@pytest.fixture
def fake_request():
    """Minimal stand-in for `fastapi.Request`.

    `resolve_timezone` only reads `request.headers.get("x-user-timezone")`;
    pinning it to UTC keeps day-boundary maths deterministic.
    """
    return SimpleNamespace(headers={"x-user-timezone": "UTC"})


@pytest.fixture
def sample_food_log():
    return {
        "id": "log-1",
        "user_id": "user-123-abc",
        "meal_type": "lunch",
        "logged_at": "2025-01-10T12:00:00",
        "food_items": [
            {"name": "Grilled Chicken", "calories": 250, "protein_g": 30},
            {"name": "Brown Rice", "calories": 200, "carbs_g": 45},
        ],
        "total_calories": 450,
        "protein_g": 35.0,
        "carbs_g": 50.0,
        "fat_g": 10.0,
        "fiber_g": 5.0,
        "health_score": 85,
        "ai_feedback": "Great balanced meal!",
        "created_at": "2025-01-10T12:00:00",
    }


@pytest.fixture
def sample_nutrition_targets():
    return {
        "daily_calorie_target": 2000,
        "daily_protein_target_g": 150.0,
        "daily_carbs_target_g": 200.0,
        "daily_fat_target_g": 70.0,
    }


# ============================================================
# LIST FOOD LOGS TESTS
# ============================================================

class TestListFoodLogs:
    """Test food logs listing endpoint."""

    def test_list_food_logs_success(self, mock_supabase_db, sample_user_id, current_user, fake_request, sample_food_log):
        """Test successful food logs listing."""
        from api.v1.nutrition import list_food_logs
        import asyncio

        mock_supabase_db.list_food_logs.return_value = [sample_food_log]

        result = asyncio.get_event_loop().run_until_complete(
            list_food_logs(
                sample_user_id, fake_request, limit=50,
                from_date=None, to_date=None, meal_type=None, tz=None,
                current_user=current_user,
            )
        )

        assert len(result) == 1
        assert result[0].id == "log-1"
        assert result[0].total_calories == 450

    def test_list_food_logs_empty(self, mock_supabase_db, sample_user_id, current_user, fake_request):
        """Test listing food logs when none exist."""
        from api.v1.nutrition import list_food_logs
        import asyncio

        mock_supabase_db.list_food_logs.return_value = []

        result = asyncio.get_event_loop().run_until_complete(
            list_food_logs(
                sample_user_id, fake_request, limit=50,
                from_date=None, to_date=None, meal_type=None, tz=None,
                current_user=current_user,
            )
        )

        assert len(result) == 0

    def test_list_food_logs_with_filters(self, mock_supabase_db, sample_user_id, current_user, fake_request, sample_food_log):
        """Test food logs listing with date and meal type filters.

        This used to assert the raw `from_date`/`to_date` strings were passed
        straight through to the DB layer. They no longer are: a date-only
        (`YYYY-MM-DD`) bound is now expanded to the UTC instants that bracket
        that day IN THE USER'S TIMEZONE (`local_date_to_utc_range`) — without
        that, a non-UTC user's day boundary was off by their UTC offset and
        meals leaked into the wrong day. The guarantee this test protects is
        unchanged in spirit (filters reach the DB layer intact) and now also
        pins the timezone expansion. With tz=UTC the window is the full day.
        """
        from api.v1.nutrition import list_food_logs
        import asyncio

        mock_supabase_db.list_food_logs.return_value = [sample_food_log]

        asyncio.get_event_loop().run_until_complete(
            list_food_logs(
                sample_user_id,
                fake_request,
                limit=50,
                from_date="2025-01-01",
                to_date="2025-01-31",
                meal_type="lunch",
                tz=None,
                current_user=current_user,
            )
        )

        mock_supabase_db.list_food_logs.assert_called_with(
            user_id=sample_user_id,
            from_date="2025-01-01T00:00:00+00:00",
            to_date="2025-01-31T23:59:59+00:00",
            meal_type="lunch",
            limit=50,
        )

    def test_list_food_logs_other_user_denied(self, mock_supabase_db, current_user, fake_request):
        """A caller may not list another user's food logs."""
        from api.v1.nutrition import list_food_logs
        from fastapi import HTTPException
        import asyncio

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                list_food_logs(
                    "someone-else", fake_request, limit=50,
                    from_date=None, to_date=None, meal_type=None, tz=None,
                    current_user=current_user,
                )
            )

        assert exc_info.value.status_code == 403
        mock_supabase_db.list_food_logs.assert_not_called()

    def test_list_food_logs_error(self, mock_supabase_db, sample_user_id, current_user, fake_request):
        """Test error handling in food logs listing."""
        from api.v1.nutrition import list_food_logs
        from fastapi import HTTPException
        import asyncio

        mock_supabase_db.list_food_logs.side_effect = Exception("Database error")

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                list_food_logs(
                sample_user_id, fake_request, limit=50,
                from_date=None, to_date=None, meal_type=None, tz=None,
                current_user=current_user,
            )
            )

        assert exc_info.value.status_code == 500


# ============================================================
# GET FOOD LOG TESTS
# ============================================================

class TestGetFoodLog:
    """Test get single food log endpoint."""

    def test_get_food_log_success(self, mock_supabase_db, sample_user_id, current_user, sample_food_log):
        """Test getting a specific food log."""
        from api.v1.nutrition import get_food_log
        import asyncio

        mock_supabase_db.get_food_log.return_value = sample_food_log

        result = asyncio.get_event_loop().run_until_complete(
            get_food_log(sample_user_id, "log-1", current_user)
        )

        assert result.id == "log-1"
        assert result.meal_type == "lunch"

    def test_get_food_log_not_found(self, mock_supabase_db, sample_user_id, current_user):
        """Test getting non-existent food log."""
        from api.v1.nutrition import get_food_log
        from fastapi import HTTPException
        import asyncio

        mock_supabase_db.get_food_log.return_value = None

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                get_food_log(sample_user_id, "nonexistent", current_user)
            )

        assert exc_info.value.status_code == 404

    def test_get_food_log_access_denied(self, mock_supabase_db, sample_food_log):
        """Test accessing food log belonging to another user.

        The authenticated caller is `different-user` asking for a log that the
        row itself says belongs to `user-123-abc` — the row-level ownership
        check must reject it with 403 (never leak another user's meal).
        """
        from api.v1.nutrition import get_food_log
        from fastapi import HTTPException
        import asyncio

        mock_supabase_db.get_food_log.return_value = sample_food_log

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                get_food_log("different-user", "log-1", {"id": "different-user"})
            )

        assert exc_info.value.status_code == 403


# ============================================================
# DELETE FOOD LOG TESTS
# ============================================================

class TestDeleteFoodLog:
    """Test delete food log endpoint."""

    def test_delete_food_log_success(self, mock_supabase_db, current_user, sample_food_log):
        """Test successful food log deletion.

        The endpoint now fetches the row first and runs a row-level ownership
        check (`verify_resource_ownership`) before deleting, so the mock must
        return the owning row — not just a bare `delete_food_log() -> True`.
        """
        from api.v1.nutrition import delete_food_log
        import asyncio

        mock_supabase_db.get_food_log.return_value = sample_food_log
        mock_supabase_db.delete_food_log.return_value = True

        result = asyncio.get_event_loop().run_until_complete(
            delete_food_log("log-1", current_user)
        )

        assert result["status"] == "deleted"
        assert result["id"] == "log-1"
        mock_supabase_db.delete_food_log.assert_called_once_with("log-1")

    def test_delete_food_log_other_user_denied(self, mock_supabase_db, sample_food_log):
        """A caller may not delete a food log owned by someone else."""
        from api.v1.nutrition import delete_food_log
        from fastapi import HTTPException
        import asyncio

        mock_supabase_db.get_food_log.return_value = sample_food_log
        mock_supabase_db.delete_food_log.return_value = True

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                delete_food_log("log-1", {"id": "different-user"})
            )

        assert exc_info.value.status_code == 403
        mock_supabase_db.delete_food_log.assert_not_called()

    def test_delete_food_log_not_found(self, mock_supabase_db, current_user):
        """Test deleting non-existent food log.

        A missing row means `get_food_log` returns None AND the soft-delete
        lookup finds nothing — only then is it a true 404.
        """
        from api.v1.nutrition import delete_food_log
        from fastapi import HTTPException
        import asyncio

        mock_supabase_db.get_food_log.return_value = None
        # The soft-delete probe (`food_logs` row that exists but has deleted_at)
        # must come back empty for this to be a genuine 404.
        mock_supabase_db.client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = []
        mock_supabase_db.delete_food_log.return_value = False

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                delete_food_log("nonexistent", current_user)
            )

        assert exc_info.value.status_code == 404


# ============================================================
# DAILY SUMMARY TESTS
# ============================================================

class TestDailySummary:
    """Test daily nutrition summary endpoint."""

    def test_get_daily_summary_success(self, mock_supabase_db, sample_user_id, current_user, fake_request, sample_food_log):
        """Test getting daily nutrition summary.

        The day's meals used to be fetched with a SECOND query
        (`db.list_food_logs`); they now ride along on the summary payload
        (`db.get_daily_nutrition_summary(...)["meals"]`) so the endpoint makes
        one DB round-trip instead of two. Same guarantee: totals AND the day's
        meals are both returned.
        """
        from api.v1.nutrition import get_daily_summary
        import asyncio

        mock_supabase_db.get_daily_nutrition_summary.return_value = {
            "total_calories": 1800,
            "total_protein_g": 120.0,
            "total_carbs_g": 200.0,
            "total_fat_g": 60.0,
            "total_fiber_g": 25.0,
            "meal_count": 4,
            "avg_health_score": 80.0,
            "meals": [sample_food_log],
        }

        result = asyncio.get_event_loop().run_until_complete(
            get_daily_summary(sample_user_id, fake_request, date="2025-01-10", tz=None, current_user=current_user)
        )

        assert result.date == "2025-01-10"
        assert result.total_calories == 1800
        assert result.total_protein_g == 120.0
        assert result.meal_count == 4
        assert result.avg_health_score == 80.0
        assert len(result.meals) == 1
        assert result.meals[0].id == "log-1"
        # The day is resolved in the USER's timezone, not the server's.
        mock_supabase_db.get_daily_nutrition_summary.assert_called_once_with(
            sample_user_id, "2025-01-10", timezone_str="UTC"
        )

    def test_get_daily_summary_defaults_to_today(self, mock_supabase_db, sample_user_id, current_user, fake_request):
        """Test that daily summary defaults to today's date.

        Rewritten to actually exercise the default: `date=None` now resolves to
        today IN THE USER'S TIMEZONE (`get_user_today`), which the old test
        side-stepped by passing the date explicitly.
        """
        from api.v1.nutrition import get_daily_summary
        import asyncio
        from core.timezone_utils import get_user_today

        today_str = get_user_today("UTC")

        mock_supabase_db.get_daily_nutrition_summary.return_value = {
            "total_calories": 0,
            "total_protein_g": 0,
            "total_carbs_g": 0,
            "total_fat_g": 0,
            "total_fiber_g": 0,
            "meal_count": 0,
            "avg_health_score": None,
            "meals": [],
        }

        result = asyncio.get_event_loop().run_until_complete(
            get_daily_summary(sample_user_id, fake_request, date=None, tz=None, current_user=current_user)
        )

        assert result.date == today_str
        mock_supabase_db.get_daily_nutrition_summary.assert_called_once_with(
            sample_user_id, today_str, timezone_str="UTC"
        )

    def test_get_daily_summary_empty_day(self, mock_supabase_db, sample_user_id, current_user, fake_request):
        """Test daily summary for a day with no meals."""
        from api.v1.nutrition import get_daily_summary
        import asyncio

        mock_supabase_db.get_daily_nutrition_summary.return_value = {
            "total_calories": None,
            "total_protein_g": None,
            "total_carbs_g": None,
            "total_fat_g": None,
            "total_fiber_g": None,
            "meal_count": None,
            "avg_health_score": None,
            "meals": [],
        }

        result = asyncio.get_event_loop().run_until_complete(
            get_daily_summary(sample_user_id, fake_request, date="2025-01-01", tz=None, current_user=current_user)
        )

        assert result.total_calories == 0
        assert result.meal_count == 0
        assert len(result.meals) == 0


# ============================================================
# WEEKLY SUMMARY TESTS
# ============================================================

class TestWeeklySummary:
    """Test weekly nutrition summary endpoint."""

    def test_get_weekly_summary_success(self, mock_supabase_db, sample_user_id, current_user, fake_request):
        """Test getting weekly nutrition summary."""
        from api.v1.nutrition import get_weekly_summary
        import asyncio

        mock_supabase_db.get_weekly_nutrition_summary.return_value = [
            {"date": "2025-01-01", "total_calories": 2000, "meal_count": 3},
            {"date": "2025-01-02", "total_calories": 1800, "meal_count": 3},
            {"date": "2025-01-03", "total_calories": 2200, "meal_count": 4},
        ]

        result = asyncio.get_event_loop().run_until_complete(
            get_weekly_summary(sample_user_id, fake_request, current_user, start_date="2025-01-01")
        )

        assert result.start_date == "2025-01-01"
        assert result.end_date == "2025-01-07"
        assert result.total_calories == 6000
        assert result.total_meals == 10
        assert result.average_daily_calories == 2000.0

    def test_get_weekly_summary_with_empty_days(self, mock_supabase_db, sample_user_id, current_user, fake_request):
        """Test weekly summary with some empty days."""
        from api.v1.nutrition import get_weekly_summary
        import asyncio

        mock_supabase_db.get_weekly_nutrition_summary.return_value = [
            {"date": "2025-01-01", "total_calories": 2000, "meal_count": 3},
            {"date": "2025-01-02", "total_calories": None, "meal_count": None},
            {"date": "2025-01-03", "total_calories": 1800, "meal_count": 3},
        ]

        result = asyncio.get_event_loop().run_until_complete(
            get_weekly_summary(sample_user_id, fake_request, current_user, start_date="2025-01-01")
        )

        assert result.total_calories == 3800
        assert result.average_daily_calories == 1900.0  # Average over 2 days with data


# ============================================================
# NUTRITION TARGETS TESTS
# ============================================================

class TestNutritionTargets:
    """Test nutrition targets endpoints."""

    def test_get_nutrition_targets_success(self, mock_supabase_db, sample_user_id, current_user, sample_nutrition_targets):
        """Test getting nutrition targets."""
        from api.v1.nutrition import get_nutrition_targets
        import asyncio

        mock_supabase_db.get_user_nutrition_targets.return_value = sample_nutrition_targets

        result = asyncio.get_event_loop().run_until_complete(
            get_nutrition_targets(sample_user_id, current_user)
        )

        assert result.user_id == sample_user_id
        assert result.daily_calorie_target == 2000
        assert result.daily_protein_target_g == 150.0

    def test_get_nutrition_targets_not_set(self, mock_supabase_db, sample_user_id, current_user):
        """Test getting nutrition targets when not set."""
        from api.v1.nutrition import get_nutrition_targets
        import asyncio

        mock_supabase_db.get_user_nutrition_targets.return_value = {}

        result = asyncio.get_event_loop().run_until_complete(
            get_nutrition_targets(sample_user_id, current_user)
        )

        assert result.user_id == sample_user_id
        assert result.daily_calorie_target is None

    def test_get_nutrition_targets_other_user_is_403_not_500(self, mock_supabase_db, sample_user_id):
        """REGRESSION: an IDOR attempt must surface as 403, not 500.

        `verify_user_ownership` raises HTTPException(403), but the handler's
        blanket `except Exception` swallowed it and re-raised it through
        `safe_internal_error` as a generic 500 — so a blocked cross-user read
        looked like a server fault to the client (retry-able) and to Sentry
        (paged as an internal error). Fixed by re-raising HTTPException, the
        same pattern `get_food_log`/`delete_food_log` already use.
        """
        from api.v1.nutrition import get_nutrition_targets
        from fastapi import HTTPException
        import asyncio

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                get_nutrition_targets(sample_user_id, {"id": "attacker-user"})
            )

        assert exc_info.value.status_code == 403
        mock_supabase_db.get_user_nutrition_targets.assert_not_called()

    def test_update_nutrition_targets_success(self, mock_supabase_db, sample_user_id, current_user, sample_nutrition_targets):
        """Test updating nutrition targets."""
        from api.v1.nutrition import update_nutrition_targets
        from models.schemas import UpdateNutritionTargetsRequest
        import asyncio

        mock_supabase_db.update_user_nutrition_targets.return_value = sample_nutrition_targets

        request = MagicMock(spec=UpdateNutritionTargetsRequest)
        request.daily_calorie_target = 2000
        request.daily_protein_target_g = 150.0
        request.daily_carbs_target_g = 200.0
        request.daily_fat_target_g = 70.0

        result = asyncio.get_event_loop().run_until_complete(
            update_nutrition_targets(sample_user_id, request, current_user)
        )

        assert result.daily_calorie_target == 2000

    def test_update_nutrition_targets_other_user_is_403_not_500(self, mock_supabase_db, sample_user_id):
        """REGRESSION: writing another user's targets must 403, not 500.

        Same blanket-`except Exception` swallow as
        `test_get_nutrition_targets_other_user_is_403_not_500` — and on a WRITE
        path, where a 500 invites the client to retry an operation it can never
        be allowed to perform.
        """
        from api.v1.nutrition import update_nutrition_targets
        from models.schemas import UpdateNutritionTargetsRequest
        from fastapi import HTTPException
        import asyncio

        request = MagicMock(spec=UpdateNutritionTargetsRequest)
        request.daily_calorie_target = 2000
        request.daily_protein_target_g = 150.0
        request.daily_carbs_target_g = 200.0
        request.daily_fat_target_g = 70.0

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                update_nutrition_targets(sample_user_id, request, {"id": "attacker-user"})
            )

        assert exc_info.value.status_code == 403
        mock_supabase_db.update_user_nutrition_targets.assert_not_called()


# ============================================================
# MODEL VALIDATION TESTS
# ============================================================

class TestNutritionModels:
    """Test Pydantic model validation."""

    def test_food_log_response_model(self):
        """Test FoodLogResponse model."""
        from api.v1.nutrition import FoodLogResponse

        response = FoodLogResponse(
            id="log-1",
            user_id="user-123",
            meal_type="lunch",
            logged_at="2025-01-10T12:00:00",
            food_items=[{"name": "Chicken", "calories": 200}],
            total_calories=200,
            protein_g=30.0,
            carbs_g=0.0,
            fat_g=5.0,
            created_at="2025-01-10T12:00:00",
        )

        assert response.id == "log-1"
        assert response.fiber_g is None  # Optional field

    def test_daily_nutrition_response_model(self):
        """Test DailyNutritionResponse model."""
        from api.v1.nutrition import DailyNutritionResponse

        response = DailyNutritionResponse(
            date="2025-01-10",
            total_calories=1800,
            total_protein_g=120.0,
            total_carbs_g=200.0,
            total_fat_g=60.0,
            total_fiber_g=25.0,
            meal_count=4,
        )

        assert response.total_calories == 1800
        assert response.avg_health_score is None  # Optional field

    def test_weekly_nutrition_response_model(self):
        """Test WeeklyNutritionResponse model."""
        from api.v1.nutrition import WeeklyNutritionResponse

        response = WeeklyNutritionResponse(
            start_date="2025-01-01",
            end_date="2025-01-07",
            daily_summaries=[],
            total_calories=14000,
            average_daily_calories=2000.0,
            total_meals=21,
        )

        assert response.average_daily_calories == 2000.0


# ============================================================
# ERROR HANDLING TESTS
# ============================================================

class TestErrorHandling:
    """Test error handling across endpoints."""

    def test_list_food_logs_database_error(self, mock_supabase_db, sample_user_id, current_user, fake_request):
        """Test handling of database errors.

        This used to assert the raw driver message ("Connection failed") was
        echoed back in the 500 body. That behavior was RETIRED on purpose:
        `core.exceptions.safe_internal_error` now logs the real exception,
        reports it to Sentry, and returns a generic body so internal details
        (table names, connection strings, stack context) never leak to a
        client. The guarantee is now the stronger one — a DB failure is a 500
        AND the internal detail is redacted.
        """
        from api.v1.nutrition import list_food_logs
        from fastapi import HTTPException
        import asyncio

        mock_supabase_db.list_food_logs.side_effect = Exception("Connection failed")

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                list_food_logs(
                sample_user_id, fake_request, limit=50,
                from_date=None, to_date=None, meal_type=None, tz=None,
                current_user=current_user,
            )
            )

        assert exc_info.value.status_code == 500
        assert "Connection failed" not in str(exc_info.value.detail)
        assert exc_info.value.detail == "An internal error occurred. Please try again."

    def test_get_daily_summary_error(self, mock_supabase_db, sample_user_id, current_user, fake_request):
        """Test handling of errors in daily summary."""
        from api.v1.nutrition import get_daily_summary
        from fastapi import HTTPException
        import asyncio

        mock_supabase_db.get_daily_nutrition_summary.side_effect = Exception("Query failed")

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                get_daily_summary(sample_user_id, fake_request, date=None, tz=None, current_user=current_user)
            )

        assert exc_info.value.status_code == 500
        assert "Query failed" not in str(exc_info.value.detail)


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
