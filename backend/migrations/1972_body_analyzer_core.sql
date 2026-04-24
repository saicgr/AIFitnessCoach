-- 1972: Body Analyzer core tables
-- Adds public.users.body_type enum + public.body_analyzer_snapshots.
-- All new tables FK to public.users(id) per the 1971 convention.

BEGIN;

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS body_type TEXT
    CHECK (body_type IN ('ectomorph','mesomorph','endomorph','balanced'));

COMMENT ON COLUMN public.users.body_type IS
  'Somatotype persisted from the Body Analyzer screen (ectomorph/mesomorph/endomorph/balanced). Read by workout + meal-plan generators.';

CREATE TABLE IF NOT EXISTS public.body_analyzer_snapshots (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,

  overall_rating int CHECK (overall_rating BETWEEN 0 AND 100),
  body_type text CHECK (body_type IN ('ectomorph','mesomorph','endomorph','balanced')),
  body_fat_percent numeric(5,2),
  muscle_mass_percent numeric(5,2),
  symmetry_score int CHECK (symmetry_score BETWEEN 0 AND 100),
  body_age int CHECK (body_age BETWEEN 18 AND 120),

  feedback_text text,
  improvement_tips jsonb DEFAULT '[]'::jsonb,
  posture_findings jsonb DEFAULT '[]'::jsonb,

  front_photo_id uuid REFERENCES public.progress_photos(id) ON DELETE SET NULL,
  back_photo_id uuid REFERENCES public.progress_photos(id) ON DELETE SET NULL,
  side_left_photo_id uuid REFERENCES public.progress_photos(id) ON DELETE SET NULL,
  side_right_photo_id uuid REFERENCES public.progress_photos(id) ON DELETE SET NULL,

  ai_model text,
  input_measurements jsonb DEFAULT '{}'::jsonb,

  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_body_analyzer_snapshots_user_created
  ON public.body_analyzer_snapshots (user_id, created_at DESC);

ALTER TABLE public.body_analyzer_snapshots ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own body_analyzer_snapshots"
  ON public.body_analyzer_snapshots FOR SELECT
  USING (auth.uid() = (SELECT auth_id FROM public.users WHERE id = user_id));

CREATE POLICY "Users insert own body_analyzer_snapshots"
  ON public.body_analyzer_snapshots FOR INSERT
  WITH CHECK (auth.uid() = (SELECT auth_id FROM public.users WHERE id = user_id));

CREATE POLICY "Users update own body_analyzer_snapshots"
  ON public.body_analyzer_snapshots FOR UPDATE
  USING (auth.uid() = (SELECT auth_id FROM public.users WHERE id = user_id));

CREATE POLICY "Users delete own body_analyzer_snapshots"
  ON public.body_analyzer_snapshots FOR DELETE
  USING (auth.uid() = (SELECT auth_id FROM public.users WHERE id = user_id));

CREATE POLICY "Service role full access body_analyzer_snapshots"
  ON public.body_analyzer_snapshots FOR ALL
  USING (auth.role() = 'service_role');

COMMENT ON TABLE public.body_analyzer_snapshots IS
  'Gemini Vision body analysis outputs. One row per analyze call; latest row drives the Body Analyzer screen.';

COMMIT;
