-- Add measurement_unit column for body measurement unit preference (cm or in)
ALTER TABLE users ADD COLUMN IF NOT EXISTS measurement_unit VARCHAR(5) DEFAULT NULL;
