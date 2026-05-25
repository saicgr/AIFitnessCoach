-- Migration 2107: Imports feature — shared_items + saved_tips tables.
--
-- shared_items is the universal record of everything a user shares into
-- Zealova via the system share sheet (iOS Share Extension, Android
-- ACTION_SEND), or via the web upload page. Every payload writes a row
-- from the moment it enters the funnel and is updated as the pipeline
-- progresses. Failures, cancellations, and manual overrides remain as
-- rows so the user has a single chronological "Imports" view.
--
-- saved_tips persists the intent=tip_save extraction output — short
-- motivational/educational summaries from Perplexity essays, X threads,
-- trainer voice notes, etc.

CREATE TABLE IF NOT EXISTS shared_items (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                 UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- What came in
    source_kind             TEXT NOT NULL,                       -- photo|video|url|text|pdf|carousel|audio
    source_origin           TEXT,                                -- photos|safari|youtube|instagram|tiktok|reddit|x|chatgpt|claude|perplexity|voicememos|files|notes|imessage|whatsapp|mail|shortcuts|web|other
    source_url              TEXT,
    raw_text                TEXT,                                -- truncated to 8 kB; full text in S3 via raw_text_s3_key if longer
    raw_text_s3_key         TEXT,
    media_s3_keys           TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],

    -- What we thought + what the user said
    classifier_intent       TEXT,                                -- workout_extract|recipe_extract|meal_plan_extract|food_log_extract|form_check|progress_log|tip_save|nutrition_question|discuss|unknown
    classifier_confidence   TEXT,                                -- high|medium|low
    user_override_intent    TEXT,                                -- non-null when the user reclassified via chooser/banner

    -- What we extracted
    extracted_payload       JSONB,
    target_entity_kind      TEXT,                                -- workout|recipe|food_log|menu_analysis|progress_photo|saved_tip|custom_exercise|form_check_job|chat|null
    target_entity_id        UUID,

    -- Lifecycle
    status                  TEXT NOT NULL DEFAULT 'received',    -- received|classifying|extracting|completed|overridden|failed|discarded|interrupted
    error_message           TEXT,

    -- Tags powering the Imports UI filter rail
    tags                    JSONB NOT NULL DEFAULT '{}'::JSONB,

    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT shared_items_source_kind_chk CHECK (
        source_kind IN ('photo', 'video', 'url', 'text', 'pdf', 'carousel', 'audio')
    ),
    CONSTRAINT shared_items_status_chk CHECK (
        status IN ('received', 'classifying', 'extracting', 'completed',
                   'overridden', 'failed', 'discarded', 'interrupted')
    )
);

CREATE INDEX IF NOT EXISTS shared_items_user_created_idx
    ON shared_items (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS shared_items_status_idx
    ON shared_items (user_id, status);

CREATE INDEX IF NOT EXISTS shared_items_tags_idx
    ON shared_items USING GIN (tags);

CREATE INDEX IF NOT EXISTS shared_items_source_kind_idx
    ON shared_items (user_id, source_kind);

-- updated_at trigger (mirrors existing convention elsewhere in the repo).
CREATE OR REPLACE FUNCTION set_shared_items_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_shared_items_updated_at ON shared_items;
CREATE TRIGGER trg_shared_items_updated_at
    BEFORE UPDATE ON shared_items
    FOR EACH ROW
    EXECUTE FUNCTION set_shared_items_updated_at();

-- RLS — every row is private to its user.
ALTER TABLE shared_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS shared_items_select_own ON shared_items;
CREATE POLICY shared_items_select_own
    ON shared_items FOR SELECT
    USING (user_id = auth.uid());

DROP POLICY IF EXISTS shared_items_insert_own ON shared_items;
CREATE POLICY shared_items_insert_own
    ON shared_items FOR INSERT
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS shared_items_update_own ON shared_items;
CREATE POLICY shared_items_update_own
    ON shared_items FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS shared_items_delete_own ON shared_items;
CREATE POLICY shared_items_delete_own
    ON shared_items FOR DELETE
    USING (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- saved_tips — short educational/motivational extractions
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS saved_tips (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    shared_item_id  UUID REFERENCES shared_items(id) ON DELETE SET NULL,
    source_url      TEXT,
    source_author   TEXT,
    source_origin   TEXT,
    summary         TEXT NOT NULL,
    full_text       TEXT,
    tags            JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS saved_tips_user_created_idx
    ON saved_tips (user_id, created_at DESC);

ALTER TABLE saved_tips ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS saved_tips_select_own ON saved_tips;
CREATE POLICY saved_tips_select_own
    ON saved_tips FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS saved_tips_insert_own ON saved_tips;
CREATE POLICY saved_tips_insert_own
    ON saved_tips FOR INSERT WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS saved_tips_update_own ON saved_tips;
CREATE POLICY saved_tips_update_own
    ON saved_tips FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS saved_tips_delete_own ON saved_tips;
CREATE POLICY saved_tips_delete_own
    ON saved_tips FOR DELETE USING (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Daily-rate-limit counter table for /share/* endpoints
-- ---------------------------------------------------------------------------
-- Single row per (user_id, day_utc, bucket). Buckets are coarse enough that
-- we keep the table tiny while still preventing abuse.

CREATE TABLE IF NOT EXISTS share_rate_counters (
    user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    day_local   DATE NOT NULL,           -- midnight in user's locale (best effort; UTC fallback)
    bucket      TEXT NOT NULL,           -- url|image|text|audio|pdf
    count       INTEGER NOT NULL DEFAULT 0,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, day_local, bucket)
);

ALTER TABLE share_rate_counters ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS share_rate_counters_select_own ON share_rate_counters;
CREATE POLICY share_rate_counters_select_own
    ON share_rate_counters FOR SELECT USING (user_id = auth.uid());
