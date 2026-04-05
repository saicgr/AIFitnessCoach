"""
Subscription API endpoints package.

ENDPOINTS:
- GET  /api/v1/subscriptions/{user_id} - Get user's subscription
- POST /api/v1/subscriptions/{user_id}/check-access - Check feature access
- POST /api/v1/subscriptions/{user_id}/track-usage - Track feature usage
- POST /api/v1/subscriptions/webhook/revenuecat - RevenueCat webhook handler
- POST /api/v1/subscriptions/{user_id}/paywall-impression - Track paywall interaction
- GET  /api/v1/subscriptions/{user_id}/usage-stats - Get feature usage stats
- GET  /api/v1/subscriptions/{user_id}/feature-limits - Get all AI feature limits
- GET  /api/v1/subscriptions/{user_id}/history - Get subscription history
- GET  /api/v1/subscriptions/{user_id}/upcoming-renewal - Get renewal info
- POST /api/v1/subscriptions/{user_id}/request-refund - Submit refund
- GET  /api/v1/subscriptions/{user_id}/refund-requests - Get refund requests
- GET  /api/v1/subscriptions/trial-eligibility/{user_id} - Check trial eligibility
- POST /api/v1/subscriptions/start-trial/{user_id} - Start free trial
- POST /api/v1/subscriptions/convert-trial/{user_id} - Convert trial to paid
- GET  /api/v1/subscriptions/trial-status/{user_id} - Get trial status
- GET  /api/v1/subscriptions/{user_id}/lifetime-status - Check lifetime status
- GET  /api/v1/subscriptions/{user_id}/lifetime-benefits - Get lifetime benefits
- POST /api/v1/subscriptions/{user_id}/convert-to-lifetime - Convert to lifetime
- POST /api/v1/subscriptions/{user_id}/pause - Pause subscription
- POST /api/v1/subscriptions/{user_id}/resume - Resume subscription
- GET  /api/v1/subscriptions/{user_id}/retention-offers - Get retention offers
- POST /api/v1/subscriptions/{user_id}/accept-offer - Accept retention offer
"""
from fastapi import APIRouter

from api.v1.subscriptions.management import router as management_router
from api.v1.subscriptions.webhooks import router as webhooks_router
from api.v1.subscriptions.transparency import router as transparency_router
from api.v1.subscriptions.trials import router as trials_router
from api.v1.subscriptions.lifetime import router as lifetime_router
from api.v1.subscriptions.retention import router as retention_router

# Re-export key symbols that tests import from api.v1.subscriptions
from api.v1.subscriptions.models import (
    SubscriptionTier,
    SubscriptionStatus,
    SubscriptionResponse,
    SubscriptionHistoryEvent,
    UpcomingRenewalResponse,
    RefundRequest,
    RefundRequestResponse,
    RefundRequestDetails,
    RefundStatus,
    PauseSubscriptionRequest,
    AcceptOfferRequest,
    _product_to_tier,
    is_lifetime_member,
    get_lifetime_member_tier,
    calculate_lifetime_value,
)
from api.v1.subscriptions.management import get_subscription, check_feature_access, get_feature_limits
from api.v1.subscriptions.transparency import get_subscription_history, get_upcoming_renewal, request_refund, get_refund_requests
from api.v1.subscriptions.trials import check_trial_eligibility, start_trial, convert_trial_to_paid, get_trial_status
from api.v1.subscriptions.lifetime import get_lifetime_status, get_lifetime_benefits, convert_to_lifetime
from api.v1.subscriptions.retention import pause_subscription, resume_subscription, get_retention_offers, accept_retention_offer

# Re-export dependencies that tests patch via 'api.v1.subscriptions.xxx'
from core.supabase_client import get_supabase
from core.activity_logger import log_user_activity, log_user_error

# Combined router
router = APIRouter()
router.include_router(management_router)
router.include_router(webhooks_router)
router.include_router(transparency_router)
router.include_router(trials_router)
router.include_router(lifetime_router)
router.include_router(retention_router)
