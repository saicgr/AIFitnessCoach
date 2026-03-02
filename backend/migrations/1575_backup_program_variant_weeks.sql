-- Backup current program_variant_weeks before fixing workout data
CREATE TABLE IF NOT EXISTS program_variant_weeks_copy AS
SELECT * FROM program_variant_weeks;

-- Verify the copy
DO $$
DECLARE
    original_count INTEGER;
    copy_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO original_count FROM program_variant_weeks;
    SELECT COUNT(*) INTO copy_count FROM program_variant_weeks_copy;
    IF original_count != copy_count THEN
        RAISE EXCEPTION 'Backup verification failed: original=%, copy=%', original_count, copy_count;
    END IF;
    RAISE NOTICE 'Backup complete: % rows copied', copy_count;
END $$;
