-- Migration: Add vague hints to hidden/secret achievements for Mystery Trophy display
-- Purpose: Ensure all hidden/secret achievements have cryptic hints that don't reveal how to unlock them

-- Update hidden achievements with vague hints
UPDATE achievement_types SET hint_text = 'A legendary feat awaits the truly dedicated...'
WHERE id = 'hidden_easter' AND (hint_text IS NULL OR hint_text = '');

UPDATE achievement_types SET hint_text = 'Perfection sustained through seasons...'
WHERE id = 'hidden_perfectionist' AND (hint_text IS NULL OR hint_text = '');

UPDATE achievement_types SET hint_text = 'Go beyond what is asked...'
WHERE id = 'hidden_overachiever' AND (hint_text IS NULL OR hint_text = '');

UPDATE achievement_types SET hint_text = 'A crown awaits the unwavering...'
WHERE id = 'hidden_king' AND (hint_text IS NULL OR hint_text = '');

UPDATE achievement_types SET hint_text = 'When others sleep, legends are forged...'
WHERE id = 'hidden_night_legend' AND (hint_text IS NULL OR hint_text = '');

UPDATE achievement_types SET hint_text = 'Mountains of iron moved by one...'
WHERE id = 'hidden_iron_legend' AND (hint_text IS NULL OR hint_text = '');

UPDATE achievement_types SET hint_text = 'Every single day, without fail...'
WHERE id = 'hidden_app_addict' AND (hint_text IS NULL OR hint_text = '');

UPDATE achievement_types SET hint_text = 'See what others cannot...'
WHERE id = 'hidden_oracle' AND (hint_text IS NULL OR hint_text = '');

UPDATE achievement_types SET hint_text = 'The phoenix rises from ashes...'
WHERE id = 'hidden_comeback' AND (hint_text IS NULL OR hint_text = '');

UPDATE achievement_types SET hint_text = 'Victory snatched from the jaws of time...'
WHERE id = 'hidden_clutch' AND (hint_text IS NULL OR hint_text = '');

-- Add default hints for any remaining hidden trophies without hints
UPDATE achievement_types
SET hint_text = 'A hidden achievement awaits discovery...'
WHERE is_hidden = true AND (hint_text IS NULL OR hint_text = '');

-- Add default hints for any remaining secret trophies without hints
UPDATE achievement_types
SET hint_text = 'A mysterious achievement shrouded in secrecy...'
WHERE is_secret = true AND (hint_text IS NULL OR hint_text = '');

-- Add hints based on category for achievements that have generic or no hints
-- Exercise mastery hidden trophies
UPDATE achievement_types
SET hint_text = 'Master the iron, unlock the unknown...'
WHERE category = 'exercise_mastery'
  AND (is_hidden = true OR is_secret = true)
  AND hint_text LIKE 'A hidden%';

-- Volume hidden trophies
UPDATE achievement_types
SET hint_text = 'Volume beyond measure awaits those who persist...'
WHERE category = 'volume'
  AND (is_hidden = true OR is_secret = true)
  AND hint_text LIKE 'A hidden%';

-- Consistency hidden trophies
UPDATE achievement_types
SET hint_text = 'Day after day, the dedicated are rewarded...'
WHERE category = 'consistency'
  AND (is_hidden = true OR is_secret = true)
  AND hint_text LIKE 'A hidden%';

-- Time hidden trophies
UPDATE achievement_types
SET hint_text = 'Time devoted to the craft reveals secrets...'
WHERE category = 'time'
  AND (is_hidden = true OR is_secret = true)
  AND hint_text LIKE 'A hidden%';

-- Personal records hidden trophies
UPDATE achievement_types
SET hint_text = 'Break through limits to unlock the impossible...'
WHERE category = 'personal_records'
  AND (is_hidden = true OR is_secret = true)
  AND hint_text LIKE 'A hidden%';

-- Nutrition hidden trophies
UPDATE achievement_types
SET hint_text = 'Fuel your body, unlock your potential...'
WHERE category = 'nutrition'
  AND (is_hidden = true OR is_secret = true)
  AND hint_text LIKE 'A hidden%';

-- Fasting hidden trophies
UPDATE achievement_types
SET hint_text = 'In restraint lies hidden power...'
WHERE category = 'fasting'
  AND (is_hidden = true OR is_secret = true)
  AND hint_text LIKE 'A hidden%';

-- Special hidden trophies
UPDATE achievement_types
SET hint_text = 'The extraordinary reveals itself to the worthy...'
WHERE category = 'special'
  AND (is_hidden = true OR is_secret = true)
  AND hint_text LIKE 'A hidden%';

-- AI Coach hidden trophies
UPDATE achievement_types
SET hint_text = 'Your AI companion holds secrets for the devoted...'
WHERE category = 'ai_coach'
  AND (is_hidden = true OR is_secret = true)
  AND hint_text LIKE 'A hidden%';
