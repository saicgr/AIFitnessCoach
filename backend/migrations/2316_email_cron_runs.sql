-- 2316_email_cron_runs.sql
--
-- Single-writer election for the hourly email cron.
--
-- The global per-user frequency cap (2 lifecycle emails/day, 4/rolling-week) is
-- enforced in services/email_sender.py with an in-process reservation ledger.
-- That ledger is exact within ONE cron run. If two runs overlap — a Render
-- retry, >1 gunicorn worker, or a manual curl racing the scheduled tick — each
-- holds its own ledger and each grants the same user a full 2/day budget, so a
-- user can receive up to 4.
--
-- api/v1/email_cron.py::_claim_cron_hour elects one writer per UTC hour by
-- inserting the hour bucket as a primary key. A PK insert is atomic in Postgres,
-- so exactly one caller wins. Without this table the insert errors (PGRST205,
-- schema cache miss), _claim_cron_hour fails OPEN — a broken lock table must
-- never mute all email — and the election silently degrades to a no-op.
--
-- Idempotent: safe to re-run.

CREATE TABLE IF NOT EXISTS email_cron_runs (
    -- The UTC hour being claimed, e.g. '2026-07-13T14'. PK = the election.
    hour_bucket   TEXT        PRIMARY KEY,
    instance_id   TEXT        NOT NULL DEFAULT 'local',
    started_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- NULL while the run is in flight. _claim_cron_hour reclaims a bucket whose
    -- holder started >30min ago and never finished (crashed mid-run).
    finished_at   TIMESTAMPTZ
);

-- _claim_cron_hour's stale-holder sweep filters on finished_at IS NULL and reads
-- started_at; keep that lookup off a seq scan as the table accumulates hours.
CREATE INDEX IF NOT EXISTS idx_email_cron_runs_unfinished
    ON email_cron_runs (started_at)
    WHERE finished_at IS NULL;

COMMENT ON TABLE email_cron_runs IS
    'One row per claimed UTC hour of the email cron. PK insert = single-writer '
    'election, so overlapping runs cannot each grant a user a full frequency-cap '
    'budget. See api/v1/email_cron.py::_claim_cron_hour.';
