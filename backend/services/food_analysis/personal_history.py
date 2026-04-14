"""Per-user food history lookup for Gemini re-log warnings.

When a user is logging a food they've logged before, we want Gemini's coach tip
to reference that pattern ("You've felt bloated 3 of 4 times after this"). This
module is the lookup path: given a list of candidate food names, fetch the
aggregated history from the `get_food_patterns` Supabase RPC.

The RPC handles confidence weighting (confirmed vs inferred) internally — we
just surface the counts so Gemini can decide how forceful to be.
"""

from __future__ import annotations

import asyncio
from typing import Any, Iterable, Optional

from core.db import get_supabase_db
from core.logger import get_logger

logger = get_logger(__name__)

# Threshold guardrails — prevents Gemini from warning on one-off noise.
MIN_CONFIRMED_COUNT = 3
MIN_TOTAL_COUNT_IF_NO_CONFIRMED = 5
NEGATIVE_RATIO_THRESHOLD = 0.6  # e.g. 3 of 5 meals negative


def _normalize_name(name: str) -> str:
    return (name or "").strip().lower()


def _dedupe_names(names: Iterable[str]) -> list[str]:
    seen: set[str] = set()
    out: list[str] = []
    for raw in names or []:
        normalized = _normalize_name(raw)
        if not normalized or len(normalized) < 2 or normalized in seen:
            continue
        seen.add(normalized)
        out.append(normalized)
    return out


async def lookup_personal_history_for_foods(
    user_id: str,
    food_names: Iterable[str],
    days: int = 90,
    include_inferred: bool = True,
    min_logs: int = 2,
) -> list[dict[str, Any]]:
    """Return history rows for each food that meets the guardrails.

    Each row includes:
      - food_name
      - logs (total: confirmed + inferred)
      - confirmed_count / inferred_count
      - negative_mood_count / positive_mood_count
      - avg_energy (nullable)
      - dominant_symptom (nullable, e.g. "bloated")
      - severity: "strong" | "moderate" | None — whether Gemini should warn
    """
    normalized = _dedupe_names(food_names)
    if not normalized:
        return []

    try:
        db = get_supabase_db()
        # supabase-py is sync; run in a thread so we don't block the event loop.
        response = await asyncio.to_thread(
            lambda: db.client.rpc(
                "get_food_patterns",
                {
                    "p_user_id": user_id,
                    "p_days": days,
                    "p_min_logs": min_logs,
                    "p_include_inferred": include_inferred,
                    "p_food_names": normalized,
                },
            ).execute()
        )
    except Exception as exc:
        logger.warning(
            "lookup_personal_history_for_foods failed for user=%s names=%s: %s",
            user_id, normalized[:5], exc,
        )
        return []

    rows = getattr(response, "data", None) or []
    shaped: list[dict[str, Any]] = []
    for row in rows:
        confirmed = int(row.get("confirmed_count") or 0)
        inferred = int(row.get("inferred_count") or 0)
        total = confirmed + inferred
        if total == 0:
            continue

        negative = int(row.get("negative_mood_count") or 0)
        positive = int(row.get("positive_mood_count") or 0)
        ratio_neg = negative / total if total else 0.0

        severity = _classify_severity(
            confirmed=confirmed,
            total=total,
            negative_ratio=ratio_neg,
        )

        shaped.append(
            {
                "food_name": row.get("food_name"),
                "logs": total,
                "confirmed_count": confirmed,
                "inferred_count": inferred,
                "negative_mood_count": negative,
                "positive_mood_count": positive,
                "avg_energy": _to_float(row.get("avg_energy")),
                "dominant_symptom": row.get("dominant_symptom"),
                "last_logged_at": row.get("last_logged_at"),
                "severity": severity,
            }
        )
    return shaped


def _classify_severity(
    confirmed: int, total: int, negative_ratio: float
) -> Optional[str]:
    """Decide whether Gemini should warn at all, and how forcefully.

    - "strong": enough confirmed data to cite numbers confidently.
    - "moderate": mostly inferred data or few confirmed — soften the copy.
    - None: don't warn.
    """
    if confirmed >= MIN_CONFIRMED_COUNT and negative_ratio >= NEGATIVE_RATIO_THRESHOLD:
        return "strong"
    if total >= MIN_TOTAL_COUNT_IF_NO_CONFIRMED and negative_ratio >= NEGATIVE_RATIO_THRESHOLD:
        return "moderate"
    return None


def _to_float(value: Any) -> Optional[float]:
    if value is None:
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def filter_warnable(history: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Keep only rows whose severity is non-null — those are what Gemini
    should actually mention in its warnings/recommended_swap."""
    return [row for row in history if row.get("severity")]
