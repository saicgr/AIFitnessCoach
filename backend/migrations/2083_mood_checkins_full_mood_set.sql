-- Migration: 2083_mood_checkins_full_mood_set.sql
-- ---------------------------------------------------------------------------
-- Part 4 (write→read consistency) dependency for the mobile mood-log path.
--
-- The mobile app's `Mood` enum (lib/data/models/mood.dart) now has TEN moods:
--   great, good, motivated, angry, calm, stressed, anxious, tired, low, focused
--
-- But mood_checkins.mood (migration 058) still CHECK-constrains to the
-- ORIGINAL four (great, good, tired, stressed). Every check-in row written
-- with one of the six newer moods (motivated/angry/calm/anxious/low/focused)
-- was being REJECTED by Postgres — and `generate-from-mood-stream` silently
-- swallowed the resulting exception. So "Just Log Mood" / mood-driven workout
-- generation could not persist most moods at all, and the Mood History / Stats
-- screens never saw them.
--
-- This migration relaxes the CHECK to the full ten-mood set so a logged mood
-- actually lands in mood_checkins and is visible on every mood surface.
-- ---------------------------------------------------------------------------

ALTER TABLE mood_checkins
    DROP CONSTRAINT IF EXISTS mood_checkins_mood_check;

ALTER TABLE mood_checkins
    ADD CONSTRAINT mood_checkins_mood_check
    CHECK (mood IN (
        'great', 'good', 'motivated', 'angry', 'calm',
        'stressed', 'anxious', 'tired', 'low', 'focused'
    ));
