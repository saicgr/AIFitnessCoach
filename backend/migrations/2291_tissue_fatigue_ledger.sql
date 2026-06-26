-- Migration: 2291_tissue_fatigue_ledger.sql
-- Created: 2026-06-26
-- Purpose: Dr-Yaad audit #4 — a per-JOINT/TISSUE fatigue ledger. His "four
--          ledgers" include tissue load (elbows/wrists/tendons) accumulating
--          across exercises that share a stress profile, so the engine "sees
--          injuries coming before they happen." We already own per-exercise
--          tissue_stress (migration 2290); this table accumulates it per user
--          per tissue with exponential decay (applied in the service on read).
--
--          No hard FK on user_id — workouts/strength tables key on
--          public.users.id and the auth_id-vs-id trap (see memory) makes a
--          constraint risky; the service only ever upserts known user ids.

CREATE TABLE IF NOT EXISTS tissue_fatigue (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID NOT NULL,
    tissue       TEXT NOT NULL,           -- shoulder|elbow|wrist|knee|hip|lumbar|ankle|achilles|neck
    accumulated_load NUMERIC NOT NULL DEFAULT 0,
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, tissue)
);

CREATE INDEX IF NOT EXISTS idx_tissue_fatigue_user ON tissue_fatigue (user_id);
