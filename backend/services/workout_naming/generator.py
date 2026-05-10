"""
Algorithmic workout-name generator.

See ``services.workout_naming.__init__`` for the public surface.

Design goals
------------
1. **Deterministic per (user, workout, day)** so the same workout doesn't
   re-render with a different name on every refresh.
2. **>95% unique across random seeds** for the same input shape — we are
   replacing Gemini specifically because Gemini collapsed onto ~5 words.
3. **Pure stdlib** — random, hashlib, datetime. No new deps, no LLM.
4. **Cheap** — typical generation is <1ms. The 8-attempt avoidance loop
   bounds worst-case work even when ``recent_names`` is large.
"""

from __future__ import annotations

import hashlib
import random
import re
from collections import Counter, deque
from datetime import date
from threading import Lock
from typing import Dict, List, Optional, Tuple

# Process-level rolling window of the last 100 generated names. Pushed to by
# `generate_workout_name` after every successful generation; consumed by the
# next call's hot-token avoidance loop. Validation harness 2026-05-09 found
# the top-5 names ("Titan Sculpting Peak", "Gentle Peak Performance", …) each
# appeared 17-18× in 486 rows. The deque is cross-user but per-process; in
# multi-worker deployments each worker keeps its own window which still
# decorrelates within a single worker's stream of requests.
_RECENT_NAMES: deque = deque(maxlen=100)
_RECENT_NAMES_LOCK = Lock()


def _push_recent_name(name: str) -> None:
    if not name:
        return
    with _RECENT_NAMES_LOCK:
        _RECENT_NAMES.append(name)


def _snapshot_recent_names() -> List[str]:
    with _RECENT_NAMES_LOCK:
        return list(_RECENT_NAMES)

from .pools import (
    DURATION_FLAVOR_BY_BUCKET,
    EQUIPMENT_TAG_BY_FAMILY,
    FOCUS_TAIL_BY_FOCUS,
    GOAL_NOUN_BY_GOAL,
    INTENSITY_ADJ_BY_DIFFICULTY,
    MYTHIC_PREFIX,
)


# ---------------------------------------------------------------------------
# Mapping helpers — translate caller vocabulary to pool keys.
# ---------------------------------------------------------------------------

# workout_type → goal pool. cardio↦endurance because that's where the
# "engine/mileage/furnace" flavor lives. mobility↦mobility (1:1).
_WORKOUT_TYPE_TO_GOAL: Dict[str, str] = {
    "strength": "strength",
    "hypertrophy": "hypertrophy",
    "endurance": "endurance",
    "cardio": "endurance",
    "mobility": "mobility",
    "stretch": "mobility",
    "flexibility": "mobility",
    "fat_loss": "fat_loss",
    "weight_loss": "fat_loss",
    "power": "power",
    "explosive": "power",
    "recovery": "recovery",
    "deload": "recovery",
    "rest": "recovery",
    "hybrid": "strength",
}

# Goal alias normalization (caller may pass "muscle_building", "lose weight", ...).
_GOAL_ALIASES: Dict[str, str] = {
    "muscle_building": "hypertrophy",
    "muscle_gain": "hypertrophy",
    "size": "hypertrophy",
    "build_muscle": "hypertrophy",
    "lose_weight": "fat_loss",
    "weight_loss": "fat_loss",
    "cut": "fat_loss",
    "lean_out": "fat_loss",
    "cardio": "endurance",
    "stamina": "endurance",
    "conditioning": "endurance",
    "stretch": "mobility",
    "flexibility": "mobility",
    "explosive": "power",
    "speed": "power",
    "athletic": "power",
    "rest": "recovery",
    "deload": "recovery",
    "active_recovery": "recovery",
    "powerlifting": "strength",
    "1rm": "strength",
}

# Focus aliases — collapse caller vocabulary onto the pool keys.
_FOCUS_ALIASES: Dict[str, str] = {
    "upper_body": "upper",
    "upperbody": "upper",
    "lower_body": "lower",
    "lowerbody": "lower",
    "leg": "legs",
    "leg_day": "legs",
    "abs": "core",
    "midsection": "core",
    "trunk": "core",
    "back": "pull",
    "chest": "push",
    "fullbody": "full_body",
    "full-body": "full_body",
    "total_body": "full_body",
    "total-body": "full_body",
    "shoulders": "push",
    "arms": "upper",
    "biceps": "pull",
    "triceps": "push",
    "glutes": "lower",
    "quads": "legs",
    "hamstrings": "lower",
    "calves": "lower",
    "stretch": "mobility",
    "flexibility": "mobility",
    "recovery": "mobility",
}

# Equipment family classifier. Maps raw equipment tokens (which arrive in
# many forms — "barbell", "Olympic Bar", "bench_press") to one of the
# EQUIPMENT_TAG_BY_FAMILY keys.
_EQUIPMENT_FAMILY_KEYWORDS: List[Tuple[str, Tuple[str, ...]]] = [
    ("barbell", ("barbell", "olympic", "bench", "rack", "platform", "deadlift bar", "squat bar")),
    ("dumbbell", ("dumbbell", "db",)),
    ("kettlebell", ("kettlebell", "kb", "bell")),
    ("bands", ("band", "loop", "tubing", "trx", "suspension")),
    ("machine", ("machine", "cable", "smith", "pulley", "selectorized", "pin-loaded", "leg press", "lat pull", "hammer strength")),
    ("cardio", ("treadmill", "rower", "bike", "elliptical", "ski-erg", "ski erg", "stair", "assault", "echo", "air bike", "cardio")),
    ("bodyweight", ("bodyweight", "none", "no_equipment", "no equipment", "mat", "floor", "self")),
]

# Duration buckets — keep the boundaries explicit so callers can read them.
def _bucket_duration(duration_minutes: Optional[int]) -> str:
    if duration_minutes is None or duration_minutes <= 0:
        return "30-60min"
    if duration_minutes <= 15:
        return "<=15min"
    if duration_minutes <= 30:
        return "15-30min"
    if duration_minutes <= 60:
        return "30-60min"
    return ">60min"


def _norm(s: Optional[str]) -> Optional[str]:
    if s is None:
        return None
    return str(s).strip().lower().replace("-", "_").replace(" ", "_")


def _resolve_goal(goal: Optional[str], workout_type: Optional[str]) -> str:
    """Pick the goal pool key. Defaults to 'strength' if nothing matches."""
    g = _norm(goal)
    if g:
        g = _GOAL_ALIASES.get(g, g)
        if g in GOAL_NOUN_BY_GOAL:
            return g
    wt = _norm(workout_type)
    if wt and wt in _WORKOUT_TYPE_TO_GOAL:
        mapped = _WORKOUT_TYPE_TO_GOAL[wt]
        if mapped in GOAL_NOUN_BY_GOAL:
            return mapped
    return "strength"


def _resolve_focus(focus: Optional[str], workout_type: Optional[str]) -> str:
    """Pick the focus tail pool key. Defaults to 'full_body'."""
    f = _norm(focus)
    if f:
        f = _FOCUS_ALIASES.get(f, f)
        if f in FOCUS_TAIL_BY_FOCUS:
            return f
        # graceful fallback for legs ↔ lower if one pool is empty
        if f == "legs" and "lower" in FOCUS_TAIL_BY_FOCUS:
            return "legs" if FOCUS_TAIL_BY_FOCUS.get("legs") else "lower"
    wt = _norm(workout_type)
    if wt in {"mobility", "stretch", "recovery", "flexibility"}:
        return "mobility"
    if wt in {"cardio", "endurance"}:
        return "full_body"
    return "full_body"


def _resolve_difficulty(difficulty: Optional[str], intensity_preference: Optional[str]) -> str:
    """Pick the intensity adjective pool key. Defaults to 'medium'."""
    d = _norm(difficulty) or _norm(intensity_preference)
    if d in INTENSITY_ADJ_BY_DIFFICULTY:
        return d
    # Common synonyms.
    synonyms = {
        "beginner": "easy", "novice": "easy", "low": "easy", "light": "easy",
        "intermediate": "medium", "moderate": "medium", "normal": "medium",
        "advanced": "hard", "high": "hard", "intense": "hard", "tough": "hard",
        "elite": "hell", "extreme": "hell", "insane": "hell", "max": "hell",
    }
    if d in synonyms:
        return synonyms[d]
    return "medium"


def _resolve_equipment_family(equipment: Optional[List[str]]) -> str:
    """Count occurrences of equipment families and return the dominant one."""
    if not equipment:
        return "bodyweight"
    counts: Counter[str] = Counter()
    for raw in equipment:
        if not raw:
            continue
        token = str(raw).lower()
        for family, keywords in _EQUIPMENT_FAMILY_KEYWORDS:
            if any(kw in token for kw in keywords):
                counts[family] += 1
                break
    if not counts:
        return "bodyweight"
    # Most common family wins; ties broken by EQUIPMENT_FAMILY order.
    return counts.most_common(1)[0][0]


# ---------------------------------------------------------------------------
# Seed derivation
# ---------------------------------------------------------------------------

def _derive_seed(
    user_id: Optional[str],
    workout_id: Optional[str],
    explicit_seed: Optional[int],
) -> int:
    """
    Stable seed: same (user, workout, today) => same name.

    We deliberately include ``today_iso`` so that if the same workout
    record is ever re-named later (e.g. a regen on a different day) the
    name can shift. For tests, callers pass ``seed`` directly.
    """
    if explicit_seed is not None:
        return int(explicit_seed)
    today_iso = date.today().isoformat()
    raw = f"{user_id or ''}|{workout_id or ''}|{today_iso}"
    digest = hashlib.sha256(raw.encode("utf-8")).digest()
    # Take 8 bytes for a 64-bit seed.
    return int.from_bytes(digest[:8], "big", signed=False)


# ---------------------------------------------------------------------------
# Templates
# ---------------------------------------------------------------------------

_TEMPLATES: List[Tuple[str, int]] = [
    ("intensity_goal_focus", 40),
    ("mythic_equipment_focus", 25),
    ("intensity_mythic_focus", 15),
    ("duration_goal_focus", 10),
    ("equipment_goal_focus", 10),
]


def _pick_template(rng: random.Random) -> str:
    total = sum(w for _, w in _TEMPLATES)
    n = rng.randint(1, total)
    cum = 0
    for name, w in _TEMPLATES:
        cum += w
        if n <= cum:
            return name
    return _TEMPLATES[0][0]


# ---------------------------------------------------------------------------
# Recent-name avoidance
# ---------------------------------------------------------------------------

_TOKEN_SPLIT_RE = re.compile(r"[^a-zA-Z]+")
_STOPWORDS = {
    "the", "a", "an", "of", "and", "or", "for", "with", "to", "in",
    "on", "by", "day", "hour", "session", "block", "stack", "set",
    "cycle", "pillar",
}


def _tokens_of(name: str) -> List[str]:
    return [
        t.lower()
        for t in _TOKEN_SPLIT_RE.split(name or "")
        if t and t.lower() not in _STOPWORDS and len(t) > 2
    ]


def _hot_tokens(recent_names: List[str], threshold: int = 3) -> set:
    """Tokens appearing >= ``threshold`` times across recent names."""
    counts: Counter[str] = Counter()
    for n in recent_names or []:
        for t in set(_tokens_of(n)):  # set() so each name contributes once
            counts[t] += 1
    return {t for t, c in counts.items() if c >= threshold}


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

def generate_workout_name(
    *,
    goal: Optional[str] = None,
    focus: Optional[str] = None,
    equipment: Optional[List[str]] = None,
    duration_minutes: Optional[int] = None,
    difficulty: Optional[str] = None,
    intensity_preference: Optional[str] = None,
    workout_type: Optional[str] = None,
    user_id: Optional[str] = None,
    workout_id: Optional[str] = None,
    recent_names: Optional[List[str]] = None,
    seed: Optional[int] = None,
) -> str:
    """
    Build a 2–4 token workout name from the curated pools.

    Returns Title-Cased, space-collapsed, max-60-char string. Never
    raises — degenerate inputs fall back to ``"<Focus> Session — Nm"``.
    """
    try:
        rng = random.Random(_derive_seed(user_id, workout_id, seed))

        goal_key = _resolve_goal(goal, workout_type)
        focus_key = _resolve_focus(focus, workout_type)
        diff_key = _resolve_difficulty(difficulty, intensity_preference)
        equip_key = _resolve_equipment_family(equipment)
        dur_key = _bucket_duration(duration_minutes)

        intensity_pool = INTENSITY_ADJ_BY_DIFFICULTY.get(diff_key) or []
        goal_pool = GOAL_NOUN_BY_GOAL.get(goal_key) or []
        equip_pool = EQUIPMENT_TAG_BY_FAMILY.get(equip_key) or []
        focus_pool = FOCUS_TAIL_BY_FOCUS.get(focus_key) or []
        duration_pool = DURATION_FLAVOR_BY_BUCKET.get(dur_key) or []
        mythic_pool = MYTHIC_PREFIX

        # Merge caller-supplied recent_names with the process-level rolling
        # window so callers that don't pass a list still get cross-call
        # avoidance. Validation harness 2026-05-09: top-10 share was 28% with
        # 5 names appearing 17-18× — the process deque squashes that.
        merged_recent = list(recent_names or []) + _snapshot_recent_names()
        hot = _hot_tokens(merged_recent, threshold=2)
        recent_full_set = {n.lower() for n in merged_recent if n}

        for _attempt in range(8):
            template = _pick_template(rng)
            tokens: List[str] = []

            if template == "intensity_goal_focus" and intensity_pool and goal_pool and focus_pool:
                tokens = [
                    rng.choice(intensity_pool),
                    rng.choice(goal_pool),
                    rng.choice(focus_pool),
                ]
            elif template == "mythic_equipment_focus" and mythic_pool and equip_pool and focus_pool:
                tokens = [
                    rng.choice(mythic_pool),
                    rng.choice(equip_pool),
                    rng.choice(focus_pool),
                ]
            elif template == "intensity_mythic_focus" and intensity_pool and mythic_pool and focus_pool:
                tokens = [
                    rng.choice(intensity_pool),
                    rng.choice(mythic_pool),
                    rng.choice(focus_pool),
                ]
            elif template == "duration_goal_focus" and duration_pool and goal_pool and focus_pool:
                tokens = [
                    rng.choice(duration_pool),
                    rng.choice(goal_pool),
                    rng.choice(focus_pool),
                ]
            elif template == "equipment_goal_focus" and equip_pool and goal_pool and focus_pool:
                tokens = [
                    rng.choice(equip_pool),
                    rng.choice(goal_pool),
                    rng.choice(focus_pool),
                ]
            else:
                # Template's required pool was empty — try another shape.
                continue

            # Hot-token avoidance: if any token recurs >= 3× in last 14d,
            # retry. We compare lowercase head tokens (split on non-alpha
            # so "Press Day" splits into "press"/"day", and "day" is in
            # _STOPWORDS so it won't trigger).
            head_tokens: set = set()
            for t in tokens:
                head_tokens.update(_tokens_of(t))
            if head_tokens & hot:
                continue

            name = _finalize(tokens)
            if name and name.lower() not in recent_full_set:
                _push_recent_name(name)
                return name

        # 8 attempts exhausted — fall back to deterministic shape.
        fallback = _fallback_name(focus, workout_type, duration_minutes)
        _push_recent_name(fallback)
        return fallback

    except Exception:
        # Never raise — naming is best-effort. Caller would lose its
        # whole workout otherwise.
        return _fallback_name(focus, workout_type, duration_minutes)


def _finalize(tokens: List[str]) -> str:
    """Join, Title-Case, collapse whitespace, cap at 60 chars."""
    text = " ".join(t.strip() for t in tokens if t and t.strip())
    text = re.sub(r"\s+", " ", text).strip()
    # Title-case but preserve interior caps (so "Cast-Iron" stays cased).
    text = " ".join(_smart_title(part) for part in text.split(" "))
    if len(text) > 60:
        text = text[:60].rstrip()
    return text


def _smart_title(token: str) -> str:
    """Title-case a single token, preserving hyphenated sub-tokens."""
    if not token:
        return token
    parts = token.split("-")
    cased = []
    for p in parts:
        if not p:
            cased.append(p)
            continue
        # Already mixed-case? Leave alone (e.g. "VO2", "Cast-Iron").
        if any(c.isupper() for c in p[1:]):
            cased.append(p)
        else:
            cased.append(p[:1].upper() + p[1:].lower())
    return "-".join(cased)


_FALLBACK_DESCRIPTORS = [
    "Session", "Block", "Builder", "Round", "Set", "Cycle", "Push",
    "Drive", "Sweep", "Lift", "Run", "Routine",
]


def _fallback_name(
    focus: Optional[str],
    workout_type: Optional[str],
    duration_minutes: Optional[int],
) -> str:
    """Safe fallback when pools are degenerate or hot-blocked. Rotates over
    `_FALLBACK_DESCRIPTORS` based on the recent-name deque size so that two
    fallbacks in a row don't return the same string (validation harness
    2026-05-09: the deterministic "Push Session — 45m" landed 5× in a 30-call
    test even after the recent-names dedup landed)."""
    label = focus or workout_type or "Workout"
    label = str(label).replace("_", " ").strip().title() or "Workout"
    minutes = int(duration_minutes) if (duration_minutes and duration_minutes > 0) else 45
    descriptor = _FALLBACK_DESCRIPTORS[len(_RECENT_NAMES) % len(_FALLBACK_DESCRIPTORS)]
    return f"{label} {descriptor} — {minutes}m"
