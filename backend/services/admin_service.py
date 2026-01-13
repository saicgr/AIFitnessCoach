"""
Admin Service for FitWiz.

Handles admin-related functionality including:
- Support user management (support@fitwiz.us)
- Role-based access control
- Auto-friending support user to new users
"""

from typing import Optional
from datetime import datetime, timezone

from core.supabase_db import get_supabase_db
from core.logger import get_logger

logger = get_logger(__name__)

# Support user email - this is the admin account
SUPPORT_EMAIL = "support@fitwiz.us"


class AdminService:
    """Service for admin-related operations."""

    def __init__(self):
        self.db = get_supabase_db()

    async def is_admin(self, user_id: str) -> bool:
        """
        Check if a user has admin role.

        Args:
            user_id: UUID of the user to check

        Returns:
            True if user has admin role, False otherwise
        """
        try:
            result = self.db.client.table("users").select("role").eq("id", user_id).execute()
            if result.data and len(result.data) > 0:
                return result.data[0].get("role") == "admin"
            return False
        except Exception as e:
            logger.error(f"Error checking admin status for user {user_id}: {e}")
            return False

    async def is_support_user(self, user_id: str) -> bool:
        """
        Check if a user is the support account.

        Args:
            user_id: UUID of the user to check

        Returns:
            True if user is the support account, False otherwise
        """
        try:
            result = self.db.client.table("users").select("is_support_user").eq("id", user_id).execute()
            if result.data and len(result.data) > 0:
                return result.data[0].get("is_support_user", False)
            return False
        except Exception as e:
            logger.error(f"Error checking support user status for {user_id}: {e}")
            return False

    async def get_support_user(self) -> Optional[dict]:
        """
        Get the support user record.

        Returns:
            Support user data dict, or None if not found
        """
        try:
            result = self.db.client.table("users").select("*").eq("is_support_user", True).limit(1).execute()
            if result.data and len(result.data) > 0:
                return result.data[0]
            return None
        except Exception as e:
            logger.error(f"Error getting support user: {e}")
            return None

    async def get_support_user_by_email(self) -> Optional[dict]:
        """
        Get the support user record by email.

        Returns:
            Support user data dict, or None if not found
        """
        try:
            result = self.db.client.table("users").select("*").eq("email", SUPPORT_EMAIL).limit(1).execute()
            if result.data and len(result.data) > 0:
                return result.data[0]
            return None
        except Exception as e:
            logger.error(f"Error getting support user by email: {e}")
            return None

    async def add_support_friend_to_user(self, user_id: str) -> bool:
        """
        Auto-add the support user as a friend to a new user.
        Creates bidirectional connections (both directions).

        Args:
            user_id: UUID of the new user

        Returns:
            True if successful, False otherwise
        """
        try:
            support_user = await self.get_support_user()
            if not support_user:
                logger.warning("Support user not found, skipping auto-friend")
                return False

            support_user_id = support_user["id"]

            # Don't add support user as friend to themselves
            if user_id == support_user_id:
                return True

            now = datetime.now(timezone.utc).isoformat()

            # Create bidirectional connections
            # Connection 1: support -> new user
            connection1 = {
                "follower_id": support_user_id,
                "following_id": user_id,
                "connection_type": "friend",
                "status": "active",
                "created_at": now,
            }

            # Connection 2: new user -> support
            connection2 = {
                "follower_id": user_id,
                "following_id": support_user_id,
                "connection_type": "friend",
                "status": "active",
                "created_at": now,
            }

            # Check if connections already exist
            existing1 = self.db.client.table("user_connections").select("id").eq(
                "follower_id", support_user_id
            ).eq("following_id", user_id).execute()

            existing2 = self.db.client.table("user_connections").select("id").eq(
                "follower_id", user_id
            ).eq("following_id", support_user_id).execute()

            # Insert connections that don't exist
            if not existing1.data:
                self.db.client.table("user_connections").insert(connection1).execute()
                logger.info(f"Created connection: support -> user {user_id}")

            if not existing2.data:
                self.db.client.table("user_connections").insert(connection2).execute()
                logger.info(f"Created connection: user {user_id} -> support")

            logger.info(f"Auto-added support user as friend to user {user_id}")
            return True

        except Exception as e:
            logger.error(f"Error adding support friend to user {user_id}: {e}")
            return False

    async def add_support_friend_to_all_existing_users(self) -> int:
        """
        Add support user as friend to all existing users.
        Used for backfilling when support user is first created.

        Returns:
            Number of users that were updated
        """
        try:
            support_user = await self.get_support_user()
            if not support_user:
                logger.error("Support user not found")
                return 0

            # Get all users except the support user
            result = self.db.client.table("users").select("id").neq(
                "id", support_user["id"]
            ).execute()

            if not result.data:
                return 0

            count = 0
            for user in result.data:
                success = await self.add_support_friend_to_user(user["id"])
                if success:
                    count += 1

            logger.info(f"Added support user as friend to {count} existing users")
            return count

        except Exception as e:
            logger.error(f"Error backfilling support friends: {e}")
            return 0

    def should_be_admin(self, email: str) -> bool:
        """
        Check if an email should be assigned admin role.

        Args:
            email: Email address to check

        Returns:
            True if email should have admin role
        """
        return email.lower() == SUPPORT_EMAIL.lower()

    def should_be_support_user(self, email: str) -> bool:
        """
        Check if an email should be marked as support user.

        Args:
            email: Email address to check

        Returns:
            True if email should be marked as support user
        """
        return email.lower() == SUPPORT_EMAIL.lower()


# Singleton instance
_admin_service: Optional[AdminService] = None


def get_admin_service() -> AdminService:
    """Get the admin service singleton."""
    global _admin_service
    if _admin_service is None:
        _admin_service = AdminService()
    return _admin_service
