-- Migration 2407 — Plain-language instructions for "Treadmill Incline Jog"
-- ----------------------------------------------------------------------------
-- Row 170 (2026-08 backend prompt sweep), second evidence bullet (the first
-- — Hip/Shoulder/Ankle CARs — was fixed by migration 2405): "Treadmill
-- Incline Jog" instruction copy used exercise-science jargon ("recruits the
-- posterior chain (glutes, hamstrings, calves) maximally", "shifts stress to
-- the knee and reduces efficiency") a normal user has to decode.
--
-- Same root cause as 2405: this row lives in `exercise_library_manual`
-- (id 6669527f-5f45-425a-936f-cdffff4d3971), the sibling table unioned into
-- `exercise_library_cleaned` (the MV the Library tab and GET /exercises/{id}
-- actually serve) that migrations 2084/2085 never touched. `exercise_library`
-- (the base table) has no "Treadmill Incline Jog" row — verified via
-- `ilike exercise_name '%treadmill%incline%'`, which only returns "Treadmill
-- Jogging" (already plain, migrations 2084/2085 covered it) in the base
-- table; the jargon-heavy "Treadmill Incline Jog" / "Treadmill Incline Walk"
-- / "Treadmill Steep Incline Walk" rows only exist in _manual.
--
-- Deterministic hand rewrite, no LLM, technique-correct, still exercise-
-- specific (not a shared template).
--
-- After applying: `SELECT refresh_exercise_library_cleaned();` (same MV
-- refresh migration 2405 requires) so the live response picks up the text.
--
-- Idempotent: keyed by id, unconditional UPDATE (safe to re-run).

UPDATE exercise_library_manual
SET instructions = '1. Set the treadmill incline to 4-8% and speed to 4.5-5.5 mph. Step on with an upright posture, leaning forward slightly from the ankles (not bending at the hips or waist) to match the slope.
2. Take 2-3 steps to settle into a steady breathing rhythm before you commit to the pace.
3. Breathe out every 2-3 steps. Shorten your stride compared to jogging on flat ground — reaching too far forward on an incline puts extra stress on your knees and wastes energy.
4. Drive your knees forward and up with each step, and push off the balls of your feet without letting your heels slam down. This works your glutes, hamstrings, and calves hard.
5. Keep your arms relaxed and slightly bent, swinging front to back (not across your body), with your shoulders down away from your ears.
6. Start with 3 minutes and add 1 minute per session, working up to 10 minutes. If your form starts to break down, slow down or lower the incline rather than gripping the handrails.'
WHERE id = '6669527f-5f45-425a-936f-cdffff4d3971';  -- Treadmill Incline Jog
