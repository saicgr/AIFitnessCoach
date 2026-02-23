"""
Feature Voting API endpoints (Robinhood-style).

ENDPOINTS:
- GET  /api/v1/features/list - Get all feature requests with voting status
- POST /api/v1/features/create - Create a new feature request
- POST /api/v1/features/vote - Toggle vote for a feature
- GET  /api/v1/features/{feature_id} - Get feature details
- GET  /api/v1/features/user/{user_id}/remaining - Get remaining submissions for user

RATE LIMITS:
- /create: 10 requests/hour (prevent spam)
- /vote: 100 requests/hour
- Other endpoints: default global limit
"""
from datetime import datetime
from fastapi import APIRouter, HTTPException, Request, Depends
from typing import Optional, List
from pydantic import BaseModel

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.rate_limiter import limiter
from core.activity_logger import log_user_activity, log_user_error
from core.auth import get_current_user
from core.exceptions import safe_internal_error

router = APIRouter(prefix="/features", tags=["features"])
logger = get_logger(__name__)


# ===================================
# Pydantic Models
# ===================================

class FeatureRequestResponse(BaseModel):
    """Response model for a feature request."""
    id: str
    title: str
    description: str
    category: str
    status: str
    vote_count: int
    release_date: Optional[datetime]
    user_has_voted: bool
    created_at: datetime
    created_by: Optional[str]


class CreateFeatureRequest(BaseModel):
    """Request body for creating a feature."""
    title: str
    description: str
    category: str
    user_id: str


class VoteRequest(BaseModel):
    """Request body for voting."""
    feature_id: str
    user_id: str


# ===================================
# Helper Functions
# ===================================

def row_to_feature_response(
    row: dict,
    user_id: Optional[str] = None,
    client=None
) -> FeatureRequestResponse:
    """Convert database row to FeatureRequestResponse."""

    # Check if user has voted for this feature
    user_has_voted = False
    if user_id and client:
        try:
            vote_result = client.table("feature_votes").select("id").eq(
                "user_id", user_id
            ).eq("feature_id", row["id"]).execute()
            user_has_voted = len(vote_result.data) > 0
        except Exception as e:
            logger.error(f"Error checking user vote: {e}")

    return FeatureRequestResponse(
        id=row["id"],
        title=row["title"],
        description=row["description"],
        category=row["category"],
        status=row["status"],
        vote_count=row.get("vote_count", 0),
        release_date=row.get("release_date"),
        user_has_voted=user_has_voted,
        created_at=row["created_at"],
        created_by=row.get("created_by")
    )


# ===================================
# Endpoints
# ===================================

@router.get("/list")
async def get_feature_requests(
    status: Optional[str] = None,
    user_id: Optional[str] = None,
    current_user: dict = Depends(get_current_user),
) -> List[FeatureRequestResponse]:
    """
    Get all feature requests with voting status.

    Args:
        status: Filter by status (voting, planned, in_progress, released)
        user_id: User ID to check if they've voted

    Returns:
        List of feature requests sorted by vote count
    """
    try:
        db = get_supabase_db()
        client = db.client

        # Build query
        query = client.table("feature_requests").select("*")

        if status:
            query = query.eq("status", status)

        # Order by vote count (highest first), then by created_at (newest first)
        query = query.order("vote_count", desc=True).order("created_at", desc=True)

        result = query.execute()

        if not result.data:
            return []

        # Convert to response models
        features = [
            row_to_feature_response(row, user_id, client)
            for row in result.data
        ]

        logger.info(f"Fetched {len(features)} feature requests (status={status})")
        return features

    except Exception as e:
        logger.error(f"Error fetching feature requests: {e}")
        raise safe_internal_error(e, "features")


@router.post("/create", status_code=201)
@limiter.limit("10/hour")
async def create_feature_request(
    request: Request,
    feature: CreateFeatureRequest,
    current_user: dict = Depends(get_current_user),
) -> FeatureRequestResponse:
    """
    Create a new feature request.

    Limit: 2 total suggestions per user (enforced by database trigger).

    Args:
        feature: Feature request details

    Returns:
        Created feature request

    Raises:
        HTTPException: If user has reached submission limit or other error
    """
    if str(current_user["id"]) != str(feature.user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    try:
        db = get_supabase_db()
        client = db.client

        # Validate category
        valid_categories = ['workout', 'social', 'analytics', 'nutrition',
                          'coaching', 'ui_ux', 'integration', 'other']
        if feature.category not in valid_categories:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid category. Must be one of: {', '.join(valid_categories)}"
            )

        # Check current submission count (database trigger will also enforce this)
        count_result = client.table("feature_requests").select(
            "id", count="exact"
        ).eq("created_by", feature.user_id).execute()

        current_count = count_result.count or 0
        if current_count >= 2:
            raise HTTPException(
                status_code=429,
                detail="You have reached the maximum of 2 feature suggestions. Vote on existing features instead!"
            )

        # Insert feature request
        insert_result = client.table("feature_requests").insert({
            "title": feature.title,
            "description": feature.description,
            "category": feature.category,
            "created_by": feature.user_id,
            "status": "voting",
            "vote_count": 0
        }).execute()

        if not insert_result.data:
            raise HTTPException(status_code=500, detail="Failed to create feature request")

        created_feature = insert_result.data[0]

        logger.info(f"Created feature request: {created_feature['id']} by user {feature.user_id}")

        # Log feature creation
        await log_user_activity(
            user_id=feature.user_id,
            action="feature_created",
            endpoint="/api/v1/features/create",
            message=f"Created feature request: {feature.title}",
            metadata={
                "feature_id": created_feature['id'],
                "category": feature.category,
                "title": feature.title,
            },
            status_code=200
        )

        return row_to_feature_response(created_feature, feature.user_id, client)

    except HTTPException:
        raise
    except Exception as e:
        error_msg = str(e)
        # Check if it's the database trigger error
        if "maximum of 2 feature suggestions" in error_msg:
            raise HTTPException(
                status_code=429,
                detail="You have reached the maximum of 2 feature suggestions"
            )
        logger.error(f"Error creating feature request: {e}")
        await log_user_error(
            user_id=feature.user_id,
            action="feature_created",
            error=e,
            endpoint="/api/v1/features/create",
            status_code=500
        )
        raise safe_internal_error(e, "features")


@router.post("/vote")
@limiter.limit("100/hour")
async def vote_for_feature(request: Request, vote: VoteRequest, current_user: dict = Depends(get_current_user)):
    """
    Toggle vote for a feature (vote if not voted, unvote if already voted).

    Args:
        vote: Vote request with feature_id and user_id

    Returns:
        Action taken and updated vote count
    """
    if str(current_user["id"]) != str(vote.user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    try:
        db = get_supabase_db()
        client = db.client

        # Check if user has already voted
        existing_vote = client.table("feature_votes").select("id").eq(
            "user_id", vote.user_id
        ).eq("feature_id", vote.feature_id).execute()

        if existing_vote.data:
            # User already voted - remove vote (unvote)
            vote_id = existing_vote.data[0]["id"]
            client.table("feature_votes").delete().eq("id", vote_id).execute()

            action = "unvoted"
            logger.info(f"User {vote.user_id} unvoted for feature {vote.feature_id}")
        else:
            # User hasn't voted - add vote
            client.table("feature_votes").insert({
                "user_id": vote.user_id,
                "feature_id": vote.feature_id
            }).execute()

            action = "voted"
            logger.info(f"User {vote.user_id} voted for feature {vote.feature_id}")

        # Get updated vote count
        feature = client.table("feature_requests").select("vote_count").eq(
            "id", vote.feature_id
        ).single().execute()

        vote_count = feature.data.get("vote_count", 0) if feature.data else 0

        # Log vote action
        await log_user_activity(
            user_id=vote.user_id,
            action="feature_vote",
            endpoint="/api/v1/features/vote",
            message=f"{action.capitalize()} for feature {vote.feature_id}",
            metadata={
                "feature_id": vote.feature_id,
                "action": action,
                "new_vote_count": vote_count,
            },
            status_code=200
        )

        return {
            "action": action,
            "vote_count": vote_count
        }

    except Exception as e:
        logger.error(f"Error toggling vote: {e}")
        await log_user_error(
            user_id=vote.user_id,
            action="feature_vote",
            error=e,
            endpoint="/api/v1/features/vote",
            metadata={"feature_id": vote.feature_id},
            status_code=500
        )
        raise safe_internal_error(e, "features")


@router.get("/{feature_id}")
async def get_feature_details(feature_id: str, user_id: Optional[str] = None, current_user: dict = Depends(get_current_user)) -> FeatureRequestResponse:
    """
    Get detailed information about a specific feature.

    Args:
        feature_id: Feature request ID
        user_id: Optional user ID to check if they've voted

    Returns:
        Feature request details
    """
    try:
        db = get_supabase_db()
        client = db.client

        result = client.table("feature_requests").select("*").eq("id", feature_id).single().execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Feature request not found")

        return row_to_feature_response(result.data, user_id, client)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching feature {feature_id}: {e}")
        raise safe_internal_error(e, "features")


@router.get("/user/{user_id}/remaining")
async def get_remaining_submissions(user_id: str, current_user: dict = Depends(get_current_user)):
    """
    Get number of remaining feature submissions for a user.

    Args:
        user_id: User ID

    Returns:
        Remaining submissions count and total limit
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    try:
        db = get_supabase_db()
        client = db.client

        result = client.table("feature_requests").select(
            "id", count="exact"
        ).eq("created_by", user_id).execute()

        current_count = result.count or 0
        remaining = max(0, 2 - current_count)

        return {
            "used": current_count,
            "remaining": remaining,
            "total_limit": 2
        }

    except Exception as e:
        logger.error(f"Error checking remaining submissions for user {user_id}: {e}")
        raise safe_internal_error(e, "features")
