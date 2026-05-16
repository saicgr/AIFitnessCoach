-- 2076_free_tools_email_signup.sql
--
-- Email-capture table for the unauthenticated /api/v1/free-tools/* surface.
-- One row per (email, tool_slug) pair. Used to nurture prospects who tried a
-- tool into installing Zealova or subscribing to the weekly-tool drop.
--
-- Privacy: ip_hash uses a dedicated salt distinct from the AI-tool rate-limit
-- salts (see backend/utils/free_tool_rate_limit.py). This prevents linking an
-- email signup back to which rate-limited IP made the call.

BEGIN;

CREATE TABLE IF NOT EXISTS public.free_tools_email_signup (
  id BIGSERIAL PRIMARY KEY,
  email TEXT NOT NULL,
  tool_slug TEXT NOT NULL,
  ip_hash TEXT,
  result_summary JSONB,
  source TEXT,  -- 'after_result' | 'during_processing' | 'manual'
  user_agent TEXT,
  referrer TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT free_tools_email_signup_source_chk CHECK (
    source IS NULL OR source IN ('after_result', 'during_processing', 'manual')
  ),
  CONSTRAINT free_tools_email_signup_email_tool_unique UNIQUE (email, tool_slug)
);

CREATE INDEX IF NOT EXISTS free_tools_email_signup_email_idx
  ON public.free_tools_email_signup (email);

CREATE INDEX IF NOT EXISTS free_tools_email_signup_created_idx
  ON public.free_tools_email_signup (created_at DESC);

CREATE INDEX IF NOT EXISTS free_tools_email_signup_tool_idx
  ON public.free_tools_email_signup (tool_slug);

-- Extend the existing free_tool_usage tool whitelist to allow the new
-- email-signup pseudo-tool so the shared rate-limit utility (10/IP/hour)
-- can reuse the same table without duplicating the rate-limit machinery.
ALTER TABLE public.free_tool_usage
  DROP CONSTRAINT IF EXISTS free_tool_usage_tool_chk;

ALTER TABLE public.free_tool_usage
  ADD CONSTRAINT free_tool_usage_tool_chk CHECK (
    tool IN (
      'ai-food-photo',
      'ai-workout-generator',
      'ai-roast-routine',
      'email-signup'
    )
  );

COMMIT;
