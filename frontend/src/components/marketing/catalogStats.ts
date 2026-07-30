/**
 * Single source of truth for the catalog numbers quoted in marketing copy.
 *
 * WHY THIS FILE EXISTS (E2E register #44)
 * ---------------------------------------
 * The exercise-library size was hardcoded independently on ~a dozen surfaces and
 * had drifted into two mutually contradictory claims — "1,700+" on one screen
 * and "1,722" on the adjacent one, immediately before the paywall. Every surface
 * must import from here so there is exactly one number to change.
 *
 * COUNT FROM THE VIEW THE PRODUCT SERVES, NOT THE RAW TABLE
 * ---------------------------------------------------------
 * The app never reads `exercise_library` directly. Every library surface
 * (`backend/api/v1/library/exercises.py` — list, detail, filter options, body
 * parts, exercise types) reads the materialized view `exercise_library_cleaned`,
 * which:
 *   - unions `exercise_library` + `exercise_library_manual`,
 *   - collapses the `_Female` / `_Male` media-variant rows into ONE movement
 *     (preferring, by design, whichever variant carries media), and
 *   - drops rows whose `body_part` or `target_muscle` is null.
 * So the MV row count IS the user-visible catalog. Counting the raw table
 * instead overstates it — and badly overstates VIDEO coverage, because a raw
 * row can carry a video and still be dropped by the MV.
 *
 * PROVENANCE — regenerate with (backend/.venv, DATABASE_URL from backend/.env):
 *
 *   -- user-visible movements
 *   select count(*) from exercise_library_cleaned;
 *
 *   -- ...of those, how many carry a video asset
 *   select count(*) from exercise_library_cleaned
 *    where video_url is not null and video_url <> '';
 *
 * Measured 2026-07-29 against production (project hpbzfahijszqmgsybuor):
 * 2,378 user-visible exercises, 1,862 of them (78.3%) with a video. A 25-item
 * random sample of those video URLs was `head_object`-ed against S3 and every
 * one resolved, so "with video demos" is not a merely-non-null claim
 * (see CLAUDE.md: "media must EXIST on S3, not just be non-null").
 *
 * The two numbers are DIFFERENT claims and must never be conflated: the catalog
 * is 2,300+; the video-backed subset is 1,800+. "2,300+ exercises with video
 * demos" would be false by ~500.
 */

/** User-visible movements in the library (rows in `exercise_library_cleaned`). */
export const EXERCISE_COUNT_EXACT = 2378;

/** Of those, how many ship a video demo. */
export const EXERCISE_COUNT_WITH_VIDEO = 1862;

/**
 * The ONLY string marketing copy should render for the library size.
 *
 * A rounded-down floor with a "+" rather than the exact figure on purpose: the
 * catalog grows, and an exact number silently becomes a lie between releases,
 * which is how "1,722" and "1,700+" ended up on adjacent screens in the first
 * place. It is a floor, so it can only ever understate.
 */
export const EXERCISE_COUNT_LABEL = '2,300+';

/** Floor for the video-backed subset. Strictly smaller than the catalog. */
export const EXERCISE_VIDEO_COUNT_LABEL = '1,800+';

/** "1,800+ exercises with video demos" — the full claim, one place. */
export const EXERCISE_LIBRARY_CLAIM = `${EXERCISE_VIDEO_COUNT_LABEL} exercises with video demos`;
