"""
Tests for field detection from AI responses.

These tests ensure that quick replies are shown consistently regardless
of which coach persona is selected. Each coach has a different communication
style, but the field detection must work for all of them.

Coach Personas:
- Coach Mike: Motivational, bro-style ("Let's crush it!")
- Dr. Sarah: Professional, science-based ("Based on research...")
- Sergeant Max: Military, direct ("Drop and give me 20!")
- Zen Maya: Calm, mindful ("Take a breath...")
- Hype Danny: Energetic, enthusiastic ("YOOO!")
"""

import pytest
from services.langgraph_agents.onboarding.nodes.utils import detect_field_from_response


class TestTrainingExperienceDetection:
    """
    Test training_experience field detection across all coach styles.

    This field asks: "How long have you been training/lifting?"
    """

    # Coach Mike (Motivational bro)
    def test_coach_mike_training_experience(self):
        assert detect_field_from_response("How long have you been crushing it at the gym, bro?") == "training_experience"
        assert detect_field_from_response("Been lifting long?") == "training_experience"
        assert detect_field_from_response("What's your training history like?") == "training_experience"

    # Dr. Sarah (Professional)
    def test_dr_sarah_training_experience(self):
        assert detect_field_from_response("What's your training background?") == "training_experience"
        assert detect_field_from_response("How many years of lifting experience do you have?") == "training_experience"
        assert detect_field_from_response("Could you share your gym experience level?") == "training_experience"

    # Sergeant Max (Military)
    def test_sergeant_max_training_experience(self):
        assert detect_field_from_response("Soldier! How long have you been training?") == "training_experience"
        assert detect_field_from_response("Report your years of training!") == "training_experience"
        assert detect_field_from_response("Been at this long, recruit?") == "training_experience"

    # Zen Maya (Calm)
    def test_zen_maya_training_experience(self):
        assert detect_field_from_response("Tell me about your fitness journey so far.") == "training_experience"
        assert detect_field_from_response("How long have you been on this training journey?") == "training_experience"
        assert detect_field_from_response("Are you new to lifting, or have you been practicing?") == "training_experience"

    # Hype Danny (Energetic)
    def test_hype_danny_training_experience(self):
        assert detect_field_from_response("YOOO how long have you been lifting?!") == "training_experience"
        assert detect_field_from_response("What's your gym experience like?!") == "training_experience"
        assert detect_field_from_response("Been training long or new to the gym?!") == "training_experience"


class TestPastProgramsDetection:
    """
    Test past_programs field detection across all coach styles.

    This field asks: "What workout programs have you tried before?"
    """

    def test_coach_mike_past_programs(self):
        assert detect_field_from_response("Ever followed a program like PPL or bro split?") == "past_programs"
        assert detect_field_from_response("What programs have you tried before?") == "past_programs"
        assert detect_field_from_response("Done Starting Strength or StrongLifts?") == "past_programs"

    def test_dr_sarah_past_programs(self):
        assert detect_field_from_response("What structured programs have you followed?") == "past_programs"
        assert detect_field_from_response("Have you done push pull legs before?") == "past_programs"
        assert detect_field_from_response("What workout routines have you tried before?") == "past_programs"

    def test_sergeant_max_past_programs(self):
        assert detect_field_from_response("Ever followed a program, soldier?") == "past_programs"
        assert detect_field_from_response("What programs have you done before, recruit?") == "past_programs"

    def test_zen_maya_past_programs(self):
        assert detect_field_from_response("What programs have you explored in your journey?") == "past_programs"
        assert detect_field_from_response("Have you followed any structured programs before?") == "past_programs"

    def test_hype_danny_past_programs(self):
        assert detect_field_from_response("WHAT programs have you tried before?!") == "past_programs"
        assert detect_field_from_response("Ever done PPL or bro split?!") == "past_programs"


class TestWorkoutDurationDetection:
    """
    Test workout_duration field detection across all coach styles.

    This field asks: "How long per workout - 30, 45, 60, or 90 min?"
    """

    def test_coach_mike_duration(self):
        assert detect_field_from_response("How long per workout - 30, 45, 60, or 90 min?") == "workout_duration"
        assert detect_field_from_response("What's your ideal session length?") == "workout_duration"
        assert detect_field_from_response("How much time per workout?") == "workout_duration"

    def test_dr_sarah_duration(self):
        assert detect_field_from_response("What workout duration works best for you?") == "workout_duration"
        assert detect_field_from_response("How long do you want your sessions to be?") == "workout_duration"
        assert detect_field_from_response("30, 45, 60, or 90 minutes per session?") == "workout_duration"

    def test_sergeant_max_duration(self):
        assert detect_field_from_response("How long per session, soldier? 30, 45, 60, 90?") == "workout_duration"
        assert detect_field_from_response("Report your preferred workout time!") == "workout_duration"

    def test_zen_maya_duration(self):
        assert detect_field_from_response("How much time would you like to dedicate per workout?") == "workout_duration"
        assert detect_field_from_response("What duration feels right for your practice?") == "workout_duration"

    def test_hype_danny_duration(self):
        assert detect_field_from_response("How long you wanna GO?! 30, 45, 60, 90?!") == "workout_duration"
        assert detect_field_from_response("What's your workout time looking like?!") == "workout_duration"


class TestTargetWeightDetection:
    """
    Test target_weight_kg field detection across all coach styles.

    This field asks: "Any target weight in mind, or happy where you are?"
    """

    def test_coach_mike_target_weight(self):
        assert detect_field_from_response("Any target weight in mind, or happy where you are?") == "target_weight_kg"
        assert detect_field_from_response("Got a weight goal?") == "target_weight_kg"
        assert detect_field_from_response("Want to lose some weight or gain?") == "target_weight_kg"

    def test_dr_sarah_target_weight(self):
        assert detect_field_from_response("Do you have a target weight in mind?") == "target_weight_kg"
        assert detect_field_from_response("What's your ideal weight goal?") == "target_weight_kg"
        assert detect_field_from_response("Are you happy where you are, weight-wise?") == "target_weight_kg"

    def test_sergeant_max_target_weight(self):
        assert detect_field_from_response("Target weight, soldier?!") == "target_weight_kg"
        assert detect_field_from_response("How many pounds to lose?") == "target_weight_kg"

    def test_zen_maya_target_weight(self):
        assert detect_field_from_response("Is there a weight you'd like to work towards?") == "target_weight_kg"
        assert detect_field_from_response("Do you have a weight goal in mind, or are you content?") == "target_weight_kg"

    def test_hype_danny_target_weight(self):
        assert detect_field_from_response("WEIGHT GOAL?! What's the target?!") == "target_weight_kg"
        assert detect_field_from_response("Wanna gain some weight or lose some?!") == "target_weight_kg"


class TestFocusAreasDetection:
    """
    Test focus_areas field detection across all coach styles.

    This field asks: "Any muscles to prioritize, or full body?"
    """

    def test_coach_mike_focus_areas(self):
        assert detect_field_from_response("Any muscles to prioritize, or full body?") == "focus_areas"
        assert detect_field_from_response("Which muscle groups you wanna hit?") == "focus_areas"
        assert detect_field_from_response("Got any focus areas in mind?") == "focus_areas"

    def test_dr_sarah_focus_areas(self):
        assert detect_field_from_response("Are there specific muscle groups you'd like to emphasize?") == "focus_areas"
        assert detect_field_from_response("Any areas to focus on, or balanced training?") == "focus_areas"
        assert detect_field_from_response("Which body parts would you like to target?") == "focus_areas"

    def test_sergeant_max_focus_areas(self):
        assert detect_field_from_response("Target muscle groups, soldier?") == "focus_areas"
        assert detect_field_from_response("What areas to focus on, recruit?") == "focus_areas"

    def test_zen_maya_focus_areas(self):
        assert detect_field_from_response("Are there areas you'd like to prioritize in your practice?") == "focus_areas"
        assert detect_field_from_response("Any muscle groups you want to target?") == "focus_areas"

    def test_hype_danny_focus_areas(self):
        assert detect_field_from_response("WHAT MUSCLES you wanna HIT?!") == "focus_areas"
        assert detect_field_from_response("Any priority muscle groups?!") == "focus_areas"


class TestWorkoutVarietyDetection:
    """
    Test workout_variety field detection across all coach styles.

    This field asks: "Prefer same exercises each week or mix it up?"
    """

    def test_coach_mike_variety(self):
        assert detect_field_from_response("Prefer same exercises each week or mix it up?") == "workout_variety"
        assert detect_field_from_response("Want a consistent routine or switch things up?") == "workout_variety"

    def test_dr_sarah_variety(self):
        assert detect_field_from_response("Do you prefer exercise variety or consistency?") == "workout_variety"
        assert detect_field_from_response("Same workout structure or different workouts each week?") == "workout_variety"

    def test_sergeant_max_variety(self):
        assert detect_field_from_response("Same exercises or mix it up, soldier?") == "workout_variety"
        assert detect_field_from_response("Consistent routine or variety?") == "workout_variety"

    def test_zen_maya_variety(self):
        assert detect_field_from_response("Would you prefer to keep it fresh each week, or a consistent routine?") == "workout_variety"
        assert detect_field_from_response("Do you enjoy routine variety or familiar exercises?") == "workout_variety"

    def test_hype_danny_variety(self):
        assert detect_field_from_response("Same exercises or SWITCH THINGS UP?!") == "workout_variety"
        assert detect_field_from_response("Keep it fresh or stick with the same workout?!") == "workout_variety"


class TestBiggestObstacleDetection:
    """
    Test biggest_obstacle field detection across all coach styles.

    This field asks: "What's been your biggest barrier to consistency?"
    """

    def test_coach_mike_obstacle(self):
        assert detect_field_from_response("What's been your biggest barrier to consistency?") == "biggest_obstacle"
        assert detect_field_from_response("What's the biggest challenge you face?") == "biggest_obstacle"
        assert detect_field_from_response("What's been holding you back?") == "biggest_obstacle"

    def test_dr_sarah_obstacle(self):
        assert detect_field_from_response("What obstacle has prevented consistency?") == "biggest_obstacle"
        assert detect_field_from_response("What's your biggest struggle with training?") == "biggest_obstacle"

    def test_sergeant_max_obstacle(self):
        assert detect_field_from_response("What's your biggest challenge, soldier?") == "biggest_obstacle"
        assert detect_field_from_response("What barrier stops you from training?") == "biggest_obstacle"

    def test_zen_maya_obstacle(self):
        assert detect_field_from_response("What has been your biggest obstacle on this journey?") == "biggest_obstacle"
        assert detect_field_from_response("What gets in the way of your practice?") == "biggest_obstacle"

    def test_hype_danny_obstacle(self):
        assert detect_field_from_response("What's the BIGGEST thing holding you back?!") == "biggest_obstacle"
        assert detect_field_from_response("What's been the challenge?!") == "biggest_obstacle"


class TestSelectedDaysDetection:
    """
    Test selected_days field detection across all coach styles.
    """

    def test_coach_mike_selected_days(self):
        assert detect_field_from_response("Which days work for you?") == "selected_days"
        assert detect_field_from_response("What days do you prefer to train?") == "selected_days"

    def test_dr_sarah_selected_days(self):
        assert detect_field_from_response("Which days of the week would you like to train?") == "selected_days"
        assert detect_field_from_response("Pick your workout days.") == "selected_days"

    def test_sergeant_max_selected_days(self):
        assert detect_field_from_response("Which days, soldier?") == "selected_days"
        assert detect_field_from_response("Choose your days, recruit!") == "selected_days"

    def test_zen_maya_selected_days(self):
        assert detect_field_from_response("Which days feel right for your practice?") == "selected_days"
        assert detect_field_from_response("Select the days that work for you.") == "selected_days"

    def test_hype_danny_selected_days(self):
        assert detect_field_from_response("WHAT DAYS are we crushing it?!") == "selected_days"
        assert detect_field_from_response("Which days work for you?!") == "selected_days"


class TestNoFalsePositives:
    """
    Test that field detection doesn't have false positives.

    These responses should NOT trigger field detection for the wrong field.
    """

    def test_completion_message_no_detection(self):
        """Completion messages shouldn't trigger quick replies for data fields."""
        # These are completion/acknowledgment messages, not questions
        assert detect_field_from_response("Perfect! Building your plan now. Let's crush it!") is None
        assert detect_field_from_response("Got it! We're all set.") is None
        assert detect_field_from_response("Awesome, ready to go!") is None

    def test_acknowledgment_no_wrong_field(self):
        """Acknowledgments of answers shouldn't trigger wrong fields."""
        # "Got it" followed by next question
        result = detect_field_from_response("Got it! How long per workout - 30, 45, 60?")
        assert result == "workout_duration"

    def test_training_vs_programs(self):
        """Training experience vs past programs - must differentiate."""
        # Training experience = how LONG they've been training
        assert detect_field_from_response("How long have you been lifting?") == "training_experience"
        # Past programs = WHAT programs they've done
        assert detect_field_from_response("What programs have you tried before?") == "past_programs"

    def test_focus_vs_variety(self):
        """Focus areas vs variety - must differentiate."""
        # Focus areas = which MUSCLES
        assert detect_field_from_response("Any muscles to prioritize?") == "focus_areas"
        # Variety = same exercises or mix it up
        assert detect_field_from_response("Same exercises or mix it up?") == "workout_variety"


class TestQuickReplyMapping:
    """
    Test that detected fields have corresponding quick replies in QUICK_REPLIES.
    """

    def test_all_detected_fields_have_quick_replies(self):
        """Every field we detect should have quick replies defined."""
        from services.langgraph_agents.onboarding.prompts import QUICK_REPLIES

        detectable_fields = [
            "training_experience",
            "past_programs",
            "workout_duration",
            "target_weight_kg",
            "focus_areas",
            "workout_variety",
            "biggest_obstacle",
            "selected_days",
            "equipment",
            "goals",
            "fitness_level",
        ]

        for field in detectable_fields:
            assert field in QUICK_REPLIES, f"Field {field} has no quick replies defined"
            assert len(QUICK_REPLIES[field]) > 0, f"Field {field} has empty quick replies"
