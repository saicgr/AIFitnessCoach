"""
Weather lookup via Open-Meteo (free, no API key).

Used by the cardio refuel prescriber (see `refuel_service.py`) and any other
caller that needs to enrich a cardio session with the weather it happened in.

Open-Meteo docs: https://open-meteo.com/en/docs

Hourly variables we ask for:
  - temperature_2m       (°C)
  - relative_humidity_2m (%)
  - wind_speed_10m       (km/h — `wind_speed_unit=kmh` is the default)
  - weather_code         (WMO interpretation code, 0-99)

Failure model:
  - On any error (HTTP, parse, timeout, rate-limit) return None. Callers
    must treat weather as optional context, never a hard requirement.

Cache:
  - In-process dict keyed by (round(lat,1), round(lon,1), hour_utc) with
    a 24h TTL. Coarse rounding because weather doesn't meaningfully vary
    inside a ~10km grid cell for our use case (refuel guidance).
"""
from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Optional, Tuple, Dict, Any

import httpx
from pydantic import BaseModel

from core.logger import get_logger

logger = get_logger(__name__)

_OPEN_METEO_URL = "https://api.open-meteo.com/v1/forecast"
_CACHE_TTL_SECONDS = 24 * 60 * 60  # 24h
# {(lat_r, lon_r, hour_iso): (expires_at, snapshot)}
_CACHE: Dict[Tuple[float, float, str], Tuple[datetime, "WeatherSnapshot"]] = {}


# WMO weather interpretation codes — Open-Meteo's `weather_code` field.
# Source: https://open-meteo.com/en/docs (search "WMO Weather interpretation codes")
_WMO_CODE_TO_TEXT: Dict[int, str] = {
    0: "Clear",
    1: "Mainly clear",
    2: "Partly cloudy",
    3: "Overcast",
    45: "Fog",
    48: "Depositing rime fog",
    51: "Light drizzle",
    53: "Moderate drizzle",
    55: "Dense drizzle",
    56: "Light freezing drizzle",
    57: "Dense freezing drizzle",
    61: "Light rain",
    63: "Moderate rain",
    65: "Heavy rain",
    66: "Light freezing rain",
    67: "Heavy freezing rain",
    71: "Light snow",
    73: "Moderate snow",
    75: "Heavy snow",
    77: "Snow grains",
    80: "Light showers",
    81: "Moderate showers",
    82: "Violent showers",
    85: "Light snow showers",
    86: "Heavy snow showers",
    95: "Thunderstorm",
    96: "Thunderstorm with light hail",
    99: "Thunderstorm with heavy hail",
}


def _wmo_to_text(code: Optional[int]) -> str:
    if code is None:
        return "Unknown"
    return _WMO_CODE_TO_TEXT.get(int(code), f"WMO {code}")


class WeatherSnapshot(BaseModel):
    """A single-point-in-time weather observation."""

    temp_c: float
    humidity_pct: float
    wind_kph: float
    condition: str
    source: str = "open-meteo"


def _cache_key(lat: float, lon: float, ts_utc: datetime) -> Tuple[float, float, str]:
    # Coarse spatial bucket + hourly time bucket.
    hour = ts_utc.replace(minute=0, second=0, microsecond=0)
    return (round(lat, 1), round(lon, 1), hour.isoformat())


def _cache_get(key: Tuple[float, float, str]) -> Optional[WeatherSnapshot]:
    entry = _CACHE.get(key)
    if entry is None:
        return None
    expires_at, snap = entry
    if datetime.now(timezone.utc) >= expires_at:
        _CACHE.pop(key, None)
        return None
    return snap


def _cache_set(key: Tuple[float, float, str], snap: WeatherSnapshot) -> None:
    _CACHE[key] = (
        datetime.now(timezone.utc) + timedelta(seconds=_CACHE_TTL_SECONDS),
        snap,
    )


def _closest_hour_index(times: list, target: datetime) -> int:
    """Return the index in `times` (ISO strings) whose timestamp is closest to
    `target`. Open-Meteo returns naive ISO strings in the requested timezone
    (we ask for UTC), so we parse them as UTC."""
    target_utc = target.astimezone(timezone.utc).replace(tzinfo=None)
    best_idx = 0
    best_delta = None
    for i, t in enumerate(times):
        try:
            # Open-Meteo hourly times look like "2025-05-23T14:00"
            dt = datetime.fromisoformat(t)
        except (ValueError, TypeError):
            continue
        delta = abs((dt - target_utc).total_seconds())
        if best_delta is None or delta < best_delta:
            best_delta = delta
            best_idx = i
    return best_idx


def _parse_response(payload: Dict[str, Any], ts_utc: datetime) -> Optional[WeatherSnapshot]:
    hourly = payload.get("hourly") or {}
    times = hourly.get("time") or []
    if not times:
        return None
    idx = _closest_hour_index(times, ts_utc)

    def _at(field: str) -> Optional[float]:
        arr = hourly.get(field) or []
        if idx < 0 or idx >= len(arr):
            return None
        v = arr[idx]
        try:
            return float(v) if v is not None else None
        except (ValueError, TypeError):
            return None

    temp = _at("temperature_2m")
    humidity = _at("relative_humidity_2m")
    wind = _at("wind_speed_10m")
    code = _at("weather_code")
    if temp is None and humidity is None and wind is None:
        return None
    return WeatherSnapshot(
        temp_c=temp if temp is not None else 0.0,
        humidity_pct=humidity if humidity is not None else 0.0,
        wind_kph=wind if wind is not None else 0.0,
        condition=_wmo_to_text(int(code) if code is not None else None),
    )


async def get_weather(
    lat: float, lon: float, ts_utc: datetime
) -> Optional[WeatherSnapshot]:
    """Fetch (or return cached) weather snapshot for the hour closest to `ts_utc`.

    Returns None on any error — Open-Meteo down, rate-limited, parse error,
    timeout, etc. Callers must treat None as "no weather context available".
    """
    # Defensive: normalize ts_utc to UTC. If naive, assume UTC.
    if ts_utc.tzinfo is None:
        ts_utc = ts_utc.replace(tzinfo=timezone.utc)
    else:
        ts_utc = ts_utc.astimezone(timezone.utc)

    key = _cache_key(lat, lon, ts_utc)
    cached = _cache_get(key)
    if cached is not None:
        return cached

    # Open-Meteo wants start_date/end_date as YYYY-MM-DD. Use the day-of for
    # the target timestamp; this returns 24 hourly slots and we pick the
    # closest one.
    day = ts_utc.strftime("%Y-%m-%d")
    params = {
        "latitude": f"{lat:.4f}",
        "longitude": f"{lon:.4f}",
        "hourly": "temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code",
        "start_date": day,
        "end_date": day,
        "timezone": "UTC",
        "wind_speed_unit": "kmh",
    }
    try:
        async with httpx.AsyncClient(timeout=httpx.Timeout(8.0, connect=4.0)) as client:
            resp = await client.get(_OPEN_METEO_URL, params=params)
        if resp.status_code != 200:
            logger.warning(
                f"[Weather] non-200 from Open-Meteo: {resp.status_code} (lat={lat}, lon={lon})"
            )
            return None
        snap = _parse_response(resp.json(), ts_utc)
        if snap is not None:
            _cache_set(key, snap)
        return snap
    except (httpx.HTTPError, ValueError, KeyError) as e:
        logger.warning(f"[Weather] fetch failed: {e}")
        return None
    except Exception as e:  # noqa: BLE001 — never crash callers
        logger.error(f"[Weather] unexpected error: {e}", exc_info=True)
        return None


def _clear_cache_for_tests() -> None:
    """Test-only helper."""
    _CACHE.clear()
