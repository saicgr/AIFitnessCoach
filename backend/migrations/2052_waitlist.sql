-- Migration 2052: Public waitlist for pre-launch email capture.
--
-- Feeds the marketing site's "Get notified when iOS / public Android drops"
-- form. Anonymous users can INSERT (single email), nothing else. Admins read
-- via service-role key from the backend or Supabase dashboard.

CREATE TABLE IF NOT EXISTS public.waitlist (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email       TEXT NOT NULL,
    source      TEXT NOT NULL DEFAULT 'web',  -- 'marketing_landing' | 'waitlist_page' | 'twitter' | etc
    referrer    TEXT,                          -- document.referrer at submit time
    user_agent  TEXT,                          -- navigator.userAgent
    platform_interest TEXT,                    -- 'ios' | 'android' | 'both'
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- Soft-validate email shape at the DB layer too. The frontend validates
    -- as well but defense-in-depth keeps junk out if RLS is ever loosened.
    CONSTRAINT waitlist_email_format CHECK (email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$')
);

-- Case-insensitive uniqueness — "Foo@bar.com" and "foo@bar.com" are the same.
CREATE UNIQUE INDEX IF NOT EXISTS waitlist_email_lower_unique
    ON public.waitlist (LOWER(email));

CREATE INDEX IF NOT EXISTS waitlist_created_at_idx
    ON public.waitlist (created_at DESC);

CREATE INDEX IF NOT EXISTS waitlist_source_idx
    ON public.waitlist (source);

-- RLS: anon can only INSERT. No reads, no updates, no deletes for anon.
ALTER TABLE public.waitlist ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anon_insert_waitlist" ON public.waitlist;
CREATE POLICY "anon_insert_waitlist"
    ON public.waitlist
    FOR INSERT
    TO anon
    WITH CHECK (true);

-- Authenticated users (e.g., logged-in users from the Flutter app) also
-- allowed to insert — same shape — for the in-app "tell a friend / waitlist
-- a friend" flow we may add later.
DROP POLICY IF EXISTS "auth_insert_waitlist" ON public.waitlist;
CREATE POLICY "auth_insert_waitlist"
    ON public.waitlist
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Service role (backend admin scripts, dashboard) can do anything.
DROP POLICY IF EXISTS "service_role_all_waitlist" ON public.waitlist;
CREATE POLICY "service_role_all_waitlist"
    ON public.waitlist
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

COMMENT ON TABLE public.waitlist IS
    'Pre-launch email waitlist. Anonymous INSERT only; reads via service role.';
