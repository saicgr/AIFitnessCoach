-- Migration: 1968_create_import_remap_audit.sql
-- Description: Audit + alias-learning tables for the bulk-remap sheet. When a
-- user maps "flat bench press" to canonical barbell_bench_press for all 147 rows
-- at once, we capture:
--   (a) an audit row so the batch can be reverted,
--   (b) a contribution row that feeds the global alias dictionary after review.

CREATE TABLE IF NOT EXISTS history_import_remap_audit (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    raw_name TEXT NOT NULL,
    canonical_name_before TEXT,
    canonical_name_after TEXT NOT NULL,
    exercise_id_before UUID,
    exercise_id_after UUID,
    rows_affected INTEGER NOT NULL CHECK (rows_affected >= 0),
    affected_row_ids UUID[] NOT NULL DEFAULT ARRAY[]::UUID[],
    reverted BOOLEAN NOT NULL DEFAULT false,
    reverted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_remap_audit_user_time
  ON history_import_remap_audit (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_remap_audit_user_raw
  ON history_import_remap_audit (user_id, LOWER(raw_name));

ALTER TABLE history_import_remap_audit ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own remap audit"
  ON history_import_remap_audit FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users insert own remap audit"
  ON history_import_remap_audit FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users update own remap audit"
  ON history_import_remap_audit FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Service role full access remap audit"
  ON history_import_remap_audit FOR ALL
  USING (auth.role() = 'service_role');


-- Alias contributions — user-submitted mappings that, after offline review,
-- get promoted into the global exercise_resolver alias dict. High-confidence
-- contributions (same mapping from ≥10 distinct users) auto-promote.

CREATE TABLE IF NOT EXISTS exercise_alias_contributions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    raw_name_lower TEXT NOT NULL,
    canonical_name TEXT NOT NULL,
    exercise_id UUID,
    submitter_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    source_app TEXT,                          -- context: which export app the raw name came from
    confidence NUMERIC(3, 2) DEFAULT 1.0 CHECK (confidence BETWEEN 0 AND 1),
    review_status TEXT NOT NULL DEFAULT 'pending'
      CHECK (review_status IN ('pending', 'approved', 'rejected', 'auto_approved')),
    reviewer_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    reviewed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_alias_contrib_raw_lower
  ON exercise_alias_contributions (raw_name_lower);

CREATE INDEX IF NOT EXISTS idx_alias_contrib_review
  ON exercise_alias_contributions (review_status, created_at DESC)
  WHERE review_status = 'pending';

-- Agreement query: how many distinct users have mapped raw_name_lower → canonical_name?
CREATE INDEX IF NOT EXISTS idx_alias_contrib_agreement
  ON exercise_alias_contributions (raw_name_lower, canonical_name, submitter_user_id);

-- Contributions are service-role only — no direct user access. The remap endpoint
-- service inserts on behalf of the user after the batch update commits.
ALTER TABLE exercise_alias_contributions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role full access alias contributions"
  ON exercise_alias_contributions FOR ALL
  USING (auth.role() = 'service_role');

COMMENT ON TABLE history_import_remap_audit IS
  'Audit log for bulk exercise-name remaps. Enables undo.';
COMMENT ON TABLE exercise_alias_contributions IS
  'User-submitted raw→canonical exercise name mappings. Feeds the global alias dict after review.';
