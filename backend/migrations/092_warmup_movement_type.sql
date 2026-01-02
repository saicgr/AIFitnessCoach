-- Migration: 092_warmup_movement_type.sql
-- Add movement_type classification to warm-up exercises for proper ordering
-- Static holds should come EARLY in warmups, followed by dynamic movements
-- This addresses user feedback: "warm-ups should have static holds early, not intermixed with kinetic moves"

-- Add movement_type column to exercises table for categorization
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS movement_type TEXT DEFAULT 'dynamic';

-- Add constraint for valid movement types
ALTER TABLE exercises DROP CONSTRAINT IF EXISTS exercises_movement_type_check;
ALTER TABLE exercises ADD CONSTRAINT exercises_movement_type_check
    CHECK (movement_type IN ('static', 'dynamic', 'mixed'));

-- Update existing exercises with movement type based on common patterns
-- Static exercises (holds, isometric)
UPDATE exercises SET movement_type = 'static'
WHERE LOWER(name) LIKE '%hold%'
   OR LOWER(name) LIKE '%plank%'
   OR LOWER(name) LIKE '%wall sit%'
   OR LOWER(name) LIKE '%dead hang%'
   OR LOWER(name) LIKE '%isometric%'
   OR LOWER(name) LIKE '%static%'
   OR LOWER(name) LIKE '%l-sit%'
   OR LOWER(name) LIKE '%hollow%'
   OR LOWER(name) LIKE '%bridge hold%';

-- Dynamic exercises (movement-based)
UPDATE exercises SET movement_type = 'dynamic'
WHERE LOWER(name) LIKE '%jumping%'
   OR LOWER(name) LIKE '%circles%'
   OR LOWER(name) LIKE '%swings%'
   OR LOWER(name) LIKE '%jacks%'
   OR LOWER(name) LIKE '%high knees%'
   OR LOWER(name) LIKE '%butt kicks%'
   OR LOWER(name) LIKE '%skips%'
   OR LOWER(name) LIKE '%march%'
   OR LOWER(name) LIKE '%rotation%'
   OR LOWER(name) LIKE '%twist%';

-- Create a view for warmup exercises with movement type
CREATE OR REPLACE VIEW warmup_exercises_with_type AS
SELECT
    e.*,
    CASE
        WHEN LOWER(e.name) LIKE '%hold%' OR LOWER(e.name) LIKE '%plank%'
             OR LOWER(e.name) LIKE '%wall sit%' OR LOWER(e.name) LIKE '%isometric%'
             OR LOWER(e.name) LIKE '%static%' OR LOWER(e.name) LIKE '%dead hang%'
        THEN 'static'
        ELSE 'dynamic'
    END AS inferred_movement_type
FROM exercises e
WHERE e.body_part IN ('cardio', 'stretching')
   OR LOWER(e.name) LIKE '%warm%up%'
   OR LOWER(e.name) LIKE '%warmup%';

-- Add index for efficient movement type queries
CREATE INDEX IF NOT EXISTS idx_exercises_movement_type ON exercises(movement_type);

-- Log migration
INSERT INTO migration_log (migration_name, applied_at, description)
VALUES (
    '092_warmup_movement_type',
    NOW(),
    'Added movement_type classification to exercises for proper warmup ordering'
) ON CONFLICT DO NOTHING;

COMMENT ON COLUMN exercises.movement_type IS 'Exercise movement type: static (holds/isometric), dynamic (movement-based), or mixed';
