-- 2083_users_email_verification.sql
--
-- Soft-gate signup: Supabase "Confirm email" is being turned OFF (autoconfirm),
-- so signup no longer walls the user. Email verification becomes a NON-BLOCKING
-- backend nudge — the app is fully usable while unverified; an in-app banner
-- nudges the user, and the backend owns the verification token + email.
--
-- One active token per user; a resend overwrites the hash. The hash is cleared
-- on successful verification.

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS email_verified BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS email_verification_token_hash TEXT,
  ADD COLUMN IF NOT EXISTS email_verification_sent_at TIMESTAMPTZ;

COMMENT ON COLUMN users.email_verified IS
  'TRUE once the user clicked the backend verification link. Non-blocking nudge only — the app is fully usable while FALSE. Lifecycle/marketing emails are gated on TRUE to protect sender reputation; transactional/security mail still sends regardless.';
COMMENT ON COLUMN users.email_verification_token_hash IS
  'HMAC-SHA256 hash of the current verification token (raw token only ever lives in the email link). One active token per user; resend overwrites. Cleared on successful verify.';
COMMENT ON COLUMN users.email_verification_sent_at IS
  'When the current verification token was last issued. Used for the 48h expiry check and the 60s resend cooldown.';

-- Backfill: every existing user already confirmed in Supabase Auth starts
-- verified, so the rollout does not suddenly nag them or cut them off from
-- lifecycle emails.
UPDATE users SET email_verified = TRUE
WHERE auth_id::text IN (
  SELECT id::text FROM auth.users WHERE email_confirmed_at IS NOT NULL
);
