"""
Library utility functions.

This module contains helper functions for the library API:
- Database pagination
- Body part normalization
- Row conversion functions
- Goal/suitability derivation
- S3 presigned URL generation
- Static (permanent) URL generation for public assets
"""
import re
from typing import List, Dict, Any, Optional
from urllib.parse import quote

from core.supabase_db import get_supabase_db
from .models import LibraryExercise, LibraryProgram


_presign_error_logged = False  # Log first error only to avoid log spam

# Ordered list of (compiled_regex, simplified_base_name, canonical_exercise_names).
# First matching pattern wins — put MORE SPECIFIC patterns before generic ones.
#
# `canonical_exercise_names` is an ordered tuple of exact exercise names (matched
# case-insensitively against exercise_library_cleaned.name) that should pin to the
# top of tier-1 when a user searches the simplified base. Index in the tuple sets
# rank — first entry = #1 result. Names that don't exist in the DB silently fall
# through to the non-canonical tier-1 branch, so an outdated entry causes no error.
# An empty tuple keeps today's word-count/length/alphabetical tiebreaker.
# Regex nouns use `s?` / `(?:es)?` / `(?:ies)?` to match both singular and plural
# exercise names because the DB mixes conventions ("Dumbbell Curls", "Barbell Shrugs",
# "Bodyweight Squats", "Good Mornings", "Mountain Climbers", "Sit-Ups", "Push Ups",
# "Crunches", "Dips", "Flies"). Without plural coverage, simplified-match misses
# these rows and they fall to a lower tier than intended.
_SIMPLIFIED_PATTERNS: list[tuple[re.Pattern, str, tuple[str, ...]]] = [
    # ── Planks — specific before generic ──────────────────
    (re.compile(r'\bside\s+planks?\b'),                        "Side Plank",       ("Side Plank",)),
    (re.compile(r'\breverse\s+planks?\b'),                     "Reverse Plank",    ()),
    (re.compile(r'\bplanks?\b'),                               "Plank",            ("Plank On Elbows", "High Plank")),
    # ── Core / abs ────────────────────────────────────────
    (re.compile(r'\brussian\s+twists?\b'),                     "Russian Twist",    ("Russian Twist",)),
    (re.compile(r'\bmountain\s+climbers?\b'),                  "Mountain Climber", ("Mountain Climber", "Mountain Climbers")),
    (re.compile(r'\bleg\s+raises?\b'),                         "Leg Raise",        ("Hanging Leg Raises", "Captains Chair Leg Raise")),
    (re.compile(r'\bcrunch(?:es)?\b'),                         "Crunch",           ("Reverse Crunch", "Cable Crunch", "Oblique Crunch")),
    (re.compile(r'\bsit[\s\-]?ups?\b|\bsitups?\b'),            "Sit Up",           ("Decline Sit Up", "Sit-Ups", "Situps")),
    # ── Upper body push (specific before generic) ─────────
    (re.compile(r'\bpush\s+press\b'),                          "Push Press",       ("Dumbbell Push Press",)),
    (re.compile(r'\boverhead\s+press\b|\bshoulder\s+press\b|\bmilitary\s+press\b'),
                                                               "Overhead Press",   ("Barbell Standing Shoulder Press", "Dumbbell Standing Overhead Press",
                                                                                    "Dumbbell Seated Shoulder Press", "Barbell Seated Overhead Press")),
    (re.compile(r'\btriceps?\s+extensions?\b'),                "Tricep Extension", ("Tricep Extension Machine", "Dumbbell Lying Triceps Extension",
                                                                                    "Barbell Lying Triceps Extension")),
    (re.compile(r'\bbench\s+press\b'),                         "Bench Press",      ("Barbell Bench Press", "Dumbbell Bench Press",
                                                                                    "Barbell Incline Bench Press", "Dumbbell Incline Bench Press",
                                                                                    "Close Grip Barbell Bench Press")),
    (re.compile(r'\bleg\s+press\b'),                           "Leg Press",        ()),
    (re.compile(r'\bpush[\s\-]?ups?\b|\bpushups?\b'),          "Push Up",          ("Normal Push-Up", "Decline Push Up", "Diamond Push Up",
                                                                                    "Incline Push-Up (On Box)")),
    (re.compile(r'\bdips?\b'),                                 "Dip",              ("Chest Dip", "Assisted Dip")),
    # Flies/flyes/flys: match both spellings and plurals of each.
    (re.compile(r'\bfly\b|\bflies\b|\bflyes?\b|\bflys\b'),     "Fly",              ("Machine Fly", "Pec Deck Fly", "Dumbbell Reverse Fly",
                                                                                    "Cable Rear Delt Fly")),
    # ── Upper body pull (specific before generic) ─────────
    (re.compile(r'\bface\s+pulls?\b'),                         "Face Pull",        ("Cable Face Pull", "Band Face Pull")),
    (re.compile(r'\bmuscle[\s\-]?ups?\b'),                     "Muscle Up",        ()),
    (re.compile(r'\bpull[\s\-]?ups?\b|\bpullups?\b'),          "Pull Up",          ("Pull Up Normal Grip", "Pull Up Wide Grip", "Assisted Pull Up")),
    (re.compile(r'\bchin[\s\-]?ups?\b|\bchinups?\b'),          "Chin Up",          ("Chin Up",)),
    (re.compile(r'\bpulldowns?\b|\blat\s+pulldowns?\b'),       "Pulldown",         ("Lat Pulldown", "Wide Grip Lat Pulldown",
                                                                                    "Close Grip Lat Pulldown", "Cable Straight Arm Pulldown")),
    (re.compile(r'\bshrugs?\b'),                               "Shrug",            ("Barbell Shrugs", "Dumbbell Shrugs", "Kettlebell Shrug",
                                                                                    "Trap Bar Shrug")),
    (re.compile(r'\bupright\s+rows?\b'),                       "Upright Row",      ("Upright Row Barbell", "Upright Row Dumbbell")),
    (re.compile(r'\brows?\b'),                                 "Row",              ("Bent Over Barbell Row", "Dumbbell Bent-Over Row",
                                                                                    "Kettlebell Row", "Cable Bent Over Row", "Landmine Row")),
    # ── Shoulder isolation (specific before generic raise) ─
    (re.compile(r'\blateral\s+raises?\b|\bside\s+raises?\b'),  "Lateral Raise",    ("Machine Lateral Raise", "Lateral Raises Dumbbell",
                                                                                    "Dumbbell One Arm Lateral Raise", "Lateral Raise Bodyweight")),
    (re.compile(r'\bfront\s+raises?\b'),                       "Front Raise",      ("Dumbbell Front Raise", "Barbell Front Raise", "Plate Front Raise")),
    (re.compile(r'\brear\s+(?:delt|lateral)\s+raises?\b'),     "Rear Delt Raise",  ("Dumbbell Rear Lateral Raise",)),
    (re.compile(r'\bcalf\s+raises?\b'),                        "Calf Raise",       ("Dumbbell Standing Calf Raise", "Bodyweight Standing Calf Raise",
                                                                                    "Donkey Calf Raise", "Dumbbell Seated Calf Raise")),
    # ── Curls — specific before generic ───────────────────
    (re.compile(r'\bwrist\s+curls?\b'),                        "Wrist Curl",       ("Wrist Curl Barbell", "Wrist Curl Dumbbell")),
    (re.compile(r'\bhammer\s+curls?\b'),                       "Hammer Curl",      ("Dumbbell Hammer Curl",)),
    (re.compile(r'\bpreacher\s+curls?\b'),                     "Preacher Curl",    ("Barbell Preacher Curl", "Dumbbell Preacher Curl")),
    (re.compile(r'\bleg\s+curls?\b'),                          "Leg Curl",         ("Seated Leg Curl", "Lying Leg Curl")),
    (re.compile(r'\bcurls?\b'),                                "Curl",             ("Barbell Curl", "Dumbbell Curls", "Barbell Biceps Curl",
                                                                                    "Incline Dumbbell Curl")),
    # ── Lower-body compound (specific before generic) ─────
    (re.compile(r'\bbulgarian\s+split\s+squats?\b'),           "Bulgarian Split Squat",
                                                               ("Bulgarian Split Squat", "Barbell Bulgarian Split Squat",
                                                                "Dumbbell Bulgarian Split Squat")),
    (re.compile(r'\bgoblet\s+squats?\b'),                      "Goblet Squat",     ("Dumbbell Goblet Squat", "Cable Goblet Squat")),
    (re.compile(r'\bfront\s+squats?\b'),                       "Front Squat",      ("Barbell Front Squat", "Dumbbell Front Squat")),
    (re.compile(r'\bhack\s+squats?\b'),                        "Hack Squat",       ("Hack Squat", "Hack Squat Machine", "Reverse Hack Squat")),
    (re.compile(r'\bsquats?\b'),                               "Squat",            ("Bodyweight Squat", "Barbell Low Bar Squat", "Barbell Full Squat",
                                                                                    "Dumbbell Goblet Squat")),
    (re.compile(r'\bromanian\s+deadlifts?\b|\brdls?\b'),       "Romanian Deadlift",
                                                               ("Barbell Romanian Deadlift", "Dumbbell Romanian Deadlift")),
    (re.compile(r'\bsumo\s+deadlifts?\b'),                     "Sumo Deadlift",    ("Barbell Sumo Deadlift", "Kettlebell Sumo Deadlift")),
    (re.compile(r'\btrap\s+bar\s+deadlifts?\b|\bhex\s+bar\s+deadlifts?\b'),
                                                               "Trap Bar Deadlift", ("Trap Bar Deadlift",)),
    (re.compile(r'\bdeadlifts?\b'),                            "Deadlift",         ("Barbell Deadlift", "Barbell Romanian Deadlift",
                                                                                    "Barbell Sumo Deadlift", "Trap Bar Deadlift",
                                                                                    "Dumbbell Romanian Deadlift")),
    (re.compile(r'\bleg\s+extensions?\b'),                     "Leg Extension",    ("Leg Extension",)),
    (re.compile(r'\blunges?\b'),                               "Lunge",            ("Barbell Lunge", "Bodyweight Forward Lunge",
                                                                                    "Dumbbell Rear Lunge", "Lateral Lunge")),
    (re.compile(r'\bhip\s+thrusts?\b'),                        "Hip Thrust",       ("Barbell Hip Thrust", "Dumbbell Hip Thrust", "Bodyweight Hip Thrust")),
    (re.compile(r'\bglute\s+bridges?\b'),                      "Glute Bridge",     ("Barbell Glute Bridge", "Dumbbell Glute Bridge", "Kettlebell Glute Bridge")),
    (re.compile(r'\bgood\s+mornings?\b'),                      "Good Morning",     ("Barbell Good Morning", "Good Mornings", "Bodyweight Good Morning")),
    (re.compile(r'\bkettlebell\s+swings?\b'),                  "Kettlebell Swing", ("Kettlebell Swing",)),
    # ── Cardio ────────────────────────────────────────────
    (re.compile(r'\btreadmill\b'),                             "Treadmill",        ("Treadmill Run", "Treadmill Walk", "Treadmill Jog")),
    (re.compile(r'\bstationary\s+bike\b|\bspin\s+bike\b|\bexercise\s+bike\b'),
                                                               "Stationary Bike",  ("Stationary Bike Moderate", "Stationary Bike Easy")),
    (re.compile(r'\bcycling\b|\bcycle\b'),                     "Cycling",          ()),
    (re.compile(r'\browing\s+machine\b|\bgym\s+row'),          "Rowing Machine",   ("Rowing Machine Moderate", "Rowing Machine Easy")),
    (re.compile(r'\belliptical\b'),                            "Elliptical",       ("Elliptical Moderate", "Elliptical Easy")),
    (re.compile(r'\bjump\s+rope\b|\bjumping\s+rope\b'),        "Jump Rope",        ("Jump Rope Basic Jump", "Jump Rope Alternating Foot")),
    (re.compile(r'\bstair\s+(?:climb|step|mill)'),             "Stair Climber",    ("Stair Climber Moderate", "Stair Climber Easy")),
    (re.compile(r'\bski\s+erg(?:ometer)?\b'),                  "Ski Erg",          ("Ski Erg Easy", "Ski Erg Intervals")),
    (re.compile(r'\bburpees?\b'),                              "Burpee",           ("Burpee",)),
    (re.compile(r'\bjumping\s+jacks?\b'),                      "Jumping Jack",     ("Jumping Jack",)),
    (re.compile(r'\bhigh\s+knees?\b'),                         "High Knees",       ("High Knees",)),
    (re.compile(r'\bbox\s+jumps?\b'),                          "Box Jump",         ("Box Jump",)),
    (re.compile(r'\bsprints?\b'),                              "Sprint",           ("Treadmill Sprint Intervals",)),
]

# Pre-compute lowercased canonical tuples so the hot-path doesn't lowercase per-call.
_SIMPLIFIED_PATTERNS_LC: list[tuple[re.Pattern, str, tuple[str, ...]]] = [
    (p, s, tuple(c.lower() for c in canon)) for p, s, canon in _SIMPLIFIED_PATTERNS
]


def _get_simplified_and_canonicals(name_lower: str) -> tuple[Optional[str], tuple[str, ...]]:
    """Return (simplified_base_name, lowercased_canonical_names) for an exercise name.

    First matching pattern wins — order of _SIMPLIFIED_PATTERNS matters.
    Returns (None, ()) if no pattern matches."""
    for pattern, simplified, canon_lc in _SIMPLIFIED_PATTERNS_LC:
        if pattern.search(name_lower):
            return simplified, canon_lc
    return None, ()


def _get_exercise_simplified_name(name_lower: str) -> Optional[str]:
    """Back-compat shim: return only the simplified name.

    Kept so external callers (none at present, but defensive) keep working."""
    simplified, _ = _get_simplified_and_canonicals(name_lower)
    return simplified

# S3 prefixes that are publicly readable (no presigning needed).
# Keep in sync with backend/scripts/setup_s3_public_assets.py — the bucket
# policy there is what actually grants anonymous s3:GetObject on these.
_STATIC_PREFIXES = ("ILLUSTRATIONS ALL/", "Ultimate-Muscle-Visuals/")


def presign_s3_path(s3_path: Optional[str]) -> Optional[str]:
    """Convert an S3 path (s3://bucket/key) to a presigned HTTPS URL.

    Returns the original value if not an S3 path (None, empty, or already HTTP).
    Returns None on presigning failure.

    Note: generate_presigned_url is a local HMAC computation (no network call),
    so calling this per-exercise (~2000 calls) adds <50ms total.
    """
    global _presign_error_logged
    if not s3_path or not s3_path.startswith('s3://'):
        return s3_path
    try:
        from api.v1.videos import s3_client, PRESIGNED_URL_EXPIRATION
        path_without_prefix = s3_path[5:]  # Remove 's3://'
        slash_idx = path_without_prefix.index('/')
        bucket = path_without_prefix[:slash_idx]
        key = path_without_prefix[slash_idx + 1:]
        return s3_client.generate_presigned_url(
            'get_object',
            Params={'Bucket': bucket, 'Key': key},
            ExpiresIn=PRESIGNED_URL_EXPIRATION,
        )
    except Exception as e:
        if not _presign_error_logged:
            from core.logger import get_logger
            get_logger(__name__).warning(f"presign_s3_path failed (further errors suppressed): {e}", exc_info=True)
            _presign_error_logged = True
        return None


def static_url(s3_path: Optional[str]) -> Optional[str]:
    """Return a permanent (non-expiring) URL for a public static asset.

    If STATIC_CDN_BASE_URL is set, returns a CloudFront URL.
    Otherwise returns a direct S3 URL (bucket must have public-read policy).

    Returns None if the path is not under a static prefix.
    """
    if not s3_path or not s3_path.startswith('s3://'):
        return None

    path_without_prefix = s3_path[5:]  # Remove 's3://'
    slash_idx = path_without_prefix.index('/')
    bucket = path_without_prefix[:slash_idx]
    key = path_without_prefix[slash_idx + 1:]

    # Only static prefixes get permanent URLs
    if not any(key.startswith(prefix) for prefix in _STATIC_PREFIXES):
        return None

    from core.config import get_settings
    settings = get_settings()

    if settings.static_cdn_base_url:
        cdn_base = settings.static_cdn_base_url.rstrip('/')
        return f"{cdn_base}/{quote(key, safe='/')}"

    region = settings.aws_default_region
    return f"https://{bucket}.s3.{region}.amazonaws.com/{quote(key, safe='/')}"


def resolve_image_url(s3_path: Optional[str]) -> Optional[str]:
    """Convert an S3 path to the best available URL.

    Tries static_url() first (permanent, cacheable forever).
    Falls back to presign_s3_path() for private content.
    """
    url = static_url(s3_path)
    if url:
        return url
    return presign_s3_path(s3_path)


async def fetch_all_rows(
    db,
    table_name: str,
    select_columns: str = "*",
    order_by: str = None,
    equipment_filter: str = None,
    difficulty_filter: int = None,
    search_filter: str = None,
    use_fuzzy_search: bool = True
) -> List[Dict[str, Any]]:
    """
    Fetch all rows from a Supabase table, handling the 1000 row limit.
    Uses pagination to get all results.
    Optionally applies DB-level filters before fetching.

    Args:
        use_fuzzy_search: If True and search_filter is provided, uses fuzzy search
                         via pg_trgm for typo tolerance (e.g., "benchpress" -> "Bench Press")
    """
    # If fuzzy search is enabled and we have a search filter, use RPC function
    if search_filter and use_fuzzy_search:
        return await fetch_fuzzy_search_results(
            db, search_filter,
            equipment_filter=equipment_filter,
            limit=2000  # Return up to 2000 fuzzy results
        )

    all_rows = []
    page_size = 1000
    offset = 0

    while True:
        query = db.client.table(table_name).select(select_columns)

        # Apply optional DB-level filters
        if equipment_filter:
            query = query.ilike("equipment", f"%{equipment_filter}%")
        if difficulty_filter:
            query = query.eq("difficulty_level", difficulty_filter)
        if search_filter:
            # Fallback to ILIKE if fuzzy search disabled; strip commas so the
            # PostgREST OR filter isn't corrupted by embedded commas.
            safe_filter = search_filter.replace(",", " ").strip()
            query = query.or_(f"name.ilike.%{safe_filter}%,original_name.ilike.%{safe_filter}%")

        if order_by:
            query = query.order(order_by)
        result = query.range(offset, offset + page_size - 1).execute()

        if not result.data:
            break

        all_rows.extend(result.data)

        if len(result.data) < page_size:
            break

        offset += page_size

    return all_rows


async def fetch_fuzzy_search_results(
    db,
    search_term: str,
    equipment_filter: str = None,
    body_part_filter: str = None,
    limit: int = 50
) -> List[Dict[str, Any]]:
    """
    Fetch exercises using fuzzy/trigram search for typo tolerance.
    Uses the fuzzy_search_exercises_api RPC function.

    Examples:
    - "benchpress" -> finds "Bench Press"
    - "bicep curl" -> finds "Barbell Curl", "Dumbbell Curl", etc.
    - "pusup" -> finds "Push Up", "Push-Up Variations"
    """
    from core.logger import get_logger
    logger = get_logger(__name__)

    try:
        # Call the RPC function for fuzzy search
        result = db.client.rpc(
            'fuzzy_search_exercises_api',
            {
                'search_term': search_term,
                'equipment_filter': equipment_filter,
                'body_part_filter': body_part_filter,
                'limit_count': limit
            }
        ).execute()

        if result.data:
            logger.info(f"Fuzzy search for '{search_term}' returned {len(result.data)} results")
            return result.data
        else:
            logger.info(f"Fuzzy search for '{search_term}' returned no results")
            return []

    except Exception as e:
        logger.warning(f"Fuzzy search RPC failed, falling back to ILIKE: {e}", exc_info=True)
        # Fallback to regular ILIKE search if fuzzy function not available;
        # strip commas so the PostgREST OR filter isn't corrupted.
        safe_term = search_term.replace(",", " ").strip()
        query = db.client.table("exercise_library_cleaned").select("*")
        query = query.or_(f"name.ilike.%{safe_term}%,original_name.ilike.%{safe_term}%,equipment.ilike.%{safe_term}%")
        if equipment_filter:
            query = query.ilike("equipment", f"%{equipment_filter}%")
        result = query.limit(limit).execute()
        return result.data if result.data else []


def sort_by_relevance(exercises: List['LibraryExercise'], search_query: str) -> List['LibraryExercise']:
    """Sort exercises by relevance to the search query.

    Tiers (lower = higher rank):
      0 — Exact name match
      1 — Simplified base name matches search (e.g., "High Plank" when searching "plank").
          Within tier 1:
            · If the exercise name is in the pattern's canonical list, rank by its
              canonical index (0-based) — curated canonical variants sort first in
              the order they're listed.
            · Otherwise, fall through to len(canonical) + word_count ASC so curated
              canonicals always precede non-canonical variants, and the legacy
              word-count/length/alphabetical tiebreaker still orders the rest.
      2 — Name starts with search query; tiebreak by word count, length
      3 — Search appears as a complete word in the name
      4 — Partial (substring) match
      5 — Everything else (trigram matches returned by SQL)
    """
    if not search_query:
        return exercises

    search_lower = search_query.lower().strip()

    def relevance_score(exercise: 'LibraryExercise') -> tuple:
        name_lower = (exercise.name or "").lower()
        simplified, canonical_lc = _get_simplified_and_canonicals(name_lower)

        if name_lower == search_lower:
            return (0, 0, 0, name_lower)

        if simplified and simplified.lower() == search_lower:
            if canonical_lc and name_lower in canonical_lc:
                # Pin canonical variants to the top of tier 1 in curator-specified order.
                return (1, canonical_lc.index(name_lower), 0, name_lower)
            # Non-canonical tier-1 match: offset by len(canonical) so canonicals
            # always rank first, then legacy word-count/length tiebreakers apply.
            return (1, len(canonical_lc) + len(name_lower.split()), len(name_lower), name_lower)

        if name_lower.startswith(search_lower):
            return (2, len(name_lower.split()), len(name_lower), name_lower)

        if re.search(r'\b' + re.escape(search_lower) + r'\b', name_lower):
            return (3, 0, len(name_lower), name_lower)

        if search_lower in name_lower:
            return (4, 0, len(name_lower), name_lower)

        return (5, 0, len(name_lower), name_lower)

    return sorted(exercises, key=relevance_score)


def normalize_body_part(target_muscle: str) -> str:
    """
    Normalize target_muscle to a simple body part category.
    The exercise_library has very detailed target_muscle values.
    We want to group them into broader categories.
    """
    if not target_muscle:
        return "Other"

    target_lower = target_muscle.lower()

    # Map to broader categories
    if any(x in target_lower for x in ["chest", "pectoralis"]):
        return "Chest"
    elif any(x in target_lower for x in ["back", "latissimus", "rhomboid", "trapezius"]):
        return "Back"
    elif any(x in target_lower for x in ["shoulder", "deltoid"]):
        return "Shoulders"
    elif any(x in target_lower for x in ["bicep", "brachii"]):
        return "Biceps"
    elif any(x in target_lower for x in ["tricep"]):
        return "Triceps"
    elif any(x in target_lower for x in ["forearm", "wrist"]):
        return "Forearms"
    elif any(x in target_lower for x in ["quad", "thigh"]):
        return "Quadriceps"
    elif any(x in target_lower for x in ["hamstring"]):
        return "Hamstrings"
    elif any(x in target_lower for x in ["glute"]):
        return "Glutes"
    elif any(x in target_lower for x in ["calf", "gastrocnemius", "soleus"]):
        return "Calves"
    elif any(x in target_lower for x in ["abdominal", "rectus abdominis", "core", "oblique"]):
        return "Core"
    elif any(x in target_lower for x in ["lower back", "erector"]):
        return "Lower Back"
    elif any(x in target_lower for x in ["hip", "adduct", "abduct"]):
        return "Hips"
    elif any(x in target_lower for x in ["neck"]):
        return "Neck"
    else:
        return "Other"


def row_to_library_exercise(row: dict, from_cleaned_view: bool = True) -> LibraryExercise:
    """Convert a Supabase row to LibraryExercise model.

    Args:
        row: Database row
        from_cleaned_view: True if row is from exercise_library_cleaned view,
                          False if from base exercise_library table

    View columns: id, name, original_name, body_part, equipment, target_muscle,
                  secondary_muscles, instructions, difficulty_level, category,
                  gif_url, video_url, goals, suitable_for, avoid_if
    """
    if from_cleaned_view:
        # From cleaned view - uses 'name' and 'original_name' columns
        # display_body_part is computed by the view with correct SQL-based muscle mapping
        # (fixes ordering bugs that existed in normalize_body_part — tricep/bicep and biceps femoris)
        return LibraryExercise(
            id=row.get("id"),
            name=row.get("name", ""),
            original_name=row.get("original_name", ""),
            body_part=row.get("display_body_part") or normalize_body_part(row.get("target_muscle") or row.get("body_part", "")),
            equipment=row.get("equipment", ""),
            target_muscle=row.get("target_muscle"),
            secondary_muscles=row.get("secondary_muscles"),
            instructions=row.get("instructions"),
            difficulty_level=row.get("difficulty_level"),
            category=row.get("category"),
            gif_url=row.get("gif_url"),
            video_url=presign_s3_path(row.get("video_url")),
            image_url=resolve_image_url(row.get("image_url")),
            goals=row.get("goals", []),
            suitable_for=row.get("suitable_for", []),
            avoid_if=row.get("avoid_if", []),
            movement_pattern=row.get("movement_pattern"),
            mechanic_type=row.get("mechanic_type"),
            force_type=row.get("force_type"),
            plane_of_motion=row.get("plane_of_motion"),
            energy_system=row.get("energy_system"),
            default_duration_seconds=row.get("default_duration_seconds"),
            default_rep_range_min=row.get("default_rep_range_min"),
            default_rep_range_max=row.get("default_rep_range_max"),
            default_rest_seconds=row.get("default_rest_seconds"),
            default_tempo=row.get("default_tempo"),
            default_incline_percent=row.get("default_incline_percent"),
            default_speed_mph=row.get("default_speed_mph"),
            default_resistance_level=row.get("default_resistance_level"),
            default_rpm=row.get("default_rpm"),
            stroke_rate_spm=row.get("stroke_rate_spm"),
            contraindicated_conditions=row.get("contraindicated_conditions"),
            impact_level=row.get("impact_level"),
            form_complexity=row.get("form_complexity"),
            stability_requirement=row.get("stability_requirement"),
            is_dynamic_stretch=row.get("is_dynamic_stretch"),
            hold_seconds_min=row.get("hold_seconds_min"),
            hold_seconds_max=row.get("hold_seconds_max"),
            single_dumbbell_friendly=row.get("single_dumbbell_friendly"),
            single_kettlebell_friendly=row.get("single_kettlebell_friendly"),
        )
    else:
        # From base table - clean name manually
        original_name = row.get("exercise_name", "")
        cleaned_name = re.sub(r'_(Female|Male|female|male)$', '', original_name).strip()
        return LibraryExercise(
            id=row.get("id"),
            name=cleaned_name,
            original_name=original_name,
            body_part=normalize_body_part(row.get("target_muscle") or row.get("body_part", "")),
            equipment=row.get("equipment", ""),
            target_muscle=row.get("target_muscle"),
            secondary_muscles=row.get("secondary_muscles"),
            instructions=row.get("instructions"),
            difficulty_level=row.get("difficulty_level"),
            category=row.get("category"),
            gif_url=row.get("gif_url"),
            video_url=row.get("video_s3_path"),
            image_url=resolve_image_url(row.get("image_s3_path")),
            goals=row.get("goals", []),
            suitable_for=row.get("suitable_for", []),
            avoid_if=row.get("avoid_if", []),
        )


def row_to_library_program(row: dict) -> LibraryProgram:
    """Convert a Supabase row from branded_programs table to LibraryProgram model.

    branded_programs fields: name, category, difficulty_level, duration_weeks,
    sessions_per_week, description, goals, tagline, split_type, is_featured,
    is_premium, requires_gym, icon_name, color_hex
    """
    # Calculate approximate session duration based on sessions per week
    sessions_per_week = row.get("sessions_per_week", 4)
    session_duration = 45 if sessions_per_week <= 4 else 60  # Default estimates

    # Use goals as tags since branded_programs doesn't have a separate tags field
    goals = row.get("goals") if isinstance(row.get("goals"), list) else []

    return LibraryProgram(
        id=row.get("id"),
        name=row.get("name", ""),  # branded_programs uses 'name' not 'program_name'
        category=row.get("category", ""),  # branded_programs uses 'category' not 'program_category'
        subcategory=row.get("split_type"),  # Map split_type to subcategory
        difficulty_level=row.get("difficulty_level"),
        duration_weeks=row.get("duration_weeks"),
        sessions_per_week=sessions_per_week,
        session_duration_minutes=session_duration,
        tags=goals,  # Use goals as tags
        goals=goals,
        description=row.get("description"),
        short_description=row.get("tagline"),  # Map tagline to short_description
        celebrity_name=None,  # branded_programs doesn't have celebrity_name
    )


def derive_exercise_type(video_url: str, body_part: str) -> str:
    """
    Derive exercise type from video path folder or body part.
    Video paths look like: s3://ai-fitness-coach/VERTICAL VIDEOS/Yoga/...
    """
    if not video_url:
        # Fallback based on body part
        if body_part and body_part.lower() in ['core', 'other']:
            return 'Functional'
        return 'Strength'

    video_lower = video_url.lower()

    # Check video path for exercise type indicators
    if 'yoga' in video_lower:
        return 'Yoga'
    elif 'stretch' in video_lower or 'mobility' in video_lower:
        return 'Stretching'
    elif 'hiit' in video_lower or 'cardio' in video_lower:
        return 'Cardio'
    elif 'calisthenics' in video_lower or 'functional' in video_lower:
        return 'Functional'
    elif 'abdominals' in video_lower or 'abs' in video_lower:
        return 'Core'
    elif any(x in video_lower for x in ['chest', 'back', 'shoulders', 'arms', 'legs', 'bicep', 'tricep']):
        return 'Strength'
    else:
        return 'Strength'


def derive_goals(name: str, body_part: str, target_muscle: str, video_url: str) -> List[str]:
    """
    Derive fitness goals this exercise supports based on name, muscles, and type.
    """
    goals = []
    name_lower = name.lower() if name else ""
    bp_lower = body_part.lower() if body_part else ""
    tm_lower = target_muscle.lower() if target_muscle else ""
    video_lower = video_url.lower() if video_url else ""

    # Testosterone boosting - compound movements targeting large muscle groups
    testosterone_keywords = ['squat', 'deadlift', 'bench press', 'row', 'pull-up', 'pullup',
                           'lunge', 'leg press', 'hip thrust', 'clean', 'snatch']
    if any(kw in name_lower for kw in testosterone_keywords) or bp_lower in ['quadriceps', 'glutes', 'back', 'chest']:
        goals.append('Testosterone Boost')

    # Weight loss / Fat burn - high intensity, cardio, full body
    fat_burn_keywords = ['jump', 'burpee', 'hiit', 'cardio', 'mountain climber', 'plank jack',
                        'high knee', 'sprint', 'skater', 'squat jump', 'box jump']
    if any(kw in name_lower for kw in fat_burn_keywords) or 'cardio' in video_lower or 'hiit' in video_lower:
        goals.append('Fat Burn')

    # Muscle building - strength exercises with weights
    muscle_keywords = ['press', 'curl', 'extension', 'row', 'fly', 'raise', 'pulldown', 'dip']
    if any(kw in name_lower for kw in muscle_keywords):
        goals.append('Muscle Building')

    # Flexibility - yoga, stretching
    flex_keywords = ['stretch', 'yoga', 'pose', 'flexibility', 'mobility', 'pigeon', 'cobra']
    if any(kw in name_lower for kw in flex_keywords) or 'yoga' in video_lower or 'stretch' in video_lower:
        goals.append('Flexibility')

    # Core strength
    core_keywords = ['crunch', 'plank', 'sit-up', 'ab ', 'core', 'twist', 'russian', 'hollow']
    if any(kw in name_lower for kw in core_keywords) or bp_lower == 'core':
        goals.append('Core Strength')

    # Pelvic floor / Hip health
    pelvic_keywords = ['kegel', 'pelvic', 'hip', 'glute bridge', 'clamshell', 'bird dog', 'dead bug']
    if any(kw in name_lower for kw in pelvic_keywords) or bp_lower in ['hips', 'glutes']:
        goals.append('Pelvic Health')

    # Posture improvement
    posture_keywords = ['face pull', 'reverse fly', 'row', 'scapula', 'thoracic', 'cat cow', 'superman']
    if any(kw in name_lower for kw in posture_keywords) or 'back' in bp_lower:
        goals.append('Posture')

    return goals if goals else ['General Fitness']


def derive_suitable_for(name: str, body_part: str, equipment: str, video_url: str) -> List[str]:
    """
    Derive who this exercise is suitable for based on intensity and requirements.
    """
    suitable = []
    name_lower = name.lower() if name else ""
    bp_lower = body_part.lower() if body_part else ""
    eq_lower = equipment.lower() if equipment else ""
    video_lower = video_url.lower() if video_url else ""

    # Beginner friendly - bodyweight, simple movements
    beginner_safe = ['wall', 'assisted', 'modified', 'seated', 'lying', 'supported']
    high_impact = ['jump', 'burpee', 'box jump', 'plyometric', 'sprint', 'snatch', 'clean']

    is_bodyweight = not equipment or 'bodyweight' in eq_lower or eq_lower == ''
    is_high_impact = any(kw in name_lower for kw in high_impact)
    is_beginner_mod = any(kw in name_lower for kw in beginner_safe)

    if (is_bodyweight and not is_high_impact) or is_beginner_mod:
        suitable.append('Beginner Friendly')

    # Senior friendly - low impact, seated, stability focused
    senior_safe = ['chair', 'seated', 'wall', 'balance', 'standing', 'stretch', 'yoga']
    if any(kw in name_lower for kw in senior_safe) and not is_high_impact:
        suitable.append('Senior Friendly')

    # Pregnancy safe - no lying flat, no high impact, no heavy abs
    pregnancy_unsafe = ['crunch', 'sit-up', 'lying leg raise', 'plank', 'burpee', 'jump',
                       'heavy', 'deadlift', 'v-up', 'twist']
    pregnancy_safe = ['cat cow', 'bird dog', 'kegel', 'pelvic tilt', 'wall sit',
                     'seated', 'standing', 'arm', 'shoulder']
    if any(kw in name_lower for kw in pregnancy_safe) and not any(kw in name_lower for kw in pregnancy_unsafe):
        suitable.append('Pregnancy Safe')

    # Low impact - good for joint issues
    if not is_high_impact and ('stretch' in video_lower or 'yoga' in video_lower or is_bodyweight):
        suitable.append('Low Impact')

    # Home workout friendly
    home_equipment = ['bodyweight', 'dumbbell', 'resistance band', 'yoga mat', 'chair',
                      'kettlebell', 'foam roller', 'medicine ball', 'ab wheel', 'jump rope',
                      'exercise ball', 'bosu ball', 'trx', 'suspension trainer', '']
    if not equipment or any(eq in eq_lower for eq in home_equipment):
        suitable.append('Home Workout')

    return suitable if suitable else ['Gym']


def derive_avoids(name: str, body_part: str, equipment: str) -> List[str]:
    """
    Derive what body parts/conditions this exercise might stress.
    Helps users with injuries filter out exercises.
    """
    avoids = []
    name_lower = name.lower() if name else ""
    bp_lower = body_part.lower() if body_part else ""

    # Exercises that stress the knees
    knee_stress = ['squat', 'lunge', 'leg press', 'leg extension', 'jump', 'step-up', 'pistol']
    if any(kw in name_lower for kw in knee_stress) or bp_lower in ['quadriceps', 'glutes']:
        avoids.append('Stresses Knees')

    # Exercises that stress the lower back
    back_stress = ['deadlift', 'bent over', 'good morning', 'hyperextension', 'row', 'clean', 'snatch']
    if any(kw in name_lower for kw in back_stress):
        avoids.append('Stresses Lower Back')

    # Exercises that stress shoulders
    shoulder_stress = ['overhead', 'press', 'raise', 'pull-up', 'dip', 'push-up', 'fly']
    if any(kw in name_lower for kw in shoulder_stress) or bp_lower == 'shoulders':
        avoids.append('Stresses Shoulders')

    # Exercises that stress wrists
    wrist_stress = ['push-up', 'plank', 'handstand', 'front rack', 'wrist']
    if any(kw in name_lower for kw in wrist_stress):
        avoids.append('Stresses Wrists')

    # High impact on joints
    high_impact = ['jump', 'burpee', 'box jump', 'plyometric', 'sprint', 'running']
    if any(kw in name_lower for kw in high_impact):
        avoids.append('High Impact')

    return avoids
