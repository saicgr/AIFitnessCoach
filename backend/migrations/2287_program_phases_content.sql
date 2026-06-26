-- ============================================================================
-- Migration 2287 — Program Phases Content
-- ----------------------------------------------------------------------------
-- Authors the `programs.phases` jsonb column (added in migration 2286) for the
-- 18 PUBLISHED programs. `phases` powers the program detail-page Overview block
-- (e.g. "01 Foundation · Week 1-2 / 02 Build · Week 3-5 / 03 Peak · Week 6-8").
--
-- Each row gets a JSON array of 2-4 blocks of the shape:
--   {"index":1, "title":"...", "subtitle":"...", "week_start":1, "week_end":2}
--
-- Week ranges are derived from each program's REAL duration_weeks; titles and
-- subtitles are specific and honest to that program's structure (a HYROX build's
-- phases are nothing like a yoga program's). Short, repeatable programs (the two
-- 7-minute circuits, the daily yoga flow) get a single "Daily practice" block.
--
-- IDEMPOTENT: every statement is an UPDATE keyed by id (re-running re-sets the
-- same value). Touches ONLY the `phases` column; no other columns/tables.
-- ============================================================================

-- ---- HYROX & Race Prep ------------------------------------------------------

-- HYROX Race Prep (8 weeks)
UPDATE programs SET phases = '[
  {"index":1,"title":"Base & Stations","subtitle":"Running intervals + station technique","week_start":1,"week_end":2},
  {"index":2,"title":"Compromised Running","subtitle":"Stations on tired legs, rising volume","week_start":3,"week_end":5},
  {"index":3,"title":"Simulation & Taper","subtitle":"Full race rehearsal, then sharpen","week_start":6,"week_end":8}
]'::jsonb WHERE id = '28509af5-3ae9-4f3b-a4ad-bbf840798a64';

-- HYROX Full Simulation (1 week — single benchmark)
UPDATE programs SET phases = '[
  {"index":1,"title":"Race Simulation","subtitle":"All 8 stations + 8 km, scored as a benchmark","week_start":1,"week_end":1}
]'::jsonb WHERE id = '73d9ec23-5845-498f-8015-e961e141cec5';

-- HYROX Pro — Elite Race Build (12 weeks)
UPDATE programs SET phases = '[
  {"index":1,"title":"Aerobic Base","subtitle":"Threshold running + heavy strength","week_start":1,"week_end":3},
  {"index":2,"title":"Volume & Double Stations","subtitle":"Back-to-back stations, longer compromised runs","week_start":4,"week_end":7},
  {"index":3,"title":"Race-Pace Simulation","subtitle":"Full-order pacing under fatigue","week_start":8,"week_end":10},
  {"index":4,"title":"Taper","subtitle":"Cut volume, hold sharpness for race day","week_start":11,"week_end":12}
]'::jsonb WHERE id = '6348ee98-26a1-4eda-9957-e058de835def';

-- ---- Aesthetic --------------------------------------------------------------

-- Beach Body Ready (12 weeks)
UPDATE programs SET phases = '[
  {"index":1,"title":"Build the Base","subtitle":"Establish lifts, dial in the deficit","week_start":1,"week_end":3},
  {"index":2,"title":"Shape & Conditioning","subtitle":"Hypertrophy volume + fat-loss finishers","week_start":4,"week_end":8},
  {"index":3,"title":"Cut & Define","subtitle":"Tighten the deficit, reveal definition","week_start":9,"week_end":12}
]'::jsonb WHERE id = '52e8f552-52f0-47bb-9e6c-d6f13a4977d9';

-- ---- Fat Loss ---------------------------------------------------------------

-- Lean Burn — Fat-Loss Circuit (8 weeks)
UPDATE programs SET phases = '[
  {"index":1,"title":"Ease In","subtitle":"Learn the circuits, build the habit","week_start":1,"week_end":3},
  {"index":2,"title":"Turn Up Density","subtitle":"Shorter rest, more rounds","week_start":4,"week_end":6},
  {"index":3,"title":"Peak Burn","subtitle":"Hardest intervals, highest output","week_start":7,"week_end":8}
]'::jsonb WHERE id = 'ce4e2196-f35d-440c-a425-880e675699bd';

-- ---- Men's Health -----------------------------------------------------------

-- Iron Surge — Heavy Compound Strength (12 weeks)
UPDATE programs SET phases = '[
  {"index":1,"title":"Accumulate","subtitle":"Groove the big lifts at 75% range","week_start":1,"week_end":3},
  {"index":2,"title":"Intensify","subtitle":"Climb toward 85-90%, keep rest short","week_start":4,"week_end":8},
  {"index":3,"title":"Peak Strength","subtitle":"Heaviest 5-rep work, then back off","week_start":9,"week_end":12}
]'::jsonb WHERE id = 'd98a7ddc-d55b-4b42-939f-e80f75d4e44e';

-- Anabolic Foundations — Free-Weight Mass (12 weeks)
UPDATE programs SET phases = '[
  {"index":1,"title":"Foundation","subtitle":"Own the free-weight compounds","week_start":1,"week_end":3},
  {"index":2,"title":"Growth Volume","subtitle":"Add sets and load across 6-12 reps","week_start":4,"week_end":8},
  {"index":3,"title":"Overload","subtitle":"Push top-end load, then deload","week_start":9,"week_end":12}
]'::jsonb WHERE id = 'ed09f728-640c-4898-aaec-81643b1dd83b';

-- ---- Women's Health ---------------------------------------------------------

-- Strong & Steady — Women's Full-Body Strength (12 weeks)
UPDATE programs SET phases = '[
  {"index":1,"title":"Movement Base","subtitle":"Squat, hinge, push, pull, carry","week_start":1,"week_end":3},
  {"index":2,"title":"Progressive Load","subtitle":"Add weight before reps each week","week_start":4,"week_end":8},
  {"index":3,"title":"Strength Peak","subtitle":"Heaviest sets, rotate accessories","week_start":9,"week_end":12}
]'::jsonb WHERE id = '76ff820c-163c-44d5-9c9e-f84e7da311d4';

-- Postpartum Rebuild (6 weeks)
UPDATE programs SET phases = '[
  {"index":1,"title":"Reconnect","subtitle":"Breathing, core & pelvic-floor connection","week_start":1,"week_end":2},
  {"index":2,"title":"Rebuild","subtitle":"Layer in gentle full-body strength","week_start":3,"week_end":4},
  {"index":3,"title":"Reload","subtitle":"Add light load as control returns","week_start":5,"week_end":6}
]'::jsonb WHERE id = '718331e4-0c06-4538-bded-63362031cdb9';

-- ---- Strength & Muscle ------------------------------------------------------

-- Starting Strength Foundations (12 weeks)
UPDATE programs SET phases = '[
  {"index":1,"title":"Linear Ramp","subtitle":"Add weight to the bar every session","week_start":1,"week_end":4},
  {"index":2,"title":"Heavy Progression","subtitle":"Loads climb, recovery gets harder","week_start":5,"week_end":9},
  {"index":3,"title":"Top-End","subtitle":"Grind out final gains, deload on stalls","week_start":10,"week_end":12}
]'::jsonb WHERE id = '5886bf32-6ee9-4c17-aa5b-f733bfba3aca';

-- Beginner Foundations (8 weeks)
UPDATE programs SET phases = '[
  {"index":1,"title":"Learn the Moves","subtitle":"Master the basic patterns","week_start":1,"week_end":3},
  {"index":2,"title":"Build the Habit","subtitle":"Add reps and confidence","week_start":4,"week_end":8}
]'::jsonb WHERE id = 'cc56fab8-c9d4-42f0-936a-ea6975c9d064';

-- Hypertrophy 4-Day Split (12 weeks)
UPDATE programs SET phases = '[
  {"index":1,"title":"Foundation","subtitle":"Set the split, find working weights","week_start":1,"week_end":3},
  {"index":2,"title":"Volume","subtitle":"Accumulate sets in the 8-15 range","week_start":4,"week_end":8},
  {"index":3,"title":"Intensify","subtitle":"Heavier load, then a deload","week_start":9,"week_end":12}
]'::jsonb WHERE id = 'b0d8bc88-b9be-4c3c-87e9-18100c9f9f87';

-- Push / Pull / Legs Hypertrophy (12 weeks)
UPDATE programs SET phases = '[
  {"index":1,"title":"Volume Base","subtitle":"Twice-a-week frequency dialed in","week_start":1,"week_end":3},
  {"index":2,"title":"Accumulation","subtitle":"Drive compounds, pile on accessory volume","week_start":4,"week_end":8},
  {"index":3,"title":"Intensify & Deload","subtitle":"Peak the lifts, then back off","week_start":9,"week_end":12}
]'::jsonb WHERE id = '8572438b-d394-4d01-bf4e-d9596e5cf7f4';

-- No-Equipment Home Workout (8 weeks)
UPDATE programs SET phases = '[
  {"index":1,"title":"Build the Base","subtitle":"Own the bodyweight basics","week_start":1,"week_end":3},
  {"index":2,"title":"Progress","subtitle":"More reps, slower tempo, harder variations","week_start":4,"week_end":8}
]'::jsonb WHERE id = 'a616a82c-d9be-4b71-a7ef-7b291ec47107';

-- ---- Yoga & Mobility --------------------------------------------------------

-- Daily Flow — Yoga for Lifters (4 weeks — daily practice)
UPDATE programs SET phases = '[
  {"index":1,"title":"Daily Practice","subtitle":"Mobility flow, easing deeper each week","week_start":1,"week_end":4}
]'::jsonb WHERE id = '3132f0e1-c235-48da-ba78-52e4b9704442';

-- ---- Quick Hits -------------------------------------------------------------

-- 7-Minute Upper Body (2 weeks — repeatable daily circuit)
UPDATE programs SET phases = '[
  {"index":1,"title":"Daily Practice","subtitle":"Repeat the 7-minute upper-body circuit","week_start":1,"week_end":2}
]'::jsonb WHERE id = '0f9d9142-be65-4d13-aafc-223c96867d5c';

-- 7-Minute Lower Body (2 weeks — repeatable daily circuit)
UPDATE programs SET phases = '[
  {"index":1,"title":"Daily Practice","subtitle":"Repeat the 7-minute lower-body circuit","week_start":1,"week_end":2}
]'::jsonb WHERE id = '5988380c-defa-49a5-b0d8-83edc2f03d09';

-- 30-Day Plank Challenge (5 weeks / 30 days — escalating holds)
UPDATE programs SET phases = '[
  {"index":1,"title":"Build the Base","subtitle":"20-50s holds, learn the variations","week_start":1,"week_end":2},
  {"index":2,"title":"Endurance","subtitle":"Climb toward two-minute holds","week_start":3,"week_end":4},
  {"index":3,"title":"Peak Holds","subtitle":"Push to the 3-minute finish line","week_start":5,"week_end":5}
]'::jsonb WHERE id = '6e9539c2-feef-497d-9d0b-8c499838d2f8';
