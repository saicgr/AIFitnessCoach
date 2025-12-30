-- ============================================================================
-- Migration 067: Extended Fasting Protocols and Meal Reminders
-- ============================================================================
-- This migration adds support for:
-- 1. Extended fasting protocols (24h, 48h, 72h, 7-day water fasts)
-- 2. Meal reminder settings for eating window notifications
-- 3. Safety acknowledgment tracking for dangerous protocols
-- 4. User context logging for fasting activities
-- ============================================================================

-- Step 1: Add meal reminder columns to fasting_preferences
ALTER TABLE fasting_preferences
ADD COLUMN IF NOT EXISTS meal_reminders_enabled BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS lunch_reminder_hour INTEGER DEFAULT 12,
ADD COLUMN IF NOT EXISTS dinner_reminder_hour INTEGER DEFAULT 18,
ADD COLUMN IF NOT EXISTS extended_protocol_acknowledged BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS safety_responses JSONB DEFAULT '{}';

-- Step 2: Update protocol enum comment
COMMENT ON COLUMN fasting_records.protocol IS 'Fasting protocol: 12:12, 14:10, 16:8, 18:6, 20:4, OMAD (One Meal a Day), 24h Water Fast, 48h Water Fast, 72h Water Fast, 7-Day Water Fast, 5:2, ADF (Alternate Day), custom';

-- Step 3: Create fasting_user_context table for logging user activities during fasts
CREATE TABLE IF NOT EXISTS fasting_user_context (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  fasting_record_id UUID REFERENCES fasting_records(id) ON DELETE CASCADE,

  -- Context type
  context_type TEXT NOT NULL, -- 'fast_started', 'zone_entered', 'fast_ended', 'fast_cancelled', 'note_added', 'mood_logged'

  -- Details
  zone_name TEXT, -- For zone_entered events
  mood TEXT, -- For mood_logged events
  energy_level INTEGER, -- 1-5
  note TEXT,

  -- Protocol info
  protocol TEXT,
  protocol_type TEXT,
  is_dangerous_protocol BOOLEAN DEFAULT false,

  -- Timing
  elapsed_minutes INTEGER,
  goal_minutes INTEGER,
  completion_percentage DECIMAL(5,2),

  -- Metadata
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT now(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- RLS for fasting_user_context
ALTER TABLE fasting_user_context ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS fasting_user_context_select_policy ON fasting_user_context;
CREATE POLICY fasting_user_context_select_policy ON fasting_user_context
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS fasting_user_context_insert_policy ON fasting_user_context;
CREATE POLICY fasting_user_context_insert_policy ON fasting_user_context
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS fasting_user_context_update_policy ON fasting_user_context;
CREATE POLICY fasting_user_context_update_policy ON fasting_user_context
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS fasting_user_context_delete_policy ON fasting_user_context;
CREATE POLICY fasting_user_context_delete_policy ON fasting_user_context
  FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_fasting_user_context_user ON fasting_user_context(user_id);
CREATE INDEX IF NOT EXISTS idx_fasting_user_context_record ON fasting_user_context(fasting_record_id);
CREATE INDEX IF NOT EXISTS idx_fasting_user_context_timestamp ON fasting_user_context(user_id, timestamp DESC);

-- Step 4: Create function to check if protocol is dangerous
CREATE OR REPLACE FUNCTION is_dangerous_fasting_protocol(protocol_name TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN protocol_name IN (
    '24h Water Fast',
    '48h Water Fast',
    '72h Water Fast',
    '7-Day Water Fast'
  );
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Step 5: Create function to get protocol duration in hours
CREATE OR REPLACE FUNCTION get_protocol_fasting_hours(protocol_name TEXT)
RETURNS INTEGER AS $$
BEGIN
  RETURN CASE protocol_name
    WHEN '12:12' THEN 12
    WHEN '14:10' THEN 14
    WHEN '16:8' THEN 16
    WHEN '18:6' THEN 18
    WHEN '20:4' THEN 20
    WHEN 'OMAD (One Meal a Day)' THEN 23
    WHEN 'OMAD' THEN 23
    WHEN '24h Water Fast' THEN 24
    WHEN '48h Water Fast' THEN 48
    WHEN '72h Water Fast' THEN 72
    WHEN '7-Day Water Fast' THEN 168
    WHEN '5:2' THEN 24
    WHEN 'ADF (Alternate Day)' THEN 24
    WHEN 'ADF' THEN 24
    ELSE 16 -- default
  END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Step 6: Add comment documentation
COMMENT ON TABLE fasting_user_context IS 'Logs user context and activities during fasting sessions for analytics and AI coaching context';
COMMENT ON COLUMN fasting_preferences.meal_reminders_enabled IS 'Enable notifications for lunch/dinner during eating window';
COMMENT ON COLUMN fasting_preferences.lunch_reminder_hour IS 'Hour to send lunch reminder (24h format)';
COMMENT ON COLUMN fasting_preferences.dinner_reminder_hour IS 'Hour to send dinner reminder (24h format)';
COMMENT ON COLUMN fasting_preferences.extended_protocol_acknowledged IS 'User has acknowledged risks of extended fasting protocols';
COMMENT ON COLUMN fasting_preferences.safety_responses IS 'JSON object storing user responses to safety screening questions';

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
