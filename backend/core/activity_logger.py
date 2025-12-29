"""
User Activity Logger - Persists user activity to the database for debugging.

This is separate from the console logger and stores activity in the database
for querying when debugging specific user issues.

Features:
- Logs activity to database for per-user debugging
- Sends webhook alerts for errors (Discord/Slack compatible)
- Tracks error rate for alerting

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

    # Log an error (automatically sends webhook alert)
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

Environment Variables:
    ERROR_WEBHOOK_URL: Discord/Slack webhook URL for error alerts
    ERROR_ALERT_THRESHOLD: Number of errors before alerting (default: 1)
"""
from typing import Optional, Dict, Any
from datetime import datetime
import traceback
import os
import asyncio
import httpx

from core.logger import get_logger, get_log_context
from core.supabase_db import get_supabase_db

logger = get_logger(__name__)

# Webhook URL for error alerts (Discord or Slack compatible)
ERROR_WEBHOOK_URL = os.getenv("ERROR_WEBHOOK_URL")

# Track recent errors to avoid spam (in-memory, resets on restart)
_recent_errors: list = []
_MAX_RECENT_ERRORS = 100


async def _send_error_alert(
    user_id: str,
    action: str,
    error_type: str,
    error_message: str,
    endpoint: Optional[str] = None,
    request_id: Optional[str] = None
) -> None:
    """
    Send error alert to webhook (Discord/Slack compatible).
    Runs in background, doesn't block the request.
    """
    if not ERROR_WEBHOOK_URL:
        return

    try:
        # Format message for Discord/Slack
        message = {
            "content": None,
            "embeds": [{
                "title": f"🚨 Error: {error_type}",
                "description": error_message[:500],  # Limit length
                "color": 15158332,  # Red color
                "fields": [
                    {"name": "User ID", "value": user_id[:50], "inline": True},
                    {"name": "Action", "value": action, "inline": True},
                    {"name": "Endpoint", "value": endpoint or "N/A", "inline": True},
                    {"name": "Request ID", "value": request_id or "N/A", "inline": True},
                ],
                "timestamp": datetime.utcnow().isoformat() + "Z"
            }]
        }

        async with httpx.AsyncClient(timeout=5.0) as client:
            await client.post(ERROR_WEBHOOK_URL, json=message)

    except Exception as e:
        logger.warning(f"Failed to send error alert: {e}")


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
    status_code: Optional[int] = 500,
    send_alert: bool = True
) -> None:
    """
    Log an error for a user to the database and optionally send webhook alert.

    Args:
        user_id: The user's ID
        action: High-level action category
        error: The exception that occurred
        endpoint: API endpoint path
        metadata: Additional context as dict
        duration_ms: Request duration in milliseconds
        status_code: HTTP status code (defaults to 500)
        send_alert: Whether to send webhook alert (default: True)
    """
    # Get error details
    error_type = type(error).__name__
    error_message = str(error)

    # Get request_id from logging context if available
    ctx = get_log_context()
    request_id = ctx.get("request_id")

    try:
        db = get_supabase_db()
        client = db.client

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

    # Send webhook alert (in background, don't block)
    if send_alert:
        asyncio.create_task(
            _send_error_alert(
                user_id=user_id,
                action=action,
                error_type=error_type,
                error_message=error_message,
                endpoint=endpoint,
                request_id=request_id
            )
        )


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
