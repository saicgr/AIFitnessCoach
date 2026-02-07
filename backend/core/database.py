"""
Database configuration and session management.
Uses SQLAlchemy async for non-blocking database operations.

Connection pool settings:
  - pool_size: Number of persistent connections kept open (default 10)
  - max_overflow: Extra connections allowed under load (default 20)
  - pool_timeout: Seconds to wait for a connection before erroring (default 30)
  - pool_recycle: Seconds before a connection is recycled to avoid stale connections (default 1800 = 30 min)
  - pool_pre_ping: Test connection health before handing it to a request (default True)
"""
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base
from core.config import get_settings
import os

settings = get_settings()

# Ensure data directory exists
os.makedirs("./data", exist_ok=True)

# Determine if we're using SQLite (local dev) vs PostgreSQL (production)
_is_sqlite = settings.database_url.startswith("sqlite")

# Connection pool kwargs - SQLite doesn't support pooling options
_pool_kwargs = {}
if not _is_sqlite:
    _pool_kwargs = {
        "pool_size": settings.db_pool_size,
        "max_overflow": settings.db_max_overflow,
        "pool_timeout": settings.db_pool_timeout,
        "pool_recycle": settings.db_pool_recycle,
        "pool_pre_ping": True,
    }

# Create async engine with connection pooling
engine = create_async_engine(
    settings.database_url,
    echo=settings.debug,
    future=True,
    **_pool_kwargs,
)

# Session factory
async_session = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)

# Base class for ORM models
Base = declarative_base()


async def get_db() -> AsyncSession:
    """
    Dependency to get database session.
    Use with FastAPI's Depends().

    Example:
        @app.get("/items")
        async def get_items(db: AsyncSession = Depends(get_db)):
            ...
    """
    async with async_session() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


async def init_db():
    """Initialize database tables."""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
