-- Add attachments, steps_to_reproduce, and screen_context to support_tickets
-- All fields are optional to maintain backward compatibility

ALTER TABLE support_tickets
  ADD COLUMN IF NOT EXISTS attachments TEXT[],
  ADD COLUMN IF NOT EXISTS steps_to_reproduce TEXT,
  ADD COLUMN IF NOT EXISTS screen_context TEXT;
