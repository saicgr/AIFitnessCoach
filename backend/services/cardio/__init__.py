"""
Cardio services module - Heart rate zones and endurance training support.

This module provides:
- Heart rate zone calculations (Tanaka formula, Karvonen formula)
- VO2 max estimation
- Cardio workout generation support
"""
from services.cardio.hr_zones import (
    calculate_max_hr,
    calculate_hr_zones,
    calculate_age_from_dob,
    estimate_vo2_max,
    get_fitness_age,
    get_zone_for_heart_rate,
    get_cardio_metrics,
    CardioMetrics,
)

__all__ = [
    "calculate_max_hr",
    "calculate_hr_zones",
    "calculate_age_from_dob",
    "estimate_vo2_max",
    "get_fitness_age",
    "get_zone_for_heart_rate",
    "get_cardio_metrics",
    "CardioMetrics",
]
