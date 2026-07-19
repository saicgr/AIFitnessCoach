"""Deterministic inline-action inference for chat turns.

ADDITIVE post-processor. Runs AFTER an agent has produced its reply text and
any structured `action_data`. It ONLY proposes a NEW `action_data` when the
agent did not already emit one — it never overwrites an existing action like
`food_analysis`, `generate_quick_workout`, `event_logged`, etc.

The frontend renders an inline "go-to" button for each of these NEW action
types only when present, so a wrong/over-eager match is worse than no match.
Every rule here is therefore CONSERVATIVE (deterministic keyword checks, first
match wins) and NO LLM call is involved.

New inline actions emitted (see frontend chat action handler):
  - log_hydration       -> drinking water / hydration advice
  - log_weight          -> reply asks the user to log/share bodyweight
  - reference_progress  -> reply references a PR or general progress/improvement
  - reference_exercise  -> reply names a specific exercise to learn (OPTIONAL,
                           only when a cheap id/name resolution is safe)
  - reference_recipe    -> nutrition agent produced structured recipe data
"""

import logging
import re
from typing import Any, Dict, List, Optional

logger = logging.getLogger(__name__)


# ── Keyword tables (all matched case-insensitive) ────────────────────────────

# Strong hydration signals. Kept tight to avoid firing on passing mentions of
# "water weight" etc. — those are filtered by requiring a drink/hydrate verb.
_HYDRATION_PHRASES = (
    "stay hydrated",
    "drink water",
    "drink more water",
    "drinking water",
    "drink some water",
    "glasses of water",
    "log your water",
    "log some water",
    "hydration",
    "hydrate",
    "water intake",
)

# Reply is prompting the user to tell us / log their bodyweight.
_LOG_WEIGHT_PHRASES = (
    "what's your current weight",
    "what is your current weight",
    "your current weight",
    "log your weight",
    "log your bodyweight",
    "log your body weight",
    "update your weight",
    "share your weight",
    "what's your weight",
    "what is your weight",
    "what do you weigh",
)

# Personal-record signals (checked before generic progress so a PR wins).
_PR_PHRASES = (
    "personal record",
    "personal best",
    "new record",
    "pr!",
    " pr ",
    " pr.",
    " pr,",
    "(pr)",
    "new pr",
    "set a pr",
    "hit a pr",
    "all-time high",
    "all time high",
)

# Generic progress / improvement signals.
_PROGRESS_PHRASES = (
    "you've improved",
    "you have improved",
    "your progress",
    "you're progressing",
    "you are progressing",
    "trending up",
    "trending upward",
    "you're getting stronger",
    "you are getting stronger",
    "you've come a long way",
    "great improvement",
    "improving over time",
    "keep up the progress",
)


# Explicit "schedule this workout" intent. Kept specific so a passing mention of
# "your schedule" doesn't fire it; also requires a resolvable workout_id.
_SCHEDULE_PHRASES = (
    "schedule this workout",
    "schedule it for",
    "schedule this for",
    "schedule it",
    "add it to your plan",
    "add this to your plan",
    "add it to your calendar",
    "put it on your calendar",
    "plan it for",
    "want me to schedule",
    "should i schedule",
)


# Technique/instruction cues. The "How to do X" chip must only fire when the
# reply actually offers a how-to — otherwise a bare exercise-name mention (e.g.
# "nice chest press today!") wrongly emits a tutorial chip. Requiring one of
# these signals keeps the chip relevant to a genuine form/technique reply.
_HOWTO_CUES = (
    "how to",
    "how do you",
    "how do i",
    "form",
    "technique",
    "demo",
    "tutorial",
    "proper",
    "properly",
    "instructions",
    "cue",
    "step",
)


def _text_has_any(text_lower: str, phrases) -> bool:
    return any(p in text_lower for p in phrases)


# ── Exercise-name matcher (lazy, cached) ─────────────────────────────────────
# The coach says short movement names ("Romanian deadlifts") while the library
# stores qualified ones ("Barbell Romanian Deadlift"). So we match the reply
# against a CURATED vocabulary of canonical movement phrases (zero false
# positives — every entry is unambiguously an exercise), then resolve each to a
# real library row by containment to get the id for the "How to do X" button.
_CANONICAL_EXERCISES = (
    "romanian deadlift", "sumo deadlift", "stiff leg deadlift", "deadlift",
    "bulgarian split squat", "split squat", "goblet squat", "front squat",
    "back squat", "hack squat", "overhead squat", "squat",
    "incline bench press", "decline bench press", "bench press", "chest press",
    "overhead press", "shoulder press", "arnold press", "push press",
    "lat pulldown", "pulldown", "bent over row", "barbell row", "dumbbell row",
    "seated row", "cable row", "upright row", "inverted row", "pendlay row",
    "hip thrust", "glute bridge", "good morning", "back extension", "hyperextension",
    "lateral raise", "front raise", "rear delt fly", "face pull", "shrug",
    "bicep curl", "hammer curl", "preacher curl", "concentration curl", "spider curl",
    "tricep extension", "tricep pushdown", "skull crusher", "overhead extension",
    "leg press", "leg curl", "leg extension", "calf raise", "nordic curl",
    "walking lunge", "reverse lunge", "lateral lunge", "lunge", "step up",
    "pull up", "chin up", "push up", "dip", "muscle up",
    "dumbbell fly", "cable fly", "pec deck", "pullover",
    "kettlebell swing", "box jump", "wall sit", "plank", "side plank",
    "russian twist", "mountain climber", "burpee", "thruster", "clean and press",
    "farmer carry", "wall ball", "sit up", "hanging leg raise", "hollow hold",
)
_CANON_REGEX: Optional["re.Pattern"] = None
_EXERCISE_RESOLVE: Optional[List[tuple]] = None  # (name_lower, name, id)
_EXERCISE_INDEX_TRIED = False


def _ensure_exercise_index() -> None:
    global _CANON_REGEX, _EXERCISE_RESOLVE, _EXERCISE_INDEX_TRIED
    if _EXERCISE_INDEX_TRIED:
        return
    _EXERCISE_INDEX_TRIED = True
    # The phrase regex works even if the DB load fails (button by name, no id).
    phrases = sorted(_CANONICAL_EXERCISES, key=len, reverse=True)
    alt = "|".join(re.escape(p) for p in phrases)
    _CANON_REGEX = re.compile(r"\b(" + alt + r")s?\b", re.IGNORECASE)
    try:
        from core.db import get_supabase_db

        db = get_supabase_db()
        rows = (
            db.client.table("exercise_library_cleaned").select("id,name").execute().data
            or []
        )
        resolve: List[tuple] = []
        for r in rows:
            nm = (r.get("name") or "").strip()
            if nm:
                resolve.append((nm.lower(), nm, str(r["id"]) if r.get("id") is not None else None))
        _EXERCISE_RESOLVE = resolve
        logger.info("[Inline Action] exercise resolve index loaded (%d rows)", len(resolve))
    except Exception as e:
        logger.warning("[Inline Action] exercise index load failed (ignored): %s", e)


def _match_exercise(text: str) -> Optional[Dict[str, Any]]:
    _ensure_exercise_index()
    if _CANON_REGEX is None:
        return None
    m = _CANON_REGEX.search(text or "")
    if not m:
        return None
    phrase = m.group(1).lower()
    rows = _EXERCISE_RESOLVE or []
    # Prefer an exact library name, else the first qualified name containing the
    # movement phrase (e.g. "romanian deadlift" -> "Barbell Romanian Deadlift").
    for nl, nm, idv in rows:
        if nl == phrase:
            return {"name": nm, "id": idv}
    # Among qualified names containing the movement, prefer the shortest (most
    # canonical, e.g. "Romanian Deadlift" over "Single Leg Romanian Deadlift").
    best = None
    for nl, nm, idv in rows:
        if phrase in nl and (best is None or len(nl) < len(best[0])):
            best = (nl, nm, idv)
    if best is not None:
        return {"name": best[1], "id": best[2]}
    # Recognised movement not in our library — still offer the button by name.
    return {"name": phrase.title(), "id": None}


def _find_workout_id(
    context: Optional[Dict[str, Any]], tool_results: Optional[List[Dict[str, Any]]]
) -> Optional[str]:
    """Best-effort workout id from the turn context (a recently generated/viewed
    workout). Returns None if none — the schedule button needs a target."""
    for key in ("workout_id", "last_workout_id", "current_workout_id", "active_workout_id"):
        v = (context or {}).get(key)
        if v:
            return str(v)
    for r in (tool_results or []):
        if isinstance(r, dict) and r.get("workout_id"):
            return str(r["workout_id"])
    return None


def _existing_recipe_from_context(
    tool_results: Optional[List[Dict[str, Any]]],
    context: Optional[Dict[str, Any]],
) -> Optional[Dict[str, Any]]:
    """Return a structured recipe dict ONLY if the agent already produced one.

    We never synthesize a recipe from free text — that would be a guess. We only
    surface a recipe object the nutrition tools/state already built (so it has
    real name/ingredients/etc).
    """
    # 1. A tool result may carry a recipe payload.
    if tool_results:
        for result in tool_results:
            if not isinstance(result, dict):
                continue
            recipe = result.get("recipe")
            if isinstance(recipe, dict) and recipe.get("name"):
                return recipe
            recipes = result.get("recipes")
            if isinstance(recipes, list) and recipes:
                first = recipes[0]
                if isinstance(first, dict) and first.get("name"):
                    return first
    # 2. State/context may carry a recipe the agent assembled.
    if context:
        recipe = context.get("recipe")
        if isinstance(recipe, dict) and recipe.get("name"):
            return recipe
        recipes = context.get("recipes")
        if isinstance(recipes, list) and recipes:
            first = recipes[0]
            if isinstance(first, dict) and first.get("name"):
                return first
    return None


def infer_inline_action(
    text: Optional[str],
    agent_type: Optional[str],
    context: Optional[Dict[str, Any]] = None,
) -> Optional[Dict[str, Any]]:
    """Infer a NEW inline action for a chat reply.

    Args:
        text: the final assistant reply text.
        agent_type: the AgentType value string (e.g. "hydration", "nutrition").
        context: optional dict — may carry `tool_results`, `recipe`/`recipes`.

    Returns:
        An `action_data` dict for the frontend, or None if nothing applies.
        NEVER raises — any failure returns None so the chat turn is unaffected.
    """
    try:
        context = context or {}
        tool_results = context.get("tool_results") or []
        agent = (agent_type or "").lower()
        body = (text or "")
        body_lower = body.lower()
        # Pad with spaces so single-token phrase checks (" pr ") match at edges.
        padded = f" {body_lower} "

        # 1. Hydration — agent is the hydration specialist, or strong water copy.
        if agent == "hydration" or _text_has_any(body_lower, _HYDRATION_PHRASES):
            logger.info("[Inline Action] Inferred log_hydration (agent=%s)", agent)
            return {"action": "log_hydration"}

        # 2. Log bodyweight — reply explicitly asks for the user's weight.
        if _text_has_any(body_lower, _LOG_WEIGHT_PHRASES):
            logger.info("[Inline Action] Inferred log_weight")
            return {"action": "log_weight"}

        # 3. Personal record (checked before generic progress).
        if _text_has_any(padded, _PR_PHRASES):
            logger.info("[Inline Action] Inferred reference_progress kind=pr")
            return {"action": "reference_progress", "kind": "pr"}

        # 4. Generic progress / improvement.
        if _text_has_any(body_lower, _PROGRESS_PHRASES):
            logger.info("[Inline Action] Inferred reference_progress kind=progress")
            return {"action": "reference_progress", "kind": "progress"}

        # 5. Recipe — ONLY if the nutrition agent already produced structured data.
        if agent == "nutrition":
            recipe = _existing_recipe_from_context(tool_results, context)
            if recipe is not None:
                logger.info(
                    "[Inline Action] Inferred reference_recipe (%s)",
                    recipe.get("name"),
                )
                return {"action": "reference_recipe", "recipe": recipe}

        # 5b. Schedule — explicit "schedule this workout" intent AND a workout
        #     id we can target (a recently generated/viewed workout).
        if _text_has_any(body_lower, _SCHEDULE_PHRASES):
            wid = _find_workout_id(context, tool_results)
            if wid:
                logger.info("[Inline Action] Inferred schedule_workout (%s)", wid)
                return {"action": "schedule_workout", "workout_id": wid}

        # 6. reference_exercise — only when the reply names a REAL library
        #    exercise (multi-word match against the cached library vocabulary,
        #    so no false positives). Emits name + id for the "How to do X" button.
        #    TWO extra guards so we never emit an irrelevant tutorial chip:
        #      (a) a FAILED tool turn (e.g. workout gen errored) produced no
        #          real how-to — the exercise name is incidental, so suppress.
        #      (b) the reply must carry an actual technique/instruction cue, not
        #          just a bare exercise-name mention ("nice chest press today!").
        failed_turn = (
            any(isinstance(r, dict) and r.get("success") is False for r in tool_results)
            and not any(isinstance(r, dict) and r.get("success") is True for r in tool_results)
        )
        if not failed_turn and _text_has_any(body_lower, _HOWTO_CUES):
            ex = _match_exercise(body)
            if ex is not None:
                logger.info("[Inline Action] Inferred reference_exercise (%s)", ex.get("name"))
                return {
                    "action": "reference_exercise",
                    "exercise_name": ex.get("name"),
                    "exercise_id": ex.get("id"),
                }

        return None
    except Exception as e:  # never break a chat turn
        logger.warning("[Inline Action] inference failed (ignored): %s", e)
        return None
