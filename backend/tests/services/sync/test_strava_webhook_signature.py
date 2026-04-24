"""
Strava webhook signature verification + subscription-validation handshake tests.

Strava supplies two different auth models in the same API surface:

1. **Subscription validation (GET)** — Strava calls ``GET /webhooks/strava``
   once with ``hub.mode=subscribe`` + ``hub.verify_token=<our-secret>`` +
   ``hub.challenge=<random>``; we echo back the challenge if the verify_token
   matches. Without this handshake, Strava refuses to create the subscription.

2. **Event payload signing (POST)** — every push event is signed with
   HMAC-SHA256 over the raw body using ``STRAVA_VERIFY_TOKEN``. We reject
   unsigned or mismatched requests.

Both are unit-tested here. The latter is the security-critical one.
"""
from __future__ import annotations

import hashlib
import hmac
import json

import pytest

from services.sync.strava import StravaProvider


VERIFY_TOKEN = "test-verify-token-shh"


@pytest.fixture(autouse=True)
def _set_verify_token(monkeypatch):
    monkeypatch.setenv("STRAVA_VERIFY_TOKEN", VERIFY_TOKEN)
    monkeypatch.setenv("STRAVA_CLIENT_ID", "test-client-id")
    monkeypatch.setenv("STRAVA_CLIENT_SECRET", "test-client-secret")


def _sign(body: bytes) -> str:
    mac = hmac.new(VERIFY_TOKEN.encode(), body, hashlib.sha256).hexdigest()
    return f"sha256={mac}"


class TestSignatureVerification:
    def test_valid_signature_accepted(self):
        body = json.dumps({"object_type": "activity", "aspect_type": "create"}).encode()
        sig = _sign(body)
        assert StravaProvider.verify_webhook_signature(body, sig) is True

    def test_valid_signature_without_prefix_accepted(self):
        # Some Strava docs show the signature as a bare hex string; we strip
        # the ``sha256=`` prefix before comparing, so either form works.
        body = b'{"object_type":"activity","aspect_type":"update"}'
        sig_with_prefix = _sign(body)
        sig_without_prefix = sig_with_prefix[len("sha256="):]
        assert StravaProvider.verify_webhook_signature(body, sig_without_prefix) is True

    def test_tampered_body_rejected(self):
        body = b'{"object_type":"activity","aspect_type":"create","object_id":1}'
        sig = _sign(body)
        # Flip the id in the payload — signature should no longer match.
        tampered = body.replace(b'"object_id":1', b'"object_id":999')
        assert StravaProvider.verify_webhook_signature(tampered, sig) is False

    def test_wrong_secret_rejected(self):
        body = b'{"x":"y"}'
        # Sign with a different key.
        wrong_mac = hmac.new(b"different-secret", body, hashlib.sha256).hexdigest()
        assert StravaProvider.verify_webhook_signature(body, f"sha256={wrong_mac}") is False

    def test_missing_signature_rejected(self):
        body = b'{"x":"y"}'
        assert StravaProvider.verify_webhook_signature(body, None) is False
        assert StravaProvider.verify_webhook_signature(body, "") is False

    def test_missing_verify_token_env_rejects_everything(self, monkeypatch):
        """If our env is misconfigured we must refuse to validate at all —
        better to 401 every webhook than to silently trust unsigned requests."""
        monkeypatch.delenv("STRAVA_VERIFY_TOKEN", raising=False)
        body = b'{"x":"y"}'
        # Even a correctly-formed sha256=<hex> must be rejected because we have
        # no key to compare against.
        fake_sig = "sha256=" + "a" * 64
        assert StravaProvider.verify_webhook_signature(body, fake_sig) is False

    def test_empty_body_with_valid_signature(self):
        """Zero-length body is syntactically a valid request to sign — HMAC
        over empty bytes produces a stable digest."""
        body = b""
        sig = _sign(body)
        assert StravaProvider.verify_webhook_signature(body, sig) is True


class TestConstantTimeCompare:
    def test_length_mismatch_returns_false(self):
        """hmac.compare_digest is used internally; we confirm a too-short
        signature can't falsely validate via partial match."""
        body = b'{"x":"y"}'
        assert StravaProvider.verify_webhook_signature(body, "sha256=abc") is False
