"""Pure, dependency-free number-grounding utilities for coach copy.

Extracted so the guardrail is unit-testable without importing Gemini / config
(both ``smart_briefing`` and the daily-insight engine share this discipline:
every number a model writes must trace back to data we actually provided, or
the output is rejected and we fall back to deterministic, number-safe copy).

No heavy imports here on purpose — import this from anywhere, test in isolation.
"""
from __future__ import annotations

import json
import re
from typing import Any, Dict, Optional

# Integers up to 5 digits, optional comma-thousands and decimal part.
_NUMBER_RE = re.compile(r"\b(\d{1,5}(?:,\d{3})*)(?:\.\d+)?\b")


def number_set(*objs: Any) -> set:
    """Flatten every numeric value across the given objects into a string set.

    Floats contribute both their int form and a one-decimal rendering (so
    "6.5h" is grounded by a 6.5 value). Bools are skipped (they are ints in
    Python). Small sentence-counter constants (0-3) are always allowed.
    """
    out: set = set()

    def _walk(v: Any) -> None:
        if isinstance(v, dict):
            for vv in v.values():
                _walk(vv)
        elif isinstance(v, (list, tuple)):
            for vv in v:
                _walk(vv)
        elif isinstance(v, bool):
            return
        elif isinstance(v, (int, float)):
            out.add(str(int(v)))
            if isinstance(v, float) and not v.is_integer():
                out.add(f"{v:.1f}")

    for o in objs:
        _walk(o)
    out.update({"0", "1", "2", "3"})
    return out


def numbers_grounded(text: str, grounded: set) -> bool:
    """True iff every number cited in `text` appears in the grounded set."""
    if not text:
        return True
    for match in _NUMBER_RE.finditer(text):
        token = match.group(1).replace(",", "")
        if token not in grounded:
            return False
    return True


def deterministic_insight_title(
    snapshot: Optional[Dict[str, Any]],
    moment: str = "morning_readiness",
) -> str:
    """A short, data-grounded INSIGHT title derived from the leading metric.

    Replaces the generic ``"{coach}'s morning briefing"`` label. Picks the most
    salient real signal in the snapshot (recovery tier, then sleep, then steps)
    and returns an observation, never a command, never a fabricated number (the
    title carries NO digits, so it is always grounded by construction). A
    deterministic small pool keyed off real state keeps it human, not robotic.

    Falls back to a neutral, non-numeric insight when no signal is present, so
    the title is never the old generic label.
    """
    import random

    snap = snapshot or {}
    recovery = (snap.get("recovery") or {})
    sleep = (snap.get("last_night_sleep") or {})
    steps = (snap.get("steps") or {})
    hr = (snap.get("heart_rate") or {})

    pools: list = []

    tier = recovery.get("tier")
    if tier in ("high", "optimal", "primed"):
        pools = [
            "Your body is primed today",
            "Recovery is in your favor",
            "Green light from your recovery",
        ]
    elif tier in ("low", "compromised", "poor"):
        pools = [
            "Your body is asking for a lighter day",
            "Recovery says ease in today",
            "Protect today, recovery is low",
        ]
    elif sleep.get("total_minutes"):
        pools = [
            "Last night set the tone",
            "Your sleep is the headline today",
            "Here is what last night gave you",
        ]
    elif hr.get("resting_vs_baseline") is not None:
        pools = [
            "Your resting heart rate has a story",
            "A quick read on your recovery signals",
        ]
    elif steps.get("today") is not None:
        pools = [
            "Your movement is the story today",
            "Let's talk about your steps",
        ]

    if not pools:
        if moment == "evening_recap":
            pools = ["How today landed", "Your day, wrapped"]
        else:
            pools = ["Your morning read", "Here is today's setup"]

    return random.choice(pools)


def parse_json_object(text: str) -> Optional[Dict[str, Any]]:
    """Parse a JSON object from a model response, tolerating ```json fences."""
    if not text:
        return None
    t = text.strip()
    if t.startswith("```"):
        t = re.sub(r"^```(?:json)?\s*|\s*```$", "", t, flags=re.IGNORECASE).strip()
    try:
        obj = json.loads(t)
        return obj if isinstance(obj, dict) else None
    except (json.JSONDecodeError, ValueError):
        start, end = t.find("{"), t.rfind("}")
        if 0 <= start < end:
            try:
                obj = json.loads(t[start : end + 1])
                return obj if isinstance(obj, dict) else None
            except (json.JSONDecodeError, ValueError):
                return None
        return None
