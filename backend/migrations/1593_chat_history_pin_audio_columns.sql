-- Add pin and audio columns for chat features (Phase 3)
ALTER TABLE chat_history ADD COLUMN IF NOT EXISTS is_pinned BOOLEAN DEFAULT FALSE;
ALTER TABLE chat_history ADD COLUMN IF NOT EXISTS audio_url TEXT;
ALTER TABLE chat_history ADD COLUMN IF NOT EXISTS audio_duration_ms INTEGER;
