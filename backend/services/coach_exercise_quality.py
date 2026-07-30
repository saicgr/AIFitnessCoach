"""Quality gate for coach-authored exercise selection (E2E rows 97 + 63).

WHY
---
`generate_quick_workout` selects straight out of `exercise_library_cleaned` —
the noisy free-exercise dataset. Alongside real lifts it holds stretches, yoga
poses, warm-up drills, and a handful of rows whose "name" is a form CUE rather
than an exercise. With no quality gate the coach shipped, on real devices:

  * "Quick Power Upper Body" containing **"Chest Bench Press Correct Stance"**
    (a coaching cue, not an exercise) and **"Trx Body-Up"** for a user with no
    suspension trainer — the library row is mislabelled `equipment='Bodyweight'`,
    so column-level equipment gating could never catch it; the GEAR IS IN THE
    NAME.
  * "Quick Power Full Body" composed **entirely of stretches** (Calve Stretch
    Foot On Wall, Standing Forward Fold, Single-Leg Hamstring Stretch) — every
    one carries `category` in ('stretching','yoga'), which the selector never
    looked at.

The curated program backfill already solved the first half of this problem
(`scripts/backfill_thin_program_sessions.py`: `_JUNK_RE` + `_equip_matches`,
per CLAUDE.md "never select accessories alphabetically — ships junk like
'180 Jump Turns'"). This module REUSES those exact primitives — it does not
define a second junk regex — and adds the two gates the coach path additionally
needs: library `category` vs requested training intent, and gear named in the
exercise NAME vs the gear the user actually owns.

INTENT FAMILIES
---------------
`_JUNK_RE` bans jump/burpee/kick/crawl/hop/punch, which is right for a
hypertrophy accessory slot and WRONG for a HIIT/boxing/plyo session. So the
gates are applied per intent family:

  mobility-ish  (mobility, flexibility, yoga, stretching, recovery)
      → nothing excluded; stretches ARE the requested content.
  conditioning  (cardio, hiit, crossfit, hyrox, boxing, martial arts, sports…)
      → category + cue + gear gates. NO `_JUNK_RE` (plyometrics are the point).
  strength      (everything else — full_body, upper, chest, legs, core, …)
      → all four gates.

FAIL-OPEN CONTRACT
------------------
Per the standing rule that workout-generation guards must never zero out a
result, an INFRASTRUCTURE failure (the shared filter cannot be imported, the
category lookup errors) disables the affected gate and logs at ERROR with the
`[CoachQuality]` prefix — it never silently degrades and never raises into the
generator. A *content* shortfall is NOT handled by returning junk: the caller's
existing selection ladder (broaden focus → curated static bodyweight set) tops
the result back up with clean exercises, which is strictly better than putting
"Chest Bench Press Correct Stance" back in the workout.
"""
from __future__ import annotations

import re
from typing import Any, Dict, List, Optional, Sequence

from core.logger import get_logger

logger = get_logger(__name__)


# ── Reuse the curated backfill's filter primitives (single source of truth) ───
def _shared_primitives():
    """Import `_JUNK_RE` / `_equip_matches` from the curated backfill.

    Deliberately NOT re-implemented here: CLAUDE.md's junk filter has one home
    (`scripts/backfill_thin_program_sessions.py`) and a second copy would drift.
    Imported lazily so a coach request never pays the import cost twice and a
    packaging problem degrades to "no filter", not "no workout".
    """
    from scripts.backfill_thin_program_sessions import _JUNK_RE, _equip_matches
    return _JUNK_RE, _equip_matches


# Library `category` values that are NOT training content for a strength or
# conditioning request. Data-driven: these are literal values of
# exercise_library_cleaned.category (strength / cardio / stretching / core /
# yoga / plyometric / power / conditioning / functional / flexibility / balance).
_NON_TRAINING_CATEGORIES = {"stretching", "yoga", "flexibility", "balance"}

# Intent families (matched against the focus_area / workout_type the coach
# resolved). Anything unlisted is treated as strength — the conservative default.
_MOBILITY_INTENTS = {
    "mobility", "flexibility", "yoga", "stretching", "stretch", "recovery",
    "cooldown", "cool_down", "warmup", "warm_up", "prehab", "rehab",
}
_CONDITIONING_INTENTS = {
    "cardio", "hiit", "crossfit", "hyrox", "boxing", "martial_arts",
    "endurance", "conditioning", "full_body_power", "plyometric", "plyo",
    "cricket", "football", "basketball", "tennis", "soccer", "running",
}

# Rows whose "name" is a coaching CUE or media artifact rather than a movement
# ("Chest Bench Press Correct Stance"). Distinct from `_JUNK_RE`, which bans
# whole movement classes; these phrases mean "this row is not an exercise".
_CUE_NAME_RE = re.compile(
    r"(correct\s+(stance|form|grip|posture|position|technique)|"
    r"proper\s+(form|grip|stance|technique)|common\s+mistake|"
    r"\bhow\s+to\b|\btutorial\b|\bexplained\b|demonstration|"
    r"form\s+check|\bdo\s+it\s+right\b)",
    re.I,
)

# Brand / shorthand names that appear in exercise NAMES but never in the
# `equipment` column vocabulary. Everything else in the gear vocabulary is read
# straight off the library's own distinct equipment values, so new gear needs no
# code change — only genuine aliases live here.
_GEAR_NAME_ALIASES: Dict[str, str] = {
    "trx": "suspension trainer",
    "suspension": "suspension trainer",
    "swiss ball": "stability ball",
    "physio ball": "stability ball",
    "bosu": "bosu ball",
    "smith": "smith machine",
    "ez-bar": "ez bar",
    "ezbar": "ez bar",
    "rings": "gymnastic rings",
    "erg": "rowing machine",
}

# Equipment values that mean "no gear required".
_BODYWEIGHT_EQUIP = {"bodyweight", "body weight", "none", ""}

_MV = "exercise_library_cleaned"

# Cached gear vocabulary (distinct equipment values), refreshed per process.
_gear_vocab_cache: Optional[List[str]] = None


def _intent_family(intent: str) -> str:
    key = (intent or "").strip().lower().replace(" ", "_").replace("-", "_")
    if key in _MOBILITY_INTENTS:
        return "mobility"
    if key in _CONDITIONING_INTENTS:
        return "conditioning"
    return "strength"


def _gear_vocabulary(db) -> List[str]:
    """Distinct non-bodyweight equipment values from the library, longest first.

    Read from the data so newly imported gear is gated automatically. Cached for
    the life of the process (the library's equipment vocabulary is ~100 values
    and changes only on import).
    """
    global _gear_vocab_cache
    if _gear_vocab_cache is not None:
        return _gear_vocab_cache
    terms = set(_GEAR_NAME_ALIASES.keys())
    try:
        rows = db.client.table(_MV).select("equipment").limit(5000).execute().data or []
        for r in rows:
            raw = (r.get("equipment") or "").lower()
            for part in raw.split(","):
                part = part.strip()
                if part and part not in _BODYWEIGHT_EQUIP:
                    terms.add(part)
    except Exception as e:
        logger.error(f"[CoachQuality] gear vocabulary query failed: {e}", exc_info=True)
        # Aliases alone still catch the observed TRX case.
    _gear_vocab_cache = sorted(terms, key=len, reverse=True)
    return _gear_vocab_cache


def _categories_for(db, names: Sequence[str]) -> Dict[str, str]:
    """Bulk `name -> category` lookup for the candidate names (ONE indexed query)."""
    wanted = [n for n in names if n]
    if not wanted:
        return {}
    try:
        rows = (
            db.client.table(_MV).select("name, category")
            .in_("name", wanted).limit(len(wanted) * 2).execute()
        ).data or []
        return {
            (r.get("name") or "").strip().lower(): (r.get("category") or "").strip().lower()
            for r in rows
        }
    except Exception as e:
        logger.error(f"[CoachQuality] category lookup failed: {e}", exc_info=True)
        return {}


def _name_gear_requirement(name: str, vocab: Sequence[str]) -> Optional[str]:
    """Canonical equipment implied by the exercise NAME, or None.

    Catches library rows whose `equipment` column is wrong — e.g. "Trx Body-Up"
    is stored as `Bodyweight`, so only the name reveals it needs a suspension
    trainer.
    """
    n = f" {(name or '').lower().replace('-', ' ')} "
    for term in vocab:
        t = term.replace("-", " ")
        if re.search(rf"(?<![a-z]){re.escape(t)}(?![a-z])", n):
            return _GEAR_NAME_ALIASES.get(term, term)
    return None


def filter_candidates(
    db,
    candidates: List[Dict[str, Any]],
    *,
    training_intent: str,
    user_equipment: Optional[List[str]] = None,
) -> List[Dict[str, Any]]:
    """Drop library junk / off-intent / un-owned-gear rows from a candidate list.

    Args:
        db: supabase db facade (needs `.client`).
        candidates: rows as produced by `services.workout_fallback` (dicts with
            at least `name`; `equipment` when known).
        training_intent: the resolved focus_area / workout_type (e.g.
            "full_body", "chest", "hiit", "mobility").
        user_equipment: the user's equipment list from their profile.

    Returns a NEW list preserving input order. May be shorter than the input
    (or empty) — the caller is expected to top up from its clean static set.
    """
    if not candidates:
        return candidates

    family = _intent_family(training_intent)
    if family == "mobility":
        # Stretches / poses are exactly what was asked for; only the cue-name
        # and gear gates still apply.
        junk_re = None
        drop_categories: set = set()
    else:
        drop_categories = set(_NON_TRAINING_CATEGORIES)
        junk_re = None
        if family == "strength":
            try:
                junk_re, _ = _shared_primitives()
            except Exception as e:
                logger.error(
                    f"[CoachQuality] could not import the shared junk filter "
                    f"({e}) — name-level junk gating is OFF for this request",
                    exc_info=True,
                )

    try:
        _, equip_matches = _shared_primitives()
    except Exception as e:
        logger.error(
            f"[CoachQuality] could not import the shared equipment matcher ({e}) "
            f"— gear gating is OFF for this request", exc_info=True
        )
        equip_matches = None

    allowed_equipment = [e for e in (user_equipment or []) if e]
    vocab = _gear_vocabulary(db) if equip_matches else []
    categories = _categories_for(db, [c.get("name", "") for c in candidates]) if drop_categories else {}

    kept: List[Dict[str, Any]] = []
    dropped: List[str] = []
    for c in candidates:
        name = (c.get("name") or "").strip()
        if not name:
            continue

        if _CUE_NAME_RE.search(name):
            dropped.append(f"{name} (coaching cue, not an exercise)")
            continue

        if junk_re is not None and junk_re.search(name):
            dropped.append(f"{name} (library junk)")
            continue

        cat = categories.get(name.lower())
        if cat and cat in drop_categories:
            dropped.append(f"{name} (category={cat}, off-intent for {training_intent})")
            continue

        if equip_matches is not None:
            required = _name_gear_requirement(name, vocab)
            if required and not equip_matches(required, allowed_equipment):
                dropped.append(f"{name} (needs '{required}', user has {allowed_equipment or 'bodyweight only'})")
                continue

        kept.append(c)

    if dropped:
        logger.info(
            f"[CoachQuality] intent={training_intent} family={family}: dropped "
            f"{len(dropped)}/{len(candidates)} -> {dropped[:8]}"
        )

    if not kept:
        logger.warning(
            f"[CoachQuality] every candidate failed the gate for "
            f"intent={training_intent} ({len(candidates)} in) — caller's "
            f"broaden/static ladder will supply clean exercises"
        )

    return kept
