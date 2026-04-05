"""Pydantic models for notifications."""
from datetime import datetime, date
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any


class TestNotificationRequest(BaseModel):
    """Request body for sending a test notification."""
    user_id: str
    fcm_token: str


class RegisterTokenRequest(BaseModel):
    """Request body for registering FCM token."""
    user_id: str
    fcm_token: str


class SendNotificationRequest(BaseModel):
    """Request body for sending a custom notification."""
    user_id: str
    title: str
    body: str
    notification_type: Optional[str] = "ai_coach"
    data: Optional[dict] = None


class BillingNotificationResponse(BaseModel):
    """Response for a billing notification."""
    id: str
    notification_type: str
    scheduled_for: str
    sent_at: Optional[str] = None
    renewal_amount: Optional[float] = None
    currency: str = "USD"
    product_id: Optional[str] = None
    status: str
    metadata: Optional[dict] = None


class UpcomingRenewalResponse(BaseModel):
    """Response with upcoming renewal info for in-app banner."""
    has_upcoming_renewal: bool
    renewal_date: Optional[str] = None
    days_until_renewal: Optional[int] = None
    renewal_amount: Optional[float] = None
    currency: str = "USD"
    tier: Optional[str] = None
    product_id: Optional[str] = None
    show_banner: bool = False
    notifications: List[BillingNotificationResponse] = []


class BillingPreferencesRequest(BaseModel):
    """Request to update billing notification preferences."""
    billing_notifications_enabled: bool


class DismissBannerRequest(BaseModel):
    """Request to dismiss the renewal banner."""
    dismiss_until: Optional[str] = None  # ISO date string, defaults to renewal date


class TrackInteractionRequest(BaseModel):
    """Request body for tracking a notification interaction."""
    notification_type: str
    opened_at: str  # ISO timestamp


class MovementReminderRequest(BaseModel):
    """Request body for sending a movement reminder."""
    user_id: str
    current_steps: int = 0
    threshold: int = 250


