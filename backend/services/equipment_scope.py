"""Deterministic equipment -> per-gym-progress-scope classifier.

The root problem per-gym tracking solves: the SAME selected weight on a cable/stack/
plate-loaded machine is mechanically different across gyms (1:1 vs 2:1 pulleys, different
stack graduations, different brands), so pooling those numbers makes per-exercise progress
meaningless. Free weights (a barbell, a dumbbell, a kettlebell) are the same load anywhere,
so their history IS comparable across gyms and should NOT be fragmented by gym.

So each exercise gets a DEFAULT progress scope, decided purely from its
``exercise_library.equipment`` string (no LLM — per the never-LLM-classify rule):

  * ``per_gym``  -> machines / cables / smith / plate-loaded / iso-lateral selectorized gear.
                   Default progress view = "this gym only"; weight suggestions pull same-gym
                   history; PRs are scoped per gym.
  * ``combined`` -> free weights + bodyweight + bands + everything else. Default progress view
                   = "all gyms combined"; PRs and suggestions pool across gyms.

The user can always override the scope per exercise in the UI; this only decides the DEFAULT.

This module is mirrored on the client in
``mobile/flutter/lib/core/utils/equipment_scope.dart`` — keep the keyword lists in sync.
"""

from __future__ import annotations

SCOPE_PER_GYM = "per_gym"
SCOPE_COMBINED = "combined"

# Substrings that mark gear whose effective load varies by gym/machine. Matched
# case-insensitively against the equipment string (and, as a fallback, the exercise name).
# Verified against the live distinct exercise_library.equipment vocabulary (2026-06).
_PER_GYM_KEYWORDS: tuple[str, ...] = (
    "machine",          # cable machine, leg press machine, *-press machine, multi-hip machine, ...
    "cable",            # cable machine, cable crossover, seated cable row
    "smith",            # smith machine
    "pulldown",         # lat pulldown
    "pull-down",
    "pec deck",
    "pec fly",
    "hack squat",
    "hammer strength",  # hammer strength mts iso-lateral *  (no literal "machine" token)
    "iso-lateral",
    "iso lateral",
    "plate-loaded",
    "plate loaded",
    "selectorized",
    "crossover",
    "leg press",
    "leg extension",
    "leg curl",
    "lat pull",
)

# Name-only hints used when the equipment string is blank/unknown. Kept tighter than the
# equipment list to avoid false positives on free-weight movements that merely mention a body part.
_PER_GYM_NAME_HINTS: tuple[str, ...] = (
    "cable",
    "machine",
    "pulldown",
    "pull-down",
    "pec deck",
    "pec fly",
    "leg press",
    "leg extension",
    "leg curl",
    "smith machine",
    "hack squat",
    "lat pulldown",
)


def default_scope(equipment: str | None, exercise_name: str | None = None) -> str:
    """Return ``SCOPE_PER_GYM`` or ``SCOPE_COMBINED`` for an exercise.

    Decision is conservative: an unknown/blank equipment with no machine/cable hint in the
    name defaults to ``combined`` so we never fragment a genuinely-comparable lift by gym.
    """
    eq = (equipment or "").strip().lower()
    if eq and any(k in eq for k in _PER_GYM_KEYWORDS):
        return SCOPE_PER_GYM
    if not eq:
        name = (exercise_name or "").strip().lower()
        if name and any(k in name for k in _PER_GYM_NAME_HINTS):
            return SCOPE_PER_GYM
    return SCOPE_COMBINED


def is_per_gym(equipment: str | None, exercise_name: str | None = None) -> bool:
    """True when this exercise's progress should default to per-gym segmentation."""
    return default_scope(equipment, exercise_name) == SCOPE_PER_GYM
