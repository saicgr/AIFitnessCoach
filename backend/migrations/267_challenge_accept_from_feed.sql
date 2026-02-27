-- Migration: Challenge Accept-From-Feed Support
-- Created: 2026-02-25
-- Description: Fix INSERT trigger for accept-from-feed flow, add completion trigger,
--              ensure abandoned/retry columns exist, and update RLS for service-role inserts.

-- ============================================================
-- 1. FIX INSERT TRIGGER: create_challenge_notification
--    Old behavior: Always creates 'challenge_received' for to_user.
--    New behavior: Conditional on status:
--      - status='pending'  -> 'challenge_received' for to_user (original direct challenge)
--      - status='accepted' -> 'challenge_accepted' for from_user (accept-from-feed)
-- ============================================================

CREATE OR REPLACE FUNCTION create_challenge_notification()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'pending' THEN
        -- Direct challenge: notify the recipient
        INSERT INTO challenge_notifications (challenge_id, user_id, notification_type)
        VALUES (NEW.id, NEW.to_user_id, 'challenge_received');
    ELSIF NEW.status = 'accepted' THEN
        -- Accept-from-feed: notify the original poster that someone accepted
        INSERT INTO challenge_notifications (challenge_id, user_id, notification_type)
        VALUES (NEW.id, NEW.from_user_id, 'challenge_accepted');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION create_challenge_notification IS
    'Conditional notification on challenge INSERT: pending->challenge_received for to_user, accepted->challenge_accepted for from_user';

-- ============================================================
-- 2. ADD COMPLETION TRIGGER: notify_challenge_completed
--    Fires on UPDATE when status changes from 'accepted' to 'completed'.
--    Creates 'challenge_beaten' if did_beat=true, else 'challenge_completed'.
--    Notifies the from_user (the original poster / challenger).
-- ============================================================

CREATE OR REPLACE FUNCTION notify_challenge_completed()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'completed' AND OLD.status = 'accepted' THEN
        INSERT INTO challenge_notifications (challenge_id, user_id, notification_type)
        VALUES (
            NEW.id,
            NEW.from_user_id,
            CASE WHEN NEW.did_beat = true THEN 'challenge_beaten' ELSE 'challenge_completed' END
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if any, then create
DROP TRIGGER IF EXISTS trigger_notify_challenge_completed ON workout_challenges;

CREATE TRIGGER trigger_notify_challenge_completed
AFTER UPDATE ON workout_challenges
FOR EACH ROW EXECUTE FUNCTION notify_challenge_completed();

COMMENT ON FUNCTION notify_challenge_completed IS
    'Notify from_user when challenge is completed: challenge_beaten if did_beat else challenge_completed';

-- ============================================================
-- 3. ENSURE ABANDONED / RETRY COLUMNS EXIST
--    These were added in migrations 031 and 032, but use IF NOT EXISTS
--    to be safe in case those haven't been applied.
-- ============================================================

ALTER TABLE workout_challenges ADD COLUMN IF NOT EXISTS abandoned_at TIMESTAMPTZ;
ALTER TABLE workout_challenges ADD COLUMN IF NOT EXISTS quit_reason TEXT;
ALTER TABLE workout_challenges ADD COLUMN IF NOT EXISTS partial_stats JSONB;
ALTER TABLE workout_challenges ADD COLUMN IF NOT EXISTS is_retry BOOLEAN DEFAULT false;
ALTER TABLE workout_challenges ADD COLUMN IF NOT EXISTS retried_from_challenge_id UUID;
ALTER TABLE workout_challenges ADD COLUMN IF NOT EXISTS retry_count INTEGER DEFAULT 0;

-- ============================================================
-- 4. RLS: Allow service role to insert challenges (accept-from-feed)
--    The existing INSERT policy requires from_user_id = auth.uid().
--    For accept-from-feed, the backend inserts with from_user_id set to
--    the poster (not the current user). The service role key bypasses RLS
--    by default in Supabase, but if RLS is enforced, we need a policy.
-- ============================================================

-- Policy for service role to insert any challenge
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'workout_challenges'
          AND policyname = 'Service role can insert challenges'
    ) THEN
        EXECUTE $policy$
            CREATE POLICY "Service role can insert challenges"
                ON workout_challenges FOR INSERT
                WITH CHECK (
                    (current_setting('request.jwt.claims', true)::json->>'role') = 'service_role'
                )
        $policy$;
    END IF;
END
$$;

-- Also allow service role to update challenges (for completing from backend)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'workout_challenges'
          AND policyname = 'Service role can update challenges'
    ) THEN
        EXECUTE $policy$
            CREATE POLICY "Service role can update challenges"
                ON workout_challenges FOR UPDATE
                USING (
                    (current_setting('request.jwt.claims', true)::json->>'role') = 'service_role'
                )
        $policy$;
    END IF;
END
$$;

-- Allow service role to select challenges (for GET endpoint)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'workout_challenges'
          AND policyname = 'Service role can select challenges'
    ) THEN
        EXECUTE $policy$
            CREATE POLICY "Service role can select challenges"
                ON workout_challenges FOR SELECT
                USING (
                    (current_setting('request.jwt.claims', true)::json->>'role') = 'service_role'
                )
        $policy$;
    END IF;
END
$$;

-- Also add service role INSERT policy for challenge_notifications
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'challenge_notifications'
          AND policyname = 'Service role can insert notifications'
    ) THEN
        EXECUTE $policy$
            CREATE POLICY "Service role can insert notifications"
                ON challenge_notifications FOR INSERT
                WITH CHECK (
                    (current_setting('request.jwt.claims', true)::json->>'role') = 'service_role'
                )
        $policy$;
    END IF;
END
$$;

-- ============================================================
-- 5. UPDATE: Allow to_user to also update challenges they accepted
--    (for marking completion). The existing policy only allows
--    to_user_id = auth.uid() which covers accept/decline, but
--    we also need from_user or to_user to update for completion.
-- ============================================================

-- Drop and recreate the update policy to allow either party
DROP POLICY IF EXISTS "Users can update received challenges" ON workout_challenges;

CREATE POLICY "Users can update their challenges"
    ON workout_challenges FOR UPDATE
    USING (from_user_id = auth.uid() OR to_user_id = auth.uid());
