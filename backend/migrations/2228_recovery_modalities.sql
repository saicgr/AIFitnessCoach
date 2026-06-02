-- Migration 2228: Recovery-modality logging (Gap 8)
-- Cold plunge / ice bath / contrast therapy / massage — the recovery practices
-- the Google-Health review centered (a 3-min ice plunge). Sauna already had its
-- own table (sauna_logs); this is the generic sibling for the rest, so the coach
-- can credit recovery work and ease next-day load. Mirrors the sauna_logs DDL.

CREATE TABLE IF NOT EXISTS recovery_modality_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    -- 'cold_plunge' | 'ice_bath' | 'contrast' | 'massage' | 'foam_rolling' |
    -- 'compression' | 'stretching' | 'other'. Open vocab (no DB enum) so new
    -- modalities never need a migration — the API validates the known set.
    modality TEXT NOT NULL,
    duration_minutes INT CHECK (duration_minutes IS NULL OR (duration_minutes > 0 AND duration_minutes <= 240)),
    -- Optional water/room temperature in Celsius (cold plunge / sauna-contrast).
    temperature_c NUMERIC(5, 1) CHECK (temperature_c IS NULL OR (temperature_c BETWEEN -10 AND 120)),
    notes TEXT,
    logged_at TIMESTAMPTZ DEFAULT NOW(),
    local_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_recovery_modality_logs_user_date
    ON recovery_modality_logs (user_id, local_date);

ALTER TABLE recovery_modality_logs ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'recovery_modality_logs' AND policyname = 'Users can view own recovery modality logs') THEN
        CREATE POLICY "Users can view own recovery modality logs" ON recovery_modality_logs
            FOR SELECT USING (auth.uid() = user_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'recovery_modality_logs' AND policyname = 'Users can insert own recovery modality logs') THEN
        CREATE POLICY "Users can insert own recovery modality logs" ON recovery_modality_logs
            FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'recovery_modality_logs' AND policyname = 'Users can delete own recovery modality logs') THEN
        CREATE POLICY "Users can delete own recovery modality logs" ON recovery_modality_logs
            FOR DELETE USING (auth.uid() = user_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'recovery_modality_logs' AND policyname = 'Service role full access recovery modality logs') THEN
        CREATE POLICY "Service role full access recovery modality logs" ON recovery_modality_logs
            FOR ALL USING (current_setting('role') = 'service_role');
    END IF;
END $$;
