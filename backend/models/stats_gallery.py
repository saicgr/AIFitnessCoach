"""
Stats Gallery Models

Pydantic models for shareable stats images.
"""
from datetime import date, datetime
from enum import Enum
from typing import Any, Optional
from pydantic import BaseModel, Field


class StatsTemplateType(str, Enum):
    """Types of shareable stats image templates."""
    OVERVIEW = "overview"  # Activity heatmap + key stats
    ACHIEVEMENTS = "achievements"  # Achievements & milestones
    PRS = "prs"  # Personal records summary


class StatsSnapshot(BaseModel):
    """Snapshot of stats data for the gallery image."""
    total_workouts: Optional[int] = None
    weekly_completed: Optional[int] = None
    weekly_goal: Optional[int] = None
    current_streak: Optional[int] = None
    longest_streak: Optional[int] = None
    total_time_minutes: Optional[int] = None
    total_volume_kg: Optional[float] = None
    total_calories: Optional[int] = None
    date_range_label: Optional[str] = None  # e.g., "Last 3 months"


class UploadStatsImageRequest(BaseModel):
    """Request to upload a stats gallery image."""
    template_type: StatsTemplateType = Field(..., description="Type of template used")
    image_base64: str = Field(..., description="Base64 encoded PNG image")
    stats_snapshot: StatsSnapshot = Field(..., description="Stats data snapshot")
    date_range_start: Optional[date] = Field(None, description="Start of date range shown")
    date_range_end: Optional[date] = Field(None, description="End of date range shown")
    prs_data: list[dict[str, Any]] = Field(default_factory=list, description="PRs for PRs template")
    achievements_data: list[dict[str, Any]] = Field(default_factory=list, description="Achievements for achievements template")


class StatsGalleryImage(BaseModel):
    """A saved stats gallery image."""
    id: str
    user_id: str
    image_url: str
    thumbnail_url: Optional[str] = None
    template_type: StatsTemplateType
    stats_snapshot: Optional[dict[str, Any]] = None
    date_range_start: Optional[date] = None
    date_range_end: Optional[date] = None
    prs_data: list[dict[str, Any]] = Field(default_factory=list)
    achievements_data: list[dict[str, Any]] = Field(default_factory=list)
    shared_to_feed: bool = False
    shared_externally: bool = False
    external_shares_count: int = 0
    created_at: datetime

    class Config:
        from_attributes = True


class StatsGalleryImageList(BaseModel):
    """Paginated list of stats gallery images."""
    images: list[StatsGalleryImage]
    total: int
    page: int
    page_size: int
    has_more: bool


class ShareStatsToFeedRequest(BaseModel):
    """Request to share a stats image to the social feed."""
    caption: Optional[str] = Field(None, max_length=500, description="Optional caption for the post")
    visibility: str = Field(default="friends", description="Post visibility: public, friends, private")


class ShareStatsToFeedResponse(BaseModel):
    """Response after sharing stats to feed."""
    success: bool
    activity_id: Optional[str] = None
    message: str


class UploadStatsImageResponse(BaseModel):
    """Response after uploading a stats image."""
    success: bool
    image: Optional[StatsGalleryImage] = None
    message: str


class DeleteStatsImageResponse(BaseModel):
    """Response after deleting a stats image."""
    success: bool
    message: str
