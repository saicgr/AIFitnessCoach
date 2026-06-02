-- Migration 2224: Barcode (UPC/EAN) lookup key on food_nutrition_overrides
-- Purpose: let a scanned barcode short-circuit the Open Food Facts round-trip
-- when the product is already a curated/verified override row, and let a user's
-- learned correction for a product apply on the barcode path (Amy-audit Feature 1).
--
-- Design notes:
--   * NOT UNIQUE: the same GTIN can map to regional formulation variants
--     (US vs EU macros) — resolution by country happens in the lookup service.
--   * Stored NORMALIZED: UPC-A (12) is expanded to EAN-13 (13, leading 0) before
--     storing/looking up so a product scanned either way matches one row.
--   * Column is nullable; existing 199k rows stay NULL until backfilled. The
--     partial index is therefore tiny until products get barcodes, so a plain
--     (non-CONCURRENT) build holds only a brief lock on this read-mostly table.

ALTER TABLE food_nutrition_overrides
    ADD COLUMN IF NOT EXISTS barcode TEXT DEFAULT NULL;

COMMENT ON COLUMN food_nutrition_overrides.barcode IS
    'Normalized GTIN/EAN-13 (UPC-A expanded with leading 0). Nullable, non-unique '
    '(regional variants share a code). Lookup short-circuits Open Food Facts.';

CREATE INDEX IF NOT EXISTS idx_food_overrides_barcode
    ON food_nutrition_overrides (barcode)
    WHERE barcode IS NOT NULL;
