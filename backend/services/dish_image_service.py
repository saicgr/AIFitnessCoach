"""Dish image resolution for menu scans.

A scanned menu is 40-80 rows of text. Thumbnails make it scannable — but
generating an image per dish would cost ~$1.20 for the first person to scan a
60-dish restaurant, which is not a price worth paying for decoration. So the
resolver spends nothing until it has to, in this order:

  1. user_photo — a photo the USER already took of that same dish. Free, real,
     and personal ("that's MY steak").
  2. food_db    — food_database.image_url when the dish matches a catalog row.
     Free, already in our DB.
  3. web_cc     — a free-licence photo from Wikimedia Commons / Open Food Facts,
     downloaded once and re-hosted. Free, real food, attribution stored and
     rendered.
  4. ai         — a generated illustration, a few cents. Only for dishes the
     user is actually likely to look at: the Recommended picks and anything
     they tap. The model and its region are owned by
     `services.image_generation_service`, never by this module.

Every result is cached in `dish_image_cache` keyed on the NORMALIZED dish name
with **no user_id**, so "caesar salad" is resolved once for the whole app and
every later scan at every restaurant is free. Same economics as
`menu_scan_cache`: the first user pays, everyone else doesn't.

Cost discipline mirrors `share_ai_service`: kill-switch env flag, per-user
daily cap on generations, cache hits never consume the cap, and no silent
fallback — a dish that can't be resolved returns None so the UI shows a
placeholder rather than a wrong picture.
"""
from __future__ import annotations

import asyncio
import os
from datetime import date, datetime, timezone
from typing import Any, Dict, List, Optional

import httpx

from core.db.facade import get_supabase_db
from core.logger import get_logger
from services.s3_service import get_s3_service

logger = get_logger(__name__)


class DishImageError(Exception):
    """Surfaced to the endpoint as a real error (no silent fallback)."""


class DishImageDisabled(DishImageError):
    pass


class DishImageCapReached(DishImageError):
    pass


class DishImageUnavailable(DishImageError):
    """The image model could not produce a picture for this dish.

    Model not enabled for the project, safety-blocked, or the platform refused.
    Nothing the user did and nothing a retry fixes — a thumbnail is decoration,
    so the endpoint answers "no image" with the reason attached instead of
    failing the request. It is still logged loudly: honest, not silent.
    """


# --------------------------------------------------------------------------- #
# Kill-switches + caps
# --------------------------------------------------------------------------- #
def _env_flag(name: str, default: bool = True) -> bool:
    raw = os.getenv(name)
    if raw is None:
        return default
    return raw.strip().lower() not in ("0", "false", "no", "off", "")


def images_enabled() -> bool:
    """Master switch for dish thumbnails (free sources included)."""
    return _env_flag("DISH_IMAGES_ENABLED", True)


def generation_enabled() -> bool:
    """AI-generation switch only. Off = free sources still resolve."""
    return _env_flag("DISH_IMAGE_AI_ENABLED", True)


def web_lookup_enabled() -> bool:
    return _env_flag("DISH_IMAGE_WEB_ENABLED", True)


def generation_daily_cap() -> int:
    """Per-user generations per day. ~8 auto (Recommended) + taps."""
    try:
        return max(0, int(os.getenv("DISH_IMAGE_DAILY_CAP", "25")))
    except ValueError:
        return 25


def image_model() -> str:
    """Image model for dish thumbnails.

    Defaults to whatever `services.image_generation_service` owns — currently
    `gemini-2.5-flash-image`, the only image model this Vertex project actually
    has (every `imagen-*` model 404s here in every region; see that module).
    `DISH_IMAGE_MODEL` still overrides per-feature, and the chokepoint routes an
    `imagen-*` override to a regional endpoint automatically.
    """
    from services.image_generation_service import default_image_model

    return os.getenv("DISH_IMAGE_MODEL") or default_image_model()


AI_DISCLOSURE = "AI-generated illustration"

# A batch resolve should never sit there hammering the network. Web lookups are
# the only slow step, so they're bounded on both fan-out and per-dish time.
_WEB_CONCURRENCY = 6
_WEB_TIMEOUT_S = 6.0
_MAX_WEB_LOOKUPS_PER_BATCH = 20
_MAX_IMAGE_BYTES = 4 * 1024 * 1024


# --------------------------------------------------------------------------- #
# Cache
# --------------------------------------------------------------------------- #
def _normalize(name: str) -> str:
    """Shared normalizer — same one the menu duplicate-check + history
    frequency map use, so a dish keys identically across every feature."""
    from api.v1.nutrition.menu_analyses import _normalize_dish_name

    return _normalize_dish_name(name)


def _lookup_cache(normalized_names: List[str]) -> Dict[str, Dict[str, Any]]:
    """Batch cache read. One query for the whole menu, not one per dish."""
    if not normalized_names:
        return {}
    db = get_supabase_db()
    res = (
        db.client.table("dish_image_cache")
        .select("*")
        .in_("normalized_name", normalized_names)
        .execute()
    )
    return {row["normalized_name"]: row for row in (res.data or [])}


def _store_cache(
    *,
    normalized_name: str,
    display_name: str,
    source: str,
    s3_key: Optional[str] = None,
    external_url: Optional[str] = None,
    attribution: Optional[str] = None,
    model: Optional[str] = None,
) -> None:
    db = get_supabase_db()
    db.client.table("dish_image_cache").upsert(
        {
            "normalized_name": normalized_name,
            "display_name": display_name,
            "source": source,
            "s3_key": s3_key,
            "external_url": external_url,
            "attribution": attribution,
            "model": model,
        },
        on_conflict="normalized_name",
    ).execute()


def _touch_cache(normalized_name: str) -> None:
    try:
        get_supabase_db().client.rpc(
            "dish_image_cache_touch", {"p_normalized_name": normalized_name}
        ).execute()
    except Exception as exc:  # noqa: BLE001 — a counter must never break a read
        logger.debug(f"[DishImage] touch failed for {normalized_name}: {exc}")


def _presign(s3_key: str, expires_in: int = 24 * 3600) -> str:
    s3 = get_s3_service()
    if not s3.is_configured():
        raise DishImageError("S3 is not configured (missing AWS credentials or bucket)")
    return s3._client.generate_presigned_url(  # noqa: SLF001 — same access as share_ai_service
        "get_object",
        Params={"Bucket": s3.bucket, "Key": s3_key},
        ExpiresIn=expires_in,
    )


def _row_to_result(row: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    """Cache row → API shape. Returns None for a row that points nowhere."""
    url = None
    if row.get("s3_key"):
        try:
            url = _presign(row["s3_key"])
        except DishImageError:
            return None
    elif row.get("external_url"):
        url = row["external_url"]
    if not url:
        return None
    return {
        "url": url,
        "source": row.get("source"),
        "attribution": row.get("attribution"),
        "is_ai": row.get("source") == "ai",
        "disclosure": AI_DISCLOSURE if row.get("source") == "ai" else None,
    }


# --------------------------------------------------------------------------- #
# Free source 1 — the user's own photos
# --------------------------------------------------------------------------- #
def _lookup_user_photos(user_id: str, wanted: Dict[str, str]) -> Dict[str, Dict[str, Any]]:
    """Match wanted dishes against photos this user already took.

    One bulk query over the user's recent photographed logs, then matched in
    Python on the normalized name — far cheaper than a query per dish.
    """
    if not wanted:
        return {}
    db = get_supabase_db()
    res = (
        db.client.table("food_logs")
        .select("food_name, food_items, image_url, logged_at")
        .eq("user_id", user_id)
        .not_.is_("image_url", "null")
        .is_("deleted_at", "null")
        .order("logged_at", desc=True)
        .limit(400)
        .execute()
    )
    out: Dict[str, Dict[str, Any]] = {}
    for row in (res.data or []):
        image_url = row.get("image_url")
        if not image_url:
            continue
        candidates = [row.get("food_name") or ""]
        for item in (row.get("food_items") or []):
            if isinstance(item, dict) and item.get("name"):
                candidates.append(str(item["name"]))
        for candidate in candidates:
            key = _normalize(candidate)
            if key and key in wanted and key not in out:
                out[key] = {
                    "source": "user_photo",
                    "external_url": image_url,
                    "attribution": "Your photo",
                }
    return out


# --------------------------------------------------------------------------- #
# Free source 2 — the food catalog
# --------------------------------------------------------------------------- #
def _lookup_food_database(wanted: Dict[str, str]) -> Dict[str, Dict[str, Any]]:
    """Match against food_database rows that already carry an image_url."""
    if not wanted:
        return {}
    db = get_supabase_db()
    out: Dict[str, Dict[str, Any]] = {}
    # ILIKE-any over the display names in one query rather than N round trips.
    names = [wanted[k] for k in list(wanted)[:60]]
    try:
        res = (
            db.client.table("food_database")
            .select("name, image_url")
            .in_("name", names)
            .not_.is_("image_url", "null")
            .limit(200)
            .execute()
        )
    except Exception as exc:  # noqa: BLE001
        logger.warning(f"[DishImage] food_database lookup failed: {exc}")
        return {}
    for row in (res.data or []):
        key = _normalize(row.get("name") or "")
        if key in wanted and key not in out and row.get("image_url"):
            out[key] = {
                "source": "food_db",
                "external_url": row["image_url"],
                "attribution": None,
            }
    return out


# --------------------------------------------------------------------------- #
# Free source 3 — free-licence web images
# --------------------------------------------------------------------------- #
async def _wikimedia_lookup(
    client: httpx.AsyncClient, display_name: str
) -> Optional[Dict[str, Any]]:
    """First free-licence Commons photo for a dish, with its credit line.

    Commons is used rather than a general image search because every file
    carries machine-readable licence + author metadata, so the attribution we
    display is accurate rather than guessed.
    """
    params = {
        "action": "query",
        "format": "json",
        "generator": "search",
        "gsrsearch": f"filetype:bitmap {display_name} food",
        "gsrnamespace": "6",
        "gsrlimit": "1",
        "prop": "imageinfo",
        "iiprop": "url|extmetadata",
        "iiurlwidth": "480",
    }
    resp = await client.get(
        "https://commons.wikimedia.org/w/api.php",
        params=params,
        headers={"User-Agent": "Zealova/1.0 (dish thumbnails; support@zealova.com)"},
    )
    resp.raise_for_status()
    pages = ((resp.json().get("query") or {}).get("pages") or {})
    for page in pages.values():
        info = (page.get("imageinfo") or [{}])[0]
        url = info.get("thumburl") or info.get("url")
        if not url:
            continue
        meta = info.get("extmetadata") or {}
        artist = (meta.get("Artist") or {}).get("value") or "Wikimedia Commons"
        licence = (meta.get("LicenseShortName") or {}).get("value") or ""
        # Strip the HTML Commons wraps the author in.
        import re

        artist = re.sub(r"<[^>]+>", "", artist).strip()
        credit = f"{artist}{f' / {licence}' if licence else ''}"
        return {"url": url, "attribution": credit[:160]}
    return None


async def _fetch_and_store_web_image(
    client: httpx.AsyncClient, normalized: str, display_name: str
) -> Optional[Dict[str, Any]]:
    """Look up, download and re-host one dish photo. None if nothing suitable."""
    try:
        hit = await _wikimedia_lookup(client, display_name)
        if not hit:
            return None
        img = await client.get(hit["url"])
        img.raise_for_status()
        data = img.content
        if not data or len(data) > _MAX_IMAGE_BYTES:
            return None
        content_type = img.headers.get("content-type", "image/jpeg").split(";")[0]
        if not content_type.startswith("image/"):
            return None
        ext = content_type.split("/")[-1].replace("jpeg", "jpg")
        s3_key = await asyncio.to_thread(
            get_s3_service().upload_bytes,
            data,
            key_prefix="dish-images/web",
            filename=f"{normalized.replace(' ', '-')[:60]}.{ext}",
            content_type=content_type,
        )
        return {
            "source": "web_cc",
            "s3_key": s3_key,
            "attribution": hit["attribution"],
        }
    except Exception as exc:  # noqa: BLE001 — one dish failing is not a scan failing
        logger.debug(f"[DishImage] web lookup failed for {display_name!r}: {exc}")
        return None


async def _lookup_web(wanted: Dict[str, str]) -> Dict[str, Dict[str, Any]]:
    if not wanted or not web_lookup_enabled():
        return {}
    targets = list(wanted.items())[:_MAX_WEB_LOOKUPS_PER_BATCH]
    if len(wanted) > _MAX_WEB_LOOKUPS_PER_BATCH:
        logger.info(
            f"[DishImage] web lookup capped at {_MAX_WEB_LOOKUPS_PER_BATCH} "
            f"of {len(wanted)} unresolved dishes this batch"
        )
    sem = asyncio.Semaphore(_WEB_CONCURRENCY)
    out: Dict[str, Dict[str, Any]] = {}

    async with httpx.AsyncClient(timeout=_WEB_TIMEOUT_S, follow_redirects=True) as client:
        async def one(normalized: str, display: str) -> None:
            async with sem:
                found = await _fetch_and_store_web_image(client, normalized, display)
                if found:
                    out[normalized] = found

        await asyncio.gather(*[one(k, v) for k, v in targets])
    return out


# --------------------------------------------------------------------------- #
# Paid source — Imagen 4 Fast
# --------------------------------------------------------------------------- #
def _today_utc() -> date:
    return datetime.now(timezone.utc).date()


def _count_today(user_id: str) -> int:
    db = get_supabase_db()
    res = (
        db.client.table("share_ai_usage")
        .select("count")
        .eq("user_id", user_id)
        .eq("day", _today_utc().isoformat())
        .eq("feature", "dish_image")
        .limit(1)
        .execute()
    )
    if res.data:
        return int(res.data[0].get("count") or 0)
    return 0


def _increment_today(user_id: str) -> None:
    """Only real generations consume the cap — cache hits are free."""
    db = get_supabase_db()
    db.client.table("share_ai_usage").upsert(
        {
            "user_id": user_id,
            "day": _today_utc().isoformat(),
            "feature": "dish_image",
            "count": _count_today(user_id) + 1,
            "updated_at": datetime.now(timezone.utc).isoformat(),
        },
        on_conflict="user_id,day,feature",
    ).execute()


def generation_quota(user_id: str) -> Dict[str, Any]:
    """BLOCKING — makes a sync Supabase call. Never call this from a coroutine;
    use `generation_quota_async`."""
    cap = generation_daily_cap()
    used = _count_today(user_id)
    return {
        "used_today": used,
        "daily_cap": cap,
        "remaining": max(0, cap - used),
        "enabled": generation_enabled(),
    }


async def generation_quota_async(user_id: str) -> Dict[str, Any]:
    """`generation_quota` off the event loop.

    `_count_today` is a synchronous supabase-py `.execute()`; awaiting it inline
    from an async endpoint stalls the whole worker for a DB round-trip. That
    matters most on the *failure* path, which the image-model circuit breaker
    makes near-instant — the quota read would otherwise become the slowest thing
    in a menu scan and block every other request eight times over.
    """
    return await asyncio.to_thread(generation_quota, user_id)


def _generation_prompt(display_name: str, restaurant_name: Optional[str]) -> str:
    """Prompt for a plausible restaurant plating of the named dish.

    Deliberately anonymous: no branding, no people, no text. The image is a
    visual cue for a menu row, not a claim about how THAT restaurant plates it.
    """
    venue = f" as served at a {restaurant_name}" if restaurant_name else ""
    return (
        f"A single appetizing serving of {display_name}{venue}, "
        "photographed from a 45-degree angle on a plain neutral plate, "
        "soft natural window light, shallow depth of field, clean uncluttered "
        "background, food-photography styling. "
        "No text, no logos, no branding, no people, no hands, no cutlery clutter."
    )


_LEGACY_LOCATION_WARNED = False


def _warn_if_legacy_location_env() -> None:
    """`DISH_IMAGE_LOCATION` no longer does anything — say so, once.

    It was the whole of commit 09569597's fix, so it may still be set in the
    Render dashboard. The Vertex region is now owned by the chokepoint
    (`IMAGE_GEN_LOCATION`), and an env var that looks configured but is ignored
    is exactly the kind of silent no-op that sent the last debugging round down
    the wrong path.
    """
    global _LEGACY_LOCATION_WARNED
    if _LEGACY_LOCATION_WARNED:
        return
    legacy = os.getenv("DISH_IMAGE_LOCATION")
    if not legacy:
        return
    _LEGACY_LOCATION_WARNED = True
    logger.warning(
        "[DishImage] DISH_IMAGE_LOCATION=%s is set but IGNORED — the Vertex "
        "region is owned by services.image_generation_service "
        "(IMAGE_GEN_LOCATION). Unset it, or move the value there.",
        legacy,
    )


def _generate_image(prompt: str):
    """One image generation through the backend's single chokepoint.

    Model *and* region are owned by `services.image_generation_service` — this
    module must never construct an image client or pick a location, because
    that is exactly how the same 404 shipped twice (global endpoint, then a
    model the project does not have).

    Raises `DishImageUnavailable` for "no picture is possible" and
    `DishImageError` for a genuine server fault, so the endpoint can tell a
    missing thumbnail apart from a broken service.
    """
    from services.image_generation_service import (
        ImageGenerationBlocked,
        ImageGenerationError,
        ImageModelUnavailable,
        generate_image,
    )

    _warn_if_legacy_location_env()
    try:
        return generate_image(
            prompt=prompt,
            purpose="dish_image",
            model=image_model(),
            aspect_ratio="1:1",
        )
    except (ImageModelUnavailable, ImageGenerationBlocked) as exc:
        raise DishImageUnavailable(str(exc)) from exc
    except ImageGenerationError as exc:
        raise DishImageError(str(exc)) from exc


# --------------------------------------------------------------------------- #
# Public API
# --------------------------------------------------------------------------- #
async def resolve_dish_images(
    *,
    user_id: str,
    names: List[str],
    allow_web: bool = True,
) -> Dict[str, Optional[Dict[str, Any]]]:
    """Resolve thumbnails for a batch of dish names using FREE sources only.

    Returns `{original_name: {url, source, attribution, ...} | None}`. A None
    means "no image we can stand behind" — the caller renders a placeholder
    (and may offer the paid generate path), never a stand-in picture of some
    other dish.
    """
    if not images_enabled() or not names:
        return {name: None for name in names}

    # Dedupe by normalized key while keeping every original spelling so the
    # caller can look results up by the exact name it sent.
    keys_by_name: Dict[str, str] = {}
    wanted: Dict[str, str] = {}
    for name in names:
        key = _normalize(name)
        if not key:
            continue
        keys_by_name[name] = key
        wanted.setdefault(key, name.strip())

    resolved: Dict[str, Dict[str, Any]] = {}

    # 0. Cache — the whole point of the design.
    cached = await asyncio.to_thread(_lookup_cache, list(wanted))
    for key, row in cached.items():
        result = _row_to_result(row)
        if result:
            resolved[key] = result
            _touch_cache(key)
    pending = {k: v for k, v in wanted.items() if k not in resolved}

    # 1-2. Free DB sources, run together — neither touches the network.
    if pending:
        user_hits, db_hits = await asyncio.gather(
            asyncio.to_thread(_lookup_user_photos, user_id, pending),
            asyncio.to_thread(_lookup_food_database, pending),
        )
        for key, found in {**db_hits, **user_hits}.items():  # user photo wins
            if key not in pending:
                continue
            await asyncio.to_thread(
                _store_cache,
                normalized_name=key,
                display_name=pending[key],
                source=found["source"],
                s3_key=found.get("s3_key"),
                external_url=found.get("external_url"),
                attribution=found.get("attribution"),
            )
            result = _row_to_result({**found, "normalized_name": key})
            if result:
                resolved[key] = result
        pending = {k: v for k, v in pending.items() if k not in resolved}

    # 3. Free-licence web photos.
    if pending and allow_web:
        web_hits = await _lookup_web(pending)
        for key, found in web_hits.items():
            await asyncio.to_thread(
                _store_cache,
                normalized_name=key,
                display_name=pending[key],
                source=found["source"],
                s3_key=found.get("s3_key"),
                attribution=found.get("attribution"),
            )
            result = _row_to_result({**found, "normalized_name": key})
            if result:
                resolved[key] = result

    logger.info(
        f"[DishImage] resolve user={user_id} asked={len(names)} unique={len(wanted)} "
        f"resolved={len(resolved)} (cache={len(cached)})"
    )
    return {name: resolved.get(key) for name, key in keys_by_name.items()}


async def generate_dish_image(
    *,
    user_id: str,
    name: str,
    restaurant_name: Optional[str] = None,
) -> Dict[str, Any]:
    """Generate (or re-serve) an image for ONE dish. Costs money on a miss.

    Raises DishImageDisabled / DishImageCapReached / DishImageError — never
    returns a placeholder dressed up as a real result.
    """
    if not images_enabled() or not generation_enabled():
        raise DishImageDisabled("Dish image generation is currently disabled.")
    key = _normalize(name)
    if not key:
        raise DishImageError("Dish name is empty.")

    # Cache hit: free, and the daily cap is untouched.
    cached = await asyncio.to_thread(_lookup_cache, [key])
    if key in cached:
        result = _row_to_result(cached[key])
        if result:
            _touch_cache(key)
            return {
                **result,
                "cached": True,
                "available": True,
                "quota": await generation_quota_async(user_id),
            }

    cap = generation_daily_cap()
    used = await asyncio.to_thread(_count_today, user_id)
    if used >= cap:
        raise DishImageCapReached(
            f"Daily dish-image limit reached ({used}/{cap}). Resets at midnight UTC."
        )

    display = name.strip()
    model = image_model()
    logger.info(f"[DishImage] MISS → generating {display!r} model={model}")
    image = await asyncio.to_thread(
        _generate_image, _generation_prompt(display, restaurant_name)
    )
    # Use the mime type the model actually returned — assuming PNG is how a
    # JPEG ends up stored under a .png key and served with the wrong header.
    s3_key = await asyncio.to_thread(
        get_s3_service().upload_bytes,
        image.data,
        key_prefix="dish-images/ai",
        filename=f"{key.replace(' ', '-')[:60]}.{image.extension}",
        content_type=image.mime_type,
    )
    await asyncio.to_thread(
        _store_cache,
        normalized_name=key,
        display_name=display,
        source="ai",
        s3_key=s3_key,
        model=image.model,
    )
    await asyncio.to_thread(_increment_today, user_id)

    return {
        "url": _presign(s3_key),
        "source": "ai",
        "attribution": None,
        "is_ai": True,
        "disclosure": AI_DISCLOSURE,
        "cached": False,
        "available": True,
        "model": image.model,
        "quota": await generation_quota_async(user_id),
    }
