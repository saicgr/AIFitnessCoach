"""L3 "It remembers you" — standing food-logging rules.

A user can define standing rules ("no bun", "I always use 0-cal sweetener",
"we cook low-oil South Indian", "skim milk not whole"). They are stored on
`nutrition_preferences.food_logging_rules` as a JSONB array of:

    {"id": <uuid>, "text": <str>, "created_at": <iso8601>, "enabled": <bool>}

This module is the READ side for the analysis hot path: given a user_id it
returns the enabled rules and builds the standing-context prompt block that is
injected into every food photo + text analysis (vision_service /
gemini.nutrition). The WRITE side (add/edit/delete) lives in the
`/preferences/{user_id}/food-logging-rules` endpoints in
`api/v1/nutrition/preferences.py`.

C9 edge cases handled here:
  * Per-log override — the prompt block explicitly tells the model that a
    per-log instruction, when present, OVERRIDES any conflicting standing
    rule for that one log ("usually no bun, today I had it").
  * Conflicting standing rules — `detect_rule_conflicts()` flags rule pairs
    that contradict each other so the settings UI / API can surface them for
    the user to resolve.
  * Per-user — rules are read by user_id off that user's preferences row, so
    they never cross-apply on a shared device.
"""

from __future__ import annotations

import re
from typing import Any, Dict, List, Optional

from core.logger import get_logger

logger = get_logger(__name__)

# A conservative cap so a runaway rule list can't blow the prompt budget. The
# user-facing settings screen enforces the same number.
MAX_RULES = 25


def _coerce_rule(raw: Any) -> Optional[Dict[str, Any]]:
    """Normalize one stored rule element; drop anything malformed."""
    if not isinstance(raw, dict):
        return None
    text = (raw.get("text") or "").strip()
    if not text:
        return None
    return {
        "id": str(raw.get("id") or ""),
        "text": text[:200],
        "created_at": raw.get("created_at"),
        "enabled": raw.get("enabled", True) is not False,
    }


def fetch_food_logging_rules(db, user_id: Optional[str]) -> List[Dict[str, Any]]:
    """Return the user's stored rules (all of them — enabled and disabled).

    Returns [] for an anonymous/guest user or on any DB error — a missing
    rules list must never block an analysis.
    """
    if not user_id:
        return []
    try:
        result = (
            db.client.table("nutrition_preferences")
            .select("food_logging_rules")
            .eq("user_id", user_id)
            .maybe_single()
            .execute()
        )
        if not result or not result.data:
            return []
        raw_rules = result.data.get("food_logging_rules") or []
        rules = [r for r in (_coerce_rule(x) for x in raw_rules) if r]
        return rules
    except Exception as e:  # noqa: BLE001
        logger.warning(f"[food_logging_rules] fetch failed for {user_id}: {e}")
        return []


def build_rules_prompt_block(rules: List[Dict[str, Any]], *, has_per_log_instruction: bool) -> str:
    """Build the standing-context block injected into a food-analysis prompt.

    Only ENABLED rules are included. Returns "" when there are no enabled
    rules so a rules-free user keeps the leaner prompt.

    `has_per_log_instruction` controls the override wording: when the current
    log ALSO carries a typed per-log instruction we explicitly tell the model
    the per-log instruction wins on any conflict (C9 — per-log override).
    """
    enabled = [r["text"] for r in rules if r.get("enabled")]
    if not enabled:
        return ""

    bullet_list = "\n".join(f"  - {t}" for t in enabled)
    override_clause = (
        "If the USER INSTRUCTION for THIS log contradicts a standing rule "
        "(e.g. a rule says 'no bun' but the instruction says 'today I had the "
        "bun'), the per-log instruction WINS for this log only — the standing "
        "rule is unchanged for future logs.\n"
        if has_per_log_instruction
        else
        "These rules describe how this user habitually eats — apply them "
        "unless the photo clearly contradicts a rule.\n"
    )
    return (
        "\n\nUSER'S STANDING FOOD-LOGGING RULES (always apply — the user set "
        "these once so they don't have to re-type them every log):\n"
        f"{bullet_list}\n"
        f"{override_clause}"
        "Apply each rule when it is relevant to what is being logged "
        "(adjust ingredients, preparation, or which items are present "
        "accordingly) and recompute macros. A rule that is not relevant to "
        "this particular food is simply ignored — do not invent items to "
        "satisfy it.\n"
    )


# ── Conflict detection (C9 — conflicting standing rules) ──────────────────────
# Lightweight heuristic pairs: a rule that asserts X and a rule that asserts
# not-X. This is intentionally conservative — it only flags clear textual
# contradictions and never blocks anything; it just surfaces pairs for the
# user to resolve in the settings UI.
_CONFLICT_PAIRS = [
    (r"\bno oil\b|\boil[\s-]*free\b|\blow[\s-]*oil\b", r"\bdeep[\s-]*fr|\bextra oil\b|\bfried\b"),
    (r"\bskim milk\b|\bnon[\s-]*fat milk\b|\bfat[\s-]*free milk\b", r"\bwhole milk\b|\bfull[\s-]*fat milk\b"),
    (r"\bno sugar\b|\bsugar[\s-]*free\b|\b0[\s-]*cal sweeten", r"\bextra sugar\b|\badd sugar\b"),
    (r"\bvegan\b|\bno (meat|dairy|eggs)\b", r"\b(extra|add) (meat|cheese|chicken|beef|egg)"),
    (r"\bno bun\b|\bbun[\s-]*less\b", r"\bextra bun\b|\bdouble bun\b"),
]


def detect_rule_conflicts(rules: List[Dict[str, Any]]) -> List[Dict[str, str]]:
    """Return a list of conflicting ENABLED rule pairs for the user to resolve.

    Each entry: {"rule_a_id", "rule_a_text", "rule_b_id", "rule_b_text"}.
    Empty list when no conflicts are detected.
    """
    enabled = [r for r in rules if r.get("enabled")]
    conflicts: List[Dict[str, str]] = []
    for i in range(len(enabled)):
        for j in range(i + 1, len(enabled)):
            a, b = enabled[i], enabled[j]
            ta, tb = a["text"].lower(), b["text"].lower()
            for pat_x, pat_y in _CONFLICT_PAIRS:
                a_x, a_y = re.search(pat_x, ta), re.search(pat_y, ta)
                b_x, b_y = re.search(pat_x, tb), re.search(pat_y, tb)
                if (a_x and b_y) or (a_y and b_x):
                    conflicts.append({
                        "rule_a_id": a["id"],
                        "rule_a_text": a["text"],
                        "rule_b_id": b["id"],
                        "rule_b_text": b["text"],
                    })
                    break
    return conflicts
