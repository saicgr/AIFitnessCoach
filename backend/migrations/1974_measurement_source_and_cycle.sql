-- 1974: Photo-measurement confidence + menstrual cycle tracking.

BEGIN;

ALTER TABLE public.body_measurements
  ADD COLUMN IF NOT EXISTS estimate_confidence numeric(3,2)
    CHECK (estimate_confidence IS NULL OR (estimate_confidence >= 0 AND estimate_confidence <= 1));

COMMENT ON COLUMN public.body_measurements.estimate_confidence IS
  'Gemini-Vision confidence for photo-extracted measurements (0–1). NULL for manual entries.';

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS cycle_aware_reminders boolean DEFAULT false;

COMMENT ON COLUMN public.users.cycle_aware_reminders IS
  'Opt-in: when true, skip progress-photo reminders during menstruation days 1–5.';

CREATE TABLE IF NOT EXISTS public.menstrual_cycle_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  cycle_start_date date NOT NULL,
  cycle_length_days int DEFAULT 28 CHECK (cycle_length_days BETWEEN 14 AND 60),
  period_length_days int DEFAULT 5 CHECK (period_length_days BETWEEN 1 AND 14),
  notes text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_menstrual_cycle_logs_user_date
  ON public.menstrual_cycle_logs (user_id, cycle_start_date DESC);

ALTER TABLE public.menstrual_cycle_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own menstrual_cycle_logs"
  ON public.menstrual_cycle_logs FOR SELECT
  USING (auth.uid() = (SELECT auth_id FROM public.users WHERE id = user_id));

CREATE POLICY "Users insert own menstrual_cycle_logs"
  ON public.menstrual_cycle_logs FOR INSERT
  WITH CHECK (auth.uid() = (SELECT auth_id FROM public.users WHERE id = user_id));

CREATE POLICY "Users update own menstrual_cycle_logs"
  ON public.menstrual_cycle_logs FOR UPDATE
  USING (auth.uid() = (SELECT auth_id FROM public.users WHERE id = user_id));

CREATE POLICY "Users delete own menstrual_cycle_logs"
  ON public.menstrual_cycle_logs FOR DELETE
  USING (auth.uid() = (SELECT auth_id FROM public.users WHERE id = user_id));

CREATE POLICY "Service role full access menstrual_cycle_logs"
  ON public.menstrual_cycle_logs FOR ALL
  USING (auth.role() = 'service_role');

COMMENT ON TABLE public.menstrual_cycle_logs IS
  'Minimal cycle tracking used by cycle-aware reminder filter. One row per logged cycle start.';

COMMIT;
