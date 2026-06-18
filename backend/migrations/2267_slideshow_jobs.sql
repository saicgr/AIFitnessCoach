-- Slideshow / transformation-video render job queue.
-- Modeled on 264_media_analysis_jobs.sql. A POST kicks a FastAPI BackgroundTask
-- that renders the MP4 (slideshow_service.py) and writes result_url back here;
-- the client polls GET /workout-photos/slideshow/{job_id} for status.
CREATE TABLE IF NOT EXISTS slideshow_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    status VARCHAR(20) NOT NULL DEFAULT 'pending',  -- pending | processing | done | error
    source VARCHAR(30) NOT NULL,                     -- workout_photos | progress_photos | food
    params JSONB NOT NULL DEFAULT '{}',              -- {date_from, date_to, style, count_up?, before_after?}
    result_url TEXT,                                 -- presigned MP4 URL (null until done)
    storage_key TEXT,                                -- S3 key for re-presign / cleanup
    error TEXT,                                      -- error message when status='error'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_slideshow_jobs_user_id ON slideshow_jobs(user_id);
CREATE INDEX IF NOT EXISTS idx_slideshow_jobs_status ON slideshow_jobs(status);
CREATE INDEX IF NOT EXISTS idx_slideshow_jobs_pending
    ON slideshow_jobs(status, created_at) WHERE status IN ('pending', 'processing');

ALTER TABLE slideshow_jobs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own slideshow jobs"
    ON slideshow_jobs FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Service role can manage all slideshow jobs"
    ON slideshow_jobs FOR ALL
    USING (auth.role() = 'service_role');
