"""
Consent enforcement for AI processing.

Checks the user's `user_ai_settings.ai_data_processing_enabled` and
`save_chat_history` flags before the backend forwards any user content
to Google Gemini or stores chat transcripts.

Why this module exists: prior to 2026-04 these toggles existed in the app
but were never honored server-side (placebo controls — GDPR Art. 7(4)
dark-pattern risk). Every outbound Gemini call or chat_history write must
route through these helpers so the toggles are real.
"""
from __future__ import annotations

from typing import Dict, Optional, Tuple

from fastapi import HTTPException

from core.logger import get_logger
from core.supabase_client import get_supabase

logger = get_logger(__name__)


# In-memory cache is intentionally avoided: settings flip rarely but when
# they flip we must honor the new value on the very next request. The
# lookup is a single indexed query on user_ai_settings.


def load_consent_flags(user_id: str) -> Dict[str, Optional[bool]]:
    """Return the user's current consent flags.

    Returns a dict with ai_data_processing_enabled and save_chat_history.
    Missing rows (user hasn't customized settings) default to
    ai_data_processing_enabled=TRUE (because they tapped through onboarding
    consent) and save_chat_history=TRUE.
    """
    try:
        supabase = get_supabase().client
        result = (
            supabase.table("user_ai_settings")
            .select("ai_data_processing_enabled,save_chat_history,health_data_consent")
            .eq("user_id", user_id)
            .limit(1)
            .execute()
        )
        if result.data:
            row = result.data[0]
            return {
                "ai_data_processing_enabled": row.get("ai_data_processing_enabled", True),
                "save_chat_history": row.get("save_chat_history", True),
                "health_data_consent": row.get("health_data_consent", False),
            }
    except Exception as e:
        # Fail closed on DB errors for AI processing — we cannot prove
        # consent, so we must not process. Logging is critical so an
        # ops incident that knocks Supabase offline doesn't silently
        # start violating consent.
        logger.error(f"consent_guard: failed to read consent flags for {user_id}: {e}", exc_info=True)
        return {
            "ai_data_processing_enabled": False,
            "save_chat_history": False,
            "health_data_consent": False,
        }

    # No row yet: user has never customized settings. Default to the
    # onboarding-accepted state (AI on, chat save on, health off).
    return {
        "ai_data_processing_enabled": True,
        "save_chat_history": True,
        "health_data_consent": False,
    }


def require_ai_processing_consent(user_id: str) -> Dict[str, Optional[bool]]:
    """Raise 403 if the user has disabled AI data processing.

    Returns the full consent flag dict on success so callers can also
    branch on save_chat_history without a second DB round-trip.
    """
    flags = load_consent_flags(user_id)
    if not flags.get("ai_data_processing_enabled", True):
        # 451 "Unavailable For Legal Reasons" would be semantically closer,
        # but 403 is standard for consent-based refusals and plays better
        # with existing client error handlers.
        raise HTTPException(
            status_code=403,
            detail=(
                "AI processing is disabled for this account. "
                "Re-enable it in Settings → Privacy & AI Data to continue."
            ),
        )
    return flags


def should_save_chat_history(flags_or_user_id) -> bool:
    """Convenience wrapper for chat persistence background tasks.

    Accepts either a user_id string (performs a lookup) or a pre-loaded
    flags dict from `require_ai_processing_consent`/`load_consent_flags`.
    """
    if isinstance(flags_or_user_id, dict):
        return bool(flags_or_user_id.get("save_chat_history", True))
    flags = load_consent_flags(str(flags_or_user_id))
    return bool(flags.get("save_chat_history", True))


def has_health_data_consent(user_id: str) -> bool:
    """Return True only if the user has explicitly consented to Art. 9
    health data processing. Used to gate Health Connect / HealthKit sync
    writes into user_metrics, hormonal_health, sleep, etc.
    """
    return bool(load_consent_flags(user_id).get("health_data_consent", False))
