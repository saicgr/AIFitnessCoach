"""
Authentication utilities for API endpoints.

Provides dependency injection for getting the current user from Supabase JWT tokens.

Two dependency levels:
- get_current_user: Full auth - validates JWT AND requires user row in DB.
  Use for all standard endpoints.
- get_verified_auth_token: Light auth - validates JWT only, no DB lookup.
  Use for auth endpoints (google, email, signup) that handle user creation themselves.
"""
from fastapi import Header, HTTPException, status
from typing import Optional
import logging

from core.supabase_client import get_supabase

logger = logging.getLogger(__name__)


def _extract_bearer_token(authorization: Optional[str]) -> str:
    """
    Extract and return the bearer token from an Authorization header.

    Args:
        authorization: The raw Authorization header value

    Returns:
        The extracted token string

    Raises:
        HTTPException 401: If header is missing or malformed
    """
    if not authorization:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authorization header required",
            headers={"WWW-Authenticate": "Bearer"},
        )

    parts = authorization.split()
    if len(parts) != 2 or parts[0].lower() != "bearer":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authorization header format. Use 'Bearer <token>'",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return parts[1]


async def get_verified_auth_token(
    authorization: Optional[str] = Header(None, alias="Authorization")
) -> dict:
    """
    Light dependency that validates the Supabase JWT but does NOT require
    a row in the `users` table.

    Use this for auth endpoints (google_auth, email_auth, email_signup) where
    the user may not yet exist in the database and the endpoint itself handles
    user creation.

    Args:
        authorization: The Authorization header containing the Bearer token

    Returns:
        dict with 'auth_id', 'email', and 'user_metadata' from Supabase Auth

    Raises:
        HTTPException 401: If token is missing, malformed, or invalid
    """
    token = _extract_bearer_token(authorization)

    try:
        supabase = get_supabase()
        user_response = supabase.client.auth.get_user(token)

        if not user_response or not user_response.user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or expired token",
                headers={"WWW-Authenticate": "Bearer"},
            )

        return {
            "auth_id": str(user_response.user.id),
            "email": user_response.user.email,
            "user_metadata": user_response.user.user_metadata,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Token verification error: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Failed to validate token",
            headers={"WWW-Authenticate": "Bearer"},
        )


async def get_current_user(
    authorization: Optional[str] = Header(None, alias="Authorization")
) -> dict:
    """
    Full dependency to get the current authenticated user from Supabase JWT.

    Validates the token AND looks up the user row in the `users` table.
    Use this for all standard endpoints that require an existing user.

    Args:
        authorization: The Authorization header containing the Bearer token

    Returns:
        dict: User info with 'id' field from Supabase auth

    Raises:
        HTTPException: If no valid auth token is provided or user not in DB
    """
    token = _extract_bearer_token(authorization)

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

        # Use .execute() without .single() to avoid PostgREST PGRST116 error
        # when 0 rows are returned. The .single() call throws an exception
        # instead of returning empty data.
        result = supabase.client.table("users").select("id, email").eq("auth_id", supabase_auth_id).execute()

        if not result.data:
            logger.error(f"User not found in database for auth_id: {supabase_auth_id}")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found in database. Please complete sign-up first.",
            )

        user_row = result.data[0]
        return {
            "id": user_row["id"],  # Backend user ID for foreign keys
            "email": user_row["email"],
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
