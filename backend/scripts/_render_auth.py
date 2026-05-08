"""Auth helper for the Render-hitting validation harness.

Strategy (in order):
  1. If env var named by `--token-env` (default QA_JWT) is set, use that JWT.
  2. Otherwise, mint a token via the Supabase service-role admin API:
     - Create or fetch an auth.users row for QA_AUTH_EMAIL with QA_AUTH_PASSWORD
       (idempotent — checks list first via admin.list_users()).
     - Patch public.users row (the QA seed user, UUID 0...aa) so its `auth_id`
       column points to that auth user — this is what core/auth.py's
       `get_current_user` joins on.
     - Sign in with password to receive an access_token (JWT) and return it.

Both flows return a `(jwt, supabase_auth_id)` tuple so the caller can log
which path was used.

This file is import-only — does not run anything on import. Call
`obtain_jwt(token_env="QA_JWT")` from the harness.
"""
from __future__ import annotations

import os
import sys
import logging
from pathlib import Path
from typing import Optional, Tuple

# Resolve backend/ on the path so we can import core/* helpers.
_BACKEND = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(_BACKEND))

# Load .env BEFORE supabase client is imported (it reads env at construction).
try:
    from dotenv import load_dotenv  # type: ignore
    load_dotenv(_BACKEND / ".env")
except ImportError:
    pass

from scripts.seed_qa_user import QA_USER_UUID, QA_EMAIL  # noqa: E402

_log = logging.getLogger("_render_auth")

# Synthetic auth-side credentials. Email differs from QA_EMAIL on purpose so
# we don't accidentally collide with anything else seeded — auth.users and
# public.users are linked via `auth_id`, not email.
QA_AUTH_EMAIL = "qa-validation-auth+harness@zealova.app"
QA_AUTH_PASSWORD = "QaHarness!2026-Render-Sweep"


def _admin_client():
    """Build a Supabase client with the service-role key.

    We can't reuse `core.supabase_client.get_supabase()` for sign-in because
    that singleton wraps the service-role gotrue, which doesn't have a
    sign_in_with_password flow exposed the way we want. Build a fresh client
    here using the same env vars.
    """
    from supabase import create_client
    url = os.getenv("SUPABASE_URL")
    key = os.getenv("SUPABASE_KEY")  # service-role
    if not url or not key:
        raise RuntimeError(
            "SUPABASE_URL / SUPABASE_KEY must be set in backend/.env "
            "to mint a JWT for the Render harness."
        )
    return create_client(url, key)


def _ensure_auth_user(admin) -> str:
    """Ensure an auth.users row exists for QA_AUTH_EMAIL. Returns its UUID."""
    # admin.auth.admin.list_users() returns a list of User objects.
    users = admin.auth.admin.list_users()
    for u in users:
        if (getattr(u, "email", None) or "").lower() == QA_AUTH_EMAIL.lower():
            _log.info(f"[render_auth] auth.users row exists: {u.id}")
            return str(u.id)
    # Not found — create.
    created = admin.auth.admin.create_user({
        "email": QA_AUTH_EMAIL,
        "password": QA_AUTH_PASSWORD,
        "email_confirm": True,
    })
    auth_id = str(created.user.id)
    _log.info(f"[render_auth] Created auth.users row: {auth_id}")
    return auth_id


def _link_public_user(admin, auth_id: str) -> None:
    """Patch public.users row so its auth_id points to our synthetic auth user."""
    res = admin.table("users").select("id, auth_id").eq(
        "id", QA_USER_UUID
    ).execute()
    if not res.data:
        raise RuntimeError(
            f"public.users row {QA_USER_UUID} missing — run "
            f"scripts/seed_qa_user.py first."
        )
    current = res.data[0].get("auth_id")
    if current == auth_id:
        return
    admin.table("users").update({"auth_id": auth_id}).eq(
        "id", QA_USER_UUID
    ).execute()
    _log.info(f"[render_auth] Linked public.users.auth_id={auth_id}")


def _mint_jwt() -> Tuple[str, str]:
    """End-to-end: ensure auth user, link public.users, sign in, return JWT."""
    admin = _admin_client()
    auth_id = _ensure_auth_user(admin)
    _link_public_user(admin, auth_id)
    sign_in = admin.auth.sign_in_with_password({
        "email": QA_AUTH_EMAIL, "password": QA_AUTH_PASSWORD,
    })
    token = sign_in.session.access_token
    if not token:
        raise RuntimeError("sign_in_with_password returned no access_token")
    return token, auth_id


def obtain_jwt(token_env: str = "QA_JWT") -> Tuple[str, str]:
    """Public entry point. Returns (jwt, source) where source is 'env' or 'minted'."""
    env_token = os.getenv(token_env, "").strip()
    if env_token:
        _log.info(f"[render_auth] Using JWT from ${token_env}")
        return env_token, "env"
    _log.info(
        f"[render_auth] ${token_env} not set — minting via service-role admin API"
    )
    token, _auth_id = _mint_jwt()
    return token, "minted"


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    tok, src = obtain_jwt()
    print(f"source={src} jwt_prefix={tok[:24]}... len={len(tok)}")
