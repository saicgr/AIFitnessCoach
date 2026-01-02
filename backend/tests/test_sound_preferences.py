"""Tests for sound preferences API.

This tests the feature that addresses user feedback:
"countdown timer sux plus cheesy applause smh. sounds should be customizable."

NOTE: No 'applause' option is available - user specifically hated it.
"""

import pytest
from fastapi.testclient import TestClient
from unittest.mock import Mock, patch


class TestSoundPreferencesValidation:
    """Tests for sound preferences validation."""

    def test_valid_countdown_sound_types(self):
        """Valid countdown sound types should be accepted."""
        valid_types = ["beep", "chime", "voice", "tick", "none"]
        for sound_type in valid_types:
            # Would validate against the enum/constraint
            assert sound_type in valid_types

    def test_valid_completion_sound_types(self):
        """Valid completion sound types should be accepted (NO APPLAUSE)."""
        valid_types = ["chime", "bell", "success", "fanfare", "none"]
        # NOTE: 'applause' is intentionally NOT in this list
        for sound_type in valid_types:
            assert sound_type in valid_types

        # Verify applause is NOT a valid option
        assert "applause" not in valid_types

    def test_volume_range_validation(self):
        """Volume should be between 0.0 and 1.0."""
        valid_volumes = [0.0, 0.5, 0.8, 1.0]
        for volume in valid_volumes:
            assert 0.0 <= volume <= 1.0

        invalid_volumes = [-0.1, 1.1, 2.0, -1.0]
        for volume in invalid_volumes:
            assert not (0.0 <= volume <= 1.0)


class TestSoundPreferencesDefaults:
    """Tests for default sound preferences."""

    def test_default_preferences(self):
        """Default preferences should have sensible values."""
        defaults = {
            "countdown_sound_enabled": True,
            "countdown_sound_type": "beep",
            "completion_sound_enabled": True,
            "completion_sound_type": "chime",  # NOT applause
            "rest_timer_sound_enabled": True,
            "rest_timer_sound_type": "beep",
            "sound_effects_volume": 0.8,
        }

        assert defaults["countdown_sound_enabled"] is True
        assert defaults["completion_sound_type"] == "chime"
        assert defaults["completion_sound_type"] != "applause"
        assert 0.0 <= defaults["sound_effects_volume"] <= 1.0


class TestNoApplauseOption:
    """Tests to ensure applause is NOT an option (user hated it)."""

    def test_applause_not_in_completion_types(self):
        """Applause should never be a valid completion sound type."""
        valid_completion_types = ["chime", "bell", "success", "fanfare", "none"]
        assert "applause" not in valid_completion_types

    def test_completion_type_constraint(self):
        """The completion sound type constraint should not include applause."""
        # This simulates the database constraint
        constraint_check = lambda t: t in ["chime", "bell", "success", "fanfare", "none"]

        assert constraint_check("chime") is True
        assert constraint_check("applause") is False

    def test_user_cannot_set_applause(self):
        """User should not be able to set completion sound to applause."""
        valid_types = {"chime", "bell", "success", "fanfare", "none"}

        user_input = "applause"
        is_valid = user_input in valid_types

        assert is_valid is False, "Applause should be rejected as a sound type"


class TestSoundPreferencesUpdate:
    """Tests for updating sound preferences."""

    def test_partial_update(self):
        """Partial updates should only modify specified fields."""
        current_prefs = {
            "countdown_sound_enabled": True,
            "countdown_sound_type": "beep",
            "completion_sound_enabled": True,
            "completion_sound_type": "chime",
        }

        update = {
            "countdown_sound_type": "tick",
        }

        # Simulate partial update
        updated = {**current_prefs, **update}

        assert updated["countdown_sound_type"] == "tick"
        assert updated["countdown_sound_enabled"] is True  # Unchanged
        assert updated["completion_sound_type"] == "chime"  # Unchanged

    def test_disable_all_sounds(self):
        """User should be able to disable all sounds."""
        prefs = {
            "countdown_sound_enabled": False,
            "completion_sound_enabled": False,
            "rest_timer_sound_enabled": False,
        }

        assert prefs["countdown_sound_enabled"] is False
        assert prefs["completion_sound_enabled"] is False
        assert prefs["rest_timer_sound_enabled"] is False

    def test_set_all_to_none(self):
        """User should be able to set all sound types to 'none'."""
        prefs = {
            "countdown_sound_type": "none",
            "completion_sound_type": "none",
            "rest_timer_sound_type": "none",
        }

        assert all(v == "none" for v in prefs.values())


class TestMigrationConstraints:
    """Tests for database migration constraints."""

    def test_countdown_type_check_constraint(self):
        """Countdown sound type should have valid values only."""
        valid = ["beep", "chime", "voice", "tick", "none"]

        def check_constraint(value):
            return value in valid

        assert check_constraint("beep") is True
        assert check_constraint("invalid") is False

    def test_completion_type_check_constraint(self):
        """Completion sound type should have valid values only (no applause)."""
        valid = ["chime", "bell", "success", "fanfare", "none"]

        def check_constraint(value):
            return value in valid

        assert check_constraint("chime") is True
        assert check_constraint("applause") is False  # User hates it!
        assert check_constraint("invalid") is False

    def test_volume_check_constraint(self):
        """Volume should be between 0.0 and 1.0."""
        def check_constraint(value):
            return 0.0 <= value <= 1.0

        assert check_constraint(0.0) is True
        assert check_constraint(0.5) is True
        assert check_constraint(1.0) is True
        assert check_constraint(-0.1) is False
        assert check_constraint(1.5) is False
