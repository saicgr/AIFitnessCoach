-- 1973: Program retune proposals — audit trail of Gemini-suggested deltas to
-- users.muscle_focus_points / training_intensity_percent / nutrition targets,
-- and whether the user accepted them.

BEGIN;

CREATE TABLE IF NOT EXISTS public.program_retune_proposals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  body_analyzer_snapshot_id uuid REFERENCES public.body_analyzer_snapshots(id) ON DELETE CASCADE,

  proposal_json jsonb NOT NULL,
  reasoning text,
  confidence numeric(3,2),

  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending','applied','dismissed','expired','auto_applied')),
  dismiss_reason text,
  expires_at timestamptz NOT NULL DEFAULT (now() + interval '7 days'),
  applied_at timestamptz,

  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_program_retune_proposals_user_status
  ON public.program_retune_proposals (user_id, status, created_at DESC);

ALTER TABLE public.program_retune_proposals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own program_retune_proposals"
  ON public.program_retune_proposals FOR SELECT
  USING (auth.uid() = (SELECT auth_id FROM public.users WHERE id = user_id));

CREATE POLICY "Users insert own program_retune_proposals"
  ON public.program_retune_proposals FOR INSERT
  WITH CHECK (auth.uid() = (SELECT auth_id FROM public.users WHERE id = user_id));

CREATE POLICY "Users update own program_retune_proposals"
  ON public.program_retune_proposals FOR UPDATE
  USING (auth.uid() = (SELECT auth_id FROM public.users WHERE id = user_id));

CREATE POLICY "Users delete own program_retune_proposals"
  ON public.program_retune_proposals FOR DELETE
  USING (auth.uid() = (SELECT auth_id FROM public.users WHERE id = user_id));

CREATE POLICY "Service role full access program_retune_proposals"
  ON public.program_retune_proposals FOR ALL
  USING (auth.role() = 'service_role');

COMMENT ON TABLE public.program_retune_proposals IS
  'Gemini-proposed changes to users.muscle_focus_points / training_intensity_percent / calorie+macro targets. User accepts → deltas written to public.users and next AI-generated plan reflects them.';

COMMIT;
