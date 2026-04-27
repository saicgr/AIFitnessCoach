"""Single source of truth for brand identity in the Zealova backend.

To rename the app: edit this file ONLY (plus the matching Flutter
`lib/core/constants/branding.dart` and web `frontend/src/lib/branding.ts`).
Most values are env-overridable so production deployments can swap branding
without code changes.

LOCKED identifiers (PACKAGE_ID_*, DEEP_LINK_SCHEME) must never change
post-launch — changing them breaks installs, subscriptions, share/widget
links on existing user devices.
"""
from __future__ import annotations

import os

# ── Identity ──────────────────────────────────────────────────────────────
APP_NAME: str = "Zealova"
APP_FULL_TITLE: str = "Zealova: Workout & Meal Coach"
APP_TAGLINE: str = "Workout & Meal Coach"

# ── Contact / domains (env-overridable) ───────────────────────────────────
WEBSITE_URL: str = os.getenv("FITWIZ_WEBSITE_URL", "https://zealova.com")
MARKETING_DOMAIN: str = os.getenv("FITWIZ_MARKETING_DOMAIN", "zealova.com")
SUPPORT_EMAIL: str = os.getenv("FITWIZ_SUPPORT_EMAIL", "support@zealova.com")
PRIVACY_EMAIL: str = os.getenv("FITWIZ_PRIVACY_EMAIL", "privacy@zealova.com")

# Resend "From" header — primary source is the existing RESEND_FROM_EMAIL env
# var; falls back to a derived literal only if that env var is missing.
FROM_EMAIL: str = os.getenv(
    "RESEND_FROM_EMAIL",
    f"{APP_NAME} <hello@{MARKETING_DOMAIN}>",
)

# ── Share / upgrade URLs (derived) ────────────────────────────────────────
PLAN_SHARE_BASE: str = f"{WEBSITE_URL}/p"
WORKOUT_SHARE_BASE: str = f"{WEBSITE_URL}/w"
RECIPE_SHARE_BASE: str = f"{WEBSITE_URL}/r"
INVITE_BASE: str = f"{WEBSITE_URL}/invite"
UPGRADE_URL: str = f"{WEBSITE_URL}/upgrade"

# ── Social (mirror Flutter AppLinks) ──────────────────────────────────────
INSTAGRAM_URL: str = "https://instagram.com/getzealova"
DISCORD_URL: str = "https://discord.gg/WAYNZpVgsK"

# ── Locked identifiers (informational; never change post-launch) ──────────
PACKAGE_ID_ANDROID: str = "com.aifitnesscoach.app"
PACKAGE_ID_IOS: str = "com.aifitnesscoach.app"
DEEP_LINK_SCHEME: str = "fitwiz"

# ── Derived labels ────────────────────────────────────────────────────────
OPENAPI_TITLE: str = f"{APP_NAME} API"
SUPPORT_USER_NAME: str = f"{APP_NAME} Support"

# ── Merch (locked if user has merch already in DB; otherwise dynamic) ─────
MERCH_PRODUCT_PREFIX: str = APP_NAME  # e.g. "Zealova T-Shirt", "Zealova Hoodie"
