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
from fastapi import APIRouter, HTTPException
import boto3
from botocore.exceptions import ClientError
import os
import re
from dotenv import load_dotenv
from core.supabase_db import get_supabase_db

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
VIDEO_BASE_PREFIX = "VERTICAL VIDEOS/"  # Base folder for all videos
IMAGE_BASE_PREFIX = "ILLUSTRATIONS/"  # Base folder for all images
PRESIGNED_URL_EXPIRATION = 3600  # 1 hour


# NOTE: More specific routes must come BEFORE catch-all routes

def check_exercise_variant_exists(db, exercise_name: str) -> bool:
    """Check if an exercise variant exists in the database."""
    result = db.client.table("exercise_library").select(
        "exercise_name"
    ).ilike("exercise_name", exercise_name).limit(1).execute()
    return bool(result.data)


@router.get("/videos/by-exercise/{exercise_name:path}")
async def get_video_by_exercise_name(exercise_name: str, gender: str = None):
    """
    Get presigned video URL by exercise name.

    Looks up the exercise in exercise_library table and generates a presigned URL
    for the associated S3 video.

    If gender is specified ('male' or 'female'), tries to find gendered variant first.

    Args:
        exercise_name: Name of the exercise to lookup
        gender: Optional gender preference ('male' or 'female')

    Returns:
        Presigned URL and expiration time, plus gender variant info
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

        if not found_result:
            raise HTTPException(status_code=404, detail="Video not found for exercise")

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

        return {
            "url": url,
            "expires_in": PRESIGNED_URL_EXPIRATION,
            "exercise_name": found_exercise_name,
            "current_gender": current_gender,
            "has_male": has_male,
            "has_female": has_female
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get video URL: {str(e)}")


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

    return score


def search_s3_for_image(exercise_name: str, gender: str = None) -> str:
    """
    Search S3 ILLUSTRATIONS folder for matching exercise image.
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
        print(f"Error searching S3 for image: {e}")
        return None


@router.get("/exercise-images/{exercise_name:path}")
async def get_image_by_exercise_name(exercise_name: str, gender: str = None):
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

        # Try each name variant - use wildcard pattern for partial matches
        found_result = None
        for name in search_names:
            # First try exact match (case-insensitive) - this is definitive
            result = db.client.table("exercise_library").select(
                "image_s3_path, exercise_name"
            ).ilike("exercise_name", name).limit(1).execute()

            if result.data and result.data[0].get("image_s3_path"):
                found_result = result.data[0]
                break

            # Try partial match with wildcards (handles gender suffixes like _female, _male)
            # Get ALL matches and score them to find the best one
            result = db.client.table("exercise_library").select(
                "image_s3_path, exercise_name"
            ).ilike("exercise_name", f"{name}%").execute()

            if result.data:
                # Score all matches and pick the best one
                candidates = [r for r in result.data if r.get("image_s3_path")]
                if candidates:
                    best_match = max(candidates, key=lambda r: score_exercise_match(exercise_name, r["exercise_name"]))
                    if score_exercise_match(exercise_name, best_match["exercise_name"]) > 0:
                        found_result = best_match
                        break

            # Try contains match (exercise name contained anywhere)
            # Get ALL matches and score them to find the best one
            result = db.client.table("exercise_library").select(
                "image_s3_path, exercise_name"
            ).ilike("exercise_name", f"%{name}%").execute()

            if result.data:
                # Score all matches and pick the best one
                candidates = [r for r in result.data if r.get("image_s3_path")]
                if candidates:
                    best_match = max(candidates, key=lambda r: score_exercise_match(exercise_name, r["exercise_name"]))
                    if score_exercise_match(exercise_name, best_match["exercise_name"]) > 0:
                        found_result = best_match
                        break

        # If database lookup failed, try fuzzy S3 search
        if not found_result:
            s3_key = search_s3_for_image(exercise_name, gender)
            if s3_key:
                url = s3_client.generate_presigned_url(
                    'get_object',
                    Params={'Bucket': BUCKET_NAME, 'Key': s3_key},
                    ExpiresIn=PRESIGNED_URL_EXPIRATION
                )
                return {
                    "url": url,
                    "expires_in": PRESIGNED_URL_EXPIRATION,
                    "exercise_name": exercise_name,
                    "source": "s3_fuzzy_search"
                }

        if not found_result:
            raise HTTPException(status_code=404, detail="Image not found for exercise")

        s3_path = found_result["image_s3_path"]
        found_exercise_name = found_result["exercise_name"]

        # s3_path format: s3://bucket/key
        # Extract key from s3:// URI
        key = s3_path.replace(f"s3://{BUCKET_NAME}/", "")

        url = s3_client.generate_presigned_url(
            'get_object',
            Params={'Bucket': BUCKET_NAME, 'Key': key},
            ExpiresIn=PRESIGNED_URL_EXPIRATION
        )

        return {
            "url": url,
            "expires_in": PRESIGNED_URL_EXPIRATION,
            "exercise_name": found_exercise_name
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get image URL: {str(e)}")


@router.get("/videos/list/")
async def list_videos(subfolder: str = ""):
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
        raise HTTPException(status_code=500, detail=f"Failed to list videos: {str(e)}")


@router.get("/videos/folders/")
async def list_folders():
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
        raise HTTPException(status_code=500, detail=f"Failed to list folders: {str(e)}")


# This catch-all route must be LAST
@router.get("/videos/{video_path:path}")
async def get_video_url(video_path: str):
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
            raise HTTPException(status_code=500, detail=f"Failed to generate video URL: {str(e)}")
