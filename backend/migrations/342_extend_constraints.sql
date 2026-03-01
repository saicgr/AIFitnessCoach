-- Migration 342: Extend branded_programs constraints for all program categories
-- This relaxes CHECK constraints to support all 80 program categories

-- Extend branded_programs.category to include all program types
ALTER TABLE branded_programs DROP CONSTRAINT IF EXISTS branded_programs_category_check;
ALTER TABLE branded_programs ADD CONSTRAINT branded_programs_category_check
CHECK (category IN (
  'strength', 'hypertrophy', 'endurance', 'athletic',
  'fat_loss', 'general_fitness', 'bodyweight', 'powerbuilding',
  'yoga', 'pilates', 'flexibility', 'cardio', 'rehab',
  'sport_specific', 'challenge', 'lifestyle', 'martial_arts',
  'dance', 'specialty', 'premium', 'celebrity', 'mind_body',
  'calisthenics', 'hiit', 'crossfit', 'functional',
  'mobility', 'recovery', 'posture', 'seniors',
  'kids_youth', 'womens_health', 'mens_health',
  'body_specific', 'equipment_specific', 'quick_workout',
  'warmup_cooldown', 'stretching', 'strongman',
  'outdoor', 'swimming', 'climbing', 'cycling',
  'running', 'hiking', 'skating', 'golf',
  'longevity', 'balance', 'hybrid', 'competition',
  'social_fitness', 'seasonal', 'sleep_recovery',
  'menstrual_cycle', 'medical', 'desk_break',
  'plyometrics', 'olympic_lifting', 'viral',
  'nervous_system', 'weighted_accessories',
  'home_workout', 'influencer', 'life_events',
  'reddit_famous', 'glute_building', 'anti_aging',
  'motivational', 'pet_friendly', 'ninja_mode',
  'mood_based', 'gen_z', 'gym_packed',
  'post_meal', 'fasted', 'quick_hit',
  'mood_quick', 'travel', 'night_shift',
  'gamer', 'cruise', 'face_jaw',
  'hell_mode', 'sedentary', 'occupation',
  'conditioning', 'progression'
));

-- Extend program_variants.duration_weeks to allow 1-52 weeks
ALTER TABLE program_variants DROP CONSTRAINT IF EXISTS program_variants_duration_weeks_check;
ALTER TABLE program_variants ADD CONSTRAINT program_variants_duration_weeks_check
CHECK (duration_weeks >= 1 AND duration_weeks <= 52);

-- Extend branded_programs.split_type to include more training splits
ALTER TABLE branded_programs DROP CONSTRAINT IF EXISTS branded_programs_split_type_check;
ALTER TABLE branded_programs ADD CONSTRAINT branded_programs_split_type_check
CHECK (split_type IN (
  'full_body', 'upper_lower', 'push_pull_legs', 'push_pull',
  'bro_split', 'arnold_split', 'custom', 'bodypart',
  'circuit', 'amrap', 'emom', 'tabata', 'flow',
  'linear', 'undulating', 'conjugate', 'block',
  'sport_specific', 'skill_based', 'movement_based',
  'time_based', 'intensity_based', 'single_session'
));

-- Extend branded_programs.difficulty_level
ALTER TABLE branded_programs DROP CONSTRAINT IF EXISTS branded_programs_difficulty_level_check;
ALTER TABLE branded_programs ADD CONSTRAINT branded_programs_difficulty_level_check
CHECK (difficulty_level IN (
  'beginner', 'intermediate', 'advanced', 'all_levels', 'elite'
));
