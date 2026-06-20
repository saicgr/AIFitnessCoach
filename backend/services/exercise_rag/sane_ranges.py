"""Static, module-level constants for the deterministic robustness guards.

This module is the single home for the lookup tables shared by the selection +
prescription hardening guards (filters.py A1, formatting.py B, selection_pipeline.py
C). Every table here is built ONCE at import time and is read-only — no I/O, no
LLM, no per-call construction. Keep it dependency-free (only stdlib + typing) so
every consumer can import it without import cycles.

Three concerns live here:

  1. ``classify_movement_pattern(name)`` — a deterministic name→pattern
     classifier (press / squat / hinge / pull / lunge / isolation / core /
     carry / olympic / bodyweight_push|pull|squat|core / other). Coarser than
     the safety-index ``movement_pattern`` column (which we don't always have in
     memory) but sufficient for sane-range + regression decisions.

  2. ``SANE_WEIGHT_RANGE_KG`` — per (pattern × level) sane *working* load
     bands in kg, used by formatting.py to detect when an owned-weights snap
     produced an absurd load (50 lb beginner lateral raise; 5 lb squat) and to
     deterministically adjust reps/RIR instead of prescribing the absurd load.
     Bands are intentionally WIDE (5th–95th-percentile gym loads, lbs→kg) so a
     normal prescription never trips them — the guard is for the pathological
     "the only weight you own is wrong for this movement" case.

  3. ``REGRESSION_PATTERNS`` / ``PROGRESSION_PATTERNS`` — capacity-aware
     swap maps. When a user can't do a movement's baseline (0 push-ups but the
     plan has standard push-ups) we prefer an EASIER same-pattern variant
     already in the candidate pool; advanced bodyweight users bias to harder
     variants. Keyed by the coarse pattern so the maps stay small + auditable.

All of the consuming guards FAIL OPEN: if a name doesn't classify, or a pattern
has no band/regression entry, the guard does nothing and output is unchanged.
"""

from __future__ import annotations

from typing import Dict, List, Optional, Tuple

# ---------------------------------------------------------------------------
# 1. Movement-pattern classifier
# ---------------------------------------------------------------------------
# Coarse pattern tokens. Bodyweight variants get their own pattern so the
# regression/progression maps and the sane-range bands can treat a bodyweight
# push differently from a loaded press.
PATTERN_PRESS = "press"                # loaded horizontal/overhead press
PATTERN_SQUAT = "squat"                # loaded squat-pattern
PATTERN_HINGE = "hinge"                # deadlift / RDL / hip hinge (loaded)
PATTERN_PULL = "pull"                  # loaded row / pulldown / pull
PATTERN_LUNGE = "lunge"                # loaded split-stance
PATTERN_ISOLATION = "isolation"        # single-joint accessory (curl, raise, fly…)
PATTERN_CORE = "core"                  # trunk (crunch, plank, leg raise…)
PATTERN_CARRY = "carry"                # loaded carries
PATTERN_OLYMPIC = "olympic"            # clean/snatch/jerk
PATTERN_BW_PUSH = "bodyweight_push"    # push-up family
PATTERN_BW_PULL = "bodyweight_pull"    # pull-up / chin-up family
PATTERN_BW_SQUAT = "bodyweight_squat"  # air squat / pistol / lunge bodyweight
PATTERN_BW_CORE = "bodyweight_core"    # bodyweight trunk holds
PATTERN_OTHER = "other"

# Ordered (substring, pattern) — FIRST match wins, so list the most specific /
# bodyweight signals before the generic loaded ones. Lowercased name matched
# with plain `in` (cheap; no regex). Order matters: e.g. "pistol squat" must hit
# bodyweight_squat before the generic "squat" press; "push up" before "press".
_PATTERN_RULES: Tuple[Tuple[str, str], ...] = (
    # --- Bodyweight push (push-up family) ---
    ("push-up", PATTERN_BW_PUSH), ("push up", PATTERN_BW_PUSH),
    ("pushup", PATTERN_BW_PUSH), ("pike push", PATTERN_BW_PUSH),
    ("dip", PATTERN_BW_PUSH),
    # --- Bodyweight pull (pull-up / chin-up / inverted row) ---
    ("pull-up", PATTERN_BW_PULL), ("pull up", PATTERN_BW_PULL),
    ("pullup", PATTERN_BW_PULL), ("chin-up", PATTERN_BW_PULL),
    ("chin up", PATTERN_BW_PULL), ("chinup", PATTERN_BW_PULL),
    ("inverted row", PATTERN_BW_PULL), ("muscle-up", PATTERN_BW_PULL),
    ("muscle up", PATTERN_BW_PULL),
    # --- Bodyweight squat / single-leg bodyweight ---
    ("pistol squat", PATTERN_BW_SQUAT), ("air squat", PATTERN_BW_SQUAT),
    ("bodyweight squat", PATTERN_BW_SQUAT), ("shrimp squat", PATTERN_BW_SQUAT),
    ("jump squat", PATTERN_BW_SQUAT), ("squat jump", PATTERN_BW_SQUAT),
    # --- Bodyweight core ---
    ("plank", PATTERN_BW_CORE), ("hollow hold", PATTERN_BW_CORE),
    ("l-sit", PATTERN_BW_CORE), ("hanging leg raise", PATTERN_BW_CORE),
    ("dead bug", PATTERN_BW_CORE), ("bird dog", PATTERN_BW_CORE),
    # --- Olympic lifts (before squat/press so "clean and press" -> olympic) ---
    ("snatch", PATTERN_OLYMPIC), ("clean and jerk", PATTERN_OLYMPIC),
    ("clean and press", PATTERN_OLYMPIC), ("power clean", PATTERN_OLYMPIC),
    ("hang clean", PATTERN_OLYMPIC), ("jerk", PATTERN_OLYMPIC),
    # --- Carries ---
    ("carry", PATTERN_CARRY), ("farmer", PATTERN_CARRY),
    ("suitcase", PATTERN_CARRY), ("waiter walk", PATTERN_CARRY),
    # --- Hinge (loaded) ---
    ("deadlift", PATTERN_HINGE), ("romanian", PATTERN_HINGE),
    ("rdl", PATTERN_HINGE), ("good morning", PATTERN_HINGE),
    ("hip thrust", PATTERN_HINGE), ("glute bridge", PATTERN_HINGE),
    ("kettlebell swing", PATTERN_HINGE), ("swing", PATTERN_HINGE),
    # --- Lunge (loaded split stance) ---
    ("lunge", PATTERN_LUNGE), ("split squat", PATTERN_LUNGE),
    ("step-up", PATTERN_LUNGE), ("step up", PATTERN_LUNGE),
    # --- Squat (loaded) ---
    ("squat", PATTERN_SQUAT), ("leg press", PATTERN_SQUAT),
    ("hack squat", PATTERN_SQUAT),
    # --- Press (loaded) ---
    ("bench press", PATTERN_PRESS), ("overhead press", PATTERN_PRESS),
    ("shoulder press", PATTERN_PRESS), ("chest press", PATTERN_PRESS),
    ("incline press", PATTERN_PRESS), ("decline press", PATTERN_PRESS),
    ("military press", PATTERN_PRESS), ("floor press", PATTERN_PRESS),
    ("push press", PATTERN_PRESS), ("z press", PATTERN_PRESS),
    ("press", PATTERN_PRESS),
    # --- Pull (loaded row / pulldown) ---
    ("pulldown", PATTERN_PULL), ("lat pull", PATTERN_PULL),
    ("barbell row", PATTERN_PULL), ("bent over row", PATTERN_PULL),
    ("bent-over row", PATTERN_PULL), ("seated row", PATTERN_PULL),
    ("cable row", PATTERN_PULL), ("dumbbell row", PATTERN_PULL),
    ("t-bar row", PATTERN_PULL), ("pendlay", PATTERN_PULL),
    ("face pull", PATTERN_ISOLATION),  # light accessory, not a heavy row
    ("row", PATTERN_PULL),
    # --- Core (loaded / trunk) ---
    ("crunch", PATTERN_CORE), ("sit-up", PATTERN_CORE), ("situp", PATTERN_CORE),
    ("sit up", PATTERN_CORE), ("russian twist", PATTERN_CORE),
    ("leg raise", PATTERN_CORE), ("wood chop", PATTERN_CORE),
    ("woodchop", PATTERN_CORE), ("pallof", PATTERN_CORE),
    ("ab wheel", PATTERN_CORE), ("cable crunch", PATTERN_CORE),
    # --- Isolation (single-joint accessory) ---
    ("curl", PATTERN_ISOLATION), ("extension", PATTERN_ISOLATION),
    ("lateral raise", PATTERN_ISOLATION), ("front raise", PATTERN_ISOLATION),
    ("rear delt", PATTERN_ISOLATION), ("reverse fly", PATTERN_ISOLATION),
    ("fly", PATTERN_ISOLATION), ("flye", PATTERN_ISOLATION),
    ("raise", PATTERN_ISOLATION), ("kickback", PATTERN_ISOLATION),
    ("shrug", PATTERN_ISOLATION), ("calf raise", PATTERN_ISOLATION),
    ("pec deck", PATTERN_ISOLATION), ("preacher", PATTERN_ISOLATION),
    ("concentration", PATTERN_ISOLATION), ("pushdown", PATTERN_ISOLATION),
    ("tricep", PATTERN_ISOLATION), ("bicep", PATTERN_ISOLATION),
)


def classify_movement_pattern(exercise_name: Optional[str]) -> str:
    """Return the coarse movement pattern for an exercise name.

    Pure, deterministic, O(len(_PATTERN_RULES)). Returns ``PATTERN_OTHER`` when
    nothing matches — every consumer must treat ``other`` as "no special
    handling" (fail-open).
    """
    if not exercise_name:
        return PATTERN_OTHER
    n = exercise_name.lower()
    for needle, pattern in _PATTERN_RULES:
        if needle in n:
            return pattern
    return PATTERN_OTHER


# Patterns that carry no external load — the sane-range guard never applies to
# them (their working "load" is bodyweight). Exposed so formatting.py can skip
# cheaply.
BODYWEIGHT_PATTERNS: frozenset = frozenset(
    {PATTERN_BW_PUSH, PATTERN_BW_PULL, PATTERN_BW_SQUAT, PATTERN_BW_CORE}
)


# ---------------------------------------------------------------------------
# 2. Sane working-load bands (kg) per pattern × level
# ---------------------------------------------------------------------------
# (min_kg, max_kg) for a SINGLE implement / the prescribed bar/stack load, by
# user level. Bands are deliberately wide — roughly the 5th–95th percentile of
# real gym working loads (sourced from Strength Level population data, lbs→kg).
# The guard only fires when an owned-weights snap lands OUTSIDE the band, which
# is the pathological "only 50 lb dumbbells -> 50 lb beginner lateral raise" or
# "only 5 lb -> 5 lb squat" case. A None band (e.g. bodyweight pattern, other)
# disables the guard for that exercise.
#
# Interpretation: these are PER-IMPLEMENT for dumbbell/kettlebell movements
# (one dumbbell), and total-bar/stack for barbell/machine. formatting.py already
# works in single-implement kg for dumbbells, so per-implement is the right unit.
_LVL_BEGINNER = "beginner"
_LVL_INTERMEDIATE = "intermediate"
_LVL_ADVANCED = "advanced"

# Bands keyed by (pattern, level). Only loaded patterns are present.
SANE_WEIGHT_RANGE_KG: Dict[Tuple[str, str], Tuple[float, float]] = {
    # Press (per dumbbell, or total bar) — light pressing for beginners.
    (PATTERN_PRESS, _LVL_BEGINNER): (5.0, 35.0),
    (PATTERN_PRESS, _LVL_INTERMEDIATE): (10.0, 70.0),
    (PATTERN_PRESS, _LVL_ADVANCED): (20.0, 130.0),
    # Squat (loaded) — bigger absolute loads.
    (PATTERN_SQUAT, _LVL_BEGINNER): (10.0, 50.0),
    (PATTERN_SQUAT, _LVL_INTERMEDIATE): (25.0, 110.0),
    (PATTERN_SQUAT, _LVL_ADVANCED): (50.0, 200.0),
    # Hinge (deadlift family) — largest loads.
    (PATTERN_HINGE, _LVL_BEGINNER): (15.0, 70.0),
    (PATTERN_HINGE, _LVL_INTERMEDIATE): (40.0, 140.0),
    (PATTERN_HINGE, _LVL_ADVANCED): (70.0, 250.0),
    # Pull (rows / pulldowns).
    (PATTERN_PULL, _LVL_BEGINNER): (5.0, 40.0),
    (PATTERN_PULL, _LVL_INTERMEDIATE): (15.0, 90.0),
    (PATTERN_PULL, _LVL_ADVANCED): (30.0, 150.0),
    # Lunge / split squat (per dumbbell or total).
    (PATTERN_LUNGE, _LVL_BEGINNER): (2.5, 25.0),
    (PATTERN_LUNGE, _LVL_INTERMEDIATE): (7.5, 50.0),
    (PATTERN_LUNGE, _LVL_ADVANCED): (15.0, 90.0),
    # Carry (per implement).
    (PATTERN_CARRY, _LVL_BEGINNER): (5.0, 30.0),
    (PATTERN_CARRY, _LVL_INTERMEDIATE): (15.0, 60.0),
    (PATTERN_CARRY, _LVL_ADVANCED): (25.0, 100.0),
    # Isolation (curls / raises / extensions — light per dumbbell).
    (PATTERN_ISOLATION, _LVL_BEGINNER): (1.0, 15.0),
    (PATTERN_ISOLATION, _LVL_INTERMEDIATE): (4.0, 30.0),
    (PATTERN_ISOLATION, _LVL_ADVANCED): (8.0, 50.0),
    # Loaded core (cable crunch / weighted leg raise).
    (PATTERN_CORE, _LVL_BEGINNER): (2.5, 20.0),
    (PATTERN_CORE, _LVL_INTERMEDIATE): (5.0, 40.0),
    (PATTERN_CORE, _LVL_ADVANCED): (10.0, 70.0),
    # Olympic (technical — modest beginner loads).
    (PATTERN_OLYMPIC, _LVL_BEGINNER): (10.0, 40.0),
    (PATTERN_OLYMPIC, _LVL_INTERMEDIATE): (25.0, 80.0),
    (PATTERN_OLYMPIC, _LVL_ADVANCED): (50.0, 150.0),
}


def sane_weight_range_kg(
    pattern: str, fitness_level: Optional[str]
) -> Optional[Tuple[float, float]]:
    """Return the (min_kg, max_kg) sane band for a pattern × level, or None.

    None ⇒ no band ⇒ the sane-range guard is a no-op (fail-open). Unknown
    levels normalize to intermediate (the middle band) rather than disabling
    the guard, so a missing/garbage level still gets reasonable protection.
    """
    if pattern in BODYWEIGHT_PATTERNS or pattern == PATTERN_OTHER:
        return None
    lvl = (fitness_level or "").strip().lower()
    if lvl not in (_LVL_BEGINNER, _LVL_INTERMEDIATE, _LVL_ADVANCED):
        lvl = _LVL_INTERMEDIATE
    return SANE_WEIGHT_RANGE_KG.get((pattern, lvl))


# ---------------------------------------------------------------------------
# 3. Capacity-aware regression / progression pattern maps
# ---------------------------------------------------------------------------
# Maps a coarse bodyweight pattern to ORDERED lists of name substrings, easiest
# first (regressions) / hardest first (progressions). Used by selection_pipeline
# to prefer an easier same-pattern variant from the *in-memory candidate pool*
# when the user can't do the baseline movement, or a harder one for advanced
# bodyweight users. Matched with plain substring `in` against candidate names.
#
# These are SIGNALS for re-ranking within the existing pool — never used to
# fetch new exercises. If no pool candidate matches, the guard is a no-op.
REGRESSION_PATTERNS: Dict[str, List[str]] = {
    # Push-up regressions, easiest → harder.
    PATTERN_BW_PUSH: [
        "wall push", "incline push", "knee push", "kneeling push",
        "negative push", "push-up", "push up", "pushup",
    ],
    # Pull-up regressions, easiest → harder.
    PATTERN_BW_PULL: [
        "dead hang", "scapular pull", "ring row", "inverted row",
        "assisted pull", "band pull-up", "band pull up", "negative pull",
        "jumping pull", "chin-up", "chin up", "pull-up", "pull up",
    ],
    # Squat regressions, easiest → harder.
    PATTERN_BW_SQUAT: [
        "box squat", "chair squat", "assisted squat", "air squat",
        "bodyweight squat", "split squat", "bulgarian", "pistol",
    ],
    # Core regressions, easiest → harder.
    PATTERN_BW_CORE: [
        "dead bug", "bird dog", "knee plank", "plank", "hollow hold", "l-sit",
    ],
}

# Progressions: hardest first — advanced bodyweight users bias toward these.
PROGRESSION_PATTERNS: Dict[str, List[str]] = {
    PATTERN_BW_PUSH: [
        "planche", "one arm push", "archer push", "pseudo planche",
        "decline push", "diamond push", "pike push",
    ],
    PATTERN_BW_PULL: [
        "one arm pull", "muscle-up", "muscle up", "archer pull",
        "wide grip pull", "weighted pull", "l-sit pull",
    ],
    PATTERN_BW_SQUAT: [
        "pistol", "shrimp squat", "jump squat", "bulgarian", "split squat",
    ],
    PATTERN_BW_CORE: [
        "dragon flag", "l-sit", "hollow rock", "hanging leg raise",
    ],
}

# Capacity thresholds: a user reporting strictly fewer than the baseline reps /
# seconds for a movement "can't do the baseline" and should get a regression.
# Conservative — only the clearly-can't case (0/very low) triggers a swap.
# Keyed by the coarse bodyweight pattern.
CAPACITY_BASELINE: Dict[str, int] = {
    PATTERN_BW_PUSH: 1,    # < 1 push-up
    PATTERN_BW_PULL: 1,    # < 1 pull-up
    PATTERN_BW_SQUAT: 1,   # < 1 bodyweight squat (rare; near-zero mobility)
    PATTERN_BW_CORE: 10,   # < 10s plank hold
}

# Above these the user is clearly ADVANCED at the bodyweight movement and an
# advanced-level user should bias toward a harder variant.
CAPACITY_ADVANCED: Dict[str, int] = {
    PATTERN_BW_PUSH: 40,   # 40+ push-ups
    PATTERN_BW_PULL: 12,   # 12+ pull-ups
    PATTERN_BW_SQUAT: 50,  # 50+ squats
    PATTERN_BW_CORE: 90,   # 90s+ plank
}

# Which capacity field gates which pattern. The capacity dict passed by callers
# uses these keys (mirrors the DB columns pushup/pullup/plank/squat capacity).
PATTERN_CAPACITY_FIELD: Dict[str, str] = {
    PATTERN_BW_PUSH: "pushup",
    PATTERN_BW_PULL: "pullup",
    PATTERN_BW_SQUAT: "squat",
    PATTERN_BW_CORE: "plank",
}
