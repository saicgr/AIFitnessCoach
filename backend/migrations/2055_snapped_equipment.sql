-- =====================================================================
-- 2055_snapped_equipment.sql
-- Snap-equipment flow (Issue #1, Task #6): persist user-snapped gym
-- equipment photos so the same canonical equipment can be reused across
-- swap / add / identify modes without re-running Vision.
--
-- See: /Users/saichetangrandhe/.claude/plans/1-image-1-in-here-jolly-wreath.md
--      backend/api/v1/equipment/snap.py
-- =====================================================================

CREATE TABLE IF NOT EXISTS snapped_equipment (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    s3_key          TEXT NOT NULL,
    canonical_name  TEXT NOT NULL,
    confidence      DOUBLE PRECISION,
    vision_label    TEXT,
    last_exercise_id UUID REFERENCES exercise_library(id) ON DELETE SET NULL,
    classified_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_via     TEXT CHECK (created_via IN ('swap','add','identify','import'))
);

CREATE INDEX IF NOT EXISTS idx_snapped_equipment_user_classified
    ON snapped_equipment (user_id, classified_at DESC);

CREATE INDEX IF NOT EXISTS idx_snapped_equipment_canonical
    ON snapped_equipment (user_id, canonical_name);

-- Row-level security: users see/modify only their own snaps.
ALTER TABLE snapped_equipment ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS snapped_equipment_select_own ON snapped_equipment;
CREATE POLICY snapped_equipment_select_own
    ON snapped_equipment
    FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS snapped_equipment_insert_own ON snapped_equipment;
CREATE POLICY snapped_equipment_insert_own
    ON snapped_equipment
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS snapped_equipment_update_own ON snapped_equipment;
CREATE POLICY snapped_equipment_update_own
    ON snapped_equipment
    FOR UPDATE
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS snapped_equipment_delete_own ON snapped_equipment;
CREATE POLICY snapped_equipment_delete_own
    ON snapped_equipment
    FOR DELETE
    USING (auth.uid() = user_id);

COMMENT ON TABLE snapped_equipment IS
    'Per-user history of gym-equipment snaps (point-camera-at-machine flow). '
    'The s3_key references the face-blurred, downscaled image; the original '
    'is deleted post-blur. last_exercise_id is set when the user confirms a '
    'swap/add to a specific exercise.';
