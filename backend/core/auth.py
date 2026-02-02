"""
Authentication utilities for API endpoints.

Provides dependency injection for getting the current user from Supabase JWT tokens.
"""
from fastapi import Header, HTTPException, status
from typing import Optional
import logging

from core.supabase_client import get_supabase

logger = logging.getLogger(__name__)


async def get_current_user(
    authorization: Optional[str] = Header(None, alias="Authorization")
) -> dict:
    """
    Dependency to get the current authenticated user from Supabase JWT.

    Args:
        authorization: The Authorization header containing the Bearer token

    Returns:
        dict: User info with 'id' field from Supabase auth

    Raises:
        HTTPException: If no valid auth token is provided
    """
    if not authorization:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authorization header required",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Extract token from "Bearer <token>" format
    parts = authorization.split()
    if len(parts) != 2 or parts[0].lower() != "bearer":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authorization header format. Use 'Bearer <token>'",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = parts[1]

    try:
        # Verify token with Supabase
        supabase = get_supabase()
        user_response = supabase.client.auth.get_user(token)

        if not user_response or not user_response.user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or expired token",
                headers={"WWW-Authenticate": "Bearer"},
            )

        # Look up backend user ID using Supabase Auth ID
        # The database uses backend user ID (users.id) for foreign keys,
        # not Supabase Auth ID (users.auth_id)
        supabase_auth_id = str(user_response.user.id)
        result = supabase.client.table("users").select("id, email").eq("auth_id", supabase_auth_id).single().execute()

        if not result.data:
            logger.error(f"User not found in database for auth_id: {supabase_auth_id}")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found in database",
            )

        return {
            "id": result.data["id"],  # Backend user ID for foreign keys
            "email": result.data["email"],
            "auth_id": supabase_auth_id,  # Supabase Auth ID if needed
            "user_metadata": user_response.user.user_metadata,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Auth error: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Failed to validate token",
            headers={"WWW-Authenticate": "Bearer"},
        )


async def get_optional_user(
    authorization: Optional[str] = Header(None, alias="Authorization")
) -> Optional[dict]:
    """
    Dependency to optionally get the current authenticated user.

    Returns None if no auth header is provided instead of raising an exception.
    Useful for endpoints that work for both authenticated and unauthenticated users.

    Args:
        authorization: The Authorization header containing the Bearer token

    Returns:
        Optional[dict]: User info with 'id' field, or None if not authenticated
    """
    if not authorization:
        return None

    try:
        return await get_current_user(authorization)
    except HTTPException:
        return None
