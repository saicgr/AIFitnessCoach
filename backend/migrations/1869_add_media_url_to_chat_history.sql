-- Add media_url and media_type columns to chat_history
-- This allows image/video messages to persist their S3 URL so they
-- can be displayed correctly when chat history is reloaded after app restart.
ALTER TABLE chat_history ADD COLUMN IF NOT EXISTS media_url TEXT;
ALTER TABLE chat_history ADD COLUMN IF NOT EXISTS media_type TEXT;
