"""
Supabase client wrapper for Zealova.
Provides database and auth functionality via Supabase.
"""
from fastapi import Depends, HTTPException
from supabase import create_client, Client
from supabase.lib.client_options import ClientOptions
from sqlalchemy.exc import TimeoutError as SQLATimeoutError
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
from core.db_circuit_breaker import get_db_breaker

# DB-RESILIENCE (Phase D): cap how long a request will wait to ACQUIRE a pooled
# connection before failing fast. SQLAlchemy's pool_timeout (30s) is the hard
# ceiling; a 30s hang under load is worse UX than a quick 503 the client can
# retry. We lower the *effective* wait via asyncio.wait_for so a saturated pool
# rejects fast. Retry-After tells the client when to come back.
DB_ACQUIRE_TIMEOUT_SECONDS = 5.0
DB_ACQUIRE_RETRY_AFTER = 5


def _pool_exhausted_503() -> HTTPException:
    """Clean FastAPI-friendly 503 for a saturated connection pool."""
    return HTTPException(
        status_code=503,
        detail="Database connection pool exhausted. Please retry shortly.",
        headers={"Retry-After": str(DB_ACQUIRE_RETRY_AFTER)},
    )

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

            # Soft-delete read guard. `food_logs` rows are never removed — a
            # delete stamps `deleted_at` — so a read that forgets
            # `.is_("deleted_at", "null")` counts meals the user threw away
            # (2026-07 sweep: 36 of 74 reads did exactly that, poisoning the
            # nutrition/health scores, streaks, weekly email, nudges, wrapped
            # and XP). Installing it on the one client every runtime read goes
            # through fixes the class instead of 36 call sites. Writes and all
            # other tables are untouched — see core/db/soft_delete.py.
            # Imported here, not at module scope: `core.db.__init__` pulls in
            # core.db.base, which imports this module — a top-level import
            # would be circular.
            from core.db.soft_delete import install_soft_delete_guard
            install_soft_delete_guard(self._supabase)

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
            #
            # transport=retries=3 mirrors the PostgREST session below: GoTrue is
            # reached over the same Supabase edge proxy that closes idle
            # keep-alive connections, so an auth call that reuses a stale socket
            # would otherwise surface a bare SSLEOFError ("EOF occurred in
            # violation of protocol") to the caller (e.g. the home bootstrap's
            # resolve_timezone/auth path). Retrying connection-level failures
            # makes the auth path as resilient to those drops as PostgREST.
            self._supabase_auth.auth._http_client = httpx.Client(
                timeout=httpx.Timeout(10.0),
                transport=httpx.HTTPTransport(retries=3),
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

            # Initialize SQLAlchemy engine for Postgres.
            #
            # Why connect_args looks the way it does — Supavisor transaction
            # mode (port 6543) recycles backend Postgres connections across
            # client transactions. asyncpg's default prepared-statement names
            # are sequential (`__asyncpg_stmt_1__`, `__asyncpg_stmt_2__`),
            # so two clients that grab the same backend at different times
            # both try to PREPARE statement #1 → DuplicatePreparedStatementError
            # → SQLAlchemy retries → request times out.
            #
            #   • statement_cache_size=0 — don't reuse prepared statements
            #     within a connection (asyncpg-side cache off)
            #   • prepared_statement_cache_size=0 — same toggle, asyncpg's
            #     newer alias for the above (set both for forward-compat)
            #   • prepared_statement_name_func=lambda: f"__asyncpg_{uuid4().hex}__"
            #     — generate a UNIQUE name per prepare call so two clients
            #     can both prepare on the same recycled backend without
            #     colliding. This is the only thing that actually makes
            #     transaction-mode pooling work with asyncpg + SQLAlchemy.
            #
            # All three are no-ops when pointed at a direct DB connection or a
            # session-mode pooler — safe to leave on unconditionally.
            from uuid import uuid4
            self._engine = create_async_engine(
                settings.database_url,
                echo=settings.debug,
                pool_pre_ping=True,
                pool_size=settings.db_pool_size,
                max_overflow=settings.db_max_overflow,
                pool_timeout=settings.db_pool_timeout,
                pool_recycle=settings.db_pool_recycle,
                connect_args={
                    "statement_cache_size": 0,
                    "prepared_statement_cache_size": 0,
                    "prepared_statement_name_func": lambda: f"__asyncpg_{uuid4().hex}__",
                },
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

    def pool_stats(self) -> dict:
        """Snapshot of SQLAlchemy connection-pool pressure (Phase D4).

        Reads the live counters off the async engine's underlying pool. All
        values are in-memory ints — this is cheap and never touches the DB,
        so it is safe to call from an observability endpoint on any tick.

        Fields:
          * size            — configured pool_size
          * checked_out     — connections currently in use by a request
          * checked_in      — idle connections sitting in the pool
          * overflow        — connections opened beyond pool_size (>=0); a
                              high/maxed value means the pool is under pressure
          * max_overflow    — configured overflow ceiling
          * total_capacity  — size + max_overflow (hard concurrency ceiling)
        """
        settings = get_settings()
        stats: dict = {
            "size": settings.db_pool_size,
            "max_overflow": settings.db_max_overflow,
            "total_capacity": settings.db_pool_size + settings.db_max_overflow,
            "pool_timeout_seconds": settings.db_pool_timeout,
        }
        try:
            pool = self._engine.pool
            # QueuePool exposes these; some pool classes (NullPool) do not.
            checked_out = pool.checkedout() if hasattr(pool, "checkedout") else None
            checked_in = pool.checkedin() if hasattr(pool, "checkedin") else None
            overflow = pool.overflow() if hasattr(pool, "overflow") else None
            stats.update({
                "checked_out": checked_out,
                "checked_in": checked_in,
                "overflow": overflow,
            })
            if checked_out is not None:
                # Fraction of the hard capacity currently in use — the single
                # number to watch during a load test.
                stats["utilization"] = round(
                    checked_out / stats["total_capacity"], 4
                ) if stats["total_capacity"] else 0.0
        except Exception as e:
            logger.debug(f"pool_stats: could not read pool counters: {e}")
            stats["error"] = "pool counters unavailable"
        return stats

    async def _acquire_connection_fast_fail(self):
        """Acquire a pooled DB connection, failing FAST instead of hanging.

        Wraps engine.connect() in asyncio.wait_for so a saturated pool rejects
        within DB_ACQUIRE_TIMEOUT_SECONDS rather than blocking up to the full
        pool_timeout (30s). A pool/acquire timeout surfaces as a clean HTTP 503
        with a Retry-After header. The whole acquisition runs through the DB
        circuit breaker so a sustained outage trips it and short-circuits.

        Returns an AsyncConnection (caller owns closing it).
        """
        breaker = get_db_breaker()
        try:
            async with breaker.guard():
                return await asyncio.wait_for(
                    self._engine.connect(),
                    timeout=DB_ACQUIRE_TIMEOUT_SECONDS,
                )
        except (asyncio.TimeoutError, SQLATimeoutError) as exc:
            # Pool exhausted / acquisition timed out — fail fast with 503.
            logger.warning("⚠️ [DB] connection acquisition timed out: %s", exc)
            raise _pool_exhausted_503() from exc

    @asynccontextmanager
    async def get_managed_session(self):
        """Get a database session.

        Concurrency is governed by SQLAlchemy's pool (`pool_size`,
        `max_overflow`, `pool_timeout`) — Supavisor on the other side then
        multiplexes onto its server-side pool. The asyncio.Semaphore that
        previously wrapped this call layered a second FIFO queue at the Python
        level, causing requests to block at the semaphore even when the pool
        had capacity, and producing the observed "_phase1 timed out at 5s
        while asyncpg was still mid-handshake" pattern under burst load.

        DB-RESILIENCE (Phase D): the connection is acquired via
        _acquire_connection_fast_fail() so a saturated pool returns a fast 503
        and a downstream outage trips the circuit breaker — instead of every
        request hanging on a dead/slow database. The healthy path is
        unchanged: a connection acquired in well under DB_ACQUIRE_TIMEOUT_SECONDS
        proceeds exactly as before.
        """
        conn = await self._acquire_connection_fast_fail()
        # Bind the session to the pre-acquired connection so pool-wait latency
        # is already paid (and fast-failed) before any session work begins.
        session = self._session_maker(bind=conn)
        try:
            yield session
        finally:
            await session.close()
            await conn.close()

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

    DB-RESILIENCE (Phase D): the connection is acquired via
    _acquire_connection_fast_fail(), so when the pool is exhausted the request
    gets a fast HTTP 503 + Retry-After instead of hanging up to pool_timeout
    (30s), and a sustained DB outage trips the shared circuit breaker. The 503
    is a plain HTTPException, so FastAPI's exception handling / middleware
    surfaces it cleanly to the caller. The healthy path is unchanged.

    Usage:
        @app.get("/users")
        async def get_users(db: AsyncSession = Depends(get_db_session)):
            result = await db.execute(select(User))
            return result.scalars().all()
    """
    supabase_manager = get_supabase()
    conn = await supabase_manager._acquire_connection_fast_fail()
    session = supabase_manager._session_maker(bind=conn)
    try:
        yield session
        await session.commit()
    except Exception:
        await session.rollback()
        raise
    finally:
        await session.close()
        await conn.close()


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
