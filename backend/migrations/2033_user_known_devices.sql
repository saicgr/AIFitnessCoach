-- 2033: Track known devices per user so we can email on first sign-in from a new device.
--
-- Mirrors the GymBeat / Google "new sign-in to your account" alert. Without
-- this, a stolen Supabase refresh token used from a new device would never
-- generate any audit signal for the user.
--
-- The fingerprint_hash is sha256(platform | model | os_version | app_install_id)
-- computed client-side. We don't ship raw IPs in the table because IP rotation
-- on mobile carriers would create a row per cell-tower hop.

CREATE TABLE IF NOT EXISTS public.user_known_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    fingerprint_hash TEXT NOT NULL,
    platform TEXT,            -- 'ios' | 'android' | 'web' | 'wearos' | 'watchos'
    model TEXT,               -- 'iPhone 15 Pro', 'Pixel 8', etc.
    os_version TEXT,          -- '17.4', '14', etc.
    app_version TEXT,
    last_seen_ip INET,        -- best-effort, may be carrier-NAT'd
    last_seen_city TEXT,      -- resolved server-side at write time, optional
    last_seen_country TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_seen_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, fingerprint_hash)
);

CREATE INDEX IF NOT EXISTS idx_user_known_devices_user
    ON public.user_known_devices (user_id, last_seen_at DESC);

ALTER TABLE public.user_known_devices ENABLE ROW LEVEL SECURITY;

-- Users can read their own device list (for a future "Manage devices" screen)
-- but writes go through the service role only — clients shouldn't be able to
-- forge a "known" fingerprint and skip the alert.
DROP POLICY IF EXISTS user_known_devices_self_select ON public.user_known_devices;
CREATE POLICY user_known_devices_self_select ON public.user_known_devices
    FOR SELECT USING (auth.uid() = (SELECT auth_id FROM public.users WHERE id = user_known_devices.user_id));
