-- Migration 100: Add is_trainer flag to users table
--
-- Captures whether the user is a personal trainer / coaching others.
-- Asked at onboarding (personal info step). Used as the warm-lead segment
-- for Reppora alpha launch invites — at alpha time we'll fire one segmented
-- email blast to all users where is_trainer = true AND email_subscribed = true.
--
-- See /Users/saichetangrandhe/Reppora/docs/STRATEGY.md §0.2 for context.

ALTER TABLE users
ADD COLUMN IF NOT EXISTS is_trainer BOOLEAN NOT NULL DEFAULT FALSE;

-- Index for fast segmentation queries when we send the Reppora alpha invite.
CREATE INDEX IF NOT EXISTS idx_users_is_trainer
  ON users (is_trainer)
  WHERE is_trainer = TRUE;

COMMENT ON COLUMN users.is_trainer IS
  'TRUE if user identified as a personal trainer at onboarding. Used as the Reppora alpha launch warm-lead segment.';
