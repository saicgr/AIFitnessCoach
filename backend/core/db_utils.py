"""
Database utility helpers for Supabase SDK workarounds.
"""
import logging
from types import SimpleNamespace

logger = logging.getLogger(__name__)


def safe_maybe_single(query):
    """
    Execute a query with .maybe_single().execute(), catching the Supabase SDK
    bug where a 204 No Content response raises an APIError instead of returning
    None.

    Usage:
        result = safe_maybe_single(
            db.client.table("users").select("*").eq("id", user_id).maybe_single()
        )
        if result.data:
            ...

    Returns:
        A response object with .data = None on 204, or the normal response.
    """
    try:
        return query.execute()
    except Exception as e:
        # Supabase SDK raises APIError({'code': '204'}) when no rows found
        error_str = str(e)
        if "204" in error_str:
            logger.debug(f"[db_utils] Caught 204 from maybe_single(), returning None")
            return SimpleNamespace(data=None)
        raise
