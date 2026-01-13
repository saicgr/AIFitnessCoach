"""
Social API module.

This module provides a unified router that combines all social-related endpoints
from the following submodules:
- connections: User follow/unfollow operations
- feed: Activity feed operations
- reactions: Reaction operations
- comments: Comment operations
- challenges: Challenge operations
- privacy: Privacy settings
- summary: Social summary endpoints
- users: User search and discovery
- friend_requests: Friend request management
- notifications: Social notifications
- messages: Direct messaging between users
"""
from fastapi import APIRouter

from .connections import router as connections_router
from .feed import router as feed_router
from .reactions import router as reactions_router
from .comments import router as comments_router
from .challenges import router as challenges_router
from .privacy import router as privacy_router
from .summary import router as summary_router
from .users import router as users_router
from .friend_requests import router as friend_requests_router
from .notifications import router as notifications_router
from .messages import router as messages_router

# Create the combined router with /social prefix
router = APIRouter(prefix="/social")

# Include all sub-routers
router.include_router(connections_router)
router.include_router(feed_router)
router.include_router(reactions_router)
router.include_router(comments_router)
router.include_router(challenges_router)
router.include_router(privacy_router)
router.include_router(summary_router)
router.include_router(users_router)
router.include_router(friend_requests_router)
router.include_router(notifications_router)
router.include_router(messages_router, prefix="/messages", tags=["messages"])

# Re-export utilities
from .utils import get_supabase_client

__all__ = [
    'router',
    'get_supabase_client',
]
