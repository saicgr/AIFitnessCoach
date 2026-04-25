"""
Video streaming endpoint using S3 presigned URLs.

S3 Bucket Structure:
  s3://ai-fitness-coach/VERTICAL VIDEOS/
    ├── subfolder1/
    │   ├── video1.mp4
    │   └── video2.mp4
    └── subfolder2/
        └── video3.mp4
"""
from core.db import get_supabase_db
from typing import List

from fastapi import APIRouter, Depends, HTTPException
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from pydantic import BaseModel
import boto3
from botocore.exceptions import ClientError
import os
import re
from dotenv import load_dotenv
from core.logger import get_logger

logger = get_logger(__name__)

# Load .env file to ensure credentials are available
load_dotenv()

router = APIRouter()

# Initialize S3 client with explicit credentials from environment
# Use signature v4 for presigned URLs
from botocore.config import Config
s3_client = boto3.client(
    's3',
    aws_access_key_id=os.getenv('AWS_ACCESS_KEY_ID'),
    aws_secret_access_key=os.getenv('AWS_SECRET_ACCESS_KEY'),
    region_name=os.getenv('AWS_DEFAULT_REGION', 'us-east-1'),
    config=Config(signature_version='s3v4')
)

BUCKET_NAME = os.getenv('S3_BUCKET_NAME', 'ai-fitness-coach')
VIDEO_BASE_PREFIX = "VERTICAL VIDEOS ALL/"  # Base folder for all videos
IMAGE_BASE_PREFIX = "ILLUSTRATIONS ALL/"  # Base folder for all images
PRESIGNED_URL_EXPIRATION = 3600  # 1 hour


# NOTE: More specific routes must come BEFORE catch-all routes

def check_exercise_variant_exists(db, exercise_name: str) -> bool:
    """Check if an exercise variant exists in the database."""
    result = db.client.table("exercise_library").select(
        "exercise_name"
    ).ilike("exercise_name", exercise_name).limit(1).execute()
    return bool(result.data)


# Similarity threshold for the ChromaDB substitute fallback. Chroma cosine
# distance is in [0, 2]; distance 0 == identical, distance ~0.6 == loosely
# related. We only substitute when the closest canonical exercise is
# meaningfully similar to avoid showing a stretch video for a missing squat.
_SUBSTITUTE_DISTANCE_THRESHOLD = 0.55

# Categories that should NOT be cross-substituted. We never want a "Running"
# query to return a "Hamstring Stretch" video, even if the embeddings happen
# to land close.
_SUBSTITUTE_CATEGORY_GUARDS = {
    "cardio": {"strength", "stretch", "mobility"},
    "stretch": {"strength", "cardio", "plyometric"},
    "mobility": {"strength", "cardio", "plyometric"},
    "plyometric": {"stretch", "mobility"},
}


def _classify_exercise_for_substitute(name: str, body_part: str = "", muscle_group: str = "") -> str:
    """Coarse category for the substitute guardrails. Conservative on purpose."""
    n = (name or "").lower()
    bp = (body_part or "").lower()
    mg = (muscle_group or "").lower()
    if any(w in n for w in ("stretch", "yoga", "pigeon", "downward dog", "child's pose")):
        return "stretch"
    if any(w in n for w in ("mobility", "foam roll", "lacrosse")):
        return "mobility"
    if any(w in n for w in ("running", "jog", "sprint", "cycling", "bike", "rowing machine",
                            "rower", "jump rope", "elliptical", "stair", "treadmill", "swim",
                            "battle rope", "sled", "cardio", "hiit")):
        return "cardio"
    if any(w in n for w in ("jump", "plyo", "bound", "hop", "skater", "explosive")):
        return "plyometric"
    if "cardio" in mg or "cardio" in bp:
        return "cardio"
    return "strength"


async def _find_substitute_video(
    db,
    original_name: str,
    user_id: str | None,
) -> dict | None:
    """
    Fallback path when the canonical exercise_library has no video for
    `original_name`. Searches:
      (1) custom_exercise_library ChromaDB collection — the user's own custom
          exercises and public custom exercises (returns own video_s3_path
          if present in metadata),
      (2) the canonical fitness_exercises ChromaDB collection — finds the
          closest canonical exercise above the similarity threshold and
          returns its video as an honest substitute.

    Returns None if no good match is found, in which case the caller raises
    404. Never silently returns a low-quality substitute.
    """
    try:
        from services.exercise_rag.service import get_exercise_rag_service
    except Exception as e:
        logger.warning(
            f"[Video Fallback] exercise_rag service unavailable: {e}"
        )
        return None

    try:
        rag = get_exercise_rag_service()
        query_embedding = await rag.gemini_service.get_embedding_async(original_name)
        if not query_embedding:
            return None
    except Exception as e:
        logger.warning(f"[Video Fallback] embedding failed for '{original_name}': {e}")
        return None

    original_category = _classify_exercise_for_substitute(original_name)
    blocked_categories = _SUBSTITUTE_CATEGORY_GUARDS.get(original_category, set())

    # Step 1: search the user's custom exercise collection (their imports +
    # any public custom exercise). These may have their own video uploads.
    try:
        custom_results = rag.query_custom_collection(
            query_embedding=query_embedding,
            user_id=user_id,
            n_results=5,
        )
        if custom_results.get("ids") and custom_results["ids"][0]:
            for idx, ex_id in enumerate(custom_results["ids"][0]):
                metas = custom_results.get("metadatas", [[]])[0]
                if idx >= len(metas):
                    continue
                meta = metas[idx] or {}
                video_path = meta.get("video_s3_path")
                if not video_path:
                    continue
                distance = (
                    custom_results.get("distances", [[]])[0][idx]
                    if idx < len(custom_results.get("distances", [[]])[0])
                    else 1.0
                )
                if distance > _SUBSTITUTE_DISTANCE_THRESHOLD:
                    continue
                matched_name = meta.get("exercise_name") or ex_id
                # Category guard
                matched_cat = _classify_exercise_for_substitute(
                    matched_name,
                    meta.get("body_part", ""),
                    meta.get("muscle_group", ""),
                )
                if matched_cat in blocked_categories:
                    continue
                return {
                    "video_s3_path": video_path,
                    "matched_name": matched_name,
                    "distance": distance,
                    "source": "custom",
                }
    except Exception as e:
        logger.warning(f"[Video Fallback] custom collection query failed: {e}")

    # Step 2: similarity search the canonical exercise_library via ChromaDB.
    try:
        canonical_results = rag.collection.query(
            query_embeddings=[query_embedding],
            n_results=10,
            include=["metadatas", "distances"],
        )
        if not canonical_results.get("ids") or not canonical_results["ids"][0]:
            return None

        ids = canonical_results["ids"][0]
        distances = canonical_results.get("distances", [[]])[0]
        metas = canonical_results.get("metadatas", [[]])[0]

        for idx in range(len(ids)):
            if idx >= len(distances) or idx >= len(metas):
                continue
            distance = distances[idx]
            if distance > _SUBSTITUTE_DISTANCE_THRESHOLD:
                continue
            meta = metas[idx] or {}
            matched_name = meta.get("exercise_name") or ids[idx]
            # Skip self-match (shouldn't happen, but guard) and empty rows.
            if not matched_name:
                continue
            if matched_name.lower() == original_name.lower():
                continue
            # Category guard
            matched_cat = _classify_exercise_for_substitute(
                matched_name,
                meta.get("body_part", ""),
                meta.get("muscle_group", ""),
            )
            if matched_cat in blocked_categories:
                continue
            # Look up a canonical entry with a usable video_s3_path. The
            # ChromaDB metadata may not carry video_s3_path, so resolve via
            # exercise_library. Use the same name-variant expansion as the
            # primary path so DB casing differences don't fail the lookup.
            for variant in generate_name_variants(matched_name):
                row = db.client.table("exercise_library").select(
                    "video_s3_path, exercise_name"
                ).ilike("exercise_name", variant).limit(1).execute()
                if row.data and row.data[0].get("video_s3_path"):
                    return {
                        "video_s3_path": row.data[0]["video_s3_path"],
                        "matched_name": row.data[0]["exercise_name"],
                        "distance": distance,
                        "source": "canonical",
                    }
    except Exception as e:
        logger.warning(f"[Video Fallback] canonical similarity query failed: {e}")

    return None


@router.get("/videos/by-exercise/{exercise_name:path}")
async def get_video_by_exercise_name(exercise_name: str, gender: str = None,
    current_user: dict = Depends(get_current_user),
):
    """
    Get presigned video URL by exercise name.

    Looks up the exercise in exercise_library table and generates a presigned URL
    for the associated S3 video.

    If gender is specified ('male' or 'female'), tries to find gendered variant first.

    On miss, falls back to a similarity search across the user's custom
    exercise collection and the canonical exercise library, returning the
    closest match's video with `is_substitute: true` so the client can
    surface an honest banner.

    Args:
        exercise_name: Name of the exercise to lookup
        gender: Optional gender preference ('male' or 'female')

    Returns:
        Presigned URL and expiration time, plus gender variant info. When the
        result is a similarity-matched substitute, also returns:
          - is_substitute: True
          - similar_to: {original, matched, similarity}
    """
    try:
        db = get_supabase_db()

        # Build list of exercise names to try
        # Strip any existing gender suffix to get base name
        base_name = exercise_name.replace('_male', '').replace('_female', '')

        search_names = []
        if gender in ('male', 'female'):
            search_names.append(f"{base_name}_{gender}")
        search_names.append(exercise_name)  # Original name as fallback
        search_names.append(base_name)      # Base name as last resort

        # Expand with name variants to handle format differences (Push-ups vs Push Up)
        expanded_names = []
        for name in search_names:
            expanded_names.extend(generate_name_variants(name))
        search_names = list(dict.fromkeys(expanded_names))  # Dedupe preserving order

        # Try each name variant - use wildcard pattern for partial matches
        found_result = None
        for name in search_names:
            # First try exact match (case-insensitive)
            result = db.client.table("exercise_library").select(
                "video_s3_path, exercise_name"
            ).ilike("exercise_name", name).limit(1).execute()

            if result.data and result.data[0].get("video_s3_path"):
                found_result = result.data[0]
                break

            # Try partial match with wildcards (handles gender suffixes like _female, _male)
            result = db.client.table("exercise_library").select(
                "video_s3_path, exercise_name"
            ).ilike("exercise_name", f"{name}%").limit(1).execute()

            if result.data and result.data[0].get("video_s3_path"):
                found_result = result.data[0]
                break

        is_substitute = False
        similar_to = None
        if not found_result:
            user_id = current_user.get("id") if isinstance(current_user, dict) else None
            substitute = await _find_substitute_video(db, exercise_name, user_id)
            if substitute is None:
                raise HTTPException(status_code=404, detail="Video not found for exercise")
            found_result = {
                "video_s3_path": substitute["video_s3_path"],
                "exercise_name": substitute["matched_name"],
            }
            is_substitute = True
            # Convert cosine distance to a 0..1 similarity for the UI.
            similarity = max(0.0, min(1.0, 1.0 - (substitute["distance"] / 2.0)))
            similar_to = {
                "original": exercise_name,
                "matched": substitute["matched_name"],
                "similarity": round(similarity, 3),
                "source": substitute.get("source", "canonical"),
            }
            logger.info(
                f"[Video Fallback] '{exercise_name}' → '{substitute['matched_name']}' "
                f"(distance={substitute['distance']:.3f}, source={substitute.get('source')})"
            )

        s3_path = found_result["video_s3_path"]
        found_exercise_name = found_result["exercise_name"]

        # s3_path format: s3://bucket/key
        # Extract key from s3:// URI
        key = s3_path.replace(f"s3://{BUCKET_NAME}/", "")

        url = s3_client.generate_presigned_url(
            'get_object',
            Params={'Bucket': BUCKET_NAME, 'Key': key},
            ExpiresIn=PRESIGNED_URL_EXPIRATION
        )

        # Determine current gender from found exercise name
        current_gender = None
        if "_male" in found_exercise_name.lower():
            current_gender = "male"
        elif "_female" in found_exercise_name.lower():
            current_gender = "female"

        # Check if gender variants exist
        has_male = check_exercise_variant_exists(db, f"{base_name}_male")
        has_female = check_exercise_variant_exists(db, f"{base_name}_female")

        response: dict = {
            "url": url,
            "expires_in": PRESIGNED_URL_EXPIRATION,
            "exercise_name": found_exercise_name,
            "current_gender": current_gender,
            "has_male": has_male,
            "has_female": has_female,
        }
        if is_substitute:
            response["is_substitute"] = True
            response["similar_to"] = similar_to
        return response

    except HTTPException:
        raise
    except Exception as e:
        raise safe_internal_error(e, "video_url_by_exercise")


def normalize_exercise_name(name: str) -> str:
    """Normalize exercise name for matching: lowercase, remove special chars, collapse spaces."""
    # Convert to lowercase
    name = name.lower()
    # Remove special characters except spaces and underscores
    name = re.sub(r'[^a-z0-9\s_]', '', name)
    # Replace underscores with spaces
    name = name.replace('_', ' ')
    # Collapse multiple spaces
    name = re.sub(r'\s+', ' ', name).strip()
    return name


def get_search_keywords(exercise_name: str) -> list:
    """Extract key search terms from exercise name."""
    normalized = normalize_exercise_name(exercise_name)
    # Remove common filler words
    stopwords = {'the', 'a', 'an', 'with', 'on', 'in', 'for', 'to', 'and', 'or'}
    words = [w for w in normalized.split() if w not in stopwords and len(w) > 2]
    return words


def generate_name_variants(name: str) -> list:
    """Generate name variants for flexible database matching.

    Handles common variations like:
    - Push-ups -> Push Up, Push-up, Push up
    - Squats -> Squat
    """
    variants = set()
    variants.add(name)

    # Replace hyphens with spaces
    space_version = name.replace("-", " ")
    variants.add(space_version)

    # Remove trailing 's' for plural handling (Push-ups -> Push-up)
    if name.endswith("s") and len(name) > 2:
        singular = name[:-1]
        variants.add(singular)
        variants.add(singular.replace("-", " "))

    # Handle space version singular
    if space_version.endswith("s") and len(space_version) > 2:
        singular = space_version[:-1]
        variants.add(singular)

    return list(variants)


def score_exercise_match(search_name: str, db_name: str) -> int:
    """
    Score how well a database exercise name matches the search term.

    Higher scores indicate better matches. Used to pick the best match
    when multiple partial matches are found.

    Args:
        search_name: The exercise name being searched for
        db_name: The exercise name from the database

    Returns:
        Integer score (higher is better)
    """
    search_words = set(search_name.lower().split())
    db_words = set(db_name.lower().split())

    # Remove common suffixes for comparison
    search_words = {w.replace('_male', '').replace('_female', '') for w in search_words}
    db_words = {w.replace('_male', '').replace('_female', '') for w in db_words}

    # Count matching words
    matching_words = len(search_words & db_words)

    # Penalize extra words in db_name that aren't in search
    # e.g., "Alternating Plank Lunge" has extra "Plank" when searching "Alternating Reverse Lunge"
    extra_words = len(db_words - search_words)

    # Penalize missing words from search that aren't in db
    # e.g., searching "Reverse Lunge" but db has "Alternating Lunge" (missing "Reverse")
    missing_words = len(search_words - db_words)

    # Base score: matching words weighted heavily
    score = matching_words * 10

    # Penalty for extra/missing words
    score -= extra_words * 3
    score -= missing_words * 5  # Missing words are worse than extra words

    # Bonus for exact length match (same word count)
    if len(search_words) == len(db_words):
        score += 5

    # Bonus when search is a prefix of db name (e.g., "Leg Press" → "Leg press machine normal stance")
    # This prefers the base exercise variant over modifier-prefixed names like "Band Leg Press"
    if db_name.lower().startswith(search_name.lower()):
        score += 8

    return score


def search_s3_for_image(exercise_name: str, gender: str = None) -> str:
    """
    Search S3 ILLUSTRATIONS ALL folder for matching exercise image.
    Uses fuzzy matching on filename with pagination support.
    """
    try:
        keywords = get_search_keywords(exercise_name)
        if not keywords:
            return None

        best_match = None
        best_score = 0

        # Use paginator to handle more than 1000 objects
        paginator = s3_client.get_paginator('list_objects_v2')
        pages = paginator.paginate(Bucket=BUCKET_NAME, Prefix=IMAGE_BASE_PREFIX)

        for page in pages:
            if 'Contents' not in page:
                continue

            for obj in page['Contents']:
                key = obj['Key']
                # Only consider image files
                if not key.lower().endswith(('.png', '.jpg', '.jpeg', '.gif', '.webp')):
                    continue

                # Get filename without path and extension
                filename = key.split('/')[-1]
                filename_base = filename.rsplit('.', 1)[0]
                normalized_filename = normalize_exercise_name(filename_base)

                # Calculate match score based on keyword matches
                score = 0
                for keyword in keywords:
                    if keyword in normalized_filename:
                        score += len(keyword)  # Weight by keyword length

                # Gender preference bonus
                if gender:
                    if gender.lower() in normalized_filename:
                        score += 5
                    # Penalize wrong gender
                    other_gender = 'female' if gender == 'male' else 'male'
                    if other_gender in normalized_filename:
                        score -= 10

                if score > best_score:
                    best_score = score
                    best_match = key

        # Require at least some match quality (at least one keyword fully matched)
        min_required_score = len(keywords[0]) if keywords else 0
        if best_score >= min_required_score:
            return best_match

        return None

    except Exception as e:
        logger.error(f"Error searching S3 for image: {e}", exc_info=True)
        return None


@router.get("/exercise-images/{exercise_name:path}")
async def get_image_by_exercise_name(exercise_name: str, gender: str = None,
    current_user: dict = Depends(get_current_user),
):
    """
    Get presigned image URL by exercise name.

    Looks up the exercise in exercise_library table and generates a presigned URL
    for the associated S3 illustration image.

    If gender is specified ('male' or 'female'), tries to find gendered variant first.

    Falls back to S3 fuzzy search if database lookup fails.

    Args:
        exercise_name: Name of the exercise to lookup
        gender: Optional gender preference ('male' or 'female')

    Returns:
        Presigned URL and expiration time
    """
    try:
        db = get_supabase_db()

        # Build list of exercise names to try
        # Strip any existing gender suffix to get base name
        base_name = exercise_name.replace('_male', '').replace('_female', '').replace('_Male', '').replace('_Female', '')

        search_names = []
        if gender in ('male', 'female'):
            search_names.append(f"{base_name}_{gender}")
        search_names.append(exercise_name)  # Original name as fallback
        search_names.append(base_name)      # Base name as last resort

        # Expand with name variants to handle format differences (Push-ups vs Push Up)
        expanded_names = []
        for name in search_names:
            expanded_names.extend(generate_name_variants(name))
        search_names = list(dict.fromkeys(expanded_names))  # Dedupe preserving order

        # Collect ALL potential matches from ALL search variants, then pick best
        found_result = None
        all_candidates = []

        for name in search_names:
            # First try exact match (case-insensitive) - this is definitive
            result = db.client.table("exercise_library").select(
                "image_s3_path, exercise_name"
            ).ilike("exercise_name", name).limit(1).execute()

            if result.data and result.data[0].get("image_s3_path"):
                # Exact match found - use it immediately
                found_result = result.data[0]
                break

            # Try partial match with wildcards (handles gender suffixes like _female, _male)
            result = db.client.table("exercise_library").select(
                "image_s3_path, exercise_name"
            ).ilike("exercise_name", f"{name}%").execute()

            if result.data:
                candidates = [r for r in result.data if r.get("image_s3_path")]
                all_candidates.extend(candidates)

            # Try contains match (exercise name contained anywhere)
            result = db.client.table("exercise_library").select(
                "image_s3_path, exercise_name"
            ).ilike("exercise_name", f"%{name}%").execute()

            if result.data:
                candidates = [r for r in result.data if r.get("image_s3_path")]
                all_candidates.extend(candidates)

        # If no exact match found, pick the best from all candidates
        if not found_result and all_candidates:
            # Dedupe by exercise_name
            seen = set()
            unique_candidates = []
            for c in all_candidates:
                if c["exercise_name"] not in seen:
                    seen.add(c["exercise_name"])
                    unique_candidates.append(c)

            # Score all unique matches and pick the best one
            if unique_candidates:
                best_match = max(unique_candidates, key=lambda r: score_exercise_match(exercise_name, r["exercise_name"]))
                # Accept any match with a reasonable score (negative is OK for partial matches)
                if score_exercise_match(exercise_name, best_match["exercise_name"]) >= -10:
                    found_result = best_match

        # If database lookup failed, try fuzzy S3 search
        if not found_result:
            s3_key = search_s3_for_image(exercise_name, gender)
            if s3_key:
                from api.v1.library.utils import resolve_image_url
                s3_path = f"s3://{BUCKET_NAME}/{s3_key}"
                url = resolve_image_url(s3_path)
                return {
                    "url": url,
                    "expires_in": None,
                    "exercise_name": exercise_name,
                    "source": "s3_fuzzy_search"
                }

        if not found_result:
            # Missing image isn't an error — it's a data state. Return 200
            # with url=null so the client can render a placeholder silently
            # instead of throwing DioException on every exercise the library
            # hasn't been populated for. Also avoids filling Sentry/Discord
            # with false-positive "Backend Error" alerts (404s aren't server
            # errors, they're expected cache misses).
            return {
                "url": None,
                "expires_in": None,
                "exercise_name": exercise_name,
                "source": "not_found",
            }

        s3_path = found_result["image_s3_path"]
        found_exercise_name = found_result["exercise_name"]

        from api.v1.library.utils import resolve_image_url
        url = resolve_image_url(s3_path)

        return {
            "url": url,
            "expires_in": None,
            "exercise_name": found_exercise_name
        }

    except HTTPException:
        raise
    except Exception as e:
        raise safe_internal_error(e, "image_url_by_exercise")


class BatchImageRequest(BaseModel):
    names: List[str]


@router.post("/exercise-images/batch")
async def batch_get_image_urls(request: BatchImageRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Batch resolve exercise names to presigned image URLs.

    Accepts up to 100 exercise names and returns a dict of {name: presigned_url}.
    Uses exact name match on the cleaned exercise library view for speed.

    Names not found (case mismatch, typo) are silently omitted — the frontend
    falls back to the individual GET /exercise-images/{name} endpoint which
    does fuzzy matching.
    """
    try:
        db = get_supabase_db()

        # Sanitize: cap at 100 names, skip blanks and overly long strings
        names = [
            n for n in request.names[:100]
            if n and len(n) <= 200
        ]

        if not names:
            return {"urls": {}}

        # Query cleaned view with exact name match (single DB call)
        result = db.client.table("exercise_library_cleaned").select(
            "name, image_url"
        ).in_("name", names).execute()

        # Generate permanent or presigned URLs for matching exercises
        from api.v1.library.utils import resolve_image_url
        urls = {}
        for row in (result.data or []):
            name = row.get("name", "")
            s3_path = row.get("image_url")
            if not name or not s3_path or not s3_path.startswith("s3://"):
                continue
            url = resolve_image_url(s3_path)
            if url:
                urls[name] = url

        return {"urls": urls, "resolved": len(urls), "requested": len(names)}

    except Exception as e:
        raise safe_internal_error(e, "batch_image_resolve")


@router.get("/videos/list/")
async def list_videos(subfolder: str = "",
    current_user: dict = Depends(get_current_user),
):
    """
    List all videos in S3 bucket under "VERTICAL VIDEOS/" folder.

    Args:
        subfolder: Optional subfolder within "VERTICAL VIDEOS/" to filter
                  Examples: "Upper Body/Chest", "Lower Body/Legs"

    Returns:
        List of videos with their paths and metadata
    """
    try:
        # Build the full prefix
        if subfolder:
            full_prefix = f"{VIDEO_BASE_PREFIX}{subfolder}/"
        else:
            full_prefix = VIDEO_BASE_PREFIX

        response = s3_client.list_objects_v2(
            Bucket=BUCKET_NAME,
            Prefix=full_prefix
        )

        if 'Contents' not in response:
            return {"videos": [], "count": 0, "subfolder": subfolder}

        videos = []
        for obj in response['Contents']:
            # Only include video files
            if obj['Key'].lower().endswith(('.mp4', '.mov', '.avi', '.webm', '.mkv')):
                # Remove the base prefix to get relative path
                relative_path = obj['Key'].replace(VIDEO_BASE_PREFIX, '', 1)

                videos.append({
                    "relative_path": relative_path,  # Path without "VERTICAL VIDEOS/"
                    "full_s3_key": obj['Key'],       # Full S3 key
                    "size_bytes": obj['Size'],
                    "size_mb": round(obj['Size'] / (1024 * 1024), 2),
                    "last_modified": obj['LastModified'].isoformat()
                })

        return {
            "videos": videos,
            "count": len(videos),
            "subfolder": subfolder,
            "base_prefix": VIDEO_BASE_PREFIX
        }

    except ClientError as e:
        raise safe_internal_error(e, "video_list")


@router.get("/videos/folders/")
async def list_folders(
    current_user: dict = Depends(get_current_user),
):
    """
    List all subfolders under "VERTICAL VIDEOS/" in S3.

    Returns:
        List of unique subfolder paths
    """
    try:
        response = s3_client.list_objects_v2(
            Bucket=BUCKET_NAME,
            Prefix=VIDEO_BASE_PREFIX,
            Delimiter='/'
        )

        folders = []

        # Get immediate subfolders
        if 'CommonPrefixes' in response:
            for prefix in response['CommonPrefixes']:
                folder_path = prefix['Prefix'].replace(VIDEO_BASE_PREFIX, '', 1).rstrip('/')
                folders.append(folder_path)

        return {
            "folders": sorted(folders),
            "count": len(folders),
            "base_prefix": VIDEO_BASE_PREFIX
        }

    except ClientError as e:
        raise safe_internal_error(e, "video_folders")


# This catch-all route must be LAST
@router.get("/videos/{video_path:path}")
async def get_video_url(video_path: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Generate a presigned URL for a video in S3.

    Args:
        video_path: Path to the video file relative to "VERTICAL VIDEOS/" folder
                   Examples:
                   - "Upper Body/Chest/bench_press.mp4"
                   - "Lower Body/Legs/squats.mp4"

    Returns:
        Presigned URL valid for 1 hour
    """
    try:
        # Construct full S3 key with base prefix
        full_key = f"{VIDEO_BASE_PREFIX}{video_path}"

        # Generate presigned URL
        url = s3_client.generate_presigned_url(
            'get_object',
            Params={
                'Bucket': BUCKET_NAME,
                'Key': full_key
            },
            ExpiresIn=PRESIGNED_URL_EXPIRATION
        )

        return {
            "url": url,
            "expires_in": PRESIGNED_URL_EXPIRATION,
            "video_path": video_path,
            "full_s3_key": full_key
        }

    except ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == 'NoSuchKey':
            raise HTTPException(status_code=404, detail=f"Video not found: {full_key}")
        else:
            raise safe_internal_error(e, "video_presigned_url")
