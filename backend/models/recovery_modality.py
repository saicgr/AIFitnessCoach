"""Recovery-modality logging models (Gap 8).

Cold plunge / ice bath / contrast / massage / foam rolling / compression /
stretching. Sauna keeps its own model (models/sauna.py); this covers the rest.
"""
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

# Known modalities the API accepts. Open-ish: 'other' is the catch-all so we
# never 422 a legitimate recovery practice (feedback_no_hardcoded_enumerations).
RECOVERY_MODALITIES = {
    "cold_plunge",
    "ice_bath",
    "contrast",
    "massage",
    "foam_rolling",
    "compression",
    "stretching",
    "other",
}


class RecoveryModalityLogCreate(BaseModel):
    user_id: str = Field(..., max_length=100)
    modality: str = Field(..., max_length=40)
    duration_minutes: Optional[int] = Field(default=None, ge=1, le=240)
    temperature_c: Optional[float] = Field(default=None, ge=-10, le=120)
    notes: Optional[str] = Field(default=None, max_length=500)
    local_date: Optional[str] = Field(default=None, max_length=10)


class RecoveryModalityLog(BaseModel):
    id: str = Field(..., max_length=100)
    user_id: str = Field(..., max_length=100)
    modality: str = Field(..., max_length=40)
    duration_minutes: Optional[int] = None
    temperature_c: Optional[float] = None
    notes: Optional[str] = Field(default=None, max_length=500)
    logged_at: Optional[datetime] = None


class DailyRecoveryModalitySummary(BaseModel):
    date: str = Field(..., max_length=20)
    total_minutes: int = Field(..., ge=0)
    modalities: List[str] = Field(default_factory=list)
    entries: List[RecoveryModalityLog]
