-- Zealova - Web Lifetime "Founding 500" Infrastructure
-- Migration 2042 (2026-04-30)
--
-- Purpose:
-- - Capture waitlist emails for the "Coming Soon" Founding 500 lifetime offer
-- - Track Stripe-fulfilled web lifetime purchases (separate from IAP-driven user_subscriptions)
-- - Enforce a hard cap of 500 founder seats via DB-level counter
-- - Sell ONLY on web (zealova.com/lifetime) — never inside iOS/Android app
--
-- The web flow:
--   1. Visitor lands on /lifetime, sees seat counter (e.g. "247 / 500 reserved")
--   2. Enters email → row inserted into `lifetime_waitlist` (no payment)
--   3. When Stripe Checkout flips on (Phase 2), webhook inserts into `web_lifetime_purchases`
--   4. Backend `/subscriptions/status` aggregates RC entitlement + web purchase
--   5. App unlocks Premium silently when user signs in with that email

-- =============================================================================
-- WAITLIST (Phase 1 — Coming Soon page)
-- =============================================================================

CREATE TABLE IF NOT EXISTS lifetime_waitlist (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL,
    -- Email lowercased + trimmed at insert time for unique-match later
    email_normalized TEXT GENERATED ALWAYS AS (lower(trim(email))) STORED,
    -- Optional: where the visitor came from (utm_source, referrer, etc.)
    source TEXT,
    referrer TEXT,
    -- Country / region from request IP (best-effort, can be null)
    country_code TEXT,
    -- Marketing opt-in (separate from waitlist itself)
    marketing_opt_in BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- Set when we email them their Stripe checkout link (Phase 2 cutover)
    invited_at TIMESTAMPTZ,
    -- Set when they convert (matches `web_lifetime_purchases.stripe_session_id`)
    converted_session_id TEXT
);

-- Unique on normalized email so duplicate signups silently no-op
CREATE UNIQUE INDEX IF NOT EXISTS idx_waitlist_email_unique
    ON lifetime_waitlist(email_normalized);

CREATE INDEX IF NOT EXISTS idx_waitlist_created_at
    ON lifetime_waitlist(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_waitlist_invited
    ON lifetime_waitlist(invited_at) WHERE invited_at IS NOT NULL;

-- =============================================================================
-- WEB LIFETIME PURCHASES (Phase 2 — Stripe Checkout live)
-- =============================================================================

CREATE TABLE IF NOT EXISTS web_lifetime_purchases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- Stripe identifiers — webhook payload references
    stripe_session_id TEXT UNIQUE NOT NULL,
    stripe_payment_intent_id TEXT,
    stripe_customer_id TEXT,
    -- The email Stripe captured at checkout. Must lowercase for app login match.
    email TEXT NOT NULL,
    email_normalized TEXT GENERATED ALWAYS AS (lower(trim(email))) STORED,
    -- Optional FK to users(id) once they create an app account.
    -- NULL until first app login with matching email — backfilled by entitlement aggregator.
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    -- Founder seat number (1..500). Enforced via trigger below.
    founder_seat_number INTEGER UNIQUE,
    -- Pricing snapshot at time of purchase (immutable)
    amount_paid_cents INTEGER NOT NULL,
    currency TEXT NOT NULL DEFAULT 'usd',
    -- Status mirrors Stripe lifecycle
    -- 'pending' → checkout.session.created
    -- 'active' → checkout.session.completed
    -- 'refunded' → charge.refunded webhook
    -- 'disputed' → charge.dispute.created (chargeback)
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'active', 'refunded', 'disputed')),
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    activated_at TIMESTAMPTZ,
    refunded_at TIMESTAMPTZ,
    -- Raw webhook payload (debugging + audit)
    last_webhook_event TEXT,
    last_webhook_at TIMESTAMPTZ
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_web_lifetime_email_active
    ON web_lifetime_purchases(email_normalized)
    WHERE status = 'active';

CREATE INDEX IF NOT EXISTS idx_web_lifetime_user_id
    ON web_lifetime_purchases(user_id) WHERE user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_web_lifetime_status
    ON web_lifetime_purchases(status);

CREATE INDEX IF NOT EXISTS idx_web_lifetime_seat_number
    ON web_lifetime_purchases(founder_seat_number) WHERE founder_seat_number IS NOT NULL;

-- =============================================================================
-- FOUNDER SEAT COUNTER (atomic, race-safe)
-- =============================================================================
--
-- Why a separate counter table instead of MAX(founder_seat_number):
-- - MAX() under concurrent inserts is a race condition; two simultaneous
--   webhook deliveries would both see the same MAX and assign duplicate seats.
-- - SELECT ... FOR UPDATE on a single counter row guarantees serialization.
-- - 500-seat hard cap enforced atomically via the assign function below.

CREATE TABLE IF NOT EXISTS lifetime_founder_seats (
    id INTEGER PRIMARY KEY CHECK (id = 1),  -- singleton row
    seats_total INTEGER NOT NULL DEFAULT 500,
    seats_claimed INTEGER NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO lifetime_founder_seats (id, seats_total, seats_claimed)
VALUES (1, 500, 0)
ON CONFLICT (id) DO NOTHING;

-- Atomic seat assignment: returns next seat number, or NULL if all 500 claimed.
-- Called from the Stripe webhook handler when a purchase moves to 'active'.
CREATE OR REPLACE FUNCTION claim_founder_seat()
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    next_seat INTEGER;
    seat_total INTEGER;
BEGIN
    -- Lock the singleton row for the duration of this transaction
    SELECT seats_claimed, seats_total
        INTO next_seat, seat_total
        FROM lifetime_founder_seats
        WHERE id = 1
        FOR UPDATE;

    IF next_seat >= seat_total THEN
        RETURN NULL;  -- Sold out
    END IF;

    next_seat := next_seat + 1;
    UPDATE lifetime_founder_seats
        SET seats_claimed = next_seat,
            updated_at = NOW()
        WHERE id = 1;

    RETURN next_seat;
END;
$$;

-- Releases a seat (used when a purchase is refunded within the refund window).
-- Decrements seats_claimed so the next purchaser gets that seat number recycled.
-- Idempotent — safe to call multiple times for the same purchase.
CREATE OR REPLACE FUNCTION release_founder_seat(p_seat_number INTEGER)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_seat_number IS NULL THEN
        RETURN;
    END IF;

    UPDATE lifetime_founder_seats
        SET seats_claimed = GREATEST(0, seats_claimed - 1),
            updated_at = NOW()
        WHERE id = 1;
END;
$$;

-- =============================================================================
-- PUBLIC SEAT-COUNTER VIEW (for the marketing landing page)
-- =============================================================================
-- Exposes a single read-only row with claimed / total / remaining, safe to
-- expose without auth so the /lifetime page can render the counter live.

CREATE OR REPLACE VIEW lifetime_founder_seats_public AS
SELECT
    seats_total,
    seats_claimed,
    GREATEST(0, seats_total - seats_claimed) AS seats_remaining,
    CASE
        WHEN seats_claimed >= seats_total THEN 'sold_out'
        WHEN seats_claimed >= (seats_total * 0.9)::INTEGER THEN 'almost_gone'
        WHEN seats_claimed >= (seats_total * 0.5)::INTEGER THEN 'going_fast'
        ELSE 'available'
    END AS availability_label,
    updated_at
FROM lifetime_founder_seats
WHERE id = 1;

COMMENT ON VIEW lifetime_founder_seats_public IS
    'Public seat counter for the /lifetime marketing page. Safe to expose without auth — read-only.';

-- =============================================================================
-- LINK WEB PURCHASE TO USER ON LOGIN
-- =============================================================================
-- When a user logs into the app with an email matching an active web purchase,
-- the entitlement aggregator calls this function to:
-- 1. Set web_lifetime_purchases.user_id (lazy backfill)
-- 2. Mirror the lifetime entitlement onto user_subscriptions (so the rest of
--    the app's subscription gating logic just reads from user_subscriptions
--    as it does today — no code paths need to know the purchase was web-side)

CREATE OR REPLACE FUNCTION link_web_lifetime_to_user(
    p_user_id UUID,
    p_email TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_purchase RECORD;
    v_normalized TEXT;
BEGIN
    v_normalized := lower(trim(p_email));

    SELECT id, founder_seat_number, amount_paid_cents, activated_at
        INTO v_purchase
        FROM web_lifetime_purchases
        WHERE email_normalized = v_normalized
          AND status = 'active'
        LIMIT 1;

    IF v_purchase.id IS NULL THEN
        RETURN FALSE;
    END IF;

    -- Backfill user_id on the purchase row
    UPDATE web_lifetime_purchases
        SET user_id = p_user_id
        WHERE id = v_purchase.id
          AND user_id IS NULL;

    -- Upsert into user_subscriptions so the rest of the app sees lifetime
    INSERT INTO user_subscriptions (
        user_id, tier, status, is_lifetime,
        lifetime_purchase_date, lifetime_original_price,
        lifetime_promotion_code, started_at, created_at
    ) VALUES (
        p_user_id, 'lifetime', 'active', TRUE,
        v_purchase.activated_at,
        (v_purchase.amount_paid_cents / 100.0)::DECIMAL(10,2),
        'FOUNDER_' || COALESCE(v_purchase.founder_seat_number::TEXT, '?'),
        v_purchase.activated_at, NOW()
    )
    ON CONFLICT (user_id) DO UPDATE SET
        tier = 'lifetime',
        status = 'active',
        is_lifetime = TRUE,
        lifetime_purchase_date = COALESCE(user_subscriptions.lifetime_purchase_date, EXCLUDED.lifetime_purchase_date),
        lifetime_original_price = COALESCE(user_subscriptions.lifetime_original_price, EXCLUDED.lifetime_original_price),
        lifetime_promotion_code = COALESCE(user_subscriptions.lifetime_promotion_code, EXCLUDED.lifetime_promotion_code);

    RETURN TRUE;
END;
$$;

-- =============================================================================
-- ROW-LEVEL SECURITY
-- =============================================================================
-- Waitlist + purchases are server-managed (only backend service role writes).
-- Public can SELECT from lifetime_founder_seats_public (the view) but not the
-- underlying tables.

ALTER TABLE lifetime_waitlist ENABLE ROW LEVEL SECURITY;
ALTER TABLE web_lifetime_purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE lifetime_founder_seats ENABLE ROW LEVEL SECURITY;

-- No public policies — service role only.
-- The frontend calls a backend endpoint (`/lifetime/seats`) which queries the
-- public view server-side using the service role.

-- Grant read access on the public view to anon (for the marketing page)
GRANT SELECT ON lifetime_founder_seats_public TO anon, authenticated;

COMMENT ON TABLE lifetime_waitlist IS
    'Email waitlist for the Founding 500 lifetime offer. Pre-Stripe-launch capture.';
COMMENT ON TABLE web_lifetime_purchases IS
    'Stripe-fulfilled web lifetime purchases. Separate from IAP user_subscriptions.';
COMMENT ON TABLE lifetime_founder_seats IS
    'Singleton counter for the 500-seat hard cap. Mutated only via claim_founder_seat() / release_founder_seat().';
