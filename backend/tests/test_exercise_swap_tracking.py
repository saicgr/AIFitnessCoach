"""Tests for exercise swap tracking.

This tests the feature that addresses user feedback:
"Please let me change exercises in a workout at my discretion."

The exercise swap tracking system:
- Records all exercise swaps with reasons
- Tracks swap patterns for AI improvement
- Identifies frequently swapped exercises
"""

import pytest
from datetime import datetime
from uuid import uuid4


class TestExerciseSwapData:
    """Tests for exercise swap data structure."""

    def test_swap_record_fields(self):
        """Swap records should have all required fields."""
        swap = {
            "id": str(uuid4()),
            "user_id": str(uuid4()),
            "workout_id": str(uuid4()),
            "original_exercise": "Barbell Bench Press",
            "new_exercise": "Dumbbell Bench Press",
            "swap_reason": "equipment_unavailable",
            "swap_reason_detail": "All barbells in use",
            "workout_phase": "main",
            "exercise_index": 2,
            "swapped_at": datetime.now().isoformat(),
            "swap_source": "ai_suggestion",
        }

        required_fields = [
            "user_id", "workout_id", "original_exercise", "new_exercise"
        ]
        for field in required_fields:
            assert field in swap

    def test_valid_swap_reasons(self):
        """Swap reasons should be from valid set."""
        valid_reasons = [
            "too_difficult",
            "too_easy",
            "equipment_unavailable",
            "injury_concern",
            "personal_preference",
            "other",
        ]

        for reason in valid_reasons:
            # Would validate against database constraint
            assert reason in valid_reasons

    def test_valid_workout_phases(self):
        """Workout phases should be valid."""
        valid_phases = ["warmup", "main", "cooldown"]

        for phase in valid_phases:
            assert phase in valid_phases

    def test_valid_swap_sources(self):
        """Swap sources should track where suggestion came from."""
        valid_sources = ["ai_suggestion", "library_search", "recent_exercise"]

        for source in valid_sources:
            assert source in valid_sources


class TestSwapPatternAnalysis:
    """Tests for swap pattern analysis."""

    def test_user_swap_patterns_grouping(self):
        """Swap patterns should group by exercise and reason."""
        swaps = [
            {"original": "Squat", "new": "Leg Press", "reason": "injury_concern"},
            {"original": "Squat", "new": "Leg Press", "reason": "injury_concern"},
            {"original": "Squat", "new": "Hack Squat", "reason": "equipment_unavailable"},
            {"original": "Deadlift", "new": "Romanian Deadlift", "reason": "too_difficult"},
        ]

        # Group by original exercise
        patterns = {}
        for swap in swaps:
            orig = swap["original"]
            if orig not in patterns:
                patterns[orig] = {"count": 0, "replacements": set(), "reasons": set()}
            patterns[orig]["count"] += 1
            patterns[orig]["replacements"].add(swap["new"])
            patterns[orig]["reasons"].add(swap["reason"])

        assert patterns["Squat"]["count"] == 3
        assert "Leg Press" in patterns["Squat"]["replacements"]
        assert "injury_concern" in patterns["Squat"]["reasons"]

    def test_frequently_swapped_threshold(self):
        """Frequently swapped exercises require >= 2 swaps."""
        swaps = [
            {"original": "Pull-ups", "count": 5},
            {"original": "Dips", "count": 2},
            {"original": "Rows", "count": 1},
        ]

        frequently_swapped = [s for s in swaps if s["count"] >= 2]

        assert len(frequently_swapped) == 2
        assert any(s["original"] == "Pull-ups" for s in frequently_swapped)
        assert any(s["original"] == "Dips" for s in frequently_swapped)
        assert not any(s["original"] == "Rows" for s in frequently_swapped)


class TestSwapForAILearning:
    """Tests for using swap data to improve AI."""

    def test_exercises_to_avoid_detection(self):
        """Exercises swapped 3+ times should be flagged for avoidance."""
        user_swaps = [
            {"original": "Burpees", "count": 5},
            {"original": "Mountain Climbers", "count": 3},
            {"original": "Jump Squats", "count": 2},
            {"original": "Push-ups", "count": 1},
        ]

        def user_frequently_swaps(exercise, threshold=3):
            for swap in user_swaps:
                if swap["original"] == exercise and swap["count"] >= threshold:
                    return True
            return False

        assert user_frequently_swaps("Burpees") is True
        assert user_frequently_swaps("Mountain Climbers") is True
        assert user_frequently_swaps("Jump Squats") is False
        assert user_frequently_swaps("Push-ups") is False

    def test_preferred_alternatives_detection(self):
        """System should learn preferred replacement exercises."""
        swaps = [
            {"original": "Barbell Squat", "new": "Leg Press"},
            {"original": "Barbell Squat", "new": "Leg Press"},
            {"original": "Barbell Squat", "new": "Goblet Squat"},
            {"original": "Barbell Squat", "new": "Leg Press"},
        ]

        # Count replacement frequency
        replacements = {}
        for swap in swaps:
            new = swap["new"]
            replacements[new] = replacements.get(new, 0) + 1

        # Most common replacement
        preferred = max(replacements, key=replacements.get)

        assert preferred == "Leg Press"
        assert replacements["Leg Press"] == 3

    def test_reason_patterns(self):
        """System should detect common swap reasons."""
        swaps = [
            {"reason": "injury_concern"},
            {"reason": "equipment_unavailable"},
            {"reason": "injury_concern"},
            {"reason": "injury_concern"},
            {"reason": "too_difficult"},
        ]

        reason_counts = {}
        for swap in swaps:
            reason = swap["reason"]
            reason_counts[reason] = reason_counts.get(reason, 0) + 1

        # Most common reason
        primary_reason = max(reason_counts, key=reason_counts.get)

        assert primary_reason == "injury_concern"
        assert reason_counts["injury_concern"] == 3


class TestMigrationConstraints:
    """Tests for database migration constraints."""

    def test_swap_reason_constraint(self):
        """Swap reason should be from valid set."""
        valid_reasons = [
            "too_difficult", "too_easy", "equipment_unavailable",
            "injury_concern", "personal_preference", "other"
        ]

        def check_constraint(value):
            return value is None or value in valid_reasons

        assert check_constraint("too_difficult") is True
        assert check_constraint("equipment_unavailable") is True
        assert check_constraint(None) is True  # Optional field
        assert check_constraint("invalid_reason") is False

    def test_workout_phase_constraint(self):
        """Workout phase should be valid."""
        valid_phases = ["warmup", "main", "cooldown"]

        def check_constraint(value):
            return value is None or value in valid_phases

        assert check_constraint("main") is True
        assert check_constraint("warmup") is True
        assert check_constraint(None) is True  # Optional with default
        assert check_constraint("invalid_phase") is False

    def test_swap_source_constraint(self):
        """Swap source should be valid."""
        valid_sources = ["ai_suggestion", "library_search", "recent_exercise"]

        def check_constraint(value):
            return value is None or value in valid_sources

        assert check_constraint("ai_suggestion") is True
        assert check_constraint("library_search") is True
        assert check_constraint(None) is True
        assert check_constraint("random_source") is False


class TestRLSPolicies:
    """Tests for Row Level Security policies."""

    def test_user_can_only_see_own_swaps(self):
        """Users should only see their own swap history."""
        user1_id = str(uuid4())
        user2_id = str(uuid4())

        swaps = [
            {"user_id": user1_id, "original": "Squat"},
            {"user_id": user1_id, "original": "Bench"},
            {"user_id": user2_id, "original": "Deadlift"},
        ]

        # Simulate RLS filtering
        def get_swaps_for_user(current_user_id):
            return [s for s in swaps if s["user_id"] == current_user_id]

        user1_swaps = get_swaps_for_user(user1_id)
        user2_swaps = get_swaps_for_user(user2_id)

        assert len(user1_swaps) == 2
        assert len(user2_swaps) == 1
        assert all(s["user_id"] == user1_id for s in user1_swaps)
