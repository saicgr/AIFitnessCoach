-- Add audio + photo note media columns to the set-performance table.
--
-- The mobile app's `EnhancedNotesSheet` captures three things: text notes,
-- an optional audio recording, and zero-or-more photo attachments. Text was
-- already persisted via the `notes` column. Audio + photo were being
-- silently dropped. These columns hold the canonical S3 URLs the client
-- uploads media to before logging the set.
--
-- Back-compat: both columns are NULLABLE. Existing rows get NULL/ empty;
-- the client reads those as "no media" via its JSON fromJson (which already
-- defaults notesAudioPath to null and notesPhotoPaths to const []).

ALTER TABLE set_performances
    ADD COLUMN IF NOT EXISTS notes_audio_url TEXT,
    ADD COLUMN IF NOT EXISTS notes_photo_urls TEXT[];

COMMENT ON COLUMN set_performances.notes_audio_url IS
    'Optional voice-note recording attached to this set. S3 URL.';
COMMENT ON COLUMN set_performances.notes_photo_urls IS
    'Optional photo attachments (0..N) for this set. S3 URLs.';
