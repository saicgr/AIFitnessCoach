"""
Supabase client wrapper for AI Fitness Coach.
Provides database and auth functionality via Supabase.
"""
from supabase import create_client, Client
from supabase.lib.client_options import ClientOptions
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base
from functools import lru_cache
from typing import Optional
import os
import httpx

from core.config import get_settings

# SQLAlchemy Base
Base = declarative_base()


class SupabaseManager:
    """Singleton manager for Supabase client and database connections."""

    _instance: Optional["SupabaseManager"] = None
    _supabase: Optional[Client] = None
    _engine = None
    _session_maker = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def __init__(self):
        if self._supabase is None:
            settings = get_settings()

            # Initialize Supabase client (for Auth and Realtime)
            self._supabase = create_client(
                settings.supabase_url,
                settings.supabase_key,
            )

            # Configure auth client with longer timeout (10s instead of default 5s)
            # This prevents ReadTimeout errors on cold starts or slow network
            auth_http_client = httpx.Client(
                timeout=httpx.Timeout(10.0),
                follow_redirects=True,
            )
            self._supabase.auth._http_client = auth_http_client

            # Initialize SQLAlchemy engine for Postgres
            # Lambda-optimized connection pooling:
            # - pool_pre_ping: Tests connections before use (handles frozen connections)
            # - pool_size: 10 connections (Lambda containers reuse connections)
            # - max_overflow: 20 (allows bursts in concurrent requests)
            self._engine = create_async_engine(
                settings.database_url,
                echo=settings.debug,
                pool_pre_ping=True,
                pool_size=10,
                max_overflow=20
            )

            # Create session maker
            self._session_maker = async_sessionmaker(
                self._engine,
                class_=AsyncSession,
                expire_on_commit=False
            )

    @property
    def client(self) -> Client:
        """Get Supabase client for Auth operations."""
        return self._supabase

    @property
    def engine(self):
        """Get SQLAlchemy engine."""
        return self._engine

    def get_session(self) -> AsyncSession:
        """Get a new database session."""
        return self._session_maker()

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

    Usage:
        @app.get("/users")
        async def get_users(db: AsyncSession = Depends(get_db_session)):
            result = await db.execute(select(User))
            return result.scalars().all()
    """
    supabase_manager = get_supabase()
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
    """Helper class for Supabase authentication operations."""

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
    """Get Supabase auth helper instance."""
    supabase_manager = get_supabase()
    return SupabaseAuth(supabase_manager.client)
