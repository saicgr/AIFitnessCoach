"""
Content catalogs API — daily lessons, knowledge cards, meditations,
sleep stories, premium previews.

Endpoints:
- GET /api/v1/discover/daily-lesson           — today's long-form lesson
- GET /api/v1/discover/knowledge-cards        — rotating 3-card slate
- GET /api/v1/meditation/today                — today's meditation pick
- GET /api/v1/sleep-stories/today             — today's sleep story
- GET /api/v1/home/premium-preview-rotation   — weekday-rotated paywall preview
                                                 (suppressed for premium users)

All rotations are deterministic — same user on the same calendar day sees the
same pick. Sources are author-curated tables seeded via migrations
2201..2204. No LLM, no mocks.
"""
from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, HTTPException, Depends

from core.db import get_supabase_db
from core.logger import get_logger
from core.auth import get_current_user
from core.exceptions import safe_internal_error

router = APIRouter()
logger = get_logger(__name__)


# Tier set considered "premium" for paywall-preview suppression.
_PREMIUM_TIERS = ("premium", "premium_plus", "lifetime")


def _doy_utc() -> int:
    """Server-side day-of-year (UTC). Stable per calendar day."""
    return datetime.now(timezone.utc).timetuple().tm_yday


def _weekday_utc() -> int:
    """0 = Monday .. 6 = Sunday in UTC."""
    return datetime.now(timezone.utc).weekday()


# ---------------------------------------------------------------------------
# Daily lessons
# ---------------------------------------------------------------------------

@router.get("/discover/daily-lesson")
async def get_daily_lesson(
    current_user: dict = Depends(get_current_user),
):
    """Return today's lesson, rotating deterministically by UTC day-of-year."""
    try:
        db = get_supabase_db()
        # Fetch the catalog ordered by slug so the rotation index is stable.
        rows = (
            db.client.table("daily_lessons")
            .select("id, slug, title, body, read_min, category, published_at")
            .order("slug")
            .execute()
        )
        catalog = rows.data or []
        if not catalog:
            raise HTTPException(status_code=503, detail="No lessons available")
        pick = catalog[_doy_utc() % len(catalog)]
        return {
            "id": pick["id"],
            "slug": pick["slug"],
            "title": pick["title"],
            "body": pick["body"],
            "read_min": pick["read_min"],
            "category": pick["category"],
            "published_at": pick.get("published_at"),
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"daily-lesson failed: {e}")
        safe_internal_error("Failed to load daily lesson")


@router.get("/discover/knowledge-cards")
async def get_knowledge_cards(
    current_user: dict = Depends(get_current_user),
):
    """
    Return three lessons for the "Learn" carousel. Deterministic rotation by
    DOY — picks indexes (DOY % n, (DOY+1) % n, (DOY+2) % n) so each card is
    distinct and the slate shifts day-to-day.
    """
    try:
        db = get_supabase_db()
        rows = (
            db.client.table("daily_lessons")
            .select("id, slug, title, body, read_min, category")
            .order("slug")
            .execute()
        )
        catalog = rows.data or []
        if not catalog:
            raise HTTPException(status_code=503, detail="No lessons available")
        n = len(catalog)
        doy = _doy_utc()
        picks = [catalog[(doy + i) % n] for i in range(min(3, n))]
        return {
            "cards": [
                {
                    "id": p["id"],
                    "slug": p["slug"],
                    "title": p["title"],
                    "tagline": _tagline_from_body(p["body"]),
                    "category": p["category"],
                    "read_min": p["read_min"],
                }
                for p in picks
            ]
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"knowledge-cards failed: {e}")
        safe_internal_error("Failed to load knowledge cards")


def _tagline_from_body(body: str, max_len: int = 110) -> str:
    """First sentence (or first `max_len` chars) of the body for the carousel."""
    if not body:
        return ""
    # First period that ends a sentence (not after "0.7" etc.) — keep simple:
    # split on ". " (period + space) so decimals don't break.
    first = body.split(". ", 1)[0].strip()
    if len(first) > max_len:
        return first[: max_len - 1].rstrip() + "…"
    # Ensure trailing period
    if not first.endswith((".", "!", "?")):
        first += "."
    return first


# ---------------------------------------------------------------------------
# Meditations
# ---------------------------------------------------------------------------

@router.get("/meditation/today")
async def get_meditation_today(
    current_user: dict = Depends(get_current_user),
):
    """Today's meditation pick — rotation by DOY."""
    try:
        db = get_supabase_db()
        rows = (
            db.client.table("meditations")
            .select("id, slug, title, description, duration_min, audio_url")
            .order("slug")
            .execute()
        )
        catalog = rows.data or []
        if not catalog:
            raise HTTPException(status_code=503, detail="No meditations available")
        pick = catalog[_doy_utc() % len(catalog)]
        return {
            "id": pick["id"],
            "slug": pick["slug"],
            "title": pick["title"],
            "description": pick["description"],
            "duration_min": pick["duration_min"],
            "audio_url": pick["audio_url"],
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"meditation/today failed: {e}")
        safe_internal_error("Failed to load meditation")


# ---------------------------------------------------------------------------
# Sleep stories
# ---------------------------------------------------------------------------

@router.get("/sleep-stories/today")
async def get_sleep_story_today(
    current_user: dict = Depends(get_current_user),
):
    """Today's sleep story — rotation by DOY."""
    try:
        db = get_supabase_db()
        rows = (
            db.client.table("sleep_stories")
            .select("id, slug, title, description, duration_min, audio_url")
            .order("slug")
            .execute()
        )
        catalog = rows.data or []
        if not catalog:
            raise HTTPException(status_code=503, detail="No sleep stories available")
        pick = catalog[_doy_utc() % len(catalog)]
        return {
            "id": pick["id"],
            "slug": pick["slug"],
            "title": pick["title"],
            "description": pick["description"],
            "duration_min": pick["duration_min"],
            "audio_url": pick["audio_url"],
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"sleep-stories/today failed: {e}")
        safe_internal_error("Failed to load sleep story")


# ---------------------------------------------------------------------------
# Premium preview rotation (tier-gated)
# ---------------------------------------------------------------------------

def _user_tier(user_id: str) -> str:
    """
    Returns the user's subscription tier ('free' if no row exists).
    Caller treats anything in `_PREMIUM_TIERS` as "do not show paywall preview".
    """
    try:
        db = get_supabase_db()
        sub = (
            db.client.table("subscriptions")
            .select("tier, status")
            .eq("user_id", user_id)
            .maybe_single()
            .execute()
        )
        if not sub or not sub.data:
            return "free"
        return sub.data.get("tier") or "free"
    except Exception as e:
        # If the lookup fails, default to free so the tile still shows rather
        # than silently disappearing (and so we don't accidentally expose a
        # preview to a paying user — free tier always sees previews).
        logger.warning(f"_user_tier lookup failed for {user_id}: {e}")
        return "free"


@router.get("/home/premium-preview-rotation")
async def get_premium_preview_rotation(
    current_user: dict = Depends(get_current_user),
):
    """
    Returns one paywall preview entry, rotated by UTC weekday. For users
    already on a paid tier the endpoint returns `{"entry": null}` so the
    client can hide the tile.
    """
    try:
        user_id = current_user.get("id")
        tier = _user_tier(str(user_id)) if user_id else "free"
        if tier in _PREMIUM_TIERS:
            return {"entry": None, "tier": tier}

        db = get_supabase_db()
        rows = (
            db.client.table("premium_previews")
            .select("id, slug, title, preview_body, locked_feature_key, route")
            .order("slug")
            .execute()
        )
        catalog = rows.data or []
        if not catalog:
            return {"entry": None, "tier": tier}

        pick = catalog[_weekday_utc() % len(catalog)]
        return {
            "entry": {
                "id": pick["id"],
                "slug": pick["slug"],
                "title": pick["title"],
                "preview_body": pick["preview_body"],
                "locked_feature_key": pick["locked_feature_key"],
                "route": pick["route"],
            },
            "tier": tier,
        }
    except Exception as e:
        logger.error(f"premium-preview-rotation failed: {e}")
        safe_internal_error("Failed to load premium preview")
