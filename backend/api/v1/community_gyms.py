"""Community Gym Catalog API (Feature 3B).

A grow-as-you-go catalog of gyms keyed by Google Places `place_id`, plus
crowdsourced equipment reports with a confirmed/reported consensus.

ENDPOINTS (mounted at /api/v1/community-gyms):
- GET  /nearby                 — gyms near a lat/lng. Server-side Google Places
                                 (backend GOOGLE_MAPS_API_KEY). Each result is
                                 UPSERTed into `gyms`. If the key is not
                                 configured → 200 {gyms:[], catalog_only:true}
                                 PLUS any canonical gyms already in the DB within
                                 a bounding box. NEVER returns mock data.
- GET  /{place_id}             — gym row + consensus equipment (confirmed vs
                                 reported pills).
- POST /{place_id}/adopt       — create a gym_profile prefilled from the gym's
                                 consensus equipment, with place_id set.
- POST /{place_id}/report      — upsert THIS user's gym_equipment_reports row
                                 (one row per user per gym, replaced on
                                 resubmit). Also upserts the canonical gym.

Per project conventions:
- NO mock data, NO silent fallbacks. A missing Places key is an explicit
  catalog-only response, not fabricated gyms.
- Weights preserved verbatim (user works out in lbs).
- Extensive 🏋️ / ✅ / ❌ / ⚠️ prefixed logs.
"""

from __future__ import annotations

import math
import os
from datetime import datetime
from typing import List, Optional

import httpx
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field

from core.auth import get_current_user
from core.exceptions import safe_internal_error
from core.logger import get_logger
from core.supabase_client import get_supabase

logger = get_logger(__name__)

router = APIRouter()

# How many DISTINCT users must report an equipment item before it is shown as
# "confirmed" (vs an unconfirmed "reported" pill). Mirrors the SQL view's
# `confirmed = reporter_count >= 3` in migration 2242 — keep both in sync.
CONSENSUS_MIN_REPORTERS = 3

# Default radius (metres) for the nearby search. Matches the Flutter caller.
_DEFAULT_RADIUS_METERS = 5000

# Google Places "Nearby Search" (legacy v1 text/nearby) endpoint.
_PLACES_NEARBY_URL = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
_PLACES_TIMEOUT_SECONDS = 8


def _get_places_api_key() -> Optional[str]:
    """Return the backend Google Maps/Places key, or None if unconfigured.

    Read directly from the environment (config.Settings ignores extras), and
    treat the .env placeholder as unset so a fresh checkout degrades to the
    catalog-only path instead of calling Places with a junk key.
    """
    key = (os.getenv("GOOGLE_MAPS_API_KEY") or "").strip()
    if not key or key.upper().startswith("YOUR_") or key == "":
        return None
    return key


def _bounding_box(lat: float, lng: float, radius_m: float) -> tuple[float, float, float, float]:
    """Return (min_lat, max_lat, min_lng, max_lng) for a radius around a point.

    Used to query canonical gyms already in the DB when Places is unconfigured.
    Approximate (degrees-per-metre); good enough for a coarse "nearby" filter.
    """
    lat_delta = radius_m / 111_320.0  # metres per degree latitude
    # Guard the cosine near the poles so we never divide by ~0.
    cos_lat = max(math.cos(math.radians(lat)), 1e-6)
    lng_delta = radius_m / (111_320.0 * cos_lat)
    return lat - lat_delta, lat + lat_delta, lng - lng_delta, lng + lng_delta


def _haversine_m(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """Great-circle distance in metres."""
    r = 6_371_000.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlmb = math.radians(lng2 - lng1)
    a = math.sin(dphi / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dlmb / 2) ** 2
    return 2 * r * math.asin(min(1.0, math.sqrt(a)))


def _city_from_vicinity(vicinity: Optional[str]) -> Optional[str]:
    """Best-effort city extraction from a Places `vicinity`/address string.

    Places `vicinity` is typically "123 Main St, Springfield". Take the last
    comma-segment as a coarse city. Returns None when nothing usable.
    """
    if not vicinity:
        return None
    parts = [p.strip() for p in vicinity.split(",") if p.strip()]
    if not parts:
        return None
    return parts[-1]


# =============================================================================
# Response / request models
# =============================================================================


class CommunityGym(BaseModel):
    place_id: str
    name: str
    address: Optional[str] = None
    city: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    source: str = "places"
    distance_meters: Optional[float] = None


class NearbyGymsResponse(BaseModel):
    gyms: List[CommunityGym]
    catalog_only: bool = False
    # True when results came from a live Places call; False when served from the
    # local canonical catalog (Places unconfigured). Helps the UI explain itself.
    from_places: bool = False


class ConsensusEquipment(BaseModel):
    equipment: str
    reporter_count: int
    confirmed: bool


class GymDetailResponse(BaseModel):
    gym: CommunityGym
    confirmed: List[ConsensusEquipment]
    reported: List[ConsensusEquipment]
    total_reporters: int = 0
    consensus_min_reporters: int = CONSENSUS_MIN_REPORTERS


class ReportEquipmentRequest(BaseModel):
    """One user's equipment report for a gym. Resubmit replaces the prior row."""
    equipment: List[str] = Field(default_factory=list)
    equipment_details: List[dict] = Field(default_factory=list)
    source: str = "manual"
    # Optional gym metadata so a report can also seed/refresh the canonical row
    # when the gym was discovered outside the nearby flow.
    name: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None


# =============================================================================
# Canonical-gym upsert helper
# =============================================================================


def _upsert_gym(
    *,
    place_id: str,
    name: str,
    address: Optional[str] = None,
    city: Optional[str] = None,
    latitude: Optional[float] = None,
    longitude: Optional[float] = None,
    source: str = "places",
) -> None:
    """UPSERT a canonical gym row (keyed by place_id), bumping seen_count.

    On conflict we refresh last_seen_at and increment seen_count. Supabase's
    PostgREST upsert can't increment in place, so we read-then-write: load the
    existing row, compute the next seen_count, and upsert the merged record.
    Best-effort — never raises into the request path.
    """
    try:
        supabase = get_supabase()
        now_iso = datetime.utcnow().isoformat()

        existing = supabase.client.table("gyms") \
            .select("id, seen_count, name, address, city, latitude, longitude") \
            .eq("place_id", place_id) \
            .limit(1) \
            .execute()

        if existing.data:
            prior = existing.data[0]
            payload = {
                "place_id": place_id,
                # Prefer fresh non-empty values, else keep what we had.
                "name": name or prior.get("name"),
                "address": address if address is not None else prior.get("address"),
                "city": city if city is not None else prior.get("city"),
                "latitude": latitude if latitude is not None else prior.get("latitude"),
                "longitude": longitude if longitude is not None else prior.get("longitude"),
                "seen_count": int(prior.get("seen_count") or 1) + 1,
                "last_seen_at": now_iso,
            }
        else:
            payload = {
                "place_id": place_id,
                "name": name,
                "address": address,
                "city": city,
                "latitude": latitude,
                "longitude": longitude,
                "source": source,
                "seen_count": 1,
                "first_seen_at": now_iso,
                "last_seen_at": now_iso,
            }

        supabase.client.table("gyms") \
            .upsert(payload, on_conflict="place_id") \
            .execute()
    except Exception as e:
        logger.warning(f"⚠️ [CommunityGyms] _upsert_gym failed for {place_id} (non-fatal): {e}")


def _gym_row_to_model(row: dict, *, distance_meters: Optional[float] = None) -> CommunityGym:
    return CommunityGym(
        place_id=row["place_id"],
        name=row.get("name") or "Gym",
        address=row.get("address"),
        city=row.get("city"),
        latitude=row.get("latitude"),
        longitude=row.get("longitude"),
        source=row.get("source") or "places",
        distance_meters=distance_meters,
    )


# =============================================================================
# GET /nearby
# =============================================================================


@router.get("/nearby", response_model=NearbyGymsResponse)
async def nearby_gyms(
    latitude: float = Query(..., ge=-90, le=90, description="Current latitude"),
    longitude: float = Query(..., ge=-180, le=180, description="Current longitude"),
    radius_meters: int = Query(
        _DEFAULT_RADIUS_METERS, ge=200, le=50000,
        description="Search radius in metres (default 5000).",
    ),
    query: Optional[str] = Query(
        None, description="Optional name filter (search by name in the catalog).",
    ),
    current_user: dict = Depends(get_current_user),
):
    """Find gyms near a point.

    Behaviour:
      * Places key configured → live Google Places Nearby Search (type=gym), each
        result UPSERTed into the canonical `gyms` table. `from_places=true`.
      * Places key NOT configured → `catalog_only=true`, and we return the
        canonical gyms already in the DB inside the bounding box (no Places call,
        NO mock data).

    `query` is an optional case-insensitive name filter applied to both paths.
    """
    api_key = _get_places_api_key()

    # ── Catalog-only path (no Places key) ──────────────────────────────────
    if not api_key:
        logger.info("🏋️ [CommunityGyms] /nearby catalog-only (no Places key)")
        return _nearby_from_catalog(latitude, longitude, radius_meters, query, catalog_only=True)

    # ── Live Places path ────────────────────────────────────────────────────
    try:
        params = {
            "location": f"{latitude},{longitude}",
            "radius": str(radius_meters),
            "type": "gym",
            "key": api_key,
        }
        if query and query.strip():
            params["keyword"] = query.strip()

        async with httpx.AsyncClient(timeout=_PLACES_TIMEOUT_SECONDS) as client:
            resp = await client.get(_PLACES_NEARBY_URL, params=params)
        resp.raise_for_status()
        data = resp.json()

        status = data.get("status")
        if status not in ("OK", "ZERO_RESULTS"):
            # Surface a real failure instead of fabricating gyms. A bad key /
            # quota error should be visible, not silently masked.
            logger.error(f"❌ [CommunityGyms] Places returned status={status}: {data.get('error_message')}")
            raise HTTPException(
                status_code=502,
                detail=f"Gym search is temporarily unavailable (Places status: {status}).",
            )

        out: List[CommunityGym] = []
        for place in (data.get("results") or []):
            pid = place.get("place_id")
            if not pid:
                continue
            name = place.get("name") or "Gym"
            vicinity = place.get("vicinity")
            loc = (place.get("geometry") or {}).get("location") or {}
            lat = loc.get("lat")
            lng = loc.get("lng")
            city = _city_from_vicinity(vicinity)

            # Grow the catalog: every Places result becomes (or refreshes) a
            # canonical gym row keyed by place_id.
            _upsert_gym(
                place_id=pid,
                name=name,
                address=vicinity,
                city=city,
                latitude=lat,
                longitude=lng,
                source="places",
            )

            dist = None
            if lat is not None and lng is not None:
                dist = round(_haversine_m(latitude, longitude, lat, lng), 1)

            out.append(CommunityGym(
                place_id=pid,
                name=name,
                address=vicinity,
                city=city,
                latitude=lat,
                longitude=lng,
                source="places",
                distance_meters=dist,
            ))

        out.sort(key=lambda g: (g.distance_meters is None, g.distance_meters or 0.0))
        logger.info(f"✅ [CommunityGyms] /nearby Places returned {len(out)} gyms")
        return NearbyGymsResponse(gyms=out, catalog_only=False, from_places=True)

    except HTTPException:
        raise
    except Exception as e:
        # Network / parse error on the live path. Do NOT fabricate gyms — fall
        # back to the canonical catalog (real, previously-seen gyms) and mark it
        # catalog_only so the UI can offer "search by name".
        logger.warning(f"⚠️ [CommunityGyms] Places call failed; serving catalog: {e}")
        return _nearby_from_catalog(latitude, longitude, radius_meters, query, catalog_only=True)


def _nearby_from_catalog(
    latitude: float,
    longitude: float,
    radius_meters: int,
    query: Optional[str],
    *,
    catalog_only: bool,
) -> NearbyGymsResponse:
    """Return canonical gyms within a bounding box around the point.

    Real rows only (previously discovered/reported gyms) — no mock data. Sorted
    by true haversine distance.
    """
    try:
        supabase = get_supabase()
        min_lat, max_lat, min_lng, max_lng = _bounding_box(latitude, longitude, float(radius_meters))

        q = supabase.client.table("gyms") \
            .select("*") \
            .gte("latitude", min_lat).lte("latitude", max_lat) \
            .gte("longitude", min_lng).lte("longitude", max_lng)
        if query and query.strip():
            q = q.ilike("name", f"%{query.strip()}%")
        result = q.limit(60).execute()

        rows = result.data or []
        models: List[CommunityGym] = []
        for row in rows:
            lat = row.get("latitude")
            lng = row.get("longitude")
            dist = None
            if lat is not None and lng is not None:
                dist = round(_haversine_m(latitude, longitude, lat, lng), 1)
            models.append(_gym_row_to_model(row, distance_meters=dist))

        models.sort(key=lambda g: (g.distance_meters is None, g.distance_meters or 0.0))
        logger.info(f"🏋️ [CommunityGyms] /nearby catalog returned {len(models)} gyms")
        return NearbyGymsResponse(gyms=models, catalog_only=catalog_only, from_places=False)
    except Exception as e:
        logger.error(f"❌ [CommunityGyms] catalog query failed: {e}", exc_info=True)
        # Empty (real) result rather than a fabricated one.
        return NearbyGymsResponse(gyms=[], catalog_only=catalog_only, from_places=False)


# =============================================================================
# Consensus helper
# =============================================================================


def _load_consensus(place_id: str) -> tuple[List[ConsensusEquipment], List[ConsensusEquipment], int]:
    """Return (confirmed, reported, total_reporters) for a gym.

    confirmed = items with reporter_count >= CONSENSUS_MIN_REPORTERS.
    reported  = items below that threshold.
    """
    supabase = get_supabase()
    rows = supabase.client.table("gym_equipment_consensus") \
        .select("equipment, reporter_count, confirmed") \
        .eq("place_id", place_id) \
        .execute()

    confirmed: List[ConsensusEquipment] = []
    reported: List[ConsensusEquipment] = []
    for r in (rows.data or []):
        item = ConsensusEquipment(
            equipment=r["equipment"],
            reporter_count=int(r.get("reporter_count") or 0),
            confirmed=bool(r.get("confirmed")),
        )
        (confirmed if item.confirmed else reported).append(item)

    confirmed.sort(key=lambda e: (-e.reporter_count, e.equipment))
    reported.sort(key=lambda e: (-e.reporter_count, e.equipment))

    # Distinct reporters across the whole gym.
    reporters = supabase.client.table("gym_equipment_reports") \
        .select("user_id", count="exact") \
        .eq("place_id", place_id) \
        .execute()
    total = reporters.count or 0
    return confirmed, reported, total


# =============================================================================
# GET /{place_id}
# =============================================================================


@router.get("/{place_id}", response_model=GymDetailResponse)
async def gym_detail(
    place_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Gym row + consensus equipment (confirmed vs reported)."""
    try:
        supabase = get_supabase()
        gym_result = supabase.client.table("gyms") \
            .select("*") \
            .eq("place_id", place_id) \
            .limit(1) \
            .execute()

        if not gym_result.data:
            raise HTTPException(status_code=404, detail="Gym not found in the catalog")

        gym = _gym_row_to_model(gym_result.data[0])
        confirmed, reported, total = _load_consensus(place_id)

        logger.info(
            f"✅ [CommunityGyms] detail {place_id}: {len(confirmed)} confirmed, "
            f"{len(reported)} reported, {total} reporters"
        )
        return GymDetailResponse(
            gym=gym,
            confirmed=confirmed,
            reported=reported,
            total_reporters=total,
            consensus_min_reporters=CONSENSUS_MIN_REPORTERS,
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ [CommunityGyms] detail failed for {place_id}: {e}", exc_info=True)
        raise safe_internal_error(e, "endpoint")


# =============================================================================
# POST /{place_id}/report
# =============================================================================


@router.post("/{place_id}/report", response_model=GymDetailResponse)
async def report_equipment(
    place_id: str,
    body: ReportEquipmentRequest,
    current_user: dict = Depends(get_current_user),
):
    """Upsert THIS user's equipment report for a gym (one row per user per gym).

    Resubmitting REPLACES the prior row (UPSERT on (user_id, place_id)). Also
    upserts the canonical gym so a report can seed it when the gym was reached
    outside the nearby flow. Returns the refreshed consensus.
    """
    user_id = str(current_user["id"])
    try:
        # Make sure the canonical gym exists / is refreshed first (the report FK
        # points at gyms.place_id). Use any metadata the client supplied.
        _upsert_gym(
            place_id=place_id,
            name=body.name or "Gym",
            address=body.address,
            city=body.city,
            latitude=body.latitude,
            longitude=body.longitude,
            source="report",
        )

        supabase = get_supabase()
        now_iso = datetime.utcnow().isoformat()

        # Look up an existing report so we can preserve created_at on replace.
        existing = supabase.client.table("gym_equipment_reports") \
            .select("created_at") \
            .eq("user_id", user_id) \
            .eq("place_id", place_id) \
            .limit(1) \
            .execute()
        created_at = (existing.data[0]["created_at"] if existing.data else now_iso)

        payload = {
            "user_id": user_id,
            "place_id": place_id,
            "equipment": list(body.equipment or []),
            "equipment_details": body.equipment_details or [],
            "source": body.source or "manual",
            "created_at": created_at,
            "updated_at": now_iso,
        }

        supabase.client.table("gym_equipment_reports") \
            .upsert(payload, on_conflict="user_id,place_id") \
            .execute()

        logger.info(
            f"✅ [CommunityGyms] report by {user_id} for {place_id}: "
            f"{len(body.equipment or [])} items"
        )

        # Return the refreshed gym detail (consensus may have moved an item to
        # confirmed if this report tipped it over CONSENSUS_MIN_REPORTERS).
        gym_result = supabase.client.table("gyms") \
            .select("*") \
            .eq("place_id", place_id) \
            .limit(1) \
            .execute()
        gym = _gym_row_to_model(gym_result.data[0]) if gym_result.data else CommunityGym(
            place_id=place_id, name=body.name or "Gym",
        )
        confirmed, reported, total = _load_consensus(place_id)
        return GymDetailResponse(
            gym=gym,
            confirmed=confirmed,
            reported=reported,
            total_reporters=total,
            consensus_min_reporters=CONSENSUS_MIN_REPORTERS,
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ [CommunityGyms] report failed for {place_id}: {e}", exc_info=True)
        raise safe_internal_error(e, "endpoint")


# =============================================================================
# POST /{place_id}/adopt
# =============================================================================


class AdoptGymRequest(BaseModel):
    """Optional overrides when adopting a community gym as a personal profile."""
    name: Optional[str] = Field(default=None, max_length=100)
    # When true, only confirmed (>=3 reporters) equipment is prefilled. Default
    # false → include everything reported (the user can prune in the editor).
    confirmed_only: bool = False


@router.post("/{place_id}/adopt")
async def adopt_gym(
    place_id: str,
    body: Optional[AdoptGymRequest] = None,
    user_id: str = Query(..., description="User ID adopting the gym"),
    current_user: dict = Depends(get_current_user),
):
    """Create a gym_profile prefilled from a community gym's consensus equipment.

    The new profile carries the gym's place_id + location and its consensus
    equipment list. It is NOT auto-activated (returns to the live pool at the end
    of display_order). Returns the created GymProfile.
    """
    try:
        # Defense-in-depth: a user may only adopt a gym onto their OWN profile.
        # (report_equipment derives user_id straight from the token; adopt keeps
        # the query param for the client contract but must match the caller so a
        # forged user_id can't create a profile owned by someone else.)
        if str(user_id) != str(current_user.get("id")):
            raise HTTPException(
                status_code=403, detail="Cannot adopt a gym for another user"
            )

        supabase = get_supabase()

        gym_result = supabase.client.table("gyms") \
            .select("*") \
            .eq("place_id", place_id) \
            .limit(1) \
            .execute()
        if not gym_result.data:
            raise HTTPException(status_code=404, detail="Gym not found in the catalog")
        gym = gym_result.data[0]

        confirmed, reported, _ = _load_consensus(place_id)
        if body and body.confirmed_only:
            equipment = [c.equipment for c in confirmed]
        else:
            equipment = [c.equipment for c in confirmed] + [r.equipment for r in reported]
        # Dedupe while preserving order. Bodyweight is always implicitly available.
        seen = set()
        equipment = [e for e in equipment if not (e in seen or seen.add(e))]
        if not equipment:
            equipment = ["bodyweight"]

        # Append at end of display order.
        order_result = supabase.client.table("gym_profiles") \
            .select("display_order") \
            .eq("user_id", user_id) \
            .order("display_order", desc=True) \
            .limit(1) \
            .execute()
        max_order = order_result.data[0]["display_order"] if order_result.data else -1

        profile_name = (body.name.strip() if (body and body.name) else None) or gym.get("name") or "Gym"
        now = datetime.utcnow().isoformat()
        profile_data = {
            "user_id": user_id,
            "name": profile_name[:100],
            "icon": "fitness_center",
            "color": "#00BCD4",
            "equipment": equipment,
            "equipment_details": [],
            "workout_environment": "commercial_gym",
            "address": gym.get("address"),
            "city": gym.get("city"),
            "latitude": gym.get("latitude"),
            "longitude": gym.get("longitude"),
            "place_id": place_id,
            "display_order": max_order + 1,
            "is_active": False,
            "created_at": now,
            "updated_at": now,
        }

        result = supabase.client.table("gym_profiles") \
            .insert(profile_data) \
            .execute()
        if not result.data:
            raise safe_internal_error(RuntimeError("DB insert returned no data"), "endpoint")

        from .gym_profiles import row_to_gym_profile
        created = row_to_gym_profile(result.data[0])
        logger.info(
            f"✅ [CommunityGyms] adopt {place_id} → profile '{created.name}' "
            f"({len(equipment)} equipment) for user {user_id}"
        )
        return created
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ [CommunityGyms] adopt failed for {place_id}: {e}", exc_info=True)
        raise safe_internal_error(e, "endpoint")
