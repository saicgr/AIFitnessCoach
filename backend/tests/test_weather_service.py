"""Tests for `services/weather_service.py`.

Pure-Python tests — we mock `httpx.AsyncClient.get` so no network is hit.
"""
from __future__ import annotations

import asyncio
from datetime import datetime, timezone
from unittest.mock import AsyncMock, patch

import pytest

from services import weather_service
from services.weather_service import (
    WeatherSnapshot,
    _wmo_to_text,
    get_weather,
)


# ---- Fixtures -----------------------------------------------------------

def _fake_open_meteo_payload(temps=None, hums=None, winds=None, codes=None):
    times = [
        "2025-05-23T12:00",
        "2025-05-23T13:00",
        "2025-05-23T14:00",
        "2025-05-23T15:00",
    ]
    return {
        "hourly": {
            "time": times,
            "temperature_2m": temps if temps is not None else [10.0, 11.0, 12.0, 13.0],
            "relative_humidity_2m": hums if hums is not None else [60, 62, 65, 70],
            "wind_speed_10m": winds if winds is not None else [5.0, 6.0, 7.0, 8.0],
            "weather_code": codes if codes is not None else [0, 1, 2, 3],
        }
    }


class _FakeResp:
    def __init__(self, payload, status_code=200):
        self._payload = payload
        self.status_code = status_code

    def json(self):
        return self._payload


# ---- WMO mapping --------------------------------------------------------

def test_wmo_known_codes_map_to_text():
    assert _wmo_to_text(0) == "Clear"
    assert _wmo_to_text(2) == "Partly cloudy"
    assert _wmo_to_text(45) == "Fog"
    assert _wmo_to_text(61) == "Light rain"
    assert _wmo_to_text(71) == "Light snow"
    assert _wmo_to_text(80) == "Light showers"
    assert _wmo_to_text(95) == "Thunderstorm"


def test_wmo_unknown_falls_back_gracefully():
    # 999 isn't in the WMO table — must not raise.
    assert _wmo_to_text(999).startswith("WMO")
    assert _wmo_to_text(None) == "Unknown"


# ---- Fetch + cache ------------------------------------------------------

def _run(coro):
    return asyncio.get_event_loop().run_until_complete(coro)


def test_fetch_returns_closest_hour_and_caches():
    weather_service._clear_cache_for_tests()
    payload = _fake_open_meteo_payload()
    fake_resp = _FakeResp(payload)

    with patch("services.weather_service.httpx.AsyncClient") as mock_client:
        client_instance = mock_client.return_value.__aenter__.return_value
        client_instance.get = AsyncMock(return_value=fake_resp)
        ts = datetime(2025, 5, 23, 14, 12, 0, tzinfo=timezone.utc)
        snap = _run(get_weather(40.7, -74.0, ts))
        assert isinstance(snap, WeatherSnapshot)
        # 14:00 is the closest slot — temp 12, code 2 (Partly cloudy)
        assert snap.temp_c == 12.0
        assert snap.condition == "Partly cloudy"
        assert snap.source == "open-meteo"
        assert client_instance.get.await_count == 1

        # Cached call — no second HTTP request.
        snap2 = _run(get_weather(40.7, -74.0, ts))
        assert snap2.temp_c == 12.0
        assert client_instance.get.await_count == 1


def test_rate_limit_returns_none():
    weather_service._clear_cache_for_tests()
    fake_resp = _FakeResp({}, status_code=429)
    with patch("services.weather_service.httpx.AsyncClient") as mock_client:
        client_instance = mock_client.return_value.__aenter__.return_value
        client_instance.get = AsyncMock(return_value=fake_resp)
        ts = datetime(2025, 5, 23, 14, 0, 0, tzinfo=timezone.utc)
        snap = _run(get_weather(0.0, 0.0, ts))
        assert snap is None


def test_network_error_returns_none():
    weather_service._clear_cache_for_tests()
    import httpx

    with patch("services.weather_service.httpx.AsyncClient") as mock_client:
        client_instance = mock_client.return_value.__aenter__.return_value
        client_instance.get = AsyncMock(side_effect=httpx.ConnectError("boom"))
        ts = datetime(2025, 5, 23, 14, 0, 0, tzinfo=timezone.utc)
        snap = _run(get_weather(1.0, 2.0, ts))
        assert snap is None


def test_malformed_payload_returns_none():
    weather_service._clear_cache_for_tests()
    fake_resp = _FakeResp({"hourly": {"time": []}})  # no slots
    with patch("services.weather_service.httpx.AsyncClient") as mock_client:
        client_instance = mock_client.return_value.__aenter__.return_value
        client_instance.get = AsyncMock(return_value=fake_resp)
        ts = datetime(2025, 5, 23, 14, 0, 0, tzinfo=timezone.utc)
        snap = _run(get_weather(1.0, 2.0, ts))
        assert snap is None
