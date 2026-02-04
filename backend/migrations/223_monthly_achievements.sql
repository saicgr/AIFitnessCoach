-- Migration 223: Monthly Achievements Tracking
-- Tracks 12 monthly achievements worth 5,250 XP total per month

-- =====================================================
-- 1. CREATE MONTHLY ACHIEVEMENTS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS user_monthly_achievements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  month_start DATE NOT NULL, -- First day of the month (e.g., 2025-01-01)

  -- Achievement 1: Monthly Dedication (500 XP) - 20+ active days
  active_days INTEGER DEFAULT 0,
  dedication_completed BOOLEAN DEFAULT FALSE,
  dedication_xp_awarded BOOLEAN DEFAULT FALSE,

  -- Achievement 2: Monthly Goal (1,000 XP) - Hit primary fitness goal
  goal_progress DECIMAL(5,2) DEFAULT 0, -- percentage toward goal
  goal_completed BOOLEAN DEFAULT FALSE,
  goal_xp_awarded BOOLEAN DEFAULT FALSE,

  -- Achievement 3: Monthly Nutrition (500 XP) - Hit macros 20+ days
  nutrition_days INTEGER DEFAULT 0,
  nutrition_completed BOOLEAN DEFAULT FALSE,
  nutrition_xp_awarded BOOLEAN DEFAULT FALSE,

  -- Achievement 4: Monthly Consistency (750 XP) - No missed scheduled workouts
  scheduled_workouts INTEGER DEFAULT 0,
  completed_workouts INTEGER DEFAULT 0,
  missed_workouts INTEGER DEFAULT 0,
  consistency_completed BOOLEAN DEFAULT FALSE,
  consistency_xp_awarded BOOLEAN DEFAULT FALSE,

  -- Achievement 5: Monthly Hydration (300 XP) - Hit water goal 25+ days
  hydration_days INTEGER DEFAULT 0,
  hydration_completed BOOLEAN DEFAULT FALSE,
  hydration_xp_awarded BOOLEAN DEFAULT FALSE,

  -- Achievement 6: Monthly Weight (400 XP) - On track with weight goal
  weight_on_track BOOLEAN DEFAULT FALSE, -- set by evaluation
  weight_completed BOOLEAN DEFAULT FALSE,
  weight_xp_awarded BOOLEAN DEFAULT FALSE,

  -- Achievement 7: Monthly Habits (400 XP) - 80%+ habit completion
  habit_completion_percent DECIMAL(5,2) DEFAULT 0,
  habits_completed BOOLEAN DEFAULT FALSE,
  habits_xp_awarded BOOLEAN DEFAULT FALSE,

  -- Achievement 8: Monthly PRs (500 XP) - Set 3+ personal records
  personal_records INTEGER DEFAULT 0,
  prs_completed BOOLEAN DEFAULT FALSE,
  prs_xp_awarded BOOLEAN DEFAULT FALSE,

  -- Achievement 9: Monthly Social Star (300 XP) - Share 10+ posts
  posts_shared INTEGER DEFAULT 0,
  social_star_completed BOOLEAN DEFAULT FALSE,
  social_star_xp_awarded BOOLEAN DEFAULT FALSE,

  -- Achievement 10: Monthly Supporter (200 XP) - React/comment on 50+ posts
  reactions_given INTEGER DEFAULT 0,
  comments_given INTEGER DEFAULT 0,
  supporter_completed BOOLEAN DEFAULT FALSE,
  supporter_xp_awarded BOOLEAN DEFAULT FALSE,

  -- Achievement 11: Monthly Networker (250 XP) - Add 10+ friends
  friends_added INTEGER DEFAULT 0,
  networker_completed BOOLEAN DEFAULT FALSE,
  networker_xp_awarded BOOLEAN DEFAULT FALSE,

  -- Achievement 12: Monthly Measurements (150 XP) - Log measurements 8+ times
  measurement_logs INTEGER DEFAULT 0,
  measurements_completed BOOLEAN DEFAULT FALSE,
  measurements_xp_awarded BOOLEAN DEFAULT FALSE,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(user_id, month_start)
);

-- Index for efficient queries
CREATE INDEX IF NOT EXISTS idx_monthly_achievements_user_month
ON user_monthly_achievements(user_id, month_start);

CREATE INDEX IF NOT EXISTS idx_monthly_achievements_month
ON user_monthly_achievements(month_start);

-- =====================================================
-- 2. MONTHLY ACHIEVEMENT REWARDS CONFIG
-- =====================================================

INSERT INTO checkpoint_rewards (checkpoint_type, period_type, xp_reward, description)
VALUES
  ('monthly_dedication', 'monthly', 500, '20+ active days this month'),
  ('monthly_goal', 'monthly', 1000, 'Hit your primary fitness goal'),
  ('monthly_nutrition', 'monthly', 500, 'Hit macros 20+ days'),
  ('monthly_consistency', 'monthly', 750, 'No missed scheduled workouts'),
  ('monthly_hydration', 'monthly', 300, 'Hit water goal 25+ days'),
  ('monthly_weight', 'monthly', 400, 'On track with weight goal'),
  ('monthly_habits', 'monthly', 400, '80%+ habit completion'),
  ('monthly_prs', 'monthly', 500, 'Set 3+ personal records'),
  ('monthly_social_star', 'monthly', 300, 'Share 10+ posts'),
  ('monthly_supporter', 'monthly', 200, 'React/comment on 50+ posts'),
  ('monthly_networker', 'monthly', 250, 'Add 10+ friends'),
  ('monthly_measurements', 'monthly', 150, 'Log measurements 8+ times')
ON CONFLICT DO NOTHING;

-- =====================================================
-- 3. INITIALIZE MONTHLY ACHIEVEMENTS FOR USER
-- =====================================================

CREATE OR REPLACE FUNCTION init_user_monthly_achievements(p_user_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_month_start DATE;
  v_record_id UUID;
BEGIN
  -- Get the first day of current month
  v_month_start := DATE_TRUNC('month', CURRENT_DATE)::DATE;

  -- Insert or get existing record
  INSERT INTO user_monthly_achievements (user_id, month_start)
  VALUES (p_user_id, v_month_start)
  ON CONFLICT (user_id, month_start) DO NOTHING
  RETURNING id INTO v_record_id;

  -- If nothing was inserted, get the existing ID
  IF v_record_id IS NULL THEN
    SELECT id INTO v_record_id
    FROM user_monthly_achievements
    WHERE user_id = p_user_id AND month_start = v_month_start;
  END IF;

  RETURN v_record_id;
END;
$$;

-- =====================================================
-- 4. INCREMENT FUNCTIONS FOR EACH ACHIEVEMENT
-- =====================================================

-- 4.1 Increment Active Days (for Monthly Dedication)
CREATE OR REPLACE FUNCTION increment_monthly_active_day(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_month_start DATE;
  v_record user_monthly_achievements%ROWTYPE;
  v_xp_awarded INTEGER := 0;
  v_result JSONB;
BEGIN
  v_month_start := DATE_TRUNC('month', CURRENT_DATE)::DATE;

  -- Ensure record exists
  PERFORM init_user_monthly_achievements(p_user_id);

  -- Update and check completion
  UPDATE user_monthly_achievements
  SET
    active_days = active_days + 1,
    dedication_completed = (active_days + 1) >= 20,
    updated_at = NOW()
  WHERE user_id = p_user_id AND month_start = v_month_start
  RETURNING * INTO v_record;

  -- Award XP if just completed
  IF v_record.dedication_completed AND NOT v_record.dedication_xp_awarded THEN
    UPDATE user_monthly_achievements
    SET dedication_xp_awarded = TRUE
    WHERE id = v_record.id;

    v_xp_awarded := 500;
    PERFORM award_xp(p_user_id, v_xp_awarded, 'monthly_dedication', v_record.id::TEXT,
                     'Monthly Dedication: 20+ active days');
  END IF;

  RETURN jsonb_build_object(
    'success', TRUE,
    'active_days', v_record.active_days + 1,
    'target', 20,
    'completed', v_record.dedication_completed OR (v_record.active_days + 1) >= 20,
    'xp_awarded', v_xp_awarded
  );
END;
$$;

-- 4.2 Update Goal Progress (for Monthly Goal)
CREATE OR REPLACE FUNCTION update_monthly_goal_progress(p_user_id UUID, p_progress DECIMAL)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_month_start DATE;
  v_record user_monthly_achievements%ROWTYPE;
  v_xp_awarded INTEGER := 0;
BEGIN
  v_month_start := DATE_TRUNC('month', CURRENT_DATE)::DATE;
  PERFORM init_user_monthly_achievements(p_user_id);

  UPDATE user_monthly_achievements
  SET
    goal_progress = p_progress,
    goal_completed = p_progress >= 100,
    updated_at = NOW()
  WHERE user_id = p_user_id AND month_start = v_month_start
  RETURNING * INTO v_record;

  IF v_record.goal_completed AND NOT v_record.goal_xp_awarded THEN
    UPDATE user_monthly_achievements
    SET goal_xp_awarded = TRUE
    WHERE id = v_record.id;

    v_xp_awarded := 1000;
    PERFORM award_xp(p_user_id, v_xp_awarded, 'monthly_goal', v_record.id::TEXT,
                     'Monthly Goal: Hit your primary fitness goal!');
  END IF;

  RETURN jsonb_build_object(
    'success', TRUE,
    'goal_progress', v_record.goal_progress,
    'target', 100,
    'completed', v_record.goal_completed OR p_progress >= 100,
    'xp_awarded', v_xp_awarded
  );
END;
$$;

-- 4.3 Increment Nutrition Days (for Monthly Nutrition)
CREATE OR REPLACE FUNCTION increment_monthly_nutrition(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_month_start DATE;
  v_record user_monthly_achievements%ROWTYPE;
  v_xp_awarded INTEGER := 0;
BEGIN
  v_month_start := DATE_TRUNC('month', CURRENT_DATE)::DATE;
  PERFORM init_user_monthly_achievements(p_user_id);

  UPDATE user_monthly_achievements
  SET
    nutrition_days = nutrition_days + 1,
    nutrition_completed = (nutrition_days + 1) >= 20,
    updated_at = NOW()
  WHERE user_id = p_user_id AND month_start = v_month_start
  RETURNING * INTO v_record;

  IF v_record.nutrition_completed AND NOT v_record.nutrition_xp_awarded THEN
    UPDATE user_monthly_achievements
    SET nutrition_xp_awarded = TRUE
    WHERE id = v_record.id;

    v_xp_awarded := 500;
    PERFORM award_xp(p_user_id, v_xp_awarded, 'monthly_nutrition', v_record.id::TEXT,
                     'Monthly Nutrition: Hit macros 20+ days');
  END IF;

  RETURN jsonb_build_object(
    'success', TRUE,
    'nutrition_days', v_record.nutrition_days + 1,
    'target', 20,
    'completed', v_record.nutrition_completed OR (v_record.nutrition_days + 1) >= 20,
    'xp_awarded', v_xp_awarded
  );
END;
$$;

-- 4.4 Track Workout Consistency (for Monthly Consistency)
CREATE OR REPLACE FUNCTION update_monthly_consistency(
  p_user_id UUID,
  p_scheduled INTEGER DEFAULT NULL,
  p_completed INTEGER DEFAULT NULL,
  p_missed INTEGER DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_month_start DATE;
  v_record user_monthly_achievements%ROWTYPE;
  v_xp_awarded INTEGER := 0;
  v_is_consistent BOOLEAN;
BEGIN
  v_month_start := DATE_TRUNC('month', CURRENT_DATE)::DATE;
  PERFORM init_user_monthly_achievements(p_user_id);

  -- Update whichever values are provided
  UPDATE user_monthly_achievements
  SET
    scheduled_workouts = COALESCE(p_scheduled, scheduled_workouts),
    completed_workouts = COALESCE(p_completed, completed_workouts),
    missed_workouts = COALESCE(p_missed, missed_workouts),
    updated_at = NOW()
  WHERE user_id = p_user_id AND month_start = v_month_start
  RETURNING * INTO v_record;

  -- Check if consistent: all scheduled completed, no missed
  v_is_consistent := v_record.missed_workouts = 0
                     AND v_record.completed_workouts >= v_record.scheduled_workouts
                     AND v_record.scheduled_workouts > 0;

  -- Update completion status at end of month or when clearly achieved
  UPDATE user_monthly_achievements
  SET consistency_completed = v_is_consistent
  WHERE id = v_record.id AND NOT consistency_xp_awarded;

  -- Award XP if completed (typically checked at month end)
  IF v_is_consistent AND NOT v_record.consistency_xp_awarded THEN
    -- Only award at month end - check if it's the last day
    IF CURRENT_DATE = (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day')::DATE THEN
      UPDATE user_monthly_achievements
      SET consistency_xp_awarded = TRUE
      WHERE id = v_record.id;

      v_xp_awarded := 750;
      PERFORM award_xp(p_user_id, v_xp_awarded, 'monthly_consistency', v_record.id::TEXT,
                       'Monthly Consistency: Perfect workout attendance!');
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'success', TRUE,
    'scheduled', v_record.scheduled_workouts,
    'completed', v_record.completed_workouts,
    'missed', v_record.missed_workouts,
    'on_track', v_record.missed_workouts = 0,
    'completed', v_is_consistent,
    'xp_awarded', v_xp_awarded
  );
END;
$$;

-- 4.5 Increment Hydration Days (for Monthly Hydration)
CREATE OR REPLACE FUNCTION increment_monthly_hydration(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_month_start DATE;
  v_record user_monthly_achievements%ROWTYPE;
  v_xp_awarded INTEGER := 0;
BEGIN
  v_month_start := DATE_TRUNC('month', CURRENT_DATE)::DATE;
  PERFORM init_user_monthly_achievements(p_user_id);

  UPDATE user_monthly_achievements
  SET
    hydration_days = hydration_days + 1,
    hydration_completed = (hydration_days + 1) >= 25,
    updated_at = NOW()
  WHERE user_id = p_user_id AND month_start = v_month_start
  RETURNING * INTO v_record;

  IF v_record.hydration_completed AND NOT v_record.hydration_xp_awarded THEN
    UPDATE user_monthly_achievements
    SET hydration_xp_awarded = TRUE
    WHERE id = v_record.id;

    v_xp_awarded := 300;
    PERFORM award_xp(p_user_id, v_xp_awarded, 'monthly_hydration', v_record.id::TEXT,
                     'Monthly Hydration: Hit water goal 25+ days');
  END IF;

  RETURN jsonb_build_object(
    'success', TRUE,
    'hydration_days', v_record.hydration_days + 1,
    'target', 25,
    'completed', v_record.hydration_completed OR (v_record.hydration_days + 1) >= 25,
    'xp_awarded', v_xp_awarded
  );
END;
$$;

-- 4.6 Update Weight On Track (for Monthly Weight)
CREATE OR REPLACE FUNCTION update_monthly_weight_status(p_user_id UUID, p_on_track BOOLEAN)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_month_start DATE;
  v_record user_monthly_achievements%ROWTYPE;
  v_xp_awarded INTEGER := 0;
BEGIN
  v_month_start := DATE_TRUNC('month', CURRENT_DATE)::DATE;
  PERFORM init_user_monthly_achievements(p_user_id);

  UPDATE user_monthly_achievements
  SET
    weight_on_track = p_on_track,
    weight_completed = p_on_track,
    updated_at = NOW()
  WHERE user_id = p_user_id AND month_start = v_month_start
  RETURNING * INTO v_record;

  -- Award at month end if on track
  IF p_on_track AND NOT v_record.weight_xp_awarded THEN
    IF CURRENT_DATE = (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day')::DATE THEN
      UPDATE user_monthly_achievements
      SET weight_xp_awarded = TRUE
      WHERE id = v_record.id;

      v_xp_awarded := 400;
      PERFORM award_xp(p_user_id, v_xp_awarded, 'monthly_weight', v_record.id::TEXT,
                       'Monthly Weight: On track with weight goal!');
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'success', TRUE,
    'weight_on_track', p_on_track,
    'completed', p_on_track,
    'xp_awarded', v_xp_awarded
  );
END;
$$;

-- 4.7 Update Habit Completion (for Monthly Habits)
CREATE OR REPLACE FUNCTION update_monthly_habits(p_user_id UUID, p_completion_percent DECIMAL)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_month_start DATE;
  v_record user_monthly_achievements%ROWTYPE;
  v_xp_awarded INTEGER := 0;
BEGIN
  v_month_start := DATE_TRUNC('month', CURRENT_DATE)::DATE;
  PERFORM init_user_monthly_achievements(p_user_id);

  UPDATE user_monthly_achievements
  SET
    habit_completion_percent = p_completion_percent,
    habits_completed = p_completion_percent >= 80,
    updated_at = NOW()
  WHERE user_id = p_user_id AND month_start = v_month_start
  RETURNING * INTO v_record;

  -- Award at month end if >= 80%
  IF p_completion_percent >= 80 AND NOT v_record.habits_xp_awarded THEN
    IF CURRENT_DATE = (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day')::DATE THEN
      UPDATE user_monthly_achievements
      SET habits_xp_awarded = TRUE
      WHERE id = v_record.id;

      v_xp_awarded := 400;
      PERFORM award_xp(p_user_id, v_xp_awarded, 'monthly_habits', v_record.id::TEXT,
                       'Monthly Habits: 80%+ habit completion!');
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'success', TRUE,
    'habit_completion_percent', p_completion_percent,
    'target', 80,
    'completed', p_completion_percent >= 80,
    'xp_awarded', v_xp_awarded
  );
END;
$$;

-- 4.8 Increment Personal Records (for Monthly PRs)
CREATE OR REPLACE FUNCTION increment_monthly_pr(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_month_start DATE;
  v_record user_monthly_achievements%ROWTYPE;
  v_xp_awarded INTEGER := 0;
BEGIN
  v_month_start := DATE_TRUNC('month', CURRENT_DATE)::DATE;
  PERFORM init_user_monthly_achievements(p_user_id);

  UPDATE user_monthly_achievements
  SET
    personal_records = personal_records + 1,
    prs_completed = (personal_records + 1) >= 3,
    updated_at = NOW()
  WHERE user_id = p_user_id AND month_start = v_month_start
  RETURNING * INTO v_record;

  IF v_record.prs_completed AND NOT v_record.prs_xp_awarded THEN
    UPDATE user_monthly_achievements
    SET prs_xp_awarded = TRUE
    WHERE id = v_record.id;

    v_xp_awarded := 500;
    PERFORM award_xp(p_user_id, v_xp_awarded, 'monthly_prs', v_record.id::TEXT,
                     'Monthly PRs: Set 3+ personal records!');
  END IF;

  RETURN jsonb_build_object(
    'success', TRUE,
    'personal_records', v_record.personal_records + 1,
    'target', 3,
    'completed', v_record.prs_completed OR (v_record.personal_records + 1) >= 3,
    'xp_awarded', v_xp_awarded
  );
END;
$$;

-- 4.9 Increment Posts Shared (for Monthly Social Star)
CREATE OR REPLACE FUNCTION increment_monthly_posts_shared(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_month_start DATE;
  v_record user_monthly_achievements%ROWTYPE;
  v_xp_awarded INTEGER := 0;
BEGIN
  v_month_start := DATE_TRUNC('month', CURRENT_DATE)::DATE;
  PERFORM init_user_monthly_achievements(p_user_id);

  UPDATE user_monthly_achievements
  SET
    posts_shared = posts_shared + 1,
    social_star_completed = (posts_shared + 1) >= 10,
    updated_at = NOW()
  WHERE user_id = p_user_id AND month_start = v_month_start
  RETURNING * INTO v_record;

  IF v_record.social_star_completed AND NOT v_record.social_star_xp_awarded THEN
    UPDATE user_monthly_achievements
    SET social_star_xp_awarded = TRUE
    WHERE id = v_record.id;

    v_xp_awarded := 300;
    PERFORM award_xp(p_user_id, v_xp_awarded, 'monthly_social_star', v_record.id::TEXT,
                     'Monthly Social Star: Share 10+ posts!');
  END IF;

  RETURN jsonb_build_object(
    'success', TRUE,
    'posts_shared', v_record.posts_shared + 1,
    'target', 10,
    'completed', v_record.social_star_completed OR (v_record.posts_shared + 1) >= 10,
    'xp_awarded', v_xp_awarded
  );
END;
$$;

-- 4.10 Increment Social Interactions (for Monthly Supporter)
CREATE OR REPLACE FUNCTION increment_monthly_social_interaction(
  p_user_id UUID,
  p_type TEXT DEFAULT 'reaction' -- 'reaction' or 'comment'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_month_start DATE;
  v_record user_monthly_achievements%ROWTYPE;
  v_xp_awarded INTEGER := 0;
  v_total_interactions INTEGER;
BEGIN
  v_month_start := DATE_TRUNC('month', CURRENT_DATE)::DATE;
  PERFORM init_user_monthly_achievements(p_user_id);

  IF p_type = 'comment' THEN
    UPDATE user_monthly_achievements
    SET
      comments_given = comments_given + 1,
      updated_at = NOW()
    WHERE user_id = p_user_id AND month_start = v_month_start
    RETURNING * INTO v_record;
  ELSE
    UPDATE user_monthly_achievements
    SET
      reactions_given = reactions_given + 1,
      updated_at = NOW()
    WHERE user_id = p_user_id AND month_start = v_month_start
    RETURNING * INTO v_record;
  END IF;

  v_total_interactions := v_record.reactions_given + v_record.comments_given;

  -- Update completion status
  UPDATE user_monthly_achievements
  SET supporter_completed = v_total_interactions >= 50
  WHERE id = v_record.id;

  IF v_total_interactions >= 50 AND NOT v_record.supporter_xp_awarded THEN
    UPDATE user_monthly_achievements
    SET supporter_xp_awarded = TRUE
    WHERE id = v_record.id;

    v_xp_awarded := 200;
    PERFORM award_xp(p_user_id, v_xp_awarded, 'monthly_supporter', v_record.id::TEXT,
                     'Monthly Supporter: React/comment on 50+ posts!');
  END IF;

  RETURN jsonb_build_object(
    'success', TRUE,
    'reactions', v_record.reactions_given + CASE WHEN p_type = 'reaction' THEN 1 ELSE 0 END,
    'comments', v_record.comments_given + CASE WHEN p_type = 'comment' THEN 1 ELSE 0 END,
    'total', v_total_interactions + 1,
    'target', 50,
    'completed', v_total_interactions + 1 >= 50,
    'xp_awarded', v_xp_awarded
  );
END;
$$;

-- 4.11 Increment Friends Added (for Monthly Networker)
CREATE OR REPLACE FUNCTION increment_monthly_friends(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_month_start DATE;
  v_record user_monthly_achievements%ROWTYPE;
  v_xp_awarded INTEGER := 0;
BEGIN
  v_month_start := DATE_TRUNC('month', CURRENT_DATE)::DATE;
  PERFORM init_user_monthly_achievements(p_user_id);

  UPDATE user_monthly_achievements
  SET
    friends_added = friends_added + 1,
    networker_completed = (friends_added + 1) >= 10,
    updated_at = NOW()
  WHERE user_id = p_user_id AND month_start = v_month_start
  RETURNING * INTO v_record;

  IF v_record.networker_completed AND NOT v_record.networker_xp_awarded THEN
    UPDATE user_monthly_achievements
    SET networker_xp_awarded = TRUE
    WHERE id = v_record.id;

    v_xp_awarded := 250;
    PERFORM award_xp(p_user_id, v_xp_awarded, 'monthly_networker', v_record.id::TEXT,
                     'Monthly Networker: Add 10+ friends!');
  END IF;

  RETURN jsonb_build_object(
    'success', TRUE,
    'friends_added', v_record.friends_added + 1,
    'target', 10,
    'completed', v_record.networker_completed OR (v_record.friends_added + 1) >= 10,
    'xp_awarded', v_xp_awarded
  );
END;
$$;

-- 4.12 Increment Measurement Logs (for Monthly Measurements)
CREATE OR REPLACE FUNCTION increment_monthly_measurements(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_month_start DATE;
  v_record user_monthly_achievements%ROWTYPE;
  v_xp_awarded INTEGER := 0;
BEGIN
  v_month_start := DATE_TRUNC('month', CURRENT_DATE)::DATE;
  PERFORM init_user_monthly_achievements(p_user_id);

  UPDATE user_monthly_achievements
  SET
    measurement_logs = measurement_logs + 1,
    measurements_completed = (measurement_logs + 1) >= 8,
    updated_at = NOW()
  WHERE user_id = p_user_id AND month_start = v_month_start
  RETURNING * INTO v_record;

  IF v_record.measurements_completed AND NOT v_record.measurements_xp_awarded THEN
    UPDATE user_monthly_achievements
    SET measurements_xp_awarded = TRUE
    WHERE id = v_record.id;

    v_xp_awarded := 150;
    PERFORM award_xp(p_user_id, v_xp_awarded, 'monthly_measurements', v_record.id::TEXT,
                     'Monthly Measurements: Log measurements 8+ times!');
  END IF;

  RETURN jsonb_build_object(
    'success', TRUE,
    'measurement_logs', v_record.measurement_logs + 1,
    'target', 8,
    'completed', v_record.measurements_completed OR (v_record.measurement_logs + 1) >= 8,
    'xp_awarded', v_xp_awarded
  );
END;
$$;

-- =====================================================
-- 5. GET FULL MONTHLY PROGRESS FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION get_monthly_achievements_progress(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_month_start DATE;
  v_record user_monthly_achievements%ROWTYPE;
  v_days_in_month INTEGER;
  v_days_remaining INTEGER;
BEGIN
  v_month_start := DATE_TRUNC('month', CURRENT_DATE)::DATE;
  v_days_in_month := EXTRACT(DAY FROM (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day'))::INTEGER;
  v_days_remaining := v_days_in_month - EXTRACT(DAY FROM CURRENT_DATE)::INTEGER;

  -- Initialize if not exists
  PERFORM init_user_monthly_achievements(p_user_id);

  SELECT * INTO v_record
  FROM user_monthly_achievements
  WHERE user_id = p_user_id AND month_start = v_month_start;

  RETURN jsonb_build_object(
    'month', TO_CHAR(v_month_start, 'YYYY-MM'),
    'month_name', TO_CHAR(v_month_start, 'Month YYYY'),
    'days_in_month', v_days_in_month,
    'days_remaining', v_days_remaining,
    'total_xp_possible', 5250,
    'achievements', jsonb_build_array(
      jsonb_build_object(
        'id', 'dedication',
        'name', 'Monthly Dedication',
        'description', '20+ active days this month',
        'icon', 'calendar_month',
        'current', v_record.active_days,
        'target', 20,
        'xp_reward', 500,
        'completed', v_record.dedication_completed,
        'xp_awarded', v_record.dedication_xp_awarded
      ),
      jsonb_build_object(
        'id', 'goal',
        'name', 'Monthly Goal',
        'description', 'Hit your primary fitness goal',
        'icon', 'flag',
        'current', v_record.goal_progress,
        'target', 100,
        'unit', '%',
        'xp_reward', 1000,
        'completed', v_record.goal_completed,
        'xp_awarded', v_record.goal_xp_awarded
      ),
      jsonb_build_object(
        'id', 'nutrition',
        'name', 'Monthly Nutrition',
        'description', 'Hit macros 20+ days',
        'icon', 'restaurant',
        'current', v_record.nutrition_days,
        'target', 20,
        'xp_reward', 500,
        'completed', v_record.nutrition_completed,
        'xp_awarded', v_record.nutrition_xp_awarded
      ),
      jsonb_build_object(
        'id', 'consistency',
        'name', 'Monthly Consistency',
        'description', 'No missed scheduled workouts',
        'icon', 'check_circle',
        'current', v_record.completed_workouts,
        'scheduled', v_record.scheduled_workouts,
        'missed', v_record.missed_workouts,
        'xp_reward', 750,
        'completed', v_record.consistency_completed,
        'xp_awarded', v_record.consistency_xp_awarded
      ),
      jsonb_build_object(
        'id', 'hydration',
        'name', 'Monthly Hydration',
        'description', 'Hit water goal 25+ days',
        'icon', 'water_drop',
        'current', v_record.hydration_days,
        'target', 25,
        'xp_reward', 300,
        'completed', v_record.hydration_completed,
        'xp_awarded', v_record.hydration_xp_awarded
      ),
      jsonb_build_object(
        'id', 'weight',
        'name', 'Monthly Weight',
        'description', 'On track with weight goal',
        'icon', 'monitor_weight',
        'on_track', v_record.weight_on_track,
        'xp_reward', 400,
        'completed', v_record.weight_completed,
        'xp_awarded', v_record.weight_xp_awarded
      ),
      jsonb_build_object(
        'id', 'habits',
        'name', 'Monthly Habits',
        'description', '80%+ habit completion',
        'icon', 'checklist',
        'current', v_record.habit_completion_percent,
        'target', 80,
        'unit', '%',
        'xp_reward', 400,
        'completed', v_record.habits_completed,
        'xp_awarded', v_record.habits_xp_awarded
      ),
      jsonb_build_object(
        'id', 'prs',
        'name', 'Monthly PRs',
        'description', 'Set 3+ personal records',
        'icon', 'emoji_events',
        'current', v_record.personal_records,
        'target', 3,
        'xp_reward', 500,
        'completed', v_record.prs_completed,
        'xp_awarded', v_record.prs_xp_awarded
      ),
      jsonb_build_object(
        'id', 'social_star',
        'name', 'Monthly Social Star',
        'description', 'Share 10+ posts',
        'icon', 'share',
        'current', v_record.posts_shared,
        'target', 10,
        'xp_reward', 300,
        'completed', v_record.social_star_completed,
        'xp_awarded', v_record.social_star_xp_awarded
      ),
      jsonb_build_object(
        'id', 'supporter',
        'name', 'Monthly Supporter',
        'description', 'React/comment on 50+ posts',
        'icon', 'favorite',
        'reactions', v_record.reactions_given,
        'comments', v_record.comments_given,
        'current', v_record.reactions_given + v_record.comments_given,
        'target', 50,
        'xp_reward', 200,
        'completed', v_record.supporter_completed,
        'xp_awarded', v_record.supporter_xp_awarded
      ),
      jsonb_build_object(
        'id', 'networker',
        'name', 'Monthly Networker',
        'description', 'Add 10+ friends',
        'icon', 'group_add',
        'current', v_record.friends_added,
        'target', 10,
        'xp_reward', 250,
        'completed', v_record.networker_completed,
        'xp_awarded', v_record.networker_xp_awarded
      ),
      jsonb_build_object(
        'id', 'measurements',
        'name', 'Monthly Measurements',
        'description', 'Log measurements 8+ times',
        'icon', 'straighten',
        'current', v_record.measurement_logs,
        'target', 8,
        'xp_reward', 150,
        'completed', v_record.measurements_completed,
        'xp_awarded', v_record.measurements_xp_awarded
      )
    )
  );
END;
$$;

-- =====================================================
-- 6. MONTH-END EVALUATION FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION evaluate_monthly_achievements(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_month_start DATE;
  v_record user_monthly_achievements%ROWTYPE;
  v_total_xp_awarded INTEGER := 0;
  v_achievements_completed INTEGER := 0;
BEGIN
  v_month_start := DATE_TRUNC('month', CURRENT_DATE)::DATE;

  SELECT * INTO v_record
  FROM user_monthly_achievements
  WHERE user_id = p_user_id AND month_start = v_month_start;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', FALSE, 'error', 'No monthly record found');
  END IF;

  -- Award pending achievements that require month-end evaluation

  -- Consistency (750 XP)
  IF v_record.missed_workouts = 0
     AND v_record.completed_workouts >= v_record.scheduled_workouts
     AND v_record.scheduled_workouts > 0
     AND NOT v_record.consistency_xp_awarded THEN
    UPDATE user_monthly_achievements
    SET consistency_completed = TRUE, consistency_xp_awarded = TRUE
    WHERE id = v_record.id;
    PERFORM award_xp(p_user_id, 750, 'monthly_consistency', v_record.id::TEXT,
                     'Monthly Consistency: Perfect workout attendance!');
    v_total_xp_awarded := v_total_xp_awarded + 750;
    v_achievements_completed := v_achievements_completed + 1;
  END IF;

  -- Weight (400 XP)
  IF v_record.weight_on_track AND NOT v_record.weight_xp_awarded THEN
    UPDATE user_monthly_achievements
    SET weight_completed = TRUE, weight_xp_awarded = TRUE
    WHERE id = v_record.id;
    PERFORM award_xp(p_user_id, 400, 'monthly_weight', v_record.id::TEXT,
                     'Monthly Weight: On track with weight goal!');
    v_total_xp_awarded := v_total_xp_awarded + 400;
    v_achievements_completed := v_achievements_completed + 1;
  END IF;

  -- Habits (400 XP)
  IF v_record.habit_completion_percent >= 80 AND NOT v_record.habits_xp_awarded THEN
    UPDATE user_monthly_achievements
    SET habits_completed = TRUE, habits_xp_awarded = TRUE
    WHERE id = v_record.id;
    PERFORM award_xp(p_user_id, 400, 'monthly_habits', v_record.id::TEXT,
                     'Monthly Habits: 80%+ habit completion!');
    v_total_xp_awarded := v_total_xp_awarded + 400;
    v_achievements_completed := v_achievements_completed + 1;
  END IF;

  RETURN jsonb_build_object(
    'success', TRUE,
    'month', TO_CHAR(v_month_start, 'YYYY-MM'),
    'achievements_completed', v_achievements_completed,
    'total_xp_awarded', v_total_xp_awarded
  );
END;
$$;

-- =====================================================
-- 7. RLS POLICIES
-- =====================================================

ALTER TABLE user_monthly_achievements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own monthly achievements"
ON user_monthly_achievements FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own monthly achievements"
ON user_monthly_achievements FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own monthly achievements"
ON user_monthly_achievements FOR UPDATE
USING (auth.uid() = user_id);

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION init_user_monthly_achievements TO authenticated;
GRANT EXECUTE ON FUNCTION increment_monthly_active_day TO authenticated;
GRANT EXECUTE ON FUNCTION update_monthly_goal_progress TO authenticated;
GRANT EXECUTE ON FUNCTION increment_monthly_nutrition TO authenticated;
GRANT EXECUTE ON FUNCTION update_monthly_consistency TO authenticated;
GRANT EXECUTE ON FUNCTION increment_monthly_hydration TO authenticated;
GRANT EXECUTE ON FUNCTION update_monthly_weight_status TO authenticated;
GRANT EXECUTE ON FUNCTION update_monthly_habits TO authenticated;
GRANT EXECUTE ON FUNCTION increment_monthly_pr TO authenticated;
GRANT EXECUTE ON FUNCTION increment_monthly_posts_shared TO authenticated;
GRANT EXECUTE ON FUNCTION increment_monthly_social_interaction TO authenticated;
GRANT EXECUTE ON FUNCTION increment_monthly_friends TO authenticated;
GRANT EXECUTE ON FUNCTION increment_monthly_measurements TO authenticated;
GRANT EXECUTE ON FUNCTION get_monthly_achievements_progress TO authenticated;
GRANT EXECUTE ON FUNCTION evaluate_monthly_achievements TO authenticated;

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================
-- This migration adds:
-- 1. user_monthly_achievements table tracking all 12 achievements
-- 2. checkpoint_rewards entries for monthly achievement XP values
-- 3. 12 increment/update functions for each achievement type
-- 4. get_monthly_achievements_progress for full progress retrieval
-- 5. evaluate_monthly_achievements for month-end XP awards
-- Total XP possible per month: 5,250 XP
