-- 1976: Audio-coach daily-brief cache.
-- Script generated with user's coach persona; audio synthesized via Google
-- Cloud TTS and cached to S3. One brief per (user, local day).

BEGIN;

CREATE TABLE IF NOT EXISTS public.audio_coach_briefs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  brief_date date NOT NULL,
  coach_persona_id text,
  script_text text NOT NULL,
  s3_key text,
  duration_seconds int,
  listened_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, brief_date)
);

CREATE INDEX IF NOT EXISTS idx_audio_coach_briefs_user_date
  ON public.audio_coach_briefs (user_id, brief_date DESC);

ALTER TABLE public.audio_coach_briefs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own audio_coach_briefs"
  ON public.audio_coach_briefs FOR SELECT
  USING (auth.uid() = (SELECT auth_id FROM public.users WHERE id = user_id));

CREATE POLICY "Users update own audio_coach_briefs"
  ON public.audio_coach_briefs FOR UPDATE
  USING (auth.uid() = (SELECT auth_id FROM public.users WHERE id = user_id));

CREATE POLICY "Service role full access audio_coach_briefs"
  ON public.audio_coach_briefs FOR ALL
  USING (auth.role() = 'service_role');

COMMENT ON TABLE public.audio_coach_briefs IS
  'Daily personalised audio briefs synthesised via Google TTS. Cached per (user, date) so replays reuse the S3-hosted MP3.';

COMMIT;
