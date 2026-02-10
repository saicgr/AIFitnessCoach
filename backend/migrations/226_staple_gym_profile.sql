-- Add gym_profile_id to staple_exercises (NULL = all profiles)
ALTER TABLE staple_exercises
  ADD COLUMN gym_profile_id UUID REFERENCES gym_profiles(id) ON DELETE CASCADE;

-- Index for profile-scoped queries
CREATE INDEX idx_staple_exercises_gym_profile
  ON staple_exercises(user_id, gym_profile_id);

-- Update unique constraint: same exercise can exist in different profiles
-- Drop old unique constraint if it exists, then add new one
-- Use COALESCE for null-safe uniqueness (NULL gym_profile_id = 'all')
DROP INDEX IF EXISTS idx_staple_exercises_unique;
CREATE UNIQUE INDEX idx_staple_exercises_unique
  ON staple_exercises(user_id, exercise_name, COALESCE(gym_profile_id, '00000000-0000-0000-0000-000000000000'));

-- Update the view to include profile info
DROP VIEW IF EXISTS user_staples_with_details;
CREATE VIEW user_staples_with_details AS
SELECT
  se.id, se.user_id, se.exercise_name, se.library_id,
  se.muscle_group, se.reason, se.created_at, se.gym_profile_id,
  gp.name AS gym_profile_name, gp.color AS gym_profile_color, gp.icon AS gym_profile_icon,
  el.body_part, el.equipment, el.gif_url
FROM staple_exercises se
LEFT JOIN gym_profiles gp ON se.gym_profile_id = gp.id
LEFT JOIN exercise_library el ON se.library_id = el.id;
