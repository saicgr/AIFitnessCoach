"""Cook event models — cook-once-eat-many leftover tracking."""

from datetime import datetime
from enum import Enum
from typing import List, Optional

from pydantic import BaseModel, Field, model_validator


class StorageKind(str, Enum):
    FRIDGE = "fridge"      # default expiry +3 days
    FREEZER = "freezer"    # +30 days
    COUNTER = "counter"    # +1 day


# Default storage life used by service when caller doesn't pass expires_at
STORAGE_DEFAULT_LIFE_DAYS = {
    StorageKind.FRIDGE: 3,
    StorageKind.FREEZER: 30,
    StorageKind.COUNTER: 1,
}


class CookEventCreate(BaseModel):
    recipe_id: Optional[str] = None
    cooked_at: Optional[datetime] = None  # defaults to NOW server-side
    portions_made: float = Field(..., gt=0, le=200)
    portions_remaining: Optional[float] = Field(default=None, ge=0)
    storage: StorageKind = StorageKind.FRIDGE
    expires_at: Optional[datetime] = None
    notes: Optional[str] = Field(default=None, max_length=2000)

    @model_validator(mode="after")
    def _validate(self):
        if self.portions_remaining is not None and self.portions_remaining > self.portions_made:
            raise ValueError("portions_remaining cannot exceed portions_made")
        return self


class CookEventUpdate(BaseModel):
    portions_made: Optional[float] = Field(default=None, gt=0, le=200)
    portions_remaining: Optional[float] = Field(default=None, ge=0)
    storage: Optional[StorageKind] = None
    expires_at: Optional[datetime] = None
    notes: Optional[str] = None


class CookEvent(BaseModel):
    id: str
    user_id: str
    recipe_id: Optional[str] = None
    cooked_at: datetime
    portions_made: float
    portions_remaining: float
    storage: StorageKind
    expires_at: datetime
    notes: Optional[str] = None
    created_at: datetime
    updated_at: datetime


class ActiveCookEvent(BaseModel):
    """Cook event enriched with recipe display info for the leftovers carousel."""
    id: str
    recipe_id: Optional[str] = None
    recipe_name: Optional[str] = None
    recipe_image_url: Optional[str] = None
    cooked_at: datetime
    portions_remaining: float
    portions_made: float
    storage: StorageKind
    expires_at: datetime
    is_expired: bool = False
    is_expiring_soon: bool = False  # within 24h


class ActiveCookEventsResponse(BaseModel):
    items: List[ActiveCookEvent]
