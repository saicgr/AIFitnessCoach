"""
Web-only Lifetime endpoints — "Founding 500" Coming-Soon waitlist + Stripe Checkout.

Architecture (see migration 2042_web_lifetime_founders.sql):

    Phase 1 (now)               Phase 2 (~3 months post-app-launch)
    ───────────────             ─────────────────────────────────────
    /lifetime page shows        /lifetime page swaps "Reserve" CTA
    "Coming Soon — 247/500      for "Buy Now" → Stripe Checkout
    reserved" + email form      → webhook → web_lifetime_purchases
                                → user logs in via app email
                                → app silently unlocks Premium

Critical guardrails:
- Stripe Checkout only enabled when `settings.lifetime_checkout_enabled == True`.
- The hard 500-seat cap is enforced atomically in Postgres
  (`claim_founder_seat()` SQL function with row-level lock).
- Webhook handler is idempotent — re-deliveries do NOT double-grant entitlements.
- Lifetime entitlement is NEVER granted from the iOS/Android app — only from
  the Stripe webhook (server-side, after payment captured).

Apple/Google compliance:
- This endpoint is NOT called from the mobile app.
- Pricing ($149.99) is NEVER returned to a mobile client (only to web).
- The mobile app's `/subscriptions/status` aggregator silently mirrors the
  lifetime entitlement onto user_subscriptions — same surface as IAP.
"""
from __future__ import annotations

import hashlib
import hmac
import json
from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Header, Request
from pydantic import BaseModel, EmailStr, Field

from core.config import get_settings
from core.logger import get_logger
from core.supabase_client import get_supabase

router = APIRouter(prefix="/lifetime-web", tags=["lifetime-web"])
logger = get_logger(__name__)


# =============================================================================
# RESPONSE / REQUEST MODELS
# =============================================================================

class FounderSeatsResponse(BaseModel):
    """Public seat counter — safe to expose without auth.

    Drives the live counter on /lifetime ("247/500 reserved").
    The marketing page polls this every ~30s during launch peaks.
    """
    seats_total: int = Field(..., description="Hard cap (always 500 unless overridden in config)")
    seats_claimed: int = Field(..., description="Number of paid lifetime members so far")
    seats_remaining: int = Field(..., description="seats_total - seats_claimed, floored at 0")
    availability_label: str = Field(
        ...,
        description="One of: 'available' | 'going_fast' (>=50%) | 'almost_gone' (>=90%) | 'sold_out'",
    )
    checkout_enabled: bool = Field(
        ...,
        description="When False, /lifetime shows 'Coming Soon' + waitlist; when True, shows Stripe Checkout button",
    )
    price_usd: float = Field(..., description="Display price (149.99). Marketing copy only — store cuts don't apply on web.")


class WaitlistJoinRequest(BaseModel):
    """Phase 1 capture — email only. No payment yet.

    User submits this from /lifetime when checkout_enabled is False.
    They get an email when checkout opens (Phase 2 cutover).
    """
    email: EmailStr
    source: Optional[str] = Field(None, max_length=64, description="utm_source / referrer hint")
    referrer: Optional[str] = Field(None, max_length=256)
    country_code: Optional[str] = Field(None, max_length=2, description="ISO 3166-1 alpha-2")
    marketing_opt_in: bool = True


class WaitlistJoinResponse(BaseModel):
    success: bool
    already_on_waitlist: bool = Field(..., description="True if this email was already captured (idempotent)")
    position: Optional[int] = Field(None, description="Approximate signup order; for marketing copy only")


class CheckoutSessionRequest(BaseModel):
    """Phase 2 — when user clicks 'Buy Founding Lifetime'."""
    email: EmailStr
    # Optional: tag the source for analytics (utm_source, referrer, etc.)
    source: Optional[str] = Field(None, max_length=64)


class CheckoutSessionResponse(BaseModel):
    checkout_url: str = Field(..., description="Stripe-hosted Checkout URL. Redirect the browser here.")
    session_id: str = Field(..., description="Stripe Checkout Session ID for post-success polling.")


# =============================================================================
# PUBLIC: SEAT COUNTER (drives the /lifetime page hero)
# =============================================================================

@router.get("/seats", response_model=FounderSeatsResponse)
async def get_founder_seats() -> FounderSeatsResponse:
    """Live seat counter for the marketing page.

    No auth required — this is intentionally public. Returns conservative
    fallback (0/500, 'available') if the counter row isn't seeded yet (i.e.
    migration 2042 hasn't been applied), so the marketing page never breaks.
    """
    settings = get_settings()
    try:
        supabase = get_supabase()
        result = supabase.client.table("lifetime_founder_seats_public").select("*").limit(1).execute()
        if result.data:
            row = result.data[0]
            return FounderSeatsResponse(
                seats_total=int(row["seats_total"]),
                seats_claimed=int(row["seats_claimed"]),
                seats_remaining=int(row["seats_remaining"]),
                availability_label=str(row["availability_label"]),
                checkout_enabled=settings.lifetime_checkout_enabled,
                price_usd=settings.lifetime_price_usd_cents / 100.0,
            )
    except Exception as e:
        # Migration not applied / table missing / network blip → degrade gracefully.
        # Marketing page will still render; counter shows full availability.
        logger.warning(f"Founder seats lookup failed (using fallback): {e}")

    return FounderSeatsResponse(
        seats_total=settings.lifetime_founder_seats_total,
        seats_claimed=0,
        seats_remaining=settings.lifetime_founder_seats_total,
        availability_label="available",
        checkout_enabled=settings.lifetime_checkout_enabled,
        price_usd=settings.lifetime_price_usd_cents / 100.0,
    )


# =============================================================================
# PHASE 1 (NOW): WAITLIST CAPTURE
# =============================================================================

@router.post("/waitlist", response_model=WaitlistJoinResponse)
async def join_waitlist(
    payload: WaitlistJoinRequest,
    request: Request,
) -> WaitlistJoinResponse:
    """Capture an email while checkout is in 'Coming Soon' state.

    Idempotent — re-submitting the same email is a silent no-op (so refreshing
    or re-clicking doesn't yell at the user). Frontend can show "You're on
    the list!" either way.

    Marketing context only: the `position` in the response is best-effort and
    is allowed to be approximate. Don't use it as a hard guarantee — multiple
    inserts can race. We claim it as "approximately #N" in the email confirmation.
    """
    supabase = get_supabase()
    normalized = payload.email.lower().strip()

    # Best-effort country override from CF/Vercel forwarded headers if not provided
    country = payload.country_code or request.headers.get("cf-ipcountry") or request.headers.get("x-vercel-ip-country")
    if country:
        country = country[:2].upper()

    try:
        existing = (
            supabase.client.table("lifetime_waitlist")
            .select("id, created_at")
            .eq("email_normalized", normalized)
            .maybe_single()
            .execute()
        )
        if existing and existing.data:
            # Already on the list — idempotent success
            return WaitlistJoinResponse(
                success=True,
                already_on_waitlist=True,
                position=None,
            )

        insert_result = (
            supabase.client.table("lifetime_waitlist")
            .insert({
                "email": payload.email,
                "source": payload.source,
                "referrer": payload.referrer,
                "country_code": country,
                "marketing_opt_in": payload.marketing_opt_in,
            })
            .execute()
        )
        if not insert_result.data:
            raise HTTPException(status_code=500, detail="Failed to record waitlist entry")

        # Approximate position = total rows so far. NOT a guarantee under concurrent inserts.
        count_result = (
            supabase.client.table("lifetime_waitlist")
            .select("id", count="exact")
            .execute()
        )
        position = count_result.count if hasattr(count_result, "count") else None

        logger.info(f"Waitlist join: email={normalized} country={country} position={position}")

        # Fire-and-forget confirmation email. Don't block the API response on
        # email delivery — Resend is fast but not free of latency, and the
        # waitlist insert succeeded regardless.
        try:
            from services.email_service import get_email_service
            email_service = get_email_service()
            # We intentionally don't await — this runs in the request task group
            # and FastAPI will let it complete after the response. If the
            # email fails, the user is still on the list (DB row is the
            # source of truth) and we log the failure inside the email method.
            import asyncio
            asyncio.create_task(
                email_service.send_lifetime_waitlist_confirmation(
                    to_email=payload.email,
                    position=position,
                )
            )
        except Exception as e:
            # Email failure must not block waitlist join — degrade gracefully.
            logger.warning(f"Waitlist confirmation email dispatch failed (non-fatal): {e}")

        return WaitlistJoinResponse(
            success=True,
            already_on_waitlist=False,
            position=position,
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Waitlist insert failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Could not join waitlist. Please try again.")


# =============================================================================
# PHASE 2 (FUTURE): STRIPE CHECKOUT SESSION
# =============================================================================

@router.post("/checkout", response_model=CheckoutSessionResponse)
async def create_checkout_session(payload: CheckoutSessionRequest) -> CheckoutSessionResponse:
    """Create a Stripe Checkout Session for the Founding Lifetime offer.

    Gated on `lifetime_checkout_enabled` config flag. While in Phase 1 (Coming Soon)
    this endpoint returns 503 — the marketing page never renders the Buy button.

    Pre-checks:
    - Stripe configured (secret + price ID present)
    - Seats available (seats_remaining > 0; race-checked again at webhook time)
    - Email not already linked to an active lifetime purchase

    Note on race conditions: this endpoint does NOT decrement the counter — that
    only happens in the webhook handler when payment is actually captured.
    Reserving seats here would need a pending-seats counter + sweep job; not
    worth the complexity at 500 seats / few-per-hour expected throughput.
    The webhook is the source of truth.
    """
    settings = get_settings()

    if not settings.lifetime_checkout_enabled:
        # Phase 1 — Coming Soon
        raise HTTPException(
            status_code=503,
            detail="Founding Lifetime checkout is not yet open. Join the waitlist for early access.",
        )

    if not settings.stripe_secret_key or not settings.stripe_lifetime_price_id:
        logger.error("Stripe checkout requested but config is missing (secret_key / price_id)")
        raise HTTPException(status_code=503, detail="Payment system temporarily unavailable.")

    # Pre-check: seats remaining (advisory — webhook is the real gatekeeper)
    seats = await get_founder_seats()
    if seats.seats_remaining <= 0:
        raise HTTPException(status_code=410, detail="Founding 500 seats are sold out.")

    # Pre-check: email not already on an active lifetime purchase
    try:
        supabase = get_supabase()
        normalized = payload.email.lower().strip()
        existing = (
            supabase.client.table("web_lifetime_purchases")
            .select("id, status, founder_seat_number")
            .eq("email_normalized", normalized)
            .eq("status", "active")
            .maybe_single()
            .execute()
        )
        if existing and existing.data:
            raise HTTPException(
                status_code=409,
                detail=(
                    f"This email already has Founding Lifetime "
                    f"(seat #{existing.data.get('founder_seat_number')}). "
                    f"Sign in to the app with the same email to activate."
                ),
            )
    except HTTPException:
        raise
    except Exception as e:
        logger.warning(f"Pre-check duplicate-email lookup failed (continuing): {e}")

    # Lazy-import Stripe — keeps the package out of cold-start dependency graph
    # for environments that don't have it installed yet (Phase 1 deploys).
    try:
        import stripe  # type: ignore
    except ImportError:
        logger.error("Stripe SDK not installed but checkout requested")
        raise HTTPException(status_code=503, detail="Payment system not configured.")

    stripe.api_key = settings.stripe_secret_key

    try:
        session = stripe.checkout.Session.create(
            mode="payment",
            payment_method_types=["card"],
            line_items=[{
                "price": settings.stripe_lifetime_price_id,
                "quantity": 1,
            }],
            customer_email=payload.email,
            # Success / cancel redirect to the marketing site, NOT into the app.
            # We never deep-link to the app from the web purchase flow — keeps
            # iOS/Android reviewers from tracing a path between the two surfaces.
            success_url=f"{settings.web_marketing_url}/lifetime/success?session_id={{CHECKOUT_SESSION_ID}}",
            cancel_url=f"{settings.web_marketing_url}/lifetime?canceled=1",
            metadata={
                "purchase_type": "founder_lifetime",
                "source": payload.source or "direct",
            },
            # Tax handled by Stripe Tax (must be enabled in Stripe Dashboard
            # for non-US sales — covers VAT, GST, etc. without manual work).
            automatic_tax={"enabled": True},
            # Allow promo codes (Black Friday, influencer codes, etc.)
            allow_promotion_codes=True,
        )

        # Insert pending row — webhook will flip status to 'active' and assign seat
        supabase = get_supabase()
        supabase.client.table("web_lifetime_purchases").insert({
            "stripe_session_id": session.id,
            "email": payload.email,
            "amount_paid_cents": settings.lifetime_price_usd_cents,
            "currency": "usd",
            "status": "pending",
        }).execute()

        logger.info(f"Stripe Checkout Session created: {session.id} for {payload.email}")

        return CheckoutSessionResponse(
            checkout_url=session.url,
            session_id=session.id,
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Stripe checkout creation failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Could not start checkout. Please try again.")


# =============================================================================
# STRIPE WEBHOOK HANDLER (server-side, idempotent)
# =============================================================================

@router.post("/webhook")
async def stripe_webhook(
    request: Request,
    background_tasks: BackgroundTasks,
    stripe_signature: Optional[str] = Header(None, alias="Stripe-Signature"),
):
    """Handle Stripe webhook events for lifetime purchases.

    Events we handle:
    - checkout.session.completed → mark purchase active, claim a founder seat
    - charge.refunded → mark purchase refunded, release the seat
    - charge.dispute.created → mark purchase disputed (doesn't release seat — manual review)

    Idempotency: webhook deliveries can be retried by Stripe. We protect against
    duplicates with:
    - `stripe_session_id` UNIQUE constraint on web_lifetime_purchases
    - status check before re-claiming a seat (only 'pending' → 'active' claims)
    - All updates are no-ops if the target state is already reached

    Security: signature verification is mandatory. If `STRIPE_WEBHOOK_SECRET`
    isn't configured, this endpoint returns 503 — never accepts unsigned events.
    """
    settings = get_settings()
    if not settings.stripe_webhook_secret:
        logger.error("Stripe webhook called but STRIPE_WEBHOOK_SECRET not configured")
        raise HTTPException(status_code=503, detail="Webhook handler not configured.")

    body = await request.body()

    try:
        import stripe  # type: ignore
    except ImportError:
        raise HTTPException(status_code=503, detail="Payment system not configured.")

    # Verify signature — rejects forged webhooks
    try:
        event = stripe.Webhook.construct_event(
            payload=body,
            sig_header=stripe_signature,
            secret=settings.stripe_webhook_secret,
        )
    except ValueError:
        logger.warning("Stripe webhook: invalid JSON payload")
        raise HTTPException(status_code=400, detail="Invalid payload")
    except stripe.error.SignatureVerificationError:
        logger.warning(f"Stripe webhook: signature verification failed (sig={stripe_signature[:16] if stripe_signature else 'none'}...)")
        raise HTTPException(status_code=400, detail="Invalid signature")

    event_type = event.get("type")
    obj = event.get("data", {}).get("object", {})

    logger.info(f"Stripe webhook received: type={event_type} id={event.get('id')}")

    # Hand off to background task so we ack the webhook quickly (Stripe times out at 10s)
    background_tasks.add_task(_process_webhook_event, event_type, obj)

    return {"received": True}


async def _process_webhook_event(event_type: str, obj: dict):
    """Background processor for Stripe webhook events. Logs but never raises."""
    try:
        if event_type == "checkout.session.completed":
            await _handle_checkout_completed(obj)
        elif event_type in ("charge.refunded", "refund.created"):
            await _handle_refund(obj)
        elif event_type == "charge.dispute.created":
            await _handle_dispute(obj)
        else:
            # Many event types we don't act on (e.g. payment_intent.succeeded,
            # which fires before checkout.session.completed). Silent skip.
            pass
    except Exception as e:
        logger.error(f"Webhook processor failed for {event_type}: {e}", exc_info=True)


async def _handle_checkout_completed(session: dict):
    """checkout.session.completed → activate the purchase + claim a founder seat.

    Idempotent: if the row is already 'active', this is a no-op. Re-deliveries
    don't double-claim seats.
    """
    supabase = get_supabase()
    session_id = session.get("id")
    if not session_id:
        logger.warning("checkout.session.completed missing id")
        return

    # Look up the pending row we created at checkout creation time
    existing = (
        supabase.client.table("web_lifetime_purchases")
        .select("id, status, founder_seat_number")
        .eq("stripe_session_id", session_id)
        .maybe_single()
        .execute()
    )

    # Already active → idempotent no-op
    if existing and existing.data and existing.data.get("status") == "active":
        logger.info(f"Webhook: session {session_id} already active, skipping")
        return

    # Defensive: if we missed creating the pending row (e.g. checkout endpoint
    # failed to insert), build one from the webhook payload now.
    if not (existing and existing.data):
        customer_email = (
            session.get("customer_details", {}).get("email")
            or session.get("customer_email")
        )
        if not customer_email:
            logger.error(f"Webhook: session {session_id} has no email, cannot record purchase")
            return
        supabase.client.table("web_lifetime_purchases").insert({
            "stripe_session_id": session_id,
            "email": customer_email,
            "amount_paid_cents": session.get("amount_total", 0),
            "currency": session.get("currency", "usd"),
            "status": "pending",
        }).execute()

    # Atomically claim a founder seat number (returns NULL if sold out)
    seat_result = supabase.client.rpc("claim_founder_seat").execute()
    seat_number = seat_result.data if isinstance(seat_result.data, int) else None

    if seat_number is None:
        # Sold out — refund the customer and bail.
        # We charge ourselves the Stripe processing fee (~3% of $149.99 = $4.50)
        # to keep the user experience clean. Better than letting them wait.
        logger.warning(f"Webhook: session {session_id} completed but seats are sold out — issuing refund")
        try:
            import stripe  # type: ignore
            settings = get_settings()
            stripe.api_key = settings.stripe_secret_key
            payment_intent = session.get("payment_intent")
            if payment_intent:
                stripe.Refund.create(
                    payment_intent=payment_intent,
                    reason="requested_by_customer",
                    metadata={"reason": "founding_500_sold_out"},
                )
        except Exception as e:
            logger.error(f"Auto-refund failed for sold-out session {session_id}: {e}")
        # Mark the row so we don't re-process
        supabase.client.table("web_lifetime_purchases").update({
            "status": "refunded",
            "refunded_at": datetime.now(timezone.utc).isoformat(),
            "last_webhook_event": "checkout.session.completed (sold out)",
            "last_webhook_at": datetime.now(timezone.utc).isoformat(),
        }).eq("stripe_session_id", session_id).execute()
        return

    # Happy path: flip status to 'active' and stamp the seat number
    supabase.client.table("web_lifetime_purchases").update({
        "status": "active",
        "founder_seat_number": seat_number,
        "stripe_payment_intent_id": session.get("payment_intent"),
        "stripe_customer_id": session.get("customer"),
        "amount_paid_cents": session.get("amount_total"),
        "currency": session.get("currency", "usd"),
        "activated_at": datetime.now(timezone.utc).isoformat(),
        "last_webhook_event": "checkout.session.completed",
        "last_webhook_at": datetime.now(timezone.utc).isoformat(),
    }).eq("stripe_session_id", session_id).execute()

    customer_email = (
        session.get("customer_details", {}).get("email")
        or session.get("customer_email")
    )

    # Mark waitlist row as converted so we don't email them the "checkout open" announcement
    if customer_email:
        normalized = customer_email.lower().strip()
        supabase.client.table("lifetime_waitlist").update({
            "converted_session_id": session_id,
        }).eq("email_normalized", normalized).execute()

        # If the user already has an app account, link the entitlement immediately.
        # Otherwise this happens on first sign-in via /subscriptions/status.
        user_lookup = (
            supabase.client.table("users")
            .select("id")
            .eq("email", customer_email)
            .maybe_single()
            .execute()
        )
        if user_lookup and user_lookup.data:
            user_id = user_lookup.data.get("id")
            if user_id:
                supabase.client.rpc(
                    "link_web_lifetime_to_user",
                    {"p_user_id": user_id, "p_email": customer_email},
                ).execute()
                logger.info(f"Founder seat #{seat_number} → user {user_id} (existing account)")
        else:
            logger.info(f"Founder seat #{seat_number} → email {customer_email} (no app account yet)")

        # Send the activation guide email (this is the user's permanent record
        # of their seat number + which email to use to sign in to the app).
        try:
            from services.email_service import get_email_service
            email_service = get_email_service()
            await email_service.send_lifetime_purchase_confirmation(
                to_email=customer_email,
                seat_number=seat_number,
                amount_paid_cents=int(session.get("amount_total") or get_settings().lifetime_price_usd_cents),
                receipt_url=session.get("receipt_url"),
            )
        except Exception as e:
            # Email failure must NEVER undo the entitlement grant. The DB row
            # is the source of truth — they have lifetime regardless. We just
            # log so support can manually re-send if needed.
            logger.error(f"Purchase confirmation email failed (entitlement is still granted): {e}", exc_info=True)

    logger.info(f"✅ Lifetime purchase activated: session={session_id} seat={seat_number}")


async def _handle_refund(charge_or_refund: dict):
    """Mark a purchase as refunded and release the founder seat.

    Stripe sends both `charge.refunded` and `refund.created` for the same event;
    we handle both and rely on idempotency in the DB to avoid double-releasing.
    """
    supabase = get_supabase()
    payment_intent = charge_or_refund.get("payment_intent")
    if not payment_intent:
        # `refund.created` payload structure differs slightly — fish for it
        payment_intent = charge_or_refund.get("charge", {}).get("payment_intent") if isinstance(charge_or_refund.get("charge"), dict) else None

    if not payment_intent:
        logger.warning("Refund webhook missing payment_intent — cannot link to purchase")
        return

    purchase = (
        supabase.client.table("web_lifetime_purchases")
        .select("id, status, founder_seat_number, user_id")
        .eq("stripe_payment_intent_id", payment_intent)
        .maybe_single()
        .execute()
    )
    if not (purchase and purchase.data):
        logger.warning(f"Refund webhook: no purchase row for payment_intent={payment_intent}")
        return

    if purchase.data.get("status") == "refunded":
        return  # Idempotent

    seat = purchase.data.get("founder_seat_number")
    user_id = purchase.data.get("user_id")

    supabase.client.table("web_lifetime_purchases").update({
        "status": "refunded",
        "refunded_at": datetime.now(timezone.utc).isoformat(),
        "last_webhook_event": "charge.refunded",
        "last_webhook_at": datetime.now(timezone.utc).isoformat(),
    }).eq("id", purchase.data["id"]).execute()

    # Release the seat back to the pool
    if seat:
        supabase.client.rpc("release_founder_seat", {"p_seat_number": seat}).execute()

    # Strip lifetime tier from the user (downgrade silently to free)
    if user_id:
        supabase.client.table("user_subscriptions").update({
            "tier": "free",
            "status": "expired",
            "is_lifetime": False,
        }).eq("user_id", user_id).execute()

    logger.info(f"💸 Lifetime refund: seat #{seat} released, user_id={user_id}")


async def _handle_dispute(dispute: dict):
    """Mark a purchase as disputed. Does NOT release the seat — needs manual review.

    Stripe disputes (chargebacks) often resolve in our favor. Releasing the seat
    immediately would let someone else claim seat #N while the original purchaser
    still owns it on Stripe's side. Better to leave it locked + alert the team.
    """
    supabase = get_supabase()
    charge_id = dispute.get("charge")
    if not charge_id:
        return

    # Stripe sends the charge ID in disputes; look up via payment_intent join
    try:
        import stripe  # type: ignore
        settings = get_settings()
        stripe.api_key = settings.stripe_secret_key
        charge = stripe.Charge.retrieve(charge_id)
        payment_intent = charge.get("payment_intent")
    except Exception as e:
        logger.error(f"Dispute webhook: could not look up charge {charge_id}: {e}")
        return

    if not payment_intent:
        return

    supabase.client.table("web_lifetime_purchases").update({
        "status": "disputed",
        "last_webhook_event": "charge.dispute.created",
        "last_webhook_at": datetime.now(timezone.utc).isoformat(),
    }).eq("stripe_payment_intent_id", payment_intent).execute()

    logger.warning(f"⚠️ Lifetime DISPUTE on payment_intent={payment_intent} — manual review needed")


# =============================================================================
# CHECKOUT SUCCESS POLLING (used by /lifetime/success page)
# =============================================================================

@router.get("/checkout-status/{session_id}")
async def get_checkout_status(session_id: str):
    """Poll endpoint for the /lifetime/success page.

    The success redirect from Stripe doesn't guarantee the webhook has fired
    yet (race window: Stripe redirects browser before delivering webhook).
    Frontend polls this endpoint for up to ~10s while the webhook lands.

    Returns:
        status: 'pending' | 'active' | 'refunded' | 'disputed'
        seat_number: int | None  (only present when active)
        email: str (the email on the purchase, for "sign in with this email" copy)
    """
    supabase = get_supabase()
    result = (
        supabase.client.table("web_lifetime_purchases")
        .select("status, founder_seat_number, email")
        .eq("stripe_session_id", session_id)
        .maybe_single()
        .execute()
    )
    if not (result and result.data):
        return {"status": "pending", "seat_number": None, "email": None}

    return {
        "status": result.data.get("status", "pending"),
        "seat_number": result.data.get("founder_seat_number"),
        "email": result.data.get("email"),
    }
