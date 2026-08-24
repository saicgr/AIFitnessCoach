-- Migration 2435: Persisted claim table for the Sunday cardio-digest push
--
-- backend/api/v1/weekly_wrapped_cron.py's cardio-digest send (SLICE_DIGEST)
-- deduped on `_CARDIO_PUSH_SENT_THIS_WEEK`, an in-process Python set. The
-- module's own comment admitted "we don't have a schema column yet". That
-- set only catches a repeat that lands on the SAME gunicorn worker --
-- render.yaml runs this service with `-w 2` (two workers, two separate
-- memory spaces), so a retry or an overlapping scheduler call landing on
-- the OTHER worker sent a duplicate cardio-digest push to a real user.
--
-- Fix: a real table with a UNIQUE(user_id, week_start) constraint, claimed
-- via INSERT *before* the send (claim-then-send), mirroring
-- push_nudge_cron._try_dedup_insert / push_nudge_log and
-- trial_coach_cron._try_claim_slot / trial_coach_messages_sent. The insert
-- is the atomic cross-process dedup gate; a UNIQUE-violation means another
-- worker already claimed this user's week and we skip.

CREATE TABLE IF NOT EXISTS cardio_digest_sent (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    week_start DATE NOT NULL,
    sent_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, week_start)
);

-- RLS: same shape as push_nudge_log / trial_coach_messages_sent — server
-- (service role) can read/write everything, a user can read only their own
-- rows, nobody else can read or write.
ALTER TABLE cardio_digest_sent ENABLE ROW LEVEL SECURITY;

CREATE POLICY "cardio_digest_sent_service_role_all" ON "public"."cardio_digest_sent"
  USING ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)))
  WITH CHECK ((((select current_setting('role'::text)) = 'service_role'::text) OR ((select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text) OR ((select auth.role()) = 'service_role'::text)));

CREATE POLICY "cardio_digest_sent_user_select" ON "public"."cardio_digest_sent"
  FOR SELECT
  USING (((select auth.uid()) = user_id));

-- VERIFY: select user_id, week_start, count(*) from cardio_digest_sent
--   group by 1, 2 having count(*) > 1; -- expect 0 rows
