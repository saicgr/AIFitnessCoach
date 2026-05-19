#!/usr/bin/env python3
"""
mint_test_tokens.py — Phase C load-test JWT minter
==================================================

Creates N **disposable test users** and writes their freshly-minted Supabase
JWTs to `tokens.txt`, the token pool consumed by `home_flow.js`.

Each test user is a real, fully-formed account so the Home hot path under load
behaves exactly like production traffic:
  1. An `auth.users` row, created via the Supabase service-role admin API.
  2. A linked `public.users` row (core/auth.py's `get_current_user` joins
     `public.users.auth_id` -> the auth user; without this row every request
     would 401 with JWT_USER_DELETED).
  3. A `sign_in_with_password` call to obtain a real access_token (JWT).

All test users share an unmistakable, greppable marker so they are trivial to
clean up afterwards (see "CLEANUP" below):
  * email  : loadtest+<n>-<runid>@zealova-loadtest.invalid
  * name   : "LoadTest User <n>"
  * role   : "user"
  * preferences.loadtest_disposable = True
  * preferences.loadtest_run_id     = <runid>

These accounts are DISPOSABLE. They are NOT real users. Never point this
script at a production database that you are not willing to also clean up.

────────────────────────────────────────────────────────────────────────────
SAFETY
────────────────────────────────────────────────────────────────────────────
  * Reads SUPABASE_URL / SUPABASE_KEY (service-role) from backend/.env.
  * `tokens.txt` is gitignored — it contains live (short-lived) JWTs.
  * The script prints the target Supabase host and requires you to pass
    --yes to proceed, so you cannot mint into the wrong project by reflex.
  * Intended target: your STAGING Supabase project. If staging and prod
    share a project, scope the load test to off-peak and clean up promptly.

────────────────────────────────────────────────────────────────────────────
USAGE
────────────────────────────────────────────────────────────────────────────
  # Mint 200 disposable users + tokens into ./tokens.txt
  python mint_test_tokens.py --count 200 --yes

  # Re-mint fresh JWTs for the SAME users (tokens expire ~1h) without
  # creating new accounts:
  python mint_test_tokens.py --refresh --yes

  # Clean up — delete every disposable user this tool ever created:
  python mint_test_tokens.py --cleanup --yes

Output file format (one entry per line, consumed by home_flow.js):
  <jwt>\t<public_users_id>

────────────────────────────────────────────────────────────────────────────
CLEANUP
────────────────────────────────────────────────────────────────────────────
  python mint_test_tokens.py --cleanup --yes
deletes every public.users + auth.users row whose email ends with
"@zealova-loadtest.invalid". Run this as soon as the load test is finished —
disposable accounts should not linger. The --cleanup path is idempotent.
"""
from __future__ import annotations

import argparse
import logging
import os
import sys
import time
import uuid
from pathlib import Path

# --- Resolve backend/ on sys.path and load .env before importing supabase. ---
_BACKEND = Path(__file__).resolve().parents[2]  # scripts/loadtest -> scripts -> backend
sys.path.insert(0, str(_BACKEND))
try:
    from dotenv import load_dotenv
    load_dotenv(_BACKEND / ".env")
except ImportError:
    pass

logging.basicConfig(level=logging.INFO, format="%(message)s")
log = logging.getLogger("mint_test_tokens")

# Everything disposable shares this email domain — the single cleanup anchor.
LOADTEST_EMAIL_DOMAIN = "zealova-loadtest.invalid"
# A fixed password for all disposable users — they only exist for this test.
LOADTEST_PASSWORD = "LoadTest!Disposable-2026"
TOKENS_FILE = Path(__file__).resolve().parent / "tokens.txt"


def _admin_client():
    """Build a Supabase client with the service-role key (from backend/.env)."""
    from supabase import create_client

    url = os.getenv("SUPABASE_URL")
    key = os.getenv("SUPABASE_KEY")  # service-role
    if not url or not key:
        log.error(
            "SUPABASE_URL / SUPABASE_KEY must be set in backend/.env to mint "
            "test tokens. Aborting."
        )
        sys.exit(1)
    return create_client(url, key), url


def _confirm(target_url: str, action: str, assume_yes: bool) -> None:
    """Print the target host and require explicit confirmation."""
    host = target_url.split("//")[-1].split("/")[0]
    log.info(f"\n  ACTION : {action}")
    log.info(f"  TARGET : {host}")
    log.info(f"  MARKER : *@{LOADTEST_EMAIL_DOMAIN}\n")
    if assume_yes:
        return
    reply = input("  Proceed? Type 'yes' to continue: ").strip().lower()
    if reply != "yes":
        log.info("  Aborted.")
        sys.exit(0)


# ── Iterating disposable users (works around list_users pagination) ──────────

def _iter_disposable_users(admin):
    """Yield every auth.users row whose email is in the loadtest domain.

    admin.auth.admin.list_users() is paginated; walk all pages so cleanup is
    complete even after a large mint run.
    """
    page = 1
    while True:
        try:
            users = admin.auth.admin.list_users(page=page, per_page=200)
        except TypeError:
            # Older supabase-py: list_users() takes no kwargs and returns all.
            users = admin.auth.admin.list_users()
            for u in users:
                if (getattr(u, "email", "") or "").endswith(LOADTEST_EMAIL_DOMAIN):
                    yield u
            return
        if not users:
            return
        for u in users:
            if (getattr(u, "email", "") or "").endswith(LOADTEST_EMAIL_DOMAIN):
                yield u
        if len(users) < 200:
            return
        page += 1


# ── Mint ─────────────────────────────────────────────────────────────────────

def _create_user(admin, index: int, run_id: str) -> tuple[str, str]:
    """Create one disposable auth.users + public.users pair.

    Returns (auth_id, public_users_id).
    """
    email = f"loadtest+{index}-{run_id}@{LOADTEST_EMAIL_DOMAIN}"

    # 1) auth.users row (email pre-confirmed so sign-in works immediately).
    created = admin.auth.admin.create_user(
        {
            "email": email,
            "password": LOADTEST_PASSWORD,
            "email_confirm": True,
        }
    )
    auth_id = str(created.user.id)

    # 2) public.users row — get_current_user joins on this. Shape mirrors the
    #    auth_sync backfill in api/v1/users/auth.py so the row is well-formed.
    public_id = str(uuid.uuid4())
    new_user = {
        "id": public_id,
        "auth_id": auth_id,
        "email": email,
        "name": f"LoadTest User {index}",
        "username": f"loadtest_{run_id}_{index}",
        "role": "user",
        "is_support_user": False,
        "onboarding_completed": True,   # so Home renders fully populated
        "coach_selected": True,
        "paywall_completed": True,
        "fitness_level": "beginner",
        "goals": "[]",
        "equipment": "[]",
        "equipment_v2": [],
        # The cleanup anchor in structured form, in addition to the email domain.
        "preferences": {
            "loadtest_disposable": True,
            "loadtest_run_id": run_id,
        },
        "active_injuries": [],
    }
    admin.table("users").insert(new_user).execute()
    return auth_id, public_id


def _sign_in(admin, index: int, run_id: str) -> str:
    """Sign a disposable user in, return their access_token (JWT)."""
    email = f"loadtest+{index}-{run_id}@{LOADTEST_EMAIL_DOMAIN}"
    res = admin.auth.sign_in_with_password(
        {"email": email, "password": LOADTEST_PASSWORD}
    )
    token = res.session.access_token if res and res.session else None
    if not token:
        raise RuntimeError(f"sign_in returned no access_token for {email}")
    return token


def mint(count: int, assume_yes: bool) -> None:
    admin, url = _admin_client()
    _confirm(url, f"CREATE {count} disposable test users + JWTs", assume_yes)

    run_id = uuid.uuid4().hex[:8]
    log.info(f"  run_id = {run_id}  (used in email + preferences for cleanup)\n")

    lines: list[str] = []
    failures = 0
    for i in range(count):
        try:
            auth_id, public_id = _create_user(admin, i, run_id)
            token = _sign_in(admin, i, run_id)
            lines.append(f"{token}\t{public_id}")
            if (i + 1) % 25 == 0 or i == count - 1:
                log.info(f"  minted {i + 1}/{count}")
        except Exception as e:
            failures += 1
            log.warning(f"  user {i} failed: {e}")
        # Gentle pacing — Supabase Auth admin API is rate-limited.
        time.sleep(0.05)

    if not lines:
        log.error("  No tokens minted — aborting without writing tokens.txt.")
        sys.exit(1)

    _write_tokens(lines, run_id)
    log.info(
        f"\n  DONE. {len(lines)} tokens written to {TOKENS_FILE}"
        f"{f' ({failures} failures)' if failures else ''}."
    )
    log.info(
        "  Tokens expire ~1h. Re-mint with: python mint_test_tokens.py --refresh --yes"
    )
    log.info(
        "  CLEAN UP AFTER THE TEST: python mint_test_tokens.py --cleanup --yes\n"
    )


def refresh(assume_yes: bool) -> None:
    """Re-mint fresh JWTs for the EXISTING disposable users (no new accounts)."""
    admin, url = _admin_client()
    _confirm(url, "RE-MINT JWTs for existing disposable users", assume_yes)

    users = list(_iter_disposable_users(admin))
    if not users:
        log.error(
            "  No disposable users found. Run with --count N first to create them."
        )
        sys.exit(1)

    lines: list[str] = []
    for u in users:
        email = u.email
        try:
            # Look up the public.users id for this auth user.
            res = admin.table("users").select("id").eq("auth_id", str(u.id)).execute()
            if not res.data:
                log.warning(f"  {email}: no public.users row — skipping")
                continue
            public_id = res.data[0]["id"]
            signin = admin.auth.sign_in_with_password(
                {"email": email, "password": LOADTEST_PASSWORD}
            )
            token = signin.session.access_token
            lines.append(f"{token}\t{public_id}")
        except Exception as e:
            log.warning(f"  {email}: refresh failed: {e}")
        time.sleep(0.05)

    if not lines:
        log.error("  No tokens refreshed — tokens.txt left unchanged.")
        sys.exit(1)

    _write_tokens(lines, run_id="refreshed")
    log.info(f"\n  DONE. {len(lines)} refreshed tokens written to {TOKENS_FILE}\n")


def cleanup(assume_yes: bool) -> None:
    """Delete every disposable user this tool ever created. Idempotent."""
    admin, url = _admin_client()
    _confirm(url, "DELETE all disposable load-test users", assume_yes)

    users = list(_iter_disposable_users(admin))
    if not users:
        log.info("  Nothing to clean up — no disposable users found.")
        # Still remove a stale tokens.txt if present.
        if TOKENS_FILE.exists():
            TOKENS_FILE.unlink()
            log.info(f"  Removed stale {TOKENS_FILE}.")
        return

    deleted = 0
    for u in users:
        try:
            # public.users first (FK-safe), then the auth.users row.
            admin.table("users").delete().eq("auth_id", str(u.id)).execute()
            admin.auth.admin.delete_user(str(u.id))
            deleted += 1
        except Exception as e:
            log.warning(f"  {u.email}: delete failed: {e}")
        time.sleep(0.05)

    log.info(f"  Deleted {deleted}/{len(users)} disposable users.")
    if TOKENS_FILE.exists():
        TOKENS_FILE.unlink()
        log.info(f"  Removed {TOKENS_FILE}.")
    log.info("  Cleanup complete.\n")


def _write_tokens(lines: list[str], run_id: str) -> None:
    """Write the token pool file with an explanatory header."""
    header = (
        "# Zealova load-test JWT pool — DISPOSABLE, gitignored, do not commit.\n"
        f"# Generated: {time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())}  run_id={run_id}\n"
        "# Format per line: <jwt>\\t<public_users_id>\n"
        "# Tokens expire ~1h. Re-mint: python mint_test_tokens.py --refresh --yes\n"
        "# Clean up users: python mint_test_tokens.py --cleanup --yes\n"
    )
    TOKENS_FILE.write_text(header + "\n".join(lines) + "\n")


def main() -> None:
    p = argparse.ArgumentParser(
        description="Mint / refresh / clean up disposable load-test JWTs.",
    )
    g = p.add_mutually_exclusive_group(required=True)
    g.add_argument("--count", type=int, help="Create N disposable users + tokens.")
    g.add_argument("--refresh", action="store_true", help="Re-mint JWTs for existing users.")
    g.add_argument("--cleanup", action="store_true", help="Delete all disposable users.")
    p.add_argument("--yes", action="store_true", help="Skip the interactive confirmation.")
    args = p.parse_args()

    if args.cleanup:
        cleanup(args.yes)
    elif args.refresh:
        refresh(args.yes)
    else:
        if args.count < 1:
            log.error("--count must be >= 1")
            sys.exit(1)
        mint(args.count, args.yes)


if __name__ == "__main__":
    main()
