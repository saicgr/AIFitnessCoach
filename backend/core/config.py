"""
Configuration settings for the FitWiz backend.
Easy to modify - just update the Settings class or .env file.
"""
from pydantic_settings import BaseSettings
from functools import lru_cache
from typing import Optional


class Settings(BaseSettings):
    """
    Application settings loaded from environment variables.

    To modify:
    1. Add new setting as a class attribute
    2. Add to .env file
    3. Access via get_settings().your_setting
    """

    # Gemini Configuration
    gemini_api_key: str
    gemini_model: str = "gemini-2.5-flash"  # Can be overridden by GEMINI_MODEL env var
    gemini_embedding_model: str = "text-embedding-004"
    gemini_max_tokens: int = 2000
    gemini_temperature: float = 0.7

    # Server Configuration
    host: str = "0.0.0.0"
    port: int = 8000
    debug: bool = True

    # Supabase Configuration
    supabase_url: str
    supabase_key: str
    supabase_db_password: Optional[str] = None

    # Database
    database_url: str = "postgresql+asyncpg://postgres:password@localhost:5432/postgres"
    sqlite_url: Optional[str] = None

    # RAG Configuration
    chroma_persist_dir: str = "./data/chroma"
    rag_top_k: int = 5  # Number of similar docs to retrieve
    rag_min_similarity: float = 0.7  # Minimum similarity threshold

    # Chroma Cloud Configuration (for AWS Lambda deployment)
    chroma_cloud_host: str = "api.trychroma.com"
    chroma_cloud_api_key: str = ""
    chroma_tenant: str = ""
    chroma_database: str = ""

    # AWS Configuration
    aws_access_key_id: Optional[str] = None
    aws_secret_access_key: Optional[str] = None
    aws_default_region: str = "us-east-1"
    s3_bucket_name: Optional[str] = None

    # Google OAuth Configuration
    gcp_oauth_client_id: Optional[str] = None
    gcp_oauth_client_secret: Optional[str] = None

    # RevenueCat Configuration
    revcat_api_key: Optional[str] = None
    revenuecat_webhook_secret: Optional[str] = None

    # USDA FoodData Central API Configuration
    # Get API key from: https://fdc.nal.usda.gov/api-key-signup.html
    usda_api_key: Optional[str] = None
    usda_cache_ttl_seconds: int = 3600  # Cache USDA results for 1 hour

    # Webhook Configuration (for admin notifications)
    # Slack webhook URL for support chat notifications
    slack_support_webhook: Optional[str] = None
    # Discord webhook URL for support chat notifications (optional)
    discord_support_webhook: Optional[str] = None
    # Admin dashboard URL for action buttons in webhook messages
    admin_dashboard_url: str = "https://fitwiz-admin.example.com"

    # CORS (for Flutter app)
    # Specific allowed origins - do not use ["*"] with allow_credentials=True
    cors_origins: list[str] = [
        "https://fitwiz-zqi3.onrender.com",
        "http://localhost:3000",
        "http://localhost:8000",
    ]

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        extra = "ignore"  # Ignore extra env vars not defined in Settings


@lru_cache()
def get_settings() -> Settings:
    """
    Get cached settings instance.
    Call this anywhere you need config values.

    Example:
        settings = get_settings()
        api_key = settings.gemini_api_key
    """
    return Settings()
