-- Migration: Backfill exercise_library.gif_url from image_s3_path (finding #221)
--
-- gif_url is NULL on all 2,450 rows even though image_s3_path is populated
-- for every one of them. Several client/server surfaces read gif_url
-- directly (bypassing the static_url()/resolve_image_url() resolution used
-- by /exercise-images), so those surfaces render a generic placeholder for
-- media that genuinely exists in S3.
--
-- Only backfills rows under the public `ILLUSTRATIONS ALL/` prefix, matching
-- the bucket policy in backend/scripts/setup_s3_public_assets.py and the
-- `_STATIC_PREFIXES` allowlist in api/v1/library/utils.py — the same prefix
-- static_url() already serves as a permanent, non-expiring URL for. Percent-
-- encodes the one character actually present in this catalog's filenames
-- (space -> %20, matching urllib.parse.quote's default encoding); a handful
-- of possible future filenames with other reserved characters would need
-- static_url()'s real quote() call, not this migration, to resolve correctly.
--
-- No cache-busting query param is included (static_url() adds one derived
-- from the S3 key) — harmless for a first backfill of an all-NULL column,
-- since there is no stale CDN edge cache to bust yet.

UPDATE exercise_library
SET gif_url = 'https://ai-fitness-coach.s3.us-east-1.amazonaws.com/' ||
    replace(
        replace(image_s3_path, 's3://ai-fitness-coach/', ''),
        ' ', '%20'
    )
WHERE gif_url IS NULL
  AND image_s3_path LIKE 's3://ai-fitness-coach/ILLUSTRATIONS ALL/%';

-- VERIFY: select count(*) from exercise_library where image_s3_path like 's3://ai-fitness-coach/ILLUSTRATIONS ALL/%' and gif_url is null; -- expect 0
