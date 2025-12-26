"""
Tests for social notifications API endpoints.

Tests cover:
- GET /notifications - Get notifications
- GET /notifications/unread-count - Get unread count
- PUT /notifications/{id}/read - Mark as read
- PUT /notifications/read-all - Mark all as read
- DELETE /notifications/{id} - Delete notification
- DELETE /notifications/clear-all - Clear all notifications
- GET /notifications/settings - Get social settings
- PUT /notifications/settings - Update social settings
"""
import pytest
from unittest.mock import MagicMock, patch
from fastapi import HTTPException

from models.friend_request import SocialNotificationType, SocialPrivacySettingsUpdate


class TestGetNotifications:
    """Tests for get_notifications endpoint."""

    @pytest.mark.asyncio
    async def test_get_notifications_success(self):
        """Test successful notification retrieval."""
        from api.v1.social.notifications import get_notifications

        mock_client = MagicMock()

        # Mock unread count result
        mock_unread = MagicMock()
        mock_unread.count = 5

        # Mock total count result
        mock_total = MagicMock()
        mock_total.count = 10

        # Create a mock chain that returns itself for chained calls
        mock_query = MagicMock()
        mock_query.eq.return_value = mock_query
        mock_query.order.return_value = mock_query
        mock_query.range.return_value = mock_query
        mock_query.execute.return_value.data = [
            {
                "id": "notif-1",
                "user_id": "user-1",
                "type": "friend_request",
                "from_user_id": "user-2",
                "from_user_name": "John Doe",
                "from_user_avatar": None,
                "reference_id": "req-1",
                "reference_type": "friend_request",
                "title": "New Friend Request",
                "body": "John Doe sent you a friend request",
                "data": {},
                "is_read": False,
                "created_at": "2024-01-15T00:00:00Z",
            }
        ]

        # Mock for count queries
        mock_count_query = MagicMock()
        mock_count_query.eq.return_value = mock_count_query
        mock_count_query.execute.return_value = mock_unread

        call_count = [0]

        def table_side_effect(table_name):
            mock_table = MagicMock()
            call_count[0] += 1
            if call_count[0] == 1:
                # First call is for notifications list
                mock_table.select.return_value = mock_query
            elif call_count[0] == 2:
                # Second call is for unread count
                mock_table.select.return_value = mock_count_query
                mock_count_query.execute.return_value = mock_unread
            else:
                # Third call is for total count
                mock_table.select.return_value = mock_count_query
                mock_count_query.execute.return_value = mock_total
            return mock_table

        mock_client.table.side_effect = table_side_effect

        with patch("api.v1.social.notifications.get_supabase_client", return_value=mock_client):
            result = await get_notifications(
                user_id="user-1",
                unread_only=False,
                notification_type=None,
                limit=50,
                offset=0,
            )

        assert len(result.notifications) == 1
        assert result.notifications[0].type == SocialNotificationType.FRIEND_REQUEST

    @pytest.mark.asyncio
    async def test_get_notifications_unread_only(self):
        """Test getting only unread notifications."""
        from api.v1.social.notifications import get_notifications

        mock_client = MagicMock()

        # Setup count mock
        mock_count = MagicMock()
        mock_count.count = 0

        # Mock query chain
        mock_query = MagicMock()
        mock_query.eq.return_value = mock_query
        mock_query.order.return_value = mock_query
        mock_query.range.return_value = mock_query
        mock_query.execute.return_value.data = []

        mock_count_query = MagicMock()
        mock_count_query.eq.return_value = mock_count_query
        mock_count_query.execute.return_value = mock_count

        call_count = [0]

        def table_side_effect(table_name):
            mock_table = MagicMock()
            call_count[0] += 1
            if call_count[0] == 1:
                mock_table.select.return_value = mock_query
            else:
                mock_table.select.return_value = mock_count_query
            return mock_table

        mock_client.table.side_effect = table_side_effect

        with patch("api.v1.social.notifications.get_supabase_client", return_value=mock_client):
            result = await get_notifications(
                user_id="user-1",
                unread_only=True,
                notification_type=None,
                limit=50,
                offset=0,
            )

        assert result.notifications == []


class TestGetUnreadCount:
    """Tests for get_unread_count endpoint."""

    @pytest.mark.asyncio
    async def test_get_unread_count_success(self):
        """Test getting unread notification count."""
        from api.v1.social.notifications import get_unread_count

        mock_client = MagicMock()
        mock_result = MagicMock()
        mock_result.count = 7
        mock_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_result

        with patch("api.v1.social.notifications.get_supabase_client", return_value=mock_client):
            result = await get_unread_count(user_id="user-1")

        assert result["count"] == 7

    @pytest.mark.asyncio
    async def test_get_unread_count_zero(self):
        """Test getting zero unread count."""
        from api.v1.social.notifications import get_unread_count

        mock_client = MagicMock()
        mock_result = MagicMock()
        mock_result.count = None  # Supabase returns None for 0
        mock_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_result

        with patch("api.v1.social.notifications.get_supabase_client", return_value=mock_client):
            result = await get_unread_count(user_id="user-1")

        assert result["count"] == 0


class TestMarkNotificationRead:
    """Tests for mark_notification_read endpoint."""

    @pytest.mark.asyncio
    async def test_mark_read_success(self):
        """Test marking notification as read."""
        from api.v1.social.notifications import mark_notification_read

        mock_client = MagicMock()
        mock_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = [
            {"id": "notif-1"}
        ]
        mock_client.table.return_value.update.return_value.eq.return_value.execute.return_value.data = [{}]

        with patch("api.v1.social.notifications.get_supabase_client", return_value=mock_client):
            result = await mark_notification_read(notification_id="notif-1", user_id="user-1")

        assert result["message"] == "Notification marked as read"

    @pytest.mark.asyncio
    async def test_mark_read_not_found(self):
        """Test 404 for non-existent notification."""
        from api.v1.social.notifications import mark_notification_read

        mock_client = MagicMock()
        mock_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = []

        with patch("api.v1.social.notifications.get_supabase_client", return_value=mock_client):
            with pytest.raises(HTTPException) as exc_info:
                await mark_notification_read(notification_id="nonexistent", user_id="user-1")

        assert exc_info.value.status_code == 404


class TestMarkAllNotificationsRead:
    """Tests for mark_all_notifications_read endpoint."""

    @pytest.mark.asyncio
    async def test_mark_all_read_success(self):
        """Test marking all notifications as read."""
        from api.v1.social.notifications import mark_all_notifications_read

        mock_client = MagicMock()
        mock_client.table.return_value.update.return_value.eq.return_value.eq.return_value.execute.return_value.data = [
            {}, {}, {}  # 3 updated
        ]

        with patch("api.v1.social.notifications.get_supabase_client", return_value=mock_client):
            result = await mark_all_notifications_read(user_id="user-1")

        assert "3" in result["message"]
        assert result["count"] == 3


class TestDeleteNotification:
    """Tests for delete_notification endpoint."""

    @pytest.mark.asyncio
    async def test_delete_notification_success(self):
        """Test successful notification deletion."""
        from api.v1.social.notifications import delete_notification

        mock_client = MagicMock()
        mock_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = [
            {"id": "notif-1"}
        ]
        mock_client.table.return_value.delete.return_value.eq.return_value.execute.return_value.data = [{}]

        with patch("api.v1.social.notifications.get_supabase_client", return_value=mock_client):
            result = await delete_notification(notification_id="notif-1", user_id="user-1")

        assert result["message"] == "Notification deleted"

    @pytest.mark.asyncio
    async def test_delete_notification_not_found(self):
        """Test 404 for non-existent notification."""
        from api.v1.social.notifications import delete_notification

        mock_client = MagicMock()
        mock_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = []

        with patch("api.v1.social.notifications.get_supabase_client", return_value=mock_client):
            with pytest.raises(HTTPException) as exc_info:
                await delete_notification(notification_id="nonexistent", user_id="user-1")

        assert exc_info.value.status_code == 404


class TestClearAllNotifications:
    """Tests for clear_all_notifications endpoint."""

    @pytest.mark.asyncio
    async def test_clear_all_success(self):
        """Test clearing all notifications."""
        from api.v1.social.notifications import clear_all_notifications

        mock_client = MagicMock()
        mock_client.table.return_value.delete.return_value.eq.return_value.execute.return_value.data = [
            {}, {}, {}, {}, {}  # 5 deleted
        ]

        with patch("api.v1.social.notifications.get_supabase_client", return_value=mock_client):
            result = await clear_all_notifications(user_id="user-1")

        assert "5" in result["message"]
        assert result["count"] == 5


class TestGetSocialSettings:
    """Tests for get_social_settings endpoint."""

    @pytest.mark.asyncio
    async def test_get_settings_success(self):
        """Test getting social settings."""
        from api.v1.social.notifications import get_social_settings

        mock_client = MagicMock()
        mock_client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [{
            "notify_friend_requests": True,
            "notify_reactions": False,
            "notify_comments": True,
            "notify_challenge_invites": True,
            "notify_friend_activity": False,
            "require_follow_approval": True,
            "allow_friend_requests": True,
            "allow_challenge_invites": True,
            "show_on_leaderboards": True,
        }]

        with patch("api.v1.social.notifications.get_supabase_client", return_value=mock_client):
            result = await get_social_settings(user_id="user-1")

        assert result.notify_friend_requests is True
        assert result.notify_reactions is False
        assert result.require_follow_approval is True

    @pytest.mark.asyncio
    async def test_get_settings_defaults_when_not_found(self):
        """Test that defaults are returned when no settings exist."""
        from api.v1.social.notifications import get_social_settings

        mock_client = MagicMock()
        mock_client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = []

        with patch("api.v1.social.notifications.get_supabase_client", return_value=mock_client):
            result = await get_social_settings(user_id="user-1")

        # Check defaults
        assert result.notify_friend_requests is True
        assert result.require_follow_approval is False


class TestUpdateSocialSettings:
    """Tests for update_social_settings endpoint."""

    @pytest.mark.asyncio
    async def test_update_settings_success(self):
        """Test updating social settings."""
        from api.v1.social.notifications import update_social_settings

        mock_client = MagicMock()

        # Mock existing settings
        mock_client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [{"id": "settings-1"}]

        # Mock update
        mock_client.table.return_value.update.return_value.eq.return_value.execute.return_value.data = [{}]

        settings = SocialPrivacySettingsUpdate(
            notify_friend_requests=False,
            require_follow_approval=True,
        )

        with patch("api.v1.social.notifications.get_supabase_client", return_value=mock_client):
            with patch("api.v1.social.notifications.get_social_settings") as mock_get:
                mock_get.return_value = MagicMock(
                    notify_friend_requests=False,
                    notify_reactions=True,
                    notify_comments=True,
                    notify_challenge_invites=True,
                    notify_friend_activity=True,
                    require_follow_approval=True,
                    allow_friend_requests=True,
                    allow_challenge_invites=True,
                    show_on_leaderboards=True,
                )
                result = await update_social_settings(user_id="user-1", settings=settings)

        assert result.notify_friend_requests is False
        assert result.require_follow_approval is True

    @pytest.mark.asyncio
    async def test_update_settings_creates_when_not_exist(self):
        """Test that settings are created if they don't exist."""
        from api.v1.social.notifications import update_social_settings

        mock_client = MagicMock()

        # Mock no existing settings
        mock_client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = []

        # Mock insert
        mock_client.table.return_value.insert.return_value.execute.return_value.data = [{}]

        settings = SocialPrivacySettingsUpdate(require_follow_approval=True)

        with patch("api.v1.social.notifications.get_supabase_client", return_value=mock_client):
            with patch("api.v1.social.notifications.get_social_settings") as mock_get:
                mock_get.return_value = MagicMock(
                    notify_friend_requests=True,
                    notify_reactions=True,
                    notify_comments=True,
                    notify_challenge_invites=True,
                    notify_friend_activity=True,
                    require_follow_approval=True,
                    allow_friend_requests=True,
                    allow_challenge_invites=True,
                    show_on_leaderboards=True,
                )
                result = await update_social_settings(user_id="user-1", settings=settings)

        # Verify insert was called
        mock_client.table.return_value.insert.assert_called_once()
