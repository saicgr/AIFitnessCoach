-- Deploy 1 of 3 (ADDITIVE) for migrating users.equipment from
-- VARCHAR-of-JSON to a typed text[].
--
-- Context: equipment is stored as a string-encoded JSON array
-- (e.g. '["bodyweight","dumbbells"]'), or sometimes as a single value
-- ('Bodyweight'), or CSV ('bodyweight,dumbbells'). Read sites do
-- `parse_json_field(user.get("equipment"), [])` to defend against this
-- ambiguity. Moving to a Postgres-native text[] kills the round-trip
-- and makes RLS / index queries clean.
--
-- This migration ONLY adds the new column + backfills it. Reads still
-- come from the old `equipment` VARCHAR. Code dual-writes both columns
-- for one release cycle. Deploys 2 and 3 (separate migrations) cut
-- reads over and finally drop the old column.
--
-- Idempotent: every statement uses IF NOT EXISTS / coalesces with the
-- existing value, so re-running does nothing.

-- 1. Add the new typed column.
ALTER TABLE users
    ADD COLUMN IF NOT EXISTS equipment_v2 text[] NOT NULL DEFAULT '{}';

-- 2. Backfill from the old VARCHAR-of-JSON. Handle every observed shape:
--      a) JSON-array string:   '["bodyweight","Dumbbells"]'   → ['bodyweight','dumbbells']
--      b) Comma-separated CSV: 'Bodyweight, Dumbbells'        → ['bodyweight','dumbbells']
--      c) Single value:        'Bodyweight'                   → ['bodyweight']
--      d) NULL / empty:                                       → ['bodyweight'] (defensive)
--      e) Invalid JSON:        '{not valid}'                  → ['bodyweight'] (logged via NOTICE)
-- All values are lowercased + trimmed + deduped on the way in.
DO $$
DECLARE
    rec record;
    parsed text[];
BEGIN
    FOR rec IN SELECT id, equipment FROM users WHERE equipment_v2 = '{}' LOOP
        BEGIN
            IF rec.equipment IS NULL OR btrim(rec.equipment) = '' THEN
                parsed := ARRAY['bodyweight']::text[];
            ELSIF rec.equipment LIKE '[%]' THEN
                -- JSON array shape.
                SELECT array_agg(DISTINCT lower(btrim(elem)) ORDER BY lower(btrim(elem)))
                INTO parsed
                FROM jsonb_array_elements_text(rec.equipment::jsonb) elem
                WHERE btrim(elem) <> '';
            ELSIF rec.equipment LIKE '%,%' THEN
                -- CSV shape.
                SELECT array_agg(DISTINCT lower(btrim(elem)) ORDER BY lower(btrim(elem)))
                INTO parsed
                FROM unnest(string_to_array(rec.equipment, ',')) elem
                WHERE btrim(elem) <> '';
            ELSE
                -- Single value.
                parsed := ARRAY[lower(btrim(rec.equipment))]::text[];
            END IF;

            -- Defensive: never leave the column empty.
            IF parsed IS NULL OR cardinality(parsed) = 0 THEN
                parsed := ARRAY['bodyweight']::text[];
            END IF;

            UPDATE users SET equipment_v2 = parsed WHERE id = rec.id;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'equipment_v2 backfill failed for user % (raw=%): %, defaulting to [bodyweight]',
                rec.id, rec.equipment, SQLERRM;
            UPDATE users SET equipment_v2 = ARRAY['bodyweight']::text[] WHERE id = rec.id;
        END;
    END LOOP;
END $$;

-- 3. Index for future queries that filter / aggregate on equipment.
--    GIN supports `equipment_v2 @> ARRAY['bodyweight']` and similar.
CREATE INDEX IF NOT EXISTS idx_users_equipment_v2_gin
    ON users USING GIN (equipment_v2);

-- Sanity check: warn if any row has an empty array post-backfill.
DO $$
DECLARE
    empty_count int;
BEGIN
    SELECT COUNT(*) INTO empty_count FROM users WHERE cardinality(equipment_v2) = 0;
    IF empty_count > 0 THEN
        RAISE WARNING 'equipment_v2 backfill left % users with empty arrays', empty_count;
    END IF;
END $$;
