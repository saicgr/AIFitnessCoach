"""
Referral + share-link service — Workstream F growth loops (F5, F8).

Self-hosted deferred-deep-link infrastructure. NO hard dependency on an external
Branch / OneLink / Firebase Dynamic Links account (Firebase Dynamic Links is
sunset). We mint short tokens stored in `share_links` and resolve them at
`GET /s/{token}` -> a deep-link payload + web fallback. A clearly-marked seam
(`_external_link_provider`) is left where Branch/OneLink keys would plug in
later for true cross-install attribution.

Capabilities:
  F5  referral codes (per-user, reuse existing `referral_tracking` table from
      migration 164) + a two-sided attribution record created on signup +
      a reward seam wired to the existing RevenueCat path.
  F8  "do my workout" / "try this recipe" share links. Resolving a workout link
      returns the workout SCALED to the requesting user's fitness_level, reusing
      the existing deterministic transform in
      services.workout.variant_generator (NO new generation, NO LLM).

Deep-link scheme: the app uses `zealova://` (see plan_share_link.py / app_links).
Web fallback host: settings.web_marketing_url (https://zealova.com).
"""
from __future__ import annotations

import random
import string
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from core.config import get_settings
from core.db.facade import get_supabase_db
from core.logger import get_logger

logger = get_logger(__name__)
_settings = get_settings()

# Token alphabet — unambiguous (no 0/o/1/l) for hand-typed / QR codes.
_TOKEN_ALPHABET = "abcdefghijkmnpqrstuvwxyz23456789"

# Custom URL scheme for the secondary `deep_link` field. The PRIMARY share
# target is always the https app-link (web_url = https://zealova.com/s/{token}),
# which is host-verified on both platforms (AndroidManifest applinks +
# iOS associated domains) AND is its own web fallback. `fitwiz` is the LOCKED
# primary custom scheme (mobile/flutter/lib/core/constants/branding.dart ::
# deepLinkScheme — the router is wired around it); `zealova` is also registered.
# Override via env SHARE_DEEP_LINK_SCHEME if the locked scheme ever changes.
import os as _os
DEEP_LINK_SCHEME = _os.getenv("SHARE_DEEP_LINK_SCHEME", "fitwiz")


def _web_base() -> str:
    return (_settings.web_marketing_url or "https://zealova.com").rstrip("/")


def _gen_token(n: int = 8) -> str:
    return "".join(random.choices(_TOKEN_ALPHABET, k=n))


# --------------------------------------------------------------------------- #
# External provider seam (Branch / OneLink). Currently a no-op pass-through.
# --------------------------------------------------------------------------- #
def _external_link_provider(token: str, deep_link: str, web_fallback: str) -> str:
    """SEAM: if a Branch/OneLink key is configured, mint a true deferred-deep-link
    here and return that URL instead of our self-hosted one. Until then we return
    the self-hosted web fallback (which itself redirects to the app or store).

    To plug in Branch later:
        key = os.getenv("BRANCH_KEY")
        if key: return branch_create_link(key, data={...}, fallback=web_fallback)
    """
    return web_fallback


# --------------------------------------------------------------------------- #
# Share-link minting + resolution (shared by F5 referral and F8 workout/recipe).
# --------------------------------------------------------------------------- #
def _mint_link(
    *, kind: str, user_id: Optional[str], payload: Dict[str, Any],
    referral_code: Optional[str] = None,
) -> Dict[str, str]:
    db = get_supabase_db()
    for _ in range(6):  # token-collision retry
        token = _gen_token()
        try:
            db.client.table("share_links").insert(
                {
                    "token": token,
                    "kind": kind,
                    "user_id": user_id,
                    "payload": payload,
                    "referral_code": referral_code,
                }
            ).execute()
            break
        except Exception as e:
            if "duplicate" in str(e).lower() or "unique" in str(e).lower():
                continue
            raise
    else:
        raise RuntimeError("Could not mint a unique share-link token")

    web = f"{_web_base()}/s/{token}"
    deep = f"{DEEP_LINK_SCHEME}://s/{token}"
    share_url = _external_link_provider(token, deep, web)
    return {"token": token, "web_url": web, "deep_link": deep, "share_url": share_url}


def resolve_link(token: str) -> Dict[str, Any]:
    """Resolve a share token to its deep-link payload + web fallback. Increments
    a click counter. Returns the row's kind + payload so the caller (web /s/
    handler) can redirect; the app reads the same payload via its deep-link
    handler for deferred attribution."""
    db = get_supabase_db()
    row = (
        db.client.table("share_links").select("*").eq("token", token).limit(1).execute()
    )
    if not row.data:
        raise KeyError("Unknown share token")
    link = row.data[0]
    # best-effort click increment
    try:
        db.client.table("share_links").update({"clicks": int(link.get("clicks") or 0) + 1}) \
            .eq("token", token).execute()
    except Exception:
        pass
    return {
        "token": token,
        "kind": link["kind"],
        "payload": link.get("payload") or {},
        "referral_code": link.get("referral_code"),
        "deep_link": f"{DEEP_LINK_SCHEME}://s/{token}",
        "web_fallback": f"{_web_base()}/s/{token}",
        # Store fallback so a non-installed user lands on the store with the
        # token preserved (the app reads it post-install = deferred deep link).
        "store_fallback": f"{_web_base()}/download?ref={token}",
    }


# --------------------------------------------------------------------------- #
# F5 — referral codes (reuse referral_tracking from migration 164).
# --------------------------------------------------------------------------- #
def get_or_create_referral_code(user_id: str) -> str:
    """Idempotent per-user referral code, persisted on users.referral_code."""
    db = get_supabase_db()
    row = db.client.table("users").select("referral_code").eq("id", user_id).limit(1).execute()
    if row.data and row.data[0].get("referral_code"):
        return row.data[0]["referral_code"]

    for _ in range(6):
        code = _gen_token(6).upper()
        try:
            db.client.table("users").update({"referral_code": code}).eq("id", user_id).execute()
            # verify uniqueness (the partial unique index will have rejected a dup)
            return code
        except Exception as e:
            if "duplicate" in str(e).lower() or "unique" in str(e).lower():
                continue
            raise
    raise RuntimeError("Could not allocate a referral code")


def get_referral_link(user_id: str) -> Dict[str, Any]:
    """F5 — referral code + a shareable deferred-deep-link carrying the code."""
    code = get_or_create_referral_code(user_id)
    link = _mint_link(kind="referral", user_id=user_id, payload={"code": code}, referral_code=code)
    return {"referral_code": code, **link}


def record_referral_signup(*, referral_code: str, new_user_id: str) -> Dict[str, Any]:
    """F5 two-sided attribution: called on signup when the installer arrived via a
    referral code (resolved from a deferred deep link). Creates a pending
    referral_tracking row linking referrer -> referred. Idempotent on
    (referrer_id, referred_id)."""
    db = get_supabase_db()
    referrer = (
        db.client.table("users").select("id").eq("referral_code", referral_code).limit(1).execute()
    )
    if not referrer.data:
        raise KeyError("Unknown referral code")
    referrer_id = referrer.data[0]["id"]
    if referrer_id == new_user_id:
        raise ValueError("Self-referral is not allowed")

    db.client.table("referral_tracking").upsert(
        {
            "referrer_id": referrer_id,
            "referred_id": new_user_id,
            "referral_code": referral_code,
            "status": "signup_complete",
            "updated_at": datetime.now(timezone.utc).isoformat(),
        },
        on_conflict="referrer_id,referred_id",
    ).execute()
    logger.info(f"\U0001f91d [Referral] signup attributed: {referrer_id[:8]}… ← {new_user_id[:8]}…")
    return {"referrer_id": referrer_id, "referred_id": new_user_id, "status": "signup_complete"}


def mark_referral_subscribed(referred_user_id: str) -> Optional[Dict[str, Any]]:
    """Reward seam wired to the RevenueCat entitlement path.

    INTEGRATION POINT (owned by the subscriptions area, not this stream): call
    this from `_handle_initial_purchase` in
    `backend/api/v1/subscriptions/webhooks.py` immediately AFTER the
    `user_subscriptions` upsert (currently webhooks.py:160), e.g.:

        try:
            from services.referral_service import mark_referral_subscribed
            mark_referral_subscribed(user_id)
        except Exception:
            pass  # fail-open — never block entitlement on referral bookkeeping

    Flips the referred user's referral row to 'qualified' and records the pending
    two-sided reward. The actual entitlement credit is granted through the
    existing RevenueCat/user_subscriptions path — we only record the pending
    reward here for a later grant (a reward-fulfilment cron / manual grant reads
    `referral_tracking.status='qualified'`).
    """
    db = get_supabase_db()
    row = (
        db.client.table("referral_tracking").select("*")
        .eq("referred_id", referred_user_id)
        .in_("status", ["pending", "signup_complete", "workouts_complete"])
        .limit(1)
        .execute()
    )
    if not row.data:
        return None
    r = row.data[0]
    db.client.table("referral_tracking").update(
        {
            "subscribed": True,
            "status": "qualified",
            "last_milestone": "subscribed",
            "updated_at": datetime.now(timezone.utc).isoformat(),
        }
    ).eq("id", r["id"]).execute()
    logger.info(f"\U0001f3af [Referral] reward pending for referrer={r['referrer_id'][:8]}…")
    return {"referrer_id": r["referrer_id"], "status": "qualified"}


# --------------------------------------------------------------------------- #
# F8 — "do my workout" / "try this recipe" links + level-scaled resolution.
# --------------------------------------------------------------------------- #
# Map a user's fitness_level -> the existing variant_generator intensity profile.
# advanced keeps the source as-is (no scale-down).
_LEVEL_TO_PROFILE = {
    "beginner": "deload",
    "novice": "deload",
    "intermediate": "moderate",
    "advanced": None,     # no down-scaling
    "expert": None,
    "elite": None,
}


def create_workout_link(*, user_id: str, workout_id: str) -> Dict[str, Any]:
    """F8 — shareable deep link to a workout. Resolving it (by a different user)
    returns the workout scaled to their level."""
    link = _mint_link(kind="workout", user_id=user_id, payload={"workout_id": workout_id})
    return {"workout_id": workout_id, **link}


def create_recipe_link(*, user_id: str, recipe_id: str) -> Dict[str, Any]:
    """F8 — shareable deep link to a recipe/meal to log."""
    link = _mint_link(kind="recipe", user_id=user_id, payload={"recipe_id": recipe_id})
    return {"recipe_id": recipe_id, **link}


def _user_level(user_id: str) -> str:
    db = get_supabase_db()
    row = db.client.table("users").select("fitness_level").eq("id", user_id).limit(1).execute()
    if row.data and row.data[0].get("fitness_level"):
        return str(row.data[0]["fitness_level"]).lower()
    return "intermediate"


def resolve_workout_for_user(*, token: str, requesting_user_id: str) -> Dict[str, Any]:
    """F8 — resolve a workout-link token and return the workout SCALED to the
    requesting user's fitness level. Reuses the deterministic transform in
    services.workout.variant_generator (no LLM, no new generation)."""
    info = resolve_link(token)
    if info["kind"] != "workout":
        raise ValueError(f"Token is a '{info['kind']}' link, not a workout link")
    workout_id = (info["payload"] or {}).get("workout_id")
    if not workout_id:
        raise KeyError("Workout link has no workout_id")

    db = get_supabase_db()
    wrow = (
        db.client.table("workouts")
        .select("id, name, type, difficulty, exercises_json, duration_minutes, estimated_calories, warmup_json, stretch_json")
        .eq("id", workout_id).limit(1).execute()
    )
    if not wrow.data:
        raise KeyError("Workout not found")
    workout = wrow.data[0]

    level = _user_level(requesting_user_id)
    profile_key = _LEVEL_TO_PROFILE.get(level)

    scaled = dict(workout)
    scaled["scaled_for_level"] = level
    if profile_key:
        from services.workout.variant_generator import _PROFILES, _transform_exercise

        profile = _PROFILES[profile_key]
        exercises = workout.get("exercises_json") or []
        if isinstance(exercises, list):
            scaled["exercises_json"] = [
                _transform_exercise(ex, profile) if isinstance(ex, dict) else ex
                for ex in exercises
            ]
        dur = workout.get("duration_minutes")
        if isinstance(dur, (int, float)):
            scaled["duration_minutes"] = round(dur * profile["duration_multiplier"])
        scaled["intensity_label"] = profile["label"]
    else:
        scaled["intensity_label"] = "As prescribed"

    return {
        "workout": scaled,
        "scaled_for_level": level,
        "source_workout_id": workout_id,
        "requires_install": True,  # new user must install (deferred deep link via F5)
    }
