"""
Base database class for Supabase operations.

Provides common functionality shared across all database modules.
"""
from typing import Optional, List, Dict, Any
from supabase import Client

from core.supabase_client import get_supabase, SupabaseManager
from core.logger import get_logger

logger = get_logger(__name__)


class BaseDB:
    """
    Base class for database operations.

    Provides access to the Supabase client and common query patterns.
    All domain-specific DB classes inherit from this base.

    Usage:
        class UserDB(BaseDB):
            def get_user(self, user_id: str) -> Optional[Dict[str, Any]]:
                result = self.client.table("users").select("*").eq("id", user_id).execute()
                return result.data[0] if result.data else None
    """

    def __init__(self, supabase_manager: Optional[SupabaseManager] = None):
        """
        Initialize the database module.

        Args:
            supabase_manager: Optional SupabaseManager instance. If not provided,
                              uses the global singleton.
        """
        self._supabase_manager = supabase_manager or get_supabase()

    @property
    def supabase(self) -> SupabaseManager:
        """Get the Supabase manager instance."""
        return self._supabase_manager

    @property
    def client(self) -> Client:
        """Get the Supabase client for table operations."""
        return self._supabase_manager.client

    def _execute_query(
        self,
        table: str,
        query_builder: callable,
        single: bool = False
    ) -> Any:
        """
        Execute a query with standard error handling.

        Args:
            table: Table name for logging purposes
            query_builder: Callable that builds and executes the query
            single: If True, returns first result or None; otherwise returns list

        Returns:
            Query result (single item or list based on 'single' parameter)
        """
        try:
            result = query_builder()
            if single:
                return result.data[0] if result.data else None
            return result.data or []
        except Exception as e:
            logger.error(f"[{table}] Query error: {e}")
            raise

    def _build_filtered_query(
        self,
        table: str,
        filters: Dict[str, Any],
        order_by: Optional[str] = None,
        order_desc: bool = True,
        limit: Optional[int] = None,
        offset: int = 0,
    ):
        """
        Build a filtered query with common patterns.

        Args:
            table: Table name to query
            filters: Dictionary of column -> value filters
            order_by: Column to order by
            order_desc: Order descending if True
            limit: Maximum number of results
            offset: Number of results to skip

        Returns:
            Query builder ready for execution
        """
        query = self.client.table(table).select("*")

        for column, value in filters.items():
            if value is not None:
                query = query.eq(column, value)

        if order_by:
            query = query.order(order_by, desc=order_desc)

        if limit:
            query = query.range(offset, offset + limit - 1)

        return query
