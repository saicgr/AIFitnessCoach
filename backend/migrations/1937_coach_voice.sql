-- ============================================================================
-- Migration 1937: Coach voice selection (cosmetic-gated)
-- ============================================================================
-- Adds `coach_voice_id` to user_ai_settings so the TTS service can pick the
-- user's chosen voice. Values correspond to cosmetics in the catalog:
--   'default'            (free for everyone)
--   'coach_voice_chad'   (unlocked at L50 via coach_voice_chad cosmetic)
--   'coach_voice_serena' (unlocked at L50 via coach_voice_serena cosmetic)
-- ============================================================================

ALTER TABLE user_ai_settings
  ADD COLUMN IF NOT EXISTS coach_voice_id TEXT DEFAULT 'default';

COMMENT ON COLUMN user_ai_settings.coach_voice_id IS
'Selected TTS voice. Values: default, coach_voice_chad, coach_voice_serena. Non-default values require owning the matching cosmetic (migration 1936).';
