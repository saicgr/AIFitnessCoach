"""
Authentication utilities for API endpoints.

Provides dependency injection for getting the current user from Supabase JWT tokens.

Two dependency levels:
- get_current_user: Full auth - validates JWT AND requires user row in DB.
  Use for all standard endpoints.
- get_verified_auth_token: Light auth - validates JWT only, no DB lookup.
  Use for auth endpoints (google, email, signup) that handle user creation themselves.
"""
from fastapi import Header, HTTPException, status, Depends
from typing import Optional
import asyncio
import logging

from supabase_auth.errors import AuthApiError, AuthRetryableError
from postgrest.exceptions import APIError as PostgrestAPIError

from core.supabase_client import get_supabase

logger = logging.getLogger(__name__)

# Substrings we consider "benign stale-JWT" — the user's client has a token
# that Supabase no longer recognizes (logged out on another device, session
# rotated, expired). These should return 401 to make the client refresh,
# but must not be captured as Sentry events (high-volume, not actionable).
# Keep this list in one place so core/sentry.py can import it too.
STALE_SESSION_MARKERS: tuple[str, ...] = (
    "session_id claim",       # "Session from session_id claim in JWT does not exist"
    "jwt expired",
    "jwt is expired",
    "invalid jwt",
    "invalid claim",
    "bad_jwt",
)


def is_stale_session_error(err: BaseException) -> bool:
    """True when the exception is a Supabase auth failure that just means
    'client's token is stale, make them re-auth'. Matches on lowercased
    message substrings so minor wording changes in supabase-py don't break
    the filter. Accepts any exception type so callers can pass the raw
    caught exception without a separate isinstance check."""
    if not isinstance(err, AuthApiError):
        return False
    msg = (getattr(err, "message", None) or str(err) or "").lower()
    return any(m in msg for m in STALE_SESSION_MARKERS)


def _is_transient_postgrest_error(err: PostgrestAPIError) -> bool:
    """Detect upstream 5xx responses from PostgREST/Cloudflare.

    PostgREST sets `code` to an int HTTP status when the upstream returns
    non-JSON (e.g., Cloudflare 502 HTML), and to a PGRST* string for
    application-level errors. Only 5xx is worth retrying.
    """
    code = err.code
    if isinstance(code, int):
        return 500 <= code < 600
    if isinstance(code, str) and code.isdigit():
        return 500 <= int(code) < 600
    return False


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
        user_response = supabase.auth_client.auth.get_user(token)

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
    except AuthApiError as e:
        if is_stale_session_error(e):
            logger.info(f"Stale Supabase session (verified_auth_token): {e}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Session expired — please log in again.",
                headers={"WWW-Authenticate": "Bearer"},
            )
        logger.error(f"Unexpected AuthApiError: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Failed to validate token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except Exception as e:
        logger.error(f"Token verification error: {e}", exc_info=True)
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
        # Verify token with Supabase (retry once on transient 5xx errors)
        supabase = get_supabase()
        user_response = None
        for attempt in range(2):
            try:
                user_response = supabase.auth_client.auth.get_user(token)
                break
            except AuthRetryableError:
                if attempt == 0:
                    logger.warning("Supabase auth returned transient error, retrying in 0.5s")
                    await asyncio.sleep(0.5)
                else:
                    raise

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
        # Retry once on transient upstream 5xx (e.g., Cloudflare 502 in front of Supabase).
        result = None
        for attempt in range(2):
            try:
                result = supabase.client.table("users").select("id, email").eq("auth_id", supabase_auth_id).execute()
                break
            except PostgrestAPIError as pg_err:
                if attempt == 0 and _is_transient_postgrest_error(pg_err):
                    logger.warning(f"PostgREST returned transient {pg_err.code}, retrying in 0.5s")
                    await asyncio.sleep(0.5)
                else:
                    raise

        if not result.data:
            logger.error(f"User not found in database for auth_id: {supabase_auth_id}")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found in database. Please complete sign-up first.",
            )

        user_row = result.data[0]
        # Attach user to Sentry scope so any error captured for this request
        # is tagged with the user id (no email — PII kept off by default).
        try:
            from core.sentry import set_user as _sentry_set_user
            _sentry_set_user(str(user_row["id"]))
        except Exception:
            pass
        return {
            "id": user_row["id"],  # Backend user ID for foreign keys
            "email": user_row["email"],
            "auth_id": supabase_auth_id,  # Supabase Auth ID if needed
            "user_metadata": user_response.user.user_metadata,
        }

    except HTTPException:
        raise
    except AuthRetryableError as e:
        # Both attempts failed — Supabase is genuinely down, return 503
        # so the client knows to retry (not 401 which would trigger logout)
        logger.error(f"Supabase auth unavailable after retry: {e}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Authentication service temporarily unavailable. Please try again.",
        )
    except AuthApiError as e:
        # Known stale-session patterns: rotate / expired / revoked JWT.
        # Log at INFO (breadcrumb only) so Sentry's LoggingIntegration
        # doesn't report each one as an error event. Response is still
        # 401 so the client knows to re-auth.
        if is_stale_session_error(e):
            logger.info(f"Stale Supabase session — prompting re-auth: {e}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Session expired — please log in again.",
                headers={"WWW-Authenticate": "Bearer"},
            )
        # Anything else is an unexpected auth backend state — keep the
        # full stack trace in Sentry so we can diagnose.
        logger.error(f"Unexpected AuthApiError during token validation: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Failed to validate token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except PostgrestAPIError as e:
        # Upstream 5xx from PostgREST (e.g., Cloudflare 502) after retry.
        # Surface as 503 so the client retries instead of logging the user out.
        if _is_transient_postgrest_error(e):
            logger.error(f"PostgREST upstream unavailable after retry: code={e.code}")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Authentication service temporarily unavailable. Please try again.",
            )
        logger.error(f"PostgREST error during auth: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Failed to validate token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except Exception as e:
        logger.error(f"Auth error: {e}", exc_info=True)
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


# ─── Ownership & Authorization Helpers ───────────────────────────────────────
# These provide SCALABLE IDOR protection. Use these instead of raw
# get_current_user when you need to verify the authenticated user
# matches the resource owner.


def verify_user_ownership(current_user: dict, user_id: str) -> None:
    """Verify the authenticated user matches the given user_id.

    Use this for endpoints that accept user_id as a path or query parameter.
    Raises 403 if the IDs don't match.

    Args:
        current_user: The authenticated user dict from get_current_user
        user_id: The user_id from the path/query parameter

    Raises:
        HTTPException 403: If current_user["id"] != user_id

    Example:
        @router.get("/{user_id}/data")
        async def get_data(user_id: str, current_user: dict = Depends(get_current_user)):
            verify_user_ownership(current_user, user_id)
            # Safe: user_id guaranteed == current_user["id"]
    """
    if str(current_user["id"]) != str(user_id):
        logger.warning(
            f"IDOR blocked: user {current_user['id']} tried to access resource for user {user_id}"
        )
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied",
        )


def verify_resource_ownership(
    current_user: dict,
    resource: Optional[dict],
    resource_name: str = "Resource",
) -> None:
    """Verify a fetched resource belongs to the authenticated user.

    Use this for endpoints that accept entity IDs (workout_id, goal_id, etc.)
    where you need to fetch the entity first, then check ownership.

    Args:
        current_user: The authenticated user dict from get_current_user
        resource: The fetched resource dict (must have a "user_id" field)
        resource_name: Human-readable name for error messages (e.g., "Workout")

    Raises:
        HTTPException 404: If resource is None
        HTTPException 403: If resource.user_id != current_user["id"]

    Example:
        @router.delete("/{workout_id}")
        async def delete_workout(workout_id: str, current_user: dict = Depends(get_current_user)):
            workout = db.get_workout(workout_id)
            verify_resource_ownership(current_user, workout, "Workout")
            db.delete_workout(workout_id)
    """
    if resource is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"{resource_name} not found",
        )

    resource_user_id = resource.get("user_id")
    if resource_user_id is None:
        # EDGE CASE: Resource doesn't have user_id field — log and deny
        logger.error(f"Resource {resource_name} missing user_id field for ownership check")
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied",
        )

    if str(resource_user_id) != str(current_user["id"]):
        logger.warning(
            f"IDOR blocked: user {current_user['id']} tried to access {resource_name} "
            f"owned by {resource_user_id}"
        )
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied",
        )


async def get_admin_user(
    authorization: Optional[str] = Header(None, alias="Authorization"),
) -> dict:
    """Dependency for admin-only endpoints.

    Like get_current_user but also verifies the user has admin role.
    Use this instead of get_current_user for endpoints that should only
    be accessible to administrators.

    Args:
        authorization: The Authorization header containing the Bearer token

    Returns:
        dict: Admin user info

    Raises:
        HTTPException 401: If not authenticated
        HTTPException 403: If authenticated but not admin

    Example:
        @router.get("/all-users")
        async def list_all(admin: dict = Depends(get_admin_user)):
            # Only admins reach here
    """
    user = await get_current_user(authorization)

    # Check admin role in user metadata or database
    user_metadata = user.get("user_metadata", {})
    if user_metadata.get("role") != "admin":
        # Also check if the user has admin role in the database
        try:
            supabase = get_supabase()
            result = supabase.client.table("users") \
                .select("role") \
                .eq("id", str(user["id"])) \
                .limit(1) \
                .execute()
            db_role = result.data[0].get("role") if result.data else None
            if db_role != "admin":
                logger.warning(f"Non-admin user {user['id']} attempted admin endpoint")
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Admin access required",
                )
        except HTTPException:
            raise
        except Exception:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Admin access required",
            )

    return user
