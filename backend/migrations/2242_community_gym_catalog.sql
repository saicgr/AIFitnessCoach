-- Migration 2242: Community Gym Catalog (Feature 3B)
--
-- Context: Travel Mode + a grow-as-you-go community gym catalog. When a user
-- searches "gyms near me", the backend hits Google Places, and each returned
-- gym is UPSERTed into a canonical `gyms` table (keyed by Places place_id) so
-- the catalog grows organically without any seed/mock data. Users can then
-- REPORT the equipment they see at a gym; once CONSENSUS_MIN_REPORTERS (3)
-- distinct users agree an item is present, it is shown as "confirmed".
--
-- Two tables + one consensus view:
--   gyms                    — canonical gym rows (one per Places place_id)
--   gym_equipment_reports   — one row per (user, gym): that user's reported set
--   gym_equipment_consensus — VIEW: per (place_id, item) reporter count + confirmed flag
--
-- FK targets: gym_equipment_reports.user_id → public.users(id) (the safe FK
-- target used across the per-gym stream — auth.users is NOT directly FK-able
-- from app tables in this schema). place_id → gyms(place_id) ON DELETE CASCADE.
--
-- Fully idempotent (IF NOT EXISTS / CREATE OR REPLACE).

-- ============================================================================
-- 1. Canonical gyms catalog
-- ============================================================================
CREATE TABLE IF NOT EXISTS gyms (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    place_id      TEXT UNIQUE NOT NULL,
    name          TEXT NOT NULL,
    address       TEXT,
    city          TEXT,
    latitude      DOUBLE PRECISION,
    longitude     DOUBLE PRECISION,
    source        TEXT NOT NULL DEFAULT 'places',
    seen_count    INTEGER NOT NULL DEFAULT 1,
    first_seen_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_seen_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Geo lookups for the "nearby canonical gyms" bounding-box query (used when the
-- Places key is unconfigured → catalog_only path).
CREATE INDEX IF NOT EXISTS idx_gyms_lat_lng
    ON gyms(latitude, longitude);

COMMENT ON TABLE gyms IS
    'Community gym catalog. One row per Google Places place_id. Grows organically '
    'from /community-gyms/nearby Places upserts + user equipment reports. No seed data.';

-- ============================================================================
-- 2. Per-user equipment reports (one row per user per gym, replaced on resubmit)
-- ============================================================================
CREATE TABLE IF NOT EXISTS gym_equipment_reports (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    place_id          TEXT NOT NULL REFERENCES gyms(place_id) ON DELETE CASCADE,
    equipment         TEXT[] NOT NULL DEFAULT '{}',
    equipment_details JSONB NOT NULL DEFAULT '[]'::jsonb,
    source            TEXT NOT NULL DEFAULT 'manual',
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    -- One report row per user per gym. Resubmitting REPLACES the prior row
    -- (the endpoint UPSERTs on this constraint).
    UNIQUE(user_id, place_id)
);

CREATE INDEX IF NOT EXISTS idx_gym_equipment_reports_place
    ON gym_equipment_reports(place_id);
CREATE INDEX IF NOT EXISTS idx_gym_equipment_reports_user
    ON gym_equipment_reports(user_id);

COMMENT ON TABLE gym_equipment_reports IS
    'Crowdsourced per-user equipment reports for a community gym. UNIQUE(user_id,place_id) '
    'means each user keeps exactly one report per gym (replaced on resubmit).';

-- ============================================================================
-- 3. Consensus view — reporter count per (gym, item); confirmed when >= 3
-- ============================================================================
-- unnest each report's equipment array, count DISTINCT reporters per item.
-- confirmed = count(DISTINCT user_id) >= CONSENSUS_MIN_REPORTERS (3).
CREATE OR REPLACE VIEW gym_equipment_consensus AS
SELECT
    r.place_id                              AS place_id,
    item                                    AS equipment,
    COUNT(DISTINCT r.user_id)               AS reporter_count,
    (COUNT(DISTINCT r.user_id) >= 3)        AS confirmed
FROM gym_equipment_reports r
CROSS JOIN LATERAL unnest(r.equipment) AS item
GROUP BY r.place_id, item;

COMMENT ON VIEW gym_equipment_consensus IS
    'Per (place_id, equipment) reporter count across gym_equipment_reports. '
    'confirmed = reporter_count >= 3 (CONSENSUS_MIN_REPORTERS). Items below 3 are '
    '"reported" (unconfirmed) pills in the UI.';

-- ============================================================================
-- 4. Grants (mirror the per-gym stream's grant pattern)
-- ============================================================================
GRANT SELECT, INSERT, UPDATE, DELETE ON gyms TO authenticated, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON gym_equipment_reports TO authenticated, service_role;
GRANT SELECT ON gym_equipment_consensus TO authenticated, service_role;
