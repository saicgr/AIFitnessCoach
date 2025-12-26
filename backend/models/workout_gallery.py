"""
Workout Gallery Models

Pydantic models for shareable workout recap images.
"""
from datetime import datetime
from enum import Enum
from typing import Any, Optional
from pydantic import BaseModel, Field


class TemplateType(str, Enum):
    """Types of shareable image templates."""
    STATS = "stats"
    PRS = "prs"
    PHOTO_OVERLAY = "photo_overlay"
    MOTIVATIONAL = "motivational"


class WorkoutSnapshot(BaseModel):
    """Snapshot of workout data for the gallery image."""
    workout_name: Optional[str] = None
    duration_seconds: Optional[int] = None
    calories: Optional[int] = None
    total_volume_kg: Optional[float] = None
    total_sets: Optional[int] = None
    total_reps: Optional[int] = None
    exercises_count: Optional[int] = None


class UploadImageRequest(BaseModel):
    """Request to upload a workout gallery image."""
    workout_log_id: str = Field(..., description="ID of the workout log")
    template_type: TemplateType = Field(..., description="Type of template used")
    image_base64: str = Field(..., description="Base64 encoded PNG image")
    workout_snapshot: WorkoutSnapshot = Field(..., description="Workout data snapshot")
    prs_data: list[dict[str, Any]] = Field(default_factory=list, description="PRs achieved in this workout")
    achievements_data: list[dict[str, Any]] = Field(default_factory=list, description="Achievements earned")
    user_photo_base64: Optional[str] = Field(None, description="Optional user photo for photo_overlay template")


class WorkoutGalleryImage(BaseModel):
    """A saved workout gallery image."""
    id: str
    user_id: str
    workout_log_id: Optional[str] = None
    image_url: str
    thumbnail_url: Optional[str] = None
    template_type: TemplateType
    workout_name: Optional[str] = None
    duration_seconds: Optional[int] = None
    calories: Optional[int] = None
    total_volume_kg: Optional[float] = None
    total_sets: Optional[int] = None
    total_reps: Optional[int] = None
    exercises_count: Optional[int] = None
    user_photo_url: Optional[str] = None
    prs_data: list[dict[str, Any]] = Field(default_factory=list)
    achievements_data: list[dict[str, Any]] = Field(default_factory=list)
    shared_to_feed: bool = False
    shared_externally: bool = False
    external_shares_count: int = 0
    created_at: datetime

    class Config:
        from_attributes = True


class WorkoutGalleryImageList(BaseModel):
    """Paginated list of gallery images."""
    images: list[WorkoutGalleryImage]
    total: int
    page: int
    page_size: int
    has_more: bool


class ShareToFeedRequest(BaseModel):
    """Request to share a gallery image to the social feed."""
    caption: Optional[str] = Field(None, max_length=500, description="Optional caption for the post")
    visibility: str = Field(default="friends", description="Post visibility: public, friends, private")


class ShareToFeedResponse(BaseModel):
    """Response after sharing to feed."""
    success: bool
    activity_id: Optional[str] = None
    message: str


class UploadImageResponse(BaseModel):
    """Response after uploading an image."""
    success: bool
    image: Optional[WorkoutGalleryImage] = None
    message: str


class DeleteImageResponse(BaseModel):
    """Response after deleting an image."""
    success: bool
    message: str
