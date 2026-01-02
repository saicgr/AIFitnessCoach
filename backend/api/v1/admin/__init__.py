"""Admin API module.

This module provides admin-specific endpoints for:
- Admin authentication (login with role verification)
- Live chat management (view, reply, assign, close)
- Support ticket management
- Chat report review
- Dashboard statistics and monitoring
- Agent presence tracking
"""

from fastapi import APIRouter
from api.v1.admin import live_chat

router = APIRouter()

# Include live chat admin routes
router.include_router(live_chat.router, tags=["Admin Live Chat"])
