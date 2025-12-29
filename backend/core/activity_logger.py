"""
User Activity Logger - Persists user activity to the database for debugging.

This is separate from the console logger and stores activity in the database
for querying when debugging specific user issues.

Usage:
    from core.activity_logger import log_user_activity, log_user_error

    # Log a successful action
    await log_user_activity(
        user_id="abc123",
        action="workout_generation",
        endpoint="/api/v1/workouts/generate",
        message="Generated 4 workouts",
        metadata={"workout_count": 4},
        duration_ms=1500,
        status_code=200
    )

    # Log an error
    await log_user_error(
        user_id="abc123",
        action="chat",
        endpoint="/api/v1/chat/send",
        error=e,
        metadata={"message": "User's message"}
    )

Querying:
    SELECT * FROM user_activity_log WHERE user_id = 'abc123' ORDER BY created_at DESC;
    SELECT * FROM recent_errors;  -- Last 24 hours of errors
    SELECT * FROM user_activity_summary;  -- Per-user summary
"""
from typing import Optional, Dict, Any
from datetime import datetime
import traceback

from core.logger import get_logger, get_log_context
from core.supabase_db import get_supabase_db

logger = get_logger(__name__)


async def log_user_activity(
    user_id: str,
    action: str,
    endpoint: Optional[str] = None,
    message: Optional[str] = None,
    metadata: Optional[Dict[str, Any]] = None,
    duration_ms: Optional[int] = None,
    status_code: Optional[int] = None,
    level: str = "INFO"
) -> None:
    """
    Log user activity to the database.

    Args:
        user_id: The user's ID
        action: High-level action category (e.g., 'workout_generation', 'chat', 'onboarding')
        endpoint: API endpoint path
        message: Human-readable description
        metadata: Additional context as dict
        duration_ms: Request duration in milliseconds
        status_code: HTTP status code
        level: Log level (INFO, WARNING, ERROR)
    """
    try:
        db = get_supabase_db()
        client = db.client

        # Get request_id from logging context if available
        ctx = get_log_context()
        request_id = ctx.get("request_id")

        # Insert activity log
        client.table("user_activity_log").insert({
            "user_id": user_id,
            "request_id": request_id,
            "level": level,
            "action": action,
            "endpoint": endpoint,
            "message": message,
            "metadata": metadata or {},
            "duration_ms": duration_ms,
            "status_code": status_code,
        }).execute()

    except Exception as e:
        # Don't fail the request if logging fails
        logger.warning(f"Failed to log user activity: {e}")


async def log_user_error(
    user_id: str,
    action: str,
    error: Exception,
    endpoint: Optional[str] = None,
    metadata: Optional[Dict[str, Any]] = None,
    duration_ms: Optional[int] = None,
    status_code: Optional[int] = 500
) -> None:
    """
    Log an error for a user to the database.

    Args:
        user_id: The user's ID
        action: High-level action category
        error: The exception that occurred
        endpoint: API endpoint path
        metadata: Additional context as dict
        duration_ms: Request duration in milliseconds
        status_code: HTTP status code (defaults to 500)
    """
    try:
        db = get_supabase_db()
        client = db.client

        # Get request_id from logging context if available
        ctx = get_log_context()
        request_id = ctx.get("request_id")

        # Get error details
        error_type = type(error).__name__
        error_message = str(error)

        # Add stack trace to metadata
        meta = metadata.copy() if metadata else {}
        meta["stack_trace"] = traceback.format_exc()

        # Insert error log
        client.table("user_activity_log").insert({
            "user_id": user_id,
            "request_id": request_id,
            "level": "ERROR",
            "action": action,
            "endpoint": endpoint,
            "message": f"{error_type}: {error_message}",
            "metadata": meta,
            "duration_ms": duration_ms,
            "status_code": status_code,
            "error_type": error_type,
            "error_message": error_message,
        }).execute()

    except Exception as e:
        # Don't fail the request if logging fails
        logger.warning(f"Failed to log user error: {e}")


async def get_user_activity(
    user_id: str,
    limit: int = 50,
    level: Optional[str] = None
) -> list:
    """
    Get recent activity for a user.

    Args:
        user_id: The user's ID
        limit: Max number of records to return
        level: Filter by log level (INFO, WARNING, ERROR)

    Returns:
        List of activity records
    """
    try:
        db = get_supabase_db()
        client = db.client

        query = client.table("user_activity_log").select("*").eq("user_id", user_id)

        if level:
            query = query.eq("level", level)

        query = query.order("created_at", desc=True).limit(limit)
        result = query.execute()

        return result.data or []

    except Exception as e:
        logger.error(f"Failed to get user activity: {e}")
        return []


async def get_user_errors(user_id: str, limit: int = 20) -> list:
    """
    Get recent errors for a user.

    Args:
        user_id: The user's ID
        limit: Max number of records to return

    Returns:
        List of error records
    """
    return await get_user_activity(user_id, limit=limit, level="ERROR")
