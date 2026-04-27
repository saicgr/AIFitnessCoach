"""HMAC-signed consent session tokens.

When a client hits /oauth/authorize we need to carry the authorization
request across the hop to zealova.com (consent UI) and back. Rather than
adding another DB table, we pack everything into a short-lived signed
token. The consent UI treats it as opaque.

Shape: base64url(json_payload) + '.' + base64url(hmac_sha256(key, payload))
"""
import base64
import hashlib
import hmac
import json
from datetime import datetime, timezone
from typing import Optional

from mcp.config import get_mcp_config

_cfg = get_mcp_config()


def _sign(payload_b64: bytes) -> bytes:
    key = _cfg.TOKEN_PEPPER.encode("utf-8")
    return hmac.new(key, payload_b64, hashlib.sha256).digest()


def _b64url_encode(raw: bytes) -> str:
    return base64.urlsafe_b64encode(raw).rstrip(b"=").decode("ascii")


def _b64url_decode(s: str) -> bytes:
    padding = "=" * (-len(s) % 4)
    return base64.urlsafe_b64decode(s + padding)


def encode(payload: dict, *, ttl_sec: int = 600) -> str:
    body = dict(payload)
    body["exp"] = int(datetime.now(timezone.utc).timestamp()) + ttl_sec
    payload_bytes = json.dumps(body, separators=(",", ":"), sort_keys=True).encode("utf-8")
    payload_b64 = _b64url_encode(payload_bytes)
    sig_b64 = _b64url_encode(_sign(payload_b64.encode("ascii")))
    return f"{payload_b64}.{sig_b64}"


def decode(token: str) -> Optional[dict]:
    """Verify signature and expiry. Returns payload dict or None."""
    try:
        payload_b64, sig_b64 = token.split(".", 1)
    except ValueError:
        return None

    expected_sig = _sign(payload_b64.encode("ascii"))
    try:
        provided_sig = _b64url_decode(sig_b64)
    except Exception:
        return None

    if not hmac.compare_digest(expected_sig, provided_sig):
        return None

    try:
        payload = json.loads(_b64url_decode(payload_b64))
    except (ValueError, json.JSONDecodeError):
        return None

    exp = payload.get("exp")
    if not isinstance(exp, int) or exp < int(datetime.now(timezone.utc).timestamp()):
        return None

    return payload
