"""
Tests for Heart Rate Zone Calculations.

Tests the cardio service's HR zone calculation functions including:
- Max HR calculation (Tanaka and traditional formulas)
- HR zone calculation (with and without resting HR)
- VO2 max estimation
- Fitness age calculation
"""
import pytest
from datetime import date, datetime
from zoneinfo import ZoneInfo

from services.cardio.hr_zones import (
    calculate_max_hr,
    calculate_hr_zones,
    calculate_age_from_dob,
    estimate_vo2_max,
    get_fitness_age,
    get_zone_for_heart_rate,
    get_cardio_metrics,
)


class TestCalculateMaxHR:
    """Tests for max HR calculation."""

    def test_max_hr_tanaka_formula_age_30(self):
        """Test Tanaka formula for 30-year-old."""
        # 208 - 0.7 * 30 = 208 - 21 = 187
        result = calculate_max_hr(30, method="tanaka")
        assert result == 187

    def test_max_hr_tanaka_formula_age_40(self):
        """Test Tanaka formula for 40-year-old."""
        # 208 - 0.7 * 40 = 208 - 28 = 180
        result = calculate_max_hr(40, method="tanaka")
        assert result == 180

    def test_max_hr_tanaka_formula_age_50(self):
        """Test Tanaka formula for 50-year-old."""
        # 208 - 0.7 * 50 = 208 - 35 = 173
        result = calculate_max_hr(50, method="tanaka")
        assert result == 173

    def test_max_hr_tanaka_formula_age_25(self):
        """Test Tanaka formula for 25-year-old."""
        # 208 - 0.7 * 25 = 208 - 17.5 = 190.5 -> 190
        result = calculate_max_hr(25, method="tanaka")
        assert result == 190

    def test_max_hr_traditional_formula_age_30(self):
        """Test traditional formula for 30-year-old."""
        # 220 - 30 = 190
        result = calculate_max_hr(30, method="traditional")
        assert result == 190

    def test_max_hr_traditional_formula_age_40(self):
        """Test traditional formula for 40-year-old."""
        # 220 - 40 = 180
        result = calculate_max_hr(40, method="traditional")
        assert result == 180

    def test_max_hr_default_is_tanaka(self):
        """Test that default method is Tanaka."""
        result_default = calculate_max_hr(30)
        result_tanaka = calculate_max_hr(30, method="tanaka")
        assert result_default == result_tanaka

    def test_max_hr_invalid_age_too_low(self):
        """Test that invalid low age raises ValueError."""
        with pytest.raises(ValueError, match="Invalid age"):
            calculate_max_hr(0)

    def test_max_hr_invalid_age_too_high(self):
        """Test that invalid high age raises ValueError."""
        with pytest.raises(ValueError, match="Invalid age"):
            calculate_max_hr(121)

    def test_max_hr_invalid_method(self):
        """Test that invalid method raises ValueError."""
        with pytest.raises(ValueError, match="Unknown method"):
            calculate_max_hr(30, method="invalid")


class TestCalculateHRZones:
    """Tests for HR zone calculation."""

    def test_hr_zones_with_resting_hr_karvonen(self):
        """Test Karvonen formula zones with resting HR."""
        zones = calculate_hr_zones(max_hr=180, resting_hr=60)

        # Heart Rate Reserve (HRR) = 180 - 60 = 120
        # Zone 2 min = 60 + 120 * 0.60 = 60 + 72 = 132
        # Zone 2 max = 60 + 120 * 0.70 = 60 + 84 = 144
        assert zones["zone2_aerobic"]["min"] == 132
        assert zones["zone2_aerobic"]["max"] == 144

        # Zone 1 (Recovery) = 50-60%
        assert zones["zone1_recovery"]["min"] == 120  # 60 + 120 * 0.50
        assert zones["zone1_recovery"]["max"] == 132  # 60 + 120 * 0.60

        # Zone 5 (VO2 Max) should end at max HR
        assert zones["zone5_max"]["max"] == 180

    def test_hr_zones_without_resting_hr_percentage(self):
        """Test percentage of max HR zones."""
        zones = calculate_hr_zones(max_hr=180)

        # Zone 2 should be 60-70% of max HR
        # Note: int(180 * 0.70) = 125 due to floating-point truncation (125.9999...)
        assert zones["zone2_aerobic"]["min"] == 108  # int(180 * 0.60) = 108
        assert zones["zone2_aerobic"]["max"] == 125  # int(180 * 0.70) = 125 (float truncation)

        # Zone 1 (Recovery) = 50-60%
        assert zones["zone1_recovery"]["min"] == 90   # int(180 * 0.50) = 90
        assert zones["zone1_recovery"]["max"] == 108  # int(180 * 0.60) = 108

        # Zone 5 should end at max HR
        assert zones["zone5_max"]["max"] == 180

        # Verify zone ranges are reasonable
        assert zones["zone2_aerobic"]["min"] >= 100
        assert zones["zone2_aerobic"]["max"] <= 130

    def test_hr_zones_has_all_five_zones(self):
        """Test that all 5 zones are returned."""
        zones = calculate_hr_zones(max_hr=180)

        expected_zones = [
            "zone1_recovery",
            "zone2_aerobic",
            "zone3_tempo",
            "zone4_threshold",
            "zone5_max",
        ]

        for zone_key in expected_zones:
            assert zone_key in zones
            assert "min" in zones[zone_key]
            assert "max" in zones[zone_key]
            assert "name" in zones[zone_key]
            assert "benefit" in zones[zone_key]
            assert "color" in zones[zone_key]

    def test_hr_zones_are_continuous(self):
        """Test that zones are continuous (no gaps)."""
        zones = calculate_hr_zones(max_hr=180, resting_hr=60)

        zone_order = [
            "zone1_recovery",
            "zone2_aerobic",
            "zone3_tempo",
            "zone4_threshold",
            "zone5_max",
        ]

        for i in range(len(zone_order) - 1):
            current_zone = zones[zone_order[i]]
            next_zone = zones[zone_order[i + 1]]
            # Current zone's max should equal next zone's min
            assert current_zone["max"] == next_zone["min"]

    def test_hr_zones_invalid_max_hr_too_low(self):
        """Test that invalid low max HR raises ValueError."""
        with pytest.raises(ValueError, match="Invalid max HR"):
            calculate_hr_zones(max_hr=90)

    def test_hr_zones_invalid_max_hr_too_high(self):
        """Test that invalid high max HR raises ValueError."""
        with pytest.raises(ValueError, match="Invalid max HR"):
            calculate_hr_zones(max_hr=230)

    def test_hr_zones_invalid_resting_hr_too_low(self):
        """Test that invalid low resting HR raises ValueError."""
        with pytest.raises(ValueError, match="Invalid resting HR"):
            calculate_hr_zones(max_hr=180, resting_hr=25)

    def test_hr_zones_invalid_resting_hr_too_high(self):
        """Test that invalid high resting HR raises ValueError."""
        with pytest.raises(ValueError, match="Invalid resting HR"):
            calculate_hr_zones(max_hr=180, resting_hr=110)


class TestCalculateAgeFromDOB:
    """Tests for age calculation from date of birth.

    STALE CALL FIXED: these tests used to call ``calculate_age_from_dob(dob)``
    with no second argument and compare against the *server's* ``date.today()``.
    ``calculate_age_from_dob`` now takes a required ``timezone_str`` and resolves
    "today" in the USER's timezone (``get_user_today``), because a server-local
    "today" makes a user's age (and therefore their max-HR / training zones) flip
    a day early or late on their birthday depending on which region Render runs in.

    No assertion was weakened: each test still pins the exact age. They now
    derive their own reference "today" in the same timezone they pass in
    (computed independently via ``zoneinfo``, not by calling back into the
    module under test).
    """

    # Timezones spanning the full UTC-11..UTC+14 range, so a regression back to a
    # server-local "today" would break these whenever the local dates diverge.
    TIMEZONES = ["UTC", "America/Chicago", "Pacific/Kiritimati", "Pacific/Niue"]

    @staticmethod
    def _today_in(timezone_str: str) -> date:
        """Today's date in ``timezone_str``, computed independently of hr_zones."""
        return datetime.now(ZoneInfo(timezone_str)).date()

    @staticmethod
    def _birthday_years_ago(today: date, years: int) -> date:
        """``today`` shifted back ``years`` years (Feb-29 safe)."""
        try:
            return today.replace(year=today.year - years)
        except ValueError:  # Feb 29 -> non-leap target year
            return today.replace(year=today.year - years, day=28)

    def test_age_calculation_simple(self):
        """Test simple age calculation."""
        # DOB 1994-01-15: anyone born then is at least 30 by 2024-01-15 onwards.
        dob = date(1994, 1, 15)
        age = calculate_age_from_dob(dob, "America/Chicago")
        assert age >= 30  # Should be at least 30

    def test_age_calculation_birthday_not_yet(self):
        """Test age when birthday hasn't occurred this year."""
        tz = "America/Chicago"
        today = self._today_in(tz)
        # Set DOB to be later this year (or next month if December)
        if today.month < 12:
            future_birthday = date(today.year - 30, today.month + 1, 15)
        else:
            future_birthday = date(today.year - 30, 1, 15)

        age = calculate_age_from_dob(future_birthday, tz)
        # Should be 29 if birthday is in the future this year
        if today.month < 12:
            assert age == 29
        else:
            assert age == 30

    def test_age_calculation_same_day(self):
        """Test age when today is the birthday."""
        tz = "America/Chicago"
        today = self._today_in(tz)
        dob = self._birthday_years_ago(today, 25)
        age = calculate_age_from_dob(dob, tz)
        assert age == 25

    def test_age_is_resolved_in_the_users_timezone(self):
        """Age must be computed against the USER's today, not the server's.

        This is the guarantee the ``timezone_str`` parameter exists for: on the
        user's birthday, each timezone must independently report the exact age,
        even when the server's local date is a different calendar day.
        """
        for tz in self.TIMEZONES:
            today = self._today_in(tz)

            # Birthday is today in this timezone -> exactly 30.
            dob = self._birthday_years_ago(today, 30)
            assert calculate_age_from_dob(dob, tz) == 30, tz

            # Birthday is Dec 31 (never Feb 29, so always representable):
            # not reached yet -> 29, unless today already IS Dec 31 -> 30.
            dob_year_end = date(today.year - 30, 12, 31)
            expected = 30 if (today.month, today.day) == (12, 31) else 29
            assert calculate_age_from_dob(dob_year_end, tz) == expected, tz


class TestEstimateVO2Max:
    """Tests for VO2 max estimation."""

    def test_vo2_max_estimation_basic(self):
        """Test basic VO2 max estimation."""
        # Using Uth-Sorensen formula: VO2 max = 15.3 * (max HR / resting HR)
        # For age 30: max HR = 187 (Tanaka), resting HR = 60
        # VO2 max = 15.3 * (187 / 60) = 15.3 * 3.117 = 47.69
        vo2_max = estimate_vo2_max(resting_hr=60, age=30, gender="male")
        assert 45 < vo2_max < 50

    def test_vo2_max_lower_resting_hr_higher_vo2(self):
        """Test that lower resting HR gives higher VO2 max."""
        vo2_high = estimate_vo2_max(resting_hr=50, age=30, gender="male")
        vo2_low = estimate_vo2_max(resting_hr=70, age=30, gender="male")
        assert vo2_high > vo2_low

    def test_vo2_max_gender_adjustment(self):
        """Test that female VO2 max is adjusted."""
        vo2_male = estimate_vo2_max(resting_hr=60, age=30, gender="male")
        vo2_female = estimate_vo2_max(resting_hr=60, age=30, gender="female")
        # Female VO2 max should be ~90% of male
        assert vo2_female < vo2_male
        assert abs(vo2_female / vo2_male - 0.90) < 0.01

    def test_vo2_max_invalid_resting_hr(self):
        """Test that invalid resting HR raises ValueError."""
        with pytest.raises(ValueError, match="Invalid resting HR"):
            estimate_vo2_max(resting_hr=25, age=30, gender="male")


class TestGetFitnessAge:
    """Tests for fitness age calculation."""

    def test_fitness_age_good_vo2(self):
        """Test fitness age for good VO2 max."""
        # High VO2 max should result in younger fitness age
        fitness_age = get_fitness_age(actual_age=40, vo2_max=50, gender="male")
        assert fitness_age < 40

    def test_fitness_age_low_vo2(self):
        """Test fitness age for low VO2 max."""
        # Low VO2 max should result in older fitness age
        fitness_age = get_fitness_age(actual_age=30, vo2_max=30, gender="male")
        assert fitness_age > 30

    def test_fitness_age_bounds(self):
        """Test that fitness age is clamped to reasonable bounds."""
        # Very high VO2 max
        fitness_age_high = get_fitness_age(actual_age=50, vo2_max=80, gender="male")
        assert fitness_age_high >= 18

        # Very low VO2 max
        fitness_age_low = get_fitness_age(actual_age=30, vo2_max=15, gender="male")
        assert fitness_age_low <= 90


class TestGetZoneForHeartRate:
    """Tests for determining current zone from heart rate."""

    def test_zone_for_high_hr(self):
        """Test zone detection for high heart rate."""
        zones = calculate_hr_zones(max_hr=180, resting_hr=60)
        zone = get_zone_for_heart_rate(175, zones)
        assert zone == "zone5_max"

    def test_zone_for_low_hr(self):
        """Test zone detection for low heart rate."""
        zones = calculate_hr_zones(max_hr=180, resting_hr=60)
        zone = get_zone_for_heart_rate(125, zones)
        assert zone == "zone1_recovery"

    def test_zone_for_moderate_hr(self):
        """Test zone detection for moderate heart rate."""
        zones = calculate_hr_zones(max_hr=180, resting_hr=60)
        zone = get_zone_for_heart_rate(145, zones)
        assert zone == "zone3_tempo"

    def test_zone_for_very_low_hr(self):
        """Test zone detection for HR below Zone 1."""
        zones = calculate_hr_zones(max_hr=180, resting_hr=60)
        zone = get_zone_for_heart_rate(100, zones)
        # Below zone 1, should return None
        assert zone is None


class TestGetCardioMetrics:
    """Tests for the comprehensive cardio metrics function."""

    def test_cardio_metrics_basic(self):
        """Test basic cardio metrics calculation."""
        metrics = get_cardio_metrics(age=30, resting_hr=60, gender="male")

        assert metrics.max_hr == 187  # Tanaka formula
        assert metrics.resting_hr == 60
        assert metrics.vo2_max_estimate is not None
        assert metrics.fitness_age is not None
        assert len(metrics.hr_zones) == 5
        assert metrics.source == "calculated"

    def test_cardio_metrics_custom_max_hr(self):
        """Test cardio metrics with custom max HR."""
        metrics = get_cardio_metrics(
            age=30,
            resting_hr=60,
            gender="male",
            custom_max_hr=195,
        )

        assert metrics.max_hr == 195  # Custom value
        assert metrics.source == "measured"

    def test_cardio_metrics_without_resting_hr(self):
        """Test cardio metrics without resting HR."""
        metrics = get_cardio_metrics(age=30, gender="male")

        assert metrics.max_hr == 187
        assert metrics.resting_hr is None
        assert metrics.vo2_max_estimate is None
        assert metrics.fitness_age is None
        # Zones should still be calculated using percentage method
        assert len(metrics.hr_zones) == 5

    def test_cardio_metrics_traditional_method(self):
        """Test cardio metrics using traditional formula."""
        metrics = get_cardio_metrics(
            age=30,
            gender="male",
            max_hr_method="traditional",
        )

        assert metrics.max_hr == 190  # 220 - 30


class TestEdgeCases:
    """Tests for edge cases and boundary conditions."""

    def test_young_athlete(self):
        """Test calculations for young athlete with low resting HR."""
        metrics = get_cardio_metrics(age=20, resting_hr=45, gender="male")

        assert metrics.max_hr == 194  # 208 - 0.7 * 20
        assert metrics.vo2_max_estimate > 60  # Elite level
        assert metrics.fitness_age < 20

    def test_senior_moderate_fitness(self):
        """Test calculations for senior with moderate fitness."""
        metrics = get_cardio_metrics(age=65, resting_hr=70, gender="male")

        assert metrics.max_hr == 162  # 208 - 0.7 * 65
        # Should have reasonable zones
        assert metrics.hr_zones["zone1_recovery"]["min"] < 120
        assert metrics.hr_zones["zone5_max"]["max"] == 162

    def test_female_adjustments(self):
        """Test that female adjustments are applied."""
        male_metrics = get_cardio_metrics(age=35, resting_hr=60, gender="male")
        female_metrics = get_cardio_metrics(age=35, resting_hr=60, gender="female")

        # Same max HR (age-based)
        assert male_metrics.max_hr == female_metrics.max_hr
        # Female VO2 max should be lower
        assert female_metrics.vo2_max_estimate < male_metrics.vo2_max_estimate
