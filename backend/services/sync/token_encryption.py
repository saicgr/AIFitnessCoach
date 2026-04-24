"""
Standalone Fernet helpers for OAuth token encryption.

Deliberately has **no imports from ``services.sync.oauth_base``** so the OAuth
callback endpoint (``api.v1.oauth_sync``) can encrypt tokens without pulling
in the full sync-provider stack (stravalib, garminconnect, fitbit, …). Those
libraries are heavy and some of them hit the network on import; we don't want
the auth callback path paying that cost.

The key is read from ``OAUTH_TOKEN_ENCRYPTION_KEY`` (base64 urlsafe, as produced
by ``Fernet.generate_key()``). If unset, we hard-fail at first use — never
silently fall back to plaintext storage.

Fernet is AES-128-CBC + HMAC-SHA256 with a random IV per token, so:

    encrypt_token("hello") != encrypt_token("hello")

Always true; the ciphertext embeds the IV and timestamp. This is asserted in
``tests/services/sync/test_token_encryption.py``.
"""
from __future__ import annotations

import os
from functools import lru_cache
from typing import Optional

from cryptography.fernet import Fernet, InvalidToken


class TokenEncryptionError(RuntimeError):
    """Raised when a ciphertext can't be decrypted (bad key / tampered / truncated)."""


@lru_cache(maxsize=1)
def _get_fernet() -> Fernet:
    """Lazily build the Fernet instance from ``OAUTH_TOKEN_ENCRYPTION_KEY``.

    Cached so every encrypt/decrypt call reuses the same key object instead of
    re-parsing the env var 10× per request.
    """
    key = os.environ.get("OAUTH_TOKEN_ENCRYPTION_KEY")
    if not key:
        raise RuntimeError(
            "OAUTH_TOKEN_ENCRYPTION_KEY env var is not set. "
            "Generate one with: python -c 'from cryptography.fernet import Fernet; "
            "print(Fernet.generate_key().decode())'"
        )
    # Accept both str and already-bytes keys.
    if isinstance(key, str):
        key_bytes = key.encode("ascii")
    else:
        key_bytes = key
    try:
        return Fernet(key_bytes)
    except ValueError as e:
        raise RuntimeError(
            f"OAUTH_TOKEN_ENCRYPTION_KEY is malformed ({e}). Must be a urlsafe "
            "base64-encoded 32-byte key from Fernet.generate_key()."
        )


def encrypt_token(plaintext: Optional[str]) -> Optional[str]:
    """Encrypt ``plaintext`` with the configured Fernet key. None in → None out.

    Returns the ciphertext as a str (urlsafe base64) suitable for a Postgres
    TEXT column. Never log the return value against a known plaintext.
    """
    if plaintext is None:
        return None
    if not isinstance(plaintext, str):
        raise TypeError(
            f"encrypt_token expects str, got {type(plaintext).__name__}"
        )
    return _get_fernet().encrypt(plaintext.encode("utf-8")).decode("ascii")


def decrypt_token(ciphertext: Optional[str]) -> Optional[str]:
    """Decrypt a ciphertext produced by :func:`encrypt_token`. None in → None out.

    Raises :class:`TokenEncryptionError` on bad ciphertext so the caller can
    decide whether to force a re-auth (most likely) or surface as 500.
    """
    if ciphertext is None:
        return None
    if not isinstance(ciphertext, str):
        raise TypeError(
            f"decrypt_token expects str, got {type(ciphertext).__name__}"
        )
    try:
        return _get_fernet().decrypt(ciphertext.encode("ascii")).decode("utf-8")
    except InvalidToken as e:
        # Don't echo the token in the exception — callers log this and we
        # don't want ciphertext material leaking into logs.
        raise TokenEncryptionError(
            "Token decryption failed — key rotated or ciphertext tampered with."
        ) from e


def generate_encryption_key() -> str:
    """Helper for ops / CI: generate a new Fernet key. Not used at runtime."""
    return Fernet.generate_key().decode("ascii")


def reset_cache_for_tests() -> None:
    """Drop the cached Fernet instance so tests can swap the env var mid-run."""
    _get_fernet.cache_clear()
