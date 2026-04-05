"""Pydantic models for cardio."""
from datetime import datetime, date
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any


class HRZoneResponse(BaseModel):
    """Heart rate zone with BPM ranges and metadata."""
    min: int = Field(..., description="Minimum heart rate for this zone in BPM")
    max: int = Field(..., description="Maximum heart rate for this zone in BPM")
    name: str = Field(..., description="Zone name (e.g., 'Recovery', 'Aerobic Base')")
    benefit: str = Field(..., description="Training benefit of this zone")
    color: str = Field(..., description="Hex color code for UI display")


class HRZonesResponse(BaseModel):
    """Complete heart rate zones response."""
    user_id: str
    max_hr: int = Field(..., description="Maximum heart rate used for calculation")
    resting_hr: Optional[int] = Field(None, description="Resting heart rate if provided")
    method: str = Field(..., description="Calculation method used: 'tanaka', 'traditional', or 'karvonen'")
    zone1_recovery: HRZoneResponse
    zone2_aerobic: HRZoneResponse
    zone3_tempo: HRZoneResponse
    zone4_threshold: HRZoneResponse
    zone5_max: HRZoneResponse
    calculated_at: datetime


class CardioMetricsResponse(BaseModel):
    """Full cardio metrics response including VO2 max and fitness age."""
    user_id: str
    max_hr: int = Field(..., description="Maximum heart rate in BPM")
    resting_hr: Optional[int] = Field(None, description="Resting heart rate in BPM")
    vo2_max_estimate: Optional[float] = Field(None, description="Estimated VO2 max in ml/kg/min")
    fitness_age: Optional[int] = Field(None, description="Calculated fitness age based on VO2 max")
    actual_age: int = Field(..., description="User's chronological age")
    source: str = Field(..., description="Data source: 'calculated', 'measured', or 'health_kit'")
    hr_zones: Dict[str, HRZoneResponse]
    calculated_at: datetime


class SaveCardioMetricsRequest(BaseModel):
    """Request to save measured cardio metrics."""
    user_id: str
    max_hr: Optional[int] = Field(None, ge=100, le=220, description="Measured max heart rate")
    resting_hr: Optional[int] = Field(None, ge=30, le=100, description="Resting heart rate")
    vo2_max_measured: Optional[float] = Field(None, ge=10, le=100, description="Measured VO2 max")
    source: str = Field("manual", description="Source of data: 'manual', 'health_kit', 'fitness_test'")


class CardioMetricsHistoryEntry(BaseModel):
    """Single cardio metrics history entry."""
    id: str
    max_hr: Optional[int]
    resting_hr: Optional[int]
    vo2_max_estimate: Optional[float]
    fitness_age: Optional[int]
    source: str
    measured_at: datetime


class CardioMetricsHistoryResponse(BaseModel):
    """Cardio metrics history response."""
    user_id: str
    entries: List[CardioMetricsHistoryEntry]
    trend: str = Field(..., description="Trend direction: 'improving', 'maintaining', 'declining'")
    avg_resting_hr_30d: Optional[float] = Field(None, description="Average resting HR over 30 days")


# ============================================================================
# HR Zones Endpoints
# ============================================================================

