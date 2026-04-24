"""
Parse-only tests for the Strava ``fetch_since`` flow.

We deliberately avoid hitting the real Strava API:
1. It requires live OAuth tokens,
2. it counts against rate limits, and
3. Strava's response shape is documented; we just need to confirm *our* JSON-
   to-``CanonicalCardioRow`` mapping is correct.

The HTTP layer (``httpx.get``) is monkey-patched to yield a fixed JSON payload.
"""
from __future__ import annotations

from datetime import datetime, timedelta, timezone
from uuid import uuid4

import pytest
from cryptography.fernet import Fernet

from services.sync import token_encryption
from services.sync.oauth_base import SyncAccount
from services.sync.strava import StravaProvider
from services.workout_import.canonical import CanonicalCardioRow


@pytest.fixture(autouse=True)
def _env(monkeypatch):
    monkeypatch.setenv("STRAVA_CLIENT_ID", "cid")
    monkeypatch.setenv("STRAVA_CLIENT_SECRET", "csec")
    monkeypatch.setenv("STRAVA_VERIFY_TOKEN", "vt")
    monkeypatch.setenv("OAUTH_TOKEN_ENCRYPTION_KEY", Fernet.generate_key().decode())
    token_encryption.reset_cache_for_tests()


def _make_account() -> SyncAccount:
    return SyncAccount(
        id=uuid4(),
        user_id=uuid4(),
        provider="strava",
        provider_user_id="12345",
        access_token="stub-access-token",
        refresh_token="stub-refresh",
        expires_at=datetime.now(timezone.utc) + timedelta(hours=1),
        scopes=["read", "activity:read_all"],
    )


def _stub_responses(monkeypatch, pages: list[list[dict]]):
    """Yield the given pages in sequence from ``httpx.get``."""
    call_state = {"i": 0}

    class _FakeResp:
        def __init__(self, data: list[dict]):
            self.status_code = 200
            self._data = data

        def json(self):
            return self._data

    def _fake_get(url, *, params=None, headers=None, timeout=None):
        i = call_state["i"]
        call_state["i"] += 1
        if i >= len(pages):
            return _FakeResp([])
        return _FakeResp(pages[i])

    monkeypatch.setattr("services.sync.strava.httpx.get", _fake_get)


class TestStravaFetchSince:
    def test_simple_run_activity_parses(self, monkeypatch):
        account = _make_account()
        activity = {
            "id": 999888777,
            "type": "Run",
            "sport_type": "Run",
            "start_date": "2024-03-18T14:22:10Z",
            "elapsed_time": 1800,
            "moving_time": 1750,
            "distance": 5100.0,
            "total_elevation_gain": 42.0,
            "average_heartrate": 148,
            "max_heartrate": 176,
            "average_speed": 2.83,
            "calories": 380,
            "name": "Morning run",
            "map": {"summary_polyline": "abcdef"},
        }
        _stub_responses(monkeypatch, [[activity], []])
        rows = StravaProvider().fetch_since(account, datetime(2024, 1, 1, tzinfo=timezone.utc))
        assert len(rows) == 1
        row: CanonicalCardioRow = rows[0]
        assert row.activity_type == "run"
        assert row.duration_seconds == 1800
        assert row.distance_m == 5100.0
        assert row.avg_heart_rate == 148
        assert row.max_heart_rate == 176
        assert row.calories == 380
        assert row.source_app == "strava"
        assert row.source_external_id == "999888777"
        assert row.sync_account_id == account.id
        assert row.gps_polyline == "abcdef"
        assert row.performed_at.tzinfo is not None

    def test_weight_training_returns_empty(self, monkeypatch):
        """Strava WeightTraining has no per-set data — we skip it rather than
        pretending we can infer volume from session duration."""
        account = _make_account()
        activity = {
            "id": 42,
            "type": "WeightTraining",
            "start_date": "2024-03-18T14:22:10Z",
            "elapsed_time": 3600,
            "distance": 0,
            "name": "Leg day",
        }
        _stub_responses(monkeypatch, [[activity], []])
        rows = StravaProvider().fetch_since(account, datetime(2024, 1, 1, tzinfo=timezone.utc))
        assert rows == []

    def test_virtual_ride_maps_to_indoor_cycle(self, monkeypatch):
        account = _make_account()
        activity = {
            "id": 1,
            "type": "VirtualRide",
            "start_date": "2024-03-18T14:22:10Z",
            "elapsed_time": 2700,
            "distance": 25000.0,
            "name": "Zwift sprint",
        }
        _stub_responses(monkeypatch, [[activity], []])
        rows = StravaProvider().fetch_since(account, datetime(2024, 1, 1, tzinfo=timezone.utc))
        assert len(rows) == 1
        assert rows[0].activity_type == "indoor_cycle"

    def test_duration_zero_row_is_dropped(self, monkeypatch):
        account = _make_account()
        activity = {
            "id": 1,
            "type": "Run",
            "start_date": "2024-03-18T14:22:10Z",
            "elapsed_time": 0,
            "moving_time": 0,
            "distance": 0,
            "name": "Accidental start",
        }
        _stub_responses(monkeypatch, [[activity], []])
        rows = StravaProvider().fetch_since(account, datetime(2024, 1, 1, tzinfo=timezone.utc))
        assert rows == []

    def test_pagination_stops_on_partial_page(self, monkeypatch):
        """Paging short-circuits when a page returns fewer than per_page rows —
        saves us one round-trip per sync."""
        account = _make_account()
        activity = {
            "id": 1,
            "type": "Run",
            "start_date": "2024-03-18T14:22:10Z",
            "elapsed_time": 1800,
            "distance": 5000.0,
            "name": "R",
        }
        # First page has 1 activity (< per_page=200) so we should stop after it.
        _stub_responses(monkeypatch, [[activity], [{}] * 200])
        rows = StravaProvider().fetch_since(account, datetime(2024, 1, 1, tzinfo=timezone.utc))
        assert len(rows) == 1

    def test_row_hash_is_deterministic(self, monkeypatch):
        """Re-running the same payload through fetch_since twice should produce
        identical ``source_row_hash`` values. The upsert dedup depends on this."""
        account = _make_account()
        activity = {
            "id": 555,
            "type": "Run",
            "start_date": "2024-03-18T14:22:10Z",
            "elapsed_time": 2400,
            "distance": 7000.5,
            "name": "repeatable",
        }

        _stub_responses(monkeypatch, [[activity], []])
        first = StravaProvider().fetch_since(account, datetime(2024, 1, 1, tzinfo=timezone.utc))

        _stub_responses(monkeypatch, [[activity], []])
        second = StravaProvider().fetch_since(account, datetime(2024, 1, 1, tzinfo=timezone.utc))

        assert first[0].source_row_hash == second[0].source_row_hash
