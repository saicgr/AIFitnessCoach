"""Wire-level contract tests for the adherence + health-consent fixes.

These tests deliberately go through the **real FastAPI `app` object** (via
`TestClient`), not a bare `APIRouter` and not by awaiting the endpoint
coroutine directly. That distinction is the whole point of this file: the
previous round of these tests exercised the router in isolation and therefore
"passed" while asserting behaviour the shipped app did not have — `main.py`
registers a custom `@app.exception_handler(HTTPException)` that rebuilt every
error response and silently DROPPED `exc.headers`, so the machine-readable
`X-Zealova-Error-Code` never reached a client.

Covered:
  1. `X-Zealova-Error-Code` survives the app-level HTTPException handler.
  2. The two /activity 403s are distinguishable on the wire, and an
     UNVERIFIABLE consent flag is a retryable 503, not a latching 403.
  3. /nutrition/adherence/{id}/summary answers "nothing to score" with a JSON
     `null` body at 200 + a reason header — the only shape Dio 5.9.2's default
     FusedTransformer turns into `response.data == null` on the client.
  4. A week with no logs is UNKNOWN, never a manufactured 0% that drags the
     average and the sustainability rating down.

Run: backend/.venv312/bin/python -m pytest tests/test_adherence_and_consent_contracts.py -v
"""
from datetime import date, datetime, timedelta, timezone
from types import SimpleNamespace
from unittest.mock import MagicMock, patch

import pytest
from fastapi.testclient import TestClient

from core.auth import get_current_user
from main import app
from services.adherence_tracking_service import (
    AdherenceTrackingService,
    DailyAdherence,
    NutritionActuals,
    NutritionTargets,
    SustainabilityRating,
)

TEST_USER_ID = "contract-test-user"

ACTIVITY_SYNC_PATH = "/api/v1/activity/sync"
ADHERENCE_PATH = f"/api/v1/nutrition/adherence/{TEST_USER_ID}/summary"


# ── fixtures ────────────────────────────────────────────────────────────────


@pytest.fixture(autouse=True)
def override_auth():
    """Authenticate every request in this module as TEST_USER_ID."""
    app.dependency_overrides[get_current_user] = lambda: {
        "id": TEST_USER_ID,
        "email": "contract-test@example.com",
    }
    yield
    app.dependency_overrides.pop(get_current_user, None)


@pytest.fixture
def client():
    return TestClient(app)


class _Chain:
    """Minimal chainable stand-in for a PostgREST query builder.

    Every builder method returns `self`; `execute()` returns whatever was
    canned for the table. A canned value of `_NO_ROW` reproduces
    `.maybe_single()`'s real behaviour of returning **None** (the response
    object itself) when zero rows match.
    """

    def __init__(self, table: str, canned: dict):
        self._table = table
        self._canned = canned

    def __getattr__(self, _name):
        return lambda *a, **k: self

    def execute(self):
        value = self._canned.get(self._table, [])
        if value is _NO_ROW:
            return None
        return SimpleNamespace(data=value)


_NO_ROW = object()


def _fake_db(canned: dict):
    db = MagicMock()
    db.client.table.side_effect = lambda name: _Chain(name, canned)
    return db


def _activity_payload(user_id: str) -> dict:
    return {
        "user_id": user_id,
        "activity_date": date.today().isoformat(),
        "steps": 4200,
        "calories_burned": 500.0,
        "active_calories": 220.0,
        "active_minutes": 35,
    }


# ── 1 + 2. error-code header reaches the wire ───────────────────────────────


def test_ownership_403_carries_error_code_header_through_the_real_app(client):
    """A body claiming another user's id → 403 tagged `user_id_mismatch`.

    Regression gate for the dropped-headers blocker: this asserts on
    `response.headers`, i.e. what actually crossed the ASGI boundary after
    main.py's custom HTTPException handler rebuilt the response.
    """
    response = client.post(
        ACTIVITY_SYNC_PATH, json=_activity_payload("someone-elses-user-id")
    )

    assert response.status_code == 403
    assert response.headers.get("X-Zealova-Error-Code") == "user_id_mismatch"
    # The human-readable body is unchanged — the header is additive.
    assert response.json()["detail"] == "Access denied"


def test_consent_403_and_ownership_403_are_distinguishable_on_the_wire(client):
    """Same status code, different machine-readable reason.

    The Flutter ActivityService latches a *persistent* "health consent denied"
    gate on any 403, so an ownership 403 used to silently disable health sync.
    The client can only stop doing that if the two are told apart on the wire.
    """
    consent_row = _fake_db({"user_ai_settings": [{"health_data_consent": False}]})
    with patch("api.v1.activity.has_health_data_consent", return_value=False), patch(
        "core.supabase_client.get_supabase", return_value=consent_row
    ):
        response = client.post(
            ACTIVITY_SYNC_PATH, json=_activity_payload(TEST_USER_ID)
        )

    assert response.status_code == 403
    assert response.headers.get("X-Zealova-Error-Code") == "health_data_consent_required"


def test_unreadable_consent_flag_is_a_retryable_503_not_a_latching_403(client):
    """Supabase down ⇒ consent is UNKNOWN, not "the user refused".

    `consent_guard.load_consent_flags` fails CLOSED and reports
    `health_data_consent=False` for a DB exception, which is correct for the
    write gate but must NOT be reported to the client as a refusal — a 403
    latches health sync off for a consenting user until they toggle the
    setting by hand. Still writes nothing; just says "try again".
    """

    def _boom():
        raise RuntimeError("supabase unreachable")

    with patch("api.v1.activity.has_health_data_consent", return_value=False), patch(
        "core.supabase_client.get_supabase", side_effect=_boom
    ):
        response = client.post(
            ACTIVITY_SYNC_PATH, json=_activity_payload(TEST_USER_ID)
        )

    assert response.status_code == 503
    assert (
        response.headers.get("X-Zealova-Error-Code")
        == "health_data_consent_unverifiable"
    )


def test_a_401_still_carries_www_authenticate(client):
    """The header fix must not be adherence-specific.

    Any route raising `HTTPException(headers=...)` — including FastAPI's own
    401 + `WWW-Authenticate` convention — now survives the custom handler.
    Exercised through the real app so the assertion covers the handler, not
    the raise site.
    """
    from fastapi import HTTPException

    @app.get("/__contract_test__/needs-auth")
    async def _needs_auth():  # pragma: no cover - invoked via TestClient
        raise HTTPException(
            status_code=401,
            detail="nope",
            headers={"WWW-Authenticate": 'Bearer realm="zealova"'},
        )

    try:
        response = client.get("/__contract_test__/needs-auth")
        assert response.status_code == 401
        assert response.headers.get("WWW-Authenticate") == 'Bearer realm="zealova"'
        assert response.json() == {"detail": "nope"}
    finally:
        app.router.routes = [
            r
            for r in app.router.routes
            if getattr(r, "path", None) != "/__contract_test__/needs-auth"
        ]


# ── 3. the "nothing to score" contract the CURRENT client handles ───────────


def _assert_client_reads_this_as_null(response, expected_reason: str):
    """Assert the exact shape `NutritionRepository.getAdherenceSummary` needs.

    That method branches on `response.data == null`. Dio 5.9.2's default
    `FusedTransformer` only produces `null` when the response advertises a JSON
    content-type (fused_transformer.dart:60-63); without one it falls through to
    `utf8.decode(bytes)` and yields the empty STRING. So the two things that
    matter are: a JSON content-type, and a body that `jsonDecode`s to null.
    """
    assert response.status_code == 200
    assert response.headers["content-type"].startswith("application/json")
    assert response.content == b"null"
    assert response.json() is None
    assert response.headers.get("X-Nutrition-Adherence-Unavailable") == expected_reason


def test_no_configured_targets_returns_json_null_not_204(client):
    db = _fake_db({"nutrition_preferences": _NO_ROW, "users": []})
    with patch("api.v1.nutrition.tdee_adherence.get_supabase_db", return_value=db):
        response = client.get(
            ADHERENCE_PATH, headers={"X-User-Timezone": "UTC"}, params={"weeks": 4}
        )

    _assert_client_reads_this_as_null(response, "targets-not-configured")


def test_targets_set_but_no_logs_in_window_returns_json_null(client):
    """The finding-4 behaviour change, made explicit and non-silent.

    A user whose most recent logs predate the window gets "nothing to score"
    rather than a mis-windowed grade. The reason header distinguishes it from
    the no-targets case, and from an error (which is a 5xx).
    """
    db = _fake_db(
        {
            "nutrition_preferences": {
                "target_calories": 2000,
                "target_protein_g": 150,
                "target_carbs_g": 200,
                "target_fat_g": 65,
                "nutrition_goal": "maintain",
            },
            "food_logs": [],
        }
    )
    with patch("api.v1.nutrition.tdee_adherence.get_supabase_db", return_value=db):
        response = client.get(
            ADHERENCE_PATH, headers={"X-User-Timezone": "UTC"}, params={"weeks": 4}
        )

    _assert_client_reads_this_as_null(response, "no-logs-in-window")


def test_one_logged_week_is_not_diluted_by_the_empty_weeks_around_it(client):
    """The finding-3 regression gate, end to end.

    Three perfectly on-target days in ONE week of a four-week window. The other
    weeks have no logs — they are UNKNOWN. Before the fix they were summarised
    as 0% and averaged in, so this user was graded ~20% adherent / "low"
    sustainability. The honest answer is 100% over the one week we can measure.
    """
    today = datetime.now(timezone.utc).date()
    # Monday of the PREVIOUS week — guaranteed entirely in the past and
    # entirely inside a 4-week window, so the bucketing is deterministic
    # regardless of which weekday the suite runs on.
    week_monday = today - timedelta(days=today.weekday()) - timedelta(days=7)
    logged_days = [week_monday, week_monday + timedelta(days=1), week_monday + timedelta(days=2)]

    db = _fake_db(
        {
            "nutrition_preferences": {
                "target_calories": 2000,
                "target_protein_g": 150,
                "target_carbs_g": 200,
                "target_fat_g": 65,
                "nutrition_goal": "maintain",
            },
            "food_logs": [
                {
                    "logged_at": f"{d.isoformat()}T12:00:00+00:00",
                    "total_calories": 2000,
                    "protein_g": 150,
                    "carbs_g": 200,
                    "fat_g": 65,
                }
                for d in logged_days
            ],
        }
    )
    with patch("api.v1.nutrition.tdee_adherence.get_supabase_db", return_value=db):
        response = client.get(
            ADHERENCE_PATH, headers={"X-User-Timezone": "UTC"}, params={"weeks": 4}
        )

    assert response.status_code == 200
    body = response.json()
    assert body is not None
    # Only the week that actually holds measurements is reported.
    assert body["weeks_analyzed"] == 1
    assert len(body["weekly_adherence"]) == 1
    week = body["weekly_adherence"][0]
    assert week["days_logged"] == 3
    assert week["has_data"] is True
    assert week["avg_overall_adherence"] == pytest.approx(100.0)
    # Not 20% — the three unlogged weeks contribute NOTHING to the average.
    assert body["average_adherence"] == pytest.approx(100.0)
    assert body["sustainability_rating"] == "high"


# ── 4. service-level: a week with no logs is unknown, not zero ──────────────


@pytest.fixture
def service():
    return AdherenceTrackingService()


def _on_target_day(service: AdherenceTrackingService, day: date) -> DailyAdherence:
    targets = NutritionTargets(calories=2000, protein_g=150, carbs_g=200, fat_g=65)
    actuals = NutritionActuals(
        date=day, calories=2000, protein_g=150, carbs_g=200, fat_g=65, meals_logged=3
    )
    return service.calculate_daily_adherence(targets, actuals)


def test_empty_week_reports_unknown_not_zero(service):
    summary = service.calculate_weekly_summary([], date(2026, 7, 6))

    assert summary.days_logged == 0
    assert summary.has_data is False
    # The distinction that matters: null, not 0.0.
    assert summary.avg_overall_adherence is None
    assert summary.avg_calorie_adherence is None
    assert summary.adherence_variance is None
    payload = summary.to_dict()
    assert payload["avg_overall_adherence"] is None
    assert payload["has_data"] is False
    assert payload["days_logged"] == 0


def test_sustainability_is_none_when_no_week_has_data(service):
    weeks = [
        service.calculate_weekly_summary([], date(2026, 6, 29)),
        service.calculate_weekly_summary([], date(2026, 7, 6)),
    ]
    # Previously: score=0.0-ish / rating=LOW, i.e. "you failed" for a user who
    # simply logged nothing.
    assert service.calculate_sustainability_score(weeks) is None


def test_sustainability_is_none_for_an_empty_week_list(service):
    """Previously returned a fabricated score=0.5 / rating=MEDIUM.

    That 0.5 was read downstream as "50% adherent" and steered which calorie
    deficit we recommended.
    """
    assert service.calculate_sustainability_score([]) is None


def test_empty_weeks_do_not_drag_the_average_or_the_rating(service):
    logged_week = service.calculate_weekly_summary(
        [
            _on_target_day(service, date(2026, 7, 6)),
            _on_target_day(service, date(2026, 7, 7)),
            _on_target_day(service, date(2026, 7, 8)),
        ],
        date(2026, 7, 6),
    )
    weeks = [
        service.calculate_weekly_summary([], date(2026, 6, 15)),
        service.calculate_weekly_summary([], date(2026, 6, 22)),
        service.calculate_weekly_summary([], date(2026, 6, 29)),
        logged_week,
    ]

    score = service.calculate_sustainability_score(weeks)

    assert score is not None
    assert score.avg_adherence == pytest.approx(100.0)  # not 25.0
    assert score.weeks_with_data == 1
    assert score.weeks_in_window == 4
    assert score.rating == SustainabilityRating.HIGH
    # Coverage is still reported honestly: 3 logged days out of 28.
    assert score.logging_score == pytest.approx(3 / 28)


def test_single_logged_day_has_unknown_variance_not_perfect_consistency(service):
    week = service.calculate_weekly_summary(
        [_on_target_day(service, date(2026, 7, 6))], date(2026, 7, 6)
    )

    assert week.has_data is True
    assert week.avg_overall_adherence == pytest.approx(100.0)
    # One point has no measurable spread — that is unknown, not zero variance.
    assert week.adherence_variance is None


def test_partial_week_coverage_denominator_is_honest(service):
    """A 3-day partial week at the edge of the window isn't 4 missed days."""
    week = service.calculate_weekly_summary(
        [
            _on_target_day(service, date(2026, 7, 6)),
            _on_target_day(service, date(2026, 7, 7)),
        ],
        date(2026, 7, 6),
        days_in_week=3,
    )

    assert week.days_in_week == 3
    assert week.to_dict()["logging_rate_pct"] == pytest.approx(66.7)
