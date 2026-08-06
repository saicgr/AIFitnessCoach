-- Row 104 (2026-08 backend prompt sweep): the "Gentle Start" program's
-- featured-carousel chip and Preview stat tile both read "20 MIN", directly
-- contradicting the program's own tagline ("Eight minutes counts.") and every
-- week's focus line ("Building consistency through 8-minute movement
-- blocks"). All of these are authored copy that AGREE with each other; only
-- `programs.session_duration_minutes` disagrees.
--
-- Verified against the actual generated content, not just the copy: every
-- session in every one of this program's 46 variants (week 1, all
-- duration/frequency/difficulty combinations) carries
-- `workouts[].duration_minutes = 8` — the stat tile's "20 MIN" was simply
-- wrong at authoring time (scripts/build_program_catalog.py hardcodes
-- session_duration_minutes as a design-time target that the generator's
-- output never matched for this program). A catalog-wide check of all 49
-- published programs found this is an isolated mismatch, not systemic — no
-- other program's stated duration disagrees with its actual session content
-- by more than a few minutes.
--
-- This corrects the STRUCTURED FIELD to match the copy + the real data,
-- rather than rewriting the (already-correct) tagline/focus strings.

UPDATE programs
SET session_duration_minutes = 8
WHERE id = 'c78eb6d8-fed0-4a24-93e6-19f424ac60eb'  -- "Gentle Start"
  AND session_duration_minutes = 20;
