-- ============================================================================
-- Migration 2284 — Program Library Curation
-- ----------------------------------------------------------------------------
-- Curates a clean, high-quality PUBLISHED launch set of 18 programs for the
-- Zealova Program Library browse experience. All ~261 existing rows are kept;
-- only the curated set is flipped to is_published=true and given rich editorial
-- copy (editorial_name, tagline, who_for, who_not_for, equipment_summary,
-- progression_note) plus a strong description where the existing one was thin.
--
-- Steps:
--   1. Publish + enrich 13 EXISTING rows (mapped by stable id).
--   2. Author 5 GAP programs with full workouts JSONB:
--        - 7-Minute Upper Body (Quick Hits)
--        - 7-Minute Lower Body (Quick Hits)
--        - 30-Day Plank Challenge (Quick Hits / Core)
--        - HYROX Pro — Elite Race Build (populate empty row 6348ee98…)
--        - Anabolic Foundations — Free-Weight Mass (Men's Health #2)
--   3. Category taxonomy normalized inline via program_category on published rows.
--
-- Design provenance (evidence-based, no medical/efficacy claims):
--   * 7-min circuits: Klika & Jordan HICT protocol, ACSM Health & Fitness Journal
--     2013 (30s work / 10s transition, total-body → lower → upper → core order).
--   * 30-day plank: U.S. Navy Warfighter Wellness progression + ≤20%/week ramp,
--     rest every 4th day to avoid the "day-8 cliff".
--   * HYROX Pro: PureGym / TrainingPeaks advanced 12-week — 5-6 days/wk, double
--     stations, compromised running after strength work, race-sim taper.
--   * Free-weight mass / "hormonal response" framing: 6-12 reps @ 67-85% 1RM,
--     compound free weights, short-to-moderate rest — framed strictly as an
--     ASSOCIATED training response, never a guaranteed/medical testosterone claim
--     (per _ZEALOVA_FACTS.md §5).
--
-- IDEMPOTENT: all Step-1 UPDATEs are keyed by id (re-running is a no-op set);
-- all Step-2 authored rows use INSERT ... WHERE NOT EXISTS or UPDATE-by-id.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- STEP 1 — Publish + enrich 13 existing rows
-- ----------------------------------------------------------------------------

-- 1) HYROX Race Prep (8-Week) — Featured HYROX
UPDATE programs SET
  is_published = true,
  program_category = 'HYROX & Race Prep',
  editorial_name = 'HYROX Race Prep',
  tagline = 'Eight weeks to your first HYROX finish line',
  description = 'An 8-week HYROX build that trains the two things the race actually tests: the running and the eight functional stations that interrupt it. You progress from running intervals and isolated station practice into compromised running — stations performed on tired legs — before a full race simulation in the taper. By race week you''ve rehearsed SkiErg, sled push and pull, burpee broad jumps, rowing, farmers carry, sandbag lunges, and wall balls in order, at pace.',
  who_for = 'First-time and returning HYROX athletes who can already run 5K and want a structured 8-week ramp to race day.',
  who_not_for = 'Complete beginners to running or strength training, or anyone with less than 8 weeks before their event — start with general conditioning first.',
  equipment_summary = 'HYROX or functional gym: SkiErg, rower, sled, wall ball, sandbag, kettlebells, and running space (treadmill or track).',
  progression_note = 'Weekly progression in running volume and station load; compromised-running density rises through weeks 5-6, then tapers into a full simulation before race day.',
  featured_rank = 1
WHERE id = '28509af5-3ae9-4f3b-a4ad-bbf840798a64';

-- 2) HYROX Full Simulation — Featured HYROX (benchmark)
UPDATE programs SET
  is_published = true,
  program_category = 'HYROX & Race Prep',
  editorial_name = 'HYROX Full Simulation',
  tagline = 'The complete 8-station race, start to finish',
  description = 'The full HYROX race simulation: eight 1 km runs interleaved with the eight functional stations in official order — SkiErg, Sled Push, Sled Pull, Burpee Broad Jumps, Row, Farmers Carry, Sandbag Lunges, and Wall Balls. Run it as a benchmark before race day to test your pacing, transitions, and where you actually fade. Record your split; repeat it a few weeks later to measure progress.',
  who_for = 'HYROX athletes inside the final few weeks of prep who want an honest, full-distance dress rehearsal.',
  who_not_for = 'Beginners or anyone not yet conditioned for an hour-plus of continuous running and functional work — build base fitness first.',
  equipment_summary = 'Full HYROX station setup: SkiErg, sled, rower, wall ball, sandbag, kettlebells, and 8×1 km of running.',
  progression_note = 'Not a progressive block — a repeatable benchmark. Re-test every 3-4 weeks and chase a faster total time and cleaner transitions.',
  featured_rank = 2
WHERE id = '73d9ec23-5845-498f-8015-e961e141cec5';

-- 3) Men's Testosterone Boosting Workout -> Iron Surge (honest hormonal-response framing)
UPDATE programs SET
  is_published = true,
  program_category = 'Men''s Health',
  program_subcategory = 'Strength',
  editorial_name = 'Iron Surge — Heavy Compound Strength',
  tagline = 'Heavy barbell training, built around big lifts',
  description = 'A heavy, free-weight strength block built on the four big compound patterns — squat, deadlift, press, and pull. You train in the 5-10 rep range at roughly 75-90% of your one-rep max with short, focused rest and sessions kept under about 45 minutes. This style of training — heavy loads, large muscle mass, multi-joint movements — is the kind associated with a strong acute hormonal and neuromuscular training response. (This is training programming, not a medical or supplement protocol, and makes no promise to raise your testosterone.)',
  who_for = 'Men with some lifting experience who want a no-frills, barbell-centric strength block and respond well to heavy compound work.',
  who_not_for = 'Absolute beginners (start with a linear novice program), or anyone seeking a medical solution to low testosterone — that is a conversation for a doctor, not a workout.',
  equipment_summary = 'Barbell, plates, squat rack, and a bench. A pull-up bar or row station for the pulling work.',
  progression_note = 'Add small amounts of load each week while staying in the 5-10 rep window; keep rest short enough to keep sessions dense and under ~45 minutes.'
WHERE id = 'd98a7ddc-d55b-4b42-939f-e80f75d4e44e';

-- 4) Men's Starting Strength Program -> Starting Strength Foundations
UPDATE programs SET
  is_published = true,
  program_category = 'Strength & Muscle',
  editorial_name = 'Starting Strength Foundations',
  tagline = 'Add weight to the bar, every session',
  description = 'A classic novice linear-progression program built on a handful of barbell compound lifts performed three days a week. Because a true beginner recovers fast, you add a small amount of weight to the bar nearly every session — the simplest, most reliable way to get strong quickly. Three movements per day, full-body, with enough rest between heavy sets to actually lift heavy.',
  who_for = 'Brand-new and early lifters who want to build a real strength base on the squat, press, deadlift, and bench with the fastest proven progression.',
  who_not_for = 'Intermediate or advanced lifters who have stalled on linear progression — you''ve outgrown this and need periodization.',
  equipment_summary = 'Barbell, plates, squat rack, and a flat bench.',
  progression_note = 'Linear: add roughly 2.5-5 lb to upper-body lifts and 5-10 lb to lower-body lifts each session for as long as you keep recovering. Deload when a lift stalls twice.'
WHERE id = '5886bf32-6ee9-4c17-aa5b-f733bfba3aca';

-- 5) Women's Full Body Strength -> Strong & Steady (Women's Health #1)
UPDATE programs SET
  is_published = true,
  program_category = 'Women''s Health',
  editorial_name = 'Strong & Steady — Women''s Full-Body Strength',
  tagline = 'Build real strength, not just tone',
  description = 'A full-body strength program that trains every major movement pattern — squat, hinge, push, pull, and carry — across four focused sessions a week. The emphasis is on getting genuinely stronger with progressive load, which is what actually changes how you look and move, rather than endless light "toning" circuits. Balanced volume for legs, glutes, back, and shoulders, with core work woven throughout.',
  who_for = 'Women who want to lift with intent and build full-body strength, whether new to the weight room or returning after time off.',
  who_not_for = 'Anyone who is pregnant or early postpartum (see Postpartum Rebuild first), or who wants a pure cardio/fat-loss circuit with no barbell work.',
  equipment_summary = 'Barbell and/or dumbbells, a bench, and a cable or band for accessories. Adaptable to a home dumbbell setup.',
  progression_note = 'Progress load before reps: when you hit the top of the rep range with good form on all sets, add weight. Rotate accessory work every 4-6 weeks to keep adapting.'
WHERE id = '76ff820c-163c-44d5-9c9e-f84e7da311d4';

-- 6) Postpartum Rebuild -> Postpartum Rebuild (Women's Health #2)
UPDATE programs SET
  is_published = true,
  program_category = 'Women''s Health',
  editorial_name = 'Postpartum Rebuild',
  tagline = 'Rebuild from the core out, gently',
  description = 'A gentle, progressive return-to-training program for the postpartum body, rebuilding from the inside out — deep core and pelvic-floor connection first, then whole-body strength layered on as you reconnect. Short, manageable sessions that fit around a newborn, prioritizing breathing mechanics, alignment, and gradual load over intensity. Always begin only after you have clearance from your healthcare provider.',
  who_for = 'People in the weeks and months after childbirth who have been cleared to exercise and want a safe, structured way back to strength.',
  who_not_for = 'Anyone not yet cleared by their doctor or midwife, or experiencing pain, heavy bleeding, or symptoms of pelvic-floor dysfunction — see your provider first.',
  equipment_summary = 'Mostly bodyweight, with light dumbbells or a resistance band added as you progress. A mat is helpful.',
  progression_note = 'Progress by control and symptom-free movement, not load: master breathing and core connection before adding weight, and never push into doming, leaking, or pain.'
WHERE id = '718331e4-0c06-4538-bded-63362031cdb9';

-- 7) Men's Beach Body Summer Prep -> Beach Body Ready (Aesthetic, featured)
UPDATE programs SET
  is_published = true,
  program_category = 'Aesthetic',
  editorial_name = 'Beach Body Ready',
  tagline = 'Lean out, build shape, look the part',
  description = 'A 12-week aesthetic program that pairs resistance training for muscle shape with enough conditioning to lean out — the classic recipe for looking good with your shirt off. Five sessions a week emphasize the visual muscles (shoulders, chest, back, arms, and abs) with progressive load, while built-in conditioning finishers and a higher training density help reveal definition. Pair it with a modest calorie deficit for best results.',
  who_for = 'People with some training experience who want a focused 12-week push to look leaner and more defined for summer or an event.',
  who_not_for = 'Total beginners (build a base first) or anyone chasing maximal strength or sport performance rather than appearance.',
  equipment_summary = 'Full gym preferred: barbell, dumbbells, cables, and machines. A conditioning option (rower, bike, or open space).',
  progression_note = 'Progressive overload on the main lifts week to week, with conditioning volume nudged up over the block. The visible change comes from the deficit — the training protects and shapes the muscle underneath.',
  featured_rank = 4
WHERE id = '52e8f552-52f0-47bb-9e6c-d6f13a4977d9';

-- 8) Fat Loss HIIT Beginner -> Lean Burn (Fat Loss)
UPDATE programs SET
  is_published = true,
  program_category = 'Fat Loss',
  editorial_name = 'Lean Burn — Fat-Loss Circuit',
  tagline = 'Short, sweaty sessions that fit a busy week',
  description = 'A beginner-friendly fat-loss program built around short, full-body interval circuits four days a week. Each 30-minute session mixes simple strength movements with bursts of conditioning to keep your heart rate up and burn calories without needing a gym full of equipment. Approachable work-to-rest ratios make it sustainable from day one, while still challenging enough to drive results when paired with sensible eating.',
  who_for = 'Beginners and returners who want efficient, equipment-light sessions for fat loss and conditioning that fit a tight schedule.',
  who_not_for = 'Anyone whose main goal is maximal strength or muscle size — pair this with, or graduate to, a dedicated strength program.',
  equipment_summary = 'Minimal: bodyweight plus a pair of light-to-moderate dumbbells. Works at home or in a gym.',
  progression_note = 'Progress by shortening rest, adding rounds, or nudging up dumbbell weight as the circuits get easier. Fat loss is driven primarily by your nutrition — the training accelerates it.'
WHERE id = 'ce4e2196-f35d-440c-a425-880e675699bd';

-- 9) Push Pull Legs Routine -> Push / Pull / Legs Hypertrophy (Muscle)
UPDATE programs SET
  is_published = true,
  program_category = 'Strength & Muscle',
  editorial_name = 'Push / Pull / Legs Hypertrophy',
  tagline = 'The proven 6-day split for serious size',
  description = 'The classic push/pull/legs split, run six days a week so every major muscle group is trained twice — the high-frequency, high-volume structure that intermediate lifters use to add real size. Push days hit chest, shoulders, and triceps; pull days build back and biceps; leg days cover quads, hamstrings, glutes, and calves. Each session balances heavy compound work with targeted accessory volume for complete development.',
  who_for = 'Intermediate lifters who can recover from training six days a week and want a structured, high-volume hypertrophy split.',
  who_not_for = 'Beginners (start with a full-body program) or anyone who can only train 2-3 days a week — the split needs the frequency to work.',
  equipment_summary = 'Full gym: barbell, dumbbells, cables, and machines for the accessory movements.',
  progression_note = 'Add weight or reps on the compound lifts each week and progress accessories by feel. Cycle in a lighter deload week roughly every 6-8 weeks to stay fresh.'
WHERE id = '8572438b-d394-4d01-bf4e-d9596e5cf7f4';

-- 10) Total Beginner Fitness -> Beginner Foundations (Beginner)
UPDATE programs SET
  is_published = true,
  program_category = 'Strength & Muscle',
  program_subcategory = 'Beginner',
  editorial_name = 'Beginner Foundations',
  tagline = 'Your first month, made completely doable',
  description = 'A genuinely gentle on-ramp for someone who has never trained before. Three short 20-minute sessions a week introduce the fundamental movement patterns with bodyweight and light resistance, building the habit and the base coordination you need before anything heavier. No jargon, no intimidating lifts — just a confident, repeatable first step into fitness.',
  who_for = 'Complete beginners who have never exercised regularly and want a low-pressure, time-efficient place to start.',
  who_not_for = 'Anyone already training consistently — you''ll progress faster on Starting Strength Foundations or a full-body program.',
  equipment_summary = 'Mostly bodyweight, with a pair of light dumbbells optional. A chair and a mat are all you really need.',
  progression_note = 'Progress by adding reps and improving control first; once the movements feel easy, graduate to Starting Strength Foundations or Strong & Steady.'
WHERE id = 'cc56fab8-c9d4-42f0-936a-ea6975c9d064';

-- 11) Morning Yoga Flow -> Daily Flow (Yoga & Mobility)
UPDATE programs SET
  is_published = true,
  program_category = 'Yoga & Mobility',
  editorial_name = 'Daily Flow — Yoga for Lifters',
  tagline = 'Twenty minutes to move and breathe better',
  description = 'A short daily yoga flow built to complement strength training — mobility for the hips, spine, shoulders, and hamstrings that tend to get tight from lifting and sitting. Twenty energizing minutes, five days a week, that improve flexibility, restore range of motion, and give your nervous system a calm reset. No experience required; every pose scales to your level.',
  who_for = 'Lifters and desk-bound people who want better mobility, easier movement, and a daily reset without a long time commitment.',
  who_not_for = 'Anyone seeking an advanced, athletic vinyasa or a strength stimulus — this is mobility and recovery, not a workout replacement.',
  equipment_summary = 'A yoga mat. Optional: a block and a strap to make poses more accessible.',
  progression_note = 'Progress by depth and breath control rather than load: ease a little further into each shape over the weeks, and add a second daily round once 20 minutes feels easy.'
WHERE id = '3132f0e1-c235-48da-ba78-52e4b9704442';

-- 12) Hypertrophy Focus 4-Day Split  (extra strong candidate — Strength & Muscle)
UPDATE programs SET
  is_published = true,
  program_category = 'Strength & Muscle',
  editorial_name = 'Hypertrophy 4-Day Split',
  tagline = 'Four focused days, maximum muscle',
  description = 'A four-day body-part split engineered purely for muscle growth: chest and triceps, back and biceps, shoulders and traps, and a dedicated leg day. The moderate-rep, moderate-load structure (mostly 8-15 reps) with controlled rest sits squarely in the hypertrophy sweet spot, and four days a week is enough volume to grow while still leaving room to recover. A great step up from full-body once you want more focus per muscle.',
  who_for = 'Intermediate lifters who want a dedicated muscle-building split and can train four days a week.',
  who_not_for = 'Beginners (start full-body) or anyone training fewer than four days — the volume is split across the week by design.',
  equipment_summary = 'Full gym: barbell, dumbbells, cables, and machines.',
  progression_note = 'Drive progressive overload within the 8-15 rep ranges, adding load when you top out a range. Deload roughly every 6-8 weeks.'
WHERE id = 'b0d8bc88-b9be-4c3c-87e9-18100c9f9f87';

-- 13) Home Workout No Equipment  (extra strong candidate — Quick Hits / at-home)
UPDATE programs SET
  is_published = true,
  program_category = 'Quick Hits',
  program_subcategory = 'Home / Bodyweight',
  editorial_name = 'No-Equipment Home Workout',
  tagline = 'Strong anywhere, zero equipment',
  description = 'A complete bodyweight program you can run in your living room — no gym, no equipment, no excuses. Four 30-minute sessions a week rotate through full-body activation, upper-body push, core, and lower-body work using nothing but your own bodyweight. Simple, scalable movements make it work whether you''re a beginner or just stuck without a gym, while progressive reps keep it challenging.',
  who_for = 'Anyone training at home, traveling, or starting out who wants a structured full-body plan with zero equipment.',
  who_not_for = 'Lifters chasing maximal strength or heavy hypertrophy — bodyweight alone will eventually cap your loading.',
  equipment_summary = 'None required. A mat adds comfort for floor work.',
  progression_note = 'Progress by adding reps, slowing tempo, or moving to harder variations (e.g. decline or archer push-ups) as the standard versions get easy.'
WHERE id = 'a616a82c-d9be-4b71-a7ef-7b291ec47107';

-- ----------------------------------------------------------------------------
-- STEP 2 — Author the GAPS (full workouts JSONB), is_published = true
-- ----------------------------------------------------------------------------

-- 2.4) HYROX Pro — Elite Race Build: populate the EMPTY row 6348ee98… in place
UPDATE programs SET
  program_name = 'HYROX Pro — Elite Race Build',
  program_category = 'HYROX & Race Prep',
  program_subcategory = 'HYROX',
  difficulty_level = 'Advanced',
  duration_weeks = 12,
  sessions_per_week = 6,
  session_duration_minutes = 75,
  is_published = true,
  has_workouts = true,
  featured_rank = 3,
  goals = ARRAY['Endurance','Athletic Performance','Conditioning'],
  tags = ARRAY['hyrox','race-prep','hybrid','advanced','conditioning'],
  short_description = 'High-volume 12-week elite HYROX build.',
  editorial_name = 'HYROX Pro — Elite Race Build',
  tagline = 'Twelve weeks to a podium-chasing race',
  description = 'A high-volume, 12-week HYROX build for athletes targeting a competitive time. Six days a week of running, strength, and hybrid conditioning, with double-station sessions, longer compromised runs, and threshold work that the 8-week plan doesn''t have room for. The block ramps station volume and running density through the middle weeks, then sharpens into race-pace simulations before a structured taper. This is the deep-end build — bring real base fitness.',
  who_for = 'Experienced HYROX athletes who can already finish a race and want a high-volume 12-week build to chase a faster, competitive time.',
  who_not_for = 'First-timers or anyone who can''t yet train six days a week — start with the 8-week HYROX Race Prep instead.',
  equipment_summary = 'Full HYROX setup: SkiErg, rower, sled, wall ball, sandbag, kettlebells, plus a treadmill or track for threshold and compromised running.',
  progression_note = 'Volume and intensity climb through weeks 5-9 (double stations, longer compromised runs), peak with race-pace simulations, then taper hard in the final two weeks.',
  workouts = '{
    "program": "HYROX Pro — Elite Race Build",
    "category": "HYROX & Race Prep",
    "difficulty": "Advanced",
    "duration": "12 weeks",
    "session_duration": 75,
    "sessions_per_week": 6,
    "goals": ["Endurance", "Athletic Performance", "Conditioning"],
    "description": "A high-volume 12-week elite HYROX build: 6 days/week of running, strength, double-station work, compromised running, and race-pace simulation, tapering to race day.",
    "workouts": [
      {"day": 1, "type": "Running / Threshold", "workout_name": "Threshold Run Intervals", "exercises": [
        {"exercise_name": "Warm-up jog", "sets": 1, "reps": "12 minutes", "rest_seconds": 0, "notes": "Build to threshold effort"},
        {"exercise_name": "1 km threshold interval", "sets": 5, "reps": "1 km", "rest_seconds": 90, "notes": "At ~10K race pace, controlled"},
        {"exercise_name": "Cool-down jog", "sets": 1, "reps": "10 minutes", "rest_seconds": 0}
      ]},
      {"day": 2, "type": "Strength", "workout_name": "Lower Strength + Sled", "exercises": [
        {"exercise_name": "Back Squat", "sets": 5, "reps": "5", "rest_seconds": 150, "notes": "Heavy, ~80% 1RM"},
        {"exercise_name": "Romanian Deadlift", "sets": 4, "reps": "8", "rest_seconds": 120},
        {"exercise_name": "Sled Push", "sets": 6, "reps": "25 m", "rest_seconds": 90, "notes": "Heavy, race-weight or above"},
        {"exercise_name": "Sled Pull", "sets": 6, "reps": "25 m", "rest_seconds": 90},
        {"exercise_name": "Farmers Carry", "sets": 4, "reps": "50 m", "rest_seconds": 75, "notes": "Heavy kettlebells, no set-down"}
      ]},
      {"day": 3, "type": "Compromised Running", "workout_name": "Double-Station Compromised Run", "exercises": [
        {"exercise_name": "Warm-up jog", "sets": 1, "reps": "10 minutes", "rest_seconds": 0},
        {"exercise_name": "Run", "sets": 4, "reps": "1 km", "rest_seconds": 0, "notes": "At race pace, straight into the stations"},
        {"exercise_name": "Wall Ball", "sets": 4, "reps": "30", "rest_seconds": 0, "notes": "Immediately after each run"},
        {"exercise_name": "Burpee Broad Jump", "sets": 4, "reps": "15", "rest_seconds": 120, "notes": "Then rest before the next round"}
      ]},
      {"day": 4, "type": "Strength", "workout_name": "Upper Strength + Engines", "exercises": [
        {"exercise_name": "Overhead Press", "sets": 4, "reps": "6", "rest_seconds": 120},
        {"exercise_name": "Bent-Over barbell row", "sets": 4, "reps": "8", "rest_seconds": 120},
        {"exercise_name": "Pull-Up normal grip", "sets": 4, "reps": "8-10", "rest_seconds": 90},
        {"exercise_name": "Ski Ergometer Cross Country Ski Basic Pull", "sets": 5, "reps": "500 m", "rest_seconds": 75, "notes": "SkiErg, strong pace"},
        {"exercise_name": "Rowing", "sets": 5, "reps": "500 m", "rest_seconds": 75, "notes": "At race-pace split"}
      ]},
      {"day": 5, "type": "Long Compromised Run", "workout_name": "Long Run + Station Blocks", "exercises": [
        {"exercise_name": "Run", "sets": 1, "reps": "5 km", "rest_seconds": 0, "notes": "Steady aerobic, then stations"},
        {"exercise_name": "Sandbag Lunges", "sets": 3, "reps": "40 m", "rest_seconds": 60},
        {"exercise_name": "Farmers Carry", "sets": 3, "reps": "100 m", "rest_seconds": 60},
        {"exercise_name": "Run", "sets": 1, "reps": "3 km", "rest_seconds": 0, "notes": "Finish the long aerobic block"}
      ]},
      {"day": 6, "type": "Race Simulation", "workout_name": "Half-Race Pace Simulation", "exercises": [
        {"exercise_name": "Run", "sets": 4, "reps": "1 km", "rest_seconds": 0, "notes": "Race order, race pace"},
        {"exercise_name": "Ski Ergometer Cross Country Ski Basic Pull", "sets": 1, "reps": "1000 m", "rest_seconds": 0},
        {"exercise_name": "Sled Push", "sets": 1, "reps": "50 m", "rest_seconds": 0},
        {"exercise_name": "Sled Pull", "sets": 1, "reps": "50 m", "rest_seconds": 0},
        {"exercise_name": "Wall Ball", "sets": 1, "reps": "75", "rest_seconds": 0, "notes": "Hold race pace through the burn"}
      ]}
    ]
  }'::jsonb
WHERE id = '6348ee98-26a1-4eda-9957-e058de835def';

-- 2.1) 7-Minute Upper Body — Quick Hits
INSERT INTO programs (
  program_name, program_category, program_subcategory, difficulty_level,
  duration_weeks, sessions_per_week, session_duration_minutes,
  tags, goals, short_description, description, has_workouts, is_published,
  editorial_name, tagline, who_for, who_not_for, equipment_summary, progression_note,
  workouts
)
SELECT
  '7-Minute Upper Body', 'Quick Hits', 'Express', 'Beginner',
  2, 5, 7,
  ARRAY['quick','bodyweight','hict','upper-body','no-equipment'],
  ARRAY['Conditioning','Muscular Endurance','Time-Efficient'],
  'A 7-minute bodyweight upper-body circuit.',
  'A science-backed, 7-minute upper-body circuit you can do anywhere. Built on the high-intensity circuit-training (HICT) model — short, hard bursts of bodyweight work with brief transitions — it hits chest, shoulders, triceps, and core with no equipment at all. Do one round when you''re short on time, or repeat it 2-3 times for a fuller session. Perfect as a morning wake-up, a desk-break reset, or a finisher.',
  true, true,
  '7-Minute Upper Body', 'Push, press, plank — done in seven minutes',
  'Anyone who wants an equipment-free upper-body hit they can finish in the time it takes to make coffee — great for busy days and travel.',
  'Lifters chasing maximal strength or size — bodyweight intervals build endurance and conditioning, not heavy hypertrophy.',
  'None — pure bodyweight. A mat adds comfort for the floor work.',
  'Each move runs ~30 seconds hard with ~10 seconds to transition. Progress by adding a second or third round, slowing the tempo, or moving to harder push-up variations.',
  '{
    "program": "7-Minute Upper Body",
    "category": "Quick Hits",
    "difficulty": "Beginner",
    "duration": "2 weeks",
    "session_duration": 7,
    "sessions_per_week": 5,
    "goals": ["Conditioning", "Muscular Endurance", "Time-Efficient"],
    "description": "A 7-minute HICT-style bodyweight upper-body circuit: ~30s work, ~10s transition. One round is 7 minutes; repeat 2-3x for more.",
    "workouts": [
      {"day": 1, "type": "Circuit", "workout_name": "Upper-Body Express Circuit", "exercises": [
        {"exercise_name": "Push-Up", "sets": 1, "reps": "30 seconds", "rest_seconds": 10, "notes": "Drop to knees if needed; keep a straight line"},
        {"exercise_name": "Pike Push-Up", "sets": 1, "reps": "30 seconds", "rest_seconds": 10, "notes": "Hips high, press through the shoulders"},
        {"exercise_name": "Floor Tricep Dip", "sets": 1, "reps": "30 seconds", "rest_seconds": 10, "notes": "Use a chair or the floor; elbows back, not flared"},
        {"exercise_name": "High plank", "sets": 1, "reps": "30 seconds", "rest_seconds": 10, "notes": "Brace the core, neutral spine"},
        {"exercise_name": "plank shoulder taps", "sets": 1, "reps": "30 seconds", "rest_seconds": 10, "notes": "Minimize hip rock"},
        {"exercise_name": "Push-Up", "sets": 1, "reps": "30 seconds", "rest_seconds": 10, "notes": "Wide hand placement for chest emphasis"},
        {"exercise_name": "Plank Pushup", "sets": 1, "reps": "30 seconds", "rest_seconds": 10, "notes": "Up-up-down-down between elbows and hands"},
        {"exercise_name": "side plank", "sets": 1, "reps": "20 seconds per side", "rest_seconds": 10, "notes": "Stack the shoulders; switch halfway"},
        {"exercise_name": "Pike Push-Up", "sets": 1, "reps": "30 seconds", "rest_seconds": 10, "notes": "Slow and controlled for the finish"}
      ]}
    ]
  }'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM programs WHERE program_name = '7-Minute Upper Body');

-- 2.2) 7-Minute Lower Body — Quick Hits
INSERT INTO programs (
  program_name, program_category, program_subcategory, difficulty_level,
  duration_weeks, sessions_per_week, session_duration_minutes,
  tags, goals, short_description, description, has_workouts, is_published,
  editorial_name, tagline, who_for, who_not_for, equipment_summary, progression_note,
  workouts
)
SELECT
  '7-Minute Lower Body', 'Quick Hits', 'Express', 'Beginner',
  2, 5, 7,
  ARRAY['quick','bodyweight','hict','lower-body','no-equipment'],
  ARRAY['Conditioning','Muscular Endurance','Time-Efficient'],
  'A 7-minute bodyweight lower-body circuit.',
  'A fast, equipment-free lower-body circuit built on the high-intensity circuit-training (HICT) model. Seven minutes of squats, lunges, glute bridges, and wall sits drives the legs and glutes hard while keeping the heart rate up — no weights, no gym. Run it once for a quick hit, or loop it 2-3 times for a real leg burner. Ideal before work, between meetings, or on the road.',
  true, true,
  '7-Minute Lower Body', 'Squat, lunge, bridge — seven minutes flat',
  'Anyone who wants a quick, no-equipment way to train legs and glutes — busy professionals, travelers, and beginners building a habit.',
  'Lifters seeking maximal leg strength or size — bodyweight intervals build endurance, not a heavy strength stimulus.',
  'None — pure bodyweight. A wall is handy for the wall sit.',
  'Each move runs ~30 seconds hard with ~10 seconds to transition. Progress by adding rounds, pausing at the bottom of each squat/lunge, or moving to single-leg variations.',
  '{
    "program": "7-Minute Lower Body",
    "category": "Quick Hits",
    "difficulty": "Beginner",
    "duration": "2 weeks",
    "session_duration": 7,
    "sessions_per_week": 5,
    "goals": ["Conditioning", "Muscular Endurance", "Time-Efficient"],
    "description": "A 7-minute HICT-style bodyweight lower-body circuit: ~30s work, ~10s transition. One round is 7 minutes; repeat 2-3x for more.",
    "workouts": [
      {"day": 1, "type": "Circuit", "workout_name": "Lower-Body Express Circuit", "exercises": [
        {"exercise_name": "Air Squat", "sets": 1, "reps": "30 seconds", "rest_seconds": 10, "notes": "Sit back, knees tracking over toes"},
        {"exercise_name": "Forward Lunge", "sets": 1, "reps": "30 seconds", "rest_seconds": 10, "notes": "Alternate legs, controlled descent"},
        {"exercise_name": "Glute Bridge", "sets": 1, "reps": "30 seconds", "rest_seconds": 10, "notes": "Squeeze the glutes at the top"},
        {"exercise_name": "Wall Sit", "sets": 1, "reps": "30 seconds", "rest_seconds": 10, "notes": "Thighs parallel, back flat to the wall"},
        {"exercise_name": "Air Squat", "sets": 1, "reps": "30 seconds", "rest_seconds": 10, "notes": "Faster tempo this round"},
        {"exercise_name": "Forward Lunge", "sets": 1, "reps": "30 seconds", "rest_seconds": 10, "notes": "Reverse-lunge variation if knees prefer it"},
        {"exercise_name": "Standing Calf Raise", "sets": 1, "reps": "30 seconds", "rest_seconds": 10, "notes": "Full range, pause at the top"},
        {"exercise_name": "Glute Bridge", "sets": 1, "reps": "30 seconds", "rest_seconds": 10, "notes": "Single-leg if you want more challenge"},
        {"exercise_name": "Wall Sit", "sets": 1, "reps": "30 seconds", "rest_seconds": 10, "notes": "Hold strong through the burn to finish"}
      ]}
    ]
  }'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM programs WHERE program_name = '7-Minute Lower Body');

-- 2.3) 30-Day Plank Challenge — Quick Hits / Core
INSERT INTO programs (
  program_name, program_category, program_subcategory, difficulty_level,
  duration_weeks, sessions_per_week, session_duration_minutes,
  tags, goals, short_description, description, has_workouts, is_published,
  editorial_name, tagline, who_for, who_not_for, equipment_summary, progression_note,
  workouts
)
SELECT
  '30-Day Plank Challenge', 'Quick Hits', 'Core Challenge', 'Beginner',
  5, 6, 10,
  ARRAY['challenge','core','plank','bodyweight','30-day','no-equipment'],
  ARRAY['Core Strength','Stability','Habit-Building'],
  'A 30-day escalating plank challenge with rest days.',
  'A 30-day challenge that builds a rock-solid core from the ground up. Starting at a manageable 20-second hold, the plan ramps your time and introduces plank variations — forearm, side, and shoulder-tap planks — with a built-in rest day every fourth day so you actually recover and don''t quit at the dreaded "day-8 cliff." Progression is capped at a safe rate, so you climb steadily toward multi-minute holds without back pain. Modeled on the U.S. Navy Warfighter Wellness progression.',
  true, true,
  '30-Day Plank Challenge', 'From 20 seconds to a fortress core',
  'Anyone who wants a simple, structured core challenge they can do at home in minutes — beginners welcome.',
  'Anyone with current lower-back, shoulder, or wrist injury, or in late pregnancy — get clearance and modify first.',
  'None — bodyweight only. A mat adds comfort.',
  'Hold time rises gradually (never more than ~20% week to week) with a rest day every 4th day. If you miss a day, repeat it rather than restarting. Drop to forearms or knees any time form breaks.',
  '{
    "program": "30-Day Plank Challenge",
    "category": "Quick Hits",
    "difficulty": "Beginner",
    "duration": "5 weeks",
    "session_duration": 10,
    "sessions_per_week": 6,
    "goals": ["Core Strength", "Stability", "Habit-Building"],
    "description": "A 30-day escalating plank challenge: holds grow from 20s toward multi-minute, with variations and a rest day every 4th day. Repeat a missed day rather than restarting.",
    "workouts": [
      {"day": 1, "type": "Core", "workout_name": "Day 1 — Foundation 20s", "exercises": [{"exercise_name": "High plank", "sets": 3, "reps": "20 seconds", "rest_seconds": 45, "notes": "Neutral spine, braced core"}]},
      {"day": 2, "type": "Core", "workout_name": "Day 2 — Foundation 20s", "exercises": [{"exercise_name": "plank on elbows", "sets": 3, "reps": "20 seconds", "rest_seconds": 45, "notes": "Forearm plank, elbows under shoulders"}]},
      {"day": 3, "type": "Core", "workout_name": "Day 3 — 30s", "exercises": [{"exercise_name": "High plank", "sets": 3, "reps": "30 seconds", "rest_seconds": 45}]},
      {"day": 4, "type": "Rest", "workout_name": "Day 4 — Rest", "exercises": [{"exercise_name": "Child Pose", "sets": 1, "reps": "60 seconds", "rest_seconds": 0, "notes": "Active recovery, breathe and decompress"}]},
      {"day": 5, "type": "Core", "workout_name": "Day 5 — 40s + Side", "exercises": [{"exercise_name": "plank on elbows", "sets": 2, "reps": "40 seconds", "rest_seconds": 45}, {"exercise_name": "side plank", "sets": 2, "reps": "20 seconds per side", "rest_seconds": 30}]},
      {"day": 6, "type": "Core", "workout_name": "Day 6 — 45s", "exercises": [{"exercise_name": "High plank", "sets": 3, "reps": "45 seconds", "rest_seconds": 60}]},
      {"day": 7, "type": "Core", "workout_name": "Day 7 — 50s + Taps", "exercises": [{"exercise_name": "plank on elbows", "sets": 2, "reps": "50 seconds", "rest_seconds": 60}, {"exercise_name": "plank shoulder taps", "sets": 2, "reps": "30 seconds", "rest_seconds": 45}]},
      {"day": 8, "type": "Rest", "workout_name": "Day 8 — Rest", "exercises": [{"exercise_name": "Child Pose", "sets": 1, "reps": "60 seconds", "rest_seconds": 0, "notes": "Recover past the day-8 cliff"}]},
      {"day": 9, "type": "Core", "workout_name": "Day 9 — 60s", "exercises": [{"exercise_name": "High plank", "sets": 3, "reps": "60 seconds", "rest_seconds": 60}]},
      {"day": 10, "type": "Core", "workout_name": "Day 10 — 60s + Side", "exercises": [{"exercise_name": "plank on elbows", "sets": 2, "reps": "60 seconds", "rest_seconds": 60}, {"exercise_name": "side plank", "sets": 2, "reps": "30 seconds per side", "rest_seconds": 30}]},
      {"day": 11, "type": "Core", "workout_name": "Day 11 — 70s", "exercises": [{"exercise_name": "High plank", "sets": 2, "reps": "70 seconds", "rest_seconds": 75}]},
      {"day": 12, "type": "Rest", "workout_name": "Day 12 — Rest", "exercises": [{"exercise_name": "Child Pose", "sets": 1, "reps": "60 seconds", "rest_seconds": 0}]},
      {"day": 13, "type": "Core", "workout_name": "Day 13 — 80s + Taps", "exercises": [{"exercise_name": "plank on elbows", "sets": 2, "reps": "80 seconds", "rest_seconds": 75}, {"exercise_name": "plank shoulder taps", "sets": 2, "reps": "40 seconds", "rest_seconds": 45}]},
      {"day": 14, "type": "Core", "workout_name": "Day 14 — 90s", "exercises": [{"exercise_name": "High plank", "sets": 2, "reps": "90 seconds", "rest_seconds": 90}]},
      {"day": 15, "type": "Core", "workout_name": "Day 15 — 90s + Side", "exercises": [{"exercise_name": "plank on elbows", "sets": 2, "reps": "90 seconds", "rest_seconds": 90}, {"exercise_name": "side plank", "sets": 2, "reps": "40 seconds per side", "rest_seconds": 30}]},
      {"day": 16, "type": "Rest", "workout_name": "Day 16 — Rest", "exercises": [{"exercise_name": "Child Pose", "sets": 1, "reps": "60 seconds", "rest_seconds": 0}]},
      {"day": 17, "type": "Core", "workout_name": "Day 17 — 100s", "exercises": [{"exercise_name": "High plank", "sets": 2, "reps": "100 seconds", "rest_seconds": 90}]},
      {"day": 18, "type": "Core", "workout_name": "Day 18 — 100s + Taps", "exercises": [{"exercise_name": "plank on elbows", "sets": 2, "reps": "100 seconds", "rest_seconds": 90}, {"exercise_name": "plank shoulder taps", "sets": 2, "reps": "45 seconds", "rest_seconds": 45}]},
      {"day": 19, "type": "Core", "workout_name": "Day 19 — 110s", "exercises": [{"exercise_name": "High plank", "sets": 2, "reps": "110 seconds", "rest_seconds": 90}]},
      {"day": 20, "type": "Rest", "workout_name": "Day 20 — Rest", "exercises": [{"exercise_name": "Child Pose", "sets": 1, "reps": "60 seconds", "rest_seconds": 0}]},
      {"day": 21, "type": "Core", "workout_name": "Day 21 — 120s + Side", "exercises": [{"exercise_name": "plank on elbows", "sets": 2, "reps": "120 seconds", "rest_seconds": 120}, {"exercise_name": "side plank", "sets": 2, "reps": "45 seconds per side", "rest_seconds": 30}]},
      {"day": 22, "type": "Core", "workout_name": "Day 22 — 130s", "exercises": [{"exercise_name": "High plank", "sets": 1, "reps": "130 seconds", "rest_seconds": 0}]},
      {"day": 23, "type": "Core", "workout_name": "Day 23 — 140s", "exercises": [{"exercise_name": "plank on elbows", "sets": 1, "reps": "140 seconds", "rest_seconds": 0}]},
      {"day": 24, "type": "Rest", "workout_name": "Day 24 — Rest", "exercises": [{"exercise_name": "Child Pose", "sets": 1, "reps": "60 seconds", "rest_seconds": 0}]},
      {"day": 25, "type": "Core", "workout_name": "Day 25 — 150s", "exercises": [{"exercise_name": "High plank", "sets": 1, "reps": "150 seconds", "rest_seconds": 0}]},
      {"day": 26, "type": "Core", "workout_name": "Day 26 — 150s + Side", "exercises": [{"exercise_name": "plank on elbows", "sets": 1, "reps": "150 seconds", "rest_seconds": 60}, {"exercise_name": "side plank", "sets": 2, "reps": "60 seconds per side", "rest_seconds": 30}]},
      {"day": 27, "type": "Core", "workout_name": "Day 27 — 160s", "exercises": [{"exercise_name": "High plank", "sets": 1, "reps": "160 seconds", "rest_seconds": 0}]},
      {"day": 28, "type": "Rest", "workout_name": "Day 28 — Rest", "exercises": [{"exercise_name": "Child Pose", "sets": 1, "reps": "60 seconds", "rest_seconds": 0}]},
      {"day": 29, "type": "Core", "workout_name": "Day 29 — 170s", "exercises": [{"exercise_name": "plank on elbows", "sets": 1, "reps": "170 seconds", "rest_seconds": 0}]},
      {"day": 30, "type": "Core", "workout_name": "Day 30 — Final 180s Test", "exercises": [{"exercise_name": "High plank", "sets": 1, "reps": "180 seconds", "rest_seconds": 0, "notes": "Three-minute hold — the finish line"}]}
    ]
  }'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM programs WHERE program_name = '30-Day Plank Challenge');

-- 2.5) Anabolic Foundations — Free-Weight Mass — Men's Health #2
INSERT INTO programs (
  program_name, program_category, program_subcategory, difficulty_level,
  duration_weeks, sessions_per_week, session_duration_minutes,
  tags, goals, short_description, description, has_workouts, is_published,
  editorial_name, tagline, who_for, who_not_for, equipment_summary, progression_note,
  workouts
)
SELECT
  'Anabolic Foundations — Free-Weight Mass', 'Men''s Health', 'Hypertrophy', 'Intermediate',
  12, 4, 60,
  ARRAY['free-weights','hypertrophy','strength','mens-health','compound'],
  ARRAY['Muscle Building','Strength','Conditioning'],
  '12-week free-weight hypertrophy and strength block.',
  'A 12-week free-weight mass block built on the big barbell and dumbbell compounds. You train four days a week in the 6-12 rep range at roughly 67-85% of your max, with short-to-moderate rest — the moderate-load, moderate-volume style associated with a strong acute anabolic training response. Free weights over machines means more stabilizer recruitment and more total muscle worked per set. (This is a training program, not a supplement or medical protocol, and makes no promise about your hormone levels.)',
  true, true,
  'Anabolic Foundations — Free-Weight Mass', 'Barbells, dumbbells, and twelve weeks of growth',
  'Intermediate lifters who want a free-weight-first hypertrophy block that doubles as solid strength work.',
  'Complete beginners (start with Starting Strength Foundations) or anyone seeking a medical answer to low testosterone — see a doctor for that.',
  'Barbell, dumbbells, bench, squat rack, and a pull-up/row option. Minimal machine reliance by design.',
  'Progress within the 6-12 rep ranges, adding load when you top a range on all sets. Keep rest short-to-moderate (60-120s) to keep the work dense. Deload every ~6 weeks.',
  '{
    "program": "Anabolic Foundations — Free-Weight Mass",
    "category": "Men''s Health",
    "difficulty": "Intermediate",
    "duration": "12 weeks",
    "session_duration": 60,
    "sessions_per_week": 4,
    "goals": ["Muscle Building", "Strength", "Conditioning"],
    "description": "A 12-week free-weight hypertrophy/strength block: 4 days/week, compound-led, 6-12 reps at ~67-85% 1RM with short-to-moderate rest.",
    "workouts": [
      {"day": 1, "type": "Strength", "workout_name": "Lower — Squat Focus", "exercises": [
        {"exercise_name": "Back Squat", "sets": 4, "reps": "6-8", "rest_seconds": 120, "notes": "Heavy, full depth"},
        {"exercise_name": "Romanian Deadlift", "sets": 4, "reps": "8-10", "rest_seconds": 90},
        {"exercise_name": "Dumbbell Goblet Reverse Lunge", "sets": 3, "reps": "10-12 per leg", "rest_seconds": 75},
        {"exercise_name": "Standing Calf Raise", "sets": 3, "reps": "12-15", "rest_seconds": 60},
        {"exercise_name": "hanging oblique crunches", "sets": 3, "reps": "12-15", "rest_seconds": 60}
      ]},
      {"day": 2, "type": "Strength", "workout_name": "Upper — Push Focus", "exercises": [
        {"exercise_name": "barbell bench press", "sets": 4, "reps": "6-8", "rest_seconds": 120},
        {"exercise_name": "Dumbbell Standing Overhead Press", "sets": 4, "reps": "8-10", "rest_seconds": 90},
        {"exercise_name": "barbell bench press incline", "sets": 3, "reps": "8-12", "rest_seconds": 90},
        {"exercise_name": "Dumbbell Single-Arm Lateral Raise", "sets": 3, "reps": "12-15", "rest_seconds": 60},
        {"exercise_name": "Floor Tricep Dip", "sets": 3, "reps": "10-12", "rest_seconds": 60}
      ]},
      {"day": 3, "type": "Strength", "workout_name": "Lower — Hinge Focus", "exercises": [
        {"exercise_name": "Barbell romanian deadlift", "sets": 4, "reps": "5-6", "rest_seconds": 150, "notes": "Heavy hinge, flat back"},
        {"exercise_name": "Dumbbell Front Squat", "sets": 4, "reps": "8-10", "rest_seconds": 90},
        {"exercise_name": "Barbell Hip Thrust", "sets": 3, "reps": "10-12", "rest_seconds": 75},
        {"exercise_name": "Dumbbell Single-Leg Step-Up", "sets": 3, "reps": "10 per leg", "rest_seconds": 60},
        {"exercise_name": "Farmer''s Carry", "sets": 3, "reps": "40 m", "rest_seconds": 60, "notes": "Heavy, brace hard"}
      ]},
      {"day": 4, "type": "Strength", "workout_name": "Upper — Pull Focus", "exercises": [
        {"exercise_name": "Bent-Over barbell row", "sets": 4, "reps": "6-8", "rest_seconds": 120},
        {"exercise_name": "Pull-Up normal grip", "sets": 4, "reps": "6-10", "rest_seconds": 90, "notes": "Add load once bodyweight is easy"},
        {"exercise_name": "Dumbbell Bench Seated Press", "sets": 3, "reps": "8-10", "rest_seconds": 75, "notes": "Or seated row variation"},
        {"exercise_name": "Dumbbell Rear Lateral Raise", "sets": 3, "reps": "12-15", "rest_seconds": 60},
        {"exercise_name": "dumbbell curls", "sets": 3, "reps": "10-12", "rest_seconds": 60}
      ]}
    ]
  }'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM programs WHERE program_name = 'Anabolic Foundations — Free-Weight Mass');

-- ----------------------------------------------------------------------------
-- STEP 3 — Clean up stray featured_rank values on published rows.
-- Only the 3 HYROX programs (1,2,3) and Beach Body Ready (4) are "featured";
-- clear any pre-existing featured_rank that leaked onto other published rows.
-- ----------------------------------------------------------------------------
UPDATE programs SET featured_rank = NULL
WHERE is_published = true
  AND id NOT IN (
    '28509af5-3ae9-4f3b-a4ad-bbf840798a64',  -- HYROX Race Prep
    '73d9ec23-5845-498f-8015-e961e141cec5',  -- HYROX Full Simulation
    '6348ee98-26a1-4eda-9957-e058de835def',  -- HYROX Pro — Elite Race Build
    '52e8f552-52f0-47bb-9e6c-d6f13a4977d9'   -- Beach Body Ready
  )
  AND featured_rank IS NOT NULL;
