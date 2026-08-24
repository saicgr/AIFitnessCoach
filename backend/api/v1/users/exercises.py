"""
Favorite exercises and exercise queue endpoints.
"""
import re
from core.db import get_supabase_db
from fastapi import APIRouter, Depends, HTTPException
from core.auth import get_current_user, verify_user_ownership
from core.exceptions import safe_internal_error
from typing import List, Optional, Tuple

from core.logger import get_logger

from api.v1.users.models import (
    FavoriteExerciseRequest,
    FavoriteExercise,
    QueueExerciseRequest,
    QueuedExercise,
    QueueExerciseUpdateRequest,
)

router = APIRouter()
logger = get_logger(__name__)


_PAREN_ASIDE_RE = re.compile(r"\([^)]*\)")
_WHITESPACE_RE = re.compile(r"\s+")
_WORD_RE = re.compile(r"[a-z0-9]+")


def _normalize_for_alias_lookup(name: str) -> str:
    """Reproduce `exercise_aliases.alias_name_normalized`'s normalization.

    That column is precomputed as: lowercase, parenthetical asides dropped
    (e.g. "Barbell Overhead Press (OHP)" -> "barbell overhead press"),
    hyphens treated as word separators, whitespace collapsed. Matching this
    exactly is what lets an exact (non-fuzzy) lookup against the alias table
    hit real rows.
    """
    if not name:
        return ""
    cleaned = _PAREN_ASIDE_RE.sub(" ", name)
    cleaned = cleaned.replace("-", " ")
    cleaned = cleaned.lower()
    return _WHITESPACE_RE.sub(" ", cleaned).strip()


def _resolve_via_exercise_aliases(
    db, exercise_name: str
) -> Optional[Tuple[str, str]]:
    """Exact-normalized lookup against the curated `exercise_aliases` table.

    E2E #233 (audit follow-up): most Quick-Add staples ("Barbell Back
    Squat", "Plank", "Dips", "Pull-Up", ...) have NO literal row in
    `exercise_library_cleaned` — that table only carries heavily-qualified
    variants ("Ring Dips", "Kneeling Plank", "Pull-Up Normal Grip", ...), so
    an exact (or even substring) match against it fails for exactly the
    common names the app's own suggestion chips show. `exercise_aliases`
    exists precisely to map a commonly-typed name to a real exercise and
    already carries entries for all of them. Its `canonical_exercise_id`
    points at `exercise_canonical`, not `exercise_library_cleaned` — a
    different id space — so the canonical row's own name is looked up there
    rather than assumed to also exist in the cleaned view.
    """
    normalized = _normalize_for_alias_lookup(exercise_name)
    if not normalized:
        return None
    try:
        alias_match = (
            db.client.table("exercise_aliases")
            .select("canonical_exercise_id")
            .eq("alias_name_normalized", normalized)
            .limit(1)
            .execute()
        )
        if not alias_match.data:
            return None
        canonical_id = alias_match.data[0].get("canonical_exercise_id")
        if not canonical_id:
            return None
        canon = (
            db.client.table("exercise_canonical")
            .select("id, canonical_name, display_name")
            .eq("id", canonical_id)
            .limit(1)
            .execute()
        )
        if canon.data:
            row = canon.data[0]
            name = row.get("display_name") or row.get("canonical_name") or exercise_name
            return row["id"], name
    except Exception as e:
        logger.warning(f"Alias exercise lookup failed for '{exercise_name}': {e}")
    return None


def _resolve_via_token_match(db, exercise_name: str) -> Optional[Tuple[str, str]]:
    """Last-resort token-overlap fallback against `exercise_library_cleaned`.

    Requires every significant word of the query to appear in the candidate
    name (an AND-chain of ILIKE substrings), then prefers whichever
    candidate's own word count is closest to the query's — the fewest extra
    qualifiers — so a generic query doesn't silently latch onto an
    unrelated, heavily-qualified variant. Only reached when neither the
    exact-match nor the curated alias table (above) resolved anything.
    """
    words = [w for w in _WORD_RE.findall(exercise_name.lower()) if w]
    if not words:
        return None
    try:
        query = db.client.table("exercise_library_cleaned").select("id, name")
        for w in words:
            query = query.ilike("name", f"%{w}%")
        result = query.limit(25).execute()
        candidates = result.data or []
        if not candidates:
            return None

        def _rank(row):
            name_words = _WORD_RE.findall((row.get("name") or "").lower())
            return (abs(len(name_words) - len(words)), row.get("name") or "")

        candidates.sort(key=_rank)
        best = candidates[0]
        return best["id"], best["name"]
    except Exception as e:
        logger.warning(f"Token-match exercise lookup failed for '{exercise_name}': {e}")
    return None


def _resolve_canonical_exercise(db, exercise_name: str, exercise_id):
    """Resolve a Quick-Add/picker name to a real canonical exercise row.

    The UI displays a title-cased/cleaned name while the library stores
    exercise_name inconsistently cased (e.g. "barbell bench press"), so an
    exact-match write silently persists `exercise_id: null` — the favorite
    can never be matched back to a real exercise at generation time.
    `exercise_library_cleaned` unions `exercise_library` with
    `exercise_library_manual` and exposes the already-cleaned display name
    the Quick-Add chips show (e.g. "Lat Pulldown", "Leg Press" only exist
    under this cleaned name, sourced from `exercise_library_manual`, not the
    raw `exercise_library` table). If the caller already supplied an
    exercise_id (picked from the library, already canonical) it is trusted
    as-is.

    Resolution order (exact match always wins; E2E #233 audit follow-up
    adds the rest — an exact-only lookup left 9 of 12 of the app's own
    suggested staples unresolved because the library only has
    heavily-qualified variants of those names, never the plain form):
      1. Exact case-insensitive match against `exercise_library_cleaned`
         (`ilike` with no wildcards — a plain equality check, never a
         substring match, so it can never over-match).
      2. Exact-normalized lookup against the curated `exercise_aliases`
         table (naming-variance handling for names the cleaned library
         doesn't carry in plain form at all).
      3. Conservative token-overlap match against
         `exercise_library_cleaned`, for anything still unresolved.
    Falls back to the name/id as given when nothing resolves, so a
    genuinely-missing name still saves instead of failing the request.
    """
    if exercise_id:
        return exercise_id, exercise_name
    if not exercise_name:
        return exercise_id, exercise_name
    try:
        match = db.client.table("exercise_library_cleaned").select(
            "id, name"
        ).ilike("name", exercise_name).limit(1).execute()
        if match.data:
            row = match.data[0]
            return row["id"], row["name"]
    except Exception as e:
        logger.warning(f"Canonical exercise lookup failed for '{exercise_name}': {e}")

    alias_hit = _resolve_via_exercise_aliases(db, exercise_name)
    if alias_hit:
        return alias_hit

    token_hit = _resolve_via_token_match(db, exercise_name)
    if token_hit:
        return token_hit

    return exercise_id, exercise_name


@router.get("/{user_id}/favorite-exercises", response_model=List[FavoriteExercise])
async def get_favorite_exercises(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Get all favorite exercises for a user.

    Used by the workout generation system to prioritize exercises
    the user prefers. Addresses competitor feedback about favoriting
    exercises not helping with AI selection.
    """
    logger.info(f"Getting favorite exercises for user: {user_id}")
    try:
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()

        # Verify user exists
        user = db.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # Get favorites
        result = db.client.table("favorite_exercises").select("*").eq(
            "user_id", user_id
        ).order("added_at", desc=True).execute()

        favorites = []
        for row in result.data:
            favorites.append(FavoriteExercise(
                id=row["id"],
                user_id=row["user_id"],
                exercise_name=row["exercise_name"],
                exercise_id=row.get("exercise_id"),
                added_at=row["added_at"],
            ))

        logger.info(f"Found {len(favorites)} favorite exercises for user {user_id}")
        return favorites

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get favorite exercises: {e}", exc_info=True)
        raise safe_internal_error(e, "users")


@router.post("/{user_id}/favorite-exercises", response_model=FavoriteExercise)
async def add_favorite_exercise(user_id: str, request: FavoriteExerciseRequest,
    current_user: dict = Depends(get_current_user),
):
    """Add an exercise to user's favorites.

    Favorited exercises get a 50% boost in similarity score during
    workout generation, making them more likely to be selected.
    """
    logger.info(f"Adding favorite exercise for user {user_id}: {request.exercise_name}")
    try:
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()

        # Verify user exists
        user = db.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # Resolve to the canonical library row (case-insensitive) so the
        # favorite carries a real exercise_id instead of a name-only entry
        # the generator can never match (see rows 187/233).
        resolved_id, resolved_name = _resolve_canonical_exercise(
            db, request.exercise_name, request.exercise_id
        )

        # Check if already favorited
        existing = db.client.table("favorite_exercises").select("id").eq(
            "user_id", user_id
        ).eq("exercise_name", resolved_name).execute()

        if existing.data:
            raise HTTPException(
                status_code=400,
                detail="Exercise is already in favorites"
            )

        # Add to favorites
        result = db.client.table("favorite_exercises").insert({
            "user_id": user_id,
            "exercise_name": resolved_name,
            "exercise_id": resolved_id,
        }).execute()

        if not result.data:
            raise safe_internal_error(ValueError("Failed to add favorite"), "users")

        row = result.data[0]
        logger.info(f"Added favorite exercise: {request.exercise_name} for user {user_id}")

        return FavoriteExercise(
            id=row["id"],
            user_id=row["user_id"],
            exercise_name=row["exercise_name"],
            exercise_id=row.get("exercise_id"),
            added_at=row["added_at"],
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to add favorite exercise: {e}", exc_info=True)
        raise safe_internal_error(e, "users")


@router.delete("/{user_id}/favorite-exercises/{exercise_name}")
async def remove_favorite_exercise(user_id: str, exercise_name: str,
    current_user: dict = Depends(get_current_user),
):
    """Remove an exercise from user's favorites.

    The exercise_name is URL-encoded, so spaces become %20.
    """
    # URL decode the exercise name
    from urllib.parse import unquote
    decoded_name = unquote(exercise_name)

    logger.info(f"Removing favorite exercise for user {user_id}: {decoded_name}")
    try:
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()

        # Verify user exists
        user = db.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # Delete the favorite
        result = db.client.table("favorite_exercises").delete().eq(
            "user_id", user_id
        ).eq("exercise_name", decoded_name).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Favorite not found")

        logger.info(f"Removed favorite exercise: {decoded_name} for user {user_id}")

        return {"message": "Favorite removed successfully", "exercise_name": decoded_name}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to remove favorite exercise: {e}", exc_info=True)
        raise safe_internal_error(e, "users")


# =============================================================================
# EXERCISE QUEUE ENDPOINTS
# =============================================================================


@router.get("/{user_id}/exercise-queue", response_model=List[QueuedExercise])
async def get_exercise_queue(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Get all queued exercises for a user.

    Returns active (not expired, not used) exercises, PLUS spent exercises
    (`used_at` set) whose destination workout hasn't happened yet — the
    "added to upcoming" set (row 280). An item whose destination workout is
    already completed (or no longer resolvable) is dropped entirely rather
    than lingering as history.
    """
    logger.info(f"Getting exercise queue for user: {user_id}")
    try:
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()

        # Verify user exists
        user = db.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # Get active queue items (not expired, not used)
        from datetime import datetime
        now = datetime.now().isoformat()

        result = db.client.table("exercise_queue").select("*").eq(
            "user_id", user_id
        ).is_("used_at", "null").gte(
            "expires_at", now
        ).order("priority", desc=False).order("added_at", desc=False).execute()

        queue = []
        for row in result.data:
            queue.append(QueuedExercise(
                id=row["id"],
                user_id=row["user_id"],
                exercise_name=row["exercise_name"],
                exercise_id=row.get("exercise_id"),
                priority=row.get("priority", 0),
                target_muscle_group=row.get("target_muscle_group"),
                added_at=row["added_at"],
                expires_at=row["expires_at"],
                used_at=row.get("used_at"),
            ))

        # "Added to upcoming": spent items whose destination workout hasn't
        # happened yet, so the tab can show where each one actually landed
        # instead of either hiding it or leaving it rendered as pending.
        try:
            used_result = db.client.table("exercise_queue").select("*").eq(
                "user_id", user_id
            ).not_.is_("used_at", "null").not_.is_(
                "used_in_workout_id", "null"
            ).order("used_at", desc=True).limit(50).execute()
            used_rows = used_result.data or []
        except Exception as ue:
            logger.warning(f"Could not fetch spent queue items: {ue}")
            used_rows = []

        if used_rows:
            workout_ids = list({r["used_in_workout_id"] for r in used_rows})
            try:
                workouts_resp = db.client.table("workouts").select(
                    "id, name, scheduled_date, is_completed"
                ).in_("id", workout_ids).execute()
                workouts_by_id = {str(w["id"]): w for w in (workouts_resp.data or [])}
            except Exception as we:
                logger.warning(f"Could not resolve destination workouts: {we}")
                workouts_by_id = {}

            for row in used_rows:
                workout = workouts_by_id.get(str(row["used_in_workout_id"]))
                if not workout or workout.get("is_completed"):
                    continue
                queue.append(QueuedExercise(
                    id=row["id"],
                    user_id=row["user_id"],
                    exercise_name=row["exercise_name"],
                    exercise_id=row.get("exercise_id"),
                    priority=row.get("priority", 0),
                    target_muscle_group=row.get("target_muscle_group"),
                    added_at=row["added_at"],
                    expires_at=row["expires_at"],
                    used_at=row.get("used_at"),
                    used_in_workout_id=str(row["used_in_workout_id"]),
                    used_in_workout_name=workout.get("name"),
                    used_in_workout_date=workout.get("scheduled_date"),
                ))

        logger.info(f"Found {len(queue)} queued exercises for user {user_id}")
        return queue

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get exercise queue: {e}", exc_info=True)
        raise safe_internal_error(e, "users")


@router.post("/{user_id}/exercise-queue")
async def add_to_exercise_queue(user_id: str, request: QueueExerciseRequest,
    current_user: dict = Depends(get_current_user),
):
    """Add an exercise to user's workout queue.

    Queued exercises are included in the next matching workout.
    """
    logger.info(f"Adding to exercise queue for user {user_id}: {request.exercise_name}")
    try:
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()

        # Verify user exists
        user = db.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # Check if already queued
        existing = db.client.table("exercise_queue").select("id").eq(
            "user_id", user_id
        ).eq("exercise_name", request.exercise_name).is_("used_at", "null").execute()

        if existing.data:
            raise HTTPException(
                status_code=400,
                detail="Exercise is already in queue"
            )

        # Add to queue
        result = db.client.table("exercise_queue").insert({
            "user_id": user_id,
            "exercise_name": request.exercise_name,
            "exercise_id": request.exercise_id,
            "priority": request.priority or 0,
            "target_muscle_group": request.target_muscle_group,
        }).execute()

        if not result.data:
            raise safe_internal_error(ValueError("Failed to add to queue"), "users")

        row = result.data[0]
        logger.info(f"Added to queue: {request.exercise_name} for user {user_id}")

        # Inject queued exercise into next workout using rule-based engine
        from api.v1.workouts.preference_engine import inject_queued_exercise_into_next_workout
        engine_result = await inject_queued_exercise_into_next_workout(
            db, user_id, request.exercise_name, row["id"]
        )
        logger.info(f"Queue injection result: {engine_result.get('message', '')}")

        response = QueuedExercise(
            id=row["id"],
            user_id=row["user_id"],
            exercise_name=row["exercise_name"],
            exercise_id=row.get("exercise_id"),
            priority=row.get("priority", 0),
            target_muscle_group=row.get("target_muscle_group"),
            added_at=row["added_at"],
            expires_at=row["expires_at"],
            used_at=row.get("used_at"),
        )
        # Return as dict with injection details
        result = response.model_dump()
        result["changes"] = engine_result.get("changes", [])
        result["engine_message"] = engine_result.get("message", "")
        return result

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to add to exercise queue: {e}", exc_info=True)
        raise safe_internal_error(e, "users")


@router.put("/{user_id}/exercise-queue/{exercise_name}")
async def update_exercise_queue_item(user_id: str, exercise_name: str,
    request: QueueExerciseUpdateRequest,
    current_user: dict = Depends(get_current_user),
):
    """Update a queued exercise's priority or target muscle group."""
    from urllib.parse import unquote
    decoded_name = unquote(exercise_name)

    logger.info(f"Updating exercise queue item for user {user_id}: {decoded_name}")
    try:
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()

        # Build update data from non-None fields
        update_data = {}
        if request.priority is not None:
            update_data["priority"] = request.priority
        if request.target_muscle_group is not None:
            update_data["target_muscle_group"] = request.target_muscle_group

        if not update_data:
            raise HTTPException(status_code=400, detail="No fields to update")

        result = db.client.table("exercise_queue").update(update_data).eq(
            "user_id", user_id
        ).eq("exercise_name", decoded_name).is_("used_at", "null").execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Exercise not found in queue")

        row = result.data[0]
        logger.info(f"Updated queue item: {decoded_name} for user {user_id}")

        return QueuedExercise(
            id=row["id"],
            user_id=row["user_id"],
            exercise_name=row["exercise_name"],
            exercise_id=row.get("exercise_id"),
            priority=row.get("priority", 0),
            target_muscle_group=row.get("target_muscle_group"),
            added_at=row["added_at"],
            expires_at=row["expires_at"],
            used_at=row.get("used_at"),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update exercise queue item: {e}", exc_info=True)
        raise safe_internal_error(e, "users")


@router.delete("/{user_id}/exercise-queue/{exercise_name}")
async def remove_from_exercise_queue(user_id: str, exercise_name: str,
    current_user: dict = Depends(get_current_user),
):
    """Remove an exercise from user's workout queue."""
    from urllib.parse import unquote
    decoded_name = unquote(exercise_name)

    logger.info(f"Removing from exercise queue for user {user_id}: {decoded_name}")
    try:
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()

        # Verify user exists
        user = db.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # Check whether this queue entry was already consumed by the workout
        # generator BEFORE deleting — the client's "won't be included in your
        # next workout" confirmation can only be true for a row that hasn't
        # been used yet. Once `used_at` is set, the exercise has already been
        # written into a real workout and deleting this bookkeeping row does
        # not pull it back out, so the caller needs to know that happened.
        existing = db.client.table("exercise_queue").select(
            "used_at"
        ).eq("user_id", user_id).eq("exercise_name", decoded_name).execute()
        already_used = any(row.get("used_at") for row in (existing.data or []))

        # Delete from queue
        result = db.client.table("exercise_queue").delete().eq(
            "user_id", user_id
        ).eq("exercise_name", decoded_name).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Exercise not found in queue")

        logger.info(f"Removed from queue: {decoded_name} for user {user_id}")

        return {
            "message": "Removed from queue successfully",
            "exercise_name": decoded_name,
            "already_used": already_used,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to remove from exercise queue: {e}", exc_info=True)
        raise safe_internal_error(e, "users")
