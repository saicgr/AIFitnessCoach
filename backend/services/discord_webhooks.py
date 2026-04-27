"""
Discord webhook notifications for Zealova.

Channels:
  #growth  — new user signups + subscription events
  #reviews — Play Store reviews (called from cron)
  #alerts  — backend errors / crashes
"""

import logging
import traceback
from datetime import datetime, timezone
from typing import Optional

import httpx

from core.config import get_settings

logger = logging.getLogger(__name__)

# Reusable async client (connection pooling)
_client: Optional[httpx.AsyncClient] = None


def _get_client() -> httpx.AsyncClient:
    global _client
    if _client is None or _client.is_closed:
        _client = httpx.AsyncClient(timeout=10.0)
    return _client


async def _post_webhook(url: Optional[str], payload: dict) -> bool:
    """Send a payload to a Discord webhook URL. Returns True on success."""
    if not url:
        return False
    try:
        resp = await _get_client().post(url, json=payload)
        if resp.status_code == 204:
            return True
        logger.warning(f"Discord webhook returned {resp.status_code}: {resp.text[:200]}")
        return False
    except Exception as e:
        # Discord notifications are best-effort telemetry — log at WARNING (not ERROR) so
        # outbound network blips don't trip alerts. Include exception type + repr so an
        # empty str(e) (common for timeouts / connection resets) still leaves a clue.
        logger.warning(
            f"Discord webhook failed: type={type(e).__name__} repr={e!r}",
            exc_info=True,
        )
        return False


# ── #growth: New user signups ────────────────────────────────────

async def notify_signup(
    email: str,
    user_id: str,
    name: Optional[str] = None,
    provider: str = "email",
) -> bool:
    """Post a new signup notification to #growth."""
    settings = get_settings()
    now = datetime.now(timezone.utc).strftime("%b %d, %Y %H:%M UTC")

    display = name or email.split("@")[0]
    payload = {
        "username": "Signup Tracker",
        "avatar_url": "https://cdn.jsdelivr.net/gh/twitter/twemoji@latest/assets/72x72/1f4c8.png",
        "embeds": [{
            "title": "New User Signup",
            "color": 0x10B981,  # emerald-500
            "fields": [
                {"name": "User", "value": display, "inline": True},
                {"name": "Email", "value": email, "inline": True},
                {"name": "Provider", "value": provider, "inline": True},
                {"name": "ID", "value": f"`{user_id[:12]}...`", "inline": True},
            ],
            "footer": {"text": now},
        }],
    }
    return await _post_webhook(settings.discord_growth_webhook, payload)


# ── #growth: Subscription events ────────────────────────────────

async def notify_subscription(
    email: str,
    user_id: str,
    plan: str,
    price: float,
    currency: str = "USD",
    is_trial: bool = False,
    store: str = "",
    name: Optional[str] = None,
) -> bool:
    """Post a new subscription notification to #growth."""
    settings = get_settings()
    now = datetime.now(timezone.utc).strftime("%b %d, %Y %H:%M UTC")
    display = name or email.split("@")[0]

    status_text = "Free Trial Started" if is_trial else "New Subscription"
    color = 0xF59E0B if is_trial else 0x10B981  # amber for trial, green for paid

    price_display = "Trial" if is_trial and price == 0 else f"${price:.2f} {currency}"

    payload = {
        "username": "Revenue Tracker",
        "avatar_url": "https://cdn.jsdelivr.net/gh/twitter/twemoji@latest/assets/72x72/1f4b0.png",
        "embeds": [{
            "title": status_text,
            "color": color,
            "fields": [
                {"name": "User", "value": display, "inline": True},
                {"name": "Email", "value": email, "inline": True},
                {"name": "Plan", "value": plan, "inline": True},
                {"name": "Price", "value": price_display, "inline": True},
                {"name": "Store", "value": store or "Unknown", "inline": True},
                {"name": "ID", "value": f"`{user_id[:12]}...`", "inline": True},
            ],
            "footer": {"text": now},
        }],
    }
    return await _post_webhook(settings.discord_growth_webhook, payload)


# ── #reviews: Play Store reviews ─────────────────────────────────

async def notify_review(
    author: str,
    rating: int,
    text: str,
    review_id: Optional[str] = None,
) -> bool:
    """Post a Play Store review to #reviews."""
    settings = get_settings()
    stars = "+" * rating + "-" * (5 - rating)
    color = 0x10B981 if rating >= 4 else (0xF59E0B if rating == 3 else 0xEF4444)

    payload = {
        "username": "Review Bot",
        "avatar_url": "https://cdn.jsdelivr.net/gh/twitter/twemoji@latest/assets/72x72/2b50.png",
        "embeds": [{
            "title": f"{'+'*rating} {rating}/5 Stars",
            "description": text[:2000] if text else "_No comment_",
            "color": color,
            "fields": [
                {"name": "Author", "value": author, "inline": True},
            ],
            "footer": {"text": review_id or "Google Play Review"},
        }],
    }
    return await _post_webhook(settings.discord_reviews_webhook, payload)


# ── #alerts: Backend errors ──────────────────────────────────────

async def notify_error(
    error: Exception,
    context: str = "",
    endpoint: Optional[str] = None,
    user_id: Optional[str] = None,
) -> bool:
    """Post a backend error to #alerts."""
    settings = get_settings()
    now = datetime.now(timezone.utc).strftime("%b %d, %H:%M UTC")
    tb = "".join(traceback.format_exception(type(error), error, error.__traceback__))
    # Truncate traceback for Discord's 4096 char limit
    tb_short = tb[-1500:] if len(tb) > 1500 else tb

    fields = [
        {"name": "Error", "value": f"`{type(error).__name__}: {str(error)[:200]}`", "inline": False},
    ]
    if endpoint:
        fields.append({"name": "Endpoint", "value": f"`{endpoint}`", "inline": True})
    if user_id:
        fields.append({"name": "User", "value": f"`{user_id[:12]}...`", "inline": True})
    if context:
        fields.append({"name": "Context", "value": context[:200], "inline": False})

    payload = {
        "username": "Error Monitor",
        "avatar_url": "https://cdn.jsdelivr.net/gh/twitter/twemoji@latest/assets/72x72/1f6a8.png",
        "embeds": [{
            "title": "Backend Error",
            "description": f"```python\n{tb_short}\n```",
            "color": 0xEF4444,  # red-500
            "fields": fields,
            "footer": {"text": now},
        }],
    }
    return await _post_webhook(settings.discord_alerts_webhook, payload)
