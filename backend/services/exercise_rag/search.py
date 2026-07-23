"""
Search query building for exercise RAG.

Includes support for custom user goals with AI-generated keywords.
Also includes helpers to merge results from the `exercise_library` and
`custom_exercise_library` ChromaDB collections.
"""

import re
from typing import Any, Dict, List, Optional

from core.logger import get_logger
from services.training_program_service import get_training_program_keywords_sync

logger = get_logger(__name__)


# ─────────────────────────────────────────────────────────────────────────────
# Equipment normalization for query building
#
# WHY THIS EXISTS: the ChromaDB search is a *vector similarity* search over an
# embedding of the query string. Every token in that string competes for the
# embedding's direction. The old code inlined the user's raw equipment list
# (`f"Equipment: {', '.join(equipment)}"`, no cap) — for a commercial-gym user
# that is 83-88 entries / ~900 characters against a ~12-word focus phrase, so
# the embedding pointed at "equipment nouns" instead of "the movement I asked
# for". Observed symptom (beginner, full gym, focus=lower): Assault Airbike
# Sprint, Air Swing Running, Balance Board Lateral Squat, Band Squat Row —
# every pick matched an EQUIPMENT token, not the movement.
#
# THE REAL INVENTORIES THIS MUST HANDLE (transcribed from the Flutter client;
# the tests pin literal copies so drift is caught):
#
#   1. `WorkoutEnvironment.commercialGym.defaultEquipment`
#      (mobile/flutter/lib/core/providers/environment_equipment_provider.dart
#      :137-228) — 83 entries and DELIBERATELY NO `full_gym` marker (see the
#      comment at :134). This is the common gym-profile shape and it does NOT
#      hit the full-gym collapse below; it goes through dedupe + rank + cap.
#   2. `GymEquipmentSheet` (screens/home/widgets/gym_equipment_sheet.dart
#      :212-218) STRIPS `full_gym` and writes back the 43 expanded category
#      items — again no marker.
#   3. `kCommercialGymEquipmentPreset` (onboarding,
#      screens/onboarding/pre_auth_quiz_screen_ext.dart:22-126) — 88 entries
#      and it DOES keep `full_gym`.
#   4. `get_default_equipment_for_environment()` (backend/api/v1/users/models.py
#      :10-20) — the literal one-element lists `['full_gym']` / `['home_gym']` /
#      `['bodyweight']`.
#
# Those lists are full of the same implement in several spellings — 'cable_machine'
# AND 'Cable Pulley Machine', 'ez_curl_bar' AND 'EZ Bar', 'lat_pulldown' AND
# 'Lat Pull Down Machine', 'stationary_bike' AND 'Stationary Exercise Bike',
# 'trx' AND 'suspension_trainer' AND 'Suspension Trainer' — plus one entry that
# is itself two implements ('tire, sledgehammer'). Case, underscores, plurals,
# a trailing/embedded "Machine", and multiword synonyms all have to collapse or
# the dedupe is theatre.
#
# WHEN COLLAPSING TO A CAPABILITY PHRASE IS LEGITIMATE: only when the downstream
# availability check is genuinely unconstrained, i.e. ONLY for the literal
# `full_gym` marker, which `filters.filter_by_equipment` short-circuits with an
# unconditional `return True` (filters.py:704-716 + :782-783). `home_gym` gets
# NO such short-circuit — filters.py:727-729 EXPANDS it to
# `HOME_EQUIPPED_EQUIPMENT` and then enforces every entry — so collapsing it to
# "Equipment: home gym" would drop signal the filter still strictly needs. We
# therefore mirror that same expansion here instead of collapsing, so the clause
# describes exactly the set the filter will enforce.
# ─────────────────────────────────────────────────────────────────────────────

# Generic nouns dropped ANYWHERE in the string when computing the canonical key,
# so "leg_press" == "Leg Press Machine" and "Hammer Strength Machines" ==
# "hammer strength". Never allowed to empty the key (bare "machine" survives).
_EQUIPMENT_NOISE_WORDS = {"machine", "machines", "equipment", "gear"}

# Multiword / synonym aliases, applied AFTER noise-word removal + singularization.
# Keys and values are both canonical-key space. Every entry here exists because
# both spellings appear in one of the four real inventories above (or in
# `filters.FULL_GYM_EQUIPMENT` / `filters.HOME_EQUIPPED_EQUIPMENT`, which is
# what `home_gym` expands to).
_EQUIPMENT_ALIASES = {
    # Bars
    "olympic barbell": "barbell",
    "ez bar": "ez curl bar",
    "ez curl bar": "ez curl bar",
    # Cable stations
    "cable pulley": "cable",
    "cable crossover": "cable",
    # Pulldown / row
    "lat pull down": "lat pulldown",
    "lat pulldown": "lat pulldown",
    "pulldown": "lat pulldown",
    "pull down": "lat pulldown",
    # Benches: for a retrieval nudge every flat/incline/decline/adjustable bench
    # and the bench-press station are the same concept. NOT the hyperextension
    # bench, which is a back-extension station and stays distinct.
    "bench press": "bench",
    "flat bench": "bench",
    "incline bench": "bench",
    "decline bench": "bench",
    "adjustable bench": "bench",
    # Racks: a power rack and a squat rack select for the same exercises.
    "power rack": "squat rack",
    "rack": "squat rack",
    # Plates
    "bumper plate": "weight plate",
    "plate": "weight plate",
    # Bands
    "loop resistance band": "resistance band",
    "band": "resistance band",
    # Suspension
    "suspension trainer": "trx",
    # Ab wheel
    "ab roller": "ab wheel",
    # Balls
    "exercise ball": "stability ball",
    "swiss ball": "stability ball",
    # Pull-up hardware
    "pullup bar": "pull up bar",
    "chin up bar": "pull up bar",
    "chinup bar": "pull up bar",
    "assisted pullup": "assisted pull up",
    "assisted pull up": "assisted pull up",
    # Cardio
    "stationary exercise bike": "stationary bike",
    "exercise bike": "stationary bike",
    "ski ergometer": "ski erg",
    "airbike": "air bike",
    "assault bike": "air bike",
    "rowing": "rower",
    # Machines whose two spellings differ by a qualifier
    "seated hip abductor": "hip abductor",
    "pec deck": "chest fly",
    "pec fly": "chest fly",
}

# The ONLY marker that may collapse the whole inventory to a capability phrase.
# Must stay in lockstep with the `has_full_gym` test in
# `filters.filter_by_equipment` (filters.py:705-707), which is what makes the
# collapse lossless: that function returns True unconditionally for these users.
# "commercial gym" / "gym membership" are deliberately NOT here — nothing
# short-circuits the filter for them, so collapsing them would lose signal.
_FULL_GYM_MARKERS = ("full gym",)

# Tokens the equipment FILTER expands rather than short-circuits. Mirrored here
# (see module header) so the clause describes the enforced set.
_HOME_GYM_MARKERS = ("home gym",)

# Relevance order used when capping a long inventory. These are canonical keys
# (post-alias), matched EXACTLY — no substring matching, which used to rank
# "samtola indian barbell" as a barbell and "box" as a plyo box. Anything not
# listed sorts after everything listed, then by original position, so an
# unknown implement can never displace a known primary one.
_EQUIPMENT_PRIORITY = (
    "barbell", "dumbbell", "cable", "bench", "squat rack", "kettlebell",
    "smith", "lat pulldown", "leg press", "pull up bar", "dip station",
    "trap bar", "ez curl bar", "weight plate", "resistance band",
    "landmine", "trx", "gymnastic ring",
    "leg curl", "leg extension", "chest press", "shoulder press",
    "chest fly", "seated row", "cable row", "hack squat", "calf raise",
    "hip abductor", "tricep extension", "assisted pull up",
    "hyperextension bench", "medicine ball", "slam ball", "stability ball",
    "ab wheel", "plyo box",
)
_EQUIPMENT_PRIORITY_RANK = {k: i for i, k in enumerate(_EQUIPMENT_PRIORITY)}

# Cap on how many equipment terms may enter the embedded query. Keeps the
# equipment clause comfortably shorter than the focus phrase (~12-20 words), so
# focus terms keep majority weight in the embedding.
MAX_EQUIPMENT_TERMS_IN_QUERY = 6


def split_equipment_entries(equipment: List[str]) -> List[str]:
    """
    Split inventory entries that pack several implements into one string.

    Real data does this: `WorkoutEnvironment.commercialGym.defaultEquipment`
    ships the single entry `'tire, sledgehammer'`. `filter_by_equipment` splits
    exercise-side equipment on the same `[,/]` separators, so the query side
    must too or 'tire, sledgehammer' dedupes as one bogus implement.
    """
    out: List[str] = []
    for raw in equipment or []:
        if raw is None:
            continue
        for part in re.split(r"[,/]", str(raw)):
            part = part.strip()
            if part:
                out.append(part)
    return out


def canonical_equipment_key(raw: str) -> str:
    """
    Collapse one equipment string to a canonical comparison key.

    Handles the case / snake_case / plural / embedded-"machine" / synonym
    duplication that inflates the real inventories:

        "leg_press"             -> "leg press"
        "Leg Press Machine"     -> "leg press"
        "smith_machine"         -> "smith"
        "Smith Machine"         -> "smith"
        "cable_machine"         -> "cable"
        "Cable Pulley Machine"  -> "cable"
        "ez_curl_bar" / "EZ Bar"-> "ez curl bar"
        "lat_pulldown" / "Lat Pull Down Machine" -> "lat pulldown"
        "stationary_bike" / "Stationary Exercise Bike" -> "stationary bike"
        "trx" / "suspension_trainer" / "Suspension Trainer" -> "trx"
        "Battle Ropes" / "battle_ropes" -> "battle rope"
        "Dumbbells"             -> "dumbbell"

    Returns "" for empty/garbage input (caller drops those).
    """
    t = (raw or "").replace("_", " ").replace("-", " ").lower()
    t = re.sub(r"[^a-z0-9 ]+", " ", t)
    t = re.sub(r"\s+", " ", t).strip()
    if not t:
        return ""

    words = t.split()
    # Drop generic nouns wherever they appear ("... Machine", "Machines ...")
    # but never empty the key — a bare "machine" entry stays "machine".
    stripped = [w for w in words if w not in _EQUIPMENT_NOISE_WORDS]
    if stripped:
        words = stripped
    # Naive singularization so "dumbbells"/"dumbbell" and "ropes"/"rope" match.
    words = [
        w[:-1] if (len(w) > 3 and w.endswith("s") and not w.endswith("ss")) else w
        for w in words
    ]
    key = " ".join(words)
    return _EQUIPMENT_ALIASES.get(key, key)


def dedupe_equipment(equipment: List[str]) -> List[str]:
    """
    Deduplicate an equipment inventory by canonical key, preserving order.

    Multi-implement entries are split first (see `split_equipment_entries`).
    The returned strings are display forms (underscores → spaces, collapsed
    whitespace) of the FIRST spelling seen for each canonical key.
    """
    seen: set = set()
    out: List[str] = []
    for raw in split_equipment_entries(equipment):
        key = canonical_equipment_key(raw)
        if not key or key in seen:
            continue
        seen.add(key)
        display = re.sub(r"\s+", " ", (raw or "").replace("_", " ")).strip()
        out.append(display)
    return out


def _equipment_relevance_rank(display: str) -> int:
    """Lower = more training-relevant. Unlisted items sort after listed ones."""
    return _EQUIPMENT_PRIORITY_RANK.get(
        canonical_equipment_key(display), len(_EQUIPMENT_PRIORITY)
    )


def _expand_home_gym_marker(equipment: List[str]) -> List[str]:
    """
    Replace a `home_gym` marker with the equipment set the FILTER enforces.

    `filters.filter_by_equipment` (filters.py:727-729) expands 'home_gym' to
    `HOME_EQUIPPED_EQUIPMENT` and then requires every retrieved candidate to
    match that set. Collapsing the marker to the phrase "home gym" in the query
    would leave the embedding blind to implements the filter still demands, so
    we perform the identical expansion and let dedupe/ranking summarize it.
    """
    from .filters import HOME_EQUIPPED_EQUIPMENT

    expanded: List[str] = []
    for raw in equipment:
        key = canonical_equipment_key(raw)
        if any(m in key for m in _HOME_GYM_MARKERS):
            expanded.extend(HOME_EQUIPPED_EQUIPMENT)
        else:
            expanded.append(raw)
    return expanded


def build_equipment_clause(
    equipment: List[str],
    max_terms: int = MAX_EQUIPMENT_TERMS_IN_QUERY,
) -> str:
    """
    Build the short equipment clause for the embedded search query.

    - A literal `full_gym` marker → the capability phrase "Equipment: full gym".
      Lossless: `filter_by_equipment` returns True unconditionally for those
      users (filters.py:782-783), so no availability signal exists to preserve.
    - A `home_gym` marker → expanded to the exact set the filter enforces, then
      summarized like any other inventory (NOT collapsed — the filter still
      checks every entry).
    - Otherwise → deduped inventory, capped at the `max_terms` highest-ranked
      training-relevant items.
    - Nothing parseable at all → "" (no clause). We do NOT claim "bodyweight":
      an entry list that is non-empty but unparseable means "unknown", and
      `filter_by_equipment` still treats such a user as EQUIPPED, so asserting
      bodyweight would be a fabricated capability.

    Truncation loses no correctness: availability is enforced downstream against
    candidate metadata by `filter_by_equipment`; this clause only nudges the
    embedding.
    """
    entries = split_equipment_entries(equipment)

    if any(
        any(m in canonical_equipment_key(e) for m in _FULL_GYM_MARKERS)
        for e in entries
    ):
        return "Equipment: full gym"

    deduped = dedupe_equipment(_expand_home_gym_marker(entries))
    if not deduped:
        if entries:
            logger.warning(
                "[RAG Query] equipment list had %d entries but none were "
                "parseable (%r) — emitting NO equipment clause rather than "
                "asserting a capability the user never declared",
                len(entries), entries[:10],
            )
        return ""

    if len(deduped) > max_terms:
        ordered = sorted(
            enumerate(deduped),
            key=lambda pair: (_equipment_relevance_rank(pair[1]), pair[0]),
        )
        chosen_indices = sorted(idx for idx, _ in ordered[:max_terms])
        deduped = [deduped[i] for i in chosen_indices]

    return f"Equipment: {', '.join(deduped)}"


def is_bodyweight_only_equipment(equipment: List[str]) -> bool:
    """True when the inventory declares no equipment at all."""
    from .filters import BODYWEIGHT_TOKENS

    eq_norm = [(e or "").strip().lower() for e in (equipment or [])]
    return (not eq_norm) or all(e in BODYWEIGHT_TOKENS for e in eq_norm)


def equipment_query_clause(equipment: List[str]) -> str:
    """
    The exact equipment clause `build_search_query` embeds, for a given list.

    Single source of truth so observability (service.py) reports the real
    substring of the real query instead of recomputing a different one.
    Returns "" when there is no honest clause to emit.
    """
    if is_bodyweight_only_equipment(equipment):
        return "Equipment: bodyweight"
    return build_equipment_clause(equipment)


def merge_library_and_custom_results(
    library_results: Dict[str, Any],
    custom_results: Dict[str, Any],
    top_n: int,
) -> Dict[str, Any]:
    """
    Merge ChromaDB query results from `exercise_library` and `custom_exercise_library`.

    Results are combined and re-sorted by distance ascending (lower = more similar),
    then truncated to `top_n`. Preserves the ChromaDB result shape:
      { "ids": [[...]], "metadatas": [[...]], "distances": [[...]], "documents": [[...]] }

    Args:
        library_results: Result dict from `collection.query(...)` on exercise_library.
        custom_results:  Result dict from `custom_collection.query(...)` filtered by user.
        top_n:           Max number of merged results to return.

    Returns:
        Merged ChromaDB-shaped result dict.
    """
    def _safe_first(result: Dict[str, Any], key: str) -> List[Any]:
        v = result.get(key) if result else None
        if not v:
            return []
        if isinstance(v, list) and v and isinstance(v[0], list):
            return v[0]
        return v

    lib_ids = _safe_first(library_results, "ids")
    lib_meta = _safe_first(library_results, "metadatas")
    lib_dist = _safe_first(library_results, "distances")
    lib_docs = _safe_first(library_results, "documents")

    cust_ids = _safe_first(custom_results, "ids")
    cust_meta = _safe_first(custom_results, "metadatas")
    cust_dist = _safe_first(custom_results, "distances")
    cust_docs = _safe_first(custom_results, "documents")

    combined: List[Dict[str, Any]] = []
    for i, _id in enumerate(lib_ids):
        combined.append({
            "id": _id,
            "meta": lib_meta[i] if i < len(lib_meta) else {},
            "distance": lib_dist[i] if i < len(lib_dist) else 2.0,
            "document": lib_docs[i] if i < len(lib_docs) else "",
        })
    for i, _id in enumerate(cust_ids):
        m = cust_meta[i] if i < len(cust_meta) else {}
        # Ensure is_custom flag is present on custom-collection items even if the
        # metadata was partially populated.
        if "is_custom" not in m:
            m = {**m, "is_custom": "true"}
        combined.append({
            "id": _id,
            "meta": m,
            "distance": cust_dist[i] if i < len(cust_dist) else 2.0,
            "document": cust_docs[i] if i < len(cust_docs) else "",
        })

    # Lower distance = closer match. Sort ascending.
    combined.sort(key=lambda x: x["distance"])
    combined = combined[:top_n]

    return {
        "ids": [[c["id"] for c in combined]],
        "metadatas": [[c["meta"] for c in combined]],
        "distances": [[c["distance"] for c in combined]],
        "documents": [[c["document"] for c in combined]],
    }


# Focus area keywords for semantic search
FOCUS_AREA_KEYWORDS = {
    # Full body variations
    "full_body_push": "full body workout emphasis on push movements chest shoulders triceps pressing",
    "full_body_pull": "full body workout emphasis on pull movements back biceps rowing pulling",
    "full_body_legs": "full body workout emphasis on legs lower body squats lunges glutes hamstrings",
    "full_body_core": "full body workout emphasis on core abs stability planks",
    "full_body_upper": "full body workout upper body focus chest back shoulders arms",
    "full_body_lower": "full body workout lower body focus legs glutes quads hamstrings calves",
    "full_body_power": "full body workout power explosive movements plyometrics jumps",
    "full_body": "full body balanced workout compound movement patterns squat hinge push pull carry lunge total body strength training",

    # Upper/Lower split focus areas
    "upper": "upper body workout chest back shoulders arms biceps triceps pressing pulling rows",
    "lower": "lower body workout legs glutes quadriceps hamstrings calves squats lunges deadlifts",

    # Push/Pull/Legs (PPL) split focus areas
    "push": "push workout chest shoulders triceps bench press overhead press dips pushing movements",
    "pull": "pull workout back biceps rows pull-ups chin-ups lat pulldown pulling movements",
    "legs": "legs workout quadriceps hamstrings glutes calves squats lunges leg press deadlifts",

    # PHUL (Power Hypertrophy Upper Lower) focus areas
    "upper_power": "upper body power heavy compound movements bench press barbell rows overhead press weighted dips strength",
    "lower_power": "lower body power heavy compound movements squats deadlifts power cleans leg press strength",
    "upper_hypertrophy": "upper body hypertrophy higher reps muscle building chest back shoulders arms isolation exercises",
    "lower_hypertrophy": "lower body hypertrophy higher reps muscle building legs glutes quad hamstring isolation exercises",

    # Arnold Split focus areas
    "chest_back": "chest and back workout antagonist pairing bench press rows flyes pulldowns compound movements",
    "shoulders_arms": "shoulders and arms workout deltoids biceps triceps overhead press curls extensions",

    # Bro Split / Body Part focus areas
    "chest": "chest workout pectorals bench press incline decline flyes dips pressing movements",
    "back": "back workout lats rhomboids traps rows pulldowns pull-ups deadlifts pulling movements",
    "shoulders": "shoulders workout deltoids front side rear overhead press lateral raises face pulls",
    "arms": "arms workout biceps triceps curls extensions dips chin-ups isolation movements",
    "core_cardio": "core and cardio workout abs obliques planks crunches conditioning metabolic",

    # HYROX focus areas
    "hyrox_strength": "hyrox strength training sled push sled pull farmers carry sandbag exercises functional strength",
    "hyrox_running": "hyrox running intervals zone 2 compromised running aerobic base building endurance",
    "hyrox_stations": "hyrox stations ski erg rowing wall balls burpee broad jumps functional fitness conditioning",
    "hyrox_endurance": "hyrox endurance long aerobic work functional conditioning sustained effort stamina",
    "hyrox_simulation": "hyrox race simulation run station transitions competition preparation race pace",

    # Sport-specific workout types
    "boxing": "boxing workout punching power jab cross hook uppercut footwork conditioning cardio core rotation speed agility combat",
    "hyrox": "hyrox workout functional fitness running lunges burpees rowing sled push farmer carry wall balls ski erg endurance strength hybrid competition",
    "crossfit": "crossfit wod functional movements olympic lifts thrusters pull-ups box jumps kettlebell swings burpees muscle-ups high intensity amrap emom",
    "martial_arts": "martial arts mma grappling striking takedowns conditioning explosive power kicks punches combat training",
    "hiit": "hiit high intensity interval training cardio burpees jumping jacks mountain climbers explosive movements metabolic conditioning",
    "strength": "strength training heavy compound exercises squat deadlift bench press overhead press powerlifting maximal strength",
    "endurance": "endurance stamina cardio running cycling sustained effort aerobic conditioning long duration",
    "flexibility": "flexibility stretching yoga mobility range of motion static stretches dynamic stretches",
    "mobility": "mobility joint health functional movement dynamic stretching foam rolling warm-up activation",

    # Power and Plyometric training
    "plyometrics": "plyometric exercises explosive power jump training box jumps squat jumps depth jumps bounding hops reactive strength power development",
    "power": "explosive power training Olympic lifts power cleans snatches jump squats medicine ball throws plyometrics speed strength rate of force development",
    "vertical_jump": "vertical jump training box jumps depth jumps squat jumps countermovement jumps plyometrics leg power explosive strength calf raises",
    "speed": "speed training sprints acceleration agility drills quick feet ladder drills explosive movements fast twitch muscle development",
    "explosiveness": "explosive movement training power plyometrics jumps medicine ball throws olympic lifts rapid force production athletic performance",

    # Ball sports
    "cricket": "cricket training rotational power batting bowling throwing shoulder stability agility sprints lateral movement core strength explosive power conditioning",
    "football": "football soccer training sprinting agility change direction lower body power endurance conditioning kicks",
    "basketball": "basketball training vertical jump explosive power lateral movement agility conditioning court sprints",
    "tennis": "tennis training lateral movement agility rotational power shoulder stability core conditioning footwork",
}

# Goal keywords for semantic search
GOAL_KEYWORDS = {
    "Build Muscle": "hypertrophy muscle building compound exercises",
    "Lose Weight": "fat burning high intensity metabolic exercises",
    "Increase Strength": "strength power heavy compound exercises",
    "Improve Endurance": "cardio endurance stamina exercises",
    "Flexibility": "stretching mobility flexibility exercises",
    "General Fitness": "functional fitness full body exercises",
}

# Custom program description keyword mappings
# Maps keywords in custom descriptions to focus areas for better RAG matching
CUSTOM_PROGRAM_KEYWORDS = {
    # Jump/Plyometric related
    "box jump": "plyometrics vertical_jump",
    "jump": "plyometrics vertical_jump power",
    "vertical jump": "vertical_jump plyometrics",
    "plyometric": "plyometrics power explosiveness",
    "explosive": "explosiveness power plyometrics",
    "power": "power explosiveness strength",

    # Sport-specific
    "hyrox": "hyrox",
    "marathon": "endurance",
    "running": "endurance speed",
    "sprint": "speed power explosiveness",
    "basketball": "basketball vertical_jump",
    "football": "football speed power",
    "soccer": "football endurance speed",
    "boxing": "boxing",
    "mma": "martial_arts",
    "tennis": "tennis",
    "cricket": "cricket",
    "crossfit": "crossfit",

    # Skill-specific
    "pull-up": "full_body_pull strength",
    "pullup": "full_body_pull strength",
    "pushup": "full_body_push strength",
    "push-up": "full_body_push strength",
    "deadlift": "strength full_body_pull",
    "squat": "strength full_body_legs",
    "bench": "strength full_body_push",

    # General
    "strength": "strength",
    "muscle": "strength",
    "endurance": "endurance",
    "speed": "speed",
    "agility": "speed",
    "flexibility": "flexibility mobility",
    "mobility": "mobility flexibility",
}


def extract_focus_areas_from_description(description: str) -> List[str]:
    """
    Extract relevant focus areas from a custom program description.

    Args:
        description: Custom program description like "Improve box jump height"

    Returns:
        List of focus area keywords to enhance RAG search
    """
    if not description:
        return []

    description_lower = description.lower()
    found_focuses = set()

    # Check for keyword matches (longer phrases first)
    sorted_keywords = sorted(CUSTOM_PROGRAM_KEYWORDS.keys(), key=len, reverse=True)

    for keyword in sorted_keywords:
        if keyword in description_lower:
            focus_areas = CUSTOM_PROGRAM_KEYWORDS[keyword].split()
            for focus in focus_areas:
                if focus in FOCUS_AREA_KEYWORDS:
                    found_focuses.add(focus)

    return list(found_focuses)


def build_search_query(
    focus_area: str,
    equipment: List[str],
    fitness_level: str,
    goals: List[str],
) -> str:
    """
    Build a semantic search query for exercises.

    Args:
        focus_area: Target body area or workout type
        equipment: Available equipment
        fitness_level: User's fitness level
        goals: User's fitness goals

    Returns:
        Semantic search query string
    """
    focus_query = FOCUS_AREA_KEYWORDS.get(focus_area, f"Exercises for {focus_area} workout")

    # ONE source of truth for the clause — `equipment_query_clause` is what
    # service.py logs, so the observability line always quotes the real
    # substring of the real query.
    equipment_clause = equipment_query_clause(equipment)

    if is_bodyweight_only_equipment(equipment):
        bw_emphasis = (
            "bodyweight calisthenics push-ups pull-ups squats lunges planks "
            "burpees mountain climbers glute bridges no equipment"
        )
        query_parts = [
            bw_emphasis,
            focus_query,
            equipment_clause,
            f"Fitness level: {fitness_level}",
        ]
    else:
        # Equipment is a FILTER, not a semantic signal — see the module header.
        # A capped, deduped capability summary keeps the focus terms dominant in
        # the embedding; the user's full inventory is still applied verbatim by
        # `filter_by_equipment` on the retrieved candidates. `equipment_clause`
        # may legitimately be "" (unparseable inventory) — dropped below rather
        # than replaced with a fabricated capability.
        query_parts = [
            focus_query,
            equipment_clause,
            f"Fitness level: {fitness_level}",
        ]

    # Add goal-specific terms
    training_program_keywords = get_training_program_keywords_sync()

    for goal in goals:
        if goal in GOAL_KEYWORDS:
            query_parts.append(GOAL_KEYWORDS[goal])
        # Check if goal matches a training program
        if goal in training_program_keywords:
            query_parts.append(training_program_keywords[goal])

    return " ".join(p for p in query_parts if p)


async def build_search_query_with_custom_goals(
    focus_area: str,
    equipment: List[str],
    fitness_level: str,
    goals: List[str],
    user_id: Optional[str] = None,
) -> str:
    """
    Build a semantic search query incorporating user's custom goals.

    This extends build_search_query to include:
    1. User's custom goal keywords from custom_goals table
    2. User's custom_program_description from preferences

    Args:
        focus_area: Target body area or workout type
        equipment: Available equipment
        fitness_level: User's fitness level
        goals: User's fitness goals
        user_id: User ID for fetching custom goal keywords (optional)

    Returns:
        Enhanced semantic search query with custom goal keywords
    """
    # Start with the base query
    base_query = build_search_query(focus_area, equipment, fitness_level, goals)

    # If no user_id, just return base query
    if not user_id:
        return base_query

    enhanced_parts = [base_query]

    # Get custom program description from user preferences
    try:
        from core.supabase_db import get_supabase_db
        db = get_supabase_db()
        user = db.get_user(user_id)
        if user:
            preferences = user.get("preferences", {})
            if isinstance(preferences, str):
                import json
                try:
                    preferences = json.loads(preferences)
                except json.JSONDecodeError:
                    preferences = {}

            custom_program_description = preferences.get("custom_program_description")
            if custom_program_description and custom_program_description.strip():
                # Extract relevant focus areas from the description
                extracted_focuses = extract_focus_areas_from_description(custom_program_description)

                if extracted_focuses:
                    # Add the focus area keywords to strongly influence RAG results
                    for focus in extracted_focuses:
                        if focus in FOCUS_AREA_KEYWORDS:
                            enhanced_parts.append(FOCUS_AREA_KEYWORDS[focus])
                    logger.info(f"Extracted focus areas from custom program: {extracted_focuses}")

                # Also add the raw description for semantic matching
                enhanced_parts.append(f"Custom training goal: {custom_program_description}")
                logger.debug(f"Added custom program description to query for user {user_id}")

    except Exception as e:
        logger.warning(f"Failed to get custom program description for user {user_id}: {e}", exc_info=True)

    # Get custom goal keywords (no Gemini call - reads from DB cache)
    try:
        from services.custom_goal_service import get_custom_goal_service
        custom_goal_service = get_custom_goal_service()
        custom_keywords = await custom_goal_service.get_combined_keywords(user_id)

        if custom_keywords:
            # Take top 10 keywords (weighted by priority, already sorted)
            top_keywords = custom_keywords[:10]
            enhanced_parts.append(f"Custom focus: {' '.join(top_keywords)}")
            logger.debug(f"Enhanced query with {len(top_keywords)} custom keywords for user {user_id}")

    except Exception as e:
        logger.warning(f"Failed to get custom goal keywords for user {user_id}: {e}", exc_info=True)

    final_query = " ".join(enhanced_parts)

    # Log the final RAG search query for debugging custom programs
    logger.info("=" * 60)
    logger.info(f"[RAG SEARCH QUERY] User: {user_id}")
    logger.info(f"Base focus area: {focus_area}")
    logger.info(f"FINAL QUERY: {final_query}")
    logger.info("=" * 60)

    return final_query
