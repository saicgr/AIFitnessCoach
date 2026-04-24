"""
Round-trip + invariant tests for the Fernet token helpers.

Things we actually assert:
1. ``decrypt_token(encrypt_token(x)) == x``  for every reasonable x, including
   empty string, unicode, and long tokens (Strava access tokens are ~40 chars;
   HealthKit device-bridge marker is longer).
2. Calling ``encrypt_token`` twice on the **same plaintext** returns different
   ciphertexts — Fernet randomizes the IV on every call. If this regressed
   we'd leak equality information to anyone who reads the DB.
3. Tampering a ciphertext by one character raises :class:`TokenEncryptionError`
   (not a plain ``InvalidToken`` — we wrap it to avoid ciphertext-in-logs).
4. ``None`` in → ``None`` out on both sides, no exception.
5. Calling without ``OAUTH_TOKEN_ENCRYPTION_KEY`` set is a hard failure — we
   never silently fall back to plaintext.
"""
from __future__ import annotations

import os

import pytest
from cryptography.fernet import Fernet

from services.sync import token_encryption
from services.sync.token_encryption import (
    TokenEncryptionError,
    decrypt_token,
    encrypt_token,
    generate_encryption_key,
)


@pytest.fixture(autouse=True)
def _set_encryption_key(monkeypatch):
    """Every test gets a fresh Fernet key and a cleared cache."""
    key = Fernet.generate_key().decode()
    monkeypatch.setenv("OAUTH_TOKEN_ENCRYPTION_KEY", key)
    token_encryption.reset_cache_for_tests()
    yield
    token_encryption.reset_cache_for_tests()


class TestRoundTrip:
    def test_ascii_plaintext_roundtrips(self):
        assert decrypt_token(encrypt_token("hello")) == "hello"

    def test_empty_string_roundtrips(self):
        assert decrypt_token(encrypt_token("")) == ""

    def test_unicode_plaintext_roundtrips(self):
        # Exercise the utf-8 path — Strava usernames in some locales can include
        # non-ASCII characters in the token scope string.
        plaintext = "tökên-日本語-🔐-strava"
        assert decrypt_token(encrypt_token(plaintext)) == plaintext

    def test_long_plaintext_roundtrips(self):
        # OAuth2 access tokens are usually ~40 chars, but some (Garmin session
        # blobs) can be several hundred bytes. Make sure we're not silently
        # truncating.
        plaintext = "x" * 4000
        assert decrypt_token(encrypt_token(plaintext)) == plaintext


class TestInvariants:
    def test_encryption_is_nondeterministic(self):
        """Same plaintext → different ciphertext every call. Fernet's IV is random."""
        a = encrypt_token("same plaintext")
        b = encrypt_token("same plaintext")
        assert a != b, "Fernet must randomize IV; if this fails we leak equality"

    def test_tampered_ciphertext_raises(self):
        ct = encrypt_token("keep-me-secret")
        assert ct is not None
        # Flip a single character.
        tampered = ("A" if ct[0] != "A" else "B") + ct[1:]
        with pytest.raises(TokenEncryptionError):
            decrypt_token(tampered)

    def test_none_passes_through_both_sides(self):
        assert encrypt_token(None) is None
        assert decrypt_token(None) is None

    def test_wrong_type_raises(self):
        with pytest.raises(TypeError):
            encrypt_token(12345)            # type: ignore[arg-type]
        with pytest.raises(TypeError):
            decrypt_token(b"some bytes")    # type: ignore[arg-type]


class TestKeyConfig:
    def test_missing_env_var_is_hard_fail(self, monkeypatch):
        monkeypatch.delenv("OAUTH_TOKEN_ENCRYPTION_KEY", raising=False)
        token_encryption.reset_cache_for_tests()
        with pytest.raises(RuntimeError, match="OAUTH_TOKEN_ENCRYPTION_KEY"):
            encrypt_token("anything")

    def test_malformed_key_raises(self, monkeypatch):
        monkeypatch.setenv("OAUTH_TOKEN_ENCRYPTION_KEY", "not-a-real-fernet-key")
        token_encryption.reset_cache_for_tests()
        with pytest.raises(RuntimeError, match="malformed"):
            encrypt_token("anything")

    def test_generate_encryption_key_is_valid(self):
        # Smoke: the helper we document for ops should produce keys that work.
        key = generate_encryption_key()
        os.environ["OAUTH_TOKEN_ENCRYPTION_KEY"] = key
        token_encryption.reset_cache_for_tests()
        assert decrypt_token(encrypt_token("hi")) == "hi"


class TestKeyRotation:
    def test_new_key_cannot_decrypt_old_ciphertext(self, monkeypatch):
        """Rotating the Fernet key invalidates existing ciphertexts. The error
        path must surface :class:`TokenEncryptionError` so the sync orchestrator
        can flip the account to ``status='expired'`` and prompt the user."""
        ct = encrypt_token("my-access-token")
        # Rotate to a new key.
        new_key = Fernet.generate_key().decode()
        monkeypatch.setenv("OAUTH_TOKEN_ENCRYPTION_KEY", new_key)
        token_encryption.reset_cache_for_tests()
        with pytest.raises(TokenEncryptionError):
            decrypt_token(ct)
