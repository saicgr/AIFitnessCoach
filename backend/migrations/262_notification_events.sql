-- Track all notification delivery + interaction events
CREATE TABLE notification_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  notification_type TEXT NOT NULL,
  sent_at TIMESTAMPTZ NOT NULL,
  opened_at TIMESTAMPTZ,
  dismissed_at TIMESTAMPTZ,
  local_hour_sent INT,
  local_hour_opened INT,
  created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_notif_events_user ON notification_events(user_id, sent_at);
CREATE INDEX idx_notif_events_type ON notification_events(notification_type);

-- Per-user calculated optimal send times (refreshed daily)
CREATE TABLE user_optimal_send_times (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  workout_reminder_hour INT,
  nutrition_reminder_hour INT,
  general_optimal_hour INT,
  confidence_score FLOAT DEFAULT 0.0,
  data_points INT DEFAULT 0,
  calculation_method TEXT DEFAULT 'default',
  calculated_at TIMESTAMPTZ DEFAULT now(),
  expires_at TIMESTAMPTZ DEFAULT now() + interval '1 day'
);

-- RLS policies
ALTER TABLE notification_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_optimal_send_times ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own notification events"
  ON notification_events FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Service role can manage notification events"
  ON notification_events FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Users can view own optimal times"
  ON user_optimal_send_times FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Service role can manage optimal times"
  ON user_optimal_send_times FOR ALL USING (auth.role() = 'service_role');
