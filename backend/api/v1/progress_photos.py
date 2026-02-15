"""
Progress Photos API Endpoints
=============================
Handles progress photo uploads, retrieval, and before/after comparisons.
"""

import uuid
import boto3
from botocore.config import Config as BotoConfig
from datetime import datetime
from typing import Optional, List
from fastapi import APIRouter, HTTPException, UploadFile, File, Form, Query
from pydantic import BaseModel, Field

from core.db import get_supabase_db
from core.config import get_settings

PRESIGNED_URL_EXPIRATION = 3600  # 1 hour

router = APIRouter()


# ============================================================================
# Pydantic Models
# ============================================================================

class ProgressPhotoResponse(BaseModel):
    id: str
    user_id: str
    photo_url: str
    thumbnail_url: Optional[str] = None
    view_type: str  # 'front', 'side_left', 'side_right', 'back'
    taken_at: datetime
    body_weight_kg: Optional[float] = None
    notes: Optional[str] = None
    measurement_id: Optional[str] = None
    is_comparison_ready: bool = True
    visibility: str = 'private'
    created_at: datetime = Field(default_factory=datetime.utcnow)


class ProgressPhotoCreate(BaseModel):
    user_id: str
    view_type: str  # 'front', 'side_left', 'side_right', 'back'
    taken_at: Optional[datetime] = None
    body_weight_kg: Optional[float] = None
    notes: Optional[str] = None
    measurement_id: Optional[str] = None
    visibility: str = 'private'


class ProgressPhotoUpdate(BaseModel):
    notes: Optional[str] = None
    body_weight_kg: Optional[float] = None
    is_comparison_ready: Optional[bool] = None
    visibility: Optional[str] = None


class PhotoComparisonResponse(BaseModel):
    id: str
    user_id: str
    before_photo: ProgressPhotoResponse
    after_photo: ProgressPhotoResponse
    title: Optional[str] = None
    description: Optional[str] = None
    weight_change_kg: Optional[float] = None
    days_between: Optional[int] = None
    visibility: str = 'private'
    created_at: datetime


class PhotoComparisonCreate(BaseModel):
    user_id: str
    before_photo_id: str
    after_photo_id: str
    title: Optional[str] = None
    description: Optional[str] = None


class PhotoStatsResponse(BaseModel):
    user_id: str
    total_photos: int
    view_types_captured: int
    first_photo_date: Optional[datetime] = None
    latest_photo_date: Optional[datetime] = None
    days_with_photos: int


# ============================================================================
# S3 Upload Helper
# ============================================================================

def get_s3_client():
    """Get S3 client with configured credentials and s3v4 signatures."""
    settings = get_settings()
    return boto3.client(
        's3',
        aws_access_key_id=settings.aws_access_key_id,
        aws_secret_access_key=settings.aws_secret_access_key,
        region_name=settings.aws_default_region,
        config=BotoConfig(signature_version='s3v4'),
    )


def _presign_photo(photo: dict) -> dict:
    """Replace photo_url with a presigned S3 URL using the storage_key."""
    storage_key = photo.get('storage_key')
    if storage_key:
        try:
            settings = get_settings()
            s3 = get_s3_client()
            photo['photo_url'] = s3.generate_presigned_url(
                'get_object',
                Params={'Bucket': settings.s3_bucket_name, 'Key': storage_key},
                ExpiresIn=PRESIGNED_URL_EXPIRATION,
            )
        except Exception:
            pass  # keep original URL as fallback
    return photo


async def upload_photo_to_s3(
    file: UploadFile,
    user_id: str,
    view_type: str,
) -> tuple[str, str]:
    """
    Upload photo to S3 and return (photo_url, storage_key).
    """
    # Generate unique key
    timestamp = datetime.utcnow().strftime('%Y%m%d_%H%M%S')
    ext = file.filename.split('.')[-1] if file.filename else 'jpg'
    storage_key = f"progress_photos/{user_id}/{view_type}/{timestamp}_{uuid.uuid4().hex[:8]}.{ext}"

    # Upload to S3
    s3 = get_s3_client()
    contents = await file.read()

    settings = get_settings()
    s3.put_object(
        Bucket=settings.s3_bucket_name,
        Key=storage_key,
        Body=contents,
        ContentType=file.content_type or 'image/jpeg',
    )

    # Generate URL
    photo_url = f"https://{settings.s3_bucket_name}.s3.{settings.aws_default_region}.amazonaws.com/{storage_key}"

    return photo_url, storage_key


async def delete_photo_from_s3(storage_key: str) -> bool:
    """Delete photo from S3."""
    try:
        settings = get_settings()
        s3 = get_s3_client()
        s3.delete_object(
            Bucket=settings.s3_bucket_name,
            Key=storage_key,
        )
        return True
    except Exception as e:
        print(f"Error deleting from S3: {e}")
        return False


# ============================================================================
# Progress Photo Endpoints
# ============================================================================

@router.post("/photos", response_model=ProgressPhotoResponse)
async def upload_progress_photo(
    user_id: str = Form(...),
    view_type: str = Form(...),
    file: UploadFile = File(...),
    taken_at: Optional[str] = Form(None),
    body_weight_kg: Optional[float] = Form(None),
    notes: Optional[str] = Form(None),
    measurement_id: Optional[str] = Form(None),
    visibility: str = Form('private'),
):
    """
    Upload a new progress photo.

    - **user_id**: User ID
    - **view_type**: One of 'front', 'side_left', 'side_right', 'back'
    - **file**: Image file (JPEG, PNG)
    - **taken_at**: When the photo was taken (ISO format, optional)
    - **body_weight_kg**: Weight at time of photo (optional)
    - **notes**: Any notes about the photo
    - **visibility**: 'private', 'shared', or 'public'
    """
    db = get_supabase_db()

    # Validate view type
    valid_view_types = ['front', 'side_left', 'side_right', 'back']
    if view_type not in valid_view_types:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid view_type. Must be one of: {valid_view_types}"
        )

    # Validate file type
    allowed_types = ['image/jpeg', 'image/png', 'image/webp']
    if file.content_type not in allowed_types:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid file type. Must be one of: {allowed_types}"
        )

    try:
        # Upload to S3
        photo_url, storage_key = await upload_photo_to_s3(file, user_id, view_type)

        # Parse taken_at
        photo_taken_at = datetime.fromisoformat(taken_at) if taken_at else datetime.utcnow()

        # Insert into database
        result = db.client.table('progress_photos').insert({
            'user_id': user_id,
            'photo_url': photo_url,
            'storage_key': storage_key,
            'view_type': view_type,
            'taken_at': photo_taken_at.isoformat(),
            'body_weight_kg': body_weight_kg,
            'notes': notes,
            'measurement_id': measurement_id,
            'visibility': visibility,
        }).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to save photo record")

        return ProgressPhotoResponse(**_presign_photo(result.data[0]))

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error uploading photo: {str(e)}")


@router.get("/photos/{user_id}", response_model=List[ProgressPhotoResponse])
async def get_progress_photos(
    user_id: str,
    view_type: Optional[str] = Query(None, description="Filter by view type"),
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    from_date: Optional[str] = Query(None, description="Start date (YYYY-MM-DD)"),
    to_date: Optional[str] = Query(None, description="End date (YYYY-MM-DD)"),
):
    """
    Get progress photos for a user.

    - **user_id**: User ID
    - **view_type**: Optional filter by view type
    - **limit**: Maximum number of photos to return
    - **offset**: Number of photos to skip
    - **from_date**: Filter photos from this date
    - **to_date**: Filter photos until this date
    """
    db = get_supabase_db()

    try:
        query = db.client.table('progress_photos') \
            .select('*') \
            .eq('user_id', user_id) \
            .order('taken_at', desc=True) \
            .limit(limit) \
            .offset(offset)

        if view_type:
            query = query.eq('view_type', view_type)

        if from_date:
            query = query.gte('taken_at', from_date)

        if to_date:
            query = query.lte('taken_at', to_date)

        result = query.execute()

        return [ProgressPhotoResponse(**_presign_photo(photo)) for photo in result.data]

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching photos: {str(e)}")


@router.get("/photos/{user_id}/latest", response_model=dict)
async def get_latest_photos_by_view(user_id: str):
    """
    Get the most recent photo for each view type.

    Returns a dict with view_type as keys and photo objects as values.
    """
    db = get_supabase_db()

    try:
        # Get latest photo for each view type
        result = db.client.rpc(
            'get_latest_progress_photos',
            {'p_user_id': user_id}
        ).execute()

        # If RPC doesn't exist, fall back to manual query
        if not result.data:
            photos_by_view = {}
            for view_type in ['front', 'side_left', 'side_right', 'back']:
                photo_result = db.client.table('progress_photos') \
                    .select('*') \
                    .eq('user_id', user_id) \
                    .eq('view_type', view_type) \
                    .order('taken_at', desc=True) \
                    .limit(1) \
                    .execute()

                if photo_result.data:
                    photos_by_view[view_type] = ProgressPhotoResponse(**_presign_photo(photo_result.data[0]))

            return photos_by_view

        # Parse RPC result
        photos_by_view = {}
        for photo in result.data:
            photos_by_view[photo['view_type']] = ProgressPhotoResponse(**_presign_photo(photo))

        return photos_by_view

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching latest photos: {str(e)}")


@router.get("/photos/{user_id}/{photo_id}", response_model=ProgressPhotoResponse)
async def get_progress_photo(user_id: str, photo_id: str):
    """Get a specific progress photo."""
    db = get_supabase_db()

    try:
        result = db.client.table('progress_photos') \
            .select('*') \
            .eq('id', photo_id) \
            .eq('user_id', user_id) \
            .maybe_single() \
            .execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Photo not found")

        return ProgressPhotoResponse(**_presign_photo(result.data))

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching photo: {str(e)}")


@router.put("/photos/{photo_id}", response_model=ProgressPhotoResponse)
async def update_progress_photo(
    photo_id: str,
    user_id: str = Query(...),
    update_data: ProgressPhotoUpdate = None,
):
    """Update a progress photo's metadata."""
    db = get_supabase_db()

    try:
        # Verify ownership
        existing = db.client.table('progress_photos') \
            .select('id') \
            .eq('id', photo_id) \
            .eq('user_id', user_id) \
            .maybe_single() \
            .execute()

        if not existing.data:
            raise HTTPException(status_code=404, detail="Photo not found")

        # Update
        update_dict = update_data.dict(exclude_unset=True) if update_data else {}
        if not update_dict:
            raise HTTPException(status_code=400, detail="No update data provided")

        result = db.client.table('progress_photos') \
            .update(update_dict) \
            .eq('id', photo_id) \
            .execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to update photo")

        return ProgressPhotoResponse(**_presign_photo(result.data[0]))

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error updating photo: {str(e)}")


@router.delete("/photos/{photo_id}")
async def delete_progress_photo(
    photo_id: str,
    user_id: str = Query(...),
):
    """Delete a progress photo."""
    db = get_supabase_db()

    try:
        # Get photo to delete from S3
        photo = db.client.table('progress_photos') \
            .select('storage_key') \
            .eq('id', photo_id) \
            .eq('user_id', user_id) \
            .maybe_single() \
            .execute()

        if not photo.data:
            raise HTTPException(status_code=404, detail="Photo not found")

        # Delete from S3
        storage_key = photo.data.get('storage_key')
        if storage_key:
            await delete_photo_from_s3(storage_key)

        # Delete from database
        db.client.table('progress_photos') \
            .delete() \
            .eq('id', photo_id) \
            .execute()

        return {"status": "deleted", "photo_id": photo_id}

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error deleting photo: {str(e)}")


# ============================================================================
# Photo Comparison Endpoints
# ============================================================================

@router.post("/comparisons", response_model=PhotoComparisonResponse)
async def create_photo_comparison(data: PhotoComparisonCreate):
    """
    Create a before/after photo comparison.

    - **before_photo_id**: ID of the "before" photo
    - **after_photo_id**: ID of the "after" photo
    - **title**: Optional title for the comparison
    - **description**: Optional description
    """
    db = get_supabase_db()

    try:
        # Get both photos
        before_photo = db.client.table('progress_photos') \
            .select('*') \
            .eq('id', data.before_photo_id) \
            .eq('user_id', data.user_id) \
            .maybe_single() \
            .execute()

        after_photo = db.client.table('progress_photos') \
            .select('*') \
            .eq('id', data.after_photo_id) \
            .eq('user_id', data.user_id) \
            .maybe_single() \
            .execute()

        if not before_photo.data or not after_photo.data:
            raise HTTPException(status_code=404, detail="One or both photos not found")

        # Calculate stats
        before_date = datetime.fromisoformat(before_photo.data['taken_at'].replace('Z', '+00:00'))
        after_date = datetime.fromisoformat(after_photo.data['taken_at'].replace('Z', '+00:00'))
        days_between = (after_date - before_date).days

        weight_change = None
        if before_photo.data.get('body_weight_kg') and after_photo.data.get('body_weight_kg'):
            weight_change = after_photo.data['body_weight_kg'] - before_photo.data['body_weight_kg']

        # Create comparison
        result = db.client.table('photo_comparisons').insert({
            'user_id': data.user_id,
            'before_photo_id': data.before_photo_id,
            'after_photo_id': data.after_photo_id,
            'title': data.title,
            'description': data.description,
            'weight_change_kg': weight_change,
            'days_between': days_between,
        }).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to create comparison")

        comparison = result.data[0]

        return PhotoComparisonResponse(
            id=comparison['id'],
            user_id=comparison['user_id'],
            before_photo=ProgressPhotoResponse(**_presign_photo(before_photo.data)),
            after_photo=ProgressPhotoResponse(**_presign_photo(after_photo.data)),
            title=comparison.get('title'),
            description=comparison.get('description'),
            weight_change_kg=comparison.get('weight_change_kg'),
            days_between=comparison.get('days_between'),
            visibility=comparison.get('visibility', 'private'),
            created_at=comparison['created_at'],
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error creating comparison: {str(e)}")


@router.get("/comparisons/{user_id}", response_model=List[PhotoComparisonResponse])
async def get_photo_comparisons(
    user_id: str,
    limit: int = Query(20, ge=1, le=50),
):
    """Get all photo comparisons for a user."""
    db = get_supabase_db()

    try:
        # Get comparisons with joined photo data
        result = db.client.table('photo_comparisons') \
            .select('*, before_photo:progress_photos!before_photo_id(*), after_photo:progress_photos!after_photo_id(*)') \
            .eq('user_id', user_id) \
            .order('created_at', desc=True) \
            .limit(limit) \
            .execute()

        comparisons = []
        for comp in result.data:
            comparisons.append(PhotoComparisonResponse(
                id=comp['id'],
                user_id=comp['user_id'],
                before_photo=ProgressPhotoResponse(**_presign_photo(comp['before_photo'])),
                after_photo=ProgressPhotoResponse(**_presign_photo(comp['after_photo'])),
                title=comp.get('title'),
                description=comp.get('description'),
                weight_change_kg=comp.get('weight_change_kg'),
                days_between=comp.get('days_between'),
                visibility=comp.get('visibility', 'private'),
                created_at=comp['created_at'],
            ))

        return comparisons

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching comparisons: {str(e)}")


@router.delete("/comparisons/{comparison_id}")
async def delete_photo_comparison(
    comparison_id: str,
    user_id: str = Query(...),
):
    """Delete a photo comparison (does not delete the photos themselves)."""
    db = get_supabase_db()

    try:
        result = db.client.table('photo_comparisons') \
            .delete() \
            .eq('id', comparison_id) \
            .eq('user_id', user_id) \
            .execute()

        return {"status": "deleted", "comparison_id": comparison_id}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error deleting comparison: {str(e)}")


# ============================================================================
# Stats Endpoint
# ============================================================================

@router.get("/stats/{user_id}", response_model=PhotoStatsResponse)
async def get_photo_stats(user_id: str):
    """Get photo statistics for a user."""
    db = get_supabase_db()

    try:
        # Get stats from view or calculate
        result = db.client.table('progress_photos') \
            .select('id, view_type, taken_at') \
            .eq('user_id', user_id) \
            .execute()

        if not result.data:
            return PhotoStatsResponse(
                user_id=user_id,
                total_photos=0,
                view_types_captured=0,
                first_photo_date=None,
                latest_photo_date=None,
                days_with_photos=0,
            )

        photos = result.data
        dates = [datetime.fromisoformat(p['taken_at'].replace('Z', '+00:00')) for p in photos]
        view_types = set(p['view_type'] for p in photos)
        unique_days = set(d.date() for d in dates)

        return PhotoStatsResponse(
            user_id=user_id,
            total_photos=len(photos),
            view_types_captured=len(view_types),
            first_photo_date=min(dates) if dates else None,
            latest_photo_date=max(dates) if dates else None,
            days_with_photos=len(unique_days),
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching stats: {str(e)}")
