"""
Tests for Injury Service.

Tests:
- Severity to duration mapping
- Recovery phase detection
- Rehab exercise generation
- Exercise safety checks
- Workout filtering for injuries
- Recovery summary

Run with: pytest backend/tests/test_injury_service.py -v
"""

import pytest
from datetime import datetime, timedelta
from services.injury_service import InjuryService, Injury, get_injury_service


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def injury_service():
    return InjuryService()


@pytest.fixture
def acute_back_injury():
    """Create an acute back injury (less than 7 days old)."""
    return Injury(
        id=1,
        user_id=100,
        body_part="back",
        severity="moderate",
        reported_at=datetime.now() - timedelta(days=3),
        expected_recovery_date=datetime.now() + timedelta(weeks=3),
        recovery_phase="acute",
        is_active=True,
        pain_level=6,
        notes="Lower back strain"
    )


@pytest.fixture
def subacute_shoulder_injury():
    """Create a subacute shoulder injury (7-14 days old)."""
    return Injury(
        id=2,
        user_id=100,
        body_part="shoulder",
        severity="mild",
        reported_at=datetime.now() - timedelta(days=10),
        expected_recovery_date=datetime.now() + timedelta(weeks=1),
        recovery_phase="subacute",
        is_active=True
    )


@pytest.fixture
def recovery_knee_injury():
    """Create a recovery phase knee injury (14-21 days old)."""
    return Injury(
        id=3,
        user_id=100,
        body_part="knee",
        severity="moderate",
        reported_at=datetime.now() - timedelta(days=18),
        expected_recovery_date=datetime.now() + timedelta(days=5),
        recovery_phase="recovery",
        is_active=True
    )


@pytest.fixture
def healed_injury():
    """Create a healed injury (over 21 days old)."""
    return Injury(
        id=4,
        user_id=100,
        body_part="wrist",
        severity="mild",
        reported_at=datetime.now() - timedelta(days=30),
        expected_recovery_date=datetime.now() - timedelta(days=10),
        recovery_phase="healed",
        is_active=False
    )


# ============================================================
# SEVERITY DURATION TESTS
# ============================================================

class TestSeverityDuration:
    """Test severity to duration mapping."""

    def test_mild_severity_duration(self, injury_service):
        """Test mild severity gives 2 weeks."""
        duration = injury_service.get_duration_for_severity("mild")
        assert duration == 2

    def test_moderate_severity_duration(self, injury_service):
        """Test moderate severity gives 3 weeks."""
        duration = injury_service.get_duration_for_severity("moderate")
        assert duration == 3

    def test_severe_severity_duration(self, injury_service):
        """Test severe severity gives 5 weeks."""
        duration = injury_service.get_duration_for_severity("severe")
        assert duration == 5

    def test_unknown_severity_defaults_to_3_weeks(self, injury_service):
        """Test unknown severity defaults to 3 weeks."""
        duration = injury_service.get_duration_for_severity("unknown")
        assert duration == 3

    def test_case_insensitive_severity(self, injury_service):
        """Test severity matching is case insensitive."""
        assert injury_service.get_duration_for_severity("MILD") == 2
        assert injury_service.get_duration_for_severity("Moderate") == 3


# ============================================================
# RECOVERY PHASE TESTS
# ============================================================

class TestRecoveryPhase:
    """Test recovery phase detection."""

    def test_acute_phase_detection(self, injury_service, acute_back_injury):
        """Test acute phase detected for injury < 7 days old."""
        phase = injury_service.get_injury_phase(acute_back_injury)
        assert phase == "acute"

    def test_subacute_phase_detection(self, injury_service, subacute_shoulder_injury):
        """Test subacute phase detected for injury 7-14 days old."""
        phase = injury_service.get_injury_phase(subacute_shoulder_injury)
        assert phase == "subacute"

    def test_recovery_phase_detection(self, injury_service, recovery_knee_injury):
        """Test recovery phase detected for injury 14-21 days old."""
        phase = injury_service.get_injury_phase(recovery_knee_injury)
        assert phase == "recovery"

    def test_healed_phase_detection(self, injury_service, healed_injury):
        """Test healed phase detected for injury > 21 days old."""
        phase = injury_service.get_injury_phase(healed_injury)
        assert phase == "healed"

    def test_get_phase_info_acute(self, injury_service):
        """Test phase info for acute phase."""
        info = injury_service.get_phase_info("acute")
        assert info["intensity"] == "none"
        assert "rest" in info["description"].lower()

    def test_get_phase_info_subacute(self, injury_service):
        """Test phase info for subacute phase."""
        info = injury_service.get_phase_info("subacute")
        assert info["intensity"] == "light"

    def test_get_phase_info_recovery(self, injury_service):
        """Test phase info for recovery phase."""
        info = injury_service.get_phase_info("recovery")
        assert info["intensity"] == "moderate"

    def test_get_phase_info_healed(self, injury_service):
        """Test phase info for healed phase."""
        info = injury_service.get_phase_info("healed")
        assert info["intensity"] == "full"

    def test_get_phase_info_unknown_defaults_to_healed(self, injury_service):
        """Test unknown phase defaults to healed."""
        info = injury_service.get_phase_info("unknown_phase")
        assert info == injury_service.RECOVERY_PHASES["healed"]


# ============================================================
# ALLOWED INTENSITY TESTS
# ============================================================

class TestAllowedIntensity:
    """Test allowed exercise intensity for injuries."""

    def test_acute_injury_intensity_none(self, injury_service, acute_back_injury):
        """Test no exercise allowed during acute phase."""
        intensity = injury_service.get_allowed_intensity(acute_back_injury)
        assert intensity == "none"

    def test_subacute_injury_intensity_light(self, injury_service, subacute_shoulder_injury):
        """Test light exercise allowed during subacute phase."""
        intensity = injury_service.get_allowed_intensity(subacute_shoulder_injury)
        assert intensity == "light"

    def test_recovery_injury_intensity_moderate(self, injury_service, recovery_knee_injury):
        """Test moderate exercise allowed during recovery phase."""
        intensity = injury_service.get_allowed_intensity(recovery_knee_injury)
        assert intensity == "moderate"


# ============================================================
# REHAB EXERCISES TESTS
# ============================================================

class TestRehabExercises:
    """Test rehab exercise generation."""

    def test_acute_phase_no_rehab_exercises(self, injury_service, acute_back_injury):
        """Test no rehab exercises during acute phase."""
        exercises = injury_service.get_rehab_exercises(acute_back_injury)
        assert exercises == []

    def test_subacute_phase_back_rehab_exercises(self, injury_service):
        """Test subacute phase back rehab exercises."""
        injury = Injury(
            id=1,
            user_id=100,
            body_part="back",
            severity="moderate",
            reported_at=datetime.now() - timedelta(days=10),
            expected_recovery_date=datetime.now() + timedelta(weeks=2)
        )
        exercises = injury_service.get_rehab_exercises(injury)

        assert len(exercises) > 0
        for ex in exercises:
            assert ex["is_rehab"] is True
            assert ex["for_injury"] == "back"
            assert ex["recovery_phase"] == "subacute"
            assert "name" in ex

    def test_recovery_phase_knee_rehab_exercises(self, injury_service):
        """Test recovery phase knee rehab exercises."""
        injury = Injury(
            id=1,
            user_id=100,
            body_part="knee",
            severity="moderate",
            reported_at=datetime.now() - timedelta(days=18),
            expected_recovery_date=datetime.now() + timedelta(days=5)
        )
        exercises = injury_service.get_rehab_exercises(injury)

        assert len(exercises) > 0
        for ex in exercises:
            assert ex["is_rehab"] is True
            assert ex["for_injury"] == "knee"
            assert ex["recovery_phase"] == "recovery"

    def test_unknown_body_part_no_exercises(self, injury_service):
        """Test unknown body part returns empty list."""
        injury = Injury(
            id=1,
            user_id=100,
            body_part="finger",  # Not in REHAB_EXERCISES
            severity="mild",
            reported_at=datetime.now() - timedelta(days=10),
            expected_recovery_date=datetime.now() + timedelta(weeks=1)
        )
        exercises = injury_service.get_rehab_exercises(injury)
        assert exercises == []


# ============================================================
# EXERCISE SAFETY TESTS
# ============================================================

class TestExerciseSafety:
    """Test exercise safety checks."""

    def test_healed_injury_all_exercises_safe(self, injury_service, healed_injury):
        """Test all exercises are safe when injury is healed."""
        assert injury_service.is_exercise_safe("Deadlift", healed_injury) is True
        assert injury_service.is_exercise_safe("Squat", healed_injury) is True

    def test_back_injury_deadlift_unsafe(self, injury_service, acute_back_injury):
        """Test deadlift is unsafe with back injury."""
        assert injury_service.is_exercise_safe("Deadlift", acute_back_injury) is False
        assert injury_service.is_exercise_safe("Romanian Deadlift", acute_back_injury) is False
        assert injury_service.is_exercise_safe("Barbell Row", acute_back_injury) is False

    def test_back_injury_bicep_curl_safe(self, injury_service, acute_back_injury):
        """Test bicep curl is safe with back injury."""
        assert injury_service.is_exercise_safe("Bicep Curl", acute_back_injury) is True

    def test_shoulder_injury_overhead_press_unsafe(self, injury_service, subacute_shoulder_injury):
        """Test overhead press is unsafe with shoulder injury."""
        assert injury_service.is_exercise_safe("Overhead Press", subacute_shoulder_injury) is False
        assert injury_service.is_exercise_safe("Shoulder Press", subacute_shoulder_injury) is False
        assert injury_service.is_exercise_safe("Lateral Raise", subacute_shoulder_injury) is False

    def test_knee_injury_squat_unsafe(self, injury_service, recovery_knee_injury):
        """Test squat is unsafe with knee injury (even in recovery)."""
        assert injury_service.is_exercise_safe("Back Squat", recovery_knee_injury) is False
        assert injury_service.is_exercise_safe("Leg Press", recovery_knee_injury) is False
        assert injury_service.is_exercise_safe("Lunges", recovery_knee_injury) is False

    def test_case_insensitive_matching(self, injury_service, acute_back_injury):
        """Test exercise name matching is case insensitive."""
        assert injury_service.is_exercise_safe("DEADLIFT", acute_back_injury) is False
        assert injury_service.is_exercise_safe("deadlift", acute_back_injury) is False


# ============================================================
# WORKOUT FILTERING TESTS
# ============================================================

class TestWorkoutFiltering:
    """Test workout filtering for injuries."""

    def test_filter_workout_single_injury(self, injury_service, acute_back_injury):
        """Test filtering workout with single injury."""
        exercises = [
            {"name": "Deadlift", "sets": 3, "reps": 5},
            {"name": "Bench Press", "sets": 3, "reps": 8},
            {"name": "Barbell Row", "sets": 3, "reps": 8},
            {"name": "Bicep Curl", "sets": 3, "reps": 12},
        ]

        safe, removed = injury_service.filter_workout_for_injuries(
            exercises, [acute_back_injury]
        )

        assert len(safe) == 2  # Bench Press, Bicep Curl
        assert len(removed) == 2  # Deadlift, Barbell Row

        safe_names = [ex["name"] for ex in safe]
        assert "Bench Press" in safe_names
        assert "Bicep Curl" in safe_names

        removed_names = [ex["name"] for ex in removed]
        assert "Deadlift" in removed_names
        assert "Barbell Row" in removed_names

    def test_filter_workout_multiple_injuries(self, injury_service, acute_back_injury, subacute_shoulder_injury):
        """Test filtering workout with multiple injuries."""
        exercises = [
            {"name": "Deadlift", "sets": 3, "reps": 5},  # Back contraindication
            {"name": "Overhead Press", "sets": 3, "reps": 8},  # Shoulder contraindication
            {"name": "Bicep Curl", "sets": 3, "reps": 12},  # Safe
            {"name": "Calf Raises", "sets": 3, "reps": 15},  # Safe
        ]

        safe, removed = injury_service.filter_workout_for_injuries(
            exercises, [acute_back_injury, subacute_shoulder_injury]
        )

        assert len(safe) == 2
        assert len(removed) == 2

        safe_names = [ex["name"] for ex in safe]
        assert "Bicep Curl" in safe_names
        assert "Calf Raises" in safe_names

    def test_filter_workout_no_injuries(self, injury_service):
        """Test filtering workout with no injuries."""
        exercises = [
            {"name": "Deadlift", "sets": 3, "reps": 5},
            {"name": "Squat", "sets": 3, "reps": 8},
        ]

        safe, removed = injury_service.filter_workout_for_injuries(exercises, [])

        assert len(safe) == 2
        assert len(removed) == 0

    def test_removed_exercise_has_injury_info(self, injury_service, acute_back_injury):
        """Test that removed exercises have injury information."""
        exercises = [{"name": "Deadlift", "sets": 3, "reps": 5}]

        safe, removed = injury_service.filter_workout_for_injuries(
            exercises, [acute_back_injury]
        )

        assert removed[0].get("removed_due_to") == "back"


# ============================================================
# ADD REHAB EXERCISES TESTS
# ============================================================

class TestAddRehabExercises:
    """Test adding rehab exercises to workout."""

    def test_add_rehab_exercises_subacute(self, injury_service):
        """Test adding rehab exercises in subacute phase."""
        injury = Injury(
            id=1,
            user_id=100,
            body_part="back",
            severity="moderate",
            reported_at=datetime.now() - timedelta(days=10),
            expected_recovery_date=datetime.now() + timedelta(weeks=2)
        )

        workout = [
            {"name": "Bench Press", "sets": 3, "reps": 8}
        ]

        result = injury_service.add_rehab_exercises_to_workout(workout, [injury])

        assert len(result) > 1
        assert result[0]["name"] == "Bench Press"
        # Rehab exercises should be at the end
        for ex in result[1:]:
            assert ex.get("is_rehab") is True

    def test_add_rehab_no_exercises_in_acute(self, injury_service, acute_back_injury):
        """Test no rehab exercises added in acute phase."""
        workout = [{"name": "Bench Press", "sets": 3, "reps": 8}]

        result = injury_service.add_rehab_exercises_to_workout(workout, [acute_back_injury])

        assert len(result) == 1  # Only original workout


# ============================================================
# RECOVERY SUMMARY TESTS
# ============================================================

class TestRecoverySummary:
    """Test recovery summary generation."""

    def test_recovery_summary_structure(self, injury_service, acute_back_injury):
        """Test recovery summary has expected fields."""
        summary = injury_service.get_recovery_summary(acute_back_injury)

        assert "body_part" in summary
        assert "severity" in summary
        assert "days_since_injury" in summary
        assert "days_remaining" in summary
        assert "current_phase" in summary
        assert "phase_description" in summary
        assert "allowed_intensity" in summary
        assert "expected_recovery_date" in summary
        assert "is_active" in summary
        assert "progress_percent" in summary

    def test_recovery_summary_values(self, injury_service, acute_back_injury):
        """Test recovery summary values are correct."""
        summary = injury_service.get_recovery_summary(acute_back_injury)

        assert summary["body_part"] == "back"
        assert summary["severity"] == "moderate"
        assert summary["current_phase"] == "acute"
        assert summary["is_active"] is True
        assert 0 <= summary["progress_percent"] <= 100

    def test_recovery_summary_progress_calculation(self, injury_service, recovery_knee_injury):
        """Test progress percentage calculation."""
        summary = injury_service.get_recovery_summary(recovery_knee_injury)

        # Injury is 18 days old with ~5 days remaining
        # Progress should be around 78% (18/(18+5))
        assert summary["progress_percent"] > 50


# ============================================================
# CONTRAINDICATED EXERCISES TESTS
# ============================================================

class TestContraindicatedExercises:
    """Test getting contraindicated exercises."""

    def test_get_back_contraindications(self, injury_service):
        """Test getting back contraindicated exercises."""
        contraindications = injury_service.get_contraindicated_exercises("back")

        assert "deadlift" in contraindications
        assert "squat" in contraindications
        assert "barbell row" in contraindications

    def test_get_knee_contraindications(self, injury_service):
        """Test getting knee contraindicated exercises."""
        contraindications = injury_service.get_contraindicated_exercises("knee")

        assert "squat" in contraindications
        assert "lunge" in contraindications
        assert "leg press" in contraindications

    def test_unknown_body_part_empty_list(self, injury_service):
        """Test unknown body part returns empty list."""
        contraindications = injury_service.get_contraindicated_exercises("finger")
        assert contraindications == []

    def test_case_insensitive(self, injury_service):
        """Test body part is case insensitive."""
        assert injury_service.get_contraindicated_exercises("BACK") == \
               injury_service.get_contraindicated_exercises("back")


# ============================================================
# SHOULD CHECK IN TESTS
# ============================================================

class TestShouldCheckIn:
    """Test check-in timing."""

    def test_should_check_in_day_7(self, injury_service):
        """Test should check in at day 7 (phase transition)."""
        injury = Injury(
            id=1,
            user_id=100,
            body_part="back",
            severity="moderate",
            reported_at=datetime.now() - timedelta(days=7),
            expected_recovery_date=datetime.now() + timedelta(weeks=2)
        )
        assert injury_service.should_check_in(injury) is True

    def test_should_check_in_day_14(self, injury_service):
        """Test should check in at day 14 (phase transition)."""
        injury = Injury(
            id=1,
            user_id=100,
            body_part="back",
            severity="moderate",
            reported_at=datetime.now() - timedelta(days=14),
            expected_recovery_date=datetime.now() + timedelta(days=7)
        )
        assert injury_service.should_check_in(injury) is True

    def test_should_check_in_day_3_acute(self, injury_service):
        """Test should check in at day 3 during acute phase."""
        injury = Injury(
            id=1,
            user_id=100,
            body_part="back",
            severity="moderate",
            reported_at=datetime.now() - timedelta(days=3),
            expected_recovery_date=datetime.now() + timedelta(weeks=3)
        )
        assert injury_service.should_check_in(injury) is True

    def test_should_not_check_in_day_5(self, injury_service):
        """Test should not check in at day 5 (not at phase boundary)."""
        injury = Injury(
            id=1,
            user_id=100,
            body_part="back",
            severity="moderate",
            reported_at=datetime.now() - timedelta(days=5),
            expected_recovery_date=datetime.now() + timedelta(weeks=2)
        )
        assert injury_service.should_check_in(injury) is False


# ============================================================
# SINGLETON TESTS
# ============================================================

class TestInjuryServiceSingleton:
    """Test injury service singleton pattern."""

    def test_get_injury_service_returns_same_instance(self):
        """Test that get_injury_service returns singleton."""
        import services.injury_service as service_module
        service_module._injury_service = None

        service1 = get_injury_service()
        service2 = get_injury_service()

        assert service1 is service2


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
