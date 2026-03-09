-- F13: Read receipts privacy setting
ALTER TABLE user_privacy_settings ADD COLUMN IF NOT EXISTS show_read_receipts BOOLEAN DEFAULT true;
