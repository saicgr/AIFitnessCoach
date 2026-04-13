"""
Shared helpers for gym-profile lookups.

These exist because supabase-py's `.single()` raises on 0 rows and
`.maybe_single()` is inconsistent about returning `data=None` vs raising a 204
APIError. Several call sites across workouts/* need the "active gym profile
id" for a user (or None if none exists). Keeping one correct implementation
here avoids the null-safety bugs that historically crashed generation_streaming
with `AttributeError: 'NoneType' object has no attribute 'data'`.
"""
from typing import Optional

from core.logger import get_logger

logger = get_logger(__name__)


def get_active_gym_profile_id(db, user_id: str) -> Optional[str]:
    """Return the user's active gym profile id, or None if no active profile exists.

    Uses `.single()` + try/except so zero-row and SDK-204 cases both collapse to
    a clean `None`. Never raises. Safe to call before any mutation logic.

    Args:
        db: SupabaseDB facade (the `get_supabase_db()` singleton).
        user_id: Internal users.id (NOT auth_id).
    """
    try:
        result = (
            db.client.table("gym_profiles")
            .select("id")
            .eq("user_id", user_id)
            .eq("is_active", True)
            .single()
            .execute()
        )
        if result and result.data:
            return result.data.get("id")
    except Exception as e:
        logger.debug(f"No active gym profile for user {user_id}: {e}")
    return None
