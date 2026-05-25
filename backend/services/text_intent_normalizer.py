"""
text_intent_normalizer.py — pre-classifier text scrubbing.

Strips markdown noise, normalizes lists, fingerprints obvious signals
(bullet lists, numbered exercises, ingredient lists, time-of-day markers)
that the intent classifier benefits from. Keeps the classifier's input
small and signal-rich.

Cheap, deterministic, no LLM call.
"""
from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Optional


@dataclass
class NormalizedText:
    text: str
    has_numbered_list: bool
    has_bullet_list: bool
    has_ingredient_markers: bool
    has_set_rep_markers: bool
    has_macro_markers: bool
    has_day_markers: bool      # "Day 1 …" / "Monday …" suggesting meal plan
    has_url: bool
    char_count: int


# Regex fingerprints — intentionally permissive.
_NUM_LIST_RE = re.compile(r"^\s*\d+[.)]\s+", re.MULTILINE)
_BULLET_RE = re.compile(r"^\s*[-*•]\s+", re.MULTILINE)
_INGREDIENT_RE = re.compile(
    r"\b(\d+(?:\.\d+)?\s*(?:cup|cups|tbsp|tsp|g|kg|oz|ml|l|lb|pound|pounds|clove|cloves|stick|sticks|pinch))\b",
    re.IGNORECASE,
)
_SET_REP_RE = re.compile(
    r"\b\d+\s*(?:x|×)\s*\d+\b"          # "3x8", "4x10"
    r"|\b\d+\s*sets?\b"                 # "3 sets"
    r"|\b\d+\s*reps?\b"                 # "8 reps"
    r"|\brest\s*\d+\s*(?:s|sec|seconds|min)\b",
    re.IGNORECASE,
)
_MACRO_RE = re.compile(
    r"\b(?:protein|carbs?|carbohydrates?|fat|fats|calories?|kcal)\b\s*[:=]?\s*\d+",
    re.IGNORECASE,
)
_DAY_RE = re.compile(
    r"\b(?:day\s*\d+|monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b",
    re.IGNORECASE,
)
_URL_RE = re.compile(r"https?://\S+", re.IGNORECASE)
_MD_FENCE_RE = re.compile(r"^```[a-zA-Z]*\s*$", re.MULTILINE)
_MD_HEADING_RE = re.compile(r"^#{1,6}\s*", re.MULTILINE)
_MD_BOLD_RE = re.compile(r"\*\*([^*]+)\*\*")
_MD_ITALIC_RE = re.compile(r"(?<!\*)\*([^*\n]+)\*(?!\*)")
_MD_LINK_RE = re.compile(r"\[([^\]]+)\]\([^)]+\)")
_WHITESPACE_RE = re.compile(r"[ \t]+")


def normalize(raw: str, *, max_chars: int = 12_000) -> NormalizedText:
    """Normalize and fingerprint text for the intent classifier.

    Strips markdown fences/headings/bold/italic but preserves list markers
    (they're a strong signal). Collapses whitespace. Truncates to
    `max_chars` from the front, since AI replies and recipe pages put the
    important content first.
    """
    if not raw:
        return NormalizedText(
            text="", has_numbered_list=False, has_bullet_list=False,
            has_ingredient_markers=False, has_set_rep_markers=False,
            has_macro_markers=False, has_day_markers=False, has_url=False,
            char_count=0,
        )

    t = raw

    # Strip markdown noise
    t = _MD_FENCE_RE.sub("", t)
    t = _MD_HEADING_RE.sub("", t)
    t = _MD_BOLD_RE.sub(r"\1", t)
    t = _MD_ITALIC_RE.sub(r"\1", t)
    t = _MD_LINK_RE.sub(r"\1", t)

    # Collapse whitespace per-line; preserve newlines
    lines = [_WHITESPACE_RE.sub(" ", ln).rstrip() for ln in t.splitlines()]
    t = "\n".join(ln for ln in lines if ln or True)  # keep blank lines for list separation

    # Drop excessive consecutive blank lines (more than 2)
    t = re.sub(r"\n{3,}", "\n\n", t).strip()

    fingerprints = NormalizedText(
        text=t[:max_chars],
        has_numbered_list=bool(_NUM_LIST_RE.search(t)),
        has_bullet_list=bool(_BULLET_RE.search(t)),
        has_ingredient_markers=bool(_INGREDIENT_RE.search(t)),
        has_set_rep_markers=bool(_SET_REP_RE.search(t)),
        has_macro_markers=bool(_MACRO_RE.search(t)),
        has_day_markers=bool(_DAY_RE.search(t)),
        has_url=bool(_URL_RE.search(t)),
        char_count=len(t),
    )
    return fingerprints


def fingerprints_to_signals(fp: NormalizedText) -> dict[str, str]:
    """Compact dict the intent classifier can append to the prompt."""
    out = {}
    if fp.has_numbered_list:
        out["numbered_list"] = "yes"
    if fp.has_bullet_list:
        out["bullet_list"] = "yes"
    if fp.has_ingredient_markers:
        out["ingredient_markers"] = "yes"
    if fp.has_set_rep_markers:
        out["set_rep_markers"] = "yes"
    if fp.has_macro_markers:
        out["macro_markers"] = "yes"
    if fp.has_day_markers:
        out["day_markers"] = "yes"
    return out


def soft_hash(s: str) -> str:
    """Stable SHA-1-style fingerprint for dedupe-within-60s checks."""
    import hashlib
    return hashlib.sha1((s or "").strip().encode("utf-8")).hexdigest()
