"""Companion-food resolver for Fix 2 — "add sides?" suggestions on re-log.

Pulls three independent signals and merges them:

  1. Same-log siblings: the tapped food_log row already has multiple
     food_items (e.g. Masala Dosa + Coconut Chutney + Green Chili Chutney).
     Frontend passes these through the decision tree and renders them in
     the "From your past logs" section; this service does not need to
     re-derive them.

  2. Cross-log co-occurrence: look at the user's last 90 days of food_logs
     in the same meal_type. For each log that contained <primary_name>,
     everything else in that meal (or a meal ±90 min away) is a candidate
     sibling. Confidence = days_paired / days_ate_primary.

  3. Global cultural pairing (Gemini, cached): for foods the user has
     never had — or where their history is thin — ask the model for
     typical sides / beverages / condiments by cuisine, cache the result
     in ``food_companion_suggestions_cache`` keyed by canonical name +
     locale, and reuse it on future calls.

The endpoint (``/nutrition/companions``) fans these in, filters against
the ``food_companion_rejected_pairs`` table (user-taught negatives), and
returns a ranked list. See migration 1919_food_companion_cache.sql.
"""
from __future__ import annotations

import asyncio
import re
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional, Tuple

from google.genai import types
from pydantic import BaseModel, Field

from core.config import get_settings
from core.logger import get_logger
from services.gemini.constants import gemini_generate_with_retry

logger = get_logger(__name__)
settings = get_settings()

# ─── Config ────────────────────────────────────────────────────────────────

# Look back this far when computing personal co-occurrence.
_HISTORY_LOOKBACK_DAYS = 90
# Pull at most this many logs — caps memory/runtime for heavy users.
_HISTORY_MAX_LOGS = 400
# Pair candidates within this window count as "in the same meal block".
_MEAL_WINDOW_MINUTES = 90
# A companion shows up in "From your past logs" only at this confidence.
_HISTORY_MIN_CONFIDENCE = 0.15
# Cache expiry — after this we re-call Gemini for global sides. Doesn't
# invalidate user history (history is computed on every request).
_CACHE_TTL_DAYS = 180
# Max items surfaced to the UI.
_MAX_SUGGESTIONS = 5

_MODEL_VERSION = "companions-v1"

# ─── Gemini schema ─────────────────────────────────────────────────────────


class CompanionGeminiItem(BaseModel):
    """Strict schema the model fills for each typical side/companion."""

    name: str = Field(..., description="Concrete, specific side dish, condiment, or beverage (e.g. 'Coconut Chutney', 'Waffle Fries', not 'chutney' or 'fries').")
    typical_portion_g: float = Field(
        ...,
        description="Realistic serving in grams (not ounces). Use the portion a typical adult pairs with the primary food.",
    )
    est_calories: int = Field(..., ge=0)
    est_protein_g: float = Field(0, ge=0)
    est_carbs_g: float = Field(0, ge=0)
    est_fat_g: float = Field(0, ge=0)
    cuisine_tag: str = Field(
        "",
        description="Free-text cuisine origin (e.g. 'south_indian', 'italian', 'fast_food:chipotle'). Empty if irrelevant.",
    )
    confidence: float = Field(
        ...,
        ge=0.0,
        le=1.0,
        description="How commonly this side is paired with the primary in real-world dining.",
    )
    why: str = Field(
        ...,
        description="One short sentence on why this pairing makes sense (tradition, macro balance, texture, etc.).",
    )


class CompanionGeminiResponse(BaseModel):
    """Top-level schema returned by the resolver's Gemini call."""

    sides: List[CompanionGeminiItem] = Field(default_factory=list)
    primary_is_combo: bool = Field(
        False,
        description="True when the primary food is already a complete meal (e.g. 'Thali', 'Bento', 'Buddha Bowl') and suggesting sides would be nonsense.",
    )
    primary_is_too_generic: bool = Field(
        False,
        description="True when the primary is a vague ingredient like 'Rice' or 'Bread' — return empty sides rather than guessing.",
    )


# ─── Result shape returned to the endpoint ─────────────────────────────────


@dataclass
class CompanionSuggestion:
    name: str
    source: str  # 'history' | 'global'
    confidence: float
    est_calories: int
    est_protein_g: float
    est_carbs_g: float
    est_fat_g: float
    typical_portion_g: float
    cuisine_tag: str
    why: str
    meta: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "name": self.name,
            "source": self.source,
            "confidence": round(self.confidence, 3),
            "est_calories": self.est_calories,
            "est_protein_g": round(self.est_protein_g, 1),
            "est_carbs_g": round(self.est_carbs_g, 1),
            "est_fat_g": round(self.est_fat_g, 1),
            "typical_portion_g": round(self.typical_portion_g, 1),
            "cuisine_tag": self.cuisine_tag,
            "why": self.why,
            **({"meta": self.meta} if self.meta else {}),
        }


# ─── Name canonicalization ─────────────────────────────────────────────────


def canonical_name(name: str) -> str:
    """Lower + collapse whitespace + strip obvious qualifiers so
    'Masala Dosa (1 piece)' / 'masala  dosa' / 'MASALA DOSA' all hit the
    same cache row. Keep it conservative — don't strip distinguishing words
    like 'plain' or 'steamed' that could be a different dish.
    """
    s = (name or "").lower()
    s = re.sub(r"\(.*?\)", " ", s)          # drop anything in parens
    s = re.sub(r"[^a-z0-9\s\-]+", " ", s)  # punctuation to spaces
    s = re.sub(r"\s+", " ", s).strip()
    return s


# ─── History (co-occurrence) ───────────────────────────────────────────────


def _iter_item_names(log: Dict[str, Any]) -> List[str]:
    items = log.get("food_items") or []
    names: List[str] = []
    for it in items:
        if isinstance(it, dict):
            n = it.get("name")
            if isinstance(n, str) and n.strip():
                names.append(n.strip())
    return names


def _history_suggestions(
    db,
    user_id: str,
    primary_name: str,
    meal_type: str,
) -> List[CompanionSuggestion]:
    """Scan the user's recent food_logs for cross-log co-occurrence with
    the primary food. Returns candidates keyed by canonical name with a
    confidence score. Empty list is a normal outcome (brand-new food)."""

    cutoff = (datetime.now(timezone.utc) - timedelta(days=_HISTORY_LOOKBACK_DAYS)).isoformat()

    try:
        logs = db.list_food_logs(
            user_id=user_id,
            from_date=cutoff,
            meal_type=meal_type,
            limit=_HISTORY_MAX_LOGS,
        )
    except Exception as e:  # noqa: BLE001
        logger.warning(f"[Companions] history fetch failed for user={user_id}: {e}")
        return []

    primary_key = canonical_name(primary_name)
    if not primary_key:
        return []

    # Step 1 — find all logs that contained the primary.
    primary_logs: List[Dict[str, Any]] = []
    for log in logs:
        names = _iter_item_names(log)
        if any(canonical_name(n) == primary_key for n in names):
            primary_logs.append(log)

    if not primary_logs:
        return []

    # Step 2 — for each primary log, collect companions from both (a) the
    # same log and (b) any other log within ±_MEAL_WINDOW_MINUTES in the
    # same meal_type. Track which **days** each companion appeared on so
    # multiple taps in one meal don't inflate the confidence.

    def parse_iso(s: Any) -> Optional[datetime]:
        if isinstance(s, datetime):
            return s if s.tzinfo else s.replace(tzinfo=timezone.utc)
        if isinstance(s, str):
            try:
                dt = datetime.fromisoformat(s.replace("Z", "+00:00"))
                return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)
            except ValueError:
                return None
        return None

    primary_days: set = set()
    companion_days: Dict[str, set] = {}
    companion_latest: Dict[str, Dict[str, Any]] = {}

    window = timedelta(minutes=_MEAL_WINDOW_MINUTES)

    # Build a quick index so neighbor lookup is O(logs_in_meal_type).
    for pl in primary_logs:
        p_time = parse_iso(pl.get("logged_at"))
        if p_time is None:
            continue
        p_day = p_time.date()
        primary_days.add(p_day)

        neighbors: List[Dict[str, Any]] = [pl]
        for other in logs:
            if other.get("id") == pl.get("id"):
                continue
            o_time = parse_iso(other.get("logged_at"))
            if o_time is None:
                continue
            if abs(o_time - p_time) <= window:
                neighbors.append(other)

        for n in neighbors:
            for nm in _iter_item_names(n):
                k = canonical_name(nm)
                if not k or k == primary_key:
                    continue
                companion_days.setdefault(k, set()).add(p_day)
                # Remember the richest item so we can pull macros when the
                # food DB doesn't have them. Prefer newer logs.
                prior = companion_latest.get(k)
                prior_time = parse_iso(prior.get("_log_time")) if prior else None
                new_time = parse_iso(n.get("logged_at"))
                if prior is None or (
                    prior_time is None
                    or (new_time is not None and new_time > prior_time)
                ):
                    # Find the matching item dict to pull macros.
                    for it in n.get("food_items") or []:
                        if isinstance(it, dict) and canonical_name(it.get("name", "")) == k:
                            companion_latest[k] = {**it, "_log_time": n.get("logged_at")}
                            break

    total_primary = max(1, len(primary_days))
    out: List[CompanionSuggestion] = []
    for key, days in companion_days.items():
        conf = len(days) / total_primary
        if conf < _HISTORY_MIN_CONFIDENCE:
            continue
        latest = companion_latest.get(key, {})
        display_name = (latest.get("name") or key).strip().title()
        cal = int(latest.get("calories") or latest.get("total_calories") or 0)
        out.append(
            CompanionSuggestion(
                name=display_name,
                source="history",
                confidence=min(1.0, conf),
                est_calories=cal,
                est_protein_g=float(latest.get("protein_g") or 0),
                est_carbs_g=float(latest.get("carbs_g") or 0),
                est_fat_g=float(latest.get("fat_g") or 0),
                typical_portion_g=float(latest.get("weight_g") or latest.get("typical_portion_g") or 0),
                cuisine_tag="",
                why=f"You've logged this with '{primary_name}' on {len(days)} of {total_primary} days.",
                meta={"days_paired": len(days), "days_primary": total_primary},
            )
        )
    out.sort(key=lambda s: s.confidence, reverse=True)
    return out


# ─── Gemini-backed global sides (cached) ───────────────────────────────────


_SYSTEM_INSTRUCTION = (
    "You are a culturally-literate chef helping a nutrition app suggest realistic "
    "side dishes, condiments, or beverages people commonly eat with a given primary food. "
    "Be concrete: name real dishes, not categories. Prefer items of the same cuisine of origin. "
    "If the primary food is already a complete meal (e.g. 'Thali', 'Bento box', 'Buddha bowl'), "
    "set primary_is_combo=true and return no sides. If the primary is too generic to pair "
    "('Rice', 'Bread', 'Meat'), set primary_is_too_generic=true and return no sides. "
    "Never invent obviously wrong pairings for novelty."
)


def _build_gemini_prompt(primary_name: str, locale: str, meal_type: str) -> str:
    return (
        f"Primary food: {primary_name}\n"
        f"Meal slot: {meal_type}\n"
        f"User locale/language hint: {locale}\n\n"
        "List up to 5 real typical sides / companions / beverages someone would "
        "eat with this at this meal. Each entry must include a specific name, a "
        "realistic portion in grams, calorie and macro estimates for that portion, "
        "cuisine tag, confidence 0–1, and one short sentence on why it pairs.\n"
    )


async def _fetch_gemini_suggestions(
    primary_name: str,
    locale: str,
    meal_type: str,
) -> CompanionGeminiResponse:
    prompt = _build_gemini_prompt(primary_name, locale, meal_type)
    response = await gemini_generate_with_retry(
        model=settings.gemini_model,
        contents=prompt,
        config=types.GenerateContentConfig(
            system_instruction=_SYSTEM_INSTRUCTION,
            response_mime_type="application/json",
            response_schema=CompanionGeminiResponse,
            max_output_tokens=900,
            temperature=0.3,
        ),
        user_id="system",
        method_name="resolve_companions",
        timeout=15,
    )
    parsed = response.parsed
    if parsed is None:
        raise RuntimeError("Gemini returned an unparseable companions response")
    return parsed


def _read_cache(db, key: str, locale: str) -> Optional[CompanionGeminiResponse]:
    try:
        res = (
            db.client.table("food_companion_suggestions_cache")
            .select("*")
            .eq("primary_name", key)
            .eq("locale", locale)
            .limit(1)
            .execute()
        )
    except Exception as e:  # noqa: BLE001
        logger.warning(f"[Companions] cache read failed: {e}")
        return None

    row = (res.data or [None])[0]
    if not row:
        return None

    # Expire old cache entries — re-fetch after TTL.
    generated_at = row.get("generated_at")
    try:
        gen_dt = (
            datetime.fromisoformat(generated_at.replace("Z", "+00:00"))
            if isinstance(generated_at, str)
            else generated_at
        )
        if gen_dt is not None:
            if gen_dt.tzinfo is None:
                gen_dt = gen_dt.replace(tzinfo=timezone.utc)
            if datetime.now(timezone.utc) - gen_dt > timedelta(days=_CACHE_TTL_DAYS):
                return None
    except Exception:  # noqa: BLE001
        pass

    try:
        return CompanionGeminiResponse.model_validate(row.get("suggestions") or {})
    except Exception as e:  # noqa: BLE001
        logger.warning(f"[Companions] cache row {key!r} malformed, ignoring: {e}")
        return None


def _write_cache(db, key: str, locale: str, payload: CompanionGeminiResponse) -> None:
    try:
        db.client.table("food_companion_suggestions_cache").upsert({
            "primary_name": key,
            "locale": locale,
            "suggestions": payload.model_dump(),
            "cuisine_tag": (payload.sides[0].cuisine_tag if payload.sides else None),
            "model_version": _MODEL_VERSION,
            "generated_at": datetime.now(timezone.utc).isoformat(),
        }).execute()
    except Exception as e:  # noqa: BLE001
        # Cache misses are tolerable. Never let cache writes break the request.
        logger.warning(f"[Companions] cache write failed for {key!r}: {e}")


async def _global_suggestions(
    db,
    primary_name: str,
    meal_type: str,
    locale: str,
) -> List[CompanionSuggestion]:
    key = canonical_name(primary_name)
    if not key:
        return []

    cached = _read_cache(db, key, locale)
    if cached is None:
        try:
            cached = await _fetch_gemini_suggestions(primary_name, locale, meal_type)
        except Exception as e:  # noqa: BLE001
            # Per feedback_no_silent_fallbacks.md: don't fabricate sides if the
            # model call fails; just return empty and let the endpoint fall
            # through to history-only.
            logger.warning(f"[Companions] Gemini fetch failed for {primary_name!r}: {e}")
            return []
        _write_cache(db, key, locale, cached)

    if cached.primary_is_combo or cached.primary_is_too_generic:
        return []

    return [
        CompanionSuggestion(
            name=s.name.strip(),
            source="global",
            confidence=max(0.0, min(1.0, s.confidence)),
            est_calories=s.est_calories,
            est_protein_g=s.est_protein_g,
            est_carbs_g=s.est_carbs_g,
            est_fat_g=s.est_fat_g,
            typical_portion_g=s.typical_portion_g,
            cuisine_tag=s.cuisine_tag or "",
            why=s.why,
        )
        for s in cached.sides
    ]


# ─── Rejected-pair lookup ──────────────────────────────────────────────────


def _rejected_set(db, user_id: str, primary_key: str) -> set:
    try:
        res = (
            db.client.table("food_companion_rejected_pairs")
            .select("companion_name")
            .eq("user_id", user_id)
            .eq("primary_name", primary_key)
            .execute()
        )
    except Exception as e:  # noqa: BLE001
        logger.warning(f"[Companions] rejected-pairs fetch failed: {e}")
        return set()
    return {canonical_name(r.get("companion_name") or "") for r in (res.data or [])}


def record_rejected_pair(db, user_id: str, primary_name: str, companion_name: str) -> None:
    key_p = canonical_name(primary_name)
    key_c = canonical_name(companion_name)
    if not key_p or not key_c:
        return
    try:
        db.client.table("food_companion_rejected_pairs").upsert({
            "user_id": user_id,
            "primary_name": key_p,
            "companion_name": key_c,
        }).execute()
    except Exception as e:  # noqa: BLE001
        logger.warning(f"[Companions] rejected-pair write failed: {e}")


# ─── Public entrypoint ─────────────────────────────────────────────────────


async def resolve_companions(
    db,
    user_id: str,
    primary_name: str,
    meal_type: str,
    locale: str = "en",
) -> List[CompanionSuggestion]:
    """Return the merged top-N companion suggestions for this user+food."""
    primary_key = canonical_name(primary_name)
    if not primary_key:
        return []

    # Run history SQL in a worker thread (Supabase python client is sync) so
    # it doesn't block the Gemini call that's already happening on the
    # asyncio loop.
    history_task = asyncio.to_thread(
        _history_suggestions, db, user_id, primary_name, meal_type
    )
    global_task = _global_suggestions(db, primary_name, meal_type, locale)
    rejected_task = asyncio.to_thread(_rejected_set, db, user_id, primary_key)

    history, global_, rejected = await asyncio.gather(
        history_task, global_task, rejected_task, return_exceptions=False
    )

    merged: Dict[str, CompanionSuggestion] = {}
    for sugg in history:
        k = canonical_name(sugg.name)
        if k in rejected:
            continue
        merged[k] = sugg
    for sugg in global_:
        k = canonical_name(sugg.name)
        if k in rejected or k == primary_key:
            continue
        if k in merged:
            # Blend: trust the user's own data on macros, but flag as also-global.
            merged[k].meta["also_global"] = True
            merged[k].confidence = max(merged[k].confidence, sugg.confidence)
            continue
        merged[k] = sugg

    ranked = sorted(
        merged.values(),
        key=lambda s: (
            0 if s.source == "history" else 1,
            -s.confidence,
        ),
    )
    return ranked[:_MAX_SUGGESTIONS]
