"""
Supabase client wrapper for FitWiz.
Provides database and auth functionality via Supabase.
"""
from fastapi import Depends
from supabase import create_client, Client
from supabase.lib.client_options import ClientOptions
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base
from contextlib import asynccontextmanager
from functools import lru_cache
from typing import Optional
import asyncio
import logging
import os
import httpx

logger = logging.getLogger(__name__)

from core.config import get_settings

# SQLAlchemy Base
Base = declarative_base()


class SupabaseManager:
    """Singleton manager for Supabase client and database connections."""

    _instance: Optional["SupabaseManager"] = None
    _supabase: Optional[Client] = None
    _supabase_auth: Optional[Client] = None
    _engine = None
    _session_maker = None
    _db_semaphore: Optional[asyncio.Semaphore] = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def __init__(self):
        if self._supabase is None:
            settings = get_settings()

            # Main client — used for PostgREST / .table() operations. Its
            # Authorization header must stay pinned to the service_role key so
            # RLS policies that check auth.role() = 'service_role' pass.
            self._supabase = create_client(
                settings.supabase_url,
                settings.supabase_key,
            )

            # Dedicated client for Supabase Auth operations (sign_in, sign_up,
            # update_user, get_user, etc). supabase-py's auth listener mutates
            # the shared Authorization header on SIGNED_IN / TOKEN_REFRESHED,
            # which would downgrade PostgREST calls from service_role to the
            # user's JWT and trip RLS. Isolating auth onto a separate client
            # means those mutations only touch this one — the main client
            # stays pinned to service_role. See:
            # .venv/.../supabase/_sync/client.py:_listen_to_auth_events
            self._supabase_auth = create_client(
                settings.supabase_url,
                settings.supabase_key,
            )

            # Configure auth client with longer timeout (10s instead of default 5s)
            # This prevents ReadTimeout errors on cold starts or slow network.
            # Applied to the dedicated auth client since that's where Auth calls run.
            self._supabase_auth.auth._http_client = httpx.Client(
                timeout=httpx.Timeout(10.0),
                follow_redirects=True,
            )

            # Configure PostgREST client with retry-enabled HTTP/1.1 transport.
            # Supabase's edge proxy can close idle HTTP/2 connections, causing
            # "Server disconnected" errors when multiple threads share one
            # multiplexed connection. HTTP/1.1 uses separate connections per
            # concurrent request, so a single drop doesn't cascade.
            # retries=3 automatically retries on connection-level failures.
            pg = self._supabase.postgrest  # trigger lazy init
            old_session = pg.session

            # Defensive service-role pinning. Even though the main client is
            # separate from the auth_client, supabase-py's GoTrue layer can
            # still swap the Authorization/apikey headers on the postgrest
            # session after any auth event (e.g. auth_client.auth.get_user()
            # firing TOKEN_REFRESHED). Confirmed in prod: inserts fail with
            # 42501 because auth.role() returns 'authenticated' instead of
            # 'service_role'. This event hook force-resets both headers on
            # EVERY outgoing request from the main client so the main client
            # is always recognized as service_role by PostgREST, regardless
            # of any mutation the SDK makes.
            _service_role_key = settings.supabase_key

            def _pin_service_role(request):
                request.headers["Authorization"] = f"Bearer {_service_role_key}"
                request.headers["apikey"] = _service_role_key

            pg.session = httpx.Client(
                base_url=str(old_session.base_url),
                headers=dict(old_session.headers),
                timeout=old_session.timeout,
                transport=httpx.HTTPTransport(retries=3),
                follow_redirects=True,
                event_hooks={"request": [_pin_service_role]},
            )
            old_session.close()

            # Initialize SQLAlchemy engine for Postgres
            # Lambda-optimized connection pooling:
            # - pool_pre_ping: Tests connections before use (handles frozen connections)
            # - pool_size: 10 connections (Lambda containers reuse connections)
            # - max_overflow: 20 (allows bursts in concurrent requests)
            self._engine = create_async_engine(
                settings.database_url,
                echo=settings.debug,
                pool_pre_ping=True,
                pool_size=settings.db_pool_size,
                max_overflow=settings.db_max_overflow,
                pool_timeout=settings.db_pool_timeout,
                pool_recycle=settings.db_pool_recycle,
            )

            # Create session maker
            self._session_maker = async_sessionmaker(
                self._engine,
                class_=AsyncSession,
                expire_on_commit=False
            )

            # Hard cap on concurrent DB sessions to stay within Supabase limits
            max_concurrent = settings.db_pool_size + settings.db_max_overflow
            self._db_semaphore = asyncio.Semaphore(max_concurrent)

    @property
    def client(self) -> Client:
        """
        Main Supabase client for PostgREST / .table() operations.

        Its Authorization header is pinned to the service_role key so that
        RLS policies with `auth.role() = 'service_role'` bypass work.
        Do NOT call Supabase Auth methods (sign_in, sign_up, update_user,
        get_user, refresh_session, reset_password_for_email, sign_out) on
        this client — use `auth_client` instead. Those methods trigger
        supabase-py's auth listener which mutates the Authorization header
        to the user's JWT and breaks service_role RLS bypass.
        """
        return self._supabase

    @property
    def auth_client(self) -> Client:
        """
        Dedicated Supabase client for Auth operations only.

        Use this for every .auth.* call (sign_in_with_password, sign_up,
        update_user, get_user, refresh_session, reset_password_for_email,
        sign_out). Its Authorization header can and will get mutated by
        the auth listener — that's fine because nothing uses this client's
        PostgREST.
        """
        return self._supabase_auth

    @property
    def engine(self):
        """Get SQLAlchemy engine."""
        return self._engine

    def get_session(self) -> AsyncSession:
        """Get a new database session (raw, without semaphore)."""
        return self._session_maker()

    @asynccontextmanager
    async def get_managed_session(self):
        """Get a database session guarded by the concurrency semaphore."""
        async with self._db_semaphore:
            session = self._session_maker()
            try:
                yield session
            finally:
                await session.close()

    async def close(self):
        """Close database connections."""
        if self._engine:
            await self._engine.dispose()


# Global Supabase manager instance
_supabase_manager: Optional[SupabaseManager] = None


def get_supabase() -> SupabaseManager:
    """Get the global Supabase manager instance."""
    global _supabase_manager
    if _supabase_manager is None:
        _supabase_manager = SupabaseManager()
    return _supabase_manager


async def get_db_session():
    """
    Dependency for FastAPI endpoints to get database session.
    Uses a semaphore to cap concurrent DB connections within Supabase limits.

    Usage:
        @app.get("/users")
        async def get_users(db: AsyncSession = Depends(get_db_session)):
            result = await db.execute(select(User))
            return result.scalars().all()
    """
    supabase_manager = get_supabase()
    async with supabase_manager._db_semaphore:
        session = supabase_manager.get_session()
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


class SupabaseAuth:
    """
    Helper class for Supabase authentication operations.

    Always construct with the isolated auth client (see SupabaseManager.auth_client).
    Never pass the main PostgREST-backing client here — auth listener mutations on
    that client break service_role RLS bypass.
    """

    def __init__(self, client: Client):
        self.client = client

    async def sign_up(self, email: str, password: str, metadata: dict = None):
        """
        Sign up a new user.

        Args:
            email: User's email
            password: User's password
            metadata: Additional user metadata

        Returns:
            Auth response with user and session
        """
        return self.client.auth.sign_up({
            "email": email,
            "password": password,
            "options": {
                "data": metadata or {}
            }
        })

    async def sign_in(self, email: str, password: str):
        """
        Sign in an existing user.

        Args:
            email: User's email
            password: User's password

        Returns:
            Auth response with user and session
        """
        return self.client.auth.sign_in_with_password({
            "email": email,
            "password": password
        })

    async def sign_out(self):
        """Sign out the current user."""
        return self.client.auth.sign_out()

    async def get_user(self, jwt: str):
        """
        Get user from JWT token.

        Args:
            jwt: JWT access token

        Returns:
            User object
        """
        return self.client.auth.get_user(jwt)

    async def refresh_session(self, refresh_token: str):
        """
        Refresh user session.

        Args:
            refresh_token: Refresh token from previous session

        Returns:
            New session with access and refresh tokens
        """
        return self.client.auth.refresh_session(refresh_token)

    async def reset_password_email(self, email: str):
        """
        Send password reset email.

        Args:
            email: User's email
        """
        return self.client.auth.reset_password_for_email(email)

    async def update_user(self, jwt: str, attributes: dict):
        """
        Update user attributes.

        Args:
            jwt: JWT access token
            attributes: User attributes to update
        """
        return self.client.auth.update_user(jwt, attributes)


def get_auth() -> SupabaseAuth:
    """Get Supabase auth helper instance (uses the isolated auth client)."""
    supabase_manager = get_supabase()
    return SupabaseAuth(supabase_manager.auth_client)
