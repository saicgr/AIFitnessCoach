-- 2102_buddy_workouts.sql — Phase 6 #15
-- Buddy synchronized workouts. Two friends start the same workout at the same
-- time and see each other's set completion live via Supabase Realtime
-- subscriptions on buddy_set_events. Reuses the existing user_connections
-- friends graph + the realtime channel pattern already powering live_chat.py.

CREATE TABLE IF NOT EXISTS buddy_workout_sessions (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  host_user_id    uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  partner_user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  workout_id      uuid,
  status          text NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending','active','completed','cancelled')),
  started_at      timestamptz,
  ended_at        timestamptz,
  exercises_snapshot jsonb,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_buddy_sessions_host    ON buddy_workout_sessions(host_user_id, status);
CREATE INDEX IF NOT EXISTS idx_buddy_sessions_partner ON buddy_workout_sessions(partner_user_id, status);
CREATE INDEX IF NOT EXISTS idx_buddy_sessions_active  ON buddy_workout_sessions(status) WHERE status = 'active';

ALTER TABLE buddy_workout_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY buddy_sessions_visibility ON buddy_workout_sessions
  FOR SELECT USING (auth.uid() IN (host_user_id, partner_user_id));
CREATE POLICY buddy_sessions_insert ON buddy_workout_sessions
  FOR INSERT WITH CHECK (auth.uid() = host_user_id);
CREATE POLICY buddy_sessions_update ON buddy_workout_sessions
  FOR UPDATE USING (auth.uid() IN (host_user_id, partner_user_id))
              WITH CHECK (auth.uid() IN (host_user_id, partner_user_id));

CREATE TABLE IF NOT EXISTS buddy_set_events (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id   uuid NOT NULL REFERENCES buddy_workout_sessions(id) ON DELETE CASCADE,
  user_id      uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  exercise_id  text NOT NULL,
  exercise_name text,
  set_number   int NOT NULL,
  weight_kg    numeric,
  reps         int,
  rpe          numeric,
  completed_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_buddy_events_session
  ON buddy_set_events(session_id, completed_at DESC);

ALTER TABLE buddy_set_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY buddy_events_visibility ON buddy_set_events
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM buddy_workout_sessions s
            WHERE s.id = buddy_set_events.session_id
              AND auth.uid() IN (s.host_user_id, s.partner_user_id))
  );

CREATE POLICY buddy_events_insert ON buddy_set_events
  FOR INSERT WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (SELECT 1 FROM buddy_workout_sessions s
                WHERE s.id = buddy_set_events.session_id
                  AND auth.uid() IN (s.host_user_id, s.partner_user_id)
                  AND s.status = 'active')
  );

ALTER PUBLICATION supabase_realtime ADD TABLE buddy_workout_sessions;
ALTER PUBLICATION supabase_realtime ADD TABLE buddy_set_events;

CREATE OR REPLACE FUNCTION public.set_buddy_session_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END $$;

DROP TRIGGER IF EXISTS trg_buddy_sessions_updated_at ON buddy_workout_sessions;
CREATE TRIGGER trg_buddy_sessions_updated_at
  BEFORE UPDATE ON buddy_workout_sessions
  FOR EACH ROW EXECUTE FUNCTION public.set_buddy_session_updated_at();
