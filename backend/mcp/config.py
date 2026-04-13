"""Centralized configuration for the MCP server.

All tunables live here — rate limits, token TTLs, subscription gating,
anomaly thresholds, scope catalog. Override any value via environment
variables with the MCP_ prefix (e.g. MCP_RATE_LIMIT_PER_MIN=15).
"""
from __future__ import annotations

from functools import lru_cache

from pydantic_settings import BaseSettings


class MCPConfig(BaseSettings):
    # ─── Rate limits (per user per integration) ──────────────────────────────
    RATE_LIMIT_PER_MIN: int = 30
    RATE_LIMIT_PER_HOUR: int = 500
    WRITE_LIMIT_PER_HOUR: int = 25
    CHAT_LIMIT_PER_HOUR: int = 10
    GENERATE_LIMIT_PER_HOUR: int = 5

    # ─── Token TTLs (seconds) ────────────────────────────────────────────────
    ACCESS_TOKEN_TTL_SEC: int = 3600         # 1 hour
    REFRESH_TOKEN_TTL_SEC: int = 2592000     # 30 days
    AUTH_CODE_TTL_SEC: int = 60
    CONFIRMATION_TOKEN_TTL_SEC: int = 300    # 5 min

    # ─── Anomaly tripwires ───────────────────────────────────────────────────
    # Hard-kill thresholds: client is auto-revoked and user notified.
    ANOMALY_LOG_MEAL_PER_5MIN: int = 50
    ANOMALY_ANY_TOOL_PER_MIN: int = 200
    # Statistical (soft) threshold for daily cron to flag outliers.
    ANOMALY_SIGMA_THRESHOLD: float = 3.0

    # ─── Subscription gate ───────────────────────────────────────────────────
    # MCP is a yearly-subscription-only feature. List RevenueCat product IDs
    # here that grant MCP access. Trial users on a yearly plan are eligible.
    YEARLY_PRODUCT_IDS: list[str] = [
        "fitwiz_yearly",
        "fitwiz_premium_yearly",
        "fitwiz_yearly_trial",
    ]
    SUBSCRIPTION_CACHE_TTL_SEC: int = 300  # 5 min, Redis

    # ─── OAuth server metadata ───────────────────────────────────────────────
    # Where to publish the OAuth authorization server metadata (RFC 8414).
    OAUTH_ISSUER: str = "https://aifitnesscoach-zqi3.onrender.com"
    # Consent screen URL users are redirected to on /oauth/authorize.
    CONSENT_URL: str = "https://aifitnesscoach-zqi3.onrender.com/mcp/consent/authorize"
    UPGRADE_URL: str = "https://fitwiz.us/upgrade?reason=mcp"

    # Token hashing pepper. MUST be set in production via MCP_TOKEN_PEPPER env.
    # Used in addition to the random token bytes; rotating the pepper invalidates
    # all outstanding tokens (use for emergency mass-revoke).
    TOKEN_PEPPER: str = "change-me-in-production"

    # ─── Scope catalog (master list) ─────────────────────────────────────────
    # Each scope maps to a human-readable description shown on consent screen.
    # Any scope requested by a client that is NOT in this dict is rejected.
    SCOPES: dict[str, str] = {
        "read:profile":    "Read your profile, goals, and preferences",
        "read:workouts":   "Read your workout plan and history",
        "read:nutrition":  "Read your meals and nutrition data",
        "read:scores":     "Read your strength and readiness scores",
        "write:logs":      "Log meals, water, sets, and body weight",
        "write:workouts":  "Generate and modify workout plans",
        "chat:coach":      "Chat with your AI coach",
        "export:data":     "Export your data and generate reports",
    }
    DEFAULT_SCOPES: list[str] = ["read:profile", "read:workouts", "read:nutrition"]

    # Tools that require a confirmation-token round-trip before execution.
    # See backend/mcp/auth/confirmation.py.
    CONFIRMATION_REQUIRED_TOOLS: list[str] = [
        "modify_workout.remove",
        "generate_workout_plan.replace",
        "log_meal.over_3000_kcal",
    ]

    class Config:
        env_prefix = "MCP_"
        env_file = ".env"
        env_file_encoding = "utf-8"
        extra = "ignore"


@lru_cache
def get_mcp_config() -> MCPConfig:
    """Cached MCP config accessor. Call anywhere."""
    return MCPConfig()
