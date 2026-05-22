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
from typing import Any, Optional
import asyncio
import hashlib
import logging
import time as _time

import httpx
import jwt as _pyjwt
from supabase_auth.errors import AuthApiError, AuthRetryableError
from postgrest.exceptions import APIError as PostgrestAPIError

from core.config import get_settings
from core.redis_cache import RedisCache
from core.supabase_client import get_supabase

logger = logging.getLogger(__name__)

# Redis-backed cache of verified identities. A client polling /workouts/today
# every ~5s reuses the same JWT, so this collapses ~720 verifications/hour into
# one. Shared across workers via Redis; per-worker in-memory fallback if Redis
# is down. TTL is additionally capped at the token's own `exp` so a cached
# entry never outlives the token.
#
# KEY FORMAT: `f"{user_id}:{token_hash}"`. The leading user-id segment is what
# makes revocation possible — a password change / forced sign-out / account
# action can bust EVERY cached token for one user in a single call via
# `_auth_user_cache.delete_prefix(f"{user_id}:")`. Keying by token_hash alone
# (the old scheme) left no handle to invalidate by user, so a revoked token
# kept hitting the fast path until its TTL elapsed.
#
# `user_id` here is the JWT `sub` claim (the Supabase auth id). It is used
# rather than the backend `users.id` because it is recoverable from the token
# itself via an unverified decode — so the cache GET can build the key WITHOUT
# a DB round-trip, which is the entire point of the fast path. `sub` is a
# stable, unique per-user identifier, so prefix-revocation works the same way.
_auth_user_cache = RedisCache(prefix="auth_user", ttl_seconds=300, max_size=2000)
_AUTH_CACHE_MAX_TTL = 300  # seconds


def _auth_cache_key(user_id: Any, token_hash: str) -> str:
    """Build the `{user_id}:{token_hash}` auth-cache key.

    The user_id segment lets `delete_prefix(f"{user_id}:")` revoke every
    cached identity for a user. user_id is coerced to str so a UUID value
    produces a stable key. See module-level note on why this is the JWT `sub`.
    """
    return f"{user_id}:{token_hash}"


async def invalidate_auth_cache_for_user(user_id: Any) -> None:
    """Bust every cached verified-identity entry for one user.

    Call this after a password change, a forced sign-out, or any action that
    should immediately stop existing JWTs from being honored via the auth
    cache. `user_id` must be the JWT `sub` (Supabase auth id) — the same value
    the cache keys on. Without this the cached identity would keep serving the
    fast path until its (≤5 min) TTL elapses.
    """
    await _auth_user_cache.delete_prefix(f"{user_id}:")


def _decode_exp_unverified(token: str) -> Optional[int]:
    """Read the `exp` claim without signature verification — used only to cap
    the auth-cache TTL so a cached identity never outlives its token."""
    try:
        return _pyjwt.decode(token, options={"verify_signature": False}).get("exp")
    except Exception:
        return None


def _decode_sub_unverified(token: str) -> Optional[str]:
    """Read the `sub` claim (Supabase auth id) WITHOUT signature verification.

    Used only to build the auth-cache key on the fast path before the token is
    cryptographically verified. A forged `sub` only ever produces a cache miss
    (the verified identity stored under the real key won't be found), so
    reading it unverified here is safe — it is never trusted as identity."""
    try:
        sub = _pyjwt.decode(token, options={"verify_signature": False}).get("sub")
        return str(sub) if sub is not None else None
    except Exception:
        return None


def _verify_jwt_local(token: str) -> Optional[dict]:
    """Verify a Supabase HS256 access token LOCALLY (no network call).

    Returns a normalized identity dict when SUPABASE_JWT_SECRET is configured
    and the signature is valid. Returns None when no secret is set OR the
    signature does not match (caller then falls back to a network verify — the
    latter keeps clients logged in across a JWT-secret rotation). Raises
    HTTPException(401) only for a definitively expired token.
    """
    secret = get_settings().supabase_jwt_secret
    if not secret:
        return None
    try:
        claims = _pyjwt.decode(
            token,
            secret,
            algorithms=["HS256"],
            audience="authenticated",
            leeway=30,  # tolerate minor client/server clock skew
        )
    except _pyjwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Session expired — please log in again.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except _pyjwt.InvalidTokenError as e:
        logger.warning(f"Local JWT verify failed ({e}) — falling back to network verify")
        return None
    return {
        "auth_id": str(claims.get("sub")),
        "email": claims.get("email"),
        "user_metadata": claims.get("user_metadata") or {},
        "app_metadata": claims.get("app_metadata") or {},
    }


async def _network_verify_token(token: str) -> dict:
    """Verify a token via Supabase Auth's /user endpoint, OFF the event loop.

    The supabase-py client is synchronous — calling it directly on the event
    loop blocks the whole worker for the network round-trip (the 2026-05-16
    serialization bug). asyncio.to_thread moves it to the blocking-io pool.
    Retries once on transient errors. Returns the same shape as
    _verify_jwt_local. AuthApiError (stale/deleted) propagates to the caller.
    """
    supabase = get_supabase()
    user_response = None
    for attempt in range(2):
        try:
            user_response = await asyncio.to_thread(
                supabase.auth_client.auth.get_user, token
            )
            break
        except AuthRetryableError:
            if attempt == 0:
                logger.warning("Supabase auth transient error, retrying in 0.5s")
                await asyncio.sleep(0.5)
            else:
                raise
        except _TRANSIENT_HTTPX_ERRORS as transport_err:
            if attempt == 0:
                logger.warning(
                    f"Transient httpx error in auth.get_user: {transport_err} — retrying in 0.5s"
                )
                await asyncio.sleep(0.5)
            else:
                raise HTTPException(
                    status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                    detail="Auth service temporarily unavailable",
                )
    if not user_response or not user_response.user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    u = user_response.user
    return {
        "auth_id": str(u.id),
        "email": u.email,
        "user_metadata": u.user_metadata or {},
        "app_metadata": u.app_metadata or {},
    }

# Transient httpx transport-layer errors that surface inside Supabase / PostgREST
# client calls as the underlying connection blips. These must NEVER be 401'd —
# the JWT is valid, the network is just glitching. Surface as 503 so the Flutter
# Dio retry interceptor backs off instead of forcing a sign-out.
_TRANSIENT_HTTPX_ERRORS = (
    httpx.RemoteProtocolError,
    httpx.ConnectError,
    httpx.ConnectTimeout,
    httpx.ReadTimeout,
    httpx.WriteTimeout,
    httpx.PoolTimeout,
    httpx.ReadError,
    httpx.WriteError,
)

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

# Substrings that mean the user row backing this JWT was hard-deleted from
# Supabase Auth (typically by our own /users/{id}/reset endpoint, an admin
# action, or a project auth wipe). The JWT itself is cryptographically valid
# and can even be refreshed — but every API call against it 401s forever
# because the `sub` claim points at a row that no longer exists. This is a
# DIFFERENT failure mode from a stale/expired session: refreshing won't
# recover, and the only fix is for the client to drop the token and route
# the user to sign-in. We surface a stable error code so the Flutter client
# can distinguish this case and stop the 401 storm.
JWT_USER_DELETED_MARKERS: tuple[str, ...] = (
    "user from sub claim in jwt does not exist",
    "user_not_found",
)
# Stable error code returned in the response `detail` so the client can
# branch on a string match instead of parsing free-form Supabase messages.
JWT_USER_DELETED_CODE: str = "JWT_USER_DELETED"


def is_jwt_user_deleted_error(err: BaseException) -> bool:
    """True when the auth backend says the JWT's `sub` user no longer exists.
    Distinct from `is_stale_session_error` because refreshSession() cannot
    recover from this — the client must hard-sign-out."""
    if not isinstance(err, AuthApiError):
        return False
    msg = (getattr(err, "message", None) or str(err) or "").lower()
    return any(m in msg for m in JWT_USER_DELETED_MARKERS)


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
        # Local HS256 verify when SUPABASE_JWT_SECRET is set; otherwise an
        # off-event-loop network verify. Either way, no blocking call on the
        # event loop.
        identity = _verify_jwt_local(token)
        if identity is None:
            identity = await _network_verify_token(token)

        return {
            "auth_id": identity["auth_id"],
            "email": identity["email"],
            "user_metadata": identity["user_metadata"],
        }

    except HTTPException:
        raise
    except AuthApiError as e:
        if is_jwt_user_deleted_error(e):
            logger.info(f"JWT user deleted (verified_auth_token): {e}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=JWT_USER_DELETED_CODE,
                headers={
                    "WWW-Authenticate": "Bearer",
                    "X-Auth-Error": JWT_USER_DELETED_CODE,
                },
            )
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
    except _TRANSIENT_HTTPX_ERRORS as exc:
        # Transport-layer blip — see get_current_user for full rationale.
        # NEVER 401 on a transient transport error; surface 503 so the client retries.
        logger.warning(f"Transient httpx error in auth: {exc}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Auth service temporarily unavailable",
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
    token_hash = hashlib.sha256(token.encode()).hexdigest()

    # Fast path: identity verified within the cache window — no network, no DB.
    # The cache key is `{sub}:{token_hash}`. `sub` is read via an unverified
    # decode so the key can be built without a DB round-trip; a forged `sub`
    # just misses the cache (the entry was stored under the real `sub`). When
    # the token has no `sub` we fall back to the token-hash-only key so the
    # fast path still functions, just without per-user prefix revocation.
    cache_sub = _decode_sub_unverified(token)
    cache_key = _auth_cache_key(cache_sub, token_hash) if cache_sub else token_hash
    cached_user = await _auth_user_cache.get(cache_key)
    if cached_user is not None:
        try:
            from core.sentry import set_user as _sentry_set_user
            _sentry_set_user(str(cached_user.get("id")))
        except Exception:
            pass
        return cached_user

    try:
        supabase = get_supabase()

        # Verify the token: local HS256 signature check when SUPABASE_JWT_SECRET
        # is set (no network); otherwise an off-event-loop network verify.
        identity = _verify_jwt_local(token)
        if identity is None:
            identity = await _network_verify_token(token)

        # Look up backend user ID using Supabase Auth ID
        # The database uses backend user ID (users.id) for foreign keys,
        # not Supabase Auth ID (users.auth_id)
        supabase_auth_id = identity["auth_id"]

        # Use .execute() without .single() to avoid PostgREST PGRST116 error
        # when 0 rows are returned. The .single() call throws an exception
        # instead of returning empty data.
        # Retry once on transient upstream 5xx (e.g., Cloudflare 502 in front of Supabase).
        # asyncio.to_thread keeps the blocking supabase-py call off the event loop.
        result = None
        for attempt in range(2):
            try:
                result = await asyncio.to_thread(
                    lambda: supabase.client.table("users")
                    .select("id, email").eq("auth_id", supabase_auth_id).execute()
                )
                break
            except PostgrestAPIError as pg_err:
                if attempt == 0 and _is_transient_postgrest_error(pg_err):
                    logger.warning(f"PostgREST returned transient {pg_err.code}, retrying in 0.5s")
                    await asyncio.sleep(0.5)
                else:
                    raise
            except _TRANSIENT_HTTPX_ERRORS as transport_err:
                if attempt == 0:
                    logger.warning(
                        f"Transient httpx error in PostgREST users lookup: {transport_err} — retrying in 0.5s"
                    )
                    await asyncio.sleep(0.5)
                else:
                    logger.warning(
                        f"Transient httpx error in PostgREST users lookup persisted after retry: {transport_err}"
                    )
                    raise HTTPException(
                        status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                        detail="Auth service temporarily unavailable",
                    )

        if not result.data:
            # JWT is cryptographically valid and the auth row still exists,
            # but our public.users row is gone. This is the post-full_reset
            # half-state (or a partially-completed signup). It is NOT
            # recoverable by token refresh — the client must sign out and
            # restart. Reuse the JWT_USER_DELETED code so the Flutter
            # interceptor handles both cases the same way.
            logger.info(
                f"public.users row missing for auth_id {supabase_auth_id} "
                "— signaling client to sign out"
            )
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=JWT_USER_DELETED_CODE,
                headers={
                    "WWW-Authenticate": "Bearer",
                    "X-Auth-Error": JWT_USER_DELETED_CODE,
                },
            )

        user_row = result.data[0]
        # Attach user to Sentry scope so any error captured for this request
        # is tagged with the user id (no email — PII kept off by default).
        try:
            from core.sentry import set_user as _sentry_set_user
            _sentry_set_user(str(user_row["id"]))
        except Exception:
            pass
        user = {
            "id": user_row["id"],  # Backend user ID for foreign keys
            "email": user_row["email"],
            "auth_id": supabase_auth_id,  # Supabase Auth ID if needed
            "user_metadata": identity["user_metadata"],
            "app_metadata": identity["app_metadata"],
        }
        # Cache the verified identity, TTL-capped so it never outlives the
        # token's own `exp`. Subsequent requests with this token skip both
        # the verify and the DB lookup entirely. Key on the VERIFIED `sub`
        # (supabase_auth_id) so `delete_prefix("{sub}:")` can revoke every
        # cached token for this user on a password change / forced logout.
        exp = _decode_exp_unverified(token)
        ttl = _AUTH_CACHE_MAX_TTL
        if exp:
            ttl = max(1, min(_AUTH_CACHE_MAX_TTL, int(exp - _time.time())))
        await _auth_user_cache.set(
            _auth_cache_key(supabase_auth_id, token_hash), user, ttl_override=ttl
        )
        return user

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
        # User row backing this JWT was hard-deleted (full_reset, admin
        # action, project wipe). refreshSession() can't recover from this —
        # return a stable error code so the client signs out instead of
        # spinning on retries. Log at INFO so we don't pollute Sentry: every
        # bricked client will fire one of these per screen mount until the
        # client picks up the signal and signs out.
        if is_jwt_user_deleted_error(e):
            logger.info(f"JWT user deleted — forcing client sign-out: {e}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=JWT_USER_DELETED_CODE,
                headers={
                    "WWW-Authenticate": "Bearer",
                    "X-Auth-Error": JWT_USER_DELETED_CODE,
                },
            )
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
    except _TRANSIENT_HTTPX_ERRORS as exc:
        # Transport-layer blip (Supabase / PostgREST connection drop, DNS jitter,
        # read timeout). The token is still valid — DO NOT 401 the client (would
        # force a logout). Surface as 503 so the Dio retry interceptor backs off
        # instead. Log at WARNING — we want visibility but not Sentry-error noise.
        logger.warning(f"Transient httpx error in auth: {exc}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Auth service temporarily unavailable",
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
