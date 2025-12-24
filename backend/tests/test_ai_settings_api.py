"""
Tests for AI Settings API endpoints.

Tests:
- Get AI settings
- Update AI settings
- AI settings history
- Reset AI settings
- Analytics endpoints

Run with: pytest backend/tests/test_ai_settings_api.py -v
"""

import pytest
from unittest.mock import MagicMock, patch
from datetime import datetime


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def mock_supabase_client():
    """Mock Supabase client for AI settings operations."""
    with patch("api.v1.ai_settings.get_supabase") as mock_get_supabase:
        mock_supabase = MagicMock()
        mock_client = MagicMock()
        mock_supabase.client = mock_client
        mock_get_supabase.return_value = mock_supabase
        yield mock_client


@pytest.fixture
def sample_user_id():
    return "user-123-abc"


@pytest.fixture
def sample_ai_settings():
    return {
        "id": "settings-1",
        "user_id": "user-123-abc",
        "coaching_style": "motivational",
        "communication_tone": "encouraging",
        "encouragement_level": 0.7,
        "response_length": "balanced",
        "use_emojis": True,
        "include_tips": True,
        "form_reminders": True,
        "rest_day_suggestions": True,
        "nutrition_mentions": True,
        "injury_sensitivity": True,
        "save_chat_history": True,
        "use_rag": True,
        "default_agent": "coach",
        "enabled_agents": {"coach": True, "nutrition": True, "workout": True},
        "created_at": "2025-01-01T00:00:00",
        "updated_at": "2025-01-01T00:00:00",
    }


@pytest.fixture
def sample_settings_history():
    return [
        {
            "id": "history-1",
            "setting_name": "coaching_style",
            "old_value": "friendly",
            "new_value": "motivational",
            "change_source": "app",
            "changed_at": "2025-01-10T10:00:00",
            "device_platform": "ios",
            "app_version": "1.0.0",
        },
        {
            "id": "history-2",
            "setting_name": "use_emojis",
            "old_value": "true",
            "new_value": "false",
            "change_source": "app",
            "changed_at": "2025-01-09T10:00:00",
            "device_platform": "android",
            "app_version": "1.0.0",
        },
    ]


# ============================================================
# GET AI SETTINGS TESTS
# ============================================================

class TestGetAISettings:
    """Test get AI settings endpoint."""

    def test_get_ai_settings_exists(self, mock_supabase_client, sample_user_id, sample_ai_settings):
        """Test getting existing AI settings."""
        from api.v1.ai_settings import get_ai_settings
        import asyncio

        mock_result = MagicMock()
        mock_result.data = [sample_ai_settings]
        mock_supabase_client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_result

        result = asyncio.get_event_loop().run_until_complete(
            get_ai_settings(sample_user_id)
        )

        assert result.user_id == sample_user_id
        assert result.coaching_style == "motivational"
        assert result.use_emojis is True

    def test_get_ai_settings_creates_default(self, mock_supabase_client, sample_user_id, sample_ai_settings):
        """Test creating default settings when none exist."""
        from api.v1.ai_settings import get_ai_settings
        import asyncio

        # First call returns empty, second returns created settings
        mock_empty_result = MagicMock()
        mock_empty_result.data = []

        mock_created_result = MagicMock()
        mock_created_result.data = [sample_ai_settings]

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_empty_result
        mock_supabase_client.table.return_value.insert.return_value.execute.return_value = mock_created_result

        result = asyncio.get_event_loop().run_until_complete(
            get_ai_settings(sample_user_id)
        )

        assert result.user_id == sample_user_id
        mock_supabase_client.table.return_value.insert.assert_called_once()

    def test_get_ai_settings_error(self, mock_supabase_client, sample_user_id):
        """Test error handling when getting settings."""
        from api.v1.ai_settings import get_ai_settings
        from fastapi import HTTPException
        import asyncio

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.execute.side_effect = Exception("Database error")

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                get_ai_settings(sample_user_id)
            )

        assert exc_info.value.status_code == 500


# ============================================================
# UPDATE AI SETTINGS TESTS
# ============================================================

class TestUpdateAISettings:
    """Test update AI settings endpoint."""

    def test_update_ai_settings_success(self, mock_supabase_client, sample_user_id, sample_ai_settings):
        """Test successful AI settings update."""
        from api.v1.ai_settings import update_ai_settings, AISettingsUpdate
        import asyncio

        # Current settings
        mock_current = MagicMock()
        mock_current.data = [sample_ai_settings]

        # Updated settings
        updated_settings = {**sample_ai_settings, "coaching_style": "strict", "updated_at": "2025-01-15T10:00:00"}
        mock_updated = MagicMock()
        mock_updated.data = [updated_settings]

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_current
        mock_supabase_client.table.return_value.update.return_value.eq.return_value.execute.return_value = mock_updated
        mock_supabase_client.table.return_value.insert.return_value.execute.return_value = MagicMock()

        request = AISettingsUpdate(
            coaching_style="strict",
            change_source="app",
            device_platform="ios"
        )

        result = asyncio.get_event_loop().run_until_complete(
            update_ai_settings(sample_user_id, request)
        )

        assert result.coaching_style == "strict"

    def test_update_ai_settings_tracks_history(self, mock_supabase_client, sample_user_id, sample_ai_settings):
        """Test that updates are tracked in history."""
        from api.v1.ai_settings import update_ai_settings, AISettingsUpdate
        import asyncio

        mock_current = MagicMock()
        mock_current.data = [sample_ai_settings]

        updated_settings = {**sample_ai_settings, "use_emojis": False}
        mock_updated = MagicMock()
        mock_updated.data = [updated_settings]

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_current
        mock_supabase_client.table.return_value.update.return_value.eq.return_value.execute.return_value = mock_updated
        mock_supabase_client.table.return_value.insert.return_value.execute.return_value = MagicMock()

        request = AISettingsUpdate(use_emojis=False)

        asyncio.get_event_loop().run_until_complete(
            update_ai_settings(sample_user_id, request)
        )

        # Verify history was recorded (insert was called for ai_settings_history)
        insert_calls = mock_supabase_client.table.return_value.insert.call_args_list
        assert len(insert_calls) > 0

    def test_update_ai_settings_creates_new(self, mock_supabase_client, sample_user_id, sample_ai_settings):
        """Test creating new settings if none exist."""
        from api.v1.ai_settings import update_ai_settings, AISettingsUpdate
        import asyncio

        mock_empty = MagicMock()
        mock_empty.data = []

        mock_created = MagicMock()
        mock_created.data = [sample_ai_settings]

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_empty
        mock_supabase_client.table.return_value.insert.return_value.execute.return_value = mock_created

        request = AISettingsUpdate(coaching_style="friendly")

        result = asyncio.get_event_loop().run_until_complete(
            update_ai_settings(sample_user_id, request)
        )

        assert result is not None


# ============================================================
# SETTINGS HISTORY TESTS
# ============================================================

class TestSettingsHistory:
    """Test AI settings history endpoint."""

    def test_get_history_success(self, mock_supabase_client, sample_user_id, sample_settings_history):
        """Test getting settings history."""
        from api.v1.ai_settings import get_ai_settings_history
        import asyncio

        mock_result = MagicMock()
        mock_result.data = sample_settings_history
        mock_result.count = 2

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.order.return_value.range.return_value.execute.return_value = mock_result

        result = asyncio.get_event_loop().run_until_complete(
            get_ai_settings_history(sample_user_id)
        )

        assert result.total_count == 2
        assert len(result.changes) == 2
        assert result.changes[0].setting_name == "coaching_style"

    def test_get_history_with_filter(self, mock_supabase_client, sample_user_id, sample_settings_history):
        """Test getting history filtered by setting name."""
        from api.v1.ai_settings import get_ai_settings_history
        import asyncio

        filtered_history = [h for h in sample_settings_history if h["setting_name"] == "coaching_style"]
        mock_result = MagicMock()
        mock_result.data = filtered_history
        mock_result.count = 1

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.eq.return_value.order.return_value.range.return_value.execute.return_value = mock_result

        result = asyncio.get_event_loop().run_until_complete(
            get_ai_settings_history(sample_user_id, setting_name="coaching_style")
        )

        assert result.total_count == 1

    def test_get_history_empty(self, mock_supabase_client, sample_user_id):
        """Test getting empty history."""
        from api.v1.ai_settings import get_ai_settings_history
        import asyncio

        mock_result = MagicMock()
        mock_result.data = []
        mock_result.count = 0

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.order.return_value.range.return_value.execute.return_value = mock_result

        result = asyncio.get_event_loop().run_until_complete(
            get_ai_settings_history(sample_user_id)
        )

        assert result.total_count == 0
        assert len(result.changes) == 0


# ============================================================
# RESET SETTINGS TESTS
# ============================================================

class TestResetSettings:
    """Test reset AI settings endpoint."""

    def test_reset_settings_success(self, mock_supabase_client, sample_user_id, sample_ai_settings):
        """Test successful settings reset."""
        from api.v1.ai_settings import reset_ai_settings
        import asyncio

        mock_current = MagicMock()
        mock_current.data = [sample_ai_settings]

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_current
        mock_supabase_client.table.return_value.delete.return_value.eq.return_value.execute.return_value = MagicMock()
        mock_supabase_client.table.return_value.insert.return_value.execute.return_value = MagicMock()

        result = asyncio.get_event_loop().run_until_complete(
            reset_ai_settings(sample_user_id)
        )

        assert result["success"] is True
        mock_supabase_client.table.return_value.delete.return_value.eq.return_value.execute.assert_called_once()

    def test_reset_settings_records_history(self, mock_supabase_client, sample_user_id, sample_ai_settings):
        """Test that reset is recorded in history."""
        from api.v1.ai_settings import reset_ai_settings
        import asyncio

        mock_current = MagicMock()
        mock_current.data = [sample_ai_settings]

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_current
        mock_supabase_client.table.return_value.delete.return_value.eq.return_value.execute.return_value = MagicMock()
        mock_supabase_client.table.return_value.insert.return_value.execute.return_value = MagicMock()

        asyncio.get_event_loop().run_until_complete(
            reset_ai_settings(sample_user_id)
        )

        # Check history was recorded
        insert_calls = mock_supabase_client.table.return_value.insert.call_args_list
        assert len(insert_calls) > 0


# ============================================================
# ANALYTICS ENDPOINTS TESTS
# ============================================================

class TestAnalyticsEndpoints:
    """Test AI settings analytics endpoints."""

    def test_get_popular_settings(self, mock_supabase_client):
        """Test getting popular settings."""
        from api.v1.ai_settings import get_popular_settings
        import asyncio

        mock_result = MagicMock()
        mock_result.data = [
            {"coaching_style": "motivational", "count": 50},
            {"coaching_style": "friendly", "count": 30},
        ]

        mock_supabase_client.table.return_value.select.return_value.execute.return_value = mock_result

        result = asyncio.get_event_loop().run_until_complete(
            get_popular_settings()
        )

        assert "popularity" in result

    def test_get_settings_trends(self, mock_supabase_client):
        """Test getting settings trends."""
        from api.v1.ai_settings import get_settings_trends
        import asyncio

        mock_result = MagicMock()
        mock_result.data = [
            {"date": "2025-01-10", "setting_name": "coaching_style", "change_count": 15},
        ]

        mock_supabase_client.table.return_value.select.return_value.execute.return_value = mock_result

        result = asyncio.get_event_loop().run_until_complete(
            get_settings_trends(days=30)
        )

        assert "trends" in result

    def test_get_engagement_by_style(self, mock_supabase_client):
        """Test getting engagement by AI style."""
        from api.v1.ai_settings import get_engagement_by_style
        import asyncio

        mock_result = MagicMock()
        mock_result.data = [
            {"coaching_style": "motivational", "avg_sessions": 5.5},
        ]

        mock_supabase_client.table.return_value.select.return_value.execute.return_value = mock_result

        result = asyncio.get_event_loop().run_until_complete(
            get_engagement_by_style()
        )

        assert "engagement" in result


# ============================================================
# MODEL VALIDATION TESTS
# ============================================================

class TestAISettingsModels:
    """Test Pydantic model validation."""

    def test_ai_settings_base_defaults(self):
        """Test AISettingsBase default values."""
        from api.v1.ai_settings import AISettingsBase

        settings = AISettingsBase()

        assert settings.coaching_style == "motivational"
        assert settings.communication_tone == "encouraging"
        assert settings.encouragement_level == 0.7
        assert settings.use_emojis is True

    def test_ai_settings_update_validation(self):
        """Test AISettingsUpdate validation."""
        from api.v1.ai_settings import AISettingsUpdate

        settings = AISettingsUpdate(
            coaching_style="strict",
            encouragement_level=0.9,
            change_source="settings_screen"
        )

        assert settings.coaching_style == "strict"
        assert settings.encouragement_level == 0.9
        assert settings.change_source == "settings_screen"

    def test_ai_settings_update_encouragement_range(self):
        """Test encouragement level range validation."""
        from api.v1.ai_settings import AISettingsUpdate
        from pydantic import ValidationError

        # Valid range
        settings = AISettingsUpdate(encouragement_level=0.5)
        assert settings.encouragement_level == 0.5

        # Invalid range
        with pytest.raises(ValidationError):
            AISettingsUpdate(encouragement_level=1.5)

    def test_setting_change_record_model(self):
        """Test SettingChangeRecord model."""
        from api.v1.ai_settings import SettingChangeRecord

        record = SettingChangeRecord(
            id="record-1",
            setting_name="coaching_style",
            old_value="friendly",
            new_value="motivational",
            change_source="app",
            changed_at=datetime.now(),
            device_platform="ios",
            app_version="1.0.0"
        )

        assert record.setting_name == "coaching_style"
        assert record.old_value == "friendly"


# ============================================================
# ERROR HANDLING TESTS
# ============================================================

class TestErrorHandling:
    """Test error handling across endpoints."""

    def test_get_settings_database_error(self, mock_supabase_client, sample_user_id):
        """Test handling database errors in get settings."""
        from api.v1.ai_settings import get_ai_settings
        from fastapi import HTTPException
        import asyncio

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.execute.side_effect = Exception("Connection failed")

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                get_ai_settings(sample_user_id)
            )

        assert exc_info.value.status_code == 500

    def test_update_settings_database_error(self, mock_supabase_client, sample_user_id):
        """Test handling database errors in update settings."""
        from api.v1.ai_settings import update_ai_settings, AISettingsUpdate
        from fastapi import HTTPException
        import asyncio

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.execute.side_effect = Exception("Update failed")

        request = AISettingsUpdate(coaching_style="strict")

        with pytest.raises(HTTPException) as exc_info:
            asyncio.get_event_loop().run_until_complete(
                update_ai_settings(sample_user_id, request)
            )

        assert exc_info.value.status_code == 500


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
