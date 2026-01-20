-- =============================================================================
-- XP EVENTS SYSTEM (Battlefield-style progression bonuses)
-- Migration 166: Daily Login, Weekly/Monthly Checkpoints, Double XP Events
-- =============================================================================

-- Daily Login Tracking
CREATE TABLE IF NOT EXISTS user_login_streaks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users NOT NULL UNIQUE,
  current_streak INT DEFAULT 0,           -- Days in current streak
  longest_streak INT DEFAULT 0,           -- Personal best
  total_logins INT DEFAULT 0,             -- Lifetime logins
  last_login_date DATE,                   -- Last login (date only)
  streak_start_date DATE,                 -- When current streak started
  first_login_at TIMESTAMPTZ,             -- First ever login
  last_daily_bonus_claimed DATE,          -- Prevents double-claiming
  last_weekly_bonus_claimed DATE,         -- Weekly bonus tracker
  last_monthly_bonus_claimed DATE,        -- Monthly bonus tracker
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- XP Events (Double XP weekends, seasonal events, etc.)
CREATE TABLE IF NOT EXISTS xp_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_name TEXT NOT NULL,
  event_type TEXT NOT NULL,               -- 'weekend_bonus', 'holiday', 'seasonal', 'flash', 'milestone'
  description TEXT,
  xp_multiplier DECIMAL(3,2) DEFAULT 1.0, -- 2.0 = Double XP
  start_at TIMESTAMPTZ NOT NULL,
  end_at TIMESTAMPTZ NOT NULL,
  is_active BOOLEAN DEFAULT true,
  applies_to TEXT[] DEFAULT ARRAY['all'], -- ['workout', 'achievement', 'streak'] or ['all']
  icon_name TEXT,                         -- For UI display
  banner_color TEXT,                      -- Hex color for event banner
  created_by UUID REFERENCES auth.users,  -- Admin who created it
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User Event Participation (track who participated in each event)
CREATE TABLE IF NOT EXISTS user_event_participation (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users NOT NULL,
  event_id UUID REFERENCES xp_events NOT NULL,
  participated_at TIMESTAMPTZ DEFAULT NOW(),
  participation_date DATE DEFAULT CURRENT_DATE,  -- Date-only for uniqueness
  base_xp_earned INT DEFAULT 0,
  bonus_xp_earned INT DEFAULT 0,          -- Extra from multiplier
  source TEXT,                            -- What triggered the bonus
  UNIQUE(user_id, event_id, participation_date)
);

-- XP Bonus Templates (defines bonus amounts)
CREATE TABLE IF NOT EXISTS xp_bonus_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bonus_type TEXT NOT NULL UNIQUE,        -- 'first_login', 'daily_login', etc.
  base_xp INT NOT NULL,
  description TEXT,
  streak_multiplier BOOLEAN DEFAULT false, -- If true, multiply by streak
  max_streak_multiplier INT DEFAULT 7,     -- Cap for streak multiplication
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Weekly/Monthly checkpoint tracking
CREATE TABLE IF NOT EXISTS user_checkpoint_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users NOT NULL,
  checkpoint_type TEXT NOT NULL,           -- 'weekly' or 'monthly'
  period_start DATE NOT NULL,              -- Monday for weekly, 1st for monthly
  period_end DATE NOT NULL,
  checkpoints_earned TEXT[] DEFAULT '{}',  -- Array of earned checkpoint types
  total_xp_earned INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, checkpoint_type, period_start)
);

-- =============================================================================
-- INSERT DEFAULT BONUS TEMPLATES
-- =============================================================================

INSERT INTO xp_bonus_templates (bonus_type, base_xp, description, streak_multiplier, max_streak_multiplier) VALUES
-- Login bonuses
('first_login', 500, 'Welcome bonus for new users', false, 1),
('daily_login', 25, 'Daily check-in bonus (multiplied by streak, max 7x)', true, 7),
('streak_milestone_7', 100, '7-day login streak bonus', false, 1),
('streak_milestone_30', 500, '30-day login streak bonus', false, 1),
('streak_milestone_100', 2000, '100-day login streak bonus', false, 1),
('streak_milestone_365', 10000, '365-day login streak bonus', false, 1),
-- Weekly checkpoints
('weekly_workouts', 200, 'Complete 3+ workouts this week', false, 1),
('weekly_perfect', 500, 'Hit ALL scheduled workouts', false, 1),
('weekly_protein', 150, 'Hit protein goal 5+ days', false, 1),
('weekly_calories', 150, 'Stay within calorie range 5+ days', false, 1),
('weekly_hydration', 100, 'Hit water goal 5+ days', false, 1),
('weekly_weight_log', 75, 'Log weight 3+ times', false, 1),
('weekly_habits', 100, 'Complete 70%+ of habits', false, 1),
('weekly_streak', 100, 'Maintain 7+ day workout streak', false, 1),
-- Monthly checkpoints
('monthly_dedication', 500, '20+ active days this month', false, 1),
('monthly_goal_met', 1000, 'Hit your primary fitness goal', false, 1),
('monthly_nutrition', 500, 'Hit macros 20+ days', false, 1),
('monthly_consistency', 750, 'No missed scheduled workouts', false, 1),
('monthly_hydration', 300, 'Hit water goal 25+ days', false, 1),
('monthly_weight', 400, 'On track with weight goal', false, 1),
('monthly_habits', 400, '80%+ habit completion', false, 1),
('monthly_prs', 500, 'Set 3+ personal records', false, 1)
ON CONFLICT (bonus_type) DO NOTHING;

-- =============================================================================
-- INDEXES
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_login_streaks_user ON user_login_streaks(user_id);
CREATE INDEX IF NOT EXISTS idx_login_streaks_last_date ON user_login_streaks(last_login_date);
CREATE INDEX IF NOT EXISTS idx_xp_events_active ON xp_events(is_active, start_at, end_at);
CREATE INDEX IF NOT EXISTS idx_xp_events_type ON xp_events(event_type);
CREATE INDEX IF NOT EXISTS idx_event_participation_user ON user_event_participation(user_id);
CREATE INDEX IF NOT EXISTS idx_event_participation_event ON user_event_participation(event_id);
CREATE INDEX IF NOT EXISTS idx_checkpoint_progress_user ON user_checkpoint_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_checkpoint_progress_period ON user_checkpoint_progress(period_start, period_end);

-- =============================================================================
-- FUNCTIONS
-- =============================================================================

-- Check and process daily login
CREATE OR REPLACE FUNCTION process_daily_login(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
  v_streak_record user_login_streaks%ROWTYPE;
  v_today DATE := CURRENT_DATE;
  v_yesterday DATE := CURRENT_DATE - 1;
  v_is_first_login BOOLEAN := false;
  v_streak_broken BOOLEAN := false;
  v_daily_bonus INT := 0;
  v_streak_bonus INT := 0;
  v_first_login_bonus INT := 0;
  v_active_events JSON;
  v_total_multiplier DECIMAL := 1.0;
  v_base_daily_xp INT;
  v_max_multiplier INT;
BEGIN
  -- Get or create streak record
  SELECT * INTO v_streak_record FROM user_login_streaks WHERE user_id = p_user_id;

  IF NOT FOUND THEN
    -- First ever login
    v_is_first_login := true;
    INSERT INTO user_login_streaks (user_id, current_streak, longest_streak, total_logins,
                                     last_login_date, streak_start_date, first_login_at,
                                     last_daily_bonus_claimed)
    VALUES (p_user_id, 1, 1, 1, v_today, v_today, NOW(), v_today)
    RETURNING * INTO v_streak_record;

    -- Award first login bonus
    SELECT base_xp INTO v_first_login_bonus
    FROM xp_bonus_templates
    WHERE bonus_type = 'first_login' AND is_active = true;

  ELSIF v_streak_record.last_login_date = v_today THEN
    -- Already logged in today, no bonus
    RETURN json_build_object(
      'already_claimed', true,
      'current_streak', v_streak_record.current_streak,
      'longest_streak', v_streak_record.longest_streak,
      'xp_awarded', 0,
      'message', 'Already claimed today''s bonus'
    );

  ELSIF v_streak_record.last_login_date = v_yesterday THEN
    -- Continuing streak
    UPDATE user_login_streaks SET
      current_streak = current_streak + 1,
      longest_streak = GREATEST(longest_streak, current_streak + 1),
      total_logins = total_logins + 1,
      last_login_date = v_today,
      last_daily_bonus_claimed = v_today,
      updated_at = NOW()
    WHERE user_id = p_user_id
    RETURNING * INTO v_streak_record;

  ELSE
    -- Streak broken
    v_streak_broken := true;
    UPDATE user_login_streaks SET
      current_streak = 1,
      total_logins = total_logins + 1,
      last_login_date = v_today,
      streak_start_date = v_today,
      last_daily_bonus_claimed = v_today,
      updated_at = NOW()
    WHERE user_id = p_user_id
    RETURNING * INTO v_streak_record;
  END IF;

  -- Get daily login template
  SELECT base_xp, max_streak_multiplier
  INTO v_base_daily_xp, v_max_multiplier
  FROM xp_bonus_templates
  WHERE bonus_type = 'daily_login' AND is_active = true;

  -- Calculate daily bonus with streak multiplier (capped)
  v_daily_bonus := COALESCE(v_base_daily_xp, 25) * LEAST(v_streak_record.current_streak, COALESCE(v_max_multiplier, 7));

  -- Check for streak milestone bonuses
  IF v_streak_record.current_streak = 7 THEN
    SELECT base_xp INTO v_streak_bonus FROM xp_bonus_templates WHERE bonus_type = 'streak_milestone_7' AND is_active = true;
  ELSIF v_streak_record.current_streak = 30 THEN
    SELECT base_xp INTO v_streak_bonus FROM xp_bonus_templates WHERE bonus_type = 'streak_milestone_30' AND is_active = true;
  ELSIF v_streak_record.current_streak = 100 THEN
    SELECT base_xp INTO v_streak_bonus FROM xp_bonus_templates WHERE bonus_type = 'streak_milestone_100' AND is_active = true;
  ELSIF v_streak_record.current_streak = 365 THEN
    SELECT base_xp INTO v_streak_bonus FROM xp_bonus_templates WHERE bonus_type = 'streak_milestone_365' AND is_active = true;
  END IF;

  -- Get active XP events and calculate multiplier
  SELECT json_agg(json_build_object(
    'id', e.id,
    'event_name', e.event_name,
    'event_type', e.event_type,
    'xp_multiplier', e.xp_multiplier,
    'end_at', e.end_at,
    'icon_name', e.icon_name,
    'banner_color', e.banner_color
  )), COALESCE(MAX(e.xp_multiplier), 1.0)
  INTO v_active_events, v_total_multiplier
  FROM xp_events e
  WHERE e.is_active = true
    AND NOW() BETWEEN e.start_at AND e.end_at
    AND ('all' = ANY(e.applies_to) OR 'daily_login' = ANY(e.applies_to));

  -- Apply multiplier to bonuses
  v_daily_bonus := FLOOR(v_daily_bonus * v_total_multiplier);
  v_first_login_bonus := FLOOR(COALESCE(v_first_login_bonus, 0) * v_total_multiplier);
  v_streak_bonus := FLOOR(COALESCE(v_streak_bonus, 0) * v_total_multiplier);

  -- Award XP via the award_xp function (if it exists)
  IF v_first_login_bonus > 0 THEN
    BEGIN
      PERFORM award_xp(p_user_id, v_first_login_bonus, 'first_login', NULL, 'Welcome to FitWiz!');
    EXCEPTION WHEN undefined_function THEN
      -- award_xp doesn't exist, insert directly to xp_transactions
      INSERT INTO xp_transactions (user_id, xp_amount, source, description, created_at)
      VALUES (p_user_id, v_first_login_bonus, 'first_login', 'Welcome to FitWiz!', NOW());
    END;
  END IF;

  IF v_daily_bonus > 0 THEN
    BEGIN
      PERFORM award_xp(p_user_id, v_daily_bonus, 'daily_checkin', NULL,
                       'Day ' || v_streak_record.current_streak || ' streak bonus');
    EXCEPTION WHEN undefined_function THEN
      INSERT INTO xp_transactions (user_id, xp_amount, source, description, created_at)
      VALUES (p_user_id, v_daily_bonus, 'daily_checkin', 'Day ' || v_streak_record.current_streak || ' streak bonus', NOW());
    END;
  END IF;

  IF v_streak_bonus > 0 THEN
    BEGIN
      PERFORM award_xp(p_user_id, v_streak_bonus, 'streak', NULL,
                       v_streak_record.current_streak || '-day streak milestone!');
    EXCEPTION WHEN undefined_function THEN
      INSERT INTO xp_transactions (user_id, xp_amount, source, description, created_at)
      VALUES (p_user_id, v_streak_bonus, 'streak', v_streak_record.current_streak || '-day streak milestone!', NOW());
    END;
  END IF;

  -- Log to user_context_logs if table exists
  BEGIN
    INSERT INTO user_context_logs (user_id, event_type, event_data, context, created_at)
    VALUES (
      p_user_id,
      'daily_login',
      json_build_object(
        'streak_day', v_streak_record.current_streak,
        'xp_earned', v_daily_bonus + COALESCE(v_first_login_bonus, 0) + COALESCE(v_streak_bonus, 0),
        'is_first_login', v_is_first_login,
        'streak_broken', v_streak_broken,
        'active_events', v_active_events
      ),
      json_build_object(
        'day_of_week', to_char(NOW(), 'Day'),
        'time_of_day', CASE
          WHEN EXTRACT(HOUR FROM NOW()) < 6 THEN 'night'
          WHEN EXTRACT(HOUR FROM NOW()) < 12 THEN 'morning'
          WHEN EXTRACT(HOUR FROM NOW()) < 18 THEN 'afternoon'
          ELSE 'evening'
        END
      ),
      NOW()
    );
  EXCEPTION WHEN undefined_table THEN
    -- user_context_logs doesn't exist, skip
    NULL;
  END;

  RETURN json_build_object(
    'is_first_login', v_is_first_login,
    'streak_broken', v_streak_broken,
    'current_streak', v_streak_record.current_streak,
    'longest_streak', v_streak_record.longest_streak,
    'total_logins', v_streak_record.total_logins,
    'daily_xp', v_daily_bonus,
    'first_login_xp', COALESCE(v_first_login_bonus, 0),
    'streak_milestone_xp', COALESCE(v_streak_bonus, 0),
    'total_xp_awarded', v_daily_bonus + COALESCE(v_first_login_bonus, 0) + COALESCE(v_streak_bonus, 0),
    'active_events', v_active_events,
    'multiplier', v_total_multiplier,
    'message', CASE
      WHEN v_is_first_login THEN 'Welcome to FitWiz! Here''s your welcome bonus!'
      WHEN v_streak_bonus > 0 THEN v_streak_record.current_streak || '-day streak milestone reached!'
      WHEN v_streak_broken THEN 'Streak reset. Start a new one today!'
      ELSE 'Day ' || v_streak_record.current_streak || ' streak!'
    END
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get active XP events
CREATE OR REPLACE FUNCTION get_active_xp_events()
RETURNS SETOF xp_events AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM xp_events
  WHERE is_active = true
    AND NOW() BETWEEN start_at AND end_at
  ORDER BY xp_multiplier DESC;
END;
$$ LANGUAGE plpgsql;

-- Enable Double XP Weekend (admin function)
CREATE OR REPLACE FUNCTION enable_double_xp_event(
  p_event_name TEXT DEFAULT 'Double XP Weekend',
  p_event_type TEXT DEFAULT 'weekend_bonus',
  p_multiplier DECIMAL DEFAULT 2.0,
  p_duration_hours INT DEFAULT 48,
  p_admin_id UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_event_id UUID;
  v_start TIMESTAMPTZ := NOW();
  v_end TIMESTAMPTZ := NOW() + (p_duration_hours || ' hours')::INTERVAL;
BEGIN
  INSERT INTO xp_events (
    event_name, event_type, description, xp_multiplier,
    start_at, end_at, applies_to, icon_name, banner_color, created_by
  )
  VALUES (
    p_event_name,
    p_event_type,
    'Earn ' || p_multiplier || 'x XP on all activities!',
    p_multiplier,
    v_start,
    v_end,
    ARRAY['all'],
    'bolt',
    '#FFD700',
    p_admin_id
  )
  RETURNING id INTO v_event_id;

  RETURN v_event_id;
END;
$$ LANGUAGE plpgsql;

-- Get user's login streak info
CREATE OR REPLACE FUNCTION get_login_streak(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
  v_streak user_login_streaks%ROWTYPE;
BEGIN
  SELECT * INTO v_streak FROM user_login_streaks WHERE user_id = p_user_id;

  IF NOT FOUND THEN
    RETURN json_build_object(
      'current_streak', 0,
      'longest_streak', 0,
      'total_logins', 0,
      'last_login_date', NULL,
      'first_login_at', NULL,
      'has_logged_in_today', false
    );
  END IF;

  RETURN json_build_object(
    'current_streak', v_streak.current_streak,
    'longest_streak', v_streak.longest_streak,
    'total_logins', v_streak.total_logins,
    'last_login_date', v_streak.last_login_date,
    'first_login_at', v_streak.first_login_at,
    'streak_start_date', v_streak.streak_start_date,
    'has_logged_in_today', v_streak.last_login_date = CURRENT_DATE
  );
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- ROW LEVEL SECURITY
-- =============================================================================

ALTER TABLE user_login_streaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE xp_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_event_participation ENABLE ROW LEVEL SECURITY;
ALTER TABLE xp_bonus_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_checkpoint_progress ENABLE ROW LEVEL SECURITY;

-- Users see own streaks
DROP POLICY IF EXISTS "Users see own streaks" ON user_login_streaks;
CREATE POLICY "Users see own streaks" ON user_login_streaks
  FOR SELECT USING (auth.uid() = user_id);

-- Service manages streaks
DROP POLICY IF EXISTS "Service manages streaks" ON user_login_streaks;
CREATE POLICY "Service manages streaks" ON user_login_streaks
  FOR ALL USING (auth.role() = 'service_role');

-- Anyone sees active events
DROP POLICY IF EXISTS "Anyone sees active events" ON xp_events;
CREATE POLICY "Anyone sees active events" ON xp_events
  FOR SELECT USING (is_active = true AND NOW() BETWEEN start_at AND end_at);

-- Service manages events
DROP POLICY IF EXISTS "Service manages events" ON xp_events;
CREATE POLICY "Service manages events" ON xp_events
  FOR ALL USING (auth.role() = 'service_role');

-- Users see own participation
DROP POLICY IF EXISTS "Users see own participation" ON user_event_participation;
CREATE POLICY "Users see own participation" ON user_event_participation
  FOR SELECT USING (auth.uid() = user_id);

-- Service manages participation
DROP POLICY IF EXISTS "Service manages participation" ON user_event_participation;
CREATE POLICY "Service manages participation" ON user_event_participation
  FOR ALL USING (auth.role() = 'service_role');

-- Anyone sees bonus templates (read-only for users)
DROP POLICY IF EXISTS "Anyone sees bonus templates" ON xp_bonus_templates;
CREATE POLICY "Anyone sees bonus templates" ON xp_bonus_templates
  FOR SELECT USING (true);

-- Service manages bonus templates
DROP POLICY IF EXISTS "Service manages bonus templates" ON xp_bonus_templates;
CREATE POLICY "Service manages bonus templates" ON xp_bonus_templates
  FOR ALL USING (auth.role() = 'service_role');

-- Users see own checkpoint progress
DROP POLICY IF EXISTS "Users see own checkpoint progress" ON user_checkpoint_progress;
CREATE POLICY "Users see own checkpoint progress" ON user_checkpoint_progress
  FOR SELECT USING (auth.uid() = user_id);

-- Service manages checkpoint progress
DROP POLICY IF EXISTS "Service manages checkpoint progress" ON user_checkpoint_progress;
CREATE POLICY "Service manages checkpoint progress" ON user_checkpoint_progress
  FOR ALL USING (auth.role() = 'service_role');

-- =============================================================================
-- COMMENTS
-- =============================================================================

COMMENT ON TABLE user_login_streaks IS 'Tracks daily login streaks for XP bonuses';
COMMENT ON TABLE xp_events IS 'Double XP events and other limited-time XP bonuses';
COMMENT ON TABLE user_event_participation IS 'Records user participation in XP events';
COMMENT ON TABLE xp_bonus_templates IS 'Defines XP amounts for various bonus types';
COMMENT ON TABLE user_checkpoint_progress IS 'Tracks weekly/monthly checkpoint completion';
COMMENT ON FUNCTION process_daily_login IS 'Processes daily login, awards XP, updates streaks';
COMMENT ON FUNCTION get_active_xp_events IS 'Returns all currently active XP multiplier events';
COMMENT ON FUNCTION enable_double_xp_event IS 'Admin function to enable a Double XP event';
