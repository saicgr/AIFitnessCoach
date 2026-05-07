-- 2051_apple_signin_revocation.sql
-- Store Apple Sign-In refresh_token so we can call Apple's /auth/revoke
-- endpoint on account deletion (App Store Guideline 5.1.1.v).
--
-- Token is opaque and only useful for revocation; storing in plaintext
-- is acceptable. Column is nullable because most users don't use SIWA.

ALTER TABLE public.users
    ADD COLUMN IF NOT EXISTS apple_refresh_token TEXT;

COMMENT ON COLUMN public.users.apple_refresh_token IS
    'Apple Sign-In refresh_token, captured at first SIWA login by exchanging '
    'authorization_code with appleid.apple.com/auth/token. Used on account '
    'deletion to call /auth/revoke per App Store guideline 5.1.1.v.';
