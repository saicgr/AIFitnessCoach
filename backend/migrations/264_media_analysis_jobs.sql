-- Media analysis background job queue
CREATE TABLE IF NOT EXISTS media_analysis_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    job_type VARCHAR(30) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    s3_keys TEXT[] NOT NULL,
    mime_types TEXT[] NOT NULL,
    media_types TEXT[] NOT NULL,
    params JSONB DEFAULT '{}',
    result JSONB,
    error_message TEXT,
    retry_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_media_jobs_user_id ON media_analysis_jobs(user_id);
CREATE INDEX IF NOT EXISTS idx_media_jobs_status ON media_analysis_jobs(status);
CREATE INDEX IF NOT EXISTS idx_media_jobs_pending ON media_analysis_jobs(status, created_at) WHERE status IN ('pending', 'in_progress');

-- RLS
ALTER TABLE media_analysis_jobs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own media jobs"
    ON media_analysis_jobs FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Service role can manage all media jobs"
    ON media_analysis_jobs FOR ALL
    USING (auth.role() = 'service_role');
