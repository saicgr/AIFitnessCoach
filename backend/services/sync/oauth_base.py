"""
Abstract base class for all two-way-sync providers.

Each concrete provider (``strava.py``, ``garmin.py``, ``fitbit.py``,
``apple_health.py``, ``peloton.py``) subclasses :class:`SyncProvider` and
implements the five required hooks:

    begin_auth(user_id)            → auth_url (str)
    exchange_code(code, state)     → TokenBundle
    refresh_token(account)         → TokenBundle
    fetch_since(account, since_dt) → List[CanonicalCardioRow | CanonicalSetRow]
    register_webhook(account)      → Optional[str]     (push subscription id)
    unregister_webhook(account)    → None

Providers without push (Garmin, Peloton) return ``None`` from
``register_webhook`` and let the 15-min cron handle pull.

All token I/O goes through :func:`encrypt_token` / :func:`decrypt_token` — the
plaintext access/refresh tokens exist **only** in memory inside provider
methods, never in logs and never on disk.
"""
from __future__ import annotations

import abc
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Union
from uuid import UUID

from services.sync.token_encryption import encrypt_token, decrypt_token
from services.workout_import.canonical import (
    CanonicalCardioRow,
    CanonicalSetRow,
)


# ─────────────────────────── Domain objects ────────────────────────────

@dataclass
class TokenBundle:
    """What ``exchange_code`` / ``refresh_token`` return.

    Plaintext tokens. Caller is responsible for encrypting before persisting.
    """
    access_token: str
    refresh_token: Optional[str] = None
    expires_at: Optional[datetime] = None     # tz-aware UTC
    scopes: List[str] = field(default_factory=list)
    provider_user_id: Optional[str] = None    # the ID the provider uses for this user

    def is_expired(self, leeway_seconds: int = 60) -> bool:
        """True if the token is within ``leeway_seconds`` of its expiry.

        Leeway exists so we refresh *before* the next API call fails — a token
        that expires in 30s is effectively dead for a 10s sync round-trip.
        """
        if self.expires_at is None:
            return False
        now = datetime.now(timezone.utc)
        delta = (self.expires_at - now).total_seconds()
        return delta < leeway_seconds


@dataclass
class SyncAccount:
    """Hydrated row from ``oauth_sync_accounts`` — tokens decrypted, typed.

    The raw DB row is the thing that's encrypted; we decrypt into a
    ``SyncAccount`` once at the start of a sync and re-encrypt if we have to
    write anything back (only on refresh).
    """
    id: UUID
    user_id: UUID
    provider: str
    provider_user_id: str
    access_token: str                           # decrypted
    refresh_token: Optional[str] = None         # decrypted
    expires_at: Optional[datetime] = None
    scopes: List[str] = field(default_factory=list)
    status: str = "active"
    last_sync_at: Optional[datetime] = None
    last_sync_status: Optional[str] = None
    last_error: Optional[str] = None
    error_count: int = 0
    auto_import: bool = True
    import_strength: bool = True
    import_cardio: bool = True
    webhook_id: Optional[str] = None

    @classmethod
    def from_db_row(cls, row: Dict[str, Any]) -> "SyncAccount":
        """Inflate a dict as returned by supabase-py (str UUIDs, str datetimes)."""
        return cls(
            id=UUID(row["id"]),
            user_id=UUID(row["user_id"]),
            provider=row["provider"],
            provider_user_id=row["provider_user_id"],
            access_token=decrypt_token(row["access_token_encrypted"]) or "",
            refresh_token=decrypt_token(row.get("refresh_token_encrypted")),
            expires_at=_parse_dt(row.get("expires_at")),
            scopes=list(row.get("scopes") or []),
            status=row.get("status") or "active",
            last_sync_at=_parse_dt(row.get("last_sync_at")),
            last_sync_status=row.get("last_sync_status"),
            last_error=row.get("last_error"),
            error_count=int(row.get("error_count") or 0),
            auto_import=bool(row.get("auto_import", True)),
            import_strength=bool(row.get("import_strength", True)),
            import_cardio=bool(row.get("import_cardio", True)),
            webhook_id=row.get("webhook_id"),
        )


def _parse_dt(raw: Any) -> Optional[datetime]:
    if raw is None:
        return None
    if isinstance(raw, datetime):
        return raw if raw.tzinfo else raw.replace(tzinfo=timezone.utc)
    # ISO-8601 string from Postgres timestamptz (supabase returns '…+00:00' or '…Z').
    s = str(raw)
    if s.endswith("Z"):
        s = s[:-1] + "+00:00"
    try:
        dt = datetime.fromisoformat(s)
    except ValueError:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt


# ───────────────────────────── Exceptions ──────────────────────────────

class SyncProviderError(RuntimeError):
    """Base error for sync operations.

    Orchestrator catches this and records the message on ``oauth_sync_accounts``
    without bubbling up a raw provider SDK exception (which often contains the
    raw access token in its repr).
    """

    def __init__(self, message: str, *, retriable: bool = False):
        super().__init__(message)
        self.retriable = retriable


class ReauthRequiredError(SyncProviderError):
    """Token is dead — the user must re-run OAuth (e.g. deauthorized)."""

    def __init__(self, message: str = "Re-authentication required"):
        super().__init__(message, retriable=False)


class ProviderRateLimitedError(SyncProviderError):
    """Back off — we hit the provider's rate ceiling for this window."""

    def __init__(self, message: str = "Provider rate limit reached"):
        super().__init__(message, retriable=True)


# ────────────────────────────── Base class ─────────────────────────────

CanonicalRow = Union[CanonicalCardioRow, CanonicalSetRow]


class SyncProvider(abc.ABC):
    """Interface every OAuth sync provider implements.

    Subclasses must set ``provider_slug`` (matches the DB CHECK constraint on
    ``oauth_sync_accounts.provider``).
    """

    provider_slug: str = ""
    supports_webhooks: bool = False
    supports_strength: bool = False   # most pull-sync providers are cardio-only
    default_lookback_days: int = 90

    # ─── OAuth lifecycle ───

    @abc.abstractmethod
    def begin_auth(self, user_id: UUID) -> str:
        """Return the provider's consent URL the client should open.

        Implementations embed a signed ``state`` token encoding (at least)
        ``user_id`` + ``nonce`` so the callback handler can verify origin.
        """

    @abc.abstractmethod
    def exchange_code(self, code: str, state: str) -> TokenBundle:
        """Swap an authorization code for long-lived tokens."""

    @abc.abstractmethod
    def refresh_token(self, account: SyncAccount) -> TokenBundle:
        """Refresh ``account``'s access token using its refresh token.

        Must return a ``TokenBundle`` even if ``refresh_token`` didn't change —
        many providers rotate it on every refresh (Strava, Fitbit do). Orchestrator
        always re-persists whatever comes back, re-encrypting.
        """

    # ─── Data pull ───

    @abc.abstractmethod
    def fetch_since(
        self,
        account: SyncAccount,
        since: datetime,
    ) -> List[CanonicalRow]:
        """Return every activity since ``since`` (tz-aware UTC) as canonical rows.

        Empty list is valid. Row hashes must be stable across calls so the
        orchestrator's upsert dedups re-pulls.
        """

    # ─── Webhooks (optional) ───

    def register_webhook(self, account: SyncAccount) -> Optional[str]:
        """Subscribe to provider push events. Return the subscription ID.

        Default is a no-op for providers without push. Subclasses override.
        """
        return None

    def unregister_webhook(self, account: SyncAccount) -> None:
        """Drop the push subscription. No-op by default."""
        return None

    # ─── Token helpers (available to subclasses) ───

    @staticmethod
    def encrypt_token(plaintext: Optional[str]) -> Optional[str]:
        return encrypt_token(plaintext)

    @staticmethod
    def decrypt_token(ciphertext: Optional[str]) -> Optional[str]:
        return decrypt_token(ciphertext)

    # ─── Utility ───

    def __repr__(self) -> str:
        # Deliberately omit any token material.
        return f"<{self.__class__.__name__} slug={self.provider_slug!r}>"


# ───────────────────────── Provider registry ──────────────────────────

_PROVIDER_REGISTRY: Dict[str, type[SyncProvider]] = {}


def register_provider(slug: str):
    """Decorator that plugs a provider subclass into the registry keyed by slug."""

    def _inner(cls: type[SyncProvider]) -> type[SyncProvider]:
        cls.provider_slug = slug
        _PROVIDER_REGISTRY[slug] = cls
        return cls

    return _inner


def get_provider(slug: str) -> SyncProvider:
    """Instantiate a provider by slug. Raises if the slug isn't registered."""
    cls = _PROVIDER_REGISTRY.get(slug)
    if cls is None:
        # Lazy-trigger module imports — providers self-register on import.
        _eager_import_providers()
        cls = _PROVIDER_REGISTRY.get(slug)
    if cls is None:
        raise SyncProviderError(f"Unknown sync provider slug: {slug!r}")
    return cls()


def list_providers() -> List[str]:
    _eager_import_providers()
    return sorted(_PROVIDER_REGISTRY.keys())


def _eager_import_providers() -> None:
    """Import every provider module so their ``@register_provider`` decorators fire.

    We keep this lazy (only called from ``get_provider`` / ``list_providers``)
    so ``token_encryption.py`` can be imported from the callback endpoint
    without pulling in stravalib etc.
    """
    for mod in ("strava", "garmin", "fitbit", "apple_health", "peloton"):
        try:
            __import__(f"services.sync.{mod}")
        except Exception as e:  # pragma: no cover — logged in prod only
            # Don't blow up the whole sync system if one provider's deps are missing.
            import logging
            logging.getLogger(__name__).warning(
                f"[sync] failed to import provider {mod!r}: {e}"
            )
