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
from api.v1.admin import live_chat, observability

router = APIRouter()

# Include live chat admin routes
router.include_router(live_chat.router, tags=["Admin Live Chat"])

# Phase D4 — backend observability snapshot (GET /api/v1/admin/metrics).
# Guarded by the X-Cron-Secret shared secret.
router.include_router(observability.router, tags=["Admin Observability"])
