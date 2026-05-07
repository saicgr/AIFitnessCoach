"""Apple Sign-In token revocation.

Apple requires apps that offer "Sign in with Apple" to revoke the user's
refresh token on account deletion (App Store Review Guideline 5.1.1.v,
enforced since June 30, 2022). Failure to do so is a known rejection
trigger.

Flow:
  1. Build a client_secret JWT signed with the Apple private key (.p8) using
     ES256, with iss=team_id, aud=appleid.apple.com, sub=services_id.
  2. POST to https://appleid.apple.com/auth/revoke with client_id,
     client_secret, token (refresh_token preferred; access_token also
     accepted), token_type_hint.

Required env vars (set in Render dashboard before submission):
  - APPLE_TEAM_ID            (e.g. G9RL26P89Q)
  - APPLE_SERVICES_ID        (e.g. com.zealova.app — the bundle ID is the
                              client_id when revocation comes from a native
                              iOS app authenticated with the bundle)
  - APPLE_KEY_ID             (10-char Key ID from developer.apple.com → Keys)
  - APPLE_PRIVATE_KEY        (full PEM contents of the .p8 file, with
                              -----BEGIN/END PRIVATE KEY----- markers,
                              newlines preserved or escaped as \\n)

If any are missing the function logs a warning and returns False — account
deletion still proceeds (we never want to block a user from deleting their
account just because the Apple revoke endpoint is misconfigured).
"""

from __future__ import annotations

import logging
import os
import time
from typing import Optional

import httpx
import jwt

logger = logging.getLogger(__name__)

APPLE_REVOKE_URL = "https://appleid.apple.com/auth/revoke"
APPLE_TOKEN_URL = "https://appleid.apple.com/auth/token"
APPLE_AUDIENCE = "https://appleid.apple.com"


async def exchange_authorization_code(authorization_code: str) -> Optional[str]:
    """Exchange a short-lived Apple authorization_code for a refresh_token.

    Called once on first Apple Sign-In. The returned refresh_token is
    long-lived (until the user revokes via Settings → Apple ID → Sign In
    With Apple) and is what we hand to /auth/revoke on account deletion.
    Returns None on any failure — never raises.
    """
    if not authorization_code:
        return None
    client_secret = _build_client_secret()
    if not client_secret:
        return None
    services_id = os.getenv("APPLE_SERVICES_ID", "")
    data = {
        "client_id": services_id,
        "client_secret": client_secret,
        "code": authorization_code,
        "grant_type": "authorization_code",
    }
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.post(
                APPLE_TOKEN_URL,
                data=data,
                headers={"Content-Type": "application/x-www-form-urlencoded"},
            )
        if resp.status_code == 200:
            payload = resp.json()
            refresh = payload.get("refresh_token")
            if refresh:
                logger.info("[AppleRevoke] Stored refresh_token for client_id=%s", services_id)
            return refresh
        logger.warning(
            "[AppleRevoke] /auth/token exchange returned %s: %s",
            resp.status_code, resp.text,
        )
        return None
    except Exception as e:
        logger.error("[AppleRevoke] /auth/token exchange failed: %s", e)
        return None


def _build_client_secret() -> Optional[str]:
    team_id = os.getenv("APPLE_TEAM_ID")
    services_id = os.getenv("APPLE_SERVICES_ID")
    key_id = os.getenv("APPLE_KEY_ID")
    private_key = os.getenv("APPLE_PRIVATE_KEY")

    if not (team_id and services_id and key_id and private_key):
        logger.warning(
            "[AppleRevoke] Missing Apple Sign-In env vars; skipping token "
            "revocation. team=%s services=%s key=%s private_key=%s",
            bool(team_id), bool(services_id), bool(key_id), bool(private_key),
        )
        return None

    # Allow the private key to be supplied with literal \n escapes (Render's
    # multi-line env var UI mangles real newlines).
    private_key = private_key.replace("\\n", "\n")

    now = int(time.time())
    payload = {
        "iss": team_id,
        "iat": now,
        "exp": now + 60 * 60,  # 1h — well under Apple's 6-month max
        "aud": APPLE_AUDIENCE,
        "sub": services_id,
    }
    try:
        return jwt.encode(
            payload,
            private_key,
            algorithm="ES256",
            headers={"kid": key_id, "alg": "ES256"},
        )
    except Exception as e:
        logger.error("[AppleRevoke] Failed to sign client_secret JWT: %s", e)
        return None


async def revoke_apple_token(
    refresh_token: Optional[str],
    access_token: Optional[str] = None,
) -> bool:
    """Best-effort revocation of an Apple Sign-In token.

    Prefers the refresh_token (revokes the entire grant); falls back to
    access_token if that's all we have. Returns True on Apple HTTP 200,
    False otherwise. Never raises — account deletion must not be blocked
    by a transient Apple outage.
    """
    token = refresh_token or access_token
    token_type_hint = "refresh_token" if refresh_token else "access_token"
    if not token:
        logger.info("[AppleRevoke] No Apple token available to revoke")
        return False

    client_secret = _build_client_secret()
    if not client_secret:
        return False

    services_id = os.getenv("APPLE_SERVICES_ID", "")
    data = {
        "client_id": services_id,
        "client_secret": client_secret,
        "token": token,
        "token_type_hint": token_type_hint,
    }

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.post(
                APPLE_REVOKE_URL,
                data=data,
                headers={"Content-Type": "application/x-www-form-urlencoded"},
            )
        if resp.status_code == 200:
            logger.info(
                "[AppleRevoke] Successfully revoked Apple %s for client_id=%s",
                token_type_hint, services_id,
            )
            return True
        logger.warning(
            "[AppleRevoke] Apple revoke returned %s: %s",
            resp.status_code, resp.text,
        )
        return False
    except Exception as e:
        logger.error("[AppleRevoke] Revoke request failed: %s", e)
        return False
