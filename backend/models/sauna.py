from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

class SaunaLogCreate(BaseModel):
    user_id: str = Field(..., max_length=100)
    workout_id: Optional[str] = Field(default=None, max_length=100)
    duration_minutes: int = Field(..., ge=1, le=240)
    notes: Optional[str] = Field(default=None, max_length=500)
    local_date: Optional[str] = Field(default=None, max_length=10)

class SaunaLog(BaseModel):
    id: str = Field(..., max_length=100)
    user_id: str = Field(..., max_length=100)
    workout_id: Optional[str] = Field(default=None, max_length=100)
    duration_minutes: int = Field(..., ge=1, le=240)
    estimated_calories: Optional[int] = None
    notes: Optional[str] = Field(default=None, max_length=500)
    logged_at: Optional[datetime] = None

class DailySaunaSummary(BaseModel):
    date: str = Field(..., max_length=20)
    total_minutes: int = Field(..., ge=0)
    total_calories: int = Field(..., ge=0)
    entries: List[SaunaLog]
