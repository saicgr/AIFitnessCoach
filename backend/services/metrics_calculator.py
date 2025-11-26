"""
Health Metrics Calculator Service.

Calculates BMI, BMR, TDEE, Ideal Body Weight, and body composition metrics.
"""
import math
from typing import Optional
from dataclasses import dataclass
from core.logger import get_logger

logger = get_logger(__name__)


@dataclass
class HealthMetrics:
    """Complete health metrics calculation result."""
    # BMI
    bmi: float
    bmi_category: str  # "underweight", "normal", "overweight", "obese"
    target_bmi: Optional[float] = None

    # Ideal Body Weight (multiple formulas)
    ideal_body_weight_devine: float = 0.0
    ideal_body_weight_robinson: float = 0.0
    ideal_body_weight_miller: float = 0.0

    # Metabolic rates
    bmr_mifflin: float = 0.0  # Mifflin-St Jeor (most accurate)
    bmr_harris: float = 0.0   # Harris-Benedict (alternative)
    tdee: float = 0.0

    # Body composition (optional - requires additional measurements)
    waist_to_height_ratio: Optional[float] = None
    waist_to_hip_ratio: Optional[float] = None
    body_fat_navy: Optional[float] = None
    lean_body_mass: Optional[float] = None
    ffmi: Optional[float] = None  # Fat-Free Mass Index


class MetricsCalculator:
    """Service for calculating health and fitness metrics."""

    # Activity level multipliers for TDEE calculation
    ACTIVITY_MULTIPLIERS = {
        "sedentary": 1.2,           # Little or no exercise
        "lightly_active": 1.375,    # Light exercise 1-3 days/week
        "moderately_active": 1.55,  # Moderate exercise 3-5 days/week
        "very_active": 1.725,       # Hard exercise 6-7 days/week
        "extremely_active": 1.9,    # Very hard exercise, physical job
    }

    # BMI category thresholds
    BMI_CATEGORIES = [
        (18.5, "underweight"),
        (25.0, "normal"),
        (30.0, "overweight"),
        (float('inf'), "obese"),
    ]

    def calculate_bmi(self, weight_kg: float, height_cm: float) -> tuple[float, str]:
        """
        Calculate BMI and category.

        Args:
            weight_kg: Weight in kilograms
            height_cm: Height in centimeters

        Returns:
            Tuple of (BMI value, category string)
        """
        if height_cm <= 0 or weight_kg <= 0:
            return 0.0, "unknown"

        height_m = height_cm / 100
        bmi = weight_kg / (height_m ** 2)

        category = "obese"
        for threshold, cat in self.BMI_CATEGORIES:
            if bmi < threshold:
                category = cat
                break

        return round(bmi, 1), category

    def calculate_ibw_devine(self, height_cm: float, gender: str) -> float:
        """
        Calculate Ideal Body Weight using Devine formula (1974).

        Args:
            height_cm: Height in centimeters
            gender: "male" or "female"

        Returns:
            Ideal body weight in kg
        """
        height_inches = height_cm / 2.54
        inches_over_5ft = height_inches - 60

        if gender == "male":
            ibw = 50 + 2.3 * inches_over_5ft
        else:
            ibw = 45.5 + 2.3 * inches_over_5ft

        return round(max(ibw, 0), 1)

    def calculate_ibw_robinson(self, height_cm: float, gender: str) -> float:
        """
        Calculate Ideal Body Weight using Robinson formula (1983).

        Args:
            height_cm: Height in centimeters
            gender: "male" or "female"

        Returns:
            Ideal body weight in kg
        """
        height_inches = height_cm / 2.54
        inches_over_5ft = height_inches - 60

        if gender == "male":
            ibw = 52 + 1.9 * inches_over_5ft
        else:
            ibw = 49 + 1.7 * inches_over_5ft

        return round(max(ibw, 0), 1)

    def calculate_ibw_miller(self, height_cm: float, gender: str) -> float:
        """
        Calculate Ideal Body Weight using Miller formula (1983).

        Args:
            height_cm: Height in centimeters
            gender: "male" or "female"

        Returns:
            Ideal body weight in kg
        """
        height_inches = height_cm / 2.54
        inches_over_5ft = height_inches - 60

        if gender == "male":
            ibw = 56.2 + 1.41 * inches_over_5ft
        else:
            ibw = 53.1 + 1.36 * inches_over_5ft

        return round(max(ibw, 0), 1)

    def calculate_bmr_mifflin(
        self,
        weight_kg: float,
        height_cm: float,
        age: int,
        gender: str
    ) -> float:
        """
        Calculate Basal Metabolic Rate using Mifflin-St Jeor equation (1990).
        This is considered the most accurate BMR formula for modern populations.

        Args:
            weight_kg: Weight in kilograms
            height_cm: Height in centimeters
            age: Age in years
            gender: "male" or "female"

        Returns:
            BMR in calories/day
        """
        if gender == "male":
            bmr = (10 * weight_kg) + (6.25 * height_cm) - (5 * age) + 5
        else:
            bmr = (10 * weight_kg) + (6.25 * height_cm) - (5 * age) - 161

        return round(bmr, 0)

    def calculate_bmr_harris(
        self,
        weight_kg: float,
        height_cm: float,
        age: int,
        gender: str
    ) -> float:
        """
        Calculate Basal Metabolic Rate using Harris-Benedict equation (1919, revised 1984).

        Args:
            weight_kg: Weight in kilograms
            height_cm: Height in centimeters
            age: Age in years
            gender: "male" or "female"

        Returns:
            BMR in calories/day
        """
        if gender == "male":
            bmr = 88.362 + (13.397 * weight_kg) + (4.799 * height_cm) - (5.677 * age)
        else:
            bmr = 447.593 + (9.247 * weight_kg) + (3.098 * height_cm) - (4.330 * age)

        return round(bmr, 0)

    def calculate_tdee(self, bmr: float, activity_level: str) -> float:
        """
        Calculate Total Daily Energy Expenditure.

        Args:
            bmr: Basal Metabolic Rate
            activity_level: One of sedentary, lightly_active, moderately_active, very_active, extremely_active

        Returns:
            TDEE in calories/day
        """
        multiplier = self.ACTIVITY_MULTIPLIERS.get(activity_level, 1.375)
        return round(bmr * multiplier, 0)

    def calculate_body_fat_navy(
        self,
        height_cm: float,
        waist_cm: float,
        neck_cm: float,
        hip_cm: Optional[float],
        gender: str
    ) -> Optional[float]:
        """
        Calculate body fat percentage using U.S. Navy method.

        Args:
            height_cm: Height in centimeters
            waist_cm: Waist circumference in centimeters
            neck_cm: Neck circumference in centimeters
            hip_cm: Hip circumference in centimeters (required for women)
            gender: "male" or "female"

        Returns:
            Body fat percentage, or None if invalid inputs
        """
        if not waist_cm or not neck_cm or height_cm <= 0:
            return None

        try:
            if gender == "male":
                # Men: 495 / (1.0324 - 0.19077 * log10(waist - neck) + 0.15456 * log10(height)) - 450
                if waist_cm <= neck_cm:
                    return None
                bf = 495 / (1.0324 - 0.19077 * math.log10(waist_cm - neck_cm) + 0.15456 * math.log10(height_cm)) - 450
            else:
                # Women: 495 / (1.29579 - 0.35004 * log10(waist + hip - neck) + 0.22100 * log10(height)) - 450
                if not hip_cm:
                    return None
                combined = waist_cm + hip_cm - neck_cm
                if combined <= 0:
                    return None
                bf = 495 / (1.29579 - 0.35004 * math.log10(combined) + 0.22100 * math.log10(height_cm)) - 450

            return round(max(bf, 0), 1)
        except (ValueError, ZeroDivisionError) as e:
            logger.warning(f"Body fat calculation failed: {e}")
            return None

    def calculate_waist_to_height_ratio(self, waist_cm: float, height_cm: float) -> Optional[float]:
        """
        Calculate waist-to-height ratio.
        < 0.5 is considered healthy.

        Args:
            waist_cm: Waist circumference in centimeters
            height_cm: Height in centimeters

        Returns:
            Ratio, or None if invalid inputs
        """
        if not waist_cm or height_cm <= 0:
            return None
        return round(waist_cm / height_cm, 2)

    def calculate_waist_to_hip_ratio(self, waist_cm: float, hip_cm: float) -> Optional[float]:
        """
        Calculate waist-to-hip ratio.
        Men: < 0.95 is low risk, > 1.0 is high risk
        Women: < 0.80 is low risk, > 0.85 is high risk

        Args:
            waist_cm: Waist circumference in centimeters
            hip_cm: Hip circumference in centimeters

        Returns:
            Ratio, or None if invalid inputs
        """
        if not waist_cm or not hip_cm or hip_cm <= 0:
            return None
        return round(waist_cm / hip_cm, 2)

    def calculate_lean_body_mass(self, weight_kg: float, body_fat_percent: float) -> Optional[float]:
        """
        Calculate lean body mass.

        Args:
            weight_kg: Total body weight in kg
            body_fat_percent: Body fat percentage

        Returns:
            Lean body mass in kg
        """
        if body_fat_percent is None or body_fat_percent < 0 or body_fat_percent > 100:
            return None
        return round(weight_kg * (1 - body_fat_percent / 100), 1)

    def calculate_ffmi(self, lean_mass_kg: float, height_cm: float) -> Optional[float]:
        """
        Calculate Fat-Free Mass Index.
        FFMI provides a normalized measure of muscle mass.
        Natural range: 18-25 for men, 15-22 for women

        Args:
            lean_mass_kg: Lean body mass in kg
            height_cm: Height in centimeters

        Returns:
            FFMI value
        """
        if lean_mass_kg is None or lean_mass_kg <= 0 or height_cm <= 0:
            return None
        height_m = height_cm / 100
        return round(lean_mass_kg / (height_m ** 2), 1)

    def calculate_all(
        self,
        weight_kg: float,
        height_cm: float,
        age: int,
        gender: str,
        activity_level: str,
        target_weight_kg: Optional[float] = None,
        waist_cm: Optional[float] = None,
        hip_cm: Optional[float] = None,
        neck_cm: Optional[float] = None,
        body_fat_percent: Optional[float] = None,
    ) -> HealthMetrics:
        """
        Calculate all health metrics at once.

        Args:
            weight_kg: Current weight in kilograms
            height_cm: Height in centimeters
            age: Age in years
            gender: "male" or "female"
            activity_level: Activity level string
            target_weight_kg: Optional target weight for BMI calculation
            waist_cm: Optional waist circumference for body composition
            hip_cm: Optional hip circumference for body composition
            neck_cm: Optional neck circumference for body composition
            body_fat_percent: Optional user-provided body fat percentage

        Returns:
            HealthMetrics dataclass with all calculated values
        """
        logger.info(f"Calculating metrics for: weight={weight_kg}kg, height={height_cm}cm, age={age}, gender={gender}")

        # Normalize gender
        gender = gender.lower() if gender else "male"
        if gender not in ["male", "female"]:
            gender = "male"  # Default

        # Core metrics
        bmi, bmi_category = self.calculate_bmi(weight_kg, height_cm)

        target_bmi = None
        if target_weight_kg and target_weight_kg > 0:
            target_bmi, _ = self.calculate_bmi(target_weight_kg, height_cm)

        # BMR and TDEE
        bmr_mifflin = self.calculate_bmr_mifflin(weight_kg, height_cm, age, gender)
        bmr_harris = self.calculate_bmr_harris(weight_kg, height_cm, age, gender)
        tdee = self.calculate_tdee(bmr_mifflin, activity_level)

        # Ideal body weight (multiple formulas)
        ibw_devine = self.calculate_ibw_devine(height_cm, gender)
        ibw_robinson = self.calculate_ibw_robinson(height_cm, gender)
        ibw_miller = self.calculate_ibw_miller(height_cm, gender)

        # Body composition (if measurements provided)
        waist_to_height = self.calculate_waist_to_height_ratio(waist_cm, height_cm) if waist_cm else None
        waist_to_hip = self.calculate_waist_to_hip_ratio(waist_cm, hip_cm) if waist_cm and hip_cm else None

        # Use provided body fat or calculate via Navy method
        bf = body_fat_percent
        if bf is None and waist_cm and neck_cm:
            bf = self.calculate_body_fat_navy(height_cm, waist_cm, neck_cm, hip_cm, gender)

        # Lean body mass and FFMI (if we have body fat)
        lean_mass = None
        ffmi = None
        if bf is not None:
            lean_mass = self.calculate_lean_body_mass(weight_kg, bf)
            if lean_mass:
                ffmi = self.calculate_ffmi(lean_mass, height_cm)

        metrics = HealthMetrics(
            bmi=bmi,
            bmi_category=bmi_category,
            target_bmi=target_bmi,
            ideal_body_weight_devine=ibw_devine,
            ideal_body_weight_robinson=ibw_robinson,
            ideal_body_weight_miller=ibw_miller,
            bmr_mifflin=bmr_mifflin,
            bmr_harris=bmr_harris,
            tdee=tdee,
            waist_to_height_ratio=waist_to_height,
            waist_to_hip_ratio=waist_to_hip,
            body_fat_navy=bf,
            lean_body_mass=lean_mass,
            ffmi=ffmi,
        )

        logger.info(f"Calculated metrics: BMI={bmi} ({bmi_category}), BMR={bmr_mifflin}, TDEE={tdee}")

        return metrics

    def get_bmi_interpretation(self, bmi: float, category: str) -> str:
        """Get a human-readable interpretation of BMI."""
        interpretations = {
            "underweight": f"Your BMI of {bmi} is below the normal range. Consider consulting a healthcare provider.",
            "normal": f"Your BMI of {bmi} is within the healthy range. Great job maintaining a healthy weight!",
            "overweight": f"Your BMI of {bmi} is above the normal range. Small lifestyle changes can help.",
            "obese": f"Your BMI of {bmi} indicates obesity. Consider speaking with a healthcare provider about a weight management plan.",
        }
        return interpretations.get(category, f"Your BMI is {bmi}.")

    def get_tdee_interpretation(self, tdee: float, activity_level: str) -> str:
        """Get a human-readable interpretation of TDEE."""
        activity_desc = {
            "sedentary": "little to no exercise",
            "lightly_active": "light exercise 1-3 days/week",
            "moderately_active": "moderate exercise 3-5 days/week",
            "very_active": "hard exercise 6-7 days/week",
            "extremely_active": "very hard exercise and physical job",
        }
        desc = activity_desc.get(activity_level, "your activity level")
        return f"With {desc}, you burn approximately {int(tdee):,} calories per day."
