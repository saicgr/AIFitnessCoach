"""
Tests for onboarding data extraction functions.
"""

import pytest


class TestExtractName:
    """Tests for _extract_name function."""

    def test_extracts_my_name_is(self):
        """Test extracting name from 'My name is X' pattern."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_name

        assert _extract_name("My name is John") == "John"
        assert _extract_name("my name is sarah") == "Sarah"

    def test_extracts_im_pattern(self):
        """Test extracting name from 'I'm X' pattern."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_name

        assert _extract_name("I'm Mike") == "Mike"
        assert _extract_name("im Alex") == "Alex"

    def test_extracts_call_me(self):
        """Test extracting name from 'call me X' pattern."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_name

        assert _extract_name("Just call me Bob") == "Bob"

    def test_extracts_single_word(self):
        """Test extracting single word as name."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_name

        assert _extract_name("Jennifer") == "Jennifer"

    def test_rejects_common_words(self):
        """Test rejecting common words as names."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_name

        assert _extract_name("hello") is None
        assert _extract_name("yes") is None
        assert _extract_name("ok") is None

    def test_handles_punctuation(self):
        """Test handling names with punctuation."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_name

        result = _extract_name("My name is John!")
        assert result == "John"


class TestExtractAge:
    """Tests for _extract_age function."""

    def test_extracts_age_with_years_old(self):
        """Test extracting age from 'X years old' pattern."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_age

        assert _extract_age("I'm 25 years old") == 25
        assert _extract_age("25 years old") == 25

    def test_extracts_age_with_im(self):
        """Test extracting age from 'I'm X' pattern."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_age

        assert _extract_age("I'm 30") == 30

    def test_extracts_just_number(self):
        """Test extracting just a number as age."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_age

        assert _extract_age("28") == 28

    def test_validates_age_range(self):
        """Test that age is validated within range."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_age

        assert _extract_age("5") is None  # Too young
        assert _extract_age("150") is None  # Too old
        assert _extract_age("13") == 13  # Minimum
        assert _extract_age("100") == 100  # Maximum


class TestExtractGender:
    """Tests for _extract_gender function."""

    def test_extracts_male(self):
        """Test extracting male gender."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_gender

        assert _extract_gender("male") == "male"
        assert _extract_gender("I'm a man") == "male"
        assert _extract_gender("m") == "male"
        assert _extract_gender("guy") == "male"

    def test_extracts_female(self):
        """Test extracting female gender."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_gender

        assert _extract_gender("female") == "female"
        assert _extract_gender("I'm a woman") == "female"
        assert _extract_gender("f") == "female"
        assert _extract_gender("girl") == "female"

    def test_returns_none_for_ambiguous(self):
        """Test returning None for ambiguous input."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_gender

        assert _extract_gender("hello") is None
        assert _extract_gender("I like fitness") is None


class TestExtractHeight:
    """Tests for _extract_height function."""

    def test_extracts_cm(self):
        """Test extracting height in centimeters."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_height

        assert _extract_height("170 cm") == 170
        assert _extract_height("180cm") == 180

    def test_extracts_meters(self):
        """Test extracting height in meters."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_height

        assert _extract_height("1.75m") == 175
        assert _extract_height("1,80 meters") == 180

    def test_extracts_feet_inches(self):
        """Test extracting height in feet and inches."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_height

        result = _extract_height("5'10")
        assert result is not None
        assert 175 <= result <= 180  # Approximately 177.8 cm

    def test_validates_height_range(self):
        """Test that height is validated within range."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_height

        assert _extract_height("50 cm") is None  # Too short
        assert _extract_height("300 cm") is None  # Too tall


class TestExtractWeight:
    """Tests for _extract_weight function."""

    def test_extracts_kg(self):
        """Test extracting weight in kilograms."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_weight

        assert _extract_weight("70 kg") == 70.0
        assert _extract_weight("75.5kg") == 75.5

    def test_extracts_lbs(self):
        """Test extracting weight in pounds."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_weight

        result = _extract_weight("150 lbs")
        assert result is not None
        assert 67 <= result <= 69  # Approximately 68 kg

    def test_extracts_weigh_pattern(self):
        """Test extracting from 'weigh X' pattern."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_weight

        assert _extract_weight("I weigh 80kg") == 80.0

    def test_validates_weight_range(self):
        """Test that weight is validated within range."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_weight

        assert _extract_weight("20 kg") is None  # Too light
        assert _extract_weight("400 kg") is None  # Too heavy


class TestExtractDaysPerWeek:
    """Tests for _extract_days_per_week function."""

    def test_extracts_single_digit(self):
        """Test extracting single digit days."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_days_per_week

        assert _extract_days_per_week("3") == 3
        assert _extract_days_per_week("5") == 5

    def test_extracts_with_days_text(self):
        """Test extracting with 'X days' text."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_days_per_week

        assert _extract_days_per_week("4 days") == 4

    def test_validates_range(self):
        """Test that days are within 1-7 range."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_days_per_week

        assert _extract_days_per_week("0") is None
        assert _extract_days_per_week("8") is None


class TestExtractSelectedDays:
    """Tests for _extract_selected_days function."""

    def test_extracts_day_names(self):
        """Test extracting day names."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_selected_days

        result = _extract_selected_days("Monday, Wednesday, Friday")
        assert result == [0, 2, 4]

    def test_extracts_abbreviated_days(self):
        """Test extracting abbreviated day names."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_selected_days

        result = _extract_selected_days("Mon, Wed, Fri")
        assert result == [0, 2, 4]

    def test_handles_single_day(self):
        """Test extracting single day."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_selected_days

        result = _extract_selected_days("Saturday")
        assert result == [5]

    def test_returns_sorted_indices(self):
        """Test that indices are returned sorted."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_selected_days

        result = _extract_selected_days("Friday, Monday, Wednesday")
        assert result == [0, 2, 4]  # Sorted


class TestExtractEquipment:
    """Tests for _extract_equipment function."""

    def test_extracts_full_gym(self):
        """Test extracting full gym."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_equipment

        result = _extract_equipment("full gym")
        assert "Full Gym" in result

    def test_extracts_dumbbells(self):
        """Test extracting dumbbells."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_equipment

        result = _extract_equipment("I have dumbbells")
        assert "Dumbbells" in result

    def test_extracts_multiple(self):
        """Test extracting multiple equipment types."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_equipment

        result = _extract_equipment("dumbbells and resistance bands")
        assert "Dumbbells" in result
        assert "Resistance Bands" in result

    def test_merges_with_existing(self):
        """Test merging with existing equipment."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_equipment

        result = _extract_equipment("barbell", ["Dumbbells"])
        assert "Dumbbells" in result
        assert "Barbell" in result


class TestExtractGoals:
    """Tests for _extract_goals function."""

    def test_extracts_build_muscle(self):
        """Test extracting build muscle goal."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_goals

        result = _extract_goals("I want to build muscle")
        assert "Build Muscle" in result

    def test_extracts_lose_weight(self):
        """Test extracting lose weight goal."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_goals

        result = _extract_goals("I want to lose weight")
        assert "Lose Weight" in result

    def test_extracts_multiple(self):
        """Test extracting multiple goals."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_goals

        result = _extract_goals("build muscle and get stronger")
        assert "Build Muscle" in result
        assert "Increase Strength" in result


class TestExtractFitnessLevel:
    """Tests for _extract_fitness_level function."""

    def test_extracts_beginner(self):
        """Test extracting beginner level."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_fitness_level

        assert _extract_fitness_level("beginner") == "beginner"
        assert _extract_fitness_level("newbie") == "beginner"

    def test_extracts_intermediate(self):
        """Test extracting intermediate level."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_fitness_level

        assert _extract_fitness_level("intermediate") == "intermediate"

    def test_extracts_advanced(self):
        """Test extracting advanced level."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_fitness_level

        assert _extract_fitness_level("advanced") == "advanced"
        assert _extract_fitness_level("pro") == "advanced"


class TestExtractTrainingExperience:
    """Tests for _extract_training_experience function."""

    def test_extracts_never(self):
        """Test extracting never experience."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_training_experience

        assert _extract_training_experience("never") == "never"
        assert _extract_training_experience("first time") == "never"

    def test_extracts_less_than_6_months(self):
        """Test extracting less than 6 months experience."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_training_experience

        assert _extract_training_experience("few months") == "less_than_6_months"

    def test_extracts_5_plus_years(self):
        """Test extracting 5+ years experience."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_training_experience

        assert _extract_training_experience("5+ years") == "5_plus_years"
        assert _extract_training_experience("decade") == "5_plus_years"


class TestExtractWorkoutEnvironment:
    """Tests for _extract_workout_environment function."""

    def test_extracts_commercial_gym(self):
        """Test extracting commercial gym."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_workout_environment

        assert _extract_workout_environment("commercial gym") == "commercial_gym"
        assert _extract_workout_environment("gym") == "commercial_gym"

    def test_extracts_home_gym(self):
        """Test extracting home gym."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_workout_environment

        assert _extract_workout_environment("home gym") == "home_gym"
        assert _extract_workout_environment("garage gym") == "home_gym"

    def test_extracts_outdoors(self):
        """Test extracting outdoors."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_workout_environment

        assert _extract_workout_environment("outdoors") == "outdoors"
        assert _extract_workout_environment("park") == "outdoors"


class TestExtractFocusAreas:
    """Tests for _extract_focus_areas function."""

    def test_extracts_single_area(self):
        """Test extracting single focus area."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_focus_areas

        result = _extract_focus_areas("chest")
        assert "chest" in result

    def test_extracts_multiple_areas(self):
        """Test extracting multiple focus areas."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_focus_areas

        result = _extract_focus_areas("chest and back")
        assert "chest" in result
        assert "back" in result

    def test_maps_aliases(self):
        """Test that aliases are mapped correctly."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_focus_areas

        result = _extract_focus_areas("pecs")
        assert "chest" in result

        result = _extract_focus_areas("abs")
        assert "core" in result


class TestExtractWorkoutVariety:
    """Tests for _extract_workout_variety function."""

    def test_extracts_consistent(self):
        """Test extracting consistent preference."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_workout_variety

        assert _extract_workout_variety("consistent") == "consistent"
        assert _extract_workout_variety("same exercises") == "consistent"

    def test_extracts_varied(self):
        """Test extracting varied preference."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_workout_variety

        assert _extract_workout_variety("variety") == "varied"
        assert _extract_workout_variety("mix it up") == "varied"

    def test_extracts_mixed(self):
        """Test extracting mixed preference."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_workout_variety

        assert _extract_workout_variety("both") == "mixed"


class TestExtractBiggestObstacle:
    """Tests for _extract_biggest_obstacle function."""

    def test_extracts_time(self):
        """Test extracting time obstacle."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_biggest_obstacle

        assert _extract_biggest_obstacle("time") == "time"
        assert _extract_biggest_obstacle("busy schedule") == "time"

    def test_extracts_motivation(self):
        """Test extracting motivation obstacle."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_biggest_obstacle

        assert _extract_biggest_obstacle("motivation") == "motivation"
        assert _extract_biggest_obstacle("feeling lazy") == "motivation"

    def test_extracts_consistency(self):
        """Test extracting consistency obstacle."""
        from services.langgraph_agents.onboarding.nodes.extraction import _extract_biggest_obstacle

        assert _extract_biggest_obstacle("consistency") == "consistency"
