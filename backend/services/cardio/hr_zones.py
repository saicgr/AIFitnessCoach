"""
Heart Rate Zone Calculations for Cardio/Endurance Training.

This module provides functions for calculating personalized heart rate training zones
using scientifically validated formulas:
- Tanaka formula (more accurate for trained individuals)
- Karvonen formula (personalized using heart rate reserve)

Training zones are essential for optimizing cardio workouts for specific goals:
- Zone 1 (Recovery): Active recovery, warm-up
- Zone 2 (Aerobic Base): Fat burning, endurance building
- Zone 3 (Tempo): Aerobic capacity improvement
- Zone 4 (Threshold): Lactate threshold, speed endurance
- Zone 5 (VO2 Max): Maximum performance, anaerobic power
"""
from typing import Dict, Optional, TypedDict
from datetime import date, datetime
from dataclasses import dataclass


class HRZone(TypedDict):
    """Heart rate zone definition."""
    min: int
    max: int
    name: str
    benefit: str
    color: str


class HRZonesResult(TypedDict):
    """Result of heart rate zone calculation."""
    zone1_recovery: HRZone
    zone2_aerobic: HRZone
    zone3_tempo: HRZone
    zone4_threshold: HRZone
    zone5_max: HRZone


@dataclass
class CardioMetrics:
    """User cardio fitness metrics."""
    max_hr: int
    resting_hr: Optional[int]
    hr_zones: HRZonesResult
    vo2_max_estimate: Optional[float]
    fitness_age: Optional[int]
    source: str = "calculated"


def calculate_age_from_dob(date_of_birth: date) -> int:
    """
    Calculate age from date of birth.

    Args:
        date_of_birth: User's date of birth

    Returns:
        Age in years
    """
    today = date.today()
    age = today.year - date_of_birth.year

    # Adjust if birthday hasn't occurred this year
    if (today.month, today.day) < (date_of_birth.month, date_of_birth.day):
        age -= 1

    return age


def calculate_max_hr(age: int, method: str = "tanaka") -> int:
    """
    Calculate maximum heart rate based on age.

    Two methods available:
    - Tanaka formula: 208 - 0.7 * age (more accurate for trained individuals)
    - Traditional: 220 - age

    Research shows the Tanaka formula (Tanaka et al., 2001) is more accurate
    across all age groups and fitness levels.

    Args:
        age: User's age in years
        method: Calculation method - "tanaka" (default) or "traditional"

    Returns:
        Estimated maximum heart rate in BPM

    Raises:
        ValueError: If age is invalid (< 1 or > 120)
    """
    if age < 1 or age > 120:
        raise ValueError(f"Invalid age: {age}. Must be between 1 and 120.")

    if method == "tanaka":
        return int(208 - 0.7 * age)
    elif method == "traditional":
        return 220 - age
    else:
        raise ValueError(f"Unknown method: {method}. Use 'tanaka' or 'traditional'.")


def calculate_hr_zones(
    max_hr: int,
    resting_hr: Optional[int] = None
) -> HRZonesResult:
    """
    Calculate 5 heart rate training zones.

    If resting_hr is provided, uses the Karvonen formula (heart rate reserve method)
    which is more personalized. Otherwise, uses percentage of max HR.

    Karvonen Formula:
        Target HR = ((Max HR - Resting HR) x %Intensity) + Resting HR

    The Karvonen formula is more accurate because it accounts for individual
    fitness levels (lower resting HR = better cardiovascular fitness).

    Args:
        max_hr: Maximum heart rate in BPM
        resting_hr: Resting heart rate in BPM (optional, for Karvonen formula)

    Returns:
        Dictionary containing 5 heart rate zones with min/max BPM and descriptions

    Raises:
        ValueError: If max_hr or resting_hr values are invalid
    """
    if max_hr < 100 or max_hr > 220:
        raise ValueError(f"Invalid max HR: {max_hr}. Expected 100-220 BPM.")

    if resting_hr is not None and (resting_hr < 30 or resting_hr > 100):
        raise ValueError(f"Invalid resting HR: {resting_hr}. Expected 30-100 BPM.")

    if resting_hr is not None:
        # Karvonen formula: Target HR = ((max HR - resting HR) x %Intensity) + resting HR
        hrr = max_hr - resting_hr  # Heart Rate Reserve

        return {
            "zone1_recovery": {
                "min": int(resting_hr + hrr * 0.50),
                "max": int(resting_hr + hrr * 0.60),
                "name": "Recovery",
                "benefit": "Active recovery, warm-up, cool-down",
                "color": "#22C55E"  # Green
            },
            "zone2_aerobic": {
                "min": int(resting_hr + hrr * 0.60),
                "max": int(resting_hr + hrr * 0.70),
                "name": "Aerobic Base",
                "benefit": "Fat burning, endurance building, base fitness",
                "color": "#06B6D4"  # Cyan
            },
            "zone3_tempo": {
                "min": int(resting_hr + hrr * 0.70),
                "max": int(resting_hr + hrr * 0.80),
                "name": "Tempo",
                "benefit": "Aerobic capacity improvement, moderate intensity",
                "color": "#F59E0B"  # Amber/Warning
            },
            "zone4_threshold": {
                "min": int(resting_hr + hrr * 0.80),
                "max": int(resting_hr + hrr * 0.90),
                "name": "Threshold",
                "benefit": "Lactate threshold, speed endurance, race pace",
                "color": "#F97316"  # Orange
            },
            "zone5_max": {
                "min": int(resting_hr + hrr * 0.90),
                "max": max_hr,
                "name": "VO2 Max",
                "benefit": "Maximum performance, anaerobic power, peak efforts",
                "color": "#EF4444"  # Red
            },
        }
    else:
        # Percentage of max HR (simpler but less personalized)
        return {
            "zone1_recovery": {
                "min": int(max_hr * 0.50),
                "max": int(max_hr * 0.60),
                "name": "Recovery",
                "benefit": "Active recovery, warm-up, cool-down",
                "color": "#22C55E"  # Green
            },
            "zone2_aerobic": {
                "min": int(max_hr * 0.60),
                "max": int(max_hr * 0.70),
                "name": "Aerobic Base",
                "benefit": "Fat burning, endurance building, base fitness",
                "color": "#06B6D4"  # Cyan
            },
            "zone3_tempo": {
                "min": int(max_hr * 0.70),
                "max": int(max_hr * 0.80),
                "name": "Tempo",
                "benefit": "Aerobic capacity improvement, moderate intensity",
                "color": "#F59E0B"  # Amber/Warning
            },
            "zone4_threshold": {
                "min": int(max_hr * 0.80),
                "max": int(max_hr * 0.90),
                "name": "Threshold",
                "benefit": "Lactate threshold, speed endurance, race pace",
                "color": "#F97316"  # Orange
            },
            "zone5_max": {
                "min": int(max_hr * 0.90),
                "max": max_hr,
                "name": "VO2 Max",
                "benefit": "Maximum performance, anaerobic power, peak efforts",
                "color": "#EF4444"  # Red
            },
        }


def estimate_vo2_max(
    resting_hr: int,
    age: int,
    gender: str = "male",
    weight_kg: Optional[float] = None
) -> float:
    """
    Estimate VO2 max from resting heart rate.

    Uses the Uth-Sorensen-Overgaard-Pedersen formula:
        VO2 max = 15.3 x (Max HR / Resting HR)

    This is a simplified estimation. For accurate VO2 max, a proper
    fitness test (e.g., Cooper test, shuttle run) is recommended.

    Args:
        resting_hr: Resting heart rate in BPM
        age: User's age in years
        gender: 'male' or 'female' (affects max HR estimation)
        weight_kg: Body weight in kg (optional, for refined estimates)

    Returns:
        Estimated VO2 max in ml/kg/min

    Note:
        Average VO2 max values:
        - Sedentary: 30-40 ml/kg/min
        - Active: 40-50 ml/kg/min
        - Athletic: 50-60 ml/kg/min
        - Elite: 60-80+ ml/kg/min
    """
    if resting_hr < 30 or resting_hr > 100:
        raise ValueError(f"Invalid resting HR: {resting_hr}. Expected 30-100 BPM.")

    max_hr = calculate_max_hr(age)

    # Uth-Sorensen formula
    vo2_max = 15.3 * (max_hr / resting_hr)

    # Apply gender adjustment (women typically have ~10-15% lower VO2 max)
    if gender.lower() == "female":
        vo2_max *= 0.90

    return round(vo2_max, 2)


def get_fitness_age(
    actual_age: int,
    vo2_max: float,
    gender: str = "male"
) -> int:
    """
    Calculate fitness age based on VO2 max.

    Fitness age represents the age of an average person with the same
    cardiovascular fitness level. A lower fitness age than actual age
    indicates above-average cardiovascular health.

    Based on research from the HUNT Fitness Study (Norwegian University of
    Science and Technology).

    Args:
        actual_age: User's chronological age
        vo2_max: Estimated or measured VO2 max
        gender: 'male' or 'female'

    Returns:
        Estimated fitness age in years

    Example:
        - A 40-year-old with VO2 max of 50 might have a fitness age of 30
        - A 30-year-old with VO2 max of 35 might have a fitness age of 45
    """
    # Average VO2 max values by age (simplified model)
    # These are approximate median values from population studies
    if gender.lower() == "male":
        # Men average VO2 max: ~45 at age 25, declining ~1% per year after 30
        baseline_vo2 = 45
        decline_rate = 0.5  # ml/kg/min per year after age 25
    else:
        # Women average VO2 max: ~38 at age 25, similar decline
        baseline_vo2 = 38
        decline_rate = 0.4

    # Calculate what age would have this VO2 max on average
    vo2_diff = baseline_vo2 - vo2_max
    age_adjustment = vo2_diff / decline_rate

    fitness_age = int(25 + age_adjustment)

    # Clamp to reasonable bounds
    fitness_age = max(18, min(fitness_age, 90))

    return fitness_age


def get_zone_for_heart_rate(
    current_hr: int,
    zones: HRZonesResult
) -> Optional[str]:
    """
    Determine which training zone a given heart rate falls into.

    Args:
        current_hr: Current heart rate in BPM
        zones: Calculated heart rate zones

    Returns:
        Zone key (e.g., "zone2_aerobic") or None if below Zone 1
    """
    for zone_key in ["zone5_max", "zone4_threshold", "zone3_tempo", "zone2_aerobic", "zone1_recovery"]:
        zone = zones[zone_key]
        if current_hr >= zone["min"]:
            return zone_key
    return None


def get_cardio_metrics(
    age: int,
    resting_hr: Optional[int] = None,
    gender: str = "male",
    max_hr_method: str = "tanaka",
    custom_max_hr: Optional[int] = None
) -> CardioMetrics:
    """
    Calculate comprehensive cardio metrics for a user.

    This is the main entry point for getting all cardio-related calculations
    for a user profile.

    Args:
        age: User's age in years
        resting_hr: Resting heart rate in BPM (optional)
        gender: 'male' or 'female'
        max_hr_method: Method for calculating max HR ('tanaka' or 'traditional')
        custom_max_hr: User-provided measured max HR (overrides calculation)

    Returns:
        CardioMetrics dataclass with all calculated values
    """
    # Calculate or use custom max HR
    if custom_max_hr is not None:
        max_hr = custom_max_hr
        source = "measured"
    else:
        max_hr = calculate_max_hr(age, method=max_hr_method)
        source = "calculated"

    # Calculate zones
    hr_zones = calculate_hr_zones(max_hr, resting_hr)

    # Calculate VO2 max and fitness age if resting HR available
    vo2_max = None
    fitness_age = None

    if resting_hr is not None:
        vo2_max = estimate_vo2_max(resting_hr, age, gender)
        fitness_age = get_fitness_age(age, vo2_max, gender)

    return CardioMetrics(
        max_hr=max_hr,
        resting_hr=resting_hr,
        hr_zones=hr_zones,
        vo2_max_estimate=vo2_max,
        fitness_age=fitness_age,
        source=source
    )
