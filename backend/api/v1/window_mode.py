"""
Window Mode API endpoints.

Logs window mode changes for analytics and understanding user behavior
across different display modes (split screen, PiP, freeform, full screen).

This data helps understand:
- How often users use split screen during workouts
- Device usage patterns for UI optimization
- Session duration in different window modes

ENDPOINTS:
- POST /api/v1/window-mode/{user_id}/log - Log a window mode change
- GET  /api/v1/window-mode/{user_id}/stats - Get user's window mode statistics
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field, field_validator
from typing import Optional, Literal
from datetime import datetime
from enum import Enum

from core.supabase_client import get_supabase
from core.logger import get_logger
from core.activity_logger import log_user_activity, log_user_error

router = APIRouter()
logger = get_logger(__name__)


# ============================================
# Enums and Constants
# ============================================

class WindowMode(str, Enum):
    """Valid window modes that can be logged."""
    SPLIT_SCREEN = "split_screen"
    FULL_SCREEN = "full_screen"
    PIP = "pip"
    FREEFORM = "freeform"
    SPLIT_SCREEN_SESSION = "split_screen_session"


VALID_MODES = {"split_screen", "full_screen", "pip", "freeform", "split_screen_session"}


# ============================================
# Pydantic Models
# ============================================

class WindowModeLogRequest(BaseModel):
    """Request model for logging a window mode change."""
    mode: str = Field(
        ...,
        description="The window mode: split_screen, full_screen, pip, freeform, or split_screen_session"
    )
    width: int = Field(
        ...,
        ge=0,
        le=10000,
        description="Window width in logical pixels"
    )
    height: int = Field(
        ...,
        ge=0,
        le=10000,
        description="Window height in logical pixels"
    )
    timestamp: str = Field(
        ...,
        description="ISO8601 timestamp of when the mode change occurred"
    )
    duration_seconds: Optional[int] = Field(
        default=None,
        ge=0,
        description="Duration in seconds (for session logs)"
    )
    device_info: Optional[dict] = Field(
        default=None,
        description="Optional device information (model, OS version, etc.)"
    )

    @field_validator("mode")
    @classmethod
    def validate_mode(cls, v: str) -> str:
        """Validate that mode is one of the allowed values."""
        if v not in VALID_MODES:
            raise ValueError(f"Invalid mode: {v}. Must be one of: {', '.join(VALID_MODES)}")
        return v

    @field_validator("timestamp")
    @classmethod
    def validate_timestamp(cls, v: str) -> str:
        """Validate that timestamp is a valid ISO8601 format."""
        try:
            datetime.fromisoformat(v.replace('Z', '+00:00'))
        except ValueError as e:
            raise ValueError(f"Invalid timestamp format. Expected ISO8601: {e}")
        return v


class WindowModeLogResponse(BaseModel):
    """Response model for window mode log."""
    id: str
    user_id: str
    mode: str
    window_width: int
    window_height: int
    logged_at: str
    success: bool = True


class WindowModeStatsResponse(BaseModel):
    """Response model for window mode statistics."""
    user_id: str
    total_logs: int
    mode_counts: dict
    split_screen_total_seconds: int
    avg_split_screen_session_seconds: float
    most_common_mode: Optional[str]
    last_mode_change: Optional[str]


# ============================================
# API Endpoints
# ============================================

@router.post("/{user_id}/log", response_model=WindowModeLogResponse)
async def log_window_mode(user_id: str, request: WindowModeLogRequest):
    """
    Log a window mode change.

    This endpoint records when a user's app window mode changes,
    such as entering split screen mode during a workout.

    This data is used for:
    - Understanding device usage patterns
    - Optimizing UI for common window configurations
    - Tracking split screen workout sessions
    """
    logger.info(f"Logging window mode for user {user_id}: {request.mode} ({request.width}x{request.height})")

    try:
        supabase = get_supabase()
        now = datetime.utcnow().isoformat()

        # Parse the incoming timestamp
        try:
            logged_at = datetime.fromisoformat(request.timestamp.replace('Z', '+00:00')).isoformat()
        except ValueError:
            logged_at = now

        # Prepare the log entry
        log_entry = {
            "user_id": user_id,
            "mode": request.mode,
            "window_width": request.width,
            "window_height": request.height,
            "device_info": request.device_info,
            "logged_at": logged_at,
        }

        # Add duration for session logs
        if request.duration_seconds is not None:
            log_entry["duration_seconds"] = request.duration_seconds

        # Insert the log entry
        result = supabase.client.table("window_mode_logs").insert(log_entry).execute()

        if not result.data or len(result.data) == 0:
            raise HTTPException(status_code=500, detail="Failed to insert window mode log")

        log_data = result.data[0]
        logger.info(f"Successfully logged window mode for user {user_id}: {request.mode}")

        # Log to user activity for analytics
        if request.mode == "split_screen":
            await log_user_activity(
                user_id=user_id,
                action="window_mode_split_screen",
                endpoint=f"/api/v1/window-mode/{user_id}/log",
                message=f"Entered split screen mode ({request.width}x{request.height})",
                metadata={
                    "mode": request.mode,
                    "width": request.width,
                    "height": request.height,
                },
                status_code=200
            )
        elif request.mode == "split_screen_session" and request.duration_seconds:
            await log_user_activity(
                user_id=user_id,
                action="window_mode_split_screen_session",
                endpoint=f"/api/v1/window-mode/{user_id}/log",
                message=f"Split screen session: {request.duration_seconds}s",
                metadata={
                    "duration_seconds": request.duration_seconds,
                    "width": request.width,
                    "height": request.height,
                },
                status_code=200
            )

        return WindowModeLogResponse(
            id=log_data["id"],
            user_id=log_data["user_id"],
            mode=log_data["mode"],
            window_width=log_data["window_width"],
            window_height=log_data["window_height"],
            logged_at=log_data["logged_at"],
            success=True,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to log window mode for user {user_id}: {e}")
        await log_user_error(
            user_id=user_id,
            action="window_mode_log",
            error=e,
            endpoint=f"/api/v1/window-mode/{user_id}/log",
            status_code=500
        )
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}/stats", response_model=WindowModeStatsResponse)
async def get_window_mode_stats(user_id: str):
    """
    Get window mode statistics for a user.

    Returns aggregated statistics about window mode usage:
    - Total number of mode changes logged
    - Count per mode type
    - Total and average split screen session duration
    - Most commonly used mode
    """
    logger.info(f"Getting window mode stats for user {user_id}")

    try:
        supabase = get_supabase()

        # Get all logs for user
        result = supabase.client.table("window_mode_logs").select(
            "mode, window_width, window_height, duration_seconds, logged_at"
        ).eq("user_id", user_id).order("logged_at", desc=True).execute()

        logs = result.data if result.data else []

        if not logs:
            return WindowModeStatsResponse(
                user_id=user_id,
                total_logs=0,
                mode_counts={},
                split_screen_total_seconds=0,
                avg_split_screen_session_seconds=0.0,
                most_common_mode=None,
                last_mode_change=None,
            )

        # Calculate statistics
        mode_counts = {}
        split_screen_sessions = []
        last_mode_change = logs[0]["logged_at"] if logs else None

        for log in logs:
            mode = log["mode"]
            mode_counts[mode] = mode_counts.get(mode, 0) + 1

            # Track split screen session durations
            if mode == "split_screen_session" and log.get("duration_seconds"):
                split_screen_sessions.append(log["duration_seconds"])

        # Calculate split screen statistics
        total_split_seconds = sum(split_screen_sessions)
        avg_split_seconds = (
            total_split_seconds / len(split_screen_sessions)
            if split_screen_sessions else 0.0
        )

        # Find most common mode (excluding session logs)
        regular_modes = {k: v for k, v in mode_counts.items() if k != "split_screen_session"}
        most_common_mode = max(regular_modes, key=regular_modes.get) if regular_modes else None

        return WindowModeStatsResponse(
            user_id=user_id,
            total_logs=len(logs),
            mode_counts=mode_counts,
            split_screen_total_seconds=total_split_seconds,
            avg_split_screen_session_seconds=round(avg_split_seconds, 1),
            most_common_mode=most_common_mode,
            last_mode_change=last_mode_change,
        )

    except Exception as e:
        logger.error(f"Failed to get window mode stats for user {user_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))
