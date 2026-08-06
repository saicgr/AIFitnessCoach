"""
Second-person voice normalizer for coach_memory `content`.

Why: the extraction prompt (extractor.py) used to instruct Gemini to write
memory content in "concise third-person-neutral form" — e.g. "User performs
workouts in the morning." That's fine as an internal database record, but it
reaches TWO user-facing/coach-facing surfaces verbatim:
  1. Settings -> "What Coach remembers" (api/v1/coach/memory.py) shows the raw
     `content` string to the READER in third person while every other string
     on that screen addresses the user directly (row 199, 2026-08).
  2. The coach's own system prompt injects it under the header "WHAT I KNOW
     ABOUT YOU: <content>" (services/coach/memory/injector.py) — "WHAT I KNOW
     ABOUT YOU: User performs workouts..." reads like a stray third-party
     reference next to a header that already says "YOU".

The extraction prompt now asks Gemini to write NEW memories in second person
directly, so this module is a deterministic (no LLM, no cost) safety net for
memories written before that change, and a defensive normalizer in case a
future prompt edit regresses. Best-effort: unrecognized shapes are returned
unchanged rather than mangled.
"""
from __future__ import annotations

import re

# Common third-person-singular verbs the extraction prompt's own examples
# and typical Gemini output use for a fitness-memory sentence ("Has lower
# back pain", "Prefers morning workouts", "User performs workouts...").
# Curated rather than a blind "ends in s" check so we don't misfire on a
# sentence that happens to start with a plural noun ("Squats felt heavy").
_IRREGULAR = {"is": "are", "has": "have", "does": "do", "goes": "go"}
_BASE_VERBS = {
    "prefers", "wants", "likes", "dislikes", "avoids", "enjoys", "needs",
    "trains", "works", "sleeps", "eats", "drinks", "follows", "plans",
    "struggles", "performs", "uses", "owns", "lives", "tracks", "wakes",
    "starts", "ends", "feels", "thinks", "believes", "hopes", "tries",
    "keeps", "gets", "takes", "makes", "runs", "lifts", "walks", "swims",
    "bikes", "cycles", "stretches", "rests", "recovers", "reports",
    "mentions", "asks", "logs", "skips", "misses", "schedules", "counts",
    "watches", "eats", "drinks", "meditates", "warms", "cools",
}

_LEADING_USER_RE = re.compile(r"^User('s)?\b\s*", re.IGNORECASE)
_LEADING_WORD_RE = re.compile(r"^([A-Za-z]+)\b")


def _verb_base(verb: str) -> str:
    """3rd-person-singular -> base form ('performs' -> 'perform')."""
    lower = verb.lower()
    if lower in _IRREGULAR:
        return _IRREGULAR[lower]
    if lower.endswith("ies") and len(lower) > 3:
        return lower[:-3] + "y"          # "tries" -> "try"
    if lower.endswith(("shes", "ches", "xes", "ses", "zes")):
        return lower[:-2]                # "watches" -> "watch"
    if lower.endswith("s"):
        return lower[:-1]                # "performs" -> "perform"
    return lower


def _recase(new_word: str, original: str) -> str:
    """Match the original word's leading capitalization on the replacement."""
    return new_word[:1].upper() + new_word[1:] if original[:1].isupper() else new_word


def to_second_person(content: str) -> str:
    """Best-effort third-person -> second-person rewrite of a coach_memory
    `content` string. Returns the input unchanged if it doesn't match a
    recognized shape (never guesses on unfamiliar sentence structure)."""
    if not content:
        return content
    text = content.strip()

    # "User's back hurts" -> "Your back hurts"
    # "User performs workouts..." -> "You perform workouts..."
    m = _LEADING_USER_RE.match(text)
    if m:
        rest = text[m.end():]
        if m.group(1):  # possessive "User's"
            return "Your " + rest
        vm = _LEADING_WORD_RE.match(rest)
        if vm:
            verb = vm.group(1)
            base = _verb_base(verb)
            rest = _recase(base, verb) + rest[len(verb):]
        return "You " + rest

    # Elliptical form the extraction prompt's own pre-fix examples modeled:
    # "Has lower back pain, started this week" / "Prefers morning workouts"
    # — no explicit subject, sentence opens directly on the 3rd-person verb.
    vm = _LEADING_WORD_RE.match(text)
    if vm:
        verb = vm.group(1)
        lower = verb.lower()
        if lower in _IRREGULAR:
            return "You " + _IRREGULAR[lower] + text[len(verb):]
        if lower in _BASE_VERBS:
            return "You " + _verb_base(verb) + text[len(verb):]

    return text
