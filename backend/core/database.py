"""
Database configuration and session management.
Uses SQLAlchemy async for non-blocking database operations.
"""
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base
from core.config import get_settings
import os

settings = get_settings()

# Ensure data directory exists
os.makedirs("./data", exist_ok=True)

# Create async engine
engine = create_async_engine(
    settings.database_url,
    echo=settings.debug,
    future=True,
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
