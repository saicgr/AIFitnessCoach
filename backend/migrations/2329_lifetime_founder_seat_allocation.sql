-- 2329_lifetime_founder_seat_allocation.sql
--
-- Fixes the Founding-500 seat-number collision class.
--
-- BEFORE (migration 2042):
--   claim_founder_seat()      -> returns seats_claimed + 1   (a bare counter)
--   release_founder_seat(n)   -> seats_claimed = seats_claimed - 1
--                                ^ ignored its argument entirely
--
--   Sell 1,2,3 -> refund #2 -> counter drops to 2 -> the NEXT buyer is issued
--   seat 3, which is already held. UNIQUE (founder_seat_number) rejects the
--   UPDATE, the exception is swallowed by the webhook's background processor,
--   and the purchase is stranded at status='pending': money captured, no
--   entitlement, no confirmation email, /lifetime/success spins forever.
--   The 30-day refund promise on the /lifetime FAQ puts this on the happy path.
--
--   A second, narrower race: claim and stamp were two separate statements in
--   two separate transactions, so two concurrent webhooks could be handed the
--   same number even with no refunds involved.
--
-- AFTER:
--   activate_founder_purchase(...) allocates the lowest FREE seat and stamps
--   the purchase row in ONE transaction, serialized on the counter row. Seat
--   ownership is derived from web_lifetime_purchases.founder_seat_number
--   (the UNIQUE column) instead of tracked in a drift-prone counter.
--   release_founder_seat(n) actually frees seat n, preserving it in
--   released_seat_number for support/audit.
--
--   seats_claimed becomes a derived cache of "how many numbers are held",
--   recomputed on every allocate/release, so the public counter can no longer
--   drift away from reality.

-- ---------------------------------------------------------------------------
-- 1. Preserve the seat number of a refunded founder (audit trail), since the
--    live column has to be NULLed to make the number reusable.
-- ---------------------------------------------------------------------------
ALTER TABLE web_lifetime_purchases
    ADD COLUMN IF NOT EXISTS released_seat_number INTEGER;

COMMENT ON COLUMN web_lifetime_purchases.released_seat_number IS
    'Founder seat this purchase held before it was refunded. Kept for support/audit; the live seat is founder_seat_number.';

-- ---------------------------------------------------------------------------
-- 2. Atomic allocate + stamp. Returns the seat number, or NULL when sold out
--    (the caller refunds) or when the session row is missing.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION activate_founder_purchase(
    p_session_id     TEXT,
    p_payment_intent TEXT    DEFAULT NULL,
    p_customer_id    TEXT    DEFAULT NULL,
    p_amount_cents   INTEGER DEFAULT NULL,
    p_currency       TEXT    DEFAULT NULL
)
RETURNS INTEGER
LANGUAGE plpgsql
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
    v_total  INTEGER;
    v_seat   INTEGER;
    v_status TEXT;
    v_held   INTEGER;
BEGIN
    -- Serialize every activation on the single counter row. Held until COMMIT,
    -- so allocate-and-stamp is indivisible: no two webhooks can be handed the
    -- same number.
    SELECT seats_total INTO v_total
      FROM lifetime_founder_seats
     WHERE id = 1
       FOR UPDATE;

    IF v_total IS NULL THEN
        RETURN NULL;
    END IF;

    SELECT status, founder_seat_number
      INTO v_status, v_seat
      FROM web_lifetime_purchases
     WHERE stripe_session_id = p_session_id;

    IF v_status IS NULL THEN
        RETURN NULL;   -- no such session; caller inserts the row first
    END IF;

    -- Idempotent: a Stripe re-delivery must not allocate a second seat.
    IF v_status = 'active' AND v_seat IS NOT NULL THEN
        RETURN v_seat;
    END IF;

    -- Lowest number nobody currently holds. Refunded rows have already had
    -- their number NULLed by release_founder_seat, so numbers are reusable;
    -- disputed rows keep theirs (deliberately not released pending review).
    SELECT s INTO v_seat
      FROM generate_series(1, v_total) AS s
     WHERE NOT EXISTS (
               SELECT 1
                 FROM web_lifetime_purchases p
                WHERE p.founder_seat_number = s
           )
     ORDER BY s
     LIMIT 1;

    IF v_seat IS NULL THEN
        RETURN NULL;   -- genuinely sold out
    END IF;

    UPDATE web_lifetime_purchases
       SET status                   = 'active',
           founder_seat_number      = v_seat,
           stripe_payment_intent_id = COALESCE(p_payment_intent, stripe_payment_intent_id),
           stripe_customer_id       = COALESCE(p_customer_id, stripe_customer_id),
           amount_paid_cents        = COALESCE(p_amount_cents, amount_paid_cents),
           currency                 = COALESCE(p_currency, currency),
           activated_at             = COALESCE(activated_at, NOW()),
           last_webhook_event       = 'checkout.session.completed',
           last_webhook_at          = NOW()
     WHERE stripe_session_id = p_session_id;

    SELECT COUNT(*) INTO v_held
      FROM web_lifetime_purchases
     WHERE founder_seat_number IS NOT NULL;

    UPDATE lifetime_founder_seats
       SET seats_claimed = v_held,
           updated_at    = NOW()
     WHERE id = 1;

    RETURN v_seat;
END;
$function$;

COMMENT ON FUNCTION activate_founder_purchase(TEXT, TEXT, TEXT, INTEGER, TEXT) IS
    'Atomically allocate the lowest free Founding-500 seat and activate the purchase row. Idempotent per stripe_session_id. Returns NULL when sold out or the session row is missing.';

-- ---------------------------------------------------------------------------
-- 3. release_founder_seat now frees the seat it was given (it previously
--    ignored the argument and just decremented the counter).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION release_founder_seat(p_seat_number INTEGER)
RETURNS VOID
LANGUAGE plpgsql
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
    v_held INTEGER;
BEGIN
    IF p_seat_number IS NULL THEN
        RETURN;
    END IF;

    PERFORM 1 FROM lifetime_founder_seats WHERE id = 1 FOR UPDATE;

    -- Only a row that has actually lost its entitlement gives up its number.
    -- Guarding on status means a stray/duplicate release can't strip an active
    -- founder's badge.
    UPDATE web_lifetime_purchases
       SET released_seat_number = COALESCE(released_seat_number, founder_seat_number),
           founder_seat_number  = NULL
     WHERE founder_seat_number = p_seat_number
       AND status = 'refunded';

    SELECT COUNT(*) INTO v_held
      FROM web_lifetime_purchases
     WHERE founder_seat_number IS NOT NULL;

    UPDATE lifetime_founder_seats
       SET seats_claimed = v_held,
           updated_at    = NOW()
     WHERE id = 1;
END;
$function$;

COMMENT ON FUNCTION release_founder_seat(INTEGER) IS
    'Free a refunded founder seat so the number can be reissued. Recomputes seats_claimed from held numbers. No-op unless the holding row is status=refunded.';

-- ---------------------------------------------------------------------------
-- 4. Drop the bare counter. Its contract (return seats_claimed + 1, stamped by
--    a separate statement) is what produced the collision; leaving it callable
--    invites the bug back.
-- ---------------------------------------------------------------------------
DROP FUNCTION IF EXISTS claim_founder_seat();

-- ---------------------------------------------------------------------------
-- 5. Reconcile the public counter with reality once, in case it already
--    drifted (a bare decrement could run without any seat changing hands).
-- ---------------------------------------------------------------------------
UPDATE lifetime_founder_seats
   SET seats_claimed = (
           SELECT COUNT(*)
             FROM web_lifetime_purchases
            WHERE founder_seat_number IS NOT NULL
       ),
       updated_at = NOW()
 WHERE id = 1;
