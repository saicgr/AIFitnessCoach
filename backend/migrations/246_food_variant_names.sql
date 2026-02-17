-- Migration 246: Add variant_names and variant_text columns to food_database
-- Purpose: Enable fuzzy matching for spelling variations (Idly→Idli, Kimchee→Kimchi)
-- Created: 2026-02-16

-- Add columns
ALTER TABLE food_database ADD COLUMN IF NOT EXISTS variant_names TEXT[] DEFAULT '{}';
ALTER TABLE food_database ADD COLUMN IF NOT EXISTS variant_text TEXT;

-- Auto-sync variant_text from variant_names on insert/update
CREATE OR REPLACE FUNCTION sync_variant_text() RETURNS TRIGGER AS $$
BEGIN
  IF NEW.variant_names IS NOT NULL AND array_length(NEW.variant_names, 1) > 0 THEN
    NEW.variant_text := LOWER(array_to_string(NEW.variant_names, ' '));
  ELSE
    NEW.variant_text := NULL;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_variant_text ON food_database;
CREATE TRIGGER trg_sync_variant_text
  BEFORE INSERT OR UPDATE OF variant_names ON food_database
  FOR EACH ROW EXECUTE FUNCTION sync_variant_text();

-- Partial GIN trigram index (only rows with variant data, ~500 non-null rows)
CREATE INDEX IF NOT EXISTS idx_food_database_variant_text_trgm
  ON food_database USING GIN (variant_text gin_trgm_ops)
  WHERE variant_text IS NOT NULL;
