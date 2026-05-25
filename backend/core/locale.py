"""
Locale resolution utilities for Zealova backend.

Parses Accept-Language headers, maps codes to native names, persists
and reads back the user's preferred locale from the `users` table.

Two independent locale tracks:
  - preferred_locale  — app UI language (from Accept-Language header)
  - chat_locale       — AI Coach reply language (from X-Chat-Locale header)
                        Null in DB = fall back to preferred_locale.

Usage:
    from core.locale import (
        parse_accept_language,
        get_user_locale_from_request,
        get_chat_locale_from_request,
        persist_user_chat_locale,
        get_persisted_chat_locale,
    )

All functions are backend-only; they do NOT call any translation APIs.
"""
import logging
from typing import Optional

from fastapi import Request

logger = logging.getLogger(__name__)

# ── Supported locales ────────────────────────────────────────────────────────
# 36 locales that ship in ARB. Keep in sync with the Flutter i18n config.
SUPPORTED_LOCALES: set[str] = {
    "en", "ar", "bn", "cs", "de", "es", "fi", "fr", "ha", "hi",
    "id", "it", "ja", "jv", "kn", "ko", "ml", "mr", "ms", "ne",
    "nl", "or", "pa", "pl", "pt", "ru", "sv", "sw", "ta", "te",
    "th", "tl", "tr", "ur", "vi", "zh",
}

# ── ISO 639-1 → native name ──────────────────────────────────────────────────
# Used to inject the friendly language name into Gemini system prompts so the
# model knows WHICH language to respond in, not just the 2-letter code.
LOCALE_NATIVE_NAMES: dict[str, str] = {
    "en": "English",
    "ar": "العربية",
    "bn": "বাংলা",
    "cs": "Čeština",
    "de": "Deutsch",
    "es": "Español",
    "fi": "Suomi",
    "fr": "Français",
    "ha": "Hausa",
    "hi": "हिन्दी",
    "id": "Bahasa Indonesia",
    "it": "Italiano",
    "ja": "日本語",
    "jv": "Basa Jawa",
    "kn": "ಕನ್ನಡ",
    "ko": "한국어",
    "ml": "മലയാളം",
    "mr": "मराठी",
    "ms": "Bahasa Melayu",
    "ne": "नेपाली",
    "nl": "Nederlands",
    "or": "ଓଡ଼ିଆ",
    "pa": "ਪੰਜਾਬੀ",
    "pl": "Polski",
    "pt": "Português",
    "ru": "Русский",
    "sv": "Svenska",
    "sw": "Kiswahili",
    "ta": "தமிழ்",
    "te": "తెలుగు",
    "th": "ภาษาไทย",
    "tl": "Filipino",
    "tr": "Türkçe",
    "ur": "اردو",
    "vi": "Tiếng Việt",
    "zh": "中文",
}


# ── Header parsing ───────────────────────────────────────────────────────────

def parse_accept_language(header: str) -> str:
    """Parse a standard Accept-Language header and return the best matching
    locale from SUPPORTED_LOCALES.

    Handles:
        - "hi-IN,en;q=0.9"  →  "hi"
        - "zh-Hant,zh;q=0.9"  →  "zh"
        - "fr"               →  "fr"
        - ""  / missing      →  "en"
        - unknown locales    →  "en"

    The q-value ordering is respected: higher-priority locales (larger q) are
    evaluated first.
    """
    if not header:
        return "en"

    # Build list of (locale_tag, q_value), sorted best-first.
    candidates: list[tuple[str, float]] = []
    for part in header.split(","):
        part = part.strip()
        if not part:
            continue
        tag_q = part.split(";")
        tag = tag_q[0].strip()
        q = 1.0
        for extra in tag_q[1:]:
            extra = extra.strip()
            if extra.lower().startswith("q="):
                try:
                    q = float(extra[2:])
                except ValueError:
                    pass
        candidates.append((tag, q))

    candidates.sort(key=lambda x: x[1], reverse=True)

    for tag, _ in candidates:
        # Exact match (e.g. "fr")
        if tag in SUPPORTED_LOCALES:
            return tag
        # Language-only prefix match (e.g. "hi-IN" → "hi", "zh-Hant" → "zh")
        base = tag.split("-")[0].lower()
        if base in SUPPORTED_LOCALES:
            return base

    return "en"


def get_user_locale_from_request(request: Request) -> str:
    """Extract the preferred locale from a FastAPI Request's Accept-Language
    header and return the best-matched SUPPORTED_LOCALES code.

    Falls back to 'en' when the header is absent or no match is found.
    """
    header = request.headers.get("Accept-Language", "")
    return parse_accept_language(header)


def get_chat_locale_from_request(request: Request) -> Optional[str]:
    """Extract the AI Coach chat locale from the X-Chat-Locale header.

    Returns None when the header is absent, so the caller can fall back to
    the user's preferred_locale (app UI language).

    The header value must be a bare ISO 639-1 code (e.g. "te", "hi").
    Unsupported codes are treated as absent (returns None).
    """
    raw = request.headers.get("X-Chat-Locale", "").strip()
    if not raw:
        return None
    # Normalise region-tagged codes like "te-IN" → "te"
    base = raw.split("-")[0].lower()
    if base in SUPPORTED_LOCALES:
        return base
    logger.debug(f"[Locale] X-Chat-Locale '{raw}' not in SUPPORTED_LOCALES — ignoring")
    return None


# ── Persistence helpers ───────────────────────────────────────────────────────

def persist_user_locale(user_id: str, locale: str, db_client) -> None:
    """Write the user's preferred locale to users.preferred_locale (sync).

    Uses the Supabase sync client (db_client.client) that is already
    used everywhere in the codebase for background-task writes.

    Edge cases:
        - Invalid locale code: silently skipped (never write garbage to DB).
        - DB error: logged as warning, never raises (background task).
    """
    if locale not in SUPPORTED_LOCALES:
        logger.debug(f"[Locale] Skipping persist for unsupported locale '{locale}' (user {user_id})")
        return
    try:
        db_client.client.table("users").update(
            {"preferred_locale": locale}
        ).eq("id", user_id).execute()
        logger.debug(f"[Locale] Persisted locale={locale} for user {user_id}")
    except Exception as exc:
        logger.warning(f"[Locale] Failed to persist locale for user {user_id}: {exc}")


def get_persisted_locale(user_id: str, db_client) -> str:
    """Read the user's persisted preferred locale from users.preferred_locale.

    Returns 'en' on any error or when the row has no preferred_locale value.
    """
    try:
        result = (
            db_client.client.table("users")
            .select("preferred_locale")
            .eq("id", user_id)
            .limit(1)
            .execute()
        )
        if result.data and result.data[0].get("preferred_locale"):
            locale = result.data[0]["preferred_locale"]
            return locale if locale in SUPPORTED_LOCALES else "en"
    except Exception as exc:
        logger.warning(f"[Locale] Failed to read locale for user {user_id}: {exc}")
    return "en"


def persist_user_chat_locale(user_id: str, chat_locale: Optional[str], db_client) -> None:
    """Write the user's AI Coach chat locale to users.chat_locale (sync).

    Pass None to clear the override (AI will use preferred_locale as fallback).
    Invalid locale codes are silently skipped. DB errors are logged, not raised
    (used as background task).
    """
    if chat_locale is not None and chat_locale not in SUPPORTED_LOCALES:
        logger.debug(
            f"[Locale] Skipping chat_locale persist for unsupported '{chat_locale}' (user {user_id})"
        )
        return
    try:
        db_client.client.table("users").update(
            {"chat_locale": chat_locale}
        ).eq("id", user_id).execute()
        logger.debug(
            f"[Locale] Persisted chat_locale={chat_locale!r} for user {user_id}"
        )
    except Exception as exc:
        logger.warning(f"[Locale] Failed to persist chat_locale for user {user_id}: {exc}")


def get_persisted_chat_locale(user_id: str, db_client) -> str:
    """Read the user's AI Coach chat locale from the DB.

    Resolution order:
      1. users.chat_locale      (explicit override)
      2. users.preferred_locale (app UI locale)
      3. 'en'                   (hard default)

    Always returns a valid SUPPORTED_LOCALES code. Never raises.
    """
    try:
        result = (
            db_client.client.table("users")
            .select("chat_locale, preferred_locale")
            .eq("id", user_id)
            .limit(1)
            .execute()
        )
        if result.data:
            row = result.data[0]
            # Prefer explicit chat_locale override
            chat_loc = row.get("chat_locale")
            if chat_loc and chat_loc in SUPPORTED_LOCALES:
                return chat_loc
            # Fall back to preferred_locale (app UI language)
            ui_loc = row.get("preferred_locale")
            if ui_loc and ui_loc in SUPPORTED_LOCALES:
                return ui_loc
    except Exception as exc:
        logger.warning(f"[Locale] Failed to read chat_locale for user {user_id}: {exc}")
    return "en"


# ── DB i18n overlay helpers ──────────────────────────────────────────────────
# These helpers look up the per-locale i18n tables (migration 2104 / 2105) and
# overlay translated fields onto base-table row dicts.
#
# Design rules:
#   - COALESCE to 'en' when the requested locale row is missing.
#   - Never raise on missing i18n rows — degrade silently to the base row.
#   - No paid API calls anywhere in this module.

_FALLBACK_LOCALE = "en"


def _fetch_i18n_row(
    db_client,
    table: str,
    pk_col: str,
    pk_val,
    locale: str,
) -> Optional[dict]:
    """Fetch a single i18n row with COALESCE-to-en fallback.

    Queries *table* for pk_col=pk_val AND locale IN (locale, 'en'), then
    prefers the exact-locale row.  Returns None if neither exists.
    Never raises — all DB errors are swallowed and logged as warnings so that
    the calling endpoint can continue with the un-translated base row.
    """
    from typing import Any  # local import to avoid circular
    try:
        locales_to_fetch = list({locale, _FALLBACK_LOCALE})
        res = (
            db_client.client
            .table(table)
            .select("*")
            .eq(pk_col, pk_val)
            .in_("locale", locales_to_fetch)
            .execute()
        )
        rows: list[dict] = res.data or []
    except Exception as exc:
        logger.warning(
            f"[Locale/i18n] Failed to query {table} for {pk_col}={pk_val!r}: {exc}"
        )
        return None

    if not rows:
        return None

    by_locale = {r["locale"]: r for r in rows}
    return by_locale.get(locale) or by_locale.get(_FALLBACK_LOCALE)


def overlay_exercise_i18n(row: dict, db_client, locale: str) -> dict:
    """Overlay i18n translations onto an exercise_library row dict.

    Looks up exercise_library_i18n for (exercise_id=row['id'], locale).
    If the requested locale has no row, falls back to locale='en'.
    Mutates and returns *row*.

    Fields overlaid (when non-null in i18n row):
      - exercise_name / name   (exercise_library uses 'exercise_name';
                                exercise_library_cleaned uses 'name')
      - instructions
      - target_muscle          (from primary_muscle_localized)
      - secondary_muscles      (from secondary_muscles_localized)
    """
    exercise_id = row.get("id")
    if not exercise_id or locale == _FALLBACK_LOCALE:
        # English is the base — no JOIN needed for the 'en' locale, it's already there.
        return row

    i18n = _fetch_i18n_row(db_client, "exercise_library_i18n", "exercise_id", str(exercise_id), locale)
    if not i18n:
        return row

    if i18n.get("name"):
        row["exercise_name"] = i18n["name"]
        row["name"] = i18n["name"]
    if i18n.get("instructions"):
        row["instructions"] = i18n["instructions"]
    if i18n.get("primary_muscle_localized"):
        row["target_muscle"] = i18n["primary_muscle_localized"]
    if i18n.get("secondary_muscles_localized") is not None:
        row["secondary_muscles"] = i18n["secondary_muscles_localized"]
    return row


def overlay_food_i18n(row: dict, db_client, locale: str) -> dict:
    """Overlay i18n translations onto a food_nutrition_overrides row dict.

    Looks up food_nutrition_overrides_i18n for (food_id=row['id'], locale).
    Falls back to 'en' if the locale row is missing.

    Fields overlaid:
      - display_name
      - description
      - common_servings_localized (new key added to row)
    """
    food_id = row.get("id")
    if food_id is None or locale == _FALLBACK_LOCALE:
        return row

    i18n = _fetch_i18n_row(db_client, "food_nutrition_overrides_i18n", "food_id", int(food_id), locale)
    if not i18n:
        return row

    if i18n.get("name"):
        row["display_name"] = i18n["name"]
    if i18n.get("description") is not None:
        row["description"] = i18n["description"]
    row["common_servings_localized"] = i18n.get("common_servings_localized") or []
    return row


def overlay_recipe_i18n(row: dict, db_client, locale: str) -> dict:
    """Overlay i18n translations onto a user_recipes row dict.

    Looks up recipes_i18n for (recipe_id=row['id'], locale).
    Falls back to 'en' if locale row is missing.

    Fields overlaid:
      - name
      - description
      - instructions_localized (new structured array key)
      - instructions           (flat string rebuilt from instructions_localized)
    """
    recipe_id = row.get("id")
    if not recipe_id or locale == _FALLBACK_LOCALE:
        return row

    i18n = _fetch_i18n_row(db_client, "recipes_i18n", "recipe_id", str(recipe_id), locale)
    if not i18n:
        return row

    if i18n.get("name"):
        row["name"] = i18n["name"]
    if i18n.get("description") is not None:
        row["description"] = i18n["description"]
    steps = i18n.get("instructions_localized") or []
    row["instructions_localized"] = steps
    if steps:
        row["instructions"] = "\n".join(
            s.get("text", "") for s in steps if s.get("text")
        ) or row.get("instructions")
    return row
