"""
User database operations.

Handles all user-related CRUD operations including:
- User profile management
- User lookup by ID, email, auth_id
- Injury management
- User metrics history
- Chat history
"""
from typing import Optional, List, Dict, Any

from core.db.base import BaseDB


class UserDB(BaseDB):
    """
    Database operations for user management.

    Handles user profiles, injuries, metrics, and chat history.
    """

    # ==================== USERS ====================

    def get_user(self, user_id: str) -> Optional[Dict[str, Any]]:
        """
        Get a user by ID (UUID string).

        Args:
            user_id: The user's UUID

        Returns:
            User data dict or None if not found
        """
        result = self.client.table("users").select("*").eq("id", user_id).execute()
        return result.data[0] if result.data else None

    def get_all_users(self) -> List[Dict[str, Any]]:
        """
        Get all users.

        Returns:
            List of all user records
        """
        result = self.client.table("users").select("*").execute()
        return result.data or []

    def get_user_by_auth_id(self, auth_id: str) -> Optional[Dict[str, Any]]:
        """
        Get a user by Supabase auth_id (UUID).

        Args:
            auth_id: The Supabase authentication UUID

        Returns:
            User data dict or None if not found
        """
        result = self.client.table("users").select("*").eq("auth_id", auth_id).execute()
        return result.data[0] if result.data else None

    def get_user_by_email(self, email: str) -> Optional[Dict[str, Any]]:
        """
        Get a user by email.

        Args:
            email: User's email address

        Returns:
            User data dict or None if not found
        """
        result = self.client.table("users").select("*").eq("email", email).execute()
        return result.data[0] if result.data else None

    def create_user(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """
        Create a new user.

        Args:
            data: User data to insert

        Returns:
            Created user record or None on failure
        """
        result = self.client.table("users").insert(data).execute()
        return result.data[0] if result.data else None

    def update_user(self, user_id: str, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """
        Update a user.

        Args:
            user_id: User's UUID
            data: Fields to update

        Returns:
            Updated user record or None on failure
        """
        import logging
        logger = logging.getLogger(__name__)
        logger.info(f"🔍 [DB] update_user called - user_id: {user_id}")
        logger.info(f"🔍 [DB] update_user - data keys: {list(data.keys())}")
        logger.info(f"🔍 [DB] update_user - equipment value: {data.get('equipment')}")
        logger.info(f"🔍 [DB] update_user - preferences value: {data.get('preferences')}")
        result = self.client.table("users").update(data).eq("id", user_id).execute()
        logger.info(f"🔍 [DB] update_user - result.data: {result.data}")
        return result.data[0] if result.data else None

    def delete_user(self, user_id: str) -> bool:
        """
        Delete a user.

        Args:
            user_id: User's UUID

        Returns:
            True on success
        """
        self.client.table("users").delete().eq("id", user_id).execute()
        return True

    # ==================== INJURIES ====================

    def list_injuries(
        self, user_id: str, is_active: Optional[bool] = None
    ) -> List[Dict[str, Any]]:
        """
        List injuries for a user.

        Args:
            user_id: User's UUID
            is_active: Filter by active status (optional)

        Returns:
            List of injury records
        """
        query = self.client.table("injuries").select("*").eq("user_id", user_id)

        if is_active is not None:
            query = query.eq("is_active", is_active)

        result = query.order("created_at", desc=True).execute()
        return result.data or []

    def create_injury(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """
        Create an injury record.

        Args:
            data: Injury data to insert

        Returns:
            Created injury record or None
        """
        result = self.client.table("injuries").insert(data).execute()
        return result.data[0] if result.data else None

    def update_injury(
        self, injury_id: int, data: Dict[str, Any]
    ) -> Optional[Dict[str, Any]]:
        """
        Update an injury record.

        Args:
            injury_id: Injury record ID
            data: Fields to update

        Returns:
            Updated injury record or None
        """
        result = self.client.table("injuries").update(data).eq("id", injury_id).execute()
        return result.data[0] if result.data else None

    def delete_injuries_by_user(self, user_id: str) -> bool:
        """
        Delete all injuries for a user.

        Args:
            user_id: User's UUID

        Returns:
            True on success
        """
        self.client.table("injuries").delete().eq("user_id", user_id).execute()
        return True

    # ==================== INJURY HISTORY ====================

    def list_injury_history(
        self,
        user_id: str,
        is_active: Optional[bool] = None,
        limit: int = 50,
    ) -> List[Dict[str, Any]]:
        """
        List injury history for a user.

        Args:
            user_id: User's UUID
            is_active: Filter by active status (optional)
            limit: Maximum records to return

        Returns:
            List of injury history records
        """
        query = self.client.table("injury_history").select("*").eq("user_id", user_id)

        if is_active is not None:
            query = query.eq("is_active", is_active)

        result = query.order("reported_at", desc=True).limit(limit).execute()
        return result.data or []

    def get_active_injuries(self, user_id: str) -> List[Dict[str, Any]]:
        """
        Get active injuries for a user.

        Args:
            user_id: User's UUID

        Returns:
            List of active injury records
        """
        result = (
            self.client.table("injury_history")
            .select("*")
            .eq("user_id", user_id)
            .eq("is_active", True)
            .order("reported_at", desc=True)
            .execute()
        )
        return result.data or []

    def create_injury_history(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """
        Create an injury history record.

        Args:
            data: Injury history data to insert

        Returns:
            Created record or None
        """
        result = self.client.table("injury_history").insert(data).execute()
        return result.data[0] if result.data else None

    def delete_injury_history_by_user(self, user_id: str) -> bool:
        """
        Delete all injury history for a user.

        Args:
            user_id: User's UUID

        Returns:
            True on success
        """
        self.client.table("injury_history").delete().eq("user_id", user_id).execute()
        return True

    # ==================== USER METRICS ====================

    def list_user_metrics(
        self, user_id: str, limit: int = 50
    ) -> List[Dict[str, Any]]:
        """
        List user metrics history.

        Args:
            user_id: User's UUID
            limit: Maximum records to return

        Returns:
            List of metric records
        """
        result = (
            self.client.table("user_metrics")
            .select("*")
            .eq("user_id", user_id)
            .order("recorded_at", desc=True)
            .limit(limit)
            .execute()
        )
        return result.data or []

    def create_user_metrics(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """
        Create user metrics record.

        Args:
            data: Metrics data to insert

        Returns:
            Created record or None
        """
        result = self.client.table("user_metrics").insert(data).execute()
        return result.data[0] if result.data else None

    def get_latest_user_metrics(self, user_id: str) -> Optional[Dict[str, Any]]:
        """
        Get the most recent metrics for a user.

        Args:
            user_id: User's UUID

        Returns:
            Most recent metrics record or None
        """
        result = (
            self.client.table("user_metrics")
            .select("*")
            .eq("user_id", user_id)
            .order("recorded_at", desc=True)
            .limit(1)
            .execute()
        )
        return result.data[0] if result.data else None

    def delete_user_metrics(self, metric_id: int, user_id: str) -> bool:
        """
        Delete a specific user metrics entry.

        Args:
            metric_id: Metric record ID
            user_id: User's UUID (for verification)

        Returns:
            True if deleted, False otherwise
        """
        result = (
            self.client.table("user_metrics")
            .delete()
            .eq("id", metric_id)
            .eq("user_id", user_id)
            .execute()
        )
        return len(result.data) > 0 if result.data else False

    def delete_user_metrics_by_user(self, user_id: str) -> bool:
        """
        Delete all user metrics for a user.

        Args:
            user_id: User's UUID

        Returns:
            True on success
        """
        self.client.table("user_metrics").delete().eq("user_id", user_id).execute()
        return True

    # ==================== CHAT HISTORY ====================

    def list_chat_history(
        self, user_id: str, limit: int = 100
    ) -> List[Dict[str, Any]]:
        """
        List chat history for a user.

        Args:
            user_id: User's UUID
            limit: Maximum records to return

        Returns:
            List of chat messages (oldest first)
        """
        result = (
            self.client.table("chat_history")
            .select("*")
            .eq("user_id", user_id)
            .order("timestamp", desc=False)
            .limit(limit)
            .execute()
        )
        return result.data or []

    def create_chat_message(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """
        Create a chat message.

        Args:
            data: Chat message data to insert

        Returns:
            Created message or None
        """
        result = self.client.table("chat_history").insert(data).execute()
        return result.data[0] if result.data else None

    def delete_chat_history_by_user(self, user_id: str) -> bool:
        """
        Delete all chat history for a user.

        Args:
            user_id: User's UUID

        Returns:
            True on success
        """
        self.client.table("chat_history").delete().eq("user_id", user_id).execute()
        return True
