-- Migration 2405 — Plain-language instructions for the CARs mobility drills
-- ----------------------------------------------------------------------------
-- Row 170 (2026-08 backend prompt sweep): "Hip CARs" / "Shoulder CARs" /
-- "Ankle CARs" (Library -> exercise detail) show instruction copy no ordinary
-- user can parse — "create an irradiation brace that anchors the pelvis",
-- "maximum articular excursion", "neuromuscular control and synovial fluid
-- distribution", "distal tension" — plus the exercise-name abbreviation
-- "CARs" (Controlled Articular Rotations) is never expanded anywhere.
--
-- Root cause: `exercise_library_cleaned` (the MV the Library tab and the
-- /exercises/{id} detail endpoint actually serve, api/v1/library/exercises.py)
-- UNIONs `exercise_library` with `exercise_library_manual`. Migrations
-- 2084/2085 (the instruction-quality rewrite CLAUDE.md documents) only
-- touched the base `exercise_library` table — `exercise_library_manual`
-- (786 rows, unioned into the same MV, same public.exercise_library_cleaned
-- surface) was never covered, so its jargon-heavy hand-authored instructions
-- shipped untouched. These 3 rows were confirmed live via the DB (searched
-- exercise_library first per CLAUDE.md's exercise-name-drift warnings —
-- zero hits; found only in exercise_library_manual) — not a Flutter string.
--
-- Fix: rewrite these 3 rows' `instructions` in plain language, technique-
-- correct, still exercise-specific (not a shared template), and expand CARs
-- on first use so the acronym is never unexplained. Deterministic hand
-- authoring, no LLM. `exercise_library` (base table, already covered by
-- 2084/2085) has no "CARs" rows to touch — verified via
-- `ilike exercise_name '%CAR%'` returning only the "Carry" family.
--
-- After applying: `SELECT refresh_exercise_library_cleaned();` so the MV
-- (and the live /exercises/{id} response) picks up the new text — see
-- migration 2038's refresh hook. No MV refresh = stale instructions keep
-- serving until the next scheduled refresh.
--
-- Idempotent: keyed by id, unconditional UPDATE (safe to re-run).

UPDATE exercise_library_manual
SET instructions = '1. Stand on one leg (or sit in a chair with one foot off the floor). CARs stands for Controlled Articular Rotations — you''re moving the ankle joint through its full range of motion, slowly and under control.
2. Point your toes down, then roll them outward, then pull your toes up toward your shin, then roll them inward — tracing the largest circle you can with your big toe.
3. Move slowly through the whole circle. If you hit a spot that feels tight or stuck, pause there for a breath before continuing.
4. Do 5-10 slow circles one way, then reverse and do 5-10 circles the other way.
5. Switch to the other ankle and repeat.'
WHERE id = '07f0600b-5285-4925-b335-3d13c1b145f5';  -- Ankle CARs

UPDATE exercise_library_manual
SET instructions = '1. Stand tall with feet hip-width apart, one arm relaxed at your side. Keep your torso still — the movement should come only from the shoulder. CARs stands for Controlled Articular Rotations — you''re moving the shoulder through its full range of motion, slowly and under control.
2. Raise the arm forward and up overhead, taking 3-4 seconds to get there.
3. Keep circling the arm back and down behind you, then sweep it back to the starting position — that''s one full slow circle.
4. Do 5 slow circles in each direction, then switch arms.
5. If any point in the circle feels tight or stuck, pause there for a couple seconds before continuing. Keep your ribs and lower back still the whole time — don''t lean or twist to help the arm move further.'
WHERE id = '18b86417-1446-4224-9d50-68a226e4201b';  -- Shoulder CARs

UPDATE exercise_library_manual
SET instructions = '1. Stand on one leg next to a wall, holding on lightly with your fingertips for balance. Brace your core and squeeze the glute of your standing leg so your hips and lower back stay still. CARs stands for Controlled Articular Rotations — you''re moving the hip joint through its full range of motion, slowly and under control.
2. Lift your other knee to hip height in front of you, then rotate the hip outward, swinging the knee out to the side while keeping your hips facing forward.
3. Continue the circle — take the leg out to the side and then behind you. Keep your hips still throughout; the motion should come from the hip joint, not from twisting your lower back.
4. Swing the leg back around to the front to complete the circle. Do 3-5 slow circles, then reverse direction for 3-5 more.
5. Switch legs and repeat. Move slowly — about 8-10 seconds per circle — so you can feel and control the whole range of motion.'
WHERE id = 'a39b6ec1-84b4-489f-8f1a-49c964c478d9';  -- Hip CARs
